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
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;


interface IAddressBook {
    /// @dev returns portal by given chainId
    function portal(uint64 chainId) external view returns (address);

    /// @dev returns synthesis by given chainId
    function synthesis(uint64 chainId) external view returns (address);

    /// @dev returns router by given chainId
    function router(uint64 chainId) external view returns (address);

    /// @dev returns cryptoPoolAdapter
    function cryptoPoolAdapter(uint64 chainId) external view returns (address);

    /// @dev returns stablePoolAdapter
    function stablePoolAdapter(uint64 chainId) external view returns (address);

    /// @dev returns whitelist
    function whitelist() external view returns (address);

    /// @dev returns treasury
    function treasury() external view returns (address);

    /// @dev returns gateKeeper
    function gateKeeper() external view returns (address);

    /// @dev returns bridge
    function bridge() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;


interface IGateKeeper {

    function calculateCost(
        address payToken,
        uint256 dataLength,
        uint64 chainIdTo,
        address sender
    ) external returns (uint256 amountToPay);

    function sendData(
        bytes calldata data,
        address to,
        uint64 chainIdTo,
        address payToken
    ) external payable;

    function getNonce() external view returns (uint256);

    function bridge() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;


interface IVirtualPriceReceiver {
    
    function receiveVirtualPrice(uint256 _virtualPriceStable, uint256 _virtualPriceCrypto, uint64 chainIdFrom) external;
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGateKeeper.sol";
import "./interfaces/IAddressBook.sol";
import "./interfaces/IVirtualPriceReceiver.sol";


interface I3Pool {
    function get_virtual_price() external view returns (uint256);
}


contract VirtualPriceSender is Ownable {

    /// @dev addressBook contract
    address public addressBook;
    /// @dev stablePool from which get virtual price
    address public stablePool;
    /// @dev cryptoPool from which get virtual price
    address public cryptoPool;
    /// @dev virtual price receiver contract where send virtual price
    address public virtualPriceReceiver;
    /// @dev chainId of virtual price receiver contract where send virtual price
    uint64 public virtualPriceReceiverChainId;

    event FeePaid(address indexed payer, address accountant, uint256 executionPrice);
    
    constructor(address addressBook_, address stablePool_, address cryptoPool_, address virtualPriceReceiver_, uint64 virtualPriceReceiverChainId_) {
        require(addressBook_ != address(0), "VirtualPriceReceiver: zero addressBook address");
        addressBook = addressBook_;
        stablePool = stablePool_;
        cryptoPool = cryptoPool_;
        virtualPriceReceiver = virtualPriceReceiver_;
        virtualPriceReceiverChainId = virtualPriceReceiverChainId_;
    }

    function sendVirtualPrice() public {
        I3Pool poolImpl = I3Pool(stablePool);
        uint256 virtualPriceStable = poolImpl.get_virtual_price();
        uint256 virtualPriceCrypto = 0;
        if (cryptoPool != address(0)) {
            poolImpl = I3Pool(cryptoPool);
            virtualPriceCrypto = poolImpl.get_virtual_price();
        }

        bytes memory out = abi.encodeWithSelector(
            IVirtualPriceReceiver.receiveVirtualPrice.selector,
            virtualPriceStable,
            virtualPriceCrypto,
            block.chainid
        );
        address gateKeeper = IAddressBook(addressBook).gateKeeper();
        IGateKeeper gateKeeperImpl = IGateKeeper(gateKeeper);
        emit FeePaid(msg.sender, msg.sender, 0);
        gateKeeperImpl.sendData(out, virtualPriceReceiver, virtualPriceReceiverChainId, address(0));

    }

    function setAddressBook(address addressBook_) external onlyOwner {
        addressBook = addressBook_;
    }

    function setStablePool(address newPool) external onlyOwner {
        stablePool = newPool;
    }

    function setCryptoPool(address newPool) external onlyOwner {
        cryptoPool = newPool;
    }

    function setVirtualPriceReceiver(address newVirtualPriceReceiver) external onlyOwner {
        virtualPriceReceiver = newVirtualPriceReceiver;
    }

    function setVirtualPriceReceiverChainId(uint64 newVirtualPriceReceiverChainId) external onlyOwner {
        virtualPriceReceiverChainId = newVirtualPriceReceiverChainId;
    }

}