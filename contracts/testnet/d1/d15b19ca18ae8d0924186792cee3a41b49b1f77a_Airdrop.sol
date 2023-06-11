/**
 *Submitted for verification at Arbiscan on 2023-06-10
*/

// SPDX-License-Identifier: MIT
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract Airdrop is Ownable {
    string public name = "BullBear AI: Airdrop Vesting";

    struct User {
        bool isClaimed;
        bool isWhitelisted;
        
       
    }

    mapping(address => User) public users;

    uint256 public MAX_PER_ADDRESS;
    uint256 public totalClaimed;

    uint256 public startClaim;
    uint256 public endClaim;
    uint256 public claimFee = 20;

    IERC20 public token;
    address treasuryWallet;

    event TokensClaimed(address indexed user, uint256 amount);
    event Burn(uint256 amount);

    constructor(
        address _tokenAddress,
        uint256 _maxperaddress,
        uint256 _startClaim,
        uint256 _endClaim,
        address _treasuryWallet
    ) {
        token = IERC20(_tokenAddress);

        MAX_PER_ADDRESS = _maxperaddress;

        startClaim = _startClaim;
        endClaim = _endClaim;
        treasuryWallet = _treasuryWallet;
    }

    function whitelistUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            users[_users[i]].isWhitelisted = true;
        }
    }

    function changeEndTime(uint256 _endTime) public onlyOwner {
        endClaim = _endTime;
    }

    function changeStartClaim(uint256 _startClaim) public onlyOwner {
        startClaim = _startClaim;
    }

    function changeClaimFee(uint256 _fee) public onlyOwner {
        claimFee = _fee;
    }

    function claimTokens() public {
        User storage user = users[msg.sender];
        require(user.isWhitelisted, "User is not whitelisted");
        require(!user.isClaimed, "User already claimed");
        require(
            block.timestamp > startClaim && block.timestamp < endClaim,
            "Claim has not start yet !"
        );

        uint256 tokensToClaim = MAX_PER_ADDRESS;
        uint256 feeClaim = (tokensToClaim * claimFee) / 100;

        token.transfer(msg.sender, tokensToClaim - feeClaim);

        token.transfer(treasuryWallet, feeClaim);

        totalClaimed += tokensToClaim;
        user.isClaimed = true;
       
        emit TokensClaimed(msg.sender, tokensToClaim);
    }

    function withdrawTokens(uint256 _amount) public onlyOwner {
        require(
            token.balanceOf(address(this)) >= _amount,
            "Not enough tokens in contract"
        );
        require(token.transfer(msg.sender, _amount), "Token transfer failed");
    }
}