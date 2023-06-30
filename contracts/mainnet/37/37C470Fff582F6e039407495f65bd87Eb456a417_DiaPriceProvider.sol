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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @dev https://docs.diadata.org/documentation/oracle-documentation/access-the-oracle
interface IDIAOracleV2 {
    function getValue(string memory key) external view returns (uint128 latestPrice, uint128 timestampOfLatestPrice);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

/// @title Common interface for Silo Price Providers
interface IPriceProvider {
    /// @notice Returns "Time-Weighted Average Price" for an asset. Calculates TWAP price for quote/asset.
    /// It unifies all tokens decimal to 18, examples:
    /// - if asses == quote it returns 1e18
    /// - if asset is USDC and quote is ETH and ETH costs ~$3300 then it returns ~0.0003e18 WETH per 1 USDC
    /// @param _asset address of an asset for which to read price
    /// @return price of asses with 18 decimals, throws when pool is not ready yet to provide price
    function getPrice(address _asset) external view returns (uint256 price);

    /// @dev Informs if PriceProvider is setup for asset. It does not means PriceProvider can provide price right away.
    /// Some providers implementations need time to "build" buffer for TWAP price,
    /// so price may not be available yet but this method will return true.
    /// @param _asset asset in question
    /// @return TRUE if asset has been setup, otherwise false
    function assetSupported(address _asset) external view returns (bool);

    /// @notice Gets token address in which prices are quoted
    /// @return quoteToken address
    function quoteToken() external view returns (address);

    /// @notice Helper method that allows easily detects, if contract is PriceProvider
    /// @dev this can save us from simple human errors, in case we use invalid address
    /// but this should NOT be treated as security check
    /// @return always true
    function priceProviderPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

import "./IPriceProvider.sol";

interface IPriceProvidersRepository {
    /// @notice Emitted when price provider is added
    /// @param newPriceProvider new price provider address
    event NewPriceProvider(IPriceProvider indexed newPriceProvider);

    /// @notice Emitted when price provider is removed
    /// @param priceProvider removed price provider address
    event PriceProviderRemoved(IPriceProvider indexed priceProvider);

    /// @notice Emitted when asset is assigned to price provider
    /// @param asset assigned asset   address
    /// @param priceProvider price provider address
    event PriceProviderForAsset(address indexed asset, IPriceProvider indexed priceProvider);

    /// @notice Register new price provider
    /// @param _priceProvider address of price provider
    function addPriceProvider(IPriceProvider _priceProvider) external;

    /// @notice Unregister price provider
    /// @param _priceProvider address of price provider to be removed
    function removePriceProvider(IPriceProvider _priceProvider) external;

    /// @notice Sets price provider for asset
    /// @dev Request for asset price is forwarded to the price provider assigned to that asset
    /// @param _asset address of an asset for which price provider will be used
    /// @param _priceProvider address of price provider
    function setPriceProviderForAsset(address _asset, IPriceProvider _priceProvider) external;

    /// @notice Returns "Time-Weighted Average Price" for an asset
    /// @param _asset address of an asset for which to read price
    /// @return price TWAP price of a token with 18 decimals
    function getPrice(address _asset) external view returns (uint256 price);

    /// @notice Gets price provider assigned to an asset
    /// @param _asset address of an asset for which to get price provider
    /// @return priceProvider address of price provider
    function priceProviders(address _asset) external view returns (IPriceProvider priceProvider);

    /// @notice Gets token address in which prices are quoted
    /// @return quoteToken address
    function quoteToken() external view returns (address);

    /// @notice Gets manager role address
    /// @return manager role address
    function manager() external view returns (address);

    /// @notice Checks if providers are available for an asset
    /// @param _asset asset address to check
    /// @return returns TRUE if price feed is ready, otherwise false
    function providersReadyForAsset(address _asset) external view returns (bool);

    /// @notice Returns true if address is a registered price provider
    /// @param _provider address of price provider to be removed
    /// @return true if address is a registered price provider, otherwise false
    function isPriceProvider(IPriceProvider _provider) external view returns (bool);

    /// @notice Gets number of price providers registered
    /// @return number of price providers registered
    function providersCount() external view returns (uint256);

    /// @notice Gets an array of price providers
    /// @return array of price providers
    function providerList() external view returns (address[] memory);

    /// @notice Sanity check function
    /// @return returns always TRUE
    function priceProvidersRepositoryPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

import "./IPriceProvider.sol";

/// @title Common interface V2 for Silo Price Providers
interface IPriceProviderV2 is IPriceProvider {
    /// @dev for liquidation purposes and for compatibility with naming convention we already using in LiquidationHelper
    /// we have this method to return on-chain provider that can be useful for liquidation
    function getFallbackProvider(address _asset) external view returns (IPriceProvider);

    /// @dev this is info method for LiquidationHelper
    /// @return bool TRUE if provider is off-chain, means it is not a dex
    function offChainProvider() external pure returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;


library Ping {
    function pong(function() external pure returns(bytes4) pingFunction) internal pure returns (bool) {
        return pingFunction.address != address(0) && pingFunction.selector == pingFunction();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../PriceProvider.sol";
import "../IERC20LikeV2.sol";
import "../../external/dia/IDIAOracleV2.sol";
import "../../interfaces/IPriceProviderV2.sol";

contract DiaPriceProvider is IPriceProviderV2, PriceProvider {
    /// @dev price provider needs to return prices in ETH, but assets prices provided by DIA are in USD
    /// Under ETH_USD_KEY we will find ETH price in USD so we can convert price in USD into price in ETH
    string public constant ETH_USD_KEY = "ETH/USD";

    /// @dev decimals in DIA oracle
    uint256 public constant DIA_DECIMALS = 1e8;

    /// @dev decimals in Silo protocol
    uint256 public immutable EXPECTED_DECIMALS; // solhint-disable-line var-name-mixedcase

    /// @dev Oracle deployed for Silo by DIA, all our prices will be submitted to this contract
    IDIAOracleV2 public immutable DIA_ORACLEV2; // solhint-disable-line var-name-mixedcase

    /// @dev Address of asset that we will be using as reference for USD
    address public immutable USD_ASSET; // solhint-disable-line var-name-mixedcase

    /// @dev we accessing prices for assets by keys eg. "Jones/USD"
    mapping (address => string) public keys;

    /// @dev asset => fallbackProvider
    mapping(address => IPriceProvider) public liquidationProviders;

    event AssetSetup(address indexed asset, string key);

    event LiquidationProvider(address indexed asset, IPriceProvider indexed liquidationProvider);

    error MissingETHPrice();
    error InvalidKey();
    error CanNotSetEthKey();
    error OnlyUSDPriceAccepted();
    error PriceCanNotBeFoundForProvidedKey();
    error OldPrice();
    error MissingPriceOrSetup();
    error LiquidationProviderAlreadySet();
    error AssetNotSupported();
    error LiquidationProviderAssetNotSupported();
    error LiquidationProviderNotExist();
    error KeyDoesNotMatchSymbol();
    error FallbackPriceProviderNotSet();

    /// @param _priceProvidersRepository IPriceProvidersRepository
    /// @param _diaOracle IDIAOracleV2 address of DIA oracle contract
    /// @param _stableAsset address Address of asset that we will be using as reference for USD
    /// it has no affect on any price, this is only for be able to getPrice(_usdAsset) using `ETH_USD_KEY` key
    constructor(
        IPriceProvidersRepository _priceProvidersRepository,
        IDIAOracleV2 _diaOracle,
        address _stableAsset
    )
        PriceProvider(_priceProvidersRepository)
    {
        EXPECTED_DECIMALS = 10 ** IERC20LikeV2(_priceProvidersRepository.quoteToken()).decimals();
        USD_ASSET = _stableAsset;
        DIA_ORACLEV2 = _diaOracle;

        bool allowEthUsdKey = true;
        _setupAsset(_stableAsset, ETH_USD_KEY, IPriceProvider(address(0)), allowEthUsdKey);
    }

    /// @inheritdoc IPriceProvider
    function assetSupported(address _asset) public view virtual override returns (bool) {
        return bytes(keys[_asset]).length != 0;
    }

    /// @param _key string under this key asset price will be available in DIA oracle
    /// @return assetPriceInUsd uint128 asset price
    /// @return priceUpToDate bool TRUE if price is up to date (acceptable), FALSE otherwise
    function getPriceForKey(string memory _key)
        public
        view
        virtual
        returns (uint128 assetPriceInUsd, bool priceUpToDate)
    {
        uint128 priceTimestamp;
        (assetPriceInUsd, priceTimestamp) = DIA_ORACLEV2.getValue(_key);

        // price must be updated at least once every 24h, otherwise something is wrong
        uint256 oldestAcceptedPriceTimestamp;
        // block.timestamp is more than 1 day, so we can not underflow
        unchecked { oldestAcceptedPriceTimestamp = block.timestamp - 1 days; }

        // we not checking assetPriceInUsd != 0, because this is checked on setup, so it will be always some value here
        priceUpToDate = priceTimestamp > oldestAcceptedPriceTimestamp;
    }

    function getFallbackPrice(address _asset) public view virtual returns (uint256) {
        IPriceProvider fallbackProvider = liquidationProviders[_asset];

        if (address(fallbackProvider) != address(0)) {
            return fallbackProvider.getPrice(_asset);
        }

        revert FallbackPriceProviderNotSet();
    }

    /// @inheritdoc IPriceProvider
    function getPrice(address _asset) public view virtual override returns (uint256) {
        string memory key = keys[_asset];

        if (bytes(key).length == 0) revert AssetNotSupported();

        (uint128 assetPriceInUsd, bool priceUpToDate) = getPriceForKey(key);

        if (!priceUpToDate) {
            return getFallbackPrice(_asset);
        }

        if (_asset == USD_ASSET) {
            unchecked {
                // multiplication of decimals is safe, this are small values, division is safe as well
                return DIA_DECIMALS * EXPECTED_DECIMALS / assetPriceInUsd;
            }
        }

        (uint128 ethPriceInUsd, bool ethPriceUpToDate) = getPriceForKey(ETH_USD_KEY);

        if (!ethPriceUpToDate) {
            return getFallbackPrice(_asset);
        }

        return normalizePrice(assetPriceInUsd, ethPriceInUsd);
    }

    /// @dev Asset setup. Can only be called by the manager.
    /// Explanation from DIA team:
    ///     Updates will be done every time there is a deviation >1% btw the last onchain update and the current price.
    ///     We have a 24hrs default update though, so assuming the price remains completely flat you would still get
    ///     an update every 24hrs.
    /// @param _asset address Asset to setup
    /// @param _key string under this key asset price will be available in DIA oracle
    /// @param _liquidationProvider IPriceProvider on-chain provider that can help with liquidation
    /// it will not be use for providing price, it is only for liquidation process
    function setupAsset(
        address _asset,
        string calldata _key,
        IPriceProvider _liquidationProvider
    ) external virtual onlyManager {
        validateSymbol(_asset, _key);

        bool allowEthUsdKey;
        _setupAsset(_asset, _key, _liquidationProvider, allowEthUsdKey);
    }
    
    function setLiquidationProvider(address _asset, IPriceProvider _liquidationProvider) public virtual onlyManager {
        _setLiquidationProvider(_asset, _liquidationProvider);
    }

    function removeLiquidationProvider(address _asset) public virtual onlyManager {
        if (address(0) == address(liquidationProviders[_asset])) revert LiquidationProviderNotExist();

        delete liquidationProviders[_asset];

        emit LiquidationProvider(_asset, IPriceProvider(address(0)));
    }

    /// @dev for liquidation purposes and for compatibility with naming convention we already using in LiquidationHelper
    /// we have this method to return on-chain provider that can be useful for liquidation
    function getFallbackProvider(address _asset) external view virtual returns (IPriceProvider) {
        return liquidationProviders[_asset];
    }

    /// @dev _assetPriceInUsd uint128 asset price returned by DIA oracle (8 decimals)
    /// @dev _ethPriceInUsd uint128 ETH price returned by DIA oracle (8 decimals)
    /// @return assetPriceInEth uint256 18 decimals price in ETH
    function normalizePrice(uint128 _assetPriceInUsd, uint128 _ethPriceInUsd)
        public
        view
        virtual
        returns (uint256 assetPriceInEth)
    {
        uint256 withDecimals = _assetPriceInUsd * EXPECTED_DECIMALS;

        unchecked {
            // div is safe
            return withDecimals / _ethPriceInUsd;
        }
    }

    /// @dev checks if key has expected format.
    /// Atm provider is accepting only prices in USD, so key must end with "/USD".
    /// If key is invalid function will throw.
    /// @param _key string DIA key for asset
    function validateKey(string memory _key) public pure virtual {
        _validateKey(_key, false);
    }

    /// @dev checks if key match token symbol. Reverts if does not match.
    /// @param _asset address Asset to setup
    /// @param _key string under this key asset price will be available in DIA oracle
    function validateSymbol(address _asset, string memory _key) public view virtual {
        bytes memory symbol = bytes(IERC20Metadata(_asset).symbol());

        unchecked {
            // `+4` for `/USD`, we will never have key with length that will overflow
            if (symbol.length + 4 != bytes(_key).length) revert KeyDoesNotMatchSymbol();

            // we will never have key with length that will overflow, so i++ is safe
            for (uint256 i; i < symbol.length; i++) {
                if (symbol[i] != bytes(_key)[i]) revert KeyDoesNotMatchSymbol();
            }
        }
    }

    /// @dev this is info method for LiquidationHelper
    /// @return bool TRUE if provider is off-chain, means it is not a dex
    function offChainProvider() external pure virtual returns (bool) {
        return true;
    }

    /// @param _allowEthUsd bool use TRUE only when setting up `ETH_USD_KEY` key, FALSE in all other cases
    // solhint-disable-next-line code-complexity
    function _validateKey(string memory _key, bool _allowEthUsd) internal pure virtual {
        if (!_allowEthUsd) {
            if (keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked(ETH_USD_KEY))) revert CanNotSetEthKey();
        }

        uint256 keyLength = bytes(_key).length;

        if (keyLength < 5) revert InvalidKey();

        unchecked {
            // keyLength is at least 5, based on above check, so it is safe to uncheck all below subtractions
            if (bytes(_key)[keyLength - 4] != "/") revert OnlyUSDPriceAccepted();
            if (bytes(_key)[keyLength - 3] != "U") revert OnlyUSDPriceAccepted();
            if (bytes(_key)[keyLength - 2] != "S") revert OnlyUSDPriceAccepted();
            if (bytes(_key)[keyLength - 1] != "D") revert OnlyUSDPriceAccepted();
        }
    }

    /// @param _asset Asset to setup
    /// @param _key string under this key asset price will be available in DIA oracle
    /// @param _liquidationProvider IPriceProvider on-chain provider that can help with liquidation
    /// it will not be use for providing price, it is only for liquidation process
    /// @param _allowEthUsd bool use TRUE only when setting up `ETH_USD_KEY` key, FALSE in all other cases
    function _setupAsset(
        address _asset,
        string memory _key,
        IPriceProvider _liquidationProvider,
        bool _allowEthUsd
    ) internal virtual {
        _validateKey(_key, _allowEthUsd);

        (uint128 latestPrice, bool priceUpToDate) = getPriceForKey(_key);

        if (latestPrice == 0) revert PriceCanNotBeFoundForProvidedKey();
        if (!priceUpToDate) revert OldPrice();

        keys[_asset] = _key;

        emit AssetSetup(_asset, _key);

        if (address(_liquidationProvider) != address(0)) {
            _setLiquidationProvider(_asset, _liquidationProvider);
        }
    }

    function _setLiquidationProvider(address _asset, IPriceProvider _liquidationProvider) internal virtual {
        if (!assetSupported(_asset)) revert AssetNotSupported();
        if (_liquidationProvider == liquidationProviders[_asset]) revert LiquidationProviderAlreadySet();
        if (!_liquidationProvider.assetSupported(_asset)) revert LiquidationProviderAssetNotSupported();

        liquidationProviders[_asset] = _liquidationProvider;

        emit LiquidationProvider(_asset, _liquidationProvider);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6;

/// @dev This is only meant to be used by price providers, which use a different
/// Solidity version than the rest of the codebase. This way de won't need to include
/// an additional version of OpenZeppelin's library.
interface IERC20LikeV2 {
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns(uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

import "../lib/Ping.sol";
import "../interfaces/IPriceProvider.sol";
import "../interfaces/IPriceProvidersRepository.sol";

/// @title PriceProvider
/// @notice Abstract PriceProvider contract, parent of all PriceProviders
/// @dev Price provider is a contract that directly integrates with a price source, ie. a DEX or alternative system
/// like Chainlink to calculate TWAP prices for assets. Each price provider should support a single price source
/// and multiple assets.
abstract contract PriceProvider is IPriceProvider {
    /// @notice PriceProvidersRepository address
    IPriceProvidersRepository public immutable priceProvidersRepository;

    /// @notice Token address which prices are quoted in. Must be the same as PriceProvidersRepository.quoteToken
    address public immutable override quoteToken;

    modifier onlyManager() {
        if (priceProvidersRepository.manager() != msg.sender) revert("OnlyManager");
        _;
    }

    /// @param _priceProvidersRepository address of PriceProvidersRepository
    constructor(IPriceProvidersRepository _priceProvidersRepository) {
        if (
            !Ping.pong(_priceProvidersRepository.priceProvidersRepositoryPing)            
        ) {
            revert("InvalidPriceProviderRepository");
        }

        priceProvidersRepository = _priceProvidersRepository;
        quoteToken = _priceProvidersRepository.quoteToken();
    }

    /// @inheritdoc IPriceProvider
    function priceProviderPing() external pure override returns (bytes4) {
        return this.priceProviderPing.selector;
    }

    function _revertBytes(bytes memory _errMsg, string memory _customErr) internal pure {
        if (_errMsg.length > 0) {
            assembly { // solhint-disable-line no-inline-assembly
                revert(add(32, _errMsg), mload(_errMsg))
            }
        }

        revert(_customErr);
    }
}