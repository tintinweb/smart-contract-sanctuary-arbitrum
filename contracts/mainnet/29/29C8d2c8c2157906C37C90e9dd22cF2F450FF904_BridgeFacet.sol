// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

error AlreadyInitialized();
error CannotAuthoriseSelf();
error CannotBridgeToSameNetwork();
error ContractCallNotAllowed();
error CumulativeSlippageTooHigh(uint256 minAmount, uint256 receivedAmount);
error ExternalCallFailed();
error InformationMismatch();
error InsufficientBalance(uint256 required, uint256 balance);
error InvalidAmount();
error InvalidCallData();
error InvalidConfig();
error InvalidContract();
error InvalidDestinationChain();
error InvalidFallbackAddress();
error InvalidReceivedAmount(uint256 expected, uint256 received);
error InvalidReceiver();
error InvalidSendingToken();
error NativeAssetNotSupported();
error NativeAssetTransferFailed();
error NoSwapDataProvided();
error NoSwapFromZeroBalance();
error NotAContract();
error NotInitialized();
error NoTransferToNullAddress();
error NullAddrIsNotAnERC20Token();
error NullAddrIsNotAValidSpender();
error OnlyContractOwner();
error RecoveryAddressCannotBeZero();
error ReentrancyError();
error TokenNotSupported();
error UnAuthorized();
error UnsupportedChainId(uint256 chainId);
error WithdrawFailed();
error ZeroAmount();

// SPDX-License-Identifier: UNLINCESED
pragma solidity 0.8.20;

import { LibDiamond } from '../libraries/LibDiamond.sol';
import { LibAccessControl } from '../libraries/LibAccessControl.sol';
import { LibBridge } from '../libraries/LibBridge.sol';
import { NullAddrIsNotAnERC20Token } from '../errors/GenericErrors.sol';
import { LibUtil } from '../libraries/LibUtil.sol';

error IncorrectFeePercent();
error LengthMismatch();

contract BridgeFacet  {
    function updateCrosschainFee(uint256 _crosschainFee) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();

        if(_crosschainFee > 10000) revert IncorrectFeePercent();

        LibBridge.updateCrosschainFee(_crosschainFee);
    }

    function updateMinFee(uint256 _chainId, uint256 _minFee) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();

        LibBridge.updateMinFee(_chainId, _minFee);
    }

    function batchUpdateMinFee(uint256[] calldata _chainId, uint256[] calldata _minFee) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();

        uint256 length = _chainId.length;

        if (length != _minFee.length) revert LengthMismatch();

        for (uint256 i; i < length;) {

            LibBridge.updateMinFee(_chainId[i], _minFee[i]);

            unchecked {
                ++i;
            }
        }
    }

    function addApprovedToken(address _token) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();

        if(LibUtil.isZeroAddress(_token)) revert NullAddrIsNotAnERC20Token();

        LibBridge.addApprovedToken(_token);
    }

    function removeApprovedToken(address _token) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();
        LibBridge.removeApprovedToken(_token);
    }

    function addContractTo(uint256 _chainId, address _contractTo) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();
        LibBridge.addContractTo(_chainId, _contractTo);
    }

    function removeContractTo(uint256 _chainId) external {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();
        LibBridge.removeContractTo(_chainId);
    }

    function getContractTo(uint256 _chainId) external view returns (address) {
        if(LibDiamond.contractOwner() != msg.sender) LibAccessControl.isAllowedTo();
        return LibBridge.getContractTo(_chainId);
    }

    function getCrosschainFee() external view returns (uint256) {
        return LibBridge.getCrosschainFee();
    }

    function getMinFee(uint256 _chainId) external view returns (uint256) {
        return LibBridge.getMinFee(_chainId);
    }

    function isTokenApproved(address _token) external view returns (bool) {
        return LibBridge.getApprovedToken(_token);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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

// SPDX-License-Identifier: UNLINCESED
pragma solidity ^0.8.0;

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLINCESED
pragma solidity 0.8.20;

import { CannotAuthoriseSelf } from '../errors/GenericErrors.sol';

error NotAllowedTo(address account, bytes4 selector);

library LibAccessControl {
    bytes32 internal constant ACCESS_CONTROL_STORAGE = keccak256("access.control.storage");

    struct AccessStorage {
        mapping(address => mapping(bytes4 => bool)) functionAccess;
    }

    event AccessGranted(address indexed account, bytes4 indexed selector);
    event AccessRevoked(address indexed account, bytes4 indexed selector);

    function _getStorage() internal pure returns (AccessStorage storage accStor) {
        bytes32 position = ACCESS_CONTROL_STORAGE;
        assembly {
            accStor.slot := position
        }
    }

    function addAccess(address _account, bytes4 _selector) internal {
        if (_account == address(this)) revert CannotAuthoriseSelf();
        AccessStorage storage accStor = _getStorage();  
        accStor.functionAccess[_account][_selector] = true;
        emit AccessGranted(_account, _selector);
    }

    function revokeAccess(address _account, bytes4 _selector) internal {
        AccessStorage storage accStor = _getStorage();
        accStor.functionAccess[_account][_selector] = false;
        emit AccessRevoked(_account, _selector);
    }

    function isAllowedTo() internal view {
        AccessStorage storage accStor = _getStorage();
        if (!accStor.functionAccess[msg.sender][msg.sig]) revert NotAllowedTo(msg.sender, msg.sig);
    }
}

// SPDX-License-Identifier: UNLINCESED
pragma solidity 0.8.20;

import { LibFeeCollector } from './LibFeeCollector.sol';
import { LibUtil } from './LibUtil.sol';

library LibBridge {
    bytes32 internal constant BRIDGE_STORAGE_POSITION =
        keccak256("bridge.storage.position");

    struct BridgeStorage {
        uint256 crosschainFee;
        //chainId -> minFee
        mapping(uint256 => uint256) minFee;
        mapping(address => bool) approvedTokens;
        mapping(uint256 => address) contractTo;
    }

    function _getStorage() internal pure returns (BridgeStorage storage bs) {
        bytes32 position = BRIDGE_STORAGE_POSITION;
        assembly {
            bs.slot := position
        }
    }

    function updateCrosschainFee(uint256 _crosschainFee) internal {
        BridgeStorage storage bs = _getStorage();

        bs.crosschainFee = _crosschainFee;
    }

    function updateMinFee(uint256 _chainId, uint256 _minFee) internal {
        BridgeStorage storage bs = _getStorage();

        bs.minFee[_chainId] = _minFee;
    }

    function addApprovedToken(address _token) internal {
        BridgeStorage storage bs = _getStorage();

        bs.approvedTokens[_token] = true;
    }

    function removeApprovedToken(address _token) internal {
        BridgeStorage storage bs = _getStorage();

        bs.approvedTokens[_token] = false;
    }

    function addContractTo(uint256 _chainId, address _contractTo) internal {
        BridgeStorage storage bs = _getStorage();

        bs.contractTo[_chainId] = _contractTo;
    }

    function removeContractTo(uint256 _chainId) internal {
        BridgeStorage storage bs = _getStorage();

        if (bs.contractTo[_chainId] == address(0)) return;

        bs.contractTo[_chainId] = address(0);
    }

    function getContractTo(uint256 _chainId) internal view returns (address) {
        BridgeStorage storage bs = _getStorage();

        return bs.contractTo[_chainId];
    }

    function getCrosschainFee() internal view returns (uint256) {
        return _getStorage().crosschainFee;
    }

    function getMinFee(uint256 _chainId) internal view returns (uint256) {
        return _getStorage().minFee[_chainId];
    }

    function getApprovedToken(address _token) internal view returns (bool) {
        return _getStorage().approvedTokens[_token];
    }

    function getFeeInfo(uint256 _chainId) internal view returns (uint256, uint256) {
        BridgeStorage storage bs = _getStorage();
        return (bs.crosschainFee, bs.minFee[_chainId]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library LibBytes {
    // solhint-disable no-inline-assembly

    // LibBytes specific errors
    error SliceOverflow();
    error SliceOutOfBounds();
    error AddressOutOfBounds();

    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    // -------------------------

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        if (_length + 31 < _length) revert SliceOverflow();
        if (_bytes.length < _start + _length) revert SliceOutOfBounds();

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (address) {
        if (_bytes.length < _start + 20) {
            revert AddressOutOfBounds();
        }
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    /// Copied from OpenZeppelin's `Strings.sol` utility library.
    /// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/8335676b0e99944eef6a742e16dcd9ff6e68e609/contracts/utils/Strings.sol
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibUtil } from "../libraries/LibUtil.sol";
// import { OnlyContractOwner } from "../Errors/GenericErrors.sol";

error OnlyContractOwner();

/// Implementation of EIP-2535 Diamond Standard
/// https://eips.ethereum.org/EIPS/eip-2535
library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    // Diamond specific errors
    error IncorrectFacetCutAction();
    error NoSelectorsInFace();
    error FunctionAlreadyExists();
    error FacetAddressIsZero();
    error FacetAddressIsNotZero();
    error FacetContainsNoCode();
    error FunctionDoesNotExist();
    error FunctionIsImmutable();
    error InitZeroButCalldataNotEmpty();
    error CalldataEmptyButInitNotZero();
    error InitReverted();
    // ----------------

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

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        if (msg.sender != diamondStorage().contractOwner)
            revert OnlyContractOwner();
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
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
                revert IncorrectFacetCutAction();
            }
            unchecked {
                ++facetIndex;
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsInFace();
        }
        DiamondStorage storage ds = diamondStorage();
        if (LibUtil.isZeroAddress(_facetAddress)) {
            revert FacetAddressIsZero();
        }
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;

        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (!LibUtil.isZeroAddress(oldFacetAddress)) {
                revert FunctionAlreadyExists();
            }
            addFunction(ds, selector, selectorPosition, _facetAddress);
            unchecked {
                ++selectorPosition;
                ++selectorIndex;
            }
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsInFace();
        }
        DiamondStorage storage ds = diamondStorage();
        if (LibUtil.isZeroAddress(_facetAddress)) {
            revert FacetAddressIsZero();
        }
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;

        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (oldFacetAddress == _facetAddress) {
                revert FunctionAlreadyExists();
            }
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            unchecked {
                ++selectorPosition;
                ++selectorIndex;
            }
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsInFace();
        }
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        if (!LibUtil.isZeroAddress(_facetAddress)) {
            revert FacetAddressIsNotZero();
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;

        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
            unchecked {
                ++selectorIndex;
            }
        }
    }

    function addFacet(
        DiamondStorage storage ds,
        address _facetAddress
    ) internal {
        enforceHasContractCode(_facetAddress);
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        if (LibUtil.isZeroAddress(_facetAddress)) {
            revert FunctionDoesNotExist();
        }
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) {
            revert FunctionIsImmutable();
        }
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                selectorPosition
            ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (LibUtil.isZeroAddress(_init)) {
            if (_calldata.length != 0) {
                revert InitZeroButCalldataNotEmpty();
            }
        } else {
            if (_calldata.length == 0) {
                revert CalldataEmptyButInitNotZero();
            }
            if (_init != address(this)) {
                enforceHasContractCode(_init);
            }
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert InitReverted();
                }
            }
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert FacetContainsNoCode();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibUtil } from './LibUtil.sol';
import { IERC20Decimals } from '../interfaces/IERC20Decimals.sol';

library LibFeeCollector {
    bytes32 internal constant FEE_STORAGE_POSITION =
        keccak256("fee.collector.storage.position");

    struct FeeStorage {
        address mainPartner;
        uint256 mainFee; //1-10000
        uint256 defaultPartnerFeeShare;
        mapping(address => bool) isPartner;
        mapping(address => uint256) partnerFeeSharePercent; //1 - 10000;
        //partner -> token -> amount
        mapping(address => mapping(address => uint256)) feePerToken;
    }

    function _getStorage()
        internal
        pure
        returns (FeeStorage storage fs)
    {
        bytes32 position = FEE_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            fs.slot := position
        }
    }

    function updateMainPartner(address _mainPartner) internal {
        FeeStorage storage fs = _getStorage();

        fs.mainPartner = _mainPartner;
    }

    function updateMainFee(uint256 _mainFee) internal {
        FeeStorage storage fs = _getStorage();

        fs.mainFee = _mainFee;
    }

    function addPartner(address _partner, uint256 _partnerFeeShare) internal {
        FeeStorage storage fs = _getStorage();

        fs.isPartner[_partner] = true;
        fs.partnerFeeSharePercent[_partner] = _partnerFeeShare;
    }

    function removePartner(address _partner) internal {
        FeeStorage storage fs = _getStorage();
        if (!fs.isPartner[_partner]) return;

        fs.isPartner[_partner] = false;
        fs.partnerFeeSharePercent[_partner] = 0;
    }

    function getMainFee() internal view returns (uint256) {
        return _getStorage().mainFee;
    }

    function getMainPartner() internal view returns (address) {
        return _getStorage().mainPartner;
    }

    function getPartnerInfo(address _partner) internal view returns (bool isPartner, uint256 partnerFeeSharePercent) {
        FeeStorage storage fs = _getStorage();
        return (fs.isPartner[_partner], fs.partnerFeeSharePercent[_partner]);
    }

    function getFeeAmount(address _token, address _partner) internal view returns (uint256) {
        return(_getStorage().feePerToken[_partner][_token]);
    }

    function decreaseFeeAmount(uint256 _amount, address _account, address _token) internal {
        FeeStorage storage fs = _getStorage();

        fs.feePerToken[_account][_token] -= _amount;
    } 

    function takeFromTokenFee(uint256 _amount, address _token, address _partner) internal returns (uint256 newAmount) {
        FeeStorage storage fs = _getStorage();

        (uint256 mainFee, uint256 partnerFee) = _calcFees(_amount, _partner);
        registerFee(mainFee, fs.mainPartner, _token);
        if (partnerFee != 0) registerFee(partnerFee, _partner, _token);
        
        newAmount = _amount - (mainFee + partnerFee);
    }

    function takeCrosschainFee(
        uint256 _amount,
        address _partner,
        address _token,
        uint256 _crosschainFee,
        uint256 _minFee
    ) internal returns (uint256 newAmount) {
        FeeStorage storage fs = _getStorage();

        (uint256 mainFee, uint256 partnerFee) = _calcCrosschainFees(_amount, _crosschainFee, _minFee, _token, _partner);
        registerFee(mainFee, fs.mainPartner, _token);
        if (partnerFee != 0) registerFee(partnerFee, _partner, _token);
        
        newAmount = _amount - (mainFee + partnerFee);
    }  

    function _calcFees(uint256 _amount, address _partner) private view returns (uint256, uint256){
        FeeStorage storage fs = _getStorage();
        uint256 totalFee = _amount * fs.mainFee / 10000;

        return _splitFee(totalFee, _partner);
    }

    function _calcCrosschainFees(
        uint256 _amount, 
        uint256 _crosschainFee, 
        uint256 _minFee, 
        address _token,
        address _partner
    ) internal view returns (uint256, uint256) {
        uint256 percentFromAmount = _amount * _crosschainFee / 10000;
        
        uint256 decimals = IERC20Decimals(_token).decimals();
        uint256 minFee = _minFee * 10**decimals / 10000;

        uint256 totalFee = percentFromAmount < minFee ? minFee : percentFromAmount;

        return _splitFee(totalFee, _partner);
    }

    function _splitFee(uint256 totalFee, address _partner) private view returns (uint256, uint256) {
        FeeStorage storage fs = _getStorage();

        uint256 mainFee;
        uint256 partnerFee;

        if (LibUtil.isZeroAddress(_partner)) {
            mainFee = totalFee;
            partnerFee = 0;
        } else {
            uint256 partnerFeePercent = fs.isPartner[_partner] 
                ? fs.partnerFeeSharePercent[_partner]
                : fs.defaultPartnerFeeShare;
            partnerFee = totalFee * partnerFeePercent / 10000;
            mainFee = totalFee - partnerFee;
        }  

        return (mainFee, partnerFee);
    }

     function registerFee(uint256 _fee, address _partner, address _token) private {
        FeeStorage storage fs = _getStorage();
        
        fs.feePerToken[_partner][_token] += _fee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibBytes.sol";

library LibUtil {
    using LibBytes for bytes;

    function getRevertMsg(
        bytes memory _res
    ) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) return "Transaction reverted silently";
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }

    /// @notice Determines whether the given address is the zero address
    /// @param addr The address to verify
    /// @return Boolean indicating if the address is the zero address
    function isZeroAddress(address addr) internal pure returns (bool) {
        return addr == address(0);
    }
}