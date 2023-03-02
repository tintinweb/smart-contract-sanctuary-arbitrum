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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Context.sol";

/**
    https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IWorldModule {
    function moduleID() external view returns (uint256);

    function tokenSVG(uint256 _actor, uint256 _startY, uint256 _lineHeight) external view returns (string memory, uint256 _endY);
    function tokenJSON(uint256 _actor) external view returns (string memory);
}

interface IWorldRandom is IWorldModule {
    function dn(uint256 _actor, uint256 _number) external view returns (uint256);
    function d20(uint256 _actor) external view returns (uint256);
}

interface IActors is IERC721, IWorldModule {

    struct Actor 
    {
        address owner;
        address account;
        uint256 actorId;
    }

    event TaiyiDAOUpdated(address taiyiDAO);
    event ActorMinted(address indexed owner, uint256 indexed actorId, uint256 indexed time);
    event ActorPurchased(address indexed payer, uint256 indexed actorId, uint256 price);

    function actor(uint256 _actor) external view returns (uint256 _mintTime, uint256 _status);
    function nextActor() external view returns (uint256);
    function mintActor(uint256 maxPrice) external returns(uint256 actorId);
    function changeActorRenderMode(uint256 _actor, uint256 _mode) external;
    function setTaiyiDAO(address _taiyiDAO) external;

    function actorPrice() external view returns (uint256);
    function getActor(uint256 _actor) external view returns (Actor memory);
    function getActorByHolder(address _holder) external view returns (Actor memory);
    function getActorsByOwner(address _owner) external view returns (Actor[] memory);
    function isHolderExist(address _holder) external view returns (bool);
}

interface IWorldYemings is IWorldModule {
    event TaiyiDAOUpdated(address taiyiDAO);

    function setTaiyiDAO(address _taiyiDAO) external;

    function YeMings(uint256 _actor) external view returns (address);
    function isYeMing(uint256 _actor) external view returns (bool);
}

interface IWorldTimeline is IWorldModule {

    event AgeEvent(uint256 indexed actor, uint256 indexed age, uint256 indexed eventId);
    event BranchEvent(uint256 indexed actor, uint256 indexed age, uint256 indexed eventId);
    event ActiveEvent(uint256 indexed actor, uint256 indexed age, uint256 indexed eventId);

    function name() external view returns (string memory);
    function description() external view returns (string memory);
    function operator() external view returns (uint256);
    function events() external view returns (IWorldEvents);

    function bornActor(uint256 _actor) external;
    function grow(uint256 _actor) external;
    function activeTrigger(uint256 _eventId, uint256 _actor, uint256[] memory _uintParams, string[] memory _stringParams) external;
}

interface IActorAttributes is IWorldModule {

    event Created(address indexed creator, uint256 indexed actor, uint256[] attributes);
    event Updated(address indexed executor, uint256 indexed actor, uint256[] attributes);

    function setAttributes(uint256 _operator, uint256 _actor, uint256[] memory _attributes) external;
    function pointActor(uint256 _operator, uint256 _actor) external;

    function attributeLabels(uint256 _attributeId) external view returns (string memory);
    function attributesScores(uint256 _attributeId, uint256 _actor) external view returns (uint256);
    function characterPointsInitiated(uint256 _actor) external view returns (bool);
    function applyModified(uint256 _actor, int[] memory _modifiers) external view returns (uint256[] memory, bool);
}

interface IActorBehaviorAttributes is IActorAttributes {

    event ActRecovered(uint256 indexed actor, uint256 indexed act);

    function canRecoverAct(uint256 _actor) external view returns (bool);
    function recoverAct(uint256 _actor) external;
}

interface IActorTalents is IWorldModule {

    event Created(address indexed creator, uint256 indexed actor, uint256[] ids);

    function talents(uint256 _id) external view returns (string memory _name, string memory _description);
    function talentAttributeModifiers(uint256 _id) external view returns (int256[] memory);
    function talentAttrPointsModifiers(uint256 _id, uint256 _attributeModuleId) external view returns (int256);
    function setTalent(uint256 _id, string memory _name, string memory _description, int[] memory _modifiers, int256[] memory _attr_point_modifiers) external;
    function setTalentExclusive(uint256 _id, uint256[] memory _exclusive) external;
    function setTalentProcessor(uint256 _id, address _processorAddress) external;
    function talentProcessors(uint256 _id) external view returns(address);
    function talentExclusivity(uint256 _id) external view returns (uint256[] memory);

    function setActorTalent(uint256 _operator, uint256 _actor, uint256 _tid) external;
    function talentActor(uint256 _operator, uint256 _actor) external; 
    function actorAttributePointBuy(uint256 _actor, uint256 _attributeModuleId) external view returns (uint256);
    function actorTalents(uint256 _actor) external view returns (uint256[] memory);
    function actorTalentsInitiated(uint256 _actor) external view returns (bool);
    function actorTalentsExist(uint256 _actor, uint256[] memory _talents) external view returns (bool[] memory);
    function canOccurred(uint256 _actor, uint256 _id, uint256 _age) external view returns (bool);
}

interface IActorTalentProcessor {
    function checkOccurrence(uint256 _actor, uint256 _age) external view returns (bool);
    function process(uint256 _operator, uint256 _actor, uint256 _age) external;
}

interface IWorldEvents is IWorldModule {

    event Born(uint256 indexed actor);

    function ages(uint256 _actor) external view returns (uint256); //current age
    function actorBorn(uint256 _actor) external view returns (bool);
    function actorBirthday(uint256 _actor) external view returns (bool);
    function expectedAge(uint256 _actor) external view returns (uint256); //age should be
    function actorEvent(uint256 _actor, uint256 _age) external view returns (uint256[] memory);
    function actorEventCount(uint256 _actor, uint256 _eventId) external view returns (uint256);

    function eventInfo(uint256 _id, uint256 _actor) external view returns (string memory);
    function eventAttributeModifiers(uint256 _id, uint256 _actor) external view returns (int256[] memory);
    function eventProcessors(uint256 _id) external view returns(address);
    function setEventProcessor(uint256 _id, address _address) external;
    function canOccurred(uint256 _actor, uint256 _id, uint256 _age) external view returns (bool);
    function checkBranch(uint256 _actor, uint256 _id, uint256 _age) external view returns (uint256);

    function bornActor(uint256 _operator, uint256 _actor) external;
    function grow(uint256 _operator, uint256 _actor) external;
    function changeAge(uint256 _operator, uint256 _actor, uint256 _age) external;
    function addActorEvent(uint256 _operator, uint256 _actor, uint256 _age, uint256 _eventId) external;
}

interface IWorldEventProcessor {
    function eventInfo(uint256 _actor) external view returns (string memory);
    function eventAttributeModifiers(uint256 _actor) external view returns (int[] memory);
    function trigrams(uint256 _actor) external view returns (uint256[] memory);
    function checkOccurrence(uint256 _actor, uint256 _age) external view returns (bool);
    function process(uint256 _operator, uint256 _actor, uint256 _age) external;
    function activeTrigger(uint256 _operator, uint256 _actor, uint256[] memory _uintParams, string[] memory _stringParams) external;

    function checkBranch(uint256 _actor, uint256 _age) external view returns (uint256);
    function setDefaultBranch(uint256 _enentId) external;
}

interface IWorldFungible is IWorldModule {
    event FungibleTransfer(uint256 indexed from, uint256 indexed to, uint256 amount);
    event FungibleApproval(uint256 indexed from, uint256 indexed to, uint256 amount);

    function balanceOfActor(uint256 _owner) external view returns (uint256);
    function allowanceActor(uint256 _owner, uint256 _spender) external view returns (uint256);

    function approveActor(uint256 _from, uint256 _spender, uint256 _amount) external;
    function transferActor(uint256 _from, uint256 _to, uint256 _amount) external;
    function transferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _amount) external;
    function claim(uint256 _operator, uint256 _actor, uint256 _amount) external;
    function withdraw(uint256 _operator, uint256 _actor, uint256 _amount) external;
}

interface IWorldNonfungible {
    event NonfungibleTransfer(uint256 indexed from, uint256 indexed to, uint256 indexed tokenId);
    event NonfungibleApproval(uint256 indexed owner, uint256 indexed approved, uint256 indexed tokenId);
    event NonfungibleApprovalForAll(uint256 indexed owner, uint256 indexed operator, bool approved);

    function tokenOfActorByIndex(uint256 _owner, uint256 _index) external view returns (uint256);
    function balanceOfActor(uint256 _owner) external view returns (uint256);
    function ownerActorOf(uint256 _tokenId) external view returns (uint256);
    function getApprovedActor(uint256 _tokenId) external view returns (uint256);
    function isApprovedForAllActor(uint256 _owner, uint256 _operator) external view returns (bool);

    function approveActor(uint256 _from, uint256 _to, uint256 _tokenId) external;
    function setApprovalForAllActor(uint256 _from, uint256 _operator, bool _approved) external;
    function safeTransferActor(uint256 _from, uint256 _to, uint256 _tokenId, bytes calldata _data) external;
    function safeTransferActor(uint256 _from, uint256 _to, uint256 _tokenId) external;
    function transferActor(uint256 _from, uint256 _to, uint256 _tokenId) external;
    function safeTransferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _tokenId, bytes calldata _data) external;
    function safeTransferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _tokenId) external;
    function transferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _tokenId) external;
}

interface IActorNames is IWorldNonfungible, IERC721Enumerable, IWorldModule {

    event NameClaimed(address indexed owner, uint256 indexed actor, uint256 indexed nameId, string name, string firstName, string lastName);
    event NameUpdated(uint256 indexed nameId, string oldName, string newName);
    event NameAssigned(uint256 indexed nameId, uint256 indexed previousActor, uint256 indexed newActor);

    function nextName() external view returns (uint256);
    function actorName(uint256 _actor) external view returns (string memory _name, string memory _firstName, string memory _lastName);
    function isNameClaimed(string memory _firstName, string memory _lastName) external view returns(bool _isClaimed);

    function claim(string memory _firstName, string memory _lastName, uint256 _actor) external returns (uint256 _nameId);
    function assignName(uint256 _nameId, uint256 _actor) external;
    function withdraw(uint256 _operator, uint256 _actor) external;
}

interface IWorldZones is IWorldNonfungible, IERC721Enumerable, IWorldModule {

    event ZoneClaimed(uint256 indexed actor, uint256 indexed zoneId, string name);
    event ZoneUpdated(uint256 indexed zoneId, string oldName, string newName);
    event ZoneAssigned(uint256 indexed zoneId, uint256 indexed previousActor, uint256 indexed newActor);

    function nextZone() external view returns (uint256);
    function names(uint256 _zoneId) external view returns (string memory);
    function timelines(uint256 _zoneId) external view returns (address);

    function claim(uint256 _operator, string memory _name, address _timelineAddress, uint256 _actor) external returns (uint256 _zoneId);
    function withdraw(uint256 _operator, uint256 _zoneId) external;
}

interface IActorBornPlaces is IWorldModule {
    function bornPlaces(uint256 _actor) external view returns (uint256);
    function bornActor(uint256 _operator, uint256 _actor, uint256 _zoneId) external;
}

interface IActorSocialIdentity is IWorldNonfungible, IERC721Enumerable, IWorldModule {
    event SIDClaimed(uint256 indexed actor, uint256 indexed sid, string name);
    event SIDDestroyed(uint256 indexed actor, uint256 indexed sid, string name);

    function nextSID() external view returns (uint256);
    function names(uint256 _nameid) external view returns (string memory);
    function claim(uint256 _operator, uint256 _nameid, uint256 _actor) external returns (uint256 _sid);
    function burn(uint256 _operator, uint256 _sid) external;
    function sidName(uint256 _sid) external view returns (uint256 _nameid, string memory _name);
    function haveName(uint256 _actor, uint256 _nameid) external view returns (bool);
}

interface IActorRelationship is IWorldModule {
    event RelationUpdated(uint256 indexed actor, uint256 indexed target, uint256 indexed rsid, string rsname);

    function relations(uint256 _rsid) external view returns (string memory);
    function setRelation(uint256 _rsid, string memory _name) external;
    function setRelationProcessor(uint256 _rsid, address _processorAddress) external;
    function relationProcessors(uint256 _id) external view returns(address);

    function setActorRelation(uint256 _operator, uint256 _actor, uint256 _target, uint256 _rsid) external;
    function actorRelations(uint256 _actor, uint256 _target) external view returns (uint256);
    function actorRelationPeople(uint256 _actor, uint256 _rsid) external view returns (uint256[] memory);
}

interface IActorRelationshipProcessor {
    function process(uint256 _actor, uint256 _age) external;
}

struct SItem 
{
    uint256 typeId;
    string typeName;
    uint256 shapeId;
    string shapeName;
    uint256 wear;
}

interface IWorldItems is IWorldNonfungible, IERC721Enumerable, IWorldModule {
    event ItemCreated(uint256 indexed actor, uint256 indexed item, uint256 indexed typeId, string typeName, uint256 wear, uint256 shape, string shapeName);
    event ItemChanged(uint256 indexed actor, uint256 indexed item, uint256 indexed typeId, string typeName, uint256 wear, uint256 shape, string shapeName);
    event ItemDestroyed(uint256 indexed item, uint256 indexed typeId, string typeName);

    function nextItemId() external view returns (uint256);
    function typeNames(uint256 _typeId) external view returns (string memory);
    function itemTypes(uint256 _itemId) external view returns (uint256);
    function itemWears(uint256 _itemId) external view returns (uint256);  //耐久
    function shapeNames(uint256 _shapeId) external view returns (string memory);
    function itemShapes(uint256 _itemId) external view returns (uint256); //品相

    function item(uint256 _itemId) external view returns (SItem memory);

    function mint(uint256 _operator, uint256 _typeId, uint256 _wear, uint256 _shape, uint256 _actor) external returns (uint256);
    function modify(uint256 _operator, uint256 _itemId, uint256 _wear) external;
    function burn(uint256 _operator, uint256 _itemId) external;
    function withdraw(uint256 _operator, uint256 _itemId) external;
}

interface IActorPrelifes is IWorldModule {

    event Reincarnation(uint256 indexed actor, uint256 indexed postLife);

    function preLifes(uint256 _actor) external view returns (uint256);
    function postLifes(uint256 _actor) external view returns (uint256);

    function setPrelife(uint256 _operator, uint256 _actor, uint256 _prelife) external;
}

interface IActorLocations is IWorldModule {

    event ActorLocationChanged(uint256 indexed actor, uint256 indexed oldA, uint256 indexed oldB, uint256 newA, uint256 newB);

    function locationActors(uint256 _A, uint256 _B) external view returns (uint256[] memory);
    function actorLocations(uint256 _actor) external view returns (uint256[] memory); //return 2 items array
    function actorFreeTimes(uint256 _actor) external view returns (uint256);
    function isActorLocked(uint256 _actor) external view returns (bool);
    function isActorUnlocked(uint256 _actor) external view returns (bool);

    function setActorLocation(uint256 _operator, uint256 _actor, uint256 _A, uint256 _B) external;
    function lockActor(uint256 _operator, uint256 _actor, uint256 _freeTime) external;
    function unlockActor(uint256 _operator, uint256 _actor) external;
    function finishActorTravel(uint256 _actor) external;
}

interface ITrigramsRender is IWorldModule {
}

interface ITrigrams is IWorldModule {
    
    event TrigramsOut(uint256 indexed actor, uint256 indexed trigram);

    function addActorTrigrams(uint256 _operator, uint256 _actor, uint256[] memory _trigramsData) external;
    function actorTrigrams(uint256 _actor) external view returns (int256[] memory);
}

interface IWorldStorylines is IWorldModule {
    function currentStoryNum() external view returns (uint256);
    function currentStoryByIndex(uint256 _index) external view returns (uint256);
    function isStoryExist(uint256 _storyEvtId) external view returns (bool);
    function storyHistoryNum(uint256 _storyEvtId) external view returns (uint256);

    /** storyEvtId is the start event id of this story **/

    function currentActorStoryNum(uint256 _actor) external view returns (uint256);
    function currentActorStoryByIndex(uint256 _actor, uint256 _index) external view returns (uint256); //storyEvtId
    function currentActorEventByStoryId(uint256 _actor, uint256 _storyEvtId) external view returns (uint256); //eventId
    function isActorInStory(uint256 _actor, uint256 _storyEvtId) external view returns (bool);

    function currentStoryActorNum(uint256 _storyEvtId) external view returns (uint256);
    function currentStoryActorByIndex(uint256 _storyEvtId, uint256 _index) external view returns (uint256); //actor id

    //set eventId to ZERO means end of this story, should delete info for this story
    function setActorStory(uint256 _operator, uint256 _actor, uint256 _storyEvtId, uint256 _eventId) external;

    //操作由剧情所有的角色
    function triggerActorEvent(uint256 _operator, uint256 _actor, uint256 _eventId) external;
}

interface IParameterizedStorylines is IWorldStorylines {
    function storyStringParameters(uint256 _storyEvtId) external view returns (string[] memory);
    function storyUIntParameters(uint256 _storyEvtId) external view returns (uint256[] memory);

    function setStoryParameters(uint256 _operator, uint256 _storyEvtId, string[] memory _params) external;
    function setStoryParameters(uint256 _operator, uint256 _storyEvtId, uint256[] memory _params) external;
}

interface IGlobalStoryRegistry is IWorldModule {
    function storyNum() external view returns (uint256);
    function storyByIndex(uint256 _index) external view returns (uint256);
    function hasStory(uint256 _storyEvtId) external view returns (bool);
    function canStoryRepeat(uint256 _storyEvtId) external view returns (bool);

    function registerStory(uint256 _operator, uint256 _storyEvtId, uint256 _canRepeat) external;
    function removeStory(uint256 _operator, uint256 _storyEvtId) external;
}

interface INameGenerator is IWorldModule {
    //数量，性别（0随机），字数（0随机，1一字，2二字），姓（“”随机），辈分（“”随机），名（“”随机）
    function genName(uint256 number, uint256 gender, uint256 ct, string memory family, string memory middle, string memory given, uint256 seed) external view returns(string[] memory);

    function registerGender(uint256 _operator, string[] memory strs) external;
    function removeGender(uint256 _operator, string[] memory strs) external;

    function registerFamily(uint256 _operator, string[] memory strs) external;
    function removeFamily(uint256 _operator, string[] memory strs) external;

    function registerMiddle(uint256 _operator, string[] memory strs) external;
    function removeMiddle(uint256 _operator, string[] memory strs) external;

    function registerGiven(uint256 _operator, string memory gender, string[] memory strs) external;
    function removeGiven(uint256 _operator, string memory gender, string[] memory strs) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library WorldConstants {

    //special actors ID
    uint256 public constant ACTOR_PANGU = 1;

    //actor attributes ID
    uint256 public constant ATTR_BASE = 0;
    uint256 public constant ATTR_AGE = 0; // 年龄
    uint256 public constant ATTR_HLH = 1; // 健康，生命

    //module ID
    uint256 public constant WORLD_MODULE_ACTORS       = 0;  //角色
    uint256 public constant WORLD_MODULE_RANDOM       = 1;  //随机数
    uint256 public constant WORLD_MODULE_NAMES        = 2;  //姓名
    uint256 public constant WORLD_MODULE_COIN         = 3;  //通货
    uint256 public constant WORLD_MODULE_YEMINGS      = 4;  //噎明权限
    uint256 public constant WORLD_MODULE_ZONES        = 5;  //区域
    uint256 public constant WORLD_MODULE_SIDS         = 6;  //身份
    uint256 public constant WORLD_MODULE_ITEMS        = 7;  //物品
    uint256 public constant WORLD_MODULE_PRELIFES     = 8;  //前世
    uint256 public constant WORLD_MODULE_ACTOR_LOCATIONS    = 9;  //角色定位

    uint256 public constant WORLD_MODULE_TRIGRAMS_RENDER    = 10; //角色符文渲染器
    uint256 public constant WORLD_MODULE_TRIGRAMS           = 11; //角色符文数据

    uint256 public constant WORLD_MODULE_SIFUS        = 12; //师傅令牌
    uint256 public constant WORLD_MODULE_ATTRIBUTES   = 13; //角色基本属性
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../../interfaces/WorldInterfaces.sol";
import '../../libs/WorldConstants.sol';
import "../WorldConfigurable.sol";

contract NameGenerator is INameGenerator, WorldConfigurable {

    /* *******
     * Globals
     * *******
     */

    string[] internal _genders;
    mapping(string => uint256) internal _genderIndices; //map gender string to (index+1) in _genders, 0 means not exist

    string[] internal _families;
    mapping(string => uint256) internal _familyIndices; //map family string to (index+1) in _families, 0 means not exist

    string[] internal _mids;
    mapping(string => uint256) internal _midIndices; //map middle string to (index+1) in _mids, 0 means not exist

    string[][] internal _givens;
    mapping(string => mapping(string => uint256)) internal _givenIndices; //map gender string to a map (given string to (index+1)) in _givens, 0 means not exist

    /* *********
     * Modifiers
     * *********
     */

    /* ****************
     * Public Functions
     * ****************
     */

    constructor(WorldContractRoute _route) WorldConfigurable(_route) {}

    function registerGender(uint256 _operator, string[] memory strs) public override 
        onlyYeMing(_operator)
    {
        for(uint256 i=0; i<strs.length; i++) {
            require(validateName(strs[i]), 'invalid gender');
            require(_genderIndices[strs[i]] == 0, "gender already exist");

            _genderIndices[strs[i]] = _genders.length + 1; //index + 1
            _genders.push(strs[i]);
            
            _givens.push(new string[](0));
        }
    }

    function removeGender(uint256 _operator, string[] memory strs) public override 
        onlyYeMing(_operator)
    {
        for(uint256 i=0; i<strs.length; i++) {
            uint256 genderId = _genderIndices[strs[i]];
            require(genderId > 0, "gender not exist");

            _genders[genderId - 1] = _genders[_genders.length - 1];
            _genders.pop();
            delete _genderIndices[strs[i]];
        }
    }

    function registerFamily(uint256 _operator, string[] memory strs) public override 
        onlyYeMing(_operator)
    {
        for(uint256 i=0; i<strs.length; i++) {
            require(validateName(strs[i]), 'invalid family');
            require(_familyIndices[strs[i]] == 0, "family already exist");

            _familyIndices[strs[i]] = _families.length + 1; //index + 1
            _families.push(strs[i]);
        }
    }

    function removeFamily(uint256 _operator, string[] memory strs) public override
        onlyYeMing(_operator)
    {
        for(uint256 i=0; i<strs.length; i++) {
            require(_familyIndices[strs[i]] > 0, "family not exist");

            _families[_familyIndices[strs[i]] - 1] = _families[_families.length - 1];
            _families.pop();
            delete _familyIndices[strs[i]];
        }
    }


    function registerMiddle(uint256 _operator, string[] memory strs) public override 
        onlyYeMing(_operator)
    {
        for(uint256 i=0; i<strs.length; i++) {
            require(validateName(strs[i]), 'invalid middle');
            require(_midIndices[strs[i]] == 0, "middle already exist");

            _midIndices[strs[i]] = _mids.length + 1; //index + 1
            _mids.push(strs[i]);
        }
    }

    function removeMiddle(uint256 _operator, string[] memory strs) public override
        onlyYeMing(_operator)
    {
        for(uint256 i=0; i<strs.length; i++) {
            require(_midIndices[strs[i]] > 0, "middle not exist");

            _mids[_midIndices[strs[i]] - 1] = _mids[_mids.length - 1];
            _mids.pop();
            delete _midIndices[strs[i]];
        }
    }

    function registerGiven(uint256 _operator, string memory gender, string[] memory strs) public override 
        onlyYeMing(_operator)
    {
        uint256 genderId = _genderIndices[gender];
        require(genderId > 0, "gender not exist");
        require(genderId <= _givens.length, "internal error");
        genderId -= 1; //index

        for(uint256 i=0; i<strs.length; i++) {
            require(validateName(strs[i]), 'invalid given');
            require(_givenIndices[gender][strs[i]] == 0, "given already exist");

            _givenIndices[gender][strs[i]] = _givens[genderId].length + 1; //index + 1
            _givens[genderId].push(strs[i]);        
        }
    }

    function removeGiven(uint256 _operator, string memory gender, string[] memory strs) public override
        onlyYeMing(_operator)
    {
        uint256 genderId = _genderIndices[gender];
        require(genderId > 0, "gender not exist");
        require(genderId <= _givens.length, "internal error");
        genderId -= 1; //index

        for(uint256 i=0; i<strs.length; i++) {
            require(_givenIndices[gender][strs[i]] > 0, "given not exist");

            _givens[genderId][_givenIndices[gender][strs[i]] - 1] = _givens[genderId][_givens[genderId].length - 1];
            _givens[genderId].pop();
            delete _givenIndices[gender][strs[i]];
        }
    }

    /* ****************
     * External Functions
     * ****************
     */

    function moduleID() external override pure returns (uint256) { return 225; }

    function tokenSVG(uint256 /*_actor*/, uint256 _startY, uint256 /*_lineHeight*/) external virtual override view returns (string memory, uint256 _endY) {
        _endY = _startY;
        return ("", _endY);
    }

    function tokenJSON(uint256 /*_actor*/) external virtual override view returns (string memory) {
        return "{}";
    }

    /* **************
     * View Functions
     * **************
     */

    //数量，性别（0随机），字数（0随机，1一字，2二字），姓（“”随机），辈分（“”随机），名（“”随机）
    //返回字符串数组，[名称0的姓,名称0的辈分,名称0的名,...]
    function genName(uint256 number,
        uint256 gender,
        uint256 ct, 
        string memory family, 
        string memory middle, 
        string memory given, 
        uint256 seed) external view override returns(string[] memory) 
    {
        require(ct <= 2, "invalid ct");
        require(number > 0, "invalid number");
        require(gender <= _genders.length, "invalid gender");

        string[] memory _names = new string[](number*3); 

        uint256 _gender = gender>0?(gender-1):0;
        uint256 _ct = ct;
        string memory _family = family;
        string memory _middle = middle;
        string memory _given = given;

        for(uint256 i=0; i<number; i++) {
            if(gender == 0)
                _gender = _dn(1733+i+seed, _genders.length);
            if(bytes(family).length == 0)
                _family = _families[_dn(2287+i+seed, _families.length)];
            if(ct == 0)
                _ct = _dn(4253+i+seed, 2) + 1;

            if(_ct == 1) {
                _middle = "";
            }
            else {
                if(bytes(middle).length == 0)
                    _middle = _mids[_dn(10151+i+seed, _mids.length)];            
            }

            if(bytes(given).length == 0)
                _given = _givens[_gender][_dn(13913+i+seed, _givens[_gender].length)];            

            _names[3*i + 0] = _family;
            _names[3*i + 1] = _middle;
            _names[3*i + 2] = _given;
        }

        return _names;
    }

    /* *****************
     * Internal Functions
     * *****************
     */

    // @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
    function validateName(string memory str) internal pure returns (bool) {
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 last_char = b[0];
        for(uint256 i; i<b.length; i++){
            bytes1 char = b[i];
            if (char == 0x20 && last_char == 0x20) return false; // Cannot contain continous spaces
            last_char = char;
        }

        return true;
    }

    function _dn(uint256 _s, uint256 _number) internal view returns (uint256) {
        return _seed(_s) % _number;
    }

    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _seed(uint256 _s) internal view returns (uint256 rand) {
        rand = _random(
            string(
                abi.encodePacked(
                    block.timestamp,
                    blockhash(block.number - 1),
                    _s,
                    msg.sender
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./WorldContractRoute.sol";

contract WorldConfigurable
{
    WorldContractRoute internal worldRoute;

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "not approved or owner of actor");
        _;
    }

    modifier onlyPanGu() {
        require(_isActorApprovedOrOwner(WorldConstants.ACTOR_PANGU), "only PanGu");
        _;
    }

    modifier onlyYeMing(uint256 _actor) {
        require(IWorldYemings(worldRoute.modules(WorldConstants.WORLD_MODULE_YEMINGS)).isYeMing(_actor), "only YeMing");
        require(_isActorApprovedOrOwner(_actor), "not YeMing's operator");
        _;
    }

    constructor(WorldContractRoute _route) {
        worldRoute = _route;
    }

    function _isActorApprovedOrOwner(uint _actor) internal view returns (bool) {
        IActors actors = worldRoute.actors();
        return (actors.getApproved(_actor) == msg.sender || actors.ownerOf(_actor) == msg.sender) || actors.isApprovedForAll(actors.ownerOf(_actor), msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/WorldInterfaces.sol";
import "../libs/WorldConstants.sol";
import "../base/Ownable.sol";

contract WorldContractRoute is Ownable
{ 
    uint256 public constant ACTOR_PANGU = 1;
    
    mapping(uint256 => address) public modules;
    address                     public actorsAddress;
    IActors                     public actors;
 
    /* *********
     * Modifiers
     * *********
     */

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "cannot set zero address");
        _;
    }

    modifier onlyPanGu() {
        require(_isActorApprovedOrOwner(ACTOR_PANGU), "only PanGu");
        _;
    }

    /* ****************
     * Internal Functions
     * ****************
     */

    function _isActorApprovedOrOwner(uint256 _actor) internal view returns (bool) {
        return (actors.getApproved(_actor) == msg.sender || actors.ownerOf(_actor) == msg.sender) || actors.isApprovedForAll(actors.ownerOf(_actor), msg.sender);
    }

    /* ****************
     * External Functions
     * ****************
     */

    function registerActors(address _address) external 
        onlyOwner
        onlyValidAddress(_address)
    {
        require(actorsAddress == address(0), "Actors address already registered.");
        actorsAddress = _address;
        actors = IActors(_address);
        modules[WorldConstants.WORLD_MODULE_ACTORS] = _address;
    }

    function registerModule(uint256 id, address _address) external 
        onlyPanGu
        onlyValidAddress(_address)
    {
        //require(modules[id] == address(0), "module address already registered.");
        require(IWorldModule(_address).moduleID() == id, "module id is not match.");
        modules[id] = _address;
    }
}