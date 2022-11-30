// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./interfaces/IERC20.sol";
import "./interfaces/IPriceOracle.sol";
import "./external/SafeOwnable.sol";

import "./interfaces/IStaticOracle.sol";

interface IExternalOracle {
    function price(address _token) external view returns (uint256);

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

/// @title Oracle aggergator for uni and link oracles
/// @author flora.loans
/// @notice Owner can set Chainlink oracles for specific tokens
/// @notice returns the token price from chainlink oracle (if available) otherwise the uni oracle will be used
/// @dev
/// @custom:this contract is configured for Arbitrum mainnet
contract UnifiedOracleAggregator is IPriceOracle, SafeOwnable {
    // Net deployed yet on arbigoerli
    IStaticOracle public constant uniswapStaticOracle =
        IStaticOracle(0x3bA0d4aF8f310186a205db6501CcD040793E9F3d); //Arbitrum -> but same address accross all networks

    // address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; //Arbitrum
    address internal constant WETH = 0xCFb46152fa89d1eE91716961e7D8854df527d8EC; //Arbitrum GOERLI
    mapping(address => IExternalOracle) public linkOracles;

    event SetOracle(address indexed token, address indexed linkOracles);

    /// @dev todo check _value param data type
    function setOracle(address _token, IExternalOracle _linkOracle)
        external
        onlyOwner
    {
        require(address(_linkOracle) != address(0), "oracle address");

        //TODO should check oracle-liveness: require _linkOracle.latestTimestamp > (block.timestamp - X)
        // Function deprecated, new function available: latestTransmissionDetails in AggregatorV3

        linkOracles[_token] = _linkOracle;
        emit SetOracle(_token, address(_linkOracle));
    }

    /// @notice Will increase observations for all existing pools for the given pair, so they start accruing information for twap calculations
    /// @dev Will revert if there are no pools available for the pair and period combination
    /// @param _tokenA One of the pair's tokens
    /// @param _tokenB The other of the pair's tokens
    /// @param _cardinality The cardinality that will be guaranteed when quoting
    function preparePool(
        address _tokenA,
        address _tokenB,
        uint16 _cardinality
    ) external {
        address[] memory _preparedPools = uniswapStaticOracle
            .prepareAllAvailablePoolsWithCardinality(
                _tokenA,
                _tokenB,
                _cardinality
            );

        //Check here as well, to make sure pools are available
        require(
            _preparedPools.length > 0,
            "UnifiedOracleAggregator: No pools found"
        );
    }

    /// @notice returns a bool indicating if a given token has an oracle
    /// @notice if no linkOracle is set -> check for uni TWAP oracle
    /// @param _token token to be queried
    /// @dev always queries the _token<->WETH pool, token order doesnt matter
    function tokenSupported(address _token)
        external
        view
        override
        returns (bool)
    {
        if (_token == WETH) {
            return true;
        }
        if (address(linkOracles[_token]) != address(0)) {
            return true;
        }
        return uniswapStaticOracle.isPairSupported(WETH, _token);
    }

    /// @notice returns the token price in ETH
    /// @notice Uses link oracle if configured otherwise uses uniOracle over all fee tiers for 30min
    /// @param _token token to fetch the price for
    /// @return Returns the price of 1 Token in ETH
    /// @dev TODO write test
    function tokenPrice(address _token) public view override returns (uint256) {
        if (_token == WETH) {
            return 1e18;
        }

        //Using preSet Chainlink oracle
        if (address(linkOracles[_token]) != address(0)) {
            (, int256 price, , , ) = IExternalOracle(linkOracles[_token])
                .latestRoundData();

            return uint256(price);
        }

        //Using Uniswap Static Oracle isPairSupported chcks if the pool actually exiists
        require(uniswapStaticOracle.isPairSupported(WETH, _token));

        (uint256 quotedAmount, ) = uniswapStaticOracle
            .quoteAllAvailablePoolsWithTimePeriod(1, _token, WETH, 3600);
        return quotedAmount;
    }

    /// @notice returns the price of two tokens
    /// @param _tokenA token to fetch the price for
    /// @param _tokenB token to fetch the price for
    function tokenPrices(address _tokenA, address _tokenB)
        public
        view
        returns (uint256, uint256)
    {
        return (tokenPrice(_tokenA), tokenPrice(_tokenB));
    }

    /// @dev Not used in any code to save gas. But useful for external usage.
    function convertTokenValues(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) external view override returns (uint256) {
        uint256 priceFrom = (tokenPrice(_fromToken) * 1e18) /
            10**IERC20(_fromToken).decimals();
        uint256 priceTo = (tokenPrice(_toToken) * 1e18) /
            10**IERC20(_toToken).decimals();
        return (_amount * priceFrom) / priceTo;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function decimals() external view returns (uint8);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

interface IPriceOracle {
    function tokenPrice(address _token) external view returns (uint256);

    function tokenSupported(address _token) external view returns (bool);

    function convertTokenValues(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

import "../interfaces/IOwnable.sol";

contract SafeOwnable is IOwnable {
    uint public constant RENOUNCE_TIMEOUT = 1 hours;

    address public override owner;
    address public pendingOwner;
    uint public renouncedAt;

    event OwnershipTransferInitiated(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferConfirmed(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferConfirmed(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function transferOwnership(address _newOwner) external override onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferInitiated(owner, _newOwner);
        pendingOwner = _newOwner;
    }

    function acceptOwnership() external override {
        require(
            msg.sender == pendingOwner,
            "Ownable: caller is not pending owner"
        );
        emit OwnershipTransferConfirmed(msg.sender, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function initiateRenounceOwnership() external onlyOwner {
        require(renouncedAt == 0, "Ownable: already initiated");
        renouncedAt = block.timestamp;
    }

    function acceptRenounceOwnership() external onlyOwner {
        require(renouncedAt > 0, "Ownable: not initiated");
        require(
            block.timestamp - renouncedAt > RENOUNCE_TIMEOUT,
            "Ownable: too early"
        );
        owner = address(0);
        pendingOwner = address(0);
        renouncedAt = 0;
    }

    function cancelRenounceOwnership() external onlyOwner {
        require(renouncedAt > 0, "Ownable: not initiated");
        renouncedAt = 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6 <0.9.0;

import "../uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

/// @title Uniswap V3 Static Oracle
/// @notice Oracle contract for calculating price quoting against Uniswap V3
interface IStaticOracle {
    /// @notice Returns the address of the Uniswap V3 factory
    /// @dev This value is assigned during deployment and cannot be changed
    /// @return The address of the Uniswap V3 factory
    function UNISWAP_V3_FACTORY() external view returns (IUniswapV3Factory);

    /// @notice Returns how many observations are needed per minute in Uniswap V3 oracles, on the deployed chain
    /// @dev This value is assigned during deployment and cannot be changed
    /// @return Number of observation that are needed per minute
    function CARDINALITY_PER_MINUTE() external view returns (uint8);

    /// @notice Returns all supported fee tiers
    /// @return The supported fee tiers
    function supportedFeeTiers() external view returns (uint24[] memory);

    /// @notice Returns whether a specific pair can be supported by the oracle
    /// @dev The pair can be provided in tokenA/tokenB or tokenB/tokenA order
    /// @return Whether the given pair can be supported by the oracle
    function isPairSupported(address tokenA, address tokenB)
        external
        view
        returns (bool);

    /// @notice Returns all existing pools for the given pair
    /// @dev The pair can be provided in tokenA/tokenB or tokenB/tokenA order
    /// @return All existing pools for the given pair
    function getAllPoolsForPair(address tokenA, address tokenB)
        external
        view
        returns (address[] memory);

    /// @notice Returns a quote, based on the given tokens and amount, by querying all of the pair's pools
    /// @dev If some pools are not configured correctly for the given period, then they will be ignored
    /// @dev Will revert if there are no pools available/configured for the pair and period combination
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @param period Number of seconds from which to calculate the TWAP
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    /// @return queriedPools The pools that were queried to calculate the quote
    function quoteAllAvailablePoolsWithTimePeriod(
        uint128 baseAmount,
        address baseToken,
        address quoteToken,
        uint32 period
    )
        external
        view
        returns (uint256 quoteAmount, address[] memory queriedPools);

    /// @notice Returns a quote, based on the given tokens and amount, by querying only the specified fee tiers
    /// @dev Will revert if the pair does not have a pool for one of the given fee tiers, or if one of the pools
    /// is not prepared/configured correctly for the given period
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @param feeTiers The fee tiers to consider when calculating the quote
    /// @param period Number of seconds from which to calculate the TWAP
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    /// @return queriedPools The pools that were queried to calculate the quote
    function quoteSpecificFeeTiersWithTimePeriod(
        uint128 baseAmount,
        address baseToken,
        address quoteToken,
        uint24[] calldata feeTiers,
        uint32 period
    )
        external
        view
        returns (uint256 quoteAmount, address[] memory queriedPools);

    /// @notice Returns a quote, based on the given tokens and amount, by querying only the specified pools
    /// @dev Will revert if one of the pools is not prepared/configured correctly for the given period
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @param pools The pools to consider when calculating the quote
    /// @param period Number of seconds from which to calculate the TWAP
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function quoteSpecificPoolsWithTimePeriod(
        uint128 baseAmount,
        address baseToken,
        address quoteToken,
        address[] calldata pools,
        uint32 period
    ) external view returns (uint256 quoteAmount);

    /// @notice Will initialize all existing pools for the given pair, so that they can be queried with the given period in the future
    /// @dev Will revert if there are no pools available for the pair and period combination
    /// @param tokenA One of the pair's tokens
    /// @param tokenB The other of the pair's tokens
    /// @param period The period that will be guaranteed when quoting
    /// @return preparedPools The pools that were prepared
    function prepareAllAvailablePoolsWithTimePeriod(
        address tokenA,
        address tokenB,
        uint32 period
    ) external returns (address[] memory preparedPools);

    /// @notice Will initialize the pair's pools with the specified fee tiers, so that they can be queried with the given period in the future
    /// @dev Will revert if the pair does not have a pool for a given fee tier
    /// @param tokenA One of the pair's tokens
    /// @param tokenB The other of the pair's tokens
    /// @param feeTiers The fee tiers to consider when searching for the pair's pools
    /// @param period The period that will be guaranteed when quoting
    /// @return preparedPools The pools that were prepared
    function prepareSpecificFeeTiersWithTimePeriod(
        address tokenA,
        address tokenB,
        uint24[] calldata feeTiers,
        uint32 period
    ) external returns (address[] memory preparedPools);

    /// @notice Will initialize all given pools, so that they can be queried with the given period in the future
    /// @param pools The pools to initialize
    /// @param period The period that will be guaranteed when quoting
    function prepareSpecificPoolsWithTimePeriod(
        address[] calldata pools,
        uint32 period
    ) external;

    /// @notice Will increase observations for all existing pools for the given pair, so they start accruing information for twap calculations
    /// @dev Will revert if there are no pools available for the pair and period combination
    /// @param tokenA One of the pair's tokens
    /// @param tokenB The other of the pair's tokens
    /// @param cardinality The cardinality that will be guaranteed when quoting
    /// @return preparedPools The pools that were prepared
    function prepareAllAvailablePoolsWithCardinality(
        address tokenA,
        address tokenB,
        uint16 cardinality
    ) external returns (address[] memory preparedPools);

    /// @notice Will increase the pair's pools with the specified fee tiers observations, so they start accruing information for twap calculations
    /// @dev Will revert if the pair does not have a pool for a given fee tier
    /// @param tokenA One of the pair's tokens
    /// @param tokenB The other of the pair's tokens
    /// @param feeTiers The fee tiers to consider when searching for the pair's pools
    /// @param cardinality The cardinality that will be guaranteed when quoting
    /// @return preparedPools The pools that were prepared
    function prepareSpecificFeeTiersWithCardinality(
        address tokenA,
        address tokenB,
        uint24[] calldata feeTiers,
        uint16 cardinality
    ) external returns (address[] memory preparedPools);

    /// @notice Will increase all given pools observations, so they start accruing information for twap calculations
    /// @param pools The pools to initialize
    /// @param cardinality The cardinality that will be guaranteed when quoting
    function prepareSpecificPoolsWithCardinality(
        address[] calldata pools,
        uint16 cardinality
    ) external;

    /// @notice Adds support for a new fee tier
    /// @dev Will revert if the given tier is invalid, or already supported
    /// @param feeTier The new fee tier to add
    function addNewFeeTier(uint24 feeTier) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}