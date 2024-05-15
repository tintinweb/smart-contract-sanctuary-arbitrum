// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./external/interfaces/weth/IWETH9.sol";
import "./interfaces/IAssetGroupRegistry.sol";
import "./interfaces/IDepositManager.sol";
import "./interfaces/IDepositSwap.sol";
import "./interfaces/ISmartVaultManager.sol";
import "./interfaces/ISwapper.sol";
import "./interfaces/CommonErrors.sol";

/**
 * @dev Requires roles:
 * - ROLE_SWAPPER
 */
contract DepositSwap is IDepositSwap {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IWETH9 private immutable _weth;
    IAssetGroupRegistry private immutable _assetGroupRegistry;
    ISmartVaultManager private immutable _smartVaultManager;
    ISwapper private immutable _swapper;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IWETH9 weth_,
        IAssetGroupRegistry assetGroupRegistry_,
        ISmartVaultManager smartVaultManager_,
        ISwapper swapper_
    ) {
        if (address(weth_) == address(0)) revert ConfigurationAddressZero();
        if (address(assetGroupRegistry_) == address(0)) revert ConfigurationAddressZero();
        if (address(smartVaultManager_) == address(0)) revert ConfigurationAddressZero();
        if (address(swapper_) == address(0)) revert ConfigurationAddressZero();

        _weth = weth_;
        _assetGroupRegistry = assetGroupRegistry_;
        _smartVaultManager = smartVaultManager_;
        _swapper = swapper_;
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    function swapAndDeposit(SwapDepositBag calldata swapDepositBag) external payable returns (uint256 nftId) {
        if (swapDepositBag.inTokens.length != swapDepositBag.inAmounts.length) revert InvalidArrayLength();
        uint256 msgValue = msg.value;

        // Wrap eth if needed.
        if (msg.value > 0) {
            _weth.deposit{value: msgValue}();
        }

        // Transfer the tokens from the caller to the swapper.
        for (uint256 i; i < swapDepositBag.inTokens.length; ++i) {
            IERC20(swapDepositBag.inTokens[i]).safeTransferFrom(
                msg.sender, address(_swapper), swapDepositBag.inAmounts[i]
            );

            if (swapDepositBag.inTokens[i] == address(_weth) && msgValue > 0) {
                IERC20(address(_weth)).safeTransfer(address(_swapper), msgValue);
            }
        }

        {
            address[] memory outTokens =
                _assetGroupRegistry.listAssetGroup(_smartVaultManager.assetGroupId(swapDepositBag.smartVault));
            // Make the swap.
            _swapper.swap(swapDepositBag.inTokens, swapDepositBag.swapInfo, outTokens, address(this));
            uint256[] memory outAmounts = new uint256[](outTokens.length);
            // Figure out how much we got out of the swap.
            for (uint256 i; i < outTokens.length; ++i) {
                outAmounts[i] = IERC20(outTokens[i]).balanceOf(address(this));
                IERC20(outTokens[i]).safeApprove(address(_smartVaultManager), outAmounts[i]);
            }

            // Deposit into the smart vault.
            nftId = _smartVaultManager.deposit(
                DepositBag(
                    swapDepositBag.smartVault,
                    outAmounts,
                    swapDepositBag.receiver,
                    swapDepositBag.referral,
                    swapDepositBag.doFlush
                )
            );
        }

        // Return unswapped tokens.
        uint256 returnBalance;
        for (uint256 i; i < swapDepositBag.inTokens.length; ++i) {
            returnBalance = IERC20(swapDepositBag.inTokens[i]).balanceOf(address(this));
            if (returnBalance > 0) {
                IERC20(swapDepositBag.inTokens[i]).safeTransfer(msg.sender, returnBalance);
            }
        }
        if (msg.value > 0) {
            returnBalance = IERC20(address(_weth)).balanceOf(address(this));
            if (returnBalance > 0) {
                IERC20(address(_weth)).safeTransfer(msg.sender, returnBalance);
            }
        }

        // send back eth if swapper returns eth
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address dst, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/token/ERC20/IERC20.sol";

/* ========== ERRORS ========== */

/**
 * @notice Used when invalid ID for asset group is provided.
 * @param assetGroupId Invalid ID for asset group.
 */
error InvalidAssetGroup(uint256 assetGroupId);

/**
 * @notice Used when no assets are provided for an asset group.
 */
error NoAssetsProvided();

/**
 * @notice Used when token is not allowed to be used as an asset.
 * @param token Address of the token that is not allowed.
 */
error TokenNotAllowed(address token);

/**
 * @notice Used when asset group already exists.
 * @param assetGroupId ID of the already existing asset group.
 */
error AssetGroupAlreadyExists(uint256 assetGroupId);

/**
 * @notice Used when given array is unsorted.
 */
error UnsortedArray();

/* ========== INTERFACES ========== */

interface IAssetGroupRegistry {
    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when token is allowed to be used as an asset.
     * @param token Address of newly allowed token.
     */
    event TokenAllowed(address indexed token);

    /**
     * @notice Emitted when asset group is registered.
     * @param assetGroupId ID of the newly registered asset group.
     */
    event AssetGroupRegistered(uint256 indexed assetGroupId);

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Checks if token is allowed to be used as an asset.
     * @param token Address of token to check.
     * @return isAllowed True if token is allowed, false otherwise.
     */
    function isTokenAllowed(address token) external view returns (bool isAllowed);

    /**
     * @notice Gets number of registered asset groups.
     * @return count Number of registered asset groups.
     */
    function numberOfAssetGroups() external view returns (uint256 count);

    /**
     * @notice Gets asset group by its ID.
     * @dev Requirements:
     * - must provide a valid ID for the asset group
     * @return assets Array of assets in the asset group.
     */
    function listAssetGroup(uint256 assetGroupId) external view returns (address[] memory assets);

    /**
     * @notice Gets asset group length.
     * @dev Requirements:
     * - must provide a valid ID for the asset group
     * @return length
     */
    function assetGroupLength(uint256 assetGroupId) external view returns (uint256 length);

    /**
     * @notice Validates that provided ID represents an asset group.
     * @dev Function reverts when ID does not represent an asset group.
     * @param assetGroupId ID to validate.
     */
    function validateAssetGroup(uint256 assetGroupId) external view;

    /**
     * @notice Checks if asset group composed of assets already exists.
     * Will revert if provided assets cannot form an asset group.
     * @param assets Assets composing the asset group.
     * @return Asset group ID if such asset group exists, 0 otherwise.
     */
    function checkAssetGroupExists(address[] calldata assets) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Allows a token to be used as an asset.
     * @dev Requirements:
     * - can only be called by the ROLE_SPOOL_ADMIN
     * @param token Address of token to be allowed.
     */
    function allowToken(address token) external;

    /**
     * @notice Allows tokens to be used as assets.
     * @dev Requirements:
     * - can only be called by the ROLE_SPOOL_ADMIN
     * @param tokens Addresses of tokens to be allowed.
     */
    function allowTokenBatch(address[] calldata tokens) external;

    /**
     * @notice Registers a new asset group.
     * @dev Requirements:
     * - must provide at least one asset
     * - all assets must be allowed
     * - assets must be sorted
     * - such asset group should not exist yet
     * - can only be called by the ROLE_SPOOL_ADMIN
     * @param assets Array of assets in the asset group.
     * @return id Sequential ID assigned to the asset group.
     */
    function registerAssetGroup(address[] calldata assets) external returns (uint256 id);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./ISmartVault.sol";
import "../libraries/uint16a16Lib.sol";

/**
 * @notice Used when deposited assets are not the same length as underlying assets.
 */
error InvalidAssetLengths();

/**
 * @notice Used when lengths of NFT id and amount arrays when claiming NFTs don't match.
 */
error InvalidNftArrayLength();

/**
 * @notice Used when there are no pending deposits to recover.
 * E.g., they were already recovered or flushed.
 */
error NoDepositsToRecover();

/**
 * @notice Used when trying to recover pending deposits from a smart vault that has non-ghost strategies.
 */
error NotGhostVault();

/**
 * @notice Gathers input for depositing assets.
 * @custom:member smartVault Smart vault for which the deposit is made.
 * @custom:member assets Amounts of assets being deposited.
 * @custom:member receiver Receiver of the deposit NFT.
 * @custom:member referral Referral address.
 * @custom:member doFlush If true, the smart vault will be flushed after the deposit as part of same transaction.
 */
struct DepositBag {
    address smartVault;
    uint256[] assets;
    address receiver;
    address referral;
    bool doFlush;
}

/**
 * @notice Gathers extra input for depositing assets.
 * @custom:member depositor Address making the deposit.
 * @custom:member tokens Tokens of the smart vault.
 * @custom:member strategies Strategies of the smart vault.
 * @custom:member allocations Set allocation of funds between strategies.
 * @custom:member flushIndex Current flush index of the smart vault.
 */
struct DepositExtras {
    address depositor;
    address[] tokens;
    address[] strategies;
    uint16a16 allocations;
    uint256 flushIndex;
}

/**
 * @notice Gathers minted SVTs for a specific fee type.
 * @custom:member depositFees Minted SVTs for deposit fees.
 * @custom:member performanceFees Minted SVTs for performance fees.
 * @custom:member managementFees Minted SVTs for management fees.
 */
struct SmartVaultFeesCollected {
    uint256 depositFees;
    uint256 performanceFees;
    uint256 managementFees;
}

/**
 * @notice Gathers return values of syncing deposits.
 * @custom:member mintedSVTs Amount of SVTs minted.
 * @custom:member dhwTimestamp Timestamp of the last DHW synced.
 * @custom:member feeSVTs Amount of SVTs minted as fees.
 * @custom:member feesCollected Breakdown of amount of SVTs minted as fees.
 * @custom:member initialLockedSVTs Amount of initial locked SVTs.
 * @custom:member sstShares Amount of SSTs claimed for each strategy.
 */
struct DepositSyncResult {
    uint256 mintedSVTs;
    uint256 dhwTimestamp;
    uint256 feeSVTs;
    SmartVaultFeesCollected feesCollected;
    uint256 initialLockedSVTs;
    uint256[] sstShares;
}

/**
 * @custom:member smartVault Smart Vault address
 * @custom:member bag flush index, lastDhwSyncedTimestamp
 * @custom:member strategies strategy addresses
 * @custom:member assetGroup vault asset group token addresses
 * @custom:member dhwIndexes DHW Indexes for given flush index
 * @custom:member dhwIndexesOld DHW Indexes for previous flush index
 * @custom:member fees smart vault fee configuration
 * @return syncResult Result of the smart vault sync.
 */
struct SimulateDepositParams {
    address smartVault;
    // bag[0]: flushIndex,
    // bag[1]: lastDhwSyncedTimestamp,
    uint256[2] bag;
    address[] strategies;
    address[] assetGroup;
    uint16a16 dhwIndexes;
    uint16a16 dhwIndexesOld;
    SmartVaultFees fees;
}

interface IDepositManager {
    /**
     * @notice User redeemed deposit NFTs for SVTs
     * @param smartVault Smart vault address
     * @param claimer Claimer address
     * @param claimedVaultTokens Amount of SVTs claimed
     * @param nftIds NFTs to burn
     * @param nftAmounts NFT shares to burn
     */
    event SmartVaultTokensClaimed(
        address indexed smartVault,
        address indexed claimer,
        uint256 claimedVaultTokens,
        uint256[] nftIds,
        uint256[] nftAmounts
    );

    /**
     * @notice A deposit has been initiated
     * @param smartVault Smart vault address
     * @param receiver Beneficiary of the deposit
     * @param depositId Deposit NFT ID for this deposit
     * @param flushIndex Flush index the deposit was scheduled for
     * @param assets Amount of assets to deposit
     * @param depositor Address that initiated the deposit
     * @param referral Referral address
     */
    event DepositInitiated(
        address indexed smartVault,
        address indexed receiver,
        uint256 indexed depositId,
        uint256 flushIndex,
        uint256[] assets,
        address depositor,
        address referral
    );

    /**
     * @notice Pending deposits were recovered.
     * @param smartVault Smart vault address.
     * @param recoveredAssets Amount of assets recovered.
     */
    event PendingDepositsRecovered(address indexed smartVault, uint256[] recoveredAssets);

    /**
     * @notice Smart vault fees collected.
     * @param smartVault Smart vault address.
     * @param smartVaultFeesCollected Collected smart vault fee amounts.
     */
    event SmartVaultFeesMinted(address indexed smartVault, SmartVaultFeesCollected smartVaultFeesCollected);

    /**
     * @notice Simulate vault synchronization (i.e. DHW was completed, but vault wasn't synced yet)
     */
    function syncDepositsSimulate(SimulateDepositParams calldata parameters)
        external
        view
        returns (DepositSyncResult memory syncResult);

    /**
     * @notice Synchronize vault deposits for completed DHW runs
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart Vault address
     * @param bag flushIndex, lastDhwSyncedTimestamp
     * @param strategies vault strategy addresses
     * @param dhwIndexes dhw indexes for given and previous flushIndex
     * @param assetGroup vault asset group token addresses
     * @param fees smart vault fee configuration
     * @return syncResult Result of the smart vault sync.
     */
    function syncDeposits(
        address smartVault,
        uint256[2] calldata bag,
        // uint256 flushIndex,
        // uint256 lastDhwSyncedTimestamp
        address[] calldata strategies,
        uint16a16[2] calldata dhwIndexes,
        address[] calldata assetGroup,
        SmartVaultFees calldata fees
    ) external returns (DepositSyncResult memory syncResult);

    /**
     * @notice Adds deposits for the next flush cycle.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param bag Deposit parameters.
     * @param bag2 Extra parameters.
     * @return nftId ID of the deposit NFT.
     */
    function depositAssets(DepositBag calldata bag, DepositExtras calldata bag2) external returns (uint256 nftId);

    /**
     * @notice Mark deposits ready to be processed in the next DHW cycle
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart Vault address
     * @param flushIndex index to flush
     * @param strategies vault strategy addresses
     * @param allocations vault strategy allocations
     * @param tokens vault asset group token addresses
     * @return dhwIndexes DHW indexes in which the deposits will be included
     */
    function flushSmartVault(
        address smartVault,
        uint256 flushIndex,
        address[] calldata strategies,
        uint16a16 allocations,
        address[] calldata tokens
    ) external returns (uint16a16 dhwIndexes);

    /**
     * @notice Get the number of SVTs that are available, but haven't been claimed yet, for the given NFT
     * @param smartVaultAddress Smart Vault address
     * @param data NFT deposit NFT metadata
     * @param nftShares amount of NFT shares to burn for SVTs
     * @param mintedSVTs amount of SVTs minted for this flush
     * @param tokens vault asset group addresses
     */
    function getClaimedVaultTokensPreview(
        address smartVaultAddress,
        DepositMetadata memory data,
        uint256 nftShares,
        uint256 mintedSVTs,
        address[] calldata tokens
    ) external view returns (uint256);

    /**
     * @notice Fetch assets deposited in a given vault flush
     */
    function smartVaultDeposits(address smartVault, uint256 flushIdx, uint256 assetGroupLength)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Claim SVTs by burning deposit NFTs.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart Vault address
     * @param nftIds NFT ids to burn
     * @param nftAmounts NFT amounts to burn (support for partial burn)
     * @param tokens vault asset group token addresses
     * @param owner address owning NFTs
     * @param executor address executing the claim transaction
     * @param flushIndexToSync next flush index to sync for the smart vault
     * @return claimedTokens Amount of smart vault tokens claimed.
     */
    function claimSmartVaultTokens(
        address smartVault,
        uint256[] calldata nftIds,
        uint256[] calldata nftAmounts,
        address[] calldata tokens,
        address owner,
        address executor,
        uint256 flushIndexToSync
    ) external returns (uint256 claimedTokens);

    /**
     * @notice Recovers pending deposits from smart vault.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault from which to recover pending deposits.
     * @param flushIndex Flush index for which to recover pending deposits.
     * @param strategies Addresses of smart vault's strategies.
     * @param tokens Asset group token addresses.
     * @param emergencyWallet Address of emergency withdraw wallet.
     */
    function recoverPendingDeposits(
        address smartVault,
        uint256 flushIndex,
        address[] calldata strategies,
        address[] calldata tokens,
        address emergencyWallet
    ) external;

    /**
     * @notice Gets current required deposit ratio of a smart vault.
     * @param tokens Asset tokens of the smart vault.
     * @param allocations Allocation between strategies of the smart vault.
     * @param strategies Strategies of the smart vault.
     * @return ratio Required deposit ratio of the smart vault.
     */
    function getDepositRatio(address[] memory tokens, uint16a16 allocations, address[] memory strategies)
        external
        view
        returns (uint256[] memory ratio);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./ISwapper.sol";

/**
 * @notice Input for swapping and depositing assets.
 * @custom:member inTokens Input tokens to be swapped.
 * @custom:member inAmounts Maximal amount of input tokens to be swapped.
 * @custom:member swapInfo Information needed to perform the swap.
 * @custom:member smartVault Smart vault for which the deposit is made.
 * @custom:member receiver Receiver of the deposit NFT.
 * @custom:member referral Referral address.
 * @custom:member doFlush If true, the smart vault will be flushed after the deposit as part of same transaction.
 */
struct SwapDepositBag {
    address[] inTokens;
    uint256[] inAmounts;
    SwapInfo[] swapInfo;
    address smartVault;
    address receiver;
    address referral;
    bool doFlush;
}

interface IDepositSwap {
    /**
     * @notice Swaps tokens input tokens based on provided swap info and
     * deposits swapped tokens into the smart vault.
     *
     * When sent eth, it will wrap it into WETH. After wrapping, WETH can be swapped
     * if it is included in inTokens parameter.
     * @dev Unswapped tokens are transferred back to the caller.
     * Requirements:
     * - caller must set approval for this contract on input tokens in input amount
     * @param swapDepositBag Data to swap and deposit assets into a smart vault.
     * @return depositNftId ID of the minted deposit NFT.
     */
    function swapAndDeposit(SwapDepositBag calldata swapDepositBag) external payable returns (uint256 depositNftId);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IDepositManager.sol";
import "./ISmartVault.sol";
import "./ISwapper.sol";
import "./IWithdrawalManager.sol";

/* ========== ERRORS ========== */

/**
 * @notice Used when user has insufficient balance for redeemal of shares.
 */
error InsufficientBalance(uint256 available, uint256 required);

/**
 * @notice Used when there is nothing to flush.
 */
error NothingToFlush();

/**
 * @notice Used when trying to register a smart vault that was already registered.
 */
error SmartVaultAlreadyRegistered();

/**
 * @notice Used when trying to perform an action for smart vault that was not registered yet.
 */
error SmartVaultNotRegisteredYet();

/**
 * @notice Used when user tries to configure a vault with too large management fee.
 */
error ManagementFeeTooLarge(uint256 mgmtFeePct);

/**
 * @notice Used when user tries to configure a vault with too large performance fee.
 */
error PerformanceFeeTooLarge(uint256 performanceFeePct);

/**
 * @notice Used when smart vault in reallocation has statically set allocation.
 */
error StaticAllocationSmartVault();

/**
 * @notice Used when user tries to configure a vault with too large deposit fee.
 */
error DepositFeeTooLarge(uint256 depositFeePct);

/**
 * @notice Used when user tries redeem on behalf of another user, but the vault does not support it
 */
error RedeemForNotAllowed();

/**
 * @notice Used when trying to flush a vault that still needs to be synced.
 */
error VaultNotSynced();

/**
 * @notice Used when trying to deposit into, redeem from, or flush a smart vault that has only ghost strategies.
 */
error GhostVault();

/**
 * @notice Used when reallocation is called with expired parameters.
 */
error ReallocationParametersExpired();

/* ========== STRUCTS ========== */

/**
 * @notice Struct holding all data for registration of smart vault.
 * @custom:member assetGroupId Underlying asset group of the smart vault.
 * @custom:member strategies Strategies used by the smart vault.
 * @custom:member strategyAllocation Optional. If empty array, values will be calculated on the spot.
 * @custom:member managementFeePct Management fee of the smart vault.
 * @custom:member depositFeePct Deposit fee of the smart vault.
 * @custom:member performanceFeePct Performance fee of the smart vault.
 */
struct SmartVaultRegistrationForm {
    uint256 assetGroupId;
    address[] strategies;
    uint16a16 strategyAllocation;
    uint16 managementFeePct;
    uint16 depositFeePct;
    uint16 performanceFeePct;
}

/**
 * @notice Parameters for reallocation.
 * @custom:member smartVaults Smart vaults to reallocate.
 * @custom:member strategies Set of strategies involved in the reallocation. Should not include ghost strategy, even if some smart vault uses it.
 * @custom:member swapInfo Information for swapping assets before depositing into the protocol.
 * @custom:member depositSlippages Slippages used to constrain depositing into the protocol.
 * @custom:member withdrawalSlippages Slippages used to contrain withdrawal from the protocol.
 * @custom:member exchangeRateSlippages Slippages used to constratrain exchange rates for asset tokens.
 * @custom:member validUntil Sets the maximum timestamp the user is willing to wait to start executing reallocation.
 */
struct ReallocateParamBag {
    address[] smartVaults;
    address[] strategies;
    SwapInfo[][] swapInfo;
    uint256[][] depositSlippages;
    uint256[][] withdrawalSlippages;
    uint256[2][] exchangeRateSlippages;
    uint256 validUntil;
}

struct FlushIndex {
    uint128 current;
    uint128 toSync;
}

/* ========== INTERFACES ========== */

interface ISmartVaultRegistry {
    /**
     * @notice Registers smart vault into the Spool protocol.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * @param smartVault Smart vault to register.
     * @param registrationForm Form with information for registration.
     */
    function registerSmartVault(address smartVault, SmartVaultRegistrationForm calldata registrationForm) external;
}

interface ISmartVaultManager is ISmartVaultRegistry {
    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Gets do-hard-work indexes.
     * @param smartVault Smart vault.
     * @param flushIndex Flush index.
     * @return dhwIndexes Do-hard-work indexes for flush index of the smart vault.
     */
    function dhwIndexes(address smartVault, uint256 flushIndex) external view returns (uint16a16 dhwIndexes);

    /**
     * @notice Gets latest flush index for a smart vault.
     * @param smartVault Smart vault.
     * @return flushIndex Latest flush index for the smart vault.
     */
    function getLatestFlushIndex(address smartVault) external view returns (uint256 flushIndex);

    /**
     * @notice Gets strategy allocation for a smart vault.
     * @param smartVault Smart vault.
     * @return allocation Strategy allocation for the smart vault.
     */
    function allocations(address smartVault) external view returns (uint16a16 allocation);

    /**
     * @notice Gets strategies used by a smart vault.
     * @param smartVault Smart vault.
     * @return strategies Strategies for the smart vault.
     */
    function strategies(address smartVault) external view returns (address[] memory strategies);

    /**
     * @notice Gets asest group used by a smart vault.
     * @param smartVault Smart vault.
     * @return assetGroupId ID of the asset group used by the smart vault.
     */
    function assetGroupId(address smartVault) external view returns (uint256 assetGroupId);

    /**
     * @notice Gets required deposit ratio for a smart vault.
     * @param smartVault Smart vault.
     * @return ratio Required deposit ratio for the smart vault.
     */
    function depositRatio(address smartVault) external view returns (uint256[] memory ratio);

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Flushes deposits and withdrawal for the next do-hard-work.
     * @param smartVault Smart vault to flush.
     */
    function flushSmartVault(address smartVault) external;

    /**
     * @notice Reallocates smart vaults.
     * @dev Requirements:
     * - caller must have a ROLE_REALLOCATOR role
     * - smart vaults must be registered
     * - smart vaults must use same asset group
     * - strategies must represent a set of strategies used by smart vaults
     * @param reallocateParams Paramaters for reallocation.
     */
    function reallocate(ReallocateParamBag calldata reallocateParams) external;

    /**
     * @notice Removes strategy from vaults, and optionally removes it from the system as well.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * - the strategy has to be active (requires ROLE_STRATEGY)
     * @param strategy Strategy address to remove.
     * @param vaults Array of vaults from which to remove the strategy
     * @param disableStrategy Also disable the strategy across the system
     */
    function removeStrategyFromVaults(address strategy, address[] calldata vaults, bool disableStrategy) external;

    /**
     * @notice Syncs smart vault with strategies.
     * @param smartVault Smart vault to sync.
     * @param revertIfError If true, sync will revert if every flush index cannot be synced; if false it will sync all flush indexes it can.
     */
    function syncSmartVault(address smartVault, bool revertIfError) external;

    /**
     * @dev Calculate number of SVTs that haven't been synced yet after DHW runs
     * DHW has minted strategy shares, but vaults haven't claimed them yet.
     * Includes management fees (percentage of assets under management, distributed throughout a year) and deposit fees .
     * Invariants:
     * - There can't be more than once un-synced flush index per vault at any given time.
     * - Flush index can't be synced, if all DHWs haven't been completed yet.
     *
     * Can be used to retrieve the number of SSTs the vault would claim during sync.
     * @param smartVault SmartVault address
     * @return oldTotalSVTs Amount of SVTs before sync
     * @return mintedSVTs Amount of SVTs minted during sync
     * @return feeSVTs Amount of SVTs pertaining to fees
     * @return sstShares Amount of SSTs claimed per strategy
     */
    function simulateSync(address smartVault)
        external
        view
        returns (uint256 oldTotalSVTs, uint256 mintedSVTs, uint256 feeSVTs, uint256[] calldata sstShares);

    /**
     * @dev Simulate sync when burning dNFTs and return their svts value.
     *
     * @param smartVault SmartVault address
     * @param userAddress User address that owns dNFTs
     * @param nftIds Ids of dNFTs
     * @return svts Amount of svts user would get if he burns dNFTs
     */
    function simulateSyncWithBurn(address smartVault, address userAddress, uint256[] calldata nftIds)
        external
        view
        returns (uint256 svts);

    /**
     * @notice Instantly redeems smart vault shares for assets.
     * @param bag Parameters for fast redeemal.
     * @param withdrawalSlippages Slippages guarding redeemal.
     * @return withdrawnAssets Amount of assets withdrawn.
     */
    function redeemFast(RedeemBag calldata bag, uint256[][] calldata withdrawalSlippages)
        external
        returns (uint256[] memory withdrawnAssets);

    /**
     * @notice Simulates redeem fast of smart vault shares.
     * @dev Should only be run by address zero to simulate the redeemal and parse logs.
     * @param bag Parameters for fast redeemal.
     * @param withdrawalSlippages Slippages guarding redeemal.
     * @param redeemer Address of a user to simulate redeem for.
     * @return withdrawnAssets Amount of assets withdrawn.
     */
    function redeemFastView(RedeemBag calldata bag, uint256[][] calldata withdrawalSlippages, address redeemer)
        external
        returns (uint256[] memory withdrawnAssets);

    /**
     * @notice Claims withdrawal of assets by burning withdrawal NFT.
     * @dev Requirements:
     * - withdrawal NFT must be valid
     * @param smartVault Address of the smart vault that issued the withdrawal NFT.
     * @param nftIds ID of withdrawal NFT to burn.
     * @param nftAmounts amounts
     * @param receiver Receiver of claimed assets.
     * @return assetAmounts Amounts of assets claimed.
     * @return assetGroupId ID of the asset group.
     */
    function claimWithdrawal(
        address smartVault,
        uint256[] calldata nftIds,
        uint256[] calldata nftAmounts,
        address receiver
    ) external returns (uint256[] memory assetAmounts, uint256 assetGroupId);

    /**
     * @notice Claims smart vault tokens by burning the deposit NFT.
     * @dev Requirements:
     * - deposit NFT must be valid
     * - flush must be synced
     * @param smartVaultAddress Address of the smart vault that issued the deposit NFT.
     * @param nftIds ID of the deposit NFT to burn.
     * @param nftAmounts amounts
     * @return claimedAmount Amount of smart vault tokens claimed.
     */
    function claimSmartVaultTokens(address smartVaultAddress, uint256[] calldata nftIds, uint256[] calldata nftAmounts)
        external
        returns (uint256 claimedAmount);

    /**
     * @notice Initiates a withdrawal process and mints a withdrawal NFT. Once all DHWs are executed, user can
     * use the withdrawal NFT to claim the assets.
     * Optionally, caller can pass a list of deposit NFTs to unwrap.
     * @param bag smart vault address, amount of shares to redeem, nft ids and amounts to burn
     * @param receiver address that will receive the withdrawal NFT
     * @param doFlush optionally flush the smart vault
     * @return receipt ID of the receipt withdrawal NFT.
     */
    function redeem(RedeemBag calldata bag, address receiver, bool doFlush) external returns (uint256 receipt);

    /**
     * @notice Initiates a withdrawal process and mints a withdrawal NFT. Once all DHWs are executed, user can
     * use the withdrawal NFT to claim the assets.
     * Optionally, caller can pass a list of deposit NFTs to unwrap.
     * @param bag smart vault address, amount of shares to redeem, nft ids and amounts to burn
     * @param owner address that owns the shares to be redeemed and will receive the withdrawal NFT
     * @param doFlush optionally flush the smart vault
     * @return receipt ID of the receipt withdrawal NFT.
     */
    function redeemFor(RedeemBag calldata bag, address owner, bool doFlush) external returns (uint256 receipt);

    /**
     * @notice Initiated a deposit and mints a deposit NFT. Once all DHWs are executed, user can
     * unwrap the deposit NDF and claim his SVTs.
     * @param bag smartVault address, assets, NFT receiver address, referral address, doFlush
     * @return receipt ID of the receipt deposit NFT.
     */
    function deposit(DepositBag calldata bag) external returns (uint256 receipt);

    /**
     * @notice Recovers pending deposits from smart vault to emergency wallet.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * - all strategies of the smart vault need to be ghost strategies
     * @param smartVault Smart vault from which to recover pending deposits.
     */
    function recoverPendingDeposits(address smartVault) external;

    /* ========== EVENTS ========== */

    /**
     * @notice Smart vault has been flushed
     * @param smartVault Smart vault address
     * @param flushIndex Flush index
     */
    event SmartVaultFlushed(address indexed smartVault, uint256 flushIndex);

    /**
     * @notice Smart vault has been synced
     * @param smartVault Smart vault address
     * @param flushIndex Flush index
     */
    event SmartVaultSynced(address indexed smartVault, uint256 flushIndex);

    /**
     * @notice Smart vault has been registered
     * @param smartVault Smart vault address
     * @param registrationForm Smart vault configuration
     */
    event SmartVaultRegistered(address indexed smartVault, SmartVaultRegistrationForm registrationForm);

    /**
     * @notice Strategy was removed from the vault
     * @param strategy Strategy address
     * @param vault Vault to remove the strategy from
     */
    event StrategyRemovedFromVault(address indexed strategy, address indexed vault);

    /**
     * @notice Vault was reallocation executed
     * @param smartVault Smart vault address
     * @param newAllocations new vault strategy allocations
     */
    event SmartVaultReallocated(address indexed smartVault, uint16a16 newAllocations);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/* ========== STRUCTS ========== */

/**
 * @notice Information needed to make a swap of assets.
 * @custom:member swapTarget Contract executing the swap.
 * @custom:member token Token to be swapped.
 * @custom:member swapCallData Calldata describing the swap itself.
 */
struct SwapInfo {
    address swapTarget;
    address token;
    bytes swapCallData;
}

/* ========== ERRORS ========== */

/**
 * @notice Used when trying to do a swap via an exchange that is not allowed to execute a swap.
 * @param exchange Exchange used.
 */
error ExchangeNotAllowed(address exchange);

/**
 * @notice Used when trying to execute a swap but are not authorized.
 * @param caller Caller of the swap method.
 */
error NotSwapper(address caller);

/* ========== INTERFACES ========== */

interface ISwapper {
    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when the exchange allowlist is updated.
     * @param exchange Exchange that was updated.
     * @param isAllowed Whether the exchange is allowed to be used in a swap or not after the update.
     */
    event ExchangeAllowlistUpdated(address indexed exchange, bool isAllowed);

    event Swapped(
        address indexed receiver, address[] tokensIn, address[] tokensOut, uint256[] amountsIn, uint256[] amountsOut
    );

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Performs a swap of tokens with external contracts.
     * - deposit tokens into the swapper contract
     * - swapper will swap tokens based on swap info provided
     * - swapper will return unswapped tokens to the receiver
     * @param tokensIn Addresses of tokens available for the swap.
     * @param swapInfo Information needed to perform the swap.
     * @param tokensOut Addresses of tokens to swap to.
     * @param receiver Receiver of unswapped tokens.
     * @return amountsOut Amounts of `tokensOut` sent from the swapper to the receiver.
     */
    function swap(
        address[] calldata tokensIn,
        SwapInfo[] calldata swapInfo,
        address[] calldata tokensOut,
        address receiver
    ) external returns (uint256[] memory amountsOut);

    /**
     * @notice Updates list of exchanges that can be used in a swap.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SPOOL_ADMIN
     *   - exchanges and allowed arrays need to be of same length
     * @param exchanges Addresses of exchanges.
     * @param allowed Whether an exchange is allowed to be used in a swap.
     */
    function updateExchangeAllowlist(address[] calldata exchanges, bool[] calldata allowed) external;

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Checks if an exchange is allowed to be used in a swap.
     * @param exchange Exchange to check.
     * @return isAllowed True if the exchange is allowed to be used in a swap, false otherwise.
     */
    function isExchangeAllowed(address exchange) external view returns (bool isAllowed);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @notice Used when an array has invalid length.
 */
error InvalidArrayLength();

/**
 * @notice Used when group of smart vaults or strategies do not have same asset group.
 */
error NotSameAssetGroup();

/**
 * @notice Used when configuring an address with a zero address.
 */
error ConfigurationAddressZero();

/**
 * @notice Used when constructor or intializer parameters are invalid.
 */
error InvalidConfiguration();

/**
 * @notice Used when fetched exchange rate is out of slippage range.
 */
error ExchangeRateOutOfSlippages();

/**
 * @notice Used when an invalid strategy is provided.
 * @param address_ Address of the invalid strategy.
 */
error InvalidStrategy(address address_);

/**
 * @notice Used when doing low-level call on an address that is not a contract.
 * @param address_ Address of the contract
 */
error AddressNotContract(address address_);

/**
 * @notice Used when invoking an only view execution and tx.origin is not address zero.
 * @param address_ Address of the tx.origin
 */
error OnlyViewExecution(address address_);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "./Constants.sol";
import "./RequestType.sol";

/* ========== ERRORS ========== */

/**
 * @notice Used when the ID for deposit NFTs overflows.
 * @dev Should never happen.
 */
error DepositIdOverflow();

/**
 * @notice Used when the ID for withdrawal NFTs overflows.
 * @dev Should never happen.
 */
error WithdrawalIdOverflow();

/**
 * @notice Used when ID does not represent a deposit NFT.
 * @param depositNftId Invalid ID for deposit NFT.
 */
error InvalidDepositNftId(uint256 depositNftId);

/**
 * @notice Used when ID does not represent a withdrawal NFT.
 * @param withdrawalNftId Invalid ID for withdrawal NFT.
 */
error InvalidWithdrawalNftId(uint256 withdrawalNftId);

/**
 * @notice Used when balance of the NFT is invalid.
 * @param balance Actual balance of the NFT.
 */
error InvalidNftBalance(uint256 balance);

/**
 * @notice Used when someone wants to transfer invalid NFT shares amount.
 * @param transferAmount Amount of shares requested to be transferred.
 */
error InvalidNftTransferAmount(uint256 transferAmount);

/**
 * @notice Used when user tries to send tokens to himself.
 */
error SenderEqualsRecipient();

/* ========== STRUCTS ========== */

struct DepositMetadata {
    uint256[] assets;
    uint256 initiated;
    uint256 flushIndex;
}

/**
 * @notice Holds metadata detailing the withdrawal behind the NFT.
 * @custom:member vaultShares Vault shares withdrawn.
 * @custom:member flushIndex Flush index into which withdrawal is included.
 */
struct WithdrawalMetadata {
    uint256 vaultShares;
    uint256 flushIndex;
}

/**
 * @notice Holds all smart vault fee percentages.
 * @custom:member managementFeePct Management fee of the smart vault.
 * @custom:member depositFeePct Deposit fee of the smart vault.
 * @custom:member performanceFeePct Performance fee of the smart vault.
 */
struct SmartVaultFees {
    uint16 managementFeePct;
    uint16 depositFeePct;
    uint16 performanceFeePct;
}

/* ========== INTERFACES ========== */

interface ISmartVault is IERC20Upgradeable, IERC1155MetadataURIUpgradeable {
    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Fractional balance of a NFT (0 - NFT_MINTED_SHARES).
     * @param account Account to check the balance for.
     * @param id ID of the NFT to check.
     * @return fractionalBalance Fractional balance of account for the NFT.
     */
    function balanceOfFractional(address account, uint256 id) external view returns (uint256 fractionalBalance);

    /**
     * @notice Fractional balance of a NFTs (0 - NFT_MINTED_SHARES).
     * @param account Account to check the balance for.
     * @param ids IDs of the NFTs to check.
     * @return fractionalBalances Fractional balances of account for each requested NFT.
     */
    function balanceOfFractionalBatch(address account, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory fractionalBalances);
    /**
     * @notice Gets the asset group used by the smart vault.
     * @return id ID of the asset group.
     */
    function assetGroupId() external view returns (uint256 id);

    /**
     * @notice Gets the name of the smart vault.
     * @return name Name of the vault.
     */
    function vaultName() external view returns (string memory name);

    /**
     * @notice Gets metadata for NFTs.
     * @param nftIds IDs of NFTs.
     * @return metadata Metadata for each requested NFT.
     */
    function getMetadata(uint256[] calldata nftIds) external view returns (bytes[] memory metadata);

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Set a new base URI for ERC1155 metadata.
     * @param uri_ new base URI value
     */
    function setBaseURI(string memory uri_) external;

    /**
     * @notice Mints smart vault tokens for receiver.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param receiver REceiver of minted tokens.
     * @param vaultShares Amount of tokens to mint.
     */
    function mintVaultShares(address receiver, uint256 vaultShares) external;

    /**
     * @notice Burns smart vault tokens and releases strategy shares back to strategies.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param owner Address for which to burn the tokens.
     * @param vaultShares Amount of tokens to burn.
     * @param strategies Strategies for which to release the strategy shares.
     * @param shares Amounts of strategy shares to release.
     */
    function burnVaultShares(
        address owner,
        uint256 vaultShares,
        address[] calldata strategies,
        uint256[] calldata shares
    ) external;

    /**
     * @notice Mints a new withdrawal NFT.
     * @dev Supply of minted NFT is NFT_MINTED_SHARES (for partial burning).
     * Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param receiver Address that will receive the NFT.
     * @param metadata Metadata to store for minted NFT.
     * @return id ID of the minted NFT.
     */
    function mintWithdrawalNFT(address receiver, WithdrawalMetadata calldata metadata) external returns (uint256 id);

    /**
     * @notice Mints a new deposit NFT.
     * @dev Supply of minted NFT is NFT_MINTED_SHARES (for partial burning).
     * Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param receiver Address that will receive the NFT.
     * @param metadata Metadata to store for minted NFT.
     * @return id ID of the minted NFT.
     */
    function mintDepositNFT(address receiver, DepositMetadata calldata metadata) external returns (uint256 id);

    /**
     * @notice Burns NFTs and returns their metadata.
     * Allows for partial burning.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param owner Owner of NFTs to burn.
     * @param nftIds IDs of NFTs to burn.
     * @param nftAmounts NFT shares to burn (partial burn).
     * @return metadata Metadata for each burned NFT.
     */
    function burnNFTs(address owner, uint256[] calldata nftIds, uint256[] calldata nftAmounts)
        external
        returns (bytes[] memory metadata);

    /**
     * @notice Transfers smart vault tokens.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param from Spender and owner of tokens.
     * @param to Address to which tokens will be transferred.
     * @param amount Amount of tokens to transfer.
     * @return success True if transfer was successful.
     */
    function transferFromSpender(address from, address to, uint256 amount) external returns (bool success);

    /**
     * @notice Transfers unclaimed shares to claimer.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param claimer Address that claims the shares.
     * @param amount Amount of shares to transfer.
     */
    function claimShares(address claimer, uint256 amount) external;

    /// @notice Emitted when base URI is changed.
    event BaseURIChanged(string baseUri);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

type uint16a16 is uint256;

/**
 * @notice This library enables packing of sixteen uint16 elements into one uint256 word.
 */
library uint16a16Lib {
    /// @notice Number of bits per stored element.
    uint256 constant bits = 16;

    /// @notice Maximal number of elements stored.
    uint256 constant elements = 16;

    // must ensure that bits * elements <= 256

    /// @notice Range covered by stored element.
    uint256 constant range = 1 << bits;

    /// @notice Maximal value of stored element.
    uint256 constant max = range - 1;

    /**
     * @notice Gets element from packed array.
     * @param va Packed array.
     * @param index Index of element to get.
     * @return element Element of va stored in index index.
     */
    function get(uint16a16 va, uint256 index) internal pure returns (uint256) {
        require(index < elements);
        return (uint16a16.unwrap(va) >> (bits * index)) & max;
    }

    /**
     * @notice Sets element to packed array.
     * @param va Packed array.
     * @param index Index under which to store the element
     * @param ev Element to store.
     * @return va Packed array with stored element.
     */
    function set(uint16a16 va, uint256 index, uint256 ev) internal pure returns (uint16a16) {
        require(index < elements);
        require(ev < range);
        index *= bits;
        return uint16a16.wrap((uint16a16.unwrap(va) & ~(max << index)) | (ev << index));
    }

    /**
     * @notice Sets elements to packed array.
     * Elements are stored continuously from index 0 onwards.
     * @param va Packed array.
     * @param ev Elements to store.
     * @return va Packed array with stored elements.
     */
    function set(uint16a16 va, uint256[] memory ev) internal pure returns (uint16a16) {
        for (uint256 i; i < ev.length; ++i) {
            va = set(va, i, ev[i]);
        }

        return va;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../libraries/uint16a16Lib.sol";

/**
 * @notice Used when trying to burn withdrawal NFT that was not synced yet.
 * @param id ID of the NFT.
 */
error WithdrawalNftNotSyncedYet(uint256 id);

/**
 * @notice Base information for redeemal.
 * @custom:member smartVault Smart vault from which to redeem.
 * @custom:member shares Amount of smart vault shares to redeem.
 * @custom:member nftIds IDs of deposit NFTs to burn before redeemal.
 * @custom:member nftAmounts Amounts of NFT shares to burn.
 */
struct RedeemBag {
    address smartVault;
    uint256 shares;
    uint256[] nftIds;
    uint256[] nftAmounts;
}

/**
 * @notice Extra information for fast redeemal.
 * @custom:member strategies Strategies of the smart vault.
 * @custom:member assetGroup Asset group of the smart vault.
 * @custom:member assetGroupId ID of the asset group of the smart vault.
 * @custom:member redeemer Address that initiated the redeemal.
 * @custom:member withdrawalSlippages Slippages used to guard redeemal.
 */
struct RedeemFastExtras {
    address[] strategies;
    address[] assetGroup;
    uint256 assetGroupId;
    address redeemer;
    uint256[][] withdrawalSlippages;
}

/**
 * @notice Extra information for redeemal.
 * @custom:member receiver Receiver of the withdraw NFT.
 * @custom:member owner Address that owns the shares being redeemed.
 * @custom:member executor Address that initiated the redeemal.
 * @custom:member flushIndex Current flush index of the smart vault.
 */
struct RedeemExtras {
    address receiver;
    address owner;
    address executor;
    uint256 flushIndex;
}

/**
 * @notice Information used to claim withdrawal.
 * @custom:member smartVault Smart vault from which to claim withdrawal.
 * @custom:member nftIds Withdrawal NFTs to burn while claiming withdrawal.
 * @custom:member nftAmounts Amounts of NFT shares to burn.
 * @custom:member receiver Receiver of withdrawn assets.
 * @custom:member executor Address that initiated the withdrawal claim.
 * @custom:member assetGroupId ID of the asset group of the smart vault.
 * @custom:member assetGroup Asset group of the smart vault.
 * @custom:member flushIndexToSync Next flush index to sync for the smart vault.
 */
struct WithdrawalClaimBag {
    address smartVault;
    uint256[] nftIds;
    uint256[] nftAmounts;
    address receiver;
    address executor;
    uint256 assetGroupId;
    address[] assetGroup;
    uint256 flushIndexToSync;
}

interface IWithdrawalManager {
    /**
     * @notice User redeemed withdrawal NFTs for underlying assets
     * @param smartVault Smart vault address
     * @param claimer Claimer address
     * @param nftIds NFTs to burn
     * @param nftAmounts NFT shares to burn
     * @param withdrawnAssets Amount of underlying assets withdrawn
     */
    event WithdrawalClaimed(
        address indexed smartVault,
        address indexed claimer,
        uint256 assetGroupId,
        uint256[] nftIds,
        uint256[] nftAmounts,
        uint256[] withdrawnAssets
    );

    /**
     * @notice A deposit has been initiated
     * @param smartVault Smart vault address
     * @param owner Owner of shares to be redeemed
     * @param redeemId Withdrawal NFT ID for this redeemal
     * @param flushIndex Flush index the redeem was scheduled for
     * @param shares Amount of vault shares to redeem
     * @param receiver Beneficiary that will be able to claim the underlying assets
     */
    event RedeemInitiated(
        address indexed smartVault,
        address indexed owner,
        uint256 indexed redeemId,
        uint256 flushIndex,
        uint256 shares,
        address receiver
    );

    /**
     * @notice A deposit has been initiated
     * @param smartVault Smart vault address
     * @param redeemer Redeem initiator and owner of shares
     * @param shares Amount of vault shares to redeem
     * @param nftIds NFTs to burn
     * @param nftAmounts NFT shares to burn
     * @param assetsWithdrawn Amount of underlying assets withdrawn
     */
    event FastRedeemInitiated(
        address indexed smartVault,
        address indexed redeemer,
        uint256 shares,
        uint256[] nftIds,
        uint256[] nftAmounts,
        uint256[] assetsWithdrawn
    );

    /**
     * @notice Flushes smart vaults deposits and withdrawals to the strategies.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault to flush.
     * @param flushIndex Current flush index of the smart vault.
     * @param strategies Strategies of the smart vault.
     * @return dhwIndexes current do-hard-work indexes of the strategies.
     */
    function flushSmartVault(address smartVault, uint256 flushIndex, address[] calldata strategies)
        external
        returns (uint16a16 dhwIndexes);

    /**
     * @notice Claims withdrawal.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SMART_VAULT_MANAGER
     * @param bag Parameters for claiming withdrawal.
     * @return withdrawnAssets Amount of assets withdrawn.
     * @return assetGroupId ID of the asset group.
     */
    function claimWithdrawal(WithdrawalClaimBag calldata bag)
        external
        returns (uint256[] memory withdrawnAssets, uint256 assetGroupId);

    /**
     * @notice Syncs withdrawals between strategies and smart vault after do-hard-works.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault to sync.
     * @param flushIndex Smart vault's flush index to sync.
     * @param strategies Strategies of the smart vault.
     * @param dhwIndexes_ Strategies' do-hard-work indexes to sync.
     */
    function syncWithdrawals(
        address smartVault,
        uint256 flushIndex,
        address[] calldata strategies,
        uint16a16 dhwIndexes_
    ) external;

    /**
     * @notice Redeems smart vault shares.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SMART_VAULT_MANAGER
     * @param bag Base information for redeemal.
     * @param bag2 Extra information for redeemal.
     * @return nftId ID of the withdrawal NFT.
     */
    function redeem(RedeemBag calldata bag, RedeemExtras calldata bag2) external returns (uint256 nftId);

    /**
     * @notice Instantly redeems smart vault shares.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SMART_VAULT_MANAGER
     * @param bag Base information for redeemal.
     * @param bag Extra information for fast redeemal.
     * @return assets Amount of assets withdrawn.
     */
    function redeemFast(RedeemBag calldata bag, RedeemFastExtras memory bag2)
        external
        returns (uint256[] memory assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @dev Number of seconds in an average year.
uint256 constant SECONDS_IN_YEAR = 31_556_926;

/// @dev Number of seconds in an average year.
int256 constant SECONDS_IN_YEAR_INT = 31_556_926;

/// @dev Represents 100%.
uint256 constant FULL_PERCENT = 100_00;

/// @dev Represents 100%.
int256 constant FULL_PERCENT_INT = 100_00;

/// @dev Represents 100% for yield.
int256 constant YIELD_FULL_PERCENT_INT = 10 ** 12;

/// @dev Represents 100% for yield.
uint256 constant YIELD_FULL_PERCENT = uint256(YIELD_FULL_PERCENT_INT);

/// @dev Maximal management fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant MANAGEMENT_FEE_MAX = 5_00;

/// @dev Maximal deposit fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant DEPOSIT_FEE_MAX = 5_00;

/// @dev Maximal smart vault performance fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant SV_PERFORMANCE_FEE_MAX = 20_00;

/// @dev Maximal ecosystem fee that can be set on the system. Expressed in terms of FULL_PERCENT.
uint256 constant ECOSYSTEM_FEE_MAX = 20_00;

/// @dev Maximal treasury fee that can be set on the system. Expressed in terms of FULL_PERCENT.
uint256 constant TREASURY_FEE_MAX = 10_00;

/// @dev Maximal risk score a strategy can be assigned.
uint8 constant MAX_RISK_SCORE = 10_0;

/// @dev Minimal risk score a strategy can be assigned.
uint8 constant MIN_RISK_SCORE = 1;

/// @dev Maximal value for risk tolerance a smart vautl can have.
int8 constant MAX_RISK_TOLERANCE = 10;

/// @dev Minimal value for risk tolerance a smart vault can have.
int8 constant MIN_RISK_TOLERANCE = -10;

/// @dev If set as risk provider, system will return fixed risk score values
address constant STATIC_RISK_PROVIDER = address(0xaaa);

/// @dev Fixed values to use if risk provider is set to STATIC_RISK_PROVIDER
uint8 constant STATIC_RISK_SCORE = 1;

/// @dev Maximal value of deposit NFT ID.
uint256 constant MAXIMAL_DEPOSIT_ID = 2 ** 255;

/// @dev Maximal value of withdrawal NFT ID.
uint256 constant MAXIMAL_WITHDRAWAL_ID = 2 ** 256 - 1;

/// @dev How many shares will be minted with a NFT
uint256 constant NFT_MINTED_SHARES = 10 ** 6;

/// @dev Each smart vault can have up to STRATEGY_COUNT_CAP strategies.
uint256 constant STRATEGY_COUNT_CAP = 16;

/// @dev Maximal DHW base yield. Expressed in terms of FULL_PERCENT.
uint256 constant MAX_DHW_BASE_YIELD_LIMIT = 10_00;

/// @dev Smart vault and strategy share multiplier at first deposit.
uint256 constant INITIAL_SHARE_MULTIPLIER = 1000;

/// @dev Strategy initial locked shares. These shares will never be unlocked.
uint256 constant INITIAL_LOCKED_SHARES = 10 ** 12;

/// @dev Strategy initial locked shares address.
address constant INITIAL_LOCKED_SHARES_ADDRESS = address(0xdead);

/// @dev Maximum number of guards a smart vault can be configured with
uint256 constant MAX_GUARD_COUNT = 10;

/// @dev Maximum number of actions a smart vault can be configured with
uint256 constant MAX_ACTION_COUNT = 10;

/// @dev ID of null asset group. Should not be used by any strategy or smart vault.
uint256 constant NULL_ASSET_GROUP_ID = 0;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @notice Different request types for guards and actions.
 * @custom:member Deposit User is depositing into a smart vault.
 * @custom:member Withdrawal User is requesting withdrawal from a smart vault.
 * @custom:member TransferNFT User is transfering deposit or withdrawal NFT.
 * @custom:member BurnNFT User is burning deposit or withdrawal NFT.
 * @custom:member TransferSVTs User is transferring smart vault tokens.
 */
enum RequestType {
    Deposit,
    Withdrawal,
    TransferNFT,
    BurnNFT,
    TransferSVTs
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}