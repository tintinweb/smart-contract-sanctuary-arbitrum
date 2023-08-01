/**
 *Submitted for verification at Arbiscan on 2023-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

        // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
            // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.

        // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
            // Divide denominator by twos.
                denominator := div(denominator, twos)

            // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

            // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

        // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

        // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
        // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
        // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

        // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
        // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

        // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
        // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
        // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
        // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function minOf4(uint256 a, uint256 b, uint256 c, uint256 d) internal pure returns (uint256) {
        return min(min(a, b), min(c, d));
    }

}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

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

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * Spider Pass
 */
interface SpiderPass is IERC721 {
    function tokenIdsOfOwner(address owner) external view returns (uint256[] memory);
}

/**
 * UPUXUY
 */
interface UPUXUY is IERC20 {
    function mint(address account, uint256 amount) external;
    function maxSupply() external view returns (uint256);
}

/**
 * UXUY
 */
interface UXUY is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

/**
 * ITaxation
 */
interface ITaxation {
    function calculate(address user, uint256 amount) external view returns (uint256);
}

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

/**
 * Manager
 */
abstract contract Manager is Context {

    mapping(address => bool) public managers;

    modifier onlyManager {
        require(managers[_msgSender()], "only manager");
        _;
    }

    event ManagerModified(address operater, address one, bool bln);

    constructor() {
        managers[_msgSender()] = true;
    }

    function setManager(address one, bool bln) public onlyManager {
        require(one != address(0), "address is zero");
        require(one != _msgSender(), "address is self");
        if (bln) {
            managers[one] = true;
        } else {
            delete managers[one];
        }
        emit ManagerModified(_msgSender(), one, bln);
    }
}

/**
 * Blacklist
 */
abstract contract Blacklist is Manager {
    mapping (address => bool) public blacklisted;

    function addToBlacklist(address _user) public onlyManager {
        require(!blacklisted[_user], "User is already on the blacklist.");
        blacklisted[_user] = true;
    }

    function removeFromBlacklist(address _user) public onlyManager {
        require(blacklisted[_user], "User is not on the blacklist.");
        delete blacklisted[_user];
    }
}

/**
 * Date by date
 */
abstract contract DataByDay {

    mapping(uint256 => mapping(uint256 => address)) private _tokenIdToUser;
    mapping(uint256 => mapping(address => uint256)) private _userToBurned;
    mapping(uint256 => uint256) private _totalBurnedOfDay;
    mapping(address => uint256) public totalBurnedOfUser;
    uint256 public totalBurned;
    
    function _daysOfNow() internal view returns (uint256) {
        return Math.mulDiv(block.timestamp, 1, 86400);
    }

    function _saveTokenIdsToUser(uint256[] memory tokenIds, address user) internal {
        require(user != address(0));
        uint256 x = _daysOfNow();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_tokenIdToUser[x][tokenIds[i]] == address(0)) {
                _tokenIdToUser[x][tokenIds[i]] = user;
            }
        }
    }

    function _increaseBurnedOfUser(address user, uint256 num) internal {
        require(user != address(0));
        uint256 x = _daysOfNow();
        _userToBurned[x][user] += num;
        _totalBurnedOfDay[x] += num;
        totalBurnedOfUser[user] += num;
        totalBurned += num;
    }

    function getTodayBurned(address user) public view returns(uint256) {
        uint256 x = _daysOfNow();
        return _userToBurned[x][user];
    }

    function getTodayUser(uint256 tokenId) public view returns(address) {
        uint256 x = _daysOfNow();
        return _tokenIdToUser[x][tokenId];
    }

    function getTodayTotalBurned() public view returns(uint256) {
        uint256 x = _daysOfNow();
        return _totalBurnedOfDay[x];
    }

    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns(uint256 _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - 2440588;

        _days = uint(__days);
    }

    function getBurnedByDate(address user, uint256 year, uint256 month, uint256 day) public view returns(uint256) {
        uint256 x = _daysFromDate(year, month, day);
        return _userToBurned[x][user];
    }

    function getUserByDate(uint256 tokenId, uint256 year, uint256 month, uint256 day) public view returns(address) {
        uint256 x = _daysFromDate(year, month, day);
        return _tokenIdToUser[x][tokenId];
    }

    function getTotalBurnedByDate(uint256 year, uint256 month, uint256 day) public view returns(uint256) {
        uint256 x = _daysFromDate(year, month, day);
        return _totalBurnedOfDay[x];
    }

    function daysFrom19700101(uint256 year, uint256 month, uint256 day) public view returns (uint256, uint256) {
        return (_daysOfNow(), _daysFromDate(year, month, day));
    }

}

/**
 * UXUY Burn
 */
contract UXUYBurn is Manager, Blacklist, DataByDay, ReentrancyGuard, Pausable {
    UXUY public Uxuy;
    UPUXUY public Upuxuy;
    SpiderPass public VipPass;
    SpiderPass public SVipPass;
    ITaxation public Tax;
    uint256 public dayCapOfUser;
    uint256 public dayCapOfTotal;
    uint256 public dayCapOfVip;
    uint256 public dayCapOfSVip;
    uint256 public capOfTotal;
    address public beneficiary;

    event burned(address user, uint256 amount, uint256 value);

    constructor(address _uxuy, address _upuxuy, address _vipPass, address _svipPass) {
        Uxuy = UXUY(_uxuy);
        Upuxuy = UPUXUY(_upuxuy);
        VipPass = SpiderPass(_vipPass);
        SVipPass = SpiderPass(_svipPass);
        capOfTotal = Math.mulDiv(Upuxuy.maxSupply(), 80, 100);
        beneficiary = _msgSender();
    }

    function setBeneficiary(address account) public onlyManager {
        require(account != address(0), "account is zero");
        beneficiary = account;
    }

    function withdraw() public onlyManager {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert("balance is zero");
        }
        payable(beneficiary).transfer(balance);
    }

    function setCaps(uint256 _dayCapOfTotal, uint256 _dayCapOfUser, uint256 _dayCapOfSVip, uint256 _dayCapOfVip) public onlyManager {
        require(_dayCapOfVip > 0 && _dayCapOfSVip > _dayCapOfVip, "wrong number for dayCapOfVip / dayCapOfSVip");
        require(_dayCapOfUser >= _dayCapOfSVip && _dayCapOfTotal >= _dayCapOfUser, "wrong number for dayCapOfUser / dayCapOfTotal");
        dayCapOfTotal = _dayCapOfTotal;
        dayCapOfUser = _dayCapOfUser;
        dayCapOfVip = _dayCapOfVip;
        dayCapOfSVip = _dayCapOfSVip;
    }

    function setTokenInstances(address _uxuy, address _upuxuy, address _vipPass, address _svipPass) public onlyManager {
        require(_vipPass != address(0) && _vipPass.code.length > 0);
        require(_svipPass != address(0) && _svipPass.code.length > 0);
        require(_uxuy != address(0) && _uxuy.code.length > 0);
        require(_upuxuy != address(0) && _upuxuy.code.length > 0);
        Uxuy = UXUY(_uxuy);
        Upuxuy = UPUXUY(_upuxuy);
        VipPass = SpiderPass(_vipPass);
        SVipPass = SpiderPass(_svipPass);
        capOfTotal = Math.mulDiv(Upuxuy.maxSupply(), 80, 100);
    }

    function setTaxInstance(address _tax) public onlyManager {
        require(_tax != address(0) && _tax.code.length > 0);
        Tax = ITaxation(_tax);
    }

    function pause() public onlyManager whenNotPaused {
        _pause();
    }

    function unpause() public onlyManager whenPaused {
        _unpause();
    }

    function todayLimit(address user) public view returns (uint256 limit, uint256[] memory tokenIds) {
        if (blacklisted[user]) {
            return (limit, tokenIds);
        }
        uint256 remainingTotal = (capOfTotal >= totalBurned ? capOfTotal - totalBurned : 0);
        if (remainingTotal == 0) {
            return (limit, tokenIds);
        }
        uint256 todayTotalBurned = getTodayTotalBurned();
        uint256 remainingToday = (dayCapOfTotal >= todayTotalBurned ? dayCapOfTotal - todayTotalBurned : 0);
        if (remainingToday == 0) {
            return (limit, tokenIds);
        }
        uint256 todayUserBurned = getTodayBurned(user);
        uint256 remainingUser = (dayCapOfUser >= todayUserBurned ? dayCapOfUser - todayUserBurned : 0);
        if (remainingUser == 0) {
            return (limit, tokenIds);
        }
        address tokenTodayUser;
        uint256 limitOfPassOwner;
        bool isSVip = false;
        if (SVipPass.balanceOf(user) > 0) { // Is SVip?
            tokenIds = SVipPass.tokenIdsOfOwner(user);
            for (uint256 i = 0; i < tokenIds.length; i++) {
                tokenTodayUser = getTodayUser(tokenIds[i]);
                if (tokenTodayUser == address(0) || tokenTodayUser == user) {
                    limitOfPassOwner = (dayCapOfSVip >= todayUserBurned ? dayCapOfSVip - todayUserBurned : 0);
                    isSVip = true;
                    break;
                }
            }
        }
        if (!isSVip && VipPass.balanceOf(user) > 0) { // IsVip
            tokenIds = VipPass.tokenIdsOfOwner(user);
            for (uint256 i = 0; i < tokenIds.length; i++) {
                tokenTodayUser = getTodayUser(tokenIds[i]);
                if (tokenTodayUser == address(0) || tokenTodayUser == user) {
                    limitOfPassOwner = (dayCapOfVip >= todayUserBurned ? dayCapOfVip - todayUserBurned : 0);
                    break;
                }
            }
        }
        limit = Math.minOf4(limitOfPassOwner, remainingUser, remainingToday, remainingTotal);
        return (limit, tokenIds);
    }

    function paymentForTax(address user, uint256 amount) public view returns (uint256) {
        if (address(Tax) == address(0)) {
            return 0;
        }
        return Tax.calculate(user, amount);
    }

    function burnToGet(uint256 amount) public payable whenNotPaused nonReentrant {
        require(!blacklisted[_msgSender()], "blacklisted");
        require(dayCapOfVip > 0 && dayCapOfSVip > dayCapOfVip, "wrong settings");
        (uint256 limit, uint256[] memory tokenIds) = todayLimit(_msgSender());
        require(limit >= amount, "amount is limited");
        require(Uxuy.allowance(_msgSender(), address(this)) >= amount, "UXUY allowance is not enough");
        require(msg.value >= paymentForTax(_msgSender(), amount), "payment is wrong");
        _saveTokenIdsToUser(tokenIds, _msgSender());
        Uxuy.burnFrom(_msgSender(), amount);
        Upuxuy.mint(_msgSender(), amount);
        _increaseBurnedOfUser(_msgSender(), amount);
        emit burned(_msgSender(), amount, msg.value);
    }

}