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

import { PausableInternal } from '@solidstate/contracts/security/pausable/PausableInternal.sol';
import { ReentrancyGuard } from '@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol';
import { OnlyDelegateCall } from '../../../access/OnlyDelegateCall.sol';
import { OFTWrapperStatus } from '../OFTWrapperStatus.sol';
import { OFTWrapperStorage } from '../OFTWrapperStorage.sol';
import '../../../helpers/TransferHelper.sol' as TransferHelper;

/**
 * @title OFTWrapperLZV2Facet
 * @notice The OFTWrapperDiamond facet for LayerZero V2 OFTs
 */
contract OFTWrapperLZV2Facet is
    OnlyDelegateCall,
    PausableInternal,
    ReentrancyGuard,
    OFTWrapperStatus
{
    /**
     * @notice OFT "send" parameter structure (LayerZero V2 OFT)
     * @param sendParam The parameters for the "send" operation
     * @param fee The fee information supplied by the caller
     * @param refundAddress The address to receive any excess funds from fees etc. on the source chain
     */
    struct SendParams {
        ILZV2OFTSend.SendParam sendParam;
        ILZV2OFTSend.MessagingFee fee;
        address refundAddress;
    }

    /**
     * @notice OFT "quoteSend" parameter structure (LayerZero V2 OFT)
     * @param sendParam The parameters for the "send" operation
     * @param payInLzToken Flag indicating whether the caller is paying in the LZ token
     */
    struct QuoteSendParams {
        ILZV2OFTSend.SendParam sendParam;
        bool payInLzToken;
    }

    /**
     * @notice OFT "enforcedOptions" parameter structure (LayerZero V2 OFT)
     * @param eid The destination chain endpoint identifier
     * @param msgType The cross-chain message type
     */
    struct EnforcedOptionsParams {
        uint32 eid;
        uint16 msgType;
    }

    /**
     * @notice Sends tokens to the destination chain (LayerZero V2 OFT)
     * @param _oft The address of the OFT
     * @param _params The "send" parameter structure
     * @param _reserve The reserve value
     * @return The LayerZero messaging receipt from the "send" operation
     * @return The OFT receipt information
     */
    function lzv2oftSend(
        ILZV2OFTSend _oft,
        SendParams calldata _params,
        uint256 _reserve
    )
        external
        payable
        onlyDelegateCall
        whenNotPaused
        nonReentrant
        returns (ILZV2OFTSend.MessagingReceipt memory, ILZV2OFTSend.OFTReceipt memory)
    {
        address token = _oft.token();
        uint256 amount = _params.sendParam.amountLD;

        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);

        bool approvalRequired = _oft.approvalRequired();

        if (approvalRequired) {
            TransferHelper.safeApprove(token, address(_oft), amount);
        }

        (
            ILZV2OFTSend.MessagingReceipt memory messagingReceipt,
            ILZV2OFTSend.OFTReceipt memory oftReceipt
        ) = _oft.send{ value: msg.value - _reserve }(
                _params.sendParam,
                _params.fee,
                _params.refundAddress
            );

        if (approvalRequired) {
            TransferHelper.safeApprove(token, address(_oft), 0);
        }

        TransferHelper.safeTransferNative(OFTWrapperStorage.layout().collector, _reserve);

        emit OftSent();

        return (messagingReceipt, oftReceipt);
    }

    /**
     * @notice Provides a quote for the "lzv2oftSend" operation
     * @param _oft The address of the OFT
     * @param _params The "quoteSend" parameter structure
     * @param _reserve The reserve value
     * @return messagingFee The calculated messaging fee: "lzv2oftSend" operation
     * @return oftMessagingFee The calculated LayerZero messaging fee: "send" operation
     */
    function lzv2oftQuoteSend(
        ILZV2OFTSend _oft,
        QuoteSendParams calldata _params,
        uint256 _reserve
    )
        external
        view
        onlyDelegateCall
        returns (
            ILZV2OFTSend.MessagingFee memory messagingFee,
            ILZV2OFTSend.MessagingFee memory oftMessagingFee
        )
    {
        oftMessagingFee = _oft.quoteSend(_params.sendParam, _params.payInLzToken);

        messagingFee = ILZV2OFTSend.MessagingFee({
            nativeFee: oftMessagingFee.nativeFee + _reserve,
            lzTokenFee: oftMessagingFee.lzTokenFee
        });
    }

    /**
     * @notice Gets the enforced options for specific endpoint and message type combinations
     * @param _oft The address of the OFT
     * @param _params The "enforcedOptions" parameter structure
     */
    function lzv2oftEnforcedOptions(
        ILZV2OFTSend _oft,
        EnforcedOptionsParams calldata _params
    ) external view onlyDelegateCall returns (bytes memory) {
        return _oft.enforcedOptions(_params.eid, _params.msgType);
    }
}

interface ILZV2OFTSend {
    struct SendParam {
        uint32 dstEid; // Destination endpoint ID
        bytes32 to; // Recipient address
        uint256 amountLD; // Amount to send in local decimals
        uint256 minAmountLD; // Minimum amount to send in local decimals
        bytes extraOptions; // Additional options supplied by the caller to be used in the LayerZero message
        bytes composeMsg; // The composed message for the "send" operation
        bytes oftCmd; // The OFT command to be executed, unused in default OFT implementations
    }

    struct MessagingFee {
        uint256 nativeFee;
        uint256 lzTokenFee;
    }

    struct MessagingReceipt {
        bytes32 guid;
        uint64 nonce;
        MessagingFee fee;
    }

    struct OFTReceipt {
        uint256 amountSentLD; // Amount of tokens ACTUALLY debited from the sender in local decimals
        uint256 amountReceivedLD; // Amount of tokens to be received on the remote side
    }

    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory, OFTReceipt memory);

    function quoteSend(
        SendParam calldata _sendParam,
        bool _payInLzToken
    ) external view returns (MessagingFee memory);

    function enforcedOptions(uint32 _eid, uint16 _msgType) external view returns (bytes memory);

    function token() external view returns (address);

    function approvalRequired() external view returns (bool);
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