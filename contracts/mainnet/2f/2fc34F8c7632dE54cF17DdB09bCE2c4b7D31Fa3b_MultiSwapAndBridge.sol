// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./IStargatePool.sol";

interface IStargateFactory {
    function getPool(uint256 _srcPoolId) external returns (IStargatePool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IStargatePool {
    function token() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

/**
 * @title ERC2612 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 is IERC2612Internal {
    /**
     * @notice return the EIP-712 domain separator unique to contract and chain
     * @return domainSeparator domain separator
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator);

    /**
     * @notice get the current ERC2612 nonce for the given address
     * @return current nonce
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice approve spender to transfer tokens held by owner via signature
     * @dev this function may be vulnerable to approval replay attacks
     * @param owner holder of tokens and signer of permit
     * @param spender beneficiary of approval
     * @param amount quantity of tokens to approve
     * @param v secp256k1 'v' value
     * @param r secp256k1 'r' value
     * @param s secp256k1 's' value
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC2612Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../interfaces/IERC20.sol';
import { AddressUtils } from './AddressUtils.sol';

/**
 * @title Safe ERC20 interaction library
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library SafeERC20 {
    using AddressUtils for address;

    error SafeERC20__ApproveFromNonZeroToNonZero();
    error SafeERC20__DecreaseAllowanceBelowZero();
    error SafeERC20__OperationFailed();

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if ((value != 0) && (token.allowance(address(this), spender) != 0))
            revert SafeERC20__ApproveFromNonZeroToNonZero();

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            if (oldAllowance < value)
                revert SafeERC20__DecreaseAllowanceBelowZero();
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );

        if (returndata.length > 0) {
            if (!abi.decode(returndata, (bool)))
                revert SafeERC20__OperationFailed();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEIP712 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEIP712} from "./IEIP712.sol";

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer is IEIP712 {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISquidRouter {
    /// @notice Call type that enables to specific behaviours of the multicall.
    enum CallType {
        // Will simply run calldata
        Default,
        // Will update amount field in calldata with ERC20 token balance of the multicall contract.
        FullTokenBalance,
        // Will update amount field in calldata with native token balance of the multicall contract.
        FullNativeBalance,
        // Will run a safeTransferFrom to get full ERC20 token balance of the caller.
        CollectTokenBalance
    }

    /// @notice Calldata format expected by multicall.
    struct Call {
        // Call type, see CallType struct description.
        CallType callType;
        // Address that will be called.
        address target;
        // Native token amount that will be sent in call.
        uint256 value;
        // Calldata that will be send in call.
        bytes callData;
        // Extra data used by multicall depending on call type.
        // Default: unused (provide 0x)
        // FullTokenBalance: address of the ERC20 token to get balance of and zero indexed position
        // of the amount parameter to update in function call contained by calldata.
        // Expect format is: abi.encode(address token, uint256 amountParameterPosition)
        // Eg: for function swap(address tokenIn, uint amountIn, address tokenOut, uint amountOutMin,)
        // amountParameterPosition would be 1.
        // FullNativeBalance: unused (provide 0x)
        // CollectTokenBalance: address of the ERC20 token to collect.
        // Expect format is: abi.encode(address token)
        bytes payload;
    }

    function callBridgeCall(
        address token,
        uint256 amount,
        Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title   Call
 * @dev     Utils for making calls to other contracts that bubble up the revert reason
 */

library Call {
    function _delegate(address to, bytes memory data) internal {
        (bool success, bytes memory result) = to.delegatecall(data);

        if (!success) {
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }

    function _call(address to, bytes memory data) internal {
        (bool success, bytes memory result) = to.call(data);

        if (!success) {
            if (result.length < 68) revert('call failed');
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';
import { IERC2612 } from '@solidstate/contracts/token/ERC20/permit/IERC2612.sol';

/**
 * @title   TrustlessPermit
 * @dev     Signed Permits can be extracted and front run. Meaning that they will revert if already used
 * @dev     Can be a very unlikely griefing vector. This library mitigates this by trying permit() first
 * @notice  Credit to https://www.trust-security.xyz/
 */

library TrustlessPermit {
    function trustlessPermit(
        address token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        // Try permit() before allowance check to advance nonce if possible
        try IERC2612(token).permit(owner, spender, value, deadline, v, r, s) {
            return;
        } catch {
            // Permit potentially got frontran. Continue anyways if allowance is sufficient.
            if (IERC20(token).allowance(owner, spender) >= value) {
                return;
            }
        }
        revert('Permit failure');
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IStargateRouter } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol';
import { IStargateFactory } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateFactory.sol';
import { ISignatureTransfer } from '@uniswap/permit2/src/interfaces/ISignatureTransfer.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';
import { ReentrancyGuard } from '@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol';

import { TrustlessPermit } from '../lib/TrustlessPermit.sol';
import { Call } from '../lib/Call.sol';

import { ISquidRouter } from '../interfaces/ISquidRouter.sol';

/**
 * @title   MultiSwapAndBridge
 * @notice  Allows the owner of multiple tokens to swap them using 0x in one tx and then bridge them to another chain
 * @dev     This contract is designed to be used with the Stargate Router and 0x Exchange Router
 * @dev     Tokens can be safeApproved via ERC2612 permit or via Permit2 for tokens not supported by ERC2612
 */

contract MultiSwapAndBridge is ReentrancyGuard {
    using TrustlessPermit for address;
    using SafeERC20 for IERC20;

    struct SwapWithPermit2 {
        address sellToken;
        uint sellAmount;
        bytes zeroXQuoteData;
        ISignatureTransfer.PermitTransferFrom permitTransferFrom;
        bytes signature;
    }

    struct SwapWithERC2612Permit {
        address sellToken;
        uint sellAmount;
        bytes zeroXQuoteData;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    string public name = 'MultiSwapAndBridge';
    address public zeroXExchangeRouter;
    IStargateRouter public stargateRouter;
    ISignatureTransfer public permit2;
    address public stargateUSDC;

    constructor(
        address _zeroXExchangeRouter,
        IStargateRouter _stargateRouter,
        ISignatureTransfer _permit2,
        address _stargateUSDC
    ) {
        zeroXExchangeRouter = _zeroXExchangeRouter;
        stargateRouter = _stargateRouter;
        permit2 = _permit2;
        stargateUSDC = _stargateUSDC;
    }

    /**
     * @notice  Swaps and bridges tokens using the given the permits, 0x routes, and destination chainId
     * @dev     User can just swap and not bridge by setting lzDstChainId to 0
     * @dev     Note: 0x Swaps must result in USDC. Any other token will be lost
     * @param   swapsWithPermit2  The swaps using Permit2 with signature and 0x route
     * @param   swapsWithERC2612Permit  The swaps using ERC2612 permit with signature and 0x route
     */
    function swapAndBridge(
        SwapWithPermit2[] memory swapsWithPermit2,
        SwapWithERC2612Permit[] memory swapsWithERC2612Permit,
        // Stargate/LayerZero chainId, if 0 wont bridge, only swap
        // Only supply chainId's where USDC poolId == 1
        uint16 lzDstChainId
    ) external payable nonReentrant {
        for (uint256 i = 0; i < swapsWithPermit2.length; i++) {
            _swapWithPermit2(swapsWithPermit2[i]);
        }

        for (uint256 i = 0; i < swapsWithERC2612Permit.length; i++) {
            _swapWithERC2612Permit(swapsWithERC2612Permit[i]);
        }

        if (lzDstChainId != 0) {
            _bridgeStargate(lzDstChainId);
        } else {
            _transferOutUsdc();
        }
    }

    /**
     * @notice  Swaps and bridges tokens using the given the permits, 0x routes, and Squid call data
     * @dev     The SquidCall data must represent a callBridgeCall quote for the output token of the swaps
     * @param   swapsWithPermit2  The swaps using Permit2 with signature and 0x route
     * @param   swapsWithERC2612Permit  The swaps using ERC2612 permit with signature and 0x route
     * @param   squidRouter  The SquidRouter Address
     * @param   squidCallData  The callData from the Squid API
     */
    function swapAndBridgeSquid(
        SwapWithPermit2[] memory swapsWithPermit2,
        SwapWithERC2612Permit[] memory swapsWithERC2612Permit,
        address squidRouter,
        bytes calldata squidCallData
    ) external payable nonReentrant {
        for (uint256 i = 0; i < swapsWithPermit2.length; i++) {
            _swapWithPermit2(swapsWithPermit2[i]);
        }

        for (uint256 i = 0; i < swapsWithERC2612Permit.length; i++) {
            _swapWithERC2612Permit(swapsWithERC2612Permit[i]);
        }

        _bridgeSquid(squidRouter, squidCallData);
    }

    /**
     * @notice  This function is used to recover any tokens that were sent to the contract by mistake
     * @dev     This function cannot be called while there is a swapAndBridge taking place
     * @dev     Under normal circumstances this contract should never hold a balance of any token or eth.
     * @param   token  The address of the token to recover
     */
    function saveToken(address token) external nonReentrant {
        IERC20(token).safeTransfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    /**
     * @notice  Gets the cost of bridging to a given chain
     * @dev     This needs to be passed to the swapAndBridge function as the value
     * @param   dstChainId  The Stargate/LayerZero chainId
     */
    function bridgeQuote(
        uint16 dstChainId, // Stargate/LayerZero chainId
        address dstAddress
    ) external view returns (uint fee) {
        (fee, ) = stargateRouter.quoteLayerZeroFee(
            dstChainId,
            1, // function type: see Stargate Bridge.sol for all types
            abi.encodePacked(dstAddress),
            '0x',
            IStargateRouter.lzTxObj(0, 0, bytes(''))
        );
    }

    /**
     * @notice  Using permit2 takes the tokens and then swaps them with the 0x router
     * @param   swap  The swap details (permit, route)
     */
    function _swapWithPermit2(SwapWithPermit2 memory swap) internal {
        permit2.permitTransferFrom(
            swap.permitTransferFrom,
            ISignatureTransfer.SignatureTransferDetails({
                to: address(this),
                requestedAmount: swap.sellAmount
            }),
            msg.sender,
            swap.signature
        );

        _swap(swap.sellToken, swap.sellAmount, swap.zeroXQuoteData);
    }

    /**
     * @notice  Using ERC2612 permit takes the tokens and then swaps them with the 0x router
     * @param   swap  The swap details (permit, route)
     */
    function _swapWithERC2612Permit(
        SwapWithERC2612Permit memory swap
    ) internal {
        swap.sellToken.trustlessPermit(
            msg.sender,
            address(this),
            swap.sellAmount,
            swap.deadline,
            swap.v,
            swap.r,
            swap.s
        );
        IERC20(swap.sellToken).safeTransferFrom(
            msg.sender,
            address(this),
            swap.sellAmount
        );
        _swap(swap.sellToken, swap.sellAmount, swap.zeroXQuoteData);
    }

    /**
     * @notice  Swaps a token using the 0x router
     * @param   sellToken  The token to sell
     * @param   sellAmount  The amount of the token to sell
     * @param   zeroXSwapData  The 0x swap data (route, amount etc.)
     */
    function _swap(
        address sellToken,
        uint sellAmount,
        bytes memory zeroXSwapData
    ) internal {
        if (zeroXSwapData.length == 0) {
            return;
        }
        IERC20(sellToken).safeApprove(zeroXExchangeRouter, sellAmount);
        Call._call(zeroXExchangeRouter, zeroXSwapData);
    }

    /**
     * @notice  Bridges the USDC to the given chain to the msg.sender
     * @dev     The contract should never hold USDC
     * @param   dstChainId  The Stargate/LayerZero chainId
     */
    function _bridgeStargate(uint16 dstChainId) internal {
        uint usdcBalance = IERC20(stargateUSDC).balanceOf(address(this));
        IERC20(stargateUSDC).safeApprove(address(stargateRouter), usdcBalance);

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        stargateRouter.swap{ value: msg.value }(
            dstChainId, // the destination chain id
            1, // USDC source Stargate poolId
            1, // USDC destination Stargate poolId
            payable(msg.sender), // refund adddress. if msg.sender pays too much gas, return extra eth
            usdcBalance, // total tokens to send to destination chain
            (usdcBalance * 995) / 1000, // min amount allowed out
            IStargateRouter.lzTxObj(0, 0, bytes('')), // default lzTxObj
            abi.encodePacked(payable(msg.sender)), // destination address
            bytes('') // bytes payload
        );
    }

    /**
     * @notice  Transfers USDC that the result of the swaps to the msg.sender
     * @dev     The contract should never hold USDC
     */
    function _transferOutUsdc() internal {
        IERC20(stargateUSDC).safeTransfer(
            msg.sender,
            IERC20(stargateUSDC).balanceOf(address(this))
        );
    }

    /**
     * @notice  Executes the Squid Bridge call
     * @dev     We need to interpolate the Squid CallData with our post swap amount
     * @param   squidRouter  the Squid Router Address
     * @param   squidCallData  the callData from the Squid API
     */
    function _bridgeSquid(
        address squidRouter,
        bytes calldata squidCallData
    ) internal {
        bytes4 selector = bytes4(squidCallData[:4]);

        require(
            selector == ISquidRouter.callBridgeCall.selector,
            'INVALID_SELECTOR'
        );

        // The first 4 bytes on the msgData are the function signature,
        // in order to decode the payload it is required to skip those bytes of the function signature!
        // The Squid API only returns the full callData, we decode it and then interpolate our post swap amount
        (
            address token,
            ,
            ISquidRouter.Call[] memory calls,
            string memory bridgedTokenSymbol,
            string memory destinationChain,
            string memory destinationAddress,
            bytes memory payload,
            address gasRefundRecipient,
            bool enableExpress
        ) = abi.decode(
                squidCallData[4:],
                (
                    address,
                    uint256,
                    ISquidRouter.Call[],
                    string,
                    string,
                    string,
                    bytes,
                    address,
                    bool
                )
            );

        require(token == stargateUSDC, 'INVALID_BRIDGE_TOKEN');

        uint usdcBalance = IERC20(stargateUSDC).balanceOf(address(this));

        IERC20(stargateUSDC).safeApprove(address(squidRouter), usdcBalance);

        ISquidRouter(squidRouter).callBridgeCall{ value: msg.value }(
            token,
            usdcBalance,
            calls,
            bridgedTokenSymbol,
            destinationChain,
            destinationAddress,
            payload,
            gasRefundRecipient,
            enableExpress
        );
    }
}