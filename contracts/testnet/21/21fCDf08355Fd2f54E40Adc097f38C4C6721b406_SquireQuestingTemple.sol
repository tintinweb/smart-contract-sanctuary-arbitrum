/**
 *Submitted for verification at Arbiscan on 2022-04-16
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

contract SquireQuestingTemple is IERC721Receiver, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    address public FIEF_CONTRACT;
    address public SQUIRE_CONTRACT;

    mapping (address => uint256) public addressToAmountClaimed;
    mapping (uint => uint256) public squireToAmountClaimed;
    mapping (uint256 => uint) public lastUpgrade;
    mapping (uint256 => string) public lastUpgradeType;
    mapping (uint256 => string) public lastReward;

    mapping (uint256 => uint256) public tokenTimer;

    mapping(address => EnumerableSet.UintSet) private _TempleQuesting;
    mapping(address => mapping(uint256 => uint256)) public depositBlocks;
    bool questingActive;

    //Temple settings
    uint AtotalProbability = 1000;
    uint Aprobability1a = 590; uint Aprobability2a = 370; uint Aprobability3a = 150; uint Aprobability4a = 30; uint Aprobability5a = 0;
    uint Aprobability1b = 400; uint Aprobability2b = 600; uint Aprobability3b = 800; uint Aprobability4b = 900; uint Aprobability5b = 800;
    uint Aprobability1c = 10; uint Aprobability2c = 30; uint Aprobability3c = 50; uint Aprobability4c = 70; uint Aprobability5c = 200;
    uint Aupgrade = 1;
    uint Areturn1 = 1 ether; //fief

    //global settings
    uint skillTreeLevel1 = 10; uint skillTreeReward1 = 1;
    uint skillTreeLevel2 = 20; uint skillTreeReward2 = 2;
    uint skillTreeLevel3 = 50; uint skillTreeReward3 = 3;
    uint skillTreeLevel4 = 100; uint skillTreeReward4 = 6;

    SQUIRES public squires = SQUIRES(SQUIRE_CONTRACT);

    uint256 public resetTime = 86400;

    constructor(
        address _fief,
        address _squire
    ) {
        FIEF_CONTRACT = _fief;
        SQUIRE_CONTRACT = _squire;
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

    function squiresQuestingTemple(address account) external view returns (uint256[] memory){
        EnumerableSet.UintSet storage depositSet = _TempleQuesting[account];
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

    function questTemple(uint256[] calldata squireIds) external {
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
            _TempleQuesting[msg.sender].add(squireIds[i]);
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


    function leaveTemple(uint256[] calldata tokenIds) external {

        for (uint256 i; i < tokenIds.length; i++) {

                  require(block.timestamp - tokenTimer[tokenIds[i]] >= resetTime,"Squires are still Questing..");

            require(
                _TempleQuesting[msg.sender].contains(tokenIds[i])
            );

            _TempleQuesting[msg.sender].remove(tokenIds[i]);

            IERC721(SQUIRE_CONTRACT).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ''
            );

            FIEF(FIEF_CONTRACT).mint(msg.sender, Areturn1);
            squireToAmountClaimed[tokenIds[i]] = Areturn1;
            addressToAmountClaimed[msg.sender] = Areturn1;

        
        }

    for (uint256 i; i < tokenIds.length; i++) {


        if(SQUIRES(SQUIRE_CONTRACT).faithByTokenId(tokenIds[i]) < skillTreeLevel1 ){
                    if(random(AtotalProbability,i) <= Aprobability1c){
                        if(random(4,i) == 1){
                                //strength
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, Aupgrade, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Strength & Wisdom";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 2){
                                //wisdom
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, Aupgrade, Aupgrade, 0);
                                lastUpgradeType[tokenIds[i]] = "Wisdom & Luck";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 3){
                                //luck
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, Aupgrade, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Luck & Faith";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 4){
                                //faith
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, 0, 0, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Faith & Stength";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }

                    }
                    else if(random(AtotalProbability,i) <= Aprobability1b){ 
                        
                            if(random(4,i) == 1){
                                            //strength
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, 0, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Strength";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 2){
                                //wisdom
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, Aupgrade, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Wisdom";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 3){
                                //luck
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, Aupgrade, 0);
                                lastUpgradeType[tokenIds[i]] = "Luck";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 4){
                                //faith
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, 0, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Faith";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                        }

                    }
                    else{
                        lastUpgradeType[tokenIds[i]] = "None";
                    }



        }
        else if(SQUIRES(SQUIRE_CONTRACT).faithByTokenId(tokenIds[i]) < skillTreeLevel2 ){
                    if(random(AtotalProbability,i) <= Aprobability2c){
                        if(random(4,i) == 1){
                                //strength
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, Aupgrade, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Strength & Wisdom";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 2){
                                //wisdom
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, Aupgrade, Aupgrade, 0);
                                lastUpgradeType[tokenIds[i]] = "Wisdom & Luck";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 3){
                                //luck
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, Aupgrade, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Luck & Faith";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 4){
                                //faith
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, 0, 0, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Faith & Stength";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }

                    }
                    else if(random(AtotalProbability,i) <= Aprobability2b){ 
                        
                            if(random(4,i) == 1){
                                            //strength
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, 0, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Strength";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 2){
                                //wisdom
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, Aupgrade, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Wisdom";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 3){
                                //luck
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, Aupgrade, 0);
                                lastUpgradeType[tokenIds[i]] = "Luck";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 4){
                                //faith
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, 0, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Faith";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                        }

                    }
                    else{
                        lastUpgradeType[tokenIds[i]] = "None";
                    }


                    
        }
    else if(SQUIRES(SQUIRE_CONTRACT).faithByTokenId(tokenIds[i]) < skillTreeLevel3 ){
                    if(random(AtotalProbability,i) <= Aprobability3c){
                        if(random(4,i) == 1){
                                //strength
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, Aupgrade, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Strength & Wisdom";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 2){
                                //wisdom
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, Aupgrade, Aupgrade, 0);
                                lastUpgradeType[tokenIds[i]] = "Wisdom & Luck";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 3){
                                //luck
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, Aupgrade, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Luck & Faith";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 4){
                                //faith
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, 0, 0, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Faith & Stength";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }

                    }
                    else if(random(AtotalProbability,i) <= Aprobability3b){ 
                        
                            if(random(4,i) == 1){
                                            //strength
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, 0, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Strength";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 2){
                                //wisdom
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, Aupgrade, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Wisdom";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 3){
                                //luck
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, Aupgrade, 0);
                                lastUpgradeType[tokenIds[i]] = "Luck";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 4){
                                //faith
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, 0, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Faith";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                        }

                    }
                    else{
                        lastUpgradeType[tokenIds[i]] = "None";
                    }


                    
        }
    else if(SQUIRES(SQUIRE_CONTRACT).faithByTokenId(tokenIds[i]) < skillTreeLevel4 ){
                    if(random(AtotalProbability,i) <= Aprobability4c){
                        if(random(4,i) == 1){
                                //strength
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, Aupgrade, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Strength & Wisdom";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 2){
                                //wisdom
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, Aupgrade, Aupgrade, 0);
                                lastUpgradeType[tokenIds[i]] = "Wisdom & Luck";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 3){
                                //luck
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, Aupgrade, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Luck & Faith";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 4){
                                //faith
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, 0, 0, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Faith & Stength";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }

                    }
                    else if(random(AtotalProbability,i) <= Aprobability4b){ 
                        
                            if(random(4,i) == 1){
                                            //strength
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, 0, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Strength";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 2){
                                //wisdom
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, Aupgrade, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Wisdom";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 3){
                                //luck
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, Aupgrade, 0);
                                lastUpgradeType[tokenIds[i]] = "Luck";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 4){
                                //faith
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, 0, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Faith";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                        }

                    }
                    else{
                        lastUpgradeType[tokenIds[i]] = "None";
                    }


                    
        }
         else {
                    if(random(AtotalProbability,i) <= Aprobability5c){
                        if(random(4,i) == 1){
                                //strength
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, Aupgrade, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Strength & Wisdom";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 2){
                                //wisdom
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, Aupgrade, Aupgrade, 0);
                                lastUpgradeType[tokenIds[i]] = "Wisdom & Luck";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 3){
                                //luck
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, Aupgrade, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Luck & Faith";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 4){
                                //faith
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, 0, 0, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Faith & Stength";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }

                    }
                    else if(random(AtotalProbability,i) <= Aprobability5b){ 
                        
                            if(random(4,i) == 1){
                                            //strength
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], Aupgrade, 0, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Strength";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 2){
                                //wisdom
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, Aupgrade, 0, 0);
                                lastUpgradeType[tokenIds[i]] = "Wisdom";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 3){
                                //luck
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, Aupgrade, 0);
                                lastUpgradeType[tokenIds[i]] = "Luck";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                                }
                        else if(random(4,i) == 4){
                                //faith
                                SQUIRES(SQUIRE_CONTRACT).upgradeTokenFromQuesting(tokenIds[i], 0, 0, 0, Aupgrade);
                                lastUpgradeType[tokenIds[i]] = "Faith";
                                lastUpgrade[tokenIds[i]] = Aupgrade;
                        }

                    }
                    else{
                        lastUpgradeType[tokenIds[i]] = "None";
                    }        
        }


       }
    }

 	function random(uint number, uint loop) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender, loop))) % number + 1;
    }

    function Aprobability1aChange(uint256 num) public onlyOwner {
        Aprobability1a = num;
    }

    function Aprobability2aChange(uint256 num) public onlyOwner {
        Aprobability2a = num;
    }

    function Aprobability3aChange(uint256 num) public onlyOwner {
        Aprobability3a = num;
    }

    function Aprobability4aChange(uint256 num) public onlyOwner {
        Aprobability4a = num;
    }

    function Aprobability5aChange(uint256 num) public onlyOwner {
        Aprobability5a = num;
    }

    function Aprobability1bChange(uint256 num) public onlyOwner {
        Aprobability1b = num;
    }

    function Aprobability2bChange(uint256 num) public onlyOwner {
        Aprobability2b = num;
    }

    function Aprobability3bChange(uint256 num) public onlyOwner {
        Aprobability3b = num;
    }

    function Aprobability4bChange(uint256 num) public onlyOwner {
        Aprobability4b = num;
    }

    function Aprobability5bChange(uint256 num) public onlyOwner {
        Aprobability5b = num;
    }

    function Aprobability1cChange(uint256 num) public onlyOwner {
        Aprobability1c = num;
    }

    function Aprobability2cChange(uint256 num) public onlyOwner {
        Aprobability2c = num;
    }

    function Aprobability3cChange(uint256 num) public onlyOwner {
        Aprobability3c = num;
    }

    function Aprobability4cChange(uint256 num) public onlyOwner {
        Aprobability4c = num;
    }

    function Aprobability5cChange(uint256 num) public onlyOwner {
        Aprobability5c = num;
    }

    function AupgradeChange(uint256 num) public onlyOwner {
        Aupgrade = num;
    }

    function Areturn1Change(uint256 num) public onlyOwner {
        Areturn1 = num;
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