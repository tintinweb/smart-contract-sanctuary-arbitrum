// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20, IERC4626 } from "openzeppelin/token/ERC20/extensions/ERC4626.sol";
import { SafeERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";

import { PrizeVault } from "./PrizeVault.sol";

/// @title  PoolTogether V5 Prize Vault Factory
/// @author PoolTogether Inc. & G9 Software Inc.
/// @notice Factory contract for deploying new prize vaults using a standard underlying ERC4626 yield vault.
contract PrizeVaultFactory {
    using SafeERC20 for IERC20;

    ////////////////////////////////////////////////////////////////////////////////
    // Events
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when a new PrizeVault has been deployed by this factory.
    /// @param vault The vault that was deployed
    /// @param yieldVault The underlying yield vault
    /// @param prizePool The prize pool the vault contributes to
    /// @param name The name of the vault token
    /// @param symbol The symbol for the vault token
    event NewPrizeVault(
        PrizeVault indexed vault,
        IERC4626 indexed yieldVault,
        PrizePool indexed prizePool,
        string name,
        string symbol
    );

    ////////////////////////////////////////////////////////////////////////////////
    // Variables
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice List of all vaults deployed by this factory.
    PrizeVault[] public allVaults;

    /// @notice Mapping to verify if a Vault has been deployed via this factory.
    mapping(address vault => bool deployedByFactory) public deployedVaults;

    /// @notice Mapping to store deployer nonces for CREATE2
    mapping(address deployer => uint256 nonce) public deployerNonces;

    ////////////////////////////////////////////////////////////////////////////////
    // External Functions
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Deploy a new vault
    /// @dev Emits a `NewPrizeVault` event with the vault details.
    /// @dev The caller MUST approve this factory to spend underlying assets equal to `YIELD_BUFFER` so the yield
    /// buffer can be filled on deployment. This value is unrecoverable and is expected to be insignificant.
    /// @dev The yield buffer is expected to be of insignificant value and is used to cover rounding
    /// errors on deposits and withdrawals. Yield is expected to accrue faster than the yield buffer
    /// can be reasonably depleted.
    ///
    /// The yield buffer should be set as high as possible while still being considered
    /// insignificant for the lowest precision per dollar asset that is expected to be supported.
    /// 
    /// Precision per dollar (PPD) can be calculated by: (10 ^ DECIMALS) / ($ value of 1 asset).
    /// For example, USDC has a PPD of (10 ^ 6) / ($1) = 10e6 p/$.
    /// 
    /// As a rule of thumb, assets with lower PPD than USDC should not be assumed to be compatible since
    /// the potential loss of a single unit rounding error is likely too high to be made up by yield at 
    /// a reasonable rate. Actual results may vary based on expected gas costs, asset fluctuation, and
    /// yield accrual rates.
    ///
    /// This factory will transfer an amount of assets equal to the yield buffer from the deployer to the
    /// prize vault on deployment to cover the initial buffer. For example, if you are deploying a USDC
    /// vault and the yield buffer is set to 1e5, you will have to approve this factory to spend 1e5
    /// USDC ($0.10) to be sent to the prize vault during deployment. Assuming there is no additional 
    /// precision loss in the yield vault, a 1e5 yield buffer will cover the first 100k rounding errors on
    /// deposits and withdraws and is not recoverable by the deployer.
    ///
    /// If the yield buffer is depleted on a vault, the vault will prevent any further 
    /// deposits if it would result in a rounding error and any rounding errors incurred by withdrawals
    /// will not be covered by yield. The yield buffer will be replenished automatically as yield accrues
    /// on deposits.
    /// @param _name Name of the ERC20 share minted by the vault
    /// @param _symbol Symbol of the ERC20 share minted by the vault
    /// @param _yieldVault Address of the ERC4626 vault in which assets are deposited to generate yield
    /// @param _prizePool Address of the PrizePool that computes prizes
    /// @param _claimer Address of the claimer
    /// @param _yieldFeeRecipient Address of the yield fee recipient
    /// @param _yieldFeePercentage Yield fee percentage
    /// @param _yieldBuffer The size of the prize vault yield buffer
    /// @param _owner Address that will gain ownership of this contract
    /// @return PrizeVault The newly deployed PrizeVault
    function deployVault(
      string memory _name,
      string memory _symbol,
      IERC4626 _yieldVault,
      PrizePool _prizePool,
      address _claimer,
      address _yieldFeeRecipient,
      uint32 _yieldFeePercentage,
      uint256 _yieldBuffer,
      address _owner
    ) external returns (PrizeVault) {
        PrizeVault _vault = new PrizeVault{
            salt: keccak256(abi.encode(msg.sender, deployerNonces[msg.sender]++))
        }(
            _name,
            _symbol,
            _yieldVault,
            _prizePool,
            _claimer,
            _yieldFeeRecipient,
            _yieldFeePercentage,
            _yieldBuffer,
            _owner
        );

        // A donation to fill the yield buffer is made to ensure that early depositors have
        // rounding errors covered in the time before yield is actually generated.
        if (_yieldBuffer > 0) {
            IERC20(_vault.asset()).safeTransferFrom(msg.sender, address(_vault), _yieldBuffer);
        }

        allVaults.push(_vault);
        deployedVaults[address(_vault)] = true;

        emit NewPrizeVault(
            _vault,
            _yieldVault,
            _prizePool,
            _name,
            _symbol
        );

        return _vault;
    }

    /// @notice Total number of vaults deployed by this factory.
    /// @return uint256 Number of vaults deployed by this factory.
    function totalVaults() external view returns (uint256) {
        return allVaults.length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../utils/SafeERC20.sol";
import "../../../interfaces/IERC4626.sol";
import "../../../utils/math/Math.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * [CAUTION]
 * ====
 * In empty (or nearly empty) ERC-4626 vaults, deposits are at high risk of being stolen through frontrunning
 * with a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well as unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * Since v4.9, this implementation uses virtual assets and shares to mitigate that risk. The `_decimalsOffset()`
 * corresponds to an offset in the decimal representation between the underlying asset's decimals and the vault
 * decimals. This offset also determines the rate of virtual shares to virtual assets in the vault, which itself
 * determines the initial exchange rate. While not fully preventing the attack, analysis shows that the default offset
 * (0) makes it non-profitable, as a result of the value being captured by the virtual shares (out of the attacker's
 * donation) matching the attacker's expected gains. With a larger offset, the attack becomes orders of magnitude more
 * expensive than it is profitable. More details about the underlying math can be found
 * xref:erc4626.adoc#inflation-attack[here].
 *
 * The drawback of this approach is that the virtual shares do capture (a very small) part of the value being accrued
 * to the vault. Also, if the vault experiences losses, the users try to exit the vault, the virtual shares and assets
 * will cause the first user to exit to experience reduced losses in detriment to the last users that will experience
 * bigger losses. Developers willing to revert back to the pre-v4.9 behavior just need to override the
 * `_convertToShares` and `_convertToAssets` functions.
 *
 * To learn more, check out our xref:ROOT:erc4626.adoc[ERC-4626 guide].
 * ====
 *
 * _Available since v4.7._
 */
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20 private immutable _asset;
    uint8 private immutable _underlyingDecimals;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20 asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _underlyingDecimals + _decimalsOffset();
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { SafeCast } from "openzeppelin/utils/math/SafeCast.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { SD59x18, convert, sd } from "prb-math/SD59x18.sol";
import { SD1x18, unwrap, UNIT } from "prb-math/SD1x18.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";

import { DrawAccumulatorLib, Observation, MAX_OBSERVATION_CARDINALITY } from "./libraries/DrawAccumulatorLib.sol";
import { TieredLiquidityDistributor, Tier } from "./abstract/TieredLiquidityDistributor.sol";
import { TierCalculationLib } from "./libraries/TierCalculationLib.sol";

/// @notice Thrown when the prize pool is constructed with a first draw open timestamp that is in the past
error FirstDrawOpensInPast();

/// @notice Thrown when the Twab Controller has an incompatible period length
error IncompatibleTwabPeriodLength();

/// @notice Thrown when the Twab Controller has an incompatible period offset
error IncompatibleTwabPeriodOffset();

/// @notice Thrown when someone tries to set the draw manager with the zero address
error DrawManagerIsZeroAddress();

/// @notice Thrown when the passed creator is the zero address
error CreatorIsZeroAddress();

/// @notice Thrown when the caller is not the deployer.
error NotDeployer();

/// @notice Thrown when the range start draw id is computed with range of zero
error RangeSizeZero();

/// @notice Thrown if the prize pool has shutdown
error PrizePoolShutdown();

/// @notice Thrown if the prize pool is not shutdown
error PrizePoolNotShutdown();

/// @notice Thrown when someone tries to withdraw too many rewards.
/// @param requested The requested reward amount to withdraw
/// @param available The total reward amount available for the caller to withdraw
error InsufficientRewardsError(uint256 requested, uint256 available);

/// @notice Thrown when an address did not win the specified prize on a vault when claiming.
/// @param vault The vault address
/// @param winner The address checked for the prize
/// @param tier The prize tier
/// @param prizeIndex The prize index
error DidNotWin(address vault, address winner, uint8 tier, uint32 prizeIndex);

/// @notice Thrown when the prize being claimed has already been claimed
/// @param vault The vault address
/// @param winner The address checked for the prize
/// @param tier The prize tier
/// @param prizeIndex The prize index
error AlreadyClaimed(address vault, address winner, uint8 tier, uint32 prizeIndex);

/// @notice Thrown when the claim reward exceeds the maximum.
/// @param reward The reward being claimed
/// @param maxReward The max reward that can be claimed
error RewardTooLarge(uint256 reward, uint256 maxReward);

/// @notice Thrown when the contributed amount is more than the available, un-accounted balance.
/// @param amount The contribution amount that is being claimed
/// @param available The available un-accounted balance that can be claimed as a contribution
error ContributionGTDeltaBalance(uint256 amount, uint256 available);

/// @notice Thrown when the withdraw amount is greater than the available reserve.
/// @param amount The amount being withdrawn
/// @param reserve The total reserve available for withdrawal
error InsufficientReserve(uint104 amount, uint104 reserve);

/// @notice Thrown when the winning random number is zero.
error RandomNumberIsZero();

/// @notice Thrown when the draw cannot be awarded since it has not closed.
/// @param drawClosesAt The timestamp in seconds at which the draw closes
error AwardingDrawNotClosed(uint48 drawClosesAt);

/// @notice Thrown when prize index is greater or equal to the max prize count for the tier.
/// @param invalidPrizeIndex The invalid prize index
/// @param prizeCount The prize count for the tier
/// @param tier The tier number
error InvalidPrizeIndex(uint32 invalidPrizeIndex, uint32 prizeCount, uint8 tier);

/// @notice Thrown when there are no awarded draws when a computation requires an awarded draw.
error NoDrawsAwarded();

/// @notice Thrown when the Prize Pool is constructed with a draw timeout of zero
error DrawTimeoutIsZero();

/// @notice Thrown when the Prize Pool is constructed with a draw timeout greater than the grand prize period draws
error DrawTimeoutGTGrandPrizePeriodDraws();

/// @notice Thrown when attempting to claim from a tier that does not exist.
/// @param tier The tier number that does not exist
/// @param numberOfTiers The current number of tiers
error InvalidTier(uint8 tier, uint8 numberOfTiers);

/// @notice Thrown when the caller is not the draw manager.
/// @param caller The caller address
/// @param drawManager The drawManager address
error CallerNotDrawManager(address caller, address drawManager);

/// @notice Thrown when someone tries to claim a prize that is zero size
error PrizeIsZero();

/// @notice Thrown when someone tries to claim a prize, but sets the reward recipient address to the zero address.
error RewardRecipientZeroAddress();

/// @notice Thrown when a claim is attempted after the claiming period has expired.
error ClaimPeriodExpired();

/// @notice Thrown when anyone but the creator calls a privileged function
error OnlyCreator();

/// @notice Thrown when the draw manager has already been set
error DrawManagerAlreadySet();

/// @notice Thrown when the grand prize period is too large
/// @param grandPrizePeriodDraws The set grand prize period
/// @param maxGrandPrizePeriodDraws The max grand prize period
error GrandPrizePeriodDrawsTooLarge(uint24 grandPrizePeriodDraws, uint24 maxGrandPrizePeriodDraws);

/// @notice Constructor Parameters
/// @param prizeToken The token to use for prizes
/// @param twabController The Twab Controller to retrieve time-weighted average balances from
/// @param creator The address that will be permitted to finish prize pool initialization after deployment
/// @param tierLiquidityUtilizationRate The rate at which liquidity is utilized for prize tiers. This allows
/// for deviations in prize claims; if 0.75e18 then it is 75% utilization so it can accommodate 25% deviation
/// in more prize claims.
/// @param drawPeriodSeconds The number of seconds between draws.
/// E.g. a Prize Pool with a daily draw should have a draw period of 86400 seconds.
/// @param firstDrawOpensAt The timestamp at which the first draw will open
/// @param grandPrizePeriodDraws The target number of draws to pass between each grand prize
/// @param numberOfTiers The number of tiers to start with. Must be greater than or equal to the minimum
/// number of tiers
/// @param tierShares The number of shares to allocate to each tier
/// @param canaryShares The number of shares to allocate to each canary tier
/// @param reserveShares The number of shares to allocate to the reserve
/// @param drawTimeout The number of draws that need to be missed before the prize pool shuts down. The timeout
/// resets when a draw is awarded.
struct ConstructorParams {
  IERC20 prizeToken;
  TwabController twabController;
  address creator;
  uint256 tierLiquidityUtilizationRate;
  uint48 drawPeriodSeconds;
  uint48 firstDrawOpensAt;
  uint24 grandPrizePeriodDraws;
  uint8 numberOfTiers;
  uint8 tierShares;
  uint8 canaryShares;
  uint8 reserveShares;
  uint24 drawTimeout;
}

/// @notice A struct to represent a shutdown portion of liquidity for a vault and account
/// @param numerator The numerator of the portion
/// @param denominator The denominator of the portion
struct ShutdownPortion {
  uint256 numerator;
  uint256 denominator;
}

/// @title PoolTogether V5 Prize Pool
/// @author G9 Software Inc. & PoolTogether Inc. Team
/// @notice The Prize Pool holds the prize liquidity and allows vaults to claim prizes.
contract PrizePool is TieredLiquidityDistributor {
  using SafeERC20 for IERC20;
  using DrawAccumulatorLib for DrawAccumulatorLib.Accumulator;

  /* ============ Events ============ */

  /// @notice Emitted when a prize is claimed.
  /// @param vault The address of the vault that claimed the prize.
  /// @param winner The address of the winner
  /// @param recipient The address of the prize recipient
  /// @param drawId The draw ID of the draw that was claimed.
  /// @param tier The prize tier that was claimed.
  /// @param prizeIndex The index of the prize that was claimed
  /// @param payout The amount of prize tokens that were paid out to the winner
  /// @param claimReward The amount of prize tokens that were paid to the claimer
  /// @param claimRewardRecipient The address that the claimReward was sent to
  event ClaimedPrize(
    address indexed vault,
    address indexed winner,
    address indexed recipient,
    uint24 drawId,
    uint8 tier,
    uint32 prizeIndex,
    uint152 payout,
    uint96 claimReward,
    address claimRewardRecipient
  );

  /// @notice Emitted when a draw is awarded.
  /// @param drawId The ID of the draw that was awarded
  /// @param winningRandomNumber The winning random number for the awarded draw
  /// @param lastNumTiers The previous number of prize tiers
  /// @param numTiers The number of prize tiers for the awarded draw
  /// @param reserve The resulting reserve available
  /// @param prizeTokensPerShare The amount of prize tokens per share for the awarded draw
  /// @param drawOpenedAt The start timestamp of the awarded draw
  event DrawAwarded(
    uint24 indexed drawId,
    uint256 winningRandomNumber,
    uint8 lastNumTiers,
    uint8 numTiers,
    uint104 reserve,
    uint128 prizeTokensPerShare,
    uint48 drawOpenedAt
  );

  /// @notice Emitted when any amount of the reserve is rewarded to a recipient.
  /// @param to The recipient of the reward
  /// @param amount The amount of assets rewarded
  event AllocateRewardFromReserve(address indexed to, uint256 amount);

  /// @notice Emitted when the reserve is manually increased.
  /// @param user The user who increased the reserve
  /// @param amount The amount of assets transferred
  event ContributedReserve(address indexed user, uint256 amount);

  /// @notice Emitted when a vault contributes prize tokens to the pool.
  /// @param vault The address of the vault that is contributing tokens
  /// @param drawId The ID of the first draw that the tokens will be contributed to
  /// @param amount The amount of tokens contributed
  event ContributePrizeTokens(address indexed vault, uint24 indexed drawId, uint256 amount);

  /// @notice Emitted when the draw manager is set
  /// @param drawManager The address of the draw manager
  event SetDrawManager(address indexed drawManager);

  /// @notice Emitted when an address withdraws their prize claim rewards.
  /// @param account The account that is withdrawing rewards
  /// @param to The address the rewards are sent to
  /// @param amount The amount withdrawn
  /// @param available The total amount that was available to withdraw before the transfer
  event WithdrawRewards(
    address indexed account,
    address indexed to,
    uint256 amount,
    uint256 available
  );

  /// @notice Emitted when an address receives new prize claim rewards.
  /// @param to The address the rewards are given to
  /// @param amount The amount increased
  event IncreaseClaimRewards(address indexed to, uint256 amount);

  /* ============ State ============ */

  /// @notice The DrawAccumulator that tracks the exponential moving average of the contributions by a vault.
  mapping(address vault => DrawAccumulatorLib.Accumulator accumulator) internal _vaultAccumulator;

  /// @notice Records the claim record for a winner.
  mapping(address vault => mapping(address account => mapping(uint24 drawId => mapping(uint8 tier => mapping(uint32 prizeIndex => bool claimed)))))
    internal _claimedPrizes;

  /// @notice Tracks the total rewards accrued for a claimer or draw completer.
  mapping(address recipient => uint256 rewards) internal _rewards;

  /// @notice The special value for the donator address. Contributions from this address are excluded from the total odds.
  /// @dev 0x000...F2EE because it's free money!
  address public constant DONATOR = 0x000000000000000000000000000000000000F2EE;

  /// @notice The token that is being contributed and awarded as prizes.
  IERC20 public immutable prizeToken;

  /// @notice The Twab Controller to use to retrieve historic balances.
  TwabController public immutable twabController;

  /// @notice The number of seconds between draws.
  uint48 public immutable drawPeriodSeconds;

  /// @notice The timestamp at which the first draw will open.
  uint48 public immutable firstDrawOpensAt;

  /// @notice The maximum number of draws that can be missed before the prize pool is considered inactive.
  uint24 public immutable drawTimeout;

  /// @notice The address that is allowed to set the draw manager
  address immutable creator;

  /// @notice The exponential weighted average of all vault contributions.
  DrawAccumulatorLib.Accumulator internal _totalAccumulator;

  /// @notice The winner random number for the last awarded draw.
  uint256 internal _winningRandomNumber;

  /// @notice The draw manager address.
  address public drawManager;

  /// @notice Tracks reserve that was contributed directly to the reserve. Always increases.
  uint96 internal _directlyContributedReserve;

  /// @notice The number of prize claims for the last awarded draw.
  uint24 public claimCount;

  /// @notice The total amount of prize tokens that have been claimed for all time.
  uint128 internal _totalWithdrawn;

  /// @notice The total amount of rewards that have yet to be claimed
  uint104 internal _totalRewardsToBeClaimed;

  /// @notice The observation at which the shutdown balance was recorded
  Observation shutdownObservation;
  
  /// @notice The balance available to be withdrawn at shutdown
  uint256 shutdownBalance;

  /// @notice The total contributed observation that was used for the last withdrawal for a vault and account
  mapping(address vault => mapping(address account => Observation lastWithdrawalTotalContributedObservation)) internal _withdrawalObservations;

  /// @notice The shutdown portion of liquidity for a vault and account
  mapping(address vault => mapping(address account => ShutdownPortion shutdownPortion)) internal _shutdownPortions;

  /* ============ Constructor ============ */

  /// @notice Constructs a new Prize Pool.
  /// @param params A struct of constructor parameters
  constructor(
    ConstructorParams memory params
  )
    TieredLiquidityDistributor(
      params.tierLiquidityUtilizationRate,
      params.numberOfTiers,
      params.tierShares,
      params.canaryShares,
      params.reserveShares,
      params.grandPrizePeriodDraws
    )
  {
    if (params.drawTimeout == 0) {
      revert DrawTimeoutIsZero();
    }

    if (params.drawTimeout > params.grandPrizePeriodDraws) {
      revert DrawTimeoutGTGrandPrizePeriodDraws();
    }

    if (params.firstDrawOpensAt < block.timestamp) {
      revert FirstDrawOpensInPast();
    }

    if (params.grandPrizePeriodDraws >= MAX_OBSERVATION_CARDINALITY) {
      revert GrandPrizePeriodDrawsTooLarge(params.grandPrizePeriodDraws, MAX_OBSERVATION_CARDINALITY - 1);
    }

    uint48 twabPeriodOffset = params.twabController.PERIOD_OFFSET();
    uint48 twabPeriodLength = params.twabController.PERIOD_LENGTH();

    if (
      params.drawPeriodSeconds < twabPeriodLength ||
      params.drawPeriodSeconds % twabPeriodLength != 0
    ) {
      revert IncompatibleTwabPeriodLength();
    }

    if ((params.firstDrawOpensAt - twabPeriodOffset) % twabPeriodLength != 0) {
      revert IncompatibleTwabPeriodOffset();
    }

    if (params.creator == address(0)) {
      revert CreatorIsZeroAddress();
    }

    creator = params.creator;
    drawTimeout = params.drawTimeout;
    prizeToken = params.prizeToken;
    twabController = params.twabController;
    drawPeriodSeconds = params.drawPeriodSeconds;
    firstDrawOpensAt = params.firstDrawOpensAt;
  }

  /* ============ Modifiers ============ */

  /// @notice Modifier that throws if sender is not the draw manager.
  modifier onlyDrawManager() {
    if (msg.sender != drawManager) {
      revert CallerNotDrawManager(msg.sender, drawManager);
    }
    _;
  }

  /// @notice Sets the Draw Manager contract on the prize pool. Can only be called once by the creator.
  /// @param _drawManager The address of the Draw Manager contract
  function setDrawManager(address _drawManager) external {
    if (msg.sender != creator) {
      revert OnlyCreator();
    }
    if (drawManager != address(0)) {
      revert DrawManagerAlreadySet();
    }
    drawManager = _drawManager;

    emit SetDrawManager(_drawManager);
  }

  /* ============ External Write Functions ============ */

  /// @notice Contributes prize tokens on behalf of the given vault.
  /// @dev The tokens should have already been transferred to the prize pool.
  /// @dev The prize pool balance will be checked to ensure there is at least the given amount to deposit.
  /// @param _prizeVault The address of the vault to contribute to
  /// @param _amount The amount of prize tokens to contribute
  /// @return The amount of available prize tokens prior to the contribution.
  function contributePrizeTokens(address _prizeVault, uint256 _amount) public returns (uint256) {
    uint256 _deltaBalance = prizeToken.balanceOf(address(this)) - accountedBalance();
    if (_deltaBalance < _amount) {
      revert ContributionGTDeltaBalance(_amount, _deltaBalance);
    }
    uint24 openDrawId_ = getOpenDrawId();
    _vaultAccumulator[_prizeVault].add(_amount, openDrawId_);
    _totalAccumulator.add(_amount, openDrawId_);
    emit ContributePrizeTokens(_prizeVault, openDrawId_, _amount);
    return _deltaBalance;
  }

  /// @notice Allows a user to donate prize tokens to the prize pool.
  /// @param _amount The amount of tokens to donate. The amount should already be approved for transfer.
  function donatePrizeTokens(uint256 _amount) external {
    prizeToken.safeTransferFrom(msg.sender, address(this), _amount);
    contributePrizeTokens(DONATOR, _amount);
  }

  /// @notice Allows the Manager to allocate a reward from the reserve to a recipient.
  /// @param _to The address to allocate the rewards to
  /// @param _amount The amount of tokens for the reward
  function allocateRewardFromReserve(address _to, uint96 _amount) external onlyDrawManager notShutdown {
    if (_to == address(0)) {
      revert RewardRecipientZeroAddress();
    }
    if (_amount > _reserve) {
      revert InsufficientReserve(_amount, _reserve);
    }

    unchecked {
      _reserve -= _amount;
    }

    _rewards[_to] += _amount;
    _totalRewardsToBeClaimed = SafeCast.toUint104(_totalRewardsToBeClaimed + _amount);
    emit AllocateRewardFromReserve(_to, _amount);
  }

  /// @notice Allows the Manager to award a draw with the winning random number.
  /// @dev Updates the number of tiers, the winning random number and the prize pool reserve.
  /// @param winningRandomNumber_ The winning random number for the draw
  /// @return The ID of the awarded draw
  function awardDraw(uint256 winningRandomNumber_) external onlyDrawManager notShutdown returns (uint24) {
    // check winning random number
    if (winningRandomNumber_ == 0) {
      revert RandomNumberIsZero();
    }
    uint24 awardingDrawId = getDrawIdToAward();
    uint48 awardingDrawOpenedAt = drawOpensAt(awardingDrawId);
    uint48 awardingDrawClosedAt = awardingDrawOpenedAt + drawPeriodSeconds;
    if (block.timestamp < awardingDrawClosedAt) {
      revert AwardingDrawNotClosed(awardingDrawClosedAt);
    }

    uint24 lastAwardedDrawId_ = _lastAwardedDrawId;
    uint32 _claimCount = claimCount;
    uint8 _numTiers = numberOfTiers;
    uint8 _nextNumberOfTiers = _numTiers;

    _nextNumberOfTiers = computeNextNumberOfTiers(_claimCount);

    // If any draws were skipped from the last awarded draw to the one we are awarding, the contribution
    // from those skipped draws will be included in the new distributions.
    _awardDraw(
      awardingDrawId,
      _nextNumberOfTiers,
      getTotalContributedBetween(lastAwardedDrawId_ + 1, awardingDrawId)
    );

    _winningRandomNumber = winningRandomNumber_;
    if (_claimCount != 0) {
      claimCount = 0;
    }

    emit DrawAwarded(
      awardingDrawId,
      winningRandomNumber_,
      _numTiers,
      _nextNumberOfTiers,
      _reserve,
      prizeTokenPerShare,
      awardingDrawOpenedAt
    );

    return awardingDrawId;
  }

  /// @notice Claims a prize for a given winner and tier.
  /// @dev This function takes in an address _winner, a uint8 _tier, a uint96 _claimReward, and an
  /// address _claimRewardRecipient. It checks if _winner is actually the winner of the _tier for the calling vault.
  /// If so, it calculates the prize size and transfers it to the winner. If not, it reverts with an error message.
  /// The function then checks the claim record of _winner to see if they have already claimed the prize for the
  /// awarded draw. If not, it updates the claim record with the claimed tier and emits a ClaimedPrize event with
  /// information about the claim.
  /// Note that this function can modify the state of the contract by updating the claim record, changing the largest
  /// tier claimed and the claim count, and transferring prize tokens. The function is marked as external which
  /// means that it can be called from outside the contract.
  /// @param _winner The address of the eligible winner
  /// @param _tier The tier of the prize to be claimed.
  /// @param _prizeIndex The prize to claim for the winner. Must be less than the prize count for the tier.
  /// @param _prizeRecipient The recipient of the prize
  /// @param _claimReward The claimReward associated with claiming the prize.
  /// @param _claimRewardRecipient The address to receive the claimReward.
  /// @return Total prize amount claimed (payout and claimRewards combined).
  function claimPrize(
    address _winner,
    uint8 _tier,
    uint32 _prizeIndex,
    address _prizeRecipient,
    uint96 _claimReward,
    address _claimRewardRecipient
  ) external returns (uint256) {
    /// @dev Claims cannot occur after a draw has been finalized (1 period after a draw closes). This prevents
    /// the reserve from changing while the following draw is being awarded.
    uint24 lastAwardedDrawId_ = _lastAwardedDrawId;
    if (isDrawFinalized(lastAwardedDrawId_)) {
      revert ClaimPeriodExpired();
    }
    if (_claimRewardRecipient == address(0) && _claimReward > 0) {
      revert RewardRecipientZeroAddress();
    }

    uint8 _numTiers = numberOfTiers;

    Tier memory tierLiquidity = _getTier(_tier, _numTiers);

    if (_claimReward > tierLiquidity.prizeSize) {
      revert RewardTooLarge(_claimReward, tierLiquidity.prizeSize);
    }

    if (tierLiquidity.prizeSize == 0) {
      revert PrizeIsZero();
    }

    if (!isWinner(msg.sender, _winner, _tier, _prizeIndex)) {
      revert DidNotWin(msg.sender, _winner, _tier, _prizeIndex);
    }

    if (_claimedPrizes[msg.sender][_winner][lastAwardedDrawId_][_tier][_prizeIndex]) {
      revert AlreadyClaimed(msg.sender, _winner, _tier, _prizeIndex);
    }

    _claimedPrizes[msg.sender][_winner][lastAwardedDrawId_][_tier][_prizeIndex] = true;

    _consumeLiquidity(tierLiquidity, _tier, tierLiquidity.prizeSize);

    // `amount` is the payout amount
    uint256 amount;
    if (_claimReward != 0) {
      emit IncreaseClaimRewards(_claimRewardRecipient, _claimReward);
      _rewards[_claimRewardRecipient] += _claimReward;

      unchecked {
        amount = tierLiquidity.prizeSize - _claimReward;
      }
    } else {
      amount = tierLiquidity.prizeSize;
    }

    // co-locate to save gas
    claimCount++;
    _totalWithdrawn = SafeCast.toUint128(_totalWithdrawn + amount);
    _totalRewardsToBeClaimed = SafeCast.toUint104(_totalRewardsToBeClaimed + _claimReward);

    emit ClaimedPrize(
      msg.sender,
      _winner,
      _prizeRecipient,
      lastAwardedDrawId_,
      _tier,
      _prizeIndex,
      uint152(amount),
      _claimReward,
      _claimRewardRecipient
    );

    if (amount > 0) {
      prizeToken.safeTransfer(_prizeRecipient, amount);
    }

    return tierLiquidity.prizeSize;
  }

  /// @notice Withdraws earned rewards for the caller.
  /// @param _to The address to transfer the rewards to
  /// @param _amount The amount of rewards to withdraw
  function withdrawRewards(address _to, uint256 _amount) external {
    uint256 _available = _rewards[msg.sender];

    if (_amount > _available) {
      revert InsufficientRewardsError(_amount, _available);
    }

    unchecked {
      _rewards[msg.sender] = _available - _amount;
    }

    _totalWithdrawn = SafeCast.toUint128(_totalWithdrawn + _amount);
    _totalRewardsToBeClaimed = SafeCast.toUint104(_totalRewardsToBeClaimed - _amount);

    // skip transfer if recipient is the prize pool (tokens stay in this contract)
    if (_to != address(this)) {
      prizeToken.safeTransfer(_to, _amount);
    }

    emit WithdrawRewards(msg.sender, _to, _amount, _available);
  }

  /// @notice Allows anyone to deposit directly into the Prize Pool reserve.
  /// @dev Ensure caller has sufficient balance and has approved the Prize Pool to transfer the tokens
  /// @param _amount The amount of tokens to increase the reserve by
  function contributeReserve(uint96 _amount) external notShutdown {
    _reserve += _amount;
    _directlyContributedReserve += _amount;
    prizeToken.safeTransferFrom(msg.sender, address(this), _amount);
    emit ContributedReserve(msg.sender, _amount);
  }

  /* ============ External Read Functions ============ */

  /// @notice Returns the winning random number for the last awarded draw.
  /// @return The winning random number
  function getWinningRandomNumber() external view returns (uint256) {
    return _winningRandomNumber;
  }

  /// @notice Returns the last awarded draw id.
  /// @return The last awarded draw id
  function getLastAwardedDrawId() external view returns (uint24) {
    return _lastAwardedDrawId;
  }

  /// @notice Returns the total prize tokens contributed by a particular vault between the given draw ids, inclusive.
  /// @param _vault The address of the vault
  /// @param _startDrawIdInclusive Start draw id inclusive
  /// @param _endDrawIdInclusive End draw id inclusive
  /// @return The total prize tokens contributed by the given vault
  function getContributedBetween(
    address _vault,
    uint24 _startDrawIdInclusive,
    uint24 _endDrawIdInclusive
  ) external view returns (uint256) {
    return
      _vaultAccumulator[_vault].getDisbursedBetween(
        _startDrawIdInclusive,
        _endDrawIdInclusive
      );
  }

  /// @notice Returns the total prize tokens donated to the prize pool
  /// @param _startDrawIdInclusive Start draw id inclusive
  /// @param _endDrawIdInclusive End draw id inclusive
  /// @return The total prize tokens donated to the prize pool
  function getDonatedBetween(
    uint24 _startDrawIdInclusive,
    uint24 _endDrawIdInclusive
  ) external view returns (uint256) {
    return
      _vaultAccumulator[DONATOR].getDisbursedBetween(
        _startDrawIdInclusive,
        _endDrawIdInclusive
      );
  }

  /// @notice Returns the newest observation for the total accumulator
  /// @return The newest observation
  function getTotalAccumulatorNewestObservation() external view returns (Observation memory) {
    return _totalAccumulator.newestObservation();
  }

  /// @notice Returns the newest observation for the specified vault accumulator
  /// @param _vault The vault to check
  /// @return The newest observation for the vault
  function getVaultAccumulatorNewestObservation(address _vault) external view returns (Observation memory) {
    return _vaultAccumulator[_vault].newestObservation();
  }

  /// @notice Computes the expected duration prize accrual for a tier.
  /// @param _tier The tier to check
  /// @return The number of draws
  function getTierAccrualDurationInDraws(uint8 _tier) external view returns (uint24) {
    return
      uint24(TierCalculationLib.estimatePrizeFrequencyInDraws(getTierOdds(_tier, numberOfTiers)));
  }

  /// @notice The total amount of prize tokens that have been withdrawn as fees or prizes
  /// @return The total amount of prize tokens that have been withdrawn as fees or prizes
  function totalWithdrawn() external view returns (uint256) {
    return _totalWithdrawn;
  }

  /// @notice Returns the amount of tokens that will be added to the reserve when next draw to award is awarded.
  /// @dev Intended for Draw manager to use after a draw has closed but not yet been awarded.
  /// @return The amount of prize tokens that will be added to the reserve
  function pendingReserveContributions() external view returns (uint256) {
    uint8 _numTiers = numberOfTiers;
    uint24 lastAwardedDrawId_ = _lastAwardedDrawId;

    (uint104 newReserve, ) = _computeNewDistributions(
      _numTiers,
      lastAwardedDrawId_ == 0 ? _numTiers : computeNextNumberOfTiers(claimCount),
      prizeTokenPerShare,
      getTotalContributedBetween(lastAwardedDrawId_ + 1, getDrawIdToAward())
    );

    return newReserve;
  }

  /// @notice Returns whether the winner has claimed the tier for the last awarded draw
  /// @param _vault The vault to check
  /// @param _winner The account to check
  /// @param _tier The tier to check
  /// @param _prizeIndex The prize index to check
  /// @return True if the winner claimed the tier for the last awarded draw, false otherwise.
  function wasClaimed(
    address _vault,
    address _winner,
    uint8 _tier,
    uint32 _prizeIndex
  ) external view returns (bool) {
    return _claimedPrizes[_vault][_winner][_lastAwardedDrawId][_tier][_prizeIndex];
  }

  /// @notice Returns whether the winner has claimed the tier for the specified draw
  /// @param _vault The vault to check
  /// @param _winner The account to check
  /// @param _drawId The draw ID to check
  /// @param _tier The tier to check
  /// @param _prizeIndex The prize index to check
  /// @return True if the winner claimed the tier for the specified draw, false otherwise.
  function wasClaimed(
    address _vault,
    address _winner,
    uint24 _drawId,
    uint8 _tier,
    uint32 _prizeIndex
  ) external view returns (bool) {
    return _claimedPrizes[_vault][_winner][_drawId][_tier][_prizeIndex];
  }

  /// @notice Returns the balance of rewards earned for the given address.
  /// @param _recipient The recipient to retrieve the reward balance for
  /// @return The balance of rewards for the given recipient
  function rewardBalance(address _recipient) external view returns (uint256) {
    return _rewards[_recipient];
  }

  /// @notice Computes and returns the next number of tiers based on the current prize claim counts. This number may change throughout the draw
  /// @return The next number of tiers
  function estimateNextNumberOfTiers() external view returns (uint8) {
    return computeNextNumberOfTiers(claimCount);
  }

  /* ============ Internal Functions ============ */

  /// @notice Computes how many tokens have been accounted for
  /// @return The balance of tokens that have been accounted for
  function accountedBalance() public view returns (uint256) {
    return _accountedBalance(_totalAccumulator.newestObservation());
  }

  /// @notice Returns the balance available at the time of shutdown, less rewards to be claimed.
  /// @dev This function will compute and store the current balance if it has not yet been set.
  /// @return balance The balance that is available for depositors to withdraw
  /// @return observation The observation used to compute the balance
  function getShutdownInfo() public returns (uint256 balance, Observation memory observation) {
    if (!isShutdown()) {
      return (balance, observation);
    }
    // if not initialized
    if (shutdownObservation.disbursed + shutdownObservation.available == 0) {
      observation = _totalAccumulator.newestObservation();
      shutdownObservation = observation;
      balance = _accountedBalance(observation) - _totalRewardsToBeClaimed;
      shutdownBalance = balance;
    } else {
      observation = shutdownObservation;
      balance = shutdownBalance;
    }
  }

  /// @notice Returns the open draw ID based on the current block timestamp.
  /// @dev Returns `1` if the first draw hasn't opened yet. This prevents any contributions from
  /// going to the inaccessible draw zero.
  /// @dev First draw has an ID of `1`. This means that if `_lastAwardedDrawId` is zero,
  /// we know that no draws have been awarded yet.
  /// @dev Capped at the shutdown draw ID if the prize pool has shutdown.
  /// @return The ID of the draw period that the current block is in
  function getOpenDrawId() public view returns (uint24) {
    uint24 shutdownDrawId = getShutdownDrawId();
    uint24 openDrawId = getDrawId(block.timestamp);
    return openDrawId > shutdownDrawId ? shutdownDrawId : openDrawId;
  }

  /// @notice Returns the open draw id for the given timestamp
  /// @param _timestamp The timestamp to get the draw id for
  /// @return The ID of the open draw that the timestamp is in
  function getDrawId(uint256 _timestamp) public view returns (uint24) {
    uint48 _firstDrawOpensAt = firstDrawOpensAt;
    return
      (_timestamp < _firstDrawOpensAt)
        ? 1
        : (uint24((_timestamp - _firstDrawOpensAt) / drawPeriodSeconds) + 1);
  }

  /// @notice Returns the next draw ID that can be awarded.
  /// @dev It's possible for draws to be missed, so the next draw ID to award
  /// may be more than one draw ahead of the last awarded draw ID.
  /// @return The next draw ID that can be awarded
  function getDrawIdToAward() public view returns (uint24) {
    uint24 openDrawId_ = getOpenDrawId();
    return (openDrawId_ - _lastAwardedDrawId) > 1 ? openDrawId_ - 1 : openDrawId_;
  }

  /// @notice Returns the time at which a draw opens / opened at.
  /// @param drawId The draw to get the timestamp for
  /// @return The start time of the draw in seconds
  function drawOpensAt(uint24 drawId) public view returns (uint48) {
    return firstDrawOpensAt + (drawId - 1) * drawPeriodSeconds;
  }

  /// @notice Returns the time at which a draw closes / closed at.
  /// @param drawId The draw to get the timestamp for
  /// @return The end time of the draw in seconds
  function drawClosesAt(uint24 drawId) public view returns (uint48) {
    return firstDrawOpensAt + drawId * drawPeriodSeconds;
  }

  /// @notice Checks if the given draw is finalized.
  /// @param drawId The draw to check
  /// @return True if the draw is finalized, false otherwise
  function isDrawFinalized(uint24 drawId) public view returns (bool) {
    return block.timestamp >= drawClosesAt(drawId + 1);
  }

  /// @notice Calculates the number of tiers given the number of prize claims
  /// @dev This function will use the claim count to determine the number of tiers, then add one for the canary tier.
  /// @param _claimCount The number of prize claims
  /// @return The estimated number of tiers + the canary tier
  function computeNextNumberOfTiers(uint32 _claimCount) public view returns (uint8) {
    if (_lastAwardedDrawId != 0) {
      // claimCount is expected to be the estimated number of claims for the current prize tier.
      uint8 nextNumberOfTiers = _estimateNumberOfTiersUsingPrizeCountPerDraw(_claimCount);
      // limit change to 1 tier
      uint8 _numTiers = numberOfTiers;
      if (nextNumberOfTiers > _numTiers) {
        nextNumberOfTiers = _numTiers + 1;
      } else if (nextNumberOfTiers < _numTiers) {
        nextNumberOfTiers = _numTiers - 1;
      }
      return nextNumberOfTiers;
    } else {
      return numberOfTiers;
    }
  }

  /// @notice Returns the given account and vault's portion of the shutdown balance.
  /// @param _vault The vault whose contributions are measured
  /// @param _account The account whose vault twab is measured
  /// @return The portion of the shutdown balance that the account is entitled to.
  function computeShutdownPortion(address _vault, address _account) public view returns (ShutdownPortion memory) {
    uint24 drawIdPriorToShutdown = getShutdownDrawId() - 1;
    uint24 startDrawIdInclusive = computeRangeStartDrawIdInclusive(drawIdPriorToShutdown, grandPrizePeriodDraws);

    (uint256 vaultContrib, uint256 totalContrib) = _getVaultShares(
      _vault,
      startDrawIdInclusive,
      drawIdPriorToShutdown
    );

    (uint256 _userTwab, uint256 _vaultTwabTotalSupply) = getVaultUserBalanceAndTotalSupplyTwab(
      _vault,
      _account,
      startDrawIdInclusive,
      drawIdPriorToShutdown
    );

    if (_vaultTwabTotalSupply == 0) {
      return ShutdownPortion(0, 0);
    }

    return ShutdownPortion(vaultContrib * _userTwab, totalContrib * _vaultTwabTotalSupply);
  }

  /// @notice Returns the shutdown balance for a given vault and account. The prize pool must already be shutdown.
  /// @dev The shutdown balance is the amount of prize tokens that a user can claim after the prize pool has been shutdown.
  /// @dev The shutdown balance is calculated using the user's TWAB and the total supply TWAB, whose time ranges are the
  /// grand prize period prior to the shutdown timestamp.
  /// @param _vault The vault to check
  /// @param _account The account to check
  /// @return The shutdown balance for the given vault and account
  function shutdownBalanceOf(address _vault, address _account) public returns (uint256) {
    if (!isShutdown()) {
      return 0;
    }

    Observation memory withdrawalObservation = _withdrawalObservations[_vault][_account];
    ShutdownPortion memory shutdownPortion;
    uint256 balance;

    // if we haven't withdrawn yet, add the portion of the shutdown balance
    if ((withdrawalObservation.available + withdrawalObservation.disbursed) == 0) {
      (balance, withdrawalObservation) = getShutdownInfo();
      shutdownPortion = computeShutdownPortion(_vault, _account);
      _shutdownPortions[_vault][_account] = shutdownPortion;
    } else {
      shutdownPortion = _shutdownPortions[_vault][_account];
    }

    if (shutdownPortion.denominator == 0) {
      return 0;
    }

    // if there are new rewards
    // current "draw id to award" observation - last withdraw observation
    Observation memory newestObs = _totalAccumulator.newestObservation();
    balance += (newestObs.available + newestObs.disbursed) - (withdrawalObservation.available + withdrawalObservation.disbursed);

    return (shutdownPortion.numerator * balance) / shutdownPortion.denominator;
  }

  /// @notice Withdraws the shutdown balance for a given vault and sender
  /// @param _vault The eligible vault to withdraw the shutdown balance from
  /// @param _recipient The address to send the shutdown balance to
  /// @return The amount of prize tokens withdrawn
  function withdrawShutdownBalance(address _vault, address _recipient) external returns (uint256) {
    if (!isShutdown()) {
      revert PrizePoolNotShutdown();
    }
    uint256 balance = shutdownBalanceOf(_vault, msg.sender);
    _withdrawalObservations[_vault][msg.sender] = _totalAccumulator.newestObservation();
    if (balance > 0) {
      prizeToken.safeTransfer(_recipient, balance);
      _totalWithdrawn += uint128(balance);
    }
    return balance;
  }

  /// @notice Returns the open draw ID at the time of shutdown.
  /// @return The draw id
  function getShutdownDrawId() public view returns (uint24) {
    return getDrawId(shutdownAt());
  }

  /// @notice Returns the timestamp at which the prize pool will be considered inactive and shutdown
  /// @return The timestamp at which the prize pool will be considered inactive
  function shutdownAt() public view returns (uint256) {
    uint256 twabShutdownAt = twabController.lastObservationAt();
    uint256 drawTimeoutAt_ = drawTimeoutAt();
    return drawTimeoutAt_ < twabShutdownAt ? drawTimeoutAt_ : twabShutdownAt;
  }

  /// @notice Returns whether the prize pool has been shutdown
  /// @return True if shutdown, false otherwise
  function isShutdown() public view returns (bool) {
    return block.timestamp >= shutdownAt();
  }

  /// @notice Returns the timestamp at which the prize pool will be considered inactive
  /// @return The timestamp at which the prize pool has timed out and becomes inactive
  function drawTimeoutAt() public view returns (uint256) { 
    return drawClosesAt(_lastAwardedDrawId + drawTimeout);
  }

  /// @notice Returns the total prize tokens contributed between the given draw ids, inclusive.
  /// @param _startDrawIdInclusive Start draw id inclusive
  /// @param _endDrawIdInclusive End draw id inclusive
  /// @return The total prize tokens contributed by all vaults
  function getTotalContributedBetween(
    uint24 _startDrawIdInclusive,
    uint24 _endDrawIdInclusive
  ) public view returns (uint256) {
    return
      _totalAccumulator.getDisbursedBetween(
        _startDrawIdInclusive,
        _endDrawIdInclusive
      );
  }

  /// @notice Checks if the given user has won the prize for the specified tier in the given vault.
  /// @param _vault The address of the vault to check
  /// @param _user The address of the user to check for the prize
  /// @param _tier The tier for which the prize is to be checked
  /// @param _prizeIndex The prize index to check. Must be less than prize count for the tier
  /// @return A boolean value indicating whether the user has won the prize or not
  function isWinner(
    address _vault,
    address _user,
    uint8 _tier,
    uint32 _prizeIndex
  ) public view returns (bool) {
    uint24 lastAwardedDrawId_ = _lastAwardedDrawId;

    if (lastAwardedDrawId_ == 0) {
      revert NoDrawsAwarded();
    }
    if (_tier >= numberOfTiers) {
      revert InvalidTier(_tier, numberOfTiers);
    }

    SD59x18 tierOdds = getTierOdds(_tier, numberOfTiers);
    uint24 startDrawIdInclusive = computeRangeStartDrawIdInclusive(lastAwardedDrawId_, uint24(TierCalculationLib.estimatePrizeFrequencyInDraws(tierOdds)));

    uint32 tierPrizeCount = uint32(TierCalculationLib.prizeCount(_tier));

    if (_prizeIndex >= tierPrizeCount) {
      revert InvalidPrizeIndex(_prizeIndex, tierPrizeCount, _tier);
    }

    uint256 userSpecificRandomNumber = TierCalculationLib.calculatePseudoRandomNumber(
      lastAwardedDrawId_,
      _vault,
      _user,
      _tier,
      _prizeIndex,
      _winningRandomNumber
    );
    
    SD59x18 vaultPortion = getVaultPortion(
      _vault,
      startDrawIdInclusive,
      lastAwardedDrawId_
    );

    (uint256 _userTwab, uint256 _vaultTwabTotalSupply) = getVaultUserBalanceAndTotalSupplyTwab(
      _vault,
      _user,
      startDrawIdInclusive,
      lastAwardedDrawId_
    );

    return
      TierCalculationLib.isWinner(
        userSpecificRandomNumber,
        _userTwab,
        _vaultTwabTotalSupply,
        vaultPortion,
        tierOdds
      );
  }

  /// @notice Compute the start draw id for a range given the end draw id and range size
  /// @param _endDrawIdInclusive The end draw id (inclusive) of the range
  /// @param _rangeSize The size of the range
  /// @return The start draw id (inclusive) of the range
  function computeRangeStartDrawIdInclusive(uint24 _endDrawIdInclusive, uint24 _rangeSize) public pure returns (uint24) {
    if (_rangeSize != 0) {
      return _rangeSize > _endDrawIdInclusive ? 1 : _endDrawIdInclusive - _rangeSize + 1;
    } else {
      revert RangeSizeZero();
    }
  }

  /// @notice Returns the time-weighted average balance (TWAB) and the TWAB total supply for the specified user in
  /// the given vault over a specified period.
  /// @dev This function calculates the TWAB for a user by calling the getTwabBetween function of the TWAB controller
  /// for a specified period of time.
  /// @param _vault The address of the vault for which to get the TWAB.
  /// @param _user The address of the user for which to get the TWAB.
  /// @param _startDrawIdInclusive The starting draw for the range (inclusive)
  /// @param _endDrawIdInclusive The end draw for the range (inclusive)
  /// @return twab The TWAB for the specified user in the given vault over the specified period.
  /// @return twabTotalSupply The TWAB total supply over the specified period.
  function getVaultUserBalanceAndTotalSupplyTwab(
    address _vault,
    address _user,
    uint24 _startDrawIdInclusive,
    uint24 _endDrawIdInclusive
  ) public view returns (uint256 twab, uint256 twabTotalSupply) {
    uint48 _startTimestamp = drawOpensAt(_startDrawIdInclusive);
    uint48 _endTimestamp = drawClosesAt(_endDrawIdInclusive);
    twab = twabController.getTwabBetween(_vault, _user, _startTimestamp, _endTimestamp);
    twabTotalSupply = twabController.getTotalSupplyTwabBetween(
      _vault,
      _startTimestamp,
      _endTimestamp
    );
  }

  /// @notice Calculates the portion of the vault's contribution to the prize pool over a specified duration in draws.
  /// @param _vault The address of the vault for which to calculate the portion.
  /// @param _startDrawIdInclusive The starting draw ID (inclusive) of the draw range to calculate the contribution portion for.
  /// @param _endDrawIdInclusive The ending draw ID (inclusive) of the draw range to calculate the contribution portion for.
  /// @return The portion of the vault's contribution to the prize pool over the specified duration in draws.
  function getVaultPortion(
    address _vault,
    uint24 _startDrawIdInclusive,
    uint24 _endDrawIdInclusive
  ) public view returns (SD59x18) {
    if (_vault == DONATOR) {
      return sd(0);
    }

    (uint256 vaultContributed, uint256 totalContributed) = _getVaultShares(_vault, _startDrawIdInclusive, _endDrawIdInclusive);

    if (totalContributed == 0) {
      return sd(0);
    }

    return sd(
      SafeCast.toInt256(
        vaultContributed
      )
    ).div(sd(SafeCast.toInt256(totalContributed)));
  }

  function _getVaultShares(
    address _vault,
    uint24 _startDrawIdInclusive,
    uint24 _endDrawIdInclusive
  ) internal view returns (uint256 shares, uint256 totalSupply) {
    uint256 totalContributed = _totalAccumulator.getDisbursedBetween(
      _startDrawIdInclusive,
      _endDrawIdInclusive
    );

    uint256 totalDonated = _vaultAccumulator[DONATOR].getDisbursedBetween(_startDrawIdInclusive, _endDrawIdInclusive);

    totalSupply = totalContributed - totalDonated;

    shares = _vaultAccumulator[_vault].getDisbursedBetween(
      _startDrawIdInclusive,
      _endDrawIdInclusive
    );
  }

  function _accountedBalance(Observation memory _observation) internal view returns (uint256) {
    // obs.disbursed includes the reserve, prizes, and prize liquidity
    // obs.disbursed is the total amount of tokens all-time contributed by vaults and released. These tokens may:
    //    - still be held for future prizes
    //    - have been given as prizes
    //    - have been captured as fees

    // obs.available is the total number of tokens that WILL be disbursed in the future.
    // _directlyContributedReserve are tokens that have been contributed directly to the reserve
    // totalWithdrawn represents all tokens that have been withdrawn as prizes or rewards

    return (_observation.available + _observation.disbursed) + uint256(_directlyContributedReserve) - uint256(_totalWithdrawn);
  }

  /// @notice Modifier that requires the prize pool not to be shutdown
  modifier notShutdown() {
    if (isShutdown()) {
      revert PrizePoolShutdown();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC4626 } from "openzeppelin/interfaces/IERC4626.sol";
import { SafeERC20, IERC20Permit } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { ERC20, IERC20, IERC20Metadata } from "openzeppelin/token/ERC20/ERC20.sol";
import { Math } from "openzeppelin/utils/math/Math.sol";
import { Ownable } from "owner-manager-contracts/Ownable.sol";

import { Claimable } from "./abstract/Claimable.sol";
import { TwabERC20 } from "./TwabERC20.sol";

import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";
import { TwabController, SPONSORSHIP_ADDRESS } from "pt-v5-twab-controller/TwabController.sol";

/// @dev The TWAB supply limit is the max number of shares that can be minted in the TWAB controller.
uint256 constant TWAB_SUPPLY_LIMIT = type(uint96).max;

/// @title  PoolTogether V5 Prize Vault
/// @author G9 Software Inc.
/// @notice The prize vault takes deposits of an asset and earns yield with the deposits through an underlying yield
///         vault. The yield is then expected to be liquidated and contributed to the prize pool as prize tokens. The
///         depositors of the prize vault will then be eligible to win prizes from the pool. If a prize is won, The 
///         permitted claimer contract for the prize vault will claim the prize on behalf of the winner. Depositors
///         can also set custom hooks that are called directly before and after their prize is claimed.
/// @dev    Share balances are stored in the TwabController contract.
/// @dev    Depositors should always expect to be able to withdraw their full deposit amount and no more as long as
///         global withdrawal limits meet or exceed their balance. However, if the underlying yield source loses
///         assets, depositors will only be able to withdraw a proportional amount of remaining assets based on their
///         share balance and the total debt balance.
/// @dev    The prize vault is designed to embody the "no loss" spirit of PoolTogether, down to the last wei. Most 
///         ERC4626 yield vaults incur small, necessary rounding errors on deposit and withdrawal to ensure the
///         internal accounting cannot be taken advantage of. The prize vault employs two strategies in an attempt
///         to cover these rounding errors with yield to ensure that depositors can withdraw every last wei of their
///         initial deposit:
///
///             1. The "dust collection strategy":
///
///                Rounding errors are directly related to the exchange rate of the underlying yield vault; the more
///                assets a single yield vault share is worth, the more severe the rounding errors can become. For
///                example, if the exchange rate is 100 assets for 1 yield vault share and we assume 0 decimal
///                precision; if alice deposits 199 assets, the yield vault will round down on the conversion and mint
///                alice 1 share, essentially donating the remaining 99 assets to the yield vault. This behavior can
///                open pathways for exploits in the prize vault since a bad actor could repeatedly make deposits and
///                withdrawals that result in large rounding errors and since the prize vault covers rounding errors
///                with yield, the attacker could withdraw without loss while essentially donating the yield back to
///                the yield vault.
///
///                To mitigate this issue, the prize vault calculates the amount of yield vault shares that would be
///                minted during a deposit, but mints those shares directly instead, ensuring that only the exact
///                amount of assets needed are sent to the yield vault while keeping the remainder as a latent balance
///                in the prize vault until it can be used in the next deposit or withdraw. An inverse strategy is also
///                used when withdrawing assets from the yield vault. This reduces the possible rounding errors to just
///                1 wei per deposit or withdraw.
///
///             2. The "yield buffer":
///
///                Since the prize vault can still incur minimal rounding errors from the yield vault, a yield buffer
///                is required to ensure that there is always enough yield reserved to cover the rounding errors on 
///                deposits and withdrawals. This buffer should never run dry during normal operating conditions and
///                expected yield rates. If the yield buffer is ever depleted, new deposits will be prevented and the
///                prize vault will enter a lossy withdrawal state where depositors will incur the rounding errors on
///                withdraw.
///
/// @dev    The prize vault does not support underlying yield vaults that take a fee on deposit or withdraw.
///
contract PrizeVault is TwabERC20, Claimable, IERC4626, ILiquidationSource, Ownable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    ////////////////////////////////////////////////////////////////////////////////
    // Public Constants and Variables
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice The yield fee decimal precision.
    uint32 public constant FEE_PRECISION = 1e9;
    
    /// @notice The max yield fee that can be set.
    /// @dev Decimal precision is defined by `FEE_PRECISION`.
    /// @dev If the yield fee is set too high, liquidations won't occur on a regular basis. If a use case requires
    /// a yield fee higher than this max, a custom liquidation pair can be set to manipulate the yield as required.
    uint32 public constant MAX_YIELD_FEE = 9e8;

    /// @notice The yield buffer that is reserved for covering rounding errors on withdrawals and deposits.
    /// @dev The buffer prevents the entire yield balance from being liquidated, which would leave the vault
    /// in a state where a single rounding error could reduce the totalAssets to less than the totalSupply.
    /// 
    /// The yield buffer is expected to be of insignificant value and is used to cover rounding
    /// errors on deposits and withdrawals. Yield is expected to accrue faster than the yield buffer
    /// can be reasonably depleted.
    ///
    /// IT IS RECOMMENDED TO DONATE ASSETS DIRECTLY TO THE PRIZE VAULT AFTER DEPLOYMENT TO FILL THE YIELD
    /// BUFFER AND COVER ROUNDING ERRORS UNTIL THE DEPOSITS CAN GENERATE ENOUGH YIELD TO KEEP THE BUFFER 
    /// FULL WITHOUT ASSISTANCE.
    ///
    /// The yield buffer should be set as high as possible while still being considered insignificant
    /// for the underlying asset. For example, a reasonable yield buffer for USDC with 6 decimals might be
    /// 1e5 ($0.10), which will cover up to 100k rounding errors while still being an insignificant value.
    /// Some assets may be considered incompatible with the prize vault if the yield vault incurs rounding
    /// errors and the underlying asset has a low precision per dollar ratio.
    /// 
    /// Precision per dollar (PPD) can be calculated by: (10 ^ DECIMALS) / ($ value of 1 asset).
    /// For example, USDC has a PPD of (10 ^ 6) / ($1) = 10e6 p/$.
    /// 
    /// As a rule of thumb, assets with lower PPD than USDC should not be assumed to be compatible since
    /// the potential loss of a single unit rounding error is likely too high to be made up by yield at 
    /// a reasonable rate. Actual results may vary based on expected gas costs, asset fluctuation, and yield
    /// accrual rates. If the underlying yield vault does not incur any rounding errors, then the yield buffer
    /// can be set to zero.
    ///
    /// If the yield buffer is depleted on the prize vault, new deposits will be prevented if it would result in
    /// a rounding error and any rounding errors incurred by withdrawals will not be covered by yield. The yield
    /// buffer will be replenished automatically as yield accrues.
    uint256 public immutable yieldBuffer;

    /// @notice Address of the underlying ERC4626 vault generating yield.
    IERC4626 public immutable yieldVault;

    /// @notice Yield fee percentage represented in integer format with decimal precision defined by `FEE_PRECISION`.
    /// @dev For example, if `FEE_PRECISION` were 1e9 a value of 1e7 = 0.01 = 1%.
    uint32 public yieldFeePercentage;

    /// @notice Address of the yield fee recipient.
    address public yieldFeeRecipient;

    /// @notice The accrued yield fee balance that the fee recipient can claim as vault shares.
    uint256 public yieldFeeBalance;

    /// @notice Address of the liquidation pair used to liquidate yield for prize token.
    address public liquidationPair;

    ////////////////////////////////////////////////////////////////////////////////
    // Private Variables
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Address of the underlying asset used by the Vault.
    IERC20 private immutable _asset;

    /// @notice Underlying asset decimals.
    uint8 private immutable _underlyingDecimals;

    ////////////////////////////////////////////////////////////////////////////////
    // Events
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when a new yield fee recipient has been set.
    /// @param yieldFeeRecipient Address of the new yield fee recipient
    event YieldFeeRecipientSet(address indexed yieldFeeRecipient);

    /// @notice Emitted when a new yield fee percentage has been set.
    /// @param yieldFeePercentage New yield fee percentage
    event YieldFeePercentageSet(uint256 yieldFeePercentage);

    /// @notice Emitted when a user sponsors the Vault.
    /// @param caller Address that called the function
    /// @param assets Amount of assets deposited into the Vault
    /// @param shares Amount of shares minted to the caller address
    event Sponsor(address indexed caller, uint256 assets, uint256 shares);

    /// @notice Emitted when yield is transferred out by the liquidation pair address.
    /// @param liquidationPair The liquidation pair address that initiated the transfer
    /// @param tokenOut The token that was transferred out
    /// @param recipient The recipient of the tokens
    /// @param amountOut The amount of tokens sent to the recipient
    /// @param yieldFee The amount of shares accrued on the yield fee balance
    event TransferYieldOut(
        address indexed liquidationPair,
        address indexed tokenOut,
        address indexed recipient,
        uint256 amountOut,
        uint256 yieldFee
    );

    /// @notice Emitted when yield fee shares are claimed by the yield fee recipient.
    /// @param recipient Address receiving the fee shares
    /// @param shares Amount of shares claimed
    event ClaimYieldFeeShares(address indexed recipient, uint256 shares);

    ////////////////////////////////////////////////////////////////////////////////
    // Errors
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when the Yield Vault is set to the zero address.
    error YieldVaultZeroAddress();

    /// @notice Thrown when the Owner is set to the zero address.
    error OwnerZeroAddress();

    /// @notice Thrown when a withdrawal of zero assets on the yield vault is attempted
    error WithdrawZeroAssets();

    /// @notice Thrown when no shares are being burnt during a withdrawal of assets
    error BurnZeroShares();

    /// @notice Thrown when zero assets are being deposited
    error DepositZeroAssets();

    /// @notice Thrown when zero shares are being minted
    error MintZeroShares();

    /// @notice Thrown if `totalAssets` is zero during a withdraw
    error ZeroTotalAssets();

    /// @notice Thrown when the Liquidation Pair being set is the zero address.
    error LPZeroAddress();

    /// @notice Thrown during the liquidation process when the liquidation amount out is zero.
    error LiquidationAmountOutZero();

    /// @notice Thrown during the liquidation process when the caller is not the liquidation pair contract.
    /// @param caller The caller address
    /// @param liquidationPair The LP address
    error CallerNotLP(address caller, address liquidationPair);

    /// @notice Thrown if the caller is not the yield fee recipient when withdrawing yield fee shares.
    /// @param caller The caller address
    /// @param yieldFeeRecipient The yield fee recipient address
    error CallerNotYieldFeeRecipient(address caller, address yieldFeeRecipient);

    /// @notice Thrown when the caller of a permit function is not the owner of the assets being permitted.
    /// @param caller The address of the caller
    /// @param owner The address of the owner
    error PermitCallerNotOwner(address caller, address owner);

    /// @notice Thrown when the yield fee percentage being set exceeds the max yield fee allowed.
    /// @param yieldFeePercentage The yield fee percentage in integer format
    /// @param maxYieldFeePercentage The max yield fee percentage in integer format
    error YieldFeePercentageExceedsMax(uint256 yieldFeePercentage, uint256 maxYieldFeePercentage);

    /// @notice Thrown when the yield fee shares being withdrawn exceeds the available yieldFee Balance.
    /// @param shares The shares being withdrawn
    /// @param yieldFeeBalance The available yield fee shares
    error SharesExceedsYieldFeeBalance(uint256 shares, uint256 yieldFeeBalance);

    /// @notice Thrown during the liquidation process when the token in is not the prize token.
    /// @param tokenIn The provided tokenIn address
    /// @param prizeToken The prize token address
    error LiquidationTokenInNotPrizeToken(address tokenIn, address prizeToken);

    /// @notice Thrown during the liquidation process when the token out is not supported.
    /// @param tokenOut The provided tokenOut address
    error LiquidationTokenOutNotSupported(address tokenOut);

    /// @notice Thrown during the liquidation process if the total to withdraw is greater than the available yield.
    /// @param totalToWithdraw The total yield to withdraw
    /// @param availableYield The available yield
    error LiquidationExceedsAvailable(uint256 totalToWithdraw, uint256 availableYield);

    /// @notice Thrown when a deposit results in a state where the total assets are less than the total share supply.
    /// @param totalAssets The total assets controlled by the vault
    /// @param totalSupply The total shares minted and internally accounted for by the vault
    error LossyDeposit(uint256 totalAssets, uint256 totalSupply);

    /// @notice Thrown when the mint limit is exceeded after increasing an external or internal share balance.
    /// @param excess The amount in excess over the limit
    error MintLimitExceeded(uint256 excess);

    /// @notice Thrown when a withdraw call burns more shares than the max share limit provided.
    /// @param shares The shares burned by the withdrawal
    /// @param maxShares The max share limit provided
    error MaxSharesExceeded(uint256 shares, uint256 maxShares);

    /// @notice Thrown when a redeem call returns less assets than the min threshold provided.
    /// @param assets The assets provided by the redemption
    /// @param minAssets The min asset threshold requested
    error MinAssetsNotReached(uint256 assets, uint256 minAssets);

    /// @notice Thrown when the underlying asset does not specify it's number of decimals.
    /// @param asset The underlying asset that was checked
    error FailedToGetAssetDecimals(address asset);

    ////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Requires the caller to be the liquidation pair.
    modifier onlyLiquidationPair() {
        if (msg.sender != liquidationPair) {
            revert CallerNotLP(msg.sender, liquidationPair);
        }
        _;
    }

    /// @notice Requires the caller to be the yield fee recipient.
    modifier onlyYieldFeeRecipient() {
        if (msg.sender != yieldFeeRecipient) {
            revert CallerNotYieldFeeRecipient(msg.sender, yieldFeeRecipient);
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Constructor
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Vault constructor
    /// @param name_ Name of the ERC20 share minted by the vault
    /// @param symbol_ Symbol of the ERC20 share minted by the vault
    /// @param yieldVault_ Address of the underlying ERC4626 vault in which assets are deposited to generate yield
    /// @param prizePool_ Address of the PrizePool that computes prizes
    /// @param claimer_ Address of the claimer
    /// @param yieldFeeRecipient_ Address of the yield fee recipient
    /// @param yieldFeePercentage_ Yield fee percentage
    /// @param yieldBuffer_ Amount of yield to keep as a buffer
    /// @param owner_ Address that will gain ownership of this contract
    constructor(
        string memory name_,
        string memory symbol_,
        IERC4626 yieldVault_,
        PrizePool prizePool_,
        address claimer_,
        address yieldFeeRecipient_,
        uint32 yieldFeePercentage_,
        uint256 yieldBuffer_,
        address owner_
    ) TwabERC20(name_, symbol_, prizePool_.twabController()) Claimable(prizePool_, claimer_) Ownable(owner_) {
        if (address(yieldVault_) == address(0)) revert YieldVaultZeroAddress();
        if (owner_ == address(0)) revert OwnerZeroAddress();

        IERC20 asset_ = IERC20(yieldVault_.asset());
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        if (success) {
            _underlyingDecimals = assetDecimals;
        } else {
            revert FailedToGetAssetDecimals(address(asset_));
        }
        _asset = asset_;

        yieldVault = yieldVault_;
        yieldBuffer = yieldBuffer_;

        _setYieldFeeRecipient(yieldFeeRecipient_);
        _setYieldFeePercentage(yieldFeePercentage_);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // ERC20 Overrides
    ////////////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IERC20Metadata
    function decimals() public view override(ERC20, IERC20Metadata) returns (uint8) {
        return _underlyingDecimals;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // ERC4626 Implementation
    ////////////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IERC4626
    function asset() external view returns (address) {
        return address(_asset);
    }

    /// @inheritdoc IERC4626
    /// @dev The latent asset balance is included in the total asset count to account for the "dust collection
    /// strategy".
    /// @dev This function uses `convertToAssets` to ensure it does not revert, but may result in some
    /// approximation depending on the yield vault implementation.
    function totalAssets() public view returns (uint256) {
        return yieldVault.convertToAssets(yieldVault.balanceOf(address(this))) + _asset.balanceOf(address(this));
    }

    /// @inheritdoc IERC4626
    /// @dev This function uses approximate total assets and should not be used for onchain conversions.
    function convertToShares(uint256 _assets) external view returns (uint256) {
        return _convertToShares(_assets, totalAssets(), totalDebt(), Math.Rounding.Down);
    }

    /// @inheritdoc IERC4626
    /// @dev This function uses approximate total assets and should not be used for onchain conversions.
    function convertToAssets(uint256 _shares) external view returns (uint256) {
        return _convertToAssets(_shares, totalAssets(), totalDebt(), Math.Rounding.Down);
    }

    /// @inheritdoc IERC4626
    /// @dev Considers the TWAB mint limit
    /// @dev Returns zero if any deposit would result in a loss of assets
    /// @dev Returns zero if total assets cannot be determined
    /// @dev Any latent balance of assets in the prize vault will be swept in with the deposit as a part of
    /// the "dust collection strategy". This means that the max deposit must account for the latent balance
    /// by subtracting it from the max deposit available otherwise.
    function maxDeposit(address /* receiver */) public view returns (uint256) {
        uint256 _totalDebt = totalDebt();
        (bool _success, uint256 _totalAssets) = _tryGetTotalPreciseAssets();
        if (!_success || _totalAssets < _totalDebt) return 0;

        uint256 _latentBalance = _asset.balanceOf(address(this));
        uint256 _maxYieldVaultDeposit = yieldVault.maxDeposit(address(this));
        if (_latentBalance >= _maxYieldVaultDeposit) {
            return 0;
        } else {
            // the vault will never mint more than 1 share per asset, so no need to convert mint limit to assets
            uint256 _depositLimit = _mintLimit(_totalDebt);
            uint256 _maxDeposit;
            unchecked {
                _maxDeposit = _maxYieldVaultDeposit - _latentBalance;
            }
            return _depositLimit < _maxDeposit ? _depositLimit : _maxDeposit;
        }
    }

    /// @inheritdoc IERC4626
    /// @dev Returns the same value as `maxDeposit` since shares and assets are 1:1 on mint
    /// @dev Returns zero if any deposit would result in a loss of assets
    function maxMint(address _owner) external view returns (uint256) {
        return maxDeposit(_owner);
    }

    /// @inheritdoc IERC4626
    /// @dev The prize vault maintains a latent balance of assets as part of the "dust collection strategy".
    /// This latent balance are accounted for in the max withdraw limits.
    /// @dev Returns zero if total assets cannot be determined
    function maxWithdraw(address _owner) external view returns (uint256) {
        (bool _success, uint256 _totalAssets) = _tryGetTotalPreciseAssets();
        if (!_success) return 0;
        
        uint256 _maxWithdraw = _maxYieldVaultWithdraw() + _asset.balanceOf(address(this));

        // the owner may receive less than 1 asset per share, so we must convert their balance here
        uint256 _ownerAssets = _convertToAssets(balanceOf(_owner), _totalAssets, totalDebt(), Math.Rounding.Down);
        return _ownerAssets < _maxWithdraw ? _ownerAssets : _maxWithdraw;
    }

    /// @inheritdoc IERC4626
    /// @dev The prize vault maintains a latent balance of assets as part of the "dust collection strategy".
    /// This latent balance are accounted for in the max redeem limits.
    /// @dev Returns zero if total assets cannot be determined
    function maxRedeem(address _owner) external view returns (uint256) {
        (bool _success, uint256 _totalAssets) = _tryGetTotalPreciseAssets();
        if (!_success) return 0;

        uint256 _maxWithdraw = _maxYieldVaultWithdraw() + _asset.balanceOf(address(this));
        uint256 _ownerShares = balanceOf(_owner);

        // The owner will never receive more than 1 asset per share, so there is no need to convert max
        // withdraw to shares unless the owner has more shares than the max withdraw and is redeeming
        // at a loss (when 1 share is worth less than 1 asset).
        if (_ownerShares > _maxWithdraw) {

            // Convert to shares while rounding up. Since 1 asset is guaranteed to be worth more than
            // 1 share and any upwards rounding will not exceed 1 share, we can be sure that when the
            // shares are converted back to assets (rounding down) the resulting asset value won't
            // exceed `_maxWithdraw`.
            uint256 _maxScaledRedeem = _convertToShares(_maxWithdraw, _totalAssets, totalDebt(), Math.Rounding.Up);
            return _maxScaledRedeem >= _ownerShares ? _ownerShares : _maxScaledRedeem;
        } else {
            return _ownerShares;
        }
    }

    /// @inheritdoc IERC4626
    function previewDeposit(uint256 _assets) public pure returns (uint256) {
        // shares represent how many assets an account has deposited, so they are 1:1 on deposit
        return _assets;
    }

    /// @inheritdoc IERC4626
    function previewMint(uint256 _shares) public pure returns (uint256) {
        // shares represent how many assets an account has deposited, so they are 1:1 on mint
        return _shares;
    }

    /// @inheritdoc IERC4626
    /// @dev Reverts if `totalAssets` in the vault is zero
    function previewWithdraw(uint256 _assets) public view returns (uint256) {
        uint256 _totalAssets = totalPreciseAssets();

        // No withdrawals can occur if the vault controls no assets.
        if (_totalAssets == 0) revert ZeroTotalAssets();

        return _convertToShares(_assets, _totalAssets, totalDebt(), Math.Rounding.Up);
    }

    /// @inheritdoc IERC4626
    function previewRedeem(uint256 _shares) public view returns (uint256) {
        return _convertToAssets(_shares, totalPreciseAssets(), totalDebt(), Math.Rounding.Down);
    }

    /// @inheritdoc IERC4626
    function deposit(uint256 _assets, address _receiver) external returns (uint256) {
        uint256 _shares = previewDeposit(_assets);
        _depositAndMint(msg.sender, _receiver, _assets, _shares);
        return _shares;
    }

    /// @inheritdoc IERC4626
    function mint(uint256 _shares, address _receiver) external returns (uint256) {
        uint256 _assets = previewMint(_shares);
        _depositAndMint(msg.sender, _receiver, _assets, _shares);
        return _assets;
    }

    /// @inheritdoc IERC4626
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    ) external returns (uint256) {
        uint256 _shares = previewWithdraw(_assets);
        _burnAndWithdraw(msg.sender, _receiver, _owner, _shares, _assets);
        return _shares;
    }

    /// @inheritdoc IERC4626
    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256) {
        uint256 _assets = previewRedeem(_shares);
        _burnAndWithdraw(msg.sender, _receiver, _owner, _shares, _assets);
        return _assets;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Additional Deposit Flows
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Approve underlying asset with permit, deposit into the Vault and mint Vault shares to `_owner`.
    /// @dev Can't be used to deposit on behalf of another user since `permit` does not accept a receiver parameter,
    /// meaning that anyone could reuse the signature and pass an arbitrary receiver to this function.
    /// @param _assets Amount of assets to approve and deposit
    /// @param _owner Address of the owner depositing `_assets` and signing the permit
    /// @param _deadline Timestamp after which the approval is no longer valid
    /// @param _v V part of the secp256k1 signature
    /// @param _r R part of the secp256k1 signature
    /// @param _s S part of the secp256k1 signature
    /// @return Amount of Vault shares minted to `_owner`.
    function depositWithPermit(
        uint256 _assets,
        address _owner,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256) {
        if (_owner != msg.sender) {
            revert PermitCallerNotOwner(msg.sender, _owner);
        }

        // Skip the permit call if the allowance has already been set to exactly what is needed. This prevents
        // griefing attacks where the signature is used by another actor to complete the permit before this
        // function is executed.
        if (_asset.allowance(_owner, address(this)) != _assets) {
            IERC20Permit(address(_asset)).permit(_owner, address(this), _assets, _deadline, _v, _r, _s);
        }

        uint256 _shares = previewDeposit(_assets);
        _depositAndMint(_owner, _owner, _assets, _shares);
        return _shares;
    }

    /// @notice Deposit assets into the Vault and delegate to the sponsorship address.
    /// @dev Emits a `Sponsor` event
    /// @param _assets Amount of assets to deposit
    /// @return Amount of shares minted to caller.
    function sponsor(uint256 _assets) external returns (uint256) {
        address _owner = msg.sender;

        uint256 _shares = previewDeposit(_assets);
        _depositAndMint(_owner, _owner, _assets, _shares);

        if (twabController.delegateOf(address(this), _owner) != SPONSORSHIP_ADDRESS) {
            twabController.sponsor(_owner);
        }

        emit Sponsor(_owner, _assets, _shares);

        return _shares;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Additional Withdrawal Flows
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Alternate flow for `IERC4626.withdraw` that reverts if the max share limit is exceeded.
    /// @param _assets See `IERC4626.withdraw`
    /// @param _receiver See `IERC4626.withdraw`
    /// @param _owner See `IERC4626.withdraw`
    /// @param _maxShares The max shares that can be burned for the withdrawal to succeed.
    /// @return The amount of shares burned for the withdrawal
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner,
        uint256 _maxShares
    ) external returns (uint256) {
        uint256 _shares = previewWithdraw(_assets);
        if (_shares > _maxShares) revert MaxSharesExceeded(_shares, _maxShares);
        _burnAndWithdraw(msg.sender, _receiver, _owner, _shares, _assets);
        return _shares;
    }

    /// @notice Alternate flow for `IERC4626.redeem` that reverts if the assets returned does not reach the
    /// minimum asset threshold.
    /// @param _shares See `IERC4626.redeem`
    /// @param _receiver See `IERC4626.redeem`
    /// @param _owner See `IERC4626.redeem`
    /// @param _minAssets The minimum assets that can be returned for the redemption to succeed
    /// @return The amount of assets returned for the redemption
    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner,
        uint256 _minAssets
    ) external returns (uint256) {
        uint256 _assets = previewRedeem(_shares);
        if (_assets < _minAssets) revert MinAssetsNotReached(_assets, _minAssets);
        _burnAndWithdraw(msg.sender, _receiver, _owner, _shares, _assets);
        return _assets;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Additional Accounting
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Returns the total assets that are owed to share holders and any other internal balances.
    /// @return The total asset debt of the vault
    function totalDebt() public view returns (uint256) {
        return totalSupply() + yieldFeeBalance;
    }

    /// @notice Calculates the amount of assets the vault controls based on current onchain conditions.
    /// @dev The latent asset balance is included in the total asset count to account for the "dust collection
    /// strategy".
    /// @dev This function should be favored over `totalAssets` for state-changing functions since it uses
    /// `previewRedeem` over `convertToAssets`.
    /// @dev May revert for reasons that would cause `yieldVault.previewRedeem` to revert.
    /// @return The total assets controlled by the vault based on current onchain conditions
    function totalPreciseAssets() public view returns (uint256) {
        return yieldVault.previewRedeem(yieldVault.balanceOf(address(this))) + _asset.balanceOf(address(this));
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Yield Functions
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Total yield balance of the vault
    /// @dev Equal to total assets minus total debt
    /// @return The total yield balance
    function totalYieldBalance() external view returns (uint256) {
        return _totalYieldBalance(totalPreciseAssets(), totalDebt());
    }

    /// @notice Total available yield on the vault
    /// @dev Equal to total assets minus total allocation (total debt + yield buffer)
    /// @return The available yield balance
    function availableYieldBalance() external view returns (uint256) {
        return _availableYieldBalance(totalPreciseAssets(), totalDebt());
    }

    /// @notice Current amount of assets available in the yield buffer
    /// @return The available assets in the yield buffer
    function currentYieldBuffer() external view returns (uint256) {
        uint256 totalYieldBalance_ = _totalYieldBalance(totalPreciseAssets(), totalDebt());
        uint256 _yieldBuffer = yieldBuffer;
        if (totalYieldBalance_ >= _yieldBuffer) {
            return _yieldBuffer;
        } else {
            return totalYieldBalance_;
        }
    }

    /// @notice Transfers yield fee shares to the yield fee recipient
    /// @param _shares The shares to mint to the yield fee recipient
    /// @dev Emits a `ClaimYieldFeeShares` event
    /// @dev Will revert if the caller is not the yield fee recipient or if zero shares are withdrawn
    function claimYieldFeeShares(uint256 _shares) external onlyYieldFeeRecipient {
        if (_shares == 0) revert MintZeroShares();
        if (_shares > yieldFeeBalance) revert SharesExceedsYieldFeeBalance(_shares, yieldFeeBalance);

        yieldFeeBalance -= _shares;

        _mint(msg.sender, _shares);

        emit ClaimYieldFeeShares(msg.sender, _shares);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // LiquidationSource Functions
    ////////////////////////////////////////////////////////////////////////////////

    /// @inheritdoc ILiquidationSource
    /// @dev Returns the liquid amount of `_tokenOut` minus any yield fees.
    /// @dev Supports the liquidation of either assets or prize vault shares.
    function liquidatableBalanceOf(address _tokenOut) external view returns (uint256) {
        uint256 _totalDebt = totalDebt();
        uint256 _maxAmountOut;
        if (_tokenOut == address(this)) {
            // Liquidation of vault shares is capped to the mint limit.
            _maxAmountOut = _mintLimit(_totalDebt);
        } else if (_tokenOut == address(_asset)) {
            // Liquidation of yield assets is capped at the max yield vault withdraw plus any latent balance.
            _maxAmountOut = _maxYieldVaultWithdraw() + _asset.balanceOf(address(this));
        } else {
            return 0;
        }

        // The liquid yield is limited by the max that can be minted or withdrawn, depending on
        // `_tokenOut`.
        uint256 _availableYield = _availableYieldBalance(totalPreciseAssets(), _totalDebt);
        uint256 _liquidYield = _availableYield >= _maxAmountOut ? _maxAmountOut : _availableYield;

        // The final balance is computed by taking the liquid yield and multiplying it by
        // (1 - yieldFeePercentage), rounding down, to ensure that enough yield is left for
        // the yield fee.
        return _liquidYield.mulDiv(FEE_PRECISION - yieldFeePercentage, FEE_PRECISION);
    }

    /// @inheritdoc ILiquidationSource
    /// @dev Emits a `TransferYieldOut` event
    /// @dev Supports the liquidation of either assets or prize vault shares.
    function transferTokensOut(
        address /* sender */,
        address _receiver,
        address _tokenOut,
        uint256 _amountOut
    ) external virtual onlyLiquidationPair returns (bytes memory) {
        if (_amountOut == 0) revert LiquidationAmountOutZero();

        uint256 _totalDebtBefore = totalDebt();
        uint256 _availableYield = _availableYieldBalance(totalPreciseAssets(), _totalDebtBefore);
        uint32 _yieldFeePercentage = yieldFeePercentage;

        // Determine the proportional yield fee based on the amount being liquidated:
        uint256 _yieldFee;
        if (_yieldFeePercentage != 0) {
            // The yield fee is calculated as a portion of the total yield being consumed, such that 
            // `total = amountOut + yieldFee` and `yieldFee / total = yieldFeePercentage`. 
            _yieldFee = (_amountOut * FEE_PRECISION) / (FEE_PRECISION - _yieldFeePercentage) - _amountOut;
        }

        // Ensure total liquidation amount does not exceed the available yield balance:
        if (_amountOut + _yieldFee > _availableYield) {
            revert LiquidationExceedsAvailable(_amountOut + _yieldFee, _availableYield);
        }

        // Increase yield fee balance:
        if (_yieldFee > 0) {
            yieldFeeBalance = yieldFeeBalance + _yieldFee;
        }

        // Mint or withdraw amountOut to `_receiver`:
        if (_tokenOut == address(_asset)) {
            _enforceMintLimit(_totalDebtBefore, _yieldFee);
            _withdraw(_receiver, _amountOut);
        } else if (_tokenOut == address(this)) {
            _enforceMintLimit(_totalDebtBefore, _amountOut + _yieldFee);
            _mint(_receiver, _amountOut);
        } else {
            revert LiquidationTokenOutNotSupported(_tokenOut);
        }

        emit TransferYieldOut(msg.sender, _tokenOut, _receiver, _amountOut, _yieldFee);

        return "";
    }

    /// @inheritdoc ILiquidationSource
    function verifyTokensIn(
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata /* transferTokensOutData */
    ) external onlyLiquidationPair {
        address _prizeToken = address(prizePool.prizeToken());
        if (_tokenIn != _prizeToken) {
            revert LiquidationTokenInNotPrizeToken(_tokenIn, _prizeToken);
        }

        prizePool.contributePrizeTokens(address(this), _amountIn);
    }

    /// @inheritdoc ILiquidationSource
    function targetOf(address /* tokenIn */) external view returns (address) {
        return address(prizePool);
    }

    /// @inheritdoc ILiquidationSource
    function isLiquidationPair(
        address _tokenOut,
        address _liquidationPair
    ) external view returns (bool) {
        return (_tokenOut == address(_asset) || _tokenOut == address(this)) && _liquidationPair == liquidationPair;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Setter Functions
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Set claimer.
    /// @param _claimer Address of the claimer
    function setClaimer(address _claimer) external onlyOwner {
        _setClaimer(_claimer);
    }

    /// @notice Set liquidationPair.
    /// @dev Emits a `LiquidationPairSet` event
    /// @param _liquidationPair New liquidationPair address
    function setLiquidationPair(address _liquidationPair) external onlyOwner {
        if (address(_liquidationPair) == address(0)) revert LPZeroAddress();

        liquidationPair = _liquidationPair;

        emit LiquidationPairSet(address(this), address(_liquidationPair));
    }

    /// @notice Set yield fee percentage.
    /// @dev Yield fee is defined on a scale from `0` to `FEE_PRECISION`, inclusive.
    /// @param _yieldFeePercentage The new yield fee percentage to set
    function setYieldFeePercentage(uint32 _yieldFeePercentage) external onlyOwner {
        _setYieldFeePercentage(_yieldFeePercentage);
    }

    /// @notice Set fee recipient.
    /// @param _yieldFeeRecipient Address of the fee recipient
    function setYieldFeeRecipient(address _yieldFeeRecipient) external onlyOwner {
        _setYieldFeeRecipient(_yieldFeeRecipient);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Internal Functions
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Fetch decimals of the underlying asset.
    /// @dev A return value of false indicates that the attempt failed in some way.
    /// @param asset_ Address of the underlying asset
    /// @return True if the attempt was successful, false otherwise
    /// @return Number of token decimals
    function _tryGetAssetDecimals(IERC20 asset_) internal view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /// @notice Calculates the amount of assets the vault controls based on current onchain conditions.
    /// @dev Calls `totalPreciseAssets` externally so it can catch `previewRedeem` failures and return
    /// whether or not the call was successful.
    /// @return _success Returns true if totalAssets was successfully calculated and false otherwise
    /// @return _totalAssets The total assets controlled by the vault based on current onchain conditions
    function _tryGetTotalPreciseAssets() internal view returns (bool _success, uint256 _totalAssets) {
        try this.totalPreciseAssets() returns (uint256 _totalPreciseAssets) {
            _success = true;
            _totalAssets = _totalPreciseAssets;
        } catch {
            _success = false;
            _totalAssets = 0;
        }
    }

    /// @notice Converts assets to shares with the given vault state and rounding direction.
    /// @param _assets The assets to convert
    /// @param _totalAssets The total assets that the vault controls
    /// @param _totalDebt The total debt the vault owes
    /// @param _rounding The rounding direction for the conversion
    /// @return The resulting share balance
    function _convertToShares(
        uint256 _assets,
        uint256 _totalAssets,
        uint256 _totalDebt,
        Math.Rounding _rounding
    ) internal pure returns (uint256) {
        if (_totalAssets >= _totalDebt) {
            return _assets;
        } else {
            // If the vault controls less assets than what has been deposited a share will be worth a
            // proportional amount of the total assets. This can happen due to fees, slippage, or loss
            // of funds in the underlying yield vault.
            return _assets.mulDiv(_totalDebt, _totalAssets, _rounding);
        }
    }

    /// @notice Converts shares to assets with the given vault state and rounding direction.
    /// @param _shares The shares to convert
    /// @param _totalAssets The total assets that the vault controls
    /// @param _totalDebt The total debt the vault owes
    /// @param _rounding The rounding direction for the conversion
    /// @return The resulting asset balance
    function _convertToAssets(
        uint256 _shares,
        uint256 _totalAssets,
        uint256 _totalDebt,
        Math.Rounding _rounding
    ) internal pure returns (uint256) {
        if (_totalAssets >= _totalDebt) {
            return _shares;
        } else {
            // If the vault controls less assets than what has been deposited a share will be worth a
            // proportional amount of the total assets. This can happen due to fees, slippage, or loss
            // of funds in the underlying yield vault.
            return _shares.mulDiv(_totalAssets, _totalDebt, _rounding);
        }
    }

    /// @notice Returns the shares that can be minted without exceeding the TwabController supply limit.
    /// @dev The TwabController limits the total supply for each vault.
    /// @param _existingShares The current allocated prize vault shares (internal and external)
    /// @return The remaining shares that can be minted without exceeding TWAB limits
    function _mintLimit(uint256 _existingShares) internal pure returns (uint256) {
        return TWAB_SUPPLY_LIMIT - _existingShares;
    }

    /// @notice Verifies that the mint limit can support the new share balance.
    /// @dev Reverts if the mint limit is exceeded.
    /// @dev This MUST be called anytime there is a positive increase in the net total shares.
    /// @param _existingShares The total existing prize vault shares (internal and external)
    /// @param _newShares The new shares
    function _enforceMintLimit(uint256 _existingShares, uint256 _newShares) internal pure {
        uint256 _limit = _mintLimit(_existingShares);
        if (_newShares > _limit) {
            unchecked {
                revert MintLimitExceeded(_newShares - _limit);
            }
        }
    }

    /// @notice Total yield balance of the vault (including the yield buffer).
    /// @param _totalAssets The total assets controlled by the vault
    /// @param totalDebt_ The total asset debt owed
    /// @return The total yield balance
    function _totalYieldBalance(uint256 _totalAssets, uint256 totalDebt_) internal pure returns (uint256) {
        if (totalDebt_ >= _totalAssets) {
            return 0;
        } else {
            unchecked {
                return _totalAssets - totalDebt_;
            }
        }
    }

    /// @notice Available yield balance given the total assets and total share supply.
    /// @dev Subtracts the yield buffer from the total yield balance.
    /// @param _totalAssets The total assets controlled by the vault
    /// @param totalDebt_ The total asset debt owed
    /// @return The available yield balance
    function _availableYieldBalance(uint256 _totalAssets, uint256 totalDebt_) internal view returns (uint256) {
        uint256 totalYieldBalance_ = _totalYieldBalance(_totalAssets, totalDebt_);
        uint256 _yieldBuffer = yieldBuffer;
        if (totalYieldBalance_ >= _yieldBuffer) {
            unchecked {
                return totalYieldBalance_ - _yieldBuffer;
            }
        } else {
            return 0;
        }
    }

    /// @notice Deposits assets to the yield vault and mints shares
    /// @param _caller The caller of the deposit
    /// @param _receiver The receiver of the deposit shares
    /// @param _assets Amount of assets to deposit
    /// @param _shares Amount of shares to mint
    /// @dev Emits a `Deposit` event.
    /// @dev Will revert if 0 shares are minted back to the receiver or if 0 assets are deposited.
    /// @dev Will revert if the deposit may result in the loss of funds.
    function _depositAndMint(address _caller, address _receiver, uint256 _assets, uint256 _shares) internal {
        if (_shares == 0) revert MintZeroShares();
        if (_assets == 0) revert DepositZeroAssets();

        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook that is triggered after the transfer
        // calls the vault which is assumed to not be malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.

        _asset.safeTransferFrom(
            _caller,
            address(this),
            _assets
        );

        // Previously accumulated dust is swept into the yield vault along with the deposit.
        uint256 _assetsWithDust = _asset.balanceOf(address(this));
        _asset.forceApprove(address(yieldVault), _assetsWithDust);

        // The shares are calculated and then minted directly to mitigate rounding error loss.
        uint256 _yieldVaultShares = yieldVault.previewDeposit(_assetsWithDust);
        yieldVault.mint(_yieldVaultShares, address(this));

        // Enforce the mint limit and protect against lossy deposits.
        uint256 _totalDebtBeforeMint = totalDebt();
        _enforceMintLimit(_totalDebtBeforeMint, _shares);
        if (totalPreciseAssets() < _totalDebtBeforeMint + _shares) {
            revert LossyDeposit(totalPreciseAssets(), _totalDebtBeforeMint + _shares);
        }

        _mint(_receiver, _shares);

        emit Deposit(_caller, _receiver, _assets, _shares);
    }

    /// @notice Burns shares and withdraws assets from the underlying yield vault.
    /// @param _caller Address of the caller
    /// @param _receiver Address of the receiver of the assets
    /// @param _owner Owner of the shares
    /// @param _shares Shares to burn
    /// @param _assets Assets to withdraw
    /// @dev Emits a `Withdraw` event.
    /// @dev Will revert if 0 assets are withdrawn or if 0 shares are burned
    function _burnAndWithdraw(
        address _caller,
        address _receiver,
        address _owner,
        uint256 _shares,
        uint256 _assets
    ) internal {
        if (_assets == 0) revert WithdrawZeroAssets();
        if (_shares == 0) revert BurnZeroShares();
        if (_caller != _owner) {
            _spendAllowance(_owner, _caller, _shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(_owner, _shares);
        _withdraw(_receiver, _assets);

        emit Withdraw(_caller, _receiver, _owner, _assets, _shares);
    }

    /// @notice Returns the max assets that can be withdrawn from the yield vault through this vault's
    /// `_withdraw` function.
    /// @dev This should be used over `yieldVault.maxWithdraw` when considering withdrawal limits since
    /// this function takes into account the yield vault redemption limits, which is necessary since the
    /// `_withdraw` function uses `yieldVault.redeem` instead of `yieldVault.withdraw`. Since we convert
    /// the max redeemable shares to assets rounding down, the `yieldVault.previewWithdraw` call in the
    /// `_withdraw` function is guaranteed to return less than or equal shares to the max yield vault 
    /// redemption.
    /// @dev Returns zero if `yieldVault.previewRedeem` reverts.
    /// @return The max assets that can be withdrawn from the yield vault.
    function _maxYieldVaultWithdraw() internal view returns (uint256) {
        try yieldVault.previewRedeem(yieldVault.maxRedeem(address(this))) returns (uint256 _maxAssets) {
            return _maxAssets;
        } catch {
            return 0;
        }
    }

    /// @notice Withdraws assets to the receiver while accounting for rounding errors.
    /// @param _receiver The receiver of the assets
    /// @param _assets The assets to withdraw
    function _withdraw(address _receiver, uint256 _assets) internal {
        // The vault accumulates dust from rounding errors over time, so if we can fulfill the withdrawal from the
        // latent balance, we don't need to redeem any yield vault shares.
        uint256 _latentAssets = _asset.balanceOf(address(this));
        if (_assets > _latentAssets) {
            // The latent balance is subtracted from the withdrawal so we don't withdraw more than we need.
            uint256 _yieldVaultShares = yieldVault.previewWithdraw(_assets - _latentAssets);
            // Assets are sent to this contract so any leftover dust can be redeposited later.
            yieldVault.redeem(_yieldVaultShares, address(this), address(this));
        }
        if (_receiver != address(this)) {
            _asset.safeTransfer(_receiver, _assets);
        }
    }

    /// @notice Set yield fee percentage.
    /// @dev Yield fee is defined on a scale from `0` to `MAX_YIELD_FEE`, inclusive.
    /// @dev Emits a `YieldFeePercentageSet` event
    /// @param _yieldFeePercentage The new yield fee percentage to set
    function _setYieldFeePercentage(uint32 _yieldFeePercentage) internal {
        if (_yieldFeePercentage > MAX_YIELD_FEE) {
            revert YieldFeePercentageExceedsMax(_yieldFeePercentage, MAX_YIELD_FEE);
        }
        yieldFeePercentage = _yieldFeePercentage;
        emit YieldFeePercentageSet(_yieldFeePercentage);
    }

    /// @notice Set yield fee recipient address.
    /// @dev Emits a `YieldFeeRecipientSet` event
    /// @param _yieldFeeRecipient Address of the fee recipient
    function _setYieldFeeRecipient(address _yieldFeeRecipient) internal {
        yieldFeeRecipient = _yieldFeeRecipient;
        emit YieldFeeRecipientSet(_yieldFeeRecipient);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/*

██████╗ ██████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗  ██╗
██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
██████╔╝██████╔╝██████╔╝██╔████╔██║███████║   ██║   ███████║
██╔═══╝ ██╔══██╗██╔══██╗██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
██║     ██║  ██║██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

███████╗██████╗ ███████╗ █████╗ ██╗  ██╗ ██╗ █████╗
██╔════╝██╔══██╗██╔════╝██╔══██╗╚██╗██╔╝███║██╔══██╗
███████╗██║  ██║███████╗╚██████║ ╚███╔╝ ╚██║╚█████╔╝
╚════██║██║  ██║╚════██║ ╚═══██║ ██╔██╗  ██║██╔══██╗
███████║██████╔╝███████║ █████╔╝██╔╝ ██╗ ██║╚█████╔╝
╚══════╝╚═════╝ ╚══════╝ ╚════╝ ╚═╝  ╚═╝ ╚═╝ ╚════╝

*/

import "./sd59x18/Casting.sol";
import "./sd59x18/Constants.sol";
import "./sd59x18/Conversions.sol";
import "./sd59x18/Errors.sol";
import "./sd59x18/Helpers.sol";
import "./sd59x18/Math.sol";
import "./sd59x18/ValueType.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/*

██████╗ ██████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗  ██╗
██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
██████╔╝██████╔╝██████╔╝██╔████╔██║███████║   ██║   ███████║
██╔═══╝ ██╔══██╗██╔══██╗██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
██║     ██║  ██║██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

███████╗██████╗  ██╗██╗  ██╗ ██╗ █████╗
██╔════╝██╔══██╗███║╚██╗██╔╝███║██╔══██╗
███████╗██║  ██║╚██║ ╚███╔╝ ╚██║╚█████╔╝
╚════██║██║  ██║ ██║ ██╔██╗  ██║██╔══██╗
███████║██████╔╝ ██║██╔╝ ██╗ ██║╚█████╔╝
╚══════╝╚═════╝  ╚═╝╚═╝  ╚═╝ ╚═╝ ╚════╝

*/

import "./sd1x18/Casting.sol";
import "./sd1x18/Constants.sol";
import "./sd1x18/Errors.sol";
import "./sd1x18/ValueType.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { SafeCast } from "openzeppelin/utils/math/SafeCast.sol";
import { TwabLib } from "./libraries/TwabLib.sol";
import { ObservationLib } from "./libraries/ObservationLib.sol";

/// @notice Emitted when an account already points to the same delegate address that is being set
error SameDelegateAlreadySet(address delegate);

/// @notice Emitted when an account tries to transfer to the sponsorship address
error CannotTransferToSponsorshipAddress();

/// @notice Emitted when the period length is too short
error PeriodLengthTooShort();

/// @notice Emitted when the period offset is not in the past.
/// @param periodOffset The period offset that was passed in
error PeriodOffsetInFuture(uint32 periodOffset);

/// @notice Emitted when a user tries to mint or transfer to the zero address
error TransferToZeroAddress();

// The minimum period length
uint32 constant MINIMUM_PERIOD_LENGTH = 1 hours;

// Allows users to revoke their chances to win by delegating to the sponsorship address.
address constant SPONSORSHIP_ADDRESS = address(1);

/**
 * @title  PoolTogether V5 Time-Weighted Average Balance Controller
 * @author PoolTogether Inc. & G9 Software Inc.
 * @dev    Time-Weighted Average Balance Controller for ERC20 tokens.
 * @notice This TwabController uses the TwabLib to provide token balances and on-chain historical
            lookups to a user(s) time-weighted average balance. Each user is mapped to an
            Account struct containing the TWAB history (ring buffer) and ring buffer parameters.
            Every token.transfer() creates a new TWAB observation. The new TWAB observation is
            stored in the circular ring buffer as either a new observation or rewriting a
            previous observation with new parameters. One observation per period is stored.
            The TwabLib guarantees minimum 1 year of search history if a period is a day.
 */
contract TwabController {
  using SafeCast for uint256;

  /// @notice Sets the minimum period length for Observations. When a period elapses, a new Observation is recorded, otherwise the most recent Observation is updated.
  uint32 public immutable PERIOD_LENGTH;

  /// @notice Sets the beginning timestamp for the first period. This allows us to maximize storage as well as line up periods with a chosen timestamp.
  /// @dev Ensure that the PERIOD_OFFSET is in the past.
  uint32 public immutable PERIOD_OFFSET;

  /* ============ State ============ */

  /// @notice Record of token holders TWABs for each account for each vault.
  mapping(address => mapping(address => TwabLib.Account)) internal userObservations;

  /// @notice Record of tickets total supply and ring buff parameters used for observation.
  mapping(address => TwabLib.Account) internal totalSupplyObservations;

  /// @notice vault => user => delegate.
  mapping(address => mapping(address => address)) internal delegates;

  /* ============ Events ============ */

  /**
   * @notice Emitted when a balance or delegateBalance is increased.
   * @param vault the vault for which the balance increased
   * @param user the users whose balance increased
   * @param amount the amount the balance increased by
   * @param delegateAmount the amount the delegateBalance increased by
   */
  event IncreasedBalance(
    address indexed vault,
    address indexed user,
    uint96 amount,
    uint96 delegateAmount
  );

  /**
   * @notice Emitted when a balance or delegateBalance is decreased.
   * @param vault the vault for which the balance decreased
   * @param user the users whose balance decreased
   * @param amount the amount the balance decreased by
   * @param delegateAmount the amount the delegateBalance decreased by
   */
  event DecreasedBalance(
    address indexed vault,
    address indexed user,
    uint96 amount,
    uint96 delegateAmount
  );

  /**
   * @notice Emitted when an Observation is recorded to the Ring Buffer.
   * @param vault the vault for which the Observation was recorded
   * @param user the users whose Observation was recorded
   * @param balance the resulting balance
   * @param delegateBalance the resulting delegated balance
   * @param isNew whether the observation is new or not
   * @param observation the observation that was created or updated
   */
  event ObservationRecorded(
    address indexed vault,
    address indexed user,
    uint96 balance,
    uint96 delegateBalance,
    bool isNew,
    ObservationLib.Observation observation
  );

  /**
   * @notice Emitted when a user delegates their balance to another address.
   * @param vault the vault for which the balance was delegated
   * @param delegator the user who delegated their balance
   * @param delegate the user who received the delegated balance
   */
  event Delegated(address indexed vault, address indexed delegator, address indexed delegate);

  /**
   * @notice Emitted when the total supply or delegateTotalSupply is increased.
   * @param vault the vault for which the total supply increased
   * @param amount the amount the total supply increased by
   * @param delegateAmount the amount the delegateTotalSupply increased by
   */
  event IncreasedTotalSupply(address indexed vault, uint96 amount, uint96 delegateAmount);

  /**
   * @notice Emitted when the total supply or delegateTotalSupply is decreased.
   * @param vault the vault for which the total supply decreased
   * @param amount the amount the total supply decreased by
   * @param delegateAmount the amount the delegateTotalSupply decreased by
   */
  event DecreasedTotalSupply(address indexed vault, uint96 amount, uint96 delegateAmount);

  /**
   * @notice Emitted when a Total Supply Observation is recorded to the Ring Buffer.
   * @param vault the vault for which the Observation was recorded
   * @param balance the resulting balance
   * @param delegateBalance the resulting delegated balance
   * @param isNew whether the observation is new or not
   * @param observation the observation that was created or updated
   */
  event TotalSupplyObservationRecorded(
    address indexed vault,
    uint96 balance,
    uint96 delegateBalance,
    bool isNew,
    ObservationLib.Observation observation
  );

  /* ============ Constructor ============ */

  /**
   * @notice Construct a new TwabController.
   * @dev Reverts if the period offset is in the future.
   * @param _periodLength Sets the minimum period length for Observations. When a period elapses, a new Observation
   *      is recorded, otherwise the most recent Observation is updated.
   * @param _periodOffset Sets the beginning timestamp for the first period. This allows us to maximize storage as well
   *      as line up periods with a chosen timestamp.
   */
  constructor(uint32 _periodLength, uint32 _periodOffset) {
    if (_periodLength < MINIMUM_PERIOD_LENGTH) {
      revert PeriodLengthTooShort();
    }
    if (_periodOffset > block.timestamp) {
      revert PeriodOffsetInFuture(_periodOffset);
    }
    PERIOD_LENGTH = _periodLength;
    PERIOD_OFFSET = _periodOffset;
  }

  /* ============ External Read Functions ============ */

  /**
   * @notice Returns whether the TwabController has been shutdown at the given timestamp
   * If the twab is queried at or after this time, whether an absolute timestamp or time range, it will return 0.
   * @dev This function will return true for any timestamp after the lastObservationAt()
   * @param timestamp The timestamp to check
   * @return True if the TwabController is shutdown at the given timestamp, false otherwise.
   */
  function isShutdownAt(uint256 timestamp) external view returns (bool) {
    return TwabLib.isShutdownAt(timestamp, PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Computes the timestamp after which no more observations will be made.
   * @return The largest timestamp at which the TwabController can record a new observation.
   */
  function lastObservationAt() external view returns (uint256) {
    return TwabLib.lastObservationAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Loads the current TWAB Account data for a specific vault stored for a user.
   * @dev Note this is a very expensive function
   * @param vault the vault for which the data is being queried
   * @param user the user whose data is being queried
   * @return The current TWAB Account data of the user
   */
  function getAccount(address vault, address user) external view returns (TwabLib.Account memory) {
    return userObservations[vault][user];
  }

  /**
   * @notice Loads the current total supply TWAB Account data for a specific vault.
   * @dev Note this is a very expensive function
   * @param vault the vault for which the data is being queried
   * @return The current total supply TWAB Account data
   */
  function getTotalSupplyAccount(address vault) external view returns (TwabLib.Account memory) {
    return totalSupplyObservations[vault];
  }

  /**
   * @notice The current token balance of a user for a specific vault.
   * @param vault the vault for which the balance is being queried
   * @param user the user whose balance is being queried
   * @return The current token balance of the user
   */
  function balanceOf(address vault, address user) external view returns (uint256) {
    return userObservations[vault][user].details.balance;
  }

  /**
   * @notice The total supply of tokens for a vault.
   * @param vault the vault for which the total supply is being queried
   * @return The total supply of tokens for a vault
   */
  function totalSupply(address vault) external view returns (uint256) {
    return totalSupplyObservations[vault].details.balance;
  }

  /**
   * @notice The total delegated amount of tokens for a vault.
   * @dev Delegated balance is not 1:1 with the token total supply. Users may delegate their
   *      balance to the sponsorship address, which will result in those tokens being subtracted
   *      from the total.
   * @param vault the vault for which the total delegated supply is being queried
   * @return The total delegated amount of tokens for a vault
   */
  function totalSupplyDelegateBalance(address vault) external view returns (uint256) {
    return totalSupplyObservations[vault].details.delegateBalance;
  }

  /**
   * @notice The current delegate of a user for a specific vault.
   * @param vault the vault for which the delegate balance is being queried
   * @param user the user whose delegate balance is being queried
   * @return The current delegate balance of the user
   */
  function delegateOf(address vault, address user) external view returns (address) {
    return _delegateOf(vault, user);
  }

  /**
   * @notice The current delegateBalance of a user for a specific vault.
   * @dev the delegateBalance is the sum of delegated balance to this user
   * @param vault the vault for which the delegateBalance is being queried
   * @param user the user whose delegateBalance is being queried
   * @return The current delegateBalance of the user
   */
  function delegateBalanceOf(address vault, address user) external view returns (uint256) {
    return userObservations[vault][user].details.delegateBalance;
  }

  /**
   * @notice Looks up a users balance at a specific time in the past.
   * @param vault the vault for which the balance is being queried
   * @param user the user whose balance is being queried
   * @param periodEndOnOrAfterTime The time in the past for which the balance is being queried. The time will be snapped to a period end time on or after the timestamp.
   * @return The balance of the user at the target time
   */
  function getBalanceAt(
    address vault,
    address user,
    uint256 periodEndOnOrAfterTime
  ) external view returns (uint256) {
    TwabLib.Account storage _account = userObservations[vault][user];
    return
      TwabLib.getBalanceAt(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account.observations,
        _account.details,
        _periodEndOnOrAfter(periodEndOnOrAfterTime)
      );
  }

  /**
   * @notice Looks up the total supply at a specific time in the past.
   * @param vault the vault for which the total supply is being queried
   * @param periodEndOnOrAfterTime The time in the past for which the balance is being queried. The time will be snapped to a period end time on or after the timestamp.
   * @return The total supply at the target time
   */
  function getTotalSupplyAt(
    address vault,
    uint256 periodEndOnOrAfterTime
  ) external view returns (uint256) {
    TwabLib.Account storage _account = totalSupplyObservations[vault];
    return
      TwabLib.getBalanceAt(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account.observations,
        _account.details,
        _periodEndOnOrAfter(periodEndOnOrAfterTime)
      );
  }

  /**
   * @notice Looks up the average balance of a user between two timestamps.
   * @dev Timestamps are Unix timestamps denominated in seconds
   * @param vault the vault for which the average balance is being queried
   * @param user the user whose average balance is being queried
   * @param startTime the start of the time range for which the average balance is being queried. The time will be snapped to a period end time on or after the timestamp.
   * @param endTime the end of the time range for which the average balance is being queried. The time will be snapped to a period end time on or after the timestamp.
   * @return The average balance of the user between the two timestamps
   */
  function getTwabBetween(
    address vault,
    address user,
    uint256 startTime,
    uint256 endTime
  ) external view returns (uint256) {
    TwabLib.Account storage _account = userObservations[vault][user];
    // We snap the timestamps to the period end on or after the timestamp because the total supply records will be sparsely populated.
    // if two users update during a period, then the total supply observation will only exist for the last one.
    return
      TwabLib.getTwabBetween(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account.observations,
        _account.details,
        _periodEndOnOrAfter(startTime),
        _periodEndOnOrAfter(endTime)
      );
  }

  /**
   * @notice Looks up the average total supply between two timestamps.
   * @dev Timestamps are Unix timestamps denominated in seconds
   * @param vault the vault for which the average total supply is being queried
   * @param startTime the start of the time range for which the average total supply is being queried
   * @param endTime the end of the time range for which the average total supply is being queried
   * @return The average total supply between the two timestamps
   */
  function getTotalSupplyTwabBetween(
    address vault,
    uint256 startTime,
    uint256 endTime
  ) external view returns (uint256) {
    TwabLib.Account storage _account = totalSupplyObservations[vault];
    // We snap the timestamps to the period end on or after the timestamp because the total supply records will be sparsely populated.
    // if two users update during a period, then the total supply observation will only exist for the last one.
    return
      TwabLib.getTwabBetween(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account.observations,
        _account.details,
        _periodEndOnOrAfter(startTime),
        _periodEndOnOrAfter(endTime)
      );
  }

  /**
   * @notice Computes the period end timestamp on or after the given timestamp.
   * @param _timestamp The timestamp to check
   * @return The end timestamp of the period that ends on or immediately after the given timestamp
   */
  function periodEndOnOrAfter(uint256 _timestamp) external view returns (uint256) {
    return _periodEndOnOrAfter(_timestamp);
  }

  /**
   * @notice Computes the period end timestamp on or after the given timestamp.
   * @param _timestamp The timestamp to compute the period end time for
   * @return A period end time.
   */
  function _periodEndOnOrAfter(uint256 _timestamp) internal view returns (uint256) {
    if (_timestamp < PERIOD_OFFSET) {
      return PERIOD_OFFSET;
    }
    if ((_timestamp - PERIOD_OFFSET) % PERIOD_LENGTH == 0) {
      return _timestamp;
    }
    uint256 period = TwabLib.getTimestampPeriod(PERIOD_LENGTH, PERIOD_OFFSET, _timestamp);
    return TwabLib.getPeriodEndTime(PERIOD_LENGTH, PERIOD_OFFSET, period);
  }

  /**
   * @notice Looks up the newest observation for a user.
   * @param vault the vault for which the observation is being queried
   * @param user the user whose observation is being queried
   * @return index The index of the observation
   * @return observation The observation of the user
   */
  function getNewestObservation(
    address vault,
    address user
  ) external view returns (uint16, ObservationLib.Observation memory) {
    TwabLib.Account storage _account = userObservations[vault][user];
    return TwabLib.getNewestObservation(_account.observations, _account.details);
  }

  /**
   * @notice Looks up the oldest observation for a user.
   * @param vault the vault for which the observation is being queried
   * @param user the user whose observation is being queried
   * @return index The index of the observation
   * @return observation The observation of the user
   */
  function getOldestObservation(
    address vault,
    address user
  ) external view returns (uint16, ObservationLib.Observation memory) {
    TwabLib.Account storage _account = userObservations[vault][user];
    return TwabLib.getOldestObservation(_account.observations, _account.details);
  }

  /**
   * @notice Looks up the newest total supply observation for a vault.
   * @param vault the vault for which the observation is being queried
   * @return index The index of the observation
   * @return observation The total supply observation
   */
  function getNewestTotalSupplyObservation(
    address vault
  ) external view returns (uint16, ObservationLib.Observation memory) {
    TwabLib.Account storage _account = totalSupplyObservations[vault];
    return TwabLib.getNewestObservation(_account.observations, _account.details);
  }

  /**
   * @notice Looks up the oldest total supply observation for a vault.
   * @param vault the vault for which the observation is being queried
   * @return index The index of the observation
   * @return observation The total supply observation
   */
  function getOldestTotalSupplyObservation(
    address vault
  ) external view returns (uint16, ObservationLib.Observation memory) {
    TwabLib.Account storage _account = totalSupplyObservations[vault];
    return TwabLib.getOldestObservation(_account.observations, _account.details);
  }

  /**
   * @notice Calculates the period a timestamp falls into.
   * @param time The timestamp to check
   * @return period The period the timestamp falls into
   */
  function getTimestampPeriod(uint256 time) external view returns (uint256) {
    return TwabLib.getTimestampPeriod(PERIOD_LENGTH, PERIOD_OFFSET, time);
  }

  /**
   * @notice Checks if the given timestamp is before the current overwrite period.
   * @param time The timestamp to check
   * @return True if the given time is finalized, false if it's during the current overwrite period.
   */
  function hasFinalized(uint256 time) external view returns (bool) {
    return TwabLib.hasFinalized(PERIOD_LENGTH, PERIOD_OFFSET, time);
  }

  /**
   * @notice Computes the timestamp at which the current overwrite period started.
   * @dev The overwrite period is the period during which observations are collated.
   * @return period The timestamp at which the current overwrite period started.
   */
  function currentOverwritePeriodStartedAt() external view returns (uint256) {
    return TwabLib.currentOverwritePeriodStartedAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /* ============ External Write Functions ============ */

  /**
   * @notice Mints new balance and delegateBalance for a given user.
   * @dev Note that if the provided user to mint to is delegating that the delegate's
   *      delegateBalance will be updated.
   * @dev Mint is expected to be called by the Vault.
   * @param _to The address to mint balance and delegateBalance to
   * @param _amount The amount to mint
   */
  function mint(address _to, uint96 _amount) external {
    if (_to == address(0)) {
      revert TransferToZeroAddress();
    }
    _transferBalance(msg.sender, address(0), _to, _amount);
  }

  /**
   * @notice Burns balance and delegateBalance for a given user.
   * @dev Note that if the provided user to burn from is delegating that the delegate's
   *      delegateBalance will be updated.
   * @dev Burn is expected to be called by the Vault.
   * @param _from The address to burn balance and delegateBalance from
   * @param _amount The amount to burn
   */
  function burn(address _from, uint96 _amount) external {
    _transferBalance(msg.sender, _from, address(0), _amount);
  }

  /**
   * @notice Transfers balance and delegateBalance from a given user.
   * @dev Note that if the provided user to transfer from is delegating that the delegate's
   *      delegateBalance will be updated.
   * @param _from The address to transfer the balance and delegateBalance from
   * @param _to The address to transfer balance and delegateBalance to
   * @param _amount The amount to transfer
   */
  function transfer(address _from, address _to, uint96 _amount) external {
    if (_to == address(0)) {
      revert TransferToZeroAddress();
    }
    _transferBalance(msg.sender, _from, _to, _amount);
  }

  /**
   * @notice Sets a delegate for a user which forwards the delegateBalance tied to the user's
   *          balance to the delegate's delegateBalance.
   * @param _vault The vault for which the delegate is being set
   * @param _to the address to delegate to
   */
  function delegate(address _vault, address _to) external {
    _delegate(_vault, msg.sender, _to);
  }

  /**
   * @notice Delegate user balance to the sponsorship address.
   * @dev Must only be called by the Vault contract.
   * @param _from Address of the user delegating their balance to the sponsorship address.
   */
  function sponsor(address _from) external {
    _delegate(msg.sender, _from, SPONSORSHIP_ADDRESS);
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Transfers a user's vault balance from one address to another.
   * @dev If the user is delegating, their delegate's delegateBalance is also updated.
   * @dev If we are minting or burning tokens then the total supply is also updated.
   * @param _vault the vault for which the balance is being transferred
   * @param _from the address from which the balance is being transferred
   * @param _to the address to which the balance is being transferred
   * @param _amount the amount of balance being transferred
   */
  function _transferBalance(address _vault, address _from, address _to, uint96 _amount) internal {
    if (_to == SPONSORSHIP_ADDRESS) {
      revert CannotTransferToSponsorshipAddress();
    }

    if (_from == _to) {
      return;
    }

    // If we are transferring tokens from a delegated account to an undelegated account
    address _fromDelegate = _delegateOf(_vault, _from);
    address _toDelegate = _delegateOf(_vault, _to);
    if (_from != address(0)) {
      bool _isFromDelegate = _fromDelegate == _from;

      _decreaseBalances(_vault, _from, _amount, _isFromDelegate ? _amount : 0);

      // If the user is not delegating to themself, decrease the delegate's delegateBalance
      // If the user is delegating to the sponsorship address, don't adjust the delegateBalance
      if (!_isFromDelegate && _fromDelegate != SPONSORSHIP_ADDRESS) {
        _decreaseBalances(_vault, _fromDelegate, 0, _amount);
      }

      // Burn balance if we're transferring to address(0)
      // Burn delegateBalance if we're transferring to address(0) and burning from an address that is not delegating to the sponsorship address
      // Burn delegateBalance if we're transferring to an address delegating to the sponsorship address from an address that isn't delegating to the sponsorship address
      if (
        _to == address(0) ||
        (_toDelegate == SPONSORSHIP_ADDRESS && _fromDelegate != SPONSORSHIP_ADDRESS)
      ) {
        // If the user is delegating to the sponsorship address, don't adjust the total supply delegateBalance
        _decreaseTotalSupplyBalances(
          _vault,
          _to == address(0) ? _amount : 0,
          (_to == address(0) && _fromDelegate != SPONSORSHIP_ADDRESS) ||
            (_toDelegate == SPONSORSHIP_ADDRESS && _fromDelegate != SPONSORSHIP_ADDRESS)
            ? _amount
            : 0
        );
      }
    }

    // If we are transferring tokens to an address other than address(0)
    if (_to != address(0)) {
      bool _isToDelegate = _toDelegate == _to;

      // If the user is delegating to themself, increase their delegateBalance
      _increaseBalances(_vault, _to, _amount, _isToDelegate ? _amount : 0);

      // Otherwise, increase their delegates delegateBalance if it is not the sponsorship address
      if (!_isToDelegate && _toDelegate != SPONSORSHIP_ADDRESS) {
        _increaseBalances(_vault, _toDelegate, 0, _amount);
      }

      // Mint balance if we're transferring from address(0)
      // Mint delegateBalance if we're transferring from address(0) and to an address not delegating to the sponsorship address
      // Mint delegateBalance if we're transferring from an address delegating to the sponsorship address to an address that isn't delegating to the sponsorship address
      if (
        _from == address(0) ||
        (_fromDelegate == SPONSORSHIP_ADDRESS && _toDelegate != SPONSORSHIP_ADDRESS)
      ) {
        _increaseTotalSupplyBalances(
          _vault,
          _from == address(0) ? _amount : 0,
          (_from == address(0) && _toDelegate != SPONSORSHIP_ADDRESS) ||
            (_fromDelegate == SPONSORSHIP_ADDRESS && _toDelegate != SPONSORSHIP_ADDRESS)
            ? _amount
            : 0
        );
      }
    }
  }

  /**
   * @notice Looks up the delegate of a user.
   * @param _vault the vault for which the user's delegate is being queried
   * @param _user the address to query the delegate of
   * @return The address of the user's delegate
   */
  function _delegateOf(address _vault, address _user) internal view returns (address) {
    address _userDelegate;

    if (_user != address(0)) {
      _userDelegate = delegates[_vault][_user];

      // If the user has not delegated, then the user is the delegate
      if (_userDelegate == address(0)) {
        _userDelegate = _user;
      }
    }

    return _userDelegate;
  }

  /**
   * @notice Transfers a user's vault delegateBalance from one address to another.
   * @param _vault the vault for which the delegateBalance is being transferred
   * @param _fromDelegate the address from which the delegateBalance is being transferred
   * @param _toDelegate the address to which the delegateBalance is being transferred
   * @param _amount the amount of delegateBalance being transferred
   */
  function _transferDelegateBalance(
    address _vault,
    address _fromDelegate,
    address _toDelegate,
    uint96 _amount
  ) internal {
    // If we are transferring tokens from a delegated account to an undelegated account
    if (_fromDelegate != address(0) && _fromDelegate != SPONSORSHIP_ADDRESS) {
      _decreaseBalances(_vault, _fromDelegate, 0, _amount);

      // If we are delegating to the zero address, decrease total supply
      // If we are delegating to the sponsorship address, decrease total supply
      if (_toDelegate == address(0) || _toDelegate == SPONSORSHIP_ADDRESS) {
        _decreaseTotalSupplyBalances(_vault, 0, _amount);
      }
    }

    // If we are transferring tokens from an undelegated account to a delegated account
    if (_toDelegate != address(0) && _toDelegate != SPONSORSHIP_ADDRESS) {
      _increaseBalances(_vault, _toDelegate, 0, _amount);

      // If we are removing delegation from the zero address, increase total supply
      // If we are removing delegation from the sponsorship address, increase total supply
      if (_fromDelegate == address(0) || _fromDelegate == SPONSORSHIP_ADDRESS) {
        _increaseTotalSupplyBalances(_vault, 0, _amount);
      }
    }
  }

  /**
   * @notice Sets a delegate for a user which forwards the delegateBalance tied to the user's
   * balance to the delegate's delegateBalance. "Sponsoring" means the funds aren't delegated
   * to anyone; this can be done by passing address(0) or the SPONSORSHIP_ADDRESS as the delegate.
   * @param _vault The vault for which the delegate is being set
   * @param _from the address to delegate from
   * @param _to the address to delegate to
   */
  function _delegate(address _vault, address _from, address _to) internal {
    address _currentDelegate = _delegateOf(_vault, _from);
    // address(0) is interpreted as sponsoring, so they don't need to know the sponsorship address.
    address to = _to == address(0) ? SPONSORSHIP_ADDRESS : _to;
    if (to == _currentDelegate) {
      revert SameDelegateAlreadySet(to);
    }

    delegates[_vault][_from] = to;

    _transferDelegateBalance(
      _vault,
      _currentDelegate,
      _to,
      SafeCast.toUint96(userObservations[_vault][_from].details.balance)
    );

    emit Delegated(_vault, _from, to);
  }

  /**
   * @notice Increases a user's balance and delegateBalance for a specific vault.
   * @param _vault the vault for which the balance is being increased
   * @param _user the address of the user whose balance is being increased
   * @param _amount the amount of balance being increased
   * @param _delegateAmount the amount of delegateBalance being increased
   */
  function _increaseBalances(
    address _vault,
    address _user,
    uint96 _amount,
    uint96 _delegateAmount
  ) internal {
    TwabLib.Account storage _account = userObservations[_vault][_user];

    (
      ObservationLib.Observation memory _observation,
      bool _isNewObservation,
      bool _isObservationRecorded,
      TwabLib.AccountDetails memory accountDetails
    ) = TwabLib.increaseBalances(PERIOD_LENGTH, PERIOD_OFFSET, _account, _amount, _delegateAmount);

    // Always emit the balance change event
    if (_amount != 0 || _delegateAmount != 0) {
      emit IncreasedBalance(_vault, _user, _amount, _delegateAmount);
    }

    // Conditionally emit the observation recorded event
    if (_isObservationRecorded) {
      emit ObservationRecorded(
        _vault,
        _user,
        accountDetails.balance,
        accountDetails.delegateBalance,
        _isNewObservation,
        _observation
      );
    }
  }

  /**
   * @notice Decreases the a user's balance and delegateBalance for a specific vault.
   * @param _vault the vault for which the totalSupply balance is being decreased
   * @param _amount the amount of balance being decreased
   * @param _delegateAmount the amount of delegateBalance being decreased
   */
  function _decreaseBalances(
    address _vault,
    address _user,
    uint96 _amount,
    uint96 _delegateAmount
  ) internal {
    TwabLib.Account storage _account = userObservations[_vault][_user];

    (
      ObservationLib.Observation memory _observation,
      bool _isNewObservation,
      bool _isObservationRecorded,
      TwabLib.AccountDetails memory accountDetails
    ) = TwabLib.decreaseBalances(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account,
        _amount,
        _delegateAmount,
        "TC/observation-burn-lt-delegate-balance"
      );

    // Always emit the balance change event
    if (_amount != 0 || _delegateAmount != 0) {
      emit DecreasedBalance(_vault, _user, _amount, _delegateAmount);
    }

    // Conditionally emit the observation recorded event
    if (_isObservationRecorded) {
      emit ObservationRecorded(
        _vault,
        _user,
        accountDetails.balance,
        accountDetails.delegateBalance,
        _isNewObservation,
        _observation
      );
    }
  }

  /**
   * @notice Decreases the totalSupply balance and delegateBalance for a specific vault.
   * @param _vault the vault for which the totalSupply balance is being decreased
   * @param _amount the amount of balance being decreased
   * @param _delegateAmount the amount of delegateBalance being decreased
   */
  function _decreaseTotalSupplyBalances(
    address _vault,
    uint96 _amount,
    uint96 _delegateAmount
  ) internal {
    TwabLib.Account storage _account = totalSupplyObservations[_vault];

    (
      ObservationLib.Observation memory _observation,
      bool _isNewObservation,
      bool _isObservationRecorded,
      TwabLib.AccountDetails memory accountDetails
    ) = TwabLib.decreaseBalances(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account,
        _amount,
        _delegateAmount,
        "TC/burn-amount-exceeds-total-supply-balance"
      );

    // Always emit the balance change event
    if (_amount != 0 || _delegateAmount != 0) {
      emit DecreasedTotalSupply(_vault, _amount, _delegateAmount);
    }

    // Conditionally emit the observation recorded event
    if (_isObservationRecorded) {
      emit TotalSupplyObservationRecorded(
        _vault,
        accountDetails.balance,
        accountDetails.delegateBalance,
        _isNewObservation,
        _observation
      );
    }
  }

  /**
   * @notice Increases the totalSupply balance and delegateBalance for a specific vault.
   * @param _vault the vault for which the totalSupply balance is being increased
   * @param _amount the amount of balance being increased
   * @param _delegateAmount the amount of delegateBalance being increased
   */
  function _increaseTotalSupplyBalances(
    address _vault,
    uint96 _amount,
    uint96 _delegateAmount
  ) internal {
    TwabLib.Account storage _account = totalSupplyObservations[_vault];

    (
      ObservationLib.Observation memory _observation,
      bool _isNewObservation,
      bool _isObservationRecorded,
      TwabLib.AccountDetails memory accountDetails
    ) = TwabLib.increaseBalances(PERIOD_LENGTH, PERIOD_OFFSET, _account, _amount, _delegateAmount);

    // Always emit the balance change event
    if (_amount != 0 || _delegateAmount != 0) {
      emit IncreasedTotalSupply(_vault, _amount, _delegateAmount);
    }

    // Conditionally emit the observation recorded event
    if (_isObservationRecorded) {
      emit TotalSupplyObservationRecorded(
        _vault,
        accountDetails.balance,
        accountDetails.delegateBalance,
        _isNewObservation,
        _observation
      );
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { SafeCast } from "openzeppelin/utils/math/SafeCast.sol";
import { RingBufferLib } from "ring-buffer-lib/RingBufferLib.sol";

// The maximum number of observations that can be recorded.
uint16 constant MAX_OBSERVATION_CARDINALITY = 366;

/// @notice Thrown when adding balance for draw zero.
error AddToDrawZero();

/// @notice Thrown when an action can't be done on a closed draw.
/// @param drawId The ID of the closed draw
/// @param newestDrawId The newest draw ID
error DrawAwarded(uint24 drawId, uint24 newestDrawId);

/// @notice Thrown when a draw range is not strictly increasing.
/// @param startDrawId The start draw ID of the range
/// @param endDrawId The end draw ID of the range
error InvalidDrawRange(uint24 startDrawId, uint24 endDrawId);

/// @notice The accumulator observation record
/// @param available The total amount available as of this Observation
/// @param disbursed The total amount disbursed in the past
struct Observation {
  uint96 available;
  uint160 disbursed;
}

/// @notice The metadata for using the ring buffer.
struct RingBufferInfo {
  uint16 nextIndex;
  uint16 cardinality;
}

/// @title Draw Accumulator Lib
/// @author G9 Software Inc.
/// @notice This contract distributes tokens over time according to an exponential weighted average.
/// Time is divided into discrete "draws", of which each is allocated tokens.
library DrawAccumulatorLib {

  /// @notice An accumulator for a draw.
  /// @param ringBufferInfo The metadata for the drawRingBuffer
  /// @param drawRingBuffer The ring buffer of draw ids
  /// @param observations The observations for each draw id
  struct Accumulator {
    RingBufferInfo ringBufferInfo; // 32 bits
    uint24[366] drawRingBuffer; // 8784 bits
    // 8784 + 32 = 8816 bits in total
    // 256 * 35 = 8960
    // 8960 - 8816 = 144 bits left over
    mapping(uint256 drawId => Observation observation) observations;
  }

  /// @notice Adds balance for the given draw id to the accumulator.
  /// @param accumulator The accumulator to add to
  /// @param _amount The amount of balance to add
  /// @param _drawId The draw id to which to add balance to. This must be greater than or equal to the previous
  /// addition's draw id.
  /// @return True if a new observation was created, false otherwise.
  function add(
    Accumulator storage accumulator,
    uint256 _amount,
    uint24 _drawId
  ) internal returns (bool) {
    if (_drawId == 0) {
      revert AddToDrawZero();
    }
    RingBufferInfo memory ringBufferInfo = accumulator.ringBufferInfo;

    uint24 newestDrawId_ = accumulator.drawRingBuffer[
      RingBufferLib.newestIndex(ringBufferInfo.nextIndex, MAX_OBSERVATION_CARDINALITY)
    ];

    if (_drawId < newestDrawId_) {
      revert DrawAwarded(_drawId, newestDrawId_);
    }

    mapping(uint256 drawId => Observation observation) storage accumulatorObservations = accumulator
      .observations;
    Observation memory newestObservation_ = accumulatorObservations[newestDrawId_];
    if (_drawId != newestDrawId_) {
      uint16 cardinality = ringBufferInfo.cardinality;
      if (ringBufferInfo.cardinality < MAX_OBSERVATION_CARDINALITY) {
        cardinality += 1;
      } else {
        // Delete the old observation to save gas (older than 1 year)
        delete accumulatorObservations[accumulator.drawRingBuffer[ringBufferInfo.nextIndex]];
      }

      accumulator.drawRingBuffer[ringBufferInfo.nextIndex] = _drawId;
      accumulatorObservations[_drawId] = Observation({
        available: SafeCast.toUint96(_amount),
        disbursed: SafeCast.toUint160(
          newestObservation_.disbursed +
            newestObservation_.available
        )
      });

      accumulator.ringBufferInfo = RingBufferInfo({
        nextIndex: uint16(RingBufferLib.nextIndex(ringBufferInfo.nextIndex, MAX_OBSERVATION_CARDINALITY)),
        cardinality: cardinality
      });

      return true;
    } else {
      accumulatorObservations[newestDrawId_] = Observation({
        available: SafeCast.toUint96(newestObservation_.available + _amount),
        disbursed: newestObservation_.disbursed
      });

      return false;
    }
  }

  /// @notice Returns the newest draw id from the accumulator.
  /// @param accumulator The accumulator to get the newest draw id from
  /// @return The newest draw id
  function newestDrawId(Accumulator storage accumulator) internal view returns (uint256) {
    return
      accumulator.drawRingBuffer[
        RingBufferLib.newestIndex(accumulator.ringBufferInfo.nextIndex, MAX_OBSERVATION_CARDINALITY)
      ];
  }

  /// @notice Returns the newest draw id from the accumulator.
  /// @param accumulator The accumulator to get the newest draw id from
  /// @return The newest draw id
  function newestObservation(Accumulator storage accumulator) internal view returns (Observation memory) {
    return accumulator.observations[
      newestDrawId(accumulator)
    ];
  }

  /// @notice Gets the balance that was disbursed between the given start and end draw ids, inclusive.
  /// @param _accumulator The accumulator to get the disbursed balance from
  /// @param _startDrawId The start draw id, inclusive
  /// @param _endDrawId The end draw id, inclusive
  /// @return The disbursed balance between the given start and end draw ids, inclusive
  function getDisbursedBetween(
    Accumulator storage _accumulator,
    uint24 _startDrawId,
    uint24 _endDrawId
  ) internal view returns (uint256) {
    if (_startDrawId > _endDrawId) {
      revert InvalidDrawRange(_startDrawId, _endDrawId);
    }

    RingBufferInfo memory ringBufferInfo = _accumulator.ringBufferInfo;

    if (ringBufferInfo.cardinality == 0) {
      return 0;
    }

    uint16 oldestIndex = uint16(
      RingBufferLib.oldestIndex(
        ringBufferInfo.nextIndex,
        ringBufferInfo.cardinality,
        MAX_OBSERVATION_CARDINALITY
      )
    );
    uint16 newestIndex = uint16(
      RingBufferLib.newestIndex(ringBufferInfo.nextIndex, ringBufferInfo.cardinality)
    );

    uint24 oldestDrawId = _accumulator.drawRingBuffer[oldestIndex];
    uint24 _newestDrawId = _accumulator.drawRingBuffer[newestIndex];

    if (_endDrawId < oldestDrawId || _startDrawId > _newestDrawId) {
      // if out of range, return 0
      return 0;
    }

    Observation memory atOrAfterStart;
    if (_startDrawId <= oldestDrawId || ringBufferInfo.cardinality == 1) {
      atOrAfterStart = _accumulator.observations[oldestDrawId];
    } else {
      // check if the start draw has an observation, otherwise search for the earliest observation after
      atOrAfterStart = _accumulator.observations[_startDrawId];
      if (atOrAfterStart.available == 0 && atOrAfterStart.disbursed == 0) {
        (, , , uint24 afterOrAtDrawId) = binarySearch(
          _accumulator.drawRingBuffer,
          oldestIndex,
          newestIndex,
          ringBufferInfo.cardinality,
          _startDrawId
        );
        atOrAfterStart = _accumulator.observations[afterOrAtDrawId];
      }
    }

    Observation memory atOrBeforeEnd;
    if (_endDrawId >= _newestDrawId || ringBufferInfo.cardinality == 1) {
      atOrBeforeEnd = _accumulator.observations[_newestDrawId];
    } else {
      // check if the end draw has an observation, otherwise search for the latest observation before
      atOrBeforeEnd = _accumulator.observations[_endDrawId];
      if (atOrBeforeEnd.available == 0 && atOrBeforeEnd.disbursed == 0) {
        (, uint24 beforeOrAtDrawId, , ) = binarySearch(
          _accumulator.drawRingBuffer,
          oldestIndex,
          newestIndex,
          ringBufferInfo.cardinality,
          _endDrawId
        );
        atOrBeforeEnd = _accumulator.observations[beforeOrAtDrawId];
      }
    }

    return atOrBeforeEnd.available + atOrBeforeEnd.disbursed - atOrAfterStart.disbursed;
  }

  /// @notice Binary searches an array of draw ids for the given target draw id.
  /// @dev The _targetDrawId MUST exist between the range of draws at _oldestIndex and _newestIndex (inclusive)
  /// @param _drawRingBuffer The array of draw ids to search
  /// @param _oldestIndex The oldest index in the ring buffer
  /// @param _newestIndex The newest index in the ring buffer
  /// @param _cardinality The number of items in the ring buffer
  /// @param _targetDrawId The target draw id to search for
  /// @return beforeOrAtIndex The index of the observation occurring at or before the target draw id
  /// @return beforeOrAtDrawId The draw id of the observation occurring at or before the target draw id
  /// @return afterOrAtIndex The index of the observation occurring at or after the target draw id
  /// @return afterOrAtDrawId The draw id of the observation occurring at or after the target draw id
  function binarySearch(
    uint24[366] storage _drawRingBuffer,
    uint16 _oldestIndex,
    uint16 _newestIndex,
    uint16 _cardinality,
    uint24 _targetDrawId
  )
    internal
    view
    returns (
      uint16 beforeOrAtIndex,
      uint24 beforeOrAtDrawId,
      uint16 afterOrAtIndex,
      uint24 afterOrAtDrawId
    )
  {
    uint16 leftSide = _oldestIndex;
    uint16 rightSide = _newestIndex < leftSide ? leftSide + _cardinality - 1 : _newestIndex;
    uint16 currentIndex;

    while (true) {
      // We start our search in the middle of the `leftSide` and `rightSide`.
      // After each iteration, we narrow down the search to the left or the right side while still starting our search in the middle.
      currentIndex = (leftSide + rightSide) / 2;

      beforeOrAtIndex = uint16(RingBufferLib.wrap(currentIndex, _cardinality));
      beforeOrAtDrawId = _drawRingBuffer[beforeOrAtIndex];

      afterOrAtIndex = uint16(RingBufferLib.nextIndex(currentIndex, _cardinality));
      afterOrAtDrawId = _drawRingBuffer[afterOrAtIndex];

      bool targetAtOrAfter = beforeOrAtDrawId <= _targetDrawId;

      // Check if we've found the corresponding Observation.
      if (targetAtOrAfter && _targetDrawId <= afterOrAtDrawId) {
        break;
      }

      // If `beforeOrAtTimestamp` is greater than `_target`, then we keep searching lower. To the left of the current index.
      if (!targetAtOrAfter) {
        rightSide = currentIndex - 1;
      } else {
        // Otherwise, we keep searching higher. To the left of the current index.
        leftSide = currentIndex + 1;
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { SafeCast } from "openzeppelin/utils/math/SafeCast.sol";
import { SD59x18, sd } from "prb-math/SD59x18.sol";
import { UD60x18, convert } from "prb-math/UD60x18.sol";

import { TierCalculationLib } from "../libraries/TierCalculationLib.sol";

/// @notice Struct that tracks tier liquidity information.
/// @param drawId The draw ID that the tier was last updated for
/// @param prizeSize The size of the prize for the tier at the drawId
/// @param prizeTokenPerShare The total prize tokens per share that have already been consumed for this tier.
struct Tier {
  uint24 drawId;
  uint104 prizeSize;
  uint128 prizeTokenPerShare;
}

/// @notice Thrown when the number of tiers is less than the minimum number of tiers.
/// @param numTiers The invalid number of tiers
error NumberOfTiersLessThanMinimum(uint8 numTiers);

/// @notice Thrown when the number of tiers is greater than the max tiers
/// @param numTiers The invalid number of tiers
error NumberOfTiersGreaterThanMaximum(uint8 numTiers);

/// @notice Thrown when the tier liquidity utilization rate is greater than 1.
error TierLiquidityUtilizationRateGreaterThanOne();

/// @notice Thrown when the tier liquidity utilization rate is 0.
error TierLiquidityUtilizationRateCannotBeZero();

/// @notice Thrown when there is insufficient liquidity to consume.
/// @param requestedLiquidity The requested amount of liquidity
error InsufficientLiquidity(uint104 requestedLiquidity);

uint8 constant MINIMUM_NUMBER_OF_TIERS = 4;
uint8 constant MAXIMUM_NUMBER_OF_TIERS = 11;
uint8 constant NUMBER_OF_CANARY_TIERS = 2;

/// @title Tiered Liquidity Distributor
/// @author PoolTogether Inc.
/// @notice A contract that distributes liquidity according to PoolTogether V5 distribution rules.
contract TieredLiquidityDistributor {
  /* ============ Events ============ */

  /// @notice Emitted when the reserve is consumed due to insufficient prize liquidity.
  /// @param amount The amount to decrease by
  event ReserveConsumed(uint256 amount);

  /* ============ Constants ============ */

  /// @notice The odds for each tier and number of tiers pair. For n tiers, the last three tiers are always daily.
  SD59x18 internal immutable TIER_ODDS_0;
  SD59x18 internal immutable TIER_ODDS_EVERY_DRAW;
  SD59x18 internal immutable TIER_ODDS_1_5;
  SD59x18 internal immutable TIER_ODDS_1_6;
  SD59x18 internal immutable TIER_ODDS_2_6;
  SD59x18 internal immutable TIER_ODDS_1_7;
  SD59x18 internal immutable TIER_ODDS_2_7;
  SD59x18 internal immutable TIER_ODDS_3_7;
  SD59x18 internal immutable TIER_ODDS_1_8;
  SD59x18 internal immutable TIER_ODDS_2_8;
  SD59x18 internal immutable TIER_ODDS_3_8;
  SD59x18 internal immutable TIER_ODDS_4_8;
  SD59x18 internal immutable TIER_ODDS_1_9;
  SD59x18 internal immutable TIER_ODDS_2_9;
  SD59x18 internal immutable TIER_ODDS_3_9;
  SD59x18 internal immutable TIER_ODDS_4_9;
  SD59x18 internal immutable TIER_ODDS_5_9;
  SD59x18 internal immutable TIER_ODDS_1_10;
  SD59x18 internal immutable TIER_ODDS_2_10;
  SD59x18 internal immutable TIER_ODDS_3_10;
  SD59x18 internal immutable TIER_ODDS_4_10;
  SD59x18 internal immutable TIER_ODDS_5_10;
  SD59x18 internal immutable TIER_ODDS_6_10;
  SD59x18 internal immutable TIER_ODDS_1_11;
  SD59x18 internal immutable TIER_ODDS_2_11;
  SD59x18 internal immutable TIER_ODDS_3_11;
  SD59x18 internal immutable TIER_ODDS_4_11;
  SD59x18 internal immutable TIER_ODDS_5_11;
  SD59x18 internal immutable TIER_ODDS_6_11;
  SD59x18 internal immutable TIER_ODDS_7_11;

  /// @notice The estimated number of prizes given X tiers.
  uint32 internal immutable ESTIMATED_PRIZES_PER_DRAW_FOR_4_TIERS;
  uint32 internal immutable ESTIMATED_PRIZES_PER_DRAW_FOR_5_TIERS;
  uint32 internal immutable ESTIMATED_PRIZES_PER_DRAW_FOR_6_TIERS;
  uint32 internal immutable ESTIMATED_PRIZES_PER_DRAW_FOR_7_TIERS;
  uint32 internal immutable ESTIMATED_PRIZES_PER_DRAW_FOR_8_TIERS;
  uint32 internal immutable ESTIMATED_PRIZES_PER_DRAW_FOR_9_TIERS;
  uint32 internal immutable ESTIMATED_PRIZES_PER_DRAW_FOR_10_TIERS;
  uint32 internal immutable ESTIMATED_PRIZES_PER_DRAW_FOR_11_TIERS;

  /// @notice The Tier liquidity data.
  mapping(uint8 tierId => Tier tierData) internal _tiers;

  /// @notice The frequency of the grand prize
  uint24 public immutable grandPrizePeriodDraws;

  /// @notice The number of shares to allocate to each prize tier.
  uint8 public immutable tierShares;

  /// @notice The number of shares to allocate to each canary tier.
  uint8 public immutable canaryShares;

  /// @notice The number of shares to allocate to the reserve.
  uint8 public immutable reserveShares;

  /// @notice The percentage of tier liquidity to target for utilization.  
  UD60x18 public immutable tierLiquidityUtilizationRate;

  /// @notice The number of prize tokens that have accrued per share for all time.
  /// @dev This is an ever-increasing exchange rate that is used to calculate the prize liquidity for each tier.
  /// @dev Each tier holds a separate tierPrizeTokenPerShare; the delta between the tierPrizeTokenPerShare and
  /// the prizeTokenPerShare * tierShares is the available liquidity they have.
  uint128 public prizeTokenPerShare;

  /// @notice The number of tiers for the last awarded draw. The last tier is the canary tier.
  uint8 public numberOfTiers;

  /// @notice The draw id of the last awarded draw.
  uint24 internal _lastAwardedDrawId;

  /// @notice The timestamp at which the last awarded draw was awarded.
  uint48 public lastAwardedDrawAwardedAt;

  /// @notice The amount of available reserve.
  uint96 internal _reserve;

  /// @notice Constructs a new Prize Pool.
  /// @param _tierLiquidityUtilizationRate The target percentage of tier liquidity to utilize each draw
  /// @param _numberOfTiers The number of tiers to start with. Must be greater than or equal to the minimum number of tiers.
  /// @param _tierShares The number of shares to allocate to each tier
  /// @param _canaryShares The number of shares to allocate to each canary tier
  /// @param _reserveShares The number of shares to allocate to the reserve.
  /// @param _grandPrizePeriodDraws The number of draws between grand prizes
  constructor(
    uint256 _tierLiquidityUtilizationRate,
    uint8 _numberOfTiers,
    uint8 _tierShares,
    uint8 _canaryShares,
    uint8 _reserveShares,
    uint24 _grandPrizePeriodDraws
  ) {
    if (_numberOfTiers < MINIMUM_NUMBER_OF_TIERS) {
      revert NumberOfTiersLessThanMinimum(_numberOfTiers);
    }
    if (_numberOfTiers > MAXIMUM_NUMBER_OF_TIERS) {
      revert NumberOfTiersGreaterThanMaximum(_numberOfTiers);
    }
    if (_tierLiquidityUtilizationRate > 1e18) {
      revert TierLiquidityUtilizationRateGreaterThanOne();
    }
    if (_tierLiquidityUtilizationRate == 0) {
      revert TierLiquidityUtilizationRateCannotBeZero();
    }

    tierLiquidityUtilizationRate = UD60x18.wrap(_tierLiquidityUtilizationRate);

    numberOfTiers = _numberOfTiers;
    tierShares = _tierShares;
    canaryShares = _canaryShares;
    reserveShares = _reserveShares;
    grandPrizePeriodDraws = _grandPrizePeriodDraws;

    TIER_ODDS_0 = sd(1).div(sd(int24(_grandPrizePeriodDraws)));
    TIER_ODDS_EVERY_DRAW = SD59x18.wrap(1000000000000000000);
    TIER_ODDS_1_5 = TierCalculationLib.getTierOdds(1, 3, _grandPrizePeriodDraws);
    TIER_ODDS_1_6 = TierCalculationLib.getTierOdds(1, 4, _grandPrizePeriodDraws);
    TIER_ODDS_2_6 = TierCalculationLib.getTierOdds(2, 4, _grandPrizePeriodDraws);
    TIER_ODDS_1_7 = TierCalculationLib.getTierOdds(1, 5, _grandPrizePeriodDraws);
    TIER_ODDS_2_7 = TierCalculationLib.getTierOdds(2, 5, _grandPrizePeriodDraws);
    TIER_ODDS_3_7 = TierCalculationLib.getTierOdds(3, 5, _grandPrizePeriodDraws);
    TIER_ODDS_1_8 = TierCalculationLib.getTierOdds(1, 6, _grandPrizePeriodDraws);
    TIER_ODDS_2_8 = TierCalculationLib.getTierOdds(2, 6, _grandPrizePeriodDraws);
    TIER_ODDS_3_8 = TierCalculationLib.getTierOdds(3, 6, _grandPrizePeriodDraws);
    TIER_ODDS_4_8 = TierCalculationLib.getTierOdds(4, 6, _grandPrizePeriodDraws);
    TIER_ODDS_1_9 = TierCalculationLib.getTierOdds(1, 7, _grandPrizePeriodDraws);
    TIER_ODDS_2_9 = TierCalculationLib.getTierOdds(2, 7, _grandPrizePeriodDraws);
    TIER_ODDS_3_9 = TierCalculationLib.getTierOdds(3, 7, _grandPrizePeriodDraws);
    TIER_ODDS_4_9 = TierCalculationLib.getTierOdds(4, 7, _grandPrizePeriodDraws);
    TIER_ODDS_5_9 = TierCalculationLib.getTierOdds(5, 7, _grandPrizePeriodDraws);
    TIER_ODDS_1_10 = TierCalculationLib.getTierOdds(1, 8, _grandPrizePeriodDraws);
    TIER_ODDS_2_10 = TierCalculationLib.getTierOdds(2, 8, _grandPrizePeriodDraws);
    TIER_ODDS_3_10 = TierCalculationLib.getTierOdds(3, 8, _grandPrizePeriodDraws);
    TIER_ODDS_4_10 = TierCalculationLib.getTierOdds(4, 8, _grandPrizePeriodDraws);
    TIER_ODDS_5_10 = TierCalculationLib.getTierOdds(5, 8, _grandPrizePeriodDraws);
    TIER_ODDS_6_10 = TierCalculationLib.getTierOdds(6, 8, _grandPrizePeriodDraws);
    TIER_ODDS_1_11 = TierCalculationLib.getTierOdds(1, 9, _grandPrizePeriodDraws);
    TIER_ODDS_2_11 = TierCalculationLib.getTierOdds(2, 9, _grandPrizePeriodDraws);
    TIER_ODDS_3_11 = TierCalculationLib.getTierOdds(3, 9, _grandPrizePeriodDraws);
    TIER_ODDS_4_11 = TierCalculationLib.getTierOdds(4, 9, _grandPrizePeriodDraws);
    TIER_ODDS_5_11 = TierCalculationLib.getTierOdds(5, 9, _grandPrizePeriodDraws);
    TIER_ODDS_6_11 = TierCalculationLib.getTierOdds(6, 9, _grandPrizePeriodDraws);
    TIER_ODDS_7_11 = TierCalculationLib.getTierOdds(7, 9, _grandPrizePeriodDraws);

    ESTIMATED_PRIZES_PER_DRAW_FOR_4_TIERS = _sumTierPrizeCounts(4);
    ESTIMATED_PRIZES_PER_DRAW_FOR_5_TIERS = _sumTierPrizeCounts(5);
    ESTIMATED_PRIZES_PER_DRAW_FOR_6_TIERS = _sumTierPrizeCounts(6);
    ESTIMATED_PRIZES_PER_DRAW_FOR_7_TIERS = _sumTierPrizeCounts(7);
    ESTIMATED_PRIZES_PER_DRAW_FOR_8_TIERS = _sumTierPrizeCounts(8);
    ESTIMATED_PRIZES_PER_DRAW_FOR_9_TIERS = _sumTierPrizeCounts(9);
    ESTIMATED_PRIZES_PER_DRAW_FOR_10_TIERS = _sumTierPrizeCounts(10);
    ESTIMATED_PRIZES_PER_DRAW_FOR_11_TIERS = _sumTierPrizeCounts(11);
  }

  /// @notice Adjusts the number of tiers and distributes new liquidity.
  /// @param _awardingDraw The ID of the draw that is being awarded
  /// @param _nextNumberOfTiers The new number of tiers. Must be greater than minimum
  /// @param _prizeTokenLiquidity The amount of fresh liquidity to distribute across the tiers and reserve
  function _awardDraw(
    uint24 _awardingDraw,
    uint8 _nextNumberOfTiers,
    uint256 _prizeTokenLiquidity
  ) internal {
    if (_nextNumberOfTiers < MINIMUM_NUMBER_OF_TIERS) {
      revert NumberOfTiersLessThanMinimum(_nextNumberOfTiers);
    }

    uint8 numTiers = numberOfTiers;
    uint128 _prizeTokenPerShare = prizeTokenPerShare;
    (uint96 deltaReserve, uint128 newPrizeTokenPerShare) = _computeNewDistributions(
      numTiers,
      _nextNumberOfTiers,
      _prizeTokenPerShare,
      _prizeTokenLiquidity
    );

    uint8 start = _computeReclamationStart(numTiers, _nextNumberOfTiers);
    uint8 end = _nextNumberOfTiers;
    for (uint8 i = start; i < end; i++) {
      _tiers[i] = Tier({
        drawId: _awardingDraw,
        prizeTokenPerShare: _prizeTokenPerShare,
        prizeSize: _computePrizeSize(
          i,
          _nextNumberOfTiers,
          _prizeTokenPerShare,
          newPrizeTokenPerShare
        )
      });
    }

    prizeTokenPerShare = newPrizeTokenPerShare;
    numberOfTiers = _nextNumberOfTiers;
    _lastAwardedDrawId = _awardingDraw;
    lastAwardedDrawAwardedAt = uint48(block.timestamp);
    _reserve += deltaReserve;
  }

  /// @notice Computes the liquidity that will be distributed for the next awarded draw given the next number of tiers and prize liquidity.
  /// @param _numberOfTiers The current number of tiers
  /// @param _nextNumberOfTiers The next number of tiers to use to compute distribution
  /// @param _currentPrizeTokenPerShare The current prize token per share
  /// @param _prizeTokenLiquidity The amount of fresh liquidity to distribute across the tiers and reserve
  /// @return deltaReserve The amount of liquidity that will be added to the reserve
  /// @return newPrizeTokenPerShare The new prize token per share
  function _computeNewDistributions(
    uint8 _numberOfTiers,
    uint8 _nextNumberOfTiers,
    uint128 _currentPrizeTokenPerShare,
    uint256 _prizeTokenLiquidity
  ) internal view returns (uint96 deltaReserve, uint128 newPrizeTokenPerShare) {
    uint256 reclaimedLiquidity;
    {
      // need to redistribute to the canary tier and any new tiers (if expanding)
      uint8 start = _computeReclamationStart(_numberOfTiers, _nextNumberOfTiers);
      uint8 end = _numberOfTiers;
      for (uint8 i = start; i < end; i++) {
        reclaimedLiquidity = reclaimedLiquidity + (
          _getTierRemainingLiquidity(
            _tiers[i].prizeTokenPerShare,
            _currentPrizeTokenPerShare,
            _numShares(i, _numberOfTiers)
          )
        );
      }
    }

    uint256 totalNewLiquidity = _prizeTokenLiquidity + reclaimedLiquidity;
    uint256 nextTotalShares = computeTotalShares(_nextNumberOfTiers);
    uint256 deltaPrizeTokensPerShare = totalNewLiquidity / nextTotalShares;

    newPrizeTokenPerShare = SafeCast.toUint128(_currentPrizeTokenPerShare + deltaPrizeTokensPerShare);

    deltaReserve = SafeCast.toUint96(
      // reserve portion of new liquidity
      deltaPrizeTokensPerShare *
        reserveShares +
        // remainder left over from shares
        totalNewLiquidity -
        deltaPrizeTokensPerShare *
        nextTotalShares
    );
  }

  /// @notice Returns the prize size for the given tier.
  /// @param _tier The tier to retrieve
  /// @return The prize size for the tier
  function getTierPrizeSize(uint8 _tier) external view returns (uint104) {
    uint8 _numTiers = numberOfTiers;

    return
      !TierCalculationLib.isValidTier(_tier, _numTiers) ? 0 : _getTier(_tier, _numTiers).prizeSize;
  }

  /// @notice Returns the estimated number of prizes for the given tier.
  /// @param _tier The tier to retrieve
  /// @return The estimated number of prizes
  function getTierPrizeCount(uint8 _tier) external pure returns (uint32) {
    return uint32(TierCalculationLib.prizeCount(_tier));
  }

  /// @notice Retrieves an up-to-date Tier struct for the given tier.
  /// @param _tier The tier to retrieve
  /// @param _numberOfTiers The number of tiers, should match the current. Passed explicitly as an optimization
  /// @return An up-to-date Tier struct; if the prize is outdated then it is recomputed based on available liquidity and the draw ID is updated.
  function _getTier(uint8 _tier, uint8 _numberOfTiers) internal view returns (Tier memory) {
    Tier memory tier = _tiers[_tier];
    uint24 lastAwardedDrawId_ = _lastAwardedDrawId;
    if (tier.drawId != lastAwardedDrawId_) {
      tier.drawId = lastAwardedDrawId_;
      tier.prizeSize = _computePrizeSize(
        _tier,
        _numberOfTiers,
        tier.prizeTokenPerShare,
        prizeTokenPerShare
      );
    }
    return tier;
  }

  /// @notice Computes the total shares in the system.
  /// @return The total shares
  function getTotalShares() external view returns (uint256) {
    return computeTotalShares(numberOfTiers);
  }

  /// @notice Computes the total shares in the system given the number of tiers.
  /// @param _numberOfTiers The number of tiers to calculate the total shares for
  /// @return The total shares
  function computeTotalShares(uint8 _numberOfTiers) public view returns (uint256) {
    return uint256(_numberOfTiers-2) * uint256(tierShares) + uint256(reserveShares) + uint256(canaryShares) * 2;
  }

  /// @notice Determines at which tier we need to start reclaiming liquidity.
  /// @param _numberOfTiers The current number of tiers
  /// @param _nextNumberOfTiers The next number of tiers
  /// @return The tier to start reclaiming liquidity from
  function _computeReclamationStart(uint8 _numberOfTiers, uint8 _nextNumberOfTiers) internal pure returns (uint8) {
    // We must always reset the canary tiers, both old and new. 
    // If the next num is less than the num tiers, then the first canary tiers to reset are the last of the next tiers.
    // Otherwise, the canary tiers to reset are the last of the current tiers.
    return (_nextNumberOfTiers > _numberOfTiers ? _numberOfTiers : _nextNumberOfTiers) - NUMBER_OF_CANARY_TIERS;
  }

  /// @notice Consumes liquidity from the given tier.
  /// @param _tierStruct The tier to consume liquidity from
  /// @param _tier The tier number
  /// @param _liquidity The amount of liquidity to consume
  function _consumeLiquidity(Tier memory _tierStruct, uint8 _tier, uint104 _liquidity) internal {
    uint8 _tierShares = _numShares(_tier, numberOfTiers);
    uint104 remainingLiquidity = SafeCast.toUint104(
      _getTierRemainingLiquidity(
        _tierStruct.prizeTokenPerShare,
        prizeTokenPerShare,
        _tierShares
      )
    );

    if (_liquidity > remainingLiquidity) {
      uint96 excess = SafeCast.toUint96(_liquidity - remainingLiquidity);

      if (excess > _reserve) {
        revert InsufficientLiquidity(_liquidity);
      }

      unchecked {
        _reserve -= excess;
      }

      emit ReserveConsumed(excess);
      _tierStruct.prizeTokenPerShare = prizeTokenPerShare;
    } else {
      uint8 _remainder = uint8(_liquidity % _tierShares);
      uint8 _roundUpConsumption = _remainder == 0 ? 0 : _tierShares - _remainder;
      if (_roundUpConsumption > 0) {
        // We must round up our tier prize token per share value to ensure we don't over-award the tier's
        // liquidity, but any extra rounded up consumption can be contributed to the reserve so every wei
        // is accounted for.
        _reserve += _roundUpConsumption;
      }

      // We know that the rounded up `liquidity` won't exceed the `remainingLiquidity` since the `remainingLiquidity`
      // is an integer multiple of `_tierShares` and we check above that `_liquidity <= remainingLiquidity`.
      _tierStruct.prizeTokenPerShare += SafeCast.toUint104(uint256(_liquidity) + _roundUpConsumption) / _tierShares;
    }

    _tiers[_tier] = _tierStruct;
  }

  /// @notice Computes the prize size of the given tier.
  /// @param _tier The tier to compute the prize size of
  /// @param _numberOfTiers The current number of tiers
  /// @param _tierPrizeTokenPerShare The prizeTokenPerShare of the Tier struct
  /// @param _prizeTokenPerShare The global prizeTokenPerShare
  /// @return The prize size
  function _computePrizeSize(
    uint8 _tier,
    uint8 _numberOfTiers,
    uint128 _tierPrizeTokenPerShare,
    uint128 _prizeTokenPerShare
  ) internal view returns (uint104) {
    uint256 prizeCount = TierCalculationLib.prizeCount(_tier);
    uint256 remainingTierLiquidity = _getTierRemainingLiquidity(
      _tierPrizeTokenPerShare,
      _prizeTokenPerShare,
      _numShares(_tier, _numberOfTiers)
    );

    uint256 prizeSize = convert(
      convert(remainingTierLiquidity).mul(tierLiquidityUtilizationRate).div(convert(prizeCount))
    );

    return prizeSize > type(uint104).max ? type(uint104).max : uint104(prizeSize);
  }

  /// @notice Returns whether the given tier is a canary tier
  /// @param _tier The tier to check
  /// @return True if the passed tier is a canary tier, false otherwise
  function isCanaryTier(uint8 _tier) public view returns (bool) {
    return _tier >= numberOfTiers - NUMBER_OF_CANARY_TIERS;
  }

  /// @notice Returns the number of shares for the given tier and number of tiers.
  /// @param _tier The tier to compute the number of shares for
  /// @param _numberOfTiers The number of tiers
  /// @return The number of shares
  function _numShares(uint8 _tier, uint8 _numberOfTiers) internal view returns (uint8) {
    uint8 result = _tier > _numberOfTiers - 3 ? canaryShares : tierShares;
    return result;
  }

  /// @notice Computes the remaining liquidity available to a tier.
  /// @param _tier The tier to compute the liquidity for
  /// @return The remaining liquidity
  function getTierRemainingLiquidity(uint8 _tier) public view returns (uint256) {
    uint8 _numTiers = numberOfTiers;
    if (TierCalculationLib.isValidTier(_tier, _numTiers)) {
      return _getTierRemainingLiquidity(
        _getTier(_tier, _numTiers).prizeTokenPerShare,
        prizeTokenPerShare,
        _numShares(_tier, _numTiers)
      );
    } else {
      return 0;
    }
  }

  /// @notice Computes the remaining tier liquidity.
  /// @param _tierPrizeTokenPerShare The prizeTokenPerShare of the Tier struct
  /// @param _prizeTokenPerShare The global prizeTokenPerShare
  /// @param _tierShares The number of shares for the tier
  /// @return The remaining available liquidity
  function _getTierRemainingLiquidity(
    uint128 _tierPrizeTokenPerShare,
    uint128 _prizeTokenPerShare,
    uint8 _tierShares
  ) internal pure returns (uint256) {
    uint256 result =
      _tierPrizeTokenPerShare >= _prizeTokenPerShare
        ? 0
        : uint256(_prizeTokenPerShare - _tierPrizeTokenPerShare) * _tierShares;
    return result;
  }

  /// @notice Estimates the number of prizes for the current number of tiers, including the first canary tier
  /// @return The estimated number of prizes including the canary tier
  function estimatedPrizeCount() external view returns (uint32) {
    return estimatedPrizeCount(numberOfTiers);
  }

  /// @notice Estimates the number of prizes for the current number of tiers, including both canary tiers
  /// @return The estimated number of prizes including both canary tiers
  function estimatedPrizeCountWithBothCanaries() external view returns (uint32) {
    return estimatedPrizeCountWithBothCanaries(numberOfTiers);
  }

  /// @notice Returns the balance of the reserve.
  /// @return The amount of tokens that have been reserved.
  function reserve() external view returns (uint96) {
    return _reserve;
  }

  /// @notice Estimates the prize count for the given number of tiers, including the first canary tier. It expects no prizes are claimed for the last canary tier
  /// @param numTiers The number of prize tiers
  /// @return The estimated total number of prizes
  function estimatedPrizeCount(
    uint8 numTiers
  ) public view returns (uint32) {
    if (numTiers == 4) {
      return ESTIMATED_PRIZES_PER_DRAW_FOR_4_TIERS;
    } else if (numTiers == 5) {
      return ESTIMATED_PRIZES_PER_DRAW_FOR_5_TIERS;
    } else if (numTiers == 6) {
      return ESTIMATED_PRIZES_PER_DRAW_FOR_6_TIERS;
    } else if (numTiers == 7) {
      return ESTIMATED_PRIZES_PER_DRAW_FOR_7_TIERS;
    } else if (numTiers == 8) {
      return ESTIMATED_PRIZES_PER_DRAW_FOR_8_TIERS;
    } else if (numTiers == 9) {
      return ESTIMATED_PRIZES_PER_DRAW_FOR_9_TIERS;
    } else if (numTiers == 10) {
      return ESTIMATED_PRIZES_PER_DRAW_FOR_10_TIERS;
    } else if (numTiers == 11) {
      return ESTIMATED_PRIZES_PER_DRAW_FOR_11_TIERS;
    }
    return 0;
  }

  /// @notice Estimates the prize count for the given tier, including BOTH canary tiers
  /// @param numTiers The number of tiers
  /// @return The estimated prize count across all tiers, including both canary tiers.
  function estimatedPrizeCountWithBothCanaries(
    uint8 numTiers
  ) public view returns (uint32) {
    if (numTiers >= MINIMUM_NUMBER_OF_TIERS && numTiers <= MAXIMUM_NUMBER_OF_TIERS) {
      return estimatedPrizeCount(numTiers) + uint32(TierCalculationLib.prizeCount(numTiers - 1));
    } else {
      return 0;
    }
  }

  /// @notice Estimates the number of tiers for the given prize count.
  /// @param _prizeCount The number of prizes that were claimed
  /// @return The estimated tier
  function _estimateNumberOfTiersUsingPrizeCountPerDraw(
    uint32 _prizeCount
  ) internal view returns (uint8) {
    // the prize count is slightly more than 4x for each higher tier. i.e. 16, 66, 270, 1108, etc
    // by doubling the measured count, we create a safe margin for error.
    uint32 _adjustedPrizeCount = _prizeCount * 2;
    if (_adjustedPrizeCount < ESTIMATED_PRIZES_PER_DRAW_FOR_5_TIERS) {
      return 4;
    } else if (_adjustedPrizeCount < ESTIMATED_PRIZES_PER_DRAW_FOR_6_TIERS) {
      return 5;
    } else if (_adjustedPrizeCount < ESTIMATED_PRIZES_PER_DRAW_FOR_7_TIERS) {
      return 6;
    } else if (_adjustedPrizeCount < ESTIMATED_PRIZES_PER_DRAW_FOR_8_TIERS) {
      return 7;
    } else if (_adjustedPrizeCount < ESTIMATED_PRIZES_PER_DRAW_FOR_9_TIERS) {
      return 8;
    } else if (_adjustedPrizeCount < ESTIMATED_PRIZES_PER_DRAW_FOR_10_TIERS) {
      return 9;
    } else if (_adjustedPrizeCount < ESTIMATED_PRIZES_PER_DRAW_FOR_11_TIERS) {
      return 10;
    } else {
      return 11;
    }
  }

  /// @notice Computes the expected number of prizes for a given number of tiers.
  /// @dev Includes the first canary tier prizes, but not the second since the first is expected to
  /// be claimed.
  /// @param _numTiers The number of tiers, including canaries
  /// @return The expected number of prizes, first canary included.
  function _sumTierPrizeCounts(uint8 _numTiers) internal view returns (uint32) {
    uint32 prizeCount;
    uint8 i = 0;
    do {
      prizeCount += TierCalculationLib.tierPrizeCountPerDraw(i, getTierOdds(i, _numTiers));
      i++;
    } while (i < _numTiers - 1);
    return prizeCount;
  }

  /// @notice Computes the odds for a tier given the number of tiers.
  /// @param _tier The tier to compute odds for
  /// @param _numTiers The number of prize tiers
  /// @return The odds of the tier
  function getTierOdds(uint8 _tier, uint8 _numTiers) public view returns (SD59x18) {
    if (_tier == 0) return TIER_ODDS_0;
    if (_numTiers == 3) {
      if (_tier <= 2) return TIER_ODDS_EVERY_DRAW;
    } else if (_numTiers == 4) {
      if (_tier <= 3) return TIER_ODDS_EVERY_DRAW;
    } else if (_numTiers == 5) {
      if (_tier == 1) return TIER_ODDS_1_5;
      else if (_tier <= 4) return TIER_ODDS_EVERY_DRAW;
    } else if (_numTiers == 6) {
      if (_tier == 1) return TIER_ODDS_1_6;
      else if (_tier == 2) return TIER_ODDS_2_6;
      else if (_tier <= 5) return TIER_ODDS_EVERY_DRAW;
    } else if (_numTiers == 7) {
      if (_tier == 1) return TIER_ODDS_1_7;
      else if (_tier == 2) return TIER_ODDS_2_7;
      else if (_tier == 3) return TIER_ODDS_3_7;
      else if (_tier <= 6) return TIER_ODDS_EVERY_DRAW;
    } else if (_numTiers == 8) {
      if (_tier == 1) return TIER_ODDS_1_8;
      else if (_tier == 2) return TIER_ODDS_2_8;
      else if (_tier == 3) return TIER_ODDS_3_8;
      else if (_tier == 4) return TIER_ODDS_4_8;
      else if (_tier <= 7) return TIER_ODDS_EVERY_DRAW;
    } else if (_numTiers == 9) {
      if (_tier == 1) return TIER_ODDS_1_9;
      else if (_tier == 2) return TIER_ODDS_2_9;
      else if (_tier == 3) return TIER_ODDS_3_9;
      else if (_tier == 4) return TIER_ODDS_4_9;
      else if (_tier == 5) return TIER_ODDS_5_9;
      else if (_tier <= 8) return TIER_ODDS_EVERY_DRAW;
    } else if (_numTiers == 10) {
      if (_tier == 1) return TIER_ODDS_1_10;
      else if (_tier == 2) return TIER_ODDS_2_10;
      else if (_tier == 3) return TIER_ODDS_3_10;
      else if (_tier == 4) return TIER_ODDS_4_10;
      else if (_tier == 5) return TIER_ODDS_5_10;
      else if (_tier == 6) return TIER_ODDS_6_10;
      else if (_tier <= 9) return TIER_ODDS_EVERY_DRAW;
    } else if (_numTiers == 11) {
      if (_tier == 1) return TIER_ODDS_1_11;
      else if (_tier == 2) return TIER_ODDS_2_11;
      else if (_tier == 3) return TIER_ODDS_3_11;
      else if (_tier == 4) return TIER_ODDS_4_11;
      else if (_tier == 5) return TIER_ODDS_5_11;
      else if (_tier == 6) return TIER_ODDS_6_11;
      else if (_tier == 7) return TIER_ODDS_7_11;
      else if (_tier <= 10) return TIER_ODDS_EVERY_DRAW;
    }
    return sd(0);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { UniformRandomNumber } from "uniform-random-number/UniformRandomNumber.sol";
import { SD59x18, sd, unwrap, convert } from "prb-math/SD59x18.sol";

/// @title Tier Calculation Library
/// @author PoolTogether Inc. Team
/// @notice Provides helper functions to assist in calculating tier prize counts, frequency, and odds.
library TierCalculationLib {
  /// @notice Calculates the odds of a tier occurring.
  /// @param _tier The tier to calculate odds for
  /// @param _numberOfTiers The total number of tiers
  /// @param _grandPrizePeriod The number of draws between grand prizes
  /// @return The odds that a tier should occur for a single draw.
  function getTierOdds(
    uint8 _tier,
    uint8 _numberOfTiers,
    uint24 _grandPrizePeriod
  ) internal pure returns (SD59x18) {
    int8 oneMinusNumTiers = 1 - int8(_numberOfTiers);
    return
      sd(1).div(sd(int24(_grandPrizePeriod))).pow(
        sd(int8(_tier) + oneMinusNumTiers).div(sd(oneMinusNumTiers)).sqrt()
      );
  }

  /// @notice Estimates the number of draws between a tier occurring.
  /// @param _tierOdds The odds for the tier to calculate the frequency of
  /// @return The estimated number of draws between the tier occurring
  function estimatePrizeFrequencyInDraws(SD59x18 _tierOdds) internal pure returns (uint256) {
    return uint256(convert(sd(1e18).div(_tierOdds).ceil()));
  }

  /// @notice Computes the number of prizes for a given tier.
  /// @param _tier The tier to compute for
  /// @return The number of prizes
  function prizeCount(uint8 _tier) internal pure returns (uint256) {
    return 4 ** _tier;
  }

  /// @notice Determines if a user won a prize tier.
  /// @param _userSpecificRandomNumber The random number to use as entropy
  /// @param _userTwab The user's time weighted average balance
  /// @param _vaultTwabTotalSupply The vault's time weighted average total supply
  /// @param _vaultContributionFraction The portion of the prize that was contributed by the vault
  /// @param _tierOdds The odds of the tier occurring
  /// @return True if the user won the tier, false otherwise
  function isWinner(
    uint256 _userSpecificRandomNumber,
    uint256 _userTwab,
    uint256 _vaultTwabTotalSupply,
    SD59x18 _vaultContributionFraction,
    SD59x18 _tierOdds
  ) internal pure returns (bool) {
    if (_vaultTwabTotalSupply == 0) {
      return false;
    }

    /// The user-held portion of the total supply is the "winning zone".
    /// If the above pseudo-random number falls within the winning zone, the user has won this tier.
    /// However, we scale the size of the zone based on:
    ///   - Odds of the tier occurring
    ///   - Number of prizes
    ///   - Portion of prize that was contributed by the vault

    return
      UniformRandomNumber.uniform(_userSpecificRandomNumber, _vaultTwabTotalSupply) <
      calculateWinningZone(_userTwab, _vaultContributionFraction, _tierOdds);
  }

  /// @notice Calculates a pseudo-random number that is unique to the user, tier, and winning random number.
  /// @param _drawId The draw id the user is checking
  /// @param _vault The vault the user deposited into
  /// @param _user The user
  /// @param _tier The tier
  /// @param _prizeIndex The particular prize index they are checking
  /// @param _winningRandomNumber The winning random number
  /// @return A pseudo-random number
  function calculatePseudoRandomNumber(
    uint24 _drawId,
    address _vault,
    address _user,
    uint8 _tier,
    uint32 _prizeIndex,
    uint256 _winningRandomNumber
  ) internal pure returns (uint256) {
    return
      uint256(
        keccak256(abi.encode(_drawId, _vault, _user, _tier, _prizeIndex, _winningRandomNumber))
      );
  }

  /// @notice Calculates the winning zone for a user. If their pseudo-random number falls within this zone, they win the tier.
  /// @param _userTwab The user's time weighted average balance
  /// @param _vaultContributionFraction The portion of the prize that was contributed by the vault
  /// @param _tierOdds The odds of the tier occurring
  /// @return The winning zone for the user.
  function calculateWinningZone(
    uint256 _userTwab,
    SD59x18 _vaultContributionFraction,
    SD59x18 _tierOdds
  ) internal pure returns (uint256) {
    return
      uint256(convert(convert(int256(_userTwab)).mul(_tierOdds).mul(_vaultContributionFraction)));
  }

  /// @notice Computes the estimated number of prizes per draw for a given tier and tier odds.
  /// @param _tier The tier
  /// @param _odds The odds of the tier occurring for the draw
  /// @return The estimated number of prizes per draw for the given tier and tier odds
  function tierPrizeCountPerDraw(uint8 _tier, SD59x18 _odds) internal pure returns (uint32) {
    return uint32(uint256(unwrap(sd(int256(prizeCount(_tier))).mul(_odds))));
  }

  /// @notice Checks whether a tier is a valid tier
  /// @param _tier The tier to check
  /// @param _numberOfTiers The number of tiers
  /// @return True if the tier is valid, false otherwise
  function isValidTier(uint8 _tier, uint8 _numberOfTiers) internal pure returns (bool) {
    return _tier < _numberOfTiers;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Abstract ownable contract that can be inherited by other contracts
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The `owner` is first set by passing the address of the `initialOwner` to the Ownable constructor.
 *
 * The owner account can be transferred through a two steps process:
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {claimOwnership} to accept the ownership transfer
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to the owner.
 */
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Emitted when `_pendingOwner` has been changed.
     * @param pendingOwner new `_pendingOwner` address.
     */
    event OwnershipOffered(address indexed pendingOwner);

    /**
     * @dev Emitted when `_owner` has been changed.
     * @param previousOwner previous `_owner` address.
     * @param newOwner new `_owner` address.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* ============ Deploy ============ */

    /**
     * @notice Initializes the contract setting `_initialOwner` as the initial owner.
     * @param _initialOwner Initial owner of the contract.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Gets current `_pendingOwner`.
     * @return Current `_pendingOwner` address.
     */
    function pendingOwner() external view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Renounce ownership of the contract.
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
    * @notice Allows current owner to set the `_pendingOwner` address.
    * @param _newOwner Address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable/pendingOwner-not-zero-address");

        _pendingOwner = _newOwner;

        emit OwnershipOffered(_newOwner);
    }

    /**
    * @notice Allows the `_pendingOwner` address to finalize the transfer.
    * @dev This function is only callable by the `_pendingOwner`.
    */
    function claimOwnership() external onlyPendingOwner {
        _setOwner(_pendingOwner);
        _pendingOwner = address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to set the `_owner` of the contract.
     * @param _newOwner New `_owner` address.
     */
    function _setOwner(address _newOwner) private {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable/caller-not-owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the `pendingOwner`.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable/caller-not-pendingOwner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IClaimable } from "pt-v5-claimable-interface/interfaces/IClaimable.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";

import { HookManager } from "./HookManager.sol";

/// @title  PoolTogether V5 Claimable Vault Extension
/// @author G9 Software Inc.
/// @notice Provides an interface for Claimer contracts to interact with a vault in PoolTogether
/// V5 while allowing each account to set and manage prize hooks that are called when they win.
abstract contract Claimable is HookManager, IClaimable {

    ////////////////////////////////////////////////////////////////////////////////
    // Public Constants and Variables
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice The gas to give to each of the before and after prize claim hooks.
    /// @dev This should be enough gas to mint an NFT if needed.
    uint24 public constant HOOK_GAS = 150_000;

    /// @notice Address of the PrizePool that computes prizes.
    PrizePool public immutable prizePool;

    /// @notice Address of the claimer.
    address public claimer;

    ////////////////////////////////////////////////////////////////////////////////
    // Errors
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when the Prize Pool is set to the zero address.
    error PrizePoolZeroAddress();

    /// @notice Thrown when the Claimer is set to the zero address.
    error ClaimerZeroAddress();

    /// @notice Thrown when a prize is claimed for the zero address.
    error ClaimRecipientZeroAddress();

    /// @notice Thrown when the caller is not the prize claimer.
    /// @param caller The caller address
    /// @param claimer The claimer address
    error CallerNotClaimer(address caller, address claimer);

    ////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Requires the caller to be the claimer.
    modifier onlyClaimer() {
        if (msg.sender != claimer) revert CallerNotClaimer(msg.sender, claimer);
        _;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Constructor
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Claimable constructor
    /// @param prizePool_ The prize pool to claim prizes from
    /// @param claimer_ The address allowed to claim prizes on behalf of winners
    constructor(PrizePool prizePool_, address claimer_) {
        if (address(prizePool_) == address(0)) revert PrizePoolZeroAddress();
        prizePool = prizePool_;
        _setClaimer(claimer_);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // IClaimable Implementation
    ////////////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IClaimable
    /// @dev Also calls the before and after claim hooks if set by the winner.
    function claimPrize(
        address _winner,
        uint8 _tier,
        uint32 _prizeIndex,
        uint96 _reward,
        address _rewardRecipient
    ) external onlyClaimer returns (uint256) {
        address _prizeRecipient;
        bytes memory _hookData;

        if (_hooks[_winner].useBeforeClaimPrize) {
            (_prizeRecipient, _hookData) = _hooks[_winner].implementation.beforeClaimPrize{ gas: HOOK_GAS }(
                _winner,
                _tier,
                _prizeIndex,
                _reward,
                _rewardRecipient
            );
        } else {
            _prizeRecipient = _winner;
        }

        if (_prizeRecipient == address(0)) revert ClaimRecipientZeroAddress();

        uint256 _prizeTotal = prizePool.claimPrize(
            _winner,
            _tier,
            _prizeIndex,
            _prizeRecipient,
            _reward,
            _rewardRecipient
        );

        if (_hooks[_winner].useAfterClaimPrize) {
            _hooks[_winner].implementation.afterClaimPrize{ gas: HOOK_GAS }(
                _winner,
                _tier,
                _prizeIndex,
                _prizeTotal - _reward,
                _prizeRecipient,
                _hookData
            );
        }

        return _prizeTotal;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Internal Helpers
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Set claimer address.
    /// @dev Will revert if `_claimer` is address zero.
    /// @param _claimer Address of the claimer
    function _setClaimer(address _claimer) internal {
        if (_claimer == address(0)) revert ClaimerZeroAddress();
        claimer = _claimer;
        emit ClaimerSet(_claimer);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "openzeppelin/token/ERC20/ERC20.sol";
import { ERC20Permit } from "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import { SafeCast } from "openzeppelin/utils/math/SafeCast.sol";

import { TwabController } from "pt-v5-twab-controller/TwabController.sol";

/// @title  PoolTogether V5 TWAB ERC20 Token
/// @author G9 Software Inc.
/// @notice This contract creates an ERC20 token with balances stored in a TwabController,
///         enabling time-weighted average balances for each depositor and token compatibility
///         with the PoolTogether V5 Prize Pool.
/// @dev    This contract is designed to be used as an accounting layer when building a vault
///         for PoolTogether V5.
/// @dev    The TwabController limits all balances including total token supply to uint96 for
///         gas savings. Any mints that increase a balance past this limit will fail.
contract TwabERC20 is ERC20, ERC20Permit {

    ////////////////////////////////////////////////////////////////////////////////
    // Public Variables
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Address of the TwabController used to keep track of balances.
    TwabController public immutable twabController;

    ////////////////////////////////////////////////////////////////////////////////
    // Errors
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown if the TwabController address is the zero address.
    error TwabControllerZeroAddress();

    ////////////////////////////////////////////////////////////////////////////////
    // Constructor
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice TwabERC20 Constructor
    /// @param name_ The name of the token
    /// @param symbol_ The token symbol
    /// @param twabController_ The TWAB controller that will be used to store token balances
    constructor(
        string memory name_,
        string memory symbol_,
        TwabController twabController_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        if (address(0) == address(twabController_)) revert TwabControllerZeroAddress();
        twabController = twabController_;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Public ERC20 Overrides
    ////////////////////////////////////////////////////////////////////////////////

    /// @inheritdoc ERC20
    function balanceOf(
        address _account
    ) public view virtual override(ERC20) returns (uint256) {
        return twabController.balanceOf(address(this), _account);
    }

    /// @inheritdoc ERC20
    function totalSupply() public view virtual override(ERC20) returns (uint256) {
        return twabController.totalSupply(address(this));
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Internal ERC20 Overrides
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Mints tokens to `_receiver` and increases the total supply.
    /// @dev Emits a {Transfer} event with `from` set to the zero address.
    /// @dev `_receiver` cannot be the zero address.
    /// @param _receiver Address that will receive the minted tokens
    /// @param _amount Tokens to mint
    function _mint(address _receiver, uint256 _amount) internal virtual override {
        twabController.mint(_receiver, SafeCast.toUint96(_amount));
        emit Transfer(address(0), _receiver, _amount);
    }

    /// @notice Destroys tokens from `_owner` and reduces the total supply.
    /// @dev Emits a {Transfer} event with `to` set to the zero address.
    /// @dev `_owner` cannot be the zero address.
    /// @dev `_owner` must have at least `_amount` tokens.
    /// @param _owner The owner of the tokens
    /// @param _amount The amount of tokens to burn
    function _burn(address _owner, uint256 _amount) internal virtual override {
        twabController.burn(_owner, SafeCast.toUint96(_amount));
        emit Transfer(_owner, address(0), _amount);
    }

    /// @notice Transfers tokens from one account to another.
    /// @dev Emits a {Transfer} event.
    /// @dev `_from` cannot be the zero address.
    /// @dev `_to` cannot be the zero address.
    /// @dev `_from` must have a balance of at least `_amount`.
    /// @param _from Address to transfer from
    /// @param _to Address to transfer to
    /// @param _amount The amount of tokens to transfer
    function _transfer(address _from, address _to, uint256 _amount) internal virtual override {
        twabController.transfer(_from, _to, SafeCast.toUint96(_amount));
        emit Transfer(_from, _to, _amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILiquidationSource {

  /**
   * @notice Emitted when a new liquidation pair is set for the given `tokenOut`.
   * @param tokenOut The token being liquidated
   * @param liquidationPair The new liquidation pair for the token
   */
  event LiquidationPairSet(address indexed tokenOut, address indexed liquidationPair);

  /**
   * @notice Get the available amount of tokens that can be swapped.
   * @param tokenOut Address of the token to get available balance for
   * @return uint256 Available amount of `token`
   */
  function liquidatableBalanceOf(address tokenOut) external returns (uint256);

  /**
   * @notice Transfers tokens to the receiver
   * @param sender Address that triggered the liquidation
   * @param receiver Address of the account that will receive `tokenOut`
   * @param tokenOut Address of the token being bought
   * @param amountOut Amount of token being bought
   */
  function transferTokensOut(
    address sender,
    address receiver,
    address tokenOut,
    uint256 amountOut
  ) external returns (bytes memory);

  /**
   * @notice Verifies that tokens have been transferred in.
   * @param tokenIn Address of the token being sold
   * @param amountIn Amount of token being sold
   * @param transferTokensOutData Data returned by the corresponding transferTokensOut call
   */
  function verifyTokensIn(
    address tokenIn,
    uint256 amountIn,
    bytes calldata transferTokensOutData
  ) external;

  /**
   * @notice Get the address that will receive `tokenIn`.
   * @param tokenIn Address of the token to get the target address for
   * @return address Address of the target
   */
  function targetOf(address tokenIn) external returns (address);

  /**
   * @notice Checks if a liquidation pair can be used to liquidate the given tokenOut from this source.
   * @param tokenOut The address of the token to liquidate
   * @param liquidationPair The address of the liquidation pair that is being checked
   * @return bool True if the liquidation pair can be used, false otherwise
   */
  function isLiquidationPair(address tokenOut, address liquidationPair) external returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Errors.sol" as CastingErrors;
import { MAX_UINT128, MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18, uMIN_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { uMAX_UD2x18 } from "../ud2x18/Constants.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Casts an SD59x18 number into int256.
/// @dev This is basically a functional alias for {unwrap}.
function intoInt256(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x);
}

/// @notice Casts an SD59x18 number into SD1x18.
/// @dev Requirements:
/// - x must be greater than or equal to `uMIN_SD1x18`.
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(SD59x18 x) pure returns (SD1x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < uMIN_SD1x18) {
        revert CastingErrors.PRBMath_SD59x18_IntoSD1x18_Underflow(x);
    }
    if (xInt > uMAX_SD1x18) {
        revert CastingErrors.PRBMath_SD59x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(xInt));
}

/// @notice Casts an SD59x18 number into UD2x18.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `uMAX_UD2x18`.
function intoUD2x18(SD59x18 x) pure returns (UD2x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUD2x18_Underflow(x);
    }
    if (xInt > int256(uint256(uMAX_UD2x18))) {
        revert CastingErrors.PRBMath_SD59x18_IntoUD2x18_Overflow(x);
    }
    result = UD2x18.wrap(uint64(uint256(xInt)));
}

/// @notice Casts an SD59x18 number into UD60x18.
/// @dev Requirements:
/// - x must be positive.
function intoUD60x18(SD59x18 x) pure returns (UD60x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUD60x18_Underflow(x);
    }
    result = UD60x18.wrap(uint256(xInt));
}

/// @notice Casts an SD59x18 number into uint256.
/// @dev Requirements:
/// - x must be positive.
function intoUint256(SD59x18 x) pure returns (uint256 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint256_Underflow(x);
    }
    result = uint256(xInt);
}

/// @notice Casts an SD59x18 number into uint128.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `uMAX_UINT128`.
function intoUint128(SD59x18 x) pure returns (uint128 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint128_Underflow(x);
    }
    if (xInt > int256(uint256(MAX_UINT128))) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint128_Overflow(x);
    }
    result = uint128(uint256(xInt));
}

/// @notice Casts an SD59x18 number into uint40.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(SD59x18 x) pure returns (uint40 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint40_Underflow(x);
    }
    if (xInt > int256(uint256(MAX_UINT40))) {
        revert CastingErrors.PRBMath_SD59x18_IntoUint40_Overflow(x);
    }
    result = uint40(uint256(xInt));
}

/// @notice Alias for {wrap}.
function sd(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

/// @notice Alias for {wrap}.
function sd59x18(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

/// @notice Unwraps an SD59x18 number into int256.
function unwrap(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x);
}

/// @notice Wraps an int256 number into SD59x18.
function wrap(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD59x18 } from "./ValueType.sol";

// NOTICE: the "u" prefix stands for "unwrapped".

/// @dev Euler's number as an SD59x18 number.
SD59x18 constant E = SD59x18.wrap(2_718281828459045235);

/// @dev The maximum input permitted in {exp}.
int256 constant uEXP_MAX_INPUT = 133_084258667509499440;
SD59x18 constant EXP_MAX_INPUT = SD59x18.wrap(uEXP_MAX_INPUT);

/// @dev The maximum input permitted in {exp2}.
int256 constant uEXP2_MAX_INPUT = 192e18 - 1;
SD59x18 constant EXP2_MAX_INPUT = SD59x18.wrap(uEXP2_MAX_INPUT);

/// @dev Half the UNIT number.
int256 constant uHALF_UNIT = 0.5e18;
SD59x18 constant HALF_UNIT = SD59x18.wrap(uHALF_UNIT);

/// @dev $log_2(10)$ as an SD59x18 number.
int256 constant uLOG2_10 = 3_321928094887362347;
SD59x18 constant LOG2_10 = SD59x18.wrap(uLOG2_10);

/// @dev $log_2(e)$ as an SD59x18 number.
int256 constant uLOG2_E = 1_442695040888963407;
SD59x18 constant LOG2_E = SD59x18.wrap(uLOG2_E);

/// @dev The maximum value an SD59x18 number can have.
int256 constant uMAX_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_792003956564819967;
SD59x18 constant MAX_SD59x18 = SD59x18.wrap(uMAX_SD59x18);

/// @dev The maximum whole value an SD59x18 number can have.
int256 constant uMAX_WHOLE_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_000000000000000000;
SD59x18 constant MAX_WHOLE_SD59x18 = SD59x18.wrap(uMAX_WHOLE_SD59x18);

/// @dev The minimum value an SD59x18 number can have.
int256 constant uMIN_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_792003956564819968;
SD59x18 constant MIN_SD59x18 = SD59x18.wrap(uMIN_SD59x18);

/// @dev The minimum whole value an SD59x18 number can have.
int256 constant uMIN_WHOLE_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_000000000000000000;
SD59x18 constant MIN_WHOLE_SD59x18 = SD59x18.wrap(uMIN_WHOLE_SD59x18);

/// @dev PI as an SD59x18 number.
SD59x18 constant PI = SD59x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of SD59x18.
int256 constant uUNIT = 1e18;
SD59x18 constant UNIT = SD59x18.wrap(1e18);

/// @dev The unit number squared.
int256 constant uUNIT_SQUARED = 1e36;
SD59x18 constant UNIT_SQUARED = SD59x18.wrap(uUNIT_SQUARED);

/// @dev Zero as an SD59x18 number.
SD59x18 constant ZERO = SD59x18.wrap(0);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { uMAX_SD59x18, uMIN_SD59x18, uUNIT } from "./Constants.sol";
import { PRBMath_SD59x18_Convert_Overflow, PRBMath_SD59x18_Convert_Underflow } from "./Errors.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Converts a simple integer to SD59x18 by multiplying it by `UNIT`.
///
/// @dev Requirements:
/// - x must be greater than or equal to `MIN_SD59x18 / UNIT`.
/// - x must be less than or equal to `MAX_SD59x18 / UNIT`.
///
/// @param x The basic integer to convert.
/// @param result The same number converted to SD59x18.
function convert(int256 x) pure returns (SD59x18 result) {
    if (x < uMIN_SD59x18 / uUNIT) {
        revert PRBMath_SD59x18_Convert_Underflow(x);
    }
    if (x > uMAX_SD59x18 / uUNIT) {
        revert PRBMath_SD59x18_Convert_Overflow(x);
    }
    unchecked {
        result = SD59x18.wrap(x * uUNIT);
    }
}

/// @notice Converts an SD59x18 number to a simple integer by dividing it by `UNIT`.
/// @dev The result is rounded toward zero.
/// @param x The SD59x18 number to convert.
/// @return result The same number as a simple integer.
function convert(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x) / uUNIT;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD59x18 } from "./ValueType.sol";

/// @notice Thrown when taking the absolute value of `MIN_SD59x18`.
error PRBMath_SD59x18_Abs_MinSD59x18();

/// @notice Thrown when ceiling a number overflows SD59x18.
error PRBMath_SD59x18_Ceil_Overflow(SD59x18 x);

/// @notice Thrown when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMath_SD59x18_Convert_Overflow(int256 x);

/// @notice Thrown when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMath_SD59x18_Convert_Underflow(int256 x);

/// @notice Thrown when dividing two numbers and one of them is `MIN_SD59x18`.
error PRBMath_SD59x18_Div_InputTooSmall();

/// @notice Thrown when dividing two numbers and one of the intermediary unsigned results overflows SD59x18.
error PRBMath_SD59x18_Div_Overflow(SD59x18 x, SD59x18 y);

/// @notice Thrown when taking the natural exponent of a base greater than 133_084258667509499441.
error PRBMath_SD59x18_Exp_InputTooBig(SD59x18 x);

/// @notice Thrown when taking the binary exponent of a base greater than 192e18.
error PRBMath_SD59x18_Exp2_InputTooBig(SD59x18 x);

/// @notice Thrown when flooring a number underflows SD59x18.
error PRBMath_SD59x18_Floor_Underflow(SD59x18 x);

/// @notice Thrown when taking the geometric mean of two numbers and their product is negative.
error PRBMath_SD59x18_Gm_NegativeProduct(SD59x18 x, SD59x18 y);

/// @notice Thrown when taking the geometric mean of two numbers and multiplying them overflows SD59x18.
error PRBMath_SD59x18_Gm_Overflow(SD59x18 x, SD59x18 y);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.
error PRBMath_SD59x18_IntoSD1x18_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.
error PRBMath_SD59x18_IntoSD1x18_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.
error PRBMath_SD59x18_IntoUD2x18_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.
error PRBMath_SD59x18_IntoUD2x18_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD60x18.
error PRBMath_SD59x18_IntoUD60x18_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.
error PRBMath_SD59x18_IntoUint128_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.
error PRBMath_SD59x18_IntoUint128_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint256.
error PRBMath_SD59x18_IntoUint256_Underflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.
error PRBMath_SD59x18_IntoUint40_Overflow(SD59x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.
error PRBMath_SD59x18_IntoUint40_Underflow(SD59x18 x);

/// @notice Thrown when taking the logarithm of a number less than or equal to zero.
error PRBMath_SD59x18_Log_InputTooSmall(SD59x18 x);

/// @notice Thrown when multiplying two numbers and one of the inputs is `MIN_SD59x18`.
error PRBMath_SD59x18_Mul_InputTooSmall();

/// @notice Thrown when multiplying two numbers and the intermediary absolute result overflows SD59x18.
error PRBMath_SD59x18_Mul_Overflow(SD59x18 x, SD59x18 y);

/// @notice Thrown when raising a number to a power and the intermediary absolute result overflows SD59x18.
error PRBMath_SD59x18_Powu_Overflow(SD59x18 x, uint256 y);

/// @notice Thrown when taking the square root of a negative number.
error PRBMath_SD59x18_Sqrt_NegativeInput(SD59x18 x);

/// @notice Thrown when the calculating the square root overflows SD59x18.
error PRBMath_SD59x18_Sqrt_Overflow(SD59x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { wrap } from "./Casting.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Implements the checked addition operation (+) in the SD59x18 type.
function add(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    return wrap(x.unwrap() + y.unwrap());
}

/// @notice Implements the AND (&) bitwise operation in the SD59x18 type.
function and(SD59x18 x, int256 bits) pure returns (SD59x18 result) {
    return wrap(x.unwrap() & bits);
}

/// @notice Implements the AND (&) bitwise operation in the SD59x18 type.
function and2(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    return wrap(x.unwrap() & y.unwrap());
}

/// @notice Implements the equal (=) operation in the SD59x18 type.
function eq(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() == y.unwrap();
}

/// @notice Implements the greater than operation (>) in the SD59x18 type.
function gt(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() > y.unwrap();
}

/// @notice Implements the greater than or equal to operation (>=) in the SD59x18 type.
function gte(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() >= y.unwrap();
}

/// @notice Implements a zero comparison check function in the SD59x18 type.
function isZero(SD59x18 x) pure returns (bool result) {
    result = x.unwrap() == 0;
}

/// @notice Implements the left shift operation (<<) in the SD59x18 type.
function lshift(SD59x18 x, uint256 bits) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() << bits);
}

/// @notice Implements the lower than operation (<) in the SD59x18 type.
function lt(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() < y.unwrap();
}

/// @notice Implements the lower than or equal to operation (<=) in the SD59x18 type.
function lte(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() <= y.unwrap();
}

/// @notice Implements the unchecked modulo operation (%) in the SD59x18 type.
function mod(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() % y.unwrap());
}

/// @notice Implements the not equal operation (!=) in the SD59x18 type.
function neq(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = x.unwrap() != y.unwrap();
}

/// @notice Implements the NOT (~) bitwise operation in the SD59x18 type.
function not(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(~x.unwrap());
}

/// @notice Implements the OR (|) bitwise operation in the SD59x18 type.
function or(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() | y.unwrap());
}

/// @notice Implements the right shift operation (>>) in the SD59x18 type.
function rshift(SD59x18 x, uint256 bits) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the SD59x18 type.
function sub(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() - y.unwrap());
}

/// @notice Implements the checked unary minus operation (-) in the SD59x18 type.
function unary(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(-x.unwrap());
}

/// @notice Implements the unchecked addition operation (+) in the SD59x18 type.
function uncheckedAdd(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(x.unwrap() + y.unwrap());
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the SD59x18 type.
function uncheckedSub(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(x.unwrap() - y.unwrap());
    }
}

/// @notice Implements the unchecked unary minus operation (-) in the SD59x18 type.
function uncheckedUnary(SD59x18 x) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(-x.unwrap());
    }
}

/// @notice Implements the XOR (^) bitwise operation in the SD59x18 type.
function xor(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() ^ y.unwrap());
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as Errors;
import {
    uEXP_MAX_INPUT,
    uEXP2_MAX_INPUT,
    uHALF_UNIT,
    uLOG2_10,
    uLOG2_E,
    uMAX_SD59x18,
    uMAX_WHOLE_SD59x18,
    uMIN_SD59x18,
    uMIN_WHOLE_SD59x18,
    UNIT,
    uUNIT,
    uUNIT_SQUARED,
    ZERO
} from "./Constants.sol";
import { wrap } from "./Helpers.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Calculates the absolute value of x.
///
/// @dev Requirements:
/// - x must be greater than `MIN_SD59x18`.
///
/// @param x The SD59x18 number for which to calculate the absolute value.
/// @param result The absolute value of x as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function abs(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt == uMIN_SD59x18) {
        revert Errors.PRBMath_SD59x18_Abs_MinSD59x18();
    }
    result = xInt < 0 ? wrap(-xInt) : x;
}

/// @notice Calculates the arithmetic average of x and y.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// @param x The first operand as an SD59x18 number.
/// @param y The second operand as an SD59x18 number.
/// @return result The arithmetic average as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function avg(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();

    unchecked {
        // This operation is equivalent to `x / 2 +  y / 2`, and it can never overflow.
        int256 sum = (xInt >> 1) + (yInt >> 1);

        if (sum < 0) {
            // If at least one of x and y is odd, add 1 to the result, because shifting negative numbers to the right
            // rounds toward negative infinity. The right part is equivalent to `sum + (x % 2 == 1 || y % 2 == 1)`.
            assembly ("memory-safe") {
                result := add(sum, and(or(xInt, yInt), 1))
            }
        } else {
            // Add 1 if both x and y are odd to account for the double 0.5 remainder truncated after shifting.
            result = wrap(sum + (xInt & yInt & 1));
        }
    }
}

/// @notice Yields the smallest whole number greater than or equal to x.
///
/// @dev Optimized for fractional value inputs, because every whole value has (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_SD59x18`.
///
/// @param x The SD59x18 number to ceil.
/// @param result The smallest whole number greater than or equal to x, as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function ceil(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt > uMAX_WHOLE_SD59x18) {
        revert Errors.PRBMath_SD59x18_Ceil_Overflow(x);
    }

    int256 remainder = xInt % uUNIT;
    if (remainder == 0) {
        result = x;
    } else {
        unchecked {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            int256 resultInt = xInt - remainder;
            if (xInt > 0) {
                resultInt += uUNIT;
            }
            result = wrap(resultInt);
        }
    }
}

/// @notice Divides two SD59x18 numbers, returning a new SD59x18 number.
///
/// @dev This is an extension of {Common.mulDiv} for signed numbers, which works by computing the signs and the absolute
/// values separately.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
/// - The result is rounded toward zero.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
/// - None of the inputs can be `MIN_SD59x18`.
/// - The denominator must not be zero.
/// - The result must fit in SD59x18.
///
/// @param x The numerator as an SD59x18 number.
/// @param y The denominator as an SD59x18 number.
/// @param result The quotient as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function div(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == uMIN_SD59x18 || yInt == uMIN_SD59x18) {
        revert Errors.PRBMath_SD59x18_Div_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*UNIT÷y). The resulting value must fit in SD59x18.
    uint256 resultAbs = Common.mulDiv(xAbs, uint256(uUNIT), yAbs);
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert Errors.PRBMath_SD59x18_Div_Overflow(x, y);
    }

    // Check if x and y have the same sign using two's complement representation. The left-most bit represents the sign (1 for
    // negative, 0 for positive or zero).
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be positive. Otherwise, it should be negative.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Calculates the natural exponent of x using the following formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {exp2}.
///
/// Requirements:
/// - Refer to the requirements in {exp2}.
/// - x must be less than 133_084258667509499441.
///
/// @param x The exponent as an SD59x18 number.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();

    // This check prevents values greater than 192e18 from being passed to {exp2}.
    if (xInt > uEXP_MAX_INPUT) {
        revert Errors.PRBMath_SD59x18_Exp_InputTooBig(x);
    }

    unchecked {
        // Inline the fixed-point multiplication to save gas.
        int256 doubleUnitProduct = xInt * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method using the following formula:
///
/// $$
/// 2^{-x} = \frac{1}{2^x}
/// $$
///
/// @dev See https://ethereum.stackexchange.com/q/79903/24693.
///
/// Notes:
/// - If x is less than -59_794705707972522261, the result is zero.
///
/// Requirements:
/// - x must be less than 192e18.
/// - The result must fit in SD59x18.
///
/// @param x The exponent as an SD59x18 number.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp2(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < 0) {
        // The inverse of any number less than this is truncated to zero.
        if (xInt < -59_794705707972522261) {
            return ZERO;
        }

        unchecked {
            // Inline the fixed-point inversion to save gas.
            result = wrap(uUNIT_SQUARED / exp2(wrap(-xInt)).unwrap());
        }
    } else {
        // Numbers greater than or equal to 192e18 don't fit in the 192.64-bit format.
        if (xInt > uEXP2_MAX_INPUT) {
            revert Errors.PRBMath_SD59x18_Exp2_InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x_192x64 = uint256((xInt << 64) / uUNIT);

            // It is safe to cast the result to int256 due to the checks above.
            result = wrap(int256(Common.exp2(x_192x64)));
        }
    }
}

/// @notice Yields the greatest whole number less than or equal to x.
///
/// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional
/// counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be greater than or equal to `MIN_WHOLE_SD59x18`.
///
/// @param x The SD59x18 number to floor.
/// @param result The greatest whole number less than or equal to x, as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function floor(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < uMIN_WHOLE_SD59x18) {
        revert Errors.PRBMath_SD59x18_Floor_Underflow(x);
    }

    int256 remainder = xInt % uUNIT;
    if (remainder == 0) {
        result = x;
    } else {
        unchecked {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            int256 resultInt = xInt - remainder;
            if (xInt < 0) {
                resultInt -= uUNIT;
            }
            result = wrap(resultInt);
        }
    }
}

/// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right.
/// of the radix point for negative numbers.
/// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
/// @param x The SD59x18 number to get the fractional part of.
/// @param result The fractional part of x as an SD59x18 number.
function frac(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(x.unwrap() % uUNIT);
}

/// @notice Calculates the geometric mean of x and y, i.e. $\sqrt{x * y}$.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x * y must fit in SD59x18.
/// - x * y must not be negative, since complex numbers are not supported.
///
/// @param x The first operand as an SD59x18 number.
/// @param y The second operand as an SD59x18 number.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function gm(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == 0 || yInt == 0) {
        return ZERO;
    }

    unchecked {
        // Equivalent to `xy / x != y`. Checking for overflow this way is faster than letting Solidity do it.
        int256 xyInt = xInt * yInt;
        if (xyInt / xInt != yInt) {
            revert Errors.PRBMath_SD59x18_Gm_Overflow(x, y);
        }

        // The product must not be negative, since complex numbers are not supported.
        if (xyInt < 0) {
            revert Errors.PRBMath_SD59x18_Gm_NegativeProduct(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product picked up a factor of `UNIT`
        // during multiplication. See the comments in {Common.sqrt}.
        uint256 resultUint = Common.sqrt(uint256(xyInt));
        result = wrap(int256(resultUint));
    }
}

/// @notice Calculates the inverse of x.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x must not be zero.
///
/// @param x The SD59x18 number for which to calculate the inverse.
/// @return result The inverse as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function inv(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(uUNIT_SQUARED / x.unwrap());
}

/// @notice Calculates the natural logarithm of x using the following formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
/// - The precision isn't sufficiently fine-grained to return exactly `UNIT` when the input is `E`.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The SD59x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function ln(SD59x18 x) pure returns (SD59x18 result) {
    // Inline the fixed-point multiplication to save gas. This is overflow-safe because the maximum value that
    // {log2} can return is ~195_205294292027477728.
    result = wrap(log2(x).unwrap() * uUNIT / uLOG2_E);
}

/// @notice Calculates the common logarithm of x using the following formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// However, if x is an exact power of ten, a hard coded value is returned.
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The SD59x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function log10(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < 0) {
        revert Errors.PRBMath_SD59x18_Log_InputTooSmall(x);
    }

    // Note that the `mul` in this block is the standard multiplication operation, not {SD59x18.mul}.
    // prettier-ignore
    assembly ("memory-safe") {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        default { result := uMAX_SD59x18 }
    }

    if (result.unwrap() == uMAX_SD59x18) {
        unchecked {
            // Inline the fixed-point division to save gas.
            result = wrap(log2(x).unwrap() * uUNIT / uLOG2_10);
        }
    }
}

/// @notice Calculates the binary logarithm of x using the iterative approximation algorithm:
///
/// $$
/// log_2{x} = n + log_2{y}, \text{ where } y = x*2^{-n}, \ y \in [1, 2)
/// $$
///
/// For $0 \leq x \lt 1$, the input is inverted:
///
/// $$
/// log_2{x} = -log_2{\frac{1}{x}}
/// $$
///
/// @dev See https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation.
///
/// Notes:
/// - Due to the lossy precision of the iterative approximation, the results are not perfectly accurate to the last decimal.
///
/// Requirements:
/// - x must be greater than zero.
///
/// @param x The SD59x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function log2(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt <= 0) {
        revert Errors.PRBMath_SD59x18_Log_InputTooSmall(x);
    }

    unchecked {
        int256 sign;
        if (xInt >= uUNIT) {
            sign = 1;
        } else {
            sign = -1;
            // Inline the fixed-point inversion to save gas.
            xInt = uUNIT_SQUARED / xInt;
        }

        // Calculate the integer part of the logarithm.
        uint256 n = Common.msb(uint256(xInt / uUNIT));

        // This is the integer part of the logarithm as an SD59x18 number. The operation can't overflow
        // because n is at most 255, `UNIT` is 1e18, and the sign is either 1 or -1.
        int256 resultInt = int256(n) * uUNIT;

        // Calculate $y = x * 2^{-n}$.
        int256 y = xInt >> n;

        // If y is the unit number, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultInt * sign);
        }

        // Calculate the fractional part via the iterative approximation.
        // The `delta >>= 1` part is equivalent to `delta /= 2`, but shifting bits is more gas efficient.
        int256 DOUBLE_UNIT = 2e18;
        for (int256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is y^2 >= 2e18 and so in the range [2e18, 4e18)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultInt = resultInt + delta;

                // Halve y, which corresponds to z/2 in the Wikipedia article.
                y >>= 1;
            }
        }
        resultInt *= sign;
        result = wrap(resultInt);
    }
}

/// @notice Multiplies two SD59x18 numbers together, returning a new SD59x18 number.
///
/// @dev Notes:
/// - Refer to the notes in {Common.mulDiv18}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv18}.
/// - None of the inputs can be `MIN_SD59x18`.
/// - The result must fit in SD59x18.
///
/// @param x The multiplicand as an SD59x18 number.
/// @param y The multiplier as an SD59x18 number.
/// @return result The product as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function mul(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();
    if (xInt == uMIN_SD59x18 || yInt == uMIN_SD59x18) {
        revert Errors.PRBMath_SD59x18_Mul_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*y÷UNIT). The resulting value must fit in SD59x18.
    uint256 resultAbs = Common.mulDiv18(xAbs, yAbs);
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert Errors.PRBMath_SD59x18_Mul_Overflow(x, y);
    }

    // Check if x and y have the same sign using two's complement representation. The left-most bit represents the sign (1 for
    // negative, 0 for positive or zero).
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be positive. Otherwise, it should be negative.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Raises x to the power of y using the following formula:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {exp2}, {log2}, and {mul}.
/// - Returns `UNIT` for 0^0.
///
/// Requirements:
/// - Refer to the requirements in {exp2}, {log2}, and {mul}.
///
/// @param x The base as an SD59x18 number.
/// @param y Exponent to raise x to, as an SD59x18 number
/// @return result x raised to power y, as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function pow(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    int256 yInt = y.unwrap();

    // If both x and y are zero, the result is `UNIT`. If just x is zero, the result is always zero.
    if (xInt == 0) {
        return yInt == 0 ? UNIT : ZERO;
    }
    // If x is `UNIT`, the result is always `UNIT`.
    else if (xInt == uUNIT) {
        return UNIT;
    }

    // If y is zero, the result is always `UNIT`.
    if (yInt == 0) {
        return UNIT;
    }
    // If y is `UNIT`, the result is always x.
    else if (yInt == uUNIT) {
        return x;
    }

    // Calculate the result using the formula.
    result = exp2(mul(log2(x), y));
}

/// @notice Raises x (an SD59x18 number) to the power y (an unsigned basic integer) using the well-known
/// algorithm "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv18}.
/// - Returns `UNIT` for 0^0.
///
/// Requirements:
/// - Refer to the requirements in {abs} and {Common.mulDiv18}.
/// - The result must fit in SD59x18.
///
/// @param x The base as an SD59x18 number.
/// @param y The exponent as a uint256.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function powu(SD59x18 x, uint256 y) pure returns (SD59x18 result) {
    uint256 xAbs = uint256(abs(x).unwrap());

    // Calculate the first iteration of the loop in advance.
    uint256 resultAbs = y & 1 > 0 ? xAbs : uint256(uUNIT);

    // Equivalent to `for(y /= 2; y > 0; y /= 2)`.
    uint256 yAux = y;
    for (yAux >>= 1; yAux > 0; yAux >>= 1) {
        xAbs = Common.mulDiv18(xAbs, xAbs);

        // Equivalent to `y % 2 == 1`.
        if (yAux & 1 > 0) {
            resultAbs = Common.mulDiv18(resultAbs, xAbs);
        }
    }

    // The result must fit in SD59x18.
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert Errors.PRBMath_SD59x18_Powu_Overflow(x, y);
    }

    unchecked {
        // Is the base negative and the exponent odd? If yes, the result should be negative.
        int256 resultInt = int256(resultAbs);
        bool isNegative = x.unwrap() < 0 && y & 1 == 1;
        if (isNegative) {
            resultInt = -resultInt;
        }
        result = wrap(resultInt);
    }
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - Only the positive root is returned.
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x cannot be negative, since complex numbers are not supported.
/// - x must be less than `MAX_SD59x18 / UNIT`.
///
/// @param x The SD59x18 number for which to calculate the square root.
/// @return result The result as an SD59x18 number.
/// @custom:smtchecker abstract-function-nondet
function sqrt(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = x.unwrap();
    if (xInt < 0) {
        revert Errors.PRBMath_SD59x18_Sqrt_NegativeInput(x);
    }
    if (xInt > uMAX_SD59x18 / uUNIT) {
        revert Errors.PRBMath_SD59x18_Sqrt_Overflow(x);
    }

    unchecked {
        // Multiply x by `UNIT` to account for the factor of `UNIT` picked up when multiplying two SD59x18 numbers.
        // In this case, the two numbers are both the square root.
        uint256 resultUint = Common.sqrt(uint256(xInt * uUNIT));
        result = wrap(int256(resultUint));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;
import "./Helpers.sol" as Helpers;
import "./Math.sol" as Math;

/// @notice The signed 59.18-decimal fixed-point number representation, which can have up to 59 digits and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity
/// type int256.
type SD59x18 is int256;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoInt256,
    Casting.intoSD1x18,
    Casting.intoUD2x18,
    Casting.intoUD60x18,
    Casting.intoUint256,
    Casting.intoUint128,
    Casting.intoUint40,
    Casting.unwrap
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    Math.abs,
    Math.avg,
    Math.ceil,
    Math.div,
    Math.exp,
    Math.exp2,
    Math.floor,
    Math.frac,
    Math.gm,
    Math.inv,
    Math.log10,
    Math.log2,
    Math.ln,
    Math.mul,
    Math.pow,
    Math.powu,
    Math.sqrt
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    Helpers.add,
    Helpers.and,
    Helpers.eq,
    Helpers.gt,
    Helpers.gte,
    Helpers.isZero,
    Helpers.lshift,
    Helpers.lt,
    Helpers.lte,
    Helpers.mod,
    Helpers.neq,
    Helpers.not,
    Helpers.or,
    Helpers.rshift,
    Helpers.sub,
    Helpers.uncheckedAdd,
    Helpers.uncheckedSub,
    Helpers.uncheckedUnary,
    Helpers.xor
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                    OPERATORS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes it possible to use these operators on the SD59x18 type.
using {
    Helpers.add as +,
    Helpers.and2 as &,
    Math.div as /,
    Helpers.eq as ==,
    Helpers.gt as >,
    Helpers.gte as >=,
    Helpers.lt as <,
    Helpers.lte as <=,
    Helpers.mod as %,
    Math.mul as *,
    Helpers.neq as !=,
    Helpers.not as ~,
    Helpers.or as |,
    Helpers.sub as -,
    Helpers.unary as -,
    Helpers.xor as ^
} for SD59x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as CastingErrors;
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { SD1x18 } from "./ValueType.sol";

/// @notice Casts an SD1x18 number into SD59x18.
/// @dev There is no overflow check because the domain of SD1x18 is a subset of SD59x18.
function intoSD59x18(SD1x18 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(int256(SD1x18.unwrap(x)));
}

/// @notice Casts an SD1x18 number into UD2x18.
/// - x must be positive.
function intoUD2x18(SD1x18 x) pure returns (UD2x18 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUD2x18_Underflow(x);
    }
    result = UD2x18.wrap(uint64(xInt));
}

/// @notice Casts an SD1x18 number into UD60x18.
/// @dev Requirements:
/// - x must be positive.
function intoUD60x18(SD1x18 x) pure returns (UD60x18 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUD60x18_Underflow(x);
    }
    result = UD60x18.wrap(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint256.
/// @dev Requirements:
/// - x must be positive.
function intoUint256(SD1x18 x) pure returns (uint256 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUint256_Underflow(x);
    }
    result = uint256(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint128.
/// @dev Requirements:
/// - x must be positive.
function intoUint128(SD1x18 x) pure returns (uint128 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUint128_Underflow(x);
    }
    result = uint128(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint40.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(SD1x18 x) pure returns (uint40 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert CastingErrors.PRBMath_SD1x18_ToUint40_Underflow(x);
    }
    if (xInt > int64(uint64(Common.MAX_UINT40))) {
        revert CastingErrors.PRBMath_SD1x18_ToUint40_Overflow(x);
    }
    result = uint40(uint64(xInt));
}

/// @notice Alias for {wrap}.
function sd1x18(int64 x) pure returns (SD1x18 result) {
    result = SD1x18.wrap(x);
}

/// @notice Unwraps an SD1x18 number into int64.
function unwrap(SD1x18 x) pure returns (int64 result) {
    result = SD1x18.unwrap(x);
}

/// @notice Wraps an int64 number into SD1x18.
function wrap(int64 x) pure returns (SD1x18 result) {
    result = SD1x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD1x18 } from "./ValueType.sol";

/// @dev Euler's number as an SD1x18 number.
SD1x18 constant E = SD1x18.wrap(2_718281828459045235);

/// @dev The maximum value an SD1x18 number can have.
int64 constant uMAX_SD1x18 = 9_223372036854775807;
SD1x18 constant MAX_SD1x18 = SD1x18.wrap(uMAX_SD1x18);

/// @dev The maximum value an SD1x18 number can have.
int64 constant uMIN_SD1x18 = -9_223372036854775808;
SD1x18 constant MIN_SD1x18 = SD1x18.wrap(uMIN_SD1x18);

/// @dev PI as an SD1x18 number.
SD1x18 constant PI = SD1x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of SD1x18.
SD1x18 constant UNIT = SD1x18.wrap(1e18);
int256 constant uUNIT = 1e18;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SD1x18 } from "./ValueType.sol";

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in UD2x18.
error PRBMath_SD1x18_ToUD2x18_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in UD60x18.
error PRBMath_SD1x18_ToUD60x18_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint128.
error PRBMath_SD1x18_ToUint128_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint256.
error PRBMath_SD1x18_ToUint256_Underflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint40.
error PRBMath_SD1x18_ToUint40_Overflow(SD1x18 x);

/// @notice Thrown when trying to cast a SD1x18 number that doesn't fit in uint40.
error PRBMath_SD1x18_ToUint40_Underflow(SD1x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;

/// @notice The signed 1.18-decimal fixed-point number representation, which can have up to 1 digit and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity
/// type int64. This is useful when end users want to use int64 to save gas, e.g. with tight variable packing in contract
/// storage.
type SD1x18 is int64;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoSD59x18,
    Casting.intoUD2x18,
    Casting.intoUD60x18,
    Casting.intoUint256,
    Casting.intoUint128,
    Casting.intoUint40,
    Casting.unwrap
} for SD1x18 global;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "ring-buffer-lib/RingBufferLib.sol";

import { ObservationLib, MAX_CARDINALITY } from "./ObservationLib.sol";

type PeriodOffsetRelativeTimestamp is uint32;

/// @notice Emitted when a balance is decreased by an amount that exceeds the amount available.
/// @param balance The current balance of the account
/// @param amount The amount being decreased from the account's balance
/// @param message An additional message describing the error
error BalanceLTAmount(uint96 balance, uint96 amount, string message);

/// @notice Emitted when a delegate balance is decreased by an amount that exceeds the amount available.
/// @param delegateBalance The current delegate balance of the account
/// @param delegateAmount The amount being decreased from the account's delegate balance
/// @param message An additional message describing the error
error DelegateBalanceLTAmount(uint96 delegateBalance, uint96 delegateAmount, string message);

/// @notice Emitted when a request is made for a twab that is not yet finalized.
/// @param timestamp The requested timestamp
/// @param currentOverwritePeriodStartedAt The current overwrite period start time
error TimestampNotFinalized(uint256 timestamp, uint256 currentOverwritePeriodStartedAt);

/// @notice Emitted when a TWAB time range start is after the end.
/// @param start The start time
/// @param end The end time
error InvalidTimeRange(uint256 start, uint256 end);

/// @notice Emitted when there is insufficient history to lookup a twab time range
/// @param requestedTimestamp The timestamp requested
/// @param oldestTimestamp The oldest timestamp that can be read
error InsufficientHistory(
  PeriodOffsetRelativeTimestamp requestedTimestamp,
  PeriodOffsetRelativeTimestamp oldestTimestamp
);

/**
 * @title  PoolTogether V5 TwabLib (Library)
 * @author PoolTogether Inc. & G9 Software Inc.
 * @dev    Time-Weighted Average Balance Library for ERC20 tokens.
 * @notice This TwabLib adds on-chain historical lookups to a user(s) time-weighted average balance.
 *         Each user is mapped to an Account struct containing the TWAB history (ring buffer) and
 *         ring buffer parameters. Every token.transfer() creates a new TWAB checkpoint. The new
 *         TWAB checkpoint is stored in the circular ring buffer, as either a new checkpoint or
 *         rewriting a previous checkpoint with new parameters. One checkpoint per day is stored.
 *         The TwabLib guarantees minimum 1 year of search history.
 * @notice There are limitations to the Observation data structure used. Ensure your token is
 *         compatible before using this library. Ensure the date ranges you're relying on are
 *         within safe boundaries.
 */
library TwabLib {
  /**
   * @notice Struct ring buffer parameters for single user Account.
   * @param balance Current token balance for an Account
   * @param delegateBalance Current delegate balance for an Account (active balance for chance)
   * @param nextObservationIndex Next uninitialized or updatable ring buffer checkpoint storage slot
   * @param cardinality Current total "initialized" ring buffer checkpoints for single user Account.
   *                    Used to set initial boundary conditions for an efficient binary search.
   */
  struct AccountDetails {
    uint96 balance;
    uint96 delegateBalance;
    uint16 nextObservationIndex;
    uint16 cardinality;
  }

  /**
   * @notice Account details and historical twabs.
   * @dev The size of observations is MAX_CARDINALITY from the ObservationLib.
   * @param details The account details
   * @param observations The history of observations for this account
   */
  struct Account {
    AccountDetails details;
    ObservationLib.Observation[17520] observations;
  }

  /**
   * @notice Increase a user's balance and delegate balance by a given amount.
   * @dev This function mutates the provided account.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _account The account to update
   * @param _amount The amount to increase the balance by
   * @param _delegateAmount The amount to increase the delegate balance by
   * @return observation The new/updated observation
   * @return isNew Whether or not the observation is new or overwrote a previous one
   * @return isObservationRecorded Whether or not an observation was recorded to storage
   */
  function increaseBalances(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    Account storage _account,
    uint96 _amount,
    uint96 _delegateAmount
  )
    internal
    returns (
      ObservationLib.Observation memory observation,
      bool isNew,
      bool isObservationRecorded,
      AccountDetails memory accountDetails
    )
  {
    accountDetails = _account.details;
    // record a new observation if the delegateAmount is non-zero and time has not overflowed.
    isObservationRecorded =
      _delegateAmount != uint96(0) &&
      block.timestamp <= lastObservationAt(PERIOD_LENGTH, PERIOD_OFFSET);

    accountDetails.balance += _amount;
    accountDetails.delegateBalance += _delegateAmount;

    // Only record a new Observation if the users delegateBalance has changed.
    if (isObservationRecorded) {
      (observation, isNew, accountDetails) = _recordObservation(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        accountDetails,
        _account
      );
    }

    _account.details = accountDetails;
  }

  /**
   * @notice Decrease a user's balance and delegate balance by a given amount.
   * @dev This function mutates the provided account.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _account The account to update
   * @param _amount The amount to decrease the balance by
   * @param _delegateAmount The amount to decrease the delegate balance by
   * @param _revertMessage The revert message to use if the balance is insufficient
   * @return observation The new/updated observation
   * @return isNew Whether or not the observation is new or overwrote a previous one
   * @return isObservationRecorded Whether or not the observation was recorded to storage
   */
  function decreaseBalances(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    Account storage _account,
    uint96 _amount,
    uint96 _delegateAmount,
    string memory _revertMessage
  )
    internal
    returns (
      ObservationLib.Observation memory observation,
      bool isNew,
      bool isObservationRecorded,
      AccountDetails memory accountDetails
    )
  {
    accountDetails = _account.details;

    if (accountDetails.balance < _amount) {
      revert BalanceLTAmount(accountDetails.balance, _amount, _revertMessage);
    }
    if (accountDetails.delegateBalance < _delegateAmount) {
      revert DelegateBalanceLTAmount(
        accountDetails.delegateBalance,
        _delegateAmount,
        _revertMessage
      );
    }

    // record a new observation if the delegateAmount is non-zero and time has not overflowed.
    isObservationRecorded =
      _delegateAmount != uint96(0) &&
      block.timestamp <= lastObservationAt(PERIOD_LENGTH, PERIOD_OFFSET);

    unchecked {
      accountDetails.balance -= _amount;
      accountDetails.delegateBalance -= _delegateAmount;
    }

    // Only record a new Observation if the users delegateBalance has changed.
    if (isObservationRecorded) {
      (observation, isNew, accountDetails) = _recordObservation(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        accountDetails,
        _account
      );
    }

    _account.details = accountDetails;
  }

  /**
   * @notice Looks up the oldest observation in the circular buffer.
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @return index The index of the oldest observation
   * @return observation The oldest observation in the circular buffer
   */
  function getOldestObservation(
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails
  ) internal view returns (uint16 index, ObservationLib.Observation memory observation) {
    // If the circular buffer has not been fully populated, we go to the beginning of the buffer at index 0.
    if (_accountDetails.cardinality < MAX_CARDINALITY) {
      index = 0;
      observation = _observations[0];
    } else {
      index = _accountDetails.nextObservationIndex;
      observation = _observations[index];
    }
  }

  /**
   * @notice Looks up the newest observation in the circular buffer.
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @return index The index of the newest observation
   * @return observation The newest observation in the circular buffer
   */
  function getNewestObservation(
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails
  ) internal view returns (uint16 index, ObservationLib.Observation memory observation) {
    index = uint16(
      RingBufferLib.newestIndex(_accountDetails.nextObservationIndex, MAX_CARDINALITY)
    );
    observation = _observations[index];
  }

  /**
   * @notice Looks up a users balance at a specific time in the past. The time must be before the current overwrite period.
   * @dev Ensure timestamps are safe using requireFinalized
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @param _targetTime The time to look up the balance at
   * @return balance The balance at the target time
   */
  function getBalanceAt(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails,
    uint256 _targetTime
  ) internal view requireFinalized(PERIOD_LENGTH, PERIOD_OFFSET, _targetTime) returns (uint256) {
    if (_targetTime < PERIOD_OFFSET) {
      return 0;
    }
    // if this is for an overflowed time period, return 0
    if (isShutdownAt(_targetTime, PERIOD_LENGTH, PERIOD_OFFSET)) {
      return 0;
    }
    ObservationLib.Observation memory prevOrAtObservation = _getPreviousOrAtObservation(
      _observations,
      _accountDetails,
      PeriodOffsetRelativeTimestamp.wrap(uint32(_targetTime - PERIOD_OFFSET))
    );
    return prevOrAtObservation.balance;
  }

  /**
   * @notice Returns whether the TwabController has been shutdown at the given timestamp
   * If the twab is queried at or after this time, whether an absolute timestamp or time range, it will return 0.
   * @param timestamp The timestamp to check
   * @param PERIOD_OFFSET The offset of the first period
   * @return True if the TwabController is shutdown at the given timestamp, false otherwise.
   */
  function isShutdownAt(
    uint256 timestamp,
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET
  ) internal pure returns (bool) {
    return timestamp > lastObservationAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Computes the largest timestamp at which the TwabController can record a new observation.
   * @param PERIOD_OFFSET The offset of the first period
   * @return The largest timestamp at which the TwabController can record a new observation.
   */
  function lastObservationAt(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET
  ) internal pure returns (uint256) {
    return uint256(PERIOD_OFFSET) + (type(uint32).max / PERIOD_LENGTH) * PERIOD_LENGTH;
  }

  /**
   * @notice Looks up a users TWAB for a time range. The time must be before the current overwrite period.
   * @dev If the timestamps in the range are not exact matches of observations, the balance is extrapolated using the previous observation.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @param _startTime The start of the time range
   * @param _endTime The end of the time range
   * @return twab The TWAB for the time range
   */
  function getTwabBetween(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails,
    uint256 _startTime,
    uint256 _endTime
  ) internal view requireFinalized(PERIOD_LENGTH, PERIOD_OFFSET, _endTime) returns (uint256) {
    if (_endTime < _startTime) {
      revert InvalidTimeRange(_startTime, _endTime);
    }

    // if the range extends into the shutdown period, return 0
    if (isShutdownAt(_endTime, PERIOD_LENGTH, PERIOD_OFFSET)) {
      return 0;
    }

    uint256 offsetStartTime = _startTime - PERIOD_OFFSET;
    uint256 offsetEndTime = _endTime - PERIOD_OFFSET;

    ObservationLib.Observation memory endObservation = _getPreviousOrAtObservation(
      _observations,
      _accountDetails,
      PeriodOffsetRelativeTimestamp.wrap(uint32(offsetEndTime))
    );

    if (offsetStartTime == offsetEndTime) {
      return endObservation.balance;
    }

    ObservationLib.Observation memory startObservation = _getPreviousOrAtObservation(
      _observations,
      _accountDetails,
      PeriodOffsetRelativeTimestamp.wrap(uint32(offsetStartTime))
    );

    if (startObservation.timestamp != offsetStartTime) {
      startObservation = _calculateTemporaryObservation(
        startObservation,
        PeriodOffsetRelativeTimestamp.wrap(uint32(offsetStartTime))
      );
    }

    if (endObservation.timestamp != offsetEndTime) {
      endObservation = _calculateTemporaryObservation(
        endObservation,
        PeriodOffsetRelativeTimestamp.wrap(uint32(offsetEndTime))
      );
    }

    // Difference in amount / time
    return
      (endObservation.cumulativeBalance - startObservation.cumulativeBalance) /
      (offsetEndTime - offsetStartTime);
  }

  /**
   * @notice Given an AccountDetails with updated balances, either updates the latest Observation or records a new one
   * @param PERIOD_LENGTH The overwrite period length
   * @param PERIOD_OFFSET The overwrite period offset
   * @param _accountDetails The updated account details
   * @param _account The account to update
   * @return observation The new/updated observation
   * @return isNew Whether or not the observation is new or overwrote a previous one
   * @return newAccountDetails The new account details
   */
  function _recordObservation(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    AccountDetails memory _accountDetails,
    Account storage _account
  )
    internal
    returns (
      ObservationLib.Observation memory observation,
      bool isNew,
      AccountDetails memory newAccountDetails
    )
  {
    PeriodOffsetRelativeTimestamp currentTime = PeriodOffsetRelativeTimestamp.wrap(
      uint32(block.timestamp - PERIOD_OFFSET)
    );

    uint16 nextIndex;
    ObservationLib.Observation memory newestObservation;
    (nextIndex, newestObservation, isNew) = _getNextObservationIndex(
      PERIOD_LENGTH,
      PERIOD_OFFSET,
      _account.observations,
      _accountDetails
    );

    if (isNew) {
      // If the index is new, then we increase the next index to use
      _accountDetails.nextObservationIndex = uint16(
        RingBufferLib.nextIndex(uint256(nextIndex), MAX_CARDINALITY)
      );

      // Prevent the Account specific cardinality from exceeding the MAX_CARDINALITY.
      // The ring buffer length is limited by MAX_CARDINALITY. IF the account.cardinality
      // exceeds the max cardinality, new observations would be incorrectly set or the
      // observation would be out of "bounds" of the ring buffer. Once reached the
      // Account.cardinality will continue to be equal to max cardinality.
      _accountDetails.cardinality = _accountDetails.cardinality < MAX_CARDINALITY
        ? _accountDetails.cardinality + 1
        : MAX_CARDINALITY;
    }

    observation = ObservationLib.Observation({
      cumulativeBalance: _extrapolateFromBalance(newestObservation, currentTime),
      balance: _accountDetails.delegateBalance,
      timestamp: PeriodOffsetRelativeTimestamp.unwrap(currentTime)
    });

    // Write to storage
    _account.observations[nextIndex] = observation;
    newAccountDetails = _accountDetails;
  }

  /**
   * @notice Calculates a temporary observation for a given time using the previous observation.
   * @dev This is used to extrapolate a balance for any given time.
   * @param _observation The previous observation
   * @param _time The time to extrapolate to
   */
  function _calculateTemporaryObservation(
    ObservationLib.Observation memory _observation,
    PeriodOffsetRelativeTimestamp _time
  ) private pure returns (ObservationLib.Observation memory) {
    return
      ObservationLib.Observation({
        cumulativeBalance: _extrapolateFromBalance(_observation, _time),
        balance: _observation.balance,
        timestamp: PeriodOffsetRelativeTimestamp.unwrap(_time)
      });
  }

  /**
   * @notice Looks up the next observation index to write to in the circular buffer.
   * @dev If the current time is in the same period as the newest observation, we overwrite it.
   * @dev If the current time is in a new period, we increment the index and write a new observation.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @return index The index of the next observation slot to overwrite
   * @return newestObservation The newest observation in the circular buffer
   * @return isNew True if the observation slot is new, false if we're overwriting
   */
  function _getNextObservationIndex(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails
  )
    private
    view
    returns (uint16 index, ObservationLib.Observation memory newestObservation, bool isNew)
  {
    uint16 newestIndex;
    (newestIndex, newestObservation) = getNewestObservation(_observations, _accountDetails);

    uint256 currentPeriod = getTimestampPeriod(PERIOD_LENGTH, PERIOD_OFFSET, block.timestamp);

    uint256 newestObservationPeriod = getTimestampPeriod(
      PERIOD_LENGTH,
      PERIOD_OFFSET,
      PERIOD_OFFSET + uint256(newestObservation.timestamp)
    );

    // Create a new Observation if it's the first period or the current time falls within a new period
    if (_accountDetails.cardinality == 0 || currentPeriod > newestObservationPeriod) {
      return (_accountDetails.nextObservationIndex, newestObservation, true);
    }

    // Otherwise, we're overwriting the current newest Observation
    return (newestIndex, newestObservation, false);
  }

  /**
   * @notice Computes the start time of the current overwrite period
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @return The start time of the current overwrite period
   */
  function _currentOverwritePeriodStartedAt(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET
  ) private view returns (uint256) {
    uint256 period = getTimestampPeriod(PERIOD_LENGTH, PERIOD_OFFSET, block.timestamp);
    return getPeriodStartTime(PERIOD_LENGTH, PERIOD_OFFSET, period);
  }

  /**
   * @notice Calculates the next cumulative balance using a provided Observation and timestamp.
   * @param _observation The observation to extrapolate from
   * @param _offsetTimestamp The timestamp to extrapolate to
   * @return cumulativeBalance The cumulative balance at the timestamp
   */
  function _extrapolateFromBalance(
    ObservationLib.Observation memory _observation,
    PeriodOffsetRelativeTimestamp _offsetTimestamp
  ) private pure returns (uint128) {
    // new cumulative balance = provided cumulative balance (or zero) + (current balance * elapsed seconds)
    unchecked {
      return
        uint128(
          uint256(_observation.cumulativeBalance) +
            uint256(_observation.balance) *
            (PeriodOffsetRelativeTimestamp.unwrap(_offsetTimestamp) - _observation.timestamp)
        );
    }
  }

  /**
   * @notice Computes the overwrite period start time given the current time
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @return The start time for the current overwrite period.
   */
  function currentOverwritePeriodStartedAt(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET
  ) internal view returns (uint256) {
    return _currentOverwritePeriodStartedAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Calculates the period a timestamp falls within.
   * @dev Timestamp prior to the PERIOD_OFFSET are considered to be in period 0.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _timestamp The timestamp to calculate the period for
   * @return period The period
   */
  function getTimestampPeriod(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _timestamp
  ) internal pure returns (uint256) {
    if (_timestamp <= PERIOD_OFFSET) {
      return 0;
    }
    return (_timestamp - PERIOD_OFFSET) / uint256(PERIOD_LENGTH);
  }

  /**
   * @notice Calculates the start timestamp for a period
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _period The period to check
   * @return _timestamp The timestamp at which the period starts
   */
  function getPeriodStartTime(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _period
  ) internal pure returns (uint256) {
    return _period * PERIOD_LENGTH + PERIOD_OFFSET;
  }

  /**
   * @notice Calculates the last timestamp for a period
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _period The period to check
   * @return _timestamp The timestamp at which the period ends
   */
  function getPeriodEndTime(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _period
  ) internal pure returns (uint256) {
    return (_period + 1) * PERIOD_LENGTH + PERIOD_OFFSET;
  }

  /**
   * @notice Looks up the newest observation before or at a given timestamp.
   * @dev If an observation is available at the target time, it is returned. Otherwise, the newest observation before the target time is returned.
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @param _targetTime The timestamp to look up
   * @return prevOrAtObservation The observation
   */
  function getPreviousOrAtObservation(
    uint32 PERIOD_OFFSET,
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails,
    uint256 _targetTime
  ) internal view returns (ObservationLib.Observation memory prevOrAtObservation) {
    if (_targetTime < PERIOD_OFFSET) {
      return ObservationLib.Observation({ cumulativeBalance: 0, balance: 0, timestamp: 0 });
    }
    uint256 offsetTargetTime = _targetTime - PERIOD_OFFSET;
    // if this is for an overflowed time period, return 0
    if (offsetTargetTime > type(uint32).max) {
      return
        ObservationLib.Observation({
          cumulativeBalance: 0,
          balance: 0,
          timestamp: type(uint32).max
        });
    }
    prevOrAtObservation = _getPreviousOrAtObservation(
      _observations,
      _accountDetails,
      PeriodOffsetRelativeTimestamp.wrap(uint32(offsetTargetTime))
    );
  }

  /**
   * @notice Looks up the newest observation before or at a given timestamp.
   * @dev If an observation is available at the target time, it is returned. Otherwise, the newest observation before the target time is returned.
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @param _offsetTargetTime The timestamp to look up (offset by the period offset)
   * @return prevOrAtObservation The observation
   */
  function _getPreviousOrAtObservation(
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails,
    PeriodOffsetRelativeTimestamp _offsetTargetTime
  ) private view returns (ObservationLib.Observation memory prevOrAtObservation) {
    // If there are no observations, return a zeroed observation
    if (_accountDetails.cardinality == 0) {
      return ObservationLib.Observation({ cumulativeBalance: 0, balance: 0, timestamp: 0 });
    }

    uint16 oldestTwabIndex;

    (oldestTwabIndex, prevOrAtObservation) = getOldestObservation(_observations, _accountDetails);

    // if the requested time is older than the oldest observation
    if (PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime) < prevOrAtObservation.timestamp) {
      // if the user didn't have any activity prior to the oldest observation, then we know they had a zero balance
      if (_accountDetails.cardinality < MAX_CARDINALITY) {
        return
          ObservationLib.Observation({
            cumulativeBalance: 0,
            balance: 0,
            timestamp: PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime)
          });
      } else {
        // if we are missing their history, we must revert
        revert InsufficientHistory(
          _offsetTargetTime,
          PeriodOffsetRelativeTimestamp.wrap(prevOrAtObservation.timestamp)
        );
      }
    }

    // We know targetTime >= oldestObservation.timestamp because of the above if statement, so we can return here.
    if (_accountDetails.cardinality == 1) {
      return prevOrAtObservation;
    }

    // Find the newest observation
    (
      uint16 newestTwabIndex,
      ObservationLib.Observation memory afterOrAtObservation
    ) = getNewestObservation(_observations, _accountDetails);

    // if the target time is at or after the newest, return it
    if (PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime) >= afterOrAtObservation.timestamp) {
      return afterOrAtObservation;
    }
    // if we know there is only 1 observation older than the newest
    if (_accountDetails.cardinality == 2) {
      return prevOrAtObservation;
    }

    // Otherwise, we perform a binarySearch to find the observation before or at the timestamp
    (prevOrAtObservation, oldestTwabIndex, afterOrAtObservation, newestTwabIndex) = ObservationLib
      .binarySearch(
        _observations,
        newestTwabIndex,
        oldestTwabIndex,
        PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime),
        _accountDetails.cardinality
      );

    // If the afterOrAt is at, we can skip a temporary Observation computation by returning it here
    if (afterOrAtObservation.timestamp == PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime)) {
      return afterOrAtObservation;
    }

    return prevOrAtObservation;
  }

  /**
   * @notice Checks if the given timestamp is safe to perform a historic balance lookup on.
   * @dev A timestamp is safe if it is before the current overwrite period
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _time The timestamp to check
   * @return isSafe Whether or not the timestamp is safe
   */
  function hasFinalized(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _time
  ) internal view returns (bool) {
    return _hasFinalized(PERIOD_LENGTH, PERIOD_OFFSET, _time);
  }

  /**
   * @notice Checks if the given timestamp is safe to perform a historic balance lookup on.
   * @dev A timestamp is safe if it is on or before the current overwrite period start time
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _time The timestamp to check
   * @return isSafe Whether or not the timestamp is safe
   */
  function _hasFinalized(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _time
  ) private view returns (bool) {
    // It's safe if equal to the overwrite period start time, because the cumulative balance won't be impacted
    return _time <= _currentOverwritePeriodStartedAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Checks if the given timestamp is safe to perform a historic balance lookup on.
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _timestamp The timestamp to check
   */
  modifier requireFinalized(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _timestamp
  ) {
    // The current period can still be changed; so the start of the period marks the beginning of unsafe timestamps.
    uint256 overwritePeriodStartTime = _currentOverwritePeriodStartedAt(
      PERIOD_LENGTH,
      PERIOD_OFFSET
    );
    // timestamp == overwritePeriodStartTime doesn't matter, because the cumulative balance won't be impacted
    if (_timestamp > overwritePeriodStartTime) {
      revert TimestampNotFinalized(_timestamp, overwritePeriodStartTime);
    }
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "ring-buffer-lib/RingBufferLib.sol";

/**
 * @dev Sets max ring buffer length in the Account.observations Observation list.
 *         As users transfer/mint/burn tickets new Observation checkpoints are recorded.
 *         The current `MAX_CARDINALITY` guarantees a one year minimum, of accurate historical lookups.
 * @dev The user Account.Account.cardinality parameter can NOT exceed the max cardinality variable.
 *      Preventing "corrupted" ring buffer lookup pointers and new observation checkpoints.
 */
uint16 constant MAX_CARDINALITY = 17520; // with min period of 1 hour, this allows for minimum two years of history

/**
 * @title PoolTogether V5 Observation Library
 * @author PoolTogether Inc. & G9 Software Inc.
 * @notice This library allows one to store an array of timestamped values and efficiently search them.
 * @dev Largely pulled from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/c05a0e2c8c08c460fb4d05cfdda30b3ad8deeaac/contracts/libraries/Oracle.sol
 */
library ObservationLib {
  /**
   * @notice Observation, which includes an amount and timestamp.
   * @param cumulativeBalance the cumulative time-weighted balance at `timestamp`.
   * @param balance `balance` at `timestamp`.
   * @param timestamp Recorded `timestamp`.
   */
  struct Observation {
    uint128 cumulativeBalance;
    uint96 balance;
    uint32 timestamp;
  }

  /**
   * @notice Fetches Observations `beforeOrAt` and `afterOrAt` a `_target`, eg: where [`beforeOrAt`, `afterOrAt`] is satisfied.
   * The result may be the same Observation, or adjacent Observations.
   * @dev The _target must fall within the boundaries of the provided _observations.
   * Meaning the _target must be: older than the most recent Observation and younger, or the same age as, the oldest Observation.
   * @dev  If `_newestObservationIndex` is less than `_oldestObservationIndex`, it means that we've wrapped around the circular buffer.
   *       So the most recent observation will be at `_oldestObservationIndex + _cardinality - 1`, at the beginning of the circular buffer.
   * @param _observations List of Observations to search through.
   * @param _newestObservationIndex Index of the newest Observation. Right side of the circular buffer.
   * @param _oldestObservationIndex Index of the oldest Observation. Left side of the circular buffer.
   * @param _target Timestamp at which we are searching the Observation.
   * @param _cardinality Cardinality of the circular buffer we are searching through.
   * @return beforeOrAt Observation recorded before, or at, the target.
   * @return beforeOrAtIndex Index of observation recorded before, or at, the target.
   * @return afterOrAt Observation recorded at, or after, the target.
   * @return afterOrAtIndex Index of observation recorded at, or after, the target.
   */
  function binarySearch(
    Observation[MAX_CARDINALITY] storage _observations,
    uint24 _newestObservationIndex,
    uint24 _oldestObservationIndex,
    uint32 _target,
    uint16 _cardinality
  )
    internal
    view
    returns (
      Observation memory beforeOrAt,
      uint16 beforeOrAtIndex,
      Observation memory afterOrAt,
      uint16 afterOrAtIndex
    )
  {
    uint256 leftSide = _oldestObservationIndex;
    uint256 rightSide = _newestObservationIndex < leftSide
      ? leftSide + _cardinality - 1
      : _newestObservationIndex;
    uint256 currentIndex;

    while (true) {
      // We start our search in the middle of the `leftSide` and `rightSide`.
      // After each iteration, we narrow down the search to the left or the right side while still starting our search in the middle.
      currentIndex = (leftSide + rightSide) / 2;

      beforeOrAtIndex = uint16(RingBufferLib.wrap(currentIndex, _cardinality));
      beforeOrAt = _observations[beforeOrAtIndex];
      uint32 beforeOrAtTimestamp = beforeOrAt.timestamp;

      afterOrAtIndex = uint16(RingBufferLib.nextIndex(currentIndex, _cardinality));
      afterOrAt = _observations[afterOrAtIndex];

      bool targetAfterOrAt = beforeOrAtTimestamp <= _target;

      // Check if we've found the corresponding Observation.
      if (targetAfterOrAt && _target <= afterOrAt.timestamp) {
        break;
      }

      // If `beforeOrAtTimestamp` is greater than `_target`, then we keep searching lower. To the left of the current index.
      if (!targetAfterOrAt) {
        rightSide = currentIndex - 1;
      } else {
        // Otherwise, we keep searching higher. To the right of the current index.
        leftSide = currentIndex + 1;
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * NOTE: There is a difference in meaning between "cardinality" and "count":
 *  - cardinality is the physical size of the ring buffer (i.e. max elements).
 *  - count is the number of elements in the buffer, which may be less than cardinality.
 */
library RingBufferLib {
    /**
    * @notice Returns wrapped TWAB index.
    * @dev  In order to navigate the TWAB circular buffer, we need to use the modulo operator.
    * @dev  For example, if `_index` is equal to 32 and the TWAB circular buffer is of `_cardinality` 32,
    *       it will return 0 and will point to the first element of the array.
    * @param _index Index used to navigate through the TWAB circular buffer.
    * @param _cardinality TWAB buffer cardinality.
    * @return TWAB index.
    */
    function wrap(uint256 _index, uint256 _cardinality) internal pure returns (uint256) {
        return _index % _cardinality;
    }

    /**
    * @notice Computes the negative offset from the given index, wrapped by the cardinality.
    * @dev  We add `_cardinality` to `_index` to be able to offset even if `_amount` is superior to `_cardinality`.
    * @param _index The index from which to offset
    * @param _amount The number of indices to offset.  This is subtracted from the given index.
    * @param _count The number of elements in the ring buffer
    * @return Offsetted index.
     */
    function offset(
        uint256 _index,
        uint256 _amount,
        uint256 _count
    ) internal pure returns (uint256) {
        return wrap(_index + _count - _amount, _count);
    }

    /// @notice Returns the index of the last recorded TWAB
    /// @param _nextIndex The next available twab index.  This will be recorded to next.
    /// @param _count The count of the TWAB history.
    /// @return The index of the last recorded TWAB
    function newestIndex(uint256 _nextIndex, uint256 _count)
        internal
        pure
        returns (uint256)
    {
        if (_count == 0) {
            return 0;
        }

        return wrap(_nextIndex + _count - 1, _count);
    }

    function oldestIndex(uint256 _nextIndex, uint256 _count, uint256 _cardinality)
        internal
        pure
        returns (uint256)
    {
        if (_count < _cardinality) {
            return 0;
        } else {
            return wrap(_nextIndex + _cardinality, _cardinality);
        }
    }

    /// @notice Computes the ring buffer index that follows the given one, wrapped by cardinality
    /// @param _index The index to increment
    /// @param _cardinality The number of elements in the Ring Buffer
    /// @return The next index relative to the given index.  Will wrap around to 0 if the next index == cardinality
    function nextIndex(uint256 _index, uint256 _cardinality)
        internal
        pure
        returns (uint256)
    {
        return wrap(_index + 1, _cardinality);
    }

    /// @notice Computes the ring buffer index that preceeds the given one, wrapped by cardinality
    /// @param _index The index to increment
    /// @param _cardinality The number of elements in the Ring Buffer
    /// @return The prev index relative to the given index.  Will wrap around to the end if the prev index == 0
    function prevIndex(uint256 _index, uint256 _cardinality)
    internal
    pure
    returns (uint256) 
    {
        return _index == 0 ? _cardinality - 1 : _index - 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/*

██████╗ ██████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗  ██╗
██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
██████╔╝██████╔╝██████╔╝██╔████╔██║███████║   ██║   ███████║
██╔═══╝ ██╔══██╗██╔══██╗██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
██║     ██║  ██║██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝

██╗   ██╗██████╗  ██████╗  ██████╗ ██╗  ██╗ ██╗ █████╗
██║   ██║██╔══██╗██╔════╝ ██╔═████╗╚██╗██╔╝███║██╔══██╗
██║   ██║██║  ██║███████╗ ██║██╔██║ ╚███╔╝ ╚██║╚█████╔╝
██║   ██║██║  ██║██╔═══██╗████╔╝██║ ██╔██╗  ██║██╔══██╗
╚██████╔╝██████╔╝╚██████╔╝╚██████╔╝██╔╝ ██╗ ██║╚█████╔╝
 ╚═════╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═╝ ╚════╝

*/

import "./ud60x18/Casting.sol";
import "./ud60x18/Constants.sol";
import "./ud60x18/Conversions.sol";
import "./ud60x18/Errors.sol";
import "./ud60x18/Helpers.sol";
import "./ud60x18/Math.sol";
import "./ud60x18/ValueType.sol";

/**
Copyright 2019 PoolTogether LLC

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity ^0.8.19;

error UpperBoundGtZero();

/**
 * @author Brendan Asselstine
 * @notice A library that uses entropy to select a random number within a bound.  Compensates for modulo bias.
 * @dev Thanks to https://medium.com/hownetworks/dont-waste-cycles-with-modulo-bias-35b6fdafcf94
 */
library UniformRandomNumber {
  /// @notice Select a random number without modulo bias using a random seed and upper bound
  /// @param _entropy The seed for randomness
  /// @param _upperBound The upper bound of the desired number
  /// @return A random number less than the _upperBound
  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
    if(_upperBound == 0) {
        revert UpperBoundGtZero();
    }
    uint256 min = (type(uint256).max-_upperBound+1) % _upperBound;
    uint256 random = _entropy;
    while (true) {
      if (random >= min) {
        break;
      }
      random = uint256(keccak256(abi.encodePacked(random)));
    }
    return random % _upperBound;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title  PoolTogether V5 Claimable Interface
 * @author G9 Software Inc.
 * @notice Provides a concise and consistent interface for Claimer contracts to interact with Vaults
 * in PoolTogether V5.
 */
interface IClaimable {
  /**
   * @notice Emitted when a new claimer has been set
   * @dev This event MUST be emitted when a new claimer has been set.
   * @param claimer Address of the new claimer
   */
  event ClaimerSet(address indexed claimer);

  /**
   * @notice Claim a prize for a winner
   * @param _winner The winner of the prize
   * @param _tier The prize tier
   * @param _prizeIndex The prize index
   * @param _reward The reward to allocate to the reward recipient, in prize tokens
   * @param _rewardRecipient The recipient of the reward
   * @return The total prize token amount claimed (zero if already claimed)
   */
  function claimPrize(
    address _winner,
    uint8 _tier,
    uint32 _prizeIndex,
    uint96 _reward,
    address _rewardRecipient
  ) external returns (uint256);

  /**
   * @notice Gets the current address that can call `claimPrize`.
   * @return The claimer address
   */
  function claimer() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { PrizeHooks } from "../interfaces/IPrizeHooks.sol";

/// @title  PoolTogether V5 HookManager
/// @author G9 Software Inc.
/// @notice Allows each account to set and manage prize hooks that can be called when they win.
abstract contract HookManager {

    /// @notice Emitted when an account sets new hooks
    /// @param account The account whose hooks are being configured
    /// @param hooks The hooks being set
    event SetHooks(address indexed account, PrizeHooks hooks);

    /// @notice Maps user addresses to hooks that they want to execute when prizes are won.
    mapping(address => PrizeHooks) internal _hooks;

    /// @notice Gets the hooks for the given account.
    /// @param account The account to retrieve the hooks for
    /// @return PrizeHooks The hooks for the given account
    function getHooks(address account) external view returns (PrizeHooks memory) {
        return _hooks[account];
    }

    /// @notice Sets the hooks for a winner.
    /// @dev Emits a `SetHooks` event
    /// @param hooks The hooks to set
    function setHooks(PrizeHooks calldata hooks) external {
        _hooks[msg.sender] = hooks;
        emit SetHooks(msg.sender, hooks);
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @inheritdoc IERC20Permit
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @inheritdoc IERC20Permit
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

// Common.sol
//
// Common mathematical functions used in both SD59x18 and UD60x18. Note that these global functions do not
// always operate with SD59x18 and UD60x18 numbers.

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Thrown when the resultant value in {mulDiv} overflows uint256.
error PRBMath_MulDiv_Overflow(uint256 x, uint256 y, uint256 denominator);

/// @notice Thrown when the resultant value in {mulDiv18} overflows uint256.
error PRBMath_MulDiv18_Overflow(uint256 x, uint256 y);

/// @notice Thrown when one of the inputs passed to {mulDivSigned} is `type(int256).min`.
error PRBMath_MulDivSigned_InputTooSmall();

/// @notice Thrown when the resultant value in {mulDivSigned} overflows int256.
error PRBMath_MulDivSigned_Overflow(int256 x, int256 y);

/*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

/// @dev The maximum value a uint128 number can have.
uint128 constant MAX_UINT128 = type(uint128).max;

/// @dev The maximum value a uint40 number can have.
uint40 constant MAX_UINT40 = type(uint40).max;

/// @dev The unit number, which the decimal precision of the fixed-point types.
uint256 constant UNIT = 1e18;

/// @dev The unit number inverted mod 2^256.
uint256 constant UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

/// @dev The the largest power of two that divides the decimal value of `UNIT`. The logarithm of this value is the least significant
/// bit in the binary representation of `UNIT`.
uint256 constant UNIT_LPOTD = 262144;

/*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Calculates the binary exponent of x using the binary fraction method.
/// @dev Has to use 192.64-bit fixed-point numbers. See https://ethereum.stackexchange.com/a/96594/24693.
/// @param x The exponent as an unsigned 192.64-bit fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
/// @custom:smtchecker abstract-function-nondet
function exp2(uint256 x) pure returns (uint256 result) {
    unchecked {
        // Start from 0.5 in the 192.64-bit fixed-point format.
        result = 0x800000000000000000000000000000000000000000000000;

        // The following logic multiplies the result by $\sqrt{2^{-i}}$ when the bit at position i is 1. Key points:
        //
        // 1. Intermediate results will not overflow, as the starting point is 2^191 and all magic factors are under 2^65.
        // 2. The rationale for organizing the if statements into groups of 8 is gas savings. If the result of performing
        // a bitwise AND operation between x and any value in the array [0x80; 0x40; 0x20; 0x10; 0x08; 0x04; 0x02; 0x01] is 1,
        // we know that `x & 0xFF` is also 1.
        if (x & 0xFF00000000000000 > 0) {
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
        }

        if (x & 0xFF000000000000 > 0) {
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
        }

        if (x & 0xFF0000000000 > 0) {
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
        }

        if (x & 0xFF00000000 > 0) {
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
        }

        if (x & 0xFF000000 > 0) {
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
        }

        if (x & 0xFF0000 > 0) {
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
        }

        if (x & 0xFF00 > 0) {
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
        }

        if (x & 0xFF > 0) {
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
        }

        // In the code snippet below, two operations are executed simultaneously:
        //
        // 1. The result is multiplied by $(2^n + 1)$, where $2^n$ represents the integer part, and the additional 1
        // accounts for the initial guess of 0.5. This is achieved by subtracting from 191 instead of 192.
        // 2. The result is then converted to an unsigned 60.18-decimal fixed-point format.
        //
        // The underlying logic is based on the relationship $2^{191-ip} = 2^{ip} / 2^{191}$, where $ip$ denotes the,
        // integer part, $2^n$.
        result *= UNIT;
        result >>= (191 - (x >> 64));
    }
}

/// @notice Finds the zero-based index of the first 1 in the binary representation of x.
///
/// @dev See the note on "msb" in this Wikipedia article: https://en.wikipedia.org/wiki/Find_first_set
///
/// Each step in this implementation is equivalent to this high-level code:
///
/// ```solidity
/// if (x >= 2 ** 128) {
///     x >>= 128;
///     result += 128;
/// }
/// ```
///
/// Where 128 is replaced with each respective power of two factor. See the full high-level implementation here:
/// https://gist.github.com/PaulRBerg/f932f8693f2733e30c4d479e8e980948
///
/// The Yul instructions used below are:
///
/// - "gt" is "greater than"
/// - "or" is the OR bitwise operator
/// - "shl" is "shift left"
/// - "shr" is "shift right"
///
/// @param x The uint256 number for which to find the index of the most significant bit.
/// @return result The index of the most significant bit as a uint256.
/// @custom:smtchecker abstract-function-nondet
function msb(uint256 x) pure returns (uint256 result) {
    // 2^128
    assembly ("memory-safe") {
        let factor := shl(7, gt(x, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^64
    assembly ("memory-safe") {
        let factor := shl(6, gt(x, 0xFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^32
    assembly ("memory-safe") {
        let factor := shl(5, gt(x, 0xFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^16
    assembly ("memory-safe") {
        let factor := shl(4, gt(x, 0xFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^8
    assembly ("memory-safe") {
        let factor := shl(3, gt(x, 0xFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^4
    assembly ("memory-safe") {
        let factor := shl(2, gt(x, 0xF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^2
    assembly ("memory-safe") {
        let factor := shl(1, gt(x, 0x3))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^1
    // No need to shift x any more.
    assembly ("memory-safe") {
        let factor := gt(x, 0x1)
        result := or(result, factor)
    }
}

/// @notice Calculates x*y÷denominator with 512-bit precision.
///
/// @dev Credits to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
///
/// Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - The denominator must not be zero.
/// - The result must fit in uint256.
///
/// @param x The multiplicand as a uint256.
/// @param y The multiplier as a uint256.
/// @param denominator The divisor as a uint256.
/// @return result The result as a uint256.
/// @custom:smtchecker abstract-function-nondet
function mulDiv(uint256 x, uint256 y, uint256 denominator) pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512-bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
        unchecked {
            return prod0 / denominator;
        }
    }

    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    if (prod1 >= denominator) {
        revert PRBMath_MulDiv_Overflow(x, y, denominator);
    }

    ////////////////////////////////////////////////////////////////////////////
    // 512 by 256 division
    ////////////////////////////////////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly ("memory-safe") {
        // Compute remainder using the mulmod Yul instruction.
        remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512-bit number.
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
    }

    unchecked {
        // Calculate the largest power of two divisor of the denominator using the unary operator ~. This operation cannot overflow
        // because the denominator cannot be zero at this point in the function execution. The result is always >= 1.
        // For more detail, see https://cs.stackexchange.com/q/138556/92363.
        uint256 lpotdod = denominator & (~denominator + 1);
        uint256 flippedLpotdod;

        assembly ("memory-safe") {
            // Factor powers of two out of denominator.
            denominator := div(denominator, lpotdod)

            // Divide [prod1 prod0] by lpotdod.
            prod0 := div(prod0, lpotdod)

            // Get the flipped value `2^256 / lpotdod`. If the `lpotdod` is zero, the flipped value is one.
            // `sub(0, lpotdod)` produces the two's complement version of `lpotdod`, which is equivalent to flipping all the bits.
            // However, `div` interprets this value as an unsigned value: https://ethereum.stackexchange.com/q/147168/24693
            flippedLpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
        }

        // Shift in bits from prod1 into prod0.
        prod0 |= prod1 * flippedLpotdod;

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
    }
}

/// @notice Calculates x*y÷1e18 with 512-bit precision.
///
/// @dev A variant of {mulDiv} with constant folding, i.e. in which the denominator is hard coded to 1e18.
///
/// Notes:
/// - The body is purposely left uncommented; to understand how this works, see the documentation in {mulDiv}.
/// - The result is rounded toward zero.
/// - We take as an axiom that the result cannot be `MAX_UINT256` when x and y solve the following system of equations:
///
/// $$
/// \begin{cases}
///     x * y = MAX\_UINT256 * UNIT \\
///     (x * y) \% UNIT \geq \frac{UNIT}{2}
/// \end{cases}
/// $$
///
/// Requirements:
/// - Refer to the requirements in {mulDiv}.
/// - The result must fit in uint256.
///
/// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
/// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
/// @custom:smtchecker abstract-function-nondet
function mulDiv18(uint256 x, uint256 y) pure returns (uint256 result) {
    uint256 prod0;
    uint256 prod1;
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    if (prod1 == 0) {
        unchecked {
            return prod0 / UNIT;
        }
    }

    if (prod1 >= UNIT) {
        revert PRBMath_MulDiv18_Overflow(x, y);
    }

    uint256 remainder;
    assembly ("memory-safe") {
        remainder := mulmod(x, y, UNIT)
        result :=
            mul(
                or(
                    div(sub(prod0, remainder), UNIT_LPOTD),
                    mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, UNIT_LPOTD), UNIT_LPOTD), 1))
                ),
                UNIT_INVERSE
            )
    }
}

/// @notice Calculates x*y÷denominator with 512-bit precision.
///
/// @dev This is an extension of {mulDiv} for signed numbers, which works by computing the signs and the absolute values separately.
///
/// Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - Refer to the requirements in {mulDiv}.
/// - None of the inputs can be `type(int256).min`.
/// - The result must fit in int256.
///
/// @param x The multiplicand as an int256.
/// @param y The multiplier as an int256.
/// @param denominator The divisor as an int256.
/// @return result The result as an int256.
/// @custom:smtchecker abstract-function-nondet
function mulDivSigned(int256 x, int256 y, int256 denominator) pure returns (int256 result) {
    if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
        revert PRBMath_MulDivSigned_InputTooSmall();
    }

    // Get hold of the absolute values of x, y and the denominator.
    uint256 xAbs;
    uint256 yAbs;
    uint256 dAbs;
    unchecked {
        xAbs = x < 0 ? uint256(-x) : uint256(x);
        yAbs = y < 0 ? uint256(-y) : uint256(y);
        dAbs = denominator < 0 ? uint256(-denominator) : uint256(denominator);
    }

    // Compute the absolute value of x*y÷denominator. The result must fit in int256.
    uint256 resultAbs = mulDiv(xAbs, yAbs, dAbs);
    if (resultAbs > uint256(type(int256).max)) {
        revert PRBMath_MulDivSigned_Overflow(x, y);
    }

    // Get the signs of x, y and the denominator.
    uint256 sx;
    uint256 sy;
    uint256 sd;
    assembly ("memory-safe") {
        // "sgt" is the "signed greater than" assembly instruction and "sub(0,1)" is -1 in two's complement.
        sx := sgt(x, sub(0, 1))
        sy := sgt(y, sub(0, 1))
        sd := sgt(denominator, sub(0, 1))
    }

    // XOR over sx, sy and sd. What this does is to check whether there are 1 or 3 negative signs in the inputs.
    // If there are, the result should be negative. Otherwise, it should be positive.
    unchecked {
        result = sx ^ sy ^ sd == 0 ? -int256(resultAbs) : int256(resultAbs);
    }
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - If x is not a perfect square, the result is rounded down.
/// - Credits to OpenZeppelin for the explanations in comments below.
///
/// @param x The uint256 number for which to calculate the square root.
/// @return result The result as a uint256.
/// @custom:smtchecker abstract-function-nondet
function sqrt(uint256 x) pure returns (uint256 result) {
    if (x == 0) {
        return 0;
    }

    // For our first guess, we calculate the biggest power of 2 which is smaller than the square root of x.
    //
    // We know that the "msb" (most significant bit) of x is a power of 2 such that we have:
    //
    // $$
    // msb(x) <= x <= 2*msb(x)$
    // $$
    //
    // We write $msb(x)$ as $2^k$, and we get:
    //
    // $$
    // k = log_2(x)
    // $$
    //
    // Thus, we can write the initial inequality as:
    //
    // $$
    // 2^{log_2(x)} <= x <= 2*2^{log_2(x)+1} \\
    // sqrt(2^k) <= sqrt(x) < sqrt(2^{k+1}) \\
    // 2^{k/2} <= sqrt(x) < 2^{(k+1)/2} <= 2^{(k/2)+1}
    // $$
    //
    // Consequently, $2^{log_2(x) /2} is a good first approximation of sqrt(x) with at least one correct bit.
    uint256 xAux = uint256(x);
    result = 1;
    if (xAux >= 2 ** 128) {
        xAux >>= 128;
        result <<= 64;
    }
    if (xAux >= 2 ** 64) {
        xAux >>= 64;
        result <<= 32;
    }
    if (xAux >= 2 ** 32) {
        xAux >>= 32;
        result <<= 16;
    }
    if (xAux >= 2 ** 16) {
        xAux >>= 16;
        result <<= 8;
    }
    if (xAux >= 2 ** 8) {
        xAux >>= 8;
        result <<= 4;
    }
    if (xAux >= 2 ** 4) {
        xAux >>= 4;
        result <<= 2;
    }
    if (xAux >= 2 ** 2) {
        result <<= 1;
    }

    // At this point, `result` is an estimation with at least one bit of precision. We know the true value has at
    // most 128 bits, since it is the square root of a uint256. Newton's method converges quadratically (precision
    // doubles at every iteration). We thus need at most 7 iteration to turn our partial result with one bit of
    // precision into the expected uint128 result.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;

        // If x is not a perfect square, round the result toward zero.
        uint256 roundedResult = x / result;
        if (result >= roundedResult) {
            result = roundedResult;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD2x18 } from "./ValueType.sol";

/// @dev Euler's number as a UD2x18 number.
UD2x18 constant E = UD2x18.wrap(2_718281828459045235);

/// @dev The maximum value a UD2x18 number can have.
uint64 constant uMAX_UD2x18 = 18_446744073709551615;
UD2x18 constant MAX_UD2x18 = UD2x18.wrap(uMAX_UD2x18);

/// @dev PI as a UD2x18 number.
UD2x18 constant PI = UD2x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of UD2x18.
uint256 constant uUNIT = 1e18;
UD2x18 constant UNIT = UD2x18.wrap(1e18);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;

/// @notice The unsigned 2.18-decimal fixed-point number representation, which can have up to 2 digits and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity
/// type uint64. This is useful when end users want to use uint64 to save gas, e.g. with tight variable packing in contract
/// storage.
type UD2x18 is uint64;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoSD1x18,
    Casting.intoSD59x18,
    Casting.intoUD60x18,
    Casting.intoUint256,
    Casting.intoUint128,
    Casting.intoUint40,
    Casting.unwrap
} for UD2x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Casting.sol" as Casting;
import "./Helpers.sol" as Helpers;
import "./Math.sol" as Math;

/// @notice The unsigned 60.18-decimal fixed-point number representation, which can have up to 60 digits and up to 18
/// decimals. The values of this are bound by the minimum and the maximum values permitted by the Solidity type uint256.
/// @dev The value type is defined here so it can be imported in all other files.
type UD60x18 is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    Casting.intoSD1x18,
    Casting.intoUD2x18,
    Casting.intoSD59x18,
    Casting.intoUint128,
    Casting.intoUint256,
    Casting.intoUint40,
    Casting.unwrap
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes the functions in this library callable on the UD60x18 type.
using {
    Math.avg,
    Math.ceil,
    Math.div,
    Math.exp,
    Math.exp2,
    Math.floor,
    Math.frac,
    Math.gm,
    Math.inv,
    Math.ln,
    Math.log10,
    Math.log2,
    Math.mul,
    Math.pow,
    Math.powu,
    Math.sqrt
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes the functions in this library callable on the UD60x18 type.
using {
    Helpers.add,
    Helpers.and,
    Helpers.eq,
    Helpers.gt,
    Helpers.gte,
    Helpers.isZero,
    Helpers.lshift,
    Helpers.lt,
    Helpers.lte,
    Helpers.mod,
    Helpers.neq,
    Helpers.not,
    Helpers.or,
    Helpers.rshift,
    Helpers.sub,
    Helpers.uncheckedAdd,
    Helpers.uncheckedSub,
    Helpers.xor
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                    OPERATORS
//////////////////////////////////////////////////////////////////////////*/

// The global "using for" directive makes it possible to use these operators on the UD60x18 type.
using {
    Helpers.add as +,
    Helpers.and2 as &,
    Math.div as /,
    Helpers.eq as ==,
    Helpers.gt as >,
    Helpers.gte as >=,
    Helpers.lt as <,
    Helpers.lte as <=,
    Helpers.or as |,
    Helpers.mod as %,
    Math.mul as *,
    Helpers.neq as !=,
    Helpers.not as ~,
    Helpers.sub as -,
    Helpers.xor as ^
} for UD60x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Errors.sol" as CastingErrors;
import { MAX_UINT128, MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { uMAX_SD59x18 } from "../sd59x18/Constants.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { uMAX_UD2x18 } from "../ud2x18/Constants.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Casts a UD60x18 number into SD1x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(UD60x18 x) pure returns (SD1x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uint256(int256(uMAX_SD1x18))) {
        revert CastingErrors.PRBMath_UD60x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(uint64(xUint)));
}

/// @notice Casts a UD60x18 number into UD2x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_UD2x18`.
function intoUD2x18(UD60x18 x) pure returns (UD2x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uMAX_UD2x18) {
        revert CastingErrors.PRBMath_UD60x18_IntoUD2x18_Overflow(x);
    }
    result = UD2x18.wrap(uint64(xUint));
}

/// @notice Casts a UD60x18 number into SD59x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD59x18`.
function intoSD59x18(UD60x18 x) pure returns (SD59x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uint256(uMAX_SD59x18)) {
        revert CastingErrors.PRBMath_UD60x18_IntoSD59x18_Overflow(x);
    }
    result = SD59x18.wrap(int256(xUint));
}

/// @notice Casts a UD60x18 number into uint128.
/// @dev This is basically an alias for {unwrap}.
function intoUint256(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Casts a UD60x18 number into uint128.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT128`.
function intoUint128(UD60x18 x) pure returns (uint128 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > MAX_UINT128) {
        revert CastingErrors.PRBMath_UD60x18_IntoUint128_Overflow(x);
    }
    result = uint128(xUint);
}

/// @notice Casts a UD60x18 number into uint40.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(UD60x18 x) pure returns (uint40 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > MAX_UINT40) {
        revert CastingErrors.PRBMath_UD60x18_IntoUint40_Overflow(x);
    }
    result = uint40(xUint);
}

/// @notice Alias for {wrap}.
function ud(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

/// @notice Alias for {wrap}.
function ud60x18(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

/// @notice Unwraps a UD60x18 number into uint256.
function unwrap(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Wraps a uint256 number into the UD60x18 value type.
function wrap(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD60x18 } from "./ValueType.sol";

// NOTICE: the "u" prefix stands for "unwrapped".

/// @dev Euler's number as a UD60x18 number.
UD60x18 constant E = UD60x18.wrap(2_718281828459045235);

/// @dev The maximum input permitted in {exp}.
uint256 constant uEXP_MAX_INPUT = 133_084258667509499440;
UD60x18 constant EXP_MAX_INPUT = UD60x18.wrap(uEXP_MAX_INPUT);

/// @dev The maximum input permitted in {exp2}.
uint256 constant uEXP2_MAX_INPUT = 192e18 - 1;
UD60x18 constant EXP2_MAX_INPUT = UD60x18.wrap(uEXP2_MAX_INPUT);

/// @dev Half the UNIT number.
uint256 constant uHALF_UNIT = 0.5e18;
UD60x18 constant HALF_UNIT = UD60x18.wrap(uHALF_UNIT);

/// @dev $log_2(10)$ as a UD60x18 number.
uint256 constant uLOG2_10 = 3_321928094887362347;
UD60x18 constant LOG2_10 = UD60x18.wrap(uLOG2_10);

/// @dev $log_2(e)$ as a UD60x18 number.
uint256 constant uLOG2_E = 1_442695040888963407;
UD60x18 constant LOG2_E = UD60x18.wrap(uLOG2_E);

/// @dev The maximum value a UD60x18 number can have.
uint256 constant uMAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_584007913129639935;
UD60x18 constant MAX_UD60x18 = UD60x18.wrap(uMAX_UD60x18);

/// @dev The maximum whole value a UD60x18 number can have.
uint256 constant uMAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_000000000000000000;
UD60x18 constant MAX_WHOLE_UD60x18 = UD60x18.wrap(uMAX_WHOLE_UD60x18);

/// @dev PI as a UD60x18 number.
UD60x18 constant PI = UD60x18.wrap(3_141592653589793238);

/// @dev The unit number, which gives the decimal precision of UD60x18.
uint256 constant uUNIT = 1e18;
UD60x18 constant UNIT = UD60x18.wrap(uUNIT);

/// @dev The unit number squared.
uint256 constant uUNIT_SQUARED = 1e36;
UD60x18 constant UNIT_SQUARED = UD60x18.wrap(uUNIT_SQUARED);

/// @dev Zero as a UD60x18 number.
UD60x18 constant ZERO = UD60x18.wrap(0);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { uMAX_UD60x18, uUNIT } from "./Constants.sol";
import { PRBMath_UD60x18_Convert_Overflow } from "./Errors.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Converts a UD60x18 number to a simple integer by dividing it by `UNIT`.
/// @dev The result is rounded toward zero.
/// @param x The UD60x18 number to convert.
/// @return result The same number in basic integer form.
function convert(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x) / uUNIT;
}

/// @notice Converts a simple integer to UD60x18 by multiplying it by `UNIT`.
///
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UD60x18 / UNIT`.
///
/// @param x The basic integer to convert.
/// @param result The same number converted to UD60x18.
function convert(uint256 x) pure returns (UD60x18 result) {
    if (x > uMAX_UD60x18 / uUNIT) {
        revert PRBMath_UD60x18_Convert_Overflow(x);
    }
    unchecked {
        result = UD60x18.wrap(x * uUNIT);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD60x18 } from "./ValueType.sol";

/// @notice Thrown when ceiling a number overflows UD60x18.
error PRBMath_UD60x18_Ceil_Overflow(UD60x18 x);

/// @notice Thrown when converting a basic integer to the fixed-point format overflows UD60x18.
error PRBMath_UD60x18_Convert_Overflow(uint256 x);

/// @notice Thrown when taking the natural exponent of a base greater than 133_084258667509499441.
error PRBMath_UD60x18_Exp_InputTooBig(UD60x18 x);

/// @notice Thrown when taking the binary exponent of a base greater than 192e18.
error PRBMath_UD60x18_Exp2_InputTooBig(UD60x18 x);

/// @notice Thrown when taking the geometric mean of two numbers and multiplying them overflows UD60x18.
error PRBMath_UD60x18_Gm_Overflow(UD60x18 x, UD60x18 y);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.
error PRBMath_UD60x18_IntoSD1x18_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in SD59x18.
error PRBMath_UD60x18_IntoSD59x18_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.
error PRBMath_UD60x18_IntoUD2x18_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.
error PRBMath_UD60x18_IntoUint128_Overflow(UD60x18 x);

/// @notice Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.
error PRBMath_UD60x18_IntoUint40_Overflow(UD60x18 x);

/// @notice Thrown when taking the logarithm of a number less than 1.
error PRBMath_UD60x18_Log_InputTooSmall(UD60x18 x);

/// @notice Thrown when calculating the square root overflows UD60x18.
error PRBMath_UD60x18_Sqrt_Overflow(UD60x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { wrap } from "./Casting.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Implements the checked addition operation (+) in the UD60x18 type.
function add(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() + y.unwrap());
}

/// @notice Implements the AND (&) bitwise operation in the UD60x18 type.
function and(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() & bits);
}

/// @notice Implements the AND (&) bitwise operation in the UD60x18 type.
function and2(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() & y.unwrap());
}

/// @notice Implements the equal operation (==) in the UD60x18 type.
function eq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() == y.unwrap();
}

/// @notice Implements the greater than operation (>) in the UD60x18 type.
function gt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() > y.unwrap();
}

/// @notice Implements the greater than or equal to operation (>=) in the UD60x18 type.
function gte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() >= y.unwrap();
}

/// @notice Implements a zero comparison check function in the UD60x18 type.
function isZero(UD60x18 x) pure returns (bool result) {
    // This wouldn't work if x could be negative.
    result = x.unwrap() == 0;
}

/// @notice Implements the left shift operation (<<) in the UD60x18 type.
function lshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() << bits);
}

/// @notice Implements the lower than operation (<) in the UD60x18 type.
function lt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() < y.unwrap();
}

/// @notice Implements the lower than or equal to operation (<=) in the UD60x18 type.
function lte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() <= y.unwrap();
}

/// @notice Implements the checked modulo operation (%) in the UD60x18 type.
function mod(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() % y.unwrap());
}

/// @notice Implements the not equal operation (!=) in the UD60x18 type.
function neq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = x.unwrap() != y.unwrap();
}

/// @notice Implements the NOT (~) bitwise operation in the UD60x18 type.
function not(UD60x18 x) pure returns (UD60x18 result) {
    result = wrap(~x.unwrap());
}

/// @notice Implements the OR (|) bitwise operation in the UD60x18 type.
function or(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() | y.unwrap());
}

/// @notice Implements the right shift operation (>>) in the UD60x18 type.
function rshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the UD60x18 type.
function sub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() - y.unwrap());
}

/// @notice Implements the unchecked addition operation (+) in the UD60x18 type.
function uncheckedAdd(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(x.unwrap() + y.unwrap());
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the UD60x18 type.
function uncheckedSub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(x.unwrap() - y.unwrap());
    }
}

/// @notice Implements the XOR (^) bitwise operation in the UD60x18 type.
function xor(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(x.unwrap() ^ y.unwrap());
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as Errors;
import { wrap } from "./Casting.sol";
import {
    uEXP_MAX_INPUT,
    uEXP2_MAX_INPUT,
    uHALF_UNIT,
    uLOG2_10,
    uLOG2_E,
    uMAX_UD60x18,
    uMAX_WHOLE_UD60x18,
    UNIT,
    uUNIT,
    uUNIT_SQUARED,
    ZERO
} from "./Constants.sol";
import { UD60x18 } from "./ValueType.sol";

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Calculates the arithmetic average of x and y using the following formula:
///
/// $$
/// avg(x, y) = (x & y) + ((xUint ^ yUint) / 2)
/// $$
///
/// In English, this is what this formula does:
///
/// 1. AND x and y.
/// 2. Calculate half of XOR x and y.
/// 3. Add the two results together.
///
/// This technique is known as SWAR, which stands for "SIMD within a register". You can read more about it here:
/// https://devblogs.microsoft.com/oldnewthing/20220207-00/?p=106223
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// @param x The first operand as a UD60x18 number.
/// @param y The second operand as a UD60x18 number.
/// @return result The arithmetic average as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function avg(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();
    unchecked {
        result = wrap((xUint & yUint) + ((xUint ^ yUint) >> 1));
    }
}

/// @notice Yields the smallest whole number greater than or equal to x.
///
/// @dev This is optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional
/// counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_UD60x18`.
///
/// @param x The UD60x18 number to ceil.
/// @param result The smallest whole number greater than or equal to x, as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function ceil(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    if (xUint > uMAX_WHOLE_UD60x18) {
        revert Errors.PRBMath_UD60x18_Ceil_Overflow(x);
    }

    assembly ("memory-safe") {
        // Equivalent to `x % UNIT`.
        let remainder := mod(x, uUNIT)

        // Equivalent to `UNIT - remainder`.
        let delta := sub(uUNIT, remainder)

        // Equivalent to `x + remainder > 0 ? delta : 0`.
        result := add(x, mul(delta, gt(remainder, 0)))
    }
}

/// @notice Divides two UD60x18 numbers, returning a new UD60x18 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @param x The numerator as a UD60x18 number.
/// @param y The denominator as a UD60x18 number.
/// @param result The quotient as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function div(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(Common.mulDiv(x.unwrap(), uUNIT, y.unwrap()));
}

/// @notice Calculates the natural exponent of x using the following formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// @dev Requirements:
/// - x must be less than 133_084258667509499441.
///
/// @param x The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    // This check prevents values greater than 192e18 from being passed to {exp2}.
    if (xUint > uEXP_MAX_INPUT) {
        revert Errors.PRBMath_UD60x18_Exp_InputTooBig(x);
    }

    unchecked {
        // Inline the fixed-point multiplication to save gas.
        uint256 doubleUnitProduct = xUint * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
///
/// @dev See https://ethereum.stackexchange.com/q/79903/24693
///
/// Requirements:
/// - x must be less than 192e18.
/// - The result must fit in UD60x18.
///
/// @param x The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    // Numbers greater than or equal to 192e18 don't fit in the 192.64-bit format.
    if (xUint > uEXP2_MAX_INPUT) {
        revert Errors.PRBMath_UD60x18_Exp2_InputTooBig(x);
    }

    // Convert x to the 192.64-bit fixed-point format.
    uint256 x_192x64 = (xUint << 64) / uUNIT;

    // Pass x to the {Common.exp2} function, which uses the 192.64-bit fixed-point number representation.
    result = wrap(Common.exp2(x_192x64));
}

/// @notice Yields the greatest whole number less than or equal to x.
/// @dev Optimized for fractional value inputs, because every whole value has (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
/// @param x The UD60x18 number to floor.
/// @param result The greatest whole number less than or equal to x, as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function floor(UD60x18 x) pure returns (UD60x18 result) {
    assembly ("memory-safe") {
        // Equivalent to `x % UNIT`.
        let remainder := mod(x, uUNIT)

        // Equivalent to `x - remainder > 0 ? remainder : 0)`.
        result := sub(x, mul(remainder, gt(remainder, 0)))
    }
}

/// @notice Yields the excess beyond the floor of x using the odd function definition.
/// @dev See https://en.wikipedia.org/wiki/Fractional_part.
/// @param x The UD60x18 number to get the fractional part of.
/// @param result The fractional part of x as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function frac(UD60x18 x) pure returns (UD60x18 result) {
    assembly ("memory-safe") {
        result := mod(x, uUNIT)
    }
}

/// @notice Calculates the geometric mean of x and y, i.e. $\sqrt{x * y}$, rounding down.
///
/// @dev Requirements:
/// - x * y must fit in UD60x18.
///
/// @param x The first operand as a UD60x18 number.
/// @param y The second operand as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function gm(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();
    if (xUint == 0 || yUint == 0) {
        return ZERO;
    }

    unchecked {
        // Checking for overflow this way is faster than letting Solidity do it.
        uint256 xyUint = xUint * yUint;
        if (xyUint / xUint != yUint) {
            revert Errors.PRBMath_UD60x18_Gm_Overflow(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product picked up a factor of `UNIT`
        // during multiplication. See the comments in {Common.sqrt}.
        result = wrap(Common.sqrt(xyUint));
    }
}

/// @notice Calculates the inverse of x.
///
/// @dev Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x must not be zero.
///
/// @param x The UD60x18 number for which to calculate the inverse.
/// @return result The inverse as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function inv(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(uUNIT_SQUARED / x.unwrap());
    }
}

/// @notice Calculates the natural logarithm of x using the following formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
/// - The precision isn't sufficiently fine-grained to return exactly `UNIT` when the input is `E`.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The UD60x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function ln(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        // Inline the fixed-point multiplication to save gas. This is overflow-safe because the maximum value that
        // {log2} can return is ~196_205294292027477728.
        result = wrap(log2(x).unwrap() * uUNIT / uLOG2_E);
    }
}

/// @notice Calculates the common logarithm of x using the following formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// However, if x is an exact power of ten, a hard coded value is returned.
///
/// @dev Notes:
/// - Refer to the notes in {log2}.
///
/// Requirements:
/// - Refer to the requirements in {log2}.
///
/// @param x The UD60x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function log10(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    if (xUint < uUNIT) {
        revert Errors.PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    // Note that the `mul` in this assembly block is the standard multiplication operation, not {UD60x18.mul}.
    // prettier-ignore
    assembly ("memory-safe") {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 59) }
        default { result := uMAX_UD60x18 }
    }

    if (result.unwrap() == uMAX_UD60x18) {
        unchecked {
            // Inline the fixed-point division to save gas.
            result = wrap(log2(x).unwrap() * uUNIT / uLOG2_10);
        }
    }
}

/// @notice Calculates the binary logarithm of x using the iterative approximation algorithm:
///
/// $$
/// log_2{x} = n + log_2{y}, \text{ where } y = x*2^{-n}, \ y \in [1, 2)
/// $$
///
/// For $0 \leq x \lt 1$, the input is inverted:
///
/// $$
/// log_2{x} = -log_2{\frac{1}{x}}
/// $$
///
/// @dev See https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
///
/// Notes:
/// - Due to the lossy precision of the iterative approximation, the results are not perfectly accurate to the last decimal.
///
/// Requirements:
/// - x must be greater than zero.
///
/// @param x The UD60x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function log2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    if (xUint < uUNIT) {
        revert Errors.PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    unchecked {
        // Calculate the integer part of the logarithm.
        uint256 n = Common.msb(xUint / uUNIT);

        // This is the integer part of the logarithm as a UD60x18 number. The operation can't overflow because n
        // n is at most 255 and UNIT is 1e18.
        uint256 resultUint = n * uUNIT;

        // Calculate $y = x * 2^{-n}$.
        uint256 y = xUint >> n;

        // If y is the unit number, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultUint);
        }

        // Calculate the fractional part via the iterative approximation.
        // The `delta >>= 1` part is equivalent to `delta /= 2`, but shifting bits is more gas efficient.
        uint256 DOUBLE_UNIT = 2e18;
        for (uint256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is y^2 >= 2e18 and so in the range [2e18, 4e18)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultUint += delta;

                // Halve y, which corresponds to z/2 in the Wikipedia article.
                y >>= 1;
            }
        }
        result = wrap(resultUint);
    }
}

/// @notice Multiplies two UD60x18 numbers together, returning a new UD60x18 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @dev See the documentation in {Common.mulDiv18}.
/// @param x The multiplicand as a UD60x18 number.
/// @param y The multiplier as a UD60x18 number.
/// @return result The product as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function mul(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(Common.mulDiv18(x.unwrap(), y.unwrap()));
}

/// @notice Raises x to the power of y.
///
/// For $1 \leq x \leq \infty$, the following standard formula is used:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// For $0 \leq x \lt 1$, since the unsigned {log2} is undefined, an equivalent formula is used:
///
/// $$
/// i = \frac{1}{x}
/// w = 2^{log_2{i} * y}
/// x^y = \frac{1}{w}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2} and {mul}.
/// - Returns `UNIT` for 0^0.
/// - It may not perform well with very small values of x. Consider using SD59x18 as an alternative.
///
/// Requirements:
/// - Refer to the requirements in {exp2}, {log2}, and {mul}.
///
/// @param x The base as a UD60x18 number.
/// @param y The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function pow(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();
    uint256 yUint = y.unwrap();

    // If both x and y are zero, the result is `UNIT`. If just x is zero, the result is always zero.
    if (xUint == 0) {
        return yUint == 0 ? UNIT : ZERO;
    }
    // If x is `UNIT`, the result is always `UNIT`.
    else if (xUint == uUNIT) {
        return UNIT;
    }

    // If y is zero, the result is always `UNIT`.
    if (yUint == 0) {
        return UNIT;
    }
    // If y is `UNIT`, the result is always x.
    else if (yUint == uUNIT) {
        return x;
    }

    // If x is greater than `UNIT`, use the standard formula.
    if (xUint > uUNIT) {
        result = exp2(mul(log2(x), y));
    }
    // Conversely, if x is less than `UNIT`, use the equivalent formula.
    else {
        UD60x18 i = wrap(uUNIT_SQUARED / xUint);
        UD60x18 w = exp2(mul(log2(i), y));
        result = wrap(uUNIT_SQUARED / w.unwrap());
    }
}

/// @notice Raises x (a UD60x18 number) to the power y (an unsigned basic integer) using the well-known
/// algorithm "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv18}.
/// - Returns `UNIT` for 0^0.
///
/// Requirements:
/// - The result must fit in UD60x18.
///
/// @param x The base as a UD60x18 number.
/// @param y The exponent as a uint256.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function powu(UD60x18 x, uint256 y) pure returns (UD60x18 result) {
    // Calculate the first iteration of the loop in advance.
    uint256 xUint = x.unwrap();
    uint256 resultUint = y & 1 > 0 ? xUint : uUNIT;

    // Equivalent to `for(y /= 2; y > 0; y /= 2)`.
    for (y >>= 1; y > 0; y >>= 1) {
        xUint = Common.mulDiv18(xUint, xUint);

        // Equivalent to `y % 2 == 1`.
        if (y & 1 > 0) {
            resultUint = Common.mulDiv18(resultUint, xUint);
        }
    }
    result = wrap(resultUint);
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - x must be less than `MAX_UD60x18 / UNIT`.
///
/// @param x The UD60x18 number for which to calculate the square root.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function sqrt(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = x.unwrap();

    unchecked {
        if (xUint > uMAX_UD60x18 / uUNIT) {
            revert Errors.PRBMath_UD60x18_Sqrt_Overflow(x);
        }
        // Multiply x by `UNIT` to account for the factor of `UNIT` picked up when multiplying two UD60x18 numbers.
        // In this case, the two numbers are both the square root.
        result = wrap(Common.sqrt(xUint * uUNIT));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Defines a hook implementation and instructions on which hooks to call.
/// @param useBeforeClaimPrize If true, the vault will call the beforeClaimPrize hook on the implementation
/// @param useAfterClaimPrize If true, the vault will call the afterClaimPrize hook on the implementation
/// @param implementation The address of the smart contract implementing the hooks
struct PrizeHooks {
    bool useBeforeClaimPrize;
    bool useAfterClaimPrize;
    IPrizeHooks implementation;
}

/// @title  PoolTogether V5 Prize Hooks Interface
/// @author PoolTogether Inc. & G9 Software Inc.
/// @notice Allows winners to attach smart contract hooks to their prize winnings
interface IPrizeHooks {
    
    /// @notice Triggered before the prize pool claim prize function is called.
    /// @param winner The user who won the prize and for whom this hook is attached
    /// @param tier The tier of the prize
    /// @param prizeIndex The index of the prize in the tier
    /// @param reward The reward portion of the prize that will be allocated to the claimer
    /// @param rewardRecipient The recipient of the claim reward
    /// @return prizeRecipient The address of the recipient of the prize
    /// @return data Arbitrary data that will be passed to the `afterClaimPrize` hook
    function beforeClaimPrize(
        address winner,
        uint8 tier,
        uint32 prizeIndex,
        uint96 reward,
        address rewardRecipient
    ) external returns (address prizeRecipient, bytes memory data);

    /// @notice Triggered after the prize pool claim prize function is called.
    /// @param winner The user who won the prize and for whom this hook is attached
    /// @param tier The tier of the prize
    /// @param prizeIndex The index of the prize
    /// @param prize The total size of the prize (not including the claim reward)
    /// @param prizeRecipient The recipient of the prize
    /// @param data Arbitrary data received from the `beforeClaimPrize` hook
    function afterClaimPrize(
        address winner,
        uint8 tier,
        uint32 prizeIndex,
        uint256 prize,
        address prizeRecipient,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "./ECDSA.sol";
import "../ShortStrings.sol";
import "../../interfaces/IERC5267.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../Common.sol" as Common;
import "./Errors.sol" as Errors;
import { uMAX_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { UD2x18 } from "./ValueType.sol";

/// @notice Casts a UD2x18 number into SD1x18.
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(UD2x18 x) pure returns (SD1x18 result) {
    uint64 xUint = UD2x18.unwrap(x);
    if (xUint > uint64(uMAX_SD1x18)) {
        revert Errors.PRBMath_UD2x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(xUint));
}

/// @notice Casts a UD2x18 number into SD59x18.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of SD59x18.
function intoSD59x18(UD2x18 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(int256(uint256(UD2x18.unwrap(x))));
}

/// @notice Casts a UD2x18 number into UD60x18.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of UD60x18.
function intoUD60x18(UD2x18 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(UD2x18.unwrap(x));
}

/// @notice Casts a UD2x18 number into uint128.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of uint128.
function intoUint128(UD2x18 x) pure returns (uint128 result) {
    result = uint128(UD2x18.unwrap(x));
}

/// @notice Casts a UD2x18 number into uint256.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of uint256.
function intoUint256(UD2x18 x) pure returns (uint256 result) {
    result = uint256(UD2x18.unwrap(x));
}

/// @notice Casts a UD2x18 number into uint40.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(UD2x18 x) pure returns (uint40 result) {
    uint64 xUint = UD2x18.unwrap(x);
    if (xUint > uint64(Common.MAX_UINT40)) {
        revert Errors.PRBMath_UD2x18_IntoUint40_Overflow(x);
    }
    result = uint40(xUint);
}

/// @notice Alias for {wrap}.
function ud2x18(uint64 x) pure returns (UD2x18 result) {
    result = UD2x18.wrap(x);
}

/// @notice Unwrap a UD2x18 number into uint64.
function unwrap(UD2x18 x) pure returns (uint64 result) {
    result = UD2x18.unwrap(x);
}

/// @notice Wraps a uint64 number into UD2x18.
function wrap(uint64 x) pure returns (UD2x18 result) {
    result = UD2x18.wrap(x);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.8;

import "./StorageSlot.sol";

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { UD2x18 } from "./ValueType.sol";

/// @notice Thrown when trying to cast a UD2x18 number that doesn't fit in SD1x18.
error PRBMath_UD2x18_IntoSD1x18_Overflow(UD2x18 x);

/// @notice Thrown when trying to cast a UD2x18 number that doesn't fit in uint40.
error PRBMath_UD2x18_IntoUint40_Overflow(UD2x18 x);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}