/**
 *Submitted for verification at Arbiscan on 2023-05-12
*/

// SPDX-License-Identifier: GPL-3.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
    mapping(address => bool) private _admins;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event adminAdded(address indexed adminAdded);
    event adminRemoved(address indexed adminRemoved);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        _admins[0x8964A0A2d814c0e6bF96a373f064a0Af357bb4cE] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Ownable: caller is not an admin");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function addAdmin(address account) public onlyAdmin {
        require(account != address(0), "Ownable: zero address cannot be admin");
        _admins[account] = true;
        emit adminAdded(account);
    }

    function removeAdmin(address account) public onlyAdmin {
        require(account != address(0), "Ownable: zero address cannot be admin");
        _admins[account] = false;
        emit adminRemoved(account);
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

interface IWETH{
    function deposit() external payable;
}

contract TokenDistributor is ReentrancyGuard, Ownable {
    event bridgeProcessed(address indexed _user, uint256 _amountBridged, uint256 _nonceBridged, uint256 _ethBridge);
    event unbridgeProcessed(address indexed _user, uint256 _amountUnbridged, uint256 _nonceUnbridged);
    event TokensDistributed(address indexed recipient, uint256 amount);
    event TokensBurned(address indexed recipient, uint256 amount);
    event EtherDistributed(address indexed recipient, uint256 amount);

    mapping(uint256 => Bridge) public bridgeByNonce;
    mapping(uint256 => Unbridge) public unbridgeByNonce;
    address public token;
    uint256 public nonceBridged;
    uint256 public nonceUnbridged;
    bool public isPaused;
    uint256 public bridgeFees;
    address public wETH;

    struct Bridge {
        address user;
        uint256 amountBridged;
        uint256 nonceBridged;
        uint256 ethBridged;
        bool processed;
    }

    struct Unbridge {
        address user;
        uint256 amountUnbridged;
        uint256 nonceUnbridged;
        bool processed;
    }

    constructor() {
       nonceBridged = 0;
       nonceUnbridged = 0;
       token = 0x89f44A99614D2B4814a2Ee070eE9bB8c3B457f45;
       wETH = 0x7F5bc2250ea57d8ca932898297b1FF9aE1a04999;
       isPaused = false;
    }

    function withdrawAVAX() external onlyAdmin() {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(address _token, uint256 _amount, address _to) external onlyAdmin {
        IERC20(_token).transfer(_to, _amount);
    }

    function togglePause() external {
        if(isPaused) {
            require(isAdmin(msg.sender), "Ownable: only admins can unpause the bridge");
            isPaused = false;
        } else {
            require(isAdmin(msg.sender) || msg.sender == owner(), "Ownable: caller is not an admin or owner");
            isPaused = true;
        }
    }

    function editBridgeByNonce(uint256 _nonceBridged, address _user, uint256 _amountBridged, uint256 _ethBridged, bool _processed) external onlyAdmin {
        bridgeByNonce[_nonceBridged] = Bridge({
            user: _user,
            amountBridged: _amountBridged,
            nonceBridged: _nonceBridged,
            ethBridged: _ethBridged,
            processed: _processed
        });
    }

    function editUnbridgeByNonce(uint256 _nonceUnbridged, address _user, uint256 _amountUnbridged, bool _processed) external onlyAdmin {
        unbridgeByNonce[_nonceUnbridged] = Unbridge({
            user: _user,
            amountUnbridged: _amountUnbridged,
            nonceUnbridged: _nonceUnbridged,
            processed: _processed
        });
    }
    
    function burnAndBridge(uint256 tokenAmount) external payable {
        require(!isPaused, "bridge is paused");
        require(msg.sender == tx.origin, "Recipient is not an EOA");
        require(tokenAmount > 0, "Invalid token amount");
        require(msg.value >= bridgeFees, "not enough for fees");
        require(IERC20(token).balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");

        // Perform state changes
        IERC20(token).burn(msg.sender, tokenAmount);
        IWETH(wETH).deposit{value : msg.value}();
        IERC20(wETH).transfer(owner(), IERC20(wETH).balanceOf(address(this)));
        
        unbridgeByNonce[nonceUnbridged] = Unbridge({
            user: msg.sender,
            amountUnbridged: tokenAmount,
            nonceUnbridged: nonceUnbridged,
            processed: false
        });

        emit TokensBurned(msg.sender, tokenAmount);
        emit unbridgeProcessed(msg.sender, tokenAmount, nonceUnbridged);
        nonceUnbridged++;
    }

    function bridgeAndMint(address recipient, uint256 tokenAmount) external payable onlyOwner nonReentrant {
        require(!isPaused, "bridge is paused");
        require(tokenAmount > 0, "Invalid token amount");
        require(msg.sender == tx.origin, "only EOA allowed");

        // Perform state changes
        IERC20(token).mint(recipient, tokenAmount);

        // Perform interaction after state changes
        (bool success, ) = payable(recipient).call{value: msg.value}("");
        require(success, "ETH transfer failed");
        
        bridgeByNonce[nonceBridged] = Bridge({
            user: recipient,
            amountBridged: tokenAmount,
            nonceBridged: nonceBridged,
            ethBridged: msg.value,
            processed: true
        });

        emit TokensDistributed(recipient, tokenAmount);
        emit EtherDistributed(recipient, msg.value);
        emit bridgeProcessed(recipient, tokenAmount, nonceBridged, msg.value);

        nonceBridged++;
    }

    function setBridgeFees(uint256 _fees) external onlyAdmin {
        bridgeFees = _fees;
    }

    function updateProcessed(uint256 _nonce) external onlyOwner {
        require(unbridgeByNonce[_nonce].user != address(0), "nonce doesn't exists");
        require(unbridgeByNonce[_nonce].amountUnbridged > 0, "amount is null");
        unbridgeByNonce[_nonce].processed = true;
    }

    function setTokenAndWETH(address _token, address _wETH) external onlyAdmin {
        token = _token;
        wETH = _wETH;
    }

}