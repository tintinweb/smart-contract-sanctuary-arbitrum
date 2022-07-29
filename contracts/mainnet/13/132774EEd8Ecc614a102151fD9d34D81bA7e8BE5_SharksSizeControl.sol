// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "./Sharks.sol";
import "./GangsMultiplierManagement.sol";

contract SharksSizeControl {
    Sharks public sharks;
    GangsMultiplierManagement public gangsMultiplierManagement;

    constructor(address sharksAddress_, address gangsMultiplierManagementAddress_) {
        sharks = Sharks(sharksAddress_);
        gangsMultiplierManagement = GangsMultiplierManagement(gangsMultiplierManagementAddress_);
    }

    function sharkSize(uint tokenId_) public view returns (uint256) {
        uint256 size = sharks.xp(tokenId_) * sharks.rarity(tokenId_);
        uint256 gangsMultiplier = gangsMultiplierManagement.getMultiplierBySharkId(tokenId_);

        if (gangsMultiplier > 0) {
            size = size * gangsMultiplier / 100;
        }

        return size;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "./SharksLocking.sol";

contract SharksTransferControl {
    SharksLocking public sharksLocking;

    constructor(address sharksLockingAddress_) {
        sharksLocking = SharksLocking(sharksLockingAddress_);
    }

    function sharkCanBeTransferred(uint tokenId_) public view returns (bool) {
        return sharksLocking.sharkCanBeTransferred(tokenId_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./Sharks.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SharksLocking is AccessControl {
    Sharks public sharks;

    uint256 public constant WEEK = 7 days;
    uint256 public xpPerWeek;
    uint256 public maxLockWeeksCount;
    mapping(uint256 => uint256) public lockedAt;
    mapping(uint256 => uint256) public lockedUntil;

    bytes32 public constant LOCK_MANAGER = keccak256("LOCK_MANAGER");

    event Locked(uint256 indexed tokenId, uint256 until, uint256 xpIncrease);
    event Relocked(uint256 indexed tokenId, uint256 until, uint256 xpIncrease);
    event Unlocked(uint256 indexed tokenId, uint256 lockedForWeeksCount);
    event XpPerWeekChanged(uint256 xpWeekWeek);
    event MaxLockWeeksCountChanged(uint256 maxLockWeeksCount);
    event LockUpdated(uint256 indexed tokenId, uint256 at, uint256 until, address lockManager);

    modifier onlySharkOwner(uint256 tokenId_) {
        require(sharks.ownerOf(tokenId_) == msg.sender, "SharksLocking: You do not own this shark");
        _;
    }

    constructor(address sharksAddress_) {
        sharks = Sharks(sharksAddress_);
        xpPerWeek = 168; // 1XP/h
        maxLockWeeksCount = 52;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function lockMany(uint256[] calldata tokenIds_, uint256 weeksCount_) public {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            lock(tokenIds_[i], weeksCount_);
        }
    }

    function relockMany(uint256[] calldata tokenIds_, uint256 weeksCount_) public {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            relock(tokenIds_[i], weeksCount_);
        }
    }

    function unlockMany(uint256[] calldata tokenIds_) public {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            unlock(tokenIds_[i]);
        }
    }


    function lock(uint256 tokenId_, uint256 weeksCount_) public onlySharkOwner(tokenId_) {
        require(lockedUntil[tokenId_] == 0, "SharksLocking: already locked");
        require(weeksCount_ > 0, "SharksLocking: must lock for at least 1 week");
        require(weeksCount_ <= maxLockWeeksCount, "SharksLocking: cannot lock for more than maxLockWeeksCount");

        uint256 _xpIncrease = calculateXpIncrease(weeksCount_);
        uint256 _lockedUntilTimestamp = block.timestamp + weeksToSeconds(weeksCount_);

        lockedAt[tokenId_] = block.timestamp;
        lockedUntil[tokenId_] = _lockedUntilTimestamp;

        sharks.increaseXp(
            tokenId_,
            _xpIncrease
        );

        emit Locked(
            tokenId_,
            _lockedUntilTimestamp,
            _xpIncrease
        );
    }

    function relock(uint256 tokenId_, uint256 weeksCount_) public onlySharkOwner(tokenId_) {
        require(lockedUntil[tokenId_] > 0, "SharksLocking: not locked yet");
        require(weeksCount_ > 0, "SharksLocking: must relock for at least 1 week");
        require(weeksCount_ <= maxLockWeeksCount, "SharksLocking: cannot relock for more than maxLockWeeksCount");

        uint256 _weeksRemainingCount;
        uint256 _baseTimestamp;
        if (lockedUntil[tokenId_] > block.timestamp) {
            _weeksRemainingCount = ((lockedUntil[tokenId_] - block.timestamp) / WEEK) + 1;
            _baseTimestamp = lockedUntil[tokenId_];
        } else {
            _weeksRemainingCount = 0;
            _baseTimestamp = block.timestamp;
        }

        uint256 _actualMaxLockWeeksCount = maxLockWeeksCount - _weeksRemainingCount;

        if (weeksCount_ > _actualMaxLockWeeksCount) {
            revert(string(abi.encodePacked(
                "SharksLocking: can only relock for ",
                Strings.toString(_actualMaxLockWeeksCount),
                " weeks max "
            )));
        }

        uint256 _xpIncrease = calculateXpIncrease(weeksCount_);

        uint256 _lockedUntilTimestamp = _baseTimestamp + weeksToSeconds(weeksCount_);

        lockedUntil[tokenId_] = _lockedUntilTimestamp;

        sharks.increaseXp(
            tokenId_,
            _xpIncrease
        );

        emit Relocked(
            tokenId_,
            _lockedUntilTimestamp,
            _xpIncrease
        );
    }

    function unlock(uint256 tokenId_) public onlySharkOwner(tokenId_) {
        require(lockedUntil[tokenId_] > 0, "SharksLocking: not locked");
        require(block.timestamp > lockedUntil[tokenId_], "SharksLocking: cannot unlock yet");

        uint256 _lockedForWeeksCount = (lockedUntil[tokenId_] - lockedAt[tokenId_]) / WEEK;

        lockedAt[tokenId_] = 0;
        lockedUntil[tokenId_] = 0;

        emit Unlocked(
            tokenId_,
            _lockedForWeeksCount
        );
    }

    function updateLock(uint256 tokenId_, uint256 lockedAt_, uint256 lockedUntil_) public onlyRole(LOCK_MANAGER) {
        lockedAt[tokenId_] = lockedAt_;
        lockedUntil[tokenId_] = lockedUntil_;

        emit LockUpdated(
            tokenId_,
            lockedAt_,
            lockedUntil_,
            msg.sender
        );
    }

    function setXpPerWeek(uint256 xpPerWeek_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        xpPerWeek = xpPerWeek_;
        emit XpPerWeekChanged(xpPerWeek);
    }

    function setMaxLockWeeksCount(uint256 maxLockWeeksCount_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxLockWeeksCount = maxLockWeeksCount_;
        emit MaxLockWeeksCountChanged(maxLockWeeksCount);
    }

    function sharkCanBeTransferred(uint tokenId_) public view returns (bool) {
        if (lockedUntil[tokenId_] == 0) {
            return true;
        } else {
            return false;
        }
    }

    function calculateXpIncrease(uint256 weeksCount_) public view returns (uint256) {
        return weeksCount_ * xpPerWeek;
    }

    function weeksToSeconds(uint256 weeksCount_) public pure returns (uint256) {
        return weeksCount_ * WEEK;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract SharksAccessControl is AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REVEALER_ROLE = keccak256("REVEALER_ROLE");
    bytes32 public constant XP_MANAGER_ROLE = keccak256("XP_MANAGER_ROLE");

    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, _msgSender()), "SharksAccessControl: no OWNER_ROLE");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "SharksAccessControl: no MINTER_ROLE");
        _;
    }

    modifier onlyRevealer() {
        require(isRevealer(_msgSender()), "SharksAccessControl: no REVEALER_ROLE");
        _;
    }

    modifier onlyXpManager() {
        require(isXpManager(_msgSender()), "SharksAccessControl: no XP_MANAGER_ROLE");
        _;
    }


    constructor() {
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
        _setRoleAdmin(REVEALER_ROLE, OWNER_ROLE);
        _setRoleAdmin(XP_MANAGER_ROLE, OWNER_ROLE);

        _setupRole(OWNER_ROLE, _msgSender());
    }

    function grantOwner(address _owner) external onlyOwner {
        grantRole(OWNER_ROLE, _owner);
    }

    function grantXpManager(address _xpManager) external onlyOwner {
        grantRole(XP_MANAGER_ROLE, _xpManager);
    }

    function grantMinter(address _minter) external onlyOwner {
        grantRole(MINTER_ROLE, _minter);
    }
    function grantRevealer(address _revealer) external onlyOwner {
        grantRole(REVEALER_ROLE, _revealer);
    }

    function revokeOwner(address _owner) external onlyOwner {
        revokeRole(OWNER_ROLE, _owner);
    }

    function revokeXpManager(address _xpManager) external onlyOwner {
        revokeRole(XP_MANAGER_ROLE, _xpManager);
    }

    function revokeMinter(address _minter) external onlyOwner {
        revokeRole(MINTER_ROLE, _minter);
    }

    function revokeRevealer(address _revealer) external onlyOwner {
        revokeRole(REVEALER_ROLE, _revealer);
    }

    function isOwner(address _owner) public view returns (bool) {
        return hasRole(OWNER_ROLE, _owner);
    }

    function isXpManager(address _xpManager) public view returns (bool) {
        return hasRole(XP_MANAGER_ROLE, _xpManager);
    }

    function isRevealer(address _revealer) public view returns (bool) {
        return hasRole(REVEALER_ROLE, _revealer);
    }

    function isMinter(address _minter) public view returns (bool) {
        return hasRole(MINTER_ROLE, _minter);
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./SharksAccessControl.sol";
import "./SharksTransferControl.sol";
import "./SharksSizeControl.sol";

contract Sharks is ERC721, ERC721Enumerable, SharksAccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdTracker;

    string public baseURI;

    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable INITIAL_XP;

    uint256 public totalSharksSize;

    SharksTransferControl public sharksTransferControl;
    SharksSizeControl public sharksSizeControl;

    mapping(uint256 => uint256) public xp;
    mapping(uint256 => uint256) public rarity;

    event Minted(address indexed to, uint256 indexed tokenId);
    event Revealed(uint256 indexed tokenId, uint256 rarity);
    event XpIncreased(uint256 indexed tokenId, uint256 xpIncrease, uint256 totalXp);

    event BaseURIChanged(string baseURI);
    event SharksSizeControlChanged(address sharksSizeControl);
    event SharksTransferControlChanged(address sharksTransferControl);

    constructor(uint256 maxSupply_) ERC721("Smol Sharks", "SMOLSHARKS") {
        MAX_SUPPLY = maxSupply_;
        INITIAL_XP = 1;
    }

    // internal
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 tokenId_)
        internal
        override(ERC721, ERC721Enumerable)
    {
        require(sharkCanBeTransferred(tokenId_) == true, "SharksTransferControl: transfer not allowed");

        super._beforeTokenTransfer(from_, to_, tokenId_);
    }

    // onlyOwner

    function setSharksSizeControl(address sharksSizeControl_)
        public
        onlyOwner
    {
        sharksSizeControl = SharksSizeControl(sharksSizeControl_);
        emit SharksSizeControlChanged(sharksSizeControl_);
    }

    function setSharksTransferControl(address sharksTransferControl_)
        public
        onlyOwner
    {
        sharksTransferControl = SharksTransferControl(sharksTransferControl_);
        emit SharksTransferControlChanged(sharksTransferControl_);
    }

    function setBaseURI(string memory baseURI_)
        public
        onlyOwner
    {
        baseURI = baseURI_;
        emit BaseURIChanged(baseURI);
    }

    // onlyMinter
    function mint(
        address to_,
        uint256 mintsCount_
    )
        public
        onlyMinter
    {
        uint256 _actualMintsCount = Math.min(mintsCount_, MAX_SUPPLY - tokenIdTracker.current());

        require(_actualMintsCount > 0, "MAX_SUPPLY reached");

        for (uint256 i = 0; i < _actualMintsCount; i++) {
            tokenIdTracker.increment();

            uint256 _tokenId = tokenIdTracker.current();

            require(_tokenId <= MAX_SUPPLY, "MAX_SUPPLY reached"); // sanity check, should not ever trigger

            _safeMint(to_, _tokenId);
            emit Minted(to_, _tokenId);
        }
    }

    // onlyRevealer

    function reveal(
        uint256 tokenId_,
        uint256 rarity_
    )
        public
        onlyRevealer
    {
        _requireMinted(tokenId_);
        require(rarity[tokenId_] == 0, "already revealed");

        rarity[tokenId_] = rarity_;
        emit Revealed(tokenId_, rarity_);
        _increaseXp(tokenId_, INITIAL_XP);
    }



    // onlyXpManager

    function increaseXp(uint tokenId_, uint xp_)
        public
        onlyXpManager
    {
        _requireMinted(tokenId_);
        _increaseXp(tokenId_, xp_);
    }

    function _increaseXp(uint tokenId_, uint xp_)
        internal
    {
        totalSharksSize += xp_;
        xp[tokenId_] += xp_;
        emit XpIncreased(tokenId_, xp_, xp[tokenId_]);
    }


    // Views

    function sharkCanBeTransferred(uint256 tokenId_)
        public
        view
        returns (bool)
    {
        if (address(sharksTransferControl) != address(0)) {
            return (sharksTransferControl.sharkCanBeTransferred(tokenId_) == true);
        } else {
            return true;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        require(bytes(_baseURI()).length > 0, "baseURI not set");

        string memory tokenFilename = rarity[tokenId] > 0 ? Strings.toString(tokenId) : "0";

        return string(abi.encodePacked(_baseURI(), tokenFilename, ".json"));
    }

    function size(uint256 tokenId_)
        public
        view
        returns (uint256)
    {
        _requireMinted(tokenId_);

        if(address(sharksSizeControl) != address(0)) {
            return sharksSizeControl.sharkSize(tokenId_);
        } else {
            return 0;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Gangs.sol";

contract GangsMultiplierManagement is AccessControl {
    mapping (uint256 => uint256) multiplierByLeaderRarity; // leaderRarity => multiplier

    Gangs public gangs;

    event MultiplierChanged(uint256 leaderRarity, uint256 multiplier);

    constructor(
        address gangsAddress_
    )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        gangs = Gangs(gangsAddress_);

        multiplierByLeaderRarity[10] = 300;
        multiplierByLeaderRarity[25] = 250;
        multiplierByLeaderRarity[100] = 200;
        multiplierByLeaderRarity[250] = 150;
        multiplierByLeaderRarity[1500] = 125;
        multiplierByLeaderRarity[10000] = 110;
        multiplierByLeaderRarity[25000] = 105;
    }

    function getMultiplierBySharkId(uint256 sharkId_)
        public
        view
        returns (uint256)
    {
        uint256 _gangId = gangs.getGangIdBySharkId(sharkId_);
        if (_gangId > 0 && gangs.isActive(_gangId))
        {
            return multiplierByLeaderRarity[gangs.getLeaderRarity(_gangId)];
        } else {
            return 100;
        }
    }

    function setMultiplierByLeaderRarity(uint256 leaderRarity_, uint256 multiplier_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        multiplierByLeaderRarity[leaderRarity_] = multiplier_;

        emit MultiplierChanged(leaderRarity_, multiplier_);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Sharks.sol";

contract Gangs is ERC721, ERC721Enumerable, AccessControl {
    bytes32 public constant GANG_MANAGER_ROLE = keccak256("GANG_MANAGER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter private tokenIdTracker;
    string public imageBaseURI;

    mapping (uint256 => Membership) public memberships; // sharkId => Membership
    mapping (uint256 => Dossier) public dossiers; // sharkId => Dossier

    Sharks public immutable sharks;
    uint256 public immutable MAX_SUPPLY;

    struct Dossier {
        string name;
        uint256 leaderId;
        uint256[] membersIds;
        uint256 leaderRarity;
        uint256 membersRarity;
        uint256 minSize;
        uint256 maxSize;
        uint256 joiningFee;
    }

    struct Membership {
        uint256 gangId;
        uint256 expiresAt;
    }

    event ImageBaseURIChanged(string imageBaseURI);
    event Minted(address indexed to, uint256 indexed tokenId);
    event MemberAdded(uint256 indexed gangId, uint256 indexed sharkId, uint256 expiresAt);
    event MemberRemoved(uint256 indexed gangId, uint256 indexed sharkId);
    event LeaderAdded(uint256 indexed gangId, uint256 indexed sharkId, uint256 expiresAt);
    event LeaderRemoved(uint256 indexed gangId, uint256 indexed sharkId);
    event MembershipChanged(uint256 indexed gangId, uint256 indexed sharkId, uint256 expiresAt);
    event NameChanged(uint256 indexed gangId, string name);
    event MinSizeChanged(uint256 indexed gangId, uint256 minSize);
    event MaxSizeChanged(uint256 indexed gangId, uint256 maxSize);
    event JoiningFeeChanged(uint256 indexed gangId, uint256 joiningFee);

    modifier onlyMinted(uint256 tokenId) {
        _requireMinted(tokenId);
        _;
    }

    constructor(
        address sharksAddress_,
        uint256 maxSupply_
    ) ERC721("Smol Sharks Gangs", "GANGS")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GANG_MANAGER_ROLE, _msgSender());

        MAX_SUPPLY = maxSupply_;

        sharks = Sharks(sharksAddress_);
    }

    // internal
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function setImageBaseURI(string memory imageBaseURI_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        imageBaseURI = imageBaseURI_;
        emit ImageBaseURIChanged(imageBaseURI);
    }

    function mint(
        address to_,
        uint256 mintsCount_,
        uint256 leaderRarity_,
        uint256 membersRarity_,
        uint256 minSize_,
        uint256 maxSize_
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 _actualMintsCount = Math.min(mintsCount_, MAX_SUPPLY - tokenIdTracker.current());

        require(_actualMintsCount > 0, "MAX_SUPPLY reached");

        for (uint256 i = 0; i < _actualMintsCount; i++) {
            tokenIdTracker.increment();

            uint256 _tokenId = tokenIdTracker.current();

            require(_tokenId <= MAX_SUPPLY, "MAX_SUPPLY reached"); // sanity check, should not ever trigger

            _safeMint(to_, _tokenId);

            Dossier storage dossier = dossiers[_tokenId];
            dossier.leaderRarity = leaderRarity_;
            dossier.membersRarity = membersRarity_;
            dossier.minSize = minSize_;
            dossier.maxSize = maxSize_;

            emit Minted(to_, _tokenId);
        }
    }

    // only GANG_MANAGER_ROLE
    function addMembers(
        uint256 gangId_,
        uint256[] calldata addedSharksIds_,
        uint256 expiresAt_
    )
        public
        onlyRole(GANG_MANAGER_ROLE)
        onlyMinted(gangId_)
    {
        Dossier storage dossier = dossiers[gangId_];

        require(
            addedSharksIds_.length + dossier.membersIds.length <= dossier.maxSize,
            "Gangs: more members than maxSize allows"
        );

        for (uint256 i = 0; i < addedSharksIds_.length; i++) {
            uint256 _sharkId = addedSharksIds_[i];
            require(memberships[_sharkId].gangId == 0, "Gangs: shark already in a gang");
            require(dossier.membersRarity == sharks.rarity(_sharkId), "Gangs: members rarity does not match");

            changeMembership(_sharkId, gangId_, expiresAt_);
            dossier.membersIds.push(_sharkId);
            emit MemberAdded(gangId_, _sharkId, expiresAt_);
        }

    }

    function removeMembers(
        uint256 gangId_,
        uint256[] calldata removedSharksIds_
    )
        public
        onlyRole(GANG_MANAGER_ROLE)
        onlyMinted(gangId_)
    {
        Dossier storage dossier = dossiers[gangId_];

        for (uint256 i = 0; i < removedSharksIds_.length; i++) {
            uint256 _removedSharkId = removedSharksIds_[i];
            require(memberships[_removedSharkId].gangId > 0, "Gangs: shark not in a gang");
            require(memberships[_removedSharkId].expiresAt <= block.timestamp, "Gangs: membership has not expired yet");

            changeMembership(_removedSharkId, 0, 0);
            emit MemberRemoved(gangId_, _removedSharkId);

            for (uint256 k = 0; k < dossier.membersIds.length; k++) {
                if (_removedSharkId == dossier.membersIds[k]) {
                    dossier.membersIds[k] = dossier.membersIds[dossier.membersIds.length-1];
                    dossier.membersIds.pop();
                    break;
                }
            }
        }

        require(dossier.membersIds.length <= dossier.maxSize, "Gangs: maxSize not met");
    }

    function addLeader(
        uint256 gangId_,
        uint256 newLeaderId_,
        uint256 expiresAt_
    )
        public
        onlyRole(GANG_MANAGER_ROLE)
        onlyMinted(gangId_)
    {
        require(memberships[newLeaderId_].gangId == 0, "Gangs: leader already in a gang");

        Dossier storage dossier = dossiers[gangId_];

        require(dossier.leaderId == 0, "Gangs: Gang already has a leader");
        require(dossier.leaderRarity == sharks.rarity(newLeaderId_), "Gangs: invalid leader rarity");

        dossier.leaderId = newLeaderId_;

        changeMembership(newLeaderId_, gangId_, expiresAt_);

        emit LeaderAdded(gangId_, newLeaderId_, expiresAt_);
    }

    function removeLeader(
        uint256 gangId_
    )
        public
        onlyRole(GANG_MANAGER_ROLE)
        onlyMinted(gangId_)
    {
        Dossier storage dossier = dossiers[gangId_];

        uint256 _removedLeaderId = dossier.leaderId;

        require(_removedLeaderId > 0, "Gangs: gang has no leader");
        require(memberships[_removedLeaderId].expiresAt <= block.timestamp, "Gangs: leader membership has not expired yet");

        dossier.leaderId = 0;

        changeMembership(_removedLeaderId, 0, 0);

        emit LeaderRemoved(gangId_, _removedLeaderId);
    }

    function changeMembership(
        uint256 sharkId_,
        uint256 gangId_,
        uint256 expiresAt_
    )
        public
        onlyRole(GANG_MANAGER_ROLE)
    {
        memberships[sharkId_].gangId = gangId_;
        memberships[sharkId_].expiresAt = expiresAt_;

        emit MembershipChanged(gangId_, sharkId_, expiresAt_);
    }

    function changeName(
        uint256 gangId_,
        string memory name_
    )
        public
        onlyRole(GANG_MANAGER_ROLE)
        onlyMinted(gangId_)
    {
        dossiers[gangId_].name = name_;

        emit NameChanged(gangId_, name_);
    }

    function changeMinSize(
        uint256 gangId_,
        uint256 minSize_
    )
        public
        onlyRole(GANG_MANAGER_ROLE)
        onlyMinted(gangId_)
    {
        dossiers[gangId_].minSize = minSize_;

        emit MinSizeChanged(gangId_, minSize_);
    }

    function changeMaxSize(
        uint256 gangId_,
        uint256 maxSize_
    )
        public
        onlyRole(GANG_MANAGER_ROLE)
        onlyMinted(gangId_)
    {
        dossiers[gangId_].maxSize = maxSize_;

        emit MaxSizeChanged(gangId_, maxSize_);
    }

    function changeJoiningFee(
        uint256 gangId_,
        uint256 joiningFee_
    )
        public
        onlyRole(GANG_MANAGER_ROLE)
        onlyMinted(gangId_)
    {
        dossiers[gangId_].joiningFee = joiningFee_;

        emit JoiningFeeChanged(gangId_, joiningFee_);
    }

    // Views

    function getLeaderId(uint256 gangId_) public view returns (uint256) {
        return dossiers[gangId_].leaderId;
    }

    function getMembersIds(uint256 gangId_) public view returns (uint256[] memory) {
        return dossiers[gangId_].membersIds;
    }

    function getMembersCount(uint256 gangId_) public view returns (uint256) {
        return dossiers[gangId_].membersIds.length;
    }

    function getLeaderRarity(uint256 gangId_) public view returns (uint256) {
        return dossiers[gangId_].leaderRarity;
    }

    function getMembersRarity(uint256 gangId_) public view returns (uint256) {
        return dossiers[gangId_].membersRarity;
    }

    function getName(uint256 gangId_) public view returns (string memory) {
        return dossiers[gangId_].name;
    }

    function getMinSize(uint256 gangId_) public view returns (uint256) {
        return dossiers[gangId_].minSize;
    }

    function getMaxSize(uint256 gangId_) public view returns (uint256) {
        return dossiers[gangId_].maxSize;
    }

    function getJoiningFee(uint256 gangId_) public view returns (uint256) {
        return dossiers[gangId_].joiningFee;
    }

    function getGangIdBySharkId(uint256 shark_) public view returns (uint256) {
        return memberships[shark_].gangId;
    }

    function getExpiresAtBySharkId(uint256 shark_) public view returns (uint256) {
        return memberships[shark_].expiresAt;
    }

    function isActive(uint256 gangId_) public view returns (bool) {
        return getLeaderId(gangId_) != 0 && getMembersCount(gangId_) >= getMinSize(gangId_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function generateDataURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        bytes memory attributes_1 = abi.encodePacked(
            '{"trait_type":"Leader","value":"', rarityToClass(getLeaderRarity(tokenId)) ,'"},',
            '{"trait_type":"Members","value":"', rarityToClass(getMembersRarity(tokenId)) ,'"},',
            '{"trait_type":"Min Size","value":', Strings.toString(getMinSize(tokenId)) ,'},'
        );
        bytes memory attributes_2 = abi.encodePacked(
            '{"trait_type":"Max Size","value":', Strings.toString(getMaxSize(tokenId)) ,'},',
            '{"trait_type":"Joining Fee","value":"', Strings.toString(getJoiningFee(tokenId)) ,'"},',
            '{"trait_type":"Active","value":', isActive(tokenId) ? 'true' : 'false' ,'}'
        );

        string memory customName = getName(tokenId);

        string memory name = bytes(customName).length != 0 ? customName : string(abi.encodePacked("Gang #", Strings.toString(tokenId)));

        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name":"', name, '",',
                '"image":"', abi.encodePacked(imageBaseURI), rarityToClass(getLeaderRarity(tokenId)), '.png",',
                '"attributes":[',
                    attributes_1,
                    attributes_2,
                ']',
            '}'
        );

        return Base64.encode(dataURI);

    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                generateDataURI(tokenId)
            )
        );

    }

    function rarityToClass(uint256 rarity) public pure returns (string memory) {
        if (rarity == 1)
            return 'Common';
        if (rarity == 10)
            return 'Robber';
        if (rarity == 25)
            return 'Astronaut';
        if (rarity == 100)
            return 'Pirate';
        if (rarity == 250)
            return 'Lady';
        if (rarity == 1500)
            return 'Mummy';
        if (rarity == 10000)
            return 'Alien';
        if (rarity == 25000)
            return 'Ghost';

        return '';
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 tokenId_)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}