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

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
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

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 len = _length(set._inner);
        bytes32[] memory arr = new bytes32[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = _length(set._inner);
        address[] memory arr = new address[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 len = _length(set._inner);
        uint256[] memory arr = new uint256[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
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

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { OTCAdminStorage } from "../storage/OTCAdminStorage.sol";
import { OTCVestingStorage } from "../storage/OTCVestingStorage.sol";
import { OTCMarketStorage } from "../storage/OTCMarketStorage.sol";
import { IOTCAdmin } from "../interfaces/IOTCAdmin.sol";
import { DiamondOwnable } from "../helpers/DiamondOwnable.sol";
import { WithACLModifiers, WithCommonModifiers } from "../utils/Mixins.sol";

contract OTCAdminFacet is IOTCAdmin, WithACLModifiers, WithCommonModifiers, DiamondOwnable {
    ///@inheritdoc IOTCAdmin
    function pause() external onlyPauseGuardians {
        OTCAdminStorage.layout().paused = true;
    }

    ///@inheritdoc IOTCAdmin
    function unpause() external onlyPauseGuardians {
        OTCAdminStorage.layout().paused = false;
    }

    ///@inheritdoc IOTCAdmin
    function addAdmin(address admin) external nonZeroAddress(admin) onlyAdmin {
        OTCAdminStorage.layout().admins[admin] = true;
        emit AdminAdded(admin);
    }

    ///@inheritdoc IOTCAdmin
    function removeVestingManager(address vestingManager) external nonZeroAddress(vestingManager) onlyAdmin {
        OTCAdminStorage.layout().vestingManagers[vestingManager] = false;
        emit VestingManagerRemoved(vestingManager);
    }

    ///@inheritdoc IOTCAdmin
    function addVestingManager(address vestingManager) external nonZeroAddress(vestingManager) onlyAdmin {
        OTCAdminStorage.layout().vestingManagers[vestingManager] = true;
        emit VestingManagerAdded(vestingManager);
    }

    ///@inheritdoc IOTCAdmin
    function removeBattleflyBot(address battleflyBot) external nonZeroAddress(battleflyBot) onlyAdmin {
        OTCAdminStorage.layout().battleflyBots[battleflyBot] = false;
        emit BattleflyBotRemoved(battleflyBot);
    }

    ///@inheritdoc IOTCAdmin
    function addBattleflyBot(address battleflyBot) external nonZeroAddress(battleflyBot) onlyAdmin {
        OTCAdminStorage.layout().battleflyBots[battleflyBot] = true;
        emit BattleflyBotAdded(battleflyBot);
    }

    ///@inheritdoc IOTCAdmin
    function removeAdmin(address admin) external nonZeroAddress(admin) onlyAdmin {
        OTCAdminStorage.layout().admins[admin] = false;
        emit AdminRemoved(admin);
    }

    ///@inheritdoc IOTCAdmin
    function addPauseGuardian(address pauseGuardian) external nonZeroAddress(pauseGuardian) onlyAdmin {
        OTCAdminStorage.layout().pauseGuardians[pauseGuardian] = true;
        emit PauseGuardianAdded(pauseGuardian);
    }

    ///@inheritdoc IOTCAdmin
    function removePauseGuardian(address pauseGuardian) external onlyAdmin {
        OTCAdminStorage.layout().pauseGuardians[pauseGuardian] = false;
        emit PauseGuardianRemoved(pauseGuardian);
    }

    ///@inheritdoc IOTCAdmin
    function isAdmin(address account) public view returns (bool) {
        return OTCAdminStorage.layout().admins[account];
    }

    ///@inheritdoc IOTCAdmin
    function isBattleflyBot(address account) public view returns (bool) {
        return OTCAdminStorage.layout().battleflyBots[account];
    }

    ///@inheritdoc IOTCAdmin
    function isPauseGuardian(address account) public view returns (bool) {
        return OTCAdminStorage.layout().pauseGuardians[account];
    }

    ///@inheritdoc IOTCAdmin
    function isVestingManager(address account) public view returns (bool) {
        return OTCAdminStorage.layout().vestingManagers[account];
    }

    ///@inheritdoc IOTCAdmin
    function setGFly(address gFLY) external nonZeroAddress(gFLY) onlyAdmin {
        OTCVestingStorage.layout().gFLY = gFLY;
    }

    ///@inheritdoc IOTCAdmin
    function setVestedGFly(address vgFLY) external nonZeroAddress(vgFLY) onlyAdmin {
        OTCVestingStorage.layout().vestedGFly = vgFLY;
    }

    ///@inheritdoc IOTCAdmin
    function setUSDC(address usdc) external nonZeroAddress(usdc) onlyAdmin {
        OTCMarketStorage.layout().USDC = usdc;
    }

    ///@inheritdoc IOTCAdmin
    function setGFlyStaking(address gFlyStaking) external nonZeroAddress(gFlyStaking) onlyAdmin {
        OTCMarketStorage.layout().gFlyStaking = gFlyStaking;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import { LibDiamond } from "./LibDiamond.sol";
import { IERC173 } from "@solidstate/contracts/interfaces/IERC173.sol";

abstract contract DiamondOwnable is IERC173 {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() public view returns (address) {
        return LibDiamond.contractOwner();
    }

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external onlyOwner {
        LibDiamond.setContractOwner(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
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

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import { IERC173 } from "@solidstate/contracts/interfaces/IERC173.sol";

/**
 * @title OTC Admin
 * @notice Interface for Access Control List management
 *         Roles:
 *           - Admin: Can perform top level restricted functions and add
 *                    and remove any other role except contract owner
 *           - Pause Guardian:
 *                    Can pause and unpause the system
 *           - Vesting Manager:
 *                    Can manage OTC vesting positions
 *           - Battlefly Bot:
 *                    Can execute CRON functions
 */
interface IOTCAdmin is IERC173 {
    event AdminAdded(address admin);
    event AdminRemoved(address admin);
    event VestingManagerAdded(address vestingManager);
    event VestingManagerRemoved(address vestingManager);
    event BattleflyBotAdded(address battleflyBot);
    event BattleflyBotRemoved(address battleflyBot);
    event PauseGuardianAdded(address pauseGuardian);
    event PauseGuardianRemoved(address pauseGuardian);

    /**
     * @notice Pauses the contract
     * @dev This function should be access restricted
     */
    function pause() external;

    /**
     * @notice Unpauses the contract
     * @dev This function should be access restricted
     */
    function unpause() external;

    /**
     * @notice Adds a new admin
     * @dev This function should be access restricted
     * @param admin The new admin
     */
    function addAdmin(address admin) external;

    /**
     * @notice Removes an existing admin
     * @dev This function should be access restricted
     * @param admin The admin to remove
     */
    function removeAdmin(address admin) external;

    /**
     * @notice Removes an existing battlefly bot
     * @dev This function should be access restricted
     * @param battleflyBot The battlefly bot to remove
     */
    function addBattleflyBot(address battleflyBot) external;

    /**
     * @notice Removes an existing battlefly bot
     * @dev This function should be access restricted
     * @param battleflyBot The battlefly bot to remove
     */
    function removeBattleflyBot(address battleflyBot) external;

    /**
     * @notice Removes an existing vesting manager
     * @dev This function should be access restricted
     * @param vestingManager The vesting manager to remove
     */
    function addVestingManager(address vestingManager) external;

    /**
     * @notice Removes an existing vesting manager
     * @dev This function should be access restricted
     * @param vestingManager The vesting manager to remove
     */
    function removeVestingManager(address vestingManager) external;

    /**
     * @notice Adds a new pause guardian
     * @dev This function should be access restricted
     * @param pauseGuardian The new pause guardian
     */
    function addPauseGuardian(address pauseGuardian) external;

    /**
     * @notice Removes an existing pause guardian
     * @dev This function should be access restricted
     * @param pauseGuardian The pause guardian to remove
     */
    function removePauseGuardian(address pauseGuardian) external;

    /**
     * @notice Attest if an address is an admin
     * @param account The address to check
     * @return True if the address is an admin
     */
    function isAdmin(address account) external view returns (bool);

    /**
     * @notice Attest if an address is a pause guardian
     * @param account The address to check
     * @return True if the address is a pause guardian
     */
    function isPauseGuardian(address account) external view returns (bool);

    /**
     * @notice Attest if an address is a vesting manager
     * @param account The address to check
     * @return True if the address is a vesting manager
     */
    function isVestingManager(address account) external view returns (bool);

    /**
     * @notice Attest if an address is a battlefly bot
     * @param account The address to check
     * @return True if the address is a battlefly bot
     */
    function isBattleflyBot(address account) external view returns (bool);

    /**
     * @notice Set the gFLY address
     * @param gFLY The gFLY address
     */
    function setGFly(address gFLY) external;

    /**
     * @notice Set the vgFLY address
     * @param vgFLY The vgFLY address
     */
    function setVestedGFly(address vgFLY) external;

    /**
     * @notice Set the USDC address
     * @param usdc The USDC address
     */
    function setUSDC(address usdc) external;

    /**
     * @notice Set the gFlyStaking address
     * @param gFlyStaking The gFlyStaking address
     */
    function setGFlyStaking(address gFlyStaking) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library OTCAdminStorage {
    struct Layout {
        bool paused;
        mapping(address => bool) admins;
        mapping(address => bool) pauseGuardians;
        mapping(address => bool) vestingManagers;
        mapping(address => bool) battleflyBots;
        // IMPORTANT: For update append only, do not re-order fields!
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("battlefly.storage.otc.admin");

    /* solhint-disable */
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

struct OTCOffer {
    address owner;
    bool processed;
    uint256 deadline;
    uint256 startTime;
    uint256 amountInWei;
    uint256 usdcPerUnit;
    uint256 filled;
    //0 = treasury, 1 = vgFLY, 2 = staked gFLY
    uint256[3] filledPerBracket;
    //0 = treasury, 1 = vgFLY, 2 = staked gFLY
    uint256[3] percentagesInBPS;
}

struct Proposal {
    address owner;
    uint8 proposalType;
    uint256 claimableUSDC;
    uint256 claimableGFly;
    uint256 soldGFly;
    uint256 rootId;
    uint256 maxSellable;
    uint256 notToExceed;
    bool useMax;
}

library OTCMarketStorage {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Layout {
        bool paused;
        uint256 totalOffers;
        uint256 totalProposals;
        uint256[3] percentagesInBPS;
        address USDC;
        address gFlyStaking;
        EnumerableSet.UintSet offersToProcess;
        mapping(uint256 => OTCOffer) otcOffers;
        mapping(uint256 => Proposal) proposals;
        mapping(uint256 => EnumerableSet.UintSet) proposalsForOffer;
        mapping(address => EnumerableSet.UintSet) allUserOffers;
        mapping(address => EnumerableSet.UintSet) allUserProposals;
        mapping(uint256 => mapping(uint256 => bool)) pendingProposalsPerBracket;
        mapping(uint256 => mapping(uint256 => uint256)) reservedForProposalsPerBracket;
        // IMPORTANT: For update append only, do not re-order fields!
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("battlefly.storage.otc.market");

    /* solhint-disable */
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import { StructuredLinkedList } from "solidity-linked-list/contracts/StructuredLinkedList.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

struct VestingPosition {
    address owner;
    uint256 distribution;
    uint256 initialAllocation;
    uint256 claimed;
    bool burnable;
    uint256 burnt;
    uint256 startTime;
}

struct Distribution {
    address owner;
    uint256 rootId;
    uint256 employmentTimestamp;
    uint256 initialAllocation;
    uint256 distributionIntervalStart;
    uint256 distributionIntervalHead;
    uint256 totalIntervals;
}

struct DistributionInterval {
    uint256 start;
    uint256 end;
    uint256 claimed;
    uint256 claimable;
    uint256 totalOwners;
}

struct IntervalOwnership {
    address owner;
    uint256 percentageInWei;
}

library OTCVestingStorage {
    using StructuredLinkedList for StructuredLinkedList.List;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Layout {
        uint256 totalVestingPositions;
        uint256 totalDistributions;
        uint256 totalIntervals;
        address vestedGFly;
        address gFLY;
        address treasury;
        mapping(uint256 => VestingPosition) vestingPositions;
        mapping(uint256 => Distribution) distributions;
        mapping(uint256 => DistributionInterval) distributionIntervals;
        mapping(uint256 => StructuredLinkedList.List) distributionIntervalIds;
        mapping(address => EnumerableSet.UintSet) allUserVestingPositions;
        mapping(uint256 => mapping(address => uint256)) claimableGFlyPerDistribution;
        mapping(uint256 => EnumerableSet.AddressSet) ownersPerDistributionInterval;
        mapping(uint256 => mapping(address => IntervalOwnership)) ownershipPerDistributionInterval;
        // IMPORTANT: For update append only, do not re-order fields!
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("battlefly.storage.otc.vesting");

    //constants
    uint256 public constant MONTH = 2628000;
    uint256 public constant ONE = 1e18;

    /* solhint-disable */
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../storage/OTCAdminStorage.sol";

abstract contract WithCommonModifiers {
    error IllegalAddress(address illegalAddress);

    modifier nonZeroAddress(address toCheck) {
        if (toCheck == address(0)) revert IllegalAddress(toCheck);
        _;
    }
}

abstract contract WithPausableModifiers {
    error Paused();
    error NotPaused();

    modifier whenNotPaused() {
        if (OTCAdminStorage.layout().paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!OTCAdminStorage.layout().paused) revert NotPaused();
        _;
    }
}

abstract contract WithACLModifiers {
    error AccessDenied();

    modifier onlyAdmin() {
        if (!OTCAdminStorage.layout().admins[msg.sender]) revert AccessDenied();
        _;
    }

    modifier onlyPauseGuardians() {
        if (!OTCAdminStorage.layout().pauseGuardians[msg.sender]) revert AccessDenied();
        _;
    }

    modifier onlyVestingManagers() {
        if (!OTCAdminStorage.layout().vestingManagers[msg.sender]) revert AccessDenied();
        _;
    }

    modifier onlyBattleflyBots() {
        if (!OTCAdminStorage.layout().battleflyBots[msg.sender]) revert AccessDenied();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStructureInterface {
    function getValue(uint256 _id) external view returns (uint256);
}

/**
 * @title StructuredLinkedList
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */
library StructuredLinkedList {
    uint256 private constant _NULL = 0;
    uint256 private constant _HEAD = 0;

    bool private constant _PREV = false;
    bool private constant _NEXT = true;

    struct List {
        uint256 size;
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function listExists(List storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function nodeExists(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
            if (self.list[_HEAD][_NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function sizeOf(List storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
     */
    function getNode(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function getAdjacent(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function getPreviousNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _PREV);
    }

    /**
     * @dev Can be used before `insert` to build an ordered list.
     * @dev Get the node and then `insertBefore` or `insertAfter` basing on your list order.
     * @dev If you want to order basing on other than `structure.getValue()` override this function
     * @param self stored linked list from contract
     * @param _structure the structure instance
     * @param _value value to seek
     * @return uint256 next node with a value less than _value
     */
    function getSortedSpot(List storage self, address _structure, uint256 _value) internal view returns (uint256) {
        if (sizeOf(self) == 0) {
            return 0;
        }

        uint256 next;
        (, next) = getAdjacent(self, _HEAD, _NEXT);
        while ((next != 0) && ((_value < IStructureInterface(_structure).getValue(next)) != _NEXT)) {
            next = self.list[next][_NEXT];
        }
        return next;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertAfter(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertBefore(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function remove(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; // NOT: SafeMath library should be used here to decrement.

        return _node;
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @return bool true if success, false otherwise
     */
    function pushFront(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    /**
     * @dev Pushes an entry to the tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the tail
     * @return bool true if success, false otherwise
     */
    function pushBack(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    /**
     * @dev Pops the first entry from the head of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popFront(List storage self) internal returns (uint256) {
        return _pop(self, _NEXT);
    }

    /**
     * @dev Pops the first entry from the tail of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popBack(List storage self) internal returns (uint256) {
        return _pop(self, _PREV);
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (_NEXT) or tail (_PREV)
     * @return bool true if success, false otherwise
     */
    function _push(List storage self, uint256 _node, bool _direction) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (_NEXT) or the tail (_PREV)
     * @return uint256 the removed node
     */
    function _pop(List storage self, bool _direction) private returns (uint256) {
        uint256 adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function _insert(List storage self, uint256 _node, uint256 _new, bool _direction) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _link node to link to in the _direction
     * @param _direction direction to insert node in
     */
    function _createLink(List storage self, uint256 _node, uint256 _link, bool _direction) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }
}