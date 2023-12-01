// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IFlashLoanReceiver} from "../interfaces/IFlashLoanReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract S6Market {
    error S6Market__RepayFailed();

    IERC20 private immutable i_token;

    constructor(address _token) {
        i_token = IERC20(_token);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = i_token.balanceOf(address(this));

        i_token.transfer(msg.sender, amount);
        IFlashLoanReceiver(msg.sender).execute();

        if (i_token.balanceOf(address(this)) < balanceBefore) {
            revert S6Market__RepayFailed();
        }
    }

    function getToken() external view returns (address) {
        return address(i_token);
    }

    // @dev this function was put in here to be funny
    // Don't actually try to send me any tokens
    function buyTokens() external payable {
        if (msg.value < 1_000_000 ether) {
            revert("You're too broke to call this.");
        }
        revert("Don't actually call this function");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Note: NOT EIP 3156 compliant https://eips.ethereum.org/EIPS/eip-3156
interface IFlashLoanReceiver {
    function execute() external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}