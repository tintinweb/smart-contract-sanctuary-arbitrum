/**
 *Submitted for verification at Arbiscan.io on 2024-05-08
*/

// Sources flattened with hardhat v2.22.2 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @ironblocks/firewall-consumer/contracts/interfaces/[email protected]


// See LICENSE file for full license text.
// Copyright (c) Ironblocks 2024
pragma solidity ^0.8;

interface IFirewall {
    function preExecution(address sender, bytes memory data, uint value) external;
    function postExecution(address sender, bytes memory data, uint value) external;
    function preExecutionPrivateInvariants(address sender, bytes memory data, uint value) external returns (bytes32[] calldata);
    function postExecutionPrivateInvariants(
        address sender,
        bytes memory data,
        uint value,
        bytes32[] calldata preValues,
        bytes32[] calldata postValues
    ) external;
}


// File @ironblocks/firewall-consumer/contracts/interfaces/[email protected]


// See LICENSE file for full license text.
// Copyright (c) Ironblocks 2024
pragma solidity ^0.8;

interface IFirewallConsumer {
    function firewallAdmin() external returns (address);
}


// File @openzeppelin/contracts/utils/[email protected]

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/utils/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}


// File @ironblocks/firewall-consumer/contracts/[email protected]


// See LICENSE file for full license text.
// Copyright (c) Ironblocks 2024
pragma solidity ^0.8;




/**
 * @title Firewall Consumer Base Contract
 * @author David Benchimol @ Ironblocks 
 * @dev This contract is a parent contract that can be used to add firewall protection to any contract.
 *
 * The contract must define a firewall contract which will manage the policies that are applied to the contract.
 * It also must define a firewall admin which will be able to add and remove policies.
 *
 */
contract FirewallConsumerBase is IFirewallConsumer, Context {

    bytes32 private constant FIREWALL_STORAGE_SLOT = bytes32(uint256(keccak256("eip1967.firewall")) - 1);
    bytes32 private constant FIREWALL_ADMIN_STORAGE_SLOT = bytes32(uint256(keccak256("eip1967.firewall.admin")) - 1);
    bytes32 private constant NEW_FIREWALL_ADMIN_STORAGE_SLOT = bytes32(uint256(keccak256("eip1967.new.firewall.admin")) - 1);

    // This slot is special since it's used for mappings and not a single value
    bytes32 private constant APPROVED_TARGETS_MAPPING_SLOT = bytes32(uint256(keccak256("eip1967.approved.targets")) - 1);

    /**
     * @dev modifier that will run the preExecution and postExecution hooks of the firewall, applying each of
     * the subscribed policies.
     */
    modifier firewallProtected() {
        address firewall = _getAddressBySlot(FIREWALL_STORAGE_SLOT);
        if (firewall == address(0)) {
            _;
            return;
        }
        uint value = _msgValue();
        IFirewall(firewall).preExecution(msg.sender, msg.data, value);
        _; 
        IFirewall(firewall).postExecution(msg.sender, msg.data, value);
    }

    /**
     * @dev modifier that will run the preExecution and postExecution hooks of the firewall, applying each of
     * the subscribed policies. Allows passing custom data to the firewall, not necessarily msg.data.
     * Useful for checking internal function calls
     */
    modifier firewallProtectedCustom(bytes memory data) {
        address firewall = _getAddressBySlot(FIREWALL_STORAGE_SLOT);
        if (firewall == address(0)) {
            _;
            return;
        }
        uint value = _msgValue();
        IFirewall(firewall).preExecution(msg.sender, data, value);
        _; 
        IFirewall(firewall).postExecution(msg.sender, data, value);
    }

    /**
     * @dev identical to the rest of the modifiers in terms of logic, but makes it more
     * aesthetic when all you want to pass are signatures/unique identifiers.
     */
    modifier firewallProtectedSig(bytes4 selector) {
        address firewall = _getAddressBySlot(FIREWALL_STORAGE_SLOT);
        if (firewall == address(0)) {
            _;
            return;
        }
        uint value = _msgValue();
        IFirewall(firewall).preExecution(msg.sender, abi.encodePacked(selector), value);
        _; 
        IFirewall(firewall).postExecution(msg.sender, abi.encodePacked(selector), value);
    }

    /**
     * @dev modifier that will run the preExecution and postExecution hooks of the firewall invariant policy,
     * applying the subscribed invariant policy
     */
    modifier invariantProtected() {
        address firewall = _getAddressBySlot(FIREWALL_STORAGE_SLOT);
        if (firewall == address(0)) {
            _;
            return;
        }
        uint value = _msgValue();
        bytes32[] memory storageSlots = IFirewall(firewall).preExecutionPrivateInvariants(msg.sender, msg.data, value);
        bytes32[] memory preValues = _readStorage(storageSlots);
        _; 
        bytes32[] memory postValues = _readStorage(storageSlots);
        IFirewall(firewall).postExecutionPrivateInvariants(msg.sender, msg.data, value, preValues, postValues);
    }


    /**
     * @dev modifier asserting that the target is approved
     */
    modifier onlyApprovedTarget(address target) {
        // We use the same logic that solidity uses for mapping locations, but we add a pseudorandom 
        // constant "salt" instead of a constant placeholder so that there are no storage collisions
        // if adding this to an upgradeable contract implementation
        bytes32 _slot = keccak256(abi.encode(APPROVED_TARGETS_MAPPING_SLOT, target));
        bool isApprovedTarget = _getValueBySlot(_slot) != bytes32(0);
        require(isApprovedTarget, "FirewallConsumer: Not approved target");
        _;
    }

    /**
     * @dev modifier similar to onlyOwner, but for the firewall admin.
     */
    modifier onlyFirewallAdmin() {
        require(msg.sender == _getAddressBySlot(FIREWALL_ADMIN_STORAGE_SLOT), "FirewallConsumer: not firewall admin");
        _;
    }

    /**
     * @dev Initializes a contract protected by a firewall, with a firewall address and a firewall admin.
     *
     * IMPORTENT: need to add _setAddressBySlot(FIREWALL_ADMIN_STORAGE_SLOT, _firewallAdmin); in the initializer for upgradable contracts
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address _firewall,
        address _firewallAdmin
    ) {
        _setAddressBySlot(FIREWALL_STORAGE_SLOT, _firewall);
        _setAddressBySlot(FIREWALL_ADMIN_STORAGE_SLOT, _firewallAdmin);
    }

    /**
     * @dev Allows calling an approved external target before executing a method.
     * 
     * This can be used for multiple purposes, but the initial one is to call `approveCallsViaSignature` before
     * executing a function, allowing synchronous transaction approvals.
     */
    function safeFunctionCall(
        address target,
        bytes calldata targetPayload,
        bytes calldata data
    ) external payable onlyApprovedTarget(target) {
        (bool success, ) = target.call(targetPayload);
        require(success);
        require(msg.sender == _msgSender(), "FirewallConsumer: No meta transactions");
        Address.functionDelegateCall(address(this), data);
    }

    /**
     * @dev Allows firewall admin to set approved targets.
     * IMPORTANT: Only set approved target if you know what you're doing. Anyone can cause this contract
     * to send any data to an approved target.
     */
    function setApprovedTarget(address target, bool status) external onlyFirewallAdmin {
        bytes32 _slot = keccak256(abi.encode(APPROVED_TARGETS_MAPPING_SLOT, target));
        assembly {
            sstore(_slot, status)
        }
    }

    /**
     * @dev View function for the firewall admin
     */
    function firewallAdmin() external view returns (address) {
        return _getAddressBySlot(FIREWALL_ADMIN_STORAGE_SLOT);
    }

    /**
     * @dev Admin only function allowing the consumers admin to set the firewall address.
     */
    function setFirewall(address _firewall) external onlyFirewallAdmin {
        _setAddressBySlot(FIREWALL_STORAGE_SLOT, _firewall);
    }

    /**
     * @dev Admin only function, sets new firewall admin. New admin must accept.
     */
    function setFirewallAdmin(address _firewallAdmin) external onlyFirewallAdmin {
        require(_firewallAdmin != address(0), "FirewallConsumer: zero address");
        _setAddressBySlot(NEW_FIREWALL_ADMIN_STORAGE_SLOT, _firewallAdmin);
    }

    /**
     * @dev Accept the role as firewall admin.
     */
    function acceptFirewallAdmin() external {
        require(msg.sender == _getAddressBySlot(NEW_FIREWALL_ADMIN_STORAGE_SLOT), "FirewallConsumer: not new admin");
        _setAddressBySlot(FIREWALL_ADMIN_STORAGE_SLOT, msg.sender);
    }

    function _msgValue() internal view returns (uint value) {
        // We do this because msg.value can only be accessed in payable functions.
        assembly {
            value := callvalue()
        }
    }

    function _readStorage(bytes32[] memory storageSlots) internal view returns (bytes32[] memory) {
        uint256 slotsLength = storageSlots.length;
        bytes32[] memory values = new bytes32[](slotsLength);

        for (uint256 i = 0; i < slotsLength; i++) {
            bytes32 slotValue = _getValueBySlot(storageSlots[i]);
            values[i] = slotValue;
        }
        return values;
    }

    function _setAddressBySlot(bytes32 _slot, address _address) internal {
        assembly {
            sstore(_slot, _address)
        }
    }

    function _getAddressBySlot(bytes32 _slot) internal view returns (address _address) {
        assembly {
            _address := sload(_slot)
        }
    }

    function _getValueBySlot(bytes32 _slot) internal view returns (bytes32 _value) {
        assembly {
            _value := sload(_slot)
        }
    }
}


// File @ironblocks/firewall-consumer/contracts/[email protected]


// See LICENSE file for full license text.
// Copyright (c) Ironblocks 2024
pragma solidity ^0.8;

/**
 * @title Firewall Consumer
 * @author David Benchimol @ Ironblocks 
 * @dev This contract is a parent contract that can be used to add firewall protection to any contract.
 *
 * The contract must initializes with the firewall contract disabled, and the deployer
 * as the firewall admin.
 *
 */
contract FirewallConsumer is FirewallConsumerBase(address(0), msg.sender) {
}


// File @openzeppelin/contracts/access/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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


// File @openzeppelin/contracts/security/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

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
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

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
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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


// File @poolzfinance/poolz-helper-v2/contracts/[email protected]

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.0;


contract ERC20Helper is FirewallConsumer {
    event TransferOut(uint256 Amount, address To, address Token);
    event TransferIn(uint256 Amount, address From, address Token);
    modifier TestAllowance(
        address _token,
        address _owner,
        uint256 _amount
    ) {
        require(
            ERC20(_token).allowance(_owner, address(this)) >= _amount,
            "ERC20Helper: no allowance"
        );
        _;
    }

    function TransferToken(
        address _Token,
        address _Reciver,
        uint256 _Amount
    ) internal firewallProtectedSig(0x3844b707) {
        uint256 OldBalance = ERC20(_Token).balanceOf(address(this));
        emit TransferOut(_Amount, _Reciver, _Token);
        ERC20(_Token).transfer(_Reciver, _Amount);
        require(
            (ERC20(_Token).balanceOf(address(this)) + _Amount) == OldBalance,
            "ERC20Helper: sent incorrect amount"
        );
    }

    function TransferInToken(
        address _Token,
        address _Subject,
        uint256 _Amount
    ) internal TestAllowance(_Token, _Subject, _Amount) {
        require(_Amount > 0);
        uint256 OldBalance = ERC20(_Token).balanceOf(address(this));
        ERC20(_Token).transferFrom(_Subject, address(this), _Amount);
        emit TransferIn(_Amount, _Subject, _Token);
        require(
            (OldBalance + _Amount) == ERC20(_Token).balanceOf(address(this)),
            "ERC20Helper: Received Incorrect Amount"
        );
    }

    function ApproveAllowanceERC20(
        address _Token,
        address _Subject,
        uint256 _Amount
    ) internal firewallProtectedSig(0x91251680) {
        require(_Amount > 0);
        ERC20(_Token).approve(_Subject, _Amount);
    }
}


// File @poolzfinance/poolz-helper-v2/contracts/[email protected]

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.0;


contract GovManager is Ownable, FirewallConsumer {
    event GovernorUpdated (
        address indexed oldGovernor,
        address indexed newGovernor
    );

    address public GovernorContract;

    modifier onlyOwnerOrGov() {
        require(
            msg.sender == owner() || msg.sender == GovernorContract,
            "Authorization Error"
        );
        _;
    }

    function setGovernorContract(address _address) external firewallProtected onlyOwnerOrGov {
        address oldGov = GovernorContract;
        GovernorContract = _address;
        emit GovernorUpdated(oldGov, GovernorContract);
    }

    constructor() {
        GovernorContract = address(0);
    }
}


// File @poolzfinance/poolz-helper-v2/contracts/interfaces/[email protected]

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.0;

//For whitelist, 
interface IWhiteList {
    function Check(address _Subject, uint256 _Id) external view returns(uint);
    function Register(address _Subject,uint256 _Id,uint256 _Amount) external;
    function LastRoundRegister(address _Subject,uint256 _Id) external;
    function CreateManualWhiteList(uint256 _ChangeUntil, address _Contract) external payable returns(uint256 Id);
    function ChangeCreator(uint256 _Id, address _NewCreator) external;
    function AddAddress(uint256 _Id, address[] calldata _Users, uint256[] calldata _Amount) external;
    function RemoveAddress(uint256 _Id, address[] calldata _Users) external;
}


// File @poolzfinance/poolz-helper-v2/contracts/Fee/[email protected]

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;


abstract contract WhiteListHelper is GovManager {
    error WhiteListNotSet();

    uint public WhiteListId;
    address public WhiteListAddress;

    modifier WhiteListSet {
        if(WhiteListAddress == address(0) || WhiteListId == 0) revert WhiteListNotSet();
        _;
    }

    function getCredits(address _user) public view returns(uint) {
        if(WhiteListAddress == address(0) || WhiteListId == 0) return 0;
        return IWhiteList(WhiteListAddress).Check(_user, WhiteListId);
    }

    function setupNewWhitelist(address _whiteListAddress) external firewallProtected onlyOwnerOrGov {
        WhiteListAddress = _whiteListAddress;
        WhiteListId = IWhiteList(_whiteListAddress).CreateManualWhiteList(type(uint256).max, address(this));
    }

    function addUsers(address[] calldata _users, uint256[] calldata _credits) external firewallProtected onlyOwnerOrGov WhiteListSet {        
        IWhiteList(WhiteListAddress).AddAddress(WhiteListId, _users, _credits);
    }

    function removeUsers(address[] calldata _users) external firewallProtected onlyOwnerOrGov WhiteListSet {
        IWhiteList(WhiteListAddress).RemoveAddress(WhiteListId, _users);
    }

    function _whiteListRegister(address _user, uint _credits) internal {
        IWhiteList(WhiteListAddress).Register(_user, WhiteListId, _credits);
    }
}


// File @poolzfinance/poolz-helper-v2/contracts/Fee/[email protected]

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;


abstract contract FeeBaseHelper is ERC20Helper, WhiteListHelper {
    event TransferInETH(uint Amount, address From);
    event NewFeeAmount(uint NewFeeAmount, uint OldFeeAmount);
    event NewFeeToken(address NewFeeToken, address OldFeeToken);

    error NotEnoughFeeProvided();
    error FeeAmountIsZero();
    error TransferFailed();

    uint public FeeAmount;
    address public FeeToken;
    
    mapping(address => uint) public FeeReserve;

    function TakeFee() internal virtual firewallProtected returns(uint feeToPay){
        feeToPay = FeeAmount;
        if(feeToPay == 0) return 0;
        uint credits = getCredits(msg.sender);
        if(credits > 0) {
            _whiteListRegister(msg.sender, credits < feeToPay ? credits : feeToPay);
            if(credits < feeToPay) {
                feeToPay -= credits;
            } else {
                return 0;
            }
        }
        _TakeFee(feeToPay);
    }

    function _TakeFee(uint _fee) private {
        address _feeToken = FeeToken;   // cache storage reads
        if (_feeToken == address(0)) {
            if (msg.value < _fee) revert NotEnoughFeeProvided();
            emit TransferInETH(msg.value, msg.sender);
        } else {
            TransferInToken(_feeToken, msg.sender, _fee);
        }
        FeeReserve[_feeToken] += _fee;
    }

    function setFee(address _token, uint _amount) external firewallProtected onlyOwnerOrGov {
        FeeToken = _token;
        FeeAmount = _amount;
    }

    function WithdrawFee(address _token, address _to) external firewallProtected onlyOwnerOrGov {
        if (FeeReserve[_token] == 0) revert FeeAmountIsZero();
        uint feeAmount = FeeReserve[_token];
        FeeReserve[_token] = 0;
        if (_token == address(0)) {
            (bool success, ) = _to.call{value: feeAmount}("");
            if (!success) revert TransferFailed();
        } else {
            TransferToken(_token, _to, feeAmount);
        }
    }
}


// File contracts/MultiManageable.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;



/// @title MultiManageable: An abstract contract for managing MultiSenderV2 with administrative controls
abstract contract MultiManageable is FeeBaseHelper, Pausable {
    event MultiTransferredERC20(
        address indexed token,
        uint256 indexed userCount,
        uint256 indexed totalAmount
    );

    event MultiTransferredETH(uint256 indexed userCount, uint256 indexed totalAmount);

    error ETHTransferFail(address user, uint amount);
    error ArrayZeroLength();
    error NoZeroAddress();
    error TotalMismatch(uint amountProvided, uint amountRequired);

    struct MultiSendData {
        address user;
        uint amount;
    }

    /// @notice Ensures token is not paused and the address is not zero before proceeding
    /// @dev Modifier that calls `_baseStartUp` with token address checks
    modifier erc20FullCheck(address _token) {
        _baseStartUp(_token);
        _;
    }


    /// @notice Starts base operations, checks for paused state and zero address, and takes fee
    /// @dev Private function called by the `erc20FullCheck` modifier
    function _baseStartUp(address _token) private whenNotPaused {
        if (_token == address(0)) revert NoZeroAddress();
        TakeFee();
    }

    /// @notice Checks if a number is not zero, returns the same number if true
    /// @dev Internal pure function for validating non-zero values
    function _notZero(
        uint256 _number
    ) internal pure returns (uint256 _sameNumber) {
        if (_number == 0) revert ArrayZeroLength();
        return _number;
    }

    /// @notice Validates that the value after fee deduction matches the expected value
    /// @dev Takes a fee and compares the provided value with transaction value minus the fee
    function _validateValueAfterFee(uint _value) internal {
        uint feeTaken = TakeFee();
        _validateEqual(_value, msg.value - feeTaken);
    }

    /// @notice Validates that two values are equal, reverts if not
    /// @dev Internal pure function for value comparison
    function _validateEqual(uint _value, uint _value2) internal pure {
        if (_value != _value2) revert TotalMismatch(_value2, _value);
    }

    /// @notice Transfers ETH based on `MultiSendData`
    /// @dev Wraps `_sendETH` call to provide value return
    function _sendETH(
        MultiSendData calldata _multiSendData
    ) internal returns (uint value) {
        _sendETH(_multiSendData.user, _multiSendData.amount);
        return _multiSendData.amount;
    }

    /// @notice Calls ERC20 `transferFrom` to collect tokens before distribution
    /// @dev Allows contract to collect the specified amount of ERC20 tokens from the sender
    function _getERC20(address _token, uint _amount) internal {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    /// @notice Transfers ERC20 tokens based on `MultiSendData`
    /// @dev Wraps `_sendERC20` call to provide value return
    function _sendERC20(
        address _token,
        MultiSendData calldata _multiSendData
    ) internal returns (uint value) {
        _sendERC20(_token, _multiSendData.user, _multiSendData.amount);
        return _multiSendData.amount;
    }

    /// @notice Directly transfers ERC20 tokens to a user
    /// @dev Uses ERC20 `transfer` to send specified amount to user
    function _sendERC20(address _token, address _user, uint _amount) internal {
        IERC20(_token).transfer(_user, _amount);
    }

    /// @notice Transfers ERC20 tokens from sender to recipient based on `MultiSendData`
    /// @dev Wraps `_sendERC20From` call for direct use in other functions
    function _sendERC20From(
        address _token,
        MultiSendData calldata _multiSendData
    ) internal returns (uint value) {
        _sendERC20From(_token, _multiSendData.user, _multiSendData.amount);
        return _multiSendData.amount;
    }

    /// @notice Allows contract to transfer ERC20 tokens from sender to a specified recipient
    /// @dev Uses ERC20 `transferFrom` for token distribution
    function _sendERC20From(
        address _token,
        address _to,
        uint _amount
    ) internal {
        IERC20(_token).transferFrom(msg.sender, _to, _amount);
    }

    /// @notice Sends ETH to a specified address, reverts on failure
    /// @dev Performs a low-level call to transfer ETH and handle failure
    function _sendETH(address _user, uint _amount) internal {
        (bool success, ) = _user.call{value: _amount}("");
        if (!success) revert ETHTransferFail(_user, _amount);
    }

    /// @notice Pauses the contract, disabling certain functions
    /// @dev Only callable by the owner or governance, wraps OpenZeppelin's `_pause`
    function Pause() external onlyOwnerOrGov {
        _pause();
    }

    /// @notice Unpauses the contract, re-enabling certain functions
    /// @dev Only callable by the owner or governance, wraps OpenZeppelin's `_unpause`
    function Unpause() external onlyOwnerOrGov {
        _unpause();
    }
}


// File contracts/MultiSenderETH.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

/// @title Main multi transfer settings contract
/// @dev Extends `MultiManageable` to enable multi-sending of ETH with various utilities.
/// @author The-Poolz contract team
contract MultiSenderETH is MultiManageable {

    /// @notice Sends ETH to multiple addresses with different amounts.
    /// @dev Iterates over the `_multiSendData` array, sending ETH to each specified address.
    /// Requires the contract not to be paused.
    /// @param _multiSendData An array of `MultiSendData` structs, each containing an address and the amount of ETH to send.
    /// @return sum The total amount of ETH sent.
    function MultiSendETH(
        MultiSendData[] calldata _multiSendData
    ) external payable whenNotPaused returns (uint256 sum) {
        uint length = _notZero(_multiSendData.length);
        for (uint256 i; i < length; ) {
            MultiSendData calldata data = _multiSendData[i];
            sum += _sendETH(data);
            unchecked {
                ++i;
            }
        }
        _validateValueAfterFee(sum);
        emit MultiTransferredETH(length, sum);
    }

    /// @notice Sends the same amount of ETH to multiple addresses.
    /// @dev Iterates over the `_users` array, sending the specified `_amount` of ETH to each.
    /// Requires the contract not to be paused.
    /// @param _users An array of addresses to receive ETH.
    /// @param _amount The amount of ETH to send to each address.
    function MultiSendETHSameValue(
        address[] calldata _users,
        uint _amount
    ) external payable whenNotPaused {
        uint length = _notZero(_users.length);
        _validateValueAfterFee(_amount * length);
        for (uint256 i; i < length; ) {
            address user = _users[i];
            _sendETH(user, _amount);
            unchecked {
                ++i;
            }
        }
        emit MultiTransferredETH(length, _amount * length);
    }
}


// File contracts/MultiSenderERC20Direct.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

/// @title A contract for batch sending ERC20 tokens directly to multiple addresses
/// @notice This contract extends MultiSenderETH to support direct ERC20 token transfers, where token are sent from the sender directly to recipients
/// @author The-Poolz contract team
contract MultiSenderERC20Direct is MultiSenderETH {
    
    /// @notice Sends specified amounts of an ERC20 token to multiple addresses
    /// @param _token The ERC20 token address to send
    /// @param _multiSendData An array of `MultiSendData` structs containing recipient addresses and amounts
    /// @return sum The total amount of tokens sent
    /// @dev Emits a `MultiTransferredERC20` event upon completion
    function MultiSendERC20Direct(
        address _token,
        MultiSendData[] calldata _multiSendData
    ) external payable erc20FullCheck(_token) returns (uint256 sum) {
        uint length = _notZero(_multiSendData.length);
        for (uint256 i; i < length; ) {
            MultiSendData calldata data = _multiSendData[i];
            sum += _sendERC20From(_token, data);
            unchecked {
                ++i;
            }
        }
        emit MultiTransferredERC20(_token, length, sum);
    }

    /// @notice Sends the same amount of an ERC20 token to multiple addresses
    /// @param _token The ERC20 token address to send
    /// @param _users An array of recipient addresses
    /// @param _amount The amount of tokens to send to each address
    /// @dev Emits a `MultiTransferredERC20` event upon completion with the total tokens sent
    function MultiSendERC20DirectSameValue(
        address _token,
        address[] calldata _users,
        uint _amount
    ) external payable erc20FullCheck(_token) {
        uint length = _notZero(_users.length);
        for (uint256 i; i < length; ) {
            address user = _users[i];
            _sendERC20From(_token, user, _amount);
            unchecked {
                ++i;
            }
        }
        emit MultiTransferredERC20(_token, length, _amount * length);
    }
}


// File contracts/MultiSender.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

/// @title A contract for batch sending ERC20 tokens indirectly to multiple addresses
/// @notice This contract extends MultiSenderERC20Direct to support indirect ERC20 token transfers, where tokens are first collected from the sender then distributed
/// @author The-Poolz contract team
contract MultiSenderV2 is MultiSenderERC20Direct {
    
    /// @notice Collects a specified total amount of ERC20 tokens from the sender and sends varying amounts to multiple addresses
    /// @param _token The ERC20 token address to be sent
    /// @param _totalAmount The total amount of ERC20 tokens to collect from the sender
    /// @param _multiSendData An array of `MultiSendData` structs containing recipient addresses and amounts
    /// @return sum The total amount of tokens distributed
    /// @dev Ensures the total collected amount equals the sum of individual amounts sent; emits a `MultiTransferredERC20` event
    function MultiSendERC20Indirect(
        address _token,
        uint256 _totalAmount,
        MultiSendData[] calldata _multiSendData
    ) external payable erc20FullCheck(_token) returns (uint256 sum) {
        uint length = _notZero(_multiSendData.length);
        _getERC20(_token, _totalAmount);
        for (uint256 i; i < length; ) {
            MultiSendData calldata data = _multiSendData[i];
            sum += _sendERC20(_token, data);
            unchecked {
                ++i;
            }
        }
        _validateEqual(sum, _totalAmount);
        emit MultiTransferredERC20(_token, length, sum);
    }

    /// @notice Collects a total amount of ERC20 tokens from the sender based on a fixed amount per recipient, and sends this amount to each address
    /// @param _token The ERC20 token address to be sent
    /// @param _users An array of recipient addresses
    /// @param _amount The amount of tokens to send to each address
    /// @dev Calculates the total amount by multiplying the number of users by the fixed amount; emits a `MultiTransferredERC20` event
    function MultiSendERC20IndirectSameValue(
        address _token,
        address[] calldata _users,
        uint _amount
    ) external payable erc20FullCheck(_token) {
        uint length = _notZero(_users.length);
        uint sum = _amount * length;
        _getERC20(_token, sum);
        for (uint256 i; i < length; ) {
            address user = _users[i];
            _sendERC20(_token, user, _amount);
            unchecked{
                ++i;
            }
        }
        emit MultiTransferredERC20(_token, length, sum);
    }
}