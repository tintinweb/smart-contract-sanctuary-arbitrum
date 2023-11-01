// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IBarz} from "./interfaces/IBarz.sol";

/**
 * @title Barz
 * @dev A diamond proxy wallet with a modular & upgradeable architecture
 * @author David Yongjun Kim (@Powerstream3604)
 */
contract Barz is IBarz {
    /**
     * @notice Initializes Barz with the given parameters. Barz account is intended to be created from Barz Factory for stable deployment.
     * @dev This method makes a delegate call to account facet and account facet handles the initialization.
     *      With modular architecture, Barz encompasses wide spectrum of architecture and logic.
     *      The only requirement is account facet to comply with initialize() interface.
     *      Barz doesn't include built-in functions and is a full proxy, for maximum extensibility and modularity.
     * @param _accountFacet Address of Account Facet in charge of the Barz initialization
     * @param _verificationFacet Address of Verification Facet for verifying the signature. Could be any signature scheme
     * @param _entryPoint Address of Entry Point contract
     * @param _facetRegistry Address of Facet Registry. Facet Registry is a registry holding trusted facets that could be added to user's wallet
     * @param _defaultFallBack Address of Default FallBack Handler. Middleware contract for more efficient deployment
     * @param _ownerPublicKey Bytes of Owner Public Key using for initialization
     */
    constructor(
        address _accountFacet,
        address _verificationFacet,
        address _entryPoint,
        address _facetRegistry,
        address _defaultFallBack,
        bytes memory _ownerPublicKey
    ) payable {
        bytes memory initCall = abi.encodeWithSignature(
            "initialize(address,address,address,address,bytes)",
            _verificationFacet,
            _entryPoint,
            _facetRegistry,
            _defaultFallBack,
            _ownerPublicKey
        );
        (bool success, bytes memory result) = _accountFacet.delegatecall(
            initCall
        );
        if (!success || uint256(bytes32(result)) != 1) {
            revert Barz__InitializationFailure();
        }
    }

    /**
     * @notice Fallback function for Barz complying with Diamond Standard with customization of adding Default Fallback Handler
     * @dev Find facet for function that is called and execute the function if a facet is found and return any value.
     */
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = address(bytes20(ds.facets[msg.sig]));
        if (facet == address(0))
            facet = ds.defaultFallbackHandler.facetAddress(msg.sig);
        require(facet != address(0), "Barz: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice Receive function to receive native token without data
     */
    receive() external payable {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {Barz} from "./Barz.sol";
import {IBarzFactory} from "./interfaces/IBarzFactory.sol";

/**
 * @title Barz Factory
 * @dev Contract to easily deploy Barz to a pre-computed address with a single call
 * @author David Yongjun Kim (@Powerstream3604)
 */
contract BarzFactory is IBarzFactory {
    event BarzDeployed(address);

    address public immutable accountFacet;
    address public immutable entryPoint;
    address public immutable facetRegistry;
    address public immutable defaultFallback;

    /**
     * @notice Sets the initialization data for Barz contract initialization
     * @param _accountFacet Account Facet to be used to create Barz
     * @param _entryPoint Entrypoint contract to be used to create Barz. This uses canonical EntryPoint deployed by EF
     * @param _facetRegistry Facet Registry to be used to create Barz
     * @param _defaultFallback Default Fallback Handler to be used to create Barz
     */
    constructor(
        address _accountFacet,
        address _entryPoint,
        address _facetRegistry,
        address _defaultFallback
    ) {
        accountFacet = _accountFacet;
        entryPoint = _entryPoint;
        facetRegistry = _facetRegistry;
        defaultFallback = _defaultFallback;
    }

    /**
     * @notice Creates the Barz with a single call. It creates the Barz contract with the givent verification facet
     * @param _verificationFacet Address of verification facet used for creating the barz account
     * @param _owner Public Key of the owner to initialize barz account
     * @param _salt Salt used for deploying barz with create2
     * @return barz Instance of Barz contract deployed with the given parameters
     */
    function createAccount(
        address _verificationFacet,
        bytes calldata _owner,
        uint256 _salt
    ) external override returns (Barz barz) {
        address addr = getAddress(_verificationFacet, _owner, _salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return Barz(payable(addr));
        }
        barz = new Barz{salt: bytes32(_salt)}(
            accountFacet,
            _verificationFacet,
            entryPoint,
            facetRegistry,
            defaultFallback,
            _owner
        );
        emit BarzDeployed(address(barz));
    }

    /**
     * @notice Calculates the address of Barz with the given parameters
     * @param _verificationFacet Address of verification facet used for creating the barz account
     * @param _owner Public Key of the owner to initialize barz account
     * @param _salt Salt used for deploying barz with create2
     * @return barzAddress Precalculated Barz address
     */
    function getAddress(
        address _verificationFacet,
        bytes calldata _owner,
        uint256 _salt
    ) public view override returns (address barzAddress) {
        bytes memory bytecode = getBytecode(
            accountFacet,
            _verificationFacet,
            entryPoint,
            facetRegistry,
            defaultFallback,
            _owner
        );
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(bytecode)
            )
        );
        barzAddress = address(uint160(uint256(hash)));
    }

    /**
     * @notice Returns the bytecode of Barz with the given parameter
     * @param _accountFacet Account Facet to be used to create Barz
     * @param _verificationFacet Verification Facet to be used to create Barz
     * @param _entryPoint Entrypoint contract to be used to create Barz. This uses canonical EntryPoint deployed by EF
     * @param _facetRegistry Facet Registry to be used to create Barz
     * @param _defaultFallback Default Fallback Handler to be used to create Barz
     * @param _ownerPublicKey Public Key of owner to be used to initialize Barz ownership
     * @return barzBytecode Bytecode of Barz
     */
    function getBytecode(
        address _accountFacet,
        address _verificationFacet,
        address _entryPoint,
        address _facetRegistry,
        address _defaultFallback,
        bytes calldata _ownerPublicKey
    ) public pure override returns (bytes memory barzBytecode) {
        bytes memory bytecode = type(Barz).creationCode;
        barzBytecode = abi.encodePacked(
            bytecode,
            abi.encode(
                _accountFacet,
                _verificationFacet,
                _entryPoint,
                _facetRegistry,
                _defaultFallback,
                _ownerPublicKey
            )
        );
    }

    /**
     * @notice Returns the creation code of the Barz contract
     * @return creationCode Creation code of Barz
     */
    function getCreationCode()
        public
        pure
        override
        returns (bytes memory creationCode)
    {
        creationCode = type(Barz).creationCode;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

/**
 * @title DiamondCut Facet Interface
 * @dev Interface for DiamondCut Facet responsible for adding/removing/replace facets in Barz
 * @author David Yongjun Kim (@Powerstream3604)
 */
interface IDiamondCut {
    error DiamondCutFacet__InvalidRouteWithGuardian();
    error DiamondCutFacet__InvalidRouteWithoutGuardian();
    error DiamondCutFacet__InvalidArrayLength();
    error DiamondCutFacet__InsufficientApprovers();
    error DiamondCutFacet__InvalidApprover();
    error DiamondCutFacet__InvalidApproverSignature();
    error DiamondCutFacet__InvalidApprovalValidationPeriod();
    error DiamondCutFacet__CannotRevokeUnapproved();
    error DiamondCutFacet__GuardianApprovalNotRequired();
    error DiamondCutFacet__LackOfOwnerApproval();
    error DiamondCutFacet__OwnerAlreadyApproved();
    error DiamondCutFacet__DuplicateApproval();

    event DiamondCutApproved(
        FacetCut[] diamondCut,
        address init,
        bytes initCalldata
    );
    event DiamondCutApprovalRevoked(
        FacetCut[] diamondCut,
        address init,
        bytes initCalldata
    );

    event SupportsInterfaceUpdated(bytes4 interfaceId, bool _lag);

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
    /// @param diamondCut Contains the facet addresses and function selectors
    /// @param init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata diamondCut,
        address init,
        bytes calldata _calldata
    ) external;

    function updateSupportsInterface(bytes4 interfaceId, bool flag) external;

    function diamondCutWithGuardian(
        FacetCut[] calldata diamondCut,
        address init,
        bytes calldata _calldata,
        address[] calldata approvers,
        bytes[] calldata signatures
    ) external;

    function approveDiamondCut(
        FacetCut[] calldata diamondCut,
        address init,
        bytes calldata _calldata
    ) external;

    function revokeDiamondCutApproval(
        FacetCut[] calldata diamondCut,
        address init,
        bytes calldata _calldata
    ) external;

    function getDiamondCutApprovalCountWithTimeValidity(
        bytes32 diamondCutHash
    ) external view returns (uint256);

    function getOwnerCutApprovalWithTimeValidity(
        bytes32 diamondCutHash
    ) external view returns (bool);

    function isCutApproved(
        bytes32 diamondCutHash,
        address approver
    ) external view returns (bool);

    function getDiamondCutHash(
        FacetCut[] calldata diamondCut,
        address init,
        bytes calldata _calldata
    ) external view returns (bytes32);

    function getDiamondCutNonce() external view returns (uint128);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

/**
 * @title Barz Interface
 * @dev Interface of Barz
 * @author David Yongjun Kim (@Powerstream3604)
 */
interface IBarz {
    error Barz__InitializationFailure();
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {Barz} from "../Barz.sol";

/**
 * @title Barz Factory Interface
 * @dev Interface of contract to easily deploy Barz to a pre-computed address with a single call
 * @author David Yongjun Kim (@Powerstream3604)
 */
interface IBarzFactory {
    function createAccount(
        address verificationFacet,
        bytes calldata owner,
        uint256 salt
    ) external returns (Barz);

    function getAddress(
        address verificationFacet,
        bytes calldata owner,
        uint256 salt
    ) external view returns (address);

    function getBytecode(
        address accountFacet,
        address verificationFacet,
        address entryPoint,
        address facetRegistry,
        address defaultFallback,
        bytes memory ownerPublicKey
    ) external pure returns (bytes memory);

    function getCreationCode() external pure returns (bytes memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {IDiamondCut} from "../facets/base/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../facets/base/interfaces/IDiamondLoupe.sol";

error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("trustwallet.barz.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // Default Fallback Handler of the barz.
        IDiamondLoupe defaultFallbackHandler;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function enforceIsSelf() internal view {
        require(msg.sender == address(this), "LibDiamond: Caller not self");
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );

            unchecked {
                facetIndex++;
            }
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(
            _selectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(
                _newFacetAddress,
                "LibDiamondCut: Add facet has no code"
            );
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "LibDiamondCut: Can't add function that already exists"
                );
                // add facet for selector
                ds.facets[selector] =
                    bytes20(_newFacetAddress) |
                    bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                // " << 5 is the same as multiplying by 32 ( * 32)
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(
                _newFacetAddress,
                "LibDiamondCut: Replace facet has no code"
            );
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(
                    oldFacetAddress != address(this),
                    "LibDiamondCut: Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "LibDiamondCut: Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "LibDiamondCut: Can't replace function that doesn't exist"
                );
                // replace old facet address
                ds.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(_newFacetAddress);

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "LibDiamondCut: Remove facet address must be address(0)"
            );
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "LibDiamondCut: Can't remove function that doesn't exist"
                    );
                    // only useful if immutable functions exist
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "LibDiamondCut: Can't remove immutable function"
                    );
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    lastSelector = bytes4(
                        _selectorSlot << (selectorInSlotIndex << 5)
                    );
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[
                        oldSelectorsSlotCount
                    ];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }

                unchecked {
                    selectorIndex++;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(
            _init,
            "LibDiamondCut: _init address has no code"
        );
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

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function restrictionsFacet() internal view returns (address facetAddress_) {
        bytes4 selector = bytes4(
            keccak256("verifyRestrictions(address,address,uint256,bytes)")
        );
        facetAddress_ = address(
            bytes20(LibDiamond.diamondStorage().facets[selector])
        );
    }
}