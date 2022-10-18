//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function balanceOf(address) external view returns (uint256);
    function safeTransferMany(address, uint[] memory) external;
    function claim(address) external;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
}

contract NFTSale is Ownable {

    uint public price;
    IERC721 public nft;
    IERC20 public token;

    uint[] public availableIds;

    constructor (IERC721 _nft, IERC20 _token) {
        nft = _nft;
        token = _token;
    }


    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function available() external view returns (uint) {
        return nft.balanceOf(address(this));
    }

    function buy(uint _amount) external {
        require(_amount <= availableIds.length, "Not enough for sale");
        uint _tokenAmount = _amount*price;
        token.transferFrom(msg.sender, owner(), _tokenAmount);
        uint[] memory _sold = new uint[](_amount);
        for (uint i=0; i<_amount; i++) {
            _sold[i] = availableIds[(availableIds.length-i) - 1];
        }
        for (uint i=0; i<_amount; i++) {
            availableIds.pop();
        }
        nft.safeTransferMany(msg.sender, _sold);
    }

    function recovertoken() external {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function recoverNft() external onlyOwner {
        nft.safeTransferMany(owner(), availableIds);
        availableIds = new uint[](0);
    }

    function setIds(uint[] calldata _ids) external onlyOwner {
        availableIds = _ids;
    }

    function claimPendingRev(address _tigAsset) external {
        nft.claim(_tigAsset);
        IERC20(_tigAsset).transfer(owner(), IERC20(_tigAsset).balanceOf(address(this)));
    }
}

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