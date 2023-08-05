// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "SafeMath.sol";

import "LibDiamond.sol";
import "LibBytes.sol";
import "LibCross.sol";
import "LibAsset.sol";
import "LibMessageCCTP.sol";
import "Swapper.sol";
import "TypedMemView.sol";
import "ReentrancyGuard.sol";
import "ISo.sol";
import "ILibSoFee.sol";
import "ITokenMessenger.sol";
import "IReceiver.sol";
import "ILibPrice.sol";
import "IMessageHandler.sol";
import "IMessageTransmitter.sol";

/// @title CCTP Facet
/// @author OmniBTC
/// @notice Provides functionality for bridging through CCTP
contract CCTPFacet is Swapper, ReentrancyGuard, IMessageHandler {
    using SafeMath for uint256;
    using LibBytes for bytes;
    using TypedMemView for bytes29;

    /// Storage ///

    bytes32 internal constant NAMESPACE =
        hex"ed7099a4d8ec3979659a0931894724cfba9c270625d87b539a3d3a9e869c389e"; // keccak256("com.so.facets.cctp")

    uint256 public constant RAY = 1e27;

    struct Storage {
        address tokenMessenger;
        address messageTransmitter;
        mapping(uint32 => uint256) dstBaseGas;
        mapping(uint32 => uint256) dstGasPerBytes;
    }

    /// Events ///
    event InitCCTP(address tokenMessenger, address messageTransmitter);
    event RelayEvent(bytes32 transactionId, uint256 fee);

    /// Types ///

    struct CCTPData {
        // Chain ID defined by CCTP
        uint32 destinationDomain;
        // Destination chain's diamond
        bytes32 dstDiamond;
        // CCTP supports tokens across chains
        address burnToken;
    }

    struct CachePayload {
        ISo.NormalizedSoData soData;
        LibSwap.NormalizedSwapData[] swapDataDst;
    }

    /// Init Methods ///

    /// @dev Set CCTP's token bridge address and message transmitter address
    /// @param _tokenMessenger cctp token bridge
    /// @param _messageTransmitter cctp message protocol
    function initCCTP(address _tokenMessenger, address _messageTransmitter)
        external
    {
        LibDiamond.enforceIsContractOwner();
        Storage storage s = getStorage();
        s.tokenMessenger = _tokenMessenger;
        s.messageTransmitter = _messageTransmitter;
        emit InitCCTP(_tokenMessenger, _messageTransmitter);
    }

    /// External Methods ///

    /// @dev Set the minimum gas to be spent on the destination chain
    /// @param destinationDomains  a batch of destination domain id
    /// @param dstBaseGas  base gas for destination chain
    function setCCTPBaseGas(
        uint32[] calldata destinationDomains,
        uint256 dstBaseGas
    ) external {
        LibDiamond.enforceIsContractOwner();
        Storage storage s = getStorage();

        for (uint64 i; i < destinationDomains.length; i++) {
            s.dstBaseGas[destinationDomains[i]] = dstBaseGas;
        }
    }

    /// @dev Set the minimum gas to be spent on the destination chain
    /// @param destinationDomains  a batch of destination domain id
    /// @param dstGasPerBytes gas per bytes for destination chain
    function setCCTPGasPerBytes(
        uint32[] calldata destinationDomains,
        uint256 dstGasPerBytes
    ) external {
        LibDiamond.enforceIsContractOwner();
        Storage storage s = getStorage();

        for (uint64 i; i < destinationDomains.length; i++) {
            s.dstGasPerBytes[destinationDomains[i]] = dstGasPerBytes;
        }
    }

    /// @dev Bridge tokens via CCTP
    /// @param soDataNo data for tracking cross-chain transactions and a
    ///                 portion of the accompanying cross-chain messages
    /// @param swapDataSrcNo contains a set of data required for Swap
    ///                     transactions on the source chain side
    /// @param cctpData data used to call CCTP's TokenMessenger for cross usdc
    function soSwapViaCCTP(
        ISo.NormalizedSoData calldata soDataNo,
        LibSwap.NormalizedSwapData[] calldata swapDataSrcNo,
        CCTPData calldata cctpData,
        LibSwap.NormalizedSwapData[] calldata swapDataDstNo
    ) external payable {
        uint256 bridgeAmount;

        ISo.SoData memory soData = LibCross.denormalizeSoData(soDataNo);
        LibSwap.SwapData[] memory swapDataSrc = LibCross.denormalizeSwapData(
            swapDataSrcNo
        );

        if (!LibAsset.isNativeAsset(soData.sendingAssetId)) {
            LibAsset.depositAsset(soData.sendingAssetId, soData.amount);
        }

        // calculate relay fee
        uint256 relay_fee = 0;
        if (LibAsset.isNativeAsset(soData.sendingAssetId)) {
            require(msg.value > soData.amount, "ValueErr");
            relay_fee = msg.value - soData.amount;
        } else {
            relay_fee = msg.value;
        }

        if (relay_fee > 0) {
            LibAsset.transferAsset(
                LibAsset.NATIVE_ASSETID,
                payable(LibDiamond.contractOwner()),
                relay_fee
            );
            emit RelayEvent(soData.transactionId, relay_fee);
        }

        if (swapDataSrc.length == 0) {
            require(soData.sendingAssetId == cctpData.burnToken, "TokenErr");
            bridgeAmount = soData.amount;
        } else {
            require(soData.amount == swapDataSrc[0].fromAmount, "AmountErr");
            bridgeAmount = this.executeAndCheckSwaps(soData, swapDataSrc);
            require(
                swapDataSrc[swapDataSrc.length - 1].receivingAssetId ==
                    cctpData.burnToken,
                "TokenErr"
            );
        }

        bytes memory payload = encodeCCTPPayloadWithAmount(
            soDataNo,
            swapDataDstNo,
            bridgeAmount
        );

        require(bridgeAmount > 0, "bridgeAmount>0");
        _startBridge(cctpData, bridgeAmount, payload);

        emit SoTransferStarted(soData.transactionId);
    }

    /// CrossData
    // 1. length + amount(SoData)
    // 2. length + transactionId(SoData)
    // 3. length + receiver(SoData)
    // 4. length + receivingAssetId(SoData)
    // 5. length + swapDataLength(u8)
    // 6. length + callTo(SwapData)
    // 7. length + sendingAssetId(SwapData)
    // 8. length + receivingAssetId(SwapData)
    // 9. length + callData(SwapData)
    function encodeCCTPPayloadWithAmount(
        ISo.NormalizedSoData memory soData,
        LibSwap.NormalizedSwapData[] memory swapDataDst,
        uint256 bridgeAmount
    ) public pure returns (bytes memory) {
        bytes memory bridgeAmountByte = LibCross.serializeU256WithHexStr(
            bridgeAmount
        );

        bytes memory encodeData = abi.encodePacked(
            uint8(bridgeAmountByte.length),
            bridgeAmountByte,
            uint8(soData.transactionId.length),
            soData.transactionId,
            uint8(soData.receiver.length),
            soData.receiver,
            uint8(soData.receivingAssetId.length),
            soData.receivingAssetId
        );

        if (swapDataDst.length > 0) {
            bytes memory swapLenBytes = LibCross.serializeU256WithHexStr(
                swapDataDst.length
            );
            encodeData = encodeData.concat(
                abi.encodePacked(uint8(swapLenBytes.length), swapLenBytes)
            );
        }

        for (uint256 i = 0; i < swapDataDst.length; i++) {
            encodeData = encodeData.concat(
                abi.encodePacked(
                    uint8(swapDataDst[i].callTo.length),
                    swapDataDst[i].callTo,
                    uint8(swapDataDst[i].sendingAssetId.length),
                    swapDataDst[i].sendingAssetId,
                    uint8(swapDataDst[i].receivingAssetId.length),
                    swapDataDst[i].receivingAssetId,
                    uint16(swapDataDst[i].callData.length),
                    swapDataDst[i].callData
                )
            );
        }
        return encodeData;
    }

    /// CrossData
    // 1. length + amount(SoData)
    // 2. length + transactionId(SoData)
    // 3. length + receiver(SoData)
    // 4. length + receivingAssetId(SoData)
    // 5. length + swapDataLength(u8)
    // 6. length + callTo(SwapData)
    // 7. length + sendingAssetId(SwapData)
    // 8. length + receivingAssetId(SwapData)
    // 9. length + callData(SwapData)
    function decodeCCTPPayload(bytes memory cctpPayload)
        public
        pure
        returns (
            ISo.NormalizedSoData memory soData,
            LibSwap.NormalizedSwapData[] memory swapDataDst
        )
    {
        CachePayload memory data;
        uint256 index;
        uint256 nextLen;

        nextLen = uint256(cctpPayload.toUint8(index));
        index += 1;
        data.soData.amount = LibCross.deserializeU256WithHexStr(
            cctpPayload.slice(index, nextLen)
        );
        index += nextLen;

        nextLen = uint256(cctpPayload.toUint8(index));
        index += 1;
        data.soData.transactionId = cctpPayload.slice(index, nextLen);
        index += nextLen;

        nextLen = uint256(cctpPayload.toUint8(index));
        index += 1;
        data.soData.receiver = cctpPayload.slice(index, nextLen);
        index += nextLen;

        nextLen = uint256(cctpPayload.toUint8(index));
        index += 1;
        data.soData.receivingAssetId = cctpPayload.slice(index, nextLen);
        index += nextLen;

        if (index < cctpPayload.length) {
            nextLen = uint256(cctpPayload.toUint8(index));
            index += 1;
            uint256 swap_len = LibCross.deserializeU256WithHexStr(
                cctpPayload.slice(index, nextLen)
            );
            index += nextLen;

            data.swapDataDst = new LibSwap.NormalizedSwapData[](swap_len);
            for (uint256 i = 0; i < swap_len; i++) {
                nextLen = uint256(cctpPayload.toUint8(index));
                index += 1;
                data.swapDataDst[i].callTo = cctpPayload.slice(index, nextLen);
                data.swapDataDst[i].approveTo = data.swapDataDst[i].callTo;
                index += nextLen;

                nextLen = uint256(cctpPayload.toUint8(index));
                index += 1;
                data.swapDataDst[i].sendingAssetId = cctpPayload.slice(
                    index,
                    nextLen
                );
                index += nextLen;

                nextLen = uint256(cctpPayload.toUint8(index));
                index += 1;
                data.swapDataDst[i].receivingAssetId = cctpPayload.slice(
                    index,
                    nextLen
                );
                index += nextLen;

                nextLen = uint256(cctpPayload.toUint16(index));
                index += 2;
                data.swapDataDst[i].callData = cctpPayload.slice(
                    index,
                    nextLen
                );
                index += nextLen;
            }
        }
        require(index == cctpPayload.length, "LenErr");
        return (data.soData, data.swapDataDst);
    }

    function decodeCCTPMessage(bytes memory message)
        public
        view
        returns (LibMessageCCTP.CCTPMessage memory)
    {
        LibMessageCCTP.CCTPMessage memory data;
        bytes29 _msg = TypedMemView.ref(message, 0);
        data._msgVersion = LibMessageCCTP._version(_msg);
        data._msgSourceDomain = LibMessageCCTP._sourceDomain(_msg);
        data._msgDestinationDomain = LibMessageCCTP._destinationDomain(_msg);
        data._msgNonce = LibMessageCCTP._nonce(_msg);
        data._msgSender = LibMessageCCTP._sender(_msg);
        data._msgRecipient = LibMessageCCTP._recipient(_msg);
        data._msgDestinationCaller = LibMessageCCTP._destinationCaller(_msg);
        data._msgRawBody = LibMessageCCTP._messageBody(_msg).clone();
        return data;
    }

    function handleReceiveMessage(
        uint32,
        bytes32,
        bytes calldata messageBody
    ) external override returns (bool) {
        Storage storage s = getStorage();
        require(
            msg.sender == s.messageTransmitter,
            "Only message transmitter can call"
        );

        (
            ISo.NormalizedSoData memory soDataNo,
            LibSwap.NormalizedSwapData[] memory swapDataDstNo
        ) = decodeCCTPPayload(messageBody);

        ISo.SoData memory soData = LibCross.denormalizeSoData(soDataNo);
        LibSwap.SwapData[] memory swapDataDst = LibCross.denormalizeSwapData(
            swapDataDstNo
        );

        // cross-chain loss not exist in burn-mint mode
        uint256 amount = soData.amount;

        uint256 soFee = getCCTPSoFee(amount);
        if (soFee < amount) {
            amount = amount.sub(soFee);
        }

        if (swapDataDst.length == 0) {
            if (soFee > 0) {
                LibAsset.transferAsset(
                    soData.receivingAssetId,
                    payable(LibDiamond.contractOwner()),
                    soFee
                );
            }
            LibAsset.transferAsset(
                soData.receivingAssetId,
                soData.receiver,
                amount
            );
            emit SoTransferCompleted(soData.transactionId, amount);
        } else {
            if (soFee > 0) {
                LibAsset.transferAsset(
                    swapDataDst[0].sendingAssetId,
                    payable(LibDiamond.contractOwner()),
                    soFee
                );
            }
            swapDataDst[0].fromAmount = amount;

            address correctSwap = appStorage.correctSwapRouterSelectors;

            if (correctSwap != address(0)) {
                swapDataDst[0].callData = ICorrectSwap(correctSwap).correctSwap(
                    swapDataDst[0].callData,
                    swapDataDst[0].fromAmount
                );
            }

            try this.executeAndCheckSwaps(soData, swapDataDst) returns (
                uint256 amountFinal
            ) {
                transferUnwrappedAsset(
                    swapDataDst[swapDataDst.length - 1].receivingAssetId,
                    soData.receivingAssetId,
                    amountFinal,
                    soData.receiver
                );
                emit SoTransferCompleted(soData.transactionId, amountFinal);
            } catch Error(string memory revertReason) {
                LibAsset.transferAsset(
                    swapDataDst[0].sendingAssetId,
                    soData.receiver,
                    amount
                );
                emit SoTransferFailed(
                    soData.transactionId,
                    revertReason,
                    bytes("")
                );
            } catch (bytes memory returnData) {
                LibAsset.transferAsset(
                    swapDataDst[0].sendingAssetId,
                    soData.receiver,
                    amount
                );
                emit SoTransferFailed(soData.transactionId, "", returnData);
            }
        }

        return true;
    }

    function receiveCCTPMessage(
        bytes calldata tokenMessage,
        bytes calldata tokenAttestation,
        bytes calldata message,
        bytes calldata attestation
    ) external {
        Storage storage s = getStorage();

        // check token and msg nonce
        bytes29 tokenMsg = TypedMemView.ref(tokenMessage, 0);
        uint64 tokenNonce = LibMessageCCTP._nonce(tokenMsg);
        bytes29 _msg = TypedMemView.ref(message, 0);
        uint64 nonce = LibMessageCCTP._nonce(_msg);
        require(tokenNonce + 1 == nonce, "nonce mismatch");

        IReceiver(s.messageTransmitter).receiveMessage(
            tokenMessage,
            tokenAttestation
        );
        IReceiver(s.messageTransmitter).receiveMessage(message, attestation);
    }

    function receiveCCTPMessageByOwner(
        bytes calldata tokenMessage,
        bytes calldata tokenAttestation
    ) external {
        LibDiamond.enforceIsContractOwner();
        Storage storage s = getStorage();

        IReceiver(s.messageTransmitter).receiveMessage(
            tokenMessage,
            tokenAttestation
        );
    }

    /// @dev estimate dst swap gas
    function estimateReceiveCCTPMessageGas(
        ISo.NormalizedSoData calldata soDataNo,
        CCTPData calldata cctpData,
        LibSwap.NormalizedSwapData[] calldata swapDataDstNo
    ) public view returns (uint256) {
        bytes memory payload = encodeCCTPPayloadWithAmount(
            soDataNo,
            swapDataDstNo,
            uint256(0)
        );
        Storage storage s = getStorage();
        return
            s.dstBaseGas[cctpData.destinationDomain].add(
                s.dstGasPerBytes[cctpData.destinationDomain].mul(payload.length)
            );
    }

    /// @dev Get so fee
    function getCCTPSoFee(uint256 amount) public view returns (uint256) {
        Storage storage s = getStorage();
        address soFee = appStorage.gatewaySoFeeSelectors[s.tokenMessenger];
        if (soFee == address(0x0)) {
            return 0;
        } else {
            return ILibSoFee(soFee).getFees(amount);
        }
    }

    /// Internal Methods ///
    function _startBridge(
        CCTPData calldata cctpData,
        uint256 bridgeAmount,
        bytes memory payload
    ) internal {
        Storage storage s = getStorage();
        // Give TokenMessenger approval to bridge tokens
        LibAsset.maxApproveERC20(
            IERC20(cctpData.burnToken),
            s.tokenMessenger,
            bridgeAmount
        );

        ITokenMessenger(s.tokenMessenger).depositForBurnWithCaller(
            bridgeAmount,
            cctpData.destinationDomain,
            cctpData.dstDiamond,
            cctpData.burnToken,
            cctpData.dstDiamond
        );

        IMessageTransmitter(s.messageTransmitter).sendMessageWithCaller(
            cctpData.destinationDomain,
            cctpData.dstDiamond,
            cctpData.dstDiamond,
            payload
        );
    }

    /// Private Methods ///

    /// @dev fetch local storage
    function getStorage() private pure returns (Storage storage s) {
        bytes32 namespace = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IDiamondCut} from "IDiamondCut.sol";

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

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
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
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
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
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
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
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
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
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
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
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
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
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

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            // solhint-disable-next-line avoid-low-level-calls
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

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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
pragma solidity 0.8.13;

library LibBytes {
    // solhint-disable no-inline-assembly

    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function indexOf(
        bytes memory _bytes,
        uint8 _e,
        uint256 _start
    ) internal pure returns (uint256) {
        while (_start < _bytes.length) {
            if (toUint8(_bytes, _start) == _e) {
                return _start;
            }
            _start += 1;
        }
        return _bytes.length;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

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

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint16)
    {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint32)
    {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint64)
    {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint96)
    {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint128)
    {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes32)
    {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        // solhint-disable-next-line no-empty-blocks
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ISo} from "ISo.sol";
import {LibSwap} from "LibSwap.sol";
import {LibBytes} from "LibBytes.sol";

library LibCross {
    using LibBytes for bytes;

    function normalizeSoData(ISo.SoData memory soData)
        internal
        pure
        returns (ISo.NormalizedSoData memory)
    {
        ISo.NormalizedSoData memory data;
        data.transactionId = abi.encodePacked(soData.transactionId);
        data.receiver = abi.encodePacked(soData.receiver);
        data.sourceChainId = soData.sourceChainId;
        data.sendingAssetId = abi.encodePacked(soData.sendingAssetId);
        data.destinationChainId = soData.destinationChainId;
        data.receivingAssetId = abi.encodePacked(soData.receivingAssetId);
        data.amount = soData.amount;

        return data;
    }

    function tryAddress(bytes memory data) internal pure returns (address) {
        if (data.length == 20) {
            return data.toAddress(0);
        } else {
            return address(0);
        }
    }

    function denormalizeSoData(ISo.NormalizedSoData memory data)
        internal
        pure
        returns (ISo.SoData memory)
    {
        return
            ISo.SoData({
                transactionId: data.transactionId.toBytes32(0),
                receiver: payable(tryAddress(data.receiver)),
                sourceChainId: data.sourceChainId,
                sendingAssetId: tryAddress(data.sendingAssetId),
                destinationChainId: data.destinationChainId,
                receivingAssetId: tryAddress(data.receivingAssetId),
                amount: data.amount
            });
    }

    function normalizeSwapData(LibSwap.SwapData[] memory swapData)
        internal
        pure
        returns (LibSwap.NormalizedSwapData[] memory)
    {
        LibSwap.NormalizedSwapData[]
            memory data = new LibSwap.NormalizedSwapData[](swapData.length);

        for (uint256 i = 0; i < swapData.length; i++) {
            data[i].callTo = abi.encodePacked(swapData[i].callTo);
            data[i].approveTo = abi.encodePacked(swapData[i].approveTo);
            data[i].sendingAssetId = abi.encodePacked(
                swapData[i].sendingAssetId
            );
            data[i].receivingAssetId = abi.encodePacked(
                swapData[i].receivingAssetId
            );
            data[i].fromAmount = swapData[i].fromAmount;
            data[i].callData = abi.encodePacked(swapData[i].callData);
        }

        return data;
    }

    function denormalizeSwapData(LibSwap.NormalizedSwapData[] memory data)
        internal
        pure
        returns (LibSwap.SwapData[] memory)
    {
        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](
            data.length
        );
        for (uint256 i = 0; i < swapData.length; i++) {
            swapData[i].callTo = data[i].callTo.toAddress(0);
            swapData[i].approveTo = data[i].approveTo.toAddress(0);
            swapData[i].sendingAssetId = data[i].sendingAssetId.toAddress(0);
            swapData[i].receivingAssetId = data[i].receivingAssetId.toAddress(
                0
            );
            swapData[i].fromAmount = data[i].fromAmount;
            swapData[i].callData = data[i].callData;
        }
        return swapData;
    }

    function encodeNormalizedSoData(ISo.NormalizedSoData memory data)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encodeData = abi.encodePacked(
            uint64(data.transactionId.length),
            data.transactionId,
            uint64(data.receiver.length),
            data.receiver,
            data.sourceChainId
        );
        // Avoid variable value1 is 1 slot(s) too deep;
        encodeData = encodeData.concat(
            abi.encodePacked(
                uint64(data.sendingAssetId.length),
                data.sendingAssetId,
                data.destinationChainId,
                uint64(data.receivingAssetId.length),
                data.receivingAssetId,
                data.amount
            )
        );
        return encodeData;
    }

    function decodeNormalizedSoData(bytes memory soData)
        internal
        pure
        returns (ISo.NormalizedSoData memory)
    {
        ISo.NormalizedSoData memory data;
        uint256 index;
        uint256 nextLen;

        nextLen = uint256(soData.toUint64(index));
        index += 8;
        data.transactionId = soData.slice(index, nextLen);
        index += nextLen;

        nextLen = uint256(soData.toUint64(index));
        index += 8;
        data.receiver = soData.slice(index, nextLen);
        index += nextLen;

        nextLen = 2;
        data.sourceChainId = soData.toUint16(index);
        index += nextLen;

        nextLen = uint256(soData.toUint64(index));
        index += 8;
        data.sendingAssetId = soData.slice(index, nextLen);
        index += nextLen;

        nextLen = 2;
        data.destinationChainId = soData.toUint16(index);
        index += nextLen;

        nextLen = uint256(soData.toUint64(index));
        index += 8;
        data.receivingAssetId = soData.slice(index, nextLen);
        index += nextLen;

        nextLen = 32;
        data.amount = soData.toUint256(index);
        index += nextLen;

        require(index == soData.length, "Length error");

        return data;
    }

    function encodeNormalizedSwapData(LibSwap.NormalizedSwapData[] memory data)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encodeData = bytes("");

        if (data.length > 0) {
            encodeData = abi.encodePacked(uint64(data.length));
        }

        for (uint256 i = 0; i < data.length; i++) {
            encodeData = encodeData.concat(
                abi.encodePacked(
                    uint64(data[i].callTo.length),
                    data[i].callTo,
                    uint64(data[i].approveTo.length),
                    data[i].approveTo,
                    uint64(data[i].sendingAssetId.length),
                    data[i].sendingAssetId
                )
            );
            // Avoid variable value1 is 1 slot(s) too deep;
            encodeData = encodeData.concat(
                abi.encodePacked(
                    uint64(data[i].receivingAssetId.length),
                    data[i].receivingAssetId,
                    data[i].fromAmount,
                    uint64(data[i].callData.length),
                    data[i].callData
                )
            );
        }

        return encodeData;
    }

    function decodeNormalizedSwapData(bytes memory swapData)
        internal
        pure
        returns (LibSwap.NormalizedSwapData[] memory)
    {
        uint256 index;
        uint256 nextLen;

        nextLen = 8;
        uint256 swapLen = uint256(swapData.toUint64(index));
        index += nextLen;

        LibSwap.NormalizedSwapData[]
            memory data = new LibSwap.NormalizedSwapData[](swapLen);

        for (uint256 i = 0; i < swapLen; i++) {
            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].callTo = swapData.slice(index, nextLen);
            index += nextLen;

            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].approveTo = swapData.slice(index, nextLen);
            index += nextLen;

            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].sendingAssetId = swapData.slice(index, nextLen);
            index += nextLen;

            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].receivingAssetId = swapData.slice(index, nextLen);
            index += nextLen;

            nextLen = 32;
            data[i].fromAmount = swapData.toUint256(index);
            index += nextLen;

            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].callData = swapData.slice(index, nextLen);
            index += nextLen;
        }

        require(index == swapData.length, "Length error");

        return data;
    }

    function serializeU256WithHexStr(uint256 data)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encodeData = abi.encodePacked(uint8(data & 0xFF));
        data = data >> 8;

        while (data != 0) {
            encodeData = abi.encodePacked(uint8(data & 0xFF)).concat(
                encodeData
            );
            data = data >> 8;
        }
        return encodeData;
    }

    function deserializeU256WithHexStr(bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 buf = 0;
        for (uint256 i = 0; i < data.length; i++) {
            buf = (buf << 8) + data.toUint8(i);
        }
        return buf;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISo {
    /// Structs ///

    struct SoData {
        bytes32 transactionId; // unique identification id
        address payable receiver; // token receiving account
        uint16 sourceChainId; // source chain id
        address sendingAssetId; // The starting token address of the source chain
        uint16 destinationChainId; // destination chain id
        address receivingAssetId; // The final token address of the destination chain
        uint256 amount; // User enters amount
    }

    struct NormalizedSoData {
        bytes transactionId; // unique identification id
        bytes receiver; // token receiving account
        uint16 sourceChainId; // source chain id
        bytes sendingAssetId; // The starting token address of the source chain
        uint16 destinationChainId; // destination chain id
        bytes receivingAssetId; // The final token address of the destination chain
        uint256 amount; // User enters amount
    }

    /// Events ///

    event SoTransferStarted(bytes32 indexed transactionId);

    event SoTransferFailed(
        bytes32 indexed transactionId,
        string revertReason,
        bytes otherReason
    );

    event SoTransferCompleted(
        bytes32 indexed transactionId,
        uint256 receiveAmount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {LibAsset, IERC20} from "LibAsset.sol";
import {LibUtil} from "LibUtil.sol";
import {InvalidContract} from "GenericErrors.sol";

library LibSwap {
    error NoSwapFromZeroBalance();

    struct SwapData {
        address callTo; // The swap address
        address approveTo; // The swap address
        address sendingAssetId; // The swap start token address
        address receivingAssetId; // The swap final token address
        uint256 fromAmount; // The swap start token amount
        bytes callData; // The swap callData
    }

    struct NormalizedSwapData {
        bytes callTo; // The swap address
        bytes approveTo; // The swap address
        bytes sendingAssetId; // The swap start token address
        bytes receivingAssetId; // The swap final token address
        uint256 fromAmount; // The swap start token amount
        bytes callData; // The swap callData
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

    function swap(bytes32 transactionId, SwapData memory _swapData) internal {
        if (!LibAsset.isContract(_swapData.callTo)) revert InvalidContract();
        uint256 fromAmount = _swapData.fromAmount;
        if (fromAmount == 0) revert NoSwapFromZeroBalance();
        uint256 nativeValue = 0;
        address fromAssetId = _swapData.sendingAssetId;
        address toAssetId = _swapData.receivingAssetId;
        uint256 initialSendingAssetBalance = LibAsset.getOwnBalance(
            fromAssetId
        );
        uint256 initialReceivingAssetBalance = LibAsset.getOwnBalance(
            toAssetId
        );
        uint256 toDeposit = initialSendingAssetBalance < fromAmount
            ? fromAmount - initialSendingAssetBalance
            : 0;

        if (!LibAsset.isNativeAsset(fromAssetId)) {
            LibAsset.maxApproveERC20(
                IERC20(fromAssetId),
                _swapData.approveTo,
                fromAmount
            );
            if (toDeposit != 0) {
                LibAsset.transferFromERC20(
                    fromAssetId,
                    msg.sender,
                    address(this),
                    toDeposit
                );
            }
        } else {
            nativeValue = fromAmount;
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory res) = _swapData.callTo.call{
            value: nativeValue
        }(_swapData.callData);
        if (!success) {
            string memory reason = LibUtil.getRevertMsg(res);
            revert(reason);
        }

        emit AssetSwapped(
            transactionId,
            _swapData.callTo,
            _swapData.sendingAssetId,
            toAssetId,
            fromAmount,
            LibAsset.getOwnBalance(toAssetId) - initialReceivingAssetBalance,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
import {NullAddrIsNotAnERC20Token, NullAddrIsNotAValidSpender, NoTransferToNullAddress, InvalidAmount, NativeValueWithERC, NativeAssetTransferFailed} from "GenericErrors.sol";
import "SafeERC20.sol";
import "IERC20.sol";

/// @title LibAsset
/// @author Connext <[email protected]>
/// @notice This library contains helpers for dealing with onchain transfers
///         of assets, including accounting for the native asset `assetId`
///         conventions and any noncompliant ERC20 transfers
library LibAsset {
    uint256 private constant MAX_INT = type(uint256).max;

    address internal constant NULL_ADDRESS =
        0x0000000000000000000000000000000000000000; //address(0)

    /// @dev All native assets use the empty address for their asset id
    ///      by convention

    address internal constant NATIVE_ASSETID = NULL_ADDRESS; //address(0)

    /// @notice Gets the balance of the inheriting contract for the given asset
    /// @param assetId The asset identifier to get the balance of
    /// @return Balance held by contracts using this library
    function getOwnBalance(address assetId) internal view returns (uint256) {
        return
            assetId == NATIVE_ASSETID
                ? address(this).balance
                : IERC20(assetId).balanceOf(address(this));
    }

    /// @notice Transfers ether from the inheriting contract to a given
    ///         recipient
    /// @param recipient Address to send ether to
    /// @param amount Amount to send to given recipient
    function transferNativeAsset(address payable recipient, uint256 amount)
        private
    {
        if (recipient == NULL_ADDRESS) revert NoTransferToNullAddress();
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert NativeAssetTransferFailed();
    }

    /// @notice Gives MAX approval for another address to spend tokens
    /// @param assetId Token address to transfer
    /// @param spender Address to give spend approval to
    /// @param amount Amount to approve for spending
    function maxApproveERC20(
        IERC20 assetId,
        address spender,
        uint256 amount
    ) internal {
        if (address(assetId) == NATIVE_ASSETID) return;
        if (spender == NULL_ADDRESS) revert NullAddrIsNotAValidSpender();
        uint256 allowance = assetId.allowance(address(this), spender);
        if (allowance < amount)
            SafeERC20.safeApprove(IERC20(assetId), spender, MAX_INT);
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
        if (isNativeAsset(assetId)) revert NullAddrIsNotAnERC20Token();
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
        if (assetId == NATIVE_ASSETID) revert NullAddrIsNotAnERC20Token();
        if (to == NULL_ADDRESS) revert NoTransferToNullAddress();
        SafeERC20.safeTransferFrom(IERC20(assetId), from, to, amount);
    }

    /// @notice Deposits an asset into the contract and performs checks to avoid NativeValueWithERC
    /// @param tokenId Token to deposit
    /// @param amount Amount to deposit
    /// @param isNative Wether the token is native or ERC20
    function depositAsset(
        address tokenId,
        uint256 amount,
        bool isNative
    ) internal {
        if (amount == 0) revert InvalidAmount();
        if (isNative) {
            if (msg.value != amount) revert InvalidAmount();
        } else {
            //            if (msg.value != 0) revert NativeValueWithERC();
            uint256 _fromTokenBalance = LibAsset.getOwnBalance(tokenId);
            LibAsset.transferFromERC20(
                tokenId,
                msg.sender,
                address(this),
                amount
            );
            if (LibAsset.getOwnBalance(tokenId) - _fromTokenBalance != amount)
                revert InvalidAmount();
        }
    }

    /// @notice Overload for depositAsset(address tokenId, uint256 amount, bool isNative)
    /// @param tokenId Token to deposit
    /// @param amount Amount to deposit
    function depositAsset(address tokenId, uint256 amount) internal {
        return depositAsset(tokenId, amount, tokenId == NATIVE_ASSETID);
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
        (assetId == NATIVE_ASSETID)
            ? transferNativeAsset(recipient, amount)
            : transferERC20(assetId, recipient, amount);
    }

    /// @dev Checks whether the given address is a contract and contains code
    function isContract(address contractAddr) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(contractAddr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

error InvalidAmount(); // 0x2c5211c6
error TokenAddressIsZero(); // 0xdc2e5e8d
error CannotBridgeToSameNetwork(); // 0x4ac09ad3
error ZeroPostSwapBalance(); // 0xf74e8909
error InvalidBridgeConfigLength(); // 0x10502ef9
error NoSwapDataProvided(); // 0x0503c3ed
error NotSupportedSwapRouter(); // 0xe986f686
error NativeValueWithERC(); // 0x003f45b5
error ContractCallNotAllowed(); // 0x94539804
error NullAddrIsNotAValidSpender(); // 0x63ba9bff
error NullAddrIsNotAnERC20Token(); // 0xd1bebf0c
error NoTransferToNullAddress(); // 0x21f74345
error NativeAssetTransferFailed(); // 0x5a046737
error InvalidContract(); // 0x6eefed20
error InvalidConfig(); // 0x35be3ac8

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "LibBytes.sol";

library LibUtil {
    using LibBytes for bytes;

    function getRevertMsg(bytes memory _res)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) return "Transaction reverted silently";
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }

    function getSlice(
        bytes memory _data,
        uint256 _start,
        uint256 _end
    ) internal pure returns (bytes memory) {
        require(_start < _end && _end <= _data.length, "DataLength error!");
        bytes memory _out = bytes("");
        for (uint256 i = _start; i < _end; i++) {
            _out = bytes.concat(_out, _data[i]);
        }
        return _out;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
import "TypedMemView.sol";

library LibMessageCCTP {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;

    // Indices of each field in message
    uint8 private constant VERSION_INDEX = 0;
    uint8 private constant SOURCE_DOMAIN_INDEX = 4;
    uint8 private constant DESTINATION_DOMAIN_INDEX = 8;
    uint8 private constant NONCE_INDEX = 12;
    uint8 private constant SENDER_INDEX = 20;
    uint8 private constant RECIPIENT_INDEX = 52;
    uint8 private constant DESTINATION_CALLER_INDEX = 84;
    uint8 private constant MESSAGE_BODY_INDEX = 116;

    struct CCTPMessage {
        uint32 _msgVersion;
        uint32 _msgSourceDomain;
        uint32 _msgDestinationDomain;
        uint64 _msgNonce;
        bytes32 _msgSender;
        bytes32 _msgRecipient;
        bytes32 _msgDestinationCaller;
        bytes _msgRawBody;
    }

    /**
     * @notice Returns formatted (packed) message with provided fields
     * @param _msgVersion the version of the message format
     * @param _msgSourceDomain Domain of home chain
     * @param _msgDestinationDomain Domain of destination chain
     * @param _msgNonce Destination-specific nonce
     * @param _msgSender Address of sender on source chain as bytes32
     * @param _msgRecipient Address of recipient on destination chain as bytes32
     * @param _msgDestinationCaller Address of caller on destination chain as bytes32
     * @param _msgRawBody Raw bytes of message body
     * @return Formatted message
     **/
    function _formatMessage(
        uint32 _msgVersion,
        uint32 _msgSourceDomain,
        uint32 _msgDestinationDomain,
        uint64 _msgNonce,
        bytes32 _msgSender,
        bytes32 _msgRecipient,
        bytes32 _msgDestinationCaller,
        bytes memory _msgRawBody
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                _msgVersion,
                _msgSourceDomain,
                _msgDestinationDomain,
                _msgNonce,
                _msgSender,
                _msgRecipient,
                _msgDestinationCaller,
                _msgRawBody
            );
    }

    // @notice Returns _message's version field
    function _version(bytes29 _message) internal pure returns (uint32) {
        return uint32(_message.indexUint(VERSION_INDEX, 4));
    }

    // @notice Returns _message's sourceDomain field
    function _sourceDomain(bytes29 _message) internal pure returns (uint32) {
        return uint32(_message.indexUint(SOURCE_DOMAIN_INDEX, 4));
    }

    // @notice Returns _message's destinationDomain field
    function _destinationDomain(bytes29 _message)
        internal
        pure
        returns (uint32)
    {
        return uint32(_message.indexUint(DESTINATION_DOMAIN_INDEX, 4));
    }

    // @notice Returns _message's nonce field
    function _nonce(bytes29 _message) internal pure returns (uint64) {
        return uint64(_message.indexUint(NONCE_INDEX, 8));
    }

    // @notice Returns _message's sender field
    function _sender(bytes29 _message) internal pure returns (bytes32) {
        return _message.index(SENDER_INDEX, 32);
    }

    // @notice Returns _message's recipient field
    function _recipient(bytes29 _message) internal pure returns (bytes32) {
        return _message.index(RECIPIENT_INDEX, 32);
    }

    // @notice Returns _message's destinationCaller field
    function _destinationCaller(bytes29 _message)
        internal
        pure
        returns (bytes32)
    {
        return _message.index(DESTINATION_CALLER_INDEX, 32);
    }

    // @notice Returns _message's messageBody field
    function _messageBody(bytes29 _message) internal pure returns (bytes29) {
        return
            _message.slice(
                MESSAGE_BODY_INDEX,
                _message.len() - MESSAGE_BODY_INDEX,
                0
            );
    }

    /**
     * @notice converts address to bytes32 (alignment preserving cast.)
     * @param addr the address to convert to bytes32
     */
    function addressToBytes32(address addr) external pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    /**
     * @notice converts bytes32 to address (alignment preserving cast.)
     * @dev Warning: it is possible to have different input values _buf map to the same address.
     * For use cases where this is not acceptable, validate that the first 12 bytes of _buf are zero-padding.
     * @param _buf the bytes32 to convert to address
     */
    function bytes32ToAddress(bytes32 _buf) public pure returns (address) {
        return address(uint160(uint256(_buf)));
    }

    /**
     * @notice Reverts if message is malformed or incorrect length
     * @param _message The message as bytes29
     */
    function _validateMessageFormat(bytes29 _message) internal pure {
        require(_message.isValid(), "Malformed message");
        require(
            _message.len() >= MESSAGE_BODY_INDEX,
            "Invalid message: too short"
        );
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.12;

library TypedMemView {
    // Why does this exist?
    // the solidity `bytes memory` type has a few weaknesses.
    // 1. You can't index ranges effectively
    // 2. You can't slice without copying
    // 3. The underlying data may represent any type
    // 4. Solidity never deallocates memory, and memory costs grow
    //    superlinearly

    // By using a memory view instead of a `bytes memory` we get the following
    // advantages:
    // 1. Slices are done on the stack, by manipulating the pointer
    // 2. We can index arbitrary ranges and quickly convert them to stack types
    // 3. We can insert type info into the pointer, and typecheck at runtime

    // This makes `TypedMemView` a useful tool for efficient zero-copy
    // algorithms.

    // Why bytes29?
    // We want to avoid confusion between views, digests, and other common
    // types so we chose a large and uncommonly used odd number of bytes
    //
    // Note that while bytes are left-aligned in a word, integers and addresses
    // are right-aligned. This means when working in assembly we have to
    // account for the 3 unused bytes on the righthand side
    //
    // First 5 bytes are a type flag.
    // - ff_ffff_fffe is reserved for unknown type.
    // - ff_ffff_ffff is reserved for invalid types/errors.
    // next 12 are memory address
    // next 12 are len
    // bottom 3 bytes are empty

    // Assumptions:
    // - non-modification of memory.
    // - No Solidity updates
    // - - wrt free mem point
    // - - wrt bytes representation in memory
    // - - wrt memory addressing in general

    // Usage:
    // - create type constants
    // - use `assertType` for runtime type assertions
    // - - unfortunately we can't do this at compile time yet :(
    // - recommended: implement modifiers that perform type checking
    // - - e.g.
    // - - `uint40 constant MY_TYPE = 3;`
    // - - ` modifer onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
    // - instantiate a typed view from a bytearray using `ref`
    // - use `index` to inspect the contents of the view
    // - use `slice` to create smaller views into the same memory
    // - - `slice` can increase the offset
    // - - `slice can decrease the length`
    // - - must specify the output type of `slice`
    // - - `slice` will return a null view if you try to overrun
    // - - make sure to explicitly check for this with `notNull` or `assertType`
    // - use `equal` for typed comparisons.

    // The null view
    bytes29 public constant NULL =
        hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    // Mask a low uint96
    uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
    // Shift constants
    uint8 constant SHIFT_TO_LEN = 24;
    uint8 constant SHIFT_TO_LOC = 96 + 24;
    uint8 constant SHIFT_TO_TYPE = 96 + 96 + 24;
    // For nibble encoding
    bytes private constant NIBBLE_LOOKUP = "0123456789abcdef";

    /**
     * @notice Returns the encoded hex character that represents the lower 4 bits of the argument.
     * @param _byte The byte
     * @return _char The encoded hex character
     */
    function nibbleHex(uint8 _byte) internal pure returns (uint8 _char) {
        uint8 _nibble = _byte & 0x0f; // keep bottom 4, 0 top 4
        _char = uint8(NIBBLE_LOOKUP[_nibble]);
    }

    /**
     * @notice      Returns a uint16 containing the hex-encoded byte.
     * @param _b    The byte
     * @return      encoded - The hex-encoded byte
     */
    function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
        encoded |= nibbleHex(_b >> 4); // top 4 bits
        encoded <<= 8;
        encoded |= nibbleHex(_b); // lower 4 bits
    }

    /**
     * @notice      Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
     *              `second` contains the encoded lower 16 bytes.
     *
     * @param _b    The 32 bytes as uint256
     * @return      first - The top 16 bytes
     * @return      second - The bottom 16 bytes
     */
    function encodeHex(uint256 _b)
        internal
        pure
        returns (uint256 first, uint256 second)
    {
        for (uint8 i = 31; i > 15; ) {
            uint8 _byte = uint8(_b >> (i * 8));
            first |= byteHex(_byte);
            if (i != 16) {
                first <<= 16;
            }
            unchecked {
                i -= 1;
            }
        }

        // abusing underflow here =_=
        for (uint8 i = 15; i < 255; ) {
            uint8 _byte = uint8(_b >> (i * 8));
            second |= byteHex(_byte);
            if (i != 0) {
                second <<= 16;
            }
            unchecked {
                i -= 1;
            }
        }
    }

    /**
     * @notice          Changes the endianness of a uint256.
     * @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
     * @param _b        The unsigned integer to reverse
     * @return          v - The reversed value
     */
    function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
        v = _b;

        // swap bytes
        v =
            ((v >> 8) &
                0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
            ((v &
                0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) <<
                8);
        // swap 2-byte long pairs
        v =
            ((v >> 16) &
                0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
            ((v &
                0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) <<
                16);
        // swap 4-byte long pairs
        v =
            ((v >> 32) &
                0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
            ((v &
                0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) <<
                32);
        // swap 8-byte long pairs
        v =
            ((v >> 64) &
                0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
            ((v &
                0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) <<
                64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /**
     * @notice      Create a mask with the highest `_len` bits set.
     * @param _len  The length
     * @return      mask - The mask
     */
    function leftMask(uint8 _len) private pure returns (uint256 mask) {
        // ugly. redo without assembly?
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            mask := sar(
                sub(_len, 1),
                0x8000000000000000000000000000000000000000000000000000000000000000
            )
        }
    }

    /**
     * @notice      Return the null view.
     * @return      bytes29 - The null view
     */
    function nullView() internal pure returns (bytes29) {
        return NULL;
    }

    /**
     * @notice      Check if the view is null.
     * @return      bool - True if the view is null
     */
    function isNull(bytes29 memView) internal pure returns (bool) {
        return memView == NULL;
    }

    /**
     * @notice      Check if the view is not null.
     * @return      bool - True if the view is not null
     */
    function notNull(bytes29 memView) internal pure returns (bool) {
        return !isNull(memView);
    }

    /**
     * @notice          Check if the view is of a valid type and points to a valid location
     *                  in memory.
     * @dev             We perform this check by examining solidity's unallocated memory
     *                  pointer and ensuring that the view's upper bound is less than that.
     * @param memView   The view
     * @return          ret - True if the view is valid
     */
    function isValid(bytes29 memView) internal pure returns (bool ret) {
        if (typeOf(memView) == 0xffffffffff) return false;
        uint256 _end = end(memView);
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ret := iszero(gt(_end, mload(0x40)))
        }
    }

    /**
     * @notice          Require that a typed memory view be valid.
     * @dev             Returns the view for easy chaining.
     * @param memView   The view
     * @return          bytes29 - The validated view
     */
    function assertValid(bytes29 memView) internal pure returns (bytes29) {
        require(isValid(memView), "Validity assertion failed");
        return memView;
    }

    /**
     * @notice          Return true if the memview is of the expected type. Otherwise false.
     * @param memView   The view
     * @param _expected The expected type
     * @return          bool - True if the memview is of the expected type
     */
    function isType(bytes29 memView, uint40 _expected)
        internal
        pure
        returns (bool)
    {
        return typeOf(memView) == _expected;
    }

    /**
     * @notice          Require that a typed memory view has a specific type.
     * @dev             Returns the view for easy chaining.
     * @param memView   The view
     * @param _expected The expected type
     * @return          bytes29 - The view with validated type
     */
    function assertType(bytes29 memView, uint40 _expected)
        internal
        pure
        returns (bytes29)
    {
        if (!isType(memView, _expected)) {
            (, uint256 g) = encodeHex(uint256(typeOf(memView)));
            (, uint256 e) = encodeHex(uint256(_expected));
            string memory err = string(
                abi.encodePacked(
                    "Type assertion failed. Got 0x",
                    uint80(g),
                    ". Expected 0x",
                    uint80(e)
                )
            );
            revert(err);
        }
        return memView;
    }

    /**
     * @notice          Return an identical view with a different type.
     * @param memView   The view
     * @param _newType  The new type
     * @return          newView - The new view with the specified type
     */
    function castTo(bytes29 memView, uint40 _newType)
        internal
        pure
        returns (bytes29 newView)
    {
        // then | in the new type
        uint256 _typeShift = SHIFT_TO_TYPE;
        uint256 _typeBits = 40;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // shift off the top 5 bytes
            newView := or(newView, shr(_typeBits, shl(_typeBits, memView)))
            newView := or(newView, shl(_typeShift, _newType))
        }
    }

    /**
     * @notice          Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function unsafeBuildUnchecked(
        uint256 _type,
        uint256 _loc,
        uint256 _len
    ) private pure returns (bytes29 newView) {
        uint256 _uint96Bits = 96;
        uint256 _emptyBits = 24;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            newView := shl(_uint96Bits, or(newView, _type)) // insert type
            newView := shl(_uint96Bits, or(newView, _loc)) // insert loc
            newView := shl(_emptyBits, or(newView, _len)) // empty bottom 3 bytes
        }
    }

    /**
     * @notice          Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function build(
        uint256 _type,
        uint256 _loc,
        uint256 _len
    ) internal pure returns (bytes29 newView) {
        uint256 _end = _loc + _len;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            if gt(_end, mload(0x40)) {
                _end := 0
            }
        }
        if (_end == 0) {
            return NULL;
        }
        newView = unsafeBuildUnchecked(_type, _loc, _len);
    }

    /**
     * @notice          Instantiate a memory view from a byte array.
     * @dev             Note that due to Solidity memory representation, it is not possible to
     *                  implement a deref, as the `bytes` type stores its len in memory.
     * @param arr       The byte array
     * @param newType   The type
     * @return          bytes29 - The memory view
     */
    function ref(bytes memory arr, uint40 newType)
        internal
        pure
        returns (bytes29)
    {
        uint256 _len = arr.length;

        uint256 _loc;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            _loc := add(arr, 0x20) // our view is of the data, not the struct
        }

        return build(newType, _loc, _len);
    }

    /**
     * @notice          Return the associated type information.
     * @param memView   The memory view
     * @return          _type - The type associated with the view
     */
    function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
        uint256 _shift = SHIFT_TO_TYPE;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            _type := shr(_shift, memView) // shift out lower 27 bytes
        }
    }

    /**
     * @notice          Optimized type comparison. Checks that the 5-byte type flag is equal.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the 5-byte type flag is equal
     */
    function sameType(bytes29 left, bytes29 right)
        internal
        pure
        returns (bool)
    {
        return (left ^ right) >> SHIFT_TO_TYPE == 0;
    }

    /**
     * @notice          Return the memory address of the underlying bytes.
     * @param memView   The view
     * @return          _loc - The memory address
     */
    function loc(bytes29 memView) internal pure returns (uint96 _loc) {
        uint256 _mask = LOW_12_MASK; // assembly can't use globals
        uint256 _shift = SHIFT_TO_LOC;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            _loc := and(shr(_shift, memView), _mask)
        }
    }

    /**
     * @notice          The number of memory words this memory view occupies, rounded up.
     * @param memView   The view
     * @return          uint256 - The number of memory words
     */
    function words(bytes29 memView) internal pure returns (uint256) {
        return (uint256(len(memView)) + 31) / 32;
    }

    /**
     * @notice          The in-memory footprint of a fresh copy of the view.
     * @param memView   The view
     * @return          uint256 - The in-memory footprint of a fresh copy of the view.
     */
    function footprint(bytes29 memView) internal pure returns (uint256) {
        return words(memView) * 32;
    }

    /**
     * @notice          The number of bytes of the view.
     * @param memView   The view
     * @return          _len - The length of the view
     */
    function len(bytes29 memView) internal pure returns (uint96 _len) {
        uint256 _mask = LOW_12_MASK; // assembly can't use globals
        uint256 _emptyBits = 24;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            _len := and(shr(_emptyBits, memView), _mask)
        }
    }

    /**
     * @notice          Returns the endpoint of `memView`.
     * @param memView   The view
     * @return          uint256 - The endpoint of `memView`
     */
    function end(bytes29 memView) internal pure returns (uint256) {
        unchecked {
            return loc(memView) + len(memView);
        }
    }

    /**
     * @notice          Safe slicing without memory modification.
     * @param memView   The view
     * @param _index    The start index
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function slice(
        bytes29 memView,
        uint256 _index,
        uint256 _len,
        uint40 newType
    ) internal pure returns (bytes29) {
        uint256 _loc = loc(memView);

        // Ensure it doesn't overrun the view
        if (_loc + _index + _len > end(memView)) {
            return NULL;
        }

        _loc = _loc + _index;
        return build(newType, _loc, _len);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing the first `_len` bytes.
     * @param memView   The view
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function prefix(
        bytes29 memView,
        uint256 _len,
        uint40 newType
    ) internal pure returns (bytes29) {
        return slice(memView, 0, _len, newType);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing the last `_len` byte.
     * @param memView   The view
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function postfix(
        bytes29 memView,
        uint256 _len,
        uint40 newType
    ) internal pure returns (bytes29) {
        return slice(memView, uint256(len(memView)) - _len, _len, newType);
    }

    /**
     * @notice          Construct an error message for an indexing overrun.
     * @param _loc      The memory address
     * @param _len      The length
     * @param _index    The index
     * @param _slice    The slice where the overrun occurred
     * @return          err - The err
     */
    function indexErrOverrun(
        uint256 _loc,
        uint256 _len,
        uint256 _index,
        uint256 _slice
    ) internal pure returns (string memory err) {
        (, uint256 a) = encodeHex(_loc);
        (, uint256 b) = encodeHex(_len);
        (, uint256 c) = encodeHex(_index);
        (, uint256 d) = encodeHex(_slice);
        err = string(
            abi.encodePacked(
                "TypedMemView/index - Overran the view. Slice is at 0x",
                uint48(a),
                " with length 0x",
                uint48(b),
                ". Attempted to index at offset 0x",
                uint48(c),
                " with length 0x",
                uint48(d),
                "."
            )
        );
    }

    /**
     * @notice          Load up to 32 bytes from the view onto the stack.
     * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
     *                  This can be immediately cast to a smaller fixed-length byte array.
     *                  To automatically cast to an integer, use `indexUint`.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes
     * @return          result - The 32 byte result
     */
    function index(
        bytes29 memView,
        uint256 _index,
        uint8 _bytes
    ) internal pure returns (bytes32 result) {
        if (_bytes == 0) return bytes32(0);
        if (_index + _bytes > len(memView)) {
            revert(
                indexErrOverrun(
                    loc(memView),
                    len(memView),
                    _index,
                    uint256(_bytes)
                )
            );
        }
        require(
            _bytes <= 32,
            "TypedMemView/index - Attempted to index more than 32 bytes"
        );

        uint8 bitLength;
        unchecked {
            bitLength = _bytes * 8;
        }
        uint256 _loc = loc(memView);
        uint256 _mask = leftMask(bitLength);
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            result := and(mload(add(_loc, _index)), _mask)
        }
    }

    /**
     * @notice          Parse an unsigned integer from the view at `_index`.
     * @dev             Requires that the view have >= `_bytes` bytes following that index.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes
     * @return          result - The unsigned integer
     */
    function indexUint(
        bytes29 memView,
        uint256 _index,
        uint8 _bytes
    ) internal pure returns (uint256 result) {
        return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
    }

    /**
     * @notice          Parse an unsigned integer from LE bytes.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes
     * @return          result - The unsigned integer
     */
    function indexLEUint(
        bytes29 memView,
        uint256 _index,
        uint8 _bytes
    ) internal pure returns (uint256 result) {
        return reverseUint256(uint256(index(memView, _index, _bytes)));
    }

    /**
     * @notice          Parse an address from the view at `_index`. Requires that the view have >= 20 bytes
     *                  following that index.
     * @param memView   The view
     * @param _index    The index
     * @return          address - The address
     */
    function indexAddress(bytes29 memView, uint256 _index)
        internal
        pure
        returns (address)
    {
        return address(uint160(indexUint(memView, _index, 20)));
    }

    /**
     * @notice          Return the keccak256 hash of the underlying memory
     * @param memView   The view
     * @return          digest - The keccak256 hash of the underlying memory
     */
    function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            digest := keccak256(_loc, _len)
        }
    }

    /**
     * @notice          Return the sha2 digest of the underlying memory.
     * @dev             We explicitly deallocate memory afterwards.
     * @param memView   The view
     * @return          digest - The sha2 hash of the underlying memory
     */
    function sha2(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);

        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            let ptr := mload(0x40)
            res := staticcall(gas(), 2, _loc, _len, ptr, 0x20) // sha2 #1
            digest := mload(ptr)
        }
        require(res, "sha2 OOG");
    }

    /**
     * @notice          Implements bitcoin's hash160 (rmd160(sha2()))
     * @param memView   The pre-image
     * @return          digest - the Digest
     */
    function hash160(bytes29 memView) internal view returns (bytes20 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            let ptr := mload(0x40)
            res := staticcall(gas(), 2, _loc, _len, ptr, 0x20) // sha2
            res := and(res, staticcall(gas(), 3, ptr, 0x20, ptr, 0x20)) // rmd160
            digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
        }
        require(res, "hash160 OOG");
    }

    /**
     * @notice          Implements bitcoin's hash256 (double sha2)
     * @param memView   A view of the preimage
     * @return          digest - the Digest
     */
    function hash256(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            let ptr := mload(0x40)
            res := staticcall(gas(), 2, _loc, _len, ptr, 0x20) // sha2 #1
            res := and(res, staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
            digest := mload(ptr)
        }
        require(res, "hash256 OOG");
    }

    /**
     * @notice          Return true if the underlying memory is equal. Else false.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the underlying memory is equal
     */
    function untypedEqual(bytes29 left, bytes29 right)
        internal
        pure
        returns (bool)
    {
        return
            (loc(left) == loc(right) && len(left) == len(right)) ||
            keccak(left) == keccak(right);
    }

    /**
     * @notice          Return false if the underlying memory is equal. Else true.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - False if the underlying memory is equal
     */
    function untypedNotEqual(bytes29 left, bytes29 right)
        internal
        pure
        returns (bool)
    {
        return !untypedEqual(left, right);
    }

    /**
     * @notice          Compares type equality.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the types are the same
     */
    function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
        return
            left == right ||
            (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
    }

    /**
     * @notice          Compares type inequality.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the types are not the same
     */
    function notEqual(bytes29 left, bytes29 right)
        internal
        pure
        returns (bool)
    {
        return !equal(left, right);
    }

    /**
     * @notice          Copy the view to a location, return an unsafe memory reference
     * @dev             Super Dangerous direct memory access.
     *
     *                  This reference can be overwritten if anything else modifies memory (!!!).
     *                  As such it MUST be consumed IMMEDIATELY.
     *                  This function is private to prevent unsafe usage by callers.
     * @param memView   The view
     * @param _newLoc   The new location
     * @return          written - the unsafe memory reference
     */
    function unsafeCopyTo(bytes29 memView, uint256 _newLoc)
        private
        view
        returns (bytes29 written)
    {
        require(notNull(memView), "TypedMemView/copyTo - Null pointer deref");
        require(
            isValid(memView),
            "TypedMemView/copyTo - Invalid pointer deref"
        );
        uint256 _len = len(memView);
        uint256 _oldLoc = loc(memView);

        uint256 ptr;
        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40)
            // revert if we're writing in occupied memory
            if gt(ptr, _newLoc) {
                revert(0x60, 0x20)
            } // empty revert message

            // use the identity precompile to copy
            res := staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len)
        }
        require(res, "identity OOG");
        written = unsafeBuildUnchecked(typeOf(memView), _newLoc, _len);
    }

    /**
     * @notice          Copies the referenced memory to a new loc in memory, returning a `bytes` pointing to
     *                  the new memory
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param memView   The view
     * @return          ret - The view pointing to the new memory
     */
    function clone(bytes29 memView) internal view returns (bytes memory ret) {
        uint256 ptr;
        uint256 _len = len(memView);
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
            ret := ptr
        }
        unchecked {
            unsafeCopyTo(memView, ptr + 0x20);
        }
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
            mstore(ptr, _len) // write len of new array (in bytes)
        }
    }

    /**
     * @notice          Join the views in memory, return an unsafe reference to the memory.
     * @dev             Super Dangerous direct memory access.
     *
     *                  This reference can be overwritten if anything else modifies memory (!!!).
     *                  As such it MUST be consumed IMMEDIATELY.
     *                  This function is private to prevent unsafe usage by callers.
     * @param memViews  The views
     * @param _location The location in memory to which to copy & concatenate
     * @return          unsafeView - The conjoined view pointing to the new memory
     */
    function unsafeJoin(bytes29[] memory memViews, uint256 _location)
        private
        view
        returns (bytes29 unsafeView)
    {
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            let ptr := mload(0x40)
            // revert if we're writing in occupied memory
            if gt(ptr, _location) {
                revert(0x60, 0x20)
            } // empty revert message
        }

        uint256 _offset = 0;
        for (uint256 i = 0; i < memViews.length; i++) {
            bytes29 memView = memViews[i];
            unchecked {
                unsafeCopyTo(memView, _location + _offset);
                _offset += len(memView);
            }
        }
        unsafeView = unsafeBuildUnchecked(0, _location, _offset);
    }

    /**
     * @notice          Produce the keccak256 digest of the concatenated contents of multiple views.
     * @param memViews  The views
     * @return          bytes32 - The keccak256 digest
     */
    function joinKeccak(bytes29[] memory memViews)
        internal
        view
        returns (bytes32)
    {
        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return keccak(unsafeJoin(memViews, ptr));
    }

    /**
     * @notice          Produce the sha256 digest of the concatenated contents of multiple views.
     * @param memViews  The views
     * @return          bytes32 - The sha256 digest
     */
    function joinSha2(bytes29[] memory memViews)
        internal
        view
        returns (bytes32)
    {
        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return sha2(unsafeJoin(memViews, ptr));
    }

    /**
     * @notice          copies all views, joins them into a new bytearray.
     * @param memViews  The views
     * @return          ret - The new byte array
     */
    function join(bytes29[] memory memViews)
        internal
        view
        returns (bytes memory ret)
    {
        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }

        bytes29 _newView;
        unchecked {
            _newView = unsafeJoin(memViews, ptr + 0x20);
        }
        uint256 _written = len(_newView);
        uint256 _footprint = footprint(_newView);

        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // store the legnth
            mstore(ptr, _written)
            // new pointer is old + 0x20 + the footprint of the body
            mstore(0x40, add(add(ptr, _footprint), 0x20))
            ret := ptr
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IWETH} from "IWETH.sol";
import {ISo} from "ISo.sol";
import {ICorrectSwap} from "ICorrectSwap.sol";
import {LibSwap} from "LibSwap.sol";
import {LibAsset} from "LibAsset.sol";
import {LibUtil} from "LibUtil.sol";
import {LibStorage} from "LibStorage.sol";
import {LibAsset} from "LibAsset.sol";
import {InvalidAmount, ContractCallNotAllowed, NoSwapDataProvided, NotSupportedSwapRouter} from "GenericErrors.sol";

/// @title Swapper
/// @notice Abstract contract to provide swap functionality
contract Swapper is ISo {
    /// Storage ///

    LibStorage internal appStorage;

    /// Modifiers ///

    /// @dev Sends any leftover balances back to the user
    modifier noLeftovers(LibSwap.SwapData[] calldata swapData) {
        uint256 nSwaps = swapData.length;
        if (nSwaps != 1) {
            uint256[] memory initialBalances = _fetchBalances(swapData);
            address finalAsset = swapData[nSwaps - 1].receivingAssetId;
            uint256 curBalance = 0;

            _;

            for (uint256 i = 0; i < nSwaps - 1; i++) {
                address curAsset = swapData[i].receivingAssetId;
                if (curAsset == finalAsset) continue; // Handle multi-to-one swaps
                curBalance =
                    LibAsset.getOwnBalance(curAsset) -
                    initialBalances[i];
                if (curBalance > 0)
                    LibAsset.transferAsset(
                        curAsset,
                        payable(msg.sender),
                        curBalance
                    );
            }
        } else _;
    }

    /// External Methods ///

    /// @dev Validates input before executing swaps
    /// @param soData So tracking data
    /// @param swapData Array of data used to execute swaps
    function executeAndCheckSwaps(
        SoData memory soData,
        LibSwap.SwapData[] calldata swapData
    ) external returns (uint256) {
        require(msg.sender == address(this), "NotDiamond");
        uint256 nSwaps = swapData.length;
        if (nSwaps == 0) revert NoSwapDataProvided();
        address finalTokenId = swapData[swapData.length - 1].receivingAssetId;
        uint256 swapBalance = LibAsset.getOwnBalance(finalTokenId);
        _executeSwaps(soData, swapData);
        swapBalance = LibAsset.getOwnBalance(finalTokenId) - swapBalance;
        if (swapBalance == 0) revert InvalidAmount();
        return swapBalance;
    }

    /// Internal Methods ///

    /// @dev Convert eth to wrapped eth and Transfer.
    function transferWrappedAsset(
        address currentAssetId,
        address expectAssetId,
        uint256 amount
    ) internal {
        if (currentAssetId == expectAssetId) {
            require(
                LibAsset.getOwnBalance(currentAssetId) >= amount,
                "NotEnough"
            );
            return;
        }

        if (LibAsset.isNativeAsset(currentAssetId)) {
            // eth -> weth
            try IWETH(expectAssetId).deposit{value: amount}() {} catch {
                revert("DepositErr");
            }
        } else {
            // weth -> eth -> weth
            if (currentAssetId != expectAssetId) {
                try IWETH(currentAssetId).withdraw(amount) {} catch {
                    revert("DepositWithdrawErr");
                }
                try IWETH(expectAssetId).deposit{value: amount}() {} catch {
                    revert("WithdrawDepositErr");
                }
            }
        }
    }

    /// @dev Convert wrapped eth to eth and Transfer.
    function transferUnwrappedAsset(
        address currentAssetId,
        address expectAssetId,
        uint256 amount,
        address receiver
    ) internal {
        if (LibAsset.isNativeAsset(expectAssetId)) {
            if (currentAssetId != expectAssetId) {
                try IWETH(currentAssetId).withdraw(amount) {} catch {
                    revert("WithdrawErr");
                }
            }
        } else {
            require(currentAssetId == expectAssetId, "AssetIdErr");
        }
        if (receiver != address(this)) {
            require(
                LibAsset.getOwnBalance(expectAssetId) >= amount,
                "NotEnough"
            );
            LibAsset.transferAsset(expectAssetId, payable(receiver), amount);
        }
    }

    /// Private Methods ///

    /// @dev Executes swaps and checks that DEXs used are in the allowList
    /// @param soData So tracking data
    /// @param swapData Array of data used to execute swaps
    function _executeSwaps(
        SoData memory soData,
        LibSwap.SwapData[] calldata swapData
    ) private {
        LibSwap.SwapData memory currentSwapData = swapData[0];
        for (uint256 i = 0; i < swapData.length; i++) {
            address receivedToken = currentSwapData.receivingAssetId;
            uint256 swapBalance = LibAsset.getOwnBalance(receivedToken);

            if (
                !(appStorage.dexAllowlist[currentSwapData.approveTo] &&
                    appStorage.dexAllowlist[currentSwapData.callTo] &&
                    appStorage.dexFuncSignatureAllowList[
                        bytes32(
                            LibUtil.getSlice(currentSwapData.callData, 0, 4)
                        )
                    ])
            ) revert ContractCallNotAllowed();

            LibSwap.swap(soData.transactionId, currentSwapData);

            swapBalance = LibAsset.getOwnBalance(receivedToken) - swapBalance;

            if (i + 1 < swapData.length) {
                currentSwapData = swapData[i + 1];
                address correctSwap = appStorage.correctSwapRouterSelectors;
                if (correctSwap == address(0)) revert NotSupportedSwapRouter();
                currentSwapData.fromAmount = swapBalance;
                currentSwapData.callData = ICorrectSwap(correctSwap)
                    .correctSwap(
                        currentSwapData.callData,
                        currentSwapData.fromAmount
                    );
            }
        }
    }

    /// @dev Fetches balances of tokens to be swapped before swapping.
    /// @param swapData Array of data used to execute swaps
    /// @return uint256[] Array of token balances.
    function _fetchBalances(LibSwap.SwapData[] calldata swapData)
        private
        view
        returns (uint256[] memory)
    {
        uint256 length = swapData.length;
        uint256[] memory balances = new uint256[](length);
        for (uint256 i = 0; i < length; i++)
            balances[i] = LibAsset.getOwnBalance(swapData[i].receivingAssetId);
        return balances;
    }
}

pragma solidity 0.8.13;

import "IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface ICorrectSwap {
    function correctSwap(bytes calldata, uint256)
        external
        pure
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct LibStorage {
    mapping(address => bool) dexAllowlist;
    mapping(bytes32 => bool) dexFuncSignatureAllowList;
    address[] dexs;
    // maps gateway facet addresses to sofee address
    mapping(address => address) gatewaySoFeeSelectors;
    // Storage correct swap address
    address correctSwapRouterSelectors;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title Reentrancy Guard
/// @author LI.FI (https://li.fi)
/// @notice Abstract contract to provide protection against reentrancy
abstract contract ReentrancyGuard {
    /// Storage ///

    bytes32 private constant NAMESPACE =
        hex"a65bb2f450488ab0858c00edc14abc5297769bf42adb48cfb77752890e8b697b";

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface ILibSoFee {
    function getFees(uint256 _amount) external view returns (uint256 s);

    function getRestoredAmount(uint256 _amount)
        external
        view
        returns (uint256 r);

    function getTransferForGas() external view returns (uint256);

    function getVersion() external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITokenMessenger {
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 _nonce);

    function depositForBurnWithCaller(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller
    ) external returns (uint64 nonce);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IReceiver {
    /**
     * @notice Receives an incoming message, validating the header and passing
     * the body to application-specific handler.
     * @param message The message raw bytes
     * @param signature The message signature
     * @return success bool, true if successful
     */
    function receiveMessage(bytes calldata message, bytes calldata signature)
        external
        returns (bool success);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface ILibPrice {
    function getPriceRatio(uint16 _chainId)
        external
        view
        returns (uint256, bool);

    function updatePriceRatio(uint16 _chainId) external returns (uint256);

    function RAY() external view returns (uint256);
}

/*
 * Copyright (c) 2022, Circle Internet Financial Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.0;

/**
 * @title IMessageHandler
 * @notice Handles messages on destination domain forwarded from
 * an IReceiver
 */
interface IMessageHandler {
    /**
     * @notice handles an incoming message from a Receiver
     * @param sourceDomain the source domain of the message
     * @param sender the sender of the message
     * @param messageBody The message raw bytes
     * @return success bool, true if successful
     */
    function handleReceiveMessage(
        uint32 sourceDomain,
        bytes32 sender,
        bytes calldata messageBody
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMessageTransmitter {
    event MessageSent(bytes message);

    /**
     * @notice Sends an outgoing message from the source domain.
     * @dev Increment nonce, format the message, and emit `MessageSent` event with message information.
     * @param destinationDomain Domain of destination chain
     * @param recipient Address of message recipient on destination domain as bytes32
     * @param messageBody Raw bytes content of message
     * @return nonce reserved by message
     */
    function sendMessage(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes calldata messageBody
    ) external returns (uint64);

    function sendMessageWithCaller(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes32 destinationCaller,
        bytes calldata messageBody
    ) external returns (uint64);
}