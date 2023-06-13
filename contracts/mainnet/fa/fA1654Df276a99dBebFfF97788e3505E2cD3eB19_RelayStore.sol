// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./types/IRelayStore.sol";

contract RelayStore is Ownable, IRelayStore {
    RelayEntry[] relayList;
    uint8 public relayPercentage = 10; // relayer beeps
    uint8 public relayPercentageSwap = 10;

    function setRelayPercentage(uint8 _relayPercentage) public onlyOwner {
        require(_relayPercentage <= 50);
        relayPercentage = _relayPercentage;
        emit RelayPercentageChanged(relayPercentage);
    }

    function setRelayPercentageSwap(uint8 _relayPercentageSwap)
        public
        onlyOwner
    {
        require(_relayPercentageSwap <= 50);
        relayPercentageSwap = _relayPercentageSwap;
        emit RelayPercentageSwapChanged(relayPercentageSwap);
    }


    function isRelayInList(address relay) public view returns (bool) {
        bool found = false;
        for (uint256 i = 0; i < relayList.length; i++) {
            if (relayList[i].relayAddress == relay) {
                found = true;
                break;
            }
        }
        return found;
    }

    function getRelayList() public view returns (RelayEntry[] memory) {
        return relayList;
    }

    function addOrSetRelay(
        address relayAddress,
        string memory url,
        uint256 priority
    ) public onlyOwner {
        uint256 foundIndex = relayList.length;

        for (uint256 i = 0; i < relayList.length; i++) {
            if (
                keccak256(abi.encodePacked(relayList[i].url)) ==
                keccak256(abi.encodePacked(url))
            ) {
                foundIndex = i;
                break;
            }
        }
        RelayEntry memory relayEntry = RelayEntry(relayAddress, url, priority);

        if (foundIndex != relayList.length) {
            require(
                relayList[foundIndex].relayAddress == relayAddress,
                "owner doesn't match"
            );
            relayList[foundIndex] = relayEntry;
        } else relayList.push(relayEntry);

        emit RelayAddedOrSet(relayAddress, url, priority);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct RelayEntry {
    address relayAddress;
    string url;
    uint256 priority;
}

interface IRelayStore {
    event RelayPercentageChanged(uint8 newRelayPercentage);
    event RelayPercentageSwapChanged(uint8 newRelayPercentageSwap);
    event RelayAddedOrSet(address relayAddress, string url, uint256 priority);

    function setRelayPercentage(uint8 _relayPercentage) external;

    function setRelayPercentageSwap(uint8 _relayPercentageSwap) external;

    function isRelayInList(address relay) external returns (bool);

    function getRelayList() external view returns (RelayEntry[] memory);

    function addOrSetRelay(
        address relayAddress,
        string memory url,
        uint256 priority
    ) external;

    function relayPercentage() external view returns (uint8);

    function relayPercentageSwap() external view returns (uint8);
    // function swapSlippagePercentage() external view returns (uint8);
}