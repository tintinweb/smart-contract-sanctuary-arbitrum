// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
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
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { AccessControlStorage } from "@solidstate/contracts/access/access_control/AccessControlStorage.sol";

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { ILaunchPadFactoryAdmin } from "../interfaces/ILaunchPadFactoryAdmin.sol";
import { ILaunchPadProject } from "../interfaces/ILaunchPadProject.sol";
import { LibLaunchPadFactoryStorage } from "../libraries/LaunchPadFactoryStorage.sol";
import { IDiamondCut } from "../../common/diamonds/interfaces/IDiamondCut.sol";

contract LaunchPadFactoryAdminFacet is ILaunchPadFactoryAdmin {
    function removeLaunchpad(address launchpad) external override onlyAdmin {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        require(ds.isLaunchPad[launchpad], "LaunchPadFactory: LaunchPad does not exist");
        address owner = ds.launchPadOwner[launchpad];
        // remove launchpad from owner
        for (uint256 i = 0; i < ds.launchPadsByOwner[owner].length; i++) {
            if (ds.launchPadsByOwner[owner][i] == launchpad) {
                ds.launchPadsByOwner[owner][i] = ds.launchPadsByOwner[owner][ds.launchPadsByOwner[owner].length - 1];
                ds.launchPadsByOwner[owner].pop();
                break;
            }
        }
        address[] memory investors = ILaunchPadProject(launchpad).getAllInvestors();
        // remove launchpad from investors
        for (uint256 i = 0; i < investors.length; i++) {
            for (uint256 j = 0; j < ds.launchPadsByInvestor[investors[i]].length; j++) {
                if (ds.launchPadsByInvestor[investors[i]][j] == launchpad) {
                    ds.launchPadsByInvestor[investors[i]][j] = ds.launchPadsByInvestor[investors[i]][ds.launchPadsByInvestor[investors[i]].length - 1];
                    ds.launchPadsByInvestor[investors[i]].pop();
                    break;
                }
            }
        }
        // remove launchpad
        for (uint256 i = 0; i < ds.launchPads.length; i++) {
            if (ds.launchPads[i] == launchpad) {
                ds.launchPads[i] = ds.launchPads[ds.launchPads.length - 1];
                ds.launchPads.pop();
                break;
            }
        }
        ds.launchPadOwner[launchpad] = address(0);
        ds.isLaunchPad[launchpad] = false;
        emit LibLaunchPadFactoryStorage.LaunchpadRemoved(launchpad, owner);
    }

    function upgradeLaunchPadProjectFacets(
        address launchPad,
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) external onlyAdmin {
        IDiamondCut(launchPad).diamondCut(_diamondCut, _init, _calldata);
    }

    function updateMaxTokenCreationDeadline(uint256 newMaxTokenCreationDeadline) external override onlyAdmin {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        uint256 oldMaxTokenCreationDeadline = ds.maxTokenCreationDeadline;
        ds.maxTokenCreationDeadline = newMaxTokenCreationDeadline;
        emit LibLaunchPadFactoryStorage.MaxTokenCreationDeadlineUpdated(oldMaxTokenCreationDeadline, newMaxTokenCreationDeadline);
    }

    function updateSignerAddress(address newSignerAddress) external override onlyAdmin {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        address oldSignerAddress = ds.signerAddress;
        ds.signerAddress = newSignerAddress;
        emit LibLaunchPadFactoryStorage.SignerAddressUpdated(oldSignerAddress, newSignerAddress);
    }

    modifier onlyAdmin() {
        require(
            IAccessControl(address(this)).hasRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender),
            "LaunchPadFactory: Only admin can call this function"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ILaunchPadCommon {
    enum LaunchPadType {
        FlokiPadCreatedBefore,
        FlokiPadCreatedAfter
    }

    enum PaymentMethod {
        NATIVE,
        USD,
        TOKENFI
    }

    struct IdoInfo {
        bool enabled;
        address dexRouter;
        address pairToken;
        uint256 price;
        uint256 amountToList;
    }

    struct RefundInfo {
        uint256 penaltyFeePercent;
        uint256 expireDuration;
    }

    struct FundTarget {
        uint256 softCap;
        uint256 hardCap;
    }

    struct ReleaseSchedule {
        uint256 timestamp;
        uint256 percent;
    }

    struct ReleaseScheduleV2 {
        uint256 timestamp;
        uint256 percent;
        bool isVesting;
    }

    struct CreateErc20Input {
        string name;
        string symbol;
        string logo;
        uint8 decimals;
        uint256 maxSupply;
        address owner;
        uint256 treasuryReserved;
    }

    struct LaunchPadInfo {
        address owner;
        address tokenAddress;
        address paymentTokenAddress;
        uint256 price;
        FundTarget fundTarget;
        uint256 maxInvestPerWallet;
        uint256 startTimestamp;
        uint256 duration;
        uint256 tokenCreationDeadline;
        RefundInfo refundInfo;
        IdoInfo idoInfo;
    }

    struct CreateLaunchPadInput {
        LaunchPadType launchPadType;
        LaunchPadInfo launchPadInfo;
        ReleaseScheduleV2[] releaseSchedule;
        CreateErc20Input createErc20Input;
        address referrer;
        bool isSuperchargerEnabled;
        PaymentMethod paymentMethod;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";
import { IDiamondCut } from "../../common/diamonds/interfaces/IDiamondCut.sol";

interface ILaunchPadFactory is ILaunchPadCommon {
    struct StoreLaunchPadInput {
        ILaunchPadCommon.LaunchPadType launchPadType;
        address launchPadAddress;
        address owner;
        address referrer;
        uint256 usdPrice;
    }

    function addInvestorToLaunchPad(address investor) external;

    function createLaunchPad(ILaunchPadCommon.CreateLaunchPadInput memory input) external payable;

    function createTokenAfterICO(address launchPadAddress) external payable;

    function setExistingTokenAfterICO(address launchPad, address tokenAddress, uint256 amount) external;

    function setExistingTokenAfterTransfer(address launchPad, address tokenAddress) external;

    function createV2LiquidityPool(address launchPadAddress) external payable;

    function updateLaunchPadOwner(address tokenAddress, address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";
import { IDiamondCut } from "../../common/diamonds/interfaces/IDiamondCut.sol";

interface ILaunchPadFactoryAdmin is ILaunchPadCommon {
    function removeLaunchpad(address launchpad) external;

    function upgradeLaunchPadProjectFacets(address launchPad, IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) external;

    function updateMaxTokenCreationDeadline(uint256 newMaxTokenCreationDeadline) external;

    function updateSignerAddress(address newSignerAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadProject {
    struct PurchasedInfo {
        uint256 purchasedTokenAmount;
        uint256 claimedTokenAmount;
        uint256 paidTokenAmount;
    }

    struct BuyTokenInput {
        uint256 tokenAmount;
        uint256 tier;
        uint256 nonce;
        uint256 deadline;
        bytes signature;
    }

    function buyTokens(uint256 tokenAmount) external payable;

    function buyTokensWithSupercharger(BuyTokenInput memory input) external payable;

    function checkSignature(address wallet, uint256 tier, uint256 nonce, uint256 deadline, bytes memory signature) external view;

    function claimTokens() external;

    function getAllInvestors() external view returns (address[] memory);

    function getCurrentTier() external view returns (uint256);

    function getFeeShare() external view returns (uint256);

    function getHardCapPerTier(uint256 tier) external view returns (uint256);

    function getInvestorAddressByIndex(uint256 index) external view returns (address);

    function getInvestorsLength() external view returns (uint256);

    function getLaunchPadAddress() external view returns (address);

    function getLaunchPadInfo() external view returns (ILaunchPadCommon.LaunchPadInfo memory);

    function getMaxInvestPerWalletPerTier(uint256 tier) external view returns (uint256);

    function getNextNonce(address user) external view returns (uint256);

    function getProjectOwnerRole() external view returns (bytes32);

    function getPurchasedInfoByUser(address user) external view returns (PurchasedInfo memory);

    function getReleasedTokensPercentage() external view returns (uint256);

    function getReleaseSchedule() external view returns (ILaunchPadCommon.ReleaseScheduleV2[] memory);

    function getTokensAvailableToBeClaimed(address user) external view returns (uint256);

    function getTokenCreationDeadline() external view returns (uint256);

    function getTotalRaised() external view returns (uint256);

    function recoverSigner(bytes32 message, bytes memory signature) external view returns (address);

    function refund(uint256 tokenAmount) external;

    function refundOnSoftCapFailure() external;

    function refundOnTokenCreationExpired(uint256 tokenAmount) external;

    function setTokenAddress(address tokenAddress) external;

    function tokenDecimals() external view returns (uint256);

    function totalTokensClaimed() external view returns (uint256);

    function totalTokensSold() external view returns (uint256);

    function withdrawFees() external;

    function withdrawTokens(address tokenAddress) external;

    function withdrawTokensToRecipient(address tokenAddress, address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "../interfaces/ILaunchPadCommon.sol";
import { ILaunchPadFactory } from "../interfaces/ILaunchPadFactory.sol";
import { ILaunchPadProject } from "../interfaces/ILaunchPadProject.sol";

library LibLaunchPadFactoryStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("tokenfi.launchpad.factory.diamond.storage");

    struct DiamondStorage {
        address[] launchPads;
        mapping(address => address[]) launchPadsByOwner;
        mapping(address => address[]) launchPadsByInvestor;
        mapping(address => address) launchPadOwner;
        mapping(address => bool) isLaunchPad;
        mapping(address => ILaunchPadFactory.CreateErc20Input) tokenInfoByLaunchPadAddress;
        uint256 currentBlockLaunchPadCreated;
        uint256 currentBlockLaunchPadOwnerUpdated;
        address tokenLauncherERC20;
        address tokenLauncherStore;
        address tokenLauncherBuybackHandler;
        address launchPadProjectFacet;
        address accessControlFacet;
        address pausableFacet;
        address loupeFacet;
        address proxyFacet;
        address launchPadProjectDiamondInit;
        address signerAddress;
        uint256 maxTokenCreationDeadline;
        uint256[] superChargerMultiplierByTier;
        uint256[] superChargerHeadstartByTier;
        uint256[] superChargerTokensPercByTier;
    }

    event LaunchPadCreated(
        uint256 indexed previousBlock,
        ILaunchPadCommon.LaunchPadType indexed launchPadType,
        address indexed owner,
        ILaunchPadFactory.StoreLaunchPadInput launchPad
    );
    event LaunchPadOwnerUpdated(uint256 indexed previousBlock, address owner, address newOwner);
    event MaxTokenCreationDeadlineUpdated(uint256 indexed previousMaxTokenCreationDeadline, uint256 newMaxTokenCreationDeadline);
    event LaunchpadRemoved(address indexed launchPadAddress, address indexed owner);
    event SignerAddressUpdated(address indexed previousSignerAddress, address indexed newSignerAddress);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    function getLaunchPadProjectSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](31);
        functionSelectors[0] = ILaunchPadProject.buyTokens.selector;
        functionSelectors[1] = ILaunchPadProject.buyTokensWithSupercharger.selector;
        functionSelectors[2] = ILaunchPadProject.checkSignature.selector;
        functionSelectors[3] = ILaunchPadProject.claimTokens.selector;
        functionSelectors[4] = ILaunchPadProject.getAllInvestors.selector;
        functionSelectors[5] = ILaunchPadProject.getCurrentTier.selector;
        functionSelectors[6] = ILaunchPadProject.getFeeShare.selector;
        functionSelectors[7] = ILaunchPadProject.getHardCapPerTier.selector;
        functionSelectors[8] = ILaunchPadProject.getInvestorAddressByIndex.selector;
        functionSelectors[9] = ILaunchPadProject.getInvestorsLength.selector;
        functionSelectors[10] = ILaunchPadProject.getLaunchPadAddress.selector;
        functionSelectors[11] = ILaunchPadProject.getLaunchPadInfo.selector;
        functionSelectors[12] = ILaunchPadProject.getMaxInvestPerWalletPerTier.selector;
        functionSelectors[13] = ILaunchPadProject.getProjectOwnerRole.selector;
        functionSelectors[14] = ILaunchPadProject.getPurchasedInfoByUser.selector;
        functionSelectors[15] = ILaunchPadProject.getReleasedTokensPercentage.selector;
        functionSelectors[16] = ILaunchPadProject.getReleaseSchedule.selector;
        functionSelectors[17] = ILaunchPadProject.getTokensAvailableToBeClaimed.selector;
        functionSelectors[18] = ILaunchPadProject.getTokenCreationDeadline.selector;
        functionSelectors[19] = ILaunchPadProject.getTotalRaised.selector;
        functionSelectors[20] = ILaunchPadProject.recoverSigner.selector;
        functionSelectors[21] = ILaunchPadProject.refund.selector;
        functionSelectors[22] = ILaunchPadProject.refundOnSoftCapFailure.selector;
        functionSelectors[23] = ILaunchPadProject.refundOnTokenCreationExpired.selector;
        functionSelectors[24] = ILaunchPadProject.setTokenAddress.selector;
        functionSelectors[25] = ILaunchPadProject.tokenDecimals.selector;
        functionSelectors[26] = ILaunchPadProject.totalTokensClaimed.selector;
        functionSelectors[27] = ILaunchPadProject.totalTokensSold.selector;
        functionSelectors[28] = ILaunchPadProject.withdrawFees.selector;
        functionSelectors[29] = ILaunchPadProject.withdrawTokens.selector;
        functionSelectors[30] = ILaunchPadProject.withdrawTokensToRecipient.selector;

        return functionSelectors;
    }
}