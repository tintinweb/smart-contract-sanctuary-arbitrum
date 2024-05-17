// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ValidatorIdentityV2 } from "./v2/ValidatorIdentityV2.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IDelegation } from "./delegation/IDelegation.sol";
import { IIdentityRouter } from "./IIdentityRouter.sol";

contract IdentityRouter is Ownable, IIdentityRouter {
    mapping(string identityName => mapping(uint32 => RouterConfig)) internal routers;

    ValidatorIdentityV2 public validatorIdentity;
    IDelegation public delegation;

    constructor(address _owner, address _validatorIdentityV2) Ownable(_owner) {
        validatorIdentity = ValidatorIdentityV2(_validatorIdentityV2);
    }

    /**
     * @inheritdoc IIdentityRouter
     */
    function hookIdentities(string calldata _parentIdentiyName, string[] calldata _children) external override {
        if (validatorIdentity.ownerOf(_parentIdentiyName) != msg.sender) revert NotIdentityOwner();

        ValidatorIdentityV2.Identifier memory identity;
        string memory childIdentityName;

        for (uint256 i = 0; i < _children.length; ++i) {
            childIdentityName = _children[i];
            identity = validatorIdentity.getIdentityData(0, childIdentityName);

            routers[_parentIdentiyName][identity.validatorUUID] = RouterConfig(childIdentityName, false);

            emit HookedIdentity(_parentIdentiyName, identity.validatorUUID, childIdentityName);
        }
    }

    /**
     * @inheritdoc IIdentityRouter
     */
    function toggleUseChildWalletReceiver(string calldata _parentIdentiyName, uint32 _validatorId) external override {
        if (validatorIdentity.ownerOf(_parentIdentiyName) != msg.sender) revert NotIdentityOwner();

        RouterConfig storage routerConfig = routers[_parentIdentiyName][_validatorId];
        bool newStatus = !routerConfig.useChildWallet;

        routerConfig.useChildWallet = newStatus;

        emit UseChildWalletUpdated(_parentIdentiyName, _validatorId, routerConfig.childName, newStatus);
    }

    /**
     * @inheritdoc IIdentityRouter
     */
    function getWalletReceiver(string calldata _parentIdentiyName, uint32 _validatorId)
        external
        view
        override
        returns (address walletReceiver_, bool isDelegated_)
    {
        if (address(delegation) != address(0) && delegation.isDelegated(_parentIdentiyName, _validatorId)) {
            return (address(delegation), true);
        }

        RouterConfig memory routerConfig = routers[_parentIdentiyName][_validatorId];
        bool isRouted = keccak256(abi.encode(routerConfig.childName)) != keccak256(abi.encode(""));

        string memory idName = isRouted && routerConfig.useChildWallet ? routerConfig.childName : _parentIdentiyName;
        ValidatorIdentityV2.Identifier memory identityData = validatorIdentity.getIdentityData(0, idName);

        walletReceiver_ =
            (isRouted || identityData.validatorUUID == _validatorId) ? identityData.walletReceiver : address(0);

        return (walletReceiver_, false);
    }

    function updateValidatorIdentity(address _validatorIdentity) external onlyOwner {
        validatorIdentity = ValidatorIdentityV2(_validatorIdentity);
        emit ValidatorIdentityUpdated(_validatorIdentity);
    }

    function updateDelegation(address _delegation) external onlyOwner {
        delegation = IDelegation(_delegation);
        emit DelegationUpdated(_delegation);
    }

    /**
     * @inheritdoc IIdentityRouter
     */
    function getRouterConfig(string calldata _parentIdentityName, uint32 _validatorId)
        external
        view
        returns (RouterConfig memory)
    {
        return routers[_parentIdentityName][_validatorId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IdentityERC721 } from "../../IdentityERC721.sol";
import { IValidatorIdentityV2 } from "./IValidatorIdentityV2.sol";
import { IValidatorIdentity } from "../IValidatorIdentity.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title ValidatorIdentityV2
 * @notice Validators require an identity to link the wallet where they wish to receive rewards (if applicable).
 * Unlike the Ticker, ValidatorIdentity is permanently owned by its creator and contains no tax.
 *
 * For more details, refer to IValidatorIdentity.sol.
 */
contract ValidatorIdentityV2 is IValidatorIdentityV2, IdentityERC721 {
    uint256 public constant MAX_BPS = 10_000;

    IValidatorIdentity public immutable oldIdentity;
    mapping(uint256 => Identifier) internal identities;

    uint32 public resetCounterTimestamp;
    uint32 public boughtToday;
    uint32 public maxIdentityPerDayAtInitialPrice;
    uint32 public priceIncreaseThreshold;
    uint32 public priceDecayBPS;
    uint256 public currentPrice;

    constructor(address _owner, address _treasury, address _nameFilter, uint256 _cost, address _oldIdentity)
        IdentityERC721(_owner, _treasury, _nameFilter, _cost, "ValidatorIdentity", "EthI")
    {
        oldIdentity = IValidatorIdentity(_oldIdentity);
        resetCounterTimestamp = uint32(block.timestamp + 1 days);
        currentPrice = cost;
        maxIdentityPerDayAtInitialPrice = 25;
        priceIncreaseThreshold = 10;
        priceDecayBPS = 2500;
    }

    function isSoulboundIdentity(string calldata _name, uint32 _validatorId) external view override returns (bool) {
        uint256 nftId = identityIds[_name];
        return identities[nftId].validatorUUID == _validatorId;
    }

    function migrateFromOldIdentity(string calldata _name, uint32 _validatorId) external override {
        if (address(oldIdentity) == address(0)) revert NoMigrationPossible();

        // Happens if the user created an new identity on the old version while the name was already taken in this
        // version
        if (identityIds[_name] != 0) revert NotBackwardCompatible();

        IValidatorIdentity.DelegatedIdentity memory oldDelegation = oldIdentity.getDelegationData(0, _name);
        IValidatorIdentity.Identifier memory oldIdentityData = oldIdentity.getIdentityData(0, _name);

        bool isDelegatedAndOwner = oldDelegation.isEnabled && oldDelegation.owner == msg.sender;
        bool isOwner = IdentityERC721(address(oldIdentity)).ownerOf(_name) == msg.sender;

        if (!isDelegatedAndOwner && !isOwner) revert NotIdentityOwner();

        _createIdentity(_name, oldIdentityData.tokenReceiver, _validatorId, 0);
    }

    function create(string calldata _name, address _receiverWallet, uint32 _validatorId) external payable override {
        if (cost == 0 && msg.value != 0) revert NoNeedToPay();

        _executeCreate(_name, _receiverWallet, _validatorId);
    }

    function _executeCreate(string calldata _name, address _receiverWallet, uint32 _validatorId) internal {
        if (_isNameExistingFromOldVersion(_name)) revert NameAlreadyTaken();

        uint256 costAtDuringTx = _updateCost();

        if (msg.value < costAtDuringTx) revert MsgValueTooLow();

        _sendNative(treasury, costAtDuringTx, true);
        _sendNative(msg.sender, msg.value - costAtDuringTx, true);

        _createIdentity(_name, _receiverWallet, _validatorId, costAtDuringTx);
    }

    function _createIdentity(string calldata _name, address _receiverWallet, uint32 _validatorId, uint256 _cost)
        internal
    {
        if (_receiverWallet == address(0)) _receiverWallet = msg.sender;

        uint256 id = _create(_name, 0);
        identities[id] = Identifier({ name: _name, validatorUUID: _validatorId, walletReceiver: _receiverWallet });

        emit NewGraffitiIdentityCreated(id, _validatorId, _name, _cost);
        emit WalletReceiverUpdated(id, _name, _receiverWallet);
    }

    function _updateCost() internal returns (uint256 userCost_) {
        (resetCounterTimestamp, boughtToday, currentPrice, userCost_) = _getCostDetails();
        return userCost_;
    }

    function getCost() external view returns (uint256 userCost_) {
        (,,, userCost_) = _getCostDetails();
        return userCost_;
    }

    function _getCostDetails()
        internal
        view
        returns (
            uint32 resetCounterTimestampReturn_,
            uint32 boughtTodayReturn_,
            uint256 currentCostReturn_,
            uint256 userCost_
        )
    {
        uint32 maxPerDayCached = maxIdentityPerDayAtInitialPrice;
        resetCounterTimestampReturn_ = resetCounterTimestamp;
        boughtTodayReturn_ = boughtToday;
        currentCostReturn_ = currentPrice;

        if (block.timestamp >= resetCounterTimestampReturn_) {
            uint256 totalDayPassed = (block.timestamp - resetCounterTimestampReturn_) / 1 days + 1;
            resetCounterTimestampReturn_ += uint32(1 days * totalDayPassed);
            boughtTodayReturn_ = 0;

            for (uint256 i = 0; i < totalDayPassed; i++) {
                currentCostReturn_ =
                    Math.max(cost, currentCostReturn_ - Math.mulDiv(currentCostReturn_, priceDecayBPS, MAX_BPS));

                if (currentCostReturn_ <= cost) break;
            }
        }

        bool boughtExceedsMaxPerDay = boughtTodayReturn_ > maxPerDayCached;

        if (boughtExceedsMaxPerDay && (boughtTodayReturn_ - maxPerDayCached) % priceIncreaseThreshold == 0) {
            currentCostReturn_ += cost / 2;
        }

        userCost_ = !boughtExceedsMaxPerDay ? cost : currentCostReturn_;
        boughtTodayReturn_++;

        return (resetCounterTimestampReturn_, boughtTodayReturn_, currentCostReturn_, userCost_);
    }

    function updateReceiverAddress(uint256 _nftId, string calldata _name, address _receiver) external override {
        if (_nftId == 0) {
            _nftId = identityIds[_name];
        }

        if (ownerOf(_nftId) != msg.sender) revert NotIdentityOwner();

        Identifier storage identity = identities[_nftId];
        identity.walletReceiver = _receiver;

        emit WalletReceiverUpdated(_nftId, identity.name, _receiver);
    }

    function updateMaxIdentityPerDayAtInitialPrice(uint32 _maxIdentityPerDayAtInitialPrice) external onlyOwner {
        maxIdentityPerDayAtInitialPrice = _maxIdentityPerDayAtInitialPrice;
        emit MaxIdentityPerDayAtInitialPriceUpdated(_maxIdentityPerDayAtInitialPrice);
    }

    function updatePriceIncreaseThreshold(uint32 _priceIncreaseThreshold) external onlyOwner {
        priceIncreaseThreshold = _priceIncreaseThreshold;
        emit PriceIncreaseThresholdUpdated(_priceIncreaseThreshold);
    }

    function updatePriceDecayBPS(uint32 _priceDecayBPS) external onlyOwner {
        if (_priceDecayBPS > MAX_BPS) revert InvalidBPS();
        priceDecayBPS = _priceDecayBPS;
        emit PriceDecayBPSUpdated(_priceDecayBPS);
    }

    function transferFrom(address, address, uint256) public pure override {
        revert("Non-Transferrable");
    }

    function getIdentityData(uint256 _nftId, string calldata _name)
        external
        view
        override
        returns (Identifier memory)
    {
        if (_nftId == 0) {
            _nftId = identityIds[_name];
        }

        return identities[_nftId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        Identifier memory identity = identities[tokenId];

        string memory data = string(
            abi.encodePacked(
                '{"name":"Graffiti Identity @',
                identity.name,
                '","description":"Required for your Heroglyph Graffiti","image":"',
                "ipfs://QmdTq1vZ6cZ6mcJBfkG49FocwqTPFQ8duq6j2tL2rpzEWF",
                '"}'
            )
        );

        return string(abi.encodePacked("data:application/json;utf8,", data));
    }

    function _isNameAvailable(string calldata _name) internal view override returns (bool success_, int32 failedAt_) {
        if (_isNameExistingFromOldVersion(_name)) return (false, -1);

        return super._isNameAvailable(_name);
    }

    function _isNameExistingFromOldVersion(string calldata _name) internal view returns (bool) {
        return address(oldIdentity) != address(0) && IdentityERC721(address(oldIdentity)).getIdentityNFTId(_name) != 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
pragma solidity >=0.8.0;

interface IDelegation {
    function isDelegated(string calldata _idName, uint32 _validatorId) external view returns (bool);

    function snapshot(string calldata _idName, uint32 _validatorId, address _tickerContract) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IIdentityRouter {
    error NotIdentityOwner();

    event HookedIdentity(string indexed parentIdentityName, uint32 indexed childValidatorIndex, string childName);
    event ValidatorIdentityUpdated(address validatorIdentity);
    event DelegationUpdated(address delegation);
    event UseChildWalletUpdated(
        string indexed parentIdentityName, uint32 indexed childValidatorIndex, string childName, bool useChildWallet
    );

    struct RouterConfig {
        string childName;
        bool useChildWallet;
    }

    /**
     * hookIdentities Hooks multiple identities to a parent identity.
     * @param _parentIdentiyName Parent identity name
     * @param _children Child identity names
     * @dev The reward will be sent to the Parent identity's wallet receiver.
     */
    function hookIdentities(string calldata _parentIdentiyName, string[] calldata _children) external;

    /**
     * toggleUseChildWalletReceiver Toggles the use of the child wallet receiver.
     * @param _parentIdentiyName Parent identity name
     * @param _validatorId Validator ID
     */
    function toggleUseChildWalletReceiver(string calldata _parentIdentiyName, uint32 _validatorId) external;

    /**
     * getWalletReceiver Returns the wallet receiver address for a given parent identity and validator id.
     * @param _parentIdentiyName Parent identity name
     * @param _validatorId Validator id
     * @return walletReceiver_ Wallet receiver address. Returns empty address if not routed or soulbound.
     * @return isDelegated_ True if the identity is delegated.
     */
    function getWalletReceiver(string calldata _parentIdentiyName, uint32 _validatorId)
        external
        view
        returns (address walletReceiver_, bool isDelegated_);

    /**
     * getRouterConfig Returns the router configuration for a given parent identity and validator id.
     * @param _parentIdentityName Parent identity name
     * @param _validatorId Validator id
     * @return RouterConfig_ Router configuration tuple(string childName, boolean useChildWallet)
     */
    function getRouterConfig(string calldata _parentIdentityName, uint32 _validatorId)
        external
        view
        returns (RouterConfig memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IIdentityERC721 } from "./IIdentityERC721.sol";
import { SendNativeHelper } from "./../SendNativeHelper.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { NameFilter } from "./NameFilter.sol";

/**
 * @title IdentityERC721
 * @notice The base of Ticker & ValidatorIdentity. It handles name verification, id tracking and the payment
 */
abstract contract IdentityERC721 is IIdentityERC721, ERC721, SendNativeHelper, Ownable {
    address public immutable treasury;
    uint256 public cost;
    NameFilter public nameFilter;

    mapping(string => uint256) internal identityIds;
    uint256 private nextIdToMint;

    /**
     * @dev Important, you need to have an array of your IdentityData. In the constructor, you must push your first
     * element as "DEAD". nftId starts at 1
     * @dev when creating an Identity, call _create to validate and mint
     */
    constructor(
        address _owner,
        address _treasury,
        address _nameFilter,
        uint256 _cost,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Ownable(_owner) {
        if (_treasury == address(0)) revert TreasuryNotSet();

        nameFilter = NameFilter(_nameFilter);
        nextIdToMint = 1;
        treasury = _treasury;
        cost = _cost;
    }

    function _create(string memory _name, uint256 _expectingCost) internal returns (uint256 mintedId_) {
        if (_expectingCost != 0 && msg.value != _expectingCost) revert ValueIsNotEqualsToCost();
        if (identityIds[_name] != 0) revert NameAlreadyTaken();

        (bool isNameHealthy, uint256 characterIndex) = nameFilter.isNameValidWithIndexError(_name);
        if (!isNameHealthy) revert InvalidCharacter(characterIndex);

        mintedId_ = nextIdToMint;
        nextIdToMint++;

        identityIds[_name] = mintedId_;

        _safeMint(msg.sender, mintedId_);
        emit NewIdentityCreated(mintedId_, _name, msg.sender);

        if (_expectingCost == 0) return mintedId_;

        _sendNative(treasury, msg.value, true);

        return mintedId_;
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        if (tokenId == 0) revert InvalidIdZero();
        return super._update(to, tokenId, auth);
    }

    function isNameAvailable(string calldata _name) external view returns (bool success_, int32 failedAt_) {
        return _isNameAvailable(_name);
    }

    function _isNameAvailable(string calldata _name) internal view virtual returns (bool success_, int32 failedAt_) {
        if (identityIds[_name] != 0) return (false, -1);

        uint256 characterIndex;
        (success_, characterIndex) = nameFilter.isNameValidWithIndexError(_name);

        return (success_, int32(uint32(characterIndex)));
    }

    function getIdentityNFTId(string calldata _name) external view override returns (uint256) {
        return identityIds[_name];
    }

    function ownerOf(string calldata _name) external view returns (address) {
        return ownerOf(identityIds[_name]);
    }

    function updateNameFilter(address _newFilter) external onlyOwner {
        nameFilter = NameFilter(_newFilter);
        emit NameFilterUpdated(_newFilter);
    }

    function updateCost(uint256 _cost) external onlyOwner {
        cost = _cost;
        emit CostUpdated(_cost);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IValidatorIdentityV2 {
    error NoMigrationPossible();
    error NotBackwardCompatible();
    error MsgValueTooLow();
    error NoNeedToPay();
    error InvalidBPS();

    /**
     * @notice Identifier
     * @param name Name of the Wallet
     * @param walletReceiver Address that will be receiving Ticker's reward if any
     */
    struct Identifier {
        string name;
        uint32 validatorUUID;
        address walletReceiver;
    }

    event WalletReceiverUpdated(uint256 indexed walletId, string indexed identityName, address newWallet);
    event NewGraffitiIdentityCreated(
        uint256 indexed walletId, uint32 indexed validatorId, string identityName, uint256 cost
    );
    event MaxIdentityPerDayAtInitialPriceUpdated(uint32 maxIdentityPerDayAtInitialPrice);
    event PriceIncreaseThresholdUpdated(uint32 priceIncreaseThreshold);
    event PriceDecayBPSUpdated(uint32 priceDecayBPS);

    /**
     * isSoulboundIdentity Try to soulbound an identity
     * @param _name Name of the identity
     * @param _validatorId Validator ID of the validator
     * @return bool Returns true if the identity is soulbound & validatorId is the same
     */
    function isSoulboundIdentity(string calldata _name, uint32 _validatorId) external view returns (bool);

    /**
     * migrateFromOldIdentity Migrate from old identity to new identity
     * @param _name Name of the identity
     * @param _validatorId Validator ID of the validator
     */
    function migrateFromOldIdentity(string calldata _name, uint32 _validatorId) external;

    /**
     * create Create an Identity
     * @param _name name of the Identity
     * @param _validatorId Unique Id of the validator
     */
    function create(string calldata _name, address _receiverWallet, uint32 _validatorId) external payable;

    /**
     * updateReceiverAddress Update Receiver Wallet of an Identity
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @param _receiver address that will be receiving any rewards
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     * @dev Only the owner of the Identity can call this function
     */
    function updateReceiverAddress(uint256 _nftId, string memory _name, address _receiver) external;

    /**
     * getIdentityDataWithName Get Identity information with name
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @return identity_ tuple(name,tokenReceiver)
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     */
    function getIdentityData(uint256 _nftId, string calldata _name) external view returns (Identifier memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IValidatorIdentity {
    error EarlyBirdOnly();
    error InvalidProof();

    /**
     * @notice Identifier
     * @param name Name of the Wallet
     * @param tokenReceiver Address that will be receiving Ticker's reward if any
     */
    struct Identifier {
        string name;
        address tokenReceiver;
    }

    /**
     * @notice DelegatedIdentity
     * @param isEnabled If the Delegation is enabled
     * @param owner The original owner of the Identity
     * @param originalTokenReceiver The original Identifier::tokenReceiver
     * @param delegatee The one buying the delegation
     * @param durationInMonths The duration in months of the delegation
     * @param endDelegationTime The time when the bought delegation ends
     * @param cost The upfront cost of the delegation
     */
    struct DelegatedIdentity {
        bool isEnabled;
        address owner;
        address originalTokenReceiver;
        address delegatee;
        uint8 durationInMonths;
        uint32 endDelegationTime;
        uint128 cost;
    }

    error NotSigner();
    error ExpiredSignature();

    error DelegationNotOver();
    error DelegationNotActive();
    error DelegationOver();
    error NotDelegatee();
    error NotPaid();
    error InvalidMonthTime();

    event TokenReceiverUpdated(uint256 indexed walletId, string indexed walletName, address newTokenReceiver);
    event DelegationUpdated(string indexed identity, uint256 indexed nftId, bool isEnabled);
    event IdentityDelegated(
        string indexed identity, uint256 indexed nftId, address indexed delegatee, uint32 endPeriod
    );

    /**
     * createWithSignature Create an Identity with signature to avoid getting front-runned
     * @param _name Name of the Identity
     * @param _receiverWallet Wallet that will be receiving the rewards
     * @param _deadline Deadline of the signature
     * @param _signature signed message abi.encodePacket(userAddress,name,deadline)
     */
    function createWithSignature(
        string calldata _name,
        address _receiverWallet,
        uint256 _deadline,
        bytes memory _signature
    ) external payable;

    /**
     * create Create an Identity
     * @param _name name of the Identity
     * @param _receiverWallet Wallet that will be receiving the rewards
     */
    function create(string calldata _name, address _receiverWallet) external payable;

    /**
     * @notice delegate Send temporary your nft away to let other user use it for a period of time
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @param _delegateCost cost to accept this delegation
     * @param _amountOfMonths term duration in months
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     */
    function delegate(uint256 _nftId, string memory _name, uint128 _delegateCost, uint8 _amountOfMonths) external;

    /**
     * @notice acceptDelegation Accept a delegation to use it for yourself during the set period defined
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @param _receiverWallet wallet you want the token(s) to be minted to
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     */
    function acceptDelegation(uint256 _nftId, string memory _name, address _receiverWallet) external payable;
    /**
     * @notice toggleDelegation Disable/Enable your delegation, so if it's currently used, nobody won't be able to
     * accept it
     * when the term ends
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     */
    function toggleDelegation(uint256 _nftId, string memory _name) external;

    /**
     * @notice retrieveDelegation() your identity
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     * @dev Only the identity original; owner can call this and it shouldn't be during a delegation
     * @dev The system will automatically restore the original wallet receiver before transferring
     */
    function retrieveDelegation(uint256 _nftId, string memory _name) external;

    /**
     * updateDelegationWalletReceiver Update the wallet that will receive the token(s) from the delegation
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @param _receiverWallet wallet you want the token(s) to be minted to
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     * @dev only the delegatee can call this function. The term needs to be still active
     */
    function updateDelegationWalletReceiver(uint256 _nftId, string memory _name, address _receiverWallet) external;

    /**
     * updateReceiverAddress Update Receiver Wallet of an Identity
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @param _receiver address that will be receiving any rewards
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     * @dev Only the owner of the Identity can call this function
     */
    function updateReceiverAddress(uint256 _nftId, string memory _name, address _receiver) external;

    /**
     * getIdentityDataWithName Get Identity information with name
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @return identity_ tuple(name,tokenReceiver)
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     */
    function getIdentityData(uint256 _nftId, string calldata _name) external view returns (Identifier memory);

    /**
     * @notice getDelegationData() Retrieves delegation data using the identity name.
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     */
    function getDelegationData(uint256 _nftId, string calldata _name)
        external
        view
        returns (DelegatedIdentity memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IIdentityERC721 {
    error NameAlreadyTaken();
    error InvalidCharacter(uint256 characterIndex);
    error ValueIsNotEqualsToCost();
    error TreasuryNotSet();
    error NotIdentityOwner();
    error InvalidIdZero();

    event NewIdentityCreated(uint256 indexed identityId, string indexed identityName, address indexed owner);
    event NameFilterUpdated(address indexed newNameFilter);
    event CostUpdated(uint256 newCost);

    /**
     * @notice getIdentityNFTId get the NFT Id attached to the name
     * @param _name Identity Name
     * @return nftId
     * @dev ID: 0 == DEAD_NFT
     */
    function getIdentityNFTId(string calldata _name) external view returns (uint256);

    /**
     * @notice ownerOf getOwner of the NFT with the Identity Name
     * @param _name Name of the Identity
     */
    function ownerOf(string calldata _name) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title SendNativeHelper
 * @notice This helper facilitates the sending of native tokens and manages actions in case of reversion or tracking
 * rewards upon failure.
 */
abstract contract SendNativeHelper {
    error NotEnough();
    error FailedToSendETH();

    mapping(address wallet => uint256) internal pendingClaims;

    function _sendNative(address _to, uint256 _amount, bool _revertIfFails) internal {
        if (_amount == 0) return;

        (bool success,) = _to.call{ gas: 60_000, value: _amount }("");

        if (!success) {
            if (_revertIfFails) revert FailedToSendETH();
            pendingClaims[_to] += _amount;
        }
    }

    function claimFund() external {
        uint256 balance = pendingClaims[msg.sender];
        pendingClaims[msg.sender] = 0;

        if (balance == 0) revert NotEnough();

        _sendNative(msg.sender, balance, true);
    }

    function getPendingToClaim(address _user) external view returns (uint256) {
        return pendingClaims[_user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.20;

import {IERC721} from "./IERC721.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";
import {IERC721Metadata} from "./extensions/IERC721Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {Strings} from "../../utils/Strings.sol";
import {IERC165, ERC165} from "../../utils/introspection/ERC165.sol";
import {IERC721Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Errors {
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    mapping(uint256 tokenId => address) private _owners;

    mapping(address owner => uint256) private _balances;

    mapping(uint256 tokenId => address) private _tokenApprovals;

    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     *
     * IMPORTANT: Any overrides to this function that add ownership of tokens not tracked by the
     * core ERC721 logic MUST be matched with the use of {_increaseBalance} to keep balances
     * consistent with ownership. The invariant to preserve is that for any address `a` the value returned by
     * `balanceOf(a)` must be equal to the number of tokens such that `_ownerOf(tokenId)` is `a`.
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
     */
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
     * particular (ignoring whether it is owned by `owner`).
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev Checks if `spender` can operate on `tokenId`, assuming the provided `owner` is the actual owner.
     * Reverts if `spender` does not have approval from the provided `owner` for the given token or for all its assets
     * the `spender` for the specific `tokenId`.
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * NOTE: the value is limited to type(uint128).max. This protect against _balance overflow. It is unrealistic that
     * a uint256 would ever overflow from increments when these increments are bounded to uint128 values.
     *
     * WARNING: Increasing an account's balance using this function tends to be paired with an override of the
     * {_ownerOf} function to resolve the ownership of the corresponding tokens so that balances and ownership
     * remain consistent with one another.
     */
    function _increaseBalance(address account, uint128 value) internal virtual {
        unchecked {
            _balances[account] += value;
        }
    }

    /**
     * @dev Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the current owner
     * (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that
     * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
     *
     * Emits a {Transfer} event.
     *
     * NOTE: If overriding this function in a way that tracks balances, see also {_increaseBalance}.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        address from = _ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                _balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                _balances[to] += 1;
            }
        }

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
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
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    /**
     * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        _checkOnERC721Received(address(0), to, tokenId, data);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address previousOwner = _update(address(0), tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
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
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking that contract recipients
     * are aware of the ERC721 standard to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is like {safeTransferFrom} in the sense that it invokes
     * {IERC721Receiver-onERC721Received} on the receiver, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `tokenId` token must exist and be owned by `from`.
     * - `to` cannot be the zero address.
     * - `from` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeTransfer-address-address-uint256-}[`_safeTransfer`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that `auth` is
     * either the owner of the token, or approved to operate on all tokens held by this owner.
     *
     * Emits an {Approval} event.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    /**
     * @dev Variant of `_approve` with an optional flag to enable or disable the {Approval} event. The event is not
     * emitted in the context of transfers.
     */
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        // Avoid reading the owner unless necessary
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            // We do not use _isAuthorized because single-token approvals should not be able to call approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        _tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Requirements:
     * - operator can't be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` doesn't have a current owner (it hasn't been minted, or it has been burned).
     * Returns the owner.
     *
     * Overrides to ownership logic should be done to {_ownerOf}.
     */
    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address. This will revert if the
     * recipient doesn't accept the token transfer. The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title NameFilter
 * @notice It filters the character we do not allow in an Identity Name.
 * @dev It is in it's standalone as we might later on change the name filtering logic, allowing or removing unicodes
 */
contract NameFilter {
    function isNameValid(string calldata _str) external pure returns (bool valid_) {
        (valid_,) = isNameValidWithIndexError(_str);
        return valid_;
    }

    function isNameValidWithIndexError(string calldata _str) public pure returns (bool, uint256 index) {
        bytes memory strBytes = bytes(_str);
        uint8 charByte;
        uint16 charValue;

        if (strBytes.length == 0) return (false, index);

        while (index < strBytes.length) {
            charByte = uint8(strBytes[index]);

            if (charByte <= 0x7F) {
                // Single byte character (Basic Latin range)
                if (
                    !(charByte > 0x20 && charByte <= 0x7E) || charByte == 0xA0 || charByte == 0x24 || charByte == 0x3A
                        || charByte == 0x2C || charByte == 0x40 || charByte == 0x2D
                ) {
                    return (false, index);
                }
                index += 1;
            } else if (charByte < 0xE0) {
                // Two byte character
                if (index + 1 >= strBytes.length) {
                    return (false, index); // Incomplete UTF-8 sequence
                }
                charValue = (uint16(uint8(strBytes[index]) & 0x1F) << 6) | (uint16(uint8(strBytes[index + 1])) & 0x3F);
                if (
                    charValue < 0x00A0 || charValue == 0x200B || charValue == 0xFEFF
                        || (charValue >= 0x2000 && charValue <= 0x206F) // General Punctuation
                        || (charValue >= 0x2150 && charValue <= 0x218F) // Number Forms
                        || (charValue >= 0xFF00 && charValue <= 0xFFEF) // Halfwidth and Fullwidth Forms
                        || (charValue >= 161 && charValue <= 191) // Latin-1 Supplement
                        || charValue == 215 || charValue == 247 // Multiplication and Division signs
                ) {
                    return (false, index);
                }
                index += 2;
            } else {
                // Three byte character (CJK, Cyrillic, Arabic, Hebrew, Hangul Jamo, etc.)
                if (index + 2 >= strBytes.length) {
                    return (false, index); // Incomplete UTF-8 sequence
                }
                charValue = (uint16(uint8(strBytes[index]) & 0x0F) << 12)
                    | (uint16(uint8(strBytes[index + 1]) & 0x3F) << 6) | (uint16(uint8(strBytes[index + 2])) & 0x3F);
                if (
                    (charValue >= 0x1100 && charValue <= 0x11FF) // Hangul Jamo
                        || (charValue >= 0x0410 && charValue <= 0x044F) // Cyrillic
                        || (charValue >= 0x3040 && charValue <= 0x309F) // Hiragana
                        || (charValue >= 0x30A0 && charValue <= 0x30FF) // Katakana
                        || (charValue >= 0xAC00 && charValue <= 0xD7AF) // Hangul
                        || (charValue >= 0x0600 && charValue <= 0x06FF) // Arabic
                        || (charValue >= 0x05D0 && charValue <= 0x05EA) // Hebrew
                        || (charValue >= 20_000 && charValue <= 20_099) // Chinese limited range
                ) {
                    index += 3;
                } else {
                    return (false, index);
                }
            }
        }

        return (true, index);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - The `operator` cannot be the address zero.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

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
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../IERC721.sol";

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

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
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
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
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

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
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}