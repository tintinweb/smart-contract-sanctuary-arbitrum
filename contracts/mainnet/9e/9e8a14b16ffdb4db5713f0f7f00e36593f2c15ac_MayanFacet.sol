// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ILiFi } from "../Interfaces/ILiFi.sol";
import { LibDiamond } from "../Libraries/LibDiamond.sol";
import { LibAsset, IERC20 } from "../Libraries/LibAsset.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { LibSwap } from "../Libraries/LibSwap.sol";
import { ReentrancyGuard } from "../Helpers/ReentrancyGuard.sol";
import { SwapperV2 } from "../Helpers/SwapperV2.sol";
import { Validatable } from "../Helpers/Validatable.sol";
import { IMayan } from "../Interfaces/IMayan.sol";
import { UnsupportedChainId } from "../Errors/GenericErrors.sol";

/// @title Mayan Facet
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for bridging through Mayan Bridge
/// @custom:version 1.0.0
contract MayanFacet is ILiFi, ReentrancyGuard, SwapperV2, Validatable {
    /// Storage ///

    bytes32 internal constant NAMESPACE = keccak256("com.lifi.facets.mayan");
    address internal constant NON_EVM_ADDRESS =
        0x11f111f111f111F111f111f111F111f111f111F1;

    IMayan public immutable mayan;

    /// @dev Mayan specific bridge data
    /// @param nonEVMReceiver The address of the non-EVM receiver if applicable
    /// @param mayanProtocol The address of the Mayan protocol final contract
    /// @param protocolData The protocol data for the Mayan protocol
    struct MayanData {
        bytes32 nonEVMReceiver;
        address mayanProtocol;
        bytes protocolData;
    }

    /// Errors ///
    error InvalidReceiver(address expected, address actual);
    error InvalidNonEVMReceiver(bytes32 expected, bytes32 actual);

    /// Events ///

    event BridgeToNonEVMChain(
        bytes32 indexed transactionId,
        uint256 indexed destinationChainId,
        bytes32 receiver
    );

    /// Constructor ///

    /// @notice Constructor for the contract.
    constructor(IMayan _mayan) {
        mayan = _mayan;
    }

    /// External Methods ///

    /// @notice Bridges tokens via Mayan
    /// @param _bridgeData The core information needed for bridging
    /// @param _mayanData Data specific to Mayan
    function startBridgeTokensViaMayan(
        ILiFi.BridgeData memory _bridgeData,
        MayanData calldata _mayanData
    )
        external
        payable
        nonReentrant
        refundExcessNative(payable(msg.sender))
        validateBridgeData(_bridgeData)
        doesNotContainSourceSwaps(_bridgeData)
        doesNotContainDestinationCalls(_bridgeData)
    {
        LibAsset.depositAsset(
            _bridgeData.sendingAssetId,
            _bridgeData.minAmount
        );
        _startBridge(_bridgeData, _mayanData);
    }

    /// @notice Performs a swap before bridging via Mayan
    /// @param _bridgeData The core information needed for bridging
    /// @param _swapData An array of swap related data for performing swaps before bridging
    /// @param _mayanData Data specific to Mayan
    function swapAndStartBridgeTokensViaMayan(
        ILiFi.BridgeData memory _bridgeData,
        LibSwap.SwapData[] calldata _swapData,
        MayanData memory _mayanData
    )
        external
        payable
        nonReentrant
        refundExcessNative(payable(msg.sender))
        containsSourceSwaps(_bridgeData)
        doesNotContainDestinationCalls(_bridgeData)
        validateBridgeData(_bridgeData)
    {
        _bridgeData.minAmount = _depositAndSwap(
            _bridgeData.transactionId,
            _bridgeData.minAmount,
            _swapData,
            payable(msg.sender)
        );

        uint256 decimals;
        bool isNative = LibAsset.isNativeAsset(_bridgeData.sendingAssetId);
        decimals = isNative
            ? 18
            : ERC20(_bridgeData.sendingAssetId).decimals();

        // Normalize the amount to 8 decimals
        _bridgeData.minAmount = _normalizeAmount(
            _bridgeData.minAmount,
            uint8(decimals)
        );

        // Native values are not passed as calldata
        if (!isNative) {
            // Update the protocol data with the new input amount
            _mayanData.protocolData = _replaceInputAmount(
                _mayanData.protocolData,
                _bridgeData.minAmount
            );
        }

        _startBridge(_bridgeData, _mayanData);
    }

    /// Internal Methods ///

    /// @dev Contains the business logic for the bridge via Mayan
    /// @param _bridgeData The core information needed for bridging
    /// @param _mayanData Data specific to Mayan
    function _startBridge(
        ILiFi.BridgeData memory _bridgeData,
        MayanData memory _mayanData
    ) internal {
        // Validate receiver address
        if (_bridgeData.receiver == NON_EVM_ADDRESS) {
            if (_mayanData.nonEVMReceiver == bytes32(0)) {
                revert InvalidNonEVMReceiver(
                    _mayanData.nonEVMReceiver,
                    bytes32(0)
                );
            }
            bytes32 receiver = _parseReceiver(_mayanData.protocolData);
            if (_mayanData.nonEVMReceiver != receiver) {
                revert InvalidNonEVMReceiver(
                    _mayanData.nonEVMReceiver,
                    receiver
                );
            }
        } else {
            address receiver = address(
                uint160(uint256(_parseReceiver(_mayanData.protocolData)))
            );
            if (_bridgeData.receiver != receiver) {
                revert InvalidReceiver(_bridgeData.receiver, receiver);
            }
        }

        IMayan.PermitParams memory emptyPermitParams;

        if (!LibAsset.isNativeAsset(_bridgeData.sendingAssetId)) {
            LibAsset.maxApproveERC20(
                IERC20(_bridgeData.sendingAssetId),
                address(mayan),
                _bridgeData.minAmount
            );

            mayan.forwardERC20(
                _bridgeData.sendingAssetId,
                _bridgeData.minAmount,
                emptyPermitParams,
                _mayanData.mayanProtocol,
                _mayanData.protocolData
            );
        } else {
            mayan.forwardEth{ value: _bridgeData.minAmount }(
                _mayanData.mayanProtocol,
                _mayanData.protocolData
            );
        }

        if (_bridgeData.receiver == NON_EVM_ADDRESS) {
            emit BridgeToNonEVMChain(
                _bridgeData.transactionId,
                _bridgeData.destinationChainId,
                _mayanData.nonEVMReceiver
            );
        }

        emit LiFiTransferStarted(_bridgeData);
    }

    // @dev Parses the receiver address from the protocol data
    // @param protocolData The protocol data for the Mayan protocol
    // @return receiver The receiver address
    function _parseReceiver(
        bytes memory protocolData
    ) internal pure returns (bytes32 receiver) {
        bytes4 selector;
        assembly {
            // Load the selector from the protocol data
            selector := mload(add(protocolData, 0x20))
            // Shift the selector to the right by 224 bits to match shape of literal in switch statement
            let shiftedSelector := shr(224, selector)
            switch shiftedSelector
            // Note: [*bytes32*] = location of receiver address
            case 0x94454a5d {
                // 0x94454a5d bridgeWithFee(address,uint256,uint64,uint64,[*bytes32*],(uint32,bytes32,bytes32))
                receiver := mload(add(protocolData, 0xa4)) // MayanCircle::bridgeWithFee()
            }
            case 0x32ad465f {
                // 0x32ad465f bridgeWithLockedFee(address,uint256,uint64,uint256,(uint32,[*bytes32*],bytes32))
                receiver := mload(add(protocolData, 0xc4)) // MayanCircle::bridgeWithLockedFee()
            }
            case 0xafd9b706 {
                // 0xafd9b706 createOrder((address,uint256,uint64,[*bytes32*],uint16,bytes32,uint64,uint64,uint64,bytes32,uint8),(uint32,bytes32,bytes32))
                receiver := mload(add(protocolData, 0x84)) // MayanCircle::createOrder()
            }
            case 0x6111ad25 {
                // 0x6111ad25 swap((uint64,uint64,uint64),(bytes32,uint16,bytes32,[*bytes32*],uint16,bytes32,bytes32),bytes32,uint16,(uint256,uint64,uint64,bool,uint64,bytes),address,uint256)
                receiver := mload(add(protocolData, 0xe4)) // MayanSwap::swap()
            }
            case 0x1eb1cff0 {
                // 0x1eb1cff0 wrapAndSwapETH((uint64,uint64,uint64),(bytes32,uint16,bytes32,[*bytes32*],uint16,bytes32,bytes32),bytes32,uint16,(uint256,uint64,uint64,bool,uint64,bytes))
                receiver := mload(add(protocolData, 0xe4)) // MayanSwap::wrapAndSwapETH()
            }
            case 0xb866e173 {
                // 0xb866e173 createOrderWithEth((bytes32,bytes32,uint64,uint64,uint64,uint64,uint64,[*bytes32*],uint16,bytes32,uint8,uint8,bytes32))
                receiver := mload(add(protocolData, 0x104)) // MayanSwift::createOrderWithEth()
            }
            case 0x8e8d142b {
                // 0x8e8d142b createOrderWithToken(address,uint256,(bytes32,bytes32,uint64,uint64,uint64,uint64,uint64,[*bytes32*],uint16,bytes32,uint8,uint8,bytes32))
                receiver := mload(add(protocolData, 0x144)) // MayanSwift::createOrderWithToken()
            }
            default {
                receiver := 0x0
            }
        }
    }

    // @dev Normalizes the amount to 8 decimals
    // @param amount The amount to normalize
    // @param decimals The number of decimals in the asset
    function _normalizeAmount(
        uint256 amount,
        uint8 decimals
    ) internal pure returns (uint256) {
        if (decimals > 8) {
            amount /= 10 ** (decimals - 8);
            amount *= 10 ** (decimals - 8);
        }
        return amount;
    }

    // @dev Replaces the input amount in the protocol data
    // @param protocolData The protocol data for the Mayan protocol
    // @param inputAmount The new input amount
    // @return modifiedData The modified protocol data
    function _replaceInputAmount(
        bytes memory protocolData,
        uint256 inputAmount
    ) internal pure returns (bytes memory) {
        require(protocolData.length >= 68, "protocol data too short");
        bytes memory modifiedData = new bytes(protocolData.length);
        bytes4 functionSelector = bytes4(protocolData[0]) |
            (bytes4(protocolData[1]) >> 8) |
            (bytes4(protocolData[2]) >> 16) |
            (bytes4(protocolData[3]) >> 24);

        uint256 amountIndex;
        // Only the wh swap method has the amount as last argument
        bytes4 swapSelector = 0x6111ad25;
        if (functionSelector == swapSelector) {
            amountIndex = protocolData.length - 32;
        } else {
            amountIndex = 36;
        }

        // Copy the function selector and params before amount in
        for (uint i = 0; i < amountIndex; i++) {
            modifiedData[i] = protocolData[i];
        }

        // Encode the amount and place it into the modified call data
        bytes memory encodedAmount = abi.encode(inputAmount);
        for (uint i = 0; i < 32; i++) {
            modifiedData[i + amountIndex] = encodedAmount[i];
        }

        // Copy the rest of the original data after the input argument
        if (functionSelector != swapSelector) {
            for (uint i = 68; i < protocolData.length; i++) {
                modifiedData[i] = protocolData[i];
            }
        }

        return modifiedData;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILiFi {
    /// Structs ///

    struct BridgeData {
        bytes32 transactionId;
        string bridge;
        string integrator;
        address referrer;
        address sendingAssetId;
        address receiver;
        uint256 minAmount;
        uint256 destinationChainId;
        bool hasSourceSwaps;
        bool hasDestinationCall;
    }

    /// Events ///

    event LiFiTransferStarted(ILiFi.BridgeData bridgeData);

    event LiFiTransferCompleted(
        bytes32 indexed transactionId,
        address receivingAssetId,
        address receiver,
        uint256 amount,
        uint256 timestamp
    );

    event LiFiTransferRecovered(
        bytes32 indexed transactionId,
        address receivingAssetId,
        address receiver,
        uint256 amount,
        uint256 timestamp
    );

    event LiFiGenericSwapCompleted(
        bytes32 indexed transactionId,
        string integrator,
        string referrer,
        address receiver,
        address fromAssetId,
        address toAssetId,
        uint256 fromAmount,
        uint256 toAmount
    );

    // Deprecated but kept here to include in ABI to parse historic events
    event LiFiSwappedGeneric(
        bytes32 indexed transactionId,
        string integrator,
        string referrer,
        address fromAssetId,
        address toAssetId,
        uint256 fromAmount,
        uint256 toAmount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IDiamondCut } from "../Interfaces/IDiamondCut.sol";
import { LibUtil } from "../Libraries/LibUtil.sol";
import { OnlyContractOwner } from "../Errors/GenericErrors.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import { InsufficientBalance, NullAddrIsNotAnERC20Token, NullAddrIsNotAValidSpender, NoTransferToNullAddress, InvalidAmount, NativeAssetTransferFailed } from "../Errors/GenericErrors.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LibSwap } from "./LibSwap.sol";

/// @title LibAsset
/// @notice This library contains helpers for dealing with onchain transfers
///         of assets, including accounting for the native asset `assetId`
///         conventions and any noncompliant ERC20 transfers
library LibAsset {
    uint256 private constant MAX_UINT = type(uint256).max;

    address internal constant NULL_ADDRESS = address(0);

    /// @dev All native assets use the empty address for their asset id
    ///      by convention

    address internal constant NATIVE_ASSETID = NULL_ADDRESS; //address(0)

    /// @notice Gets the balance of the inheriting contract for the given asset
    /// @param assetId The asset identifier to get the balance of
    /// @return Balance held by contracts using this library
    function getOwnBalance(address assetId) internal view returns (uint256) {
        return
            isNativeAsset(assetId)
                ? address(this).balance
                : IERC20(assetId).balanceOf(address(this));
    }

    /// @notice Transfers ether from the inheriting contract to a given
    ///         recipient
    /// @param recipient Address to send ether to
    /// @param amount Amount to send to given recipient
    function transferNativeAsset(
        address payable recipient,
        uint256 amount
    ) private {
        if (recipient == NULL_ADDRESS) revert NoTransferToNullAddress();
        if (amount > address(this).balance)
            revert InsufficientBalance(amount, address(this).balance);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = recipient.call{ value: amount }("");
        if (!success) revert NativeAssetTransferFailed();
    }

    /// @notice If the current allowance is insufficient, the allowance for a given spender
    /// is set to MAX_UINT.
    /// @param assetId Token address to transfer
    /// @param spender Address to give spend approval to
    /// @param amount Amount to approve for spending
    function maxApproveERC20(
        IERC20 assetId,
        address spender,
        uint256 amount
    ) internal {
        if (isNativeAsset(address(assetId))) {
            return;
        }
        if (spender == NULL_ADDRESS) {
            revert NullAddrIsNotAValidSpender();
        }

        if (assetId.allowance(address(this), spender) < amount) {
            SafeERC20.safeApprove(IERC20(assetId), spender, 0);
            SafeERC20.safeApprove(IERC20(assetId), spender, MAX_UINT);
        }
    }

    /// @notice Transfers tokens from the inheriting contract to a given
    ///         recipient
    /// @param assetId Token address to transfer
    /// @param recipient Address to send token to
    /// @param amount Amount to send to given recipient
    function transferERC20(
        address assetId,
        address recipient,
        uint256 amount
    ) private {
        if (isNativeAsset(assetId)) {
            revert NullAddrIsNotAnERC20Token();
        }
        if (recipient == NULL_ADDRESS) {
            revert NoTransferToNullAddress();
        }

        uint256 assetBalance = IERC20(assetId).balanceOf(address(this));
        if (amount > assetBalance) {
            revert InsufficientBalance(amount, assetBalance);
        }
        SafeERC20.safeTransfer(IERC20(assetId), recipient, amount);
    }

    /// @notice Transfers tokens from a sender to a given recipient
    /// @param assetId Token address to transfer
    /// @param from Address of sender/owner
    /// @param to Address of recipient/spender
    /// @param amount Amount to transfer from owner to spender
    function transferFromERC20(
        address assetId,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (isNativeAsset(assetId)) {
            revert NullAddrIsNotAnERC20Token();
        }
        if (to == NULL_ADDRESS) {
            revert NoTransferToNullAddress();
        }

        IERC20 asset = IERC20(assetId);
        uint256 prevBalance = asset.balanceOf(to);
        SafeERC20.safeTransferFrom(asset, from, to, amount);
        if (asset.balanceOf(to) - prevBalance != amount) {
            revert InvalidAmount();
        }
    }

    function depositAsset(address assetId, uint256 amount) internal {
        if (amount == 0) revert InvalidAmount();
        if (isNativeAsset(assetId)) {
            if (msg.value < amount) revert InvalidAmount();
        } else {
            uint256 balance = IERC20(assetId).balanceOf(msg.sender);
            if (balance < amount) revert InsufficientBalance(amount, balance);
            transferFromERC20(assetId, msg.sender, address(this), amount);
        }
    }

    function depositAssets(LibSwap.SwapData[] calldata swaps) internal {
        for (uint256 i = 0; i < swaps.length; ) {
            LibSwap.SwapData calldata swap = swaps[i];
            if (swap.requiresDeposit) {
                depositAsset(swap.sendingAssetId, swap.fromAmount);
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Determines whether the given assetId is the native asset
    /// @param assetId The asset identifier to evaluate
    /// @return Boolean indicating if the asset is the native asset
    function isNativeAsset(address assetId) internal pure returns (bool) {
        return assetId == NATIVE_ASSETID;
    }

    /// @notice Wrapper function to transfer a given asset (native or erc20) to
    ///         some recipient. Should handle all non-compliant return value
    ///         tokens as well by using the SafeERC20 contract by open zeppelin.
    /// @param assetId Asset id for transfer (address(0) for native asset,
    ///                token address for erc20s)
    /// @param recipient Address to send asset to
    /// @param amount Amount to send to given recipient
    function transferAsset(
        address assetId,
        address payable recipient,
        uint256 amount
    ) internal {
        isNativeAsset(assetId)
            ? transferNativeAsset(recipient, amount)
            : transferERC20(assetId, recipient, amount);
    }

    /// @dev Checks whether the given address is a contract and contains code
    function isContract(address _contractAddr) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_contractAddr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibAsset } from "./LibAsset.sol";
import { LibUtil } from "./LibUtil.sol";
import { InvalidContract, NoSwapFromZeroBalance, InsufficientBalance } from "../Errors/GenericErrors.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibSwap {
    struct SwapData {
        address callTo;
        address approveTo;
        address sendingAssetId;
        address receivingAssetId;
        uint256 fromAmount;
        bytes callData;
        bool requiresDeposit;
    }

    event AssetSwapped(
        bytes32 transactionId,
        address dex,
        address fromAssetId,
        address toAssetId,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 timestamp
    );

    function swap(bytes32 transactionId, SwapData calldata _swap) internal {
        if (!LibAsset.isContract(_swap.callTo)) revert InvalidContract();
        uint256 fromAmount = _swap.fromAmount;
        if (fromAmount == 0) revert NoSwapFromZeroBalance();
        uint256 nativeValue = LibAsset.isNativeAsset(_swap.sendingAssetId)
            ? _swap.fromAmount
            : 0;
        uint256 initialSendingAssetBalance = LibAsset.getOwnBalance(
            _swap.sendingAssetId
        );
        uint256 initialReceivingAssetBalance = LibAsset.getOwnBalance(
            _swap.receivingAssetId
        );

        if (nativeValue == 0) {
            LibAsset.maxApproveERC20(
                IERC20(_swap.sendingAssetId),
                _swap.approveTo,
                _swap.fromAmount
            );
        }

        if (initialSendingAssetBalance < _swap.fromAmount) {
            revert InsufficientBalance(
                _swap.fromAmount,
                initialSendingAssetBalance
            );
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory res) = _swap.callTo.call{
            value: nativeValue
        }(_swap.callData);
        if (!success) {
            LibUtil.revertWith(res);
        }

        uint256 newBalance = LibAsset.getOwnBalance(_swap.receivingAssetId);

        emit AssetSwapped(
            transactionId,
            _swap.callTo,
            _swap.sendingAssetId,
            _swap.receivingAssetId,
            _swap.fromAmount,
            newBalance > initialReceivingAssetBalance
                ? newBalance - initialReceivingAssetBalance
                : newBalance,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @title Reentrancy Guard
/// @author LI.FI (https://li.fi)
/// @notice Abstract contract to provide protection against reentrancy
abstract contract ReentrancyGuard {
    /// Storage ///

    bytes32 private constant NAMESPACE = keccak256("com.lifi.reentrancyguard");

    /// Types ///

    struct ReentrancyStorage {
        uint256 status;
    }

    /// Errors ///

    error ReentrancyError();

    /// Constants ///

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    /// Modifiers ///

    modifier nonReentrant() {
        ReentrancyStorage storage s = reentrancyStorage();
        if (s.status == _ENTERED) revert ReentrancyError();
        s.status = _ENTERED;
        _;
        s.status = _NOT_ENTERED;
    }

    /// Private Methods ///

    /// @dev fetch local storage
    function reentrancyStorage()
        private
        pure
        returns (ReentrancyStorage storage data)
    {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ILiFi } from "../Interfaces/ILiFi.sol";
import { LibSwap } from "../Libraries/LibSwap.sol";
import { LibAsset } from "../Libraries/LibAsset.sol";
import { LibAllowList } from "../Libraries/LibAllowList.sol";
import { ContractCallNotAllowed, NoSwapDataProvided, CumulativeSlippageTooHigh } from "../Errors/GenericErrors.sol";

/// @title Swapper
/// @author LI.FI (https://li.fi)
/// @notice Abstract contract to provide swap functionality
contract SwapperV2 is ILiFi {
    /// Types ///

    /// @dev only used to get around "Stack Too Deep" errors
    struct ReserveData {
        bytes32 transactionId;
        address payable leftoverReceiver;
        uint256 nativeReserve;
    }

    /// Modifiers ///

    /// @dev Sends any leftover balances back to the user
    /// @notice Sends any leftover balances to the user
    /// @param _swaps Swap data array
    /// @param _leftoverReceiver Address to send leftover tokens to
    /// @param _initialBalances Array of initial token balances
    modifier noLeftovers(
        LibSwap.SwapData[] calldata _swaps,
        address payable _leftoverReceiver,
        uint256[] memory _initialBalances
    ) {
        uint256 numSwaps = _swaps.length;
        if (numSwaps != 1) {
            address finalAsset = _swaps[numSwaps - 1].receivingAssetId;
            uint256 curBalance;

            _;

            for (uint256 i = 0; i < numSwaps - 1; ) {
                address curAsset = _swaps[i].receivingAssetId;
                // Handle multi-to-one swaps
                if (curAsset != finalAsset) {
                    curBalance =
                        LibAsset.getOwnBalance(curAsset) -
                        _initialBalances[i];
                    if (curBalance > 0) {
                        LibAsset.transferAsset(
                            curAsset,
                            _leftoverReceiver,
                            curBalance
                        );
                    }
                }
                unchecked {
                    ++i;
                }
            }
        } else {
            _;
        }
    }

    /// @dev Sends any leftover balances back to the user reserving native tokens
    /// @notice Sends any leftover balances to the user
    /// @param _swaps Swap data array
    /// @param _leftoverReceiver Address to send leftover tokens to
    /// @param _initialBalances Array of initial token balances
    modifier noLeftoversReserve(
        LibSwap.SwapData[] calldata _swaps,
        address payable _leftoverReceiver,
        uint256[] memory _initialBalances,
        uint256 _nativeReserve
    ) {
        uint256 numSwaps = _swaps.length;
        if (numSwaps != 1) {
            address finalAsset = _swaps[numSwaps - 1].receivingAssetId;
            uint256 curBalance;

            _;

            for (uint256 i = 0; i < numSwaps - 1; ) {
                address curAsset = _swaps[i].receivingAssetId;
                // Handle multi-to-one swaps
                if (curAsset != finalAsset) {
                    curBalance =
                        LibAsset.getOwnBalance(curAsset) -
                        _initialBalances[i];
                    uint256 reserve = LibAsset.isNativeAsset(curAsset)
                        ? _nativeReserve
                        : 0;
                    if (curBalance > 0) {
                        LibAsset.transferAsset(
                            curAsset,
                            _leftoverReceiver,
                            curBalance - reserve
                        );
                    }
                }
                unchecked {
                    ++i;
                }
            }
        } else {
            _;
        }
    }

    /// @dev Refunds any excess native asset sent to the contract after the main function
    /// @notice Refunds any excess native asset sent to the contract after the main function
    /// @param _refundReceiver Address to send refunds to
    modifier refundExcessNative(address payable _refundReceiver) {
        uint256 initialBalance = address(this).balance - msg.value;
        _;
        uint256 finalBalance = address(this).balance;

        if (finalBalance > initialBalance) {
            LibAsset.transferAsset(
                LibAsset.NATIVE_ASSETID,
                _refundReceiver,
                finalBalance - initialBalance
            );
        }
    }

    /// Internal Methods ///

    /// @dev Deposits value, executes swaps, and performs minimum amount check
    /// @param _transactionId the transaction id associated with the operation
    /// @param _minAmount the minimum amount of the final asset to receive
    /// @param _swaps Array of data used to execute swaps
    /// @param _leftoverReceiver The address to send leftover funds to
    /// @return uint256 result of the swap
    function _depositAndSwap(
        bytes32 _transactionId,
        uint256 _minAmount,
        LibSwap.SwapData[] calldata _swaps,
        address payable _leftoverReceiver
    ) internal returns (uint256) {
        uint256 numSwaps = _swaps.length;

        if (numSwaps == 0) {
            revert NoSwapDataProvided();
        }

        address finalTokenId = _swaps[numSwaps - 1].receivingAssetId;
        uint256 initialBalance = LibAsset.getOwnBalance(finalTokenId);

        if (LibAsset.isNativeAsset(finalTokenId)) {
            initialBalance -= msg.value;
        }

        uint256[] memory initialBalances = _fetchBalances(_swaps);

        LibAsset.depositAssets(_swaps);
        _executeSwaps(
            _transactionId,
            _swaps,
            _leftoverReceiver,
            initialBalances
        );

        uint256 newBalance = LibAsset.getOwnBalance(finalTokenId) -
            initialBalance;

        if (newBalance < _minAmount) {
            revert CumulativeSlippageTooHigh(_minAmount, newBalance);
        }

        return newBalance;
    }

    /// @dev Deposits value, executes swaps, and performs minimum amount check and reserves native token for fees
    /// @param _transactionId the transaction id associated with the operation
    /// @param _minAmount the minimum amount of the final asset to receive
    /// @param _swaps Array of data used to execute swaps
    /// @param _leftoverReceiver The address to send leftover funds to
    /// @param _nativeReserve Amount of native token to prevent from being swept back to the caller
    function _depositAndSwap(
        bytes32 _transactionId,
        uint256 _minAmount,
        LibSwap.SwapData[] calldata _swaps,
        address payable _leftoverReceiver,
        uint256 _nativeReserve
    ) internal returns (uint256) {
        uint256 numSwaps = _swaps.length;

        if (numSwaps == 0) {
            revert NoSwapDataProvided();
        }

        address finalTokenId = _swaps[numSwaps - 1].receivingAssetId;
        uint256 initialBalance = LibAsset.getOwnBalance(finalTokenId);

        if (LibAsset.isNativeAsset(finalTokenId)) {
            initialBalance -= msg.value;
        }

        uint256[] memory initialBalances = _fetchBalances(_swaps);

        LibAsset.depositAssets(_swaps);
        ReserveData memory rd = ReserveData(
            _transactionId,
            _leftoverReceiver,
            _nativeReserve
        );
        _executeSwaps(rd, _swaps, initialBalances);

        uint256 newBalance = LibAsset.getOwnBalance(finalTokenId) -
            initialBalance;

        if (LibAsset.isNativeAsset(finalTokenId)) {
            newBalance -= _nativeReserve;
        }

        if (newBalance < _minAmount) {
            revert CumulativeSlippageTooHigh(_minAmount, newBalance);
        }

        return newBalance;
    }

    /// Private Methods ///

    /// @dev Executes swaps and checks that DEXs used are in the allowList
    /// @param _transactionId the transaction id associated with the operation
    /// @param _swaps Array of data used to execute swaps
    /// @param _leftoverReceiver Address to send leftover tokens to
    /// @param _initialBalances Array of initial balances
    function _executeSwaps(
        bytes32 _transactionId,
        LibSwap.SwapData[] calldata _swaps,
        address payable _leftoverReceiver,
        uint256[] memory _initialBalances
    ) internal noLeftovers(_swaps, _leftoverReceiver, _initialBalances) {
        uint256 numSwaps = _swaps.length;
        for (uint256 i = 0; i < numSwaps; ) {
            LibSwap.SwapData calldata currentSwap = _swaps[i];

            if (
                !((LibAsset.isNativeAsset(currentSwap.sendingAssetId) ||
                    LibAllowList.contractIsAllowed(currentSwap.approveTo)) &&
                    LibAllowList.contractIsAllowed(currentSwap.callTo) &&
                    LibAllowList.selectorIsAllowed(
                        bytes4(currentSwap.callData[:4])
                    ))
            ) revert ContractCallNotAllowed();

            LibSwap.swap(_transactionId, currentSwap);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Executes swaps and checks that DEXs used are in the allowList
    /// @param _reserveData Data passed used to reserve native tokens
    /// @param _swaps Array of data used to execute swaps
    function _executeSwaps(
        ReserveData memory _reserveData,
        LibSwap.SwapData[] calldata _swaps,
        uint256[] memory _initialBalances
    )
        internal
        noLeftoversReserve(
            _swaps,
            _reserveData.leftoverReceiver,
            _initialBalances,
            _reserveData.nativeReserve
        )
    {
        uint256 numSwaps = _swaps.length;
        for (uint256 i = 0; i < numSwaps; ) {
            LibSwap.SwapData calldata currentSwap = _swaps[i];

            if (
                !((LibAsset.isNativeAsset(currentSwap.sendingAssetId) ||
                    LibAllowList.contractIsAllowed(currentSwap.approveTo)) &&
                    LibAllowList.contractIsAllowed(currentSwap.callTo) &&
                    LibAllowList.selectorIsAllowed(
                        bytes4(currentSwap.callData[:4])
                    ))
            ) revert ContractCallNotAllowed();

            LibSwap.swap(_reserveData.transactionId, currentSwap);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Fetches balances of tokens to be swapped before swapping.
    /// @param _swaps Array of data used to execute swaps
    /// @return uint256[] Array of token balances.
    function _fetchBalances(
        LibSwap.SwapData[] calldata _swaps
    ) private view returns (uint256[] memory) {
        uint256 numSwaps = _swaps.length;
        uint256[] memory balances = new uint256[](numSwaps);
        address asset;
        for (uint256 i = 0; i < numSwaps; ) {
            asset = _swaps[i].receivingAssetId;
            balances[i] = LibAsset.getOwnBalance(asset);

            if (LibAsset.isNativeAsset(asset)) {
                balances[i] -= msg.value;
            }

            unchecked {
                ++i;
            }
        }

        return balances;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { LibAsset } from "../Libraries/LibAsset.sol";
import { LibUtil } from "../Libraries/LibUtil.sol";
import { InvalidReceiver, InformationMismatch, InvalidSendingToken, InvalidAmount, NativeAssetNotSupported, InvalidDestinationChain, CannotBridgeToSameNetwork } from "../Errors/GenericErrors.sol";
import { ILiFi } from "../Interfaces/ILiFi.sol";
import { LibSwap } from "../Libraries/LibSwap.sol";

contract Validatable {
    modifier validateBridgeData(ILiFi.BridgeData memory _bridgeData) {
        if (LibUtil.isZeroAddress(_bridgeData.receiver)) {
            revert InvalidReceiver();
        }
        if (_bridgeData.minAmount == 0) {
            revert InvalidAmount();
        }
        if (_bridgeData.destinationChainId == block.chainid) {
            revert CannotBridgeToSameNetwork();
        }
        _;
    }

    modifier noNativeAsset(ILiFi.BridgeData memory _bridgeData) {
        if (LibAsset.isNativeAsset(_bridgeData.sendingAssetId)) {
            revert NativeAssetNotSupported();
        }
        _;
    }

    modifier onlyAllowSourceToken(
        ILiFi.BridgeData memory _bridgeData,
        address _token
    ) {
        if (_bridgeData.sendingAssetId != _token) {
            revert InvalidSendingToken();
        }
        _;
    }

    modifier onlyAllowDestinationChain(
        ILiFi.BridgeData memory _bridgeData,
        uint256 _chainId
    ) {
        if (_bridgeData.destinationChainId != _chainId) {
            revert InvalidDestinationChain();
        }
        _;
    }

    modifier containsSourceSwaps(ILiFi.BridgeData memory _bridgeData) {
        if (!_bridgeData.hasSourceSwaps) {
            revert InformationMismatch();
        }
        _;
    }

    modifier doesNotContainSourceSwaps(ILiFi.BridgeData memory _bridgeData) {
        if (_bridgeData.hasSourceSwaps) {
            revert InformationMismatch();
        }
        _;
    }

    modifier doesNotContainDestinationCalls(
        ILiFi.BridgeData memory _bridgeData
    ) {
        if (_bridgeData.hasDestinationCall) {
            revert InformationMismatch();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMayan {
    struct PermitParams {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function forwardEth(
        address mayanProtocol,
        bytes calldata protocolData
    ) external payable;

    function forwardERC20(
        address tokenIn,
        uint256 amountIn,
        PermitParams calldata permitParams,
        address mayanProtocol,
        bytes calldata protocolData
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

    function revertWith(bytes memory data) internal pure {
        assembly {
            let dataSize := mload(data) // Load the size of the data
            let dataPtr := add(data, 0x20) // Advance data pointer to the next word
            revert(dataPtr, dataSize) // Revert with the given data
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
pragma solidity 0.8.17;

import { InvalidContract } from "../Errors/GenericErrors.sol";

/// @title Lib Allow List
/// @author LI.FI (https://li.fi)
/// @notice Library for managing and accessing the conract address allow list
library LibAllowList {
    /// Storage ///
    bytes32 internal constant NAMESPACE =
        keccak256("com.lifi.library.allow.list");

    struct AllowListStorage {
        mapping(address => bool) allowlist;
        mapping(bytes4 => bool) selectorAllowList;
        address[] contracts;
    }

    /// @dev Adds a contract address to the allow list
    /// @param _contract the contract address to add
    function addAllowedContract(address _contract) internal {
        _checkAddress(_contract);

        AllowListStorage storage als = _getStorage();

        if (als.allowlist[_contract]) return;

        als.allowlist[_contract] = true;
        als.contracts.push(_contract);
    }

    /// @dev Checks whether a contract address has been added to the allow list
    /// @param _contract the contract address to check
    function contractIsAllowed(
        address _contract
    ) internal view returns (bool) {
        return _getStorage().allowlist[_contract];
    }

    /// @dev Remove a contract address from the allow list
    /// @param _contract the contract address to remove
    function removeAllowedContract(address _contract) internal {
        AllowListStorage storage als = _getStorage();

        if (!als.allowlist[_contract]) {
            return;
        }

        als.allowlist[_contract] = false;

        uint256 length = als.contracts.length;
        // Find the contract in the list
        for (uint256 i = 0; i < length; i++) {
            if (als.contracts[i] == _contract) {
                // Move the last element into the place to delete
                als.contracts[i] = als.contracts[length - 1];
                // Remove the last element
                als.contracts.pop();
                break;
            }
        }
    }

    /// @dev Fetch contract addresses from the allow list
    function getAllowedContracts() internal view returns (address[] memory) {
        return _getStorage().contracts;
    }

    /// @dev Add a selector to the allow list
    /// @param _selector the selector to add
    function addAllowedSelector(bytes4 _selector) internal {
        _getStorage().selectorAllowList[_selector] = true;
    }

    /// @dev Removes a selector from the allow list
    /// @param _selector the selector to remove
    function removeAllowedSelector(bytes4 _selector) internal {
        _getStorage().selectorAllowList[_selector] = false;
    }

    /// @dev Returns if selector has been added to the allow list
    /// @param _selector the selector to check
    function selectorIsAllowed(bytes4 _selector) internal view returns (bool) {
        return _getStorage().selectorAllowList[_selector];
    }

    /// @dev Fetch local storage struct
    function _getStorage()
        internal
        pure
        returns (AllowListStorage storage als)
    {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            als.slot := position
        }
    }

    /// @dev Contains business logic for validating a contract address.
    /// @param _contract address of the dex to check
    function _checkAddress(address _contract) private view {
        if (_contract == address(0)) revert InvalidContract();

        if (_contract.code.length == 0) revert InvalidContract();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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