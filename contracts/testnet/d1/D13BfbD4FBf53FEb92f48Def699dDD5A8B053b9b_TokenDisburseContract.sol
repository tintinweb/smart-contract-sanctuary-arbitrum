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
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenDisburseContract {
    struct UserDetails {
        address userAddress;
        uint256 lastDisperseTimestamp;
        uint256 totalDisperseAmount;
    }

    uint256 public constant MAX_DISPERSE_AMOUNT_PER_TXN = 200;
    uint256 public constant MAX_DISPERSE_AMOUNT_PER_USER = 1e5;
    uint256 public constant ONE_DAY_TIMESTAMP = 86400;

    IERC20 public token;
    mapping(address => UserDetails) public users;

    constructor(IERC20 _token) {
        token = _token;
    }

    function disburseTokens() public {
        UserDetails storage user = users[tx.origin];
        if (user.userAddress == address(0)) user.userAddress = tx.origin;
        
        if (user.totalDisperseAmount + MAX_DISPERSE_AMOUNT_PER_TXN <= MAX_DISPERSE_AMOUNT_PER_USER) {
            if ((user.lastDisperseTimestamp + ONE_DAY_TIMESTAMP) <= block.timestamp)
                if (token.balanceOf(address(this)) >= MAX_DISPERSE_AMOUNT_PER_TXN) {
                    token.transfer(user.userAddress, MAX_DISPERSE_AMOUNT_PER_TXN);
                    user.lastDisperseTimestamp = block.timestamp;
                    user.totalDisperseAmount += MAX_DISPERSE_AMOUNT_PER_TXN;
                }
        }
    }
}