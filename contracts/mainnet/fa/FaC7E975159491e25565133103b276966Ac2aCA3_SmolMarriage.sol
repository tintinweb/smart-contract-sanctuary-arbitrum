// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "../interfaces/ISmolMarriage.sol";
import "../interfaces/ISmolRings.sol";
import "../interfaces/ISmolHappiness.sol";
import "../interfaces/ISmolRingStaking.sol";
import "../interfaces/ICreatureOwnerResolver.sol";
import "../interfaces/ICreatureOwnerResolverRegistry.sol";
import "../battlefly_flywheel/interfaces/ISmoloveActionsVault.sol";
import "../battlefly_flywheel/interfaces/IAtlasMine.sol";

/**
 * @title  SmolMarriage contract
 * @author Archethect
 * @notice This contract contains all functionalities for marrying Smols
 */
contract SmolMarriage is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, ISmolMarriage {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StringsUpgradeable for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");

    bool public marriageEnabled;
    uint256 public divorcePenaltyFee;
    uint256 public divorceCoolOff;
    uint256 public marriageStakingPriceInWei;

    address public treasury;
    ICreatureOwnerResolverRegistry public creatureOwnerResolverRegistry;
    IERC20Upgradeable public magic;
    ISmolRingStaking public staking;
    ISmolRings public smolRings;
    ISmolHappiness public smolHappiness;
    ISmoloveActionsVault public smoloveActionsVault;

    mapping(address => mapping(uint256 => Marriage)) public marriages;
    mapping(address => mapping(uint256 => RequestedMarriage)) public marriageRequest;
    mapping(address => mapping(uint256 => address)) public marriageRequestToAddress;
    mapping(address => mapping(uint256 => RequestedDivorce)) public divorceRequest;
    mapping(address => mapping(uint256 => RequestedDivorce)) public pendingDivorceRequest;
    mapping(address => mapping(uint256 => ICreatureOwnerResolverRegistry.Creature[])) public pendingMarriageRequests;
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256))))
        public pendingMarriageRequestsLUT;
    mapping(address => mapping(uint256 => RedeemableDivorce[])) public redeemableDivorces;
    mapping(address => mapping(uint256 => uint256)) public lastDivorced;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address creatureOwnerResolverRegistry_,
        address magic_,
        address operator_,
        address admin_,
        address treasury_,
        address staking_,
        address smolRings_,
        address smolHappiness_,
        address smoloveActionsVault_
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        require(creatureOwnerResolverRegistry_ != address(0), "SMOLMARRIAGE:ILLEGAL_ADDRESS");
        require(magic_ != address(0), "SMOLMARRIAGE:ILLEGAL_ADDRESS");
        require(operator_ != address(0), "SMOLMARRIAGE:ILLEGAL_ADDRESS");
        require(admin_ != address(0), "SMOLMARRIAGE:ILLEGAL_ADDRESS");
        require(treasury_ != address(0), "SMOLMARRIAGE:ILLEGAL_ADDRESS");
        require(staking_ != address(0), "SMOLMARRIAGE:ILLEGAL_ADDRESS");
        require(smolRings_ != address(0), "SMOLMARRIAGE:ILLEGAL_ADDRESS");
        require(smolHappiness_ != address(0), "SMOLMARRIAGE:ILLEGAL_ADDRESS");
        require(smoloveActionsVault_ != address(0), "SMOLMARRIAGE:ILLEGAL_ADDRESS");
        creatureOwnerResolverRegistry = ICreatureOwnerResolverRegistry(creatureOwnerResolverRegistry_);
        magic = IERC20Upgradeable(magic_);
        staking = ISmolRingStaking(staking_);
        smolRings = ISmolRings(smolRings_);
        smolHappiness = ISmolHappiness(smolHappiness_);
        smoloveActionsVault = ISmoloveActionsVault(smoloveActionsVault_);
        treasury = treasury_;
        divorcePenaltyFee = 20e18;
        marriageStakingPriceInWei = 80e18;
        divorceCoolOff = 2 weeks;
        magic.approve(address(this), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        _setupRole(ADMIN_ROLE, admin_);
        _setupRole(OPERATOR_ROLE, admin_);
        _setupRole(OPERATOR_ROLE, operator_);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "SMOLMARRIAGE:ACCESS_DENIED");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "SMOLMARRIAGE:ACCESS_DENIED");
        _;
    }

    /**
     * @notice Request marriage to another creature
     * @param creature1 creature object 1
     * @param creature2 creature object 2
     * @param ring1 id of ring 2
     * @param ring2 id of ring 2
     */
    function requestMarriage(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2,
        uint256 ring1,
        uint256 ring2
    ) public {
        require(
            isAllowedToMarry(creature1) && isAllowedToMarry(creature2),
            "SMOLMARRIAGE:ONLY_ALLOWED_TO_MARRY_WITH_ALLOWED_CREATURES"
        );
        require(!areCreaturesEqual(creature1, creature2), "SMOLMARRIAGE:CANNOT_MARRY_YOURSELF");
        require(ring1 != ring2, "SMOLMARRIAGE:CANNOT_USE_THE_SAME_RING");
        require(!isMarried(creature1) && !isMarried(creature2), "SMOLMARRIAGE:ONLY_ALLOWED_TO_MARRY_1_PARTNER");
        require(!hasMarriageRequest(creature1), "SMOLMARRIAGE:ONLY_1_MARRIAGE_REQUEST_ALLOWED");
        require(
            !marriageRequest[creature2.ownerResolver][creature2.tokenId].valid ||
                !areCreaturesEqual(marriageRequest[creature2.ownerResolver][creature2.tokenId].partner, creature1),
            "SMOLMARRIAGE:MARRIAGE_REQUEST_ALREADY_EXISTS_FOR_SMOL"
        );
        require(isOwner(msg.sender, creature1), "SMOLMARRIAGE:NOT_OWNER_OF_CREATURE");
        require(
            smolRings.getApproved(ring1) == address(staking) ||
                smolRings.isApprovedForAll(msg.sender, address(staking)),
            "SMOLMARRIAGE:NO_ALLOWANCE_FOR_STAKING_CONTRACT_SET"
        );
        require(smolRings.ownerOf(ring1) == msg.sender, "SMOLMARRIAGE:NOT_OWNER_OF_RING");
        require(
            magic.allowance(msg.sender, address(smoloveActionsVault)) >= marriageStakingPriceInWei,
            "SMOLMARRIAGE:NO_ALLOWANCE_FOR_MAGIC_STAKING_CONTRACT_SET"
        );
        require(magic.balanceOf(msg.sender) >= marriageStakingPriceInWei, "SMOLMARRIAGE:NOT_ENOUGH_MAGIC_IN_WALLET");
        marriageRequest[creature1.ownerResolver][creature1.tokenId] = RequestedMarriage(true, creature2, ring1, ring2);
        pendingMarriageRequests[creature2.ownerResolver][creature2.tokenId].push(creature1);
        pendingMarriageRequestsLUT[creature2.ownerResolver][creature2.tokenId][creature1.ownerResolver][
            creature1.tokenId
        ] = pendingMarriageRequests[creature2.ownerResolver][creature2.tokenId].length - 1;
        marriageRequestToAddress[creature1.ownerResolver][creature1.tokenId] = msg.sender;
        emit RequestMarriage(creature1, creature2, ring1, ring2);
    }

    /**
     * @notice Cancel an existing marriage request
     * @param creature1 creature object 1
     * @param creature2 creature object 2
     */
    function cancelMarriageRequest(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2
    ) public {
        require(isOwner(msg.sender, creature1) || isOwner(msg.sender, creature2), "SMOLMARRIAGE:NOT_OWNER_OF_CREATURE");
        require(
            (marriageRequest[creature1.ownerResolver][creature1.tokenId].valid &&
                areCreaturesEqual(marriageRequest[creature1.ownerResolver][creature1.tokenId].partner, creature2)) ||
                (marriageRequest[creature2.ownerResolver][creature2.tokenId].valid &&
                    areCreaturesEqual(marriageRequest[creature2.ownerResolver][creature2.tokenId].partner, creature1)),
            "SMOLMARRIAGE:NON_EXISTANT_MARRIAGE_REQUEST"
        );
        if (!hasMarriageRequest(creature1)) {
            //Switch smols around
            ICreatureOwnerResolverRegistry.Creature memory newCreature1 = creature2;
            creature2 = creature1;
            creature1 = newCreature1;
        }
        delete marriageRequest[creature1.ownerResolver][creature1.tokenId];
        uint256 rowToDelete = pendingMarriageRequestsLUT[creature2.ownerResolver][creature2.tokenId][
            creature1.ownerResolver
        ][creature1.tokenId];
        ICreatureOwnerResolverRegistry.Creature memory requestToMove = pendingMarriageRequests[creature2.ownerResolver][
            creature2.tokenId
        ][pendingMarriageRequests[creature2.ownerResolver][creature2.tokenId].length - 1];
        pendingMarriageRequests[creature2.ownerResolver][creature2.tokenId][rowToDelete] = requestToMove;
        pendingMarriageRequestsLUT[creature2.ownerResolver][creature2.tokenId][requestToMove.ownerResolver][
            requestToMove.tokenId
        ] = rowToDelete;
        pendingMarriageRequests[creature2.ownerResolver][creature2.tokenId].pop();
        delete pendingMarriageRequestsLUT[creature2.ownerResolver][creature2.tokenId][creature1.ownerResolver][
            creature1.tokenId
        ];
        emit CancelMarriageRequest(creature1, creature2);
    }

    /**
     * @notice Request a divorce
     * @param creature creature object of the creature that requests a divorce
     */
    function requestDivorce(ICreatureOwnerResolverRegistry.Creature memory creature) public {
        require(isOwner(msg.sender, creature), "SMOLMARRIAGE:NOT_OWNER_OF_CREATURE");
        require(isMarried(creature), "SMOLMARRIAGE:CREATURE_NOT_MARRIED");
        require(
            !hasDivorceRequest(creature) && !hasPendingDivorceRequest(creature),
            "SMOLMARRIAGE:DIVORCE_REQUEST_ALREADY_EXISTS"
        );
        ICreatureOwnerResolverRegistry.Creature memory partner = areCreaturesEqual(
            marriages[creature.ownerResolver][creature.tokenId].creature1,
            creature
        )
            ? marriages[creature.ownerResolver][creature.tokenId].creature2
            : marriages[creature.ownerResolver][creature.tokenId].creature1;
        divorceRequest[creature.ownerResolver][creature.tokenId] = RequestedDivorce(true, partner);
        pendingDivorceRequest[partner.ownerResolver][partner.tokenId] = RequestedDivorce(true, creature);
        emit DivorceRequest(creature, partner);
    }

    /**
     * @notice Cancel a divorce request
     * @param creature1 creature object 1
     * @param creature2 creature object 2
     */
    function cancelDivorceRequest(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2
    ) public {
        require(
            isOwner(msg.sender, creature1) || isOwner(msg.sender, creature2),
            "SMOLMARRIAGE:ONLY_CREATURE_OWNER_CAN_CANCEL_DIVORCE_REQUEST"
        );
        require(
            areCreaturesEqual(divorceRequest[creature1.ownerResolver][creature1.tokenId].partner, creature2) ||
                areCreaturesEqual(divorceRequest[creature2.ownerResolver][creature2.tokenId].partner, creature1),
            "SMOLMARRIAGE:NON_EXISTANT_DIVORCE_REQUEST"
        );
        if (!hasDivorceRequest(creature1)) {
            //Switch smols around
            ICreatureOwnerResolverRegistry.Creature memory newCreature1 = creature2;
            creature2 = creature1;
            creature1 = newCreature1;
        }
        delete divorceRequest[creature1.ownerResolver][creature1.tokenId];
        delete pendingDivorceRequest[creature2.ownerResolver][creature2.tokenId];
        emit CancelDivorceRequest(creature1, creature2);
    }

    /**
     * @notice Marry 2 creatures. Requires existing marriage request
     * @param creature1 creature object 1
     * @param creature2 creature object 2
     * @param ring1 id of ring 2
     * @param ring2 id of ring 2
     * @param partner Address of owner of creature 2
     */
    function marry(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2,
        uint256 ring1,
        uint256 ring2,
        address partner
    ) public nonReentrant {
        require(marriageEnabled, "SMOLMARRIAGE:MARRIAGE_DISABLED");
        require(!areCreaturesEqual(creature1, creature2), "SMOLMARRIAGE:CANNOT_MARRY_YOURSELF");
        require(ring1 != ring2, "SMOLMARRIAGE:CANNOT_USE_THE_SAME_RING");
        require(
            isAllowedToMarry(creature1) && isAllowedToMarry(creature2),
            "SMOLMARRIAGE:ONLY_ALLOWED_TO_MARRY_WITH_ALLOWED_CREATURES"
        );
        require(
            lastDivorced[creature1.ownerResolver][creature1.tokenId] + divorceCoolOff < block.timestamp,
            "SMOLMARRIAGE:RECENTLY_DIVORCED"
        );
        require(
            lastDivorced[creature2.ownerResolver][creature2.tokenId] + divorceCoolOff < block.timestamp,
            "SMOLMARRIAGE:RECENTLY_DIVORCED"
        );
        require(
            isOwner(msg.sender, creature1) &&
                isOwner(partner, creature2) &&
                smolRings.ownerOf(ring1) == msg.sender &&
                smolRings.ownerOf(ring2) == partner,
            "SMOLMARRIAGE:INCORRECT_OWNER_OF_CREATURE_AND_RING"
        );
        require(
            marriageRequestToAddress[creature2.ownerResolver][creature2.tokenId] == partner,
            "SMOLMARRIAGE:CURRENT_CREATURE_OWNER_IS_NOT_PROPOSER"
        );
        require(
            (smolRings.getApproved(ring1) == address(staking) ||
                smolRings.isApprovedForAll(msg.sender, address(staking))) &&
                (smolRings.getApproved(ring2) == address(staking) ||
                    smolRings.isApprovedForAll(partner, address(staking))),
            "SMOLMARRIAGE:NO_ALLOWANCE_FOR_RING_STAKING_CONTRACT_SET"
        );
        require(
            marriageRequest[creature2.ownerResolver][creature2.tokenId].ring == ring2 &&
                areCreaturesEqual(marriageRequest[creature2.ownerResolver][creature2.tokenId].partner, creature1) &&
                marriageRequest[creature2.ownerResolver][creature2.tokenId].partnerRing == ring1,
            "SMOLMARRIAGE:NON_EXISTANT_MARRIAGE_REQUEST"
        );
        require(
            (magic.allowance(msg.sender, address(smoloveActionsVault)) >= marriageStakingPriceInWei &&
                magic.allowance(partner, address(smoloveActionsVault)) >= marriageStakingPriceInWei),
            "SMOLMARRIAGE:NO_ALLOWANCE_FOR_MAGIC_STAKING_CONTRACT_SET"
        );
        require(
            (magic.balanceOf(msg.sender) >= marriageStakingPriceInWei &&
                magic.balanceOf(partner) >= marriageStakingPriceInWei),
            "SMOLMARRIAGE:NOT_ENOUGH_MAGIC_IN_WALLET"
        );
        smoloveActionsVault.stake(msg.sender, marriageStakingPriceInWei);
        smoloveActionsVault.stake(partner, marriageStakingPriceInWei);
        smolHappiness.setHappiness(creature1, smolHappiness.getMaxHappiness());
        smolHappiness.setHappiness(creature2, smolHappiness.getMaxHappiness());
        staking.stake(ring1, creature1, ring2, creature2, msg.sender, partner);
        Marriage memory marriage = Marriage(true, creature1, creature2, ring1, ring2, block.timestamp);
        marriages[creature1.ownerResolver][creature1.tokenId] = marriage;
        marriages[creature2.ownerResolver][creature2.tokenId] = marriage;
        delete marriageRequest[creature2.ownerResolver][creature2.tokenId];
        uint256 rowToDelete = pendingMarriageRequestsLUT[creature1.ownerResolver][creature1.tokenId][
            creature2.ownerResolver
        ][creature2.tokenId];
        ICreatureOwnerResolverRegistry.Creature memory requestToMove = pendingMarriageRequests[creature1.ownerResolver][
            creature1.tokenId
        ][pendingMarriageRequests[creature1.ownerResolver][creature1.tokenId].length - 1];
        pendingMarriageRequests[creature1.ownerResolver][creature1.tokenId][rowToDelete] = requestToMove;
        pendingMarriageRequestsLUT[creature1.ownerResolver][creature1.tokenId][requestToMove.ownerResolver][
            requestToMove.tokenId
        ] = rowToDelete;
        pendingMarriageRequests[creature1.ownerResolver][creature1.tokenId].pop();
        delete pendingMarriageRequestsLUT[creature1.ownerResolver][creature1.tokenId][creature2.ownerResolver][
            creature2.tokenId
        ];
        emit Married(creature1, creature2, ring1, ring2, block.timestamp);
    }

    /**
     * @notice Divorce 2 creatures. Requires existing divorce request for free divorce
     * @param creature1 creature object 1
     * @param creature2 creature object 2
     */
    function divorce(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2
    ) public nonReentrant {
        require(isOwner(msg.sender, creature1), "SMOLMARRIAGE:NOT_OWNER_OF_CREATURE");
        require(areMarried(creature1, creature2), "SMOLMARRIAGE:CREATURES_NOT_MARRIED");
        uint256 penaltyFee;
        if (!divorceRequest[creature2.ownerResolver][creature2.tokenId].valid) {
            //Pay divorce fee
            penaltyFee =
                (divorcePenaltyFee *
                    smolRings.ringRarity(marriages[creature1.ownerResolver][creature1.tokenId].ring1) *
                    50) /
                100000;
            magic.transferFrom(msg.sender, treasury, penaltyFee);
            magic.transferFrom(msg.sender, address(this), penaltyFee);
        } else {
            delete divorceRequest[creature2.ownerResolver][creature2.tokenId];
            delete pendingDivorceRequest[creature1.ownerResolver][creature1.tokenId];
        }
        uint256 redeemRing = marriages[creature1.ownerResolver][creature1.tokenId].ring1;
        uint256 pendingRing = marriages[creature1.ownerResolver][creature1.tokenId].ring2;
        if (areCreaturesEqual(marriages[creature1.ownerResolver][creature1.tokenId].creature2, creature1)) {
            redeemRing = marriages[creature1.ownerResolver][creature1.tokenId].ring2;
            pendingRing = marriages[creature1.ownerResolver][creature1.tokenId].ring1;
        }
        redeemableDivorces[creature2.ownerResolver][creature2.tokenId].push(
            RedeemableDivorce(true, pendingRing, penaltyFee)
        );
        staking.unstake(redeemRing, pendingRing, creature1, creature2, msg.sender);
        smolHappiness.setHappiness(creature1, 0);
        smolHappiness.setHappiness(creature2, 0);
        delete marriages[creature1.ownerResolver][creature1.tokenId];
        delete marriages[creature2.ownerResolver][creature2.tokenId];
        lastDivorced[creature1.ownerResolver][creature1.tokenId] = block.timestamp;
        lastDivorced[creature2.ownerResolver][creature2.tokenId] = block.timestamp;
        emit Divorced(creature1, creature2);
    }

    /**
     * @notice Redeem the rings of the partner of the divorce initiator
     * @param creature creature object of creature to redeem the rings from
     */
    function redeemDivorcedRings(ICreatureOwnerResolverRegistry.Creature memory creature) public nonReentrant {
        require(isOwner(msg.sender, creature), "SMOLMARRIAGE:NOT_OWNER_OF_CREATURE");
        require(
            redeemableDivorces[creature.ownerResolver][creature.tokenId].length > 0,
            "SMOLMARRIAGE:NO_PENDING_RING_AFTER_DIVORCE"
        );
        uint256 penaltyFee = 0;
        for (uint256 i = 0; i < redeemableDivorces[creature.ownerResolver][creature.tokenId].length; i++) {
            if (redeemableDivorces[creature.ownerResolver][creature.tokenId][i].valid) {
                if (redeemableDivorces[creature.ownerResolver][creature.tokenId][i].penaltyFee > 0) {
                    penaltyFee += redeemableDivorces[creature.ownerResolver][creature.tokenId][i].penaltyFee;
                }
                staking.withdrawRing(
                    redeemableDivorces[creature.ownerResolver][creature.tokenId][i].ring,
                    creature,
                    msg.sender
                );
                emit RedeemedDivorcedRing(
                    creature,
                    redeemableDivorces[creature.ownerResolver][creature.tokenId][i].ring,
                    redeemableDivorces[creature.ownerResolver][creature.tokenId][i].penaltyFee
                );
            }
        }
        delete redeemableDivorces[creature.ownerResolver][creature.tokenId];
        if (penaltyFee > 0) {
            magic.transferFrom(address(this), msg.sender, penaltyFee);
        }
    }

    function setDivorcePenaltyFee(uint256 divorcePenaltyFee_) external onlyOperator {
        divorcePenaltyFee = divorcePenaltyFee_;
    }

    function setDivorceCoolOff(uint256 divorceCoolOff_) external onlyOperator {
        divorceCoolOff = divorceCoolOff_;
    }

    function areMarried(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2
    ) public view returns (bool) {
        return (marriages[creature1.ownerResolver][creature1.tokenId].valid &&
            (
                areCreaturesEqual(
                    marriages[creature1.ownerResolver][creature1.tokenId].creature1,
                    marriages[creature2.ownerResolver][creature2.tokenId].creature1
                )
            ));
    }

    function isMarried(ICreatureOwnerResolverRegistry.Creature memory creature) public view returns (bool) {
        return marriages[creature.ownerResolver][creature.tokenId].valid;
    }

    function getMarriage(ICreatureOwnerResolverRegistry.Creature memory creature)
        public
        view
        returns (Marriage memory)
    {
        return marriages[creature.ownerResolver][creature.tokenId];
    }

    function hasMarriageRequest(ICreatureOwnerResolverRegistry.Creature memory creature) public view returns (bool) {
        return marriageRequest[creature.ownerResolver][creature.tokenId].valid;
    }

    function getPendingMarriageRequests(ICreatureOwnerResolverRegistry.Creature memory creature)
        public
        view
        returns (ICreatureOwnerResolverRegistry.Creature[] memory)
    {
        return pendingMarriageRequests[creature.ownerResolver][creature.tokenId];
    }

    function getRedeemableDivorces(ICreatureOwnerResolverRegistry.Creature memory creature)
        public
        view
        returns (RedeemableDivorce[] memory)
    {
        return redeemableDivorces[creature.ownerResolver][creature.tokenId];
    }

    function hasPendingMarriageRequests(ICreatureOwnerResolverRegistry.Creature memory creature)
        public
        view
        returns (bool)
    {
        return (pendingMarriageRequests[creature.ownerResolver][creature.tokenId].length > 0);
    }

    function hasDivorceRequest(ICreatureOwnerResolverRegistry.Creature memory creature) public view returns (bool) {
        return divorceRequest[creature.ownerResolver][creature.tokenId].valid;
    }

    function hasPendingDivorceRequest(ICreatureOwnerResolverRegistry.Creature memory creature)
        public
        view
        returns (bool)
    {
        return pendingDivorceRequest[creature.ownerResolver][creature.tokenId].valid;
    }

    function getPendingDivorceRequest(ICreatureOwnerResolverRegistry.Creature memory creature)
        public
        view
        returns (ICreatureOwnerResolverRegistry.Creature memory)
    {
        return pendingDivorceRequest[creature.ownerResolver][creature.tokenId].partner;
    }

    function getMarriageProposerAddressForCreature(ICreatureOwnerResolverRegistry.Creature memory creature)
        public
        view
        returns (address)
    {
        return marriageRequestToAddress[creature.ownerResolver][creature.tokenId];
    }

    function setMarriageEnabled(bool status) public onlyOperator {
        marriageEnabled = status;
    }

    function isAllowedToMarry(ICreatureOwnerResolverRegistry.Creature memory creature) public view returns (bool) {
        if (creatureOwnerResolverRegistry.isAllowed(creature.ownerResolver)) {
            return true;
        }
        return false;
    }

    function areCreaturesEqual(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2
    ) internal pure returns (bool) {
        if (creature1.ownerResolver == creature2.ownerResolver && creature1.tokenId == creature2.tokenId) {
            return true;
        }
        return false;
    }

    function isOwner(address account, ICreatureOwnerResolverRegistry.Creature memory creature)
        internal
        view
        returns (bool)
    {
        if (ICreatureOwnerResolver(creature.ownerResolver).isOwner(account, creature.tokenId)) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ICreatureOwnerResolverRegistry.sol";

/**
 * @title  ISmolMarriage interface
 * @author Archethect
 * @notice This interface contains all functionalities for marrying Smols.
 */
interface ISmolMarriage {
    event Married(
        ICreatureOwnerResolverRegistry.Creature creature1,
        ICreatureOwnerResolverRegistry.Creature creature2,
        uint256 ring1,
        uint256 ring2,
        uint256 timestamp
    );
    event Divorced(
        ICreatureOwnerResolverRegistry.Creature creature1,
        ICreatureOwnerResolverRegistry.Creature creature2
    );
    event CancelDivorceRequest(
        ICreatureOwnerResolverRegistry.Creature creature1,
        ICreatureOwnerResolverRegistry.Creature creature2
    );
    event DivorceRequest(
        ICreatureOwnerResolverRegistry.Creature creature1,
        ICreatureOwnerResolverRegistry.Creature creature2
    );
    event CancelMarriageRequest(
        ICreatureOwnerResolverRegistry.Creature creature1,
        ICreatureOwnerResolverRegistry.Creature creature2
    );
    event RequestMarriage(
        ICreatureOwnerResolverRegistry.Creature creature1,
        ICreatureOwnerResolverRegistry.Creature creature2,
        uint256 ring1,
        uint256 ring2
    );
    event RedeemedDivorcedRing(ICreatureOwnerResolverRegistry.Creature creature, uint256 ring, uint256 penaltyFee);

    struct Marriage {
        bool valid;
        ICreatureOwnerResolverRegistry.Creature creature1;
        ICreatureOwnerResolverRegistry.Creature creature2;
        uint256 ring1;
        uint256 ring2;
        uint256 marriageTimestamp;
    }

    struct RequestedMarriage {
        bool valid;
        ICreatureOwnerResolverRegistry.Creature partner;
        uint256 ring;
        uint256 partnerRing;
    }

    struct RequestedDivorce {
        bool valid;
        ICreatureOwnerResolverRegistry.Creature partner;
    }

    struct RedeemableDivorce {
        bool valid;
        uint256 ring;
        uint256 penaltyFee;
    }

    function requestMarriage(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2,
        uint256 ring1,
        uint256 ring2
    ) external;

    function cancelMarriageRequest(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2
    ) external;

    function requestDivorce(ICreatureOwnerResolverRegistry.Creature memory creature) external;

    function cancelDivorceRequest(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2
    ) external;

    function marry(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2,
        uint256 ring1,
        uint256 ring2,
        address partner
    ) external;

    function divorce(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2
    ) external;

    function redeemDivorcedRings(ICreatureOwnerResolverRegistry.Creature memory creature) external;

    function setDivorcePenaltyFee(uint256 divorcePenaltyFee_) external;

    function setDivorceCoolOff(uint256 divorceCoolOff_) external;

    function areMarried(
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2
    ) external view returns (bool);

    function isMarried(ICreatureOwnerResolverRegistry.Creature memory creature) external view returns (bool);

    function getMarriage(ICreatureOwnerResolverRegistry.Creature memory creature)
        external
        view
        returns (Marriage memory);

    function hasMarriageRequest(ICreatureOwnerResolverRegistry.Creature memory creature) external view returns (bool);

    function getPendingMarriageRequests(ICreatureOwnerResolverRegistry.Creature memory creature)
        external
        view
        returns (ICreatureOwnerResolverRegistry.Creature[] memory);

    function getRedeemableDivorces(ICreatureOwnerResolverRegistry.Creature memory creature)
        external
        view
        returns (RedeemableDivorce[] memory);

    function hasPendingMarriageRequests(ICreatureOwnerResolverRegistry.Creature memory creature)
        external
        view
        returns (bool);

    function hasDivorceRequest(ICreatureOwnerResolverRegistry.Creature memory creature) external view returns (bool);

    function hasPendingDivorceRequest(ICreatureOwnerResolverRegistry.Creature memory creature)
        external
        view
        returns (bool);

    function getPendingDivorceRequest(ICreatureOwnerResolverRegistry.Creature memory creature)
        external
        view
        returns (ICreatureOwnerResolverRegistry.Creature memory);

    function getMarriageProposerAddressForCreature(ICreatureOwnerResolverRegistry.Creature memory creature)
        external
        view
        returns (address);

    function setMarriageEnabled(bool status) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title  ISmolRings interface
 * @author Archethect
 * @notice This interface contains all functionalities for Smol Rings.
 */
interface ISmolRings is IERC721Enumerable {
    struct Ring {
        uint256 ringType;
    }

    function mintRing(uint256 amount, bool stake) external payable;

    function mintRingSmolSwol(
        uint256[] calldata smolIds,
        uint256[] calldata swolIds,
        bool stake
    ) external payable;

    function mintRingSmol(uint256[] calldata smolIds, bool stake) external payable;

    function mintRingSwol(uint256[] calldata swolIds, bool stake) external payable;

    function mintRingWhitelist(
        uint256 epoch,
        uint256 index,
        uint256 amount,
        uint256[] calldata rings,
        bytes32[] calldata merkleProof,
        bool stake
    ) external payable;

    function mintRingTeam(
        uint256 ringType,
        uint256 amount,
        address account
    ) external;

    function setBaseRewardFactor(uint256 baseRewardFactor_) external;

    function ringRarity(uint256 ring) external view returns (uint256);

    function getRingProps(uint256 ringId) external view returns (Ring memory);

    function getTotalRingsPerType(uint256 ringType) external view returns (uint256);

    function setRegularMintEnabled(bool status) external;

    function setWhitelistMintEnabled(bool status) external;

    function setSmolMintEnabled(bool status) external;

    function setWhitelistAmount(uint128 whitelistAmount_) external;

    function switchToRingType(uint256 ringId, uint256 ringType) external;

    function withdrawProceeds() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
import "./ICreatureOwnerResolverRegistry.sol";

/**
 * @title  ISmolHappiness interface
 * @author Archethect
 * @notice This interface contains all functionalities for Smol happiness.
 */
interface ISmolHappiness {
    struct Happiness {
        bool valid;
        uint256 score;
        uint256 lastModified;
    }

    function getCurrentHappiness(ICreatureOwnerResolverRegistry.Creature memory creature)
        external
        view
        returns (uint256);

    function getStartHappiness(ICreatureOwnerResolverRegistry.Creature memory creature) external view returns (uint256);

    function setHappiness(ICreatureOwnerResolverRegistry.Creature memory creature, uint256 happiness) external;

    function increaseHappiness(ICreatureOwnerResolverRegistry.Creature memory creature, uint256 happiness) external;

    function decreaseHappiness(ICreatureOwnerResolverRegistry.Creature memory creature, uint256 happiness) external;

    function enableHappiness() external;

    function disableHappiness() external;

    function setDecayFactor(uint256 decay) external;

    function getHappinessDecayPerSec() external view returns (uint256);

    function getMaxHappiness() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ICreatureOwnerResolverRegistry.sol";

/**
 * @title  ISmolRingStaking interface
 * @author Archethect
 * @notice This interface contains all functionalities for staking Smol Rings.
 */
interface ISmolRingStaking {
    event Staked(ICreatureOwnerResolverRegistry.Creature creature, uint256[] rewards);
    event Unstaked(ICreatureOwnerResolverRegistry.Creature creature, uint256[] rewards);
    event Rewarded(ICreatureOwnerResolverRegistry.Creature creature, uint256[] rewards);
    event RewardTokenAdded(uint256 reward, address tokenDistributor, uint256 rewardsDuration);
    event RewardAdded(address tokenDistributor, uint256 reward);
    event RewardsDurationUpdated(address tokenDistributor, uint256 rewardsDuration);

    struct RewardTokenState {
        bool valid;
        uint256 rewardRatePerSecondInBPS;
        uint256 rewardPerTokenStored;
        uint256 lastRewardsRateUpdate;
        uint256 rewardsDuration;
        uint256 periodFinish;
        address tokenDistributor;
    }

    struct RewardCalculation {
        uint256 rewardFactor1;
        uint256 rewardFactor2;
        uint256 ring1Type;
        uint256 ring2Type;
    }

    function stake(
        uint256 ring1,
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        uint256 ring2,
        ICreatureOwnerResolverRegistry.Creature memory creature2,
        address ownerCreature1,
        address ownerCreature2
    ) external;

    function unstake(
        uint256 ring1,
        uint256 ring2,
        ICreatureOwnerResolverRegistry.Creature memory creature1,
        ICreatureOwnerResolverRegistry.Creature memory creature2,
        address ownerCreature1
    ) external;

    function withdrawRing(
        uint256 ring,
        ICreatureOwnerResolverRegistry.Creature memory creature,
        address ownerCreature
    ) external;

    function accrueForNewScore(ICreatureOwnerResolverRegistry.Creature memory creature) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @title  ICreatureOwnerResolver interface
 * @author Archethect
 * @notice This interface contains all functionalities for verifying Creature ownership
 */
interface ICreatureOwnerResolver {
    function isOwner(address account, uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @title  ICreatureOwnerResolverRegistry interface
 * @author Archethect
 * @notice This interface contains all functionalities for managing Creature owner resolvers
 */
interface ICreatureOwnerResolverRegistry {
    struct Creature {
        address ownerResolver;
        uint256 tokenId;
    }

    function isAllowed(address creatureOwnerResolver) external view returns (bool);

    function addCreatureOwnerResolver(address creatureOwnerResolver) external;

    function removeCreatureOwnerResolver(address creatureOwnerResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IBattleflyAtlasStakerV02.sol";
import "./IAtlasMine.sol";
import "../../interfaces/ICreatureOwnerResolverRegistry.sol";

interface ISmoloveActionsVault {
    // ============================================ EVENT ==============================================
    event Stake(address indexed user, uint256 stakeId, uint256 amount, uint256 inclusion);
    event Withdraw(address indexed user, uint256 stakeId, uint256 amount);
    event RequestWithdrawal(uint256 stakeId);
    event SetAdminAccess(address indexed user, bool access);
    event ClaimAndRestake(uint256 amount);

    struct UserStake {
        uint256 id;
        uint256 amount;
        uint256 inclusion;
        uint256 withdrawAt;
        address owner;
    }

    struct AtlasStake {
        uint256 id;
        uint256 amount;
        uint256 withdrawableAt;
        uint256 startDay;
    }

    function stake(address user, uint256 amount) external;

    function getStakeAmount(address user) external view returns (uint256);

    function getTotalClaimableAmount() external view returns (uint256);

    function getUserStakes(address user) external view returns (UserStake[] memory);

    function withdrawAll() external;

    function withdraw(uint256[] memory stakeIds) external;

    function requestWithdrawal(uint256[] memory stakeIds) external;

    function claimAllAndRestake() external;

    function canRequestWithdrawal(uint256 stakeId) external view returns (bool requestable);

    function canWithdraw(uint256 stakeId) external view returns (bool withdrawable);

    function initialUnlock(uint256 stakeId) external view returns (uint256 epoch);

    function retentionUnlock(uint256 stakeId) external view returns (uint256 epoch);

    function getCurrentEpoch() external view returns (uint256 epoch);

    function getNumberOfActiveStakes() external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IAtlasMine {
    enum Lock {
        twoWeeks,
        oneMonth,
        threeMonths,
        sixMonths,
        twelveMonths
    }
    struct UserInfo {
        uint256 originalDepositAmount;
        uint256 depositAmount;
        uint256 lpAmount;
        uint256 lockedUntil;
        uint256 vestingLastUpdate;
        int256 rewardDebt;
        Lock lock;
    }

    function treasure() external view returns (address);

    function legion() external view returns (address);

    function unlockAll() external view returns (bool);

    function boosts(address user) external view returns (uint256);

    function userInfo(address user, uint256 depositId)
        external
        view
        returns (
            uint256 originalDepositAmount,
            uint256 depositAmount,
            uint256 lpAmount,
            uint256 lockedUntil,
            uint256 vestingLastUpdate,
            int256 rewardDebt,
            Lock lock
        );

    function getLockBoost(Lock _lock) external pure returns (uint256 boost, uint256 timelock);

    function getVestingTime(Lock _lock) external pure returns (uint256 vestingTime);

    function stakeTreasure(uint256 _tokenId, uint256 _amount) external;

    function unstakeTreasure(uint256 _tokenId, uint256 _amount) external;

    function stakeLegion(uint256 _tokenId) external;

    function unstakeLegion(uint256 _tokenId) external;

    function withdrawPosition(uint256 _depositId, uint256 _amount) external returns (bool);

    function withdrawAll() external;

    function pendingRewardsAll(address _user) external view returns (uint256 pending);

    function deposit(uint256 _amount, Lock _lock) external;

    function harvestAll() external;

    function harvestPosition(uint256 _depositId) external;

    function currentId(address _user) external view returns (uint256);

    function pendingRewardsPosition(address _user, uint256 _depositId) external view returns (uint256);

    function getAllUserDepositIds(address) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IAtlasMine.sol";

interface IBattleflyAtlasStakerV02 {
    struct Vault {
        uint16 fee;
        uint16 claimRate;
        bool enabled;
    }

    struct VaultStake {
        uint64 lockAt;
        uint64 unlockAt;
        uint64 retentionUnlock;
        uint256 amount;
        uint256 paidEmission;
        address vault;
        IAtlasMine.Lock lock;
    }

    function MAGIC() external returns (IERC20Upgradeable);

    function deposit(uint256, IAtlasMine.Lock) external returns (uint256);

    function withdraw(uint256) external returns (uint256);

    function claim(uint256) external returns (uint256);

    function requestWithdrawal(uint256) external returns (uint64);

    function currentDepositId() external view returns (uint256);

    function getAllowedLocks() external view returns (IAtlasMine.Lock[] memory);

    function getVaultStake(uint256) external view returns (VaultStake memory);

    function getClaimableEmission(uint256) external view returns (uint256, uint256);

    function canWithdraw(uint256 _depositId) external view returns (bool withdrawable);

    function canRequestWithdrawal(uint256 _depositId) external view returns (bool requestable);

    function currentEpoch() external view returns (uint64 epoch);

    function getLockPeriod(IAtlasMine.Lock) external view returns (uint64 epoch);

    function setPause(bool _paused) external;

    function depositIdsOfVault(address vault) external view returns (uint256[] memory depositIds);

    function activeAtlasPositionSize() external view returns (uint256);

    // ========== Events ==========
    event AddedSuperAdmin(address who);
    event RemovedSuperAdmin(address who);

    event AddedVault(address indexed vault, uint16 fee, uint16 claimRate);
    event RemovedVault(address indexed vault);

    event StakedTreasure(address staker, uint256 tokenId, uint256 amount);
    event UnstakedTreasure(address staker, uint256 tokenId, uint256 amount);

    event StakedLegion(address staker, uint256 tokenId);
    event UnstakedLegion(address staker, uint256 tokenId);

    event SetTreasury(address treasury);
    event SetBattleflyBot(address bot);

    event NewDeposit(address indexed vault, uint256 amount, uint256 unlockedAt, uint256 indexed depositId);
    event WithdrawPosition(address indexed vault, uint256 amount, uint256 indexed depositId);
    event ClaimEmission(address indexed vault, uint256 amount, uint256 indexed depositId);
    event RequestWithdrawal(address indexed vault, uint64 withdrawalEpoch, uint256 indexed depositId);

    event DepositedAllToMine(uint256 amount);

    event SetPause(bool paused);
}