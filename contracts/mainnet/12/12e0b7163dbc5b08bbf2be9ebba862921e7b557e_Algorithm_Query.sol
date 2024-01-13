/**
 *Submitted for verification at Arbiscan.io on 2024-01-12
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

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

    function Gas (uint256 tokenId) external view returns (uint256);

    function getLevelCom (uint256 tokenId) external view returns (uint256 level);

    function gasCom (uint256 tokenId) external view returns (uint256);

/* PlanetKey */
    function Gas (address user) external view returns (uint256);

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

/** SocialMiningV2 **/
    function getRecentClaimed (address user) external view returns (uint256);

/** Algorithm **/
    function bestPM (address user) external view returns (uint256);

    function syncPMRate (address user) external view returns (uint256 rate);

    function stakeRate (address user) external view returns (uint256);

    function getRate (address user) external view returns (uint256 rate);

    function bhRate (uint256 tokenId) external view returns (uint256);

    function getToken (address user, uint256 posw) external view returns (uint256);

    function getToken_BH (uint256 tokenId, uint256 posw) external view returns (uint256);

    function getIntWeight (address user0, address user1) external view returns (uint256 weight);

/** Red Pocket **/
    function getAccumSend (address user) external view returns (uint256);

    function getAccumSendByUser (address user0, address user1) external view returns (uint256);

    function getEpochSendByUser (address user0, address user1, uint256 epoch) external view returns (uint256);

    function getCurrentSendByUser (address user0, address user1) external view returns (uint256);
}
// File: SocialMining_V2/Algorithm_Query.sol


pragma solidity 0.8.20;




contract Algorithm_Query is Ownable {

/** Smart Contracts **/
    /* $MetaX */
    IERC20 public MetaX;

    function setMetaX (address MetaX_addr) public onlyOwner {
        MetaX = IERC20(MetaX_addr);
    }

    /* POSW */
    IMetaX public POSW;

    function setPOSW (address POSW_addr) public onlyOwner {
        POSW = IMetaX(POSW_addr);
    }

    /* XPower */
    IMetaX public PM;
    IMetaX public XP;

    function setXPower (address PlanetMan_addr, address XPower_addr) public onlyOwner {
        PM = IMetaX(PlanetMan_addr);
        XP = IMetaX(XPower_addr);
    }

    /* PlanetKey */
    IMetaX public Key;

    function setPlanetKey (address PlanetKey_addr) public onlyOwner {
        Key = IMetaX(PlanetKey_addr);
    }

    /* PlanetBadges */
    IMetaX public PB;

    function setPlanetBadges (address PlanetBadges_addr) public onlyOwner {
        PB = IMetaX(PlanetBadges_addr);
    }

    /* Staking Level */
    IMetaX public LV;

    function setStakingLevel (address StakingLevel_addr) public onlyOwner {
        LV = IMetaX(StakingLevel_addr);
    }

    /* SocialMiningV2 */
    IMetaX public SM;

    function setSocialMiningV2 (address SocialMiningV2_addr) public onlyOwner {
        SM = IMetaX(SocialMiningV2_addr);
    }

    /* Algorithm */
    IMetaX public Alg;

    function setAlgorithm (address Algorithm_addr) public onlyOwner {
        Alg = IMetaX(Algorithm_addr);
    }

    /* Red Pocket */
    IMetaX public Red;

    function setRedPocket (address RedPocket_addr) public onlyOwner {
        Red = IMetaX(RedPocket_addr);
    }

/** Initialization **/
    constructor (
        address MetaX_addr,
        address POSW_addr,
        address PlanetMan_addr,
        address XPower_addr,
        address PlanetKey_addr,
        address PlanetBadges_addr,
        address StakingLevel_addr,
        address SocialMiningV2_addr,
        address Algorithm_addr,
        address RedPocket_addr
    ) {
        setMetaX(MetaX_addr);
        setPOSW(POSW_addr);
        setXPower(PlanetMan_addr, XPower_addr);
        setPlanetKey(PlanetKey_addr);
        setPlanetBadges(PlanetBadges_addr);
        setStakingLevel(StakingLevel_addr);
        setSocialMiningV2(SocialMiningV2_addr);
        setAlgorithm(Algorithm_addr);
        setRedPocket(RedPocket_addr);
    }

/** Algorithm **/
    function getRate_batch (address[] memory user) public view returns (uint256[] memory) {
        uint256[] memory rate = new uint256[](user.length);
        for (uint256 i=0; i<user.length; i++) {
            rate[i] = Alg.getRate(user[i]);
        }
        return rate;
    }

    function getToken_batch (address[] memory user, uint256[] memory posw) public view returns (uint256[] memory) {
        uint256[] memory token = new uint256[](user.length);
        for (uint256 i=0; i<user.length; i++) {
            token[i] = Alg.getToken(user[i], posw[i]);
        }
        return token;
    }

    function getToken_BH_batch (uint256[] memory tokenId, uint256[] memory posw) public view returns (uint256[] memory) {
        uint256[] memory token = new uint256[](tokenId.length);
        for (uint256 i=0; i<tokenId.length; i++) {
            token[i] = Alg.getToken_BH(tokenId[i], posw[i]);
        }
        return token;
    }

    function bestPM_batch (address[] memory user) public view returns (uint256[] memory) {
        uint256[] memory tokenId = new uint256[](user.length);
        for (uint256 i=0; i<user.length; i++) {
            tokenId[i] = Alg.bestPM(user[i]);
        }
        return tokenId;
    }

    function syncPMRate_batch (address[] memory user) public view returns (uint256[] memory) {
        uint256[] memory syncRate = new uint256[](user.length);
        for (uint256 i=0; i<user.length; i++) {
            syncRate[i] = Alg.syncPMRate(user[i]);
        }
        return syncRate;
    }

    function stakeRate_batch (address[] memory user) public view returns (uint256[] memory) {
        uint256[] memory stakeRate = new uint256[](user.length);
        for (uint256 i=0; i<user.length; i++) {
            stakeRate[i] = Alg.stakeRate(user[i]);
        }
        return stakeRate;
    }

    function bhRate_batch (uint256[] memory tokenId) public view returns (uint256[] memory) {
        uint256[] memory bhRate = new uint256[](tokenId.length);
        for (uint256 i=0; i<tokenId.length; i++) {
            bhRate[i] = Alg.bhRate(tokenId[i]);
        }
        return bhRate;
    }

    function getIntWeight_batch (address[] memory user0, address[] memory user1) public view returns (uint256[] memory) {
        uint256[] memory weight = new uint256[](user0.length);
        for (uint256 i=0; i<user0.length; i++) {
            weight[i] = Alg.getIntWeight(user0[i], user1[i]);
        }
        return weight;
    }

/** XPower **/
    function getRarity_batch (uint256[] memory tokenId) public view returns (uint256[] memory) {
        uint256[] memory rarity = new uint256[](tokenId.length);
        for (uint256 i=0; i<tokenId.length; i++) {
            rarity[i] = PM.getRarity(tokenId[i]);
        }
        return rarity;
    }

    function getLevel_batch (uint256[] memory tokenId) public view returns (uint256[] memory) {
        uint256[] memory level = new uint256[](tokenId.length);
        for (uint256 i=0; i<tokenId.length; i++) {
            level[i] = XP.getLevel(tokenId[i]);
        }
        return level;
    }

    function gasPM_batch (uint256[] memory tokenId) public view returns (uint256[] memory) {
        uint256[] memory gas = new uint256[](tokenId.length);
        for (uint256 i=0; i<tokenId.length; i++) {
            gas[i] = XP.Gas(tokenId[i]);
        }
        return gas;
    }

    function getLevelCom_batch (uint256[] memory tokenId) public view returns (uint256[] memory) {
        uint256[] memory level = new uint256[](tokenId.length);
        for (uint256 i=0; i<tokenId.length; i++) {
            level[i] = XP.getLevelCom(tokenId[i]);
        }
        return level;
    }

    function gasCom_batch (uint256[] memory tokenId) public view returns (uint256[] memory) {
        uint256[] memory gas = new uint256[](tokenId.length);
        for (uint256 i=0; i<tokenId.length; i++) {
            gas[i] = XP.gasCom(tokenId[i]);
        }
        return gas;
    }

/** PlanetKey **/
    function gasKey_batch (address[] memory user) public view returns (uint256[] memory) {
        uint256[] memory gas = new uint256[](user.length);
        for (uint256 i=0; i<user.length; i++) {
            gas[i] = Key.Gas(user[i]);
        }
        return gas;
    }

/** PlanetBadges **/
    function getBoostNum_batch (address[] memory user) public view returns (uint256[] memory) {
        uint256[] memory boostNum = new uint256[](user.length);
        for (uint256 i=0; i<user.length; i++) {
            boostNum[i] = PB.getBoostNum(user[i]);
        }
        return boostNum;
    }

/** SocialMiningV2 **/
    function getRecentClaimed_batch (address[] memory user) public view returns (uint256[] memory) {
        uint256[] memory recent = new uint256[](user.length);
        for (uint256 i=0; i<user.length; i++) {
            recent[i] = SM.getRecentClaimed(user[i]);
        }
        return recent;
    }

/* Staking Level */
    function stakingLevel_batch (address[] memory user) public view returns (uint256[] memory) {
        uint256[] memory level = new uint256[](user.length);
        for (uint256 i=0; i<user.length; i++) {
            level[i] = LV.Level(user[i]);
        }
        return level;
    }

    function Adjustment_batch (address[] memory user) public view returns (uint256[] memory) {
        uint256[] memory adj = new uint256[](user.length);
        for (uint256 i=0; i<user.length; i++) {
            adj[i] = LV.Adjustment(user[i]);
        }
        return adj;
    }

    function finalScores_batch (address[] memory user) public view returns (uint256[] memory) {
        uint256[] memory scores = new uint256[](user.length);
        for (uint256 i=0; i<user.length; i++) {
            scores[i] = LV.finalScores(user[i]);
        }
        return scores;
    }

/** Red Pocket **/
    function getAccumSend_batch (address[] memory user) public view returns (uint256[] memory) {
        uint256[] memory send = new uint256[](user.length);
        for (uint256 i=0; i<user.length; i++) {
            send[i] = Red.getAccumSend(user[i]);
        }
        return send;
    }
}