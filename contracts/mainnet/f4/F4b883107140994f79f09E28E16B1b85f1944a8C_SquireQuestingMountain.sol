/**
 *Submitted for verification at Arbiscan on 2022-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract TRINKET {

    function mintUpgrade(address to,  uint tokenType) external virtual;

    function changeType(address to,  uint tokenType, uint loop) external virtual;

    function addressToTypeCheck(address addr) public view virtual returns (uint[] memory);

    function mintQuesting(address to,  uint loop) external virtual;
}

abstract contract RING {

    function mintUpgrade(address to,  uint tokenType) external virtual;

    function changeType(address to,  uint tokenType, uint loop) external virtual;

    function addressToTypeCheck(address addr) public view virtual returns (uint[] memory);

    function mintQuesting(address to,  uint loop) external virtual;
}

abstract contract POTION {

    function mintUpgrade(address to,  uint tokenType) external virtual;

    function changeType(address to,  uint tokenType, uint loop) external virtual;

    function addressToTypeCheck(address addr) public view virtual returns (uint[] memory);

    function mintQuesting(address to,  uint loop) external virtual;
}

abstract contract RINGP {
    function chooseType(uint i) external virtual view returns (uint);
    function checkTypes() external virtual view returns (uint);
    function checkLevelCap() external virtual view returns (uint);
}

abstract contract TRINKETP {
    function chooseType(uint i) external virtual view returns (uint);
    function checkTypes() external virtual view returns (uint);
    function checkLevelCap() external virtual view returns (uint);
}

abstract contract SQUIRES {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256 balance);

	function upgradeTokenFromQuesting(uint256 tokenId,  uint stengthUpgrade, uint wisdomUpgrade, uint luckUpgrade, uint faithUpgrade) external virtual;

    function squireTypeByTokenId(uint256 tokenId) external view virtual returns (uint);

    function setApprovalForAll(address operator, bool _approved) external virtual;

    //contract calls to get trait totals
	function strengthByTokenId(uint256 tokenId) external view virtual returns (uint);

	function luckByTokenId(uint256 tokenId) external view virtual returns (uint);
	
	function wisdomByTokenId(uint256 tokenId) external view virtual returns (uint);
	
	function faithByTokenId(uint256 tokenId) external view virtual returns (uint);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual;
}


interface FIEF {
    function mint(address account, uint256 amount) external;
}

contract SquireQuestingMountain is IERC721Receiver, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    address public FIEF_CONTRACT;
    address public SQUIRE_CONTRACT;
    address public POTION_CONTRACT;
    address public TRINKET_CONTRACT;
    address public RING_CONTRACT;
    address public TRINKETP_CONTRACT;
    address public RINGP_CONTRACT;

    mapping(address => uint256[]) private addressToSquireMountain;

    mapping (address => uint256) public addressToAmountClaimed;
    mapping (uint => uint256) public squireToAmountClaimed;
    mapping (uint256 => uint) public lastUpgrade;
    mapping (uint256 => string) public lastUpgradeType;
    mapping (uint256 => uint) public lastReward;
    mapping (uint256 => string) public lastRewardType;
    

    mapping (uint256 => uint256) public tokenTimer;

    mapping(address => EnumerableSet.UintSet) private _MountainQuesting;
    mapping(address => mapping(uint256 => uint256)) public depositBlocks;
    bool questingActive;

     //mountain settings
    uint MtotalProbability = 1000;
    uint Mprobability1 = 690; uint Mreturn1 = 1 ether; //fief
    uint Mprobability2 = 250; 
    uint Mprobability3 = 60;   
    uint Mupgrade = 1;
    uint MprobabilityUpgrade = 200;

    //global settings
    uint skillTreeLevel1 = 10; uint skillTreeReward1 = 1;
    uint skillTreeLevel2 = 20; uint skillTreeReward2 = 2;
    uint skillTreeLevel3 = 50; uint skillTreeReward3 = 3;
    uint skillTreeLevel4 = 100; uint skillTreeReward4 = 6;

    //luck skill tree for mountain
    uint luckTree1a = 690; uint luckTree2a = 630; uint luckTree3a = 570; uint luckTree4a = 500; uint luckTree5a = 350;
    uint luckTree1b = 250; uint luckTree2b = 290; uint luckTree3b = 330; uint luckTree4b = 350; uint luckTree5b = 425;
    uint luckTree1c = 60; uint luckTree2c = 80; uint luckTree3c = 100; uint luckTree4c = 150; uint luckTree5c = 225;

    SQUIRES public squires = SQUIRES(SQUIRE_CONTRACT);
    POTION public potion = POTION(POTION_CONTRACT);
    RING public ring = RING(RING_CONTRACT);
    TRINKET public trinket = TRINKET(TRINKET_CONTRACT);
    RINGP public ringp = RINGP(TRINKET_CONTRACT);
    TRINKETP public trinketp = TRINKETP(TRINKETP_CONTRACT);

    uint256 public resetTime = 85200;

    constructor(
        address _fief,
        address _squire,
        address _potion,
        address _ring,
        address _trinket,
        address _ringp,
        address _trinketp
    ) {
        FIEF_CONTRACT = _fief;
        SQUIRE_CONTRACT = _squire;
        POTION_CONTRACT = _potion;
        RING_CONTRACT = _ring;
        TRINKET_CONTRACT = _trinket;
        RINGP_CONTRACT = _ringp;
        TRINKETP_CONTRACT = _trinketp;
        questingActive = false;
    }


    function changeResetPeriod(uint256 _time) public onlyOwner {
        resetTime = _time;
    }
    
    function toggleQuesting() public onlyOwner() {
        questingActive = !questingActive;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner() {
        FIEF_CONTRACT = _tokenAddress;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }


    function squiresQuestingMountain(address account) external view returns (uint256[] memory){
        EnumerableSet.UintSet storage depositSet = _MountainQuesting[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());
        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }
        return tokenIds;
    }

      //check squires
    function checkSquires(address owner) public view returns (uint256[] memory){
        uint256 tokenCount = SQUIRES(SQUIRE_CONTRACT).balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = SQUIRES(SQUIRE_CONTRACT).tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }


    function questMountain(uint256[] calldata squireIds) external {
        require(questingActive, "Questing must be active");
        require(squireIds.length >= 1, "1 or more Squires must go on a quest");
        for (uint256 i = 0; i < squireIds.length; i++) {
           IERC721(SQUIRE_CONTRACT).safeTransferFrom(
                msg.sender,
                address(this),
                squireIds[i],
                ''
            );
                 tokenTimer[squireIds[i]] = block.timestamp; //curent block
            _MountainQuesting[msg.sender].add(squireIds[i]);
        }
    }

       function checkIfSquireCanLeave(uint256 squireId) public view returns (bool) {
        if(block.timestamp - tokenTimer[squireId] > resetTime){
            return true;
        }
        else{
            return  false;
        }
    }

    function checkTimer(uint256 squireId) public view returns (uint) {
        return resetTime - (block.timestamp - tokenTimer[squireId]);
    }

    function leaveMountain(uint256[] calldata tokenIds) external {

        for (uint256 i; i < tokenIds.length; i++) {
        require(block.timestamp - tokenTimer[tokenIds[i]] >= resetTime,"Squires are still Questing..");

            require(
                _MountainQuesting[msg.sender].contains(tokenIds[i])
            );

            _MountainQuesting[msg.sender].remove(tokenIds[i]);

            IERC721(SQUIRE_CONTRACT).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ''
            );
            FIEF(FIEF_CONTRACT).mint(msg.sender, Mreturn1);
            squireToAmountClaimed[tokenIds[i]] = Mreturn1;
            addressToAmountClaimed[msg.sender] = Mreturn1;

            uint rewardR = RINGP(RINGP_CONTRACT).chooseType(i);
            uint rewardT = TRINKETP(TRINKETP_CONTRACT).chooseType(i);   

    if(SQUIRES(SQUIRE_CONTRACT).luckByTokenId(tokenIds[i]) <= skillTreeLevel1){
            if(random(MtotalProbability,i) <= luckTree1b){
                RING(RING_CONTRACT).mintQuesting(msg.sender,rewardR);
                 lastRewardType[tokenIds[i]] = "Ring";
                 lastReward[tokenIds[i]] = rewardR;
            }
            else if(random(MtotalProbability,i) > luckTree1b && random(MtotalProbability,i) <= luckTree1b + luckTree1c){
                TRINKET(TRINKET_CONTRACT).mintQuesting(msg.sender,rewardT);
                 lastRewardType[tokenIds[i]] = "Trinket";
                 lastReward[tokenIds[i]] = rewardT;
            }
    }
   else if(SQUIRES(SQUIRE_CONTRACT).luckByTokenId(tokenIds[i]) <= skillTreeLevel2){
            if(random(MtotalProbability,i) <= luckTree2b){
                  RING(RING_CONTRACT).mintQuesting(msg.sender,rewardR);
                 lastRewardType[tokenIds[i]] = "Ring";
                 lastReward[tokenIds[i]] = rewardR;
            }
            else if(random(MtotalProbability,i) > luckTree2b && random(MtotalProbability,i) <= luckTree2b + luckTree2c){
              TRINKET(TRINKET_CONTRACT).mintQuesting(msg.sender,rewardT);
                 lastRewardType[tokenIds[i]] = "Trinket";
                 lastReward[tokenIds[i]] = rewardT;
            }
    }
   else if(SQUIRES(SQUIRE_CONTRACT).luckByTokenId(tokenIds[i]) <= skillTreeLevel3){
            if(random(MtotalProbability,i) <= luckTree3b){
                 RING(RING_CONTRACT).mintQuesting(msg.sender,rewardR);
                 lastRewardType[tokenIds[i]] = "Ring";
                 lastReward[tokenIds[i]] = rewardR;
            }
            else if(random(MtotalProbability,i) > luckTree3b && random(MtotalProbability,i) <= luckTree3b + luckTree3c){
                 TRINKET(TRINKET_CONTRACT).mintQuesting(msg.sender,rewardT);
                 lastRewardType[tokenIds[i]] = "Trinket";
                 lastReward[tokenIds[i]] = rewardT;
            }
    } 
   else if(SQUIRES(SQUIRE_CONTRACT).luckByTokenId(tokenIds[i]) <= skillTreeLevel4){
            if(random(MtotalProbability,i) <= luckTree4b){
                RING(RING_CONTRACT).mintQuesting(msg.sender,rewardR);
                 lastRewardType[tokenIds[i]] = "Ring";
                 lastReward[tokenIds[i]] = rewardR;
            }
            else if(random(MtotalProbability,i) > luckTree4b && random(MtotalProbability,i) <= luckTree4b + luckTree4c){
                 TRINKET(TRINKET_CONTRACT).mintQuesting(msg.sender,rewardT);
                 lastRewardType[tokenIds[i]] = "Trinket";
                 lastReward[tokenIds[i]] = rewardT;
            }
        }
        else{
              if(random(MtotalProbability,i) <= luckTree5b){
                RING(RING_CONTRACT).mintQuesting(msg.sender,rewardR);
                 lastRewardType[tokenIds[i]] = "Ring";
                 lastReward[tokenIds[i]] = rewardR;
            }
            else if(random(MtotalProbability,i) > luckTree5b && random(MtotalProbability,i) <= luckTree5b + luckTree5c){
                TRINKET(TRINKET_CONTRACT).mintQuesting(msg.sender,rewardT);
                 lastRewardType[tokenIds[i]] = "Trinket";
                 lastReward[tokenIds[i]] = rewardT;
            }  
        }    


    }


    for (uint256 i; i < tokenIds.length; i++) {

       if(random(MtotalProbability,i) <= MprobabilityUpgrade){
            if(random(5,i) == 1){
                    //strength
                    SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Mupgrade, 0, 0, 0);
                    lastUpgradeType[tokenIds[i]] = "Strength";
                    lastUpgrade[tokenIds[i]] = Mupgrade;
                    }
            else if(random(5,i) == 2){
                    //wisdom
                    SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, Mupgrade, 0, 0);
                    lastUpgradeType[tokenIds[i]] = "Wisdom";
                    lastUpgrade[tokenIds[i]] = Mupgrade;
                    }
            else if(random(5,i) == 3){
                    //luck
                    SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, Mupgrade, 0);
                    lastUpgradeType[tokenIds[i]] = "Luck";
                    lastUpgrade[tokenIds[i]] = Mupgrade;
                    }
            else if(random(5,i) == 4){
                    //faith
                    SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, 0, Mupgrade);
                    lastUpgradeType[tokenIds[i]] = "Faith";
                    lastUpgrade[tokenIds[i]] = Mupgrade;
                }
             else if(random(5,i) == 5){
                    //your type
                    uint yourType = SQUIRES(SQUIRE_CONTRACT).squireTypeByTokenId(tokenIds[i]);
                    if(yourType == 1){
                    SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Mupgrade, 0, 0, 0);
                    lastUpgradeType[tokenIds[i]] = "Strength";
                    lastUpgrade[tokenIds[i]] = Mupgrade;
                    }
                    else if(yourType == 2){
                    SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, Mupgrade, 0, 0);
                    lastUpgradeType[tokenIds[i]] = "Wisdom";
                    lastUpgrade[tokenIds[i]] = Mupgrade;
                    }
                    else if(yourType == 3){
                    SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, Mupgrade, 0);
                    lastUpgradeType[tokenIds[i]] = "Luck";
                    lastUpgrade[tokenIds[i]] = Mupgrade;
                    }
                        else {
                    SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, 0, Mupgrade);
                    lastUpgradeType[tokenIds[i]] = "Faith";
                    lastUpgrade[tokenIds[i]] = Mupgrade;
                    }
                }
            }
        else{
             lastUpgradeType[tokenIds[i]] = "None";
        }
       }
    }

 	function random(uint number, uint loop) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender, loop))) % number + 1;
    }

    function luckTree1aChange(uint256 num) public onlyOwner {
    luckTree1a = num;
    }

    function luckTree2aChange(uint256 num) public onlyOwner {
        luckTree2a = num;
    }

    function luckTree3aChange(uint256 num) public onlyOwner {
        luckTree3a = num;
    }

    function luckTree4aChange(uint256 num) public onlyOwner {
        luckTree4a = num;
    }

    function luckTree5aChange(uint256 num) public onlyOwner {
        luckTree5a = num;
    }

    function luckTree1bChange(uint256 num) public onlyOwner {
        luckTree1b = num;
    }

    function luckTree2bChange(uint256 num) public onlyOwner {
        luckTree2b = num;
    }

    function luckTree3bChange(uint256 num) public onlyOwner {
        luckTree3b = num;
    }

    function luckTree4bChange(uint256 num) public onlyOwner {
        luckTree4b = num;
    }

    function luckTree5bChange(uint256 num) public onlyOwner {
        luckTree5b = num;
    }

    function luckTree1cChange(uint256 num) public onlyOwner {
        luckTree1c = num;
    }

    function luckTree2cChange(uint256 num) public onlyOwner {
        luckTree2c = num;
    }

    function luckTree3cChange(uint256 num) public onlyOwner {
        luckTree3c = num;
    }

    function luckTree4cChange(uint256 num) public onlyOwner {
        luckTree4c = num;
    }

    function luckTree5cChange(uint256 num) public onlyOwner {
        luckTree5c = num;
    }

    function Mprobability1Change(uint256 num) public onlyOwner {
        Mprobability1 = num;
    }

    function Mprobability2Change(uint256 num) public onlyOwner {
        Mprobability2 = num;
    }

    function Mprobability3Change(uint256 num) public onlyOwner {
        Mprobability3 = num;
    }

    function Mreturn1Change(uint256 num) public onlyOwner {
        Mreturn1 = num;
    }

    function MupgradeChange(uint256 num) public onlyOwner {
        Mupgrade = num;
    }

    function MprobabilityUpgradeChange(uint256 num) public onlyOwner {
        MprobabilityUpgrade = num;
    }

    function skillTreeLevel1Change(uint256 num) public onlyOwner {
        skillTreeLevel1 = num;
    }

    function skillTreeLevel2Change(uint256 num) public onlyOwner {
        skillTreeLevel2 = num;
    }

    function skillTreeLevel3Change(uint256 num) public onlyOwner {
        skillTreeLevel3 = num;
    }

    function skillTreeLevel4Change(uint256 num) public onlyOwner {
        skillTreeLevel4 = num;
    }

    function skillTreeReward1Change(uint256 num) public onlyOwner {
        skillTreeReward1 = num;
    }

    function skillTreeReward2Change(uint256 num) public onlyOwner {
        skillTreeReward2 = num;
    }

    function skillTreeReward3Change(uint256 num) public onlyOwner {
        skillTreeReward3 = num;
    }

    function skillTreeReward4Change(uint256 num) public onlyOwner {
        skillTreeReward4 = num;
    }
    
}