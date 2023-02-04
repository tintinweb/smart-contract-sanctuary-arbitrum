/**
 *Submitted for verification at Arbiscan on 2023-02-04
*/

// SPDX-License-Identifier: MIT
/// @author EVMlord (for Kimberlite Labs - https://kimberlite.rocks)

pragma solidity ^0.8.17;

//pragma experimental ABIEncoderV2;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    mapping(address => bool) internal authorizations;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function constructor_(address adr) internal {
        //address msgSender = _msgSender();
        _owner = adr;
        authorizations[_owner] = true;
        emit OwnershipTransferred(address(0), adr);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(_msgSender()), "!AUTHORIZED");
        _;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner)
        public
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        authorizations[newOwner] = true;
        _owner = newOwner;
    }
}

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IREGISTRY {
    function getReferee(address _user) external view returns (address);

    function hasReferee(address _user) external view returns (bool);

    function createReferralAnchor(address _user, address _referee) external;

    function getRefCount4Index(address userAddress, uint256 _index)
        external
        view
        returns (uint256);

    function getReferralStatsByLevel(
        address userAddress,
        uint256 startLevel,
        uint256 endLevel
    ) external view returns (uint256[] memory);

    function getTotalReferralCountForLevels(
        address userAddress,
        uint256 startLevel,
        uint256 endLevel
    ) external view returns (uint256 tRefOnLevels);
}

contract GemHunterWaitist is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    mapping(address => bool) public isRegistered;
    uint256 public totalPoints;
    uint256 public participants;
    uint256 constant public bonus = 100;
    uint256 public totalRefBonus;
    uint256[5] public refPercents; // = [500, 400, 300, 200, 100];
    mapping(address => uint256) internal userBonus;
    mapping(address => uint256) internal userRedeemed;
    IREGISTRY public referralRegistry;

    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event BonusRedeemed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event Welcome(address indexed user, uint256 timestamp);

    constructor() /*IREGISTRY _referralRegistry*/
    {
        //referralRegistry = IREGISTRY(_referralRegistry);
        //isRegistered[_msgSender()] = true;
    }

    function initialize(IREGISTRY _referralRegistry, address _admin_)
        public
        nonReentrant
    {
        referralRegistry = IREGISTRY(_referralRegistry);
        isRegistered[_msgSender()] = true;
        refPercents = [500, 400, 300, 200, 100];
        constructor_(_admin_);
    }

    function preRegister(address _upline) external {
        _preRegister(_upline, _msgSender());
    }

    function _preRegister(address _upline, address _user) internal {
        require(!isRegistered[_user] && isRegistered[_upline],"GemHunterWaitist: Invalid Registration");

        userBonus[_user] += bonus;
        totalPoints += bonus;

        address upline = _getReferee(_upline);

        for (uint256 i = 0; i < 5; i++) {
            if (upline != address(0)) {
                uint256 userAmount = bonus.mul(refPercents[i]).div(10000);
                if (userAmount > 0) {
                    userBonus[upline] += userAmount;
                    totalRefBonus += userAmount;
                    emit RefBonus(upline, _user, i, userAmount);
                }
                upline = referralRegistry.getReferee(upline);
            } else break;
        }

        isRegistered[_user] = true;
        participants++;

        emit Welcome(msg.sender, block.timestamp);
    }

    function registerBatch(address[] memory _upline, address[] memory _user) external authorized {
        assert(_upline.length == _user.length);
        // loop through to addresses and preRegister
		for (uint8 i = 0; i < _upline.length; i++) {
            _preRegister(_upline[i],_user[i]);
		} 
    }

    function UserBonus(address _user) external view returns (uint256) {
        return userBonus[_user];
    }

    function UserRedeemed(address _user) external view returns (uint256) {
        return userRedeemed[_user];
    }

    function userData(address userAddress)
        external
        view
        returns (
            uint256 directRefs,
            uint256[] memory multiLevelRef,
            uint256 teamSize
        )
    {
        directRefs = referralRegistry.getRefCount4Index(userAddress, 0);
        multiLevelRef = referralRegistry.getReferralStatsByLevel(
            userAddress,
            0,
            4
        );
        teamSize = referralRegistry.getTotalReferralCountForLevels(
            userAddress,
            0,
            4
        );
    }

    function _getReferee(address referee) internal returns (address) {
        address sender = _msgSender();
        if (!referralRegistry.hasReferee(sender) && referee != address(0)) {
            referralRegistry.createReferralAnchor(sender, referee);
        }
        return referralRegistry.getReferee(sender);
    }

    function redeemBonus(address userAddress, uint256 amount) external {
        require(
            _msgSender() == userAddress || authorizations[_msgSender()] == true
        );
        require(amount <= userBonus[userAddress],"GemHunterWaitist: User can't redeem more than available balance");
        userBonus[userAddress] -= amount;
        userRedeemed[userAddress] += amount;
        emit BonusRedeemed(userAddress, amount, block.timestamp);
    }

    function addBonus(address _user, uint256 amount) external authorized {
        userBonus[_user] += amount;
        totalPoints += amount;
    }

    function removeBonus(address _user, uint256 amount) external authorized {
        userBonus[_user] -= amount;
        totalPoints -= amount;
    }
}