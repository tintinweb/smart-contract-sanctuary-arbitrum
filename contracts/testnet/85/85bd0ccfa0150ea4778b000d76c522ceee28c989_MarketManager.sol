// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EndpointGatedUpgradeable} from "../endpoint/EndpointGatedUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC1967Factory} from "../lib/ERC1967Factory.sol";
import "../interfaces/IMarketManager.sol";

interface IERC1967Factory {
    function upgrade(address proxy, address implementation) external payable;
    function upgradeAndCall(address proxy, address implementation, bytes calldata data) external payable;
    function deploy(address implementation, address admin) external payable returns (address proxy);
    function deployAndCall(address implementation, address admin, bytes calldata data)
        external
        payable
        returns (address proxy);
}

contract MarketManager is IMarketManager, Initializable, EndpointGatedUpgradeable {
    IERC20 public usdc;
    IERC1967Factory public proxyFactory;

    IPerpEngine public perpEngine;
    IPriceFeed public priceFeed;
    IFundingRateManager public fundingRateManager;

    address[] public markets;
    mapping(address => IOffchainBook) public books;
    mapping(address => bool) public isListed;

    mapping(uint256 => address) public bookImplements;
    uint256 public bookImplementVersion;

    function initialize(
        address _initialOwner,
        address _endpoint,
        address _usdc,
        address _proxyFactory,
        address _bookImpl
    ) external initializer {
        if (_initialOwner == address(0)) revert ZeroAddress();
        if (_endpoint == address(0)) revert ZeroAddress();
        if (_usdc == address(0)) revert ZeroAddress();
        if (_proxyFactory == address(0)) revert ZeroAddress();
        __Ownable_init(_initialOwner);
        setEndpoint(address(_endpoint));
        usdc = IERC20(_usdc);
        proxyFactory = IERC1967Factory(_proxyFactory);
        _setBookImplement(_bookImpl);
    }

    // =============== VIEWS FUNCTIONS ===============
    function getAllMarkets() external view returns (address[] memory, address[] memory) {
        address[] memory _markets = markets;
        uint256 _length = markets.length;
        address[] memory _books = new address[](_length);
        for (uint256 _i = 0; _i < _length;) {
            address _market = _markets[_i];
            _books[_i] = address(books[_market]);
            unchecked {
                ++_i;
            }
        }
        return (_markets, _books);
    }

    function getMarkets() external view returns (address[] memory _markets) {
        _markets = markets;
    }

    // =============== USER FUNCTIONS ===============
    function addMarket(
        address _market, // address of index token
        int128 _maxLeverage,
        int128 _minSize,
        int128 _tickSize,
        int128 _stepSize,
        IOffchainBook.RiskStore memory _riskStore,
        IOffchainBook.FeeStore memory _feeStore,
        OracleConfig memory _oracleConfig
    ) external onlyOwner returns (address) {
        if (_market == address(0)) revert ZeroAddress();
        if (isListed[_market]) revert DuplicateMarket();
        // deploy new offchain book contract and update config
        IOffchainBook _book =
            IOffchainBook(proxyFactory.deploy(bookImplements[bookImplementVersion - 1], address(this)));
        _book.initialize(
            address(this),
            address(getEndpoint()),
            perpEngine,
            _market,
            address(usdc),
            _maxLeverage,
            _minSize,
            _tickSize,
            _stepSize
        );
        _book.modifyRiskStore(_riskStore);
        _book.modifyFeeStore(_feeStore);
        // enable trade
        books[_market] = _book;
        isListed[_market] = true;
        markets.push(_market);
        // update external contract
        perpEngine.addMarket(_market, address(_book));
        priceFeed.configMarket(
            _market, _oracleConfig.priceSource, _oracleConfig.chainlinkPriceFeed, _oracleConfig.pythId
        );
        fundingRateManager.addMarket(_market, block.timestamp);

        return address(_book);
    }

    function removeMarket(address _market) external onlyOwner {
        _checkMarketExits(_market);
        IOffchainBook _book = books[_market];
        // disable trade
        books[_market] = IOffchainBook(address(0));
        isListed[_market] = false;
        // update list of markets
        uint256 _length = markets.length;
        for (uint256 i = 0; i < _length; i++) {
            if (markets[i] == _market) {
                markets[i] = markets[markets.length - 1];
                break;
            }
        }
        markets.pop();
        // update external contract
        perpEngine.removeMarket(_market, address(_book));
        priceFeed.removeMarket(_market);
        fundingRateManager.removeMarket(_market);
    }

    function updateMarketConfig(UpdateMarketTx calldata _tx) external onlyOwner {
        _checkMarketExits(_tx.market);

        IOffchainBook _book = books[_tx.market];
        _book.modifyMarket(_tx.maxLeverage, _tx.minSize, _tx.tickSize, _tx.stepSize);
        _book.modifyRiskStore(_tx.riskStore);
        _book.modifyFeeStore(_tx.feeStore);
    }

    function upgradeMarket(address[] memory _markets, uint256 _implVersion) external onlyOwner {
        address _implement = bookImplements[_implVersion];
        if (_implement == address(0)) revert ZeroAddress();
        uint256 _length = _markets.length;
        for (uint256 _i = 0; _i < _length;) {
            address _market = _markets[_i];
            _checkMarketExits(_market);
            proxyFactory.upgrade(address(books[_market]), _implement);
            unchecked {
                ++_i;
            }
        }
    }

    // =============== RESTRICTED ===============
    function setPerpEngine(address _perpEngine) external onlyOwner {
        if (_perpEngine == address(0)) revert ZeroAddress();
        perpEngine = IPerpEngine(_perpEngine);
        emit PerpEngineSet(_perpEngine);
    }

    function setFundingRateManager(address _fundingRateManager) external onlyOwner {
        if (_fundingRateManager == address(0)) revert ZeroAddress();
        fundingRateManager = IFundingRateManager(_fundingRateManager);
        emit FundingRateManagerSet(_fundingRateManager);
    }

    function setPriceFeed(address _priceFeed) external onlyOwner {
        if (_priceFeed == address(0)) revert ZeroAddress();
        priceFeed = IPriceFeed(_priceFeed);
        emit PriceFeedSet(_priceFeed);
    }

    function setBookImplement(address _bookImpl) external onlyOwner {
        _setBookImplement(_bookImpl);
    }

    // =============== INTERNAL FUNCTIONS ===============
    function _checkMarketExits(address _market) internal view {
        if (!isListed[_market]) revert MarketNotExits();
    }

    function _setBookImplement(address _bookImpl) internal {
        if (_bookImpl == address(0)) revert ZeroAddress();
        bookImplements[bookImplementVersion] = _bookImpl;
        bookImplementVersion++;

        emit BookImplementSet(_bookImpl);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IEndpoint} from "../interfaces/IEndpoint.sol";

contract EndpointGatedUpgradeable is OwnableUpgradeable {
    IEndpoint private endpoint;

    modifier onlyEndpoint() {
        if (msg.sender != address(endpoint)) revert Unauthorized();
        _;
    }

    // =============== VIEWS FUNCTIONS ===============
    function getEndpoint() public view returns (IEndpoint) {
        return endpoint;
    }

    // =============== USER FUNCTIONS ===============
    function setEndpoint(address _endpoint) public onlyOwner {
        if (_endpoint == address(0)) revert ZeroAddress();
        endpoint = IEndpoint(_endpoint);
        emit EndpointSet(_endpoint);
    }

    // =============== ERRORS ===============
    error ZeroAddress();
    error Unauthorized();

    // =============== EVENTS ===============
    event EndpointSet(address _endpoint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Factory for deploying and managing ERC1967 proxy contracts.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ERC1967Factory.sol)
/// @author jtriley-eth (https://github.com/jtriley-eth/minimum-viable-proxy)
contract ERC1967Factory {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The proxy deployment failed.
    error DeploymentFailed();

    /// @dev The upgrade failed.
    error UpgradeFailed();

    /// @dev The salt does not start with the caller.
    error SaltDoesNotStartWithCaller();

    /// @dev `bytes4(keccak256(bytes("Unauthorized()")))`.
    uint256 internal constant _UNAUTHORIZED_ERROR_SELECTOR = 0x82b42900;

    /// @dev `bytes4(keccak256(bytes("DeploymentFailed()")))`.
    uint256 internal constant _DEPLOYMENT_FAILED_ERROR_SELECTOR = 0x30116425;

    /// @dev `bytes4(keccak256(bytes("UpgradeFailed()")))`.
    uint256 internal constant _UPGRADE_FAILED_ERROR_SELECTOR = 0x55299b49;

    /// @dev `bytes4(keccak256(bytes("SaltDoesNotStartWithCaller()")))`.
    uint256 internal constant _SALT_DOES_NOT_START_WITH_CALLER_ERROR_SELECTOR = 0x2f634836;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The admin of a proxy contract has been changed.
    event AdminChanged(address indexed proxy, address indexed admin);

    /// @dev The implementation for a proxy has been upgraded.
    event Upgraded(address indexed proxy, address indexed implementation);

    /// @dev A proxy has been deployed.
    event Deployed(address indexed proxy, address indexed implementation, address indexed admin);

    /// @dev `keccak256(bytes("AdminChanged(address,address)"))`.
    uint256 internal constant _ADMIN_CHANGED_EVENT_SIGNATURE =
        0x7e644d79422f17c01e4894b5f4f588d331ebfa28653d42ae832dc59e38c9798f;

    /// @dev `keccak256(bytes("Upgraded(address,address)"))`.
    uint256 internal constant _UPGRADED_EVENT_SIGNATURE =
        0x5d611f318680d00598bb735d61bacf0c514c6b50e1e5ad30040a4df2b12791c7;

    /// @dev `keccak256(bytes("Deployed(address,address,address)"))`.
    uint256 internal constant _DEPLOYED_EVENT_SIGNATURE =
        0xc95935a66d15e0da5e412aca0ad27ae891d20b2fb91cf3994b6a3bf2b8178082;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // The admin slot for a `proxy` is given by:
    // ```
    //     mstore(0x0c, address())
    //     mstore(0x00, proxy)
    //     let adminSlot := keccak256(0x0c, 0x20)
    // ```

    /// @dev The ERC-1967 storage slot for the implementation in the proxy.
    /// `uint256(keccak256("eip1967.proxy.implementation")) - 1`.
    uint256 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ADMIN FUNCTIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the admin of the proxy.
    function adminOf(address proxy) public view returns (address admin) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, address())
            mstore(0x00, proxy)
            admin := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Sets the admin of the proxy.
    /// The caller of this function must be the admin of the proxy on this factory.
    function changeAdmin(address proxy, address admin) public {
        /// @solidity memory-safe-assembly
        assembly {
            // Check if the caller is the admin of the proxy.
            mstore(0x0c, address())
            mstore(0x00, proxy)
            let adminSlot := keccak256(0x0c, 0x20)
            if iszero(eq(sload(adminSlot), caller())) {
                mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
            // Store the admin for the proxy.
            sstore(adminSlot, admin)
            // Emit the {AdminChanged} event.
            log3(0, 0, _ADMIN_CHANGED_EVENT_SIGNATURE, proxy, admin)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     UPGRADE FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Upgrades the proxy to point to `implementation`.
    /// The caller of this function must be the admin of the proxy on this factory.
    function upgrade(address proxy, address implementation) public payable {
        upgradeAndCall(proxy, implementation, _emptyData());
    }

    /// @dev Upgrades the proxy to point to `implementation`.
    /// Then, calls the proxy with abi encoded `data`.
    /// The caller of this function must be the admin of the proxy on this factory.
    function upgradeAndCall(address proxy, address implementation, bytes calldata data) public payable {
        /// @solidity memory-safe-assembly
        assembly {
            // Check if the caller is the admin of the proxy.
            mstore(0x0c, address())
            mstore(0x00, proxy)
            if iszero(eq(sload(keccak256(0x0c, 0x20)), caller())) {
                mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
            // Set up the calldata to upgrade the proxy.
            let m := mload(0x40)
            mstore(m, implementation)
            mstore(add(m, 0x20), _IMPLEMENTATION_SLOT)
            calldatacopy(add(m, 0x40), data.offset, data.length)
            // Try upgrading the proxy and revert upon failure.
            if iszero(call(gas(), proxy, callvalue(), m, add(0x40, data.length), 0x00, 0x00)) {
                // Revert with the `UpgradeFailed` selector if there is no error returndata.
                if iszero(returndatasize()) {
                    mstore(0x00, _UPGRADE_FAILED_ERROR_SELECTOR)
                    revert(0x1c, 0x04)
                }
                // Otherwise, bubble up the returned error.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            // Emit the {Upgraded} event.
            log3(0, 0, _UPGRADED_EVENT_SIGNATURE, proxy, implementation)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      DEPLOY FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a proxy for `implementation`, with `admin`,
    /// and returns its address.
    /// The value passed into this function will be forwarded to the proxy.
    function deploy(address implementation, address admin) public payable returns (address proxy) {
        proxy = deployAndCall(implementation, admin, _emptyData());
    }

    /// @dev Deploys a proxy for `implementation`, with `admin`,
    /// and returns its address.
    /// The value passed into this function will be forwarded to the proxy.
    /// Then, calls the proxy with abi encoded `data`.
    function deployAndCall(address implementation, address admin, bytes calldata data)
        public
        payable
        returns (address proxy)
    {
        proxy = _deploy(implementation, admin, bytes32(0), false, data);
    }

    /// @dev Deploys a proxy for `implementation`, with `admin`, `salt`,
    /// and returns its deterministic address.
    /// The value passed into this function will be forwarded to the proxy.
    function deployDeterministic(address implementation, address admin, bytes32 salt)
        public
        payable
        returns (address proxy)
    {
        proxy = deployDeterministicAndCall(implementation, admin, salt, _emptyData());
    }

    /// @dev Deploys a proxy for `implementation`, with `admin`, `salt`,
    /// and returns its deterministic address.
    /// The value passed into this function will be forwarded to the proxy.
    /// Then, calls the proxy with abi encoded `data`.
    function deployDeterministicAndCall(address implementation, address admin, bytes32 salt, bytes calldata data)
        public
        payable
        returns (address proxy)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // If the salt does not start with the zero address or the caller.
            if iszero(or(iszero(shr(96, salt)), eq(caller(), shr(96, salt)))) {
                mstore(0x00, _SALT_DOES_NOT_START_WITH_CALLER_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
        proxy = _deploy(implementation, admin, salt, true, data);
    }

    /// @dev Deploys the proxy, with optionality to deploy deterministically with a `salt`.
    function _deploy(address implementation, address admin, bytes32 salt, bool useSalt, bytes calldata data)
        internal
        returns (address proxy)
    {
        bytes memory m = _initCode();
        /// @solidity memory-safe-assembly
        assembly {
            // Create the proxy.
            switch useSalt
            case 0 { proxy := create(0, add(m, 0x13), 0x89) }
            default { proxy := create2(0, add(m, 0x13), 0x89, salt) }
            // Revert if the creation fails.
            if iszero(proxy) {
                mstore(0x00, _DEPLOYMENT_FAILED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }

            // Set up the calldata to set the implementation of the proxy.
            mstore(m, implementation)
            mstore(add(m, 0x20), _IMPLEMENTATION_SLOT)
            calldatacopy(add(m, 0x40), data.offset, data.length)
            // Try setting the implementation on the proxy and revert upon failure.
            if iszero(call(gas(), proxy, callvalue(), m, add(0x40, data.length), 0x00, 0x00)) {
                // Revert with the `DeploymentFailed` selector if there is no error returndata.
                if iszero(returndatasize()) {
                    mstore(0x00, _DEPLOYMENT_FAILED_ERROR_SELECTOR)
                    revert(0x1c, 0x04)
                }
                // Otherwise, bubble up the returned error.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }

            // Store the admin for the proxy.
            mstore(0x0c, address())
            mstore(0x00, proxy)
            sstore(keccak256(0x0c, 0x20), admin)

            // Emit the {Deployed} event.
            log4(0, 0, _DEPLOYED_EVENT_SIGNATURE, proxy, implementation, admin)
        }
    }

    /// @dev Returns the address of the proxy deployed with `salt`.
    function predictDeterministicAddress(bytes32 salt) public view returns (address predicted) {
        bytes32 hash = initCodeHash();
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, address()))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /// @dev Returns the initialization code hash of the proxy.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash() public view returns (bytes32 result) {
        bytes memory m = _initCode();
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(add(m, 0x13), 0x89)
        }
    }

    /// @dev Returns the initialization code of a proxy created via this factory.
    function _initCode() internal view returns (bytes memory m) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * -------------------------------------------------------------------------------------+
             * CREATION (9 bytes)                                                                   |
             * -------------------------------------------------------------------------------------|
             * Opcode     | Mnemonic        | Stack               | Memory                          |
             * -------------------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize   | r                   |                                 |
             * 3d         | RETURNDATASIZE  | 0 r                 |                                 |
             * 81         | DUP2            | r 0 r               |                                 |
             * 60 offset  | PUSH1 offset    | o r 0 r             |                                 |
             * 3d         | RETURNDATASIZE  | 0 o r 0 r           |                                 |
             * 39         | CODECOPY        | 0 r                 | [0..runSize): runtime code      |
             * f3         | RETURN          |                     | [0..runSize): runtime code      |
             * -------------------------------------------------------------------------------------|
             * RUNTIME (127 bytes)                                                                  |
             * -------------------------------------------------------------------------------------|
             * Opcode      | Mnemonic       | Stack               | Memory                          |
             * -------------------------------------------------------------------------------------|
             *                                                                                      |
             * ::: keep some values in stack :::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | 0                   |                                 |
             * 3d          | RETURNDATASIZE | 0 0                 |                                 |
             *                                                                                      |
             * ::: check if caller is factory ::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 33          | CALLER         | c 0 0               |                                 |
             * 73 factory  | PUSH20 factory | f c 0 0             |                                 |
             * 14          | EQ             | isf 0 0             |                                 |
             * 60 0x57     | PUSH1 0x57     | dest isf 0 0        |                                 |
             * 57          | JUMPI          | 0 0                 |                                 |
             *                                                                                      |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36          | CALLDATASIZE   | cds 0 0             |                                 |
             * 3d          | RETURNDATASIZE | 0 cds 0 0           |                                 |
             * 3d          | RETURNDATASIZE | 0 0 cds 0 0         |                                 |
             * 37          | CALLDATACOPY   | 0 0                 | [0..calldatasize): calldata     |
             *                                                                                      |
             * ::: delegatecall to implementation ::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36          | CALLDATASIZE   | cds 0 0             | [0..calldatasize): calldata     |
             * 3d          | RETURNDATASIZE | 0 cds 0 0           | [0..calldatasize): calldata     |
             * 7f slot     | PUSH32 slot    | s 0 cds 0 0         | [0..calldatasize): calldata     |
             * 54          | SLOAD          | i cds 0 0           | [0..calldatasize): calldata     |
             * 5a          | GAS            | g i cds 0 0         | [0..calldatasize): calldata     |
             * f4          | DELEGATECALL   | succ                | [0..calldatasize): calldata     |
             *                                                                                      |
             * ::: copy returndata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | rds succ            | [0..calldatasize): calldata     |
             * 60 0x00     | PUSH1 0x00     | 0 rds succ          | [0..calldatasize): calldata     |
             * 80          | DUP1           | 0 0 rds succ        | [0..calldatasize): calldata     |
             * 3e          | RETURNDATACOPY | succ                | [0..returndatasize): returndata |
             *                                                                                      |
             * ::: branch on delegatecall status :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x52     | PUSH1 0x52     | dest succ           | [0..returndatasize): returndata |
             * 57          | JUMPI          |                     | [0..returndatasize): returndata |
             *                                                                                      |
             * ::: delegatecall failed, revert :::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | rds                 | [0..returndatasize): returndata |
             * 60 0x00     | PUSH1 0x00     | 0 rds               | [0..returndatasize): returndata |
             * fd          | REVERT         |                     | [0..returndatasize): returndata |
             *                                                                                      |
             * ::: delegatecall succeeded, return ::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b          | JUMPDEST       |                     | [0..returndatasize): returndata |
             * 3d          | RETURNDATASIZE | rds                 | [0..returndatasize): returndata |
             * 60 0x00     | PUSH1 0x00     | 0 rds               | [0..returndatasize): returndata |
             * f3          | RETURN         |                     | [0..returndatasize): returndata |
             *                                                                                      |
             * ::: set new implementation (caller is factory) ::::::::::::::::::::::::::::::::::::: |
             * 5b          | JUMPDEST       | 0 0                 |                                 |
             * 3d          | RETURNDATASIZE | 0 0 0               |                                 |
             * 35          | CALLDATALOAD   | impl 0 0            |                                 |
             * 06 0x20     | PUSH1 0x20     | w impl 0 0          |                                 |
             * 35          | CALLDATALOAD   | slot impl 0 0       |                                 |
             * 55          | SSTORE         | 0 0                 |                                 |
             *                                                                                      |
             * ::: no extra calldata, return :::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x40     | PUSH1 0x40     | 2w 0 0              |                                 |
             * 80          | DUP1           | 2w 2w 0 0           |                                 |
             * 36          | CALLDATASIZE   | cds 2w 2w 0 0       |                                 |
             * 11          | GT             | gt 2w 0 0           |                                 |
             * 15          | ISZERO         | lte 2w 0 0          |                                 |
             * 60 0x52     | PUSH1 0x52     | dest lte 2w 0 0     |                                 |
             * 57          | JUMPI          | 2w 0 0              |                                 |
             *                                                                                      |
             * ::: copy extra calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36          | CALLDATASIZE   | cds 2w 0 0          |                                 |
             * 03          | SUB            | t 0 0               |                                 |
             * 80          | DUP1           | t t 0 0             |                                 |
             * 60 0x40     | PUSH1 0x40     | 2w t t 0 0          |                                 |
             * 3d          | RETURNDATASIZE | 0 2w t t 0 0        |                                 |
             * 37          | CALLDATACOPY   | t 0 0               | [0..t): extra calldata          |
             *                                                                                      |
             * ::: delegatecall to implementation ::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | 0 t 0 0             | [0..t): extra calldata          |
             * 3d          | RETURNDATASIZE | 0 0 t 0 0           | [0..t): extra calldata          |
             * 35          | CALLDATALOAD   | i t 0 0             | [0..t): extra calldata          |
             * 5a          | GAS            | g i t 0 0           | [0..t): extra calldata          |
             * f4          | DELEGATECALL   | succ                | [0..t): extra calldata          |
             *                                                                                      |
             * ::: copy returndata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | rds succ            | [0..t): extra calldata          |
             * 60 0x00     | PUSH1 0x00     | 0 rds succ          | [0..t): extra calldata          |
             * 80          | DUP1           | 0 0 rds succ        | [0..t): extra calldata          |
             * 3e          | RETURNDATACOPY | succ                | [0..returndatasize): returndata |
             *                                                                                      |
             * ::: branch on delegatecall status :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x52     | PUSH1 0x52     | dest succ           | [0..returndatasize): returndata |
             * 57          | JUMPI          |                     | [0..returndatasize): returndata |
             *                                                                                      |
             * ::: delegatecall failed, revert :::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | rds                 | [0..returndatasize): returndata |
             * 60 0x00     | PUSH1 0x00     | 0 rds               | [0..returndatasize): returndata |
             * fd          | REVERT         |                     | [0..returndatasize): returndata |
             * -------------------------------------------------------------------------------------+
             */

            m := mload(0x40)
            // forgefmt: disable-start
            switch shr(112, address())
            case 0 {
                // If the factory's address has six or more leading zero bytes.
                mstore(add(m, 0x75), 0x604c573d6000fd) // 7
                mstore(add(m, 0x6e), 0x3d3560203555604080361115604c5736038060403d373d3d355af43d6000803e) // 32
                mstore(add(m, 0x4e), 0x3735a920a3ca505d382bbc545af43d6000803e604c573d6000fd5b3d6000f35b) // 32
                mstore(add(m, 0x2e), 0x14605157363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc) // 32
                mstore(add(m, 0x0e), address()) // 14
                mstore(m, 0x60793d8160093d39f33d3d336d) // 9 + 4
            }
            default {
                mstore(add(m, 0x7b), 0x6052573d6000fd) // 7
                mstore(add(m, 0x74), 0x3d356020355560408036111560525736038060403d373d3d355af43d6000803e) // 32
                mstore(add(m, 0x54), 0x3735a920a3ca505d382bbc545af43d6000803e6052573d6000fd5b3d6000f35b) // 32
                mstore(add(m, 0x34), 0x14605757363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc) // 32
                mstore(add(m, 0x14), address()) // 20
                mstore(m, 0x607f3d8160093d39f33d3d3373) // 9 + 4
            }
            // forgefmt: disable-end
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          HELPERS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper function to return an empty bytes calldata.
    function _emptyData() internal pure returns (bytes calldata data) {
        /// @solidity memory-safe-assembly
        assembly {
            data.length := 0
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IPerpEngine} from "./IPerpEngine.sol";
import {IFundingRateManager} from "./IFundingRateManager.sol";
import {IPriceFeed} from "./IPriceFeed.sol";
import {IOffchainBook} from "./IOffchainBook.sol";

interface IMarketManager {
    struct OracleConfig {
        IPriceFeed.PriceSource priceSource;
        address chainlinkPriceFeed;
        bytes32 pythId;
    }

    struct UpdateMarketTx {
        address market;
        int128 maxLeverage;
        int128 minSize;
        int128 tickSize;
        int128 stepSize;
        IOffchainBook.RiskStore riskStore;
        IOffchainBook.FeeStore feeStore;
    }

    // =============== VIEWS FUNCTIONS ===============
    function getAllMarkets() external view returns (address[] memory, address[] memory);

    function getMarkets() external view returns(address[] memory);
    
    // =============== USER FUNCTIONS ===============
    function addMarket(
        address _market, // address of index token
        int128 _maxLeverage,
        int128 _minSize,
        int128 _tickSize,
        int128 _stepSize,
        IOffchainBook.RiskStore memory _riskStore,
        IOffchainBook.FeeStore memory _feeStore,
        OracleConfig memory _oracleConfig
    ) external returns (address);
    function removeMarket(address _market) external;
    function updateMarketConfig(UpdateMarketTx calldata _tx) external;
    function upgradeMarket(address[] memory _markets, uint256 _implVersion) external;

    // =============== RESTRICTED ===============
    function setPerpEngine(address _perpEngine) external;
    function setFundingRateManager(address _fundingRateManager) external;
    function setPriceFeed(address _priceFeed) external;

    // =============== ERRORS ===============
    error DuplicateMarket();
    error MarketNotExits();
    error PerpEngineNotSet();

    // =============== EVENTS ===============
    event SequencerSet(address indexed _sequencer);
    event PerpEngineSet(address indexed _perpEngine);
    event BookImplementSet(address indexed _impl);
    event FundingRateManagerSet(address indexed _fundingRateManager);
    event PriceFeedSet(address indexed _priceFeed);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

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
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
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
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IOffchainBook} from "./IOffchainBook.sol";

interface IEndpoint {
    enum TransactionType {
        ExecuteSlowMode,
        UpdateFundingRate,
        WithdrawCollateral,
        MatchOrders,
        SettlePnl,
        ClaimExecutionFees,
        ClaimTradeFees,
        Liquidate
    }

    struct WithdrawCollateral {
        address account;
        uint64 nonce;
        address token;
        uint256 amount;
    }

    struct SignedWithdrawCollateral {
        WithdrawCollateral tx;
        bytes signature;
    }

    struct Liquidate {
        bytes[] priceData;
        address liquidator;
        address liquidatee;
        address market;
        int256 amount;
        uint64 nonce;
    }

    struct UpdateFundingRate {
        address[] markets;
        int256[] values;
    }

    struct Order {
        address account;
        int256 price;
        int256 amount;
        bool reduceOnly;
        uint64 nonce;
    }

    struct SignedOrder {
        Order order;
        bytes signature;
    }

    struct SignedMatchOrders {
        address market;
        SignedOrder taker;
        SignedOrder maker;
    }

    struct MatchOrders {
        address market;
        Order taker;
        Order maker;
    }

    struct SettlePnl {
        address account;
    }

    // =============== FUNCTIONS ===============
    function depositCollateral(address _account, uint256 _amount) external;
    function submitTransactions(bytes[] calldata _txs) external;

    function setMarketManager(address _marketManager) external;
    function setMarginBank(address _marginBank) external;
    function setPerpEngine(address _perpEngine) external;
    function setFundingRateManager(address _fundingRateManager) external;
    function setPriceFeed(address _priceFeed) external;
    function setSequencer(address _sequencer) external;

    // =============== VIEWS ===============
    function getNonce(address account) external view returns (uint64);
    function getOrderDigest(Order memory _order) external view returns (bytes32);
    function getAllMarkets()
        external
        view
        returns (
            IOffchainBook.Market[] memory _markets,
            IOffchainBook.FeeStore[] memory _fees,
            IOffchainBook.RiskStore[] memory _risks
        );

    // =============== EVENTS ===============
    event MarketManagerSet(address indexed _marketManager);
    event MarginBankSet(address indexed _marginBank);
    event SequencerSet(address indexed _sequencer);
    event PerpEngineSet(address indexed _perpEngine);
    event FundingRateManagerSet(address indexed _fundingRateManager);
    event PriceFeedSet(address indexed _priceFeed);
    event SubmitTransactions();

    // =============== ERRORS ===============
    error Unauthorized();
    error ZeroAddress();
    error ZeroAmount();
    error InvalidNonce();
    error InvalidSignature();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IMarketManager} from "./IMarketManager.sol";
import {IMarginBank} from "./IMarginBank.sol";
import {IPriceFeed} from "./IPriceFeed.sol";
import {IFundingRateManager} from "./IFundingRateManager.sol";
import {IFeeCalculator} from "./IFeeCalculator.sol";
import {IOffchainBook} from "./IOffchainBook.sol";

interface IPerpEngine {
    /// @dev data of market.
    struct State {
        int256 openInterest;
        int256 fundingIndex;
        int256 lastAccrualFundingTime;
    }

    /// @dev position of user in market
    struct Position {
        int256 baseAmount;
        int256 quoteAmount;
        int256 fundingIndex;
    }

    struct MarketDelta {
        address market;
        address account;
        int256 baseDelta;
        int256 quoteDelta;
    }

    // =============== FUNCTIONS ===============
    function applyDeltas(MarketDelta[] calldata _deltas) external;
    function settlePnl(address _account) external returns (int256 _pnl);
    function socializeAccount(address _account, int256 _insurance) external returns (int256);
    function accrueFunding(address _market) external returns (int256);
    function addMarket(address _market, address _book) external;
    function removeMarket(address _market, address _book) external;
    function liquidate(address _market, address _liquidatee, address _liquidator, int256 _amountToLiquidate)
        external
        returns (int256 _liquidationFee);

    function setMarketManager(address _marketManager) external;
    function setMarginBank(address _marginBank) external;
    function setPriceFeed(address _priceFeed) external;
    function setFundingRateManager(address _fundingRateManager) external;
    function setFeeCalculator(address _feeCalculator) external;

    // =============== VIEWS ===============
    function getConfig()
        external
        view
        returns (address _bank, address _priceFeed, address _fundingManager, address _feeCalculator);
    function getOffchainBook(address _market) external view returns (address);
    function getPosition(address _market, address _account) external view returns (Position memory);
    function getPositionBaseAmount(address _market, address _account) external view returns (int256);
    function getSettledPnl(address _account) external view returns (int256);
    function getUnRealizedPnl(address[] calldata _markets, address _account)
        external
        view
        returns (int256 _unRealizedPnl);

    function getAccountMarkets(address _account) external view returns(address[] memory);

    // =============== ERRORS ===============
    error DuplicateMarket();
    error InvalidOffchainBook();
    error InvalidDecimals();
    error OverSize();

    // =============== EVENTS ===============
    event MarketManagerSet(address indexed _marketManager);
    event MarginBankSet(address indexed _bank);
    event PriceFeedSet(address indexed _priceFeed);
    event FundingRateManagerSet(address indexed _fundingManager);
    event FeeCalculatorSet(address indexed _feeCalculator);
    event MarketAdded(address indexed _indexToken, address indexed _book);
    event PnlSettled(address indexed _market, int256 _pnl);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IMarketManager} from "./IMarketManager.sol";

interface IFundingRateManager {
    // =============== FUNCTIONS ===============
    function addMarket(address _market, uint256 _startTime) external;
    function removeMarket(address _market) external;
    function update(address[] calldata _markets, int256[] calldata _values) external;

    function setMarketManager(address _marketManager) external;

    // =============== VIEWS ===============
    function PRECISION() external view returns (uint256);
    function FUNDING_INTERVAL() external view returns (uint256);

    function lastFundingRate(address _market) external view returns (int256);
    function nextFundingTime(address _market) external view returns (uint256);

    // =============== ERRORS ===============
    error Outdated();
    error OutOfRange();

    error DuplicateMarket();
    error MarketNotExits();
    error InvalidUpdateData();

    // =============== EVENTS ===============
    event MarketManagerSet(address indexed _marketManager);
    event MarketAdded(address indexed _market, uint256 _startTime);
    event MarketRemoved(address indexed _market);
    event ValueUpdated(address indexed _market, int256 _value);
    event FundingRateUpdated(address indexed _market, int256 _value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IMarketManager} from "./IMarketManager.sol";
import {IFundingRateManager} from "./IFundingRateManager.sol";
import {IPyth} from "././pyth/IPyth.sol";
import {PythStructs} from "././pyth/PythStructs.sol";
import {IAggregatorV3Interface} from "./IAggregatorV3Interface.sol";

interface IPriceFeed {
    enum PriceSource {
        Pyth,
        Chainlink
    }

    struct MarketConfig {
        /// @dev precision of base token
        uint256 baseUnits;
        /// @dev use chainlink or pyth oracle
        PriceSource priceSource;
        /// @dev chainlink price feed
        IAggregatorV3Interface chainlinkPriceFeed;
        /// @dev market id of pyth
        bytes32 pythId;
    }

    function configMarket(address _market, PriceSource _priceSource, address _chainlinkPriceFeed, bytes32 _pythId)
        external;
    function removeMarket(address _market) external;
    function setFundingRateManager(address _fundingRateManager) external;
    function updatePrice(bytes[] calldata _data) external payable;

    function setMarketManager(address _marketManager) external;

    // =============== VIEW FUNCTIONS ===============
    function getIndexPrice(address _market) external view returns (uint256);
    function getMarkPrice(address _market) external view returns (uint256);

    // =============== ERRORS ===============
    error InvalidPythId();
    error UnknownMarket();

    // =============== EVENTS ===============
    event MarketManagerSet(address indexed _marketManager);
    event FundingRateManagerSet(address indexed _fundingRateManager);
    event MarketAdded(address indexed _market);
    event MarketRemoved(address indexed _market);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IEndpoint} from "./IEndpoint.sol";
import {IPerpEngine} from "./IPerpEngine.sol";

interface IOffchainBook {
    struct OrderDigest {
        bytes32 taker;
        bytes32 maker;
    }

    struct Market {
        address indexToken;
        uint8 indexDecimals;
        address quoteToken;
        uint8 quoteDecimals;
        /// @dev max leverage of market, default 20x.
        int128 maxLeverage;
        /// @dev min size of position, ex 0.01 btc-usdc perp.
        int128 minSize;
        /// @dev min price increment of order, ex 1 usdc.
        int128 tickSize;
        /// @dev min size increment of order, ex 0.001 btc-usdc perp.
        int128 stepSize;
    }

    struct RiskStore {
        int64 longWeightInitial;
        int64 shortWeightInitial;
        int64 longWeightMaintenance;
        int64 shortWeightMaintenance;
    }

    struct FeeStore {
        int256 makerFees;
        int256 talkerFees;
    }

    // =============== FUNCTIONS ===============
    function initialize(
        address _owner,
        address _endpoint,
        IPerpEngine _engine,
        address _indexToken,
        address _quoteToken,
        int128 _maxLeverage,
        int128 _minSize,
        int128 _tickSize,
        int128 _stepSize
    ) external;
    function claimTradeFees() external returns (int256 _feeAmount);
    function claimExecutionFees() external returns (int256 _feeAmount);
    function modifyMarket(int128 _maxLeverage, int128 _minSize, int128 _tickSize, int128 _stepSize) external;
    function modifyRiskStore(RiskStore calldata _risk) external;
    function modifyFeeStore(FeeStore calldata _fee) external;
    function matchOrders(IEndpoint.MatchOrders calldata _params) external;

    // =============== VIEWS ===============
    function getRiskStore() external view returns (RiskStore memory);
    function getFeeStore() external view returns (FeeStore memory);
    function getMarket() external view returns (Market memory);
    function getIndexToken() external view returns (address);
    function getQuoteToken() external view returns (address);
    function getMaxLeverage() external view returns (int128);
    function getFees() external view returns (uint256, uint256);

    // =============== ERRORS ===============
    error NotHealthy();
    error InvalidSignature();
    error InvalidOrderPrice();
    error InvalidOrderAmount();
    error OrderCannotBeMatched();
    error BadRiskStoreConfig();
    error BadFeeStoreConfig();
    error BadMarketConfig();
    error MaxLeverageTooHigh();

    // =============== EVENTS ===============
    event TradeFeeClaimed(int256 _feeAmount);
    event ExecutionFeeClaimed(int256 _feeAmount);
    event MarketModified(int128 _maxLeverage, int128 _minSize, int128 _tickSize, int128 _stepSize);
    event RiskStoreModified(RiskStore _risk);
    event FeeStoreModified(FeeStore _fee);
    event FillOrder(
        bytes32 indexed _digest,
        address indexed _account,
        int256 _price,
        int256 _amount,
        // whether this order is taking or making
        bool _isTaker,
        // amount paid in fees (in quote)
        int256 _feeAmount,
        // change in this account's base balance from this fill
        int256 _baseAmountDelta,
        // change in this account's quote balance from this fill
        int256 _quoteAmountDelta
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IEndpoint.sol";

interface IMarginBank {
    function handleDepositTransfer(address _account, uint256 _amount) external;

    function withdrawCollateral(IEndpoint.WithdrawCollateral memory _txn) external;

    function liquidate(IEndpoint.Liquidate calldata _txn) external;

    function claimTradeFees() external;

    // function sync() external;

    // EVENTS
    event Deposited(address indexed account, uint256 amount);
    event EndpointSet(address indexed endpoint);
    event Withdrawn(address indexed account, uint256 amount);

    // ERRORS
    error UnknownToken();
    error ZeroAddress();
    error InsufficientFunds();
    error NotUnderMaintenance();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IFeeCalculator {
    function getFeeRate(address _market, address _account, bool _isTaker) external view returns (uint256);
    function getLiquidationFee(address _market) external view returns (int256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint256 validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(bytes32 id, uint256 age) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(bytes32 id, uint256 age) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256 feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint256 publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(bytes32 indexed id, uint64 publishTime, int64 price, uint64 conf);

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}