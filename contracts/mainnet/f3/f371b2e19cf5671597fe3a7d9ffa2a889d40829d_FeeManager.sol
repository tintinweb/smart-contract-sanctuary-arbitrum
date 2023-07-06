// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin-contracts/contracts/access/Ownable.sol";

import "../interfaces/IFeeManager.sol";

/**
 * @title FeeManager
 * @dev A fee manager contract designed to handle fees within the box
 */
contract FeeManager is IFeeManager, Ownable {
    uint256 public fee;
    uint256 public commissionBPS;

    /**
     * @dev Sets initial values for {fee} and {commissionBPS}.
     * @param _fee a flat fee, denominated in NATIVE, for transactions going through the box
     * @param _commissionBPS a bp fee, denominated in NATIVE, for transactions going through the box
     */
    constructor(uint256 _fee, uint256 _commissionBPS) {
        fee = _fee;
        commissionBPS = _commissionBPS;
    }

    /**
     * @dev allows owner to update the values for {fee} and {commissionBPS}.
     * @param _fee a flat fee, denominated in native, for transactions going through the box
     * @param _commissionBPS a bp fee, denominated in native, for transactions going through the box
     */
    function setFees(uint256 _fee, uint256 _commissionBPS) external onlyOwner {
        fee = _fee;
        commissionBPS = _commissionBPS;
    }

    /**
     * @dev calculates the bp fee on a transaction
     * @param amountIn The amount of native or erc20 being transferred.
     * @param tokenIn The address of the token being transferred, zero address for native currency.
     */
    function _calculateCommission(uint256 amountIn, address tokenIn) private view returns (uint256) {
        return commissionBPS == 0 || tokenIn != address(0) ? 0 : (amountIn * commissionBPS / 100_00);
    }

    /**
     * @dev calculates flat fee and bp fee for transaction, returns a tuple for both values
     * @param amountIn The amount of native or erc20 being transferred.
     * @param tokenIn The address of the token being transferred, zero address for native currency.
     */
    function calculateFees(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256 fees, uint256 commission)
    {
        return (fee, _calculateCommission(amountIn, tokenIn));
    }

    /**
     * @dev allows controller of feemanager to redeem fees
     */
    function redeemFees() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    receive() external payable {}
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IFeeManager {
    error WithdrawFailed();

    function setFees(uint256 _fee, uint256 _commissionBPS) external;

    function calculateFees(uint256 amountIn, address tokenIn) external view returns (uint256 fee, uint256 commission);

    function redeemFees() external;
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