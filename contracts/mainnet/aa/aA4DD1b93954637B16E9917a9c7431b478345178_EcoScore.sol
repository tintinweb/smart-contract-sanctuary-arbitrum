// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/EnumerableSetUpgradeable.sol";
import "../../utils/EnumerableMapUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
    using StringsUpgradeable for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSetUpgradeable.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMapUpgradeable.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721Upgradeable.isApprovedForAll(owner, _msgSender()),
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
        return _tokenOwners.contains(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721Upgradeable.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

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
        address owner = ERC721Upgradeable.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721ReceiverUpgradeable(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId); // internal owner
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
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMathUpgradeable.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library CountersUpgradeable {
    using SafeMathUpgradeable for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMapUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
 */
library EnumerableSetUpgradeable {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
        return _tokenOwners.contains(tokenId);
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
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

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
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/INFTOracle.sol";
import "../interfaces/IGNft.sol";

contract NFTOracle is INFTOracle, OwnableUpgradeable {
    using SafeMath for uint256;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 private constant DECIMAL_PRECISION = 10**18;

    /* ========== STATE VARIABLES ========== */
    // key is nft contract address
    mapping(address => NFTPriceFeed) public nftPriceFeed;
    address[] public nftPriceFeedKeys;

    // Maximum deviation allowed between two consecutive oracle prices.
    uint256 public maxPriceDeviation; // 20% 18-digit precision.

    // Maximum allowed deviation between two consecutive oracle prices within a certain time frame
    // 18-bit precision.
    uint256 public maxPriceDeviationWithTime; // 10%
    uint256 public timeIntervalWithPrice; // 30 minutes
    uint256 public minUpdateTime; // 10 minutes

    uint256 public twapInterval;

    address public keeper;

    mapping(address => uint256) public twapPrices;
    mapping(address => bool) public nftPaused;

    /* ========== INITIALIZER ========== */

    function initialize(
        uint256 _maxPriceDeviation,
        uint256 _maxPriceDeviationWithTime,
        uint256 _timeIntervalWithPrice,
        uint256 _minUpdateTime,
        uint256 _twapInterval
    ) external initializer {
        __Ownable_init();

        maxPriceDeviation = _maxPriceDeviation;
        maxPriceDeviationWithTime = _maxPriceDeviationWithTime;
        timeIntervalWithPrice = _timeIntervalWithPrice;
        minUpdateTime = _minUpdateTime;
        twapInterval = _twapInterval;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == owner(), "NFTOracle: caller is not the owner or keeper");
        _;
    }

    modifier onlyExistedKey(address _nftContract) {
        require(nftPriceFeed[_nftContract].registered == true, "NFTOracle: key not existed");
        _;
    }

    modifier whenNotPaused(address _nftContract) {
        require(!nftPaused[_nftContract], "NFTOracle: nft price feed paused");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "NFTOracle: invalid keeper address");
        keeper = _keeper;
        emit KeeperUpdated(_keeper);
    }

    function addAssets(
        address[] calldata _nftContracts
    ) external
    onlyOwner
    {
        for (uint256 i = 0; i < _nftContracts.length; i++) {
            _addAsset(_nftContracts[i]);
        }
    }

    function addAsset(
        address _nftContract
    ) external
    onlyOwner
    {
        _addAsset(_nftContract);
    }

    function removeAsset(
        address _nftContract
    ) external
    onlyOwner
    onlyExistedKey(_nftContract)
    {
        delete nftPriceFeed[_nftContract];

        uint256 length = nftPriceFeedKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (nftPriceFeedKeys[i] == _nftContract) {
                nftPriceFeedKeys[i] = nftPriceFeedKeys[length - 1];
                nftPriceFeedKeys.pop();
                break;
            }
        }

        emit AssetRemoved(_nftContract);
    }

    function setDataValidityParameters(
        uint256 _maxPriceDeviation,
        uint256 _maxPriceDeviationWithTime,
        uint256 _timeIntervalWithPrice,
        uint256 _minUpdateTime
    ) external onlyOwner {
        maxPriceDeviation = _maxPriceDeviation;
        maxPriceDeviationWithTime = _maxPriceDeviationWithTime;
        timeIntervalWithPrice = _timeIntervalWithPrice;
        minUpdateTime = _minUpdateTime;
    }

    function setPause(address _nftContract, bool isPause) external onlyOwner {
        nftPaused[_nftContract] = isPause;
    }

    function setTwapInterval(uint256 _twapInterval) external onlyOwner {
        twapInterval = _twapInterval;
    }

    function setAssetData(
        address _nftContract,
        uint256 _price
    ) external
    onlyKeeper
    whenNotPaused(_nftContract)
    {
        uint256 _timestamp = block.timestamp;
        _setAssetData(_nftContract, _price, _timestamp);
    }

    function setMultipleAssetData(
        address[] calldata _nftContracts,
        uint256[] calldata _prices
    ) external
    onlyKeeper
    {
        require(_nftContracts.length == _prices.length, "NFTOracle: data length not match");
        uint256 _timestamp = block.timestamp;
        for (uint256 i = 0; i < _nftContracts.length; i++) {
            bool _paused = nftPaused[_nftContracts[i]];
            if (!_paused) {
                _setAssetData(_nftContracts[i], _prices[i], _timestamp);
            }
        }
    }

    /* ========== VIEWS ========== */

    function getUnderlyingPrice(address _gNft) external view override returns (uint256) {
        address _nftContract = IGNft(_gNft).underlying();
        uint256 len = getPriceFeedLength(_nftContract);
        require(len > 0, "NFTOracle: no price data");

        uint256 twapPrice = twapPrices[_nftContract];
        if (twapPrice == 0) {
            return nftPriceFeed[_nftContract].nftPriceData[len - 1].price;
        } else {
            return twapPrice;
        }
    }

    function getAssetPrice(address _nftContract) external view override returns (uint256) {
        uint256 len = getPriceFeedLength(_nftContract);
        require(len > 0, "NFTOracle: no price data");

        uint256 twapPrice = twapPrices[_nftContract];
        if (twapPrice == 0) {
            return nftPriceFeed[_nftContract].nftPriceData[len - 1].price;
        } else {
            return twapPrice;
        }
    }

    function getLatestTimestamp(address _nftContract) public view returns (uint256) {
        uint256 len = getPriceFeedLength(_nftContract);
        if (len == 0) {
            return 0;
        }
        return nftPriceFeed[_nftContract].nftPriceData[len - 1].timestamp;
    }

    function getLatestPrice(address _nftContract) public view returns (uint256) {
        uint256 len = getPriceFeedLength(_nftContract);
        if (len == 0) {
            return 0;
        }
        return nftPriceFeed[_nftContract].nftPriceData[len - 1].price;
    }

    function getPreviousPrice(address _nftContract, uint256 _numOfRoundBack) public view returns (uint256) {
        uint256 len = getPriceFeedLength(_nftContract);
        require(len > 0 && _numOfRoundBack < len, "NFTOracle: Not enough history");
        return nftPriceFeed[_nftContract].nftPriceData[len - _numOfRoundBack - 1].price;
    }

    function getPreviousTimestamp(address _nftContract, uint256 _numOfRoundBack) public view returns (uint256) {
        uint256 len = getPriceFeedLength(_nftContract);
        require(len > 0 && _numOfRoundBack < len, "NFTOracle: Not enough history");
        return nftPriceFeed[_nftContract].nftPriceData[len - _numOfRoundBack - 1].timestamp;
    }

    function getPriceFeedLength(address _nftContract) public view returns (uint256) {
        return nftPriceFeed[_nftContract].nftPriceData.length;
    }

    function getLatestRoundId(address _nftContract) external view override returns (uint256) {
        uint256 len = getPriceFeedLength(_nftContract);
        if (len == 0) {
            return 0;
        }
        return nftPriceFeed[_nftContract].nftPriceData[len - 1].roundId;
    }

    function isExistedKey(address _nftContract) public view returns (bool) {
        return nftPriceFeed[_nftContract].registered;
    }

    function nftPriceFeedKeysLength() public view returns (uint256) {
        return nftPriceFeedKeys.length;
    }

    function calculateTwapPrice(address _nftContract) public view returns (uint256) {
        require(nftPriceFeed[_nftContract].registered == true, "NFTOracle: key not existed");
        require(twapInterval != 0, "NFTOracle: interval can't be 0");

        uint256 len = getPriceFeedLength(_nftContract);
        require(len > 0, "NFTOracle: Not Enough history");
        uint256 round = len - 1;
        NFTPriceData memory priceRecord = nftPriceFeed[_nftContract].nftPriceData[round];

        uint256 latestTimestamp = priceRecord.timestamp;
        uint256 baseTimestamp = block.timestamp - twapInterval;

        // if latest updated timestamp is earlier than target timestamp, return the latest price.
        if (latestTimestamp < baseTimestamp || round == 0) {
            return priceRecord.price;
        }

        // rounds are like snapshots, latestRound means the latest price snapshot. follow chainlink naming
        uint256 cumulativeTime = block.timestamp - latestTimestamp;
        uint256 previousTimestamp = latestTimestamp;
        uint256 weightedPrice = priceRecord.price * cumulativeTime;
        while (true) {
            if (round == 0) {
                // if cumulative time less than requested interval, return current twap price
                return weightedPrice / cumulativeTime;
            }

            round = round - 1;
            // get current round timestamp and price
            priceRecord = nftPriceFeed[_nftContract].nftPriceData[round];
            uint256 currentTimestamp = priceRecord.timestamp;
            uint256 price = priceRecord.price;

            // check if current round timestamp is earlier than target timestamp
            if (currentTimestamp <= baseTimestamp) {
                weightedPrice = weightedPrice + (price * (previousTimestamp - baseTimestamp));
                break;
            }

            uint256 timeFraction = previousTimestamp - currentTimestamp;
            weightedPrice = weightedPrice + price * timeFraction;
            cumulativeTime = cumulativeTime + timeFraction;
            previousTimestamp = currentTimestamp;
        }
        return weightedPrice / twapInterval;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _addAsset(
        address _nftContract
    ) private {
        require(nftPriceFeed[_nftContract].registered == false, "NFTOracle: key existed");
        nftPriceFeed[_nftContract].registered = true;
        nftPriceFeedKeys.push(_nftContract);
        emit AssetAdded(_nftContract);
    }

    function _setAssetData(
        address _nftContract,
        uint256 _price,
        uint256 _timestamp
    ) private {
        require(nftPriceFeed[_nftContract].registered == true, "NFTOracle: key not existed");
        require(_timestamp > getLatestTimestamp(_nftContract), "NFTOracle: incorrect timestamp");
        require(_price > 0, "NFTOracle: price can not be 0");

        bool dataValidity = _checkValidityOfPrice(_nftContract, _price, _timestamp);
        require(dataValidity, "NFTOracle: invalid price data");

        uint256 len = getPriceFeedLength(_nftContract);
        NFTPriceData memory data = NFTPriceData({
            price: _price,
            timestamp: _timestamp,
            roundId: len
        });
        nftPriceFeed[_nftContract].nftPriceData.push(data);

        uint256 twapPrice = calculateTwapPrice(_nftContract);
        twapPrices[_nftContract] = twapPrice;

        emit SetAssetData(_nftContract, _price, _timestamp, len);
        emit SetAssetTwapPrice(_nftContract, twapPrice, _timestamp);
    }

    function _checkValidityOfPrice(
        address _nftContract,
        uint256 _price,
        uint256 _timestamp
    ) private view returns (bool) {
        uint256 len = getPriceFeedLength(_nftContract);
        if (len > 0) {
            uint256 price = nftPriceFeed[_nftContract].nftPriceData[len - 1].price;
            if (_price == price) {
                return true;
            }
            uint256 timestamp = nftPriceFeed[_nftContract].nftPriceData[len - 1].timestamp;
            uint256 percentDeviation;
            if (_price > price) {
                percentDeviation = ((_price - price).mul(DECIMAL_PRECISION)).div(price) ;
            } else {
                percentDeviation = ((price - _price)).mul(DECIMAL_PRECISION).div(price);
            }
            uint256 timeDeviation = _timestamp - timestamp;
            if (percentDeviation > maxPriceDeviation) {
                return false;
            } else if (timeDeviation < minUpdateTime) {
                return false;
            } else if ((percentDeviation > maxPriceDeviationWithTime) && (timeDeviation < timeIntervalWithPrice)) {
                return false;
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../library/HomoraMath.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IGToken.sol";

contract PriceCalculator is IPriceCalculator, OwnableUpgradeable {
    using SafeMath for uint256;
    using HomoraMath for uint256;

    // Min price setting interval
    address internal constant ETH = 0x0000000000000000000000000000000000000000;
    uint256 private constant THRESHOLD = 5 minutes;

    /* ========== STATE VARIABLES ========== */

    address public keeper;
    mapping(address => ReferenceData) public references;
    mapping(address => address) private tokenFeeds;

    /* ========== Event ========== */

    event MarketListed(address gToken);
    event MarketEntered(address gToken, address account);
    event MarketExited(address gToken, address account);

    event CloseFactorUpdated(uint256 newCloseFactor);
    event CollateralFactorUpdated(address gToken, uint256 newCollateralFactor);
    event LiquidationIncentiveUpdated(uint256 newLiquidationIncentive);
    event BorrowCapUpdated(address indexed gToken, uint256 newBorrowCap);

    /* ========== MODIFIERS ========== */

    /// @dev `msg.sender` 가 keeper 또는 owner 인지 검증
    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == owner(), "Core: caller is not the owner or keeper");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Keeper address 변경
    /// @dev Keeper address 에서만 요청 가능
    /// @param _keeper New keeper address
    function setKeeper(address _keeper) external onlyKeeper {
        require(_keeper != address(0), "PriceCalculatorBSC: invalid keeper address");
        keeper = _keeper;
    }

    /// @notice Chainlink oracle feed 설정
    /// @param asset Asset address to be used as a key
    /// @param feed Chainlink oracle feed contract address
    function setTokenFeed(address asset, address feed) external onlyKeeper {
        tokenFeeds[asset] = feed;
    }

    /// @notice Set price by keeper
    /// @dev Keeper address 에서만 요청 가능
    /// @param assets Array of asset addresses to set
    /// @param prices Array of asset prices to set
    /// @param timestamp Timstamp of price information
    function setPrices(address[] memory assets, uint256[] memory prices, uint256 timestamp) external onlyKeeper {
        require(
            timestamp <= block.timestamp && block.timestamp.sub(timestamp) <= THRESHOLD,
            "PriceCalculator: invalid timestamp"
        );

        for (uint256 i = 0; i < assets.length; i++) {
            references[assets[i]] = ReferenceData({lastData: prices[i], lastUpdated: block.timestamp});
        }
    }

    /* ========== VIEWS ========== */

    /// @notice View price in USD of asset
    /// @dev `asset` is not a gToken
    /// @param asset Asset address
    function priceOf(address asset) public view override returns (uint256 priceInUSD) {
        if (asset == address(0)) {
            return priceOfETH();
        }
        uint256 decimals = uint256(IBEP20(asset).decimals());
        uint256 unitAmount = 10 ** decimals;
        return _oracleValueInUSDOf(asset, unitAmount, decimals);
    }

    /// @notice View prices in USD of multiple assets
    /// @dev `asset` is not a gToken
    /// @param assets Array of asset addresses
    function pricesOf(address[] memory assets) public view override returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = priceOf(assets[i]);
        }
        return prices;
    }

    /// @notice View underyling token price by gToken
    /// @param gToken gToken address
    function getUnderlyingPrice(address gToken) public view override returns (uint256) {
        return priceOf(IGToken(gToken).underlying());
    }

    /// @notice View underlying token prices by gToken addresses
    /// @param gTokens Array of gToken addresses
    function getUnderlyingPrices(address[] memory gTokens) public view override returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](gTokens.length);
        for (uint256 i = 0; i < gTokens.length; i++) {
            prices[i] = priceOf(IGToken(gTokens[i]).underlying());
        }
        return prices;
    }

    function priceOfETH() public view override returns (uint256 valueInUSD) {
        valueInUSD = 0;
        if (tokenFeeds[ETH] != address(0)) {
            (, int price, , ,) = AggregatorV3Interface(tokenFeeds[ETH]).latestRoundData();
            return uint256(price).mul(1e10);
        } else if (references[ETH].lastUpdated > block.timestamp.sub(1 days)) {
            return references[ETH].lastData;
        } else {
            revert("PriceCalculator: invalid oracle value");
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /// @notice Underlying asset 의 value 를 USD 가치로 환산하여 조회
    /// @dev chainlink token feed 를 이용하고, feed 없으면 references lastData 정보를 이용
    /// @param asset gToken address
    /// @param amount Underlying token amount
    /// @param decimals Underlying token decimals
    function _oracleValueInUSDOf(
        address asset,
        uint256 amount,
        uint256 decimals
    ) private view returns (uint256 valueInUSD) {
        valueInUSD = 0;
        uint256 assetDecimals = asset == address(0) ? 1e18 : 10 ** decimals;
        if (tokenFeeds[asset] != address(0)) {
            (, int256 price, , , ) = AggregatorV3Interface(tokenFeeds[asset]).latestRoundData();
            valueInUSD = uint256(price).mul(1e10).mul(amount).div(assetDecimals);
        } else if (references[asset].lastUpdated > block.timestamp.sub(1 days)) {
            valueInUSD = references[asset].lastData.mul(amount).div(assetDecimals);
        } else {
            revert("PriceCalculator: invalid oracle value");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IPriceProtectionTaxCalculator.sol";
import "../library/SafeToken.sol";

contract PriceProtectionTaxCalculator is IPriceProtectionTaxCalculator, OwnableUpgradeable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address public keeper;
    uint256 public override referencePrice;
    mapping(uint256 => uint256) private grvPrices;
    uint256[] private grvPriceWeight;

    /* ========== MODIFIER ========== */

    modifier onlyKeeper() {
        require(
            msg.sender == keeper || msg.sender == owner(),
            "PriceProtectionTaxCalculator: caller is not the owner or keeper"
        );
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "PriceProtectionTaxCalculator: invalid keeper address");
        keeper = _keeper;

        emit KeeperUpdated(_keeper);
    }

    function setGrvPrice(uint256 _timestamp, uint256 _price) external override onlyKeeper {
        require(_price > 0, "PriceProtectionTaxCalculator: invalid grv price");
        uint256 truncatedTimestamp = startOfDay(_timestamp);
        if (grvPrices[truncatedTimestamp] == 0) {
            grvPrices[truncatedTimestamp] = _price;
        }

        referencePrice = _calculateReferencePrice(truncatedTimestamp);
        emit PriceUpdated(_timestamp, _price);
    }

    function setGrvPriceWeight(uint256[] calldata weights) external override onlyOwner {
        require(weights.length >= 7 && weights.length <= 30, "PriceProtectionTaxCalculator: invalid grv price weight");
        require(weights[0] >= 0 && weights[0] <= 10, "PriceProtectionTaxCalculator: invalid 1st grv price weight");
        require(weights[1] >= 0 && weights[1] <= 10, "PriceProtectionTaxCalculator: invalid 2nd grv price weight");
        require(weights[2] >= 0 && weights[2] <= 10, "PriceProtectionTaxCalculator: invalid 3rd grv price weight");
        require(weights[3] >= 0 && weights[3] <= 10, "PriceProtectionTaxCalculator: invalid 4th grv price weight");
        require(weights[4] >= 0 && weights[4] <= 10, "PriceProtectionTaxCalculator: invalid 5th grv price weight");
        require(weights[5] >= 0 && weights[5] <= 10, "PriceProtectionTaxCalculator: invalid 6th grv price weight");
        require(weights[6] >= 0 && weights[6] <= 10, "PriceProtectionTaxCalculator: invalid 7th grv price weight");

        grvPriceWeight = weights;

        emit GrvPriceWeightUpdated(weights);
    }

    /// @notice ppt tax test를 위한 임시 reference price 설정 함수
    /// @dev test 후 필요에 따라 제거 가능
    /// @param price price value
    function setReferencePrice(uint256 price) public onlyOwner {
        referencePrice = price;
    }

    /* ========== VIEWS ========== */

    function getGrvPrice(uint256 timestamp) external view override returns (uint256) {
        return grvPrices[startOfDay(timestamp)];
    }

    function startOfDay(uint256 timestamp) public pure override returns (uint256) {
        timestamp = ((timestamp.add(1 days) / 1 days) * 1 days);
        timestamp = timestamp.sub(1 days);
        return timestamp;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _calculateReferencePrice(uint256 timestamp) private view returns (uint256) {
        uint256 pastDay = timestamp;
        uint256 totalPrice = 0;
        uint256 count = 0;
        for (uint256 i = 0; i < 7; i++) {
            if (grvPrices[pastDay] > 0 && grvPriceWeight.length > i) {
                uint256 weight = grvPriceWeight[i];
                uint256 weightPrice = grvPrices[pastDay].mul(weight);
                totalPrice = totalPrice.add(weightPrice);
                count += weight;
            }
            pastDay = pastDay.sub(1 days);
        }
        uint256 calculatedReferencePrice = count > 0 ? totalPrice.div(count) : 0;
        return calculatedReferencePrice;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./CoreAdmin.sol";

import "./interfaces/IGToken.sol";
import "./interfaces/IValidator.sol";
import "./interfaces/IPriceCalculator.sol";

contract Core is CoreAdmin {
    using SafeMath for uint256;

    /* ========== CONSTANT VARIABLES ========== */

    address internal constant ETH = 0x0000000000000000000000000000000000000000;

    /* ========== STATE VARIABLES ========== */

    mapping(address => address[]) public marketListOfUsers; // (account => gTokenAddress[])
    mapping(address => mapping(address => bool)) public usersOfMarket; // (gTokenAddress => (account => joined))

    /* ========== INITIALIZER ========== */

    function initialize(address _priceCalculator) external initializer {
        __Core_init();
        priceCalculator = IPriceCalculator(_priceCalculator);
    }

    /* ========== MODIFIERS ========== */

    /// @dev sender 가 해당 gToken 의 Market Enter 되어있는 상태인지 검사
    /// @param gToken 검사할 Market 의 gToken address
    modifier onlyMemberOfMarket(address gToken) {
        require(usersOfMarket[gToken][msg.sender], "Core: must enter market");
        _;
    }

    /// @dev caller 가 market 인지 검사
    modifier onlyMarket() {
        bool fromMarket = false;
        for (uint256 i = 0; i < markets.length; i++) {
            if (msg.sender == markets[i]) {
                fromMarket = true;
                break;
            }
        }
        require(fromMarket == true, "Core: caller should be market");
        _;
    }

    /* ========== VIEWS ========== */

    /// @notice market addresses 조회
    /// @return markets address[]
    function allMarkets() external view override returns (address[] memory) {
        return markets;
    }

    /// @notice gToken 의 marketInfo 조회
    /// @param gToken gToken address
    /// @return Market info
    function marketInfoOf(address gToken) external view override returns (Constant.MarketInfo memory) {
        return marketInfos[gToken];
    }

    /// @notice account 의 market addresses
    /// @param account account address
    /// @return Market addresses of account
    function marketListOf(address account) external view override returns (address[] memory) {
        return marketListOfUsers[account];
    }

    /// @notice account market enter 상태인지 여부 조회
    /// @param account account address
    /// @param gToken gToken address
    /// @return Market enter 여부에 대한 boolean value
    function checkMembership(address account, address gToken) external view override returns (bool) {
        return usersOfMarket[gToken][account];
    }

    /// @notice !TBD
    function accountLiquidityOf(
        address account
    ) external view override returns (uint256 collateralInUSD, uint256 supplyInUSD, uint256 borrowInUSD) {
        return IValidator(validator).getAccountLiquidity(account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice 여러 token 에 대하여 Enter Market 수행
    /// @dev 해당 Token 을 대출하거나, 담보로 enable 하기 위해서는 Enter Market 이 필요함
    /// @param gTokens gToken addresses
    function enterMarkets(address[] memory gTokens) public override {
        for (uint256 i = 0; i < gTokens.length; i++) {
            _enterMarket(payable(gTokens[i]), msg.sender);
        }
    }

    /// @notice 하나의 token 에 대하여 Market Exit 수행
    /// @dev Market 에서 제거할 시에 해당 토큰이 담보물에서 제거되어 청산되지 않음
    /// @param gToken Token address
    function exitMarket(address gToken) external override onlyListedMarket(gToken) onlyMemberOfMarket(gToken) {
        Constant.AccountSnapshot memory snapshot = IGToken(gToken).accruedAccountSnapshot(msg.sender);
        require(snapshot.borrowBalance == 0, "Core: borrow balance must be zero");
        require(IValidator(validator).redeemAllowed(gToken, msg.sender, snapshot.gTokenBalance), "Core: cannot redeem");

        _removeUserMarket(gToken, msg.sender);
        emit MarketExited(gToken, msg.sender);
    }

    /// @notice 담보 제공 트랜잭션
    /// @param gToken 담보 gToken address
    /// @param uAmount 담보 gToken amount
    /// @return gAmount
    function supply(
        address gToken,
        uint256 uAmount
    ) external payable override onlyListedMarket(gToken) nonReentrant whenNotPaused returns (uint256) {
        uAmount = IGToken(gToken).underlying() == address(ETH) ? msg.value : uAmount;
        uint256 supplyCap = marketInfos[gToken].supplyCap;
        require(
            supplyCap == 0 ||
                IGToken(gToken).totalSupply().mul(IGToken(gToken).exchangeRate()).div(1e18).add(uAmount) <= supplyCap,
            "Core: supply cap reached"
        );

        uint256 gAmount = IGToken(gToken).supply{value: msg.value}(msg.sender, uAmount);
        grvDistributor.notifySupplyUpdated(gToken, msg.sender);

        emit MarketSupply(msg.sender, gToken, uAmount);
        return gAmount;
    }

    /// @notice 담보로 제공한 토큰을 전부 Redeem All
    /// @param gToken 담보 gToken address
    /// @param gAmount 담보 gToken redeem amount
    /// @return uAmountRedeem
    function redeemToken(
        address gToken,
        uint256 gAmount
    ) external override onlyListedMarket(gToken) nonReentrant whenNotPaused returns (uint256) {
        uint256 uAmountRedeem = IGToken(gToken).redeemToken(msg.sender, gAmount);
        grvDistributor.notifySupplyUpdated(gToken, msg.sender);

        emit MarketRedeem(msg.sender, gToken, uAmountRedeem);
        return uAmountRedeem;
    }

    /// @notice 담보로 제공한 토큰 중 일부를 Redeem
    /// @param gToken 담보 gToken address
    /// @param uAmount 담보 gToken redeem amount
    /// @return uAmountRedeem
    function redeemUnderlying(
        address gToken,
        uint256 uAmount
    ) external override onlyListedMarket(gToken) nonReentrant whenNotPaused returns (uint256) {
        uint256 uAmountRedeem = IGToken(gToken).redeemUnderlying(msg.sender, uAmount);
        grvDistributor.notifySupplyUpdated(gToken, msg.sender);

        emit MarketRedeem(msg.sender, gToken, uAmountRedeem);
        return uAmountRedeem;
    }

    /// @notice 원하는 자산을 Borrow 하는 트랜잭션
    /// @param gToken 빌리는 gToken address
    /// @param amount 빌리는 underlying token amount
    function borrow(
        address gToken,
        uint256 amount
    ) external override onlyListedMarket(gToken) nonReentrant whenNotPaused {
        _enterMarket(gToken, msg.sender);
        require(IValidator(validator).borrowAllowed(gToken, msg.sender, amount), "Core: cannot borrow");

        IGToken(payable(gToken)).borrow(msg.sender, amount);
        grvDistributor.notifyBorrowUpdated(gToken, msg.sender);
    }

    function nftBorrow(
        address gToken,
        address user,
        uint256 amount
    ) external override onlyListedMarket(gToken) onlyNftCore nonReentrant whenNotPaused {
        require(IGToken(gToken).underlying() == address(ETH), "Core: invalid underlying asset");
        _enterMarket(gToken, msg.sender);
        IGToken(payable(gToken)).borrow(msg.sender, amount);
        grvDistributor.notifyBorrowUpdated(gToken, user);
    }

    /// @notice 대출한 자산을 상환하는 트랜잭션
    /// @dev UI 에서의 Repay All 도 본 트랜잭션을 사용함
    ///      amount 를 넉넉하게 주면 repay 후 초과분은 환불함
    /// @param gToken 상환하려는 gToken address
    /// @param amount 상환하려는 gToken amount
    function repayBorrow(
        address gToken,
        uint256 amount
    ) external payable override onlyListedMarket(gToken) nonReentrant whenNotPaused {
        IGToken(payable(gToken)).repayBorrow{value: msg.value}(msg.sender, amount);
        grvDistributor.notifyBorrowUpdated(gToken, msg.sender);
    }

    function nftRepayBorrow(
        address gToken,
        address user,
        uint256 amount
    ) external payable override onlyListedMarket(gToken) onlyNftCore nonReentrant whenNotPaused {
        require(IGToken(gToken).underlying() == address(ETH), "Core: invalid underlying asset");
        IGToken(payable(gToken)).repayBorrow{value: msg.value}(msg.sender, amount);
        grvDistributor.notifyBorrowUpdated(gToken, user);
    }

    /// @notice 본인이 아닌 특정한 주소의 대출을 청산시키는 트랜잭션
    /// @dev UI 에서 본 트랜잭션 호출을 확인하지 못했음
    /// @param gToken 상환하려는 gToken address
    /// @param amount 상환하려는 gToken amount
    function repayBorrowBehalf(
        address gToken,
        address borrower,
        uint256 amount
    ) external payable override onlyListedMarket(gToken) nonReentrant whenNotPaused {
        IGToken(payable(gToken)).repayBorrowBehalf{value: msg.value}(msg.sender, borrower, amount);
        grvDistributor.notifyBorrowUpdated(gToken, borrower);
    }

    /// @notice 본인이 아닌 특정한 주소의 대출을 청산시키는 트랜잭션
    /// @dev UI 에서 본 트랜잭션 호출을 확인하지 못했음
    function liquidateBorrow(
        address gTokenBorrowed,
        address gTokenCollateral,
        address borrower,
        uint256 amount
    ) external payable override nonReentrant whenNotPaused {
        amount = IGToken(gTokenBorrowed).underlying() == address(ETH) ? msg.value : amount;
        require(marketInfos[gTokenBorrowed].isListed && marketInfos[gTokenCollateral].isListed, "Core: invalid market");
        require(usersOfMarket[gTokenCollateral][borrower], "Core: not a collateral");
        require(marketInfos[gTokenCollateral].collateralFactor > 0, "Core: not a collateral");
        require(
            IValidator(validator).liquidateAllowed(gTokenBorrowed, borrower, amount, closeFactor),
            "Core: cannot liquidate borrow"
        );

        (, uint256 rebateGAmount, uint256 liquidatorGAmount) = IGToken(gTokenBorrowed).liquidateBorrow{
            value: msg.value
        }(gTokenCollateral, msg.sender, borrower, amount);

        IGToken(gTokenCollateral).seize(msg.sender, borrower, liquidatorGAmount);
        grvDistributor.notifyTransferred(gTokenCollateral, borrower, msg.sender);

        if (rebateGAmount > 0) {
            IGToken(gTokenCollateral).seize(rebateDistributor, borrower, rebateGAmount);
            grvDistributor.notifyTransferred(gTokenCollateral, borrower, rebateDistributor);
        }

        grvDistributor.notifyBorrowUpdated(gTokenBorrowed, borrower);

        IRebateDistributor(rebateDistributor).addRebateAmount(
            gTokenCollateral,
            rebateGAmount.mul(IGToken(gTokenCollateral).accruedExchangeRate()).div(1e18)
        );
    }

    /// @notice 모든 마켓의 Reward GRV 클레임 트랜잭션
    function claimGRV() external override nonReentrant {
        grvDistributor.claimGRV(markets, msg.sender);
    }

    /// @notice 하나의 market 의 Reward GRV 클레임 트랜잭션
    /// @param market 클레임 하는 market 의 address
    function claimGRV(address market) external override nonReentrant {
        address[] memory _markets = new address[](1);
        _markets[0] = market;
        grvDistributor.claimGRV(_markets, msg.sender);
    }

    /// @notice 모든 마켓의 Reward GRV 재락업 트랜잭션
    function compoundGRV() external override {
        grvDistributor.compound(markets, msg.sender);
    }

    /// @notice 모든 마켓의 Reward GRV 재락업 트랜잭션
    function firstDepositGRV(uint256 expiry) external override {
        grvDistributor.firstDeposit(markets, msg.sender, expiry);
    }

    /// @notice Called when gToken has transfered
    /// @dev gToken 에서 grvDistributor 의 메서드를 호출하기 위해 중간 역할을 함
    ///      gToken -> Core -> gToken, grvDistributor
    function transferTokens(
        address spender,
        address src,
        address dst,
        uint256 amount
    ) external override nonReentrant onlyMarket {
        IGToken(msg.sender).transferTokensInternal(spender, src, dst, amount);
        grvDistributor.notifyTransferred(msg.sender, src, dst);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /// @notice Enter Market
    /// @dev 해당 Token 을 대출하거나, 담보로 enable 하기 위해서는 Enter Market 이 필요함
    /// @param gToken Token address
    /// @param _account Market 에 Enter 할 account address
    function _enterMarket(address gToken, address _account) internal onlyListedMarket(gToken) {
        if (!usersOfMarket[gToken][_account]) {
            usersOfMarket[gToken][_account] = true;
            marketListOfUsers[_account].push(gToken);
            emit MarketEntered(gToken, _account);
        }
    }

    /// @notice remove user from market
    /// @dev Market 에서 제거할 시에 해당 토큰이 담보물에서 제거되어 청산되지 않음
    /// @param gTokenToExit Token address
    /// @param _account Market 에 제거할 account address
    function _removeUserMarket(address gTokenToExit, address _account) private {
        require(marketListOfUsers[_account].length > 0, "Core: cannot pop user market");
        delete usersOfMarket[gTokenToExit][_account];

        uint256 length = marketListOfUsers[_account].length;
        for (uint256 i = 0; i < length; i++) {
            if (marketListOfUsers[_account][i] == gTokenToExit) {
                marketListOfUsers[_account][i] = marketListOfUsers[_account][length - 1];
                marketListOfUsers[_account].pop();
                break;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "./library/Constant.sol";

import "./interfaces/ICore.sol";
import "./interfaces/IGRVDistributor.sol";
import "./interfaces/IPriceCalculator.sol";
import "./interfaces/IGToken.sol";
import "./interfaces/IRebateDistributor.sol";

abstract contract CoreAdmin is ICore, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    /* ========== STATE VARIABLES ========== */

    address public keeper;
    address public override nftCore;
    address public override validator;
    address public override rebateDistributor;
    IGRVDistributor public grvDistributor;
    IPriceCalculator public priceCalculator;

    address[] public markets; // gTokenAddress[]
    mapping(address => Constant.MarketInfo) public marketInfos; // (gTokenAddress => MarketInfo)

    uint256 public override closeFactor;
    uint256 public override liquidationIncentive;

    /* ========== VARIABLE GAP ========== */

    uint256[49] private __gap;

    /* ========== MODIFIERS ========== */

    /// @dev sender 가 keeper address 인지 검증
    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == owner(), "Core: caller is not the owner or keeper");
        _;
    }

    /// @dev Market 에 list 된 gToken address 인지 검증
    /// @param gToken gToken address
    modifier onlyListedMarket(address gToken) {
        require(marketInfos[gToken].isListed, "Core: invalid market");
        _;
    }

    modifier onlyNftCore() {
        require(msg.sender == nftCore, "Core: caller is not the nft core");
        _;
    }

    /* ========== INITIALIZER ========== */

    function __Core_init() internal initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        closeFactor = 5e17; // 0.5
        liquidationIncentive = 115e16; // 1.15
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice keeper address 변경
    /// @dev keeper address 에서만 요청 가능
    /// @param _keeper 새로운 keeper address
    function setKeeper(address _keeper) external onlyKeeper {
        require(_keeper != address(0), "Core: invalid keeper address");
        keeper = _keeper;
        emit KeeperUpdated(_keeper);
    }

    function setNftCore(address _nftCore) external onlyKeeper {
        require(_nftCore != address(0), "Core: invalid nft core address");
        nftCore = _nftCore;
        emit NftCoreUpdated(_nftCore);
    }

    /// @notice validator 변경
    /// @dev keeper address 에서만 요청 가능
    /// @param _validator 새로운 validator address
    function setValidator(address _validator) external onlyKeeper {
        require(_validator != address(0), "Core: invalid validator address");
        validator = _validator;
        emit ValidatorUpdated(_validator);
    }

    /// @notice grvDistributor 변경
    /// @dev keeper address 에서만 요청 가능
    /// @param _grvDistributor 새로운 grvDistributor address
    function setGRVDistributor(address _grvDistributor) external onlyKeeper {
        require(_grvDistributor != address(0), "Core: invalid grvDistributor address");
        grvDistributor = IGRVDistributor(_grvDistributor);
        emit GRVDistributorUpdated(_grvDistributor);
    }

    function setRebateDistributor(address _rebateDistributor) external onlyKeeper {
        require(_rebateDistributor != address(0), "Core: invalid rebateDistributor address");
        rebateDistributor = _rebateDistributor;
        emit RebateDistributorUpdated(_rebateDistributor);
    }

    /// @notice close factor 변경
    /// @dev keeper address 에서만 요청 가능
    /// @param newCloseFactor 새로운 close factor 값 (TBD)
    function setCloseFactor(uint256 newCloseFactor) external onlyKeeper {
        require(
            newCloseFactor >= Constant.CLOSE_FACTOR_MIN && newCloseFactor <= Constant.CLOSE_FACTOR_MAX,
            "Core: invalid close factor"
        );
        closeFactor = newCloseFactor;
        emit CloseFactorUpdated(newCloseFactor);
    }

    /// @notice Market collateral factor (담보 인정 비율) 변경
    /// @dev keeper address 에서만 요청 가능
    /// @param gToken gToken address
    /// @param newCollateralFactor collateral factor (담보 인정 비율)
    function setCollateralFactor(
        address gToken,
        uint256 newCollateralFactor
    ) external onlyKeeper onlyListedMarket(gToken) {
        require(newCollateralFactor <= Constant.COLLATERAL_FACTOR_MAX, "Core: invalid collateral factor");
        if (newCollateralFactor != 0 && priceCalculator.getUnderlyingPrice(gToken) == 0) {
            revert("Core: invalid underlying price");
        }

        marketInfos[gToken].collateralFactor = newCollateralFactor;
        emit CollateralFactorUpdated(gToken, newCollateralFactor);
    }

    /// @notice 청산 인센티브 설정
    /// @dev keeper address 에서만 요청 가능
    /// @param newLiquidationIncentive 새로운 청산 인센티브 값 (TBD)
    function setLiquidationIncentive(uint256 newLiquidationIncentive) external onlyKeeper {
        liquidationIncentive = newLiquidationIncentive;
        emit LiquidationIncentiveUpdated(newLiquidationIncentive);
    }

    /// @notice Market supply cap 변경
    /// @dev keeper address 에서만 요청 가능
    /// @param gTokens gToken addresses
    /// @param newSupplyCaps new supply caps in array
    function setMarketSupplyCaps(address[] calldata gTokens, uint256[] calldata newSupplyCaps) external onlyKeeper {
        require(gTokens.length != 0 && gTokens.length == newSupplyCaps.length, "Core: invalid data");

        for (uint256 i = 0; i < gTokens.length; i++) {
            marketInfos[gTokens[i]].supplyCap = newSupplyCaps[i];
            emit SupplyCapUpdated(gTokens[i], newSupplyCaps[i]);
        }
    }

    /// @notice Market borrow cap 변경
    /// @dev keeper address 에서만 요청 가능
    /// @param gTokens gToken addresses
    /// @param newBorrowCaps new borrow caps in array
    function setMarketBorrowCaps(address[] calldata gTokens, uint256[] calldata newBorrowCaps) external onlyKeeper {
        require(gTokens.length != 0 && gTokens.length == newBorrowCaps.length, "Core: invalid data");

        for (uint256 i = 0; i < gTokens.length; i++) {
            marketInfos[gTokens[i]].borrowCap = newBorrowCaps[i];
            emit BorrowCapUpdated(gTokens[i], newBorrowCaps[i]);
        }
    }

    /// @notice Market 추가
    /// @dev keeper address 에서만 요청 가능
    /// @param gToken gToken address
    /// @param supplyCap supply cap
    /// @param borrowCap borrow cap
    /// @param collateralFactor collateral factor (담보 인정 비율)
    function listMarket(
        address payable gToken,
        uint256 supplyCap,
        uint256 borrowCap,
        uint256 collateralFactor
    ) external onlyKeeper {
        require(!marketInfos[gToken].isListed, "Core: already listed market");
        for (uint256 i = 0; i < markets.length; i++) {
            require(markets[i] != gToken, "Core: already listed market");
        }

        marketInfos[gToken] = Constant.MarketInfo({
            isListed: true,
            supplyCap: supplyCap,
            borrowCap: borrowCap,
            collateralFactor: collateralFactor
        });
        markets.push(gToken);
        emit MarketListed(gToken);
    }

    /// @notice Market 제거
    /// @dev keeper address 에서만 요청 가능
    /// @param gToken gToken address
    function removeMarket(address payable gToken) external onlyKeeper {
        require(marketInfos[gToken].isListed, "Core: unlisted market");
        require(IGToken(gToken).totalSupply() == 0 && IGToken(gToken).totalBorrow() == 0, "Core: cannot remove market");

        uint256 length = markets.length;
        for (uint256 i = 0; i < length; i++) {
            if (markets[i] == gToken) {
                markets[i] = markets[length - 1];
                markets.pop();
                delete marketInfos[gToken];
                break;
            }
        }
    }

    function pause() external onlyKeeper {
        _pause();
    }

    function unpause() external onlyKeeper {
        _unpause();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IGToken.sol";
import "../interfaces/ICore.sol";
import "../interfaces/IDashboard.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IGRVDistributor.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IEcoScore.sol";
import "../interfaces/IWhiteholePair.sol";
import "../interfaces/IRebateDistributor.sol";
import "../interfaces/ILendPoolLoan.sol";

contract Dashboard is IDashboard, OwnableUpgradeable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ICore public core;
    ILocker public locker;
    IGRVDistributor public grvDistributor;
    IEcoScore public ecoScore;
    IWhiteholePair public pairContract;
    IRebateDistributor public rebateDistributor;
    ILendPoolLoan public lendPoolLoan;

    address public GRV;
    address public marketingTreasury;
    address public reserveTreasury;
    address public devTeamTreasury;
    address public taxTreasury;
    address public grvPresale;
    address public rankerRewardDistributor;
    address public swapFeeTreasury;
    address public lpVault;

    bool public isGenesis;

    /* ========== INITIALIZER ========== */

    function initialize(
        address _grvTokenAddress,
        address _core,
        address _locker,
        address _grvDistributor,
        address _ecoScore,
        address _pairContract,
        address _rebateDistributor,
        address _reserveTreasury,
        address _swapFeeTreasury,
        address _devTeamTreasury,
        address _marketingTreasury,
        address _taxTreasury
    ) external initializer {
        __Ownable_init();

        GRV = _grvTokenAddress;
        core = ICore(_core);
        locker = ILocker(_locker);
        grvDistributor = IGRVDistributor(_grvDistributor);
        ecoScore = IEcoScore(_ecoScore);
        pairContract = IWhiteholePair(_pairContract);
        rebateDistributor = IRebateDistributor(_rebateDistributor);
        reserveTreasury = _reserveTreasury;
        swapFeeTreasury = _swapFeeTreasury;
        devTeamTreasury = _devTeamTreasury;
        marketingTreasury = _marketingTreasury;
        taxTreasury = _taxTreasury;
        isGenesis = true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setGrvPresale(address _grvPresale) external onlyOwner {
        require(_grvPresale != address(0), "Dashboard: invalid grvPresale address");
        grvPresale = _grvPresale;
    }

    function setLpVault(address _lpVault) external onlyOwner {
        require(_lpVault != address(0), "Dashboard: invalid lpvault address");
        lpVault = _lpVault;
    }

    function setRankerRewardDistributor(address _rankerRewardDistributor) external onlyOwner {
        require(_rankerRewardDistributor != address(0), "Dashboard: invalid rankerRewardDistributor");
        rankerRewardDistributor = _rankerRewardDistributor;
    }

    function setLendPoolLoan(address _lendPoolLoan) external onlyOwner {
        require(_lendPoolLoan != address(0), "Dashboard: invalid lendPoolLoan address");
        lendPoolLoan = ILendPoolLoan(_lendPoolLoan);
    }

    function setIsGenesis(bool _isGenesis) external onlyOwner {
        isGenesis = _isGenesis;
    }

    /* ========== VIEWS ========== */

    function totalCirculating() public view returns (uint256) {
        return
            IBEP20(GRV)
            .totalSupply()
            .sub(IBEP20(GRV).balanceOf(marketingTreasury)) // marketing Treasury
            .sub(IBEP20(GRV).balanceOf(devTeamTreasury)) // dev team Treasury
            .sub(IBEP20(GRV).balanceOf(reserveTreasury)) // reserve Treasury
            .sub(locker.totalBalance()) // Locker
            .sub(IBEP20(GRV).balanceOf(address(pairContract))) // GRV-USDC pair contract
            .sub(IBEP20(GRV).balanceOf(address(grvDistributor))) // grv distributor
            .sub(IBEP20(GRV).balanceOf(taxTreasury)) // tax treasury
            .sub(IBEP20(GRV).balanceOf(grvPresale)) // grv presale
            .sub(IBEP20(GRV).balanceOf(rankerRewardDistributor)) // ranker reward distributor
            .sub(IBEP20(GRV).balanceOf(swapFeeTreasury)) // swap fee treasury
            .sub(IBEP20(GRV).balanceOf(lpVault)); // lp vault
    }

    function vaultDashboardInfo()
        public
        view
        returns (
            uint256 totalCirculation,
            uint256 totalLockedGrv,
            uint256 totalVeGrv,
            uint256 averageLockDuration,
            uint256[] memory thisWeekRebatePoolAmounts,
            address[] memory thisWeekRebatePoolMarkets,
            uint256 thisWeekRebatePoolValue
        )
    {
        totalCirculation = totalCirculating();
        totalLockedGrv = locker.totalBalance();
        (totalVeGrv, ) = locker.totalScore();
        averageLockDuration = totalLockedGrv > 0 ? locker.getLockUnitMax().mul(totalVeGrv).div(totalLockedGrv) : 0;
        (uint256[] memory rebates, address[] memory markets, uint256 value, ) = rebateDistributor.thisWeekRebatePool();
        thisWeekRebatePoolAmounts = rebates;
        thisWeekRebatePoolMarkets = markets;
        thisWeekRebatePoolValue = value;
    }

    function ecoScoreInfo(
        address account
    ) public view returns (Constant.EcoZone ecoZone, uint256 claimTax, uint256 ppt, uint256 ecoDR) {
        Constant.EcoScoreInfo memory userEcoInfo = ecoScore.accountEcoScoreInfoOf(account);
        Constant.EcoPolicyInfo memory ecoTaxInfo = ecoScore.ecoPolicyInfoOf(userEcoInfo.ecoZone);
        (uint256 pptTaxRate, ) = ecoScore.getPptTaxRate(userEcoInfo.ecoZone);
        ecoZone = userEcoInfo.ecoZone;
        claimTax = ecoTaxInfo.claimTax;
        ppt = pptTaxRate;
        ecoDR = userEcoInfo.ecoDR;
    }

    function userLockedGrvInfo(
        address account
    ) public view returns (uint256 lockedBalance, uint256 lockDuration, uint256 firstLockTime) {
        lockedBalance = locker.balanceOf(account);
        lockDuration = locker.expiryOf(account);
        firstLockTime = locker.firstLockTimeInfoOf(account);
    }

    function userVeGrvInfo(address account) public view returns (uint256 veGrv, uint256 vp) {
        veGrv = locker.scoreOf(account);
        (uint256 totalScore, ) = locker.totalScore();
        vp = totalScore > 0 ? veGrv.mul(1e18).div(totalScore) : 0;
    }

    function userRebateInfo(address account) public view returns (RebateData memory) {
        RebateData memory rebateData;
        rebateData.weeklyProfit = rebateDistributor.weeklyProfitOf(account);
        (uint256[] memory rebates, address[] memory markets, , uint256 value) = rebateDistributor.accuredRebates(
            account
        );
        rebateData.unClaimedRebateValue = value;
        rebateData.unClaimedMarkets = markets;
        rebateData.unClaimedRebatesAmount = rebates;
        (uint256[] memory claimedRebates, address[] memory claimedMarkets, uint256 claimed) = rebateDistributor
            .totalClaimedRebates(account);
        rebateData.claimedRebateValue = claimed;
        rebateData.claimedMarkets = claimedMarkets;
        rebateData.claimedRebatesAmount = claimedRebates;

        return rebateData;
    }

    function expectedVeGrvInfo(
        address account,
        uint256 amountOfGrv,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    )
        public
        view
        returns (uint256 expectedVeGrv, uint256 expectedVp, uint256 expectedWeeklyProfit, uint256 currentWeeklyProfit)
    {
        expectedVeGrv = locker.preScoreOf(account, amountOfGrv, expiry, option);
        uint256 veGrv = locker.scoreOf(account);
        uint256 incrementVeGrv = expectedVeGrv > veGrv ? expectedVeGrv.sub(veGrv) : 0;
        (uint256 totalScore, ) = locker.totalScore();
        uint256 expectedTotalScore = totalScore.add(incrementVeGrv);

        expectedVp = expectedTotalScore > 0 ? expectedVeGrv.mul(1e18).div(expectedTotalScore) : 0;
        expectedVp = Math.min(expectedVp, 1e18);
        expectedWeeklyProfit = rebateDistributor.weeklyProfitOfVP(expectedVp);
        currentWeeklyProfit = rebateDistributor.weeklyProfitOf(account);
    }

    /// @notice GRV의 현재가 반환
    function getCurrentGRVPrice() external view override returns (uint256) {
        if (isGenesis) {
            return 3e16;
        } else {
            address token0 = pairContract.token0();
            (uint256 reserve0, uint256 reserve1, ) = pairContract.getReserves();
            uint256 price = 0;
            if (token0 == GRV) {
                price = reserve0 > 0 ? reserve1.mul(1e12).mul(1e18).div(reserve0) : 0;
            } else {
                price = reserve1 > 0 ? reserve0.mul(1e12).mul(1e18).div(reserve1) : 0;
            }
            return price;
        }
    }

    function getVaultInfo(address account) external view override returns (VaultData memory) {
        VaultData memory vaultData;
        {
            (
                uint256 totalCirculation,
                uint256 totalLockedGrv,
                uint256 totalVeGrv,
                uint256 averageLockDuration,
                uint256[] memory thisWeekRebatePoolAmounts,
                address[] memory thisWeekRebatePoolMarkets,
                uint256 thisWeekRebatePoolValue
            ) = vaultDashboardInfo();
            vaultData.totalCirculation = totalCirculation;
            vaultData.totalLockedGrv = totalLockedGrv;
            vaultData.totalVeGrv = totalVeGrv;
            vaultData.averageLockDuration = averageLockDuration;
            vaultData.thisWeekRebatePoolAmounts = thisWeekRebatePoolAmounts;
            vaultData.thisWeekRebatePoolMarkets = thisWeekRebatePoolMarkets;
            vaultData.thisWeekRebatePoolValue = thisWeekRebatePoolValue;
        }
        {
            uint256 accruedGrv = grvDistributor.accruedGRV(core.allMarkets(), account);
            uint256 claimedGrv = (ecoScore.accountEcoScoreInfoOf(account)).claimedGrv;
            vaultData.accruedGrv = accruedGrv;
            vaultData.claimedGrv = claimedGrv;
        }
        {
            (Constant.EcoZone ecoZone, uint256 claimTax, uint256 ppt, uint256 ecoDR) = ecoScoreInfo(account);
            vaultData.ecoZone = ecoZone;
            vaultData.claimTax = claimTax;
            vaultData.ppt = ppt;
            vaultData.ecoDR = ecoDR;
        }
        {
            (uint256 lockedBalance, uint256 lockDuration, uint256 firstLockTime) = userLockedGrvInfo(
                account
            );
            vaultData.lockedBalance = lockedBalance;
            vaultData.lockDuration = lockDuration;
            vaultData.firstLockTime = firstLockTime;
        }
        {
            (uint256 veGrv, uint256 vp) = userVeGrvInfo(account);
            RebateData memory rebateData = userRebateInfo(account);
            vaultData.myVeGrv = veGrv;
            vaultData.vp = vp;
            vaultData.rebateData = rebateData;
        }

        return vaultData;
    }

    function getLockUnclaimedGrvModalInfo(address account) external view override returns (CompoundData memory) {
        require(locker.balanceOf(account) > 0, "Dashboard: getLockUnclaimedGrvModalInfo: User has not locked");
        CompoundData memory compoundData;
        uint256 accruedGrv = grvDistributor.accruedGRV(core.allMarkets(), account);
        uint256 expiry = locker.expiryOf(account);
        (uint256 adjustedValue, ) = ecoScore.calculateCompoundTaxes(
            account,
            accruedGrv,
            expiry,
            Constant.EcoScorePreviewOption.LOCK_MORE
        );
        {
            compoundData.accruedGrv = accruedGrv;
            compoundData.lockDuration = expiry;
        }
        {
            compoundData.taxData.prevClaimTaxRate = ecoScore
                .ecoPolicyInfoOf(ecoScore.accountEcoScoreInfoOf(account).ecoZone)
                .claimTax;
            compoundData.taxData.nextClaimTaxRate = ecoScore.getClaimTaxRate(
                account,
                accruedGrv,
                expiry,
                Constant.EcoScorePreviewOption.LOCK_MORE
            );
            compoundData.taxData.discountTaxRate = ecoScore.getDiscountTaxRate(account);
            compoundData.taxData.afterTaxesGrv = adjustedValue;
        }
        {
            Constant.EcoScoreInfo memory userEcoScoreInfo = ecoScore.accountEcoScoreInfoOf(account);
            (Constant.EcoZone ecoZone, uint256 ecoDR, ) = ecoScore.calculatePreUserEcoScoreInfo(
                account,
                adjustedValue,
                expiry,
                Constant.EcoScorePreviewOption.LOCK_MORE
            );
            (uint256 pptTaxRate, ) = ecoScore.getPptTaxRate(userEcoScoreInfo.ecoZone);

            compoundData.ecoScoreData.prevEcoDR = userEcoScoreInfo.ecoDR;
            compoundData.ecoScoreData.prevEcoZone = userEcoScoreInfo.ecoZone;
            compoundData.ecoScoreData.nextEcoDR = ecoDR;
            compoundData.ecoScoreData.nextEcoZone = ecoZone;

            compoundData.taxData.prevPPTRate = pptTaxRate;
            if (userEcoScoreInfo.ecoZone == ecoZone) {
                compoundData.taxData.nextPPTRate = pptTaxRate;
            } else {
                (uint256 nextPptTaxRate, ) = ecoScore.getPptTaxRate(ecoZone);
                compoundData.taxData.nextPPTRate = nextPptTaxRate;
            }
        }
        {
            (
                uint256 expectedVeGrv,
                uint256 expectedVp,
                uint256 expectedWeeklyProfit,
                uint256 currentWeeklyProfit
            ) = expectedVeGrvInfo(account, adjustedValue, expiry, Constant.EcoScorePreviewOption.LOCK_MORE);
            (uint256 veGrv, uint256 vp) = userVeGrvInfo(account);
            compoundData.veGrvData.prevVeGrv = veGrv;
            compoundData.veGrvData.prevVotingPower = vp;
            compoundData.veGrvData.nextVeGrv = expectedVeGrv;
            compoundData.veGrvData.nextVotingPower = expectedVp;
            compoundData.veGrvData.nextWeeklyRebate = expectedWeeklyProfit;
            compoundData.veGrvData.prevWeeklyRebate = currentWeeklyProfit;
        }
        {
            BoostedAprParams memory data;
            data.account = account;
            data.amount = adjustedValue;
            data.expiry = expiry;
            data.option = Constant.EcoScorePreviewOption.LOCK_MORE;
            BoostedAprData memory aprData = getBoostedApr(data);
            compoundData.boostedAprData = aprData;
        }
        return compoundData;
    }

    function getInitialLockUnclaimedGrvModalInfo(
        address account,
        uint256 expiry
    ) external view override returns (CompoundData memory) {
        require(locker.balanceOf(account) == 0, "Dashboard: getInitialLockUnclaimedGrvModalInfo: User already locked");
        CompoundData memory compoundData;
        uint256 accruedGrv = grvDistributor.accruedGRV(core.allMarkets(), account);
        (uint256 adjustedValue, ) = ecoScore.calculateCompoundTaxes(
            account,
            accruedGrv,
            expiry,
            Constant.EcoScorePreviewOption.LOCK
        );
        {
            uint256 truncatedExpiryOfUser = locker.truncateExpiry(expiry);
            compoundData.accruedGrv = accruedGrv;
            compoundData.nextLockDuration = truncatedExpiryOfUser;
        }
        {
            compoundData.taxData.prevClaimTaxRate = ecoScore
                .ecoPolicyInfoOf(ecoScore.accountEcoScoreInfoOf(account).ecoZone)
                .claimTax;
            compoundData.taxData.nextClaimTaxRate = ecoScore.getClaimTaxRate(
                account,
                accruedGrv,
                expiry,
                Constant.EcoScorePreviewOption.LOCK
            );
            compoundData.taxData.discountTaxRate = ecoScore.getDiscountTaxRate(account);
            compoundData.taxData.afterTaxesGrv = adjustedValue;
        }
        {
            Constant.EcoScoreInfo memory userEcoScoreInfo = ecoScore.accountEcoScoreInfoOf(account);
            (Constant.EcoZone ecoZone, uint256 ecoDR, ) = ecoScore.calculatePreUserEcoScoreInfo(
                account,
                adjustedValue,
                expiry,
                Constant.EcoScorePreviewOption.LOCK
            );
            (uint256 pptTaxRate, ) = ecoScore.getPptTaxRate(userEcoScoreInfo.ecoZone);

            compoundData.ecoScoreData.prevEcoDR = userEcoScoreInfo.ecoDR;
            compoundData.ecoScoreData.prevEcoZone = userEcoScoreInfo.ecoZone;
            compoundData.ecoScoreData.nextEcoDR = ecoDR;
            compoundData.ecoScoreData.nextEcoZone = ecoZone;

            compoundData.taxData.prevPPTRate = pptTaxRate;
            if (userEcoScoreInfo.ecoZone == ecoZone) {
                compoundData.taxData.nextPPTRate = pptTaxRate;
            } else {
                (uint256 nextPptTaxRate, ) = ecoScore.getPptTaxRate(ecoZone);
                compoundData.taxData.nextPPTRate = nextPptTaxRate;
            }
        }
        {
            (
                uint256 expectedVeGrv,
                uint256 expectedVp,
                uint256 expectedWeeklyProfit,
                uint256 currentWeeklyProfit
            ) = expectedVeGrvInfo(account, adjustedValue, expiry, Constant.EcoScorePreviewOption.LOCK);
            (uint256 veGrv, uint256 vp) = userVeGrvInfo(account);
            compoundData.veGrvData.prevVeGrv = veGrv;
            compoundData.veGrvData.prevVotingPower = vp;
            compoundData.veGrvData.nextVeGrv = expectedVeGrv;
            compoundData.veGrvData.nextVotingPower = expectedVp;
            compoundData.veGrvData.nextWeeklyRebate = expectedWeeklyProfit;
            compoundData.veGrvData.prevWeeklyRebate = currentWeeklyProfit;
        }
        {
            BoostedAprParams memory data;
            data.account = account;
            data.amount = adjustedValue;
            data.expiry = expiry;
            data.option = Constant.EcoScorePreviewOption.LOCK;
            BoostedAprData memory aprData = getBoostedApr(data);
            compoundData.boostedAprData = aprData;
        }
        return compoundData;
    }

    /// @notice Lock, Lock more, Extend 모달 데이터
    /// @param account user address
    /// @param amount input grv amount
    /// @param expiry input expiry
    /// @param option Lock, Lock More, Extend
    function getLockModalInfo(
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view override returns (LockData memory) {
        uint256 expiryOfUser = locker.expiryOf(account);
        uint256 truncatedExpiryOfUser = expiry > 0 ? locker.truncateExpiry(expiry) : 0;
        if (expiry == 0 && option == Constant.EcoScorePreviewOption.LOCK_MORE) {
            expiry = expiryOfUser;
            truncatedExpiryOfUser = expiryOfUser;
        }
        if (option == Constant.EcoScorePreviewOption.EXTEND) {
            if (amount == 0) {
                amount = locker.balanceOf(account);
            }
            if (expiry == 0) {
                expiry = expiryOfUser;
                truncatedExpiryOfUser = expiryOfUser;
            }
        }
        LockData memory lockData;
        {
            (Constant.EcoZone ecoZone, uint256 ecoDR, ) = ecoScore.calculatePreUserEcoScoreInfo(
                account,
                amount,
                expiry,
                option
            );
            Constant.EcoScoreInfo memory ecoScoreInfoData = ecoScore.accountEcoScoreInfoOf(account);
            lockData.ecoScoreData.prevEcoDR = ecoScoreInfoData.ecoDR;
            lockData.ecoScoreData.prevEcoZone = ecoScoreInfoData.ecoZone;
            lockData.ecoScoreData.nextEcoDR = ecoDR;
            lockData.ecoScoreData.nextEcoZone = ecoZone;
        }
        {
            (
                uint256 expectedVeGrv,
                uint256 expectedVp,
                uint256 expectedWeeklyProfit,
                uint256 currentWeeklyProfit
            ) = expectedVeGrvInfo(account, amount, expiry, option);
            (uint256 veGrv, uint256 vp) = userVeGrvInfo(account);

            lockData.veGrvData.prevVeGrv = veGrv;
            lockData.veGrvData.prevVotingPower = vp;
            lockData.veGrvData.nextVeGrv = expectedVeGrv;
            lockData.veGrvData.nextVotingPower = expectedVp;
            lockData.veGrvData.nextWeeklyRebate = expectedWeeklyProfit;
            lockData.veGrvData.prevWeeklyRebate = currentWeeklyProfit;
        }
        {
            BoostedAprParams memory data;
            data.account = account;
            data.amount = amount;
            data.expiry = expiry;
            data.option = option;
            BoostedAprData memory aprData = getBoostedApr(data);
            lockData.boostedAprData = aprData;
        }
        {
            lockData.lockDuration = expiryOfUser;
            lockData.nextLockDuration = truncatedExpiryOfUser;
            lockData.lockedGrv = locker.balanceOf(account);
        }
        return lockData;
    }

    function getClaimModalInfo(address account) external view override returns (ClaimData memory) {
        ClaimData memory claimData;
        uint256 accruedGrv = grvDistributor.accruedGRV(core.allMarkets(), account);
        {
            (Constant.EcoZone ecoZone, uint256 ecoDR, ) = ecoScore.calculatePreUserEcoScoreInfo(
                account,
                accruedGrv,
                0,
                Constant.EcoScorePreviewOption.CLAIM
            );
            Constant.EcoScoreInfo memory ecoScoreInfoData = ecoScore.accountEcoScoreInfoOf(account);
            (uint256 pptTaxRate, ) = ecoScore.getPptTaxRate(ecoScoreInfoData.ecoZone);

            claimData.taxData.prevPPTRate = pptTaxRate;
            if (ecoScoreInfoData.ecoZone == ecoZone) {
                claimData.taxData.nextPPTRate = pptTaxRate;
            } else {
                (uint256 nextPptTaxRate, ) = ecoScore.getPptTaxRate(ecoZone);
                claimData.taxData.nextPPTRate = nextPptTaxRate;
            }
            claimData.ecoScoreData.prevEcoDR = ecoScoreInfoData.ecoDR;
            claimData.ecoScoreData.prevEcoZone = ecoScoreInfoData.ecoZone;
            claimData.ecoScoreData.nextEcoDR = ecoDR;
            claimData.ecoScoreData.nextEcoZone = ecoZone;
        }
        {
            (uint256 adjustedValue, ) = ecoScore.calculateClaimTaxes(account, accruedGrv);
            claimData.taxData.prevClaimTaxRate = ecoScore
                .ecoPolicyInfoOf(ecoScore.accountEcoScoreInfoOf(account).ecoZone)
                .claimTax;
            claimData.taxData.nextClaimTaxRate = ecoScore.getClaimTaxRate(
                account,
                accruedGrv,
                0,
                Constant.EcoScorePreviewOption.CLAIM
            );
            claimData.taxData.afterTaxesGrv = adjustedValue;
        }

        claimData.accruedGrv = accruedGrv;

        return claimData;
    }

    function getBoostedApr(BoostedAprParams memory data) public view returns (BoostedAprData memory) {
        address[] memory markets = core.allMarkets();
        BoostedAprData memory aprData;
        aprData.boostedAprDetailList = new BoostedAprDetails[](markets.length);

        for (uint256 i = 0; i < markets.length; i++) {
            aprData.boostedAprDetailList[i] = _calculateBoostedAprInfo(markets[i], data);
        }
        return aprData;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _calculateBoostedAprInfo(
        address market,
        BoostedAprParams memory data
    ) private view returns (BoostedAprDetails memory) {
        BoostedAprDetails memory aprDetailInfo;
        aprDetailInfo.market = market;
        address _account = data.account;
        Constant.DistributionAPY memory apyDistribution = grvDistributor.apyDistributionOf(market, _account);
        {
            aprDetailInfo.currentSupplyApr = apyDistribution.apyAccountSupplyGRV;
            aprDetailInfo.currentBorrowApr = apyDistribution.apyAccountBorrowGRV;
        }
        {
            uint256 accountSupply = IGToken(market).balanceOf(_account);
            uint256 accountBorrow = IGToken(market).borrowBalanceOf(_account).mul(1e18).div(
                IGToken(market).getAccInterestIndex()
            );

            if (IGToken(market).underlying() == address(0)) {
                uint256 nftAccInterestIndex = lendPoolLoan.getAccInterestIndex();
                uint256 nftBorrow = lendPoolLoan.userBorrowBalance(_account).mul(1e18).div(nftAccInterestIndex);
                accountBorrow = accountBorrow.add(nftBorrow);
            }

            (uint256 preBoostedSupply, uint256 preBoostedBorrow) = grvDistributor.getPreEcoBoostedInfo(
                market,
                _account,
                data.amount,
                data.expiry,
                data.option
            );
            uint256 expectedApyAccountSupplyGRV = accountSupply > 0
                ? apyDistribution.apySupplyGRV.mul(preBoostedSupply).div(accountSupply)
                : 0;

            uint256 expectedApyAccountBorrowGRV = accountBorrow > 0
                ? apyDistribution.apyBorrowGRV.mul(preBoostedBorrow).div(accountBorrow)
                : 0;

            aprDetailInfo.expectedSupplyApr = expectedApyAccountSupplyGRV;
            aprDetailInfo.expectedBorrowApr = expectedApyAccountBorrowGRV;
        }
        return aprDetailInfo;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../library/Math.sol";

import "../interfaces/ILpVaultDashboard.sol";
import "../interfaces/ILpVault.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IWhiteholePair.sol";
import "../interfaces/IDashboard.sol";

contract LpVaultDashboard is ILpVaultDashboard {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ILpVault public lpVault;
    IWhiteholePair public GRV_USDC_LP;
    IDashboard public dashboard;
    address public GRV;

    /* ========== INITIALIZER ========== */

    constructor(
        address _lpVault,
        address _GRV_USDC_LP,
        address _GRV,
        address _dashboard
    ) public {
        lpVault = ILpVault(_lpVault);
        GRV_USDC_LP = IWhiteholePair(_GRV_USDC_LP);
        GRV = _GRV;
        dashboard = IDashboard(_dashboard);
    }

    /* ========== VIEWS ========== */

    function getLpVaultInfo(address _user) external view override returns (LpVaultData memory) {
        LpVaultData memory lpVaultData;

        (uint256 _amount, , uint256 _lastClaimTime, uint256 _pendingGrvAmount) = lpVault.userInfo(_user);
        lpVaultData.stakedLpAmount = _amount;
        lpVaultData.claimableReward = lpVault.claimableGrvAmount(_user);
        lpVaultData.pendingGrvAmount = _pendingGrvAmount;

        lpVaultData.stakedLpValueInUSD = calculateLpValueInUSD(_amount);
        lpVaultData.totalLiquidity = calculateLpValueInUSD(GRV_USDC_LP.balanceOf(address(lpVault)));
        lpVaultData.apr = calculateVaultAPR();
        lpVaultData.penaltyDuration = _lastClaimTime.add(lpVault.harvestFeePeriod());
        lpVaultData.lockDuration = _lastClaimTime.add(lpVault.lockupPeriod());

        return lpVaultData;
    }

    function calculateVaultAPR() public view returns (uint256) {
        uint256 _rewardPerInterval = lpVault.rewardPerInterval();
        uint256 _dailyRewardAmount = _rewardPerInterval.mul(86400);
        uint256 _vaultLpBalance = GRV_USDC_LP.balanceOf(address(lpVault));

        if (_vaultLpBalance == 0) {
            _vaultLpBalance = _getLpTokenUnitAmount();
        }

        uint256 _stakedValueInUSD = calculateLpValueInUSD(_vaultLpBalance);
        uint256 _grvValueInUSD = dashboard.getCurrentGRVPrice().mul(_dailyRewardAmount).div(1e18);

        if (_stakedValueInUSD == 0) {
            _stakedValueInUSD = 1e18;
        }

        uint256 _dayProfit = _grvValueInUSD.mul(1e18).div(_stakedValueInUSD);
        uint256 apr = _dayProfit.mul(365).mul(100);

        return apr;
    }

    function calculateLpValueInUSD(uint256 _amount) public view override returns (uint256) {
        uint256 _tokenBalance = 0; // USDC Balance
        address _tokenAddress = address(0);

        uint256 _pairTotalSupply = GRV_USDC_LP.totalSupply();

        if (GRV_USDC_LP.token0() == GRV) {
            _tokenAddress = GRV_USDC_LP.token1();
            _tokenBalance = IBEP20(_tokenAddress).balanceOf(address(GRV_USDC_LP));
        } else {
            _tokenAddress = GRV_USDC_LP.token0();
            _tokenBalance = IBEP20(_tokenAddress).balanceOf(address(GRV_USDC_LP));
        }

        uint256 lpValueInUSD = 0;

        if (_pairTotalSupply == 0) {
            lpValueInUSD = 0;
        } else {
            lpValueInUSD = _getAdjustedAmount(address(GRV_USDC_LP), _amount).mul(
                _getAdjustedAmount(_tokenAddress, _tokenBalance)
            ).mul(2).div(_getAdjustedAmount(address(GRV_USDC_LP), _pairTotalSupply));
        }

        return lpValueInUSD;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getLpTokenUnitAmount() private view returns (uint256) {
        uint256 _token0Decimals = IBEP20(GRV_USDC_LP.token0()).decimals();
        uint256 _token0UnitAmount = 10 ** _token0Decimals;

        uint256 _token1Decimals = IBEP20(GRV_USDC_LP.token1()).decimals();
        uint256 _token1UnitAmount = 10 ** _token1Decimals;

        return Math.sqrt(_token0UnitAmount.mul(_token1UnitAmount));
    }

    function _getAdjustedAmount(address token, uint256 amount) private view returns (uint256) {
        if (token == address(0)) {
            return amount;
        } else if (keccak256(abi.encodePacked(IWhiteholePair(token).symbol())) == keccak256("Whitehole-LP")) {
            address _token0 = IWhiteholePair(token).token0();
            address _token1 = IWhiteholePair(token).token1();

            uint256 _token0Decimals = IBEP20(_token0).decimals();
            uint256 _token0UnitAmount = 10 ** _token0Decimals;

            uint256 _token1Decimals = IBEP20(_token1).decimals();
            uint256 _token1UnitAmount = 10 ** _token1Decimals;

            uint256 _lpTokenUnitAmount = Math.sqrt(_token0UnitAmount * _token1UnitAmount);
            return (amount * 1e18) / _lpTokenUnitAmount;
        } else {
            uint256 defaultDecimal = 18;
            uint256 tokenDecimal = IBEP20(token).decimals();

            if (tokenDecimal == defaultDecimal) {
                return amount;
            } else if (tokenDecimal < defaultDecimal) {
                return amount * (10**(defaultDecimal - tokenDecimal));
            } else {
                return amount / (10**(tokenDecimal - defaultDecimal));
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IMarketDashboard.sol";
import "../interfaces/IGRVDistributor.sol";
import "../interfaces/IMarketView.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/ICore.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/ILendPoolLoan.sol";

contract MarketDashboard is IMarketDashboard, OwnableUpgradeable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    IGRVDistributor public grvDistributor;
    IMarketView public marketView;
    ICore public core;
    IPriceCalculator public priceCalculator;
    ILendPoolLoan public lendPoolLoan;

    /* ========== INITIALIZER ========== */

    function initialize(address _core, address _grvDistributor, address _marketView, address _priceCalculator) external initializer {
        require(_grvDistributor != address(0), "MarketDashboard: grvDistributor address can't be zero");
        require(_marketView != address(0), "MarketDashboard: MarketView address can't be zero");
        require(_core != address(0), "MarketDashboard: core address can't be zero");
        require(_priceCalculator != address(0), "MarketDashboard: priceCalculator address can't be zero");

        __Ownable_init();

        core = ICore(_core);
        grvDistributor = IGRVDistributor(_grvDistributor);
        marketView = IMarketView(_marketView);
        priceCalculator = IPriceCalculator(_priceCalculator);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setDistributor(address _grvDistributor) external onlyOwner {
        require(_grvDistributor != address(0), "MarketDashboard: invalid grvDistributor address");
        grvDistributor = IGRVDistributor(_grvDistributor);
    }

    function setMarketView(address _marketView) external onlyOwner {
        require(_marketView != address(0), "MarketDashboard: invalid MarketView address");
        marketView = IMarketView(_marketView);
    }

    function setPriceCalculator(address _priceCalculator) external onlyOwner {
        require(_priceCalculator != address(0), "MarketDashboard: invalid priceCalculator address");
        priceCalculator = IPriceCalculator(_priceCalculator);
    }

    function setLendPoolLoan(address _lendPoolLoan) external onlyOwner {
        require(_lendPoolLoan != address(0), "MarketDashboard: invalid lendPoolLoan address");
        lendPoolLoan = ILendPoolLoan(_lendPoolLoan);
    }

    /* ========== VIEWS ========== */

    function marketDataOf(address market) external view override returns (MarketData memory) {
        MarketData memory marketData;
        Constant.DistributionAPY memory apyDistribution = grvDistributor.apyDistributionOf(market, address(0));
        Constant.DistributionInfo memory distributionInfo = grvDistributor.distributionInfoOf(market);
        IGToken gToken = IGToken(market);

        marketData.gToken = market;

        marketData.apySupply = marketView.supplyRatePerSec(market).mul(365 days);
        marketData.apyBorrow = marketView.borrowRatePerSec(market).mul(365 days);
        marketData.apySupplyGRV = apyDistribution.apySupplyGRV;
        marketData.apyBorrowGRV = apyDistribution.apyBorrowGRV;

        marketData.totalSupply = gToken.totalSupply().mul(gToken.exchangeRate()).div(1e18);
        marketData.totalBorrows = gToken.totalBorrow();
        marketData.totalBoostedSupply = distributionInfo.totalBoostedSupply;
        marketData.totalBoostedBorrow = distributionInfo.totalBoostedBorrow;

        marketData.cash = gToken.getCash();
        marketData.reserve = gToken.totalReserve();
        marketData.reserveFactor = gToken.reserveFactor();
        marketData.collateralFactor = core.marketInfoOf(market).collateralFactor;
        marketData.exchangeRate = gToken.exchangeRate();
        marketData.borrowCap = core.marketInfoOf(market).borrowCap;
        marketData.accInterestIndex = gToken.getAccInterestIndex();
        return marketData;
    }

    function usersMonthlyProfit(address account) external view override returns (uint256 supplyBaseProfits, uint256 supplyRewardProfits, uint256 borrowBaseProfits, uint256 borrowRewardProfits) {
        address[] memory markets = core.allMarkets();
        uint[] memory prices = priceCalculator.getUnderlyingPrices(markets);
        supplyBaseProfits = 0;
        supplyRewardProfits = 0;
        borrowBaseProfits = 0;
        borrowRewardProfits = 0;

        for (uint256 i = 0; i < markets.length; i++) {
            Constant.DistributionAPY memory apyDistribution = grvDistributor.apyDistributionOf(markets[i], account);
            uint256 decimals = _getDecimals(markets[i]);
            {
                uint256 supplyBalance = IGToken(markets[i]).underlyingBalanceOf(account);
                uint256 supplyAPY = marketView.supplyRatePerSec(markets[i]).mul(365 days);
                uint256 supplyInUSD = supplyBalance.mul(10 ** (18-decimals)).mul(prices[i]).div(1e18);
                uint256 supplyMonthlyProfit = supplyInUSD.mul(supplyAPY).div(12).div(1e18);
                uint256 supplyGRVMonthlyProfit = supplyInUSD.mul(apyDistribution.apyAccountSupplyGRV).div(12).div(1e18);

                supplyBaseProfits = supplyBaseProfits.add(supplyMonthlyProfit);
                supplyRewardProfits = supplyRewardProfits.add(supplyGRVMonthlyProfit);
            }
            {
                uint256 borrowBalance = IGToken(markets[i]).borrowBalanceOf(account);
                if (IGToken(markets[i]).underlying() == address(0)) {
                    borrowBalance = borrowBalance.add(lendPoolLoan.userBorrowBalance(account));
                }
                uint256 borrowAPY = marketView.borrowRatePerSec(markets[i]).mul(365 days);
                uint256 borrowInUSD = borrowBalance.mul(10 ** (18-decimals)).mul(prices[i]).div(1e18);
                uint256 borrowMonthlyProfit = borrowInUSD.mul(borrowAPY).div(12).div(1e18);
                uint256 borrowGRVMonthlyProfit = borrowInUSD.mul(apyDistribution.apyAccountBorrowGRV).div(12).div(1e18);

                borrowBaseProfits = borrowBaseProfits.add(borrowMonthlyProfit);
                borrowRewardProfits = borrowRewardProfits.add(borrowGRVMonthlyProfit);
            }
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getDecimals(address gToken) internal view returns (uint256 decimals) {
        address underlying = IGToken(gToken).underlying();
        if (underlying == address(0)) {
            decimals = 18; // ETH
        }
        else {
            decimals = IBEP20(underlying).decimals();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

import "../interfaces/INftMarketDashboard.sol";
import "../interfaces/ILendPoolLoan.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/IGNft.sol";
import "../interfaces/INFTOracle.sol";
import "../interfaces/INftCore.sol";

contract NftMarketDashboard is INftMarketDashboard {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ILendPoolLoan public lendPoolLoan;
    IGToken public borrowMarket;
    INFTOracle public nftOracle;
    INftCore public nftCore;

    /* ========== INITIALIZER ========== */

    constructor(
        address _lendPoolLoan,
        address _borrowMarket,
        address _nftOracle,
        address _nftCore
    ) public {
        lendPoolLoan = ILendPoolLoan(_lendPoolLoan);
        borrowMarket = IGToken(_borrowMarket);
        nftOracle = INFTOracle(_nftOracle);
        nftCore = INftCore(_nftCore);
    }

    /* ========== VIEWS ========== */

    // NFT Market Overview - NFT Market Info
    function nftMarketStats() external view override returns (NftMarketStats memory) {
        NftMarketStats memory _nftMarketStats;

        uint256 _totalBorrowInETH = lendPoolLoan.totalBorrow();

        uint256 _totalSupply = borrowMarket.totalSupply().mul(borrowMarket.exchangeRate()).div(1e18);
        uint256 _collateralLoanRatio = 0;

        if (_totalSupply > 0) {
            _collateralLoanRatio = _totalBorrowInETH.mul(1e18).div(_totalSupply);
        }

        uint256 _totalNftValueInETH = 0;
        address[] memory _markets = nftCore.allMarkets();
        for (uint256 i = 0; i < _markets.length; i++) {
            address _underlying = IGNft(_markets[i]).underlying();
            uint256 _nftCollateralAmount = lendPoolLoan.getNftCollateralAmount(_underlying);
            uint256 _nftPriceInETH = nftOracle.getUnderlyingPrice(_markets[i]);
            uint256 _nftCollateralValue = _nftPriceInETH.mul(_nftCollateralAmount);
            _totalNftValueInETH = _totalNftValueInETH.add(_nftCollateralValue);
        }

        _nftMarketStats.collateralLoanRatio = _collateralLoanRatio;
        _nftMarketStats.totalNftValueInETH = _totalNftValueInETH;
        _nftMarketStats.totalBorrowInETH = _totalBorrowInETH;
        return _nftMarketStats;
    }

    // NFT Market Overview - NFT Market List
    function nftMarketInfos() external view override returns (NftMarketInfo[] memory) {
        address[] memory _markets = nftCore.allMarkets();
        NftMarketInfo[] memory _nftMarketInfos = new NftMarketInfo[](_markets.length);

        for (uint256 i = 0; i < _markets.length; i++) {
            address _underlying = IGNft(_markets[i]).underlying();
            string memory _symbol = IERC721Metadata(_underlying).symbol();
            uint256 _totalSupply = IERC721EnumerableUpgradeable(_underlying).totalSupply();
            uint256 _nftCollateralAmount = lendPoolLoan.getNftCollateralAmount(_underlying);
            uint256 _supplyCap = nftCore.marketInfoOf(_markets[i]).supplyCap;
            uint256 _availableNft = _supplyCap.sub(_nftCollateralAmount);
            uint256 _borrowCap = nftCore.marketInfoOf(_markets[i]).borrowCap;
            uint256 _floorPrice = nftOracle.getUnderlyingPrice(_markets[i]);
            uint256 _totalNftValueInETH = _floorPrice.mul(_nftCollateralAmount);
            uint256 _totalBorrowInETH = lendPoolLoan.marketBorrowBalance(_markets[i]);

            _nftMarketInfos[i] = NftMarketInfo({
                symbol: _symbol,
                totalSupply: _totalSupply,
                nftCollateralAmount: _nftCollateralAmount,
                availableNft: _availableNft,
                borrowCap: _borrowCap,
                floorPrice: _floorPrice,
                totalNftValueInETH: _totalNftValueInETH,
                totalBorrowInETH: _totalBorrowInETH
            });
        }
        return _nftMarketInfos;
    }

    // Deposit NFT & Borrow ETH Modal
    function borrowModalInfo(address gNft, address user) external view override returns (BorrowModalInfo memory) {
        BorrowModalInfo memory _borrowModalInfo;

        uint256[] memory tokenIds = _getUserTokenIds(gNft, user);

        _borrowModalInfo.tokenIds = tokenIds;
        _borrowModalInfo.floorPrice = nftOracle.getUnderlyingPrice(gNft);
        _borrowModalInfo.collateralFactor = nftCore.marketInfoOf(gNft).collateralFactor;
        _borrowModalInfo.liquidationThreshold = nftCore.marketInfoOf(gNft).liquidationThreshold;

        return _borrowModalInfo;
    }

    // Manage Loan Modal
    function manageLoanModalInfo(address gNft, address user) external view override returns (ManageLoanModalInfo memory) {
        ManageLoanModalInfo memory _manageLoanModalInfo;

        UserLoanInfo[] memory userLoanInfos = _getUserLoanInfos(gNft, user);

        _manageLoanModalInfo.userLoanInfos = userLoanInfos;
        _manageLoanModalInfo.floorPrice = nftOracle.getUnderlyingPrice(gNft);

        return _manageLoanModalInfo;
    }

    // My Dashboard - NFT Market Info
    function myNftMarketStats(address user) external view override returns (MyNftMarketStats memory) {
        MyNftMarketStats memory _myNftMarketStats;

        uint256 _totalCollateralAmount = 0;
        uint256 _totalBorrowAmount = lendPoolLoan.userBorrowBalance(user);

        address[] memory _markets = nftCore.allMarkets();
        for (uint256 i = 0; i < _markets.length; i++) {
            address _underlying = IGNft(_markets[i]).underlying();
            uint256 _nftCollateralAmount = lendPoolLoan.getUserNftCollateralAmount(user, _underlying);

            _totalCollateralAmount = _totalCollateralAmount.add(_nftCollateralAmount);
        }

        _myNftMarketStats.nftCollateralAmount = _totalCollateralAmount;
        _myNftMarketStats.totalBorrowInETH = _totalBorrowAmount;
        return _myNftMarketStats;
    }

    // My Dashboard - My Collection List
    function myNftMarketInfos(address user) external view override returns (MyNftMarketInfo[] memory) {
        address[] memory _markets = nftCore.allMarkets();
        address _user = user;
        uint256 _activeMarketCount = 0;

        for (uint256 i = 0; i < _markets.length; i++) {
            address _underlying = IGNft(_markets[i]).underlying();
            uint256 _nftCollateralAmount = lendPoolLoan.getUserNftCollateralAmount(_user, _underlying);
            if (_nftCollateralAmount > 0) {
                _activeMarketCount = _activeMarketCount.add(1);
            }
        }

        address[] memory _activeMarkets = new address[](_activeMarketCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < _markets.length; i++) {
            address _underlying = IGNft(_markets[i]).underlying();
            uint256 _nftCollateralAmount = lendPoolLoan.getUserNftCollateralAmount(_user, _underlying);
            if (_nftCollateralAmount > 0) {
                _activeMarkets[idx] = _markets[i];
                idx = idx + 1;
            }
        }

        MyNftMarketInfo[] memory _myNftMarketInfos = new MyNftMarketInfo[](_activeMarkets.length);
        for (uint256 i = 0; i < _activeMarkets.length; i++) {
            address _underlying = IGNft(_activeMarkets[i]).underlying();
            string memory _symbol = IERC721Metadata(_underlying).symbol();
            uint256 _nftCollateralAmount = lendPoolLoan.getUserNftCollateralAmount(_user, _underlying);
            uint256 _floorPrice = nftOracle.getUnderlyingPrice(_activeMarkets[i]);
            uint256 _totalBorrowInETH = lendPoolLoan.marketAccountBorrowBalance(_activeMarkets[i], _user);
            uint256 _collateralFactor = nftCore.marketInfoOf(_activeMarkets[i]).collateralFactor;
            uint256 _collateralValueInETH = _floorPrice.mul(_nftCollateralAmount).mul(_collateralFactor).div(1e18);

            uint256 _availableBorrowInETH = 0;

            if (_collateralValueInETH >= _totalBorrowInETH) {
                _availableBorrowInETH = _collateralValueInETH.sub(_totalBorrowInETH);
            }
            _myNftMarketInfos[i] = MyNftMarketInfo({
                symbol: _symbol,
                availableBorrowInETH: _availableBorrowInETH,
                totalBorrowInETH: _totalBorrowInETH,
                nftCollateralAmount: _nftCollateralAmount,
                floorPrice: _floorPrice
            });
        }
        return _myNftMarketInfos;
    }

    // My Dashboard - My Collection List - View Details
    function userLoanInfos(address gNft, address user) external view override returns (UserLoanInfo[] memory) {
        return _getUserLoanInfos(gNft, user);
    }

    // Auction List
    function auctionList() external view override returns (Auction[] memory) {
        Auction[] memory auctionInfos = _getAuctionInfos();
        Auction[] memory dangerousLoans = _getDangerousLoans();

        uint256 _auctionLength = auctionInfos.length.add(dangerousLoans.length);
        Auction[] memory auctions = new Auction[](_auctionLength);

        for (uint256 i = 0; i < dangerousLoans.length; i++) {
            auctions[i] = dangerousLoans[i];
        }

        uint256 idx = 0;
        for (uint256 i = dangerousLoans.length; i < _auctionLength; i++) {
            auctions[i] = auctionInfos[idx];
            idx = idx.add(1);
        }
        return auctions;
    }

    // Health Factor Alert List
    function healthFactorAlertList() external view override returns (RiskyLoanInfo[] memory) {
        return _getRiskyLoans();
    }

    // Auction History
    function auctionHistory() external view override returns (Auction[] memory) {
        return _getAuctionHistory();
    }

    // My Auction History
    function myAuctionHistory(address user) external view override returns (Auction[] memory) {
        return _getMyAuctionHistory(user);
    }

    function calculateLiquidatePrice(address gNft, uint256 floorPrice, uint256 debt) external view override returns (uint256) {
        uint256 liquidationBonus = nftCore.marketInfoOf(gNft).liquidationBonus;
        uint256 bonusAmount = floorPrice.mul(liquidationBonus).div(1e18);

        uint256 liquidatePrice = floorPrice.sub(bonusAmount);

        if (liquidatePrice < debt) {
            uint256 bidDelta = debt.mul(1e16).div(1e18); // 1%
            liquidatePrice = debt.add(bidDelta).add(1e16); // 0.01ETH
        }
        return liquidatePrice;
    }

    function calculateBiddablePrice(uint256 debt, uint256 bidAmount) external view override returns (uint256) {
        uint256 bidDelta = debt.mul(1e16).div(1e18); // 1%
        return bidAmount.add(bidDelta).add(1e16); // 0.01ETH
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getUserTokenIds(address gNft, address user) private view returns (uint256[] memory) {
        address _underlying = IGNft(gNft).underlying();
        uint256 _balance = IERC721Upgradeable(_underlying).balanceOf(user);

        uint256[] memory tokenIds = new uint256[](_balance);

        for(uint256 i = 0; i < _balance; i++) {
            tokenIds[i]= IERC721EnumerableUpgradeable(_underlying).tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

    function _getRiskyLoans() private view returns (RiskyLoanInfo[] memory) {
        uint256 _currentLoanId = lendPoolLoan.currentLoanId();

        if (_currentLoanId == 1) {
            return new RiskyLoanInfo[](0);
        }

        uint256 _riskyLoanCount = 0;
        for (uint256 i = 1; i < _currentLoanId; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(i);
            uint256 _floorPrice = nftOracle.getUnderlyingPrice(loan.gNft);
            uint256 _debt = lendPoolLoan.borrowBalanceOf(i);
            uint256 _liquidationThreshold = nftCore.marketInfoOf(loan.gNft).liquidationThreshold;
            uint256 _healthFactor = _calculateHealthFactor(_floorPrice, _debt, _liquidationThreshold);
            if (loan.state == Constant.LoanState.Active && _healthFactor >= 1e18 && _healthFactor <= 12e17) {
                _riskyLoanCount = _riskyLoanCount.add(1);
            }
        }

        RiskyLoanInfo[] memory _riskyLoans = new RiskyLoanInfo[](_riskyLoanCount);
        uint256 idx = 0;

        for (uint256 i = 1; i < _currentLoanId; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(i);
            uint256 _floorPrice = nftOracle.getUnderlyingPrice(loan.gNft);
            uint256 _debt = lendPoolLoan.borrowBalanceOf(i);
            uint256 _liquidationThreshold = nftCore.marketInfoOf(loan.gNft).liquidationThreshold;
            uint256 _healthFactor = _calculateHealthFactor(_floorPrice, _debt, _liquidationThreshold);
            if (loan.state == Constant.LoanState.Active && _healthFactor >= 1e18 && _healthFactor <= 12e17) {
                _riskyLoans[idx] = RiskyLoanInfo({
                    symbol: IERC721Metadata(loan.nftAsset).symbol(),
                    tokenId: loan.nftTokenId,
                    floorPrice: _floorPrice,
                    debt: _debt,
                    healthFactor: _healthFactor
                });
                idx = idx.add(1);
            }
        }
        return _riskyLoans;
    }

    function _getDangerousLoans() private view returns (Auction[] memory) {
        uint256 _currentLoanId = lendPoolLoan.currentLoanId();

        if (_currentLoanId == 1) {
            return new Auction[](0);
        }

        uint256 _dangerousLoanCount = 0;
        for (uint256 i = 1; i < _currentLoanId; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(i);
            uint256 _floorPrice = nftOracle.getUnderlyingPrice(loan.gNft);
            uint256 _debt = lendPoolLoan.borrowBalanceOf(i);
            uint256 _liquidationThreshold = nftCore.marketInfoOf(loan.gNft).liquidationThreshold;
            uint256 _healthFactor = _calculateHealthFactor(_floorPrice, _debt, _liquidationThreshold);
            if (loan.state == Constant.LoanState.Active && _healthFactor < 1e18) {
                _dangerousLoanCount = _dangerousLoanCount.add(1);
            }
        }

        Auction[] memory _dangerousLoans = new Auction[](_dangerousLoanCount);
        uint256 idx = 0;

        for (uint256 i = 1; i < _currentLoanId; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(i);
            uint256 _floorPrice = nftOracle.getUnderlyingPrice(loan.gNft);
            uint256 _debt = lendPoolLoan.borrowBalanceOf(i);
            uint256 _liquidationThreshold = nftCore.marketInfoOf(loan.gNft).liquidationThreshold;
            uint256 _healthFactor = _calculateHealthFactor(_floorPrice, _debt, _liquidationThreshold);
            if (loan.state == Constant.LoanState.Active && _healthFactor < 1e18) {
                _dangerousLoans[idx] = Auction({
                    state: loan.state,
                    symbol: IERC721Metadata(loan.nftAsset).symbol(),
                    tokenId: loan.nftTokenId,
                    floorPrice: _floorPrice,
                    debt: _debt,
                    latestBidAmount: loan.bidPrice,
                    bidEndTimestamp: 0,
                    healthFactor: _healthFactor,
                    bidCount: loan.bidCount,
                    bidderAddress: loan.bidderAddress,
                    borrower: loan.borrower,
                    loanId: loan.loanId
                });
                idx = idx.add(1);
            }
        }
        return _dangerousLoans;
    }

    function _getAuctionHistory() private view returns (Auction[] memory) {
        uint256 _currentLoanId = lendPoolLoan.currentLoanId();

        if (_currentLoanId == 1) {
            return new Auction[](0);
        }

        uint256 _auctionHistoryCount = 0;
        for (uint256 i = 1; i < _currentLoanId; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(i);
            if ((loan.state == Constant.LoanState.Auction &&
                 block.timestamp > loan.bidStartTimestamp.add(lendPoolLoan.auctionDuration())) ||
                 loan.state == Constant.LoanState.Defaulted) {
                _auctionHistoryCount = _auctionHistoryCount.add(1);
            }
        }

        Auction[] memory _auctionHistory = new Auction[](_auctionHistoryCount);
        uint256 idx = 0;

        for (uint256 i = 1; i < _currentLoanId; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(i);
            if ((loan.state == Constant.LoanState.Auction &&
                 block.timestamp > loan.bidStartTimestamp.add(lendPoolLoan.auctionDuration())) ||
                 loan.state == Constant.LoanState.Defaulted) {

                uint256 debt = 0;

                if (loan.state == Constant.LoanState.Auction) {
                    debt = lendPoolLoan.borrowBalanceOf(i);
                } else {
                    debt = loan.bidBorrowAmount;
                }
                _auctionHistory[idx] = Auction({
                    state: loan.state,
                    symbol: IERC721Metadata(loan.nftAsset).symbol(),
                    tokenId: loan.nftTokenId,
                    floorPrice: loan.floorPrice,
                    debt: debt,
                    latestBidAmount: loan.bidPrice,
                    bidEndTimestamp: loan.bidStartTimestamp.add(lendPoolLoan.auctionDuration()),
                    healthFactor: 0,
                    bidCount: loan.bidCount,
                    bidderAddress: loan.bidderAddress,
                    borrower: loan.borrower,
                    loanId: loan.loanId
                });
                idx = idx.add(1);
            }
        }
        return _auctionHistory;
    }

    function _getMyAuctionHistory(address user) private view returns (Auction[] memory) {
        uint256 _currentLoanId = lendPoolLoan.currentLoanId();

        if (_currentLoanId == 1) {
            return new Auction[](0);
        }

        uint256 _myAuctionHistoryCount = 0;
        for (uint256 i = 1; i < _currentLoanId; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(i);
            if ((loan.state == Constant.LoanState.Auction &&
                block.timestamp > loan.bidStartTimestamp.add(lendPoolLoan.auctionDuration()) &&
                (loan.borrower == user || loan.bidderAddress == user)) ||
                (loan.state == Constant.LoanState.Defaulted && (loan.borrower == user || loan.bidderAddress == user))) {
                _myAuctionHistoryCount = _myAuctionHistoryCount.add(1);
            }
        }

        Auction[] memory _auctionHistory = new Auction[](_myAuctionHistoryCount);
        uint256 idx = 0;

        for (uint256 i = 1; i < _currentLoanId; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(i);

            if ((loan.state == Constant.LoanState.Auction &&
                block.timestamp > loan.bidStartTimestamp.add(lendPoolLoan.auctionDuration()) &&
                (loan.borrower == user || loan.bidderAddress == user)) ||
                (loan.state == Constant.LoanState.Defaulted && (loan.borrower == user || loan.bidderAddress == user))) {
                uint256 debt = 0;

                if (loan.state == Constant.LoanState.Auction) {
                    debt = lendPoolLoan.borrowBalanceOf(i);
                } else {
                    debt = loan.bidBorrowAmount;
                }
                _auctionHistory[idx] = Auction({
                    state: loan.state,
                    symbol: IERC721Metadata(loan.nftAsset).symbol(),
                    tokenId: loan.nftTokenId,
                    floorPrice: loan.floorPrice,
                    debt: debt,
                    latestBidAmount: loan.bidPrice,
                    bidEndTimestamp: loan.bidStartTimestamp.add(lendPoolLoan.auctionDuration()),
                    healthFactor: 0,
                    bidCount: loan.bidCount,
                    bidderAddress: loan.bidderAddress,
                    borrower: loan.borrower,
                    loanId: loan.loanId
                });
                idx = idx.add(1);
            }
        }
        return _auctionHistory;
    }

    function _getAuctionInfos() private view returns (Auction[] memory) {
        uint256 _currentLoanId = lendPoolLoan.currentLoanId();

        if (_currentLoanId == 1) {
            return new Auction[](0);
        }

        uint256 _activeAuctionCount = 0;
        uint256 _auctionDuration = lendPoolLoan.auctionDuration();

        for (uint256 i = 1; i < _currentLoanId; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(i);
            if (loan.state == Constant.LoanState.Auction &&
                block.timestamp < loan.bidStartTimestamp.add(_auctionDuration)) {
                _activeAuctionCount = _activeAuctionCount.add(1);
            }
        }

        Auction[] memory _auctions = new Auction[](_activeAuctionCount);
        uint256 idx = 0;

        for (uint256 i = 1; i < _currentLoanId; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(i);
            if (loan.state == Constant.LoanState.Auction &&
                block.timestamp < loan.bidStartTimestamp.add(_auctionDuration)) {
                uint256 _liquidationThreshold = nftCore.marketInfoOf(loan.gNft).liquidationThreshold;
                uint256 _floorPrice = nftOracle.getUnderlyingPrice(loan.gNft);
                uint256 _debt = lendPoolLoan.borrowBalanceOf(i);
                _auctions[idx] = Auction({
                    state: loan.state,
                    symbol: IERC721Metadata(loan.nftAsset).symbol(),
                    tokenId: loan.nftTokenId,
                    floorPrice: loan.floorPrice,
                    debt: lendPoolLoan.borrowBalanceOf(i),
                    latestBidAmount: loan.bidPrice,
                    bidEndTimestamp: loan.bidStartTimestamp.add(lendPoolLoan.auctionDuration()),
                    healthFactor: _calculateHealthFactor(_floorPrice, _debt, _liquidationThreshold),
                    bidCount: loan.bidCount,
                    bidderAddress: loan.bidderAddress,
                    borrower: loan.borrower,
                    loanId: loan.loanId
                });
                idx = idx.add(1);
            }
        }
        return _auctions;
    }

    function _getUserLoanInfos(address gNft, address user) private view returns (UserLoanInfo[] memory) {
        address _user = user;
        address _gNft = gNft;
        address _underlying = IGNft(_gNft).underlying();
        uint256 _currentLoanId = lendPoolLoan.currentLoanId();
        uint256 _userLoanCount = 0;

        if (_currentLoanId == 1) {
            return new UserLoanInfo[](0);
        }

        for (uint256 i = 1; i < _currentLoanId; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(i);
            if (loan.nftAsset == _underlying &&
               (loan.state == Constant.LoanState.Active || loan.state == Constant.LoanState.Auction) &&
                loan.borrower == _user) {
                _userLoanCount = _userLoanCount.add(1);
            }
        }

        UserLoanInfo[] memory _userLoanInfos = new UserLoanInfo[](_userLoanCount);
        uint256 idx = 0;
        uint256 _nftAssetPrice = nftOracle.getUnderlyingPrice(_gNft);
        uint256 _liquidationThreshold = nftCore.marketInfoOf(_gNft).liquidationThreshold;
        uint256 _collateralFactor = nftCore.marketInfoOf(_gNft).collateralFactor;
        uint256 _redeemThreshold = lendPoolLoan.redeemThreshold();
        uint256 _minBidFine = lendPoolLoan.minBidFine();
        uint256 _redeemFineRate = lendPoolLoan.redeemFineRate();

        for (uint256 i = 1; i < _currentLoanId; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(i);
            if (loan.nftAsset == _underlying &&
               (loan.state == Constant.LoanState.Active || loan.state == Constant.LoanState.Auction) &&
                loan.borrower == _user) {
                uint256 _borrowBalance = lendPoolLoan.borrowBalanceOf(i);
                uint256 _nftCollateralInETH = _nftAssetPrice.mul(_collateralFactor).div(1e18);
                uint256 _availableBorrowInETH = 0;
                uint256 _bidFineAmount = _borrowBalance.mul(_redeemFineRate).div(1e18);
                if (_bidFineAmount < _minBidFine) {
                    _bidFineAmount = _minBidFine;
                }

                if (_nftCollateralInETH > _borrowBalance) {
                    _availableBorrowInETH = _nftCollateralInETH.sub(_borrowBalance);
                }
                _userLoanInfos[idx] = UserLoanInfo({
                    loanId: loan.loanId,
                    state: loan.state,
                    tokenId: loan.nftTokenId,
                    healthFactor: _calculateHealthFactor(_nftAssetPrice, _borrowBalance, _liquidationThreshold),
                    debt: _borrowBalance,
                    liquidationPrice: _calculateLiquidationPrice(_borrowBalance, _liquidationThreshold),
                    collateralInETH: loan.state == Constant.LoanState.Active ? _nftCollateralInETH : 0,
                    availableBorrowInETH: _availableBorrowInETH,
                    bidPrice: loan.bidPrice,
                    minRepayAmount: loan.state == Constant.LoanState.Auction ? _borrowBalance.mul(_redeemThreshold).div(1e18) : 0,
                    maxRepayAmount: loan.state == Constant.LoanState.Auction ? _borrowBalance.mul(9e17).div(1e18) : 0,
                    repayPenalty: loan.state == Constant.LoanState.Auction ? _bidFineAmount : 0
                });
                idx = idx.add(1);
            }
        }
        return _userLoanInfos;
    }

    function _calculateHealthFactor(uint256 _totalCollateral, uint256 _totalDebt, uint256 _liquidationThreshold) private pure returns (uint256) {
        if (_totalDebt == 0) {
            return uint256(-1);
        }
        return (_totalCollateral.mul(_liquidationThreshold).mul(1e18).div(_totalDebt).div(1e18));
    }

    function _calculateLiquidationPrice(uint256 _totalDebt, uint256 _liquidationThreshold) private pure returns (uint256) {
        if (_totalDebt == 0) {
            return 0;
        }
        return (_totalDebt.mul(1e18).div(_liquidationThreshold));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

import "../interfaces/INftMarketDashboardV2.sol";
import "../interfaces/ILendPoolLoan.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/IGNft.sol";
import "../interfaces/INFTOracle.sol";
import "../interfaces/INftCore.sol";
import "../interfaces/INFT.sol";

contract NftMarketDashboardV2 is INftMarketDashboardV2 {
    using SafeMath for uint256;

    /* ========== CONSTANTS ============= */
    address private constant SMOLBRAIN = 0x6325439389E0797Ab35752B4F43a14C004f22A9c;
    address private constant LILPUDGYS = 0x611747CC4576aAb44f602a65dF3557150C214493;

    /* ========== STATE VARIABLES ========== */

    ILendPoolLoan public lendPoolLoan;
    IGToken public borrowMarket;
    INFTOracle public nftOracle;
    INftCore public nftCore;

    /* ========== INITIALIZER ========== */

    constructor(
        address _lendPoolLoan,
        address _borrowMarket,
        address _nftOracle,
        address _nftCore
    ) public {
        lendPoolLoan = ILendPoolLoan(_lendPoolLoan);
        borrowMarket = IGToken(_borrowMarket);
        nftOracle = INFTOracle(_nftOracle);
        nftCore = INftCore(_nftCore);
    }

    /* ========== VIEWS ========== */

    // NFT Market Overview - NFT Market Info
    function nftMarketStats() external view override returns (NftMarketStats memory) {
        NftMarketStats memory _nftMarketStats;

        uint256 _totalBorrowInETH = lendPoolLoan.totalBorrow();

        uint256 _totalSupply = borrowMarket.totalSupply().mul(borrowMarket.exchangeRate()).div(1e18);
        uint256 _collateralLoanRatio = 0;

        if (_totalSupply > 0) {
            _collateralLoanRatio = _totalBorrowInETH.mul(1e18).div(_totalSupply);
        }

        uint256 _totalNftValueInETH = 0;
        address[] memory _markets = nftCore.allMarkets();
        for (uint256 i = 0; i < _markets.length; i++) {
            address _underlying = IGNft(_markets[i]).underlying();
            uint256 _nftCollateralAmount = lendPoolLoan.getNftCollateralAmount(_underlying);
            uint256 _nftPriceInETH = nftOracle.getUnderlyingPrice(_markets[i]);
            uint256 _nftCollateralValue = _nftPriceInETH.mul(_nftCollateralAmount);
            _totalNftValueInETH = _totalNftValueInETH.add(_nftCollateralValue);
        }

        _nftMarketStats.collateralLoanRatio = _collateralLoanRatio;
        _nftMarketStats.totalNftValueInETH = _totalNftValueInETH;
        _nftMarketStats.totalBorrowInETH = _totalBorrowInETH;
        return _nftMarketStats;
    }

    // NFT Market Overview - NFT Market List
    function nftMarketInfos() external view override returns (NftMarketInfo[] memory) {
        address[] memory _markets = nftCore.allMarkets();
        NftMarketInfo[] memory _nftMarketInfos = new NftMarketInfo[](_markets.length);

        for (uint256 i = 0; i < _markets.length; i++) {
            address _underlying = IGNft(_markets[i]).underlying();
            string memory _symbol = IERC721Metadata(_underlying).symbol();
            uint256 _totalSupply = 0;
            if (_underlying == LILPUDGYS) {
                _totalSupply = INFT(_underlying).MAX_ELEMENTS();
            } else {
                _totalSupply = IERC721EnumerableUpgradeable(_underlying).totalSupply();
            }
            uint256 _nftCollateralAmount = lendPoolLoan.getNftCollateralAmount(_underlying);
            uint256 _supplyCap = nftCore.marketInfoOf(_markets[i]).supplyCap;
            uint256 _availableNft = _supplyCap.sub(_nftCollateralAmount);
            uint256 _borrowCap = nftCore.marketInfoOf(_markets[i]).borrowCap;
            uint256 _floorPrice = nftOracle.getUnderlyingPrice(_markets[i]);
            uint256 _totalNftValueInETH = _floorPrice.mul(_nftCollateralAmount);
            uint256 _totalBorrowInETH = lendPoolLoan.marketBorrowBalance(_markets[i]);

            _nftMarketInfos[i] = NftMarketInfo({
                symbol: _symbol,
                totalSupply: _totalSupply,
                nftCollateralAmount: _nftCollateralAmount,
                availableNft: _availableNft,
                borrowCap: _borrowCap,
                floorPrice: _floorPrice,
                totalNftValueInETH: _totalNftValueInETH,
                totalBorrowInETH: _totalBorrowInETH
            });
        }
        return _nftMarketInfos;
    }

    // Deposit NFT & Borrow ETH Modal
    function borrowModalInfo(address gNft, address user) external view override returns (BorrowModalInfo memory) {
        BorrowModalInfo memory _borrowModalInfo;

        uint256[] memory tokenIds = _getUserTokenIds(gNft, user);

        _borrowModalInfo.tokenIds = tokenIds;
        _borrowModalInfo.floorPrice = nftOracle.getUnderlyingPrice(gNft);
        _borrowModalInfo.collateralFactor = nftCore.marketInfoOf(gNft).collateralFactor;
        _borrowModalInfo.liquidationThreshold = nftCore.marketInfoOf(gNft).liquidationThreshold;

        return _borrowModalInfo;
    }

    // Manage Loan Modal
    function manageLoanModalInfo(address gNft, address user, uint256[] calldata loanIds) external view override returns (ManageLoanModalInfo memory) {
        ManageLoanModalInfo memory _manageLoanModalInfo;

        UserLoanInfo[] memory userLoanInfos = _getUserLoanInfos(gNft, user, loanIds);

        _manageLoanModalInfo.userLoanInfos = userLoanInfos;
        _manageLoanModalInfo.floorPrice = nftOracle.getUnderlyingPrice(gNft);

        return _manageLoanModalInfo;
    }

    // My Dashboard - NFT Market Info
    function myNftMarketStats(address user) external view override returns (MyNftMarketStats memory) {
        MyNftMarketStats memory _myNftMarketStats;

        uint256 _totalCollateralAmount = 0;
        uint256 _totalBorrowAmount = lendPoolLoan.userBorrowBalance(user);

        address[] memory _markets = nftCore.allMarkets();
        for (uint256 i = 0; i < _markets.length; i++) {
            address _underlying = IGNft(_markets[i]).underlying();
            uint256 _nftCollateralAmount = lendPoolLoan.getUserNftCollateralAmount(user, _underlying);
            _totalCollateralAmount = _totalCollateralAmount.add(_nftCollateralAmount);
        }

        _myNftMarketStats.nftCollateralAmount = _totalCollateralAmount;
        _myNftMarketStats.totalBorrowInETH = _totalBorrowAmount;
        return _myNftMarketStats;
    }

    // My Dashboard - My Collection List
    function myNftMarketInfos(address user) external view override returns (MyNftMarketInfo[] memory) {
        address[] memory _markets = nftCore.allMarkets();
        address _user = user;
        uint256 _activeMarketCount = 0;

        for (uint256 i = 0; i < _markets.length; i++) {
            address _underlying = IGNft(_markets[i]).underlying();
            uint256 _nftCollateralAmount = lendPoolLoan.getUserNftCollateralAmount(_user, _underlying);
            if (_nftCollateralAmount > 0) {
                _activeMarketCount = _activeMarketCount.add(1);
            }
        }

        address[] memory _activeMarkets = new address[](_activeMarketCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < _markets.length; i++) {
            address _underlying = IGNft(_markets[i]).underlying();
            uint256 _nftCollateralAmount = lendPoolLoan.getUserNftCollateralAmount(_user, _underlying);
            if (_nftCollateralAmount > 0) {
                _activeMarkets[idx] = _markets[i];
                idx = idx + 1;
            }
        }

        MyNftMarketInfo[] memory _myNftMarketInfos = new MyNftMarketInfo[](_activeMarkets.length);
        for (uint256 i = 0; i < _activeMarkets.length; i++) {
            address _underlying = IGNft(_activeMarkets[i]).underlying();
            string memory _symbol = IERC721Metadata(_underlying).symbol();
            uint256 _nftCollateralAmount = lendPoolLoan.getUserNftCollateralAmount(_user, _underlying);
            uint256 _floorPrice = nftOracle.getUnderlyingPrice(_activeMarkets[i]);
            uint256 _totalBorrowInETH = lendPoolLoan.marketAccountBorrowBalance(_activeMarkets[i], _user);
            uint256 _collateralFactor = nftCore.marketInfoOf(_activeMarkets[i]).collateralFactor;
            uint256 _collateralValueInETH = _floorPrice.mul(_nftCollateralAmount).mul(_collateralFactor).div(1e18);
            uint256 _marketBorrowBalance = lendPoolLoan.marketBorrowBalance(_activeMarkets[i]);
            uint256 _borrowCap = nftCore.marketInfoOf(_activeMarkets[i]).borrowCap;

            uint256 _availableBorrowInETH = 0;

            if (_collateralValueInETH >= _totalBorrowInETH) {
                _availableBorrowInETH = _collateralValueInETH.sub(_totalBorrowInETH);
            }

            if (_marketBorrowBalance.add(_availableBorrowInETH) > _borrowCap) {
                _availableBorrowInETH = _marketBorrowBalance.add(_availableBorrowInETH).sub(_borrowCap);
            }

            _myNftMarketInfos[i] = MyNftMarketInfo({
                symbol: _symbol,
                availableBorrowInETH: _availableBorrowInETH,
                totalBorrowInETH: _totalBorrowInETH,
                nftCollateralAmount: _nftCollateralAmount,
                floorPrice: _floorPrice,
                marketBorrowBalance: _marketBorrowBalance,
                borrowCap: _borrowCap
            });
        }
        return _myNftMarketInfos;
    }

    // My Dashboard - My Collection List - View Details
    function userLoanInfos(address gNft, address user, uint256[] calldata loanIds) external view override returns (UserLoanInfo[] memory) {
        return _getUserLoanInfos(gNft, user, loanIds);
    }

    function calculateLiquidatePrice(address gNft, uint256 floorPrice, uint256 debt) external view override returns (uint256) {
        uint256 liquidationBonus = nftCore.marketInfoOf(gNft).liquidationBonus;
        uint256 bonusAmount = floorPrice.mul(liquidationBonus).div(1e18);

        uint256 liquidatePrice = floorPrice.sub(bonusAmount);

        if (liquidatePrice < debt) {
            uint256 bidDelta = debt.mul(1e16).div(1e18); // 1%
            liquidatePrice = debt.add(bidDelta).add(1e16); // 0.01ETH
        }
        return liquidatePrice;
    }

    function calculateBiddablePrice(uint256 debt, uint256 bidAmount) external view override returns (uint256) {
        uint256 bidDelta = debt.mul(1e16).div(1e18); // 1%
        return bidAmount.add(bidDelta).add(1e16); // 0.01ETH
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getUserTokenIds(address gNft, address user) private view returns (uint256[] memory) {
        address _underlying = IGNft(gNft).underlying();
        uint256 _balance = IERC721Upgradeable(_underlying).balanceOf(user);

        uint256[] memory tokenIds = new uint256[](_balance);
        tokenIds = INFT(_underlying).walletOfOwner(user);
        return tokenIds;
    }

    function _getUserLoanInfos(address gNft, address user, uint256[] calldata loanIds) private view returns (UserLoanInfo[] memory) {
        address _user = user;
        address _gNft = gNft;
        address _underlying = IGNft(_gNft).underlying();
        uint256 _currentLoanId = lendPoolLoan.currentLoanId();
        uint256 _userLoanCount = 0;
        uint256[] memory _loanIds = loanIds;

        if (_currentLoanId == 1) {
            return new UserLoanInfo[](0);
        }

        for (uint256 i = 0; i < _loanIds.length; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(_loanIds[i]);
            if (loan.nftAsset == _underlying &&
               (loan.state == Constant.LoanState.Active || loan.state == Constant.LoanState.Auction) &&
                loan.borrower == _user) {
                _userLoanCount = _userLoanCount.add(1);
            }
        }

        UserLoanInfo[] memory _userLoanInfos = new UserLoanInfo[](_userLoanCount);
        uint256 idx = 0;
        uint256 _nftAssetPrice = nftOracle.getUnderlyingPrice(_gNft);
        uint256 _liquidationThreshold = nftCore.marketInfoOf(_gNft).liquidationThreshold;
        uint256 _collateralFactor = nftCore.marketInfoOf(_gNft).collateralFactor;
        uint256 _redeemThreshold = lendPoolLoan.redeemThreshold();
        uint256 _minBidFine = lendPoolLoan.minBidFine();
        uint256 _redeemFineRate = lendPoolLoan.redeemFineRate();

        for (uint256 i = 0; i < _loanIds.length; i++) {
            Constant.LoanData memory loan = lendPoolLoan.getLoan(_loanIds[i]);
            if (loan.nftAsset == _underlying &&
               (loan.state == Constant.LoanState.Active || loan.state == Constant.LoanState.Auction) &&
                loan.borrower == _user) {
                uint256 _borrowBalance = lendPoolLoan.borrowBalanceOf(_loanIds[i]);
                uint256 _nftCollateralInETH = _nftAssetPrice.mul(_collateralFactor).div(1e18);
                uint256 _availableBorrowInETH = 0;
                uint256 _bidFineAmount = _borrowBalance.mul(_redeemFineRate).div(1e18);
                if (_bidFineAmount < _minBidFine) {
                    _bidFineAmount = _minBidFine;
                }

                if (_nftCollateralInETH > _borrowBalance) {
                    _availableBorrowInETH = _nftCollateralInETH.sub(_borrowBalance);
                }
                _userLoanInfos[idx] = UserLoanInfo({
                    loanId: loan.loanId,
                    state: loan.state,
                    tokenId: loan.nftTokenId,
                    healthFactor: _calculateHealthFactor(_nftAssetPrice, _borrowBalance, _liquidationThreshold),
                    debt: _borrowBalance,
                    liquidationPrice: _calculateLiquidationPrice(_borrowBalance, _liquidationThreshold),
                    collateralInETH: loan.state == Constant.LoanState.Active ? _nftCollateralInETH : 0,
                    availableBorrowInETH: _availableBorrowInETH,
                    bidPrice: loan.bidPrice,
                    minRepayAmount: loan.state == Constant.LoanState.Auction ? _borrowBalance.mul(_redeemThreshold).div(1e18) : 0,
                    maxRepayAmount: loan.state == Constant.LoanState.Auction ? _borrowBalance.mul(9e17).div(1e18) : 0,
                    repayPenalty: loan.state == Constant.LoanState.Auction ? _bidFineAmount : 0
                });
                idx = idx.add(1);
            }
        }
        return _userLoanInfos;
    }

    function _calculateHealthFactor(uint256 _totalCollateral, uint256 _totalDebt, uint256 _liquidationThreshold) private pure returns (uint256) {
        if (_totalDebt == 0) {
            return uint256(-1);
        }
        return (_totalCollateral.mul(_liquidationThreshold).mul(1e18).div(_totalDebt).div(1e18));
    }

    function _calculateLiquidationPrice(uint256 _totalDebt, uint256 _liquidationThreshold) private pure returns (uint256) {
        if (_totalDebt == 0) {
            return 0;
        }
        return (_totalDebt.mul(1e18).div(_liquidationThreshold));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IGrvPresale.sol";
import "../interfaces/IPresaleDashboard.sol";
import "../interfaces/IBEP20.sol";

contract PresaleDashboard is IPresaleDashboard {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    IGrvPresale public grvPresale;

    /* ========== INITIALIZER ========== */

    constructor(address _grvPresale) public {
        grvPresale = IGrvPresale(_grvPresale);
    }

    /* ========== VIEWS ========== */

    function receiveGrvAmount(uint256 _amount) external view override returns (uint256) {
        uint256 _adjustedAmount = _getAdjustedAmount(grvPresale.paymentCurrency(), _amount);
        uint256 _tokenPrice = grvPresale.tokenPrice();
        (uint256 _commitmentsTotal, , ) = grvPresale.marketStatus();
        uint256 _adjustedCommitmentsTotal = _getAdjustedAmount(grvPresale.paymentCurrency(), _commitmentsTotal);

        if (_tokenPrice == 0) {
            _tokenPrice = _adjustedAmount.mul(1e18).div(grvPresale.getTotalTokens());
        } else {
            _tokenPrice = _adjustedCommitmentsTotal.add(_adjustedAmount).mul(1e18).div(grvPresale.getTotalTokens());
        }

        return _adjustedAmount.mul(1e18).div(_tokenPrice);
    }

    function getPresaleInfo(address _user) external view override returns (PresaleData memory) {
        PresaleData memory presaleData;

        uint256 _commitments = grvPresale.commitments(_user);
        presaleData.commitmentAmount = _commitments;

        (uint256 _commitmentsTotal, uint256 _minimumCommitmentAmount, bool _finalized) = grvPresale.marketStatus();
        presaleData.commitmentsTotal = _commitmentsTotal;
        presaleData.minimumCommitmentAmount = _minimumCommitmentAmount;
        presaleData.finalized = _finalized;

        uint256 _tokenPrice = grvPresale.tokenPrice();

        if (_tokenPrice == 0) {
            _tokenPrice = uint256(1e18).mul(1e18).div(grvPresale.getTotalTokens());
        }

        uint256 _estimatedReceiveAmount;
        if (_commitmentsTotal == 0 || _commitments == 0) {
            _estimatedReceiveAmount = 0;
        } else {
            _estimatedReceiveAmount = _getAdjustedAmount(grvPresale.paymentCurrency(), _commitments).mul(1e18).div(_tokenPrice);
        }
        presaleData.estimatedReceiveAmount = _estimatedReceiveAmount;
        presaleData.exchangeRate = uint256(1e18).mul(1e18).div(_tokenPrice);
        presaleData.tokenPrice = _tokenPrice;
        presaleData.launchPrice = _tokenPrice.mul(20000).div(10000);

        (uint256 _startTime, uint256 _endTime, uint256 _totalTokens, ) = grvPresale.marketInfo();

        presaleData.startDate = _startTime;
        presaleData.endDate = _endTime;
        presaleData.totalTokens = _totalTokens;

        return presaleData;
    }

    function getVestingInfo(address _user) external view override returns (VestingData memory) {
        VestingData memory vestingData;

        (uint256 _commitmentsTotal, , ) = grvPresale.marketStatus();
        uint256 _commitments = grvPresale.commitments(_user);
        uint256 _tokenPrice = grvPresale.tokenPrice();

        if (_tokenPrice == 0) {
            _tokenPrice = uint256(1e18).mul(1e18).div(grvPresale.getTotalTokens());
        }

        if (_commitmentsTotal == 0 || _commitments == 0) {
            vestingData.totalPurchaseAmount = 0;
        } else {
            vestingData.totalPurchaseAmount = _getAdjustedAmount(grvPresale.paymentCurrency(), _commitments).mul(1e18).div(_tokenPrice);
        }

        vestingData.claimedAmount = grvPresale.claimed(_user);
        vestingData.claimableAmount = grvPresale.tokensClaimable(_user);

        return vestingData;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getAdjustedAmount(address token, uint256 amount) private view returns (uint256) {
        if (token == address(0)) {
            return amount;
        } else {
            uint256 defaultDecimal = 18;
            uint256 tokenDecimal = IBEP20(token).decimals();

            if (tokenDecimal == defaultDecimal) {
                return amount;
            } else if (tokenDecimal < defaultDecimal) {
                return amount * (10**(defaultDecimal - tokenDecimal));
            } else {
                return amount / (10**(tokenDecimal - defaultDecimal));
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IVoteDashboard.sol";
import "../interfaces/IDashboard.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IVoteController.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IGRVDistributor.sol";

contract VoteDashboard is IVoteDashboard, Ownable {
    using SafeMath for uint256;

    uint256 private constant weekUnit = uint256(60 * 60 * 24 * 7);
    uint256 private constant divider = 1e18 * weekUnit;

    /* ========== STATE VARIABLES ========== */

    IVoteController public voteController;
    ILocker public locker;
    IGRVDistributor public grvDistributor;
    IDashboard public dashboard;
    IPriceCalculator public priceCalculator;

    uint256 public totalWeekEmission;

    /* ========== INITIALIZER ========== */

    constructor(address _voteController, address _locker, address _grvDistributor,
                address _dashboard, address _priceCalculator, uint256 _totalWeekEmission) public {
        voteController = IVoteController(_voteController);
        locker = ILocker(_locker);
        grvDistributor = IGRVDistributor(_grvDistributor);
        dashboard = IDashboard(_dashboard);
        priceCalculator = IPriceCalculator(_priceCalculator);
        totalWeekEmission = _totalWeekEmission;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTotalWeekEmission(uint256 _totalWeekEmission) external onlyOwner {
        totalWeekEmission = _totalWeekEmission;
    }

    /* ========== VIEWS ========== */

    function votedGrvInfo(address user) external view override returns (VotedGrvInfo memory) {
        VotedGrvInfo memory _votedGrvInfo;
        (uint256 _totalScore, ) = locker.totalScore();
        uint256 _totalVotedGrvAmount = voteController.totalSupply();
        uint256 _totalVotedGrvRatio = _totalVotedGrvAmount.mul(1e18).div(_totalScore);

        uint256 _myScore = 0;
        uint256 _myVotedGrvAmount = 0;
        uint256 _myVotedGrvRatio = 0;

        if (user != address(0)) {
            _myScore = locker.scoreOf(user);
            _myVotedGrvAmount = voteController.balanceOf(user);
            _myVotedGrvRatio = _myVotedGrvAmount >= _myScore ? 1e18 : _myVotedGrvAmount.mul(1e18).div(_myScore);
        }

        _votedGrvInfo.totalVotedGrvAmount = _totalVotedGrvAmount;
        _votedGrvInfo.totalVotedGrvRatio = _totalVotedGrvRatio;
        _votedGrvInfo.myVotedGrvAmount = _myVotedGrvAmount;
        _votedGrvInfo.myVotedGrvRatio = _myVotedGrvRatio;

        return _votedGrvInfo;
    }

    function votingStatus(address user) external view override returns (VotingStatus[] memory) {
        address[] memory pools = voteController.getPools();
        VotingStatus[] memory _votingStatus = new VotingStatus[](pools.length);

        uint256 totalVotedGrvAmount = voteController.totalSupply();

        for (uint256 i = 0; i < pools.length; i++) {
            string memory symbol = _getSymbol(pools[i]);
            uint256 userWeight = voteController.userWeights(user, pools[i]);
            uint256 poolVotedAmount = voteController.sumAtTimestamp(pools[i], block.timestamp);
            uint256 poolVotedRate = totalVotedGrvAmount > 0 ? poolVotedAmount.mul(1e18).div(totalVotedGrvAmount) : 0;

            Constant.DistributionAPY memory apyDistribution = grvDistributor.apyDistributionOf(pools[i], address(0));
            uint256 poolSpeed = totalWeekEmission.mul(poolVotedRate).div(divider);
            uint256 supplySpeed = poolSpeed.mul(1e18).div(3e18);
            uint256 borrowSpeed = poolSpeed.mul(2e18).div(3e18);
            (uint256 toApySupplyGRV, uint256 toApyBorrowGRV) = _calculateMarketDistributionAPY(pools[i], supplySpeed, borrowSpeed);

            _votingStatus[i].symbol = symbol;
            _votingStatus[i].userWeight = userWeight;
            _votingStatus[i].poolVotedRate = poolVotedRate;
            _votingStatus[i].fromGrvSupplyAPR = apyDistribution.apySupplyGRV;
            _votingStatus[i].fromGrvBorrowAPR = apyDistribution.apyBorrowGRV;
            _votingStatus[i].toGrvSupplyAPR = toApySupplyGRV;
            _votingStatus[i].toGrvBorrowAPR = toApyBorrowGRV;
        }
        return _votingStatus;
    }

    function _calculateMarketDistributionAPY(
        address market,
        uint256 supplySpeed,
        uint256 borrowSpeed
    ) private view returns (uint256 apySupplyGRV, uint256 apyBorrowGRV) {
        address _market = market;
        uint256 decimals = _getDecimals(_market);
        // base supply GRV APY == average supply GRV APY * (Total balance / total Boosted balance)
        // base supply GRV APY == (GRVRate * 365 days * price Of GRV) / (Total balance * exchangeRate * price of asset) * (Total balance / Total Boosted balance)
        // base supply GRV APY == (GRVRate * 365 days * price Of GRV) / (Total boosted balance * exchangeRate * price of asset)
        {
            uint256 numerSupply = supplySpeed.mul(365 days).mul(dashboard.getCurrentGRVPrice());
            uint256 denomSupply = grvDistributor.distributionInfoOf(_market)
            .totalBoostedSupply
            .mul(10 ** (18 - decimals))
            .mul(IGToken(_market).exchangeRate())
            .mul(priceCalculator.getUnderlyingPrice(_market))
            .div(1e36);
            apySupplyGRV = denomSupply > 0 ? numerSupply.div(denomSupply) : 0;
        }

        // base borrow GRV APY == average borrow GRV APY * (Total balance / total Boosted balance)
        // base borrow GRV APY == (GRVRate * 365 days * price Of GRV) / (Total balance * exchangeRate * price of asset) * (Total balance / Total Boosted balance)
        // base borrow GRV APY == (GRVRate * 365 days * price Of GRV) / (Total boosted balance * exchangeRate * price of asset)
        {
            uint256 numerBorrow = borrowSpeed.mul(365 days).mul(dashboard.getCurrentGRVPrice());
            uint256 denomBorrow = grvDistributor.distributionInfoOf(_market)
            .totalBoostedBorrow
            .mul(10 ** (18 - decimals))
            .mul(IGToken(_market).getAccInterestIndex())
            .mul(priceCalculator.getUnderlyingPrice(_market))
            .div(1e36);
            apyBorrowGRV = denomBorrow > 0 ? numerBorrow.div(denomBorrow) : 0;
        }
    }

    function _getSymbol(address gToken) internal view returns (string memory symbol) {
        address underlying = IGToken(gToken).underlying();
        if (underlying == address(0)) {
            symbol = "ETH";
        } else {
            symbol = IBEP20(underlying).symbol();
        }
    }

    function _getDecimals(address gToken) internal view returns (uint256 decimals) {
        address underlying = IGToken(gToken).underlying();
        if (underlying == address(0)) {
            decimals = 18;
            // ETH
        } else {
            decimals = IBEP20(underlying).decimals();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../library/Math.sol";

import "../interfaces/IBEP20.sol";
import "../interfaces/IZapDashboard.sol";
import "../interfaces/IZap.sol";
import "../interfaces/IWhiteholePair.sol";
import "../interfaces/ILpVaultDashboard.sol";
import "../interfaces/IDashboard.sol";
import "../interfaces/IWhiteholeRouter.sol";

contract ZapDashboard is IZapDashboard {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    IZap public zap;
    IWhiteholePair public GRV_USDC_LP;
    IWhiteholeRouter public whiteholeRouter;
    ILpVaultDashboard public lpVaultDashboard;
    address public GRV;

    /* ========== INITIALIZER ========== */

    constructor(
        address _zap,
        address _GRV_USDC_LP,
        address _whiteholeRouter,
        address _GRV,
        address _lpVaultDashboard
    ) public {
        zap = IZap(_zap);
        GRV_USDC_LP = IWhiteholePair(_GRV_USDC_LP);
        whiteholeRouter = IWhiteholeRouter(_whiteholeRouter);
        GRV = _GRV;
        lpVaultDashboard = ILpVaultDashboard(_lpVaultDashboard);
    }

    /* ========== VIEWS ========== */

    function estimatedReceiveLpData(address _token, uint256 _amount) external view override returns (uint256, uint256) {
        address token0 = GRV_USDC_LP.token0();
        uint256 _tokenAmount = _amount;

        uint256 _sellAmount = _amount.div(2);

        (uint256 _reserve0, uint256 _reserve1, ) = GRV_USDC_LP.getReserves();

        uint256 _otherAmount;
        if (_token == token0) {
            _otherAmount = whiteholeRouter.getAmountOut(_sellAmount, _reserve0, _reserve1);
        } else {
            _otherAmount = whiteholeRouter.getAmountOut(_sellAmount, _reserve1, _reserve0);
        }

        uint256 _liquidity;
        uint256 _lpTotalSupply = GRV_USDC_LP.totalSupply();

        if (_lpTotalSupply == 0) {
            _liquidity = Math.sqrt(_tokenAmount.sub(_sellAmount).mul(_otherAmount)).sub(GRV_USDC_LP.MINIMUM_LIQUIDITY());
        } else {
            uint256 amount0;
            uint256 amount1;

            if (token0 == GRV) {
                if (_token == GRV) { // token0 is GRV, sell token is GRV
                    amount0 = _tokenAmount.sub(_sellAmount);
                    amount1 = _otherAmount;
                } else { // token0 is GRV, sell token is USDC
                    amount0 = _otherAmount;
                    amount1 = _tokenAmount.sub(_sellAmount);
                }
            } else {
                if (_token == GRV) { // token0 is USDC, sell token is GRV
                    amount0 = _otherAmount;
                    amount1 = _tokenAmount.sub(_sellAmount);
                } else { // token0 is USDC, sell token is USDC
                    amount0 = _tokenAmount.sub(_sellAmount);
                    amount1 = _otherAmount;
                }
            }
            _liquidity = Math.min(amount0.mul(_lpTotalSupply) / _reserve0, amount1.mul(_lpTotalSupply) / _reserve1);
        }
        return (_liquidity, lpVaultDashboard.calculateLpValueInUSD(_liquidity));
    }

    function getLiquidityInfo(
        address token,
        uint256 tokenAmount
    ) external view override returns (uint256, uint256) {
        if (tokenAmount == 0) {
            return (0, 0);
        }
        (uint256 _reserve0, uint256 _reserve1, ) = GRV_USDC_LP.getReserves();

        uint256 _lpTotalSupply = GRV_USDC_LP.totalSupply();

        uint256 _quote;
        uint256 _liquidity;

        if (token == GRV_USDC_LP.token0()) {
            _quote = whiteholeRouter.quote(tokenAmount, _reserve0, _reserve1);
        } else {
            _quote = whiteholeRouter.quote(tokenAmount, _reserve1, _reserve0);
        }

        if (_lpTotalSupply == 0) {
            _liquidity = Math.sqrt(tokenAmount.mul(_quote)).sub(GRV_USDC_LP.MINIMUM_LIQUIDITY());
        } else {
            if (token == GRV_USDC_LP.token0()) {
                _liquidity = Math.min(tokenAmount.mul(_lpTotalSupply) / _reserve0, _quote.mul(_lpTotalSupply) / _reserve1);
            } else {
                _liquidity = Math.min(tokenAmount.mul(_lpTotalSupply) / _reserve1, _quote.mul(_lpTotalSupply) / _reserve0);
            }
        }
        return (_quote, _liquidity);
    }

    function getTokenAmount(
        uint256 tokenAmount
    ) external view override returns (uint256, uint256) {
        if (tokenAmount == 0) {
            return (0, 0);
        }
        uint256 balance0 = IBEP20(GRV_USDC_LP.token0()).balanceOf(address(GRV_USDC_LP));
        uint256 balance1 = IBEP20(GRV_USDC_LP.token1()).balanceOf(address(GRV_USDC_LP));

        uint256 liquidity = tokenAmount;
        uint256 totalSupply = GRV_USDC_LP.totalSupply();

        uint256 token0Amount = liquidity.mul(balance0).div(totalSupply);
        uint256 token1Amount = liquidity.mul(balance1).div(totalSupply);

        return (token0Amount, token1Amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract WhiteholeERC20 {
    using SafeMath for uint256;

    string public constant name = "Whitehole LPs";
    string public constant symbol = "Whitehole-LP";
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "WHITEHOLE: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "WHITEHOLE: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "../interfaces/IWhiteholeFactory.sol";
import "./WhiteholePair.sol";

contract WhiteholeFactory is IWhiteholeFactory {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(WhiteholePair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "WHITEHOLE: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "WHITEHOLE: ZERO_ADDRESSES");
        require(getPair[token0][token1] == address(0), "WHITEHOLE: PAIR_EXISTS");
        bytes memory bytecode = type(WhiteholePair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        WhiteholePair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "WHITEHOLE: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "WHITEHOLE: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "./WhiteholeERC20.sol";
import "../library/Math.sol";
import "../library/UQ112x112.sol";
import "../interfaces/IWhiteholeFactory.sol";
import "../interfaces/IWhiteholeCallee.sol";
import "../interfaces/IBEP20.sol";

contract WhiteholePair is WhiteholeERC20 {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast;

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "WHITEHOLE: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "WHITEHOLE: TRANSFER_FAILED");
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "WHITEHOLE: FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
    }

    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), "WHITEHOLE: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 8/25 of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IWhiteholeFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(8);
                    uint256 denominator = rootK.mul(17).add(rootKLast.mul(8));
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IBEP20(token0).balanceOf(address(this));
        uint256 balance1 = IBEP20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }

        require(liquidity > 0, "WHITEHOLE: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IBEP20(_token0).balanceOf(address(this));
        uint256 balance1 = IBEP20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "WHITEHOLE: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IBEP20(_token0).balanceOf(address(this));
        balance1 = IBEP20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, "WHITEHOLE: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "WHITEHOLE: INSUFFICIENT_LIQUIDITY");

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "WHITEHOLE: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IWhiteholeCallee(to).whiteholeCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IBEP20(_token0).balanceOf(address(this));
            balance1 = IBEP20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "WHITEHOLE: INSUFFICIENT_INPUT_AMOUNT");
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(10000).sub(amount0In.mul(25));
            uint256 balance1Adjusted = balance1.mul(10000).sub(amount1In.mul(25));
            require(
                balance0Adjusted.mul(balance1Adjusted) >= uint256(_reserve0).mul(_reserve1).mul(10000 ** 2),
                "WHITEHOLE: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IBEP20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IBEP20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IBEP20(token0).balanceOf(address(this)), IBEP20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function decimals() external view returns (uint256) {
        uint256 _token0Decimals = IBEP20(token0).decimals();
        uint256 _token0UnitAmount = 10 ** _token0Decimals;

        uint256 _token1Decimals = IBEP20(token1).decimals();
        uint256 _token1UnitAmount = 10 ** _token1Decimals;

        uint256 _lpTokenUnitAmount = Math.sqrt(_token0UnitAmount * _token1UnitAmount);

        uint256 _decimals = 1;
        if (_lpTokenUnitAmount == 1e18) {
            return 18;
        } else {
            while (_lpTokenUnitAmount > 10) {
                _lpTokenUnitAmount = _lpTokenUnitAmount / 10;
                _decimals = _decimals + 1;
            }
        }
        return _decimals;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "../library/WhiteholeLibrary.sol";
import "../library/SafeToken.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IWhiteholeFactory.sol";
import "../interfaces/IWhiteholeRouter.sol";

contract WhiteholeRouter is IWhiteholeRouter {
    using SafeMath for uint256;
    using SafeToken for address;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "WhiteholeRouter: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IWhiteholeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IWhiteholeFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = WhiteholeLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = WhiteholeLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "WhiteholeRouter: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = WhiteholeLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "WhiteholeRouter: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    // Adds liquidity to an ERC20-ERC20 Pool
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = WhiteholeLibrary.pairFor(factory, tokenA, tokenB);
        SafeToken.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        SafeToken.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IWhiteholePair(pair).mint(to);
    }

    // Adds liquidity to an ERC20-WETH Pool with ETH
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );

        address pair = WhiteholeLibrary.pairFor(factory, token, WETH);
        SafeToken.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IWhiteholePair(pair).mint(to);
        // refund dust ETH, if any
        if (msg.value > amountETH) SafeToken.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = WhiteholeLibrary.pairFor(factory, tokenA, tokenB);

        IWhiteholePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IWhiteholePair(pair).burn(to);
        (address token0, ) = WhiteholeLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "WhiteholeRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "WhiteholeRouter: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        SafeToken.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        SafeToken.safeTransferETH(to, amountETH);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = WhiteholeLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? WhiteholeLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IWhiteholePair(WhiteholeLibrary.pairFor(factory, input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = WhiteholeLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "WhiteholeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        SafeToken.safeTransferFrom(
            path[0],
            msg.sender,
            WhiteholeLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = WhiteholeLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "WhiteholeRouter: EXCESSIVE_INPUT_AMOUNT");
        SafeToken.safeTransferFrom(
            path[0],
            msg.sender,
            WhiteholeLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WETH, "WhiteholeRouter: INVALID_PATH");
        amounts = WhiteholeLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "WhiteholeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(WhiteholeLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "WhiteholeRouter: INVALID_PATH");
        amounts = WhiteholeLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "WhiteholeRouter: EXCESSIVE_INPUT_AMOUNT");
        SafeToken.safeTransferFrom(
            path[0],
            msg.sender,
            WhiteholeLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        SafeToken.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "WhiteholeRouter: INVALID_PATH");
        amounts = WhiteholeLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "WhiteholeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        SafeToken.safeTransferFrom(
            path[0],
            msg.sender,
            WhiteholeLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        SafeToken.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WETH, "WhiteholeRouter: INVALID_PATH");
        amounts = WhiteholeLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, "WhiteholeRouter: EXCESSIVE_INPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(WhiteholeLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust ETH, if any
        if (msg.value > amounts[0]) SafeToken.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual override returns (uint256 amountB) {
        return WhiteholeLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountOut) {
        return WhiteholeLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountIn) {
        return WhiteholeLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) public view virtual override returns (uint256[] memory amounts) {
        return WhiteholeLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(
        uint256 amountOut,
        address[] memory path
    ) public view virtual override returns (uint256[] memory amounts) {
        return WhiteholeLibrary.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IVoteController.sol";
import "../interfaces/ILocker.sol";

import "../library/SafeDecimalMath.sol";

contract VoteController is IVoteController, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 public constant LOCK_UNIT_MAX = 2 * 365 days; // 2 years
    uint256 public constant LOCK_UNIT_BASE = 7 days;

    /* ========== STATE VARIABLES ========== */

    ILocker public locker;

    address[65535] private _pools;
    uint256 public poolSize;
    uint256 public disabledPoolSize;

    // Locked balance of an account, which is synchronized with locker
    mapping(address => IVoteController.LockedBalance) public userLockedBalances;

    // mapping of account => pool => fraction of the user's veGRV voted to the pool
    mapping(address => mapping(address => uint256)) public override userWeights;

    // mapping of pool => unlockTime => GRV amount voted to the pool that will be unlock at unlockTime
    mapping(address => mapping(uint256 => uint256)) public poolScheduledUnlock;

    // mapping of pool index => status of the pool
    mapping(uint256 => bool) public disabledPools;

    /* ========== INITIALIZER ========== */

    function initialize(address _locker) external initializer {
        __Ownable_init();
        locker = ILocker(_locker);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addPool(address newPool) external override onlyOwner {
        uint256 size = poolSize;
        _pools[size] = newPool;
        poolSize = size + 1;
        emit PoolAdded(newPool);
    }

    function togglePool(uint256 index) external override onlyOwner {
        require(index < poolSize, "Invalid index");
        if (disabledPools[index]) {
            disabledPools[index] = false;
            disabledPoolSize--;
        } else {
            disabledPools[index] = true;
            disabledPoolSize++;
        }
        emit PoolToggled(_pools[index], disabledPools[index]);
    }

    /* ========== VIEWS ========== */

    function getPools() external view override returns (address[] memory) {
        uint256 size = poolSize;
        address[] memory pools = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            pools[i] = _pools[i];
        }
        return pools;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balanceOfAtTimestamp(account, block.timestamp);
    }

    function balanceOfAtTimestamp(address account, uint256 timestamp) public view returns (uint256) {
        require(timestamp >= block.timestamp, "Must be current or future time");
        IVoteController.LockedBalance memory locked = userLockedBalances[account];
        if (timestamp >= locked.unlockTime) {
            return 0;
        }
        return locked.amount.mul(locked.unlockTime - timestamp) / LOCK_UNIT_MAX;
    }

    function totalSupply() external view override returns (uint256) {
        return totalSupplyAtTimestamp(block.timestamp);
    }

    function totalSupplyAtTimestamp(uint256 timestamp) public view returns (uint256) {
        uint256 size = poolSize;
        uint256 total = 0;
        for (uint256 i = 0; i < size; i++) {
            total = total.add(sumAtTimestamp(_pools[i], timestamp));
        }
        return total;
    }

    function sumAtTimestamp(address pool, uint256 timestamp) public view override returns (uint256) {
        uint256 sum = 0;
        for (
            uint256 weekCursor = _truncateExpiry(timestamp);
            weekCursor <= timestamp + LOCK_UNIT_MAX;
            weekCursor += 1 weeks
        ) {
            sum = sum.add(poolScheduledUnlock[pool][weekCursor].mul(weekCursor - timestamp) / LOCK_UNIT_MAX);
        }
        return sum;
    }

    function count(
        uint256 timestamp
    ) external view override returns (uint256[] memory weights, address[] memory pools) {
        uint256 poolSize_ = poolSize;
        uint256 size = poolSize_ - disabledPoolSize;
        pools = new address[](size);
        uint256 j = 0;
        for (uint256 i = 0; i < poolSize_ && j < size; i++) {
            address pool = _pools[i];
            if (!disabledPools[i]) pools[j++] = pool;
        }

        uint256[] memory sums = new uint256[](size);
        uint256 total = 0;
        for (uint256 i = 0; i < size; i++) {
            uint256 sum = sumAtTimestamp(pools[i], timestamp);
            sums[i] = sum;
            total = total.add(sum);
        }

        weights = new uint256[](size);
        if (total == 0) {
            for (uint256 i = 0; i < size; i++) {
                weights[i] = 1e18 / size;
            }
        } else {
            for (uint256 i = 0; i < size; i++) {
                weights[i] = sums[i].divideDecimal(total);
            }
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function cast(uint256[] memory weights) external override {
        uint256 size = poolSize;
        require(weights.length == size, "Invalid number of weights");
        uint256 totalWeight;
        for (uint256 i = 0; i < size; i++) {
            totalWeight = totalWeight.add(weights[i]);
        }
        require(totalWeight == 1e18, "Invalid weights");

        uint256[] memory oldWeights = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            oldWeights[i] = userWeights[msg.sender][_pools[i]];
        }

        IVoteController.LockedBalance memory oldLockedBalance = userLockedBalances[msg.sender];

        uint256 lockedAmount = locker.balanceOf(msg.sender);
        uint256 unlockTime = locker.expiryOf(msg.sender);

        IVoteController.LockedBalance memory lockedBalance = IVoteController.LockedBalance({
            amount: lockedAmount,
            unlockTime: unlockTime
        });

        require(lockedBalance.amount > 0 && lockedBalance.unlockTime > block.timestamp, "No veGRV");

        _updateVoteStatus(msg.sender, size, oldWeights, weights, oldLockedBalance, lockedBalance);
    }

    function syncWithLocker(address account) external override {
        IVoteController.LockedBalance memory oldLockedBalance = userLockedBalances[account];
        if (oldLockedBalance.amount == 0) {
            return; // The account did not voted before
        }

        uint256 lockedAmount = locker.balanceOf(msg.sender);
        uint256 unlockTime = locker.expiryOf(msg.sender);

        IVoteController.LockedBalance memory lockedBalance = IVoteController.LockedBalance({
            amount: lockedAmount,
            unlockTime: unlockTime
        });

        uint256 size = poolSize;
        uint256[] memory weights = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            weights[i] = userWeights[account][_pools[i]];
        }

        _updateVoteStatus(account, size, weights, weights, oldLockedBalance, lockedBalance);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _updateVoteStatus(
        address account,
        uint256 size,
        uint256[] memory oldWeights,
        uint256[] memory weights,
        IVoteController.LockedBalance memory oldLockedBalance,
        IVoteController.LockedBalance memory lockedBalance
    ) private {
        for (uint256 i = 0; i < size; i++) {
            address pool = _pools[i];
            poolScheduledUnlock[pool][oldLockedBalance.unlockTime] = poolScheduledUnlock[pool][
                oldLockedBalance.unlockTime
            ].sub(oldLockedBalance.amount.multiplyDecimal(oldWeights[i]));

            poolScheduledUnlock[pool][lockedBalance.unlockTime] = poolScheduledUnlock[pool][lockedBalance.unlockTime]
                .add(lockedBalance.amount.multiplyDecimal(weights[i]));
            userWeights[account][pool] = weights[i];
        }
        userLockedBalances[account] = lockedBalance;
        emit Voted(
            account,
            oldLockedBalance.amount,
            oldLockedBalance.unlockTime,
            oldWeights,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            weights
        );
    }

    function _truncateExpiry(uint256 time) private view returns (uint256) {
        if (time > block.timestamp.add(LOCK_UNIT_MAX)) {
            time = block.timestamp.add(LOCK_UNIT_MAX);
        }
        return (time.div(LOCK_UNIT_BASE).mul(LOCK_UNIT_BASE)).add(LOCK_UNIT_BASE);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./library/BEP20Upgradeable.sol";

contract GRVToken is BEP20Upgradeable {
    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private _minters;

    /* ========== MODIFIERS ========== */

    modifier onlyMinter() {
        require(isMinter(msg.sender), "GRV: caller is not the minter");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __BEP20__init("Gravity Token", "GRV", 18);
        _minters[owner()] = true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address minter, bool canMint) external onlyOwner {
        _minters[minter] = canMint;
    }

    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }

    /* ========== VIEWS ========== */

    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface ICore {
    /* ========== Event ========== */
    event MarketSupply(address user, address gToken, uint256 uAmount);
    event MarketRedeem(address user, address gToken, uint256 uAmount);

    event MarketListed(address gToken);
    event MarketEntered(address gToken, address account);
    event MarketExited(address gToken, address account);

    event CloseFactorUpdated(uint256 newCloseFactor);
    event CollateralFactorUpdated(address gToken, uint256 newCollateralFactor);
    event LiquidationIncentiveUpdated(uint256 newLiquidationIncentive);
    event SupplyCapUpdated(address indexed gToken, uint256 newSupplyCap);
    event BorrowCapUpdated(address indexed gToken, uint256 newBorrowCap);
    event KeeperUpdated(address newKeeper);
    event NftCoreUpdated(address newNftCore);
    event ValidatorUpdated(address newValidator);
    event GRVDistributorUpdated(address newGRVDistributor);
    event RebateDistributorUpdated(address newRebateDistributor);
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium
    );

    function nftCore() external view returns (address);

    function validator() external view returns (address);

    function rebateDistributor() external view returns (address);

    function allMarkets() external view returns (address[] memory);

    function marketListOf(address account) external view returns (address[] memory);

    function marketInfoOf(address gToken) external view returns (Constant.MarketInfo memory);

    function checkMembership(address account, address gToken) external view returns (bool);

    function accountLiquidityOf(
        address account
    ) external view returns (uint256 collateralInUSD, uint256 supplyInUSD, uint256 borrowInUSD);

    function closeFactor() external view returns (uint256);

    function liquidationIncentive() external view returns (uint256);

    function enterMarkets(address[] memory gTokens) external;

    function exitMarket(address gToken) external;

    function supply(address gToken, uint256 underlyingAmount) external payable returns (uint256);

    function redeemToken(address gToken, uint256 gTokenAmount) external returns (uint256 redeemed);

    function redeemUnderlying(address gToken, uint256 underlyingAmount) external returns (uint256 redeemed);

    function borrow(address gToken, uint256 amount) external;

    function nftBorrow(address gToken, address user, uint256 amount) external;

    function repayBorrow(address gToken, uint256 amount) external payable;

    function nftRepayBorrow(address gToken, address user, uint256 amount) external payable;

    function repayBorrowBehalf(address gToken, address borrower, uint256 amount) external payable;

    function liquidateBorrow(
        address gTokenBorrowed,
        address gTokenCollateral,
        address borrower,
        uint256 amount
    ) external payable;

    function claimGRV() external;

    function claimGRV(address market) external;

    function compoundGRV() external;

    function firstDepositGRV(uint256 expiry) external;

    function transferTokens(address spender, address src, address dst, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IDashboard {
    struct VaultData {
        uint256 totalCirculation;
        uint256 totalLockedGrv;
        uint256 totalVeGrv;
        uint256 averageLockDuration;
        uint256 accruedGrv;
        uint256 claimedGrv;
        uint256[] thisWeekRebatePoolAmounts;
        address[] thisWeekRebatePoolMarkets;
        uint256 thisWeekRebatePoolValue;
        Constant.EcoZone ecoZone;
        uint256 claimTax;
        uint256 ppt;
        uint256 ecoDR;
        uint256 lockedBalance;
        uint256 lockDuration;
        uint256 firstLockTime;
        uint256 myVeGrv;
        uint256 vp;
        RebateData rebateData;
    }

    struct RebateData {
        uint256 weeklyProfit;
        uint256 unClaimedRebateValue;
        address[] unClaimedMarkets;
        uint256[] unClaimedRebatesAmount;
        uint256 claimedRebateValue;
        address[] claimedMarkets;
        uint256[] claimedRebatesAmount;
    }
    struct CompoundData {
        ExpectedTaxData taxData;
        ExpectedEcoScoreData ecoScoreData;
        ExpectedVeGrv veGrvData;
        BoostedAprData boostedAprData;
        uint256 accruedGrv;
        uint256 lockDuration;
        uint256 nextLockDuration;
    }

    struct LockData {
        ExpectedEcoScoreData ecoScoreData;
        ExpectedVeGrv veGrvData;
        BoostedAprData boostedAprData;
        uint256 lockedGrv;
        uint256 lockDuration;
        uint256 nextLockDuration;
    }

    struct ClaimData {
        ExpectedEcoScoreData ecoScoreData;
        ExpectedTaxData taxData;
        uint256 accruedGrv;
    }

    struct ExpectedTaxData {
        uint256 prevPPTRate;
        uint256 nextPPTRate;
        uint256 prevClaimTaxRate;
        uint256 nextClaimTaxRate;
        uint256 discountTaxRate;
        uint256 afterTaxesGrv;
    }

    struct ExpectedEcoScoreData {
        Constant.EcoZone prevEcoZone;
        Constant.EcoZone nextEcoZone;
        uint256 prevEcoDR;
        uint256 nextEcoDR;
    }

    struct ExpectedVeGrv {
        uint256 prevVeGrv;
        uint256 prevVotingPower;
        uint256 nextVeGrv;
        uint256 nextVotingPower;
        uint256 nextWeeklyRebate;
        uint256 prevWeeklyRebate;
    }

    struct BoostedAprParams {
        address account;
        uint256 amount;
        uint256 expiry;
        Constant.EcoScorePreviewOption option;
    }

    struct BoostedAprData {
        BoostedAprDetails[] boostedAprDetailList;
    }
    struct BoostedAprDetails {
        address market;
        uint256 currentSupplyApr;
        uint256 currentBorrowApr;
        uint256 expectedSupplyApr;
        uint256 expectedBorrowApr;
    }

    function getCurrentGRVPrice() external view returns (uint256);
    function getVaultInfo(address account) external view returns (VaultData memory);
    function getLockUnclaimedGrvModalInfo(address account) external view returns (CompoundData memory);

    function getInitialLockUnclaimedGrvModalInfo(
        address account,
        uint256 expiry
    ) external view returns (CompoundData memory);

    function getLockModalInfo(
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (LockData memory);

    function getClaimModalInfo(address account) external view returns (ClaimData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IEcoScore {
    event SetGRVDistributor(address newGRVDistributor);
    event SetPriceProtectionTaxCalculator(address newPriceProtectionTaxCalculator);
    event SetPriceCalculator(address priceCalculator);
    event SetLendPoolLoan(address lendPoolLoan);
    event SetEcoPolicyInfo(
        Constant.EcoZone _zone,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] _pptTax
    );
    event SetAccountCustomEcoPolicy(
        address indexed account,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] _pptTax
    );
    event RemoveAccountCustomEcoPolicy(address indexed account);
    event ExcludeAccount(address indexed account);
    event IncludeAccount(address indexed account);
    event SetEcoZoneStandard(
        uint256 _minExpiryOfGreenZone,
        uint256 _minExpiryOfLightGreenZone,
        uint256 _minDrOfGreenZone,
        uint256 _minDrOfLightGreenZone,
        uint256 _minDrOfYellowZone,
        uint256 _minDrOfOrangeZone
    );
    event SetPPTPhaseInfo(uint256 _phase1, uint256 _phase2, uint256 _phase3, uint256 _phase4);

    function setGRVDistributor(address _grvDistributor) external;

    function setPriceProtectionTaxCalculator(address _priceProtectionTaxCalculator) external;

    function setPriceCalculator(address _priceCalculator) external;

    function setLendPoolLoan(address _lendPoolLoan) external;

    function setEcoPolicyInfo(
        Constant.EcoZone _zone,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] calldata _pptTax
    ) external;

    function setAccountCustomEcoPolicy(
        address account,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] calldata _pptTax
    ) external;

    function setEcoZoneStandard(
        uint256 _minExpiryOfGreenZone,
        uint256 _minExpiryOfLightGreenZone,
        uint256 _minDrOfGreenZone,
        uint256 _minDrOfLightGreenZone,
        uint256 _minDrOfYellowZone,
        uint256 _minDrOfOrangeZone
    ) external;

    function setPPTPhaseInfo(uint256 _phase1, uint256 _phase2, uint256 _phase3, uint256 _phase4) external;

    function removeAccountCustomEcoPolicy(address account) external;

    function excludeAccount(address account) external;

    function includeAccount(address account) external;

    function calculateEcoBoostedSupply(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) external view returns (uint256);

    function calculateEcoBoostedBorrow(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) external view returns (uint256);

    function calculatePreEcoBoostedSupply(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore,
        Constant.EcoZone ecoZone
    ) external view returns (uint256);

    function calculatePreEcoBoostedBorrow(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore,
        Constant.EcoZone ecoZone
    ) external view returns (uint256);

    function calculateCompoundTaxes(
        address account,
        uint256 value,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (uint256 adjustedValue, uint256 taxAmount);

    function calculateClaimTaxes(
        address account,
        uint256 value
    ) external view returns (uint256 adjustedValue, uint256 taxAmount);

    function getClaimTaxRate(
        address account,
        uint256 value,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (uint256);

    function getDiscountTaxRate(address account) external view returns (uint256);

    function getPptTaxRate(Constant.EcoZone ecoZone) external view returns (uint256 pptTaxRate, uint256 gapPercent);

    function getEcoZone(uint256 ecoDRpercent, uint256 remainExpiry) external view returns (Constant.EcoZone ecoZone);

    function updateUserClaimInfo(address account, uint256 amount) external;

    function updateUserCompoundInfo(address account, uint256 amount) external;

    function updateUserEcoScoreInfo(address account) external;

    function accountEcoScoreInfoOf(address account) external view returns (Constant.EcoScoreInfo memory);

    function ecoPolicyInfoOf(Constant.EcoZone zone) external view returns (Constant.EcoPolicyInfo memory);

    function calculatePreUserEcoScoreInfo(
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (Constant.EcoZone ecoZone, uint256 ecoDR, uint256 userScore);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

/**
 * @title IFlashLoanReceiver
 * @author Aave
 * @notice Defines the basic interface of a flashloan-receiver contract.
 * @dev Implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 */
interface IFlashLoanReceiver {
    /**
     * @notice Executes an operation after receiving the flash-borrowed assets
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     * @param assets The addresses of the flash-borrowed assets
     * @param amounts The amounts of the flash-borrowed assets
     * @param premiums The fee of each flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IGenesisRewardDistributor {
    function withdrawTokens() external;
    function withdrawToLocker() external;

    function tokensClaimable(address _user) external view returns (uint256 claimableAmount);
    function tokensLockable(address _user) external view returns (uint256 lockableAmount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IGNft {
    /* ========== Event ========== */
    event Mint(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);
    event Burn(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);


    function underlying() external view returns (address);
    function minterOf(uint256 tokenId) external view returns (address);

    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IGRVDistributor {
    /* ========== EVENTS ========== */
    event SetCore(address core);
    event SetPriceCalculator(address priceCalculator);
    event SetEcoScore(address ecoScore);
    event SetTaxTreasury(address treasury);
    event GRVDistributionSpeedUpdated(address indexed gToken, uint256 supplySpeed, uint256 borrowSpeed);
    event GRVClaimed(address indexed user, uint256 amount);
    event GRVCompound(
        address indexed account,
        uint256 amount,
        uint256 adjustedValue,
        uint256 taxAmount,
        uint256 expiry
    );
    event SetDashboard(address dashboard);
    event SetLendPoolLoan(address lendPoolLoan);

    function approve(address _spender, uint256 amount) external returns (bool);

    function accruedGRV(address[] calldata markets, address account) external view returns (uint256);

    function distributionInfoOf(address market) external view returns (Constant.DistributionInfo memory);

    function accountDistributionInfoOf(
        address market,
        address account
    ) external view returns (Constant.DistributionAccountInfo memory);

    function apyDistributionOf(address market, address account) external view returns (Constant.DistributionAPY memory);

    function boostedRatioOf(
        address market,
        address account
    ) external view returns (uint256 boostedSupplyRatio, uint256 boostedBorrowRatio);

    function notifySupplyUpdated(address market, address user) external;

    function notifyBorrowUpdated(address market, address user) external;

    function notifyTransferred(address gToken, address sender, address receiver) external;

    function claimGRV(address[] calldata markets, address account) external;

    function compound(address[] calldata markets, address account) external;

    function firstDeposit(address[] calldata markets, address account, uint256 expiry) external;

    function kick(address user) external;
    function kicks(address[] calldata users) external;

    function updateAccountBoostedInfo(address user) external;
    function updateAccountBoostedInfos(address[] calldata users) external;

    function getTaxTreasury() external view returns (address);

    function getPreEcoBoostedInfo(
        address market,
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (uint256 boostedSupply, uint256 boostedBorrow);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IGrvPresale {
    struct MarketInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 totalTokens;
        uint256 commitmentCap;
    }

    struct MarketStatus {
        uint256 commitmentsTotal;
        uint256 minimumCommitmentAmount;
        bool finalized;
    }

    event AuctionTokenDeposited(uint256 amount);
    event AuctionTimeUpdated(uint256 startTime, uint256 endTime);
    event EndTimeUpdated(uint256 endTime);
    event AuctionPriceUpdated(uint256 minimumCommitmentAmount);
    event AuctionTreasuryUpdated(address treasury);
    event LockerUpdated(address locker);

    event AddedCommitment(address addr, uint256 commitment);
    event AuctionFinalized();
    event AuctionCancelled();

    function commitETH(address payable _beneficiary) external payable;
    function commitTokens(uint256 _amount) external;

    function afterMonth(uint256 timestamp) external pure returns (uint256);
    function tokenPrice() external view returns (uint256);

    function withdrawTokens(address payable beneficiary) external;
    function withdrawToLocker() external;
    function setNickname(address _addr, string calldata _name) external;

    function tokensClaimable(address _user) external view returns (uint256);
    function tokensLockable(address _user) external view returns (uint256);

    function finalized() external view returns (bool);
    function auctionSuccessful() external view returns (bool);
    function auctionEnded() external view returns (bool);

    function getBaseInformation() external view returns (uint256 startTime, uint256 endTime, bool marketFinalized);
    function getTotalTokens() external view returns (uint256);

    function commitments(address user) external view returns (uint256);
    function claimed(address user) external view returns (uint256);
    function locked(address user) external view returns (uint256);

    function nicknames(address user) external view returns (string memory);

    function auctionToken() external view returns (address);
    function paymentCurrency() external view returns (address);

    function marketStatus() external view returns (uint256, uint256, bool);
    function marketInfo() external view returns (uint256, uint256, uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IGToken {
    function underlying() external view returns (address);

    function totalSupply() external view returns (uint256);

    function accountSnapshot(address account) external view returns (Constant.AccountSnapshot memory);

    function underlyingBalanceOf(address account) external view returns (uint256);

    function borrowBalanceOf(address account) external view returns (uint256);

    function totalBorrow() external view returns (uint256);

    function _totalBorrow() external view returns (uint256);

    function totalReserve() external view returns (uint256);

    function reserveFactor() external view returns (uint256);

    function lastAccruedTime() external view returns (uint256);

    function accInterestIndex() external view returns (uint256);

    function exchangeRate() external view returns (uint256);

    function getCash() external view returns (uint256);

    function getRateModel() external view returns (address);

    function getAccInterestIndex() external view returns (uint256);

    function accruedAccountSnapshot(address account) external returns (Constant.AccountSnapshot memory);

    function accruedBorrowBalanceOf(address account) external returns (uint256);

    function accruedTotalBorrow() external returns (uint256);

    function accruedExchangeRate() external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    function supply(address account, uint256 underlyingAmount) external payable returns (uint256);

    function redeemToken(address account, uint256 gTokenAmount) external returns (uint256);

    function redeemUnderlying(address account, uint256 underlyingAmount) external returns (uint256);

    function borrow(address account, uint256 amount) external returns (uint256);

    function repayBorrow(address account, uint256 amount) external payable returns (uint256);

    function repayBorrowBehalf(address payer, address borrower, uint256 amount) external payable returns (uint256);

    function liquidateBorrow(
        address gTokenCollateral,
        address liquidator,
        address borrower,
        uint256 amount
    ) external payable returns (uint256 seizeGAmount, uint256 rebateGAmount, uint256 liquidatorGAmount);

    function seize(address liquidator, address borrower, uint256 gTokenAmount) external;

    function withdrawReserves() external;

    function transferTokensInternal(address spender, address src, address dst, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface ILendPoolLoan {
    /* ========== Event ========== */
    event LoanCreated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address gNft,
        uint256 amount
    );

    event LoanUpdated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amountAdded,
        uint256 amountTaken
    );

    event LoanRepaid(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    );

    event LoanAuctioned(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 bidBorrowAmount,
        address bidder,
        uint256 price,
        address previousBidder,
        uint256 previousPrice,
        uint256 floorPrice
    );

    event LoanRedeemed(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 repayAmount
    );

    event LoanLiquidated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    );

    event AuctionDurationUpdated(
        uint256 newAuctionDuration
    );

    event MinBidFineUpdated(
        uint256 newMinBidFine
    );

    event RedeemFineRateUpdated(
        uint256 newRedeemFineRate
    );

    event RedeemThresholdUpdated(
        uint256 newRedeemThreshold
    );

    event BorrowRateMultiplierUpdated(
        uint256 borrowRateMultiplier
    );

    event AuctionFeeRateUpdated(
        uint256 auctionFeeRate
    );

    function createLoan(
        address to,
        address nftAsset,
        uint256 nftTokenId,
        address gNft,
        uint256 amount
    ) external returns (uint256);

    function updateLoan(
        uint256 loanId,
        uint256 amountAdded,
        uint256 amountTaken
    ) external;

    function repayLoan(
        uint256 loanId,
        address gNft,
        uint256 amount
    ) external;

    function auctionLoan(
        address bidder,
        uint256 loanId,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external;

    function redeemLoan(
        uint256 loanId,
        uint256 amountTaken
    ) external;

    function liquidateLoan(
        address gNft,
        uint256 loanId,
        uint256 borrowAmount
    ) external;

    function initNft(address nftAsset, address gNft) external;
    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);
    function getNftCollateralAmount(address nftAsset) external view returns (uint256);
    function getUserNftCollateralAmount(address user, address nftAsset) external view returns (uint256);
    function getLoan(uint256 loanId) external view returns (Constant.LoanData memory loanData);

    function borrowBalanceOf(uint256 loanId) external view returns (uint256);
    function userBorrowBalance(address user) external view returns (uint256);
    function marketBorrowBalance(address gNft) external view returns (uint256);
    function marketAccountBorrowBalance(address gNft, address user) external view returns (uint256);
    function accrueInterest() external;
    function totalBorrow() external view returns (uint256);
    function currentLoanId() external view returns (uint256);
    function getAccInterestIndex() external view returns (uint256);

    function auctionDuration() external view returns (uint256);
    function minBidFine() external view returns (uint256);
    function redeemFineRate() external view returns (uint256);
    function redeemThreshold() external view returns (uint256);

    function auctionFeeRate() external view returns (uint256);
    function accInterestIndex() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface ILocker {
    event GRVDistributorUpdated(address newGRVDistributor);

    event RebateDistributorUpdated(address newRebateDistributor);

    event Pause();

    event Unpause();

    event Deposit(address indexed account, uint256 amount, uint256 expiry);

    event ExtendLock(address indexed account, uint256 nextExpiry);

    event Withdraw(address indexed account);

    event WithdrawAndLock(address indexed account, uint256 expiry);

    event DepositBehalf(address caller, address indexed account, uint256 amount, uint256 expiry);

    event WithdrawBehalf(address caller, address indexed account);

    event WithdrawAndLockBehalf(address caller, address indexed account, uint256 expiry);

    function scoreOfAt(address account, uint256 timestamp) external view returns (uint256);

    function lockInfoOf(address account) external view returns (Constant.LockInfo[] memory);

    function firstLockTimeInfoOf(address account) external view returns (uint256);

    function setGRVDistributor(address _grvDistributor) external;

    function setRebateDistributor(address _rebateDistributor) external;

    function pause() external;

    function unpause() external;

    function totalBalance() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function expiryOf(address account) external view returns (uint256);

    function availableOf(address account) external view returns (uint256);

    function getLockUnitMax() external view returns (uint256);

    function totalScore() external view returns (uint256 score, uint256 slope);

    function scoreOf(address account) external view returns (uint256);

    function truncateExpiry(uint256 time) external view returns (uint256);

    function deposit(uint256 amount, uint256 unlockTime) external;

    function extendLock(uint256 expiryTime) external;

    function withdraw() external;

    function withdrawAndLock(uint256 expiry) external;

    function depositBehalf(address account, uint256 amount, uint256 unlockTime) external;

    function withdrawBehalf(address account) external;

    function withdrawAndLockBehalf(address account, uint256 expiry) external;

    function preScoreOf(
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (uint256);

    function remainExpiryOf(address account) external view returns (uint256);

    function preRemainExpiryOf(uint256 expiry) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface ILpVault {
    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
        uint256 lastClaimTime; // keeps track of claimed time for lockup and potential penalty
        uint256 pendingGrvAmount; // pending grv amount
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amiunt);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartTimestamp(uint256 startTimestamp);
    event NewBonusEndTimestamp(uint256 bonusEndTimestamp);
    event NewRewardPerInterval(uint256 rewardPerInterval);
    event RewardsStop(uint256 blockTimestamp);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);
    event Compound(address indexed user, uint256 amount);
    event LogSetTreasury(address indexed prevTreasury, address indexed newTreasury);
    event LogSetHarvestFee(uint256 prevHarvestFee, uint256 newHarvestFee);
    event LogSetHarvestFeePeriod(uint256 prevHarvestFeePeriod, uint256 newHarvestFeePeriod);
    event LogSetLockupPeriod(uint256 prevHarvestPeriod, uint256 newHarvestPeriod);

    function rewardPerInterval() external view returns (uint256);
    function claimableGrvAmount(address userAddress) external view returns (uint256);
    function depositLpAmount(address userAddress) external view returns (uint256);
    function userInfo(address _user) external view returns (uint256, uint256, uint256, uint256);

    function lockupPeriod() external view returns (uint256);
    function harvestFeePeriod() external view returns (uint256);

    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;

    function claim() external;
    function harvest() external;
    function compound() external;
    function emergencyWithdraw() external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface ILpVaultDashboard {

    struct LpVaultData {
        uint256 totalLiquidity;
        uint256 apr;
        uint256 stakedLpAmount;
        uint256 stakedLpValueInUSD;
        uint256 claimableReward;
        uint256 pendingGrvAmount;
        uint256 penaltyDuration;
        uint256 lockDuration;
    }

    function getLpVaultInfo(address _user) external view returns (LpVaultData memory);
    function calculateLpValueInUSD(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IMarketDashboard {
    struct MarketData {
        address gToken;
        uint256 apySupply;
        uint256 apyBorrow;
        uint256 apySupplyGRV;
        uint256 apyBorrowGRV;
        uint256 totalSupply;
        uint256 totalBorrows;
        uint256 totalBoostedSupply;
        uint256 totalBoostedBorrow;
        uint256 cash;
        uint256 reserve;
        uint256 reserveFactor;
        uint256 collateralFactor;
        uint256 exchangeRate;
        uint256 borrowCap;
        uint256 accInterestIndex;
    }

    function marketDataOf(address market) external view returns (MarketData memory);
    function usersMonthlyProfit(address account) external view returns (uint256 supplyBaseProfits, uint256 supplyRewardProfits, uint256 borrowBaseProfits, uint256 borrowRewardProfits);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IMarketView {
    function borrowRatePerSec(address gToken) external view returns (uint256);

    function supplyRatePerSec(address gToken) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface INFT {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function MAX_ELEMENTS() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface INftCore {
    /* ========== Event ========== */
    event MarketListed(address gNft);
    event MarketEntered(address gNft, address account);
    event MarketExited(address gNft, address account);

    event CollateralFactorUpdated(address gNft, uint256 newCollateralFactor);
    event SupplyCapUpdated(address indexed gNft, uint256 newSupplyCap);
    event BorrowCapUpdated(address indexed gNft, uint256 newBorrowCap);
    event LiquidationThresholdUpdated(address indexed gNft, uint256 newLiquidationThreshold);
    event LiquidationBonusUpdated(address indexed gNft, uint256 newLiquidationBonus);
    event KeeperUpdated(address newKeeper);
    event TreasuryUpdated(address newTreasury);
    event CoreUpdated(address newCore);
    event ValidatorUpdated(address newValidator);
    event NftOracleUpdated(address newNftOracle);
    event BorrowMarketUpdated(address newBorrowMarket);
    event LendPoolLoanUpdated(address newLendPoolLoan);

    event Borrow(
        address user,
        uint256 amount,
        address indexed nftAsset,
        uint256 nftTokenId,
        uint256 loanId,
        uint256 indexed referral
    );

    event Repay(
        address user,
        uint256 amount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    event Auction(
        address user,
        uint256 bidPrice,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    event Redeem(
        address user,
        uint256 borrowAmount,
        uint256 fineAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    event Liquidate(
        address user,
        uint256 repayAmount,
        uint256 remainAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    function allMarkets() external view returns (address[] memory);
    function marketInfoOf(address gNft) external view returns (Constant.NftMarketInfo memory);
    function getLendPoolLoan() external view returns (address);
    function getNftOracle() external view returns (address);

    function borrow(address gNft, uint256 tokenId, uint256 borrowAmount) external;
    function batchBorrow(
        address gNft,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    function repay(address gNft, uint256 tokenId) external payable;
    function batchRepay(address gNft,
        uint256[] calldata tokenIds,
        uint256[] calldata repayAmounts
    ) external payable;

    function auction(address gNft, uint256 tokenId) external payable;
    function redeem(address gNft, uint256 tokenId, uint256 amount, uint256 bidFine) external payable;
    function liquidate(address gNft, uint256 tokenId) external payable;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface INftMarketDashboard {

    struct NftMarketStats {
        uint256 collateralLoanRatio;
        uint256 totalNftValueInETH;
        uint256 totalBorrowInETH;
    }

    struct NftMarketInfo {
        string symbol;
        uint256 totalSupply;
        uint256 nftCollateralAmount;
        uint256 availableNft;
        uint256 borrowCap;
        uint256 floorPrice;
        uint256 totalNftValueInETH;
        uint256 totalBorrowInETH;
    }

    struct MyNftMarketInfo {
        string symbol;
        uint256 availableBorrowInETH;
        uint256 totalBorrowInETH;
        uint256 nftCollateralAmount;
        uint256 floorPrice;
    }

    struct UserLoanInfo {
        uint256 loanId;
        Constant.LoanState state;
        uint256 tokenId;
        uint256 healthFactor;
        uint256 debt;
        uint256 liquidationPrice;
        uint256 collateralInETH;
        uint256 availableBorrowInETH;
        uint256 bidPrice;
        uint256 minRepayAmount;
        uint256 maxRepayAmount;
        uint256 repayPenalty;
    }

    struct BorrowModalInfo {
        uint256[] tokenIds;
        uint256 floorPrice;
        uint256 collateralFactor;
        uint256 liquidationThreshold;
    }

    struct ManageLoanModalInfo {
        UserLoanInfo[] userLoanInfos;
        uint256 floorPrice;
    }

    struct MyNftMarketStats {
        uint256 nftCollateralAmount;
        uint256 totalBorrowInETH;
    }

    struct Auction {
        Constant.LoanState state;
        string symbol;
        uint256 tokenId;
        uint256 floorPrice;
        uint256 debt;
        uint256 latestBidAmount;
        uint256 bidEndTimestamp;
        uint256 healthFactor;
        uint256 bidCount;
        address bidderAddress;
        address borrower;
        uint256 loanId;
    }

    struct RiskyLoanInfo {
        string symbol;
        uint256 tokenId;
        uint256 floorPrice;
        uint256 debt;
        uint256 healthFactor;
    }

    function borrowModalInfo(address gNft, address user) external view returns (BorrowModalInfo memory);
    function manageLoanModalInfo(address gNft, address user) external view returns (ManageLoanModalInfo memory);
    function nftMarketStats() external view returns (NftMarketStats memory);
    function nftMarketInfos() external view returns (NftMarketInfo[] memory);

    function myNftMarketStats(address user) external view returns (MyNftMarketStats memory);
    function myNftMarketInfos(address user) external view returns (MyNftMarketInfo[] memory);

    function userLoanInfos(address gNft, address user) external view returns (UserLoanInfo[] memory);
    function auctionList() external view returns (Auction[] memory);
    function healthFactorAlertList() external view returns (RiskyLoanInfo[] memory);
    function auctionHistory() external view returns (Auction[] memory);
    function myAuctionHistory(address user) external view returns (Auction[] memory);

    function calculateLiquidatePrice(address gNft, uint256 floorPrice, uint256 debt) external view returns (uint256);
    function calculateBiddablePrice(uint256 debt, uint256 bidAmount) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface INftMarketDashboardV2 {

    struct NftMarketStats {
        uint256 collateralLoanRatio;
        uint256 totalNftValueInETH;
        uint256 totalBorrowInETH;
    }

    struct NftMarketInfo {
        string symbol;
        uint256 totalSupply;
        uint256 nftCollateralAmount;
        uint256 availableNft;
        uint256 borrowCap;
        uint256 floorPrice;
        uint256 totalNftValueInETH;
        uint256 totalBorrowInETH;
    }

    struct MyNftMarketInfo {
        string symbol;
        uint256 availableBorrowInETH;
        uint256 totalBorrowInETH;
        uint256 nftCollateralAmount;
        uint256 floorPrice;
        uint256 marketBorrowBalance;
        uint256 borrowCap;
    }

    struct UserLoanInfo {
        uint256 loanId;
        Constant.LoanState state;
        uint256 tokenId;
        uint256 healthFactor;
        uint256 debt;
        uint256 liquidationPrice;
        uint256 collateralInETH;
        uint256 availableBorrowInETH;
        uint256 bidPrice;
        uint256 minRepayAmount;
        uint256 maxRepayAmount;
        uint256 repayPenalty;
    }

    struct BorrowModalInfo {
        uint256[] tokenIds;
        uint256 floorPrice;
        uint256 collateralFactor;
        uint256 liquidationThreshold;
    }

    struct ManageLoanModalInfo {
        UserLoanInfo[] userLoanInfos;
        uint256 floorPrice;
    }

    struct MyNftMarketStats {
        uint256 nftCollateralAmount;
        uint256 totalBorrowInETH;
    }

    function borrowModalInfo(address gNft, address user) external view returns (BorrowModalInfo memory);
    function manageLoanModalInfo(address gNft, address user, uint256[] calldata loanIds) external view returns (ManageLoanModalInfo memory);
    function nftMarketStats() external view returns (NftMarketStats memory);
    function nftMarketInfos() external view returns (NftMarketInfo[] memory);

    function myNftMarketStats(address user) external view returns (MyNftMarketStats memory);
    function myNftMarketInfos(address user) external view returns (MyNftMarketInfo[] memory);

    function userLoanInfos(address gNft, address user, uint256[] calldata loanIds) external view returns (UserLoanInfo[] memory);

    function calculateLiquidatePrice(address gNft, uint256 floorPrice, uint256 debt) external view returns (uint256);
    function calculateBiddablePrice(uint256 debt, uint256 bidAmount) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface INFTOracle {
    struct NFTPriceData {
        uint256 price;
        uint256 timestamp;
        uint256 roundId;
    }

    struct NFTPriceFeed {
        bool registered;
        NFTPriceData[] nftPriceData;
    }

    /* ========== Event ========== */

    event KeeperUpdated(address indexed newKeeper);
    event AssetAdded(address indexed asset);
    event AssetRemoved(address indexed asset);

    event SetAssetData(address indexed asset, uint256 price, uint256 timestamp, uint256 roundId);
    event SetAssetTwapPrice(address indexed asset, uint256 price, uint256 timestamp);

    function getAssetPrice(address _nftContract) external view returns (uint256);
    function getLatestRoundId(address _nftContract) external view returns (uint256);
    function getUnderlyingPrice(address _gNft) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface INftValidator {
    function validateBorrow(
        address user,
        uint256 amount,
        address gNft,
        uint256 loanId
    ) external view;

    function validateRepay(
        uint256 loanId,
        uint256 repayAmount,
        uint256 borrowAmount
    ) external view;

    function validateAuction(
        address gNft,
        uint256 loanId,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external view;

    function validateRedeem(
        uint256 loanId,
        uint256 repayAmount,
        uint256 bidFine,
        uint256 borrowAmount
    ) external view returns (uint256);

    function validateLiquidate(
        uint256 loanId,
        uint256 borrowAmount,
        uint256 amount
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.6.12;

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 */
interface IPool {
    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://docs.aave.com/developers/
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts of the assets being flash-borrowed
     * @param interestRateModes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://docs.aave.com/developers/
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IPresaleDashboard {

    struct PresaleData {
        uint256 commitmentsTotal;
        uint256 commitmentAmount;
        uint256 estimatedReceiveAmount;
        uint256 exchangeRate;
        uint256 tokenPrice;
        uint256 launchPrice;
        uint256 startDate;
        uint256 endDate;
        uint256 totalTokens;
        uint256 minimumCommitmentAmount;
        bool finalized;
    }

    struct VestingData {
        uint256 totalPurchaseAmount;
        uint256 claimedAmount;
        uint256 claimableAmount;
    }

    function getPresaleInfo(address _user) external view returns (PresaleData memory);
    function getVestingInfo(address _user) external view returns (VestingData memory);

    function receiveGrvAmount(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IPriceCalculator {
    struct ReferenceData {
        uint256 lastData;
        uint256 lastUpdated;
    }

    function priceOf(address asset) external view returns (uint256);

    function pricesOf(address[] memory assets) external view returns (uint256[] memory);

    function priceOfETH() external view returns (uint256);

    function getUnderlyingPrice(address gToken) external view returns (uint256);

    function getUnderlyingPrices(address[] memory gTokens) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IPriceProtectionTaxCalculator {
    event KeeperUpdated(address keeper);
    event PriceUpdated(uint256 timestamp, uint256 price);
    event GrvPriceWeightUpdated(uint256[] weights);

    function setGrvPrice(uint256 timestamp, uint256 price) external;

    function setGrvPriceWeight(uint256[] calldata weights) external;

    function getGrvPrice(uint256 timestamp) external view returns (uint256);

    function referencePrice() external view returns (uint256);

    function startOfDay(uint256 timestamp) external pure returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IRankerRewardDistributor {
    function withdrawTokens() external;
    function withdrawToLocker() external;

    function tokensClaimable(address _user) external view returns (uint256 claimableAmount);
    function tokensLockable(address _user) external view returns (uint256 lockableAmount);
    function getTokenAmount(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IRateModel {
    function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) external view returns (uint256);

    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactor
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IRebateDistributor {
    event RebateClaimed(address indexed user, address[] markets, uint256[] uAmount, uint256[] gAmount);

    function setKeeper(address _keeper) external;

    function pause() external;

    function unpause() external;

    function updateAdminFeeRate(uint256 newAdminFeeRate) external;

    function approveMarkets() external;

    function checkpoint() external;

    function thisWeekRebatePool() external view returns (uint256[] memory, address[] memory, uint256, uint256);

    function weeklyRebatePool() external view returns (uint256, uint256);

    function weeklyProfitOfVP(uint256 vp) external view returns (uint256);

    function weeklyProfitOf(address account) external view returns (uint256);

    function indicativeYearProfit() external view returns (uint256);

    function accuredRebates(
        address account
    ) external view returns (uint256[] memory, address[] memory, uint256[] memory, uint256);

    function claimRebates() external returns (uint256[] memory, address[] memory, uint256[] memory);

    function claimAdminRebates() external returns (uint256[] memory, address[] memory, uint256[] memory);

    function addRebateAmount(address gToken, uint256 uAmount) external;

    function totalClaimedRebates(
        address account
    ) external view returns (uint256[] memory rebates, address[] memory markets, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IRushAirdropDistributor {
    function withdrawTokens() external;
    function withdrawToLocker() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface ISafeSwapETH {
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IValidator {
    function redeemAllowed(address gToken, address redeemer, uint256 redeemAmount) external returns (bool);

    function borrowAllowed(address gToken, address borrower, uint256 borrowAmount) external returns (bool);

    function liquidateAllowed(
        address gTokenBorrowed,
        address borrower,
        uint256 repayAmount,
        uint256 closeFactor
    ) external returns (bool);

    function gTokenAmountToSeize(
        address gTokenBorrowed,
        address gTokenCollateral,
        uint256 actualRepayAmount
    ) external returns (uint256 seizeGAmount, uint256 rebateGAmount, uint256 liquidatorGAmount);

    function getAccountLiquidity(
        address account
    ) external view returns (uint256 collateralInUSD, uint256 supplyInUSD, uint256 borrowInUSD);

    function getAccountRedeemFeeRate(address account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IVoteController {
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    event PoolAdded(address pool);
    event PoolToggled(address indexed pool, bool isDisabled);
    event Voted(
        address indexed account,
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256[] oldWeights,
        uint256 amount,
        uint256 unlockTime,
        uint256[] weights
    );

    // mapping(address => mapping(address => uint256)) public override userWeights;

    function userWeights(address account, address pool) external view returns (uint256);

    function getPools() external view returns (address[] memory);

    function addPool(address newPool) external;

    function togglePool(uint256 index) external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function sumAtTimestamp(address pool, uint256 timestamp) external view returns (uint256);

    function count(uint256 timestamp) external view returns (uint256[] memory weights, address[] memory pools);

    function cast(uint256[] memory weights) external;

    function syncWithLocker(address account) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IVoteDashboard {
    struct VotedGrvInfo {
        uint256 totalVotedGrvAmount;
        uint256 totalVotedGrvRatio;
        uint256 myVotedGrvAmount;
        uint256 myVotedGrvRatio;
    }

    struct VotingStatus {
        string symbol;
        uint256 userWeight;
        uint256 poolVotedRate;
        uint256 fromGrvSupplyAPR;
        uint256 fromGrvBorrowAPR;
        uint256 toGrvSupplyAPR;
        uint256 toGrvBorrowAPR;
    }

    function votedGrvInfo(address user) external view returns (VotedGrvInfo memory);
    function votingStatus(address user) external view returns (VotingStatus[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IWETH {
    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface IWhiteholeCallee {
    function whiteholeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface IWhiteholeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface IWhiteholePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface IWhiteholeRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IZap {
    function zapInToken(address _from, uint256 amount, address _to) external;

    function zapIn(address _to) external payable;

    function zapOut(address _from, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IZapDashboard {
    function estimatedReceiveLpData(address _token, uint256 _amount) external view returns (uint256, uint256);
    function getLiquidityInfo(
        address token,
        uint256 tokenAmount
    ) external view returns (uint256, uint256);

    function getTokenAmount(
        uint256 tokenAmount
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

import "../interfaces/IBEP20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract BEP20Upgradeable is IBEP20, OwnableUpgradeable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256[50] private __gap;

    /**
     * @dev sets initials supply and the owner
     */
    function __BEP20__init(string memory name, string memory symbol, uint8 decimals) internal initializer {
        __Ownable_init();
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Burn `amount` tokens and decreasing the total supply.
     */
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance")
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

library Constant {
    uint256 public constant CLOSE_FACTOR_MIN = 5e16;
    uint256 public constant CLOSE_FACTOR_MAX = 9e17;
    uint256 public constant COLLATERAL_FACTOR_MAX = 9e17;
    uint256 public constant LIQUIDATION_THRESHOLD_MAX = 9e17;
    uint256 public constant LIQUIDATION_BONUS_MAX = 5e17;
    uint256 public constant AUCTION_DURATION_MAX = 7 days;
    uint256 public constant MIN_BID_FINE_MAX = 100 ether;
    uint256 public constant REDEEM_FINE_RATE_MAX = 5e17;
    uint256 public constant REDEEM_THRESHOLD_MAX = 9e17;
    uint256 public constant BORROW_RATE_MULTIPLIER_MAX = 1e19;
    uint256 public constant AUCTION_FEE_RATE_MAX = 5e17;

    enum EcoZone {
        RED,
        ORANGE,
        YELLOW,
        LIGHTGREEN,
        GREEN
    }

    enum EcoScorePreviewOption {
        LOCK,
        CLAIM,
        EXTEND,
        LOCK_MORE
    }

    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        None,
        // The loan data is stored, but not initiated yet.
        Active,
        // The loan is in auction, higest price liquidator will got chance to claim it.
        Auction,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
        Defaulted
    }

    struct LoanData {
        uint256 loanId;
        LoanState state;
        address borrower;
        address gNft;
        address nftAsset;
        uint256 nftTokenId;
        uint256 borrowAmount;
        uint256 interestIndex;

        uint256 bidStartTimestamp;
        address bidderAddress;
        uint256 bidPrice;
        uint256 bidBorrowAmount;
        uint256 floorPrice;
        uint256 bidCount;
        address firstBidderAddress;
    }

    struct MarketInfo {
        bool isListed;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 collateralFactor;
    }

    struct NftMarketInfo {
        bool isListed;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 collateralFactor;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
    }

    struct BorrowInfo {
        uint256 borrow;
        uint256 interestIndex;
    }

    struct AccountSnapshot {
        uint256 gTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRate;
    }

    struct AccrueSnapshot {
        uint256 totalBorrow;
        uint256 totalReserve;
        uint256 accInterestIndex;
    }

    struct AccrueLoanSnapshot {
        uint256 totalBorrow;
        uint256 accInterestIndex;
    }

    struct DistributionInfo {
        uint256 supplySpeed;
        uint256 borrowSpeed;
        uint256 totalBoostedSupply;
        uint256 totalBoostedBorrow;
        uint256 accPerShareSupply;
        uint256 accPerShareBorrow;
        uint256 accruedAt;
    }

    struct DistributionAccountInfo {
        uint256 accruedGRV; // Unclaimed GRV rewards amount
        uint256 boostedSupply; // effective(boosted) supply balance of user  (since last_action)
        uint256 boostedBorrow; // effective(boosted) borrow balance of user  (since last_action)
        uint256 accPerShareSupply; // Last integral value of GRV rewards per share. ∫(GRVRate(t) / totalShare(t) dt) from 0 till (last_action)
        uint256 accPerShareBorrow; // Last integral value of GRV rewards per share. ∫(GRVRate(t) / totalShare(t) dt) from 0 till (last_action)
    }

    struct DistributionAPY {
        uint256 apySupplyGRV;
        uint256 apyBorrowGRV;
        uint256 apyAccountSupplyGRV;
        uint256 apyAccountBorrowGRV;
    }

    struct EcoScoreInfo {
        uint256 claimedGrv;
        uint256 ecoDR;
        EcoZone ecoZone;
        uint256 compoundGrv;
        uint256 changedEcoZoneAt;
    }

    struct BoostConstant {
        uint256 boost_max;
        uint256 boost_portion;
        uint256 ecoBoost_portion;
    }

    struct RebateCheckpoint {
        uint256 timestamp;
        uint256 totalScore;
        uint256 adminFeeRate;
        mapping(address => uint256) amount;
    }

    struct RebateClaimInfo {
        uint256 timestamp;
        address[] markets;
        uint256[] amount;
        uint256[] prices;
        uint256 value;
    }

    struct LockInfo {
        uint256 timestamp;
        uint256 amount;
        uint256 expiry;
    }

    struct EcoPolicyInfo {
        uint256 boostMultiple;
        uint256 maxBoostCap;
        uint256 boostBase;
        uint256 redeemFee;
        uint256 claimTax;
        uint256[] pptTax;
    }

    struct EcoZoneStandard {
        uint256 minExpiryOfGreenZone;
        uint256 minExpiryOfLightGreenZone;
        uint256 minDrOfGreenZone;
        uint256 minDrOfLightGreenZone;
        uint256 minDrOfYellowZone;
        uint256 minDrOfOrangeZone;
    }

    struct PPTPhaseInfo {
        uint256 phase1;
        uint256 phase2;
        uint256 phase3;
        uint256 phase4;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

library HomoraMath {
    using SafeMath for uint256;

    function divCeil(uint256 lhs, uint256 rhs) internal pure returns (uint256) {
        return lhs.add(rhs).sub(1) / rhs;
    }

    function fmul(uint256 lhs, uint256 rhs) internal pure returns (uint256) {
        return lhs.mul(rhs) / (2 ** 112);
    }

    function fdiv(uint256 lhs, uint256 rhs) internal pure returns (uint256) {
        return lhs.mul(2 ** 112) / rhs;
    }

    // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
    // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }

        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.6.12;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721EnumerableUpgradeable.sol";

import "../library/Constant.sol";

import "../interfaces/INftValidator.sol";
import "../interfaces/INFTOracle.sol";
import "../interfaces/INftCore.sol";
import "../interfaces/ILendPoolLoan.sol";
import "../interfaces/IGNft.sol";

contract NftValidator is INftValidator, OwnableUpgradeable {
    using SafeMath for uint256;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

    /* ========== STATE VARIABLES ========== */

    INFTOracle public nftOracle;
    INftCore public nftCore;
    ILendPoolLoan public lendPoolLoan;

    /* ========== INITIALIZER ========== */

    function initialize(address _nftOracle, address _nftCore, address _lendPoolLoan) external initializer {
        __Ownable_init();

        nftOracle = INFTOracle(_nftOracle);
        nftCore = INftCore(_nftCore);
        lendPoolLoan = ILendPoolLoan(_lendPoolLoan);
    }

    /* ========== VIEWS ========== */

    function validateBorrow(
        address user,
        uint256 amount,
        address gNft,
        uint256 loanId
    ) external view override {
        require(gNft != address(0), "NftValidator: invalid gNft address");
        require(amount > 0, "NftValidator: invalid amount");

        Constant.NftMarketInfo memory marketInfo = nftCore.marketInfoOf(gNft);

        uint256 collateralAmount = lendPoolLoan.getNftCollateralAmount(IGNft(gNft).underlying());
        require(marketInfo.supplyCap == 0 || collateralAmount < marketInfo.supplyCap, "NftValidator: supply cap reached");

        if (marketInfo.borrowCap != 0) {
            uint256 marketBorrows = lendPoolLoan.marketBorrowBalance(gNft);
            uint256 nextMarketBorrows = marketBorrows.add(amount);
            require(nextMarketBorrows < marketInfo.borrowCap, "NftValidator: borrow cap reached");
        }

        if (loanId != 0) {
            Constant.LoanData memory loanData = lendPoolLoan.getLoan(loanId);
            require(loanData.state == Constant.LoanState.Active, "NftValidator: invalid loan state");
            require(user == loanData.borrower, "NftValidator: invalid borrower");
        }

        (uint256 userCollateralBalance, uint256 userBorrowBalance, uint256 healthFactor) = _calculateLoanData(
            gNft,
            loanId,
            marketInfo.liquidationThreshold
        );

        require(userCollateralBalance > 0, "NftValidator: collateral balance is zero");
        require(healthFactor > HEALTH_FACTOR_LIQUIDATION_THRESHOLD, "NftValidator: health factor lower than liquidation threshold");

        uint256 amountOfCollateralNeeded = userBorrowBalance.add(amount);
        userCollateralBalance = userCollateralBalance.mul(marketInfo.collateralFactor).div(1e18);

        require(amountOfCollateralNeeded <= userCollateralBalance, "NftValidator: Collateral cannot cover new borrow");
    }

    function validateRepay(
        uint256 loanId,
        uint256 repayAmount,
        uint256 borrowAmount
    ) external view override {
        require(repayAmount > 0, "NftValidator: invalid repay amount");
        require(borrowAmount > 0, "NftValidator: invalid borrow amount");

        Constant.LoanData memory loanData = lendPoolLoan.getLoan(loanId);
        require(loanData.state == Constant.LoanState.Active, "NftValidator: invalid loan state");
    }

    function validateAuction(
        address gNft,
        uint256 loanId,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external view override {
        Constant.LoanData memory loanData = lendPoolLoan.getLoan(loanId);
        require(loanData.state == Constant.LoanState.Active || loanData.state == Constant.LoanState.Auction,
                "NftValidator: invalid loan state");

        require(bidPrice > 0, "NftValidator: invalid bid price");
        require(borrowAmount > 0, "NftValidator: invalid borrow amount");

        (uint256 thresholdPrice, uint256 liquidatePrice) = _calculateLoanLiquidatePrice(
            gNft,
            borrowAmount
        );

        if (loanData.state == Constant.LoanState.Active) {
            // Loan accumulated debt must exceed threshold (health factor below 1.0)
            require(borrowAmount > thresholdPrice, "NftValidator: borrow not exceed liquidation threshold");

            // bid price must greater than borrow debt
            require(bidPrice >= borrowAmount, "NftValidator: bid price less than borrow debt");

            // bid price must greater than liquidate price
            require(bidPrice >= liquidatePrice, "NftValidator: bid price less than liquidate price");
        } else {
            // bid price must greater than borrow debt
            require(bidPrice >= borrowAmount, "NftValidator: bid price less than borrow debt");

            uint256 auctionEndTimestamp = loanData.bidStartTimestamp.add(lendPoolLoan.auctionDuration());
            require(block.timestamp <= auctionEndTimestamp, "NftValidator: bid auction duration has ended");

            // bid price must greater than highest bid + delta
            uint256 bidDelta = borrowAmount.mul(1e16).div(1e18); // 1%
            require(bidPrice >= loanData.bidPrice.add(bidDelta), "NftValidator: bid price less than highest price");
        }
    }

    function validateRedeem(
        uint256 loanId,
        uint256 repayAmount,
        uint256 bidFine,
        uint256 borrowAmount
    ) external view override returns (uint256) {
        Constant.LoanData memory loanData = lendPoolLoan.getLoan(loanId);
        require(loanData.state == Constant.LoanState.Auction, "NftValidator: invalid loan state");
        require(loanData.bidderAddress != address(0), "NftValidator: invalid bidder address");

        require(repayAmount > 0, "NftValidator: invalid repay amount");

        uint256 redeemEndTimestamp = loanData.bidStartTimestamp.add(lendPoolLoan.auctionDuration());
        require(block.timestamp <= redeemEndTimestamp, "NftValidator: redeem duration has ended");

        uint256 _bidFine = _calculateLoanBidFine(loanData, borrowAmount);
        require(bidFine >= _bidFine, "NftValidator: invalid bid fine");

        uint256 _minRepayAmount = borrowAmount.mul(lendPoolLoan.redeemThreshold()).div(1e18);
        require(repayAmount >= _minRepayAmount, "NftValidator: repay amount less than redeem threshold");

        uint256 _maxRepayAmount = borrowAmount.mul(9e17).div(1e18);
        require(repayAmount <= _maxRepayAmount, "NftValidator: repay amount greater than max repay");

        return _bidFine;
    }

    function validateLiquidate(
        uint256 loanId,
        uint256 borrowAmount,
        uint256 amount
    ) external view override returns (uint256, uint256) {
        Constant.LoanData memory loanData = lendPoolLoan.getLoan(loanId);
        require(loanData.state == Constant.LoanState.Auction, "NftValidator: invalid loan state");
        require(loanData.bidderAddress != address(0), "NftValidator: invalid bidder address");

        uint256 auctionEndTimestamp = loanData.bidStartTimestamp.add(lendPoolLoan.auctionDuration());
        require(block.timestamp > auctionEndTimestamp, "NftValidator: auction duration not end");

        // Last bid price can not cover borrow amount
        uint256 extraDebtAmount = 0;
        if (loanData.bidPrice < borrowAmount) {
            extraDebtAmount = borrowAmount.sub(loanData.bidPrice);
            require(amount >= extraDebtAmount, "NftValidator: amount less than extra debt amount");
        }

        uint256 remainAmount = 0;
        if (loanData.bidPrice > borrowAmount) {
            remainAmount = loanData.bidPrice.sub(borrowAmount);
        }

        return (extraDebtAmount, remainAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _calculateLoanBidFine(
        Constant.LoanData memory loanData,
        uint256 borrowAmount
    ) internal view returns (uint256) {
        if (loanData.bidPrice == 0) {
            return 0;
        }

        uint256 minBidFine = lendPoolLoan.minBidFine();
        uint256 bidFineAmount = borrowAmount.mul(lendPoolLoan.redeemFineRate()).div(1e18);

        if (bidFineAmount < minBidFine) {
            bidFineAmount = minBidFine;
        }

        return bidFineAmount;
    }

    function _calculateLoanData(
        address gNft,
        uint256 loanId,
        uint256 liquidationThreshold
    ) internal view returns (uint256, uint256, uint256) {
        uint256 totalDebtInETH = 0;

        if (loanId != 0) {
            totalDebtInETH = lendPoolLoan.borrowBalanceOf(loanId);
        }

        uint256 totalCollateralInETH = nftOracle.getUnderlyingPrice(gNft);
        uint256 healthFactor = _calculateHealthFactorFromBalances(totalCollateralInETH, totalDebtInETH, liquidationThreshold);

        return (totalCollateralInETH, totalDebtInETH, healthFactor);
    }

    /*
     * 0                   CR                  LH                  100
     * |___________________|___________________|___________________|
     *  <       Borrowing with Interest        <
     * CR: Callteral Ratio;
     * LH: Liquidate Threshold;
     * Liquidate Trigger: Borrowing with Interest > thresholdPrice;
     * Liquidate Price: (100% - BonusRatio) * NFT Price;
     */
    function _calculateLoanLiquidatePrice(
        address gNft,
        uint256 borrowAmount
    ) internal view returns (uint256, uint256) {
        uint256 liquidationThreshold = nftCore.marketInfoOf(gNft).liquidationThreshold;
        uint256 liquidationBonus = nftCore.marketInfoOf(gNft).liquidationBonus;

        uint256 nftPriceInETH = nftOracle.getUnderlyingPrice(gNft);
        uint256 thresholdPrice = nftPriceInETH.mul(liquidationThreshold).div(1e18);

        uint256 bonusAmount = nftPriceInETH.mul(liquidationBonus).div(1e18);
        uint256 liquidatePrice = nftPriceInETH.sub(bonusAmount);

        if (liquidatePrice < borrowAmount) {
            uint256 bidDelta = borrowAmount.mul(1e16).div(1e18); // 1%
            liquidatePrice = borrowAmount.add(bidDelta);
        }

        return (thresholdPrice, liquidatePrice);
    }

    function _calculateHealthFactorFromBalances(
        uint256 totalCollateral,
        uint256 totalDebt,
        uint256 liquidationThreshold
    ) public pure returns (uint256) {
        if (totalDebt == 0) {
            return uint256(-1);
        }
        return (totalCollateral.mul(liquidationThreshold).mul(1e18).div(totalDebt).div(1e18));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint256 private constant decimals = 18;
    uint256 private constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 private constant UNIT = 10 ** uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 private constant PRECISE_UNIT = 10 ** uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10 ** uint256(highPrecisionDecimals - decimals);

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(UNIT);
    }

    function multiplyDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(PRECISE_UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    function divideDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(PRECISE_UNIT).div(y);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i.mul(10).div(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen = quotientTimesTen.add(10);
        }

        return quotientTimesTen.div(10);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, and the max value of
     * uint256 on overflow.
     */
    function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        return c / a != b ? type(uint256).max : c;
    }

    function saturatingMultiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return saturatingMul(x, y).div(UNIT);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.6.12;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2 ** 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IValidator.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/ICore.sol";
import "../interfaces/IEcoScore.sol";
import "../interfaces/IBEP20.sol";
import "../library/Constant.sol";

contract Validator is IValidator, OwnableUpgradeable {
    using SafeMath for uint256;

    /* ========== CONSTANT VARIABLES ========== */

    IPriceCalculator public oracle;
    IEcoScore public ecoScore;
    uint256 private constant grvPriceCollateralCap = 75e15;

    /* ========== STATE VARIABLES ========== */

    ICore public core;
    address private GRV;

    /* ========== INITIALIZER ========== */

    function initialize(address _grv) external initializer {
        __Ownable_init();
        GRV = _grv;
    }

    /// @notice priceCalculator address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    /// @param _priceCalculator priceCalculator contract address
    function setPriceCalculator(address _priceCalculator) public onlyOwner {
        require(_priceCalculator != address(0), "Validator: invalid priceCalculator address");
        oracle = IPriceCalculator(_priceCalculator);
    }

    function setEcoScore(address _ecoScore) public onlyOwner {
        require(_ecoScore != address(0), "Validator: invalid ecoScore address");
        ecoScore = IEcoScore(_ecoScore);
    }

    /* ========== VIEWS ========== */

    /// @notice View collateral, supply, borrow value in USD of account
    /// @param account account address
    /// @return collateralInUSD Total collateral value in USD
    /// @return supplyInUSD Total supply value in USD
    /// @return borrowInUSD Total borrow value in USD
    function getAccountLiquidity(
        address account
    ) external view override returns (uint256 collateralInUSD, uint256 supplyInUSD, uint256 borrowInUSD) {
        collateralInUSD = 0;
        supplyInUSD = 0;
        borrowInUSD = 0;

        address[] memory assets = core.marketListOf(account);
        uint256[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint256 i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "Validator: price error");
            uint256 decimals = _getDecimals(assets[i]);
            Constant.AccountSnapshot memory snapshot = IGToken(payable(assets[i])).accountSnapshot(account);

            uint256 priceCollateral;
            if (assets[i] == GRV && prices[i] > grvPriceCollateralCap) {
                priceCollateral = grvPriceCollateralCap;
            } else {
                priceCollateral = prices[i];
            }

            uint256 collateralFactor = core.marketInfoOf(payable(assets[i])).collateralFactor;
            uint256 collateralValuePerShareInUSD = snapshot.exchangeRate.mul(priceCollateral).mul(collateralFactor).div(
                1e36
            );

            collateralInUSD = collateralInUSD.add(
                snapshot.gTokenBalance.mul(10 ** (18 - decimals)).mul(collateralValuePerShareInUSD).div(1e18)
            );
            supplyInUSD = supplyInUSD.add(
                snapshot.gTokenBalance.mul(snapshot.exchangeRate).mul(10 ** (18 - decimals)).mul(prices[i]).div(1e36)
            );
            borrowInUSD = borrowInUSD.add(snapshot.borrowBalance.mul(10 ** (18 - decimals)).mul(prices[i]).div(1e18));
        }
    }

    function getAccountRedeemFeeRate(address account) external view override returns (uint256 redeemFee) {
        Constant.EcoScoreInfo memory scoreInfo = ecoScore.accountEcoScoreInfoOf(account);
        Constant.EcoPolicyInfo memory scorePolicy = ecoScore.ecoPolicyInfoOf(scoreInfo.ecoZone);
        redeemFee = scorePolicy.redeemFee;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice core address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    ///      설정 이후에는 다른 주소로 변경할 수 없음
    /// @param _core core contract address
    function setCore(address _core) external onlyOwner {
        require(_core != address(0), "Validator: invalid core address");
        require(address(core) == address(0), "Validator: core already set");
        core = ICore(_core);
    }

    /* ========== ALLOWED FUNCTIONS ========== */

    /// @notice View if redeem is allowed
    /// @param gToken gToken address
    /// @param redeemer Redeemer account
    /// @param redeemAmount Redeem amount of underlying token
    function redeemAllowed(address gToken, address redeemer, uint256 redeemAmount) external override returns (bool) {
        (, uint256 shortfall) = _getAccountLiquidityInternal(redeemer, gToken, redeemAmount, 0);
        return shortfall == 0;
    }

    /// @notice View if borrow is allowed
    /// @param gToken gToken address
    /// @param borrower Borrower address
    /// @param borrowAmount Borrow amount of underlying token
    function borrowAllowed(address gToken, address borrower, uint256 borrowAmount) external override returns (bool) {
        require(core.checkMembership(borrower, address(gToken)), "Validator: enterMarket required");
        require(oracle.getUnderlyingPrice(address(gToken)) > 0, "Validator: Underlying price error");

        // Borrow cap of 0 corresponds to unlimited borrowing
        uint256 borrowCap = core.marketInfoOf(gToken).borrowCap;
        if (borrowCap != 0) {
            uint256 totalBorrows = IGToken(payable(gToken)).accruedTotalBorrow();
            uint256 nextTotalBorrows = totalBorrows.add(borrowAmount);
            require(nextTotalBorrows < borrowCap, "Validator: market borrow cap reached");
        }

        (, uint256 shortfall) = _getAccountLiquidityInternal(borrower, gToken, 0, borrowAmount);
        return shortfall == 0;
    }

    /// @notice View if liquidate is allowed
    /// @param gToken gToken address
    /// @param borrower Borrower address
    /// @param liquidateAmount Underlying token amount to liquidate
    /// @param closeFactor Close factor
    function liquidateAllowed(
        address gToken,
        address borrower,
        uint256 liquidateAmount,
        uint256 closeFactor
    ) external override returns (bool) {
        // The borrower must have shortfall in order to be liquidate
        (, uint256 shortfall) = _getAccountLiquidityInternal(borrower, address(0), 0, 0);
        require(shortfall != 0, "Validator: Insufficient shortfall");

        // The liquidator may not repay more than what is allowed by the closeFactor
        uint256 borrowBalance = IGToken(payable(gToken)).accruedBorrowBalanceOf(borrower);
        uint256 maxClose = closeFactor.mul(borrowBalance).div(1e18);
        return liquidateAmount <= maxClose;
    }

    function gTokenAmountToSeize(
        address gTokenBorrowed,
        address gTokenCollateral,
        uint256 amount
    ) external override returns (uint256 seizeGAmount, uint256 rebateGAmount, uint256 liquidatorGAmount) {
        require(
            oracle.getUnderlyingPrice(gTokenBorrowed) != 0 && oracle.getUnderlyingPrice(gTokenCollateral) != 0,
            "Validator: price error"
        );

        uint256 exchangeRate = IGToken(payable(gTokenCollateral)).accruedExchangeRate();
        require(exchangeRate != 0, "Validator: exchangeRate of gTokenCollateral is zero");

        uint256 borrowedDecimals = _getDecimals(gTokenBorrowed);
        uint256 collateralDecimals = _getDecimals(gTokenCollateral);

        // seizeGTokenAmountBase18 =  ( repayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate) )
        // seizeGTokenAmount = seizeGTokenAmountBase18 / (10 ** (18 - decimals))
        uint256 seizeGTokenAmountBase = amount
            .mul(10 ** (18 - borrowedDecimals))
            .mul(core.liquidationIncentive())
            .mul(oracle.getUnderlyingPrice(gTokenBorrowed))
            .div(oracle.getUnderlyingPrice(gTokenCollateral).mul(exchangeRate));

        seizeGAmount = seizeGTokenAmountBase.div(10 ** (18 - collateralDecimals));
        liquidatorGAmount = seizeGAmount;
        rebateGAmount = 0;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getAccountLiquidityInternal(
        address account,
        address gToken,
        uint256 redeemAmount,
        uint256 borrowAmount
    ) private returns (uint256 liquidity, uint256 shortfall) {
        uint256 accCollateralValueInUSD;
        uint256 accBorrowValueInUSD;

        address[] memory assets = core.marketListOf(account);
        uint256[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 decimals = _getDecimals(assets[i]);
            require(prices[i] != 0, "Validator: price error");
            Constant.AccountSnapshot memory snapshot = IGToken(payable(assets[i])).accruedAccountSnapshot(account);

            uint256 collateralValuePerShareInUSD;
            if (assets[i] == GRV && prices[i] > grvPriceCollateralCap) {
                collateralValuePerShareInUSD = snapshot
                    .exchangeRate
                    .mul(grvPriceCollateralCap)
                    .mul(core.marketInfoOf(payable(assets[i])).collateralFactor)
                    .div(1e36);
            } else {
                collateralValuePerShareInUSD = snapshot
                    .exchangeRate
                    .mul(prices[i])
                    .mul(core.marketInfoOf(payable(assets[i])).collateralFactor)
                    .div(1e36);
            }

            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.gTokenBalance.mul(10 ** (18 - decimals)).mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(
                snapshot.borrowBalance.mul(10 ** (18 - decimals)).mul(prices[i]).div(1e18)
            );

            if (assets[i] == gToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(
                    _getAmountForAdditionalBorrowValue(
                        redeemAmount,
                        borrowAmount,
                        collateralValuePerShareInUSD,
                        prices[i],
                        decimals
                    )
                );
            }
        }

        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }

    function _getAmountForAdditionalBorrowValue(
        uint256 redeemAmount,
        uint256 borrowAmount,
        uint256 collateralValuePerShareInUSD,
        uint256 price,
        uint256 decimals
    ) internal pure returns (uint256 additionalBorrowValueInUSD) {
        additionalBorrowValueInUSD = redeemAmount.mul(10 ** (18 - decimals)).mul(collateralValuePerShareInUSD).div(
            1e18
        );
        additionalBorrowValueInUSD = additionalBorrowValueInUSD.add(
            borrowAmount.mul(10 ** (18 - decimals)).mul(price).div(1e18)
        );
    }

    /// @notice View underlying token decimals by gToken address
    /// @param gToken gToken address
    function _getDecimals(address gToken) internal view returns (uint256 decimals) {
        address underlying = IGToken(gToken).underlying();
        if (underlying == address(0)) {
            decimals = 18; // ETH
        } else {
            decimals = IBEP20(underlying).decimals();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "../interfaces/IWhiteholePair.sol";
import "../dex/WhiteholePair.sol";

library WhiteholeLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "WhiteholeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "WhiteholeLibrary: ZERO_ADDRESS");
    }

    // calculate the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"7d1ff54958e8ac533f125a31946702b91ad19c8bec8fd0488b77175950887d96" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IWhiteholePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "WhiteholeLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "WhiteholeLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "WhiteholeLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "WhiteholeLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(9975);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "WhiteholeLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "WhiteholeLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        uint256 denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "WhiteholeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "WhiteholeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WhitelistUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _whitelist;
    bool private _disable; // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted() {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function __WhitelistUpgradeable_init() internal initializer {
        __Ownable_init();
    }

    function isWhitelist(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        _whitelist[_address] = _on;

        emit Whitelisted(_address, _on);
    }

    function disableWhitelist(bool disable) external onlyOwner {
        _disable = disable;
        if (disable) {
            emit DisableWhitelist();
        } else {
            emit EnableWhitelist();
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./NftMarket.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

contract GNft is NftMarket, ERC721Upgradeable, IERC721ReceiverUpgradeable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address public lendPoolLoan;
    mapping(uint256 => address) private _minters;

    /* ========== MODIFIERS ========== */

    modifier onlyLendPoolLoan() {
        require(msg.sender == lendPoolLoan, "GNft: only lendPoolLoan contract");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize(string calldata gNftName, string calldata gNftSymbol, address _lendPoolLoan) external initializer {
        __ERC721_init(gNftName, gNftSymbol);
        __GMarket_init();
        lendPoolLoan = _lendPoolLoan;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(address to, uint256 tokenId) external override onlyLendPoolLoan nonReentrant {
        require(IERC721Upgradeable(underlying).ownerOf(tokenId) == msg.sender, "GNft: caller is not owner");

        _mint(to, tokenId);

        _minters[tokenId] = msg.sender;

        IERC721Upgradeable(underlying).safeTransferFrom(msg.sender, address(this), tokenId);

        emit Mint(msg.sender, underlying, tokenId, to);
    }

    function burn(uint256 tokenId) external override nonReentrant {
        require(_exists(tokenId), "GNft: nonexist token");
        require(_minters[tokenId] == msg.sender, "GNft: caller is not minter");

        address tokenOwner = IERC721Upgradeable(underlying).ownerOf(tokenId);

        _burn(tokenId);

        delete _minters[tokenId];

        IERC721Upgradeable(underlying).safeTransferFrom(address(this), msg.sender, tokenId);

        emit Burn(msg.sender, underlying, tokenId, tokenOwner);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        to;
        tokenId;
        revert("APPROVAL_NOT_SUPPORTED");
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        operator;
        approved;
        revert("APPROVAL_NOT_SUPPORTED");
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        from;
        to;
        tokenId;
        revert("TRANSFER_NOT_SUPPORTED");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        from;
        to;
        tokenId;
        revert("TRANSFER_NOT_SUPPORTED");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        from;
        to;
        tokenId;
        _data;
        revert("TRANSFER_NOT_SUPPORTED");
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        from;
        to;
        tokenId;
        revert("TRANSFER_NOT_SUPPORTED");
    }

    /* ========== VIEWS ========== */

    function minterOf(uint256 tokenId) public view override returns (address) {
        address _minter = _minters[tokenId];
        require(_minter != address(0), "GNft: minter query for nonexistent token");
        return _minter;
    }

    /* ========== RECEIVER FUNCTIONS ========== */

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";

import "../library/SafeToken.sol";

import "./Market.sol";

import "../interfaces/IWETH.sol";

contract GToken is Market {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== STATE VARIABLES ========== */

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => mapping(address => uint256)) private _transferAllowances;

    /* ========== EVENT ========== */

    event Mint(address minter, uint256 mintAmount);
    event Redeem(
        address account,
        uint256 underlyingAmount,
        uint256 gTokenAmount,
        uint256 uAmountToReceive,
        uint256 uAmountRedeemFee
    );

    event Borrow(address account, uint256 ammount, uint256 accountBorrow);
    event RepayBorrow(address payer, address borrower, uint256 amount, uint256 accountBorrow);
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 amount,
        address gTokenCollateral,
        uint256 seizeAmount
    );

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /* ========== INITIALIZER ========== */

    /// @notice Initialization
    /// @param _name name
    /// @param _symbol symbol
    /// @param _decimals decimals
    function initialize(string memory _name, string memory _symbol, uint8 _decimals) external initializer {
        __GMarket_init();

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /* ========== VIEWS ========== */

    /// @notice View allowance
    /// @param account Account address
    /// @param spender Spender address
    /// @return Allowance amount
    function allowance(address account, address spender) external view override returns (uint256) {
        return _transferAllowances[account][spender];
    }

    /// @notice Owner address 조회
    function getOwner() external view returns (address) {
        return owner();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function transfer(address dst, uint256 amount) external override accrue nonReentrant returns (bool) {
        core.transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external override accrue nonReentrant returns (bool) {
        core.transferTokens(msg.sender, src, dst, amount);
        return true;
    }

    /// @notice account 의 allowance amount 변경
    /// @param spender spender address
    /// @param amount amount
    function approve(address spender, uint256 amount) external override returns (bool) {
        _transferAllowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Update supply information
    /// @param account Account address to supply
    /// @param uAmount Underlying token amount to supply
    /// @return gAmount gToken amount to receive
    function supply(address account, uint256 uAmount) external payable override accrue onlyCore returns (uint256) {
        uint256 exchangeRate = exchangeRate();
        uAmount = underlying == address(ETH) ? msg.value : uAmount;
        uAmount = _doTransferIn(account, uAmount);
        uint256 gAmount = uAmount.mul(1e18).div(exchangeRate);
        require(gAmount > 0, "GToken: invalid gAmount");
        updateSupplyInfo(account, gAmount, 0);

        emit Mint(account, gAmount);
        emit Transfer(address(0), account, gAmount);
        return gAmount;
    }

    /// @notice Redeem token by gToken amount
    /// @param redeemer Redeemer account address
    /// @param gAmount gToken amount
    function redeemToken(address redeemer, uint256 gAmount) external override accrue nftAccrue onlyCore returns (uint256) {
        return _redeem(redeemer, gAmount, 0);
    }

    /// @notice Redeem token by underlying token amount
    /// @param redeemer Redeemer account address
    /// @param uAmount Underlying token amount
    function redeemUnderlying(address redeemer, uint256 uAmount) external override accrue nftAccrue onlyCore returns (uint256) {
        return _redeem(redeemer, 0, uAmount);
    }

    /// @notice Update borrow information
    /// @param account Borrower account address
    /// @param amount Borrow amount
    function borrow(address account, uint256 amount) external override accrue nftAccrue onlyCore returns (uint256) {
        require(getCash() >= amount, "GToken: borrow amount exceeds cash");
        updateBorrowInfo(account, amount, 0);
        _doTransferOut(account, amount);

        emit Borrow(account, amount, borrowBalanceOf(account));
        return amount;
    }

    /// @notice Repay own borrowing dept
    /// @dev Called when repay my own debt only
    /// @param account Borrower account address
    /// @param amount Repay amount
    function repayBorrow(address account, uint256 amount) external payable override accrue onlyCore returns (uint256) {
        if (amount == uint256(-1)) {
            amount = borrowBalanceOf(account);
        }
        return _repay(account, account, underlying == address(ETH) ? msg.value : amount);
    }

    /// @notice Repay others' debt behalf
    /// @dev Called when repay others' debt behalf
    /// @param payer Account address who pay for the debt
    /// @param borrower Account address who borrowing debt
    /// @param amount Dept amount to repay
    function repayBorrowBehalf(
        address payer,
        address borrower,
        uint256 amount
    ) external payable override accrue onlyCore returns (uint256) {
        return _repay(payer, borrower, underlying == address(ETH) ? msg.value : amount);
    }

    /// @notice Force to liquidate others debt
    /// @param gTokenCollateral gToken address provided as collateral
    /// @param liquidator Liquidator account address
    /// @param borrower Borrower account address
    /// @param amount Collateral amount
    function liquidateBorrow(
        address gTokenCollateral,
        address liquidator,
        address borrower,
        uint256 amount
    )
        external
        payable
        override
        accrue
        onlyCore
        returns (uint256 seizeGAmount, uint256 rebateGAmount, uint256 liquidatorGAmount)
    {
        require(borrower != liquidator, "GToken: cannot liquidate yourself");
        amount = underlying == address(ETH) ? msg.value : amount;
        amount = _repay(liquidator, borrower, amount);
        require(amount > 0 && amount < uint256(-1), "GToken: invalid repay amount");

        (seizeGAmount, rebateGAmount, liquidatorGAmount) = IValidator(core.validator()).gTokenAmountToSeize(
            address(this),
            gTokenCollateral,
            amount
        );

        require(
            IGToken(payable(gTokenCollateral)).balanceOf(borrower) >= seizeGAmount,
            "GToken: too much seize amount"
        );

        emit LiquidateBorrow(liquidator, borrower, amount, gTokenCollateral, seizeGAmount);
    }

    function seize(
        address liquidator,
        address borrower,
        uint256 gAmount
    ) external override accrue onlyCore nonReentrant {
        accountBalances[borrower] = accountBalances[borrower].sub(gAmount);
        accountBalances[liquidator] = accountBalances[liquidator].add(gAmount);

        emit Transfer(borrower, liquidator, gAmount);
    }

    function withdrawReserves() external override accrue onlyRebateDistributor nonReentrant {
        if (getCash() >= totalReserve) {
            uint256 amount = totalReserve;

            if (totalReserve > 0) {
                totalReserve = 0;
                _doTransferOut(address(rebateDistributor), amount);
            }
        }
    }

    /// @notice Transfer interneal
    /// @param spender Spender account address
    /// @param src Source account address
    /// @param dst Destination account address
    /// @param amount Transfer amount
    function transferTokensInternal(
        address spender,
        address src,
        address dst,
        uint256 amount
    ) external override onlyCore {
        require(
            src != dst && IValidator(core.validator()).redeemAllowed(address(this), src, amount),
            "GToken: cannot transfer"
        );
        require(amount != 0, "GToken: zero amount");
        uint256 _allowance = spender == src ? uint256(-1) : _transferAllowances[src][spender];
        uint256 _allowanceNew = _allowance.sub(amount, "GToken: transfer amount exceeds allowance");

        accountBalances[src] = accountBalances[src].sub(amount);
        accountBalances[dst] = accountBalances[dst].add(amount);

        if (_allowance != uint256(-1)) {
            _transferAllowances[src][spender] = _allowanceNew;
        }
        emit Transfer(src, dst, amount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /// @notice Transfer in underlying token
    /// @param from Transfer from address
    /// @param amount Transfer amount
    /// @return Transfered amount
    function _doTransferIn(address from, uint256 amount) private returns (uint256) {
        if (underlying == address(ETH)) {
            require(msg.value >= amount, "GToken: value mismatch");
            return Math.min(msg.value, amount);
        } else {
            uint256 balanceBefore = IBEP20(underlying).balanceOf(address(this));
            underlying.safeTransferFrom(from, address(this), amount);
            uint256 balanceAfter = IBEP20(underlying).balanceOf(address(this));
            require(balanceAfter.sub(balanceBefore) <= amount);
            return balanceAfter.sub(balanceBefore);
        }
    }

    /// @notice Transfer out underlying token
    /// @param to Transfer target add
    /// @param amount Transfer amount
    function _doTransferOut(address to, uint256 amount) private {
        if (underlying == address(ETH)) {
            SafeToken.safeTransferETH(to, amount);
        } else {
            underlying.safeTransfer(to, amount);
        }
    }

    /// @notice Redeem underlying token
    /// @dev Use only one of the amount params (gAmountIn or uAmountIn)
    ///      Pass unused parameter to 0
    /// @param account Redeemer account
    /// @param gAmountIn Redeem amount calculated by gToken amount
    /// @param uAmountIn Redeem amount
    function _redeem(address account, uint256 gAmountIn, uint256 uAmountIn) private returns (uint256) {
        require(gAmountIn == 0 || uAmountIn == 0, "GToken: one of gAmountIn or uAmountIn must be zero");
        require(totalSupply >= gAmountIn, "GToken: not enough total supply");
        require(getCash() >= uAmountIn || uAmountIn == 0, "GToken: not enough underlying");
        require(
            getCash() >= gAmountIn.mul(exchangeRate()).div(1e18) || gAmountIn == 0,
            "GToken: not enough underlying"
        );

        IValidator validator = IValidator(core.validator());
        uint256 gAmountToRedeem = gAmountIn > 0 ? gAmountIn : uAmountIn.mul(1e18).div(exchangeRate());
        uint256 uAmountToRedeem = gAmountIn > 0 ? gAmountIn.mul(exchangeRate()).div(1e18) : uAmountIn;

        require(validator.redeemAllowed(address(this), account, gAmountToRedeem), "GToken: cannot redeem");

        uint256 redeemFeeRate = validator.getAccountRedeemFeeRate(account);
        uint256 uAmountRedeemFee = uAmountToRedeem.mul(redeemFeeRate).div(1e4);
        uint256 uAmountToReceive = uAmountToRedeem.sub(uAmountRedeemFee);

        updateSupplyInfo(account, 0, gAmountToRedeem);
        _doTransferOut(account, uAmountToReceive);
        _doTransferOut(core.rebateDistributor(), uAmountRedeemFee);

        emit Transfer(account, address(0), gAmountToRedeem);
        emit Redeem(account, uAmountToRedeem, gAmountToRedeem, uAmountToReceive, uAmountRedeemFee);
        return uAmountToRedeem;
    }

    /// @notice Repay borrowing debt and update borrow information
    /// @param payer Payer account address
    /// @param borrower Borrower account address
    function _repay(address payer, address borrower, uint256 amount) private returns (uint256) {
        uint256 borrowBalance = borrowBalanceOf(borrower);
        uint256 repayAmount = Math.min(borrowBalance, amount);
        repayAmount = _doTransferIn(payer, repayAmount);
        updateBorrowInfo(borrower, 0, repayAmount);

        if (underlying == address(ETH)) {
            uint256 refundAmount = amount > repayAmount ? amount.sub(repayAmount) : 0;
            if (refundAmount > 0) {
                _doTransferOut(payer, refundAmount);
            }
        }

        emit RepayBorrow(payer, borrower, repayAmount, borrowBalanceOf(borrower));
        return repayAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../interfaces/IRateModel.sol";

/// @dev https://bscscan.com/address/0x9535c1f26df97451671913f7aeda646c0f1eda85#readProxyContract
contract RateModelSlope is IRateModel, OwnableUpgradeable {
    using SafeMath for uint256;

    uint256 private baseRatePerYear;
    uint256 private slopePerYearFirst;
    uint256 private slopePerYearSecond;
    uint256 private optimal;

    /// @notice Contract 초기화 변수 설정
    /// @param _baseRatePerYear 기본 이자율
    /// @param _slopePerYearFirst optimal 이전 이자 계수
    /// @param _slopePerYearSecond optimal 초과 이자 계수
    /// @param _optimal double-slope optimal
    function initialize(
        uint256 _baseRatePerYear,
        uint256 _slopePerYearFirst,
        uint256 _slopePerYearSecond,
        uint256 _optimal
    ) external initializer {
        __Ownable_init();

        baseRatePerYear = _baseRatePerYear;
        slopePerYearFirst = _slopePerYearFirst;
        slopePerYearSecond = _slopePerYearSecond;
        optimal = _optimal;
    }

    /// @notice Utilization rate 조회
    /// @dev Utilization rate = Borrows / (Supplies - Reserves)
    ///      Supplies = Cash + Borrows
    /// @param cash Underlying token amount in gToken contract
    /// @param borrows borrow amount
    /// @param reserves reserve amount
    function utilizationRate(uint256 cash, uint256 borrows, uint256 reserves) public pure returns (uint256) {
        if (reserves >= cash.add(borrows)) return 0;
        return Math.min(borrows.mul(1e18).div(cash.add(borrows).sub(reserves)), 1e18);
    }

    /// @notice Interest rate (Borrow rate) 조회
    /// @param cash Underlying token amount in gToken contract
    /// @param borrows borrow amount
    /// @param reserves reserve amount
    function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) public view override returns (uint256) {
        uint256 utilization = utilizationRate(cash, borrows, reserves);
        if (optimal > 0 && utilization < optimal) {
            return baseRatePerYear.add(utilization.mul(slopePerYearFirst).div(optimal)).div(365 days);
        } else {
            uint256 ratio = utilization.sub(optimal).mul(1e18).div(uint256(1e18).sub(optimal));
            return baseRatePerYear.add(slopePerYearFirst).add(ratio.mul(slopePerYearSecond).div(1e18)).div(365 days);
        }
    }

    /// @notice Interest rate (Borrow rate) 조회
    /// @param cash Underlying token amount in gToken contract
    /// @param borrows borrow amount
    /// @param reserves reserve amount
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactor
    ) public view override returns (uint256) {
        uint256 oneMinusReserveFactor = uint256(1e18).sub(reserveFactor);
        uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
        uint256 rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import "../library/SafeToken.sol";
import "../library/WhitelistUpgradeable.sol";

import "../interfaces/ICore.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IFlashLoanReceiver.sol";
import "../interfaces/IPool.sol";

contract Liquidation is IFlashLoanReceiver, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    address private constant ETH = address(0);
    address private constant WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address private constant WBTC = address(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    address private constant DAI = address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
    address private constant USDT = address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    address private constant USDC = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

    IUniswapV2Factory private constant factory = IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);
    IUniswapV2Router02 private constant router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    IPool private constant lendPool = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    /* ========== STATE VARIABLES ========== */

    mapping(address => mapping(address => bool)) private tokenApproval;
    ICore public core;
    IPriceCalculator public priceCalculator;

    receive() external payable {}

    /* ========== Event ========== */

    event Liquidated(
        address gTokenBorrowed,
        address gTokenCollateral,
        address borrower,
        uint256 amount,
        uint256 rebateAmount
    );

    /* ========== INITIALIZER ========== */

    function initialize(address _core, address _priceCalculator) external initializer {
        require(_core != address(0), "Liquidation: core address can't be zero");
        require(_priceCalculator != address(0), "Liquidation: priceCalculator address can't be zero");

        __ReentrancyGuard_init();
        __WhitelistUpgradeable_init();

        core = ICore(_core);
        priceCalculator = IPriceCalculator(_priceCalculator);

        _approveTokens();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Liquidate borrower's debt by manual
    /// @param gTokenBorrowed Market of debt to liquidate
    /// @param gTokenCollateral Market of collateral to seize
    /// @param borrower Borrower account address
    /// @param amount Liquidate underlying amount
    function liquidate(
        address gTokenBorrowed,
        address gTokenCollateral,
        address borrower,
        uint256 amount
    ) external onlyWhitelisted nonReentrant {
        (uint256 collateralInUSD, , uint256 borrowInUSD) = core.accountLiquidityOf(borrower);
        require(borrowInUSD > collateralInUSD, "Liquidation: Insufficient shortfall");

        _flashLoan(gTokenBorrowed, gTokenCollateral, borrower, amount);

        address underlying = IGToken(gTokenBorrowed).underlying();

        emit Liquidated(
            gTokenBorrowed,
            gTokenCollateral,
            borrower,
            amount,
            underlying == ETH
                ? address(this).balance
                : IERC20(IGToken(gTokenBorrowed).underlying()).balanceOf(address(this))
        );

        _sendTokenToRebateDistributor(underlying);
    }

    /// @notice Liquidate borrower's max value debt using max value collateral
    /// @param borrower borrower account address
    function autoLiquidate(address borrower) external onlyWhitelisted nonReentrant {
        (uint256 collateralInUSD, , uint256 borrowInUSD) = core.accountLiquidityOf(borrower);
        require(borrowInUSD > collateralInUSD, "Liquidation: Insufficient shortfall");

        (address gTokenBorrowed, address gTokenCollateral) = _getTargetMarkets(borrower);
        uint256 liquidateAmount = _getMaxLiquidateAmount(gTokenBorrowed, gTokenCollateral, borrower);
        require(liquidateAmount > 0, "Liquidation: liquidate amount error");

        _flashLoan(gTokenBorrowed, gTokenCollateral, borrower, liquidateAmount);

        address underlying = IGToken(gTokenBorrowed).underlying();

        emit Liquidated(
            gTokenBorrowed,
            gTokenCollateral,
            borrower,
            liquidateAmount,
            underlying == ETH
                ? address(this).balance
                : IERC20(IGToken(gTokenBorrowed).underlying()).balanceOf(address(this))
        );

        _sendTokenToRebateDistributor(underlying);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _approveTokens() private {
        address[] memory markets = core.allMarkets();

        for (uint256 i = 0; i < markets.length; i++) {
            address token = IGToken(markets[i]).underlying();
            _approveToken(token, address(markets[i]));
            _approveToken(token, address(router));
            _approveToken(token, address(lendPool));
        }
        _approveToken(WETH, address(router));
        _approveToken(WETH, address(lendPool));
    }

    function _approveToken(address token, address spender) private {
        if (token != ETH && !tokenApproval[token][spender]) {
            token.safeApprove(spender, uint256(-1));
            tokenApproval[token][spender] = true;
        }
    }

    function _flashLoan(address gTokenBorrowed, address gTokenCollateral, address borrower, uint256 amount) private {
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory modes = new uint256[](1);
        bytes memory params = abi.encode(gTokenBorrowed, gTokenCollateral, borrower, amount);

        address underlying = IGToken(gTokenBorrowed).underlying();

        assets[0] = underlying == ETH ? WETH : underlying;
        amounts[0] = amount;
        modes[0] = 0;

        lendPool.flashLoan(address(this), assets, amounts, modes, address(this), params, 0);
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(lendPool), "Liquidation: Invalid sender");
        require(initiator == address(this), "Liquidation Invalid initiator");
        require(assets.length == 1, "Liquidation: Invalid assets");
        require(amounts.length == 1, "Liquidation: Invalid amounts");
        require(premiums.length == 1, "Liquidation: Invalid premiums");
        (address gTokenBorrowed, address gTokenCollateral, address borrower, uint256 liquidateAmount) = abi.decode(
            params,
            (address, address, address, uint256)
        );
        uint256 repayAmount = amounts[0].add(premiums[0]);

        if (assets[0] == WETH) {
            IWETH(WETH).withdraw(amounts[0]);
        }

        _liquidate(gTokenBorrowed, gTokenCollateral, borrower, liquidateAmount);

        if (IGToken(gTokenCollateral).underlying() == ETH) {
            IWETH(WETH).deposit{value: address(this).balance}();
        }

        if (gTokenCollateral != gTokenBorrowed) {
            _swapForRepay(gTokenCollateral, gTokenBorrowed, repayAmount);
        }

        return true;
    }

    function _liquidate(address gTokenBorrowed, address gTokenCollateral, address borrower, uint256 amount) private {
        if (IGToken(gTokenBorrowed).underlying() == ETH) {
            core.liquidateBorrow{value: amount}(gTokenBorrowed, gTokenCollateral, borrower, 0);
        } else {
            core.liquidateBorrow(gTokenBorrowed, gTokenCollateral, borrower, amount);
        }

        uint256 gTokenCollateralBalance = IGToken(gTokenCollateral).balanceOf(address(this));
        _redeemToken(gTokenCollateral, gTokenCollateralBalance);
    }

    function _getTargetMarkets(
        address account
    ) private view returns (address gTokenBorrowed, address gTokenCollateral) {
        uint256 maxSupplied;
        uint256 maxBorrowed;
        address[] memory markets = core.marketListOf(account);
        uint256[] memory prices = priceCalculator.getUnderlyingPrices(markets);

        for (uint256 i = 0; i < markets.length; i++) {
            uint256 borrowValue = IGToken(markets[i]).borrowBalanceOf(account).mul(prices[i]).div(1e18);
            uint256 supplyValue = IGToken(markets[i]).underlyingBalanceOf(account).mul(prices[i]).div(1e18);

            if (borrowValue > 0 && borrowValue > maxBorrowed) {
                maxBorrowed = borrowValue;
                gTokenBorrowed = markets[i];
            }

            uint256 collateralFactor = core.marketInfoOf(markets[i]).collateralFactor;
            if (collateralFactor > 0 && supplyValue > 0 && supplyValue > maxSupplied) {
                maxSupplied = supplyValue;
                gTokenCollateral = markets[i];
            }
        }
    }

    function _getMaxLiquidateAmount(
        address gTokenBorrowed,
        address gTokenCollateral,
        address borrower
    ) private view returns (uint256 liquidateAmount) {
        uint256 borrowPrice = priceCalculator.getUnderlyingPrice(gTokenBorrowed);
        uint256 supplyPrice = priceCalculator.getUnderlyingPrice(gTokenCollateral);
        require(supplyPrice != 0 && borrowPrice != 0, "Liquidation: price error");

        uint256 borrowAmount = IGToken(gTokenBorrowed).borrowBalanceOf(borrower);
        uint256 supplyAmount = IGToken(gTokenCollateral).underlyingBalanceOf(borrower);

        uint256 borrowValue = borrowPrice.mul(borrowAmount).div(10 ** _getDecimals(gTokenBorrowed));
        uint256 supplyValue = supplyPrice.mul(supplyAmount).div(10 ** _getDecimals(gTokenCollateral));

        uint256 liquidationIncentive = core.liquidationIncentive();
        uint256 maxCloseValue = borrowValue.mul(core.closeFactor()).div(1e18);
        uint256 maxCloseValueWithIncentive = maxCloseValue.mul(liquidationIncentive).div(1e18);

        liquidateAmount = maxCloseValueWithIncentive < supplyValue
            ? maxCloseValue.mul(1e18).div(borrowPrice).div(10 ** (18 - _getDecimals(gTokenBorrowed)))
            : supplyValue.mul(1e36).div(liquidationIncentive).div(borrowPrice).div(
                10 ** (18 - _getDecimals(gTokenBorrowed))
            );
    }

    function _redeemToken(address gToken, uint256 gAmount) private {
        core.redeemToken(gToken, gAmount);
    }

    function _sendTokenToRebateDistributor(address token) private {
        address rebateDistributor = core.rebateDistributor();
        uint256 balance = token == ETH ? address(this).balance : IERC20(token).balanceOf(address(this));

        if (balance > 0 && token == ETH) {
            SafeToken.safeTransferETH(rebateDistributor, balance);
        } else if (balance > 0) {
            token.safeTransfer(rebateDistributor, balance);
        }
    }

    function _swapForRepay(address gTokenCollateral, address gTokenBorrowed, uint256 minReceiveAmount) private {
        address collateralToken = IGToken(gTokenCollateral).underlying();
        if (collateralToken == ETH) {
            collateralToken = WETH;
        }

        uint256 collateralTokenAmount = IERC20(collateralToken).balanceOf(address(this));
        require(collateralTokenAmount > 0, "Liquidation: Insufficent collateral");

        address borrowToken = IGToken(gTokenBorrowed).underlying();
        _swapToken(collateralToken, collateralTokenAmount, borrowToken, minReceiveAmount);
    }

    function _swapToken(address token, uint256 amount, address receiveToken, uint256 minReceiveAmount) private {
        address[] memory path = _getSwapPath(token == ETH ? WETH : token, receiveToken == ETH ? WETH : receiveToken);
        router.swapExactTokensForTokens(amount, minReceiveAmount, path, address(this), block.timestamp);
    }

    function _getSwapPath(address token1, address token2) private pure returns (address[] memory) {
        if (token1 == WETH || token2 == WETH) {
            address[] memory path = new address[](2);
            path[0] = token1;
            path[1] = token2;
            return path;
        } else {
            address[] memory path = new address[](3);
            path[0] = token1;
            path[1] = WETH;
            path[2] = token2;
            return path;
        }
    }

    /// @notice View underlying token decimals by gToken address
    /// @param gToken gToken address
    function _getDecimals(address gToken) private view returns (uint256 decimals) {
        address underlying = IGToken(gToken).underlying();
        if (underlying == address(0)) {
            decimals = 18;
        } else {
            decimals = IERC20(underlying).decimals();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../library/Constant.sol";

import "../interfaces/IBEP20.sol";
import "../interfaces/IValidator.sol";
import "../interfaces/IRateModel.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/ICore.sol";
import "../interfaces/IRebateDistributor.sol";
import "../interfaces/INftCore.sol";
import "../interfaces/ILendPoolLoan.sol";

abstract contract Market is IGToken, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 internal constant RESERVE_FACTOR_MAX = 1e18;
    uint256 internal constant DUST = 1000;

    address internal constant ETH = 0x0000000000000000000000000000000000000000;

    /* ========== STATE VARIABLES ========== */

    ICore public core;
    IRateModel public rateModel;
    IRebateDistributor public rebateDistributor;
    address public override underlying;

    uint256 public override totalSupply; // Total supply of gToken
    uint256 public override totalReserve;
    uint256 public override _totalBorrow;

    mapping(address => uint256) internal accountBalances;
    mapping(address => Constant.BorrowInfo) internal accountBorrows;

    uint256 public override reserveFactor;
    uint256 public override lastAccruedTime;
    uint256 public override accInterestIndex;

    /* ========== VARIABLE GAP ========== */

    uint256[49] private __gap;

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    /// @dev Initialization
    function __GMarket_init() internal initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        lastAccruedTime = block.timestamp;
        accInterestIndex = 1e18;
    }

    /* ========== MODIFIERS ========== */

    /// @dev 아직 처리되지 않은 totalBorrow, totalReserve, accInterestIndex 계산 및 저장
    modifier accrue() {
        if (block.timestamp > lastAccruedTime && address(rateModel) != address(0)) {
            uint256 borrowRate = rateModel.getBorrowRate(getCashPrior(), _totalBorrow, totalReserve);
            uint256 interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint256 pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            _totalBorrow = _totalBorrow.add(pendingInterest);
            totalReserve = totalReserve.add(pendingInterest.mul(reserveFactor).div(1e18));
            accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
            lastAccruedTime = block.timestamp;
        }
        _;
    }

    modifier nftAccrue() {
        if (block.timestamp > lastAccruedTime && address(rateModel) != address(0)) {
            if (underlying == address(ETH)) {
                ILendPoolLoan(INftCore(core.nftCore()).getLendPoolLoan()).accrueInterest();
            }
        }
        _;
    }

    /// @dev msg.sender 가 core address 인지 검증
    modifier onlyCore() {
        require(msg.sender == address(core), "GToken: only Core Contract");
        _;
    }

    modifier onlyRebateDistributor() {
        require(msg.sender == address(rebateDistributor), "GToken: only RebateDistributor");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice core address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    ///      설정 이후에는 다른 주소로 변경할 수 없음
    /// @param _core core contract address
    function setCore(address _core) public onlyOwner {
        require(_core != address(0), "GMarket: invalid core address");
        require(address(core) == address(0), "GMarket: core already set");
        core = ICore(_core);
    }

    /// @notice underlying asset 의 token 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    ///      설정 이후에는 다른 주소로 변경할 수 없음
    /// @param _underlying Underlying token contract address
    function setUnderlying(address _underlying) public onlyOwner {
        require(_underlying != address(0), "GMarket: invalid underlying address");
        require(underlying == address(0), "GMarket: set underlying already");
        underlying = _underlying;
    }

    /// @notice rateModel 설정
    /// @param _rateModel 새로운 RateModel contract address
    function setRateModel(address _rateModel) public accrue onlyOwner {
        require(_rateModel != address(0), "GMarket: invalid rate model address");
        rateModel = IRateModel(_rateModel);
    }

    /// @notice reserve factor 변경
    /// @dev RESERVE_FACTOR_MAX 를 초과할 수 없음
    /// @param _reserveFactor 새로운 reserveFactor 값
    function setReserveFactor(uint256 _reserveFactor) public accrue onlyOwner {
        require(_reserveFactor <= RESERVE_FACTOR_MAX, "GMarket: invalid reserve factor");
        reserveFactor = _reserveFactor;
    }

    function setRebateDistributor(address _rebateDistributor) public onlyOwner {
        require(_rebateDistributor != address(0), "GMarket: invalid rebate distributor address");
        rebateDistributor = IRebateDistributor(_rebateDistributor);
    }

    /* ========== VIEWS ========== */

    /// @notice account 의 gToken 에 대한 balance 조회
    /// @param account account address
    function balanceOf(address account) external view override returns (uint256) {
        return accountBalances[account];
    }

    /// @notice account 의 AccountSnapshot 조회
    /// @param account account address
    function accountSnapshot(address account) external view override returns (Constant.AccountSnapshot memory) {
        Constant.AccountSnapshot memory snapshot;
        snapshot.gTokenBalance = accountBalances[account];
        snapshot.borrowBalance = borrowBalanceOf(account);
        snapshot.exchangeRate = exchangeRate();
        return snapshot;
    }

    /// @notice account 의 supply 된 underlying token 의 amount 조회
    /// @dev 원금에 붙은 이자를 포함
    /// @param account account address
    function underlyingBalanceOf(address account) external view override returns (uint256) {
        return accountBalances[account].mul(exchangeRate()).div(1e18);
    }

    /// @notice 계정의 borrow amount 조회
    /// @dev 원금에 붙은 이자를 포함
    function borrowBalanceOf(address account) public view override returns (uint256) {
        Constant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        Constant.BorrowInfo storage info = accountBorrows[account];

        if (info.borrow == 0) return 0;
        return info.borrow.mul(snapshot.accInterestIndex).div(info.interestIndex);
    }

    /// @notice totalBorrow 조회
    function totalBorrow() public view override returns (uint256) {
        Constant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return snapshot.totalBorrow;
    }

    /// @notice gToken 과 underlying token 의 교환비율 조회
    /// @dev Exchange rate = (Total pure supplies / Total gToken supplies)
    function exchangeRate() public view override returns (uint256) {
        if (totalSupply == 0) return 1e18;
        Constant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return getCashPrior().add(snapshot.totalBorrow).sub(snapshot.totalReserve).mul(1e18).div(totalSupply);
    }

    /// @notice contract 가 가지고 있는 underlying token amount 조회
    /// @dev underlying token 이 ETH 인 경우 msg.value 값을 빼서 계산함
    function getCash() public view override returns (uint256) {
        return getCashPrior();
    }

    function getRateModel() external view override returns (address) {
        return address(rateModel);
    }

    /// @notice accInterestIndex 조회
    function getAccInterestIndex() public view override returns (uint256) {
        Constant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return snapshot.accInterestIndex;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice View account snapshot after accure mutation
    function accruedAccountSnapshot(
        address account
    ) external override accrue returns (Constant.AccountSnapshot memory) {
        Constant.AccountSnapshot memory snapshot;
        Constant.BorrowInfo storage info = accountBorrows[account];
        if (info.interestIndex != 0) {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex);
            info.interestIndex = accInterestIndex;
        }

        snapshot.gTokenBalance = accountBalances[account];
        snapshot.borrowBalance = info.borrow;
        snapshot.exchangeRate = exchangeRate();
        return snapshot;
    }

    /// @notice View borrow balance amount after accure mutation
    function accruedBorrowBalanceOf(address account) external override accrue returns (uint256) {
        Constant.BorrowInfo storage info = accountBorrows[account];
        if (info.interestIndex != 0) {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex);
            info.interestIndex = accInterestIndex;
        }
        return info.borrow;
    }

    /// @notice View total borrow amount after accrue mutation
    function accruedTotalBorrow() external override accrue returns (uint256) {
        return _totalBorrow;
    }

    /// @notice View underlying token exchange rate after accure mutation
    function accruedExchangeRate() external override accrue returns (uint256) {
        return exchangeRate();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /// @notice borrow info 업데이트
    /// @dev account 의 accountBorrows 를 변경하고, totalSupply 를 변경함
    /// @param account borrow 하는 address account
    /// @param addAmount 추가되는 borrow amount
    /// @param subAmount 제거되는 borrow amount
    function updateBorrowInfo(address account, uint256 addAmount, uint256 subAmount) internal {
        Constant.BorrowInfo storage info = accountBorrows[account];
        if (info.interestIndex == 0) {
            info.interestIndex = accInterestIndex;
        }

        info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex).add(addAmount).sub(subAmount);
        info.interestIndex = accInterestIndex;
        _totalBorrow = _totalBorrow.add(addAmount).sub(subAmount);

        info.borrow = (info.borrow < DUST) ? 0 : info.borrow;
        _totalBorrow = (_totalBorrow < DUST) ? 0 : _totalBorrow;
    }

    /// @notice supply info 업데이트
    /// @dev account 의 accountBalances 를 변경하고, totalSupply 를 변경함
    /// @param account supply 하는 address account
    /// @param addAmount 추가되는 supply amount
    /// @param subAmount 제거되는 supply amount
    function updateSupplyInfo(address account, uint256 addAmount, uint256 subAmount) internal {
        accountBalances[account] = accountBalances[account].add(addAmount).sub(subAmount);
        totalSupply = totalSupply.add(addAmount).sub(subAmount);

        totalSupply = (totalSupply < DUST) ? 0 : totalSupply;
    }

    /// @notice contract 가 가지고 있는 underlying token amount 조회
    /// @dev underlying token 이 ETH 인 경우 msg.value 값을 빼서 계산함
    function getCashPrior() internal view returns (uint256) {
        return
            underlying == address(ETH)
                ? address(this).balance.sub(msg.value)
                : IBEP20(underlying).balanceOf(address(this));
    }

    /// @notice totalBorrow, totlaReserver, accInterestIdx 조회
    /// @dev 아직 계산되지 않은 pending interest 더한 값으로 조회
    ///      상태가 변겅되거나 저장되지는 않는다
    function pendingAccrueSnapshot() internal view returns (Constant.AccrueSnapshot memory) {
        Constant.AccrueSnapshot memory snapshot;
        snapshot.totalBorrow = _totalBorrow;
        snapshot.totalReserve = totalReserve;
        snapshot.accInterestIndex = accInterestIndex;

        if (block.timestamp > lastAccruedTime && _totalBorrow > 0) {
            uint256 borrowRate = rateModel.getBorrowRate(getCashPrior(), _totalBorrow, totalReserve);
            uint256 interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint256 pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            snapshot.totalBorrow = _totalBorrow.add(pendingInterest);
            snapshot.totalReserve = totalReserve.add(pendingInterest.mul(reserveFactor).div(1e18));
            snapshot.accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
        }
        return snapshot;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../library/Constant.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IValidator.sol";
import "../interfaces/IRateModel.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/ICore.sol";
import "../interfaces/IMarketView.sol";

contract MarketView is IMarketView, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    mapping(address => IRateModel) public rateModel;

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRateModel(address gToken, address _rateModel) public onlyOwner {
        require(_rateModel != address(0), "MarketView: invalid rate model address");
        rateModel[gToken] = IRateModel(_rateModel);
    }

    /* ========== VIEWS ========== */

    function borrowRatePerSec(address gToken) external view override returns (uint256) {
        Constant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot(IGToken(gToken));
        return rateModel[gToken].getBorrowRate(IGToken(gToken).getCash(), snapshot.totalBorrow, snapshot.totalReserve);
    }

    function supplyRatePerSec(address gToken) external view override returns (uint256) {
        Constant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot(IGToken(gToken));
        return
            rateModel[gToken].getSupplyRate(
                IGToken(gToken).getCash(),
                snapshot.totalBorrow,
                snapshot.totalReserve,
                IGToken(gToken).reserveFactor()
            );
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function pendingAccrueSnapshot(IGToken gToken) internal view returns (Constant.AccrueSnapshot memory) {
        Constant.AccrueSnapshot memory snapshot;
        snapshot.totalBorrow = gToken._totalBorrow();
        snapshot.totalReserve = gToken.totalReserve();
        snapshot.accInterestIndex = gToken.accInterestIndex();

        uint256 reserveFactor = gToken.reserveFactor();
        uint256 lastAccruedTime = gToken.lastAccruedTime();

        if (block.timestamp > lastAccruedTime && snapshot.totalBorrow > 0) {
            uint256 borrowRate = rateModel[address(gToken)].getBorrowRate(
                gToken.getCash(),
                snapshot.totalBorrow,
                snapshot.totalReserve
            );
            uint256 interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint256 pendingInterest = snapshot.totalBorrow.mul(interestFactor).div(1e18);

            snapshot.totalBorrow = snapshot.totalBorrow.add(pendingInterest);
            snapshot.totalReserve = snapshot.totalReserve.add(pendingInterest.mul(reserveFactor).div(1e18));
            snapshot.accInterestIndex = snapshot.accInterestIndex.add(
                interestFactor.mul(snapshot.accInterestIndex).div(1e18)
            );
        }
        return snapshot;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IGNft.sol";
import "../interfaces/INftCore.sol";


abstract contract NftMarket is IGNft, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    INftCore public nftCore;
    address public override underlying;

    /* ========== INITIALIZER ========== */

    function __GMarket_init() internal initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyNftCore() {
        require(msg.sender == address(nftCore), "GNft: only nft core contract");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setNftCore(address _nftCore) public onlyOwner {
        require(_nftCore != address(0), "GNft: invalid core address");
        require(address(nftCore) == address(0), "GNft: core already set");
        nftCore = INftCore(_nftCore);
    }

    function setUnderlying(address _underlying) public onlyOwner {
        require(_underlying != address(0), "GNft: invalid underlying address");
        require(underlying == address(0), "GNft: set underlying already");
        underlying = _underlying;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./library/SafeToken.sol";

import "./NftCoreAdmin.sol";
import "./interfaces/IGNft.sol";
import "./interfaces/INftValidator.sol";

contract NftCore is NftCoreAdmin {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== INITIALIZER ========== */

    function initialize(
        address _nftOracle,
        address _borrowMarket,
        address _core,
        address _treasury
    ) external initializer {
        __NftCore_init(_nftOracle, _borrowMarket, _core, _treasury);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyMarket() {
        bool fromMarket = false;
        for (uint256 i = 0; i < markets.length; i++) {
            if (msg.sender == markets[i]) {
                fromMarket = true;
                break;
            }
        }
        require(fromMarket == true, "NftCore: caller should be market");
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "NftCore: not eoa");
        _;
    }

    /* ========== VIEWS ========== */

    function allMarkets() external view override returns (address[] memory) {
        return markets;
    }

    function marketInfoOf(address gNft) external view override returns (Constant.NftMarketInfo memory) {
        return marketInfos[gNft];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function withdrawBalance() external onlyOwner {
        uint256 _balance = address(this).balance;
        if (_balance > 0) {
            SafeToken.safeTransferETH(treasury, _balance);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function borrow(
        address gNft,
        uint256 tokenId,
        uint256 amount
    ) external override onlyListedMarket(gNft) nonReentrant whenNotPaused {
        _borrow(gNft, tokenId, amount);
    }

    function batchBorrow(
        address gNft,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external override onlyListedMarket(gNft) nonReentrant whenNotPaused {
        require(tokenIds.length == amounts.length, "NftCore: inconsistent amounts length");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _borrow(gNft, tokenIds[i], amounts[i]);
        }
    }

    function _borrow(address gNft, uint256 tokenId, uint256 amount) private {
        address nftAsset = IGNft(gNft).underlying();
        uint256 loanId = lendPoolLoan.getCollateralLoanId(nftAsset, tokenId);

        validator.validateBorrow(
            msg.sender,
            amount,
            gNft,
            loanId
        );

        if (loanId == 0) {
            IERC721Upgradeable(nftAsset).safeTransferFrom(msg.sender, address(this), tokenId);

            loanId = lendPoolLoan.createLoan(
                msg.sender,
                nftAsset,
                tokenId,
                gNft,
                amount
            );
        } else {
            lendPoolLoan.updateLoan(
                loanId,
                amount,
                0
            );
        }
        core.nftBorrow(borrowMarket, msg.sender, amount);
        SafeToken.safeTransferETH(msg.sender, amount);
        emit Borrow(
            msg.sender,
            amount,
            nftAsset,
            tokenId,
            loanId,
            0 // referral
        );
    }

    function repay(
        address gNft,
        uint256 tokenId
    ) external payable override onlyListedMarket(gNft) nonReentrant whenNotPaused {
        _repay(gNft, tokenId, msg.value);
    }

    function batchRepay(
        address gNft,
        uint256[] calldata tokenIds,
        uint256[] calldata repayAmounts
    ) external payable override onlyListedMarket(gNft) nonReentrant whenNotPaused {
        require(tokenIds.length == repayAmounts.length, "NftCore: inconsistent amounts length");

        uint256 allRepayAmount = 0;
        for (uint256 i = 0; i < repayAmounts.length; i++) {
            allRepayAmount = allRepayAmount.add(repayAmounts[i]);
        }
        require(msg.value >= allRepayAmount, "NftCore: msg.value less than all repay amount");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _repay(gNft, tokenIds[i], repayAmounts[i]);
        }

        if (msg.value > allRepayAmount) {
            SafeToken.safeTransferETH(msg.sender, msg.value.sub(allRepayAmount));
        }
    }

    function _repay(
        address gNft,
        uint256 tokenId,
        uint256 amount
    ) private {
        address nftAsset = IGNft(gNft).underlying();
        uint256 loanId = lendPoolLoan.getCollateralLoanId(nftAsset, tokenId);
        require(loanId > 0, "NftCore: collateral loan id not exist");

        Constant.LoanData memory loan = lendPoolLoan.getLoan(loanId);

        uint256 borrowBalance = lendPoolLoan.borrowBalanceOf(loanId);
        uint256 repayAmount = Math.min(borrowBalance, amount);

        validator.validateRepay(loanId, repayAmount, borrowBalance);

        if (repayAmount < borrowBalance) {
            lendPoolLoan.updateLoan(
                loanId,
                0,
                repayAmount
            );
        } else {
            lendPoolLoan.repayLoan(
                loanId,
                gNft,
                repayAmount
            );
            IERC721Upgradeable(nftAsset).safeTransferFrom(address(this), loan.borrower, tokenId);
        }

        core.nftRepayBorrow{value: repayAmount}(borrowMarket, loan.borrower, repayAmount);
        if (amount > repayAmount) {
            SafeToken.safeTransferETH(msg.sender, amount.sub(repayAmount));
        }
        emit Repay(
            msg.sender,
            repayAmount,
            nftAsset,
            tokenId,
            msg.sender,
            loanId
        );
    }

    function auction(
        address gNft,
        uint256 tokenId
    ) external payable override onlyListedMarket(gNft) onlyEOA nonReentrant whenNotPaused {
        address nftAsset = IGNft(gNft).underlying();
        uint256 loanId = lendPoolLoan.getCollateralLoanId(nftAsset, tokenId);
        require(loanId > 0, "NftCore: collateral loan id not exist");

        Constant.LoanData memory loan = lendPoolLoan.getLoan(loanId);
        uint256 borrowBalance = lendPoolLoan.borrowBalanceOf(loanId);

        validator.validateAuction(gNft, loanId, msg.value, borrowBalance);
        lendPoolLoan.auctionLoan(msg.sender, loanId, msg.value, borrowBalance);

        if (loan.bidderAddress != address(0)) {
            SafeToken.safeTransferETH(loan.bidderAddress, loan.bidPrice);
        }

        emit Auction(
            msg.sender,
            msg.value,
            nftAsset,
            tokenId,
            loan.borrower,
            loanId
        );
    }

    function redeem(
        address gNft,
        uint256 tokenId,
        uint256 repayAmount,
        uint256 bidFine
    ) external payable override onlyListedMarket(gNft) nonReentrant whenNotPaused {
        address nftAsset = IGNft(gNft).underlying();
        uint256 loanId = lendPoolLoan.getCollateralLoanId(nftAsset, tokenId);
        require(loanId > 0, "NftCore: collateral loan id not exist");
        require(msg.value >= (repayAmount.add(bidFine)), "NftCore: msg.value less than repayAmount + bidFine");

        Constant.LoanData memory loan = lendPoolLoan.getLoan(loanId);
        uint256 borrowBalance = lendPoolLoan.borrowBalanceOf(loanId);

        uint256 _bidFine = validator.validateRedeem(loanId, repayAmount, bidFine, borrowBalance);
        lendPoolLoan.redeemLoan(loanId, repayAmount);

        core.nftRepayBorrow{value: repayAmount}(borrowMarket, loan.borrower, repayAmount);

        if (loan.bidderAddress != address(0)) {
            SafeToken.safeTransferETH(loan.bidderAddress, loan.bidPrice);
            SafeToken.safeTransferETH(loan.firstBidderAddress, _bidFine);
        }

        uint256 paybackAmount = repayAmount.add(_bidFine);
        if (msg.value > paybackAmount) {
            SafeToken.safeTransferETH(msg.sender, msg.value.sub(paybackAmount));
        }
    }

    function liquidate(
        address gNft,
        uint256 tokenId
    ) external payable override onlyListedMarket(gNft) nonReentrant whenNotPaused {
        address nftAsset = IGNft(gNft).underlying();
        uint256 loanId = lendPoolLoan.getCollateralLoanId(nftAsset, tokenId);
        require(loanId > 0, "NftCore: collateral loan id not exist");

        Constant.LoanData memory loan = lendPoolLoan.getLoan(loanId);

        uint256 borrowBalance = lendPoolLoan.borrowBalanceOf(loanId);
        (uint256 extraDebtAmount, uint256 remainAmount) = validator.validateLiquidate(loanId, borrowBalance, msg.value);

        lendPoolLoan.liquidateLoan(gNft, loanId, borrowBalance);
        core.nftRepayBorrow{value: borrowBalance}(borrowMarket, loan.borrower, borrowBalance);

        if (remainAmount > 0) {
            uint256 auctionFee = remainAmount.mul(lendPoolLoan.auctionFeeRate()).div(1e18);
            remainAmount = remainAmount.sub(auctionFee);
            SafeToken.safeTransferETH(loan.borrower, remainAmount);
            SafeToken.safeTransferETH(treasury, auctionFee);
        }

        IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), loan.bidderAddress, loan.nftTokenId);

        if (msg.value > extraDebtAmount) {
            SafeToken.safeTransferETH(msg.sender, msg.value.sub(extraDebtAmount));
        }

        emit Liquidate(
            msg.sender,
            msg.value,
            remainAmount,
            loan.nftAsset,
            loan.nftTokenId,
            loan.borrower,
            loanId
        );
    }
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "./library/Constant.sol";

import "./interfaces/INftCore.sol";
import "./interfaces/INFTOracle.sol";
import "./interfaces/IGToken.sol";
import "./interfaces/IGNft.sol";
import "./interfaces/ICore.sol";
import "./interfaces/ILendPoolLoan.sol";
import "./interfaces/INftValidator.sol";

abstract contract NftCoreAdmin is INftCore, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, IERC721ReceiverUpgradeable {

    /* ========== STATE VARIABLES ========== */

    INFTOracle public nftOracle;
    ICore public core;
    ILendPoolLoan public lendPoolLoan;
    INftValidator public validator;

    address public borrowMarket;
    address public keeper;
    address public treasury;

    address[] public markets; // gNftAddress[]
    mapping(address => Constant.NftMarketInfo) public marketInfos; // (gNftAddress => NftMarketInfo)

    /* ========== MODIFIERS ========== */

    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == owner(), "NftCore: caller is not the owner or keeper");
        _;
    }

    modifier onlyListedMarket(address gNft) {
        require(marketInfos[gNft].isListed, "NftCore: invalid market");
        _;
    }

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function __NftCore_init(
        address _nftOracle,
        address _borrowMarket,
        address _core,
        address _treasury
    ) internal initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        nftOracle = INFTOracle(_nftOracle);
        core = ICore(_core);
        borrowMarket = _borrowMarket;
        treasury = _treasury;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setKeeper(address _keeper) external onlyKeeper {
        require(_keeper != address(0), "NftCore: invalid keeper address");
        keeper = _keeper;
        emit KeeperUpdated(_keeper);
    }

    function setTreasury(address _treasury) external onlyKeeper {
        require(_treasury != address(0), "NftCore: invalid treasury address");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setValidator(address _validator) external onlyKeeper {
        require(_validator != address(0), "NftCore: invalid validator address");
        validator = INftValidator(_validator);
        emit ValidatorUpdated(_validator);
    }

    function setNftOracle(address _nftOracle) external onlyKeeper {
        require(_nftOracle != address(0), "NftCore: invalid nft oracle address");
        nftOracle = INFTOracle(_nftOracle);
        emit NftOracleUpdated(_nftOracle);
    }

    function setLendPoolLoan(address _lendPoolLoan) external onlyKeeper {
        require(_lendPoolLoan != address(0), "NftCore: invalid lend pool loan address");
        lendPoolLoan = ILendPoolLoan(_lendPoolLoan);
        emit LendPoolLoanUpdated(_lendPoolLoan);
    }

    function setCore(address _core) external onlyKeeper {
        require(_core != address(0), "NftCore: invalid core address");
        core = ICore(_core);
        emit CoreUpdated(_core);
    }

    function setCollateralFactor(
        address gNft,
        uint256 newCollateralFactor
    ) external onlyKeeper onlyListedMarket(gNft) {
        require(newCollateralFactor <= Constant.COLLATERAL_FACTOR_MAX, "NftCore: invalid collateral factor");
        if (newCollateralFactor != 0 && nftOracle.getUnderlyingPrice(gNft) == 0) {
            revert("NftCore: invalid underlying price");
        }

        marketInfos[gNft].collateralFactor = newCollateralFactor;
        emit CollateralFactorUpdated(gNft, newCollateralFactor);
    }

    function setMarketSupplyCaps(address[] calldata gNfts, uint256[] calldata newSupplyCaps) external onlyKeeper {
        require(gNfts.length != 0 && gNfts.length == newSupplyCaps.length, "NftCore: invalid data");

        for (uint256 i = 0; i < gNfts.length; i++) {
            marketInfos[gNfts[i]].supplyCap = newSupplyCaps[i];
            emit SupplyCapUpdated(gNfts[i], newSupplyCaps[i]);
        }
    }

    function setMarketBorrowCaps(address[] calldata gNfts, uint256[] calldata newBorrowCaps) external onlyKeeper {
        require(gNfts.length != 0 && gNfts.length == newBorrowCaps.length, "NftCore: invalid data");

        for (uint256 i = 0; i < gNfts.length; i++) {
            marketInfos[gNfts[i]].borrowCap = newBorrowCaps[i];
            emit BorrowCapUpdated(gNfts[i], newBorrowCaps[i]);
        }
    }

    function setLiquidationThreshold(
        address gNft,
        uint256 newLiquidationThreshold
    ) external onlyKeeper onlyListedMarket(gNft) {
        require(newLiquidationThreshold <= Constant.LIQUIDATION_THRESHOLD_MAX, "NftCore: invalid liquidation threshold");
        if (newLiquidationThreshold != 0 && nftOracle.getUnderlyingPrice(gNft) == 0) {
            revert("NftCore: invalid underlying price");
        }

        marketInfos[gNft].liquidationThreshold = newLiquidationThreshold;
        emit LiquidationThresholdUpdated(gNft, newLiquidationThreshold);
    }

    function setLiquidationBonus(
        address gNft,
        uint256 newLiquidationBonus
    ) external onlyKeeper onlyListedMarket(gNft) {
        require(newLiquidationBonus <= Constant.LIQUIDATION_BONUS_MAX, "NftCore: invalid liquidation bonus");
        if (newLiquidationBonus != 0 && nftOracle.getUnderlyingPrice(gNft) == 0) {
            revert("NftCore: invalid underlying price");
        }

        marketInfos[gNft].liquidationBonus = newLiquidationBonus;
        emit LiquidationBonusUpdated(gNft, newLiquidationBonus);
    }

    function listMarket(
        address gNft,
        uint256 supplyCap,
        uint256 borrowCap,
        uint256 collateralFactor,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external onlyKeeper {
        require(!marketInfos[gNft].isListed, "NftCore: already listed market");
        for (uint256 i = 0; i < markets.length; i++) {
            require(markets[i] != gNft, "NftCore: already listed market");
        }

        marketInfos[gNft] = Constant.NftMarketInfo({
            isListed: true,
            supplyCap: supplyCap,
            borrowCap: borrowCap,
            collateralFactor: collateralFactor,
            liquidationThreshold: liquidationThreshold,
            liquidationBonus: liquidationBonus
        });

        address _underlying = IGNft(gNft).underlying();

        IERC721Upgradeable(_underlying).setApprovalForAll(address(lendPoolLoan), true);
        lendPoolLoan.initNft(_underlying, gNft);

        markets.push(gNft);
        emit MarketListed(gNft);
    }

    function removeMarket(address gNft) external onlyKeeper {
        require(marketInfos[gNft].isListed, "NftCore: unlisted market");
        require(IERC721EnumerableUpgradeable(gNft).totalSupply() == 0, "NftCore: cannot remove market");

        uint256 length = markets.length;
        for (uint256 i = 0; i < length; i++) {
            if (markets[i] == gNft) {
                markets[i] = markets[length - 1];
                markets.pop();
                delete marketInfos[gNft];
                break;
            }
        }
    }

    function pause() external onlyKeeper {
        _pause();
    }

    function unpause() external onlyKeeper {
        _unpause();
    }

    /* ========== VIEWS ========== */

    function getLendPoolLoan() external view override returns (address) {
        return address(lendPoolLoan);
    }

    function getNftOracle() external view override returns (address) {
        return address(nftOracle);
    }

    /* ========== RECEIVER FUNCTIONS ========== */

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "../interfaces/ILendPoolLoan.sol";
import "../interfaces/ICore.sol";
import "../interfaces/INftCore.sol";
import "../interfaces/IGNft.sol";
import "../interfaces/IRateModel.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/IRateModel.sol";
import "../interfaces/INFTOracle.sol";

import "../library/Constant.sol";

contract LendPoolLoan is ILendPoolLoan, OwnableUpgradeable, IERC721ReceiverUpgradeable {
    using SafeMath for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 internal constant DUST = 1000;

    /* ========== STATE VARIABLES ========== */

    INftCore public nftCore;
    ICore public core;
    IGToken public borrowMarket;

    CountersUpgradeable.Counter private _loanIdTracker;
    mapping(uint256 => Constant.LoanData) private _loans;
    mapping(address => Constant.BorrowInfo) private _accountBorrows;
    mapping(address => Constant.BorrowInfo) private _marketBorrows;
    mapping(address => mapping(address => Constant.BorrowInfo)) private _marketAccountBorrows;

    uint256 public _totalBorrow;
    uint256 public lastAccruedTime;
    uint256 public override accInterestIndex;
    uint256 public borrowRateMultiplier;

    uint256 public override auctionDuration;
    uint256 public override minBidFine;
    uint256 public override redeemFineRate;
    uint256 public override redeemThreshold;
    uint256 public override auctionFeeRate;

    // nftAsset + nftTokenId => loanId
    mapping(address => mapping(uint256 => uint256)) private _nftToLoanIds;
    mapping(address => uint256) private _nftTotalCollateral;
    mapping(address => mapping(address => uint256)) private _userNftCollateral;

    /* ========== INITIALIZER ========== */

    function initialize(
        INftCore _nftCore,
        ICore _core,
        IGToken _borrowMarket,
        uint256 _auctionDuration,
        uint256 _minBidFine,
        uint256 _redeemFineRate,
        uint256 _redeemThreshold,
        uint256 _borrowRateMultiplier,
        uint256 _auctionFeeRate
    ) external initializer {
        __Ownable_init();

        nftCore = _nftCore;
        core = _core;
        borrowMarket = _borrowMarket;

        auctionDuration = _auctionDuration;
        minBidFine = _minBidFine;
        redeemFineRate = _redeemFineRate;
        redeemThreshold = _redeemThreshold;
        borrowRateMultiplier = _borrowRateMultiplier;

        auctionFeeRate = _auctionFeeRate;

        // Avoid having loanId = 0
        _loanIdTracker.increment();

        lastAccruedTime = block.timestamp;
        accInterestIndex = 1e18;
    }

    /* ========== MODIFIERS ========== */

    modifier accrue() {
        if (block.timestamp > lastAccruedTime && borrowMarket.getRateModel() != address(0)) {
            uint256 borrowRate = getBorrowRate();
            uint256 interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint256 pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            _totalBorrow = _totalBorrow.add(pendingInterest);
            accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
            lastAccruedTime = block.timestamp;
        }
        _;
    }

    modifier onlyNftCore() {
        require(msg.sender == address(nftCore), "LendPoolLoan: caller should be nft core");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function initNft(address nftAsset, address gNft) external override onlyNftCore {
        IERC721Upgradeable(nftAsset).setApprovalForAll(gNft, true);
    }

    function setAuctionDuration(uint256 _auctionDuration) external onlyOwner {
        require(_auctionDuration <= Constant.AUCTION_DURATION_MAX, "LendPoolLoan: invalid auction duration");
        auctionDuration = _auctionDuration;
        emit AuctionDurationUpdated(_auctionDuration);
    }

    function setMinBidFine(uint256 _minBidFine) external onlyOwner {
        require(_minBidFine <= Constant.MIN_BID_FINE_MAX, "LendPoolLoan: invalid min bid fine");
        minBidFine = _minBidFine;
        emit MinBidFineUpdated(_minBidFine);
    }

    function setRedeemFineRate(uint256 _redeemFineRate) external onlyOwner {
        require(_redeemFineRate <= Constant.REDEEM_FINE_RATE_MAX, "LendPoolLoan: invalid redeem fine ratio");
        redeemFineRate = _redeemFineRate;
        emit RedeemFineRateUpdated(_redeemFineRate);
    }

    function setRedeemThreshold(uint256 _redeemThreshold) external onlyOwner {
        require(_redeemThreshold <= Constant.REDEEM_THRESHOLD_MAX, "LendPoolLoan: invalid redeem threshold");
        redeemThreshold = _redeemThreshold;
        emit RedeemThresholdUpdated(_redeemThreshold);
    }

    function setBorrowRateMultiplier(uint256 _borrowRateMultiplier) external onlyOwner {
        require(_borrowRateMultiplier <= Constant.BORROW_RATE_MULTIPLIER_MAX, "LendPoolLoan: invalid borrow rate multiplier");
        borrowRateMultiplier = _borrowRateMultiplier;
        emit BorrowRateMultiplierUpdated(_borrowRateMultiplier);
    }

    function setAuctionFeeRate(uint256 _auctionFeeRate) external onlyOwner {
        require(_auctionFeeRate <= Constant.AUCTION_FEE_RATE_MAX, "LendPoolLoan: invalid auction fee rate");
        auctionFeeRate = _auctionFeeRate;
        emit AuctionFeeRateUpdated(_auctionFeeRate);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createLoan(
        address to,
        address nftAsset,
        uint256 nftTokenId,
        address gNft,
        uint256 amount
    ) external override onlyNftCore accrue returns (uint256) {
        require(_nftToLoanIds[nftAsset][nftTokenId] == 0, "LendPoolLoan: nft already used as collateral");

        uint256 loanId = _loanIdTracker.current();
        _loanIdTracker.increment();
        _nftToLoanIds[nftAsset][nftTokenId] = loanId;

        IERC721Upgradeable(nftAsset).safeTransferFrom(msg.sender, address(this), nftTokenId);

        IGNft(gNft).mint(to, nftTokenId);

        Constant.LoanData storage loanData = _loans[loanId];
        loanData.loanId = loanId;
        loanData.state = Constant.LoanState.Active;
        loanData.borrower = to;
        loanData.gNft = gNft;
        loanData.nftAsset = nftAsset;
        loanData.nftTokenId = nftTokenId;
        loanData.borrowAmount = amount;
        loanData.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage info = _accountBorrows[to];
        if (info.borrow == 0) {
            info.borrow = amount;
            info.interestIndex = accInterestIndex;
        } else {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex).add(amount);
            info.interestIndex = accInterestIndex;
        }

        Constant.BorrowInfo storage marketBorrowInfo = _marketBorrows[gNft];
        if (marketBorrowInfo.borrow == 0) {
            marketBorrowInfo.borrow = amount;
            marketBorrowInfo.interestIndex = accInterestIndex;
        } else {
            marketBorrowInfo.borrow = marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex).add(amount);
            marketBorrowInfo.interestIndex = accInterestIndex;
        }

        Constant.BorrowInfo storage marketAccountBorrowInfo = _marketAccountBorrows[gNft][to];
        if (marketAccountBorrowInfo.borrow == 0) {
            marketAccountBorrowInfo.borrow = amount;
            marketAccountBorrowInfo.interestIndex = accInterestIndex;
        } else {
            marketAccountBorrowInfo.borrow = marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex).add(amount);
            marketAccountBorrowInfo.interestIndex = accInterestIndex;
        }

        _totalBorrow = _totalBorrow.add(amount);

        _userNftCollateral[to][nftAsset] = _userNftCollateral[to][nftAsset].add(1);
        _nftTotalCollateral[nftAsset] = _nftTotalCollateral[nftAsset].add(1);

        emit LoanCreated(to, loanId, nftAsset, nftTokenId, gNft, amount);
        return (loanId);
    }

    function updateLoan(
        uint256 loanId,
        uint256 amountAdded,
        uint256 amountTaken
    ) external override onlyNftCore accrue {
        Constant.LoanData storage loan = _loans[loanId];
        require(loan.state == Constant.LoanState.Active, "LendPoolLoan: invalid loan state");

        if (loan.interestIndex == 0) {
            loan.interestIndex = accInterestIndex;
        }

        loan.borrowAmount = loan.borrowAmount.mul(accInterestIndex).div(loan.interestIndex).add(amountAdded).sub(amountTaken);
        loan.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage info = _accountBorrows[loan.borrower];
        info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex).add(amountAdded).sub(amountTaken);
        info.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketBorrowInfo = _marketBorrows[loan.gNft];
        marketBorrowInfo.borrow = marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex).add(amountAdded).sub(amountTaken);
        marketBorrowInfo.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketAccountBorrowInfo = _marketAccountBorrows[loan.gNft][loan.borrower];
        marketAccountBorrowInfo.borrow = marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex).add(amountAdded).sub(amountTaken);
        marketAccountBorrowInfo.interestIndex = accInterestIndex;

        _totalBorrow = _totalBorrow.add(amountAdded).sub(amountTaken);

        loan.borrowAmount = (loan.borrowAmount < DUST) ? 0 : loan.borrowAmount;
        info.borrow = (info.borrow < DUST) ? 0 : info.borrow;
        marketBorrowInfo.borrow = (marketBorrowInfo.borrow < DUST) ? 0 : marketBorrowInfo.borrow;
        marketAccountBorrowInfo.borrow = (marketAccountBorrowInfo.borrow < DUST) ? 0 : marketAccountBorrowInfo.borrow;
        _totalBorrow = (_totalBorrow < DUST) ? 0 : _totalBorrow;

        emit LoanUpdated(loan.borrower, loanId, loan.nftAsset, loan.nftTokenId, amountAdded, amountTaken);
    }

    function repayLoan(
        uint256 loanId,
        address gNft,
        uint256 amount
    ) external override onlyNftCore accrue {
        Constant.LoanData storage loan = _loans[loanId];
        require(loan.state == Constant.LoanState.Active, "LendPoolLoan: invalid loan state");

        loan.state = Constant.LoanState.Repaid;
        loan.borrowAmount = 0;

        Constant.BorrowInfo storage info = _accountBorrows[loan.borrower];
        if (info.borrow.mul(accInterestIndex).div(info.interestIndex) < amount) {
            info.borrow = 0;
        } else {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex).sub(amount);
        }
        info.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketAccountBorrowInfo = _marketAccountBorrows[loan.gNft][loan.borrower];
        if (marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex) < amount) {
            marketAccountBorrowInfo.borrow = 0;
        } else {
            marketAccountBorrowInfo.borrow = marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex).sub(amount);
        }
        marketAccountBorrowInfo.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketBorrowInfo = _marketBorrows[loan.gNft];
        if (marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex) < amount) {
            marketBorrowInfo.borrow = 0;
        } else {
            marketBorrowInfo.borrow = marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex).sub(amount);
        }
        marketBorrowInfo.interestIndex = accInterestIndex;

        if (_totalBorrow < amount) {
            _totalBorrow = 0;
        } else {
            _totalBorrow = _totalBorrow.sub(amount);
        }

        loan.borrowAmount = (loan.borrowAmount < DUST) ? 0 : loan.borrowAmount;
        info.borrow = (info.borrow < DUST) ? 0 : info.borrow;
        marketBorrowInfo.borrow = (marketBorrowInfo.borrow < DUST) ? 0 : marketBorrowInfo.borrow;
        marketAccountBorrowInfo.borrow = (marketAccountBorrowInfo.borrow < DUST) ? 0 : marketAccountBorrowInfo.borrow;
        _totalBorrow = (_totalBorrow < DUST) ? 0 : _totalBorrow;

        _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

        require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, "LendPoolLoan: invalid user nft amount");
        _userNftCollateral[loan.borrower][loan.nftAsset] = _userNftCollateral[loan.borrower][loan.nftAsset].sub(1);

        require(_nftTotalCollateral[loan.nftAsset] >= 1, "LendPoolLoan: invalid nft amount");
        _nftTotalCollateral[loan.nftAsset] = _nftTotalCollateral[loan.nftAsset].sub(1);

        IGNft(gNft).burn(loan.nftTokenId);
        IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), msg.sender, loan.nftTokenId);

        emit LoanRepaid(loan.borrower, loanId, loan.nftAsset, loan.nftTokenId, amount);
    }

    function auctionLoan(
        address bidder,
        uint256 loanId,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external override onlyNftCore accrue {
        Constant.LoanData storage loan = _loans[loanId];
        address previousBidder = loan.bidderAddress;
        uint256 previousPrice = loan.bidPrice;

        if (loan.bidStartTimestamp == 0) {
            require(loan.state == Constant.LoanState.Active, "LendPoolLoan: invalid loan state");
            loan.state = Constant.LoanState.Auction;
            loan.bidStartTimestamp = block.timestamp;
            loan.firstBidderAddress = bidder;
            loan.floorPrice = INFTOracle(nftCore.getNftOracle()).getUnderlyingPrice(loan.gNft);
        } else {
            require(loan.state == Constant.LoanState.Auction, "LendPoolLoan: invalid loan state");
            require(bidPrice > loan.bidPrice, "LendPoolLoan: bid price less than highest price");
        }

        loan.bidBorrowAmount = borrowAmount;
        loan.bidderAddress = bidder;
        loan.bidPrice = bidPrice;
        loan.bidCount = loan.bidCount.add(1);

        emit LoanAuctioned(
            bidder,
            loanId,
            loan.nftAsset,
            loan.nftTokenId,
            loan.bidBorrowAmount,
            bidder,
            bidPrice,
            previousBidder,
            previousPrice,
            loan.floorPrice
        );
    }

    function redeemLoan(
        uint256 loanId,
        uint256 amountTaken
    ) external override onlyNftCore accrue {
        Constant.LoanData storage loan = _loans[loanId];
        require(loan.state == Constant.LoanState.Auction, "LendPoolLoan: invalid loan state");
        require(amountTaken > 0, "LendPoolLoan: invalid taken amount");

        loan.borrowAmount = loan.borrowAmount.mul(accInterestIndex).div(loan.interestIndex);
        require(loan.borrowAmount >= amountTaken, "LendPoolLoan: amount underflow");
        loan.borrowAmount = loan.borrowAmount.sub(amountTaken);
        loan.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage info = _accountBorrows[loan.borrower];
        info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex);
        require(info.borrow >= amountTaken, "LendPoolLoan: amount underflow");
        info.borrow = info.borrow.sub(amountTaken);
        info.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketBorrowInfo = _marketBorrows[loan.gNft];
        marketBorrowInfo.borrow = marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex);
        require(marketBorrowInfo.borrow >= amountTaken, "LendPoolLoan: amount underflow");
        marketBorrowInfo.borrow = marketBorrowInfo.borrow.sub(amountTaken);
        marketBorrowInfo.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketAccountBorrowInfo = _marketAccountBorrows[loan.gNft][loan.borrower];
        marketAccountBorrowInfo.borrow = marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex);
        require(marketAccountBorrowInfo.borrow >= amountTaken, "LendPoolLoan: amount underflow");
        marketAccountBorrowInfo.borrow = marketAccountBorrowInfo.borrow.sub(amountTaken);
        marketAccountBorrowInfo.interestIndex = accInterestIndex;

        _totalBorrow = _totalBorrow.sub(amountTaken);

        loan.borrowAmount = (loan.borrowAmount < DUST) ? 0 : loan.borrowAmount;
        info.borrow = (info.borrow < DUST) ? 0 : info.borrow;
        marketBorrowInfo.borrow = (marketBorrowInfo.borrow < DUST) ? 0 : marketBorrowInfo.borrow;
        marketAccountBorrowInfo.borrow = (marketAccountBorrowInfo.borrow < DUST) ? 0 : marketAccountBorrowInfo.borrow;
        _totalBorrow = (_totalBorrow < DUST) ? 0 : _totalBorrow;

        loan.state = Constant.LoanState.Active;
        loan.bidStartTimestamp = 0;
        loan.bidBorrowAmount = 0;
        loan.bidderAddress = address(0);
        loan.bidPrice = 0;
        loan.firstBidderAddress = address(0);
        loan.floorPrice = 0;
        loan.bidCount = 0;

        emit LoanRedeemed(
            loan.borrower,
            loanId,
            loan.nftAsset,
            loan.nftTokenId,
            amountTaken
        );
    }

    function liquidateLoan(
        address gNft,
        uint256 loanId,
        uint256 borrowAmount
    ) external override onlyNftCore accrue {
        Constant.LoanData storage loan = _loans[loanId];
        require(loan.state == Constant.LoanState.Auction, "LendPoolLoan: invalid loan state");

        loan.state = Constant.LoanState.Defaulted;
        loan.borrowAmount = 0;
        loan.bidBorrowAmount = borrowAmount;

        Constant.BorrowInfo storage info = _accountBorrows[loan.borrower];
        if (info.borrow.mul(accInterestIndex).div(info.interestIndex) < borrowAmount) {
            info.borrow = 0;
        } else {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex).sub(borrowAmount);
        }
        info.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketBorrowInfo = _marketBorrows[loan.gNft];
        if (marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex) < borrowAmount) {
            marketBorrowInfo.borrow = 0;
        } else {
            marketBorrowInfo.borrow = marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex).sub(borrowAmount);
        }
        marketBorrowInfo.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketAccountBorrowInfo = _marketAccountBorrows[loan.gNft][loan.borrower];
        if (marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex) < borrowAmount) {
            marketAccountBorrowInfo.borrow = 0;
        } else {
            marketAccountBorrowInfo.borrow = marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex).sub(borrowAmount);
        }
        marketAccountBorrowInfo.interestIndex = accInterestIndex;

        if (_totalBorrow < borrowAmount) {
            _totalBorrow = 0;
        } else {
            _totalBorrow = _totalBorrow.sub(borrowAmount);
        }

        info.borrow = (info.borrow < DUST) ? 0 : info.borrow;
        marketBorrowInfo.borrow = (marketBorrowInfo.borrow < DUST) ? 0 : marketBorrowInfo.borrow;
        marketAccountBorrowInfo.borrow = (marketAccountBorrowInfo.borrow < DUST) ? 0 : marketAccountBorrowInfo.borrow;
        _totalBorrow = (_totalBorrow < DUST) ? 0 : _totalBorrow;

        _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

        require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, "LendPoolLoan: invalid user nft amount");
        _userNftCollateral[loan.borrower][loan.nftAsset] = _userNftCollateral[loan.borrower][loan.nftAsset].sub(1);

        require(_nftTotalCollateral[loan.nftAsset] >= 1, "LendPoolLoan: invalid nft amount");
        _nftTotalCollateral[loan.nftAsset] = _nftTotalCollateral[loan.nftAsset].sub(1);

        IGNft(gNft).burn(loan.nftTokenId);
        IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), msg.sender, loan.nftTokenId);

        emit LoanLiquidated(
            loan.borrower,
            loanId,
            loan.nftAsset,
            loan.nftTokenId,
            borrowAmount
        );
    }

    function accrueInterest() external override accrue {}

    /* ========== VIEWS ========== */

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view override returns (uint256) {
        return _nftToLoanIds[nftAsset][nftTokenId];
    }

    function getNftCollateralAmount(address nftAsset) external view override returns (uint256) {
        return _nftTotalCollateral[nftAsset];
    }

    function getUserNftCollateralAmount(address user, address nftAsset) external view override returns (uint256) {
        return _userNftCollateral[user][nftAsset];
    }

    function borrowBalanceOf(uint256 loanId) public view override returns (uint256) {
        Constant.AccrueLoanSnapshot memory snapshot = pendingAccrueSnapshot();
        Constant.LoanData storage loan = _loans[loanId];

        if (loan.borrowAmount == 0) return 0;
        return loan.borrowAmount.mul(snapshot.accInterestIndex).div(loan.interestIndex);
    }

    function totalBorrow() public view override returns (uint256) {
        Constant.AccrueLoanSnapshot memory snapshot = pendingAccrueSnapshot();
        return snapshot.totalBorrow;
    }

    function userBorrowBalance(address user) external view override returns (uint256) {
        Constant.AccrueLoanSnapshot memory snapshot = pendingAccrueSnapshot();
        Constant.BorrowInfo memory info = _accountBorrows[user];

        if (info.borrow == 0) return 0;
        return info.borrow.mul(snapshot.accInterestIndex).div(info.interestIndex);
    }

    function marketBorrowBalance(address gNft) external view override returns (uint256) {
        Constant.AccrueLoanSnapshot memory snapshot = pendingAccrueSnapshot();
        Constant.BorrowInfo memory marketBorrowInfo = _marketBorrows[gNft];

        if (marketBorrowInfo.borrow == 0) return 0;
        return marketBorrowInfo.borrow.mul(snapshot.accInterestIndex).div(marketBorrowInfo.interestIndex);
    }

    function marketAccountBorrowBalance(address gNft, address user) external view override returns (uint256) {
        Constant.AccrueLoanSnapshot memory snapshot = pendingAccrueSnapshot();
        Constant.BorrowInfo memory marketAccountBorrowInfo = _marketAccountBorrows[gNft][user];

        if (marketAccountBorrowInfo.borrow == 0) return 0;
        return marketAccountBorrowInfo.borrow.mul(snapshot.accInterestIndex).div(marketAccountBorrowInfo.interestIndex);
    }

    function getLoan(uint256 loanId) external view override returns (Constant.LoanData memory loanData) {
        return _loans[loanId];
    }

    function pendingAccrueSnapshot() internal view returns (Constant.AccrueLoanSnapshot memory) {
        Constant.AccrueLoanSnapshot memory snapshot;
        snapshot.totalBorrow = _totalBorrow;
        snapshot.accInterestIndex = accInterestIndex;

        if (block.timestamp > lastAccruedTime && _totalBorrow > 0) {
            uint256 borrowRate = getBorrowRate();
            uint256 interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint256 pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            snapshot.totalBorrow = _totalBorrow.add(pendingInterest);
            snapshot.accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
        }
        return snapshot;
    }

    function getBorrowRate() internal view returns (uint256) {
        uint256 _borrowRate = IRateModel(borrowMarket.getRateModel()).getBorrowRate(
            borrowMarket.getCash(), borrowMarket._totalBorrow(), borrowMarket.totalReserve()
        );
        return _borrowRate.mul(borrowRateMultiplier).div(1e18);
    }

    function currentLoanId() external view override returns (uint256) {
        uint256 _loanId = _loanIdTracker.current();
        return _loanId;
    }

    function getAccInterestIndex() public view override returns (uint256) {
        Constant.AccrueLoanSnapshot memory snapshot = pendingAccrueSnapshot();
        return snapshot.accInterestIndex;
    }

    /* ========== RECEIVER FUNCTIONS ========== */

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IGenesisRewardDistributor.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IBEP20.sol";

import "../library/SafeToken.sol";

contract GenesisRewardDistributor is IGenesisRewardDistributor, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeToken for address;

    uint256 public constant totalRewardAmount = 5000000e18;

    /* ========== STATE VARIABLES ========== */

    mapping(address => uint256) public lastUnlockTimestamp;
    mapping(address => uint256) public claimed;

    mapping(address => uint256) public userLiquidity;
    uint256 public tvl;

    uint256 public startReleaseTimestamp;
    uint256 public endReleaseTimestamp;

    address public airdropToken;
    address public locker;

    /* ========== INITIALIZER ========== */

    function initialize(
        address _airdropToken,
        address _locker,
        uint256 _startReleaseTimestamp,
        uint256 _endReleaseTimestamp
    ) external initializer {
        require(_airdropToken != address(0), "GenesisRewardDistributor: airdropToken is zero address");
        require(_startReleaseTimestamp > block.timestamp, "GenesisRewardDistributor: invalid startReleaseTimestamp");
        require(_endReleaseTimestamp > _startReleaseTimestamp, "GenesisRewardDistributor: invalid endReleaseTimestamp");

        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        airdropToken = _airdropToken;
        locker = _locker;

        startReleaseTimestamp = _startReleaseTimestamp;
        endReleaseTimestamp = _endReleaseTimestamp;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function depositAirdropToken(address _funder) external onlyOwner {
        airdropToken.safeTransferFrom(_funder, address(this), totalRewardAmount);
    }

    function withdrawAirdropToken() external onlyOwner {
        uint256 _airdropTokenBalance = IBEP20(airdropToken).balanceOf(address(this));
        airdropToken.safeTransfer(msg.sender, _airdropTokenBalance);
    }

    function setTvl(uint256 _tvl) external onlyOwner {
        require(_tvl > 0, "GenesisRewardDistributor: invalid tvl");
        tvl = _tvl;
    }

    function setUserLiquidityInfos(address[] calldata _users, uint256[] calldata _liquidityInfos) external onlyOwner {
        require(_users.length == _liquidityInfos.length, "GenesisRewardDistributor: invalid liquidityInfos length");
        for (uint256 i = 0; i < _users.length; i++) {
            userLiquidity[_users[i]] = _liquidityInfos[i];
            if (lastUnlockTimestamp[_users[i]] < startReleaseTimestamp) {
                lastUnlockTimestamp[_users[i]] = startReleaseTimestamp;
            }
        }
    }

    function setLocker(address _locker) external onlyOwner {
        require(_locker != address(0), "GrvPresale: locker is the zero address");
        locker = _locker;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function withdrawTokens() external override nonReentrant {
        uint256 _tokensToClaim = tokensClaimable(msg.sender);
        require(_tokensToClaim > 0, "GenesisRewardDistributor: No tokens to claim");
        claimed[msg.sender] = claimed[msg.sender].add(_tokensToClaim);

        airdropToken.safeTransfer(msg.sender, _tokensToClaim);
        lastUnlockTimestamp[msg.sender] = block.timestamp;
    }

    function withdrawToLocker() external override nonReentrant {
        uint256 _tokensToLockable = tokensLockable(msg.sender);
        require(_tokensToLockable > 0, "GenesisRewardDistributor: No tokens to Lock");
        require(ILocker(locker).expiryOf(msg.sender) == 0 || ILocker(locker).expiryOf(msg.sender) > after6Month(block.timestamp),
            "GenesisRewardDistributor: locker lockup period less than 6 months");

        claimed[msg.sender] = claimed[msg.sender].add(_tokensToLockable);
        airdropToken.safeApprove(locker, _tokensToLockable);
        ILocker(locker).depositBehalf(msg.sender, _tokensToLockable, after6Month(block.timestamp));
        airdropToken.safeApprove(locker, 0);
    }

    /* ========== VIEWS ========== */

    function tokensClaimable(address _user) public view override returns (uint256 claimableAmount) {
        if (userLiquidity[_user] == 0) {
            return 0;
        }
        uint256 unclaimedTokens = IBEP20(airdropToken).balanceOf(address(this));
        claimableAmount = _getTokenAmount(_user);
        claimableAmount = claimableAmount.sub(claimed[_user]);

        claimableAmount = _canUnlockAmount(_user, claimableAmount);

        if (claimableAmount > unclaimedTokens) {
            claimableAmount = unclaimedTokens;
        }
    }

    function tokensLockable(address _user) public view override returns (uint256 lockableAmount) {
        if (userLiquidity[_user] == 0) {
            return 0;
        }
        uint256 unclaimedTokens = IBEP20(airdropToken).balanceOf(address(this));
        lockableAmount = _getTokenAmount(_user);
        lockableAmount = lockableAmount.sub(claimed[_user]);

        if (lockableAmount > unclaimedTokens) {
            lockableAmount = unclaimedTokens;
        }
    }

    function after6Month(uint256 timestamp) public pure returns (uint) {
        timestamp = timestamp + 180 days;
        return ((timestamp.add(1 weeks) / 1 weeks) * 1 weeks);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _allocationOf(address _user) private view returns (uint256) {
        if (tvl == 0) {
            return 0;
        } else {
            return userLiquidity[_user].mul(1e18).div(tvl);
        }
    }

    function _getTokenAmount(address _user) private view returns (uint256) {
        if (tvl == 0) {
            return 0;
        }
        return totalRewardAmount.mul(_allocationOf(_user)).div(1e18);
    }

    function _canUnlockAmount(address _user, uint256 _unclaimedTokenAmount) private view returns (uint256) {
        if (block.timestamp < startReleaseTimestamp) {
            return 0;
        } else if (block.timestamp >= endReleaseTimestamp) {
            return _unclaimedTokenAmount;
        } else {
            uint256 releasedTimestamp = block.timestamp.sub(lastUnlockTimestamp[_user]);
            uint256 timeLeft = endReleaseTimestamp.sub(lastUnlockTimestamp[_user]);
            return _unclaimedTokenAmount.mul(releasedTimestamp).div(timeLeft);
        }
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../library/SafeToken.sol";

import "../interfaces/IGrvPresale.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IBEP20.sol";

contract GrvPresale is IGrvPresale, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ========== STATE VARIABLES ========== */

    MarketInfo public override marketInfo;
    MarketStatus public override marketStatus;
    ILocker public locker;

    address public override auctionToken;
    address public override paymentCurrency;
    address payable public treasury;

    mapping(address => uint256) public override commitments;
    mapping(address => uint256) public override claimed;
    mapping(address => uint256) public override locked;
    mapping(address => string) public override nicknames;
    mapping(address => bool) public blacklist;

    /* ========== INITIALIZER ========== */

    function initialize(address _token, address _locker, uint256 _totalTokens, uint256 _startTime,
        uint256 _endTime, address _paymentCurrency, uint256 _minimumCommitmentAmount,
        uint256 _commitmentCap, address payable _treasury) external initializer {
        require(_startTime < 10000000000, "GrvPresale: enter an unix timestamp in seconds, not miliseconds");
        require(_endTime < 10000000000, "GrvPresale: enter an unix timestamp in seconds, not miliseconds");
        require(_startTime >= block.timestamp, "GrvPresale: start time is before current time");
        require(_endTime > _startTime, "GrvPresale: end time must be older than start time");
        require(_totalTokens > 0, "GrvPresale: total tokens must be greater than zero");
        require(_treasury != address(0), "GrvPresale: treasury is the zero address");

        require(IBEP20(_token).decimals() == 18, "GrvPresale: Token does not have 18 decimals");
        if (_paymentCurrency != ETH_ADDRESS) {
            require(IBEP20(_paymentCurrency).decimals() > 0, "GrvPresale: Payment currency is not ERC20");
        }

        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        marketStatus.minimumCommitmentAmount = _minimumCommitmentAmount;

        marketInfo.startTime = _startTime;
        marketInfo.endTime = _endTime;
        marketInfo.totalTokens = _totalTokens;
        marketInfo.commitmentCap = _commitmentCap;

        auctionToken = _token;
        paymentCurrency = _paymentCurrency;
        treasury = _treasury;

        locker = ILocker(_locker);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function depositAuctionToken(address _funder) external onlyOwner {
        auctionToken.safeTransferFrom(_funder, address(this), marketInfo.totalTokens);
        emit AuctionTokenDeposited(marketInfo.totalTokens);
    }

    function finalize() external onlyOwner {
        require(!marketStatus.finalized, "GrvPresale: Auction has already finalized");
        require(block.timestamp > marketInfo.endTime, "GrvPresale: Auction has not finished yet");
        if (auctionSuccessful()) {
            // Successful auction
            // Transfer contributed tokens to treasury.
            _safeTokenPayment(paymentCurrency, treasury, marketStatus.commitmentsTotal);
        } else {
            // Failed auction
            // Return auction tokens back to treasury.
            auctionToken.safeTransfer(treasury, marketInfo.totalTokens);
        }
        marketStatus.finalized = true;
        emit AuctionFinalized();
    }

    function cancelAuction() external onlyOwner nonReentrant {
        MarketStatus storage status = marketStatus;
        require(!status.finalized, "GrvPresale: already finalized");
        require(status.commitmentsTotal == 0, "GrvPresale: Funds already raised");

        auctionToken.safeTransfer(treasury, marketInfo.totalTokens);
        status.finalized = true;
        emit AuctionCancelled();
    }

    function setAuctionTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime < 10000000000, "GrvPresale: enter an unix timestamp in seconds, not miliseconds");
        require(_endTime < 10000000000, "GrvPresale: enter an unix timestamp in seconds, not miliseconds");
        require(_startTime >= block.timestamp, "GrvPresale: start time is before current time");
        require(_endTime > _startTime, "GrvPresale: end time must be older than start price");

        require(marketStatus.commitmentsTotal == 0, "GrvPresale: auction cannot have already started");

        marketInfo.startTime = _startTime;
        marketInfo.endTime = _endTime;

        emit AuctionTimeUpdated(_startTime, _endTime);
    }

    function setAuctionPrice(uint256 _minimumCommitmentAmount) external onlyOwner {
        require(marketStatus.commitmentsTotal == 0, "GrvPresale: auction cannot have already started");
        marketStatus.minimumCommitmentAmount = _minimumCommitmentAmount;
        emit AuctionPriceUpdated(_minimumCommitmentAmount);
    }

    function setAuctionTreasury(address payable _treasury) external onlyOwner {
        require(_treasury != address(0), "GrvPresale: treasury is the zero address");
        treasury = _treasury;
        emit AuctionTreasuryUpdated(_treasury);
    }

    function setLocker(address _locker) external onlyOwner {
        require(_locker != address(0), "GrvPresale: locker is the zero address");
        locker = ILocker(_locker);
        emit LockerUpdated(_locker);
    }

    function setBlacklist(address _addr, bool isBlackUser) external onlyOwner {
        require(_addr != address(0), "GrvPresale: address is zero address");
        blacklist[_addr] = isBlackUser;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function commitETH(address payable _beneficiary) external payable override nonReentrant {
        require(paymentCurrency == ETH_ADDRESS, "GrvPresale: Payment currency is not ETH");
        require(msg.value > 0, "GrvPresale: value must be higher than 0");
        require(marketStatus.commitmentsTotal < marketInfo.commitmentCap, "GrvPresale: commitment cap full");

        _addCommitment(_beneficiary, msg.value);
        // Revert if commitmentsTotal exceeds the balance
        require(marketStatus.commitmentsTotal <= address(this).balance, "GrvPresale: The committed GRV exceeds the balance");
    }

    function commitTokens(uint256 _amount) external override nonReentrant {
        _commitTokensFrom(msg.sender, _amount);
    }

    function withdrawTokens(address payable beneficiary) external override nonReentrant {
        if (auctionSuccessful()) {
            require(marketStatus.finalized, "GrvPresale: not finalized");
            // Successful auction! Transfer claimed tokens.
            uint256 tokensToClaim = tokensClaimable(beneficiary);
            require(tokensToClaim > 0, "GrvPresale: No tokens to claim");
            claimed[beneficiary] = claimed[beneficiary].add(tokensToClaim);

            auctionToken.safeTransfer(beneficiary, tokensToClaim);
        } else {
            // auction did not meet reserve price
            // return committed funds back to user
            require(block.timestamp > marketInfo.endTime, "GrvPresale: Auction has not finished yet");
            uint256 fundsCommitted = commitments[beneficiary];
            require(fundsCommitted > 0, "GrvPresale: No funds committed");
            commitments[beneficiary] = 0; // Stop multiple withdrawals
            _safeTokenPayment(paymentCurrency, beneficiary, fundsCommitted);
        }
    }

    function withdrawToLocker() external override nonReentrant {
        require(marketStatus.finalized, "GrvPresale: not finalized");
        require(auctionSuccessful(), "GrvPresale: auction failed");
        uint256 tokensToLockable = tokensLockable(msg.sender);
        require(tokensToLockable > 0, "GrvPresale: No tokens to Lock");
        require(locker.expiryOf(msg.sender) == 0 || locker.expiryOf(msg.sender) > afterMonth(block.timestamp),
            "GrvPresale: locker lockup period less than months");

        locked[msg.sender] = locked[msg.sender].add(tokensToLockable);

        auctionToken.safeApprove(address(locker), tokensToLockable);
        locker.depositBehalf(msg.sender, tokensToLockable, afterMonth(block.timestamp));
        auctionToken.safeApprove(address(locker), 0);
    }

    function setNickname(address _addr, string calldata _name) external override {
        require(_addr != address(0), "GrvPresale: address is zero address");
        require(blacklist[msg.sender] == false, "GrvPresale: Blacklist user");
        require(msg.sender == _addr || msg.sender == owner(), "GrvPresale: do not have permission to set a name");
        nicknames[_addr] = _name;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _commitTokensFrom(address payable _from, uint256 _amount) private {
        require(paymentCurrency != ETH_ADDRESS, "GrvPresale: Payment currency is not a token");
        require(_amount > 0, "GrvPresale: Value must be higher than 0");
        require(marketStatus.commitmentsTotal < marketInfo.commitmentCap, "GrvPresale: commitment cap full");

        _safeTransferFrom(paymentCurrency, msg.sender, _amount);
        _addCommitment(_from, _amount);
    }

    function _addCommitment(address payable _addr, uint256 _commitment) private {
        require(block.timestamp >= marketInfo.startTime && block.timestamp <= marketInfo.endTime, "GrvPresale: outside auction hours");
        require(!marketStatus.finalized, "GrvPresale: has been finalized");

        if (_commitment.add(marketStatus.commitmentsTotal) > marketInfo.commitmentCap) {
            uint256 _canCommitmentAmount = marketInfo.commitmentCap.sub(marketStatus.commitmentsTotal);
            uint256 _refundAmount = _commitment.sub(_canCommitmentAmount);
            _commitment = _canCommitmentAmount;
            _safeTokenPayment(paymentCurrency, _addr, _refundAmount);
        }

        uint256 newCommitment = commitments[_addr].add(_commitment);
        commitments[_addr] = newCommitment;
        marketStatus.commitmentsTotal = marketStatus.commitmentsTotal.add(_commitment);
        emit AddedCommitment(_addr, _commitment);
    }

    // calculates amount of auction tokens for user to receive.
    function _getTokenAmount(uint256 amount) private view returns (uint256) {
        if (marketStatus.commitmentsTotal == 0) {
            return 0;
        }
        uint256 _tokenAmount = _getAdjustedAmount(paymentCurrency, amount).mul(1e18).div(tokenPrice());
        return _tokenAmount.mul(1e18).div(2e18);
    }

    /// @dev Helper function to handle both ETH and ERC20 payments
    function _safeTokenPayment(
        address _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            _safeTransferETH(_to,_amount );
        } else {
            _safeTransfer(_token, _to, _amount);
        }
    }

    function _safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "!safeTransferETH");
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal virtual {
        (bool success, bytes memory data) =
        token.call(
        // 0xa9059cbb = bytes4(keccak256("transfer(address,uint256)"))
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 Transfer failed
    }

    function _safeTransferFrom(address token, address from, uint256 amount) private {
        (bool success, bytes memory data) =
        token.call(
        // 0x23b872dd = bytes4(keccak256("transferFrom(address,address,uint256)"))
            abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _getAdjustedAmount(address token, uint256 amount) private view returns (uint256) {
        if (token == address(0)) {
            return amount;
        } else {
            uint256 defaultDecimal = 18;
            uint256 tokenDecimal = IBEP20(token).decimals();

            if (tokenDecimal == defaultDecimal) {
                return amount;
            } else if (tokenDecimal < defaultDecimal) {
                return amount * (10**(defaultDecimal - tokenDecimal));
            } else {
                return amount / (10**(tokenDecimal - defaultDecimal));
            }
        }
    }

    /* ========== VIEWS ========== */

    function afterMonth(uint256 timestamp) public pure override returns (uint256) {
        timestamp = timestamp + 30 days;
        return ((timestamp.add(1 weeks) / 1 weeks) * 1 weeks);
    }

    function tokenPrice() public view override returns (uint256) {
        return _getAdjustedAmount(paymentCurrency, marketStatus.commitmentsTotal).mul(1e18).div(marketInfo.totalTokens);
    }

    function tokensClaimable(address _user) public view override returns (uint256 claimerCommitment) {
        if (commitments[_user] == 0) {
            return 0;
        }
        uint256 unclaimedTokens = IBEP20(auctionToken).balanceOf(address(this));
        claimerCommitment = _getTokenAmount(commitments[_user]);
        claimerCommitment = claimerCommitment.sub(claimed[_user]);

        if (claimerCommitment > unclaimedTokens) {
            claimerCommitment = unclaimedTokens;
        }
    }

    function tokensLockable(address _user) public view override returns (uint256 claimerCommitment) {
        if (commitments[_user] == 0) {
            return 0;
        }
        uint256 unclaimedTokens = IBEP20(auctionToken).balanceOf(address(this));
        claimerCommitment = _getTokenAmount(commitments[_user]);
        claimerCommitment = claimerCommitment.sub(locked[_user]);

        if (claimerCommitment > unclaimedTokens) {
            claimerCommitment = unclaimedTokens;
        }
    }

    function finalized() external view override returns (bool) {
        return marketStatus.finalized;
    }

    function auctionSuccessful() public view override returns (bool) {
        return marketStatus.commitmentsTotal >= marketStatus.minimumCommitmentAmount && marketStatus.commitmentsTotal > 0;
    }

    function auctionEnded() external view override returns (bool) {
        return block.timestamp > marketInfo.endTime;
    }

    function getBaseInformation() external view override returns (uint256 startTime, uint256 endTime, bool marketFinalized) {
        startTime = marketInfo.startTime;
        endTime = marketInfo.endTime;
        marketFinalized = marketStatus.finalized;
    }

    function getTotalTokens() external view override returns(uint256) {
        return marketInfo.totalTokens;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IRankerRewardDistributor.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IBEP20.sol";

import "../library/SafeToken.sol";

contract RankerRewardDistributor is IRankerRewardDistributor, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 public constant totalRewardAmount = 2000000e18;
    uint256 public constant firstSectionReward = 250000e18;
    uint256 public constant secondSectionReward = 125000e18;
    uint256 public constant thirdSectionReward = 50000e18;
    uint256 public constant fourthSectionReward = 30000e18;
    uint256 public constant fifthSectionReward = 10625e18;
    uint256 public constant sixthSectionReward = 5625e18;

    /* ========== STATE VARIABLES ========== */

    mapping(address => uint256) public lastUnlockTimestamp;
    mapping(address => uint256) public claimed;

    mapping(address => uint256) public userRank;

    uint256 public startReleaseTimestamp;
    uint256 public endReleaseTimestamp;

    address public rewardToken;
    address public locker;

    /* ========== INITIALIZER ========== */
    function initialize(
        address _rewardToken,
        address _locker,
        uint256 _startReleaseTimestamp,
        uint256 _endReleaseTimestamp
    ) external initializer {
        require(_rewardToken != address(0), "RankerRewardDistributor: rewardToken is zero address");
        require(_startReleaseTimestamp > block.timestamp, "RankerRewardDistributor: invalid startReleaseTimestamp");
        require(_endReleaseTimestamp > _startReleaseTimestamp, "RankerRewardDistributor: invalid endReleaseTimestamp");

        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        rewardToken = _rewardToken;
        locker = _locker;

        startReleaseTimestamp = _startReleaseTimestamp;
        endReleaseTimestamp = _endReleaseTimestamp;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function depositRewardToken() external onlyOwner {
        rewardToken.safeTransferFrom(msg.sender, address(this), totalRewardAmount);
    }

    function withdrawRewardToken() external onlyOwner {
        uint256 _rewardTokenBalance = IBEP20(rewardToken).balanceOf(address(this));
        rewardToken.safeTransfer(msg.sender, _rewardTokenBalance);
    }

    function setUserRanks(address[] calldata _users, uint256[] calldata _ranks) external onlyOwner {
        require(_users.length == _ranks.length, "RankerRewardDistributor: invalid ranks length");
        for (uint256 i = 0; i < _users.length; i++) {
            userRank[_users[i]] = _ranks[i];
            if (lastUnlockTimestamp[_users[i]] < startReleaseTimestamp) {
                lastUnlockTimestamp[_users[i]] = startReleaseTimestamp;
            }
        }
    }

    function setLocker(address _locker) external onlyOwner {
        require(_locker != address(0), "GrvPresale: locker is the zero address");
        locker = _locker;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function withdrawTokens() external override nonReentrant {
        uint256 _tokensToClaim = tokensClaimable(msg.sender);
        require(_tokensToClaim > 0, "RankerRewardDistributor: No tokens to claim");
        claimed[msg.sender] = claimed[msg.sender].add(_tokensToClaim);

        rewardToken.safeTransfer(msg.sender, _tokensToClaim);
        lastUnlockTimestamp[msg.sender] = block.timestamp;
    }

    function withdrawToLocker() external override nonReentrant {
        uint256 _tokensToLockable = tokensLockable(msg.sender);
        require(_tokensToLockable > 0, "RankerRewardDistributor: No tokens to Lock");
        require(ILocker(locker).expiryOf(msg.sender) == 0 ||
                ILocker(locker).expiryOf(msg.sender) > after6Month(block.timestamp),
                "RankerRewardDistributor: locker lockup period less than 6 months");

        claimed[msg.sender] = claimed[msg.sender].add(_tokensToLockable);
        rewardToken.safeApprove(locker, _tokensToLockable);
        ILocker(locker).depositBehalf(msg.sender, _tokensToLockable, after6Month(block.timestamp));
        rewardToken.safeApprove(locker, 0);
    }

    /* ========== VIEWS ========== */

    function tokensClaimable(address _user) public view override returns (uint256 claimableAmount) {
        if (userRank[_user] == 0) {
            return 0;
        }
        uint256 unclaimedTokens = IBEP20(rewardToken).balanceOf(address(this));
        claimableAmount = getTokenAmount(_user);
        claimableAmount = claimableAmount.sub(claimed[_user]);

        claimableAmount = _canUnlockAmount(_user, claimableAmount);

        if (claimableAmount > unclaimedTokens) {
            claimableAmount = unclaimedTokens;
        }
    }

    function tokensLockable(address _user) public view override returns (uint256 lockableAmount) {
        if (userRank[_user] == 0) {
            return 0;
        }
        uint256 unclaimedTokens = IBEP20(rewardToken).balanceOf(address(this));
        lockableAmount = getTokenAmount(_user);
        lockableAmount = lockableAmount.sub(claimed[_user]);

        if (lockableAmount > unclaimedTokens) {
            lockableAmount = unclaimedTokens;
        }
    }

    function getTokenAmount(address _user) public view override returns (uint256) {
        if (userRank[_user] == 1) {
            return firstSectionReward;
        } else if (userRank[_user] == 2 || userRank[_user] == 3) {
            return secondSectionReward;
        } else if (userRank[_user] >= 4 && userRank[_user] <= 10) {
            return thirdSectionReward;
        } else if (userRank[_user] >= 11 && userRank[_user] <= 30) {
            return fourthSectionReward;
        } else if (userRank[_user] >= 31 && userRank[_user] <= 70) {
            return fifthSectionReward;
        } else if (userRank[_user] >= 71 && userRank[_user] <= 100) {
            return sixthSectionReward;
        } else {
            return 0;
        }
    }

    function after6Month(uint256 timestamp) public pure returns (uint) {
        timestamp = timestamp + 180 days;
        return ((timestamp.add(1 weeks) / 1 weeks) * 1 weeks);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _canUnlockAmount(address _user, uint256 _unclaimedTokenAmount) private view returns (uint256) {
        if (block.timestamp < startReleaseTimestamp) {
            return 0;
        } else if (block.timestamp >= endReleaseTimestamp) {
            return _unclaimedTokenAmount;
        } else {
            uint256 releasedTimestamp = block.timestamp.sub(lastUnlockTimestamp[_user]);
            uint256 timeLeft = endReleaseTimestamp.sub(lastUnlockTimestamp[_user]);
            return _unclaimedTokenAmount.mul(releasedTimestamp).div(timeLeft);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IRushAirdropDistributor.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IBEP20.sol";

import "../library/SafeToken.sol";

contract RushAirdropDistributor is IRushAirdropDistributor, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 public constant firstGravityRewardQuota = 1000000e18;
    uint256 public constant secondGravityRewardQuota = 1000000e18;
    uint256 public constant thirdGravityRewardQuota = 1000000e18;
    uint256 public constant fourthGravityRewardQuota = 1000000e18;
    uint256 public constant fifthGravityRewardQuota = 1000000e18;
    uint256 public constant totalRewardQuota = 5000000e18;

    /* ========== STATE VARIABLES ========== */

    uint256 public startReleaseTimestamp;
    uint256 public endReleaseTimestamp;

    address public airdropToken;
    address public locker;

    mapping(address => uint256) public lastUnlockTimestamp;

    mapping(address => bool) public firstGravityUsers;
    uint256 public firstGravityUserCount;

    mapping(address => bool) public secondGravityUsers;
    uint256 public secondGravityUserCount;

    mapping(address => bool) public thirdGravityUsers;
    uint256 public thirdGravityUserCount;

    mapping(address => bool) public fourthGravityUsers;
    uint256 public fourthGravityUserCount;

    mapping(address => bool) public fifthGravityUsers;
    uint256 public fifthGravityUserCount;

    mapping(address => uint256) public claimed;

    /* ========== INITIALIZER ========== */

    function initialize(
        address _airdropToken,
        address _locker,
        uint256 _startReleaseTimestamp,
        uint256 _endReleaseTimestamp
    ) external initializer {
        require(_airdropToken != address(0), "RushAirdropDistributor: airdropToken is zero address");
        require(_locker != address(0), "RushAirdropDistributor: locker is zero address");

        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        airdropToken = _airdropToken;
        locker = _locker;

        startReleaseTimestamp = _startReleaseTimestamp;
        endReleaseTimestamp = _endReleaseTimestamp;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function depositAirdropToken(address _funder) external onlyOwner {
        airdropToken.safeTransferFrom(_funder, address(this), totalRewardQuota);
    }

    function withdrawAirdropToken() external onlyOwner {
        uint256 _airdropTokenBalance = IBEP20(airdropToken).balanceOf(address(this));
        airdropToken.safeTransfer(msg.sender, _airdropTokenBalance);
    }

    function setFirstGravityUser(address _user) external onlyOwner {
        if (firstGravityUsers[_user] == false) {
            firstGravityUsers[_user] = true;
            firstGravityUserCount = firstGravityUserCount.add(1);
        }
        if (lastUnlockTimestamp[_user] < startReleaseTimestamp) {
            lastUnlockTimestamp[_user] = startReleaseTimestamp;
        }
    }

    function setFirstGravityUsers(address[] calldata _users) external onlyOwner {
        uint256 _setCount = 0;
        for (uint256 i = 0; i < _users.length; i++) {
            if (firstGravityUsers[_users[i]] == false) {
                firstGravityUsers[_users[i]] = true;
                _setCount = _setCount.add(1);
            }
            if (lastUnlockTimestamp[_users[i]] < startReleaseTimestamp) {
                lastUnlockTimestamp[_users[i]] = startReleaseTimestamp;
            }
        }
        firstGravityUserCount = firstGravityUserCount.add(_setCount);
    }

    function removeFirstGravityUser(address _user) external onlyOwner {
        if (firstGravityUsers[_user]) {
            firstGravityUsers[_user] = false;
            firstGravityUserCount = firstGravityUserCount.sub(1);
        }
    }

    function setSecondGravityUser(address _user) external onlyOwner {
        if (secondGravityUsers[_user] == false) {
            secondGravityUsers[_user] = true;
            secondGravityUserCount = secondGravityUserCount.add(1);
        }
        if (lastUnlockTimestamp[_user] < startReleaseTimestamp) {
            lastUnlockTimestamp[_user] = startReleaseTimestamp;
        }
    }

    function setSecondGravityUsers(address[] calldata _users) external onlyOwner {
        uint256 _setCount = 0;
        for (uint256 i = 0; i < _users.length; i++) {
            if (secondGravityUsers[_users[i]] == false) {
                secondGravityUsers[_users[i]] = true;
                _setCount = _setCount.add(1);
            }
            if (lastUnlockTimestamp[_users[i]] < startReleaseTimestamp) {
                lastUnlockTimestamp[_users[i]] = startReleaseTimestamp;
            }
        }
        secondGravityUserCount = secondGravityUserCount.add(_setCount);
    }

    function removeSecondGravityUser(address _user) external onlyOwner {
        if (secondGravityUsers[_user]) {
            secondGravityUsers[_user] = false;
            secondGravityUserCount = secondGravityUserCount.sub(1);
        }
    }

    function setThirdGravityUser(address _user) external onlyOwner {
        if (thirdGravityUsers[_user] == false) {
            thirdGravityUsers[_user] = true;
            thirdGravityUserCount = thirdGravityUserCount.add(1);
        }
        if (lastUnlockTimestamp[_user] < startReleaseTimestamp) {
            lastUnlockTimestamp[_user] = startReleaseTimestamp;
        }
    }

    function setThirdGravityUsers(address[] calldata _users) external onlyOwner {
        uint256 _setCount = 0;
        for (uint256 i = 0; i < _users.length; i++) {
            if (thirdGravityUsers[_users[i]] == false) {
                thirdGravityUsers[_users[i]] = true;
                _setCount = _setCount.add(1);
            }
            if (lastUnlockTimestamp[_users[i]] < startReleaseTimestamp) {
                lastUnlockTimestamp[_users[i]] = startReleaseTimestamp;
            }
        }
        thirdGravityUserCount = thirdGravityUserCount.add(_setCount);
    }

    function removeThirdGravityUser(address _user) external onlyOwner {
        if (thirdGravityUsers[_user]) {
            thirdGravityUsers[_user] = false;
            thirdGravityUserCount = thirdGravityUserCount.sub(1);
        }
    }

    function setFourthGravityUser(address _user) external onlyOwner {
        if (fourthGravityUsers[_user] == false) {
            fourthGravityUsers[_user] = true;
            fourthGravityUserCount = fourthGravityUserCount.add(1);
        }
        if (lastUnlockTimestamp[_user] < startReleaseTimestamp) {
            lastUnlockTimestamp[_user] = startReleaseTimestamp;
        }
    }

    function setFourthGravityUsers(address[] calldata _users) external onlyOwner {
        uint256 _setCount = 0;
        for (uint256 i = 0; i < _users.length; i++) {
            if (fourthGravityUsers[_users[i]] == false) {
                fourthGravityUsers[_users[i]] = true;
                _setCount = _setCount.add(1);
            }
            if (lastUnlockTimestamp[_users[i]] < startReleaseTimestamp) {
                lastUnlockTimestamp[_users[i]] = startReleaseTimestamp;
            }
        }
        fourthGravityUserCount = fourthGravityUserCount.add(_setCount);
    }

    function removeFourthGravityUser(address _user) external onlyOwner {
        if (fourthGravityUsers[_user]) {
            fourthGravityUsers[_user] = false;
            fourthGravityUserCount = fourthGravityUserCount.sub(1);
        }
    }

    function setFifthGravityUser(address _user) external onlyOwner {
        if (fifthGravityUsers[_user] == false) {
            fifthGravityUsers[_user] = true;
            fifthGravityUserCount = fifthGravityUserCount.add(1);
        }
        if (lastUnlockTimestamp[_user] < startReleaseTimestamp) {
            lastUnlockTimestamp[_user] = startReleaseTimestamp;
        }
    }

    function setFifthGravityUsers(address[] calldata _users) external onlyOwner {
        uint256 _setCount = 0;
        for (uint256 i = 0; i < _users.length; i++) {
            if (fifthGravityUsers[_users[i]] == false) {
                fifthGravityUsers[_users[i]] = true;
                _setCount = _setCount.add(1);
            }
            if (lastUnlockTimestamp[_users[i]] < startReleaseTimestamp) {
                lastUnlockTimestamp[_users[i]] = startReleaseTimestamp;
            }
        }
        fifthGravityUserCount = fifthGravityUserCount.add(_setCount);
    }

    function removeFifthGravityUser(address _user) external onlyOwner {
        if (fifthGravityUsers[_user]) {
            fifthGravityUsers[_user] = false;
            fifthGravityUserCount = fifthGravityUserCount.sub(1);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function withdrawTokens() external override nonReentrant {
        uint256 _tokensToClaim = tokensClaimable(msg.sender);
        require(_tokensToClaim > 0, "RushAirdropDistributor: No tokens to claim");
        claimed[msg.sender] = claimed[msg.sender].add(_tokensToClaim);

        airdropToken.safeTransfer(msg.sender, _tokensToClaim);
        lastUnlockTimestamp[msg.sender] = block.timestamp;
    }

    function withdrawToLocker() external override nonReentrant {
        uint256 _tokensToLockable = tokensLockable(msg.sender);
        require(_tokensToLockable > 0, "RushAirdropDistributor: No tokens to Lock");
        require(ILocker(locker).expiryOf(msg.sender) == 0 || ILocker(locker).expiryOf(msg.sender) > after6Month(block.timestamp),
            "RushAirdropDistributor: locker lockup period less than 6 months");

        claimed[msg.sender] = claimed[msg.sender].add(_tokensToLockable);

        airdropToken.safeApprove(locker, _tokensToLockable);
        ILocker(locker).depositBehalf(msg.sender, _tokensToLockable, after6Month(block.timestamp));
        airdropToken.safeApprove(locker, 0);
    }

    /* ========== VIEWS ========== */

    function tokensClaimable(address _user) public view returns (uint256 claimableAmount) {
        claimableAmount = 0;

        if (firstGravityUsers[_user]) {
            claimableAmount = claimableAmount.add(getFirstGravityReward());
        }

        if (secondGravityUsers[_user]) {
            claimableAmount = claimableAmount.add(getSecondGravityReward());
        }

        if (thirdGravityUsers[_user]) {
            claimableAmount = claimableAmount.add(getThirdGravityReward());
        }

        if (fourthGravityUsers[_user]) {
            claimableAmount = claimableAmount.add(getFourthGravityReward());
        }

        if (fifthGravityUsers[_user]) {
            claimableAmount = claimableAmount.add(getFifthGravityReward());
        }

        claimableAmount = claimableAmount.sub(claimed[_user]);
        claimableAmount = _canUnlockAmount(_user, claimableAmount);

        uint256 unclaimedTokens = IBEP20(airdropToken).balanceOf(address(this));

        if (claimableAmount > unclaimedTokens) {
            claimableAmount = unclaimedTokens;
        }
    }

    function tokensLockable(address _user) public view returns (uint256 lockableAmount) {
        lockableAmount = 0;

        if (firstGravityUsers[_user]) {
            lockableAmount = lockableAmount.add(getFirstGravityReward());
        }

        if (secondGravityUsers[_user]) {
            lockableAmount = lockableAmount.add(getSecondGravityReward());
        }

        if (thirdGravityUsers[_user]) {
            lockableAmount = lockableAmount.add(getThirdGravityReward());
        }

        if (fourthGravityUsers[_user]) {
            lockableAmount = lockableAmount.add(getFourthGravityReward());
        }

        if (fifthGravityUsers[_user]) {
            lockableAmount = lockableAmount.add(getFifthGravityReward());
        }

        lockableAmount = lockableAmount.sub(claimed[_user]);

        uint256 unclaimedTokens = IBEP20(airdropToken).balanceOf(address(this));

        if (lockableAmount > unclaimedTokens) {
            lockableAmount = unclaimedTokens;
        }
    }

    function getFirstGravityReward() public view returns (uint256 _rewardAmount) {
        if (firstGravityUserCount == 0) {
            return 0;
        }
        return firstGravityRewardQuota.div(firstGravityUserCount);
    }

    function getSecondGravityReward() public view returns (uint256 _rewardAmount) {
        if (secondGravityUserCount == 0) {
            return 0;
        }
        return secondGravityRewardQuota.div(secondGravityUserCount);
    }

    function getThirdGravityReward() public view returns (uint256 _rewardAmount) {
        if (thirdGravityUserCount == 0) {
            return 0;
        }
        return thirdGravityRewardQuota.div(thirdGravityUserCount);
    }

    function getFourthGravityReward() public view returns (uint256 _rewardAmount) {
        if (fourthGravityUserCount == 0) {
            return 0;
        }
        return fourthGravityRewardQuota.div(fourthGravityUserCount);
    }

    function getFifthGravityReward() public view returns (uint256 _rewardAmount) {
        if (fifthGravityUserCount == 0) {
            return 0;
        }
        return fifthGravityRewardQuota.div(fifthGravityUserCount);
    }

    function after6Month(uint256 timestamp) public pure returns (uint) {
        timestamp = timestamp + 180 days;
        return ((timestamp.add(1 weeks) / 1 weeks) * 1 weeks);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _canUnlockAmount(address _user, uint256 _unclaimedTokenAmount) private view returns (uint) {
        if (block.timestamp < startReleaseTimestamp) {
            return 0;
        } else if (block.timestamp >= endReleaseTimestamp) {
            return _unclaimedTokenAmount;
        } else {
            uint256 releasedTimestamp = block.timestamp.sub(lastUnlockTimestamp[_user]);
            uint256 timeLeft = endReleaseTimestamp.sub(lastUnlockTimestamp[_user]);
            return _unclaimedTokenAmount.mul(releasedTimestamp).div(timeLeft);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../library/SafeToken.sol";
import "../library/WhitelistUpgradeable.sol";
import "../interfaces/IEcoScore.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IGRVDistributor.sol";
import "../interfaces/IPriceProtectionTaxCalculator.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/ILendPoolLoan.sol";

contract EcoScore is IEcoScore, WhitelistUpgradeable {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 public constant BOOST_PORTION = 100; //1배
    uint256 public constant BOOST_MAX = 200; // 기본 max boost 2배
    uint256 private constant ECO_BOOST_PORTION = 100; // 1배
    uint256 private constant TAX_DEFAULT = 0; // 0% default tax
    uint256 private constant MAX_BOOST_MULTIPLE_VALUE = 1000; // 10%
    uint256 private constant MAX_BOOST_CAP_VALUE = 1000; // 10%
    uint256 private constant MAX_BOOST_BASE_VALUE = 1000; // 10%
    uint256 private constant MAX_REDEEM_FEE_VALUE = 1000; // 10%
    uint256 private constant MAX_CLAIM_TAX_VALUE = 100; // 100%

    /* ========== STATE VARIABLES ========== */

    ILocker public locker;
    IGRVDistributor public grvDistributor;
    IPriceProtectionTaxCalculator public priceProtectionTaxCalculator;
    IPriceCalculator public priceCalculator;
    ILendPoolLoan public lendPoolLoan;
    address public GRV;

    mapping(address => Constant.EcoScoreInfo) public accountEcoScoreInfo; // 유저별 eco score 정보
    mapping(Constant.EcoZone => Constant.EcoPolicyInfo) public ecoPolicyInfo; // zone 별 tax 및 파라미터 정보 저장
    mapping(address => Constant.EcoPolicyInfo) private _customEcoPolicyRate;
    mapping(address => bool) private _hasCustomTax;
    mapping(address => bool) private _isExcluded;

    address[] private _excluded;

    Constant.EcoZoneStandard public ecoZoneStandard;
    Constant.PPTPhaseInfo public pptPhaseInfo;

    /* ========== VARIABLE GAP ========== */

    uint256[49] private __gap;

    /* ========== MODIFIERS ========== */

    /// @dev msg.sender 가 core address 인지 검증
    modifier onlyGRVDistributor() {
        require(msg.sender == address(grvDistributor), "EcoScore: caller is not grvDistributor");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize(
        address _grvDistributor,
        address _locker,
        address _priceProtectionTaxCalculator,
        address _priceCalculator,
        address _grvTokenAddress
    ) external initializer {
        require(_grvDistributor != address(0), "EcoScore: grvDistributor can't be zero address");
        require(_locker != address(0), "EcoScore: locker can't be zero address");
        require(
            _priceProtectionTaxCalculator != address(0),
            "EcoScore: priceProtectionTaxCalculator can't be zero address"
        );
        require(_priceCalculator != address(0), "EcoScore: priceCalculator address can't be zero");
        require(_grvTokenAddress != address(0), "EcoScore: grv address can't be zero");

        __WhitelistUpgradeable_init();
        grvDistributor = IGRVDistributor(_grvDistributor);
        locker = ILocker(_locker);
        priceProtectionTaxCalculator = IPriceProtectionTaxCalculator(_priceProtectionTaxCalculator);
        priceCalculator = IPriceCalculator(_priceCalculator);
        GRV = _grvTokenAddress;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice grvDistributor 변경
    /// @dev owner address 에서만 요청 가능
    /// @param _grvDistributor 새로운 grvDistributor address
    function setGRVDistributor(address _grvDistributor) external override onlyOwner {
        require(_grvDistributor != address(0), "EcoScore: invalid grvDistributor address");
        grvDistributor = IGRVDistributor(_grvDistributor);
        emit SetGRVDistributor(_grvDistributor);
    }

    /// @notice priceProtectionTaxCalculator 변경
    /// @dev owner address 에서만 요청 가능
    /// @param _priceProtectionTaxCalculator 새로운 priceProtectionTaxCalculator address
    function setPriceProtectionTaxCalculator(address _priceProtectionTaxCalculator) external override onlyOwner {
        require(_priceProtectionTaxCalculator != address(0), "EcoScore: invalid priceProtectionTaxCalculator address");
        priceProtectionTaxCalculator = IPriceProtectionTaxCalculator(_priceProtectionTaxCalculator);
        emit SetPriceProtectionTaxCalculator(_priceProtectionTaxCalculator);
    }

    /// @notice priceCalculator address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    /// @param _priceCalculator priceCalculator contract address
    function setPriceCalculator(address _priceCalculator) external override onlyOwner {
        require(_priceCalculator != address(0), "EcoScore: invalid priceCalculator address");
        priceCalculator = IPriceCalculator(_priceCalculator);

        emit SetPriceCalculator(_priceCalculator);
    }

    function setLendPoolLoan(address _lendPoolLoan) external override onlyOwner {
        require(_lendPoolLoan != address(0), "EcoScore: invalid lendPoolLoan address");
        lendPoolLoan = ILendPoolLoan(_lendPoolLoan);

        emit SetLendPoolLoan(_lendPoolLoan);
    }

    function setEcoPolicyInfo(
        Constant.EcoZone _zone,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] calldata _pptTax
    ) external override onlyOwner {
        require(
            _zone == Constant.EcoZone.GREEN ||
                _zone == Constant.EcoZone.LIGHTGREEN ||
                _zone == Constant.EcoZone.YELLOW ||
                _zone == Constant.EcoZone.ORANGE ||
                _zone == Constant.EcoZone.RED,
            "EcoScore: setEcoPolicyInfo: invalid zone"
        );
        require(
            _boostMultiple > 0 && _boostMultiple <= MAX_BOOST_MULTIPLE_VALUE,
            "EcoScore: setEcoPolicyInfo: invalid boostMultiple"
        );
        require(
            _maxBoostCap > 0 && _maxBoostCap <= MAX_BOOST_CAP_VALUE,
            "EcoScore: setEcoPolicyInfo: invalid maxBoostCap"
        );
        require(_boostBase >= 0 && _boostBase <= MAX_BOOST_BASE_VALUE, "EcoScore: setEcoPolicyInfo: invalid boostBase");
        require(_redeemFee > 0 && _redeemFee <= MAX_REDEEM_FEE_VALUE, "EcoScore: setEcoPolicyInfo: invalid redeemFee");
        require(_claimTax >= 0 && _claimTax <= MAX_CLAIM_TAX_VALUE, "EcoScore: setEcoPolicyInfo: invalid claimTax");
        require(_pptTax.length == 4, "EcoScore: setEcoPolicyInfo: invalid pptTax");

        ecoPolicyInfo[_zone].boostMultiple = _boostMultiple;
        ecoPolicyInfo[_zone].maxBoostCap = _maxBoostCap;
        ecoPolicyInfo[_zone].boostBase = _boostBase;
        ecoPolicyInfo[_zone].redeemFee = _redeemFee;
        ecoPolicyInfo[_zone].claimTax = _claimTax;
        ecoPolicyInfo[_zone].pptTax = _pptTax;

        emit SetEcoPolicyInfo(_zone, _boostMultiple, _maxBoostCap, _boostBase, _redeemFee, _claimTax, _pptTax);
    }

    function setEcoZoneStandard(
        uint256 _minExpiryOfGreenZone,
        uint256 _minExpiryOfLightGreenZone,
        uint256 _minDrOfGreenZone,
        uint256 _minDrOfLightGreenZone,
        uint256 _minDrOfYellowZone,
        uint256 _minDrOfOrangeZone
    ) external override onlyOwner {
        require(
            _minExpiryOfGreenZone >= 4 weeks && _minExpiryOfGreenZone <= 2 * 365 days,
            "EcoScore: setEcoZoneStandard: invalid minExpiryOfGreenZone"
        );
        require(
            _minExpiryOfLightGreenZone >= 4 weeks && _minExpiryOfLightGreenZone <= 2 * 365 days,
            "EcoScore: setEcoZoneStandard: invalid minExpiryOfLightGreenZone"
        );

        require(
            _minDrOfGreenZone >= 0 && _minDrOfGreenZone <= 100,
            "EcoScore: setEcoZoneStandard: invalid minDrOfGreenZone"
        );
        require(
            _minDrOfLightGreenZone >= 0 && _minDrOfLightGreenZone <= 100,
            "EcoScore: setEcoZoneStandard: invalid minDrOfLightGreenZone"
        );
        require(
            _minDrOfYellowZone >= 0 && _minDrOfYellowZone <= 100,
            "EcoScore: setEcoZoneStandard: invalid minDrOfYellowZone"
        );
        require(
            _minDrOfOrangeZone >= 0 && _minDrOfOrangeZone <= 100,
            "EcoScore: setEcoZoneStandard: invalid minDrOfOrangeZone"
        );
        require(
            _minDrOfGreenZone >= _minDrOfLightGreenZone &&
                _minDrOfLightGreenZone >= _minDrOfYellowZone &&
                _minDrOfYellowZone >= _minDrOfOrangeZone,
            "EcoScore: setEcoZoneStandard: invalid order of zone"
        );

        ecoZoneStandard.minExpiryOfGreenZone = _minExpiryOfGreenZone;
        ecoZoneStandard.minExpiryOfLightGreenZone = _minExpiryOfLightGreenZone;

        ecoZoneStandard.minDrOfGreenZone = _minDrOfGreenZone;
        ecoZoneStandard.minDrOfLightGreenZone = _minDrOfLightGreenZone;
        ecoZoneStandard.minDrOfYellowZone = _minDrOfYellowZone;
        ecoZoneStandard.minDrOfOrangeZone = _minDrOfOrangeZone;
        emit SetEcoZoneStandard(
            _minExpiryOfGreenZone,
            _minExpiryOfLightGreenZone,
            _minDrOfGreenZone,
            _minDrOfLightGreenZone,
            _minDrOfYellowZone,
            _minDrOfOrangeZone
        );
    }

    function setPPTPhaseInfo(
        uint256 _phase1,
        uint256 _phase2,
        uint256 _phase3,
        uint256 _phase4
    ) external override onlyOwner {
        require(_phase1 >= 0 && _phase1 < 100, "EcoScore: setPPTPhaseInfo: invalid phase1 standard");
        require(_phase2 > _phase1 && _phase2 < 100, "EcoScore: setPPTPhaseInfo: invalid phase2 standard");
        require(_phase3 > _phase2 && _phase3 < 100, "EcoScore: setPPTPhaseInfo: invalid phase3 standard");
        require(_phase4 > _phase3 && _phase4 < 100, "EcoScore: setPPTPhaseInfo: invalid phase4 standard");

        pptPhaseInfo.phase1 = _phase1;
        pptPhaseInfo.phase2 = _phase2;
        pptPhaseInfo.phase3 = _phase3;
        pptPhaseInfo.phase4 = _phase4;

        emit SetPPTPhaseInfo(_phase1, _phase2, _phase3, _phase4);
    }

    function setAccountCustomEcoPolicy(
        address account,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] calldata _pptTax
    ) external override onlyOwner {
        require(account != address(0), "EcoScore: setAccountCustomTax: Invalid account");
        require(
            _boostMultiple > 0 && _boostMultiple <= MAX_BOOST_MULTIPLE_VALUE,
            "EcoScore: setAccountCustomTax: Invalid boostMultiple"
        );
        require(
            _maxBoostCap > 0 && _maxBoostCap <= MAX_BOOST_CAP_VALUE,
            "EcoScore: setAccountCustomTax: Invalid maxBoostCap"
        );
        require(
            _boostBase >= 0 && _boostBase <= MAX_BOOST_BASE_VALUE,
            "EcoScore: setAccountCustomTax: Invalid boostBase"
        );
        require(
            _redeemFee > 0 && _redeemFee <= MAX_REDEEM_FEE_VALUE,
            "EcoScore: setAccountCustomTax: Invalid redeemFee"
        );
        require(_claimTax >= 0 && _claimTax <= MAX_CLAIM_TAX_VALUE, "EcoScore: setAccountCustomTax: Invalid claimTax");
        require(_pptTax.length == 4, "EcoScore: setAccountCustomTax: Invalid pptTax");

        _hasCustomTax[account] = true;

        _customEcoPolicyRate[account].boostMultiple = _boostMultiple;
        _customEcoPolicyRate[account].maxBoostCap = _maxBoostCap;
        _customEcoPolicyRate[account].boostBase = _boostBase;
        _customEcoPolicyRate[account].redeemFee = _redeemFee;
        _customEcoPolicyRate[account].claimTax = _claimTax;
        _customEcoPolicyRate[account].pptTax = _pptTax;

        emit SetAccountCustomEcoPolicy(
            account,
            _boostMultiple,
            _maxBoostCap,
            _boostBase,
            _redeemFee,
            _claimTax,
            _pptTax
        );
    }

    function removeAccountCustomEcoPolicy(address account) external override onlyOwner {
        require(account != address(0), "EcoScore: removeAccountCustomTax: Invalid account");
        _hasCustomTax[account] = false;

        emit RemoveAccountCustomEcoPolicy(account);
    }

    function excludeAccount(address account) external override onlyOwner {
        require(account != address(0), "EcoScore: excludeAccount: Invalid account");
        require(!_isExcluded[account], "EcoScore: excludeAccount: Account is already excluded");
        _isExcluded[account] = true;
        _excluded.push(account);

        emit ExcludeAccount(account);
    }

    function includeAccount(address account) external override onlyOwner {
        require(_isExcluded[account], "EcoScore: includeAccount: Account is not excluded before");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _isExcluded[account] = false;
                delete _excluded[_excluded.length - 1];
                break;
            }
        }
        emit IncludeAccount(account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /// @notice 현재까지의 누적 claim grv에 따른 user의 DR 및 Zone 업데이트
    /// @param account user address
    function updateUserEcoScoreInfo(address account) external override onlyGRVDistributor {
        require(account != address(0), "EcoScore: updateUserEcoScoreInfo: Invalid account");
        uint256 userScore = locker.scoreOf(account);
        uint256 remainExpiry = locker.remainExpiryOf(account);
        uint256 numerator = userScore > accountEcoScoreInfo[account].claimedGrv.div(2)
            ? userScore.sub(accountEcoScoreInfo[account].claimedGrv.div(2))
            : 0;
        uint256 ecoDR = userScore > 0 ? numerator.mul(1e18).div(userScore) : 0;
        uint256 ecoDRpercent = ecoDR.mul(100).div(1e18);

        Constant.EcoZone ecoZone = _getEcoZone(ecoDRpercent, remainExpiry);

        Constant.EcoZone prevZone = accountEcoScoreInfo[account].ecoZone;

        if (prevZone != ecoZone) {
            accountEcoScoreInfo[account].ecoZone = ecoZone;
            accountEcoScoreInfo[account].changedEcoZoneAt = block.timestamp;
        }
        accountEcoScoreInfo[account].ecoDR = ecoDR;
    }

    /// @notice Claim시 User의 claimedGRV 정보 업데이트
    function updateUserClaimInfo(address account, uint256 amount) external override onlyWhitelisted {
        accountEcoScoreInfo[account].claimedGrv += amount;
    }

    /// @notice Compound시 User의 compoundGRV 정보 업데이트
    function updateUserCompoundInfo(address account, uint256 amount) external override onlyWhitelisted {
        accountEcoScoreInfo[account].compoundGrv += amount;
    }

    /* ========== VIEWS ========== */
    /// @notice user의 eco score 정보 전달
    /// @param account user address
    function accountEcoScoreInfoOf(address account) external view override returns (Constant.EcoScoreInfo memory) {
        return accountEcoScoreInfo[account];
    }

    /// @notice 특정 zone의 boost parameter 정보 전달
    /// @param zone zone name
    function ecoPolicyInfoOf(Constant.EcoZone zone) external view override returns (Constant.EcoPolicyInfo memory) {
        require(
            zone == Constant.EcoZone.GREEN ||
                zone == Constant.EcoZone.LIGHTGREEN ||
                zone == Constant.EcoZone.YELLOW ||
                zone == Constant.EcoZone.ORANGE ||
                zone == Constant.EcoZone.RED,
            "EcoScore: ecoPolicyInfoOf: invalid zone"
        );
        return ecoPolicyInfo[zone];
    }

    /// @notice 해당 토큰에서의 유저의 boost된 담보량 반환
    /// @dev Eco score 를 적용한 boostedSupply 계산 함수
    /// @param market gToken address
    /// @param user user address
    /// @param userScore user veToken score
    /// @param totalScore total veToken score
    function calculateEcoBoostedSupply(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) external view override returns (uint256) {
        uint256 defaultSupply = IGToken(market).balanceOf(user);
        uint256 boostedSupply = defaultSupply;

        Constant.BoostConstant memory boostConstant = _getBoostConstant(user);

        if (userScore > 0 && totalScore > 0) {
            uint256 totalSupply = IGToken(market).totalSupply();
            uint256 scoreBoosted = _calculateScoreBoosted(totalSupply, userScore, totalScore, boostConstant);

            boostedSupply = boostedSupply.add(scoreBoosted);
        }
        return Math.min(boostedSupply, defaultSupply.mul(boostConstant.boost_max).div(100));
    }

    /// @notice 해당 토큰에서의 유저의 boost된 대출금 반환
    /// @param market gToken address
    /// @param user user address
    /// @param userScore user veToken score
    /// @param totalScore total veToken score
    function calculateEcoBoostedBorrow(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) external view override returns (uint256) {
        uint256 accInterestIndex = IGToken(market).getAccInterestIndex();
        uint256 defaultBorrow = IGToken(market).borrowBalanceOf(user).mul(1e18).div(accInterestIndex);

        if (IGToken(market).underlying() == address(0)) {
            uint256 nftAccInterestIndex = lendPoolLoan.getAccInterestIndex();
            uint256 nftBorrow = lendPoolLoan.userBorrowBalance(user).mul(1e18).div(nftAccInterestIndex);
            defaultBorrow = defaultBorrow.add(nftBorrow);
        }

        uint256 boostedBorrow = defaultBorrow;
        Constant.BoostConstant memory boostConstant = _getBoostConstant(user);

        if (userScore > 0 && totalScore > 0) {
            uint256 totalBorrow = IGToken(market).totalBorrow().mul(1e18).div(accInterestIndex);
            uint256 scoreBoosted = _calculateScoreBoosted(totalBorrow, userScore, totalScore, boostConstant);
            boostedBorrow = boostedBorrow.add(scoreBoosted);
        }
        return Math.min(boostedBorrow, defaultBorrow.mul(boostConstant.boost_max).div(100));
    }

    /// @notice 유저의 Eco score에 따른 세금 비율을 구한뒤 적용하여 실수령금액 및 세금액 반환
    /// @dev 해당 amount만큼 Claim 됐을 시의 변경될 ecoZone을 미리 구한 뒤 해당 ecoZone의 claimTax 및 pptTax를 이용하여 tax 차감
    /// @param account user address
    /// @param value grv amount
    function calculateClaimTaxes(
        address account,
        uint256 value
    ) external view override returns (uint256 adjustedValue, uint256 taxAmount) {
        adjustedValue = value;
        (Constant.EcoZone userPreEcoZone, , ) = _calculatePreUserEcoScoreInfo(
            account,
            value,
            0,
            Constant.EcoScorePreviewOption.CLAIM
        );
        uint256 claimTaxPercent = _getClaimTaxRate(account, userPreEcoZone);
        (uint256 pptTaxPercent, ) = _getPptTaxRate(userPreEcoZone);
        uint256 taxPercent = claimTaxPercent.add(pptTaxPercent);

        if (taxPercent > 0) {
            (adjustedValue, taxAmount) = _calculateTransactionTax(value, taxPercent);
        }
        return (adjustedValue, taxAmount);
    }

    /// @notice 유저의 변경할 GRV수량과 expiry 따른 eco score를 미리 계산하여 사전 tax정보를 반환
    /// @param account user address
    /// @param value grv amount
    /// @param expiry lock exiry date
    /// @param option 0 = lock, 1 = claim, 2 = extend, 3 = lock more
    function getClaimTaxRate(
        address account,
        uint256 value,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view override returns (uint256) {
        (Constant.EcoZone userPreEcoZone, , ) = _calculatePreUserEcoScoreInfo(account, value, expiry, option);
        return _getClaimTaxRate(account, userPreEcoZone);
    }

    /// @notice 유저의 expiry에 따른 할인율 반환
    /// @dev 남은 expiry기간 / 2년 X 100
    /// @param account user address
    function getDiscountTaxRate(address account) external view override returns (uint256) {
        return _getDiscountTaxRate(account);
    }

    /// @notice 유저의 EcoScore 혹은 전달받은 ecoZone에 따른 ppt tax 반환
    /// @param ecoZone user's ecoZone
    function getPptTaxRate(
        Constant.EcoZone ecoZone
    ) external view override returns (uint256 pptTaxRate, uint256 gapPercent) {
        return _getPptTaxRate(ecoZone);
    }

    /// @notice 유저의 Eco score에 따른 세금 비율을 구한뒤 적용하여 실수령금액 및 세금액 반환
    /// @dev 해당 amount만큼 Compound 됐을 시의 변경될 ecoZone을 미리 구한 뒤 해당 ecoZone의 claimTax 및 pptTax를 이용하여 tax 차감
    function calculateCompoundTaxes(
        address account,
        uint256 value,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view override returns (uint256 adjustedValue, uint256 taxAmount) {
        adjustedValue = value;
        (Constant.EcoZone userPreEcoZone, , ) = _calculatePreUserEcoScoreInfo(account, value, expiry, option);
        uint256 claimTaxPercent = _getClaimTaxRate(account, userPreEcoZone);
        (uint256 pptTaxPercent, ) = _getPptTaxRate(userPreEcoZone);
        uint256 discountTaxPercent = _getDiscountTaxRate(account);

        uint256 penaltyTax = claimTaxPercent.add(pptTaxPercent);
        uint256 finalTax = penaltyTax > discountTaxPercent ? SafeMath.sub(penaltyTax, discountTaxPercent) : 0;

        if (finalTax > 0) {
            (adjustedValue, taxAmount) = _calculateTransactionTax(value, finalTax);
        }
        return (adjustedValue, taxAmount);
    }

    /// @notice 유저가 사전에 자신의 액션에 따른 zone 변경정보를 미리 확인하기 위한 함수
    /// @param account user address
    /// @param amount request amount
    /// @param expiry request expiry
    /// @param option 0 = lock, 1 = claim, 2 = extend, 3 = lock more
    function calculatePreUserEcoScoreInfo(
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view override returns (Constant.EcoZone ecoZone, uint256 ecoDR, uint256 userScore) {
        (ecoZone, ecoDR, userScore) = _calculatePreUserEcoScoreInfo(account, amount, expiry, option);
    }

    /// @notice eco zone 구하는 함수
    function getEcoZone(
        uint256 ecoDRpercent,
        uint256 remainExpiry
    ) external view override returns (Constant.EcoZone ecoZone) {
        return _getEcoZone(ecoDRpercent, remainExpiry);
    }

    /// @notice 전달받은 ecoZone으로 계산시의 Boosted된 supply 양을 반환
    /// @dev 예상 boostedSupply를 계산하기 위해 사용
    function calculatePreEcoBoostedSupply(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore,
        Constant.EcoZone ecoZone
    ) external view override returns (uint256) {
        uint256 defaultSupply = IGToken(market).balanceOf(user);
        uint256 boostedSupply = defaultSupply;
        Constant.BoostConstant memory boostConstant = _getPreBoostConstant(user, ecoZone);

        if (userScore > 0 && totalScore > 0) {
            uint256 totalSupply = IGToken(market).totalSupply();
            uint256 scoreBoosted = _calculateScoreBoosted(totalSupply, userScore, totalScore, boostConstant);

            boostedSupply = boostedSupply.add(scoreBoosted);
        }
        return Math.min(boostedSupply, defaultSupply.mul(boostConstant.boost_max).div(100));
    }

    /// @notice 전달받은 ecoZone으로 계산시의 Boosted된 borrow 양을 반환
    /// @dev 예상 boostedBorrow를 계산하기 위해 사용
    function calculatePreEcoBoostedBorrow(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore,
        Constant.EcoZone ecoZone
    ) external view override returns (uint256) {
        uint256 accInterestIndex = IGToken(market).getAccInterestIndex();
        uint256 defaultBorrow = IGToken(market).borrowBalanceOf(user).mul(1e18).div(accInterestIndex);

        if (IGToken(market).underlying() == address(0)) {
            uint256 nftAccInterestIndex = lendPoolLoan.getAccInterestIndex();
            uint256 nftBorrow = lendPoolLoan.userBorrowBalance(user).mul(1e18).div(nftAccInterestIndex);
            defaultBorrow = defaultBorrow.add(nftBorrow);
        }

        uint256 boostedBorrow = defaultBorrow;
        Constant.BoostConstant memory boostConstant = _getPreBoostConstant(user, ecoZone);

        if (userScore > 0 && totalScore > 0) {
            uint256 totalBorrow = IGToken(market).totalBorrow().mul(1e18).div(accInterestIndex);
            uint256 scoreBoosted = _calculateScoreBoosted(totalBorrow, userScore, totalScore, boostConstant);
            boostedBorrow = boostedBorrow.add(scoreBoosted);
        }
        return Math.min(boostedBorrow, defaultBorrow.mul(boostConstant.boost_max).div(100));
    }

    /* ========== PRIVATE FUNCTIONS ========== */
    /// @notice BoostedSupply or BoostedBorrow 계산에 필요한 상수값들을 user의 zone에 따라 결정하여 반환
    /// @param user user address
    function _getBoostConstant(address user) private view returns (Constant.BoostConstant memory) {
        Constant.BoostConstant memory boostConstant;

        if (_hasCustomTax[user]) {
            boostConstant.boost_max = _customEcoPolicyRate[user].maxBoostCap;
            boostConstant.boost_portion = _customEcoPolicyRate[user].boostBase;
            boostConstant.ecoBoost_portion = _customEcoPolicyRate[user].boostMultiple;
        } else {
            Constant.EcoPolicyInfo storage userEcoPolicyInfo = ecoPolicyInfo[accountEcoScoreInfo[user].ecoZone];
            boostConstant.boost_max = userEcoPolicyInfo.maxBoostCap;
            boostConstant.boost_portion = userEcoPolicyInfo.boostBase;
            boostConstant.ecoBoost_portion = userEcoPolicyInfo.boostMultiple;
        }
        return boostConstant;
    }

    /// @notice BoostedSupply or BoostedBorrow 계산에 필요한 상수값들을 전달받은 zone에 따라 결정하여 반환
    /// @param user user address
    /// @param ecoZone expected ecoZone
    function _getPreBoostConstant(
        address user,
        Constant.EcoZone ecoZone
    ) private view returns (Constant.BoostConstant memory) {
        Constant.BoostConstant memory boostConstant;

        if (_hasCustomTax[user]) {
            boostConstant.boost_max = _customEcoPolicyRate[user].maxBoostCap;
            boostConstant.boost_portion = _customEcoPolicyRate[user].boostBase;
            boostConstant.ecoBoost_portion = _customEcoPolicyRate[user].boostMultiple;
        } else {
            Constant.EcoPolicyInfo storage userEcoPolicyInfo = ecoPolicyInfo[ecoZone];
            boostConstant.boost_max = userEcoPolicyInfo.maxBoostCap;
            boostConstant.boost_portion = userEcoPolicyInfo.boostBase;
            boostConstant.ecoBoost_portion = userEcoPolicyInfo.boostMultiple;
        }
        return boostConstant;
    }

    /// @notice DefaultSupply or DefaultBorrow에서 자신의 eco score에 따른 가중치 적용하여 Boosted 값 반환
    /// @param totalAmount DefaultSupply or DefaultBorrow에서
    /// @param userScore user's veGRV
    /// @param totalScore total veGRV
    function _calculateScoreBoosted(
        uint256 totalAmount,
        uint256 userScore,
        uint256 totalScore,
        Constant.BoostConstant memory boostConstant
    ) private pure returns (uint256) {
        uint256 scoreBoosted = totalAmount
            .mul(userScore)
            .div(totalScore)
            .mul(boostConstant.boost_portion)
            .mul(boostConstant.ecoBoost_portion)
            .div(10000);

        return scoreBoosted;
    }

    /// @notice 전달받은 세금을 적용하여 실수령액과 세금액 반환
    function _calculateTransactionTax(
        uint256 value,
        uint256 tax
    ) private pure returns (uint256 adjustedValue, uint256 taxAmount) {
        taxAmount = tax < 100 ? value.mul(tax).div(100) : value;
        adjustedValue = tax < 100 ? value.mul(SafeMath.sub(100, tax)).div(100) : 0;
        return (adjustedValue, taxAmount);
    }

    /// @notice DR percent에 따른 eco zone 반환
    function _getEcoZone(uint256 ecoDRpercent, uint256 remainExpiry) private view returns (Constant.EcoZone ecoZone) {
        require(
            ecoZoneStandard.minExpiryOfGreenZone >= 4 weeks && ecoZoneStandard.minExpiryOfGreenZone <= 2 * 365 days,
            "EcoScore: setEcoZoneStandard: invalid minExpiryOfGreenZone"
        );
        require(
            ecoZoneStandard.minExpiryOfLightGreenZone >= 4 weeks &&
                ecoZoneStandard.minExpiryOfLightGreenZone <= 2 * 365 days,
            "EcoScore: setEcoZoneStandard: invalid minExpiryOfLightGreenZone"
        );
        require(
            ecoZoneStandard.minDrOfGreenZone >= 0 && ecoZoneStandard.minDrOfGreenZone <= 100,
            "EcoScore: _getEcoZone: invalid minDrOfGreenZone"
        );
        require(
            ecoZoneStandard.minDrOfLightGreenZone >= 0 && ecoZoneStandard.minDrOfLightGreenZone <= 100,
            "EcoScore: _getEcoZone: invalid minDrOfLightGreenZone"
        );
        require(
            ecoZoneStandard.minDrOfYellowZone >= 0 && ecoZoneStandard.minDrOfYellowZone <= 100,
            "EcoScore: _getEcoZone: invalid minDrOfYellowZone"
        );
        require(
            ecoZoneStandard.minDrOfOrangeZone >= 0 && ecoZoneStandard.minDrOfOrangeZone <= 100,
            "EcoScore: _getEcoZone: invalid minDrOfOrangeZone"
        );

        if (ecoDRpercent > ecoZoneStandard.minDrOfGreenZone && remainExpiry >= ecoZoneStandard.minExpiryOfGreenZone) {
            ecoZone = Constant.EcoZone.GREEN;
        } else if (
            ecoDRpercent > ecoZoneStandard.minDrOfLightGreenZone &&
            remainExpiry >= ecoZoneStandard.minExpiryOfLightGreenZone
        ) {
            ecoZone = Constant.EcoZone.LIGHTGREEN;
        } else if (ecoDRpercent > ecoZoneStandard.minDrOfYellowZone) {
            ecoZone = Constant.EcoZone.YELLOW;
        } else if (ecoDRpercent > ecoZoneStandard.minDrOfOrangeZone) {
            ecoZone = Constant.EcoZone.ORANGE;
        } else {
            ecoZone = Constant.EcoZone.RED;
        }
    }

    /// @notice 전달받은 유저 정보 및 lock 정보에 따라 변화될 예상 EcoScore Info를 반환
    function _calculatePreUserEcoScoreInfo(
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) private view returns (Constant.EcoZone ecoZone, uint256 ecoDR, uint256 userScore) {
        uint256 preClaimedGrv = 0;
        uint256 remainExpiry = locker.remainExpiryOf(account);

        if (option == Constant.EcoScorePreviewOption.CLAIM) {
            userScore = locker.scoreOf(account);
            preClaimedGrv = (accountEcoScoreInfo[account].claimedGrv).add(amount);
        } else {
            userScore = locker.preScoreOf(account, amount, expiry, option);
            preClaimedGrv = accountEcoScoreInfo[account].claimedGrv;
            remainExpiry = locker.preRemainExpiryOf(expiry);
        }
        preClaimedGrv = preClaimedGrv.div(2);
        uint256 numerator = userScore > preClaimedGrv ? userScore.sub(preClaimedGrv) : 0;
        ecoDR = userScore > 0 ? numerator.mul(1e18).div(userScore) : 0;
        uint256 ecoDRpercent = ecoDR.mul(100).div(1e18);
        ecoZone = _getEcoZone(ecoDRpercent, remainExpiry);
    }

    /// @notice 유저와 전달받은 ecoZone의 정보에 따른 claimTax값을 반환한다
    function _getClaimTaxRate(address account, Constant.EcoZone userEcoZone) private view returns (uint256) {
        uint256 taxPercent = TAX_DEFAULT; // set to default tax 0%
        if (!_isExcluded[account]) {
            if (_hasCustomTax[account]) {
                taxPercent = _customEcoPolicyRate[account].claimTax;
            } else {
                Constant.EcoPolicyInfo storage userEcoTaxInfo = ecoPolicyInfo[userEcoZone];
                taxPercent = userEcoTaxInfo.claimTax;
            }
        }
        return taxPercent;
    }

    /// @notice 유저의 lock duration 비율에 따른 할인율 반환
    function _getDiscountTaxRate(address account) private view returns (uint256 discountTaxRate) {
        uint256 expiry = locker.expiryOf(account);
        discountTaxRate = 0;
        if (expiry > block.timestamp) {
            discountTaxRate = (expiry.sub(block.timestamp)).mul(100).div(locker.getLockUnitMax());
        }
    }

    /// @notice 전달받은 유저의 ecoZone에 따른 pptTax 반환
    function _getPptTaxRate(Constant.EcoZone ecoZone) private view returns (uint256 pptTaxRate, uint256 gapPercent) {
        gapPercent = calculatePptPriceGap();
        uint256 pptTaxIndex = 0;
        if (gapPercent < pptPhaseInfo.phase1) {
            pptTaxIndex = 0;
        } else if (gapPercent < pptPhaseInfo.phase2) {
            pptTaxIndex = 1;
        } else if (gapPercent < pptPhaseInfo.phase3) {
            pptTaxIndex = 2;
        } else {
            pptTaxIndex = 3;
        }

        if (gapPercent > 0) {
            pptTaxRate = ecoPolicyInfo[ecoZone].pptTax[pptTaxIndex];
        } else {
            pptTaxRate = 0;
        }
    }

    /// @notice 현재 ppt reference price와 grv token price의 가격 차이를 반환
    function calculatePptPriceGap() public view returns (uint256 gapPercent) {
        uint256 currentTokenPrice = priceCalculator.priceOf(GRV);
        uint256 referenceTokenPrice = priceProtectionTaxCalculator.referencePrice();
        uint256 gap = currentTokenPrice >= referenceTokenPrice ? 0 : referenceTokenPrice.sub(currentTokenPrice);
        gapPercent = referenceTokenPrice > 0 ? gap.mul(1e2).div(referenceTokenPrice) : 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../library/SafeToken.sol";

import "../interfaces/IBEP20.sol";
import "../interfaces/IGRVDistributor.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/ICore.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IEcoScore.sol";
import "../interfaces/IDashboard.sol";
import "../interfaces/ILendPoolLoan.sol";

contract GRVDistributor is IGRVDistributor, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 private constant LAUNCH_TIMESTAMP = 1681117200;

    /* ========== STATE VARIABLES ========== */

    ICore public core;
    ILocker public locker;
    IPriceCalculator public priceCalculator;
    IEcoScore public ecoScore;
    IDashboard public dashboard;
    ILendPoolLoan public lendPoolLoan;

    mapping(address => Constant.DistributionInfo) public distributions; // Market => DistributionInfo
    mapping(address => mapping(address => Constant.DistributionAccountInfo)) // Market => Account => DistributionAccountInfo
        public accountDistributions; // 토큰별, 유저별 distribution 정보
    mapping(address => uint256) public kickInfo; // user kick count stored

    address public GRV;
    address public taxTreasury;

    /* ========== MODIFIERS ========== */

    /// @notice timestamp에 따른 distribution 정보 갱신
    /// @dev 마지막 time과 비교하여 시간이 지난 경우 해당 시간만큼 쌓인 이자를 계산하여 accPerShareSupply 값을 갱신시켜준다.
    /// @param market gToken address
    modifier updateDistributionOf(address market) {
        Constant.DistributionInfo storage dist = distributions[market];
        if (dist.accruedAt == 0) {
            dist.accruedAt = block.timestamp;
        }

        uint256 timeElapsed = block.timestamp > dist.accruedAt ? block.timestamp.sub(dist.accruedAt) : 0;
        if (timeElapsed > 0) {
            if (dist.totalBoostedSupply > 0) {
                dist.accPerShareSupply = dist.accPerShareSupply.add(
                    dist.supplySpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedSupply)
                );
            }
            if (dist.totalBoostedBorrow > 0) {
                dist.accPerShareBorrow = dist.accPerShareBorrow.add(
                    dist.borrowSpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedBorrow)
                );
            }
        }
        dist.accruedAt = block.timestamp;
        _;
    }

    /// @dev msg.sender 가 core address 인지 검증
    modifier onlyCore() {
        require(msg.sender == address(core), "GRVDistributor: caller is not Core");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize(
        address _grvTokenAddress,
        address _core,
        address _locker,
        address _priceCalculator
    ) external initializer {
        require(_grvTokenAddress != address(0), "GRVDistributor: grv address can't be zero");
        require(_core != address(0), "GRVDistributor: core address can't be zero");
        require(address(locker) == address(0), "GRVDistributor: locker already set");
        require(address(core) == address(0), "GRVDistributor: core already set");
        require(_locker != address(0), "GRVDistributor: locker address can't be zero");
        require(_priceCalculator != address(0), "GRVDistributor: priceCalculator address can't be zero");

        __Ownable_init();
        __ReentrancyGuard_init();

        GRV = _grvTokenAddress;
        core = ICore(_core);
        locker = ILocker(_locker);
        priceCalculator = IPriceCalculator(_priceCalculator);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function approve(address _spender, uint256 amount) external override onlyOwner returns (bool) {
        GRV.safeApprove(_spender, amount);
        return true;
    }

    /// @notice core address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    ///      설정 이후에는 다른 주소로 변경할 수 없음
    /// @param _core core contract address
    function setCore(address _core) public onlyOwner {
        require(_core != address(0), "GRVDistributor: invalid core address");
        require(address(core) == address(0), "GRVDistributor: core already set");
        core = ICore(_core);

        emit SetCore(_core);
    }

    /// @notice priceCalculator address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    /// @param _priceCalculator priceCalculator contract address
    function setPriceCalculator(address _priceCalculator) public onlyOwner {
        require(_priceCalculator != address(0), "GRVDistributor: invalid priceCalculator address");
        priceCalculator = IPriceCalculator(_priceCalculator);

        emit SetPriceCalculator(_priceCalculator);
    }

    /// @notice EcoScore address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    /// @param _ecoScore EcoScore contract address
    function setEcoScore(address _ecoScore) public onlyOwner {
        require(_ecoScore != address(0), "GRVDistributor: invalid ecoScore address");
        ecoScore = IEcoScore(_ecoScore);

        emit SetEcoScore(_ecoScore);
    }

    /// @notice dashboard contract 변경
    /// @dev owner address 에서만 요청 가능
    /// @param _dashboard dashboard contract address
    function setDashboard(address _dashboard) public onlyOwner {
        require(_dashboard != address(0), "GRVDistributor: invalid dashboard address");
        dashboard = IDashboard(_dashboard);

        emit SetDashboard(_dashboard);
    }

    function setTaxTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "GRVDistributor: Tax Treasury can't be zero address");
        taxTreasury = _treasury;
        emit SetTaxTreasury(_treasury);
    }

    /// @notice gToken 의 supplySpeed, borrowSpeed 설정
    /// @dev owner 만 실행 가능
    /// @param gToken gToken address
    /// @param supplySpeed New supply speed
    /// @param borrowSpeed New borrow speed
    function setGRVDistributionSpeed(
        address gToken,
        uint256 supplySpeed,
        uint256 borrowSpeed
    ) external onlyOwner updateDistributionOf(gToken) {
        require(gToken != address(0), "GRVDistributor: setGRVDistributionSpeedL: gToken can't be zero address");
        require(supplySpeed > 0, "GRVDistributor: setGRVDistributionSpeedL: supplySpeed can't be zero");
        require(borrowSpeed > 0, "GRVDistributor: setGRVDistributionSpeedL: borrowSpeed can't be zero");
        Constant.DistributionInfo storage dist = distributions[gToken];
        dist.supplySpeed = supplySpeed;
        dist.borrowSpeed = borrowSpeed;
        emit GRVDistributionSpeedUpdated(gToken, supplySpeed, borrowSpeed);
    }

    function setLendPoolLoan(address _lendPoolLoan) external onlyOwner {
        require(_lendPoolLoan != address(0), "GRVDistributor: lendPoolLoan can't be zero address");
        lendPoolLoan = ILendPoolLoan(_lendPoolLoan);
        emit SetLendPoolLoan(_lendPoolLoan);
    }

    /* ========== VIEWS ========== */

    function accruedGRV(address[] calldata markets, address account) external view override returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < markets.length; i++) {
            amount = amount.add(_accruedGRV(markets[i], account));
        }
        return amount;
    }

    /// @notice 토큰의 distribition 정보 전달
    /// @param market gToken address
    function distributionInfoOf(address market) external view override returns (Constant.DistributionInfo memory) {
        return distributions[market];
    }

    /// @notice 해당 토큰의 유저 distribition 정보 전달
    /// @param market gToken address
    /// @param account user address
    function accountDistributionInfoOf(
        address market,
        address account
    ) external view override returns (Constant.DistributionAccountInfo memory) {
        return accountDistributions[market][account];
    }

    /// @notice 해당 토큰 및 유저의 apy 정보 전달
    /// @param market gToken address
    /// @param account user address
    function apyDistributionOf(
        address market,
        address account
    ) external view override returns (Constant.DistributionAPY memory) {
        (uint256 apySupplyGRV, uint256 apyBorrowGRV) = _calculateMarketDistributionAPY(market);
        (uint256 apyAccountSupplyGRV, uint256 apyAccountBorrowGRV) = _calculateAccountDistributionAPY(market, account);
        return Constant.DistributionAPY(apySupplyGRV, apyBorrowGRV, apyAccountSupplyGRV, apyAccountBorrowGRV);
    }

    /// @notice 특정 유저의 해당 토큰의 boost 비율값 전달
    /// @dev 토큰 담보양, 토큰 대출양(이자인덱스 고려), boostedSupplyRatio= 개인의 부스트 비율에 자신의 담보양을 나눠 계산, boostedBorrowRatio= 개인의 부스트 비율에 자신의 대출양을 나눠 계산
    /// @param market gToken address
    /// @param account user address
    function boostedRatioOf(
        address market,
        address account
    ) external view override returns (uint256 boostedSupplyRatio, uint256 boostedBorrowRatio) {
        uint256 accountSupply = IGToken(market).balanceOf(account);
        uint256 accountBorrow = IGToken(market).borrowBalanceOf(account).mul(1e18).div(
            IGToken(market).getAccInterestIndex()
        );

        if (IGToken(market).underlying() == address(0)) {
            uint256 nftAccInterestIndex = lendPoolLoan.getAccInterestIndex();
            uint256 nftAccountBorrow = lendPoolLoan.userBorrowBalance(account).mul(1e18).div(nftAccInterestIndex);
            accountBorrow = accountBorrow.add(nftAccountBorrow);
        }

        boostedSupplyRatio = accountSupply > 0
            ? accountDistributions[market][account].boostedSupply.mul(1e18).div(accountSupply)
            : 0;
        boostedBorrowRatio = accountBorrow > 0
            ? accountDistributions[market][account].boostedBorrow.mul(1e18).div(accountBorrow)
            : 0;
    }

    function getTaxTreasury() external view override returns (address) {
        return taxTreasury;
    }

    function getPreEcoBoostedInfo(
        address market,
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view override returns (uint256 boostedSupply, uint256 boostedBorrow) {
        uint256 expectedUserScore = locker.preScoreOf(account, amount, expiry, option);
        (uint256 totalScore, ) = locker.totalScore();
        uint256 userScore = locker.scoreOf(account);

        uint256 incrementUserScore = expectedUserScore > userScore ? expectedUserScore.sub(userScore) : 0;

        uint256 expectedTotalScore = totalScore.add(incrementUserScore);
        (Constant.EcoZone ecoZone, , ) = ecoScore.calculatePreUserEcoScoreInfo(account, amount, expiry, option);
        boostedSupply = ecoScore.calculatePreEcoBoostedSupply(
            market,
            account,
            expectedUserScore,
            expectedTotalScore,
            ecoZone
        );
        boostedBorrow = ecoScore.calculatePreEcoBoostedBorrow(
            market,
            account,
            expectedUserScore,
            expectedTotalScore,
            ecoZone
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /// @notice Supply 또는 redeem 발생시 해당 유저의 boostedSupply, accruedGRV, accPerShareSupply값을 갱신 -> 시간에 따른 GRV 토큰 보상 업데이트
    /// @param market gToken address
    /// @param user user address
    function notifySupplyUpdated(
        address market,
        address user
    ) external override nonReentrant onlyCore updateDistributionOf(market) {
        if (block.timestamp < LAUNCH_TIMESTAMP) return;

        Constant.DistributionInfo storage dist = distributions[market];
        Constant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedSupply > 0) {
            uint256 accGRVPerShare = dist.accPerShareSupply.sub(userInfo.accPerShareSupply);
            userInfo.accruedGRV = userInfo.accruedGRV.add(accGRVPerShare.mul(userInfo.boostedSupply).div(1e18));
        }
        userInfo.accPerShareSupply = dist.accPerShareSupply;

        uint256 userScore = locker.scoreOf(user);
        (uint256 totalScore, ) = locker.totalScore();

        ecoScore.updateUserEcoScoreInfo(user);
        uint256 boostedSupply = ecoScore.calculateEcoBoostedSupply(market, user, userScore, totalScore);

        dist.totalBoostedSupply = dist.totalBoostedSupply.add(boostedSupply).sub(userInfo.boostedSupply);
        userInfo.boostedSupply = boostedSupply;
    }

    /// @notice Borrow 또는 Repay 발생시 해당 유저의 boostedBorrow, accruedGRV, accPerShareBorrow 갱신 -> 시간에 따른 GRV 토큰 보상 업데이트
    /// @param market gToken address
    /// @param user user address
    function notifyBorrowUpdated(
        address market,
        address user
    ) external override nonReentrant onlyCore updateDistributionOf(market) {
        if (block.timestamp < LAUNCH_TIMESTAMP) return;

        Constant.DistributionInfo storage dist = distributions[market];
        Constant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedBorrow > 0) {
            uint256 accGRVPerShare = dist.accPerShareBorrow.sub(userInfo.accPerShareBorrow);
            userInfo.accruedGRV = userInfo.accruedGRV.add(accGRVPerShare.mul(userInfo.boostedBorrow).div(1e18));
        }
        userInfo.accPerShareBorrow = dist.accPerShareBorrow;

        uint256 userScore = locker.scoreOf(user);
        (uint256 totalScore, ) = locker.totalScore();

        ecoScore.updateUserEcoScoreInfo(user);
        uint256 boostedBorrow = ecoScore.calculateEcoBoostedBorrow(market, user, userScore, totalScore);

        dist.totalBoostedBorrow = dist.totalBoostedBorrow.add(boostedBorrow).sub(userInfo.boostedBorrow);
        userInfo.boostedBorrow = boostedBorrow;
    }

    /// @notice 특정 토큰 전송시 이자 내용 업데이트
    /// @dev 전송자와 수신자의 각각의 남은 보상 이자를 처리한 후 각자의 부스트율 업데이트
    /// @param gToken gToken address
    /// @param sender sender address
    /// @param receiver receiver address
    function notifyTransferred(
        address gToken,
        address sender,
        address receiver
    ) external override nonReentrant onlyCore updateDistributionOf(gToken) {
        if (block.timestamp < LAUNCH_TIMESTAMP) return;

        require(sender != receiver, "GRVDistributor: invalid transfer");
        Constant.DistributionInfo storage dist = distributions[gToken];
        Constant.DistributionAccountInfo storage senderInfo = accountDistributions[gToken][sender];
        Constant.DistributionAccountInfo storage receiverInfo = accountDistributions[gToken][receiver];

        if (senderInfo.boostedSupply > 0) {
            uint256 accGRVPerShare = dist.accPerShareSupply.sub(senderInfo.accPerShareSupply);
            senderInfo.accruedGRV = senderInfo.accruedGRV.add(accGRVPerShare.mul(senderInfo.boostedSupply).div(1e18));
        }
        senderInfo.accPerShareSupply = dist.accPerShareSupply;

        if (receiverInfo.boostedSupply > 0) {
            uint256 accGRVPerShare = dist.accPerShareSupply.sub(receiverInfo.accPerShareSupply);
            receiverInfo.accruedGRV = receiverInfo.accruedGRV.add(
                accGRVPerShare.mul(receiverInfo.boostedSupply).div(1e18)
            );
        }
        receiverInfo.accPerShareSupply = dist.accPerShareSupply;

        uint256 senderScore = locker.scoreOf(sender);
        uint256 receiverScore = locker.scoreOf(receiver);
        (uint256 totalScore, ) = locker.totalScore();

        ecoScore.updateUserEcoScoreInfo(sender);
        ecoScore.updateUserEcoScoreInfo(receiver);
        uint256 boostedSenderSupply = ecoScore.calculateEcoBoostedSupply(gToken, sender, senderScore, totalScore);
        uint256 boostedReceiverSupply = ecoScore.calculateEcoBoostedSupply(gToken, receiver, receiverScore, totalScore);
        dist.totalBoostedSupply = dist
            .totalBoostedSupply
            .add(boostedSenderSupply)
            .add(boostedReceiverSupply)
            .sub(senderInfo.boostedSupply)
            .sub(receiverInfo.boostedSupply);
        senderInfo.boostedSupply = boostedSenderSupply;
        receiverInfo.boostedSupply = boostedReceiverSupply;
    }

    /// @notice 토큰별로 소유하고 있는 보상 토큰을 모두 합하여 유저에게 전달
    /// @param markets gToken address
    /// @param account user address
    function claimGRV(address[] calldata markets, address account) external override onlyCore {
        require(account != address(0), "GRVDistributor: claimGRV: User account can't be zero address");
        require(taxTreasury != address(0), "GRVDistributor: claimGRV: TaxTreasury can't be zero address");
        uint256 amount = 0;
        uint256 userScore = locker.scoreOf(account);
        (uint256 totalScore, ) = locker.totalScore();

        for (uint256 i = 0; i < markets.length; i++) {
            amount = amount.add(_claimGRV(markets[i], account, userScore, totalScore));
        }
        require(amount > 0, "GRVDistributor: claimGRV: Can't claim amount of zero");
        (uint256 adjustedValue, uint256 taxAmount) = ecoScore.calculateClaimTaxes(account, amount);

        ecoScore.updateUserClaimInfo(account, amount);
        _updateAccountBoostedInfo(account);

        adjustedValue = Math.min(adjustedValue, IBEP20(GRV).balanceOf(address(this)));
        GRV.safeTransfer(account, adjustedValue);

        taxAmount = Math.min(taxAmount, IBEP20(GRV).balanceOf(address(this)));
        GRV.safeTransfer(taxTreasury, taxAmount);
        emit GRVClaimed(account, amount);
    }

    /// @notice 현재까지 쌓인 유저의 보상 GRV를 전부 재락업한다
    /// @dev GRV 재락업시 Claim tax와 Discount tax를 고려한 양만큼만 재락업한다.
    /// @param markets gToken address
    /// @param account user address
    function compound(address[] calldata markets, address account) external override onlyCore {
        require(account != address(0), "GRVDistributor: compound: User account can't be zero address");
        uint256 expiryOfAccount = locker.expiryOf(account);
        _compound(markets, account, expiryOfAccount, Constant.EcoScorePreviewOption.LOCK_MORE);
    }

    /// @notice 아직 GRV Lock한적이 없는 유저의 경우 쌓인 보상 GRV를 바로 Lock 할 수 있도록 하는 함수
    /// @param account user address
    function firstDeposit(address[] calldata markets, address account, uint256 expiry) external override onlyCore {
        require(account != address(0), "GRVDistributor: firstDeposit: User account can't be zero address");
        uint256 balanceOfLockedGrv = locker.balanceOf(account);
        require(balanceOfLockedGrv == 0, "GRVDistributor: firstDeposit: User already deposited");

        _compound(markets, account, expiry, Constant.EcoScorePreviewOption.LOCK);
    }

    /// @notice 특정 유저의 score가 0이 될 경우 해당 유저의 부스트 점수를 없애고 초기 담보량으로 업데이트한다.
    /// @param user user address
    function kick(address user) external override nonReentrant {
        if (block.timestamp < LAUNCH_TIMESTAMP) return;
        _kick(user);
    }

    function kicks(address[] calldata users) external override nonReentrant {
        if (block.timestamp < LAUNCH_TIMESTAMP) return;
        for (uint256 i = 0; i < users.length; i++) {
            _kick(users[i]);
        }
    }

    function _kick(address user) private {
        uint256 userScore = locker.scoreOf(user);
        require(userScore == 0, "GRVDistributor: kick not allowed");
        (uint256 totalScore, ) = locker.totalScore();

        address[] memory markets = core.allMarkets();
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            Constant.DistributionAccountInfo memory userInfo = accountDistributions[market][user];
            if (userInfo.boostedSupply > 0) _updateSupplyOf(market, user, userScore, totalScore);
            if (userInfo.boostedBorrow > 0) _updateBorrowOf(market, user, userScore, totalScore);
        }
        kickInfo[msg.sender] += 1;
    }

    /// @notice 유저가 locker에 deposit 후 boostedSupply, boostedBorrow 정보 업데이트를 위해 호출하는 함수
    /// @param user user address
    function updateAccountBoostedInfo(address user) external override {
        require(user != address(0), "GRVDistributor: compound: User account can't be zero address");
        _updateAccountBoostedInfo(user);
    }

    function updateAccountBoostedInfos(address[] calldata users) external override {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] != address(0)) {
                _updateAccountBoostedInfo(users[i]);
            }
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /// @notice 유저가 locker에 deposit 후 boostedSupply, boostedBorrow 정보 업데이트를 위해 호출하는 내부 함수
    /// @param user user address
    function _updateAccountBoostedInfo(address user) private {
        if (block.timestamp < LAUNCH_TIMESTAMP) return;

        uint256 userScore = locker.scoreOf(user);
        (uint256 totalScore, ) = locker.totalScore();
        ecoScore.updateUserEcoScoreInfo(user);

        address[] memory markets = core.allMarkets();
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            Constant.DistributionAccountInfo memory userInfo = accountDistributions[market][user];
            if (userInfo.boostedSupply > 0) _updateSupplyOf(market, user, userScore, totalScore);
            if (userInfo.boostedBorrow > 0) _updateBorrowOf(market, user, userScore, totalScore);
        }
    }

    /// @notice 축적된 보상 토큰 반환
    /// @dev time에 따라 그동안 축적된 보상 토큰 수량을 계산하여 반환한다
    /// @param market gToken address
    /// @param user user address
    function _accruedGRV(address market, address user) private view returns (uint256) {
        Constant.DistributionInfo memory dist = distributions[market];
        Constant.DistributionAccountInfo memory userInfo = accountDistributions[market][user];

        uint256 amount = userInfo.accruedGRV;
        uint256 accPerShareSupply = dist.accPerShareSupply;
        uint256 accPerShareBorrow = dist.accPerShareBorrow;

        uint256 timeElapsed = block.timestamp > dist.accruedAt ? block.timestamp.sub(dist.accruedAt) : 0;
        if (
            timeElapsed > 0 ||
            (accPerShareSupply != userInfo.accPerShareSupply) ||
            (accPerShareBorrow != userInfo.accPerShareBorrow)
        ) {
            if (dist.totalBoostedSupply > 0) {
                accPerShareSupply = accPerShareSupply.add(
                    dist.supplySpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedSupply)
                );

                uint256 pendingGRV = userInfo.boostedSupply.mul(accPerShareSupply.sub(userInfo.accPerShareSupply)).div(
                    1e18
                );
                amount = amount.add(pendingGRV);
            }

            if (dist.totalBoostedBorrow > 0) {
                accPerShareBorrow = accPerShareBorrow.add(
                    dist.borrowSpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedBorrow)
                );

                uint256 pendingGRV = userInfo.boostedBorrow.mul(accPerShareBorrow.sub(userInfo.accPerShareBorrow)).div(
                    1e18
                );
                amount = amount.add(pendingGRV);
            }
        }
        return amount;
    }

    /// @notice 유저의 축적된 보상 토큰 반환 및 0으로 초기화
    /// @dev time에 따라 그동안 축적된 보상 토큰수량을 계산하여 반환한다
    /// @param market gToken address
    /// @param user user address
    function _claimGRV(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) private returns (uint256 amount) {
        Constant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedSupply > 0) _updateSupplyOf(market, user, userScore, totalScore);
        if (userInfo.boostedBorrow > 0) _updateBorrowOf(market, user, userScore, totalScore);

        amount = amount.add(userInfo.accruedGRV);
        userInfo.accruedGRV = 0;

        return amount;
    }

    /// @notice 특정 토큰의 담보 및 대출 APY 계산 후 반환
    /// @dev (담보스피드 X 365일 X 거버넌스토큰 가격 / 전체 담보 부스트 X 토큰 교환비 X 토큰가격 ) X 1e36
    /// @param market gToken address
    function _calculateMarketDistributionAPY(
        address market
    ) private view returns (uint256 apySupplyGRV, uint256 apyBorrowGRV) {
        uint256 decimals = _getDecimals(market);
        // base supply GRV APY == average supply GRV APY * (Total balance / total Boosted balance)
        // base supply GRV APY == (GRVRate * 365 days * price Of GRV) / (Total balance * exchangeRate * price of asset) * (Total balance / Total Boosted balance)
        // base supply GRV APY == (GRVRate * 365 days * price Of GRV) / (Total boosted balance * exchangeRate * price of asset)
        {
            uint256 numerSupply = distributions[market].supplySpeed.mul(365 days).mul(dashboard.getCurrentGRVPrice());
            uint256 denomSupply = distributions[market]
                .totalBoostedSupply
                .mul(10 ** (18 - decimals))
                .mul(IGToken(market).exchangeRate())
                .mul(priceCalculator.getUnderlyingPrice(market))
                .div(1e36);
            apySupplyGRV = denomSupply > 0 ? numerSupply.div(denomSupply) : 0;
        }

        // base borrow GRV APY == average borrow GRV APY * (Total balance / total Boosted balance)
        // base borrow GRV APY == (GRVRate * 365 days * price Of GRV) / (Total balance * exchangeRate * price of asset) * (Total balance / Total Boosted balance)
        // base borrow GRV APY == (GRVRate * 365 days * price Of GRV) / (Total boosted balance * exchangeRate * price of asset)
        {
            uint256 numerBorrow = distributions[market].borrowSpeed.mul(365 days).mul(dashboard.getCurrentGRVPrice());
            uint256 denomBorrow = distributions[market]
                .totalBoostedBorrow
                .mul(10 ** (18 - decimals))
                .mul(IGToken(market).getAccInterestIndex())
                .mul(priceCalculator.getUnderlyingPrice(market))
                .div(1e36);
            apyBorrowGRV = denomBorrow > 0 ? numerBorrow.div(denomBorrow) : 0;
        }
    }

    /// @notice 특정 토큰의 유저의 담보 및 대출 APY 계산 후 반환
    /// @dev
    /// @param market gToken address
    function _calculateAccountDistributionAPY(
        address market,
        address account
    ) private view returns (uint256 apyAccountSupplyGRV, uint256 apyAccountBorrowGRV) {
        if (account == address(0)) return (0, 0);
        (uint256 apySupplyGRV, uint256 apyBorrowGRV) = _calculateMarketDistributionAPY(market);

        // user supply GRV APY == ((GRVRate * 365 days * price Of GRV) / (Total boosted balance * exchangeRate * price of asset) ) * my boosted balance  / my balance
        uint256 accountSupply = IGToken(market).balanceOf(account);
        apyAccountSupplyGRV = accountSupply > 0
            ? apySupplyGRV.mul(accountDistributions[market][account].boostedSupply).div(accountSupply)
            : 0;

        // user borrow GRV APY == (GRVRate * 365 days * price Of GRV) / (Total boosted balance * interestIndex * price of asset) * my boosted balance  / my balance
        uint256 accountBorrow = IGToken(market).borrowBalanceOf(account).mul(1e18).div(
            IGToken(market).getAccInterestIndex()
        );

        if (IGToken(market).underlying() == address(0)) {
            uint256 nftAccInterestIndex = lendPoolLoan.getAccInterestIndex();
            accountBorrow = accountBorrow.add(
                lendPoolLoan.userBorrowBalance(account).mul(1e18).div(nftAccInterestIndex)
            );
        }

        apyAccountBorrowGRV = accountBorrow > 0
            ? apyBorrowGRV.mul(accountDistributions[market][account].boostedBorrow).div(accountBorrow)
            : 0;
    }

    /// @notice kick, Claim용 update supply
    /// @dev user score가 0인 경우 boostedSupply 값을 초기 담보금으로 업데이트 하기 위함
    /// @param market gToken address
    function _updateSupplyOf(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) private updateDistributionOf(market) {
        Constant.DistributionInfo storage dist = distributions[market];
        Constant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedSupply > 0) {
            uint256 accGRVPerShare = dist.accPerShareSupply.sub(userInfo.accPerShareSupply);
            userInfo.accruedGRV = userInfo.accruedGRV.add(accGRVPerShare.mul(userInfo.boostedSupply).div(1e18));
        }
        userInfo.accPerShareSupply = dist.accPerShareSupply;

        uint256 boostedSupply = ecoScore.calculateEcoBoostedSupply(market, user, userScore, totalScore);
        dist.totalBoostedSupply = dist.totalBoostedSupply.add(boostedSupply).sub(userInfo.boostedSupply);
        userInfo.boostedSupply = boostedSupply;
    }

    function _updateBorrowOf(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) private updateDistributionOf(market) {
        Constant.DistributionInfo storage dist = distributions[market];
        Constant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedBorrow > 0) {
            uint256 accGRVPerShare = dist.accPerShareBorrow.sub(userInfo.accPerShareBorrow);
            userInfo.accruedGRV = userInfo.accruedGRV.add(accGRVPerShare.mul(userInfo.boostedBorrow).div(1e18));
        }
        userInfo.accPerShareBorrow = dist.accPerShareBorrow;

        uint256 boostedBorrow = ecoScore.calculateEcoBoostedBorrow(market, user, userScore, totalScore);
        dist.totalBoostedBorrow = dist.totalBoostedBorrow.add(boostedBorrow).sub(userInfo.boostedBorrow);
        userInfo.boostedBorrow = boostedBorrow;
    }

    function _compound(
        address[] calldata markets,
        address account,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) private {
        require(taxTreasury != address(0), "GRVDistributor: _compound: TaxTreasury can't be zero address");
        uint256 amount = 0;
        uint256 userScore = locker.scoreOf(account);
        (uint256 totalScore, ) = locker.totalScore();

        for (uint256 i = 0; i < markets.length; i++) {
            amount = amount.add(_claimGRV(markets[i], account, userScore, totalScore));
        }
        (uint256 adjustedValue, uint256 taxAmount) = ecoScore.calculateCompoundTaxes(account, amount, expiry, option);

        locker.depositBehalf(account, adjustedValue, expiry);
        ecoScore.updateUserCompoundInfo(account, adjustedValue);

        taxAmount = Math.min(taxAmount, IBEP20(GRV).balanceOf(address(this)));
        if (taxAmount > 0) {
            GRV.safeTransfer(taxTreasury, taxAmount);
        }

        emit GRVCompound(account, amount, adjustedValue, taxAmount, expiry);
    }

    function _getDecimals(address gToken) internal view returns (uint256 decimals) {
        address underlying = IGToken(gToken).underlying();
        if (underlying == address(0)) {
            decimals = 18;
            // ETH
        } else {
            decimals = IBEP20(underlying).decimals();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "../library/WhitelistUpgradeable.sol";
import "../library/SafeToken.sol";
import "../library/Constant.sol";

import "../interfaces/ILocker.sol";
import "../interfaces/IRebateDistributor.sol";
import "../interfaces/IGRVDistributor.sol";

contract Locker is ILocker, WhitelistUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    uint256 public constant LOCK_UNIT_BASE = 7 days;
    uint256 public constant LOCK_UNIT_MAX = 2 * 365 days; // 2 years
    uint256 public constant LOCK_UNIT_MIN = 4 weeks; // 4 weeks = 1 month

    /* ========== STATE VARIABLES ========== */

    address public GRV;
    IGRVDistributor public grvDistributor;
    IRebateDistributor public rebateDistributor;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public expires;

    uint256 public override totalBalance;

    uint256 private _lastTotalScore;
    uint256 private _lastSlope;
    uint256 private _lastTimestamp;
    mapping(uint256 => uint256) private _slopeChanges; // Timestamp => Expire amount / Max Period
    mapping(address => Constant.LockInfo[]) private _lockHistory;
    mapping(address => uint256) private _firstLockTime;

    /* ========== VARIABLE GAP ========== */

    uint256[49] private __gap;

    /* ========== INITIALIZER ========== */

    function initialize(address _grvTokenAddress) external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        _lastTimestamp = block.timestamp;

        require(_grvTokenAddress != address(0), "Locker: GRV address can't be zero");
        GRV = _grvTokenAddress;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice grvDistributor 변경
    /// @dev owner address 에서만 요청 가능
    /// @param _grvDistributor 새로운 grvDistributor address
    function setGRVDistributor(address _grvDistributor) external override onlyOwner {
        require(_grvDistributor != address(0), "Locker: invalid grvDistributor address");
        grvDistributor = IGRVDistributor(_grvDistributor);
        emit GRVDistributorUpdated(_grvDistributor);
    }

    /// @notice Rebate distributor 변경
    /// @dev owner address 에서만 요청 가능
    /// @param _rebateDistributor 새로운 rebate distributor address
    function setRebateDistributor(address _rebateDistributor) external override onlyOwner {
        require(_rebateDistributor != address(0), "Locker: invalid grvDistributor address");
        rebateDistributor = IRebateDistributor(_rebateDistributor);
        emit RebateDistributorUpdated(_rebateDistributor);
    }

    /// @notice 긴급상황시 Deposit, Withdraw를 막기 위한 pause
    function pause() external override onlyOwner {
        _pause();
        emit Pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
        emit Unpause();
    }

    /* ========== VIEWS ========== */

    /// @notice View amount of locked GRV
    /// @param account Account address
    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    /// @notice View lock expire time of account
    /// @param account Account address
    function expiryOf(address account) external view override returns (uint256) {
        return expires[account];
    }

    /// @notice View withdrawable amount that lock had been expired
    /// @param account Account address
    function availableOf(address account) external view override returns (uint256) {
        return expires[account] < block.timestamp ? balances[account] : 0;
    }

    /// @notice View Lock Unit Max value
    function getLockUnitMax() external view override returns (uint256) {
        return LOCK_UNIT_MAX;
    }

    /// @notice View total score
    /// @dev 마지막 계산된 total score 시점에서부터 지난 시간 만큼의 deltaScore을 구한 뒤 차감하여, 현재의 total score 값을 구하여 반환한다.
    function totalScore() public view override returns (uint256 score, uint256 slope) {
        score = _lastTotalScore;
        slope = _lastSlope;

        uint256 prevTimestamp = _lastTimestamp;
        uint256 nextTimestamp = _onlyTruncateExpiry(_lastTimestamp).add(LOCK_UNIT_BASE);
        while (nextTimestamp < block.timestamp) {
            uint256 deltaScore = nextTimestamp.sub(prevTimestamp).mul(slope);
            score = score < deltaScore ? 0 : score.sub(deltaScore);
            slope = slope.sub(_slopeChanges[nextTimestamp]);

            prevTimestamp = nextTimestamp;
            nextTimestamp = nextTimestamp.add(LOCK_UNIT_BASE);
        }
        uint256 deltaScore = block.timestamp > prevTimestamp ? block.timestamp.sub(prevTimestamp).mul(slope) : 0;
        score = score > deltaScore ? score.sub(deltaScore) : 0;
    }

    /// @notice Calculate time-weighted balance of account (유저의 현재 score 반환)
    /// @dev 남은시간 대비 현재까지의 score 계산
    ///      Expiry time 에 가까워질수록 score 감소
    ///      if 만료일 = 현재시간, score = 0
    /// @param account Account of which the balance will be calculated
    function scoreOf(address account) external view override returns (uint256) {
        if (expires[account] < block.timestamp) return 0;
        return expires[account].sub(block.timestamp).mul(balances[account].div(LOCK_UNIT_MAX));
    }

    /// @notice 남은 만료 기간 반환
    /// @param account user address
    function remainExpiryOf(address account) external view override returns (uint256) {
        if (expires[account] < block.timestamp) return 0;
        return expires[account].sub(block.timestamp);
    }

    /// @notice 예상 만료일에 따른 남은 만료 기간 반환
    /// @param expiry lock period
    function preRemainExpiryOf(uint256 expiry) external view override returns (uint256) {
        if (expiry <= block.timestamp) return 0;
        expiry = _truncateExpiry(expiry);
        require(
            expiry > block.timestamp && expiry <= _truncateExpiry(block.timestamp + LOCK_UNIT_MAX),
            "Locker: preRemainExpiryOf: invalid expiry"
        );
        return expiry.sub(block.timestamp);
    }

    /// @notice Pre-Calculate time-weighted balance of account (유저의 예상 score 반환)
    /// @dev 주어진 GRV수량과 연장만료일에 따라 사전에 미리 veGrv점수를 구하기 위함
    /// @param account Account of which the balance will be calculated
    /// @param amount Amount of GRV, Lock GRV 또는 Claim GRV수량을 전달받는다.
    /// @param expiry Extended expiry, 연장될 만료일을 전달 받는다.
    /// @param option 0 = lock, 1 = claim, 2 = extend, 3 = lock more
    function preScoreOf(
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view override returns (uint256) {
        if (option == Constant.EcoScorePreviewOption.EXTEND && expires[account] < block.timestamp) return 0;
        uint256 expectedAmount = balances[account];
        uint256 expectedExpires = expires[account];

        if (option == Constant.EcoScorePreviewOption.LOCK) {
            expectedAmount = expectedAmount.add(amount);
            expectedExpires = _truncateExpiry(expiry);
        } else if (option == Constant.EcoScorePreviewOption.LOCK_MORE) {
            expectedAmount = expectedAmount.add(amount);
        } else if (option == Constant.EcoScorePreviewOption.EXTEND) {
            expectedExpires = _truncateExpiry(expiry);
        }
        if (expectedExpires <= block.timestamp) {
            return 0;
        }
        return expectedExpires.sub(block.timestamp).mul(expectedAmount.div(LOCK_UNIT_MAX));
    }

    /// @notice account 의 특정 시점의 score 를 계산
    /// @param account account address
    /// @param timestamp timestamp
    function scoreOfAt(address account, uint256 timestamp) external view override returns (uint256) {
        uint256 count = _lockHistory[account].length;
        if (count == 0 || _lockHistory[account][count - 1].expiry <= timestamp) return 0;

        for (uint256 i = count - 1; i < uint256(-1); i--) {
            Constant.LockInfo storage lock = _lockHistory[account][i];

            if (lock.timestamp <= timestamp) {
                return lock.expiry <= timestamp ? 0 : lock.expiry.sub(timestamp).mul(lock.amount).div(LOCK_UNIT_MAX);
            }
        }
        return 0;
    }

    function lockInfoOf(address account) external view override returns (Constant.LockInfo[] memory) {
        return _lockHistory[account];
    }

    function firstLockTimeInfoOf(address account) external view override returns (uint256) {
        return _firstLockTime[account];
    }

    /// @notice 전달받은 expiry 기간과 가까운 목요일을 기준 만료일로 정한 후 7일 더 추가하여 최종 만료일을 반환한다.
    /// @param time expiry time
    function truncateExpiry(uint256 time) external view override returns (uint256) {
        return _truncateExpiry(time);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Deposit GRV (Lock)
    /// @dev deposit amount와 만료일을 받아 해당 내용 업데이트, total score 업데이트, total balance 업데이트 , 유저 정보 업데이트
    /// @param amount GRV token amount to deposit
    /// @param expiry Lock expire time
    function deposit(uint256 amount, uint256 expiry) external override nonReentrant whenNotPaused {
        require(amount > 0, "Locker: invalid amount");
        expiry = balances[msg.sender] == 0 ? _truncateExpiry(expiry) : expires[msg.sender];
        require(
            block.timestamp < expiry && expiry <= _truncateExpiry(block.timestamp + LOCK_UNIT_MAX),
            "Locker: deposit: invalid expiry"
        );
        if (balances[msg.sender] == 0) {
            uint256 lockPeriod = expiry > block.timestamp ? expiry.sub(block.timestamp) : 0;
            require(lockPeriod >= LOCK_UNIT_MIN, "Locker: The expiry does not meet the minimum period");
            _firstLockTime[msg.sender] = block.timestamp;
        }
        _slopeChanges[expiry] = _slopeChanges[expiry].add(amount.div(LOCK_UNIT_MAX));
        _updateTotalScore(amount, expiry);

        GRV.safeTransferFrom(msg.sender, address(this), amount);
        totalBalance = totalBalance.add(amount);

        balances[msg.sender] = balances[msg.sender].add(amount);
        expires[msg.sender] = expiry;

        _updateGRVDistributorBoostedInfo(msg.sender);

        _lockHistory[msg.sender].push(
            Constant.LockInfo({timestamp: block.timestamp, amount: balances[msg.sender], expiry: expires[msg.sender]})
        );

        emit Deposit(msg.sender, amount, expiry);
    }

    /**
     * @notice Extend for expiry of `msg.sender`
     * @param nextExpiry New Lock expire time
     */
    function extendLock(uint256 nextExpiry) external override nonReentrant whenNotPaused {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Locker: zero balance");

        uint256 prevExpiry = expires[msg.sender];
        nextExpiry = _truncateExpiry(nextExpiry);
        require(block.timestamp < prevExpiry, "Locker: expired lock");
        require(
            Math.max(prevExpiry, block.timestamp) < nextExpiry &&
                nextExpiry <= _truncateExpiry(block.timestamp + LOCK_UNIT_MAX),
            "Locker: invalid expiry time"
        );

        uint256 slopeChange = (_slopeChanges[prevExpiry] < amount.div(LOCK_UNIT_MAX))
            ? _slopeChanges[prevExpiry]
            : amount.div(LOCK_UNIT_MAX);
        _slopeChanges[prevExpiry] = _slopeChanges[prevExpiry].sub(slopeChange);
        _slopeChanges[nextExpiry] = _slopeChanges[nextExpiry].add(slopeChange);
        _updateTotalScoreExtendingLock(amount, prevExpiry, nextExpiry);
        expires[msg.sender] = nextExpiry;

        _updateGRVDistributorBoostedInfo(msg.sender);

        _lockHistory[msg.sender].push(
            Constant.LockInfo({timestamp: block.timestamp, amount: balances[msg.sender], expiry: expires[msg.sender]})
        );

        emit ExtendLock(msg.sender, nextExpiry);
    }

    /**
     * @notice Withdraw all tokens for `msg.sender`
     * @dev Only possible if the lock has expired
     */
    function withdraw() external override nonReentrant whenNotPaused {
        require(balances[msg.sender] > 0 && block.timestamp >= expires[msg.sender], "Locker: invalid state");
        _updateTotalScore(0, 0);

        uint256 amount = balances[msg.sender];
        totalBalance = totalBalance.sub(amount);
        delete balances[msg.sender];
        delete expires[msg.sender];
        delete _firstLockTime[msg.sender];
        GRV.safeTransfer(msg.sender, amount);

        _updateGRVDistributorBoostedInfo(msg.sender);

        emit Withdraw(msg.sender);
    }

    /**
     * @notice Withdraw all tokens for `msg.sender` and Lock again until given expiry
     *  @dev Only possible if the lock has expired
     * @param expiry Lock expire time
     */
    function withdrawAndLock(uint256 expiry) external override nonReentrant whenNotPaused {
        uint256 amount = balances[msg.sender];
        require(amount > 0 && block.timestamp >= expires[msg.sender], "Locker: invalid state");

        expiry = _truncateExpiry(expiry);
        require(
            block.timestamp < expiry && expiry <= _truncateExpiry(block.timestamp + LOCK_UNIT_MAX),
            "Locker: withdrawAndLock: invalid expiry"
        );

        _slopeChanges[expiry] = _slopeChanges[expiry].add(amount.div(LOCK_UNIT_MAX));
        _updateTotalScore(amount, expiry);

        expires[msg.sender] = expiry;

        _updateGRVDistributorBoostedInfo(msg.sender);
        _firstLockTime[msg.sender] = block.timestamp;

        _lockHistory[msg.sender].push(
            Constant.LockInfo({timestamp: block.timestamp, amount: balances[msg.sender], expiry: expires[msg.sender]})
        );

        emit WithdrawAndLock(msg.sender, expiry);
    }

    /// @notice whiteList 유저가 타인의 Deposit을 대신 해주는 함수
    function depositBehalf(
        address account,
        uint256 amount,
        uint256 expiry
    ) external override onlyWhitelisted nonReentrant whenNotPaused {
        require(amount > 0, "Locker: invalid amount");

        expiry = balances[account] == 0 ? _truncateExpiry(expiry) : expires[account];
        require(
            block.timestamp < expiry && expiry <= _truncateExpiry(block.timestamp + LOCK_UNIT_MAX),
            "Locker: depositBehalf: invalid expiry"
        );

        if (balances[account] == 0) {
            uint256 lockPeriod = expiry > block.timestamp ? expiry.sub(block.timestamp) : 0;
            require(lockPeriod >= LOCK_UNIT_MIN, "Locker: The expiry does not meet the minimum period");
            _firstLockTime[account] = block.timestamp;
        }

        _slopeChanges[expiry] = _slopeChanges[expiry].add(amount.div(LOCK_UNIT_MAX));
        _updateTotalScore(amount, expiry);

        GRV.safeTransferFrom(msg.sender, address(this), amount);
        totalBalance = totalBalance.add(amount);

        balances[account] = balances[account].add(amount);
        expires[account] = expiry;

        _updateGRVDistributorBoostedInfo(account);
        _lockHistory[account].push(
            Constant.LockInfo({timestamp: block.timestamp, amount: balances[account], expiry: expires[account]})
        );

        emit DepositBehalf(msg.sender, account, amount, expiry);
    }

    /// @notice WhiteList 유저가 타인의 Withdraw 를 대신 해주는 함수
    function withdrawBehalf(address account) external override onlyWhitelisted nonReentrant whenNotPaused {
        require(balances[account] > 0 && block.timestamp >= expires[account], "Locker: invalid state");
        _updateTotalScore(0, 0);

        uint256 amount = balances[account];
        totalBalance = totalBalance.sub(amount);
        delete balances[account];
        delete expires[account];
        delete _firstLockTime[account];
        GRV.safeTransfer(account, amount);

        _updateGRVDistributorBoostedInfo(account);

        emit WithdrawBehalf(msg.sender, account);
    }

    /**
     * @notice Withdraw and Lock 을 대신해주는 함수
     *  @dev Only possible if the lock has expired
     * @param expiry Lock expire time
     */
    function withdrawAndLockBehalf(
        address account,
        uint256 expiry
    ) external override onlyWhitelisted nonReentrant whenNotPaused {
        uint256 amount = balances[account];
        require(amount > 0 && block.timestamp >= expires[account], "Locker: invalid state");

        expiry = _truncateExpiry(expiry);
        require(
            block.timestamp < expiry && expiry <= _truncateExpiry(block.timestamp + LOCK_UNIT_MAX),
            "Locker: withdrawAndLockBehalf: invalid expiry"
        );

        _slopeChanges[expiry] = _slopeChanges[expiry].add(amount.div(LOCK_UNIT_MAX));
        _updateTotalScore(amount, expiry);

        expires[account] = expiry;

        _updateGRVDistributorBoostedInfo(account);
        _firstLockTime[account] = block.timestamp;

        _lockHistory[account].push(
            Constant.LockInfo({timestamp: block.timestamp, amount: balances[account], expiry: expires[account]})
        );

        emit WithdrawAndLockBehalf(msg.sender, account, expiry);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /// @notice total score update
    /// @dev 2년기준으로 deposit amount에 해당하는 unit score을 계산한뒤 선택한 expiry 기간 만큼의 score로 계산하여 total score에 추가, slop은 2년 기준으로 나눴을때 시간단위의 amount양을 나타내는것으로 보임
    /// @param newAmount GRV amount
    /// @param nextExpiry lockup period
    function _updateTotalScore(uint256 newAmount, uint256 nextExpiry) private {
        (uint256 score, uint256 slope) = totalScore();

        if (newAmount > 0) {
            uint256 slopeChange = newAmount.div(LOCK_UNIT_MAX);
            uint256 newAmountDeltaScore = nextExpiry.sub(block.timestamp).mul(slopeChange);

            slope = slope.add(slopeChange);
            score = score.add(newAmountDeltaScore);
        }

        _lastTotalScore = score;
        _lastSlope = slope;
        _lastTimestamp = block.timestamp;

        rebateDistributor.checkpoint();
    }

    function _updateTotalScoreExtendingLock(uint256 amount, uint256 prevExpiry, uint256 nextExpiry) private {
        (uint256 score, uint256 slope) = totalScore();

        uint256 deltaScore = nextExpiry.sub(prevExpiry).mul(amount.div(LOCK_UNIT_MAX));
        score = score.add(deltaScore);

        _lastTotalScore = score;
        _lastSlope = slope;
        _lastTimestamp = block.timestamp;

        rebateDistributor.checkpoint();
    }

    function _updateGRVDistributorBoostedInfo(address user) private {
        grvDistributor.updateAccountBoostedInfo(user);
    }

    function _truncateExpiry(uint256 time) private view returns (uint256) {
        if (time > block.timestamp.add(LOCK_UNIT_MAX)) {
            time = block.timestamp.add(LOCK_UNIT_MAX);
        }
        return (time.div(LOCK_UNIT_BASE).mul(LOCK_UNIT_BASE)).add(LOCK_UNIT_BASE);
    }

    function _onlyTruncateExpiry(uint256 time) private pure returns (uint256) {
        return time.div(LOCK_UNIT_BASE).mul(LOCK_UNIT_BASE);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../library/SafeToken.sol";
import "../library/Constant.sol";

import "../interfaces/IRebateDistributor.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/ICore.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IBEP20.sol";

contract RebateDistributor is IRebateDistributor, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    address internal constant ETH = 0x0000000000000000000000000000000000000000;
    uint256 public constant MAX_ADMIN_FEE_RATE = 5e17;
    uint256 public constant REBATE_CYCLE = 7 days;

    /* ========== STATE VARIABLES ========== */

    ICore public core;
    ILocker public locker;
    IPriceCalculator public priceCalc;
    Constant.RebateCheckpoint[] public rebateCheckpoints;
    uint256 public adminFeeRate;
    address public keeper;

    mapping(address => uint256) private userCheckpoint;
    mapping(address => Constant.RebateClaimInfo[]) private claimHistory;
    uint256 private adminCheckpoint;

    /* ========== VARIABLE GAP ========== */

    uint256[50] private __gap;

    /* ========== MODIFIERS ========== */

    /// @dev msg.sender 가 core address 인지 검증
    modifier onlyCore() {
        require(msg.sender == address(core), "GToken: only Core Contract");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == owner(), "RebateDistributor: caller is not the owner or keeper");
        _;
    }

    /* ========== EVENTS ========== */

    event RebateClaimed(address indexed user, address[] markets, uint256[] uAmount, uint256[] gAmount);
    event AdminFeeRateUpdated(uint256 newAdminFeeRate);
    event AdminRebateTreasuryUpdated(address newTreasury);
    event KeeperUpdated(address newKeeper);

    /* ========== SPECIAL FUNCTIONS ========== */

    receive() external payable {}

    /* ========== INITIALIZER ========== */

    function initialize(address _core, address _locker, address _priceCalc) external initializer {
        require(_core != address(0), "RebateDistributor: invalid core address");
        require(_locker != address(0), "RebateDistributor: invalid locker address");
        require(_priceCalc != address(0), "RebateDistributor: invalid priceCalc address");

        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        core = ICore(_core);
        locker = ILocker(_locker);
        priceCalc = IPriceCalculator(_priceCalc);

        adminCheckpoint = block.timestamp;
        adminFeeRate = 5e17;

        if (rebateCheckpoints.length == 0) {
            rebateCheckpoints.push(
                Constant.RebateCheckpoint({
                    timestamp: _truncateTimestamp(block.timestamp),
                    totalScore: _getTotalScoreAtTruncatedTime(),
                    adminFeeRate: adminFeeRate
                })
            );
        }

        _approveMarkets();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    /// @notice set keeper address
    /// @param _keeper new keeper address
    function setKeeper(address _keeper) external override onlyKeeper {
        require(_keeper != address(0), "RebateDistributor: invalid keeper address");
        keeper = _keeper;
        emit KeeperUpdated(_keeper);
    }

    function updateAdminFeeRate(uint256 newAdminFeeRate) external override onlyKeeper {
        require(newAdminFeeRate <= MAX_ADMIN_FEE_RATE, "RebateDisbtirubor: Invalid fee rate");
        adminFeeRate = newAdminFeeRate;
        emit AdminFeeRateUpdated(newAdminFeeRate);
    }

    function approveMarkets() external override onlyKeeper {
        _approveMarkets();
    }

    /// @notice Claim accured admin rebates
    function claimAdminRebates()
        external
        override
        nonReentrant
        onlyKeeper
        returns (uint256[] memory rebates, address[] memory markets, uint256[] memory gAmounts)
    {
        (rebates, markets) = accuredAdminRebate();
        adminCheckpoint = block.timestamp;
        gAmounts = new uint256[](markets.length);

        for (uint256 i = 0; i < markets.length; i++) {
            uint256 exchangeRate = IGToken(markets[i]).exchangeRate();
            uint256 gAmount = rebates[i].mul(1e18).div(exchangeRate);
            if (gAmount > 0) {
                address(markets[i]).safeTransfer(msg.sender, gAmount);
                gAmounts[i] = gAmounts[i].add(gAmount);
            }
        }

        emit RebateClaimed(msg.sender, markets, rebates, gAmounts);
    }

    function addRebateAmount(address gToken, uint256 uAmount) external override onlyCore {
        _addRebateAmount(gToken, uAmount);
    }

    /* ========== VIEWS ========== */

    /// @notice Accured rebate amount of account
    /// @param account account address
    function accuredRebates(
        address account
    )
        public
        view
        override
        returns (uint256[] memory rebates, address[] memory markets, uint256[] memory prices, uint256 value)
    {
        Constant.RebateCheckpoint memory lastCheckpoint = rebateCheckpoints[rebateCheckpoints.length - 1];
        markets = core.allMarkets();
        rebates = new uint256[](markets.length);
        prices = priceCalc.getUnderlyingPrices(markets);
        value = 0;

        if (locker.lockInfoOf(account).length == 0) return (rebates, markets, prices, value);

        for (
            uint256 nextTimestamp = _truncateTimestamp(
                userCheckpoint[account] != 0 ? userCheckpoint[account] : locker.lockInfoOf(account)[0].timestamp
            ).add(REBATE_CYCLE);
            nextTimestamp <= lastCheckpoint.timestamp.sub(REBATE_CYCLE);
            nextTimestamp = nextTimestamp.add(REBATE_CYCLE)
        ) {
            uint256 votingPower = _getUserVPAt(account, nextTimestamp);
            if (votingPower == 0) continue;

            Constant.RebateCheckpoint storage currentCheckpoint = rebateCheckpoints[_getCheckpointIdxAt(nextTimestamp)];

            for (uint256 i = 0; i < markets.length; i++) {
                if (currentCheckpoint.amount[markets[i]] > 0) {
                    uint256 amount = currentCheckpoint
                        .amount[markets[i]]
                        .mul(uint256(1e18).sub(currentCheckpoint.adminFeeRate).mul(votingPower))
                        .div(1e36);
                    rebates[i] = rebates[i].add(amount);
                    value = value.add(amount.mul(10 ** (18 - _getDecimals(markets[i]))).mul(prices[i]).div(1e18));
                }
            }
        }
    }

    /// @notice Accured rebate amount of admin
    function accuredAdminRebate() public view returns (uint256[] memory rebates, address[] memory markets) {
        Constant.RebateCheckpoint memory lastCheckpoint = rebateCheckpoints[rebateCheckpoints.length - 1];
        markets = core.allMarkets();
        rebates = new uint256[](markets.length);

        for (
            uint256 nextTimestamp = _truncateTimestamp(adminCheckpoint).add(REBATE_CYCLE);
            nextTimestamp <= lastCheckpoint.timestamp.sub(REBATE_CYCLE);
            nextTimestamp = nextTimestamp.add(REBATE_CYCLE)
        ) {
            uint256 checkpointIdx = _getCheckpointIdxAt(nextTimestamp);
            Constant.RebateCheckpoint storage currentCheckpoint = rebateCheckpoints[checkpointIdx];
            for (uint256 i = 0; i < markets.length; i++) {
                if (currentCheckpoint.amount[markets[i]] > 0) {
                    rebates[i] = rebates[i].add(
                        currentCheckpoint.amount[markets[i]].mul(currentCheckpoint.adminFeeRate).div(1e18)
                    );
                }
            }
        }
    }

    function thisWeekRebatePool()
        external
        view
        override
        returns (uint256[] memory rebates, address[] memory markets, uint256 value, uint256 adminRate)
    {
        markets = core.allMarkets();
        rebates = new uint256[](markets.length);
        value = 0;

        uint256[] memory prices = priceCalc.getUnderlyingPrices(markets);
        Constant.RebateCheckpoint storage lastCheckpoint = rebateCheckpoints[rebateCheckpoints.length - 1];
        adminRate = lastCheckpoint.adminFeeRate;

        for (uint256 i = 0; i < markets.length; i++) {
            if (lastCheckpoint.amount[markets[i]] > 0) {
                rebates[i] = rebates[i].add(lastCheckpoint.amount[markets[i]]);
                value = value.add(rebates[i].mul(10 ** (18 - _getDecimals(markets[i]))).mul(prices[i]).div(1e18));
            }
        }
    }

    function weeklyRebatePool() public view override returns (uint256 value, uint256 adminRate) {
        value = 0;
        adminRate = 0;

        if (rebateCheckpoints.length >= 2) {
            address[] memory markets = core.allMarkets();
            uint256[] memory prices = priceCalc.getUnderlyingPrices(markets);
            Constant.RebateCheckpoint storage checkpoint = rebateCheckpoints[rebateCheckpoints.length - 2];
            adminRate = checkpoint.adminFeeRate;

            for (uint256 i = 0; i < markets.length; i++) {
                if (checkpoint.amount[markets[i]] > 0) {
                    value = value.add(
                        checkpoint.amount[markets[i]].mul(10 ** (18 - _getDecimals(markets[i]))).mul(prices[i]).div(
                            1e18
                        )
                    );
                }
            }
        }
    }

    function weeklyProfitOfVP(uint256 vp) public view override returns (uint256 amount) {
        require(vp >= 0 && vp <= 1e18, "RebateDistributor: Invalid VP");

        (uint256 value, uint256 adminRate) = weeklyRebatePool();
        uint256 feeRate = uint256(1e18).sub(adminRate).mul(vp);
        amount = 0;

        if (value > 0) {
            amount = value.mul(feeRate).div(1e36);
        }
    }

    function weeklyProfitOf(address account) external view override returns (uint256) {
        uint256 vp = _getUserVPAt(account, block.timestamp.add(REBATE_CYCLE));
        return weeklyProfitOfVP(vp);
    }

    function totalClaimedRebates(
        address account
    ) external view override returns (uint256[] memory rebates, address[] memory markets, uint256 value) {
        markets = core.allMarkets();
        rebates = new uint256[](markets.length);
        value = 0;
        uint256 claimCount = claimHistory[account].length;

        for (uint256 i = 0; i < claimCount; i++) {
            Constant.RebateClaimInfo memory info = claimHistory[account][i];

            for (uint256 j = 0; j < markets.length; j++) {
                for (uint256 k = 0; k < info.markets.length; k++) {
                    if (markets[j] == info.markets[k]) {
                        rebates[j] = rebates[j].add(info.amount[k]);
                    }
                }
            }
            value = value.add(info.value);
        }
    }

    function indicativeYearProfit() external view override returns (uint256) {
        (uint256 totalScore, ) = locker.totalScore();
        if (totalScore == 0) {
            return 0;
        }

        uint256 preScore = locker.preScoreOf(
            address(0),
            1e18,
            uint256(block.timestamp).add(365 days),
            Constant.EcoScorePreviewOption.LOCK
        );
        uint256 weeklyProfit = weeklyProfitOfVP(preScore.mul(1e18).div(totalScore));

        return weeklyProfit.mul(52);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Add checkpoint if needed and supply supluses
    function checkpoint() external override nonReentrant {
        Constant.RebateCheckpoint memory lastRebateScore = rebateCheckpoints[rebateCheckpoints.length - 1];
        address[] memory markets = core.allMarkets();

        uint256 nextTimestamp = lastRebateScore.timestamp.add(REBATE_CYCLE);
        while (block.timestamp >= nextTimestamp) {
            (uint256 totalScore, uint256 slope) = locker.totalScore();
            uint256 newTotalScore = totalScore == 0 ? 0 : totalScore.add(slope.mul(block.timestamp.sub(nextTimestamp)));
            rebateCheckpoints.push(
                Constant.RebateCheckpoint({
                    totalScore: newTotalScore,
                    timestamp: nextTimestamp,
                    adminFeeRate: adminFeeRate
                })
            );
            nextTimestamp = nextTimestamp.add(REBATE_CYCLE);

            for (uint256 i = 0; i < markets.length; i++) {
                IGToken(markets[i]).withdrawReserves();
            }
        }
        _supplySurpluses();
    }

    /// @notice Claim accured all rebates
    function claimRebates()
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256[] memory rebates, address[] memory markets, uint256[] memory gAmounts)
    {
        uint256[] memory prices;
        uint256 value;
        (rebates, markets, prices, value) = accuredRebates(msg.sender);
        userCheckpoint[msg.sender] = block.timestamp;
        gAmounts = new uint256[](markets.length);

        for (uint256 i = 0; i < markets.length; i++) {
            uint256 exchangeRate = IGToken(markets[i]).exchangeRate();
            uint256 gAmount = rebates[i].mul(1e18).div(exchangeRate);
            if (gAmount > 0) {
                address(markets[i]).safeTransfer(msg.sender, gAmount);
                gAmounts[i] = gAmounts[i].add(gAmount);
            }
        }

        claimHistory[msg.sender].push(
            Constant.RebateClaimInfo({
                timestamp: block.timestamp,
                markets: markets,
                amount: rebates,
                prices: prices,
                value: value
            })
        );
        emit RebateClaimed(msg.sender, markets, rebates, gAmounts);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /// @dev Approve markets to supply
    function _approveMarkets() private {
        address[] memory markets = core.allMarkets();

        for (uint256 i = 0; i < markets.length; i++) {
            address underlying = IGToken(markets[i]).underlying();

            if (underlying != ETH) {
                underlying.safeApprove(markets[i], 0);
                underlying.safeApprove(markets[i], uint256(-1));
            }
        }
    }

    /// @dev Supply all having underlying tokens to markets
    function _supplySurpluses() private {
        require(rebateCheckpoints.length > 0, "RebateDistributor: invalid checkpoint");

        Constant.RebateCheckpoint storage lastCheckpoint = rebateCheckpoints[rebateCheckpoints.length - 1];
        address[] memory markets = core.allMarkets();

        for (uint256 i = 0; i < markets.length; i++) {
            address underlying = IGToken(markets[i]).underlying();
            uint256 balance = underlying == address(ETH)
                ? address(this).balance
                : IBEP20(underlying).balanceOf(address(this));

            if (underlying == ETH && balance > 0) {
                core.supply{value: balance}(markets[i], balance);
            }
            if (underlying != ETH && balance > 0) {
                core.supply(markets[i], balance);
            }
            lastCheckpoint.amount[markets[i]] = lastCheckpoint.amount[markets[i]].add(balance);
        }
    }

    function _addRebateAmount(address gToken, uint256 uAmount) private {
        Constant.RebateCheckpoint storage lastCheckpoint = rebateCheckpoints[rebateCheckpoints.length - 1];
        lastCheckpoint.amount[gToken] = lastCheckpoint.amount[gToken].add(uAmount);
    }

    /// @notice Find checkpoint index of timestamp
    /// @param timestamp checkpoint timestamp
    function _getCheckpointIdxAt(uint256 timestamp) private view returns (uint256) {
        timestamp = _truncateTimestamp(timestamp);

        for (uint256 i = rebateCheckpoints.length - 1; i < uint256(-1); i--) {
            if (rebateCheckpoints[i].timestamp == timestamp) {
                return i;
            }
        }

        revert("RebateDistributor: checkpoint index error");
    }

    /// @notice Get total score at timestamp
    /// @dev Get from
    function _getTotalScoreAt(uint256 timestamp) private view returns (uint256) {
        for (uint256 i = rebateCheckpoints.length - 1; i < uint256(-1); i--) {
            if (rebateCheckpoints[i].timestamp == timestamp) {
                return rebateCheckpoints[i].totalScore;
            }
        }

        if (rebateCheckpoints[rebateCheckpoints.length - 1].timestamp < timestamp) {
            (uint256 totalScore, uint256 slope) = locker.totalScore();

            if (totalScore == 0 || slope == 0) {
                return 0;
            } else if (block.timestamp > timestamp) {
                return totalScore.add(slope.mul(block.timestamp.sub(timestamp)));
            } else if (block.timestamp < timestamp) {
                return totalScore.sub(slope.mul(timestamp.sub(block.timestamp)));
            } else {
                return totalScore;
            }
        }

        revert("RebateDistributor: checkpoint index error");
    }

    /// @notice Get total score at truncated current time
    function _getTotalScoreAtTruncatedTime() private view returns (uint256 score) {
        (uint256 totalScore, uint256 slope) = locker.totalScore();
        uint256 lastTimestmp = _truncateTimestamp(block.timestamp);
        score = 0;

        if (totalScore > 0 && slope > 0) {
            score = totalScore.add(slope.mul(block.timestamp.sub(lastTimestmp)));
        }
    }

    /// @notice Get user voting power at timestamp
    /// @param account account address
    /// @param timestamp timestamp
    function _getUserVPAt(address account, uint256 timestamp) private view returns (uint256) {
        timestamp = _truncateTimestamp(timestamp);
        uint256 userScore = locker.scoreOfAt(account, timestamp);
        uint256 totalScore = _getTotalScoreAt(timestamp);

        return totalScore != 0 ? userScore.mul(1e18).div(totalScore).div(1e8).mul(1e8) : 0;
    }

    /// @notice Truncate timestamp to adjust to rebate checkpoint
    function _truncateTimestamp(uint256 timestamp) private pure returns (uint256) {
        return timestamp.div(REBATE_CYCLE).mul(REBATE_CYCLE);
    }

    /// @notice View underlying token decimals by gToken address
    /// @param gToken gToken address
    function _getDecimals(address gToken) private view returns (uint256 decimals) {
        address underlying = IGToken(gToken).underlying();
        if (underlying == address(0)) {
            decimals = 18;
        } else {
            decimals = IBEP20(underlying).decimals();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract LilPudgysNFT is ERC721, Ownable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC721("LilPudgys", "LP") public {
        _setupRole(MINTER_ROLE, msg.sender);
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "LilPudgys: caller is not the minter");
        _;
    }

    function mint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        return true;
    }

    function setMinterRole(address minter) external onlyOwner {
        _setupRole(MINTER_ROLE, minter);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SmolBrainNFT is ERC721, Ownable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC721("Smol Brain", "SmolBrain") public {}

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "SmolBrain: caller is not the minter");
        _;
    }

    function mint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        return true;
    }

    function setMinterRole(address minter) external onlyOwner {
        _setupRole(MINTER_ROLE, minter);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IBEP20.sol";
import "../interfaces/ILpVault.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IEcoScore.sol";

import "../library/SafeToken.sol";
import "../library/Constant.sol";

contract LpVault is ILpVault, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    uint256 public constant MAX_HARVEST_FEE = 6000; // 60%
    uint256 public constant MAX_HARVEST_FEE_PERIOD = 30 days;
    uint256 public constant MAX_LOCKUP_PERIOD = 21 days;

    /* ========== STATE VARIABLES ========== */

    address public treasury;

    uint256 public harvestFee;
    uint256 public override harvestFeePeriod;
    uint256 public override lockupPeriod;

    uint256 public accTokenPerShare;
    uint256 public bonusEndTimestamp;
    uint256 public startTimestamp;
    uint256 public lastRewardTimestamp;

    uint256 public override rewardPerInterval;

    IBEP20 public rewardToken;
    IBEP20 public stakedToken;
    ILocker public locker;
    IEcoScore public ecoScore;

    mapping(address => UserInfo) public override userInfo;

    /* ========== INITIALIZER ========== */

    function initialize(
        IBEP20 _stakedToken,
        IBEP20 _rewardToken,
        ILocker _locker,
        IEcoScore _ecoScore,
        uint256 _rewardPerInterval,
        uint256 _startTimestamp,
        uint256 _bonusEndTimestamp,
        address _treasury
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerInterval = _rewardPerInterval;
        startTimestamp = _startTimestamp;
        bonusEndTimestamp = _bonusEndTimestamp;

        // Set the lastRewardTimestamp as the startTimestamp
        lastRewardTimestamp = startTimestamp;
        treasury = _treasury;
        locker = _locker;
        ecoScore = _ecoScore;

        harvestFee = 5000; // 50%
        harvestFeePeriod = 14 days; // 14 days
        lockupPeriod = 7 days; // 7 days

        rewardToken.approve(address(locker), uint256(-1));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        address(rewardToken).safeTransfer(address(msg.sender), _amount);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        require(_tokenAddress != address(rewardToken), "Cannot be reward token");

        _tokenAddress.safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    function stopReward() external onlyOwner {
        bonusEndTimestamp = block.timestamp;
    }

    function setStartTimestamp(uint256 _startTimestamp) external onlyOwner {
        require(block.timestamp < _startTimestamp, "startTimestamp lower than current timestamp");
        startTimestamp = _startTimestamp;
        emit NewStartTimestamp(_startTimestamp);
    }

    function setBonusEndTimestamp(uint256 _bonusEndTimestamp) external onlyOwner {
        require(startTimestamp < _bonusEndTimestamp, "bonusEndTimestamp lower than start timestamp");
        bonusEndTimestamp = _bonusEndTimestamp;
        emit NewBonusEndTimestamp(_bonusEndTimestamp);
    }

    function updateRewardPerInterval(uint256 _rewardPerInterval) external onlyOwner {
        require(block.timestamp < startTimestamp, "Pool has started");
        rewardPerInterval = _rewardPerInterval;
        emit NewRewardPerInterval(_rewardPerInterval);
    }

    function setHarvestFee(uint256 _harvestFee) external onlyOwner {
        require(_harvestFee <= MAX_HARVEST_FEE, "LpVault::setHarvestFee::harvestFee cannot be mor than MAX");
        emit LogSetHarvestFee(harvestFee, _harvestFee);
        harvestFee = _harvestFee;
    }

    function setHarvestFeePeriod(uint256 _harvestFeePeriod) external onlyOwner {
        require(
            _harvestFeePeriod <= MAX_HARVEST_FEE_PERIOD,
            "LpVault::setHarvestFeePeriod::harvestFeePeriod cannot be more than MAX_HARVEST_FEE_PERIOD"
        );

        emit LogSetHarvestFeePeriod(harvestFeePeriod, _harvestFeePeriod);

        harvestFeePeriod = _harvestFeePeriod;
    }

    function setLockupPeriod(uint256 _lockupPeriod) external onlyOwner {
        require(
            _lockupPeriod <= MAX_LOCKUP_PERIOD,
            "LpVault::setLockupPeriod::lockupPeriod cannot be more than MAX_HARVEST_PERIOD"
        );
        require(
            _lockupPeriod <= harvestFeePeriod,
            "LpVault::setLockupPeriod::lockupPeriod cannot be more than harvestFeePeriod"
        );

        emit LogSetLockupPeriod(lockupPeriod, _lockupPeriod);

        lockupPeriod = _lockupPeriod;
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "LpVault::setTreasury::cannot be zero address");

        treasury = _treasury;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint256 _amount) external override nonReentrant {
        require(_amount > 0, "amount must be greater than 0");

        _updatePool();

        UserInfo storage user = userInfo[msg.sender];

        if (user.amount > 0) {
            uint256 _userAmount = _getAdjustedAmount(address(stakedToken), user.amount);
            uint256 _pending = _userAmount.mul(accTokenPerShare).div(1e18).sub(user.rewardDebt);

            if (_pending > 0) {
                user.pendingGrvAmount = user.pendingGrvAmount.add(_pending);
                user.lastClaimTime = block.timestamp;
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            address(stakedToken).safeTransferFrom(address(msg.sender), address(this), _amount);
        }

        user.rewardDebt = _getAdjustedAmount(address(stakedToken), user.amount).mul(accTokenPerShare).div(1e18);
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external override nonReentrant {
        require(_amount > 0, "amount must be greater than 0");

        _updatePool();

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        uint256 _userAmount = _getAdjustedAmount(address(stakedToken), user.amount);
        uint256 _pending = _userAmount.mul(accTokenPerShare).div(1e18).sub(user.rewardDebt);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            address(stakedToken).safeTransfer(address(msg.sender), _amount);
        }

        if (_pending > 0) {
            user.pendingGrvAmount = user.pendingGrvAmount.add(_pending);
            user.lastClaimTime = block.timestamp;
        }

        user.rewardDebt = _getAdjustedAmount(address(stakedToken), user.amount).mul(accTokenPerShare).div(1e18);
        emit Withdraw(msg.sender, _amount);
    }

    function claim() external override {
        _updatePool();

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "nothing to claim");

        uint256 _userAmount = _getAdjustedAmount(address(stakedToken), user.amount);
        uint256 pending = _userAmount.mul(accTokenPerShare).div(1e18).sub(user.rewardDebt);

        if (pending > 0) {
            user.pendingGrvAmount = user.pendingGrvAmount.add(pending);
            user.lastClaimTime = block.timestamp;
        }

        user.rewardDebt = _getAdjustedAmount(address(stakedToken), user.amount).mul(accTokenPerShare).div(1e18);
        emit Claim(msg.sender, pending);
    }

    function harvest() external override nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.pendingGrvAmount > 0, "pending grv amount is zero");
        require(block.timestamp > user.lastClaimTime.add(lockupPeriod), "not harvest period"); // 7days

        uint256 _pendingAmount = user.pendingGrvAmount;

        if (block.timestamp < user.lastClaimTime.add(harvestFeePeriod)) {
            // 14days
            uint256 currentHarvestFee = _pendingAmount.mul(harvestFee).div(10000);
            address(rewardToken).safeTransfer(treasury, currentHarvestFee);
            _pendingAmount = _pendingAmount.sub(currentHarvestFee);
        }
        address(rewardToken).safeTransfer(address(msg.sender), _pendingAmount);
        user.pendingGrvAmount = 0;

        ecoScore.updateUserClaimInfo(msg.sender, _pendingAmount);

        emit Harvest(msg.sender, _pendingAmount);
    }

    function compound() external override nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _pendingAmount = user.pendingGrvAmount;
        require(_pendingAmount > 0, "pending grv amount is zero");

        uint256 expiryOfAccount = locker.expiryOf(msg.sender);
        require(
            user.lastClaimTime.add(harvestFeePeriod) < expiryOfAccount,
            "The expiry date is less than the harvest fee period"
        );

        locker.depositBehalf(msg.sender, _pendingAmount, expiryOfAccount);
        ecoScore.updateUserCompoundInfo(msg.sender, _pendingAmount);

        user.pendingGrvAmount = 0;
        emit Compound(msg.sender, _pendingAmount);
    }

    function emergencyWithdraw() external override nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            address(stakedToken).safeTransfer(address(msg.sender), amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, amountToTransfer);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _updatePool() private {
        if (block.timestamp <= lastRewardTimestamp) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        stakedTokenSupply = _getAdjustedAmount(address(stakedToken), stakedTokenSupply);

        if (stakedTokenSupply == 0) {
            lastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 timeDiff = _getTimeDiff(lastRewardTimestamp, block.timestamp);
        uint256 rewardAmount = timeDiff.mul(rewardPerInterval);

        accTokenPerShare = accTokenPerShare.add(rewardAmount.mul(1e18).div(stakedTokenSupply));
        lastRewardTimestamp = block.timestamp;
    }

    /* ========== VIEWS ========== */

    function claimableGrvAmount(address userAddress) external view override returns (uint256) {
        UserInfo memory user = userInfo[userAddress];
        uint256 _accTokenPerShare = accTokenPerShare;
        uint256 _stakedTokenSupply = stakedToken.balanceOf(address(this));
        _stakedTokenSupply = _getAdjustedAmount(address(stakedToken), _stakedTokenSupply);

        if (block.timestamp > lastRewardTimestamp && _stakedTokenSupply != 0) {
            uint256 multiplier = _getTimeDiff(lastRewardTimestamp, block.timestamp);
            uint256 rewardAmount = multiplier.mul(rewardPerInterval);
            _accTokenPerShare = _accTokenPerShare.add(rewardAmount.mul(1e18).div(_stakedTokenSupply));
        }

        uint256 _userAmount = _getAdjustedAmount(address(stakedToken), user.amount);
        return _userAmount.mul(_accTokenPerShare).div(1e18).sub(user.rewardDebt);
    }

    function depositLpAmount(address userAddress) external view override returns (uint256) {
        UserInfo memory user = userInfo[userAddress];
        return user.amount;
    }

    function _getTimeDiff(uint256 _from, uint256 _to) private view returns (uint256) {
        if (_to <= bonusEndTimestamp) {
            return _to.sub(_from);
        } else if (_from >= bonusEndTimestamp) {
            return 0;
        } else {
            return bonusEndTimestamp.sub(_from);
        }
    }

    function _getAdjustedAmount(address _token, uint256 _amount) private view returns (uint256) {
        uint256 defaultDecimal = 18;
        uint256 tokenDecimal = IBEP20(_token).decimals();

        if(defaultDecimal == tokenDecimal) {
            return _amount;
        } else if(defaultDecimal > tokenDecimal) {
            return _amount.mul(10**(defaultDecimal.sub(tokenDecimal)));
        } else {
            return _amount.div(10**(tokenDecimal.sub(defaultDecimal)));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "../library/SafeToken.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IBEP20.sol";

contract safeSwapETH {
    /* ========== CONSTANTS ============= */

    address private constant WETH = 0x8DfbB066e2881C85749cCe3d9ea5c7F1335b46aE;

    /* ========== CONSTRUCTOR ========== */

    constructor() public {}

    receive() external payable {}

    /* ========== FUNCTIONS ========== */

    function withdraw(uint256 amount) external {
        require(IBEP20(WETH).balanceOf(msg.sender) >= amount, "Not enough Tokens!");

        IBEP20(WETH).transferFrom(msg.sender, address(this), amount);

        IWETH(WETH).withdraw(amount);

        SafeToken.safeTransferETH(msg.sender, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../library/SafeToken.sol";

import "../interfaces/IWhiteholePair.sol";
import "../interfaces/IWhiteholeRouter.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/ISafeSwapETH.sol";
import "../interfaces/IZap.sol";

contract Zap is IZap, OwnableUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    address public GRV;
    address public WETH;
    address public USDC;

    IWhiteholeRouter public ROUTER;

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private notFlip;
    mapping(address => address) private routePairAddresses;
    address[] public tokens;
    address public safeSwapETH;

    /* ========== INITIALIZER ========== */
    function initialize(address _GRV, address _WETH, address _USDC, address _ROUTER) external initializer {
        __Ownable_init();
        require(owner() != address(0), "Zap: owner must be set");

        GRV = _GRV;
        WETH = _WETH;
        USDC = _USDC;
        ROUTER = IWhiteholeRouter(_ROUTER);

        setNotFlip(GRV);
        setNotFlip(WETH);
        setNotFlip(USDC);
    }

    receive() external payable {}

    /* ========== View Functions ========== */
    function isFlip(address _address) public view returns (bool) {
        return !notFlip[_address];
    }

    function routePair(address _address) external view returns (address) {
        return routePairAddresses[_address];
    }

    /* ========== External Functions ========== */

    function zapInToken(address _from, uint256 amount, address _to) external override {
        _from.safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from);

        if (isFlip(_to)) {
            IWhiteholePair pair = IWhiteholePair(_to);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (_from == token0 || _from == token1) {
                // swap half amount for other
                address other = _from == token0 ? token1 : token0;
                _approveTokenIfNeeded(other);
                uint256 sellAmount = amount.div(2);
                uint256 otherAmount = _swap(_from, sellAmount, other, address(this));
                pair.skim(address(this));
                ROUTER.addLiquidity(
                    _from,
                    other,
                    amount.sub(sellAmount),
                    otherAmount,
                    0,
                    0,
                    msg.sender,
                    block.timestamp
                );
            } else {
                uint256 ethAmount = _from == WETH
                    ? _safeSwapToETH(amount)
                    : _swapTokenForETH(_from, amount, address(this));
                _swapETHToFlip(_to, ethAmount, msg.sender);
            }
        } else {
            _swap(_from, amount, _to, msg.sender);
        }
    }

    function zapIn(address _to) external payable override {
        _swapETHToFlip(_to, msg.value, msg.sender);
    }

    function zapOut(address _from, uint256 amount) external override {
        _from.safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from);

        if (!isFlip(_from)) {
            _swapTokenForETH(_from, amount, msg.sender);
        } else {
            IWhiteholePair pair = IWhiteholePair(_from);
            address token0 = pair.token0();
            address token1 = pair.token1();

            if (pair.balanceOf(_from) > 0) {
                pair.burn(address(this));
            }

            if (token0 == WETH || token1 == WETH) {
                ROUTER.removeLiquidityETH(
                    token0 != WETH ? token0 : token1,
                    amount,
                    0,
                    0,
                    msg.sender,
                    block.timestamp
                );
            } else {
                ROUTER.removeLiquidity(token0, token1, amount, 0, 0, msg.sender, block.timestamp);
            }
        }
    }

    /* ========== PRIVATE Functions ========== */

    function _approveTokenIfNeeded(address token) private {
        if (IBEP20(token).allowance(address(this), address(ROUTER)) == 0) {
            token.safeApprove(address(ROUTER), uint(-1));
        }
    }

    function _swapETHToFlip(address flip, uint256 amount, address receiver) private {
        if (!isFlip(flip)) {
            _swapETHForToken(flip, amount, receiver);
        } else {
            // flip
            IWhiteholePair pair = IWhiteholePair(flip);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WETH || token1 == WETH) {
                address token = token0 == WETH ? token1 : token0;
                uint256 swapValue = amount.div(2);
                uint256 tokenAmount = _swapETHForToken(token, swapValue, address(this));

                _approveTokenIfNeeded(token);
                pair.skim(address(this));
                ROUTER.addLiquidityETH{value: amount.sub(swapValue)}(
                    token,
                    tokenAmount,
                    0,
                    0,
                    receiver,
                    block.timestamp
                );
            } else {
                uint256 swapValue = amount.div(2);
                uint256 token0Amount = _swapETHForToken(token0, swapValue, address(this));
                uint256 token1Amount = _swapETHForToken(token1, amount.sub(swapValue), address(this));

                _approveTokenIfNeeded(token0);
                _approveTokenIfNeeded(token1);
                pair.skim(address(this));
                ROUTER.addLiquidity(token0, token1, token0Amount, token1Amount, 0, 0, receiver, block.timestamp);
            }
        }
    }

    function _swapETHForToken(address token, uint256 value, address receiver) private returns (uint256) {
        address[] memory path;

        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = WETH;
            path[1] = routePairAddresses[token];
            path[2] = token;
        } else {
            path = new address[](2);
            path[0] = WETH;
            path[1] = token;
        }

        uint[] memory amounts = ROUTER.swapExactETHForTokens{value: value}(0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swapTokenForETH(address token, uint256 amount, address receiver) private returns (uint256) {
        address[] memory path;
        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = token;
            path[1] = routePairAddresses[token];
            path[2] = WETH;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = WETH;
        }

        uint[] memory amounts = ROUTER.swapExactTokensForETH(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swap(address _from, uint256 amount, address _to, address receiver) private returns (uint256) {
        address intermediate = routePairAddresses[_from];
        if (intermediate == address(0)) {
            intermediate = routePairAddresses[_to];
        }

        address[] memory path;
        if (intermediate != address(0) && (_from == WETH || _to == WETH)) {
            // [WBNB, BUSD, VAI] or [VAI, BUSD, WBNB]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (intermediate != address(0) && (_from == intermediate || _to == intermediate)) {
            // [VAI, BUSD] or [BUSD, VAI]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_from] == routePairAddresses[_to]) {
            // [VAI, DAI] or [VAI, USDC]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (
            routePairAddresses[_from] != address(0) &&
            routePairAddresses[_to] != address(0) &&
            routePairAddresses[_from] != routePairAddresses[_to]
        ) {
            // routePairAddresses[xToken] = xRoute
            // [VAI, BUSD, WBNB, xRoute, xToken]
            path = new address[](5);
            path[0] = _from;
            path[1] = routePairAddresses[_from];
            path[2] = WETH;
            path[3] = routePairAddresses[_to];
            path[4] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_from] != address(0)) {
            // [VAI, BUSD, WBNB, BUNNY]
            path = new address[](4);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = WETH;
            path[3] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_to] != address(0)) {
            // [BUNNY, WBNB, BUSD, VAI]
            path = new address[](4);
            path[0] = _from;
            path[1] = WETH;
            path[2] = intermediate;
            path[3] = _to;
        } else if (_from == WETH || _to == WETH) {
            // [WBNB, BUNNY] or [BUNNY, WBNB]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            // [USDT, BUNNY] or [BUNNY, USDT]
            path = new address[](3);
            path[0] = _from;
            path[1] = WETH;
            path[2] = _to;
        }

        uint[] memory amounts = ROUTER.swapExactTokensForTokens(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _safeSwapToETH(uint256 amount) private returns (uint256) {
        require(IBEP20(WETH).balanceOf(address(this)) >= amount, "Zap: Not enough WETH balance");
        require(safeSwapETH != address(0), "Zap: safeSwapETH is not set");
        uint256 beforeETH = address(this).balance;
        ISafeSwapETH(safeSwapETH).withdraw(amount);
        return (address(this).balance).sub(beforeETH);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRoutePairAddress(address asset, address route) public onlyOwner {
        routePairAddresses[asset] = route;
    }

    function setNotFlip(address token) public onlyOwner {
        bool needPush = notFlip[token] == false;
        notFlip[token] = true;
        if (needPush) {
            tokens.push(token);
        }
    }

    function removeToken(uint256 i) external onlyOwner {
        address token = tokens[i];
        notFlip[token] = false;
        tokens[i] = tokens[tokens.length - 1];
        tokens.pop();
    }

    function sweep() external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint256 amount = IBEP20(token).balanceOf(address(this));
            if (amount > 0) {
                _swapTokenForETH(token, amount, owner());
            }
        }
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IBEP20(token).transfer(owner(), IBEP20(token).balanceOf(address(this)));
    }

    function setSafeSwapETH(address _safeSwapETH) external onlyOwner {
        require(safeSwapETH == address(0), "Zap: safeSwapETH already set!");
        safeSwapETH = _safeSwapETH;
        IBEP20(WETH).approve(_safeSwapETH, uint(-1));
    }
}