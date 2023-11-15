//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Hangar18.sol
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

/*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  .
    .               .            .               .      🛰️     .           .                 *              .
           █████████           ---======*.                                                 .           ⠀
          ███░░░░░███                                               📡                🌔                       . 
         ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
        ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀           .           .
        ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
        ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             .⠀
         ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████     .----===*  ⠀
          ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                            .⠀
                       ███ ░███  ███ ░███                .                 .                 .  ⠀
     🛰️  .             ░░██████  ░░██████                                             .                 .           
                       ░░░░░░    ░░░░░░      -------=========*                      .                     ⠀
           .                            .       .          .            .                          .             .⠀
    
        LENDING POOL FACTORY V1 - `Hangar18`                                                           
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  */
pragma solidity >=0.8.17;

// Dependencies
import {IHangar18} from "./interfaces/IHangar18.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

// Libraries
import {CygnusPoolAddress} from "./libraries/CygnusPoolAddress.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

// Interfaces
import {ICygnusNebulaRegistry} from "./interfaces/ICygnusNebulaRegistry.sol";
import {IDenebOrbiter} from "./interfaces/IDenebOrbiter.sol";
import {IAlbireoOrbiter} from "./interfaces/IAlbireoOrbiter.sol";
import {ICygnusDAOReserves} from "./interfaces/ICygnusDAOReserves.sol";

// For TVLs
import {ICygnusBorrow} from "./interfaces/ICygnusBorrow.sol";
import {ICygnusCollateral} from "./interfaces/ICygnusCollateral.sol";

/**
 *  @title  Hangar18
 *  @author CygnusDAO
 *  @notice Factory-like contract for CygnusDAO which deploys all borrow/collateral contracts in this chain. There
 *          is only 1 factory contract per chain along with multiple pairs of `orbiters`.
 *
 *          Orbiters are the collateral and borrow deployers contracts which are not not part of the
 *          core contracts, but instead are in charge of deploying the arms of core contracts with each other's
 *          addresses (borrow orbiter deploys the borrow arm with the collateral address, and vice versa).
 *
 *          Orbiters = Strategies for the underlying assets
 *
 *          Each orbiter has the bytecode of the collateral/borrow contracts being deployed, and they may differ
 *          slighlty due to the strategy deployed (for example each masterchef is different, requiring different
 *          harvest strategy, staking mechanism, etc.).
 *
 *          Ideally there should only be 1 orbiter per DEX (1 borrow && 1 collateral orbiter) or 1 per strategy.
 *
 *          This factory contract contains the records of all shuttles deployed by Cygnus. Every collateral/borrow
 *          contract reports back here to:
 *              - Check admin address (to increase debt ratios, update interest rate model, set void, etc.)
 *              - Check reserves manager address when minting new DAO reserves (in CygnusBorrow.sol)
 */
contract Hangar18 is IHangar18, ReentrancyGuard {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library FixedPointMathLib Arithmetic library with operations for fixed-point numbers.
     */
    using FixedPointMathLib for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc IHangar18
     */
    Orbiter[] public override allOrbiters;

    /**
     *  @inheritdoc IHangar18
     */
    Shuttle[] public override allShuttles;

    /**
     *  @inheritdoc IHangar18
     */
    mapping(bytes32 => bool) public override orbitersExist;

    /**
     *  @inheritdoc IHangar18
     */
    mapping(address => mapping(uint256 => Shuttle)) public override getShuttles; // LP Address -> Orbiter ID = Lending Pool

    /**
     *  @inheritdoc IHangar18
     */
    string public override name = "Cygnus: Hangar18";

    /**
     *  @inheritdoc IHangar18
     */
    string public constant override version = "1.0.0";

    /**
     *  @inheritdoc IHangar18
     */
    address public immutable override usd;

    /**
     *  @inheritdoc IHangar18
     */
    address public immutable override nativeToken;

    /**
     *  @inheritdoc IHangar18
     */
    address public immutable nebulaRegistry;

    /**
     *  @inheritdoc IHangar18
     */
    address public override admin;

    /**
     *  @inheritdoc IHangar18
     */
    address public override pendingAdmin;

    /**
     *  @inheritdoc IHangar18
     */
    address public override daoReserves;

    /**
     *  @inheritdoc IHangar18
     */
    address public override cygnusX1Vault;

    /**
     *  @inheritdoc IHangar18
     */
    address public override cygnusPillars;

    /**
     *  @inheritdoc IHangar18
     */
    address public override cygnusAltair;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Sets the important addresses which pools report back here to check for
     *  @param _usd Address of the borrowable`s underlying (stablecoins USDC, DAI, BUSD, etc.).
     *  @param _nativeToken The address of this chain's native token
     *  @param _registry The Cygnus oracle registry which keeps track of all initialized LP oracles
     */
    constructor(address _usd, address _nativeToken, address _registry) {
        // Assign cygnus admin, has access to special functions
        admin = msg.sender;

        // Address of the native token for this chain (ie WETH)
        nativeToken = _nativeToken;

        // Address of DAI on this factory's chain
        usd = _usd;

        // Oracle registry
        nebulaRegistry = _registry;

        /// @custom:event NewCygnusAdmin
        emit NewCygnusAdmin(address(0), msg.sender);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:modifier cygnusAdmin Modifier for Cygnus Admin only
     */
    modifier cygnusAdmin() {
        isCygnusAdmin();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Only Cygnus admins can deploy pools in Cygnus V1
     */
    function isCygnusAdmin() private view {
        /// @custom:error CygnusAdminOnly
        if (msg.sender != admin) {
            revert Hangar18__CygnusAdminOnly({sender: msg.sender, admin: admin});
        }
    }

    /*  ─────────────────────────────────────────────── Public ──────────────────────────────────────────────── */

    /**
     *  @inheritdoc IHangar18
     */
    function chainId() public view override returns (uint256) {
        return block.chainid;
    }

    /**
     *  @inheritdoc IHangar18
     */
    function borrowableTvlUsd(uint256 shuttleId) public view override returns (uint256 totalUsd) {
        // Get shuttleId's borrowable
        address borrowable = allShuttles[shuttleId].borrowable;

        // Price of the stablecoin in 18 decimals (DAI, USDC, etc.)
        uint256 price = ICygnusBorrow(borrowable).getUsdPrice();

        // Total Balance + Total Borrows of borrowable
        uint256 totalAssets = ICygnusBorrow(borrowable).totalAssets();

        // TVL = Price of stablecoin * total stablecoin assets
        totalUsd = totalAssets.mulWad(price);
    }

    /**
     *  @inheritdoc IHangar18
     */
    function collateralTvlUsd(uint256 shuttleId) public view override returns (uint256 totalUsd) {
        // Get shuttleId's collateral
        address collateral = allShuttles[shuttleId].collateral;

        // Price of the LP in borrowable's decimals
        uint256 price = ICygnusCollateral(collateral).getLPTokenPrice();

        // Total LP assets
        uint256 totalAssets = ICygnusCollateral(collateral).totalAssets();

        // TVL = Price of LP * total LP assets
        totalUsd = totalAssets.mulWad(price); // Denom in USDC
    }

    /**
     *  @inheritdoc IHangar18
     */
    function shuttleTvlUsd(uint256 shuttleId) public view override returns (uint256 totalUsd) {
        // Return TVL of a single shuttle
        return borrowableTvlUsd(shuttleId) + collateralTvlUsd(shuttleId);
    }

    /**
     *  @inheritdoc IHangar18
     */
    function allBorrowablesTvlUsd() public view override returns (uint256 totalUsd) {
        // Loop through all shuttles and accumulate the TVL of each borrowable
        for (uint256 i = 0; i < allShuttles.length; i++) totalUsd += borrowableTvlUsd(i);
    }

    /**
     *  @inheritdoc IHangar18
     */
    function allCollateralsTvlUsd() public view override returns (uint256 totalUsd) {
        // Loop through all shuttles and accumulate the TVL of each collateral
        for (uint256 i = 0; i < allShuttles.length; i++) totalUsd += collateralTvlUsd(i);
    }

    /**
     *  @inheritdoc IHangar18
     */
    function cygnusTvlUsd() public view override returns (uint256) {
        // Return the cygnus protocol TVL on this chain
        return allBorrowablesTvlUsd() + allCollateralsTvlUsd();
    }

    /**
     *  @inheritdoc IHangar18
     */
    function daoCygUsdReservesUsd() public view override returns (uint256 reserves) {
        // Array of pools deployed
        Shuttle[] memory shuttles = allShuttles;

        // Total pools deployed
        uint256 poolsDeployed = shuttles.length;

        // Loop through each pool deployed, get borrowable and add to total TVL
        for (uint256 i = 0; i < poolsDeployed; i++) {
            // This pool`s borrowable
            address borrowable = shuttles[i].borrowable;

            // Get the current USD holding of the DAO for this shuttle
            (, uint256 positionUsd) = ICygnusBorrow(borrowable).getLenderPosition(daoReserves);

            // Add to reserves
            reserves += positionUsd;
        }
    }

    /**
     *  @inheritdoc IHangar18
     */
    function daoCygLPReservesUsd() public view override returns (uint256 reserves) {
        // Array of pools deployed
        Shuttle[] memory shuttles = allShuttles;

        // Total pools deployed
        uint256 poolsDeployed = allShuttles.length;

        // Loop through each pool deployed, get collateral and query the DAO's positionUsd:
        // positionUsd = (CygLP * Exchange Rate) * LP Price
        for (uint256 i = 0; i < poolsDeployed; i++) {
            // This pool`s collateral
            address collateral = shuttles[i].collateral;

            // Position in USD
            (, uint256 positionUsd, ) = ICygnusCollateral(collateral).getBorrowerPosition(daoReserves);

            // Add to reserves
            reserves += positionUsd;
        }
    }

    /**
     *  @inheritdoc IHangar18
     */
    function cygnusTotalReservesUsd() public view override returns (uint256) {
        // Total reserves USD
        return daoCygUsdReservesUsd() + daoCygLPReservesUsd();
    }

    /**
     *  @inheritdoc IHangar18
     */
    function cygnusTotalBorrows() public view override returns (uint256 totalBorrows) {
        // Array of pools deployed
        Shuttle[] memory shuttles = allShuttles;

        // Total pools deployed
        uint256 poolsDeployed = shuttles.length;

        // Loop through each pool deployed, get borrowable and add to total TVL
        for (uint256 i = 0; i < poolsDeployed; i++) {
            // This pool`s borrowable
            address borrowable = shuttles[i].borrowable;

            // Current total borrows
            totalBorrows += ICygnusBorrow(borrowable).totalBorrows();
        }
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc IHangar18
     */
    function orbitersDeployed() external view override returns (uint256) {
        // Return how many borrow/collateral orbiters this contract has
        return allOrbiters.length;
    }

    /**
     *  @inheritdoc IHangar18
     */
    function shuttlesDeployed() external view override returns (uint256) {
        // Return how many shuttles this contract has launched
        return allShuttles.length;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Creates a record of each shuttle deployed by this contract
     *  @dev Prepares shuttle for deployment and stores the orbiter used for this Shuttle
     *  @param lpTokenPair Address of the LP Token for this shuttle
     *  @param orbiterId The orbiter ID used to deploy this shuttle
     *  @return shuttle Struct of the lending pool being deployed
     */
    function boardShuttlePrivate(address lpTokenPair, uint256 orbiterId) private returns (Shuttle storage) {
        // Get the ID for this LP token's shuttle
        bool deployed = getShuttles[lpTokenPair][orbiterId].launched;

        /// @custom:error ShuttleAlreadyDeployed
        if (deployed) revert Hangar18__ShuttleAlreadyDeployed();

        // Create shuttle
        return
            getShuttles[lpTokenPair][orbiterId] = Shuttle(
                false, // False until `deployShuttle` call succeeds
                uint88(allShuttles.length), // Lending pool ID
                address(0), // Borrowable address
                address(0), // Collateral address
                uint96(orbiterId) // The orbiter ID used to launch this shuttle
            );
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  Phase1: Orbiter check
     *            - Orbiters (deployers) are active and usable
     *  Phase2: Board shuttle check
     *            - No shuttle with the same LP Token AND Orbiter has been deployed before
     *  Phase4: Price Oracle check:
     *            - Assert price oracle exists for this LP Token pair
     *  Phase3: Deploy Collateral and Borrow contracts
     *            - Calculate address of the collateral and deploy borrow contract with calculated collateral address
     *            - Deploy the collateral contract with the deployed borrow address
     *            - Check that collateral contract address is equal to the calculated collateral address, else revert
     *  Phase5: Initialize shuttle
     *            - Initialize and store record of this shuttle in this contract
     *
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function deployShuttle(
        address lpTokenPair,
        uint256 orbiterId
    ) external override cygnusAdmin returns (address borrowable, address collateral) {
        //  ─────────────────────────────── Phase 1 ───────────────────────────────
        // Load orbiter to storage for gas savings (throws if doesn't exist)
        Orbiter storage orbiter = allOrbiters[orbiterId];

        // @custom:error OrbiterInactive
        if (!orbiter.status) revert Hangar18__OrbiterInactive();

        //  ─────────────────────────────── Phase 2 ───────────────────────────────
        // Prepare shuttle for deployment, reverts if lpTokenPair && orbiterId already exists
        // Load shuttle to storage to store if the call succeeds
        Shuttle storage shuttle = boardShuttlePrivate(lpTokenPair, orbiterId);

        //  ─────────────────────────────── Phase 3 ───────────────────────────────
        // Check that oracle has been initialized in the registry and get the nebula address
        address nebula = ICygnusNebulaRegistry(nebulaRegistry).getLPTokenNebulaAddress(lpTokenPair);

        /// @custom:error LiquidityTokenNotSupported
        if (nebula == address(0)) revert Hangar18__LiquidityTokenNotSupported();

        //  ─────────────────────────────── Phase 4 ───────────────────────────────
        // Get the pre-determined collateral address for this LP Token (check CygnusPoolAddres library)
        address create2Collateral = CygnusPoolAddress.getCollateralContract(
            lpTokenPair,
            address(this),
            address(orbiter.denebOrbiter),
            orbiter.collateralInitCodeHash
        );

        // Deploy borrow contract with calculated collateral address
        borrowable = orbiter.albireoOrbiter.deployAlbireo(usd, create2Collateral, nebula, shuttle.shuttleId);

        // Deploy collateral contract with deployed borrowable address
        collateral = orbiter.denebOrbiter.deployDeneb(lpTokenPair, borrowable, nebula, shuttle.shuttleId);

        /// @custom:error CollateralAddressMismatch
        if (collateral != create2Collateral) revert Hangar18__CollateralAddressMismatch();

        //  ─────────────────────────────── Phase 5 ───────────────────────────────
        // Save addresses to storage and mark as launched. This LP Token with orbiter ID cannot be redeployed
        shuttle.launched = true;

        // Add cygnus borrow contract to record
        shuttle.borrowable = borrowable;

        // Add collateral contract to record
        shuttle.collateral = collateral;

        // Push the lending pool struct to the object array
        allShuttles.push(shuttle);

        // Add shuttle to reserves, dao reserves is never zero
        ICygnusDAOReserves(daoReserves).addShuttle(shuttle.shuttleId, borrowable, collateral);

        /// @custom:event NewShuttleLaunched
        emit NewShuttle(lpTokenPair, orbiterId, shuttle.shuttleId, shuttle.borrowable, shuttle.collateral);
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function initializeOrbiter(string calldata _name, IAlbireoOrbiter albireo, IDenebOrbiter deneb) external override cygnusAdmin {
        // Borrowable init code hash
        bytes32 borrowableInitCodeHash = albireo.borrowableInitCodeHash();

        // Collateral init code hash
        bytes32 collateralInitCodeHash = deneb.collateralInitCodeHash();

        // Unique hash of both orbiters by hashing their respective init code hash
        bytes32 uniqueHash = keccak256(abi.encode(borrowableInitCodeHash, collateralInitCodeHash));

        /// @custom:error OrbitersAlreadySet
        if (orbitersExist[uniqueHash]) revert Hangar18__OrbitersAlreadySet();

        // Has not been initialized yet, create struct and push to orbiter array
        allOrbiters.push(
            Orbiter({
                orbiterId: uint88(allOrbiters.length), // Orbiter ID
                orbiterName: _name, // Friendly name for these orbiters (ie. `Compound-UniswapV3`)
                albireoOrbiter: albireo, // Borrowable deployer
                denebOrbiter: deneb, // Collateral deployer
                borrowableInitCodeHash: borrowableInitCodeHash, // Borrowable code hash
                collateralInitCodeHash: collateralInitCodeHash, // Collateral code hash
                uniqueHash: uniqueHash, // Unique bytes32 orbiter id
                status: true // Mark as true
            })
        );

        // Set this pair of orbiters as unique, cannot be initialized again
        orbitersExist[uniqueHash] = true;

        /// @custom:event InitializeOrbiters
        emit InitializeOrbiters(true, allOrbiters.length, albireo, deneb, uniqueHash, _name);
    }

    /**
     *  @notice Reverts future deployments with disabled orbiter
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function switchOrbiterStatus(uint256 orbiterId) external override cygnusAdmin {
        // Get the orbiter by the ID (throws if not set)
        IHangar18.Orbiter storage orbiter = allOrbiters[orbiterId];

        // Switch orbiter status. If currently active then future deployments with this orbiter will revert
        orbiter.status = !orbiter.status;

        /// @custom:event SwitchOrbiterStatus
        emit SwitchOrbiterStatus(orbiter.status, orbiter.orbiterId, orbiter.albireoOrbiter, orbiter.denebOrbiter, orbiter.orbiterName);
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function setPendingAdmin(address newPendingAdmin) external override cygnusAdmin {
        /// @custom:error AdminAlreadySet
        if (newPendingAdmin == admin) revert Hangar18__AdminAlreadySet();

        // Address of the pending admin until this point
        address oldPendingAdmin = pendingAdmin;

        /// @custom:event NewPendingCygnusAdmin
        emit NewPendingCygnusAdmin(oldPendingAdmin, pendingAdmin = newPendingAdmin);
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-pending-admin
     */
    function acceptCygnusAdmin() external override {
        /// @custom:error PendingAdminCantBeZero
        if (msg.sender != pendingAdmin) revert Hangar18__SenderNotPendingAdmin();

        // Address of the Admin until this point
        address oldAdmin = admin;

        // Assign the pending admin as the new cygnus admin
        admin = pendingAdmin;

        // Gas refund
        delete pendingAdmin;

        // @custom:event NewCygnusAdming
        emit NewCygnusAdmin(oldAdmin, admin);
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function setDaoReserves(address reserves) external override cygnusAdmin {
        /// @custom:error DaoReservesCantBeZero
        if (reserves == address(0)) revert Hangar18__DaoReservesCantBeZero();

        // Address of the DAO reserves until now
        address oldDaoReserves = daoReserves;

        /// @custom:event NewDaoReserves
        emit NewDaoReserves(oldDaoReserves, daoReserves = reserves);
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function setCygnusX1Vault(address newX1Vault) external override cygnusAdmin {
        /// @custom:error X1VaultCantBeZero
        if (newX1Vault == address(0)) revert Hangar18__X1VaultCantBeZero();

        // Old vault
        address oldVault = cygnusX1Vault;

        /// @custom:event NewX1Vault
        emit NewX1Vault(oldVault, cygnusX1Vault = newX1Vault);
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function setCygnusPillars(address newPillars) external override cygnusAdmin {
        /// @custom:error PillarsCantBeZero
        if (newPillars == address(0)) revert Hangar18__PillarsCantBeZero();

        // Old pillars
        address oldPillars = cygnusPillars;

        /// @custom:event NewPillarsOfCreation
        emit NewPillarsOfCreation(oldPillars, cygnusPillars = newPillars);
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function setCygnusAltair(address newAltair) external override cygnusAdmin {
        /// @custom:error PillarsCantBeZero
        if (newAltair == address(0)) revert Hangar18__AltairCantBeZero();

        // Old router
        address oldAltair = cygnusAltair;

        /// @custom:event NewAltairRouter
        emit NewAltairRouter(oldAltair, cygnusAltair = newAltair);
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
     *  @return The init code hash of the borrow contract for this deployer
     */
    function borrowableInitCodeHash() external view returns (bytes32);

    /**
     *  @notice Function to deploy the borrow contract of a lending pool
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
     *  @custom:error InsufficientLiquidity
     */
    error CygnusBorrow__InsufficientLiquidity();

    /**
     *  @dev Reverts if usd received is less than repaid after liquidating
     *  @custom:error InsufficientUsdReceived
     */
    error CygnusBorrow__InsufficientUsdReceived();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when a borrower borrows or repays a loan.
     *  @param sender Indexed address of msg.sender
     *  @param borrower Indexed address of the borrower
     *  @param receiver Indexed address of receiver
     *  @param borrowAmount The amount of stablecoins borrowed (if any)
     *  @param repayAmount The amount of stablecoins repaid (if any)
     *  @custom:event Borrow
     */
    event Borrow(address indexed sender, address indexed borrower, address indexed receiver, uint256 borrowAmount, uint256 repayAmount);

    /**
     *  @dev Logs when a liquidator repays and seizes collateral
     *  @param sender Indexed address of msg.sender (should be `Altair` address)
     *  @param borrower Indexed address of the borrower
     *  @param receiver Indexed address of receiver
     *  @param repayAmount The amount of USD repaid
     *  @param cygLPAmount The amount of CygLP seized
     *  @param usdAmount The total amount of underlying deposited
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
     *  @notice This low level function should be called from a periphery contract only
     *  @notice Main function used to borrow stablecoins or repay loans.
     *  @param borrower The address of the borrower
     *  @param receiver The address of the receiver of the borrow amount.
     *  @param borrowAmount The amount of the underlying asset to borrow.
     *  @param data Calldata passed to a router contract
     *  @custom:security non-reentrant
     */
    function borrow(address borrower, address receiver, uint256 borrowAmount, bytes calldata data) external returns (uint256);

    /**
     *  @notice This low level function should be called from a periphery contract only
     *  @notice Main function used to liquidate or flash liquidation positions.
     *  @param borrower The address of the borrower being liquidated
     *  @param receiver The address of the receiver of the collateral
     *  @param repayAmount USD amount covering the loan
     *  @param data Calldata passed to a router contract
     *  @return usdAmount The amount of USD deposited after taking into account liq. incentive
     *  @custom:security non-reentrant
     */
    function liquidate(address borrower, address receiver, uint256 repayAmount, bytes calldata data) external returns (uint256 usdAmount);
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
     *  @custom:error ParameterNotInRange
     */
    error CygnusBorrowControl__ParameterNotInRange();

    /**
     *  @dev Reverts when setting the collateral if the msg.sender is not the hangar18 contract
     *  @custom:error MsgSenderNotHangar
     */
    error CygnusBorrowControl__MsgSenderNotHangar();

    /**
     *  @dev Reverts wehn attempting to set a collateral that has already been set
     *  @custom:error CollateralAlreadySet
     */
    error CygnusBorrowControl__CollateralAlreadySet();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when a new interest rate curve is set for this shuttle
     *  @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     *  @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     *  @param kinkMultiplier_ The increase to multiplier per year once kink utilization is reached
     *  @param kinkUtilizationRate_ The rate at which the jump interest rate takes effect
     *  custom:event NewInterestRateParameters
     */
    event NewInterestRateParameters(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 kinkMultiplier_,
        uint256 kinkUtilizationRate_
    );

    /**
     *  @dev Logs when a new rewarder contract is set to reward borrowers and lenders.
     *  @param oldRewarder The address of the rewarder up until this point used for CYG distribution
     *  @param newRewarder The address of the new rewarder
     *  @custom:event NewCygnusBorrowRewarder
     */
    event NewPillarsOfCreation(address oldRewarder, address newRewarder);

    /**
     *  @dev Logs when a new reserve factor is set.
     *  @param oldReserveFactor The reserve factor used in this shuttle until this point
     *  @param newReserveFactor The new reserve factor set
     *  @custom:event NewReserveFactor
     */
    event NewReserveFactor(uint256 oldReserveFactor, uint256 newReserveFactor);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @custom:struct InterestRateModel The interest rate params for this pool
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
     *  @return The address of the Cygnus Collateral contract for this borrowable
     */
    function collateral() external view returns (address);

    /**
     *  @return Address that rewards borrowers and lenders in CYG
     */
    function pillarsOfCreation() external view returns (address);

    /**
     *  @notice The current interest rate params set for this pool
     *  @return baseRatePerSecond The base interest rate which is the y-intercept when utilization rate is 0
     *  @return multiplierPerSecond The multiplier of utilization rate that gives the slope of the interest rate
     *  @return jumpMultiplierPerSecond The multiplierPerSecond after hitting a specified utilization point
     *  @return kink The utilization point at which the jump multiplier is applied
     */
    function interestRateModel()
        external
        view
        returns (uint64 baseRatePerSecond, uint64 multiplierPerSecond, uint64 jumpMultiplierPerSecond, uint64 kink);

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
     *  @notice Updates the interest rate model with annualized rates, scaled by 1e18 (ie 1% = 0.01e18)
     *  @param baseRatePerYear The new annualized base rate
     *  @param multiplierPerYear The new annualized rate of increase in interest rate wrt utilization
     *  @param kinkMultiplier_ The increase to the slope once kink utilization is reached
     *  @param kinkUtilizationRate_ The new max utilization rate
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
     *  @notice Updates the reserve factor
     *  @param newReserveFactor The new reserve factor for this shuttle
     *  @custom:security only-admin
     */
    function setReserveFactor(uint256 newReserveFactor) external;

    /**
     *  @notice Admin 👽
     *  @notice Updates the pillars of creation contract. This can be updated to the zero address in case we need
     *          to remove rewards from pools saving us gas instead of calling the contract.
     *  @param newPillars The address of the new CYG rewarder
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
 *  @title ICygnusBorrowModel Interface of the contract that implements the interest rate model and interest accruals
 */
interface ICygnusBorrowModel is ICygnusBorrowControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when interest is accrued to borrows and reserves
     *  @param cash Total balance of the underlying in the strategy
     *  @param borrows Latest total borrows stored
     *  @param interest Interest accumulated since last accrual
     *  @param reserves The amount of CygUSD minted to the DAO
     *  @custom:event AccrueInterest
     */
    event AccrueInterest(uint256 cash, uint256 borrows, uint256 interest, uint256 reserves);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @custom:struct BorrowSnapshot Container for individual user's borrow balance information
     *  @custom:member principal The total borrowed amount without interest accrued
     *  @custom:member interestIndex Borrow index as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint128 principal;
        uint128 interestIndex;
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return Total borrows of the lending pool (uses borrow indices to simulate interest rate accruals)
     */
    function totalBorrows() external view returns (uint256);

    /**
     *  @return Borrow index stored of this lending pool (uses borrow indices)
     */
    function borrowIndex() external view returns (uint256);

    /**
     *  @return The unix timestamp stored of the last interest rate accrual
     */
    function lastAccrualTimestamp() external view returns (uint256);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return The price of the denomination token in 18 decimals, used for reporting purposes only
     */
    function getUsdPrice() external view returns (uint256);

    /**
     *  @return The total amount of borrowed funds divided by the total vault assets
     */
    function utilizationRate() external view returns (uint256);

    /**
     *  @return The current per-second borrow rate
     */
    function borrowRate() external view returns (uint256);

    /**
     *  @return The current per-second supply rate
     */
    function supplyRate() external view returns (uint256);

    /**
     *  @notice Function used to get the borrow balance of users and their principal.
     *  @param borrower The address whose balance should be calculated
     *  @return principal The stablecoin amount borrowed without interests
     *  @return borrowBalance The stablecoin amount borrowed with interests  (ie. what borrowers must pay back)
     */
    function getBorrowBalance(address borrower) external view returns (uint256 principal, uint256 borrowBalance);

    /**
     *  @notice Gets the lender`s full position
     *  @param lender The address of the lender
     *  @return usdBalance The amount of stablecoins that the lender owns
     *  @return positionInUsd The position of the lender in USD
     */
    function getLenderPosition(address lender) external view returns (uint256 usdBalance, uint256 positionInUsd);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Applies interest accruals to borrows and reserves
     */
    function accrueInterest() external;

    /**
     *  @notice Manually track the user's CygUSD shares to pass to the rewarder contract
     *  @param lender The address of the lender
     */
    function trackLender(address lender) external;

    /**
     *  @notice Manually track the user's borrows
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
     *  @custom:error InsufficientLiquidity
     */
    error CygnusCollateral__InsufficientLiquidity();

    /**
     *  @dev Reverts when the msg.sender of the liquidation is not this contract`s borrowable
     *  @custom:error MsgSenderNotBorrowable
     */
    error CygnusCollateral__MsgSenderNotBorrowable();

    /**
     *  @dev Reverts when the repayAmount in a liquidation is 0
     *  @custom:error CantLiquidateZero
     */
    error CygnusCollateral__CantLiquidateZero();

    /**
     *  @dev Reverts when trying to redeem 0 tokens
     *  @custom:error CantRedeemZero
     */
    error CygnusCollateral__CantRedeemZero();

    /**
     * @dev Reverts when liquidating an account that has no shortfall
     * @custom:error NotLiquidatable
     */
    error CygnusCollateral__NotLiquidatable();

    /**
     *  @dev Reverts when redeeming more shares than CygLP in this contract
     *  @custom:error InsufficientRedeemAmount
     */
    error CygnusCollateral__InsufficientCygLPReceived();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when collateral is seized from the borrower and sent to the liquidator
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
     *  @notice Seizes CygLP from borrower and adds it to the liquidator's account. This function can only be called 
     *          from the borrowable contract, else it reverts.
     *  @param liquidator The address repaying the borrow amount and seizing the collateral
     *  @param borrower The address of the borrower
     *  @param repayAmount The number of collateral tokens to seize
     *  @return liquidatorAmount The amount of CygLP that the liquidator received for liquidating the position
     *  @custom:security non-reentrant
     */
    function seizeCygLP(address liquidator, address borrower, uint256 repayAmount) external returns (uint256 liquidatorAmount);

    /**
     *  @notice Flash redeems the underlying LP Token - Low level function which should only be called by a router.
     *  @param redeemer The address redeeming the tokens (Altair contract)
     *  @param assets The amount of the underlying assets to redeem
     *  @param data Calldata passed from and back to router contract
     *  @custom:security non-reentrant
     */
    function flashRedeemAltair(address redeemer, uint256 assets, bytes calldata data) external returns (uint256 usdAmount);
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
     *  @custom:error ParameterNotInRange
     */
    error CygnusCollateralControl__ParameterNotInRange();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════  
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when the max debt ratio is updated for this shuttle
     *  @param oldDebtRatio The old debt ratio at which the collateral was liquidatable in this shuttle
     *  @param newDebtRatio The new debt ratio for this shuttle
     *  @custom:event NewDebtRatio
     */
    event NewDebtRatio(uint256 oldDebtRatio, uint256 newDebtRatio);

    /**
     *  @dev Logs when a new liquidation incentive is set for liquidators
     *  @param oldLiquidationIncentive The old incentive for liquidators taken from the collateral
     *  @param newLiquidationIncentive The new liquidation incentive for this shuttle
     *  @custom:event NewLiquidationIncentive
     */
    event NewLiquidationIncentive(uint256 oldLiquidationIncentive, uint256 newLiquidationIncentive);

    /**
     *  @dev Logs when a new liquidation fee is set, which the protocol keeps from each liquidation
     *  @param oldLiquidationFee The previous fee the protocol kept as reserves from each liquidation
     *  @param newLiquidationFee The new liquidation fee for this shuttle
     *  @custom:event NewLiquidationFee
     */
    event NewLiquidationFee(uint256 oldLiquidationFee, uint256 newLiquidationFee);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return The address of the Cygnus Borrow contract for this collateral
     */
    function borrowable() external view returns (address);

    /**
     *  @return The current max debt ratio for this shuttle, after which positions become liquidatable
     */
    function debtRatio() external view returns (uint256);

    /**
     *  @return The current liquidation incentive for this shuttle
     */
    function liquidationIncentive() external view returns (uint256);

    /**
     *  @return The current liquidation fee the protocol keeps from each liquidation
     */
    function liquidationFee() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Admin 👽
     *  @notice Updates the shuttle's debt ratio
     *  @param  newDebtRatio The new max debt ratio at which positions become liquidatable.
     *  @custom:security only-admin
     */
    function setDebtRatio(uint256 newDebtRatio) external;

    /**
     *  @notice Admin 👽
     *  @notice Updates the liquidation bonus for liquidators
     *  @param  newLiquidationIncentive The new incentive that the liquidators receive for liquidating positions.
     *  @custom:security only-admin
     */
    function setLiquidationIncentive(uint256 newLiquidationIncentive) external;

    /**
     *  @notice Admin 👽
     *  @notice Updates the liquidation fee that the protocol keeps for every liquidation
     *  @param newLiquidationFee The new fee that the protocol keeps from every liquidation.
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
 *  @title ICygnusCollateralModel The contract that implements the collateralization model
 */
interface ICygnusCollateralModel is ICygnusCollateralControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when the borrower is the zero address or this collateral
     *  @custom:error InvalidBorrower
     */
    error CygnusCollateralModel__InvalidBorrower();

    /**
     *  @dev Reverts when the price returned from the oracle is 0
     *  @custom:error PriceCantBeZero
     */
    error CygnusCollateralModel__PriceCantBeZero();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Checks if the given user is able to redeem the specified amount of LP tokens.
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
     *  @return The price of 1 LP Token denominated in the Borrowable's underlying stablecoin
     */
    function getLPTokenPrice() external view returns (uint256);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Gets an account's liquidity or shortfall
     *  @param borrower The address of the borrower
     *  @return liquidity The account's liquidity denominated in the borrowable's underlying stablecoin.
     *  @return shortfall The account's shortfall denominated in the borrowable's underlying stablecoin. If positive 
     *                    then the account can be liquidated.
     */
    function getAccountLiquidity(address borrower) external view returns (uint256 liquidity, uint256 shortfall);

    /**
     *  @notice Check if a borrower can borrow a specified amount of stablecoins from the borrowable contract.
     *  @param borrower The address of the borrower
     *  @param borrowAmount The amount of stablecoins that borrower wants to borrow.
     *  @return A boolean indicating whether the borrower can borrow the specified amount
     */
    function canBorrow(address borrower, uint256 borrowAmount) external view returns (bool);

    /**
     *  @notice Quick view function to get a borrower's latest position
     *  @param borrower The address of the borrower
     *  @return lpBalance The borrower`s position in LP Tokens
     *  @return positionUsd The borrower's position in USD (ie. CygLP Balance * Exchange Rate * LP Token Price)
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

interface ICygnusDAOReserves {
    /// @notice Adds a shuttle to the record
    /// @param shuttleId The ID for the shuttle we are adding
    /// @custom:security non-reentrant only-admin
    function addShuttle(uint256 shuttleId, address borrowable, address collateral) external;
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
     *  @custom:error CantMintZeroShares
     */
    error CygnusTerminal__CantMintZeroShares();

    /**
     *  @dev Reverts when attempting to redeem zero assets
     *  @custom:error CantBurnZeroAssets
     */
    error CygnusTerminal__CantRedeemZeroAssets();

    /**
     *  @dev Reverts when attempting to call Admin-only functions
     *  @custom:error MsgSenderNotAdmin
     */
    error CygnusTerminal__MsgSenderNotAdmin();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when totalBalance syncs with the underlying contract's balanceOf.
     *  @param totalBalance Total balance in terms of the underlying
     *  @custom:event Sync
     */
    event Sync(uint160 totalBalance);

    /**
     *  @dev Logs when CygLP or CygUSD pool tokens are minted
     *  @param sender The address of `CygnusAltair` or the sender of the function call
     *  @param recipient Address of the minter
     *  @param assets Amount of assets being deposited
     *  @param shares Amount of pool tokens being minted
     *  @custom:event Mint
     */
    event Deposit(address indexed sender, address indexed recipient, uint256 assets, uint256 shares);

    /**
     *  @dev Logs when CygLP or CygUSD are redeemed
     *  @param sender The address of the redeemer of the shares
     *  @param recipient The address of the recipient of assets
     *  @param owner The address of the owner of the pool tokens
     *  @param assets The amount of assets to redeem
     *  @param shares The amount of pool tokens burnt
     *  @custom:event Redeem
     */
    event Withdraw(address indexed sender, address indexed recipient, address indexed owner, uint256 assets, uint256 shares);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
           3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return Address of the Permit2 router on this chain. We use the AllowanceTransfer instead of SignatureTransfer 
     *          to allow deposits from other smart contracts.
     *        
     */
    function PERMIT2() external view returns (IAllowanceTransfer);

    /**
     *  @return The address of the Cygnus Factory contract used to deploy this shuttle
     */
    function hangar18() external view returns (IHangar18);

    /**
     *  @return The address of the underlying asset (stablecoin for Borrowable, LP Token for collateral)
     */
    function underlying() external view returns (address);

    /**
     *  @return The address of the oracle for this lending pool
     */
    function nebula() external view returns (ICygnusNebula);

    /**
     *  @return The unique ID of the lending pool, shared by Borrowable and Collateral
     */
    function shuttleId() external view returns (uint256);

    /**
     *  @return Total available cash deposited in the strategy (stablecoin for Borrowable, LP Token for collateral)
     */
    function totalBalance() external view returns (uint160);

    /**
     *  @return The total assets owned by the vault. Same as total balance, but includes total borrows for Borrowable.
     */
    function totalAssets() external view returns (uint256);

    /**
     *  @return The exchange rate between 1 vault share (CygUSD/CygLP) and the underlying asset
     */
    function exchangeRate() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Deposits the underlying asset into the vault (stablecoins for borrowable, LP tokens for collateral).
     *          Users must approve the Permit2 router in the underlying before depositing. Users can bypass
     *          the permit and signature arguments by also approving the vault contract in the Permit2 router
     *          and pass an empty permit and signature.
     *  @param assets Amount of the underlying asset to deposit.
     *  @param recipient Address that will receive the corresponding amount of shares.
     *  @param _permit Data signed over by the owner specifying the terms of approval
     *  @param _signature The owner's signature over the permit data
     *  @return shares Amount of Cygnus Vault shares minted and transferred to the `recipient`.
     *  @custom:security non-reentrant
     */
    function deposit(
        uint256 assets,
        address recipient,
        IAllowanceTransfer.PermitSingle calldata _permit,
        bytes calldata _signature
    ) external returns (uint256 shares);

    /**
     *  @notice Redeems vault shares and transfers out assets (stablecoins for borrowable, LP tokens for collateral).
     *  @param shares The number of shares to redeem for the underlying asset.
     *  @param recipient The address that will receive the underlying asset.
     *  @param owner The address that owns the shares.
     *  @return assets The amount of underlying assets received by the `recipient`.
     *  @custom:security non-reentrant
     */
    function redeem(uint256 shares, address recipient, address owner) external returns (uint256 assets);

    /**
     *  @notice Syncs `totalBalance` in terms of its underlying
     *  @custom:security non-reentrant
     */
    function sync() external;
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
     *  @return The init code hash of the collateral contract for this deployer
     */
    function collateralInitCodeHash() external view returns (bytes32);

    /**
     *  @notice Function to deploy the collateral contract of a lending pool
     *  @param underlying The address of the underlying LP Token
     *  @param borrowable The address of the Cygnus borrow contract for this collateral
     *  @param oracle The address of the oracle for this lending pool
     *  @param shuttleId The ID of the lending pool
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
    function nebulaRegistry() external view returns (address);

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

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusPoolAddress.sol
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
 *  @title CygnusPoolAddress
 *  @dev Provides functions for deriving Cygnus collateral and borrow addresses deployed by Factory
 */
library CygnusPoolAddress {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Used by CygnusAltair.sol and Cygnus Factory
     *  @dev create2_address: keccak256(0xff, senderAddress, salt, keccak256(init_code))
     *  @param lpTokenPair The address of the LP Token
     *  @param factory The address of the Cygnus Factory used to deploy the shuttle
     *  @param denebOrbiter The address of the collateral deployer
     *  @param initCodeHash The keccak256 hash of the initcode of the Cygnus Collateral contracts
     *  @return collateral The calculated address of the Cygnus collateral contract given the salt (`lpTokenPair` and
     *                     `factory` addresses), the msg.sender (Deneb Orbiter) and the init code hash of the
     *                     CygnusCollateral.
     */
    function getCollateralContract(
        address lpTokenPair,
        address factory,
        address denebOrbiter,
        bytes32 initCodeHash
    ) internal pure returns (address collateral) {
        collateral = address(
            uint160(
                uint256(keccak256(abi.encodePacked(bytes1(0xff), denebOrbiter, keccak256(abi.encode(lpTokenPair, factory)), initCodeHash)))
            )
        );
    }

    /**
     *  @dev Used by CygnusAltair.sol
     *  @dev create2_address: keccak256(0xff, senderAddress, salt, keccak256(init_code))[12:]
     *  @param collateral The address of the LP Token
     *  @param factory The address of the Cygnus Factory used to deploy the shuttle
     *  @param borrowDeployer The address of the CygnusAlbireo contract
     *  @return borrow The calculated address of the Cygnus Borrow contract deployed by factory given
     *          `lpTokenPair` and `factory` addresses along with borrowDeployer contract address
     */
    function getBorrowContract(
        address collateral,
        address factory,
        address borrowDeployer,
        bytes32 initCodeHash
    ) internal pure returns (address borrow) {
        borrow = address(
            uint160(
                uint256(keccak256(abi.encodePacked(bytes1(0xff), borrowDeployer, keccak256(abi.encode(collateral, factory)), initCodeHash)))
            )
        );
    }
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
    /*//////////////////////////////////////////////////////////////////////////
                                       ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when there is a reentrancy call.
    error ReentrantCall();

    /*//////////////////////////////////////////////////////////////////////////
                                  PRIVATE STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    bool private notEntered;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// Storing an initial non-zero value makes deployment a bit more expensive but in exchange the
    /// refund on every call to nonReentrant will be lower in amount. Since refunds are capped to a
    /// percentage of the total transaction's gas, it is best to keep them low in cases like this one,
    /// to increase the likelihood of the full refund coming into effect.
    constructor() {
        notEntered = true;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

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