//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
                    ____     ____
                  /'    |   |    \
                /    /  |   | \   \
              /    / |  |   |  \   \
             (   /   |  """"   |\   \       
             | /   / /^\    /^\  \  _|           
              ~   | |   |  |   | | ~
                  | |__O|__|O__| |
                /~~      \/     ~~\
               /   (      |      )  \
         _--_  /,   \____/^\___/'   \  _--_
       /~    ~\ / -____-|_|_|-____-\ /~    ~\
     /________|___/~~~~\___/~~~~\ __|________\
--~~~          ^ |     |   |     |  -     :  ~~~~~:~-_     ___-----~~~~~~~~|
   /             `^-^-^'   `^-^-^'                  :  ~\ /'   ____/--------|
       --                                            ;   |/~~~------~~~~~~~~~|
 ;                                    :              :    |----------/--------|
:                     ,                           ;    .  |---\\--------------|
 :     -                          .                  : : |______________-__|
  :              ,                 ,                :   /'~----___________|
__  \\\        ^                          ,, ;; ;; ;._-~
  ~~~-----____________________________________----~~~


     _______.___________.  ______    __       _______ .__   __. .______     ______     ______    __      
    /       |           | /  __  \  |  |     |   ____||  \ |  | |   _  \   /  __  \   /  __  \  |  |     
   |   (----`---|  |----`|  |  |  | |  |     |  |__   |   \|  | |  |_)  | |  |  |  | |  |  |  | |  |     
    \   \       |  |     |  |  |  | |  |     |   __|  |  . `  | |   ___/  |  |  |  | |  |  |  | |  |     
.----)   |      |  |     |  `--'  | |  `----.|  |____ |  |\   | |  |      |  `--'  | |  `--'  | |  `----.
|_______/       |__|      \______/  |_______||_______||__| \__| | _|       \______/   \______/  |_______|
                                                                                                         

 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./KarrotInterfaces.sol";

/**
StolenPool: where the stolen karrots go
- claim tax (rabbits stealing karrots) from karrotChef are deposited here
- every deposit is grouped into an epoch (1 day) based on time of deposit
- rabbit attacks during this epoch are weighted by tier and stake claim to a portion of the epoch's deposited karrots
- epoch ends, rewards are calculated, and rewards are claimable by attackers based on tier and number of successful attacks during that epoch
- rewards are claimable only for previous epochs (not current)
 */
 
contract KarrotStolenPool is AccessControl, ReentrancyGuard {
    
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    IAttackRewardCalculator public rewardCalculator;
    IConfig public config;

    address public outputAddress;
    bool public poolOpenTimestampSet;
    bool public stolenPoolAttackIsOpen = false;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    uint16 public constant PERCENTAGE_DENOMINATOR = 10000;
    uint16 public attackBurnPercentage = 1000; //10%
    uint16 public rabbitTier1AttackRewardsWeight = 10000; //1x
    uint16 public rabbitTier2AttackRewardsWeight = 25000; //2.5x
    uint16 public rabbitTier3AttackRewardsWeight = 50000; //5x

    uint32 public poolOpenTimestamp = 1685134906; //start timestamp of v1 to preserve epoch numberings
    uint32 public stolenPoolEpochLength = 1 days; //1 day
    uint32 public totalAttacks;

    uint256 public totalClaimedRewardsForAll;
    uint256 public totalBurned;
    uint256 public totalMinted;

    mapping(uint256 => uint256) public epochBalances;
    mapping(address => Attack[]) public userAttacks;
    mapping(uint256 => EpochAttackStats) public epochAttackStats;
    mapping(address => UserAttackStats) public userAttackStats;
    mapping(address => uint256) public manuallyAddedRewards;

    struct UserAttackStats {
        uint32 successfulAttacks;
        uint32 lastClaimEpoch;
        uint192 totalClaimedRewards;
    }

    struct EpochAttackStats {
        uint32 tier1;
        uint32 tier2;
        uint32 tier3;
        uint160 total;
    }

    struct Attack {
        uint216 epoch; //takes into account calcs for reward per attack by tier for this epoch (range of timestamps)
        uint32 rabbitId;
        uint8 tier;
        address user;
    }

    event AttackEvent(address indexed sender, uint256 tier);
    event StolenPoolRewardClaimed(address indexed sender, uint256 amount);

    error InvalidCaller(address caller, address expected);
    error CallerIsNotConfig();
    error ForwardFailed();
    error NoRewardsToClaim();
    error PoolOpenTimestampNotSet();
    error PoolOpenTimestampAlreadySet();
    error FirstEpochHasNotPassedYet(uint256 remainingTimeUntilFirstEpochPasses);
    error InvalidRabbitTier();
    error AlreadyClaimedCurrentEpoch();

    constructor(address _configAddress) {
        config = IConfig(_configAddress);
        rewardCalculator = IAttackRewardCalculator(config.attackRewardCalculatorAddress());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    modifier attackIsOpen() {
        require(stolenPoolAttackIsOpen, "Attack is not open");
        _;
    }

    modifier onlyConfig() {
        if (msg.sender != address(config)) {
            revert CallerIsNotConfig();
        }
        _;
    }

    function batchSetManuallyAddedRewards(address[] memory _users, uint256[] memory _amounts) external onlyRole(ADMIN_ROLE) {
        require(_users.length == _amounts.length, "Invalid input");
        for (uint256 i = 0; i < _users.length; i++) {
            manuallyAddedRewards[_users[i]] = _amounts[i];
        }
    }

    function setManuallyAddedRewardsForUser(address _user, uint256 _amount) public onlyRole(ADMIN_ROLE) {
        manuallyAddedRewards[_user] = _amount;
    }

    function deposit(uint256 _amount) external {

        //add to this epoch's balance
        uint256 currentEpoch = getCurrentEpoch();
        epochBalances[currentEpoch] += _amount;
        totalBurned += _amount;

        //'burn' input tokens
        IKarrotsToken(config.karrotsAddress()).transferFrom(msg.sender, DEAD_ADDRESS, _amount);

    }

    // [!] check logik - make sure cooldown is controlled from the rabbit contract
    function attack(address _sender, uint256 _rabbitTier, uint256 _rabbitId) external attackIsOpen {
        //caller must be Rabbit contract
        address rabbitAddress = config.rabbitAddress();
        if (msg.sender != rabbitAddress) {
            revert InvalidCaller(msg.sender, rabbitAddress);
        }

        uint256 currentEpoch = getCurrentEpoch();

        //update overall attack stats for this epoch
        if (_rabbitTier == 1) {
            ++epochAttackStats[currentEpoch].tier1;
        } else if (_rabbitTier == 2) {
            ++epochAttackStats[currentEpoch].tier2;
        } else if (_rabbitTier == 3) {
            ++epochAttackStats[currentEpoch].tier3;
        } else {
            revert InvalidRabbitTier();
        }

        ++epochAttackStats[currentEpoch].total;
        ++totalAttacks;

        //set successful attacks for this rabbit id/user and tier and epoch
        userAttacks[_sender].push(Attack(uint216(currentEpoch), uint32(_rabbitId), uint8(_rabbitTier), _sender));
        ++userAttackStats[_sender].successfulAttacks;       
        
        
        emit AttackEvent(_sender, _rabbitTier);
    }

    function claimRewards() external nonReentrant {

        if(userAttackStats[msg.sender].lastClaimEpoch == uint32(getCurrentEpoch())) {
            revert AlreadyClaimedCurrentEpoch();
        }

        uint256 totalRewardsForUser = getPretaxPendingRewards(msg.sender);
        manuallyAddedRewards[msg.sender] = 0; //reset to 0 after claim

        if (totalRewardsForUser == 0) {
            revert NoRewardsToClaim();
        }

        uint256 burnAmount = Math.mulDiv(
            totalRewardsForUser,
            attackBurnPercentage,
            PERCENTAGE_DENOMINATOR
        );
        
        //update last claim epoch to current epoch to prevent double claiming
        userAttackStats[msg.sender].lastClaimEpoch = uint32(getCurrentEpoch());
        userAttackStats[msg.sender].totalClaimedRewards += uint192(totalRewardsForUser - burnAmount);
        totalClaimedRewardsForAll += totalRewardsForUser - burnAmount;        
        
        // send remaining rewards to user
        totalMinted += totalRewardsForUser - burnAmount;
        IKarrotsToken(config.karrotsAddress()).mint(msg.sender, totalRewardsForUser - burnAmount);

        emit StolenPoolRewardClaimed(msg.sender, totalRewardsForUser - burnAmount);
    }

    function getCurrentEpoch() public view returns (uint256) {
        return Math.mulDiv(
            block.timestamp - poolOpenTimestamp,
            1,
            stolenPoolEpochLength
        );
    }

    // [!] burn pool tokens from empty epochs or claim to treasury if desired, otherwise, leaving them is like burning...
    function transferExtraToTreasury() external onlyRole(ADMIN_ROLE) {
        //add amounts from any epochs without claims to claimable balance, set those epoch balances to 0
        uint256 claimableBalance;
        uint256 currentEpoch = getCurrentEpoch();
        for (uint256 i = 0; i < currentEpoch; i++) {
            if(epochAttackStats[i].total == 0){
                claimableBalance += epochBalances[i];
                epochBalances[i] = 0;    
            }
        }

        IKarrotsToken(config.karrotsAddress()).mint(config.treasuryBAddress(), claimableBalance);
    }

    function getEpochLength() public view returns (uint256) {
        return stolenPoolEpochLength;
    }

    //get seconds until next epoch, with handling for 0th epoch / just starting the pool
    function getSecondsUntilNextEpoch() public view returns (uint256) {
        return stolenPoolEpochLength - ((block.timestamp - poolOpenTimestamp) % stolenPoolEpochLength);
    }

    function getCurrentEpochBalance() public view returns (uint256) {
        uint256 currentEpoch = getCurrentEpoch();
        return epochBalances[currentEpoch];
    }

    function getEpochBalance(uint256 _epoch) public view returns (uint256) {
        return epochBalances[_epoch];
    }

    function getUserAttackEpochs(address _user) public view returns (uint256[] memory) {
        uint256[] memory epochs = new uint256[](userAttacks[_user].length);
        for (uint256 i = 0; i < userAttacks[_user].length; ++i) {
            epochs[i] = userAttacks[_user][i].epoch;
        }
        return epochs;
    }

    function getUserAttackRabbitId(uint256 _index) public view returns (uint256) {
        return userAttacks[msg.sender][_index].rabbitId;
    }

    function getUserAttackTier(uint256 _index) public view returns (uint256) {
        return userAttacks[msg.sender][_index].tier;
    }

    /**
        @dev calculate user rewards by summing up rewards from each epoch
        rewards from each epoch are calculated as: baseReward = (total karrots deposited this epoch) / (total successful attacks this epoch)
        where baseReward is scaled based on tier of rabbit attacked such that the relative earnings are: tier 1 = 1x, tier 2 = 2x, tier 3 = 5x
        and 95% of the baseReward is given to the user and 5% is sent to treasury B
     */
    function getPretaxPendingRewards(address _user) public view returns (uint256) {
        //claim rewards from lastClaimEpoch[_user] to currentEpoch
        uint256 currentEpoch = getCurrentEpoch();
        uint256 lastClaimedEpoch = userAttackStats[_user].lastClaimEpoch;

        uint256 totalRewardsForUser;
        for (uint256 i = lastClaimedEpoch; i < currentEpoch; ++i) {
            //get total deposited karrots this epoch
            
            if(epochBalances[i] == 0) {
                continue;
            }

            (uint256 tier1RewardsPerAttack, uint256 tier2RewardsPerAttack, uint256 tier3RewardsPerAttack) = getPretaxPendingRewardsForEpoch(i);

            //now that I have the rewards per attack for each tier, I can calculate the total rewards for the user
            uint256 totalRewardCurrentEpoch = 0;
            for (uint256 j = 0; j < userAttacks[_user].length; ++j) {
                Attack memory thisAttack = userAttacks[_user][j];
                if (thisAttack.epoch == i) {
                    if (thisAttack.tier == 1) {
                        totalRewardCurrentEpoch += tier1RewardsPerAttack;
                    } else if (thisAttack.tier == 2) {
                        totalRewardCurrentEpoch += tier2RewardsPerAttack;
                    } else if (thisAttack.tier == 3) {
                        totalRewardCurrentEpoch += tier3RewardsPerAttack;
                    }
                }
            }

            totalRewardsForUser += totalRewardCurrentEpoch;
        }

        totalRewardsForUser += manuallyAddedRewards[_user];

        return totalRewardsForUser;
    }


    function getPretaxPendingRewardsForEpoch(uint256 _epoch) public view returns (uint256, uint256, uint256) {
        //get total deposited karrots this epoch
        uint256 totalKarrotsDepositedCurrentEpoch = epochBalances[_epoch];
        EpochAttackStats memory currentEpochStats = epochAttackStats[_epoch];
        uint256 tier1Attacks = currentEpochStats.tier1;
        uint256 tier2Attacks = currentEpochStats.tier2;
        uint256 tier3Attacks = currentEpochStats.tier3;

        //get rewards per attack for each tier [tier1, tier2, tier3]
        uint256[] memory rewardsPerAttackByTier = rewardCalculator.calculateRewardPerAttackByTier(
            tier1Attacks,
            tier2Attacks,
            tier3Attacks,
            rabbitTier1AttackRewardsWeight,
            rabbitTier2AttackRewardsWeight,
            rabbitTier3AttackRewardsWeight,
            totalKarrotsDepositedCurrentEpoch
        );

        return (rewardsPerAttackByTier[0], rewardsPerAttackByTier[1], rewardsPerAttackByTier[2]);
    }

    function getPosttaxPendingRewards(address _user) public view returns (uint256) {
        uint256 pretaxRewards = getPretaxPendingRewards(_user);
        uint256 posttaxRewards = Math.mulDiv(
            pretaxRewards,
            PERCENTAGE_DENOMINATOR - attackBurnPercentage,
            PERCENTAGE_DENOMINATOR
        );
        return posttaxRewards;
    }

    function getUserSuccessfulAttacks(address _user) public view returns (uint256) {
        return userAttackStats[_user].successfulAttacks;
    }

    function getUserLastClaimEpoch(address _user) public view returns (uint256) {
        return userAttackStats[_user].lastClaimEpoch;
    }

    function getUserTotalClaimedRewards(address _user) public view returns (uint256) {
        return userAttackStats[_user].totalClaimedRewards;
    }

    function getEpochTier1Attacks(uint256 _epoch) public view returns (uint256) {
        return epochAttackStats[_epoch].tier1;
    }

    function getEpochTier2Attacks(uint256 _epoch) public view returns (uint256) {
        return epochAttackStats[_epoch].tier2;
    }

    function getEpochTier3Attacks(uint256 _epoch) public view returns (uint256) {
        return epochAttackStats[_epoch].tier3;
    }

    function getEpochTotalAttacks(uint256 _epoch) public view returns (uint256) {
        return epochAttackStats[_epoch].total;
    }

    //=========================================================================
    // SETTERS/WITHDRAWALS
    //=========================================================================

    //corresponds to the call of karrotChef.openKarrotChefDeposits()
    function setStolenPoolOpenTimestamp() external onlyConfig {
        if (!poolOpenTimestampSet) {
            //set timestamp for the start of epochs
            poolOpenTimestamp = uint32(block.timestamp);
            poolOpenTimestampSet = true;
        } else {
            revert PoolOpenTimestampAlreadySet();
        }
    }

    function setPoolOpenTimestampManual(uint32 _timestamp) external onlyRole(ADMIN_ROLE) {
        poolOpenTimestamp = _timestamp;
    }

    function setStolenPoolAttackIsOpen(bool _isOpen) external onlyConfig {
        stolenPoolAttackIsOpen = _isOpen;
    }

    function setStolenPoolAttackIsOpenManual(bool _isOpen) external onlyRole(ADMIN_ROLE) {
        stolenPoolAttackIsOpen = _isOpen;
    }

    function setAttackBurnPercentage(uint16 _percentage) external onlyConfig {
        attackBurnPercentage = _percentage;
    }

    function setAttackBurnPercentageManual(uint16 _percentage) external onlyRole(ADMIN_ROLE) {
        attackBurnPercentage = _percentage;
    }

    function setStolenPoolEpochLength(uint32 _epochLength) external onlyConfig {
        stolenPoolEpochLength = _epochLength;
    }

    function setStolenEpochLengthManual(uint32 _epochLength) external onlyRole(ADMIN_ROLE) {
        stolenPoolEpochLength = _epochLength;
    }

    function setAttackRewardCalculator(address _attackRewardCalculator) external onlyRole(ADMIN_ROLE) {
        rewardCalculator = IAttackRewardCalculator(_attackRewardCalculator);
    }

    //-------------------------------------------------------------------------

    function setConfigManagerAddress(address _configManagerAddress) external onlyRole(ADMIN_ROLE) {
        config = IConfig(_configManagerAddress);
    }

    function setOutputAddress(address _outputAddress) external onlyRole(ADMIN_ROLE) {
        outputAddress = _outputAddress;
    }

    function withdrawERC20FromContract(address _to, address _token) external onlyRole(ADMIN_ROLE) {
        bool os = IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
        if (!os) {
            revert ForwardFailed();
        }
    }

    function withdrawEthFromContract() external onlyRole(ADMIN_ROLE) {
        require(outputAddress != address(0), "Payment splitter address not set");
        (bool os, ) = payable(outputAddress).call{value: address(this).balance}("");
        if (!os) {
            revert ForwardFailed();
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
pragma solidity ^0.8.19;

//================================================================================
// COMPLETE (interfaces with all functions used across contracts)
//================================================================================

interface IConfig {
    function dexInterfacerAddress() external view returns (address);
    function karrotsAddress() external view returns (address);
    function karrotChefAddress() external view returns (address);
    function karrotStolenPoolAddress() external view returns (address);
    function karrotFullProtecAddress() external view returns (address);
    function karrotsPoolAddress() external view returns (address);
    function rabbitAddress() external view returns (address);
    function randomizerAddress() external view returns (address);
    function sushiswapRouterAddress() external view returns (address);
    function sushiswapFactoryAddress() external view returns (address);
    function treasuryAddress() external view returns (address);
    function treasuryBAddress() external view returns (address);
    function teamSplitterAddress() external view returns (address);
    function presaleDistributorAddress() external view returns (address);
    function attackRewardCalculatorAddress() external view returns (address);
}

interface IKarrotChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function claim(uint256 _pid) external;
    function attack() external;
    function randomizerWithdrawKarrotChef(address _to, uint256 _amount) external;
    function getUserStakedAmount(address _user) external view returns (uint256);
    function getTotalStakedAmount() external view returns (uint256);
    function updateConfig() external;
    function setAllocationPoint(uint256 _pid, uint128 _allocPoint, bool _withUpdatePools) external;
    function setLockDuration(uint256 _pid, uint256 _lockDuration) external;
    function updateRewardPerBlock(uint88 _rewardPerBlock) external;
    function setCompoundRatio(uint48 _compoundRatio) external;
    function openKarrotChefDeposits() external;
    function setDepositIsPaused(bool _isPaused) external;
    function setThresholdFullProtecKarrotBalance(uint256 _thresholdFullProtecKarrotBalance) external;
    function setClaimTaxRate(uint16 _maxTaxRate) external;
    function randomzierWithdraw(address _to, uint256 _amount) external;
    function setRandomizerClaimCallbackGasLimit(uint24 _randomizerClaimCallbackGasLimit) external;
    function setFullProtecLiquidityProportion(uint16 _fullProtecLiquidityProportion) external;
    function setClaimTaxChance(uint16 _claimTaxChance) external;
}

interface IKarrotsToken {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function updateConfig() external;
    function addDexAddress(address _dexAddress) external;
    function removeDexAddress(address _dexAddress) external;
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferUnderlying(address to, uint256 value) external returns (bool);
    function fragmentToKarrots(uint256 value) external view returns (uint256);
    function karrotsToFragment(uint256 karrots) external view returns (uint256);
    function balanceOfUnderlying(address who) external view returns (uint256);
    function setSellTaxRate(uint16 _sellTaxRate) external;
    function setBuyTaxRate(uint16 _buyTaxRate) external;
    function setSellTaxIsActive(bool _sellTaxIsActive) external;
    function setBuyTaxIsActive(bool _buyTaxIsActive) external;
    function setTradingIsOpen(bool _tradingIsOpen) external;
    function setMaxIndexDelta(uint256 _maxIndexDelta) external;
    function setTransferTradingBlockIsOn(bool _transferTradingBlockIsOn) external;
}

interface IRabbit {
    function getRabbitSupply() external view returns (uint256);
    function getRabbitIdsByOwner(address _owner) external view returns (uint256[] memory);
    function updateConfig() external;
    function randomizerWithdrawRabbit(address _to, uint256 _amount) external;
    function setRabbitMintIsOpen(bool _isOpen) external;
    function setRabbitBatchSize(uint16 _batchSize) external;
    function setRabbitMintSecondsBetweenBatches(uint32 _secondsBetweenBatches) external;
    function setRabbitMaxPerWallet(uint8 _maxPerWallet) external;
    function setRabbitMintPriceInKarrots(uint72 _priceInKarrots) external;
    function setRabbitRerollPriceInKarrots(uint72 _priceInKarrots) external;
    function setRabbitMintKarrotFeePercentageToBurn(uint16 _karrotFeePercentageToBurn) external;
    function setRabbitMintKarrotFeePercentageToTreasury(uint16 _karrotFeePercentageToTreasury) external;
    function setRabbitMintTier1Threshold(uint16 _tier1Threshold) external;
    function setRabbitMintTier2Threshold(uint16 _tier2Threshold) external;
    function setRabbitTier1HP(uint8 _tier1HP) external;
    function setRabbitTier2HP(uint8 _tier2HP) external;
    function setRabbitTier3HP(uint8 _tier3HP) external;
    function setRabbitTier1HitRate(uint16 _tier1HitRate) external;
    function setRabbitTier2HitRate(uint16 _tier2HitRate) external;
    function setRabbitTier3HitRate(uint16 _tier3HitRate) external;
    function setRabbitAttackIsOpen(bool _isOpen) external;
    function setAttackCooldownSeconds(uint32 _attackCooldownSeconds) external;
    function setAttackHPDeductionAmount(uint8 _attackHPDeductionAmount) external;
    function setAttackHPDeductionThreshold(uint16 _attackHPDeductionThreshold) external;
    function setRandomizerMintCallbackGasLimit(uint24 _randomizerMintCallbackGasLimit) external;
    function setRandomizerAttackCallbackGasLimit(uint24 _randomizerAttackCallbackGasLimit) external;
}

interface IFullProtec {
    function getUserStakedAmount(address _user) external view returns (uint256);
    function getTotalStakedAmount() external view returns (uint256);
    function getIsUserAboveThresholdToAvoidClaimTax(address _user) external view returns (bool);
    function updateConfig() external;
    function openFullProtecDeposits() external;
    function setFullProtecLockDuration(uint32 _lockDuration) external;
    function setThresholdFullProtecKarrotBalance(uint224 _thresholdFullProtecKarrotBalance) external;
}

interface IStolenPool {
    function deposit(uint256 _amount) external;
    function attack(address _sender, uint256 _rabbitTier, uint256 _rabbitId) external;
    function updateConfig() external;
    function setStolenPoolOpenTimestamp() external;
    function setStolenPoolAttackIsOpen(bool _isOpen) external;
    function setAttackBurnPercentage(uint16 _attackBurnPercentage) external;
    function setStolenPoolEpochLength(uint32 _epochLength) external;
}

interface IAttackRewardCalculator {
    function calculateRewardPerAttackByTier(
        uint256 tier1Attacks,
        uint256 tier2Attacks,
        uint256 tier3Attacks,
        uint256 tier1Weight,
        uint256 tier2Weight,
        uint256 tier3Weight,
        uint256 totalKarrotsDepositedThisEpoch
    ) external view returns (uint256[] memory);
}

interface IDexInterfacer {
    function updateConfig() external;
    function depositEth() external payable;
    function depositErc20(uint256 _amount) external;
    function getPoolIsCreated() external view returns (bool);
    function getPoolIsFunded() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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