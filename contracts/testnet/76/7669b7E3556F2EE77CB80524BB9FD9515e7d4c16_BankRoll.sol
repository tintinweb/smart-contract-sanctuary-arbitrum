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

pragma solidity ^0.8.18;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// BankRoll
contract BankRoll {
    address public owner;
    uint256 private _reEntancyStatus = 1; //Non_Entered
    mapping(address => bool) public whitelistedAddresses;
    /* ========== EVENTS ========== */
    event Withdraw(address indexed withdrawActionBy, address indexed to, uint256 amount);
    event EtherDeposited(address indexed from, uint256 amount);
    event SentWinAmount(address indexed game, address indexed player, uint256 amount);
    event WhitelistStatus(address[] indexed contractAddresses, bool isWhitelisted);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Sender is not owner');
        _;
    }

    modifier nonReentrant() {
        require(_reEntancyStatus != 2, 'ReentrancyGuard: reentrant call');
        _reEntancyStatus = 2; //Entered
        _;
        _reEntancyStatus = 1;
    }

    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    function whitelistGames(address[] calldata addresses, bool isWhitelisted) external onlyOwner {
        require(addresses.length != 0, 'CoinFlip: Addresses length should be greater than 0');
        for (uint256 i = 0; i < addresses.length; ) {
            whitelistedAddresses[addresses[i]] = isWhitelisted;
            unchecked {
                ++i;
            }
        }
        emit WhitelistStatus(addresses, isWhitelisted);
    }

    function sendWinAmount(address player, uint256 amount) external onlyOwner {
        require(whitelistedAddresses[msg.sender], 'BankRoll: Address not whitelisted');
        _withdrawEther(player, amount);
        emit SentWinAmount(msg.sender, player, amount);
    }

    /// Withdraw any IERC20 tokens accumulated in this contract
    function withdrawTokens(IERC20 _token) external onlyOwner nonReentrant {
        _token.transfer(owner, _token.balanceOf(address(this)));
    }

    /// Withdraw Ether accumulated in this contract
    function withdrawEther(address to, uint256 amount) external onlyOwner nonReentrant {
        _withdrawEther(to, amount);
        emit Withdraw(msg.sender, to, amount);
    }

    function _withdrawEther(address player, uint256 amount) internal {
        (bool sent, bytes memory data) = payable(player).call{value: amount}('');
        string memory response = string(data);
        require(sent, response);
    }
}