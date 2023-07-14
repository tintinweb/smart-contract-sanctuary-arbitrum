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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/IIntellSetting.sol";

pragma experimental ABIEncoderV2;

contract IntellSetting is Ownable, IIntellSetting {
    address private _admin;
    address private _truthHolder;
    address private _intellTokenAddr;
    address private _intellShareCollectionContractAddr;
    address private _intellModelNFTContractAddr;
    uint256 private _modelRegisterationPrice;
    uint256 private _intellShareCollectionLaunchPrice;

    constructor() {}

    function truthHolder() external view override returns (address) {
        return _truthHolder;
    }

    function setTruthHolder(address _newTruthHolder) external onlyOwner {
        _truthHolder = _newTruthHolder;
    }

    function modelRegisterationPrice()
        external
        view
        override
        returns (uint256)
    {
        return _modelRegisterationPrice;
    }

    function setModelRegisterationPrice(uint256 val) external onlyOwner {
        _modelRegisterationPrice = val;
    }

    function intellShareCollectionLaunchPrice()
        external
        view
        override
        returns (uint256)
    {
        return _intellShareCollectionLaunchPrice;
    }

    function setIntellShareCollectionLaunchPrice(
        uint256 _newLaunchPrice
    ) external onlyOwner {
        _intellShareCollectionLaunchPrice = _newLaunchPrice;
    }

    function admin() external view override returns (address) {
        return _admin;
    }

    function setAdmin(address newAdmin) external onlyOwner {
        _admin = newAdmin;
    }

    function intellTokenAddr() external view override returns (address) {
        return _intellTokenAddr;
    }

    function setIntellTokenAddr(address newIntellTokenAddr) external onlyOwner {
        _intellTokenAddr = newIntellTokenAddr;
    }

    function intellShareCollectionContractAddr()
        external
        view
        override
        returns (address)
    {
        return _intellShareCollectionContractAddr;
    }

    function setIntellShareCollectionContractAddr(
        address _newAddr
    ) external onlyOwner {
        _intellShareCollectionContractAddr = _newAddr;
    }

    function intellModelNFTContractAddr()
        external
        view
        override
        returns (address)
    {
        return _intellModelNFTContractAddr;
    }

    function setIntellModelNFTContractAddr(address newAddr) external onlyOwner {
        _intellModelNFTContractAddr = newAddr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IIntellSetting {
    function admin() external view returns(address);
    function truthHolder() external view returns(address);
    function intellShareCollectionLaunchPrice() external view returns(uint256);
    function intellTokenAddr() external view returns(address);
    function intellShareCollectionContractAddr() external view returns(address);
    function intellModelNFTContractAddr() external view returns(address);
    function modelRegisterationPrice() external view returns(uint256);
}