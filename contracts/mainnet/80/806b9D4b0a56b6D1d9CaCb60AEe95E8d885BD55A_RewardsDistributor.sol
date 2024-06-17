// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/// @title Interface a reward distributor.
interface IRewardDistributor is IERC165 {
    /// @notice Returns a human-readable name for the reward distributor
    function name() external returns (string memory);

    /// @notice This function should revert if ERC2771Context._msgSender() is not the Synthetix CoreProxy address.
    /// @return whether or not the payout was executed
    function payout(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address sender,
        uint256 amount
    ) external returns (bool);

    /// @notice This function is called by the Synthetix Core Proxy whenever
    /// a position is updated on a pool which this distributor is registered
    function onPositionUpdated(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 newShares
    ) external;

    /// @notice Address to ERC-20 token distributed by this distributor, for display purposes only
    /// @dev Return address(0) if providing non ERC-20 rewards
    function token() external returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for access related errors.
 */
library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for errors related with expected function parameters.
 */
library ParameterError {
    /**
     * @dev Thrown when an invalid parameter is used in a function.
     * @param parameter The name of the parameter.
     * @param reason The reason why the received parameter is invalid.
     */
    error InvalidParameter(string parameter, string reason);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC165 interface for determining if a contract supports a given interface.
 */
interface IERC165 {
    /**
     * @notice Determines if the contract in question supports the specified interface.
     * @param interfaceID XOR of all selectors in the contract.
     * @return True if the contract supports the specified interface.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC20 token implementation.
 */
interface IERC20 {
    /**
     * @notice Emitted when tokens have been transferred.
     * @param from The address that originally owned the tokens.
     * @param to The address that received the tokens.
     * @param amount The number of tokens that were transferred.
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice Emitted when a user has provided allowance to another user for transferring tokens on its behalf.
     * @param owner The address that is providing the allowance.
     * @param spender The address that received the allowance.
     * @param amount The number of tokens that were added to `spender`'s allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient allowance to transfer tokens from another contract.
     * @param required The necessary allowance.
     * @param existing The current allowance.
     */
    error InsufficientAllowance(uint required, uint existing);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient tokens.
     * @param required The necessary balance.
     * @param existing The current balance.
     */
    error InsufficientBalance(uint required, uint existing);

    /**
     * @notice Retrieves the name of the token, e.g. "Synthetix Network Token".
     * @return A string with the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieves the symbol of the token, e.g. "SNX".
     * @return A string with the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retrieves the number of decimals used by the token. The default is 18.
     * @return The number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the total number of tokens in circulation (minted - burnt).
     * @return The total number of tokens.
     */
    function totalSupply() external view returns (uint);

    /**
     * @notice Returns the balance of a user.
     * @param owner The address whose balance is being retrieved.
     * @return The number of tokens owned by the user.
     */
    function balanceOf(address owner) external view returns (uint);

    /**
     * @notice Returns how many tokens a user has allowed another user to transfer on its behalf.
     * @param owner The user who has given the allowance.
     * @param spender The user who was given the allowance.
     * @return The amount of tokens `spender` can transfer on `owner`'s behalf.
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @notice Transfer tokens from one address to another.
     * @param to The address that will receive the tokens.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean which is true if the operation succeeded.
     */
    function transfer(address to, uint amount) external returns (bool);

    /**
     * @notice Allows users to provide allowance to other users so that they can transfer tokens on their behalf.
     * @param spender The address that is receiving the allowance.
     * @param amount The amount of tokens that are being added to the allowance.
     * @return A boolean which is true if the operation succeeded.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @notice Allows a user who has been given allowance to transfer tokens on another user's behalf.
     * @param from The address that owns the tokens that are being transferred.
     * @param to The address that will receive the tokens.
     * @param amount The number of tokens to transfer.
     * @return A boolean which is true if the operation succeeded.
     */
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IERC20.sol";

library ERC20Helper {
    error FailedTransfer(address from, address to, uint value);

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert FailedTransfer(address(this), to, value);
        }
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert FailedTransfer(from, to, value);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IRewardDistributor} from "@synthetixio/main/contracts/interfaces/external/IRewardDistributor.sol";
import {AccessError} from "@synthetixio/core-contracts/contracts/errors/AccessError.sol";
import {ParameterError} from "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import {ERC20Helper} from "@synthetixio/core-contracts/contracts/token/ERC20Helper.sol";
import {IERC165} from "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";
import {IERC20} from "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";
import {ISynthetixCore} from "./interfaces/ISynthetixCore.sol";

contract RewardsDistributor is IRewardDistributor {
    error NotEnoughRewardsLeft(uint256 amountRequested, uint256 amountLeft);
    error NotEnoughBalance(uint256 amountRequested, uint256 currentBalance);

    using ERC20Helper for address;

    address public rewardManager;
    uint128 public poolId;
    address public collateralType;
    address public payoutToken;
    string public name;

    uint256 public precision;
    uint256 public constant SYSTEM_PRECISION = 10 ** 18;

    bool public shouldFailPayout;

    // Internal tracking for the remaining rewards, it keeps value in payoutToken precision
    uint256 public rewardsAmount = 0;

    constructor(
        address rewardManager_,
        uint128 poolId_,
        address collateralType_,
        address payoutToken_,
        uint8 payoutTokenDecimals_,
        string memory name_
    ) {
        rewardManager = rewardManager_; // Synthetix CoreProxy
        poolId = poolId_;
        collateralType = collateralType_;
        payoutToken = payoutToken_;
        name = name_;

        (bool success, bytes memory data) = payoutToken_.staticcall(
            abi.encodeWithSignature("decimals()")
        );

        if (success && data.length > 0 && abi.decode(data, (uint8)) != payoutTokenDecimals_) {
            revert ParameterError.InvalidParameter(
                "payoutTokenDecimals",
                "Specified token decimals do not match actual token decimals"
            );
        }
        // Fallback to the specified token decimals skipping the check if token does not support decimals method
        precision = 10 ** payoutTokenDecimals_;
    }

    function token() public view returns (address) {
        return payoutToken;
    }

    function setShouldFailPayout(bool shouldFailPayout_) external {
        if (msg.sender != ISynthetixCore(rewardManager).getPoolOwner(poolId)) {
            revert AccessError.Unauthorized(msg.sender);
        }
        shouldFailPayout = shouldFailPayout_;
    }

    function payout(
        uint128, // accountId,
        uint128 poolId_,
        address collateralType_,
        address payoutTarget_, // msg.sender of claimRewards() call, payout target address
        uint256 payoutAmount_
    ) external returns (bool) {
        if (shouldFailPayout) {
            return false;
        }
        // IMPORTANT: In production, this function should revert if msg.sender is not the Synthetix CoreProxy address.
        if (msg.sender != rewardManager) {
            revert AccessError.Unauthorized(msg.sender);
        }
        if (poolId_ != poolId) {
            revert ParameterError.InvalidParameter(
                "poolId",
                "Pool does not match the rewards pool"
            );
        }
        if (collateralType_ != collateralType) {
            revert ParameterError.InvalidParameter(
                "collateralType",
                "Collateral does not match the rewards token"
            );
        }

        // payoutAmount_ is always in 18 decimals precision, adjust actual payout amount to match payout token decimals
        uint256 adjustedAmount = (payoutAmount_ * precision) / SYSTEM_PRECISION;

        if (adjustedAmount > rewardsAmount) {
            revert NotEnoughRewardsLeft(adjustedAmount, rewardsAmount);
        }
        rewardsAmount = rewardsAmount - adjustedAmount;

        payoutToken.safeTransfer(payoutTarget_, adjustedAmount);

        return true;
    }

    function distributeRewards(
        uint128 poolId_,
        address collateralType_,
        uint256 amount_,
        uint64 start_,
        uint32 duration_
    ) public {
        if (msg.sender != ISynthetixCore(rewardManager).getPoolOwner(poolId)) {
            revert AccessError.Unauthorized(msg.sender);
        }
        if (poolId_ != poolId) {
            revert ParameterError.InvalidParameter(
                "poolId",
                "Pool does not match the rewards pool"
            );
        }
        if (collateralType_ != collateralType) {
            revert ParameterError.InvalidParameter(
                "collateralType",
                "Collateral does not match the rewards token"
            );
        }

        rewardsAmount = rewardsAmount + amount_;
        uint256 balance = IERC20(payoutToken).balanceOf(address(this));
        if (rewardsAmount > balance) {
            revert NotEnoughBalance(amount_, balance);
        }

        // amount_ is in payout token decimals precision, adjust actual distribution amount to 18 decimals that core is making its calculations in
        // this is necessary to avoid rounding issues when doing actual payouts
        uint256 adjustedAmount = (amount_ * SYSTEM_PRECISION) / precision;

        ISynthetixCore(rewardManager).distributeRewards(
            poolId_,
            collateralType_,
            adjustedAmount,
            start_,
            duration_
        );
    }

    function onPositionUpdated(
        uint128, // accountId,
        uint128, // poolId,
        address, // collateralType,
        uint256 // actorSharesD18
    ) external {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IRewardDistributor).interfaceId ||
            interfaceId == this.supportsInterface.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface ISynthetixCore {
    error ImplementationIsSterile(address implementation);
    error NoChange();
    error NotAContract(address contr);
    error NotNominated(address addr);
    error Unauthorized(address addr);
    error UpgradeSimulationFailed();
    error ZeroAddress();

    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerNominated(address newOwner);
    event Upgraded(address indexed self, address implementation);

    function acceptOwnership() external;
    function getImplementation() external view returns (address);
    function nominateNewOwner(address newNominatedOwner) external;
    function nominatedOwner() external view returns (address);
    function owner() external view returns (address);
    function renounceNomination() external;
    function simulateUpgradeTo(address newImplementation) external;
    function upgradeTo(address newImplementation) external;

    error ValueAlreadyInSet();
    error ValueNotInSet();

    event FeatureFlagAllowAllSet(bytes32 indexed feature, bool allowAll);
    event FeatureFlagAllowlistAdded(bytes32 indexed feature, address account);
    event FeatureFlagAllowlistRemoved(bytes32 indexed feature, address account);
    event FeatureFlagDeniersReset(bytes32 indexed feature, address[] deniers);
    event FeatureFlagDenyAllSet(bytes32 indexed feature, bool denyAll);

    function addToFeatureFlagAllowlist(bytes32 feature, address account) external;
    function getDeniers(bytes32 feature) external view returns (address[] memory);
    function getFeatureFlagAllowAll(bytes32 feature) external view returns (bool);
    function getFeatureFlagAllowlist(bytes32 feature) external view returns (address[] memory);
    function getFeatureFlagDenyAll(bytes32 feature) external view returns (bool);
    function isFeatureAllowed(bytes32 feature, address account) external view returns (bool);
    function removeFromFeatureFlagAllowlist(bytes32 feature, address account) external;
    function setDeniers(bytes32 feature, address[] memory deniers) external;
    function setFeatureFlagAllowAll(bytes32 feature, bool allowAll) external;
    function setFeatureFlagDenyAll(bytes32 feature, bool denyAll) external;

    error FeatureUnavailable(bytes32 which);
    error InvalidAccountId(uint128 accountId);
    error InvalidPermission(bytes32 permission);
    error OnlyAccountTokenProxy(address origin);
    error PermissionDenied(uint128 accountId, bytes32 permission, address target);
    error PermissionNotGranted(uint128 accountId, bytes32 permission, address user);
    error PositionOutOfBounds();

    event AccountCreated(uint128 indexed accountId, address indexed owner);
    event PermissionGranted(
        uint128 indexed accountId,
        bytes32 indexed permission,
        address indexed user,
        address sender
    );
    event PermissionRevoked(
        uint128 indexed accountId,
        bytes32 indexed permission,
        address indexed user,
        address sender
    );

    function createAccount() external returns (uint128 accountId);
    function createAccount(uint128 requestedAccountId) external;
    function getAccountLastInteraction(uint128 accountId) external view returns (uint256);
    function getAccountOwner(uint128 accountId) external view returns (address);
    function getAccountPermissions(
        uint128 accountId
    ) external view returns (IAccountModule.AccountPermissions[] memory accountPerms);
    function getAccountTokenAddress() external view returns (address);
    function grantPermission(uint128 accountId, bytes32 permission, address user) external;
    function hasPermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external view returns (bool);
    function isAuthorized(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external view returns (bool);
    function notifyAccountTransfer(address to, uint128 accountId) external;
    function renouncePermission(uint128 accountId, bytes32 permission) external;
    function revokePermission(uint128 accountId, bytes32 permission, address user) external;

    error AccountNotFound(uint128 accountId);
    error EmptyDistribution();
    error InsufficientCollateralRatio(
        uint256 collateralValue,
        uint256 debt,
        uint256 ratio,
        uint256 minRatio
    );
    error MarketNotFound(uint128 marketId);
    error NotFundedByPool(uint256 marketId, uint256 poolId);
    error OverflowInt256ToInt128();
    error OverflowInt256ToUint256();
    error OverflowUint128ToInt128();
    error OverflowUint256ToInt256();
    error OverflowUint256ToUint128();

    event DebtAssociated(
        uint128 indexed marketId,
        uint128 indexed poolId,
        address indexed collateralType,
        uint128 accountId,
        uint256 amount,
        int256 updatedDebt
    );

    function associateDebt(
        uint128 marketId,
        uint128 poolId,
        address collateralType,
        uint128 accountId,
        uint256 amount
    ) external returns (int256);

    error MismatchAssociatedSystemKind(bytes32 expected, bytes32 actual);
    error MissingAssociatedSystem(bytes32 id);

    event AssociatedSystemSet(
        bytes32 indexed kind,
        bytes32 indexed id,
        address proxy,
        address impl
    );

    function getAssociatedSystem(bytes32 id) external view returns (address addr, bytes32 kind);
    function initOrUpgradeNft(
        bytes32 id,
        string memory name,
        string memory symbol,
        string memory uri,
        address impl
    ) external;
    function initOrUpgradeToken(
        bytes32 id,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address impl
    ) external;
    function registerUnmanagedSystem(bytes32 id, address endpoint) external;

    error InvalidMessage();
    error NotCcipRouter(address);
    error UnsupportedNetwork(uint64);

    function ccipReceive(CcipClient.Any2EVMMessage memory message) external;

    error AccountActivityTimeoutPending(
        uint128 accountId,
        uint256 currentTime,
        uint256 requiredTime
    );
    error CollateralDepositDisabled(address collateralType);
    error CollateralNotFound();
    error FailedTransfer(address from, address to, uint256 value);
    error InsufficentAvailableCollateral(
        uint256 amountAvailableForDelegationD18,
        uint256 amountD18
    );
    error InsufficientAccountCollateral(uint256 amount);
    error InsufficientAllowance(uint256 required, uint256 existing);
    error InvalidParameter(string parameter, string reason);
    error OverflowUint256ToUint64();
    error PrecisionLost(uint256 tokenAmount, uint8 decimals);

    event CollateralLockCreated(
        uint128 indexed accountId,
        address indexed collateralType,
        uint256 tokenAmount,
        uint64 expireTimestamp
    );
    event CollateralLockExpired(
        uint128 indexed accountId,
        address indexed collateralType,
        uint256 tokenAmount,
        uint64 expireTimestamp
    );
    event Deposited(
        uint128 indexed accountId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender
    );
    event Withdrawn(
        uint128 indexed accountId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender
    );

    function cleanExpiredLocks(
        uint128 accountId,
        address collateralType,
        uint256 offset,
        uint256 count
    ) external returns (uint256 cleared);
    function createLock(
        uint128 accountId,
        address collateralType,
        uint256 amount,
        uint64 expireTimestamp
    ) external;
    function deposit(uint128 accountId, address collateralType, uint256 tokenAmount) external;
    function getAccountAvailableCollateral(
        uint128 accountId,
        address collateralType
    ) external view returns (uint256);
    function getAccountCollateral(
        uint128 accountId,
        address collateralType
    ) external view returns (uint256 totalDeposited, uint256 totalAssigned, uint256 totalLocked);
    function getLocks(
        uint128 accountId,
        address collateralType,
        uint256 offset,
        uint256 count
    ) external view returns (CollateralLock.Data[] memory locks);
    function withdraw(uint128 accountId, address collateralType, uint256 tokenAmount) external;

    event CollateralConfigured(address indexed collateralType, CollateralConfiguration.Data config);

    function configureCollateral(CollateralConfiguration.Data memory config) external;
    function getCollateralConfiguration(
        address collateralType
    ) external pure returns (CollateralConfiguration.Data memory);
    function getCollateralConfigurations(
        bool hideDisabled
    ) external view returns (CollateralConfiguration.Data[] memory);
    function getCollateralPrice(address collateralType) external view returns (uint256);

    error InsufficientCcipFee(uint256 requiredAmount, uint256 availableAmount);

    event TransferCrossChainInitiated(
        uint64 indexed destChainId,
        uint256 indexed amount,
        address sender
    );

    function transferCrossChain(
        uint64 destChainId,
        uint256 amount
    ) external payable returns (uint256 gasTokenUsed);

    error InsufficientDebt(int256 currentDebt);
    error PoolNotFound(uint128 poolId);

    event IssuanceFeePaid(
        uint128 indexed accountId,
        uint128 indexed poolId,
        address collateralType,
        uint256 feeAmount
    );
    event UsdBurned(
        uint128 indexed accountId,
        uint128 indexed poolId,
        address collateralType,
        uint256 amount,
        address indexed sender
    );
    event UsdMinted(
        uint128 indexed accountId,
        uint128 indexed poolId,
        address collateralType,
        uint256 amount,
        address indexed sender
    );

    function burnUsd(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 amount
    ) external;
    function mintUsd(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 amount
    ) external;

    error CannotScaleEmptyMapping();
    error IneligibleForLiquidation(
        uint256 collateralValue,
        int256 debt,
        uint256 currentCRatio,
        uint256 cratio
    );
    error InsufficientMappedAmount();
    error MustBeVaultLiquidated();
    error OverflowInt128ToUint128();

    event Liquidation(
        uint128 indexed accountId,
        uint128 indexed poolId,
        address indexed collateralType,
        ILiquidationModule.LiquidationData liquidationData,
        uint128 liquidateAsAccountId,
        address sender
    );
    event VaultLiquidation(
        uint128 indexed poolId,
        address indexed collateralType,
        ILiquidationModule.LiquidationData liquidationData,
        uint128 liquidateAsAccountId,
        address sender
    );

    function isPositionLiquidatable(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) external returns (bool);
    function isVaultLiquidatable(uint128 poolId, address collateralType) external returns (bool);
    function liquidate(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint128 liquidateAsAccountId
    ) external returns (ILiquidationModule.LiquidationData memory liquidationData);
    function liquidateVault(
        uint128 poolId,
        address collateralType,
        uint128 liquidateAsAccountId,
        uint256 maxUsd
    ) external returns (ILiquidationModule.LiquidationData memory liquidationData);

    error InsufficientMarketCollateralDepositable(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmountToDeposit
    );
    error InsufficientMarketCollateralWithdrawable(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmountToWithdraw
    );

    event MarketCollateralDeposited(
        uint128 indexed marketId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender,
        int128 creditCapacity,
        int128 netIssuance,
        uint256 depositedCollateralValue,
        uint256 reportedDebt
    );
    event MarketCollateralWithdrawn(
        uint128 indexed marketId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender,
        int128 creditCapacity,
        int128 netIssuance,
        uint256 depositedCollateralValue,
        uint256 reportedDebt
    );
    event MaximumMarketCollateralConfigured(
        uint128 indexed marketId,
        address indexed collateralType,
        uint256 systemAmount,
        address indexed owner
    );

    function configureMaximumMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 amount
    ) external;
    function depositMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmount
    ) external;
    function getMarketCollateralAmount(
        uint128 marketId,
        address collateralType
    ) external view returns (uint256 collateralAmountD18);
    function getMarketCollateralValue(uint128 marketId) external view returns (uint256);
    function getMaximumMarketCollateral(
        uint128 marketId,
        address collateralType
    ) external view returns (uint256);
    function withdrawMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmount
    ) external;

    error IncorrectMarketInterface(address market);
    error NotEnoughLiquidity(uint128 marketId, uint256 amount);

    event MarketRegistered(
        address indexed market,
        uint128 indexed marketId,
        address indexed sender
    );
    event MarketSystemFeePaid(uint128 indexed marketId, uint256 feeAmount);
    event MarketUsdDeposited(
        uint128 indexed marketId,
        address indexed target,
        uint256 amount,
        address indexed market,
        int128 creditCapacity,
        int128 netIssuance,
        uint256 depositedCollateralValue,
        uint256 reportedDebt
    );
    event MarketUsdWithdrawn(
        uint128 indexed marketId,
        address indexed target,
        uint256 amount,
        address indexed market,
        int128 creditCapacity,
        int128 netIssuance,
        uint256 depositedCollateralValue,
        uint256 reportedDebt
    );
    event SetMarketMinLiquidityRatio(uint128 indexed marketId, uint256 minLiquidityRatio);
    event SetMinDelegateTime(uint128 indexed marketId, uint32 minDelegateTime);

    function depositMarketUsd(
        uint128 marketId,
        address target,
        uint256 amount
    ) external returns (uint256 feeAmount);
    function distributeDebtToPools(uint128 marketId, uint256 maxIter) external returns (bool);
    function getMarketAddress(uint128 marketId) external view returns (address);
    function getMarketCollateral(uint128 marketId) external view returns (uint256);
    function getMarketDebtPerShare(uint128 marketId) external returns (int256);
    function getMarketFees(
        uint128,
        uint256 amount
    ) external view returns (uint256 depositFeeAmount, uint256 withdrawFeeAmount);
    function getMarketMinDelegateTime(uint128 marketId) external view returns (uint32);
    function getMarketNetIssuance(uint128 marketId) external view returns (int128);
    function getMarketPoolDebtDistribution(
        uint128 marketId,
        uint128 poolId
    ) external returns (uint256 sharesD18, uint128 totalSharesD18, int128 valuePerShareD27);
    function getMarketPools(
        uint128 marketId
    ) external returns (uint128[] memory inRangePoolIds, uint128[] memory outRangePoolIds);
    function getMarketReportedDebt(uint128 marketId) external view returns (uint256);
    function getMarketTotalDebt(uint128 marketId) external view returns (int256);
    function getMinLiquidityRatio(uint128 marketId) external view returns (uint256);
    function getOracleManager() external view returns (address);
    function getUsdToken() external view returns (address);
    function getWithdrawableMarketUsd(uint128 marketId) external view returns (uint256);
    function isMarketCapacityLocked(uint128 marketId) external view returns (bool);
    function registerMarket(address market) external returns (uint128 marketId);
    function setMarketMinDelegateTime(uint128 marketId, uint32 minDelegateTime) external;
    function setMinLiquidityRatio(uint128 marketId, uint256 minLiquidityRatio) external;
    function withdrawMarketUsd(
        uint128 marketId,
        address target,
        uint256 amount
    ) external returns (uint256 feeAmount);

    error DeniedMulticallTarget(address);
    error RecursiveMulticall(address);

    function multicall(bytes[] memory data) external returns (bytes[] memory results);

    event PoolApprovedAdded(uint256 poolId);
    event PoolApprovedRemoved(uint256 poolId);
    event PreferredPoolSet(uint256 poolId);

    function addApprovedPool(uint128 poolId) external;
    function getApprovedPools() external view returns (uint256[] memory);
    function getPreferredPool() external view returns (uint128);
    function removeApprovedPool(uint128 poolId) external;
    function setPreferredPool(uint128 poolId) external;

    error CapacityLocked(uint256 marketId);
    error MinDelegationTimeoutPending(uint128 poolId, uint32 timeRemaining);
    error PoolAlreadyExists(uint128 poolId);

    event PoolCollateralConfigurationUpdated(
        uint128 indexed poolId,
        address collateralType,
        PoolCollateralConfiguration.Data config
    );
    event PoolCollateralDisabledByDefaultSet(uint128 poolId, bool disabled);
    event PoolConfigurationSet(
        uint128 indexed poolId,
        MarketConfiguration.Data[] markets,
        address indexed sender
    );
    event PoolCreated(uint128 indexed poolId, address indexed owner, address indexed sender);
    event PoolNameUpdated(uint128 indexed poolId, string name, address indexed sender);
    event PoolNominationRenounced(uint128 indexed poolId, address indexed owner);
    event PoolNominationRevoked(uint128 indexed poolId, address indexed owner);
    event PoolOwnerNominated(
        uint128 indexed poolId,
        address indexed nominatedOwner,
        address indexed owner
    );
    event PoolOwnershipAccepted(uint128 indexed poolId, address indexed owner);
    event SetMinLiquidityRatio(uint256 minLiquidityRatio);

    function acceptPoolOwnership(uint128 poolId) external;
    function createPool(uint128 requestedPoolId, address owner) external;
    function getMinLiquidityRatio() external view returns (uint256);
    function getNominatedPoolOwner(uint128 poolId) external view returns (address);
    function getPoolCollateralConfiguration(
        uint128 poolId,
        address collateralType
    ) external view returns (PoolCollateralConfiguration.Data memory config);
    function getPoolCollateralIssuanceRatio(
        uint128 poolId,
        address collateral
    ) external view returns (uint256);
    function getPoolConfiguration(
        uint128 poolId
    ) external view returns (MarketConfiguration.Data[] memory);
    function getPoolName(uint128 poolId) external view returns (string memory poolName);
    function getPoolOwner(uint128 poolId) external view returns (address);
    function nominatePoolOwner(address nominatedOwner, uint128 poolId) external;
    function rebalancePool(uint128 poolId, address optionalCollateralType) external;
    function renouncePoolNomination(uint128 poolId) external;
    function revokePoolNomination(uint128 poolId) external;
    function setMinLiquidityRatio(uint256 minLiquidityRatio) external;
    function setPoolCollateralConfiguration(
        uint128 poolId,
        address collateralType,
        PoolCollateralConfiguration.Data memory newConfig
    ) external;
    function setPoolCollateralDisabledByDefault(uint128 poolId, bool disabled) external;
    function setPoolConfiguration(
        uint128 poolId,
        MarketConfiguration.Data[] memory newMarketConfigurations
    ) external;
    function setPoolName(uint128 poolId, string memory name) external;

    error OverflowUint256ToUint32();
    error OverflowUint32ToInt32();
    error OverflowUint64ToInt64();
    error RewardDistributorNotFound();
    error RewardUnavailable(address distributor);

    event RewardsClaimed(
        uint128 indexed accountId,
        uint128 indexed poolId,
        address indexed collateralType,
        address distributor,
        uint256 amount
    );
    event RewardsDistributed(
        uint128 indexed poolId,
        address indexed collateralType,
        address distributor,
        uint256 amount,
        uint256 start,
        uint256 duration
    );
    event RewardsDistributorRegistered(
        uint128 indexed poolId,
        address indexed collateralType,
        address indexed distributor
    );
    event RewardsDistributorRemoved(
        uint128 indexed poolId,
        address indexed collateralType,
        address indexed distributor
    );

    function claimRewards(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address distributor
    ) external returns (uint256);
    function distributeRewards(
        uint128 poolId,
        address collateralType,
        uint256 amount,
        uint64 start,
        uint32 duration
    ) external;
    function getRewardRate(
        uint128 poolId,
        address collateralType,
        address distributor
    ) external view returns (uint256);
    function registerRewardsDistributor(
        uint128 poolId,
        address collateralType,
        address distributor
    ) external;
    function removeRewardsDistributor(
        uint128 poolId,
        address collateralType,
        address distributor
    ) external;
    function updateRewards(
        uint128 poolId,
        address collateralType,
        uint128 accountId
    ) external returns (uint256[] memory, address[] memory);

    event NewSupportedCrossChainNetwork(uint64 newChainId);

    function configureChainlinkCrossChain(address ccipRouter, address ccipTokenPool) external;
    function configureOracleManager(address oracleManagerAddress) external;
    function getConfig(bytes32 k) external view returns (bytes32 v);
    function getConfigAddress(bytes32 k) external view returns (address v);
    function getConfigUint(bytes32 k) external view returns (uint256 v);
    function getTrustedForwarder() external pure returns (address);
    function isTrustedForwarder(address forwarder) external pure returns (bool);
    function setConfig(bytes32 k, bytes32 v) external;
    function setSupportedCrossChainNetworks(
        uint64[] memory supportedNetworks,
        uint64[] memory ccipSelectors
    ) external returns (uint256 numRegistered);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    error InsufficientDelegation(uint256 minDelegation);
    error InvalidCollateralAmount();
    error InvalidLeverage(uint256 leverage);
    error PoolCollateralLimitExceeded(
        uint128 poolId,
        address collateralType,
        uint256 currentCollateral,
        uint256 maxCollateral
    );

    event DelegationUpdated(
        uint128 indexed accountId,
        uint128 indexed poolId,
        address collateralType,
        uint256 amount,
        uint256 leverage,
        address indexed sender
    );

    function delegateCollateral(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 newCollateralAmountD18,
        uint256 leverage
    ) external;
    function getPosition(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    )
        external
        returns (
            uint256 collateralAmount,
            uint256 collateralValue,
            int256 debt,
            uint256 collateralizationRatio
        );
    function getPositionCollateral(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) external view returns (uint256 amount);
    function getPositionCollateralRatio(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) external returns (uint256);
    function getPositionDebt(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) external returns (int256 debt);
    function getVaultCollateral(
        uint128 poolId,
        address collateralType
    ) external view returns (uint256 amount, uint256 value);
    function getVaultCollateralRatio(
        uint128 poolId,
        address collateralType
    ) external returns (uint256);
    function getVaultDebt(uint128 poolId, address collateralType) external returns (int256);
}

interface IAccountModule {
    struct AccountPermissions {
        address user;
        bytes32[] permissions;
    }
}

interface CcipClient {
    struct EVMTokenAmount {
        address token;
        uint256 amount;
    }

    struct Any2EVMMessage {
        bytes32 messageId;
        uint64 sourceChainSelector;
        bytes sender;
        bytes data;
        EVMTokenAmount[] tokenAmounts;
    }
}

interface CollateralLock {
    struct Data {
        uint128 amountD18;
        uint64 lockExpirationTime;
    }
}

interface CollateralConfiguration {
    struct Data {
        bool depositingEnabled;
        uint256 issuanceRatioD18;
        uint256 liquidationRatioD18;
        uint256 liquidationRewardD18;
        bytes32 oracleNodeId;
        address tokenAddress;
        uint256 minDelegationD18;
    }
}

interface ILiquidationModule {
    struct LiquidationData {
        uint256 debtLiquidated;
        uint256 collateralLiquidated;
        uint256 amountRewarded;
    }
}

interface PoolCollateralConfiguration {
    struct Data {
        uint256 collateralLimitD18;
        uint256 issuanceRatioD18;
    }
}

interface MarketConfiguration {
    struct Data {
        uint128 marketId;
        uint128 weightD18;
        int128 maxDebtShareValueD18;
    }
}