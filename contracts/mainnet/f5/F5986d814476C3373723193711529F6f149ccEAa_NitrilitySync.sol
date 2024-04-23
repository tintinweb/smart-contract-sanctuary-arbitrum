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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
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
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
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
            set._positions[value] = set._values.length;
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
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../NitrilityCommon.sol";

interface INitrilityFactory {
    function fetchArtistAddressForArtistId(
        string memory artistId
    ) external view returns (address[] memory);

    function fetchCollectionAddressOfArtist(
        string memory artistId
    ) external view returns (address);

    function mintLicense(
        address buyerAddr,
        string memory newTokenURI,
        NitrilityCommon.License memory license,
        NitrilityCommon.EventTypes eventType,
        NitrilityCommon.MediaListingType mediaListingType,
        uint256 price,
        uint256 amount
    ) external;

    function revenueSplits(
        NitrilityCommon.ArtistRevenue[] memory artistRevenues,
        uint256 revenue
    ) external;

    function reFundOffer(address refunder, uint256 offerPrice) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract NitrilityCommon {
    // Showcase Offer Status
    enum ReviewStatus {
        Pending,
        Approved,
        Rejected,
        Deleted
    }

    enum EventTypes {
        Listing,
        Change,
        Relisting,
        Unlisting,
        Gifting,
        SalePending,
        SaleAccepted,
        SaleDeclined,
        SaleDeleted,
        OfferPending,
        OfferAccepted,
        OfferDeclined,
        OfferDeleted,
        OfferEdited
    }

    enum MediaListingType {
        NonExclusive,
        Exclusive,
        Both,
        None
    }

    // Listing Type
    enum ListingType {
        OnlyBid,
        OnlyPrice,
        BidAndPrice
    }

    // Licensing Type
    enum LicensingType {
        CreatorSync,
        CreatorMasters,
        MovieSync,
        MovieMasters,
        AdvertismentSync,
        AdvertismentMasters,
        VideoGameSync,
        VideoGameMasters,
        TvShowSync,
        TvShowMasters
    }

    // Lazy Minting Data
    struct License {
        string tokenURI;
        string artistId;
        uint listedId;
        ListingType listingFormatValue;
        uint256 fPrice;
        uint256 sPrice;
        uint256 totalSupply;
        bool infiniteSupply;
        bool infiniteDuration;
        LicensingType licensingType;
        MediaListingType mediaListingType;
        uint256 startTime;
        uint256 endTime;
        bytes signature;
    }

    // Artist Revenue
    struct ArtistRevenue {
        string artistId;
        string artistName;
        uint256 percentage;
        bool isAdmin;
        ReviewStatus status;
    }

    // Discount Type
    enum DiscountType {
        PercentageOff,
        FixedAmountOff
    }

    // Discount Code
    struct DiscountCode {
        string name;
        string code;
        DiscountType discountType;
        uint256 percentage;
        uint256 fixedAmount;
        bool isValidOption;
        uint256 endTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./utils/SafeMath.sol";
import "./utils/Counters.sol";
import "./NitrilityCommon.sol";
import "./interfaces/INitrilityFactory.sol";

contract NitrilitySync is Ownable(msg.sender), ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    Counters.Counter private mediaPurchasingIds;

    EnumerableSet.UintSet mediaPurchasingDataSet;

    uint256 decimals = 18;
    address public _nitrilityFactory;

    struct MediaPurchasingData {
        uint256 listedId;
        string artistId;
        string tokenURI;
        uint256 purchasingId;
        address buyerAddr;
        uint256 purchasingPrice;
        NitrilityCommon.LicensingType licensingType;
        NitrilityCommon.EventTypes eventType;
        NitrilityCommon.MediaListingType mediaListingType;
    }

    struct LicensesData {
        address buyerAddr;
        string newTokenURI;
        NitrilityCommon.License license;
        NitrilityCommon.ArtistRevenue[] artistRevenues;
        NitrilityCommon.DiscountCode[] discountCodes;
    }

    event MediaSyncLicenseEvent(
        uint256 listedId,
        string artistId,
        string tokenURI,
        uint256 purchasingId,
        address buyerAddr,
        uint256 purchasingPrice,
        NitrilityCommon.LicensingType licensingType,
        NitrilityCommon.EventTypes eventType,
        NitrilityCommon.MediaListingType mediaListingType
    );

    mapping(uint256 => MediaPurchasingData) idToMediaPurchasingData;

    function setFactory(address nitrilityFactory) external onlyOwner {
        _nitrilityFactory = nitrilityFactory;
    }

    function purchaseCreator(
        LicensesData[] memory licensesData,
        string memory discountCode
    ) public payable {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < licensesData.length; i++) {
            require(
                licensesData[i].license.licensingType ==
                    NitrilityCommon.LicensingType.CreatorSync ||
                    licensesData[i].license.licensingType ==
                    NitrilityCommon.LicensingType.CreatorMasters,
                "Invalid Licensing Type"
            );
            require(
                (!licensesData[i].license.infiniteSupply &&
                    licensesData[i].license.totalSupply > 0) ||
                    licensesData[i].license.infiniteSupply,
                "This License is expired"
            );
            require(
                licensesData[i].license.fPrice > 0,
                "Market price should be greater than 0"
            );

            bool bDiscounted = false;
            uint256 percentage = 100;
            for (uint256 j = 0; j < licensesData[i].discountCodes.length; j++) {
                if (
                    keccak256(bytes(discountCode)) ==
                    keccak256(bytes(licensesData[i].discountCodes[j].code))
                ) {
                    bDiscounted = true;
                    percentage = licensesData[i].discountCodes[j].percentage;
                }
            }

            totalPrice += licensesData[i].license.fPrice.mul(percentage).div(
                10 ** (decimals + 2)
            );

            INitrilityFactory(_nitrilityFactory).mintLicense(
                licensesData[i].buyerAddr,
                licensesData[i].newTokenURI,
                licensesData[i].license,
                NitrilityCommon.EventTypes.SaleAccepted,
                NitrilityCommon.MediaListingType.None,
                licensesData[i].license.fPrice,
                1
            );
            INitrilityFactory(_nitrilityFactory).revenueSplits(
                licensesData[i].artistRevenues,
                licensesData[i].license.fPrice
            );
        }
        require(
            totalPrice <= msg.value,
            "Total Price should be larger than the amount of the market price"
        );
        payable(_nitrilityFactory).transfer(msg.value);
    }

    function purchaseMedia(
        NitrilityCommon.License memory license,
        string memory tokenURI,
        NitrilityCommon.MediaListingType mediaListingType,
        address buyerAddr
    ) public payable {
        require(
            license.licensingType >
                NitrilityCommon.LicensingType.CreatorMasters,
            "Invalid Licensing Type"
        );

        require(
            license.mediaListingType == mediaListingType ||
                license.mediaListingType ==
                NitrilityCommon.MediaListingType.Both,
            "Invalid Purchasing"
        );

        if (mediaListingType == NitrilityCommon.MediaListingType.Exclusive) {
            require(
                msg.value >= license.sPrice,
                "You cant purchase exclusive license with less than exclusive price"
            );
        } else {
            require(
                msg.value >= license.fPrice,
                "You cant purchase non exclusive license with less than non exclusive price"
            );
        }

        mediaPurchasingIds.increment();
        uint256 currentPurchasingId = mediaPurchasingIds.current();
        mediaPurchasingDataSet.add(currentPurchasingId);

        idToMediaPurchasingData[currentPurchasingId] = MediaPurchasingData(
            license.listedId,
            license.artistId,
            tokenURI,
            currentPurchasingId,
            buyerAddr,
            msg.value,
            license.licensingType,
            NitrilityCommon.EventTypes.SalePending,
            mediaListingType
        );

        emit MediaSyncLicenseEvent(
            license.listedId,
            license.artistId,
            tokenURI,
            currentPurchasingId,
            buyerAddr,
            msg.value,
            license.licensingType,
            NitrilityCommon.EventTypes.SalePending,
            mediaListingType
        );

        payable(_nitrilityFactory).transfer(msg.value);
    }

    function approveMediaPurchasing(
        NitrilityCommon.License memory license,
        NitrilityCommon.ArtistRevenue[] memory artistRevenues,
        uint256 mediaPurchasingId
    ) external {
        address[] memory artistAddrs = INitrilityFactory(_nitrilityFactory)
            .fetchArtistAddressForArtistId(license.artistId);
        bool valid = false;
        for (uint256 i = 0; i < artistAddrs.length; i++) {
            if (artistAddrs[i] == msg.sender) valid = true;
        }

        require(valid, "Only Artist can approve");

        require(
            idToMediaPurchasingData[mediaPurchasingId].eventType ==
                NitrilityCommon.EventTypes.SalePending,
            "Invalid License"
        );

        idToMediaPurchasingData[mediaPurchasingId].eventType = NitrilityCommon
            .EventTypes
            .SaleAccepted;

        MediaPurchasingData memory purchasingData = idToMediaPurchasingData[
            mediaPurchasingId
        ];

        INitrilityFactory(_nitrilityFactory).mintLicense(
            purchasingData.buyerAddr,
            purchasingData.tokenURI,
            license,
            NitrilityCommon.EventTypes.SaleAccepted,
            purchasingData.mediaListingType,
            purchasingData.purchasingPrice,
            1
        );
        INitrilityFactory(_nitrilityFactory).revenueSplits(
            artistRevenues,
            purchasingData.purchasingPrice
        );

        emit MediaSyncLicenseEvent(
            license.listedId,
            license.artistId,
            purchasingData.tokenURI,
            purchasingData.purchasingId,
            purchasingData.buyerAddr,
            purchasingData.purchasingPrice,
            purchasingData.licensingType,
            NitrilityCommon.EventTypes.SaleAccepted,
            purchasingData.mediaListingType
        );
    }

    function rejectMediaPurchasing(
        uint256 mediaPurchasingId
    ) external onlyOwner {
        require(
            idToMediaPurchasingData[mediaPurchasingId].eventType ==
                NitrilityCommon.EventTypes.SalePending,
            "cant reject this purchasing"
        );

        idToMediaPurchasingData[mediaPurchasingId].eventType = NitrilityCommon
            .EventTypes
            .SaleDeclined;

        MediaPurchasingData memory purchasingData = idToMediaPurchasingData[
            mediaPurchasingId
        ];

        emit MediaSyncLicenseEvent(
            purchasingData.listedId,
            purchasingData.artistId,
            purchasingData.tokenURI,
            purchasingData.purchasingId,
            purchasingData.buyerAddr,
            purchasingData.purchasingPrice,
            purchasingData.licensingType,
            NitrilityCommon.EventTypes.SaleDeclined,
            purchasingData.mediaListingType
        );

        INitrilityFactory(_nitrilityFactory).reFundOffer(
            purchasingData.buyerAddr,
            purchasingData.purchasingPrice
        );
    }

    function removeMediaPurchasing(uint256 mediaPurchasingId) external {
        require(
            idToMediaPurchasingData[mediaPurchasingId].buyerAddr == msg.sender,
            "Only bider can remove"
        );

        require(
            idToMediaPurchasingData[mediaPurchasingId].eventType ==
                NitrilityCommon.EventTypes.SalePending,
            "cant reject this purchasing"
        );

        idToMediaPurchasingData[mediaPurchasingId].eventType = NitrilityCommon
            .EventTypes
            .SaleDeleted;

        MediaPurchasingData memory purchasingData = idToMediaPurchasingData[
            mediaPurchasingId
        ];

        emit MediaSyncLicenseEvent(
            purchasingData.listedId,
            purchasingData.artistId,
            purchasingData.tokenURI,
            purchasingData.purchasingId,
            purchasingData.buyerAddr,
            purchasingData.purchasingPrice,
            purchasingData.licensingType,
            NitrilityCommon.EventTypes.SaleDeleted,
            purchasingData.mediaListingType
        );
        INitrilityFactory(_nitrilityFactory).reFundOffer(
            purchasingData.buyerAddr,
            purchasingData.purchasingPrice
        );
    }

    function fetchMediaPurchasingDataOfBuyer(
        address _buyerAddr,
        uint256 _listedId
    ) public view returns (MediaPurchasingData[] memory) {
        uint256 itemCount = 0;
        MediaPurchasingData[] memory mediaPurchasingDatas;

        for (uint256 i = 0; i < mediaPurchasingDataSet.length(); i++) {
            MediaPurchasingData
                storage purchasingData = idToMediaPurchasingData[
                    mediaPurchasingDataSet.at(i)
                ];

            if (
                purchasingData.listedId == _listedId &&
                purchasingData.buyerAddr == _buyerAddr &&
                purchasingData.eventType ==
                NitrilityCommon.EventTypes.SalePending
            ) {
                itemCount++;
            }
        }

        mediaPurchasingDatas = new MediaPurchasingData[](itemCount);
        itemCount = 0;

        for (uint256 i = 0; i < mediaPurchasingDataSet.length(); i++) {
            MediaPurchasingData
                storage purchasingData = idToMediaPurchasingData[
                    mediaPurchasingDataSet.at(i)
                ];

            if (
                purchasingData.listedId == _listedId &&
                purchasingData.buyerAddr == _buyerAddr &&
                purchasingData.eventType ==
                NitrilityCommon.EventTypes.SalePending
            ) {
                mediaPurchasingDatas[itemCount] = purchasingData;
                itemCount++;
            }
        }

        return mediaPurchasingDatas;
    }

    function isSeller(
        address _sellerAddr,
        string memory _artistId
    ) internal view returns (bool) {
        address[] memory artistAddresses = INitrilityFactory(_nitrilityFactory)
            .fetchArtistAddressForArtistId(_artistId);
        for (uint256 j = 0; j < artistAddresses.length; j++) {
            if (artistAddresses[j] == _sellerAddr) {
                return true;
            }
        }
        return false;
    }

    function fetchMediaPurchasingDataOfSeller(
        address _sellerAddr,
        uint256 _listedId
    ) public view returns (MediaPurchasingData[] memory) {
        uint256 itemCount = 0;
        MediaPurchasingData[] memory mediaPurchasingDatas;

        for (uint256 i = 0; i < mediaPurchasingDataSet.length(); i++) {
            MediaPurchasingData
                storage purchasingData = idToMediaPurchasingData[
                    mediaPurchasingDataSet.at(i)
                ];

            if (
                purchasingData.listedId == _listedId &&
                purchasingData.eventType ==
                NitrilityCommon.EventTypes.SalePending &&
                isSeller(_sellerAddr, purchasingData.artistId)
            ) {
                itemCount++;
            }
        }

        mediaPurchasingDatas = new MediaPurchasingData[](itemCount);
        itemCount = 0;

        for (uint256 i = 0; i < mediaPurchasingDataSet.length(); i++) {
            MediaPurchasingData
                storage purchasingData = idToMediaPurchasingData[
                    mediaPurchasingDataSet.at(i)
                ];

            if (
                purchasingData.listedId == _listedId &&
                purchasingData.eventType ==
                NitrilityCommon.EventTypes.SalePending &&
                isSeller(_sellerAddr, purchasingData.artistId)
            ) {
                mediaPurchasingDatas[itemCount] = purchasingData;
                itemCount++;
            }
        }

        return mediaPurchasingDatas;
    }

    function getTokenURI(
        uint256 purchasingId
    ) public view returns (string memory) {
        return idToMediaPurchasingData[purchasingId].tokenURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
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
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}