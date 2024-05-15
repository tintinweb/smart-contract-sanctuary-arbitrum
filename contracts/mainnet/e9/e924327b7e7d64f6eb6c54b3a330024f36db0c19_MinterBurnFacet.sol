// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {Arrays} from "libs/Arrays.sol";
import {Role, Enums} from "common/Constants.sol";
import {burnKrAsset} from "common/funcs/Actions.sol";
import {cs} from "common/State.sol";
import {Asset} from "common/Types.sol";
import {Modifiers} from "common/Modifiers.sol";
import {Errors} from "common/Errors.sol";

import {IMinterBurnFacet} from "minter/interfaces/IMinterBurnFacet.sol";
import {ms, MinterState} from "minter/MState.sol";
import {MEvent} from "minter/MEvent.sol";
import {handleMinterFee} from "minter/funcs/MFees.sol";
import {BurnArgs} from "common/Args.sol";

/**
 * @author Kresko
 * @title MinterBurnFacet
 * @notice Core burning functionality for Kresko Minter.
 */
contract MinterBurnFacet is Modifiers, IMinterBurnFacet {
    using Arrays for address[];

    /// @inheritdoc IMinterBurnFacet
    function burnKreskoAsset(
        BurnArgs memory args,
        bytes[] calldata _updateData
    )
        external
        payable
        nonReentrant
        onlyRoleIf(args.account != msg.sender || args.repayee != msg.sender, Role.MANAGER)
        usePyth(_updateData)
    {
        if (args.amount == 0) revert Errors.ZERO_BURN(Errors.id(args.krAsset));
        Asset storage asset = cs().onlyMinterMintable(args.krAsset, Enums.Action.Repay);

        MinterState storage s = ms();
        // Get accounts principal debt
        uint256 debtAmount = s.accountDebtAmount(args.account, args.krAsset, asset);
        if (debtAmount == 0) revert Errors.ZERO_DEBT(Errors.id(args.krAsset));

        if (args.amount != type(uint256).max) {
            if (args.amount > debtAmount) {
                revert Errors.BURN_AMOUNT_OVERFLOW(Errors.id(args.krAsset), args.amount, debtAmount);
            }
            // Ensure principal left is either 0 or >= minDebtValue
            args.amount = asset.checkDust(args.amount, debtAmount);
        } else {
            // Burn full debt
            args.amount = debtAmount;
        }

        // Charge the burn fee from collateral of args.account
        handleMinterFee(asset, args.account, args.amount, Enums.MinterFee.Close);

        // Record the burn
        s.kreskoAssetDebt[args.account][args.krAsset] -= burnKrAsset(args.amount, args.repayee, asset.anchor);

        // If sender repays all debt of asset, remove it from minted assets array.
        if (s.accountDebtAmount(args.account, args.krAsset, asset) == 0) {
            s.mintedKreskoAssets[args.account].removeAddress(args.krAsset, args.mintIndex);
        }

        // Emit logs
        emit MEvent.KreskoAssetBurned(args.account, args.krAsset, args.amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {Errors} from "common/Errors.sol";
import {Enums} from "common/Constants.sol";

/**
 * @title Library for operations on arrays
 */
library Arrays {
    using Arrays for address[];
    using Arrays for bytes32[];
    using Arrays for string[];

    struct FindResult {
        uint256 index;
        bool exists;
    }

    function empty(address[2] memory _addresses) internal pure returns (bool) {
        return _addresses[0] == address(0) && _addresses[1] == address(0);
    }

    function empty(Enums.OracleType[2] memory _oracles) internal pure returns (bool) {
        return _oracles[0] == Enums.OracleType.Empty && _oracles[1] == Enums.OracleType.Empty;
    }

    function findIndex(address[] memory _elements, address _elementToFind) internal pure returns (int256 idx) {
        for (uint256 i; i < _elements.length; ) {
            if (_elements[i] == _elementToFind) {
                return int256(i);
            }
            unchecked {
                ++i;
            }
        }

        return -1;
    }

    function find(address[] storage _elements, address _elementToFind) internal pure returns (FindResult memory result) {
        address[] memory elements = _elements;
        for (uint256 i; i < elements.length; ) {
            if (elements[i] == _elementToFind) {
                return FindResult(i, true);
            }
            unchecked {
                ++i;
            }
        }
    }

    function find(bytes32[] storage _elements, bytes32 _elementToFind) internal pure returns (FindResult memory result) {
        bytes32[] memory elements = _elements;
        for (uint256 i; i < elements.length; ) {
            if (elements[i] == _elementToFind) {
                return FindResult(i, true);
            }
            unchecked {
                ++i;
            }
        }
    }

    function find(string[] storage _elements, string memory _elementToFind) internal pure returns (FindResult memory result) {
        string[] memory elements = _elements;
        for (uint256 i; i < elements.length; ) {
            if (keccak256(abi.encodePacked(elements[i])) == keccak256(abi.encodePacked(_elementToFind))) {
                return FindResult(i, true);
            }
            unchecked {
                ++i;
            }
        }
    }

    function pushUnique(address[] storage _elements, address _elementToAdd) internal {
        if (!_elements.find(_elementToAdd).exists) {
            _elements.push(_elementToAdd);
        }
    }

    function pushUnique(bytes32[] storage _elements, bytes32 _elementToAdd) internal {
        if (!_elements.find(_elementToAdd).exists) {
            _elements.push(_elementToAdd);
        }
    }

    function pushUnique(string[] storage _elements, string memory _elementToAdd) internal {
        if (!_elements.find(_elementToAdd).exists) {
            _elements.push(_elementToAdd);
        }
    }

    function removeExisting(address[] storage _addresses, address _elementToRemove) internal {
        FindResult memory result = _addresses.find(_elementToRemove);
        if (result.exists) {
            _addresses.removeAddress(_elementToRemove, result.index);
        }
    }

    /**
     * @dev Removes an element by copying the last element to the element to remove's place and removing
     * the last element.
     * @param _addresses The address array containing the item to be removed.
     * @param _elementToRemove The element to be removed.
     * @param _elementIndex The index of the element to be removed.
     */
    function removeAddress(address[] storage _addresses, address _elementToRemove, uint256 _elementIndex) internal {
        if (_addresses[_elementIndex] != _elementToRemove)
            revert Errors.ELEMENT_DOES_NOT_MATCH_PROVIDED_INDEX(Errors.id(_elementToRemove), _elementIndex, _addresses);

        uint256 lastIndex = _addresses.length - 1;
        // If the index to remove is not the last one, overwrite the element at the index
        // with the last element.
        if (_elementIndex != lastIndex) {
            _addresses[_elementIndex] = _addresses[lastIndex];
        }
        // Remove the last element.
        _addresses.pop();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Enums                                   */
/* -------------------------------------------------------------------------- */
library Enums {
    /**
     * @dev Minter fees for minting and burning.
     * Open = 0
     * Close = 1
     */
    enum MinterFee {
        Open,
        Close
    }
    /**
     * @notice Swap fee types for shared collateral debt pool swaps.
     * Open = 0
     * Close = 1
     */
    enum SwapFee {
        In,
        Out
    }
    /**
     * @notice Configurable oracle types for assets.
     * Empty = 0
     * Redstone = 1,
     * Chainlink = 2,
     * API3 = 3,
     * Vault = 4
     * Pyth = 5
     */
    enum OracleType {
        Empty,
        Redstone,
        Chainlink,
        API3,
        Vault,
        Pyth
    }

    /**
     * @notice Protocol core actions.
     * Deposit = 0
     * Withdraw = 1,
     * Repay = 2,
     * Borrow = 3,
     * Liquidate = 4
     * SCDPDeposit = 5,
     * SCDPSwap = 6,
     * SCDPWithdraw = 7,
     * SCDPRepay = 8,
     * SCDPLiquidation = 9
     * SCDPFeeClaim = 10
     * SCDPCover = 11
     */
    enum Action {
        Deposit,
        Withdraw,
        Repay,
        Borrow,
        Liquidation,
        SCDPDeposit,
        SCDPSwap,
        SCDPWithdraw,
        SCDPRepay,
        SCDPLiquidation,
        SCDPFeeClaim,
        SCDPCover
    }
}

/* -------------------------------------------------------------------------- */
/*                               Access Control                               */
/* -------------------------------------------------------------------------- */

library Role {
    /// @dev Meta role for all roles.
    bytes32 internal constant DEFAULT_ADMIN = 0x00;
    /// @dev keccak256("kresko.roles.minter.admin")
    bytes32 internal constant ADMIN = 0xb9dacdf02281f2e98ddbadaaf44db270b3d5a916342df47c59f77937a6bcd5d8;
    /// @dev keccak256("kresko.roles.minter.operator")
    bytes32 internal constant OPERATOR = 0x112e48a576fb3a75acc75d9fcf6e0bc670b27b1dbcd2463502e10e68cf57d6fd;
    /// @dev keccak256("kresko.roles.minter.manager")
    bytes32 internal constant MANAGER = 0x46925e0f0cc76e485772167edccb8dc449d43b23b55fc4e756b063f49099e6a0;
    /// @dev keccak256("kresko.roles.minter.safety.council")
    bytes32 internal constant SAFETY_COUNCIL = 0x9c387ecf1663f9144595993e2c602b45de94bf8ba3a110cb30e3652d79b581c0;
}

/* -------------------------------------------------------------------------- */
/*                                    MISC                                    */
/* -------------------------------------------------------------------------- */

library Constants {
    /// @dev Set the initial value to 1, (not hindering possible gas refunds by setting it to 0 on exit).
    uint8 internal constant NOT_ENTERED = 1;
    uint8 internal constant ENTERED = 2;
    uint8 internal constant NOT_INITIALIZING = 1;
    uint8 internal constant INITIALIZING = 2;

    bytes32 internal constant ZERO_BYTES32 = bytes32("");
    /// @dev The min oracle decimal precision
    uint256 internal constant MIN_ORACLE_DECIMALS = 8;
    /// @dev The minimum collateral amount for a kresko asset.
    uint256 internal constant MIN_KRASSET_COLLATERAL_AMOUNT = 1e12;

    /// @dev The maximum configurable minimum debt USD value. 8 decimals.
    uint256 internal constant MAX_MIN_DEBT_VALUE = 1_000 * 1e8; // $1,000
}

library Percents {
    uint16 internal constant ONE = 0.01e4;
    uint16 internal constant HUNDRED = 1e4;
    uint16 internal constant TWENTY_FIVE = 0.25e4;
    uint16 internal constant FIFTY = 0.50e4;
    uint16 internal constant MAX_DEVIATION = TWENTY_FIVE;

    uint16 internal constant BASIS_POINT = 1;
    /// @dev The maximum configurable close fee.
    uint16 internal constant MAX_CLOSE_FEE = 0.25e4; // 25%

    /// @dev The maximum configurable open fee.
    uint16 internal constant MAX_OPEN_FEE = 0.25e4; // 25%

    /// @dev The maximum configurable protocol fee per asset for collateral pool swaps.
    uint16 internal constant MAX_SCDP_FEE = 0.5e4; // 50%

    /// @dev The minimum configurable minimum collateralization ratio.
    uint16 internal constant MIN_LT = HUNDRED + ONE; // 101%
    uint16 internal constant MIN_MCR = HUNDRED + ONE + ONE; // 102%

    /// @dev The minimum configurable liquidation incentive multiplier.
    /// This means liquidator only receives equal amount of collateral to debt repaid.
    uint16 internal constant MIN_LIQ_INCENTIVE = HUNDRED;

    /// @dev The maximum configurable liquidation incentive multiplier.
    /// This means liquidator receives 25% bonus collateral compared to the debt repaid.
    uint16 internal constant MAX_LIQ_INCENTIVE = 1.25e4; // 125%
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {sdi} from "scdp/SState.sol";
import {IKreskoAssetIssuer} from "kresko-asset/IKreskoAssetIssuer.sol";
import {Asset} from "common/Types.sol";
import {Errors} from "common/Errors.sol";
import {Strings} from "libs/Strings.sol";
import {cs} from "common/State.sol";

using Strings for bytes32;

/* -------------------------------------------------------------------------- */
/*                                   Actions                                  */
/* -------------------------------------------------------------------------- */

/// @notice Burn kresko assets with anchor already known.
/// @param _burnAmount The amount being burned
/// @param _fromAddr The account to burn assets from.
/// @param _anchorAddr The anchor token of the asset being burned.
function burnKrAsset(uint256 _burnAmount, address _fromAddr, address _anchorAddr) returns (uint256 burned) {
    burned = IKreskoAssetIssuer(_anchorAddr).destroy(_burnAmount, _fromAddr);
    if (burned == 0) revert Errors.ZERO_BURN(Errors.id(_anchorAddr));
}

/// @notice Mint kresko assets with anchor already known.
/// @param _mintAmount The asset amount being minted
/// @param _toAddr The account receiving minted assets.
/// @param _anchorAddr The anchor token of the minted asset.
function mintKrAsset(uint256 _mintAmount, address _toAddr, address _anchorAddr) returns (uint256 minted) {
    minted = IKreskoAssetIssuer(_anchorAddr).issue(_mintAmount, _toAddr);
    if (minted == 0) revert Errors.ZERO_MINT(Errors.id(_anchorAddr));
}

/// @notice Repay SCDP swap debt.
/// @param _asset the asset being repaid
/// @param _burnAmount the asset amount being burned
/// @param _fromAddr the account to burn assets from
/// @return destroyed Normalized amount of burned assets.
function burnSCDP(Asset storage _asset, uint256 _burnAmount, address _fromAddr) returns (uint256 destroyed) {
    destroyed = burnKrAsset(_burnAmount, _fromAddr, _asset.anchor);

    uint256 sdiBurned = _asset.debtAmountToSDI(_burnAmount, false);
    if (sdiBurned > sdi().totalDebt) {
        if ((sdiBurned - sdi().totalDebt) > 10 ** cs().oracleDecimals) {
            revert Errors.SDI_DEBT_REPAY_OVERFLOW(sdi().totalDebt, sdiBurned);
        }
        sdi().totalDebt = 0;
    } else {
        sdi().totalDebt -= sdiBurned;
    }
}

/// @notice Mint kresko assets from SCDP swap.
/// @notice Reverts if market for asset is not open.
/// @param _asset the asset requested
/// @param _mintAmount the asset amount requested
/// @param _toAddr the account to mint the assets to
/// @return issued Normalized amount of minted assets.
function mintSCDP(Asset storage _asset, uint256 _mintAmount, address _toAddr) returns (uint256 issued) {
    if (!_asset.isMarketOpen()) revert Errors.MARKET_CLOSED(Errors.id(_asset.anchor), _asset.ticker.toString());
    issued = mintKrAsset(_mintAmount, _toAddr, _asset.anchor);
    unchecked {
        sdi().totalDebt += _asset.debtAmountToSDI(_mintAmount, false);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {EnumerableSet} from "@oz/utils/structs/EnumerableSet.sol";
import {LibModifiers} from "common/Modifiers.sol";
import {Enums} from "common/Constants.sol";
import {Asset, SafetyState, RoleData, Oracle} from "common/Types.sol";
import {IGatingManager} from "periphery/IGatingManager.sol";

using LibModifiers for CommonState global;

struct CommonState {
    /* -------------------------------------------------------------------------- */
    /*                                    Core                                    */
    /* -------------------------------------------------------------------------- */
    /// @notice asset address -> asset data
    mapping(address => Asset) assets;
    /// @notice asset -> oracle type -> oracle
    mapping(bytes32 => mapping(Enums.OracleType => Oracle)) oracles;
    /// @notice asset -> action -> state
    mapping(address => mapping(Enums.Action => SafetyState)) safetyState;
    /// @notice The recipient of protocol fees.
    address feeRecipient;
    /* -------------------------------------------------------------------------- */
    /*                             Oracle & Sequencer                             */
    /* -------------------------------------------------------------------------- */
    /// @notice Pyth endpoint
    address pythEp;
    /// @notice L2 sequencer feed address
    address sequencerUptimeFeed;
    /// @notice grace period of sequencer in seconds
    uint32 sequencerGracePeriodTime;
    /// @notice The max deviation percentage between primary and secondary price.
    uint16 maxPriceDeviationPct;
    /// @notice Offchain oracle decimals
    uint8 oracleDecimals;
    /// @notice Flag tells if there is a need to perform safety checks on user actions
    bool safetyStateSet;
    /* -------------------------------------------------------------------------- */
    /*                                 Reentrancy                                 */
    /* -------------------------------------------------------------------------- */
    uint256 entered;
    /* -------------------------------------------------------------------------- */
    /*                               Access Control                               */
    /* -------------------------------------------------------------------------- */
    mapping(bytes32 role => RoleData data) _roles;
    mapping(bytes32 role => EnumerableSet.AddressSet member) _roleMembers;
    /* -------------------------------------------------------------------------- */
    /*                                Market Status Provider                      */
    /* -------------------------------------------------------------------------- */
    address marketStatusProvider;
}

/* -------------------------------------------------------------------------- */
/*                                   Getter                                   */
/* -------------------------------------------------------------------------- */

// Storage position
bytes32 constant COMMON_STORAGE_POSITION = keccak256("kresko.common.storage");

// Gating
bytes32 constant GATING_MANAGER_POSITION = keccak256("kresko.gating.storage");
struct GatingState {
    IGatingManager manager;
}

function gm() pure returns (GatingState storage state) {
    bytes32 position = GATING_MANAGER_POSITION;
    assembly {
        state.slot := position
    }
}

function cs() pure returns (CommonState storage state) {
    bytes32 position = bytes32(COMMON_STORAGE_POSITION);
    assembly {
        state.slot := position
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Assets} from "common/funcs/Assets.sol";
import {Enums} from "common/Constants.sol";

using Assets for Asset global;

/* ========================================================================== */
/*                                   Structs                                  */
/* ========================================================================== */

/// @notice Oracle configuration mapped to `Asset.ticker`.
struct Oracle {
    address feed;
    bytes32 pythId;
    uint256 staleTime;
    bool invertPyth;
    bool isClosable;
}

/**
 * @notice Feed configuration.
 * @param oracleIds List of two supported oracle providers.
 * @param feeds List of two feed addresses matching to the providers supplied. Redstone will be address(0).
 * @param staleTimes List of two stale times for the feeds.
 * @param pythId Pyth asset ID.
 * @param invertPyth Invert the Pyth price.
 * @param isClosable Is the market for the ticker closable.
 */
struct FeedConfiguration {
    Enums.OracleType[2] oracleIds;
    address[2] feeds;
    uint256[2] staleTimes;
    bytes32 pythId;
    bool invertPyth;
    bool isClosable;
}

/**
 * @title Protocol Asset Configuration
 * @author Kresko
 * @notice All assets in the protocol share this configuration.
 * @notice ticker is not unique, eg. krETH and WETH both would use bytes32('ETH')
 * @dev Percentages use 2 decimals: 1e4 (10000) == 100.00%. See {PercentageMath.sol}.
 * @dev Note that the percentage value for uint16 caps at 655.36%.
 */
struct Asset {
    /// @notice Reference asset ticker (matching what Redstone uses, eg. bytes32('ETH')).
    /// @notice NOT unique per asset.
    bytes32 ticker;
    /// @notice Kresko Asset Anchor address.
    address anchor;
    /// @notice Oracle provider priority for this asset.
    /// @notice Provider at index 0 is the primary price source.
    /// @notice Provider at index 1 is the reference price for deviation check and also the fallback price.
    Enums.OracleType[2] oracles;
    /// @notice Percentage multiplier which decreases collateral asset valuation (if < 100%), mitigating price risk.
    /// @notice Always <= 100% or 1e4.
    uint16 factor;
    /// @notice Percentage multiplier which increases debt asset valution (if > 100%), mitigating price risk.
    /// @notice Always >= 100% or 1e4.
    uint16 kFactor;
    /// @notice Minter fee percent for opening a debt position.
    /// @notice Fee is deducted from collaterals.
    uint16 openFee;
    /// @notice Minter fee percent for closing a debt position.
    /// @notice Fee is deducted from collaterals.
    uint16 closeFee;
    /// @notice Minter liquidation incentive when asset is the seized collateral in a liquidation.
    uint16 liqIncentive;
    /// @notice Supply limit for Kresko Assets.
    uint256 maxDebtMinter;
    /// @notice Supply limit for Kresko Assets mints in SCDP.
    uint256 maxDebtSCDP;
    /// @notice SCDP deposit limit for the asset.
    uint256 depositLimitSCDP;
    /// @notice SCDP fee percent when swapped as "asset in".
    uint16 swapInFeeSCDP;
    /// @notice SCDP fee percent when swapped as "asset out".
    uint16 swapOutFeeSCDP;
    /// @notice SCDP protocol cut of the swap fees. Cap 50% == a.feeShare + b.feeShare <= 100%.
    uint16 protocolFeeShareSCDP;
    /// @notice SCDP liquidation incentive, defined for Kresko Assets.
    /// @notice Applied as discount for seized collateral when the KrAsset is repaid in a liquidation.
    uint16 liqIncentiveSCDP;
    /// @notice ERC20 decimals of the asset, queried and saved once during setup.
    /// @notice Kresko Assets have 18 decimals.
    uint8 decimals;
    /// @notice Asset can be deposited as collateral in the Minter.
    bool isMinterCollateral;
    /// @notice Asset can be minted as debt from the Minter.
    bool isMinterMintable;
    /// @notice Asset can be deposited by users as collateral in the SCDP.
    bool isSharedCollateral;
    /// @notice Asset can be minted through swaps in the SCDP.
    bool isSwapMintable;
    /// @notice Asset is included in the total collateral value calculation for the SCDP.
    /// @notice KrAssets will be true by default - since they are indirectly deposited through swaps.
    bool isSharedOrSwappedCollateral;
    /// @notice Asset can be used to cover SCDP debt.
    bool isCoverAsset;
}

/// @notice The access control role data.
struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
}

/// @notice Variables used for calculating the max liquidation value.
struct MaxLiqVars {
    Asset collateral;
    uint256 accountCollateralValue;
    uint256 minCollateralValue;
    uint256 seizeCollateralAccountValue;
    uint192 minDebtValue;
    uint32 gainFactor;
    uint32 maxLiquidationRatio;
    uint32 debtFactor;
}

struct MaxLiqInfo {
    address account;
    address seizeAssetAddr;
    address repayAssetAddr;
    uint256 repayValue;
    uint256 repayAmount;
    uint256 seizeAmount;
    uint256 seizeValue;
    uint256 repayAssetPrice;
    uint256 repayAssetIndex;
    uint256 seizeAssetPrice;
    uint256 seizeAssetIndex;
}

/// @notice Convenience struct for checking configurations
struct RawPrice {
    int256 answer;
    uint256 timestamp;
    uint256 staleTime;
    bool isStale;
    bool isZero;
    Enums.OracleType oracle;
    address feed;
}

/// @notice Configuration for pausing `Action`
struct Pause {
    bool enabled;
    uint256 timestamp0;
    uint256 timestamp1;
}

/// @notice Safety configuration for assets
struct SafetyState {
    Pause pause;
}

/**
 * @notice Initialization arguments for common values
 */
struct CommonInitArgs {
    address admin;
    address council;
    address treasury;
    uint16 maxPriceDeviationPct;
    uint8 oracleDecimals;
    uint32 sequencerGracePeriodTime;
    address sequencerUptimeFeed;
    address gatingManager;
    address pythEp;
    address marketStatusProvider;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {ds} from "diamond/DState.sol";
import {Errors} from "common/Errors.sol";
import {Auth} from "common/Auth.sol";
import {Role, Constants, Enums} from "common/Constants.sol";
import {Asset} from "common/Types.sol";
import {cs, gm, CommonState} from "common/State.sol";
import {WadRay} from "libs/WadRay.sol";
import {scdp} from "scdp/SState.sol";
import {IPyth} from "vendor/pyth/IPyth.sol";
import {handlePythUpdate} from "common/funcs/Utils.sol";

library LibModifiers {
    /// @dev Simple check for the enabled flag
    /// @param _assetAddr The address of the asset.
    /// @param _action The action to this is called from.
    /// @return asset The asset struct.
    function onlyUnpaused(
        CommonState storage self,
        address _assetAddr,
        Enums.Action _action
    ) internal view returns (Asset storage asset) {
        if (self.safetyStateSet && self.safetyState[_assetAddr][_action].pause.enabled) {
            revert Errors.ASSET_PAUSED_FOR_THIS_ACTION(Errors.id(_assetAddr), uint8(_action));
        }
        return self.assets[_assetAddr];
    }

    function onlyExistingAsset(CommonState storage self, address _assetAddr) internal view returns (Asset storage asset) {
        asset = self.assets[_assetAddr];
        if (!asset.exists()) {
            revert Errors.ASSET_DOES_NOT_EXIST(Errors.id(_assetAddr));
        }
    }

    /**
     * @notice Reverts if address is not a minter collateral asset.
     * @param _assetAddr The address of the asset.
     * @return asset The asset struct.
     */
    function onlyMinterCollateral(CommonState storage self, address _assetAddr) internal view returns (Asset storage asset) {
        asset = self.assets[_assetAddr];
        if (!asset.isMinterCollateral) {
            revert Errors.ASSET_NOT_MINTER_COLLATERAL(Errors.id(_assetAddr));
        }
    }

    function onlyMinterCollateral(
        CommonState storage self,
        address _assetAddr,
        Enums.Action _action
    ) internal view returns (Asset storage asset) {
        asset = onlyUnpaused(self, _assetAddr, _action);
        if (!asset.isMinterCollateral) {
            revert Errors.ASSET_NOT_MINTER_COLLATERAL(Errors.id(_assetAddr));
        }
    }

    /**
     * @notice Reverts if address is not a Kresko Asset.
     * @param _assetAddr The address of the asset.
     * @return asset The asset struct.
     */
    function onlyMinterMintable(CommonState storage self, address _assetAddr) internal view returns (Asset storage asset) {
        asset = self.assets[_assetAddr];
        if (!asset.isMinterMintable) {
            revert Errors.ASSET_NOT_MINTABLE_FROM_MINTER(Errors.id(_assetAddr));
        }
    }

    function onlyMinterMintable(
        CommonState storage self,
        address _assetAddr,
        Enums.Action _action
    ) internal view returns (Asset storage asset) {
        asset = onlyUnpaused(self, _assetAddr, _action);
        if (!asset.isMinterMintable) {
            revert Errors.ASSET_NOT_MINTABLE_FROM_MINTER(Errors.id(_assetAddr));
        }
    }

    /**
     * @notice Reverts if address is not depositable to SCDP.
     * @param _assetAddr The address of the asset.
     * @return asset The asset struct.
     */
    function onlySharedCollateral(CommonState storage self, address _assetAddr) internal view returns (Asset storage asset) {
        asset = self.assets[_assetAddr];
        if (!asset.isSharedCollateral) {
            revert Errors.ASSET_NOT_SHARED_COLLATERAL(Errors.id(_assetAddr));
        }
    }

    /**
     * @notice Reverts if asset is not the feeAsset and does not have any shared fees accumulated.
     * @notice Assets that pass this are guaranteed to never have a zero liquidity index.
     * @param _assetAddr The address of the asset.
     * @return asset The asset struct.
     */
    function onlyFeeAccumulatingCollateral(
        CommonState storage self,
        address _assetAddr
    ) internal view returns (Asset storage asset) {
        asset = self.assets[_assetAddr];
        if (
            !asset.isSharedCollateral ||
            (_assetAddr != scdp().feeAsset && scdp().assetIndexes[_assetAddr].currFeeIndex <= WadRay.RAY)
        ) {
            revert Errors.ASSET_NOT_FEE_ACCUMULATING_ASSET(Errors.id(_assetAddr));
        }
    }

    function onlyFeeAccumulatingCollateral(
        CommonState storage self,
        address _assetAddr,
        Enums.Action _action
    ) internal view returns (Asset storage asset) {
        asset = onlyUnpaused(self, _assetAddr, _action);
        if (
            !asset.isSharedCollateral ||
            (_assetAddr != scdp().feeAsset && scdp().assetIndexes[_assetAddr].currFeeIndex <= WadRay.RAY)
        ) {
            revert Errors.ASSET_NOT_FEE_ACCUMULATING_ASSET(Errors.id(_assetAddr));
        }
    }

    /**
     * @notice Reverts if address is not swappable Kresko Asset.
     * @param _assetAddr The address of the asset.
     * @return asset The asset struct.
     */
    function onlySwapMintable(CommonState storage self, address _assetAddr) internal view returns (Asset storage asset) {
        asset = self.assets[_assetAddr];
        if (!asset.isSwapMintable) {
            revert Errors.ASSET_NOT_SWAPPABLE(Errors.id(_assetAddr));
        }
    }

    function onlySwapMintable(
        CommonState storage self,
        address _assetAddr,
        Enums.Action _action
    ) internal view returns (Asset storage asset) {
        asset = onlyUnpaused(self, _assetAddr, _action);
        if (!asset.isSwapMintable) {
            revert Errors.ASSET_NOT_SWAPPABLE(Errors.id(_assetAddr));
        }
    }

    /**
     * @notice Reverts if address does not have any deposits.
     * @param _assetAddr The address of the asset.
     * @return asset The asset struct.
     * @dev This is used to check if an asset has any deposits before removing it.
     */
    function onlyActiveSharedCollateral(
        CommonState storage self,
        address _assetAddr
    ) internal view returns (Asset storage asset) {
        asset = self.assets[_assetAddr];
        if (scdp().assetIndexes[_assetAddr].currFeeIndex == 0) {
            revert Errors.ASSET_DOES_NOT_HAVE_DEPOSITS(Errors.id(_assetAddr));
        }
    }

    function onlyActiveSharedCollateral(
        CommonState storage self,
        address _assetAddr,
        Enums.Action _action
    ) internal view returns (Asset storage asset) {
        asset = onlyUnpaused(self, _assetAddr, _action);
        if (scdp().assetIndexes[_assetAddr].currFeeIndex == 0) {
            revert Errors.ASSET_DOES_NOT_HAVE_DEPOSITS(Errors.id(_assetAddr));
        }
    }

    function onlyCoverAsset(CommonState storage self, address _assetAddr) internal view returns (Asset storage asset) {
        asset = self.assets[_assetAddr];
        if (!asset.isCoverAsset) {
            revert Errors.ASSET_CANNOT_BE_USED_TO_COVER(Errors.id(_assetAddr));
        }
    }

    function onlyCoverAsset(
        CommonState storage self,
        address _assetAddr,
        Enums.Action _action
    ) internal view returns (Asset storage asset) {
        asset = onlyUnpaused(self, _assetAddr, _action);
        if (!asset.isCoverAsset) {
            revert Errors.ASSET_CANNOT_BE_USED_TO_COVER(Errors.id(_assetAddr));
        }
    }

    function onlyIncomeAsset(CommonState storage self, address _assetAddr) internal view returns (Asset storage asset) {
        if (_assetAddr != scdp().feeAsset) revert Errors.NOT_SUPPORTED_YET();
        asset = onlyActiveSharedCollateral(self, _assetAddr);
        if (!asset.isSharedCollateral) revert Errors.ASSET_NOT_FEE_ACCUMULATING_ASSET(Errors.id(_assetAddr));
    }
}

contract Modifiers {
    /**
     * @dev Modifier that checks if the contract is initializing and if so, gives the caller the ADMIN role
     */
    modifier initializeAsAdmin() {
        if (ds().initializing != Constants.INITIALIZING) revert Errors.NOT_INITIALIZING();
        if (!Auth.hasRole(Role.ADMIN, msg.sender)) {
            Auth._grantRole(Role.ADMIN, msg.sender);
            _;
            Auth._revokeRole(Role.ADMIN, msg.sender);
        } else {
            _;
        }
    }
    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        Auth.checkRole(role);
        _;
    }

    /**
     * @notice Check for role if the condition is true.
     * @param _shouldCheckRole Should be checking the role.
     */
    modifier onlyRoleIf(bool _shouldCheckRole, bytes32 role) {
        if (_shouldCheckRole) {
            Auth.checkRole(role);
        }
        _;
    }

    modifier nonReentrant() {
        if (cs().entered == Constants.ENTERED) {
            revert Errors.CANNOT_RE_ENTER();
        }
        cs().entered = Constants.ENTERED;
        _;
        cs().entered = Constants.NOT_ENTERED;
    }

    /// @notice Reverts if the caller does not have the required NFT's for the gated phase
    modifier gate(address _account) {
        if (address(gm().manager) != address(0)) {
            gm().manager.check(_account);
        }
        _;
    }

    modifier usePyth(bytes[] calldata _updateData) {
        handlePythUpdate(_updateData);
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

interface IErrorFieldProvider {
    function symbol() external view returns (string memory);
}

/* solhint-disable max-line-length */
library Errors {
    struct ID {
        string symbol;
        address addr;
    }

    function id(address _addr) internal view returns (ID memory) {
        if (_addr.code.length > 0) return ID(IErrorFieldProvider(_addr).symbol(), _addr);
        return ID("", _addr); // not a token
    }

    function symbol(address _addr) internal view returns (string memory symbol_) {
        if (_addr.code.length > 0) return IErrorFieldProvider(_addr).symbol();
    }

    error ADDRESS_HAS_NO_CODE(address);
    error NOT_INITIALIZING();
    error TO_WAD_AMOUNT_IS_NEGATIVE(int256);
    error COMMON_ALREADY_INITIALIZED();
    error MINTER_ALREADY_INITIALIZED();
    error SCDP_ALREADY_INITIALIZED();
    error STRING_HEX_LENGTH_INSUFFICIENT();
    error SAFETY_COUNCIL_NOT_ALLOWED();
    error SAFETY_COUNCIL_SETTER_IS_NOT_ITS_OWNER(address);
    error SAFETY_COUNCIL_ALREADY_EXISTS(address given, address existing);
    error MULTISIG_NOT_ENOUGH_OWNERS(address, uint256 owners, uint256 required);
    error ACCESS_CONTROL_NOT_SELF(address who, address self);
    error MARKET_CLOSED(ID, string);
    error SCDP_ASSET_ECONOMY(ID, uint256 seizeReductionPct, ID, uint256 repayIncreasePct);
    error MINTER_ASSET_ECONOMY(ID, uint256 seizeReductionPct, ID, uint256 repayIncreasePct);
    error INVALID_TICKER(ID, string ticker);
    error PYTH_EP_ZERO();
    error ASSET_NOT_ENABLED(ID);
    error ASSET_SET_FEEDS_FAILED(ID);
    error ASSET_CANNOT_BE_USED_TO_COVER(ID);
    error ASSET_PAUSED_FOR_THIS_ACTION(ID, uint8 action);
    error ASSET_NOT_MINTER_COLLATERAL(ID);
    error ASSET_NOT_FEE_ACCUMULATING_ASSET(ID);
    error ASSET_NOT_SHARED_COLLATERAL(ID);
    error ASSET_NOT_MINTABLE_FROM_MINTER(ID);
    error ASSET_NOT_SWAPPABLE(ID);
    error ASSET_DOES_NOT_HAVE_DEPOSITS(ID);
    error ASSET_CANNOT_BE_FEE_ASSET(ID);
    error ASSET_NOT_VALID_DEPOSIT_ASSET(ID);
    error ASSET_ALREADY_ENABLED(ID);
    error ASSET_ALREADY_DISABLED(ID);
    error ASSET_DOES_NOT_EXIST(ID);
    error ASSET_ALREADY_EXISTS(ID);
    error ASSET_IS_VOID(ID);
    error INVALID_ASSET(ID);
    error CANNOT_REMOVE_COLLATERAL_THAT_HAS_USER_DEPOSITS(ID);
    error CANNOT_REMOVE_SWAPPABLE_ASSET_THAT_HAS_DEBT(ID);
    error INVALID_CONTRACT_KRASSET(ID krAsset);
    error INVALID_CONTRACT_KRASSET_ANCHOR(ID anchor, ID krAsset);
    error NOT_SWAPPABLE_KRASSET(ID);
    error IDENTICAL_ASSETS(ID);
    error WITHDRAW_NOT_SUPPORTED();
    error MINT_NOT_SUPPORTED();
    error DEPOSIT_NOT_SUPPORTED();
    error REDEEM_NOT_SUPPORTED();
    error NATIVE_TOKEN_DISABLED(ID);
    error EXCEEDS_ASSET_DEPOSIT_LIMIT(ID, uint256 deposits, uint256 limit);
    error EXCEEDS_ASSET_MINTING_LIMIT(ID, uint256 deposits, uint256 limit);
    error UINT128_OVERFLOW(ID, uint256 deposits, uint256 limit);
    error INVALID_SENDER(address, address);
    error INVALID_MIN_DEBT(uint256 invalid, uint256 valid);
    error INVALID_SCDP_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_MCR(uint256 invalid, uint256 valid);
    error MLR_CANNOT_BE_LESS_THAN_LIQ_THRESHOLD(uint256 mlt, uint256 lt);
    error INVALID_LIQ_THRESHOLD(uint256 lt, uint256 min, uint256 max);
    error INVALID_PROTOCOL_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_ASSET_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_ORACLE_DEVIATION(uint256 invalid, uint256 valid);
    error INVALID_ORACLE_TYPE(uint8 invalid);
    error INVALID_FEE_RECIPIENT(address invalid);
    error INVALID_LIQ_INCENTIVE(ID, uint256 invalid, uint256 min, uint256 max);
    error INVALID_KFACTOR(ID, uint256 invalid, uint256 valid);
    error INVALID_CFACTOR(ID, uint256 invalid, uint256 valid);
    error INVALID_MINTER_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_PRICE_PRECISION(uint256 decimals, uint256 valid);
    error INVALID_COVER_THRESHOLD(uint256 threshold, uint256 max);
    error INVALID_COVER_INCENTIVE(uint256 incentive, uint256 min, uint256 max);
    error INVALID_DECIMALS(ID, uint256 decimals);
    error INVALID_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_FEE_TYPE(uint8 invalid, uint8 valid);
    error INVALID_VAULT_PRICE(string ticker, address);
    error INVALID_API3_PRICE(string ticker, address);
    error INVALID_CL_PRICE(string ticker, address);
    error INVALID_PRICE(ID, address oracle, int256 price);
    error INVALID_KRASSET_OPERATOR(ID, address invalidOperator, address validOperator);
    error INVALID_DENOMINATOR(ID, uint256 denominator, uint256 valid);
    error INVALID_OPERATOR(ID, address who, address valid);
    error INVALID_SUPPLY_LIMIT(ID, uint256 invalid, uint256 valid);
    error NEGATIVE_PRICE(address asset, int256 price);
    error INVALID_PYTH_PRICE(bytes32 id, uint256 price);
    error STALE_PRICE(string ticker, uint256 price, uint256 timeFromUpdate, uint256 threshold);
    error STALE_PUSH_PRICE(
        ID asset,
        string ticker,
        int256 price,
        uint8 oracleType,
        address feed,
        uint256 timeFromUpdate,
        uint256 threshold
    );
    error PRICE_UNSTABLE(uint256 primaryPrice, uint256 referencePrice, uint256 deviationPct);
    error ZERO_OR_STALE_VAULT_PRICE(ID, address, uint256);
    error ZERO_OR_STALE_PRICE(string ticker, uint8[2] oracles);
    error STALE_ORACLE(uint8 oracleType, address feed, uint256 time, uint256 staleTime);
    error ZERO_OR_NEGATIVE_PUSH_PRICE(ID asset, string ticker, int256 price, uint8 oracleType, address feed);
    error UNSUPPORTED_ORACLE(string ticker, uint8 oracle);
    error NO_PUSH_ORACLE_SET(string ticker);
    error NO_VIEW_PRICE_AVAILABLE(string ticker);
    error NOT_SUPPORTED_YET();
    error WRAP_NOT_SUPPORTED();
    error BURN_AMOUNT_OVERFLOW(ID, uint256 burnAmount, uint256 debtAmount);
    error PAUSED(address who);
    error L2_SEQUENCER_DOWN();
    error FEED_ZERO_ADDRESS(string ticker);
    error INVALID_SEQUENCER_UPTIME_FEED(address);
    error NO_MINTED_ASSETS(address who);
    error NO_COLLATERALS_DEPOSITED(address who);
    error ONLY_WHITELISTED();
    error BLACKLISTED();
    error MISSING_PHASE_3_NFT();
    error MISSING_PHASE_2_NFT();
    error MISSING_PHASE_1_NFT();
    error CANNOT_RE_ENTER();
    error PYTH_ID_ZERO(string ticker);
    error ARRAY_LENGTH_MISMATCH(string ticker, uint256 arr1, uint256 arr2);
    error COLLATERAL_VALUE_GREATER_THAN_REQUIRED(uint256 collateralValue, uint256 minCollateralValue, uint32 ratio);
    error COLLATERAL_VALUE_GREATER_THAN_COVER_THRESHOLD(uint256 collateralValue, uint256 minCollateralValue, uint48 ratio);
    error ACCOUNT_COLLATERAL_VALUE_LESS_THAN_REQUIRED(
        address who,
        uint256 collateralValue,
        uint256 minCollateralValue,
        uint32 ratio
    );
    error COLLATERAL_VALUE_LESS_THAN_REQUIRED(uint256 collateralValue, uint256 minCollateralValue, uint32 ratio);
    error CANNOT_LIQUIDATE_HEALTHY_ACCOUNT(address who, uint256 collateralValue, uint256 minCollateralValue, uint32 ratio);
    error CANNOT_LIQUIDATE_SELF();
    error LIQUIDATION_AMOUNT_GREATER_THAN_DEBT(ID repayAsset, uint256 repayAmount, uint256 availableAmount);
    error LIQUIDATION_SEIZED_LESS_THAN_EXPECTED(ID, uint256, uint256);
    error LIQUIDATION_VALUE_IS_ZERO(ID repayAsset, ID seizeAsset);
    error ACCOUNT_HAS_NO_DEPOSITS(address who, ID);
    error WITHDRAW_AMOUNT_GREATER_THAN_DEPOSITS(address who, ID, uint256 requested, uint256 deposits);
    error ACCOUNT_KRASSET_NOT_FOUND(address account, ID, address[] accountCollaterals);
    error ACCOUNT_COLLATERAL_NOT_FOUND(address account, ID, address[] accountCollaterals);
    error ARRAY_INDEX_OUT_OF_BOUNDS(ID element, uint256 index, address[] elements);
    error ELEMENT_DOES_NOT_MATCH_PROVIDED_INDEX(ID element, uint256 index, address[] elements);
    error NO_FEES_TO_CLAIM(ID asset, address claimer);
    error REPAY_OVERFLOW(ID repayAsset, ID seizeAsset, uint256 invalid, uint256 valid);
    error INCOME_AMOUNT_IS_ZERO(ID incomeAsset);
    error NO_LIQUIDITY_TO_GIVE_INCOME_FOR(ID incomeAsset, uint256 userDeposits, uint256 totalDeposits);
    error NOT_ENOUGH_SWAP_DEPOSITS_TO_SEIZE(ID repayAsset, ID seizeAsset, uint256 invalid, uint256 valid);
    error SWAP_ROUTE_NOT_ENABLED(ID assetIn, ID assetOut);
    error RECEIVED_LESS_THAN_DESIRED(ID, uint256 invalid, uint256 valid);
    error SWAP_ZERO_AMOUNT_IN(ID tokenIn);
    error INVALID_WITHDRAW(ID withdrawAsset, uint256 sharesIn, uint256 assetsOut);
    error ROUNDING_ERROR(ID asset, uint256 sharesIn, uint256 assetsOut);
    error MAX_DEPOSIT_EXCEEDED(ID asset, uint256 assetsIn, uint256 maxDeposit);
    error COLLATERAL_AMOUNT_LOW(ID krAssetCollateral, uint256 amount, uint256 minAmount);
    error MINT_VALUE_LESS_THAN_MIN_DEBT_VALUE(ID, uint256 value, uint256 minRequiredValue);
    error NOT_A_CONTRACT(address who);
    error NO_ALLOWANCE(address spender, address owner, uint256 requested, uint256 allowed);
    error NOT_ENOUGH_BALANCE(address who, uint256 requested, uint256 available);
    error SENDER_NOT_OPERATOR(ID, address sender, address kresko);
    error ZERO_SHARES_FROM_ASSETS(ID, uint256 assets, ID);
    error ZERO_SHARES_OUT(ID, uint256 assets);
    error ZERO_SHARES_IN(ID, uint256 assets);
    error ZERO_ASSETS_FROM_SHARES(ID, uint256 shares, ID);
    error ZERO_ASSETS_OUT(ID, uint256 shares);
    error ZERO_ASSETS_IN(ID, uint256 shares);
    error ZERO_ADDRESS();
    error ZERO_DEPOSIT(ID);
    error ZERO_AMOUNT(ID);
    error ZERO_WITHDRAW(ID);
    error ZERO_MINT(ID);
    error SDI_DEBT_REPAY_OVERFLOW(uint256 debt, uint256 repay);
    error ZERO_REPAY(ID, uint256 repayAmount, uint256 seizeAmount);
    error ZERO_BURN(ID);
    error ZERO_DEBT(ID);
    error UPDATE_FEE_OVERFLOW(uint256 sent, uint256 required);
    error BatchResult(uint256 timestamp, bytes[] results);
    /**
     * @notice Cannot directly rethrow or redeclare panic errors in try/catch - so using a similar error instead.
     * @param code The panic code received.
     */
    error Panicked(uint256 code);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {BurnArgs} from "common/Args.sol";

interface IMinterBurnFacet {
    /**
     * @notice Burns existing Kresko assets.
     * @notice Manager role is required if the caller is not the account being repaid to or the account repaying.
     * @param args Burn arguments
     * @param _updateData Price update data
     */
    function burnKreskoAsset(BurnArgs memory args, bytes[] calldata _updateData) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {MAccounts} from "./funcs/MAccounts.sol";
import {MCore} from "./funcs/MCore.sol";

/* -------------------------------------------------------------------------- */
/*                                   Usings                                   */
/* -------------------------------------------------------------------------- */

using MAccounts for MinterState global;
using MCore for MinterState global;

/**
 * @title Storage layout for the minter state
 * @author Kresko
 */
struct MinterState {
    /* -------------------------------------------------------------------------- */
    /*                              Collateral Assets                             */
    /* -------------------------------------------------------------------------- */
    /// @notice Mapping of account -> collateral asset addresses deposited
    mapping(address => address[]) depositedCollateralAssets;
    /// @notice Mapping of account -> asset -> deposit amount
    mapping(address => mapping(address => uint256)) collateralDeposits;
    /* -------------------------------------------------------------------------- */
    /*                                Kresko Assets                               */
    /* -------------------------------------------------------------------------- */
    /// @notice Mapping of account -> krAsset -> debt amount owed to the protocol
    mapping(address => mapping(address => uint256)) kreskoAssetDebt;
    /// @notice Mapping of account -> addresses of borrowed krAssets
    mapping(address => address[]) mintedKreskoAssets;
    /* --------------------------------- Assets --------------------------------- */
    address[] krAssets;
    address[] collaterals;
    /* -------------------------------------------------------------------------- */
    /*                           Configurable Parameters                          */
    /* -------------------------------------------------------------------------- */

    /// @notice The recipient of protocol fees.
    address feeRecipient;
    /// @notice Max liquidation ratio, this is the max collateral ratio liquidations can liquidate to.
    uint32 maxLiquidationRatio;
    /// @notice The minimum ratio of collateral to debt that can be taken by direct action.
    uint32 minCollateralRatio;
    /// @notice The collateralization ratio at which positions may be liquidated.
    uint32 liquidationThreshold;
    /// @notice The minimum USD value of an individual synthetic asset debt position.
    uint256 minDebtValue;
}

/* -------------------------------------------------------------------------- */
/*                                   Getter                                   */
/* -------------------------------------------------------------------------- */

// Storage position
bytes32 constant MINTER_STORAGE_POSITION = keccak256("kresko.minter.storage");

function ms() pure returns (MinterState storage state) {
    bytes32 position = MINTER_STORAGE_POSITION;
    assembly {
        state.slot := position
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Enums} from "common/Constants.sol";

interface IEventFieldProvider {
    function symbol() external view returns (string memory);
}

library MEvent {
    function symbol(address _addr) internal view returns (string memory symbol_) {
        if (_addr.code.length > 0) return IEventFieldProvider(_addr).symbol();
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Collateral                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when a collateral asset is added to the protocol.
     * @dev Can only be emitted once for a given collateral asset.
     * @param ticker Underlying asset ticker.
     * @param symbol Asset symbol
     * @param collateralAsset The address of the collateral asset.
     * @param factor The collateral factor.
     * @param liqIncentive The liquidation incentive
     */
    event CollateralAssetAdded(
        string indexed ticker,
        string indexed symbol,
        address indexed collateralAsset,
        uint256 factor,
        address anchor,
        uint256 liqIncentive
    );

    /**
     * @notice Emitted when a collateral asset is updated.
     * @param ticker Underlying asset ticker.
     * @param symbol Asset symbol
     * @param collateralAsset The address of the collateral asset.
     * @param factor The collateral factor.
     * @param liqIncentive The liquidation incentive
     */
    event CollateralAssetUpdated(
        string indexed ticker,
        string indexed symbol,
        address indexed collateralAsset,
        uint256 factor,
        address anchor,
        uint256 liqIncentive
    );

    /**
     * @notice Emitted when an account deposits collateral.
     * @param account The address of the account depositing collateral.
     * @param collateralAsset The address of the collateral asset.
     * @param amount The amount of the collateral asset that was deposited.
     */
    event CollateralDeposited(address indexed account, address indexed collateralAsset, uint256 amount);

    /**
     * @notice Emitted when an account withdraws collateral.
     * @param account The address of the account withdrawing collateral.
     * @param collateralAsset The address of the collateral asset.
     * @param amount The amount of the collateral asset that was withdrawn.
     */
    event CollateralWithdrawn(address indexed account, address indexed collateralAsset, uint256 amount);

    /**
     * @notice Emitted when AMM helper withdraws account collateral without MCR checks.
     * @param account The address of the account withdrawing collateral.
     * @param collateralAsset The address of the collateral asset.
     * @param amount The amount of the collateral asset that was withdrawn.
     */
    event UncheckedCollateralWithdrawn(address indexed account, address indexed collateralAsset, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                Kresko Assets                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when a KreskoAsset is added to the protocol.
     * @dev Can only be emitted once for a given Kresko asset.
     * @param ticker Underlying asset ticker.
     * @param symbol Asset symbol
     * @param kreskoAsset The address of the Kresko asset.
     * @param anchor anchor token
     * @param kFactor The k-factor.
     * @param maxDebtMinter The total supply limit.
     * @param closeFee The close fee percentage.
     * @param openFee The open fee percentage.
     */
    event KreskoAssetAdded(
        string indexed ticker,
        string indexed symbol,
        address indexed kreskoAsset,
        address anchor,
        uint256 kFactor,
        uint256 maxDebtMinter,
        uint256 closeFee,
        uint256 openFee
    );

    /**
     * @notice Emitted when a Kresko asset's oracle is updated.
     * @param ticker Underlying asset ticker.
     * @param symbol Asset symbol
     * @param kreskoAsset The address of the Kresko asset.
     * @param kFactor The k-factor.
     * @param maxDebtMinter The total supply limit.
     * @param closeFee The close fee percentage.
     * @param openFee The open fee percentage.
     */
    event KreskoAssetUpdated(
        string indexed ticker,
        string indexed symbol,
        address indexed kreskoAsset,
        address anchor,
        uint256 kFactor,
        uint256 maxDebtMinter,
        uint256 closeFee,
        uint256 openFee
    );

    /**
     * @notice Emitted when an account mints a Kresko asset.
     * @param account The address of the account minting the Kresko asset.
     * @param kreskoAsset The address of the Kresko asset.
     * @param amount The amount of the KreskoAsset that was minted.
     * @param receiver Receiver of the minted assets.
     */
    event KreskoAssetMinted(address indexed account, address indexed kreskoAsset, uint256 amount, address receiver);

    /**
     * @notice Emitted when an account burns a Kresko asset.
     * @param account The address of the account burning the Kresko asset.
     * @param kreskoAsset The address of the Kresko asset.
     * @param amount The amount of the KreskoAsset that was burned.
     */
    event KreskoAssetBurned(address indexed account, address indexed kreskoAsset, uint256 amount);

    /**
     * @notice Emitted when cFactor is updated for a collateral asset.
     * @param symbol Asset symbol
     * @param collateralAsset The address of the collateral asset.
     * @param from Previous value.
     * @param to New value.
     */
    event CFactorUpdated(string indexed symbol, address indexed collateralAsset, uint256 from, uint256 to);
    /**
     * @notice Emitted when kFactor is updated for a KreskoAsset.
     * @param symbol Asset symbol
     * @param kreskoAsset The address of the KreskoAsset.
     * @param from Previous value.
     * @param to New value.
     */
    event KFactorUpdated(string indexed symbol, address indexed kreskoAsset, uint256 from, uint256 to);

    /**
     * @notice Emitted when an account burns a Kresko asset.
     * @param account The address of the account burning the Kresko asset.
     * @param kreskoAsset The address of the Kresko asset.
     * @param amount The amount of the KreskoAsset that was burned.
     */
    event DebtPositionClosed(address indexed account, address indexed kreskoAsset, uint256 amount);

    /**
     * @notice Emitted when an account pays an open/close fee with a collateral asset in the Minter.
     * @dev This can be emitted multiple times for a single asset.
     * @param account Address of the account paying the fee.
     * @param paymentCollateralAsset Address of the collateral asset used to pay the fee.
     * @param feeType Fee type.
     * @param paymentAmount Amount of ollateral asset that was paid.
     * @param paymentValue USD value of the payment.
     */
    event FeePaid(
        address indexed account,
        address indexed paymentCollateralAsset,
        uint256 indexed feeType,
        uint256 paymentAmount,
        uint256 paymentValue,
        uint256 feeValue
    );

    /**
     * @notice Emitted when a liquidation occurs.
     * @param account The address of the account being liquidated.
     * @param liquidator The account performing the liquidation.
     * @param repayKreskoAsset The address of the KreskoAsset being paid back to the protocol by the liquidator.
     * @param repayAmount The amount of the repay KreskoAsset being paid back to the protocol by the liquidator.
     * @param seizedCollateralAsset The address of the collateral asset being seized from the account by the liquidator.
     * @param collateralSent The amount of the seized collateral asset being seized from the account by the liquidator.
     */
    event LiquidationOccurred(
        address indexed account,
        address indexed liquidator,
        address indexed repayKreskoAsset,
        uint256 repayAmount,
        address seizedCollateralAsset,
        uint256 collateralSent
    );

    /* -------------------------------------------------------------------------- */
    /*                                Parameters                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when a safety state is triggered for an asset
     * @param action Target action
     * @param symbol Asset symbol
     * @param asset Asset affected
     * @param description change description
     */
    event SafetyStateChange(Enums.Action indexed action, string indexed symbol, address indexed asset, string description);

    /**
     * @notice Emitted when the fee recipient is updated.
     * @param from The previous value.
     * @param to New value.
     */
    event FeeRecipientUpdated(address from, address to);

    /**
     * @notice Emitted when the liquidation incentive multiplier is updated.
     * @param symbol Asset symbol
     * @param asset The collateral asset being updated.
     * @param from Previous value.
     * @param to New value.
     */
    event LiquidationIncentiveUpdated(string indexed symbol, address indexed asset, uint256 from, uint256 to);

    /**
     * @notice Emitted when the minimum collateralization ratio is updated.
     * @param from Previous value.
     * @param to New value.
     */
    event MinCollateralRatioUpdated(uint256 from, uint256 to);

    /**
     * @notice Emitted when the minimum debt value updated.
     * @param from Previous value.
     * @param to New value.
     */
    event MinimumDebtValueUpdated(uint256 from, uint256 to);

    /**
     * @notice Emitted when the liquidation threshold value is updated
     * @param from Previous value.
     * @param to New value.
     * @param mlr The new max liquidation ratio.
     */
    event LiquidationThresholdUpdated(uint256 from, uint256 to, uint256 mlr);
    /**
     * @notice Emitted when the max liquidation ratio is updated
     * @param from Previous value.
     * @param to New value.
     */
    event MaxLiquidationRatioUpdated(uint256 from, uint256 to);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {IERC20} from "kresko-lib/token/IERC20.sol";
import {SafeTransfer} from "kresko-lib/token/SafeTransfer.sol";
import {Arrays} from "libs/Arrays.sol";
import {WadRay} from "libs/WadRay.sol";
import {PercentageMath} from "libs/PercentageMath.sol";

import {fromWad} from "common/funcs/Math.sol";
import {Enums} from "common/Constants.sol";
import {cs} from "common/State.sol";
import {Asset} from "common/Types.sol";

import {ms} from "minter/MState.sol";
import {MEvent} from "minter/MEvent.sol";

using WadRay for uint256;
using SafeTransfer for IERC20;
using PercentageMath for uint256;
using Arrays for address[];

/* -------------------------------------------------------------------------- */
/*                                    Fees                                    */
/* -------------------------------------------------------------------------- */

/**
 * @notice Charges the protocol open fee based off the value of the minted asset.
 * @dev Takes the fee from the account's collateral assets. Attempts collateral assets
 *   in reverse order of the account's deposited collateral assets array.
 * @param _krAsset Asset struct of the kresko asset being minted.
 * @param _account Account to charge the open fee from.
 * @param _mintAmount Amount of the kresko asset being minted.
 * @param _feeType MinterFee type
 */
function handleMinterFee(Asset storage _krAsset, address _account, uint256 _mintAmount, Enums.MinterFee _feeType) {
    // Calculate the value of the fee according to the value of the krAssets being minted.
    uint256 feeValue = _krAsset.krAssetUSD(_mintAmount).percentMul(
        _feeType == Enums.MinterFee.Open ? _krAsset.openFee : _krAsset.closeFee
    );

    // Do nothing if the fee value is 0.
    if (feeValue == 0) {
        return;
    }

    address[] memory accountCollaterals = ms().depositedCollateralAssets[_account];
    // Iterate backward through the account's deposited collateral assets to safely
    // traverse the array while still being able to remove elements if necessary.
    // This is because removing the last element of the array does not shift around
    // other elements in the array.
    for (uint256 i = accountCollaterals.length - 1; i >= 0; i--) {
        address collateralAddr = accountCollaterals[i];
        Asset storage collateral = cs().assets[collateralAddr];

        (uint256 transferAmount, uint256 feeValuePaid) = _calcFeeAndHandleCollateralRemoval(
            collateral,
            collateralAddr,
            _account,
            feeValue,
            i
        );

        // Remove the transferAmount from the stored deposit for the account.
        ms().collateralDeposits[_account][collateralAddr] -= collateral.toNonRebasingAmount(transferAmount);

        // Transfer the fee to the feeRecipient.
        IERC20(collateralAddr).safeTransfer(cs().feeRecipient, transferAmount);

        emit MEvent.FeePaid(_account, collateralAddr, uint8(_feeType), transferAmount, feeValuePaid, feeValue);
        feeValue = feeValue - feeValuePaid;
        // If the entire fee has been paid, no more action needed.
        if (feeValue == 0) {
            return;
        }
    }
}

/**
 * @notice Calculates the fee to be taken from a user's deposited collateral asset.
 * @param _asset Asset struct of the collateral asset.
 * @param _collateralAsset The collateral asset from which to take to the fee.
 * @param _account The owner of the collateral.
 * @param _feeValue The original value of the fee.
 * @param _collateralAssetIndex The collateral asset's index in the user's depositedCollateralAssets array.
 * @return transferAmount to be received as a uint256
 * @return feeValuePaid wad representing the fee value paid.
 */
function _calcFeeAndHandleCollateralRemoval(
    Asset storage _asset,
    address _collateralAsset,
    address _account,
    uint256 _feeValue,
    uint256 _collateralAssetIndex
) returns (uint256 transferAmount, uint256 feeValuePaid) {
    uint256 depositAmount = ms().accountCollateralAmount(_account, _collateralAsset, _asset);

    // Don't take the collateral asset's collateral factor into consideration.
    (uint256 depositValue, uint256 oraclePrice) = _asset.collateralAmountToValueWithPrice(depositAmount, true);

    if (_feeValue < depositValue) {
        // If feeValue < depositValue, the entire fee can be charged for this collateral asset.
        transferAmount = fromWad(_feeValue.wadDiv(oraclePrice), _asset.decimals);
        feeValuePaid = _feeValue;
    } else {
        // If the feeValue >= depositValue, the entire deposit should be taken as the fee.
        transferAmount = depositAmount;
        feeValuePaid = depositValue;
    }

    if (transferAmount == depositAmount) {
        // Because the entire deposit is taken, remove it from the depositCollateralAssets array.
        ms().depositedCollateralAssets[_account].removeAddress(_collateralAsset, _collateralAssetIndex);
    }

    return (transferAmount, feeValuePaid);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/**
 * @notice External, used when caling liquidate.
 * @param account The account to attempt to liquidate.
 * @param repayAssetAddr Address of the Kresko asset to be repaid.
 * @param repayAmount Amount of the Kresko asset to be repaid.
 * @param seizeAssetAddr Address of the collateral asset to be seized.
 * @param repayAssetIndex Index of the Kresko asset in the user's minted assets array.
 * @param seizeAssetIndex Index of the collateral asset in the account's collateral assets array.
 * @param prices Price update data for pyth.
 */
struct LiquidationArgs {
    address account;
    address repayAssetAddr;
    uint256 repayAmount;
    address seizeAssetAddr;
    uint256 repayAssetIndex;
    uint256 seizeAssetIndex;
    bytes[] prices;
}

/**
 * @notice Args to liquidate the collateral pool.
 * @notice Adjusts everyones deposits if swap deposits do not cover the seized amount.
 * @param repayAsset The asset to repay the debt in.
 * @param repayAmount The amount of the asset to repay the debt with.
 * @param seizeAsset The collateral asset to seize.
 * @param prices Price update data
 */
struct SCDPLiquidationArgs {
    address repayAsset;
    uint256 repayAmount;
    address seizeAsset;
}

/**
 * @notice Repay debt for no fees or slippage.
 * @notice Only uses swap deposits, if none available, reverts.
 * @param repayAsset The asset to repay the debt in.
 * @param repayAmount The amount of the asset to repay the debt with.
 * @param seizeAsset The collateral asset to seize.
 * @param prices Price update data
 */
struct SCDPRepayArgs {
    address repayAsset;
    uint256 repayAmount;
    address seizeAsset;
    bytes[] prices;
}

/**
 * @notice Withdraw collateral for account from the collateral pool.
 * @param _account The account to withdraw from.
 * @param _collateralAsset The collateral asset to withdraw.
 * @param _amount The amount to withdraw.
 * @param _receiver The receiver of assets, if 0 then the receiver is the account.
 */
struct SCDPWithdrawArgs {
    address account;
    address asset;
    uint256 amount;
    address receiver;
}

/**
 * @notice Swap kresko assets with KISS using the shared collateral pool.
 * Uses oracle pricing of _amountIn to determine how much _assetOut to send.
 * @param _account The receiver of amount out.
 * @param _assetIn The asset to pay with.
 * @param _assetOut The asset to receive.
 * @param _amountIn The amount of _assetIn to pay.
 * @param _amountOutMin The minimum amount of _assetOut to receive, this is due to possible oracle price change.
 * @param prices Price update data
 */
struct SwapArgs {
    address receiver;
    address assetIn;
    address assetOut;
    uint256 amountIn;
    uint256 amountOutMin;
    bytes[] prices;
}

/**
 * @notice Args to mint new Kresko assets.
 * @param account The address to mint assets for.
 * @param krAsset The address of the Kresko asset.
 * @param amount The amount of the Kresko asset to be minted.
 * @param receiver Receiver of the minted assets.
 */
struct MintArgs {
    address account;
    address krAsset;
    uint256 amount;
    address receiver;
}

/**
 * @param account The address to burn kresko assets for
 * @param krAsset The address of the Kresko asset.
 * @param amount The amount of the Kresko asset to be burned.
 * @param mintIndex The index of the kresko asset in the user's minted assets array.
 * Only needed if burning all principal debt of a particular collateral asset.
 * @param repayee Account to burn assets from,
 */
struct BurnArgs {
    address account;
    address krAsset;
    uint256 amount;
    uint256 mintIndex;
    address repayee;
}

/**
 * @notice Args to withdraw sender's collateral from the protocol.
 * @dev Requires that the post-withdrawal collateral value does not violate minimum collateral requirement.
 * @param account The address to withdraw assets for.
 * @param asset The address of the collateral asset.
 * @param amount The amount of the collateral asset to withdraw.
 * @param collateralIndex The index of the collateral asset in the sender's deposited collateral
 * @param receiver Receiver of the collateral, if address 0 then the receiver is the account.
 */
struct WithdrawArgs {
    address account;
    address asset;
    uint256 amount;
    uint256 collateralIndex;
    address receiver;
}

/**
 * @notice Withdraws sender's collateral from the protocol before checking minimum collateral ratio.
 * @dev Executes post-withdraw-callback triggering onUncheckedCollateralWithdraw on the caller
 * @dev Requires that the post-withdraw-callback collateral value does not violate minimum collateral requirement.
 * @param account The address to withdraw assets for.
 * @param asset The address of the collateral asset.
 * @param amount The amount of the collateral asset to withdraw.
 * @param collateralIndex The index of the collateral asset in the sender's deposited collateral
 * @param userData Arbitrary data passed in by the withdrawer, to be used by the post-withdraw-callback
 * assets array. Only needed if withdrawing the entire deposit of a particular collateral asset.
 */
struct UncheckedWithdrawArgs {
    address account;
    address asset;
    uint256 amount;
    uint256 collateralIndex;
    bytes userData;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {SCDPAccountIndexes, SCDPAssetData, SCDPAssetIndexes, SCDPSeizeData} from "scdp/STypes.sol";
import {SGlobal} from "scdp/funcs/SGlobal.sol";
import {SDeposits} from "scdp/funcs/SDeposits.sol";
import {SAccounts} from "scdp/funcs/SAccounts.sol";
import {Swap} from "scdp/funcs/SSwap.sol";
import {SDebtIndex} from "scdp/funcs/SDI.sol";
/* -------------------------------------------------------------------------- */
/*                                   Usings                                   */
/* -------------------------------------------------------------------------- */

using SGlobal for SCDPState global;
using SDeposits for SCDPState global;
using SAccounts for SCDPState global;
using Swap for SCDPState global;
using SDebtIndex for SDIState global;

/* -------------------------------------------------------------------------- */
/*                                    State                                   */
/* -------------------------------------------------------------------------- */

/**
 * @title Storage layout for the shared cdp state
 * @author Kresko
 */
struct SCDPState {
    /// @notice Array of assets that are deposit assets and can be swapped
    address[] collaterals;
    /// @notice Array of kresko assets that can be minted and swapped.
    address[] krAssets;
    /// @notice Mapping of asset -> asset -> swap enabled
    mapping(address => mapping(address => bool)) isRoute;
    /// @notice Mapping of asset -> enabled
    mapping(address => bool) isEnabled;
    /// @notice Mapping of asset -> deposit/debt data
    mapping(address => SCDPAssetData) assetData;
    /// @notice Mapping of account -> depositAsset -> deposit amount.
    mapping(address => mapping(address => uint256)) deposits;
    /// @notice Mapping of account -> depositAsset -> principal deposit amount.
    mapping(address => mapping(address => uint256)) depositsPrincipal;
    /// @notice Mapping of depositAsset -> indexes.
    mapping(address => SCDPAssetIndexes) assetIndexes;
    /// @notice Mapping of account -> depositAsset -> indices.
    mapping(address => mapping(address => SCDPAccountIndexes)) accountIndexes;
    /// @notice Mapping of account -> liquidationIndex -> Seize data.
    mapping(address => mapping(uint256 => SCDPSeizeData)) seizeEvents;
    /// @notice The asset to convert fees into
    address feeAsset;
    /// @notice The minimum ratio of collateral to debt that can be taken by direct action.
    uint32 minCollateralRatio;
    /// @notice The collateralization ratio at which positions may be liquidated.
    uint32 liquidationThreshold;
    /// @notice Liquidation Overflow Multiplier, multiplies max liquidatable value.
    uint32 maxLiquidationRatio;
}

struct SDIState {
    uint256 totalDebt;
    uint256 totalCover;
    address coverRecipient;
    /// @notice Threshold after cover can be performed.
    uint48 coverThreshold;
    /// @notice Incentive for covering debt
    uint48 coverIncentive;
    address[] coverAssets;
}

/* -------------------------------------------------------------------------- */
/*                                   Getters                                  */
/* -------------------------------------------------------------------------- */

// Storage position
bytes32 constant SCDP_STORAGE_POSITION = keccak256("kresko.scdp.storage");
bytes32 constant SDI_STORAGE_POSITION = keccak256("kresko.scdp.sdi.storage");

// solhint-disable func-visibility
function scdp() pure returns (SCDPState storage state) {
    bytes32 position = SCDP_STORAGE_POSITION;
    assembly {
        state.slot := position
    }
}

function sdi() pure returns (SDIState storage state) {
    bytes32 position = SDI_STORAGE_POSITION;
    assembly {
        state.slot := position
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

/// @title KreskoAsset issuer interface
/// @author Kresko
/// @notice Contract that allows minting and burning through Kresko.
/// @dev All mintable assets in Kresko must implement this. (enforced through introspection)
interface IKreskoAssetIssuer {
    /**
     * @notice Mints @param _assets of krAssets for @param _to,
     * @notice Mints relative @return _shares of anchor tokens.
     */
    function issue(uint256 _assets, address _to) external returns (uint256 shares);

    /**
     * @notice Burns @param _assets of krAssets from @param _from,
     * @notice Burns relative @return _shares of anchor tokens.
     */
    function destroy(uint256 _assets, address _from) external returns (uint256 shares);

    /**
     * @notice Preview conversion from KrAsset amount: @param assets to matching amount of Anchor tokens: @return shares
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Preview conversion from Anchor token amount: @param shares to matching KrAsset amount: @return assets
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @notice Preview conversion from Anchor token amounts: @param shares to matching amounts of KrAssets: @return assets
     */
    function convertManyToAssets(uint256[] calldata shares) external view returns (uint256[] memory assets);

    /**
     * @notice Preview conversion from KrAsset amounts: @param assets to matching amounts of Anchor tokens: @return shares
     */
    function convertManyToShares(uint256[] calldata assets) external view returns (uint256[] memory shares);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity 0.8.23;
import {Errors} from "common/Errors.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(bytes32 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        if (value != 0) revert Errors.STRING_HEX_LENGTH_INSUFFICIENT();
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC1155} from "common/interfaces/IERC1155.sol";

interface IGatingManager {
    function transferOwnership(address) external;

    function phase() external view returns (uint8);

    function qfkNFTs() external view returns (uint256[] memory);

    function kreskian() external view returns (IERC1155);

    function questForKresk() external view returns (IERC1155);

    function isWhiteListed(address) external view returns (bool);

    function whitelist(address, bool _whitelisted) external;

    function setPhase(uint8) external;

    function isEligible(address) external view returns (bool);

    function check(address) external view;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;
import {IKreskoAssetAnchor} from "kresko-asset/IKreskoAssetAnchor.sol";
import {WadRay} from "libs/WadRay.sol";
import {Errors} from "common/Errors.sol";
import {Constants} from "common/Constants.sol";
import {Asset} from "common/Types.sol";
import {toWad} from "common/funcs/Math.sol";
import {safePrice, SDIPrice} from "common/funcs/Prices.sol";
import {cs} from "common/State.sol";
import {PercentageMath} from "libs/PercentageMath.sol";
import {ms} from "minter/MState.sol";
import {scdp} from "scdp/SState.sol";
import {IERC20} from "kresko-lib/token/IERC20.sol";
import {IKISS} from "kiss/interfaces/IKISS.sol";
import {IMarketStatus} from "common/interfaces/IMarketStatus.sol";

library Assets {
    using WadRay for uint256;
    using PercentageMath for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                Asset Prices                                */
    /* -------------------------------------------------------------------------- */

    function price(Asset storage self) internal view returns (uint256) {
        return safePrice(self.ticker, self.oracles, cs().maxPriceDeviationPct);
    }

    function price(Asset storage self, uint256 maxPriceDeviationPct) internal view returns (uint256) {
        return safePrice(self.ticker, self.oracles, maxPriceDeviationPct);
    }

    /**
     * @notice Get value for @param _assetAmount of @param self in uint256
     */
    function krAssetUSD(Asset storage self, uint256 _amount) internal view returns (uint256) {
        return self.price().wadMul(_amount);
    }

    /**
     * @notice Get value for @param _assetAmount of @param self in uint256
     */
    function assetUSD(Asset storage self, uint256 _amount) internal view returns (uint256) {
        return self.collateralAmountToValue(_amount, true);
    }

    function isMarketOpen(Asset storage self) internal view returns (bool) {
        return IMarketStatus(cs().marketStatusProvider).getTickerStatus(self.ticker);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Conversions                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Ensure repayment value (and amount), clamp to max if necessary.
     * @param _maxRepayValue The max liquidatable USD (uint256).
     * @param _repayAmount The repay amount (uint256).
     * @return repayValue Effective repayment value.
     * @return repayAmount Effective repayment amount.
     */
    function boundRepayValue(
        Asset storage self,
        uint256 _maxRepayValue,
        uint256 _repayAmount
    ) internal view returns (uint256 repayValue, uint256 repayAmount) {
        uint256 assetPrice = self.price();
        repayValue = _repayAmount.wadMul(assetPrice);

        if (repayValue > _maxRepayValue) {
            _repayAmount = _maxRepayValue.wadDiv(assetPrice);
            repayValue = _maxRepayValue;
        }

        return (repayValue, _repayAmount);
    }

    /**
     * @notice Gets the collateral value for a single collateral asset and amount.
     * @param _amount Amount of asset to get the value for.
     * @param _ignoreFactor Should collateral factor be ignored.
     * @return value  Value for `_amount` of the asset.
     */
    function collateralAmountToValue(
        Asset storage self,
        uint256 _amount,
        bool _ignoreFactor
    ) internal view returns (uint256 value) {
        if (_amount == 0) return 0;
        value = toWad(_amount, self.decimals).wadMul(self.price());

        if (!_ignoreFactor) {
            value = value.percentMul(self.factor);
        }
    }

    /**
     * @notice Gets the collateral value for `_amount` and returns the price used.
     * @param _amount Amount of asset
     * @param _ignoreFactor Should collateral factor be ignored.
     * @return value Value for `_amount` of the asset.
     * @return assetPrice Price of the collateral asset.
     */
    function collateralAmountToValueWithPrice(
        Asset storage self,
        uint256 _amount,
        bool _ignoreFactor
    ) internal view returns (uint256 value, uint256 assetPrice) {
        assetPrice = self.price();
        if (_amount == 0) return (0, assetPrice);
        value = toWad(_amount, self.decimals).wadMul(assetPrice);

        if (!_ignoreFactor) {
            value = value.percentMul(self.factor);
        }
    }

    /**
     * @notice Gets the USD value for a single Kresko asset and amount.
     * @param _amount Amount of the Kresko asset to calculate the value for.
     * @param _ignoreKFactor Boolean indicating if the asset's k-factor should be ignored.
     * @return value Value for the provided amount of the Kresko asset.
     */
    function debtAmountToValue(Asset storage self, uint256 _amount, bool _ignoreKFactor) internal view returns (uint256 value) {
        if (_amount == 0) return 0;
        value = self.krAssetUSD(_amount);

        if (!_ignoreKFactor) {
            value = value.percentMul(self.kFactor);
        }
    }

    /**
     * @notice Gets the amount for a single debt asset and value.
     * @param _value Value of the asset to calculate the amount for.
     * @param _ignoreKFactor Boolean indicating if the asset's k-factor should be ignored.
     * @return amount Amount for the provided value of the Kresko asset.
     */
    function debtValueToAmount(Asset storage self, uint256 _value, bool _ignoreKFactor) internal view returns (uint256 amount) {
        if (_value == 0) return 0;

        uint256 assetPrice = self.price();
        if (!_ignoreKFactor) {
            assetPrice = assetPrice.percentMul(self.kFactor);
        }

        return _value.wadDiv(assetPrice);
    }

    /// @notice Preview SDI amount from krAsset amount.
    function debtAmountToSDI(Asset storage asset, uint256 amount, bool ignoreFactors) internal view returns (uint256 shares) {
        return toWad(asset.debtAmountToValue(amount, ignoreFactors), cs().oracleDecimals).wadDiv(SDIPrice());
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Minter Util                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Check that amount does not put the user's debt position below the minimum debt value.
     * @param _asset Asset being burned.
     * @param _burnAmount Debt amount burned.
     * @param _debtAmount Debt amount before burn.
     * @return amount >= minDebtAmount
     */
    function checkDust(Asset storage _asset, uint256 _burnAmount, uint256 _debtAmount) internal view returns (uint256 amount) {
        if (_burnAmount == _debtAmount) return _burnAmount;
        // If the requested burn would put the user's debt position below the minimum
        // debt value, close up to the minimum debt value instead.
        uint256 krAssetValue = _asset.debtAmountToValue(_debtAmount - _burnAmount, true);
        uint256 minDebtValue = ms().minDebtValue;
        if (krAssetValue > 0 && krAssetValue < minDebtValue) {
            uint256 minDebtAmount = minDebtValue.wadDiv(_asset.price());
            amount = _debtAmount - minDebtAmount;
        } else {
            amount = _burnAmount;
        }
    }

    /**
     * @notice Checks min debt value against some amount.
     * @param _asset The asset (Asset).
     * @param _krAsset The kresko asset address.
     * @param _debtAmount The debt amount (uint256).
     */
    function ensureMinDebtValue(Asset storage _asset, address _krAsset, uint256 _debtAmount) internal view {
        uint256 positionValue = _asset.krAssetUSD(_debtAmount);
        uint256 minDebtValue = ms().minDebtValue;
        if (positionValue < minDebtValue)
            revert Errors.MINT_VALUE_LESS_THAN_MIN_DEBT_VALUE(Errors.id(_krAsset), positionValue, minDebtValue);
    }

    /**
     * @notice Get the minimum collateral value required to
     * back a Kresko asset amount at a given collateralization ratio.
     * @param _krAsset Address of the Kresko asset.
     * @param _amount Kresko Asset debt amount.
     * @param _ratio Collateralization ratio for the minimum collateral value.
     * @return minCollateralValue Minimum collateral value required for `_amount` of the Kresko Asset.
     */
    function minCollateralValueAtRatio(
        Asset storage _krAsset,
        uint256 _amount,
        uint32 _ratio
    ) internal view returns (uint256 minCollateralValue) {
        if (_amount == 0) return 0;
        // Calculate the collateral value required to back this Kresko asset amount at the given ratio
        return _krAsset.debtAmountToValue(_amount, false).percentMul(_ratio);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Utils                                   */
    /* -------------------------------------------------------------------------- */
    function exists(Asset storage self) internal view returns (bool) {
        return self.ticker != Constants.ZERO_BYTES32;
    }

    function isVoid(Asset storage self) internal view returns (bool) {
        return
            self.ticker != Constants.ZERO_BYTES32 &&
            !self.isMinterCollateral &&
            !self.isMinterMintable &&
            !self.isSharedCollateral &&
            !self.isSwapMintable;
    }

    /**
     * @notice EDGE CASE: If the collateral asset is also a kresko asset, ensure that the deposit amount is above the minimum.
     * @dev This is done because kresko assets can be rebased.
     */
    function ensureMinKrAssetCollateral(Asset storage self, address _self, uint256 _newCollateralAmount) internal view {
        if (_newCollateralAmount > Constants.MIN_KRASSET_COLLATERAL_AMOUNT || _newCollateralAmount == 0) return;
        if (self.anchor == address(0)) return;
        revert Errors.COLLATERAL_AMOUNT_LOW(Errors.id(_self), _newCollateralAmount, Constants.MIN_KRASSET_COLLATERAL_AMOUNT);
    }

    /**
     * @notice Amount of non rebasing tokens -> amount of rebasing tokens
     * @dev DO use this function when reading values storage.
     * @dev DONT use this function when writing to storage.
     * @param _unrebasedAmount Unrebased amount to convert.
     * @return maybeRebasedAmount Possibly rebased amount of asset
     */
    function toRebasingAmount(Asset storage self, uint256 _unrebasedAmount) internal view returns (uint256 maybeRebasedAmount) {
        if (_unrebasedAmount == 0) return 0;
        if (self.anchor != address(0)) {
            return IKreskoAssetAnchor(self.anchor).convertToAssets(_unrebasedAmount);
        }
        return _unrebasedAmount;
    }

    /**
     * @notice Amount of rebasing tokens -> amount of non rebasing tokens
     * @dev DONT use this function when reading from storage.
     * @dev DO use this function when writing to storage.
     * @param _maybeRebasedAmount Possibly rebased amount of asset.
     * @return maybeUnrebasedAmount Possibly unrebased amount of asset
     */
    function toNonRebasingAmount(
        Asset storage self,
        uint256 _maybeRebasedAmount
    ) internal view returns (uint256 maybeUnrebasedAmount) {
        if (_maybeRebasedAmount == 0) return 0;
        if (self.anchor != address(0)) {
            return IKreskoAssetAnchor(self.anchor).convertToShares(_maybeRebasedAmount);
        }
        return _maybeRebasedAmount;
    }

    /**
     * @notice Validate that the minter debt limit is not exceeded.
     * @param _asset Asset struct of the asset being minted.
     * @param _krAsset Address of the kresko asset being minted.
     * @param _mintAmount Amount of the kresko asset being minted.
     * @dev Reverts if the minter debt limit is exceeded.
     */
    function validateMinterDebtLimit(Asset storage _asset, address _krAsset, uint256 _mintAmount) internal view {
        uint256 supply = getMinterSupply(_asset, _krAsset);
        uint256 newSupply = supply + _mintAmount;
        if (newSupply > _asset.maxDebtMinter) {
            revert Errors.EXCEEDS_ASSET_MINTING_LIMIT(Errors.id(_krAsset), newSupply, _asset.maxDebtMinter);
        }
    }

    /**
     * @notice Get the minter supply for a given kresko asset.
     * @param _asset Asset struct of the asset being minted.
     * @param _krAsset Address of the kresko asset being minted.
     * @return minterSupply Minter supply for the kresko asset.
     */
    function getMinterSupply(Asset storage _asset, address _krAsset) internal view returns (uint256) {
        if (_asset.anchor == _krAsset) {
            return _getMinterSupplyKiss(_krAsset);
        }
        return _getMinterSupplyKrAsset(_krAsset, _asset.anchor);
    }

    function _getMinterSupplyKrAsset(address _assetAddr, address _anchor) private view returns (uint256) {
        IKreskoAssetAnchor anchor = IKreskoAssetAnchor(_anchor);
        uint256 supply = anchor.totalSupply() - anchor.balanceOf(_assetAddr) - scdp().assetData[_assetAddr].debt;
        if (supply == 0) return 0;
        return anchor.convertToAssets(supply);
    }

    function _getMinterSupplyKiss(address _assetAddr) private view returns (uint256) {
        return
            IERC20(_assetAddr).totalSupply() -
            (IERC20(IKISS(_assetAddr).vKISS()).balanceOf(_assetAddr) + scdp().assetData[_assetAddr].debt);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {FacetAddressAndPosition, FacetFunctionSelectors} from "diamond/DSTypes.sol";

struct DiamondState {
    /// @notice Maps function selector to the facet address and
    /// the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    /// @notice Maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    /// @notice Facet addresses
    address[] facetAddresses;
    /// @notice ERC165 query implementation
    mapping(bytes4 => bool) supportedInterfaces;
    /// @notice address(this) replacement for FF
    address self;
    /// @notice Diamond initialized
    bool initialized;
    /// @notice Diamond initializing
    uint8 initializing;
    /// @notice Domain field separator
    bytes32 diamondDomainSeparator;
    /// @notice Current owner of the diamond
    address contractOwner;
    /// @notice Pending new diamond owner
    address pendingOwner;
    /// @notice Storage version
    uint96 storageVersion;
}

// Storage position
bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("kresko.diamond.storage");

/**
 * @notice Ds, a pure free function.
 * @return state A DiamondState value.
 * @custom:signature ds()
 * @custom:selector 0x30dce62b
 */
function ds() pure returns (DiamondState storage state) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
        state.slot := position
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {EnumerableSet} from "@oz/utils/structs/EnumerableSet.sol";
import {Strings} from "libs/Strings.sol";
import {Meta} from "libs/Meta.sol";
import {ds} from "diamond/DState.sol";

import {Errors} from "common/Errors.sol";
import {Role} from "common/Constants.sol";
import {cs} from "common/State.sol";

interface IGnosisSafeL2 {
    function isOwner(address owner) external view returns (bool);

    function getOwners() external view returns (address[] memory);
}

/**
 * @title Shared library for access control
 * @author Kresko
 */
library Auth {
    using EnumerableSet for EnumerableSet.AddressSet;
    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /* -------------------------------------------------------------------------- */
    /*                                Functionality                               */
    /* -------------------------------------------------------------------------- */

    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return cs()._roles[role].members[account];
    }

    function getRoleMemberCount(bytes32 role) internal view returns (uint256) {
        return cs()._roleMembers[role].length();
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function checkRole(bytes32 role) internal view {
        _checkRole(role, msg.sender);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
        return cs()._roles[role].adminRole;
    }

    function getRoleMember(bytes32 role, uint256 index) internal view returns (address) {
        return cs()._roleMembers[role].at(index);
    }

    /**
     * @notice setups the security council
     *
     */
    function setupSecurityCouncil(address _councilAddress) internal {
        if (getRoleMemberCount(Role.SAFETY_COUNCIL) != 0)
            revert Errors.SAFETY_COUNCIL_ALREADY_EXISTS(_councilAddress, getRoleMember(Role.SAFETY_COUNCIL, 0));

        cs()._roles[Role.SAFETY_COUNCIL].members[_councilAddress] = true;
        cs()._roleMembers[Role.SAFETY_COUNCIL].add(_councilAddress);

        emit RoleGranted(Role.SAFETY_COUNCIL, _councilAddress, msg.sender);
    }

    function transferSecurityCouncil(address _newCouncil) internal {
        checkRole(Role.SAFETY_COUNCIL);
        uint256 owners = IGnosisSafeL2(_newCouncil).getOwners().length;
        if (owners < 5) revert Errors.MULTISIG_NOT_ENOUGH_OWNERS(_newCouncil, owners, 5);

        cs()._roles[Role.SAFETY_COUNCIL].members[msg.sender] = false;
        cs()._roleMembers[Role.SAFETY_COUNCIL].remove(msg.sender);

        cs()._roles[Role.SAFETY_COUNCIL].members[_newCouncil] = true;
        cs()._roleMembers[Role.SAFETY_COUNCIL].add(_newCouncil);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) internal {
        checkRole(getRoleAdmin(role));
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) internal {
        checkRole(getRoleAdmin(role));
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function _renounceRole(bytes32 role, address account) internal {
        if (account != msg.sender) revert Errors.ACCESS_CONTROL_NOT_SELF(account, msg.sender);

        _revokeRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        cs()._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * @notice Cannot grant the role `SAFETY_COUNCIL` - must be done via explicit function.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal ensureNotSafetyCouncil(role) {
        if (!hasRole(role, account)) {
            cs()._roles[role].members[account] = true;
            cs()._roleMembers[role].add(account);
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            cs()._roles[role].members[account] = false;
            cs()._roleMembers[role].remove(account);
            emit RoleRevoked(role, account, Meta.msgSender());
        }
    }

    /**
     * @dev Ensure we use the explicit `grantSafetyCouncilRole` function.
     */
    modifier ensureNotSafetyCouncil(bytes32 role) {
        if (role == Role.SAFETY_COUNCIL) revert Errors.SAFETY_COUNCIL_NOT_ALLOWED();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRay {
    // HALF_WAD and HALF_RAY expressed with extended notation
    // as constant with operations are not supported in Yul assembly
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    uint128 internal constant RAY128 = 1e27;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings: https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings: https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
                revert(0, 0)
            }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings: https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings: https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
                revert(0, 0)
            }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings: https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
                b := add(b, 1)
            }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings: https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IPyth {
    struct Price {
        int64 price;
        uint64 conf;
        int32 exp;
        uint256 timestamp;
    }

    function getPriceNoOlderThan(bytes32 _id, uint256 _maxAge) external view returns (Price memory);

    function getPriceUnsafe(bytes32 _id) external view returns (Price memory);

    function getUpdateFee(bytes[] memory _updateData) external view returns (uint256);

    function updatePriceFeeds(bytes[] memory _updateData) external payable;

    function updatePriceFeedsIfNecessary(
        bytes[] memory _updateData,
        bytes32[] memory _ids,
        uint64[] memory _publishTimes
    ) external payable;

    // Function arguments are invalid (e.g., the arguments lengths mismatch)
    // Signature: 0xa9cb9e0d
    error InvalidArgument();
    // Update data is coming from an invalid data source.
    // Signature: 0xe60dce71
    error InvalidUpdateDataSource();
    // Update data is invalid (e.g., deserialization error)
    // Signature: 0xe69ffece
    error InvalidUpdateData();
    // Insufficient fee is paid to the method.
    // Signature: 0x025dbdd4
    error InsufficientFee();
    // There is no fresh update, whereas expected fresh updates.
    // Signature: 0xde2c57fa
    error NoFreshUpdate();
    // There is no price feed found within the given range or it does not exists.
    // Signature: 0x45805f5d
    error PriceFeedNotFoundWithinRange();
    // Price feed not found or it is not pushed on-chain yet.
    // Signature: 0x14aebe68
    error PriceFeedNotFound();
    // Requested price is stale.
    // Signature: 0x19abf40e
    error StalePrice();
    // Given message is not a valid Wormhole VAA.
    // Signature: 0x2acbe915
    error InvalidWormholeVaa();
    // Governance message is invalid (e.g., deserialization error).
    // Signature: 0x97363b35
    error InvalidGovernanceMessage();
    // Governance message is not for this contract.
    // Signature: 0x63daeb77
    error InvalidGovernanceTarget();
    // Governance message is coming from an invalid data source.
    // Signature: 0x360f2d87
    error InvalidGovernanceDataSource();
    // Governance message is old.
    // Signature: 0x88d1b847
    error OldGovernanceMessage();
    // The wormhole address to set in SetWormholeAddress governance is invalid.
    // Signature: 0x13d3ed82
    error InvalidWormholeAddressToSet();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {Asset} from "common/Types.sol";
import {PercentageMath} from "libs/PercentageMath.sol";
import {WadRay} from "libs/WadRay.sol";
import {toWad} from "common/funcs/Math.sol";
import {IAggregatorV3} from "kresko-lib/vendor/IAggregatorV3.sol";
import {IPyth} from "vendor/pyth/IPyth.sol";
import {cs} from "common/State.sol";
import {Errors} from "common/Errors.sol";

using PercentageMath for uint256;
using WadRay for uint256;

/// @notice Helper function to get unadjusted, adjusted and price values for collateral assets
function collateralAmountToValues(
    Asset storage self,
    uint256 _amount
) view returns (uint256 value, uint256 valueAdjusted, uint256 price) {
    price = self.price();
    value = toWad(_amount, self.decimals).wadMul(price);
    valueAdjusted = value.percentMul(self.factor);
}

/// @notice Helper function to get unadjusted, adjusted and price values for debt assets
function debtAmountToValues(
    Asset storage self,
    uint256 _amount
) view returns (uint256 value, uint256 valueAdjusted, uint256 price) {
    price = self.price();
    value = _amount.wadMul(price);
    valueAdjusted = value.percentMul(self.kFactor);
}

/**
 * @notice Checks if the L2 sequencer is up.
 * 1 means the sequencer is down, 0 means the sequencer is up.
 * @param _uptimeFeed The address of the uptime feed.
 * @param _gracePeriod The grace period in seconds.
 * @return bool returns true/false if the sequencer is up/not.
 */
function isSequencerUp(address _uptimeFeed, uint256 _gracePeriod) view returns (bool) {
    bool up = true;
    if (_uptimeFeed != address(0)) {
        (, int256 answer, uint256 startedAt, , ) = IAggregatorV3(_uptimeFeed).latestRoundData();

        up = answer == 0;
        if (!up) {
            return false;
        }
        // Make sure the grace period has passed after the
        // sequencer is back up.
        if (block.timestamp - startedAt < _gracePeriod) {
            return false;
        }
    }
    return up;
}

/**
 * If update data exists, updates the prices in the pyth endpoint. Does nothing when data is empty.
 * @param _updateData The update data.
 * @dev Reverts if msg.value does not match the update fee required.
 * @dev Sending empty data + non-zero msg.value should be handled by the caller.
 */
function handlePythUpdate(bytes[] calldata _updateData) {
    if (_updateData.length == 0) {
        return;
    }

    IPyth pythEp = IPyth(cs().pythEp);
    uint256 updateFee = pythEp.getUpdateFee(_updateData);

    if (msg.value > updateFee) {
        revert Errors.UPDATE_FEE_OVERFLOW(msg.value, updateFee);
    }

    pythEp.updatePriceFeeds{value: updateFee}(_updateData);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {WadRay} from "libs/WadRay.sol";
import {PercentageMath} from "libs/PercentageMath.sol";
import {Errors} from "common/Errors.sol";
import {cs} from "common/State.sol";
import {Asset} from "common/Types.sol";
import {MinterState} from "minter/MState.sol";
import {Arrays} from "libs/Arrays.sol";

library MAccounts {
    using WadRay for uint256;
    using PercentageMath for uint256;
    using Arrays for address[];

    /* -------------------------------------------------------------------------- */
    /*                             Account Liquidation                            */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Checks if accounts collateral value is less than required.
     * @notice Reverts if account is not liquidatable.
     * @param _account Account to check.
     */
    function checkAccountLiquidatable(MinterState storage self, address _account) internal view {
        uint256 collateralValue = self.accountTotalCollateralValue(_account);
        uint256 minCollateralValue = self.accountMinCollateralAtRatio(_account, self.liquidationThreshold);
        if (collateralValue >= minCollateralValue) {
            revert Errors.CANNOT_LIQUIDATE_HEALTHY_ACCOUNT(
                _account,
                collateralValue,
                minCollateralValue,
                self.liquidationThreshold
            );
        }
    }

    /**
     * @notice Gets the liquidatable status of an account.
     * @param _account Account to check.
     * @return bool Indicating if the account is liquidatable.
     */
    function isAccountLiquidatable(MinterState storage self, address _account) internal view returns (bool) {
        uint256 collateralValue = self.accountTotalCollateralValue(_account);
        uint256 minCollateralValue = self.accountMinCollateralAtRatio(_account, self.liquidationThreshold);
        return collateralValue < minCollateralValue;
    }

    /**
     * @notice verifies that the account has enough collateral value
     * @param _account The address of the account to verify the collateral for.
     */
    function checkAccountCollateral(MinterState storage self, address _account) internal view {
        uint256 collateralValue = self.accountTotalCollateralValue(_account);
        // Get the account's minimum collateral value.
        uint256 minCollateralValue = self.accountMinCollateralAtRatio(_account, self.minCollateralRatio);

        if (collateralValue < minCollateralValue) {
            revert Errors.ACCOUNT_COLLATERAL_VALUE_LESS_THAN_REQUIRED(
                _account,
                collateralValue,
                minCollateralValue,
                self.minCollateralRatio
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                Account Debt                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Gets the total debt value in USD for an account.
     * @param _account Account to calculate the KreskoAsset value for.
     * @return value Total kresko asset debt value of `_account`.
     */
    function accountTotalDebtValue(MinterState storage self, address _account) internal view returns (uint256 value) {
        address[] memory assets = self.mintedKreskoAssets[_account];
        for (uint256 i; i < assets.length; ) {
            Asset storage asset = cs().assets[assets[i]];
            uint256 debtAmount = self.accountDebtAmount(_account, assets[i], asset);
            unchecked {
                if (debtAmount != 0) {
                    value += asset.debtAmountToValue(debtAmount, false);
                }
                i++;
            }
        }
        return value;
    }

    /**
     * @notice Gets `_account` principal debt amount for `_asset`
     * @dev Principal debt is rebase adjusted due to possible stock splits/reverse splits
     * @param _account Account to get debt amount for.
     * @param _assetAddr Kresko asset address
     * @param _asset Asset truct for the kresko asset.
     * @return debtAmount Amount of debt the `_account` has for `_asset`
     */
    function accountDebtAmount(
        MinterState storage self,
        address _account,
        address _assetAddr,
        Asset storage _asset
    ) internal view returns (uint256 debtAmount) {
        return _asset.toRebasingAmount(self.kreskoAssetDebt[_account][_assetAddr]);
    }

    /**
     * @notice Gets an index for the Kresko asset the account has minted.
     * @param _account Account to get the minted Kresko assets for.
     * @param _krAsset Asset address.
     * @return uint256 Index of the minted asset. Reverts if not found.
     */
    function accountMintIndex(MinterState storage self, address _account, address _krAsset) internal view returns (uint256) {
        Arrays.FindResult memory item = self.mintedKreskoAssets[_account].find(_krAsset);
        if (!item.exists) {
            revert Errors.ACCOUNT_KRASSET_NOT_FOUND(_account, Errors.id(_krAsset), self.mintedKreskoAssets[_account]);
        }
        return item.index;
    }

    /**
     * @notice Gets an array of kresko assets the account has minted.
     * @param _account Account to get the minted kresko assets for.
     * @return mintedAssets Array of addresses of kresko assets the account has minted.
     */
    function accountDebtAssets(
        MinterState storage self,
        address _account
    ) internal view returns (address[] memory mintedAssets) {
        return self.mintedKreskoAssets[_account];
    }

    /**
     * @notice Gets accounts min collateral value required to cover debt at a given collateralization ratio.
     * @notice Account with min collateral value under MCR cannot borrow.
     * @notice Account with min collateral value under LT can be liquidated up to maxLiquidationRatio.
     * @param _account Account to calculate the minimum collateral value for.
     * @param _ratio Collateralization ratio to apply for the minimum collateral value.
     * @return minCollateralValue Minimum collateral value required for the account with `_ratio`.
     */
    function accountMinCollateralAtRatio(
        MinterState storage self,
        address _account,
        uint32 _ratio
    ) internal view returns (uint256 minCollateralValue) {
        return self.accountTotalDebtValue(_account).percentMul(_ratio);
    }

    /* -------------------------------------------------------------------------- */
    /*                             Account Collateral                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Gets the array of collateral assets the account has deposited.
     * @param _account Account to get the deposited collateral assets for.
     * @return depositedAssets Array of deposited collateral assets for `_account`.
     */
    function accountCollateralAssets(
        MinterState storage self,
        address _account
    ) internal view returns (address[] memory depositedAssets) {
        return self.depositedCollateralAssets[_account];
    }

    /**
     * @notice Gets the deposited collateral asset amount for an account
     * @notice Performs rebasing conversion for KreskoAssets
     * @param _account Account to query amount for
     * @param _assetAddress Collateral asset address
     * @param _asset Asset struct of the collateral asset
     * @return uint256 Collateral deposit amount of `_asset` for `_account`
     */
    function accountCollateralAmount(
        MinterState storage self,
        address _account,
        address _assetAddress,
        Asset storage _asset
    ) internal view returns (uint256) {
        return _asset.toRebasingAmount(self.collateralDeposits[_account][_assetAddress]);
    }

    /**
     * @notice Gets the collateral value of a particular account.
     * @param _account Account to calculate the collateral value for.
     * @return totalCollateralValue Collateral value of a particular account.
     */
    function accountTotalCollateralValue(
        MinterState storage self,
        address _account
    ) internal view returns (uint256 totalCollateralValue) {
        address[] memory assets = self.depositedCollateralAssets[_account];
        for (uint256 i; i < assets.length; ) {
            Asset storage asset = cs().assets[assets[i]];
            uint256 collateralAmount = self.accountCollateralAmount(_account, assets[i], asset);
            unchecked {
                if (collateralAmount != 0) {
                    totalCollateralValue += asset.collateralAmountToValue(
                        collateralAmount,
                        false // Take the collateral factor into consideration.
                    );
                }
                i++;
            }
        }

        return totalCollateralValue;
    }

    /**
     * @notice Gets the total collateral deposits value of an account while extracting value for `_collateralAsset`.
     * @param _account Account to calculate the collateral value for.
     * @param _collateralAsset Collateral asset to extract value for.
     * @return totalValue Total collateral value of `_account`
     * @return assetValue Collateral value of `_collateralAsset` for `_account`
     */
    function accountTotalCollateralValue(
        MinterState storage self,
        address _account,
        address _collateralAsset
    ) internal view returns (uint256 totalValue, uint256 assetValue) {
        address[] memory assets = self.depositedCollateralAssets[_account];
        for (uint256 i; i < assets.length; ) {
            Asset storage asset = cs().assets[assets[i]];
            uint256 collateralAmount = self.accountCollateralAmount(_account, assets[i], asset);

            unchecked {
                if (collateralAmount != 0) {
                    uint256 collateralValue = asset.collateralAmountToValue(
                        collateralAmount,
                        false // Take the collateral factor into consideration.
                    );
                    totalValue += collateralValue;
                    if (assets[i] == _collateralAsset) {
                        assetValue = collateralValue;
                    }
                }
                i++;
            }
        }
    }

    /**
     * @notice Gets the deposit index of `_collateralAsset` for `_account`.
     * @param _account Account to get the index for.
     * @param _collateralAsset Collateral asset address.
     * @return uint256 Index of the deposited collateral asset. Reverts if not found.
     */
    function accountDepositIndex(
        MinterState storage self,
        address _account,
        address _collateralAsset
    ) internal view returns (uint256) {
        Arrays.FindResult memory item = self.depositedCollateralAssets[_account].find(_collateralAsset);
        if (!item.exists) {
            revert Errors.ACCOUNT_COLLATERAL_NOT_FOUND(
                _account,
                Errors.id(_collateralAsset),
                self.depositedCollateralAssets[_account]
            );
        }
        return item.index;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {Arrays} from "libs/Arrays.sol";
import {WadRay} from "libs/WadRay.sol";
import {IKreskoAssetIssuer} from "kresko-asset/IKreskoAssetIssuer.sol";

import {Errors} from "common/Errors.sol";
import {Asset} from "common/Types.sol";
import {Validations} from "common/Validations.sol";

import {MEvent} from "minter/MEvent.sol";
import {MinterState} from "minter/MState.sol";

library MCore {
    using Arrays for address[];
    using WadRay for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                Mint And Burn                               */
    /* -------------------------------------------------------------------------- */

    function mint(MinterState storage self, address _krAsset, address _anchor, uint256 _amount, address _account) internal {
        // Increase principal debt
        self.kreskoAssetDebt[_account][_krAsset] += IKreskoAssetIssuer(_anchor).issue(_amount, _account);
    }

    /// @notice Repay user kresko asset debt.
    /// @dev Updates the principal in MinterState
    /// @param _krAsset the asset being repaid
    /// @param _anchor the anchor token of the asset being repaid
    /// @param _burnAmount the asset amount being burned
    /// @param _account the account the debt is subtracted from
    function burn(MinterState storage self, address _krAsset, address _anchor, uint256 _burnAmount, address _account) internal {
        // Decrease the principal debt
        self.kreskoAssetDebt[_account][_krAsset] -= IKreskoAssetIssuer(_anchor).destroy(_burnAmount, msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                             Collateral Actions                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Records account as having deposited an amount of a collateral asset.
     * @dev Token transfers are expected to be done by the caller.
     * @param _asset The asset struct
     * @param _account The address of the collateral asset.
     * @param _collateralAsset The address of the collateral asset.
     * @param _depositAmount The amount of the collateral asset deposited.
     */
    function handleDeposit(
        MinterState storage self,
        Asset storage _asset,
        address _account,
        address _collateralAsset,
        uint256 _depositAmount
    ) internal {
        // Because the depositedCollateralAssets[_account] is pushed to if the existing
        // deposit amount is 0, require the amount to be > 0. Otherwise, the depositedCollateralAssets[_account]
        // could be filled with duplicates, causing collateral to be double-counted in the collateral value.
        if (_depositAmount == 0) revert Errors.ZERO_DEPOSIT(Errors.id(_collateralAsset));

        // If the account does not have an existing deposit for this collateral asset,
        // push it to the list of the account's deposited collateral assets.
        uint256 existingCollateralAmount = self.accountCollateralAmount(_account, _collateralAsset, _asset);

        if (existingCollateralAmount == 0) {
            self.depositedCollateralAssets[_account].push(_collateralAsset);
        }

        unchecked {
            uint256 newCollateralAmount = existingCollateralAmount + _depositAmount;
            _asset.ensureMinKrAssetCollateral(_collateralAsset, newCollateralAmount);
            // Record the deposit.
            self.collateralDeposits[_account][_collateralAsset] = _asset.toNonRebasingAmount(newCollateralAmount);
        }

        emit MEvent.CollateralDeposited(_account, _collateralAsset, _depositAmount);
    }

    /**
     * @notice Verifies that the account has sufficient collateral for the requested amount and records the collateral
     * @param _asset The asset struct
     * @param _account The address of the account to verify the collateral for.
     * @param _collateralAsset The address of the collateral asset.
     * @param _withdrawAmount The amount of the collateral asset to withdraw.
     * @param _collateralDeposits Collateral deposits for the account.
     * @param _collateralIndex Index of the collateral asset in the account's deposited collateral assets array.
     */
    function handleWithdrawal(
        MinterState storage self,
        Asset storage _asset,
        address _account,
        address _collateralAsset,
        uint256 _withdrawAmount,
        uint256 _collateralDeposits,
        uint256 _collateralIndex
    ) internal {
        Validations.validateCollateralArgs(self, _account, _collateralAsset, _collateralIndex, _withdrawAmount);

        uint256 newCollateralAmount = _collateralDeposits - _withdrawAmount;

        // If the collateral asset is also a kresko asset, ensure that the deposit amount is above the minimum.
        // This is done because kresko assets can be rebased.
        _asset.ensureMinKrAssetCollateral(_collateralAsset, newCollateralAmount);

        // If the user is withdrawing all of the collateral asset, remove the collateral asset
        // from the user's deposited collateral assets array.
        if (newCollateralAmount == 0) {
            self.depositedCollateralAssets[_account].removeAddress(_collateralAsset, _collateralIndex);
        }

        // Record the withdrawal.
        self.collateralDeposits[_account][_collateralAsset] = _asset.toNonRebasingAmount(newCollateralAmount);

        // Verify that the account has sufficient collateral value left.
        self.checkAccountCollateral(_account);

        emit MEvent.CollateralWithdrawn(_account, _collateralAsset, _withdrawAmount);
    }

    /**
     * @notice records the collateral withdrawal
     * @param _asset The collateral asset struct.
     * @param _account The address of the account to verify the collateral for.
     * @param _collateralAsset The address of the collateral asset.
     * @param _withdrawAmount The amount of the collateral asset to withdraw.
     * @param _collateralDeposits Collateral deposits for the account.
     * @param _collateralIndex Index of the collateral asset in the account's deposited collateral assets array.
     */
    function handleUncheckedWithdrawal(
        MinterState storage self,
        Asset storage _asset,
        address _account,
        address _collateralAsset,
        uint256 _withdrawAmount,
        uint256 _collateralDeposits,
        uint256 _collateralIndex
    ) internal {
        Validations.validateCollateralArgs(self, _account, _collateralAsset, _collateralIndex, _withdrawAmount);
        uint256 newCollateralAmount = _collateralDeposits - _withdrawAmount;

        // If the collateral asset is also a kresko asset, ensure that the deposit amount is above the minimum.
        // This is done because kresko assets can be rebased.
        _asset.ensureMinKrAssetCollateral(_collateralAsset, newCollateralAmount);

        // If the user is withdrawing all of the collateral asset, remove the collateral asset
        // from the user's deposited collateral assets array.
        if (newCollateralAmount == 0) {
            self.depositedCollateralAssets[_account].removeAddress(_collateralAsset, _collateralIndex);
        }

        // Record the withdrawal.
        self.collateralDeposits[_account][_collateralAsset] = _asset.toNonRebasingAmount(newCollateralAmount);

        emit MEvent.UncheckedCollateralWithdrawn(_account, _collateralAsset, _withdrawAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /* -------------------------------------------------------------------------- */
    /*                                    ERC20                                   */
    /* -------------------------------------------------------------------------- */

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

error APPROVE_FAILED(address, address, address, uint256);
error ETH_TRANSFER_FAILED(address, uint256);
error TRANSFER_FAILED(address, address, address, uint256);

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransfer {
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

        if (!success) revert ETH_TRANSFER_FAILED(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20 token,
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
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "from" argument.
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        if (!success) revert TRANSFER_FAILED(address(token), from, to, amount);
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success)
            revert TRANSFER_FAILED(address(token), msg.sender, to, amount);
    }

    function safeApprove(IERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            )
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success)
            revert APPROVE_FAILED(address(token), msg.sender, to, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev PercentageMath are defined by default with 2 decimals of precision (100.00).
 * The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library PercentageMath {
    // Maximum percentage factor (100.00%)
    uint256 internal constant PERCENTAGE_FACTOR = 1e4;

    // Half percentage factor (50.00%)
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;

    /**
     * @notice Executes a percentage multiplication
     * @dev assembly optimized for improved gas savings: https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentmul percentage
     **/
    function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if iszero(or(iszero(percentage), iszero(gt(value, div(sub(not(0), HALF_PERCENTAGE_FACTOR), percentage))))) {
                revert(0, 0)
            }

            result := div(add(mul(value, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /**
     * @notice Executes a percentage division
     * @dev assembly optimized for improved gas savings: https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentdiv percentage
     **/
    function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR
        assembly {
            if or(iszero(percentage), iszero(iszero(gt(value, div(sub(not(0), div(percentage, 2)), PERCENTAGE_FACTOR))))) {
                revert(0, 0)
            }

            result := div(add(mul(value, PERCENTAGE_FACTOR), div(percentage, 2)), percentage)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {WadRay} from "libs/WadRay.sol";
import {PercentageMath} from "libs/PercentageMath.sol";
import {Errors} from "common/Errors.sol";

using WadRay for uint256;
using PercentageMath for uint256;
using PercentageMath for uint16;

/* -------------------------------------------------------------------------- */
/*                                   General                                  */
/* -------------------------------------------------------------------------- */

/**
 * @notice Calculate amount for value provided with possible incentive multiplier for value.
 * @param _value Value to convert into amount.
 * @param _price The price to apply.
 * @param _multiplier Multiplier to apply, 1e4 = 100.00% precision.
 */
function valueToAmount(uint256 _value, uint256 _price, uint16 _multiplier) pure returns (uint256) {
    return _value.percentMul(_multiplier).wadDiv(_price);
}

/**
 * @notice Converts some decimal precision of `_amount` to wad decimal precision, which is 18 decimals.
 * @dev Multiplies if precision is less and divides if precision is greater than 18 decimals.
 * @param _amount Amount to convert.
 * @param _decimals Decimal precision for `_amount`.
 * @return uint256 Amount converted to wad precision.
 */
function toWad(uint256 _amount, uint8 _decimals) pure returns (uint256) {
    // Most tokens use 18 decimals.
    if (_decimals == 18 || _amount == 0) return _amount;

    if (_decimals < 18) {
        // Multiply for decimals less than 18 to get a wad value out.
        // If the token has 17 decimals, multiply by 10 ** (18 - 17) = 10
        // Results in a value of 1e18.
        return _amount * (10 ** (18 - _decimals));
    }

    // Divide for decimals greater than 18 to get a wad value out.
    // Loses precision, eg. 1 wei of token with 19 decimals:
    // Results in 1 / 10 ** (19 - 18) =  1 / 10 = 0.
    return _amount / (10 ** (_decimals - 18));
}

function toWad(int256 _amount, uint8 _decimals) pure returns (uint256) {
    if (_amount < 0) {
        revert Errors.TO_WAD_AMOUNT_IS_NEGATIVE(_amount);
    }
    return toWad(uint256(_amount), _decimals);
}

/**
 * @notice  Converts wad precision `_amount`  to some decimal precision.
 * @dev Multiplies if precision is greater and divides if precision is less than 18 decimals.
 * @param _wadAmount Wad amount to convert.
 * @param _decimals Decimals for the result.
 * @return uint256 Converted amount.
 */
function fromWad(uint256 _wadAmount, uint8 _decimals) pure returns (uint256) {
    // Most tokens use 18 decimals.
    if (_decimals == 18 || _wadAmount == 0) return _wadAmount;

    if (_decimals < 18) {
        // Divide if decimals are less than 18 to get the correct amount out.
        // If token has 17 decimals, dividing by 10 ** (18 - 17) = 10
        // Results in a value of 1e17, which can lose precision.
        return _wadAmount / (10 ** (18 - _decimals));
    }
    // Multiply for decimals greater than 18 to get the correct amount out.
    // If the token has 19 decimals, multiply by 10 ** (19 - 18) = 10
    // Results in a value of 1e19.
    return _wadAmount * (10 ** (_decimals - 18));
}

/**
 * @notice Get the value of `_amount` and convert to 18 decimal precision.
 * @param _amount Amount of tokens to calculate.
 * @param _amountDecimal Precision of `_amount`.
 * @param _price Price to use.
 * @param _priceDecimals Precision of `_price`.
 * @return uint256 Value of `_amount` in 18 decimal precision.
 */
function wadUSD(uint256 _amount, uint8 _amountDecimal, uint256 _price, uint8 _priceDecimals) pure returns (uint256) {
    if (_amount == 0 || _price == 0) return 0;
    return toWad(_amount, _amountDecimal).wadMul(toWad(_price, _priceDecimals));
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @notice SCDP initializer configuration.
 * @param minCollateralRatio The minimum collateralization ratio.
 * @param liquidationThreshold The liquidation threshold.
 * @param coverThreshold Threshold after which cover can be performed.
 * @param coverIncentive Incentive for covering debt instead of performing a liquidation.
 */
struct SCDPInitArgs {
    uint32 minCollateralRatio;
    uint32 liquidationThreshold;
    uint48 coverThreshold;
    uint48 coverIncentive;
}

/**
 * @notice SCDP initializer configuration.
 * @param feeAsset Asset that all fees from swaps are collected in.
 * @param minCollateralRatio The minimum collateralization ratio.
 * @param liquidationThreshold The liquidation threshold.
 * @param maxLiquidationRatio The maximum CR resulting from liquidations.
 * @param coverThreshold Threshold after which cover can be performed.
 * @param coverIncentive Incentive for covering debt instead of performing a liquidation.
 */
struct SCDPParameters {
    address feeAsset;
    uint32 minCollateralRatio;
    uint32 liquidationThreshold;
    uint32 maxLiquidationRatio;
    uint128 coverThreshold;
    uint128 coverIncentive;
}

// Used for setting swap pairs enabled or disabled in the pool.
struct SwapRouteSetter {
    address assetIn;
    address assetOut;
    bool enabled;
}

struct SCDPAssetData {
    uint256 debt;
    uint128 totalDeposits;
    uint128 swapDeposits;
}

/**
 * @notice SCDP asset fee and liquidation index data
 * @param currFeeIndex The ever increasing fee index, used to calculate fees.
 * @param currLiqIndex The ever increasing liquidation index, used to calculate liquidated amounts from principal.
 */
struct SCDPAssetIndexes {
    uint128 currFeeIndex;
    uint128 currLiqIndex;
}

/**
 * @notice SCDP seize data
 * @param prevLiqIndex Link to previous value in the liquidation index history.
 * @param feeIndex The fee index at the time of the seize.
 * @param liqIndex The liquidation index after the seize.
 */
struct SCDPSeizeData {
    uint256 prevLiqIndex;
    uint128 feeIndex;
    uint128 liqIndex;
}

/**
 * @notice SCDP account indexes
 * @param lastFeeIndex Fee index at the time of the action.
 * @param lastLiqIndex Liquidation index at the time of the action.
 * @param timestamp Timestamp of the last update.
 */
struct SCDPAccountIndexes {
    uint128 lastFeeIndex;
    uint128 lastLiqIndex;
    uint256 timestamp;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {WadRay} from "libs/WadRay.sol";
import {PercentageMath} from "libs/PercentageMath.sol";
import {Percents} from "common/Constants.sol";
import {cs} from "common/State.sol";
import {Errors} from "common/Errors.sol";
import {Asset} from "common/Types.sol";
import {SCDPState, sdi} from "scdp/SState.sol";
import {toWad} from "common/funcs/Math.sol";

library SGlobal {
    using WadRay for uint256;
    using WadRay for uint128;
    using PercentageMath for uint256;

    /**
     * @notice Checks whether the shared debt pool can be liquidated.
     * @notice Reverts if collateral value .
     */
    function ensureLiquidatableSCDP(SCDPState storage self) internal view {
        uint256 collateralValue = self.totalCollateralValueSCDP(false);
        uint256 minCollateralValue = sdi().effectiveDebtValue().percentMul(self.liquidationThreshold);
        if (collateralValue >= minCollateralValue) {
            revert Errors.COLLATERAL_VALUE_GREATER_THAN_REQUIRED(
                collateralValue,
                minCollateralValue,
                self.liquidationThreshold
            );
        }
    }

    /**
     * @notice Checks whether the shared debt pool can be liquidated.
     * @notice Reverts if collateral value .
     */
    function checkCoverableSCDP(SCDPState storage self) internal view {
        uint256 collateralValue = self.totalCollateralValueSCDP(false);
        uint256 minCoverValue = sdi().effectiveDebtValue().percentMul(sdi().coverThreshold);
        if (collateralValue >= minCoverValue) {
            revert Errors.COLLATERAL_VALUE_GREATER_THAN_COVER_THRESHOLD(collateralValue, minCoverValue, sdi().coverThreshold);
        }
    }

    /**
     * @notice Checks whether the collateral value is less than minimum required.
     * @notice Reverts when collateralValue is below minimum required.
     * @param _ratio Ratio to check in 1e4 percentage precision (uint32).
     */
    function ensureCollateralRatio(SCDPState storage self, uint32 _ratio) internal view {
        uint256 collateralValue = self.totalCollateralValueSCDP(false);
        uint256 minCollateralValue = sdi().effectiveDebtValue().percentMul(_ratio);
        if (collateralValue < minCollateralValue) {
            revert Errors.COLLATERAL_VALUE_LESS_THAN_REQUIRED(collateralValue, minCollateralValue, _ratio);
        }
    }

    /**
     * @notice Returns the value of the krAsset held in the pool at a ratio.
     * @param _ratio Percentage ratio to apply for the value in 1e4 percentage precision (uint32).
     * @param _ignorekFactor Whether to ignore kFactor
     * @return totalValue Total value in USD
     */
    function totalDebtValueAtRatioSCDP(
        SCDPState storage self,
        uint32 _ratio,
        bool _ignorekFactor
    ) internal view returns (uint256 totalValue) {
        address[] memory assets = self.krAssets;
        for (uint256 i; i < assets.length; ) {
            Asset storage asset = cs().assets[assets[i]];
            uint256 debtAmount = asset.toRebasingAmount(self.assetData[assets[i]].debt);
            unchecked {
                if (debtAmount != 0) {
                    totalValue += asset.debtAmountToValue(debtAmount, _ignorekFactor);
                }
                i++;
            }
        }

        // Multiply if needed
        if (_ratio != Percents.HUNDRED) {
            totalValue = totalValue.percentMul(_ratio);
        }
    }

    /**
     * @notice Calculates the total collateral value of collateral assets in the pool.
     * @param _ignoreFactors Whether to ignore cFactor.
     * @return totalValue Total value in USD
     */
    function totalCollateralValueSCDP(SCDPState storage self, bool _ignoreFactors) internal view returns (uint256 totalValue) {
        address[] memory assets = self.collaterals;
        for (uint256 i; i < assets.length; ) {
            Asset storage asset = cs().assets[assets[i]];
            uint256 depositAmount = self.totalDepositAmount(assets[i], asset);
            if (depositAmount != 0) {
                unchecked {
                    totalValue += asset.collateralAmountToValue(depositAmount, _ignoreFactors);
                }
            }

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Calculates total collateral value while extracting single asset value.
     * @param _collateralAsset Collateral asset to extract value for
     * @param _ignoreFactors Whether to ignore cFactor.
     * @return totalValue Total value in USD
     * @return assetValue Asset value in USD
     */
    function totalCollateralValueSCDP(
        SCDPState storage self,
        address _collateralAsset,
        bool _ignoreFactors
    ) internal view returns (uint256 totalValue, uint256 assetValue) {
        address[] memory assets = self.collaterals;
        for (uint256 i; i < assets.length; ) {
            Asset storage asset = cs().assets[assets[i]];
            uint256 depositAmount = self.totalDepositAmount(assets[i], asset);
            unchecked {
                if (depositAmount != 0) {
                    uint256 value = asset.collateralAmountToValue(depositAmount, _ignoreFactors);
                    totalValue += value;
                    if (assets[i] == _collateralAsset) {
                        assetValue = value;
                    }
                }
                i++;
            }
        }
    }

    /**
     * @notice Get pool collateral deposits of an asset.
     * @param _assetAddress The asset address
     * @param _asset The asset struct
     * @return Effective collateral deposit amount for this asset.
     */
    function totalDepositAmount(
        SCDPState storage self,
        address _assetAddress,
        Asset storage _asset
    ) internal view returns (uint128) {
        return uint128(_asset.toRebasingAmount(self.assetData[_assetAddress].totalDeposits));
    }

    /**
     * @notice Get pool user collateral deposits of an asset.
     * @param _assetAddress The asset address
     * @param _asset The asset struct
     * @return Collateral deposits originating from users.
     */
    function userDepositAmount(
        SCDPState storage self,
        address _assetAddress,
        Asset storage _asset
    ) internal view returns (uint256) {
        return
            _asset.toRebasingAmount(self.assetData[_assetAddress].totalDeposits) -
            _asset.toRebasingAmount(self.assetData[_assetAddress].swapDeposits);
    }

    /**
     * @notice Get "swap" collateral deposits.
     * @param _assetAddress The asset address
     * @param _asset The asset struct.
     * @return Amount of debt.
     */
    function swapDepositAmount(
        SCDPState storage self,
        address _assetAddress,
        Asset storage _asset
    ) internal view returns (uint128) {
        return uint128(_asset.toRebasingAmount(self.assetData[_assetAddress].swapDeposits));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {WadRay} from "libs/WadRay.sol";
import {Asset} from "common/Types.sol";
import {Errors} from "common/Errors.sol";
import {SCDPState} from "scdp/SState.sol";
import {IERC20} from "kresko-lib/token/IERC20.sol";
import {SCDPSeizeData} from "scdp/STypes.sol";
import {SEvent} from "scdp/SEvent.sol";
import {SafeTransfer} from "kresko-lib/token/SafeTransfer.sol";

library SDeposits {
    using WadRay for uint256;
    using WadRay for uint128;
    using SafeTransfer for IERC20;

    /**
     * @notice Records a deposit of collateral asset.
     * @notice It will withdraw any pending fees first.
     * @notice Saves global deposit amount and principal for user.
     * @param _asset Asset struct for the deposit asset
     * @param _account depositor
     * @param _assetAddr the deposit asset
     * @param _amount amount of collateral asset to deposit
     */
    function handleDepositSCDP(
        SCDPState storage self,
        Asset storage _asset,
        address _account,
        address _assetAddr,
        uint256 _amount
    ) internal returns (uint256 feeIndex) {
        // Withdraw any fees first.
        uint256 fees = handleFeeClaim(self, _asset, _account, _assetAddr, _account, false);
        // Save account liquidation and fee indexes if they werent saved before.
        if (fees == 0) {
            (, feeIndex) = updateAccountIndexes(self, _account, _assetAddr);
        }

        unchecked {
            // Save global deposits using normalized amount.
            uint128 normalizedAmount = uint128(_asset.toNonRebasingAmount(_amount));
            self.assetData[_assetAddr].totalDeposits += normalizedAmount;

            // Save account deposit amount, its scaled up by the liquidation index.
            self.depositsPrincipal[_account][_assetAddr] += self.mulByLiqIndex(_assetAddr, normalizedAmount);

            // Check if the deposit limit is exceeded.
            if (self.userDepositAmount(_assetAddr, _asset) > _asset.depositLimitSCDP) {
                revert Errors.EXCEEDS_ASSET_DEPOSIT_LIMIT(
                    Errors.id(_assetAddr),
                    self.userDepositAmount(_assetAddr, _asset),
                    _asset.depositLimitSCDP
                );
            }
        }
    }

    /**
     * @notice Records a withdrawal of collateral asset from the SCDP.
     * @notice It will withdraw any pending fees first.
     * @notice Saves global deposit amount and principal for user.
     * @param _asset Asset struct for the deposit asset
     * @param _account The withdrawing account
     * @param _assetAddr the deposit asset
     * @param _amount The amount of collateral to withdraw
     * @param _receiver The receiver of the withdrawn fees
     * @param _skipClaim Emergency flag to skip claiming fees
     */
    function handleWithdrawSCDP(
        SCDPState storage self,
        Asset storage _asset,
        address _account,
        address _assetAddr,
        uint256 _amount,
        address _receiver,
        bool _skipClaim
    ) internal returns (uint256 feeIndex) {
        // Handle fee claiming.
        uint256 fees = handleFeeClaim(self, _asset, _account, _assetAddr, _receiver, _skipClaim);
        // Save account liquidation and fee indexes if they werent updated on fee claim.
        if (fees == 0) {
            (, feeIndex) = updateAccountIndexes(self, _account, _assetAddr);
        }

        // Get accounts principal deposits.
        uint256 depositsPrincipal = self.accountDeposits(_account, _assetAddr, _asset);

        // Check that we can perform the withdrawal.
        if (depositsPrincipal == 0) {
            revert Errors.ACCOUNT_HAS_NO_DEPOSITS(_account, Errors.id(_assetAddr));
        }
        if (depositsPrincipal < _amount) {
            revert Errors.WITHDRAW_AMOUNT_GREATER_THAN_DEPOSITS(_account, Errors.id(_assetAddr), _amount, depositsPrincipal);
        }

        unchecked {
            // Save global deposits using normalized amount.
            uint128 normalizedAmount = uint128(_asset.toNonRebasingAmount(_amount));
            self.assetData[_assetAddr].totalDeposits -= normalizedAmount;

            // Save account deposit amount, the amount withdrawn is scaled up by the liquidation index.
            self.depositsPrincipal[_account][_assetAddr] -= self.mulByLiqIndex(_assetAddr, normalizedAmount);
        }
    }

    /**
     * @notice This function seizes collateral from the shared pool.
     * @notice It will reduce all deposits in the case where swap deposits do not cover the amount.
     * @notice Each event touching user deposits will save a checkpoint of the indexes.
     * @param _sAsset The asset struct (Asset).
     * @param _assetAddr The seized asset address.
     * @param _seizeAmount The seize amount (uint256).
     */
    function handleSeizeSCDP(
        SCDPState storage self,
        Asset storage _sAsset,
        address _assetAddr,
        uint256 _seizeAmount
    ) internal returns (uint128 prevLiqIndex, uint128 newLiqIndex) {
        uint128 swapDeposits = self.swapDepositAmount(_assetAddr, _sAsset);

        if (swapDeposits >= _seizeAmount) {
            uint128 amountOut = uint128(_sAsset.toNonRebasingAmount(_seizeAmount));
            // swap deposits cover the amount
            unchecked {
                self.assetData[_assetAddr].swapDeposits -= amountOut;
                self.assetData[_assetAddr].totalDeposits -= amountOut;
            }
        } else {
            // swap deposits do not cover the amount
            self.assetData[_assetAddr].swapDeposits = 0;
            // total deposits = user deposits at this point
            self.assetData[_assetAddr].totalDeposits -= uint128(_sAsset.toNonRebasingAmount(_seizeAmount));

            // We need this later for seize data as well.
            prevLiqIndex = self.assetIndexes[_assetAddr].currLiqIndex;
            newLiqIndex = uint128(
                prevLiqIndex +
                    (_seizeAmount - swapDeposits).wadToRay().rayMul(prevLiqIndex).rayDiv(
                        _sAsset.toRebasingAmount(self.assetData[_assetAddr].totalDeposits.wadToRay())
                    )
            );

            // Increase liquidation index, note this uses rebased amounts instead of normalized.
            self.assetIndexes[_assetAddr].currLiqIndex = newLiqIndex;

            // Save the seize data.
            self.seizeEvents[_assetAddr][self.assetIndexes[_assetAddr].currLiqIndex] = SCDPSeizeData({
                prevLiqIndex: prevLiqIndex,
                feeIndex: self.assetIndexes[_assetAddr].currFeeIndex,
                liqIndex: self.assetIndexes[_assetAddr].currLiqIndex
            });
        }

        IERC20(_assetAddr).safeTransfer(msg.sender, _seizeAmount);
        return (prevLiqIndex, self.assetIndexes[_assetAddr].currLiqIndex);
    }

    /**
     * @notice Fully handles fee claim.
     * @notice Checks whether some fees exists, withdrawis them and updates account indexes.
     * @param _asset The asset struct.
     * @param _account The account to withdraw fees for.
     * @param _assetAddr The asset address.
     * @param _receiver Receiver of fees withdrawn, if 0 then the receiver is the account.
     * @param _skip Emergency flag, skips claiming fees due and logs a receipt for off-chain processing
     * @return feeAmount Amount of fees withdrawn.
     * @dev This function is used by deposit and withdraw functions.
     */
    function handleFeeClaim(
        SCDPState storage self,
        Asset storage _asset,
        address _account,
        address _assetAddr,
        address _receiver,
        bool _skip
    ) internal returns (uint256 feeAmount) {
        if (_skip) {
            _logFeeReceipt(self, _account, _assetAddr);
            return 0;
        }
        uint256 fees = self.accountFees(_account, _assetAddr, _asset);
        if (fees > 0) {
            (uint256 prevIndex, uint256 newIndex) = updateAccountIndexes(self, _account, _assetAddr);
            IERC20(_assetAddr).transfer(_receiver, fees);
            emit SEvent.SCDPFeeClaim(_account, _receiver, _assetAddr, fees, newIndex, prevIndex, block.timestamp);
        }

        return fees;
    }

    function _logFeeReceipt(SCDPState storage self, address _account, address _assetAddr) private {
        emit SEvent.SCDPFeeReceipt(
            _account,
            _assetAddr,
            self.depositsPrincipal[_account][_assetAddr],
            self.assetIndexes[_assetAddr].currFeeIndex,
            self.accountIndexes[_account][_assetAddr].lastFeeIndex,
            self.assetIndexes[_assetAddr].currLiqIndex,
            self.accountIndexes[_account][_assetAddr].lastLiqIndex,
            block.number,
            block.timestamp
        );
    }

    /**
     * @notice Updates account indexes to checkpoint the fee index and liquidation index at the time of action.
     * @param _account The account to update indexes for.
     * @param _assetAddr The asset being withdrawn/deposited.
     * @dev This function is used by deposit and withdraw functions.
     */
    function updateAccountIndexes(
        SCDPState storage self,
        address _account,
        address _assetAddr
    ) private returns (uint128 prevIndex, uint128 newIndex) {
        prevIndex = self.accountIndexes[_account][_assetAddr].lastFeeIndex;
        newIndex = self.assetIndexes[_assetAddr].currFeeIndex;
        self.accountIndexes[_account][_assetAddr].lastFeeIndex = self.assetIndexes[_assetAddr].currFeeIndex;
        self.accountIndexes[_account][_assetAddr].lastLiqIndex = self.assetIndexes[_assetAddr].currLiqIndex;
        self.accountIndexes[_account][_assetAddr].timestamp = block.timestamp;
    }

    function mulByLiqIndex(SCDPState storage self, address _assetAddr, uint256 _amount) internal view returns (uint128) {
        return uint128(_amount.wadToRay().rayMul(self.assetIndexes[_assetAddr].currLiqIndex).rayToWad());
    }

    function divByLiqIndex(SCDPState storage self, address _assetAddr, uint256 _depositAmount) internal view returns (uint128) {
        return uint128(_depositAmount.wadToRay().rayDiv(self.assetIndexes[_assetAddr].currLiqIndex).rayToWad());
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {WadRay} from "libs/WadRay.sol";
import {SCDPState} from "scdp/SState.sol";
import {cs} from "common/State.sol";
import {Asset} from "common/Types.sol";
import {SCDPAccountIndexes, SCDPAssetIndexes, SCDPSeizeData} from "scdp/STypes.sol";

library SAccounts {
    using WadRay for uint256;

    /**
     * @notice Get accounts principal deposits.
     * @notice Uses scaled deposits if its lower than principal (realizing liquidations).
     * @param _account The account to get the amount for
     * @param _assetAddr The deposit asset address
     * @param _asset The deposit asset struct
     * @return principalDeposits The principal deposit amount for the account.
     */
    function accountDeposits(
        SCDPState storage self,
        address _account,
        address _assetAddr,
        Asset storage _asset
    ) internal view returns (uint256 principalDeposits) {
        return self.divByLiqIndex(_assetAddr, _asset.toRebasingAmount(self.depositsPrincipal[_account][_assetAddr]));
    }

    /**
     * @notice Returns the value of the deposits for `_account`.
     * @param _account Account to get total deposit value for
     * @param _ignoreFactors Whether to ignore cFactor and kFactor
     */
    function accountDepositsValue(
        SCDPState storage self,
        address _account,
        bool _ignoreFactors
    ) internal view returns (uint256 totalValue) {
        address[] memory assets = self.collaterals;
        for (uint256 i; i < assets.length; ) {
            Asset storage asset = cs().assets[assets[i]];
            uint256 depositAmount = self.accountDeposits(_account, assets[i], asset);
            unchecked {
                if (depositAmount != 0) {
                    totalValue += asset.collateralAmountToValue(depositAmount, _ignoreFactors);
                }
                i++;
            }
        }
    }

    /**
     * @notice Get accounts total fees gained for this asset.
     * @notice To get this value it compares deposit time liquidity index with current.
     * @notice If the account has endured liquidation events, separate logic is used to combine fees according to historical balance.
     * @param _account The account to get the amount for
     * @param _assetAddr The asset address
     * @param _asset The asset struct
     * @return feeAmount Amount of fees accrued.
     */
    function accountFees(
        SCDPState storage self,
        address _account,
        address _assetAddr,
        Asset storage _asset
    ) internal view returns (uint256 feeAmount) {
        SCDPAssetIndexes memory assetIndexes = self.assetIndexes[_assetAddr];
        SCDPAccountIndexes memory accountIndexes = self.accountIndexes[_account][_assetAddr];
        // Return early if there are no fees accrued.
        if (accountIndexes.lastFeeIndex == 0 || accountIndexes.lastFeeIndex == assetIndexes.currFeeIndex) return 0;

        // Get the principal deposits for the account.
        uint256 principalDeposits = _asset.toRebasingAmount(self.depositsPrincipal[_account][_assetAddr]).wadToRay();

        // If accounts last liquidation index is lower than current, it means they endured a liquidation.
        SCDPSeizeData memory latestSeize = self.seizeEvents[_assetAddr][assetIndexes.currLiqIndex];

        if (accountIndexes.lastLiqIndex < latestSeize.liqIndex) {
            // Accumulated fees before now and after latest seize.
            uint256 feesAfterLastSeize = principalDeposits.rayMul(assetIndexes.currFeeIndex - latestSeize.feeIndex).rayDiv(
                latestSeize.liqIndex
            );

            uint256 feesBeforeLastSeize;
            // Just loop through all events until we hit the same index as the account.
            while (accountIndexes.lastLiqIndex < latestSeize.liqIndex && accountIndexes.lastFeeIndex < latestSeize.feeIndex) {
                SCDPSeizeData memory previousSeize = self.seizeEvents[_assetAddr][latestSeize.prevLiqIndex];

                if (previousSeize.liqIndex == 0) break;
                if (previousSeize.feeIndex < accountIndexes.lastFeeIndex) {
                    previousSeize.feeIndex = accountIndexes.lastFeeIndex;
                }
                uint256 feePct = latestSeize.feeIndex - previousSeize.feeIndex;
                if (feePct > 0) {
                    // Get the historical balance according to liquidation index at the time
                    // Then we simply multiply by fee index difference to get the fees accrued.
                    feesBeforeLastSeize += principalDeposits.rayMul(feePct).rayDiv(latestSeize.prevLiqIndex);
                }
                // Iterate backwards in time.
                latestSeize = previousSeize;
            }

            return (feesBeforeLastSeize + feesAfterLastSeize).rayToWad();
        }

        // If we are here, it means the account has not endured a liquidation.
        // We can simply calculate the fees by multiplying the difference in fee indexes with the principal deposits.
        return
            principalDeposits
                .rayMul(assetIndexes.currFeeIndex - accountIndexes.lastFeeIndex)
                .rayDiv(assetIndexes.currLiqIndex)
                .rayToWad();
    }

    /**
     * @notice Returns the total fees value for `_account`.
     * @notice Ignores all factors.
     * @param _account Account to get fees for
     * @return totalValue Total fees value for `_account`
     */
    function accountTotalFeeValue(SCDPState storage self, address _account) internal view returns (uint256 totalValue) {
        address[] memory assets = self.collaterals;
        for (uint256 i; i < assets.length; ) {
            Asset storage asset = cs().assets[assets[i]];
            uint256 fees = self.accountFees(_account, assets[i], asset);
            unchecked {
                if (fees != 0) {
                    totalValue += asset.collateralAmountToValue(fees, true);
                }
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;
import {SafeTransfer} from "kresko-lib/token/SafeTransfer.sol";
import {IERC20} from "kresko-lib/token/IERC20.sol";
import {WadRay} from "libs/WadRay.sol";
import {mintSCDP, burnSCDP} from "common/funcs/Actions.sol";
import {Asset} from "common/Types.sol";

import {Errors} from "common/Errors.sol";
import {scdp, SCDPState} from "scdp/SState.sol";
import {SCDPAssetData} from "scdp/STypes.sol";

library Swap {
    using WadRay for uint256;
    using WadRay for uint128;
    using SafeTransfer for IERC20;

    /**
     * @notice Records the assets received from account in a swap.
     * Burning any existing shared debt or increasing collateral deposits.
     * @param _assetInAddr The asset received.
     * @param _assetIn The asset in struct.
     * @param _amountIn The amount of the asset received.
     * @param _assetsFrom The account that holds the assets to burn.
     * @return The value of the assets received into the protocol, used to calculate assets out.
     */
    function handleAssetsIn(
        SCDPState storage self,
        address _assetInAddr,
        Asset storage _assetIn,
        uint256 _amountIn,
        address _assetsFrom
    ) internal returns (uint256) {
        SCDPAssetData storage assetData = self.assetData[_assetInAddr];
        uint256 debt = _assetIn.toRebasingAmount(assetData.debt);

        uint256 collateralIn; // assets used increase "swap" owned collateral
        uint256 debtOut; // assets used to burn debt

        if (debt < _amountIn) {
            // == Debt is less than the amount received.
            // 1. Burn full debt.
            debtOut = debt;
            // 2. Increase collateral by remainder.
            unchecked {
                collateralIn = _amountIn - debt;
            }
        } else {
            // == Debt is greater than the amount.
            // 1. Burn full amount received.
            debtOut = _amountIn;
            // 2. No increase in collateral.
        }

        if (collateralIn > 0) {
            uint128 collateralInNormalized = uint128(_assetIn.toNonRebasingAmount(collateralIn));
            unchecked {
                // 1. Increase collateral deposits.
                assetData.totalDeposits += collateralInNormalized;
                // 2. Increase "swap" collateral.
                assetData.swapDeposits += collateralInNormalized;
            }
        }

        if (debtOut > 0) {
            unchecked {
                // 1. Burn debt that was repaid from the assets received.
                assetData.debt -= burnSCDP(_assetIn, debtOut, _assetsFrom);
            }
        }

        assert(_amountIn == debtOut + collateralIn);
        return _assetIn.debtAmountToValue(_amountIn, true); // ignore kFactor here
    }

    /**
     * @notice Records the assets to send out in a swap.
     * Increasing debt of the pool by minting new assets when required.
     * @param _assetOutAddr The asset to send out.
     * @param _assetOut The asset out struct.
     * @param _valueIn The value received in.
     * @param _assetsTo The asset receiver.
     * @return amountOut The amount of the asset out.
     */
    function handleAssetsOut(
        SCDPState storage self,
        address _assetOutAddr,
        Asset storage _assetOut,
        uint256 _valueIn,
        address _assetsTo
    ) internal returns (uint256 amountOut) {
        SCDPAssetData storage assetData = self.assetData[_assetOutAddr];
        uint128 swapDeposits = uint128(_assetOut.toRebasingAmount(assetData.swapDeposits)); // current "swap" collateral

        // Calculate amount to send out from value received in.
        amountOut = _assetOut.debtValueToAmount(_valueIn, true);

        uint256 collateralOut; // decrease in "swap" collateral
        uint256 debtIn; // new debt required to mint

        if (swapDeposits < amountOut) {
            // == "Swap" owned collateral is less than requested amount.
            // 1. Issue debt for remainder.
            unchecked {
                debtIn = amountOut - swapDeposits;
            }
            // 2. Reduce "swap" owned collateral to zero.
            collateralOut = swapDeposits;
        } else {
            // == "Swap" owned collateral exceeds requested amount
            // 1. No debt issued.
            // 2. Decrease collateral by full amount.
            collateralOut = amountOut;
        }

        if (collateralOut > 0) {
            uint128 collateralOutNormalized = uint128(_assetOut.toNonRebasingAmount(collateralOut));
            unchecked {
                // 1. Decrease collateral deposits.
                assetData.totalDeposits -= collateralOutNormalized;
                // 2. Decrease "swap" owned collateral.
                assetData.swapDeposits -= collateralOutNormalized;
            }
            if (_assetsTo != address(this)) {
                // 3. Transfer collateral to receiver if it is not this contract.
                IERC20(_assetOutAddr).safeTransfer(_assetsTo, collateralOut);
            }
        }

        if (debtIn > 0) {
            // 1. Issue required debt to the pool, minting new assets to receiver.
            unchecked {
                assetData.debt += mintSCDP(_assetOut, debtIn, _assetsTo);
                uint256 newTotalDebt = _assetOut.toRebasingAmount(assetData.debt);
                if (newTotalDebt > _assetOut.maxDebtSCDP) {
                    revert Errors.EXCEEDS_ASSET_MINTING_LIMIT(Errors.id(_assetOutAddr), newTotalDebt, _assetOut.maxDebtSCDP);
                }
            }
        }

        assert(amountOut == debtIn + collateralOut);
    }

    /**
     * @notice Accumulates fees to deposits as a fixed, instantaneous income.
     * @param _assetAddr The asset address
     * @param _asset The asset struct
     * @param _amount The amount to accumulate
     * @return nextLiquidityIndex The next liquidity index of the reserve
     */
    function cumulateIncome(
        SCDPState storage self,
        address _assetAddr,
        Asset storage _asset,
        uint256 _amount
    ) internal returns (uint256 nextLiquidityIndex) {
        if (_amount == 0) {
            revert Errors.INCOME_AMOUNT_IS_ZERO(Errors.id(_assetAddr));
        }

        uint256 userDeposits = self.userDepositAmount(_assetAddr, _asset);
        if (userDeposits == 0) {
            revert Errors.NO_LIQUIDITY_TO_GIVE_INCOME_FOR(
                Errors.id(_assetAddr),
                userDeposits,
                self.totalDepositAmount(_assetAddr, _asset)
            );
        }

        // liquidity index increment is calculated this way: `(amount / totalLiquidity)`
        // division `amount / totalLiquidity` done in ray for precision
        unchecked {
            return (scdp().assetIndexes[_assetAddr].currFeeIndex += uint128(
                (_amount.wadToRay().rayDiv(userDeposits.wadToRay()))
            ));
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {WadRay} from "libs/WadRay.sol";
import {SafeTransfer} from "kresko-lib/token/SafeTransfer.sol";
import {IERC20} from "kresko-lib/token/IERC20.sol";
import {cs} from "common/State.sol";
import {Asset} from "common/Types.sol";
import {fromWad, toWad, wadUSD} from "common/funcs/Math.sol";
import {SDIPrice} from "common/funcs/Prices.sol";
import {Errors} from "common/Errors.sol";
import {scdp, SDIState} from "scdp/SState.sol";

library SDebtIndex {
    using SafeTransfer for IERC20;
    using WadRay for uint256;

    function cover(SDIState storage self, address _assetAddr, uint256 _amount, uint256 _value) internal {
        scdp().checkCoverableSCDP();
        if (_amount == 0) revert Errors.ZERO_AMOUNT(Errors.id(_assetAddr));

        IERC20(_assetAddr).safeTransferFrom(msg.sender, self.coverRecipient, _amount);
        self.totalCover += valueToSDI(_value);
    }

    function valueToSDI(uint256 valueInWad) internal view returns (uint256) {
        return toWad(valueInWad, cs().oracleDecimals).wadDiv(SDIPrice());
    }

    /// @notice Returns the total effective debt amount of the SCDP.
    function effectiveDebt(SDIState storage self) internal view returns (uint256) {
        uint256 currentCover = self.totalCoverAmount();
        uint256 totalDebt = self.totalDebt;
        if (currentCover >= totalDebt) {
            return 0;
        }
        return (totalDebt - currentCover);
    }

    /// @notice Returns the total effective debt value of the SCDP.
    /// @notice Calculation is done in wad precision but returned as oracle precision.
    function effectiveDebtValue(SDIState storage self) internal view returns (uint256 result) {
        uint256 sdiPrice = SDIPrice();
        uint256 coverValue = self.totalCoverValue();
        uint256 coverAmount = coverValue != 0 ? coverValue.wadDiv(sdiPrice) : 0;
        uint256 totalDebt = self.totalDebt;

        if (coverAmount >= totalDebt) return 0;

        if (coverValue == 0) {
            result = totalDebt;
        } else {
            result = (totalDebt - coverAmount);
        }

        return fromWad(result.wadMul(sdiPrice), cs().oracleDecimals);
    }

    function totalCoverAmount(SDIState storage self) internal view returns (uint256) {
        return self.totalCoverValue().wadDiv(SDIPrice());
    }

    /// @notice Gets the total cover debt value, wad precision
    function totalCoverValue(SDIState storage self) internal view returns (uint256 result) {
        address[] memory assets = self.coverAssets;
        for (uint256 i; i < assets.length; ) {
            unchecked {
                result += coverAssetValue(self, assets[i]);
                i++;
            }
        }
    }

    /// @notice Simply returns the total supply of SDI.
    function totalSDI(SDIState storage self) internal view returns (uint256) {
        return self.totalDebt + self.totalCoverAmount();
    }

    /// @notice Get total deposit value of `asset` in USD, wad precision.
    function coverAssetValue(SDIState storage self, address _assetAddr) internal view returns (uint256) {
        uint256 bal = IERC20(_assetAddr).balanceOf(self.coverRecipient);
        if (bal == 0) return 0;

        Asset storage asset = cs().assets[_assetAddr];
        if (!asset.isCoverAsset) return 0;

        return wadUSD(bal, asset.decimals, asset.price(), cs().oracleDecimals);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns (uint256[] memory balances);

    function setApprovalForAll(address operator, bool approved) external;

    function uri(uint256) external view returns (string memory);

    function contractURI() external view returns (string memory);

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function storeGetByKey(uint256 _tokenId, address _account, bytes32 _key) external view returns (bytes32[] memory);

    function storeGetByIndex(uint256 _tokenId, address _account, bytes32 _key, uint256 _idx) external view returns (bytes32);

    function storeCreateValue(uint256 _tokenId, address _account, bytes32 _key, bytes32 _value) external returns (bytes32);

    function storeAppendValue(uint256 _tokenId, address _account, bytes32 _key, bytes32 _value) external returns (bytes32);

    function storeUpdateValue(uint256 _tokenId, address _account, bytes32 _key, bytes32 _value) external returns (bytes32);

    function storeClearKey(uint256 _tokenId, address _account, bytes32 _key) external returns (bool);

    function storeClearKeys(uint256 _tokenId, address _account, bytes32[] memory _keys) external returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) external;

    function mint(address _to, uint256 _tokenId, uint256 _amount, bytes memory) external;

    function mint(address _to, uint256 _tokenId, uint256 _amount) external;

    function burn(address _to, uint256 _tokenId, uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {IAccessControlEnumerable} from "@oz/access/extensions/IAccessControlEnumerable.sol";
import {IERC165} from "vendor/IERC165.sol";
import {IERC20Permit} from "kresko-lib/token/IERC20Permit.sol";

import {IKreskoAssetIssuer} from "./IKreskoAssetIssuer.sol";
import {IERC4626Upgradeable} from "./IERC4626Upgradeable.sol";

interface IKreskoAssetAnchor is IKreskoAssetIssuer, IERC4626Upgradeable, IERC20Permit, IAccessControlEnumerable, IERC165 {
    function totalAssets() external view override(IERC4626Upgradeable) returns (uint256);

    /**
     * @notice Updates ERC20 metadata for the token in case eg. a ticker change
     * @param _name new name for the asset
     * @param _symbol new symbol for the asset
     * @param _version number that must be greater than latest emitted `Initialized` version
     */
    function reinitializeERC20(string memory _name, string memory _symbol, uint8 _version) external;

    /**
     * @notice Mint Kresko Anchor Asset to Kresko Asset (Only KreskoAsset can call)
     * @param assets The assets (uint256).
     */
    function wrap(uint256 assets) external;

    /**
     * @notice Burn Kresko Anchor Asset to Kresko Asset (Only KreskoAsset can call)
     * @param assets The assets (uint256).
     */

    function unwrap(uint256 assets) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {IAggregatorV3} from "kresko-lib/vendor/IAggregatorV3.sol";
import {IAPI3} from "kresko-lib/vendor/IAPI3.sol";
import {IVaultRateProvider} from "vault/interfaces/IVaultRateProvider.sol";

import {WadRay} from "libs/WadRay.sol";
import {Strings} from "libs/Strings.sol";
import {PercentageMath} from "libs/PercentageMath.sol";
import {Redstone} from "libs/Redstone.sol";

import {Errors} from "common/Errors.sol";
import {cs} from "common/State.sol";
import {scdp, sdi} from "scdp/SState.sol";
import {isSequencerUp} from "common/funcs/Utils.sol";
import {RawPrice, Oracle} from "common/Types.sol";
import {Percents, Enums} from "common/Constants.sol";
import {fromWad, toWad} from "common/funcs/Math.sol";
import {IPyth} from "vendor/pyth/IPyth.sol";
import {PythView} from "vendor/pyth/PythScript.sol";
import {IMarketStatus} from "common/interfaces/IMarketStatus.sol";

using WadRay for uint256;
using PercentageMath for uint256;
using Strings for bytes32;

/* -------------------------------------------------------------------------- */
/*                                   Getters                                  */
/* -------------------------------------------------------------------------- */

/**
 * @notice Gets the oracle price using safety checks for deviation and sequencer uptime
 * @notice Reverts when price deviates more than `_oracleDeviationPct`
 * @notice Allows stale price when market is closed, market status must be checked before calling this function if needed.
 * @param _ticker Ticker of the price
 * @param _oracles The list of oracle identifiers
 * @param _oracleDeviationPct the deviation percentage
 */
function safePrice(bytes32 _ticker, Enums.OracleType[2] memory _oracles, uint256 _oracleDeviationPct) view returns (uint256) {
    Oracle memory primaryConfig = cs().oracles[_ticker][_oracles[0]];
    Oracle memory referenceConfig = cs().oracles[_ticker][_oracles[1]];

    bool isClosed = (primaryConfig.isClosable || referenceConfig.isClosable) &&
        !IMarketStatus(cs().marketStatusProvider).getTickerStatus(_ticker);

    uint256 primaryPrice = oraclePrice(_oracles[0], primaryConfig, _ticker, isClosed);
    uint256 referencePrice = oraclePrice(_oracles[1], referenceConfig, _ticker, isClosed);

    if (primaryPrice == 0 && referencePrice == 0) {
        revert Errors.ZERO_OR_STALE_PRICE(_ticker.toString(), [uint8(_oracles[0]), uint8(_oracles[1])]);
    }

    // Enums.OracleType.Vault uses the same check, reverting if the sequencer is down.
    if (!isSequencerUp(cs().sequencerUptimeFeed, cs().sequencerGracePeriodTime)) {
        revert Errors.L2_SEQUENCER_DOWN();
    }

    return deducePrice(primaryPrice, referencePrice, _oracleDeviationPct);
}

/**
 * @notice Call the price getter for the oracle provided and return the price.
 * @param _oracleId The oracle id (uint8).
 * @param _ticker Ticker for the asset
 * @param _allowStale Flag to allow stale price in the case when market is closed.
 * @return uint256 oracle price.
 * This will return 0 if the oracle is not set.
 */
function oraclePrice(
    Enums.OracleType _oracleId,
    Oracle memory _config,
    bytes32 _ticker,
    bool _allowStale
) view returns (uint256) {
    if (_oracleId == Enums.OracleType.Empty) return 0;

    uint256 staleTime = _allowStale ? _config.staleTime : 4 days;

    if (_oracleId == Enums.OracleType.Redstone) return Redstone.getPrice(_ticker, staleTime);

    if (_oracleId == Enums.OracleType.Pyth) return pythPrice(_config.pythId, _config.invertPyth, staleTime);

    if (_oracleId == Enums.OracleType.Vault) {
        return vaultPrice(_config.feed);
    }

    if (_oracleId == Enums.OracleType.Chainlink) {
        return aggregatorV3Price(_config.feed, staleTime);
    }

    if (_oracleId == Enums.OracleType.API3) {
        return API3Price(_config.feed, staleTime);
    }

    // Revert if no answer is found
    revert Errors.UNSUPPORTED_ORACLE(_ticker.toString(), uint8(_oracleId));
}

/**
 * @notice Checks the primary and reference price for deviations.
 * @notice Reverts if the price deviates more than `_oracleDeviationPct`
 * @param _primaryPrice the primary price source to use
 * @param _referencePrice the reference price to compare primary against
 * @param _oracleDeviationPct the deviation percentage to use for the oracle
 * @return uint256 Primary price if its within deviation range of reference price.
 * = the primary price is reference price is 0.
 * = the reference price if primary price is 0.
 * = reverts if price deviates more than `_oracleDeviationPct`
 */
function deducePrice(uint256 _primaryPrice, uint256 _referencePrice, uint256 _oracleDeviationPct) pure returns (uint256) {
    if (_referencePrice == 0 && _primaryPrice != 0) return _primaryPrice;
    if (_primaryPrice == 0 && _referencePrice != 0) return _referencePrice;
    if (
        (_referencePrice.percentMul(1e4 - _oracleDeviationPct) <= _primaryPrice) &&
        (_referencePrice.percentMul(1e4 + _oracleDeviationPct) >= _primaryPrice)
    ) {
        return _primaryPrice;
    }

    // Revert if price deviates more than `_oracleDeviationPct`
    revert Errors.PRICE_UNSTABLE(_primaryPrice, _referencePrice, _oracleDeviationPct);
}

function pythPrice(bytes32 _id, bool _invert, uint256 _staleTime) view returns (uint256 price_) {
    IPyth.Price memory result = IPyth(cs().pythEp).getPriceNoOlderThan(_id, _staleTime);

    if (!_invert) {
        price_ = normalizePythPrice(result, cs().oracleDecimals);
    } else {
        price_ = invertNormalizePythPrice(result, cs().oracleDecimals);
    }

    if (price_ == 0 || price_ > type(uint56).max) {
        revert Errors.INVALID_PYTH_PRICE(_id, price_);
    }
}

function normalizePythPrice(IPyth.Price memory _price, uint8 oracleDec) pure returns (uint256) {
    uint256 result = uint64(_price.price);
    uint256 exp = uint32(-_price.exp);
    if (exp > oracleDec) {
        result = result / 10 ** (exp - oracleDec);
    }
    if (exp < oracleDec) {
        result = result * 10 ** (oracleDec - exp);
    }

    return result;
}

function invertNormalizePythPrice(IPyth.Price memory _price, uint8 oracleDec) pure returns (uint256) {
    _price.price = int64(uint64(1 * (10 ** uint32(-_price.exp)).wadDiv(uint64(_price.price))));
    _price.exp = -18;
    return normalizePythPrice(_price, oracleDec);
}

/**
 * @notice Gets the price from the provided vault.
 * @dev Vault exchange rate is in 18 decimal precision so we normalize to 8 decimals.
 * @param _vaultAddr The vault address.
 * @return uint256 The price of the vault share in 8 decimal precision.
 */
function vaultPrice(address _vaultAddr) view returns (uint256) {
    return fromWad(IVaultRateProvider(_vaultAddr).exchangeRate(), cs().oracleDecimals);
}

/// @notice Get the price of SDI in USD (WAD precision, so 18 decimals).
function SDIPrice() view returns (uint256) {
    uint256 totalValue = scdp().totalDebtValueAtRatioSCDP(Percents.HUNDRED, false);
    if (totalValue == 0) {
        return 1e18;
    }
    return toWad(totalValue, cs().oracleDecimals).wadDiv(sdi().totalDebt);
}

/**
 * @notice Gets answer from AggregatorV3 type feed.
 * @param _feedAddr The feed address.
 * @param _staleTime Time in seconds for the feed to be considered stale.
 * @return uint256 Parsed answer from the feed, 0 if its stale.
 */
function aggregatorV3Price(address _feedAddr, uint256 _staleTime) view returns (uint256) {
    (, int256 answer, , uint256 updatedAt, ) = IAggregatorV3(_feedAddr).latestRoundData();
    if (answer < 0) {
        revert Errors.NEGATIVE_PRICE(_feedAddr, answer);
    }
    // IMPORTANT: Returning zero when answer is stale, to activate fallback oracle.
    if (block.timestamp - updatedAt > _staleTime) {
        revert Errors.STALE_ORACLE(uint8(Enums.OracleType.Chainlink), _feedAddr, block.timestamp - updatedAt, _staleTime);
    }
    return uint256(answer);
}

/**
 * @notice Gets answer from IAPI3 type feed.
 * @param _feedAddr The feed address.
 * @param _staleTime Staleness threshold.
 * @return uint256 Parsed answer from the feed, 0 if its stale.
 */
function API3Price(address _feedAddr, uint256 _staleTime) view returns (uint256) {
    (int256 answer, uint256 updatedAt) = IAPI3(_feedAddr).read();
    if (answer < 0) {
        revert Errors.NEGATIVE_PRICE(_feedAddr, answer);
    }
    // IMPORTANT: Returning zero when answer is stale, to activate fallback oracle.
    if (block.timestamp - updatedAt > _staleTime) {
        revert Errors.STALE_ORACLE(uint8(Enums.OracleType.API3), _feedAddr, block.timestamp - updatedAt, _staleTime);
    }
    return fromWad(uint256(answer), cs().oracleDecimals); // API3 returns 18 decimals always.
}

/* -------------------------------------------------------------------------- */
/*                                    Util                                    */
/* -------------------------------------------------------------------------- */

/**
 * @notice Gets raw answer info from AggregatorV3 type feed.
 * @param _config Configuration for the oracle.
 * @return RawPrice Unparsed answer with metadata.
 */
function aggregatorV3RawPrice(Oracle memory _config) view returns (RawPrice memory) {
    (, int256 answer, , uint256 updatedAt, ) = IAggregatorV3(_config.feed).latestRoundData();
    bool isStale = block.timestamp - updatedAt > _config.staleTime;
    return RawPrice(answer, updatedAt, _config.staleTime, isStale, answer == 0, Enums.OracleType.Chainlink, _config.feed);
}

/**
 * @notice Gets raw answer info from IAPI3 type feed.
 * @param _config Configuration for the oracle.
 * @return RawPrice Unparsed answer with metadata.
 */
function API3RawPrice(Oracle memory _config) view returns (RawPrice memory) {
    (int256 answer, uint256 updatedAt) = IAPI3(_config.feed).read();
    bool isStale = block.timestamp - updatedAt > _config.staleTime;
    return RawPrice(answer, updatedAt, _config.staleTime, isStale, answer == 0, Enums.OracleType.API3, _config.feed);
}

/**
 * @notice Return raw answer info from the oracles provided
 * @param _oracles Oracles to check.
 * @param _ticker Ticker for the asset.
 * @return RawPrice Unparsed answer with metadata.
 */
function pushPrice(Enums.OracleType[2] memory _oracles, bytes32 _ticker) view returns (RawPrice memory) {
    for (uint256 i; i < _oracles.length; i++) {
        Enums.OracleType oracleType = _oracles[i];
        Oracle storage oracle = cs().oracles[_ticker][_oracles[i]];

        if (oracleType == Enums.OracleType.Chainlink) return aggregatorV3RawPrice(oracle);
        if (oracleType == Enums.OracleType.API3) return API3RawPrice(oracle);
        if (oracleType == Enums.OracleType.Vault) {
            int256 answer = int256(vaultPrice(oracle.feed));
            return RawPrice(answer, block.timestamp, 0, false, answer == 0, Enums.OracleType.Vault, oracle.feed);
        }
    }

    // Revert if no answer is found
    revert Errors.NO_PUSH_ORACLE_SET(_ticker.toString());
}

function viewPrice(bytes32 _ticker, PythView calldata views) view returns (RawPrice memory) {
    Oracle memory config;

    if (_ticker == bytes32("KISS")) {
        config = cs().oracles[_ticker][Enums.OracleType.Vault];
        int256 answer = int256(vaultPrice(config.feed));
        return RawPrice(answer, block.timestamp, 0, false, answer == 0, Enums.OracleType.Vault, config.feed);
    }

    config = cs().oracles[_ticker][Enums.OracleType.Pyth];

    for (uint256 i; i < views.ids.length; i++) {
        if (views.ids[i] == config.pythId) {
            IPyth.Price memory _price = views.prices[i];
            RawPrice memory result = RawPrice(
                int256(
                    !config.invertPyth
                        ? normalizePythPrice(_price, cs().oracleDecimals)
                        : invertNormalizePythPrice(_price, cs().oracleDecimals)
                ),
                _price.timestamp,
                config.staleTime,
                false,
                _price.price == 0,
                Enums.OracleType.Pyth,
                address(0)
            );
            return result;
        }
    }

    revert Errors.NO_VIEW_PRICE_AVAILABLE(_ticker.toString());
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC165} from "vendor/IERC165.sol";
import {IKreskoAssetIssuer} from "kresko-asset/IKreskoAssetIssuer.sol";
import {IVaultExtender} from "vault/interfaces/IVaultExtender.sol";
import {IERC20Permit} from "kresko-lib/token/IERC20Permit.sol";

interface IKISS is IERC20Permit, IVaultExtender, IKreskoAssetIssuer, IERC165 {
    function vKISS() external view returns (address);

    function kresko() external view returns (address);

    /**
     * @notice This function adds KISS to circulation
     * Caller must be a contract and have the OPERATOR_ROLE
     * @param _amount amount to mint
     * @param _to address to mint tokens to
     * @return uint256 amount minted
     */
    function issue(uint256 _amount, address _to) external override returns (uint256);

    /**
     * @notice This function removes KISS from circulation
     * Caller must be a contract and have the OPERATOR_ROLE
     * @param _amount amount to burn
     * @param _from address to burn tokens from
     * @return uint256 amount burned
     *
     * @inheritdoc IKreskoAssetIssuer
     */
    function destroy(uint256 _amount, address _from) external override returns (uint256);

    /**
     * @notice Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external;

    /**
     * @notice  Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external;

    /**
     * @notice Exchange rate of vKISS to USD.
     * @return rate vKISS/USD exchange rate.
     * @custom:signature exchangeRate()
     * @custom:selector 0x3ba0b9a9
     */
    function exchangeRate() external view returns (uint256 rate);

    /**
     * @notice Overrides `AccessControl.grantRole` for following:
     * @notice EOA cannot be granted Role.OPERATOR role
     * @param _role role to grant
     * @param _to address to grant role for
     */
    function grantRole(bytes32 _role, address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketStatus {
    function allowed(address) external view returns (bool);

    function exchanges(bytes32) external view returns (bytes32);

    function status(bytes32) external view returns (uint256);

    function setStatus(bytes32[] calldata, bool[] calldata) external;

    function setTickers(bytes32[] calldata, bytes32[] calldata) external;

    function setAllowed(address, bool) external;

    function getExchangeStatus(bytes32) external view returns (bool);

    function getExchangeStatuses(bytes32[] calldata) external view returns (bool[] memory);

    function getExchange(bytes32) external view returns (bytes32);

    function getTickerStatus(bytes32) external view returns (bool);

    function getTickerExchange(bytes32) external view returns (bytes32);

    function getTickerStatuses(bytes32[] calldata) external view returns (bool[] memory);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// These functions are expected to be called frequently
/// by tools.

struct Facet {
    address facetAddress;
    bytes4[] functionSelectors;
}

struct FacetAddressAndPosition {
    address facetAddress;
    // position in facetFunctionSelectors.functionSelectors array
    uint96 functionSelectorPosition;
}

struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    // position of facetAddress in facetAddresses array
    uint256 facetAddressPosition;
}

/// @dev  Add=0, Replace=1, Remove=2
enum FacetCutAction {
    Add,
    Replace,
    Remove
}

struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
}

struct Initializer {
    address initContract;
    bytes initData;
}

// SPDX-License-Identifier: MIT
/* solhint-disable no-inline-assembly */

pragma solidity 0.8.23;
import {Errors} from "common/Errors.sol";

library Meta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        /// @solidity memory-safe-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert Errors.ADDRESS_HAS_NO_CODE(_contract);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function latestAnswer() external view returns (int256);

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

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;
import {IERC165} from "vendor/IERC165.sol";
import {IERC20} from "kresko-lib/token/IERC20.sol";
import {IKreskoAsset} from "kresko-asset/IKreskoAsset.sol";
import {IKreskoAssetIssuer} from "kresko-asset/IKreskoAssetIssuer.sol";
import {IKISS} from "kiss/interfaces/IKISS.sol";

import {Strings} from "libs/Strings.sol";
import {PercentageMath} from "libs/PercentageMath.sol";

import {Errors} from "common/Errors.sol";
import {Asset, RawPrice} from "common/Types.sol";
import {Role, Percents, Constants} from "common/Constants.sol";
import {cs} from "common/State.sol";
import {pushPrice} from "common/funcs/Prices.sol";

import {scdp} from "scdp/SState.sol";
import {ms, MinterState} from "minter/MState.sol";

// solhint-disable code-complexity
library Validations {
    using PercentageMath for uint256;
    using PercentageMath for uint16;
    using Strings for bytes32;

    function validatePriceDeviationPct(uint16 _deviationPct) internal pure {
        if (_deviationPct > Percents.MAX_DEVIATION) {
            revert Errors.INVALID_ORACLE_DEVIATION(_deviationPct, Percents.MAX_DEVIATION);
        }
    }

    function validateMinDebtValue(uint256 _minDebtValue) internal pure {
        if (_minDebtValue > Constants.MAX_MIN_DEBT_VALUE) {
            revert Errors.INVALID_MIN_DEBT(_minDebtValue, Constants.MAX_MIN_DEBT_VALUE);
        }
    }

    function validateFeeRecipient(address _feeRecipient) internal pure {
        if (_feeRecipient == address(0)) revert Errors.INVALID_FEE_RECIPIENT(_feeRecipient);
    }

    function validateOraclePrecision(uint256 _decimalPrecision) internal pure {
        if (_decimalPrecision < Constants.MIN_ORACLE_DECIMALS) {
            revert Errors.INVALID_PRICE_PRECISION(_decimalPrecision, Constants.MIN_ORACLE_DECIMALS);
        }
    }

    function validateCoverThreshold(uint256 _coverThreshold, uint256 _mcr) internal pure {
        if (_coverThreshold > _mcr) {
            revert Errors.INVALID_COVER_THRESHOLD(_coverThreshold, _mcr);
        }
    }

    function validateCoverIncentive(uint256 _coverIncentive) internal pure {
        if (_coverIncentive > Percents.MAX_LIQ_INCENTIVE || _coverIncentive < Percents.HUNDRED) {
            revert Errors.INVALID_COVER_INCENTIVE(_coverIncentive, Percents.HUNDRED, Percents.MAX_LIQ_INCENTIVE);
        }
    }

    function validateMinCollateralRatio(uint256 _minCollateralRatio, uint256 _liqThreshold) internal pure {
        if (_minCollateralRatio < Percents.MIN_MCR) {
            revert Errors.INVALID_MCR(_minCollateralRatio, Percents.MIN_MCR);
        }
        // this should never be hit, but just in case
        if (_liqThreshold >= _minCollateralRatio) {
            revert Errors.INVALID_MCR(_minCollateralRatio, _liqThreshold);
        }
    }

    function validateLiquidationThreshold(uint256 _liqThreshold, uint256 _minCollateralRatio) internal pure {
        if (_liqThreshold < Percents.MIN_LT || _liqThreshold >= _minCollateralRatio) {
            revert Errors.INVALID_LIQ_THRESHOLD(_liqThreshold, Percents.MIN_LT, _minCollateralRatio);
        }
    }

    function validateMaxLiquidationRatio(uint256 _maxLiqRatio, uint256 _liqThreshold) internal pure {
        if (_maxLiqRatio < _liqThreshold) {
            revert Errors.MLR_CANNOT_BE_LESS_THAN_LIQ_THRESHOLD(_maxLiqRatio, _liqThreshold);
        }
    }

    function validateAddAssetArgs(
        address _assetAddr,
        Asset memory _config
    ) internal view returns (string memory symbol, string memory tickerStr, uint8 decimals) {
        if (_assetAddr == address(0)) revert Errors.ZERO_ADDRESS();

        symbol = IERC20(_assetAddr).symbol();
        if (cs().assets[_assetAddr].exists()) revert Errors.ASSET_ALREADY_EXISTS(Errors.ID(symbol, _assetAddr));

        tickerStr = _config.ticker.toString();
        if (_config.ticker == Constants.ZERO_BYTES32) revert Errors.INVALID_TICKER(Errors.ID(symbol, _assetAddr), tickerStr);

        decimals = IERC20(_assetAddr).decimals();
        validateDecimals(_assetAddr, decimals);
    }

    function validateUpdateAssetArgs(
        address _assetAddr,
        Asset memory _config
    ) internal view returns (string memory symbol, string memory tickerStr, Asset storage asset) {
        if (_assetAddr == address(0)) revert Errors.ZERO_ADDRESS();

        symbol = IERC20(_assetAddr).symbol();
        asset = cs().assets[_assetAddr];

        if (!asset.exists()) revert Errors.ASSET_DOES_NOT_EXIST(Errors.ID(symbol, _assetAddr));

        tickerStr = _config.ticker.toString();
        if (_config.ticker == Constants.ZERO_BYTES32) revert Errors.INVALID_TICKER(Errors.ID(symbol, _assetAddr), tickerStr);
    }

    function validateAsset(address _assetAddr, Asset memory _config) internal view returns (bool) {
        validateMinterCollateral(_assetAddr, _config);
        validateMinterKrAsset(_assetAddr, _config);
        validateSCDPDepositAsset(_assetAddr, _config);
        validateSCDPKrAsset(_assetAddr, _config);
        validatePushPrice(_assetAddr);
        validateLiqConfig(_assetAddr);
        return true;
    }

    function validateMinterCollateral(
        address _assetAddr,
        Asset memory _config
    ) internal view returns (bool isMinterCollateral) {
        if (_config.isMinterCollateral) {
            validateCFactor(_assetAddr, _config.factor);
            validateLiqIncentive(_assetAddr, _config.liqIncentive);
            return true;
        }
    }

    function validateSCDPDepositAsset(
        address _assetAddr,
        Asset memory _config
    ) internal view returns (bool isSharedCollateral) {
        if (_config.isSharedCollateral) {
            validateCFactor(_assetAddr, _config.factor);
            return true;
        }
    }

    function validateMinterKrAsset(address _assetAddr, Asset memory _config) internal view returns (bool isMinterKrAsset) {
        if (_config.isMinterMintable) {
            validateKFactor(_assetAddr, _config.kFactor);
            validateFees(_assetAddr, _config.openFee, _config.closeFee);
            validateKrAssetContract(_assetAddr, _config.anchor);
            return true;
        }
    }

    function validateSCDPKrAsset(address _assetAddr, Asset memory _config) internal view returns (bool isSwapMintable) {
        if (_config.isSwapMintable) {
            validateFees(_assetAddr, _config.swapInFeeSCDP, _config.swapOutFeeSCDP);
            validateFees(_assetAddr, _config.protocolFeeShareSCDP, _config.protocolFeeShareSCDP);
            validateLiqIncentive(_assetAddr, _config.liqIncentiveSCDP);
            return true;
        }
    }

    function validateSDICoverAsset(address _assetAddr) internal view returns (Asset storage asset) {
        asset = cs().assets[_assetAddr];
        if (!asset.exists()) revert Errors.ASSET_DOES_NOT_EXIST(Errors.id(_assetAddr));
        if (asset.isCoverAsset) revert Errors.ASSET_ALREADY_ENABLED(Errors.id(_assetAddr));
        validatePushPrice(_assetAddr);
    }

    function validateKrAssetContract(address _assetAddr, address _anchorAddr) internal view {
        IERC165 asset = IERC165(_assetAddr);
        if (!asset.supportsInterface(type(IKISS).interfaceId) && !asset.supportsInterface(type(IKreskoAsset).interfaceId)) {
            revert Errors.INVALID_CONTRACT_KRASSET(Errors.id(_assetAddr));
        }
        if (!IERC165(_anchorAddr).supportsInterface(type(IKreskoAssetIssuer).interfaceId)) {
            revert Errors.INVALID_CONTRACT_KRASSET_ANCHOR(Errors.id(_anchorAddr), Errors.id(_assetAddr));
        }
        if (!IKreskoAsset(_assetAddr).hasRole(Role.OPERATOR, address(this))) {
            revert Errors.INVALID_KRASSET_OPERATOR(
                Errors.id(_assetAddr),
                address(this),
                IKreskoAsset(_assetAddr).getRoleMember(Role.OPERATOR, 0)
            );
        }
    }

    function ensureUnique(address _asset1Addr, address _asset2Addr) internal view {
        if (_asset1Addr == _asset2Addr) revert Errors.IDENTICAL_ASSETS(Errors.id(_asset1Addr));
    }

    function validateRoute(address _assetInAddr, address _assetOutAddr) internal view {
        if (!scdp().isRoute[_assetInAddr][_assetOutAddr])
            revert Errors.SWAP_ROUTE_NOT_ENABLED(Errors.id(_assetInAddr), Errors.id(_assetOutAddr));
    }

    function validateDecimals(address _assetAddr, uint8 _decimals) internal view {
        if (_decimals == 0) {
            revert Errors.INVALID_DECIMALS(Errors.id(_assetAddr), _decimals);
        }
    }

    function validateVaultAssetDecimals(address _assetAddr, uint8 _decimals) internal view {
        if (_decimals == 0) {
            revert Errors.INVALID_DECIMALS(Errors.id(_assetAddr), _decimals);
        }
        if (_decimals > 18) revert Errors.INVALID_DECIMALS(Errors.id(_assetAddr), _decimals);
    }

    function validateUint128(address _assetAddr, uint256 _value) internal view {
        if (_value > type(uint128).max) {
            revert Errors.UINT128_OVERFLOW(Errors.id(_assetAddr), _value, type(uint128).max);
        }
    }

    function validateCFactor(address _assetAddr, uint16 _cFactor) internal view {
        if (_cFactor > Percents.HUNDRED) {
            revert Errors.INVALID_CFACTOR(Errors.id(_assetAddr), _cFactor, Percents.HUNDRED);
        }
    }

    function validateKFactor(address _assetAddr, uint16 _kFactor) internal view {
        if (_kFactor < Percents.HUNDRED) {
            revert Errors.INVALID_KFACTOR(Errors.id(_assetAddr), _kFactor, Percents.HUNDRED);
        }
    }

    function validateFees(address _assetAddr, uint16 _fee1, uint16 _fee2) internal view {
        if (_fee1 + _fee2 > Percents.HUNDRED) {
            revert Errors.INVALID_FEE(Errors.id(_assetAddr), _fee1 + _fee2, Percents.HUNDRED);
        }
    }

    function validateLiqIncentive(address _assetAddr, uint16 _liqIncentive) internal view {
        if (_liqIncentive > Percents.MAX_LIQ_INCENTIVE || _liqIncentive < Percents.MIN_LIQ_INCENTIVE) {
            revert Errors.INVALID_LIQ_INCENTIVE(
                Errors.id(_assetAddr),
                _liqIncentive,
                Percents.MIN_LIQ_INCENTIVE,
                Percents.MAX_LIQ_INCENTIVE
            );
        }
    }

    function validateLiqConfig(address _assetAddr) internal view {
        Asset storage asset = cs().assets[_assetAddr];
        if (asset.isMinterMintable) {
            address[] memory minterCollaterals = ms().collaterals;
            for (uint256 i; i < minterCollaterals.length; i++) {
                address collateralAddr = minterCollaterals[i];
                Asset storage collateral = cs().assets[collateralAddr];
                validateLiquidationMarket(collateralAddr, collateral, _assetAddr, asset);
                validateLiquidationMarket(_assetAddr, asset, collateralAddr, collateral);
            }
        }

        if (asset.isMinterCollateral) {
            address[] memory minterKrAssets = ms().krAssets;
            for (uint256 i; i < minterKrAssets.length; i++) {
                address krAssetAddr = minterKrAssets[i];
                Asset storage krAsset = cs().assets[krAssetAddr];
                validateLiquidationMarket(_assetAddr, asset, krAssetAddr, krAsset);
                validateLiquidationMarket(krAssetAddr, krAsset, _assetAddr, asset);
            }
        }

        if (asset.isSharedOrSwappedCollateral) {
            address[] memory scdpKrAssets = scdp().krAssets;
            for (uint256 i; i < scdpKrAssets.length; i++) {
                address scdpKrAssetAddr = scdpKrAssets[i];
                Asset storage scdpKrAsset = cs().assets[scdpKrAssetAddr];
                validateLiquidationMarket(_assetAddr, asset, scdpKrAssetAddr, scdpKrAsset);
                validateLiquidationMarket(scdpKrAssetAddr, scdpKrAsset, _assetAddr, asset);
            }
        }

        if (asset.isSwapMintable) {
            address[] memory scdpCollaterals = scdp().collaterals;
            for (uint256 i; i < scdpCollaterals.length; i++) {
                address scdpCollateralAddr = scdpCollaterals[i];
                Asset storage scdpCollateral = cs().assets[scdpCollateralAddr];
                validateLiquidationMarket(_assetAddr, asset, scdpCollateralAddr, scdpCollateral);
                validateLiquidationMarket(scdpCollateralAddr, scdpCollateral, _assetAddr, asset);
            }
        }
    }

    function validateLiquidationMarket(
        address _seizeAssetAddr,
        Asset storage seizeAsset,
        address _repayAssetAddr,
        Asset storage repayAsset
    ) internal view {
        if (seizeAsset.isSharedOrSwappedCollateral && repayAsset.isSwapMintable) {
            uint256 seizeReductionPct = (repayAsset.liqIncentiveSCDP.percentMul(seizeAsset.factor));
            uint256 repayIncreasePct = (repayAsset.kFactor.percentMul(scdp().maxLiquidationRatio));
            if (seizeReductionPct >= repayIncreasePct) {
                revert Errors.SCDP_ASSET_ECONOMY(
                    Errors.id(_seizeAssetAddr),
                    seizeReductionPct,
                    Errors.id(_repayAssetAddr),
                    repayIncreasePct
                );
            }
        }
        if (seizeAsset.isMinterCollateral && repayAsset.isMinterMintable) {
            uint256 seizeReductionPct = (seizeAsset.liqIncentive.percentMul(seizeAsset.factor)) + repayAsset.closeFee;
            uint256 repayIncreasePct = (repayAsset.kFactor.percentMul(ms().maxLiquidationRatio));
            if (seizeReductionPct >= repayIncreasePct) {
                revert Errors.MINTER_ASSET_ECONOMY(
                    Errors.id(_seizeAssetAddr),
                    seizeReductionPct,
                    Errors.id(_repayAssetAddr),
                    repayIncreasePct
                );
            }
        }
    }

    function validateCollateralArgs(
        MinterState storage self,
        address _account,
        address _collateralAsset,
        uint256 _collateralIndex,
        uint256 _amount
    ) internal view {
        if (_amount == 0) revert Errors.ZERO_AMOUNT(Errors.id(_collateralAsset));
        if (_collateralIndex > self.depositedCollateralAssets[_account].length - 1)
            revert Errors.ARRAY_INDEX_OUT_OF_BOUNDS(
                Errors.id(_collateralAsset),
                _collateralIndex,
                self.depositedCollateralAssets[_account]
            );
    }

    function getPushOraclePrice(Asset storage self) internal view returns (RawPrice memory) {
        return pushPrice(self.oracles, self.ticker);
    }

    function validatePushPrice(address _assetAddr) internal view {
        Asset storage asset = cs().assets[_assetAddr];
        RawPrice memory result = getPushOraclePrice(asset);
        if (result.answer <= 0) {
            revert Errors.ZERO_OR_NEGATIVE_PUSH_PRICE(
                Errors.id(_assetAddr),
                asset.ticker.toString(),
                result.answer,
                uint8(result.oracle),
                result.feed
            );
        }
        if (result.isStale) {
            revert Errors.STALE_PUSH_PRICE(
                Errors.id(_assetAddr),
                asset.ticker.toString(),
                result.answer,
                uint8(result.oracle),
                result.feed,
                block.timestamp - result.timestamp,
                result.staleTime
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library SEvent {
    event SCDPDeposit(
        address indexed depositor,
        address indexed collateralAsset,
        uint256 amount,
        uint256 feeIndex,
        uint256 timestamp
    );
    event SCDPWithdraw(
        address indexed account,
        address indexed receiver,
        address indexed collateralAsset,
        address withdrawer,
        uint256 amount,
        uint256 feeIndex,
        uint256 timestamp
    );
    event SCDPFeeReceipt(
        address indexed account,
        address indexed collateralAsset,
        uint256 accDeposits,
        uint256 assetFeeIndex,
        uint256 accFeeIndex,
        uint256 assetLiqIndex,
        uint256 accLiqIndex,
        uint256 blockNumber,
        uint256 timestamp
    );
    event SCDPFeeClaim(
        address indexed claimer,
        address indexed receiver,
        address indexed collateralAsset,
        uint256 feeAmount,
        uint256 newIndex,
        uint256 prevIndex,
        uint256 timestamp
    );
    event SCDPRepay(
        address indexed repayer,
        address indexed repayKreskoAsset,
        uint256 repayAmount,
        address indexed receiveKreskoAsset,
        uint256 receiveAmount,
        uint256 timestamp
    );

    event SCDPLiquidationOccured(
        address indexed liquidator,
        address indexed repayKreskoAsset,
        uint256 repayAmount,
        address indexed seizeCollateral,
        uint256 seizeAmount,
        uint256 prevLiqIndex,
        uint256 newLiqIndex,
        uint256 timestamp
    );
    event SCDPCoverOccured(
        address indexed coverer,
        address indexed coverAsset,
        uint256 coverAmount,
        address indexed seizeCollateral,
        uint256 seizeAmount,
        uint256 prevLiqIndex,
        uint256 newLiqIndex,
        uint256 timestamp
    );

    // Emitted when a swap pair is disabled / enabled.
    event PairSet(address indexed assetIn, address indexed assetOut, bool enabled);
    // Emitted when a kresko asset fee is updated.
    event FeeSet(address indexed _asset, uint256 openFee, uint256 closeFee, uint256 protocolFee);

    // Emitted when a collateral is updated.
    event SCDPCollateralUpdated(address indexed _asset, uint256 liquidationThreshold);

    // Emitted when a kresko asset is updated.
    event SCDPKrAssetUpdated(
        address indexed _asset,
        uint256 openFee,
        uint256 closeFee,
        uint256 protocolFee,
        uint256 maxDebtMinter
    );

    event Swap(
        address indexed who,
        address indexed assetIn,
        address indexed assetOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp
    );
    event SwapFee(
        address indexed feeAsset,
        address indexed assetIn,
        uint256 feeAmount,
        uint256 protocolFeeAmount,
        uint256 timestamp
    );

    event Income(address asset, uint256 amount);

    /**
     * @notice Emitted when the liquidation incentive multiplier is updated for a swappable krAsset.
     * @param symbol Asset symbol
     * @param asset The krAsset asset updated.
     * @param from Previous value.
     * @param to New value.
     */
    event SCDPLiquidationIncentiveUpdated(string indexed symbol, address indexed asset, uint256 from, uint256 to);

    /**
     * @notice Emitted when the minimum collateralization ratio is updated for the SCDP.
     * @param from Previous value.
     * @param to New value.
     */
    event SCDPMinCollateralRatioUpdated(uint256 from, uint256 to);

    /**
     * @notice Emitted when the liquidation threshold value is updated
     * @param from Previous value.
     * @param to New value.
     * @param mlr The new max liquidation ratio.
     */
    event SCDPLiquidationThresholdUpdated(uint256 from, uint256 to, uint256 mlr);

    /**
     * @notice Emitted when the max liquidation ratio is updated
     * @param from Previous value.
     * @param to New value.
     */
    event SCDPMaxLiquidationRatioUpdated(uint256 from, uint256 to);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/extensions/IAccessControlEnumerable.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "../IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20} from "./IERC20.sol";

/* solhint-disable func-name-mixedcase */

interface IERC20Permit is IERC20 {
    error PERMIT_DEADLINE_EXPIRED(address, address, uint256, uint256);
    error INVALID_SIGNER(address, address);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IKreskoAsset} from "./IKreskoAsset.sol";

interface IERC4626Upgradeable {
    /**
     * @notice The underlying Kresko Asset
     */
    function asset() external view returns (IKreskoAsset);

    /**
     * @notice Deposit KreskoAssets for equivalent amount of anchor tokens
     * @param assets Amount of KreskoAssets to deposit
     * @param receiver Address to send shares to
     * @return shares Amount of shares minted
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @notice Withdraw KreskoAssets for equivalent amount of anchor tokens
     * @param assets Amount of KreskoAssets to withdraw
     * @param receiver Address to send KreskoAssets to
     * @param owner Address to burn shares from
     * @return shares Amount of shares burned
     * @dev shares are burned from owner, not msg.sender
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    function maxDeposit(address) external view returns (uint256);

    function maxMint(address) external view returns (uint256 assets);

    function maxRedeem(address owner) external view returns (uint256 assets);

    function maxWithdraw(address owner) external view returns (uint256 assets);

    /**
     * @notice Mint shares of anchor tokens for equivalent amount of KreskoAssets
     * @param shares Amount of shares to mint
     * @param receiver Address to send shares to
     * @return assets Amount of KreskoAssets redeemed
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    function previewMint(uint256 shares) external view returns (uint256 assets);

    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Track the underlying amount
     * @return Total supply for the underlying
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Redeem shares of anchor for KreskoAssets
     * @param shares Amount of shares to redeem
     * @param receiver Address to send KreskoAssets to
     * @param owner Address to burn shares from
     * @return assets Amount of KreskoAssets redeemed
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev See DapiProxy.sol for comments about usage
interface IAPI3 {
    function read() external view returns (int224 value, uint32 timestamp);

    function api3ServerV1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IVaultRateProvider
 * @author Kresko
 * @notice Minimal exchange rate interface for vaults.
 */
interface IVaultRateProvider {
    /**
     * @notice Gets the exchange rate of one vault share to USD.
     * @return uint256 The current exchange rate of the vault share in 18 decimals precision.
     */
    function exchangeRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import {BitmapLib, SignatureLib, RedstoneError, RedstoneDefaultsLib} from "./RedstoneInternals.sol";

// solhint-disable no-empty-blocks
// solhint-disable avoid-low-level-calls

// === Abbreviations ===
// BS - Bytes size
// PTR - Pointer (memory location)
// SIG - Signature

library Redstone {
    struct CalldataExtract {
        bytes32[] dataFeedIds;
        uint256[] uniqueSignerCountForDataFeedIds;
        uint256[] signersBitmapForDataFeedIds;
        uint256[][] valuesForDataFeeds;
        uint256 calldataNegativeOffset;
    }
    // Solidity and YUL constants
    uint256 internal constant STANDARD_SLOT_BS = 32;
    uint256 internal constant FREE_MEMORY_PTR = 0x40;
    uint256 internal constant BYTES_ARR_LEN_VAR_BS = 32;
    uint256 internal constant FUNCTION_SIGNATURE_BS = 4;
    uint256 internal constant REVERT_MSG_OFFSET = 68; // Revert message structure described here: https://ethereum.stackexchange.com/a/66173/106364
    uint256 internal constant STRING_ERR_MESSAGE_MASK = 0x08c379a000000000000000000000000000000000000000000000000000000000;

    // RedStone protocol consts
    uint256 internal constant SIG_BS = 65;
    uint256 internal constant TIMESTAMP_BS = 6;
    uint256 internal constant DATA_PACKAGES_COUNT_BS = 2;
    uint256 internal constant DATA_POINTS_COUNT_BS = 3;
    uint256 internal constant DATA_POINT_VALUE_BYTE_SIZE_BS = 4;
    uint256 internal constant DATA_POINT_SYMBOL_BS = 32;
    uint256 internal constant DEFAULT_DATA_POINT_VALUE_BS = 32;
    uint256 internal constant UNSIGNED_METADATA_BYTE_SIZE_BS = 3;
    uint256 internal constant REDSTONE_MARKER_BS = 9; // byte size of 0x000002ed57011e0000
    uint256 internal constant REDSTONE_MARKER_MASK = 0x0000000000000000000000000000000000000000000000000002ed57011e0000;

    // Derived values (based on consts)
    uint256 internal constant TIMESTAMP_NEGATIVE_OFFSET_IN_DATA_PACKAGE_WITH_STANDARD_SLOT_BS = 104; // SIG_BS + DATA_POINTS_COUNT_BS + DATA_POINT_VALUE_BYTE_SIZE_BS + STANDARD_SLOT_BS
    uint256 internal constant DATA_PACKAGE_WITHOUT_DATA_POINTS_BS = 78; // DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS + SIG_BS
    uint256 internal constant DATA_PACKAGE_WITHOUT_DATA_POINTS_AND_SIG_BS = 13; // DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS
    uint256 internal constant REDSTONE_MARKER_BS_PLUS_STANDARD_SLOT_BS = 41; // REDSTONE_MARKER_BS + STANDARD_SLOT_BS

    // using SafeMath for uint256;
    // inside unchecked these functions are still checked
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    using {sub, add} for uint256;

    /**
     * @dev This function can be used in a consumer contract to securely extract an
     * oracle value for a given data feed id. Security is achieved by
     * signatures verification, timestamp validation, and aggregating values
     * from different authorised signers into a single numeric value. If any of the
     * required conditions do not match, the function will revert.
     * Note! This function expects that tx calldata contains redstone payload in the end
     * Learn more about redstone payload here: https://github.com/redstone-finance/redstone-oracles-monorepo/tree/main/packages/evm-connector#readme
     * @param dataFeedId bytes32 value that uniquely identifies the data feed
     * @return Extracted and verified numeric oracle value for the given data feed id
     */
    function getPrice(bytes32 dataFeedId, uint256 _staleTime) internal view returns (uint256) {
        bytes32[] memory dataFeedIds = new bytes32[](1);
        dataFeedIds[0] = dataFeedId;
        return _securelyExtractOracleValuesFromTxMsg(dataFeedIds, _staleTime)[0];
    }

    function getAuthorisedSignerIndex(address signerAddress) internal pure returns (uint8) {
        if (signerAddress == 0x926E370fD53c23f8B71ad2B3217b227E41A92b12) return 0;
        if (signerAddress == 0x0C39486f770B26F5527BBBf942726537986Cd7eb) return 1;
        // For testing hardhat signer 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 is authorised
        // will be removed in production deployment
        if (signerAddress == 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) return 2;

        revert RedstoneError.SignerNotAuthorised(signerAddress);
    }

    /**
     * @dev This function can be used in a consumer contract to securely extract several
     * numeric oracle values for a given array of data feed ids. Security is achieved by
     * signatures verification, timestamp validation, and aggregating values
     * from different authorised signers into a single numeric value. If any of the
     * required conditions do not match, the function will revert.
     * Note! This function expects that tx calldata contains redstone payload in the end
     * Learn more about redstone payload here: https://github.com/redstone-finance/redstone-oracles-monorepo/tree/main/packages/evm-connector#readme
     * @param dataFeedIds An array of unique data feed identifiers
     * @return An array of the extracted and verified oracle values in the same order
     * as they are requested in the dataFeedIds array
     */
    function getPrices(bytes32[] memory dataFeedIds, uint256 _staleTime) internal view returns (uint256[] memory) {
        return _securelyExtractOracleValuesFromTxMsg(dataFeedIds, _staleTime);
    }

    /**
     * @dev This function may be overridden by the child consumer contract.
     * It should validate the timestamp against the current time (block.timestamp)
     * It should revert with a helpful message if the timestamp is not valid
     * @param receivedTimestampMilliseconds Timestamp extracted from calldata
     * @param _staleTime Stale time
     */
    function validateTimestamp(uint256 receivedTimestampMilliseconds, uint256 _staleTime) internal view {
        if (receivedTimestampMilliseconds == 0) {
            revert RedstoneError.Timestamp(receivedTimestampMilliseconds, block.timestamp);
        }

        if ((block.timestamp * 1000 - receivedTimestampMilliseconds) > _staleTime * 1000) {
            revert RedstoneError.Timestamp(block.timestamp * 1000 - receivedTimestampMilliseconds, _staleTime * 1000);
        }
        // For testing this function is disabled
        // Uncomment this line to enable timestamp validation in prod
        // RedstoneDefaultsLib.validateTimestamp(receivedTimestampMilliseconds);
    }

    /**
     * @dev This function should be overridden by the child consumer contract.
     * @return The minimum required value of unique authorised signers
     */
    function getUniqueSignersThreshold() internal pure returns (uint8) {
        return 1;
    }

    /**
     * @dev This function may be overridden by the child consumer contract.
     * It should aggregate values from different signers to a single uint value.
     * By default, it calculates the median value
     * @param values An array of uint256 values from different signers
     * @return Result of the aggregation in the form of a single number
     */
    function aggregateValues(uint256[] memory values) internal pure returns (uint256) {
        return RedstoneDefaultsLib.aggregateValues(values);
    }

    /**
     * @dev This is an internal helpful function for secure extraction oracle values
     * from the tx calldata. Security is achieved by signatures verification, timestamp
     * validation, and aggregating values from different authorised signers into a
     * single numeric value. If any of the required conditions (e.g. too old timestamp or
     * insufficient number of authorised signers) do not match, the function will revert.
     *
     * Note! You should not call this function in a consumer contract. You can use
     * `getOracleNumericValuesFromTxMsg` or `getOracleNumericValueFromTxMsg` instead.
     *
     * @param dataFeedIds An array of unique data feed identifiers
     * @return An array of the extracted and verified oracle values in the same order
     * as they are requested in dataFeedIds array
     */
    function _securelyExtractOracleValuesFromTxMsg(
        bytes32[] memory dataFeedIds,
        uint256 _staleTime
    ) private view returns (uint256[] memory) {
        CalldataExtract memory args;
        // Initializing helpful variables and allocating memory
        args.dataFeedIds = dataFeedIds;
        args.uniqueSignerCountForDataFeedIds = new uint256[](dataFeedIds.length);
        args.signersBitmapForDataFeedIds = new uint256[](dataFeedIds.length);
        args.valuesForDataFeeds = new uint256[][](dataFeedIds.length);
        for (uint256 i; i < dataFeedIds.length; ) {
            // The line below is commented because newly allocated arrays are filled with zeros
            // But we left it for better readability
            // signersBitmapForDataFeedIds[i] = 0; // <- setting to an empty bitmap
            args.valuesForDataFeeds[i] = new uint256[](getUniqueSignersThreshold());

            unchecked {
                i++;
            }
        }

        // Extracting the number of data packages from calldata
        args.calldataNegativeOffset = _extractByteSizeOfUnsignedMetadata();
        uint256 dataPackagesCount = _extractDataPackagesCountFromCalldata(args.calldataNegativeOffset);
        unchecked {
            args.calldataNegativeOffset += DATA_PACKAGES_COUNT_BS;
        }

        // Saving current free memory pointer
        uint256 freeMemPtr;
        assembly {
            freeMemPtr := mload(FREE_MEMORY_PTR)
        }

        // Data packages extraction in a loop
        for (uint256 dataPackageIndex; dataPackageIndex < dataPackagesCount; ) {
            // Extract data package details and update calldata offset
            (uint256 dataPackageByteSize, uint256 timestamp) = _extractDataPackage(args);
            // Validating timestamp
            validateTimestamp(timestamp, _staleTime);
            unchecked {
                args.calldataNegativeOffset += dataPackageByteSize;
            }

            // Shifting memory pointer back to the "safe" value
            assembly {
                mstore(FREE_MEMORY_PTR, freeMemPtr)
            }

            unchecked {
                dataPackageIndex++;
            }
        }

        // Validating numbers of unique signers and calculating aggregated values for each dataFeedId
        return _getAggregatedValues(args.valuesForDataFeeds, args.uniqueSignerCountForDataFeedIds);
    }

    /**
     * @dev This is a private helpful function, which extracts data for a data package based
     * on the given negative calldata offset, verifies them, and in the case of successful
     * verification updates the corresponding data package values in memory
     *
     * @param args CalldataExtract struct with all the necessary data for the extraction
     *
     * @return An array of the aggregated values
     */
    function _extractDataPackage(CalldataExtract memory args) private pure returns (uint256, uint256) {
        (uint256 dataPointsCount, uint256 eachDataPointValueByteSize) = _extractDataPointsDetailsForDataPackage(
            args.calldataNegativeOffset
        );

        // We use scopes to resolve problem with too deep stack
        uint256 timeMillis;
        uint256 signerIndex;

        {
            bytes32 signedHash;

            unchecked {
                bytes memory signedMessage;
                uint256 signedMessageBytesCount = dataPointsCount *
                    (eachDataPointValueByteSize + DATA_POINT_SYMBOL_BS) +
                    DATA_PACKAGE_WITHOUT_DATA_POINTS_AND_SIG_BS; //DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS
                uint256 timestampCalldataOffset = msg.data.length.sub(
                    args.calldataNegativeOffset + TIMESTAMP_NEGATIVE_OFFSET_IN_DATA_PACKAGE_WITH_STANDARD_SLOT_BS
                );

                uint256 signedMessageCalldataOffset = msg.data.length.sub(
                    args.calldataNegativeOffset + SIG_BS + signedMessageBytesCount
                );

                assembly {
                    // Extracting the signed message
                    signedMessage := extractBytesFromCalldata(signedMessageCalldataOffset, signedMessageBytesCount)

                    // Hashing the signed message
                    signedHash := keccak256(add(signedMessage, BYTES_ARR_LEN_VAR_BS), signedMessageBytesCount)

                    // Extracting timestamp
                    timeMillis := calldataload(timestampCalldataOffset)

                    function initByteArray(bytesCount) -> ptr {
                        ptr := mload(FREE_MEMORY_PTR)
                        mstore(ptr, bytesCount)
                        ptr := add(ptr, BYTES_ARR_LEN_VAR_BS)
                        mstore(FREE_MEMORY_PTR, add(ptr, bytesCount))
                    }

                    function extractBytesFromCalldata(offset, bytesCount) -> extractedBytes {
                        let extractedBytesStartPtr := initByteArray(bytesCount)
                        calldatacopy(extractedBytesStartPtr, offset, bytesCount)
                        extractedBytes := sub(extractedBytesStartPtr, BYTES_ARR_LEN_VAR_BS)
                    }
                }
            }

            // Verifying the off-chain signature against on-chain hashed data
            signerIndex = getAuthorisedSignerIndex(
                SignatureLib.recoverSignerAddress(signedHash, args.calldataNegativeOffset + SIG_BS)
            );
        }

        // Updating helpful arrays
        {
            bytes32 dataPointDataFeedId;
            uint256 dataPointValue;
            for (uint256 dataPointIndex; dataPointIndex < dataPointsCount; ) {
                // Extracting data feed id and value for the current data point
                (dataPointDataFeedId, dataPointValue) = _extractDataPointValueAndDataFeedId(
                    args.calldataNegativeOffset,
                    eachDataPointValueByteSize,
                    dataPointIndex
                );

                for (uint256 dataFeedIdIndex; dataFeedIdIndex < args.dataFeedIds.length; ) {
                    if (dataPointDataFeedId == args.dataFeedIds[dataFeedIdIndex]) {
                        uint256 bitmapSignersForDataFeedId = args.signersBitmapForDataFeedIds[dataFeedIdIndex];

                        if (
                            !BitmapLib.getBitFromBitmap(
                                bitmapSignersForDataFeedId,
                                signerIndex
                            ) /* current signer was not counted for current dataFeedId */ &&
                            args.uniqueSignerCountForDataFeedIds[dataFeedIdIndex] < getUniqueSignersThreshold()
                        ) {
                            unchecked {
                                // Increase unique signer counter
                                args.uniqueSignerCountForDataFeedIds[dataFeedIdIndex]++;

                                // Add new value
                                args.valuesForDataFeeds[dataFeedIdIndex][
                                    args.uniqueSignerCountForDataFeedIds[dataFeedIdIndex] - 1
                                ] = dataPointValue;
                            }
                            // Update signers bitmap
                            args.signersBitmapForDataFeedIds[dataFeedIdIndex] = BitmapLib.setBitInBitmap(
                                bitmapSignersForDataFeedId,
                                signerIndex
                            );
                        }

                        // Breaking, as there couldn't be several indexes for the same feed ID
                        break;
                    }
                    unchecked {
                        dataFeedIdIndex++;
                    }
                }
                unchecked {
                    dataPointIndex++;
                }
            }
        }

        // Return total data package byte size
        unchecked {
            return (
                DATA_PACKAGE_WITHOUT_DATA_POINTS_BS + (eachDataPointValueByteSize + DATA_POINT_SYMBOL_BS) * dataPointsCount,
                timeMillis
            );
        }
    }

    /**
     * @dev This is a private helpful function, which aggregates values from different
     * authorised signers for the given arrays of values for each data feed
     *
     * @param valuesForDataFeeds 2-dimensional array, valuesForDataFeeds[i][j] contains
     * j-th value for the i-th data feed
     * @param uniqueSignerCountForDataFeedIds an array with the numbers of unique signers
     * for each data feed
     *
     * @return An array of the aggregated values
     */
    function _getAggregatedValues(
        uint256[][] memory valuesForDataFeeds,
        uint256[] memory uniqueSignerCountForDataFeedIds
    ) private pure returns (uint256[] memory) {
        uint256[] memory aggregatedValues = new uint256[](valuesForDataFeeds.length);
        uint256 uniqueSignersThreshold = getUniqueSignersThreshold();

        for (uint256 dataFeedIndex; dataFeedIndex < valuesForDataFeeds.length; ) {
            if (uniqueSignerCountForDataFeedIds[dataFeedIndex] < uniqueSignersThreshold) {
                revert RedstoneError.InsufficientNumberOfUniqueSigners(
                    uniqueSignerCountForDataFeedIds[dataFeedIndex],
                    uniqueSignersThreshold
                );
            }
            uint256 aggregatedValueForDataFeedId = aggregateValues(valuesForDataFeeds[dataFeedIndex]);
            aggregatedValues[dataFeedIndex] = aggregatedValueForDataFeedId;
            unchecked {
                dataFeedIndex++;
            }
        }

        return aggregatedValues;
    }

    function _extractDataPointsDetailsForDataPackage(
        uint256 calldataNegativeOffsetForDataPackage
    ) private pure returns (uint256 dataPointsCount, uint256 eachDataPointValueByteSize) {
        // Using uint24, because data points count byte size number has 3 bytes
        uint24 dataPointsCount_;

        // Using uint32, because data point value byte size has 4 bytes
        uint32 eachDataPointValueByteSize_;

        // Extract data points count
        unchecked {
            uint256 negativeCalldataOffset = calldataNegativeOffsetForDataPackage + SIG_BS;
            uint256 calldataOffset = msg.data.length.sub(negativeCalldataOffset + STANDARD_SLOT_BS);
            assembly {
                dataPointsCount_ := calldataload(calldataOffset)
            }

            // Extract each data point value size
            calldataOffset = calldataOffset.sub(DATA_POINTS_COUNT_BS);
            assembly {
                eachDataPointValueByteSize_ := calldataload(calldataOffset)
            }

            // Prepare returned values
            dataPointsCount = dataPointsCount_;
            eachDataPointValueByteSize = eachDataPointValueByteSize_;
        }
    }

    function _extractByteSizeOfUnsignedMetadata() private pure returns (uint256) {
        // Checking if the calldata ends with the RedStone marker
        bool hasValidRedstoneMarker;
        assembly {
            let calldataLast32Bytes := calldataload(sub(calldatasize(), STANDARD_SLOT_BS))
            hasValidRedstoneMarker := eq(REDSTONE_MARKER_MASK, and(calldataLast32Bytes, REDSTONE_MARKER_MASK))
        }
        if (!hasValidRedstoneMarker) {
            revert RedstoneError.CalldataMustHaveValidPayload();
        }

        // Using uint24, because unsigned metadata byte size number has 3 bytes
        uint24 unsignedMetadataByteSize;
        if (REDSTONE_MARKER_BS_PLUS_STANDARD_SLOT_BS > msg.data.length) {
            revert RedstoneError.CalldataOverOrUnderFlow();
        }
        assembly {
            unsignedMetadataByteSize := calldataload(sub(calldatasize(), REDSTONE_MARKER_BS_PLUS_STANDARD_SLOT_BS))
        }
        unchecked {
            uint256 calldataNegativeOffset = unsignedMetadataByteSize + UNSIGNED_METADATA_BYTE_SIZE_BS + REDSTONE_MARKER_BS;
            if (calldataNegativeOffset + DATA_PACKAGES_COUNT_BS > msg.data.length) {
                revert RedstoneError.IncorrectUnsignedMetadataSize();
            }
            return calldataNegativeOffset;
        }
    }

    function _extractDataPackagesCountFromCalldata(
        uint256 calldataNegativeOffset
    ) private pure returns (uint16 dataPackagesCount) {
        unchecked {
            uint256 calldataNegativeOffsetWithStandardSlot = calldataNegativeOffset + STANDARD_SLOT_BS;
            if (calldataNegativeOffsetWithStandardSlot > msg.data.length) {
                revert RedstoneError.CalldataOverOrUnderFlow();
            }
            assembly {
                dataPackagesCount := calldataload(sub(calldatasize(), calldataNegativeOffsetWithStandardSlot))
            }
            return dataPackagesCount;
        }
    }

    function _extractDataPointValueAndDataFeedId(
        uint256 calldataNegativeOffsetForDataPackage,
        uint256 defaultDataPointValueByteSize,
        uint256 dataPointIndex
    ) private pure returns (bytes32 dataPointDataFeedId, uint256 dataPointValue) {
        uint256 negativeOffsetToDataPoints = calldataNegativeOffsetForDataPackage + DATA_PACKAGE_WITHOUT_DATA_POINTS_BS;
        uint256 dataPointNegativeOffset = negativeOffsetToDataPoints +
            ((1 + dataPointIndex) * ((defaultDataPointValueByteSize + DATA_POINT_SYMBOL_BS)));
        uint256 dataPointCalldataOffset = msg.data.length.sub(dataPointNegativeOffset);
        assembly {
            dataPointDataFeedId := calldataload(dataPointCalldataOffset)
            dataPointValue := calldataload(add(dataPointCalldataOffset, DATA_POINT_SYMBOL_BS))
        }
    }

    function proxyCalldata(
        address contractAddress,
        bytes memory encodedFunction,
        bool forwardValue
    ) internal returns (bytes memory) {
        bytes memory message = _prepareMessage(encodedFunction);

        (bool success, bytes memory result) = contractAddress.call{value: forwardValue ? msg.value : 0}(message);

        return _prepareReturnValue(success, result);
    }

    function proxyDelegateCalldata(address contractAddress, bytes memory encodedFunction) internal returns (bytes memory) {
        bytes memory message = _prepareMessage(encodedFunction);
        (bool success, bytes memory result) = contractAddress.delegatecall(message);
        return _prepareReturnValue(success, result);
    }

    function proxyCalldataView(address contractAddress, bytes memory encodedFunction) internal view returns (bytes memory) {
        bytes memory message = _prepareMessage(encodedFunction);
        (bool success, bytes memory result) = contractAddress.staticcall(message);
        return _prepareReturnValue(success, result);
    }

    function _prepareMessage(bytes memory encodedFunction) private pure returns (bytes memory) {
        uint256 encodedFunctionBytesCount = encodedFunction.length;
        uint256 redstonePayloadByteSize = _getRedstonePayloadByteSize();
        uint256 resultMessageByteSize = encodedFunctionBytesCount + redstonePayloadByteSize;

        if (redstonePayloadByteSize > msg.data.length) {
            revert RedstoneError.CalldataOverOrUnderFlow();
        }

        bytes memory message;

        assembly {
            message := mload(FREE_MEMORY_PTR) // sets message pointer to first free place in memory

            // Saving the byte size of the result message (it's a standard in EVM)
            mstore(message, resultMessageByteSize)

            // Copying function and its arguments
            for {
                let from := add(BYTES_ARR_LEN_VAR_BS, encodedFunction)
                let fromEnd := add(from, encodedFunctionBytesCount)
                let to := add(BYTES_ARR_LEN_VAR_BS, message)
            } lt(from, fromEnd) {
                from := add(from, STANDARD_SLOT_BS)
                to := add(to, STANDARD_SLOT_BS)
            } {
                // Copying data from encodedFunction to message (32 bytes at a time)
                mstore(to, mload(from))
            }

            // Copying redstone payload to the message bytes
            calldatacopy(
                add(message, add(BYTES_ARR_LEN_VAR_BS, encodedFunctionBytesCount)), // address
                sub(calldatasize(), redstonePayloadByteSize), // offset
                redstonePayloadByteSize // bytes length to copy
            )

            // Updating free memory pointer
            mstore(
                FREE_MEMORY_PTR,
                add(add(message, add(redstonePayloadByteSize, encodedFunctionBytesCount)), BYTES_ARR_LEN_VAR_BS)
            )
        }

        return message;
    }

    function _getRedstonePayloadByteSize() private pure returns (uint256) {
        uint256 calldataNegativeOffset = _extractByteSizeOfUnsignedMetadata();
        uint256 dataPackagesCount = _extractDataPackagesCountFromCalldata(calldataNegativeOffset);
        calldataNegativeOffset += DATA_PACKAGES_COUNT_BS;
        for (uint256 dataPackageIndex; dataPackageIndex < dataPackagesCount; ) {
            calldataNegativeOffset += _getDataPackageByteSize(calldataNegativeOffset);
            unchecked {
                dataPackageIndex++;
            }
        }

        return calldataNegativeOffset;
    }

    function _getDataPackageByteSize(uint256 calldataNegativeOffset) private pure returns (uint256) {
        (uint256 dataPointsCount, uint256 eachDataPointValueByteSize) = _extractDataPointsDetailsForDataPackage(
            calldataNegativeOffset
        );

        return dataPointsCount * (DATA_POINT_SYMBOL_BS + eachDataPointValueByteSize) + DATA_PACKAGE_WITHOUT_DATA_POINTS_BS;
    }

    function _prepareReturnValue(bool success, bytes memory result) internal pure returns (bytes memory) {
        if (!success) {
            if (result.length == 0) {
                revert RedstoneError.ProxyCalldataFailedWithoutErrMsg();
            } else {
                bool isStringErrorMessage;
                assembly {
                    let first32BytesOfResult := mload(add(result, BYTES_ARR_LEN_VAR_BS))
                    isStringErrorMessage := eq(first32BytesOfResult, STRING_ERR_MESSAGE_MASK)
                }

                if (isStringErrorMessage) {
                    string memory receivedErrMsg;
                    assembly {
                        receivedErrMsg := add(result, REVERT_MSG_OFFSET)
                    }
                    revert RedstoneError.ProxyCalldataFailedWithStringMessage(receivedErrMsg);
                } else {
                    revert RedstoneError.ProxyCalldataFailedWithCustomError(result);
                }
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {vmFFI} from "kresko-lib/utils/Base.s.sol";

import {IPyth} from "vendor/pyth/IPyth.sol";
import {JSON} from "scripts/deploy/libs/LibJSON.s.sol";

struct PythView {
    bytes32[] ids;
    IPyth.Price[] prices;
}

struct Output {
    bytes32[] ids;
    bytes[] updatedatas;
    IPyth.Price[] prices;
}

function getPythData(bytes32[] memory _ids) returns (bytes[] memory) {
    string[] memory args = new string[](3 + _ids.length);
    args[0] = "bun";
    args[1] = "utils/ffi.ts";
    args[2] = "getPythPrices";
    for (uint256 i = 0; i < _ids.length; i++) {
        args[i + 3] = vmFFI.toString(_ids[i]);
    }

    (, bytes[] memory updatedata, ) = abi.decode(vmFFI.ffi(args), (bytes32[], bytes[], IPyth.Price[]));
    return updatedata;
}

function getPythData(JSON.Config memory cfg) returns (bytes[] memory) {
    (bytes32[] memory _assets, int64[] memory mockPrices) = cfg.getMockPrices();
    if (cfg.assets.mockFeeds) {
        return getMockPythPayload(_assets, mockPrices);
    }

    string[] memory args = new string[](3 + _assets.length);
    args[0] = "bun";
    args[1] = "utils/ffi.ts";
    args[2] = "getPythPrices";
    for (uint256 i = 0; i < _assets.length; i++) {
        args[i + 3] = vmFFI.toString(_assets[i]);
    }

    (, bytes[] memory updatedata, ) = abi.decode(vmFFI.ffi(args), (bytes32[], bytes[], IPyth.Price[]));
    return updatedata;
}

function getPythData(string memory _ids) returns (bytes[] memory, PythView memory) {
    string[] memory args = new string[](4);

    args[0] = "bun";
    args[1] = "utils/ffi.ts";
    args[2] = "getPythPrices";
    args[3] = _ids;

    (bytes32[] memory ids, bytes[] memory updatedata, IPyth.Price[] memory prices) = abi.decode(
        vmFFI.ffi(args),
        (bytes32[], bytes[], IPyth.Price[])
    );
    return (updatedata, PythView(ids, prices));
}

function getMockPythPayload(bytes32[] memory _ids, int64[] memory _prices) view returns (bytes[] memory) {
    bytes[] memory _updateData = new bytes[](_ids.length);
    for (uint256 i = 0; i < _ids.length; i++) {
        _updateData[i] = abi.encode(_ids[i], IPyth.Price(_prices[i], uint64(_prices[i]) / 1000, -8, block.timestamp));
    }
    return _updateData;
}

function getPythViewData(bytes32[] memory _ids) returns (PythView memory result) {
    string[] memory args = new string[](3 + _ids.length);
    args[0] = "bun";
    args[1] = "utils/ffi.ts";
    args[2] = "getPythPrices";
    for (uint256 i = 0; i < _ids.length; i++) {
        args[i + 3] = vmFFI.toString(_ids[i]);
    }

    (bytes32[] memory ids, , IPyth.Price[] memory prices) = abi.decode(vmFFI.ffi(args), (bytes32[], bytes[], IPyth.Price[]));
    return PythView(ids, prices);
}

function getMockPythViewPrices(JSON.Config memory cfg) view returns (PythView memory result) {
    (bytes32[] memory ids, int64[] memory prices) = cfg.getMockPrices();
    require(ids.length == prices.length, "PythScript: mock price length mismatch");
    result.ids = new bytes32[](ids.length);
    result.prices = new IPyth.Price[](ids.length);
    for (uint256 i = 0; i < prices.length; i++) {
        result.ids[i] = ids[i];
        result.prices[i] = IPyth.Price({price: prices[i], conf: 1, exp: -8, timestamp: block.timestamp});
    }
}

function getPythViewData(string memory _ids) returns (PythView memory result) {
    string[] memory args = new string[](4);

    args[0] = "bun";
    args[1] = "utils/ffi.ts";
    args[2] = "getPythPrices";
    args[3] = _ids;

    (bytes32[] memory ids, , IPyth.Price[] memory prices) = abi.decode(vmFFI.ffi(args), (bytes32[], bytes[], IPyth.Price[]));
    return PythView(ids, prices);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IVaultExtender {
    event Deposit(address indexed _from, address indexed _to, uint256 _amount);
    event Withdraw(address indexed _from, address indexed _to, uint256 _amount);

    /**
     * @notice Deposit tokens to vault for shares and convert them to equal amount of extender token.
     * @param _assetAddr Supported vault asset address
     * @param _assets amount of `_assetAddr` to deposit
     * @param _receiver Address receive extender tokens
     * @return sharesOut amount of shares/extender tokens minted
     * @return assetFee amount of `_assetAddr` vault took as fee
     */
    function vaultDeposit(
        address _assetAddr,
        uint256 _assets,
        address _receiver
    ) external returns (uint256 sharesOut, uint256 assetFee);

    /**
     * @notice Deposit supported vault assets to receive `_shares`, depositing the shares for equal amount of extender token.
     * @param _assetAddr Supported vault asset address
     * @param _receiver Address receive extender tokens
     * @param _shares Amount of shares to receive
     * @return assetsIn Amount of assets for `_shares`
     * @return assetFee Amount of `_assetAddr` vault took as fee
     */

    /**
     * @notice Vault mint, an external state-modifying function.
     * @param _assetAddr The asset addr address.
     * @param _shares The shares (uint256).
     * @param _receiver The receiver address.
     * @return assetsIn An uint256 value.
     * @return assetFee An uint256 value.
     * @custom:signature vaultMint(address,uint256,address)
     * @custom:selector 0x0c8daea9
     */
    function vaultMint(
        address _assetAddr,
        uint256 _shares,
        address _receiver
    ) external returns (uint256 assetsIn, uint256 assetFee);

    /**
     * @notice Withdraw supported vault asset, burning extender tokens and withdrawing shares from vault.
     * @param _assetAddr Supported vault asset address
     * @param _assets amount of `_assetAddr` to deposit
     * @param _receiver Address receive extender tokens
     * @param _owner Owner of extender tokens
     * @return sharesIn amount of shares/extender tokens burned
     * @return assetFee amount of `_assetAddr` vault took as fee
     */
    function vaultWithdraw(
        address _assetAddr,
        uint256 _assets,
        address _receiver,
        address _owner
    ) external returns (uint256 sharesIn, uint256 assetFee);

    /**
     * @notice  Withdraw supported vault asset for  `_shares` of extender tokens.
     * @param _assetAddr Token to deposit into vault for shares.
     * @param _shares amount of extender tokens to burn
     * @param _receiver Address to receive assets withdrawn
     * @param _owner Owner of extender tokens
     * @return assetsOut amount of assets out
     * @return assetFee amount of `_assetAddr` vault took as fee
     */
    function vaultRedeem(
        address _assetAddr,
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256 assetsOut, uint256 assetFee);

    /**
     * @notice Max redeem for underlying extender token.
     * @param assetAddr The withdraw asset address.
     * @param owner The extender token owner.
     * @return max Maximum amount withdrawable.
     * @return fee Fee paid if max is withdrawn.
     * @custom:signature maxRedeem(address,address)
     * @custom:selector 0x95b734fb
     */
    function maxRedeem(address assetAddr, address owner) external view returns (uint256 max, uint256 fee);

    /**
     * @notice Deposit shares for equal amount of extender token.
     * @param _shares amount of vault shares to deposit
     * @param _receiver address to mint extender tokens to
     * @dev Does not return a value
     */
    function deposit(uint256 _shares, address _receiver) external;

    /**
     * @notice Withdraw shares for equal amount of extender token.
     * @param _amount amount of vault extender tokens to burn
     * @param _receiver address to send shares to
     * @dev Does not return a value
     */
    function withdraw(uint256 _amount, address _receiver) external;

    /**
     * @notice Withdraw shares for equal amount of extender token with allowance.
     * @param _from address to burn extender tokens from
     * @param _to address to send shares to
     * @param _amount amount to convert
     * @dev Does not return a value
     */
    function withdrawFrom(address _from, address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {IAccessControlEnumerable} from "@oz/access/extensions/IAccessControlEnumerable.sol";
import {IERC20Permit} from "kresko-lib/token/IERC20Permit.sol";
import {IERC165} from "vendor/IERC165.sol";

interface ISyncable {
    function sync() external;
}

interface IKreskoAsset is IERC20Permit, IAccessControlEnumerable, IERC165 {
    event Wrap(address indexed asset, address underlying, address indexed to, uint256 amount);
    event Unwrap(address indexed asset, address underlying, address indexed to, uint256 amount);

    /**
     * @notice Rebase information
     * @param positive supply increasing/reducing rebase
     * @param denominator the denominator for the operator, 1 ether = 1
     */
    struct Rebase {
        uint248 denominator;
        bool positive;
    }

    /**
     * @notice Wrapping information for the Kresko Asset
     * @param underlying If available, this is the corresponding on-chain underlying token.
     * @param underlyingDecimals Decimals of the underlying token.
     * @param openFee Possible fee when wrapping from underlying to KrAsset.
     * @param closeFee Possible fee when wrapping from KrAsset to underlying.
     * @param nativeUnderlyingEnabled Whether native underlying can be sent used for wrapping.
     * @param feeRecipient Fee recipient.
     */
    struct Wrapping {
        address underlying;
        uint8 underlyingDecimals;
        uint48 openFee;
        uint40 closeFee;
        bool nativeUnderlyingEnabled;
        address payable feeRecipient;
    }

    function kresko() external view returns (address);

    function rebaseInfo() external view returns (Rebase memory);

    function wrappingInfo() external view returns (Wrapping memory);

    function isRebased() external view returns (bool);

    /**
     * @notice Perform a rebase, changing the denumerator and its operator
     * @param _denominator the denumerator for the operator, 1 ether = 1
     * @param _positive supply increasing/reducing rebase
     * @param _pools UniswapV2Pair address to sync so we wont get rekt by skim() calls.
     * @dev denumerator values 0 and 1 ether will disable the rebase
     */
    function rebase(uint248 _denominator, bool _positive, address[] calldata _pools) external;

    /**
     * @notice Updates ERC20 metadata for the token in case eg. a ticker change
     * @param _name new name for the asset
     * @param _symbol new symbol for the asset
     * @param _version number that must be greater than latest emitted `Initialized` version
     */
    function reinitializeERC20(string memory _name, string memory _symbol, uint8 _version) external;

    /**
     * @notice Mints tokens to an address.
     * @dev Only callable by operator.
     * @dev Internal balances are always unrebased, events emitted are not.
     * @param _to The address to mint tokens to.
     * @param _amount The amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @notice Burns tokens from an address.
     * @dev Only callable by operator.
     * @dev Internal balances are always unrebased, events emitted are not.
     * @param _from The address to burn tokens from.
     * @param _amount The amount of tokens to burn.
     */
    function burn(address _from, uint256 _amount) external;

    /**
     * @notice Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external;

    /**
     * @notice  Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external;

    /**
     * @notice Deposit underlying tokens to receive equal value of krAsset (-fee).
     * @param _to The address to send tokens to.
     * @param _amount The amount (uint256).
     */
    function wrap(address _to, uint256 _amount) external;

    /**
     * @notice Withdraw kreskoAsset to receive underlying tokens / native (-fee).
     * @param _to The address to send unwrapped tokens to.
     * @param _amount The amount (uint256).
     * @param _receiveNative bool whether to receive underlying as native
     */
    function unwrap(address _to, uint256 _amount, bool _receiveNative) external;

    /**
     * @notice Sets anchor token address
     * @dev Has modifiers: onlyRole.
     * @param _anchor The anchor address.
     */
    function setAnchorToken(address _anchor) external;

    /**
     * @notice Enables depositing native token ETH in case of krETH
     * @dev Has modifiers: onlyRole.
     * @param _enabled The enabled (bool).
     */
    function enableNativeUnderlying(bool _enabled) external;

    /**
     * @notice Sets fee recipient address
     * @dev Has modifiers: onlyRole.
     * @param _feeRecipient The fee recipient address.
     */
    function setFeeRecipient(address _feeRecipient) external;

    /**
     * @notice Sets deposit fee
     * @dev Has modifiers: onlyRole.
     * @param _openFee The open fee (uint48).
     */
    function setOpenFee(uint48 _openFee) external;

    /**
     * @notice Sets withdraw fee
     * @dev Has modifiers: onlyRole.
     * @param _closeFee The open fee (uint48).
     */
    function setCloseFee(uint40 _closeFee) external;

    /**
     * @notice Sets underlying token address (and its decimals)
     * @notice Zero address will disable functionality provided for the underlying.
     * @dev Has modifiers: onlyRole.
     * @param _underlyingAddr The underlying address.
     */
    function setUnderlying(address _underlyingAddr) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library NumericArrayLib {
    // This function sort array in memory using bubble sort algorithm,
    // which performs even better than quick sort for small arrays

    uint256 internal constant BYTES_ARR_LEN_VAR_BS = 32;
    uint256 internal constant UINT256_VALUE_BS = 32;

    error CanNotPickMedianOfEmptyArray();

    // This function modifies the array
    function pickMedian(uint256[] memory arr) internal pure returns (uint256) {
        if (arr.length == 0) {
            revert CanNotPickMedianOfEmptyArray();
        }
        sort(arr);
        uint256 middleIndex = arr.length / 2;
        if (arr.length % 2 == 0) {
            uint256 sum = arr[middleIndex - 1] + arr[middleIndex];
            return sum / 2;
        } else {
            return arr[middleIndex];
        }
    }

    function sort(uint256[] memory arr) internal pure {
        assembly {
            let arrLength := mload(arr)
            let valuesPtr := add(arr, BYTES_ARR_LEN_VAR_BS)
            let endPtr := add(valuesPtr, mul(arrLength, UINT256_VALUE_BS))
            for {
                let arrIPtr := valuesPtr
            } lt(arrIPtr, endPtr) {
                arrIPtr := add(arrIPtr, UINT256_VALUE_BS) // arrIPtr += 32
            } {
                for {
                    let arrJPtr := valuesPtr
                } lt(arrJPtr, arrIPtr) {
                    arrJPtr := add(arrJPtr, UINT256_VALUE_BS) // arrJPtr += 32
                } {
                    let arrI := mload(arrIPtr)
                    let arrJ := mload(arrJPtr)
                    if lt(arrI, arrJ) {
                        mstore(arrIPtr, arrJ)
                        mstore(arrJPtr, arrI)
                    }
                }
            }
        }
    }
}

/**
 * @title Default implementations of virtual redstone consumer base functions
 * @author The Redstone Oracles team
 */
library RedstoneDefaultsLib {
    uint256 internal constant DEFAULT_MAX_DATA_TIMESTAMP_DELAY_SECONDS = 3 minutes;
    uint256 internal constant DEFAULT_MAX_DATA_TIMESTAMP_AHEAD_SECONDS = 1 minutes;

    error TimestampFromTooLongFuture(uint256 receivedTimestampSeconds, uint256 blockTimestamp);
    error TimestampIsTooOld(uint256 receivedTimestampSeconds, uint256 blockTimestamp);

    function validateTimestamp(uint256 receivedTimestampMilliseconds) internal view {
        // Getting data timestamp from future seems quite unlikely
        // But we've already spent too much time with different cases
        // Where block.timestamp was less than dataPackage.timestamp.
        // Some blockchains may case this problem as well.
        // That's why we add MAX_BLOCK_TIMESTAMP_DELAY
        // and allow data "from future" but with a small delay
        uint256 receivedTimestampSeconds = receivedTimestampMilliseconds / 1000;

        if (block.timestamp < receivedTimestampSeconds) {
            if ((receivedTimestampSeconds - block.timestamp) > DEFAULT_MAX_DATA_TIMESTAMP_AHEAD_SECONDS) {
                revert TimestampFromTooLongFuture(receivedTimestampSeconds, block.timestamp);
            }
        } else if ((block.timestamp - receivedTimestampSeconds) > DEFAULT_MAX_DATA_TIMESTAMP_DELAY_SECONDS) {
            revert TimestampIsTooOld(receivedTimestampSeconds, block.timestamp);
        }
    }

    function aggregateValues(uint256[] memory values) internal pure returns (uint256) {
        return NumericArrayLib.pickMedian(values);
    }
}

library BitmapLib {
    function setBitInBitmap(uint256 bitmap, uint256 bitIndex) internal pure returns (uint256) {
        return bitmap | (1 << bitIndex);
    }

    function getBitFromBitmap(uint256 bitmap, uint256 bitIndex) internal pure returns (bool) {
        uint256 bitAtIndex = bitmap & (1 << bitIndex);
        return bitAtIndex > 0;
    }
}

library SignatureLib {
    uint256 internal constant ECDSA_SIG_R_BS = 32;
    uint256 internal constant ECDSA_SIG_S_BS = 32;

    function recoverSignerAddress(bytes32 signedHash, uint256 signatureCalldataNegativeOffset) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            let signatureCalldataStartPos := sub(calldatasize(), signatureCalldataNegativeOffset)
            r := calldataload(signatureCalldataStartPos)
            signatureCalldataStartPos := add(signatureCalldataStartPos, ECDSA_SIG_R_BS)
            s := calldataload(signatureCalldataStartPos)
            signatureCalldataStartPos := add(signatureCalldataStartPos, ECDSA_SIG_S_BS)
            v := byte(0, calldataload(signatureCalldataStartPos)) // last byte of the signature memory array
        }
        return ecrecover(signedHash, v, r, s);
    }
}

/**
 * @title The base contract with helpful constants
 * @author The Redstone Oracles team
 * @dev It mainly contains redstone-related values, which improve readability
 * of other contracts (e.g. CalldataExtractor and RedstoneConsumerBase)
 */
library RedstoneError {
    // Error messages
    error ProxyCalldataFailedWithoutErrMsg2();
    error Timestamp(uint256 receivedTimestampSeconds, uint256 blockTimestamp);
    error ProxyCalldataFailedWithoutErrMsg();
    error CalldataOverOrUnderFlow();
    error ProxyCalldataFailedWithCustomError(bytes result);
    error IncorrectUnsignedMetadataSize();
    error ProxyCalldataFailedWithStringMessage(string);
    error InsufficientNumberOfUniqueSigners(uint256 receivedSignersCount, uint256 requiredSignersCount);
    error EachSignerMustProvideTheSameValue();
    error EmptyCalldataPointersArr();
    error InvalidCalldataPointer();
    error CalldataMustHaveValidPayload();
    error SignerNotAuthorised(address receivedSigner);
}

// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Purify} from "./Purify.sol";

address constant clgAddr = 0x000000000000000000636F6e736F6c652e6c6f67;
address constant fSender = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
address constant vmAddr = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
string constant rs_script_def = "utils/rsPayload.js";

function logp(bytes memory _p) pure {
    Purify.BytesIn(logv)(_p);
}

function logv(bytes memory _b) view {
    uint256 len = _b.length;
    address _a = clgAddr;
    /// @solidity memory-safe-assembly
    assembly {
        let start := add(_b, 32)
        let r := staticcall(gas(), _a, start, len, 0, 0)
    }
}

interface FFIVm {
    function ffi(string[] memory) external returns (bytes memory);

    function toString(bytes32) external view returns (string memory);

    function toString(address) external view returns (string memory);

    function toString(uint256) external view returns (string memory);
}

FFIVm constant vmFFI = FFIVm(vmAddr);

function hasVM() view returns (bool) {
    uint256 len = 0;
    assembly {
        len := extcodesize(vmAddr)
    }
    return len > 0;
}

function __revert(bytes memory _d) pure {
    assembly {
        revert(add(32, _d), mload(_d))
    }
}

// solhint-disable state-visibility
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {mvm} from "kresko-lib/utils/MinVm.s.sol";
import {Help, Log} from "kresko-lib/utils/Libs.s.sol";
import {Asset, FeedConfiguration} from "common/Types.sol";
import {Enums} from "common/Constants.sol";
import {VaultAsset} from "vault/VTypes.sol";
import {LibDeploy} from "scripts/deploy/libs/LibDeploy.s.sol";
import "scripts/deploy/JSON.s.sol" as JSON;
import {CONST} from "scripts/deploy/CONST.s.sol";
import {IERC20} from "kresko-lib/token/IERC20.sol";
import {Deployed} from "scripts/deploy/libs/Deployed.s.sol";
import {IAggregatorV3} from "kresko-lib/vendor/IAggregatorV3.sol";

library LibJSON {
    using Help for *;
    using LibDeploy for string;
    using LibJSON for *;
    using Deployed for *;

    struct KrAssetMetadata {
        string name;
        string symbol;
        string anchorName;
        string anchorSymbol;
        bytes32 krAssetSalt;
        bytes32 anchorSalt;
    }

    function getVaultAssets(JSON.Config memory json) internal view returns (VaultAsset[] memory) {
        uint256 vaultAssetCount;
        for (uint256 i; i < json.assets.extAssets.length; i++) {
            if (json.assets.extAssets[i].isVaultAsset) vaultAssetCount++;
        }
        VaultAsset[] memory result = new VaultAsset[](vaultAssetCount);

        uint256 current;
        for (uint256 i; i < json.assets.extAssets.length; i++) {
            if (json.assets.extAssets[i].isVaultAsset) {
                result[current].token = IERC20(json.assets.extAssets[i].symbol.cached());
                result[current].feed = json.getFeed(json.assets.extAssets[i].vault.feed);
                result[current].withdrawFee = json.assets.extAssets[i].vault.withdrawFee;
                result[current].depositFee = json.assets.extAssets[i].vault.depositFee;
                result[current].maxDeposits = json.assets.extAssets[i].vault.maxDeposits;
                result[current].staleTime = json.assets.extAssets[i].vault.staleTime;
                result[current].enabled = json.assets.extAssets[i].vault.enabled;

                current++;
            }
        }

        return result;
    }

    function getTicker(JSON.Config memory json, string memory _ticker) internal pure returns (JSON.TickerConfig memory) {
        for (uint256 i; i < json.assets.tickers.length; i++) {
            if (json.assets.tickers[i].ticker.equals(_ticker)) {
                return json.assets.tickers[i];
            }
        }

        revert(string.concat("!feed: ", _ticker));
    }

    function getFeeds(
        JSON.Config memory json,
        string memory _assetTicker,
        Enums.OracleType[] memory _assetOracles
    ) internal pure returns (FeedConfiguration memory) {
        JSON.TickerConfig memory ticker = json.getTicker(_assetTicker);
        (uint256 staleTime1, address feed1) = ticker.getFeed(_assetOracles[0]);
        (uint256 staleTime2, address feed2) = ticker.getFeed(_assetOracles[1]);
        return
            FeedConfiguration({
                oracleIds: [_assetOracles[0], _assetOracles[1]],
                feeds: [feed1, feed2],
                pythId: ticker.pythId,
                staleTimes: [staleTime1, staleTime2],
                invertPyth: ticker.invertPyth,
                isClosable: ticker.isClosable
            });
    }

    function getFeed(JSON.Config memory json, string[] memory config) internal pure returns (IAggregatorV3) {
        (, address feed) = json.getTicker(config[0]).getFeed(config[1]);
        return IAggregatorV3(feed);
    }

    function getFeed(JSON.TickerConfig memory ticker, string memory oracle) internal pure returns (uint256, address) {
        if (oracle.equals("chainlink")) {
            return (ticker.staleTimeChainlink, ticker.chainlink);
        }
        if (oracle.equals("api3")) {
            return (ticker.staleTimeAPI3, ticker.api3);
        }
        if (oracle.equals("vault")) {
            return (0, ticker.vault);
        }
        if (oracle.equals("redstone")) {
            return (ticker.staleTimeRedstone, address(0));
        }
        if (oracle.equals("pyth")) {
            return (ticker.staleTimePyth, address(0));
        }
        return (0, address(0));
    }

    function getFeed(JSON.TickerConfig memory ticker, Enums.OracleType oracle) internal pure returns (uint256, address) {
        if (oracle == Enums.OracleType.Chainlink) {
            return (ticker.staleTimeChainlink, ticker.chainlink);
        }
        if (oracle == Enums.OracleType.API3) {
            return (ticker.staleTimeAPI3, ticker.api3);
        }
        if (oracle == Enums.OracleType.Vault) {
            return (0, ticker.vault);
        }
        if (oracle == Enums.OracleType.Redstone) {
            return (ticker.staleTimeRedstone, address(0));
        }
        if (oracle == Enums.OracleType.Pyth) {
            return (ticker.staleTimePyth, address(0));
        }
        return (0, address(0));
    }

    function toAsset(JSON.AssetJSON memory assetJson, string memory symbol) internal view returns (Asset memory result) {
        // assembly {
        //     result := assetJson
        // }
        result.ticker = bytes32(bytes(assetJson.ticker));
        if (assetJson.kFactor > 0) {
            if (symbol.equals("KISS")) {
                result.anchor = ("KISS").cached();
            } else {
                result.anchor = string.concat(CONST.ANCHOR_SYMBOL_PREFIX, symbol).cached();
            }
        }
        Enums.OracleType[2] memory oracles = [assetJson.oracles[0], assetJson.oracles[1]];
        result.oracles = oracles;
        result.factor = assetJson.factor;
        result.kFactor = assetJson.kFactor;
        result.openFee = assetJson.openFee;
        result.closeFee = assetJson.closeFee;
        result.liqIncentive = assetJson.liqIncentive;
        result.maxDebtMinter = assetJson.maxDebtMinter;
        result.maxDebtSCDP = assetJson.maxDebtSCDP;
        result.depositLimitSCDP = assetJson.depositLimitSCDP;
        result.swapInFeeSCDP = assetJson.swapInFeeSCDP;
        result.swapOutFeeSCDP = assetJson.swapOutFeeSCDP;
        result.protocolFeeShareSCDP = assetJson.protocolFeeShareSCDP;
        result.liqIncentiveSCDP = assetJson.liqIncentiveSCDP;
        result.decimals = assetJson.decimals;
        result.isMinterCollateral = assetJson.isMinterCollateral;
        result.isMinterMintable = assetJson.isMinterMintable;
        result.isSharedCollateral = assetJson.isSharedCollateral;
        result.isSwapMintable = assetJson.isSwapMintable;
        result.isSharedOrSwappedCollateral = assetJson.isSharedOrSwappedCollateral;
        result.isCoverAsset = assetJson.isCoverAsset;
    }

    function feedBytesId(string memory ticker) internal pure returns (bytes32) {
        return bytes32(bytes(feedStringId(ticker)));
    }

    function feedStringId(string memory ticker) internal pure returns (string memory) {
        return string.concat(ticker, ".feed");
    }

    function metadata(JSON.KrAssetConfig memory cfg) internal pure returns (KrAssetMetadata memory) {
        (string memory name, string memory symbol) = getKrAssetNameAndSymbol(cfg.name, cfg.symbol);
        (string memory anchorName, string memory anchorSymbol) = getAnchorSymbolAndName(cfg.name, cfg.symbol);
        (bytes32 krAssetSalt, bytes32 anchorSalt) = getKrAssetSalts(symbol, anchorSymbol);

        return
            KrAssetMetadata({
                name: name,
                symbol: symbol,
                anchorName: anchorName,
                anchorSymbol: anchorSymbol,
                krAssetSalt: krAssetSalt,
                anchorSalt: anchorSalt
            });
    }

    function getKrAssetNameAndSymbol(
        string memory krAssetName,
        string memory krAssetSymbol
    ) internal pure returns (string memory name, string memory symbol) {
        name = string.concat(CONST.KRASSET_NAME_PREFIX, krAssetName);
        symbol = krAssetSymbol;
    }

    function getAnchorSymbolAndName(
        string memory krAssetName,
        string memory krAssetSymbol
    ) internal pure returns (string memory name, string memory symbol) {
        name = string.concat(CONST.ANCHOR_NAME_PREFIX, krAssetName);
        symbol = string.concat(CONST.ANCHOR_SYMBOL_PREFIX, krAssetSymbol);
    }

    function getKrAssetSalts(
        string memory krAssetSymbol,
        string memory anchorSymbol
    ) internal pure returns (bytes32 krAssetSalt, bytes32 anchorSalt) {
        krAssetSalt = bytes32(bytes.concat(bytes(krAssetSymbol), bytes(anchorSymbol), CONST.SALT_ID));
        anchorSalt = bytes32(bytes.concat(bytes(anchorSymbol), bytes(krAssetSymbol), CONST.SALT_ID));
    }

    function mockTokenSalt(string memory symbol) internal pure returns (bytes32) {
        return bytes32(bytes(symbol));
    }

    function pairId(address assetA, address assetB) internal pure returns (bytes32) {
        if (assetA < assetB) {
            return keccak256(abi.encodePacked(assetA, assetB));
        }
        return keccak256(abi.encodePacked(assetB, assetA));
    }

    function getBalanceConfig(
        JSON.Balance[] memory balances,
        string memory symbol
    ) internal pure returns (JSON.Balance memory) {
        for (uint256 i; i < balances.length; i++) {
            if (balances[i].symbol.equals(symbol)) {
                return balances[i];
            }
        }
        revert("Balance not found");
    }
}

// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Purify {
    function BytesIn(
        function(bytes memory) view fn
    ) internal pure returns (function(bytes memory) pure out) {
        assembly {
            out := fn
        }
    }

    function Empty(
        function() view fn
    ) internal pure returns (function() pure out) {
        assembly {
            out := fn
        }
    }

    function BoolOut(
        function() view returns (bool) fn
    ) internal pure returns (function() pure returns (bool) out) {
        assembly {
            out := fn
        }
    }

    function StrInStrOut(
        function(string memory) view returns (string memory) fn
    )
        internal
        pure
        returns (function(string memory) pure returns (string memory) out)
    {
        assembly {
            out := fn
        }
    }
}

// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {FFIVm, hasVM, vmAddr} from "./Base.s.sol";

interface IMinVM is FFIVm {
    enum CallerMode {
        // No caller modification is currently active.
        None,
        // A one time broadcast triggered by a `vm.broadcast()` call is currently active.
        Broadcast,
        // A recurrent broadcast triggered by a `vm.startBroadcast()` call is currently active.
        RecurrentBroadcast,
        // A one time prank triggered by a `vm.prank()` call is currently active.
        Prank,
        // A recurrent prank triggered by a `vm.startPrank()` call is currently active.
        RecurrentPrank
    }

    function broadcast(address signer) external;

    function getNonce(address) external returns (uint256);

    function readCallers() external returns (CallerMode, address, address);

    function readFile(string memory) external returns (string memory);

    function writeFile(string calldata, string calldata) external;

    function exists(string calldata) external returns (bool);

    function assertTrue(bool) external pure;

    function assertTrue(bool, string calldata) external pure;

    function copyFile(
        string calldata from,
        string calldata to
    ) external returns (uint64 copied);

    function createDir(string calldata path, bool recursive) external;

    function replace(
        string calldata input,
        string calldata from,
        string calldata to
    ) external pure returns (string memory output);

    function split(
        string calldata input,
        string calldata delimiter
    ) external pure returns (string[] memory outputs);

    function writeJson(
        string calldata json,
        string calldata path,
        string calldata valueKey
    ) external;

    function parseJson(
        string calldata
    ) external pure returns (bytes memory encoded);

    function parseJson(
        string calldata json,
        string calldata key
    ) external pure returns (bytes memory encoded);

    function isFile(string calldata) external view returns (bool);

    function snapshot() external returns (uint256);

    function revertTo(uint256) external returns (bool);

    function warp(uint256 newTime) external;

    function projectRoot() external view returns (string memory);

    function startBroadcast(address) external;

    function stopBroadcast() external;

    function startPrank(address) external;

    function startPrank(address, address) external;

    function stopPrank() external;

    function prank(address, address) external;

    function prank(address) external;

    function rememberKey(uint256) external returns (address);

    function deriveKey(string calldata, uint32) external pure returns (uint256);

    function envOr(
        string calldata n,
        string calldata d
    ) external returns (string memory);

    function envOr(string calldata n, uint256 d) external returns (uint256);

    function envOr(string calldata n, address d) external returns (address);

    function createFork(string calldata urlOrAlias) external returns (uint256);

    function load(address t, bytes32 s) external view returns (bytes32);

    // Signs data
    function sign(
        uint256 pk,
        bytes32 d
    ) external pure returns (uint8 v, bytes32 r, bytes32 s);

    function record() external;

    function accesses(
        address t
    ) external returns (bytes32[] memory reads, bytes32[] memory wries);

    function getCode(string calldata a) external view returns (bytes memory cc);

    function setEnv(string calldata k, string calldata v) external;

    function toString(address value) external pure returns (string memory r);

    function toString(
        bytes calldata value
    ) external pure returns (string memory r);

    function toString(bytes32 value) external pure returns (string memory r);

    function toString(bool value) external pure returns (string memory r);

    function toString(uint256 value) external pure returns (string memory r);

    function toString(int256 value) external pure returns (string memory r);

    // Convert values from a string
    function parseBytes(
        string calldata str
    ) external pure returns (bytes memory r);

    function parseAddress(
        string calldata str
    ) external pure returns (address r);

    function parseUint(string calldata str) external pure returns (uint256 r);

    function parseInt(string calldata str) external pure returns (int256 r);

    function parseBytes32(
        string calldata str
    ) external pure returns (bytes32 r);

    function parseBool(string calldata str) external pure returns (bool r);

    function rpc(string calldata method, string calldata params) external;

    function createSelectFork(
        string calldata network
    ) external returns (uint256);

    function createSelectFork(
        string calldata network,
        uint256 blockNr
    ) external returns (uint256);

    function allowCheatcodes(address to) external;

    function unixTime() external returns (uint256);

    function activeFork() external view returns (uint256);

    function selectFork(uint256 forkId) external;

    function rollFork(uint256 blockNumber) external;

    function rollFork(uint256 forkId, uint256 blockNumber) external;

    /// See `serializeJson`.
    function serializeAddress(
        string calldata objk,
        string calldata valk,
        address value
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeAddress(
        string calldata objk,
        string calldata valk,
        address[] calldata values
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeBool(
        string calldata objk,
        string calldata valk,
        bool value
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeBool(
        string calldata objk,
        string calldata valk,
        bool[] calldata values
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeBytes32(
        string calldata objk,
        string calldata valk,
        bytes32 value
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeBytes32(
        string calldata objk,
        string calldata valk,
        bytes32[] calldata values
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeBytes(
        string calldata objk,
        string calldata valk,
        bytes calldata value
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeBytes(
        string calldata objk,
        string calldata valk,
        bytes[] calldata values
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeInt(
        string calldata objk,
        string calldata valueKey,
        int256 value
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeInt(
        string calldata objk,
        string calldata valk,
        int256[] calldata values
    ) external returns (string memory json);

    /// Serializes a key and value to a JSON object stored in-memory that can be later written to a file.
    /// Returns the stringified version of the specific JSON file up to that moment.
    function serializeJson(
        string calldata objk,
        string calldata value
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeString(
        string calldata objk,
        string calldata valk,
        string calldata value
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeString(
        string calldata objk,
        string calldata valk,
        string[] calldata values
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeUint(
        string calldata objk,
        string calldata valk,
        uint256 value
    ) external returns (string memory json);

    /// See `serializeJson`.
    function serializeUint(
        string calldata objk,
        string calldata valk,
        uint256[] calldata values
    ) external returns (string memory json);

    /// Write a serialized JSON object to a file. If the file exists, it will be overwritten.
    function writeJson(string calldata json, string calldata path) external;
}

IMinVM constant mvm = IMinVM(vmAddr);

function mPk(string memory _mEnv, uint32 _idx) returns (uint256) {
    return mvm.deriveKey(mvm.envOr(_mEnv, "error burger code"), _idx);
}

function mAddr(string memory _mEnv, uint32 _idx) returns (address) {
    return
        mvm.rememberKey(
            mvm.deriveKey(mvm.envOr(_mEnv, "error burger code"), _idx)
        );
}

struct Store {
    bool _failed;
    bool logDisabled;
    string logPrefix;
}

function store() view returns (Store storage s) {
    if (!hasVM()) revert("no hevm");
    assembly {
        s.slot := 0x35b9089429a720996a27ffd842a4c293f759fc6856f1c672c8e2b5040a1eddfe
    }
}

// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {mvm, LibVm} from "./LibVm.s.sol";
import {IERC20} from "../token/IERC20.sol";
import {hasVM, mAddr, store} from "./MinVm.s.sol";
import {PLog} from "./PLog.s.sol";
import {Purify} from "./Purify.sol";

library Help {
    error ELEMENT_NOT_FOUND(ID element, uint256 index, address[] elements);
    using Help for address[];
    using Help for bytes32[];
    using Help for string[];
    using Help for string;

    struct ID {
        string symbol;
        address addr;
    }

    function id(address _token) internal view returns (ID memory) {
        if (_token.code.length > 0) {
            return ID(IERC20(_token).symbol(), _token);
        }
        return ID("", _token); // not a token
    }

    struct FindResult {
        uint256 index;
        bool exists;
    }

    function find(
        address[] storage _els,
        address _search
    ) internal pure returns (FindResult memory result) {
        address[] memory elements = _els;
        for (uint256 i; i < elements.length; ) {
            if (elements[i] == _search) {
                return FindResult(i, true);
            }
            unchecked {
                ++i;
            }
        }
    }

    function find(
        bytes32[] storage _els,
        bytes32 _search
    ) internal pure returns (FindResult memory result) {
        bytes32[] memory elements = _els;
        for (uint256 i; i < elements.length; ) {
            if (elements[i] == _search) {
                return FindResult(i, true);
            }
            unchecked {
                ++i;
            }
        }
    }

    function find(
        string[] storage _els,
        string memory _search
    ) internal pure returns (FindResult memory result) {
        string[] memory elements = _els;
        for (uint256 i; i < elements.length; ) {
            if (elements[i].equals(_search)) {
                return FindResult(i, true);
            }
            unchecked {
                ++i;
            }
        }
    }

    function pushUnique(address[] storage _els, address _toAdd) internal {
        if (!_els.find(_toAdd).exists) {
            _els.push(_toAdd);
        }
    }

    function pushUnique(bytes32[] storage _els, bytes32 _toAdd) internal {
        if (!_els.find(_toAdd).exists) {
            _els.push(_toAdd);
        }
    }

    function pushUnique(string[] storage _els, string memory _toAdd) internal {
        if (!_els.find(_toAdd).exists) {
            _els.push(_toAdd);
        }
    }

    function removeExisting(address[] storage _arr, address _toR) internal {
        FindResult memory result = _arr.find(_toR);
        if (result.exists) {
            _arr.removeAddress(_toR, result.index);
        }
    }

    function removeAddress(
        address[] storage _arr,
        address _toR,
        uint256 _idx
    ) internal {
        if (_arr[_idx] != _toR) revert ELEMENT_NOT_FOUND(id(_toR), _idx, _arr);

        uint256 lastIndex = _arr.length - 1;
        if (_idx != lastIndex) {
            _arr[_idx] = _arr[lastIndex];
        }

        _arr.pop();
    }

    function isEmpty(address[2] memory _arr) internal pure returns (bool) {
        return _arr[0] == address(0) && _arr[1] == address(0);
    }

    function isEmpty(string memory _val) internal pure returns (bool) {
        return bytes(_val).length == 0;
    }

    function equals(
        string memory _a,
        string memory _b
    ) internal pure returns (bool) {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function str(address _val) internal pure returns (string memory) {
        return mvm.toString(_val);
    }

    function str(uint256 _val) internal pure returns (string memory) {
        return mvm.toString(_val);
    }

    function str(bytes32 _val) internal pure returns (string memory) {
        return mvm.toString(_val);
    }

    function txt(bytes32 _val) internal pure returns (string memory) {
        return string(abi.encodePacked(_val));
    }

    function txt(bytes memory _val) internal pure returns (string memory) {
        return string(abi.encodePacked(_val));
    }

    function str(bytes memory _val) internal pure returns (string memory) {
        return mvm.toString(_val);
    }

    function toAddr(string memory _val) internal pure returns (address) {
        return mvm.parseAddress(_val);
    }

    function toUint(string memory _val) internal pure returns (uint256) {
        return mvm.parseUint(_val);
    }

    function toB32(string memory _val) internal pure returns (bytes32) {
        return mvm.parseBytes32(_val);
    }

    function toBytes(string memory _val) internal pure returns (bytes memory) {
        return mvm.parseBytes(_val);
    }

    function and(
        string memory a,
        string memory b
    ) internal pure returns (string memory) {
        return string.concat(a, b);
    }

    uint256 internal constant PCT_F = 1e4;
    uint256 internal constant HALF_PCT_F = 0.5e4;

    function pctMul(
        uint256 value,
        uint256 _pct
    ) internal pure returns (uint256 result) {
        assembly {
            if iszero(
                or(
                    iszero(_pct),
                    iszero(gt(value, div(sub(not(0), HALF_PCT_F), _pct)))
                )
            ) {
                revert(0, 0)
            }

            result := div(add(mul(value, _pct), HALF_PCT_F), PCT_F)
        }
    }

    function pctDiv(
        uint256 value,
        uint256 _pct
    ) internal pure returns (uint256 result) {
        assembly {
            if or(
                iszero(_pct),
                iszero(iszero(gt(value, div(sub(not(0), div(_pct, 2)), PCT_F))))
            ) {
                revert(0, 0)
            }

            result := div(add(mul(value, PCT_F), div(_pct, 2)), _pct)
        }
    }

    // HALF_WAD and HALF_RAY expressed with extended notation
    // as constant with operations are not supported in Yul assembly
    uint256 constant WAD = 1e18;
    uint256 constant HALF_WAD = 0.5e18;

    uint256 constant RAY = 1e27;
    uint256 constant HALF_RAY = 0.5e27;

    uint256 constant WAD_RAY_RATIO = 1e9;

    function mulWad(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    function divWad(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    function mulRay(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    function divRay(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    function fromRayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
                b := add(b, 1)
            }
        }
    }

    function fromWadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
                revert(0, 0)
            }
        }
    }
}

library Log {
    event log(string);
    event logs(bytes);

    event log_address(address);
    event log_bytes32(bytes32);
    event log_int(int256);
    event log_uint(uint256);
    event log_bytes(bytes);
    event log_string(string);

    event log_named_address(string key, address val);
    event log_named_bytes32(string key, bytes32 val);
    event log_named_decimal_int(string key, int256 val, uint256 decimals);
    event log_named_decimal_uint(string key, uint256 val, uint256 decimals);
    event log_named_int(string key, int256 val);
    event log_named_uint(string key, uint256 val);
    event log_named_bytes(string key, bytes val);
    event log_named_string(string key, string val);

    event log_array(uint256[] val);
    event log_array(int256[] val);
    event log_array(address[] val);
    event log_named_array(string key, uint256[] val);
    event log_named_array(string key, int256[] val);
    event log_named_array(string key, address[] val);
    using Help for bytes32;
    using Help for string;
    using Help for address;
    using Help for bytes;
    using Help for uint256[2];
    using Help for uint8[2];
    using Help for uint32[2];
    using Help for uint16[2];

    function prefix(string memory _prefix) internal {
        store().logPrefix = _prefix;
    }

    function _hp() private view returns (bool) {
        return !store().logPrefix.isEmpty();
    }

    function __pre(string memory _str) private view returns (string memory) {
        if (_hasPrefix()) {
            return store().logPrefix.and(_str);
        } else {
            return _str;
        }
    }

    function _pre(string memory _str) internal pure returns (string memory) {
        return Purify.StrInStrOut(__pre)(_str);
    }

    function _hasPrefix() private pure returns (bool) {
        return Purify.BoolOut(_hp)();
    }

    function hr() internal pure {
        PLog.clg("--------------------------------------------------");
    }

    function br() internal pure {
        PLog.clg("\n");
    }

    function n() internal pure {
        PLog.clg("\n");
    }

    function sr() internal pure {
        PLog.clg("**************************************************");
    }

    function log_bool(bool _val) internal pure {
        PLog.clg(_pre(_val ? "true" : "false"));
    }

    function log_named_bool(string memory _str, bool _val) internal pure {
        PLog.clg(_pre(_str), _val ? "true" : "false");
    }

    function log_pct(uint256 _val) internal {
        emit log_named_decimal_uint(_pre(""), _val, 2);
    }

    function log_pct(uint256 _val, string memory _str) internal {
        emit log_named_decimal_uint(_pre(_str), _val, 2);
    }

    function log_decimal_balance(address _account, address _token) internal {
        emit log_named_decimal_uint(
            _pre(mvm.toString(_account).and(IERC20(_token).symbol())),
            IERC20(_token).balanceOf(_account),
            IERC20(_token).decimals()
        );
    }

    function log_decimal_balances(
        address _account,
        address[] memory _tokens
    ) internal {
        for (uint256 i; i < _tokens.length; i++) {
            emit log_named_decimal_uint(
                _pre(mvm.toString(_account).and(IERC20(_tokens[i]).symbol())),
                IERC20(_tokens[i]).balanceOf(_account),
                IERC20(_tokens[i]).decimals()
            );
        }
    }

    function clg(address _val) internal pure {
        if (check()) return;
        if (!_hasPrefix()) {
            PLog.clg(_val);
        } else {
            PLog.clg(_val, _pre(""));
        }
    }

    function blg(bytes32 _val) internal pure {
        if (check()) return;
        if (!_hasPrefix()) {
            PLog.blg(_val);
        } else {
            PLog.blg(_val, _pre(""));
        }
    }

    function clg(int256 _val) internal pure {
        if (check()) return;
        if (!_hasPrefix()) {
            PLog.clg(_val);
        } else {
            PLog.clg(_val, _pre(""));
        }
    }

    function clg(uint256 _val) internal pure {
        if (check()) return;
        if (!_hasPrefix()) {
            PLog.clg(_val);
        } else {
            PLog.clg(_val, _pre(""));
        }
    }

    function blg(bytes memory _val) internal pure {
        if (check()) return;
        if (!_hasPrefix()) {
            PLog.blg(_val);
        } else {
            PLog.blg(_val, _pre(""));
        }
    }

    function pct(uint256 _val, string memory _str) internal {
        if (check()) return;
        emit log_named_decimal_uint(_pre(_str), _val, 2);
    }

    function pct(string memory _str, uint256 _val) internal {
        if (check()) return;
        emit log_named_decimal_uint(_pre(_str), _val, 2);
    }

    function dlg(int256 _val, string memory _str) internal {
        if (check()) return;
        emit log_named_decimal_int(_pre(_str), _val, 18);
    }

    function dlg(int256 _val, string memory _str, uint256 dec) internal {
        if (check()) return;
        emit log_named_decimal_int(_pre(_str), _val, dec);
    }

    function dlg(string memory _str, int256 _val) internal {
        if (check()) return;
        emit log_named_decimal_int(_pre(_str), _val, 18);
    }

    function dlg(string memory _str, uint256 _val) internal {
        if (check()) return;
        emit log_named_decimal_uint(_pre(_str), _val, 18);
    }

    function dlg(string memory _str, int256 _val, uint256 dec) internal {
        if (check()) return;
        emit log_named_decimal_int(_pre(_str), _val, dec);
    }

    function dlg(string memory _str, uint256 _val, uint256 dec) internal {
        if (check()) return;
        emit log_named_decimal_uint(_pre(_str), _val, dec);
    }

    function dlg(uint256 _val, string memory _str) internal {
        if (check()) return;
        emit log_named_decimal_uint(_pre(_str), _val, 18);
    }

    function dlg(uint256 _val, string memory _str, uint256 dec) internal {
        if (check()) return;
        emit log_named_decimal_uint(_pre(_str), _val, dec);
    }

    function clg(string memory _str, uint256 _val) internal pure {
        if (check()) return;
        PLog.clg(_val, _pre(_str));
    }

    function clg(uint256 _val, string memory _str) internal pure {
        if (check()) return;
        PLog.clg(_val, _pre(_str));
    }

    function clg(string memory _str, int256 _val) internal pure {
        if (check()) return;
        PLog.clg(_val, _pre(_str));
    }

    function clg(int256 _val, string memory _str) internal pure {
        if (check()) return;
        PLog.clg(_val, _pre(_str));
    }

    function clg(string memory _val) internal pure {
        if (check()) return;
        PLog.clg(_pre(_val));
    }

    function clg(string memory _val, string memory _lbl) internal pure {
        if (check()) return;
        PLog.clg(_pre(_lbl), _val);
    }

    function clg(string memory _lbl, address _val) internal pure {
        if (check()) return;
        PLog.clg(_val, _pre(_lbl));
    }

    function clg(string memory _lbl, uint256[] memory _val) internal {
        if (check()) return;
        emit log_named_array(_pre(_lbl), _val);
    }

    function clg(string memory _lbl, int256[] memory _val) internal {
        if (check()) return;
        emit log_named_array(_pre(_lbl), _val);
    }

    function blg(string memory _lbl, bytes memory _val) internal pure {
        if (check()) return;
        PLog.blg(_val, _pre(_lbl));
    }

    function blg(string memory _lbl, bytes32 _val) internal pure {
        if (check()) return;
        PLog.blg(_val, _pre(_lbl));
    }

    function blg2txt(string memory _lbl, bytes32 _val) internal pure {
        if (check()) return;
        PLog.clg(_pre(_lbl), _val.txt());
    }

    function blg2str(string memory _lbl, bytes memory _val) internal pure {
        if (check()) return;
        PLog.clg(_pre(_lbl), _val.str());
    }

    function blg2txt(string memory _lbl, bytes memory _val) internal pure {
        if (check()) return;
        PLog.clg(_pre(_lbl), _val.txt());
    }

    function blg2str(bytes32 _val, string memory _lbl) internal pure {
        if (check()) return;
        PLog.clg(_pre(_lbl), _val.str());
    }

    function blg2txt(bytes32 _val, string memory _lbl) internal pure {
        if (check()) return;
        PLog.clg(_pre(_lbl), _val.txt());
    }

    function blg2str(bytes memory _val, string memory _lbl) internal pure {
        if (check()) return;
        PLog.clg(_pre(_lbl), _val.str());
    }

    function blg2txt(bytes memory _val, string memory _lbl) internal pure {
        if (check()) return;
        PLog.clg(_pre(_lbl), _val.txt());
    }

    function clg2bytes(string memory _val, string memory _lbl) internal pure {
        if (check()) return;
        PLog.blg(bytes(_val), _pre(_lbl));
    }

    function clg2str(address _val, string memory _lbl) internal pure {
        if (check()) return;
        PLog.clg(_pre(_lbl), _val.str());
    }

    function clg2str(string memory _lbl, address _val) internal pure {
        if (check()) return;
        PLog.clg(_pre(_lbl).and(_val.str()));
    }

    function clg(address[] memory _val, string memory _str) internal {
        if (check()) return;
        emit log_named_array(_pre(_str), _val);
    }

    function clg(address _val, string memory _str) internal pure {
        if (check()) return;
        PLog.clg(_val, _pre(_str));
    }

    function clg(bool _val, string memory _str) internal pure {
        log_named_bool(_pre(_str), _val);
    }

    function clg(bool _val) internal pure {
        log_bool(_val);
    }

    function clg(address[] memory _val) internal {
        if (check()) return;
        emit log_array(_val);
    }

    function clg(uint256[] memory _val) internal {
        if (check()) return;
        if (!_hasPrefix()) {
            emit log_array(_val);
        } else {
            emit log_named_array(_pre(""), _val);
        }
    }

    function clg(int256[] memory _val) internal {
        if (check()) return;
        if (!_hasPrefix()) {
            emit log_array(_val);
        } else {
            emit log_named_array(_pre(""), _val);
        }
    }

    function clg(uint256[] memory _val, string memory _str) internal {
        if (check()) return;
        emit log_named_array(_pre(_str), _val);
    }

    function clg(int256[] memory _val, string memory _str) internal {
        if (check()) return;
        emit log_named_array(_pre(_str), _val);
    }

    function blg(bytes32 _val, string memory _str) internal pure {
        if (check()) return;
        PLog.blg(_val, _pre(_str));
    }

    function blg(bytes memory _val, string memory _str) internal pure {
        if (check()) return;
        PLog.blg(_val, _pre(_str));
    }

    function clgBal(address _account, address[] memory _tokens) internal {
        log_decimal_balances(_account, _tokens);
    }

    function clgBal(address _account, address _token) internal {
        log_decimal_balance(_account, _token);
    }

    function logCallers() internal {
        if (check()) return;
        LibVm.Callers memory current = LibVm.callers();

        emit log_named_string("isHEVM", hasVM() ? "true" : "false");
        emit log_named_address("msg.sender", current.msgSender);
        emit log_named_address("tx.origin", current.txOrigin);
        emit log_named_string("mode", current.mode);
    }

    function disable() internal {
        store().logDisabled = true;
    }

    function enable() internal {
        store().logDisabled = false;
    }

    function _check() internal view returns (bool) {
        return store().logDisabled;
    }

    function check() internal pure returns (bool) {
        return Purify.BoolOut(_check)();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "kresko-lib/token/IERC20.sol";
import {IAggregatorV3} from "kresko-lib/vendor/IAggregatorV3.sol";

/**
 * @notice Asset struct for deposit assets in contract
 * @param token The ERC20 token
 * @param feed IAggregatorV3 feed for the asset
 * @param staleTime Time in seconds for the feed to be considered stale
 * @param maxDeposits Max deposits allowed for the asset
 * @param depositFee Deposit fee of the asset
 * @param withdrawFee Withdraw fee of the asset
 * @param enabled Enabled status of the asset
 */
struct VaultAsset {
    IERC20 token;
    IAggregatorV3 feed;
    uint24 staleTime;
    uint8 decimals;
    uint32 depositFee;
    uint32 withdrawFee;
    uint248 maxDeposits;
    bool enabled;
}

/**
 * @notice Vault configuration struct
 * @param sequencerUptimeFeed The feed address for the sequencer uptime
 * @param sequencerGracePeriodTime The grace period time for the sequencer
 * @param governance The governance address
 * @param feeRecipient The fee recipient address
 * @param oracleDecimals The oracle decimals
 */
struct VaultConfiguration {
    address sequencerUptimeFeed;
    uint96 sequencerGracePeriodTime;
    address governance;
    address pendingGovernance;
    address feeRecipient;
    uint8 oracleDecimals;
}

// solhint-disable var-name-mixedcase
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {Deployment, DeploymentFactory} from "factory/DeploymentFactory.sol";
import {Vault} from "vault/Vault.sol";
import {KreskoAssetAnchor} from "kresko-asset/KreskoAssetAnchor.sol";
import {Conversions} from "libs/Utils.sol";
import {KreskoAsset} from "kresko-asset/KreskoAsset.sol";
import {IKreskoAsset} from "kresko-asset/IKreskoAsset.sol";
import {KISS} from "kiss/KISS.sol";
import {DataV1} from "periphery/DataV1.sol";
import {KrMulticall} from "periphery/KrMulticall.sol";
import {Role} from "common/Constants.sol";
import {IKresko} from "periphery/IKresko.sol";
import {Help, Log, mvm} from "kresko-lib/utils/Libs.s.sol";
import {GatingManager} from "periphery/GatingManager.sol";
import {Deployed} from "scripts/deploy/libs/Deployed.s.sol";
import {CONST} from "scripts/deploy/CONST.s.sol";
import {IDeploymentFactory} from "factory/IDeploymentFactory.sol";
import {MockPyth} from "mocks/MockPyth.sol";
import {getPythViewData, getMockPythPayload, PythView} from "vendor/pyth/PythScript.sol";
import {LibJSON, JSON} from "scripts/deploy/libs/LibJSON.s.sol";
import {MockMarketStatus} from "src/contracts/mocks/MockMarketStatus.sol";

library LibDeploy {
    using Conversions for bytes[];
    using Log for *;
    using Help for *;
    using Deployed for *;
    using LibJSON for string;
    using LibDeploy for bytes;
    using LibDeploy for bytes32;

    function createFactory(address _owner) internal saveOutput("Factory") returns (DeploymentFactory result) {
        result = new DeploymentFactory(_owner);
        setJsonAddr("address", address(result));
        setJsonBytes("ctor", abi.encode(_owner));
        state().factory = result;
    }

    function createGatingManager(
        JSON.Config memory json,
        address _owner
    ) internal saveOutput("GatingManager") returns (GatingManager) {
        bytes memory implementation = type(GatingManager).creationCode.ctor(
            abi.encode(_owner, json.params.periphery.okNFT, json.params.periphery.qfkNFT, 0)
        );
        return GatingManager(implementation.d3("", CONST.GM_SALT).implementation);
    }

    function createMockMarketStatusProvider(JSON.Config memory) internal saveOutput("MarketStatus") returns (MockMarketStatus) {
        return MockMarketStatus(type(MockMarketStatus).creationCode.d3("", CONST.MOCK_STATUS_SALT).implementation);
    }

    function createMockPythEP(JSON.Config memory json, bool _realPrices) internal saveOutput("MockPythEP") returns (MockPyth) {
        (bytes32[] memory ids, int64[] memory prices) = json.getMockPrices();

        if (_realPrices) {
            PythView memory data = getPythViewData(ids);
            for (uint256 i; i < data.ids.length; i++) {
                prices[i] = data.prices[i].price;
            }
        }

        bytes memory implementation = type(MockPyth).creationCode.ctor(abi.encode(getMockPythPayload(ids, prices)));
        return MockPyth(implementation.d3("", CONST.PYTH_MOCK_SALT).implementation);
    }

    function createKISS(
        JSON.Config memory json,
        address kresko,
        address vault
    ) internal saveOutput("KISS") returns (KISS result) {
        require(kresko != address(0), "deployKISS: !Kresko");
        require(vault != address(0), "deployKISS: !Vault");
        string memory name = CONST.KISS_PREFIX.and(json.assets.kiss.name);
        bytes memory initializer = abi.encodeCall(
            KISS.initialize,
            (name, json.assets.kiss.symbol, 18, json.params.common.admin, kresko, vault)
        );
        result = KISS(address(type(KISS).creationCode.p3(initializer, CONST.KISS_SALT).proxy));
        json.assets.kiss.symbol.cache(address(result));
    }

    function createVault(JSON.Config memory json, address _owner) internal saveOutput("Vault") returns (Vault) {
        string memory name = CONST.VAULT_NAME_PREFIX.and(json.assets.kiss.name);
        string memory symbol = CONST.VAULT_SYMBOL_PREFIX.and(json.assets.kiss.symbol);
        bytes memory implementation = type(Vault).creationCode.ctor(
            abi.encode(name, symbol, 18, 8, _owner, json.params.common.treasury, json.params.common.sequencerUptimeFeed)
        );
        return Vault(implementation.d3("", CONST.VAULT_SALT).implementation);
    }

    function createDataV1(
        JSON.Config memory json,
        address _kresko,
        address _vault,
        address _kiss
    ) internal saveOutput("DataV1") returns (DataV1) {
        bytes memory implementation = type(DataV1).creationCode.ctor(
            abi.encode(
                _kresko,
                _vault,
                _kiss,
                json.params.periphery.quoterv2,
                json.params.periphery.okNFT,
                json.params.periphery.qfkNFT
            )
        );
        return DataV1(implementation.d3("", CONST.D1_SALT).implementation);
    }

    function createMulticall(
        JSON.Config memory json,
        address _kresko,
        address _kiss,
        address _pythEp,
        bytes32 _salt
    ) internal saveOutput("Multicall") returns (KrMulticall) {
        bytes memory implementation = type(KrMulticall).creationCode.ctor(
            abi.encode(
                _kresko,
                _kiss,
                json.params.periphery.v3Router,
                json.assets.wNative.token,
                _pythEp,
                json.params.common.admin
            )
        );
        address multicall = implementation.d2("", _salt).implementation;
        IKresko(_kresko).grantRole(Role.MANAGER, multicall);
        LibDeploy.setJsonBytes("INIT_CODE_HASH", bytes.concat(keccak256(implementation)));
        return KrMulticall(payable(multicall));
    }

    function createKrAssets(JSON.Config memory json, address kresko) internal returns (JSON.Config memory) {
        for (uint256 i; i < json.assets.kreskoAssets.length; i++) {
            DeployedKrAsset memory deployed = deployKrAsset(json, json.assets.kreskoAssets[i], kresko);
            json.assets.kreskoAssets[i].config.anchor = deployed.anchorAddr;
        }

        return json;
    }

    function deployKrAsset(
        JSON.Config memory json,
        JSON.KrAssetConfig memory asset,
        address kresko
    ) internal returns (DeployedKrAsset memory result) {
        JSONKey(asset.symbol);
        LibJSON.KrAssetMetadata memory meta = asset.metadata();
        address underlying = !asset.underlyingSymbol.isEmpty() ? asset.underlyingSymbol.cached() : address(0);
        bytes memory KR_ASSET_INITIALIZER = abi.encodeCall(
            KreskoAsset.initialize,
            (
                meta.name,
                meta.symbol,
                18,
                json.params.common.admin,
                kresko,
                underlying,
                json.params.common.treasury,
                asset.wrapFee,
                asset.unwrapFee
            )
        );
        (address proxyAddr, address implAddr) = meta.krAssetSalt.pp3();
        setJsonAddr("address", proxyAddr);
        setJsonBytes("initializer", abi.encode(implAddr, address(factory()), KR_ASSET_INITIALIZER));
        setJsonAddr("implementation", implAddr);
        saveJSONKey();

        JSONKey(meta.anchorSymbol);
        bytes memory ANCHOR_IMPL = type(KreskoAssetAnchor).creationCode.ctor(abi.encode(proxyAddr));
        bytes memory ANCHOR_INITIALIZER = abi.encodeCall(
            KreskoAssetAnchor.initialize,
            (IKreskoAsset(proxyAddr), meta.anchorName, meta.anchorSymbol, json.params.common.admin)
        );

        // deploy krasset + anchor in batch
        bytes[] memory batch = new bytes[](2);
        batch[0] = abi.encodeCall(
            factory().create3ProxyAndLogic,
            (type(KreskoAsset).creationCode, KR_ASSET_INITIALIZER, meta.krAssetSalt)
        );
        batch[1] = abi.encodeCall(factory().create3ProxyAndLogic, (ANCHOR_IMPL, ANCHOR_INITIALIZER, meta.anchorSalt));
        Deployment[] memory proxies = factory().batch(batch).map(Conversions.toDeployment);

        result.addr = address(proxies[0].proxy);
        result.anchorAddr = address(proxies[1].proxy);
        result.anchorSymbol = meta.anchorSymbol;
        asset.symbol.cache(result.addr);
        result.anchorSymbol.cache(result.anchorAddr);
        setJsonAddr("address", result.anchorAddr);
        setJsonBytes("initializer", abi.encode(proxies[1].implementation, address(factory()), ANCHOR_INITIALIZER));
        setJsonAddr("implementation", proxies[1].implementation);
        saveJSONKey();
        result.json = asset;
    }

    function pd3(bytes32 salt) internal returns (address) {
        return factory().getCreate3Address(salt);
    }

    function pp3(bytes32 salt) internal returns (address, address) {
        return factory().previewCreate3ProxyAndLogic(salt);
    }

    function ctor(bytes memory bcode, bytes memory args) internal returns (bytes memory ccode) {
        setJsonBytes("ctor", args);
        return abi.encodePacked(bcode, args);
    }

    function d2(bytes memory ccode, bytes memory _init, bytes32 _salt) internal returns (Deployment memory result) {
        result = factory().deployCreate2(ccode, _init, _salt);
        setJsonAddr("address", result.implementation);
    }

    function d3(bytes memory ccode, bytes memory _init, bytes32 _salt) internal returns (Deployment memory result) {
        result = factory().deployCreate3(ccode, _init, _salt);
        setJsonAddr("address", result.implementation);
    }

    function p3(bytes memory ccode, bytes memory _init, bytes32 _salt) internal returns (Deployment memory result) {
        result = factory().create3ProxyAndLogic(ccode, _init, _salt);
        setJsonAddr("address", address(result.proxy));
        setJsonBytes("initializer", abi.encode(result.implementation, address(factory()), _init));
        setJsonAddr("implementation", result.implementation);
    }

    function pkr3(JSON.KrAssetConfig memory asset) internal returns (address) {
        return asset.metadata().krAssetSalt.pd3();
    }

    function previewTokenAddr(JSON.Config memory json, string memory symbol) internal returns (address) {
        for (uint256 i; i < json.assets.extAssets.length; i++) {
            if (json.assets.extAssets[i].symbol.equals(symbol)) {
                if (json.assets.extAssets[i].mocked) {
                    return json.assets.extAssets[i].symbol.mockTokenSalt().pd3();
                }
                return json.assets.extAssets[i].addr;
            }
        }

        for (uint256 i; i < json.assets.kreskoAssets.length; i++) {
            if (json.assets.kreskoAssets[i].symbol.equals(symbol)) {
                return pkr3(json.assets.kreskoAssets[i]);
            }
        }
        revert(string.concat("!assetAddr: ", symbol));
    }

    bytes32 internal constant DEPLOY_STATE_SLOT = keccak256("DeployState");

    struct DeployedKrAsset {
        address addr;
        address anchorAddr;
        string symbol;
        string anchorSymbol;
        JSON.KrAssetConfig json;
    }

    struct DeployState {
        IDeploymentFactory factory;
        string id;
        string outputLocation;
        string currentKey;
        string currentJson;
        string outputJson;
        bool disableLog;
    }

    function initOutputJSON(string memory configId) internal {
        string memory outputDir = string.concat("./out/foundry/deploy/", mvm.toString(block.chainid), "/");
        if (!mvm.exists(outputDir)) mvm.createDir(outputDir, true);
        state().id = configId;
        state().outputLocation = outputDir;
        state().outputJson = configId;
    }

    function writeOutputJSON() internal {
        string memory runsDir = string.concat(state().outputLocation, "runs/");
        if (!mvm.exists(runsDir)) mvm.createDir(runsDir, true);
        mvm.writeFile(string.concat(runsDir, state().id, "-", mvm.toString(mvm.unixTime()), ".json"), state().outputJson);
        mvm.writeFile(string.concat(state().outputLocation, state().id, "-", "latest", ".json"), state().outputJson);
    }

    function state() internal pure returns (DeployState storage ds) {
        bytes32 slot = DEPLOY_STATE_SLOT;
        assembly {
            ds.slot := slot
        }
    }

    modifier saveOutput(string memory id) {
        JSONKey(id);
        _;
        saveJSONKey();
    }

    function JSONKey(string memory id) internal {
        state().currentKey = id;
        state().currentJson = "";
    }

    function setJsonAddr(string memory key, address val) internal {
        state().currentJson = mvm.serializeAddress(state().currentKey, key, val);
    }

    function setJsonBool(string memory key, bool val) internal {
        state().currentJson = mvm.serializeBool(state().currentKey, key, val);
    }

    function setJsonNumber(string memory key, uint256 val) internal {
        state().currentJson = mvm.serializeUint(state().currentKey, key, val);
    }

    function setJsonBytes(string memory key, bytes memory val) internal {
        state().currentJson = mvm.serializeBytes(state().currentKey, key, val);
    }

    function saveJSONKey() internal {
        state().outputJson = mvm.serializeString("out", state().currentKey, state().currentJson);
    }

    function disableLog() internal {
        state().disableLog = true;
    }

    function factory() internal returns (IDeploymentFactory factory_) {
        if (address(state().factory) == address(0)) {
            state().factory = Deployed.factory();
        }
        return state().factory;
    }

    function cacheExtTokens(JSON.Config memory input) internal {
        for (uint256 i; i < input.assets.extAssets.length; i++) {
            JSON.ExtAsset memory ext = input.assets.extAssets[i];
            ext.symbol.cache(ext.addr);
            if (ext.mocked) continue;
            JSONKey(ext.symbol);
            setJsonAddr("address", ext.addr);
            saveJSONKey();
        }

        if (input.assets.wNative.mocked) {
            input.assets.wNative.symbol.cache(address(input.assets.wNative.token));
            return;
        }
        JSONKey("wNative");
        setJsonAddr("address", address(input.assets.wNative.token));
        saveJSONKey();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;
import {Asset, CommonInitArgs} from "common/Types.sol";
import {SCDPInitArgs} from "scdp/STypes.sol";
import {MinterInitArgs} from "minter/MTypes.sol";
import {IWETH9} from "kresko-lib/token/IWETH9.sol";
import {Enums} from "common/Constants.sol";
import {LibJSON} from "scripts/deploy/libs/LibJSON.s.sol";
import {mAddr, mvm} from "kresko-lib/utils/MinVm.s.sol";
import {Help} from "kresko-lib/utils/Libs.s.sol";
import {CONST} from "scripts/deploy/CONST.s.sol";
import {PLog} from "kresko-lib/utils/PLog.s.sol";
import {Deployed} from "scripts/deploy/libs/Deployed.s.sol";
struct Files {
    string params;
    string assets;
    string users;
}

using Help for string;

function getConfig(string memory network, string memory configId) returns (Config memory json) {
    string memory dir = string.concat(CONST.CONFIG_DIR, network, "/");

    return getConfigFrom(dir, configId);
}

function getSalts(string memory network, string memory configId) returns (Salts memory) {
    string memory dir = string.concat(CONST.CONFIG_DIR, network, "/");
    string memory location = string.concat(dir, "salts-", configId, ".json");
    if (!mvm.exists(location)) {
        return Salts({kresko: bytes32("Kresko"), multicall: bytes32("Multicall")});
    }

    return abi.decode(mvm.parseJson(mvm.readFile(location)), (Salts));
}

function getConfigFrom(string memory dir, string memory configId) returns (Config memory json) {
    Files memory files;

    files.params = string.concat(dir, "params-", configId, ".json");
    if (!mvm.exists(files.params)) {
        revert(string.concat("No configuration exists: ", files.params));
    }
    files.assets = string.concat(dir, "assets-", configId, ".json");
    if (!mvm.exists(files.assets)) {
        revert(string.concat("No asset configuration exists: ", files.assets));
    }

    json.params = abi.decode(mvm.parseJson(mvm.readFile(files.params)), (Params));
    json.assets = getAssetConfigFrom(dir, configId);

    files.users = string.concat(dir, "users-", configId, ".json");
    if (mvm.exists(files.users)) {
        json.users = abi.decode(mvm.parseJson(mvm.readFile(files.users)), (Users));
    }

    if (json.params.common.admin == address(0)) {
        json.params.common.admin = mAddr("MNEMONIC_DEVNET", 0);
    }

    Deployed.init(configId);
}

// stacks too deep so need to split assets into separate function
function getAssetConfig(string memory network, string memory configId) returns (Assets memory json) {
    string memory dir = string.concat(CONST.CONFIG_DIR, network, "/");
    return getAssetConfigFrom(dir, configId);
}

function getAssetConfigFrom(string memory dir, string memory configId) returns (Assets memory) {
    Files memory files;

    files.assets = string.concat(dir, "assets-", configId, ".json");
    if (!mvm.exists(files.assets)) {
        revert(string.concat("No asset configuration exists: ", files.assets));
    }

    return abi.decode(mvm.parseJson(mvm.readFile(files.assets)), (Assets));
}

function getKrAsset(Config memory cfg, string memory symbol) pure returns (KrAssetParams memory result) {
    for (uint256 i; i < cfg.assets.kreskoAssets.length; i++) {
        if (cfg.assets.kreskoAssets[i].symbol.equals(symbol)) {
            result.json = cfg.assets.kreskoAssets[i];
            break;
        }
    }

    for (uint256 i; i < cfg.assets.extAssets.length; i++) {
        if (cfg.assets.extAssets[i].symbol.equals(result.json.underlyingSymbol)) {
            result.underlying = cfg.assets.extAssets[i];
            break;
        }
    }
    for (uint256 i; i < cfg.assets.tickers.length; i++) {
        if (cfg.assets.tickers[i].ticker.equals(result.json.config.ticker)) {
            result.ticker = cfg.assets.tickers[i];
            break;
        }
    }
}

function getExtAsset(Config memory cfg, string memory symbol) pure returns (ExtAssetParams memory result) {
    for (uint256 i; i < cfg.assets.extAssets.length; i++) {
        if (cfg.assets.extAssets[i].symbol.equals(symbol)) {
            result.json = cfg.assets.extAssets[i];
            break;
        }
    }
    for (uint256 i; i < cfg.assets.tickers.length; i++) {
        if (cfg.assets.tickers[i].ticker.equals(result.json.config.ticker)) {
            result.ticker = cfg.assets.tickers[i];
            break;
        }
    }
}

struct KrAssetParams {
    KrAssetConfig json;
    ExtAsset underlying;
    TickerConfig ticker;
}
struct ExtAssetParams {
    ExtAsset json;
    TickerConfig ticker;
}

struct Salts {
    bytes32 kresko;
    bytes32 multicall;
}

struct Config {
    Params params;
    Assets assets;
    Users users;
}

struct Params {
    string configId;
    address deploymentFactory;
    CommonInitArgs common;
    SCDPInitArgs scdp;
    MinterInitArgs minter;
    Periphery periphery;
    uint8 gatingPhase;
}

struct Periphery {
    address okNFT;
    address qfkNFT;
    address v3Router;
    address quoterv2;
}

struct Assets {
    string configId;
    bool mockFeeds;
    WNative wNative;
    ExtAsset[] extAssets;
    KrAssetConfig[] kreskoAssets;
    KISSConfig kiss;
    TickerConfig[] tickers;
    TradeRouteConfig[] customTradeRoutes;
}

struct KISSConfig {
    string name;
    string symbol;
    AssetJSON config;
}

struct WNative {
    bool mocked;
    string name;
    string symbol;
    IWETH9 token;
}

struct ExtAsset {
    bool mocked;
    bool isVaultAsset;
    string name;
    string symbol;
    address addr;
    AssetJSON config;
    VaultAssetJSON vault;
}

struct TickerConfig {
    string ticker;
    uint256 mockPrice;
    uint8 priceDecimals;
    address chainlink;
    address api3;
    address vault;
    bytes32 pythId;
    uint256 staleTimePyth;
    uint256 staleTimeAPI3;
    uint256 staleTimeChainlink;
    uint256 staleTimeRedstone;
    bool useAdapter;
    bool invertPyth;
    bool isClosable;
}

struct Balance {
    uint256 user;
    string symbol;
    uint256 amount;
    address assetsFrom;
}

struct MinterPosition {
    uint256 user;
    string depositSymbol;
    uint256 depositAmount;
    address assetsFrom;
    string mintSymbol;
    uint256 mintAmount;
}

struct SCDPPosition {
    uint256 user;
    uint256 kissDeposits;
    string vaultAssetSymbol;
    address assetsFrom;
}

struct TradeRouteConfig {
    string assetA;
    string assetB;
    bool enabled;
}

struct Account {
    uint32 idx;
    address addr;
}

struct NFTSetup {
    bool useMocks;
    address nftsFrom;
    uint256 userCount;
}

struct Users {
    string configId;
    string mnemonicEnv;
    Account[] accounts;
    Balance[] balances;
    SCDPPosition[] scdp;
    MinterPosition[] minter;
    NFTSetup nfts;
}

/// @notice forge cannot parse structs with fixed arrays so we use this intermediate struct
struct AssetJSON {
    string ticker;
    address anchor;
    Enums.OracleType[] oracles;
    uint16 factor;
    uint16 kFactor;
    uint16 openFee;
    uint16 closeFee;
    uint16 liqIncentive;
    uint256 maxDebtMinter;
    uint256 maxDebtSCDP;
    uint256 depositLimitSCDP;
    uint16 swapInFeeSCDP;
    uint16 swapOutFeeSCDP;
    uint16 protocolFeeShareSCDP;
    uint16 liqIncentiveSCDP;
    uint8 decimals;
    bool isMinterCollateral;
    bool isMinterMintable;
    bool isSharedCollateral;
    bool isSwapMintable;
    bool isSharedOrSwappedCollateral;
    bool isCoverAsset;
}

struct VaultAssetJSON {
    string[] feed;
    uint24 staleTime;
    uint32 depositFee;
    uint32 withdrawFee;
    uint248 maxDeposits;
    bool enabled;
}

struct KrAssetConfig {
    string name;
    string symbol;
    string underlyingSymbol;
    uint48 wrapFee;
    uint40 unwrapFee;
    AssetJSON config;
}

function get(Users memory users, uint256 i) returns (address) {
    Account memory acc = users.accounts[i];
    if (acc.addr == address(0)) {
        return mAddr(users.mnemonicEnv, acc.idx);
    }
    return acc.addr;
}

function getMockPrices(Config memory cfg) pure returns (bytes32[] memory ids, int64[] memory prices) {
    uint256 count;

    for (uint256 i; i < cfg.assets.tickers.length; i++) {
        if (cfg.assets.tickers[i].pythId != bytes32(0)) {
            count++;
        }
    }

    ids = new bytes32[](count);
    prices = new int64[](count);

    count = 0;
    for (uint256 i; i < cfg.assets.tickers.length; i++) {
        if (cfg.assets.tickers[i].pythId != bytes32(0)) {
            ids[count] = cfg.assets.tickers[i].pythId;
            prices[count] = int64(uint64(cfg.assets.tickers[i].mockPrice));
            count++;
        }
    }
}

uint256 constant ALL_USERS = 9999;

using {get} for Users global;
using {getMockPrices} for Config global;

using {LibJSON.metadata} for KrAssetConfig global;
using {LibJSON.toAsset} for AssetJSON global;

// solhint-disable state-visibility
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library CONST {
    string constant CONFIG_DIR = "configs/foundry/deploy/";

    bytes32 constant SALT_ID = bytes32("_1");
    bytes32 constant KISS_SALT = bytes32("KISS_1");
    bytes32 constant VAULT_SALT = bytes32("vKISS_1");
    bytes32 constant GM_SALT = bytes32("GatingManager_1");
    bytes32 constant MOCK_STATUS_SALT = bytes32("mock_market_status");
    bytes32 constant PYTH_MOCK_SALT = bytes32("MockPythEP_1");
    bytes32 constant MC_SALT = bytes32("Multicall_1");
    bytes32 constant D1_SALT = bytes32("DataV1_1");

    string constant KRASSET_NAME_PREFIX = "Kresko: ";
    string constant KISS_PREFIX = "Kresko: ";

    string constant ANCHOR_NAME_PREFIX = "Kresko Asset Anchor: ";
    string constant ANCHOR_SYMBOL_PREFIX = "a";

    string constant VAULT_NAME_PREFIX = "Kresko Vault: ";
    string constant VAULT_SYMBOL_PREFIX = "v";
}

// solhint-disable state-visibility
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Help, mvm} from "kresko-lib/utils/Libs.s.sol";
import {Asset} from "common/Types.sol";
import {IDeploymentFactory} from "factory/IDeploymentFactory.sol";

library Deployed {
    using Help for *;

    struct Cache {
        string deployId;
        address factory;
        mapping(string => address) cache;
        mapping(string => Asset) assets;
    }

    function addr(string memory name) internal returns (address) {
        return addr(name, block.chainid);
    }

    function factory() internal returns (IDeploymentFactory) {
        if (state().factory == address(0)) {
            return IDeploymentFactory(addr("Factory"));
        }
        return IDeploymentFactory(state().factory);
    }

    function factory(address _factory) internal {
        state().factory = _factory;
    }

    function addr(string memory name, uint256 chainId) internal returns (address) {
        require(!state().deployId.isEmpty(), "deployId is empty");

        string[] memory args = new string[](6);
        args[0] = "bun";
        args[1] = "utils/ffi.ts";
        args[2] = "getDeployment";
        args[3] = name;
        args[4] = chainId.str();
        args[5] = state().deployId;

        return mvm.ffi(args).str().toAddr();
    }

    function cache(string memory id, address _addr) internal returns (address) {
        ensureAddr(id, _addr);
        return (state().cache[id] = _addr);
    }

    function cache(string memory id, Asset memory asset) internal returns (Asset memory) {
        state().assets[id] = asset;
        return asset;
    }

    function cached(string memory id) internal view returns (address result) {
        result = state().cache[id];
        ensureAddr(id, result);
    }

    function cachedAsset(string memory id) internal view returns (Asset memory) {
        return state().assets[id];
    }

    function ensureAddr(string memory id, address _addr) internal pure {
        if (_addr == address(0)) {
            revert(string.concat("!exists: ", id));
        }
    }

    function init(string memory deployId) internal {
        state().deployId = deployId;
    }

    function state() internal pure returns (Cache storage ds) {
        bytes32 slot = bytes32("DEPLOY_CACHE");
        assembly {
            ds.slot := slot
        }
    }
}

// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IMinVM, mvm, mAddr, mPk, vmAddr} from "./MinVm.s.sol";

library LibVm {
    struct Callers {
        address msgSender;
        address txOrigin;
        string mode;
    }

    function callmode() internal returns (string memory) {
        (IMinVM.CallerMode _m, , ) = mvm.readCallers();
        return callModeStr(_m);
    }

    function clearCallers()
        internal
        returns (IMinVM.CallerMode m_, address s_, address o_)
    {
        (m_, s_, o_) = mvm.readCallers();
        if (
            m_ == IMinVM.CallerMode.Broadcast ||
            m_ == IMinVM.CallerMode.RecurrentBroadcast
        ) {
            mvm.stopBroadcast();
        } else if (
            m_ == IMinVM.CallerMode.Prank ||
            m_ == IMinVM.CallerMode.RecurrentPrank
        ) {
            mvm.stopPrank();
        }
    }

    function getTime() internal returns (uint256) {
        return uint256((mvm.unixTime() / 1000));
    }

    function restore(IMinVM.CallerMode _m, address _ss, address _so) internal {
        if (_m == IMinVM.CallerMode.Broadcast) {
            _ss == _so ? mvm.broadcast(_ss) : mvm.broadcast(_ss);
        } else if (_m == IMinVM.CallerMode.RecurrentBroadcast) {
            _ss == _so ? mvm.startBroadcast(_ss) : mvm.startBroadcast(_ss);
        } else if (_m == IMinVM.CallerMode.Prank) {
            _ss == _so ? mvm.prank(_ss, _so) : mvm.prank(_ss);
        } else if (_m == IMinVM.CallerMode.RecurrentPrank) {
            _ss == _so ? mvm.startPrank(_ss, _so) : mvm.startPrank(_ss);
        }
    }

    function unbroadcast()
        internal
        returns (IMinVM.CallerMode m_, address s_, address o_)
    {
        (m_, s_, o_) = mvm.readCallers();
        if (
            m_ == IMinVM.CallerMode.Broadcast ||
            m_ == IMinVM.CallerMode.RecurrentBroadcast
        ) {
            mvm.stopBroadcast();
        }
    }

    function unprank()
        internal
        returns (IMinVM.CallerMode m_, address s_, address o_)
    {
        (m_, s_, o_) = mvm.readCallers();
        if (
            m_ == IMinVM.CallerMode.Prank ||
            m_ == IMinVM.CallerMode.RecurrentPrank
        ) {
            mvm.stopPrank();
        }
    }

    function callers() internal returns (Callers memory) {
        (IMinVM.CallerMode m_, address s_, address o_) = mvm.readCallers();
        return Callers(s_, o_, callModeStr(m_));
    }

    function sender() internal returns (address s_) {
        (, s_, ) = mvm.readCallers();
    }

    function callModeStr(
        IMinVM.CallerMode _mode
    ) internal pure returns (string memory) {
        if (_mode == IMinVM.CallerMode.Broadcast) {
            return "broadcast";
        } else if (_mode == IMinVM.CallerMode.RecurrentBroadcast) {
            return "persistent broadcast";
        } else if (_mode == IMinVM.CallerMode.Prank) {
            return "prank";
        } else if (_mode == IMinVM.CallerMode.RecurrentPrank) {
            return "persistent prank";
        } else if (_mode == IMinVM.CallerMode.None) {
            return "none";
        } else {
            return "unknown mode";
        }
    }

    function getAddr(
        string memory _mEnv,
        uint32 _idx
    ) internal returns (address) {
        return mAddr(_mEnv, _idx);
    }

    function getPk(
        string memory _mEnv,
        uint32 _idx
    ) internal returns (uint256) {
        return mPk(_mEnv, _idx);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {logp} from "./Base.s.sol";

library PLog {
    function clg(string memory p0) internal pure {
        logp(abi.encodeWithSignature("log(string)", p0));
    }

    function clg(string memory p0, string memory p1) internal pure {
        logp(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function clg(address p0) internal pure {
        logp(abi.encodeWithSignature("log(address)", p0));
    }

    function clg(uint256 p0) internal pure {
        logp(abi.encodeWithSignature("log(uint256)", p0));
    }

    function clg(int256 p0) internal pure {
        logp(abi.encodeWithSignature("log(int256)", p0));
    }

    function clg(int256 p0, string memory p1) internal pure {
        logp(abi.encodeWithSignature("log(string,int256)", p1, p0));
    }

    function clg(bool p0) internal pure {
        logp(abi.encodeWithSignature("log(bool)", p0));
    }

    function clg(uint256 p1, string memory p0) internal pure {
        logp(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function clg(address p0, uint256 p1) internal pure {
        logp(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function clg(string memory p0, address p1, uint256 p2) internal pure {
        logp(
            abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2)
        );
    }

    function clg(address p1, string memory p0) internal pure {
        logp(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function blg(bytes32 p0) internal pure {
        logp(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function blg(bytes32 p1, string memory p0) internal pure {
        logp(abi.encodeWithSignature("log(string,bytes32)", p0, p1));
    }

    function blg(bytes memory p0) internal pure {
        logp(abi.encodeWithSignature("log(bytes)", p0));
    }

    function blg(bytes memory p1, string memory p0) internal pure {
        logp(abi.encodeWithSignature("log(string,bytes)", p0, p1));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ProxyAdmin} from "@oz/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "./TransparentUpgradeableProxy.sol";
import {IDeploymentFactory, Deployment, CreationKind, ITransparentUpgradeableProxy} from "factory/IDeploymentFactory.sol";
import {Conversions, Deploys, Proxies} from "libs/Utils.sol";
import {Solady} from "libs/Solady.sol";

/**
 * @author Kresko
 * @title DeploymentFactory
 * @notice Deploys contracts, optionally with a {TransparentUpgradeableProxy}. Is the (immutable) admin of proxies.
 * @notice Upgrades of proxies are only available for the owner of the DeploymentFactory.
 * @notice Deployments can be made by the owner or whitelisted deployer.
 */
contract DeploymentFactory is ProxyAdmin, IDeploymentFactory {
    using Proxies for address;
    using Conversions for bytes32;
    using Deploys for bytes32;
    using Deploys for bytes;

    /* -------------------------------------------------------------------------- */
    /*                                    State                                   */
    /* -------------------------------------------------------------------------- */
    mapping(address => bool) private _deployer;
    mapping(address => Deployment) private _deployment;
    Deployment[] private _deploymentList;

    /**
     * @dev Set the initial owner of the contract.
     */
    constructor(address initialOwner) ProxyAdmin(initialOwner) {}

    /* -------------------------------------------------------------------------- */
    /*                                    Auth                                    */
    /* -------------------------------------------------------------------------- */

    function setDeployer(address who, bool value) external onlyOwner {
        if (_deployer[who] == value) revert DeployerAlreadySet(who, value);

        _deployer[who] = value;
        emit DeployerSet(who, value);
    }

    function isDeployer(address who) external view returns (bool) {
        return _deployer[who];
    }

    modifier onlyDeployerOrOwner() {
        if (!_deployer[_msgSender()]) {
            _checkOwner();
        }
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Views                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IDeploymentFactory
    function getDeployment(address addr) external view returns (Deployment memory) {
        return _deployment[addr];
    }

    /// @inheritdoc IDeploymentFactory
    function getLatestDeployments(uint256 count) external view returns (Deployment[] memory result) {
        uint256 length = _deploymentList.length;
        if (count > length) count = length;

        result = new Deployment[](count);
        for (uint256 i = length - count; i < length; i++) {
            result[i - (length - count)] = _deploymentList[i];
        }
    }

    /// @inheritdoc IDeploymentFactory
    function getDeployByIndex(uint256 index) external view returns (Deployment memory) {
        return _deploymentList[index];
    }

    /// @inheritdoc IDeploymentFactory
    function getDeployments() external view returns (Deployment[] memory) {
        return _deploymentList;
    }

    /// @inheritdoc IDeploymentFactory
    function getDeployCount() external view returns (uint256) {
        return _deploymentList.length;
    }

    /// @inheritdoc IDeploymentFactory
    function isDeployment(address addr) external view returns (bool) {
        return _deployment[addr].version != 0;
    }

    /// @inheritdoc IDeploymentFactory
    function isNonProxy(address addr) external view returns (bool) {
        return _deployment[addr].implementation != address(0) && address(_deployment[addr].proxy) == address(0);
    }

    /// @inheritdoc IDeploymentFactory
    function isProxy(address addr) external view returns (bool) {
        return address(_deployment[addr].proxy) != address(0);
    }

    /// @inheritdoc IDeploymentFactory
    function isDeterministic(address addr) public view returns (bool) {
        return _deployment[addr].salt != bytes32(0);
    }

    /// @inheritdoc IDeploymentFactory
    function getImplementation(address proxy) external view override returns (address) {
        return _deployment[proxy].implementation;
    }

    /// @inheritdoc IDeploymentFactory
    function getProxyInitCodeHash(address implementation, bytes memory _calldata) public view returns (bytes32) {
        return implementation.proxyInitCodeHash(_calldata);
    }

    /// @inheritdoc IDeploymentFactory
    function getCreate2Address(bytes32 salt, bytes memory creationCode) public view returns (address) {
        return salt.peek2(address(this), creationCode);
    }

    /// @inheritdoc IDeploymentFactory
    function getCreate3Address(bytes32 salt) public view returns (address) {
        return salt.peek3();
    }

    function previewCreateProxy(address implementation, bytes memory _calldata) external returns (address proxyPreview) {
        proxyPreview = address(new TransparentUpgradeableProxy(implementation, address(this), _calldata));
        revert CreateProxyPreview(proxyPreview);
    }

    /// @inheritdoc IDeploymentFactory
    function previewCreate2Proxy(
        address implementation,
        bytes memory _calldata,
        bytes32 salt
    ) public view returns (address proxyPreview) {
        return getCreate2Address(salt, implementation.proxyInitCode(_calldata));
    }

    /// @inheritdoc IDeploymentFactory
    function previewCreate3Proxy(bytes32 salt) external view returns (address proxyPreview) {
        return getCreate3Address(salt);
    }

    function previewCreateProxyAndLogic(
        bytes memory implementation,
        bytes memory _calldata
    ) external returns (address proxyPreview, address implementationPreview) {
        implementationPreview = address(implementation.create());
        proxyPreview = address(new TransparentUpgradeableProxy(implementationPreview, address(this), _calldata));
        revert CreateProxyAndLogicPreview(proxyPreview, implementationPreview);
    }

    /// @inheritdoc IDeploymentFactory
    function previewCreate2ProxyAndLogic(
        bytes memory implementation,
        bytes memory _calldata,
        bytes32 salt
    ) external view returns (address proxyPreview, address implementationPreview) {
        proxyPreview = previewCreate2Proxy(
            (implementationPreview = getCreate2Address(salt.add(1), implementation)),
            _calldata,
            salt
        );
    }

    /// @inheritdoc IDeploymentFactory
    function previewCreate3ProxyAndLogic(
        bytes32 salt
    ) external view returns (address proxyPreview, address implementationPreview) {
        return (salt.peek3(), salt.add(1).peek3());
    }

    /// @inheritdoc IDeploymentFactory
    function previewCreate2Upgrade(
        ITransparentUpgradeableProxy proxy,
        bytes memory implementation
    ) external view returns (address implementationPreview, uint256 version) {
        Deployment memory info = _deployment[address(proxy)];

        version = info.version + 1;
        if (info.salt == bytes32(0) || version == 1) revert InvalidKind(info);

        return (getCreate2Address(info.salt.add(version), implementation), version);
    }

    /// @inheritdoc IDeploymentFactory
    function previewCreate3Upgrade(
        ITransparentUpgradeableProxy proxy
    ) external view returns (address implementationPreview, uint256 version) {
        Deployment memory info = _deployment[address(proxy)];

        version = info.version + 1;
        if (info.salt == bytes32(0) || version == 1) revert InvalidKind(info);

        return (getCreate3Address(info.salt.add(version)), version);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Creation                                  */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IDeploymentFactory
    function createProxy(
        address implementation,
        bytes memory _calldata
    ) public payable onlyDeployerOrOwner returns (Deployment memory newProxy) {
        newProxy.proxy = address(new TransparentUpgradeableProxy(implementation, address(this), _calldata)).asInterface();
        newProxy.implementation = implementation;
        newProxy.kind = CreationKind.CREATE;
        return _save(newProxy);
    }

    /// @inheritdoc IDeploymentFactory
    function create2Proxy(
        address implementation,
        bytes memory _calldata,
        bytes32 salt
    ) public payable onlyDeployerOrOwner returns (Deployment memory newProxy) {
        newProxy.proxy = salt.create2(implementation.proxyInitCode(_calldata)).asInterface();
        newProxy.implementation = implementation;
        newProxy.kind = CreationKind.CREATE2;
        newProxy.salt = salt;
        return _save(newProxy);
    }

    /// @inheritdoc IDeploymentFactory
    function create3Proxy(
        address implementation,
        bytes memory _calldata,
        bytes32 salt
    ) public payable onlyDeployerOrOwner returns (Deployment memory newProxy) {
        newProxy.proxy = salt.create3(implementation.proxyInitCode(_calldata)).asInterface();
        newProxy.implementation = implementation;
        newProxy.kind = CreationKind.CREATE3;
        newProxy.salt = salt;
        return _save(newProxy);
    }

    /* ---------------------------- With implentation --------------------------- */

    /// @inheritdoc IDeploymentFactory
    function createProxyAndLogic(
        bytes memory implementation,
        bytes memory _calldata
    ) external payable onlyDeployerOrOwner returns (Deployment memory) {
        return createProxy(implementation.create(), _calldata);
    }

    /// @inheritdoc IDeploymentFactory
    function create2ProxyAndLogic(
        bytes memory implementation,
        bytes memory _calldata,
        bytes32 salt
    ) external payable onlyDeployerOrOwner returns (Deployment memory) {
        return create2Proxy(salt.add(1).create2(implementation), _calldata, salt);
    }

    /// @inheritdoc IDeploymentFactory
    function create3ProxyAndLogic(
        bytes memory implementation,
        bytes memory _calldata,
        bytes32 salt
    ) external payable onlyDeployerOrOwner returns (Deployment memory) {
        return create3Proxy(salt.add(1).create3(implementation), _calldata, salt);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Upgrade                                  */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ProxyAdmin
    function upgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory _calldata
    ) public payable override(ProxyAdmin) {
        Deployment memory info = _deployment[address(proxy)];

        info.implementation = implementation;
        ProxyAdmin.upgradeAndCall(proxy, implementation, _calldata);

        _save(info);
    }

    /// @inheritdoc IDeploymentFactory
    function upgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        bytes memory implementation,
        bytes memory _calldata
    ) external payable returns (Deployment memory) {
        return upgradeAndCallReturn(proxy, implementation.create(), _calldata);
    }

    /// @inheritdoc IDeploymentFactory
    function upgradeAndCallReturn(
        ITransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory _calldata
    ) public payable returns (Deployment memory) {
        Deployment memory info = _deployment[address(proxy)];

        info.implementation = implementation;
        ProxyAdmin.upgradeAndCall(proxy, implementation, _calldata);

        return _save(info);
    }

    /// @inheritdoc IDeploymentFactory
    function create2UpgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        bytes memory implementation,
        bytes memory _calldata
    ) external payable returns (Deployment memory) {
        Deployment memory info = _deployment[address(proxy)];
        if (info.salt == bytes32(0)) revert InvalidKind(info);
        return upgradeAndCallReturn(proxy, info.salt.add(info.version + 1).create2(implementation), _calldata);
    }

    /// @inheritdoc IDeploymentFactory
    function create3UpgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        bytes memory implementation,
        bytes memory _calldata
    ) public payable returns (Deployment memory) {
        Deployment memory info = _deployment[address(proxy)];
        if (info.salt == bytes32(0)) revert InvalidKind(info);
        return upgradeAndCallReturn(proxy, info.salt.add(info.version + 1).create3(implementation), _calldata);
    }

    /// @inheritdoc IDeploymentFactory
    function batchStatic(bytes[] calldata calls) external view returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        unchecked {
            for (uint256 i; i < calls.length; i++) {
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, bytes memory result) = address(this).staticcall(calls[i]);

                if (!success) _tryParseRevert(result);
                results[i] = result;
            }
        }
    }

    /// @inheritdoc IDeploymentFactory
    function batch(bytes[] calldata calls) external payable onlyDeployerOrOwner returns (bytes[] memory) {
        return Solady.multicall(calls);
    }

    function deployCreate2(
        bytes memory creationCode,
        bytes calldata _calldata,
        bytes32 salt
    ) external payable onlyDeployerOrOwner returns (Deployment memory newDeployment) {
        newDeployment.implementation = salt.create2(creationCode);

        if (_calldata.length != 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = newDeployment.implementation.call{value: msg.value}(_calldata);
            if (!success) _tryParseRevert(result);
        }

        newDeployment.kind = CreationKind.CREATE2;
        newDeployment.salt = salt;

        return _save(newDeployment);
    }

    function deployCreate3(
        bytes memory creationCode,
        bytes calldata _calldata,
        bytes32 salt
    ) external payable onlyDeployerOrOwner returns (Deployment memory newDeployment) {
        newDeployment.implementation = salt.create3(creationCode);

        if (_calldata.length != 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = newDeployment.implementation.call{value: msg.value}(_calldata);
            if (!success) _tryParseRevert(result);
        }

        newDeployment.kind = CreationKind.CREATE3;
        newDeployment.salt = salt;

        return _save(newDeployment);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Internals                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Updates deployment fields to _deployment and _deploymentList.
     */
    function _save(Deployment memory update) internal returns (Deployment memory) {
        address deploymentAddr = address(update.proxy) != address(0) ? address(update.proxy) : update.implementation;
        if (deploymentAddr == address(0)) revert InvalidKind(update);

        uint48 blockTimestamp = uint48(block.timestamp);
        update.version++;
        update.updatedAt = blockTimestamp;

        if (update.createdAt == 0) {
            update.index = uint48(_deploymentList.length);
            update.createdAt = blockTimestamp;
            _deploymentList.push(update);
            emit Deployed(update);
        } else {
            _deploymentList[update.index] = update;
            emit Upgrade(update);
        }

        _deployment[deploymentAddr] = update;

        return update;
    }

    /**
     * @notice Function that tries to extract some useful information about a failed call.
     * @dev If returned data is malformed or has incorrect encoding this can fail itself.
     */
    function _tryParseRevert(bytes memory _returnData) internal pure {
        // If the _res length is less than 68, then
        // the transaction failed with custom error or silently (without a revert message)
        if (_returnData.length < 68) {
            revert BatchRevertSilentOrCustomError(_returnData);
        }

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {IAggregatorV3} from "kresko-lib/vendor/IAggregatorV3.sol";
import {IERC20} from "kresko-lib/token/IERC20.sol";
import {ERC20} from "kresko-lib/token/ERC20.sol";
import {SafeTransfer} from "kresko-lib/token/SafeTransfer.sol";
import {IVault} from "vault/interfaces/IVault.sol";

import {Arrays} from "libs/Arrays.sol";
import {FixedPointMath} from "libs/FixedPointMath.sol";

import {Errors} from "common/Errors.sol";
import {isSequencerUp} from "common/funcs/Utils.sol";
import {Validations} from "common/Validations.sol";

import {VEvent} from "vault/VEvent.sol";
import {VAssets} from "vault/funcs/VAssets.sol";
import {VaultAsset, VaultConfiguration} from "vault/VTypes.sol";

/**
 * @title Vault - A multiple deposit token vault.
 * @author Kresko
 * @notice This is derived from ERC4626 standard.
 * @notice Users deposit tokens into the vault and receive shares of equal value in return.
 * @notice Shares are redeemable for the underlying tokens at any time.
 * @notice Price or exchange rate of SHARE/USD is determined by the total value of the underlying tokens in the vault and the share supply.
 */
contract Vault is IVault, ERC20 {
    using SafeTransfer for IERC20;
    using FixedPointMath for uint256;
    using VAssets for uint256;
    using VAssets for VaultAsset;
    using Arrays for address[];

    /* -------------------------------------------------------------------------- */
    /*                                    State                                   */
    /* -------------------------------------------------------------------------- */
    VaultConfiguration internal _config;
    mapping(address => VaultAsset) internal _assets;
    address[] public assetList;
    uint256 public constant TARGET_PRICE = 1e18;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint8 _oracleDecimals,
        address _governance,
        address _feeRecipient,
        address _sequencerUptimeFeed
    ) ERC20(_name, _symbol, _decimals) {
        _config.governance = _governance;
        _config.oracleDecimals = _oracleDecimals;
        _config.feeRecipient = _feeRecipient;
        _config.sequencerUptimeFeed = _sequencerUptimeFeed;
        _config.sequencerGracePeriodTime = 0;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Modifiers                                 */
    /* -------------------------------------------------------------------------- */

    modifier onlyGovernance() {
        if (msg.sender != _config.governance) revert Errors.INVALID_SENDER(msg.sender, _config.governance);
        _;
    }

    modifier check(address assetAddr) {
        if (!_assets[assetAddr].enabled) revert Errors.ASSET_NOT_ENABLED(Errors.id(assetAddr));
        _;
    }

    /// @notice Validate deposits.
    function _checkAssetsIn(address assetAddr, uint256 assetsIn, uint256 sharesOut) private view {
        uint256 depositLimit = maxDeposit(assetAddr);

        if (sharesOut == 0) revert Errors.ZERO_SHARES_OUT(Errors.id(assetAddr), assetsIn);
        if (assetsIn == 0) revert Errors.ZERO_ASSETS_IN(Errors.id(assetAddr), sharesOut);
        if (assetsIn > depositLimit) revert Errors.EXCEEDS_ASSET_DEPOSIT_LIMIT(Errors.id(assetAddr), assetsIn, depositLimit);
    }

    /* -------------------------------------------------------------------------- */
    /*                                Functionality                               */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IVault
    function deposit(
        address assetAddr,
        uint256 assetsIn,
        address receiver
    ) public virtual check(assetAddr) returns (uint256 sharesOut, uint256 assetFee) {
        (sharesOut, assetFee) = previewDeposit(assetAddr, assetsIn);

        _checkAssetsIn(assetAddr, assetsIn, sharesOut);

        IERC20 token = IERC20(assetAddr);

        token.safeTransferFrom(msg.sender, address(this), assetsIn);

        if (assetFee > 0) token.safeTransfer(_config.feeRecipient, assetFee);

        _mint(receiver == address(0) ? msg.sender : receiver, sharesOut);

        emit VEvent.Deposit(msg.sender, receiver, assetAddr, assetsIn, sharesOut);
    }

    /// @inheritdoc IVault
    function mint(
        address assetAddr,
        uint256 sharesOut,
        address receiver
    ) public virtual check(assetAddr) returns (uint256 assetsIn, uint256 assetFee) {
        (assetsIn, assetFee) = previewMint(assetAddr, sharesOut);

        _checkAssetsIn(assetAddr, assetsIn, sharesOut);

        IERC20 token = IERC20(assetAddr);

        token.safeTransferFrom(msg.sender, address(this), assetsIn);

        if (assetFee > 0) token.safeTransfer(_config.feeRecipient, assetFee);

        _mint(receiver == address(0) ? msg.sender : receiver, sharesOut);

        emit VEvent.Deposit(msg.sender, receiver, assetAddr, assetsIn, sharesOut);
    }

    /// @inheritdoc IVault
    function redeem(
        address assetAddr,
        uint256 sharesIn,
        address receiver,
        address owner
    ) public virtual check(assetAddr) returns (uint256 assetsOut, uint256 assetFee) {
        (assetsOut, assetFee) = previewRedeem(assetAddr, sharesIn);

        if (assetsOut == 0) revert Errors.ZERO_ASSETS_OUT(Errors.id(assetAddr), sharesIn);

        IERC20 token = IERC20(assetAddr);

        uint256 balance = token.balanceOf(address(this));

        if (assetsOut + assetFee > balance) {
            VaultAsset storage asset = _assets[assetAddr];

            (uint256 tSupply, uint256 tAssets) = _getTSupplyTAssets();
            sharesIn = asset.usdWad(_config, balance).mulDivUp(tSupply, tAssets);
            (assetsOut, assetFee) = previewRedeem(assetAddr, sharesIn);

            if (assetsOut > balance) {
                assetsOut = balance;
            }
            token.safeTransfer(receiver, assetsOut);
        } else {
            token.safeTransfer(receiver, assetsOut);
        }

        if (assetFee > 0) token.safeTransfer(_config.feeRecipient, assetFee);

        if (msg.sender != owner) {
            uint256 allowed = _allowances[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) _allowances[owner][msg.sender] = allowed - sharesIn;
        }

        _burn(owner, sharesIn);

        emit VEvent.Withdraw(msg.sender, receiver, assetAddr, owner, assetsOut, sharesIn);
    }

    /// @inheritdoc IVault
    function withdraw(
        address assetAddr,
        uint256 assetsOut,
        address receiver,
        address owner
    ) public virtual check(assetAddr) returns (uint256 sharesIn, uint256 assetFee) {
        (sharesIn, assetFee) = previewWithdraw(assetAddr, assetsOut);

        if (sharesIn == 0) revert Errors.ZERO_SHARES_IN(Errors.id(assetAddr), assetsOut);

        if (msg.sender != owner) {
            uint256 allowed = _allowances[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) _allowances[owner][msg.sender] = allowed - sharesIn;
        }

        IERC20 token = IERC20(assetAddr);

        if (assetFee > 0) token.safeTransfer(_config.feeRecipient, assetFee);

        _burn(owner, sharesIn);

        token.safeTransfer(receiver, assetsOut);

        emit VEvent.Withdraw(msg.sender, receiver, assetAddr, owner, assetsOut, sharesIn);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Views                                   */
    /* -------------------------------------------------------------------------- */
    /// @inheritdoc IVault
    function getConfig() external view returns (VaultConfiguration memory) {
        return _config;
    }

    /// @inheritdoc IVault
    function assets(address assetAddr) external view returns (VaultAsset memory) {
        return _assets[assetAddr];
    }

    /// @inheritdoc IVault
    function allAssets() external view returns (VaultAsset[] memory result) {
        result = new VaultAsset[](assetList.length);
        for (uint256 i; i < assetList.length; i++) {
            result[i] = _assets[assetList[i]];
        }
    }

    function assetPrice(address assetAddr) external view returns (uint256) {
        return _assets[assetAddr].price(_config);
    }

    /// @inheritdoc IVault
    function totalAssets() public view virtual returns (uint256 result) {
        for (uint256 i; i < assetList.length; ) {
            result += _assets[assetList[i]].getDepositValueWad(_config);
            unchecked {
                i++;
            }
        }
    }

    /// @inheritdoc IVault
    function exchangeRate() public view virtual returns (uint256) {
        uint256 tAssets = totalAssets();
        uint256 tSupply = totalSupply();
        if (tSupply == 0 || tAssets == 0) return TARGET_PRICE;
        return (tAssets * 1e18) / tSupply;
    }

    /// @inheritdoc IVault
    function previewDeposit(
        address assetAddr,
        uint256 assetsIn
    ) public view virtual returns (uint256 sharesOut, uint256 assetFee) {
        (uint256 tSupply, uint256 tAssets) = _getTSupplyTAssets();

        VaultAsset storage asset = _assets[assetAddr];

        (assetsIn, assetFee) = asset.handleDepositFee(assetsIn);

        sharesOut = asset.usdWad(_config, assetsIn).mulDivDown(tSupply, tAssets);
    }

    /// @inheritdoc IVault
    function previewMint(
        address assetAddr,
        uint256 sharesOut
    ) public view virtual returns (uint256 assetsIn, uint256 assetFee) {
        (uint256 tSupply, uint256 tAssets) = _getTSupplyTAssets();

        VaultAsset storage asset = _assets[assetAddr];

        (assetsIn, assetFee) = asset.handleMintFee(asset.getAmount(_config, sharesOut.mulDivUp(tAssets, tSupply)));
    }

    /// @inheritdoc IVault
    function previewRedeem(
        address assetAddr,
        uint256 sharesIn
    ) public view virtual returns (uint256 assetsOut, uint256 assetFee) {
        (uint256 tSupply, uint256 tAssets) = _getTSupplyTAssets();

        VaultAsset storage asset = _assets[assetAddr];

        (assetsOut, assetFee) = asset.handleRedeemFee(asset.getAmount(_config, sharesIn.mulDivDown(tAssets, tSupply)));
    }

    /// @inheritdoc IVault
    function previewWithdraw(
        address assetAddr,
        uint256 assetsOut
    ) public view virtual returns (uint256 sharesIn, uint256 assetFee) {
        (uint256 tSupply, uint256 tAssets) = _getTSupplyTAssets();

        VaultAsset storage asset = _assets[assetAddr];

        (assetsOut, assetFee) = asset.handleWithdrawFee(assetsOut);

        sharesIn = asset.usdWad(_config, assetsOut).mulDivUp(tSupply, tAssets);

        if (sharesIn > tSupply) revert Errors.ROUNDING_ERROR(Errors.id(assetAddr), sharesIn, tSupply);
    }

    /// @inheritdoc IVault
    function maxRedeem(address assetAddr, address owner) public view virtual returns (uint256 max) {
        (uint256 assetsOut, uint256 fee) = previewRedeem(assetAddr, _balances[owner]);
        uint256 balance = IERC20(assetAddr).balanceOf(address(this));

        if (assetsOut + fee > balance) {
            (uint256 tSupply, uint256 tAssets) = _getTSupplyTAssets();
            return _assets[assetAddr].usdWad(_config, balance).mulDivDown(tSupply, tAssets);
        } else {
            return _balances[owner];
        }
    }

    /// @inheritdoc IVault
    function maxWithdraw(address assetAddr, address owner) external view returns (uint256 max) {
        (max, ) = previewRedeem(assetAddr, maxRedeem(assetAddr, owner));
    }

    /// @inheritdoc IVault
    function maxDeposit(address assetAddr) public view virtual returns (uint256) {
        return _assets[assetAddr].maxDeposits - _assets[assetAddr].token.balanceOf(address(this));
    }

    /// @inheritdoc IVault
    function maxMint(address assetAddr, address user) external view virtual returns (uint256 max) {
        uint256 balance = IERC20(assetAddr).balanceOf(user);
        uint256 depositLimit = maxDeposit(assetAddr);
        if (balance > depositLimit) {
            (max, ) = previewDeposit(assetAddr, depositLimit);
        } else {
            (max, ) = previewDeposit(assetAddr, balance);
        }
    }

    function _getTSupplyTAssets() private view returns (uint256 tSupply, uint256 tAssets) {
        tSupply = totalSupply();
        tAssets = totalAssets();

        if (tSupply == 0 || tAssets == 0) {
            tSupply = 1 ether;
            tAssets = TARGET_PRICE;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Admin                                   */
    /* -------------------------------------------------------------------------- */
    function setSequencerUptimeFeed(address newFeedAddr, uint96 gracePeriod) external onlyGovernance {
        if (newFeedAddr != address(0)) {
            if (!isSequencerUp(newFeedAddr, gracePeriod)) revert Errors.INVALID_SEQUENCER_UPTIME_FEED(newFeedAddr);
        }
        _config.sequencerUptimeFeed = newFeedAddr;
        _config.sequencerGracePeriodTime = gracePeriod;
    }

    /// @inheritdoc IVault
    function addAsset(VaultAsset memory assetConfig) external onlyGovernance returns (VaultAsset memory) {
        address assetAddr = address(assetConfig.token);
        if (assetAddr == address(0)) revert Errors.ZERO_ADDRESS();
        if (_assets[assetAddr].decimals != 0) revert Errors.ASSET_ALREADY_EXISTS(Errors.id(assetAddr));

        assetConfig.decimals = assetConfig.token.decimals();
        Validations.validateVaultAssetDecimals(assetAddr, assetConfig.decimals);
        Validations.validateFees(assetAddr, uint16(assetConfig.depositFee), uint16(assetConfig.withdrawFee));

        _assets[assetAddr] = assetConfig;
        assetList.pushUnique(assetAddr);

        emit VEvent.AssetAdded(
            assetAddr,
            address(assetConfig.feed),
            assetConfig.token.symbol(),
            assetConfig.staleTime,
            _assets[assetAddr].price(_config),
            assetConfig.maxDeposits,
            block.timestamp
        );

        return assetConfig;
    }

    /// @inheritdoc IVault
    function removeAsset(address assetAddr) external onlyGovernance {
        assetList.removeExisting(assetAddr);
        delete _assets[assetAddr];
        emit VEvent.AssetRemoved(assetAddr, block.timestamp);
    }

    /// @inheritdoc IVault
    function setAssetFeed(address assetAddr, address newFeedAddr, uint24 newStaleTime) external onlyGovernance {
        _assets[assetAddr].feed = IAggregatorV3(newFeedAddr);
        _assets[assetAddr].staleTime = newStaleTime;
        emit VEvent.OracleSet(assetAddr, newFeedAddr, newStaleTime, _assets[assetAddr].price(_config), block.timestamp);
    }

    /// @inheritdoc IVault
    function setFeedPricePrecision(uint8 newDecimals) external onlyGovernance {
        _config.oracleDecimals = newDecimals;
    }

    /// @inheritdoc IVault
    function setAssetEnabled(address assetAddr, bool isEnabled) external onlyGovernance {
        _assets[assetAddr].enabled = isEnabled;
        emit VEvent.AssetEnabledChange(assetAddr, isEnabled, block.timestamp);
    }

    /// @inheritdoc IVault
    function setDepositFee(address assetAddr, uint16 newDepositFee) external onlyGovernance {
        Validations.validateFees(assetAddr, newDepositFee, newDepositFee);
        _assets[assetAddr].depositFee = newDepositFee;
    }

    /// @inheritdoc IVault
    function setWithdrawFee(address assetAddr, uint16 newWithdrawFee) external onlyGovernance {
        Validations.validateFees(assetAddr, newWithdrawFee, newWithdrawFee);
        _assets[assetAddr].withdrawFee = newWithdrawFee;
    }

    /// @inheritdoc IVault
    function setMaxDeposits(address assetAddr, uint248 newMaxDeposits) external onlyGovernance {
        _assets[assetAddr].maxDeposits = newMaxDeposits;
    }

    /// @inheritdoc IVault
    function setGovernance(address newGovernance) external onlyGovernance {
        _config.pendingGovernance = newGovernance;
    }

    /// @inheritdoc IVault
    function acceptGovernance() external {
        if (msg.sender != _config.pendingGovernance) revert Errors.INVALID_SENDER(msg.sender, _config.pendingGovernance);
        _config.governance = _config.pendingGovernance;
        _config.pendingGovernance = address(0);
    }

    /// @inheritdoc IVault
    function setFeeRecipient(address newFeeRecipient) external onlyGovernance {
        _config.feeRecipient = newFeeRecipient;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {AccessControlEnumerableUpgradeable} from "@oz-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {IERC165} from "vendor/IERC165.sol";

import {Role} from "common/Constants.sol";
import {Errors} from "common/Errors.sol";
import {IKreskoAssetIssuer} from "./IKreskoAssetIssuer.sol";
import {IKreskoAssetAnchor} from "./IKreskoAssetAnchor.sol";
import {IERC4626Upgradeable} from "./IERC4626Upgradeable.sol";
import {ERC4626Upgradeable, IKreskoAsset} from "./ERC4626Upgradeable.sol";

/* solhint-disable no-empty-blocks */

/**
 * @title Kresko Asset Anchor
 * Pro-rata representation of the underlying kresko asset.
 * Based on ERC-4626 by Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
 *
 * @notice Main purpose of this token is to represent a static amount of the possibly rebased underlying KreskoAsset.
 * Main use-cases are normalized book-keeping, bridging and integration with external contracts.
 *
 * @notice Shares means amount of this token.
 * @notice Assets mean amount of KreskoAssets.
 * @author Kresko
 */
contract KreskoAssetAnchor is ERC4626Upgradeable, IKreskoAssetAnchor, AccessControlEnumerableUpgradeable {
    /* -------------------------------------------------------------------------- */
    /*                                 Immutables                                 */
    /* -------------------------------------------------------------------------- */
    constructor(IKreskoAsset _asset) payable ERC4626Upgradeable(_asset) {
        // _disableInitializers();
    }

    function initialize(IKreskoAsset _asset, string memory _name, string memory _symbol, address _admin) external initializer {
        // ERC4626
        __ERC4626Upgradeable_init(_asset, _name, _symbol);
        // Default admin setup
        _grantRole(Role.DEFAULT_ADMIN, _admin);
        _grantRole(Role.ADMIN, _admin);
        // Setup the operator, which is the protocol linked to the main asset
        _grantRole(Role.OPERATOR, asset.kresko());

        _asset.setAnchorToken(address(this));
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlEnumerableUpgradeable, IERC165) returns (bool) {
        return
            interfaceId != 0xffffffff &&
            (interfaceId == type(IKreskoAssetAnchor).interfaceId ||
                interfaceId == type(IKreskoAssetIssuer).interfaceId ||
                interfaceId == 0x01ffc9a7 ||
                interfaceId == 0x36372b07 ||
                super.supportsInterface(interfaceId));
    }

    /// @inheritdoc IKreskoAssetAnchor
    function reinitializeERC20(
        string memory _name,
        string memory _symbol,
        uint8 _version
    ) external onlyRole(Role.ADMIN) reinitializer(_version) {
        __ERC20Upgradeable_init(_name, _symbol, decimals);
    }

    /// @inheritdoc IKreskoAssetAnchor
    function totalAssets() public view virtual override(IKreskoAssetAnchor, ERC4626Upgradeable) returns (uint256) {
        return asset.totalSupply();
    }

    /// @inheritdoc IKreskoAssetIssuer
    function convertToAssets(
        uint256 shares
    ) public view virtual override(ERC4626Upgradeable, IKreskoAssetIssuer) returns (uint256 assets) {
        return super.convertToAssets(shares);
    }

    /// @inheritdoc IKreskoAssetIssuer
    function convertToShares(
        uint256 assets
    ) public view virtual override(ERC4626Upgradeable, IKreskoAssetIssuer) returns (uint256 shares) {
        return super.convertToShares(assets);
    }

    function convertManyToShares(uint256[] calldata assets) external view returns (uint256[] memory shares) {
        shares = new uint256[](assets.length);
        for (uint256 i; i < assets.length; ) {
            shares[i] = super.convertToShares(assets[i]);
            i++;
        }
        return shares;
    }

    /// @inheritdoc IKreskoAssetIssuer
    function convertManyToAssets(uint256[] calldata shares) external view returns (uint256[] memory assets) {
        assets = new uint256[](shares.length);
        for (uint256 i; i < shares.length; ) {
            assets[i] = super.convertToAssets(shares[i]);
            i++;
        }
        return assets;
    }

    /// @inheritdoc IKreskoAssetIssuer
    function issue(
        uint256 _assets,
        address _to
    ) public virtual override(ERC4626Upgradeable, IKreskoAssetIssuer) returns (uint256 shares) {
        _onlyOperator();
        shares = super.issue(_assets, _to);
    }

    /// @inheritdoc IKreskoAssetIssuer
    function destroy(
        uint256 _assets,
        address _from
    ) public virtual override(ERC4626Upgradeable, IKreskoAssetIssuer) returns (uint256 shares) {
        _onlyOperator();
        shares = super.destroy(_assets, _from);
    }

    /// @inheritdoc IKreskoAssetAnchor
    function wrap(uint256 assets) external {
        _onlyOperatorOrAsset();
        // Mint anchor shares to the asset contract
        _mint(address(asset), convertToShares(assets));
    }

    /// @inheritdoc IKreskoAssetAnchor
    function unwrap(uint256 assets) external {
        _onlyOperatorOrAsset();
        // Burn anchor shares from the asset contract
        _burn(address(asset), convertToShares(assets));
    }

    /// @notice No support for direct interactions yet
    function mint(uint256, address) public pure override(ERC4626Upgradeable, IERC4626Upgradeable) returns (uint256) {
        revert Errors.MINT_NOT_SUPPORTED();
    }

    /// @notice No support for direct interactions yet
    function deposit(uint256, address) public pure override(ERC4626Upgradeable, IERC4626Upgradeable) returns (uint256) {
        revert Errors.DEPOSIT_NOT_SUPPORTED();
    }

    /// @notice No support for direct interactions yet
    function withdraw(
        uint256,
        address,
        address
    ) public pure override(ERC4626Upgradeable, IERC4626Upgradeable) returns (uint256) {
        revert Errors.WITHDRAW_NOT_SUPPORTED();
    }

    /// @notice No support for direct interactions yet
    function redeem(uint256, address, address) public pure override(ERC4626Upgradeable, IERC4626Upgradeable) returns (uint256) {
        revert Errors.REDEEM_NOT_SUPPORTED();
    }

    /* -------------------------------------------------------------------------- */
    /*                            INTERNAL HOOKS LOGIC                            */
    /* -------------------------------------------------------------------------- */
    function _onlyOperator() internal view {
        if (!hasRole(Role.OPERATOR, msg.sender)) {
            revert Errors.SENDER_NOT_OPERATOR(_anchorId(), msg.sender, asset.kresko());
        }
    }

    function _onlyOperatorOrAsset() private view {
        if (msg.sender != address(asset) && !hasRole(Role.OPERATOR, msg.sender)) {
            revert Errors.INVALID_KRASSET_OPERATOR(_assetId(), msg.sender, getRoleMember(Role.OPERATOR, 0));
        }
    }

    function _beforeWithdraw(uint256 assets, uint256 shares) internal virtual override {
        super._beforeWithdraw(assets, shares);
    }

    function _afterDeposit(uint256 assets, uint256 shares) internal virtual override {
        super._afterDeposit(assets, shares);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {Asset} from "common/Types.sol";
import {Solady} from "libs/Solady.sol";
import {ITransparentUpgradeableProxy, Deployment} from "factory/IDeploymentFactory.sol";
import {TransparentUpgradeableProxy} from "factory/TransparentUpgradeableProxy.sol";

library Conversions {
    function toAddress(bytes32 b) internal pure returns (address) {
        return address(uint160(uint256(b)));
    }

    function toBytes32(address a) internal pure returns (bytes32) {
        return bytes32(bytes20(uint160(a)));
    }

    function toAddr(bytes memory b) internal pure returns (address) {
        return abi.decode(b, (address));
    }

    function toDeployment(bytes memory b) internal pure returns (Deployment memory) {
        return abi.decode(b, (Deployment));
    }

    function toAsset(bytes memory b) internal pure returns (Asset memory) {
        return abi.decode(b, (Asset));
    }

    function toArray(bytes memory value) internal pure returns (bytes[] memory result) {
        result = new bytes[](1);
        result[0] = value;
    }

    function add(bytes32 a, uint256 b) internal pure returns (bytes32) {
        return bytes32(uint256(a) + b);
    }

    function sub(bytes32 a, uint256 b) internal pure returns (bytes32) {
        return bytes32(uint256(a) - b);
    }

    function map(
        bytes[] memory rawData,
        function(bytes memory) pure returns (address) dataHandler
    ) internal pure returns (address[] memory result) {
        result = new address[](rawData.length);
        unchecked {
            for (uint256 i; i < rawData.length; i++) {
                result[i] = dataHandler(rawData[i]);
            }
        }
    }

    function map(
        bytes[] memory rawData,
        function(bytes memory) pure returns (Deployment memory) dataHandler
    ) internal pure returns (Deployment[] memory result) {
        result = new Deployment[](rawData.length);
        unchecked {
            for (uint256 i; i < rawData.length; i++) {
                result[i] = dataHandler(rawData[i]);
            }
        }
    }
}

library Deploys {
    function create(bytes memory creationCode, uint256 value) internal returns (address location) {
        assembly {
            location := create(value, add(creationCode, 0x20), mload(creationCode))
            if iszero(extcodesize(location)) {
                revert(0, 0)
            }
        }
    }

    function create2(bytes32 salt, bytes memory creationCode, uint256 value) internal returns (address location) {
        uint256 _salt = uint256(salt);
        assembly {
            location := create2(value, add(creationCode, 0x20), mload(creationCode), _salt)
            if iszero(extcodesize(location)) {
                revert(0, 0)
            }
        }
    }

    function create3(bytes32 salt, bytes memory creationCode, uint256 value) internal returns (address location) {
        return Solady.create3(salt, creationCode, value);
    }

    function create(bytes memory creationCode) internal returns (address location) {
        return create(creationCode, msg.value);
    }

    function create2(bytes32 salt, bytes memory creationCode) internal returns (address location) {
        return create2(salt, creationCode, msg.value);
    }

    function create3(bytes32 salt, bytes memory creationCode) internal returns (address location) {
        return create3(salt, creationCode, msg.value);
    }

    function peek2(bytes32 salt, address _c2caller, bytes memory creationCode) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), _c2caller, salt, keccak256(creationCode))))));
    }

    function peek3(bytes32 salt) internal view returns (address) {
        return Solady.peek3(salt);
    }
}

library Proxies {
    using Proxies for address;

    function proxyInitCode(
        address implementation,
        address _factory,
        bytes memory _calldata
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(type(TransparentUpgradeableProxy).creationCode, abi.encode(implementation, _factory, _calldata));
    }

    function proxyInitCode(address implementation, bytes memory _calldata) internal view returns (bytes memory) {
        return implementation.proxyInitCode(address(this), _calldata);
    }

    function proxyInitCodeHash(
        address implementation,
        address _factory,
        bytes memory _calldata
    ) internal pure returns (bytes32) {
        return keccak256(implementation.proxyInitCode(_factory, _calldata));
    }

    function proxyInitCodeHash(address implementation, bytes memory _calldata) internal view returns (bytes32) {
        return proxyInitCodeHash(implementation, address(this), _calldata);
    }

    function asInterface(address proxy) internal pure returns (ITransparentUpgradeableProxy) {
        return ITransparentUpgradeableProxy(proxy);
    }
}

// solhint-disable no-empty-blocks
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {AccessControlEnumerableUpgradeable} from "@oz-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {PausableUpgradeable} from "@oz-upgradeable/utils/PausableUpgradeable.sol";
import {SafeTransfer} from "kresko-lib/token/SafeTransfer.sol";
import {ERC20Upgradeable} from "kresko-lib/token/ERC20Upgradeable.sol";
import {IERC20} from "kresko-lib/token/IERC20.sol";
import {IERC165} from "vendor/IERC165.sol";
import {PercentageMath} from "libs/PercentageMath.sol";
import {Percents, Role} from "common/Constants.sol";
import {Errors} from "common/Errors.sol";
import {IKreskoAssetAnchor} from "./IKreskoAssetAnchor.sol";
import {Rebaser} from "./Rebaser.sol";
import {IKreskoAsset, ISyncable} from "./IKreskoAsset.sol";

/**
 * @title Kresko Synthethic Asset, rebasing ERC20 with underlying wrapping.
 * @author Kresko
 * @notice Rebases to adjust for stock splits and reverse stock splits
 * @notice Minting, burning and rebasing can only be performed by the `Role.OPERATOR`
 */

contract KreskoAsset is ERC20Upgradeable, AccessControlEnumerableUpgradeable, PausableUpgradeable, IKreskoAsset {
    using SafeTransfer for IERC20;
    using SafeTransfer for address payable;
    using Rebaser for uint256;
    using PercentageMath for uint256;

    Rebase private rebasing;
    bool public isRebased;
    address public kresko;
    address public anchor;
    Wrapping private wrapping;

    constructor() {
        // _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _admin,
        address _kresko,
        address _underlying,
        address _feeRecipient,
        uint48 _openFee,
        uint40 _closeFee
    ) external initializer {
        // SetupERC20
        __ERC20Upgradeable_init(_name, _symbol, _decimals);

        // Setup pausable
        __Pausable_init();

        // Setup the protocol
        kresko = _kresko;
        _grantRole(Role.OPERATOR, _kresko);

        // Setup the state
        _grantRole(Role.ADMIN, msg.sender);
        setUnderlying(_underlying);
        setFeeRecipient(_feeRecipient);
        setOpenFee(_openFee);
        setCloseFee(_closeFee);
        // Revoke admin rights after state setup
        _revokeRole(Role.ADMIN, msg.sender);

        // Setup the admin
        _grantRole(Role.DEFAULT_ADMIN, _admin);
        _grantRole(Role.ADMIN, _admin);
    }

    /// @inheritdoc IKreskoAsset
    function setAnchorToken(address _anchor) external {
        if (_anchor == address(0)) revert Errors.ZERO_ADDRESS();

        // allows easy initialization from anchor itself
        if (anchor != address(0)) _checkRole(Role.ADMIN);

        anchor = _anchor;
        _grantRole(Role.OPERATOR, _anchor);
    }

    /// @inheritdoc IKreskoAsset
    function setUnderlying(address _underlyingAddr) public onlyRole(Role.ADMIN) {
        wrapping.underlying = _underlyingAddr;
        if (_underlyingAddr != address(0)) {
            wrapping.underlyingDecimals = IERC20(wrapping.underlying).decimals();
        }
    }

    /// @inheritdoc IKreskoAsset
    function enableNativeUnderlying(bool _enabled) external onlyRole(Role.ADMIN) {
        wrapping.nativeUnderlyingEnabled = _enabled;
    }

    /// @inheritdoc IKreskoAsset
    function setFeeRecipient(address _feeRecipient) public onlyRole(Role.ADMIN) {
        if (_feeRecipient == address(0)) revert Errors.ZERO_ADDRESS();
        wrapping.feeRecipient = payable(_feeRecipient);
    }

    /// @inheritdoc IKreskoAsset
    function setOpenFee(uint48 _openFee) public onlyRole(Role.ADMIN) {
        if (_openFee > Percents.HUNDRED) revert Errors.INVALID_FEE(_assetId(), _openFee, Percents.HUNDRED);
        wrapping.openFee = _openFee;
    }

    /// @inheritdoc IKreskoAsset
    function setCloseFee(uint40 _closeFee) public onlyRole(Role.ADMIN) {
        if (_closeFee > Percents.HUNDRED) revert Errors.INVALID_FEE(_assetId(), _closeFee, Percents.HUNDRED);
        wrapping.closeFee = _closeFee;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Read                                    */
    /* -------------------------------------------------------------------------- */
    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlEnumerableUpgradeable, IERC165) returns (bool) {
        return (interfaceId != 0xffffffff &&
            (interfaceId == type(IKreskoAsset).interfaceId ||
                interfaceId == 0x01ffc9a7 ||
                interfaceId == 0x36372b07 ||
                super.supportsInterface(interfaceId)));
    }

    function wrappingInfo() external view override returns (Wrapping memory) {
        return wrapping;
    }

    /// @inheritdoc IKreskoAsset
    function rebaseInfo() external view override returns (Rebase memory) {
        return rebasing;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view override(ERC20Upgradeable, IERC20) returns (uint256) {
        return _totalSupply.rebase(rebasing);
    }

    /// @inheritdoc IERC20
    function balanceOf(address _account) public view override(ERC20Upgradeable, IERC20) returns (uint256) {
        return _balances[_account].rebase(rebasing);
    }

    /// @inheritdoc IERC20
    function allowance(address _owner, address _account) public view override(ERC20Upgradeable, IERC20) returns (uint256) {
        return _allowances[_owner][_account];
    }

    /// @inheritdoc IKreskoAsset
    function pause() public onlyRole(Role.ADMIN) {
        _pause();
    }

    /// @inheritdoc IKreskoAsset
    function unpause() public onlyRole(Role.ADMIN) {
        _unpause();
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Write                                   */
    /* -------------------------------------------------------------------------- */
    /// @inheritdoc IKreskoAsset
    function reinitializeERC20(
        string memory _name,
        string memory _symbol,
        uint8 _version
    ) external onlyRole(Role.ADMIN) reinitializer(_version) {
        __ERC20Upgradeable_init(_name, _symbol, decimals);
    }

    /// @inheritdoc IERC20
    function approve(address _spender, uint256 _amount) public override(ERC20Upgradeable, IERC20) returns (bool) {
        _allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address _to, uint256 _amount) public override(ERC20Upgradeable, IERC20) returns (bool) {
        return _transfer(msg.sender, _to, _amount);
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override(ERC20Upgradeable, IERC20) returns (bool) {
        uint256 allowed = allowance(_from, msg.sender); // Saves gas for unlimited approvals.

        if (allowed != type(uint256).max) {
            if (_amount > allowed) revert Errors.NO_ALLOWANCE(msg.sender, _from, _amount, allowed);
            _allowances[_from][msg.sender] -= _amount;
        }

        return _transfer(_from, _to, _amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Restricted                                 */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IKreskoAsset
    function rebase(uint248 _denominator, bool _positive, address[] calldata _pools) external onlyRole(Role.ADMIN) {
        if (_denominator < 1 ether) revert Errors.INVALID_DENOMINATOR(_assetId(), _denominator, 1 ether);
        if (_denominator == 1 ether) {
            isRebased = false;
            rebasing = Rebase(0, false);
        } else {
            isRebased = true;
            rebasing = Rebase(_denominator, _positive);
        }
        uint256 length = _pools.length;
        for (uint256 i; i < length; ) {
            ISyncable(_pools[i]).sync();
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IKreskoAsset
    function mint(address _to, uint256 _amount) external onlyRole(Role.OPERATOR) {
        _requireNotPaused();
        _mint(_to, _amount);
    }

    /// @inheritdoc IKreskoAsset
    function burn(address _from, uint256 _amount) external onlyRole(Role.OPERATOR) {
        _requireNotPaused();
        _burn(_from, _amount);
    }

    /// @inheritdoc IKreskoAsset
    function wrap(address _to, uint256 _amount) external {
        _requireNotPaused();

        address underlying = wrapping.underlying;
        if (underlying == address(0)) {
            revert Errors.WRAP_NOT_SUPPORTED();
        }

        IERC20(underlying).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 openFee = wrapping.openFee;
        if (openFee > 0) {
            uint256 fee = _amount.percentMul(openFee);
            _amount -= fee;
            IERC20(underlying).safeTransfer(address(wrapping.feeRecipient), fee);
        }

        _amount = _adjustDecimals(_amount, wrapping.underlyingDecimals, decimals);

        IKreskoAssetAnchor(anchor).wrap(_amount);
        _mint(_to, _amount);

        emit Wrap(address(this), underlying, _to, _amount);
    }

    /// @inheritdoc IKreskoAsset
    function unwrap(address _to, uint256 _amount, bool _receiveNative) external {
        _requireNotPaused();

        address underlying = wrapping.underlying;
        if (underlying == address(0)) {
            revert Errors.WRAP_NOT_SUPPORTED();
        }

        uint256 adjustedAmount = _adjustDecimals(_amount, wrapping.underlyingDecimals, decimals);

        IKreskoAssetAnchor(anchor).unwrap(adjustedAmount);
        _burn(msg.sender, adjustedAmount);

        bool allowNative = _receiveNative && wrapping.nativeUnderlyingEnabled;

        uint256 closeFee = wrapping.closeFee;
        if (closeFee > 0) {
            uint256 fee = _amount.percentMul(closeFee);
            _amount -= fee;

            if (!allowNative) {
                IERC20(underlying).safeTransfer(wrapping.feeRecipient, fee);
            } else {
                wrapping.feeRecipient.safeTransferETH(fee);
            }
        }
        if (!allowNative) {
            IERC20(underlying).safeTransfer(_to, _amount);
        } else {
            payable(_to).safeTransferETH(_amount);
        }

        emit Unwrap(address(this), underlying, msg.sender, _amount);
    }

    receive() external payable {
        _requireNotPaused();
        if (!wrapping.nativeUnderlyingEnabled) revert Errors.NATIVE_TOKEN_DISABLED(_assetId());

        uint256 amount = msg.value;
        if (amount == 0) revert Errors.ZERO_AMOUNT(_assetId());

        uint256 openFee = wrapping.openFee;
        if (openFee > 0) {
            uint256 fee = amount.percentMul(openFee);
            amount -= fee;
            wrapping.feeRecipient.safeTransferETH(fee);
        }

        IKreskoAssetAnchor(anchor).wrap(amount);
        _mint(msg.sender, amount);

        emit Wrap(address(this), address(0), msg.sender, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Internal                                  */
    /* -------------------------------------------------------------------------- */

    function _mint(address _to, uint256 _amount) internal override {
        uint256 normalizedAmount = _amount.unrebase(rebasing);
        unchecked {
            _totalSupply += normalizedAmount;
        }

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balances[_to] += normalizedAmount;
        }
        // Emit user input amount, not the maybe unrebased amount.
        emit Transfer(address(0), _to, _amount);
    }

    function _burn(address _from, uint256 _amount) internal override {
        uint256 normalizedAmount = _amount.unrebase(rebasing);

        _balances[_from] -= normalizedAmount;
        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            _totalSupply -= normalizedAmount;
        }

        emit Transfer(_from, address(0), _amount);
    }

    /// @dev Internal balances are always unrebased, events emitted are not.
    function _transfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        _requireNotPaused();
        uint256 bal = balanceOf(_from);
        if (_amount > bal) revert Errors.NOT_ENOUGH_BALANCE(_from, _amount, bal);
        uint256 normalizedAmount = _amount.unrebase(rebasing);

        _balances[_from] -= normalizedAmount;
        unchecked {
            _balances[_to] += normalizedAmount;
        }

        // Emit user input amount, not the maybe unrebased amount.
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function _adjustDecimals(uint256 _amount, uint8 _fromDecimal, uint8 _toDecimal) internal pure returns (uint256) {
        if (_fromDecimal == _toDecimal) return _amount;
        return
            _fromDecimal < _toDecimal
                ? _amount * (10 ** (_toDecimal - _fromDecimal))
                : _amount / (10 ** (_fromDecimal - _toDecimal));
    }

    function _assetId() internal view returns (Errors.ID memory) {
        return Errors.ID(symbol, address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

// solhint-disable-next-line
import {AccessControlEnumerableUpgradeable, AccessControlUpgradeable} from "@oz-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {IAccessControl} from "@oz/access/IAccessControl.sol";
import {PausableUpgradeable} from "@oz-upgradeable/utils/PausableUpgradeable.sol";
import {ERC20Upgradeable} from "kresko-lib/token/ERC20Upgradeable.sol";
import {SafeTransfer} from "kresko-lib/token/SafeTransfer.sol";

import {Role} from "common/Constants.sol";
import {Errors} from "common/Errors.sol";
import {IKreskoAssetIssuer} from "kresko-asset/IKreskoAssetIssuer.sol";
import {IERC165} from "vendor/IERC165.sol";
import {IKISS} from "kiss/interfaces/IKISS.sol";
import {IVaultExtender} from "vault/interfaces/IVaultExtender.sol";
import {IVault} from "vault/interfaces/IVault.sol";

/* solhint-disable not-rely-on-time */

/**
 * @title Kresko Integrated Stable System
 * This is a non-rebasing Kresko Asset, intended to be paired with KreskoVault shares (vKISS) token.
 * @author Kresko
 */
contract KISS is IKISS, ERC20Upgradeable, PausableUpgradeable, AccessControlEnumerableUpgradeable {
    using SafeTransfer for ERC20Upgradeable;

    address public kresko;
    address public vKISS;

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 dec_,
        address admin_,
        address kresko_,
        address vKISS_
    ) external initializer {
        if (kresko_.code.length == 0) revert Errors.NOT_A_CONTRACT(kresko_);

        __ERC20Upgradeable_init(name_, symbol_, dec_);

        // Setup the admin
        _grantRole(Role.DEFAULT_ADMIN, admin_);
        _grantRole(Role.ADMIN, admin_);

        // Setup the protocol
        kresko = kresko_;
        _grantRole(Role.OPERATOR, kresko_);

        // Setup vault
        vKISS = vKISS_;
    }

    modifier onlyContract() {
        if (msg.sender.code.length == 0) revert Errors.NOT_A_CONTRACT(msg.sender);
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Writes                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IKISS
    function issue(uint256 _amount, address _to) public override onlyRole(Role.OPERATOR) returns (uint256) {
        _mint(_to, _amount);
        return _amount;
    }

    /// @inheritdoc IKISS
    function destroy(uint256 _amount, address _from) external onlyRole(Role.OPERATOR) returns (uint256) {
        _burn(_from, _amount);
        return _amount;
    }

    /// @inheritdoc IVaultExtender
    function vaultDeposit(
        address _assetAddr,
        uint256 _assets,
        address _receiver
    ) external returns (uint256 sharesOut, uint256 assetFee) {
        ERC20Upgradeable(_assetAddr).safeTransferFrom(msg.sender, address(this), _assets);

        ERC20Upgradeable(_assetAddr).approve(vKISS, _assets);
        (sharesOut, assetFee) = IVault(vKISS).deposit(_assetAddr, _assets, address(this));

        address receiver = _receiver == address(0) ? msg.sender : _receiver;
        _mint(receiver, sharesOut);
    }

    /// @inheritdoc IVaultExtender
    function vaultMint(
        address _assetAddr,
        uint256 _shares,
        address _receiver
    ) external returns (uint256 assetsIn, uint256 assetFee) {
        (assetsIn, assetFee) = IVault(vKISS).previewMint(_assetAddr, _shares);
        ERC20Upgradeable(_assetAddr).safeTransferFrom(msg.sender, address(this), assetsIn);

        ERC20Upgradeable(_assetAddr).approve(vKISS, assetsIn);
        IVault(vKISS).mint(_assetAddr, _shares, address(this));

        address receiver = _receiver == address(0) ? msg.sender : _receiver;
        _mint(receiver, _shares);
    }

    /// @inheritdoc IVaultExtender
    function vaultWithdraw(
        address _assetAddr,
        uint256 _assets,
        address _receiver,
        address _owner
    ) external returns (uint256 sharesIn, uint256 assetFee) {
        (sharesIn, assetFee) = IVault(vKISS).previewWithdraw(_assetAddr, _assets);
        withdrawFrom(_owner, address(this), sharesIn);
        address receiver = _receiver == address(0) ? _owner : _receiver;
        IVault(vKISS).withdraw(_assetAddr, _assets, receiver, address(this));
    }

    /// @inheritdoc IVaultExtender
    function vaultRedeem(
        address _assetAddr,
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256 assetsOut, uint256 assetFee) {
        withdrawFrom(_owner, address(this), _shares);
        address receiver = _receiver == address(0) ? _owner : _receiver;
        (assetsOut, assetFee) = IVault(vKISS).redeem(_assetAddr, _shares, receiver, address(this));
    }

    /// @inheritdoc IVaultExtender
    function maxRedeem(address assetAddr, address owner) external view returns (uint256 max, uint256 feePaid) {
        (uint256 assetsOut, uint256 fee) = IVault(vKISS).previewRedeem(assetAddr, _balances[owner]);
        uint256 balance = ERC20Upgradeable(assetAddr).balanceOf(vKISS);

        if (assetsOut + fee > balance) {
            (max, fee) = IVault(vKISS).previewWithdraw(assetAddr, balance);
        } else {
            return (_balances[owner], fee);
        }
    }

    /// @inheritdoc IVaultExtender
    function deposit(uint256 _shares, address _receiver) external {
        ERC20Upgradeable(vKISS).transferFrom(msg.sender, address(this), _shares);
        address receiver = _receiver == address(0) ? msg.sender : _receiver;
        _mint(receiver, _shares);
    }

    /// @inheritdoc IVaultExtender
    function withdraw(uint256 _amount, address _receiver) external {
        address receiver = _receiver == address(0) ? msg.sender : _receiver;
        _withdraw(msg.sender, receiver, _amount);
    }

    /// @inheritdoc IVaultExtender
    function withdrawFrom(address _from, address _to, uint256 _amount) public {
        if (msg.sender != _from) {
            uint256 allowed = _allowances[_from][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) _allowances[_from][msg.sender] = allowed - _amount;
        }

        _withdraw(_from, _to, _amount);
    }

    /// @inheritdoc IKISS
    function pause() public onlyContract onlyRole(Role.ADMIN) {
        super._pause();
    }

    /// @inheritdoc IKISS
    function unpause() public onlyContract onlyRole(Role.ADMIN) {
        _unpause();
    }

    /// @inheritdoc IKISS
    function grantRole(
        bytes32 _role,
        address _to
    ) public override(IKISS, AccessControlUpgradeable, IAccessControl) onlyRole(Role.ADMIN) {
        if (_role == Role.OPERATOR && _to.code.length == 0) revert Errors.NOT_A_CONTRACT(_to);
        _grantRole(_role, _to);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Views                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IKISS
    function exchangeRate() external view returns (uint256) {
        return IVault(vKISS).exchangeRate();
    }

    /// @inheritdoc IKreskoAssetIssuer
    function convertToShares(uint256 assets) external pure returns (uint256) {
        return assets;
    }

    /// @inheritdoc IKreskoAssetIssuer
    function convertManyToShares(uint256[] calldata assets) external pure returns (uint256[] calldata shares) {
        return assets;
    }

    /// @inheritdoc IKreskoAssetIssuer
    function convertToAssets(uint256 shares) external pure returns (uint256) {
        return shares;
    }

    /// @inheritdoc IKreskoAssetIssuer
    function convertManyToAssets(uint256[] calldata shares) external pure returns (uint256[] calldata assets) {
        return shares;
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlEnumerableUpgradeable, IERC165) returns (bool) {
        return (interfaceId != 0xffffffff &&
            (interfaceId == type(IKISS).interfaceId ||
                interfaceId == type(IKreskoAssetIssuer).interfaceId ||
                interfaceId == 0x01ffc9a7 ||
                interfaceId == 0x36372b07 ||
                super.supportsInterface(interfaceId)));
    }

    /* -------------------------------------------------------------------------- */
    /*                                  internal                                  */
    /* -------------------------------------------------------------------------- */
    function _withdraw(address from, address to, uint256 amount) internal {
        _burn(from, amount);
        ERC20Upgradeable(vKISS).transfer(to, amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (paused()) revert Errors.PAUSED(address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {IDataV1} from "./interfaces/IDataV1.sol";
import {ViewFuncs} from "periphery/ViewData.sol";
import {View} from "periphery/ViewTypes.sol";
import {IERC20} from "kresko-lib/token/IERC20.sol";
import {IVault} from "vault/interfaces/IVault.sol";
import {IERC1155} from "common/interfaces/IERC1155.sol";
import {VaultAsset} from "vault/VTypes.sol";
import {Enums} from "common/Constants.sol";
import {Asset, RawPrice} from "common/Types.sol";
import {IAggregatorV3} from "kresko-lib/vendor/IAggregatorV3.sol";
import {toWad} from "common/funcs/Math.sol";
import {WadRay} from "libs/WadRay.sol";
import {IViewDataFacet} from "periphery/interfaces/IViewDataFacet.sol";
import {PythView} from "vendor/pyth/PythScript.sol";
import {ISwapRouter} from "periphery/IKrMulticall.sol";
import {IAssetStateFacet} from "common/interfaces/IAssetStateFacet.sol";
import {PercentageMath} from "libs/PercentageMath.sol";
import {IPyth} from "vendor/pyth/IPyth.sol";
import {IKresko} from "periphery/IKresko.sol";
import {Arrays} from "libs/Arrays.sol";

// solhint-disable avoid-low-level-calls, var-name-mixedcase

contract DataV1 is IDataV1 {
    using WadRay for uint256;
    using PercentageMath for uint256;
    using Arrays for address[];

    address public immutable VAULT;
    IViewDataFacet public immutable DIAMOND;
    address public immutable KISS;
    IPyth public immutable PYTH_EP;
    ISwapRouter public QUOTER;

    uint256 public constant QUEST_FOR_KRESK_TOKEN_COUNT = 8;
    uint256 public constant KRESKIAN_LAST_TOKEN_COUNT = 1;
    address public immutable KRESKIAN_COLLECTION;
    address public immutable QUEST_FOR_KRESK_COLLECTION;

    constructor(
        address _diamond,
        address _vault,
        address _KISS,
        address _uniQuoter,
        address _kreskian,
        address _questForKresk
    ) {
        VAULT = _vault;
        DIAMOND = IViewDataFacet(_diamond);
        KISS = _KISS;
        KRESKIAN_COLLECTION = _kreskian;
        QUEST_FOR_KRESK_COLLECTION = _questForKresk;
        QUOTER = ISwapRouter(_uniQuoter);
    }

    function getTradeFees(
        address _assetIn,
        address _assetOut
    ) public view returns (uint256 feePercentage, uint256 depositorFee, uint256 protocolFee) {
        Asset memory assetIn = IAssetStateFacet(address(DIAMOND)).getAsset(_assetIn);
        Asset memory assetOut = IAssetStateFacet(address(DIAMOND)).getAsset(_assetOut);
        unchecked {
            feePercentage = assetIn.swapInFeeSCDP + assetOut.swapOutFeeSCDP;
            protocolFee = assetIn.protocolFeeShareSCDP + assetOut.protocolFeeShareSCDP;
            depositorFee = feePercentage - protocolFee;
        }
    }

    function previewWithdraw(PreviewWithdrawArgs calldata args) external payable returns (uint256 withdrawAmount, uint256 fee) {
        bool isVaultToAMM = args.vaultAsset != address(0) && args.path.length > 0;
        uint256 vaultAssetAmount = !isVaultToAMM ? 0 : args.outputAmount;
        if (isVaultToAMM) {
            (vaultAssetAmount, , , ) = QUOTER.quoteExactOutput(args.path, args.outputAmount);
        }
        (withdrawAmount, fee) = IVault(VAULT).previewWithdraw(args.vaultAsset, vaultAssetAmount);
    }

    function getGlobals(PythView calldata _prices) external view returns (DGlobal memory result, DWrap[] memory wraps) {
        result.chainId = block.chainid;
        result.protocol = DIAMOND.viewProtocolData(_prices);
        result.vault = getVault();
        result.collections = getCollectionData(address(1));
        wraps = getWraps(result);
    }

    function getWraps(DGlobal memory _globals) internal view returns (DWrap[] memory result) {
        uint256 count;
        for (uint256 i; i < _globals.protocol.assets.length; i++) {
            View.AssetView memory asset = _globals.protocol.assets[i];
            if (asset.config.kFactor > 0 && asset.synthwrap.underlying != address(0)) ++count;
        }
        result = new DWrap[](count);
        count = 0;
        for (uint256 i; i < _globals.protocol.assets.length; i++) {
            View.AssetView memory asset = _globals.protocol.assets[i];
            if (asset.config.kFactor > 0 && asset.synthwrap.underlying != address(0)) {
                uint256 nativeAmount = asset.synthwrap.nativeUnderlyingEnabled ? asset.synthwrap.underlying.balance : 0;
                uint256 amount = IERC20(asset.synthwrap.underlying).balanceOf(asset.addr);
                result[count] = DWrap({
                    addr: asset.addr,
                    underlying: asset.synthwrap.underlying,
                    symbol: asset.symbol,
                    price: asset.price,
                    decimals: asset.config.decimals,
                    val: toWad(amount, asset.synthwrap.underlyingDecimals).wadMul(asset.price),
                    amount: amount,
                    nativeAmount: nativeAmount,
                    nativeVal: nativeAmount.wadMul(asset.price)
                });
                ++count;
            }
        }
    }

    function getExternalTokens(
        ExternalTokenArgs[] memory tokens,
        address _account
    ) external view returns (DVTokenBalance[] memory result) {
        result = new DVTokenBalance[](tokens.length);

        for (uint256 i; i < tokens.length; i++) {
            ExternalTokenArgs memory token = tokens[i];
            IERC20 tkn = IERC20(token.token);

            (int256 answer, uint256 updatedAt, uint8 oracleDecimals) = _possibleOracleValue(token.feed);

            uint256 balance = _account != address(0) ? tkn.balanceOf(_account) : 0;

            uint8 decimals = tkn.decimals();
            uint256 value = toWad(balance, decimals).wadMul(answer > 0 ? uint256(answer) : 0);

            result[i] = DVTokenBalance({
                chainId: block.chainid,
                addr: token.token,
                name: tkn.name(),
                symbol: ViewFuncs._symbol(token.token),
                decimals: decimals,
                amount: balance,
                val: value,
                tSupply: tkn.totalSupply(),
                price: answer >= 0 ? uint256(answer) : 0,
                oracleDecimals: oracleDecimals,
                priceRaw: RawPrice(
                    answer,
                    block.timestamp,
                    86401,
                    block.timestamp - updatedAt > 86401,
                    answer == 0,
                    Enums.OracleType.Chainlink,
                    token.feed
                )
            });
        }
    }

    function _possibleOracleValue(address _feed) internal view returns (int256 answer, uint256 updatedAt, uint8 decimals) {
        if (_feed == address(0)) {
            return (0, 0, 8);
        }
        (, answer, , updatedAt, ) = IAggregatorV3(_feed).latestRoundData();
        decimals = IAggregatorV3(_feed).decimals();
    }

    function getAccount(PythView calldata _prices, address _account) external view returns (DAccount memory result) {
        result.protocol = DIAMOND.viewAccountData(_prices, _account);
        result.vault.addr = VAULT;
        result.vault.name = IERC20(VAULT).name();
        result.vault.amount = IERC20(VAULT).balanceOf(_account);
        result.vault.price = IVault(VAULT).exchangeRate();
        result.vault.oracleDecimals = 18;
        result.vault.symbol = IERC20(VAULT).symbol();
        result.vault.decimals = IERC20(VAULT).decimals();

        result.collections = getCollectionData(_account);
        (result.phase, result.eligible) = DIAMOND.viewAccountGatingPhase(_account);
        result.chainId = block.chainid;
    }

    function getBalances(
        PythView calldata _prices,
        address _account,
        address[] memory _tokens
    ) external view returns (View.Balance[] memory result) {
        result = DIAMOND.viewTokenBalances(_prices, _account, _tokens);
    }

    function getCollectionData(address _account) public view returns (DCollection[] memory result) {
        result = new DCollection[](2);

        if (address(QUEST_FOR_KRESK_COLLECTION) == address(0) && address(KRESKIAN_COLLECTION) == address(0)) return result;

        result[0].uri = IERC1155(KRESKIAN_COLLECTION).contractURI();
        result[0].addr = KRESKIAN_COLLECTION;
        result[0].name = IERC20(KRESKIAN_COLLECTION).name();
        result[0].symbol = IERC20(KRESKIAN_COLLECTION).symbol();
        result[0].items = getCollectionItems(_account, KRESKIAN_COLLECTION);

        result[1].uri = IERC1155(QUEST_FOR_KRESK_COLLECTION).contractURI();
        result[1].addr = QUEST_FOR_KRESK_COLLECTION;
        result[1].name = IERC20(QUEST_FOR_KRESK_COLLECTION).name();
        result[1].symbol = IERC20(QUEST_FOR_KRESK_COLLECTION).symbol();
        result[1].items = getCollectionItems(_account, QUEST_FOR_KRESK_COLLECTION);
    }

    function getCollectionItems(
        address _account,
        address _collectionAddr
    ) public view returns (DCollectionItem[] memory result) {
        uint256 totalItems = _collectionAddr == KRESKIAN_COLLECTION ? KRESKIAN_LAST_TOKEN_COUNT : QUEST_FOR_KRESK_TOKEN_COUNT;
        result = new DCollectionItem[](totalItems);

        for (uint256 i; i < totalItems; i++) {
            result[i] = DCollectionItem({
                id: i,
                uri: IERC1155(_collectionAddr).uri(i),
                balance: IERC1155(_collectionAddr).balanceOf(_account, i)
            });
        }
    }

    function getVault() public view returns (DVault memory result) {
        result.assets = getVAssets();
        result.token.price = IVault(VAULT).exchangeRate();
        result.token.symbol = IERC20(VAULT).symbol();
        result.token.name = IERC20(VAULT).name();
        result.token.tSupply = IERC20(VAULT).totalSupply();
        result.token.decimals = IERC20(VAULT).decimals();
        result.token.oracleDecimals = 18;
    }

    function getVAssets() public view returns (DVAsset[] memory result) {
        VaultAsset[] memory vAssets = IVault(VAULT).allAssets();
        result = new DVAsset[](vAssets.length);

        for (uint256 i; i < vAssets.length; i++) {
            VaultAsset memory asset = vAssets[i];
            (, int256 answer, , uint256 updatedAt, ) = asset.feed.latestRoundData();

            result[i] = DVAsset({
                addr: address(asset.token),
                name: asset.token.name(),
                symbol: ViewFuncs._symbol(address(asset.token)),
                tSupply: asset.token.totalSupply(),
                vSupply: asset.token.balanceOf(VAULT),
                price: answer > 0 ? uint256(answer) : 0,
                isMarketOpen: answer > 0 ? true : false,
                oracleDecimals: asset.feed.decimals(),
                priceRaw: RawPrice(
                    answer,
                    block.timestamp,
                    asset.staleTime,
                    block.timestamp - updatedAt > asset.staleTime,
                    answer == 0,
                    Enums.OracleType.Chainlink,
                    address(asset.feed)
                ),
                config: asset
            });
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IMinterDepositWithdrawFacet} from "minter/interfaces/IMinterDepositWithdrawFacet.sol";
import {IMinterBurnFacet} from "minter/interfaces/IMinterBurnFacet.sol";
import {IMinterMintFacet} from "minter/interfaces/IMinterMintFacet.sol";
import {ISCDPFacet} from "scdp/interfaces/ISCDPFacet.sol";
import {ISCDPSwapFacet} from "scdp/interfaces/ISCDPSwapFacet.sol";
import {IVaultExtender} from "vault/interfaces/IVaultExtender.sol";
import {IERC20} from "kresko-lib/token/IERC20.sol";
import {IKreskoAsset} from "kresko-asset/IKreskoAsset.sol";
import {Ownable} from "@oz/access/Ownable.sol";
import {IWETH9} from "kresko-lib/token/IWETH9.sol";
import {ISwapRouter, IKrMulticall} from "periphery/IKrMulticall.sol";
import {IPyth} from "vendor/pyth/IPyth.sol";
import {BurnArgs, MintArgs, SCDPWithdrawArgs, SwapArgs, WithdrawArgs} from "common/Args.sol";
import {fromWad} from "common/funcs/Math.sol";

// solhint-disable avoid-low-level-calls, code-complexity

/**
 * @title KrMulticall
 * @notice Executes some number of supported operations one after another.
 * @notice Any operation can specify the mode for tokens in and out:
 * Specifically this means that if any operation leaves tokens in the contract, the next one can use them.
 * @notice All tokens left in the contract after operations will be returned to the sender at the end.
 */
contract KrMulticall is IKrMulticall, Ownable {
    address public kresko;
    address public kiss;
    IPyth public pythEp;
    ISwapRouter public v3Router;
    IWETH9 public wNative;
    event MulticallExecuted(address _sender, Operation[] ops, Result[] results);

    constructor(
        address _kresko,
        address _kiss,
        address _v3Router,
        address _wNative,
        address _pythEp,
        address _owner
    ) Ownable(_owner) {
        kresko = _kresko;
        kiss = _kiss;
        v3Router = ISwapRouter(_v3Router);
        wNative = IWETH9(_wNative);
        pythEp = IPyth(_pythEp);
    }

    function rescue(address _token, uint256 _amount, address _receiver) external onlyOwner {
        if (_token == address(0)) payable(_receiver).transfer(_amount);
        else IERC20(_token).transfer(_receiver, _amount);
    }

    function execute(
        Operation[] calldata ops,
        bytes[] calldata _updateData
    ) external payable returns (Result[] memory results) {
        uint256 value = msg.value;
        if (msg.value > 0 && _updateData.length > 0) {
            uint256 updateFee = pythEp.getUpdateFee(_updateData);
            pythEp.updatePriceFeeds{value: updateFee}(_updateData);
            value -= updateFee;
        }

        unchecked {
            results = new Result[](ops.length);
            for (uint256 i; i < ops.length; i++) {
                Operation memory op = ops[i];

                if (op.data.tokensInMode != TokensInMode.None) {
                    op.data.amountIn = uint96(_handleTokensIn(op, value));
                    results[i].tokenIn = op.data.tokenIn;
                    results[i].amountIn = op.data.amountIn;
                } else {
                    if (op.data.tokenIn != address(0)) {
                        revert TOKENS_IN_MODE_WAS_NONE_BUT_ADDRESS_NOT_ZERO(op.action, op.data.tokenIn);
                    }
                }

                if (op.data.tokensOutMode != TokensOutMode.None) {
                    results[i].tokenOut = op.data.tokenOut;
                    if (op.data.tokensOutMode == TokensOutMode.ReturnToSender) {
                        results[i].amountOut = IERC20(op.data.tokenOut).balanceOf(msg.sender);
                    } else if (op.data.tokensOutMode == TokensOutMode.ReturnToSenderNative) {
                        results[i].amountOut = msg.sender.balance;
                    } else {
                        results[i].amountOut = IERC20(op.data.tokenOut).balanceOf(address(this));
                    }
                } else {
                    if (op.data.tokenOut != address(0)) {
                        revert TOKENS_OUT_MODE_WAS_NONE_BUT_ADDRESS_NOT_ZERO(op.action, op.data.tokenOut);
                    }
                }

                _handleOp(op, _updateData, value != msg.value);

                if (
                    op.data.tokensInMode != TokensInMode.None &&
                    op.data.tokensInMode != TokensInMode.UseContractBalanceExactAmountIn
                ) {
                    uint256 balanceAfter = IERC20(op.data.tokenIn).balanceOf(address(this));
                    if (balanceAfter != 0 && balanceAfter <= results[i].amountIn) {
                        results[i].amountIn = results[i].amountIn - balanceAfter;
                    }
                }

                if (op.data.tokensOutMode != TokensOutMode.None) {
                    uint256 balanceAfter = IERC20(op.data.tokenOut).balanceOf(address(this));
                    if (op.data.tokensOutMode == TokensOutMode.ReturnToSender) {
                        _handleTokensOut(op, balanceAfter);
                        results[i].amountOut = IERC20(op.data.tokenOut).balanceOf(msg.sender) - results[i].amountOut;
                    } else if (op.data.tokensOutMode == TokensOutMode.ReturnToSenderNative) {
                        _handleTokensOut(op, balanceAfter);
                        results[i].amountOut = msg.sender.balance - results[i].amountOut;
                    } else {
                        results[i].amountOut = balanceAfter - results[i].amountOut;
                    }
                }

                if (i > 0 && results[i - 1].amountOut == 0) {
                    results[i - 1].amountOut = results[i].amountIn;
                }
            }

            _handleFinished(ops);

            emit MulticallExecuted(msg.sender, ops, results);
        }
    }

    function _handleTokensIn(Operation memory _op, uint256 _value) internal returns (uint256 amountIn) {
        if (_op.data.tokensInMode == TokensInMode.Native) {
            if (_value == 0) {
                revert ZERO_NATIVE_IN(_op.action);
            }

            if (address(wNative) != _op.data.tokenIn) {
                revert INVALID_NATIVE_TOKEN_IN(_op.action, _op.data.tokenIn, wNative.symbol());
            }

            wNative.deposit{value: _value}();
            return _value;
        }

        IERC20 token = IERC20(_op.data.tokenIn);

        // Pull tokens from sender
        if (_op.data.tokensInMode == TokensInMode.PullFromSender) {
            if (_op.data.amountIn == 0) revert ZERO_AMOUNT_IN(_op.action, _op.data.tokenIn, token.symbol());
            if (token.allowance(msg.sender, address(this)) < _op.data.amountIn)
                revert NO_ALLOWANCE(_op.action, _op.data.tokenIn, token.symbol());
            token.transferFrom(msg.sender, address(this), _op.data.amountIn);
            return _op.data.amountIn;
        }

        // Use contract balance for tokens in
        if (_op.data.tokensInMode == TokensInMode.UseContractBalance) {
            return token.balanceOf(address(this));
        }
        if (_op.data.tokensInMode == TokensInMode.UseContractBalanceNative) {
            return address(this).balance;
        }

        if (_op.data.tokensInMode == TokensInMode.UseContractBalanceUnwrapNative) {
            if (_op.data.tokenIn != address(wNative)) {
                revert INVALID_NATIVE_TOKEN_IN(_op.action, _op.data.tokenIn, wNative.symbol());
            }
            wNative.withdraw(wNative.balanceOf(address(this)));
            return address(this).balance;
        }

        if (_op.data.tokensInMode == TokensInMode.UseContractBalanceWrapNative) {
            if (_op.data.tokenIn != address(wNative)) {
                revert INVALID_NATIVE_TOKEN_IN(_op.action, _op.data.tokenIn, wNative.symbol());
            }
            wNative.deposit{value: address(this).balance}();
            return wNative.balanceOf(address(this));
        }

        // Use amountIn for tokens in, eg. MinterRepay allows this.
        if (_op.data.tokensInMode == TokensInMode.UseContractBalanceExactAmountIn) return _op.data.amountIn;

        revert INVALID_ACTION(_op.action);
    }

    function _handleTokensOut(Operation memory _op, uint256 balance) internal {
        if (_op.data.tokensOutMode == TokensOutMode.ReturnToSenderNative) {
            wNative.withdraw(balance);
            payable(msg.sender).transfer(address(this).balance);
            return;
        }

        // Transfer tokens to sender
        IERC20 tokenOut = IERC20(_op.data.tokenOut);
        if (balance != 0) {
            tokenOut.transfer(msg.sender, balance);
        }
    }

    /// @notice Send all op tokens and native to sender
    function _handleFinished(Operation[] memory _ops) internal {
        for (uint256 i; i < _ops.length; i++) {
            Operation memory _op = _ops[i];

            // Transfer any tokenIns to sender
            if (_op.data.tokenIn != address(0)) {
                IERC20 tokenIn = IERC20(_op.data.tokenIn);
                uint256 bal = tokenIn.balanceOf(address(this));
                if (bal != 0) {
                    tokenIn.transfer(msg.sender, bal);
                }
            }

            // Transfer any tokenOuts to sender
            if (_op.data.tokenOut != address(0)) {
                IERC20 tokenOut = IERC20(_op.data.tokenOut);
                uint256 bal = tokenOut.balanceOf(address(this));
                if (bal != 0) {
                    tokenOut.transfer(msg.sender, bal);
                }
            }
        }

        // Transfer native to sender
        if (address(this).balance != 0) payable(msg.sender).transfer(address(this).balance);
    }

    function _approve(address _token, uint256 _amount, address spender) internal {
        if (_amount > 0) {
            IERC20(_token).approve(spender, _amount);
        }
    }

    function _handleOp(Operation memory _op, bytes[] calldata _updateData, bool _didUpdate) internal {
        (bool success, bytes memory returndata) = _call(_op, _updateData, _didUpdate);
        if (!success) _handleRevert(returndata);
    }

    function _call(
        Operation memory _op,
        bytes[] calldata _updateData,
        bool _didUpdate
    ) internal returns (bool success, bytes memory returndata) {
        bool isReturn = _op.data.tokensOutMode == TokensOutMode.ReturnToSender;
        address receiver = isReturn ? msg.sender : address(this);
        if (_op.action == Action.MinterDeposit) {
            _approve(_op.data.tokenIn, _op.data.amountIn, address(kresko));
            return
                kresko.call(
                    abi.encodeCall(
                        IMinterDepositWithdrawFacet.depositCollateral,
                        (msg.sender, _op.data.tokenIn, _op.data.amountIn)
                    )
                );
        } else if (_op.action == Action.MinterWithdraw) {
            return
                kresko.call(
                    abi.encodeCall(
                        IMinterDepositWithdrawFacet.withdrawCollateral,
                        (
                            WithdrawArgs(msg.sender, _op.data.tokenOut, _op.data.amountOut, _op.data.index, receiver),
                            !_didUpdate ? _updateData : new bytes[](0)
                        )
                    )
                );
        } else if (_op.action == Action.MinterRepay) {
            return
                kresko.call(
                    abi.encodeCall(
                        IMinterBurnFacet.burnKreskoAsset,
                        (
                            BurnArgs(msg.sender, _op.data.tokenIn, _op.data.amountIn, _op.data.index, receiver),
                            !_didUpdate ? _updateData : new bytes[](0)
                        )
                    )
                );
        } else if (_op.action == Action.MinterBorrow) {
            return
                kresko.call(
                    abi.encodeCall(
                        IMinterMintFacet.mintKreskoAsset,
                        (
                            MintArgs(msg.sender, _op.data.tokenOut, _op.data.amountOut, receiver),
                            !_didUpdate ? _updateData : new bytes[](0)
                        )
                    )
                );
        } else if (_op.action == Action.SCDPDeposit) {
            _approve(_op.data.tokenIn, _op.data.amountIn, address(kresko));
            return kresko.call(abi.encodeCall(ISCDPFacet.depositSCDP, (msg.sender, _op.data.tokenIn, _op.data.amountIn)));
        } else if (_op.action == Action.SCDPTrade) {
            _approve(_op.data.tokenIn, _op.data.amountIn, address(kresko));
            return
                kresko.call(
                    abi.encodeCall(
                        ISCDPSwapFacet.swapSCDP,
                        (
                            SwapArgs(
                                receiver,
                                _op.data.tokenIn,
                                _op.data.tokenOut,
                                _op.data.amountIn,
                                _op.data.amountOutMin,
                                !_didUpdate ? _updateData : new bytes[](0)
                            )
                        )
                    )
                );
        } else if (_op.action == Action.SCDPWithdraw) {
            return
                kresko.call(
                    abi.encodeCall(
                        ISCDPFacet.withdrawSCDP,
                        (
                            SCDPWithdrawArgs(msg.sender, _op.data.tokenOut, _op.data.amountOut, receiver),
                            !_didUpdate ? _updateData : new bytes[](0)
                        )
                    )
                );
        } else if (_op.action == Action.SCDPClaim) {
            return kresko.call(abi.encodeCall(ISCDPFacet.claimFeesSCDP, (msg.sender, _op.data.tokenOut, receiver)));
        } else if (_op.action == Action.SynthWrap) {
            _approve(_op.data.tokenIn, _op.data.amountIn, _op.data.tokenOut);
            return _op.data.tokenOut.call(abi.encodeCall(IKreskoAsset.wrap, (receiver, _op.data.amountIn)));
        } else if (_op.action == Action.SynthwrapNative) {
            if (!IKreskoAsset(_op.data.tokenOut).wrappingInfo().nativeUnderlyingEnabled) {
                revert NATIVE_SYNTH_WRAP_NOT_ALLOWED(_op.action, _op.data.tokenOut, IKreskoAsset(_op.data.tokenOut).symbol());
            }

            uint256 wBal = wNative.balanceOf(address(this));
            if (wBal != 0) wNative.withdraw(wBal);

            return address(_op.data.tokenOut).call{value: address(this).balance}("");
        } else if (_op.action == Action.SynthUnwrap) {
            IKreskoAsset krAsset = IKreskoAsset(_op.data.tokenIn);
            IKreskoAsset.Wrapping memory info = krAsset.wrappingInfo();
            return
                _op.data.tokenIn.call(
                    abi.encodeCall(
                        IKreskoAsset.unwrap,
                        (receiver, fromWad(krAsset.balanceOf(address(this)), info.underlyingDecimals), false)
                    )
                );
        } else if (_op.action == Action.SynthUnwrapNative) {
            return _op.data.tokenIn.call(abi.encodeCall(IKreskoAsset.unwrap, (receiver, _op.data.amountIn, true)));
        } else if (_op.action == Action.VaultDeposit) {
            _approve(_op.data.tokenIn, _op.data.amountIn, kiss);
            return kiss.call(abi.encodeCall(IVaultExtender.vaultDeposit, (_op.data.tokenIn, _op.data.amountIn, receiver)));
        } else if (_op.action == Action.VaultRedeem) {
            _approve(kiss, _op.data.amountIn, kiss);
            return
                kiss.call(
                    abi.encodeCall(IVaultExtender.vaultRedeem, (_op.data.tokenOut, _op.data.amountIn, receiver, address(this)))
                );
        } else if (_op.action == Action.AMMExactInput) {
            IERC20(_op.data.tokenIn).transfer(address(v3Router), _op.data.amountIn);
            if (
                v3Router.exactInput(
                    ISwapRouter.ExactInputParams({
                        path: _op.data.path,
                        recipient: receiver,
                        amountIn: 0,
                        amountOutMinimum: _op.data.amountOutMin
                    })
                ) == 0
            ) {
                revert ZERO_OR_INVALID_AMOUNT_IN(
                    _op.action,
                    _op.data.tokenOut,
                    IERC20(_op.data.tokenOut).symbol(),
                    IERC20(_op.data.tokenOut).balanceOf(address(this)),
                    _op.data.amountOutMin
                );
            }
            return (true, "");
        } else {
            revert INVALID_ACTION(_op.action);
        }
    }

    function _handleRevert(bytes memory data) internal pure {
        assembly {
            revert(add(32, data), mload(data))
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ISCDPConfigFacet} from "scdp/interfaces/ISCDPConfigFacet.sol";
import {ISCDPStateFacet} from "scdp/interfaces/ISCDPStateFacet.sol";
import {ISCDPFacet} from "scdp/interfaces/ISCDPFacet.sol";
import {ISDIFacet} from "scdp/interfaces/ISDIFacet.sol";
import {ISCDPSwapFacet} from "scdp/interfaces/ISCDPSwapFacet.sol";
import {IMinterBurnFacet} from "minter/interfaces/IMinterBurnFacet.sol";
import {IMinterConfigFacet} from "minter/interfaces/IMinterConfigFacet.sol";
import {IMinterMintFacet} from "minter/interfaces/IMinterMintFacet.sol";
import {IMinterDepositWithdrawFacet} from "minter/interfaces/IMinterDepositWithdrawFacet.sol";
import {IMinterStateFacet} from "minter/interfaces/IMinterStateFacet.sol";
import {IMinterLiquidationFacet} from "minter/interfaces/IMinterLiquidationFacet.sol";
import {IMinterAccountStateFacet} from "minter/interfaces/IMinterAccountStateFacet.sol";
import {IAuthorizationFacet} from "common/interfaces/IAuthorizationFacet.sol";
import {ISafetyCouncilFacet} from "common/interfaces/ISafetyCouncilFacet.sol";
import {ICommonConfigFacet} from "common/interfaces/ICommonConfigFacet.sol";
import {ICommonStateFacet} from "common/interfaces/ICommonStateFacet.sol";
import {IAssetStateFacet} from "common/interfaces/IAssetStateFacet.sol";
import {IAssetConfigFacet} from "common/interfaces/IAssetConfigFacet.sol";
import {IDiamondCutFacet} from "diamond/interfaces/IDiamondCutFacet.sol";
import {IDiamondLoupeFacet} from "diamond/interfaces/IDiamondLoupeFacet.sol";
import {IDiamondStateFacet} from "diamond/interfaces/IDiamondStateFacet.sol";
import {IViewDataFacet} from "periphery/interfaces/IViewDataFacet.sol";
import {IBatchFacet} from "common/interfaces/IBatchFacet.sol";
import {IErrorsEvents} from "periphery/IErrorsEvents.sol";

// solhint-disable-next-line no-empty-blocks
interface IKresko is
    IDiamondCutFacet,
    IDiamondLoupeFacet,
    IDiamondStateFacet,
    IAuthorizationFacet,
    ICommonConfigFacet,
    ICommonStateFacet,
    IAssetConfigFacet,
    IErrorsEvents,
    IAssetStateFacet,
    ISCDPSwapFacet,
    ISCDPFacet,
    ISCDPConfigFacet,
    ISCDPStateFacet,
    ISDIFacet,
    IMinterBurnFacet,
    ISafetyCouncilFacet,
    IMinterConfigFacet,
    IMinterMintFacet,
    IMinterStateFacet,
    IMinterDepositWithdrawFacet,
    IMinterAccountStateFacet,
    IMinterLiquidationFacet,
    IViewDataFacet,
    IBatchFacet
{

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {IERC1155} from "common/interfaces/IERC1155.sol";
import {Ownable} from "@oz/access/Ownable.sol";
import {Errors} from "common/Errors.sol";
import {IGatingManager} from "periphery/IGatingManager.sol";

// solhint-disable code-complexity

contract GatingManager is IGatingManager, Ownable {
    IERC1155 public kreskian;
    IERC1155 public questForKresk;
    uint8 public phase;
    uint256[] internal _qfkNFTs;

    mapping(address => bool) internal whitelisted;

    constructor(address _admin, address _kreskian, address _questForKresk, uint8 _phase) Ownable(_admin) {
        kreskian = IERC1155(_kreskian);
        questForKresk = IERC1155(_questForKresk);
        phase = _phase;

        _qfkNFTs.push(0);
        _qfkNFTs.push(1);
        _qfkNFTs.push(2);
        _qfkNFTs.push(3);
        _qfkNFTs.push(4);
        _qfkNFTs.push(5);
        _qfkNFTs.push(6);
        _qfkNFTs.push(7);
    }

    function transferOwnership(address newOwner) public override(IGatingManager, Ownable) onlyOwner {
        Ownable.transferOwnership(newOwner);
    }

    function qfkNFTs() external view returns (uint256[] memory) {
        return _qfkNFTs;
    }

    function isWhiteListed(address _account) external view returns (bool) {
        return whitelisted[_account];
    }

    function whitelist(address _account, bool _whitelisted) external onlyOwner {
        whitelisted[_account] = _whitelisted;
    }

    function setPhase(uint8 newPhase) external onlyOwner {
        phase = newPhase;
    }

    function isEligible(address _account) external view returns (bool) {
        uint256 currentPhase = phase;
        if (currentPhase == 0) return true;

        bool hasKreskian = kreskian.balanceOf(_account, 0) != 0;

        if (currentPhase == 3) {
            return hasKreskian || whitelisted[_account];
        }

        uint256[] memory qfkBals = questForKresk.balanceOfBatch(_toArray(_account), _qfkNFTs);
        bool validPhaseTwo = qfkBals[0] != 0;

        if (currentPhase == 2) {
            return validPhaseTwo || whitelisted[_account];
        }

        if (currentPhase == 1 && validPhaseTwo) {
            for (uint256 i = 1; i < qfkBals.length; i++) {
                if (qfkBals[i] != 0) return true;
            }
        }

        return whitelisted[_account];
    }

    function check(address _account) external view {
        uint256 currentPhase = phase;
        if (currentPhase == 0) return;

        bool hasKreskian = kreskian.balanceOf(_account, 0) != 0;

        if (currentPhase == 3) {
            if (!hasKreskian && !whitelisted[_account]) revert Errors.MISSING_PHASE_3_NFT();
            return;
        }

        uint256[] memory qfkBals = questForKresk.balanceOfBatch(_toArray(_account), _qfkNFTs);

        bool validPhaseTwo = qfkBals[0] != 0;

        if (currentPhase == 2) {
            if (!validPhaseTwo && !whitelisted[_account]) revert Errors.MISSING_PHASE_2_NFT();
            return;
        }

        if (currentPhase == 1 && validPhaseTwo) {
            for (uint256 i = 1; i < qfkBals.length; i++) {
                if (qfkBals[i] != 0) return;
            }
        }

        if (!whitelisted[_account]) revert Errors.MISSING_PHASE_1_NFT();
    }

    function _toArray(address _acc) internal pure returns (address[] memory array) {
        array = new address[](8);
        array[0] = _acc;
        array[1] = _acc;
        array[2] = _acc;
        array[3] = _acc;
        array[4] = _acc;
        array[5] = _acc;
        array[6] = _acc;
        array[7] = _acc;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import {ITransparentUpgradeableProxy} from "@oz/proxy/transparent/TransparentUpgradeableProxy.sol";

enum CreationKind {
    NONE,
    CREATE,
    CREATE2,
    CREATE3
}

/**
 * @notice Deployment information
 * @param implementation Current implementation address
 * @param updatedAt Timestamp of latest upgrade
 * @param kind Creation mechanism used for the deployment
 * @param proxy Address of the proxy or zero if not a proxy deployment
 * @param index Array index of the deployment in the internal tracking list
 * @param createdAt Creation timestamp of the deployment
 * @param version Current version of the deployment (can be over 1 for proxies)
 */
struct Deployment {
    address implementation;
    uint88 updatedAt;
    CreationKind kind;
    ITransparentUpgradeableProxy proxy;
    uint48 index;
    uint48 createdAt;
    uint256 version;
    bytes32 salt;
}

interface IDeploymentFactory {
    error BatchRevertSilentOrCustomError(bytes innerError);
    error CreateProxyPreview(address proxy);
    error CreateProxyAndLogicPreview(address proxy, address implementation);
    error InvalidKind(Deployment);
    error ArrayLengthMismatch(uint256 proxies, uint256 implementations, uint256 datas);
    error InvalidSalt(Deployment);
    error DeployerAlreadySet(address, bool);

    event DeployerSet(address, bool);
    event Deployed(Deployment);
    event Upgrade(Deployment);

    function setDeployer(address who, bool value) external;

    function isDeployer(address who) external view returns (bool);

    /**
     * @notice Get available deployment information for address.
     * @param addr Address of the contract.
     * @return Deployment Deployment information.
     */
    function getDeployment(address addr) external view returns (Deployment memory);

    /**
     * @notice Get the topmost `count` of deployments.
     * @return Deployment[] List of information about the deployments.
     */
    function getLatestDeployments(uint256 count) external view returns (Deployment[] memory);

    /**
     * @notice Get available information of deployment in index.
     * @param index Index of the deployment.
     * @return Deployment Deployment information.
     */
    function getDeployByIndex(uint256 index) external view returns (Deployment memory);

    /**
     * @notice Get all deployments.
     * @return Deployment[] Array of deployments.
     */
    function getDeployments() external view returns (Deployment[] memory);

    /**
     * @notice Get number of deployments.
     * @return uint256 Number of deployments.
     */
    function getDeployCount() external view returns (uint256);

    /**
     * @notice Inspect if an address is created by this contract.
     * @param addr Address to inspect
     * @return bool True if deployment was created by this contract.
     */
    function isDeployment(address addr) external view returns (bool);

    /**
     * @notice Inspect if an address is a proxy created by this contract.
     * @param addr Address to inspect
     * @return bool True if proxy was created by this contract.
     */
    function isProxy(address addr) external view returns (bool);

    /// @notice Inspect if an address is a non proxy deployment created by this contract.
    function isNonProxy(address addr) external view returns (bool);

    function isDeterministic(address addr) external view returns (bool);

    /**
     * @notice Inspect the current implementation address of a proxy.
     * @param proxy Address of the proxy.
     * @return address Implementation address of the proxy
     */
    function getImplementation(address proxy) external view returns (address);

    /**
     * @notice Get the init code hash for a proxy.
     * @param implementation Address of the implementation.
     * @param data Initializer calldata.
     * @return bytes32 Hash of the init code.
     */
    function getProxyInitCodeHash(address implementation, bytes memory data) external view returns (bytes32);

    /**
     * @notice Preview address from CREATE2 with given salt and creation code.
     */
    function getCreate2Address(bytes32 _salt, bytes memory _creationCode) external view returns (address);

    /**
     * @notice Preview address from CREATE3 with given salt.
     */
    function getCreate3Address(bytes32 salt) external view returns (address);

    /**
     * @notice Preview proxy address from {createProxy} through {CreateProxyPreview} custom error.
     * @param implementation Bytecode of the implementation.
     * @param _calldata Initializer calldata.
     * @return proxyPreview Address of the proxy that would be created.
     */
    function previewCreateProxy(address implementation, bytes memory _calldata) external returns (address proxyPreview);

    /**
     * @notice Preview resulting proxy address from {create2AndCall} with given salt.
     * @param implementation Address of the implementation.
     * @param _calldata Initializer calldata.
     * @param salt Salt for the deterministic deployment.
     * @return proxyPreview Address of the proxy that would be created.
     */
    function previewCreate2Proxy(
        address implementation,
        bytes memory _calldata,
        bytes32 salt
    ) external view returns (address proxyPreview);

    /**
     * @notice Preview resulting proxy address from {create3AndCall} or {deployCreate3AndCall} with given salt.
     * @param salt Salt for the deterministic deployment.
     * @return proxyPreview Address of the proxy that would be created.
     */
    function previewCreate3Proxy(bytes32 salt) external view returns (address proxyPreview);

    /**
     * @notice Preview resulting proxy and implementation address from {deployCreateAndCall} through the {CreateProxyAndLogic} custom error.
     * @param implementation Bytecode of the implementation.
     * @param _calldata Initializer calldata.
     * @return proxyPreview Address of the proxy that would be created.
     * @return implementationPreview Address of the deployed implementation.
     */
    function previewCreateProxyAndLogic(
        bytes memory implementation,
        bytes memory _calldata
    ) external returns (address proxyPreview, address implementationPreview);

    /**
     * @notice Preview resulting proxy and implementation address from {deployCreate2AndCall} with given salt.
     * @param implementation Bytecode of the implementation.
     * @param _calldata Initializer calldata.
     * @param salt Salt for the deterministic deployment.
     * @return proxyPreview Address of the proxy that would be created.
     * @return implementationPreview Address of the deployed implementation.
     */
    function previewCreate2ProxyAndLogic(
        bytes memory implementation,
        bytes memory _calldata,
        bytes32 salt
    ) external view returns (address proxyPreview, address implementationPreview);

    /**
     * @notice Preview implementation and proxy address from {deployCreate3AndCall} with given salt.
     * @param salt Salt for the deterministic deployment.
     * @return proxyPreview Address of the new proxy.
     * @return implementationPreview Address of the deployed implementation.
     */
    function previewCreate3ProxyAndLogic(
        bytes32 salt
    ) external view returns (address proxyPreview, address implementationPreview);

    /**
     * @notice Preview resulting implementation address from {upgrade2AndCall} with given salt.
     * @param proxy Existing ITransparentUpgradeableProxy address.
     * @param implementation Bytecode of the new implementation.
     * @return implementationPreview Address for the next implementation.
     * @return version New version number of the proxy.
     */
    function previewCreate2Upgrade(
        ITransparentUpgradeableProxy proxy,
        bytes memory implementation
    ) external view returns (address implementationPreview, uint256 version);

    /**
     * @notice Preview resulting implementation address from {upgrade3AndCall} with given salt.
     * @param proxy Existing ITransparentUpgradeableProxy address.
     * @return implementationPreview Address for the next implementation.
     * @return version New version number of the proxy.
     */
    function previewCreate3Upgrade(
        ITransparentUpgradeableProxy proxy
    ) external view returns (address implementationPreview, uint256 version);

    /**
     * @notice Creates a new proxy for the `implementation` and initializes it with `data`.
     * @param implementation Address of the implementation.
     * @param _calldata Initializer calldata.
     * @return newProxy Deployment information.
     * See {TransparentUpgradeableProxy-constructor}.
     * @custom:signature createAndCall(address,bytes)
     * @custom:selector 0xfb506844
     */
    function createProxy(address implementation, bytes memory _calldata) external payable returns (Deployment memory newProxy);

    /**
     * @notice Creates a new proxy with deterministic address derived from arguments given.
     * @param implementation Address of the implementation.
     * @param _calldata Initializer calldata.
     * @param salt Salt for the deterministic deployment.
     * @return newProxy Deployment information.
     * @custom:signature create2AndCall(address,bytes,bytes32)
     * @custom:selector 0xe852e6d5
     */
    function create2Proxy(
        address implementation,
        bytes memory _calldata,
        bytes32 salt
    ) external payable returns (Deployment memory newProxy);

    /**
     * @notice Creates a new proxy with deterministic address derived only from the salt given.
     * @param implementation Address of the implementation.
     * @param _calldata Initializer calldata.
     * @param salt Salt for the deterministic deployment.
     * @return newProxy Deployment information.
     * @custom:signature create3AndCall(address,bytes,bytes32)
     * @custom:selector 0xbd233f6c
     */
    function create3Proxy(
        address implementation,
        bytes memory _calldata,
        bytes32 salt
    ) external payable returns (Deployment memory newProxy);

    /**
     * @notice Deploys an implementation and creates a proxy initialized with `data` for it.
     * @param implementation Bytecode of the implementation.
     * @param _calldata Initializer calldata.
     * @return newProxy Deployment information.
     * @custom:signature deployCreateAndCall(bytes,bytes)
     * @custom:selector 0xfcdf055e
     */
    function createProxyAndLogic(
        bytes memory implementation,
        bytes memory _calldata
    ) external payable returns (Deployment memory newProxy);

    /**
     * @notice Deterministic version of {deployCreateAndCall} where arguments are used to derive the salt.
     * @dev Implementation salt is salt + 1. Use {previewDeployCreate3} to preview.
     * @param implementation Bytecode of the implementation.
     * @param _calldata Initializer calldata.
     * @param salt Salt to derive both addresses from.
     * @return newProxy Deployment information.
     * @custom:signature deployCreate2AndCall(bytes,bytes,bytes32)
     * @custom:selector 0xeb4495f3
     */
    function create2ProxyAndLogic(
        bytes memory implementation,
        bytes memory _calldata,
        bytes32 salt
    ) external payable returns (Deployment memory newProxy);

    /**
     * @notice Deterministic version of {deployCreateAndCall} where only salt matters.
     * @dev Implementation salt is salt + 1. Use {previewDeployCreate3} to preview.
     * @param implementation Bytecode of the implementation to deploy.
     * @param _calldata Initializer calldata.
     * @param salt Salt to derive both addresses from.
     * @return newProxy Deployment information.
     * @custom:signature deployCreate3AndCall(bytes,bytes,bytes32)
     * @custom:selector 0x99480e85
     */
    function create3ProxyAndLogic(
        bytes memory implementation,
        bytes memory _calldata,
        bytes32 salt
    ) external payable returns (Deployment memory newProxy);

    /// @notice Deploys the @param implementation for {upgradeAndCall} and @return Deployment information.
    function upgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        bytes memory implementation,
        bytes memory _calldata
    ) external payable returns (Deployment memory);

    /// @notice Same as {upgradeAndCall} but @return Deployment information.
    function upgradeAndCallReturn(
        ITransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory _calldata
    ) external payable returns (Deployment memory);

    /**
     * @notice Deterministically deploys the upgrade implementation and calls the {ProxyAdmin-upgradeAndCall}.
     * @dev Implementation salt is salt + next version. Use {previewUpgrade2} to preview.
     * @param proxy Existing ITransparentUpgradeableProxy to upgrade.
     * @param implementation Bytecode of the new implementation.
     * @param _calldata Initializer calldata.
     * @return Deployment Deployment information.
     */

    function create2UpgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        bytes memory implementation,
        bytes memory _calldata
    ) external payable returns (Deployment memory);

    /**
     * @notice Deterministically deploys the upgrade implementatio and calls the {ProxyAdmin-upgradeAndCall}.
     * @dev Implementation salt is salt + next version. Use {previewUpgrade3} to preview.
     * @param proxy Existing ITransparentUpgradeableProxy to upgrade.
     * @param implementation Bytecode of the new implementation.
     * @param _calldata Initializer calldata.
     * @return Deployment Deployment information.
     */
    function create3UpgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        bytes memory implementation,
        bytes memory _calldata
    ) external payable returns (Deployment memory);

    /**
     * @notice Deploy contract using create2.
     * @param creationCode The creation code (bytes).
     * @param _calldata The calldata (bytes).
     * @param salt The salt (bytes32).
     * @return newDeployment Deployment information.
     * @custom:signature deployCreate2(bytes,bytes,bytes32)
     * @custom:selector 0x2197eeb6
     */
    function deployCreate2(
        bytes memory creationCode,
        bytes memory _calldata,
        bytes32 salt
    ) external payable returns (Deployment memory newDeployment);

    /**
     * @notice Deploy contract using create3.
     * @param creationCode The creation code (bytes).
     * @param _calldata The calldata (bytes).
     * @param salt The salt (bytes32).
     * @return newDeployment Deployment information.
     * @custom:signature deployCreate3(bytes,bytes,bytes32)
     * @custom:selector 0xa3419e18
     */
    function deployCreate3(
        bytes memory creationCode,
        bytes memory _calldata,
        bytes32 salt
    ) external payable returns (Deployment memory newDeployment);

    /**
     * @notice Batch any action in this contract.
     * @dev Reverts if any of the calls fail.
     * @dev Delegates to self which keeps context, so msg.value is fine.
     */
    function batch(bytes[] calldata calls) external payable returns (bytes[] memory results);

    /**
     * @notice Batch view data from this contract.
     */
    function batchStatic(bytes[] calldata calls) external view returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IPyth} from "vendor/pyth/IPyth.sol";

contract MockPyth is IPyth {
    mapping(bytes32 => Price) internal prices;

    constructor(bytes[] memory _updateData) {
        for (uint256 i = 0; i < _updateData.length; i++) {
            _set(_updateData[i]);
        }
    }

    function getPriceNoOlderThan(bytes32 _id, uint256 _maxAge) external view override returns (Price memory) {
        if (prices[_id].timestamp >= block.timestamp - _maxAge) {
            return prices[_id];
        }
        revert("Pyth: price too old");
    }

    function getPriceUnsafe(bytes32 _id) external view override returns (Price memory) {
        return prices[_id];
    }

    function getUpdateFee(bytes[] memory _updateData) external pure override returns (uint256) {
        return _updateData.length;
    }

    function updatePriceFeeds(bytes[] memory _updateData) external payable {
        for (uint256 i = 0; i < _updateData.length; i++) {
            _set(_updateData[i]);
        }
    }

    function updatePriceFeedsIfNecessary(
        bytes[] memory _updateData,
        bytes32[] memory _ids,
        uint64[] memory _publishTimes
    ) external payable override {
        for (uint256 i = 0; i < _ids.length; i++) {
            if (prices[_ids[i]].timestamp < _publishTimes[i]) {
                _set(_updateData[i]);
            }
        }
    }

    function getMockPayload(bytes32[] memory _ids, int64[] memory _prices) external view returns (bytes[] memory) {
        bytes[] memory _updateData = new bytes[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            _updateData[i] = abi.encode(_ids[i], IPyth.Price(_prices[i], uint64(_prices[i]) / 1000, -8, block.timestamp));
        }
        return _updateData;
    }

    function _set(bytes memory _update) internal returns (bytes32 id, Price memory price) {
        (id, price) = abi.decode(_update, (bytes32, IPyth.Price));
        prices[id] = price;
    }
}

function createMockPyth(bytes32[] memory _ids, int64[] memory _prices) returns (MockPyth) {
    bytes[] memory _updateData = new bytes[](_ids.length);
    for (uint256 i = 0; i < _ids.length; i++) {
        _updateData[i] = abi.encode(_ids[i], IPyth.Price(_prices[i], uint64(_prices[i]) / 1000, -8, block.timestamp));
    }

    return new MockPyth(_updateData);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockMarketStatus {
    bool public alwaysOpen = true;

    mapping(bytes32 => bool) public tickers;

    function setAlwaysOpen(bool _status) external {
        alwaysOpen = _status;
    }

    function setTickerStatus(bytes32 _ticker, bool _status) external {
        tickers[_ticker] = _status;
    }

    function getTickerStatus(bytes32 _ticker) external view returns (bool) {
        return alwaysOpen || tickers[_ticker];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

/* ========================================================================== */
/*                                   STRUCTS                                  */
/* ========================================================================== */
/**
 * @notice Internal, used execute _liquidateAssets.
 * @param account The account being liquidated.
 * @param repayAmount Amount of the Kresko Assets repaid.
 * @param seizeAmount Calculated amount of collateral being seized.
 * @param repayAsset Address of the Kresko asset being repaid.
 * @param repayIndex Index of the Kresko asset in the accounts minted assets array.
 * @param seizeAsset Address of the collateral asset being seized.
 * @param seizeAssetIndex Index of the collateral asset in the account's collateral assets array.
 */
struct LiquidateExecution {
    address account;
    uint256 repayAmount;
    uint256 seizeAmount;
    address repayAssetAddr;
    uint256 repayAssetIndex;
    address seizedAssetAddr;
    uint256 seizedAssetIndex;
}

struct MinterAccountState {
    uint256 totalDebtValue;
    uint256 totalCollateralValue;
    uint256 collateralRatio;
}
/**
 * @notice Initialization arguments for the protocol
 */
struct MinterInitArgs {
    uint32 liquidationThreshold;
    uint32 minCollateralRatio;
    uint256 minDebtValue;
}

/**
 * @notice Configurable parameters within the protocol
 */

struct MinterParams {
    uint32 minCollateralRatio;
    uint32 liquidationThreshold;
    uint32 maxLiquidationRatio;
    uint256 minDebtValue;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20} from "./IERC20.sol";

interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.20;

import {ITransparentUpgradeableProxy} from "./TransparentUpgradeableProxy.sol";
import {Ownable} from "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev The version of the upgrade interface of the contract. If this getter is missing, both `upgrade(address)`
     * and `upgradeAndCall(address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
     * while `upgradeAndCall` will invoke the `receive` function if the second argument is the empty byte string.
     * If the getter returns `"5.0.0"`, only `upgradeAndCall(address,bytes)` is present, and the second argument must
     * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
     * during an upgrade.
     */
    string public constant UPGRADE_INTERFACE_VERSION = "5.0.0";

    /**
     * @dev Sets the initial owner who can perform upgrades.
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation.
     * See {TransparentUpgradeableProxy-_dispatchUpgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     * - If `data` is empty, `msg.value` must be zero.
     */
    function upgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.20;

import {ERC1967Utils, ERC1967Proxy, ITransparentUpgradeableProxy} from "@oz/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable through an associated {ProxyAdmin} instance.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches the {ITransparentUpgradeableProxy-upgradeToAndCall} function exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can call the `upgradeToAndCall` function but any other call won't be forwarded to
 * the implementation. If the admin tries to call a function on the implementation it will fail with an error indicating
 * the proxy admin cannot fallback to the target implementation.
 *
 * These properties mean that the admin account can only be used for upgrading the proxy, so it's best if it's a
 * dedicated account that is not used for anything else. This will avoid headaches due to sudden errors when trying to
 * call a function from the proxy implementation. For this reason, the proxy deploys an instance of {ProxyAdmin} and
 * allows upgrades only if they come through it. You should think of the `ProxyAdmin` instance as the administrative
 * interface of the proxy, including the ability to change who can trigger upgrades by transferring ownership.
 *
 * NOTE: The real interface of this proxy is that defined in `ITransparentUpgradeableProxy`. This contract does not
 * inherit from that interface, and instead `upgradeToAndCall` is implicitly implemented using a custom dispatch
 * mechanism in `_fallback`. Consequently, the compiler will not produce an ABI for this contract. This is necessary to
 * fully implement transparency without decoding reverts caused by selector clashes between the proxy and the
 * implementation.
 *
 * NOTE: This proxy does not inherit from {Context} deliberately. The {ProxyAdmin} of this contract won't send a
 * meta-transaction in any way, and any other meta-transaction setup should be made in the implementation contract.
 *
 * IMPORTANT: This contract avoids unnecessary storage reads by setting the admin only during construction as an
 * immutable variable, preventing any changes thereafter. However, the admin slot defined in ERC-1967 can still be
 * overwritten by the implementation logic pointed to by this proxy. In such cases, the contract may end up in an
 * undesirable state where the admin slot is different from the actual admin.
 *
 * WARNING: It is not recommended to extend this contract to add additional external functions. If you do so, the
 * compiler will not check that there are no selector conflicts, due to the note above. A selector clash between any new
 * function and the functions declared in {ITransparentUpgradeableProxy} will be resolved in favor of the new one. This
 * could render the `upgradeToAndCall` function inaccessible, preventing upgradeability and compromising transparency.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    // An immutable address for the admin to avoid unnecessary SLOADs before each call
    // at the expense of removing the ability to change the admin once it's set.
    // This is acceptable if the admin is always a ProxyAdmin instance or similar contract
    // with its own ability to transfer the permissions to another account.
    address private immutable _admin;

    /**
     * @dev The proxy caller is the current admin, and can't fallback to the proxy target.
     */
    error ProxyDeniedAdminAccess();

    /**
     * @dev Initializes an upgradeable proxy managed by an instance of a {ProxyAdmin} with an `initialOwner`,
     * backed by the implementation at `_logic`, and optionally initialized with `_data` as explained in
     * {ERC1967Proxy-constructor}.
     *
     * @notice Kresko
     * @dev Removed ProxyAdmin construction - instead using the creator {DeploymentFactory} as {ProxyAdmin}.
     * @dev Factory address is explicitly passed as argument (and not as msg.sender) to support "CREATE3".
     */
    constructor(address _logic, address _factory, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _admin = _factory;
        // Set the storage value and emit an event for ERC-1967 compatibility
        ERC1967Utils.changeAdmin(_proxyAdmin());
    }

    /**
     * @dev Returns the admin of this proxy.
     */
    function _proxyAdmin() internal virtual returns (address) {
        return _admin;
    }

    /**
     * @dev If caller is the admin process the call internally, otherwise transparently fallback to the proxy behavior.
     */
    function _fallback() internal virtual override {
        if (msg.sender == _proxyAdmin()) {
            if (msg.sig != ITransparentUpgradeableProxy.upgradeToAndCall.selector) {
                revert ProxyDeniedAdminAccess();
            } else {
                _dispatchUpgradeToAndCall();
            }
        } else {
            super._fallback();
        }
    }

    /**
     * @dev Upgrade the implementation of the proxy. See {ERC1967Utils-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - If `data` is empty, `msg.value` must be zero.
     */
    function _dispatchUpgradeToAndCall() private {
        (address newImplementation, bytes memory data) = abi.decode(msg.data[4:], (address, bytes));
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Solady https://github.com/Vectorized/solady
library Solady {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the contract.
    error DeploymentFailed();

    /// @dev Unable to initialize the contract.
    error InitializationFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      BYTECODE CONSTANTS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * -------------------------------------------------------------------+
     * Opcode      | Mnemonic         | Stack        | Memory             |
     * -------------------------------------------------------------------|
     * 36          | CALLDATASIZE     | cds          |                    |
     * 3d          | RETURNDATASIZE   | 0 cds        |                    |
     * 3d          | RETURNDATASIZE   | 0 0 cds      |                    |
     * 37          | CALLDATACOPY     |              | [0..cds): calldata |
     * 36          | CALLDATASIZE     | cds          | [0..cds): calldata |
     * 3d          | RETURNDATASIZE   | 0 cds        | [0..cds): calldata |
     * 34          | CALLVALUE        | value 0 cds  | [0..cds): calldata |
     * f0          | CREATE           | newContract  | [0..cds): calldata |
     * -------------------------------------------------------------------|
     * Opcode      | Mnemonic         | Stack        | Memory             |
     * -------------------------------------------------------------------|
     * 67 bytecode | PUSH8 bytecode   | bytecode     |                    |
     * 3d          | RETURNDATASIZE   | 0 bytecode   |                    |
     * 52          | MSTORE           |              | [0..8): bytecode   |
     * 60 0x08     | PUSH1 0x08       | 0x08         | [0..8): bytecode   |
     * 60 0x18     | PUSH1 0x18       | 0x18 0x08    | [0..8): bytecode   |
     * f3          | RETURN           |              | [0..8): bytecode   |
     * -------------------------------------------------------------------+
     */

    /// @dev The proxy bytecode.
    uint256 private constant _PROXY_BYTECODE = 0x67363d3d37363d34f03d5260086018f3;

    /// @dev Hash of the `_PROXY_BYTECODE`.
    /// Equivalent to `keccak256(abi.encodePacked(hex"67363d3d37363d34f03d5260086018f3"))`.
    bytes32 private constant _PROXY_BYTECODE_HASH = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      CREATE3 OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// Deploy to deterministic addresses without an initcode factor.
    /// Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol)
    /// Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
    /// @dev Deploys `creationCode` deterministically with a `salt`.
    /// The deployed contract is funded with `value` (in wei) ETH.
    /// Returns the deterministic address of the deployed contract,
    /// which solely depends on `salt`.
    function create3(bytes32 salt, bytes memory creationCode, uint256 value) internal returns (address deployed) {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the `_PROXY_BYTECODE` into scratch space.
            mstore(0x00, _PROXY_BYTECODE)
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            let proxy := create2(0, 0x10, 0x10, salt)

            // If the result of `create2` is the zero address, revert.
            if iszero(proxy) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the proxy's address.
            mstore(0x14, proxy)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            // Nonce of the proxy contract (1).
            mstore8(0x34, 0x01)

            deployed := keccak256(0x1e, 0x17)

            // If the `call` fails, revert.
            if iszero(
                call(
                    gas(), // Gas remaining.
                    proxy, // Proxy's address.
                    value, // Ether value.
                    add(creationCode, 0x20), // Start of `creationCode`.
                    mload(creationCode), // Length of `creationCode`.
                    0x00, // Offset of output.
                    0x00 // Length of output.
                )
            ) {
                // Store the function selector of `InitializationFailed()`.
                mstore(0x00, 0x19b991a8)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If the code size of `deployed` is zero, revert.
            if iszero(extcodesize(deployed)) {
                // Store the function selector of `InitializationFailed()`.
                mstore(0x00, 0x19b991a8)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the deterministic address for `salt`.
    function peek3(bytes32 salt) internal view returns (address deployed) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the free memory pointer.
            let m := mload(0x40)
            // Store `address(this)`.
            mstore(0x00, address())
            // Store the prefix.
            mstore8(0x0b, 0xff)
            // Store the salt.
            mstore(0x20, salt)
            // Store the bytecode hash.
            mstore(0x40, _PROXY_BYTECODE_HASH)

            // Store the proxy's address.
            mstore(0x14, keccak256(0x0b, 0x55))
            // Restore the free memory pointer.
            mstore(0x40, m)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            // Nonce of the proxy contract (1).
            mstore8(0x34, 0x01)

            deployed := keccak256(0x1e, 0x17)
        }
    }

    /// @notice Enables a single call to call multiple methods on itself.
    /// Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
    /// Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Multicallable.sol)
    /// @dev Apply `DELEGATECALL` with the current contract to each calldata in `data`,
    /// and store the `abi.encode` formatted results of each `DELEGATECALL` into `results`.
    /// If any of the `DELEGATECALL`s reverts, the entire context is reverted,
    /// and the error is bubbled up.
    ///
    /// For payable, see: https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong)
    ///
    /// For efficiency, this function will directly return the results, terminating the context.
    /// If called internally, it must be called at the end of a function
    /// that returns `(bytes[] memory)`.
    function multicall(bytes[] calldata data) internal returns (bytes[] memory) {
        assembly {
            mstore(0x00, 0x20)
            mstore(0x20, data.length) // Store `data.length` into `results`.
            // Early return if no data.
            if iszero(data.length) {
                return(0x00, 0x40)
            }

            let results := 0x40
            // `shl` 5 is equivalent to multiplying by 0x20.
            let end := shl(5, data.length)
            // Copy the offsets from calldata into memory.
            calldatacopy(0x40, data.offset, end)
            // Offset into `results`.
            let resultsOffset := end
            // Pointer to the end of `results`.
            end := add(results, end)

            for {

            } 1 {

            } {
                // The offset of the current bytes in the calldata.
                let o := add(data.offset, mload(results))
                let m := add(resultsOffset, 0x40)
                // Copy the current bytes from calldata to the memory.
                calldatacopy(
                    m,
                    add(o, 0x20), // The offset of the current bytes' bytes.
                    calldataload(o) // The length of the current bytes.
                )
                if iszero(delegatecall(gas(), address(), m, calldataload(o), codesize(), 0x00)) {
                    // Bubble up the revert if the delegatecall reverts.
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                // Append the current `resultsOffset` into `results`.
                mstore(results, resultsOffset)
                results := add(results, 0x20)
                // Append the `returndatasize()`, and the return data.
                mstore(m, returndatasize())
                returndatacopy(add(m, 0x20), 0x00, returndatasize())
                // Advance the `resultsOffset` by `returndatasize() + 0x20`,
                // rounded up to the next multiple of 32.
                resultsOffset := and(add(add(resultsOffset, returndatasize()), 0x3f), 0xffffffffffffffe0)
                if iszero(lt(results, end)) {
                    break
                }
            }
            return(0x00, add(resultsOffset, 0x40))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import {IERC20Permit} from "./IERC20Permit.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
contract ERC20 is IERC20Permit {
    /* -------------------------------------------------------------------------- */
    /*                                ERC20 Storage                               */
    /* -------------------------------------------------------------------------- */

    string public name;
    string public symbol;
    uint8 public immutable decimals;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    /* -------------------------------------------------------------------------- */
    /*                                  EIP-2612                                  */
    /* -------------------------------------------------------------------------- */

    mapping(address => uint256) public nonces;

    /* -------------------------------------------------------------------------- */
    /*                                 Immutables                                 */
    /* -------------------------------------------------------------------------- */

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /* -------------------------------------------------------------------------- */
    /*                                    READ                                    */
    /* -------------------------------------------------------------------------- */

    function balanceOf(address _account) public view virtual returns (uint256) {
        return _balances[_account];
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view virtual returns (uint256) {
        return _allowances[_owner][_spender];
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ERC20 Logic                                */
    /* -------------------------------------------------------------------------- */

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _balances[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balances[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = _allowances[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            _allowances[from][msg.sender] = allowed - amount;

        _balances[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /* -------------------------------------------------------------------------- */
    /*                               EIP-2612 Logic                               */
    /* -------------------------------------------------------------------------- */

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline)
            revert PERMIT_DEADLINE_EXPIRED(
                owner,
                spender,
                deadline,
                block.timestamp
            );

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
            if (recoveredAddress == address(0) || recoveredAddress != owner)
                revert INVALID_SIGNER(owner, recoveredAddress);

            _allowances[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Internals                                 */
    /* -------------------------------------------------------------------------- */

    function _mint(address to, uint256 amount) internal virtual {
        _totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balances[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        _balances[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            _totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {VaultAsset, VaultConfiguration} from "vault/VTypes.sol";

interface IVault {
    /* -------------------------------------------------------------------------- */
    /*                                Functionality                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice This function deposits `assetsIn` of `asset`, regardless of the amount of vault shares minted.
     * @notice If depositFee > 0, `depositFee` of `assetsIn` is sent to the fee recipient.
     * @dev emits Deposit(caller, receiver, asset, assetsIn, sharesOut);
     * @param assetAddr Asset to deposit.
     * @param assetsIn Amount of `asset` to deposit.
     * @param receiver Address to receive `sharesOut` of vault shares.
     * @return sharesOut Amount of vault shares minted for `assetsIn`.
     * @return assetFee Amount of fees paid in `asset`.
     */
    function deposit(
        address assetAddr,
        uint256 assetsIn,
        address receiver
    ) external returns (uint256 sharesOut, uint256 assetFee);

    /**
     * @notice This function mints `sharesOut` of vault shares, regardless of the amount of `asset` received.
     * @notice If depositFee > 0, `depositFee` of `assetsIn` is sent to the fee recipient.
     * @param assetAddr Asset to deposit.
     * @param sharesOut Amount of vault shares desired to mint.
     * @param receiver Address to receive `sharesOut` of shares.
     * @return assetsIn Assets used to mint `sharesOut` of vault shares.
     * @return assetFee Amount of fees paid in `asset`.
     * @dev emits Deposit(caller, receiver, asset, assetsIn, sharesOut);
     */
    function mint(address assetAddr, uint256 sharesOut, address receiver) external returns (uint256 assetsIn, uint256 assetFee);

    /**
     * @notice This function burns `sharesIn` of shares from `owner`, regardless of the amount of `asset` received.
     * @notice If withdrawFee > 0, `withdrawFee` of `assetsOut` is sent to the fee recipient.
     * @param assetAddr Asset to redeem.
     * @param sharesIn Amount of vault shares to redeem.
     * @param receiver Address to receive the redeemed assets.
     * @param owner Owner of vault shares.
     * @return assetsOut Amount of `asset` used for redeem `assetsOut`.
     * @return assetFee Amount of fees paid in `asset`.
     * @dev emits Withdraw(caller, receiver, asset, owner, assetsOut, sharesIn);
     */
    function redeem(
        address assetAddr,
        uint256 sharesIn,
        address receiver,
        address owner
    ) external returns (uint256 assetsOut, uint256 assetFee);

    /**
     * @notice This function withdraws `assetsOut` of assets, regardless of the amount of vault shares required.
     * @notice If withdrawFee > 0, `withdrawFee` of `assetsOut` is sent to the fee recipient.
     * @param assetAddr Asset to withdraw.
     * @param assetsOut Amount of `asset` desired to withdraw.
     * @param receiver Address to receive the withdrawn assets.
     * @param owner Owner of vault shares.
     * @return sharesIn Amount of vault shares used to withdraw `assetsOut` of `asset`.
     * @return assetFee Amount of fees paid in `asset`.
     * @dev emits Withdraw(caller, receiver, asset, owner, assetsOut, sharesIn);
     */
    function withdraw(
        address assetAddr,
        uint256 assetsOut,
        address receiver,
        address owner
    ) external returns (uint256 sharesIn, uint256 assetFee);

    /* -------------------------------------------------------------------------- */
    /*                                    Views                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Returns the current vault configuration
     * @return config Vault configuration struct
     */
    function getConfig() external view returns (VaultConfiguration memory config);

    /**
     * @notice Returns the total value of all assets in the shares contract in USD WAD precision.
     */
    function totalAssets() external view returns (uint256 result);

    /**
     * @notice Array of all assets
     */
    function allAssets() external view returns (VaultAsset[] memory assets);

    /**
     * @notice Assets array used for iterating through the assets in the shares contract
     */
    function assetList(uint256 index) external view returns (address assetAddr);

    /**
     * @notice Returns the asset struct for a given asset
     * @param asset Supported asset address
     * @return asset Asset struct for `asset`
     */
    function assets(address) external view returns (VaultAsset memory asset);

    function assetPrice(address assetAddr) external view returns (uint256);

    /**
     * @notice This function is used for previewing the amount of shares minted for `assetsIn` of `asset`.
     * @param assetAddr Supported asset address
     * @param assetsIn Amount of `asset` in.
     * @return sharesOut Amount of vault shares minted.
     * @return assetFee Amount of fees paid in `asset`.
     */
    function previewDeposit(address assetAddr, uint256 assetsIn) external view returns (uint256 sharesOut, uint256 assetFee);

    /**
     * @notice This function is used for previewing `assetsIn` of `asset` required to mint `sharesOut` of vault shares.
     * @param assetAddr Supported asset address
     * @param sharesOut Desired amount of vault shares to mint.
     * @return assetsIn Amount of `asset` required.
     * @return assetFee Amount of fees paid in `asset`.
     */
    function previewMint(address assetAddr, uint256 sharesOut) external view returns (uint256 assetsIn, uint256 assetFee);

    /**
     * @notice This function is used for previewing `assetsOut` of `asset` received for `sharesIn` of vault shares.
     * @param assetAddr Supported asset address
     * @param sharesIn Desired amount of vault shares to burn.
     * @return assetsOut Amount of `asset` received.
     * @return assetFee Amount of fees paid in `asset`.
     */
    function previewRedeem(address assetAddr, uint256 sharesIn) external view returns (uint256 assetsOut, uint256 assetFee);

    /**
     * @notice This function is used for previewing `sharesIn` of vault shares required to burn for `assetsOut` of `asset`.
     * @param assetAddr Supported asset address
     * @param assetsOut Desired amount of `asset` out.
     * @return sharesIn Amount of vault shares required.
     * @return assetFee Amount of fees paid in `asset`.
     */
    function previewWithdraw(address assetAddr, uint256 assetsOut) external view returns (uint256 sharesIn, uint256 assetFee);

    /**
     * @notice Returns the maximum deposit amount of `asset`
     * @param assetAddr Supported asset address
     * @return assetsIn Maximum depositable amount of assets.
     */
    function maxDeposit(address assetAddr) external view returns (uint256 assetsIn);

    /**
     * @notice Returns the maximum mint using `asset`
     * @param assetAddr Supported asset address.
     * @param owner Owner of assets.
     * @return sharesOut Maximum mint amount.
     */
    function maxMint(address assetAddr, address owner) external view returns (uint256 sharesOut);

    /**
     * @notice Returns the maximum redeemable amount for `user`
     * @param assetAddr Supported asset address.
     * @param owner Owner of vault shares.
     * @return sharesIn Maximum redeemable amount of `shares` (vault share balance)
     */
    function maxRedeem(address assetAddr, address owner) external view returns (uint256 sharesIn);

    /**
     * @notice Returns the maximum redeemable amount for `user`
     * @param assetAddr Supported asset address.
     * @param owner Owner of vault shares.
     * @return amountOut Maximum amount of `asset` received.
     */
    function maxWithdraw(address assetAddr, address owner) external view returns (uint256 amountOut);

    /**
     * @notice Returns the exchange rate of one vault share to USD.
     * @return rate Exchange rate of one vault share to USD in wad precision.
     */
    function exchangeRate() external view returns (uint256 rate);

    /* -------------------------------------------------------------------------- */
    /*                                    Admin                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Adds a new asset to the vault
     * @param assetConfig Asset to add
     */
    function addAsset(VaultAsset memory assetConfig) external returns (VaultAsset memory);

    /**
     * @notice Removes an asset from the vault
     * @param assetAddr Asset address to remove
     * emits assetRemoved(asset, block.timestamp);
     */
    function removeAsset(address assetAddr) external;

    /**
     * @notice Current governance sets a new governance address
     * @param newGovernance The new governance address
     */
    function setGovernance(address newGovernance) external;

    function acceptGovernance() external;

    /**
     * @notice Current governance sets a new fee recipient address
     * @param newFeeRecipient The new fee recipient address
     */
    function setFeeRecipient(address newFeeRecipient) external;

    /**
     * @notice Sets a new oracle for a asset
     * @param assetAddr Asset to set the oracle for
     * @param feedAddr Feed to set
     * @param newStaleTime Time in seconds for the feed to be considered stale
     */
    function setAssetFeed(address assetAddr, address feedAddr, uint24 newStaleTime) external;

    /**
     * @notice Sets a new oracle decimals
     * @param newDecimals New oracle decimal precision
     */
    function setFeedPricePrecision(uint8 newDecimals) external;

    /**
     * @notice Sets the max deposit amount for a asset
     * @param assetAddr Asset to set the max deposits for
     * @param newMaxDeposits Max deposits to set
     */
    function setMaxDeposits(address assetAddr, uint248 newMaxDeposits) external;

    /**
     * @notice Sets the enabled status for a asset
     * @param assetAddr Asset to set the enabled status for
     * @param isEnabled Enabled status to set
     */
    function setAssetEnabled(address assetAddr, bool isEnabled) external;

    /**
     * @notice Sets the deposit fee for a asset
     * @param assetAddr Asset to set the deposit fee for
     * @param newDepositFee Fee to set
     */
    function setDepositFee(address assetAddr, uint16 newDepositFee) external;

    /**
     * @notice Sets the withdraw fee for a asset
     * @param assetAddr Asset to set the withdraw fee for
     * @param newWithdrawFee Fee to set
     */
    function setWithdrawFee(address assetAddr, uint16 newWithdrawFee) external;

    /* -------------------------------------------------------------------------- */
    /*                                   Errors                                   */
    /* -------------------------------------------------------------------------- */
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMath {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(uint256 x, uint256 n, uint256 scalar) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library VEvent {
    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when a deposit/mint is made
     * @param caller Caller of the deposit/mint
     * @param receiver Receiver of the minted assets
     * @param asset Asset that was deposited/minted
     * @param assetsIn Amount of assets deposited
     * @param sharesOut Amount of shares minted
     */
    event Deposit(address indexed caller, address indexed receiver, address indexed asset, uint256 assetsIn, uint256 sharesOut);

    /**
     * @notice Emitted when a new oracle is set for an asset
     * @param asset Asset that was updated
     * @param feed Feed that was set
     * @param staletime Time in seconds for the feed to be considered stale
     * @param price Price at the time of setting the feed
     * @param timestamp Timestamp of the update
     */
    event OracleSet(address indexed asset, address indexed feed, uint256 staletime, uint256 price, uint256 timestamp);

    /**
     * @notice Emitted when a new asset is added to the shares contract
     * @param asset Address of the asset
     * @param feed Price feed of the asset
     * @param symbol Asset symbol
     * @param staletime Time in seconds for the feed to be considered stale
     * @param price Price of the asset
     * @param depositLimit Deposit limit of the asset
     * @param timestamp Timestamp of the addition
     */
    event AssetAdded(
        address indexed asset,
        address indexed feed,
        string indexed symbol,
        uint256 staletime,
        uint256 price,
        uint256 depositLimit,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a previously existing asset is removed from the shares contract
     * @param asset Asset that was removed
     * @param timestamp Timestamp of the removal
     */
    event AssetRemoved(address indexed asset, uint256 timestamp);
    /**
     * @notice Emitted when the enabled status for asset is changed
     * @param asset Asset that was removed
     * @param enabled Enabled status set
     * @param timestamp Timestamp of the removal
     */
    event AssetEnabledChange(address indexed asset, bool enabled, uint256 timestamp);

    /**
     * @notice Emitted when a withdraw/redeem is made
     * @param caller Caller of the withdraw/redeem
     * @param receiver Receiver of the withdrawn assets
     * @param asset Asset that was withdrawn/redeemed
     * @param owner Owner of the withdrawn assets
     * @param assetsOut Amount of assets withdrawn
     * @param sharesIn Amount of shares redeemed
     */
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed asset,
        address owner,
        uint256 assetsOut,
        uint256 sharesIn
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {PercentageMath} from "libs/PercentageMath.sol";
import {WadRay} from "libs/WadRay.sol";
import {Errors} from "common/Errors.sol";
import {isSequencerUp} from "common/funcs/Utils.sol";
import {Percents} from "common/Constants.sol";
import {aggregatorV3Price} from "common/funcs/Prices.sol";
import {wadUSD} from "common/funcs/Math.sol";
import {VaultConfiguration, VaultAsset} from "vault/VTypes.sol";

/**
 * @title LibVault
 * @author Kresko
 * @notice Helper library for KreskoVault
 */
library VAssets {
    using WadRay for uint256;
    using PercentageMath for uint256;
    using PercentageMath for uint32;
    using VAssets for VaultAsset;
    using VAssets for uint256;

    /// @notice Gets the price of an asset from the oracle speficied.
    function price(VaultAsset storage self, VaultConfiguration storage config) internal view returns (uint256 answer) {
        if (!isSequencerUp(config.sequencerUptimeFeed, config.sequencerGracePeriodTime)) {
            revert Errors.L2_SEQUENCER_DOWN();
        }
        answer = aggregatorV3Price(address(self.feed), self.staleTime);
        if (answer == 0) revert Errors.ZERO_OR_STALE_VAULT_PRICE(Errors.id(address(self.token)), address(self.feed), answer);
    }

    /// @notice Gets the price of an asset from the oracle speficied.
    function handleDepositFee(
        VaultAsset storage self,
        uint256 assets
    ) internal view returns (uint256 assetsWithFee, uint256 fee) {
        uint256 depositFee = self.depositFee;
        if (depositFee == 0) {
            return (assets, 0);
        }

        fee = assets.percentMul(depositFee);
        assetsWithFee = assets - fee;
    }

    /// @notice Gets the price of an asset from the oracle speficied.
    function handleMintFee(VaultAsset storage self, uint256 assets) internal view returns (uint256 assetsWithFee, uint256 fee) {
        uint256 depositFee = self.depositFee;
        if (depositFee == 0) {
            return (assets, 0);
        }

        assetsWithFee = assets.percentDiv(Percents.HUNDRED - depositFee);
        fee = assetsWithFee - assets;
    }

    /// @notice Gets the price of an asset from the oracle speficied.
    function handleWithdrawFee(
        VaultAsset storage self,
        uint256 assets
    ) internal view returns (uint256 assetsWithFee, uint256 fee) {
        uint256 withdrawFee = self.withdrawFee;
        if (withdrawFee == 0) {
            return (assets, 0);
        }

        assetsWithFee = assets.percentDiv(Percents.HUNDRED - withdrawFee);
        fee = assetsWithFee - assets;
    }

    /// @notice Gets the price of an asset from the oracle speficied.
    function handleRedeemFee(
        VaultAsset storage self,
        uint256 assets
    ) internal view returns (uint256 assetsWithFee, uint256 fee) {
        uint256 withdrawFee = self.withdrawFee;
        if (withdrawFee == 0) {
            return (assets, 0);
        }

        fee = assets.percentMul(withdrawFee);
        assetsWithFee = assets - fee;
    }

    /// @notice Gets the oracle decimal precision USD value for `amount`.
    /// @param config vault configuration.
    /// @param amount amount of tokens to get USD value for.
    function usdWad(
        VaultAsset storage self,
        VaultConfiguration storage config,
        uint256 amount
    ) internal view returns (uint256) {
        return wadUSD(amount, self.decimals, self.price(config), config.oracleDecimals);
    }

    /// @notice Gets the total deposit value of `self` in USD, oracle precision.
    function getDepositValue(VaultAsset storage self, VaultConfiguration storage config) internal view returns (uint256) {
        uint256 bal = self.token.balanceOf(address(this));
        if (bal == 0) return 0;
        return bal.wadMul(self.price(config));
    }

    /// @notice Gets the total deposit value of `self` in USD, oracle precision.
    function getDepositValueWad(VaultAsset storage self, VaultConfiguration storage config) internal view returns (uint256) {
        uint256 bal = self.token.balanceOf(address(this));
        if (bal == 0) return 0;
        return self.usdWad(config, bal);
    }

    /// @notice Gets the a token amount for `value` USD, oracle precision.
    function getAmount(
        VaultAsset storage self,
        VaultConfiguration storage config,
        uint256 value
    ) internal view returns (uint256) {
        uint256 valueScaled = (value * 1e18) / 10 ** ((36 - config.oracleDecimals) - self.decimals);

        return valueScaled / self.price(config);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/extensions/AccessControlEnumerable.sol)

pragma solidity ^0.8.20;

import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/IAccessControlEnumerable.sol";
import {AccessControlUpgradeable} from "../AccessControlUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @custom:storage-location erc7201:openzeppelin.storage.AccessControlEnumerable
    struct AccessControlEnumerableStorage {
        mapping(bytes32 role => EnumerableSet.AddressSet) _roleMembers;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControlEnumerable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AccessControlEnumerableStorageLocation = 0xc1f6fe24621ce81ec5827caf0253cadb74709b061630e6b55e82371705932000;

    function _getAccessControlEnumerableStorage() private pure returns (AccessControlEnumerableStorage storage $) {
        assembly {
            $.slot := AccessControlEnumerableStorageLocation
        }
    }

    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual returns (address) {
        AccessControlEnumerableStorage storage $ = _getAccessControlEnumerableStorage();
        return $._roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual returns (uint256) {
        AccessControlEnumerableStorage storage $ = _getAccessControlEnumerableStorage();
        return $._roleMembers[role].length();
    }

    /**
     * @dev Overload {AccessControl-_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override returns (bool) {
        AccessControlEnumerableStorage storage $ = _getAccessControlEnumerableStorage();
        bool granted = super._grantRole(role, account);
        if (granted) {
            $._roleMembers[role].add(account);
        }
        return granted;
    }

    /**
     * @dev Overload {AccessControl-_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override returns (bool) {
        AccessControlEnumerableStorage storage $ = _getAccessControlEnumerableStorage();
        bool revoked = super._revokeRole(role, account);
        if (revoked) {
            $._roleMembers[role].remove(account);
        }
        return revoked;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20Permit} from "kresko-lib/token/IERC20Permit.sol";
import {SafeTransfer} from "kresko-lib/token/SafeTransfer.sol";
import {ERC20Upgradeable} from "kresko-lib/token/ERC20Upgradeable.sol";

import {FixedPointMath} from "libs/FixedPointMath.sol";
import {Errors} from "common/Errors.sol";

import {IKreskoAsset} from "./IKreskoAsset.sol";
import {IERC4626Upgradeable} from "./IERC4626Upgradeable.sol";

/* solhint-disable func-name-mixedcase */
/* solhint-disable no-empty-blocks */
/* solhint-disable func-visibility */

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @notice Kresko:
/// Adds issue/destroy functions that are called when KreskoAssets are minted/burned through the protocol.
/// @notice shares = anchor tokens
/// @notice assets = underlying KreskoAssets
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
/// @author Kresko (https://www.kresko.fi)
abstract contract ERC4626Upgradeable is IERC4626Upgradeable, ERC20Upgradeable {
    using SafeTransfer for IKreskoAsset;
    using FixedPointMath for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    event Issue(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Destroy(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    /* -------------------------------------------------------------------------- */
    /*                                 Immutables                                 */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IERC4626Upgradeable
    IKreskoAsset public immutable asset;

    constructor(IKreskoAsset _asset) payable {
        asset = _asset;
    }

    /**
     * @notice Initializes the ERC4626.
     *
     * @param _asset The underlying (Kresko) Asset
     * @param _name Name of the anchor token
     * @param _symbol Symbol of the anchor token
     * @dev decimals are read from the underlying asset
     */
    function __ERC4626Upgradeable_init(
        IERC20Permit _asset,
        string memory _name,
        string memory _symbol
    ) internal onlyInitializing {
        __ERC20Upgradeable_init(_name, _symbol, _asset.decimals());
    }

    /* -------------------------------------------------------------------------- */
    /*                                Issue & Destroy                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice When new KreskoAssets are minted:
     * Issues the equivalent amount of anchor tokens to Kresko
     * Issues the equivalent amount of assets to user
     */
    function issue(uint256 assets, address to) public virtual returns (uint256 shares) {
        shares = convertToShares(assets);

        // Mint shares to kresko
        _mint(asset.kresko(), shares);
        // Mint assets to receiver
        asset.mint(to, assets);

        emit Issue(msg.sender, to, assets, shares);

        _afterDeposit(assets, shares);
    }

    /**
     * @notice When new KreskoAssets are burned:
     * Destroys the equivalent amount of anchor tokens from Kresko
     * Destroys the equivalent amount of assets from user
     */
    function destroy(uint256 assets, address from) public virtual returns (uint256 shares) {
        shares = convertToShares(assets);

        _beforeWithdraw(assets, shares);

        // Burn shares from kresko
        _burn(asset.kresko(), shares);
        // Burn assets from user
        asset.burn(from, assets);

        emit Destroy(msg.sender, from, from, assets, shares);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Accounting Logic                              */
    /* -------------------------------------------------------------------------- */

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256 shares) {
        uint256 supply = _totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        shares = supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
        if (shares == 0) revert Errors.ZERO_SHARES_FROM_ASSETS(_assetId(), assets, _anchorId());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256 assets) {
        uint256 supply = _totalSupply; // Saves an extra SLOAD if _totalSupply is non-zero.

        assets = supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
        if (assets == 0) revert Errors.ZERO_ASSETS_FROM_SHARES(_anchorId(), shares, _assetId());
    }

    /// @return shares for amount of @param assets
    function previewIssue(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /// @return shares for amount of @param assets
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /// @return assets for amount of @param shares
    function previewDestroy(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /// @return assets for amount of @param shares
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /// @return assets for amount of @param shares
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = _totalSupply; // Saves an extra SLOAD if _totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    /// @return shares for amount of @param assets
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = _totalSupply; // Saves an extra SLOAD if _totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    /* -------------------------------------------------------------------------- */
    /*                       DEPOSIT/WITHDRAWAL LIMIT VIEWS                       */
    /* -------------------------------------------------------------------------- */

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxIssue(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxDestroy(address owner) public view virtual returns (uint256) {
        return convertToAssets(_balances[owner]);
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(_balances[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return _balances[owner];
    }

    /* -------------------------------------------------------------------------- */
    /*                               EXTERNAL USE                                 */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IERC4626Upgradeable
    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        shares = previewDeposit(assets);

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        _afterDeposit(assets, shares);
    }

    /// @inheritdoc IERC4626Upgradeable
    function withdraw(uint256 assets, address receiver, address owner) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = _allowances[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) {
                _allowances[owner][msg.sender] = allowed - shares;
            }
        }

        _beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /// @inheritdoc IERC4626Upgradeable
    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        _afterDeposit(assets, shares);
    }

    /// @inheritdoc IERC4626Upgradeable
    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = _allowances[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) {
                _allowances[owner][msg.sender] = allowed - shares;
            }
        }
        assets = previewRedeem(shares);

        _beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /* -------------------------------------------------------------------------- */
    /*                            INTERNAL HOOKS LOGIC                            */
    /* -------------------------------------------------------------------------- */

    function _anchorId() internal view returns (Errors.ID memory) {
        return Errors.ID(symbol, address(this));
    }

    function _assetId() internal view returns (Errors.ID memory) {
        return Errors.id(address(asset));
    }

    function _beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function _afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Pausable
    struct PausableStorage {
        bool _paused;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Pausable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PausableStorageLocation = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;

    function _getPausableStorage() private pure returns (PausableStorage storage $) {
        assembly {
            $.slot := PausableStorageLocation
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        PausableStorage storage $ = _getPausableStorage();
        return $._paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Permit} from "./IERC20Permit.sol";

/* solhint-disable var-name-mixedcase */
/* solhint-disable not-rely-on-time */
/* solhint-disable func-name-mixedcase */
/* solhint-disable no-empty-blocks */

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @author Kresko: modified to an upgradeable
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.

abstract contract ERC20Upgradeable is Initializable, IERC20Permit {
    /* -------------------------------------------------------------------------- */
    /*                                ERC20 Storage                               */
    /* -------------------------------------------------------------------------- */

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    /* -------------------------------------------------------------------------- */
    /*                                  EIP-2612                                  */
    /* -------------------------------------------------------------------------- */

    mapping(address => uint256) public nonces;

    /* -------------------------------------------------------------------------- */
    /*                                 Constructor                                */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20Upgradeable_init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal onlyInitializing {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    READ                                    */
    /* -------------------------------------------------------------------------- */

    function balanceOf(address _account) public view virtual returns (uint256) {
        return _balances[_account];
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view virtual returns (uint256) {
        return _allowances[_owner][_spender];
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ERC20 Logic                                */
    /* -------------------------------------------------------------------------- */

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _beforeTokenTransfer(msg.sender, to, amount);

        _balances[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balances[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);

        uint256 allowed = _allowances[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            _allowances[from][msg.sender] = allowed - amount;

        _balances[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /* -------------------------------------------------------------------------- */
    /*                               EIP-2612 Logic                               */
    /* -------------------------------------------------------------------------- */

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline)
            revert PERMIT_DEADLINE_EXPIRED(
                owner,
                spender,
                deadline,
                block.timestamp
            );

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
            if (recoveredAddress == address(0) || recoveredAddress != owner)
                revert INVALID_SIGNER(owner, recoveredAddress);

            _allowances[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Internals                                 */
    /* -------------------------------------------------------------------------- */

    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);

        _totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balances[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);

        _balances[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            _totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        // Silence state mutability warning without generating bytecode.
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {FixedPointMath} from "libs/FixedPointMath.sol";
import {IKreskoAsset} from "./IKreskoAsset.sol";

library Rebaser {
    using FixedPointMath for uint256;

    /**
     * @notice Unrebase a value by a given rebase struct.
     * @param self The value to unrebase.
     * @param _rebase The rebase struct.
     * @return The unrebased value.
     */
    function unrebase(uint256 self, IKreskoAsset.Rebase storage _rebase) internal view returns (uint256) {
        if (_rebase.denominator == 0) return self;
        return _rebase.positive ? self.divWadDown(_rebase.denominator) : self.mulWadDown(_rebase.denominator);
    }

    /**
     * @notice Rebase a value by a given rebase struct.
     * @param self The value to rebase.
     * @param _rebase The rebase struct.
     * @return The rebased value.
     */
    function rebase(uint256 self, IKreskoAsset.Rebase storage _rebase) internal view returns (uint256) {
        if (_rebase.denominator == 0) return self;
        return _rebase.positive ? self.mulWadDown(_rebase.denominator) : self.divWadDown(_rebase.denominator);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {View} from "periphery/ViewTypes.sol";
import {RawPrice} from "common/Types.sol";
import {VaultAsset} from "vault/VTypes.sol";
import {PythView} from "vendor/pyth/PythScript.sol";

interface IDataV1 {
    struct PreviewWithdrawArgs {
        address vaultAsset;
        uint256 outputAmount;
        bytes path;
    }

    struct ExternalTokenArgs {
        address token;
        address feed;
    }

    struct DVAsset {
        address addr;
        string name;
        string symbol;
        uint8 oracleDecimals;
        uint256 vSupply;
        bool isMarketOpen;
        uint256 tSupply;
        RawPrice priceRaw;
        VaultAsset config;
        uint256 price;
    }

    struct DVToken {
        string symbol;
        uint8 decimals;
        string name;
        uint256 price;
        uint8 oracleDecimals;
        uint256 tSupply;
    }

    struct DVault {
        DVAsset[] assets;
        DVToken token;
    }

    struct DCollection {
        address addr;
        string name;
        string symbol;
        string uri;
        DCollectionItem[] items;
    }

    struct DCollectionItem {
        uint256 id;
        string uri;
        uint256 balance;
    }

    struct DGlobal {
        View.Protocol protocol;
        DVault vault;
        DCollection[] collections;
        uint256 chainId;
    }

    struct DVTokenBalance {
        address addr;
        string name;
        string symbol;
        uint256 amount;
        uint256 tSupply;
        uint8 oracleDecimals;
        uint256 val;
        uint8 decimals;
        uint256 price;
        RawPrice priceRaw;
        uint256 chainId;
    }

    struct DAccount {
        View.Account protocol;
        DCollection[] collections;
        DVTokenBalance vault;
        bool eligible;
        uint8 phase;
        uint256 chainId;
    }

    struct DWrap {
        address addr;
        address underlying;
        string symbol;
        uint256 price;
        uint8 decimals;
        uint256 amount;
        uint256 nativeAmount;
        uint256 val;
        uint256 nativeVal;
    }

    function getTradeFees(
        address _assetIn,
        address _assetOut
    ) external view returns (uint256 feePercentage, uint256 depositorFee, uint256 protocolFee);

    function previewWithdraw(PreviewWithdrawArgs calldata args) external payable returns (uint256 withdrawAmount, uint256 fee);

    function getGlobals(PythView calldata prices) external view returns (DGlobal memory, DWrap[] memory wraps);

    function getExternalTokens(
        ExternalTokenArgs[] memory tokens,
        address _account
    ) external view returns (DVTokenBalance[] memory);

    function getAccount(PythView calldata prices, address _account) external view returns (DAccount memory);

    function getVault() external view returns (DVault memory);

    function getVAssets() external view returns (DVAsset[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {PercentageMath} from "libs/PercentageMath.sol";
import {cs, gm} from "common/State.sol";
import {scdp, sdi, SDIState} from "scdp/SState.sol";
import {View} from "periphery/ViewTypes.sol";
import {isSequencerUp} from "common/funcs/Utils.sol";
import {Asset, RawPrice} from "common/Types.sol";
import {IERC20} from "kresko-lib/token/IERC20.sol";
import {pushPrice, viewPrice} from "common/funcs/Prices.sol";
import {WadRay} from "libs/WadRay.sol";
import {MinterState, ms} from "minter/MState.sol";
import {Arrays} from "libs/Arrays.sol";
import {IAggregatorV3} from "kresko-lib/vendor/IAggregatorV3.sol";
import {IKreskoAsset} from "kresko-asset/IKreskoAsset.sol";
import {ViewHelpers} from "periphery/ViewHelpers.sol";
import {fromWad, toWad, wadUSD} from "common/funcs/Math.sol";
import {Percents} from "common/Constants.sol";
import {PythView} from "vendor/pyth/PythScript.sol";

// solhint-disable code-complexity

library ViewFuncs {
    using PercentageMath for *;
    using ViewHelpers for Asset;
    using ViewHelpers for MinterState;
    using WadRay for uint256;
    using Arrays for address[];

    function includes(address[] memory _elements, address _elementToFind) internal pure returns (bool) {
        for (uint256 i; i < _elements.length; ) {
            if (_elements[i] == _elementToFind) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    function getAllAssets() internal view returns (address[] memory result) {
        address[] memory mCollaterals = ms().collaterals;
        address[] memory mkrAssets = ms().krAssets;
        address[] memory sAssets = scdp().collaterals;

        address[] memory all = new address[](mCollaterals.length + mkrAssets.length + sAssets.length);

        uint256 uniques;

        for (uint256 i; i < mCollaterals.length; i++) {
            if (!includes(all, mCollaterals[i])) {
                all[uniques] = mCollaterals[i];
                uniques++;
            }
        }

        for (uint256 i; i < mkrAssets.length; i++) {
            if (!includes(all, mkrAssets[i])) {
                all[uniques] = mkrAssets[i];
                uniques++;
            }
        }

        for (uint256 i; i < sAssets.length; i++) {
            if (!includes(all, sAssets[i])) {
                all[uniques] = sAssets[i];
                uniques++;
            }
        }

        result = new address[](uniques);

        for (uint256 i; i < uniques; i++) {
            result[i] = all[i];
        }
    }

    function viewProtocol(PythView calldata prices) internal view returns (View.Protocol memory result) {
        result.assets = viewAssets(prices);
        result.minter = viewMinter();
        result.scdp = viewSCDP(prices);
        result.maxPriceDeviationPct = cs().maxPriceDeviationPct;
        result.oracleDecimals = cs().oracleDecimals;
        result.pythEp = cs().pythEp;
        result.safetyStateSet = cs().safetyStateSet;
        result.sequencerGracePeriodTime = cs().sequencerGracePeriodTime;
        result.isSequencerUp = isSequencerUp(cs().sequencerUptimeFeed, cs().sequencerGracePeriodTime);
        (, , uint256 startedAt, , ) = IAggregatorV3(cs().sequencerUptimeFeed).latestRoundData();
        result.sequencerStartedAt = uint32(startedAt);
        result.timestamp = uint32(block.timestamp);
        result.blockNr = uint32(block.number);
        result.gate = viewGate();
        result.tvl = viewTVL(prices);
    }

    function viewTVL(PythView calldata prices) internal view returns (uint256 result) {
        address[] memory assets = getAllAssets();
        for (uint256 i; i < assets.length; i++) {
            Asset storage asset = cs().assets[assets[i]];
            result += toWad(IERC20(assets[i]).balanceOf(address(this)), asset.decimals).wadMul(asset.getViewPrice(prices));
        }
    }

    function viewGate() internal view returns (View.Gate memory result) {
        if (address(gm().manager) == address(0)) {
            return result;
        }
        result.kreskian = address(gm().manager.kreskian());
        result.questForKresk = address(gm().manager.questForKresk());
        result.phase = gm().manager.phase();
    }

    function viewMinter() internal view returns (View.Minter memory result) {
        result.LT = ms().liquidationThreshold;
        result.MCR = ms().minCollateralRatio;
        result.MLR = ms().maxLiquidationRatio;
        result.minDebtValue = ms().minDebtValue;
    }

    function viewAccount(PythView calldata prices, address _account) internal view returns (View.Account memory result) {
        result.addr = _account;
        result.bals = viewBalances(prices, _account);
        result.minter = viewMAccount(prices, _account);
        result.scdp = viewSAccount(prices, _account, viewSDepositAssets());
    }

    function viewSCDP(PythView calldata prices) internal view returns (View.SCDP memory result) {
        result.LT = scdp().liquidationThreshold;
        result.MCR = scdp().minCollateralRatio;
        result.MLR = scdp().maxLiquidationRatio;
        result.coverIncentive = uint32(sdi().coverIncentive);
        result.coverThreshold = uint32(sdi().coverThreshold);

        (result.totals, result.deposits) = viewSData(prices);
        result.debts = viewSDebts(prices);
    }

    function viewSDebts(PythView calldata prices) internal view returns (View.Position[] memory results) {
        address[] memory krAssets = scdp().krAssets;
        results = new View.Position[](krAssets.length);

        for (uint256 i; i < krAssets.length; i++) {
            address addr = krAssets[i];

            View.AssetData memory data = viewSAssetData(prices, addr);

            results[i] = View.Position({
                addr: addr,
                symbol: _symbol(addr),
                amount: data.amountDebt,
                amountAdj: data.amountDebt,
                val: data.valDebt,
                valAdj: data.valDebtAdj,
                price: data.price,
                index: -1,
                config: data.config
            });
        }
    }

    function viewSData(
        PythView calldata prices
    ) internal view returns (View.STotals memory totals, View.SDeposit[] memory results) {
        address[] memory collaterals = scdp().collaterals;
        results = new View.SDeposit[](collaterals.length);

        for (uint256 i; i < collaterals.length; i++) {
            address assetAddr = collaterals[i];

            View.AssetData memory data = viewSAssetData(prices, assetAddr);
            totals.valFees += data.valCollFees;
            totals.valColl += data.valColl;
            totals.valCollAdj += data.valCollAdj;
            totals.valDebtOg += data.valDebt;
            totals.valDebtOgAdj += data.valDebtAdj;
            totals.sdiPrice = viewSDIPrice(prices);
            results[i] = View.SDeposit({
                addr: assetAddr,
                liqIndex: scdp().assetIndexes[assetAddr].currLiqIndex,
                feeIndex: scdp().assetIndexes[assetAddr].currFeeIndex,
                symbol: _symbol(assetAddr),
                config: data.config,
                price: data.price,
                amount: data.amountColl,
                amountFees: data.amountCollFees,
                amountSwapDeposit: data.amountSwapDeposit,
                val: data.valColl,
                valAdj: data.valCollAdj,
                valFees: data.valCollFees
            });
        }

        totals.valDebt = viewEffectiveDebtValue(sdi(), prices);
        if (totals.valColl == 0) {
            totals.cr = 0;
            totals.crOg = 0;
            totals.crOgAdj = 0;
        } else if (totals.valDebt == 0) {
            totals.cr = type(uint256).max;
            totals.crOg = type(uint256).max;
            totals.crOgAdj = type(uint256).max;
        } else {
            totals.cr = totals.valColl.percentDiv(totals.valDebt);
            totals.crOg = totals.valColl.percentDiv(totals.valDebtOg);
            totals.crOgAdj = totals.valCollAdj.percentDiv(totals.valDebtOgAdj);
        }
    }

    function viewBalances(PythView calldata prices, address _account) internal view returns (View.Balance[] memory result) {
        address[] memory allAssets = getAllAssets();
        result = new View.Balance[](allAssets.length);
        for (uint256 i; i < allAssets.length; i++) {
            result[i] = viewBalance(prices, _account, allAssets[i]);
        }
    }

    function viewAsset(PythView calldata prices, address addr) internal view returns (View.AssetView memory) {
        Asset storage asset = cs().assets[addr];
        IERC20 token = IERC20(addr);
        RawPrice memory price = prices.ids.length > 0
            ? viewPrice(asset.ticker, prices)
            : pushPrice(asset.oracles, asset.ticker);
        string memory symbol = _symbol(address(token));

        IKreskoAsset.Wrapping memory synthwrap;
        if (asset.kFactor > 0 && bytes32(bytes(symbol)) != bytes32("KISS")) {
            synthwrap = IKreskoAsset(addr).wrappingInfo();
        }
        return
            View.AssetView({
                addr: addr,
                symbol: symbol,
                synthwrap: synthwrap,
                name: token.name(),
                tSupply: token.totalSupply(),
                mSupply: asset.isMinterMintable ? asset.getMinterSupply(addr) : 0,
                price: uint256(price.answer),
                isMarketOpen: asset.isMarketOpen(),
                priceRaw: price,
                config: asset
            });
    }

    function viewAssets(PythView calldata prices) internal view returns (View.AssetView[] memory result) {
        address[] memory mCollaterals = ms().collaterals;
        address[] memory mkrAssets = ms().krAssets;
        address[] memory sAssets = scdp().collaterals;

        address[] memory all = new address[](mCollaterals.length + mkrAssets.length + sAssets.length);

        uint256 uniques;

        for (uint256 i; i < mCollaterals.length; i++) {
            if (!includes(all, mCollaterals[i])) {
                all[uniques] = mCollaterals[i];
                uniques++;
            }
        }

        for (uint256 i; i < mkrAssets.length; i++) {
            if (!includes(all, mkrAssets[i])) {
                all[uniques] = mkrAssets[i];
                uniques++;
            }
        }

        for (uint256 i; i < sAssets.length; i++) {
            if (!includes(all, sAssets[i])) {
                all[uniques] = sAssets[i];
                uniques++;
            }
        }

        result = new View.AssetView[](uniques);

        for (uint256 i; i < uniques; i++) {
            result[i] = viewAsset(prices, all[i]);
        }
    }

    function viewBalance(
        PythView calldata prices,
        address _account,
        address _assetAddr
    ) internal view returns (View.Balance memory result) {
        IERC20 token = IERC20(_assetAddr);
        Asset storage asset = cs().assets[_assetAddr];
        result.addr = _account;
        result.amount = token.balanceOf(_account);
        result.val = asset.exists() ? asset.viewCollateralAmountToValue(asset.getViewPrice(prices), result.amount, true) : 0;
        result.token = _assetAddr;
        result.name = token.name();
        result.decimals = token.decimals();
        result.symbol = _symbol(address(token));
    }

    function viewSDepositAssets() internal view returns (address[] memory result) {
        address[] memory depositAssets = scdp().collaterals;
        address[] memory assets = new address[](depositAssets.length);

        uint256 length;

        for (uint256 i; i < depositAssets.length; ) {
            if (cs().assets[depositAssets[i]].isSharedCollateral) {
                assets[length++] = depositAssets[i];
            }
            unchecked {
                i++;
            }
        }

        result = new address[](length);
        for (uint256 i; i < length; ) {
            result[i] = assets[i];
            unchecked {
                i++;
            }
        }
    }

    function viewSAssetData(PythView calldata prices, address _assetAddr) internal view returns (View.AssetData memory result) {
        Asset storage asset = cs().assets[_assetAddr];
        result.addr = _assetAddr;
        result.config = asset;
        result.price = asset.getViewPrice(prices);
        result.symbol = _symbol(_assetAddr);

        bool isSwapMintable = asset.isSwapMintable;
        bool isSCDPAsset = asset.isSharedOrSwappedCollateral;
        result.amountColl = isSCDPAsset ? scdp().totalDepositAmount(_assetAddr, asset) : 0;
        result.amountDebt = isSwapMintable ? asset.toRebasingAmount(scdp().assetData[_assetAddr].debt) : 0;

        uint256 feeIndex = scdp().assetIndexes[_assetAddr].currFeeIndex;
        result.amountCollFees = feeIndex > 0 ? result.amountColl.wadToRay().rayMul(feeIndex).rayToWad() : 0;
        {
            (result.valDebt, result.valDebtAdj) = isSwapMintable
                ? asset.viewDebtAmountToValues(result.price, result.amountDebt)
                : (0, 0);

            (result.valColl, result.valCollAdj) = isSCDPAsset
                ? asset.viewCollateralAmountToValues(result.price, result.amountColl)
                : (0, 0);

            result.valCollFees = feeIndex > 0 ? result.valColl.wadToRay().rayMul(feeIndex).rayToWad() : 0;
        }
        result.amountSwapDeposit = isSwapMintable ? scdp().swapDepositAmount(_assetAddr, asset) : 0;
    }

    function viewMAssetData(
        PythView calldata prices,
        address _account,
        address _assetAddr
    ) internal view returns (View.AssetData memory result) {
        Asset storage asset = cs().assets[_assetAddr];
        result.addr = _assetAddr;
        result.config = asset;
        result.symbol = _symbol(_assetAddr);
        result.price = asset.getViewPrice(prices);

        bool isMinterCollateral = asset.isMinterCollateral;
        bool isMinterMintable = asset.isMinterMintable;

        result.amountColl = isMinterCollateral ? ms().accountCollateralAmount(_account, _assetAddr, asset) : 0;
        result.amountDebt = isMinterMintable ? ms().accountDebtAmount(_account, _assetAddr, asset) : 0;

        (result.valDebt, result.valDebtAdj) = isMinterMintable
            ? asset.viewDebtAmountToValues(result.price, result.amountDebt)
            : (0, 0);

        (result.valColl, result.valCollAdj) = isMinterCollateral
            ? asset.viewCollateralAmountToValues(result.price, result.amountColl)
            : (0, 0);
    }

    function viewMAccount(PythView calldata prices, address _account) internal view returns (View.MAccount memory result) {
        result.totals.valColl = ms().viewAccountTotalCollateralValue(prices, _account);
        result.totals.valDebt = ms().viewAccountTotalDebtValue(prices, _account);
        if (result.totals.valColl == 0) {
            result.totals.cr = 0;
        } else if (result.totals.valDebt == 0) {
            result.totals.cr = type(uint256).max;
        } else {
            result.totals.cr = result.totals.valColl.percentDiv(result.totals.valDebt);
        }
        result.deposits = viewMDeposits(prices, _account);
        result.debts = viewMDebts(prices, _account);
    }

    function viewMDeposits(PythView calldata prices, address _account) internal view returns (View.Position[] memory result) {
        address[] memory colls = ms().collaterals;
        result = new View.Position[](colls.length);

        for (uint256 i; i < colls.length; i++) {
            address addr = colls[i];
            View.AssetData memory data = viewMAssetData(prices, _account, addr);
            Arrays.FindResult memory findResult = ms().depositedCollateralAssets[_account].find(addr);
            result[i] = View.Position({
                addr: addr,
                symbol: _symbol(addr),
                amount: data.amountColl,
                amountAdj: 0,
                val: data.valColl,
                valAdj: data.valCollAdj,
                price: data.price,
                index: findResult.exists ? int256(findResult.index) : -1,
                config: data.config
            });
        }
    }

    function viewMDebts(PythView calldata prices, address _account) internal view returns (View.Position[] memory result) {
        address[] memory krAssets = ms().krAssets;
        result = new View.Position[](krAssets.length);

        for (uint256 i; i < krAssets.length; i++) {
            address addr = krAssets[i];
            View.AssetData memory data = viewMAssetData(prices, _account, addr);
            Arrays.FindResult memory findResult = ms().mintedKreskoAssets[_account].find(addr);
            result[i] = View.Position({
                addr: addr,
                symbol: _symbol(addr),
                amount: data.amountDebt,
                amountAdj: 0,
                val: data.valDebt,
                valAdj: data.valDebtAdj,
                price: data.price,
                index: findResult.exists ? int256(findResult.index) : -1,
                config: data.config
            });
        }
    }

    function viewSAccount(
        PythView calldata prices,
        address _account,
        address[] memory _assets
    ) internal view returns (View.SAccount memory result) {
        result.addr = _account;
        (result.totals.valColl, result.totals.valFees, result.deposits) = viewSAccountTotals(prices, _account, _assets);
    }

    function viewSAccountTotals(
        PythView calldata prices,
        address _account,
        address[] memory _assets
    ) internal view returns (uint256 totalVal, uint256 totalValFees, View.SDepositUser[] memory datas) {
        address[] memory assets = scdp().collaterals;
        datas = new View.SDepositUser[](_assets.length);

        for (uint256 i; i < assets.length; ) {
            address asset = assets[i];
            View.SDepositUser memory assetData = viewSAccountDeposit(prices, _account, asset);

            totalVal += assetData.val;
            totalValFees += assetData.valFees;

            for (uint256 j; j < _assets.length; ) {
                if (asset == _assets[j]) {
                    datas[j] = assetData;
                }
                unchecked {
                    j++;
                }
            }

            unchecked {
                i++;
            }
        }
    }

    function viewSAccountDeposit(
        PythView calldata prices,
        address _account,
        address _assetAddr
    ) internal view returns (View.SDepositUser memory result) {
        Asset storage asset = cs().assets[_assetAddr];

        result.price = asset.getViewPrice(prices);
        result.config = asset;

        result.amount = scdp().accountDeposits(_account, _assetAddr, asset);
        result.amountFees = scdp().accountFees(_account, _assetAddr, asset);
        result.val = asset.viewCollateralAmountToValue(result.price, result.amount, true);
        result.valFees = asset.viewCollateralAmountToValue(result.price, result.amountFees, true);

        result.symbol = _symbol(_assetAddr);
        result.addr = _assetAddr;
        result.liqIndexAccount = scdp().accountIndexes[_account][_assetAddr].lastLiqIndex;
        result.feeIndexAccount = scdp().accountIndexes[_account][_assetAddr].lastFeeIndex;
        result.accountIndexTimestamp = scdp().accountIndexes[_account][_assetAddr].timestamp;
        result.liqIndexCurrent = scdp().assetIndexes[_assetAddr].currLiqIndex;
        result.feeIndexCurrent = scdp().assetIndexes[_assetAddr].currFeeIndex;
    }

    function viewPhaseEligibility(address _account) internal view returns (uint8 phase, bool isEligible) {
        if (address(gm().manager) == address(0)) {
            return (0, true);
        }
        phase = gm().manager.phase();
        isEligible = gm().manager.isEligible(_account);
    }

    function _symbol(address _assetAddr) internal view returns (string memory) {
        return _assetAddr == 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8 ? "USDC.e" : IERC20(_assetAddr).symbol();
    }

    /// @notice Returns the total effective debt value of the SCDP.
    /// @notice Calculation is done in wad precision but returned as oracle precision.
    function viewEffectiveDebtValue(SDIState storage self, PythView calldata prices) internal view returns (uint256 result) {
        uint256 sdiPrice = viewSDIPrice(prices);
        uint256 coverValue = viewTotalCoverValue(prices);
        uint256 coverAmount = coverValue != 0 ? coverValue.wadDiv(sdiPrice) : 0;
        uint256 totalDebt = self.totalDebt;

        if (coverAmount >= totalDebt) return 0;

        if (coverValue == 0) {
            result = totalDebt;
        } else {
            result = (totalDebt - coverAmount);
        }

        return fromWad(result.wadMul(sdiPrice), cs().oracleDecimals);
    }

    /// @notice Get the price of SDI in USD (WAD precision, so 18 decimals).
    function viewSDIPrice(PythView calldata prices) internal view returns (uint256) {
        uint256 totalValue = viewTotalDebtValueAtRatioSCDP(prices, Percents.HUNDRED, false);
        if (totalValue == 0) {
            return 1e18;
        }
        return toWad(totalValue, cs().oracleDecimals).wadDiv(sdi().totalDebt);
    }

    /**
     * @notice Returns the value of the krAsset held in the pool at a ratio.
     * @param _ratio Percentage ratio to apply for the value in 1e4 percentage precision (uint32).
     * @param _ignorekFactor Whether to ignore kFactor
     * @return totalValue Total value in USD
     */
    function viewTotalDebtValueAtRatioSCDP(
        PythView calldata prices,
        uint32 _ratio,
        bool _ignorekFactor
    ) internal view returns (uint256 totalValue) {
        address[] memory assets = scdp().krAssets;
        for (uint256 i; i < assets.length; ) {
            Asset storage asset = cs().assets[assets[i]];
            uint256 debtAmount = asset.toRebasingAmount(scdp().assetData[assets[i]].debt);
            unchecked {
                if (debtAmount != 0) {
                    totalValue += asset.viewDebtAmountToValue(debtAmount, asset.getViewPrice(prices), _ignorekFactor);
                }
                i++;
            }
        }

        // Multiply if needed
        if (_ratio != Percents.HUNDRED) {
            totalValue = totalValue.percentMul(_ratio);
        }
    }

    function viewTotalCoverValue(PythView calldata prices) internal view returns (uint256 result) {
        address[] memory assets = sdi().coverAssets;
        for (uint256 i; i < assets.length; ) {
            unchecked {
                result += viewCoverAssetValue(prices, assets[i]);
                i++;
            }
        }
    }

    /// @notice Get total deposit value of `asset` in USD, wad precision.
    function viewCoverAssetValue(PythView calldata prices, address _assetAddr) internal view returns (uint256) {
        uint256 bal = IERC20(_assetAddr).balanceOf(sdi().coverRecipient);
        if (bal == 0) return 0;

        Asset storage asset = cs().assets[_assetAddr];
        if (!asset.isCoverAsset) return 0;

        return wadUSD(bal, asset.decimals, asset.getViewPrice(prices), cs().oracleDecimals);
    }
}

// solhint-disable state-visibility, max-states-count, var-name-mixedcase, no-global-import, const-name-snakecase, no-empty-blocks, no-console, code-complexity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Asset, RawPrice} from "common/Types.sol";
import {IKreskoAsset} from "kresko-asset/IKreskoAsset.sol";

library View {
    struct AssetData {
        uint256 amountColl;
        address addr;
        string symbol;
        uint256 amountCollFees;
        uint256 valColl;
        uint256 valCollAdj;
        uint256 valCollFees;
        uint256 amountDebt;
        uint256 valDebt;
        uint256 valDebtAdj;
        uint256 amountSwapDeposit;
        uint256 price;
        Asset config;
    }

    struct STotals {
        uint256 valColl;
        uint256 valCollAdj;
        uint256 valFees;
        uint256 valDebt;
        uint256 valDebtOg;
        uint256 valDebtOgAdj;
        uint256 sdiPrice;
        uint256 cr;
        uint256 crOg;
        uint256 crOgAdj;
    }

    struct Protocol {
        SCDP scdp;
        Gate gate;
        Minter minter;
        AssetView[] assets;
        uint32 sequencerGracePeriodTime;
        address pythEp;
        uint32 maxPriceDeviationPct;
        uint8 oracleDecimals;
        uint32 sequencerStartedAt;
        bool safetyStateSet;
        bool isSequencerUp;
        uint32 timestamp;
        uint256 blockNr;
        uint256 tvl;
    }

    struct Account {
        address addr;
        Balance[] bals;
        MAccount minter;
        SAccount scdp;
    }

    struct Balance {
        address addr;
        string name;
        address token;
        string symbol;
        uint256 amount;
        uint256 val;
        uint8 decimals;
    }

    struct Minter {
        uint32 MCR;
        uint32 LT;
        uint32 MLR;
        uint256 minDebtValue;
    }

    struct SCDP {
        uint32 MCR;
        uint32 LT;
        uint32 MLR;
        SDeposit[] deposits;
        Position[] debts;
        STotals totals;
        uint32 coverIncentive;
        uint32 coverThreshold;
    }

    struct Gate {
        address kreskian;
        address questForKresk;
        uint256 phase;
    }

    struct Synthwrap {
        address token;
        uint256 openFee;
        uint256 closeFee;
    }

    struct AssetView {
        IKreskoAsset.Wrapping synthwrap;
        RawPrice priceRaw;
        string name;
        string symbol;
        address addr;
        bool isMarketOpen;
        uint256 tSupply;
        uint256 mSupply;
        uint256 price;
        Asset config;
    }

    struct MAccount {
        MTotals totals;
        Position[] deposits;
        Position[] debts;
    }

    struct MTotals {
        uint256 valColl;
        uint256 valDebt;
        uint256 cr;
    }

    struct SAccountTotals {
        uint256 valColl;
        uint256 valFees;
    }

    struct SAccount {
        address addr;
        SAccountTotals totals;
        SDepositUser[] deposits;
    }

    struct SDeposit {
        uint256 amount;
        address addr;
        string symbol;
        uint256 amountSwapDeposit;
        uint256 amountFees;
        uint256 val;
        uint256 valAdj;
        uint256 valFees;
        uint256 feeIndex;
        uint256 liqIndex;
        uint256 price;
        Asset config;
    }

    struct SDepositUser {
        uint256 amount;
        address addr;
        string symbol;
        uint256 amountFees;
        uint256 val;
        uint256 feeIndexAccount;
        uint256 feeIndexCurrent;
        uint256 liqIndexAccount;
        uint256 liqIndexCurrent;
        uint256 accountIndexTimestamp;
        uint256 valFees;
        uint256 price;
        Asset config;
    }

    struct Position {
        uint256 amount;
        address addr;
        string symbol;
        uint256 amountAdj;
        uint256 val;
        uint256 valAdj;
        int256 index;
        uint256 price;
        Asset config;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {View} from "periphery/ViewTypes.sol";
import {PythView} from "vendor/pyth/PythScript.sol";

interface IViewDataFacet {
    function viewProtocolData(PythView calldata prices) external view returns (View.Protocol memory);

    function viewAccountData(PythView calldata prices, address account) external view returns (View.Account memory);

    function viewMinterAccounts(
        PythView calldata prices,
        address[] memory accounts
    ) external view returns (View.MAccount[] memory);

    function viewSCDPAccount(PythView calldata prices, address account) external view returns (View.SAccount memory);

    function viewSCDPDepositAssets() external view returns (address[] memory);

    function viewTokenBalances(
        PythView calldata prices,
        address account,
        address[] memory tokens
    ) external view returns (View.Balance[] memory result);

    function viewAccountGatingPhase(address account) external view returns (uint8 phase, bool eligibleForCurrentPhase);

    function viewSCDPAccounts(
        PythView calldata prices,
        address[] memory accounts,
        address[] memory assets
    ) external view returns (View.SAccount[] memory);

    function viewSCDPAssets(PythView calldata prices, address[] memory assets) external view returns (View.AssetData[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function WETH9() external view returns (address);

    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    )
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    function quoteExactOutput(
        bytes memory path,
        uint256 amountOut
    )
        external
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    function exactInput(ExactInputParams calldata params) external returns (uint256 amountOut);

    function exactOutput(ExactOutputParams calldata params) external returns (uint256 amountIn);
}

interface IKrMulticall {
    function rescue(address _token, uint256 _amount, address _receiver) external;

    function execute(Operation[] calldata ops, bytes[] calldata _updateData) external payable returns (Result[] memory);

    /**
     * @notice An operation to execute.
     * @param action The operation to execute.
     * @param data The data for the operation.
     */
    struct Operation {
        Action action;
        Data data;
    }

    /**
     * @notice Data for an operation.
     * @param tokenIn The tokenIn to use, or address(0) if none.
     * @param amountIn The amount of tokenIn to use, or 0 if none.
     * @param tokensInMode The mode for tokensIn.
     * @param tokenOut The tokenOut to use, or address(0) if none.
     * @param amountOut The amount of tokenOut to use, or 0 if none.
     * @param tokensOutMode The mode for tokensOut.
     * @param amountOutMin The minimum amount of tokenOut to receive, or 0 if none.
     * @param index The index of the mintedKreskoAssets array to use, or 0 if none.
     * @param path The path for the Uniswap V3 swap, or empty if none.
     */
    struct Data {
        address tokenIn;
        uint96 amountIn;
        TokensInMode tokensInMode;
        address tokenOut;
        uint96 amountOut;
        TokensOutMode tokensOutMode;
        uint128 amountOutMin;
        uint128 index;
        bytes path;
    }

    /**
     * @notice The result of an operation.
     * @param tokenIn The tokenIn to use.
     * @param amountIn The amount of tokenIn used.
     * @param tokenOut The tokenOut to receive from the operation.
     * @param amountOut The amount of tokenOut received.
     */
    struct Result {
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 amountOut;
    }

    /**
     * @notice The action for an operation.
     */
    enum Action {
        MinterDeposit,
        MinterWithdraw,
        MinterRepay,
        MinterBorrow,
        SCDPDeposit,
        SCDPTrade,
        SCDPWithdraw,
        SCDPClaim,
        SynthUnwrap,
        SynthWrap,
        VaultDeposit,
        VaultRedeem,
        AMMExactInput,
        SynthwrapNative,
        SynthUnwrapNative
    }

    /**
     * @notice The token in mode for an operation.
     * @param None Operation requires no tokens in.
     * @param PullFromSender Operation pulls tokens in from sender.
     * @param UseContractBalance Operation uses the existing contract balance for tokens in.
     * @param UseContractBalanceExactAmountIn Operation uses the existing contract balance for tokens in, but only the amountIn specified.
     */
    enum TokensInMode {
        None,
        Native,
        PullFromSender,
        UseContractBalance,
        UseContractBalanceExactAmountIn,
        UseContractBalanceUnwrapNative,
        UseContractBalanceWrapNative,
        UseContractBalanceNative
    }

    /**
     * @notice The token out mode for an operation.
     * @param None Operation requires no tokens out.
     * @param ReturnToSenderNative Operation will unwrap and transfer native to sender.
     * @param ReturnToSender Operation returns tokens received to sender.
     * @param LeaveInContract Operation leaves tokens received in the contract for later use.
     */
    enum TokensOutMode {
        None,
        ReturnToSenderNative,
        ReturnToSender,
        LeaveInContract
    }

    error NO_ALLOWANCE(Action action, address token, string symbol);
    error ZERO_AMOUNT_IN(Action action, address token, string symbol);
    error ZERO_NATIVE_IN(Action action);
    error VALUE_NOT_ZERO(Action action, uint256 value);
    error INVALID_NATIVE_TOKEN_IN(Action action, address token, string symbol);
    error ZERO_OR_INVALID_AMOUNT_IN(Action action, address token, string symbol, uint256 balance, uint256 amountOut);
    error INVALID_ACTION(Action action);
    error NATIVE_SYNTH_WRAP_NOT_ALLOWED(Action action, address token, string symbol);

    error TOKENS_IN_MODE_WAS_NONE_BUT_ADDRESS_NOT_ZERO(Action action, address token);
    error TOKENS_OUT_MODE_WAS_NONE_BUT_ADDRESS_NOT_ZERO(Action action, address token);

    error INSUFFICIENT_UPDATE_FEE(uint256 updateFee, uint256 amountIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {Asset} from "common/Types.sol";
import {Enums} from "common/Constants.sol";
import {RawPrice} from "common/Types.sol";

interface IAssetStateFacet {
    /**
     * @notice Get the state of a specific asset
     * @param _assetAddr Address of the asset.
     * @return Asset State of asset
     * @custom:signature getAsset(address)
     * @custom:selector 0x30b8b2c6
     */

    function getAsset(address _assetAddr) external view returns (Asset memory);

    /**
     * @notice Get price for an asset from address.
     * @param _assetAddr Asset address.
     * @return uint256 Current price for the asset.
     * @custom:signature getPrice(address)
     * @custom:selector 0x41976e09
     */
    function getPrice(address _assetAddr) external view returns (uint256);

    /**
     * @notice Get push price for an asset from address.
     * @param _assetAddr Asset address.
     * @return RawPrice Current raw price for the asset.
     * @custom:signature getPushPrice(address)
     * @custom:selector 0xc72f3dd7
     */
    function getPushPrice(address _assetAddr) external view returns (RawPrice memory);

    /**
     * @notice Get value for an asset amount using the current price.
     * @param _assetAddr Asset address.
     * @param _amount The amount (uint256).
     * @return uint256 Current value for `_amount` of `_assetAddr`.
     * @custom:signature getValue(address,uint256)
     * @custom:selector 0xc7bf8cf5
     */
    function getValue(address _assetAddr, uint256 _amount) external view returns (uint256);

    /**
     * @notice Gets corresponding feed address for the oracle type and asset address.
     * @param _assetAddr The asset address.
     * @param _oracleType The oracle type.
     * @return feedAddr Feed address that the asset uses with the oracle type.
     */
    function getFeedForAddress(address _assetAddr, Enums.OracleType _oracleType) external view returns (address feedAddr);

    /**
     * @notice Get the market status for an asset.
     * @param _assetAddr Asset address.
     * @return bool True if the market is open, false otherwise.
     * @custom:signature getMarketStatus(address)
     * @custom:selector 0x3b3b3b3b
     */
    function getMarketStatus(address _assetAddr) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {UncheckedWithdrawArgs, WithdrawArgs} from "common/Args.sol";

interface IMinterDepositWithdrawFacet {
    /**
     * @notice Deposits collateral into the protocol.
     * @param _account The user to deposit collateral for.
     * @param _collateralAsset The address of the collateral asset.
     * @param _depositAmount The amount of the collateral asset to deposit.
     */
    function depositCollateral(address _account, address _collateralAsset, uint256 _depositAmount) external payable;

    /**
     * @notice Withdraws sender's collateral from the protocol.
     * @dev Requires that the post-withdrawal collateral value does not violate minimum collateral requirement.
     * @param _args WithdrawArgs
     * @param _updateData Price update data
     * assets array. Only needed if withdrawing the entire deposit of a particular collateral asset.
     */
    function withdrawCollateral(WithdrawArgs memory _args, bytes[] calldata _updateData) external payable;

    /**
     * @notice Withdraws sender's collateral from the protocol before checking minimum collateral ratio.
     * @dev Executes post-withdraw-callback triggering onUncheckedCollateralWithdraw on the caller
     * @dev Requires that the post-withdraw-callback collateral value does not violate minimum collateral requirement.
     * @param _args UncheckedWithdrawArgs
     * @param _updateData Price update data
     * assets array. Only needed if withdrawing the entire deposit of a particular collateral asset.
     */
    function withdrawCollateralUnchecked(UncheckedWithdrawArgs memory _args, bytes[] calldata _updateData) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {MintArgs} from "common/Args.sol";

interface IMinterMintFacet {
    /**
     * @notice Mints new Kresko assets.
     * @param _args MintArgs struct containing the arguments necessary to perform a mint.
     */
    function mintKreskoAsset(MintArgs memory _args, bytes[] calldata _updateData) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {MaxLiqInfo} from "common/Types.sol";
import {SCDPLiquidationArgs, SCDPRepayArgs, SCDPWithdrawArgs} from "common/Args.sol";

interface ISCDPFacet {
    /**
     * @notice Deposit collateral for account to the collateral pool.
     * @param _account The account to deposit for.
     * @param _collateralAsset The collateral asset to deposit.
     * @param _amount The amount to deposit.
     */
    function depositSCDP(address _account, address _collateralAsset, uint256 _amount) external payable;

    /**
     * @notice Withdraw collateral for account from the collateral pool.
     * @param _args WithdrawArgs struct containing withdraw data.
     */
    function withdrawSCDP(SCDPWithdrawArgs memory _args, bytes[] calldata _updateData) external payable;

    /**
     * @notice Withdraw collateral without caring about fees.
     * @param _args WithdrawArgs struct containing withdraw data.
     */
    function emergencyWithdrawSCDP(SCDPWithdrawArgs memory _args, bytes[] calldata _updateData) external payable;

    /**
     * @notice Withdraws any pending fees for an account.
     * @param _account The account to withdraw fees for.
     * @param _collateralAsset The collateral asset to withdraw fees for.
     * @param _receiver Receiver of fees withdrawn, if 0 then the receiver is the account.
     * @return feeAmount The amount of fees withdrawn.
     */
    function claimFeesSCDP(
        address _account,
        address _collateralAsset,
        address _receiver
    ) external payable returns (uint256 feeAmount);

    /**
     * @notice Repay debt for no fees or slippage.
     * @notice Only uses swap deposits, if none available, reverts.
     * @param _args RepayArgs struct containing repay data.
     */
    function repaySCDP(SCDPRepayArgs calldata _args) external payable;

    /**
     * @notice Liquidate the collateral pool.
     * @notice Adjusts everyones deposits if swap deposits do not cover the seized amount.
     * @param _args LiquidationArgs struct containing liquidation data.
     */
    function liquidateSCDP(SCDPLiquidationArgs memory _args, bytes[] calldata _updateData) external payable;

    /**
     * @dev Calculates the total value that is allowed to be liquidated from SCDP (if it is liquidatable)
     * @param _repayAssetAddr Address of Kresko Asset to repay
     * @param _seizeAssetAddr Address of Collateral to seize
     * @return MaxLiqInfo Calculated information about the maximum liquidation.
     */
    function getMaxLiqValueSCDP(address _repayAssetAddr, address _seizeAssetAddr) external view returns (MaxLiqInfo memory);

    function getLiquidatableSCDP() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {SwapArgs} from "common/Args.sol";

interface ISCDPSwapFacet {
    /**
     * @notice Preview the amount out received.
     * @param _assetIn The asset to pay with.
     * @param _assetOut The asset to receive.
     * @param _amountIn The amount of _assetIn to pay
     * @return amountOut The amount of `_assetOut` to receive according to `_amountIn`.
     */
    function previewSwapSCDP(
        address _assetIn,
        address _assetOut,
        uint256 _amountIn
    ) external view returns (uint256 amountOut, uint256 feeAmount, uint256 protocolFee);

    /**
     * @notice Swap kresko assets with KISS using the shared collateral pool.
     * Uses oracle pricing of _amountIn to determine how much _assetOut to send.
     * @param _args SwapArgs struct containing swap data.
     */
    function swapSCDP(SwapArgs calldata _args) external payable;

    /**
     * @notice Accumulates fees to deposits as a fixed, instantaneous income.
     * @param _depositAssetAddr Deposit asset to give income for
     * @param _incomeAmount Amount to accumulate
     * @return nextLiquidityIndex Next liquidity index for the asset.
     */
    function cumulateIncomeSCDP(
        address _depositAssetAddr,
        uint256 _incomeAmount
    ) external payable returns (uint256 nextLiquidityIndex);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {SCDPInitArgs, SwapRouteSetter, SCDPParameters} from "scdp/STypes.sol";

interface ISCDPConfigFacet {
    /**
     * @notice Initialize SCDP.
     * Callable by diamond owner only.
     * @param _init The initial configuration.
     */
    function initializeSCDP(SCDPInitArgs memory _init) external;

    /// @notice Get the pool configuration.
    function getParametersSCDP() external view returns (SCDPParameters memory);

    /**
     * @notice Set the asset to cumulate swap fees into.
     * Only callable by admin.
     * @param _assetAddr Asset that is validated to be a deposit asset.
     */
    function setFeeAssetSCDP(address _assetAddr) external;

    /// @notice Set the minimum collateralization ratio for SCDP.
    function setMinCollateralRatioSCDP(uint32 _newMCR) external;

    /// @notice Set the liquidation threshold for SCDP while updating MLR to one percent above it.
    function setLiquidationThresholdSCDP(uint32 _newLT) external;

    /// @notice Set the max liquidation ratio for SCDP.
    /// @notice MLR is also updated automatically when setLiquidationThresholdSCDP is used.
    function setMaxLiquidationRatioSCDP(uint32 _newMLR) external;

    /// @notice Set the new liquidation incentive for a swappable asset.
    /// @param _assetAddr Asset address
    /// @param _newLiqIncentiveSCDP New liquidation incentive. Bounded to 1e4 <-> 1.25e4.
    function setKrAssetLiqIncentiveSCDP(address _assetAddr, uint16 _newLiqIncentiveSCDP) external;

    /**
     * @notice Update the deposit asset limit configuration.
     * Only callable by admin.
     * emits PoolCollateralUpdated
     * @param _assetAddr The Collateral asset to update
     * @param _newDepositLimitSCDP The new deposit limit for the collateral
     */
    function setDepositLimitSCDP(address _assetAddr, uint256 _newDepositLimitSCDP) external;

    /**
     * @notice Disable or enable a deposit asset. Reverts if invalid asset.
     * Only callable by admin.
     * @param _assetAddr Asset to set.
     * @param _enabled Whether to enable or disable the asset.
     */
    function setAssetIsSharedCollateralSCDP(address _assetAddr, bool _enabled) external;

    /**
     * @notice Disable or enable asset from shared collateral value calculations.
     * Reverts if invalid asset and if disabling asset that has user deposits.
     * Only callable by admin.
     * @param _assetAddr Asset to set.
     * @param _enabled Whether to enable or disable the asset.
     */
    function setAssetIsSharedOrSwappedCollateralSCDP(address _assetAddr, bool _enabled) external;

    /**
     * @notice Disable or enable a kresko asset to be used in swaps.
     * Reverts if invalid asset. Enabling will also add it to collateral value calculations.
     * Only callable by admin.
     * @param _assetAddr Asset to set.
     * @param _enabled Whether to enable or disable the asset.
     */
    function setAssetIsSwapMintableSCDP(address _assetAddr, bool _enabled) external;

    /**
     * @notice Sets the fees for a kresko asset
     * @dev Only callable by admin.
     * @param _assetAddr The kresko asset to set fees for.
     * @param _openFee The new open fee.
     * @param _closeFee The new close fee.
     * @param _protocolFee The protocol fee share.
     */
    function setAssetSwapFeesSCDP(address _assetAddr, uint16 _openFee, uint16 _closeFee, uint16 _protocolFee) external;

    /**
     * @notice Set whether swap routes for pairs are enabled or not. Both ways.
     * Only callable by admin.
     * @param _setters The configurations to set.
     */
    function setSwapRoutesSCDP(SwapRouteSetter[] calldata _setters) external;

    /**
     * @notice Set whether a swap route for a pair is enabled or not.
     * Only callable by admin.
     * @param _setter The configuration to set
     */
    function setSingleSwapRouteSCDP(SwapRouteSetter calldata _setter) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {SCDPAssetIndexes} from "scdp/STypes.sol";

interface ISCDPStateFacet {
    /**
     * @notice Get the total collateral principal deposits for `_account`
     * @param _account The account.
     * @param _depositAsset The deposit asset
     */
    function getAccountDepositSCDP(address _account, address _depositAsset) external view returns (uint256);

    /**
     * @notice Get the fees of `depositAsset` for `_account`
     * @param _account The account.
     * @param _depositAsset The deposit asset
     */
    function getAccountFeesSCDP(address _account, address _depositAsset) external view returns (uint256);

    /**
     * @notice Get the value of fees for `_account`
     * @param _account The account.
     */
    function getAccountTotalFeesValueSCDP(address _account) external view returns (uint256);

    /**
     * @notice Get the (principal) deposit value for `_account`
     * @param _account The account.
     * @param _depositAsset The deposit asset
     */
    function getAccountDepositValueSCDP(address _account, address _depositAsset) external view returns (uint256);

    function getAssetIndexesSCDP(address _assetAddr) external view returns (SCDPAssetIndexes memory);

    /**
     * @notice Get the total collateral deposit value for `_account`
     * @param _account The account.
     */
    function getAccountTotalDepositsValueSCDP(address _account) external view returns (uint256);

    /**
     * @notice Get the total collateral deposits for `_collateralAsset`
     * @param _collateralAsset The collateral asset
     */
    function getDepositsSCDP(address _collateralAsset) external view returns (uint256);

    /**
     * @notice Get the total collateral swap deposits for `_collateralAsset`
     * @param _collateralAsset The collateral asset
     */
    function getSwapDepositsSCDP(address _collateralAsset) external view returns (uint256);

    /**
     * @notice Get the total collateral deposit value for `_collateralAsset`
     * @param _depositAsset The collateral asset
     * @param _ignoreFactors Ignore factors when calculating collateral and debt value.
     */
    function getCollateralValueSCDP(address _depositAsset, bool _ignoreFactors) external view returns (uint256);

    /**
     * @notice Get the total collateral value, oracle precision
     * @param _ignoreFactors Ignore factors when calculating collateral value.
     */
    function getTotalCollateralValueSCDP(bool _ignoreFactors) external view returns (uint256);

    /**
     * @notice Get all pool collateral assets
     */
    function getCollateralsSCDP() external view returns (address[] memory);

    /**
     * @notice Get all pool KreskoAssets
     */
    function getKreskoAssetsSCDP() external view returns (address[] memory);

    /**
     * @notice Get the collateral debt amount for `_krAsset`
     * @param _krAsset The KreskoAsset
     */
    function getDebtSCDP(address _krAsset) external view returns (uint256);

    /**
     * @notice Get the debt value for `_krAsset`
     * @param _krAsset The KreskoAsset
     * @param _ignoreFactors Ignore factors when calculating collateral and debt value.
     */
    function getDebtValueSCDP(address _krAsset, bool _ignoreFactors) external view returns (uint256);

    /**
     * @notice Get the total debt value of krAssets in oracle precision
     * @param _ignoreFactors Ignore factors when calculating debt value.
     */
    function getTotalDebtValueSCDP(bool _ignoreFactors) external view returns (uint256);

    /**
     * @notice Get enabled state of asset
     */
    function getAssetEnabledSCDP(address _assetAddr) external view returns (bool);

    /**
     * @notice Get whether swap is enabled from `_assetIn` to `_assetOut`
     * @param _assetIn The asset to swap from
     * @param _assetOut The asset to swap to
     */
    function getSwapEnabledSCDP(address _assetIn, address _assetOut) external view returns (bool);

    function getCollateralRatioSCDP() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISDIFacet {
    /// @notice Get the total debt of the SCDP.
    function getTotalSDIDebt() external view returns (uint256);

    /// @notice Get the effective debt value of the SCDP.
    function getEffectiveSDIDebtUSD() external view returns (uint256);

    /// @notice Get the effective debt amount of the SCDP.
    function getEffectiveSDIDebt() external view returns (uint256);

    /// @notice Get the total normalized amount of cover.
    function getSDICoverAmount() external view returns (uint256);

    function previewSCDPBurn(
        address _assetAddr,
        uint256 _burnAmount,
        bool _ignoreFactors
    ) external view returns (uint256 shares);

    function previewSCDPMint(
        address _assetAddr,
        uint256 _mintAmount,
        bool _ignoreFactors
    ) external view returns (uint256 shares);

    /// @notice Simply returns the total supply of SDI.
    function totalSDI() external view returns (uint256);

    /// @notice Get the price of SDI in USD, oracle precision.
    function getSDIPrice() external view returns (uint256);

    /// @notice Cover debt by providing collateral without getting anything in return.
    function coverSCDP(
        address _assetAddr,
        uint256 _coverAmount,
        bytes[] calldata _updateData
    ) external payable returns (uint256 value);

    /// @notice Cover debt by providing collateral, receiving small incentive in return.
    function coverWithIncentiveSCDP(
        address _assetAddr,
        uint256 _coverAmount,
        address _seizeAssetAddr,
        bytes[] calldata _updateData
    ) external payable returns (uint256 value, uint256 seizedAmount);

    /// @notice Enable a cover asset to be used.
    function enableCoverAssetSDI(address _assetAddr) external;

    /// @notice Disable a cover asset to be used.
    function disableCoverAssetSDI(address _assetAddr) external;

    /// @notice Set the contract holding cover assets.
    function setCoverRecipientSDI(address _coverRecipient) external;

    /// @notice Get all accepted cover assets.
    function getCoverAssetsSDI() external view returns (address[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {MinterInitArgs} from "minter/MTypes.sol";

interface IMinterConfigFacet {
    function initializeMinter(MinterInitArgs calldata args) external;

    /**
     * @dev Updates the contract's minimum debt value.
     * @param _newMinDebtValue The new minimum debt value as a wad.
     */
    function setMinDebtValueMinter(uint256 _newMinDebtValue) external;

    /**
     * @notice Updates the liquidation incentive multiplier.
     * @param _collateralAsset The collateral asset to update.
     * @param _newLiquidationIncentive The new liquidation incentive multiplier for the asset.
     */
    function setCollateralLiquidationIncentiveMinter(address _collateralAsset, uint16 _newLiquidationIncentive) external;

    /**
     * @dev Updates the contract's collateralization ratio.
     * @param _newMinCollateralRatio The new minimum collateralization ratio as wad.
     */
    function setMinCollateralRatioMinter(uint32 _newMinCollateralRatio) external;

    /**
     * @dev Updates the contract's liquidation threshold value
     * @param _newThreshold The new liquidation threshold value
     */
    function setLiquidationThresholdMinter(uint32 _newThreshold) external;

    /**
     * @notice Updates the max liquidation ratior value.
     * @notice This is the maximum collateral ratio that liquidations can liquidate to.
     * @param _newMaxLiquidationRatio Percent value in wad precision.
     */
    function setMaxLiquidationRatioMinter(uint32 _newMaxLiquidationRatio) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {MinterParams} from "minter/MTypes.sol";

interface IMinterStateFacet {
    /// @notice The collateralization ratio at which positions may be liquidated.
    function getLiquidationThresholdMinter() external view returns (uint32);

    /// @notice Multiplies max liquidation multiplier, if a full liquidation happens this is the resulting CR.
    function getMaxLiquidationRatioMinter() external view returns (uint32);

    /// @notice The minimum USD value of an individual synthetic asset debt position.
    function getMinDebtValueMinter() external view returns (uint256);

    /// @notice The minimum ratio of collateral to debt that can be taken by direct action.
    function getMinCollateralRatioMinter() external view returns (uint32);

    /// @notice simple check if kresko asset exists
    function getKrAssetExists(address _krAsset) external view returns (bool);

    /// @notice simple check if collateral asset exists
    function getCollateralExists(address _collateralAsset) external view returns (bool);

    /// @notice get all meaningful protocol parameters
    function getParametersMinter() external view returns (MinterParams memory);

    /// @notice Gets the supply originating from the Minter for @param _asset.
    function getMinterSupply(address _asset) external view returns (uint256);

    /**
     * @notice Gets the USD value for a single collateral asset and amount.
     * @param _collateralAsset The address of the collateral asset.
     * @param _amount The amount of the collateral asset to calculate the value for.
     * @return value The unadjusted value for the provided amount of the collateral asset.
     * @return adjustedValue The (cFactor) adjusted value for the provided amount of the collateral asset.
     * @return price The price of the collateral asset.
     */
    function getCollateralValueWithPrice(
        address _collateralAsset,
        uint256 _amount
    ) external view returns (uint256 value, uint256 adjustedValue, uint256 price);

    /**
     * @notice Gets the USD value for a single Kresko asset and amount.
     * @param _krAsset The address of the Kresko asset.
     * @param _amount The amount of the Kresko asset to calculate the value for.
     * @return value The unadjusted value for the provided amount of the debt asset.
     * @return adjustedValue The (kFactor) adjusted value for the provided amount of the debt asset.
     * @return price The price of the debt asset.
     */
    function getDebtValueWithPrice(
        address _krAsset,
        uint256 _amount
    ) external view returns (uint256 value, uint256 adjustedValue, uint256 price);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {MaxLiqInfo} from "common/Types.sol";
import {LiquidationArgs} from "common/Args.sol";

interface IMinterLiquidationFacet {
    /**
     * @notice Attempts to liquidate an account by repaying the portion of the account's Kresko asset
     * debt, receiving in return a portion of the account's collateral at a discounted rate.
     * @param _args LiquidationArgs struct containing the arguments necessary to perform a liquidation.
     */
    function liquidate(LiquidationArgs calldata _args) external payable;

    /**
     * @dev Calculates the total value that is allowed to be liquidated from an account (if it is liquidatable)
     * @param _account Address of the account to liquidate
     * @param _repayAssetAddr Address of Kresko Asset to repay
     * @param _seizeAssetAddr Address of Collateral to seize
     * @return MaxLiqInfo Calculated information about the maximum liquidation.
     */
    function getMaxLiqValue(
        address _account,
        address _repayAssetAddr,
        address _seizeAssetAddr
    ) external view returns (MaxLiqInfo memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {MinterAccountState} from "minter/MTypes.sol";
import {Enums} from "common/Constants.sol";

interface IMinterAccountStateFacet {
    // ExpectedFeeRuntimeInfo is used for stack size optimization
    struct ExpectedFeeRuntimeInfo {
        address[] assets;
        uint256[] amounts;
        uint256 collateralTypeCount;
    }

    /**
     * @notice Calculates if an account's current collateral value is under its minimum collateral value
     * @param _account The account to check.
     * @return bool Indicates if the account can be liquidated.
     */
    function getAccountLiquidatable(address _account) external view returns (bool);

    /**
     * @notice Get accounts state in the Minter.
     * @param _account Account address to get the state for.
     * @return MinterAccountState Total debt value, total collateral value and collateral ratio.
     */
    function getAccountState(address _account) external view returns (MinterAccountState memory);

    /**
     * @notice Gets an array of Kresko assets the account has minted.
     * @param _account The account to get the minted Kresko assets for.
     * @return address[] Array of Kresko Asset addresses the account has minted.
     */
    function getAccountMintedAssets(address _account) external view returns (address[] memory);

    /**
     * @notice Gets an index for the Kresko asset the account has minted.
     * @param _account The account to get the minted Kresko assets for.
     * @param _krAsset The asset lookup address.
     * @return index The index of asset in the minted assets array.
     */
    function getAccountMintIndex(address _account, address _krAsset) external view returns (uint256);

    /**
     * @notice Gets the total Kresko asset debt value in USD for an account.
     * @notice Adjusted value means it is multiplied by kFactor.
     * @param _account Account to calculate the Kresko asset value for.
     * @return value The unadjusted value of debt.
     * @return valueAdjusted The kFactor adjusted value of debt.
     */
    function getAccountTotalDebtValues(address _account) external view returns (uint256 value, uint256 valueAdjusted);

    /**
     * @notice Gets the total Kresko asset debt value in USD for an account.
     * @param _account The account to calculate the Kresko asset value for.
     * @return uint256 Total debt value of `_account`.
     */
    function getAccountTotalDebtValue(address _account) external view returns (uint256);

    /**
     * @notice Get `_account` debt amount for `_asset`
     * @param _assetAddr The asset address
     * @param _account The account to query amount for
     * @return uint256 Amount of debt for `_assetAddr`
     */
    function getAccountDebtAmount(address _account, address _assetAddr) external view returns (uint256);

    /**
     * @notice Get the unadjusted and the adjusted value of collateral deposits of `_assetAddr` for `_account`.
     * @notice Adjusted value means it is multiplied by cFactor.
     * @param _account Account to get the collateral values for.
     * @param _assetAddr Asset to get the collateral values for.
     * @return value Unadjusted value of the collateral deposits.
     * @return valueAdjusted cFactor adjusted value of the collateral deposits.
     * @return price Price for the collateral asset
     */
    function getAccountCollateralValues(
        address _account,
        address _assetAddr
    ) external view returns (uint256 value, uint256 valueAdjusted, uint256 price);

    /**
     * @notice Gets the adjusted collateral value of a particular account.
     * @param _account Account to calculate the collateral value for.
     * @return valueAdjusted Collateral value of a particular account.
     */
    function getAccountTotalCollateralValue(address _account) external view returns (uint256 valueAdjusted);

    /**
     * @notice Gets the adjusted and unadjusted collateral value of `_account`.
     * @notice Adjusted value means it is multiplied by cFactor.
     * @param _account Account to get the values for
     * @return value Unadjusted total value of the collateral deposits.
     * @return valueAdjusted cFactor adjusted total value of the collateral deposits.
     */
    function getAccountTotalCollateralValues(address _account) external view returns (uint256 value, uint256 valueAdjusted);

    /**
     * @notice Get an account's minimum collateral value required
     * to back a Kresko asset amount at a given collateralization ratio.
     * @dev Accounts that have their collateral value under the minimum collateral value are considered unhealthy,
     *      accounts with their collateral value under the liquidation threshold are considered liquidatable.
     * @param _account Account to calculate the minimum collateral value for.
     * @param _ratio Collateralization ratio required: higher ratio = more collateral required
     * @return uint256 Minimum collateral value of a particular account.
     */
    function getAccountMinCollateralAtRatio(address _account, uint32 _ratio) external view returns (uint256);

    /**
     * @notice Get a list of accounts and their collateral ratios
     * @return ratio The collateral ratio of `_account`
     */
    function getAccountCollateralRatio(address _account) external view returns (uint256 ratio);

    /**
     * @notice Get a list of account collateral ratios
     * @return ratios Collateral ratios of the `_accounts`
     */
    function getAccountCollateralRatios(address[] memory _accounts) external view returns (uint256[] memory);

    /**
     * @notice Gets an index for the collateral asset the account has deposited.
     * @param _account Account to get the index for.
     * @param _collateralAsset Asset address.
     * @return i Index of the minted collateral asset.
     */
    function getAccountDepositIndex(address _account, address _collateralAsset) external view returns (uint256 i);

    /**
     * @notice Gets an array of collateral assets the account has deposited.
     * @param _account The account to get the deposited collateral assets for.
     * @return address[] Array of collateral asset addresses the account has deposited.
     */
    function getAccountCollateralAssets(address _account) external view returns (address[] memory);

    /**
     * @notice Get `_account` collateral deposit amount for `_assetAddr`
     * @param _assetAddr The asset address
     * @param _account The account to query amount for
     * @return uint256 Amount of collateral deposited for `_assetAddr`
     */
    function getAccountCollateralAmount(address _account, address _assetAddr) external view returns (uint256);

    /**
     * @notice Calculates the expected fee to be taken from a user's deposited collateral assets,
     *         by imitating calcFee without modifying state.
     * @param _account Account to charge the open fee from.
     * @param _krAsset Address of the kresko asset being burned.
     * @param _kreskoAssetAmount Amount of the kresko asset being minted.
     * @param _feeType Fee type (open or close).
     * @return assets Collateral types as an array of addresses.
     * @return amounts Collateral amounts as an array of uint256.
     */
    function previewFee(
        address _account,
        address _krAsset,
        uint256 _kreskoAssetAmount,
        Enums.MinterFee _feeType
    ) external view returns (address[] memory assets, uint256[] memory amounts);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

interface IAuthorizationFacet {
    /**
     * @dev OpenZeppelin
     * Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * @notice WARNING:
     * When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block.
     *
     * See the following forum post for more information:
     * - https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296
     *
     * @dev Kresko
     *
     * TL;DR above:
     *
     * - If you iterate the EnumSet outside a single block scope you might get different results.
     * - Since when EnumSet member is deleted it is replaced with the highest index.
     * @return address with the `role`
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     * @notice See warning in {getRoleMember} if combining these two
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * @notice To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Returns true if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * @notice Requirements
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * @notice Requirements
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {SafetyState} from "common/Types.sol";
import {Enums} from "common/Constants.sol";

interface ISafetyCouncilFacet {
    /**
     * @dev Toggle paused-state of assets in a per-action basis
     *
     * @notice These functions are only callable by a multisig quorum.
     * @param _assets list of addresses of krAssets and/or collateral assets
     * @param _action One of possible user actions:
     *  Deposit = 0
     *  Withdraw = 1,
     *  Repay = 2,
     *  Borrow = 3,
     *  Liquidate = 4
     * @param _withDuration Set a duration for this pause - @todo: implement it if required
     * @param _duration Duration for the pause if `_withDuration` is true
     */
    function toggleAssetsPaused(address[] memory _assets, Enums.Action _action, bool _withDuration, uint256 _duration) external;

    /**
     * @notice set the safetyStateSet flag
     */
    function setSafetyStateSet(bool val) external;

    /**
     * @notice For external checks if a safety state has been set for any asset
     */
    function safetyStateSet() external view returns (bool);

    /**
     * @notice View the state of safety measures for an asset on a per-action basis
     * @param _assetAddr krAsset / collateral asset
     * @param _action One of possible user actions:
     *
     *  Deposit = 0
     *  Withdraw = 1,
     *  Repay = 2,
     *  Borrow = 3,
     *  Liquidate = 4
     */
    function safetyStateFor(address _assetAddr, Enums.Action _action) external view returns (SafetyState memory);

    /**
     * @notice Check if `_assetAddr` has a pause enabled for `_action`
     * @param _action enum `Action`
     *  Deposit = 0
     *  Withdraw = 1,
     *  Repay = 2,
     *  Borrow = 3,
     *  Liquidate = 4
     * @return true if `_action` is paused
     */
    function assetActionPaused(Enums.Action _action, address _assetAddr) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {FeedConfiguration} from "common/Types.sol";

interface ICommonConfigFacet {
    struct PythConfig {
        bytes32[] pythIds;
        uint256[] staleTimes;
        bool[] invertPyth;
        bool[] isClosables;
    }

    /**
     * @notice Updates the fee recipient.
     * @param _newFeeRecipient The new fee recipient.
     */
    function setFeeRecipient(address _newFeeRecipient) external;

    function setPythEndpoint(address _pythEp) external;

    /**
     * @notice Sets the decimal precision of external oracle
     * @param _decimals Amount of decimals
     */
    function setDefaultOraclePrecision(uint8 _decimals) external;

    /**
     * @notice Sets the decimal precision of external oracle
     * @param _oracleDeviationPct Amount of decimals
     */
    function setMaxPriceDeviationPct(uint16 _oracleDeviationPct) external;

    /**
     * @notice Sets L2 sequencer uptime feed address
     * @param _sequencerUptimeFeed sequencer uptime feed address
     */
    function setSequencerUptimeFeed(address _sequencerUptimeFeed) external;

    /**
     * @notice Sets sequencer grace period time
     * @param _sequencerGracePeriodTime grace period time
     */
    function setSequencerGracePeriod(uint32 _sequencerGracePeriodTime) external;

    /**
     * @notice Set feeds for a ticker.
     * @param _ticker Ticker in bytes32 eg. bytes32("ETH")
     * @param _feedConfig List oracle configuration containing oracle identifiers and feed addresses.
     */
    function setFeedsForTicker(bytes32 _ticker, FeedConfiguration memory _feedConfig) external;

    /**
     * @notice Set chainlink feeds for tickers.
     * @dev Has modifiers: onlyRole.
     * @param _tickers Bytes32 list of tickers
     * @param _feeds List of feed addresses.
     */
    function setChainlinkFeeds(
        bytes32[] calldata _tickers,
        address[] calldata _feeds,
        uint256[] memory _staleTimes,
        bool[] calldata _isClosables
    ) external;

    /**
     * @notice Set api3 feeds for tickers.
     * @dev Has modifiers: onlyRole.
     * @param _tickers Bytes32 list of tickers
     * @param _feeds List of feed addresses.
     */
    function setAPI3Feeds(
        bytes32[] calldata _tickers,
        address[] calldata _feeds,
        uint256[] memory _staleTimes,
        bool[] calldata _isClosables
    ) external;

    /**
     * @notice Set a vault feed for ticker.
     * @dev Has modifiers: onlyRole.
     * @param _ticker Ticker in bytes32 eg. bytes32("ETH")
     * @param _vaultAddr Vault address
     * @custom:signature setVaultFeed(bytes32,address)
     * @custom:selector 0xc3f9c901
     */
    function setVaultFeed(bytes32 _ticker, address _vaultAddr) external;

    /**
     * @notice Set a pyth feeds for tickers.
     * @dev Has modifiers: onlyRole.
     * @param _tickers Bytes32 list of tickers
     * @param pythConfig Pyth configuration
     */
    function setPythFeeds(bytes32[] calldata _tickers, PythConfig calldata pythConfig) external;

    function setPythFeed(bytes32 _ticker, bytes32 _pythId, bool _invert, uint256 _staleTime, bool _isClosable) external;

    /**
     * @notice Set ChainLink feed address for ticker.
     * @param _ticker Ticker in bytes32 eg. bytes32("ETH")
     * @param _feedAddr The feed address.
     * @custom:signature setChainLinkFeed(bytes32,address)
     * @custom:selector 0xe091f77a
     */
    function setChainLinkFeed(bytes32 _ticker, address _feedAddr, uint256 _staleTime, bool _isClosable) external;

    /**
     * @notice Set API3 feed address for an asset.
     * @param _ticker Ticker in bytes32 eg. bytes32("ETH")
     * @param _feedAddr The feed address.
     * @custom:signature setApi3Feed(bytes32,address)
     * @custom:selector 0x7e9f9837
     */
    function setAPI3Feed(bytes32 _ticker, address _feedAddr, uint256 _staleTime, bool _isClosable) external;

    /**
     * @notice Sets gating manager
     * @param _newManager _newManager address
     */
    function setGatingManager(address _newManager) external;

    /**
     * @notice Sets market status provider
     * @param _provider market status provider address
     */
    function setMarketStatusProvider(address _provider) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {Enums} from "common/Constants.sol";
import {Oracle} from "common/Types.sol";

interface ICommonStateFacet {
    /// @notice The recipient of protocol fees.
    function getFeeRecipient() external view returns (address);

    /// @notice The pyth endpoint.
    function getPythEndpoint() external view returns (address);

    /// @notice Offchain oracle decimals
    function getDefaultOraclePrecision() external view returns (uint8);

    /// @notice max deviation between main oracle and fallback oracle
    function getOracleDeviationPct() external view returns (uint16);

    /// @notice gating manager contract address
    function getGatingManager() external view returns (address);

    /// @notice Get the market status provider address.
    function getMarketStatusProvider() external view returns (address);

    /// @notice Get the L2 sequencer uptime feed address.
    function getSequencerUptimeFeed() external view returns (address);

    /// @notice Get the L2 sequencer uptime feed grace period
    function getSequencerGracePeriod() external view returns (uint32);

    /**
     * @notice Get configured feed of the ticker
     * @param _ticker Ticker in bytes32, eg. bytes32("ETH").
     * @param _oracleType The oracle type.
     * @return feedAddr Feed address matching the oracle type given.
     */
    function getOracleOfTicker(bytes32 _ticker, Enums.OracleType _oracleType) external view returns (Oracle memory);

    function getChainlinkPrice(bytes32 _ticker) external view returns (uint256);

    function getVaultPrice(bytes32 _ticker) external view returns (uint256);

    function getRedstonePrice(bytes32 _ticker) external view returns (uint256);

    function getAPI3Price(bytes32 _ticker) external view returns (uint256);

    function getPythPrice(bytes32 _ticker) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {Asset, FeedConfiguration} from "common/Types.sol";
import {Enums} from "common/Constants.sol";

interface IAssetConfigFacet {
    /**
     * @notice Adds a new asset to the common state.
     * @notice Performs validations according to the `_config` provided.
     * @dev Use validateAssetConfig / static call this for validation.
     * @param _assetAddr Asset address.
     * @param _config Configuration struct to save for the asset.
     * @param _feedConfig Configuration struct for the asset's oracles
     * @return Asset Result of addAsset.
     */
    function addAsset(
        address _assetAddr,
        Asset memory _config,
        FeedConfiguration memory _feedConfig
    ) external returns (Asset memory);

    /**
     * @notice Update asset config.
     * @notice Performs validations according to the `_config` set.
     * @dev Use validateAssetConfig / static call this for validation.
     * @param _assetAddr The asset address.
     * @param _config Configuration struct to apply for the asset.
     */
    function updateAsset(address _assetAddr, Asset memory _config) external returns (Asset memory);

    /**
     * @notice  Updates the cFactor of a KreskoAsset. Convenience.
     * @param _assetAddr The collateral asset.
     * @param _newFactor The new collateral factor.
     */
    function setAssetCFactor(address _assetAddr, uint16 _newFactor) external;

    /**
     * @notice Updates the kFactor of a KreskoAsset.
     * @param _assetAddr The KreskoAsset.
     * @param _newKFactor The new kFactor.
     */
    function setAssetKFactor(address _assetAddr, uint16 _newKFactor) external;

    /**
     * @notice Validate supplied asset config. Reverts with information if invalid.
     * @param _assetAddr The asset address.
     * @param _config Configuration for the asset.
     * @return bool True for convenience.
     */
    function validateAssetConfig(address _assetAddr, Asset memory _config) external view returns (bool);

    /**
     * @notice Update oracle order for an asset.
     * @param _assetAddr The asset address.
     * @param _newOracleOrder List of 2 OracleTypes. 0 is primary and 1 is the reference.
     */
    function setAssetOracleOrder(address _assetAddr, Enums.OracleType[2] memory _newOracleOrder) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FacetCut, Initializer} from "diamond/DSTypes.sol";

interface IDiamondCutFacet {
    /**
     *@notice Add/replace/remove any number of functions, optionally execute a function with delegatecall
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _initializer The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     *                  _calldata is executed with delegatecall on _init
     */
    function diamondCut(FacetCut[] calldata _diamondCut, address _initializer, bytes calldata _calldata) external;
}

interface IExtendedDiamondCutFacet is IDiamondCutFacet {
    /**
     * @notice Use an initializer contract without cutting.
     * @param _initializer Address of contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     * - _calldata is executed with delegatecall on _init
     */
    function executeInitializer(address _initializer, bytes calldata _calldata) external;

    /// @notice Execute multiple initializers without cutting.
    function executeInitializers(Initializer[] calldata _initializers) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Facet} from "diamond/DSTypes.sol";

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupeFacet {
    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IDiamondStateFacet
/// @notice Functions for the diamond state itself.
interface IDiamondStateFacet {
    /// @notice Whether the diamond is initialized.
    function initialized() external view returns (bool);

    /// @notice The EIP-712 typehash for the contract's domain.
    function domainSeparator() external view returns (bytes32);

    /// @notice Get the storage version (amount of times the storage has been upgraded)
    /// @return uint256 The storage version.
    function getStorageVersion() external view returns (uint256);

    /**
     * @notice Get the address of the owner
     * @return owner_ The address of the owner.
     */
    function owner() external view returns (address owner_);

    /**
     * @notice Get the address of pending owner
     * @return pendingOwner_ The address of the pending owner.
     **/
    function pendingOwner() external view returns (address pendingOwner_);

    /**
     * @notice Initiate ownership transfer to a new address
     * @notice caller must be the current contract owner
     * @notice the new owner cannot be address(0)
     * @notice emits a {PendingOwnershipTransfer} event
     * @param _newOwner address that is set as the pending new owner
     */
    function transferOwnership(address _newOwner) external;

    /**
     * @notice Transfer the ownership to the new pending owner
     * @notice caller must be the pending owner
     * @notice emits a {OwnershipTransferred} event
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface IBatchFacet {
    /**
     * @notice Performs batched calls to the protocol with a single price update.
     * @param _calls Calls to perform.
     * @param _updateData Pyth price data to use for the calls.
     */
    function batchCall(bytes[] calldata _calls, bytes[] calldata _updateData) external payable;

    /**
     * @notice Performs "static calls" with the update prices through `batchCallToError`, using a try-catch.
     * Refunds the msg.value sent for price update fee.
     * @param _staticCalls Calls to perform.
     * @param _updateData Pyth price update preview with the static calls.
     * @return timestamp Timestamp of the data.
     * @return results Static call results as bytes[]
     */
    function batchStaticCall(
        bytes[] calldata _staticCalls,
        bytes[] calldata _updateData
    ) external payable returns (uint256 timestamp, bytes[] memory results);

    /**
     * @notice Performs supplied calls and reverts a `Errors.BatchResult` containing returned results as bytes[].
     * @param _calls Calls to perform.
     * @param _updateData Pyth price update data to use for the static calls.
     * @return `Errors.BatchResult` which needs to be caught and decoded on-chain (according to the result signature).
     * Use `batchStaticCall` for a direct return.
     */
    function batchCallToError(
        bytes[] calldata _calls,
        bytes[] calldata _updateData
    ) external payable returns (uint256, bytes[] memory);

    /**
     * @notice Used to transform bytes memory -> calldata by external call, then calldata slices the error selector away.
     * @param _errorData Error data to decode.
     * @return timestamp Timestamp of the data.
     * @return results Static call results as bytes[]
     */
    function decodeErrorData(bytes calldata _errorData) external pure returns (uint256 timestamp, bytes[] memory results);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {Enums} from "common/Constants.sol";

interface IErrorsEvents {
    struct ID {
        string symbol;
        address addr;
    }

    event SCDPDeposit(
        address indexed depositor,
        address indexed collateralAsset,
        uint256 amount,
        uint256 feeIndex,
        uint256 timestamp
    );
    event SCDPWithdraw(
        address indexed account,
        address indexed receiver,
        address indexed collateralAsset,
        address withdrawer,
        uint256 amount,
        uint256 feeIndex,
        uint256 timestamp
    );
    event SCDPFeeClaim(
        address indexed claimer,
        address indexed receiver,
        address indexed collateralAsset,
        uint256 feeAmount,
        uint256 newIndex,
        uint256 prevIndex,
        uint256 timestamp
    );
    event SCDPRepay(
        address indexed repayer,
        address indexed repayKreskoAsset,
        uint256 repayAmount,
        address indexed receiveKreskoAsset,
        uint256 receiveAmount,
        uint256 timestamp
    );

    event SCDPLiquidationOccured(
        address indexed liquidator,
        address indexed repayKreskoAsset,
        uint256 repayAmount,
        address indexed seizeCollateral,
        uint256 seizeAmount,
        uint256 prevLiqIndex,
        uint256 newLiqIndex,
        uint256 timestamp
    );
    event SCDPCoverOccured(
        address indexed coverer,
        address indexed coverAsset,
        uint256 coverAmount,
        address indexed seizeCollateral,
        uint256 seizeAmount,
        uint256 prevLiqIndex,
        uint256 newLiqIndex,
        uint256 timestamp
    );

    // Emitted when a swap pair is disabled / enabled.
    event PairSet(address indexed assetIn, address indexed assetOut, bool enabled);
    // Emitted when a kresko asset fee is updated.
    event FeeSet(address indexed _asset, uint256 openFee, uint256 closeFee, uint256 protocolFee);

    // Emitted when a collateral is updated.
    event SCDPCollateralUpdated(address indexed _asset, uint256 liquidationThreshold);

    // Emitted when a kresko asset is updated.
    event SCDPKrAssetUpdated(
        address indexed _asset,
        uint256 openFee,
        uint256 closeFee,
        uint256 protocolFee,
        uint256 maxDebtMinter
    );

    event Swap(
        address indexed who,
        address indexed assetIn,
        address indexed assetOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp
    );
    event SwapFee(
        address indexed feeAsset,
        address indexed assetIn,
        uint256 feeAmount,
        uint256 protocolFeeAmount,
        uint256 timestamp
    );

    event Income(address asset, uint256 amount);

    /**
     * @notice Emitted when the liquidation incentive multiplier is updated for a swappable krAsset.
     * @param symbol Asset symbol
     * @param asset The krAsset asset updated.
     * @param from Previous value.
     * @param to New value.
     */
    event SCDPLiquidationIncentiveUpdated(string indexed symbol, address indexed asset, uint256 from, uint256 to);

    /**
     * @notice Emitted when the minimum collateralization ratio is updated for the SCDP.
     * @param from Previous value.
     * @param to New value.
     */
    event SCDPMinCollateralRatioUpdated(uint256 from, uint256 to);

    /**
     * @notice Emitted when the liquidation threshold value is updated
     * @param from Previous value.
     * @param to New value.
     * @param mlr The new max liquidation ratio.
     */
    event SCDPLiquidationThresholdUpdated(uint256 from, uint256 to, uint256 mlr);

    /**
     * @notice Emitted when the max liquidation ratio is updated
     * @param from Previous value.
     * @param to New value.
     */
    event SCDPMaxLiquidationRatioUpdated(uint256 from, uint256 to);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                 Collateral                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when a collateral asset is added to the protocol.
     * @dev Can only be emitted once for a given collateral asset.
     * @param ticker Underlying asset ticker.
     * @param symbol Asset symbol
     * @param collateralAsset The address of the collateral asset.
     * @param factor The collateral factor.
     * @param liqIncentive The liquidation incentive
     */
    event CollateralAssetAdded(
        string indexed ticker,
        string indexed symbol,
        address indexed collateralAsset,
        uint256 factor,
        address anchor,
        uint256 liqIncentive
    );

    /**
     * @notice Emitted when a collateral asset is updated.
     * @param ticker Underlying asset ticker.
     * @param symbol Asset symbol
     * @param collateralAsset The address of the collateral asset.
     * @param factor The collateral factor.
     * @param liqIncentive The liquidation incentive
     */
    event CollateralAssetUpdated(
        string indexed ticker,
        string indexed symbol,
        address indexed collateralAsset,
        uint256 factor,
        address anchor,
        uint256 liqIncentive
    );

    /**
     * @notice Emitted when an account deposits collateral.
     * @param account The address of the account depositing collateral.
     * @param collateralAsset The address of the collateral asset.
     * @param amount The amount of the collateral asset that was deposited.
     */
    event CollateralDeposited(address indexed account, address indexed collateralAsset, uint256 amount);

    /**
     * @notice Emitted when an account withdraws collateral.
     * @param account The address of the account withdrawing collateral.
     * @param collateralAsset The address of the collateral asset.
     * @param amount The amount of the collateral asset that was withdrawn.
     */
    event CollateralWithdrawn(address indexed account, address indexed collateralAsset, uint256 amount);

    /**
     * @notice Emitted when AMM helper withdraws account collateral without MCR checks.
     * @param account The address of the account withdrawing collateral.
     * @param collateralAsset The address of the collateral asset.
     * @param amount The amount of the collateral asset that was withdrawn.
     */
    event UncheckedCollateralWithdrawn(address indexed account, address indexed collateralAsset, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                Kresko Assets                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when a KreskoAsset is added to the protocol.
     * @dev Can only be emitted once for a given Kresko asset.
     * @param ticker Underlying asset ticker.
     * @param symbol Asset symbol
     * @param kreskoAsset The address of the Kresko asset.
     * @param anchor anchor token
     * @param kFactor The k-factor.
     * @param maxDebtMinter The total supply limit.
     * @param closeFee The close fee percentage.
     * @param openFee The open fee percentage.
     */
    event KreskoAssetAdded(
        string indexed ticker,
        string indexed symbol,
        address indexed kreskoAsset,
        address anchor,
        uint256 kFactor,
        uint256 maxDebtMinter,
        uint256 closeFee,
        uint256 openFee
    );

    /**
     * @notice Emitted when a Kresko asset's oracle is updated.
     * @param ticker Underlying asset ticker.
     * @param symbol Asset symbol
     * @param kreskoAsset The address of the Kresko asset.
     * @param kFactor The k-factor.
     * @param maxDebtMinter The total supply limit.
     * @param closeFee The close fee percentage.
     * @param openFee The open fee percentage.
     */
    event KreskoAssetUpdated(
        string indexed ticker,
        string indexed symbol,
        address indexed kreskoAsset,
        address anchor,
        uint256 kFactor,
        uint256 maxDebtMinter,
        uint256 closeFee,
        uint256 openFee
    );

    /**
     * @notice Emitted when an account mints a Kresko asset.
     * @param account The address of the account minting the Kresko asset.
     * @param kreskoAsset The address of the Kresko asset.
     * @param amount The amount of the KreskoAsset that was minted.
     * @param receiver Receiver of the minted assets.
     */
    event KreskoAssetMinted(address indexed account, address indexed kreskoAsset, uint256 amount, address receiver);

    /**
     * @notice Emitted when an account burns a Kresko asset.
     * @param account The address of the account burning the Kresko asset.
     * @param kreskoAsset The address of the Kresko asset.
     * @param amount The amount of the KreskoAsset that was burned.
     */
    event KreskoAssetBurned(address indexed account, address indexed kreskoAsset, uint256 amount);

    /**
     * @notice Emitted when cFactor is updated for a collateral asset.
     * @param symbol Asset symbol
     * @param collateralAsset The address of the collateral asset.
     * @param from Previous value.
     * @param to New value.
     */
    event CFactorUpdated(string indexed symbol, address indexed collateralAsset, uint256 from, uint256 to);
    /**
     * @notice Emitted when kFactor is updated for a KreskoAsset.
     * @param symbol Asset symbol
     * @param kreskoAsset The address of the KreskoAsset.
     * @param from Previous value.
     * @param to New value.
     */
    event KFactorUpdated(string indexed symbol, address indexed kreskoAsset, uint256 from, uint256 to);

    /**
     * @notice Emitted when an account burns a Kresko asset.
     * @param account The address of the account burning the Kresko asset.
     * @param kreskoAsset The address of the Kresko asset.
     * @param amount The amount of the KreskoAsset that was burned.
     */
    event DebtPositionClosed(address indexed account, address indexed kreskoAsset, uint256 amount);

    /**
     * @notice Emitted when an account pays an open/close fee with a collateral asset in the Minter.
     * @dev This can be emitted multiple times for a single asset.
     * @param account Address of the account paying the fee.
     * @param paymentCollateralAsset Address of the collateral asset used to pay the fee.
     * @param feeType Fee type.
     * @param paymentAmount Amount of ollateral asset that was paid.
     * @param paymentValue USD value of the payment.
     */
    event FeePaid(
        address indexed account,
        address indexed paymentCollateralAsset,
        uint256 indexed feeType,
        uint256 paymentAmount,
        uint256 paymentValue,
        uint256 feeValue
    );

    /**
     * @notice Emitted when a liquidation occurs.
     * @param account The address of the account being liquidated.
     * @param liquidator The account performing the liquidation.
     * @param repayKreskoAsset The address of the KreskoAsset being paid back to the protocol by the liquidator.
     * @param repayAmount The amount of the repay KreskoAsset being paid back to the protocol by the liquidator.
     * @param seizedCollateralAsset The address of the collateral asset being seized from the account by the liquidator.
     * @param collateralSent The amount of the seized collateral asset being seized from the account by the liquidator.
     */
    event LiquidationOccurred(
        address indexed account,
        address indexed liquidator,
        address indexed repayKreskoAsset,
        uint256 repayAmount,
        address seizedCollateralAsset,
        uint256 collateralSent
    );

    /* -------------------------------------------------------------------------- */
    /*                                Parameters                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when a safety state is triggered for an asset
     * @param action Target action
     * @param symbol Asset symbol
     * @param asset Asset affected
     * @param description change description
     */
    event SafetyStateChange(Enums.Action indexed action, string indexed symbol, address indexed asset, string description);

    /**
     * @notice Emitted when the fee recipient is updated.
     * @param from The previous value.
     * @param to New value.
     */
    event FeeRecipientUpdated(address from, address to);

    /**
     * @notice Emitted when the liquidation incentive multiplier is updated.
     * @param symbol Asset symbol
     * @param asset The collateral asset being updated.
     * @param from Previous value.
     * @param to New value.
     */
    event LiquidationIncentiveUpdated(string indexed symbol, address indexed asset, uint256 from, uint256 to);

    /**
     * @notice Emitted when the minimum collateralization ratio is updated.
     * @param from Previous value.
     * @param to New value.
     */
    event MinCollateralRatioUpdated(uint256 from, uint256 to);

    /**
     * @notice Emitted when the minimum debt value updated.
     * @param from Previous value.
     * @param to New value.
     */
    event MinimumDebtValueUpdated(uint256 from, uint256 to);

    /**
     * @notice Emitted when the liquidation threshold value is updated
     * @param from Previous value.
     * @param to New value.
     * @param mlr The new max liquidation ratio.
     */
    event LiquidationThresholdUpdated(uint256 from, uint256 to, uint256 mlr);
    /**
     * @notice Emitted when the max liquidation ratio is updated
     * @param from Previous value.
     * @param to New value.
     */
    event MaxLiquidationRatioUpdated(uint256 from, uint256 to);

    error PERMIT_DEADLINE_EXPIRED(address, address, uint256, uint256);
    error INVALID_SIGNER(address, address);

    error ProxyCalldataFailedWithoutErrMsg();
    error ProxyCalldataFailedWithStringMessage(string message);
    error ProxyCalldataFailedWithCustomError(bytes result);

    error DIAMOND_FUNCTION_DOES_NOT_EXIST(bytes4 selector);
    error DIAMOND_INIT_DATA_PROVIDED_BUT_INIT_ADDRESS_WAS_ZERO(bytes data);
    error DIAMOND_INIT_ADDRESS_PROVIDED_BUT_INIT_DATA_WAS_EMPTY(address initializer);
    error DIAMOND_FUNCTION_ALREADY_EXISTS(address newFacet, address oldFacet, bytes4 func);
    error DIAMOND_INIT_FAILED(address initializer, bytes data);
    error DIAMOND_NOT_INITIALIZING();
    error DIAMOND_ALREADY_INITIALIZED(uint256 initializerVersion, uint256 currentVersion);
    error DIAMOND_CUT_ACTION_WAS_NOT_ADD_REPLACE_REMOVE();
    error DIAMOND_FACET_ADDRESS_CANNOT_BE_ZERO_WHEN_ADDING_FUNCTIONS(bytes4[] selectors);
    error DIAMOND_FACET_ADDRESS_CANNOT_BE_ZERO_WHEN_REPLACING_FUNCTIONS(bytes4[] selectors);
    error DIAMOND_FACET_ADDRESS_MUST_BE_ZERO_WHEN_REMOVING_FUNCTIONS(address facet, bytes4[] selectors);
    error DIAMOND_NO_FACET_SELECTORS(address facet);
    error DIAMOND_FACET_ADDRESS_CANNOT_BE_ZERO_WHEN_REMOVING_ONE_FUNCTION(bytes4 selector);
    error DIAMOND_REPLACE_FUNCTION_NEW_FACET_IS_SAME_AS_OLD(address facet, bytes4 selector);
    error NEW_OWNER_CANNOT_BE_ZERO_ADDRESS();
    error NOT_DIAMOND_OWNER(address who, address owner);
    error NOT_PENDING_DIAMOND_OWNER(address who, address pendingOwner);

    error APPROVE_FAILED(address, address, address, uint256);
    error ETH_TRANSFER_FAILED(address, uint256);
    error TRANSFER_FAILED(address, address, address, uint256);
    error ADDRESS_HAS_NO_CODE(address);
    error NOT_INITIALIZING();
    error TO_WAD_AMOUNT_IS_NEGATIVE(int256);
    error COMMON_ALREADY_INITIALIZED();
    error MINTER_ALREADY_INITIALIZED();
    error SCDP_ALREADY_INITIALIZED();
    error STRING_HEX_LENGTH_INSUFFICIENT();
    error SAFETY_COUNCIL_NOT_ALLOWED();
    error SAFETY_COUNCIL_SETTER_IS_NOT_ITS_OWNER(address);
    error SAFETY_COUNCIL_ALREADY_EXISTS(address given, address existing);
    error MULTISIG_NOT_ENOUGH_OWNERS(address, uint256 owners, uint256 required);
    error ACCESS_CONTROL_NOT_SELF(address who, address self);
    error MARKET_CLOSED(ID, string);
    error SCDP_ASSET_ECONOMY(ID, uint256 seizeReductionPct, ID, uint256 repayIncreasePct);
    error MINTER_ASSET_ECONOMY(ID, uint256 seizeReductionPct, ID, uint256 repayIncreasePct);
    error INVALID_TICKER(ID, string ticker);
    error ASSET_NOT_ENABLED(ID);
    error ASSET_SET_FEEDS_FAILED(ID);
    error ASSET_CANNOT_BE_USED_TO_COVER(ID);
    error ASSET_PAUSED_FOR_THIS_ACTION(ID, uint8 action);
    error ASSET_NOT_MINTER_COLLATERAL(ID);
    error ASSET_NOT_FEE_ACCUMULATING_ASSET(ID);
    error ASSET_NOT_SHARED_COLLATERAL(ID);
    error ASSET_NOT_MINTABLE_FROM_MINTER(ID);
    error ASSET_NOT_SWAPPABLE(ID);
    error ASSET_DOES_NOT_HAVE_DEPOSITS(ID);
    error ASSET_CANNOT_BE_FEE_ASSET(ID);
    error ASSET_NOT_VALID_DEPOSIT_ASSET(ID);
    error ASSET_ALREADY_ENABLED(ID);
    error ASSET_ALREADY_DISABLED(ID);
    error ASSET_DOES_NOT_EXIST(ID);
    error ASSET_ALREADY_EXISTS(ID);
    error ASSET_IS_VOID(ID);
    error INVALID_ASSET(ID);
    error CANNOT_REMOVE_COLLATERAL_THAT_HAS_USER_DEPOSITS(ID);
    error CANNOT_REMOVE_SWAPPABLE_ASSET_THAT_HAS_DEBT(ID);
    error INVALID_CONTRACT_KRASSET(ID krAsset);
    error INVALID_CONTRACT_KRASSET_ANCHOR(ID anchor, ID krAsset);
    error NOT_SWAPPABLE_KRASSET(ID);
    error IDENTICAL_ASSETS(ID);
    error WITHDRAW_NOT_SUPPORTED();
    error MINT_NOT_SUPPORTED();
    error DEPOSIT_NOT_SUPPORTED();
    error REDEEM_NOT_SUPPORTED();
    error NATIVE_TOKEN_DISABLED(ID);
    error EXCEEDS_ASSET_DEPOSIT_LIMIT(ID, uint256 deposits, uint256 limit);
    error EXCEEDS_ASSET_MINTING_LIMIT(ID, uint256 deposits, uint256 limit);
    error UINT128_OVERFLOW(ID, uint256 deposits, uint256 limit);
    error INVALID_SENDER(address, address);
    error INVALID_MIN_DEBT(uint256 invalid, uint256 valid);
    error INVALID_SCDP_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_MCR(uint256 invalid, uint256 valid);
    error MLR_CANNOT_BE_LESS_THAN_LIQ_THRESHOLD(uint256 mlt, uint256 lt);
    error INVALID_LIQ_THRESHOLD(uint256 lt, uint256 min, uint256 max);
    error INVALID_PROTOCOL_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_ASSET_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_ORACLE_DEVIATION(uint256 invalid, uint256 valid);
    error INVALID_ORACLE_TYPE(uint8 invalid);
    error INVALID_FEE_RECIPIENT(address invalid);
    error INVALID_LIQ_INCENTIVE(ID, uint256 invalid, uint256 min, uint256 max);
    error INVALID_KFACTOR(ID, uint256 invalid, uint256 valid);
    error INVALID_CFACTOR(ID, uint256 invalid, uint256 valid);
    error INVALID_MINTER_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_PRICE_PRECISION(uint256 decimals, uint256 valid);
    error INVALID_COVER_THRESHOLD(uint256 threshold, uint256 max);
    error INVALID_COVER_INCENTIVE(uint256 incentive, uint256 min, uint256 max);
    error INVALID_DECIMALS(ID, uint256 decimals);
    error INVALID_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_FEE_TYPE(uint8 invalid, uint8 valid);
    error INVALID_VAULT_PRICE(string ticker, address);
    error INVALID_API3_PRICE(string ticker, address);
    error INVALID_CL_PRICE(string ticker, address);
    error INVALID_PRICE(ID, address oracle, int256 price);
    error INVALID_KRASSET_OPERATOR(ID, address invalidOperator, address validOperator);
    error INVALID_DENOMINATOR(ID, uint256 denominator, uint256 valid);
    error INVALID_OPERATOR(ID, address who, address valid);
    error INVALID_SUPPLY_LIMIT(ID, uint256 invalid, uint256 valid);
    error NEGATIVE_PRICE(address asset, int256 price);
    error STALE_PRICE(string ticker, uint256 price, uint256 timeFromUpdate, uint256 threshold);
    error STALE_PUSH_PRICE(
        ID asset,
        string ticker,
        int256 price,
        uint8 oracleType,
        address feed,
        uint256 timeFromUpdate,
        uint256 threshold
    );
    error PRICE_UNSTABLE(uint256 primaryPrice, uint256 referencePrice, uint256 deviationPct);
    error ZERO_OR_STALE_VAULT_PRICE(ID, address, uint256);
    error ZERO_OR_STALE_PRICE(string ticker, uint8[2] oracles);
    error ZERO_OR_NEGATIVE_PUSH_PRICE(ID asset, string ticker, int256 price, uint8 oracleType, address feed);
    error NO_PUSH_ORACLE_SET(string ticker);
    error NOT_SUPPORTED_YET();
    error WRAP_NOT_SUPPORTED();
    error BURN_AMOUNT_OVERFLOW(ID, uint256 burnAmount, uint256 debtAmount);
    error PAUSED(address who);
    error L2_SEQUENCER_DOWN();
    error FEED_ZERO_ADDRESS(string ticker);
    error INVALID_SEQUENCER_UPTIME_FEED(address);
    error NO_MINTED_ASSETS(address who);
    error NO_COLLATERALS_DEPOSITED(address who);
    error MISSING_PHASE_3_NFT();
    error MISSING_PHASE_2_NFT();
    error MISSING_PHASE_1_NFT();
    error CANNOT_RE_ENTER();
    error ARRAY_LENGTH_MISMATCH(string ticker, uint256 arr1, uint256 arr2);
    error COLLATERAL_VALUE_GREATER_THAN_REQUIRED(uint256 collateralValue, uint256 minCollateralValue, uint32 ratio);
    error COLLATERAL_VALUE_GREATER_THAN_COVER_THRESHOLD(uint256 collateralValue, uint256 minCollateralValue, uint48 ratio);
    error ACCOUNT_COLLATERAL_VALUE_LESS_THAN_REQUIRED(
        address who,
        uint256 collateralValue,
        uint256 minCollateralValue,
        uint32 ratio
    );
    error COLLATERAL_VALUE_LESS_THAN_REQUIRED(uint256 collateralValue, uint256 minCollateralValue, uint32 ratio);
    error CANNOT_LIQUIDATE_HEALTHY_ACCOUNT(address who, uint256 collateralValue, uint256 minCollateralValue, uint32 ratio);
    error CANNOT_LIQUIDATE_SELF();
    error LIQUIDATION_AMOUNT_GREATER_THAN_DEBT(ID repayAsset, uint256 repayAmount, uint256 availableAmount);
    error LIQUIDATION_SEIZED_LESS_THAN_EXPECTED(ID, uint256, uint256);
    error LIQUIDATION_VALUE_IS_ZERO(ID repayAsset, ID seizeAsset);
    error ACCOUNT_HAS_NO_DEPOSITS(address who, ID);
    error WITHDRAW_AMOUNT_GREATER_THAN_DEPOSITS(address who, ID, uint256 requested, uint256 deposits);
    error ACCOUNT_KRASSET_NOT_FOUND(address account, ID, address[] accountCollaterals);
    error ACCOUNT_COLLATERAL_NOT_FOUND(address account, ID, address[] accountCollaterals);
    error ARRAY_INDEX_OUT_OF_BOUNDS(ID element, uint256 index, address[] elements);
    error ELEMENT_DOES_NOT_MATCH_PROVIDED_INDEX(ID element, uint256 index, address[] elements);
    error NO_FEES_TO_CLAIM(ID asset, address claimer);
    error REPAY_OVERFLOW(ID repayAsset, ID seizeAsset, uint256 invalid, uint256 valid);
    error INCOME_AMOUNT_IS_ZERO(ID incomeAsset);
    error NO_LIQUIDITY_TO_GIVE_INCOME_FOR(ID incomeAsset, uint256 userDeposits, uint256 totalDeposits);
    error NOT_ENOUGH_SWAP_DEPOSITS_TO_SEIZE(ID repayAsset, ID seizeAsset, uint256 invalid, uint256 valid);
    error SWAP_ROUTE_NOT_ENABLED(ID assetIn, ID assetOut);
    error RECEIVED_LESS_THAN_DESIRED(ID, uint256 invalid, uint256 valid);
    error SWAP_ZERO_AMOUNT_IN(ID tokenIn);
    error INVALID_WITHDRAW(ID withdrawAsset, uint256 sharesIn, uint256 assetsOut);
    error ROUNDING_ERROR(ID asset, uint256 sharesIn, uint256 assetsOut);
    error MAX_DEPOSIT_EXCEEDED(ID asset, uint256 assetsIn, uint256 maxDeposit);
    error COLLATERAL_AMOUNT_LOW(ID krAssetCollateral, uint256 amount, uint256 minAmount);
    error MINT_VALUE_LESS_THAN_MIN_DEBT_VALUE(ID, uint256 value, uint256 minRequiredValue);
    error NOT_A_CONTRACT(address who);
    error NO_ALLOWANCE(address spender, address owner, uint256 requested, uint256 allowed);
    error NOT_ENOUGH_BALANCE(address who, uint256 requested, uint256 available);
    error SENDER_NOT_OPERATOR(ID, address sender, address kresko);
    error ZERO_SHARES_FROM_ASSETS(ID, uint256 assets, ID);
    error ZERO_SHARES_OUT(ID, uint256 assets);
    error ZERO_SHARES_IN(ID, uint256 assets);
    error ZERO_ASSETS_FROM_SHARES(ID, uint256 shares, ID);
    error ZERO_ASSETS_OUT(ID, uint256 shares);
    error ZERO_ASSETS_IN(ID, uint256 shares);
    error ZERO_ADDRESS();
    error ZERO_DEPOSIT(ID);
    error ZERO_AMOUNT(ID);
    error ZERO_WITHDRAW(ID);
    error ZERO_MINT(ID);
    error ZERO_REPAY(ID, uint256 repayAmount, uint256 seizeAmount);
    error ZERO_BURN(ID);
    error ZERO_DEBT(ID);
    error UPDATE_FEE_OVERFLOW(uint256 sent, uint256 required);
    error BatchResult(uint256 timestamp, bytes[] results);
    error Panicked(uint256 code);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.20;

import {ERC1967Utils} from "../ERC1967/ERC1967Utils.sol";
import {ERC1967Proxy} from "../ERC1967/ERC1967Proxy.sol";
import {IERC1967} from "../../interfaces/IERC1967.sol";
import {ProxyAdmin} from "./ProxyAdmin.sol";

/**
 * @dev Interface for {TransparentUpgradeableProxy}. In order to implement transparency, {TransparentUpgradeableProxy}
 * does not implement this interface directly, and its upgradeability mechanism is implemented by an internal dispatch
 * mechanism. The compiler is unaware that these functions are implemented by {TransparentUpgradeableProxy} and will not
 * include them in the ABI so this interface must be used to interact with it.
 */
interface ITransparentUpgradeableProxy is IERC1967 {
    function upgradeToAndCall(address, bytes calldata) external payable;
}

/**
 * @dev This contract implements a proxy that is upgradeable through an associated {ProxyAdmin} instance.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches the {ITransparentUpgradeableProxy-upgradeToAndCall} function exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can call the `upgradeToAndCall` function but any other call won't be forwarded to
 * the implementation. If the admin tries to call a function on the implementation it will fail with an error indicating
 * the proxy admin cannot fallback to the target implementation.
 *
 * These properties mean that the admin account can only be used for upgrading the proxy, so it's best if it's a
 * dedicated account that is not used for anything else. This will avoid headaches due to sudden errors when trying to
 * call a function from the proxy implementation. For this reason, the proxy deploys an instance of {ProxyAdmin} and
 * allows upgrades only if they come through it. You should think of the `ProxyAdmin` instance as the administrative
 * interface of the proxy, including the ability to change who can trigger upgrades by transferring ownership.
 *
 * NOTE: The real interface of this proxy is that defined in `ITransparentUpgradeableProxy`. This contract does not
 * inherit from that interface, and instead `upgradeToAndCall` is implicitly implemented using a custom dispatch
 * mechanism in `_fallback`. Consequently, the compiler will not produce an ABI for this contract. This is necessary to
 * fully implement transparency without decoding reverts caused by selector clashes between the proxy and the
 * implementation.
 *
 * NOTE: This proxy does not inherit from {Context} deliberately. The {ProxyAdmin} of this contract won't send a
 * meta-transaction in any way, and any other meta-transaction setup should be made in the implementation contract.
 *
 * IMPORTANT: This contract avoids unnecessary storage reads by setting the admin only during construction as an
 * immutable variable, preventing any changes thereafter. However, the admin slot defined in ERC-1967 can still be
 * overwritten by the implementation logic pointed to by this proxy. In such cases, the contract may end up in an
 * undesirable state where the admin slot is different from the actual admin.
 *
 * WARNING: It is not recommended to extend this contract to add additional external functions. If you do so, the
 * compiler will not check that there are no selector conflicts, due to the note above. A selector clash between any new
 * function and the functions declared in {ITransparentUpgradeableProxy} will be resolved in favor of the new one. This
 * could render the `upgradeToAndCall` function inaccessible, preventing upgradeability and compromising transparency.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    // An immutable address for the admin to avoid unnecessary SLOADs before each call
    // at the expense of removing the ability to change the admin once it's set.
    // This is acceptable if the admin is always a ProxyAdmin instance or similar contract
    // with its own ability to transfer the permissions to another account.
    address private immutable _admin;

    /**
     * @dev The proxy caller is the current admin, and can't fallback to the proxy target.
     */
    error ProxyDeniedAdminAccess();

    /**
     * @dev Initializes an upgradeable proxy managed by an instance of a {ProxyAdmin} with an `initialOwner`,
     * backed by the implementation at `_logic`, and optionally initialized with `_data` as explained in
     * {ERC1967Proxy-constructor}.
     */
    constructor(address _logic, address initialOwner, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _admin = address(new ProxyAdmin(initialOwner));
        // Set the storage value and emit an event for ERC-1967 compatibility
        ERC1967Utils.changeAdmin(_proxyAdmin());
    }

    /**
     * @dev Returns the admin of this proxy.
     */
    function _proxyAdmin() internal virtual returns (address) {
        return _admin;
    }

    /**
     * @dev If caller is the admin process the call internally, otherwise transparently fallback to the proxy behavior.
     */
    function _fallback() internal virtual override {
        if (msg.sender == _proxyAdmin()) {
            if (msg.sig != ITransparentUpgradeableProxy.upgradeToAndCall.selector) {
                revert ProxyDeniedAdminAccess();
            } else {
                _dispatchUpgradeToAndCall();
            }
        } else {
            super._fallback();
        }
    }

    /**
     * @dev Upgrade the implementation of the proxy. See {ERC1967Utils-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - If `data` is empty, `msg.value` must be zero.
     */
    function _dispatchUpgradeToAndCall() private {
        (address newImplementation, bytes memory data) = abi.decode(msg.data[4:], (address, bytes));
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {ERC165Upgradeable} from "../utils/introspection/ERC165Upgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControl, ERC165Upgradeable {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;


    /// @custom:storage-location erc7201:openzeppelin.storage.AccessControl
    struct AccessControlStorage {
        mapping(bytes32 role => RoleData) _roles;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AccessControlStorageLocation = 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800;

    function _getAccessControlStorage() private pure returns (AccessControlStorage storage $) {
        assembly {
            $.slot := AccessControlStorageLocation
        }
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        return $._roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        return $._roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        AccessControlStorage storage $ = _getAccessControlStorage();
        bytes32 previousAdminRole = getRoleAdmin(role);
        $._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        if (!hasRole(role, account)) {
            $._roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        if (hasRole(role, account)) {
            $._roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
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
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
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
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {Asset} from "common/Types.sol";
import {toWad} from "common/funcs/Math.sol";
import {pushPrice, viewPrice} from "common/funcs/Prices.sol";
import {MinterState} from "minter/MState.sol";
import {cs} from "common/State.sol";
import {PercentageMath} from "libs/PercentageMath.sol";
import {WadRay} from "libs/WadRay.sol";
import {PythView} from "vendor/pyth/PythScript.sol";

using PercentageMath for uint256;
using WadRay for uint256;

library ViewHelpers {
    /* -------------------------------------------------------------------------- */
    /*                                 Push Price                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Gets the USD value for a single Kresko asset and amount.
     * @param _amount Amount of the Kresko asset to calculate the value for.
     * @param _ignoreKFactor Boolean indicating if the asset's k-factor should be ignored.
     * @return value Value for the provided amount of the Kresko asset.
     */
    function viewDebtAmountToValue(
        Asset storage self,
        uint256 _price,
        uint256 _amount,
        bool _ignoreKFactor
    ) internal view returns (uint256 value) {
        if (_amount == 0) return 0;
        value = _price.wadMul(_amount);

        if (!_ignoreKFactor) {
            value = value.percentMul(self.kFactor);
        }
    }

    /// @notice Helper function to get unadjusted, adjusted and price values for collateral assets
    function viewCollateralAmountToValues(
        Asset storage self,
        uint256 _price,
        uint256 _amount
    ) internal view returns (uint256 value, uint256 valueAdjusted) {
        value = toWad(_amount, self.decimals).wadMul(_price);
        valueAdjusted = value.percentMul(self.factor);
    }

    function viewCollateralAmountToValue(
        Asset storage self,
        uint256 _price,
        uint256 _amount,
        bool _ignoreFactor
    ) internal view returns (uint256 value) {
        if (_amount == 0) return 0;
        value = toWad(_amount, self.decimals).wadMul(_price);

        if (!_ignoreFactor) {
            value = value.percentMul(self.factor);
        }
    }

    /// @notice Helper function to get unadjusted, adjusted and price values for debt assets
    function viewDebtAmountToValues(
        Asset storage self,
        uint256 _price,
        uint256 _amount
    ) internal view returns (uint256 value, uint256 valueAdjusted) {
        value = _amount.wadMul(_price);
        valueAdjusted = value.percentMul(self.kFactor);
    }

    function getViewPrice(Asset storage self, PythView calldata prices) internal view returns (uint256 price_) {
        price_ = uint256(
            prices.ids.length == 0 ? pushPrice(self.oracles, self.ticker).answer : viewPrice(self.ticker, prices).answer
        );
    }

    /**
     * @notice Gets the total debt value in USD for an account.
     * @param _account Account to calculate the KreskoAsset value for.
     * @return value Total kresko asset debt value of `_account`.
     */
    function viewAccountTotalDebtValue(
        MinterState storage self,
        PythView calldata prices,
        address _account
    ) internal view returns (uint256 value) {
        address[] memory assets = self.mintedKreskoAssets[_account];
        for (uint256 i; i < assets.length; ) {
            Asset storage asset = cs().assets[assets[i]];
            uint256 debtAmount = self.accountDebtAmount(_account, assets[i], asset);
            unchecked {
                if (debtAmount != 0) {
                    value += viewDebtAmountToValue(asset, getViewPrice(asset, prices), debtAmount, false);
                }
                i++;
            }
        }
        return value;
    }

    /**
     * @notice Gets the collateral value of a particular account.
     * @param _account Account to calculate the collateral value for.
     * @return totalCollateralValue Collateral value of a particular account.
     */
    function viewAccountTotalCollateralValue(
        MinterState storage self,
        PythView calldata prices,
        address _account
    ) internal view returns (uint256 totalCollateralValue) {
        address[] memory assets = self.depositedCollateralAssets[_account];
        for (uint256 i; i < assets.length; ) {
            Asset storage asset = cs().assets[assets[i]];
            uint256 collateralAmount = self.accountCollateralAmount(_account, assets[i], asset);
            unchecked {
                if (collateralAmount != 0) {
                    totalCollateralValue += viewCollateralAmountToValue(
                        asset,
                        getViewPrice(asset, prices),
                        collateralAmount,
                        false // Take the collateral factor into consideration.
                    );
                }
                i++;
            }
        }

        return totalCollateralValue;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Utils.sol)

pragma solidity ^0.8.20;

import {IBeacon} from "../beacon/IBeacon.sol";
import {Address} from "../../utils/Address.sol";
import {StorageSlot} from "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 */
library ERC1967Utils {
    // We re-declare ERC-1967 events here because they can't be used directly from IERC1967.
    // This will be fixed in Solidity 0.8.21. At that point we should remove these events.
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev The `admin` of the proxy is invalid.
     */
    error ERC1967InvalidAdmin(address admin);

    /**
     * @dev The `beacon` of the proxy is invalid.
     */
    error ERC1967InvalidBeacon(address beacon);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Performs implementation upgrade with additional setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967InvalidAdmin(address(0));
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {IERC1967-AdminChanged} event.
     */
    function changeAdmin(address newAdmin) internal {
        emit AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is the keccak-256 hash of "eip1967.proxy.beacon" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (newBeacon.code.length == 0) {
            revert ERC1967InvalidBeacon(newBeacon);
        }

        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;

        address beaconImplementation = IBeacon(newBeacon).implementation();
        if (beaconImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(beaconImplementation);
        }
    }

    /**
     * @dev Change the beacon and trigger a setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-BeaconUpgraded} event.
     *
     * CAUTION: Invoking this function has no effect on an instance of {BeaconProxy} since v5, since
     * it uses an immutable beacon without looking at the value of the ERC-1967 beacon slot for
     * efficiency.
     */
    function upgradeBeaconToAndCall(address newBeacon, bytes memory data) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);

        if (data.length > 0) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.20;

import {Proxy} from "../Proxy.sol";
import {ERC1967Utils} from "./ERC1967Utils.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `implementation`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `implementation`. This will typically be an
     * encoded function call, and allows initializing the storage of the proxy like a Solidity constructor.
     *
     * Requirements:
     *
     * - If `data` is empty, `msg.value` must be zero.
     */
    constructor(address implementation, bytes memory _data) payable {
        ERC1967Utils.upgradeToAndCall(implementation, _data);
    }

    /**
     * @dev Returns the current implementation address.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function _implementation() internal view virtual override returns (address) {
        return ERC1967Utils.getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.20;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165Upgradeable is Initializable, IERC165 {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {UpgradeableBeacon} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/Proxy.sol)

pragma solidity ^0.8.20;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback
     * function and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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