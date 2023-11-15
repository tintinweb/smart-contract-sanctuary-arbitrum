//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusNebulaRegistry.sol
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
    
           █████████                🛸         🛸                              🛸          .                    
     🛸   ███░░░░░███                                              📡                                     🌔   
         ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
        ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀        🛰️   .             
        ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
        ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             .           
         ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████       -----========*⠀
          ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                            .
                       ███ ░███  ███ ░███                .                 .         🛸           ⠀             
         .    🛸*     ░░██████  ░░██████   .    🛸                     🛰️            -----=========*                 
                       ░░░░░░    ░░░░░░                                               🛸  ⠀
           .                            .       .             🛰️         .                          
    
        CYGNUS NEBULA REGISTRY - https://cygnusdao.finance                                                          .                     .
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════ */
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusNebulaRegistry} from "./interfaces/ICygnusNebulaRegistry.sol";
import {ICygnusNebula} from "./interfaces/ICygnusNebula.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

// Libraries

// Interfaces
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {IERC20} from "./interfaces/IERC20.sol";

/**
 *  @title  CygnusNebulaRegistry
 *  @author CygnusDAO
 *  @notice Registry of all nebulas deployed by CygnusDAO. A nebula is a contract which contains the logic to
 *          price specific Liquidity Tokens. For example, Balancer Weighted Pools requires different logic than
 *          UniswapV2 pairs to price the liquidity token, so we must deploy separate logic for each. A nebula
 *          oracle is a unique LP oracle within the nebula.
 *
 *          Each nebula we deploy must have this registry's address as the registry is the only one that can
 *          initialize a specific Liquidity Token in the nebula.
 *
 *          At the time of pool deployment, the hangar18 contract checks this contract to see if the liquidity
 *          token has been added to the registry via `getLPTokenNebulaAddress`. If it hasn't, then the pool cannot
 *          be deployed as the collateral cannot be priced.
 */
contract CygnusNebulaRegistry is ICygnusNebulaRegistry, ReentrancyGuard {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Storage mapping for LP Token => Nebula address
     */
    mapping(address => address) internal lpNebulas;

    /**
     *  @notice Storage mapping for Nebula address => Nebula struct
     */
    mapping(address => CygnusNebula) internal nebulas;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    CygnusNebula[] public override allNebulas;

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    address[] public allLPTokenPairs;

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    string public override name = "Cygnus: Nebula Registry";

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    string public override version = "1.0.0";

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    address public override admin;

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    address public override pendingAdmin;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs the Oracle registry
     */
    constructor() {
        // Assign the admin
        admin = msg.sender;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:modifier cygnusAdmin Modifier for admin control only 👽
     */
    modifier cygnusAdmin() {
        isCygnusAdmin();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Internal check for admin control only 👽
     */
    function isCygnusAdmin() internal view {
        /// @custom:error MsgSenderNotAdmin Avoid unless caller is Cygnus Admin
        if (msg.sender != admin) revert CygnusNebula__SenderNotAdmin();
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    function allNebulasLength() public view override returns (uint256) {
        // Total initialized nebulas
        return allNebulas.length;
    }

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    function allLPTokenPairsLength() public view override returns (uint256) {
        // Total initialized LP Token pairs
        return allLPTokenPairs.length;
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    function getNebula(address nebula) external view override returns (CygnusNebula memory) {
        // Return the nebula struct for this `_nebula`
        return nebulas[nebula];
    }

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    function getLPTokenNebula(address lpTokenPair) external view override returns (CygnusNebula memory) {
        // Get the stored nebula for `lpTokenPair`
        address nebula = lpNebulas[lpTokenPair];

        // Return the nebula struct for this `lpTokenPair`
        return nebulas[nebula];
    }

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    function getLPTokenNebulaAddress(address lpTokenPair) external view override returns (address) {
        // Return the address of the nebula for this `lpTokenPair`
        // If not set then returns zero address
        return lpNebulas[lpTokenPair];
    }

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    function getLPTokenNebulaOracle(address lpTokenPair) external view override returns (ICygnusNebula.NebulaOracle memory) {
        // Get the stored nebula for the LP Token
        address nebula = lpNebulas[lpTokenPair];

        // Return the oracle struct
        return ICygnusNebula(nebula).getNebulaOracle(lpTokenPair);
    }

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    function getLPTokenPriceUsd(address lpTokenPair) external view override returns (uint256) {
        // Get the stored nebula for the LP Token
        address nebula = lpNebulas[lpTokenPair];

        // Return the price of the LP in the oracle`s denomination token (in our case USDC)
        // IMPORTANT: Do not use this in any important contract since the oracle never does safety checks,
        // such as assuring price != 0, etc.
        return ICygnusNebula(nebula).lpTokenPriceUsd(lpTokenPair);
    }

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     */
    function getLPTokenInfo(
        address lpTokenPair
    )
        external
        view
        override
        returns (
            IERC20[] memory tokens,
            uint256[] memory prices,
            uint256[] memory reserves,
            uint256[] memory tokenDecimals,
            uint256[] memory reservesUsd
        )
    {
        // Get the stored nebula for the LP Token
        address nebula = lpNebulas[lpTokenPair];

        // Return the current info of the LP
        // IMPORTANT: Do not use this on-chain, this function is for convention and reporting purposes only
        return ICygnusNebula(nebula).lpTokenInfo(lpTokenPair);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     *  @custom:security only-admin 👽
     */
    function createNebulaOracle(
        uint256 nebulaId,
        address lpTokenPair,
        AggregatorV3Interface[] calldata aggregators,
        bool isOverride
    ) external override cygnusAdmin {
        // Get nebula address
        CygnusNebula storage nebula = allNebulas[nebulaId];

        // Initialize nebula. Will revert if it has already been initialized and we are outside grace period
        ICygnusNebula(nebula.nebulaAddress).initializeNebulaOracle(lpTokenPair, aggregators);

        // If this is the first time we initialize this oracle;
        // Account for cases where we modify the oracle during grace period
        if (lpNebulas[lpTokenPair] == address(0)) allLPTokenPairs.push(lpTokenPair);

        // If we are not overriding then we add oracle to nebula (this is done for quick info purposes)
        if (!isOverride) nebula.totalOracles++;

        // Map LP Token => Nebula address
        // This is intentinally left outside of the above if statement. If we need to re-deploy an oracle
        // and initialize lp tokens, then we override the `lpNebulas` mapping, and future shuttles
        // deployed by the factory will use this new oracle instead.
        lpNebulas[lpTokenPair] = nebula.nebulaAddress;

        // Map Nebula address => Nebula struct
        nebulas[nebula.nebulaAddress] = nebula;
    }

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     *  @custom:security only-admin 👽
     */
    function createNebula(address _nebula) external override cygnusAdmin {
        /// @custom:error NebulaAlreadyCreated
        if (nebulas[_nebula].createdAt != 0) revert CygnusNebula__NebulaAlreadyCreated();

        // Create new nebula since it passed checks
        CygnusNebula memory nebula = CygnusNebula({
            name: ICygnusNebula(_nebula).name(),
            nebulaAddress: _nebula,
            nebulaId: allNebulasLength(),
            totalOracles: 0,
            createdAt: block.timestamp
        });

        // Add nebula to array
        allNebulas.push(nebula);

        // Add nebula to mapping
        nebulas[_nebula] = nebula;

        /// @custom:event NewNebulaOracle
        emit NewNebulaOracle(_nebula, nebula.nebulaId);
    }

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     *  @custom:security only-admin 👽
     */
    function setRegistryPendingAdmin(address newPendingAdmin) external override cygnusAdmin {
        // Pending admin initial is always zero
        /// @custom:error PendingAdminAlreadySet Avoid setting the same pending admin twice
        if (newPendingAdmin == admin) revert CygnusNebula__AdminAlreadySet();

        // Assign address of the requested admin
        pendingAdmin = newPendingAdmin;

        /// @custom:event NewOraclePendingAdmin
        emit NewNebulaPendingAdmin(admin, newPendingAdmin);
    }

    /**
     *  @inheritdoc ICygnusNebulaRegistry
     *  @custom:security only-pending-admin
     */
    function acceptRegistryAdmin() external override {
        /// @custom:error SenderNotPendingAdmin Avoid if sender is not pending admin
        if (msg.sender != pendingAdmin) revert CygnusNebula__SenderNotPendingAdmin();

        // Address of the Admin up until now
        address oldAdmin = admin;

        // Assign new admin
        admin = pendingAdmin;

        // Gas refund
        delete pendingAdmin;

        // @custom:event NewOracleAdmin
        emit NewNebulaAdmin(oldAdmin, admin);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

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

    function latestAnswer() external view returns (int256);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusNebula.sol
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
     *  @dev Reverts when the initializer of the oracle is not the registry address
     *
     *  @param sender The msg.sender
     *
     *  @custom:error MsgSenderNotRegistry
     */
    error CygnusNebulaOracle__MsgSenderNotRegistry(address sender);

    /**
     *  @dev Prevents cross-contracnt reentrancy
     *
     *  @custom:error AlreadyInContext
     */
    error CygnusNebulaOracle__AlreadyInContext();

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
        uint256 createdAt;
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
     *  @return The version of this oracle
     */
    function version() external view returns (string memory);

    /**
     *  @return SECONDS_PER_YEAR The number of seconds in year assumed by the oracle
     */
    function SECONDS_PER_YEAR() external view returns (uint256);

    /**
     *  @return GRACE_PERIOD The time period where oracle can be modified (1 hour)
     */
    function GRACE_PERIOD() external pure returns (uint256);

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

    /**
     *  @return S The selector of a non-reentrant function in the underlying LP pair to ensure we are not within the pair's context
     */
    function S() external pure returns (bytes4);

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
     *  @notice Gets the latest info for an initialized LP Token
     *  @notice Can be used to calculate optimal amount of leverage, avoid calling on-chain.
     *
     *  @param lpTokenPair The address of the LP Token
     *
     *  @return tokens Array of addresses of all the LP's assets
     *  @return prices Array of prices of each asset (in denom token)
     *  @return reserves Array of reserves of each asset in the LP
     *  @return tokenDecimals Array of decimals of each token
     *  @return reservesUsd Array of reserves of each asset in USD
     */
    function lpTokenInfo(
        address lpTokenPair
    )
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory prices,
            uint256[] memory reserves,
            uint256[] memory tokenDecimals,
            uint256[] memory reservesUsd
        );

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
//  ICygnusNebulaRegistry.sol
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
 *  @title ICygnusNebulaRegistry Interface to interact with Cygnus' LP Oracle
 *  @author CygnusDAO
 */
interface ICygnusNebulaRegistry {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when sender is not the pending admin
     *
     *  @custom:error SenderNotPendingAdmin
     */
    error CygnusNebula__SenderNotPendingAdmin();

    /**
     *  @dev Reverts when admin is already set
     *
     *  @custom:error AdminAlreadySet
     */
    error CygnusNebula__AdminAlreadySet();

    /**
     *  @dev Reverts when the msg.sender is not the registry's admin
     *
     *  @custom:error SenderNotAdmin
     */
    error CygnusNebula__SenderNotAdmin();

    /**
     *  @dev Reverts when creating a new nebula
     *
     *  @custom:error NebulaAlreadyCreated
     */
    error CygnusNebula__NebulaAlreadyCreated();

    /**
     *  @dev Reverts if the price we get for the `lpTokenPair` is 0
     *
     *  @custom:error PriceCantBeZero
     */
    error CygnusNebulaRegistry__PriceCantBeZero();

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
     *  @custom:member createdAt The timestamp of nebula creation
     */
    struct CygnusNebula {
        string name;
        address nebulaAddress;
        uint256 nebulaId;
        uint256 totalOracles;
        uint256 createdAt;
    }

    /**
     *  @return The name for the registry
     */
    function name() external view returns (string memory);

    /**
     *  @return Current version of the registry
     */
    function version() external view returns (string memory);

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
     *  @return createdAt The timestamp the admin created the nebula
     */
    function allNebulas(
        uint256 index
    ) external view returns (string memory _name, address _nebula, uint256 id, uint256 totalOracles, uint256 createdAt);

    /**
     *  @notice Array of initialized LP Token pairs
     *  @param index THe index of the nebula oracle
     *  @return lpTokenPair The address of the LP Token pair
     */
    function allLPTokenPairs(uint256 index) external view returns (address lpTokenPair);

    /**
     *  @notice Length of nebulas added
     */
    function allNebulasLength() external view returns (uint256);

    /**
     *  @notice Total LP Token pairs
     */
    function allLPTokenPairsLength() external view returns (uint256);

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
     *  @notice Get the Oracle for the LP token pair
     *  @param lpTokenPair The address of the LP Token pair
     */
    function getLPTokenNebulaOracle(address lpTokenPair) external view returns (ICygnusNebula.NebulaOracle memory);

    /**
     *  @notice Get the price the nebula reports for `lpTokenPair`
     *  @param lpTokenPair The address of the LP Token pair
     *  @return The price of the LP Token in USDC
     */
    function getLPTokenPriceUsd(address lpTokenPair) external view returns (uint256);

    /**
     *  @notice Gets the latest info for an initialized LP Token
     *  @param lpTokenPair The address of the LP Token
     *  @return tokens Array of addresses of all the LP's assets
     *  @return prices Array of prices of each asset (in denom token)
     *  @return reserves Array of reserves of each asset in the LP
     *  @return tokenDecimals Array of decimals of each token
     *  @return reservesUsd Array of reserves of each asset in USD
     */
    function getLPTokenInfo(
        address lpTokenPair
    )
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory prices,
            uint256[] memory reserves,
            uint256[] memory tokenDecimals,
            uint256[] memory reservesUsd
        );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Admin 👽
     *  @notice Initializes an oracle for the LP, mapping it to the nebula
     *
     *  @param nebulaId The ID of the nebula (ie. each nebula depends on the dex and the logic for calculating the LP Price)
     *  @param lpTokenPair The address of the LP Token
     *  @param aggregators Calldata array of Chainlink aggregators
     *  @param isOverride Whether or not we are overriding an existing oracle
     *
     *  @custom:security only-admin
     */
    function createNebulaOracle(uint256 nebulaId, address lpTokenPair, AggregatorV3Interface[] calldata aggregators, bool isOverride) external;

    /**
     *  @notice Admin 👽
     *  @notice Adds a new nebula to the registry
     *
     *  @param _nebula Address of the new nebula
     *
     *  @custom:security only-admin
     */
    function createNebula(address _nebula) external;

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
     *  @notice Sets a new admin for the Oracle
     *
     *  @custom:security only-pending-admin
     */
    function acceptRegistryAdmin() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

/// @title IERC20
/// @author Paul Razvan Berg
/// @notice Implementation for the Erc20 standard.
///
/// We have followed general OpenZeppelin guidelines: functions revert instead of returning
/// `false` on failure. This behavior is nonetheless conventional and does not conflict with
/// the with the expectations of Erc20 applications.
///
/// Additionally, an {Approval} event is emitted on calls to {transferFrom}. This allows
/// applications to reconstruct the allowance for all accounts just by listening to said
/// events. Other implementations of the Erc may not emit these events, as it isn't
/// required by the specification.
///
/// Finally, the non-standard {decreaseAllowance} and {increaseAllowance} functions have been
/// added to mitigate the well-known issues around setting allowances.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/ERC20.sol
interface IERC20 {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when the owner is the zero address.
    error Erc20__ApproveOwnerZeroAddress();

    /// @notice Emitted when the spender is the zero address.
    error Erc20__ApproveSpenderZeroAddress();

    /// @notice Emitted when burning more tokens than are in the account.
    error Erc20__BurnUnderflow(uint256 accountBalance, uint256 burnAmount);

    /// @notice Emitted when the holder is the zero address.
    error Erc20__BurnZeroAddress();

    /// @notice Emitted when the owner did not give the spender sufficient allowance.
    error Erc20__InsufficientAllowance(uint256 allowance, uint256 amount);

    /// @notice Emitted when tranferring more tokens than there are in the account.
    error Erc20__InsufficientBalance(uint256 senderBalance, uint256 amount);

    /// @notice Emitted when the beneficiary is the zero address.
    error Erc20__MintZeroAddress();

    /// @notice Emitted when the sender is the zero address.
    error Erc20__TransferSenderZeroAddress();

    /// @notice Emitted when the recipient is the zero address.
    error Erc20__TransferRecipientZeroAddress();

    /// EVENTS ///

    /// @notice Emitted when an approval happens.
    /// @param owner The address of the owner of the tokens.
    /// @param spender The address of the spender.
    /// @param amount The maximum amount that can be spent.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when a transfer happens.
    /// @param from The account sending the tokens.
    /// @param to The account receiving the tokens.
    /// @param amount The amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend
    /// on behalf of `owner` through {transferFrom}. This is zero by default.
    ///
    /// @dev This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    function symbol() external view returns (string memory);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may
    /// use both the old and the new allowance by unfortunate transaction ordering. One possible solution
    /// to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired
    /// value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for problems described
    /// in {Erc20Interface-approve}.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    /// - `spender` must have allowance for the caller of at least `subtractedAmount`.
    function decreaseAllowance(address spender, uint256 subtractedAmount) external returns (bool);

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for the problems described above.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    function increaseAllowance(address spender, uint256 addedAmount) external returns (bool);

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `recipient` cannot be the zero address.
    /// - The caller must have a balance of at least `amount`.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount`
    /// `is then deducted from the caller's allowance.
    ///
    /// @dev Emits a {Transfer} event and an {Approval} event indicating the updated allowance. This is
    /// not required by the Erc. See the note at the beginning of {Erc20}.
    ///
    /// Requirements:
    ///
    /// - `sender` and `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    /// - The caller must have approed `sender` to spent at least `amount` tokens.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

/// @title ReentrancyGuard
/// @author Paul Razvan Berg
/// @notice Contract module that helps prevent reentrant calls to a function.
///
/// Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier available, which can be applied
/// to functions to make sure there are no nested (reentrant) calls to them.
///
/// Note that because there is a single `nonReentrant` guard, functions marked as `nonReentrant` may not
/// call one another. This can be worked around by making those functions `private`, and then adding
/// `external` `nonReentrant` entry points to them.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/ReentrancyGuard.sol
abstract contract ReentrancyGuard {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when there is a reentrancy call.
    error ReentrantCall();

    /// PRIVATE STORAGE ///

    bool private notEntered;

    /// CONSTRUCTOR ///

    /// Storing an initial non-zero value makes deployment a bit more expensive but in exchange the
    /// refund on every call to nonReentrant will be lower in amount. Since refunds are capped to a
    /// percetange of the total transaction's gas, it is best to keep them low in cases like this one,
    /// to increase the likelihood of the full refund coming into effect.
    constructor() {
        notEntered = true;
    }

    /// MODIFIERS ///

    /// @notice Prevents a contract from calling itself, directly or indirectly.
    /// @dev Calling a `nonReentrant` function from another `nonReentrant` function
    /// is not supported. It is possible to prevent this from happening by making
    /// the `nonReentrant` function external, and make it call a `private`
    /// function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, notEntered will be true.
        if (!notEntered) {
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail.
        notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (https://eips.ethereum.org/EIPS/eip-2200).
        notEntered = true;
    }
}