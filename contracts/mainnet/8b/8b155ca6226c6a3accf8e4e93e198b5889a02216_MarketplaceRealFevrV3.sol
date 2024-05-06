/**
 *Submitted for verification at Arbiscan.io on 2024-05-06
*/

// File: OpenerV2/Contracts/interfaces/IUniswapV2Router.sol


pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: OpenerV2/Contracts/interfaces/BundlesInterface.sol


pragma solidity ^0.8.0;

interface BundlesInterface {
    function getBundleDistribution(uint256 tokenId) external view returns(uint16[][] memory, address[][] memory, uint256);
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: OpenerV2/Contracts/interfaces/OpenerMintInterface.sol


pragma solidity ^0.8.0;

interface OpenerMintInterface is IERC721 {

    struct MarketplaceDistribution {
        uint16[] marketplaceDistributionRates;
        address[] marketplaceDistributionAddresses;
    }

    function mint(uint256 tokenId) external;
    function getLastNFTID() external returns(uint256);
    function setLastNFTID(uint256 newId) external;

    function setRegisteredID(address _account, uint256 _id) external;
    function pushRegisteredIDsArray(address _account, uint256 _id) external;
    function exists(uint256 _tokenId) external view returns (bool);
    function alreadyMinted(uint256 _tokenId) external view returns (bool);
    function mintedCounts(address _account) external view returns (uint256);
    function getRegisteredIDs(address _account) external view returns (uint256[] memory);
    
    function setMarketplaceDistribution(uint16[] memory distributionRates, address[] memory distributionAddresses, uint256 _id) external;
    function getMarketplaceDistributionForERC721(uint256 _tokenId) external view returns(uint16[] memory, address[] memory);

    function setAdmin(address admin_) external;
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: OpenerV2/Contracts/interfaces/IMarketplaceRealFevrV3.sol


pragma solidity ^0.8.0;






interface IMarketplaceRealFevrV3 {
    struct MarketplaceFees {
        bool rightHolderFlag;
        bool marketplaceFeeFlag;
        uint256[] marketplaceFees;
        address[] feeAddresses;
        bool buybackTakeFee;
        uint256 buybackFee;
    }

    struct Sale {
        address collectionAddress;
        address erc20payment; // if address = 0x0, accepted payment is eth
        uint256 saleId;
        uint256 tokenId;
        //uint256 timesSold;
        uint256 price;
        address payable seller;
        address buyer;
        uint256 date;
    }

    struct Offer {
        uint256 offerId;
        address collectionAddress;
        uint256 tokenId;
        address payment;
        uint256 price;
        bool accepted;
        bool cancelled;
        address user;
    }

    struct dataType {
        address collectionAddress;
        address payment;
        uint256 price;
        uint256 tokenId;
        bool _buyERC721;
        address payable seller;
    }

    event SaleCreated(
        address indexed collectionAddress,
        uint256 indexed tokenId,
        address erc20Payment,
        uint256 price,
        address indexed creator,
        uint256 saleId
    );
    event SaleCanceled(
        address indexed collectionAddress,
        uint256 indexed tokenId,
        address indexed creator,
        uint256 saleId
    );
    event SaleCompleted(
        address indexed collectionAddress,
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price,
        uint256 saleId
    );

    // offers
    event OfferFulfilled(
        address indexed collectionAddress,
        uint256 indexed tokenId,
        uint256 indexed offerId
    );
    event OfferPlaced(
        address indexed collectionAddress,
        uint256 indexed tokenId,
        uint256 indexed offerId
    );
    event OfferCancelled(
        address indexed collectionAddress,
        uint256 indexed tokenId,
        uint256 indexed offerId
    );

    event Buyback(uint256 indexed ethAmount);
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
 * ```
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/access/Ownable2Step.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// File: OpenerV2/Contracts/marketplaceV3.sol



pragma solidity ^0.8.0;






contract MarketplaceRealFevrV3 is
    Ownable2Step,
    Pausable,
    ReentrancyGuard,
    IMarketplaceRealFevrV3
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public saleIncrementId;
    uint256 public offerIndex;
    address public immutable deadAddress;
    address public fevr;

    EnumerableSet.AddressSet private acceptableERC20s; // if erc20 is acceptable as form of payment, this is to display in frontend
    EnumerableSet.AddressSet private acceptableCollectionAddresses; // if ecr20 is acceptable as form of payment
    EnumerableSet.UintSet private availableSaleIds;
    EnumerableSet.UintSet private availableOfferIds;

    IUniswapV2Router02 public immutable uniswapV2Router;
    bool public buybackEnabled;

    mapping(address => bool) public salesClosedForCollection;
    //buyback variables
    mapping(address => uint256) minTokensBeforeSwap;
    mapping(address => uint256) tokensHeld;
    mapping(uint256 => Sale) public sales; // maps sale id with sales struct
    mapping(address => mapping(uint256 => bool)) public rejectOffers;
    mapping(address => bool) public isBundleAddress;
    mapping(address => MarketplaceFees) public nftAddressToMarketplace;
    mapping(uint256 => Offer) public offerIds;

    constructor(address _fevrAddress) {
        require(_fevrAddress != address(0), "zero fevr token address");

        offerIndex = 1;
        saleIncrementId = 1;
        _setAcceptableERC20(address(0), true); // accept eth/bnb as payment
        deadAddress = 0x000000000000000000000000000000000000dEaD;
        fevr = _fevrAddress;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function isNativeTransaction(address _erc20) public pure returns (bool) {
        return _erc20 == address(0);
    }

    function getAcceptableCollectionAddresses()
        external
        view
        returns (address[] memory)
    {
        return acceptableCollectionAddresses.values();
    }

    function getMarketplaceFeesAndAddressesForCollection(
        address collection
    ) external view returns (uint256[] memory, address[] memory) {
        return (
            nftAddressToMarketplace[collection].marketplaceFees,
            nftAddressToMarketplace[collection].feeAddresses
        );
    }

    function getAcceptableERC20s() external view returns (address[] memory) {
        return acceptableERC20s.values();
    }

    function getAvailableSaleIds() external view returns (uint256[] memory) {
        return availableSaleIds.values();
    }

    function getAvailableOfferIds() external view returns (uint256[] memory) {
        return availableOfferIds.values();
    }

    function setIsBundle(
        address bundleAddress,
        bool state
    ) external onlyOwner whenNotPaused {
        isBundleAddress[bundleAddress] = state;
    }

    function setSalesClosedForCollection(
        address _collection,
        bool _state
    ) external onlyOwner whenNotPaused {
        salesClosedForCollection[_collection] = _state;
    }

    function setBuybackEnabled(bool _state) external onlyOwner whenNotPaused {
        buybackEnabled = _state;
    }

    function setBuyBackTakeFee(
        address _address,
        bool _state
    ) external onlyOwner whenNotPaused {
        nftAddressToMarketplace[_address].buybackTakeFee = _state;
    }

    function editRejectOffers(
        address collectionAddress,
        uint256 _tokenId,
        bool _state
    ) external whenNotPaused {
        require(
            acceptableCollectionAddresses.contains(collectionAddress),
            "This collection address is not accepted"
        );
        require(
            IERC721(collectionAddress).ownerOf(_tokenId) == msg.sender,
            "Not the owner"
        );
        rejectOffers[collectionAddress][_tokenId] = _state;
    }

    function addERC20AcceptablePayment(
        address _token
    ) external onlyOwner whenNotPaused {
        _setAcceptableERC20(_token, true);
    }

    function removeERC20AcceptablePayment(
        address _token
    ) external onlyOwner whenNotPaused {
        _setAcceptableERC20(_token, false);
    }

    function addAcceptableCollectionAddress(
        address _collection
    ) external onlyOwner whenNotPaused {
        _setAcceptableCollection(_collection, true);
    }

    function removeAcceptableCollectionAddress(
        address _collection
    ) external onlyOwner whenNotPaused {
        _setAcceptableCollection(_collection, false);
    }

    function putERC721OnSale(
        address _collectionAddress,
        uint256 _tokenId,
        address _erc20payment,
        uint256 _price
    ) public whenNotPaused nonReentrant {
        require(
            checkCollectionAddressAccepted(_collectionAddress),
            "This collection address is not accepted"
        );
        require(
            checkERC20Payment(_erc20payment),
            "This token is not acceptable for payment"
        );
        require(
            IERC721(_collectionAddress).ownerOf(_tokenId) == msg.sender,
            "Not Owner of the NFT"
        );
        require(
            !salesClosedForCollection[address(_collectionAddress)],
            "Sales are closed for this collection"
        );

        IERC721(_collectionAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        // Create Sale Object
        uint256 curSaleId = saleIncrementId;
        sales[saleIncrementId++] = Sale(
            _collectionAddress,
            _erc20payment,
            curSaleId,
            _tokenId,
            _price,
            payable(msg.sender),
            address(0),
            block.timestamp
        );

        availableSaleIds.add(curSaleId);
        emit SaleCreated(
            _collectionAddress,
            _tokenId,
            _erc20payment,
            _price,
            msg.sender,
            curSaleId
        );
    }

    function putMultipleERC721OnSale(
        address[] memory _collectionAddress,
        uint256[] memory _tokenId,
        address[] memory _erc20payment,
        uint256[] memory _price
    ) external whenNotPaused {
        for (uint256 i = 0; i < _collectionAddress.length; i++) {
            putERC721OnSale(
                _collectionAddress[i],
                _tokenId[i],
                _erc20payment[i],
                _price[i]
            );
        }
    }

    function removeERC721FromSale(
        uint256 _saleID
    ) external whenNotPaused nonReentrant {
        Sale memory sale = sales[_saleID];
        address sender = msg.sender;

        require(availableSaleIds.contains(_saleID), "not exists saleID");
        require(sale.seller == sender, "not sale creator");

        IERC721(sale.collectionAddress).transferFrom(
            address(this),
            sale.seller,
            sale.tokenId
        );
        emit SaleCanceled(
            sale.collectionAddress,
            sale.tokenId,
            sender,
            _saleID
        );

        availableSaleIds.remove(_saleID);
        delete sales[_saleID];
    }

    function setBuybackFee(
        address _address,
        uint256 _buybackFee
    ) external onlyOwner whenNotPaused {
        require(_buybackFee < 100, "Fee Percentage has to be lower than 100");
        nftAddressToMarketplace[_address].buybackFee = _buybackFee;
    }

    function removeERC721FromSaleAdmin(
        uint256 _saleID
    ) external onlyOwner whenNotPaused {
        Sale memory sale = sales[_saleID];

        require(availableSaleIds.contains(_saleID), "not exists saleID");
        IERC721(sale.collectionAddress).transferFrom(
            address(this),
            sale.seller,
            sale.tokenId
        );

        emit SaleCanceled(
            sale.collectionAddress,
            sale.tokenId,
            sale.seller,
            _saleID
        );
        availableSaleIds.remove(_saleID);
        delete sales[_saleID];
    }

    function buyERC721(
        uint256 _saleId
    ) public payable whenNotPaused nonReentrant {
        Sale memory sale = sales[_saleId];
        require(availableSaleIds.contains(_saleId), "not exists saleID");
        require(
            !salesClosedForCollection[address(sale.collectionAddress)],
            "Sales are closed for this collection"
        );

        //processFeePayments();
        processFeePayments(
            dataType(
                sale.collectionAddress,
                sale.erc20payment,
                sale.price,
                sale.tokenId,
                true,
                sale.seller
            )
        );

        //Transfer ERC721 to buyer
        IERC721(sale.collectionAddress).transferFrom(
            address(this),
            msg.sender,
            sale.tokenId
        );

        emit SaleCompleted(
            sale.collectionAddress,
            sale.tokenId,
            msg.sender,
            sale.price,
            _saleId
        );
        availableSaleIds.remove(_saleId);
        delete sales[_saleId];
    }

    receive() external payable {}

    //place bid
    function placeOffer(
        address _collectionAddress,
        uint256 _tokenId,
        address _erc20payment,
        uint256 _price
    ) external payable whenNotPaused nonReentrant {
        address sender = msg.sender;

        require(
            !rejectOffers[_collectionAddress][_tokenId],
            "Owner has blocked offers"
        );
        require(
            checkCollectionAddressAccepted(_collectionAddress),
            "This collection address is not accepted"
        );
        require(
            IERC721(_collectionAddress).ownerOf(_tokenId) != address(this),
            "NFT is already on sale"
        );
        require(
            checkERC20Payment(_erc20payment),
            "This token is not acceptable for payment"
        );
        require(
            !salesClosedForCollection[address(_collectionAddress)],
            "Sales are closed for this collection"
        );
        require(_price > 0, "invalid offer price");

        uint256 curOfferId = offerIndex;
        offerIds[curOfferId] = Offer(
            curOfferId,
            _collectionAddress,
            _tokenId,
            _erc20payment,
            _price,
            false,
            false,
            sender
        );

        if (isNativeTransaction(_erc20payment)) {
            // if payment is eth/bnb
            uint256 receivedAmount = msg.value;
            require(
                receivedAmount > 0 && receivedAmount == _price,
                "Price is not set correctly"
            );
        } else {
            require(
                IERC20(_erc20payment).transferFrom(
                    sender,
                    address(this),
                    _price
                ),
                "ERC20 transfer failed"
            );
        }

        availableOfferIds.add(offerIndex);
        emit OfferPlaced(_collectionAddress, _tokenId, offerIndex++);
    }

    function acceptOffer(uint256 _offerId) external whenNotPaused nonReentrant {
        Offer memory offer = offerIds[_offerId];
        require(!offer.accepted, "Offer already accepted");
        require(!offer.cancelled, "Offer is cancelled");
        require(availableOfferIds.contains(_offerId), "not exists offerId");
        require(
            !salesClosedForCollection[address(offer.collectionAddress)],
            "Sales are closed for this collection"
        );
        require(
            IERC721(offer.collectionAddress).ownerOf(offer.tokenId) ==
                msg.sender,
            "Not offer maker"
        );

        processFeePayments(
            dataType(
                offer.collectionAddress,
                offer.payment,
                offer.price,
                offer.tokenId,
                false,
                payable(address(0))
            )
        );

        //Transfer ERC721 to user who made the offer
        IERC721(offer.collectionAddress).transferFrom(
            msg.sender,
            offer.user,
            offer.tokenId
        );

        offerIds[_offerId].accepted = true;
        availableOfferIds.remove(_offerId);
        emit OfferFulfilled(offer.collectionAddress, offer.tokenId, _offerId);
    }

    function cancelOffer(uint256 _offerId) external whenNotPaused nonReentrant {
        Offer storage offer = offerIds[_offerId];
        address sender = msg.sender;

        require(sender == offer.user, "Not owner of this offer");
        require(!offer.cancelled, "Already cancelled");
        require(!offer.accepted, "Offer is already accepted");
        require(availableOfferIds.contains(_offerId), "not exits offerId");

        if (isNativeTransaction(offer.payment)) {
            payable(sender).transfer(offer.price);
        } else {
            require(
                IERC20(offer.payment).transfer(sender, offer.price),
                "ERC20 transfer failed"
            );
        }

        offer.cancelled = true;
        availableOfferIds.remove(_offerId);
        emit OfferCancelled(offer.collectionAddress, offer.tokenId, _offerId);
    }

    function changeMinTokens(
        address _token,
        uint256 _amount
    ) external onlyOwner whenNotPaused {
        minTokensBeforeSwap[_token] = _amount;
    }

    function setFevrAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "zero fevr token address");
        fevr = newAddress;
    }

    function setRightholderFlag(
        address nftAddress,
        bool state
    ) external onlyOwner whenNotPaused {
        nftAddressToMarketplace[nftAddress].rightHolderFlag = state;
    }

    function setMarketplaceFeeFlag(
        address nftAddress,
        bool state
    ) external onlyOwner whenNotPaused {
        nftAddressToMarketplace[nftAddress].marketplaceFeeFlag = state;
    }

    function setMarketplaceFeesAndAddressesForCollection(
        address collection,
        uint256[] memory fees,
        address[] memory addresses
    ) external onlyOwner whenNotPaused {
        require(fees.length > 0, "zero array length");
        require(fees.length == addresses.length, "Wrong length");
        nftAddressToMarketplace[collection].marketplaceFees = fees;
        nftAddressToMarketplace[collection].feeAddresses = addresses;
    }

    function checkERC20Payment(address _address) internal view returns (bool) {
        return acceptableERC20s.contains(_address);
    }

    function checkCollectionAddressAccepted(
        address _address
    ) internal view returns (bool) {
        return acceptableCollectionAddresses.contains(_address);
    }

    function buyback(uint256 _amount) internal {
        swapETHForTokens(_amount);
    }

    function swapETHForTokens(uint256 _amount) internal {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = fevr;

        // Create the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _amount
        }(
            0, // Accept any amount of Tokens
            path,
            deadAddress,
            block.timestamp + 300
        );
    }

    // @parameter "buyERC721" if true it means function is called by buyERC721(), if false its called by acceptOffer()
    function processFeePayments(dataType memory p) internal {
        //Get Marketplace Sale Distibutions on the Smart Contract

        // this block scope trick saves function from "stack too deep" error
        {
            uint256 buybackFee = 0;

            if (nftAddressToMarketplace[p.collectionAddress].buybackTakeFee) {
                buybackFee =
                    (p.price *
                        nftAddressToMarketplace[p.collectionAddress]
                            .buybackFee) /
                    100;
            }

            if (isNativeTransaction(p.payment)) {
                if (p._buyERC721) {
                    require(
                        p.price == msg.value,
                        "Require Amount of Native Currency to be correct"
                    );
                }

                uint256 totalFee = 0;
                if (!isBundleAddress[p.collectionAddress]) {
                    if (
                        nftAddressToMarketplace[p.collectionAddress]
                            .rightHolderFlag
                    ) {
                        (
                            uint16[] memory distributionRates,
                            address[] memory distributionAddresses
                        ) = OpenerMintInterface(p.collectionAddress)
                                .getMarketplaceDistributionForERC721(p.tokenId);
                        for (uint i = 0; i < distributionRates.length; i++) {
                            if (distributionAddresses[i] != address(0)) {
                                // Transfer fee to fee address
                                uint256 feeAmount = (distributionRates[i] *
                                    p.price) / 100;
                                _transferETH(
                                    distributionAddresses[i],
                                    feeAmount
                                );
                                totalFee += feeAmount;
                            }
                        }
                    }
                } else {
                    if (
                        nftAddressToMarketplace[p.collectionAddress]
                            .rightHolderFlag
                    ) {
                        (
                            uint16[][] memory distributionRates,
                            address[][] memory distributionAddresses,
                            uint256 sumNFTs
                        ) = BundlesInterface(address(p.collectionAddress))
                                .getBundleDistribution(p.tokenId);
                        for (uint i = 0; i < distributionRates.length; i++) {
                            for (
                                uint j = 0;
                                j < distributionRates[i].length;
                                j++
                            ) {
                                if (distributionAddresses[i][j] != address(0)) {
                                    // Transfer fee to fee address
                                    uint256 feeAmount = (((
                                        distributionRates[i][j]
                                    ) * p.price) / sumNFTs) / 100;
                                    _transferETH(
                                        distributionAddresses[i][j],
                                        feeAmount
                                    );
                                    totalFee += feeAmount;
                                }
                            }
                        }
                    }
                }

                uint256 marketplaceFeeAmount = 0;
                // take marketplace fee
                if (
                    nftAddressToMarketplace[p.collectionAddress]
                        .marketplaceFeeFlag
                ) {
                    for (
                        uint i = 0;
                        i <
                        nftAddressToMarketplace[p.collectionAddress]
                            .marketplaceFees
                            .length;
                        i++
                    ) {
                        if (
                            nftAddressToMarketplace[p.collectionAddress]
                                .feeAddresses[i] !=
                            address(0) &&
                            nftAddressToMarketplace[p.collectionAddress]
                                .marketplaceFees[i] !=
                            0
                        ) {
                            uint256 feeAmount = (nftAddressToMarketplace[
                                p.collectionAddress
                            ].marketplaceFees[i] * p.price) / 100;
                            _transferETH(
                                nftAddressToMarketplace[p.collectionAddress]
                                    .feeAddresses[i],
                                feeAmount
                            );
                            marketplaceFeeAmount += feeAmount;
                        }
                    }
                }

                if (p._buyERC721) {
                    //Transfer Native Currency to seller minus fees
                    uint256 amountForSeller = p.price -
                        marketplaceFeeAmount -
                        totalFee -
                        buybackFee;
                    _transferETH(p.seller, amountForSeller);
                } else {
                    //Transfer Native Currency to seller minus fees
                    uint256 amountForSeller = p.price -
                        marketplaceFeeAmount -
                        totalFee -
                        buybackFee;
                    _transferETH(msg.sender, amountForSeller);
                }
                tokensHeld[address(0)] += buybackFee;
            } else {
                if (p._buyERC721) {
                    //Transfer ERC20 to contract
                    require(
                        IERC20(p.payment).transferFrom(
                            msg.sender,
                            address(this),
                            p.price
                        ),
                        "Contract was not allowed to do the transfer"
                    );
                }

                uint256 totalFee = 0;
                if (!isBundleAddress[p.collectionAddress]) {
                    if (
                        nftAddressToMarketplace[p.collectionAddress]
                            .rightHolderFlag
                    ) {
                        (
                            uint16[] memory distributionRates,
                            address[] memory distributionAddresses
                        ) = OpenerMintInterface(p.collectionAddress)
                                .getMarketplaceDistributionForERC721(p.tokenId);
                        for (uint i = 0; i < distributionRates.length; i++) {
                            if (distributionAddresses[i] != address(0)) {
                                // Transfer fee to fee address
                                uint256 feeAmount = (distributionRates[i] *
                                    p.price) / 100;
                                require(
                                    IERC20(p.payment).transfer(
                                        distributionAddresses[i],
                                        feeAmount
                                    ),
                                    "Contract was not allowed to do the transfer"
                                );
                                totalFee += feeAmount;
                            }
                        }
                    }
                } else {
                    if (
                        nftAddressToMarketplace[p.collectionAddress]
                            .rightHolderFlag
                    ) {
                        (
                            uint16[][] memory distributionRates,
                            address[][] memory distributionAddresses,
                            uint256 sumNFTs
                        ) = BundlesInterface(address(p.collectionAddress))
                                .getBundleDistribution(p.tokenId);
                        for (uint i = 0; i < distributionRates.length; i++) {
                            for (
                                uint j = 0;
                                j < distributionRates[i].length;
                                j++
                            ) {
                                if (distributionAddresses[i][j] != address(0)) {
                                    // Transfer fee to fee address
                                    uint256 multiplier = 10000;
                                    // (5 / 10 * 1 / 100) = 0.5 / 100 = 0.005
                                    uint256 feeAmount = (((multiplier *
                                        distributionRates[i][j]) / sumNFTs) *
                                        p.price) /
                                        100 /
                                        multiplier;
                                    require(
                                        IERC20(p.payment).transfer(
                                            distributionAddresses[i][j],
                                            feeAmount
                                        ),
                                        "Contract was not allowed to do the transfer"
                                    );
                                    totalFee += feeAmount;
                                }
                            }
                        }
                    }
                }

                uint256 marketplaceFeeAmount;
                // take marketplace fee
                if (
                    nftAddressToMarketplace[p.collectionAddress]
                        .marketplaceFeeFlag
                ) {
                    // Transfer fee to fee address
                    for (
                        uint i = 0;
                        i <
                        nftAddressToMarketplace[p.collectionAddress]
                            .marketplaceFees
                            .length;
                        i++
                    ) {
                        if (
                            nftAddressToMarketplace[p.collectionAddress]
                                .feeAddresses[i] !=
                            address(0) &&
                            nftAddressToMarketplace[p.collectionAddress]
                                .marketplaceFees[i] !=
                            0
                        ) {
                            uint256 feeAmount = (nftAddressToMarketplace[
                                p.collectionAddress
                            ].marketplaceFees[i] * p.price) / 100;
                            require(
                                IERC20(p.payment).transfer(
                                    nftAddressToMarketplace[p.collectionAddress]
                                        .feeAddresses[i],
                                    feeAmount
                                ),
                                "Contract was not allowed to do the transfer"
                            );
                            marketplaceFeeAmount += feeAmount;
                        }
                    }
                }

                //Transfer ERC20 to owner of nft
                if (p._buyERC721) {
                    uint256 amountForSeller = p.price -
                        marketplaceFeeAmount -
                        totalFee -
                        buybackFee;
                    require(
                        IERC20(p.payment).transfer(p.seller, amountForSeller),
                        "Wasnt able to transfer the ERC20 to the seller"
                    );
                } else {
                    uint256 amountForSeller = p.price -
                        marketplaceFeeAmount -
                        totalFee -
                        buybackFee;
                    require(
                        IERC20(p.payment).transfer(msg.sender, amountForSeller),
                        "Wasnt able to transfer the ERC20 to the seller"
                    );
                }
                tokensHeld[p.payment] += buybackFee;
            }
        }

        //buyback
        if (
            tokensHeld[p.payment] >= minTokensBeforeSwap[p.payment] &&
            buybackEnabled
        ) {
            uint256 newBalance;
            bool success = false; // if payment is eth or if token has liquidity pool

            if (address(p.payment) == address(0)) {
                // if eth was payment
                //do things in eth way
                newBalance = minTokensBeforeSwap[p.payment];
                success = true; // enable flag for buyback
            } else {
                if (address(p.payment) != fevr) {
                    uint256 initialBalance = address(this).balance;

                    // generate the uniswap pair path of token -> weth
                    address[] memory path = new address[](2);
                    path[0] = address(p.payment);
                    path[1] = uniswapV2Router.WETH();

                    IERC20(p.payment).approve(
                        address(uniswapV2Router),
                        minTokensBeforeSwap[p.payment]
                    );

                    // try to swap token for eth (if pool doesnt exist or wrong amount dont revert)
                    try
                        uniswapV2Router
                            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                                minTokensBeforeSwap[p.payment],
                                0, // accept any amount of ETH
                                path,
                                address(this),
                                block.timestamp
                            )
                    {
                        success = true;
                        newBalance = address(this).balance - initialBalance;
                    } catch {
                        success = false;
                    }
                }
            }

            if (success && address(p.payment) != fevr) {
                tokensHeld[p.payment] -= minTokensBeforeSwap[p.payment];
                buyback(newBalance);
                emit Buyback(newBalance);
            }
            if (address(p.payment) == fevr) {
                // if fevr just burn
                IERC20(fevr).transfer(
                    deadAddress,
                    minTokensBeforeSwap[p.payment]
                );
                tokensHeld[p.payment] -= minTokensBeforeSwap[p.payment];
            }
        }
    }

    function _transferETH(address _recipient, uint256 _amount) internal {
        (bool sent, ) = _recipient.call{value: _amount}("");
        require(sent, "Contract was not alloed to do the transfer");
    }

    function _setAcceptableERC20(address _token, bool _isAdd) internal {
        if (_isAdd) {
            require(!acceptableERC20s.contains(_token), "already added");
            acceptableERC20s.add(_token);
        } else {
            require(acceptableERC20s.contains(_token), "already removed");
            acceptableERC20s.remove(_token);
        }
    }

    function _setAcceptableCollection(
        address _collection,
        bool _isAdd
    ) internal {
        if (_isAdd) {
            require(
                !acceptableCollectionAddresses.contains(_collection),
                "already added"
            );
            acceptableCollectionAddresses.add(_collection);
        } else {
            require(
                acceptableCollectionAddresses.contains(_collection),
                "already removed"
            );
            acceptableCollectionAddresses.remove(_collection);
        }
    }
}