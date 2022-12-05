//SPDX-License-Identifier: Unlicense
// Creator: Pixel8 Labs
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract LPFarmingSYN {
    mapping(uint256 => address) poolAddress;
    mapping(address => uint256) stakedAmount;

    address SYNAddr = 0x5EaB1Ddc2692EFb1F311e2052F85e61dC73ddbF0; // SYN token address

    constructor() {
        poolAddress[0] = 0x2af760c7065b2A2b7D41acAD23481839F3f28456; // SYN-LPToken
    }

    function deposit(uint256 pid, uint256 amount, address to) external {
        IERC20 lpUSDC = IERC20(poolAddress[pid]);
        lpUSDC.transferFrom(to, address(this), amount);
        stakedAmount[to] += amount;
    }

    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external {
        require(stakedAmount[to] >= amount, "withdraw: amount is too large");
        IERC20 lpUSDC = IERC20(poolAddress[pid]);
        lpUSDC.transfer(to, amount);
        stakedAmount[to] -= amount;
        IERC20 SYN = IERC20(SYNAddr);
        SYN.transfer(to, 1000000000000000000);
    }

    function harvest(uint256 pid, address to) external {
        IERC20 SYN = IERC20(SYNAddr);
        SYN.transfer(to, 1000000000000000000);
    }

    function userInfo(uint256 pid, address user) external view returns (uint256) {
        return stakedAmount[user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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