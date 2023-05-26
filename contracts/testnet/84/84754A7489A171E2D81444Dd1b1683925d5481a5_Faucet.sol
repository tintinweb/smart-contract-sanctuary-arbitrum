/**
 *Submitted for verification at Arbiscan on 2023-05-25
*/

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.2;

contract Faucet {

    address public owner;
    uint256 public amountClaim;
    IERC20 public token;
    mapping(address => bool) userClaimed;
    address[] public usersClaimed;
    
    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        amountClaim = 1000000000000000000000;
        owner = msg.sender;
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "not allow");
        _;
    }

    mapping(address => uint256) public lockTime;

    function claim() external {
        require(userClaimed[msg.sender] == false, "you have claimed");
        token.transfer(msg.sender, amountClaim);
        userClaimed[msg.sender] = true;
        usersClaimed.push(msg.sender);
    }

    function setAmountClaim(uint256 _amount) external isOwner {
        amountClaim = _amount;
    }

    function setToken(address _tokenAddress) external isOwner {
        token = IERC20(_tokenAddress);
    }

    function delAllClaimed() external isOwner {
        for (uint i=0; i < usersClaimed.length; i++) {
            userClaimed[usersClaimed[i]] = false;
            delete usersClaimed[i];
        }
    }

    function withdraw(uint256 _amount) external isOwner {
        token.transfer(msg.sender, _amount);
    }

    function balance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}