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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IMarketMakerOperator {
    function depositTokens(uint256 amount, address user) external;
}

interface SHStaking {
    function stakeAs(uint256 _amount, address _to) external;
}

contract SHVestingCliff is Ownable, ReentrancyGuard {
    uint256 public constant VESTING_DIVIDER = 100000;
    uint256 public constant YEAR_DIVIDER = 31556952;

    struct Config {
        uint256 tgeDate;
        uint256 startDate;
        uint256 endDate;
        IERC20 token;
        uint256 ethClaimFee;
        uint256 ethClaimAndStakeFee;
        uint256 ethMMFee;
    }

    Config public config;
    IMarketMakerOperator marketMakerOperator;
    SHStaking shStaking;

    uint public tgePercent;

    mapping(address => uint256) public tokensReleased;
    mapping(address => uint256) public userTotal;
    mapping(address => bool) public freezeUsers;

    event TokensReleased(uint256 amount, address user);
    event Withdraw(address user, uint256 amount);
    event WithdrawEth(address user, uint256 amount);
    event UpdateFee(uint256 newFee, uint256 oldFee);
    event UpdateStaking(address newStaking);
    event UpdateMM(address newMM);
    event FreezeAccount(address indexed user, bool freeze);
    event TokensReleasedToStake(uint256 amount, address user);
    event TokensReleasedToMM(uint256 amount, address user);

    error TransferFailed();
    error WithdrawFailed();

    modifier checkEthFeeAndRefundDust(uint256 value, uint256 expectedFee) {
        require(value >= expectedFee, "Insufficient fee: the required fee must be covered");
        uint256 dust = unsafeSub(value, expectedFee);
        if (dust != 0) {
            (bool sent,) = address(msg.sender).call{value : dust}("");
            require(sent, "Failed to return overpayment");
        }
        _;
    }

    modifier accountNotFrozen() {
        require(!freezeUsers[msg.sender], "Account frozen");
        _;
    }

    constructor(
        uint256 _tgeDate,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress,
        uint256 _ethClaimFee,
        uint256 _ethStakeFee,
        uint256 _ethMMFee,
        uint256 _tgePercent
    ) {
        require(_startTime >= _tgeDate, "Start time must be greater than tge time");
        require(_endTime > _startTime, "End time must be greater than start time");
        require(_tokenAddress != address(0), "Token address cannot be zero address");

        config.tgeDate = _tgeDate;
        config.startDate = _startTime;
        config.endDate = _endTime;
        config.token = IERC20(_tokenAddress);
        config.ethClaimFee = _ethClaimFee;
        config.ethClaimAndStakeFee = _ethStakeFee;
        config.ethMMFee = _ethMMFee;
        tgePercent = _tgePercent;
    }

    function release() external payable nonReentrant accountNotFrozen checkEthFeeAndRefundDust(msg.value, config.ethClaimFee) {
        uint256 unreleased = releasableAmount(msg.sender);
        require(unreleased != 0, "No tokens to release");
        require(msg.value >= config.ethClaimFee, "Insufficient fee: the required fee must be covered");

        tokensReleased[msg.sender] = tokensReleased[msg.sender] + unreleased;
        if (
            !config.token.transfer(msg.sender, unreleased)
        ) {
            revert TransferFailed();
        }

        emit TokensReleased(unreleased, msg.sender);
    }

    function releaseToMM() external payable nonReentrant accountNotFrozen checkEthFeeAndRefundDust(msg.value, config.ethMMFee) {
        uint256 unreleased = releasableAmount(msg.sender);
        require(unreleased != 0, "No tokens to release");
        require(address(marketMakerOperator) != address(0), "Address not defined");
        require(msg.value >= config.ethMMFee, "Insufficient fee: the required fee must be covered");

        tokensReleased[msg.sender] = tokensReleased[msg.sender] + unreleased;
        config.token.approve(address(marketMakerOperator), unreleased);
        marketMakerOperator.depositTokens(unreleased, msg.sender);

        emit TokensReleasedToMM(unreleased, msg.sender);
    }

    function releaseToStake() external payable nonReentrant accountNotFrozen checkEthFeeAndRefundDust(msg.value, config.ethClaimAndStakeFee) {
        uint256 unreleased = releasableAmount(msg.sender);
        require(unreleased != 0, "No tokens to release");
        require(msg.value >= config.ethClaimAndStakeFee, "Insufficient fee: the required fee must be covered");

        tokensReleased[msg.sender] = tokensReleased[msg.sender] + unreleased;
        config.token.approve(address(shStaking), unreleased);
        shStaking.stakeAs(unreleased, msg.sender);

        emit TokensReleasedToStake(unreleased, msg.sender);
    }

    function releasableAmount(address userAddress) public view returns (uint256) {
        if (freezeUsers[userAddress]) {
            return 0;
        }

        if (block.timestamp < config.tgeDate) {
            return 0;
        }

        uint256 totalTokens = userTotal[userAddress];
        uint256 tgeTokens = totalTokens * tgePercent / VESTING_DIVIDER;

        if (block.timestamp < config.startDate) {
            return tgeTokens - tokensReleased[userAddress];
        }

        if (block.timestamp > config.endDate) {
            return totalTokens - tokensReleased[userAddress];
        }

        uint256 vestingPartTokens = totalTokens - tgeTokens;
        uint256 elapsedTime = block.timestamp - config.startDate;
        uint256 totalVestingTime = config.endDate - config.startDate;
        uint256 vestedAmount = vestingPartTokens * elapsedTime / totalVestingTime;
        return vestedAmount + tgeTokens < tokensReleased[userAddress] ? 0 : vestedAmount + tgeTokens - tokensReleased[userAddress];
    }

    function withdrawToken(IERC20 token, uint256 amount) external onlyOwner {

        if (
            !token.transfer(msg.sender, amount)
        ) {
            revert TransferFailed();
        }

        emit Withdraw(msg.sender, amount);
    }

    function withdrawEth(uint256 amount) external onlyOwner {

        require(address(this).balance >= amount, "Insufficient balance");
        (bool success,) = payable(msg.sender).call{value : amount}("");
        if (!success) {
            revert WithdrawFailed();
        }
        emit WithdrawEth(msg.sender, amount);
    }

    function updateEthClaimFee(uint256 _newFee) external onlyOwner {

        uint256 oldFee = config.ethClaimFee;
        config.ethClaimFee = _newFee;
        emit UpdateFee(_newFee, oldFee);
    }

    function updateEthClaimAndStakeFee(uint256 _newFee) external onlyOwner {

        uint256 oldFee = config.ethClaimAndStakeFee;
        config.ethClaimAndStakeFee = _newFee;
        emit UpdateFee(_newFee, oldFee);
    }

    function updateEthMMFee(uint256 _newFee) external onlyOwner {

        uint256 oldFee = config.ethMMFee;
        config.ethMMFee = _newFee;
        emit UpdateFee(_newFee, oldFee);
    }

    function updateShStaking(address _shStaking) external onlyOwner {

        shStaking = SHStaking(_shStaking);
        emit UpdateStaking(_shStaking);
    }

    function updateMMAddress(address _mm) external onlyOwner {

        emit UpdateStaking(_mm);
    }

    function registerVestingAccounts(address[] memory _userAddresses, uint256[] memory _amounts) external onlyOwner {
        require(_amounts.length == _userAddresses.length, "Amounts and userAddresses must have the same length");

        for (uint i; i < _userAddresses.length; i = unsafeInc(i)) {
            userTotal[_userAddresses[i]] = _amounts[i];
        }
    }

    function freezeVestingAccounts(address[] memory _userAddresses, bool _freeze) external onlyOwner {
        for (uint i; i < _userAddresses.length; i = unsafeInc(i)) {
            freezeUsers[_userAddresses[i]] = _freeze;
            emit FreezeAccount(_userAddresses[i], _freeze);
        }
    }

    function unsafeInc(uint x) private pure returns (uint) {
    unchecked {return x + 1;}
    }

    function unsafeSub(uint x, uint y) private pure returns (uint) {
    unchecked {return x - y;}
    }
}