// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { RewardLiquidator, IPrizePool, TpdaLiquidationPairFactory } from "./RewardLiquidator.sol";

/// @title  PoolTogether V5 Reward Liquidator Factory
/// @author G9 Software Inc.
/// @notice Factory contract for deploying new reward liquidators
contract RewardLiquidatorFactory {

    ////////////////////////////////////////////////////////////////////////////////
    // Events
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when a new RewardLiquidator has been deployed by this factory.
    /// @param liquidator The address of the newly deployed RewardLiquidator
    event NewRewardLiquidator(
        RewardLiquidator indexed liquidator
    );

    /// @notice List of all liquidators deployed by this factory.
    RewardLiquidator[] public allLiquidators;

    /// @notice Mapping to verify if a Liquidator has been deployed via this factory.
    mapping(address liquidator => bool deployedByFactory) public deployedLiquidators;

    /// @notice Mapping to store deployer nonces for CREATE2
    mapping(address deployer => uint256 nonce) public deployerNonces;

    ////////////////////////////////////////////////////////////////////////////////
    // External Functions
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Deploy a new liquidator that contributes liquidations to a prize pool on behalf of a vault.
    /// @dev Emits a `NewRewardLiquidator` event with the vault details.
    /// @param _creator The address of the creator of the vault
    /// @param _vaultBeneficiary The address of the vault beneficiary of the prize pool contributions
    /// @param _prizePool The prize pool the vault will contribute to
    /// @param _liquidationPairFactory The factory to use for creating liquidation pairs
    /// @param _targetAuctionPeriod The target auction period for liquidations
    /// @param _targetAuctionPrice The target auction price for liquidations
    /// @param _smoothingFactor The smoothing factor for liquidations
    /// @return RewardLiquidator The newly deployed RewardLiquidator
    function createLiquidator(
        address _creator,
        address _vaultBeneficiary,
        IPrizePool _prizePool,
        TpdaLiquidationPairFactory _liquidationPairFactory,
        uint64 _targetAuctionPeriod,
        uint192 _targetAuctionPrice,
        uint256 _smoothingFactor
    ) external returns (RewardLiquidator) {
        RewardLiquidator liquidator = new RewardLiquidator{
            salt: keccak256(abi.encode(msg.sender, deployerNonces[msg.sender]++))
        }(
            _creator,
            _vaultBeneficiary,
            _prizePool,
            _liquidationPairFactory,
            _targetAuctionPeriod,
            _targetAuctionPrice,
            _smoothingFactor
        );

        allLiquidators.push(liquidator);
        deployedLiquidators[address(liquidator)] = true;

        emit NewRewardLiquidator(liquidator);

        return liquidator;
    }

    /// @notice Total number of liquidators deployed by this factory.
    /// @return uint256 Number of liquidators deployed by this factory.
    function totalLiquidators() external view returns (uint256) {
        return allLiquidators.length;
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    TpdaLiquidationPairFactory,
    ILiquidationSource
} from "pt-v5-tpda-liquidator/TpdaLiquidationPairFactory.sol";
import { TpdaLiquidationPair } from "pt-v5-tpda-liquidator/TpdaLiquidationPair.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import { IRewardSource } from "./external/interfaces/IRewardSource.sol";
import { IPrizePool } from "./external/interfaces/IPrizePool.sol";

/// @notice Thrown when a function is called by an account that isn't the creator
error OnlyCreator();

/// @notice Thrown when the yield vault has already been set
error YieldVaultAlreadySet();

/// @notice Thrown when the yield vault reward recipient is not the liquidator
error InvalidRewardRecipient();

/// @notice Thrown when a reward token has already been initialized
error AlreadyInitialized();

/// @notice Thrown when an account that isn't a valid liquidation pair calls the contract
error OnlyLiquidationPair();

/// @notice Thrown when a token is queried that isn't known
error UnknownRewardToken();

/// @notice Thrown when trying to initialize a token with the zero address
error CannotInitializeZeroAddress();

/// @title Reward Liquidator
/// @author G9 Software Inc.
/// @notice Liquidates rewards from a reward source.
contract RewardLiquidator is ILiquidationSource {
    using SafeERC20 for IERC20;

    /// @notice Emitted when the yield vault has been set by the creator
    /// @param yieldVault The address of the yield vault
    event YieldVaultSet(IRewardSource indexed yieldVault);

    /// @notice Emitted when the reward token has been initialized
    /// @param token The address of the reward token
    /// @param pair The address of the liquidation pair
    event InitializedRewardToken(address indexed token, TpdaLiquidationPair indexed pair);

    /// @notice The account that will set the yield vault
    address public immutable creator;

    /// @notice The vault on whose behalf this contract will contribute to the prize pool
    address public immutable vaultBeneficiary;

    /// @notice The prize pool to contribute liquidation proceeds to
    IPrizePool public immutable prizePool;

    /// @notice The factory to create liquidation pairs
    TpdaLiquidationPairFactory public immutable liquidationPairFactory;

    /// @notice The target auction period for liquidation pairs
    uint64 public immutable targetAuctionPeriod;

    /// @notice The target auction price for liquidation pairs
    uint192 public immutable targetAuctionPrice;

    /// @notice The smoothing factor for liquidation pairs
    uint256 public immutable smoothingFactor;

    /// @notice The yield vault from which this contract receives rewards
    IRewardSource public yieldVault;

    /// @notice A mapping from reward tokens to liquidation pairs
    mapping(address tokenOut => TpdaLiquidationPair liquidationPair) public liquidationPairs;

    /// @notice Construct a new RewardLiquidator
    /// @param _creator The account that will set the yield vault
    /// @param _vaultBeneficiary The vault on whose behalf this contract will contribute to the prize pool
    /// @param _prizePool The prize pool to contribute liquidation proceeds to
    /// @param _liquidationPairFactory The factory to create liquidation pairs
    /// @param _targetAuctionPeriod The target auction period for liquidation pairs
    /// @param _targetAuctionPrice The target auction price for liquidation pairs
    /// @param _smoothingFactor The smoothing factor for liquidation pairs
    constructor(
        address _creator,
        address _vaultBeneficiary,
        IPrizePool _prizePool,
        TpdaLiquidationPairFactory _liquidationPairFactory,
        uint64 _targetAuctionPeriod,
        uint192 _targetAuctionPrice,
        uint256 _smoothingFactor
    ) {
        vaultBeneficiary = _vaultBeneficiary;
        targetAuctionPeriod = _targetAuctionPeriod;
        targetAuctionPrice = _targetAuctionPrice;
        smoothingFactor = _smoothingFactor;
        prizePool = _prizePool;
        liquidationPairFactory = _liquidationPairFactory;
        creator = _creator;
    }

    /// @notice Set the yield vault to receive rewards from
    /// @param _yieldVault The yield vault to set
    function setYieldVault(IRewardSource _yieldVault) external {
        if (msg.sender != creator) {
            revert OnlyCreator();
        }
        if (address(yieldVault) != address(0)) {
            revert YieldVaultAlreadySet();
        }
        if (_yieldVault.rewardRecipient() != address(this)) {
            revert InvalidRewardRecipient();
        }
        yieldVault = _yieldVault;

        emit YieldVaultSet(_yieldVault);
    }

    /// @notice Initialize a reward token for liquidation. Must be called before liquidations can be performed for this token.
    /// @param rewardToken The address of the reward token
    /// @return The liquidation pair for the reward token
    function initializeRewardToken(address rewardToken) external returns (TpdaLiquidationPair) {
        if (rewardToken == address(0)) {
            revert CannotInitializeZeroAddress();
        }
        if (address(liquidationPairs[rewardToken]) != address(0)) {
            revert AlreadyInitialized();
        }
        TpdaLiquidationPair pair = liquidationPairFactory.createPair(
            this,
            address(prizePool.prizeToken()),
            rewardToken,
            targetAuctionPeriod,
            targetAuctionPrice,
            smoothingFactor
        );
        liquidationPairs[rewardToken] = pair;

        emit InitializedRewardToken(rewardToken, pair);

        return pair;
    }

    /// @inheritdoc ILiquidationSource
    function liquidatableBalanceOf(address tokenOut) external returns (uint256) {
        yieldVault.claimRewards();
        return IERC20(tokenOut).balanceOf(address(this));
    }

    /// @inheritdoc ILiquidationSource
    function transferTokensOut(
        address,
        address receiver,
        address tokenOut,
        uint256 amountOut
    ) external returns (bytes memory) {
        if (msg.sender != address(liquidationPairs[tokenOut])) {
            revert OnlyLiquidationPair();
        }
        IERC20(tokenOut).safeTransfer(receiver, amountOut);

        return "";
    }

    /// @inheritdoc ILiquidationSource
    function verifyTokensIn(
        address,
        uint256 amountIn,
        bytes calldata
    ) external {
        prizePool.contributePrizeTokens(vaultBeneficiary, amountIn);
    }

    /// @inheritdoc ILiquidationSource
    function targetOf(address) external view returns (address) {
        return address(prizePool);
    }

    /// @inheritdoc ILiquidationSource
    function isLiquidationPair(address tokenOut, address liquidationPair) external view returns (bool) {
        address existingPair = address(liquidationPairs[tokenOut]);
        if (existingPair == address(0)) {
            revert UnknownRewardToken();
        }
        return existingPair == liquidationPair;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ILiquidationSource, TpdaLiquidationPair } from "./TpdaLiquidationPair.sol";

/// @title TpdaLiquidationPairFactory
/// @author G9 Software Inc.
/// @notice Factory contract for deploying TpdaLiquidationPair contracts.
contract TpdaLiquidationPairFactory {
    /* ============ Events ============ */

    /// @notice Emitted when a new TpdaLiquidationPair is created
    /// @param pair The address of the new pair
    /// @param source The liquidation source that the pair is using
    /// @param tokenIn The input token for the pair
    /// @param tokenOut The output token for the pair
    /// @param targetAuctionPeriod The duration of auctions
    /// @param targetAuctionPrice The minimum auction size in output tokens
    /// @param smoothingFactor The 18 decimal smoothing fraction for the liquid balance
    event PairCreated(
        TpdaLiquidationPair indexed pair,
        ILiquidationSource source,
        address indexed tokenIn,
        address indexed tokenOut,
        uint64 targetAuctionPeriod,
        uint192 targetAuctionPrice,
        uint256 smoothingFactor
    );

    /* ============ Variables ============ */

    /// @notice Tracks an array of all pairs created by this factory
    TpdaLiquidationPair[] public allPairs;

    /* ============ Mappings ============ */

    /// @notice Mapping to verify if a TpdaLiquidationPair has been deployed via this factory.
    mapping(address pair => bool wasDeployed) public deployedPairs;

    /// @notice Creates a new TpdaLiquidationPair and registers it within the factory
    /// @param _source The liquidation source that the pair will use
    /// @param _tokenIn The input token for the pair
    /// @param _tokenOut The output token for the pair
    /// @param _targetAuctionPeriod The duration of auctions
    /// @param _targetAuctionPrice The initial auction price
    /// @param _smoothingFactor The degree of smoothing to apply to the available token balance
    /// @return The new liquidation pair
    function createPair(
        ILiquidationSource _source,
        address _tokenIn,
        address _tokenOut,
        uint64 _targetAuctionPeriod,
        uint192 _targetAuctionPrice,
        uint256 _smoothingFactor
    ) external returns (TpdaLiquidationPair) {
        TpdaLiquidationPair _liquidationPair = new TpdaLiquidationPair(
            _source,
            _tokenIn,
            _tokenOut,
            _targetAuctionPeriod,
            _targetAuctionPrice,
            _smoothingFactor
        );

        allPairs.push(_liquidationPair);
        deployedPairs[address(_liquidationPair)] = true;

        emit PairCreated(
            _liquidationPair,
            _source,
            _tokenIn,
            _tokenOut,
            _targetAuctionPeriod,
            _targetAuctionPrice,
            _smoothingFactor
        );

        return _liquidationPair;
    }

    /// @notice Total number of TpdaLiquidationPair deployed by this factory.
    /// @return Number of TpdaLiquidationPair deployed by this factory.
    function totalPairs() external view returns (uint256) {
        return allPairs.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { ILiquidationPair } from "pt-v5-liquidator-interfaces/ILiquidationPair.sol";
import { IFlashSwapCallback } from "pt-v5-liquidator-interfaces/IFlashSwapCallback.sol";

/// @notice Thrown when the actual swap amount in exceeds the user defined maximum amount in
/// @param amountInMax The user-defined max amount in
/// @param amountIn The actual amount in
error SwapExceedsMax(uint256 amountInMax, uint256 amountIn);

/// @notice Thrown when the amount out requested is greater than the available balance
/// @param requested The amount requested to swap
/// @param available The amount available to swap
error InsufficientBalance(uint256 requested, uint256 available);

/// @notice Thrown when the receiver of the swap is the zero address
error ReceiverIsZero();

/// @notice Thrown when the smoothing parameter is 1 or greater
error SmoothingGteOne();

// The minimum auction price. This ensures the auction cannot get bricked to zero.
uint192 constant MIN_PRICE = 100;

/// @title Target Period Dutch Auction Liquidation Pair
/// @author G9 Software Inc.
/// @notice This contract sells one token for another at a target time interval. The pricing algorithm is designed
/// such that the price of the auction is inversely proportional to the time since the last auction.
/// auctionPrice = (targetAuctionPeriod / elapsedTimeSinceLastAuction) * lastAuctionPrice
contract TpdaLiquidationPair is ILiquidationPair {

    /// @notice Emitted when a swap is made
    /// @param sender The sender of the swap
    /// @param receiver The receiver of the swap
    /// @param amountOut The amount of tokens out
    /// @param amountInMax The maximum amount of tokens in
    /// @param amountIn The actual amount of tokens in
    /// @param flashSwapData The data used for the flash swap
    event SwappedExactAmountOut(
        address indexed sender,
        address indexed receiver,
        uint256 amountOut,
        uint256 amountInMax,
        uint256 amountIn,
        bytes flashSwapData
    );

    /// @notice The liquidation source
    ILiquidationSource public immutable source;

    /// @notice The target time interval between auctions
    uint256 public immutable targetAuctionPeriod;

    /// @notice The token that is being purchased
    IERC20 internal immutable _tokenIn;

    /// @notice The token that is being sold
    IERC20 internal immutable _tokenOut;

    /// @notice The degree of smoothing to apply to the available token balance
    uint256 public immutable smoothingFactor;    

    /// @notice The time at which the last auction occurred
    uint64 public lastAuctionAt;

    /// @notice The price of the last auction
    uint192 public lastAuctionPrice;

    /// @notice Constructors a new TpdaLiquidationPair
    /// @param _source The liquidation source
    /// @param __tokenIn The token that is being purchased by the source
    /// @param __tokenOut The token that is being sold by the source
    /// @param _targetAuctionPeriod The target time interval between auctions
    /// @param _targetAuctionPrice The first target price of the auction
    /// @param _smoothingFactor The degree of smoothing to apply to the available token balance
    constructor (
        ILiquidationSource _source,
        address __tokenIn,
        address __tokenOut,
        uint64 _targetAuctionPeriod,
        uint192 _targetAuctionPrice,
        uint256 _smoothingFactor
    ) {
        if (_smoothingFactor >= 1e18) {
            revert SmoothingGteOne();
        }

        source = _source;
        _tokenIn = IERC20(__tokenIn);
        _tokenOut = IERC20(__tokenOut);
        targetAuctionPeriod = _targetAuctionPeriod;
        smoothingFactor = _smoothingFactor;

        lastAuctionAt = uint64(block.timestamp);
        lastAuctionPrice = _targetAuctionPrice;
    }

    /// @inheritdoc ILiquidationPair
    function tokenIn() external view returns (address) {
        return address(_tokenIn);
    }

    /// @inheritdoc ILiquidationPair
    function tokenOut() external view returns (address) {
        return address(_tokenOut);
    }

    /// @inheritdoc ILiquidationPair
    function target() external returns (address) {
        return source.targetOf(address(_tokenIn));
    }

    /// @inheritdoc ILiquidationPair
    function maxAmountOut() external returns (uint256) {  
        return _availableBalance();
    }

    /// @inheritdoc ILiquidationPair
    function swapExactAmountOut(
        address _receiver,
        uint256 _amountOut,
        uint256 _amountInMax,
        bytes calldata _flashSwapData
    ) external returns (uint256) {
        if (_receiver == address(0)) {
            revert ReceiverIsZero();
        }

        uint192 swapAmountIn = _computePrice();

        if (swapAmountIn > _amountInMax) {
            revert SwapExceedsMax(_amountInMax, swapAmountIn);
        }

        lastAuctionAt = uint64(block.timestamp);
        lastAuctionPrice = swapAmountIn;

        uint256 availableOut = _availableBalance();
        if (_amountOut > availableOut) {
            revert InsufficientBalance(_amountOut, availableOut);
        }

        bytes memory transferTokensOutData = source.transferTokensOut(
            msg.sender,
            _receiver,
            address(_tokenOut),
            _amountOut
        );

        if (_flashSwapData.length > 0) {
            IFlashSwapCallback(_receiver).flashSwapCallback(
                msg.sender,
                swapAmountIn,
                _amountOut,
                _flashSwapData
            );
        }

        source.verifyTokensIn(address(_tokenIn), swapAmountIn, transferTokensOutData);

        emit SwappedExactAmountOut(msg.sender, _receiver, _amountOut, _amountInMax, swapAmountIn, _flashSwapData);

        return swapAmountIn;
    }

    /// @inheritdoc ILiquidationPair
    function computeExactAmountIn(uint256) external view returns (uint256) {
        return _computePrice();
    }

    /// @notice Computes the time at which the given auction price will occur
    /// @param price The price of the auction
    /// @return The timestamp at which the given price will occur
    function computeTimeForPrice(uint256 price) external view returns (uint256) {
        // p2/p1 = t/e => e = (t*p1)/p2
        return lastAuctionAt + (targetAuctionPeriod * lastAuctionPrice) / price;
    }

    /// @notice Computes the available balance of the tokens to be sold
    /// @return The available balance of the tokens
    function _availableBalance() internal returns (uint256) {
        return ((1e18 - smoothingFactor) * source.liquidatableBalanceOf(address(_tokenOut))) / 1e18;
    }

    /// @notice Computes the current auction price
    /// @return The current auction price
    function _computePrice() internal view returns (uint192) {
        uint256 elapsedTime = block.timestamp - lastAuctionAt;
        if (elapsedTime == 0) {
            return type(uint192).max;
        }
        uint192 price = uint192((targetAuctionPeriod * lastAuctionPrice) / elapsedTime);

        if (price < MIN_PRICE) {
            price = MIN_PRICE;
        }

        return price;
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

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRewardSource {
    function rewardRecipient() external returns (address);
    function claimRewards() external;
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";

interface IPrizePool {
    function contributePrizeTokens(address _prizeVault, uint256 _amount) external returns (uint256);
    function prizeToken() external view returns (IERC20);
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
pragma solidity ^0.8.0;

import { ILiquidationSource } from "./ILiquidationSource.sol";

interface ILiquidationPair {

  /**
   * @notice The liquidation source that the pair is using.
   * @dev The source executes the actual token swap, while the pair handles the pricing.
   */
  function source() external returns (ILiquidationSource);

  /**
   * @notice Returns the token that is used to pay for auctions.
   * @return address of the token coming in
   */
  function tokenIn() external returns (address);

  /**
   * @notice Returns the token that is being auctioned.
   * @return address of the token coming out
   */
  function tokenOut() external returns (address);

  /**
   * @notice Get the address that will receive `tokenIn`.
   * @return Address of the target
   */
  function target() external returns (address);

  /**
   * @notice Gets the maximum amount of tokens that can be swapped out from the source.
   * @return The maximum amount of tokens that can be swapped out.
   */
  function maxAmountOut() external returns (uint256);

  /**
   * @notice Swaps the given amount of tokens out and ensures the amount of tokens in doesn't exceed the given maximum.
   * @dev The amount of tokens being swapped in must be sent to the target before calling this function.
   * @param _receiver The address to send the tokens to.
   * @param _amountOut The amount of tokens to receive out.
   * @param _amountInMax The maximum amount of tokens to send in.
   * @param _flashSwapData If non-zero, the _receiver is called with this data prior to
   * @return The amount of tokens sent in.
   */
  function swapExactAmountOut(
    address _receiver,
    uint256 _amountOut,
    uint256 _amountInMax,
    bytes calldata _flashSwapData
  ) external returns (uint256);

  /**
   * @notice Computes the exact amount of tokens to send in for the given amount of tokens to receive out.
   * @param _amountOut The amount of tokens to receive out.
   * @return The amount of tokens to send in.
   */
  function computeExactAmountIn(uint256 _amountOut) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Interface for the flash swap callback
interface IFlashSwapCallback {

    /// @notice Called on the token receiver by the LiquidationPair during a liquidation if the flashSwap data length is non-zero
    /// @param _sender The address that triggered the liquidation swap
    /// @param _amountOut The amount of tokens that were sent to the receiver
    /// @param _amountIn The amount of tokens expected to be sent to the target
    /// @param _flashSwapData The flash swap data that was passed into the swap function.
    function flashSwapCallback(
        address _sender,
        uint256 _amountIn,
        uint256 _amountOut,
        bytes calldata _flashSwapData
    ) external;
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