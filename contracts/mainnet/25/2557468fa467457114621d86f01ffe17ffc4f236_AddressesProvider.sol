/**
 *Submitted for verification at Arbiscan on 2023-05-15
*/

pragma solidity 0.8.4;


// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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

//
interface IOperatorAccessControl {
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function isOperator(address account) external view returns (bool);

    function addOperator(address account) external;

    function revokeOperator(address account) external;
}

//
contract OperatorAccessControl is IOperatorAccessControl, Ownable {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    modifier isOperatorOrOwner() {
        address _sender = _msgSender();
        require(
            isOperator(_sender) || owner() == _sender,
            "OperatorAccessControl: caller is not operator or owner"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            isOperator(_msgSender()),
            "OperatorAccessControl: caller is not operator"
        );
        _;
    }

    function isOperator(address account) public view override returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    function _addOperator(address account) internal virtual {
        _grantRole(OPERATOR_ROLE, account);
    }

    function addOperator(address account) public override onlyOperator {
        _grantRole(OPERATOR_ROLE, account);
    }

    function revokeOperator(address account) public override onlyOperator {
        _revokeRole(OPERATOR_ROLE, account);
    }
}

//
interface IAddressesProvider {
    function addSigner(address signer) external;

    function removeSigner(address signer) external;

    function isSigner(address signer) external view returns (bool);

    function setAddress(bytes32 key, address addr) external;

    function getAddress(bytes32 key) external view returns (address);

    function setPlatformAccount(address platformAccount) external;

    function getPlatformAccount() external view returns (address);

    function safeGetPlatformAccount() external view returns (address);
}

//
contract AddressesProvider is OperatorAccessControl, IAddressesProvider {
    mapping(address => bool) signers;

    mapping(bytes32 => address) addresses;

    bytes32 constant PLATFORM_ACCOUNT = keccak256("PLATFORM_ACCOUNT");

    //初始化合约
    constructor() {
        _addOperator(_msgSender());
    }

    function addSigner(address signer) public override onlyOperator {
        require(
            signer != address(0),
            "AddressesProvider: signer cannot be zero address"
        );
        if (!signers[signer]) {
            signers[signer] = true;
        }
    }

    function removeSigner(address signer) public override onlyOperator {
        if (signers[signer]) {
            delete signers[signer];
        }
    }

    function isSigner(address signer) public view override returns (bool) {
        require(
            signer != address(0),
            "AddressesProvider: signer cannot be zero address"
        );
        return signers[signer];
    }

    function setAddress(
        bytes32 key,
        address addr
    ) public override onlyOperator {
        addresses[key] = addr;
    }

    function getAddress(
        bytes32 key
    ) public view override onlyOperator returns (address) {
        return addresses[key];
    }

    function setPlatformAccount(
        address platformAccount
    ) public override onlyOperator {
        addresses[PLATFORM_ACCOUNT] = platformAccount;
    }

    function getPlatformAccount() public view override returns (address) {
        return addresses[PLATFORM_ACCOUNT];
    }

    function safeGetPlatformAccount() public view override returns (address) {
        address _addr = addresses[PLATFORM_ACCOUNT];
        require(
            _addr != address(0),
            "AddressesProvider: platform account is not set"
        );
        return _addr;
    }
}