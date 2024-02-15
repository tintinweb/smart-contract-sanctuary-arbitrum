// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

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
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// -----------------------------------------------
//  Safety margins to avoid impractical values
// -----------------------------------------------
// @notice Safety time buffer to avoid expiration time too close to the opening time.
uint256 constant SAFETY_TIME_RANGE = 10 minutes;
// @notice Maximum value for referral discounts and rewards
uint256 constant SAFETY_MAX_REFERRAL_RATE = 50;
// @notice Maximum number of items per type on each purchase/join.
uint256 constant MAX_NUMBER_OF_PURCHASED_ITEMS = 200;
// @notice Maximum time the service provider has to react after campaigm reaches target, 
// otherwise the campaign can be still put into failed state, in case of unresponsive service providers.
uint256 constant MAX_UNRESPONSIVE_TIME = 30 days;

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// @dev External dependencies
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// @dev Internal dependencies
import "./ICrowdtainer.sol";
import "./Errors.sol";
import "./Constants.sol";

interface AuthorizationGateway {
    function getSignedJoinApproval(
        address crowdtainerAddress,
        address addr,
        uint256[] calldata quantities,
        bool _enableReferral,
        address _referrer
    ) external view returns (bytes memory signature);
}

/**
 * @title Crowdtainer contract
 * @author Crowdtainer.eth
 */
contract Crowdtainer is ICrowdtainer, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    // -----------------------------------------------
    //  Main project state
    // -----------------------------------------------
    CrowdtainerState public crowdtainerState;

    /// @notice Owner of this contract.
    /// @dev Has permissions to call: initialize(), join() and leave() functions. These functions are optionally
    /// @dev gated so that an owner contract can do special accounting (such as an EIP721-compliant contract as its owner).
    address public owner;

    /// @notice The entity or person responsible for the delivery of this crowdtainer project.
    /// @dev Allowed to call getPaidAndDeliver(), abortProject() and set signer address.
    address public shippingAgent;

    /// @notice Maps wallets that joined this Crowdtainer to the values they paid to join.
    mapping(address => uint256) public costForWallet;

    /// @notice Maps accounts to accumulated referral rewards.
    mapping(address => uint256) public accumulatedRewardsOf;

    /// @notice Total rewards claimable for project.
    uint256 public accumulatedRewards;

    /// @notice Maps referee to referrer.
    mapping(address => address) public referrerOfReferee;

    uint256 public referralEligibilityValue;

    /// @notice Wether an account has opted into being elibible for referral rewards.
    mapping(address => bool) public enableReferral;

    /// @notice Maps the total discount for each user.
    mapping(address => uint256) public discountForUser;

    /// @notice The total value raised/accumulated by this contract.
    uint256 public totalValueRaised;

    /// @notice Address owned by shipping agent to sign authorization transactions.
    address private signer;

    /// @notice Mapping of addresses to random nonces; Used for transaction replay protection.
    mapping(address => mapping(bytes32 => bool)) public usedNonces;

    /// @notice URL templates to the service provider's gateways that implement the CCIP-read protocol.
    string[] public urls;

    uint256 internal oneUnit; // Smallest unit based on erc20 decimals.

    // -----------------------------------------------
    //  Modifiers
    // -----------------------------------------------
    /**
     * @dev If the Crowdtainer contract has an "owner" contract (such as Vouchers721.sol), this modifier will
     * enforce that only the owner can call this function. If no owner is assigned (is address(0)), then the
     * restriction is not applied, in which case msg.sender checks are performed by the owner.
     */
    modifier onlyOwner() {
        if (owner == address(0)) {
            // This branch means this contract is being used as a stand-alone contract, not managed/owned by a EIP-721/1155 contract
            // E.g.: A Crowdtainer instance interacted directly by an EOA.
            _;
            return;
        }
        requireMsgSender(owner);
        _;
    }

    /**
     * @dev Throws if called in state other than the specified.
     */
    modifier onlyInState(CrowdtainerState requiredState) {
        requireState(requiredState);
        _;
    }

    modifier onlyActive() {
        requireActive();
        _;
    }

    // Auxiliary modifier functions, used to save deployment cost.
    function requireState(CrowdtainerState requiredState) internal view {
        if (crowdtainerState != requiredState)
            revert Errors.InvalidOperationFor({state: crowdtainerState});
        require(crowdtainerState == requiredState);
    }

    function requireMsgSender(address requiredAddress) internal view {
        if (msg.sender != requiredAddress)
            revert Errors.CallerNotAllowed({
                expected: requiredAddress,
                actual: msg.sender
            });
        require(msg.sender == requiredAddress);
    }

    function requireActive() internal view {
        if (block.timestamp < openingTime)
            revert Errors.OpeningTimeNotReachedYet(
                block.timestamp,
                openingTime
            );
        if (block.timestamp > expireTime)
            revert Errors.CrowdtainerExpired(block.timestamp, expireTime);
    }

    /// @notice Address used for signing authorizations. This allows for arbitrary
    /// off-chain mechanisms to apply law-based restrictions and/or combat bots squatting offered items.
    /// @notice If signer equals to address(0), no restriction is applied.
    function getSigner() external view returns (address) {
        return signer;
    }

    function setSigner(address _signer) external {
        requireMsgSender(shippingAgent);
        signer = _signer;
        emit SignerChanged(signer);
    }

    function setUrls(string[] memory _urls) external {
        requireMsgSender(shippingAgent);
        urls = _urls;
        emit CCIPURLChanged(urls);
    }

    // -----------------------------------------------
    //  Values set by initialize function
    // -----------------------------------------------
    /// @notice Time after which it is possible to join this Crowdtainer.
    uint256 public openingTime;
    /// @notice Time after which it is no longer possible for the service or product provider to withdraw funds.
    uint256 public expireTime;
    /// @notice Minimum amount in ERC20 units required for Crowdtainer to be considered to be successful.
    uint256 public targetMinimum;
    /// @notice Amount in ERC20 units after which no further participation is possible.
    uint256 public targetMaximum;
    /// @notice The price for each unit type.
    /// @dev The price should be given in the number of smallest unit for precision (e.g 10^18 == 1 DAI).
    uint256[] public unitPricePerType;
    /// @notice Half of the value act as a discount for a new participant using an existing referral code, and the other
    /// half is given for the participant making a referral. The former is similar to the 'cash discount device' in stamp era,
    /// while the latter is a reward for contributing to the Crowdtainer by incentivising participation from others.
    uint256 public referralRate;
    /// @notice Address of the ERC20 token used for payment.
    IERC20 public token;
    /// @notice URI string pointing to the legal terms and conditions ruling this project.
    string public legalContractURI;

    // -----------------------------------------------
    //  Events
    // -----------------------------------------------

    /// @notice Emmited when the signer changes.
    event SignerChanged(address indexed newSigner);

    /// @notice Emmited when CCIP-read URLs changes.
    event CCIPURLChanged(string[] indexed newUrls);

    /// @notice Emmited when a Crowdtainer is created.
    event CrowdtainerCreated(
        address indexed owner,
        address indexed shippingAgent
    );

    /// @notice Emmited when a Crowdtainer is initialized.
    event CrowdtainerInitialized(
        address indexed _owner,
        IERC20 _token,
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[] _unitPricePerType,
        uint256 _referralRate,
        uint256 _referralEligibilityValue,
        string _legalContractURI,
        address _signer
    );

    /// @notice Emmited when a user joins, signalling participation intent.
    event Joined(
        address indexed wallet,
        uint256[] quantities,
        address indexed referrer,
        uint256 finalCost, // @dev with discount applied
        uint256 appliedDiscount,
        bool referralEnabled
    );

    event Left(address indexed wallet, uint256 withdrawnAmount);

    event RewardsClaimed(address indexed wallet, uint256 withdrawnAmount);

    event FundsClaimed(address indexed wallet, uint256 withdrawnAmount);

    event CrowdtainerInDeliveryStage(
        address indexed shippingAgent,
        uint256 totalValueRaised
    );

    // -----------------------------------------------
    // Contract functions
    // -----------------------------------------------

    /**
     * @notice Initializes a Crowdtainer.
     * @param _owner The contract owning this Crowdtainer instance, if any (address(0x0) for no owner).
     * @param _campaignData Data defining all rules and values of this Crowdtainer instance.
     */
    function initialize(
        address _owner,
        CampaignData calldata _campaignData
    ) external initializer onlyInState(CrowdtainerState.Uninitialized) {
        owner = _owner;

        // @dev: Sanity checks
        if (address(_campaignData.token) == address(0))
            revert Errors.TokenAddressIsZero();

        if (address(_campaignData.shippingAgent) == address(0))
            revert Errors.ShippingAgentAddressIsZero();

        if (
            _campaignData.referralEligibilityValue > _campaignData.targetMinimum
        )
            revert Errors.ReferralMinimumValueTooHigh({
                received: _campaignData.referralEligibilityValue,
                maximum: _campaignData.targetMinimum
            });

        if (_campaignData.referralRate % 2 != 0)
            revert Errors.ReferralRateNotMultipleOfTwo();

        // @dev: Expiration time should not be too close to the opening time
        if (
            _campaignData.expireTime <
            _campaignData.openingTime + SAFETY_TIME_RANGE
        ) revert Errors.ClosingTimeTooEarly();

        if (_campaignData.targetMaximum == 0)
            revert Errors.InvalidMaximumTarget();

        if (_campaignData.targetMinimum == 0)
            revert Errors.InvalidMinimumTarget();

        if (_campaignData.targetMinimum > _campaignData.targetMaximum)
            revert Errors.MinimumTargetHigherThanMaximum();

        uint256 _oneUnit = 10 ** IERC20Metadata(_campaignData.token).decimals();

        for (uint256 i = 0; i < _campaignData.unitPricePerType.length; i++) {
            if (_campaignData.unitPricePerType[i] < _oneUnit) {
                revert Errors.PriceTooLow();
            }
        }

        if (_campaignData.referralRate > SAFETY_MAX_REFERRAL_RATE)
            revert Errors.InvalidReferralRate({
                received: _campaignData.referralRate,
                maximum: SAFETY_MAX_REFERRAL_RATE
            });

        shippingAgent = _campaignData.shippingAgent;
        signer = _campaignData.signer;
        openingTime = _campaignData.openingTime;
        expireTime = _campaignData.expireTime;
        targetMinimum = _campaignData.targetMinimum;
        targetMaximum = _campaignData.targetMaximum;
        unitPricePerType = _campaignData.unitPricePerType;
        referralRate = _campaignData.referralRate;
        referralEligibilityValue = _campaignData.referralEligibilityValue;
        token = IERC20(_campaignData.token);
        legalContractURI = _campaignData.legalContractURI;
        oneUnit = _oneUnit;

        crowdtainerState = CrowdtainerState.Funding;

        emit CrowdtainerInitialized(
            owner,
            token,
            openingTime,
            expireTime,
            targetMinimum,
            targetMaximum,
            unitPricePerType,
            referralRate,
            referralEligibilityValue,
            legalContractURI,
            signer
        );
    }

    function numberOfProducts() external view returns (uint256) {
        return unitPricePerType.length;
    }

    /**
     * @notice Join the Crowdtainer project.
     * @param _wallet The wallet that is joining the Crowdtainer. Must be the msg.sender if Crowdtainer owner is address(0x0).
     * @param _quantities Array with the number of units desired for each product.
     *
     * @dev This method is present to make wallet interactions more friendly, by requiring fewer parameters for projects with referral system disabled.
     * @dev Requires IERC20 permit.
     */
    function join(address _wallet, uint256[] calldata _quantities) public {
        join(_wallet, _quantities, false, address(0));
    }

    /**
     * @notice Join the Crowdtainer project with optional referral and discount.
     * @param _wallet The wallet that is joining the Crowdtainer. Must be the msg.sender if Crowdtainer owner is address(0x0).
     * @param _quantities Array with the number of units desired for each product.
     * @param _enableReferral Informs whether the user would like to be eligible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     *
     * @dev Requires IERC20 permit.
     * @dev referrer is the wallet address of a previous participant.
     * @dev if `enableReferral` is true, and the user decides to leave after the wallet has been used to claim a discount,
     *       then the full value can't be claimed if deciding to leave the project.
     * @dev A same user is not allowed to increase the order amounts (i.e., by calling join multiple times).
     *      To 'update' an order, the user must first 'leave' then join again with the new values.
     */
    function join(
        address _wallet,
        uint256[] calldata _quantities,
        bool _enableReferral,
        address _referrer
    )
        public
        onlyOwner
        onlyInState(CrowdtainerState.Funding)
        onlyActive
        nonReentrant
    {
        if (signer != address(0)) {
            // See https://eips.ethereum.org/EIPS/eip-3668
            revert Errors.OffchainLookup(
                address(this), // sender
                urls, // gateway urls
                abi.encodeWithSelector(
                    AuthorizationGateway.getSignedJoinApproval.selector,
                    address(this),
                    _wallet,
                    _quantities,
                    _enableReferral,
                    _referrer
                ), // parameters/data for the gateway (callData)
                Crowdtainer.joinWithSignature.selector, // 4-byte callback function selector
                abi.encode(_wallet, _quantities, _enableReferral, _referrer) // parameters for the contract callback function
            );
        }

        if (owner == address(0)) {
            requireMsgSender(_wallet);
        }

        _join(_wallet, _quantities, _enableReferral, _referrer);
    }

    /**
     * @notice Allows joining by means of CCIP-READ (EIP-3668).
     * @param result (uint64, bytes) of signature validity and the signature itself.
     * @param extraData ABI encoded parameters for _join() method.
     *
     * @dev Requires IRC20 permit.
     */
    function joinWithSignature(
        bytes calldata result, // off-chain signed payload
        bytes calldata extraData // retained by client, passed for verification in this function
    )
        external
        onlyOwner
        onlyInState(CrowdtainerState.Funding)
        onlyActive
        nonReentrant
    {
        require(signer != address(0));

        // decode extraData provided by client
        (
            address _wallet,
            uint256[] memory _quantities,
            bool _enableReferral,
            address _referrer
        ) = abi.decode(extraData, (address, uint256[], bool, address));

        if (_quantities.length != unitPricePerType.length) {
            revert Errors.InvalidProductNumberAndPrices();
        }

        if (owner == address(0)) {
            requireMsgSender(_wallet);
        }

        // Get signature from server response
        (
            address contractAddress,
            uint64 epochExpiration,
            bytes32 nonce,
            bytes memory signature
        ) = abi.decode(result, (address, uint64, bytes32, bytes));

        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                contractAddress,
                _wallet,
                _quantities,
                _enableReferral,
                _referrer,
                epochExpiration,
                nonce
            )
        );

        require(
            signaturePayloadValid(
                contractAddress,
                messageDigest,
                signer,
                epochExpiration,
                nonce,
                signature
            )
        );
        usedNonces[signer][nonce] = true;

        _join(_wallet, _quantities, _enableReferral, _referrer);
    }

    function signaturePayloadValid(
        address contractAddress,
        bytes32 messageDigest,
        address expectedPublicKey,
        uint64 expiration,
        bytes32 nonce,
        bytes memory signature
    ) internal view returns (bool) {
        address recoveredPublicKey = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageDigest)
        ).recover(signature);

        if (recoveredPublicKey != expectedPublicKey) {
            revert Errors.InvalidSignature();
        }
        if (contractAddress != address(this)) {
            revert Errors.InvalidSignature();
        }

        if (expiration <= block.timestamp) {
            revert Errors.SignatureExpired(uint64(block.timestamp), expiration);
        }

        if (usedNonces[expectedPublicKey][nonce]) {
            revert Errors.NonceAlreadyUsed(expectedPublicKey, nonce);
        }

        return true;
    }

    function _join(
        address _wallet,
        uint256[] memory _quantities,
        bool _enableReferral,
        address _referrer
    ) internal {
        enableReferral[_wallet] = _enableReferral;

        if (_quantities.length != unitPricePerType.length) {
            revert Errors.InvalidProductNumberAndPrices();
        }

        // @dev Check if wallet didn't already join
        if (costForWallet[_wallet] != 0) revert Errors.UserAlreadyJoined();

        // @dev Calculate cost
        uint256 finalCost;

        for (uint256 i = 0; i < _quantities.length; i++) {
            if (_quantities[i] > MAX_NUMBER_OF_PURCHASED_ITEMS)
                revert Errors.ExceededNumberOfItemsAllowed({
                    received: _quantities[i],
                    maximum: MAX_NUMBER_OF_PURCHASED_ITEMS
                });

            finalCost += unitPricePerType[i] * _quantities[i];
        }

        if (finalCost < oneUnit) {
            revert Errors.InvalidNumberOfQuantities();
        }

        if (_enableReferral && finalCost < referralEligibilityValue)
            revert Errors.MinimumPurchaseValueForReferralNotMet({
                received: finalCost,
                minimum: referralEligibilityValue
            });

        // @dev Apply discounts to `finalCost` if applicable.
        bool eligibleForDiscount;
        // @dev Verify validity of given `referrer`
        if (_referrer != address(0) && referralRate > 0) {
            // @dev Check if referrer participated
            if (costForWallet[_referrer] == 0) {
                revert Errors.ReferralInexistent();
            }

            if (!enableReferral[_referrer]) {
                revert Errors.ReferralDisabledForProvidedCode();
            }

            eligibleForDiscount = true;
        }

        uint256 discount;

        if (eligibleForDiscount) {
            // @dev Two things happens when a valid referral code is given:
            //    1 - Half of the referral rate is applied as a discount to the current order.
            //    2 - Half of the referral rate is credited to the referrer.

            // @dev Calculate the discount value
            discount = (finalCost * referralRate) / 100 / 2;

            // @dev 1- Apply discount
            finalCost -= discount;
            discountForUser[_wallet] += discount;

            // @dev 2- Apply reward for referrer
            accumulatedRewardsOf[_referrer] += discount;
            accumulatedRewards += discount;

            referrerOfReferee[_wallet] = _referrer;
        }

        costForWallet[_wallet] = finalCost;

        // increase total value accumulated by this contract
        totalValueRaised += finalCost;

        // @dev Check if the purchase order doesn't exceed the goal's `targetMaximum`.
        if (totalValueRaised > targetMaximum)
            revert Errors.PurchaseExceedsMaximumTarget({
                received: totalValueRaised,
                maximum: targetMaximum
            });

        // @dev transfer required funds into this contract
        token.safeTransferFrom(_wallet, address(this), finalCost);

        emit Joined(
            _wallet,
            _quantities,
            _referrer,
            finalCost,
            discount,
            _enableReferral
        );
    }

    /**
     * @notice Leave the Crowdtainer and withdraw deposited funds given when joining.
     * @notice Calling this method signals that the participant is no longer interested in the project.
     * @param _wallet The wallet that is leaving the Crowdtainer.
     * @dev Only allowed if the respective Crowdtainer is in active `Funding` state.
     */
    function leave(
        address _wallet
    )
        external
        onlyOwner
        onlyInState(CrowdtainerState.Funding)
        onlyActive
        nonReentrant
    {
        if (owner == address(0)) {
            requireMsgSender(_wallet);
        }

        uint256 withdrawalTotal = costForWallet[_wallet];

        // @dev Subtract formerly given referral rewards originating from this account.
        address referrer = referrerOfReferee[_wallet];
        if (referrer != address(0)) {
            accumulatedRewardsOf[referrer] -= discountForUser[_wallet];
        }

        /* @dev If this wallet's referral was used, then it is no longer possible to leave().
         *      This is to discourage users from joining just to generate discount codes.
         *      E.g.: A user uses two different wallets, the first joins to generate a discount code for him/herself to be used in
         *      the second wallet, and then immediatelly leaves the pool from the first wallet, leaving the second wallet with a full discount. */
        if (accumulatedRewardsOf[_wallet] > 0) {
            revert Errors.CannotLeaveDueAccumulatedReferralCredits();
        }

        totalValueRaised -= costForWallet[_wallet];
        accumulatedRewards -= discountForUser[_wallet];

        costForWallet[_wallet] = 0;
        discountForUser[_wallet] = 0;
        referrerOfReferee[_wallet] = address(0);
        enableReferral[_wallet] = false;

        // @dev transfer the owed funds from this contract back to the user.
        token.safeTransfer(_wallet, withdrawalTotal);

        emit Left(_wallet, withdrawalTotal);
    }

    /**
     * @notice Function used by the service provider to signal commitment to ship service or product by withdrawing/receiving the payment.
     */
    function getPaidAndDeliver()
        public
        onlyInState(CrowdtainerState.Funding)
        nonReentrant
    {
        requireMsgSender(shippingAgent);
        uint256 availableForAgent = totalValueRaised - accumulatedRewards;

        if (totalValueRaised < targetMinimum) {
            revert Errors.MinimumTargetNotReached(
                targetMinimum,
                totalValueRaised
            );
        }

        crowdtainerState = CrowdtainerState.Delivery;

        // @dev transfer the owed funds from this contract to the service provider.
        token.safeTransfer(shippingAgent, availableForAgent);

        emit CrowdtainerInDeliveryStage(shippingAgent, availableForAgent);
    }

    /**
     * @notice Function used by project deployer to signal that it is no longer possible to the ship service or product.
     *         This puts the project into `Failed` state and participants can withdraw their funds.
     */
    function abortProject()
        public
        onlyInState(CrowdtainerState.Funding)
        nonReentrant
    {
        requireMsgSender(shippingAgent);
        crowdtainerState = CrowdtainerState.Failed;
    }

    /**
     * @notice Function used by participants to withdraw funds from a failed/expired project.
     */
    function claimFunds() public {
        claimFunds(msg.sender);
    }

    /**
     * @notice Function to withdraw funds from a failed/expired project back to the participant, with sponsored transaction.
     */
    function claimFunds(address wallet) public nonReentrant {
        uint256 withdrawalTotal = costForWallet[wallet];

        if (withdrawalTotal == 0) {
            revert Errors.InsufficientBalance();
        }

        if (block.timestamp < openingTime)
            revert Errors.OpeningTimeNotReachedYet(
                block.timestamp,
                openingTime
            );

        if (crowdtainerState == CrowdtainerState.Uninitialized)
            revert Errors.InvalidOperationFor({state: crowdtainerState});

        if (crowdtainerState == CrowdtainerState.Delivery)
            revert Errors.InvalidOperationFor({state: crowdtainerState});

        // The first interaction with this function 'nudges' the state to `Failed` if
        // the project didn't reach the goal in time, or if service provider is unresponsive.
        if (block.timestamp > expireTime && totalValueRaised < targetMinimum) {
            crowdtainerState = CrowdtainerState.Failed;
        } else if (block.timestamp > expireTime + MAX_UNRESPONSIVE_TIME) {
            crowdtainerState = CrowdtainerState.Failed;
        }

        if (crowdtainerState != CrowdtainerState.Failed)
            revert Errors.CantClaimFundsOnActiveProject();

        // Reaching this line means the project failed either due expiration or explicit transition from `abortProject()`.

        costForWallet[wallet] = 0;
        discountForUser[wallet] = 0;
        referrerOfReferee[wallet] = address(0);

        // @dev transfer the owed funds from this contract back to the user.
        token.safeTransfer(wallet, withdrawalTotal);

        emit FundsClaimed(wallet, withdrawalTotal);
    }

    /**
     * @notice Function used by participants to withdraw referral rewards from a successful project.
     */
    function claimRewards() public {
        claimRewards(msg.sender);
    }

    /**
     * @notice Function to withdraw referral rewards from a successful project, with sponsored transaction.
     */
    function claimRewards(
        address _wallet
    ) public nonReentrant onlyInState(CrowdtainerState.Delivery) {
        uint256 totalRewards = accumulatedRewardsOf[_wallet];
        accumulatedRewardsOf[_wallet] = 0;

        token.safeTransfer(_wallet, totalRewards);

        emit RewardsClaimed(_wallet, totalRewards);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./States.sol";

library Errors {
    // -----------------------------------------------
    //  Vouchers
    // -----------------------------------------------
    // @notice: The provided crowdtainer does not exist.
    error CrowdtainerInexistent();
    // @notice: Invalid token id.
    error InvalidTokenId(uint256 tokenId);
    // @notice: Prices lower than 1 * 1^6 not supported.
    error PriceTooLow();
    // @notice: Attempted to join with all product quantities set to zero.
    error InvalidNumberOfQuantities();
    // @notice: Account cannot be of address(0).
    error AccountAddressIsZero();
    // @notice: Metadata service contract cannot be of address(0).
    error MetadataServiceAddressIsZero();
    // @notice: Accounts and ids lengths do not match.
    error AccountIdsLengthMismatch();
    // @notice: ID's and amounts lengths do not match.
    error IDsAmountsLengthMismatch();
    // @notice: Cannot set approval for the same account.
    error CannotSetApprovalForSelf();
    // @notice: Caller is not owner or has correct permission.
    error AccountNotOwner();
    // @notice: Only the shipping agent is able to set a voucher/tokenId as "claimed".
    error SetClaimedOnlyAllowedByShippingAgent();
    // @notice: Cannot transfer someone else's tokens.
    error UnauthorizedTransfer();
    // @notice: Insufficient balance.
    error InsufficientBalance();
    // @notice: Quantities input length doesn't match number of available products.
    error InvalidProductNumberAndPrices();
    // @notice: Can't make transfers in given state.
    error TransferNotAllowed(address crowdtainer, CrowdtainerState state);
    // @notice: No further participants possible in a given Crowdtainer.
    error MaximumNumberOfParticipantsReached(
        uint256 maximum,
        address crowdtainer
    );
    // Used to apply off-chain verifications/rules per CCIP-read (EIP-3668),
    // see https://eips.ethereum.org/EIPS/eip-3668 for description.
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    error CCIP_Read_InvalidOperation();
    error SignatureExpired(uint64 current, uint64 expires);
    error NonceAlreadyUsed(address wallet, bytes32 nonce);
    error InvalidSignature();
    // Errors that occur inside external function calls, provided without decoding.
    error CrowdtainerLowLevelError(bytes reason);

    // -----------------------------------------------
    //  Initialization with invalid parameters
    // -----------------------------------------------
    // @notice: Contract initialized without owner address can't be set to having one.
    error OwnerAddressIsZero();
    // @notice: Cannot initialize with token of address(0).
    error TokenAddressIsZero();
    // @notice: Shipping agent can't have address(0).
    error ShippingAgentAddressIsZero();
    // @notice: Initialize called with closing time is less than one hour away from the opening time.
    error ClosingTimeTooEarly();
    // @notice: Initialize called with invalid number of maximum units to be sold (0).
    error InvalidMaximumTarget();
    // @notice: Initialize called with invalid number of minimum units to be sold (less than maximum sold units).
    error InvalidMinimumTarget();
    // @notice: Initialize called with invalid minimum and maximum targets (minimum value higher than maximum).
    error MinimumTargetHigherThanMaximum();
    // @notice: Initialize called with invalid referral rate.
    error InvalidReferralRate(uint256 received, uint256 maximum);
    // @notice: Referral rate not multiple of 2.
    error ReferralRateNotMultipleOfTwo();
    // @notice: Refferal minimum value for participation can't be higher than project's minimum target.
    error ReferralMinimumValueTooHigh(uint256 received, uint256 maximum);

    // -----------------------------------------------
    //  Authorization
    // -----------------------------------------------
    // @notice: Method not authorized for caller (message sender).
    error CallerNotAllowed(address expected, address actual);

    // -----------------------------------------------
    //  Join() operation
    // -----------------------------------------------
    // @notice: The given referral was not found thus can't be used to claim a discount.
    error ReferralInexistent();
    // @notice: Purchase exceed target's maximum goal.
    error PurchaseExceedsMaximumTarget(uint256 received, uint256 maximum);
    // @notice: Number of items purchased per type exceeds maximum allowed.
    error ExceededNumberOfItemsAllowed(uint256 received, uint256 maximum);
    // @notice: Wallet already used to join project.
    error UserAlreadyJoined();
    // @notice: Referral is not enabled for the given code/wallet.
    error ReferralDisabledForProvidedCode();
    // @notice: Participant can't participate in referral if the minimum purchase value specified by the service provider is not met.
    error MinimumPurchaseValueForReferralNotMet(
        uint256 received,
        uint256 minimum
    );

    // -----------------------------------------------
    //  Leave() operation
    // -----------------------------------------------
    // @notice: It is not possible to leave when the user has referrals enabled, has been referred and gained rewards.
    error CannotLeaveDueAccumulatedReferralCredits();

    // -----------------------------------------------
    //  GetPaidAndDeliver() operation
    // -----------------------------------------------
    // @notice: GetPaidAndDeliver can't be called on a expired project.
    error CrowdtainerExpired(uint256 timestamp, uint256 expiredTime);
    // @notice: Not enough funds were raised.
    error MinimumTargetNotReached(uint256 minimum, uint256 actual);
    // @notice: The project is not active yet.
    error OpeningTimeNotReachedYet(uint256 timestamp, uint256 openingTime);

    // -----------------------------------------------
    //  ClaimFunds() operation
    // -----------------------------------------------
    // @notice: Can't be called if the project is still active.
    error CantClaimFundsOnActiveProject();

    // -----------------------------------------------
    //  State transition
    // -----------------------------------------------
    // @notice: Method can't be invoked at current state.
    error InvalidOperationFor(CrowdtainerState state);

    // -----------------------------------------------
    //  Other Invariants
    // -----------------------------------------------
    // @notice: Payable receive function called, but we don't accept Eth for payment.
    error ContractDoesNotAcceptEther();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./Constants.sol";
import "./States.sol";

// @notice:  Data defining all rules and values of a Crowdtainer instance.
struct CampaignData {
    // Ethereum Address that represents the product or service provider.
    address shippingAgent;
    // Address used for signing authorizations.
    address signer;
    // Funding opening time.
    uint256 openingTime;
    // Time after which the owner can no longer withdraw funds.
    uint256 expireTime;
    // Amount in ERC20 units required for project to be considered to be successful.
    uint256 targetMinimum;
    // Amount in ERC20 units after which no further participation is possible.
    uint256 targetMaximum;
    // Array with price of each item, in ERC2O units. Zero is an invalid value and will throw.
    uint256[] unitPricePerType;
    // Percentage used for incentivising participation. Half the amount goes to the referee, and the other half to the referrer.
    uint256 referralRate;
    // The minimum purchase value required to be eligible to participate in referral rewards.
    uint256 referralEligibilityValue;
    // Address of the ERC20 token used for payment.
    address token;
    // URI string pointing to the legal terms and conditions ruling this project.
    string legalContractURI;
}

// @notice: EIP-712 / ERC-2612 permit data structure.
struct SignedPermit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @dev Interface for Crowdtainer instances.
 */
interface ICrowdtainer {
    /**
     * @dev Initializes a Crowdtainer.
     * @param _owner The contract owning this Crowdtainer instance, if any (address(0x0) for no owner).
     * @param _campaignData Data defining all rules and values of this Crowdtainer instance.
     */
    function initialize(
        address _owner,
        CampaignData calldata _campaignData
    ) external;

    function crowdtainerState() external view returns (CrowdtainerState);

    function shippingAgent() external view returns (address);

    function numberOfProducts() external view returns (uint256);

    function unitPricePerType(uint256) external view returns (uint256);

    /**
     * @notice Join the Crowdtainer project.
     * @param _wallet The wallet that is joining the Crowdtainer. Must be the msg.sender if Crowdtainer owner is address(0x0).
     * @param _quantities Array with the number of units desired for each product.
     *
     * @dev This method is present to make wallet interactions more friendly, by requiring fewer parameters for projects with referral system disabled.
     * @dev Requires IERC20 permit.
     */
    function join(address _wallet, uint256[] calldata _quantities) external;

    /**
     * @notice Join the Crowdtainer project with optional referral and discount.
     * @param _wallet The wallet that is joining the Crowdtainer. Must be the msg.sender if Crowdtainer owner is address(0x0).
     * @param _quantities Array with the number of units desired for each product.
     * @param _enableReferral Informs whether the user would like to be eligible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     *
     * @dev Requires IERC20 permit.
     * @dev referrer is the wallet address of a previous participant.
     * @dev if `enableReferral` is true, and the user decides to leave after the wallet has been used to claim a discount,
     *       then the full value can't be claimed if deciding to leave the project.
     * @dev A same user is not allowed to increase the order amounts (i.e., by calling join multiple times).
     *      To 'update' an order, the user must first 'leave' then join again with the new values.
     */
    function join(
        address _wallet,
        uint256[] calldata _quantities,
        bool _enableReferral,
        address _referrer
    ) external;

    /*
     * @dev Leave the Crowdtainer and withdraw deposited funds given when joining.
     * @note Calling this method signals that the user is no longer interested in participating.
     * @note Only allowed if the respective Crowdtainer is in active `Funding` state.
     * @param _wallet The wallet that is leaving the Crowdtainer.
     */
    function leave(address _wallet) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

struct Metadata {
    uint256 crowdtainerId;
    uint256 tokenId;
    address currentOwner;
    bool claimed;
    uint256[] unitPricePerType;
    uint256[] quantities;
    string[] productDescription;
    uint256 numberOfProducts;
}

/**
 * @dev Metadata service used to provide URI for a voucher / token id.
 */
interface IMetadataService {
    function uri(Metadata memory) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

enum CrowdtainerState {
    Uninitialized,
    Funding,
    Delivery,
    Failed
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// @dev External dependencies
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

// @dev Internal dependencies
import "./ICrowdtainer.sol";
import "./Crowdtainer.sol";
import "./Errors.sol";
import "./Constants.sol";
import "./Metadata/IMetadataService.sol";

/**
 * @title Crowdtainer's project manager contract.
 * @author Crowdtainer.eth
 * @notice Manages Crowdtainer projects and ownership of its product/services by participants.
 * @dev Essentially, a Crowdtainer factory with ERC-721 compliance.
 * @dev Each token id represents a "sold voucher", a set of one or more products or services of a specific Crowdtainer.
 */
contract Vouchers721 is ERC721Enumerable {
    // @dev Each Crowdtainer project is alloacted a range.
    // @dev This is used as a multiple to deduce the crowdtainer id from a given token id.
    uint256 public constant ID_MULTIPLE = 1000000;

    // @dev Claimed status of a specific token id
    BitMaps.BitMap private claimed;

    // @dev The next available tokenId for the given crowdtainerId.
    mapping(uint256 => uint256) private nextTokenIdForCrowdtainer;

    /// @notice Owner of this contract deployment.
    /// @dev Has permission to call createCrowdtainer() function. This function is optionally
    /// @dev gated so that unrelated entities can't maliciously associate themselves with the deployer
    /// @dev of this contract, but is instead required to deploy a new contract.
    address public owner;

    // @dev Number of created crowdtainers.
    uint256 public crowdtainerCount;

    address private immutable crowdtainerImplementation;

    // @dev Mapping of id to Crowdtainer contract address.
    mapping(uint256 => address) public crowdtainerForId;
    // @dev Mapping of deployed Crowdtainer contract addresses to its token id.
    mapping(address => uint256) public idForCrowdtainer;

    // @dev Mapping of base token ID to metadata service, used as return value for URI method.
    mapping(uint256 => address) public metadataServiceForCrowdatinerId;

    // @dev Mapping of token ID => product quantities.
    mapping(uint256 => uint256[]) public tokenIdQuantities;

    // @dev Mapping of crowdtainer id => array of product descriptions.
    mapping(uint256 => string[]) public productDescription;

    // -----------------------------------------------
    //  Modifiers
    // -----------------------------------------------
    /**
     * @dev If the contract has an "owner" specified, this modifier will
     * enforce that only the owner can call the function. If no owner is assigned (is address(0)), then the
     * restriction is not applied.
     */
    modifier onlyOwner() {
        if (owner == address(0)) {
            // No restrictions.
            _;
            return;
        }
        if (msg.sender != owner)
            revert Errors.CallerNotAllowed({
                expected: owner,
                actual: msg.sender
            });
        require(msg.sender == owner);
        _;
    }

    // -----------------------------------------------
    //  Events
    // -----------------------------------------------

    // @note Emmited when this contract is created.
    event Vouchers721Created(
        address indexed crowdtainer,
        address indexed owner
    );

    // @note Emmited when a new Crowdtainer is deployed and initialized by this contract.
    event CrowdtainerDeployed(
        address indexed _crowdtainerAddress,
        uint256 _nextCrowdtainerId
    );

    /// @notice Emmited when the owner changes.
    event OwnerChanged(address indexed newOwner);

    function requireMsgSender(address requiredAddress) internal view {
        if (msg.sender != requiredAddress)
            revert Errors.CallerNotAllowed({
                expected: requiredAddress,
                actual: msg.sender
            });
        require(msg.sender == requiredAddress);
    }

    // -----------------------------------------------
    //  Contract functions
    // -----------------------------------------------

    /**
     * @notice Create and deploy a new Crowdtainer manager.
     * @dev Uses contract factory pattern.
     * @param _crowdtainerImplementation the address of the reference implementation.
     * @param _owner Optional. If not address(0), it will be the only address allowed to create new crowdtainer projects from this manager contract.
     */
    constructor(
        address _crowdtainerImplementation,
        address _owner
    ) ERC721("Vouchers721", "VV1") {
        // equivalent to: crowdtainerImplementation = address(new Crowdtainer(address(this)));.
        crowdtainerImplementation = _crowdtainerImplementation;
        owner = _owner;
        emit Vouchers721Created(address(this), owner);
    }

    /**
     * @notice Set a new address to be allowed to deploy new campaigns from this manager contract.
     * @notice Only possible if this contract was deployed with a owner other than address(0).
     */
    function setOwner(address _owner) external onlyOwner {
        if (owner == address(0)) {
            revert Errors.OwnerAddressIsZero();
        }
        owner = _owner;
        emit OwnerChanged(owner);
    }

    /**
     * @notice Create and deploy a new Crowdtainer.
     * @param _campaignData Data defining all rules and values of this Crowdtainer instance.
     * @param _productDescription An array with the description of each item.
     * @param _metadataService Contract address used to fetch metadata about the token.
     * @return crowdtainerId The contract address and id for the created Crowdtainer.
     */
    function createCrowdtainer(
        CampaignData calldata _campaignData,
        string[] memory _productDescription,
        address _metadataService
    ) external onlyOwner returns (address, uint256) {
        if (_metadataService == address(0)) {
            revert Errors.MetadataServiceAddressIsZero();
        }

        // Equivalent to: ICrowdtainer crowdtainer = ICrowdtainer(new Crowdtainer());
        ICrowdtainer crowdtainer = ICrowdtainer(
            Clones.clone(crowdtainerImplementation)
        );

        try crowdtainer.initialize(address(this), _campaignData) {
            idForCrowdtainer[address(crowdtainer)] = ++crowdtainerCount;
            crowdtainerForId[crowdtainerCount] = address(crowdtainer);

            productDescription[crowdtainerCount] = _productDescription;
            metadataServiceForCrowdatinerId[
                crowdtainerCount
            ] = _metadataService;
            emit CrowdtainerDeployed(address(crowdtainer), crowdtainerCount);

            return (address(crowdtainer), crowdtainerCount);
        } catch (bytes memory receivedBytes) {
            _bubbleRevert(receivedBytes);
        }
    }

    /**
     * @notice Join the specified Crowdtainer project.
     * @param _crowdtainer Crowdtainer project address.
     * @param _quantities Array with the number of units desired for each product.
     *
     * @dev This method is present to make wallet UX more friendly, by requiring fewer parameters (for projects with referral system disabled).
     * @dev Requires IERC20 permit.
     */
    function join(
        address _crowdtainer,
        uint256[] calldata _quantities
    ) public returns (uint256) {
        return join(_crowdtainer, _quantities, false, address(0));
    }

    /**
     * @notice Join the specified Crowdtainer project with optional referral and discount.
     * @param _crowdtainer Crowdtainer project address.
     * @param _quantities Array with the number of units desired for each product.
     * @param _enableReferral Informs whether the user would like to be eligible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     * @return The token id that represents the created voucher / ownership.
     *
     * @dev Requires IERC20 permit.
     * @dev referrer is the wallet address of a previous participant.
     * @dev if `enableReferral` is true, and the user decides to leave after the wallet has been used to claim a discount,
     *       then the full value can't be claimed if deciding to leave the project.
     * @dev A same user is not allowed to increase the order amounts (i.e., by calling join multiple times).
     *      To 'update' an order, the user must first 'leave' then join again with the new values.
     */
    function join(
        address _crowdtainer,
        uint256[] calldata _quantities,
        bool _enableReferral,
        address _referrer
    ) public returns (uint256) {
        uint256 crowdtainerId = idForCrowdtainer[_crowdtainer];

        if (crowdtainerId == 0) {
            revert Errors.CrowdtainerInexistent();
        }

        ICrowdtainer crowdtainer = ICrowdtainer(_crowdtainer);

        try
            crowdtainer.join(
                msg.sender,
                _quantities,
                _enableReferral,
                _referrer
            )
        /* solhint-disable-next-line no-empty-blocks */
        {

        } catch (bytes memory receivedBytes) {
            handleJoinError(_crowdtainer, receivedBytes);
        }

        uint256 nextAvailableTokenId = ++nextTokenIdForCrowdtainer[
            crowdtainerId
        ];

        if (nextAvailableTokenId >= ID_MULTIPLE) {
            revert Errors.MaximumNumberOfParticipantsReached(
                ID_MULTIPLE,
                _crowdtainer
            );
        }

        uint256 newTokenID = (ID_MULTIPLE * crowdtainerId) +
            nextAvailableTokenId;

        tokenIdQuantities[newTokenID] = _quantities;

        // Mint the voucher to the respective owner
        _safeMint(msg.sender, newTokenID);

        return newTokenID;
    }

    /**
     * @notice Join the specified Crowdtainer project with optional referral and discount, along with an ERC-2612 Permit.
     * @param _crowdtainer Crowdtainer project address.
     * @param _quantities Array with the number of units desired for each product.
     * @param _enableReferral Informs whether the user would like to be eligible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     * @param _signedPermit The ERC-2612 signed permit data.
     * @return The token id that represents the created voucher / ownership.
     *
     * @dev referrer is the wallet address of a previous participant.
     * @dev if `enableReferral` is true, and the user decides to leave after the wallet has been used to claim a discount,
     *       then the full value can't be claimed if deciding to leave the project.
     * @dev A same user is not allowed to increase the order amounts (i.e., by calling join multiple times).
     *      To 'update' an order, the user must first 'leave' then join again with the new values.
     */
    function join(
        address _crowdtainer,
        uint256[] calldata _quantities,
        bool _enableReferral,
        address _referrer,
        SignedPermit memory _signedPermit
    ) public returns (uint256) {
        IERC20Permit erc20token = IERC20Permit(
            address(Crowdtainer(_crowdtainer).token())
        );

        try
            erc20token.permit(
                _signedPermit.owner,
                _crowdtainer,
                _signedPermit.value,
                _signedPermit.deadline,
                _signedPermit.v,
                _signedPermit.r,
                _signedPermit.s
            )
        {
            return join(_crowdtainer, _quantities, _enableReferral, _referrer);
        } catch (bytes memory receivedBytes) {
            _bubbleRevert(receivedBytes);
        }
    }

    // @dev Function that calls a contract, and makes sure any revert 'bubbles up' and halts execution.
    // This function is used because there is no Solidity syntax to 'rethrow' custom errors within a try/catch,
    // other than comparing each error manually (which would unnecessarily increase code size / deployment costs).
    function _bubbleRevert(
        bytes memory receivedBytes
    ) internal pure returns (bytes memory) {
        if (receivedBytes.length == 0) revert();
        assembly {
            revert(add(32, receivedBytes), mload(receivedBytes))
        }
    }

    // @dev Extract abi encoded selector bytes
    function getSignature(bytes calldata data) external pure returns (bytes4) {
        assert(data.length >= 4);
        return bytes4(data[:4]);
    }

    // @dev Extract abi encoded parameters
    function getParameters(
        bytes calldata data
    ) external pure returns (bytes calldata) {
        assert(data.length > 4);
        return data[4:];
    }

    // @dev Decodes external Crowdtainer join function call errors.
    function handleJoinError(
        address crowdtainer,
        bytes memory receivedBytes
    ) private view {
        if (
            receivedBytes.length >= 4 &&
            this.getSignature(receivedBytes) == Errors.OffchainLookup.selector
        ) {
            // EIP-3668 OffchainLookup revert requires processing as below.
            // Namely, the 'sender' must be address(this), and not the inner contract address.
            (
                address sender,
                string[] memory urls,
                bytes memory callData,
                bytes4 callbackFunction,
                bytes memory extraData
            ) = abi.decode(
                    this.getParameters(receivedBytes),
                    (address, string[], bytes, bytes4, bytes)
                );

            if (sender != address(crowdtainer)) {
                revert Errors.CCIP_Read_InvalidOperation();
            }

            revert Errors.OffchainLookup(
                address(this),
                urls,
                callData,
                this.joinWithSignature.selector,
                abi.encode(address(crowdtainer), callbackFunction, extraData)
            );
        }
        // All other Crowdtainer.sol's errors can be propagated for decoding in external tooling.
        _bubbleRevert(receivedBytes);
    }

    /**
     * @notice Allows joining by means of CCIP-READ (EIP-3668).
     * @param result ABI encoded (uint64, bytes) for signature time validity and the signature itself.
     * @param extraData ABI encoded (address, bytes4, bytes), 3rd parameter contains encoded values for Crowdtainer._join() method.
     *
     * @dev Requires IRC20 permit.
     * @dev This function is called automatically by EIP-3668-compliant clients.
     */
    function joinWithSignature(
        bytes calldata result, // off-chain signed payload
        bytes calldata extraData // retained by client, passed for verification in this function
    ) public returns (uint256) {
        (
            address crowdtainer, // Address of Crowdtainer contract
            bytes4 innerCallbackFunction,
            bytes memory innerExtraData
        ) = abi.decode(extraData, (address, bytes4, bytes));

        require(
            innerCallbackFunction == Crowdtainer.joinWithSignature.selector
        );

        (address _wallet, uint256[] memory _quantities, , ) = abi.decode(
            innerExtraData,
            (address, uint256[], bool, address)
        );

        require(crowdtainer != address(0));
        uint256 crowdtainerId = idForCrowdtainer[crowdtainer];

        if (crowdtainerId == 0) {
            revert Errors.CrowdtainerInexistent();
        }

        require(crowdtainer.code.length > 0);

        uint256 costForWallet = Crowdtainer(crowdtainer).costForWallet(_wallet);

        try Crowdtainer(crowdtainer).joinWithSignature(result, innerExtraData) {
            // internal state invariant after joining
            assert(
                Crowdtainer(crowdtainer).costForWallet(_wallet) > costForWallet
            );
        } catch (bytes memory receivedBytes) {
            handleJoinError(crowdtainer, receivedBytes);
        }

        uint256 nextAvailableTokenId = ++nextTokenIdForCrowdtainer[
            crowdtainerId
        ];

        if (nextAvailableTokenId >= ID_MULTIPLE) {
            revert Errors.MaximumNumberOfParticipantsReached(
                ID_MULTIPLE,
                crowdtainer
            );
        }

        uint256 newTokenID = (ID_MULTIPLE * crowdtainerId) +
            nextAvailableTokenId;

        tokenIdQuantities[newTokenID] = _quantities;

        // Mint the voucher to the respective owner
        _safeMint(_wallet, newTokenID);

        return newTokenID;
    }

    /**
     * @notice Set ERC20's allowance using Permit, and call joinWithSignature(..), in a single call.
     * @param result ABI encoded (uint64, bytes) for signature time validity and the signature itself.
     * @param extraData ABI encoded (address, bytes4, bytes), 3rd parameter contains encoded values for Crowdtainer._join() method.
     * @param _signedPermit The ERC-2612 signed permit data.
     *
     * @dev This convenience function is *not* EIP-3668-compliant: the frontend needs to be aware of it to take advantage.
     */
    function joinWithSignatureAndPermit(
        bytes calldata result, // off-chain signed payload
        bytes calldata extraData, // retained by client, passed for verification in this function
        SignedPermit memory _signedPermit // Params to be forwarded to ERC-20 contract.
    ) external returns (uint256) {
        (address crowdtainer, , ) = abi.decode(
            extraData,
            (address, bytes4, bytes)
        );

        IERC20Permit erc20token = IERC20Permit(
            address(Crowdtainer(crowdtainer).token())
        );

        try
            erc20token.permit(
                _signedPermit.owner,
                crowdtainer,
                _signedPermit.value,
                _signedPermit.deadline,
                _signedPermit.v,
                _signedPermit.r,
                _signedPermit.s
            )
        {
            return joinWithSignature(result, extraData);
        } catch (bytes memory receivedBytes) {
            _bubbleRevert(receivedBytes);
        }
    }

    /**
     * @notice Returns the specified voucher and withdraw all deposited funds given when joining the Crowdtainer.
     * @notice Calling this method signals that the participant is no longer interested in the project.
     * @dev Only allowed if the respective Crowdtainer is in active funding state.
     */
    function leave(uint256 _tokenId) external {
        if (ownerOf(_tokenId) != msg.sender) {
            revert Errors.AccountNotOwner();
        }

        address crowdtainerAddress = crowdtainerIdToAddress(
            tokenIdToCrowdtainerId(_tokenId)
        );

        try ICrowdtainer(crowdtainerAddress).leave(msg.sender) {
            // internal state invariant after leaving
            assert(
                Crowdtainer(crowdtainerAddress).costForWallet(msg.sender) == 0
            );

            delete tokenIdQuantities[_tokenId];

            _burn(_tokenId);
        } catch (bytes memory receivedBytes) {
            _bubbleRevert(receivedBytes);
        }
    }

    /**
     * @notice Get the metadata representation.
     * @param _tokenId The encoded voucher token id.
     * @return Token URI String.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        uint256 crowdtainerId = tokenIdToCrowdtainerId(_tokenId);
        address crowdtainerAddress = crowdtainerIdToAddress(crowdtainerId);

        ICrowdtainer crowdtainer = ICrowdtainer(crowdtainerAddress);

        uint256 numberOfProducts = crowdtainer.numberOfProducts();
        uint256[] memory unitPricePerType = new uint256[](numberOfProducts);

        for (uint256 i = 0; i < numberOfProducts; i++) {
            unitPricePerType[i] = crowdtainer.unitPricePerType(i);
        }

        IMetadataService metadataService = IMetadataService(
            metadataServiceForCrowdatinerId[crowdtainerId]
        );

        Metadata memory metadata = Metadata(
            crowdtainerId,
            _tokenId - (tokenIdToCrowdtainerId(_tokenId) * ID_MULTIPLE),
            ownerOf(_tokenId),
            getClaimStatus(_tokenId),
            unitPricePerType,
            tokenIdQuantities[_tokenId],
            productDescription[crowdtainerId],
            numberOfProducts
        );

        return metadataService.uri(metadata);
    }

    /**************************************************************************
     * Internal/private methods
     *************************************************************************/

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     * @dev Tranfers are only allowed in `Delivery` or `Failed` states, but not e.g. during `Funding`.
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        bool mintOrBurn = from == address(0) || to == address(0);
        if (mintOrBurn) return;

        // Transfers are only allowed after funding either succeeded or failed.
        address crowdtainerAddress = crowdtainerIdToAddress(
            tokenIdToCrowdtainerId(tokenId)
        );
        ICrowdtainer crowdtainer = ICrowdtainer(crowdtainerAddress);

        if (
            crowdtainer.crowdtainerState() == CrowdtainerState.Funding ||
            crowdtainer.crowdtainerState() == CrowdtainerState.Uninitialized
        ) {
            revert Errors.TransferNotAllowed({
                crowdtainer: address(crowdtainer),
                state: crowdtainer.crowdtainerState()
            });
        }
    }

    function tokenIdToCrowdtainerId(
        uint256 _tokenId
    ) public pure returns (uint256) {
        if (_tokenId == 0) {
            revert Errors.InvalidTokenId(_tokenId);
        }

        return _tokenId / ID_MULTIPLE;
    }

    function crowdtainerIdToAddress(
        uint256 _crowdtainerId
    ) public view returns (address) {
        address crowdtainerAddress = crowdtainerForId[_crowdtainerId];
        if (crowdtainerAddress == address(0)) {
            revert Errors.CrowdtainerInexistent();
        }
        return crowdtainerAddress;
    }

    function getClaimStatus(uint256 _tokenId) public view returns (bool) {
        return BitMaps.get(claimed, _tokenId);
    }

    function setClaimStatus(uint256 _tokenId, bool _value) public {
        address crowdtainerAddress = crowdtainerIdToAddress(
            tokenIdToCrowdtainerId(_tokenId)
        );

        ICrowdtainer crowdtainer = ICrowdtainer(crowdtainerAddress);

        address shippingAgent = crowdtainer.shippingAgent();

        if (msg.sender != shippingAgent) {
            revert Errors.SetClaimedOnlyAllowedByShippingAgent();
        }

        BitMaps.setTo(claimed, _tokenId, _value);
    }
}