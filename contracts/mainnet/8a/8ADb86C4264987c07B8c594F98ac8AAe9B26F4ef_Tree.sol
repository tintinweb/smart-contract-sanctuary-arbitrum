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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface INetwork {
    function getF1ListForAccount(address _wallet) external view returns (address[] memory);
}

contract Tree is Ownable {
    address public networkContract;

    constructor(address _networkContract) {
        networkContract = _networkContract;
    }

    function setNetworkContract(address _networkContract) external onlyOwner {
        networkContract = _networkContract;
    }

    function getF1ListForAccount(address _wallet) public view returns (address[] memory) {
        return INetwork(networkContract).getF1ListForAccount(_wallet);
    }

    function getChildren(
        address wallet,
        uint256 floor,
        uint256 maxFloor,
        address[] memory childrenList
    ) internal view returns (address[] memory) {
        address[] memory children = getF1ListForAccount(wallet);
        uint256 childrenCount = childrenList.length + children.length;
        address[] memory returnArr = new address[](childrenCount);

        uint256 i = 0;
        for (; i < childrenList.length; i++) {
            returnArr[i] = childrenList[i];
        }

        uint256 j = 0;
        while (j < children.length) {
            returnArr[i++] = children[j++];
        }

        if (floor < maxFloor) {
            for (uint256 k = 0; k < children.length; k++) {
                returnArr = getChildren(children[k], (floor + 1), maxFloor, returnArr);
            }
        }

        return returnArr;
    }

    function getAllChildren(address wallet, uint256 maxFloor) external view returns (address[] memory) {
        address[] memory childrenList;
        return getChildren(wallet, 1, maxFloor, childrenList);
    }

    function getChildrenFloorCount(
        address wallet,
        uint256 floor,
        uint256 maxFloor,
        uint256 childrenCount
    ) internal view returns (uint256) {
        address[] memory children = getF1ListForAccount(wallet);
        if (floor == maxFloor) {
            return childrenCount + children.length;
        }

        for (uint256 k = 0; k < children.length; k++) {
            childrenCount = getChildrenFloorCount(children[k], (floor + 1), maxFloor, childrenCount);
        }

        return childrenCount;
    }

    function getChildrenFloor(
        address wallet,
        uint256 floor,
        uint256 maxFloor,
        address[] memory childrenList
    ) internal view returns (address[] memory) {
        address[] memory children = getF1ListForAccount(wallet);
        if (floor == maxFloor) {
            uint256 childrenCount = childrenList.length + children.length;
            address[] memory childrenArr = new address[](childrenCount);
            uint256 i = 0;
            for (; i < childrenList.length; i++) {
                childrenArr[i] = childrenList[i];
            }

            uint256 j = 0;
            while (j < children.length) {
                childrenArr[i++] = children[j++];
            }

            return childrenArr;
        }

        for (uint256 k = 0; k < children.length; k++) {
            childrenList = getChildrenFloor(children[k], (floor + 1), maxFloor, childrenList);
        }

        return childrenList;
    }

    function getAllChildrenFloor(address wallet, uint256 floor) external view returns (address[] memory) {
        address[] memory childrenList;
        return getChildrenFloor(wallet, 1, floor, childrenList);
    }

    function getAllChildrenFloorCount(address wallet, uint256 floor) external view returns (uint256) {
        return getChildrenFloorCount(wallet, 1, floor, 0);
    }
}