// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "joe-v2/libraries/Math512Bits.sol";
import "joe-v2/libraries/Constants.sol";
import "joe-v2/libraries/PendingOwnable.sol";
import "joe-v2/interfaces/ILBPair.sol";
import "joe-v2/interfaces/IJoePair.sol";
import "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

import "./interfaces/IJoeDexLens.sol";

/// @title Joe Dex Lens
/// @author Trader Joe
/// @notice This contract allows to price tokens in either Native or USDC. It could be easily extended to any collateral.
/// Owners can add or remove data feeds to price a token and can set the weight of the different data feeds.
/// When no data feed is provided, the contract will use the TOKEN/WNative and TOKEN/USDC V1 pool to try to price the asset
contract JoeDexLens is PendingOwnable, IJoeDexLens {
    using Math512Bits for uint256;

    uint256 constant DECIMALS = 18;
    uint256 constant PRECISION = 10**DECIMALS;

    ILBRouter private immutable _ROUTER_V2;
    IJoeFactory private immutable _FACTORY_V1;

    address private immutable _WNATIVE;
    address private immutable _USDC;

    /// @dev Mapping from a collateral token to a token to an enumerable set of data feeds used to get the price of the token in collateral
    /// e.g. USDC => Native will return datafeeds to get the price of Native in USD
    /// And Native => JOE will return datafeeds to get the price of JOE in Native
    mapping(address => mapping(address => DataFeedSet)) private _whitelistedDataFeeds;

    /** Modifiers **/

    /// @notice Verify that the two lengths match
    /// @dev Revert if length are not equal
    /// @param _lengthA The length of the first list
    /// @param _lengthB The length of the second list
    modifier verifyLengths(uint256 _lengthA, uint256 _lengthB) {
        if (_lengthA != _lengthB) revert JoeDexLens__LengthsMismatch();
        _;
    }

    /// @notice Verify a data feed
    /// @dev Revert if :
    /// - The _collateral and the _token are the same address
    /// - The _collateral is not one of the two tokens of the pair (if the dfType is V1 or V2)
    /// - The _token is not one of the two tokens of the pair (if the dfType is V1 or V2)
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _token The address of the token
    /// @param _dataFeed The data feeds information
    modifier verifyDataFeed(
        address _collateral,
        address _token,
        DataFeed calldata _dataFeed
    ) {
        if (_collateral == _token) revert JoeDexLens__SameTokens();

        if (_dataFeed.dfType != dfType.CHAINLINK) {
            (address tokenA, address tokenB) = _getTokens(_dataFeed);

            if (tokenA != _collateral && tokenB != _collateral)
                revert JoeDexLens__CollateralNotInPair(_dataFeed.dfAddress, _collateral);
            if (tokenA != _token && tokenB != _token) revert JoeDexLens__TokenNotInPair(_dataFeed.dfAddress, _token);
        }
        _;
    }

    /// @notice Verify the weight for a data feed
    /// @dev Revert if the weight is equal to 0
    /// @param weight The weight of a data feed
    modifier verifyWeight(uint88 weight) {
        if (weight == 0) revert JoeDexLens__NullWeight();
        _;
    }

    /** Constructor **/

    constructor(
        ILBRouter _routerV2,
        IJoeFactory _factoryV1,
        address _wNative,
        address _usdc
    ) {
        _ROUTER_V2 = _routerV2;
        _FACTORY_V1 = _factoryV1;
        _WNATIVE = _wNative;
        _USDC = _usdc;
    }

    /** External View Functions **/

    /// @notice Returns the address of the router V2
    /// @return routerV2 The address of the router V2
    function getRouterV2() external view override returns (ILBRouter routerV2) {
        return _ROUTER_V2;
    }

    /// @notice Returns the address of the factory V1
    /// @return factoryV1 The address of the factory V1
    function getFactoryV1() external view override returns (IJoeFactory factoryV1) {
        return _FACTORY_V1;
    }

    /// @notice Returns the list of data feeds used to calculate the price of the token in USD
    /// @param _token The address of the token
    /// @return dataFeeds The array of data feeds used to price `token` in USD
    function getUSDDataFeeds(address _token) external view override returns (DataFeed[] memory dataFeeds) {
        return _whitelistedDataFeeds[_USDC][_token].dataFeeds;
    }

    /// @notice Returns the list of data feeds used to calculate the price of the token in Native
    /// @param _token The address of the token
    /// @return dataFeeds The array of data feeds used to price `token` in Native
    function getNativeDataFeeds(address _token) external view override returns (DataFeed[] memory dataFeeds) {
        return _whitelistedDataFeeds[_WNATIVE][_token].dataFeeds;
    }

    /// @notice Returns the price of token in USD, scaled with 6 decimals
    /// @param _token The address of the token
    /// @return price The price of the token in USD, with 6 decimals
    function getTokenPriceUSD(address _token) external view override returns (uint256 price) {
        return _getTokenWeightedAveragePrice(_USDC, _token);
    }

    /// @notice Returns the price of token in Native, scaled with `DECIMALS` decimals
    /// @param _token The address of the token
    /// @return price The price of the token in Native, with `DECIMALS` decimals
    function getTokenPriceNative(address _token) external view override returns (uint256 price) {
        return _getTokenWeightedAveragePrice(_WNATIVE, _token);
    }

    /// @notice Returns the prices of each token in USD, scaled with 6 decimals
    /// @param _tokens The list of address of the tokens
    /// @return prices The prices of each token in USD, with 6 decimals
    function getTokensPricesUSD(address[] calldata _tokens) external view override returns (uint256[] memory prices) {
        return _getTokenWeightedAveragePrices(_USDC, _tokens);
    }

    /// @notice Returns the prices of each token in Native, scaled with `DECIMALS` decimals
    /// @param _tokens The list of address of the tokens
    /// @return prices The prices of each token in Native, with `DECIMALS` decimals
    function getTokensPricesNative(address[] calldata _tokens)
        external
        view
        override
        returns (uint256[] memory prices)
    {
        return _getTokenWeightedAveragePrices(_WNATIVE, _tokens);
    }

    /** Owner Functions **/

    /// @notice Add a USD data feed for a specific token
    /// @dev Can only be called by the owner
    /// @param _token The address of the token
    /// @param _dataFeed The USD data feeds information
    function addUSDDataFeed(address _token, DataFeed calldata _dataFeed) external override onlyOwner {
        _addDataFeed(_USDC, _token, _dataFeed);
    }

    /// @notice Add a Native data feed for a specific token
    /// @dev Can only be called by the owner
    /// @param _token The address of the token
    /// @param _dataFeed The Native data feeds information
    function addNativeDataFeed(address _token, DataFeed calldata _dataFeed) external override onlyOwner {
        _addDataFeed(_WNATIVE, _token, _dataFeed);
    }

    /// @notice Set the USD weight for a specific data feed of a token
    /// @dev Can only be called by the owner
    /// @param _token The address of the token
    /// @param _dfAddress The USD data feed address
    /// @param _newWeight The new weight of the data feed
    function setUSDDataFeedWeight(
        address _token,
        address _dfAddress,
        uint88 _newWeight
    ) external override onlyOwner {
        _setDataFeedWeight(_USDC, _token, _dfAddress, _newWeight);
    }

    /// @notice Set the Native weight for a specific data feed of a token
    /// @dev Can only be called by the owner
    /// @param _token The address of the token
    /// @param _dfAddress The data feed address
    /// @param _newWeight The new weight of the data feed
    function setNativeDataFeedWeight(
        address _token,
        address _dfAddress,
        uint88 _newWeight
    ) external override onlyOwner {
        _setDataFeedWeight(_WNATIVE, _token, _dfAddress, _newWeight);
    }

    /// @notice Remove a USD data feed of a token
    /// @dev Can only be called by the owner
    /// @param _token The address of the token
    /// @param _dfAddress The USD data feed address
    function removeUSDDataFeed(address _token, address _dfAddress) external override onlyOwner {
        _removeDataFeed(_USDC, _token, _dfAddress);
    }

    /// @notice Remove a Native data feed of a token
    /// @dev Can only be called by the owner
    /// @param _token The address of the token
    /// @param _dfAddress The data feed address
    function removeNativeDataFeed(address _token, address _dfAddress) external override onlyOwner {
        _removeDataFeed(_WNATIVE, _token, _dfAddress);
    }

    /// @notice Batch add USD data feed for each (token, data feed)
    /// @dev Can only be called by the owner
    /// @param _tokens The addresses of the tokens
    /// @param _dataFeeds The list of USD data feeds informations
    function addUSDDataFeeds(address[] calldata _tokens, DataFeed[] calldata _dataFeeds) external override onlyOwner {
        _addDataFeeds(_USDC, _tokens, _dataFeeds);
    }

    /// @notice Batch add Native data feed for each (token, data feed)
    /// @dev Can only be called by the owner
    /// @param _tokens The addresses of the tokens
    /// @param _dataFeeds The list of Native data feeds informations
    function addNativeDataFeeds(address[] calldata _tokens, DataFeed[] calldata _dataFeeds)
        external
        override
        onlyOwner
    {
        _addDataFeeds(_WNATIVE, _tokens, _dataFeeds);
    }

    /// @notice Batch set the USD weight for each (token, data feed)
    /// @dev Can only be called by the owner
    /// @param _tokens The list of addresses of the tokens
    /// @param _dfAddresses The list of USD data feed addresses
    /// @param _newWeights The list of new weights of the data feeds
    function setUSDDataFeedsWeights(
        address[] calldata _tokens,
        address[] calldata _dfAddresses,
        uint88[] calldata _newWeights
    ) external override onlyOwner {
        _setDataFeedsWeights(_USDC, _tokens, _dfAddresses, _newWeights);
    }

    /// @notice Batch set the Native weight for each (token, data feed)
    /// @dev Can only be called by the owner
    /// @param _tokens The list of addresses of the tokens
    /// @param _dfAddresses The list of Native data feed addresses
    /// @param _newWeights The list of new weights of the data feeds
    function setNativeDataFeedsWeights(
        address[] calldata _tokens,
        address[] calldata _dfAddresses,
        uint88[] calldata _newWeights
    ) external override onlyOwner {
        _setDataFeedsWeights(_WNATIVE, _tokens, _dfAddresses, _newWeights);
    }

    /// @notice Batch remove a list of USD data feeds for each (token, data feed)
    /// @dev Can only be called by the owner
    /// @param _tokens The list of addresses of the tokens
    /// @param _dfAddresses The list of USD data feed addresses
    function removeUSDDataFeeds(address[] calldata _tokens, address[] calldata _dfAddresses)
        external
        override
        onlyOwner
    {
        _removeDataFeeds(_USDC, _tokens, _dfAddresses);
    }

    /// @notice Batch remove a list of Native data feeds for each (token, data feed)
    /// @dev Can only be called by the owner
    /// @param _tokens The list of addresses of the tokens
    /// @param _dfAddresses The list of Native data feed addresses
    function removeNativeDataFeeds(address[] calldata _tokens, address[] calldata _dfAddresses)
        external
        override
        onlyOwner
    {
        _removeDataFeeds(_WNATIVE, _tokens, _dfAddresses);
    }

    /** Private Functions **/

    /// @notice Returns the data feed length for a specific collateral and a token
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _token The address of the token
    /// @return length The number of data feeds
    function _getDataFeedsLength(address _collateral, address _token) private view returns (uint256 length) {
        return _whitelistedDataFeeds[_collateral][_token].dataFeeds.length;
    }

    /// @notice Returns the data feed at index `_index` for a specific collateral and a token
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _token The address of the token
    /// @param _index The index
    /// @return dataFeed the data feed at index `_index`
    function _getDataFeedAt(
        address _collateral,
        address _token,
        uint256 _index
    ) private view returns (DataFeed memory dataFeed) {
        return _whitelistedDataFeeds[_collateral][_token].dataFeeds[_index];
    }

    /// @notice Returns if a (tokens)'s set contains the data feed address
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _token The address of the token
    /// @param _dfAddress The data feed address
    /// @return Whether the set contains the data feed address (true) or not (false)
    function _dataFeedContains(
        address _collateral,
        address _token,
        address _dfAddress
    ) private view returns (bool) {
        return _whitelistedDataFeeds[_collateral][_token].indexes[_dfAddress] != 0;
    }

    /// @notice Add a data feed to a set, return true if it was added, false if not
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _token The address of the token
    /// @param _dataFeed The data feeds information
    /// @return Whether the data feed was added (true) to the set or not (false)
    function _addToSet(
        address _collateral,
        address _token,
        DataFeed calldata _dataFeed
    ) private returns (bool) {
        if (!_dataFeedContains(_collateral, _token, _dataFeed.dfAddress)) {
            DataFeedSet storage set = _whitelistedDataFeeds[_collateral][_token];

            set.dataFeeds.push(_dataFeed);
            set.indexes[_dataFeed.dfAddress] = set.dataFeeds.length;
            return true;
        } else {
            return false;
        }
    }

    /// @notice Remove a data feed from a set, returns true if it was removed, false if not
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _token The address of the token
    /// @param _dfAddress The data feed address
    /// @return Whether the data feed was removed (true) from the set or not (false)
    function _removeFromSet(
        address _collateral,
        address _token,
        address _dfAddress
    ) private returns (bool) {
        DataFeedSet storage set = _whitelistedDataFeeds[_collateral][_token];
        uint256 dataFeedIndex = set.indexes[_dfAddress];

        if (dataFeedIndex != 0) {
            uint256 toDeleteIndex = dataFeedIndex - 1;
            uint256 lastIndex = set.dataFeeds.length - 1;

            if (toDeleteIndex != lastIndex) {
                DataFeed memory lastDataFeed = set.dataFeeds[lastIndex];

                set.dataFeeds[toDeleteIndex] = lastDataFeed;
                set.indexes[lastDataFeed.dfAddress] = dataFeedIndex;
            }

            set.dataFeeds.pop();
            delete set.indexes[_dfAddress];

            return true;
        } else {
            return false;
        }
    }

    /// @notice Add a data feed to a set, revert if it couldn't add it
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _token The address of the token
    /// @param _dataFeed The data feeds information
    function _addDataFeed(
        address _collateral,
        address _token,
        DataFeed calldata _dataFeed
    ) private verifyDataFeed(_collateral, _token, _dataFeed) verifyWeight(_dataFeed.dfWeight) {
        if (!_addToSet(_collateral, _token, _dataFeed))
            revert JoeDexLens__DataFeedAlreadyAdded(_collateral, _token, _dataFeed.dfAddress);

        emit DataFeedAdded(_collateral, _token, _dataFeed);
    }

    /// @notice Batch add data feed for each (_collateral, token, data feed)
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _tokens The addresses of the tokens
    /// @param _dataFeeds The list of USD data feeds informations
    function _addDataFeeds(
        address _collateral,
        address[] calldata _tokens,
        DataFeed[] calldata _dataFeeds
    ) private verifyLengths(_tokens.length, _dataFeeds.length) {
        for (uint256 i; i < _tokens.length; ) {
            _addDataFeed(_collateral, _tokens[i], _dataFeeds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Set the weight for a specific data feed of a (collateral, token)
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _token The address of the token
    /// @param _dfAddress The data feed address
    /// @param _newWeight The new weight of the data feed
    function _setDataFeedWeight(
        address _collateral,
        address _token,
        address _dfAddress,
        uint88 _newWeight
    ) private verifyWeight(_newWeight) {
        DataFeedSet storage set = _whitelistedDataFeeds[_collateral][_token];

        uint256 index = set.indexes[_dfAddress];

        if (index == 0) revert JoeDexLens__DataFeedNotInSet(_collateral, _token, _dfAddress);

        set.dataFeeds[index - 1].dfWeight = _newWeight;

        emit DataFeedsWeightSet(_collateral, _token, _dfAddress, _newWeight);
    }

    /// @notice Batch set the weight for each (_collateral, token, data feed)
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _tokens The list of addresses of the tokens
    /// @param _dfAddresses The list of USD data feed addresses
    /// @param _newWeights The list of new weights of the data feeds
    function _setDataFeedsWeights(
        address _collateral,
        address[] calldata _tokens,
        address[] calldata _dfAddresses,
        uint88[] calldata _newWeights
    ) private verifyLengths(_tokens.length, _dfAddresses.length) verifyLengths(_tokens.length, _newWeights.length) {
        for (uint256 i; i < _tokens.length; ) {
            _setDataFeedWeight(_collateral, _tokens[i], _dfAddresses[i], _newWeights[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Remove a data feed from a set, revert if it couldn't remove it
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _token The address of the token
    /// @param _dfAddress The data feed address
    function _removeDataFeed(
        address _collateral,
        address _token,
        address _dfAddress
    ) private {
        if (!_removeFromSet(_collateral, _token, _dfAddress))
            revert JoeDexLens__DataFeedNotInSet(_collateral, _token, _dfAddress);

        emit DataFeedRemoved(_collateral, _token, _dfAddress);
    }

    /// @notice Batch remove a list of collateral data feeds for each (token, data feed)
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _tokens The list of addresses of the tokens
    /// @param _dfAddresses The list of USD data feed addresses
    function _removeDataFeeds(
        address _collateral,
        address[] calldata _tokens,
        address[] calldata _dfAddresses
    ) private verifyLengths(_tokens.length, _dfAddresses.length) {
        for (uint256 i; i < _tokens.length; ) {
            _removeDataFeed(_collateral, _tokens[i], _dfAddresses[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Return the weighted average price of a token using its collateral data feeds
    /// @dev If no data feed was provided, will use V1 TOKEN/Native and USDC/TOKEN pools to calculate the price of the token
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _token The address of the token
    /// @return price The weighted average price of the token, with the collateral's decimals
    function _getTokenWeightedAveragePrice(address _collateral, address _token) private view returns (uint256 price) {
        uint256 decimals = IERC20Metadata(_collateral).decimals();
        if (_collateral == _token) return 10**decimals;

        uint256 length = _getDataFeedsLength(_collateral, _token);
        if (length == 0) return _getPriceAnyToken(_collateral, _token);

        uint256 dfPrice;
        uint256 totalWeights;
        for (uint256 i; i < length; ) {
            DataFeed memory dataFeed = _getDataFeedAt(_collateral, _token, i);

            if (dataFeed.dfType == dfType.V1) {
                dfPrice = _getPriceFromV1(dataFeed.dfAddress, _token);
            } else if (dataFeed.dfType == dfType.V2) {
                dfPrice = _getPriceFromV2(dataFeed.dfAddress, _token);
            } else if (dataFeed.dfType == dfType.CHAINLINK) {
                dfPrice = _getPriceFromChainlink(dataFeed.dfAddress);
            } else revert JoeDexLens__UnknownDataFeedType();

            price += dfPrice * dataFeed.dfWeight;
            totalWeights += dataFeed.dfWeight;

            unchecked {
                ++i;
            }
        }

        price /= totalWeights;

        // Return the price with the collateral's decimals
        if (decimals < DECIMALS) price /= 10**(DECIMALS - decimals);
        else if (decimals > DECIMALS) price *= 10**(decimals - DECIMALS);
    }

    /// @notice Batch function to return the weighted average price of each tokens using its collateral data feeds
    /// @dev If no data feed was provided, will use V1 TOKEN/Native and USDC/TOKEN pools to calculate the price of the token
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _tokens The list of addresses of the tokens
    /// @return prices The list of weighted average price of each token, with the collateral's decimals
    function _getTokenWeightedAveragePrices(address _collateral, address[] calldata _tokens)
        private
        view
        returns (uint256[] memory prices)
    {
        prices = new uint256[](_tokens.length);
        for (uint256 i; i < _tokens.length; ) {
            prices[i] = _getTokenWeightedAveragePrice(_collateral, _tokens[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Return the price tracked by the aggreagator using chainlink's data feed, with `DECIMALS` decimals
    /// @param _dfAddress The address of the data feed
    /// @return price The price tracked by the aggreagator, with `DECIMALS` decimals
    function _getPriceFromChainlink(address _dfAddress) private view returns (uint256 price) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(_dfAddress);

        (, int256 sPrice, , , ) = aggregator.latestRoundData();
        if (sPrice <= 0) revert JoeDexLens__InvalidChainLinkPrice();

        price = uint256(sPrice);

        uint256 aggregatorDecimals = aggregator.decimals();

        // Return the price with `DECIMALS` decimals
        if (aggregatorDecimals < DECIMALS) price *= 10**(DECIMALS - aggregatorDecimals);
        else if (aggregatorDecimals > DECIMALS) price /= 10**(aggregatorDecimals - DECIMALS);
    }

    /// @notice Return the price of the token denominated in the second token of the V1 pair, with `DECIMALS` decimals
    /// @dev The `token` token needs to be on of the two paired token of the given pair
    /// @param _pairAddress The address of the pair
    /// @param _token The address of the token
    /// @return price The price of the token, with `DECIMALS` decimals
    function _getPriceFromV1(address _pairAddress, address _token) private view returns (uint256 price) {
        IJoePair pair = IJoePair(_pairAddress);

        address token0 = pair.token0();
        address token1 = pair.token1();

        uint256 decimals0 = IERC20Metadata(token0).decimals();
        uint256 decimals1 = IERC20Metadata(token1).decimals();

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        // Return the price with `DECIMALS` decimals
        if (_token == token0) {
            return (reserve1 * 10**(decimals0 + DECIMALS)) / (reserve0 * 10**decimals1);
        } else if (_token == token1) {
            return (reserve0 * 10**(decimals1 + DECIMALS)) / (reserve1 * 10**decimals0);
        } else revert JoeDexLens__WrongPair();
    }

    /// @notice Return the price of the token denominated in the second token of the V2 pair, with `DECIMALS` decimals
    /// @dev The `token` token needs to be on of the two paired token of the given pair
    /// @param _pairAddress The address of the pair
    /// @param _token The address of the token
    /// @return price The price of the token, with `DECIMALS` decimals
    function _getPriceFromV2(address _pairAddress, address _token) private view returns (uint256 price) {
        ILBPair pair = ILBPair(_pairAddress);

        (, , uint256 activeID) = pair.getReservesAndId();
        uint256 priceScaled = _ROUTER_V2.getPriceFromId(pair, uint24(activeID));

        address tokenX = address(pair.tokenX());
        address tokenY = address(pair.tokenY());

        uint256 decimalsX = IERC20Metadata(tokenX).decimals();
        uint256 decimalsY = IERC20Metadata(tokenY).decimals();

        // Return the price with `DECIMALS` decimals
        if (_token == tokenX) {
            return priceScaled.mulShiftRoundDown(10**(18 + decimalsX - decimalsY), Constants.SCALE_OFFSET);
        } else if (_token == tokenY) {
            return
                (type(uint256).max / priceScaled).mulShiftRoundDown(
                    10**(18 + decimalsY - decimalsX),
                    Constants.SCALE_OFFSET
                );
        } else revert JoeDexLens__WrongPair();
    }

    /// @notice Return the addresses of the two tokens of a pair
    /// @dev Work with both V1 or V2 pairs
    /// @param _dataFeed The data feeds information
    /// @return tokenA The address of the first token of the pair
    /// @return tokenB The address of the second token of the pair
    function _getTokens(DataFeed calldata _dataFeed) private view returns (address tokenA, address tokenB) {
        if (_dataFeed.dfType == dfType.V1) {
            IJoePair pair = IJoePair(_dataFeed.dfAddress);

            tokenA = pair.token0();
            tokenB = pair.token1();
        } else if (_dataFeed.dfType == dfType.V2) {
            ILBPair pair = ILBPair(_dataFeed.dfAddress);

            tokenA = address(pair.tokenX());
            tokenB = address(pair.tokenY());
        } else revert JoeDexLens__UnknownDataFeedType();
    }

    /// @notice Return the price of a token using TOKEN/Native and TOKEN/USDC V1 pairs, with `DECIMALS` decimals
    /// @dev If only one pair is available, will return the price on this pair, and will revert if no pools were created
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _token The address of the token
    /// @return price The weighted average, based on pair's liquidity, of the token with the collateral's decimals
    function _getPriceAnyToken(address _collateral, address _token) private view returns (uint256 price) {
        address pairTokenWNative = _FACTORY_V1.getPair(_token, _WNATIVE);
        address pairTokenUsdc = _FACTORY_V1.getPair(_token, _USDC);

        if (pairTokenWNative != address(0) && pairTokenUsdc != address(0)) {
            uint256 priceOfNative = _getTokenWeightedAveragePrice(_collateral, _WNATIVE);
            uint256 priceOfUSDC = _getTokenWeightedAveragePrice(_collateral, _USDC);

            uint256 priceInUSDC = _getPriceFromV1(pairTokenUsdc, _token);
            uint256 priceInNative = _getPriceFromV1(pairTokenWNative, _token);

            uint256 totalReserveInUSDC = _getReserveInTokenAFromV1(pairTokenUsdc, _USDC, _token);
            uint256 totalReserveinWNative = _getReserveInTokenAFromV1(pairTokenWNative, _WNATIVE, _token);

            uint256 weightUSDC = (totalReserveInUSDC * priceOfUSDC) / PRECISION;
            uint256 weightWNative = (totalReserveinWNative * priceOfNative) / PRECISION;

            uint256 totalWeights;
            uint256 weightedPriceUSDC = (priceInUSDC * priceOfUSDC * weightUSDC) / PRECISION;
            if (weightedPriceUSDC != 0) totalWeights += weightUSDC;

            uint256 weightedPriceNative = (priceInNative * priceOfNative * weightWNative) / PRECISION;
            if (weightedPriceNative != 0) totalWeights += weightWNative;

            if (totalWeights == 0) revert JoeDexLens__NotEnoughLiquidity();

            return (weightedPriceUSDC + weightedPriceNative) / totalWeights;
        } else if (pairTokenWNative != address(0)) {
            return _getPriceInCollateralFromV1(_collateral, pairTokenWNative, _WNATIVE, _token);
        } else if (pairTokenUsdc != address(0)) {
            return _getPriceInCollateralFromV1(_collateral, pairTokenUsdc, _USDC, _token);
        } else revert JoeDexLens__PairsNotCreated();
    }

    /// @notice Return the price in collateral of a token from a V1 pair
    /// @param _collateral The address of the collateral (USDC or WNATIVE)
    /// @param _pairAddress The address of the V1 pair
    /// @param _tokenBase The address of the base token of the pair, i.e. the collateral one
    /// @param _token The address of the token
    /// @return priceInCollateral The price of the token in collateral, with the collateral's decimals
    function _getPriceInCollateralFromV1(
        address _collateral,
        address _pairAddress,
        address _tokenBase,
        address _token
    ) private view returns (uint256 priceInCollateral) {
        uint256 priceInBase = _getPriceFromV1(_pairAddress, _token);
        uint256 priceOfBase = _getTokenWeightedAveragePrice(_collateral, _tokenBase);

        // Return the price with the collateral's decimals
        return (priceInBase * priceOfBase) / PRECISION;
    }

    /// @notice Return the entire TVL of a pair in token A, with `DECIMALS` decimals
    /// @dev tokenA and tokenB needs to be the two tokens paired in the given pair
    /// @param _pairAddress The address of the pair
    /// @param _tokenA The address of one of the pair's token
    /// @param _tokenB The address of the other pair's token
    /// @return totalReserveInTokenA The total reserve of the pool in token A
    function _getReserveInTokenAFromV1(
        address _pairAddress,
        address _tokenA,
        address _tokenB
    ) private view returns (uint256 totalReserveInTokenA) {
        IJoePair pair = IJoePair(_pairAddress);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint8 decimals = IERC20Metadata(_tokenA).decimals();

        if (_tokenA < _tokenB) totalReserveInTokenA = reserve0 * 2;
        else totalReserveInTokenA = reserve1 * 2;

        if (decimals < DECIMALS) totalReserveInTokenA *= 10**(DECIMALS - decimals);
        else if (decimals > DECIMALS) totalReserveInTokenA /= 10**(decimals - DECIMALS);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "joe-v2/LBErrors.sol";

error JoeDexLens__PairsNotCreated();
error JoeDexLens__UnknownDataFeedType();
error JoeDexLens__CollateralNotInPair(address pair, address collateral);
error JoeDexLens__TokenNotInPair(address pair, address token);
error JoeDexLens__SameTokens();
error JoeDexLens__DataFeedAlreadyAdded(address colateral, address token, address dataFeed);
error JoeDexLens__DataFeedNotInSet(address colateral, address token, address dataFeed);
error JoeDexLens__LengthsMismatch();
error JoeDexLens__NullWeight();
error JoeDexLens__WrongPair();
error JoeDexLens__InvalidChainLinkPrice();
error JoeDexLens__NotEnoughLiquidity();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "joe-v2/interfaces/ILBRouter.sol";
import "joe-v2/interfaces/IJoeFactory.sol";
import "joe-v2/interfaces/IPendingOwnable.sol";

import "../JoeDexLensErrors.sol";
import "../interfaces/AggregatorV3Interface.sol";

/// @title Interface of the Joe Dex Lens contract
/// @author Trader Joe
/// @notice The interface needed to interract with the Joe Dex Lens contract
interface IJoeDexLens is IPendingOwnable {
    /// @notice Enumerators of the different data feed types
    enum dfType {
        V1,
        V2,
        CHAINLINK
    }

    /// @notice Structure for data feeds, contains the data feed's address and its type.
    /// For V1/V2, the`dfAddress` should be the address of the pair
    /// For chainlink, the `dfAddress` should be the address of the aggregator
    struct DataFeed {
        address dfAddress;
        uint88 dfWeight;
        dfType dfType;
    }

    /// @notice Structure for a set of data feeds
    /// `datafeeds` is the list of addresses of all the data feeds
    /// `indexes` is a mapping linking the address of a data feed to its index in the `datafeeds` list.
    struct DataFeedSet {
        DataFeed[] dataFeeds;
        mapping(address => uint256) indexes;
    }

    event DataFeedAdded(address collateral, address token, DataFeed dataFeed);

    event DataFeedsWeightSet(address collateral, address token, address dfAddress, uint256 weight);

    event DataFeedRemoved(address collateral, address token, address dfAddress);

    function getRouterV2() external view returns (ILBRouter routerV2);

    function getFactoryV1() external view returns (IJoeFactory factoryV1);

    function getUSDDataFeeds(address token) external view returns (DataFeed[] memory dataFeeds);

    function getNativeDataFeeds(address token) external view returns (DataFeed[] memory dataFeeds);

    function getTokenPriceUSD(address token) external view returns (uint256 price);

    function getTokenPriceNative(address token) external view returns (uint256 price);

    function getTokensPricesUSD(address[] calldata tokens) external view returns (uint256[] memory prices);

    function getTokensPricesNative(address[] calldata tokens) external view returns (uint256[] memory prices);

    function addUSDDataFeed(address token, DataFeed calldata dataFeed) external;

    function addNativeDataFeed(address token, DataFeed calldata dataFeed) external;

    function setUSDDataFeedWeight(
        address token,
        address dfAddress,
        uint88 newWeight
    ) external;

    function setNativeDataFeedWeight(
        address token,
        address dfAddress,
        uint88 newWeight
    ) external;

    function removeUSDDataFeed(address token, address dfAddress) external;

    function removeNativeDataFeed(address token, address dfAddress) external;

    function addUSDDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds) external;

    function addNativeDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds) external;

    function setUSDDataFeedsWeights(
        address[] calldata _tokens,
        address[] calldata _dfAddresses,
        uint88[] calldata _newWeights
    ) external;

    function setNativeDataFeedsWeights(
        address[] calldata _tokens,
        address[] calldata _dfAddresses,
        uint88[] calldata _newWeights
    ) external;

    function removeUSDDataFeeds(address[] calldata tokens, address[] calldata dfAddresses) external;

    function removeNativeDataFeeds(address[] calldata tokens, address[] calldata dfAddresses) external;
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
interface IERC165 {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/ILBPair.sol";

/** LBRouter errors */

error LBRouter__SenderIsNotWAVAX();
error LBRouter__PairNotCreated(address tokenX, address tokenY, uint256 binStep);
error LBRouter__WrongAmounts(uint256 amount, uint256 reserve);
error LBRouter__SwapOverflows(uint256 id);
error LBRouter__BrokenSwapSafetyCheck();
error LBRouter__NotFactoryOwner();
error LBRouter__TooMuchTokensIn(uint256 excess);
error LBRouter__BinReserveOverflows(uint256 id);
error LBRouter__IdOverflows(int256 id);
error LBRouter__LengthsMismatch();
error LBRouter__WrongTokenOrder();
error LBRouter__IdSlippageCaught(uint256 activeIdDesired, uint256 idSlippage, uint256 activeId);
error LBRouter__AmountSlippageCaught(uint256 amountXMin, uint256 amountX, uint256 amountYMin, uint256 amountY);
error LBRouter__IdDesiredOverflows(uint256 idDesired, uint256 idSlippage);
error LBRouter__FailedToSendAVAX(address recipient, uint256 amount);
error LBRouter__DeadlineExceeded(uint256 deadline, uint256 currentTimestamp);
error LBRouter__AmountSlippageBPTooBig(uint256 amountSlippage);
error LBRouter__InsufficientAmountOut(uint256 amountOutMin, uint256 amountOut);
error LBRouter__MaxAmountInExceeded(uint256 amountInMax, uint256 amountIn);
error LBRouter__InvalidTokenPath(address wrongToken);
error LBRouter__InvalidVersion(uint256 version);
error LBRouter__WrongAvaxLiquidityParameters(
    address tokenX,
    address tokenY,
    uint256 amountX,
    uint256 amountY,
    uint256 msgValue
);

/** LBToken errors */

error LBToken__SpenderNotApproved(address owner, address spender);
error LBToken__TransferFromOrToAddress0();
error LBToken__MintToAddress0();
error LBToken__BurnFromAddress0();
error LBToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);
error LBToken__LengthMismatch(uint256 accountsLength, uint256 idsLength);
error LBToken__SelfApproval(address owner);
error LBToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
error LBToken__TransferToSelf();

/** LBFactory errors */

error LBFactory__IdenticalAddresses(IERC20 token);
error LBFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset);
error LBFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset);
error LBFactory__AddressZero();
error LBFactory__LBPairAlreadyExists(IERC20 tokenX, IERC20 tokenY, uint256 _binStep);
error LBFactory__LBPairNotCreated(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
error LBFactory__DecreasingPeriods(uint16 filterPeriod, uint16 decayPeriod);
error LBFactory__ReductionFactorOverflows(uint16 reductionFactor, uint256 max);
error LBFactory__VariableFeeControlOverflows(uint16 variableFeeControl, uint256 max);
error LBFactory__BaseFeesBelowMin(uint256 baseFees, uint256 minBaseFees);
error LBFactory__FeesAboveMax(uint256 fees, uint256 maxFees);
error LBFactory__FlashLoanFeeAboveMax(uint256 fees, uint256 maxFees);
error LBFactory__BinStepRequirementsBreached(uint256 lowerBound, uint16 binStep, uint256 higherBound);
error LBFactory__ProtocolShareOverflows(uint16 protocolShare, uint256 max);
error LBFactory__FunctionIsLockedForUsers(address user);
error LBFactory__FactoryLockIsAlreadyInTheSameState();
error LBFactory__LBPairIgnoredIsAlreadyInTheSameState();
error LBFactory__BinStepHasNoPreset(uint256 binStep);
error LBFactory__SameFeeRecipient(address feeRecipient);
error LBFactory__SameFlashLoanFee(uint256 flashLoanFee);
error LBFactory__LBPairSafetyCheckFailed(address LBPairImplementation);
error LBFactory__SameImplementation(address LBPairImplementation);
error LBFactory__ImplementationNotSet();

/** LBPair errors */

error LBPair__InsufficientAmounts();
error LBPair__AddressZero();
error LBPair__AddressZeroOrThis();
error LBPair__CompositionFactorFlawed(uint256 id);
error LBPair__InsufficientLiquidityMinted(uint256 id);
error LBPair__InsufficientLiquidityBurned(uint256 id);
error LBPair__WrongLengths();
error LBPair__OnlyStrictlyIncreasingId();
error LBPair__OnlyFactory();
error LBPair__DistributionsOverflow();
error LBPair__OnlyFeeRecipient(address feeRecipient, address sender);
error LBPair__OracleNotEnoughSample();
error LBPair__AlreadyInitialized();
error LBPair__OracleNewSizeTooSmall(uint256 newSize, uint256 oracleSize);
error LBPair__FlashLoanCallbackFailed();
error LBPair__FlashLoanInvalidBalance();
error LBPair__FlashLoanInvalidToken();

/** BinHelper errors */

error BinHelper__BinStepOverflows(uint256 bp);
error BinHelper__IdOverflows();

/** Math128x128 errors */

error Math128x128__PowerUnderflow(uint256 x, int256 y);
error Math128x128__LogUnderflow();

/** Math512Bits errors */

error Math512Bits__MulDivOverflow(uint256 prod1, uint256 denominator);
error Math512Bits__ShiftDivOverflow(uint256 prod1, uint256 denominator);
error Math512Bits__MulShiftOverflow(uint256 prod1, uint256 offset);
error Math512Bits__OffsetOverflows(uint256 offset);

/** Oracle errors */

error Oracle__AlreadyInitialized(uint256 _index);
error Oracle__LookUpTimestampTooOld(uint256 _minTimestamp, uint256 _lookUpTimestamp);
error Oracle__NotInitialized();

/** PendingOwnable errors */

error PendingOwnable__NotOwner();
error PendingOwnable__NotPendingOwner();
error PendingOwnable__PendingOwnerAlreadySet();
error PendingOwnable__NoPendingOwner();
error PendingOwnable__AddressZero();

/** ReentrancyGuardUpgradeable errors */

error ReentrancyGuardUpgradeable__ReentrantCall();
error ReentrancyGuardUpgradeable__AlreadyInitialized();

/** SafeCast errors */

error SafeCast__Exceeds256Bits(uint256 x);
error SafeCast__Exceeds248Bits(uint256 x);
error SafeCast__Exceeds240Bits(uint256 x);
error SafeCast__Exceeds232Bits(uint256 x);
error SafeCast__Exceeds224Bits(uint256 x);
error SafeCast__Exceeds216Bits(uint256 x);
error SafeCast__Exceeds208Bits(uint256 x);
error SafeCast__Exceeds200Bits(uint256 x);
error SafeCast__Exceeds192Bits(uint256 x);
error SafeCast__Exceeds184Bits(uint256 x);
error SafeCast__Exceeds176Bits(uint256 x);
error SafeCast__Exceeds168Bits(uint256 x);
error SafeCast__Exceeds160Bits(uint256 x);
error SafeCast__Exceeds152Bits(uint256 x);
error SafeCast__Exceeds144Bits(uint256 x);
error SafeCast__Exceeds136Bits(uint256 x);
error SafeCast__Exceeds128Bits(uint256 x);
error SafeCast__Exceeds120Bits(uint256 x);
error SafeCast__Exceeds112Bits(uint256 x);
error SafeCast__Exceeds104Bits(uint256 x);
error SafeCast__Exceeds96Bits(uint256 x);
error SafeCast__Exceeds88Bits(uint256 x);
error SafeCast__Exceeds80Bits(uint256 x);
error SafeCast__Exceeds72Bits(uint256 x);
error SafeCast__Exceeds64Bits(uint256 x);
error SafeCast__Exceeds56Bits(uint256 x);
error SafeCast__Exceeds48Bits(uint256 x);
error SafeCast__Exceeds40Bits(uint256 x);
error SafeCast__Exceeds32Bits(uint256 x);
error SafeCast__Exceeds24Bits(uint256 x);
error SafeCast__Exceeds16Bits(uint256 x);
error SafeCast__Exceeds8Bits(uint256 x);

/** TreeMath errors */

error TreeMath__ErrorDepthSearch();

/** JoeLibrary errors */

error JoeLibrary__IdenticalAddresses();
error JoeLibrary__AddressZero();
error JoeLibrary__InsufficientAmount();
error JoeLibrary__InsufficientLiquidity();

/** TokenHelper errors */

error TokenHelper__NonContract();
error TokenHelper__CallFailed();
error TokenHelper__TransferFailed();

/** LBQuoter errors */

error LBQuoter_InvalidLength();

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/// @title Joe V1 Factory Interface
/// @notice Interface to interact with Joe V1 Factory
interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/// @title Joe V1 Pair Interface
/// @notice Interface to interact with Joe V1 Pairs
interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "openzeppelin/token/ERC20/IERC20.sol";

import "./ILBPair.sol";
import "./IPendingOwnable.sol";

/// @title Liquidity Book Factory Interface
/// @author Trader Joe
/// @notice Required interface of LBFactory contract
interface ILBFactory is IPendingOwnable {
    /// @dev Structure to store the LBPair information, such as:
    /// - binStep: The bin step of the LBPair
    /// - LBPair: The address of the LBPair
    /// - createdByOwner: Whether the pair was created by the owner of the factory
    /// - ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX,
        IERC20 indexed tokenY,
        uint256 indexed binStep,
        ILBPair LBPair,
        uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event FeeParametersSet(
        address indexed sender,
        ILBPair indexed LBPair,
        uint256 binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulated
    );

    event FactoryLockedStatusUpdated(bool unlocked);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulated,
        uint256 sampleLifetime
    );

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function MAX_FEE() external pure returns (uint256);

    function MIN_BIN_STEP() external pure returns (uint256);

    function MAX_BIN_STEP() external pure returns (uint256);

    function MAX_PROTOCOL_SHARE() external pure returns (uint256);

    function LBPairImplementation() external view returns (address);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAsset(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function feeRecipient() external view returns (address);

    function flashLoanFee() external view returns (uint256);

    function creationUnlocked() external view returns (bool);

    function allLBPairs(uint256 id) external returns (ILBPair);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairInformation(
        IERC20 tokenX,
        IERC20 tokenY,
        uint256 binStep
    ) external view returns (LBPairInformation memory);

    function getPreset(uint16 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            uint256 sampleLifetime
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address LBPairImplementation) external;

    function createLBPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 binStep
    ) external returns (ILBPair pair);

    function setLBPairIgnored(
        IERC20 tokenX,
        IERC20 tokenY,
        uint256 binStep,
        bool ignored
    ) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulated,
        uint16 sampleLifetime
    ) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulated
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function setFactoryLockedState(bool locked) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair LBPair) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "openzeppelin/token/ERC20/IERC20.sol";

/// @title Liquidity Book Flashloan Callback Interface
/// @author Trader Joe
/// @notice Required interface to interact with LB flash loans
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "openzeppelin/token/ERC20/IERC20.sol";

import "../libraries/FeeHelper.sol";
import "./ILBFactory.sol";
import "./ILBFlashLoanCallback.sol";

/// @title Liquidity Book Pair Interface
/// @author Trader Joe
/// @notice Required interface of LBPair contract
interface ILBPair {
    /// @dev Structure to store the reserves of bins:
    /// - reserveX: The current reserve of tokenX of the bin
    /// - reserveY: The current reserve of tokenY of the bin
    struct Bin {
        uint112 reserveX;
        uint112 reserveY;
        uint256 accTokenXPerShare;
        uint256 accTokenYPerShare;
    }

    /// @dev Structure to store the information of the pair such as:
    /// slot0:
    /// - activeId: The current id used for swaps, this is also linked with the price
    /// - reserveX: The sum of amounts of tokenX across all bins
    /// slot1:
    /// - reserveY: The sum of amounts of tokenY across all bins
    /// - oracleSampleLifetime: The lifetime of an oracle sample
    /// - oracleSize: The current size of the oracle, can be increase by users
    /// - oracleActiveSize: The current active size of the oracle, composed only from non empty data sample
    /// - oracleLastTimestamp: The current last timestamp at which a sample was added to the circular buffer
    /// - oracleId: The current id of the oracle
    /// slot2:
    /// - feesX: The current amount of fees to distribute in tokenX (total, protocol)
    /// slot3:
    /// - feesY: The current amount of fees to distribute in tokenY (total, protocol)
    struct PairInformation {
        uint24 activeId;
        uint136 reserveX;
        uint136 reserveY;
        uint16 oracleSampleLifetime;
        uint16 oracleSize;
        uint16 oracleActiveSize;
        uint40 oracleLastTimestamp;
        uint16 oracleId;
        FeeHelper.FeesDistribution feesX;
        FeeHelper.FeesDistribution feesY;
    }

    /// @dev Structure to store the debts of users
    /// - debtX: The tokenX's debt
    /// - debtY: The tokenY's debt
    struct Debts {
        uint256 debtX;
        uint256 debtY;
    }

    /// @dev Structure to store fees:
    /// - tokenX: The amount of fees of token X
    /// - tokenY: The amount of fees of token Y
    struct Fees {
        uint128 tokenX;
        uint128 tokenY;
    }

    /// @dev Structure to minting informations:
    /// - amountXIn: The amount of token X sent
    /// - amountYIn: The amount of token Y sent
    /// - amountXAddedToPair: The amount of token X that have been actually added to the pair
    /// - amountYAddedToPair: The amount of token Y that have been actually added to the pair
    /// - activeFeeX: Fees X currently generated
    /// - activeFeeY: Fees Y currently generated
    /// - totalDistributionX: Total distribution of token X. Should be 1e18 (100%) or 0 (0%)
    /// - totalDistributionY: Total distribution of token Y. Should be 1e18 (100%) or 0 (0%)
    /// - id: Id of the current working bin when looping on the distribution array
    /// - amountX: The amount of token X deposited in the current bin
    /// - amountY: The amount of token Y deposited in the current bin
    /// - distributionX: Distribution of token X for the current working bin
    /// - distributionY: Distribution of token Y for the current working bin
    struct MintInfo {
        uint256 amountXIn;
        uint256 amountYIn;
        uint256 amountXAddedToPair;
        uint256 amountYAddedToPair;
        uint256 activeFeeX;
        uint256 activeFeeY;
        uint256 totalDistributionX;
        uint256 totalDistributionY;
        uint256 id;
        uint256 amountX;
        uint256 amountY;
        uint256 distributionX;
        uint256 distributionY;
    }

    event Swap(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        bool swapForY,
        uint256 amountIn,
        uint256 amountOut,
        uint256 volatilityAccumulated,
        uint256 fees
    );

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        IERC20 token,
        uint256 amount,
        uint256 fee
    );

    event CompositionFee(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        uint256 feesX,
        uint256 feesY
    );

    event DepositedToBin(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        uint256 amountX,
        uint256 amountY
    );

    event WithdrawnFromBin(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        uint256 amountX,
        uint256 amountY
    );

    event FeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event ProtocolFeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event OracleSizeIncreased(uint256 previousSize, uint256 newSize);

    function tokenX() external view returns (IERC20);

    function tokenY() external view returns (IERC20);

    function factory() external view returns (ILBFactory);

    function getReservesAndId()
        external
        view
        returns (
            uint256 reserveX,
            uint256 reserveY,
            uint256 activeId
        );

    function getGlobalFees()
        external
        view
        returns (
            uint128 feesXTotal,
            uint128 feesYTotal,
            uint128 feesXProtocol,
            uint128 feesYProtocol
        );

    function getOracleParameters()
        external
        view
        returns (
            uint256 oracleSampleLifetime,
            uint256 oracleSize,
            uint256 oracleActiveSize,
            uint256 oracleLastTimestamp,
            uint256 oracleId,
            uint256 min,
            uint256 max
        );

    function getOracleSampleFrom(uint256 timeDelta)
        external
        view
        returns (
            uint256 cumulativeId,
            uint256 cumulativeAccumulator,
            uint256 cumulativeBinCrossed
        );

    function feeParameters() external view returns (FeeHelper.FeeParameters memory);

    function findFirstNonEmptyBinId(uint24 id_, bool sentTokenY) external view returns (uint24 id);

    function getBin(uint24 id) external view returns (uint256 reserveX, uint256 reserveY);

    function pendingFees(address account, uint256[] memory ids)
        external
        view
        returns (uint256 amountX, uint256 amountY);

    function swap(bool sentTokenY, address to) external returns (uint256 amountXOut, uint256 amountYOut);

    function flashLoan(
        ILBFlashLoanCallback receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function mint(
        uint256[] calldata ids,
        uint256[] calldata distributionX,
        uint256[] calldata distributionY,
        address to
    )
        external
        returns (
            uint256 amountXAddedToPair,
            uint256 amountYAddedToPair,
            uint256[] memory liquidityMinted
        );

    function burn(
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address to
    ) external returns (uint256 amountX, uint256 amountY);

    function increaseOracleLength(uint16 newSize) external;

    function collectFees(address account, uint256[] calldata ids) external returns (uint256 amountX, uint256 amountY);

    function collectProtocolFees() external returns (uint128 amountX, uint128 amountY);

    function setFeesParameters(bytes32 packedFeeParameters) external;

    function forceDecay() external;

    function initialize(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 sampleLifetime,
        bytes32 packedFeeParameters
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IJoeFactory.sol";
import "./ILBPair.sol";
import "./ILBToken.sol";
import "./IWAVAX.sol";

/// @title Liquidity Book Router Interface
/// @author Trader Joe
/// @notice Required interface of LBRouter contract
interface ILBRouter {
    /// @dev The liquidity parameters, such as:
    /// - tokenX: The address of token X
    /// - tokenY: The address of token Y
    /// - binStep: The bin step of the pair
    /// - amountX: The amount to send of token X
    /// - amountY: The amount to send of token Y
    /// - amountXMin: The min amount of token X added to liquidity
    /// - amountYMin: The min amount of token Y added to liquidity
    /// - activeIdDesired: The active id that user wants to add liquidity from
    /// - idSlippage: The number of id that are allowed to slip
    /// - deltaIds: The list of delta ids to add liquidity (`deltaId = activeId - desiredId`)
    /// - distributionX: The distribution of tokenX with sum(distributionX) = 100e18 (100%) or 0 (0%)
    /// - distributionY: The distribution of tokenY with sum(distributionY) = 100e18 (100%) or 0 (0%)
    /// - to: The address of the recipient
    /// - deadline: The deadline of the tx
    struct LiquidityParameters {
        IERC20 tokenX;
        IERC20 tokenY;
        uint256 binStep;
        uint256 amountX;
        uint256 amountY;
        uint256 amountXMin;
        uint256 amountYMin;
        uint256 activeIdDesired;
        uint256 idSlippage;
        int256[] deltaIds;
        uint256[] distributionX;
        uint256[] distributionY;
        address to;
        uint256 deadline;
    }

    function factory() external view returns (ILBFactory);

    function oldFactory() external view returns (IJoeFactory);

    function wavax() external view returns (IWAVAX);

    function getIdFromPrice(ILBPair LBPair, uint256 price) external view returns (uint24);

    function getPriceFromId(ILBPair LBPair, uint24 id) external view returns (uint256);

    function getSwapIn(
        ILBPair LBPair,
        uint256 amountOut,
        bool swapForY
    ) external view returns (uint256 amountIn, uint256 feesIn);

    function getSwapOut(
        ILBPair LBPair,
        uint256 amountIn,
        bool swapForY
    ) external view returns (uint256 amountOut, uint256 feesIn);

    function createLBPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 binStep
    ) external returns (ILBPair pair);

    function addLiquidity(LiquidityParameters calldata liquidityParameters)
        external
        returns (uint256[] memory depositIds, uint256[] memory liquidityMinted);

    function addLiquidityAVAX(LiquidityParameters calldata liquidityParameters)
        external
        payable
        returns (uint256[] memory depositIds, uint256[] memory liquidityMinted);

    function removeLiquidity(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external returns (uint256 amountX, uint256 amountY);

    function removeLiquidityAVAX(
        IERC20 token,
        uint16 binStep,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMinAVAX,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amountsIn);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMinAVAX,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function sweep(
        IERC20 token,
        address to,
        uint256 amount
    ) external;

    function sweepLBToken(
        ILBToken _lbToken,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "openzeppelin/utils/introspection/IERC165.sol";

/// @title Liquidity Book Token Interface
/// @author Trader Joe
/// @notice Required interface of LBToken contract
interface ILBToken is IERC165 {
    event TransferSingle(address indexed sender, address indexed from, address indexed to, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory batchBalances);

    function totalSupply(uint256 id) external view returns (uint256);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function setApprovalForAll(address sender, bool approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata id,
        uint256[] calldata amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title Liquidity Book Pending Ownable Interface
/// @author Trader Joe
/// @notice Required interface of Pending Ownable contract used for LBFactory
interface IPendingOwnable {
    event PendingOwnerSet(address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "openzeppelin/token/ERC20/IERC20.sol";

/// @title WAVAX Interface
/// @notice Required interface of Wrapped AVAX contract
interface IWAVAX is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title Liquidity Book Bit Math Library
/// @author Trader Joe
/// @notice Helper contract used for bit calculations
library BitMath {
    /// @notice Returns the closest non-zero bit of `integer` to the right (of left) of the `bit` bits that is not `bit`
    /// @param _integer The integer as a uint256
    /// @param _bit The bit index
    /// @param _rightSide Whether we're searching in the right side of the tree (true) or the left side (false)
    /// @return The index of the closest non-zero bit. If there is no closest bit, it returns max(uint256)
    function closestBit(
        uint256 _integer,
        uint8 _bit,
        bool _rightSide
    ) internal pure returns (uint256) {
        return _rightSide ? closestBitRight(_integer, _bit - 1) : closestBitLeft(_integer, _bit + 1);
    }

    /// @notice Returns the most (or least) significant bit of `_integer`
    /// @param _integer The integer
    /// @param _isMostSignificant Whether we want the most (true) or the least (false) significant bit
    /// @return The index of the most (or least) significant bit
    function significantBit(uint256 _integer, bool _isMostSignificant) internal pure returns (uint8) {
        return _isMostSignificant ? mostSignificantBit(_integer) : leastSignificantBit(_integer);
    }

    /// @notice Returns the index of the closest bit on the right of x that is non null
    /// @param x The value as a uint256
    /// @param bit The index of the bit to start searching at
    /// @return id The index of the closest non null bit on the right of x.
    /// If there is no closest bit, it returns max(uint256)
    function closestBitRight(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            uint256 _shift = 255 - bit;
            x <<= _shift;

            // can't overflow as it's non-zero and we shifted it by `_shift`
            return (x == 0) ? type(uint256).max : mostSignificantBit(x) - _shift;
        }
    }

    /// @notice Returns the index of the closest bit on the left of x that is non null
    /// @param x The value as a uint256
    /// @param bit The index of the bit to start searching at
    /// @return id The index of the closest non null bit on the left of x.
    /// If there is no closest bit, it returns max(uint256)
    function closestBitLeft(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            x >>= bit;

            return (x == 0) ? type(uint256).max : leastSignificantBit(x) + bit;
        }
    }

    /// @notice Returns the index of the most significant bit of x
    /// @param x The value as a uint256
    /// @return msb The index of the most significant bit of x
    function mostSignificantBit(uint256 x) internal pure returns (uint8 msb) {
        unchecked {
            if (x >= 1 << 128) {
                x >>= 128;
                msb = 128;
            }
            if (x >= 1 << 64) {
                x >>= 64;
                msb += 64;
            }
            if (x >= 1 << 32) {
                x >>= 32;
                msb += 32;
            }
            if (x >= 1 << 16) {
                x >>= 16;
                msb += 16;
            }
            if (x >= 1 << 8) {
                x >>= 8;
                msb += 8;
            }
            if (x >= 1 << 4) {
                x >>= 4;
                msb += 4;
            }
            if (x >= 1 << 2) {
                x >>= 2;
                msb += 2;
            }
            if (x >= 1 << 1) {
                msb += 1;
            }
        }
    }

    /// @notice Returns the index of the least significant bit of x
    /// @param x The value as a uint256
    /// @return lsb The index of the least significant bit of x
    function leastSignificantBit(uint256 x) internal pure returns (uint8 lsb) {
        unchecked {
            if (x << 128 != 0) {
                x <<= 128;
                lsb = 128;
            }
            if (x << 64 != 0) {
                x <<= 64;
                lsb += 64;
            }
            if (x << 32 != 0) {
                x <<= 32;
                lsb += 32;
            }
            if (x << 16 != 0) {
                x <<= 16;
                lsb += 16;
            }
            if (x << 8 != 0) {
                x <<= 8;
                lsb += 8;
            }
            if (x << 4 != 0) {
                x <<= 4;
                lsb += 4;
            }
            if (x << 2 != 0) {
                x <<= 2;
                lsb += 2;
            }
            if (x << 1 != 0) {
                lsb += 1;
            }

            return 255 - lsb;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title Liquidity Book Constants Library
/// @author Trader Joe
/// @notice Set of constants for Liquidity Book contracts
library Constants {
    uint256 internal constant SCALE_OFFSET = 128;
    uint256 internal constant SCALE = 1 << SCALE_OFFSET;

    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant BASIS_POINT_MAX = 10_000;

    /// @dev The expected return after a successful flash loan
    bytes32 internal constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Constants.sol";
import "./SafeCast.sol";
import "./SafeMath.sol";

/// @title Liquidity Book Fee Helper Library
/// @author Trader Joe
/// @notice Helper contract used for fees calculation
library FeeHelper {
    using SafeCast for uint256;
    using SafeMath for uint256;

    /// @dev Structure to store the protocol fees:
    /// - binStep: The bin step
    /// - baseFactor: The base factor
    /// - filterPeriod: The filter period, where the fees stays constant
    /// - decayPeriod: The decay period, where the fees are halved
    /// - reductionFactor: The reduction factor, used to calculate the reduction of the accumulator
    /// - variableFeeControl: The variable fee control, used to control the variable fee, can be 0 to disable them
    /// - protocolShare: The share of fees sent to protocol
    /// - maxVolatilityAccumulated: The max value of volatility accumulated
    /// - volatilityAccumulated: The value of volatility accumulated
    /// - volatilityReference: The value of volatility reference
    /// - indexRef: The index reference
    /// - time: The last time the accumulator was called
    struct FeeParameters {
        // 144 lowest bits in slot
        uint16 binStep;
        uint16 baseFactor;
        uint16 filterPeriod;
        uint16 decayPeriod;
        uint16 reductionFactor;
        uint24 variableFeeControl;
        uint16 protocolShare;
        uint24 maxVolatilityAccumulated;
        // 112 highest bits in slot
        uint24 volatilityAccumulated;
        uint24 volatilityReference;
        uint24 indexRef;
        uint40 time;
    }

    /// @dev Structure used during swaps to distributes the fees:
    /// - total: The total amount of fees
    /// - protocol: The amount of fees reserved for protocol
    struct FeesDistribution {
        uint128 total;
        uint128 protocol;
    }

    /// @notice Update the value of the volatility accumulated
    /// @param _fp The current fee parameters
    /// @param _activeId The current active id
    function updateVariableFeeParameters(FeeParameters memory _fp, uint256 _activeId) internal view {
        uint256 _deltaT = block.timestamp - _fp.time;

        if (_deltaT >= _fp.filterPeriod || _fp.time == 0) {
            _fp.indexRef = uint24(_activeId);
            if (_deltaT < _fp.decayPeriod) {
                unchecked {
                    // This can't overflow as `reductionFactor <= BASIS_POINT_MAX`
                    _fp.volatilityReference = uint24(
                        (uint256(_fp.reductionFactor) * _fp.volatilityAccumulated) / Constants.BASIS_POINT_MAX
                    );
                }
            } else {
                _fp.volatilityReference = 0;
            }
        }

        _fp.time = (block.timestamp).safe40();

        updateVolatilityAccumulated(_fp, _activeId);
    }

    /// @notice Update the volatility accumulated
    /// @param _fp The fee parameter
    /// @param _activeId The current active id
    function updateVolatilityAccumulated(FeeParameters memory _fp, uint256 _activeId) internal pure {
        uint256 volatilityAccumulated = (_activeId.absSub(_fp.indexRef) * Constants.BASIS_POINT_MAX) +
            _fp.volatilityReference;
        _fp.volatilityAccumulated = volatilityAccumulated > _fp.maxVolatilityAccumulated
            ? _fp.maxVolatilityAccumulated
            : uint24(volatilityAccumulated);
    }

    /// @notice Returns the base fee added to a swap, with 18 decimals
    /// @param _fp The current fee parameters
    /// @return The fee with 18 decimals precision
    function getBaseFee(FeeParameters memory _fp) internal pure returns (uint256) {
        unchecked {
            return uint256(_fp.baseFactor) * _fp.binStep * 1e10;
        }
    }

    /// @notice Returns the variable fee added to a swap, with 18 decimals
    /// @param _fp The current fee parameters
    /// @return variableFee The variable fee with 18 decimals precision
    function getVariableFee(FeeParameters memory _fp) internal pure returns (uint256 variableFee) {
        if (_fp.variableFeeControl != 0) {
            // Can't overflow as the max value is `max(uint24) * (max(uint24) * max(uint16)) ** 2 < max(uint104)`
            // It returns 18 decimals as:
            // decimals(variableFeeControl * (volatilityAccumulated * binStep)**2 / 100) = 4 + (4 + 4) * 2 - 2 = 18
            unchecked {
                uint256 _prod = uint256(_fp.volatilityAccumulated) * _fp.binStep;
                variableFee = (_prod * _prod * _fp.variableFeeControl + 99) / 100;
            }
        }
    }

    /// @notice Return the amount of fees from an amount
    /// @dev Rounds amount up, follows `amount = amountWithFees - getFeeAmountFrom(fp, amountWithFees)`
    /// @param _fp The current fee parameter
    /// @param _amountWithFees The amount of token sent
    /// @return The fee amount from the amount sent
    function getFeeAmountFrom(FeeParameters memory _fp, uint256 _amountWithFees) internal pure returns (uint256) {
        return (_amountWithFees * getTotalFee(_fp) + Constants.PRECISION - 1) / (Constants.PRECISION);
    }

    /// @notice Return the fees to add to an amount
    /// @dev Rounds amount up, follows `amountWithFees = amount + getFeeAmount(fp, amount)`
    /// @param _fp The current fee parameter
    /// @param _amount The amount of token sent
    /// @return The fee amount to add to the amount
    function getFeeAmount(FeeParameters memory _fp, uint256 _amount) internal pure returns (uint256) {
        uint256 _fee = getTotalFee(_fp);
        uint256 _denominator = Constants.PRECISION - _fee;
        return (_amount * _fee + _denominator - 1) / _denominator;
    }

    /// @notice Return the fees added when an user adds liquidity and change the ratio in the active bin
    /// @dev Rounds amount up
    /// @param _fp The current fee parameter
    /// @param _amountWithFees The amount of token sent
    /// @return The fee amount
    function getFeeAmountForC(FeeParameters memory _fp, uint256 _amountWithFees) internal pure returns (uint256) {
        uint256 _fee = getTotalFee(_fp);
        uint256 _denominator = Constants.PRECISION * Constants.PRECISION;
        return (_amountWithFees * _fee * (_fee + Constants.PRECISION) + _denominator - 1) / _denominator;
    }

    /// @notice Return the fees distribution added to an amount
    /// @param _fp The current fee parameter
    /// @param _fees The fee amount
    /// @return fees The fee distribution
    function getFeeAmountDistribution(FeeParameters memory _fp, uint256 _fees)
        internal
        pure
        returns (FeesDistribution memory fees)
    {
        fees.total = _fees.safe128();
        // unsafe math is fine because total >= protocol
        unchecked {
            fees.protocol = uint128((_fees * _fp.protocolShare) / Constants.BASIS_POINT_MAX);
        }
    }

    /// @notice Return the total fee, i.e. baseFee + variableFee
    /// @param _fp The current fee parameter
    /// @return The total fee, with 18 decimals
    function getTotalFee(FeeParameters memory _fp) private pure returns (uint256) {
        unchecked {
            return getBaseFee(_fp) + getVariableFee(_fp);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../LBErrors.sol";
import "./BitMath.sol";

/// @title Liquidity Book Math Helper Library
/// @author Trader Joe
/// @notice Helper contract used for full precision calculations
library Math512Bits {
    using BitMath for uint256;

    /// @notice Calculates floor(x*y÷denominator) with full precision
    /// The result will be rounded down
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The denominator cannot be zero
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @param denominator The divisor as an uint256
    /// @return result The result as an uint256
    function mulDivRoundDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        return _getEndOfDivRoundDown(x, y, denominator, prod0, prod1);
    }

    /// @notice Calculates x * y >> offset with full precision
    /// The result will be rounded down
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The offset needs to be strictly lower than 256
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @param offset The offset as an uint256, can't be greater than 256
    /// @return result The result as an uint256
    function mulShiftRoundDown(
        uint256 x,
        uint256 y,
        uint256 offset
    ) internal pure returns (uint256 result) {
        if (offset > 255) revert Math512Bits__OffsetOverflows(offset);

        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        if (prod0 != 0) result = prod0 >> offset;
        if (prod1 != 0) {
            // Make sure the result is less than 2^256.
            if (prod1 >= 1 << offset) revert Math512Bits__MulShiftOverflow(prod1, offset);

            unchecked {
                result += prod1 << (256 - offset);
            }
        }
    }

    /// @notice Calculates x * y >> offset with full precision
    /// The result will be rounded up
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The offset needs to be strictly lower than 256
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @param offset The offset as an uint256, can't be greater than 256
    /// @return result The result as an uint256
    function mulShiftRoundUp(
        uint256 x,
        uint256 y,
        uint256 offset
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulShiftRoundDown(x, y, offset);
            if (mulmod(x, y, 1 << offset) != 0) result += 1;
        }
    }

    /// @notice Calculates x << offset / y with full precision
    /// The result will be rounded down
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The offset needs to be strictly lower than 256
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param offset The number of bit to shift x as an uint256
    /// @param denominator The divisor as an uint256
    /// @return result The result as an uint256
    function shiftDivRoundDown(
        uint256 x,
        uint256 offset,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        if (offset > 255) revert Math512Bits__OffsetOverflows(offset);
        uint256 prod0;
        uint256 prod1;

        prod0 = x << offset; // Least significant 256 bits of the product
        unchecked {
            prod1 = x >> (256 - offset); // Most significant 256 bits of the product
        }

        return _getEndOfDivRoundDown(x, 1 << offset, denominator, prod0, prod1);
    }

    /// @notice Calculates x << offset / y with full precision
    /// The result will be rounded up
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The offset needs to be strictly lower than 256
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param offset The number of bit to shift x as an uint256
    /// @param denominator The divisor as an uint256
    /// @return result The result as an uint256
    function shiftDivRoundUp(
        uint256 x,
        uint256 offset,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = shiftDivRoundDown(x, offset, denominator);
        unchecked {
            if (mulmod(x, 1 << offset, denominator) != 0) result += 1;
        }
    }

    /// @notice Helper function to return the result of `x * y` as 2 uint256
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @return prod0 The least significant 256 bits of the product
    /// @return prod1 The most significant 256 bits of the product
    function _getMulProds(uint256 x, uint256 y) private pure returns (uint256 prod0, uint256 prod1) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
    }

    /// @notice Helper function to return the result of `x * y / denominator` with full precision
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @param denominator The divisor as an uint256
    /// @param prod0 The least significant 256 bits of the product
    /// @param prod1 The most significant 256 bits of the product
    /// @return result The result as an uint256
    function _getEndOfDivRoundDown(
        uint256 x,
        uint256 y,
        uint256 denominator,
        uint256 prod0,
        uint256 prod1
    ) private pure returns (uint256 result) {
        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
        } else {
            // Make sure the result is less than 2^256. Also prevents denominator == 0
            if (prod1 >= denominator) revert Math512Bits__MulDivOverflow(prod1, denominator);

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1
            // See https://cs.stackexchange.com/q/138556/92363
            unchecked {
                // Does not overflow because the denominator cannot be zero at this stage in the function
                uint256 lpotdod = denominator & (~denominator + 1);
                assembly {
                    // Divide denominator by lpotdod.
                    denominator := div(denominator, lpotdod)

                    // Divide [prod1 prod0] by lpotdod.
                    prod0 := div(prod0, lpotdod)

                    // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one
                    lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
                }

                // Shift in bits from prod1 into prod0
                prod0 |= prod1 * lpotdod;

                // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
                // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
                // four bits. That is, denominator * inv = 1 mod 2^4
                uint256 inverse = (3 * denominator) ^ 2;

                // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
                // in modular arithmetic, doubling the correct bits in each step
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
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../LBErrors.sol";
import "../interfaces/IPendingOwnable.sol";

/// @title Pending Ownable
/// @author Trader Joe
/// @notice Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions. The ownership of this contract is transferred using the
/// push and pull pattern, the current owner set a `pendingOwner` using
/// {setPendingOwner} and that address can then call {becomeOwner} to become the
/// owner of that contract. The main logic and comments comes from OpenZeppelin's
/// Ownable contract.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {setPendingOwner} and {becomeOwner}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner
contract PendingOwnable is IPendingOwnable {
    address private _owner;
    address private _pendingOwner;

    /// @notice Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) revert PendingOwnable__NotOwner();
        _;
    }

    /// @notice Throws if called by any account other than the pending owner.
    modifier onlyPendingOwner() {
        if (msg.sender != _pendingOwner || msg.sender == address(0)) revert PendingOwnable__NotPendingOwner();
        _;
    }

    /// @notice Initializes the contract setting the deployer as the initial owner
    constructor() {
        _transferOwnership(msg.sender);
    }

    /// @notice Returns the address of the current owner
    /// @return The address of the current owner
    function owner() public view override returns (address) {
        return _owner;
    }

    /// @notice Returns the address of the current pending owner
    /// @return The address of the current pending owner
    function pendingOwner() public view override returns (address) {
        return _pendingOwner;
    }

    /// @notice Sets the pending owner address. This address will be able to become
    /// the owner of this contract by calling {becomeOwner}
    function setPendingOwner(address pendingOwner_) public override onlyOwner {
        if (pendingOwner_ == address(0)) revert PendingOwnable__AddressZero();
        if (_pendingOwner != address(0)) revert PendingOwnable__PendingOwnerAlreadySet();
        _setPendingOwner(pendingOwner_);
    }

    /// @notice Revoke the pending owner address. This address will not be able to
    /// call {becomeOwner} to become the owner anymore.
    /// Can only be called by the owner
    function revokePendingOwner() public override onlyOwner {
        if (_pendingOwner == address(0)) revert PendingOwnable__NoPendingOwner();
        _setPendingOwner(address(0));
    }

    /// @notice Transfers the ownership to the new owner (`pendingOwner).
    /// Can only be called by the pending owner
    function becomeOwner() public override onlyPendingOwner {
        _transferOwnership(msg.sender);
    }

    /// @notice Leaves the contract without owner. It will not be possible to call
    /// `onlyOwner` functions anymore. Can only be called by the current owner.
    ///
    /// NOTE: Renouncing ownership will leave the contract without an owner,
    /// thereby removing any functionality that is only available to the owner.
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));
    }

    /// @notice Transfers ownership of the contract to a new account (`newOwner`).
    /// Internal function without access restriction.
    /// @param _newOwner The address of the new owner
    function _transferOwnership(address _newOwner) internal virtual {
        address _oldOwner = _owner;
        _owner = _newOwner;
        _pendingOwner = address(0);
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /// @notice Push the new owner, it needs to be pulled to be effective.
    /// Internal function without access restriction.
    /// @param pendingOwner_ The address of the new pending owner
    function _setPendingOwner(address pendingOwner_) internal virtual {
        _pendingOwner = pendingOwner_;
        emit PendingOwnerSet(pendingOwner_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../LBErrors.sol";

/// @title Liquidity Book Safe Cast Library
/// @author Trader Joe
/// @notice Helper contract used for converting uint values safely
library SafeCast {
    /// @notice Returns x on uint248 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint248
    function safe248(uint256 x) internal pure returns (uint248 y) {
        if ((y = uint248(x)) != x) revert SafeCast__Exceeds248Bits(x);
    }

    /// @notice Returns x on uint240 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint240
    function safe240(uint256 x) internal pure returns (uint240 y) {
        if ((y = uint240(x)) != x) revert SafeCast__Exceeds240Bits(x);
    }

    /// @notice Returns x on uint232 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint232
    function safe232(uint256 x) internal pure returns (uint232 y) {
        if ((y = uint232(x)) != x) revert SafeCast__Exceeds232Bits(x);
    }

    /// @notice Returns x on uint224 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint224
    function safe224(uint256 x) internal pure returns (uint224 y) {
        if ((y = uint224(x)) != x) revert SafeCast__Exceeds224Bits(x);
    }

    /// @notice Returns x on uint216 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint216
    function safe216(uint256 x) internal pure returns (uint216 y) {
        if ((y = uint216(x)) != x) revert SafeCast__Exceeds216Bits(x);
    }

    /// @notice Returns x on uint208 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint208
    function safe208(uint256 x) internal pure returns (uint208 y) {
        if ((y = uint208(x)) != x) revert SafeCast__Exceeds208Bits(x);
    }

    /// @notice Returns x on uint200 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint200
    function safe200(uint256 x) internal pure returns (uint200 y) {
        if ((y = uint200(x)) != x) revert SafeCast__Exceeds200Bits(x);
    }

    /// @notice Returns x on uint192 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint192
    function safe192(uint256 x) internal pure returns (uint192 y) {
        if ((y = uint192(x)) != x) revert SafeCast__Exceeds192Bits(x);
    }

    /// @notice Returns x on uint184 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint184
    function safe184(uint256 x) internal pure returns (uint184 y) {
        if ((y = uint184(x)) != x) revert SafeCast__Exceeds184Bits(x);
    }

    /// @notice Returns x on uint176 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint176
    function safe176(uint256 x) internal pure returns (uint176 y) {
        if ((y = uint176(x)) != x) revert SafeCast__Exceeds176Bits(x);
    }

    /// @notice Returns x on uint168 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint168
    function safe168(uint256 x) internal pure returns (uint168 y) {
        if ((y = uint168(x)) != x) revert SafeCast__Exceeds168Bits(x);
    }

    /// @notice Returns x on uint160 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint160
    function safe160(uint256 x) internal pure returns (uint160 y) {
        if ((y = uint160(x)) != x) revert SafeCast__Exceeds160Bits(x);
    }

    /// @notice Returns x on uint152 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint152
    function safe152(uint256 x) internal pure returns (uint152 y) {
        if ((y = uint152(x)) != x) revert SafeCast__Exceeds152Bits(x);
    }

    /// @notice Returns x on uint144 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint144
    function safe144(uint256 x) internal pure returns (uint144 y) {
        if ((y = uint144(x)) != x) revert SafeCast__Exceeds144Bits(x);
    }

    /// @notice Returns x on uint136 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint136
    function safe136(uint256 x) internal pure returns (uint136 y) {
        if ((y = uint136(x)) != x) revert SafeCast__Exceeds136Bits(x);
    }

    /// @notice Returns x on uint128 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint128
    function safe128(uint256 x) internal pure returns (uint128 y) {
        if ((y = uint128(x)) != x) revert SafeCast__Exceeds128Bits(x);
    }

    /// @notice Returns x on uint120 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint120
    function safe120(uint256 x) internal pure returns (uint120 y) {
        if ((y = uint120(x)) != x) revert SafeCast__Exceeds120Bits(x);
    }

    /// @notice Returns x on uint112 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint112
    function safe112(uint256 x) internal pure returns (uint112 y) {
        if ((y = uint112(x)) != x) revert SafeCast__Exceeds112Bits(x);
    }

    /// @notice Returns x on uint104 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint104
    function safe104(uint256 x) internal pure returns (uint104 y) {
        if ((y = uint104(x)) != x) revert SafeCast__Exceeds104Bits(x);
    }

    /// @notice Returns x on uint96 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint96
    function safe96(uint256 x) internal pure returns (uint96 y) {
        if ((y = uint96(x)) != x) revert SafeCast__Exceeds96Bits(x);
    }

    /// @notice Returns x on uint88 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint88
    function safe88(uint256 x) internal pure returns (uint88 y) {
        if ((y = uint88(x)) != x) revert SafeCast__Exceeds88Bits(x);
    }

    /// @notice Returns x on uint80 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint80
    function safe80(uint256 x) internal pure returns (uint80 y) {
        if ((y = uint80(x)) != x) revert SafeCast__Exceeds80Bits(x);
    }

    /// @notice Returns x on uint72 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint72
    function safe72(uint256 x) internal pure returns (uint72 y) {
        if ((y = uint72(x)) != x) revert SafeCast__Exceeds72Bits(x);
    }

    /// @notice Returns x on uint64 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint64
    function safe64(uint256 x) internal pure returns (uint64 y) {
        if ((y = uint64(x)) != x) revert SafeCast__Exceeds64Bits(x);
    }

    /// @notice Returns x on uint56 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint56
    function safe56(uint256 x) internal pure returns (uint56 y) {
        if ((y = uint56(x)) != x) revert SafeCast__Exceeds56Bits(x);
    }

    /// @notice Returns x on uint48 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint48
    function safe48(uint256 x) internal pure returns (uint48 y) {
        if ((y = uint48(x)) != x) revert SafeCast__Exceeds48Bits(x);
    }

    /// @notice Returns x on uint40 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint40
    function safe40(uint256 x) internal pure returns (uint40 y) {
        if ((y = uint40(x)) != x) revert SafeCast__Exceeds40Bits(x);
    }

    /// @notice Returns x on uint32 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint32
    function safe32(uint256 x) internal pure returns (uint32 y) {
        if ((y = uint32(x)) != x) revert SafeCast__Exceeds32Bits(x);
    }

    /// @notice Returns x on uint24 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint24
    function safe24(uint256 x) internal pure returns (uint24 y) {
        if ((y = uint24(x)) != x) revert SafeCast__Exceeds24Bits(x);
    }

    /// @notice Returns x on uint16 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint16
    function safe16(uint256 x) internal pure returns (uint16 y) {
        if ((y = uint16(x)) != x) revert SafeCast__Exceeds16Bits(x);
    }

    /// @notice Returns x on uint8 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint8
    function safe8(uint256 x) internal pure returns (uint8 y) {
        if ((y = uint8(x)) != x) revert SafeCast__Exceeds8Bits(x);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title Liquidity Book Safe Math Helper Library
/// @author Trader Joe
/// @notice Helper contract used for calculating absolute value safely
library SafeMath {
    /// @notice absSub, can't underflow or overflow
    /// @param x The first value
    /// @param y The second value
    /// @return The result of abs(x - y)
    function absSub(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            return x > y ? x - y : y - x;
        }
    }
}