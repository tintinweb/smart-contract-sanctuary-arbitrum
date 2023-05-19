/**
 *Submitted for verification at Arbiscan on 2023-05-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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

contract Airdrop {
    struct Target {
        address addr;
        uint256 amount;
    }

    function airDropNative(Target[] calldata targets) public {
        bool success = false;
        for (uint256 index = 0; index < targets.length; index++) {
            Target memory target = targets[index];
            (success, ) = target.addr.call{value: target.amount}("");
            if (!success) {
                break;
            }
        }
    }

    function airDropNative(address[] calldata targets, uint256 amount) public {
        for (uint256 index = 0; index < targets.length; index++) {
            address target = targets[index];
            (bool success, ) = target.call{value: amount}("");
            if (!success) {
                break;
            }
        }
    }

    function airDropErc20(address addr, Target[] calldata targets) public {
        IERC20 erc20 = IERC20(addr);
        bool success = false;
        for (uint256 index = 0; index < targets.length; index++) {
            Target memory target = targets[index];
            success = erc20.transferFrom(
                address(msg.sender),
                target.addr,
                target.amount
            );
            if (!success) {
                break;
            }
        }
    }

    function airDropErc20(
        address addr,
        address[] calldata targets,
        uint256 amount
    ) public {
        IERC20 erc20 = IERC20(addr);
        for (uint256 index = 0; index < targets.length; index++) {
            bool success = erc20.transferFrom(
                address(msg.sender),
                targets[index],
                amount
            );
            if (!success) {
                break;
            }
        }
    }
}