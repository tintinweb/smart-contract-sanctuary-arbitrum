//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusAltair.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

/*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  
    .         🛰️    .            .               .      🛰️     .           .                .           .
           █████████           ---======*.                                                .           ⠀
          ███░░░░░███                                               📡                🌔      🛰️                   . 
         ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
        ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀           .          
        ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
        ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             .⠀🛰️
         ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████     .----===*  ⠀
          ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                            .⠀
                       ███ ░███  ███ ░███                .                 .                 .  ⠀
     🛰️  .             ░░██████  ░░██████                 🛰️                             .                 .           
                      ░░░░░░    ░░░░░░      -------=========*             🛰️         .                     ⠀
           .                            .🛰️       .          .            .                         🛰️ .             .⠀
    
        CYGNUS PERIPHERY ROUTER - `Altair`                                                           
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  */
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusAltair} from "./interfaces/ICygnusAltair.sol";

// Libraries
import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

// Interfaces
import {IWrappedNative} from "./interfaces/IWrappedNative.sol";
import {ICygnusAltairX} from "./interfaces/ICygnusAltairX.sol";

// Cygnus Core
import {IERC20} from "./interfaces/core/IERC20.sol";
import {IHangar18} from "./interfaces/core/IHangar18.sol";
import {ICygnusBorrow} from "./interfaces/core/ICygnusBorrow.sol";
import {ICygnusTerminal} from "./interfaces/core/ICygnusTerminal.sol";
import {ICygnusCollateral} from "./interfaces/core/ICygnusCollateral.sol";

// Permit2
import {IAllowanceTransfer} from "./interfaces/core/IAllowanceTransfer.sol";
import {ISignatureTransfer} from "./interfaces/core/ISignatureTransfer.sol";

/**
 *  @title  CygnusAltair Periphery contract to interact with Cygnus Core contracts
 *  @author CygnusDAO
 *  @notice The base periphery contract that is used to interact with Cygnus Core contracts. Aside from
 *          depositing and withdrawing from the core contracts, users should always use this router
 *          (or a similar implementation) to interact wtih the core contracts. It is integrated with Uniswap's
 *          Permit2 and allows users to interact with Cygnus Core without ever giving any allowance ot this
 *          router (can borrow, repay, leverage, deleverage and liquidate using the Permit functions).
 *
 *          Leverage   = Borrow USDC from the borrowable and use it to mint more collateral (Liquidity Tokens)
 *          Deleverage = Redeem collateral (Liquidity Tokens) and sell the assets for USDC to repay the loan
 *                       or just to convert all your liquidity to USDC in 1 step.
 *
 *          As such, using a dex aggregator improves capital efficiency during swaps. This router is integrated with
 *          the following aggregators to make sure that slippage is minimal between the borrowed USDC and the
 *          minted LP and when converting LP back to USDC. When using the functions you should pass the ID of each.
 *            - Paraswap                       (0)
 *            - OneInchV5 Legacy Swap          (1)
 *            - OneInchV5 Optimized Swap       (2)
 *            - 0xProject Swap API             (3)
 *            - OpenOcean Legacy Swap          (4)
 *            - OpenOcean Optimized Swap       (5)
 *            - OKX Aggregation Router         (6)
 *            - UniswapV3 (*)                  (7)
 *
 *          (*) In the unlikely case where ALL aggregators start failing at the same time (APIs are down, etc.),
 *          users can perform EMERGENCY deleverage or liquidations with UniswapV3's router. The end result would
 *          likely be suffering higher slippage and liquidators receiving less liquidation profit, but this way users
 *          are always guaranteed to be able to adjust their positions.
 *
 *          During the leverage functionality the router borrows USD from the borrowable arm contract, and
 *          then converts it to LP Tokens. Since each liquidity token requires different logic to "mint".,
 *          for example, minting an LP from UniswapV2 is different to minting a BPT from Balancer or UniswapV3,
 *          the router delegates the call to an extension contract to mint the liquidity token.
 *
 *          During the deleverage functionality the router receives Liquidity Tokens from the collateral arm
 *          contract, and then converts it to USDC. Again, since the process of burning or redeeming the liquidity
 *          token requires different logic across DEXes, this contract delegates the redeem call to the extensions
 *          in the fallback.
 *
 *          The admin is in charge of setting up the extension contracts and these are updatable, however this is
 *          the only contract that users should interact with.
 *
 *          Functions in this contract allow for:
 *            - Borrowing USD
 *            - Repaying USD
 *            - Liquidating user's with USD (pay back USD, receive CygLP + bonus liquidation reward)
 *            - Flash liquidating a user by selling collateral to the market and receive USD
 *            - Leveraging USD into Liquidity
 *            - Deleveraging Liquidity into USD
 */
contract CygnusAltair is ICygnusAltair {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
          1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library SafeTransferLib For safe transfers of Erc20 tokens
     */
    using SafeTransferLib for address;

    /**
     *  @custom:library FixedPointMathLib Arithmetic library with operations for fixed-point numbers
     */
    using FixedPointMathLib for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
          2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Empty bytes to pass to contracts if needed
     */
    bytes internal constant LOCAL_BYTES = new bytes(0);

    /**
     *  @notice Internal record of all Altair Extensions - Borrowable/Collateral address to extension contract implementation.
     */
    mapping(address => address) internal altairExtensions;

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Internal mapping to check if extension has been added
     */
    mapping(address => bool) public override isExtension;

    /**
     *  @inheritdoc ICygnusAltair
     */
    address[] public override allExtensions;

    /**
     *  @inheritdoc ICygnusAltair
     */
    string public constant override name = "Cygnus: Altair Router";

    /**
     *  @inheritdoc ICygnusAltair
     */
    string public constant override version = "1.0.0";

    /**
     *  @inheritdoc ICygnusAltair
     */
    address public constant override PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    // Aggregator addresses are not used in this contract, kept here for consistency with extensions

    /**
     *  @inheritdoc ICygnusAltair
     */
    address public constant override PARASWAP_AUGUSTUS_SWAPPER_V5 = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    /**
     *  @inheritdoc ICygnusAltair
     */
    address public constant override ONE_INCH_ROUTER_V5 = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    /**
     *  @inheritdoc ICygnusAltair
     */
    address public constant override OxPROJECT_EXCHANGE_PROXY = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

    /**
     *  @inheritdoc ICygnusAltair
     */
    address public constant override OPEN_OCEAN_EXCHANGE_PROXY = 0x6352a56caadC4F1E25CD6c75970Fa768A3304e64;

    /**
     *  @inheritdoc ICygnusAltair
     */
    address public constant override OKX_AGGREGATION_ROUTER = 0xf332761c673b59B21fF6dfa8adA44d78c12dEF09;

    /**
     *  @inheritdoc ICygnusAltair
     */
    address public constant override UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    /**
     *  @inheritdoc ICygnusAltair
     */
    IHangar18 public immutable override hangar18;

    /**
     *  @inheritdoc ICygnusAltair
     */
    address public immutable override usd;

    /**
     *  @inheritdoc ICygnusAltair
     */
    IWrappedNative public immutable override nativeToken;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
          3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs the periphery contract. Factory must be deployed on the chain first to get the addresses
     *          of deployers and the wrapped native token (WETH, WFTM, etc.)
     *  @param _hangar18 The address of the Cygnus Factory contract on this chain
     */
    constructor(IHangar18 _hangar18) {
        // Factory
        hangar18 = _hangar18;

        // Assign the native token set at the factory
        nativeToken = IWrappedNative(_hangar18.nativeToken());

        // Assign the USD address set at the factoryn
        usd = _hangar18.usd();
    }

    /**
     *  @dev Fallback function is executed if none of the other functions match the function
     *  identifier or no data was provided with the function call.
     */
    fallback() external payable {
        // Get extension for the caller contract (borrowable or collateral)
        address altairX = altairExtensions[msg.sender];

        /// @custom:error ExtensionDoesntExist Avoid if the extension does not exist
        if (altairX == address(0)) revert CygnusAltair__AltairXDoesNotExist();

        // Delegate the call to the extension router
        (bool success, bytes memory data) = altairX.delegatecall(msg.data);

        // Revert with extension reason
        if (!success) _extensionRevert(data);

        // Return the return value from leverage/deleverage/flash liquidate
        _extensionReturn(data);
    }

    /**
     *  @dev This function is called for plain Ether transfers, i.e. for every call with empty calldata.
     */
    receive() external payable {}

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
          4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:modifier checkDeadline Reverts the transaction if the block.timestamp is after deadline
     */
    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
          5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Reverts with reason if the delegate call fails
     */
    function _extensionRevert(bytes memory data) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            revert(add(data, 32), mload(data))
        }
    }

    /**
     *  @notice Returns the returned data from the delegate call
     */
    function _extensionReturn(bytes memory data) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            return(add(data, 32), mload(data))
        }
    }

    /**
     *  @notice The current block timestamp
     */
    function _checkTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     *  @notice Reverts the transaction if the block.timestamp is after deadline
     *  @param deadline The time by which the transaction must be included to effect the change
     */
    function _checkDeadline(uint256 deadline) internal view {
        /// @custom:error TransactionExpired Avoid transacting past deadline
        if (_checkTimestamp() > deadline) revert CygnusAltair__TransactionExpired();
    }

    /**
     *  @notice Convert shares to assets
     *  @param collateral Address of the CygLP
     *  @param shares Amount of CygLP redeemed
     */
    function _convertToAssets(address collateral, uint256 shares) internal view returns (uint256) {
        // CygLP Supply
        uint256 _totalSupply = ICygnusCollateral(collateral).totalSupply();

        // LP assets in collateral
        uint256 _totalAssets = ICygnusCollateral(collateral).totalAssets();

        // Return the amount of LPs we get by redeeming shares, rounds down
        return shares.fullMulDiv(_totalAssets, _totalSupply);
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusAltair
     */
    function getAltairExtension(address poolToken) external view override returns (address) {
        // Return the router extension
        return altairExtensions[poolToken];
    }

    /**
     *  @inheritdoc ICygnusAltair
     */
    function altairExtensionsLength() external view override returns (uint256) {
        // How many extensions we have added to the base router
        return allExtensions.length;
    }

    /**
     *  @inheritdoc ICygnusAltair
     */
    function getShuttleExtension(uint256 shuttleId) external view override returns (address) {
        // Get the collateral or borrowable (borrowable, collateral and lp share the extension anyways)
        (, , , address collateral, ) = hangar18.allShuttles(shuttleId);

        // Return extension
        return altairExtensions[collateral];
    }

    /**
     *  @dev Same calculation as all vault tokens, asset = shares * balance / supply
     *  @dev Relies on the extension to perform the logic
     *  @inheritdoc ICygnusAltair
     */
    function getAssetsForShares(
        address lpTokenPair,
        uint256 shares,
        uint256 difference
    ) external view returns (address[] memory tokens, uint256[] memory amounts) {
        // Get the extension for this lp token pair
        address altairX = altairExtensions[lpTokenPair];

        /// @custom:error ExtensionDoesntExist Avoid if the extension does not exist
        if (altairX == address(0)) revert CygnusAltair__AltairXDoesNotExist();

        // The extension should implement the assets for shares function - ie. Which assets and how much we receive
        // by redeeming `shares` amount of a liquidity token
        return ICygnusAltairX(altairX).getAssetsForShares(lpTokenPair, shares, difference);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
          6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Calls permit function on pool token
     *  @param terminal The address of the collateral or borrowable
     *  @param amount The permit amount
     *  @param deadline Permit deadline
     *  @param permitData Permit data to decode
     */
    function _checkPermit(address terminal, uint256 amount, uint256 deadline, bytes memory permitData) internal {
        // Return if no permit data
        if (permitData.length == 0) return;

        // Decode permit data
        (uint256 _amount, uint8 v, bytes32 r, bytes32 s) = abi.decode(permitData, (uint256, uint8, bytes32, bytes32));

        // Shh
        amount;

        // Call permit on terminal token
        ICygnusTerminal(terminal).permit(msg.sender, address(this), _amount, deadline, v, r, s);
    }

    /**
     *  @notice Safe internal function to repay borrowed amount
     *  @param borrowable The address of the Cygnus borrow arm where the borrowed amount was taken from
     *  @param amountMax The max amount that can be repaid
     *  @param borrower The address of the account that is repaying the borrowed amount
     */
    function _maxRepayAmount(address borrowable, uint256 amountMax, address borrower) internal view returns (uint256 amount) {
        // Get latest borrow balance of borrower
        (, uint256 borrowedAmount) = ICygnusBorrow(borrowable).getBorrowBalance(borrower);

        // Avoid repaying more than borrowedAmount
        amount = amountMax < borrowedAmount ? amountMax : borrowedAmount;
    }

    /**
     *  @notice Avoid repeating ourselves to make leverage data and stack-too-deep errors
     *  @param lpTokenPair The address of the LP Token
     *  @param collateral The address of the collateral of the lending pool
     *  @param borrowable The address of the borrowable of the lending pool
     *  @param lpAmountMin The minimum amount of LP Tokens to receive
     *  @param dexAggregator The dex aggregator to use for the swaps
     *  @param swapdata the aggregator swap data to convert USD to liquidity
     */
    function _createLeverageData(
        address lpTokenPair,
        address collateral,
        address borrowable,
        uint256 lpAmountMin,
        DexAggregator dexAggregator,
        bytes[] calldata swapdata
    ) internal view returns (bytes memory) {
        // Return encoded bytes to pass to borrowbale
        return
            abi.encode(
                AltairLeverageCalldata({
                    lpTokenPair: lpTokenPair,
                    collateral: collateral,
                    borrowable: borrowable,
                    recipient: msg.sender,
                    lpAmountMin: lpAmountMin,
                    dexAggregator: dexAggregator,
                    swapdata: swapdata
                })
            );
    }

    /**
     *  @notice Avoid repeating ourselves to make deleverage data and stack-too-deep errors
     *  @param lpTokenPair The address of the LP Token
     *  @param collateral The address of the collateral of the lending pool
     *  @param borrowable The address of the borrowable of the lending pool
     *  @param cygLPAmount The amount of CygLP we are deleveraging
     *  @param usdAmountMin The minimum amount of USD to receive from the deleverage
     *  @param dexAggregator The dex aggregator to use for the swaps
     *  @param swapdata the aggregator swap data to convert USD to liquidity
     */
    function _createDeleverageData(
        address lpTokenPair,
        address collateral,
        address borrowable,
        uint256 cygLPAmount,
        uint256 usdAmountMin,
        DexAggregator dexAggregator,
        bytes[] calldata swapdata
    ) internal view returns (bytes memory) {
        // Encode redeem data
        return
            abi.encode(
                AltairDeleverageCalldata({
                    lpTokenPair: lpTokenPair,
                    collateral: collateral,
                    borrowable: borrowable,
                    recipient: msg.sender,
                    redeemTokens: cygLPAmount,
                    usdAmountMin: usdAmountMin,
                    dexAggregator: dexAggregator,
                    swapdata: swapdata
                })
            );
    }

    /**
     *  @notice Flash liquidate data to pass to the borrowable contract
     *  @param lpTokenPair The address of the LP Token
     *  @param collateral The address of the collateral of the lending pool
     *  @param borrowable The address of the borrowable of the lending pool
     *  @param borrower The address of the borrower to liquidate
     *  @param amount The amount of USDC being repaid
     *  @param dexAggregator The dex aggregator to use for the swaps
     *  @param swapdata the aggregator swap data to convert USD to liquidity
     */
    function _createFlashLiquidateData(
        address lpTokenPair,
        address collateral,
        address borrowable,
        address borrower,
        uint256 amount,
        DexAggregator dexAggregator,
        bytes[] calldata swapdata
    ) internal view returns (bytes memory) {
        // Encode data to bytes
        return
            abi.encode(
                AltairLiquidateCalldata({
                    lpTokenPair: lpTokenPair,
                    collateral: collateral,
                    borrowable: borrowable,
                    borrower: borrower,
                    recipient: msg.sender,
                    repayAmount: amount,
                    dexAggregator: dexAggregator,
                    swapdata: swapdata
                })
            );
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    // Start periphery functions:
    //   1. Borrow - Users can borrow passing a standard permit to approve borrow allowance + borrow in 1 tx
    //   2. Repay - (standard permit + permit2 allowance + permit2 signature)
    //   3. Liquidate - (standard permit + permit2 allowance + permit2 signature)
    //   4. Flash Liquidate - There's no need to approve anything as we are just selling collateral to the market
    //   5. Leverage - Users can leverage passing a standard permit to approve borrow allowance + leverage in 1 tx
    //   6. Deleverage - Users can deleverage passing a standard permit to approve CygLP allowance + deleverage in 1 tx

    //  1. BORROW ────────────────────────────────────

    /**
     *  @notice Borrows USDC and sends it to `recipient`
     *  @inheritdoc ICygnusAltair
     */
    function borrow(
        address borrowable,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata permitData
    ) external virtual override checkDeadline(deadline) {
        // Check permit on borrowable (borrow allowance)
        _checkPermit(borrowable, amount, deadline, permitData);

        // Borrow amount
        ICygnusBorrow(borrowable).borrow(msg.sender, recipient, amount, LOCAL_BYTES);
    }

    //  2. REPAY ─────────────────────────────────────

    /**
     *  @notice Transfers USDC from sender to the borrowable and repays the debt for `borrower`
     *  @inheritdoc ICygnusAltair
     */
    function repay(
        address borrowable,
        uint256 amountMax,
        address borrower,
        uint256 deadline,
        bytes calldata permitData
    ) external virtual override checkDeadline(deadline) returns (uint256 amount) {
        // Ensure that the amount being repaid never more than currently owed.
        amount = _maxRepayAmount(borrowable, amountMax, borrower);

        // Check permit on USDC
        _checkPermit(usd, amount, deadline, permitData);

        // Transfer USD from msg sender to borrow contract
        usd.safeTransferFrom(msg.sender, borrowable, amount);

        // Call borrow to update borrower's borrow balance
        ICygnusBorrow(borrowable).borrow(borrower, address(0), 0, LOCAL_BYTES);
    }

    /**
     *  @inheritdoc ICygnusAltair
     */
    function repayPermit2Allowance(
        address borrowable,
        uint256 amountMax,
        address borrower,
        uint256 deadline,
        IAllowanceTransfer.PermitSingle calldata _permit,
        bytes calldata signature
    ) external virtual override checkDeadline(deadline) returns (uint256 amount) {
        // Ensure that the amount being repaid never more than currently owed.
        amount = _maxRepayAmount(borrowable, amountMax, borrower);

        // Check for permit (else users can just approve permit2 and skip this by passing an empty
        // PermitSingle and an empty `_signature`)
        if (signature.length > 0) {
            // Set allowance using permit
            IAllowanceTransfer(PERMIT2).permit(
                // The owner of the tokens being approved.
                // We only allow the owner of the tokens to be the repayer
                msg.sender,
                // Data signed over by the owner specifying the terms of approval
                _permit,
                // The owner's signature over the permit data that was the result
                // of signing the EIP712 hash of `_permit`
                signature
            );
        }

        // Transfer underlying to vault
        IAllowanceTransfer(PERMIT2).transferFrom(msg.sender, borrowable, uint160(amount), usd);

        // Call borrow with 0 borrowAmount to update borrower's borrow balance and repay loan
        ICygnusBorrow(borrowable).borrow(borrower, address(0), 0, LOCAL_BYTES);
    }

    /**
     *  @inheritdoc ICygnusAltair
     */
    function repayPermit2Signature(
        address borrowable,
        uint256 amountMax,
        address borrower,
        uint256 deadline,
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata signature
    ) external virtual override checkDeadline(deadline) returns (uint256 amount) {
        // Ensure that the amount being repaid never more than currently owed.
        amount = _maxRepayAmount(borrowable, amountMax, borrower);

        // Signture transfer
        ISignatureTransfer(PERMIT2).permitTransferFrom(
            // The permit message.
            _permit,
            // The transfer recipient and amount.
            ISignatureTransfer.SignatureTransferDetails({to: borrowable, requestedAmount: amount}),
            // Owner of the tokens and signer of the message.
            msg.sender,
            // The packed signature that was the result of signing
            // the EIP712 hash of `_permit`.
            signature
        );

        // Call borrow with 0 borrowAmount to update borrower's borrow balance and repay loan
        ICygnusBorrow(borrowable).borrow(borrower, address(0), 0, LOCAL_BYTES);
    }

    //  3. LIQUIDATE ─────────────────────────────────

    /**
     *  @notice Transfers USDC from sender to the borrowable, liquidating `borrower` and receiving the equivalent
     *          of the repaid amount + the liquidation incentinve in CygLP.
     *  @inheritdoc ICygnusAltair
     */
    function liquidate(
        address borrowable,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline,
        bytes calldata permitData
    ) external virtual override checkDeadline(deadline) returns (uint256 amount, uint256 seizeTokens) {
        // Ensure that the amount being repaid never more than currently owed.
        amount = _maxRepayAmount(borrowable, amountMax, borrower);

        // Check permit
        _checkPermit(usd, amount, deadline, permitData);

        // Transfer USD
        usd.safeTransferFrom(msg.sender, borrowable, amount);

        // Liquidate
        seizeTokens = ICygnusBorrow(borrowable).liquidate(borrower, recipient, amount, LOCAL_BYTES);
    }

    /**
     *  @inheritdoc ICygnusAltair
     */
    function liquidatePermit2Allowance(
        address borrowable,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline,
        IAllowanceTransfer.PermitSingle calldata _permit,
        bytes calldata signature
    ) external virtual override checkDeadline(deadline) returns (uint256 amount, uint256 seizeTokens) {
        // Ensure that the amount being repaid never more than currently owed.
        amount = _maxRepayAmount(borrowable, amountMax, borrower);

        // Check for permit (else users can just approve permit2 and skip this by passing an empty
        // PermitSingle and an empty `_signature`)
        if (signature.length > 0) {
            // Set allowance using permit
            IAllowanceTransfer(PERMIT2).permit(
                // The owner of the tokens being approved.
                // We only allow the owner of the tokens to be the liquidator
                msg.sender,
                // Data signed over by the owner specifying the terms of approval
                _permit,
                // The owner's signature over the permit data that was the result
                // of signing the EIP712 hash of `_permit`
                signature
            );
        }

        // Transfer underlying to vault
        IAllowanceTransfer(PERMIT2).transferFrom(msg.sender, borrowable, uint160(amount), usd);

        // Liquidate
        seizeTokens = ICygnusBorrow(borrowable).liquidate(borrower, recipient, amount, LOCAL_BYTES);
    }

    /**
     *  @inheritdoc ICygnusAltair
     */
    function liquidatePermit2Signature(
        address borrowable,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline,
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata signature
    ) external virtual override checkDeadline(deadline) returns (uint256 amount, uint256 seizeTokens) {
        // Ensure that the amount being repaid never more than currently owed.
        amount = _maxRepayAmount(borrowable, amountMax, borrower);

        // Signture transfer
        ISignatureTransfer(PERMIT2).permitTransferFrom(
            // The permit message.
            _permit,
            // The transfer recipient and amount.
            ISignatureTransfer.SignatureTransferDetails({to: borrowable, requestedAmount: amount}),
            // Owner of the tokens and signer of the message.
            msg.sender,
            // The packed signature that was the result of signing
            // the EIP712 hash of `_permit`.
            signature
        );

        // Liquidate
        seizeTokens = ICygnusBorrow(borrowable).liquidate(borrower, recipient, amount, LOCAL_BYTES);
    }

    //  4. FLASH LIQUIDATE ───────────────────────────

    /**
     *  @notice Sells the LP collateral to the market, repays debt and sends liquidator the liq. incentive in USDC
     *  @inheritdoc ICygnusAltair
     */
    function flashLiquidate(
        address borrowable,
        address collateral,
        uint256 amountMax,
        address borrower,
        uint256 deadline,
        DexAggregator dexAggregator,
        bytes[] calldata swapdata
    ) external virtual override checkDeadline(deadline) returns (uint256 amount) {
        // Ensure that the amount being repaid never more than currently owed.
        amount = _maxRepayAmount(borrowable, amountMax, borrower);

        // Get LP TokenPair
        address lpTokenPair = ICygnusCollateral(collateral).underlying();

        // Encode data to bytes
        bytes memory liquidateData = _createFlashLiquidateData(
            lpTokenPair,
            collateral,
            borrowable,
            borrower,
            amount,
            dexAggregator,
            swapdata
        );

        // Liquidate
        // The liquidated CYGLP is transfered to the collateral to then call `flashRedeem` and receive LP
        ICygnusBorrow(borrowable).liquidate(borrower, collateral, amount, liquidateData);
    }

    //  5. LEVERAGE ──────────────────────────────────

    /**
     *  @notice Converts all USDC to LP's assets and mints LP token
     *  @inheritdoc ICygnusAltair
     */
    function leverage(
        address lpTokenPair,
        address collateral,
        address borrowable,
        uint256 usdAmount,
        uint256 lpAmountMin,
        uint256 deadline,
        bytes calldata permitData,
        DexAggregator dexAggregator,
        bytes[] calldata swapdata
    ) external virtual override checkDeadline(deadline) returns (uint256 liquidity) {
        // Check permit on borrowable (borrow allowance)
        _checkPermit(borrowable, usdAmount, deadline, permitData);

        // Encode data to bytes
        bytes memory borrowData = _createLeverageData(lpTokenPair, collateral, borrowable, lpAmountMin, dexAggregator, swapdata);

        // Call borrow with encoded data
        liquidity = ICygnusBorrow(borrowable).borrow(msg.sender, address(this), usdAmount, borrowData);
    }

    //  6. DELEVERAGE ────────────────────────────────

    /**
     *  @notice Burns the LP token and converts all LP's assets to USDC
     *  @inheritdoc ICygnusAltair
     */
    function deleverage(
        address lpTokenPair,
        address collateral,
        address borrowable,
        uint256 cygLPAmount,
        uint256 usdAmountMin,
        uint256 deadline,
        bytes calldata permitData,
        DexAggregator dexAggregator,
        bytes[] calldata swapdata
    ) external virtual override checkDeadline(deadline) returns (uint256 usdAmount) {
        // Check permit on collateral (transfer allowance)
        _checkPermit(collateral, cygLPAmount, deadline, permitData);

        // Get redeem amount, rounding down
        uint256 redeemAmount = _convertToAssets(collateral, cygLPAmount);

        // Encode data to bytes
        bytes memory redeemData = _createDeleverageData(
            lpTokenPair,
            collateral,
            borrowable,
            cygLPAmount,
            usdAmountMin,
            dexAggregator,
            swapdata
        );

        // Flash redeem LP Tokens
        usdAmount = ICygnusCollateral(collateral).flashRedeemAltair(address(this), redeemAmount, redeemData);
    }

    // ADMIN

    /**
     *  @notice Initializes the mapping of borrowable/collateral/lp token => extension
     *  @inheritdoc ICygnusAltair
     *  @custom:security only-admin
     */
    function setAltairExtension(uint256[] calldata shuttleIds, address extension) external override {
        // Get latest admin
        address admin = hangar18.admin();

        /// @custom:error MsgSenderNotAdmin
        if (msg.sender != admin) revert CygnusAltair__MsgSenderNotAdmin();

        // Total lending pools
        uint256 length = shuttleIds.length;

        // Set extension for shuttleId[i]
        for (uint256 i = 0; i < length; i++) {
            // Get the shuttle for the shuttle ID
            (bool launched, , address borrowable, address collateral, ) = hangar18.allShuttles(shuttleIds[i]);

            /// @custom:error ShuttleDoesNotExist
            if (!launched) revert CygnusAltair__ShuttleDoesNotExist();

            // Add to array - Allow admin to update extension for the lending pool
            if (!isExtension[extension]) {
                // Add to array
                allExtensions.push(extension);

                // Mark as true
                isExtension[extension] = true;
            }

            // For leveraging USD
            altairExtensions[borrowable] = extension;

            // For deleveraging the LP
            altairExtensions[collateral] = extension;

            // For getting the assets for a a given amount of shares:
            //
            // asset received = shares_burnt * asset_balance / vault_token_supply
            //
            // Calling `getAssetsForShares(underlying, amount)` returns two arrays: `tokens` and `amounts`. The
            // extensions handle this logic since it differs per underlying Liquidity Token. For example, returning
            // assets by burning 1 LP in UniV2, or 1 BPT in a Balancer Weighted Pool, etc. Helpful when deleveraging
            // liquidity tokens into USDC.
            address lpTokenAddress = ICygnusCollateral(collateral).underlying();

            // Store LP => Extension
            altairExtensions[lpTokenAddress] = extension;

            /// @custom:event NewExtension
            emit NewExtension(shuttleIds[i], borrowable, collateral, lpTokenAddress, extension);
        }
    }

    /**
     *  @inheritdoc ICygnusAltair
     *  @custom:security only-admin
     */
    function sweepTokens(IERC20[] memory tokens, address to) external override {
        // Get latest admin
        address admin = hangar18.admin();

        /// @custom:error MsgSenderNotAdmin
        if (msg.sender != admin) revert CygnusAltair__MsgSenderNotAdmin();

        // Transfer each token to admin
        for (uint256 i = 0; i < tokens.length; i++) {
            // Balance of token
            uint256 balance = tokens[i].balanceOf(address(this));

            // Send to admin
            if (balance > 0) address(tokens[i]).safeTransfer(to, balance);
        }
    }

    /**
     *  @inheritdoc ICygnusAltair
     *  @custom:security only-admin
     */
    function sweepNative() external override {
        // Get latest admin
        address admin = hangar18.admin();

        /// @custom:error MsgSenderNotAdmin
        if (msg.sender != admin) revert CygnusAltair__MsgSenderNotAdmin();

        // Get native balance
        uint256 balance = address(this).balance;

        // Get ETH out
        if (balance > 0) SafeTransferLib.safeTransferETH(admin, balance);
    }

    //  POSITIONS ────────────────────────────────────

    //  These functions are not used by the router and are kept here for reporting purposes only

    /**
     *  @notice Accrues interest and syncs balance
     *  @inheritdoc ICygnusAltair
     */
    function latestBorrowerPosition(
        ICygnusBorrow borrowable,
        address borrower
    )
        external
        returns (
            uint256 cygLPBalance,
            uint256 principal,
            uint256 borrowBalance,
            uint256 price,
            uint256 rate,
            uint256 lpBalance,
            uint256 positionUsd,
            uint256 health
        )
    {
        // Accrue interest and update balance
        borrowable.sync();

        // Get collateral contract
        ICygnusCollateral collateral = ICygnusCollateral(borrowable.collateral());

        // CygLP Balance of borrower
        cygLPBalance = collateral.balanceOf(borrower);

        // Principal (borrowed amount) + borrow balance (borrowed amount + interest)
        (principal, borrowBalance) = borrowable.getBorrowBalance(borrower);

        // Get price of LP
        price = collateral.getLPTokenPrice();

        // Exchange rate between 1 CygLP and LP
        rate = collateral.exchangeRate();

        // The balance of the borrower
        (lpBalance, positionUsd, health) = collateral.getBorrowerPosition(borrower);
    }

    /**
     *  @notice Accrues interest and syncs balance
     *  @inheritdoc ICygnusAltair
     */
    function latestLenderPosition(
        ICygnusBorrow borrowable,
        address lender
    ) external override returns (uint256 cygUsdBalance, uint256 rate, uint256 usdBalance, uint256 positionUsd) {
        // Accrue interest and update balance
        borrowable.sync();

        // CygUSd balance of lender
        cygUsdBalance = borrowable.balanceOf(lender);

        // Exchange rate between 1 CygUSD and USD
        rate = borrowable.exchangeRate();

        (usdBalance, positionUsd) = borrowable.getLenderPosition(lender);
    }

    /**
     *  @notice Accrues interest and syncs balance
     *  @inheritdoc ICygnusAltair
     */
    function latestAccountLiquidity(
        ICygnusBorrow borrowable,
        address borrower
    ) external override returns (uint256 liquidity, uint256 shortfall) {
        // Accrue interest and update balance
        borrowable.sync();

        // Get collateral contract
        address collateral = borrowable.collateral();

        // Liquidity info
        (liquidity, shortfall) = ICygnusCollateral(collateral).getAccountLiquidity(borrower);
    }

    /**
     *  @notice Accrues interest and syncs balance
     *  @inheritdoc ICygnusAltair
     */
    function latestShuttleInfo(
        ICygnusBorrow borrowable
    )
        external
        override
        returns (uint256 supplyApr, uint256 borrowApr, uint256 util, uint256 totalBorrows, uint256 totalBalance, uint256 exchangeRate)
    {
        // Accrue interest and update balance
        borrowable.sync();

        // For APRs
        uint256 secondsPerYear = 24 * 60 * 60 * 365;

        // The APR for lenders
        supplyApr = borrowable.supplyRate() * secondsPerYear;

        // The interest rate for borrowers
        borrowApr = borrowable.borrowRate() * secondsPerYear;

        // Utilization rate
        util = borrowable.utilizationRate();

        // Total borrows stored in the contract
        totalBorrows = borrowable.totalBorrows();

        // Available cash
        totalBalance = borrowable.totalBalance();

        // The latest exchange rate
        exchangeRate = borrowable.exchangeRate();
    }

    /**
     *  @notice Get all positions for borrower in Cygnus protocol
     *  @notice Accrues interest and syncs balance
     *  @inheritdoc ICygnusAltair
     */
    function latestBorrowerAll(address borrower) external override returns (uint256 principal, uint256 borrowBalance, uint256 positionUsd) {
        // Total lending pools in Cygnus
        uint256 totalShuttles = hangar18.shuttlesDeployed();

        // Loop through each pool and update borrower's position
        for (uint256 i = 0; i < totalShuttles; i++) {
            // Get borrowale and collateral for shuttle `i`
            (, , address borrowable, address collateral, ) = hangar18.allShuttles(i);

            // Accrue interest in borrowable
            ICygnusBorrow(borrowable).sync();

            // Get collateral position
            (uint256 _principal, uint256 _borrowBalance) = ICygnusBorrow(borrowable).getBorrowBalance(borrower);

            // The balance of the borrower
            (, uint256 _positionUsd, ) = ICygnusCollateral(collateral).getBorrowerPosition(borrower);

            // Increase total principal
            principal += _principal;

            // Increase total borrowed balance
            borrowBalance += _borrowBalance;

            // Increase the borrower`s position in USD
            positionUsd += _positionUsd;
        }
    }

    /**
     *  @notice Get all positions for lender in Cygnus protocol
     *  @notice Accrues interest and syncs balance
     *  @inheritdoc ICygnusAltair
     */
    function latestLenderAll(address lender) external override returns (uint256 cygUsdBalance, uint256 usdBalance, uint256 positionUsd) {
        // Total lending pools in Cygnus
        uint256 totalShuttles = hangar18.shuttlesDeployed();

        // Loop through each pool and update lender's position
        for (uint256 i = 0; i < totalShuttles; i++) {
            // Get borrowable contract for shuttle `i`
            (, , address borrowable, , ) = hangar18.allShuttles(i);

            // Accrue interest
            ICygnusBorrow(borrowable).sync();

            // Get lender position
            (uint256 _usdBalance, uint256 _positionUsd) = ICygnusBorrow(borrowable).getLenderPosition(lender);

            // Increase shares balance
            cygUsdBalance += borrowable.balanceOf(lender);

            // Increase stablecoin balance
            usdBalance += _usdBalance;

            // Increase position denominated in USD using stablecoin's price
            positionUsd += _positionUsd;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  IAlbireoOrbiter.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

/**
 *  @title ICygnusAlbireo The interface the Cygnus borrow deployer
 *  @notice A contract that constructs a Cygnus borrow pool must implement this to pass arguments to the pool
 */
interface IAlbireoOrbiter {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Passing the struct parameters to the borrow contracts avoids setting constructor parameters
     *
     *  @return factory The address of the Cygnus factory assigned to `Hangar18`
     *  @return underlying The address of the underlying borrow token (address of USDC)
     *  @return collateral The address of the Cygnus collateral contract for this borrow contract
     *  @return oracle The address of the oracle for this lending pool
     *  @return shuttleId The lending pool ID
     */
    function shuttleParameters()
        external
        returns (address factory, address underlying, address collateral, address oracle, uint256 shuttleId);

    /**
     *  @return borrowableInitCodeHash The init code hash of the borrow contract for this deployer
     */
    function borrowableInitCodeHash() external view returns (bytes32);

    /**
     *  @notice Function to deploy the borrow contract of a lending pool
     *
     *  @param underlying The address of the underlying borrow token (address of USDc)
     *  @param collateral The address of the Cygnus collateral contract for this borrow contract
     *  @param shuttleId The ID of the shuttle we are deploying (shared by borrow and collateral)
     *  @return borrowable The address of the new borrow contract
     */
    function deployAlbireo(address underlying, address collateral, address oracle, uint256 shuttleId) external returns (address borrowable);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce);

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration);

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration, uint48 nonce);

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address, address, address) external view returns (uint160, uint48, uint48);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusBorrow.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusBorrowVoid} from "./ICygnusBorrowVoid.sol";

// Overrides
import {ICygnusTerminal} from "./ICygnusTerminal.sol";

/**
 *  @title ICygnusBorrow Interface for the main Borrow contract which handles borrows/liquidations
 *  @notice Main interface to borrow against collateral or liquidate positions
 */
interface ICygnusBorrow is ICygnusBorrowVoid {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts if the borrower has insufficient liquidity for this borrow
     *
     *  @custom:error InsufficientLiquidity
     */
    error CygnusBorrow__InsufficientLiquidity();

    /**
     *  @dev Reverts if usd received is less than repaid after liquidating
     *
     *  @custom:error InsufficientUsdReceived
     */
    error CygnusBorrow__InsufficientUsdReceived();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when a borrower takes out a loan
     *
     *  @param sender Indexed address of msg.sender (should be `Altair` address)
     *  @param borrower Indexed address of the borrower
     *  @param receiver Indexed address of receiver
     *  @param borrowAmount The amount of USD borrowed
     *  @param repayAmount The amount of USD repaid
     *
     *  @custom:event Borrow
     */
    event Borrow(address indexed sender, address indexed borrower, address indexed receiver, uint256 borrowAmount, uint256 repayAmount);

    /**
     *  @dev Logs when a liquidator repays and seizes collateral
     *
     *  @param sender Indexed address of msg.sender (should be `Altair` address)
     *  @param borrower Indexed address of the borrower
     *  @param receiver Indexed address of receiver
     *  @param repayAmount The amount of USD repaid
     *  @param cygLPAmount The amount of CygLP seized
     *  @param usdAmount The total amount of underlying deposited
     *
     *  @custom:event Liquidate
     */
    event Liquidate(
        address indexed sender,
        address indexed borrower,
        address indexed receiver,
        uint256 repayAmount,
        uint256 cygLPAmount,
        uint256 usdAmount
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice This low level function should only be called from `CygnusAltair` contract only
     *
     *  @param borrower The address of the Borrow contract.
     *  @param receiver The address of the receiver of the borrow amount.
     *  @param borrowAmount The amount of the underlying asset to borrow.
     *  @param data Calltype data passed to Router contract.
     *
     *  @custom:security non-reentrant
     */
    function borrow(address borrower, address receiver, uint256 borrowAmount, bytes calldata data) external returns (uint256);

    /**
     *  @notice This low level function should only be called from `CygnusAltair` contract only
     *
     *  @param borrower The address of the borrower being liquidated
     *  @param receiver The address of the receiver of the collateral
     *  @param repayAmount USD amount covering the loan
     *  @param data Calltype data passed to Router contract.
     *  @return usdAmount The amount of USD deposited after taking into account liq. incentive
     *
     *  @custom:security non-reentrant
     */
    function liquidate(address borrower, address receiver, uint256 repayAmount, bytes calldata data) external returns (uint256 usdAmount);

    /**
     *  @notice Manually sync the balance held of the underlying
     *  @custom:security non-reentrant
     */
    function sync() external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusBorrowControl.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusTerminal} from "./ICygnusTerminal.sol";

/**
 *  @title  ICygnusBorrowControl Interface for the control of borrow contracts (interest rate params, reserves, etc.)
 *  @notice Admin contract for Cygnus Borrow contract 👽
 */
interface ICygnusBorrowControl is ICygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when attempting to set a parameter outside the min/max ranges allowed in the Control contract
     *
     *  @custom:error ParameterNotInRange
     */
    error CygnusBorrowControl__ParameterNotInRange();

    /**
     *  @dev Reverts when setting the collateral if the msg.sender is not the hangar18 contract
     *
     *  @custom:error MsgSenderNotHangar
     */
    error CygnusBorrowControl__MsgSenderNotHangar();

    /**
     *  @dev Reverts wehn attempting to set a collateral that has already been set
     *
     *  @custom:error CollateralAlreadySet
     */
    error CygnusBorrowControl__CollateralAlreadySet();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    event NewCollateralAdded(address sender, address collateral, uint256 collateralsLength);

    /**
     *  @dev Logs when a new contract is set that rewards users in CYG
     *
     *  @param oldRewarder The address of the rewarder up until this point used for CYG distribution
     *  @param newRewarder The address of the new rewarder
     *
     *  @custom:event NewCygnusBorrowRewarder
     */
    event NewPillarsOfCreation(address oldRewarder, address newRewarder);

    /**
     *  @dev Logs when a new reserve factory is set by admin
     *
     *  @param oldReserveFactor The reserve factor used in this shuttle until this point
     *  @param newReserveFactor The new reserve factor set
     *
     *  @custom:event NewReserveFactor
     */
    event NewReserveFactor(uint256 oldReserveFactor, uint256 newReserveFactor);

    /**
     *  @dev Logs when a new interest rate curve is set for this shuttle
     *
     *  @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     *  @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     *  @param kinkMultiplier_ The increase to multiplier per year once kink utilization is reached
     *  @param kinkUtilizationRate_ The rate at which the jump interest rate takes effect
     *
     *  custom:event NewInterestRateParameters
     */ // prettier-ignore
    event NewInterestRateParameters( uint256 baseRatePerYear, uint256 multiplierPerYear, uint256 kinkMultiplier_, uint256 kinkUtilizationRate_);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @custom:struct InterestRateModel The structwith the interest rate params for this pool
     *  @custom:member baseRatePerSecond The base interest rate which is the y-intercept when utilization rate is 0
     *  @custom:member multiplierPerSecond The multiplier of utilization rate that gives the slope of the interest rate
     *  @custom:member jumpMultiplierPerSecond The multiplierPerSecond after hitting a specified utilization point
     *  @custom:member kink The utilization point at which the jump multiplier is applied
     */
    struct InterestRateModel {
        uint64 baseRatePerSecond;
        uint64 multiplierPerSecond;
        uint64 jumpMultiplierPerSecond;
        uint64 kink;
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return collateral The address of the collateral
     */
    function collateral() external view returns (address);

    /**
     *  @return pillarsOfCreation Address of the contract that rewards both borrowers and lenders in CYG
     */
    function pillarsOfCreation() external view returns (address);

    // ────────────── Current Pool Rates ──────────────

    /**
     *  @notice The current interest rate params set for this pool
     *  @return baseRatePerSecond The base interest rate which is the y-intercept when utilization rate is 0
     *  @return multiplierPerSecond The multiplier of utilization rate that gives the slope of the interest rate
     *  @return jumpMultiplierPerSecond The multiplierPerSecond after hitting a specified utilization point
     *  @return kink The utilization point at which the jump multiplier is applied
     */
    // prettier-ignore
    function interestRateModel() external view returns (uint64 baseRatePerSecond, uint64 multiplierPerSecond, uint64 jumpMultiplierPerSecond, uint64 kink);

    /**
     *  @return reserveFactor Percentage of interest that is routed to this market's Reserve Pool
     */
    function reserveFactor() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Admin 👽
     *  @notice Updates the reserve factor
     *
     *  @param newReserveFactor The new reserve factor for this shuttle
     *
     *  @custom:security only-admin
     */
    function setReserveFactor(uint256 newReserveFactor) external;

    /**
     *  @notice Admin 👽
     *  @notice Internal function to update the parameters of the interest rate model
     *
     *  @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     *  @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     *  @param kinkMultiplier_ The increase to farmApy once kink utilization is reached
     *  @param kinkUtilizationRate_ The new utilization rate
     *
     *  @custom:security only-admin
     */
    function setInterestRateModel(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 kinkMultiplier_,
        uint256 kinkUtilizationRate_
    ) external;

    /**
     *  @notice Admin 👽
     *  @notice Updates the pillars of creation contract. This can be updated to the zero address in case we need
     *          to remove rewards from pools saving us gas instead of calling the contract.
     *
     *  @param newPillars The address of the new CYG rewarder
     *
     *  @custom:security only-admin
     */
    function setPillarsOfCreation(address newPillars) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusBorrowModel.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusBorrowControl} from "./ICygnusBorrowControl.sol";

/**
 *  @title ICygnusBorrowModel
 *  @notice Interface for the Borrowable's model which takes into account interest accruals and borrow snapshots
 */
interface ICygnusBorrowModel is ICygnusBorrowControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when interest is accrued to borrows and reserves
     *
     *  @param cash Total balance of the underlying in the strategy
     *  @param borrows Latest total borrows stored
     *  @param interest Interest accumulated since last accrual
     *  @param reserves The amount of CygUSD minted to the DAO
     *
     *  @custom:event AccrueInterest
     */
    event AccrueInterest(uint256 cash, uint256 borrows, uint256 interest, uint256 reserves);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return totalBorrows Total borrows stored in the lending pool
     */
    function totalBorrows() external view returns (uint256);

    /**
     *  @return borrowIndex Borrow index stored of this lending pool, starts at 1e18
     */
    function borrowIndex() external view returns (uint256);

    /**
     *  @return lastAccrualTimestamp The unix timestamp stored of the last interest rate accrual
     */
    function lastAccrualTimestamp() external view returns (uint256);

    /**
     *  @notice This public view function is used to get the borrow balance of users and their principal.
     *
     *  @param borrower The address whose balance should be calculated
     *
     *  @return principal The USD amount borrowed without interest accrual
     *  @return borrowBalance The USD amount borrowed with interest accrual (ie. USD amount the borrower must repay)
     */
    function getBorrowBalance(address borrower) external view returns (uint256 principal, uint256 borrowBalance);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return utilizationRate The total amount of borrowed funds divided by the total cash the pool has available
     */
    function utilizationRate() external view returns (uint256);

    /**
     *  @return borrowRate The current per-second borrow rate stored for this pool.
     */
    function borrowRate() external view returns (uint256);

    /**
     *  @return supplyRate The current APR for lenders
     */
    function supplyRate() external view returns (uint256);

    /**
     *  @return getUsdPrice the price of the denomination token
     */
    function getUsdPrice() external view returns (uint256);

    /**
     *  @notice Get the lender`s full position
     *  @param lender The address of the lender
     *  @return lendingTokenBalance The lender's position in USD
     *  @return positionInUsd The lender's position in USD
     */
    function getLenderPosition(address lender) external view returns (uint256 lendingTokenBalance, uint256 positionInUsd);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Manually track the user's deposited USD
     *
     *  @param lender The address of the lender
     */
    function trackLender(address lender) external;

    /**
     *  @notice Applies interest accruals to borrows and reserves
     */
    function accrueInterest() external;

    /**
     *  @notice Manually track the user's borrows
     *
     *  @param borrower The address of the borrower
     */
    function trackBorrower(address borrower) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusBorrowVoid.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusBorrowModel} from "./ICygnusBorrowModel.sol";

/**
 *  @title  ICygnusBorrowVoid
 *  @notice Interface for `CygnusBorrowVoid` which is in charge of connecting the stablecoin Token with
 *          a specified strategy (for example connect to a rewarder contract to stake the USDC, etc.)
 */
interface ICygnusBorrowVoid is ICygnusBorrowModel {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts if msg.sender is not the harvester
     *
     *  @custom:error OnlyHarvesterAllowed
     */
    error CygnusBorrowVoid__OnlyHarvesterAllowed();

    /**
     *  @dev Reverts if the token we are sweeping is underlying
     *
     *  @custom:error TokenIsUnderlying
     */
    error CygnusBorrowVoid__TokenIsUnderlying();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when the strategy is first initialized or re-approves contracts
     *
     *  @param underlying The address of the underlying LP
     *  @param shuttleId The unique ID of the lending pool
     *  @param whitelisted The contract we approved to use our underlying
     *
     *  @custom:event ChargeVoid
     */
    event ChargeVoid(address underlying, uint256 shuttleId, address whitelisted);

    /**
     *  @dev Logs when rewards are harvested
     *
     *  @param sender The address of the caller who harvested the rewards
     *  @param tokens Total reward tokens harvested
     *  @param amounts Amounts of reward tokens harvested
     *  @param timestamp The timestamp of the harvest
     *
     *  @custom:event RechargeVoid
     */
    event RechargeVoid(address indexed sender, address[] tokens, uint256[] amounts, uint256 timestamp);

    /**
     *  @dev Logs when admin sets a new harvester to reinvest rewards
     *
     *  @param oldHarvester The address of the old harvester
     *  @param newHarvester The address of the new harvester
     *  @param rewardTokens The reward tokens added for the new harvester
     *
     *  @custom:event NewHarvester
     */
    event NewHarvester(address oldHarvester, address newHarvester, address[] rewardTokens);

    /**
     *  @dev Logs when admin sets a new reward token for the harvester (if needed)
     *
     *  @param _token Address of the token we are allowing the harvester to move
     *  @param _harvester Address of the harvester
     *
     *  @custom:event NewBonusHarvesterToken
     */
    event NewBonusHarvesterToken(address _token, address _harvester);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return harvester The address of the harvester contract
     */
    function harvester() external view returns (address);

    /**
     *  @return lastHarvest Timestamp of the last reinvest performed by the harvester contract
     */
    function lastHarvest() external view returns (uint256);

    /**
     *  @notice Array of reward tokens for this pool
     *  @param index The index of the token in the array
     *  @return rewardToken The reward token
     */
    function allRewardTokens(uint256 index) external view returns (address rewardToken);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return rewarder The address of the rewarder contract
     */
    function rewarder() external view returns (address);

    /**
     *  @return rewardTokensLength Length of reward tokens
     */
    function rewardTokensLength() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Get the pending rewards manually - helpful to get rewards through static calls
     *
     *  @return tokens The addresses of the reward tokens earned by harvesting rewards
     *  @return amounts The amounts of each token received
     *
     *  @custom:security non-reentrant
     */
    function getRewards() external returns (address[] memory tokens, uint256[] memory amounts);

    /**
     *  @notice Only the harvester can reinvest
     *  @notice Reinvests all rewards from the rewarder to buy more USD to then deposit back into the rewarder
     *          This makes underlying balance increase in this contract, increasing the exchangeRate between
     *          CygUSD and underlying and thus lowering utilization rate and borrow rate
     *
     *  @custom:security non-reentrant only-harvester
     */
    function reinvestRewards_y7b(uint256 liquidity) external;

    /**
     *  @notice Admin 👽
     *  @notice Charges approvals needed for deposits and withdrawals, and any other function
     *          needed to get the vault started. ie, setting a pool ID from a MasterChef, a gauge, etc.
     *
     *  @custom:security only-admin
     */
    function chargeVoid() external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the harvester address to harvest and reinvest rewards into more underlying
     *
     *  @param _harvester The address of the new harvester contract
     *  @param rewardTokens Array of reward tokens
     *
     *  @custom:security only-admin
     */
    function setHarvester(address _harvester, address[] calldata rewardTokens) external;

    /**
     *  @notice Admin 👽
     *  @notice Sweeps a token that was sent to this address by mistake, or a bonus reward token we are not tracking. Cannot
     *          sweep the underlying USD or USD LP token (like Comp USDC, etc.)
     *
     *  @custom:security only-admin
     */
    function sweepToken(address token, address to) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusCollateral.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusCollateralVoid} from "./ICygnusCollateralVoid.sol";

/**
 *  @title ICygnusCollateral
 *  @notice Interface for the main collateral contract which handles collateral seizes and flash redeems
 */
interface ICygnusCollateral is ICygnusCollateralVoid {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when the user doesn't have enough liquidity to redeem
     *
     *  @custom:error InsufficientLiquidity
     */
    error CygnusCollateral__InsufficientLiquidity();

    /**
     *  @dev Reverts when the msg.sender of the liquidation is not this contract`s borrowable
     *
     *  @custom:error MsgSenderNotBorrowable
     */
    error CygnusCollateral__MsgSenderNotBorrowable();

    /**
     *  @dev Reverts when the repayAmount in a liquidation is 0
     *
     *  @custom:error CantLiquidateZero
     */
    error CygnusCollateral__CantLiquidateZero();

    /**
     *  @dev Reverts when trying to redeem 0 tokens
     *
     *  @custom:error CantRedeemZero
     */
    error CygnusCollateral__CantRedeemZero();

    /**
     * @dev Reverts when liquidating an account that has no shortfall
     *
     * @custom:error NotLiquidatable
     */
    error CygnusCollateral__NotLiquidatable();

    /**
     *  @dev Reverts when redeeming more shares than CygLP in this contract
     *
     *  @custom:error InsufficientRedeemAmount
     */
    error CygnusCollateral__InsufficientCygLPReceived();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when collateral is seized from the borrower and sent to the liquidator
     *
     *  @param liquidator The address of the liquidator
     *  @param borrower The address of the borrower being liquidated
     *  @param cygLPAmount The amount of CygLP seized without taking into account incentive or fee
     *  @param liquidatorAmount The aamount of CygLP seized sent to the liquidator (with the liq. incentive)
     *  @param daoFee The amount of CygLP sent to the DAO Reserves
     *  @param totalSeized The total amount of CygLP seized from the borrower
     */
    event SeizeCygLP(
        address indexed liquidator,
        address indexed borrower,
        uint256 cygLPAmount,
        uint256 liquidatorAmount,
        uint256 daoFee,
        uint256 totalSeized
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Seizes CygLP from borrower and adds it to the liquidator's account.
     *  @notice Not marked as non-reentrant
     *
     *  @dev This should be called from `borrowable` contract, else it reverts
     *
     *  @param liquidator The address repaying the borrow and seizing the collateral
     *  @param borrower The address of the borrower
     *  @param repayAmount The number of collateral tokens to seize
     *
     *  @return liquidatorAmount The amount of CygLP that the liquidator received for liquidating the position
     */
    function seizeCygLP(address liquidator, address borrower, uint256 repayAmount) external returns (uint256 liquidatorAmount);

    /**
     *  @notice Flash redeems the underlying LP Token
     *
     *  @dev This should be called from `Altair` contract
     *
     *  @param redeemer The address redeeming the tokens (Altair contract)
     *  @param assets The amount of the underlying assets to redeem
     *  @param data Calldata passed from and back to router contract
     *
     *  @custom:security non-reentrant
     */
    function flashRedeemAltair(address redeemer, uint256 assets, bytes calldata data) external returns (uint256 usdAmount);

    /**
     *  @notice Manually sync the balance held of the underlying
     *  @custom:security non-reentrant
     */
    function sync() external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusCollateralControl.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusTerminal} from "./ICygnusTerminal.sol";

/**
 *  @title  ICygnusCollateralControl Interface for the admin control of collateral contracts (incentives, debt ratios)
 *  @notice Admin contract for Cygnus Collateral contract 👽
 */
interface ICygnusCollateralControl is ICygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when attempting to set a parameter outside the min/max ranges allowed in the Control contract
     *
     *  @custom:error ParameterNotInRange
     */
    error CygnusCollateralControl__ParameterNotInRange();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════  
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when the max debt ratio is updated for this shuttle
     *
     *  @param oldDebtRatio The old debt ratio at which the collateral was liquidatable in this shuttle
     *  @param newDebtRatio The new debt ratio for this shuttle
     *
     *  @custom:event NewDebtRatio
     */
    event NewDebtRatio(uint256 oldDebtRatio, uint256 newDebtRatio);

    /**
     *  @dev Logs when a new liquidation incentive is set for liquidators
     *
     *  @param oldLiquidationIncentive The old incentive for liquidators taken from the collateral
     *  @param newLiquidationIncentive The new liquidation incentive for this shuttle
     *
     *  @custom:event NewLiquidationIncentive
     */
    event NewLiquidationIncentive(uint256 oldLiquidationIncentive, uint256 newLiquidationIncentive);

    /**
     *  @dev Logs when a new liquidation fee is set, which the protocol keeps from each liquidation
     *
     *  @param oldLiquidationFee The previous fee the protocol kept as reserves from each liquidation
     *  @param newLiquidationFee The new liquidation fee for this shuttle
     *
     *  @custom:event NewLiquidationFee
     */
    event NewLiquidationFee(uint256 oldLiquidationFee, uint256 newLiquidationFee);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return borrowable The address of the Cygnus borrow contract for this collateral which holds USDC
     */
    function borrowable() external view returns (address);

    // ────────────── Current Pool Rates ──────────────

    /**
     *  @return debtRatio The current debt ratio for this shuttle, default at 95%
     */
    function debtRatio() external view returns (uint256);

    /**
     *  @return liquidationIncentive The current liquidation incentive for this shuttle
     */
    function liquidationIncentive() external view returns (uint256);

    /**
     *  @return liquidationFee The current liquidation fee the protocol keeps from each liquidation
     */
    function liquidationFee() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Admin 👽
     *  @notice Updates the debt ratio for the shuttle
     *
     *  @param  newDebtRatio The new requested point at which a loan is liquidatable
     *
     *  @custom:security only-admin
     */
    function setDebtRatio(uint256 newDebtRatio) external;

    /**
     *  @notice Admin 👽
     *  @notice Updates the liquidation incentive for the shuttle
     *
     *  @param  newLiquidationIncentive The new requested profit liquidators keep from the collateral
     *
     *  @custom:security only-admin
     */
    function setLiquidationIncentive(uint256 newLiquidationIncentive) external;

    /**
     *  @notice Admin 👽
     *  @notice Updates the fee the protocol keeps for every liquidation
     *
     *  @param newLiquidationFee The new requested fee taken from the liquidation incentive
     *
     *  @custom:security only-admin
     */
    function setLiquidationFee(uint256 newLiquidationFee) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusCollateralModel.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusCollateralControl} from "./ICygnusCollateralControl.sol";

/**
 *  @title ICygnusCollateralModel The interface for querying any borrower's positions and find liquidity/shortfalls
 */
interface ICygnusCollateralModel is ICygnusCollateralControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when the borrower is the zero address or this collateral
     *
     *  @custom:error InvalidBorrower
     */
    error CygnusCollateralModel__InvalidBorrower();

    /**
     *  @dev Reverts when the price returned from the oracle is 0
     *
     *  @custom:error PriceCantBeZero
     */
    error CygnusCollateralModel__PriceCantBeZero();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Checks if the given user is able to redeem the specified amount of LP tokens.
     *
     *  @param borrower The address of the user to check.
     *  @param redeemAmount The amount of LP tokens to be redeemed.
     *  @return True if the user can redeem, false otherwise.
     *
     */
    function canRedeem(address borrower, uint256 redeemAmount) external view returns (bool);

    /**
     *  @notice Get the price of 1 amount of the underlying in stablecoins. Note: It returns the price in the borrowable`s
     *          decimals. ie If USDC, returns price in 6 deicmals, if DAI/BUSD in 18
     *  @notice Calls the oracle to return the price of 1 unit of the underlying LP Token of this shuttle
     *
     *  @return lpTokenPrice The price of 1 LP Token in USDC
     */
    function getLPTokenPrice() external view returns (uint256);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Gets an account's liquidity or shortfall
     *
     *  @param borrower The address of the borrower
     *  @return liquidity The account's liquidity in USDC
     *  @return shortfall If user has no liquidity, return the shortfall in USDC
     */
    function getAccountLiquidity(address borrower) external view returns (uint256 liquidity, uint256 shortfall);

    /**
     *  @notice Check if a borrower can borrow a specified amount of an asset from CygnusBorrow.
     *  @dev Throws a custom error message if the borrowableToken is invalid.
     *  @dev Calls the internal accountLiquidityInternal function to calculate the borrower's liquidity and shortfall.
     *
     *  @param borrower The address of the borrower to check.
     *  @param borrowAmount The amount the borrower wishes to borrow.
     *
     *  @return A boolean indicating whether the borrower can borrow the specified amount.
     */
    function canBorrow(address borrower, uint256 borrowAmount) external view returns (bool);

    /**
     *  @notice Gets the account's total position value in USD (LP Tokens owned multiplied by LP price). It uses the oracle to get the
     *          price of the LP Token and uses the current exchange rate.
     *
     *  @param borrower The address of the borrower
     *
     *  @return lpBalance The borrower`s position in LP Tokens
     *  @return positionUsd The borrower's position in USD. position = CygLP Balance * Exchange Rate * LP Token Price
     *  @return health The user's current loan health (once it reaches 100% the user becomes liquidatable)
     */
    function getBorrowerPosition(address borrower) external view returns (uint256 lpBalance, uint256 positionUsd, uint256 health);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusCollateralVoid.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusCollateralModel} from "./ICygnusCollateralModel.sol";

/**
 *  @title ICygnusCollateralVoid
 *  @notice Interface for `CygnusCollateralVoid` which is in charge of connecting the collateral LP Tokens with
 *          a specified strategy (for example connect to a rewarder contract to stake the LP Token, etc.)
 */
interface ICygnusCollateralVoid is ICygnusCollateralModel {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts if msg.sender is not the harvester
     *
     *  @custom:error OnlyHarvesterAllowed
     */
    error CygnusCollateralVoid__OnlyHarvesterAllowed();

    /**
     *  @dev Reverts if the token we are sweeping is the underlying LP
     *
     *  @custom:error TokenIsUnderlying
     */
    error CygnusCollateralVoid__TokenIsUnderlying();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when the strategy is first initialized or re-approves contracts
     *
     *  @param underlying The address of the underlying stablecoin
     *  @param shuttleId The unique ID of the lending pool
     *  @param whitelisted The contract we approved to use our underlying
     *
     *  @custom:event ChargeVoid
     */
    event ChargeVoid(address underlying, uint256 shuttleId, address whitelisted);

    /**
     *  @dev Logs when rewards are harvested
     *
     *  @param sender The address of the caller who harvested the rewards
     *  @param tokens Total reward tokens harvested
     *  @param amounts Amounts of reward tokens harvested
     *  @param timestamp The timestamp of the harvest
     *
     *  @custom:event RechargeVoid
     */
    event RechargeVoid(address indexed sender, address[] tokens, uint256[] amounts, uint256 timestamp);

    /**
     *  @dev Logs when admin sets a new harvester to reinvest rewards
     *
     *  @param oldHarvester The address of the old harvester
     *  @param newHarvester The address of the new harvester
     *  @param rewardTokens The reward tokens added for the new harvester
     *
     *  @custom:event NewHarvester
     */
    event NewHarvester(address oldHarvester, address newHarvester, address[] rewardTokens);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return harvester The address of the harvester contract
     */
    function harvester() external view returns (address);

    /**
     *  @return lastHarvest Timestamp of the last harvest performed by the harvester contract
     */
    function lastHarvest() external view returns (uint256);

    /**
     *  @notice Array of reward tokens for this pool
     *  @param index The index of the token in the array
     *  @return rewardToken The reward token
     */
    function allRewardTokens(uint256 index) external view returns (address rewardToken);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return rewarder The address of the rewarder contract
     */
    function rewarder() external view returns (address);

    /**
     *  @return rewardTokensLength Length of reward tokens
     */
    function rewardTokensLength() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Get the pending rewards manually - helpful to get rewards through static calls
     *
     *  @return tokens The addresses of the reward tokens earned by harvesting rewards
     *  @return amounts The amounts of each token received
     *
     *  @custom:security non-reentrant
     */
    function getRewards() external returns (address[] memory tokens, uint256[] memory amounts);

    /**
     *  @notice Only the harvester can reinvest
     *  @notice Reinvests all rewards from the rewarder to buy more LP to then deposit back into the rewarder
     *          This makes underlying LP balance increase in this contract, increasing the exchangeRate between
     *          CygLP and underlying and thus lowering debt ratio for all borrwers in the pool as they own more LP.
     *
     *  @custom:security non-reentrant only-harvester
     */
    function reinvestRewards_y7b(uint256 liquidity) external;

    /**
     *  @notice Admin 👽
     *  @notice Charges approvals needed for deposits and withdrawals, and any other function
     *          needed to get the vault started. ie, setting a pool ID from a MasterChef, a gauge, etc.
     *
     *  @custom:security only-admin
     */
    function chargeVoid() external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the harvester address to harvest and reinvest rewards into more underlying
     *
     *  @param _harvester The address of the new harvester contract
     *
     *  @custom:security only-admin
     */
    function setHarvester(address _harvester, address[] calldata rewardTokens) external;

    /**
     *  @notice Admin 👽
     *  @notice Sweeps a token that was sent to this address by mistake, or a bonus reward token we are not tracking. Cannot
     *          sweep the underlying LP
     *
     *  @custom:security only-admin
     */
    function sweepToken(address token, address to) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusNebulaOracle.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.17;

// Interfaces
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";
import {IERC20} from "./IERC20.sol";

/**
 *  @title ICygnusNebula Interface to interact with Cygnus' LP Oracle
 *  @author CygnusDAO
 */
interface ICygnusNebula {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when attempting to initialize an already initialized LP Token
     *
     *  @param lpTokenPair The address of the LP Token we are initializing
     *
     *  @custom:error PairIsInitialized
     */
    error CygnusNebulaOracle__PairAlreadyInitialized(address lpTokenPair);

    /**
     *  @dev Reverts when attempting to get the price of an LP Token that is not initialized
     *
     *  @param lpTokenPair THe address of the LP Token we are getting the price for
     *
     *  @custom:error PairNotInitialized
     */
    error CygnusNebulaOracle__PairNotInitialized(address lpTokenPair);

    /**
     *  @dev Reverts when attempting to access admin only methods
     *
     *  @param sender The address of msg.sender
     *
     *  @custom:error MsgSenderNotAdmin
     */
    error CygnusNebulaOracle__MsgSenderNotAdmin(address sender);

    /**
     *  @dev Reverts when attempting to set the admin if the pending admin is the zero address
     *
     *  @param pendingAdmin The address of the pending oracle admin
     *
     *  @custom:error AdminCantBeZero
     */
    error CygnusNebulaOracle__AdminCantBeZero(address pendingAdmin);

    /**
     *  @dev Reverts when attempting to set the same pending admin twice
     *
     *  @param pendingAdmin The address of the pending oracle admin
     *
     *  @custom:error PendingAdminAlreadySet
     */
    error CygnusNebulaOracle__PendingAdminAlreadySet(address pendingAdmin);

    /**
     *  @dev Reverts when getting a record if not initialized
     *
     *  @param lpTokenPair The address of the LP Token for the record
     *
     *  @custom:error NebulaRecordNotInitialized
     */
    error CygnusNebulaOracle__NebulaRecordNotInitialized(address lpTokenPair);

    /**
     *  @dev Reverts when re-initializing a record
     *
     *  @param lpTokenPair The address of the LP Token for the record
     *
     *  @custom:error NebulaRecordAlreadyInitialized
     */
    error CygnusNebulaOracle__NebulaRecordAlreadyInitialized(address lpTokenPair);

    /**
     *  @dev Reverts when the price of an initialized `lpTokenPair` is 0
     *
     *  @param lpTokenPair The address of the LP Token for the record
     *
     *  @custom:error NebulaRecordAlreadyInitialized
     */
    error CygnusNebulaOracle__PriceCantBeZero(address lpTokenPair);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when an LP Token pair's price starts being tracked
     *
     *  @param initialized Whether or not the LP Token is initialized
     *  @param oracleId The ID for this oracle
     *  @param lpTokenPair The address of the LP Token
     *  @param poolTokens The addresses of the tokens for this LP Token
     *  @param poolTokensDecimals The decimals of each pool token
     *  @param priceFeeds The addresses of the price feeds for the tokens
     *  @param priceFeedsDecimals The decimals of each price feed
     *
     *  @custom:event InitializeCygnusNebula
     */
    event InitializeNebulaOracle(
        bool initialized,
        uint88 oracleId,
        address lpTokenPair,
        IERC20[] poolTokens,
        uint256[] poolTokensDecimals,
        AggregatorV3Interface[] priceFeeds,
        uint256[] priceFeedsDecimals
    );

    /**
     *  @dev Logs when a new pending admin is set, to be accepted by admin
     *
     *  @param oracleCurrentAdmin The address of the current oracle admin
     *  @param oraclePendingAdmin The address of the pending oracle admin
     *
     *  @custom:event NewNebulaPendingAdmin
     */
    event NewOraclePendingAdmin(address oracleCurrentAdmin, address oraclePendingAdmin);

    /**
     *  @dev Logs when the pending admin is confirmed as the new oracle admin
     *
     *  @param oracleOldAdmin The address of the old oracle admin
     *  @param oracleNewAdmin The address of the new oracle admin
     *
     *  @custom:event NewNebulaAdmin
     */
    event NewOracleAdmin(address oracleOldAdmin, address oracleNewAdmin);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice The struct record of each oracle used by Cygnus
     *  @custom:member initialized Whether an LP Token is being tracked or not
     *  @custom:member oracleId The ID of the LP Token tracked by the oracle
     *  @custom:member name User friendly name of the underlying
     *  @custom:member underlying The address of the LP Token
     *  @custom:member poolTokens Array of all the pool tokens
     *  @custom:member poolTokensDecimals Array of the decimals of each pool token
     *  @custom:member priceFeeds Array of all the Chainlink price feeds for the pool tokens
     *  @custom:member priceFeedsDecimals Array of the decimals of each price feed
     */
    struct NebulaOracle {
        bool initialized;
        uint88 oracleId;
        string name;
        address underlying;
        IERC20[] poolTokens;
        uint256[] poolTokensDecimals;
        AggregatorV3Interface[] priceFeeds;
        uint256[] priceFeedsDecimals;
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Returns the struct record of each oracle used by Cygnus
     *
     *  @param lpTokenPair The address of the LP Token
     *  @return nebulaOracle Struct of the oracle for the LP Token
     */
    function getNebulaOracle(address lpTokenPair) external view returns (NebulaOracle memory nebulaOracle);

    /**
     *  @notice Gets the address of the LP Token that (if) is being tracked by this oracle
     *
     *  @param id The ID of each LP Token that is being tracked by this oracle
     *  @return The address of the LP Token if it is being tracked by this oracle, else returns address zero
     */
    function allNebulas(uint256 id) external view returns (address);

    /**
     *  @return The name for this Cygnus-Chainlink Nebula oracle
     */
    function name() external view returns (string memory);

    /**
     *  @return The address of the Cygnus admin
     */
    function admin() external view returns (address);

    /**
     *  @return The address of the new requested admin
     */
    function pendingAdmin() external view returns (address);

    /**
     *  @return The version of this oracle
     */
    function version() external view returns (string memory);

    /**
     *  @return SECONDS_PER_YEAR The number of seconds in year assumed by the oracle
     */
    function SECONDS_PER_YEAR() external view returns (uint256);

    /**
     *  @notice We use a constant to set the chainlink aggregator decimals. As stated by chainlink all decimals for tokens
     *          denominated in USD are 8 decimals. And all decimals for tokens denominated in ETH are 18 decimals. We use
     *          tokens denominated in USD, so we set the constant to 8 decimals.
     *  @return AGGREGATOR_DECIMALS The decimals used by Chainlink (8 for all tokens priced in USD, 18 for priced in ETH)
     */
    function AGGREGATOR_DECIMALS() external pure returns (uint256);

    /**
     *  @return The scalar used to price the token in 18 decimals (ie. 10 ** (18 - AGGREGATOR_DECIMALS))
     */
    function AGGREGATOR_SCALAR() external pure returns (uint256);

    /**
     *  @return How many LP Token pairs' prices are being tracked by this oracle
     */
    function nebulaSize() external view returns (uint88);

    /**
     *  @return The denomination token this oracle returns the price in
     */
    function denominationToken() external view returns (IERC20);

    /**
     *  @return The decimals for this Cygnus-Chainlink Nebula oracle
     */
    function decimals() external view returns (uint8);

    /**
     *  @return The address of Chainlink's denomination oracle
     */
    function denominationAggregator() external view returns (AggregatorV3Interface);

    /**
     *  @return nebulaRegistry The address of the nebula registry
     */
    function nebulaRegistry() external view returns (address);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return The price of the denomination token in oracle decimals
     */
    function denominationTokenPrice() external view returns (uint256);

    /**
     *  @notice Get the APR given 2 exchange rates and the time elapsed between them. This is helpful for tokens
     *          that meet x*y=k such as UniswapV2 since exchange rates should never decrease (else LPs lose cash).
     *          Uses the natural log to avoid overflowing when we annualize the log difference.
     *
     *  @param exchangeRateLast The previous exchange rate
     *  @param exchangeRateNow The current exchange rate
     *  @param timeElapsed Time elapsed between the exchange rates
     *  @return apr The estimated base rate (APR excluding any token rewards)
     */
    function getAnnualizedBaseRate(
        uint256 exchangeRateLast,
        uint256 exchangeRateNow,
        uint256 timeElapsed
    ) external pure returns (uint256 apr);

    /**
     *  @notice Gets the latest price of the LP Token denominated in denomination token
     *  @notice LP Token pair must be initialized, else reverts with custom error
     *
     *  @param lpTokenPair The address of the LP Token
     *  @return lpTokenPrice The price of the LP Token denominated in denomination token
     */
    function lpTokenPriceUsd(address lpTokenPair) external view returns (uint256 lpTokenPrice);

    /**
     *  @notice Gets the latest price of the LP Token's token0 and token1 denominated in denomination token
     *  @notice Used by Cygnus Altair contract to calculate optimal amount of leverage
     *
     *  @param lpTokenPair The address of the LP Token
     *  @return Array of the LP's asset prices
     */
    function assetPricesUsd(address lpTokenPair) external view returns (uint256[] memory);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Admin 👽
     *  @notice Initialize an LP Token pair, only admin
     *
     *  @param lpTokenPair The contract address of the LP Token
     *  @param aggregators Array of Chainlink aggregators for this LP token's tokens
     *
     *  @custom:security non-reentrant only-admin
     */
    function initializeNebulaOracle(address lpTokenPair, AggregatorV3Interface[] calldata aggregators) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusNebulaOracle.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.17;

// Interfaces
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";
import {ICygnusNebula} from "./ICygnusNebula.sol";
import {IERC20} from "./IERC20.sol";

/**
 *  @title ICygnusNebulaOracle Interface to interact with Cygnus' LP Oracle
 *  @author CygnusDAO
 */
interface ICygnusNebulaRegistry {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when attempting to set admin as the zero address
     *
     *  @custom:error AdminCantBeZero
     */
    error CygnusNebula__AdminCantBeZero();

    /**
     *  @dev Reverts when attempting to set the same pending admin twice
     *
     *  @custom:error PendingAdminAlreadySet
     */
    error CygnusNebula__PendingAdminAlreadySet();

    /**
     *  @dev Reverts when the msg.sender is not the registry's admin
     *
     *  @custom:error SenderNotAdmin
     */
    error CygnusNebula__SenderNotAdmin();

    /**
     *  @dev Reverts when setting a new oracle (ie a new UniV2 oracle)
     *
     *  @custom:error OracleAlreadyAdded
     */
    error CygnusNebula__OracleAlreadyAdded();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when a new pending admin is set, to be accepted by admin
     *
     *  @param oldPendingAdmin The address of the current oracle admin
     *  @param newPendingAdmin The address of the pending oracle admin
     *
     *  @custom:event NewNebulaPendingAdmin
     */
    event NewNebulaPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     *  @dev Logs when the pending admin is confirmed as the new oracle admin
     *
     *  @param oldAdmin The address of the old oracle admin
     *  @param newAdmin The address of the new oracle admin
     *
     *  @custom:event NewNebulaAdmin
     */
    event NewNebulaAdmin(address oldAdmin, address newAdmin);

    /**
     *  @dev Logs when a new nebula oracle is added
     *
     *  @param oracle The address of the new oracle
     *  @param oracleId The ID of the oracle
     *
     *  @custom:event NewNebulaOracle
     */
    event NewNebulaOracle(address oracle, uint256 oracleId);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Struct for each nebula
     *  @custom:member name Friendly name to identify the Nebula
     *  @custom:member nebula The address of the nebula
     *  @custom:member nebulaId The ID of the nebula
     *  @custom:member totalOracles The total amount of initialized oracles
     */
    struct CygnusNebula {
        string name;
        address nebula;
        uint256 nebulaId;
        uint256 totalOracles;
    }

    /**
     *  @return The name for the registry
     */
    function name() external view returns (string memory);

    /**
     *  @return The address of the Cygnus admin
     */
    function admin() external view returns (address);

    /**
     *  @return The address of the new requested admin
     */
    function pendingAdmin() external view returns (address);

    /**
     *  @notice Array of Nebula structs
     *  @param index The index of the nebula struct
     *  @return _name User friendly name of the Nebula (ie 'Constant Product AMMs')
     *  @return _nebula The address of the nebula
     *  @return id The ID of the nebula
     *  @return totalOracles The total amount of initialized oracles in this nebula
     */
    function allNebulas(uint256 index) external view returns (string memory _name, address _nebula, uint256 id, uint256 totalOracles);

    /**
     *  @notice Array of initialized LP Token pairs
     *  @param index THe index of the nebula oracle
     *  @return lpTokenPair The address of the LP Token pair
     */
    function allNebulaOracles(uint256 index) external view returns (address lpTokenPair);

    /**
     *  @notice Length of nebulas added
     */
    function totalNebulas() external view returns (uint256);

    /**
     *  @notice Total LP Token pairs
     */
    function totalNebulaOracles() external view returns (uint256);

    /**
     *  @notice Checks if nebula has already been added to the registry
     *  @param _nebula The address of the nebula
     *  @return Whether the nebula has been added or not
     */
    function isNebula(address _nebula) external view returns (bool);

    /**
     *  @notice Getter for the nebula struct given a nebula address
     *  @param _nebula The address of the nebula
     *  @return Record of the nebula
     */
    function getNebula(address _nebula) external view returns (CygnusNebula memory);

    /**
     *  @notice Getter for the nebula struct given an LP
     *  @param lpTokenPair The address of the LP Token
     *  @return Record of the nebula for this LP
     */
    function getLPTokenNebula(address lpTokenPair) external view returns (CygnusNebula memory);

    /**
     *  @notice Used gas savings during hangar18 shuttle deployments. Given an LP Token pair, we return the nebula address
     *  @param lpTokenPair The address of the LP Token
     *  @return nebula The address of the nebula for `lpTokenPair`
     */
    function getLPTokenNebulaAddress(address lpTokenPair) external view returns (address nebula);

    /**
     *  @notice Initializes an oracle for the LP, mapping it to the nebula
     *  @param nebulaId The ID of the nebula (ie. each nebula depends on the dex and the logic for calculating the LP Price)
     *  @param lpTokenPair The address of the LP Token
     *  @param aggregators Calldata array of Chainlink aggregators
     */
    function initializeOracle(uint256 nebulaId, address lpTokenPair, AggregatorV3Interface[] calldata aggregators) external;

    /**
     *  @notice Get the Oracle for the LP token pair
     *  @param lpTokenPair The address of the LP Token pair
     */
    function getNebulaOracle(address lpTokenPair) external view returns (ICygnusNebula.NebulaOracle memory);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Admin 👽
     *  @notice Adds a new nebula to the registry
     *
     *  @param _nebula Address of the new nebula
     *
     *  @custom:security only-admin
     */
    function addNebula(address _nebula) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets a new pending admin for the Oracle
     *
     *  @param newOraclePendingAdmin Address of the requested Oracle Admin
     *
     *  @custom:security non-reentrant only-admin
     */
    function setRegistryPendingAdmin(address newOraclePendingAdmin) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets a new admin for the Oracle
     *
     *  @custom:security non-reentrant only-admin
     */
    function setRegistryAdmin() external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusTerminal.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {IERC20Permit} from "./IERC20Permit.sol";

// Interfaces
import {IHangar18} from "./IHangar18.sol";
import {IAllowanceTransfer} from "./IAllowanceTransfer.sol";
import {ICygnusNebula} from "./ICygnusNebula.sol";

/**
 *  @title ICygnusTerminal
 *  @notice The interface to mint/redeem pool tokens (CygLP and CygUSD)
 */
interface ICygnusTerminal is IERC20Permit {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when attempting to mint zero shares
     *
     *  @custom:error CantMintZeroShares
     */
    error CygnusTerminal__CantMintZeroShares();

    /**
     *  @dev Reverts when attempting to redeem zero assets
     *
     *  @custom:error CantBurnZeroAssets
     */
    error CygnusTerminal__CantRedeemZeroAssets();

    /**
     *  @dev Reverts when attempting to call Admin-only functions
     *
     *  @custom:error MsgSenderNotAdmin
     */
    error CygnusTerminal__MsgSenderNotAdmin();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when totalBalance syncs with the underlying contract's balanceOf.
     *
     *  @param totalBalance Total balance in terms of the underlying
     *
     *  @custom:event Sync
     */
    event Sync(uint160 totalBalance);

    /**
     *  @dev Logs when CygLP or CygUSD pool tokens are minted
     *
     *  @param sender The address of `CygnusAltair` or the sender of the function call
     *  @param recipient Address of the minter
     *  @param assets Amount of assets being deposited
     *  @param shares Amount of pool tokens being minted
     *
     *  @custom:event Mint
     */
    event Deposit(address indexed sender, address indexed recipient, uint256 assets, uint256 shares);

    /**
     *  @dev Logs when CygLP or CygUSD are redeemed
     *
     *  @param sender The address of the redeemer of the shares
     *  @param recipient The address of the recipient of assets
     *  @param owner The address of the owner of the pool tokens
     *  @param assets The amount of assets to redeem
     *  @param shares The amount of pool tokens burnt
     *
     *  @custom:event Redeem
     */
    event Withdraw(address indexed sender, address indexed recipient, address indexed owner, uint256 assets, uint256 shares);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
           3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return PERMIT2 Uniswap's Permit2 router. We use the AllowanceTransfer as opposed to SignatureTransfer
     *                  to allow router deposits.
     */
    function PERMIT2() external view returns (IAllowanceTransfer);

    /**
     *  @return hangar18 The address of the Cygnus Factory contract used to deploy this shuttle
     */
    function hangar18() external view returns (IHangar18);

    /**
     *  @return underlying The address of the underlying (LP Token for collateral contracts, USDC for borrow contracts)
     */
    function underlying() external view returns (address);

    /**
     *  @return nebula The address of the oracle for this lending pool
     */
    function nebula() external view returns (ICygnusNebula);

    /**
     *  @return shuttleId The ID of the lending pool (shares by borrowable and collateral)
     */
    function shuttleId() external view returns (uint256);

    /**
     *  @return totalBalance Total available cash (USDC for borrowable, LPs by collateral) owned by this shuttle
     */
    function totalBalance() external view returns (uint160);

    /**
     *  @return totalAssets The total assets (including those not in this contract, ie. borrows) owned by this shuttle
     */
    function totalAssets() external view returns (uint256);

    /**
     *  @return exchangeRate The ratio which 1 pool token can be redeemed for underlying amount.
     */
    function exchangeRate() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice This function must be called with the `approve` method of the underlying asset token contract for
     *          the `assets` amount on behalf of the sender before calling this function.
     *  @notice Implements the deposit of the underlying asset into the Cygnus Vault pool. This function transfers
     *          the underlying assets from the sender to this contract and mints a corresponding amount of Cygnus
     *          Vault shares to the recipient. A deposit fee may be charged by the strategy, which is deducted from
     *          the deposited assets.
     *
     *  @dev If the deposit amount is less than or equal to 0, this function will revert.
     *
     *  @param assets Amount of the underlying asset to deposit.
     *  @param recipient Address that will receive the corresponding amount of shares.
     *  @param _permit Data signed over by the owner specifying the terms of approval
     *  @param _signature The owner's signature over the permit data
     *  @return shares Amount of Cygnus Vault shares minted and transferred to the `recipient`.
     */
    function deposit(
        uint256 assets,
        address recipient,
        IAllowanceTransfer.PermitSingle calldata _permit,
        bytes calldata _signature
    ) external returns (uint256 shares);

    /**
     *  @notice Redeems the specified amount of `shares` for the underlying asset and transfers it to `recipient`.
     *
     *  @dev shares must be greater than 0.
     *  @dev If the function is called by someone other than `owner`, then the function will reduce the allowance
     *       granted to the caller by `shares`.
     *
     *  @param shares The number of shares to redeem for the underlying asset.
     *  @param recipient The address that will receive the underlying asset.
     *  @param owner The address that owns the shares.
     *
     *  @return assets The amount of underlying assets received by the `recipient`.
     */
    function redeem(uint256 shares, address recipient, address owner) external returns (uint256 assets);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  IDenebOrbiter.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

/**
 *  @title ICygnusDeneb The interface for a contract that is capable of deploying Cygnus collateral pools
 *  @notice A contract that constructs a Cygnus collateral pool must implement this to pass arguments to the pool
 */
interface IDenebOrbiter {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Passing the struct parameters to the collateral contract avoids setting constructor
     *
     *  @return factory The address of the Cygnus factory
     *  @return underlying The address of the underlying LP Token
     *  @return borrowable The address of the Cygnus borrow contract for this collateral
     *  @return oracle The address of the oracle for this lending pool
     *  @return shuttleId The ID of the lending pool
     */
    function shuttleParameters()
        external
        returns (address factory, address underlying, address borrowable, address oracle, uint256 shuttleId);

    /**
     *  @return collateralInitCodeHash The init code hash of the collateral contract for this deployer
     */
    function collateralInitCodeHash() external view returns (bytes32);

    /**
     *  @notice Function to deploy the collateral contract of a lending pool
     *
     *  @param underlying The address of the underlying LP Token
     *  @param borrowable The address of the Cygnus borrow contract for this collateral
     *  @param oracle The address of the oracle for this lending pool
     *  @param shuttleId The ID of the lending pool
     *
     *  @return collateral The address of the new deployed Cygnus collateral contract
     */
    function deployDeneb(address underlying, address borrowable, address oracle, uint256 shuttleId) external returns (address collateral);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)
pragma solidity >=0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)
pragma solidity >=0.8.17;

import {IERC20} from "./IERC20.sol";

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

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

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  IHangar18.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Orbiters
import {IDenebOrbiter} from "./IDenebOrbiter.sol";
import {IAlbireoOrbiter} from "./IAlbireoOrbiter.sol";
import {ICygnusNebulaRegistry} from "./ICygnusNebulaRegistry.sol";

// Oracles

/**
 *  @title The interface for the Cygnus Factory
 *  @notice The Cygnus factory facilitates creation of collateral and borrow pools
 */
interface IHangar18 {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when caller is not Admin
     *
     *  @param sender The address of the account that invoked the function and caused the error
     *  @param admin The address of the Admin that is allowed to perform the function
     *
     *  @custom:error CygnusAdminOnly
     */
    error Hangar18__CygnusAdminOnly(address sender, address admin);

    /**
     *  @dev Reverts when the orbiter pair already exists
     *
     *  @custom:error OrbitersAlreadySet
     */
    error Hangar18__OrbitersAlreadySet();

    /**
     *  @dev Reverts when trying to deploy a shuttle that already exists
     *
     *  @custom:error ShuttleAlreadyDeployed
     */
    error Hangar18__ShuttleAlreadyDeployed();

    /**
     *  @dev Reverts when deploying a shuttle with orbiters that are inactive or dont exist
     *
     *  @custom:error OrbitersAreInactive
     */
    error Hangar18__OrbitersAreInactive();

    /**
     *  @dev Reverts when predicted collateral address doesn't match with deployed
     *
     *  @custom:error CollateralAddressMismatch
     */
    error Hangar18__CollateralAddressMismatch();

    /**
     *  @dev Reverts when trying to deploy a shuttle with an unsupported LP Pair
     *
     *  @custom:error LiquidityTokenNotSupported
     */
    error Hangar18__LiquidityTokenNotSupported();

    /**
     *  @dev Reverts when the CYG rewarder contract is zero
     *
     *  @custom:error PillarsCantBeZero
     */
    error Hangar18__PillarsCantBeZero();

    /**
     *  @dev Reverts when the CYG rewarder contract is zero
     *
     *  @custom:error PillarsCantBeZero
     */
    error Hangar18__AltairCantBeZero();

    /**
     *  @dev Reverts when the oracle set is the same as the new one we are assigning
     *
     *  @param priceOracle The address of the existing price oracle
     *  @param newPriceOracle The address of the new price oracle that was attempted to be set
     *
     *  @custom:error CygnusNebulaAlreadySet
     */
    error Hangar18__CygnusNebulaAlreadySet(address priceOracle, address newPriceOracle);

    /**
     *  @dev Reverts when the admin is the same as the new one we are assigning
     *
     *  @custom:error AdminAlreadySet
     */
    error Hangar18__AdminAlreadySet();

    /**
     *  @dev Reverts when the pending admin is the same as the new one we are assigning
     *
     *  @param newPendingAdmin The address of the new pending admin
     *  @param pendingAdmin The address of the existing pending admin
     *
     *  @custom:error PendingAdminAlreadySet
     */
    error Hangar18__PendingAdminAlreadySet(address newPendingAdmin, address pendingAdmin);

    /**
     *  @dev Reverts when the pending dao reserves is already the dao reserves
     *
     *  @custom:error DaoReservesAlreadySet
     */
    error Hangar18__DaoReservesAlreadySet();

    /**
     *  @dev Reverts when the pending address is the same as the new pending
     *
     *  @custom:error PendingDaoReservesAlreadySet
     */
    error Hangar18__PendingDaoReservesAlreadySet();

    /**
     *  @dev Reverts when msg.sender is not the pending admin
     *
     *  @custom:error SenderNotPendingAdmin
     */
    error Hangar18__SenderNotPendingAdmin();

    /**
     *  @dev Reverts when pending reserves contract address is the zero address
     *
     *  @custom:error DaoReservesCantBeZero
     */
    error Hangar18__DaoReservesCantBeZero();

    /**
     *  @dev Reverts when setting a new vault as the 0 address
     *
     *  @custom:error X1VaultCantBeZero
     */
    error Hangar18__X1VaultCantBeZero();

    /**
     *  @dev Reverts when deploying a pool with an inactive orbiter
     *
     *  @custom:error OrbiterInactive
     */
    error Hangar18__OrbiterInactive();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when a new lending pool is launched
     *
     *  @param lpTokenPair The address of the LP Token pair
     *  @param orbiterId The ID of the orbiter used to deploy this lending pool
     *  @param borrowable The address of the Cygnus borrow contract
     *  @param collateral The address of the Cygnus collateral contract
     *  @param shuttleId The ID of the lending pool
     *
     *  @custom:event NewShuttle
     */
    event NewShuttle(address indexed lpTokenPair, uint256 indexed shuttleId, uint256 orbiterId, address borrowable, address collateral);

    /**
     *  @dev Logs when a new Cygnus admin is requested
     *
     *  @param pendingAdmin Address of the requested admin
     *  @param _admin Address of the present admin
     *
     *  @custom:event NewPendingCygnusAdmin
     */
    event NewPendingCygnusAdmin(address pendingAdmin, address _admin);

    /**
     *  @dev Logs when a new Cygnus admin is confirmed
     *
     *  @param oldAdmin Address of the old admin
     *  @param newAdmin Address of the new confirmed admin
     *
     *  @custom:event NewCygnusAdmin
     */
    event NewCygnusAdmin(address oldAdmin, address newAdmin);

    /**
     *  @dev Logs when a new implementation contract is requested
     *
     *  @param oldPendingdaoReservesContract Address of the current `daoReserves` contract
     *  @param newPendingdaoReservesContract Address of the requested new `daoReserves` contract
     *
     *  @custom:event NewPendingDaoReserves
     */
    event NewPendingDaoReserves(address oldPendingdaoReservesContract, address newPendingdaoReservesContract);

    /**
     *  @dev Logs when a new implementation contract is confirmed
     *
     *  @param oldDaoReserves Address of old `daoReserves` contract
     *  @param daoReserves Address of the new confirmed `daoReserves` contract
     *
     *  @custom:event NewDaoReserves
     */
    event NewDaoReserves(address oldDaoReserves, address daoReserves);

    /**
     *  @dev Logs when a new pillars is confirmed
     *
     *  @param oldPillars Address of old `pillars` contract
     *  @param newPillars Address of the new pillars contract
     *
     *  @custom:event NewPillarsOfCreation
     */
    event NewPillarsOfCreation(address oldPillars, address newPillars);

    /**
     *  @dev Logs when a new router is confirmed
     *
     *  @param oldRouter Address of the old base router contract
     *  @param newRouter Address of the new router contract
     *
     *  @custom:event NewAltairRouter
     */
    event NewAltairRouter(address oldRouter, address newRouter);

    /**
     *  @dev Logs when orbiters are initialized in the factory
     *
     *  @param status Whether or not these orbiters are active and usable
     *  @param orbitersLength How many orbiter pairs we have (equals the amount of Dexes cygnus is using)
     *  @param borrowOrbiter The address of the borrow orbiter for this dex
     *  @param denebOrbiter The address of the collateral orbiter for this dex
     *  @param orbitersName The name of the dex for these orbiters
     *  @param uniqueHash The keccack256 hash of the collateral init code hash and borrowable init code hash
     *
     *  @custom:event InitializeOrbiters
     */
    event InitializeOrbiters(
        bool status,
        uint256 orbitersLength,
        IAlbireoOrbiter borrowOrbiter,
        IDenebOrbiter denebOrbiter,
        bytes32 uniqueHash,
        string orbitersName
    );

    /**
     *  @dev Logs when admins switch orbiters off for future deployments
     *
     *  @param status Bool representing whether or not these orbiters are usable
     *  @param orbiterId The ID of the collateral & borrow orbiters
     *  @param albireoOrbiter The address of the deleted borrow orbiter
     *  @param denebOrbiter The address of the deleted collateral orbiter
     *  @param orbiterName The name of the dex these orbiters were for
     *
     *  @custom:event SwitchOrbiterStatus
     */
    event SwitchOrbiterStatus(
        bool status,
        uint256 orbiterId,
        IAlbireoOrbiter albireoOrbiter,
        IDenebOrbiter denebOrbiter,
        string orbiterName
    );

    /**
     *  @dev Logs when a new vault is set which accumulates rewards from lending pools
     *
     *  @param oldVault The address of the old vault
     *  @param newVault The address of the new vault
     *
     *  @custom:event NewX1Vault
     */
    event NewX1Vault(address oldVault, address newVault);

    /**
     *  @dev Logs when an owner allows or disallows spender to borrow on their behalf
     *
     *  @param owner The address of msg.sender (owner of the CygLP)
     *  @param spender The address of the user the owner is allowing/disallowing
     *  @param status Whether or not the spender can borrow after this transaction
     *
     *  @custom:event NewMasterBorrowApproval
     */
    event NewMasterBorrowApproval(address owner, address spender, bool status);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     * @custom:struct Official record of all collateral and borrow deployer contracts, unique per dex
     * @custom:member status Whether or not these orbiters are active and usable
     * @custom:member orbiterId The ID for this pair of orbiters
     * @custom:member albireoOrbiter The address of the borrow deployer contract
     * @custom:member denebOrbiter The address of the collateral deployer contract
     * @custom:member borrowableInitCodeHash The hash of the borrowable contract's initialization code
     * @custom:member collateralInitCodeHash The hash of the collateral contract's initialization code
     * @custom:member uniqueHash The unique hash of the orbiter
     * @custom:member orbiterName Huamn friendly name for the orbiters
     */
    struct Orbiter {
        bool status;
        uint88 orbiterId;
        IAlbireoOrbiter albireoOrbiter;
        IDenebOrbiter denebOrbiter;
        bytes32 borrowableInitCodeHash;
        bytes32 collateralInitCodeHash;
        bytes32 uniqueHash;
        string orbiterName;
    }

    /**
     *  @custom:struct Shuttle Official record of pools deployed by this factory
     *  @custom:member launched Whether or not the lending pool is initialized
     *  @custom:member shuttleId The ID of the lending pool
     *  @custom:member borrowable The address of the borrowing contract
     *  @custom:member collateral The address of the Cygnus collateral
     *  @custom:member orbiterId The ID of the orbiters used to deploy lending pool
     */
    struct Shuttle {
        bool launched;
        uint88 shuttleId;
        address borrowable;
        address collateral;
        uint96 orbiterId;
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Array of structs containing all orbiters deployed
     *  @param _orbiterId The ID of the orbiter pair
     *  @return status Whether or not these orbiters are active and usable
     *  @return orbiterId The ID for these orbiters (ideally should be 1 per dex)
     *  @return albireoOrbiter The address of the borrow deployer contract
     *  @return denebOrbiter The address of the collateral deployer contract
     *  @return borrowableInitCodeHash The init code hash of the borrowable
     *  @return collateralInitCodeHash The init code hash of the collateral
     *  @return uniqueHash The keccak256 hash of collateralInitCodeHash and borrowableInitCodeHash
     *  @return orbiterName The name of the dex
     */
    function allOrbiters(
        uint256 _orbiterId
    )
        external
        view
        returns (
            bool status,
            uint88 orbiterId,
            IAlbireoOrbiter albireoOrbiter,
            IDenebOrbiter denebOrbiter,
            bytes32 borrowableInitCodeHash,
            bytes32 collateralInitCodeHash,
            bytes32 uniqueHash,
            string memory orbiterName
        );

    /**
     *  @notice Array of LP Token pairs deployed
     *  @param _shuttleId The ID of the shuttle deployed
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return borrowable The address of the borrow contract
     *  @return collateral The address of the collateral contract
     *  @return orbiterId The ID of the orbiters used to deploy this lending pool
     */
    function allShuttles(
        uint256 _shuttleId
    ) external view returns (bool launched, uint88 shuttleId, address borrowable, address collateral, uint96 orbiterId);

    /**
     *  @notice Checks if a pair of orbiters has been added to the Hangar
     *  @param orbiterHash The keccak hash of the creation code of each orbiter
     *  @return Whether this par of orbiters has been added or not
     */
    function orbitersExist(bytes32 orbiterHash) external view returns (bool);

    /**
     *  @notice Official record of all lending pools deployed
     *  @param _lpTokenPair The address of the LP Token
     *  @param _orbiterId The ID of the orbiter for this LP Token
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return borrowable The address of the borrow contract
     *  @return collateral The address of the collateral contract
     *  @return orbiterId The ID of the orbiters used to deploy this lending pool
     */
    function getShuttles(
        address _lpTokenPair,
        uint256 _orbiterId
    ) external view returns (bool launched, uint88 shuttleId, address borrowable, address collateral, uint96 orbiterId);

    /**
     *  @return Human friendly name for this contract
     */
    function name() external view returns (string memory);

    /**
     *  @return The version of this contract
     */
    function version() external view returns (string memory);

    /**
     *  @return usd The address of the borrowable token (stablecoin)
     */
    function usd() external view returns (address);

    /**
     *  @return nativeToken The address of the chain's native token
     */
    function nativeToken() external view returns (address);

    /**
     *  @notice The address of the nebula registry on this chain
     */
    function nebulaRegistry() external view returns (ICygnusNebulaRegistry);

    /**
     *  @return admin The address of the Cygnus Admin which grants special permissions in collateral/borrow contracts
     */
    function admin() external view returns (address);

    /**
     *  @return pendingAdmin The address of the requested account to be the new Cygnus Admin
     */
    function pendingAdmin() external view returns (address);

    /**
     *  @return daoReserves The address that handles Cygnus reserves from all pools
     */
    function daoReserves() external view returns (address);

    /**
     *  @dev Returns the address of the CygnusDAO revenue vault.
     *  @return cygnusX1Vault The address of the CygnusDAO revenue vault.
     */
    function cygnusX1Vault() external view returns (address);

    /**
     *  @dev Returns the address of the CygnusDAO base router.
     *  @return cygnusAltair Latest address of the base router on this chain.
     */
    function cygnusAltair() external view returns (address);

    /**
     *  @dev Returns the address of the CYG rewarder
     *  @return cygnusPillars The address of the CYG rewarder on this chain
     */
    function cygnusPillars() external view returns (address);

    /**
     * @dev Returns the total number of orbiter pairs deployed (1 collateral + 1 borrow = 1 orbiter).
     * @return orbitersDeployed The total number of orbiter pairs deployed.
     */
    function orbitersDeployed() external view returns (uint256);

    /**
     *  @dev Returns the total number of shuttles deployed.
     *  @return shuttlesDeployed The total number of shuttles deployed.
     */
    function shuttlesDeployed() external view returns (uint256);

    /**
     *  @dev Returns the chain ID
     */
    function chainId() external view returns (uint256);

    /**
     *  @dev Returns the borrowable TVL (Total Value Locked) in USD for a specific shuttle.
     *  @param shuttleId The ID of the shuttle for which the borrowable TVL is requested.
     *  @return The borrowable TVL in USD for the specified shuttle.
     */
    function borrowableTvlUsd(uint256 shuttleId) external view returns (uint256);

    /**
     *  @dev Returns the collateral TVL (Total Value Locked) in USD for a specific shuttle.
     *  @param shuttleId The ID of the shuttle for which the collateral TVL is requested.
     *  @return The collateral TVL in USD for the specified shuttle.
     */
    function collateralTvlUsd(uint256 shuttleId) external view returns (uint256);

    /**
     *  @dev Returns the total TVL (Total Value Locked) in USD for a specific shuttle.
     *  @param shuttleId The ID of the shuttle for which the total TVL is requested.
     *  @return The total TVL in USD for the specified shuttle.
     */
    function shuttleTvlUsd(uint256 shuttleId) external view returns (uint256);

    /**
     *  @dev Returns the total borrowable TVL in USD for all shuttles.
     *  @return The total borrowable TVL in USD.
     */
    function allBorrowablesTvlUsd() external view returns (uint256);

    /**
     *  @dev Returns the total collateral TVL in USD for all shuttles.
     *  @return The total collateral TVL in USD.
     */
    function allCollateralsTvlUsd() external view returns (uint256);

    /**
     *  @dev Returns the USD value of the DAO Cyg USD reserves.
     *  @return The USD value of the DAO Cyg USD reserves.
     */
    function daoCygUsdReservesUsd() external view returns (uint256);

    /**
     *  @dev Returns the USD value of the DAO Cyg LP reserves.
     *  @return The USD value of the DAO Cyg LP reserves.
     */
    function daoCygLPReservesUsd() external view returns (uint256);

    /**
     *  @dev Returns the total USD value of CygnusDAO reserves.
     *  @return The total USD value of CygnusDAO reserves.
     */
    function cygnusTotalReservesUsd() external view returns (uint256);

    /**
     *  @dev Returns the total TVL in USD for CygnusDAO.
     *  @return The total TVL in USD for CygnusDAO.
     */
    function cygnusTvlUsd() external view returns (uint256);

    /**
     *  @dev Returns the total amount borrowed for all shuttles
     *  @return The total amount borrowed in USD.
     */
    function cygnusTotalBorrows() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Admin 👽
     *  @notice Turns off orbiters making them not able for deployment of pools
     *
     *  @param orbiterId The ID of the orbiter pairs we want to switch the status of
     *
     *  @custom:security only-admin
     */
    function switchOrbiterStatus(uint256 orbiterId) external;

    /**
     *  @notice Admin 👽
     *  @notice Initializes both Borrow arms and the collateral arm
     *
     *  @param lpTokenPair The address of the underlying LP Token this pool is for
     *  @param orbiterId The ID of the orbiters we want to deploy to (= dex Id)
     *  @return borrowable The address of the Cygnus borrow contract for this pool
     *  @return collateral The address of the Cygnus collateral contract for both borrow tokens
     *
     *  @custom:security non-reentrant only-admin 👽
     */
    function deployShuttle(address lpTokenPair, uint256 orbiterId) external returns (address borrowable, address collateral);

    /**
     *  @notice Admin 👽
     *  @notice Sets the new orbiters to deploy collateral and borrow contracts and stores orbiters in storage
     *
     *  @param name The name of the strategy OR the dex these orbiters are for
     *  @param albireoOrbiter the address of this orbiter's borrow deployer
     *  @param denebOrbiter The address of this orbiter's collateral deployer
     *
     *  @custom:security non-reentrant only-admin
     */
    function initializeOrbiter(string memory name, IAlbireoOrbiter albireoOrbiter, IDenebOrbiter denebOrbiter) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets a new pending admin for Cygnus
     *
     *  @param newCygnusAdmin Address of the requested Cygnus admin
     *
     *  @custom:security only-admin
     */
    function setPendingAdmin(address newCygnusAdmin) external;

    /**
     *  @notice Approves the pending admin and is the new Cygnus admin
     *
     *  @custom:security only-pending-admin
     */
    function acceptCygnusAdmin() external;

    /**
     *  @notice Admin 👽
     *  @notice Accepts the new implementation contract
     *
     *  @param newReserves The address of the new DAO reserves
     *
     *  @custom:security only-admin
     */
    function setDaoReserves(address newReserves) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the address of the new x1 vault which accumulates rewards over time
     *
     *  @custom:security only-admin
     */
    function setCygnusX1Vault(address newX1Vault) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the address of the new pillars of creation
     *
     *  @custom:security only-admin
     */
    function setCygnusPillars(address newPillars) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the address of the new base router
     *
     *  @custom:security only-admin
     */
    function setCygnusAltair(address newAltair) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusAltair.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Interfaces
import {IERC20} from "./core/IERC20.sol";
import {IHangar18} from "./core/IHangar18.sol";
import {IWrappedNative} from "./IWrappedNative.sol";
import {ICygnusBorrow} from "./core/ICygnusBorrow.sol";

// Permit2
import {IAllowanceTransfer} from "./core/IAllowanceTransfer.sol";
import {ISignatureTransfer} from "./core/ISignatureTransfer.sol";

/**
 *  @notice Interface to interact with Cygnus' router contract
 */
interface ICygnusAltair {
    /**
     *  @notice Enum for choosing dex aggregators to perform leverage, deleverage and flash liquidations
     *  @custom:member PARASWAP Uses Paraswap
     *  @custom:member ONE_INCH Uses 1inch with the legacy `swap` mmethod
     *  @custom:member ONE_INCH Uses 1inch with optimized routers
     *  @custom:member OxPROJECT Uses 0xProjects swap API
     *  @custom:member OPEN_OCEAN_V1 Uses OpenOcean  with the legacy `swap` method
     *  @custom:member OPEN_OCEAN_V2 Uses OpenOcean with `uniswapV3SwapTo` method
     *  @custom:member OKX Uses OKX aggregation router
     *  @custom:member UNISWAP_V3_EMERGENCY Uses Uniswapv3 to perform the swap, should only be used under emergency scenarios
     *                 in case that aggregators stop working all of a sudden and users cannot deleverage.
     */
    enum DexAggregator {
        PARASWAP,
        ONE_INCH_LEGACY,
        ONE_INCH_V2,
        OxPROJECT,
        OPEN_OCEAN_LEGACY,
        OPEN_OCEAN_V2,
        OKX,
        UNISWAP_V3_EMERGENCY
    }

    /**
     *  @custom:struct AltairLeverageCalldata Encoded bytes passed to Cygnus Borrow contract for leverage
     *  @custom:member lpTokenPair The address of the LP Token
     *  @custom:member collateral The address of the Cygnus collateral contract
     *  @custom:member borrowable The address of the Cygnus borrow contract
     *  @custom:member recipient The address of the user receiving the leveraged LP Tokens
     *  @custom:member lpAmountMin The minimum amount of LP Tokens to receive
     *  @custom:member dexAggregator The ID of the aggregator used according to the `DexAggregator` enum
     *  @custom:member swapdata Byte array of the swapdata
     *
     */
    struct AltairLeverageCalldata {
        address lpTokenPair;
        address collateral;
        address borrowable;
        address recipient;
        uint256 lpAmountMin;
        DexAggregator dexAggregator;
        bytes[] swapdata;
    }

    /**
     *  @custom:struct AltairDeleverageCalldata Encoded bytes passed to Cygnus Collateral contract for de-leverage
     *  @custom:member lpTokenPair The address of the LP Token
     *  @custom:member collateral The address of the collateral contract
     *  @custom:member borrowable The address of the borrow contract
     *  @custom:member recipient The address of the user receiving the de-leveraged assets
     *  @custom:member redeemTokens The amount of CygLP to redeem
     *  @custom:member usdAmountMin The minimum amount of USD to receive by redeeming `redeemTokens`
     *  @custom:member swapdata The 1inch swap data byte array to convert Liquidity Tokens to USD
     */
    struct AltairDeleverageCalldata {
        address lpTokenPair;
        address collateral;
        address borrowable;
        address recipient;
        uint256 redeemTokens;
        uint256 usdAmountMin;
        DexAggregator dexAggregator;
        bytes[] swapdata;
    }

    /**
     *  @custom:struct AltairLiquidateCalldata Encoded bytes passed to Cygnus Borrow contract for liquidating borrows
     *  @custom:member lpTokenPair The address of the LP Token
     *  @custom:member collateral The address of the collateral contract
     *  @custom:member borrowable The address of the borrow contract
     *  @custom:member recipient The address of the liquidator (or this contract if protocol liquidation)
     *  @custom:member borrower The address of the borrower being liquidated
     *  @custom:member repayAmount The USD amount being repaid by the liquidator
     *  @custom:member swapdata The 1inch swap data byte array to convert Liquidity Tokens to USD after burning
     */
    struct AltairLiquidateCalldata {
        address lpTokenPair;
        address collateral;
        address borrowable;
        address recipient;
        address borrower;
        uint256 repayAmount;
        DexAggregator dexAggregator;
        bytes[] swapdata;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when the current block.timestamp is past deadline
     *
     *  @custom:error TransactionExpired
     */
    error CygnusAltair__TransactionExpired();

    /**
     *  @dev Reverts when the msg sender is not the cygnus factory admin
     *
     *  @custom:error MsgSenderNotAdmin
     */
    error CygnusAltair__MsgSenderNotAdmin();

    /**
     *  @dev Reverts when the paraswap transaction fails
     *
     *  @custom:error ParaswapTransactionFailed
     */
    error CygnusAltair__ParaswapTransactionFailed();

    /**
     *  @dev Reverts when the 1inch transaction fails
     *
     *  @custom:error OneInchTransactionFailed
     */
    error CygnusAltair__OneInchTransactionFailed();

    /**
     *  @dev Reverts when the 0x swap api transaction fails
     *
     *  @custom:error 0xProjectTransactionFailed
     */
    error CygnusAltair__0xProjectTransactionFailed();

    /**
     *  @dev Reverts when the OpenOcean transaction fails
     *
     *  @custom:error OpenOceanTransactionFailed
     */
    error CygnusAltair__OpenOceanTransactionFailed();

    /**
     *  @dev Reverts if an extension has not been set for the borrowable or collateral
     *
     *  @custom:error AltairXDoesNotExist
     */
    error CygnusAltair__AltairXDoesNotExist();

    /**
     *  @dev Reverts if the shuttle does not exist when initializing an extension for it
     *
     *  @custom:erro ShuttleDoesNotExist
     */
    error CygnusAltair__ShuttleDoesNotExist();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when admin sets a new extension
     *
     *  @param shuttleId Indexed shuttle ID
     *  @param borrowable Address of the borrowable
     *  @param collateral Address of the collateral
     *  @param lpTokenAddres Address of the lp token
     *  @param extension Address of the new extension
     *
     *  @custom:event NewExtension
     */
    event NewExtension(uint256 indexed shuttleId, address borrowable, address collateral, address lpTokenAddres, address extension);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @return name The human readable name this router is for
     */
    function name() external view returns (string memory);

    /**
     *  @return version The version of the router
     */
    function version() external view returns (string memory);

    /**
     *  @return hangar18 The address of the Cygnus factory contract V1 - Used to get the nativeToken and USD address
     */
    function hangar18() external view returns (IHangar18);

    /**
     *  @return PERMIT Uniswap's Permit2 router
     */
    function PERMIT2() external view returns (address);

    /**
     *  @return PARASWAP_AUGUSTUS_SWAPPER_V5 The address of the Paraswap router used to perform the swaps
     */
    function PARASWAP_AUGUSTUS_SWAPPER_V5() external pure returns (address);

    /**
     *  @return ONE_INCH_ROUTER_V5 The address of the 1Inch router used to perform the swaps
     */
    function ONE_INCH_ROUTER_V5() external pure returns (address);

    /**
     *  @return OxPROJECT_EXCHANGE_PROXY The address of 0x's exchange proxy
     */
    function OxPROJECT_EXCHANGE_PROXY() external pure returns (address);

    /**
     *  @return OPEN_OCEAN_EXCHANGE_PROXY The address of OpenOcean's exchange router
     */
    function OPEN_OCEAN_EXCHANGE_PROXY() external pure returns (address);

    /**
     *  @return OKX_AGGREGATION_ROUTER The address of OKX's Aggregation Router on this chain
     */
    function OKX_AGGREGATION_ROUTER() external pure returns (address);

    /**
     *  @return UNISWAP_V3_ROUTER The address of UniswapV3's swap router
     */
    function UNISWAP_V3_ROUTER() external pure returns (address);

    /**
     *  @return usd The address of USD on this chain, used for the leverage/deleverage swaps
     */
    function usd() external view returns (address);

    /**
     *  @return nativeToken The address of the native token on this chain (ie. WETH)
     */
    function nativeToken() external view returns (IWrappedNative);

    /**
     *  @notice Array of all initialized extensions
     */
    function allExtensions(uint256 index) external view returns (address);

    /**
     *  @notice Returns the altair extension for a borrowable or collateral contract
     *  @param poolToken The address of a Cygnus borrowable or collateral or an lp token pair
     *  @return The address of the extension
     */
    function getAltairExtension(address poolToken) external view returns (address);

    /**
     *  @notice Returns the altair extension for a shuttle id
     *  @param shuttleId The ID of the lending pool
     *  @return The address of the extension
     */
    function getShuttleExtension(uint256 shuttleId) external view returns (address);

    /**
     *  @return altairExtensionsLength How many extensions we have added to the router so far
     */
    function altairExtensionsLength() external view returns (uint256);

    /**
     *  @dev Returns the assets and amounts received by redeeming a given amount of underlying liquidity tokens.
     *  @param underlying The address of the underlying liquidity token (e.g., LP token or Balancer BPT).
     *  @param shares The amount of underlying liquidity tokens to redeem.
     *  @return tokens An array of addresses representing the received tokens.
     *  @return amounts An array of corresponding amounts received by redeeming the liquidity tokens.
     */
    function getAssetsForShares(
        address underlying,
        uint256 shares,
        uint256 slippage
    ) external view returns (address[] memory tokens, uint256[] memory amounts);

    /**
     *  @dev Returns whether an extension is set or not
     *  @param extension The addres of CygnusAltairX
     */
    function isExtension(address extension) external returns (bool);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Main function used in Cygnus to liquidate borrows
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The maximum amount to liquidate
     *  @param borrower The address of the borrower
     *  @param recipient The address of the recipient
     *  @param deadline The time by which the transaction must be included to effect the change
     */
    function liquidate(
        address borrowable,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline,
        bytes calldata permitData
    ) external returns (uint256 amount, uint256 seizeTokens);

    /**
     *  @notice Main function used in Cygnus to liquidate borrows
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The maximum amount to liquidate
     *  @param borrower The address of the borrower
     *  @param recipient The address of the recipient
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param _permit Data signed over by the owner specifying the terms of approval
     *  @param signature The owner's signature over the permit data
     *  @return amount The amount of stablecoins repaid
     *  @return seizeTokens The amount of CygLP seized
     */
    function liquidatePermit2Allowance(
        address borrowable,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline,
        IAllowanceTransfer.PermitSingle calldata _permit,
        bytes calldata signature
    ) external returns (uint256 amount, uint256 seizeTokens);

    /**
     *  @notice Main function used in Cygnus to liquidate borrows
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The maximum amount to liquidate
     *  @param borrower The address of the borrower
     *  @param recipient The address of the recipient
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param _permit Data signed over by the owner specifying the terms of approval
     *  @param signature The owner's signature over the permit data
     *  @return amount The amount of stablecoins repaid
     *  @return seizeTokens The amount of CygLP seized
     */
    function liquidatePermit2Signature(
        address borrowable,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline,
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata signature
    ) external returns (uint256 amount, uint256 seizeTokens);

    /**
     *  @notice Main function used in Cygnus to borrow USD
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amount Amount of USD to borrow
     *  @param recipient The address of the borrower
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param permitData Permit data for pool token
     */
    function borrow(address borrowable, uint256 amount, address recipient, uint256 deadline, bytes calldata permitData) external;

    /**
     *  @notice Main function used in Cygnus to repay borrows
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The max amount to repay
     *  @param borrower Thea ddress of the borrower
     *  @param deadline The time by which the transaction must be included to effect the change
     */
    function repay(
        address borrowable,
        uint256 amountMax,
        address borrower,
        uint256 deadline,
        bytes calldata permitData
    ) external returns (uint256 amount);

    /**
     *  @notice Main function used in Cygnus to repay borrow using Permit2 Signature Transfer
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The max amount to repay
     *  @param borrower Thea ddress of the borrower
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param _permit Data signed over by the owner specifying the terms of approval
     *  @param signature The owner's signature over the permit data
     */
    function repayPermit2Allowance(
        address borrowable,
        uint256 amountMax,
        address borrower,
        uint256 deadline,
        IAllowanceTransfer.PermitSingle calldata _permit,
        bytes calldata signature
    ) external returns (uint256);

    /**
     *  @notice Main function used in Cygnus to repay borrow using Permit2 Signature Transfer
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The max amount to repay
     *  @param borrower Thea ddress of the borrower
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param _permit Data signed over by the owner specifying the terms of approval
     *  @param signature The owner's signature over the permit data
     */
    function repayPermit2Signature(
        address borrowable,
        uint256 amountMax,
        address borrower,
        uint256 deadline,
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata signature
    ) external returns (uint256);

    /**
     *  @notice Main function to flash liquidate borrows. Ie, liquidating a user without needing to have USD
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The maximum amount to liquidate
     *  @param borrower The address of the borrower
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param dexAggregator The dex used to sell the collateral (0 for Paraswap, 1 for 1inch)
     *  @param swapdata Calldata to swap
     */
    function flashLiquidate(
        address borrowable,
        address collateral,
        uint256 amountMax,
        address borrower,
        uint256 deadline,
        DexAggregator dexAggregator,
        bytes[] calldata swapdata
    ) external returns (uint256 amount);

    /**
     *  @notice Main leverage function
     *  @param lpTokenPair The address of the LP Token
     *  @param collateral The address of the collateral of the lending pool
     *  @param borrowable The address of the borrowable of the lending pool
     *  @param usdAmount The amount to leverage
     *  @param lpAmountMin The minimum amount of LP Tokens to receive
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param permitData Permit data for borrowable leverage
     *  @param dexAggregator The dex used to sell the collateral (0 for Paraswap, 1 for 1inch)
     *  @param swapdata the 1inch swap data to convert USD to liquidity
     */
    function leverage(
        address lpTokenPair,
        address collateral,
        address borrowable,
        uint256 usdAmount,
        uint256 lpAmountMin,
        uint256 deadline,
        bytes calldata permitData,
        DexAggregator dexAggregator,
        bytes[] calldata swapdata
    ) external returns (uint256);

    /**
     *  @notice Main deleverage function
     *  @param lpTokenPair The address of the LP Token
     *  @param collateral The address of the collateral of the lending pool
     *  @param borrowable The address of the borrowable of the lending pool
     *  @param cygLPAmount The amount to CygLP to deleverage
     *  @param usdAmountMin The minimum amount of USD to receive
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param permitData Permit data for collateral deleverage
     *  @param dexAggregator The dex used to sell the collateral (0 for Paraswap, 1 for 1inch)
     *  @param swapdata the 1inch swap data to convert liquidity to USD
     */
    function deleverage(
        address lpTokenPair,
        address collateral,
        address borrowable,
        uint256 cygLPAmount,
        uint256 usdAmountMin,
        uint256 deadline,
        bytes calldata permitData,
        DexAggregator dexAggregator,
        bytes[] calldata swapdata
    ) external returns (uint256);

    //  Admin only  //

    /**
     *  @notice Initializes an extnesion of the router and maps it to a borrowable/collateral/lp token
     *  @param shuttleIds Array of shuttle IDs for the extension
     *  @param extension The address of the extension
     *  @custom:security only-admin
     */
    function setAltairExtension(uint256[] calldata shuttleIds, address extension) external;

    /**
     *  @notice Sweeps tokens that were sent here by mistake
     *  @param tokens Array of tokens to sweep
     *  @param to The receiver of the sweep
     *  @custom:security only-admin
     */
    function sweepTokens(IERC20[] memory tokens, address to) external;

    /**
     *  @notice Sweeps native
     *  @custom:security only-admin
     */
    function sweepNative() external;

    /**
     *  @notice Get the borrower`s full position
     *  @param borrowable The address of the borrowable contract
     *  @param borrower The address of the borrower
     *  @return cygLPBalance The user's balance of collateral (CygLP)
     *  @return principal The original loaned USDC amount (without interest)
     *  @return borrowBalance The original loaned USDC amount plus interest (ie. what the user must pay back)
     *  @return price The current liquidity token price
     *  @return rate The current exchange rate between CygLP and LP Token
     *  @return lpBalance The borrower`s position in LP Tokens
     *  @return positionUsd The borrower's position in USD. position = CygLP Balance * Exchange Rate * LP Token Price
     *  @return health The user's current loan health (once it reaches 100% the user becomes liquidatable)
     */
    function latestBorrowerPosition(
        ICygnusBorrow borrowable,
        address borrower
    )
        external
        returns (
            uint256 cygLPBalance,
            uint256 principal,
            uint256 borrowBalance,
            uint256 price,
            uint256 rate,
            uint256 lpBalance,
            uint256 positionUsd,
            uint256 health
        );

    /**
     *  @notice Get the lender`s full position
     *  @param borrowable The address of the borrowable contract
     *  @param lender The address of the lender
     *  @return cygUsdBalance The `lender's` balance of CygUSD
     *  @return rate The currente exchange rate
     *  @return usdBalance The lender's balance of the stablecoin
     *  @return positionUsd The lender's position in USD
     */
    function latestLenderPosition(
        ICygnusBorrow borrowable,
        address lender
    ) external returns (uint256 cygUsdBalance, uint256 rate, uint256 usdBalance, uint256 positionUsd);

    /**
     *  @notice Get the borrower's latest account liquidity
     *  @param borrowable The address of the borrowable contract
     *  @param borrower The address of the borrower
     *  @return liquidity The position's liquidity in stablecoins (if any)
     *  @return shortfall The position's shortfall in stablecoins (if any)
     */
    function latestAccountLiquidity(ICygnusBorrow borrowable, address borrower) external returns (uint256 liquidity, uint256 shortfall);

    /**
     *  @notice Get the whole lending pool info with latest interest rate accruals
     *  @param borrowable The address of the borrowable contract
     *  @return supplyApr The latest annualized return for lenders
     *  @return borrowApr The latest interest rate for borrowers
     *  @return util The latest utilization rate
     *  @return totalBorrows The latest total borrows
     *  @return totalBalance The latest available cash
     *  @return exchangeRate The latest exchange rate between USD and CygUSD
     */
    function latestShuttleInfo(
        ICygnusBorrow borrowable
    )
        external
        returns (uint256 supplyApr, uint256 borrowApr, uint256 util, uint256 totalBorrows, uint256 totalBalance, uint256 exchangeRate);

    /**
     *  @notice Get the borrower's TVL in Cygnus
     *  @param borrower The address of the borrower
     *  @return principal The original loaned USDC amount (without interest)
     *  @return borrowBalance The original loaned USDC amount plus interest (ie. what the user must pay back)
     *  @return positionUsd The borrower's position in USD. position = CygLP Balance * Exchange Rate * LP Token Price
     */
    function latestBorrowerAll(address borrower) external returns (uint256 principal, uint256 borrowBalance, uint256 positionUsd);

    /**
     *  @notice Get the lender's TVL in Cygnus
     *  @param lender The address of the lender
     *  @return cygUsdBalance The `lender's` balance of CygUSD
     *  @return usdBalance The lender`s stablecoin balance
     *  @return positionUsd The lender's position in USD
     */
    function latestLenderAll(address lender) external returns (uint256 cygUsdBalance, uint256 usdBalance, uint256 positionUsd);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusAltairX.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Interfaces
import {IERC20} from "./core/IERC20.sol";
import {IHangar18} from "./core/IHangar18.sol";
import {IWrappedNative} from "./IWrappedNative.sol";
import {ICygnusNebulaRegistry} from "./core/ICygnusNebulaRegistry.sol";

/**
 *  @notice Interface to interact with Cygnus' router contract
 */
interface ICygnusAltairX {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when the msg sender is not the collateral contract
     *
     *  @custom:error MsgSenderNotCollateral
     */
    error CygnusAltair__MsgSenderNotCollateral();

    /**
     *  @dev Reverts when the msg sender is not the router in the leverage function
     *
     *  @custom:error MsgSenderNotRouter
     */
    error CygnusAltair__MsgSenderNotRouter();

    /**
     *  @dev Reverts when the msg sender is not the cygnus factory admin
     *
     *  @custom:error MsgSenderNotAdmin
     */
    error CygnusAltair__MsgSenderNotAdmin();

    /**
     *  @dev Reverts when the msg sender is not the borrow contract
     *
     *  @custom:error MsgSenderNotBorrowable
     */
    error CygnusAltair__MsgSenderNotBorrowable();

    /**
     *  @dev Reverts when the paraswap transaction fails
     *
     *  @custom:error ParaswapTransactionFailed
     */
    error CygnusAltair__ParaswapTransactionFailed();

    /**
     *  @dev Reverts when the 1inch transaction fails
     *
     *  @custom:error OneInchTransactionFailed
     */
    error CygnusAltair__OneInchTransactionFailed();

    /**
     *  @dev Reverts when the 0x swap api transaction fails
     *
     *  @custom:error 0xProjectTransactionFailed
     */
    error CygnusAltair__0xProjectTransactionFailed();

    /**
     *  @dev Reverts when the Open Ocean swap transaction fails
     *
     *  @custom:error OpenOceanTransactionFailed
     */
    error CygnusAltair__OpenOceanTransactionFailed();

    /**
     *  @dev Reverts when USD amount received is less than minimum asked while liquidating
     *
     *  @custom:error InsufficientLiquidateUsd
     */
    error CygnusAltair__InsufficientLiquidateUsd();

    /**
     *  @dev Reverts when amount of USD received is less than the minimum asked
     *
     *  @custom:error InsufficientUSDAmount
     */
    error CygnusAltair__InsufficientUSDAmount();

    /**
     *  @dev Reverts when the swapped amount is less than the min requested
     *
     *  @custom:error InsufficientLPTokenAmount
     */
    error CygnusAltair__InsufficientLPTokenAmount();

    /**
     *  @dev Reverts if the call is not a delegate call
     *
     *  @custom:error OnlyDelegateCall
     */
    error CygnusAltair__OnlyDelegateCall();

    /**
     *  @dev Reverts when no pool is found for swapping tokens through the UniswapV3 router
     *
     *  @custom:error InvalidPoolFee
     */
    error CygnusAltair__InvalidPool();

    /**
     *
     */
    error CygnusAltair__InvalidAggregator();
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @return name The human readable name this router is for
     */
    function name() external view returns (string memory);

    /**
     *  @return version The version of the Extension contract
     */
    function version() external view returns (string memory);

    /**
     *  @return PERMIT Uniswap's Permit2 router
     */
    function PERMIT2() external view returns (address);

    /**
     *  @return PARASWAP_AUGUSTUS_SWAPPER_V5 The address of the Paraswap router used to perform the swaps
     */
    function PARASWAP_AUGUSTUS_SWAPPER_V5() external pure returns (address);

    /**
     *  @return ONE_INCH_ROUTER_V5 The address of the 1Inch router used to perform the swaps
     */
    function ONE_INCH_ROUTER_V5() external pure returns (address);

    /**
     *  @return OxPROJECT_EXCHANGE_PROXY The address of 0x's exchange proxy
     */
    function OxPROJECT_EXCHANGE_PROXY() external pure returns (address);

    /**
     *  @return OPEN_OCEAN_EXCHANGE_PROXY The address of OpenOcean's exchange router
     */
    function OPEN_OCEAN_EXCHANGE_PROXY() external pure returns (address);

    /**
     *  @return OKX_AGGREGATION_ROUTER The address of OKX's Aggregation Router on this chain
     */
    function OKX_AGGREGATION_ROUTER() external pure returns (address);

    /**
     *  @return UNISWAP_V3_ROUTER The address of UniswapV3's swap router
     */
    function UNISWAP_V3_ROUTER() external pure returns (address);

    /**
     *  @return hangar18 The address of the Cygnus factory contract V1 - Used to get the nativeToken and USD address
     */
    function hangar18() external view returns (IHangar18);

    /**
     *  @return usd The address of USD on this chain, used for the leverage/deleverage swaps
     */
    function usd() external view returns (address);

    /**
     *  @return nativeToken The address of the native token on this chain (ie. WETH)
     */
    function nativeToken() external view returns (IWrappedNative);

    /**
     *  @dev Returns the assets and amounts received by redeeming a given amount of underlying liquidity tokens.
     *  @param underlying The address of the underlying liquidity token (e.g., LP token or Balancer BPT).
     *  @param shares The amount of underlying liquidity tokens to redeem.
     *  @param difference Substract a difference from the estimated amount received to make sure router always has enough
     *                    from the actual amount received.
     *  @return tokens An array of addresses representing the received tokens.
     *  @return amounts An array of corresponding amounts received by redeeming the liquidity tokens.
     */
    function getAssetsForShares(
        address underlying,
        uint256 shares,
        uint256 difference
    ) external view returns (address[] memory tokens, uint256[] memory amounts);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Sweeps tokens that were sent here by mistake
     *  @param tokens Array of tokens to sweep
     *  @param to The receiver of the sweep
     *  @custom:security only-admin
     */
    function sweepTokens(IERC20[] memory tokens, address to) external;

    /**
     *  @notice Sweeps native
     *  @custom:security only-admin
     */
    function sweepNative() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

// Interface for interfacting with Wrapped Eth
interface IWrappedNative {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /// @dev The output is undefined, as the input is zero.
    error Log2Undefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    // Store the function selector of `ExpOverflow()`.
                    mstore(0x00, 0xa37bfec9)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    // Store the function selector of `LnWadUndefined()`.
                    mstore(0x00, 0x1615e638)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                let v := x
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, v))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, v))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, v))))

                // For the remaining 32 bits, use a De Bruijn lookup.
                // See: https://graphics.stanford.edu/~seander/bithacks.html
                v := shr(k, v)
                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))

                // forgefmt: disable-next-item
                k := sub(
                    or(k, byte(shr(251, mul(v, shl(224, 0x07c4acdd))), 0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f)),
                    96
                )
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates `floor(a * b / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {

            } 1 {

            } {
                // 512-bit multiply `[prod1 prod0] = x * y`.
                // Compute the product mod `2**256` and mod `2**256 - 1`
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that `product = prod1 * 2**256 + prod0`.

                // Least significant 256 bits of the product.
                let prod0 := mul(x, y)
                let mm := mulmod(x, y, not(0))
                // Most significant 256 bits of the product.
                let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(prod1) {
                    if iszero(d) {
                        // Store the function selector of `FullMulDivFailed()`.
                        mstore(0x00, 0xae47f702)
                        // Revert with (offset, size).
                        revert(0x1c, 0x04)
                    }
                    result := div(prod0, d)
                    break
                }

                // Make sure the result is less than `2**256`.
                // Also prevents `d == 0`.
                if iszero(gt(d, prod1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                ///////////////////////////////////////////////
                // 512 by 256 division.
                ///////////////////////////////////////////////

                // Make division exact by subtracting the remainder from `[prod1 prod0]`.
                // Compute remainder using mulmod.
                let remainder := mulmod(x, y, d)
                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
                // Factor powers of two out of `d`.
                // Compute largest power of two divisor of `d`.
                // Always greater or equal to 1.
                let twos := and(d, sub(0, d))
                // Divide d by power of two.
                d := div(d, twos)
                // Divide [prod1 prod0] by the factors of two.
                prod0 := div(prod0, twos)
                // Shift in bits from `prod1` into `prod0`. For this we need
                // to flip `twos` such that it is `2**256 / twos`.
                // If `twos` is zero, then it becomes one.
                prod0 := or(prod0, mul(prod1, add(div(sub(0, twos), twos), 1)))
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(mul(3, d), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                result := mul(prod0, mul(inv, sub(2, mul(d, inv)))) // inverse mod 2**256
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        result = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                if iszero(add(result, 1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
                result := add(result, 1)
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                // Store the function selector of `DivFailed()`.
                mstore(0x00, 0x65244e4e)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`.
            // We check `y >= 2**(k + 8)` but shift right by `k` bits
            // each branch to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {

            } 1 {

            } {
                if iszero(lt(10, x)) {
                    // forgefmt: disable-next-item
                    result := and(shr(mul(22, x), 0x375f0016260009d80004ec0002d00001e0000180000180000200000400001), 0x3fffff)
                    break
                }
                if iszero(lt(57, x)) {
                    let end := 31
                    result := 8222838654177922817725562880000000
                    if iszero(lt(end, x)) {
                        end := 10
                        result := 3628800
                    }
                    for {
                        let w := not(0)
                    } 1 {

                    } {
                        result := mul(result, x)
                        x := add(x, w)
                        if eq(x, end) {
                            break
                        }
                    }
                    break
                }
                // Store the function selector of `FactorialOverflow()`.
                mstore(0x00, 0xaba0f2a2)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                // Store the function selector of `Log2Undefined()`.
                mstore(0x00, 0x5be3aa5c)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            // forgefmt: disable-next-item
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))), 0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            uint256 isNotPo2;
            assembly {
                isNotPo2 := iszero(iszero(and(x, sub(x, 1))))
            }
            return log2(x) + isNotPo2;
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let a := sub(y, x)
            z := xor(a, mul(xor(a, sub(x, y)), sgt(x, y)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue) internal pure returns (uint256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {
                z := x
            } y {

            } {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RAW NUMBER OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // For better gas estimation.
                    if iszero(gt(gas(), 1000000)) {
                        revert(0, 0)
                    }
                }
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // For better gas estimation.
                    if iszero(gt(gas(), 1000000)) {
                        revert(0, 0)
                    }
                }
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x0c, 0x23b872dd000000000000000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x0c, 0x70a08231000000000000000000000000)
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            // The `amount` argument is already written to the memory word at 0x6c.
            amount := mload(0x60)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x14, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x34.
            amount := mload(0x34)
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`.
            mstore(0x00, 0x095ea7b3000000000000000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x00, 0x70a08231000000000000000000000000)
            amount := mul(
                mload(0x20),
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                )
            )
        }
    }
}