/**
 *Submitted for verification at Arbiscan on 2023-02-04
*/

// SPDX-License-Identifier: MIT
/// @author EVMlord (for Kimberlite Labs - https://kimberlite.rocks)

pragma solidity ^0.8.17;

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
    mapping (address => bool) internal authorizations;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        authorizations[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
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
    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        authorizations[newOwner] = true;
        _owner = newOwner;
    }
}

contract KimberliteReferralRegistry is Ownable {
    event ReferralAnchorCreated(address indexed user, address indexed referee);
    event ReferralAnchorUpdated(address indexed user, address indexed referee);
    event AnchorManagerUpdated(address account, bool isManager);

    // stores accounts which are allowed to create new anchors
    mapping(address => bool) public isAnchorManager;

    // stores the address that referred a given user
    mapping(address => address) internal referralAnchor;

	// stores the addresses that are referred by a given user
    mapping(address => address[]) internal children;
	
	// stores the number of users referred by a given address
	mapping (address => uint256[20]) internal referralCount;

    // stores the total number of users
    uint internal totalUsers;

    // stores the registration time of a given address
    mapping (address => uint256) internal checkIn;

    constructor () {
        isAnchorManager[_msgSender()] = true;
    }

    function checkInTime(address _user) external view returns (uint) {
        return checkIn[_user];
    }

    function getTotalUsers() external view returns (uint) {
        return totalUsers;
    }

    function createReferralAnchor(address _user, address _referee) external onlyAnchorManager {
        require(referralAnchor[_user] == address(0), "Kimberlite Referral Registry: ANCHOR_EXISTS");
        
        referralAnchor[_user] = _referee;

        emit ReferralAnchorCreated(_user, _referee);

        checkIn[_user] = block.timestamp;
        address upline = referralAnchor[_user];
        
        for (uint i = 0; i < referralCount[_user].length; i++) {
                if (upline != address(0)) {
                    referralCount[upline][i]++;
                    upline = referralAnchor[upline];
                } else break;
        }
	
        totalUsers ++;
        addChild(_user);
    }

    function updateReferralAnchor(address _user, address _referee) external authorized {
        referralAnchor[_user] = _referee;
        emit ReferralAnchorUpdated(_user, _referee);
    }

    function updateAnchorManager(address _anchorManager, bool _isManager) external authorized {
        isAnchorManager[_anchorManager] = _isManager;
        emit AnchorManagerUpdated(_anchorManager, _isManager);
    }

    function getReferee(address _user) external view returns (address) {
        return referralAnchor[_user];
    }

    function hasReferee(address _user) external view returns (bool) {
        return referralAnchor[_user] != address(0);
    }

    modifier onlyAnchorManager() {
        require(isAnchorManager[msg.sender], "Kimberlite Referral Registry: FORBIDDEN");
        _;
    }

    function addChild(address _user) internal {
        address upline = referralAnchor[_user];

        for (uint256 i = 0; i < children[upline].length; i++) {
            if (children[upline][i] == _user) {
                // Child address is already in the array, return
                return;
            }

        }
        children[upline].push(_user);   
    }

    
    function getReferralStats(address userAddress) external view returns (uint[20] memory ) {
        return (referralCount[userAddress]);
    }

    function getTotalRefs20Levels(address userAddress) external view returns (uint tRef) {
        for (uint i = 0; i < referralCount[userAddress].length; i++) {
        tRef += referralCount[userAddress][i]; 
        }
    }

    function getRefCount4Index(address userAddress, uint _index) external view returns (uint) {
        return referralCount[userAddress][_index]; 
    }

    function getChildren(address userAddress) external view returns (address[] memory) {
        return children[userAddress];
    }

    function getReferralStatsByLevel(address userAddress, uint startLevel, uint endLevel) 
    external view returns (uint[] memory) {
        return _getReferralStatsByLevel(userAddress, startLevel, endLevel);
    }

    function _getReferralStatsByLevel(address userAddress, uint startLevel, uint endLevel) 
    internal view returns (uint[] memory) {
    
    require((startLevel >= 0 && startLevel <= 19) 
    && (endLevel >= 0 && endLevel <= 19) 
    && (startLevel <= endLevel), "Invalid level range");

    uint bandwidth = (endLevel+1)-startLevel;
    
    uint[] memory refOnLevCount = new uint[](bandwidth);
    for (uint i = startLevel; i <= endLevel; i++) {
        refOnLevCount[i - startLevel] = referralCount[userAddress][i];
    }

    return (refOnLevCount);
    }

    function getTotalReferralCountForLevels (address userAddress, uint startLevel, uint endLevel) 
    external view returns (uint tRefOnLevels) {
        require((startLevel >= 0 && startLevel <= 19) 
    && (endLevel >= 0 && endLevel <= 19) 
    && (startLevel <= endLevel), "Invalid level range");

    uint256[] memory referralStats = _getReferralStatsByLevel(userAddress, startLevel, endLevel);
    //uint256 tRefOnLevels = 0;
    for (uint256 i = 0; i < referralStats.length; i++) {
        tRefOnLevels += referralStats[i];
    }
    //return total;
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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