// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../external/interfaces/chainlink/AggregatorV3Interface.sol";
import "../interfaces/IPriceFeedAdapter.sol";
import "./UnlimitedPriceFeedUpdater.sol";
import "../shared/Constants.sol";
import "../shared/UnlimitedOwnable.sol";

/**
 * @title Unlimited Price Feed Adapter
 * @notice Gets the price data from the trusted Unlimited Leverage source.
 * @dev
 * The price is defined in token vs token price (e.g. ETH/USDC)
 * The Unlimited price has to be within a relative margin of the Chainlink one.
 * This acts as an additional price selfcheck with an external price feed source.
 * Limitation of this price feed is that Unlimited price, Chainlink asset and
 * Chainlink collateral price needs to be the same. This is done for optimization
 * puprposes as most Chainlink USD pairs have 8 decimals
 */
contract UnlimitedPriceFeedAdapter is UnlimitedPriceFeedUpdater, IPriceFeedAdapter, UnlimitedOwnable {
    /* ========== CONSTANTS ========== */

    /// @notice Minimum value that can be set for max deviation.
    uint256 constant MINIMUM_MAX_DEVIATION = 5;

    /* ========== STATE VARIABLES ========== */

    string public override name;
    AggregatorV3Interface public collateralChainlinkPriceFeed;
    AggregatorV3Interface public assetChainlinkPriceFeed;

    uint256 public immutable collateralDecimals;

    uint256 private immutable COLLATERAL_MULTIPLIER;
    uint256 private immutable COLLATERAL_TO_PRICE_MULTIPLIER;
    uint256 private assetPriceMultiplier;
    uint256 private collateralPriceMultiplier;

    uint256 public maxDeviation;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Constructs the UnlimitedPriceFeedAdapter contract.
     * @param controller_ The address of the controller contract.
     */
    constructor(uint256 collateralDecimals_, IController controller_, IUnlimitedOwner unlimitedOwner_)
        UnlimitedPriceFeedUpdater(controller_)
        UnlimitedOwnable(unlimitedOwner_)
    {
        require(
            PRICE_DECIMALS >= collateralDecimals_,
            "UnlimitedPriceFeedAdapter::constructor: price decimals must be >= collateral decimals"
        );

        collateralDecimals = collateralDecimals_;

        COLLATERAL_MULTIPLIER = 10 ** collateralDecimals_;
        COLLATERAL_TO_PRICE_MULTIPLIER = PRICE_MULTIPLIER / COLLATERAL_MULTIPLIER;
    }

    /**
     * @notice Initializes the name of the price feed adapter and underlying updater
     * @param name_ The name of the price feed adapter.
     * @param maxDeviation_ The maximum deviation of the Unlimited price from the Chainlink price.
     * @param collateralChainlinkPriceFeed_ The address of the Chainlink price feed for the collateral, needed for usd price.
     * @param assetChainlinkPriceFeed_ The address of the Chainlink price feed for the asset, needed for usd price.
     */
    function initialize(
        string calldata name_,
        uint256 maxDeviation_,
        AggregatorV3Interface collateralChainlinkPriceFeed_,
        AggregatorV3Interface assetChainlinkPriceFeed_
    ) external onlyOwner initializer {
        __UnlimitedPriceFeedUpdater_init(name_);

        name = name_;

        collateralChainlinkPriceFeed = collateralChainlinkPriceFeed_;
        assetChainlinkPriceFeed = assetChainlinkPriceFeed_;
        assetPriceMultiplier = 10 ** assetChainlinkPriceFeed_.decimals();
        collateralPriceMultiplier = 10 ** collateralChainlinkPriceFeed_.decimals();

        _updateMaxDeviation(maxDeviation_);
    }

    /* ============ ASSET - COLLATERAL CONVERSION ============ */

    /**
     * @notice Returns max asset equivalent to the collateral amount
     * @param collateralAmount_ the amount of collateral
     */
    function collateralToAssetMax(uint256 collateralAmount_) external view returns (uint256) {
        return _collateralToAsset(collateralAmount_);
    }

    /**
     * @notice Returns min asset equivalent to the collateral amount
     * @param collateralAmount_ the amount of collateral
     */
    function collateralToAssetMin(uint256 collateralAmount_) external view returns (uint256) {
        return _collateralToAsset(collateralAmount_);
    }

    function _collateralToAsset(uint256 collateralAmount_) private view returns (uint256) {
        return collateralAmount_ * COLLATERAL_TO_PRICE_MULTIPLIER * ASSET_MULTIPLIER / uint256(_price());
    }

    /**
     * @notice Returns maximum collateral equivalent to the asset amount
     * @param assetAmount_ the amount of asset
     */
    function assetToCollateralMax(uint256 assetAmount_) external view returns (uint256) {
        return _assetToCollateral(assetAmount_);
    }

    /**
     * @notice Returns minimum collateral equivalent to the asset amount
     * @param assetAmount_ the amount of asset
     */
    function assetToCollateralMin(uint256 assetAmount_) external view returns (uint256) {
        return _assetToCollateral(assetAmount_);
    }

    function _assetToCollateral(uint256 assetAmount_) private view returns (uint256) {
        return assetAmount_ * uint256(_price()) / COLLATERAL_TO_PRICE_MULTIPLIER / ASSET_MULTIPLIER;
    }

    /* ============ USD Conversion ============ */

    /**
     * @notice Returns the minimum usd equivalent to the asset amount
     * @dev The minimum collateral amount gets returned. It takes into accounts the minimum price.
     * NOTE: This price should not be used to calculate PnL of the trades
     * @param assetAmount_ the amount of asset
     * @return the amount of usd
     */
    function assetToUsdMin(uint256 assetAmount_) external view returns (uint256) {
        return _assetToUsd(assetAmount_);
    }

    /**
     * @notice Returns the maximum usd equivalent to the asset amount
     * @dev The maximum collateral amount gets returned. It takes into accounts the maximum price.
     * NOTE: This price should not be used to calculate PnL of the trades
     * @param assetAmount_ the amount of asset
     * @return the amount of usd
     */
    function assetToUsdMax(uint256 assetAmount_) external view returns (uint256) {
        return _assetToUsd(assetAmount_);
    }

    function _assetToUsd(uint256 assetAmount_) private view returns (uint256) {
        (, int256 answer,,,) = assetChainlinkPriceFeed.latestRoundData();
        return assetAmount_ * uint256(answer) / ASSET_MULTIPLIER;
    }

    /**
     * @notice Returns the minimum usd equivalent to the collateral amount
     * @dev The minimum collateral amount gets returned. It takes into accounts the minimum price.
     * NOTE: This price should not be used to calculate PnL of the trades
     * @param collateralAmount_ the amount of collateral
     * @return the amount of usd
     */
    function collateralToUsdMin(uint256 collateralAmount_) external view returns (uint256) {
        return _collateralToUsd(collateralAmount_);
    }

    /**
     * @notice Returns the maximum usd equivalent to the collateral amount
     * @dev The maximum collateral amount gets returned. It takes into accounts the maximum price.
     * NOTE: This price should not be used to calculate PnL of the trades
     * @param collateralAmount_ the amount of collateral
     * @return the amount of usd
     */
    function collateralToUsdMax(uint256 collateralAmount_) external view returns (uint256) {
        return _collateralToUsd(collateralAmount_);
    }

    function _collateralToUsd(uint256 collateralAmount_) private view returns (uint256) {
        (, int256 answer,,,) = collateralChainlinkPriceFeed.latestRoundData();
        return collateralAmount_ * uint256(answer) / COLLATERAL_MULTIPLIER;
    }

    /* ============ PRICE ============ */

    /**
     * @notice Returns the max price of the asset in the collateral
     * @dev Returns price of the last updated round
     */
    function markPriceMax() external view returns (int256) {
        return _price();
    }

    /**
     * @notice Returns the min price of the asset in the collateral
     * @dev Returns price of the last updated round
     */
    function markPriceMin() external view returns (int256) {
        return _price();
    }

    /**
     * @notice Updates the maximum deviation from the chainlink price feed.
     * @param maxDeviation_ The new maximum deviation.
     */
    function updateMaxDeviation(uint256 maxDeviation_) external onlyOwner {
        _updateMaxDeviation(maxDeviation_);
    }

    function _updateMaxDeviation(uint256 maxDeviation_) private {
        require(
            maxDeviation_ >= MINIMUM_MAX_DEVIATION && maxDeviation_ <= FULL_PERCENT,
            "UnlimitedPriceFeedAdapter::_updateMaxDeviation: Bad max deviation"
        );

        maxDeviation = maxDeviation_;
    }

    function _verifyNewPrice(int256 newPrice) internal view override {
        int256 chainlinkPrice = _getChainlinkPrice();

        unchecked {
            int256 maxAbsoluteDeviation = int256(uint256(chainlinkPrice) * maxDeviation / FULL_PERCENT);

            require(
                newPrice >= chainlinkPrice - maxAbsoluteDeviation && newPrice <= chainlinkPrice + maxAbsoluteDeviation,
                "UnlimitedPriceFeedAdapter::_verifyNewPrice: Price deviation too high"
            );
        }
    }

    function _getChainlinkPrice() internal view returns (int256) {
        (uint80 assetBaseRoundID, int256 assetAnswer,, uint256 assetBaseTimestamp, uint80 assetBaseAnsweredInRound) =
            assetChainlinkPriceFeed.latestRoundData();
        require(assetAnswer > 0, "UnlimitedPriceFeedAdapter::_getChainLinkPrice:assetChainlinkPriceFeed: answer <= 0");
        require(
            assetBaseAnsweredInRound >= assetBaseRoundID,
            "UnlimitedPriceFeedAdapter::_getChainLinkPrice:assetChainlinkPriceFeed: stale price"
        );
        require(
            assetBaseTimestamp > 0,
            "UnlimitedPriceFeedAdapter::_getChainLinkPrice:assetChainlinkPriceFeed: round not complete"
        );

        (
            uint80 collateralBaseRoundID,
            int256 collateralAnswer,
            ,
            uint256 collateralBaseTimestamp,
            uint80 collateralBaseAnsweredInRound
        ) = collateralChainlinkPriceFeed.latestRoundData();
        require(
            collateralAnswer > 0,
            "UnlimitedPriceFeedAdapter::_getChainLinkPrice:collateralChainlinkPriceFeed answer <= 0"
        );
        require(
            collateralBaseAnsweredInRound >= collateralBaseRoundID,
            "UnlimitedPriceFeedAdapter::_getChainLinkPrice:collateralChainlinkPriceFeed stale price"
        );
        require(
            collateralBaseTimestamp > 0,
            "UnlimitedPriceFeedAdapter::_getChainLinkPrice:collateralChainlinkPriceFeed Round not complete"
        );

        return assetAnswer * int256(PRICE_MULTIPLIER) * int256(collateralPriceMultiplier) / collateralAnswer
            / int256(assetPriceMultiplier);
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
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IPriceFeedAggregator.sol";

/**
 * @title IPriceFeedAdapter
 * @notice Provides a way to convert an asset amount to a collateral amount and vice versa
 * Needs two PriceFeedAggregators: One for asset and one for collateral
 */
interface IPriceFeedAdapter {
    function name() external view returns (string memory);

    /* ============ DECIMALS ============ */

    function collateralDecimals() external view returns (uint256);

    /* ============ ASSET - COLLATERAL CONVERSION ============ */

    function collateralToAssetMin(uint256 collateralAmount) external view returns (uint256);

    function collateralToAssetMax(uint256 collateralAmount) external view returns (uint256);

    function assetToCollateralMin(uint256 assetAmount) external view returns (uint256);

    function assetToCollateralMax(uint256 assetAmount) external view returns (uint256);

    /* ============ USD Conversion ============ */

    function assetToUsdMin(uint256 assetAmount) external view returns (uint256);

    function assetToUsdMax(uint256 assetAmount) external view returns (uint256);

    function collateralToUsdMin(uint256 collateralAmount) external view returns (uint256);

    function collateralToUsdMax(uint256 collateralAmount) external view returns (uint256);

    /* ============ PRICE ============ */

    function markPriceMin() external view returns (int256);

    function markPriceMax() external view returns (int256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin-upgradeable/contracts/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "../interfaces/IController.sol";
import "../interfaces/IUpdatable.sol";

/**
 * @notice Struct to store the price feed data.
 * @custom:member createdOn The timestamp when the price data was stored.
 * @custom:member validTo The timestamp until which the price data is valid.
 * @custom:member price The price.
 */
struct PriceData {
    uint32 createdOn;
    uint32 validTo;
    int192 price;
}

/**
 * @title Unlimited Price Feed
 * @notice Unlimited Price Feed is a price feed that can be updated by anyone.
 * To update the price feed, the caller must provide a UpdateData struct that contains
 * a valid signature from the registered signer. Price Updates contained must by valid and more recent than
 * the last update. The price feed will only accept updates that are within the validTo period.
 * The price may only deviate at a set percentage from the chainlink price feed.
 */
abstract contract UnlimitedPriceFeedUpdater is EIP712Upgradeable, IUpdatable {
    /* ========== CONSTANTS ========== */

    uint256 private constant SIGNATURE_END = 65;
    uint256 private constant WORD_LENGTH = 32;
    uint256 private constant SIGNER_END = SIGNATURE_END + WORD_LENGTH;
    uint256 private constant DATA_LENGTH = SIGNER_END + WORD_LENGTH * 3;

    /* ========== STATE VARIABLES ========== */

    /// @notice Controller contract.
    IController public immutable controller;
    /// @notice Recent price data. It gets updated with each valid update request.
    PriceData public priceData;

    /**
     * @notice Constructs the UnlimitedPriceFeedUpdater contract.
     * @param controller_ The address of the controller contract.
     */
    constructor(IController controller_) {
        controller = controller_;
    }

    /**
     * @notice Initializes the underlying EIP712 contract
     * @param name_ the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     */
    function __UnlimitedPriceFeedUpdater_init(string memory name_) internal onlyInitializing {
        __EIP712_init(name_, "1");
    }

    /**
     * @notice Returns last price
     * @return the price from the last round
     */
    function _price() internal view verifyPriceValidity returns (int256) {
        return priceData.price;
    }

    /**
     * @notice Update price with signed data.
     * @param updateData_ Data bytes consisting of signature, signer and price data in respected order.
     */
    function update(bytes calldata updateData_) external {
        require(updateData_.length == DATA_LENGTH, "UnlimitedPriceFeedUpdater::update: Bad data length");

        PriceData memory newPriceData = abi.decode(updateData_[SIGNER_END:], (PriceData));

        // Verify new price data is more recent than the current price data
        // Return if the new price data is not more recent
        if (newPriceData.createdOn <= priceData.createdOn) {
            return;
        }

        // verify signer access controlls
        address signer = abi.decode(updateData_[SIGNATURE_END:SIGNER_END], (address));

        // throw if the signer is not allowed to update the price
        _verifySigner(signer);

        // verify signature
        bytes calldata signature = updateData_[:SIGNATURE_END];
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(signer, _hashPriceDataUpdate(newPriceData), signature),
            "UnlimitedPriceFeedUpdater::update: Bad signature"
        );

        // verify validity of data
        _verifyValidTo(newPriceData.validTo);

        _verifyNewPrice(newPriceData.price);

        priceData = newPriceData;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _hashPriceDataUpdate(PriceData memory priceData_) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(address(this), priceData_)));
    }

    function _verifyNewPrice(int256 newPrice) internal view virtual;

    /* ========== RESTRICTION FUNCTIONS ========== */

    function _verifyValidTo(uint256 validTo_) private view {
        require(validTo_ >= block.timestamp, "UnlimitedPriceFeedUpdater::_verifyValidTo: Price is not valid");
    }

    function _verifySigner(address signer_) private view {
        require(controller.isSigner(signer_), "UnlimitedPriceFeedUpdater::_verifySigner: Bad signer");
    }

    /* ========== MODIFIERS ========== */

    modifier verifyPriceValidity() {
        _verifyValidTo(priceData.validTo);
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

/**
 * @dev These are global constants used in the Unlimited protocol.
 * These constants are mainly used as multipliers.
 */

// 100 percent in BPS.
uint256 constant FULL_PERCENT = 100_00;
int256 constant FEE_MULTIPLIER = 1e14;
int256 constant FEE_BPS_MULTIPLIER = FEE_MULTIPLIER / 1e4; // 1e10
int256 constant BUFFER_MULTIPLIER = 1e6;
uint256 constant PERCENTAGE_MULTIPLIER = 1e6;
uint256 constant LEVERAGE_MULTIPLIER = 1_000_000;
uint8 constant ASSET_DECIMALS = 18;
uint256 constant ASSET_MULTIPLIER = 10 ** ASSET_DECIMALS;

// Rational to use 24 decimals for prices:
// 24 decimals is larger or equal than decimals of all important tokens. (Ethereum = 18, BNB = 18, USDT = 6)
// It is higher than most price feeds (Chainlink = 8, Uniswap = 18, Binance = 8)
uint256 constant PRICE_DECIMALS = 24;
uint256 constant PRICE_MULTIPLIER = 10 ** PRICE_DECIMALS;

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../interfaces/IUnlimitedOwner.sol";

/// @title Logic to help check whether the caller is the Unlimited owner
abstract contract UnlimitedOwnable {
    /* ========== STATE VARIABLES ========== */

    /// @notice Contract that holds the address of Unlimited owner
    IUnlimitedOwner public immutable unlimitedOwner;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Sets correct initial values
     * @param _unlimitedOwner Unlimited owner contract address
     */
    constructor(IUnlimitedOwner _unlimitedOwner) {
        require(
            address(_unlimitedOwner) != address(0),
            "UnlimitedOwnable::constructor: Unlimited owner contract address cannot be 0"
        );

        unlimitedOwner = _unlimitedOwner;
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @notice Checks if caller is Unlimited owner
     * @return True if caller is Unlimited owner, false otherwise
     */
    function isUnlimitedOwner() internal view returns (bool) {
        return unlimitedOwner.isUnlimitedOwner(msg.sender);
    }

    /// @notice Checks and throws if caller is not Unlimited owner
    function _onlyOwner() private view {
        require(isUnlimitedOwner(), "UnlimitedOwnable::_onlyOwner: Caller is not the Unlimited owner");
    }

    /// @notice Checks and throws if caller is not Unlimited owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IPriceFeed.sol";

/**
 * @title IPriceFeedAggregator
 * @notice Aggreates two or more price feeds into min and max prices
 */
interface IPriceFeedAggregator {
    /* ========== VIEW FUNCTIONS ========== */

    function name() external view returns (string memory);

    function minPrice() external view returns (int256);

    function maxPrice() external view returns (int256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addPriceFeed(IPriceFeed) external;

    function removePriceFeed(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
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
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271Upgradeable.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IController {
    /* ========== EVENTS ========== */

    event TradePairAdded(address indexed tradePair);

    event LiquidityPoolAdded(address indexed liquidityPool);

    event LiquidityPoolAdapterAdded(address indexed liquidityPoolAdapter);

    event PriceFeedAdded(address indexed priceFeed);

    event UpdatableAdded(address indexed updatable);

    event TradePairRemoved(address indexed tradePair);

    event LiquidityPoolRemoved(address indexed liquidityPool);

    event LiquidityPoolAdapterRemoved(address indexed liquidityPoolAdapter);

    event PriceFeedRemoved(address indexed priceFeed);

    event UpdatableRemoved(address indexed updatable);

    event SignerAdded(address indexed signer);

    event SignerRemoved(address indexed signer);

    event OrderExecutorAdded(address indexed orderExecutor);

    event OrderExecutorRemoved(address indexed orderExecutor);

    event SetOrderRewardOfCollateral(address indexed collateral_, uint256 reward_);

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Is trade pair registered
    function isTradePair(address tradePair) external view returns (bool);

    /// @notice Is liquidity pool registered
    function isLiquidityPool(address liquidityPool) external view returns (bool);

    /// @notice Is liquidity pool adapter registered
    function isLiquidityPoolAdapter(address liquidityPoolAdapter) external view returns (bool);

    /// @notice Is price fee adapter registered
    function isPriceFeed(address priceFeed) external view returns (bool);

    /// @notice Is contract updatable
    function isUpdatable(address contractAddress) external view returns (bool);

    /// @notice Is Signer registered
    function isSigner(address signer) external view returns (bool);

    /// @notice Is order executor registered
    function isOrderExecutor(address orderExecutor) external view returns (bool);

    /// @notice Reverts if trade pair inactive
    function checkTradePairActive(address tradePair) external view;

    /// @notice Returns order reward for collateral token
    function orderRewardOfCollateral(address collateral) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Adds the trade pair to the registry
     */
    function addTradePair(address tradePair) external;

    /**
     * @notice Adds the liquidity pool to the registry
     */
    function addLiquidityPool(address liquidityPool) external;

    /**
     * @notice Adds the liquidity pool adapter to the registry
     */
    function addLiquidityPoolAdapter(address liquidityPoolAdapter) external;

    /**
     * @notice Adds the price feed to the registry
     */
    function addPriceFeed(address priceFeed) external;

    /**
     * @notice Adds updatable contract to the registry
     */
    function addUpdatable(address) external;

    /**
     * @notice Adds signer to the registry
     */
    function addSigner(address) external;

    /**
     * @notice Adds order executor to the registry
     */
    function addOrderExecutor(address) external;

    /**
     * @notice Removes the trade pair from the registry
     */
    function removeTradePair(address tradePair) external;

    /**
     * @notice Removes the liquidity pool from the registry
     */
    function removeLiquidityPool(address liquidityPool) external;

    /**
     * @notice Removes the liquidity pool adapter from the registry
     */
    function removeLiquidityPoolAdapter(address liquidityPoolAdapter) external;

    /**
     * @notice Removes the price feed from the registry
     */
    function removePriceFeed(address priceFeed) external;

    /**
     * @notice Removes updatable from the registry
     */
    function removeUpdatable(address) external;

    /**
     * @notice Removes signer from the registry
     */
    function removeSigner(address) external;

    /**
     * @notice Removes order executor from the registry
     */
    function removeOrderExecutor(address) external;

    /**
     * @notice Sets order reward for collateral token
     */
    function setOrderRewardOfCollateral(address, uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IUpdatable
 */
interface IUpdatable {
    /* ========== CORE FUNCTIONS ========== */
    function update(bytes calldata data) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IUnlimitedOwner
 */
interface IUnlimitedOwner {
    function owner() external view returns (address);

    function isUnlimitedOwner(address) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IPriceFeed
 * @notice Gets the last and previous price of an asset from a price feed
 * @dev The price must be returned with 8 decimals, following the USD convention
 */
interface IPriceFeed {
    /* ========== VIEW FUNCTIONS ========== */

    function price() external view returns (int256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
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