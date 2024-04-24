// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.20;

import "../interfaces/ICurvePool.sol";
import "../interfaces/IPrincipalToken.sol";
import "openzeppelin-math/Math.sol";

/**
 * @title CurvePoolUtil library
 * @author Spectra Finance
 * @notice Provides miscellaneous utils for computations related to Curve protocol.
 */
library CurvePoolUtil {
    using Math for uint256;

    error SolutionNotFound();
    error FailedToFetchExpectedLPTokenAmount();
    error FailedToFetchExpectedCoinAmount();

    /// @notice Decimal precision used internally in the Curve AMM
    uint256 public constant CURVE_DECIMALS = 18;
    /// @notice Base unit for Curve AMM calculations
    uint256 public constant CURVE_UNIT = 1e18;
    /// @notice Make rounding errors favoring other LPs a tiny bit
    uint256 private constant APPROXIMATION_DECREMENT = 1;
    /// @notice Maximal number of iterations in the binary search algorithm
    uint256 private constant MAX_ITERATIONS_BINSEARCH = 255;

    /**
     * @notice Returns the expected LP token amount received for depositing given amounts of IBT and PT
     * @param _curvePool The address of the Curve Pool in which liquidity will be deposited
     * @param _amounts Array containing the amounts of IBT and PT to deposit in the Curve Pool
     * @return minMintAmount The amount of expected LP tokens received for depositing the liquidity in the pool
     */
    function previewAddLiquidity(
        address _curvePool,
        uint256[2] memory _amounts
    ) external view returns (uint256 minMintAmount) {
        (bool success, bytes memory responseData) = _curvePool.staticcall(
            abi.encodeCall(ICurvePool(address(0)).calc_token_amount, (_amounts))
        );
        if (!success) {
            revert FailedToFetchExpectedLPTokenAmount();
        }
        minMintAmount = abi.decode(responseData, (uint256));
    }

    /**
     * @notice Returns the IBT and PT amounts received for burning a given amount of LP tokens
     * @param _curvePool The address of the curve pool
     * @param _lpTokenAmount The amount of the lp token to burn
     * @return minAmounts The expected respective amounts of IBT and PT withdrawn from the curve pool
     */
    function previewRemoveLiquidity(
        address _curvePool,
        uint256 _lpTokenAmount
    ) external view returns (uint256[2] memory minAmounts) {
        address lpToken = ICurvePool(_curvePool).token();
        uint256 totalSupply = IERC20(lpToken).totalSupply();
        (uint256 ibtBalance, uint256 ptBalance) = _getCurvePoolBalances(_curvePool);
        // decrement following what Curve is doing
        if (_lpTokenAmount > APPROXIMATION_DECREMENT && totalSupply != 0) {
            _lpTokenAmount -= APPROXIMATION_DECREMENT;
            minAmounts = [
                (ibtBalance * _lpTokenAmount) / totalSupply,
                (ptBalance * _lpTokenAmount) / totalSupply
            ];
        } else {
            minAmounts = [uint256(0), uint256(0)];
        }
    }

    /**
     * @notice Returns the amount of coin i received for burning a given amount of LP tokens
     * @param _curvePool The address of the curve pool
     * @param _lpTokenAmount The amount of the LP tokens to burn
     * @param _i The index of the unique coin to withdraw
     * @return minAmount The expected amount of coin i withdrawn from the curve pool
     */
    function previewRemoveLiquidityOneCoin(
        address _curvePool,
        uint256 _lpTokenAmount,
        uint256 _i
    ) external view returns (uint256 minAmount) {
        (bool success, bytes memory responseData) = _curvePool.staticcall(
            abi.encodeCall(ICurvePool(address(0)).calc_withdraw_one_coin, (_lpTokenAmount, _i))
        );
        if (!success) {
            revert FailedToFetchExpectedCoinAmount();
        }
        minAmount = abi.decode(responseData, (uint256));
    }

    /**
     * @notice Return the amount of IBT to deposit in the curve pool, given the total amount of IBT available for deposit
     * @param _amount The total amount of IBT available for deposit
     * @param _curvePool The address of the pool to deposit the amounts
     * @param _pt The address of the PT
     * @return ibts The amount of IBT which will be deposited in the curve pool
     */
    function calcIBTsToTokenizeForCurvePool(
        uint256 _amount,
        address _curvePool,
        address _pt
    ) external view returns (uint256 ibts) {
        (uint256 ibtBalance, uint256 ptBalance) = _getCurvePoolBalances(_curvePool);
        uint256 ibtBalanceInPT = IPrincipalToken(_pt).previewDepositIBT(ibtBalance);
        // Liquidity added in a ratio that (closely) matches the existing pool's ratio
        ibts = _amount.mulDiv(ptBalance, ibtBalanceInPT + ptBalance);
    }

    /**
     * @param _curvePool : PT/IBT curve pool
     * @param _i token index
     * @param _j token index
     * @param _targetDy amount out desired
     * @return dx The amount of token to provide in order to obtain _targetDy after swap
     */
    function getDx(
        address _curvePool,
        uint256 _i,
        uint256 _j,
        uint256 _targetDy
    ) external view returns (uint256 dx) {
        // Initial guesses
        uint256 _minGuess = type(uint256).max;
        uint256 _maxGuess = type(uint256).max;
        uint256 _factor100;
        uint256 _guess = ICurvePool(_curvePool).get_dy(_i, _j, _targetDy);

        if (_guess > _targetDy) {
            _maxGuess = _targetDy;
            _factor100 = 10;
        } else {
            _minGuess = _targetDy;
            _factor100 = 1000;
        }
        uint256 loops;
        _guess = _targetDy;
        while (!_dxSolved(_curvePool, _i, _j, _guess, _targetDy, _minGuess, _maxGuess)) {
            loops++;

            (_minGuess, _maxGuess, _guess) = _runLoop(
                _minGuess,
                _maxGuess,
                _factor100,
                _guess,
                _targetDy,
                _curvePool,
                _i,
                _j
            );

            if (loops >= MAX_ITERATIONS_BINSEARCH) {
                revert SolutionNotFound();
            }
        }
        dx = _guess;
    }

    /**
     * @dev Runs bisection search
     * @param _minGuess lower bound on searched value
     * @param _maxGuess upper bound on searched value
     * @param _factor100 search interval scaling factor
     * @param _guess The previous guess for the `dx` value that is being refined through the search process
     * @param _targetDy The target output of the `get_dy` function, which the search aims to achieve by adjusting `dx`.
     * @param _curvePool PT/IBT curve pool
     * @param _i token index, either 0 or 1
     * @param _j token index, either 0 or 1, must be different than _i
     * @return The lower bound on _guess, upper bound on _guess and next _guess
     */
    function _runLoop(
        uint256 _minGuess,
        uint256 _maxGuess,
        uint256 _factor100,
        uint256 _guess,
        uint256 _targetDy,
        address _curvePool,
        uint256 _i,
        uint256 _j
    ) internal view returns (uint256, uint256, uint256) {
        if (_minGuess == type(uint256).max || _maxGuess == type(uint256).max) {
            _guess = (_guess * _factor100) / 100;
        } else {
            _guess = (_maxGuess + _minGuess) >> 1;
        }
        uint256 dy = ICurvePool(_curvePool).get_dy(_i, _j, _guess);
        if (dy < _targetDy) {
            _minGuess = _guess;
        } else if (dy > _targetDy) {
            _maxGuess = _guess;
        }
        return (_minGuess, _maxGuess, _guess);
    }

    /**
     * @dev Returns true if algorithm converged
     * @param _curvePool PT/IBT curve pool
     * @param _i token index, either 0 or 1
     * @param _j token index, either 0 or 1, must be different than _i
     * @param _dx The current guess for the `dx` value that is being refined through the search process.
     * @param _targetDy The target output of the `get_dy` function, which the search aims to achieve by adjusting `dx`.
     * @param _minGuess lower bound on searched value
     * @param _maxGuess upper bound on searched value
     * @return true if the solution to the search problem was found, false otherwise
     */
    function _dxSolved(
        address _curvePool,
        uint256 _i,
        uint256 _j,
        uint256 _dx,
        uint256 _targetDy,
        uint256 _minGuess,
        uint256 _maxGuess
    ) internal view returns (bool) {
        if (_minGuess == type(uint256).max || _maxGuess == type(uint256).max) {
            return false;
        }
        uint256 dy = ICurvePool(_curvePool).get_dy(_i, _j, _dx);
        if (dy == _targetDy) {
            return true;
        }
        uint256 dy1 = ICurvePool(_curvePool).get_dy(_i, _j, _dx + 1);
        if (dy < _targetDy && _targetDy < dy1) {
            return true;
        }
        return false;
    }

    /**
     * @notice Returns the balances of the two tokens in provided curve pool
     * @param _curvePool address of the curve pool
     * @return The IBT and PT balances of the curve pool
     */
    function _getCurvePoolBalances(address _curvePool) internal view returns (uint256, uint256) {
        return (ICurvePool(_curvePool).balances(0), ICurvePool(_curvePool).balances(1));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

interface ICurvePool {
    function coins(uint256 index) external view returns (address);

    function balances(uint256 index) external view returns (uint256);

    function A() external view returns (uint256);

    function gamma() external view returns (uint256);

    function D() external view returns (uint256);

    function token() external view returns (address);

    function price_scale() external view returns (uint256);

    function future_A_gamma_time() external view returns (uint256);

    function future_A_gamma() external view returns (uint256);

    function initial_A_gamma_time() external view returns (uint256);

    function initial_A_gamma() external view returns (uint256);

    function fee_gamma() external view returns (uint256);

    function mid_fee() external view returns (uint256);

    function out_fee() external view returns (uint256);

    function allowed_extra_profit() external view returns (uint256);

    function adjustment_step() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function ma_half_time() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function fee() external view returns (uint256);

    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);

    function last_prices() external view returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts) external view returns (uint256);

    function calc_withdraw_one_coin(
        uint256 _token_amount,
        uint256 i
    ) external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external returns (uint256);

    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function remove_liquidity(uint256 amount, uint256[2] calldata min_amounts) external;

    function remove_liquidity(
        uint256 amount,
        uint256[2] calldata min_amounts,
        bool use_eth,
        address receiver
    ) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth,
        address receiver
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/interfaces/IERC20Metadata.sol";
import "openzeppelin-contracts/interfaces/IERC3156FlashLender.sol";

interface IPrincipalToken is IERC20, IERC20Metadata, IERC3156FlashLender {
    /* ERRORS
     *****************************************************************************************************************/

    error InvalidDecimals();
    error BeaconNotSet();
    error PTExpired();
    error PTNotExpired();
    error RateError();
    error AddressError();
    error UnauthorizedCaller();
    error RatesAtExpiryAlreadyStored();
    error ERC5143SlippageProtectionFailed();
    error InsufficientBalance();
    error FlashLoanExceedsMaxAmount();
    error FlashLoanCallbackFailed();
    error NoRewardsProxy();
    error ClaimRewardsFailed();

    /* Functions
     *****************************************************************************************************************/

    function initialize(address _ibt, uint256 _duration, address initialAuthority) external;

    /**
     * @notice Toggle Pause
     * @dev Should only be called in extraordinary situations by the admin of the contract
     */
    function pause() external;

    /**
     * @notice Toggle UnPause
     * @dev Should only be called in extraordinary situations by the admin of the contract
     */
    function unPause() external;

    /**
     * @notice Deposits amount of assets in the PT vault
     * @param assets The amount of assets being deposited
     * @param receiver The receiver address of the shares
     * @return shares The amount of shares minted (same amount for PT & yt)
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @notice Deposits amount of assets in the PT vault
     * @param assets The amount of assets being deposited
     * @param ptReceiver The receiver address of the PTs
     * @param ytReceiver the receiver address of the YTs
     * @return shares The amount of shares minted (same amount for PT & yt)
     */
    function deposit(
        uint256 assets,
        address ptReceiver,
        address ytReceiver
    ) external returns (uint256 shares);

    /**
     * @notice Deposits amount of assets with a lower bound on shares received
     * @param assets The amount of assets being deposited
     * @param ptReceiver The receiver address of the PTs
     * @param ytReceiver The receiver address of the YTs
     * @param minShares The minimum allowed shares from this deposit
     * @return shares The amount of shares actually minted to the receiver
     */
    function deposit(
        uint256 assets,
        address ptReceiver,
        address ytReceiver,
        uint256 minShares
    ) external returns (uint256 shares);

    /**
     * @notice Same as normal deposit but with IBTs
     * @param ibts The amount of IBT being deposited
     * @param receiver The receiver address of the shares
     * @return shares The amount of shares minted to the receiver
     */
    function depositIBT(uint256 ibts, address receiver) external returns (uint256 shares);

    /**
     * @notice Same as normal deposit but with IBTs
     * @param ibts The amount of IBT being deposited
     * @param ptReceiver The receiver address of the PTs
     * @param ytReceiver the receiver address of the YTs
     * @return shares The amount of shares minted to the receiver
     */
    function depositIBT(
        uint256 ibts,
        address ptReceiver,
        address ytReceiver
    ) external returns (uint256 shares);

    /**
     * @notice Same as normal deposit but with IBTs
     * @param ibts The amount of IBT being deposited
     * @param ptReceiver The receiver address of the PTs
     * @param ytReceiver The receiver address of the YTs
     * @param minShares The minimum allowed shares from this deposit
     * @return shares The amount of shares minted to the receiver
     */
    function depositIBT(
        uint256 ibts,
        address ptReceiver,
        address ytReceiver,
        uint256 minShares
    ) external returns (uint256 shares);

    /**
     * @notice Burns owner's shares (PTs and YTs before expiry, PTs after expiry)
     * and sends assets to receiver
     * @param shares The amount of shares to burn
     * @param receiver The address that will receive the assets
     * @param owner The owner of the shares
     * @return assets The actual amount of assets received for burning the shares
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    /**
     * @notice Burns owner's shares (PTs and YTs before expiry, PTs after expiry)
     * and sends assets to receiver
     * @param shares The amount of shares to burn
     * @param receiver The address that will receive the assets
     * @param owner The owner of the shares
     * @param minAssets The minimum assets that should be returned to user
     * @return assets The actual amount of assets received for burning the shares
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 minAssets
    ) external returns (uint256 assets);

    /**
     * @notice Burns owner's shares (PTs and YTs before expiry, PTs after expiry)
     * and sends IBTs to receiver
     * @param shares The amount of shares to burn
     * @param receiver The address that will receive the IBTs
     * @param owner The owner of the shares
     * @return ibts The actual amount of IBT received for burning the shares
     */
    function redeemForIBT(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 ibts);

    /**
     * @notice Burns owner's shares (PTs and YTs before expiry, PTs after expiry)
     * and sends IBTs to receiver
     * @param shares The amount of shares to burn
     * @param receiver The address that will receive the IBTs
     * @param owner The owner of the shares
     * @param minIbts The minimum IBTs that should be returned to user
     * @return ibts The actual amount of IBT received for burning the shares
     */
    function redeemForIBT(
        uint256 shares,
        address receiver,
        address owner,
        uint256 minIbts
    ) external returns (uint256 ibts);

    /**
     * @notice Burns owner's shares (before expiry : PTs and YTs) and sends assets to receiver
     * @param assets The amount of assets to be received
     * @param receiver The address that will receive the assets
     * @param owner The owner of the shares (PTs and YTs)
     * @return shares The actual amount of shares burnt for receiving the assets
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @notice Burns owner's shares (before expiry : PTs and YTs) and sends assets to receiver
     * @param assets The amount of assets to be received
     * @param receiver The address that will receive the assets
     * @param owner The owner of the shares (PTs and YTs)
     * @param maxShares The maximum shares allowed to be burnt
     * @return shares The actual amount of shares burnt for receiving the assets
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxShares
    ) external returns (uint256 shares);

    /**
     * @notice Burns owner's shares (before expiry : PTs and YTs) and sends IBTs to receiver
     * @param ibts The amount of IBT to be received
     * @param receiver The address that will receive the IBTs
     * @param owner The owner of the shares (PTs and YTs)
     * @return shares The actual amount of shares burnt for receiving the IBTs
     */
    function withdrawIBT(
        uint256 ibts,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @notice Burns owner's shares (before expiry : PTs and YTs) and sends IBTs to receiver
     * @param ibts The amount of IBT to be received
     * @param receiver The address that will receive the IBTs
     * @param owner The owner of the shares (PTs and YTs)
     * @param maxShares The maximum shares allowed to be burnt
     * @return shares The actual amount of shares burnt for receiving the IBTs
     */
    function withdrawIBT(
        uint256 ibts,
        address receiver,
        address owner,
        uint256 maxShares
    ) external returns (uint256 shares);

    /**
     * @notice Updates _user's yield since last update
     * @param _user The user whose yield will be updated
     * @return updatedUserYieldInIBT The unclaimed yield of the user in IBT (not just the updated yield)
     */
    function updateYield(address _user) external returns (uint256 updatedUserYieldInIBT);

    /**
     * @notice Claims caller's unclaimed yield in asset
     * @param _receiver The receiver of yield
     * @param _minAssets The minimum amount of assets that should be received
     * @return yieldInAsset The amount of yield claimed in asset
     */
    function claimYield(
        address _receiver,
        uint256 _minAssets
    ) external returns (uint256 yieldInAsset);

    /**
     * @notice Claims caller's unclaimed yield in IBT
     * @param _receiver The receiver of yield
     * @param _minIBT The minimum amount of IBT that should be received
     * @return yieldInIBT The amount of yield claimed in IBT
     */
    function claimYieldInIBT(
        address _receiver,
        uint256 _minIBT
    ) external returns (uint256 yieldInIBT);

    /**
     * @notice Claims the collected ibt fees and redeems them to the fee collector
     * @param _minAssets The minimum amount of assets that should be received
     * @return assets The amount of assets sent to the fee collector
     */
    function claimFees(uint256 _minAssets) external returns (uint256 assets);

    /**
     * @notice Updates yield of both sender and receiver of YTs
     * @param _from the sender of YTs
     * @param _to the receiver of YTs
     */
    function beforeYtTransfer(address _from, address _to) external;

    /**
     * Call the claimRewards function of the rewards contract
     * @param data The optional data to be passed to the rewards contract
     */
    function claimRewards(bytes memory data) external;

    /* SETTERS
     *****************************************************************************************************************/

    /**
     * @notice Stores PT and IBT rates at expiry. Ideally, it should be called the day of expiry
     */
    function storeRatesAtExpiry() external;

    /** Set a new Rewards Proxy
     * @param _rewardsProxy The address of the new reward proxy
     */
    function setRewardsProxy(address _rewardsProxy) external;

    /* GETTERS
     *****************************************************************************************************************/

    /**
     * @notice Returns the amount of shares minted for the theorical deposited amount of assets
     * @param assets The amount of assets deposited
     * @return The amount of shares minted
     */
    function previewDeposit(uint256 assets) external view returns (uint256);

    /**
     * @notice Returns the amount of shares minted for the theorical deposited amount of IBT
     * @param ibts The amount of IBT deposited
     * @return The amount of shares minted
     */
    function previewDepositIBT(uint256 ibts) external view returns (uint256);

    /**
     * @notice Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     * @param receiver The receiver of the shares
     * @return The maximum amount of assets that can be deposited
     */
    function maxDeposit(address receiver) external view returns (uint256);

    /**
     * @notice Returns the theorical amount of shares that need to be burnt to receive assets of underlying
     * @param assets The amount of assets to receive
     * @return The amount of shares burnt
     */
    function previewWithdraw(uint256 assets) external view returns (uint256);

    /**
     * @notice Returns the theorical amount of shares that need to be burnt to receive amount of IBT
     * @param ibts The amount of IBT to receive
     * @return The amount of shares burnt
     */
    function previewWithdrawIBT(uint256 ibts) external view returns (uint256);

    /**
     * @notice Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     * @param owner The owner of the Vault shares
     * @return The maximum amount of assets that can be withdrawn
     */
    function maxWithdraw(address owner) external view returns (uint256);

    /**
     * @notice Returns the maximum amount of the IBT that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     * @param owner The owner of the Vault shares
     * @return The maximum amount of IBT that can be withdrawn
     */
    function maxWithdrawIBT(address owner) external view returns (uint256);

    /**
     * @notice Returns the amount of assets received for the theorical amount of burnt shares
     * @param shares The amount of shares to burn
     * @return The amount of assets received
     */
    function previewRedeem(uint256 shares) external view returns (uint256);

    /**
     * @notice Returns the amount of IBT received for the theorical amount of burnt shares
     * @param shares The amount of shares to burn
     * @return The amount of IBT received
     */
    function previewRedeemForIBT(uint256 shares) external view returns (uint256);

    /**
     * @notice Returns the maximum amount of Vault shares that can be redeemed by the owner
     * @notice This function behaves differently before and after expiry. Before expiry an equal amount of PT and YT
     * needs to be burnt, while after expiry only PTs are burnt.
     * @param owner The owner of the shares
     * @return The maximum amount of shares that can be redeemed
     */
    function maxRedeem(address owner) external view returns (uint256);

    /**
     * Returns the total amount of the underlying asset that is owned by the Vault in the form of IBT.
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Converts an underlying amount in principal. Equivalent to ERC-4626's convertToShares method.
     * @param underlyingAmount The amount of underlying (or assets) to convert
     * @return The resulting amount of principal (or shares)
     */
    function convertToPrincipal(uint256 underlyingAmount) external view returns (uint256);

    /**
     * @notice Converts a principal amount in underlying. Equivalent to ERC-4626's convertToAssets method.
     * @param principalAmount The amount of principal (or shares) to convert
     * @return The resulting amount of underlying (or assets)
     */
    function convertToUnderlying(uint256 principalAmount) external view returns (uint256);

    /**
     * @notice Returns whether or not the contract is paused.
     * @return true if the contract is paused, and false otherwise
     */
    function paused() external view returns (bool);

    /**
     * @notice Returns the unix timestamp (uint256) at which the PT contract expires
     * @return The unix timestamp (uint256) when PTs become redeemable
     */
    function maturity() external view returns (uint256);

    /**
     * @notice Returns the duration of the PT contract
     * @return The duration (in s) to expiry/maturity of the PT contract
     */
    function getDuration() external view returns (uint256);

    /**
     * @notice Returns the address of the underlying token (or asset). Equivalent to ERC-4626's asset method.
     * @return The address of the underlying token (or asset)
     */
    function underlying() external view returns (address);

    /**
     * @notice Returns the IBT address of the PT contract
     * @return ibt The address of the IBT
     */
    function getIBT() external view returns (address ibt);

    /**
     * @notice Returns the yt address of the PT contract
     * @return yt The address of the yt
     */
    function getYT() external view returns (address yt);

    /**
     * @notice Returns the current ibtRate
     * @return The current ibtRate
     */
    function getIBTRate() external view returns (uint256);

    /**
     * @notice Returns the current ptRate
     * @return The current ptRate
     */
    function getPTRate() external view returns (uint256);

    /**
     * @notice Returns 1 unit of IBT
     * @return The IBT unit
     */
    function getIBTUnit() external view returns (uint256);

    /**
     * @notice Get the unclaimed fees in IBT
     * @return The unclaimed fees in IBT
     */
    function getUnclaimedFeesInIBT() external view returns (uint256);

    /**
     * @notice Get the total collected fees in IBT (claimed and unclaimed)
     * @return The total fees in IBT
     */
    function getTotalFeesInIBT() external view returns (uint256);

    /**
     * @notice Get the tokenization fee of the PT
     * @return The tokenization fee
     */
    function getTokenizationFee() external view returns (uint256);

    /**
     * @notice Get the current IBT yield of the user
     * @param _user The address of the user to get the current yield from
     * @return The yield of the user in IBT
     */
    function getCurrentYieldOfUserInIBT(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20Metadata} from "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.20;

import {IERC3156FlashBorrower} from "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}