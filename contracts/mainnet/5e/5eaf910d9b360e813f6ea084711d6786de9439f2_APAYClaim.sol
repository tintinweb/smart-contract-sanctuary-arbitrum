/**
 *Submitted for verification at Arbiscan.io on 2023-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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


contract APAYClaim {
    address public owner;
    address public APAYAddress = 0xCf5eDf9c4e8bBD9D7Fa3D9E18B915f198FDA8F66; // APAY Address
    uint256 public ApayPerEth = 98209486 * 1e18; // APAY/ETH RATIO
    IERC20  public ApayToken = IERC20(APAYAddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Sends ETH to any APAY holder based on the ratio ethPerAPAY ratio
    function claimETH() external {
        uint256 ApayBalance = getAPAYBalance(msg.sender);
        require(ApayBalance > 0, "No APAY FOUND");
        require(ApayToken.transferFrom(msg.sender, owner, ApayBalance), "APAY transfer failed");

        // amount of eth to be claimed
        uint256 ethToBeClaimed = (ApayBalance * 1e18) / ApayPerEth;
        
        uint256 contractBalance = address(this).balance;
        require(ethToBeClaimed > 0, "Not ETH to be claimed");
        require(ethToBeClaimed <= contractBalance, "Not enough ETH to claim");

        // Transfer ETH to the caller
        payable(msg.sender).transfer(ethToBeClaimed);
    }

    // sends all the eth to the owner
    function withdrawETH() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No ETH to withdraw");
        payable(owner).transfer(contractBalance);
    }

    // gets a given wallet balance of APAY
    function getAPAYBalance(address _wallet) public view returns (uint256) {
        return ApayToken.balanceOf(_wallet);
    }

    function changeRatio(uint256 _newRatio) external onlyOwner {
        ApayPerEth = _newRatio;
    }

    fallback() external payable {}

    receive() external payable {}
}