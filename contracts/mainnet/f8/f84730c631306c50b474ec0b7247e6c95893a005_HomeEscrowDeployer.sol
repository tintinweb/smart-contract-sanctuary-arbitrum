// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {HomeEscrow} from "./HomeEscrow.sol";
import {BaseEscrowDeployer, CREATE3} from "./BaseEscrowDeployer.sol";

/// @title HomeEscrowDeployer
/// @notice Contract for deploying HomeEscrow contracts
contract HomeEscrowDeployer is BaseEscrowDeployer {
    address public immutable sgComposer;

    constructor(address _messenger, address _sgComposer) BaseEscrowDeployer(_messenger) {
        sgComposer = _sgComposer;
    }

    /// @notice Deploys a new escrow contract
    ///
    /// @param user The address of the user for whom the escrow contract is being deployed
    ///
    /// @return escrow The address of the deployed escrow contract
    function deploy(address user) external override returns (address escrow) {
        escrow = CREATE3.deploy(
            keccak256(abi.encodePacked(user)),
            abi.encodePacked(type(HomeEscrow).creationCode, abi.encode(messenger, sgComposer)),
            0
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IStargateReceiver} from "../interfaces/stargate/IStargateReceiver.sol";
import {IPhutureOnEscrowCallback} from "../interfaces/IPhutureOnEscrowCallback.sol";

import {BaseEscrow} from "./BaseEscrow.sol";

import {EscrowCallLib} from "./libraries/EscrowCallLib.sol";

/// @title HomeEscrow
/// @dev Implementation of the IHomeEscrow interface, which extends the functionality of the IEscrow interface.
///      The HomeEscrow contract enables trading and withdrawal of funds based on specified parameters
contract HomeEscrow is BaseEscrow, IPhutureOnEscrowCallback, IStargateReceiver {
    using EscrowCallLib for *;

    address public immutable sgComposer;
    bytes32 private immutable selfHash;

    /// @notice Address whos allowed to call `sgReceive` method
    /// @dev this slot is used for stateOverrides during gas estimation
    address internal allowedCaller;

    constructor(address _messenger, address _sgComposer) BaseEscrow(_messenger) {
        sgComposer = _sgComposer;
        selfHash = keccak256(abi.encodePacked(address(this)));
    }

    /// @notice Receives tokens from Stargate
    ///
    /// @param srcEid The source endpoint ID
    /// @param srcAddress The source address
    /// @param token The address of the token received
    /// @param amountLD The amount received in local decimals
    /// @param payload Additional data passed with the transfer
    function sgReceive(
        uint16 srcEid,
        bytes calldata srcAddress,
        uint256,
        address token,
        uint256 amountLD,
        bytes calldata payload
    ) external {
        if (!(msg.sender == sgComposer || msg.sender == allowedCaller)) revert Forbidden();
        if (keccak256(srcAddress) != selfHash) revert Forbidden();

        (EscrowCallLib.Trade[] memory trades, EscrowCallLib.Target memory callback) =
            abi.decode(payload, (EscrowCallLib.Trade[], EscrowCallLib.Target));

        _phutureOnEscrowCallbackV1(trades, callback);
    }

    function phutureOnEscrowCallbackV1(EscrowCallLib.Trade[] calldata trades, EscrowCallLib.Target calldata callback)
        external
    {
        if (msg.sender != messenger) revert Forbidden();

        _phutureOnEscrowCallbackV1(trades, callback);
    }

    function _phutureOnEscrowCallbackV1(EscrowCallLib.Trade[] memory trades, EscrowCallLib.Target memory callback)
        internal
    {
        _lock();

        for (uint256 i; i < trades.length; ++i) {
            trades[i].callNotSelf();
        }

        _executeCallback(callback);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IEscrowDeployer} from "./interfaces/IEscrowDeployer.sol";

import {CREATE3} from "solmate/utils/CREATE3.sol";

/// @title BaseEscrowDeployer
/// @notice Contract for deploying escrow contracts
abstract contract BaseEscrowDeployer is IEscrowDeployer {
    /// @dev The address of the Messenger contract
    address public immutable messenger;

    constructor(address _messenger) {
        messenger = _messenger;
    }

    /// @notice Predicts the address of the escrow contract for a user
    ///
    /// @param user The address of the user for whom the escrow contract is being predicted
    ///
    /// @return escrow The address of the predicted escrow contract
    /// @return deployed Whether the escrow contract has been deployed
    function escrowOf(address user) external view override returns (address escrow, bool deployed) {
        escrow = CREATE3.getDeployed(keccak256(abi.encodePacked(user)));
        deployed = _deployed(escrow);
    }

    /// @dev Checks if a contract is deployed at a given address
    ///
    /// @param _addr The address to check
    ///
    /// @return result Whether a contract is deployed at the given address
    function _deployed(address _addr) private view returns (bool result) {
        assembly ("memory-safe") {
            result := extcodesize(_addr)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IStargateReceiver {
    function sgReceive(
        uint16 _eid,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {EscrowCallLib} from "src/escrow/libraries/EscrowCallLib.sol";

interface IPhutureOnEscrowCallback {
    function phutureOnEscrowCallbackV1(EscrowCallLib.Trade[] calldata targets, EscrowCallLib.Target calldata callback)
        external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IPhutureEscrowCallbackBuilder} from "./interfaces/IPhutureEscrowCallbackBuilder.sol";
import {IPhutureEscrowCallback} from "./interfaces/IPhutureEscrowCallback.sol";
import {IEscrow} from "./interfaces/IEscrow.sol";

import {EscrowCallLib} from "./libraries/EscrowCallLib.sol";

abstract contract BaseEscrow is IEscrow {
    using EscrowCallLib for *;

    uint256 private locked = 1;

    /// @dev The address of the Messenger contract, set during contract deployment
    address public immutable messenger;

    /// @notice Thrown when an unauthorized caller attempts to execute a callback
    /// @dev Only the RemoteMessenger contract is allowed to execute the callback
    error Forbidden();
    error Reentrancy();

    constructor(address _messenger) {
        messenger = _messenger;
    }

    receive() external payable {}

    function phutureOnCallbackReceived(EscrowCallLib.Target[] calldata targets, EscrowCallLib.Target calldata callback)
        external
    {
        if (msg.sender != address(this)) revert Forbidden();

        _lock();

        for (uint256 i; i < targets.length; ++i) {
            targets[i].callNotSelf();
        }

        _executeCallback(callback);
    }

    function _executeCallback(EscrowCallLib.Target memory callback) internal {
        if (callback.addr != address(0)) {
            (EscrowCallLib.Target[] memory nextTargets, EscrowCallLib.Target memory nextCallback) =
                IPhutureEscrowCallbackBuilder(callback.addr).phutureCreateTarget{value: callback.value}(callback.data);

            _unlock();

            IPhutureEscrowCallback(address(this)).phutureOnCallbackReceived(nextTargets, nextCallback);
        } else {
            _unlock();
        }
    }

    function _lock() internal {
        if (locked != 1) revert Reentrancy();
        locked = 2;
    }

    function _unlock() internal {
        locked = 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {CurrencyLib, Currency} from "src/libraries/CurrencyLib.sol";

library EscrowCallLib {
    using CurrencyLib for Currency;

    struct Trade {
        bool skipRevert;
        Currency currency;
        address allowanceTarget;
        address addr;
        uint256 value;
        bytes data;
    }

    struct Target {
        bool skipRevert;
        address addr;
        uint256 value;
        bytes data;
    }

    error SelfCall();
    error TradeFailed();
    error TargetFailed();

    function callNotSelf(Trade memory self) internal {
        if (self.addr == address(this)) revert SelfCall();

        uint256 balance = self.currency.balanceOfSelf();
        bool approve = self.allowanceTarget != address(0) && balance != 0;
        if (approve) self.currency.approve(self.allowanceTarget, balance);

        // if currency is Native and no value passed - use current balance as value
        if (self.currency.isNative() && self.value == 0) self.value = balance;

        (bool success, bytes memory returnData) = self.addr.call{value: self.value}(self.data);
        if (!self.skipRevert && !success) {
            if (returnData.length == 0) revert TradeFailed();

            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        if (approve) self.currency.approve(self.allowanceTarget, 0);
    }

    function callNotSelf(Target memory self) internal {
        if (self.addr == address(this)) revert SelfCall();

        (bool success, bytes memory returnData) = self.addr.call{value: self.value}(self.data);
        if (!self.skipRevert && !success) {
            if (returnData.length == 0) revert TargetFailed();

            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/// @title IEscrowDeployer
/// @dev Interface for the EscrowDeployer contract, which manages the deployment and tracking of Escrow contracts
interface IEscrowDeployer {
    /// @notice Deploys a new Escrow contract for the specified user
    ///
    /// @param user The address of the user for whom the Escrow contract is deployed
    ///
    /// @return escrow The address of the newly deployed Escrow contract
    function deploy(address user) external returns (address escrow);

    /// @notice Retrieves the address and deployment status of the Escrow contract associated with the given owner
    ///
    /// @param owner The address of the owner for whom to retrieve the Escrow contract information
    ///
    /// @return escrow The address of the Escrow contract associated with the owner
    /// @return deployed A boolean indicating whether the Escrow contract has been deployed for the owner
    function escrowOf(address owner) external view returns (address escrow, bool deployed);

    /// @notice Retrieves the address of the Messenger contract associated with the EscrowDeployer
    ///
    /// @return The address of the Messenger contract
    function messenger() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Bytes32AddressLib} from "./Bytes32AddressLib.sol";

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
library CREATE3 {
    using Bytes32AddressLib for bytes32;

    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 0 size               //
    // 0x37       |  0x37                 | CALLDATACOPY     |                        //
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x34       |  0x34                 | CALLVALUE        | value 0 size           //
    // 0xf0       |  0xf0                 | CREATE           | newContract            //
    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x67       |  0x67XXXXXXXXXXXXXXXX | PUSH8 bytecode   | bytecode               //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 bytecode             //
    // 0x52       |  0x52                 | MSTORE           |                        //
    // 0x60       |  0x6008               | PUSH1 08         | 8                      //
    // 0x60       |  0x6018               | PUSH1 18         | 24 8                   //
    // 0xf3       |  0xf3                 | RETURN           |                        //
    //--------------------------------------------------------------------------------//
    bytes internal constant PROXY_BYTECODE = hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

    bytes32 internal constant PROXY_BYTECODE_HASH = keccak256(PROXY_BYTECODE);

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) internal returns (address deployed) {
        bytes memory proxyChildBytecode = PROXY_BYTECODE;

        address proxy;
        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            // We start 32 bytes into the code to avoid copying the byte length.
            proxy := create2(0, add(proxyChildBytecode, 32), mload(proxyChildBytecode), salt)
        }
        require(proxy != address(0), "DEPLOYMENT_FAILED");

        deployed = getDeployed(salt);
        (bool success, ) = proxy.call{value: value}(creationCode);
        require(success && deployed.code.length != 0, "INITIALIZATION_FAILED");
    }

    function getDeployed(bytes32 salt) internal view returns (address) {
        return getDeployed(salt, address(this));
    }

    function getDeployed(bytes32 salt, address creator) internal pure returns (address) {
        address proxy = keccak256(
            abi.encodePacked(
                // Prefix:
                bytes1(0xFF),
                // Creator:
                creator,
                // Salt:
                salt,
                // Bytecode hash:
                PROXY_BYTECODE_HASH
            )
        ).fromLast20Bytes();

        return
            keccak256(
                abi.encodePacked(
                    // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01)
                    // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
                    hex"d6_94",
                    proxy,
                    hex"01" // Nonce of the proxy contract (1)
                )
            ).fromLast20Bytes();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {EscrowCallLib} from "../libraries/EscrowCallLib.sol";

interface IPhutureEscrowCallbackBuilder {
    function phutureCreateTarget(bytes calldata data)
        external
        payable
        returns (EscrowCallLib.Target[] memory targets, EscrowCallLib.Target memory callback);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {EscrowCallLib} from "../libraries/EscrowCallLib.sol";

interface IPhutureEscrowCallback {
    function phutureOnCallbackReceived(EscrowCallLib.Target[] calldata targets, EscrowCallLib.Target calldata callback)
        external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {EscrowCallLib} from "../libraries/EscrowCallLib.sol";

/// @title IEscrow
/// @dev Interface for the Escrow contract
interface IEscrow {
    function phutureOnCallbackReceived(EscrowCallLib.Target[] calldata targets, EscrowCallLib.Target calldata callback)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

type Currency is address;

using {eq as ==, neq as !=} for Currency global;

function eq(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) == Currency.unwrap(other);
}

function neq(Currency currency, Currency other) pure returns (bool) {
    return !eq(currency, other);
}

/// @title CurrencyLibrary
/// @dev This library allows for transferring and holding native tokens and ERC20 tokens
/// @author Modified from Uniswap (https://github.com/Uniswap/v4-core/blob/main/src/types/Currency.sol)
library CurrencyLib {
    using SafeERC20 for IERC20;
    using CurrencyLib for Currency;

    /// @dev Currency wrapper for native currency
    Currency public constant NATIVE = Currency.wrap(address(0));

    /// @notice Thrown when a native transfer fails
    error NativeTransferFailed();

    /// @notice Thrown when an ERC20 transfer fails
    error ERC20TransferFailed();

    /// @notice Thrown when deposit amount exceeds current balance
    error AmountExceedsBalance();

    /// @notice Transfers currency
    ///
    /// @param currency Currency to transfer
    /// @param to Address of recipient
    /// @param amount Currency amount ot transfer
    function transfer(Currency currency, address to, uint256 amount) internal {
        if (amount == 0) return;
        // implementation from
        // https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/SafeTransferLib.sol

        bool success;
        if (currency.isNative()) {
            assembly {
                // Transfer the ETH and store if it succeeded or not.
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }

            if (!success) revert NativeTransferFailed();
        } else {
            assembly {
                // We'll write our calldata to this slot below, but restore it later.
                let freeMemoryPointer := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
                mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

                success :=
                    and(
                        // Set success to whether the call reverted, if not we check it either
                        // returned exactly 1 (can't just be non-zero data), or had no return data.
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                        // Counterintuitively, this call() must be positioned after the or() in the
                        // surrounding and() because and() evaluates its arguments from right to left.
                        call(gas(), currency, 0, freeMemoryPointer, 68, 0, 32)
                    )
            }

            if (!success) revert ERC20TransferFailed();
        }
    }

    /// @notice Approves currency
    ///
    /// @param currency Currency to approve
    /// @param spender Address of spender
    /// @param amount Currency amount to approve
    function approve(Currency currency, address spender, uint256 amount) internal {
        if (isNative(currency)) return;
        IERC20(Currency.unwrap(currency)).forceApprove(spender, amount);
    }

    /// @notice Returns the balance of a given currency for a specific account
    ///
    /// @param currency The currency to check
    /// @param account The address of the account
    ///
    /// @return The balance of the specified currency for the given account
    function balanceOf(Currency currency, address account) internal view returns (uint256) {
        return currency.isNative() ? account.balance : IERC20(Currency.unwrap(currency)).balanceOf(account);
    }

    /// @notice Returns the balance of a given currency for this contract
    ///
    /// @param currency The currency to check
    ///
    /// @return The balance of the specified currency for this contract
    function balanceOfSelf(Currency currency) internal view returns (uint256) {
        return currency.isNative() ? address(this).balance : IERC20(Currency.unwrap(currency)).balanceOf(address(this));
    }

    /// @notice Checks if the specified currency is the native currency
    ///
    /// @param currency The currency to check
    ///
    /// @return `true` if the specified currency is the native currency, `false` otherwise
    function isNative(Currency currency) internal pure returns (bool) {
        return currency == NATIVE;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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