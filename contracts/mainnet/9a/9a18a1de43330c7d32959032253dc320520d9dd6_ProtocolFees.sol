// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "./external/Ownable.sol";
import {TransferHelper} from "../src/vault/libraries/utils/TransferHelper.sol";

import {IProtocolFees} from "./IProtocolFees.sol";

/// @title ProtocolFees
contract ProtocolFees is IProtocolFees, Ownable {
    // =========================
    // Storage
    // =========================

    /// @dev ditto treasury address
    address private _treasury;

    /// @dev instant fee in gas bps, 1e18 == 100%
    /// @dev e.g. gasUsed * instantFeeGasBps / 1e18
    uint64 private _instantFeeGasBps; //

    /// @dev fixed fee for transactions
    uint192 private _instantFeeFix;

    /// @dev automation fee in gas bps, 1e18 == 100%
    /// @dev e.g. gasUsed * automationFeeGasBps / 1e18
    uint64 private _automationFeeGasBps;

    /// @dev fixed fee for transactions
    uint192 private _automationFeeFix; //

    // =========================
    // Constructor
    // =========================

    constructor(address owner) {
        _transferOwnership(owner);
    }

    // =========================
    // Getters
    // =========================

    /// @inheritdoc IProtocolFees
    function getInstantFeesAndTreasury()
        external
        view
        returns (
            address treasury,
            uint256 instantFeeGasBps,
            uint256 instantFeeFix
        )
    {
        treasury = _treasury;
        instantFeeGasBps = _instantFeeGasBps;
        instantFeeFix = _instantFeeFix;
    }

    /// @inheritdoc IProtocolFees
    function getAutomationFeesAndTreasury()
        external
        view
        returns (
            address treasury,
            uint256 automationFeeGasBps,
            uint256 automationFeeFix
        )
    {
        treasury = _treasury;
        automationFeeGasBps = _automationFeeGasBps;
        automationFeeFix = _automationFeeFix;
    }

    // =========================
    // Setters
    // =========================

    /// @inheritdoc IProtocolFees
    function setInstantFees(
        uint64 instantFeeGasBps,
        uint192 instantFeeFix
    ) external onlyOwner {
        _instantFeeGasBps = instantFeeGasBps;
        _instantFeeFix = instantFeeFix;

        emit InstantFeesChanged(instantFeeGasBps, instantFeeFix);
    }

    /// @inheritdoc IProtocolFees
    function setAutomationFee(
        uint64 automationFeeGasBps,
        uint192 automationFeeFix
    ) external onlyOwner {
        _automationFeeGasBps = automationFeeGasBps;
        _automationFeeFix = automationFeeFix;

        emit AutomationFeesChanged(automationFeeGasBps, automationFeeFix);
    }

    /// @inheritdoc IProtocolFees
    function setTreasury(address treasury) external onlyOwner {
        _treasury = treasury;

        emit TreasuryChanged(treasury);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IOwnable} from "./IOwnable.sol";

/// @title Ownable
/// @dev Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {transferOwnership}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner.
abstract contract Ownable is IOwnable {
    // =========================
    // Storage
    // =========================

    /// @dev Private variable to store the owner's address.
    address private _owner;

    // =========================
    // Main functions
    // =========================

    /// @notice Initializes the contract, setting the deployer as the initial owner.
    constructor() {
        _transferOwnership(msg.sender);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /// @inheritdoc IOwnable
    function owner() external view returns (address) {
        return _owner;
    }

    /// @inheritdoc IOwnable
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    /// @inheritdoc IOwnable
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert Ownable_NewOwnerCannotBeAddressZero();
        }

        _transferOwnership(newOwner);
    }

    // =========================
    // Internal functions
    // =========================

    /// @dev Internal function to verify if the caller is the owner of the contract.
    /// Errors:
    /// - Thrown `Ownable_SenderIsNotOwner` if the caller is not the owner.
    function _checkOwner() internal view {
        if (_owner != msg.sender) {
            revert Ownable_SenderIsNotOwner(msg.sender);
        }
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// @dev Emits an {OwnershipTransferred} event.
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title TransferHelper
/// @notice A helper library for safe transfers, approvals, and balance checks.
/// @dev Provides safe functions for ERC20 token and native currency transfers.
library TransferHelper {
    // =========================
    // Event
    // =========================

    /// @notice Emits when a transfer is successfully executed.
    /// @param token The address of the token (address(0) for native currency).
    /// @param from The address of the sender.
    /// @param to The address of the recipient.
    /// @param value The number of tokens (or native currency) transferred.
    event TransferHelperTransfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 value
    );

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when `safeTransferFrom` fails.
    error TransferHelper_SafeTransferFromError();

    /// @notice Thrown when `safeTransfer` fails.
    error TransferHelper_SafeTransferError();

    /// @notice Thrown when `safeApprove` fails.
    error TransferHelper_SafeApproveError();

    /// @notice Thrown when `safeGetBalance` fails.
    error TransferHelper_SafeGetBalanceError();

    /// @notice Thrown when `safeTransferNative` fails.
    error TransferHelper_SafeTransferNativeError();

    // =========================
    // Functions
    // =========================

    /// @notice Executes a safe transfer from one address to another.
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param token Address of the ERC20 token to transfer.
    /// @param from Address of the sender.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        if (
            !_makeCall(
                token,
                abi.encodeCall(IERC20.transferFrom, (from, to, value))
            )
        ) {
            revert TransferHelper_SafeTransferFromError();
        }

        emit TransferHelperTransfer(token, from, to, value);
    }

    /// @notice Executes a safe transfer.
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param token Address of the ERC20 token to transfer.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransfer(address token, address to, uint256 value) internal {
        if (!_makeCall(token, abi.encodeCall(IERC20.transfer, (to, value)))) {
            revert TransferHelper_SafeTransferError();
        }

        emit TransferHelperTransfer(token, address(this), to, value);
    }

    /// @notice Executes a safe approval.
    /// @dev Uses low-level calls to handle cases where allowance is not zero
    /// and tokens which are not supports approve with non-zero allowance.
    /// @param token Address of the ERC20 token to approve.
    /// @param spender Address of the account that gets the approval.
    /// @param value Amount to approve.
    function safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeCall(
            IERC20.approve,
            (spender, value)
        );

        if (!_makeCall(token, approvalCall)) {
            if (
                !_makeCall(
                    token,
                    abi.encodeCall(IERC20.approve, (spender, 0))
                ) || !_makeCall(token, approvalCall)
            ) {
                revert TransferHelper_SafeApproveError();
            }
        }
    }

    /// @notice Retrieves the balance of an account safely.
    /// @dev Uses low-level staticcall to ensure proper error handling.
    /// @param token Address of the ERC20 token.
    /// @param account Address of the account to fetch balance for.
    /// @return The balance of the account.
    function safeGetBalance(
        address token,
        address account
    ) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, account)
        );
        if (!success || data.length == 0) {
            revert TransferHelper_SafeGetBalanceError();
        }
        return abi.decode(data, (uint256));
    }

    /// @notice Executes a safe transfer of native currency (e.g., ETH).
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        if (!success) {
            revert TransferHelper_SafeTransferNativeError();
        }

        emit TransferHelperTransfer(address(0), address(this), to, value);
    }

    // =========================
    // Private function
    // =========================

    /// @dev Helper function to make a low-level call for token methods.
    /// @dev Ensures correct return value and decodes it.
    ///
    /// @param token Address to make the call on.
    /// @param data Calldata for the low-level call.
    /// @return True if the call succeeded, false otherwise.
    function _makeCall(
        address token,
        bytes memory data
    ) private returns (bool) {
        (bool success, bytes memory returndata) = token.call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title IProtocolFees - ProtocolFees interface
interface IProtocolFees {
    // =========================
    // Events
    // =========================

    /// @notice Emits when instant fees are changed.
    event InstantFeesChanged(uint64 instantFeeGasBps, uint192 instantFeeFix);

    /// @notice Emits when automation fees are changed.
    event AutomationFeesChanged(
        uint64 automationFeeGasBps,
        uint192 automationFeeFix
    );

    /// @notice Emits when treasury address are changed.
    event TreasuryChanged(address treasury);

    // =========================
    // Getters
    // =========================

    /// @notice Gets instant fees.
    /// @return treasury address of the ditto treasury
    /// @return instantFeeGasBps instant fee in gas bps
    /// @return instantFeeFix fixed fee for instant calls
    function getInstantFeesAndTreasury()
        external
        view
        returns (
            address treasury,
            uint256 instantFeeGasBps,
            uint256 instantFeeFix
        );

    /// @notice Gets automation fees.
    /// @return treasury address of the ditto treasury
    /// @return automationFeeGasBps automation fee in gas bps
    /// @return automationFeeFix fixed fee for automation calls
    function getAutomationFeesAndTreasury()
        external
        view
        returns (
            address treasury,
            uint256 automationFeeGasBps,
            uint256 automationFeeFix
        );

    // =========================
    // Setters
    // =========================

    /// @notice Sets instant fees.
    /// @param instantFeeGasBps: instant fee in gas bps
    /// @param instantFeeFix: fixed fee for instant calls
    function setInstantFees(
        uint64 instantFeeGasBps,
        uint192 instantFeeFix
    ) external;

    /// @notice Sets automation fees.
    /// @param automationFeeGasBps: automation fee in gas bps
    /// @param automationFeeFix: fixed fee for automation calls
    function setAutomationFee(
        uint64 automationFeeGasBps,
        uint192 automationFeeFix
    ) external;

    /// @notice Sets the ditto treasury address.
    /// @param treasury: address of the ditto treasury
    function setTreasury(address treasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title IOwnable - Ownable Interface
/// @dev Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {transferOwnership}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner.
interface IOwnable {
    // =========================
    // Events
    // =========================

    /// @notice Emits when ownership of the contract is transferred from `previousOwner`
    /// to `newOwner`.
    /// @param previousOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when the caller is not authorized to perform an operation.
    /// @param sender The address of the sender trying to access a restricted function.
    error Ownable_SenderIsNotOwner(address sender);

    /// @notice Thrown when the new owner is not a valid owner account.
    error Ownable_NewOwnerCannotBeAddressZero();

    // =========================
    // Main functions
    // =========================

    /// @notice Returns the address of the current owner.
    /// @return The address of the current owner.
    function owner() external view returns (address);

    /// @notice Leaves the contract without an owner. It will not be possible to call
    /// `onlyOwner` functions anymore.
    /// @dev Can only be called by the current owner.
    function renounceOwnership() external;

    /// @notice Transfers ownership of the contract to a new account (`newOwner`).
    /// @param newOwner The address of the new owner.
    /// @dev Can only be called by the current owner.
    function transferOwnership(address newOwner) external;
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