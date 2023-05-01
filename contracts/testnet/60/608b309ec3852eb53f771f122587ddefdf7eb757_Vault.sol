// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "solmate/src/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "./AccessControlBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/tokens/wlp/IUSDW.sol";
import "../interfaces/core/IVault.sol";
import "../interfaces/oracles/IOracleRouter.sol";
import "../interfaces/jbcontracts/IVaultManager.sol";
import "../interfaces/core/IWLPManager.sol";

contract Vault is ReentrancyGuard, AccessControlBase, IVault {
	using EnumerableSet for EnumerableSet.AddressSet;
	/*==================== Constants *====================*/
	uint32 private constant BASIS_POINTS_DIVISOR = 1e4;
	uint32 private constant USDW_DECIMALS = 18;
	uint32 private constant MAX_FEE_BASIS_POINTS = 1000; // 10%
	uint128 private constant PRICE_PRECISION = 1e30;
	uint128 private constant MAX_WAGER_FEE = (15 * 1e16); // 15% | Scaling: 1e18 = 100% - 1e17 = 10% - 1e16 = 1%

	/*==================== State Variables *====================*/
	bool public override isInitialized;
	bool public override isSwapEnabled = true;
	bool public override hasDynamicFees = false;
	bool public override inManagerMode = false;
	bool private payoutsHalted = false;
	bool private circuitBreakerEnabled = false;

	IVaultUtils public vaultUtils;
	address public override router;
	address public override priceOracleRouter;
	address public immutable override usdw;

	address public wlpManagerAddress;
	EnumerableSet.AddressSet internal allWhitelistedTokensSet;
	address public override feeCollector;

	// all the fees are in basis points, scaled 1e4, so 100% = 1e4, 50 = 0.5%, 20 = 0.2%, 100 = 1%
	uint256 public override taxBasisPoints = 50;
	uint256 public override stableTaxBasisPoints = 20;
	uint256 public override mintBurnFeeBasisPoints = 30;
	uint256 public override swapFeeBasisPoints = 30;
	uint256 public override stableSwapFeeBasisPoints = 4;
	uint256 public override minimumBurnMintFee = 15;
	// percentage fee that will be charged over every wager coming into the contract
	uint256 public override wagerFeeBasisPoints;
	uint256 public override totalTokenWeights;

	mapping(address => bool) public override isManager;
	mapping(address => bool) internal _whitelistedTokens;
	mapping(address => uint256) public override tokenDecimals;
	mapping(address => bool) public override stableTokens;
	// tokenBalances is used only to determine _transferIn values
	mapping(address => uint256) public override tokenBalances;
	// tokenWeights allows customisation of index composition
	mapping(address => uint256) public override tokenWeights;
	// usdwAmounts tracks the amount of USDW debt for each whitelisted token
	mapping(address => uint256) public override usdwAmounts;
	// maxUsdwAmounts allows setting a max amount of USDW debt for a token
	mapping(address => uint256) public override maxUsdwAmounts;
	mapping(address => uint256) public override poolAmounts;
	mapping(address => uint256) internal circuitBreakerAmounts;
	// bufferAmounts allows specification of an amount to exclude from swaps
	mapping(address => uint256) public override bufferAmounts;
	mapping(uint256 => string) internal errors;
	// tokenAddress => amountOfWagerFees accumulated
	mapping(address => uint256) public override wagerFeeReserves;
	// swapFeeReserves tracks the amount of swap fees per token collecte
	mapping(address => uint256) public override swapFeeReserves;
	// mapping that stores the amount of referralfees that are collected in the vault
	mapping(address => uint256) public override referralReserves;
	// mapping storing the AGGREGATED (so of all time) amount of payouts via games!
	mapping(address => uint256) internal totalOut_;
	// mapping storing the AGGREGATED (so of all time) amount of payins via games!
	mapping(address => uint256) internal totalIn_;
	mapping(address => bool) internal isVaultManager;

	constructor(
		address _vaultRegistry,
		address _timelock,
		address _usdw
	) AccessControlBase(_vaultRegistry, _timelock) {
		usdw = _usdw;
	}

	function initialize(address _router, address _priceOracleRouter) external onlyGovernance {
		_validate(!isInitialized, 1);
		isInitialized = true;
		router = _router;
		priceOracleRouter = _priceOracleRouter;
	}

	/*==================== Operational functions Custom WINR/JB *====================*/

	/**
	 * @notice function that collects the escrowerd tokens and pays out recipients based on info passed in by the VaultManager
	 * @dev function can only be called by the vaultmanager contract
	 * note: one of the most important contracts as it handles payouts to players
	 * @param _tokens [0] is the wagerToken(coming into the contract), [1] is the payout token (leaving the contract)
	 * @param _escrowAddress the address where the escrowed wager is held (generally vaultManager address)
	 * @param _escrowAmount the amount of _tokens[0] held in escrow
	 * @param _recipient the address the _tokens[1] will be sent to
	 * @param _totalAmount total value of _tokens[1] the _recipient will receive (with fees deducted) - note that _totalAmount is denominated in _tokens[0].
	 */
	function payout(
		address[2] calldata _tokens,
		address _escrowAddress,
		uint256 _escrowAmount,
		address _recipient,
		uint256 _totalAmount
	) external nonReentrant protocolNotPaused {
		_validate(isVaultManager[_msgSender()], 13);
		_validate(!payoutsHalted, 19);
		_validate(_totalAmount != 0, 10);
		_validate(_escrowAmount != 0, 16);
		_validate(_whitelistedTokens[_tokens[0]], 9);
		_validate(_whitelistedTokens[_tokens[1]], 9);
		// withdraw the escrowed tokens from the vaultmanager contract
		IVaultManager(_escrowAddress).getEscrowedTokens(_tokens[0], _escrowAmount);
		// collect the wager fees, charged in the wager token _tokens[0] over _escrowAmount
		(uint256 amountAfterWagerFee_, uint256 wagerFeeCharged_) = _collectWagerFees(
			_tokens[0],
			_escrowAmount
		);
		/**
		 * Accounting rules post payout (called by the VRF resolution) - SAME ASSET PAYOUT:
		 * - The wager fee is charged over the incoming asset (the wagerAsset, _tokens[0]) this value comes from the escrowAmount (the wager is held in escrow during the game while awaiting the VRF result)
		 * - The wagerFeeCharged_ cost is beared by the vault (so it comes out of the poolAmounts or the WLPs 'equity')
		 * - The player has won the _totalAmount this is denominated in the wagerAsset (so in _tokens[0])
		 * - If the player has decided he wants to win the same asset, the player (_recipient) will receive the _totalAmount without any deduction (for this flow see the first if statement _tokens[0] == _tokens[1])
		 *
		 * note: the wager fee is charged over the incoming asset (the wagerAsset, _tokens[0])
		 */

		uint256 _amountNetDifference;
		if (_tokens[0] == _tokens[1]) {
			// wagerAsset in, is the same as winAsset
			uint256 _totalForVault;
			unchecked {
				_totalForVault = (_totalAmount + wagerFeeCharged_);
			}
			if (_escrowAmount <= _totalForVault) {
				unchecked {
					// calculate how much the vault lost on net
					_amountNetDifference = (_totalForVault - _escrowAmount);
					// decrease the net amount the WLP has to pay from the pool amounts
					totalOut_[_tokens[0]] += _amountNetDifference;
				}
				_decreasePoolAmount(_tokens[0], _amountNetDifference);
			} else {
				// the vault made a profit!
				unchecked {
					_amountNetDifference = (_escrowAmount - _totalForVault);
					totalIn_[_tokens[0]] += _amountNetDifference;
				}
				_increasePoolAmount(_tokens[0], _amountNetDifference);
			}
			_payoutPlayer(
				_tokens[0], // _addressTokenOut (same as _tokens[1])
				_totalAmount,
				_recipient // _recipient (player address)
			);
			return;
		} else {
			// token in, is different from token out, the player wants the totalAmount in a different asset, so we need to swap in this scenario
			uint256 totalAmountOut_ = _amountOfTokenForToken(
				_tokens[0],
				_tokens[1],
				_totalAmount
			);
			// note the player wants to receive the winnings in _tokens[1], the _totalAmount is denominated in _tokens[0] so before we proceed we need to calculate how much _totalAmount is in _tokens[1].
			if (totalAmountOut_ == 0) {
				// the player has effectively won nothing converted into _tokens[1]
				_increasePoolAmount(_tokens[0], amountAfterWagerFee_);
				unchecked {
					totalIn_[_tokens[0]] += amountAfterWagerFee_;
				}
				// sync the tokenbalance of the vault, as the wagerAsset now sits in this contract and we are not doing a _playerPayout
				_updateTokenBalance(_tokens[0]);
				emit AmountOutNull();
				emit PlayerPayout(_recipient, _tokens[1], 0);
				return; // function stops as there is nothing to pay out!
			}
			// note swap fees are paid to the feecollector in the outgoing token (so _tokens[1])
			(uint256 amountOutAfterSwap_, uint256 feesPaidInOut_) = _swap(
				_tokens[0],
				_tokens[1],
				address(this),
				_escrowAmount,
				true
			);
			/**
			 * Accounting rules post payout (called by the VRF resolution) - DIFFERENT ASSET PAYOUT:
			 * - The wager fee is charged over the incoming asset (the wagerAsset, _tokens[0]) and paid to the feecollector
			 * - The vault swaps the entire _escowAmount (this to maximize the swapFee the vault can generate) - due to this in a payout where the vault has made a loss, the vault will decrease its poolAmount of both tokens[0] and tokens[1]
			 * - UNLIKE the wagerFee the swapFee is paid by the player (the player pays the swapFee in the outgoing token, _tokens[1])
			 *
			 * Main think to note is that the swapFee is paid for by the player, so the player will receive less than the _totalAmount. The swap fee is NOT A COST for the vault like the wagerFee is - but it does mean that the vault will receive less assets that go towarwards it equity.
			 */

			// the vault has paid the wagerFeeCharged_ in _tokens[0] so we need to update the pool amounts
			_decreasePoolAmount(_tokens[0], wagerFeeCharged_);
			unchecked {
				// update totalOut for the _tokens[0] wagerFee the vault has paid
				totalOut_[_tokens[0]] += wagerFeeCharged_;
			}
			_updateTokenBalance(_tokens[0]);
			if (totalAmountOut_ >= amountOutAfterSwap_) {
				// vault has made a loss
				unchecked {
					_amountNetDifference = (totalAmountOut_ -
						amountOutAfterSwap_);
					totalOut_[_tokens[1]] += _amountNetDifference;
				}
				// we register the loss with the pool balances
				_decreasePoolAmount(_tokens[1], _amountNetDifference);
			} else {
				// vault has made a profit
				unchecked {
					_amountNetDifference = (amountOutAfterSwap_ -
						totalAmountOut_);
					totalIn_[_tokens[1]] += _amountNetDifference;
				}
				// we register the profit with the pool balances
				_increasePoolAmount(_tokens[1], _amountNetDifference);
				if (feesPaidInOut_ >= totalAmountOut_) {
					// if the feesPaidInOut_ is larger as the totalAmountOut_, the player is not receiving anything
					_updateTokenBalance(_tokens[1]);
					// correct the subtracted totalAmountOut_ since it is owned by the vault
					_increasePoolAmount(_tokens[1], totalAmountOut_);
					unchecked {
						totalIn_[_tokens[1]] += totalAmountOut_;
					}
					// since _payoutPlayer is not reached, emit event for null payout
					emit PlayerPayout(_recipient, _tokens[1], 0);
					return;
				}
			}
			// note: the swapFee stays in the Vault  (for now) however it is not part of the WLP anymore! the _swap function has already done the _updateTokenBalance so we do not need to do that anymore
			_payoutPlayer(
				_tokens[1],
				(totalAmountOut_ - feesPaidInOut_), // feesPaidInOut_ cannot be larger as because otherwise it would already have returned because of the previous if/else/if statement
				_recipient
			);
			return;
		}
	}

	/**
	 * @notice function called by the vault manager to add assets to the WLP (profit)
	 * @dev can only be called by the vault manager
	 * @dev a wagerFeeBasisPoints will be charged over the incoming assets
	 * @param _inputToken the address of the escrowed token
	 * @param _escrowAddress the address where the _inputToken is in escrow
	 * @param _escrowAmount the amount of the _inputToken that is held in escrow
	 */
	function payin(
		address _inputToken,
		address _escrowAddress,
		uint256 _escrowAmount
	) external nonReentrant protocolNotPaused {
		_validate(isVaultManager[_msgSender()], 13);
		_validate(_whitelistedTokens[_inputToken], 9);
		_validate(_escrowAmount != 0, 16);
		// pull the ecrowed tokens to the vault from the vault manager
		IVaultManager(_escrowAddress).getEscrowedTokens(_inputToken, _escrowAmount);
		// note: the escrowed tokens now sit in this contract
		// deduct the wager fees from the escrowed tokens
		(uint256 amountAfterWagerFee_, ) = _collectWagerFees(_inputToken, _escrowAmount);
		// add the tokens to the WLP, this will incrase the value of the wlp
		_increasePoolAmount(_inputToken, amountAfterWagerFee_);
		// update the balace of tokenBalances to ensure that the next swapper for this token isn't credited for this payin
		_updateTokenBalance(_inputToken);
		unchecked {
			totalIn_[_inputToken] += amountAfterWagerFee_;
		}
		emit PayinWLP(_inputToken, _escrowAmount);
	}

	/*==================== Operational functions WINR/JB *====================*/

	/**
	 * @notice function that adds a whitelisted asset to the pool, without issuance of WLP or USDW!
	 * @param _tokenIn address of the token to directly deposit into the pool
	 * @dev take note that depositing LP by this means will NOT mint WLP to the caller. This function would only make sense to use if called by the WINR DAO. If you call this function you will receive nothing in return, it is effectively gifting liquidity to the pool without getting anything back.
	 */
	function directPoolDeposit(
		address _tokenIn
	) external override protocolNotPaused onlyManager {
		require(IERC20(usdw).totalSupply() != 0, "Vault: USDW supply 0");
		_validate(_whitelistedTokens[_tokenIn], 9);
		uint256 tokenAmount_ = _transferIn(_tokenIn);
		_validate(tokenAmount_ != 0, 10);
		_increasePoolAmount(_tokenIn, tokenAmount_);
		emit DirectPoolDeposit(_tokenIn, tokenAmount_);
	}

	/**
	 * @notice function that withdraws the swap fees and transfers them to the feeCollector contract
	 * @param _tokenToWithdraw the address of the token youS want to withdraw fees from
	 * @return collectedSwapFees_ the amount of swap fees that are available to be withdrawn
	 * @return totalWagerFees_ the amount of wager fees that are available to be withdrawn
	 * @return registeredReferralKickback_ the amount of referral kickback that is available to be withdrawn
	 */
	function withdrawAllFees(
		address _tokenToWithdraw
	)
		external
		override
		protocolNotPaused
		returns (
			uint256 collectedSwapFees_,
			uint256 totalWagerFees_,
			uint256 registeredReferralKickback_
		)
	{
		// store to memory to save on SLOAD
		address feeCollector_ = feeCollector;
		// only a fecollector can collect fees
		require(_msgSender() == feeCollector_, "Vault: Caller must be feecollector");

		collectedSwapFees_ = swapFeeReserves[_tokenToWithdraw];
		totalWagerFees_ = wagerFeeReserves[_tokenToWithdraw];
		registeredReferralKickback_ = referralReserves[_tokenToWithdraw];

		/**
		 * The amounnt of referral kickback is capped by the amount of wagerFees that is collected in a period.
		 * As per rule the referral fees cannot bee more than 20% of the amount of wagerFees collected.
		 * If the referral fees are more than 20% of the wagerFees collected, the referral fees are capped at 20% of the wagerFees collected.
		 */

		// calculate the maximum amount of referral kickback that can be paid out (a fraction of wagerFeeReserves, the size of fraction is configured in WLPManager)
		uint256 maxAmountReferral_ = (totalWagerFees_ *
			IWLPManager(wlpManagerAddress).maxPercentageOfWagerFee()) /
			BASIS_POINTS_DIVISOR;

		if (registeredReferralKickback_ > maxAmountReferral_) {
			// the referral amount is larger as should be possible, this indicates there is a mistake or exploit in the referral system, hence we null the registeredReferralickback
			emit ReferralDistributionReverted(
				registeredReferralKickback_,
				maxAmountReferral_
			);
			//  since we suspect a exploit/problem in referral system, we null the referral rewards, with this no funds can be lost
			registeredReferralKickback_ = 0;
		} else {
			// this is the normal situation, the referral kickback is smaller then the configured fraction of the total wager fees._tokenToWithdraw
			// note: the vault/WLPs 'pay for' the referral kickback! to reflect this we need to decrease pool amout and also update the totalOut
			_decreasePoolAmount(_tokenToWithdraw, registeredReferralKickback_);
			unchecked {
				// update totalOut for the _tokenToWithdraw that the vault pays
				totalOut_[_tokenToWithdraw] += registeredReferralKickback_;
			}
		}

		// clear the collected reserves
		delete swapFeeReserves[_tokenToWithdraw];
		delete wagerFeeReserves[_tokenToWithdraw];
		delete referralReserves[_tokenToWithdraw];

		// transfer all the collected fees to the feecollector contract
		_transferOut(
			_tokenToWithdraw,
			(collectedSwapFees_ + totalWagerFees_ + registeredReferralKickback_),
			feeCollector_
		);

		emit WithdrawAllFees(
			_tokenToWithdraw,
			collectedSwapFees_,
			totalWagerFees_,
			registeredReferralKickback_
		);

		return (collectedSwapFees_, totalWagerFees_, registeredReferralKickback_);
	}

	/**
	 * @notice function used to purchase USDW with
	 * @dev when ManagerMode is enabled, this function can only be called by a WLPManager contract
	 * @param _tokenIn the token used to purchase/mint the WLP
	 * @param _receiverUSDW the address the caller, this is generally the WLPManager contract, this address will receive the USDW (not the WLP)
	 * @return mintAmountUsdw_ the amount of usdw that is minted to the WLPManager contract
	 */
	function deposit(
		address _tokenIn,
		address _receiverUSDW
	) external override protocolNotPaused nonReentrant returns (uint256 mintAmountUsdw_) {
		_validateManager();
		_validate(_whitelistedTokens[_tokenIn], 9);
		uint256 tokenAmount_ = _transferIn(_tokenIn);
		_validate(tokenAmount_ != 0, 10);
		// fetch the price of the incoming token, the vault always prices an incoming asset by its lower bound price (so in the benefit of the WLPs)
		uint256 price_ = getMinPrice(_tokenIn);
		uint256 usdwAmount_ = _adjustForDecimals(
			tokenAmount_,
			price_,
			PRICE_PRECISION,
			tokenDecimals[_tokenIn],
			USDW_DECIMALS
		);
		_validate(usdwAmount_ != 0, 12);
		uint256 feeBasisPoints_ = vaultUtils.getBuyUsdwFeeBasisPoints(
			_tokenIn,
			usdwAmount_
		);
		// note: the swapfee is charged in the incoming token (so in _tokenIn)
		(uint256 amountOutAfterFees_, ) = _collectSwapFees(
			_tokenIn,
			tokenAmount_,
			feeBasisPoints_
		);
		// calculate the USDW value of the deposit (so this is the dollar value)
		mintAmountUsdw_ = _adjustForDecimals(
			amountOutAfterFees_,
			price_,
			PRICE_PRECISION,
			tokenDecimals[_tokenIn],
			USDW_DECIMALS
		);
		_increaseUsdwAmount(_tokenIn, mintAmountUsdw_);
		_increasePoolAmount(_tokenIn, amountOutAfterFees_);
		// mint usdw to the _receiverUSDW contract (generally wlpManager if ManagerMode is enabled)
		IUSDW(usdw).mint(_receiverUSDW, mintAmountUsdw_);
		emit BuyUSDW(
			_receiverUSDW,
			_tokenIn,
			tokenAmount_,
			mintAmountUsdw_,
			feeBasisPoints_
		);
		return mintAmountUsdw_;
	}

	/**
	 * @notice redeem wlp for asset of choice (burn wlp, withdraw asset) -> sellUSDW/sellUSDW
	 * @param _tokenOut the address of the token the seller wants to redeem his USDW for
	 * @param _receiverTokenOut the address that will receive the _tokenOut (so the asset the withdrawer is redeeming their WLP for)
	 * @return amountOut_ the amount of _tokenOut that the receiver has redeemed
	 * @dev when ManagerMode is enabled, this function can only be called by the wlpManager contract!
	 */
	function withdraw(
		address _tokenOut,
		address _receiverTokenOut
	) external override protocolNotPaused nonReentrant returns (uint256) {
		_validateManager();
		_validate(_whitelistedTokens[_tokenOut], 9);
		address usdw_ = usdw;
		uint256 usdwAmount_ = _transferIn(usdw_);
		_validate(usdwAmount_ != 0, 12);
		uint256 redemptionAmount_ = getRedemptionAmount(_tokenOut, usdwAmount_);
		_validate(redemptionAmount_ != 0, 15);
		_decreaseUsdwAmount(_tokenOut, usdwAmount_);
		_decreasePoolAmount(_tokenOut, redemptionAmount_);
		// check if the withdraw of the chose asset (_tokenOut) doesn't push the balance of the token under the bufferAmount
		_validateBufferAmount(_tokenOut);
		// USDW held in this contract (the vault) is burned
		IUSDW(usdw_).burn(address(this), usdwAmount_);
		// the _transferIn call increased the value of tokenBalances[usdw]
		// usually decreases in token balances are synced by calling _transferOut
		// however, for usdw, the tokens are burnt, so _updateTokenBalance should
		// be manually called to record the decrease in tokens
		_updateTokenBalance(usdw_);
		uint256 feeBasisPoints_ = vaultUtils.getSellUsdwFeeBasisPoints(
			_tokenOut,
			usdwAmount_
		);
		// swap fee is collected in the outgoing token (so the token that is reedeemed)
		(uint256 amountOutAfterFees_, ) = _collectSwapFees(
			_tokenOut,
			redemptionAmount_,
			feeBasisPoints_
		);
		_validate(amountOutAfterFees_ != 0, 10);
		_transferOut(_tokenOut, amountOutAfterFees_, _receiverTokenOut);
		emit SellUSDW(
			_receiverTokenOut,
			_tokenOut,
			usdwAmount_,
			amountOutAfterFees_,
			feeBasisPoints_
		);
		return amountOutAfterFees_;
	}

	/**
	 * @notice function allowing a purchaser to buy a WLP asset with another WLP asset
	 * @dev this function is generally used for arbitrage
	 * @param _tokenIn address of the token that is being sold
	 * @param _tokenOut address of token that is being bought
	 * @param _receiver the address the tokenOut will be receive the _tokenOut
	 * @return amountOutAfterFees_ amount of _tokenOut _receiver will be credited
	 */
	function swap(
		address _tokenIn,
		address _tokenOut,
		address _receiver
	) external override nonReentrant protocolNotPaused returns (uint256 amountOutAfterFees_) {
		_validate(isSwapEnabled, 17);
		_validate(_whitelistedTokens[_tokenIn], 9);
		_validate(_whitelistedTokens[_tokenOut], 9);
		_validate(_tokenIn != _tokenOut, 22);
		uint256 amountIn_ = _transferIn(_tokenIn);
		(amountOutAfterFees_, ) = _swap(_tokenIn, _tokenOut, _receiver, amountIn_, false);
		return amountOutAfterFees_;
	}

	/*==================== Internal functions *====================*/

	/**
	 * @param _tokenIn address of the tokens being sold
	 * @param _tokenOut address of the token being bought
	 * @param _receiver address that will receive _receiver
	 * @param _amountIn amount of _tokenIn being sold to the Vault
	 * @param _byPayout bool signalling if the swap is for a payout
	 * @return amountOutAfterFees_ amount of _tokenOut that
	 * @return feesPaidInOut_ amount of swapFees charged in _tokenOut
	 * @dev the swapFee is charged in the outgoing token (_tokenOut)
	 */
	function _swap(
		address _tokenIn,
		address _tokenOut,
		address _receiver,
		uint256 _amountIn,
		bool _byPayout
	) internal returns (uint256 amountOutAfterFees_, uint256 feesPaidInOut_) {
		_validate(_amountIn != 0, 10);
		uint256 amountOut_;
		uint256 usdwAmount_;
		{
			uint256 priceOut_ = getMaxPrice(_tokenOut);
			uint256 priceIn_ = getMinPrice(_tokenIn);
			uint256 decimalsIn_ = tokenDecimals[_tokenIn];
			uint256 decimalsOut_ = tokenDecimals[_tokenOut];
			if (decimalsOut_ >= decimalsIn_) {
				amountOut_ = Math.mulDiv(
					_amountIn * 10 ** (decimalsOut_ - decimalsIn_),
					priceIn_,
					priceOut_
				);
			} else {
				amountOut_ = Math.mulDiv(
					_amountIn,
					priceIn_,
					priceOut_ * 10 ** (decimalsIn_ - decimalsOut_)
				);
			}
			if (USDW_DECIMALS >= decimalsIn_) {
				usdwAmount_ = Math.mulDiv(
					_amountIn * 10 ** (USDW_DECIMALS - decimalsIn_),
					priceIn_,
					1e30
				);
			} else {
				usdwAmount_ = Math.mulDiv(
					_amountIn,
					priceIn_,
					1e30 * 10 ** (decimalsIn_ - USDW_DECIMALS)
				);
			}
		}
		uint256 feeBasisPoints_ = vaultUtils.getSwapFeeBasisPoints(
			_tokenIn,
			_tokenOut,
			usdwAmount_
		);
		// note: when swapping the swap fee is paid in the outgoing asset
		(amountOutAfterFees_, feesPaidInOut_) = _collectSwapFees(
			_tokenOut,
			amountOut_,
			feeBasisPoints_
		);
		_increaseUsdwAmount(_tokenIn, usdwAmount_);
		_decreaseUsdwAmount(_tokenOut, usdwAmount_);
		_increasePoolAmount(_tokenIn, _amountIn);
		_decreasePoolAmount(_tokenOut, amountOut_);
		// if the swap function is called by payout, we do not check bufferamount
		if (!_byPayout) {
			// only checked on external swap
			_validateBufferAmount(_tokenOut);
		}
		_transferOut(_tokenOut, amountOutAfterFees_, _receiver);
		emit Swap(
			_receiver,
			_tokenIn,
			_tokenOut,
			_amountIn,
			amountOut_,
			amountOutAfterFees_,
			feeBasisPoints_
		);
		return (amountOutAfterFees_, feesPaidInOut_);
	}

	/**
	 * @dev wager fees accumulate in this contract and need to be periodically sweeped
	 * @param _tokenEscrowIn the address of the token the wagerFeeBasisPoints is charged over
	 * @param _amountEscrow the amount of _token the wagerFeeBasisPoints is charged over
	 * @return amountAfterWagerFee_ wager amount of the _token that is left after the fee is deducted
	 * @return wagerFeeCharged_ amount of fee charged, denominated in _token (not USD value)
	 * note the wagerFeeBasisPoints stays in the vault contract until it is farmed by the FeeCollector contract
	 */
	function _collectWagerFees(
		address _tokenEscrowIn,
		uint256 _amountEscrow
	) private returns (uint256 amountAfterWagerFee_, uint256 wagerFeeCharged_) {
		// using 1e18 scaling or wagerFee -  Scaling: 1e18 = 100% - 1e17 = 10% - 1e16 = 1%
		amountAfterWagerFee_ = ((_amountEscrow * (1e18 - wagerFeeBasisPoints)) / 1e18);
		wagerFeeCharged_ = _amountEscrow - amountAfterWagerFee_;
		unchecked {
			wagerFeeReserves[_tokenEscrowIn] += wagerFeeCharged_;
		}
		return (amountAfterWagerFee_, wagerFeeCharged_);
	}

	/**
	 * @dev swap fees arge charged over/on the outgoing token
	 * @param _tokenAddress the address of the token the fees are charged over
	 * @param _amountOfToken the amount of the ingoing
	 * @param _feeBasisPoints amount of baiss points (scaled 1e4)
	 * @return amountOutAfterFees_ the amount of _tokenAddress that is left after fees are deducted
	 * @return feesPaidInOut_ the amount of _tokenAddress that 'stays behind' in the vailt
	 */
	function _collectSwapFees(
		address _tokenAddress,
		uint256 _amountOfToken,
		uint256 _feeBasisPoints
	) private returns (uint256 amountOutAfterFees_, uint256 feesPaidInOut_) {
		amountOutAfterFees_ =
			(_amountOfToken * (BASIS_POINTS_DIVISOR - _feeBasisPoints)) /
			BASIS_POINTS_DIVISOR;
		feesPaidInOut_ = (_amountOfToken - amountOutAfterFees_);
		unchecked {
			swapFeeReserves[_tokenAddress] += feesPaidInOut_;
		}
		return (amountOutAfterFees_, feesPaidInOut_);
	}

	/**
	 * @notice internal payout function -  transfer the token to the recipient
	 * @param _addressTokenOut the address of the token that will be transferred to the player
	 * @param _toPayOnNet amount of _addressTokenOut the WLP will transfer to the
	 * @param _recipient the address of the recipient of the token _recipient
	 */
	function _payoutPlayer(
		address _addressTokenOut,
		uint256 _toPayOnNet,
		address _recipient
	) internal {
		_transferOut(_addressTokenOut, _toPayOnNet, _recipient);
		emit PlayerPayout(_recipient, _addressTokenOut, _toPayOnNet);
	}

	/**
	 * @notice internal function that keeps track of the recorded incoming token transfers
	 * @dev this function is crucial for the proper operation of swap and deposit functionality
	 * @param _tokenIn address of the token that is (allegidly) transferred to the vault
	 * @return amountTokenIn_ amount of _tokenIn that was transferred into the contract
	 */
	function _transferIn(address _tokenIn) private returns (uint256 amountTokenIn_) {
		uint256 prevBalance_ = tokenBalances[_tokenIn];
		uint256 nextBalance_ = IERC20(_tokenIn).balanceOf(address(this));
		tokenBalances[_tokenIn] = nextBalance_;
		amountTokenIn_ = (nextBalance_ - prevBalance_);
	}

	/**
	 * @notice internal function that transfers tokens out to the receiver
	 * @param _tokenOut address of the token transferred out
	 * @param _amountOut amount of _token to send out of the vault
	 * @param _receiver address that will receive the tokens
	 */
	function _transferOut(address _tokenOut, uint256 _amountOut, address _receiver) private {
		IERC20(_tokenOut).transfer(_receiver, _amountOut);
		// update the tokenBalance of the outgoing token
		tokenBalances[_tokenOut] = IERC20(_tokenOut).balanceOf(address(this));
	}

	function _updateTokenBalance(address _tokenToUpdate) private {
		tokenBalances[_tokenToUpdate] = IERC20(_tokenToUpdate).balanceOf(address(this));
	}

	/**
	 * @notice accounting function that increases the registered/realized WLP assets
	 * @dev this is a very important function to understand! this function increases the value of WLP
	 * @dev note that this is different from the tokenBalances! poolAmounts belong to the WLPs
	 * @param _tokenIn  address of the token
	 * @param _amountToIncrease  amount to increment of the tokens poolAmounts
	 */
	function _increasePoolAmount(address _tokenIn, uint256 _amountToIncrease) private {
		unchecked {
			poolAmounts[_tokenIn] += _amountToIncrease;
		}
		// if the registered pool amounts are larger than the actual balance of the token, something went wrong in the accounting because this is technically a impossability - by definition the poolAmounts registered to WLPs will always be lower as the balance, even if the WLPs are in a net loss (historically). So this check is in place to essentially check if the vault isn't broken/exploited.
		_validate(poolAmounts[_tokenIn] <= IERC20(_tokenIn).balanceOf(address(this)), 11);
	}

	/**
	 * @notice accounting function that decreases the registered/realized WLP assets
	 * @dev this is a very important function to understand! this function decreases the value of WLP
	 * @dev note that this is different from the tokenBalances! poolAmounts belong to the WLPs
	 * @param _tokenOut  address of the token
	 * @param _amountToDecrease  amount to be deducted of the tokens poolAmounts
	 */
	function _decreasePoolAmount(address _tokenOut, uint256 _amountToDecrease) private {
		require(poolAmounts[_tokenOut] >= _amountToDecrease, "Vault: poolAmount exceeded");
		unchecked {
			poolAmounts[_tokenOut] -= _amountToDecrease;
		}
		// check if circuit breaker is enable in vault config
		if (circuitBreakerEnabled) {
			// if cb is enbaled, check if the poolAmounts are below the circuitBreakerAmounts
			if (poolAmounts[_tokenOut] < circuitBreakerAmounts[_tokenOut]) {
				// if so, call the WLP manager (whom will enforce a CB policy onto the vault)
				IWLPManager(wlpManagerAddress).circuitBreakerTrigger(_tokenOut);
			}
		}
	}

	/**
	 * @dev this function should always be called after the _decreasePoolAmount is called!
	 * @param _token address of the token
	 */
	function _validateBufferAmount(address _token) private view {
		if (poolAmounts[_token] < bufferAmounts[_token]) {
			revert TokenBufferViolation(_token);
		}
	}

	/**
	 * @notice increases the registered token-debt (in USDW)
	 * @dev for each asset entering the vault, we register its USD value at the time it entered, the main use of this being that we can set max exposure in USD to a certain asset (for this maxUsdwAmount_ needs to be set)
	 * @param _token  address of the token
	 * @param _amountToIncrease  amount the tokens maxUsdwAmounts mapping will be incremented
	 */
	function _increaseUsdwAmount(address _token, uint256 _amountToIncrease) private {
		unchecked {
			usdwAmounts[_token] += _amountToIncrease;
		}
		uint256 maxUsdwAmount_ = maxUsdwAmounts[_token];
		if (maxUsdwAmount_ != 0) {
			_validate(usdwAmounts[_token] <= maxUsdwAmount_, 8);
		}
	}

	/**
	 * @notice decreases the registered token-debt (in USDW) of the vault
	 * @param _token  address of the token
	 * @param _amountToDecrease  amount the tokens maxUsdwAmounts mapping will be deducted
	 */
	function _decreaseUsdwAmount(address _token, uint256 _amountToDecrease) private {
		uint256 value_ = usdwAmounts[_token];
		// since USDW can be minted using multiple assets
		// it is possible for the USDW debt for a single asset to be less than zero
		// the USDW debt is capped to zero for this case
		if (value_ <= _amountToDecrease) {
			delete usdwAmounts[_token];
			return;
		} else {
			unchecked {
				usdwAmounts[_token] = (value_ - _amountToDecrease);
			}
		}
	}

	/**
	 * @notice internal require that checks if the caller is a manager
	 */
	function _validateManager() private view {
		if (inManagerMode) {
			_validate(isManager[_msgSender()], 7);
		}
	}

	/**
	 * @notice internal require checker to emit certain error messages
	 * @dev using internal function as to reduce contract size
	 */
	function _validate(bool _condition, uint256 _errorCode) private view {
		require(_condition, errors[_errorCode]);
	}

	/**
	 * @notice internal function that reverts if the oracle price of an asset is zero
	 */
	function _revertIfZero(uint256 _value) internal pure {
		if (_value == 0) {
			revert PriceZero();
		}
	}

	/*==================== View functions *====================*/

	/**
	 * @notice returns the upperbound/maximum price of a asset
	 * @dev the return value is scaled 1e30 (so $1 = 1e30)
	 * @param _token address of the token/asset
	 * @return priceUpperBound_ the amount of USD(scaled 1e30) 1 token unit of _token is worth using the upper price bound of the GMX oracle
	 */
	function getMaxPrice(
		address _token
	) public view override returns (uint256 priceUpperBound_) {
		// note: the pricefeed being called is managed by GMX
		priceUpperBound_ = IOracleRouter(priceOracleRouter).getPriceMax(_token);
		_revertIfZero(priceUpperBound_);
	}

	/**
	 * @notice returns the lowerbound/minimum price of the wlp asset
	 * @dev the return value is scaled 1e30 (so $1 = 1e30)
	 * @param _token address of the token/asset
	 * @return priceLowerBound_ the amount of USD(scaled 1e30) 1 token unit of _token is worth using the lower price bound of the GMX oracle
	 */
	function getMinPrice(
		address _token
	) public view override returns (uint256 priceLowerBound_) {
		// note: the pricefeed being called is managed by GMX
		priceLowerBound_ = IOracleRouter(priceOracleRouter).getPriceMin(_token);
		_revertIfZero(priceLowerBound_);
	}

	/**
	 * @notice returns the amount of a specitic tokens can be redeemed for a certain amount of USDW
	 * @param _tokenOut address of the token/asset that to be redeemed
	 * @param _usdwAmount amount of USDW that would be burned for the token/asset
	 * @return redemptionAmount_ the amount of the _tokenOut that can be redeemed when burning the _usdwAmount in the vault
	 */
	function getRedemptionAmount(
		address _tokenOut,
		uint256 _usdwAmount
	) public view override returns (uint256 redemptionAmount_) {
		redemptionAmount_ = _adjustForDecimals(
			_usdwAmount,
			PRICE_PRECISION,
			getMaxPrice(_tokenOut),
			USDW_DECIMALS,
			tokenDecimals[_tokenOut]
		);
	}

	/**
	 * utility function that helps scaling different tokens when expressed in each others equivalent value
	 */
	function _adjustForDecimals(
		uint256 _amountA,
		uint256 _amountB,
		uint256 _amountDiv,
		uint256 _decimalsTokenIn, // decimals of incoming token
		uint256 _decimalsTokenOut // decimals of outgoing token
	) internal pure returns (uint256 scaledAmount_) {
		if (_decimalsTokenOut >= _decimalsTokenIn) {
			scaledAmount_ = Math.mulDiv(
				_amountA * 10 ** (_decimalsTokenOut - _decimalsTokenIn),
				_amountB,
				_amountDiv
			);
		} else {
			scaledAmount_ = Math.mulDiv(
				_amountA,
				_amountB,
				_amountDiv * 10 ** (_decimalsTokenIn - _decimalsTokenOut)
			);
		}
	}

	/**
	 * @notice function returns how much USD a certain amount of a token is worth
	 * @dev the _tokenToPrice needs to be available in the GMX pricefeed
	 * @param _tokenToPrice address of the token to price/value
	 * @param _tokenAmount amount of the token you want to know the USD value of
	 * @return usdAmount_ amount of USD(1e30 scaled) a _tokenAmount is worth using the lower price bound of the oracle
	 */
	function tokenToUsdMin(
		address _tokenToPrice,
		uint256 _tokenAmount
	) external view override returns (uint256 usdAmount_) {
		// using the lower price bound of the asset
		usdAmount_ =
			(_tokenAmount * getMinPrice(_tokenToPrice)) /
			(10 ** tokenDecimals[_tokenToPrice]);
	}

	/**
	 * @notice function that returns the amount of tokens a certain amount of USD is worth - pricing by lower bound
	 * @dev this function uses the lower bound price, so the price/value for outgoing assets this is at the benefit of the WLPs
	 * @param _tokenToPrice address of the token to price/value
	 * @param _usdAmount amount of USD (in 1e30) you want to price
	 * @return tokenAmountMax_ amount of the token the _usdAmount is worth
	 */
	function usdToTokenMax(
		address _tokenToPrice,
		uint256 _usdAmount
	) external view returns (uint256 tokenAmountMax_) {
		// using the lower price bound of the asset
		tokenAmountMax_ = usdToToken(_tokenToPrice, _usdAmount, getMinPrice(_tokenToPrice));
	}

	/**
	 * @notice function that returns the amount of tokens a certain amount of USD is worth - pricing by upper bound
	 * @dev this function uses the upper bound price, so the price/value is for incoming assets at the benefit of the WLPs
	 * @param _tokenToPrice address of the token being queried
	 * @param _usdAmount amount of USD (in 1e30) you want to price
	 * @return tokenAmountMin_ amount of the token the _usdAmount is worth
	 */
	function usdToTokenMin(
		address _tokenToPrice,
		uint256 _usdAmount
	) external view returns (uint256 tokenAmountMin_) {
		tokenAmountMin_ = usdToToken(_tokenToPrice, _usdAmount, getMaxPrice(_tokenToPrice));
	}

	/**
	 * @notice function that returns how much of a token is worth a certain amount of USD
	 * @dev note: 1 USD value is 1e30 when plugged into _usdAmount
	 * @param _token address of the token
	 * @param _usdAmount amount of usd (1 usd = 1e30)
	 * @param _priceToken the price of the token
	 * @return tokenAmount_ amount of units of a token
	 */
	function usdToToken(
		address _token,
		uint256 _usdAmount,
		uint256 _priceToken
	) public view returns (uint256 tokenAmount_) {
		uint256 decimals_ = tokenDecimals[_token];
		tokenAmount_ = ((_usdAmount * (10 ** decimals_)) / _priceToken);
	}

	function allWhitelistedTokensLength()
		external
		view
		override
		returns (uint256 whitelistedLength_)
	{
		whitelistedLength_ = allWhitelistedTokensSet.length();
	}

	function allWhitelistedTokens(uint256 _index)
		external
		view
		override
		returns (address token_)
	{
		token_ = allWhitelistedTokensSet.at(_index);
	}

	/**
	 * @notice returns the aggregated count of a token (total in all time, total out all time)
	 * @param token_ address of the token to return the aggragated total of
	 */
	function returnTotalOutAndIn(
		address token_
	) external view returns (uint256 totalOutAllTime_, uint256 totalInAllTime_) {
		return (totalOut_[token_], totalIn_[token_]);
	}

	/*==================== View functions Winr/JB *====================*/

	/**
	 * @notice returns the usd value of all the assets in the wlp combined (only the realized ones)
	 * @dev take note that usd value is scaled by 1e30 and not 1e18 (1e30 = $1)
	 */
	function getReserve() external view override returns (uint256 totalReserveValue_) {
		totalReserveValue_ = (IWLPManager(wlpManagerAddress).getAum(false) -
			IWLPManager(wlpManagerAddress).reserveDeduction());
	}

	/**
	 * @notice returns the USD(scaled 1e30) value of 1 WLP token
	 */
	function getWlpValue() external view returns (uint256 wlpValue_) {
		wlpValue_ = IWLPManager(wlpManagerAddress).getPriceWlp(false);
	}

	/**
	 * @notice function converts equivalent value from tokenIn to tokenOut
	 * @dev this is mainly used for a multi-asset payout, the VM/Game represents a players winnings in its wagerAsset, with help of this function we convert the wagerAsset into the requested winningAsset by the plater
	 * @param _tokenInAddress address of the token the value is expressed in
	 * @param _tokenOutAddress address of the token you want this value to be expressed in
	 * @param _amountIn amount of tokenIn (that you want to convert to a token amount in _tokenInAddress)
	 * @return amountTokenOut_ amount of tokens _tokenOutAddress
	 */
	function _amountOfTokenForToken(
		address _tokenInAddress,
		address _tokenOutAddress,
		uint256 _amountIn
	) internal view returns (uint256 amountTokenOut_) {
		{
			uint256 priceOut_ = getMaxPrice(_tokenOutAddress);
			uint256 priceIn_ = getMinPrice(_tokenInAddress);
			uint256 decimalsIn_ = tokenDecimals[_tokenInAddress];
			uint256 decimalsOut_ = tokenDecimals[_tokenOutAddress];
			if (decimalsOut_ >= decimalsIn_) {
				amountTokenOut_ = Math.mulDiv(
					_amountIn * 10 ** (decimalsOut_ - decimalsIn_),
					priceIn_,
					priceOut_
				);
			} else {
				amountTokenOut_ = Math.mulDiv(
					_amountIn,
					priceIn_,
					priceOut_ * 10 ** (decimalsIn_ - decimalsOut_)
				);
			}
		}
	}

	/**
	 * @notice returns how much value (in usd) of a certain token the vault should have according to its weight
	 * @dev this function is used to determine if a certain asset is scarce in the pool
	 * @param _token address of the token
	 */
	function getTargetUsdwAmount(
		address _token
	) external view override returns (uint256 usdwAmount_) {
		uint256 supply_ = IERC20(usdw).totalSupply();
		if (supply_ == 0) {
			return 0;
		}
		usdwAmount_ = ((tokenWeights[_token] * supply_) / totalTokenWeights);
	}

	/*==================== Timelocked / controversial functions (onlyTimelockGovernance) *====================*/

	/**
	 * @notice migration function to a new vault
	 * @dev this is a timelocked feature since it moves WLP owned vaul assets to a different address
	 * @param _newVault address of the new vault
	 * @param _token address of the token to migrate
	 * @param _amount amount to migrate the token to
	 * @param _upgrade bool singalling if the balances need to be updated
	 */
	function upgradeVault(
		address _newVault,
		address _token,
		uint256 _amount,
		bool _upgrade
	) external onlyTimelockGovernance {
		IERC20(_token).transfer(_newVault, _amount);
		if (_upgrade) {
			_decreasePoolAmount(_token, _amount);
			_updateTokenBalance(_token);
		}
	}

	/**
	 * @notice function that changes the feecollector contract
	 * @param _feeCollector address of the (new) feecollector
	 */
	function setFeeCollector(address _feeCollector) external onlyTimelockGovernance {
		feeCollector = _feeCollector;
	}

	/**
	 * @notice function that changes the vaultmanager contract
	 * @param _vaultManagerAddress address of the (new) vaultmanager
	 */
	function setVaultManagerAddress(
		address _vaultManagerAddress,
		bool _setting
	) external override onlyTimelockGovernance {
		isVaultManager[_vaultManagerAddress] = _setting;
	}

	/**
	 * @dev due to the imporance of the priceOracleRouter, this function is protected by the timelocked modifier
	 * @param _priceOracleRouter address of the price feed
	 */
	function setPriceFeedRouter(
		address _priceOracleRouter
	) external override onlyTimelockGovernance {
		priceOracleRouter = _priceOracleRouter;
	}

	/**
	 * @notice configuration of the circuit breaker level/amount
	 * @param _token address of the token to set the cb for
	 * @param _amount trigger amount of the cb in units of the token
	 */
	function setCircuitBreakerAmount(address _token, uint256 _amount) external onlyManager {
		circuitBreakerAmounts[_token] = _amount;
	}

	/*==================== Emergency intervention functions (onlyEmergency) *====================*/

	/**
	 * @notice configuration function that sets the types of fees charged by the vault
	 * @dev remember that 1e4 = 100% (so scaled by 1e4)
	 * @param _taxBasisPoints tax basis points (incentive/punish (re/un)balancing)
	 * @param _stableTaxBasisPoints stable swap basis points
	 * @param _mintBurnFeeBasisPoints basis point tax/fee for minting/burning
	 * @param _swapFeeBasisPoints swap fee basis piint
	 * @param _stableSwapFeeBasisPoints base swap fee for stable -> stable swaps
	 * @param _hasDynamicFees bool signifiying if the dynamic swap fee mechanism needs to be enabled
	 */
	function setFees(
		uint256 _taxBasisPoints,
		uint256 _stableTaxBasisPoints,
		uint256 _mintBurnFeeBasisPoints,
		uint256 _swapFeeBasisPoints,
		uint256 _stableSwapFeeBasisPoints,
		uint256 _minimumBurnMintFee,
		bool _hasDynamicFees
	) external override onlyGovernance {
		_validate(_taxBasisPoints <= MAX_FEE_BASIS_POINTS, 2);
		_validate(_stableTaxBasisPoints <= MAX_FEE_BASIS_POINTS, 3);
		_validate(_mintBurnFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 4);
		_validate(_swapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 5);
		_validate(_stableSwapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 6);
		_validate(_minimumBurnMintFee <= MAX_FEE_BASIS_POINTS, 6);
		taxBasisPoints = _taxBasisPoints;
		stableTaxBasisPoints = _stableTaxBasisPoints;
		mintBurnFeeBasisPoints = _mintBurnFeeBasisPoints;
		swapFeeBasisPoints = _swapFeeBasisPoints;
		stableSwapFeeBasisPoints = _stableSwapFeeBasisPoints;
		minimumBurnMintFee = _minimumBurnMintFee;
		hasDynamicFees = _hasDynamicFees;
	}

	/**
	 * @notice economic configuration function to set a token confugration
	 * @param _token address of the token
	 * @param _tokenDecimals amount of decimals that the token is denominated in
	 * @param _tokenWeight the weight (relative) the token will have in the pool/vault
	 * @param _maxUsdwAmount maximum USDW debt of the token that the vault will maximally hold
	 * @param _isStable if the token is a stable coin/token
	 */
	function setTokenConfig(
		address _token,
		uint256 _tokenDecimals,
		uint256 _tokenWeight,
		uint256 _maxUsdwAmount,
		bool _isStable
	) external override onlyGovernance {
		// increment token count for the first time
		if (!allWhitelistedTokensSet.contains(_token)) {
			allWhitelistedTokensSet.add(_token);
		}
		uint256 _totalTokenWeights = totalTokenWeights;
		_totalTokenWeights -= tokenWeights[_token];
		_whitelistedTokens[_token] = true;
		tokenDecimals[_token] = _tokenDecimals;
		tokenWeights[_token] = _tokenWeight;
		maxUsdwAmounts[_token] = _maxUsdwAmount;
		stableTokens[_token] = _isStable;
		totalTokenWeights = (_totalTokenWeights + _tokenWeight);
		// check if the oracle returns a price for this token
		getMaxPrice(_token);
	}

	/**
	 * @notice function that deletes the configuration of a certain token
	 * @param _token address of the token
	 */
	function clearTokenConfig(address _token) external onlyGovernance {
		_validate(allWhitelistedTokensSet.contains(_token), 9);
		totalTokenWeights -= tokenWeights[_token];
		allWhitelistedTokensSet.remove(_token);
		_whitelistedTokens[_token] = false;
		delete tokenDecimals[_token];
		delete tokenWeights[_token];
		delete maxUsdwAmounts[_token];
		delete stableTokens[_token];
	}

	/**
	 * @notice update the token balance sync in the contract
	 * @dev this function should be called in cases where for some reason tokens end up on the contract
	 * @param _token address of the token to be updated
	 */
	function updateTokenBalance(address _token) external onlyEmergency {
		_updateTokenBalance(_token);
	}

	/**
	 * @notice function that flips if traders can swap/trade with the vault or not
	 * @dev when enabled no external entities will be able to swap
	 * @param _isSwapEnabled what to flip the isSwapEnabled to
	 */
	function setIsSwapEnabled(bool _isSwapEnabled) external override onlyEmergency {
		isSwapEnabled = _isSwapEnabled;
	}

	/**
	 * @notice function that flips if the vault performs payouts or not
	 * @param _setting what to flip the payoutsHalted to
	 */
	function setPayoutHalted(bool _setting) external onlyEmergency {
		payoutsHalted = _setting;
	}

	/*==================== Configuration functions non-economic / operational (onlyGovernance) *====================*/

	function setVaultUtils(IVaultUtils _vaultUtils) external override onlyGovernance {
		vaultUtils = _vaultUtils;
	}

	/**
	 * @notice configuration function that can change/add a config function
	 * @param _errorCode uint pointing to a certain error code
	 * @param _error string of new error code
	 */
	function setError(uint256 _errorCode, string calldata _error) external override {
		_validate(!isInitialized, 1);
		errors[_errorCode] = _error;
	}

	function setAsideReferral(
		address _token,
		uint256 _amountSetAside
	) external override onlyManager {
		unchecked {
			referralReserves[_token] += _amountSetAside;
		}
	}

	function removeAsideReferral(
		address _token,
		uint256 _amountRemoveAside
	) external override onlyManager {
		if (referralReserves[_token] >= _amountRemoveAside) {
			referralReserves[_token] -= _amountRemoveAside;
		}
	}

	function setRouter(address _router) external onlyGovernance {
		router = _router;
	}

	/*==================== Configuration functions Economic (onlyGovernance / onlyManager) *====================*/

	/**
	 * @notice enables circuit breaker mechanism
	 */
	function setCircuitBreakerEnabled(bool _setting) external onlyManager {
		circuitBreakerEnabled = _setting;
	}

	/**
	 * @notice configuration function to set the amount of wagerFees
	 * @param _wagerFee uint configuration for the wagerfee
	 */
	function setWagerFee(uint256 _wagerFee) external override onlyManager {
		require(_wagerFee <= MAX_WAGER_FEE, "Vault: Wagerfee exceed maximum");
		wagerFeeBasisPoints = _wagerFee;
		emit WagerFeeChanged(_wagerFee);
	}

	/**
	 * @notice enables managed mode - when enabled only addresses configured as mananager can mint usdw (so wlpManager for example)
	 */
	function setInManagerMode(bool _inManagerMode) external override onlyGovernance {
		inManagerMode = _inManagerMode;
	}

	/**
	 * @notice configuration function that can add/remove contracts/addressees that are allowed to mint/redeem USDW
	 * @dev take note that the WLPManager mints the WLP, the vault mints USDW
	 * @param _manager address of the manager to add/remove
	 * @param _isManager bool that determines if a manager is added or removed
	 */
	function setManager(
		address _manager,
		bool _isManager,
		bool _isWLPManager
	) external override onlyGovernance {
		isManager[_manager] = _isManager;
		if (_isWLPManager) {
			wlpManagerAddress = _manager;
		}
	}

	/**
	 * @notice configuration function to set a minimum amount of a certain asset
	 * @param _token address of the token
	 * @param _amount buffer amount to be set
	 */
	function setBufferAmount(address _token, uint256 _amount) external override onlyGovernance {
		bufferAmounts[_token] = _amount;
	}

	/**
	 * @param _token address of the token
	 * @param _amount amount of the USDW to set
	 */
	function setUsdwAmount(address _token, uint256 _amount) external override onlyGovernance {
		uint256 usdwAmount_ = usdwAmounts[_token];
		if (_amount > usdwAmount_) {
			_increaseUsdwAmount(_token, (_amount - usdwAmount_));
		} else {
			_decreaseUsdwAmount(_token, (usdwAmount_ - _amount));
		}
	}

	/**
	 * @notice configuration function to edit/change poolbalances
	 * @dev note that this function can drascitally change the WLP value
	 * @param _token address of the token
	 * @param _amount amount to configure in poolAmounts
	 */
	function setPoolBalance(address _token, uint256 _amount) external onlyGovernance {
		poolAmounts[_token] = _amount;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IUSDW {
	event VaultAdded(address vaultAddress);

	event VaultRemoved(address vaultAddress);

	function addVault(address _vault) external;

	function removeVault(address _vault) external;

	function mint(address _account, uint256 _amount) external;

	function burn(address _account, uint256 _amount) external;
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

	function isInitialized() external view returns (bool);

	function isSwapEnabled() external view returns (bool);

	function setVaultUtils(IVaultUtils _vaultUtils) external;

	function setError(uint256 _errorCode, string calldata _error) external;

	function router() external view returns (address);

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

	function deposit(address _tokenIn, address _receiver) external returns (uint256);

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
		address[2] calldata _tokens,
		address _escrowAddress,
		uint256 _escrowAmount,
		address _recipient,
		uint256 _totalAmount
	) external;

	function payin(address _inputToken, address _escrowAddress, uint256 _escrowAmount) external;

	function setAsideReferral(address _token, uint256 _amount) external;

	function removeAsideReferral(address _token, uint256 _amountRemoveAside) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IOracleRouter {
	function getPrice(
		address _token,
		bool _maximise,
		bool _includeAmmPrice,
		bool _useSwapPricing
	) external view returns (uint256);

	function getPriceMax(address _token) external view returns (uint256);

	function getPriceMin(address _token) external view returns (uint256);

	function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);

	function isAdjustmentAdditive(address _token) external view returns (bool);

	function adjustmentBasisPoints(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev This contract designed to easing token transfers broadcasting information between contracts
interface IVaultManager {
	/// @notice escrow tokens into the manager
	/// @param _token one of the whitelisted tokens which is collected in settings
	/// @param _sender holder of tokens
	/// @param _amount the amount of token
	function escrow(address _token, address _sender, uint256 _amount) external;

	/// @notice release some amount of escrowed tokens
	/// @param _token one of the whitelisted tokens which is collected in settings
	/// @param _recipient holder of tokens
	/// @param _amount the amount of token
	function payback(address _token, address _recipient, uint256 _amount) external;

	/// @notice lets vault get wager amount from escrowed tokens
	/// @param _token one of the whitelisted tokens which is collected in settings
	/// @param _amount the amount of token
	function getEscrowedTokens(address _token, uint256 _amount) external;

	/// @notice lets vault get wager amount from escrowed tokens
	function payout(
		address[2] memory _tokens,
		address _recipient,
		uint256 _escrowAmount,
		uint256 _totalAmount
	) external;

	/// @notice lets vault get wager amount from escrowed tokens
	function payin(address _token, uint256 _escrowAmount) external;

	/// @notice transfers any whitelisted token into here
	/// @param _token one of the whitelisted tokens which is collected in settings
	/// @param _sender holder of tokens
	/// @param _amount the amount of token
	function transferIn(address _token, address _sender, uint256 _amount) external;

	/// @notice transfers any whitelisted token to recipient
	/// @param _token one of the whitelisted tokens which is collected in settings
	/// @param _recipient of tokens
	/// @param _amount the amount of token
	function transferOut(address _token, address _recipient, uint256 _amount) external;

	/// @notice transfers WLP tokens from this contract to Fee Collector and triggers Fee Collector
	/// @param _fee the amount of WLP sends to Fee Controller
	function transferWLPFee(uint256 _fee) external;

	function getMaxWager() external view returns (uint256);
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