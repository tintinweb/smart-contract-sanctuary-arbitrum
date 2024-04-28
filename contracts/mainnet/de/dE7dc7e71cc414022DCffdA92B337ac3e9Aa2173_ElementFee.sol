// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibStorage {

    uint256 constant STORAGE_ID_OWNABLE = 1 << 128;

    struct Storage {
        address implementation;
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_OWNABLE }
    }
}

contract ElementFee {

    event Upgraded(address indexed previousImpl, address indexed newImpl);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ERC20Deposited(address indexed token, address indexed caller, uint256 indexed value);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function implementation() public view returns (address) {
        return LibStorage.getStorage().implementation;
    }

    function upgrade(address impl) external onlyOwner {
        LibStorage.Storage storage stor = LibStorage.getStorage();
        address oldImpl = stor.implementation;
        stor.implementation = impl;
        emit Upgraded(oldImpl, impl);
    }

    function owner() public view returns (address) {
        return LibStorage.getStorage().owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function depositETH() external payable {
        require(msg.value != 0, "depositETH failed : msg.value is zero");
        emit ERC20Deposited(address(0), msg.sender, msg.value);
    }

    function depositERC20(address asset, uint256 amount) external {
        require(asset != address(0), "depositERC20 failed : invalid token");
        require(amount != 0, "depositERC20 failed : amount is zero");
        uint256 beforeBalance = IERC20(asset).balanceOf(address(this));
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        uint256 afterBalance = IERC20(asset).balanceOf(address(this));
        require(beforeBalance + amount == afterBalance, "depositERC20 failed : checkout balance error");
        emit ERC20Deposited(asset, msg.sender, amount);
    }

    function withdrawETH(address recipient, uint256 amount) external onlyOwner {
        address to = (recipient != address(0)) ? recipient : msg.sender;
        if (amount == 0) {
            amount = address(this).balance;
            require(amount != 0, "withdrawETH failed : insufficient balance");
        }
        _transferEth(to, amount);
    }

    function withdrawERC20(address asset, address recipient, uint256 amount) external onlyOwner {
        address to = (recipient != address(0)) ? recipient : msg.sender;
        if (amount == 0) {
            amount = IERC20(asset).balanceOf(address(this));
            require(amount != 0, "withdrawERC20 failed : insufficient balance");
        }
        IERC20(asset).transfer(to, amount);
    }

    receive() external payable {}

    fallback() external payable {
        address impl = implementation();
        require(impl != address(0), "Implementation not set");
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _transferOwnership(address newOwner) private {
        LibStorage.Storage storage stor = LibStorage.getStorage();
        address oldOwner = stor.owner;
        stor.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _transferEth(address recipient, uint256 amount) internal {
        uint256 success;
        assembly {
            if call(gas(), recipient, amount, 0, 0, 0, 0) {
                success := 1
            }
        }
        require(success != 0, "_transferEth failed");
    }
}