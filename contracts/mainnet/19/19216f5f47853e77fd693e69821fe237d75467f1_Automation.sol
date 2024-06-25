// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Admin } from "contracts/base/Admin.sol";
import { NonDelegateMulticall } from "contracts/base/NonDelegateMulticall.sol";
import { Sickle } from "contracts/Sickle.sol";
import { SickleRegistry } from "contracts/SickleRegistry.sol";
import { ICompoundable } from "contracts/interfaces/ICompoundable.sol";
import { IHarvestable } from "contracts/interfaces/IHarvestable.sol";
import {
    IRebalanceable,
    RebalanceParams
} from "contracts/interfaces/IRebalanceable.sol";
import {
    HarvestParams,
    CompoundParams
} from "contracts/structs/FarmStrategyStructs.sol";

enum RewardAutomation {
    None,
    Harvest,
    Compound
}

// @title Automation contract for automating farming strategies
// @notice This contract allows users to automate their farming strategies
// by enabling auto-compound or auto-harvest.
// The contract also allows an approved automator to compound, harvest or
// auto-rebalance farming positions on behalf of users.
// Only one of Auto-Compound or Auto-Harvest can be enabled:
// all user positions will be either auto-compounded or auto-harvested.
// Auto-Rebalance settings are per NFT, and are not affected by this contract.
// @dev This contract is expected to be used by an external automation bot
// that will call the compoundFor, harvestFor, and rebalanceFor functions.
// The automation bot is expected to be the EOA of the approved automator.
// The approved automator is set by the protocol admin.
contract Automation is Admin, NonDelegateMulticall {
    error InvalidInputLength();
    error AutomationNotSet();
    error AutomationAlreadySet();
    error NotApprovedAutomator();
    error InvalidSlippage();

    event HarvestedFor(address indexed user, address indexed stakingContract);
    event CompoundedFor(
        address indexed user,
        address indexed claimContract,
        address indexed depositContract
    );
    event RebalancedFor(
        address indexed user,
        address indexed nftAddress,
        uint256 indexed tokenId
    );
    event ApprovedAutomatorSet(address approvedAutomator);

    event AutoHarvestEnabled(address indexed user, address tokenOut);
    event AutoCompoundEnabled(address indexed user);
    event AutoHarvestDisabled(address indexed user);
    event AutoCompoundDisabled(address indexed user);

    address payable public approvedAutomator;

    mapping(address => RewardAutomation) public rewardAutomation;
    mapping(address => address) public harvestTokensOut;

    constructor(
        SickleRegistry registry_,
        address payable approvedAutomator_,
        address admin_
    ) Admin(admin_) NonDelegateMulticall(registry_) {
        approvedAutomator = approvedAutomator_;
    }

    modifier onlyApprovedAutomator() {
        if (msg.sender != approvedAutomator) revert NotApprovedAutomator();
        _;
    }

    // Admin functions

    /// @notice Update approved automator address.
    /// @dev Controls which external address is allowed to
    /// compound farming positions for Sickles. This is expected to be the EOA
    /// of an automation bot.
    /// @custom:access Restricted to protocol admin.
    function setApprovedAutomator(address payable approvedAutomator_)
        external
        onlyAdmin
    {
        approvedAutomator = approvedAutomator_;
        emit ApprovedAutomatorSet(approvedAutomator_);
    }

    // Automator functions

    function compoundFor(
        ICompoundable[] memory strategies,
        Sickle[] memory sickles,
        CompoundParams[] memory params,
        address[][] memory sweepTokens
    ) external onlyApprovedAutomator {
        uint256 strategiesLength = strategies.length;
        if (
            strategiesLength != sickles.length
                || strategiesLength != params.length
                || strategiesLength != sweepTokens.length
        ) {
            revert InvalidInputLength();
        }

        address[] memory targets = new address[](strategiesLength);
        bytes[] memory data = new bytes[](strategiesLength);
        for (uint256 i; i < strategiesLength; i++) {
            address user = sickles[i].owner();
            if (rewardAutomation[user] != RewardAutomation.Compound) {
                revert AutomationNotSet();
            }
            CompoundParams memory param = params[i];
            targets[i] = address(strategies[i]);
            data[i] = abi.encodeCall(
                ICompoundable.compoundFor, (sickles[i], param, sweepTokens[i])
            );
            emit CompoundedFor(
                user, param.claimContractAddress, param.depositContractAddress
            );
        }
        this.multicall(targets, data);
    }

    function harvestFor(
        IHarvestable[] memory strategies,
        Sickle[] memory sickles,
        HarvestParams[] memory params,
        address[][] memory sweepTokens
    ) external onlyApprovedAutomator {
        uint256 strategiesLength = strategies.length;
        if (
            strategiesLength != sickles.length
                || strategiesLength != params.length
                || strategiesLength != sweepTokens.length
        ) {
            revert InvalidInputLength();
        }

        address[] memory targets = new address[](strategiesLength);
        bytes[] memory data = new bytes[](strategiesLength);
        for (uint256 i; i < strategiesLength; i++) {
            address user = sickles[i].owner();
            if (rewardAutomation[user] != RewardAutomation.Harvest) {
                revert AutomationNotSet();
            }
            HarvestParams memory param = params[i];
            targets[i] = address(strategies[i]);
            data[i] = abi.encodeCall(
                IHarvestable.harvestFor, (sickles[i], param, sweepTokens[i])
            );
            emit HarvestedFor(user, param.stakingContractAddress);
        }
        this.multicall(targets, data);
    }

    function rebalanceFor(
        IRebalanceable[] memory strategies,
        Sickle[] memory sickles,
        RebalanceParams[] memory params,
        address[][] memory sweepTokens
    ) external onlyApprovedAutomator {
        uint256 strategiesLength = strategies.length;
        if (
            strategiesLength != sickles.length
                || strategiesLength != params.length
                || strategiesLength != sweepTokens.length
        ) {
            revert InvalidInputLength();
        }

        address[] memory targets = new address[](strategiesLength);
        bytes[] memory data = new bytes[](strategiesLength);
        for (uint256 i; i < strategiesLength; i++) {
            RebalanceParams memory param = params[i];
            address user = sickles[i].owner();
            targets[i] = address(strategies[i]);
            data[i] = abi.encodeCall(
                IRebalanceable.rebalanceFor, (sickles[i], param, sweepTokens[i])
            );
            emit RebalancedFor(
                user, address(param.nftInfo.nftManager), param.nftInfo.tokenId
            );
        }
        this.multicall(targets, data);
    }

    // User functions

    function enableAutoCompound() external {
        RewardAutomation automation = rewardAutomation[msg.sender];
        if (automation == RewardAutomation.Compound) {
            revert AutomationAlreadySet();
        }
        if (automation == RewardAutomation.Harvest) {
            delete harvestTokensOut[msg.sender];
        }
        rewardAutomation[msg.sender] = RewardAutomation.Compound;
        emit AutoCompoundEnabled(msg.sender);
    }

    function enableAutoHarvest(address tokenOut) external {
        if (
            rewardAutomation[msg.sender] == RewardAutomation.Harvest
                && harvestTokensOut[msg.sender] == tokenOut
        ) {
            revert AutomationAlreadySet();
        }
        rewardAutomation[msg.sender] = RewardAutomation.Harvest;
        harvestTokensOut[msg.sender] = tokenOut;
        emit AutoHarvestEnabled(msg.sender, tokenOut);
    }

    function disableAutoCompound() external {
        if (rewardAutomation[msg.sender] != RewardAutomation.Compound) {
            revert AutomationNotSet();
        }
        delete rewardAutomation[msg.sender];
        emit AutoCompoundDisabled(msg.sender);
    }

    function disableAutoHarvest() external {
        if (rewardAutomation[msg.sender] != RewardAutomation.Harvest) {
            revert AutomationNotSet();
        }
        delete rewardAutomation[msg.sender];
        delete harvestTokensOut[msg.sender];

        emit AutoHarvestDisabled(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Admin contract
/// @author vfat.tools
/// @notice Provides an administration mechanism allowing restricted functions
abstract contract Admin {
    /// ERRORS ///

    /// @notice Thrown when the caller is not the admin
    error NotAdminError(); //0xb5c42b3b

    /// EVENTS ///

    /// @notice Emitted when a new admin is set
    /// @param oldAdmin Address of the old admin
    /// @param newAdmin Address of the new admin
    event AdminSet(address oldAdmin, address newAdmin);

    /// STORAGE ///

    /// @notice Address of the current admin
    address public admin;

    /// MODIFIERS ///

    /// @dev Restricts a function to the admin
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdminError();
        _;
    }

    /// WRITE FUNCTIONS ///

    /// @param admin_ Address of the admin
    constructor(address admin_) {
        emit AdminSet(admin, admin_);
        admin = admin_;
    }

    /// @notice Sets a new admin
    /// @param newAdmin Address of the new admin
    /// @custom:access Restricted to protocol admin.
    function setAdmin(address newAdmin) external onlyAdmin {
        emit AdminSet(admin, newAdmin);
        admin = newAdmin;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { SickleStorage } from "contracts/base/SickleStorage.sol";
import { SickleRegistry } from "contracts/SickleRegistry.sol";

/// @title Multicall contract
/// @author vfat.tools
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract NonDelegateMulticall is SickleStorage {
    /// ERRORS ///

    error MulticallParamsMismatchError(); // 0xc1e637c9

    /// @notice Thrown when the target contract is not whitelisted
    /// @param target Address of the non-whitelisted target
    error TargetNotWhitelisted(address target); // 0x47ccabe7

    /// @notice Thrown when the caller is not whitelisted
    /// @param caller Address of the non-whitelisted caller
    error CallerNotWhitelisted(address caller); // 0x252c8273

    /// STORAGE ///

    /// @notice Address of the SickleRegistry contract
    /// @dev Needs to be immutable so that it's accessible for Sickle proxies
    SickleRegistry public immutable registry;

    /// INITIALIZATION ///

    /// @param registry_ Address of the SickleRegistry contract
    constructor(SickleRegistry registry_) initializer {
        registry = registry_;
    }

    /// WRITE FUNCTIONS ///

    /// @notice Batch multiple calls together (calls or delegatecalls)
    /// @param targets Array of targets to call
    /// @param data Array of data to pass with the calls
    function multicall(
        address[] calldata targets,
        bytes[] calldata data
    ) external payable {
        if (targets.length != data.length) {
            revert MulticallParamsMismatchError();
        }

        if (!registry.isWhitelistedCaller(msg.sender)) {
            revert CallerNotWhitelisted(msg.sender);
        }

        for (uint256 i = 0; i != data.length;) {
            if (targets[i] == address(0)) {
                unchecked {
                    ++i;
                }
                continue; // No-op
            }

            if (targets[i] != address(this)) {
                if (!registry.isWhitelistedTarget(targets[i])) {
                    revert TargetNotWhitelisted(targets[i]);
                }
            }

            (bool success, bytes memory result) = targets[i].call(data[i]);

            if (!success) {
                if (result.length == 0) revert();
                assembly {
                    revert(add(32, result), mload(result))
                }
            }
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { SickleStorage } from "contracts/base/SickleStorage.sol";
import { Multicall } from "contracts/base/Multicall.sol";
import { SickleRegistry } from "contracts/SickleRegistry.sol";

/// @title Sickle contract
/// @author vfat.tools
/// @notice Sickle facilitates farming and interactions with MasterChef
/// contracts
/// @dev Base contract inheriting from all the other "manager" contracts
contract Sickle is SickleStorage, Multicall {
    /// @notice Function to receive ETH
    receive() external payable { }

    /// @param sickleRegistry_ Address of the SickleRegistry contract
    constructor(SickleRegistry sickleRegistry_)
        initializer
        Multicall(sickleRegistry_)
    {
        _Sickle_initialize(address(0), address(0));
    }

    /// @param sickleOwner_ Address of the Sickle owner
    function initialize(
        address sickleOwner_,
        address approved_
    ) external initializer {
        _Sickle_initialize(sickleOwner_, approved_);
    }

    /// INTERNALS ///

    function _Sickle_initialize(
        address sickleOwner_,
        address approved_
    ) internal {
        SickleStorage._SickleStorage_initialize(sickleOwner_, approved_);
    }

    function onERC721Received(
        address, // operator
        address, // from
        uint256, // tokenId
        bytes calldata // data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address, // operator
        address, // from
        uint256, // id
        uint256, // value
        bytes calldata // data
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, // operator
        address, // from
        uint256[] calldata, // ids
        uint256[] calldata, // values
        bytes calldata // data
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Admin } from "contracts/base/Admin.sol";

library SickleRegistryEvents {
    event CollectorChanged(address newCollector);
    event FeesUpdated(bytes32[] feeHashes, uint256[] feesInBP);
    event ReferralCodeCreated(bytes32 indexed code, address indexed referrer);

    // Multicall caller and target whitelist status changes
    event CallerStatusChanged(address caller, bool isWhitelisted);
    event TargetStatusChanged(address target, bool isWhitelisted);
}

/// @title SickleRegistry contract
/// @author vfat.tools
/// @notice Manages the whitelisted contracts and the collector address
contract SickleRegistry is Admin {
    /// ERRORS ///

    error ArrayLengthMismatch(); // 0xa24a13a6
    error FeeAboveMaxLimit(); // 0xd6cf7b5e
    error InvalidReferralCode(); // 0xe55b4629

    /// STORAGE ///

    /// @notice Address of the fee collector
    address public collector;

    /// @notice Tracks the contracts that can be called through Sickle multicall
    /// @return True if the contract is a whitelisted target
    mapping(address => bool) public isWhitelistedTarget;

    /// @notice Tracks the contracts that can call Sickle multicall
    /// @return True if the contract is a whitelisted caller
    mapping(address => bool) public isWhitelistedCaller;

    /// @notice Keeps track of the referrers and their associated code
    mapping(bytes32 => address) public referralCodes;

    /// @notice Mapping for fee hashes (hash of the strategy contract addresses
    /// and the function selectors) and their associated fees
    /// @return The fee in basis points to apply to the transaction amount
    mapping(bytes32 => uint256) public feeRegistry;

    /// WRITE FUNCTIONS ///

    /// @param admin_ Address of the admin
    /// @param collector_ Address of the collector
    constructor(address admin_, address collector_) Admin(admin_) {
        collector = collector_;
    }

    /// @notice Updates the whitelist status for multiple multicall targets
    /// @param targets Addresses of the contracts to update
    /// @param isApproved New status for the contracts
    /// @custom:access Restricted to protocol admin.
    function setWhitelistedTargets(
        address[] calldata targets,
        bool isApproved
    ) external onlyAdmin {
        for (uint256 i; i < targets.length;) {
            isWhitelistedTarget[targets[i]] = isApproved;
            emit SickleRegistryEvents.TargetStatusChanged(
                targets[i], isApproved
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Updates the fee collector address
    /// @param newCollector Address of the new fee collector
    /// @custom:access Restricted to protocol admin.
    function updateCollector(address newCollector) external onlyAdmin {
        collector = newCollector;
        emit SickleRegistryEvents.CollectorChanged(newCollector);
    }

    /// @notice Update the whitelist status for multiple multicall callers
    /// @param callers Addresses of the callers
    /// @param isApproved New status for the caller
    /// @custom:access Restricted to protocol admin.
    function setWhitelistedCallers(
        address[] calldata callers,
        bool isApproved
    ) external onlyAdmin {
        for (uint256 i; i < callers.length;) {
            isWhitelistedCaller[callers[i]] = isApproved;
            emit SickleRegistryEvents.CallerStatusChanged(
                callers[i], isApproved
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Associates a referral code to the address of the caller
    function setReferralCode(bytes32 referralCode) external {
        if (referralCodes[referralCode] != address(0)) {
            revert InvalidReferralCode();
        }

        referralCodes[referralCode] = msg.sender;
        emit SickleRegistryEvents.ReferralCodeCreated(referralCode, msg.sender);
    }

    /// @notice Update the fees for multiple strategy functions
    /// @param feeHashes Array of fee hashes
    /// @param feesArray Array of fees to apply (in basis points)
    /// @custom:access Restricted to protocol admin.
    function setFees(
        bytes32[] calldata feeHashes,
        uint256[] calldata feesArray
    ) external onlyAdmin {
        if (feeHashes.length != feesArray.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < feeHashes.length;) {
            if (feesArray[i] <= 500) {
                // maximum fee of 5%
                feeRegistry[feeHashes[i]] = feesArray[i];
            } else {
                revert FeeAboveMaxLimit();
            }
            unchecked {
                ++i;
            }
        }

        emit SickleRegistryEvents.FeesUpdated(feeHashes, feesArray);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Sickle } from "contracts/Sickle.sol";
import { CompoundParams } from "contracts/structs/FarmStrategyStructs.sol";

interface ICompoundable {
    function compoundFor(
        Sickle sickle,
        CompoundParams calldata params,
        address[] memory sweepTokens
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Sickle } from "contracts/Sickle.sol";
import { HarvestParams } from "contracts/structs/FarmStrategyStructs.sol";

interface IHarvestable {
    function harvestFor(
        Sickle sickle,
        HarvestParams calldata params,
        address[] memory sweepTokens
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Sickle } from "contracts/Sickle.sol";
import {
    DepositParams,
    HarvestParams,
    WithdrawParams
} from "contracts/structs/FarmStrategyStructs.sol";
import { NftInfo } from "contracts/interfaces/INftSettingsRegistry.sol";

struct RebalanceParams {
    NftInfo nftInfo;
    HarvestParams harvestParams;
    WithdrawParams withdrawParams;
    DepositParams depositParams;
}

interface IRebalanceable {
    function rebalanceFor(
        Sickle sickle,
        RebalanceParams calldata params,
        address[] calldata sweepTokens
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ZapInData, ZapOutData } from "contracts/libraries/ZapLib.sol";
import { SwapData } from "contracts/interfaces/ILiquidityConnector.sol";

struct DepositParams {
    address stakingContractAddress;
    address[] tokensIn;
    uint256[] amountsIn;
    ZapInData zapData;
    bytes extraData;
}

struct WithdrawParams {
    address stakingContractAddress;
    bytes extraData;
    ZapOutData zapData;
    address[] tokensOut;
}

struct HarvestParams {
    address stakingContractAddress;
    SwapData[] swaps;
    bytes extraData;
    address[] tokensOut;
}

struct CompoundParams {
    address claimContractAddress;
    bytes claimExtraData;
    address[] rewardTokens;
    ZapInData zapData;
    address depositContractAddress;
    bytes depositExtraData;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Initializable } from
    "@openzeppelin/contracts/proxy/utils/Initializable.sol";

library SickleStorageEvents {
    event ApprovedAddressChanged(address newApproved);
}

/// @title SickleStorage contract
/// @author vfat.tools
/// @notice Base storage of the Sickle contract
/// @dev This contract needs to be inherited by stub contracts meant to be used
/// with `delegatecall`
abstract contract SickleStorage is Initializable {
    /// ERRORS ///

    /// @notice Thrown when the caller is not the owner of the Sickle contract
    error NotOwnerError(); // 0x74a21527

    /// @notice Thrown when the caller is not a strategy contract or the
    /// Flashloan Stub
    error NotStrategyError(); // 0x4581ba62

    /// STORAGE ///

    /// @notice Address of the owner
    address public owner;

    /// @notice An address that can be set by the owner of the Sickle contract
    /// in order to trigger specific functions.
    address public approved;

    /// MODIFIERS ///

    /// @dev Restricts a function call to the owner, however if the admin was
    /// not set yet,
    /// the modifier will not restrict the call, this allows the SickleFactory
    /// to perform
    /// some calls on the user's behalf before passing the admin rights to them
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerError();
        _;
    }

    /// INITIALIZATION ///

    /// @param owner_ Address of the owner of this Sickle contract
    function _SickleStorage_initialize(
        address owner_,
        address approved_
    ) internal onlyInitializing {
        owner = owner_;
        approved = approved_;
    }

    /// WRITE FUNCTIONS ///

    /// @notice Sets the approved address of this Sickle
    /// @param newApproved Address meant to be approved by the owner
    function setApproved(address newApproved) external onlyOwner {
        approved = newApproved;
        emit SickleStorageEvents.ApprovedAddressChanged(newApproved);
    }

    /// @notice Checks if `caller` is either the owner of the Sickle contract
    /// or was approved by them
    /// @param caller Address to check
    /// @return True if `caller` is either the owner of the Sickle contract
    function isOwnerOrApproved(address caller) public view returns (bool) {
        return caller == owner || caller == approved;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { SickleStorage } from "contracts/base/SickleStorage.sol";
import { SickleRegistry } from "contracts/SickleRegistry.sol";

/// @title Multicall contract
/// @author vfat.tools
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is SickleStorage {
    /// ERRORS ///

    error MulticallParamsMismatchError(); // 0xc1e637c9

    /// @notice Thrown when the target contract is not whitelisted
    /// @param target Address of the non-whitelisted target
    error TargetNotWhitelisted(address target); // 0x47ccabe7

    /// @notice Thrown when the caller is not whitelisted
    /// @param caller Address of the non-whitelisted caller
    error CallerNotWhitelisted(address caller); // 0x252c8273

    /// STORAGE ///

    /// @notice Address of the SickleRegistry contract
    /// @dev Needs to be immutable so that it's accessible for Sickle proxies
    SickleRegistry public immutable registry;

    /// INITIALIZATION ///

    /// @param registry_ Address of the SickleRegistry contract
    constructor(SickleRegistry registry_) initializer {
        registry = registry_;
    }

    /// WRITE FUNCTIONS ///

    /// @notice Batch multiple calls together (calls or delegatecalls)
    /// @param targets Array of targets to call
    /// @param data Array of data to pass with the calls
    function multicall(
        address[] calldata targets,
        bytes[] calldata data
    ) external payable {
        if (targets.length != data.length) {
            revert MulticallParamsMismatchError();
        }

        if (!registry.isWhitelistedCaller(msg.sender)) {
            revert CallerNotWhitelisted(msg.sender);
        }

        for (uint256 i = 0; i != data.length;) {
            if (targets[i] == address(0)) {
                unchecked {
                    ++i;
                }
                continue; // No-op
            }

            if (targets[i] != address(this)) {
                if (!registry.isWhitelistedTarget(targets[i])) {
                    revert TargetNotWhitelisted(targets[i]);
                }
            }

            (bool success, bytes memory result) =
                targets[i].delegatecall(data[i]);

            if (!success) {
                if (result.length == 0) revert();
                assembly {
                    revert(add(32, result), mload(result))
                }
            }
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IUniswapV3Pool } from
    "contracts/interfaces/external/uniswap/IUniswapV3Pool.sol";
import { INonfungiblePositionManager } from
    "contracts/interfaces/external/uniswap/INonfungiblePositionManager.sol";
import { Sickle } from "contracts/Sickle.sol";

struct NftKey {
    Sickle sickle;
    INonfungiblePositionManager nftManager;
    uint256 tokenId;
}

/**
 * @notice Settings for automatic rebalancing
 * @param diffToRebalanceBelowTick: Difference from position tickLower to
 * rebalance below
 * Default: 0 (always rebalance if tick < tickLower)
 * @param diffToRebalanceAboveTick: Difference from position tickUpper to
 * rebalance above
 * Default: 0 (always rebalance if tick >= tickUpper)
 * @param slippageBP: Slippage in basis points
 * Used for price impact as well
 * @param stopLossTickLow: stop rebalancing below this tick
 * default: MIN_TICK (no stop loss)
 * @param stopLossTickHigh: stop rebalancing above this tick
 * default: MAX_TICK (no stop loss)
 * @param delayMin: delay in minutes before rebalancing
 */
struct RebalanceConfig {
    uint24 diffToRebalanceBelowTick;
    uint24 diffToRebalanceAboveTick;
    uint256 slippageBP;
    int24 stopLossTickLow;
    int24 stopLossTickHigh;
    uint8 delayMin;
}

enum RewardBehavior {
    Compound,
    Harvest
}

struct NftSettings {
    bool autoRebalance;
    RewardBehavior rewardBehavior;
    address harvestTokenOut;
    RebalanceConfig rebalanceConfig;
}

struct NftInfo {
    IUniswapV3Pool pool;
    INonfungiblePositionManager nftManager;
    uint256 tokenId;
}

interface INftSettingsRegistry {
    function getNftSettings(NftKey calldata key)
        external
        view
        returns (NftSettings memory);

    function resetNftSettings(
        NftKey calldata oldKey,
        NftKey calldata newKey,
        NftSettings calldata settings
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import {
    ILiquidityConnector,
    SwapData,
    AddLiquidityData,
    RemoveLiquidityData
} from "contracts/interfaces/ILiquidityConnector.sol";
import { SwapLib } from "contracts/libraries/SwapLib.sol";
import { ConnectorRegistry } from "contracts/ConnectorRegistry.sol";
import { DelegateModule } from "contracts/modules/DelegateModule.sol";

struct ZapInData {
    SwapData[] swaps;
    AddLiquidityData addLiquidityData;
}

struct ZapOutData {
    RemoveLiquidityData removeLiquidityData;
    SwapData[] swaps;
}

contract ZapLib is DelegateModule {
    error LiquidityAmountError(); // 0x4d0ab6b4

    SwapLib public immutable swapLib;
    ConnectorRegistry public immutable connectorRegistry;

    constructor(ConnectorRegistry connectorRegistry_, SwapLib swapLib_) {
        connectorRegistry = connectorRegistry_;
        swapLib = swapLib_;
    }

    function zapIn(ZapInData memory zapData) external payable {
        uint256 swapDataLength = zapData.swaps.length;
        for (uint256 i; i < swapDataLength;) {
            _delegateTo(
                address(swapLib),
                abi.encodeCall(SwapLib.swap, (zapData.swaps[i]))
            );
            unchecked {
                i++;
            }
        }

        if (zapData.addLiquidityData.lpToken == address(0)) {
            return;
        }

        bool atLeastOneNonZero = false;

        AddLiquidityData memory addLiquidityData = zapData.addLiquidityData;
        uint256 addLiquidityDataTokensLength = addLiquidityData.tokens.length;
        for (uint256 i; i < addLiquidityDataTokensLength; i++) {
            if (addLiquidityData.tokens[i] == address(0)) {
                continue;
            }
            if (addLiquidityData.desiredAmounts[i] == 0) {
                addLiquidityData.desiredAmounts[i] =
                    IERC20(addLiquidityData.tokens[i]).balanceOf(address(this));
            }
            if (addLiquidityData.desiredAmounts[i] > 0) {
                atLeastOneNonZero = true;
                // In case there is USDT or similar dust approval, revoke it
                SafeTransferLib.safeApprove(
                    addLiquidityData.tokens[i], addLiquidityData.router, 0
                );
                SafeTransferLib.safeApprove(
                    addLiquidityData.tokens[i],
                    addLiquidityData.router,
                    addLiquidityData.desiredAmounts[i]
                );
            }
        }

        if (!atLeastOneNonZero) {
            revert LiquidityAmountError();
        }

        address routerConnector =
            connectorRegistry.connectorOf(addLiquidityData.router);

        _delegateTo(
            routerConnector,
            abi.encodeCall(ILiquidityConnector.addLiquidity, (addLiquidityData))
        );

        for (uint256 i; i < addLiquidityDataTokensLength;) {
            if (addLiquidityData.tokens[i] != address(0)) {
                // Revoke any dust approval in case the amount was estimated
                SafeTransferLib.safeApprove(
                    addLiquidityData.tokens[i], addLiquidityData.router, 0
                );
            }
            unchecked {
                i++;
            }
        }
    }

    function zapOut(ZapOutData memory zapData) external {
        if (zapData.removeLiquidityData.lpToken != address(0)) {
            if (zapData.removeLiquidityData.lpAmountIn > 0) {
                SafeTransferLib.safeApprove(
                    zapData.removeLiquidityData.lpToken,
                    zapData.removeLiquidityData.router,
                    zapData.removeLiquidityData.lpAmountIn
                );
            }
            address routerConnector = connectorRegistry.connectorOf(
                zapData.removeLiquidityData.router
            );
            _delegateTo(
                address(routerConnector),
                abi.encodeCall(
                    ILiquidityConnector.removeLiquidity,
                    zapData.removeLiquidityData
                )
            );
        }

        uint256 swapDataLength = zapData.swaps.length;
        for (uint256 i; i < swapDataLength;) {
            _delegateTo(
                address(swapLib),
                abi.encodeCall(SwapLib.swap, (zapData.swaps[i]))
            );
            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AddLiquidityData {
    address router;
    address lpToken;
    address[] tokens;
    uint256[] desiredAmounts;
    uint256[] minAmounts;
    bytes extraData;
}

struct RemoveLiquidityData {
    address router;
    address lpToken;
    address[] tokens;
    uint256 lpAmountIn;
    uint256[] minAmountsOut;
    bytes extraData;
}

struct SwapData {
    address router;
    uint256 amountIn;
    uint256 minAmountOut;
    address tokenIn;
    bytes extraData;
}

interface ILiquidityConnector {
    function addLiquidity(AddLiquidityData memory addLiquidityData)
        external
        payable;

    function removeLiquidity(RemoveLiquidityData memory removeLiquidityData)
        external;

    function swapExactTokensForTokens(SwapData memory swapData)
        external
        payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
        if (_initialized < type(uint8).max) {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods
/// will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the
    /// IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and
    /// always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick,
    /// i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always
    /// positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick
    /// in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from
    /// overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding
    /// in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any
/// frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is
    /// exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a
    /// sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last
    /// tick transition that was run.
    /// This value may not always be equal to
    /// SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that
    /// was written,
    /// @return observationCardinality The current maximum number of
    /// observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of
    /// observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted
    /// 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap
    /// fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
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

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit
    /// of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit
    /// of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees()
        external
        view
        returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all
    /// ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses
    /// the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price
    /// crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the
    /// tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the
    /// tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other
    /// side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity
    /// on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick
    /// from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e.
    /// liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if
    /// liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in
    /// comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See
    /// TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the
    /// owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick
    /// range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick
    /// range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position
    /// as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position
    /// as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to
    /// get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the
    /// life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range
    /// liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the
    /// values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

interface IUniswapV3Pool is IUniswapV3PoolImmutables, IUniswapV3PoolState {
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC721Enumerable } from
    "openzeppelin-contracts/contracts/interfaces/IERC721Enumerable.sol";

interface INonfungiblePositionManager is IERC721Enumerable {
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function increaseLiquidity(IncreaseLiquidityParams memory params)
        external
        payable
        returns (uint256 amount0, uint256 amount1, uint256 liquidity);

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function mint(MintParams memory params)
        external
        payable
        returns (uint256 tokenId, uint256 amount0, uint256 amount1);

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external payable;

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ETHTransferFailed();
    error TransferFromFailed();
    error TransferFailed();
    error ApproveFailed();

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!success) revert ETHTransferFailed();
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        if (!success) revert TransferFromFailed();
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success) revert TransferFailed();
    }

    function safeApprove(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success) revert ApproveFailed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { DelegateModule } from "contracts/modules/DelegateModule.sol";
import { ConnectorRegistry } from "contracts/ConnectorRegistry.sol";
import {
    ILiquidityConnector,
    SwapData
} from "contracts/interfaces/ILiquidityConnector.sol";

contract SwapLib is DelegateModule {
    error SwapAmountZero();

    ConnectorRegistry immutable connectorRegistry;

    constructor(ConnectorRegistry connectorRegistry_) {
        connectorRegistry = connectorRegistry_;
    }

    function swap(SwapData memory swapData) external payable {
        _swap(swapData);
    }

    function swapMultiple(SwapData[] memory swapData) external {
        uint256 swapDataLength = swapData.length;
        for (uint256 i; i < swapDataLength;) {
            _swap(swapData[i]);
            unchecked {
                i++;
            }
        }
    }

    /* Internal Functions */

    function _swap(SwapData memory swapData) internal {
        address tokenIn = swapData.tokenIn;

        if (swapData.amountIn == 0) {
            swapData.amountIn = IERC20(tokenIn).balanceOf(address(this));
        }

        if (swapData.amountIn == 0) {
            revert SwapAmountZero();
        }

        // In case there is USDT dust approval, revoke it
        SafeTransferLib.safeApprove(tokenIn, swapData.router, 0);

        SafeTransferLib.safeApprove(tokenIn, swapData.router, swapData.amountIn);

        address connectorAddress =
            connectorRegistry.connectorOf(swapData.router);

        ILiquidityConnector routerConnector =
            ILiquidityConnector(connectorAddress);

        _delegateTo(
            address(routerConnector),
            abi.encodeCall(routerConnector.swapExactTokensForTokens, swapData)
        );

        // Revoke any approval after swap in case the swap amount was estimated
        SafeTransferLib.safeApprove(tokenIn, swapData.router, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Admin } from "contracts/base/Admin.sol";
import { TimelockAdmin } from "contracts/base/TimelockAdmin.sol";

error ConnectorNotRegistered(address target);

interface ICustomConnectorRegistry {
    function connectorOf(address target) external view returns (address);
}

contract ConnectorRegistry is Admin, TimelockAdmin {
    event ConnectorChanged(address target, address connector);
    event CustomRegistryAdded(address registry);
    event CustomRegistryRemoved(address registry);

    error ConnectorAlreadySet(address target);
    error ConnectorNotSet(address target);

    ICustomConnectorRegistry[] public customRegistries;
    mapping(ICustomConnectorRegistry => bool) public isCustomRegistry;

    mapping(address target => address connector) private connectors_;

    constructor(
        address admin_,
        address timelockAdmin_
    ) Admin(admin_) TimelockAdmin(timelockAdmin_) { }

    /// @notice Update connector addresses for a batch of targets.
    /// @dev Controls which connector contracts are used for the specified
    /// targets.
    /// @custom:access Restricted to protocol admin.
    function setConnectors(
        address[] calldata targets,
        address[] calldata connectors
    ) external onlyAdmin {
        for (uint256 i; i != targets.length;) {
            if (connectors_[targets[i]] != address(0)) {
                revert ConnectorAlreadySet(targets[i]);
            }
            connectors_[targets[i]] = connectors[i];
            emit ConnectorChanged(targets[i], connectors[i]);

            unchecked {
                ++i;
            }
        }
    }

    function updateConnectors(
        address[] calldata targets,
        address[] calldata connectors
    ) external onlyTimelockAdmin {
        for (uint256 i; i != targets.length;) {
            if (connectors_[targets[i]] == address(0)) {
                revert ConnectorNotSet(targets[i]);
            }
            connectors_[targets[i]] = connectors[i];
            emit ConnectorChanged(targets[i], connectors[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Append an address to the custom registries list.
    /// @custom:access Restricted to protocol admin.
    function addCustomRegistry(ICustomConnectorRegistry registry)
        external
        onlyAdmin
    {
        customRegistries.push(registry);
        isCustomRegistry[registry] = true;
        emit CustomRegistryAdded(address(registry));
    }

    /// @notice Replace an address in the custom registries list.
    /// @custom:access Restricted to protocol admin.
    function updateCustomRegistry(
        uint256 index,
        ICustomConnectorRegistry newRegistry
    ) external onlyTimelockAdmin {
        address oldRegistry = address(customRegistries[index]);
        isCustomRegistry[customRegistries[index]] = false;
        emit CustomRegistryRemoved(oldRegistry);
        customRegistries[index] = newRegistry;
        isCustomRegistry[newRegistry] = true;
        if (address(newRegistry) != address(0)) {
            emit CustomRegistryAdded(address(newRegistry));
        }
    }

    function connectorOf(address target) external view returns (address) {
        address connector = connectors_[target];
        if (connector != address(0)) {
            return connector;
        }

        uint256 length = customRegistries.length;
        for (uint256 i; i != length;) {
            if (address(customRegistries[i]) != address(0)) {
                try customRegistries[i].connectorOf(target) returns (
                    address _connector
                ) {
                    if (_connector != address(0)) {
                        return _connector;
                    }
                } catch {
                    // Ignore
                }
            }

            unchecked {
                ++i;
            }
        }

        revert ConnectorNotRegistered(target);
    }

    function hasConnector(address target) external view returns (bool) {
        if (connectors_[target] != address(0)) {
            return true;
        }

        uint256 length = customRegistries.length;
        for (uint256 i; i != length;) {
            if (address(customRegistries[i]) != address(0)) {
                try customRegistries[i].connectorOf(target) returns (
                    address _connector
                ) {
                    if (_connector != address(0)) {
                        return true;
                    }
                } catch {
                    // Ignore
                }

                unchecked {
                    ++i;
                }
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DelegateModule {
    function _delegateTo(
        address to,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory result) = to.delegatecall(data);

        if (!success) {
            if (result.length == 0) revert();
            assembly {
                revert(add(32, result), mload(result))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title TimelockAdmin contract
/// @author vfat.tools
/// @notice Provides an timelockAdministration mechanism allowing restricted
/// functions
abstract contract TimelockAdmin {
    /// ERRORS ///

    /// @notice Thrown when the caller is not the timelockAdmin
    error NotTimelockAdminError();

    /// EVENTS ///

    /// @notice Emitted when a new timelockAdmin is set
    /// @param oldTimelockAdmin Address of the old timelockAdmin
    /// @param newTimelockAdmin Address of the new timelockAdmin
    event TimelockAdminSet(address oldTimelockAdmin, address newTimelockAdmin);

    /// STORAGE ///

    /// @notice Address of the current timelockAdmin
    address public timelockAdmin;

    /// MODIFIERS ///

    /// @dev Restricts a function to the timelockAdmin
    modifier onlyTimelockAdmin() {
        if (msg.sender != timelockAdmin) revert NotTimelockAdminError();
        _;
    }

    /// WRITE FUNCTIONS ///

    /// @param timelockAdmin_ Address of the timelockAdmin
    constructor(address timelockAdmin_) {
        emit TimelockAdminSet(timelockAdmin, timelockAdmin_);
        timelockAdmin = timelockAdmin_;
    }

    /// @notice Sets a new timelockAdmin
    /// @dev Can only be called by the current timelockAdmin
    /// @param newTimelockAdmin Address of the new timelockAdmin
    function setTimelockAdmin(address newTimelockAdmin)
        external
        onlyTimelockAdmin
    {
        emit TimelockAdminSet(timelockAdmin, newTimelockAdmin);
        timelockAdmin = newTimelockAdmin;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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