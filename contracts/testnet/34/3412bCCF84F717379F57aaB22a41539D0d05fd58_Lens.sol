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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IHedgedPool} from "../interfaces/IHedgedPool.sol";
import {IHedger} from "../interfaces/IHedger.sol";
import {ILpManager} from "../interfaces/ILpManager.sol";
import {IAddressBook} from "../interfaces/IAddressBook.sol";
import {IController, IOtoken, GammaTypes, IOracle} from "../interfaces/IGamma.sol";

contract Lens {
    struct PoolInfo {
        uint256 freeCollateral; // collateral available as liquidity in the pool
        uint256 totalCollateral; // free collateral plus any cash allocated for pending withdrawals (should be used for pricePerShare calculation)
        address[] underlyings; // list of underlying assets supported by the pool
        uint256[] hedgeCollateralValue; // total collateral value inside of the hedge for each underlying
        int256[] hedgeRequiredCollateral; // collateral shortfall (positive) or excess (negative) in the hedge for each underlying
        int256[] hedgeDeltas; // hedge delta for each underlying
        string[] optionSymbols; // all options symbols
        int256[] optionBalances; // all options balances: positive (long), negative (short)
        uint256[] optionsCollateral; // collateral locked inside options vaults (0 for longs)
        uint256[] optionsExpiryPrices; // for expired options expiry prices if available
        bool[] optionsExpiryPricesFinalized; // for expired options whether expiry price is finalized (past dispute period)
    }

    /// @notice returns the pool info for a given pool
    /// @dev call this function using callStatic
    /// @param poolAddress the address of the pool
    /// @return poolInfo the pool info
    function getPoolInfo(
        address poolAddress
    ) external returns (PoolInfo memory) {
        IHedgedPool pool = IHedgedPool(poolAddress);
        IAddressBook addressBook = pool.addressBook();
        ILpManager lpManager = ILpManager(addressBook.getLpManager());
        IController controller = IController(addressBook.getController());
        IOracle oracle = IOracle(addressBook.getOracle());

        PoolInfo memory poolInfo;

        uint256 collateralBalance = pool.collateralToken().balanceOf(
            poolAddress
        );

        // exludes pending withdrawals (use this for pool available liquidity)
        poolInfo.freeCollateral =
            collateralBalance -
            lpManager.getCashLocked(poolAddress, true);
        // includes pending withdrawals (use this for total pool value)
        poolInfo.totalCollateral =
            collateralBalance -
            lpManager.getCashLocked(poolAddress, false);

        poolInfo.underlyings = pool.getAllUnderlyings();
        poolInfo.hedgeCollateralValue = new uint256[](
            poolInfo.underlyings.length
        );
        poolInfo.hedgeRequiredCollateral = new int256[](
            poolInfo.underlyings.length
        );
        poolInfo.hedgeDeltas = new int256[](poolInfo.underlyings.length);

        for (uint i = 0; i < poolInfo.underlyings.length; i++) {
            address underlying = poolInfo.underlyings[i];
            address hedger = pool.hedgers(underlying);
            poolInfo.hedgeCollateralValue[i] = IHedger(hedger)
                .getCollateralValue();
            poolInfo.hedgeRequiredCollateral[i] = IHedger(hedger)
                .getRequiredCollateral();
            poolInfo.hedgeDeltas[i] = IHedger(hedger).getDelta();
        }

        address[] memory oTokens = pool.getActiveOTokens();
        poolInfo.optionSymbols = new string[](oTokens.length);
        poolInfo.optionBalances = new int256[](oTokens.length);
        poolInfo.optionsCollateral = new uint256[](oTokens.length);
        poolInfo.optionsExpiryPrices = new uint256[](oTokens.length);
        poolInfo.optionsExpiryPricesFinalized = new bool[](oTokens.length);
        for (uint i = 0; i < oTokens.length; i++) {
            address oToken = oTokens[i];
            poolInfo.optionSymbols[i] = IERC20Metadata(oToken).symbol();

            uint vaultId = pool.marginVaults(oToken);
            // short oToken
            if (vaultId != 0) {
                GammaTypes.Vault memory vault = controller.getVault(
                    poolAddress,
                    vaultId
                );

                poolInfo.optionBalances[i] = -int256(vault.shortAmounts[0]);

                // TODO: for expired options collateral should be equal to payoff
                poolInfo.optionsCollateral[i] = vault.collateralAmounts[0];
            }

            // long oToken
            poolInfo.optionBalances[i] += int256(
                IERC20Metadata(oToken).balanceOf(poolAddress)
            );

            // return expiry price for expired options
            if (IOtoken(oToken).expiryTimestamp() <= block.timestamp) {
                (
                    poolInfo.optionsExpiryPrices[i],
                    poolInfo.optionsExpiryPricesFinalized[i]
                ) = oracle.getExpiryPrice(
                    IOtoken(oToken).underlyingAsset(),
                    IOtoken(oToken).expiryTimestamp()
                );
            }
        }

        return poolInfo;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IAddressBookGamma} from "./IGamma.sol";

interface IAddressBook is IAddressBookGamma {
    event OpynAddressBookUpdated(address indexed newAddress);
    event LpManagerUpdated(address indexed newAddress);
    event OrderUtilUpdated(address indexed newAddress);
    event FeeCollectorUpdated(address indexed newAddress);
    event LensUpdated(address indexed newAddress);
    event PerennialMultiInvokerUpdated(address indexed newAddress);
    event PerennialLensUpdated(address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function setOpynAddressBook(address opynAddressBookAddress) external;

    function setLpManager(address lpManagerlAddress) external;

    function setOrderUtil(address orderUtilAddress) external;

    function getOpynAddressBook() external view returns (address);

    function getLpManager() external view returns (address);

    function getOrderUtil() external view returns (address);

    function getFeeCollector() external view returns (address);

    function getLens() external view returns (address);

    function getPerennialMultiInvoker() external view returns (address);

    function getPerennialLens() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

library GammaTypes {
    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral
        // in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }
}

interface IAddressBookGamma {
    /* Getters */

    function getOtokenImpl() external view returns (address);

    function getOtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);
}

interface IOtoken {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);
}

interface IOtokenFactory {
    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    function createOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address);

    function getTargetOtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    event OtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );
}

interface IController {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets
        // but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    function getPayout(
        address _otoken,
        uint256 _amount
    ) external view returns (uint256);

    function operate(ActionArgs[] calldata _actions) external;

    function getAccountVaultCounter(
        address owner
    ) external view returns (uint256);

    function oracle() external view returns (address);

    function getVault(
        address _owner,
        uint256 _vaultId
    ) external view returns (GammaTypes.Vault memory);

    function getVaultWithDetails(
        address _owner,
        uint256 _vaultId
    ) external view returns (GammaTypes.Vault memory, uint256, uint256);

    function getProceed(
        address _owner,
        uint256 _vaultId
    ) external view returns (uint256);

    function isSettlementAllowed(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _expiry
    ) external view returns (bool);

    function hasExpired(address _otoken) external view returns (bool);
}

interface IMarginCalculator {
    function getNakedMarginRequired(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _shortAmount,
        uint256 _strikePrice,
        uint256 _underlyingPrice,
        uint256 _shortExpiryTimestamp,
        uint256 _collateralDecimals,
        bool _isPut
    ) external view returns (uint256);

    function getExcessCollateral(
        GammaTypes.Vault calldata _vault,
        uint256 _vaultType
    ) external view returns (uint256 netValue, bool isExcess);
}

interface IOracle {
    function isLockingPeriodOver(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (bool);

    function isDisputePeriodOver(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (bool);

    function getExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(
        address _pricer
    ) external view returns (uint256);

    function getPricerDisputePeriod(
        address _pricer
    ) external view returns (uint256);

    function getChainlinkRoundData(
        address _asset,
        uint80 _roundId
    ) external view returns (uint256, uint256);

    // Non-view function

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;
}

interface OpynPricerInterface {
    function getPrice() external view returns (uint256);

    function getHistoricalPrice(
        uint80 _roundId
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOrderUtil.sol";
import {IAddressBook} from "./IAddressBook.sol";

interface IHedgedPool {
    function addressBook() external view returns (IAddressBook);

    function getCollateralBalance() external view returns (uint256);

    function strikeToken() external view returns (IERC20);

    function collateralToken() external view returns (IERC20);

    function getAllUnderlyings() external view returns (address[] memory);

    function getActiveOTokens() external view returns (address[] memory);

    function hedgers(address underlying) external view returns (address);

    function marginVaults(address oToken) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

interface IHedger {
    function hedge(int256 delta) external returns (int256 deltaDiff);

    function sync() external returns (int256 collateralDiff);

    function getDelta() external view returns (int256);

    function getCollateralValue() external returns (uint256);

    function getRequiredCollateral() external returns (int256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

interface ILpManager {
    function depositRoundId(
        address poolAddress
    ) external view returns (uint256);

    function withdrawalRoundId(
        address poolAddress
    ) external view returns (uint256);

    function getCashLocked(
        address poolAddress,
        bool includePendingWithdrawals
    ) external view returns (uint256);

    function getUnfilledShares(
        address poolAddress
    ) external view returns (uint256);

    function getWithdrawalStatus(
        address poolAddress,
        address lpAddress
    )
        external
        view
        returns (
            uint256 sharesRedeemable,
            uint256 sharesOutstanding,
            uint256 cashRedeemable
        );

    function getDepositStatus(
        address poolAddress,
        address lpAddress
    ) external view returns (uint256 cashPending, uint256 sharesRedeemable);

    function closeWithdrawalRound(
        uint256 pricePerShare
    ) external returns (uint256 sharesRemoved);

    function closeDepositRound(
        uint256 pricePerShare
    ) external returns (uint256 sharesAdded);

    function addPendingCash(uint256 cashAmount) external;

    function addPricedCash(uint256 cashAmount, uint256 shareAmount) external;

    function requestWithdrawal(
        address lpAddress,
        uint256 sharesAmount
    ) external;

    function requestDeposit(address lpAddress, uint256 cashAmount) external;

    function redeemShares(address lpAddress) external returns (uint256);

    function withdrawCash(
        address lpAddress
    ) external returns (uint256, uint256);

    function cancelPendingDeposit(address lpAddress, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IOrderUtil {
    struct Order {
        address poolAddress;
        address underlying;
        address referrer;
        uint256 validUntil;
        uint256 nonce;
        OptionLeg[] legs;
        Signature signature;
        Signature[] coSignatures;
    }

    struct OptionLeg {
        uint256 strike;
        uint256 expiration;
        bool isPut;
        int256 amount;
        int256 premium;
        uint256 fee;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event Cancel(uint256 indexed nonce, address indexed signerWallet);

    event CancelUpTo(uint256 indexed nonce, address indexed signerWallet);

    error InvalidAdapters();
    error OrderExpired();
    error NonceTooLow();
    error NonceAlreadyUsed(uint256);
    error SenderInvalid();
    error SignatureInvalid();
    error SignerInvalid();
    error TokenKindUnknown();
    error Unauthorized();

    /**
     * @notice Validates order and returns its signatory
     * @param order Order
     */
    function processOrder(
        Order calldata order
    ) external returns (address signer, address[] memory coSigners);

    /**
     * @notice Cancel one or more open orders by nonce
     * @param nonces uint256[]
     */
    function cancel(uint256[] calldata nonces) external;

    /**
     * @notice Cancels all orders below a nonce value
     * @dev These orders can be made active by reducing the minimum nonce
     * @param minimumNonce uint256
     */
    function cancelUpTo(uint256 minimumNonce) external;

    function nonceUsed(address, uint256) external view returns (bool);

    function getSigners(
        Order calldata order
    ) external returns (address signer, address[] memory coSigners);
}