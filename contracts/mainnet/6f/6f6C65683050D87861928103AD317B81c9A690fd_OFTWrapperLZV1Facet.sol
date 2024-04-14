// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint _configType,
        bytes calldata _config
    ) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTCore is IERC165 {
    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _amount - amount of the tokens to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(uint16 _dstChainId, bytes calldata _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_from` the owner of token
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address _from, uint16 _dstChainId, bytes calldata _toAddress, uint _amount, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint);

    /**
     * @dev returns the address of the ERC20 token
     */
    function token() external view returns (address);

    /**
     * @dev Emitted when `_amount` tokens are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce
     */
    event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes _toAddress, uint _amount);

    /**
     * @dev Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
     * `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 indexed _srcChainId, address indexed _to, uint _amount);

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "../interfaces/ICommonOFT.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTWithFee is ICommonOFT {

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_from` the owner of token
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_minAmount` the minimum amount of tokens to receive on dstChain
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, uint _minAmount, LzCallParams calldata _callParams) external payable;

    function sendAndCall(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, uint _minAmount, bytes calldata _payload, uint64 _dstGasForCall, LzCallParams calldata _callParams) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface ICommonOFT is IERC165 {

    struct LzCallParams {
        address payable refundAddress;
        address zroPaymentAddress;
        bytes adapterParams;
    }

    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _amount - amount of the tokens to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    function estimateSendAndCallFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint);

    /**
     * @dev returns the address of the ERC20 token
     */
    function token() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ICommonOFT.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTV2 is ICommonOFT {

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_from` the owner of token
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, LzCallParams calldata _callParams) external payable;

    function sendAndCall(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, LzCallParams calldata _callParams) external payable;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IPausableInternal {
    error Pausable__Paused();
    error Pausable__NotPaused();

    event Paused(address account);
    event Unpaused(address account);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IPausableInternal } from './IPausableInternal.sol';
import { PausableStorage } from './PausableStorage.sol';

/**
 * @title Internal functions for Pausable security control module.
 */
abstract contract PausableInternal is IPausableInternal {
    modifier whenNotPaused() {
        if (_paused()) revert Pausable__Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused()) revert Pausable__NotPaused();
        _;
    }

    /**
     * @notice query whether contract is paused
     * @return status whether contract is paused
     */
    function _paused() internal view virtual returns (bool status) {
        status = PausableStorage.layout().paused;
    }

    /**
     * @notice Triggers paused state, when contract is unpaused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout().paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Triggers unpaused state, when contract is paused.
     */
    function _unpause() internal virtual whenPaused {
        delete PausableStorage.layout().paused;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PausableStorage {
    struct Layout {
        bool paused;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Pausable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IReentrancyGuard } from './IReentrancyGuard.sol';
import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard is IReentrancyGuard {
    uint256 internal constant REENTRANCY_STATUS_LOCKED = 2;
    uint256 internal constant REENTRANCY_STATUS_UNLOCKED = 1;

    modifier nonReentrant() virtual {
        if (_isReentrancyGuardLocked()) revert ReentrancyGuard__ReentrantCall();
        _lockReentrancyGuard();
        _;
        _unlockReentrancyGuard();
    }

    /**
     * @notice returns true if the reentrancy guard is locked, false otherwise
     */
    function _isReentrancyGuardLocked() internal view virtual returns (bool) {
        return
            ReentrancyGuardStorage.layout().status == REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice lock functions that use the nonReentrant modifier
     */
    function _lockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice unlock functions that use the nonReentrant modifier
     */
    function _unlockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_UNLOCKED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title OnlyDelegateCall
 * @notice delegatecall invocation guard
 */
abstract contract OnlyDelegateCall {
    address private immutable self = address(this);

    /**
     * @dev Reverts if the current function context is not inside of a delegatecall
     */
    modifier onlyDelegateCall() {
        require(address(this) != self, 'onlyDelegateCall');

        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import './TransferHelper.sol' as TransferHelper;

/**
 * @notice Refunds the extra balance of the native token
 * @dev Reverts on subtraction if the actual balance is less than expected
 * @param _self The address of the executing contract
 * @param _expectedBalance The expected native token balance value
 * @param _to The refund receiver's address
 */
function refundExtraBalance(address _self, uint256 _expectedBalance, address payable _to) {
    uint256 extraBalance = _self.balance - _expectedBalance;

    if (extraBalance > 0) {
        TransferHelper.safeTransferNative(_to, extraBalance);
    }
}

/**
 * @notice Refunds the extra balance of the native token
 * @dev Reverts on subtraction if the actual balance is less than expected
 * @param _self The address of the executing contract
 * @param _expectedBalance The expected native token balance value
 * @param _to The refund receiver's address
 * @return extraBalance The extra balance of the native token
 */
function refundExtraBalanceWithResult(
    address _self,
    uint256 _expectedBalance,
    address payable _to
) returns (uint256 extraBalance) {
    extraBalance = _self.balance - _expectedBalance;

    if (extraBalance > 0) {
        TransferHelper.safeTransferNative(_to, extraBalance);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when an approval action fails
 */
error SafeApproveError();

/**
 * @notice Emitted when a transfer action fails
 */
error SafeTransferError();

/**
 * @notice Emitted when a transferFrom action fails
 */
error SafeTransferFromError();

/**
 * @notice Emitted when a transfer of the native token fails
 */
error SafeTransferNativeError();

/**
 * @notice Safely approve the token to the account
 * @param _token The token address
 * @param _to The token approval recipient address
 * @param _value The token approval amount
 */
function safeApprove(address _token, address _to, uint256 _value) {
    // 0x095ea7b3 is the selector for "approve(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x095ea7b3, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeApproveError();
    }
}

/**
 * @notice Safely transfer the token to the account
 * @param _token The token address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransfer(address _token, address _to, uint256 _value) {
    // 0xa9059cbb is the selector for "transfer(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0xa9059cbb, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferError();
    }
}

/**
 * @notice Safely transfer the token between the accounts
 * @param _token The token address
 * @param _from The token transfer source address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransferFrom(address _token, address _from, address _to, uint256 _value) {
    // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferFromError();
    }
}

/**
 * @notice Safely transfer the native token to the account
 * @param _to The native token transfer recipient address
 * @param _value The native token transfer amount
 */
function safeTransferNative(address _to, uint256 _value) {
    (bool success, ) = _to.call{ value: _value }(new bytes(0));

    if (!success) {
        revert SafeTransferNativeError();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ICommonOFT } from '@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/ICommonOFT.sol';
import { IOFTCore } from '@layerzerolabs/solidity-examples/contracts/token/oft/v1/interfaces/IOFTCore.sol';
import { IOFTV2 } from '@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/IOFTV2.sol';
import { IOFTWithFee } from '@layerzerolabs/solidity-examples/contracts/token/oft/v2/fee/IOFTWithFee.sol';
import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/lzApp/interfaces/ILayerZeroEndpoint.sol';
import { PausableInternal } from '@solidstate/contracts/security/pausable/PausableInternal.sol';
import { ReentrancyGuard } from '@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol';
import { OnlyDelegateCall } from '../../../access/OnlyDelegateCall.sol';
import { OFTWrapperStatus } from '../OFTWrapperStatus.sol';
import { OFTWrapperStorage } from '../OFTWrapperStorage.sol';
import '../../../helpers/RefundHelper.sol' as RefundHelper;
import '../../../helpers/TransferHelper.sol' as TransferHelper;

/**
 * @title OFTWrapperLZV1Facet
 * @notice The OFTWrapperDiamond facet for LayerZero V1 OFTs
 */
contract OFTWrapperLZV1Facet is
    OnlyDelegateCall,
    PausableInternal,
    ReentrancyGuard,
    OFTWrapperStatus
{
    /**
     * @notice OFT "sendFrom" parameter structure (LayerZero V1 - OFT v2)
     * @param from The owner of token
     * @param dstChainId The destination chain identifier
     * @param toAddress Can be any size depending on the `dstChainId`
     * @param amount The quantity of tokens in wei
     * @param callParams LayerZero call parameters
     */
    struct SendFromParams {
        address from;
        uint16 dstChainId;
        bytes32 toAddress;
        uint256 amount;
        ICommonOFT.LzCallParams callParams;
    }

    /**
     * @notice OFT "sendFrom" parameter structure (LayerZero V1 - OFTWithFee)
     * @param from The owner of token
     * @param dstChainId The destination chain identifier
     * @param toAddress Can be any size depending on the `dstChainId`
     * @param amount The quantity of tokens in wei
     * @param minAmount The minimum amount of tokens to receive on the destination chain
     * @param callParams LayerZero call parameters
     */
    struct SendFromWithMinAmountParams {
        address from;
        uint16 dstChainId;
        bytes32 toAddress;
        uint256 amount;
        uint256 minAmount;
        ICommonOFT.LzCallParams callParams;
    }

    /**
     * @notice OFT "sendFrom" parameter structure (LayerZero V1 - OFT v1)
     * @param from The owner of token
     * @param dstChainId The destination chain identifier
     * @param toAddress Can be any size depending on the `dstChainId`
     * @param amount The quantity of tokens in wei
     * @param refundAddress Refund address
     * @param zroPaymentAddress ZRO payment address
     * @param adapterParams LayerZero adapter parameters
     */
    struct SendFromV1Params {
        address from;
        uint16 dstChainId;
        bytes toAddress;
        uint256 amount;
        address payable refundAddress;
        address zroPaymentAddress;
        bytes adapterParams;
    }

    /**
     * @notice OFT "sendTokens" parameter structure (LayerZero V1 - OmnichainFungibleToken)
     * @param dstChainId Send tokens to this chainId
     * @param to Where to deliver the tokens on the destination chain
     * @param qty How many tokens to send
     * @param zroPaymentAddress ZRO payment address
     * @param adapterParam LayerZero adapter parameters
     */
    struct SendTokensParams {
        uint16 dstChainId;
        bytes to;
        uint256 qty;
        address zroPaymentAddress;
        bytes adapterParam;
    }

    /**
     * @notice OFT "estimateSendFee" parameter structure (LayerZero V1 - OFT v2 and OFTWithFee)
     * @param dstChainId The destination chain identifier
     * @param toAddress Can be any size depending on the `dstChainId`
     * @param amount The quantity of tokens in wei
     * @param useZro The ZRO token payment flag
     * @param adapterParams LayerZero adapter parameters
     */
    struct EstimateSendFeeParams {
        uint16 dstChainId;
        bytes32 toAddress;
        uint256 amount;
        bool useZro;
        bytes adapterParams;
    }

    /**
     * @notice OFT "estimateSendFee" parameter structure (LayerZero V1 - OFT v1)
     * @param dstChainId The destination chain identifier
     * @param toAddress Can be any size depending on the `dstChainId`
     * @param amount The quantity of tokens in wei
     * @param useZro The ZRO token payment flag
     * @param adapterParams LayerZero adapter parameters
     */
    struct EstimateSendFeeV1Params {
        uint16 dstChainId;
        bytes toAddress;
        uint256 amount;
        bool useZro;
        bytes adapterParams;
    }

    /**
     * @notice OFT "estimateSendTokensFee" parameter structure (LayerZero V1 - OmnichainFungibleToken)
     * @param dstChainId The destination chain identifier
     * @param useZro The ZRO token payment flag
     * @param txParameters LayerZero tx parameters
     */
    struct EstimateSendTokensFeeParams {
        uint16 dstChainId;
        bool useZro;
        bytes txParameters;
    }

    uint16 private constant PT_SEND = 0; // packet type

    /**
     * @notice Sends tokens to the destination chain (LayerZero V1 - OFT v2)
     * @param _oft The address of the OFT
     * @param _params The "sendFrom" parameters
     * @param _reserve The reserve value
     */
    function oftSendFrom(
        IOFTV2 _oft,
        SendFromParams calldata _params,
        uint256 _reserve
    ) external payable onlyDelegateCall whenNotPaused nonReentrant {
        address tokenAddress = _oft.token();

        address tokenHolder = _beforeSendFrom(
            address(_oft),
            tokenAddress,
            _params.from,
            _params.amount
        );

        _oft.sendFrom{ value: msg.value - _reserve }(
            tokenHolder,
            _params.dstChainId,
            _params.toAddress,
            _params.amount,
            _params.callParams
        );

        _afterSendFrom(address(_oft), tokenAddress, _reserve);
    }

    /**
     * @notice Sends tokens to the destination chain (LayerZero V1 - OFTWithFee)
     * @param _oft The address of the OFT
     * @param _params The "sendFrom" parameters
     * @param _reserve The reserve value
     */
    function oftSendFromWithMinAmount(
        IOFTWithFee _oft,
        SendFromWithMinAmountParams calldata _params,
        uint256 _reserve
    ) external payable onlyDelegateCall whenNotPaused nonReentrant {
        address tokenAddress = _oft.token();

        address tokenHolder = _beforeSendFrom(
            address(_oft),
            tokenAddress,
            _params.from,
            _params.amount
        );

        _oft.sendFrom{ value: msg.value - _reserve }(
            tokenHolder,
            _params.dstChainId,
            _params.toAddress,
            _params.amount,
            _params.minAmount,
            _params.callParams
        );

        _afterSendFrom(address(_oft), tokenAddress, _reserve);
    }

    /**
     * @notice Sends tokens to the destination chain (LayerZero V1 - OFT v1)
     * @param _oft The address of the OFT
     * @param _params The "sendFrom" parameters
     * @param _reserve The reserve value
     */
    function oftSendFromV1(
        IOFTCore _oft,
        SendFromV1Params calldata _params,
        uint256 _reserve
    ) external payable onlyDelegateCall whenNotPaused nonReentrant {
        address tokenAddress = _oft.token();

        address tokenHolder = _beforeSendFrom(
            address(_oft),
            tokenAddress,
            _params.from,
            _params.amount
        );

        _oft.sendFrom{ value: msg.value - _reserve }(
            tokenHolder,
            _params.dstChainId,
            _params.toAddress,
            _params.amount,
            _params.refundAddress,
            _params.zroPaymentAddress,
            _params.adapterParams
        );

        _afterSendFrom(address(_oft), tokenAddress, _reserve);
    }

    /**
     * @notice Sends tokens to the destination chain (LayerZero V1 - OmnichainFungibleToken)
     * @param _oft The address of the OFT
     * @param _params The "sendTokens" parameters
     * @param _reserve The reserve value
     */
    function oftSendTokens(
        IOmnichainFungibleToken _oft,
        SendTokensParams calldata _params,
        uint256 _reserve
    ) external payable onlyDelegateCall whenNotPaused nonReentrant {
        uint256 initialBalance = address(this).balance - msg.value;

        TransferHelper.safeTransferFrom(address(_oft), msg.sender, address(this), _params.qty);

        _oft.sendTokens{ value: msg.value - _reserve }(
            _params.dstChainId,
            _params.to,
            _params.qty,
            address(0),
            _params.adapterParam
        );

        TransferHelper.safeTransferNative(OFTWrapperStorage.layout().collector, _reserve);

        RefundHelper.refundExtraBalance(address(this), initialBalance, payable(msg.sender));

        emit OftSent();
    }

    /**
     * @notice Estimates the cross-chain transfer fees (LayerZero V1 - OFT v2 and OFTWithFee)
     * @param _oft The address of the OFT
     * @param _params The "estimateSendFee" parameters
     * @param _reserve The reserve value
     * @return nativeFee Native fee amount
     * @return zroFee ZRO fee amount
     */
    function oftEstimateSendFee(
        ICommonOFT _oft,
        EstimateSendFeeParams calldata _params,
        uint256 _reserve
    ) external view onlyDelegateCall returns (uint256 nativeFee, uint256 zroFee) {
        (uint256 oftNativeFee, uint256 oftZroFee) = _oft.estimateSendFee(
            _params.dstChainId,
            _params.toAddress,
            _params.amount,
            _params.useZro,
            _params.adapterParams
        );

        return (oftNativeFee + _reserve, oftZroFee);
    }

    /**
     * @notice Estimates the cross-chain transfer fees (LayerZero V1 - OFT v1)
     * @param _oft The address of the OFT
     * @param _params The "estimateSendFee" parameters
     * @param _reserve The reserve value
     * @return nativeFee Native fee amount
     * @return zroFee ZRO fee amount
     */
    function oftEstimateSendV1Fee(
        IOFTCore _oft,
        EstimateSendFeeV1Params calldata _params,
        uint256 _reserve
    ) external view onlyDelegateCall returns (uint256 nativeFee, uint256 zroFee) {
        (uint256 oftNativeFee, uint256 oftZroFee) = _oft.estimateSendFee(
            _params.dstChainId,
            _params.toAddress,
            _params.amount,
            _params.useZro,
            _params.adapterParams
        );

        return (oftNativeFee + _reserve, oftZroFee);
    }

    /**
     * @notice Estimates the cross-chain transfer fees (LayerZero V1 - OmnichainFungibleToken)
     * @param _oft The address of the OFT
     * @param _to Where to deliver the tokens on the destination chain
     * @param _qty How many tokens to send
     * @param _params The "estimateFees" parameters
     * @param _reserve The reserve value
     * @return nativeFee Native fee amount
     * @return zroFee ZRO fee amount
     */
    function oftEstimateSendTokensFee(
        IOmnichainFungibleToken _oft,
        bytes calldata _to,
        uint256 _qty,
        EstimateSendTokensFeeParams calldata _params,
        uint256 _reserve
    ) external view onlyDelegateCall returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = abi.encode(_to, _qty);

        (uint256 oftNativeFee, uint256 oftZroFee) = _oft.endpoint().estimateFees(
            _params.dstChainId,
            address(_oft),
            payload,
            _params.useZro,
            _params.txParameters
        );

        return (oftNativeFee + _reserve, oftZroFee);
    }

    /**
     * @notice Destination gas parameters lookup (LayerZero V1)
     * @param _oftAddress The address of the OFT
     * @param _targetLzChainId The destination chain ID (LayerZero-specific)
     * @return useCustomParameters Custom parameters flag
     * @return minTargetGas Minimum destination gas
     */
    function oftTargetGasParameters(
        address _oftAddress,
        uint16 _targetLzChainId
    ) external view onlyDelegateCall returns (bool useCustomParameters, uint256 minTargetGas) {
        try IOptionalChainConfig(_oftAddress).useCustomAdapterParams() returns (bool result) {
            useCustomParameters = result;
        } catch {
            useCustomParameters = true;
        }

        // The default value of "minTargetGas" is 0
        if (useCustomParameters) {
            minTargetGas = IChainConfig(_oftAddress).minDstGasLookup(_targetLzChainId, PT_SEND);
        }
    }

    function _beforeSendFrom(
        address _oftAddress,
        address _tokenAddress,
        address _paramsFrom,
        uint256 _paramsAmount
    ) private returns (address tokenHolder) {
        if (_paramsFrom != msg.sender) {
            revert SenderError();
        }

        if (_tokenAddress != _oftAddress) {
            TransferHelper.safeTransferFrom(
                _tokenAddress,
                _paramsFrom,
                address(this),
                _paramsAmount
            );

            tokenHolder = address(this);

            TransferHelper.safeApprove(_tokenAddress, _oftAddress, _paramsAmount);
        } else {
            tokenHolder = _paramsFrom;
        }
    }

    function _afterSendFrom(address _oftAddress, address _tokenAddress, uint256 _reserve) private {
        if (_tokenAddress != _oftAddress) {
            TransferHelper.safeApprove(_tokenAddress, _oftAddress, 0);
        }

        TransferHelper.safeTransferNative(OFTWrapperStorage.layout().collector, _reserve);

        emit OftSent();
    }
}

interface IOptionalChainConfig {
    function useCustomAdapterParams() external view returns (bool);
}

interface IChainConfig {
    function minDstGasLookup(uint16 _dstChainId, uint16 _type) external view returns (uint256);
}

interface IOmnichainFungibleToken {
    function sendTokens(
        uint16 _dstChainId, // send tokens to this chainId
        bytes calldata _to, // where to deliver the tokens on the destination chain
        uint256 _qty, // how many tokens to send
        address zroPaymentAddress, // ZRO payment address
        bytes calldata adapterParam // LayerZero adapter parameters
    ) external payable;

    function endpoint() external view returns (ILayerZeroEndpoint);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title OFTWrapperStatus
 * @notice OFTWrapperDiamond events and custom errors
 */
interface OFTWrapperStatus {
    /**
     * @notice Emitted when the OFT sending function is invoked
     */
    event OftSent();

    /**
     * @notice Emitted when the caller is not the token sender
     */
    error SenderError();
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title OFTWrapperStorage
 * @notice OFTWrapperDiamond storage
 */
library OFTWrapperStorage {
    /**
     * @notice OFTWrapperDiamond storage layout
     * @param collector The address of the collector
     */
    struct Layout {
        address collector;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('interport.oft.wrapper.OFTWrapperDiamond');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}