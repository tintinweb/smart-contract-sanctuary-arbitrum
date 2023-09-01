/**
 *Submitted for verification at Arbiscan.io on 2023-08-30
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IRecoreEvent.sol

pragma solidity 0.8.1;

interface IRecoreEvent {
    event Operator(
        address indexed sender,
        address user,
        uint256 itype
    );

    event OperatorWithValue(
        address indexed sender,
        address user,
        uint256 itype,
        uint256 aValue,
        uint256 bValue,
        uint256 cValue
    );

    function operationEvent(address user,uint256 iType) external; 
    function operatorWithValue(address user,uint256 iType,uint256 aValue,uint256 bValue,uint256 cValue) external;
    function setWhiteList(address whiteUser) external;
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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

// File: contracts/RecodEvent.sol

pragma solidity 0.8.1;
contract RecordEvent is IRecoreEvent,Ownable  {
    mapping(address=>bool) public _whiteList;
    address public _factory;

    constructor(){}

    modifier onlyFactory() {
        require(_factory == msg.sender || owner() == msg.sender,"only factory or Owner can set");
        _;
    }

    modifier onlyWhite() {
        require(_whiteList[msg.sender],"only white can emit operator event");
        _;
    }

    function setFactory(address factory_) public onlyOwner {
        _factory = factory_;
    }

    function setWhiteList(address whiteUser) external override onlyFactory {
        _whiteList[whiteUser] = true;
    }

    function removeWhiteList(address whiteUser) public onlyOwner {
        _whiteList[whiteUser] = false;
    }
    function operationEvent(address user,uint256 iType) external override onlyWhite {
        emit Operator(msg.sender,user,iType);
    }

    function operatorWithValue(address user,uint256 iType,uint256 aValue,uint256 bValue,uint256 cValue) external override onlyWhite {
        emit OperatorWithValue(msg.sender,user,iType,aValue,bValue,cValue);
    }
}