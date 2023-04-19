//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BBQPartyPublicPresale {
    uint256 public maxAllocation;

    address public owner;
    address public withdrawalAddress;
    address public usdc;

    bool public publicSaleOpen;
    uint256 public totalFund;
    uint256 public hardCap;

    mapping(address => bool) whitelistedAddress;
    mapping(address => uint256) currentPayments;

    constructor(address _usdc, address _withdrawalAddress) {
        owner = msg.sender;

        usdc = _usdc;
        withdrawalAddress = _withdrawalAddress;

        publicSaleOpen = false;

        maxAllocation = 1500_000_000; // 1500 USDC

        hardCap = 45000_000_000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function fillPresale(uint256 amount) public payable {
        require(publicSaleOpen, "Presale not open");
        require(amount <= maxAllocation, "Amount above maximum allocation");
        require(totalFund + amount <= hardCap, "Hardcap");
        IERC20(usdc).transferFrom(msg.sender, address(this), amount);
        currentPayments[msg.sender] += amount;
        totalFund += amount;
    }

    function withdraw() external onlyOwner {
        uint256 amount = IERC20(usdc).balanceOf(address(this));
        IERC20(usdc).transfer(withdrawalAddress, amount);
    }

    function setPresaleStatus(bool _status) external onlyOwner {
        publicSaleOpen = _status;
    }

    function setMaxAllocation(uint256 _maxAllocation) external onlyOwner {
        maxAllocation = _maxAllocation;
    }

    function setHardCap(uint256 _hardCap) external onlyOwner {
        hardCap = _hardCap;
    }

    function getAddressCurrentPayments(address _address) public view returns (uint256) {
        return currentPayments[_address];
    }

}

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