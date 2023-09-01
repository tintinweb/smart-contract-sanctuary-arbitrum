// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {ClonesWithImmutableArgs} from "src/lib/clones/ClonesWithImmutableArgs.sol";

import {IFixedStrikeOptionTeller, IOptionTeller} from "src/interfaces/IFixedStrikeOptionTeller.sol";
import {FixedStrikeOptionToken} from "src/fixed-strike/FixedStrikeOptionToken.sol";

import {TransferHelper} from "src/lib/TransferHelper.sol";
import {FullMath} from "src/lib/FullMath.sol";

/// @title Fixed Strike Option Teller
/// @notice Fixed Strike Option Teller Contract
/// @dev Option Teller contracts handle the deployment, creation, and exercise of option tokens.
///      Option Tokens are ERC20 tokens that represent the right to buy (call) or sell (put) a fixed
///      amount of an asset (payout token) for an amount of another asset (quote token) between two
///      timestamps (eligible and expiry). Option Tokens are denominated in units of the payout token
///      and are created at a 1:1 ratio for the amount of payout tokens to buy or sell.
///      The amount of quote tokens required to exercise (call) or collateralize (put) an option token
///      is called the strike price. Strike prices are denominated in units of the quote token.
///      The Fixed Strike Option Teller implementation creates option tokens that have a fixed strike
///      price that is set at the time of creation.
///
///      In order to create option tokens, an issuer must deploy the specific token configuration on
///      the teller, and then provide collateral to the teller to mint option tokens. The collateral is
///      required to guarantee that the option tokens can be exercised. The collateral required depends on
///      the option type. For call options, the collateral required is an amount of payout tokens equivalent
///      to the amount of option tokens being minted. For put options, the collateral required is an amount
///      of quote tokens equivalent to the amount of option tokens being minted multipled by the strike price.
///      As the name "option" suggests, the holder of an option token has the right, but not the obligation,
///      to exercise the option token within the eligible time window. If the option token is not exercised,
///      the designated "receiver" of the option token exercise proceeds can reclaim the collateral after
///      the expiry timestamp. If an option token is exercised, the holder receives the collateral and the
///      receiver receives the exercise proceeds.
///
/// @author Bond Protocol
contract FixedStrikeOptionTeller is IFixedStrikeOptionTeller, Auth, ReentrancyGuard {
    using TransferHelper for ERC20;
    using FullMath for uint256;
    using ClonesWithImmutableArgs for address;

    /* ========== ERRORS ========== */

    error Teller_NotAuthorized();
    error Teller_TokenDoesNotExist(bytes32 optionHash);
    error Teller_UnsupportedToken(address token);
    error Teller_InvalidParams(uint256 index, bytes value);
    error Teller_OptionExpired(uint48 expiry);
    error Teller_NotEligible(uint48 eligible);
    error Teller_NotExpired(uint48 expiry);
    error Teller_AlreadyReclaimed(FixedStrikeOptionToken optionToken);
    error Teller_PriceOutOfBounds();
    error Teller_InvalidAmount();

    /* ========== EVENTS ========== */
    event WroteOption(uint256 indexed id, address indexed referrer, uint256 amount, uint256 payout);
    event OptionTokenCreated(
        FixedStrikeOptionToken optionToken,
        ERC20 indexed payoutToken,
        ERC20 quoteToken,
        uint48 eligible,
        uint48 indexed expiry,
        address indexed receiver,
        bool call,
        uint256 strikePrice
    );

    /* ========== STATE VARIABLES ========== */

    /// @notice Fee paid to protocol when options are exercised in basis points (3 decimal places).
    uint48 public protocolFee;

    /// @notice Base value used to scale fees. 1e5 = 100%
    uint48 public constant FEE_DECIMALS = 1e5; // one percent equals 1000.

    /// @notice FixedStrikeOptionToken reference implementation (deployed on creation to clone from)
    FixedStrikeOptionToken public immutable optionTokenImplementation;

    /// @notice Minimum duration an option must be eligible to exercise (in seconds)
    uint48 public minOptionDuration;

    /// @notice Fees earned by protocol, by token
    mapping(ERC20 => uint256) public fees;

    /// @notice Fixed strike option tokens (hash of parameters to address)
    mapping(bytes32 => FixedStrikeOptionToken) public optionTokens;

    /// @notice Whether the receiver of an option token has reclaimed the collateral
    mapping(FixedStrikeOptionToken => bool) public collateralClaimed;

    /* ========== CONSTRUCTOR ========== */

    /// @param guardian_    Address of the guardian for Auth
    /// @param authority_   Address of the authority for Auth
    constructor(address guardian_, Authority authority_) Auth(guardian_, authority_) {
        // Explicitly setting protocol fee to zero initially
        protocolFee = 0;

        // Set minimum option duration initially to 1 day (the absolute minimum given timestamp rounding)
        minOptionDuration = uint48(1 days);

        // Deploy option token implementation that clones proxy to
        optionTokenImplementation = new FixedStrikeOptionToken();
    }

    /* ========== CREATE OPTION TOKENS ========== */

    /// @inheritdoc IFixedStrikeOptionTeller
    function deploy(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external override nonReentrant returns (FixedStrikeOptionToken) {
        // If eligible is zero, use current timestamp
        if (eligible_ == 0) eligible_ = uint48(block.timestamp);

        // Eligible and Expiry are rounded to the nearest day at 0000 UTC (in seconds) since
        // option tokens are only unique to a day, not a specific timestamp.
        eligible_ = uint48(eligible_ / 1 days) * 1 days;
        expiry_ = uint48(expiry_ / 1 days) * 1 days;

        // Revert if eligible is in the past, we do this to avoid duplicates tokens with the same parameters otherwise
        // Truncate block.timestamp to the nearest day for comparison
        if (eligible_ < uint48(block.timestamp / 1 days) * 1 days)
            revert Teller_InvalidParams(2, abi.encodePacked(eligible_));

        // Revert if the difference between eligible and expiry is less than min duration or eligible is after expiry
        // Don't need to check expiry against current timestamp since eligible is already checked
        if (eligible_ > expiry_ || expiry_ - eligible_ < minOptionDuration)
            revert Teller_InvalidParams(3, abi.encodePacked(expiry_));

        // Revert if any addresses are zero or the tokens are not contracts
        if (address(payoutToken_) == address(0) || address(payoutToken_).code.length == 0)
            revert Teller_InvalidParams(0, abi.encodePacked(payoutToken_));
        if (address(quoteToken_) == address(0) || address(quoteToken_).code.length == 0)
            revert Teller_InvalidParams(1, abi.encodePacked(quoteToken_));
        if (receiver_ == address(0)) revert Teller_InvalidParams(4, abi.encodePacked(receiver_));

        // Revert if strike price is zero or out of bounds
        uint8 quoteDecimals = quoteToken_.decimals();
        int8 priceDecimals = _getPriceDecimals(strikePrice_, quoteDecimals);
        // We check that the strike pirce is not zero and that the price decimals are not less than half the quote decimals to avoid precision loss
        // For 18 decimal tokens, this means relative prices as low as 1e-9 are supported
        if (strikePrice_ == 0 || priceDecimals < -int8(quoteDecimals / 2))
            revert Teller_InvalidParams(6, abi.encodePacked(strikePrice_));

        // Create option token if one doesn't already exist
        // Timestamps are truncated above to give canonical version of hash
        bytes32 optionHash = _getOptionTokenHash(
            payoutToken_,
            quoteToken_,
            eligible_,
            expiry_,
            receiver_,
            call_,
            strikePrice_
        );

        FixedStrikeOptionToken optionToken = optionTokens[optionHash];

        // If option token doesn't exist, deploy it
        if (address(optionToken) == address(0)) {
            optionToken = _deploy(
                payoutToken_,
                quoteToken_,
                eligible_,
                expiry_,
                receiver_,
                call_,
                strikePrice_
            );

            // Set the domain separator for the option token on creation to save gas on permit approvals
            optionToken.updateDomainSeparator();

            // Store option token against computed hash
            optionTokens[optionHash] = optionToken;

            // Emit event
            emit OptionTokenCreated(
                optionToken,
                payoutToken_,
                quoteToken_,
                eligible_,
                expiry_,
                receiver_,
                call_,
                strikePrice_
            );
        }
        return optionToken;
    }

    function _deploy(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) internal returns (FixedStrikeOptionToken) {
        // All data has been validated prior to entering this function
        // Option token does not exist yet

        // Get name and symbol for option token
        (bytes32 name, bytes32 symbol) = _getNameAndSymbol(
            payoutToken_,
            quoteToken_,
            expiry_,
            call_,
            strikePrice_
        );

        // Deploy option token
        return
            FixedStrikeOptionToken(
                address(optionTokenImplementation).clone(
                    abi.encodePacked(
                        name,
                        symbol,
                        uint8(payoutToken_.decimals()),
                        payoutToken_,
                        quoteToken_,
                        eligible_,
                        expiry_,
                        receiver_,
                        call_,
                        address(this),
                        strikePrice_
                    )
                )
            );
    }

    /// @inheritdoc IFixedStrikeOptionTeller
    function create(
        FixedStrikeOptionToken optionToken_,
        uint256 amount_
    ) external override nonReentrant {
        // Load option parameters
        (
            uint8 decimals,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 eligible,
            uint48 expiry,
            address receiver,
            bool call,
            uint256 strikePrice
        ) = optionToken_.getOptionParameters();

        // Retrieve the internally stored option token with this configuration
        // Reverts internally if token doesn't exist
        FixedStrikeOptionToken optionToken = getOptionToken(
            payoutToken,
            quoteToken,
            eligible,
            expiry,
            receiver,
            call,
            strikePrice
        );

        // Revert if provided token address does not match stored token address
        if (optionToken_ != optionToken) revert Teller_UnsupportedToken(address(optionToken_));

        // Revert if expiry is in the past
        if (uint256(expiry) <= block.timestamp) revert Teller_OptionExpired(expiry);

        // Transfer in collateral
        // If call option, transfer in payout tokens equivalent to the amount of option tokens being issued
        // If put option, transfer in quote tokens equivalent to the amount of option tokens being issued * strike price
        if (call) {
            // Transfer payout tokens from user
            // Check that amount received is not less than amount expected
            // Handles edge cases like fee-on-transfer tokens (which are not supported)
            uint256 startBalance = payoutToken.balanceOf(address(this));
            payoutToken.safeTransferFrom(msg.sender, address(this), amount_);
            uint256 endBalance = payoutToken.balanceOf(address(this));
            if (endBalance < startBalance + amount_)
                revert Teller_UnsupportedToken(address(payoutToken));
        } else {
            // Calculate amount of quote tokens required to mint
            // We round up here to avoid issues with precision loss which could lead to loss of funds
            // The rounding is small at normal values, but protects against purposefully small values
            uint256 quoteAmount = amount_.mulDivUp(strikePrice, 10 ** decimals);
            if (quoteAmount == 0) revert Teller_InvalidAmount();

            // Transfer quote tokens from user
            // Check that amount received is not less than amount expected
            // Handles edge cases like fee-on-transfer tokens (which are not supported)
            uint256 startBalance = quoteToken.balanceOf(address(this));
            quoteToken.safeTransferFrom(msg.sender, address(this), quoteAmount);
            uint256 endBalance = quoteToken.balanceOf(address(this));
            if (endBalance < startBalance + quoteAmount)
                revert Teller_UnsupportedToken(address(quoteToken));
        }

        // Mint new option tokens to sender
        optionToken.mint(msg.sender, amount_);
    }

    /* ========== EXERCISE OPTION TOKENS ========== */

    /// @inheritdoc IFixedStrikeOptionTeller
    function exercise(
        FixedStrikeOptionToken optionToken_,
        uint256 amount_
    ) external override nonReentrant {
        // Load option parameters
        (
            uint8 decimals,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 eligible,
            uint48 expiry,
            address receiver,
            bool call,
            uint256 strikePrice
        ) = optionToken_.getOptionParameters();

        // Retrieve the internally stored option token with this configuration
        // Reverts internally if token doesn't exist
        FixedStrikeOptionToken optionToken = getOptionToken(
            payoutToken,
            quoteToken,
            eligible,
            expiry,
            receiver,
            call,
            strikePrice
        );

        // Revert if token does not match stored token
        if (optionToken_ != optionToken) revert Teller_UnsupportedToken(address(optionToken_));

        // Validate that option token is eligible to be exercised
        if (uint48(block.timestamp) < eligible) revert Teller_NotEligible(eligible);

        // Validate that option token is not expired
        if (uint48(block.timestamp) >= expiry) revert Teller_OptionExpired(expiry);

        // Calculate amount of quote tokens equivalent to amount at strike price
        uint256 quoteAmount = amount_.mulDivUp(strikePrice, 10 ** decimals);

        // If not receiver, require payment
        if (msg.sender != receiver) {
            // If call, transfer in quote tokens equivalent to the amount of option tokens being exercised * strike price
            // If put, transfer in payout tokens equivalent to the amount of option tokens being exercised
            if (call) {
                // Calculate protocol fee
                uint256 fee = (quoteAmount * protocolFee) / FEE_DECIMALS;
                fees[quoteToken] += fee;

                // Transfer proceeds from user
                // Check balances before and after transfer to ensure that the correct amount was transferred
                // @audit this does enable potential malicious option tokens that can't be exercised
                // However, we view it as a "buyer beware" situation that can handled on the front-end
                {
                    uint256 startBalance = quoteToken.balanceOf(address(this));
                    quoteToken.safeTransferFrom(msg.sender, address(this), quoteAmount);
                    uint256 endBalance = quoteToken.balanceOf(address(this));
                    if (endBalance < startBalance + quoteAmount)
                        revert Teller_UnsupportedToken(address(quoteToken));
                }

                // Transfer proceeds minus fee to receiver
                quoteToken.safeTransfer(receiver, quoteAmount - fee);
            } else {
                // Calculate protocol fee (in payout tokens)
                uint256 fee = (amount_ * protocolFee) / FEE_DECIMALS;
                fees[payoutToken] += fee;

                // Transfer proceeds from user
                // Check balances before and after transfer to ensure that the correct amount was transferred
                // @audit this does enable potential malicious option tokens that can't be exercised
                // However, we view it as a "buyer beware" situation that can handled on the front-end
                {
                    uint256 startBalance = payoutToken.balanceOf(address(this));
                    payoutToken.safeTransferFrom(msg.sender, address(this), amount_);
                    uint256 endBalance = payoutToken.balanceOf(address(this));
                    if (endBalance < startBalance + amount_)
                        revert Teller_UnsupportedToken(address(payoutToken));
                }

                // Transfer proceeds minus fee to receiver
                payoutToken.safeTransfer(receiver, amount_ - fee);
            }
        }

        // Burn option tokens
        optionToken.burn(msg.sender, amount_);

        if (call) {
            // Transfer payout tokens to user
            payoutToken.safeTransfer(msg.sender, amount_);
        } else {
            // Transfer quote tokens to user
            quoteToken.safeTransfer(msg.sender, quoteAmount);
        }
    }

    /// @inheritdoc IFixedStrikeOptionTeller
    function reclaim(FixedStrikeOptionToken optionToken_) external override nonReentrant {
        // Load option parameters
        (
            uint8 decimals,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 eligible,
            uint48 expiry,
            address receiver,
            bool call,
            uint256 strikePrice
        ) = optionToken_.getOptionParameters();

        // Retrieve the internally stored option token with this configuration
        // Reverts internally if token doesn't exist
        FixedStrikeOptionToken optionToken = getOptionToken(
            payoutToken,
            quoteToken,
            eligible,
            expiry,
            receiver,
            call,
            strikePrice
        );

        // Revert if token does not match stored token
        if (optionToken_ != optionToken) revert Teller_UnsupportedToken(address(optionToken_));

        // Revert if not expired
        if (uint48(block.timestamp) < expiry) revert Teller_NotExpired(expiry);

        // Revert if caller is not receiver
        if (msg.sender != receiver) revert Teller_NotAuthorized();

        // Revert if collateral has already been reclaimed
        if (collateralClaimed[optionToken]) revert Teller_AlreadyReclaimed(optionToken);

        // Set collateral as reclaimed
        collateralClaimed[optionToken] = true;

        // Transfer remaining collateral to receiver
        uint256 amount = optionToken.totalSupply();
        if (call) {
            payoutToken.safeTransfer(receiver, amount);
        } else {
            // Calculate amount of quote tokens equivalent to amount at strike price
            uint256 quoteAmount = amount.mulDivUp(strikePrice, 10 ** decimals);
            quoteToken.safeTransfer(receiver, quoteAmount);
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @inheritdoc IFixedStrikeOptionTeller
    function exerciseCost(
        FixedStrikeOptionToken optionToken_,
        uint256 amount_
    ) external view returns (ERC20, uint256) {
        // Load option parameters
        (
            uint8 decimals,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 eligible,
            uint48 expiry,
            address receiver,
            bool call,
            uint256 strikePrice
        ) = optionToken_.getOptionParameters();

        // Retrieve the internally stored option token with this configuration
        // Reverts internally if token doesn't exist
        FixedStrikeOptionToken optionToken = getOptionToken(
            payoutToken,
            quoteToken,
            eligible,
            expiry,
            receiver,
            call,
            strikePrice
        );

        // Revert if token does not match stored token
        if (optionToken_ != optionToken) revert Teller_UnsupportedToken(address(optionToken_));

        // If option is a call, calculate quote tokens required to exercise
        // If option is a put, exercise cost is the same as the option token amount in payout tokens
        if (call) {
            return (quoteToken, amount_.mulDivUp(strikePrice, 10 ** decimals));
        } else {
            return (payoutToken, amount_);
        }
    }

    /// @inheritdoc IFixedStrikeOptionTeller
    function getOptionToken(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) public view returns (FixedStrikeOptionToken) {
        // Eligible and Expiry are rounded to the nearest day at 0000 UTC (in seconds) since
        // option tokens are only unique to a day, not a specific timestamp.
        uint48 eligible = uint48(eligible_ / 1 days) * 1 days;
        uint48 expiry = uint48(expiry_ / 1 days) * 1 days;

        // Calculate a hash from the normalized inputs
        bytes32 optionHash = _getOptionTokenHash(
            payoutToken_,
            quoteToken_,
            eligible,
            expiry,
            receiver_,
            call_,
            strikePrice_
        );

        FixedStrikeOptionToken optionToken = optionTokens[optionHash];

        // Revert if token does not exist
        if (address(optionToken) == address(0)) revert Teller_TokenDoesNotExist(optionHash);

        return optionToken;
    }

    /// @inheritdoc IFixedStrikeOptionTeller
    function getOptionTokenHash(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external pure returns (bytes32) {
        // Eligible and Expiry are rounded to the nearest day at 0000 UTC (in seconds) since
        // option tokens are only unique to a day, not a specific timestamp.
        uint48 eligible = uint48(eligible_ / 1 days) * 1 days;
        uint48 expiry = uint48(expiry_ / 1 days) * 1 days;

        return
            _getOptionTokenHash(
                payoutToken_,
                quoteToken_,
                eligible,
                expiry,
                receiver_,
                call_,
                strikePrice_
            );
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _getOptionTokenHash(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    payoutToken_,
                    quoteToken_,
                    eligible_,
                    expiry_,
                    receiver_,
                    call_,
                    strikePrice_
                )
            );
    }

    /// @notice Derive name and symbol of option token
    function _getNameAndSymbol(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint256 expiry_,
        bool call_,
        uint256 strikePrice_
    ) internal view returns (bytes32, bytes32) {
        // Examples
        // WETH call option expiring on 2100-01-01 with strike price of 10_010.50 DAI would be formatted as:
        // Name: "WETH/DAI C 1.001e+4 2100-01-01"
        // Symbol: "oWETH-21000101"
        //
        // WETH put option expiring on 2100-01-01 with strike price of 10.546 DAI would be formatted as:
        // Name: "WETH/DAI P 1.054e+1 2100-01-01"
        // Symbol: "oWETH-21000101"
        //
        // Note: Names are more specific than symbols, but none are guaranteed to be completely unique to a specific oToken.
        // To ensure uniqueness, the option token address and hash identifier should be used.

        // Get the date format from the expiry timestamp.
        // Convert a number of days into a human-readable date, courtesy of BokkyPooBah.
        // Source: https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
        string memory yearStr;
        string memory monthStr;
        string memory dayStr;
        {
            int256 __days = int256(expiry_ / 1 days);

            int256 num1 = __days + 68569 + 2440588; // 2440588 = OFFSET19700101
            int256 num2 = (4 * num1) / 146097;
            num1 = num1 - (146097 * num2 + 3) / 4;
            int256 _year = (4000 * (num1 + 1)) / 1461001;
            num1 = num1 - (1461 * _year) / 4 + 31;
            int256 _month = (80 * num1) / 2447;
            int256 _day = num1 - (2447 * _month) / 80;
            num1 = _month / 11;
            _month = _month + 2 - 12 * num1;
            _year = 100 * (num2 - 49) + _year + num1;

            yearStr = _uint2str(uint256(_year) % 10000);
            monthStr = uint256(_month) < 10
                ? string(abi.encodePacked("0", _uint2str(uint256(_month))))
                : _uint2str(uint256(_month));
            dayStr = uint256(_day) < 10
                ? string(abi.encodePacked("0", _uint2str(uint256(_day))))
                : _uint2str(uint256(_day));
        }

        // Format token symbols
        // Symbols longer than 5 characters are truncated, min length would be 1 if tokens have no symbols, max length is 11
        bytes memory tokenSymbols;
        bytes memory payoutSymbol;
        {
            payoutSymbol = bytes(payoutToken_.symbol());
            if (payoutSymbol.length > 5) payoutSymbol = abi.encodePacked(bytes5(payoutSymbol));
            bytes memory quoteSymbol = bytes(quoteToken_.symbol());
            if (quoteSymbol.length > 5) quoteSymbol = abi.encodePacked(bytes5(quoteSymbol));

            tokenSymbols = abi.encodePacked(payoutSymbol, "/", quoteSymbol);
        }

        // Format option type
        bytes1 callPut = call_ ? bytes1("C") : bytes1("P");

        // Format strike price
        // Strike price is formatted as scientific notation to 3 significant figures
        // Will either be 8 or 9 bytes, e.g. 1.056e+1 (8) or 9.745e-12 (9)
        bytes memory strike = _getScientificNotation(strikePrice_, quoteToken_.decimals());

        // Construct name/symbol strings.

        // Name and symbol can each be at most 32 bytes since it is stored as a bytes32
        // Name is formatted as "payoutSymbol/quoteSymbol callPut strikePrice expiry" with the following constraints:
        // payoutSymbol - 5 bytes
        // "/" - 1 byte
        // quoteSymbol - 5 bytes
        // " " - 1 byte
        // callPut - 1 byte
        // " " - 1 byte
        // strikePrice - 8 or 9 bytes, scientific notation to 3 significant figures, e.g. 1.056e+1 (8) or 9.745e-12 (9)
        // " " - 1 byte
        // expiry - 8 bytes, YYYYMMDD
        // Total is 31 or 32 bytes

        // Symbol is formatted as "oPayoutSymbol-expiry" with the following constraints:
        // "o" - 1 byte
        // payoutSymbol - 5 bytes
        // "-" - 1 byte
        // expiry - 8 bytes, YYYYMMDD
        // Total is 15 bytes

        bytes32 name = bytes32(
            abi.encodePacked(
                tokenSymbols,
                " ",
                callPut,
                " ",
                strike,
                " ",
                yearStr,
                monthStr,
                dayStr
            )
        );
        bytes32 symbol = bytes32(
            abi.encodePacked("o", payoutSymbol, "-", yearStr, monthStr, dayStr)
        );

        return (name, symbol);
    }

    /// @notice Helper function to calculate number of price decimals in the provided price
    /// @param price_   The price to calculate the number of decimals for
    /// @return         The number of decimals
    function _getPriceDecimals(uint256 price_, uint8 tokenDecimals_) internal pure returns (int8) {
        int8 decimals;
        while (price_ >= 10) {
            price_ = price_ / 10;
            decimals++;
        }

        // Subtract the stated decimals from the calculated decimals to get the relative price decimals.
        // Required to do it this way vs. normalizing at the beginning since price decimals can be negative.
        return decimals - int8(tokenDecimals_);
    }

    /// @notice Helper function to format a uint256 into scientific notation with 3 significant figures
    /// @param price_           The price to format
    /// @param tokenDecimals_   The number of decimals in the token
    function _getScientificNotation(
        uint256 price_,
        uint8 tokenDecimals_
    ) internal pure returns (bytes memory) {
        // Get a bytes representation of the price in scientific notation with 3 significant figures.
        // 1. Get the number of price decimals
        int8 priceDecimals = _getPriceDecimals(price_, tokenDecimals_);

        // Scientific notation can support up to 2 digit exponents (i.e. price decimals)
        // The bounds for valid prices have been checked earlier when the token was deployed
        // so we don't have to check again here.

        // 2. Get a string of the price decimals and exponent figure
        bytes memory decStr;
        if (priceDecimals < 0) {
            uint256 decimals = uint256(uint8(-priceDecimals));
            decStr = bytes.concat("e-", bytes(_uint2str(decimals)));
        } else {
            uint256 decimals = uint256(uint8(priceDecimals));
            decStr = bytes.concat("e+", bytes(_uint2str(decimals)));
        }

        // 3. Get a string of the leading digits with decimal point
        uint8 priceMagnitude = uint8(int8(tokenDecimals_) + priceDecimals);
        uint256 digits = price_ / (10 ** (priceMagnitude < 3 ? 0 : priceMagnitude - 3));
        bytes memory digitStr = bytes(_uint2str(digits));
        uint256 len = bytes(digitStr).length;
        bytes memory leadingStr = bytes.concat(digitStr[0], ".");
        for (uint256 i = 1; i < len; ++i) {
            leadingStr = bytes.concat(leadingStr, digitStr[i]);
        }

        // 4. Combine and return
        // The bytes string should be at most 9 bytes (e.g. 1.056e-10)
        return bytes.concat(leadingStr, decStr);
    }

    // Some fancy math to convert a uint into a string, courtesy of Provable Things.
    // Updated to work with solc 0.8.0.
    // https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /* ========== ADMIN & FEES ========== */

    /// @inheritdoc IOptionTeller
    function setMinOptionDuration(uint48 duration_) external override requiresAuth {
        // Must be a minimum of 1 day due to timestamp rounding
        if (duration_ < uint48(1 days)) revert Teller_InvalidParams(0, abi.encodePacked(duration_));
        minOptionDuration = duration_;
    }

    /// @inheritdoc IOptionTeller
    function setProtocolFee(uint48 fee_) external override requiresAuth {
        if (fee_ > 5e3) revert Teller_InvalidParams(0, abi.encodePacked(fee_)); // 5% max
        protocolFee = fee_;
    }

    /// @inheritdoc IOptionTeller
    function claimFees(
        ERC20[] memory tokens_,
        address to_
    ) external override nonReentrant requiresAuth {
        uint256 len = tokens_.length;
        for (uint256 i; i < len; ++i) {
            ERC20 token = tokens_[i];
            uint256 send = fees[token];

            if (send != 0) {
                fees[token] = 0;
                token.safeTransfer(to_, send);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnershipTransferred(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function transferOwnership(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.4;

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    error CreateFail();

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data) internal returns (address instance) {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x43 + extraLength;
            uint256 runSize = creationSize - 11;
            uint256 dataPtr;
            uint256 ptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (11 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 61 runtime  | PUSH2 runtime (r)     | r 0                     | –
                mstore(ptr, 0x3d61000000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x02), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0b
                // 80          | DUP1                  | r r 0                   | –
                // 60 creation | PUSH1 creation (c)    | c r r 0                 | –
                // 3d          | RETURNDATASIZE        | 0 c r r 0               | –
                // 39          | CODECOPY              | r 0                     | [0-2d]: runtime code
                // 81          | DUP2                  | 0 c  0                  | [0-2d]: runtime code
                // f3          | RETURN                | 0                       | [0-2d]: runtime code
                mstore(
                    add(ptr, 0x04),
                    0x80600b3d3981f300000000000000000000000000000000000000000000000000
                )

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME
                // -------------------------------------------------------------------------------------------------------------

                // 36          | CALLDATASIZE          | cds                     | –
                // 3d          | RETURNDATASIZE        | 0 cds                   | –
                // 3d          | RETURNDATASIZE        | 0 0 cds                 | –
                // 37          | CALLDATACOPY          | –                       | [0, cds] = calldata
                // 61          | PUSH2 extra           | extra                   | [0, cds] = calldata
                mstore(
                    add(ptr, 0x0b),
                    0x363d3d3761000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x10), shl(240, extraLength))

                // 60 0x38     | PUSH1 0x38            | 0x38 extra              | [0, cds] = calldata // 0x38 (56) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x38 extra          | [0, cds] = calldata
                // 39          | CODECOPY              | _                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0                     | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0 0                   | [0, cds] = calldata
                // 36          | CALLDATASIZE          | cds 0 0 0               | [0, cds] = calldata
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0         | [0, cds] = calldata
                mstore(
                    add(ptr, 0x12),
                    0x603836393d3d3d36610000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0         | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0             | [0, cds] = calldata
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0        | [0, cds] = calldata
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0    | [0, cds] = calldata
                // f4          | DELEGATECALL          | success 0               | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | rds success 0           | [0, cds] = calldata
                // 82          | DUP3                  | 0 rds success 0         | [0, cds] = calldata
                // 80          | DUP1                  | 0 0 rds success 0       | [0, cds] = calldata
                // 3e          | RETURNDATACOPY        | success 0               | [0, rds] = return data (there might be some irrelevant leftovers in memory [rds, cds] when rds < cds)
                // 90          | SWAP1                 | 0 success               | [0, rds] = return data
                // 3d          | RETURNDATASIZE        | rds 0 success           | [0, rds] = return data
                // 91          | SWAP2                 | success 0 rds           | [0, rds] = return data
                // 60 0x36     | PUSH1 0x36            | 0x36 sucess 0 rds       | [0, rds] = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds] = return data
                // fd          | REVERT                | –                       | [0, rds] = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds] = return data
                // f3          | RETURN                | –                       | [0, rds] = return data

                mstore(
                    add(ptr, 0x34),
                    0x5af43d82803e903d91603657fd5bf30000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x43;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256 ** (32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
            // solhint-disable-next-line no-inline-assembly
            assembly {
                instance := create(0, ptr, creationSize)
            }
            if (instance == address(0)) {
                revert CreateFail();
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IOptionTeller} from "src/interfaces/IOptionTeller.sol";
import {FixedStrikeOptionToken} from "src/fixed-strike/FixedStrikeOptionToken.sol";

interface IFixedStrikeOptionTeller is IOptionTeller {
    /// @notice             Deploy a new ERC20 fixed strike option token and return its address
    /// @dev                If an option token already exists for the parameters, it returns that address
    /// @param payoutToken_ ERC20 token that the purchaser will receive on execution
    /// @param quoteToken_  ERC20 token used that the purchaser will need to provide on execution
    /// @param eligible_    Timestamp at which the option token can first be executed (gets rounded to nearest day)
    /// @param expiry_      Timestamp at which the option token can no longer be executed (gets rounded to nearest day)
    /// @param receiver_    Address that will receive the proceeds when option tokens are exercised. Also the address that can claim collateral from unexercised options.
    /// @param call_        Whether the option token is a call (true) or a put (false)
    /// @param strikePrice_ Strike price of the option token (in units of quoteToken per payoutToken)
    /// @return             Address of the ERC20 fixed strike option token being created
    function deploy(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external returns (FixedStrikeOptionToken);

    /// @notice              Deposit an ERC20 token and mint an ERC20 fixed strike option token
    /// @param optionToken_  Fixed strike option token to mint
    /// @param amount_       Amount of option tokens to mint (also the number of payout tokens required to be deposited)
    function create(FixedStrikeOptionToken optionToken_, uint256 amount_) external;

    /// @notice              Exercise an ERC20 fixed strike option token. Provide required quote tokens and receive amount of payout tokens.
    /// @param optionToken_  Fixed strike option token to exercise
    /// @param amount_       Amount of option tokens to exercise (also the number of payout tokens to receive)
    /// @dev                 Amount of quote tokens required to exercise is return from the exerciseCost() function
    /// @dev                 If the calling address is the token receiver address, then the amount of option tokens
    /// @dev                 are burned and collateral sent back to receiver, but proceeds are not required.
    /// @dev                 This allows unwrapping option tokens that aren't used prior to expiry.
    function exercise(FixedStrikeOptionToken optionToken_, uint256 amount_) external;

    /// @notice              Reclaim collateral from expired option tokens
    /// @notice              Only callable by the option token receiver address
    /// @param optionToken_  Fixed strike option token to reclaim collateral from
    function reclaim(FixedStrikeOptionToken optionToken_) external;

    /* ========== VIEWS ========== */

    /// @notice              Get the cost to exercise an amount of fixed strike option tokens
    /// @param optionToken_  Fixed strike option token to exercise
    /// @param amount_       Amount of option tokens to exercise
    /// @return token_       Token required to exercise (quoteToken for call, payoutToken for put)
    /// @return cost_        Amount of token_ required to exercise
    function exerciseCost(
        FixedStrikeOptionToken optionToken_,
        uint256 amount_
    ) external view returns (ERC20, uint256);

    /// @notice             Get the FixedStrikeOptionToken contract corresponding to the params, reverts if no token exists
    /// @param payoutToken_ ERC20 token that the purchaser will receive on execution
    /// @param quoteToken_  ERC20 token used that the purchaser will need to provide on execution
    /// @param eligible_    Timestamp at which the option token can first be executed (gets rounded to nearest day)
    /// @param expiry_      Timestamp at which the option token can no longer be executed (gets rounded to nearest day)
    /// @param receiver_    Address that will receive the proceeds when option tokens are exercised. Also the address that can claim collateral from unexercised options.
    /// @param call_        Whether the option token is a call (true) or a put (false)
    /// @param strikePrice_ Strike price of the option token (in units of quoteToken per payoutToken)
    /// @return token_      FixedStrikeOptionToken contract address
    function getOptionToken(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external view returns (FixedStrikeOptionToken);

    /// @notice             Get the hash ID of the fixed strike option token with these parameters
    /// @param payoutToken_ ERC20 token that the purchaser will receive on execution
    /// @param quoteToken_  ERC20 token used that the purchaser will need to provide on execution
    /// @param eligible_    Timestamp at which the option token can first be executed (gets rounded to nearest day)
    /// @param expiry_      Timestamp at which the option token can no longer be executed (gets rounded to nearest day)
    /// @param receiver_    Address that will receive the proceeds when option tokens are exercised. Also the address that can claim collateral from unexercised options.
    /// @param call_        Whether the option token is a call (true) or a put (false)
    /// @param strikePrice_ Strike price of the option token (in units of quoteToken per payoutToken)
    /// @return hash_       Hash ID of the fixed strike option token with these parameters
    function getOptionTokenHash(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {OptionToken, ERC20} from "src/bases/OptionToken.sol";

/// @title Fixed Strike Option Token
/// @notice Fixed Strike Option Token Contract (ERC-20 compatible)
///
/// @dev The Fixed Strike Option Token contract is issued by a
///      Fixed Strike Option Token Teller to represent traditional
///      American-style options on the underlying token with a fixed strike price.
///
///      Call option tokens can be exercised for the underlying token 1:1
///      by paying the amount * strike price in the quote token
///      at any time between the eligible and expiry timestamps.
///
/// @dev This contract uses Clones (https://github.com/wighawag/clones-with-immutable-args)
///      to save gas on deployment and is based on VestedERC20 (https://github.com/ZeframLou/vested-erc20)
///
/// @author Bond Protocol
contract FixedStrikeOptionToken is OptionToken {
    /* ========== IMMUTABLE PARAMETERS ========== */

    /// @notice The strike price of the option
    /// @return _strike The option strike price specified in the amount of quote tokens per underlying token
    function strike() public pure returns (uint256 _strike) {
        return _getArgUint256(0x9e);
    }

    /* ========== VIEW ========== */

    /// @notice Get collection of option parameters in a single call
    /// @return decimals_  The number of decimals for the option token (same as payout token)
    /// @return payout_    The address of the payout token
    /// @return quote_     The address of the quote token
    /// @return eligible_  The option exercise eligibility timestamp
    /// @return expiry_    The option exercise expiry timestamp
    /// @return receiver_  The address of the receiver
    /// @return call_      Whether the option is a call (true) or a put (false)
    /// @return strike_    The option strike price specified in the amount of quote tokens per underlying token
    function getOptionParameters()
        external
        pure
        returns (
            uint8 decimals_,
            ERC20 payout_,
            ERC20 quote_,
            uint48 eligible_,
            uint48 expiry_,
            address receiver_,
            bool call_,
            uint256 strike_
        )
    {
        return (decimals(), payout(), quote(), eligible(), expiry(), receiver(), call(), strike());
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice Safe ERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// @author Taken from Solmate.
library TransferHelper {
    function safeTransferFrom(ERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, amount)
        );

        require(
            success &&
                (data.length == 0 || abi.decode(data, (bool))) &&
                address(token).code.length > 0,
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(ERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transfer.selector, to, amount)
        );

        require(
            success &&
                (data.length == 0 || abi.decode(data, (bool))) &&
                address(token).code.length > 0,
            "TRANSFER_FAILED"
        );
    }

    function safeApprove(ERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    // function safeTransferETH(address to, uint256 amount) internal {
    //     (bool success, ) = to.call{value: amount}(new bytes(0));

    //     require(success, "ETH_TRANSFER_FAILED");
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IOptionTeller {
    /// @notice         Set minimum duration to exercise option
    /// @notice         Access controlled
    /// @dev            Absolute minimum is 1 day (86400 seconds) due to timestamp rounding of eligible and expiry parameters
    /// @param duration_ Minimum duration in seconds
    function setMinOptionDuration(uint48 duration_) external;

    /// @notice         Set protocol fee
    /// @notice         Access controlled
    /// @param fee_     Protocol fee in basis points (3 decimal places)
    function setProtocolFee(uint48 fee_) external;

    /// @notice         Claim fees accrued by protocol in the input tokens and sends them to the provided address
    /// @notice         Access controlled
    /// @param tokens_  Array of tokens to claim fees for
    /// @param to_      Address to send fees to
    function claimFees(ERC20[] memory tokens_, address to_) external;

    /// @notice         Minimum duration an option must be eligible for exercise for (in seconds)
    function minOptionDuration() external view returns (uint48);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {CloneERC20} from "src/lib/clones/CloneERC20.sol";

/// @title Option Token
/// @notice Option Token Contract (ERC-20 compatible)
///
/// @dev The Option Token contract is issued by a Option Token Teller to
///      represent American-style options on the underlying token.
///
///      Call option tokens can be exercised for the underlying token 1:1
///      by paying the amount * strike price in the quote token
///      at any time between the eligible and expiry timestamps.
///
///      Put option tokens can be exercised for the underlying token 1:1
///      by paying the amount of the underlying token to receive the
///      amount * strike price in the quote token at any time between
///      the eligible and expiry timestamps.
///
/// @dev This contract uses Clones (https://github.com/wighawag/clones-with-immutable-args)
///      to save gas on deployment and is based on VestedERC20 (https://github.com/ZeframLou/vested-erc20)
///
/// @author Bond Protocol
abstract contract OptionToken is CloneERC20 {
    /* ========== ERRORS ========== */
    error OptionToken_OnlyTeller();

    /* ========== IMMUTABLE PARAMETERS ========== */

    /// @notice The token that the option is on
    /// @return _payout The address of the payout token
    function payout() public pure returns (ERC20 _payout) {
        return ERC20(_getArgAddress(0x41));
    }

    /// @notice The token that the option is quoted in
    /// @return _quote The address of the quote token
    function quote() public pure returns (ERC20 _quote) {
        return ERC20(_getArgAddress(0x55));
    }

    /// @notice Timestamp at which the Option token can first be exercised
    /// @return _eligible The option exercise eligibility timestamp
    function eligible() public pure returns (uint48 _eligible) {
        return _getArgUint48(0x69);
    }

    /// @notice Timestamp at which the Option token cannot be exercised after
    /// @return _expiry The option exercise expiry timestamp
    function expiry() public pure returns (uint48 _expiry) {
        return _getArgUint48(0x6f);
    }

    /// @notice Address that will receive the proceeds when option tokens are exercised
    /// @return _receiver The address of the receiver
    function receiver() public pure returns (address _receiver) {
        return _getArgAddress(0x75);
    }

    /// @notice Whether the option is a call or a put
    /// @return _call True if the option is a call, false if the option is a put
    function call() public pure returns (bool _call) {
        return _getArgBool(0x89);
    }

    /// @notice Address of the Teller that created the token
    function teller() public pure returns (address _teller) {
        return _getArgAddress(0x8a);
    }

    /* ========== MINT/BURN ========== */

    /// @notice Mint option tokens
    /// @notice Only callable by the Teller that created the token
    /// @param to     The address to mint to
    /// @param amount The amount to mint
    function mint(address to, uint256 amount) external {
        if (msg.sender != teller()) revert OptionToken_OnlyTeller();
        _mint(to, amount);
    }

    /// @notice Burn option tokens
    /// @notice Only callable by the Teller that created the token
    /// @param from   The address to burn from
    /// @param amount The amount to burtn
    function burn(address from, uint256 amount) external {
        if (msg.sender != teller()) revert OptionToken_OnlyTeller();
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Clone} from "src/lib/clones/Clone.sol";

/// @notice Modern and gas efficient ERC20 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract CloneERC20 is Clone {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public nonces;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 public chainId;

    bytes32 internal domainSeparator;

    /*///////////////////////////////////////////////////////////////
                               METADATA
    //////////////////////////////////////////////////////////////*/

    function name() public pure returns (string memory) {
        return string(abi.encodePacked(_getArgUint256(0)));
    }

    function symbol() external pure returns (string memory) {
        return string(abi.encodePacked(_getArgUint256(0x20)));
    }

    function decimals() public pure returns (uint8) {
        return _getArgUint8(0x40);
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == chainId ? domainSeparator : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name())),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function updateDomainSeparator() external {
        require(block.chainid != chainId, "DOMAIN_SEPARATOR_ALREADY_UPDATED");

        chainId = block.chainid;

        domainSeparator = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] += amount;

        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);

        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] -= amount;

        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    function _getImmutableVariablesOffset() internal pure returns (uint256 offset) {
        assembly {
            offset := sub(calldatasize(), add(shr(240, calldataload(sub(calldatasize(), 2))), 2))
        }
    }
}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset) internal pure returns (address arg) {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset) internal pure returns (uint256 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset) internal pure returns (uint64 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint48
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint48(uint256 argOffset) internal pure returns (uint48 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xd0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type bool
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgBool(uint256 argOffset) internal pure returns (bool arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(calldatasize(), add(shr(240, calldataload(sub(calldatasize(), 2))), 2))
        }
    }
}