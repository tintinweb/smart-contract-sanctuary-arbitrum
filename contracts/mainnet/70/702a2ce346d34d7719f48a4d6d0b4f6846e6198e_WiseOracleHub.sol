// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

/**
 * @author René Hochmuth
 * @author Christoph Krpoun
 * @author Vitally Marinchenko
 */

import "./OracleHelper.sol";

/**
 * @dev WiseOracleHub is an onchain extension for price feeds (chainLink or others).
 * The master address is owned by a timelock contract which itself is secured by a
 * multisig. Only the master can add new price feed <-> address pairs to the contract.
 *
 * One advantage is the linking of price feeds to their underlying token address.
 * Therefore, users can get the current ETH value of a token by just knowing the token
 * address when calling {latestResolver}. It takes the answer from {latestRoundData}
 * for chainLink oracles as recommended from chainLink.
 *
 * NOTE: If you want to propose adding an own developed price feed it is
 * mandatory to wrap its answer into a function mimicking {latestRoundData}
 * (See {latestResolver} implementation).
 *
 * Additionally, the oracleHub provides so called heartbeat checks if a token gets
 * still updated in expected time interval.
 */

contract WiseOracleHub is OracleHelper {

    constructor(
        address _wethAddrss,
        address _ethPricingFeed,
        address _uniswapFactoryV3
    )
        Declarations(
            _wethAddrss,
            _ethPricingFeed,
            _uniswapFactoryV3
        )
    {
    }

    /**
     * @dev Returns priceFeed latest ETH value
     * by passing the underlying token address.
     */
    function latestResolver(
        address _tokenAddress
    )
        public
        view
        returns (uint256)
    {
        if (chainLinkIsDead(_tokenAddress) == true) {
            revert OracleIsDead();
        }

        UniTwapPoolInfo memory uniTwapPoolInfoStruct = uniTwapPoolInfo[
            _tokenAddress
        ];

        uint256 fetchTwapValue;

        if (uniTwapPoolInfoStruct.oracle > ZERO_ADDRESS) {
            fetchTwapValue = latestResolverTwap(
                _tokenAddress
            );
        }

        uint256 answer = _getChainlinkAnswer(
            _tokenAddress
        );

        if (fetchTwapValue > 0) {

            uint256 relativeDifference = _getRelativeDifference(
                answer,
                fetchTwapValue
            );

            _compareDifference(
                relativeDifference
            );
        }

        return answer;
    }

    /**
     * @dev Returns Twaps latest USD value
     * by passing the underlying token address.
     */
    function latestResolverTwap(
        address _tokenAddress
    )
        public
        view
        returns (uint256)
    {
        UniTwapPoolInfo memory uniTwapPoolInfoStruct = uniTwapPoolInfo[
            _tokenAddress
        ];

        if (uniTwapPoolInfoStruct.isUniPool == true) {

            return _getTwapPrice(
                _tokenAddress,
                uniTwapPoolInfoStruct.oracle
            )
                / 10 ** (_decimalsWETH - decimals(_tokenAddress));
        }

        return _getTwapDerivatePrice(
            _tokenAddress,
            uniTwapPoolInfoStruct
        )
            / 10 ** (_decimalsWETH - decimals(_tokenAddress));
    }

    function getTokenDecimals(
        address _tokenAddress
    )
        external
        view
        returns (uint8)
    {
        return _tokenDecimals[_tokenAddress];
    }

    // @TODO: Delete later, keep for backward compatibility
    function getTokensInUSD(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        external
        view
        returns (uint256)
    {
        uint8 tokenDecimals = _tokenDecimals[
            _tokenAddress
        ];

        return _decimalsETH < tokenDecimals
            ? _tokenAmount
                * latestResolver(_tokenAddress)
                / 10 ** decimals(_tokenAddress)
                / 10 ** (tokenDecimals - _decimalsETH)
            : _tokenAmount
                * 10 ** (_decimalsETH - tokenDecimals)
                * latestResolver(_tokenAddress)
                / 10 ** decimals(_tokenAddress);
    }

    /**
     * @dev Returns USD value of a given token
     * amount in order of 1E18 decimal precision.
     */
    function getTokensPriceInUSD(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        external
        view
        returns (uint256)
    {
        return getTokensInETH(
            _tokenAddress,
            _tokenAmount
        )
            * getETHPriceInUSD()
            / 10 ** _decimalsUSD;
    }

    /**
     * @dev Returns ETH value of a given token
     * amount in order of 1E18 decimal precision.
     */
    function getTokensInETH(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        public
        view
        returns (uint256)
    {
        if (_tokenAddress == WETH_ADDRESS) {
            return _tokenAmount;
        }

        uint8 tokenDecimals = _tokenDecimals[
            _tokenAddress
        ];

        return _decimalsETH < tokenDecimals
            ? _tokenAmount
                * latestResolver(_tokenAddress)
                / 10 ** decimals(_tokenAddress)
                / 10 ** (tokenDecimals - _decimalsETH)
            : _tokenAmount
                * 10 ** (_decimalsETH - tokenDecimals)
                * latestResolver(_tokenAddress)
                / 10 ** decimals(_tokenAddress);
    }

    // @TODO: Delete later, keep for backward compatibility
    function getTokensFromUSD(
        address _tokenAddress,
        uint256 _usdValue
    )
        external
        view
        returns (uint256)
    {
        uint8 tokenDecimals = _tokenDecimals[
            _tokenAddress
        ];

        return _decimalsETH < tokenDecimals
            ? _usdValue
                * 10 ** (tokenDecimals - _decimalsETH)
                * 10 ** decimals(_tokenAddress)
                / latestResolver(_tokenAddress)
            : _usdValue
                * 10 ** decimals(_tokenAddress)
                / latestResolver(_tokenAddress)
                / 10 ** (_decimalsETH - tokenDecimals);
    }

    /**
     * @dev Converts USD value of a token into token amount with a
     * current price. The order of the argument _usdValue is 1E18.
     */
    function getTokensPriceFromUSD(
        address _tokenAddress,
        uint256 _usdValue
    )
        external
        view
        returns (uint256)
    {
        return getTokensFromETH(
            _tokenAddress,
            _usdValue
                * 10 ** _decimalsUSD
                / getETHPriceInUSD()
        );
    }

    /**
     * @dev Adds a new token address to the oracleHub Twap.
     * Can't overwrite existing mappings.
     */
    function addTwapOracle(
        address _tokenAddress,
        address _uniPoolAddress,
        address _token0,
        address _token1,
        uint24 _fee
    )
        external
        onlyMaster
    {
        address pool = _getPool(
            _token0,
            _token1,
            _fee
        );

        _validateTokenAddress(
            _tokenAddress,
            _token0,
            _token1
        );

        _validateTwapOracle(
            _tokenAddress
        );

        _validatePoolAddress(
            pool,
            _uniPoolAddress
        );

        _validatePriceFeed(
            _tokenAddress
        );

        _writeUniTwapPoolInfoStruct(
            {
                _tokenAddress: _tokenAddress,
                _oracle: pool,
                _isUniPool: true
            }
        );
    }

    /**
     * @dev Adds a new token address to TWAP as derivative.
     * Not permitted to overwrite existing mappings.
     */
    function addTwapOracleDerivative(
        address _tokenAddress,
        address _partnerTokenAddress,
        address[2] calldata _uniPools,
        address[2] calldata _token0Array,
        address[2] calldata _token1Array,
        uint24[2] calldata _feeArray
    )
        external
        onlyMaster
    {
        _validatePriceFeed(
            _tokenAddress
        );

        _validateTwapOracle(
            _tokenAddress
        );

        _validateTokenAddress(
            _tokenAddress,
            _token0Array[1],
            _token1Array[1]
        );

        uint256 i;
        address pool;
        uint256 length = _uniPools.length;

        while (i < length) {
            pool = _getPool(
                _token0Array[i],
                _token1Array[i],
                _feeArray[i]
            );

            _validatePoolAddress(
                pool,
                _uniPools[i]
            );

            unchecked {
                ++i;
            }
        }

        _writeUniTwapPoolInfoStructDerivative(
            {
                _tokenAddress: _tokenAddress,
                _partnerTokenAddress: _partnerTokenAddress,
                _oracleAddress: _uniPools[0],
                _partnerOracleAddress: _uniPools[1],
                _isUniPool: false
            }
        );
    }

    /**
     * @dev Converts ETH value of a token into token amount with a
     * current price. The order of the argument _ethAmount is 1E18.
     */
    function getTokensFromETH(
        address _tokenAddress,
        uint256 _ethAmount
    )
        public
        view
        returns (uint256)
    {
        if (_tokenAddress == WETH_ADDRESS) {
            return _ethAmount;
        }

        uint8 tokenDecimals = _tokenDecimals[
            _tokenAddress
        ];

        return _decimalsETH < tokenDecimals
            ? _ethAmount
                * 10 ** (tokenDecimals - _decimalsETH)
                * 10 ** decimals(_tokenAddress)
                / latestResolver(_tokenAddress)
            : _ethAmount
                * 10 ** decimals(_tokenAddress)
                / latestResolver(_tokenAddress)
                / 10 ** (_decimalsETH - tokenDecimals);
    }

    /**
     * @dev Adds priceFeed for a token.
     * Can't overwrite existing mappings.
     * Master is a timelock contract.
     */
    function addOracle(
        address _tokenAddress,
        IPriceFeed _priceFeedAddress,
        address[] calldata _underlyingFeedTokens
    )
        external
        onlyMaster
    {
        _addOracle(
            _tokenAddress,
            _priceFeedAddress,
            _underlyingFeedTokens
        );
    }

    /**
     * @dev Adds priceFeeds for tokens.
     * Can't overwrite existing mappings.
     * Master is a timelock contract.
     */
    function addOracleBulk(
        address[] calldata _tokenAddresses,
        IPriceFeed[] calldata _priceFeedAddresses,
        address[][] calldata _underlyingFeedTokens
    )
        external
        onlyMaster
    {
        uint256 i;
        uint256 l = _tokenAddresses.length;

        while (i < l) {
            _addOracle(
                _tokenAddresses[i],
                _priceFeedAddresses[i],
                _underlyingFeedTokens[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Looks at the maximal last 50 rounds and
     * takes second highest value to avoid counting
     * offline time of chainlink as valid heartbeat.
     */
    function recalibratePreview(
        address _tokenAddress
    )
        external
        view
        returns (uint256)
    {
        return _recalibratePreview(
            _tokenAddress
        );
    }

    /**
     * @dev Check if chainLink feed was
     * updated within expected timeFrame.
     * If length of {underlyingFeedTokens}
     * is greater than zero it checks the
     * heartbeat of all base feeds of the
     * derivate oracle.
     */
    function chainLinkIsDead(
        address _tokenAddress
    )
        public
        view
        returns (bool state)
    {
        uint256 i;
        uint256 length = underlyingFeedTokens[
            _tokenAddress
        ].length;

        if (sequencerIsDead() == true) {
            return true;
        }

        if (length == 0) {
            return _chainLinkIsDead(
                _tokenAddress
            );
        }

        while (i < length) {

            state = _chainLinkIsDead(
                underlyingFeedTokens[_tokenAddress][i]
            );

            unchecked {
                ++i;
            }

            if (state == true) {
                break;
            }
        }

        return state;
    }

    /**
     * @dev Recalibrates expected
     * heartbeat for a pricing feed.
     */
    function recalibrate(
        address _tokenAddress
    )
        external
    {
        _recalibrate(
            _tokenAddress
        );
    }

    /**
     * @dev Bulk function to recalibrate
     * the heartbeat for several tokens.
     */
    function recalibrateBulk(
        address[] calldata _tokenAddresses
    )
        external
    {
        uint256 i;
        uint256 l = _tokenAddresses.length;

        while (i < l) {
            _recalibrate(
                _tokenAddresses[i]
            );

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./Declarations.sol";

abstract contract OracleHelper is Declarations {

    /**
     * @dev Adds priceFeed for a given token.
     */
    function _addOracle(
        address _tokenAddress,
        IPriceFeed _priceFeedAddress,
        address[] calldata _underlyingFeedTokens
    )
        internal
    {
        if (priceFeed[_tokenAddress] > ZERO_FEED) {
            revert OracleAlreadySet();
        }

        priceFeed[_tokenAddress] = _priceFeedAddress;

        _tokenDecimals[_tokenAddress] = IERC20(
            _tokenAddress
        ).decimals();

        underlyingFeedTokens[_tokenAddress] = _underlyingFeedTokens;
    }

    /**
     * @dev Adds uniTwapPoolInfo for a given token.
     */
    function _writeUniTwapPoolInfoStruct(
        address _tokenAddress,
        address _oracle,
        bool _isUniPool
    )
        internal
    {
        uniTwapPoolInfo[_tokenAddress] = UniTwapPoolInfo({
            oracle: _oracle,
            isUniPool: _isUniPool
        });
    }

    /**
     * @dev Adds uniTwapPoolInfo for a given token and its derivative.
     */
    function _writeUniTwapPoolInfoStructDerivative(
        address _tokenAddress,
        address _partnerTokenAddress,
        address _oracleAddress,
        address _partnerOracleAddress,
        bool _isUniPool
    )
        internal
    {
        _writeUniTwapPoolInfoStruct(
            _tokenAddress,
            _oracleAddress,
            _isUniPool
        );

        derivativePartnerTwap[_tokenAddress] = DerivativePartnerInfo(
            _partnerTokenAddress,
            _partnerOracleAddress
        );
    }

    function _getRelativeDifference(
        uint256 _answerUint256,
        uint256 _fetchTwapValue
    )
        internal
        pure
        returns (uint256)
    {
        if (_answerUint256 > _fetchTwapValue) {
            return _answerUint256
                * PRECISION_FACTOR_E4
                / _fetchTwapValue;
        }

        return _fetchTwapValue
            * PRECISION_FACTOR_E4
            / _answerUint256;
    }

    function _compareDifference(
        uint256 _relativeDifference
    )
        internal
        view
    {
        if (_relativeDifference > ALLOWED_DIFFERENCE) {
            revert OraclesDeviate();
        }
    }

    function _getChainlinkAnswer(
        address _tokenAddress
    )
        internal
        view
        returns (uint256)
    {
        (
            ,
            int256 answer,
            ,
            ,
        ) = priceFeed[_tokenAddress].latestRoundData();

        return uint256(
            answer
        );
    }

    function getETHPriceInUSD()
        public
        view
        returns (uint256)
    {
        (
            ,
            int256 answer,
            ,
            ,
        ) = ETH_PRICE_FEED.latestRoundData();

        return uint256(
            answer
        );
    }

    /**
    * @dev Retrieves the pool address for given
    * tokens and fee from Uniswap V3 Factory.
    */
    function _getPool(
        address _token0,
        address _token1,
        uint24 _fee
    )
        internal
        view
        returns (address pool)
    {
        return UNI_V3_FACTORY.getPool(
            _token0,
            _token1,
            _fee
        );
    }

    /**
    * @dev Validates if the given token address
    * is one of the two specified token addresses.
    */
    function _validateTokenAddress(
        address _tokenAddress,
        address _token0,
        address _token1
    )
        internal
        pure
    {
        if (_tokenAddress == ZERO_ADDRESS) {
            revert ZeroAddressNotAllowed();
        }

        if (_tokenAddress != _token0 && _tokenAddress != _token1) {
            revert TokenAddressMismatch();
        }
    }

    /**
    * @dev Validates if the given pool
    * address matches the expected pool address.
    */
    function _validatePoolAddress(
        address _pool,
        address _expectedPool
    )
        internal
        pure
    {
        if (_pool == ZERO_ADDRESS) {
            revert PoolDoesNotExist();
        }

        if (_pool != _expectedPool) {
            revert PoolAddressMismatch();
        }
    }

    /**
    * @dev Validates if the price feed for
    * a given token address is set.
    */
    function _validatePriceFeed(
        address _tokenAddress
    )
        internal
        view
    {
        if (priceFeed[_tokenAddress] == ZERO_FEED) {
            revert ChainLinkOracleNotSet();
        }
    }

    /**
    * @dev Validates if the TWAP oracle for
    * a given token address is already set.
    */
    function _validateTwapOracle(
        address _tokenAddress
    )
        internal
        view
    {
        if (uniTwapPoolInfo[_tokenAddress].oracle > ZERO_ADDRESS) {
            revert TwapOracleAlreadySet();
        }
    }

    /**
     * @dev Returns twapPrice by passing
     * the underlying token address.
     */
    function _getTwapPrice(
        address _tokenAddress,
        address _oracle
    )
        internal
        view
        returns (uint256)
    {
        return OracleLibrary.getQuoteAtTick(
            _getAverageTick(
                _oracle
            ),
            _getOneUnit(
                _tokenAddress
            ),
            _tokenAddress,
            WETH_ADDRESS
        );
    }

    function _getOneUnit(
        address _tokenAddress
    )
        internal
        view
        returns (uint128)
    {
        return uint128(
            10 ** _tokenDecimals[_tokenAddress]
        );
    }

    function _getAverageTick(
        address _oracle
    )
        internal
        view
        returns (int24)
    {
        uint32[] memory secondsAgo = new uint32[](
            2
        );

        secondsAgo[0] = TWAP_PERIOD;
        secondsAgo[1] = 0;

        (
            int56[] memory tickCumulatives
            ,
        ) = IUniswapV3Pool(_oracle).observe(
            secondsAgo
        );

        int56 twapPeriodInt56 = int56(
            int32(TWAP_PERIOD)
        );

        int56 tickCumulativesDelta = tickCumulatives[1]
            - tickCumulatives[0];

        int24 tick = int24(
            tickCumulativesDelta
            / twapPeriodInt56
        );

        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % twapPeriodInt56 != 0)) {
            tick--;
        }

        return tick;
    }

    /**
     * @dev Returns priceFeed decimals by
     * passing the underlying token address.
     */
    function decimals(
        address _tokenAddress
    )
        public
        view
        returns (uint8)
    {
        return priceFeed[_tokenAddress].decimals();
    }

    function _getTwapDerivatePrice(
        address _tokenAddress,
        UniTwapPoolInfo memory _uniTwapPoolInfo
    )
        internal
        view
        returns (uint256)
    {
        DerivativePartnerInfo memory partnerInfo = derivativePartnerTwap[
            _tokenAddress
        ];

        uint256 firstQuote = OracleLibrary.getQuoteAtTick(
            _getAverageTick(
                _uniTwapPoolInfo.oracle
            ),
            _getOneUnit(
                partnerInfo.partnerTokenAddress
            ),
            partnerInfo.partnerTokenAddress,
            WETH_ADDRESS
        );

        uint256 secondQuote = OracleLibrary.getQuoteAtTick(
            _getAverageTick(
                partnerInfo.partnerOracleAddress
            ),
            _getOneUnit(
                _tokenAddress
            ),
            _tokenAddress,
            partnerInfo.partnerTokenAddress
        );

        return firstQuote
            * secondQuote
            / uint256(
                _getOneUnit(
                    partnerInfo.partnerTokenAddress
                )
            );
    }

    /**
     * @dev Stores expected heartbeat
     * value for a pricing feed token.
     */
    function _recalibrate(
        address _tokenAddress
    )
        internal
    {
        heartBeat[_tokenAddress] = _recalibratePreview(
            _tokenAddress
        );
    }

    /**
     * @dev Check if chainLink
     * squencer is wroking.
     */
    function sequencerIsDead()
        public
        view
        returns (bool)
    {
        if (IS_ARBITRUM_CHAIN == false) {
            return false;
        }

        (
            ,
            int256 answer,
            uint256 startedAt,
            ,
        ) = SEQUENCER.latestRoundData();

        if (answer == 1) {
            return true;
        }

        uint256 timeSinceUp = block.timestamp
            - startedAt;

        if (timeSinceUp <= GRACE_PEROID) {
            return true;
        }

        return false;
    }

    /**
     * @dev Check if chainLink feed was
     * updated within expected timeFrame
     * for single {_tokenAddress}.
     */
    function _chainLinkIsDead(
        address _tokenAddress
    )
        internal
        view
        returns (bool)
    {
        if (heartBeat[_tokenAddress] == 0) {
            revert HeartBeatNotSet();
        }

        uint80 latestRoundId = getLatestRoundId(
            _tokenAddress
        );

        uint256 upd = _getRoundTimestamp(
            _tokenAddress,
            latestRoundId
        );

        unchecked {
            upd = block.timestamp < upd
                ? block.timestamp
                : block.timestamp - upd;

            return upd > heartBeat[_tokenAddress];
        }
    }

    /**
     * @dev Recalibrates expected
     * heartbeat for a pricing feed.
     */
    function _recalibratePreview(
        address _tokenAddress
    )
        internal
        view
        returns (uint256)
    {
        uint80 latestRoundId = getLatestRoundId(
            _tokenAddress
        );

        uint256 latestTimestamp = _getRoundTimestamp(
            _tokenAddress,
            latestRoundId
        );

        uint80 iterationCount = _getIterationCount(
            latestRoundId
        );

        if (iterationCount < MIN_ITERATION_COUNT) {
            revert SampleTooSmall(
                {
                    size: iterationCount
                }
            );
        }

        uint80 i = 1;
        uint256 currentDiff;
        uint256 currentBiggest;
        uint256 currentSecondBiggest;

        while (i < iterationCount) {

            uint256 currentTimestamp = _getRoundTimestamp(
                _tokenAddress,
                latestRoundId - i
            );

            currentDiff = latestTimestamp
                - currentTimestamp;

            latestTimestamp = currentTimestamp;

            if (currentDiff >= currentBiggest) {

                currentSecondBiggest = currentBiggest;
                currentBiggest = currentDiff;

            } else if (currentDiff > currentSecondBiggest) {
                currentSecondBiggest = currentDiff;
            }

            unchecked {
                ++i;
            }
        }

        return currentSecondBiggest;
    }

    /**
     * @dev Determines number of iterations
     * needed during heartbeat recalibration.
     */
    function _getIterationCount(
        uint80 _latestAggregatorRoundId
    )
        internal
        pure
        returns (uint80 res)
    {
        res = _latestAggregatorRoundId < MAX_ROUND_COUNT
            ? _latestAggregatorRoundId
            : MAX_ROUND_COUNT;
    }

    /**
     * @dev Fetches timestamp of a byteshifted
     * aggregatorRound with specific _roundId.
     */
    function _getRoundTimestamp(
        address _tokenAddress,
        uint80 _roundId
    )
        internal
        view
        returns (uint256)
    {
        (
            ,
            ,
            ,
            uint256 timestamp
            ,
        ) = priceFeed[_tokenAddress].getRoundData(
                _roundId
            );

        return timestamp;
    }

    /**
     * @dev Routing latest round data from chainLink.
     * Returns latestRoundData by passing underlying token address.
     */
    function getLatestRoundId(
        address _tokenAddress
    )
        public
        view
        returns (
            uint80 roundId
        )
    {
        (
            roundId
            ,
            ,
            ,
            ,
        ) = priceFeed[_tokenAddress].latestRoundData();
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "../InterfaceHub/IERC20.sol";
import "../InterfaceHub/IPriceFeed.sol";

import "./Libraries/IUniswapV3Factory.sol";
import "./Libraries/OracleLibrary.sol";

import "../OwnableMaster.sol";

error OracleIsDead();
error OraclesDeviate();
error OracleAlreadySet();
error ChainLinkOracleNotSet();

error SampleTooSmall(
    uint256 size
);

error HeartBeatNotSet();
error PoolDoesNotExist();
error PoolAddressMismatch();
error TokenAddressMismatch();
error TwapOracleAlreadySet();
error ZeroAddressNotAllowed();

abstract contract Declarations is OwnableMaster {

    struct UniTwapPoolInfo {
        bool isUniPool;
        address oracle;
    }

    struct DerivativePartnerInfo {
        address partnerTokenAddress;
        address partnerOracleAddress;
    }

    constructor(
        address _wethAddress,
        address _ethPriceFeed,
        address _uniswapV3Factory
    )
        OwnableMaster(
            msg.sender
        )
    {
        WETH_ADDRESS = _wethAddress;

        _decimalsWETH = IERC20(
            WETH_ADDRESS
        ).decimals();

        ETH_PRICE_FEED = IPriceFeed(
            _ethPriceFeed
        );

        UNI_V3_FACTORY = IUniswapV3Factory(
            _uniswapV3Factory
        );

        SEQUENCER = IPriceFeed(
            SEQUENCER_ADDRESS
        );

        IS_ARBITRUM_CHAIN = block.chainid == ARBITRUM_CHAIN_ID;
    }

    // Address of WETH token on Mainnet
    address public immutable WETH_ADDRESS;

    // Sequencer address on Arbitrum
    address public constant SEQUENCER_ADDRESS = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;

    // Target Decimals of the returned WETH values.
    uint8 internal immutable _decimalsWETH;

    // ChainLink ETH price feed ETH to USD value.
    IPriceFeed public immutable ETH_PRICE_FEED;

    // Chainlink sequencer interface for L2 communication
    IPriceFeed public immutable SEQUENCER;

    // Uniswap Factory interface
    IUniswapV3Factory public immutable UNI_V3_FACTORY;

    // Target Decimals of the returned USD values.
    uint8 internal constant _decimalsUSD = 8;

    // Target Decimals of the returned ETH values.
    uint8 internal constant _decimalsETH = 18;

    // Number of last rounds which are checked for heartbeat.
    uint80 internal constant MAX_ROUND_COUNT = 50;

    // Define the number of seconds in a minute.
    uint32 internal constant SECONDS_IN_MINUTE = 60;

    // Define TWAP period in seconds.
    uint32 internal constant TWAP_PERIOD = 30 * SECONDS_IN_MINUTE;

    // Allowed difference between oracle values.
    uint256 internal ALLOWED_DIFFERENCE = 10250;

    // Minimum iteration count for median calculation.
    uint256 internal constant MIN_ITERATION_COUNT = 3;

    // Precision factor for ETH values.
    uint256 internal constant PRECISION_FACTOR_E4 = 1E4;

    // Time period to wait when sequencer is active again.
    uint256 internal constant GRACE_PEROID = 3600;

    // Value address used for empty feed comparison.
    IPriceFeed internal constant ZERO_FEED = IPriceFeed(
        address(0x0)
    );

    bool internal immutable IS_ARBITRUM_CHAIN;
    uint256 internal constant ARBITRUM_CHAIN_ID = 42161;

    // -- Mapping values --

    // Stores decimals of specific ERC20 token.
    mapping(address => uint8) _tokenDecimals;

    // Stores the price feed address from oracle sources.
    mapping(address => IPriceFeed) public priceFeed;

    // Stores the time between chainLink heartbeats.
    mapping(address => uint256) public heartBeat;

    // Mapping underlying feed token for multi token derivate oracle.
    mapping(address => address[]) public underlyingFeedTokens;

    // Stores the uniswap twap pool or derivative info.
    mapping(address => UniTwapPoolInfo) public uniTwapPoolInfo;

    // Stores the derivative partner address of the TWAP.
    mapping(address => DerivativePartnerInfo) public derivativePartnerTwap;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

interface IERC20 {

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool);

    function decimals()
        external
        view
        returns (uint8);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event  Deposit(
        address indexed dst,
        uint wad
    );

    event  Withdrawal(
        address indexed src,
        uint wad
    );
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

interface IPriceFeed {

    function decimals()
        external
        view
        returns (uint8);

    function description()
        external
        view
        returns (string memory);

    function version()
        external
        view
        returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
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

    function latestAnswer()
        external
        view
        returns (uint256);

    function phaseId()
        external
        view
        returns (uint16);

    function aggregator()
        external
        view
        returns (address);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev _tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param _tokenA The contract address of either token0 or token1
    /// @param _tokenB The contract address of the other token
    /// @param _fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address _tokenA,
        address _tokenB,
        uint24 _fee
    )
        external
        view
        returns (address pool);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./FullMath.sol";
import "./TickMath.sol";
import "./IUniswapV3Pool.sol";

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param _tick Tick value used to calculate the quote
    /// @param _baseAmount Amount of token to be converted
    /// @param _baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param _quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 _tick,
        uint128 _baseAmount,
        address _baseToken,
        address _quoteToken
    )
        internal
        pure
        returns (uint256 quoteAmount)
    {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(
            _tick
        );

        // Calculate quoteAmount with better precision
        // if it doesn't overflow when multiplied by itself

        if (sqrtRatioX96 <= type(uint128).max) {

            uint256 ratioX192 = uint256(sqrtRatioX96)
                * sqrtRatioX96;

            quoteAmount = _baseToken < _quoteToken
                ? FullMath.mulDiv(
                    ratioX192,
                    _baseAmount,
                    1 << 192
                )
                : FullMath.mulDiv(
                    1 << 192,
                    _baseAmount,
                    ratioX192
                );

            return quoteAmount;
        }

        uint256 ratioX128 = FullMath.mulDiv(
            sqrtRatioX96,
            sqrtRatioX96,
            1 << 64
        );

        quoteAmount = _baseToken < _quoteToken
            ? FullMath.mulDiv(
                ratioX128,
                _baseAmount,
                1 << 128
            )
            : FullMath.mulDiv(
                1 << 128,
                _baseAmount,
                ratioX128
            );

        return quoteAmount;
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

error NoValue();
error NotMaster();
error NotProposed();

contract OwnableMaster {

    address public master;
    address public proposedMaster;

    address internal constant ZERO_ADDRESS = address(0x0);

    modifier onlyProposed() {
        _onlyProposed();
        _;
    }

    function _onlyMaster()
        private
        view
    {
        if (msg.sender == master) {
            return;
        }

        revert NotMaster();
    }

    modifier onlyMaster() {
        _onlyMaster();
        _;
    }

    function _onlyProposed()
        private
        view
    {
        if (msg.sender == proposedMaster) {
            return;
        }

        revert NotProposed();
    }

    constructor(
        address _master
    ) {
        if (_master == ZERO_ADDRESS) {
            revert NoValue();
        }
        master = _master;
    }

    /**
     * @dev Allows to propose next master.
     * Must be claimed by proposer.
     */
    function proposeOwner(
        address _proposedOwner
    )
        external
        onlyMaster
    {
        if (_proposedOwner == ZERO_ADDRESS) {
            revert NoValue();
        }

        proposedMaster = _proposedOwner;
    }

    /**
     * @dev Allows to claim master role.
     * Must be called by proposer.
     */
    function claimOwnership()
        external
        onlyProposed
    {
        master = proposedMaster;
    }

    /**
     * @dev Removes master role.
     * No ability to be in control.
     */
    function renounceOwnership()
        external
        onlyMaster
    {
        master = ZERO_ADDRESS;
        proposedMaster = ZERO_ADDRESS;
    }
}

// SPDX-License-Identifier: -- WISE --
pragma solidity =0.8.23;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param _a The multiplicand
    /// @param _b The multiplier
    /// @param _denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 _a,
        uint256 _b,
        uint256 _denominator
    )
        internal
        pure
        returns (uint256 result)
    {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(_a, _b, not(0))
                prod0 := mul(_a, _b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(_denominator > 0);
                assembly {
                    result := div(prod0, _denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents _denominator == 0
            require(_denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(_a, _b, _denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of _denominator
            // Compute largest power of two divisor of _denominator.
            // Always >= 1.
            uint256 twos = (0 - _denominator) & _denominator;
            // Divide _denominator by power of two
            assembly {
                _denominator := div(_denominator, twos)
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

            // Invert _denominator mod 2**256
            // Now that _denominator is an odd number, it has an inverse
            // modulo 2**256 such that _denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, _denominator * inv = 1 mod 2**4
            uint256 inv = (3 * _denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - _denominator * inv; // inverse mod 2**8
            inv *= 2 - _denominator * inv; // inverse mod 2**16
            inv *= 2 - _denominator * inv; // inverse mod 2**32
            inv *= 2 - _denominator * inv; // inverse mod 2**64
            inv *= 2 - _denominator * inv; // inverse mod 2**128
            inv *= 2 - _denominator * inv; // inverse mod 2**256

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
    /// @param _a The multiplicand
    /// @param _b The multiplier
    /// @param _denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 _a,
        uint256 _b,
        uint256 _denominator
    )
        internal
        pure
        returns (uint256 result)
    {
        unchecked {
            result = mulDiv(
                _a,
                _b,
                _denominator
            );

            if (mulmod(_a, _b, _denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.23;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param _tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(
        int24 _tick
    )
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        unchecked {
            uint256 absTick = _tick < 0 ? uint256(-int256(_tick)) : uint256(int256(_tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (_tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param _sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(
        uint160 _sqrtPriceX96
    )
        internal
        pure
        returns (int24 tick)
    {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(_sqrtPriceX96 >= MIN_SQRT_RATIO && _sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(_sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi
                ? tickLow
                : getSqrtRatioAtTick(tickHi) <= _sqrtPriceX96
                    ? tickHi
                    : tickLow;
        }
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import './IUniswapV3PoolDerivedState.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is IUniswapV3PoolDerivedState {
    function slot0(
  )
    external
    view
    returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

interface IUniswapV3PoolDerivedState {

    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param _secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(
        uint32[] calldata _secondsAgos
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );
}