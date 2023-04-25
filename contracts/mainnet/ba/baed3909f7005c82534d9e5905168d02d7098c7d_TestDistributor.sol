/**
 *Submitted for verification at Arbiscan on 2023-04-25
*/

// SPDX-License-Identifier: MIT AND Apache-2.0
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


pragma solidity 0.8.18;

/// @notice increments an integer without checking for overflows
/// @dev from https://github.com/ethereum/solidity/issues/11721#issuecomment-890917517
function uncheckedInc(uint256 x) pure returns (uint256) {
    unchecked {
        return x + 1;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity 0.8.18;


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



/// @title  Token Distributor
/// @notice Holds tokens for users to claim.
/// @dev    Unlike a merkle distributor this contract uses storage to record claims rather than a
///         merkle root. This is because calldata on Arbitrum is relatively expensive when compared with
///         storage, since calldata uses L1 gas.
///         After construction do the following
///         1. transfer tokens to this contract
///         2. setRecipients - called as many times as required to set all the recipients
///         3. transferOwnership - the ownership of the contract should be transferred to a new owner (eg DAO) after all recipients have been set
contract TestDistributor is Ownable {
    /// @notice Token to be distributed
    IERC20 public immutable token;
    /// @notice Address to receive tokens that were not claimed
    address payable public sweepReceiver;
    /// @notice amount of tokens that can be claimed by address
    mapping(address => uint256) public claimableTokens;
    /// @notice Total amount of tokens claimable by recipients of this contract
    uint256 public totalClaimable;
    /// @notice Block number at which claiming starts
    uint256 public claimPeriodStart;
    /// @notice Block number at which claiming ends
    uint256 public claimPeriodEnd;

    /// @notice recipient can claim this amount of tokens
    event CanClaim(address indexed recipient, uint256 amount);
    /// @notice recipient has claimed this amount of tokens
    event HasClaimed(address indexed recipient, uint256 amount);
    /// @notice leftover tokens after claiming period have been swept
    event Swept(uint256 amount);
    /// @notice new address set to receive unclaimed tokens
    event SweepReceiverSet(address indexed newSweepReceiver);
    /// @notice Tokens withdrawn
    event Withdrawal(address indexed recipient, uint256 amount);
    event ClaimPeriodStartSet(uint256 indexed newClaimPeriodStart);
    event ClaimPeriodEndSet(uint256 indexed newClaimPeriodEnd);

    constructor(
        IERC20 _token,
        address payable _sweepReceiver,
        address _owner
    ) Ownable() {
        require(address(_token) != address(0), "TokenDistributor: zero token address");
        require(_sweepReceiver != address(0), "TokenDistributor: zero sweep address");
        require(_owner != address(0), "TokenDistributor: zero owner address");
        token = _token;
        _setSweepReciever(_sweepReceiver);
        _transferOwnership(_owner);
    }

    function setClaimPeriod(uint256 _claimPeriodStart, uint256 _claimPeriodEnd) external onlyOwner {
        _setClaimPeriod(_claimPeriodStart, _claimPeriodEnd);
    }

    function _setClaimPeriod(uint256 _claimPeriodStart, uint256 _claimPeriodEnd) internal {
        require(_claimPeriodStart > block.number, "TokenDistributor: start should be in the future");
        require(_claimPeriodEnd > _claimPeriodStart, "TokenDistributor: start should be before end");  
        claimPeriodStart = _claimPeriodStart;
        claimPeriodEnd = _claimPeriodEnd;
        emit ClaimPeriodStartSet(_claimPeriodStart);
        emit ClaimPeriodEndSet(_claimPeriodEnd);
    }

    /// @notice Allows owner to update address of sweep receiver
    function setSweepReciever(address payable _sweepReceiver) external onlyOwner {
        _setSweepReciever(_sweepReceiver);
    }

    function _setSweepReciever(address payable _sweepReceiver) internal {
        require(_sweepReceiver != address(0), "TokenDistributor: zero sweep receiver address");
        sweepReceiver = _sweepReceiver;
        emit SweepReceiverSet(_sweepReceiver);
    }

    /// @notice Allows owner of the contract to withdraw tokens
    /// @dev A safety measure in case something goes wrong with the distribution
    function withdraw(uint256 amount) external onlyOwner {
        require(token.transfer(msg.sender, amount), "TokenDistributor: fail transfer token");
        emit Withdrawal(msg.sender, amount);
    }

    function getblocknumber() public view returns (uint256) {
        return block.number;
    }


    /// @notice Allows owner to set a list of recipients to receive tokens
    /// @dev This may need to be called many times to set the full list of recipients
    function setRecipients(address[] calldata _recipients, uint256[] calldata _claimableAmount)
        external
        onlyOwner
    {
        require(
            _recipients.length == _claimableAmount.length, "TokenDistributor: invalid array length"
        );
        uint256 sum = totalClaimable;
        for (uint256 i = 0; i < _recipients.length; i++) {
            // sanity check that the address being set is consistent
            require(claimableTokens[_recipients[i]] == 0, "TokenDistributor: recipient already set");
            claimableTokens[_recipients[i]] = _claimableAmount[i];
            emit CanClaim(_recipients[i], _claimableAmount[i]);
            unchecked {
                sum += _claimableAmount[i];
            }
        }

        // sanity check that the current has been sufficiently allocated
        require(token.balanceOf(address(this)) >= sum, "TokenDistributor: not enough balance");
        totalClaimable = sum;
    }

    /// @notice Claim and delegate in a single call
    /// @dev Different implementations may handle validation/fail delegateBySig differently. here a OZ v4.6.0 impl is assumed
    /// @dev delegateBySig by OZ does not support `IERC1271`, so smart contract wallets should not use this method
    /// @dev delegateBySig is used so that the token contract doesn't need to contain any claiming functionality


    /// @notice Sends any unclaimed funds to the sweep reciever once the claiming period is over
    function sweep() external {
        //require(block.number >= claimPeriodEnd, "TokenDistributor: not ended");
        uint256 leftovers = token.balanceOf(address(this));
        require(leftovers != 0, "TokenDistributor: no leftovers");

        require(token.transfer(sweepReceiver, leftovers), "TokenDistributor: fail token transfer");

        emit Swept(leftovers);

        // contract is destroyed to clean up storage
        // selfdestruct(payable(sweepReceiver));
    }

    /// @notice Allows a recipient to claim their tokens
    /// @dev Can only be called during the claim period
    function claim() public {
        require(block.number >= claimPeriodStart, "TokenDistributor: claim not started");
        require(block.number < claimPeriodEnd, "TokenDistributor: claim ended");

        uint256 amount = claimableTokens[msg.sender];
        require(amount > 0, "TokenDistributor: nothing to claim");

        claimableTokens[msg.sender] = 0;

        // we don't use safeTransfer since impl is assumed to be OZ
        require(token.transfer(msg.sender, amount), "TokenDistributor: fail token transfer");
        emit HasClaimed(msg.sender, amount);
    }
}