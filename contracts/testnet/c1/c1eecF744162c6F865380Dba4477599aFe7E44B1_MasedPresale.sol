/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

/**
 *Submitted for verification at Arbiscan on 2023-03-01
*/

/**
 *Submitted for verification at Arbiscan on 2023-02-22
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MasedPresale {
    address payable public immutable owner;

    mapping(address => uint256) public amountPurchased;
    uint256 public immutable maxPerWallet = 10 ether;
    uint256 public immutable presalePrice = 900000000 * 1e18;
    uint256 public totalPurchased = 0;
    uint256 public presaleMax;

    bool public isPublicStart;
    bool public isClaimStart;

    address public immutable token;

    constructor(address _token, uint256 _max) {
        owner = payable(msg.sender);
        token = _token;
        presaleMax = _max;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function buyPresale() external payable {
        require(isPublicStart == true, "Public Sale is not available");
        require(msg.sender == tx.origin, "No contracts");
        require(msg.value > 0, "Zero amount");
        require(amountPurchased[msg.sender] + msg.value <= maxPerWallet, "Over wallet limit");
        require(totalPurchased + msg.value <= presaleMax, "Amount over limit");
        amountPurchased[msg.sender] += msg.value;
        totalPurchased += msg.value;
    }

    function claim() external {
        require(isClaimStart == true, "Claim not allowed");
        require(amountPurchased[msg.sender] > 0, "No amount claimable");
        uint256 amount = amountPurchased[msg.sender] * presalePrice;
        amountPurchased[msg.sender] = 0;
        IERC20(token).transfer(msg.sender, amount);
    }

    function startClaim() public onlyOwner {
        require(isPublicStart == false, "Presale is open");
        isClaimStart = true;
    }

    function startPublicSale() public onlyOwner {
        isPublicStart = true;
    }

    function endPublicSale() public onlyOwner {
        isPublicStart = false;
    }

    function setMax(uint256 _max) external onlyOwner {
        presaleMax = _max;
    }

    function claimPool() public onlyOwner {
        require(isClaimStart == true, "Claim not allowed");
        require(address(this).balance == 0, "Insufficient balance");
        owner.transfer(address(this).balance);
    }

    function recover() public onlyOwner {
        require(isClaimStart == true, "Claim not allowed");
        uint256 unsoldAmt = presaleMax - totalPurchased;
        IERC20(token).transfer(owner, unsoldAmt);
    }
}