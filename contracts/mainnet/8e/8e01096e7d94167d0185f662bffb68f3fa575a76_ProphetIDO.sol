// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProphetIDO is Ownable {
    uint256 constant PROPHET_PER_STAGE = 20_000_000_000 ether;
    uint256 constant MINIMUM_PURCHASE = 100_000 ether;

    uint256 public totalSold;
    uint256 public taxFromParticipation;
    uint256 public currentTier;

    mapping(uint256 => Tier) public tiers;
    mapping(address => uint256) public participants;

    IERC20 public prophetToken;

    struct Tier {
        uint256 price; // cost per 100_000 prophet
        uint256 amountSold;
    }

    constructor(address _prophetToken) Ownable(msg.sender) {
        tiers[0] = Tier(312500000000000, 0);
        tiers[1] = Tier(312500000000000 * 2, 0);
        tiers[2] = Tier(312500000000000 * 4, 0);
        tiers[3] = Tier(312500000000000 * 8, 0);
        tiers[4] = Tier(312500000000000 * 16, 0);
        tiers[5] = Tier(312500000000000 * 32, 0);

        prophetToken = IERC20(_prophetToken);

        taxFromParticipation = 25;
    }

    function buyAtTier(uint256 _tokenAmount, uint256 _tier) public payable {
        require(_tier == currentTier, "IDO: Wrong tier");
        require(_tier <= 5, "IDO: Tier Doesn't exist");
        require(MINIMUM_PURCHASE <= _tokenAmount, "IDO: Minimum purchase not met");
        require(_tokenAmount <= PROPHET_PER_STAGE - tiers[_tier].amountSold, "IDO: Wrong tier");
        require((_tokenAmount / MINIMUM_PURCHASE) * tiers[_tier].price == msg.value, "IDO: Wrong amount");

        tiers[_tier].amountSold += _tokenAmount;
        totalSold += _tokenAmount;
        prophetToken.transfer(msg.sender, _tokenAmount);

        participants[msg.sender] = _tier;

        if (tiers[_tier].amountSold == PROPHET_PER_STAGE) {
            currentTier++;
        }

        emit ProphetBought(msg.sender, msg.value, _tokenAmount, _tier);
    }

    function buy(uint256 _tokenAmount) public payable {
        buyAtTier(_tokenAmount, currentTier);
    }

    function addToParticipants(address _sender, address _receiver) external {
        require(msg.sender == address(prophetToken), "IDO: Only ProphetToken can call this function");
        participants[_receiver] = participants[_sender];
    }

    function getUserTaxAmount(address _user) external view returns (uint256 tax) {
        tax = 0;
        if (currentTier > participants[_user]) {
            tax = taxFromParticipation;
        }
    }

    function updateTaxFromParticipation(uint256 _newTax) external onlyOwner {
        taxFromParticipation = _newTax;
        emit TaxUpdated(_newTax);
    }

    function retrieveEther() external onlyOwner {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "IDO: ETH transfer failed");
    }

    event ProphetBought(address indexed buyer, uint256 ethAmount, uint256 tokenAmount, uint256 tier);
    event TaxUpdated(uint256 newTax);
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
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