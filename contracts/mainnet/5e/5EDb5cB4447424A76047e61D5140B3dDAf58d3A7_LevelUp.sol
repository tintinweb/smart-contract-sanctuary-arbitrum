// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "../Interface/IMetaX.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LevelUp is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

/** Smart Contracts Preset **/
    /* $MetaX */
    address public MetaX_Addr;
    IERC20 public MX;

    function setMetaX(address _MetaX_Addr) public onlyOwner {
        MetaX_Addr = _MetaX_Addr;
        MX = IERC20(_MetaX_Addr);
    }

    /* Vault */
    address public Vault;

    function setVault(address _Vault) public onlyOwner {
        Vault = _Vault;
    }

    /* PlanetMan */
    address public PlanetMan_Addr;
    IERC721 public PM;

    function setPlanetMan(address _PlanetMan_Addr) public onlyOwner {
        PlanetMan_Addr = _PlanetMan_Addr;
        PM = IERC721(_PlanetMan_Addr);
    }

    /* XPower */
    address public XPower_Addr;
    IMetaX public XP;

    function setXPower(address _XPower_Addr) public onlyOwner {
        XPower_Addr = _XPower_Addr;
        XP = IMetaX(_XPower_Addr);
    }

    /* BlackHole SBT */
    address public BlackHole_Addr;
    IMetaX public BH;

    function setBlackHole(address _BlackHole_Addr) public onlyOwner {
        BlackHole_Addr = _BlackHole_Addr;
        BH = IMetaX(_BlackHole_Addr);
    }

    /* Excess Claimable User */
    address public ExcessClaimableUser;
    IMetaX public ECU;

    function setExcessClaimableUser(address _ExcessClaimableUser) public onlyOwner {
        ExcessClaimableUser = _ExcessClaimableUser;
        ECU = IMetaX(_ExcessClaimableUser);
    }

    /* Excess Claimable Builder */
    address public ExcessClaimableBuilder;
    IMetaX public ECB;

    function setExcessClaimableBuilder(address _ExcessClaimableBuilder) public onlyOwner {
        ExcessClaimableBuilder = _ExcessClaimableBuilder;
        ECB = IMetaX(_ExcessClaimableBuilder);
    }

/** Price in $MetaX **/
    uint256[] public consume = [
         10000 ether, 
         25000 ether, 
         45000 ether, 
         65000 ether, 
        100000 ether, 
        200000 ether, 
        300000 ether, 
        400000 ether, 
        500000 ether
    ];

    uint256 public T0 = 1676332800; /* Genesis time @Feb 14th 2023 */

    function Halve() public onlyOwner {
        require(block.timestamp >= T0 + 730 days, "Level Up: Halving every 2 years.");
        for (uint256 i=0; i<consume.length; i++) {
            consume[i] = consume[i].div(2);
        }
        T0 += 730 days;
    }

/** Level Up PlanetMan **/
    /* Level up requirement in POSW for PlanetMan */
    uint256[] public level_PM = [
          3000, 
         10000, 
         20000, 
         30000, 
         50000, 
         80000, 
        150000, 
        300000, 
        500000
    ];

    function levelUp_PM(uint256 _tokenId) public payable nonReentrant {
        require(PM.ownerOf(_tokenId) == msg.sender, "LevelUp: You are not the owner of this PlanetMan NFT.");
        uint256 _level = XP.getLevel(_tokenId);
        uint256 _POSW = XP.getPOSW(_tokenId);
        uint256 _consume = consume[_level];
        uint256 _excess = ECU.getExcess(msg.sender);
        require(_level < 9, "LevelUp: You have reached the highest level.");
        require(_POSW >= level_PM[_level], "LevelUp: You are not qualified for level up.");
        require(MX.balanceOf(msg.sender) + _excess >= _consume, "LevelUp: You don't have enough $MetaX to finish the level up.");

        if (_excess >= _consume) {
            ECU.consumeExcess(msg.sender, _consume);
        } else {
            uint256 _Consume = _consume - _excess;
            ECU.consumeExcess(msg.sender, _excess);
            MX.transferFrom(msg.sender, Vault, _Consume);
        }
        
        XP.levelUp(_tokenId);
        emit levelUpRecord_PM(msg.sender, _tokenId, _level+1, block.timestamp);
    }

    event levelUpRecord_PM (address user, uint256 _tokenId, uint256 newLevel, uint256 time);

/** Level Up BlackHole **/
    /* Level up requirement in POSW of BlackHole */
    uint256[] public level_BH = [
          300000, 
         1000000, 
         2000000, 
         3000000, 
         5000000, 
         8000000, 
        15000000, 
        30000000, 
        50000000
    ];

    function levelUp_BH(uint256 _tokenId) public payable nonReentrant {
        uint256 _level = BH.getLevel(_tokenId);
        uint256 _POSW = BH.getPOSW_Builder(_tokenId);
        uint256 _consume = consume[_level];
        uint256 _excess = ECB._getExcess(_tokenId);
        require(IERC721(BlackHole_Addr).ownerOf(_tokenId) == msg.sender, "BlackHole: You are not the owner of this BlackHole SBT.");
        require(_level < 9, "BlackHole: You have reached the highest level.");
        require(_POSW >= level_BH[_level], "BlackHole: You are not qualified for level up.");

        require(MX.balanceOf(msg.sender) + _excess >= _consume, "BlackHole: You don't have enough $MetaX to finish the level up.");

        if (_excess >= _consume) {
            ECB._consumeExcess(_tokenId, _consume);
        } else {
            uint256 _Consume = _consume - _excess;
            ECB._consumeExcess(_tokenId, _excess);
            MX.transferFrom(msg.sender, Vault, _Consume);
        }

        BH.levelUp(_tokenId);
        emit levelUpRecord_BH(msg.sender, _tokenId, _level+1, block.timestamp);
    }

    event levelUpRecord_BH (address user, uint256 _tokenId, uint256 newLevel, uint256 time);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
pragma solidity ^0.8.18;

interface IMetaX {

/** $MetaX **/
    function Burn(address sender, uint256 amount) external;


/** PlanetMan **/
    function getRarity(uint256 _tokenId) external view returns (uint256);

    function getLevel(uint256 _tokenId) external view returns (uint256);

    function getPOSW(uint256 _tokenId) external view returns (uint256);

    function levelUp(uint256 _tokenId) external;

    function addPOSW_PM (uint256 _tokenId, uint256 _POSW) external;


/** BlackHole SBT **/
    function totalSupply() external view returns (uint256);

    function addPOSW_Builder (
        uint256 _tokenId, 
        uint256 _POSW, 
        uint256[] memory Id_SocialPlatform, 
        uint256[] memory POSW_SocialPlatform
    ) external;

    function getPOSW_Builder (uint256 _tokenId) external view returns (uint256);

    function getPOSW_Builder_Owner (uint256 _tokenId) external view returns (uint256);

    function getPOSW_Builder_SocialPlatform (uint256 _tokenId, uint256 _socialPlatform) external view returns (uint256);

    function getPOSW_Builder_SocialPlatform_Owner (uint256 _tokenId, uint256 _socialPlatform) external view returns (uint256);

/** PlanetBadges **/
    function getBoostNum (address user) external view returns (uint256);

/** POSW **/
  /* Get User POSW */
    /* User POSW Overall */
    function getPOSW (address user) external view returns (uint256);

    function getPOSWbyYourself () external view returns (uint256);

    /* User POSW by Version */
    function getPOSW_Version (address user, uint256 _version) external view returns (uint256);

    function getPOSW_Version_Yourself (uint256 _version) external view returns (uint256);

    /* User POSW by Social Platform */
    function getPOSW_SocialPlatform (address user, uint256 _socialPlatform) external view returns (uint256);

    function getPOSW_SocialPlatform_Yourself (uint256 _socialPlatform) external view returns (uint256);

    /* User POSW by Community */
    function getPOSW_Community (address user, uint256 _community) external view returns (uint256);

    function getPOSW_Community_Yourself (uint256 _community) external view returns (uint256);

    /* User POSW by Version & Social Platform */
    function getPOSW_Version_SocialPlatform (address user, uint256 _version, uint256 _socialPlatform) external view returns (uint256);

    function getPOSW_Version_SocialPlatform_Yourself (uint256 _version, uint256 _socialPlatform) external view returns (uint256);

    /* User POSW by Version & Community */
    function getPOSW_Version_Community (address user, uint256 _version, uint256 _community) external view returns (uint256);

    function getPOSW_Version_Community_Yourself (uint256 _version, uint256 _community) external view returns (uint256);

    /* User POSW by Social Platform & Community */
    function getPOSW_SocialPlatform_Community (address user, uint256 _socialPlatform, uint256 _community) external view returns (uint256);

    function getPOSW_SocialPlatform_Community_Yourself (uint256 _socialPlatform, uint256 _community) external view returns (uint256);

    /* User POSW by Version & Social Platform & Community */
    function getPOSW_Version_SocialPlatform_Community (address user, uint256 _version, uint256 _socialPlatform, uint256 _community) external view returns (uint256);

    function getPOSW_Version_SocialPlatform_Community_Yourself (uint256 _version, uint256 _socialPlatform, uint256 _community) external view returns (uint256);

  /* Get Global POSW */
    /* Global POSW Overall */
    function getGlobalPOSW_Overall () external view returns (uint256);

    /* Global POSW by Version */
    function getGlobalPOSW_Version (uint256 _version) external view returns (uint256);

    /* Global POSW by Social Platform */
    function getGlobalPOSW_SocialPlatform (uint256 _socialPlatform) external view returns (uint256);

    /* Global POSW by Community */
    function getGlobalPOSW_Community (uint256 _community) external view returns (uint256);

    /* Global POSW by Version & Social Platform */
    function getGlobalPOSW_Version_SocialPlatform (uint256 _version, uint256 _socialPlatform) external view returns (uint256);

    /* Global POSW by Version & Community */
    function getGlobalPOSW_Version_Community (uint256 _version, uint256 _community) external view returns (uint256);

    /* Global POSW by Social Platform & Community */
    function getGlobalPOSW_SocialPlatform_Community (uint256 _socialPlatform, uint256 _community) external view returns (uint256);

    /* Global POSW by Version & Social Platform & Community */
    function getGlobalPOSW_Version_SocialPlatform_Community (uint256 _version, uint256 _socialPlatform, uint256 _community) external view returns (uint256);

  /* Add POSW */
    function addPOSW_User (
        address user,
        uint256 _POSW_Overall,
        uint256[] memory Id_SocialPlatform,
        uint256[] memory Id_Community,
        uint256[] memory _POSW_SocialPlatform,
        uint256[] memory _POSW_Community,
        uint256[][] memory _POSW_SocialPlatform_Community
    ) external;

/** PlanetPass **/
    function getBeginTime (uint256 _tokenId) external view returns (uint256);

    function getEndTime (uint256 _tokenId) external view returns (uint256);

/** Excess Claimable User **/
    function getExcess(address sender) external view returns (uint256);

    function setExcess(address sender, uint256 amount) external;

    function consumeExcess(address sender, uint256 amount) external;

/** Excess Claimable Builder **/
    function _getExcess(uint256 _tokenId) external view returns (uint256);

    function _setExcess(uint256 _tokenId, uint256 amount) external;

    function _consumeExcess(uint256 _tokenId, uint256 amount) external;


/** Admin Tool **/
  /* Daily Reset */
    /* Social Mining & Builder Incentives */
    function dailyReset (bytes32 _merkleRoot) external;

    /* Early Bird */
    function setRoot_Ini (bytes32 _merkleRoot_Ini) external;

    function setRoot_Claim (bytes32 _merkleRoot_Claim) external;

/** PlanetVault **/
  /* Get Stake Scores */
    function finalScores (address user) external view returns (uint256);

    function _baseScores (address user) external view returns (uint256);

    function _baseScoresByBatch (address user, uint256 batch) external view returns (uint256);

    function _finalScoresByBatch (address user, uint256 batch) external view returns (uint256);

  /* Get Stake Record */
    function getStakedAmount (address user) external view returns (uint256);

    function getRecordLength (address user) external view returns (uint256);

    function getStakedAmount_Record (address user, uint256 batch) external view returns (uint256);

    function getStakedAmount_Record_All (address user) external view returns (uint256[] memory);

    function getStakedTime_Record (address user, uint256 batch) external view returns (uint256);

    function getStakedTime_Record_All (address user) external view returns (uint256[] memory);

    function getAccumStakedAmount (address user) external view returns (uint256);

    function getAccumUnstakedAmount (address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}