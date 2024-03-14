/**
 *Submitted for verification at Arbiscan.io on 2024-03-14
*/

/**
 *Submitted for verification at Arbiscan.io on 2024-02-23
*/

/**
 *Submitted for verification at Arbiscan.io on 2023-05-15
 */

/*
────────────────────────────────────────────────────────────────────────────
─██████████████─██████──██████─██████████████─██████████████─██████████████─
─██░░░░░░░░░░██─██░░██──██░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─
─██░░██████████─██░░██──██░░██─██░░██████░░██─██░░██████████─██████░░██████─
─██░░██─────────██░░██──██░░██─██░░██──██░░██─██░░██─────────────██░░██─────
─██░░██─────────██░░██████░░██─██░░██████░░██─██░░██████████─────██░░██─────
─██░░██──██████─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─────██░░██─────
─██░░██──██░░██─██░░██████░░██─██░░██████░░██─██████████░░██─────██░░██─────
─██░░██──██░░██─██░░██──██░░██─██░░██──██░░██─────────██░░██─────██░░██─────
─██░░██████░░██─██░░██──██░░██─██░░██──██░░██─██████████░░██─────██░░██─────
─██░░░░░░░░░░██─██░░██──██░░██─██░░██──██░░██─██░░░░░░░░░░██─────██░░██─────
─██████████████─██████──██████─██████──██████─██████████████─────██████─────
────────────────────────────────────────────────────────────────────────────
https://ghastprotocol.com/
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: esGHARedeem.sol

pragma solidity ^0.8.19;

contract GHARFVRedemption {

    // 1 token for 2.71 USDC = 1e18/2.71e6
    uint256 public ghaPerUsdc = 369000000000;

    // USDC.e
    IERC20 public USDC = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    IERC20 public GHA = IERC20(0xeCA66820ed807c096e1Bd7a1A091cD3D3152cC79);
    IERC20 public esGHA = IERC20(0x3129F42a1b574715921cb65FAbB0F0f9bd8b4f39);

    // gas maxi
    constructor() payable {}

    modifier onlyOwner() {
        require(msg.sender == 0xe7c48B9DD485Efa6bEf7831B562DDd6C10aEef95);
        _;
    }

    function redeemGHA() external {
        uint256 amount = GHA.balanceOf(msg.sender);
        GHA.transferFrom(msg.sender, address(this), amount);
        USDC.transfer(msg.sender, amount / ghaPerUsdc);
    }
    function redeemEsGHA() external {
        uint256 amount = esGHA.balanceOf(msg.sender);
        esGHA.transferFrom(msg.sender, address(this), amount);
        USDC.transfer(msg.sender, amount / ghaPerUsdc);
    }

    function changePrice(uint256 _ghaPerUsdc) external payable onlyOwner {
        ghaPerUsdc = _ghaPerUsdc;
    }

    function yoink(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external payable onlyOwner {
        _token.transfer(_to, _amount);
    }
}