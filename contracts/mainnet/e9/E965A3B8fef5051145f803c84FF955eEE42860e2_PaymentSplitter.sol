// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

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

    modifier nonReentrant() {
        if (ReentrancyGuardStorage.layout().status == REENTRANCY_STATUS_LOCKED)
            revert ReentrancyGuard__ReentrantCall();
        _lockReentrancyGuard();
        _;
        _unlockReentrancyGuard();
    }

    /**
     * @notice lock functions that use the nonReentrant modifier
     */
    function _lockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice unlock funtions that use the nonReentrant modifier
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

import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IERC20BaseInternal } from './IERC20BaseInternal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20Base is IERC20BaseInternal, IERC20 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from '../../../interfaces/IERC20Internal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20BaseInternal is IERC20Internal {
    error ERC20Base__ApproveFromZeroAddress();
    error ERC20Base__ApproveToZeroAddress();
    error ERC20Base__BurnExceedsBalance();
    error ERC20Base__BurnFromZeroAddress();
    error ERC20Base__InsufficientAllowance();
    error ERC20Base__MintToZeroAddress();
    error ERC20Base__TransferExceedsBalance();
    error ERC20Base__TransferFromZeroAddress();
    error ERC20Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20ExtendedInternal } from './IERC20ExtendedInternal.sol';

/**
 * @title ERC20 extended interface
 */
interface IERC20Extended is IERC20ExtendedInternal {
    /**
     * @notice increase spend amount granted to spender
     * @param spender address whose allowance to increase
     * @param amount quantity by which to increase allowance
     * @return success status (always true; otherwise function will revert)
     */
    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice decrease spend amount granted to spender
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     * @return success status (always true; otherwise function will revert)
     */
    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20BaseInternal } from '../base/IERC20BaseInternal.sol';

/**
 * @title ERC20 extended internal interface
 */
interface IERC20ExtendedInternal is IERC20BaseInternal {
    error ERC20Extended__ExcessiveAllowance();
    error ERC20Extended__InsufficientAllowance();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Base } from './base/IERC20Base.sol';
import { IERC20Extended } from './extended/IERC20Extended.sol';
import { IERC20Metadata } from './metadata/IERC20Metadata.sol';
import { IERC20Permit } from './permit/IERC20Permit.sol';

interface ISolidStateERC20 is
    IERC20Base,
    IERC20Extended,
    IERC20Metadata,
    IERC20Permit
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC20 metadata internal interface
 */
interface IERC20MetadataInternal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Metadata } from '../metadata/IERC20Metadata.sol';
import { IERC2612 } from './IERC2612.sol';
import { IERC20PermitInternal } from './IERC20PermitInternal.sol';

// TODO: note that IERC20Metadata is needed for eth-permit library

interface IERC20Permit is IERC20PermitInternal, IERC2612 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

interface IERC20PermitInternal is IERC2612Internal {
    error ERC20Permit__ExpiredDeadline();
    error ERC20Permit__InvalidSignature();
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
pragma solidity ^0.8.19;

import {IOFTCore} from "./IOFTCore.sol";
import {ISolidStateERC20} from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";

/// @dev Interface of the OFT standard
interface IOFT is IOFTCore, ISolidStateERC20 {
    error OFT_InsufficientAllowance();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";

/// @dev Interface of the IOFT core standard
interface IOFTCore is IERC165 {
    /// @dev Estimate send token `tokenId` to (`dstChainId`, `toAddress`)
    /// @param dstChainId L0 defined chain id to send tokens too
    /// @param toAddress Dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
    /// @param amount Amount of the tokens to transfer
    /// @param useZro Indicates to use zro to pay L0 fees
    /// @param adapterParams Flexible bytes array to indicate messaging adapter services in L0
    function estimateSendFee(
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 amount,
        bool useZro,
        bytes calldata adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /// @dev Send `amount` amount of token to (`dstChainId`, `toAddress`) from `from`
    /// @param from The owner of token
    /// @param dstChainId The destination chain identifier
    /// @param toAddress Can be any size depending on the `dstChainId`.
    /// @param amount The quantity of tokens in wei
    /// @param refundAddress The address LayerZero refunds if too much message fee is sent
    /// @param zroPaymentAddress Set to address(0x0) if not paying in ZRO (LayerZero Token)
    /// @param adapterParams Flexible bytes array to indicate messaging adapter services
    function sendFrom(
        address from,
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 amount,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable;

    /// @dev Returns the circulating amount of tokens on current chain
    function circulatingSupply() external view returns (uint256);

    /// @dev Emitted when `amount` tokens are moved from the `sender` to (`dstChainId`, `toAddress`)
    event SendToChain(address indexed sender, uint16 indexed dstChainId, bytes indexed toAddress, uint256 amount);

    /// @dev Emitted when `amount` tokens are received from `srcChainId` into the `toAddress` on the local chain.
    event ReceiveFromChain(
        uint16 indexed srcChainId,
        bytes indexed srcAddress,
        address indexed toAddress,
        uint256 amount
    );

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

interface IMiningAddRewards {
    /// @notice Add rewards to the mining contract
    function addRewards(uint256 amount) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

interface IPaymentSplitter {
    function pay(uint256 baseAmount, uint256 quoteAmount) external;
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import {IVxPremia} from "../staking/IVxPremia.sol";

import {IPaymentSplitter} from "./IPaymentSplitter.sol";
import {IMiningAddRewards} from "./IMiningAddRewards.sol";

contract PaymentSplitter is IPaymentSplitter, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable PREMIA;
    IERC20 public immutable USDC;
    IVxPremia public immutable VX_PREMIA;
    IMiningAddRewards public immutable MINING;

    constructor(IERC20 premia, IERC20 usdc, IVxPremia vxPremia, IMiningAddRewards mining) {
        PREMIA = premia;
        USDC = usdc;
        VX_PREMIA = vxPremia;
        MINING = mining;
    }

    /// @notice Distributes rewards to vxPREMIA staking contract, and send back PREMIA leftover to mining contract
    /// @param premiaAmount Amount of PREMIA to send back to mining contract
    /// @param usdcAmount Amount of USDC to send to vxPREMIA staking contract
    function pay(uint256 premiaAmount, uint256 usdcAmount) external nonReentrant {
        if (premiaAmount > 0) {
            PREMIA.safeTransferFrom(msg.sender, address(this), premiaAmount);
            PREMIA.approve(address(MINING), premiaAmount);
            MINING.addRewards(premiaAmount);
        }

        if (usdcAmount > 0) {
            USDC.safeTransferFrom(msg.sender, address(this), usdcAmount);
            USDC.approve(address(VX_PREMIA), usdcAmount);
            VX_PREMIA.addRewards(usdcAmount);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {PremiaStakingStorage} from "./PremiaStakingStorage.sol";
import {IOFT} from "../layerZero/token/oft/IOFT.sol";

import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";

// IERC20Metadata inheritance not possible due to linearization issue
interface IPremiaStaking is IERC2612, IOFT {
    error PremiaStaking__CantTransfer();
    error PremiaStaking__ExcessiveStakePeriod();
    error PremiaStaking__InsufficientSwapOutput();
    error PremiaStaking__NoPendingWithdrawal();
    error PremiaStaking__NotEnoughLiquidity();
    error PremiaStaking__PeriodTooShort();
    error PremiaStaking__StakeLocked();
    error PremiaStaking__StakeNotLocked();
    error PremiaStaking__WithdrawalStillPending();

    event Stake(address indexed user, uint256 amount, uint64 stakePeriod, uint64 lockedUntil);

    event Unstake(address indexed user, uint256 amount, uint256 fee, uint256 startDate);

    event Harvest(address indexed user, uint256 amount);

    event EarlyUnstakeRewardCollected(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event RewardsAdded(uint256 amount);

    struct StakeLevel {
        uint256 amount; // Amount to stake
        uint256 discount; // Discount when amount is reached
    }

    struct SwapArgs {
        //min amount out to be used to purchase
        uint256 amountOutMin;
        // exchange address to call to execute the trade
        address callee;
        // address for which to set allowance for the trade
        address allowanceTarget;
        // data to execute the trade
        bytes data;
        // address to which refund excess tokens
        address refundAddress;
    }

    event BridgeLock(address indexed user, uint64 stakePeriod, uint64 lockedUntil);

    event UpdateLock(address indexed user, uint64 oldStakePeriod, uint64 newStakePeriod);

    /// @notice Returns the reward token address
    /// @return The reward token address
    function getRewardToken() external view returns (address);

    /// @notice add premia tokens as available tokens to be distributed as rewards
    /// @param amount amount of premia tokens to add as rewards
    function addRewards(uint256 amount) external;

    /// @notice get amount of tokens that have not yet been distributed as rewards
    /// @return rewards amount of tokens not yet distributed as rewards
    /// @return unstakeRewards amount of PREMIA not yet claimed from early unstake fees
    function getAvailableRewards() external view returns (uint256 rewards, uint256 unstakeRewards);

    /// @notice get pending amount of tokens to be distributed as rewards to stakers
    /// @return amount of tokens pending to be distributed as rewards
    function getPendingRewards() external view returns (uint256);

    /// @notice Return the total amount of premia pending withdrawal
    function getPendingWithdrawals() external view returns (uint256);

    /// @notice get pending withdrawal data of a user
    /// @return amount pending withdrawal amount
    /// @return startDate start timestamp of withdrawal
    /// @return unlockDate timestamp at which withdrawal becomes available
    function getPendingWithdrawal(
        address user
    ) external view returns (uint256 amount, uint256 startDate, uint256 unlockDate);

    /// @notice get the amount of PREMIA available for withdrawal
    /// @return amount of PREMIA available for withdrawal
    function getAvailablePremiaAmount() external view returns (uint256);

    /// @notice Stake using IERC2612 permit
    /// @param amount The amount of xPremia to stake
    /// @param period The lockup period (in seconds)
    /// @param deadline Deadline after which permit will fail
    /// @param v V
    /// @param r R
    /// @param s S
    function stakeWithPermit(uint256 amount, uint64 period, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /// @notice Lockup xPremia for protocol fee discounts
    ///         Longer period of locking will apply a multiplier on the amount staked, in the fee discount calculation
    /// @param amount The amount of xPremia to stake
    /// @param period The lockup period (in seconds)
    function stake(uint256 amount, uint64 period) external;

    /// @notice update vxPremia lock
    /// @param period The new lockup period (in seconds)
    function updateLock(uint64 period) external;

    /// @notice harvest rewards, convert to PREMIA using exchange helper, and stake
    /// @param s swap arguments
    /// @param stakePeriod The lockup period (in seconds)
    function harvestAndStake(IPremiaStaking.SwapArgs calldata s, uint64 stakePeriod) external;

    /// @notice Harvest rewards directly to user wallet
    function harvest() external;

    /// @notice Get pending rewards amount, including pending pool update
    /// @param user User for which to calculate pending rewards
    /// @return reward amount of pending rewards from protocol fees (in REWARD_TOKEN)
    /// @return unstakeReward amount of pending rewards from early unstake fees (in PREMIA)
    function getPendingUserRewards(address user) external view returns (uint256 reward, uint256 unstakeReward);

    /// @notice unstake tokens before end of the lock period, for a fee
    /// @param amount the amount of vxPremia to unstake
    function earlyUnstake(uint256 amount) external;

    /// @notice get early unstake fee for given user
    /// @param user address of the user
    /// @return feePercentage % fee to pay for early unstake (1e18 = 100%)
    function getEarlyUnstakeFee(address user) external view returns (uint256 feePercentage);

    /// @notice Initiate the withdrawal process by burning xPremia, starting the delay period
    /// @param amount quantity of xPremia to unstake
    function startWithdraw(uint256 amount) external;

    /// @notice Withdraw underlying premia
    function withdraw() external;

    //////////
    // View //
    //////////

    /// Calculate the stake amount of a user, after applying the bonus from the lockup period chosen
    /// @param user The user from which to query the stake amount
    /// @return The user stake amount after applying the bonus
    function getUserPower(address user) external view returns (uint256);

    /// Return the total power across all users (applying the bonus from lockup period chosen)
    /// @return The total power across all users
    function getTotalPower() external view returns (uint256);

    /// @notice Calculate the % of fee discount for user, based on his stake
    /// @param user The _user for which the discount is for
    /// @return Percentage of protocol fee discount
    ///         Ex : 1e17 = 10% fee discount
    function getDiscount(address user) external view returns (uint256);

    /// @notice Get stake levels
    /// @return Stake levels
    ///         Ex : 25e16 = -25%
    function getStakeLevels() external pure returns (StakeLevel[] memory);

    /// @notice Get stake period multiplier
    /// @param period The duration (in seconds) for which tokens are locked
    /// @return The multiplier for this staking period
    ///         Ex : 2e18 = x2
    function getStakePeriodMultiplier(uint256 period) external pure returns (uint256);

    /// @notice Get staking infos of a user
    /// @param user The user address for which to get staking infos
    /// @return The staking infos of the user
    function getUserInfo(address user) external view returns (PremiaStakingStorage.UserInfo memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {VxPremiaStorage} from "./VxPremiaStorage.sol";
import {IPremiaStaking} from "./IPremiaStaking.sol";

interface IVxPremia is IPremiaStaking {
    error VxPremia__InvalidPoolAddress();
    error VxPremia__InvalidVoteTarget();
    error VxPremia__NotEnoughVotingPower();

    event AddVote(address indexed voter, VoteVersion indexed version, bytes target, uint256 amount);
    event RemoveVote(address indexed voter, VoteVersion indexed version, bytes target, uint256 amount);

    enum VoteVersion {
        V2, // poolAddress : 20 bytes / isCallPool : 2 bytes
        VaultV3 // vaultAddress : 20 bytes
    }

    /// @notice get total votes for specific pools
    /// @param version version of target (used to know how to decode data)
    /// @param target ABI encoded target of the votes
    /// @return total votes for specific pool
    function getPoolVotes(VoteVersion version, bytes calldata target) external view returns (uint256);

    /// @notice get votes of user
    /// @param user user from which to get votes
    /// @return votes of user
    function getUserVotes(address user) external view returns (VxPremiaStorage.Vote[] memory);

    /// @notice add or remove votes, in the limit of the user voting power
    /// @param votes votes to cast
    function castVotes(VxPremiaStorage.Vote[] calldata votes) external;
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

library PremiaStakingStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.staking.PremiaStaking");

    struct Withdrawal {
        uint256 amount; // Premia amount
        uint256 startDate; // Will unlock at startDate + withdrawalDelay
    }

    struct UserInfo {
        uint256 reward; // Amount of rewards accrued which havent been claimed yet
        uint256 rewardDebt; // Debt to subtract from reward calculation
        uint256 unstakeRewardDebt; // Debt to subtract from reward calculation from early unstake fee
        uint64 stakePeriod; // Stake period selected by user
        uint64 lockedUntil; // Timestamp at which the lock ends
    }

    struct Layout {
        uint256 pendingWithdrawal;
        uint256 _deprecated_withdrawalDelay;
        mapping(address => Withdrawal) withdrawals;
        uint256 availableRewards;
        uint256 lastRewardUpdate; // Timestamp of last reward distribution update
        uint256 totalPower; // Total power of all staked tokens (underlying amount with multiplier applied)
        mapping(address => UserInfo) userInfo;
        uint256 accRewardPerShare;
        uint256 accUnstakeRewardPerShare;
        uint256 availableUnstakeRewards;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: LicenseRef-P3-DUAL
// For terms and conditions regarding commercial use please see https://license.premia.blue
pragma solidity ^0.8.19;

import {IVxPremia} from "./IVxPremia.sol";

library VxPremiaStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("premia.contracts.staking.VxPremia");

    struct Vote {
        uint256 amount;
        IVxPremia.VoteVersion version;
        bytes target;
    }

    struct Layout {
        mapping(address => Vote[]) userVotes;
        // Vote version -> Pool identifier -> Vote amount
        mapping(IVxPremia.VoteVersion => mapping(bytes => uint256)) votes;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}