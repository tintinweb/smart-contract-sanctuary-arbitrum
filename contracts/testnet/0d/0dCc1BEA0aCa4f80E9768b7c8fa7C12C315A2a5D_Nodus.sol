/**
 *Submitted for verification at Arbiscan on 2023-06-14
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
contract NodusVault is Ownable {
    IERC20 public usdc;

    constructor(address _usdcAddress) {
        usdc = IERC20(_usdcAddress);
    }

    function withdraw(uint _amount) external onlyOwner {
        require(usdc.transfer(owner(), _amount), "Withdrawal failed");
    }
}
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

    uint constant PROCESSING_FEE_PERCENT = 250; 

    event PurchaseContent(string contentId, address buyer);
    event PurchaseMembership(string membershipId, address buyer);

    constructor(address _usdcAddress, address _vaultAddress) {
        usdc = IERC20(_usdcAddress);
        vault = NodusVault(_vaultAddress);
    }

    function createContent(string memory _id, uint _price) public {
        contents[_id] = Content(_id, _price, payable(msg.sender));
    }

    function createMembership(string memory _id, uint _price) public {
        memberships[_id] = Membership(_id, _price, payable(msg.sender));
    }

    function purchaseContent(string memory _id) public {
        Content memory content = contents[_id];
        uint price = content.price;
        require(usdc.transferFrom(msg.sender, address(this), price), "Not enough USDC provided.");

        uint fee = (price * PROCESSING_FEE_PERCENT) / 10000;
        uint amountToCreator = price - fee;

        require(usdc.transfer(content.creator, amountToCreator), "Transfer to creator failed.");
        require(usdc.transfer(address(vault), fee), "Transfer to vault failed.");

        emit PurchaseContent(_id, msg.sender);
    }

    function purchaseMembership(string memory _id) public {
        Membership memory membership = memberships[_id];
        uint price = membership.price;
        require(usdc.transferFrom(msg.sender, address(this), price), "Not enough USDC provided.");

        uint fee = (price * PROCESSING_FEE_PERCENT) / 10000;
        uint amountToCreator = price - fee;

        require(usdc.transfer(membership.creator, amountToCreator), "Transfer to creator failed.");
        require(usdc.transfer(address(vault), fee), "Transfer to vault failed.");

        emit PurchaseMembership(_id, msg.sender);
    }
}