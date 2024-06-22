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
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import {AddressArrayUtils} from "./lib/AddressArrayUtils.sol";

/**
 * @title HayaTokenPool
 * @dev This contract represents a Haya Pool, which is used to claim Haya tokens.
*/
contract HayaTokenPool is Ownable2Step {

    using AddressArrayUtils for address[];

    /**
     * @dev Public variable representing the Haya token contract.
     */
    IERC20 public immutable hayaToken;

    /**
     * @dev An array of addresses representing the claimers in the HayaPool contract.
     */
    address[] public claimers;

    /**
     * @dev Emitted when a user deposits tokens into the HayaPool contract.
     * @param user The address of the user who made the deposit.
     * @param amount The amount of tokens deposited.
     */
    event Deposited(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user claims their rewards from the HayaPool contract.
     * @param claimer The address of the user who claimed the rewards.
     * @param recipient The address where the claimed rewards are sent to.
     * @param amount The amount of rewards claimed.
     */
    event Claimed(address indexed claimer, address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when a claimer is added to the HayaPool contract.
     * @param claimer The address of the claimer being added.
     */
    event ClaimerAdded(address indexed claimer);

    /**
     * @dev Emitted when a claimer is removed from the HayaPool contract.
     * @param claimer The address of the claimer being removed.
     */
    event ClaimerRemoved(address indexed claimer);

    /**
     * @dev Emitted when an emergency claim is made.
     * @param recipient The address of the recipient who made the claim.
     * @param amount The amount that was claimed.
     */
    event EmergencyClaimed(address indexed recipient, uint256 amount);


    /**
    * @dev Constructor function for the HayaPool contract.
    * @param _hayaToken The address of the Haya token contract.
    * @param _owner The address of the contract owner.
    */
    constructor(address _hayaToken, address _owner) Ownable(_owner) {
        hayaToken = IERC20(_hayaToken);
    }

    /**
     * @dev Claims the rewards from the HayaPool contract.
     * Can only be called by a claimer.
     * @param _recipient The address where the claimed rewards are sent to.
     * @param _amount The amount of rewards to claim.
     */
    function claim(address _recipient, uint256 _amount) external onlyClaimer {
        hayaToken.transfer(_recipient, _amount);
        emit Claimed(msg.sender, _recipient, _amount);
    }

    /**
     * @dev Transfers a specified amount of Haya tokens to the HayaPool contract.
     * Can be called by anyone.
     * 
     * @param _amount The amount of Haya tokens to transfer.
     */
    function deposit(uint256 _amount) external {
        hayaToken.transferFrom(msg.sender, address(this), _amount);
        emit Deposited(msg.sender, _amount);
    }
    
    /**
     * @dev Adds a new claimer to the HayaPool contract.
     * This function can only be called by the contract owner.
     * @param _claimer The address of the new claimer.
     */
    function addClaimer(address _claimer) public onlyOwner {
        require(claimers.contains(_claimer) == false, "HayaTokenPool: claimer already exists");
        claimers.push(_claimer);
        emit ClaimerAdded(_claimer);
    }
    
    /**
     * @dev Removes a claimer from the HayaPool contract.
     * This function can only be called by the contract owner.
     * @param _claimer The address of the claimer to remove.
     */
    function removeClaimer(address _claimer) public onlyOwner {
        require(claimers.contains(_claimer) == true, "HayaTokenPool: claimer does not exist");
        claimers.removeStorage(_claimer);
        emit ClaimerRemoved(_claimer);
    }
    
    /**
     * @dev Allows the owner to perform an emergency claim of Haya tokens.
     * This function can only be called by the contract owner.
     * @param _recipient The address to receive the claimed Haya tokens.
     * @param _amount The amount of Haya tokens to claim.
     */
    function emergencyClaim(address _recipient, uint256 _amount) public onlyOwner {
        hayaToken.transfer(_recipient, _amount);
        emit EmergencyClaimed(_recipient, _amount);
    }

    /**
     * @dev Fallback function to reject any incoming Ether transfers.
     * Reverts the transaction to prevent accidental transfers to this contract.
     */
    receive() external payable {
        revert();
    }

    /**
     * @dev Modifies a method to only be executable by a specific claimer.
     */
    modifier onlyClaimer() {
        require(claimers.contains(msg.sender), "HayaTokenPool: caller is not a claimer");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title AddressArrayUtils
 * @dev Library for working with arrays of addresses.
 */
library AddressArrayUtils {

    /**
     * @dev Returns the index of the specified address in the given array.
     * @param A The array of addresses to search in.
     * @param a The address to search for.
     * @return The index of the address in the array, and a boolean indicating whether the address was found.
     */
    function indexOf(
        address[] memory A,
        address a
    ) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (type(uint256).max, false);
    }

    /**
     * @dev Checks if an address array contains a specific address.
     * @param A The address array to search in.
     * @param a The address to search for.
     * @return True if the address is found in the array, false otherwise.
     */
    function contains(
        address[] memory A,
        address a
    ) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
     * @dev Checks if an array of addresses contains any duplicates.
     * @param A The array of addresses to check.
     * @return True if the array contains duplicates, false otherwise.
     */
    function hasDuplicate(address[] memory A) internal pure returns (bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @dev Removes a specific address from an array of addresses.
     * @param A The array of addresses.
     * @param a The address to be removed.
     * @return The updated array of addresses after removing the specified address.
     * @notice This function is internal and should only be called from within the contract.
     * @notice If the specified address is not found in the array, a revert error is thrown.
     */
    function remove(
        address[] memory A,
        address a
    ) internal pure returns (address[] memory) {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A, ) = pop(A, index);
            return _A;
        }
    }

    /**
     * @dev Removes the specified address from the given storage array.
     * @param A The storage array of addresses.
     * @param a The address to be removed.
     * @notice This function will revert if the specified address is not found in the array.
     * @notice If the array is empty, this function will not throw an underflow error.
     */
    function removeStorage(address[] storage A, address a) internal {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) {
                A[index] = A[lastIndex];
            }
            A.pop();
        }
    }

    /**
     * @dev Removes an element from the given address array at the specified index.
     * @param A The address array.
     * @param index The index of the element to be removed.
     * @return The updated address array after removing the element, and the removed element.
     * @notice This function modifies the original array by removing the element at the specified index.
     * @notice The index must be less than the length of the array.
     */
    function pop(
        address[] memory A,
        uint256 index
    ) internal pure returns (address[] memory, address) {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * @dev Extends an array of addresses by appending another array of addresses.
     * @param A The first array of addresses.
     * @param B The second array of addresses.
     * @return The extended array of addresses.
     */
    function extend(
        address[] memory A,
        address[] memory B
    ) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }
}