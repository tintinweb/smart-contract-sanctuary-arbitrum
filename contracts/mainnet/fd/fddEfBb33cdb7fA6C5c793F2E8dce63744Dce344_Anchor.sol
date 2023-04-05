// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external returns (uint);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Anchor is Ownable {
    IERC20 public volt;
    mapping(address => bool) public allowedTokens;
    address public treasury;
    uint public mintFees = 5;
    uint public redeemFees = 5;


    constructor(address _volt, address _treasury) {
        treasury = _treasury;
        volt = IERC20(_volt);
    }

    function mint(uint256 amount, address input) external {
        require(allowedTokens[input], "!allowed");
        IERC20(input).transferFrom(msg.sender, address(this), amount);
        uint256 fee = amount * mintFees / 1000;
        uint256 amountAfterFee = amount - fee;
        uint256 decimals = IERC20(input).decimals();
        uint256 voltAmount = amountAfterFee * 10 ** uint256(volt.decimals()) / 10 ** decimals;
        volt.transfer(msg.sender, voltAmount);
        IERC20(input).transfer(treasury, fee);
    }

    function redeem(uint256 amount, address output) external {
        require(allowedTokens[output], "!allowed");
        uint256 decimals = IERC20(output).decimals();
        uint256 voltAmount = amount * 10 ** uint256(volt.decimals()) / 10 ** decimals;
        volt.transferFrom(msg.sender, address(this), voltAmount);
        uint256 fee = amount * redeemFees / 1000;
        uint256 amountAfterFee = amount - fee;
        IERC20(output).transfer(msg.sender, amountAfterFee);
        IERC20(output).transfer(treasury, fee);
    }

    function changeTreasury(address _new) external onlyOwner {
        treasury = _new;
    }

    function changeFees(uint _mint, uint _redeem) external onlyOwner {
        mintFees = _mint;
        redeemFees = _redeem;
    }

    function allowToken(address _token, bool _isAllowed) external onlyOwner {
        allowedTokens[_token] = _isAllowed;
    }
}