// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract PendleForwarder is Ownable {
    uint256 public fee;
    address payable public feeReceiver;

    event Received(address indexed sender, uint256 amount);
    event ERC20Received(address indexed sender, address indexed tokenAddress, uint256 amount);
    event ERC721Received(address indexed sender, address indexed tokenAddress, uint256 tokenId);
    event ERC1155Received(address indexed sender, address indexed tokenAddress, uint256 tokenId, uint256 amount);
    event PendleSwap(address indexed market, uint256 indexed user_fid, uint256 indexed referrer_fid, uint256 amount);

    constructor(uint256 _fee, address payable _feeReceiver, address _initialOwner) Ownable(_initialOwner) {
        fee = _fee;
        feeReceiver = _feeReceiver;
    }

    receive() external payable { }

    function forwardPendle(
        address target,
        bytes calldata data,
        address market,
        uint256 user,
        uint256 referrer
    )
        public
        payable
    {
        uint256 swapValue;
        uint256 feeAmount;
        if (fee > 0) {
            feeAmount = msg.value * fee / 1e18;
            swapValue = msg.value - feeAmount;
        } else {
            swapValue = msg.value;
        }

        (bool success,) = target.call{ value: swapValue }(data);
        if (success) {
            emit PendleSwap(market, user, referrer, msg.value);
            if (feeAmount > 0) {
                feeReceiver.transfer(feeAmount);
            }
        } else {
            revert("Call failed");
        }
    }

    function setFee(uint256 _newFee) public onlyOwner {
        fee = _newFee;
    }

    function setFeeReceiver(address payable _newReceiver) public onlyOwner {
        feeReceiver = _newReceiver;
    }

    // 1. 특정 주소로 ethereum을 보낼 수 있는 함수 (ownerOnly)
    function sendEther(address payable _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Invalid address");
        require(address(this).balance >= _amount, "Insufficient balance");
        _to.transfer(_amount);
    }

    // 2. ERC-20 토큰을 safe로 받을 수 있게 하는 리시브함수
    function onERC20Received(
        address _operator,
        address _from,
        uint256 _value,
        bytes calldata /* _data */
    )
        external
        returns (bytes4)
    {
        emit ERC20Received(_from, _operator, _value);
        return 0x150b7a02; // ERC-20 Token Received
    }

    // 3. ERC-721, 1155도 마찬가지
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata /* _data */
    )
        external
        returns (bytes4)
    {
        emit ERC721Received(_from, _operator, _tokenId);
        return 0x150b7a02; // ERC-721 Token Received
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata /* _data */
    )
        external
        returns (bytes4)
    {
        emit ERC1155Received(_from, _operator, _id, _value);
        return 0xf23a6e61; // ERC-1155 Single Token Received
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata /* _data */
    )
        external
        returns (bytes4)
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            emit ERC1155Received(_from, _operator, _ids[i], _values[i]);
        }
        return 0xbc197c81; // ERC-1155 Batch Token Received
    }

    // 4. target (address), value(ethereum), data(calldata) 로 어떤 컨트랙트든 실행할 수 있는 함수 (ownerOnly)
    function executeTransaction(address payable target, uint256 value, bytes calldata data) public payable onlyOwner {
        require(target != address(0), "Invalid target address");
        (bool success,) = target.call{ value: value }(data);
        require(success, "Transaction failed");
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