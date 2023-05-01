// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC20 {
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
}

// BankRoll
contract BankRoll {
    address public owner;
    uint256 private _reEntancyStatus = 1; //Non_Entered
    mapping(address => bool) public whitelistedAddresses;
    /* ========== EVENTS ========== */
    event Withdraw(address indexed withdrawActionBy, address indexed to, uint256 amount);
    event EtherDeposited(address indexed from, uint256 amount);
    event SentWinAmount(address indexed game, address indexed user, uint256 amount);
    event WhitelistStatus(address[] indexed contractAddresses, bool isWhitelisted);

    /* ========== ERRORS ========== */
    error AddressNotWhiteListed(address _inputAddress);
    error CallerIsNotOwner(address _owner);
    error ArrayLengthCantBeZero();
    error ETHTransferFailed(address _to, uint256 _amount);
    error ReEntrantCall();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert CallerIsNotOwner(owner);
        }
        _;
    }

    modifier nonReentrant() {
        if (_reEntancyStatus == 2) {
            revert ReEntrantCall();
        }
        _reEntancyStatus = 2; //Entered
        _;
        _reEntancyStatus = 1;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    function whitelistGames(address[] calldata addresses, bool isWhitelisted) external onlyOwner {
        if (addresses.length == 0) {
            revert ArrayLengthCantBeZero();
        }
        for (uint256 i = 0; i < addresses.length; ) {
            whitelistedAddresses[addresses[i]] = isWhitelisted;
            unchecked {
                ++i;
            }
        }
        emit WhitelistStatus(addresses, isWhitelisted);
    }

    function sendWinAmount(address user, uint256 amount) external {
        if (!whitelistedAddresses[msg.sender]) {
            revert AddressNotWhiteListed(msg.sender);
        }
        _withdrawEther(user, amount);
        emit SentWinAmount(msg.sender, user, amount);
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

    function _withdrawEther(address user, uint256 amount) internal {
        (bool sent, ) = payable(user).call{value: amount}('');
        if (!sent) {
            revert ETHTransferFailed(user, amount);
        }
    }
}