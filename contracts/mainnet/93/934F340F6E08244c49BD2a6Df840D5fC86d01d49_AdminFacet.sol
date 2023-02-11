// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.18;
import "./shared/Structs.sol";

struct AppStorage {
    // Re-entrancy guard for functions that make external calls
    uint8 _status;
    uint256 latestRequestId;
    // Protocol addresses
    address sequencer;
    address proposedSequencer;
    address treasury;
    address[] beacons;
    // Reserve uint space for additional future config kv stores
    uint256[48] configUints;
    uint256[16] gasEstimates;
    // Client Deposits & Reserved Amounts
    mapping(address client => uint256 value) ethDeposit;
    mapping(address client => uint256 reserved) ethReserved;
    // Beacon Stores
    mapping(address beacon => uint256 index) beaconIndex;
    mapping(address beacon => Beacon data) beacon;
    // Request Stores
    mapping(uint256 id => bytes32 result) results;
    mapping(uint256 id => bytes32 dataHash) requestToHash; // The hash of the request data
    mapping(uint256 id => bytes10[2] vrfHashes) requestToVrfHashes; // The submitted hashes from beacons
    mapping(uint256 id => uint256 feePaid) requestToFeePaid;
    mapping(uint256 id => uint256 feeRefunded) requestToFeeRefunded;
    // Collateral
    mapping(address beacon => uint256 value) ethCollateral;
}

// SPDX-License-Identifier: BUSL-1.1
/// @title Randomizer Admin Functions
/// @author Dean van Dugteren (https://github.com/deanpress)
/// @notice Administrative functions, variables, and constants used by Randomizer.

pragma solidity ^0.8.18;
import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../shared/Structs.sol";
import "../libraries/Constants.sol";
import "../libraries/Events.sol";
import "../AppStorage.sol";

contract AdminFacet {
    AppStorage internal s;

    /* Errors */
    error Unauthorized();
    error NoProposedSequencer();

    /* Events */
    event SequencerProposed(address indexed currentSequencer, address indexed newSequencer);
    event ProposeSequencerCanceled(address indexed proposedSequencer, address indexed currentSequencer);
    event UpdateGasConfig(uint256 indexed key, uint256 oldValue, uint256 newValue);
    event UpdateContractConfig(uint256 indexed key, uint256 oldValue, uint256 newValue);

    /* Functions */
    /// @notice Returns the current treasury address
    function treasury() external view returns (address treasury_) {
        treasury_ = s.treasury;
    }

    /// @notice Returns the current sequencer address
    function sequencer() external view returns (address sequencer_) {
        sequencer_ = s.sequencer;
    }

    /// @notice Returns the address of the proposed sequencer
    function proposedSequencer() external view returns (address proposedSequencer_) {
        proposedSequencer_ = s.proposedSequencer;
    }

    /// @notice Returns the value of a contract configuration key
    function configUint(uint256 key) external view returns (uint256) {
        return s.configUints[key];
    }

    /// @notice Returns the list of uint256 config values
    function configUints() external view returns (uint256[48] memory) {
        return s.configUints;
    }

    /// @notice Returns the value of a gas estimate key
    function gasEstimate(uint256 key) external view returns (uint256) {
        return s.gasEstimates[key];
    }

    /// @notice Returns all gas estimate values
    function gasEstimates() external view returns (uint256[16] memory) {
        return s.gasEstimates;
    }

    /// @notice The sequencer can propose a new address to be the sequencer.
    function proposeSequencer(address _proposed) external {
        if (msg.sender != s.sequencer) revert Unauthorized();
        s.proposedSequencer = _proposed;
        emit SequencerProposed(s.sequencer, _proposed);
    }

    /// @notice The proposed sequencer can accept the role.
    function acceptSequencer() external {
        if (msg.sender != s.proposedSequencer) revert Unauthorized();
        emit Events.TransferSequencer(s.sequencer, msg.sender);
        s.sequencer = msg.sender;
        s.proposedSequencer = address(0);
    }

    /// @notice The current or proposed sequencer can cancel the new sequencer proposal.
    function cancelProposeSequencer() external {
        if (msg.sender != s.sequencer && msg.sender != s.proposedSequencer) revert Unauthorized();
        if (s.proposedSequencer == address(0)) revert NoProposedSequencer();
        emit ProposeSequencerCanceled(s.proposedSequencer, s.sequencer);
        s.proposedSequencer = address(0);
    }

    /// @notice Set the contract's treasury address
    function setTreasury(address _treasury) external {
        LibDiamond.enforceIsContractOwner();
        emit Events.SetTreasury(s.treasury, _treasury);
        s.treasury = _treasury;
    }

    /// @notice Set the value of a contract configuration key
    function setConfigUint(uint256 key, uint256 _value) external {
        LibDiamond.enforceIsContractOwner();
        emit UpdateContractConfig(key, s.configUints[key], _value);
        s.configUints[key] = _value;
    }

    /// @notice Set the value of a gas estimate key
    function setGasEstimate(uint256 key, uint256 _value) external {
        LibDiamond.enforceIsContractOwner();
        emit UpdateGasConfig(key, s.gasEstimates[key], _value);
        s.gasEstimates[key] = _value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

library Constants {
    // Config keys for configUints
    uint256 constant CKEY_MIN_STAKE_ETH = 0;
    uint256 constant CKEY_EXPIRATION_BLOCKS = 1;
    uint256 constant CKEY_EXPIRATION_SECONDS = 2;
    uint256 constant CKEY_REQUEST_MIN_GAS_LIMIT = 3;
    uint256 constant CKEY_REQUEST_MAX_GAS_LIMIT = 4;
    uint256 constant CKEY_BEACON_FEE = 5;
    uint256 constant CKEY_MAX_STRIKES = 6;
    uint256 constant CKEY_MAX_CONSECUTIVE_SUBMISSIONS = 7;
    uint256 constant CKEY_MIN_CONFIRMATIONS = 8;
    uint256 constant CKEY_MAX_CONFIRMATIONS = 9;

    // Gas keys for estimateGas
    uint256 constant GKEY_OFFSET_SUBMIT = 0;
    uint256 constant GKEY_OFFSET_FINAL_SUBMIT = 1;
    uint256 constant GKEY_OFFSET_RENEW = 2;
    uint256 constant GKEY_TOTAL_SUBMIT = 3;
    uint256 constant GKEY_GAS_PER_BEACON_SELECT = 4;

    // Re-entrancy statuses
    uint8 constant STATUS_NOT_ENTERED = 1;
    uint8 constant STATUS_ENTERED = 2;

    // ChargeEth event types
    uint8 constant CHARGE_TYPE_CLIENT_TO_BEACON = 0;
    uint8 constant CHARGE_TYPE_BEACON_TO_CLIENT = 1;
    uint8 constant CHARGE_TYPE_BEACON_TO_BEACON = 2;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

// Events that are shared across Randomizer facets
import "../shared/Structs.sol";

library Events {
    /// @notice Emits when ETH is charged between accounts
    /// @param chargeType 0: client to beacon, 1: beacon to client, 2: beacon to beacon
    /// @param from address of the sender
    /// @param to address of the recipient
    /// @param amount amount of ETH charged
    event ChargeEth(address indexed from, address indexed to, uint256 amount, uint8 chargeType);
    /// @notice Emits when a client deposits ETH
    /// @param account address of the client
    /// @param amount amount of ETH deposited
    event ClientDepositEth(address indexed account, uint256 amount);
    /// @notice Emits when a beacon stakes ETH
    /// @param account address of the beacon
    /// @param amount amount of ETH deposited
    event BeaconDepositEth(address indexed account, uint256 amount);
    /// @notice Emits when a beacon is unregistered
    /// @param beacon address of the unregistered beacon
    /// @param kicked boolean indicating if the beacon was kicked or voluntarily unregistered
    /// @param strikes number of strikes the beacon had before being unregistered
    event UnregisterBeacon(address indexed beacon, bool indexed kicked, uint8 strikes);
    /// @notice Emits when a final beacon is selected for a request
    /// @param id request id
    /// @param beacon address of the beacon added
    /// @param seed seed used for the random value generation
    /// @param timestamp new timestamp of the request
    event RequestBeacon(uint256 indexed id, address indexed beacon, bytes32 seed, uint256 timestamp);
    /// @notice Emits an event with the final random value
    /// @param id request id
    /// @param result result value
    event Result(uint256 indexed id, bytes32 result);
    /// @notice Emits when ETH is withdrawn
    /// @param to address of the recipient
    /// @param amount amount of ETH withdrawn
    event WithdrawEth(address indexed to, uint256 amount);
    /// @notice Emits if a request is retried (has new beacons)
    /// @param id request id
    /// @param request SRequestEventData struct containing request data
    /// @param chargedBeacon address of the beacon that was charged
    /// @param renewer address of the renewer
    /// @param ethToClient amount of ETH returned to the client
    /// @param ethToRenewer amount of ETH returned to the caller
    event Retry(
        uint256 indexed id,
        SRequestEventData request,
        address indexed chargedBeacon,
        address indexed renewer,
        uint256 ethToClient,
        uint256 ethToRenewer
    );
    /// @notice Emits when the sequencer is transferred from one address to another
    /// @param previousSequencer address of the previous sequencer
    /// @param newSequencer address of the new sequencer
    event TransferSequencer(address indexed previousSequencer, address indexed newSequencer);
    /// @notice Emits when the treasury address is set
    /// @param previousTreasury address of the previous treasury
    /// @param newTreasury address of the new treasury
    event SetTreasury(address indexed previousTreasury, address indexed newTreasury);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

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
        // Owner of the contract
        address contractOwner;
        // Proposed owner of the contract
        address proposedOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipProposed(address indexed previousOwner, address indexed newOwner);
    event ProposeOwnershipCanceled(address indexed proposedOwner, address indexed currentOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function setProposedContractOwner(address _proposedOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.proposedOwner = _proposedOwner;
        emit OwnershipProposed(ds.contractOwner, _proposedOwner);
    }

    function acceptProposedContractOwner() internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = ds.proposedOwner;
        ds.proposedOwner = address(0);
        emit OwnershipTransferred(previousOwner, ds.contractOwner);
    }

    function cancelProposedContractOwner() internal {
        DiamondStorage storage ds = diamondStorage();
        address previousProposedOwner = ds.proposedOwner;
        ds.proposedOwner = address(0);
        emit ProposeOwnershipCanceled(previousProposedOwner, ds.contractOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function proposedOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().proposedOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "Unauthorized: Must be contract owner");
    }

    function enforceIsProposedContractOwner() internal view {
        require(
            msg.sender == diamondStorage().proposedOwner,
            "Unauthorized: Must be proposed contract owner"
        );
    }

    function enforceIsCurrentOrProposedContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner || msg.sender == diamondStorage().proposedOwner,
            "Unauthorized: Must be current or proposed contract owner"
        );
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
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
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
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
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

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                lastSelectorPosition
            ];
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
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

struct SPackedSubmitData {
    uint256 id;
    SRandomUintData data;
    SFastVerifyData vrf;
}

// publicKey: [pubKey-x, pubKey-y]
// proof: [gamma-x, gamma-y, c, s]
// uPoint: [uPointX, uPointY]
// vComponents: [sHX, sHY, cGammaX, cGammaY]
struct SFastVerifyData {
    uint256[4] proof;
    uint256[2] uPoint;
    uint256[4] vComponents;
}

struct SPackedUintData {
    uint256 id;
    SRandomUintData data;
}

struct SRandomUintData {
    uint256 ethReserved;
    uint256 beaconFee;
    uint256 height;
    uint256 timestamp;
    uint256 expirationBlocks;
    uint256 expirationSeconds;
    uint256 callbackGasLimit;
    uint256 minConfirmations;
}

struct SRequestEventData {
    uint256 ethReserved;
    uint256 beaconFee;
    uint256 timestamp;
    uint256 expirationBlocks;
    uint256 expirationSeconds;
    uint256 callbackGasLimit;
    uint256 minConfirmations;
    address client;
    address[3] beacons;
    bytes32 seed;
}

struct SAccounts {
    address client;
    address[3] beacons;
}

struct Beacon {
    uint256[2] publicKey;
    bool registered;
    uint8 strikes;
    uint8 consecutiveSubmissions;
    uint64 pending;
}