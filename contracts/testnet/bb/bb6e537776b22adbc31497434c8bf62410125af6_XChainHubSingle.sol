//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {XChainHub} from "@hub/XChainHub.sol";
import {IVault} from "@interfaces/IVault.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {IHubPayload} from "@interfaces/IHubPayload.sol";

/// @title XChainHubSingle - a restricted version of the XChainHub
/// @dev limitations on Stargate prevent us from being able to trust inbound payloads.
///      This contract extends the XChain hub with additional restrictions
/// @dev The aim is to setup several of these with hardcoded constants in a format similar to below:
///      address public constant ADDY_AVAX_STRATEGY = 0xa23bAFEB30Cc41c4dE68b91aA7Db0eF565276dE3;
///      address public constant ADDY_AVAX_VAULT = 0x34B57897b734fD12D8423346942d796E1CCF2E08;
///      uint16 public constant DESTINATION_CHAIN_ID = 0;
///      uint16 public constant ORIGIN_CHAIN_ID = 0;
///      bool public constant IS_ORIGIN = true;
///      address public constant ORIGIN_UNDERLYING_ADDY = 0x37883431AF7f8fd4c04dc3573b6914e12F089Dfa;
contract XChainHubSingle is XChainHub {
    /// @notice emitted when the designated strategy changes
    event SetStrategyForChain(address strategy, uint16 chain);

    /// @notice emitted when the designated vault changes
    event SetVaultForChain(address vault, uint16 chain);

    /// @notice emitted when the local XChainStrategy is updated
    event SetLocalStrategy(address strategy);

    /// @notice the XChainStrategy on this chain that will use the Hub
    address public localStrategy;

    /// @notice permits one and only one strategy to make deposits on each chain
    /// @dev this is due to issues with reporting and trusted payloads
    mapping(uint16 => address) public strategyForChain;

    /// @notice permits one and only one vault on this chain to make deposits for each remote chain
    /// @dev this is due to issues with reporting and trusted payloads
    mapping(uint16 => address) public vaultForChain;

    /// @dev you can set hardcoded variables in the constructor
    //       _setStrategyForChain(ADDY_AVAX_STRATEGY, DESTINATION_CHAIN_ID);
    //       _setVaultForChain(ADDY_AVAX_VAULT, DESTINATION_CHAIN_ID);
    constructor(address _stargateEndpoint, address _lzEndpoint)
        XChainHub(_stargateEndpoint, _lzEndpoint)
    {}

    /// @notice when withdrawing back to the original chain, funds will be accessible to this strategy only
    /// @param _newStrategy the address of the XChainStrategy on this chain
    function setLocalStrategy(address _newStrategy) external onlyOwner {
        require(
            trustedStrategy[_newStrategy],
            "XChainHubSingle::setLocalStrategy:UNTRUSTED"
        );
        localStrategy = _newStrategy;
        emit SetLocalStrategy(_newStrategy);
    }

    /// @notice external setter callable by the owner
    function setStrategyForChain(address _strategy, uint16 _chain)
        external
        onlyOwner
    {
        _setStrategyForChain(_strategy, _chain);
    }

    /// @notice sets designated remote strategy for a given chain
    /// @param _strategy the address of the XChainStrategy on the remote chain
    /// @param _remoteChainId the layerZero chain id on which the vault resides
    function _setStrategyForChain(address _strategy, uint16 _remoteChainId)
        internal
    {
        // require the strategy is fully withdrawn before calling
        address currentStrategyForChain = strategyForChain[_remoteChainId];
        require(
            exitingSharesPerStrategy[_remoteChainId][currentStrategyForChain] ==
                0 &&
                sharesPerStrategy[_remoteChainId][currentStrategyForChain] == 0,
            "XChainHub::setStrategyForChain:NOT EXITED"
        );
        strategyForChain[_remoteChainId] = _strategy;
        emit SetStrategyForChain(_strategy, _remoteChainId);
    }

    /// @notice external setter callable by the owner
    function setVaultForChain(address _vault, uint16 _remoteChainId)
        external
        onlyOwner
    {
        _setVaultForChain(_vault, _remoteChainId);
    }

    /// @notice sets designated vault (on this chain) for a given chain
    /// @dev must set the strategy for the chain first
    /// @param _vault the address of the vault on the this chain
    /// @param _remoteChainId the layerZero chain id where deposits will originate
    function _setVaultForChain(address _vault, uint16 _remoteChainId) internal {
        address strategy = strategyForChain[_remoteChainId];

        require(
            trustedVault[_vault],
            "XChainHub::setVaultForChain:UNTRUSTED VAULT"
        );
        require(
            strategy != address(0),
            "XChainHub::setVaultForChain:SET STRATEGY"
        );

        IVault vault = IVault(_vault);
        IVault.BatchBurnReceipt memory receipt = vault.userBatchBurnReceipts(
            strategy
        );

        require(
            vault.balanceOf(strategy) == 0 && receipt.shares == 0,
            "XChainHub::setVaultForChain:NOT EMPTY"
        );

        vaultForChain[_remoteChainId] = _vault;
        emit SetVaultForChain(_vault, _remoteChainId);
    }

    /// @notice Override deposit to hardcode strategy & vault in case of untrusted payloads
    /// @param _srcChainId comes from stargate
    /// @param _amountReceived comes from stargate
    function _sg_depositAction(
        uint16 _srcChainId,
        bytes memory,
        uint256 _amountReceived
    ) internal override {
        _makeDeposit(
            _srcChainId,
            _amountReceived,
            strategyForChain[_srcChainId],
            vaultForChain[_srcChainId]
        );
    }

    /// @notice Override finalizewithdraw to hardcode strategy & vault in case of untrusted payloads
    /// @param _srcChainId comes from stargate
    /// @param _amountReceived comes from stargate
    function _sg_finalizeWithdrawAction(
        uint16 _srcChainId,
        bytes memory,
        uint256 _amountReceived
    ) internal override {
        _saveWithdrawal(
            _srcChainId,
            vaultForChain[_srcChainId],
            localStrategy,
            _amountReceived
        );
    }
}

//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {Ownable} from "@oz/access/Ownable.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";

import {IVault} from "@interfaces/IVault.sol";
import {IHubPayload} from "@interfaces/IHubPayload.sol";
import {IStrategy} from "@interfaces/IStrategy.sol";
import {IXChainHub} from "@interfaces/IXChainHub.sol";

import {XChainHubDest} from "@hub/XChainHubDest.sol";
import {XChainHubSrc} from "@hub/XChainHubSrc.sol";
import {CallFacet} from "@hub/CallFacet.sol";
import {LayerZeroApp} from "@hub/LayerZeroApp.sol";
import {XChainHubStorage} from "@hub/XChainHubStorage.sol";
import {XChainHubEvents} from "@hub/XChainHubEvents.sol";

/// @title XChainHub
/// @notice imports Hub components into a single contract with admin functions
/// @dev we rely heavily on Solditiy's implementation of C3 Linearization to resolve dependency conflicts.
///      it is advisable you have a base understanding of the concept before changing import ordering.
contract XChainHub is
    Ownable,
    CallFacet,
    XChainHubStorage,
    XChainHubEvents,
    XChainHubSrc,
    XChainHubDest
{
    using SafeERC20 for IERC20;

    constructor(address _stargateEndpoint, address _lzEndpoint)
        XChainHubSrc(_stargateEndpoint)
        XChainHubDest(_lzEndpoint)
    {
        REPORT_DELAY = 6 hours;
    }

    /// @notice remove funds from the contract in the event that a revert locks them in
    /// @dev this could happen because of a revert on one of the forwarding functions
    /// @param _amount the quantity of tokens to remove
    /// @param _token the address of the token to withdraw
    function emergencyWithdraw(uint256 _amount, address _token)
        external
        onlyOwner
    {
        IERC20 underlying = IERC20(_token);
        /// @dev - update reporting here
        underlying.safeTransfer(msg.sender, _amount);
    }

    /// @notice Triggers the Hub's pause
    function triggerPause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    // ------------------------
    // Admin Setters
    // ------------------------

    /// @notice updates a vault on the current chain to be either trusted or untrusted
    /// @dev do not use this for trusting remote chains
    function setTrustedVault(address vault, bool trusted) external onlyOwner {
        trustedVault[vault] = trusted;
    }

    /// @notice updates a strategy on the current chain to be either trusted or untrusted
    /// @dev do not use this for trusting remote chains
    function setTrustedStrategy(address strategy, bool trusted)
        external
        onlyOwner
    {
        trustedStrategy[strategy] = trusted;
    }

    /// @notice indicates whether the vault is in an `exiting` state
    /// @dev this can potentially be removed
    function setExiting(address vault, bool exit) external onlyOwner {
        exiting[vault] = exit;
    }

    /// @notice alters the report delay to prevent overly frequent reporting
    function setReportDelay(uint64 newDelay) external onlyOwner {
        require(newDelay > 0, "XChainHub::setReportDelay:ZERO DELAY");
        REPORT_DELAY = newDelay;
    }

    /// @notice administrative override to fix broken states
    /// @param _srcChainId remote chain id
    /// @param _strategy remote strategy
    /// @param _round the batch burn round
    function setCurrentRoundPerStrategy(
        uint16 _srcChainId,
        address _strategy,
        uint256 _round
    ) external onlyOwner {
        currentRoundPerStrategy[_srcChainId][_strategy] = _round;
    }

    /// @notice administrative override to fix broken states
    /// @param _srcChainId remote chain id
    /// @param _strategy remote strategy
    /// @param _shares the number of vault shares
    function setSharesPerStrategy(
        uint16 _srcChainId,
        address _strategy,
        uint256 _shares
    ) external onlyOwner {
        sharesPerStrategy[_srcChainId][_strategy] = _shares;
    }

    /// @notice administrative override to fix broken states
    /// @param _srcChainId remote chain id
    /// @param _strategy remote strategy
    /// @param _shares the number of vault shares
    function setExitingSharesPerStrategy(
        uint16 _srcChainId,
        address _strategy,
        uint256 _shares
    ) external onlyOwner {
        exitingSharesPerStrategy[_srcChainId][_strategy] = _shares;
    }

    /// @notice administrative override to fix broken states
    /// @param _strategy XChainStrategy on this chain
    /// @param _amount qty of underlying that can be withdrawn by the strategy
    function setPendingWithdrawalPerStrategy(address _strategy, uint256 _amount)
        external
        onlyOwner
    {
        pendingWithdrawalPerStrategy[_strategy] = _amount;
    }

    /// @notice administrative override to fix broken states
    /// @param _vault address of the vault on this chain
    /// @param _round the batch burn round
    /// @param _amount the qty of underlying tokens that have been withdrawn from the vault but not yet returned
    function setWithdrawnPerRound(
        address _vault,
        uint256 _round,
        uint256 _amount
    ) external onlyOwner {
        withdrawnPerRound[_vault][_round] = _amount;
    }

    /// @notice administrative override to fix broken states
    /// @param _srcChainId remote chain id to report on
    /// @param _strategy remote strategy
    /// @param _timestamp of last report
    function setLatestUpdate(
        uint16 _srcChainId,
        address _strategy,
        uint256 _timestamp
    ) external onlyOwner {
        latestUpdate[_srcChainId][_strategy] = _timestamp;
    }
}

//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/// @title IVault
/// @notice Basic MonoVault interface.
/// @dev This interface should not change frequently and can be used to code interactions
///      for the users of the Vault. Admin functions are available through the `VaultBase` contract.
interface IVault is IERC20 {
    /*///////////////////////////////////////////////////////////////
                              Vault API Version
    ///////////////////////////////////////////////////////////////*/

    /// @notice The API version the vault implements
    function version() external view returns (string memory);

    /*///////////////////////////////////////////////////////////////
                              ERC20Detailed
    ///////////////////////////////////////////////////////////////*/

    /// @notice The Vault shares token name.
    function name() external view returns (string calldata);

    /// @notice The Vault shares token symbol.
    function symbol() external view returns (string calldata);

    /// @notice The Vault shares token decimals.
    function decimals() external view returns (uint8);

    /*///////////////////////////////////////////////////////////////
                              Batched burns
    ///////////////////////////////////////////////////////////////*/

    /// @dev Struct for users' batched burning requests.
    /// @param round Batched burning event index.
    /// @param shares Shares to burn for the user.
    struct BatchBurnReceipt {
        uint256 round;
        uint256 shares;
    }

    /// @dev Struct for batched burning events.
    /// @param totalShares Shares to burn during the event.
    /// @param amountPerShare Underlying amount per share (this differs from exchangeRate at the moment of batched burning).
    struct BatchBurn {
        uint256 totalShares;
        uint256 amountPerShare;
    }

    /// @notice Current batched burning round.
    function batchBurnRound() external view returns (uint256);

    /// @notice Maps user's address to withdrawal request.
    function userBatchBurnReceipts(address account) external view returns (BatchBurnReceipt memory);

    /// @notice Maps social burning events rounds to batched burn details.
    function batchBurns(uint256 round) external view returns (BatchBurn memory);

    /// @notice Enter a batched burn event.
    /// @dev Each user can take part to one batched burn event a time.
    /// @dev User's shares amount will be staked until the burn happens.
    /// @param shares Shares to withdraw during the next batched burn event.
    function enterBatchBurn(uint256 shares) external;

    /// @notice Withdraw underlying redeemed in batched burning events.
    function exitBatchBurn() external;

    /*///////////////////////////////////////////////////////////////
                              ERC4626-like
    ///////////////////////////////////////////////////////////////*/

    /// @notice The underlying token the vault accepts
    function underlying() external view returns (IERC20);

    /// @notice Deposit a specific amount of underlying tokens.
    /// @dev User needs to approve `underlyingAmount` of underlying tokens to spend.
    /// @param to The address to receive shares corresponding to the deposit.
    /// @param underlyingAmount The amount of the underlying token to deposit.
    /// @return shares The amount of shares minted using `underlyingAmount`.
    function deposit(address to, uint256 underlyingAmount) external returns (uint256);

    /// @notice Deposit a specific amount of underlying tokens.
    /// @dev User needs to approve `underlyingAmount` of underlying tokens to spend.
    /// @param to The address to receive shares corresponding to the deposit.
    /// @param shares The amount of Vault's shares to mint.
    /// @return underlyingAmount The amount needed to mint `shares` amount of shares.
    function mint(address to, uint256 shares) external returns (uint256);

    /// @notice Returns a user's Vault balance in underlying tokens.
    /// @param user THe user to get the underlying balance of.
    /// @return The user's Vault balance in underlying tokens.
    function balanceOfUnderlying(address user) external view returns (uint256);

    /// @notice Calculates the amount of Vault's shares for a given amount of underlying tokens.
    /// @param underlyingAmount The underlying token's amount.
    function calculateShares(uint256 underlyingAmount) external view returns (uint256);

    /// @notice Calculates the amount of underlying tokens corresponding to a given amount of Vault's shares.
    /// @param sharesAmount The shares amount.
    function calculateUnderlying(uint256 sharesAmount) external view returns (uint256);

    /// @notice Returns the amount of underlying tokens a share can be redeemed for.
    /// @return The amount of underlying tokens a share can be redeemed for.
    function exchangeRate() external view returns (uint256);

    /// @notice Returns the amount of underlying tokens that idly sit in the Vault.
    /// @return The amount of underlying tokens that sit idly in the Vault.
    function totalFloat() external view returns (uint256);

    /// @notice Calculate the current amount of locked profit.
    /// @return The current amount of locked profit.
    function lockedProfit() external view returns (uint256);

    /// @notice Calculates the total amount of underlying tokens the Vault holds.
    /// @return The total amount of underlying tokens the Vault holds.
    function totalUnderlying() external view returns (uint256);

    /// @notice Returns an estimated return for the vault.
    /// @dev This method should not be used to get a precise estimate.
    /// @return A formatted APR value
    function estimatedReturn() external view returns (uint256);
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

//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {IVault} from "@interfaces/IVault.sol";
import {IStrategy} from "@interfaces/IStrategy.sol";

/// @title The set of interfaces for the various encoded payloads transferred across chains
/// @dev assistance to the programmer for ensuring consistent serialisation and deserialisation across functions
interface IHubPayload {

    /// @notice generic container for cross chain messages
    /// @param action numerical identifier used to determine what function to call on receipt of message
    /// @param payload encoded data to be sent with the message
    struct Message {
        uint8 action;
        bytes payload;
    }

    /// @param vault on the dst chain
    /// @param strategy will be a Xchain trusted strategy on the src
    /// @param amountUnderyling to deposit
    struct DepositPayload {
        address vault;
        address strategy;
        uint256 amountUnderyling;
    }

    /// @param vault on the dst chain
    /// @param strategy (to withdraw from?)
    struct FinalizeWithdrawPayload {
        address vault;
        address strategy;
    }

    /// @param vault on the destinationc chain
    /// @param strategy the XChainStrategy to withdraw shares to
    /// @param amountVaultShares the amount of auxo vault shares to burn for underlying
    struct RequestWithdrawPayload {
        address vault;
        address strategy;
        uint256 amountVaultShares;
    }

    /// @param strategy that is being reported on
    /// @param amountToReport new underlying balance for that strategy
    struct ReportUnderlyingPayload {
        address strategy;
        uint256 amountToReport;
    }

    /// @notice arguments for the sg_depositToChain funtion
    /// @param dstChainId the layerZero chain id
    /// @param srcPoolId https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    /// @param dstPoolId https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    /// @param dstVault address of the vault on the destination chain
    /// @param amount is the amount to deposit in underlying tokens
    /// @param minOut min quantity to receive back out from swap
    /// @param refundAddress if native for fees is too high, refund to this addr on current chain
    /// @param dstGas gas to be sent with the request, for use on the dst chain.
    /// @dev destination gas is non-refundable
    struct SgDepositParams {
        uint16 dstChainId;
        uint16 srcPoolId;
        uint16 dstPoolId;
        address dstVault;
        uint256 amount;
        uint256 minOut;
        address payable refundAddress;
        uint256 dstGas;
    }

    /// @notice arguments for sg_finalizeWithdrawFromChain function
    /// @param dstChainId layerZero ChainId to send tokens
    /// @param vault the vault on this chain to validate the withdrawal against
    /// @param strategy the XChainStrategy that initially deposited the tokens
    /// @param minOutUnderlying minimum amount of underlying to receive after cross chain swap
    /// @param srcPoolId https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    /// @param dstPoolId https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    /// @param currentRound vault batch burn round when the withdraw took place
    /// @param refundAddress if native for fees is too high, refund to this addr on current chain
    /// @param dstGas gas to be sent with the request, for use on the dst chain.
    /// @dev destination gas is non-refundable
    struct SgFinalizeParams {
        uint16 dstChainId;
        address vault;
        address strategy;
        uint256 minOutUnderlying;
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 currentRound;
        address payable refundAddress;
        uint256 dstGas;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import {IVault} from "./IVault.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/// @title IStrategy
/// @notice Basic Vault Strategy interface.
interface IStrategy {
    /*///////////////////////////////////////////////////////////////
                             GENERAL INFO
    //////////////////////////////////////////////////////////////*/

    /// @notice The strategy name.
    function name() external view returns (string calldata);

    /// @notice The Vault managing this strategy.
    function vault() external view returns (IVault);

    /*///////////////////////////////////////////////////////////////
                            DEPOSIT/WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit a specific amount of underlying tokens.
    function deposit(uint256) external returns (uint8);

    /// @notice Withdraw a specific amount of underlying tokens.
    function withdraw(uint256) external returns (uint8);

    /*///////////////////////////////////////////////////////////////
                            ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    /// @notice The underlying token the strategy accepts.
    function underlying() external view returns (IERC20);

    /// @notice The amount deposited by the Vault in this strategy.
    function depositedUnderlying() external returns (uint256);

    /// @notice An estimate amount of underlying managed by the strategy.
    function estimatedUnderlying() external returns (uint256);

    /// @notice Report underlying from different domain (chain).
    function report(uint256 underlyingAmount) external;
}

//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {IStargateRouter} from "@interfaces/IStargateRouter.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {IStargateReceiver} from "@interfaces/IStargateReceiver.sol";
import {ILayerZeroReceiver} from "@interfaces/ILayerZeroReceiver.sol";
import {Pausable} from "@oz/security/Pausable.sol";
import {Ownable} from "@oz/access/Ownable.sol";
import {IVault} from "@interfaces/IVault.sol";
import {IHubPayload} from "@interfaces/IHubPayload.sol";


interface IXChainHub is IStargateReceiver, ILayerZeroReceiver {
    function DEPOSIT_ACTION() external view returns (uint8);

    function FINALIZE_WITHDRAW_ACTION() external view returns (uint8);

    function LAYER_ZERO_MAX_VALUE() external view returns (uint8);

    function REPORT_DELAY() external view returns (uint64);

    function REPORT_UNDERLYING_ACTION() external view returns (uint8);

    function REQUEST_WITHDRAW_ACTION() external view returns (uint8);

    function STARGATE_MAX_VALUE() external view returns (uint8);

    function approveWithdrawalForStrategy(
        address _strategy,
        address underlying,
        uint256 _amount
    ) external;

    function currentRoundPerStrategy(uint16, address)
        external
        view
        returns (uint256);

    function emergencyReducer(
        uint16 _srcChainId,
        IHubPayload.Message memory message,
        uint256 amount
    ) external;

    function emergencyWithdraw(uint256 _amount, address _token) external;

    function exiting(address) external view returns (bool);

    function exitingSharesPerStrategy(uint16, address)
        external
        view
        returns (uint256);

    function failedMessages(
        uint16,
        bytes memory,
        uint64
    ) external view returns (bytes32);

    function forceResumeReceive(uint16 srcChainId, bytes memory srcAddress)
        external;

    function getConfig(
        uint16 version,
        uint16 chainId,
        uint256 configType
    ) external view returns (bytes memory);

    function isTrustedRemote(uint16 srcChainId, bytes memory srcAddress)
        external
        view
        returns (bool);

    function latestUpdate(uint16, address) external view returns (uint256);

    function layerZeroEndpoint() external view returns (address);

    function lzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) external;

    function lz_reportUnderlying(
        address _vault,
        uint16[] memory _dstChains,
        address[] memory _strats,
        uint256 _dstGas,
        address _refundAddress
    ) external payable;

    function lz_requestWithdrawFromChain(
        uint16 _dstChainId,
        address _dstVault,
        uint256 _amountVaultShares,
        address _refundAddress,
        uint256 _dstGas
    ) external payable;

    function nonblockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) external;

    function owner() external view returns (address);

    function paused() external view returns (bool);

    function renounceOwnership() external;

    function retryMessage(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) external payable;

    function setConfig(
        uint16 version,
        uint16 chainId,
        uint256 configType,
        bytes memory config
    ) external;

    function setExiting(address vault, bool exit) external;

    function setReceiveVersion(uint16 version) external;

    function setReportDelay(uint64 newDelay) external;

    function setSendVersion(uint16 version) external;

    function setTrustedRemote(uint16 srcChainId, bytes memory srcAddress)
        external;

    function setTrustedStrategy(address strategy, bool trusted) external;

    function setTrustedVault(address vault, bool trusted) external;

    function sgReceive(
        uint16 _srcChainId,
        bytes memory,
        uint256,
        address,
        uint256 amountLD,
        bytes memory _payload
    ) external;

    function sg_depositToChain(IHubPayload.SgDepositParams memory _params)
        external
        payable;

    function sg_finalizeWithdrawFromChain(
        IHubPayload.SgFinalizeParams memory _params
    ) external payable;

    function sharesPerStrategy(uint16, address) external view returns (uint256);

    function stargateRouter() external view returns (address);

    function transferOwnership(address newOwner) external;

    function triggerPause() external;

    function trustedRemoteLookup(uint16) external view returns (bytes memory);

    function trustedStrategy(address) external view returns (bool);

    function trustedVault(address) external view returns (bool);

    function withdrawFromVault(address vault) external;

    function withdrawnPerRound(address, uint256)
        external
        view
        returns (uint256);
}

//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {Ownable} from "@oz/access/Ownable.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@oz/security/Pausable.sol";

import {IVault} from "@interfaces/IVault.sol";
import {IHubPayload} from "@interfaces/IHubPayload.sol";
import {IStrategy} from "@interfaces/IStrategy.sol";

import {XChainHubStorage} from "@hub/XChainHubStorage.sol";
import {XChainHubEvents} from "@hub/XChainHubEvents.sol";

import {LayerZeroApp} from "@hub/LayerZeroApp.sol";
import {IStargateReceiver} from "@interfaces/IStargateReceiver.sol";
import {IStargateRouter} from "@interfaces/IStargateRouter.sol";

/// @title XChainHub Destination
/// @notice Grouping of XChainHub functions on the destination chain
/// @dev destination refers to the chain in which XChain deposits are initially received
abstract contract XChainHubDest is
    Pausable,
    LayerZeroApp,
    IStargateReceiver,
    XChainHubStorage,
    XChainHubEvents
{
    using SafeERC20 for IERC20;

    /// --------------------------
    /// Constructor
    /// --------------------------

    /// @param _lzEndpoint address of the layerZero endpoint contract on the src chain
    constructor(address _lzEndpoint) LayerZeroApp(_lzEndpoint) {}

    /// --------------------------
    /// Single Chain Functions
    /// --------------------------

    /// @notice calls the vault on the current chain to exit batch burn
    /// @param vault the vault on this chain that contains deposits
    function withdrawFromVault(IVault vault) external onlyOwner whenNotPaused {
        uint256 round = vault.batchBurnRound();
        IERC20 underlying = vault.underlying();
        uint256 balanceBefore = underlying.balanceOf(address(this));
        vault.exitBatchBurn();
        uint256 withdrawn = underlying.balanceOf(address(this)) - balanceBefore;

        withdrawnPerRound[address(vault)][round] = withdrawn;
        emit WithdrawExecuted(withdrawn, address(vault), round);
    }

    /// --------------------------
    ///        Reducer
    /// --------------------------

    /// @notice pass actions from other entrypoint functions here
    /// @dev sgReceive and _nonBlockingLzReceive both call this function
    /// @param _srcChainId the layerZero chain ID
    /// @param message containing action type and payload
    function _reducer(
        uint16 _srcChainId,
        IHubPayload.Message memory message,
        uint256 amount
    ) internal {
        if (message.action == DEPOSIT_ACTION) {
            _sg_depositAction(_srcChainId, message.payload, amount);
        } else if (message.action == REQUEST_WITHDRAW_ACTION) {
            _lz_requestWithdrawAction(_srcChainId, message.payload);
        } else if (message.action == FINALIZE_WITHDRAW_ACTION) {
            _sg_finalizeWithdrawAction(_srcChainId, message.payload, amount);
        } else if (message.action == REPORT_UNDERLYING_ACTION) {
            _lz_reportUnderlyingAction(_srcChainId, message.payload);
        } else {
            revert("XChainHub::_reducer:UNRECOGNISED ACTION");
        }
    }

    /// @notice allows the owner to call the reducer if needed
    /// @dev if a previous transaction fails due an out of gas error, it is preferable simply
    ///      to retry the message, or it will be sitting in the stuck messages queue and will open
    ///      up a replay attack vulnerability
    /// @param _srcChainId chainId to simulate from
    /// @param message the payload to send
    /// @param amount to send in case of deposit action
    function emergencyReducer(
        uint16 _srcChainId,
        IHubPayload.Message memory message,
        uint256 amount
    ) external onlyOwner {
        _reducer(_srcChainId, message, amount);
    }

    /// --------------------------
    ///    Entrypoints
    /// --------------------------

    /// @notice called by the stargate application on the dstChain
    /// @dev invoked when IStargateRouter.swap is called
    /// @param _srcChainId layerzero chain id on src
    /// @param amountLD of underlying tokens actually received (after swap fees)
    /// @param _payload encoded payload data as IHubPayload.Message
    function sgReceive(
        uint16 _srcChainId,
        bytes memory, // address of *router* on src
        uint256, // nonce
        address, // the underlying contract on this chain
        uint256 amountLD,
        bytes memory _payload
    ) external override whenNotPaused {
        require(
            msg.sender == address(stargateRouter),
            "XChainHub::sgRecieve:NOT STARGATE ROUTER"
        );

        if (_payload.length > 0) {
            IHubPayload.Message memory message = abi.decode(
                _payload,
                (IHubPayload.Message)
            );

            // actions 0 - 85 cannot be initiated through sgReceive
            require(
                message.action > LAYER_ZERO_MAX_VALUE,
                "XChainHub::sgRecieve:PROHIBITED ACTION"
            );

            _reducer(_srcChainId, message, amountLD);
        }
    }

    /// @notice called by the Lz application on the dstChain, then executes the corresponding action.
    /// @param _srcChainId the layerZero chain id
    /// @param _payload bytes encoded Message to be passed to the action
    /// @dev do not confuse _payload with Message.payload, these are encoded separately
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory, // srcAddress
        uint64, // nonce
        bytes memory _payload
    ) internal virtual override whenNotPaused {
        if (_payload.length > 0) {
            IHubPayload.Message memory message = abi.decode(
                _payload,
                (IHubPayload.Message)
            );

            // actions 86 - 171 cannot be initiated through layerzero
            require(
                message.action <= LAYER_ZERO_MAX_VALUE ||
                    message.action > STARGATE_MAX_VALUE,
                "XChainHub::_nonblockingLzReceive:PROHIBITED ACTION"
            );

            _reducer(_srcChainId, message, 0);
        }
    }

    /// --------------------------
    /// Action Functions
    /// --------------------------

    /// @notice called on destination chain to deposit underlying tokens into a vault
    /// @dev the payload here cannot be trusted, use XChainHubSingle if you need to do critical operations
    /// @param _srcChainId layerZero chain id from where deposit came
    /// @param _payload abi encoded as IHubPayload.DepositPayload
    /// @param _amountReceived underlying tokens to be deposited
    function _sg_depositAction(
        uint16 _srcChainId,
        bytes memory _payload,
        uint256 _amountReceived
    ) internal virtual {
        IHubPayload.DepositPayload memory payload = abi.decode(
            _payload,
            (IHubPayload.DepositPayload)
        );
        _makeDeposit(
            _srcChainId,
            _amountReceived,
            payload.strategy,
            payload.vault
        );
    }

    /// @notice actions the deposit
    /// @param _srcChainId what layerZero chainId was the request initiated from
    /// @param _amountReceived is the amount of underyling from stargate swap after fees
    /// @param _strategy source XChainStrategy of the deposit request
    /// @param _vault in which to make the deposit
    function _makeDeposit(
        uint16 _srcChainId,
        uint256 _amountReceived,
        address _strategy,
        address _vault
    ) internal virtual {
        require(
            trustedVault[_vault],
            "XChainHub::_depositAction:UNTRUSTED VAULT"
        );
        IVault vault = IVault(_vault);
        IERC20 underlying = vault.underlying();

        uint256 vaultBalance = vault.balanceOf(address(this));

        // make the deposit
        underlying.safeIncreaseAllowance(address(vault), _amountReceived);
        vault.deposit(address(this), _amountReceived);

        // shares minted is the differential in balances before and after
        uint256 mintedShares = vault.balanceOf(address(this)) - vaultBalance;
        sharesPerStrategy[_srcChainId][_strategy] += mintedShares;

        emit DepositReceived(
            _srcChainId,
            _amountReceived,
            mintedShares,
            _vault,
            _strategy
        );
    }

    /// @notice enter the batch burn for a vault on the current chain
    /// @param _srcChainId layerZero chain id where the request originated
    /// @param _payload abi encoded as IHubPayload.RequestWithdrawPayload
    function _lz_requestWithdrawAction(
        uint16 _srcChainId,
        bytes memory _payload
    ) internal virtual {
        IHubPayload.RequestWithdrawPayload memory decoded = abi.decode(
            _payload,
            (IHubPayload.RequestWithdrawPayload)
        );

        // check the vault is in the correct state and is trusted
        address _vault = decoded.vault;
        require(
            trustedVault[_vault],
            "XChainHub::_requestWithdrawAction:UNTRUSTED"
        );
        /// @dev TODO should not be exiting? or maybe we can top up?
        require(
            exiting[_vault],
            "XChainHub::_requestWithdrawAction:VAULT NOT EXITING"
        );

        IVault vault = IVault(_vault);
        // check the strategy is trusted

        address strategy = decoded.strategy;
        uint256 amountVaultShares = decoded.amountVaultShares;

        uint256 round = vault.batchBurnRound();
        uint256 currentRound = currentRoundPerStrategy[_srcChainId][strategy];

        require(
            currentRound == 0 || currentRound == round,
            "XChainHub::_requestWithdrawAction:ROUNDS MISMATCHED"
        );
        require(
            sharesPerStrategy[_srcChainId][strategy] >= amountVaultShares,
            "XChainHub::_requestWithdrawAction:INSUFFICIENT SHARES"
        );

        // when execBatchBurn is called, the round will increment
        /// @dev TODO how to solve - we could increment it here?
        currentRoundPerStrategy[_srcChainId][strategy] = round;

        // this now prevents reporting because shares will be zero
        sharesPerStrategy[_srcChainId][strategy] -= amountVaultShares;
        exitingSharesPerStrategy[_srcChainId][strategy] += amountVaultShares;

        /// @dev TODO should set exiting here

        vault.enterBatchBurn(amountVaultShares);

        emit WithdrawRequestReceived(
            _srcChainId,
            amountVaultShares,
            _vault,
            strategy
        );
    }

    /// @notice callback executed when funds are withdrawn back to origin chain
    /// @dev the payload here cannot be trusted, use XChainHubSingle if you need to do critical operations
    /// @param _srcChainId what layerZero chainId was the request initiated from
    /// @param _payload abi encoded as IHubPayload.FinalizeWithdrawPayload
    /// @param _amountReceived the qty of underlying tokens that were received
    function _sg_finalizeWithdrawAction(
        uint16 _srcChainId,
        bytes memory _payload,
        uint256 _amountReceived
    ) internal virtual {
        IHubPayload.FinalizeWithdrawPayload memory payload = abi.decode(
            _payload,
            (IHubPayload.FinalizeWithdrawPayload)
        );
        _saveWithdrawal(
            _srcChainId,
            payload.vault,
            payload.strategy,
            _amountReceived
        );
    }

    /// @notice actions the withdrawal
    /// @param _vault is the remote vault
    /// @param _strategy is the strategy on this chain
    function _saveWithdrawal(
        uint16 _srcChainId,
        address _vault,
        address _strategy,
        uint256 _amountReceived
    ) internal virtual {
        require(
            trustedStrategy[_strategy],
            "XChainHub::_saveWithdrawal:UNTRUSTED STRATEGY"
        );
        pendingWithdrawalPerStrategy[_strategy] += _amountReceived;
        emit WithdrawalReceived(
            _srcChainId,
            _amountReceived,
            _vault,
            _strategy
        );
    }

    /// @notice underlying holdings are updated on another chain and this function is broadcast
    ///     to all other chains for the strategy.
    /// @param _srcChainId the layerZero chain id from where the request originates
    /// @param _payload byte encoded data adhering to IHubPayload.lz_reportUnderlyingPayload
    function _lz_reportUnderlyingAction(
        uint16 _srcChainId,
        bytes memory _payload
    ) internal virtual {
        IHubPayload.ReportUnderlyingPayload memory payload = abi.decode(
            _payload,
            (IHubPayload.ReportUnderlyingPayload)
        );

        IStrategy(payload.strategy).report(payload.amountToReport);
        emit UnderlyingUpdated(
            _srcChainId,
            payload.amountToReport,
            payload.strategy
        );
    }
}

//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@oz/security/Pausable.sol";

import {IVault} from "@interfaces/IVault.sol";
import {IHubPayload} from "@interfaces/IHubPayload.sol";
import {IStrategy} from "@interfaces/IStrategy.sol";

import {XChainHubStorage} from "@hub/XChainHubStorage.sol";
import {XChainHubEvents} from "@hub/XChainHubEvents.sol";

import {LayerZeroApp} from "@hub/LayerZeroApp.sol";
import {IStargateReceiver} from "@interfaces/IStargateReceiver.sol";
import {IStargateRouter} from "@interfaces/IStargateRouter.sol";

/// @title XChainHub Source
/// @notice Grouping of XChainHub functions on the source chain
/// @dev source refers to the chain initially sending XChain deposits
abstract contract XChainHubSrc is
    Pausable,
    LayerZeroApp,
    XChainHubStorage,
    XChainHubEvents
{
    using SafeERC20 for IERC20;

    constructor(address _stargateRouter) {
        stargateRouter = IStargateRouter(_stargateRouter);
    }

    /// ------------------------
    /// Single Chain Functions
    /// ------------------------

    /// @notice called by the strategy to extract funds that have arrived in the hub
    /// @dev only callable by the strategy
    /// @param _amount underlying quantity to withdraw from the hub
    function withdrawFromHub(uint256 _amount) external whenNotPaused {
        require(
            trustedStrategy[msg.sender],
            "XChainHub::withdrawPending:UNTRUSTED"
        );
        uint256 maxWithdrawal = pendingWithdrawalPerStrategy[msg.sender];
        require(
            _amount <= maxWithdrawal,
            "XChainHub::withdrawPending:INSUFFICENT FUNDS FOR WITHDRAWAL"
        );

        pendingWithdrawalPerStrategy[msg.sender] -= _amount;

        IERC20 underlying = IStrategy(msg.sender).underlying();
        // underlying.safeIncreaseAllowance(msg.sender, _amount);
        underlying.safeTransfer(msg.sender, _amount);
    }

    // --------------------------
    // Cross Chain Functions
    // --------------------------

    /// @notice iterates through a list of destination chains and sends the current value of
    ///         the strategy (in terms of the underlying vault token) to that chain.
    /// @param _vault Vault on the current chain.
    /// @param _dstChains is an array of the layerZero chain Ids to check
    /// @param _strats array of strategy addresses on the destination chains, index should match the dstChainId
    /// @param _dstGas required on dstChain for operations
    /// @dev There are a few caveats:
    ///       - All strategies must have deposits.
    ///       - Strategies must be trusted
    ///       - The list of chain ids and strategy addresses must be the same length, and use the same underlying token.
    function lz_reportUnderlying(
        IVault _vault,
        uint16[] memory _dstChains,
        address[] memory _strats,
        uint256 _dstGas,
        address payable _refundAddress
    ) external payable onlyOwner whenNotPaused {
        require(REPORT_DELAY > 0, "XChainHub::reportUnderlying:SET DELAY");
        require(
            trustedVault[address(_vault)],
            "XChainHub::reportUnderlying:UNTRUSTED"
        );
        require(
            _dstChains.length == _strats.length,
            "XChainHub::reportUnderlying:LENGTH MISMATCH"
        );

        uint256 amountToReport;
        uint256 exchangeRate = _vault.exchangeRate();

        for (uint256 i; i < _dstChains.length; i++) {
            uint256 shares = sharesPerStrategy[_dstChains[i]][_strats[i]];

            /// @dev: we explicitly check for zero deposits withdrawing
            /// TODO check whether we need this, for now it is commented
            // require(shares > 0, "XChainHub::reportUnderlying:NO DEPOSITS");

            require(
                block.timestamp >=
                    latestUpdate[_dstChains[i]][_strats[i]] + REPORT_DELAY,
                "XChainHub::reportUnderlying:TOO RECENT"
            );

            // record the latest update for future reference
            latestUpdate[_dstChains[i]][_strats[i]] = block.timestamp;

            amountToReport = (shares * exchangeRate) / 10**_vault.decimals();

            IHubPayload.Message memory message = IHubPayload.Message({
                action: REPORT_UNDERLYING_ACTION,
                payload: abi.encode(
                    IHubPayload.ReportUnderlyingPayload({
                        strategy: _strats[i],
                        amountToReport: amountToReport
                    })
                )
            });

            _lzSend(
                _dstChains[i],
                abi.encode(message),
                _refundAddress,
                address(0), // zro address (not used)
                abi.encodePacked(uint8(1), _dstGas) // version 1 only accepts dstGas
            );

            emit UnderlyingReported(_dstChains[i], amountToReport, _strats[i]);
        }
    }

    /// @notice approve transfer to the stargate router
    /// @dev stack too deep prevents keeping in function below
    function _approveRouterTransfer(address _sender, uint256 _amount) internal {
        IStrategy strategy = IStrategy(_sender);
        IERC20 underlying = strategy.underlying();

        underlying.safeTransferFrom(_sender, address(this), _amount);
        underlying.safeIncreaseAllowance(address(stargateRouter), _amount);
    }

    /// @dev Only Called by the Cross Chain Strategy
    /// @notice makes a deposit of the underyling token into the vault on a given chain
    /// @param _params a stuct encoding the deposit paramters
    function sg_depositToChain(IHubPayload.SgDepositParams calldata _params)
        external
        payable
        whenNotPaused
    {
        require(
            trustedStrategy[msg.sender],
            "XChainHub::depositToChain:UNTRUSTED"
        );

        bytes memory dstHub = trustedRemoteLookup[_params.dstChainId];

        require(dstHub.length != 0, "XChainHub::depositToChain:NO HUB");

        // load some variables into memory
        uint256 amount = _params.amount;
        address dstVault = _params.dstVault;

        _approveRouterTransfer(msg.sender, amount);

        IHubPayload.Message memory message = IHubPayload.Message({
            action: DEPOSIT_ACTION,
            payload: abi.encode(
                IHubPayload.DepositPayload({
                    vault: dstVault,
                    strategy: msg.sender,
                    amountUnderyling: amount
                })
            )
        });

        stargateRouter.swap{value: msg.value}(
            _params.dstChainId,
            _params.srcPoolId,
            _params.dstPoolId,
            _params.refundAddress,
            amount,
            _params.minOut,
            IStargateRouter.lzTxObj({
                dstGasForCall: _params.dstGas,
                dstNativeAmount: 0,
                dstNativeAddr: abi.encodePacked(address(0x0))
            }),
            dstHub, // This hub must implement sgReceive
            abi.encode(message)
        );
        emit DepositSent(
            _params.dstChainId,
            amount,
            dstHub,
            dstVault,
            msg.sender
        );
    }

    /// @notice Only called by x-chain Strategy
    /// @dev IMPORTANT you need to add the dstHub as a trustedRemote on the src chain BEFORE calling
    ///      any layerZero functions. Call `setTrustedRemote` on this contract as the owner
    ///      with the params (dstChainId - LAYERZERO, dstHub address)
    /// @notice make a request to withdraw tokens from a vault on a specified chain
    ///         the actual withdrawal takes place once the batch burn process is completed
    /// @param _dstChainId the layerZero chain id on destination
    /// @param _dstVault address of the vault on destination
    /// @param _amountVaultShares the number of auxovault shares to burn for underlying
    /// @param _refundAddress addrss on the this chain to send gas rebates to
    /// @param _dstGas required on dstChain for operations
    function lz_requestWithdrawFromChain(
        uint16 _dstChainId,
        address _dstVault,
        uint256 _amountVaultShares,
        address payable _refundAddress,
        uint256 _dstGas
    ) external payable whenNotPaused {
        require(
            trustedStrategy[msg.sender],
            "XChainHub::requestWithdrawFromChain:UNTRUSTED"
        );
        require(
            _dstVault != address(0x0),
            "XChainHub::requestWithdrawFromChain:NO DST VAULT"
        );

        IHubPayload.Message memory message = IHubPayload.Message({
            action: REQUEST_WITHDRAW_ACTION,
            payload: abi.encode(
                IHubPayload.RequestWithdrawPayload({
                    vault: _dstVault,
                    strategy: msg.sender,
                    amountVaultShares: _amountVaultShares
                })
            )
        });

        _lzSend(
            _dstChainId,
            abi.encode(message),
            _refundAddress,
            address(0), // ZRO address (not implemented)
            abi.encodePacked(uint8(1), _dstGas) // version 1 only accepts dstGas
        );

        emit WithdrawRequested(
            _dstChainId,
            _amountVaultShares,
            _dstVault,
            msg.sender
        );
    }

    function _getTrustedHub(uint16 _srcChainId)
        internal
        view
        returns (address)
    {
        address hub;
        bytes memory _h = trustedRemoteLookup[_srcChainId];
        assembly {
            hub := mload(_h)
        }
        return hub;
    }

    /// @notice approves the stargate router to transfer underlying tokens from the hub
    /// @param _vault the vault on this chain
    /// @param _amount the number of tokens to approve
    function _approveRouter(address _vault, uint256 _amount) internal {
        IVault vault = IVault(_vault);
        IERC20 underlying = vault.underlying();
        underlying.safeIncreaseAllowance(address(stargateRouter), _amount);
    }

    /// @notice sends tokens withdrawn from local vault to a remote hub
    /// @param _params struct encoding arguments
    function sg_finalizeWithdrawFromChain(
        IHubPayload.SgFinalizeParams calldata _params
    ) external payable whenNotPaused onlyOwner {
        /// @dev passing manually at the moment
        // uint256 currentRound = currentRoundPerStrategy[_dstChainId][_strategy];

        bytes memory dstHub = trustedRemoteLookup[_params.dstChainId];
        uint256 shares = exitingSharesPerStrategy[_params.dstChainId][
            _params.strategy
        ];

        require(
            dstHub.length != 0,
            "XChainHub::finalizeWithdrawFromChain:NO HUB"
        );
        require(
            _params.currentRound > 0,
            "XChainHub::finalizeWithdrawFromChain:NO ACTIVE ROUND"
        );
        require(
            !exiting[_params.vault],
            "XChainHub::finalizeWithdrawFromChain:EXITING"
        );
        require(
            trustedVault[_params.vault],
            "XChainHub::finalizeWithdrawFromChain:UNTRUSTED VAULT"
        );

        // move external contract calls until after we have vetted the vault
        uint256 strategyAmount = IVault(_params.vault).calculateUnderlying(
            shares
        );

        // here we copld check strategy in the vault
        require(
            strategyAmount > 0,
            "XChainHub::finalizeWithdrawFromChain:NO WITHDRAWS"
        );

        _approveRouter(_params.vault, strategyAmount);

        withdrawnPerRound[_params.vault][
            _params.currentRound
        ] -= strategyAmount;
        // if we check dont need to reindex
        currentRoundPerStrategy[_params.dstChainId][_params.strategy] = 0;
        exitingSharesPerStrategy[_params.dstChainId][_params.strategy] = 0;

        IHubPayload.Message memory message = IHubPayload.Message({
            action: FINALIZE_WITHDRAW_ACTION,
            payload: abi.encode(
                IHubPayload.FinalizeWithdrawPayload({
                    vault: _params.vault,
                    strategy: _params.strategy
                })
            )
        });

        stargateRouter.swap{value: msg.value}(
            _params.dstChainId,
            _params.srcPoolId,
            _params.dstPoolId,
            _params.refundAddress,
            strategyAmount,
            _params.minOutUnderlying,
            IStargateRouter.lzTxObj({
                dstGasForCall: _params.dstGas,
                dstNativeAmount: 0,
                dstNativeAddr: abi.encodePacked(address(0x0))
            }),
            dstHub,
            abi.encode(message)
        );

        emit WithdrawalSent(
            _params.dstChainId,
            strategyAmount,
            dstHub,
            _params.vault,
            _params.strategy,
            _params.currentRound
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {ReentrancyGuard} from "@oz/security/ReentrancyGuard.sol";
import {Ownable} from "@oz/access/Ownable.sol";

contract CallFacet is Ownable, ReentrancyGuard {
    event Call(address indexed caller, address indexed target, bytes data, uint256 value);

    function call(address[] memory _targets, bytes[] memory _calldata, uint256[] memory _values)
        public
        nonReentrant
        onlyOwner
    {
        require(_targets.length == _calldata.length && _values.length == _calldata.length, "ARRAY_LENGTH_MISMATCH");

        for (uint256 i = 0; i < _targets.length; i++) {
            _call(_targets[i], _calldata[i], _values[i]);
        }
    }

    function callNoValue(address[] memory _targets, bytes[] memory _calldata) public nonReentrant onlyOwner {
        require(_targets.length == _calldata.length, "ARRAY_LENGTH_MISMATCH");

        for (uint256 i = 0; i < _targets.length; i++) {
            _call(_targets[i], _calldata[i], 0);
        }
    }

    function singleCall(address _target, bytes calldata _calldata, uint256 _value) external nonReentrant onlyOwner {
        _call(_target, _calldata, _value);
    }

    function _call(address _target, bytes memory _calldata, uint256 _value) internal {
        require(address(this).balance >= _value, "ETH_BALANCE_TOO_LOW");
        (bool success,) = _target.call{value: _value}(_calldata);
        require(success, "CALL_FAILED");
        emit Call(msg.sender, _target, _calldata, _value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ILayerZeroReceiver} from "@interfaces/ILayerZeroReceiver.sol";
import {ILayerZeroEndpoint} from "@interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroUserApplicationConfig} from "@interfaces/ILayerZeroUserApplicationConfig.sol";

/// @title LayerZeroApp
/// @notice A generic app template that uses LayerZero.
/// @dev this contract is in large part provided by the layer zero team
abstract contract LayerZeroApp is
    Ownable,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    /// @notice The LayerZero endpoint for the current chain.
    ILayerZeroEndpoint public immutable layerZeroEndpoint;

    /// @notice The remote trusted parties.
    mapping(uint16 => bytes) public trustedRemoteLookup;

    /// @notice Failed messages.
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
        public failedMessages;

    /// @notice Event emitted when a new remote trusted is added.
    /// @param srcChainId Source chain id.
    /// @param srcAddress Trusted address.
    event SetTrustedRemote(uint16 srcChainId, bytes srcAddress);

    /// @notice Event emitted when a message fails.
    /// @param srcChainId Source chain id.
    /// @param srcAddress Source address.
    /// @param nonce Message nonce.
    /// @param payload Message payload.
    event MessageFailed(
        uint16 srcChainId,
        bytes srcAddress,
        uint64 nonce,
        bytes payload
    );

    /// @notice Initialize contract.
    /// @param endpoint The LayerZero endpoint.
    constructor(address endpoint) {
        layerZeroEndpoint = ILayerZeroEndpoint(endpoint);
    }

    function lzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) public virtual override {
        require(
            msg.sender == address(layerZeroEndpoint),
            "LayerZeroApp::lzReceive:UNAUTHORISED"
        );

        bytes memory trustedRemote = trustedRemoteLookup[srcChainId];

        require(
            srcAddress.length == trustedRemote.length &&
                keccak256(srcAddress) == keccak256(trustedRemote),
            "LayerZeroApp::lzReceive:INVALID REMOTE"
        );

        _lzReceive(srcChainId, srcAddress, nonce, payload);
    }

    /// @dev - interesting function here, pass control flow to attacker
    /// even if the payload is fixed.
    function retryMessage(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) public payable virtual {
        bytes32 payloadHash = failedMessages[srcChainId][srcAddress][nonce];

        require(
            payloadHash != bytes32(0),
            "LayerZeroApp::retryMessage:NOT FOUND"
        );

        require(
            keccak256(payload) == payloadHash,
            "LayerZeroApp::retryMessage:HASH INCORRECT"
        );

        failedMessages[srcChainId][srcAddress][nonce] = bytes32(0);

        _nonblockingLzReceive(srcChainId, srcAddress, nonce, payload);
    }

    function _lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual {
        // try-catch all errors/exceptions
        try
            this.nonblockingLzReceive(
                _srcChainId,
                _srcAddress,
                _nonce,
                _payload
            )
        {} catch {
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(
                _payload
            );
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function nonblockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) public virtual {
        require(
            msg.sender == address(this),
            "LayerZeroApp::nonblockingLzReceive:UNAUTHORIZED"
        );

        _nonblockingLzReceive(srcChainId, srcAddress, nonce, payload);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    /// @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    /// @param _dstChainId - the destination chain identifier
    /// @param _payload - a custom bytes payload to send to the destination contract
    /// @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    /// @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    /// @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        // dst chain comes from the array
        // when it arrives
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];

        // this is all good
        require(
            trustedRemote.length != 0,
            "LayerZeroApp::lzSend:UNTRUSTED DESTINATION"
        );

        layerZeroEndpoint.send{value: msg.value}(
            _dstChainId, // this is okay
            // this is pulled from the trustedRemoteLookup - if sending from dstHub, we expect it to be srcHub
            trustedRemote,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    function getConfig(
        uint16 version,
        uint16 chainId,
        uint256 configType
    ) external view returns (bytes memory) {
        return
            layerZeroEndpoint.getConfig(
                version,
                chainId,
                address(this),
                configType
            );
    }

    function setConfig(
        uint16 version,
        uint16 chainId,
        uint256 configType,
        bytes calldata config
    ) external override onlyOwner {
        layerZeroEndpoint.setConfig(version, chainId, configType, config);
    }

    function setSendVersion(uint16 version) external override onlyOwner {
        layerZeroEndpoint.setSendVersion(version);
    }

    function setReceiveVersion(uint16 version) external override onlyOwner {
        layerZeroEndpoint.setReceiveVersion(version);
    }

    function forceResumeReceive(uint16 srcChainId, bytes calldata srcAddress)
        external
        override
        onlyOwner
    {
        layerZeroEndpoint.forceResumeReceive(srcChainId, srcAddress);
    }

    function setTrustedRemote(uint16 srcChainId, bytes calldata srcAddress)
        external
        onlyOwner
    {
        trustedRemoteLookup[srcChainId] = srcAddress;
        emit SetTrustedRemote(srcChainId, srcAddress);
    }

    function isTrustedRemote(uint16 srcChainId, bytes calldata srcAddress)
        external
        view
        returns (bool)
    {
        bytes memory trustedSource = trustedRemoteLookup[srcChainId];
        return keccak256(trustedSource) == keccak256(srcAddress);
    }
}

//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {IStargateRouter} from "@interfaces/IStargateRouter.sol";

/// @title XChainHubBase
/// @notice state variables and functions not involving LayerZero technologies
/// @dev Expect this contract to change in future.
/// @dev ownable is provided by CallFacet
contract XChainHubStorage {
    /// @notice Trusted vaults - use only to trust vaults on chains which funds are recevied
    mapping(address => bool) public trustedVault;

    /// @notice Trusted strategies - use only to trust strategies on chain from which funds are sent
    mapping(address => bool) public trustedStrategy;

    /// @notice Indicates if the hub is gathering exit request for a given vault.
    mapping(address => bool) public exiting;

    /// @notice Indicates withdrawn amount per round (in underlying) for a given vault.
    /// @dev format vaultAddr => round => withdrawn
    mapping(address => mapping(uint256 => uint256)) public withdrawnPerRound;

    /// @notice underlying tokens sitting in the hub, sent back from remote chain
    ///         waiting to be withdrawn to a strategy on this chain
    /// @dev strategy on this chain => qty underlying
    mapping(address => uint256) public pendingWithdrawalPerStrategy;

    // --------------------------
    // Cross Chain Mappings
    // --------------------------

    /// @notice Shares held on behalf of strategies from other chains, Origin Chain ID => Strategy => Shares
    /// @dev Each strategy will have one and only one underlying forever.
    mapping(uint16 => mapping(address => uint256)) public sharesPerStrategy;

    /// @notice Origin Chain ID => Strategy => CurrentRound (Batch Burn)
    mapping(uint16 => mapping(address => uint256))
        public currentRoundPerStrategy;

    /// @notice Shares waiting for burn. Origin Chain ID => Strategy => ExitingShares
    mapping(uint16 => mapping(address => uint256))
        public exitingSharesPerStrategy;

    /// @notice Latest updated block.timestamp per strategy. Origin Chain ID => Strategy => LatestUpdate
    mapping(uint16 => mapping(address => uint256)) public latestUpdate;

    // --------------------------
    // Variables
    // --------------------------

    /// Prevent reporting function called too frequently
    uint64 public REPORT_DELAY;

    /// @notice https://stargateprotocol.gitbook.io/stargate/developers/official-erc20-addresses
    IStargateRouter public stargateRouter;

    // --------------------------
    // Actions
    // --------------------------

    /// @dev some actions involve stargate swaps while others involve lz messages
    ///      * 0 - 85: Actions should only be triggered by LayerZero
    ///      * 86 - 171: Actions should only be triggered by sgReceive
    ///      * 172 - 255: Actions can be triggered by either
    uint8 public constant LAYER_ZERO_MAX_VALUE = 85;
    uint8 public constant STARGATE_MAX_VALUE = 171;

    /// LAYERZERO ACTION::Begin the batch burn process
    uint8 public constant REQUEST_WITHDRAW_ACTION = 0;

    /// LAYERZERO ACTION::Report underlying from different chain
    uint8 public constant REPORT_UNDERLYING_ACTION = 1;

    /// STARGATE ACTION::Enter into a vault
    uint8 public constant DEPOSIT_ACTION = 86;

    /// STARGATE ACTION::Send funds back to origin chain after a batch burn
    uint8 public constant FINALIZE_WITHDRAW_ACTION = 87;
}

//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

/// @notice events that can be shared between XChainHub instances (such as when testing)
contract XChainHubEvents {
    /// @notice emitted on the source chain when a deposit request is successfully sent
    /// @param dstChainId destination layerZero chainId
    /// @param amountUnderlying sent with the request
    /// @param dstHub address of the remote hub
    /// @param vault on the remote chain to deposit into
    /// @param strategy XChainStrategy on this chain that made the deposit
    event DepositSent(uint16 dstChainId, uint256 amountUnderlying, bytes dstHub, address vault, address strategy);

    /// @notice emitted on the destination chain from DepositSent when a deposit is made into a vault
    /// @param srcChainId origin layerZero chain id of the Tx
    /// @param amountUnderlyingReceived as a deposit
    /// @param sharesMinted in return for underlying
    /// @param vault on this chain that accepted deposits
    /// @param strategy XChainStrategy (remote) that originally made the deposit
    event DepositReceived(
        uint16 srcChainId, uint256 amountUnderlyingReceived, uint256 sharesMinted, address vault, address strategy
    );

    /// @notice emitted on the source chain when a request to enter batch burn is successfully sent
    /// @param dstChainId destination layerZero chainId
    /// @param shares to burn
    /// @param vault on the remote chain to burn shares
    /// @param strategy Xchainstrategy originating the request
    event WithdrawRequested(uint16 dstChainId, uint256 shares, address vault, address strategy);

    /// @notice emitted on the destination chain from WithdrawRequested when a request to enter batch burn is accepted
    /// @param srcChainId origin layerZero chain id of the Tx
    /// @param shares to burn
    /// @param vault address of the vault on this chain to redeem from
    /// @param strategy remote XChainStrategy address from which the request was sent
    event WithdrawRequestReceived(uint16 srcChainId, uint256 shares, address vault, address strategy);

    /// @notice emitted when the hub successfully withdraws underlying after a batch burn
    /// @param withdrawn underlying token qty that have been redeemed
    /// @param vault address of the remote vault
    /// @param round batch burn execution round
    event WithdrawExecuted(uint256 withdrawn, address vault, uint256 round);

    /// @notice emitted on the source chain when withdrawn tokens have been sent to the destination hub
    /// @param amountUnderlying that were sent back
    /// @param dstChainId destination layerZero chainId
    /// @param dstHub address of the remote hub
    /// @param vault from which tokens withdrawn on this chain
    /// @param strategy remote Xchainstrategy address
    /// @param round the round which was passed
    event WithdrawalSent(
        uint16 dstChainId, uint256 amountUnderlying, bytes dstHub, address vault, address strategy, uint256 round
    );

    /// @notice emitted on the destination chain from WithdrawlSent when tokens have been received
    /// @param srcChainId origin layerZero chain id of the Tx
    /// @param amountUnderlying that were received
    /// @param vault remote vault from which tokens withdrawn
    /// @param strategy on this chain to which the tokens are destined
    event WithdrawalReceived(uint16 srcChainId, uint256 amountUnderlying, address vault, address strategy);

    /// @notice emitted on the source chain when a message is sent to update underlying balances for a strategy
    /// @param dstChainId destination layerZero chainId
    /// @param amount amount of underlying tokens reporte
    /// @param strategy remote Xchainstrategy address
    event UnderlyingReported(uint16 dstChainId, uint256 amount, address strategy);

    /// @notice emitted on the destination chain from UnderlyingReported on receipt of a report of underlying changed
    /// @param srcChainId origin layerZero chain id of the Tx
    /// @param amount of underlying tokens reporte
    /// @param strategy Xchainstrategy address on this chain
    event UnderlyingUpdated(uint16 srcChainId, uint256 amount, address strategy);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

pragma abicoder v2;

interface IStargateRouter {
    /// @notice the LayerZero Transaction Object
    /// @dev allows custom gas limits and airdrops on the dst chain
    /// @dev https://layerzero.gitbook.io/docs/guides/advanced/relayer-adapter-parameters
    /// @param dstGasForCall override the default 200,000 gas limit for a custom call
    /// @param dstNativeAmount amount of native on the dst chain to transfer to dstNativeAddr
    /// @param dstNativeAddr an address on the dst chain where dstNativeAmount will be sent
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    /// @notice adds liquidity to a stargate pool on the current chain
    /// @param _poolId the stargate poolId representing the specific ERC20 token
    /// @param _amountLD the amount to loan. quantity in local decimals
    /// @param _to the address to receive the LP token. ie: shares of the pool
    function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external;

    /// @notice executes the stargate swap
    /// @param _dstChainId the layerZero chainId for the destination chain
    /// @param _srcPoolId source pool id
    /// @param _dstPoolId destination pool id
    /// @dev pool ids found here: https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    /// @param _refundAddress if msg.sender pays too much gas, return extra native
    /// @param _amountLD total tokens to send to destination chain
    /// @param _minAmountLD min tokens allowed out on dstChain
    /// @param _lzTxParams send native or adjust gas limits on dstChain
    /// @param _to encoded destination address, must implement sgReceive()
    /// @param _payload pass arbitrary data which will be available in sgReceive()
    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    )
        external
        payable;

    /// @notice Removing user liquidity across multiple chains..
    /// @param _dstChainId the chainId to remove liquidity
    /// @param _srcPoolId the source poolId
    /// @param _dstPoolId the destination poolId
    /// @param _refundAddress refund extra native gas to this address
    /// @param _amountLP quantity of LP tokens to redeem
    /// @param _minAmountLD slippage amount in local decimals
    /// @param _to the address to redeem the poolId asset to
    /// @param _lzTxParams adpater parameters
    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    )
        external
        payable;

    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external returns (uint256);

    /// @notice Removing user liquidity on local chain.
    /// @param _dstChainId the chainId to remove liquidity
    /// @param _srcPoolId the source poolId
    /// @param _dstPoolId the destination poolId
    /// @param _refundAddress refund extra native gas to this address
    /// @param _amountLP quantity of LP tokens to redeem
    /// @param _to address to send the redeemed poolId tokens
    /// @param _lzTxParams adpater parameters
    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    )
        external
        payable;

    /// @notice Part of the Delta-Algorithm implementation. Shares state information with destination chainId.
    /// @param _dstChainId destination chainId
    /// @param _srcPoolId source poolId
    /// @param _dstPoolId destination poolId
    /// @param _refundAddress refund extra native gas to this address
    function sendCredits(uint16 _dstChainId, uint256 _srcPoolId, uint256 _dstPoolId, address payable _refundAddress)
        external
        payable;

    /// @notice gets a fee estimate for the cross chain transaction
    /// @dev can be passed as {value:fee} to swap()
    /// @param _dstChainId layerZero chain id for destination
    /// @param _functionType https://stargateprotocol.gitbook.io/stargate/developers/function-types
    /// @param _toAddress destination of tokens
    /// @param _transferAndCallPayload encoded extra data to send with the swap
    /// @param _lzTxParams extra gas or airdrop params
    /// @return fee tuple in (native, zro)
    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    )
        external
        view
        returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

interface IStargateReceiver {
    /// @notice triggered when executing a stargate swap by any stargate enabled contract
    /// @param _chainId the layerZero chain ID
    /// @param _srcAddress The remote Bridge address
    /// @param _nonce The message ordering nonce
    /// @param _token The token contract on the local chain
    /// @param _amountLD The qty of local _token contract tokens
    /// @dev may be different to tokens sent on the source chain
    /// @param _payload The bytes containing the toAddress
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 _amountLD,
        bytes memory _payload
    )
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload)
        external;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    )
        external
        payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    )
        external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    )
        external
        view
        returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint256 _configType)
        external
        view
        returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}