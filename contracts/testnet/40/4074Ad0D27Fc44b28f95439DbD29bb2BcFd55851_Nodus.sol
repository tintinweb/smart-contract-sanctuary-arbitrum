/**
 *Submitted for verification at Arbiscan on 2023-07-11
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/nodus.sol



pragma solidity ^0.8.0;


contract NodusVault is Ownable {
    IERC20 public usdc;

    constructor(address _usdcAddress) {
        usdc = IERC20(_usdcAddress);
    }

    function withdraw(uint _amount) external onlyOwner {
        require(usdc.transfer(owner(), _amount), "Withdrawal failed");
    }
}

contract Nodus is Ownable {
    IERC20 public usdc;
    NodusVault public vault;

    struct Content {
        string id;
        uint price;
        address payable creator;
    }

    struct Membership {
        string id;
        uint price;
        address payable creator;
    }

    mapping(string => Content) public contents;
    mapping(string => Membership) public memberships;
    mapping(address => bool) public registeredUsers;

    uint constant PROCESSING_FEE_PERCENT = 250;

    event PurchaseContent(string contentId, address buyer);
    event PurchaseMembership(string membershipId, address buyer);
    event Donation(string contentId, address donor, uint amount);

    modifier onlyRegisteredUser() {
        require(registeredUsers[msg.sender] == true, "Not a registered user");
        _;
    }

    constructor(address _usdcAddress, address _vaultAddress) {
        usdc = IERC20(_usdcAddress);
        vault = NodusVault(_vaultAddress);
    }

    function registerUser(address _user) external onlyOwner {
        registeredUsers[_user] = true;
    }

    function createContent(string memory _id, uint _price) public onlyOwner {
        require(
            contents[_id].creator == address(0),
            "Content ID already exists"
        );
        contents[_id] = Content(_id, _price, payable(msg.sender));
    }

    function createMembership(string memory _id, uint _price) public onlyOwner {
        require(
            memberships[_id].creator == address(0),
            "Membership ID already exists"
        );
        memberships[_id] = Membership(_id, _price, payable(msg.sender));
    }

    function updateContentPrice(
        string memory _id,
        uint _newPrice
    ) public onlyOwner {
        require(
            contents[_id].creator == msg.sender,
            "Only the content creator can update the price"
        );
        contents[_id].price = _newPrice;
    }

    function updateMembershipPrice(
        string memory _id,
        uint _newPrice
    ) public onlyOwner {
        require(
            memberships[_id].creator == msg.sender,
            "Only the membership creator can update the price"
        );
        memberships[_id].price = _newPrice;
    }

    function deleteContent(string memory _id) public onlyOwner {
        require(
            contents[_id].creator == msg.sender,
            "Only the content creator can delete this content"
        );
        delete contents[_id];
    }

    function deleteMembership(string memory _id) public onlyOwner {
        require(
            memberships[_id].creator == msg.sender,
            "Only the membership creator can delete this membership"
        );
        delete memberships[_id];
    }

    function purchaseContent(string memory _id) public onlyRegisteredUser {
        require(
            usdc.allowance(msg.sender, address(this)) >= contents[_id].price,
            "Not enough USDC allowance"
        );
        _purchaseContent(_id);
    }

    function purchaseMembership(string memory _id) public onlyRegisteredUser {
        require(
            usdc.allowance(msg.sender, address(this)) >= memberships[_id].price,
            "Not enough USDC allowance"
        );
        _purchaseMembership(_id);
    }

    function donateContent(
        string memory _id,
        uint _amount
    ) public onlyRegisteredUser {
        require(
            usdc.allowance(msg.sender, address(this)) >= _amount,
            "Not enough USDC allowance"
        );
        require(contents[_id].creator != address(0), "Content does not exist");
        _donateContent(_id, _amount);
    }

    function _purchaseContent(string memory _id) private {
        _purchase(_id, contents[_id].creator, contents[_id].price);
        emit PurchaseContent(_id, msg.sender);
    }

    function _purchaseMembership(string memory _id) private {
        _purchase(_id, memberships[_id].creator, memberships[_id].price);
        emit PurchaseMembership(_id, msg.sender);
    }

    function _purchase(
        string memory _id,
        address payable _recipient,
        uint _price
    ) private {
        require(
            usdc.transferFrom(msg.sender, address(this), _price),
            "Not enough USDC provided"
        );

        uint fee = (_price * PROCESSING_FEE_PERCENT) / 10000;
        uint amountToRecipient = _price - fee;

        require(
            usdc.transfer(_recipient, amountToRecipient),
            "Transfer to recipient failed"
        );
        require(usdc.transfer(address(vault), fee), "Transfer to vault failed");
    }

    function _donateContent(string memory _id, uint _amount) private {
        _donate(_id, contents[_id].creator, _amount);
        emit Donation(_id, msg.sender, _amount);
    }

    function _donate(
        string memory _id,
        address payable _recipient,
        uint _amount
    ) private {
        require(
            usdc.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        uint fee = (_amount * PROCESSING_FEE_PERCENT) / 10000;
        uint amountToRecipient = _amount - fee;

        require(
            usdc.transfer(_recipient, amountToRecipient),
            "Transfer to recipient failed"
        );
        require(usdc.transfer(address(vault), fee), "Transfer to vault failed");
    }
}