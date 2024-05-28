// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Contracts
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

// Interfaces
import { IAugustusFeeVault } from "../interfaces/IAugustusFeeVault.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

// Libraries
import { ERC20Utils } from "../libraries/ERC20Utils.sol";

/// @title Augstus Fee Vault
/// @notice Allows partners to collect fees stored in the vault, and allows augustus contracts to register fees
contract AugustusFeeVault is IAugustusFeeVault, Ownable, Pausable {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ERC20Utils for IERC20;

    /*//////////////////////////////////////////////////////////////
                                VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev A mapping of augustus contract addresses to their approval status
    mapping(address augustus => bool approved) public augustusContracts;

    // @dev Mapping of fee tokens to stored fee amounts
    mapping(address account => mapping(IERC20 token => uint256 amount)) public fees;

    // @dev Mapping of fee tokens to allocated fee amounts
    mapping(IERC20 token => uint256 amount) public allocatedFees;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address[] memory _augustusContracts, address owner) Ownable(owner) {
        // Set augustus verifier contracts
        for (uint256 i = 0; i < _augustusContracts.length; i++) {
            augustusContracts[_augustusContracts[i]] = true;
            emit AugustusApprovalSet(_augustusContracts[i], true);
        }
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Modifier to check if the caller is an approved augustus contract
    modifier onlyApprovedAugustus() {
        if (!augustusContracts[msg.sender]) {
            revert UnauthorizedCaller();
        }
        _;
    }

    /// @dev Verifies that the withdraw amount is not zero
    modifier validAmount(uint256 amount) {
        // Check if amount is zero
        if (amount == 0) {
            revert InvalidWithdrawAmount();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAugustusFeeVault
    function withdrawSomeERC20(
        IERC20 token,
        uint256 amount,
        address recipient
    )
        public
        validAmount(amount)
        whenNotPaused
        returns (bool success)
    {
        /// Check recipient
        recipient = _checkRecipient(recipient);

        // Update fees mapping
        _updateFees(token, msg.sender, amount);

        // Transfer tokens to recipient
        token.safeTransfer(recipient, amount);

        // Return success
        return true;
    }

    /// @inheritdoc IAugustusFeeVault
    function getUnallocatedFees(IERC20 token) public view returns (uint256 unallocatedFees) {
        // Get the allocated fees for the given token
        uint256 allocatedFee = allocatedFees[token];

        // Get the balance of the given token
        uint256 balance = token.getBalance(address(this));

        // If the balance is bigger than the allocated fee, then the unallocated fees should
        // be equal to the balance minus the allocated fee
        if (balance > allocatedFee) {
            // Set the unallocated fees to the balance minus the allocated fee
            unallocatedFees = balance - allocatedFee;
        }
    }

    /*///////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAugustusFeeVault
    function batchWithdrawSomeERC20(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    )
        external
        whenNotPaused
        returns (bool success)
    {
        // Check if the length of the tokens and amounts arrays are the same
        if (tokens.length != amounts.length) {
            revert InvalidParameterLength();
        }

        // Loop through the tokens and amounts arrays
        for (uint256 i; i < tokens.length; ++i) {
            // Collect fees for the given token
            if (!withdrawSomeERC20(tokens[i], amounts[i], recipient)) {
                // Revert if collect fails
                revert BatchCollectFailed();
            }
        }

        // Return success
        return true;
    }

    /// @inheritdoc IAugustusFeeVault
    function withdrawAllERC20(IERC20 token, address recipient) public whenNotPaused returns (bool success) {
        // Check recipient
        recipient = _checkRecipient(recipient);

        // Get the total fees for msg.sender in the given token
        uint256 totalBalance = fees[msg.sender][token];

        // Make sure the amount is not zero
        if (totalBalance == 0) {
            revert InvalidWithdrawAmount();
        }

        // Update fees mapping
        _updateFees(token, msg.sender, totalBalance);

        // Transfer tokens to recipient
        token.safeTransfer(recipient, totalBalance);

        // Return success
        return true;
    }

    /// @inheritdoc IAugustusFeeVault
    function batchWithdrawAllERC20(
        IERC20[] calldata tokens,
        address recipient
    )
        external
        whenNotPaused
        returns (bool success)
    {
        // Loop through the tokens array
        for (uint256 i; i < tokens.length; ++i) {
            // Collect all fees for the given token
            if (!withdrawAllERC20(tokens[i], recipient)) {
                // Revert if withdrawAllERC20 fails
                revert BatchCollectFailed();
            }
        }

        // Return success
        return true;
    }

    /// @inheritdoc IAugustusFeeVault
    function registerFees(FeeRegistration memory feeData) external onlyApprovedAugustus {
        // Get the addresses, tokens, and feeAmounts from the feeData struct
        address[] memory addresses = feeData.addresses;
        IERC20 token = feeData.token;
        uint256[] memory feeAmounts = feeData.fees;

        // Make sure the length of the addresses and feeAmounts arrays are the same
        if (addresses.length != feeAmounts.length) {
            revert InvalidParameterLength();
        }

        // Loop through the addresses and fees arrays
        for (uint256 i; i < addresses.length; ++i) {
            // Register the fees for the given address and token if the fee and address are not zero
            if (feeAmounts[i] != 0 && addresses[i] != address(0)) {
                _registerFee(addresses[i], token, feeAmounts[i]);
            }
        }
    }

    /// @inheritdoc IAugustusFeeVault
    function setAugustusApproval(address augustus, bool approved) external onlyOwner {
        // Set the approval status for the given augustus contract
        augustusContracts[augustus] = approved;
        // Emit an event
        emit AugustusApprovalSet(augustus, approved);
    }

    /// @inheritdoc IAugustusFeeVault
    function setContractPauseState(bool _isPaused) external onlyOwner {
        // Set the pause state
        if (_isPaused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @inheritdoc IAugustusFeeVault
    function getBalance(IERC20 token, address partner) external view returns (uint256 feeBalance) {
        // Get the fees for the given token and partner
        return fees[partner][token];
    }

    /// @inheritdoc IAugustusFeeVault
    function batchGetBalance(
        IERC20[] calldata tokens,
        address partner
    )
        external
        view
        returns (uint256[] memory feeBalances)
    {
        // Initialize the feeBalances array
        feeBalances = new uint256[](tokens.length);

        // Loop through the tokens array
        for (uint256 i; i < tokens.length; ++i) {
            // Get the fees for the given token and partner
            feeBalances[i] = fees[partner][tokens[i]];
        }
    }

    /*//////////////////////////////////////////////////////////////
                                PRIVATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Register fees for a given account and token
    /// @param account The account to register the fees for
    /// @param token The token to register the fees for
    /// @param fee The amount of fees to register
    function _registerFee(address account, IERC20 token, uint256 fee) private {
        // Get the unallocated fees for the given token
        uint256 unallocatedFees = getUnallocatedFees(token);

        // Make sure the fee is not bigger than the unallocated fees
        if (fee > unallocatedFees) {
            // If it is, set the fee to the unallocated fees
            fee = unallocatedFees;
        }

        // Update the fees mapping
        fees[account][token] += fee;

        // Update the allocated fees mapping
        allocatedFees[token] += fee;
    }

    /// @notice Update fees and allocatedFees for a given token and claimer
    /// @param token The token to update the fees for
    /// @param claimer The address to withdraw the fees for
    /// @param withdrawAmount The amount of fees to withdraw
    function _updateFees(IERC20 token, address claimer, uint256 withdrawAmount) private {
        // get the fees for the claimer
        uint256 feesForClaimer = fees[claimer][token];

        // revert if withdraw amount is bigger than the fees for the claimer
        if (withdrawAmount > feesForClaimer) {
            revert InvalidWithdrawAmount();
        }

        // update the allocated fees
        allocatedFees[token] -= withdrawAmount;

        // update the fees for the claimer
        fees[claimer][token] -= withdrawAmount;
    }

    /// @notice Check if recipient is zero address and set it to msg sender if it is, otherwise return recipient
    /// @param recipient The recipient address
    /// @return recipient The updated recipient address
    function _checkRecipient(address recipient) private view returns (address) {
        // Allow arbitrary recipient unless it is zero address
        if (recipient == address(0)) {
            recipient = msg.sender;
        }

        // Return recipient
        return recipient;
    }

    /*//////////////////////////////////////////////////////////////
                                RECEIVE
    //////////////////////////////////////////////////////////////*/

    /// @notice Reverts if the caller is one of the following:
    //         - an externally-owned account
    //         - a contract in construction
    //         - an address where a contract will be created
    //         - an address where a contract lived, but was destroyed
    receive() external payable {
        address addr = msg.sender;
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

/// @title IAugustusFeeVault
/// @notice Interface for the AugustusFeeVault contract
interface IAugustusFeeVault {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Error emitted when withdraw amount is zero or exceeds the stored amount
    error InvalidWithdrawAmount();

    /// @notice Error emmitted when caller is not an approved augustus contract
    error UnauthorizedCaller();

    /// @notice Error emitted when an invalid parameter length is passed
    error InvalidParameterLength();

    /// @notice Error emitted when batch withdraw fails
    error BatchCollectFailed();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an augustus contract approval status is set
    /// @param augustus The augustus contract address
    /// @param approved The approval status
    event AugustusApprovalSet(address indexed augustus, bool approved);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct to register fees
    /// @param addresses The addresses to register fees for
    /// @param token The token to register fees for
    /// @param fees The fees to register
    struct FeeRegistration {
        address[] addresses;
        IERC20 token;
        uint256[] fees;
    }

    /*//////////////////////////////////////////////////////////////
                                COLLECT
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows partners to withdraw fees allocated to them and stored in the vault
    /// @param token The token to withdraw fees in
    /// @param amount The amount of fees to withdraw
    /// @param recipient The address to send the fees to
    /// @return success Whether the transfer was successful or not
    function withdrawSomeERC20(IERC20 token, uint256 amount, address recipient) external returns (bool success);

    /// @notice Allows partners to withdraw all fees allocated to them and stored in the vault for a given token
    /// @param token The token to withdraw fees in
    /// @param recipient The address to send the fees to
    /// @return success Whether the transfer was successful or not
    function withdrawAllERC20(IERC20 token, address recipient) external returns (bool success);

    /// @notice Allows partners to withdraw all fees allocated to them and stored in the vault for multiple tokens
    /// @param tokens The tokens to withdraw fees i
    /// @param recipient The address to send the fees to
    /// @return success Whether the transfer was successful or not
    function batchWithdrawAllERC20(IERC20[] calldata tokens, address recipient) external returns (bool success);

    /// @notice Allows partners to withdraw fees allocated to them and stored in the vault
    /// @param tokens The tokens to withdraw fees in
    /// @param amounts The amounts of fees to withdraw
    /// @param recipient The address to send the fees to
    /// @return success Whether the transfer was successful or not
    function batchWithdrawSomeERC20(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    )
        external
        returns (bool success);

    /*//////////////////////////////////////////////////////////////
                            BALANCE GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the balance of a given token for a given partner
    /// @param token The token to get the balance of
    /// @param partner The partner to get the balance for
    /// @return feeBalance The balance of the given token for the given partner
    function getBalance(IERC20 token, address partner) external view returns (uint256 feeBalance);

    /// @notice Get the balances of a given partner for multiple tokens
    /// @param tokens The tokens to get the balances of
    /// @param partner The partner to get the balances for
    /// @return feeBalances The balances of the given tokens for the given partner
    function batchGetBalance(
        IERC20[] calldata tokens,
        address partner
    )
        external
        view
        returns (uint256[] memory feeBalances);

    /// @notice Returns the unallocated fees for a given token
    /// @param token The token to get the unallocated fees for
    /// @return unallocatedFees The unallocated fees for the given token
    function getUnallocatedFees(IERC20 token) external view returns (uint256 unallocatedFees);

    /*//////////////////////////////////////////////////////////////
                                 OWNER
    //////////////////////////////////////////////////////////////*/

    /// @notice Registers the given feeData to the vault
    /// @param feeData The fee registration data
    function registerFees(FeeRegistration memory feeData) external;

    /// @notice Sets the augustus contract approval status
    /// @param augustus The augustus contract address
    /// @param approved The approval status
    function setAugustusApproval(address augustus, bool approved) external;

    /// @notice Sets the contract pause state
    /// @param _isPaused The new pause state
    function setContractPauseState(bool _isPaused) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

/// @title ERC20Utils
/// @notice Optimized functions for ERC20 tokens
library ERC20Utils {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error IncorrectEthAmount();
    error PermitFailed();
    error TransferFromFailed();
    error TransferFailed();
    error ApprovalFailed();

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    IERC20 internal constant ETH = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /*//////////////////////////////////////////////////////////////
                                APPROVE
    //////////////////////////////////////////////////////////////*/

    /// @dev Vendored from Solady by @vectorized - SafeTransferLib.approveWithRetry
    /// https://github.com/Vectorized/solady/src/utils/SafeTransferLib.sol#L325
    /// Instead of approving a specific amount, this function approves for uint256(-1) (type(uint256).max).
    function approve(IERC20 token, address to) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) // Store the `amount`
                // argument (type(uint256).max).
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, retrying upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
                pop(call(gas(), token, 0, 0x10, 0x44, codesize(), 0x00)) // Reset the approval.
                mstore(0x34, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) // Store
                    // type(uint256).max for the `amount`.
                // Retry the approval, reverting upon failure.
                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0, 0x8164f84200000000000000000000000000000000000000000000000000000000)
                    // store the selector (error ApprovalFailed())
                    revert(0, 4) // revert with error selector
                }
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /*//////////////////////////////////////////////////////////////
                                PERMIT
    //////////////////////////////////////////////////////////////*/

    /// @dev Executes an ERC20 permit and reverts if invalid length is provided
    function permit(IERC20 token, bytes calldata data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // check the permit length
            switch data.length
            // 32 * 7 = 224 EIP2612 Permit
            case 224 {
                let x := mload(64) // get the free memory pointer
                mstore(x, 0xd505accf00000000000000000000000000000000000000000000000000000000) // store the selector
                    // function permit(address owner, address spender, uint256
                    // amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
                calldatacopy(add(x, 4), data.offset, 224) // store the args
                pop(call(gas(), token, 0, x, 228, 0, 32)) // call ERC20 permit, skip checking return data
            }
            // 32 * 8 = 256 DAI-Style Permit
            case 256 {
                let x := mload(64) // get the free memory pointer
                mstore(x, 0x8fcbaf0c00000000000000000000000000000000000000000000000000000000) // store the selector
                    // function permit(address holder, address spender, uint256
                    // nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s)
                calldatacopy(add(x, 4), data.offset, 256) // store the args
                pop(call(gas(), token, 0, x, 260, 0, 32)) // call ERC20 permit, skip checking return data
            }
            default {
                mstore(0, 0xb78cb0dd00000000000000000000000000000000000000000000000000000000) // store the selector
                    // (error PermitFailed())
                revert(0, 4)
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 ETH
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns 1 if the token is ETH, 0 if not ETH
    function isETH(IERC20 token, uint256 amount) internal view returns (uint256 fromETH) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // If token is ETH
            if eq(token, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                // if msg.value is not equal to fromAmount, then revert
                if xor(amount, callvalue()) {
                    mstore(0, 0x8b6ebb4d00000000000000000000000000000000000000000000000000000000) // store the selector
                        // (error IncorrectEthAmount())
                    revert(0, 4) // revert with error selector
                }
                // return 1 if ETH
                fromETH := 1
            }
            // If token is not ETH
            if xor(token, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                // if msg.value is not equal to 0, then revert
                if gt(callvalue(), 0) {
                    mstore(0, 0x8b6ebb4d00000000000000000000000000000000000000000000000000000000) // store the selector
                    // (error IncorrectEthAmount())
                    revert(0, 4) // revert with error selector
                }
            }
        }
        // return 0 if not ETH
    }

    /*//////////////////////////////////////////////////////////////
                                TRANSFER
    //////////////////////////////////////////////////////////////*/

    /// @dev Executes transfer and reverts if it fails, works for both ETH and ERC20 transfers
    function safeTransfer(IERC20 token, address recipient, uint256 amount) internal returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            switch eq(token, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            // ETH
            case 1 {
                // transfer ETH
                // Cap gas at 10000 to avoid reentrancy
                success := call(10000, recipient, amount, 0, 0, 0, 0)
            }
            // ERC20
            default {
                let x := mload(64) // get the free memory pointer
                mstore(x, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // store the selector
                    // (function transfer(address recipient, uint256 amount))
                mstore(add(x, 4), recipient) // store the recipient
                mstore(add(x, 36), amount) // store the amount
                success := call(gas(), token, 0, x, 68, 0, 32) // call transfer
                if success {
                    switch returndatasize()
                    // check the return data size
                    case 0 { success := gt(extcodesize(token), 0) }
                    default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
                }
            }
            if iszero(success) {
                mstore(0, 0x90b8ec1800000000000000000000000000000000000000000000000000000000) // store the selector
                    // (error TransferFailed())
                revert(0, 4) // revert with error selector
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                             TRANSFER FROM
    //////////////////////////////////////////////////////////////*/

    /// @dev Executes transferFrom and reverts if it fails
    function safeTransferFrom(
        IERC20 srcToken,
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        returns (bool success)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let x := mload(64) // get the free memory pointer
            mstore(x, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // store the selector
                // (function transferFrom(address sender, address recipient,
                // uint256 amount))
            mstore(add(x, 4), sender) // store the sender
            mstore(add(x, 36), recipient) // store the recipient
            mstore(add(x, 68), amount) // store the amount
            success := call(gas(), srcToken, 0, x, 100, 0, 32) // call transferFrom
            if success {
                switch returndatasize()
                // check the return data size
                case 0 { success := gt(extcodesize(srcToken), 0) }
                default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
            if iszero(success) {
                mstore(x, 0x7939f42400000000000000000000000000000000000000000000000000000000) // store the selector
                    // (error TransferFromFailed())
                revert(x, 4) // revert with error selector
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                BALANCE
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the balance of an account, works for both ETH and ERC20 tokens
    function getBalance(IERC20 token, address account) internal view returns (uint256 balanceOf) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            switch eq(token, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            // ETH
            case 1 { balanceOf := balance(account) }
            // ERC20
            default {
                let x := mload(64) // get the free memory pointer
                mstore(x, 0x70a0823100000000000000000000000000000000000000000000000000000000) // store the selector
                    // (function balanceOf(address account))
                mstore(add(x, 4), account) // store the account
                let success := staticcall(gas(), token, x, 36, x, 32) // call balanceOf
                if success { balanceOf := mload(x) } // load the balance
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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