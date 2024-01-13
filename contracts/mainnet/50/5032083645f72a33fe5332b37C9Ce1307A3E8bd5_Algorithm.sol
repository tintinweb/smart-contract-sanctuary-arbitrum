/**
 *Submitted for verification at Arbiscan.io on 2024-01-11
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: Interface/IMetaX.sol


pragma solidity ^0.8.18;

interface IMetaX {

/** Token Vault **/
    function Release () external;

/** PlanetMan **/
    function getRarity (uint256 _tokenId) external view returns (uint256);

    function getAllTokens (address owner) external view returns (uint256[] memory);

/** XPower **/
    function getLevel (uint256 tokenId) external view returns (uint256 level);

    function getLevelCom (uint256 tokenId) external view returns (uint256 level);

/** PlanetBadges **/
    function getBoostNum (address user) external view returns (uint256);

/** POSW **/
    function setEpoch () external;

    function getEpoch () external view returns (uint256);

    function addPOSW (address user, uint256 posw) external;

    function getPOSW (address user) external view returns (uint256);

/** Staking **/
  /* Staking Level */
    function Level (address user) external view returns (uint256 level);

    function baseScores (address user) external view returns (uint256 _baseScores);

    function Adjustment (address user) external view returns (uint256 adjustment);

    function finalScores (address user) external view returns (uint256);

  /* Planet Vault */
    function getStakedAmount (address user) external view returns (uint256);

    function getAccumStakedAmount (address user) external view returns (uint256);

    function getStakedAmount_Record_All (address user) external view returns (uint256[] memory);

    function getStakedTime_Record_All (address user) external view returns (uint256[] memory);

/** Algorithm **/
    function bestPM (address user) external view returns (uint256);

    function syncPMRate (address user) external view returns (uint256 rate);

    function stakeRate (address user) external view returns (uint256);

    function getRate (address user) external view returns (uint256 rate);

/** Red Pocket **/
    function getAccumSend (address user) external view returns (uint256);

    function getAccumSendByUser (address user0, address user1) external view returns (uint256);

    function getEpochSendByUser (address user0, address user1, uint256 epoch) external view returns (uint256);

    function getCurrentSendByUser (address user0, address user1) external view returns (uint256);
}
// File: SocialMining_V2/Algorithm.sol


pragma solidity ^0.8.18;





contract Algorithm is Ownable {
    using SafeMath for uint256;

/** Smart Contract **/
    /* Staking Level */
    IMetaX public LV;

    function setStakingLevel (address StakingLevel_addr) public onlyOwner {
        LV = IMetaX(StakingLevel_addr);
    }

    /* PlanetMan */
    IMetaX public PM;
    IERC721 public pm;
    IMetaX public XP;

    function setPlanetMan (address PlanetMan_addr, address XPower_addr) public onlyOwner {
        PM = IMetaX(PlanetMan_addr);
        pm = IERC721(PlanetMan_addr);
        XP = IMetaX(XPower_addr);
    }

    /* BlackHole */
    IERC721 public BH;

    function setBlackHole (address BlackHole_addr) public onlyOwner {
        BH = IERC721(BlackHole_addr);
    }

    /* PlanetGenesis */
    address public PlanetGenesis_addr;
    IERC721 public PG;

    function setPlanetGenesis (address _PlanetGenesis_addr) public onlyOwner {
        PlanetGenesis_addr = _PlanetGenesis_addr;
        PG = IERC721(_PlanetGenesis_addr);
    }

    /* PlanetBadges */
    IMetaX public PB;

    function setPlanetBadges (address PlanetBadges_addr) public onlyOwner {
        PB = IMetaX(PlanetBadges_addr);
    }

    /* Red Pocket */
    IMetaX public Red;

    function setRedPocket (address RedPocket_addr) public onlyOwner {
        Red = IMetaX(RedPocket_addr);
    }

/** Initialization **/
    constructor (
        address StakingLevel_addr,
        address PlanetMan_addr,
        address XPower_addr,
        address BlackHole_addr,
        address PlanetBadges_addr,
        address RedPocket_addr
    ) {
        setStakingLevel(StakingLevel_addr);
        setPlanetMan(PlanetMan_addr, XPower_addr);
        setBlackHole(BlackHole_addr);
        setPlanetBadges(PlanetBadges_addr);
        setRedPocket(RedPocket_addr);
    }

/*** Interactive POSW Weight ***/
    uint256 public baseIntWeight = 100;
    uint256 public maxIntWeight = 10000;

    function setBaseIntWeight (uint256 _baseIntWeight, uint256 _maxIntWeight) public onlyOwner {
        baseIntWeight = _baseIntWeight;
        maxIntWeight = _maxIntWeight;
    }

    uint256 public epochIntWeightRatio = 100 ether;
    uint256 public permanentIntWeightRatio = 10000 ether;

    function setIntWeightRatio (uint256 _epochIntWeightRatio, uint256 _permanentIntWeightRatio) public onlyOwner {
        epochIntWeightRatio = _epochIntWeightRatio;
        permanentIntWeightRatio = _permanentIntWeightRatio;
    }

    uint256 public maxEpochRatio = 10000;
    uint256 public maxPermanentRatio = 3000;

    function setMaxRatio (uint256 _maxEpochRatio, uint256 _maxPermanentRatio) public onlyOwner {
        maxEpochRatio = _maxEpochRatio;
        maxPermanentRatio = _maxPermanentRatio;
    }

    function extraEpochIntWeight (address user0, address user1) public view returns (uint256 epochRatio) {
        uint256 sent = Red.getCurrentSendByUser(user0, user1);
        epochRatio = sent.mul(100).div(epochIntWeightRatio);
        if (epochRatio > maxEpochRatio) {
            epochRatio = maxEpochRatio;
        }
    }

    function extraPermanentIntWeight (address user0, address user1) public view returns (uint256 permanentRatio) {
        uint256 sent = Red.getAccumSendByUser(user0, user1);
        permanentRatio = sent.mul(100).div(permanentIntWeightRatio);
        if (permanentRatio > maxPermanentRatio) {
            permanentRatio = maxPermanentRatio;
        }
    }

    function getIntWeight (address user0, address user1) public view returns (uint256 weight) {
        weight = baseIntWeight.add(extraEpochIntWeight(user0, user1)).add(extraPermanentIntWeight(user0, user1));
        if (weight > maxIntWeight) {
            weight = maxIntWeight;
        }
    }

/** Halving **/
    uint256 public T0 = 1676505600; /* Genesis Epoch @Feb 16th 2023 */

    function Halve () public onlyOwner {
        require(block.timestamp > T0.add(730 days), "Algorithm: please wait till next halve.");
        maxRelease_SM = maxRelease_SM.div(2);
        maxRelease_BI = maxRelease_BI.div(2);
        baseUserRate = baseUserRate.div(2);
        for (uint256 i=0; i<pmRate.length; i++) {
            for (uint256 j=0; j<pmRate[0].length; j++) {
                pmRate[i][j] = pmRate[i][j].div(2);
                maxPMRate[i][j] = maxPMRate[i][j].div(2);
            }
        }
        for (uint256 k=0; k<baseStakeRate.length; k++) {
            baseStakeRate[k] = baseStakeRate[k].div(2);
        }
        for (uint256 y=0; y<baseBHRate.length; y++) {
            baseBHRate[y] = baseBHRate[y].div(2);
        }
        T0 = T0.add(730 days);
    }


/*** Social Mining Ability ***/

    uint256 public baseUserRate = 100; /* 10 ** 16 */

/** PlanetMan Sync **/
    /* Base PlanetMan Rate */
    uint256[][] public pmRate = [ /* 10 ** 16 */
        [0,  20,  22,  25,  30,  38,  50,  62,  75,   88,  100,  120,  140,  160,  180,  200,  220,  240,  260,  280,  300,  320,  340,  360,  380,  400,  420,  440,  460,  480,  500],
        [0,  30,  38,  50,  68,  88, 100, 118, 135,  150,  162,  180,  200,  220,  250,  280,  300,  320,  340,  360,  400,  440,  480,  520,  560,  600,  640,  680,  720,  780,  800],
        [0, 100, 145, 180, 205, 225, 240, 285, 325,  340,  360,  380,  420,  460,  500,  560,  620,  680,  740,  800,  900, 1000, 1080, 1150, 1260, 1320, 1400, 1500, 1600, 1700, 1800],
        [0, 256, 300, 320, 368, 400, 450, 520, 600,  720,  800,  900, 1050, 1120, 1200, 1280, 1400, 1530, 1650, 1720, 1800, 1880, 2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800],
        [0, 400, 460, 520, 580, 640, 720, 830, 950, 1050, 1200, 1360, 1480, 1580, 1700, 1880, 2000, 2100, 2200, 2300, 2400, 2500, 2680, 2800, 3000, 3150, 3300, 3400, 3500, 3600, 3800]
    ];

    /* Max PlanetMan Rate */
    uint256[][] public maxPMRate = [ /* 10 ** 16 */
        [0,  20,  22,  25,  30,   38,   50,   62,   75,   88,  100,  120,  140,  160,  180,  200,  220,  240,  260,  280,  300,  320,  340,  360,  380,  400,  420,  440,  460,  480,  500],
        [0,  75,  95, 125, 170,  220,  250,  295,  338,  375,  405,  450,  500,  550,  625,  700,  750,  800,  850,  900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000],
        [0, 168, 230, 300, 330,  375,  400,  475,  520,  560,  600,  650,  700,  760,  850,  950, 1050, 1150, 1250, 1350, 1500, 1650, 1800, 1920, 2100, 2200, 2300, 2500, 2650, 2800, 3000],
        [0, 400, 480, 520, 600,  650,  750,  850,  950, 1100, 1250, 1400, 1550, 1780, 1900, 2050, 2250, 2450, 2650, 2750, 2900, 3050, 3200, 3350, 3500, 3680, 3850, 4000, 4200, 4350, 4500],
        [0, 630, 720, 820, 920, 1000, 1150, 1300, 1500, 1650, 1900, 2150, 2300, 2500, 2700, 3000, 3150, 3350, 3500, 3650, 3800, 4000, 4250, 4500, 4750, 5000, 5200, 5400, 5600, 5800, 6000]
    ];

    /* Additional 5 levels by owning PlanetGenesis NFT */
    function boostPG (address user) public view returns (bool) {
        if (PlanetGenesis_addr == address(0) || PG.balanceOf(user) == 0) {
            return false;
        } else {
            return true;
        }
    }

    /* Additional 10% of social mining ability by owning 10+ different series of PlanetBadges NFT */
    function boostPB (address user) public view returns (bool) {
        if (PB.getBoostNum(user) < 10) {
            return false;
        } else {
            return true;
        }
    }

    /* Best PlanetMan */
    function bestPlanetMan (address user) public view returns (uint256 tokenId, uint256 _baseRate, uint256 _maxRate) {
        uint256[] memory _tokenId = PM.getAllTokens(user);
        if (_tokenId.length > 0) {
            tokenId = _tokenId[0];
            for (uint256 i=1; i<_tokenId.length; i++) {
                uint256 rarity = PM.getRarity(_tokenId[i]);
                uint256 level = XP.getLevel(_tokenId[i]);
                if (rarity > PM.getRarity(tokenId)) {
                    tokenId = _tokenId[i];
                } else if (rarity == PM.getRarity(tokenId)) {
                    if (level > XP.getLevel(tokenId)) {
                        tokenId = _tokenId[i];
                    } else if (level == XP.getLevel(tokenId)) {
                        if (tokenId > _tokenId[i]) {
                            tokenId = _tokenId[i];
                        }
                    } else {
                        continue;
                    }
                } else {
                    continue;
                }
            }
            uint256 _rarity = PM.getRarity(tokenId);
            uint256 _level = XP.getLevel(tokenId);
            if (boostPG(user)) {
                _level = _level.add(5);
            }
            _baseRate = pmRate[_rarity][_level];
            if (boostPB(user)) {
                _baseRate = _baseRate.mul(110).div(100);
            }
            _maxRate = maxPMRate[_rarity][_level];
        }
    }

    function bestPM (address user) public view returns (uint256) {
        (uint256 tokenId, , ) = bestPlanetMan(user);
        return tokenId;
    }

    function bestBasePMRate (address user) public view returns (uint256) {
        ( , uint256 _baseRate, ) = bestPlanetMan(user);
        return _baseRate;
    }

    function bestMaxPMRate (address user) public view returns (uint256) {
        ( , , uint256 _maxRate) = bestPlanetMan(user);
        return _maxRate;
    }

    /* Synergy */
    function syncPMRate (address user) public view returns (uint256 rate) {
        uint256[] memory tokenId = PM.getAllTokens(user);
        if (tokenId.length > 0) {
            uint256 bestRarity = PM.getRarity(bestPM(user));
            for (uint256 i=0; i<tokenId.length; i++) {
                uint256 rarity = PM.getRarity(tokenId[i]);
                if (rarity < bestRarity) {
                    uint256 level = XP.getLevel(tokenId[i]);
                    if (boostPG(user)) {
                        level = level.add(5);
                    }
                    rate = rate.add(pmRate[rarity][level]);
                } else {
                    continue;
                }
            }
            if (boostPB(user)) {
                rate = rate.mul(110).div(100);
            }
            rate = rate.add(bestBasePMRate(user));
            if (rate > bestMaxPMRate(user)) {
                rate = bestMaxPMRate(user);
            }
        }
    }

/** Staking Level **/
    uint256[] public baseStakeRate = [ /* 10 ** 16 */
        0, 20, 50, 100, 300, 500, 800, 1200, 1500, 1800, 2000, 2300, 2600, 3000, 3500, 3750, 4000, 4500, 5000, 5500, 6000
    ];

    function stakeLevel (address user) public view returns (uint256) {
        return LV.Level(user);
    }

    function stakeRate (address user) public view returns (uint256) {
        return baseStakeRate[stakeLevel(user)];
    }

/** Final Rate **/
    function getRate (address user) public view returns (uint256 rate) {
        rate = baseUserRate.add(stakeRate(user));
        if (pm.balanceOf(user) > 0) {
            rate = rate.add(syncPMRate(user));
        }
        rate = rate.mul(10**16);
    }

/** BlackHole SBT **/
    uint256[] public baseBHRate = [ /* 10 ** 16 */
        0, 1, 2, 3, 4, 5, 7, 8, 10, 12, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35
    ];

    function bhRate (uint256 tokenId) public view returns (uint256) {
        uint256 level = XP.getLevelCom(tokenId);
        return baseBHRate[level].mul(10**16);
    }

/*** $MetaX Calculation ***/
    uint256 public maxRelease_SM = 38356164 ether; /* 40% allocation | halve every 2 years | released in epoch */
    uint256 public maxRelease_BI =  4794517 ether; /*  5% allocation | halve every 2 years | released in epoch */

    function getToken (address user, uint256 posw) public view returns (uint256) {
        uint256 _posw = posw.div(10**18);
        return _posw.mul(getRate(user));
    }

    function getToken_BH (uint256 tokenId, uint256 posw) public view returns (uint256) {
        uint256 _posw = posw.div(10**18);
        return _posw.mul(bhRate(tokenId));
    }
}