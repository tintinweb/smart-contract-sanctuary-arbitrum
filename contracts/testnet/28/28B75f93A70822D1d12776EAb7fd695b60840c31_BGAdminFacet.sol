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
pragma solidity ^0.8.17;

import { DiamondOwnable } from "../helpers/DiamondOwnable.sol";
import { DiamondAccessControl } from "../helpers/DiamondAccessControl.sol";

// Storage imports
import { WithModifiers } from "../libraries/LibStorage.sol";
import { Errors } from "../helpers/Errors.sol";

contract BGAdminFacet is WithModifiers, DiamondAccessControl {
    event PauseStateChanged(bool paused);

    /**
     * @dev Pause the contract
     */
    function pause() external onlyGuardian notPaused {
        gs().paused = true;
        emit PauseStateChanged(true);
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyGuardian {
        if (!gs().paused) revert Errors.GameAlreadyUnPaused();
        gs().paused = false;
        emit PauseStateChanged(false);
    }

    /**
     * @dev Return the paused state
     */
    function isPaused() external view returns (bool) {
        return gs().paused;
    }

    /**
     * @dev Set the Magic address
     */
    function setMagic(address magic) external onlyOwner {
        if (magic == address(0)) revert Errors.InvalidAddress();
        gs().magic = magic;
    }

    /**
     * @dev Set the MagicSwap router address
     */
    function setMagicSwapRouter(address magicSwapRouter) external onlyOwner {
        if (magicSwapRouter == address(0)) revert Errors.InvalidAddress();
        gs().magicSwapRouter = magicSwapRouter;
    }

    /**
     * @dev Set the Magic/gFLY LP address
     */
    function setMagicGFlyLp(address magicGFlyLp) external onlyOwner {
        if (magicGFlyLp == address(0)) revert Errors.InvalidAddress();
        gs().magicGFlyLp = magicGFlyLp;
    }

    /**
     * @dev Set the Battlefly address
     */
    function setBattlefly(address battlefly) external onlyOwner {
        if (battlefly == address(0)) revert Errors.InvalidAddress();
        gs().battlefly = battlefly;
    }

    /**
     * @dev Set the Soulbound address
     */
    function setSoulbound(address soulbound) external onlyOwner {
        if (soulbound == address(0)) revert Errors.InvalidAddress();
        gs().soulbound = soulbound;
    }

    /**
     * @dev Set the GameV2 address
     */
    function setGameV2(address gameV2) external onlyOwner {
        if (gameV2 == address(0)) revert Errors.InvalidAddress();
        gs().gameV2 = gameV2;
    }

    /**
     * @dev Set the Payment Receiver address
     */
    function setPaymentReceiver(address paymentReceiver) external onlyOwner {
        if (paymentReceiver == address(0)) revert Errors.InvalidAddress();
        gs().paymentReceiver = paymentReceiver;
    }

    /**
     * @dev Set the USDC address
     */
    function setUSDC(address usdc) external onlyOwner {
        if (usdc == address(0)) revert Errors.InvalidAddress();
        gs().usdc = usdc;
    }

    /**
     * @dev Set the WETH address
     */
    function setWETH(address weth) external onlyOwner {
        if (weth == address(0)) revert Errors.InvalidAddress();
        gs().weth = weth;
    }

    /**
     * @dev Set the USDCDataFeedAddress address
     */
    function setUSDCDataFeedAddress(address usdcDataFeedAddress) external onlyOwner {
        if (usdcDataFeedAddress == address(0)) revert Errors.InvalidAddress();
        gs().usdcDataFeedAddress = usdcDataFeedAddress;
    }

    /**
     * @dev Set the ETHDataFeedAddress address
     */
    function setETHDataFeedAddress(address ethDataFeedAddress) external onlyOwner {
        if (ethDataFeedAddress == address(0)) revert Errors.InvalidAddress();
        gs().ethDataFeedAddress = ethDataFeedAddress;
    }

    /**
     * @dev Set the MagicDataFeedAddress address
     */
    function setMagicDataFeedAddress(address magicDataFeedAddress) external onlyOwner {
        if (magicDataFeedAddress == address(0)) revert Errors.InvalidAddress();
        gs().magicDataFeedAddress = magicDataFeedAddress;
    }

    /**
     * @dev Set the SushiswapRouter address
     */
    function setSushiswapRouter(address sushiswapRouter) external onlyOwner {
        if (sushiswapRouter == address(0)) revert Errors.InvalidAddress();
        gs().sushiswapRouter = sushiswapRouter;
    }

    /**
    * @dev Set the SequencerUptimeFeedAddress address
     */
    function setSequencerUptimeFeedAddress(address sequencerUptimeFeedAddress) external onlyOwner {
        if (sequencerUptimeFeedAddress == address(0)) revert Errors.InvalidAddress();
        gs().sequencerUptimeFeedAddress = sequencerUptimeFeedAddress;
    }

    /**
    * @dev Set the Sequencer Grace Period
     */
    function setSequencerGracePeriod(uint256 sequencerGracePeriod) external onlyOwner {
        gs().sequencerGracePeriod = sequencerGracePeriod;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC173 } from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC173.sol";
import { DiamondOwnable } from "./DiamondOwnable.sol";
import { WithStorage } from "../libraries/LibStorage.sol";

contract DiamondAccessControl is WithStorage, DiamondOwnable {
    function setGuardian(address account, bool state) external onlyOwner {
        gs().guardian[account] = state;
    }

    function isGuardian(address account) external view returns (bool) {
        return gs().guardian[account];
    }

    function setBattleflyBot(address account) external onlyOwner {
        gs().battleflyBot = account;
    }

    function isBattleflyBot(address account) external view returns (bool) {
        return (gs().battleflyBot == account);
    }

    function setSigner(address account, bool state) external onlyOwner {
        gs().signer[account] = state;
    }

    function isSigner(address account) external view returns (bool) {
        return gs().signer[account];
    }

    function setEmissionDepositor(address account, bool state) external onlyOwner {
        gs().emissionDepositor[account] = state;
    }

    function isEmissionDepositor(address account) external view returns (bool) {
        return gs().emissionDepositor[account];
    }

    function setBackendExecutor(address account, bool state) external onlyOwner {
        gs().backendExecutor[account] = state;
    }

    function isBackendExecutor(address account) external view returns (bool) {
        return gs().backendExecutor[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { LibDiamond } from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import { IERC173 } from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC173.sol";
import { WithModifiers } from "../libraries/LibStorage.sol";

contract DiamondOwnable is IERC173, WithModifiers {
    function transferOwnership(address account) external onlyOwner {
        LibDiamond.setContractOwner(account);
    }

    function owner() external view override returns (address) {
        return LibDiamond.contractOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Errors {
    error NotGuardian();
    error GamePaused();
    error GameAlreadyUnPaused();
    error UnsupportedCreditType();
    error InvalidArrayLength();
    error IncorrectTreasuresAmount();
    error InvalidAmount();
    error UnsupportedPaymentType();
    error InvalidAddress();
    error InsufficientMagicForLpAmount();
    error InsufficientGFlyForLpAmount();
    error IdenticalAddresses();
    error NotBattleflyBot();

    error NotSoulbound();
    error IncorrectSigner(address signer);
    error NotOwnerOfBattlefly(address account, uint256 tokenId, uint256 tokenType);
    error InvalidTokenType(uint256 tokenId, uint256 tokenType);

    error InvalidEpoch(uint256 epoch, uint256 emissionsEpoch);
    error InvalidProof(bytes32[] merkleProof, bytes32 merkleRoot, bytes32 node);
    error NotEmissionDepositor();

    error NotBackendExecutor();

    error InvalidCurrency();
    error InvalidEthAmount();
    error EthTransferFailed();

    error NotGameV2();
    error InsufficientAmount();
    error SequencerDown();
    error GracePeriodNotOver();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { LibDiamond } from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import { Errors } from "../helpers/Errors.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

enum PaymentType {
    // DO NOT CHANGE ORDER AND ALWAYS ADD AT THE BOTTOM
    MAGIC,
    GFLY,
    TREASURES
}

struct BattleflyGameStorage {
    // DO NOT CHANGE ORDER AND ALWAYS ADD AT THE BOTTOM

    bool paused;
    uint256 gFlyPerCredit;
    uint256 treasuresPerCredit;
    address diamondAddress;
    address gFlyReceiver;
    address treasureReceiver;
    address gFLY;
    address treasures;
    mapping(uint256 => bool) creditTypes;
    mapping(address => bool) guardian;
    address magic;
    uint256 magicPerCredit;
    // automatic Magic/gFLY LP setup
    address magicSwapRouter;
    address magicGFlyLp;
    address lpReceiver;
    uint256 magicForLp;
    uint256 magicLpTreshold;
    uint256 gFlyForLp;
    uint256 gFlyLpTreshold;
    address battleflyBot;
    uint256 bpsDenominator;
    uint256 slippageInBPS;
    address battlefly;
    address soulbound;
    mapping(uint256 => mapping(uint256 => address)) battleflyOwner;
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) battlefliesOfOwner;
    mapping(address => bool) signer;
    bytes32 merkleRoot;
    uint256 emissionsEpoch;
    mapping(address => uint256) claimedMagicRNGEmissions;
    address gameV2;
    mapping(address => bool) emissionDepositor;
    mapping(uint256 => uint256) magicRNGEmissionsForProcessingEpoch;
    uint256 processingEpoch;
    mapping(address => bool) backendExecutor;
    address paymentReceiver;
    address usdc;
    uint256 magicReserve;
    uint256 ethReserve;
    uint256 usdcReserve;
    address weth;
    address usdcDataFeedAddress;
    address ethDataFeedAddress;
    address magicDataFeedAddress;
    address sushiswapRouter;
    address sequencerUptimeFeedAddress;
    uint256 sequencerGracePeriod;
}

/**
 * All of Battlefly's wastelands storage is stored in a single WastelandStorage struct.
 *
 * The Diamond Storage pattern (https://dev.to/mudgen/how-diamond-storage-works-90e)
 * is used to set the struct at a specific place in contract storage. The pattern
 * recommends that the hash of a specific namespace (e.g. "battlefly.storage.game")
 * be used as the slot to store the struct.
 *
 * Additionally, the Diamond Storage pattern can be used to access and change state inside
 * of Library contract code (https://dev.to/mudgen/solidity-libraries-can-t-have-state-variables-oh-yes-they-can-3ke9).
 * Instead of using `LibStorage.wastelandStorage()` directly, a Library will probably
 * define a convenience function to accessing state, similar to the `gs()` function provided
 * in the `WithStorage` base contract below.
 *
 * This pattern was chosen over the AppStorage pattern (https://dev.to/mudgen/appstorage-pattern-for-state-variables-in-solidity-3lki)
 * because AppStorage seems to indicate it doesn't support additional state in contracts.
 * This becomes a problem when using base contracts that manage their own state internally.
 *
 * There are a few caveats to this approach:
 * 1. State must always be loaded through a function (`LibStorage.gameStorage()`)
 *    instead of accessing it as a variable directly. The `WithStorage` base contract
 *    below provides convenience functions, such as `gs()`, for accessing storage.
 * 2. Although inherited contracts can have their own state, top level contracts must
 *    ONLY use the Diamond Storage. This seems to be due to how contract inheritance
 *    calculates contract storage layout.
 * 3. The same namespace can't be used for multiple structs. However, new namespaces can
 *    be added to the contract to add additional storage structs.
 * 4. If a contract is deployed using the Diamond Storage, you must ONLY ADD fields to the
 *    very end of the struct during upgrades. During an upgrade, if any fields get added,
 *    removed, or changed at the beginning or middle of the existing struct, the
 *    entire layout of the storage will be broken.
 * 5. Avoid structs within the Diamond Storage struct, as these nested structs cannot be
 *    changed during upgrades without breaking the layout of storage. Structs inside of
 *    mappings are fine because their storage layout is different. Consider creating a new
 *    Diamond storage for each struct.
 *
 * More information on Solidity contract storage layout is available at:
 * https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html
 *
 * Nick Mudge, the author of the Diamond Pattern and creator of Diamond Storage pattern,
 * wrote about the benefits of the Diamond Storage pattern over other storage patterns at
 * https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb#bfc1
 */
library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of Wastelands
    bytes32 constant BATTLEFLY_GAME_STORAGE_POSITION = keccak256("battlefly.storage.game");

    function gameStorage() internal pure returns (BattleflyGameStorage storage gs) {
        bytes32 position = BATTLEFLY_GAME_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }
}

/**
 * The `WithStorage` contract provides a base contract for Facet contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.gameStorage()` to just `gs()`.
 *
 * To understand why the storage structs must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */
contract WithStorage {
    function gs() internal pure returns (BattleflyGameStorage storage) {
        return LibStorage.gameStorage();
    }
}

contract WithModifiers is WithStorage {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyGuardian() {
        if (!gs().guardian[msg.sender]) revert Errors.NotGuardian();
        _;
    }

    modifier onlySoulbound() {
        if (msg.sender != gs().soulbound) revert Errors.NotSoulbound();
        _;
    }

    modifier onlyBattleflyBot() {
        if (gs().battleflyBot != msg.sender) revert Errors.NotBattleflyBot();
        _;
    }

    modifier onlyGameV2() {
        if (gs().gameV2 != msg.sender) revert Errors.NotGameV2();
        _;
    }

    modifier onlyEmissionDepositor() {
        if (!gs().emissionDepositor[msg.sender]) revert Errors.NotEmissionDepositor();
        _;
    }

    modifier onlyBackendExecutor() {
        if (!gs().backendExecutor[msg.sender]) revert Errors.NotBackendExecutor();
        _;
    }

    modifier notPaused() {
        if (gs().paused) revert Errors.GamePaused();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
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
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
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
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
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
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
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
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
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
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
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
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
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