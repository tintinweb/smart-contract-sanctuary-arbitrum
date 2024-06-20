// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract WhitelistPayment is Ownable {
    address public paymentToken; 
    uint256 public paymentAmount = 250 * 10 ** 18; // 250 LPOOL tokens

    mapping(address => bool) public whitelisted;
    address[] public whitelistArray;

    event Whitelisted(address indexed user);
    event PaymentReceived(address indexed user, uint256 amount);
    event TokensWithdrawn(address indexed to, uint256 amount);
    event PaymentAmountChanged(uint256 oldAmount, uint256 newAmount);
    event PaymentTokenChanged(address indexed oldToken, address indexed newToken);

    constructor(address _paymentToken, address _initialOwner) Ownable(_initialOwner) {
        paymentToken = _paymentToken;
    }

    function joinWhitelist() external {
        require(!whitelisted[msg.sender], "Already whitelisted");
        require(IERC20(paymentToken).transferFrom(msg.sender, address(this), paymentAmount), "Payment failed");

        whitelisted[msg.sender] = true;
        whitelistArray.push(msg.sender);

        emit Whitelisted(msg.sender);
        emit PaymentReceived(msg.sender, paymentAmount);
    }

    function exportWhitelist() external view returns (address[] memory) {
        return whitelistArray;
    }

    function exportWhiteListCount() external view returns (uint256) {
        return whitelistArray.length;
    }

    function withdrawTokens(address _to) external onlyOwner {
        uint256 balance = IERC20(paymentToken).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(IERC20(paymentToken).transfer(_to, balance), "Withdraw failed");

        emit TokensWithdrawn(_to, balance);
    }

    function withdrawBalance(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        payable(_to).transfer(balance);
    }

    function changePaymentAmount(uint256 _newAmount) external onlyOwner {
        emit PaymentAmountChanged(paymentAmount, _newAmount);
        paymentAmount = _newAmount;
    }

    function changePaymentToken(address _newToken) external onlyOwner {
        require(_newToken != address(0), "Invalid address");
        emit PaymentTokenChanged(paymentToken, _newToken);
        paymentToken = _newToken;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}