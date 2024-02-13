// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

enum ActionType {
    DEPOSIT,
    REDEEM
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITypes.sol";

contract PartnerShip is Ownable {
    struct Fee {
        uint256 depositFee;
        uint256 redeemFee;
    }

    mapping(address => address) private childToParent;
    mapping(address => Fee) private parentToFees;

    event PartnerShipCreated(address indexed parent, address indexed child);
    event PartnerShipFeesUpdated(
        address indexed parent,
        uint256 depositFee,
        uint256 redeemFee
    );

    // Create the relationship between a parent and children
    function createPartnerShip(
        address[] calldata _children,
        address _parent
    ) external onlyOwner {
        for (uint256 i = 0; i < _children.length; i++) {
            address child = _children[i];
            require(child != address(0), "PartnerShip: child is zero address");
            childToParent[child] = _parent;
            emit PartnerShipCreated(_parent, child);
        }
    }

    // Update the fees of the parent
    function updatePartnerShipFees(
        address _parent,
        uint256 _depositFee,
        uint256 _redeemFee
    ) external onlyOwner {
        require(_parent != address(0), "PartnerShip: parent is zero address");
        parentToFees[_parent] = Fee(_depositFee, _redeemFee);
        emit PartnerShipFeesUpdated(_parent, _depositFee, _redeemFee);
    }

    // Get the parent of the child
    function getParent(address _child) external view returns (address _parent) {
        _parent = childToParent[_child];
    }

    // Get the deposit and redeem fees of the parent
    function getParentFees(
        address _parent
    ) external view returns (uint256 _depositFee, uint256 _redeemFee) {
        Fee memory fees = parentToFees[_parent];
        _depositFee = fees.depositFee;
        _redeemFee = fees.redeemFee;
    }

    // Get the fee of the child based on action type
    function getFeeByChildAndAction(
        address child,
        ActionType action
    ) external view returns (uint256 _fee) {
        Fee memory fees = parentToFees[childToParent[child]];
        _fee = (action == ActionType.DEPOSIT)
            ? fees.depositFee
            : fees.redeemFee;
    }

    // Check if there is a relationship between the child and parent
    function isChildHasParent(address child) external view returns (bool) {
        return childToParent[child] != address(0);
    }
}