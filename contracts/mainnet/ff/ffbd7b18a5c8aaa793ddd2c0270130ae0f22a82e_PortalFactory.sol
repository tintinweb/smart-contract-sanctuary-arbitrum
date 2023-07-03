//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IArbipad.sol";
import "../interface/IRefundController.sol";
import "./Portal.sol";

/**
 * @dev Contract module to deploy a portal automatically
 */
contract PortalFactory is Ownable {
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    address public immutable REFUND_CONTROLLER;

    /**
     * @dev Emitted when launchPortal function is succesfully called and a portal for token claim is created
     */
    event PortalCreation(
        uint256 indexed timestamp,
        Portal indexed portalAddress,
        address indexed tokenAddress,
        string tokenName,
        string portalName,
        address[] fundingPool,
        uint256 tokenPrice,
        uint256 vestingAllocInBps,
        uint256 tokenAmount,
        string imgUrl
    );

    constructor(address _REFUND_CONTROLLER) {
        REFUND_CONTROLLER = _REFUND_CONTROLLER;
    }

    /**
     * @dev Create a portal.
     * Note: input Vesting Alloc in bips, e.g 10% => 1000, 20% => 2000
     * emits a {PortalCreation} event
     */
    function launchPortal(
        string memory _tokenName,
        string memory _portalName,
        address _tokenAddress,
        address[] memory _fundingPool,
        uint256 _tokenPrice,
        uint256 _vestingAllocInBps,
        uint256 _claimableAt,
        string memory _imgUrl
    ) public onlyOwner {
        Portal _portal;
        _portal = new Portal(
            owner(),
            _portalName,
            _tokenAddress,
            REFUND_CONTROLLER,
            _fundingPool,
            _tokenPrice,
            _vestingAllocInBps,
            _claimableAt
        );

        uint256 _tokenAmount = _calculateTokenAmount(_fundingPool, _tokenAddress, _tokenPrice, _vestingAllocInBps);
        IERC20 _ERC20Interface = IERC20(_tokenAddress);
        _ERC20Interface.transferFrom(msg.sender, address(_portal), _tokenAmount);

        IRefundController(REFUND_CONTROLLER).openRefundWindow(_claimableAt, _tokenAddress, _fundingPool);
        IRefundController(REFUND_CONTROLLER).grantRole(keccak256("ADMIN_ROLE"),address(_portal));

        emit PortalCreation(
            block.timestamp,
            _portal,
            _tokenAddress,
            _tokenName,
            _portalName,
            _fundingPool,
            _tokenPrice,
            _vestingAllocInBps,
            _tokenAmount,
            _imgUrl
        );
    }

    /**
     * @dev Calculate amount of token to be transferred, based on the total raised fund in pool & vesting bps. Handling the decimals too!
     * @return Claimable token
     */
    function _calculateTokenAmount(
        address[] memory _fundingPool,
        address _tokenAddress,
        uint256 _tokenPrice,
        uint256 _vestingAllocInBps
    ) private view returns (uint256) {
        uint256 _bpsDivisor = 10000;
        address _fundingToken = IArbipad(_fundingPool[0]).tokenAddress();
        uint256 _fundingTokenDecimals = safeDecimals(_fundingToken);
        uint256 _vestingTokenDecimals = safeDecimals(_tokenAddress);
        uint256 _denominator = 10**_vestingTokenDecimals;

        uint256 _totalRaisedFund;
        for (uint256 i = 0; i < _fundingPool.length; i++) {
            _totalRaisedFund += IArbipad(_fundingPool[i]).totalRaisedFundInAllTier();
        }

        uint256 _refunded = IRefundController(REFUND_CONTROLLER).totalRefundedAmount(_tokenAddress);
        uint256 _finalRaisedFund = _totalRaisedFund - _refunded;

        if (_fundingTokenDecimals == _vestingTokenDecimals) {
            return FullMath.mulDiv((_finalRaisedFund * _vestingAllocInBps) / _bpsDivisor, _denominator, _tokenPrice);
        } else if (_fundingTokenDecimals < _vestingTokenDecimals) {
            uint256 _totalRaisedFundAdj = _finalRaisedFund * 10**(_vestingTokenDecimals - _fundingTokenDecimals);
            return FullMath.mulDiv((_totalRaisedFundAdj * _vestingAllocInBps) / _bpsDivisor, _denominator, _tokenPrice);
        } else {
            uint256 _totalRaisedFundAdj = _finalRaisedFund / 10**(_fundingTokenDecimals - _vestingTokenDecimals);
            return FullMath.mulDiv((_totalRaisedFundAdj * _vestingAllocInBps) / _bpsDivisor, _denominator, _tokenPrice);
        }
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param _token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(address _token) private view returns (uint8) {
        (bool success, bytes memory data) = address(_token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }
}

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArbipad {
    struct User {
        uint256 tier;
        uint256 totalAllocation;
    }

    function userInfo(address _address) external view returns (User memory);

    function tokenAddress() external view returns (address);

    function totalRaisedFundInAllTier() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRefundController {
    function totalRefundedAmount(address _tokenAddress) external view returns (uint256);

    function openRefundWindow(
        uint256 _claimableAt,
        address _tokenAddress,
        address[] memory _fundingPools
    ) external;

    function eligibleForRefund(address _userAllocation, address _tokenAddress) external view returns (uint256);

    function updateUserEligibility(address _userAllocation, address _tokenAddress, uint256 _eligibility) external; 

    function windowCloseUntil(address _tokenAddress) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interface/IArbipad.sol";
import "../interface/FullMath.sol";
import "../interface/IRefundController.sol";

contract Portal is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    address public immutable REFUND_CONTROLLER;

    IERC20 _ERC20Interface;

    string public name;
    address[] public fundingPool;
    address public tokenAddress;
    uint256 public tokenPrice;
    uint256 public vestingAllocInBps;
    uint256 public claimableAt;
    mapping(address => bool) private _claimed;
    bool public refundClaimed;

    event ClaimToken(uint256 indexed timestamp, address indexed initiator, address indexed tokenAddress, uint256 value);

    constructor(
        address portalOwner,
        string memory _name,
        address _tokenAddress,
        address _REFUND_CONTROLLER,
        address[] memory _fundingPool,
        uint256 _tokenPrice,
        uint256 _vestingAllocInBps,
        uint256 _claimableAt
    ) {
        require(portalOwner != address(0), "Zero project owner address");
        require(_tokenAddress != address(0), "Zero token address");
        require(_fundingPool.length > 0, "Invalid input fundingPool");
        REFUND_CONTROLLER = _REFUND_CONTROLLER;
        transferOwnership(portalOwner);
        name = _name;
        tokenAddress = _tokenAddress;
        fundingPool = _fundingPool;
        tokenPrice = _tokenPrice;
        vestingAllocInBps = _vestingAllocInBps;
        claimableAt = _claimableAt;
        _ERC20Interface = IERC20(tokenAddress);
    }

    /**
     * @dev Claim the token.
     *
     * emits a {ClaimToken} event
     */
    function claimToken() external whenNotPaused nonReentrant {
        require(block.timestamp >= claimableAt, "Not Claimable yet!");
        uint256 _tokenAmount = _calculateClaimableToken(msg.sender);
        require(_tokenAmount > 0, "Zero Allocation!");
        require(!_claimed[msg.sender], "Claimed!");
        uint256 _isRefund = IRefundController(REFUND_CONTROLLER).eligibleForRefund(msg.sender, tokenAddress);
        require(_isRefund != 1, "Requested for refund!");

        _ERC20Interface.safeTransfer(msg.sender, _tokenAmount);
        _claimed[msg.sender] = true;

        // update in refund contract about user already claimt he token
        IRefundController(REFUND_CONTROLLER).updateUserEligibility(msg.sender, tokenAddress, 2);
        emit ClaimToken(block.timestamp, msg.sender, tokenAddress, _tokenAmount);
    }

    /**
     * @dev Claim refunded token
     *
     */
    function claimRefundedToken() external onlyOwner {
        uint256 windowClose = IRefundController(REFUND_CONTROLLER).windowCloseUntil(tokenAddress);
        require(block.timestamp >= windowClose, "Refund window still open");
        require(!refundClaimed, "Refund claimed!");
        uint256 totalRefundedAmount = IRefundController(REFUND_CONTROLLER).totalRefundedAmount(tokenAddress);
        address _fundingToken = IArbipad(fundingPool[0]).tokenAddress();
        uint256 _fundingTokenDecimals = safeDecimals(_fundingToken);
        uint256 _vestingTokenDecimals = safeDecimals(tokenAddress);
        uint256 _denominator = 10**_vestingTokenDecimals;
        uint256 _bpsDivisor = 10000;

        // Convert to token amount
        uint256 tokenAmount;
        if (_fundingTokenDecimals == _vestingTokenDecimals) {
            tokenAmount = FullMath.mulDiv((totalRefundedAmount * vestingAllocInBps) / _bpsDivisor, _denominator, tokenPrice);
        } else if (_fundingTokenDecimals < _vestingTokenDecimals) {
            uint256 totalRefundedAmountAdj = totalRefundedAmount * 10**(_vestingTokenDecimals - _fundingTokenDecimals);
            tokenAmount = FullMath.mulDiv((totalRefundedAmountAdj * vestingAllocInBps) / _bpsDivisor, _denominator, tokenPrice);
        } else {
            uint256 totalRefundedAmountAdj = totalRefundedAmount / 10**(_fundingTokenDecimals - _vestingTokenDecimals);
            tokenAmount = FullMath.mulDiv((totalRefundedAmountAdj * vestingAllocInBps) / _bpsDivisor, _denominator, tokenPrice);
        }

        _ERC20Interface.safeTransfer(msg.sender, tokenAmount);
        refundClaimed = true;
    }

    /**
     * @dev Claim all the token if something went wrong within this contract.
     *
     */
    function sweep() external onlyOwner whenPaused {
        uint256 _tokenBalance = _ERC20Interface.balanceOf(address(this));
        _ERC20Interface.safeTransfer(msg.sender, _tokenBalance);
    }

    /**
     * @dev Pause the contract
     *
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev UnPause the contract
     *
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Retrive current Token Balance
     * @return Token Balance
     */
    function balanceOfToken() external view returns (uint256) {
        return _ERC20Interface.balanceOf(address(this));
    }

    /**
     * @dev Current user's status
     * @param _address, User's address
     * @return User's status
     */
    function isClaimed(address _address) external view returns (bool) {
        return _claimed[_address];
    }

    /**
     * @dev Retrive user's pool allocation.
     * @param _address, User's address
     * @return User's pool allocation info
     */
    function userAllocation(address _address) external view returns (uint256) {
        return _userAllocation(_address);
    }

    /**
     * @dev Retrive amount of token that can be claimed, based on the user's pool allocation.
     * @param _address, User's address
     * @return Claimable token
     */
    function claimableTokenAmount(address _address) external view returns (uint256) {
        return _calculateClaimableToken(_address);
    }

    /**
     * @dev Retrive user in pool.
     * @param _address, User's address
     * @return User's pool info
     */
    // function userInfo(address _address) public view returns (IArbipad.User[] memory) {
    function userInfo(address _address) external view returns (IArbipad.User[] memory) {
        IArbipad.User[] memory _userInPool = new IArbipad.User[](fundingPool.length);
        for (uint256 i; i < fundingPool.length; i++) {
            IArbipad _arbipadInterface = IArbipad(fundingPool[i]);
            _userInPool[i] = _arbipadInterface.userInfo(_address);
        }
        // return _userInPool;
        return _userInPool;
    }

    /**
     * @dev Retrive user's pool allocation.
     * @param _address, User's address
     * @return User's pool allocation info
     */
    function _userAllocation(address _address) private view returns (uint256) {
        uint256 totalAllocation;
        for (uint256 i; i < fundingPool.length; i++) {
            IArbipad _arbipadInterface = IArbipad(fundingPool[i]);
            totalAllocation += _arbipadInterface.userInfo(_address).totalAllocation;
        }
        return totalAllocation;
    }

    /**
     * @dev Calculate amount of token that can be claimed, based on the pool allocation & vesting bps. Handling the decimals too!
     * @return Claimable token
     */
    function _calculateClaimableToken(address _address) private view returns (uint256) {
        uint256 _bpsDivisor = 10000;
        address _fundingToken = IArbipad(fundingPool[0]).tokenAddress();
        uint256 _fundingTokenDecimals = safeDecimals(_fundingToken);
        uint256 _vestingTokenDecimals = safeDecimals(tokenAddress);
        uint256 _denominator = 10**_vestingTokenDecimals;

        uint256 _isRefund = IRefundController(REFUND_CONTROLLER).eligibleForRefund(_address, tokenAddress);
        if (_isRefund == 1) {
            return 0;
        }

        // Calculate the claimable tokens
        if (_fundingTokenDecimals == _vestingTokenDecimals) {
            uint256 _totalAllocation = _userAllocation(_address);
            return FullMath.mulDiv((_totalAllocation * vestingAllocInBps) / _bpsDivisor, _denominator, tokenPrice);
        } else if (_fundingTokenDecimals < _vestingTokenDecimals) {
            uint256 _totalAllocation = _userAllocation(_address) * 10**(_vestingTokenDecimals - _fundingTokenDecimals);
            return FullMath.mulDiv((_totalAllocation * vestingAllocInBps) / _bpsDivisor, _denominator, tokenPrice);
        } else {
            uint256 _totalAllocation = _userAllocation(_address) / 10**(_fundingTokenDecimals - _vestingTokenDecimals);
            return FullMath.mulDiv((_totalAllocation * vestingAllocInBps) / _bpsDivisor, _denominator, tokenPrice);
        }
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param _token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(address _token) private view returns (uint8) {
        (bool success, bytes memory data) = address(_token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        unchecked {
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}