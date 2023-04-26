// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
pragma solidity 0.8.19;

/**
@title ISubscriptionManager
@dev The interface for the SubscriptionManager contract.
*/

interface ISubscriptionManager {
    error SubscriptionManager__Unclaimed();
    /**
    @dev Error emitted when an invalid argument is provided.
    */
    error SubscriptionManager__InvalidArgument();
    /**
    @dev Error emitted when the caller is not authorized to perform the action.
    @param caller The address of the unauthorized caller.
    */
    error SubscriptionManager__Unauthorized(address caller);

    struct FeeInfo {
        address recipient;
        uint96 amount;
    }

    struct Bonus {
        address recipient;
        uint256 bonus;
    }

    event Distributed(
        address indexed operator,
        uint256[] success,
        bytes[] results
    );

    event NewPayment(
        address indexed operator,
        address indexed from,
        address indexed to
    );

    event Claimed(address indexed operator, uint256[] success, bytes[] results);

    event NewFeeInfo(
        address indexed operator,
        FeeInfo indexed oldFeeInfo,
        FeeInfo indexed newFeeInfo
    );

    function setPayment(address payment_) external;

    function setFeeInfo(address recipient_, uint96 amount_) external;

    function claimFees(
        address[] calldata accounts_
    ) external returns (uint256[] memory success, bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Context} from "oz-custom/contracts/oz/utils/Context.sol";

import {IFundRecoverable} from "./interfaces/IFundRecoverable.sol";

import {ErrorHandler} from "oz-custom/contracts/libraries/ErrorHandler.sol";

abstract contract FundRecoverable is Context, IFundRecoverable {
    using ErrorHandler for bool;

    function recover(
        RecoverCallData[] calldata calldata_,
        bytes calldata data_
    ) external virtual {
        _beforeRecover(data_);
        _recover(calldata_);
    }

    function _beforeRecover(bytes memory) internal virtual;

    function _recover(RecoverCallData[] calldata calldata_) internal virtual {
        uint256 length = calldata_.length;
        bytes[] memory results = new bytes[](length);

        bool success;
        bytes memory returnOrRevertData;
        for (uint256 i; i < length; ) {
            (success, returnOrRevertData) = calldata_[i].target.call{
                value: calldata_[i].value
            }(calldata_[i].callData);

            success.handleRevertIfNotSuccess(returnOrRevertData);

            results[i] = returnOrRevertData;

            unchecked {
                ++i;
            }
        }

        emit Executed(_msgSender(), results);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFundRecoverable {
    struct RecoverCallData {
        address target;
        uint256 value;
        bytes callData;
    }

    event Executed(address indexed operator, bytes[] results);

    function recover(
        RecoverCallData[] calldata calldata_,
        bytes calldata data_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "oz-custom/contracts/oz/access/Ownable.sol";

import {FundRecoverable} from "./internal/FundRecoverable.sol";

import {IERC20} from "./utils/permit2/interfaces/IPermit2.sol";
import {ISubscriptionManager} from "./interfaces/ISubscriptionManager.sol";

contract SubscriptionManager is Ownable, FundRecoverable, ISubscriptionManager {
    FeeInfo public feeInfo;

    address public payment;

    constructor(
        address payment_,
        uint96 amount_,
        address recipient_
    ) payable Ownable() {
        _setPayment(_msgSender(), payment_);
        _setFeeInfo(recipient_, amount_, feeInfo);
    }

    function setPayment(address payment_) external onlyOwner {
        _setPayment(_msgSender(), payment_);
    }

    function setFeeInfo(address recipient_, uint96 amount_) external {
        FeeInfo memory _feeInfo = feeInfo;
        address sender = _msgSender();
        if (sender != _feeInfo.recipient)
            revert SubscriptionManager__Unauthorized(sender);

        _setFeeInfo(recipient_, amount_, _feeInfo);
    }

    function distributeBonuses(
        Bonus[] calldata bonuses
    )
        public
        onlyOwner
        returns (uint256[] memory success, bytes[] memory results)
    {
        uint256 length = bonuses.length;
        success = new uint256[](length);
        results = new bytes[](length);

        bytes memory callData = abi.encodeCall(
            IERC20.transfer,
            (address(0), 0)
        );
        address _payment = payment;

        bool ok;
        address recipient;
        uint256 bonus;

        for (uint256 i; i < length; ) {
            bonus = bonuses[i].bonus;
            recipient = bonuses[i].recipient;
            assembly {
                mstore(add(callData, 0x24), recipient)
                mstore(add(callData, 0x44), bonus)
            }

            (ok, results[i]) = _payment.call(callData);

            success[i] = ok ? 2 : 1;

            unchecked {
                ++i;
            }
        }

        IERC20(_payment).transfer(
            feeInfo.recipient,
            IERC20(_payment).balanceOf(address(this))
        );

        emit Distributed(_msgSender(), success, results);
    }

    function claimFees(
        address[] calldata accounts_
    )
        public
        onlyOwner
        returns (uint256[] memory success, bytes[] memory results)
    {
        uint256 length = accounts_.length;
        results = new bytes[](length);
        success = new uint256[](length);

        FeeInfo memory _feeInfo = feeInfo;

        bytes memory callData = abi.encodeCall(
            IERC20.transferFrom,
            (address(0), address(this), _feeInfo.amount)
        );

        address _payment = payment;
        bool ok;
        address account;
        for (uint256 i; i < length; ) {
            account = accounts_[i];

            assembly {
                mstore(add(callData, 0x24), account)
            }

            (ok, results[i]) = _payment.call(callData);

            success[i] = ok ? 2 : 1;

            unchecked {
                ++i;
            }
        }

        emit Claimed(_msgSender(), success, results);
    }

    function _setPayment(address sender_, address payment_) internal {
        emit NewPayment(sender_, payment, payment_);
        payment = payment_;
    }

    function _setFeeInfo(
        address recipient_,
        uint96 amount_,
        FeeInfo memory currentFeeInfo_
    ) internal {
        if (recipient_ == address(0))
            revert SubscriptionManager__InvalidArgument();

        FeeInfo memory _feeInfo = FeeInfo(recipient_, amount_);
        emit NewFeeInfo(_msgSender(), currentFeeInfo_, _feeInfo);

        feeInfo = _feeInfo;
    }

    function _beforeRecover(bytes memory) internal view override {
        _checkOwner(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IPermit2 {
    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }
    // Token and amount in a permit message.
    struct TokenPermissions {
        // Token to transfer.
        IERC20 token;
        // Amount to transfer.
        uint256 amount;
    }

    // The permit2 message.
    struct PermitTransferFrom {
        // Permitted token and amount.
        TokenPermissions permitted;
        // Unique identifier for this permit.
        uint256 nonce;
        // Expiration for this permit.
        uint256 deadline;
    }

    // Transfer details for permitTransferFrom().
    struct SignatureTransferDetails {
        // Recipient of tokens.
        address to;
        // Amount to transfer.
        uint256 requestedAmount;
    }

    // Consume a permit2 message and transfer tokens.
    function permitTransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(
        address,
        address,
        address
    ) external view returns (uint160, uint48, uint48);

    // @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(
        address from,
        address to,
        uint160 amount,
        address token
    ) external;

    // @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(
        address owner,
        PermitSingle memory permitSingle,
        bytes calldata signature
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Bytes32Address {
    function fromFirst20Bytes(
        bytes32 bytesValue
    ) internal pure returns (address addr) {
        assembly {
            addr := bytesValue
        }
    }

    function fillLast12Bytes(
        address addressValue
    ) internal pure returns (bytes32 value) {
        assembly {
            value := addressValue
        }
    }

    function fromFirst160Bits(
        uint256 uintValue
    ) internal pure returns (address addr) {
        assembly {
            addr := uintValue
        }
    }

    function fillLast96Bits(
        address addressValue
    ) internal pure returns (uint256 value) {
        assembly {
            value := addressValue
        }
    }

    function fromLast160Bits(
        uint256 uintValue
    ) internal pure returns (address addr) {
        assembly {
            addr := shr(0x60, uintValue)
        }
    }

    function fillFirst96Bits(
        address addressValue
    ) internal pure returns (uint256 value) {
        assembly {
            value := shl(0x60, addressValue)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error ErrorHandler__ExecutionFailed();

library ErrorHandler {
    function handleRevertIfNotSuccess(
        bool ok_,
        bytes memory revertData_
    ) internal pure {
        assembly {
            if iszero(ok_) {
                let revertLength := mload(revertData_)
                if iszero(iszero(revertLength)) {
                    // Start of revert data bytes. The 0x20 offset is always the same.
                    revert(add(revertData_, 0x20), revertLength)
                }

                //  revert ErrorHandler__ExecutionFailed()
                mstore(0x00, 0xa94eec76)
                revert(0x1c, 0x04)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.17;

import {Context} from "../utils/Context.sol";
import {Bytes32Address} from "../../libraries/Bytes32Address.sol";

interface IOwnable {
    error Ownable__Unauthorized();
    error Ownable__NonZeroAddress();

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address _owner);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context, IOwnable {
    using Bytes32Address for *;

    bytes32 private __owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner(_msgSender());
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() payable {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address _owner) {
        assembly {
            _owner := sload(__owner.slot)
        }
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner(address sender_) internal view virtual {
        if (__owner != sender_.fillLast12Bytes())
            revert Ownable__Unauthorized();
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Ownable__Unauthorized();
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        assembly {
            log3(
                0x00,
                0x00,
                /// @dev value is equal to kecak256("OwnershipTransferred(address,address)");
                0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0,
                sload(__owner.slot),
                newOwner
            )
            sstore(__owner.slot, newOwner)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.17;

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
    function _msgSender() internal view virtual returns (address sender) {
        assembly {
            sender := caller()
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}