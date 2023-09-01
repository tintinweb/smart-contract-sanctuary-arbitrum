// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Interface/IMetaX.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract POSWRequest_temporary is Ownable {

/** Smart Contracts Preset **/
    /* User POSW */
    address public POSW_Addr;

    IMetaX public POSW;

    function setPOSW(address _POSW_Addr) public onlyOwner {
        POSW_Addr = _POSW_Addr;
        POSW = IMetaX(_POSW_Addr);
    }

    /* Builder POSW */
    address public BlackHole_Addr;

    IMetaX public BH;

    function setBlackHole(address _BlackHole_Addr) public onlyOwner {
        BlackHole_Addr = _BlackHole_Addr;
        BH = IMetaX(_BlackHole_Addr);
    }

/*** User POSW Request ***/
  /** User POSW Request **/
    /* User POSW Overall */
    function getPOSW (address user) public view returns (uint256) {
        return POSW.getPOSW(user);
    }

    /* User POSW by Version */
    function getPOSW_Version (address user, uint256 _version) public view returns (uint256) {
        return POSW.getPOSW_Version(user, _version);
    }

    /* User POSW by Social Platform */
    function getPOSW_SocialPlatform (address user, uint256 _socialPlatform) public view returns (uint256) {
        return POSW.getPOSW_SocialPlatform(user, _socialPlatform);
    }

    /* User POSW by Community */
    function getPOSW_Community (address user, uint256 _community) public view returns (uint256) {
        return POSW.getPOSW_Community(user, _community);
    }

    /* User POSW by Version & Social Platform */
    function getPOSW_Version_SocialPlatform (address user, uint256 _version, uint256 _socialPlatform) public view returns (uint256) {
        return POSW.getPOSW_Version_SocialPlatform(user, _version, _socialPlatform);
    }

    /* User POSW by Version & Community */
    function getPOSW_Version_Community (address user, uint256 _version, uint256 _community) public view returns (uint256) {
        return POSW.getPOSW_Version_Community(user, _version, _community);
    }

    /* User POSW by Social Platform & Community */
    function getPOSW_SocialPlatform_Community (address user, uint256 _socialPlatform, uint256 _community) public view returns (uint256) {
        return POSW.getPOSW_SocialPlatform_Community(user, _socialPlatform, _community);
    }

    /* User POSW by Version & Social Platform & Community */
    function getPOSW_Version_SocialPlatform_Community (address user, uint256 _version, uint256 _socialPlatform, uint256 _community) public view returns (uint256) {
        return POSW.getPOSW_Version_SocialPlatform_Community(user, _version, _socialPlatform, _community);
    }

  /** Global User POSW Request **/
    /* Global POSW Overall */
    function getGlobalPOSW_Overall () public view returns (uint256) {
        return POSW.getGlobalPOSW_Overall();
    }

    /* Global POSW by Version */
    function getGlobalPOSW_Version (uint256 _version) public view returns (uint256) {
        return POSW.getGlobalPOSW_Version(_version);
    }

    /* Global POSW by Social Platform */
    function getGlobalPOSW_SocialPlatform (uint256 _socialPlatform) public view returns (uint256) {
        return POSW.getGlobalPOSW_SocialPlatform(_socialPlatform);
    }

    /* Global POSW by Community */
    function getGlobalPOSW_Community (uint256 _community) public view returns (uint256) {
        return POSW.getGlobalPOSW_Community(_community);
    }

    /* Global POSW by Version & Social Platform */
    function getGlobalPOSW_Version_SocialPlatform (uint256 _version, uint256 _socialPlatform) public view returns (uint256) {
        return POSW.getGlobalPOSW_Version_SocialPlatform(_version, _socialPlatform);
    }

    /* Global POSW by Version & Community */
    function getGlobalPOSW_Version_Community (uint256 _version, uint256 _community) public view returns (uint256) {
        return POSW.getGlobalPOSW_Version_Community(_version, _community);
    }

    /* Global POSW by Social Platform & Community */
    function getGlobalPOSW_SocialPlatform_Community (uint256 _socialPlatform, uint256 _community) public view returns (uint256) {
        return POSW.getGlobalPOSW_SocialPlatform_Community(_socialPlatform, _community);
    }

    /* Global POSW by Version & Social Platform & Community */
    function getGlobalPOSW_Version_SocialPlatform_Community (uint256 _version, uint256 _socialPlatform, uint256 _community) public view returns (uint256) {
        return POSW.getGlobalPOSW_Version_SocialPlatform_Community(_version, _socialPlatform, _community);
    }

/*** Builder POSW Request ***/
    function getPOSW_Builder (uint256 _tokenId) public view returns (uint256) {
        return BH.getPOSW_Builder(_tokenId);
    }

    function getPOSW_Builder_Owner (uint256 _tokenId) public view returns (uint256) {
        return BH.getPOSW_Builder_Owner(_tokenId);
    }

    function getPOSW_Builder_SocialPlatform (uint256 _tokenId, uint256 _socialPlatform) public view returns (uint256) {
        return BH.getPOSW_Builder_SocialPlatform(_tokenId, _socialPlatform);
    }

    function getPOSW_Builder_SocialPlatform_Owner (uint256 _tokenId, uint256 _socialPlatform) public view returns (uint256) {
        return BH.getPOSW_Builder_SocialPlatform_Owner(_tokenId, _socialPlatform);
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


/** XPower of PlanetMan **/
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