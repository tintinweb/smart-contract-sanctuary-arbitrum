// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface ICVIOracle {
    function getCVIRoundData(uint80 roundId) external view returns (uint32 cviValue, uint256 cviTimestamp);
    function getCVILatestRoundData() external view returns (uint32 cviValue, uint80 cviRoundId, uint256 cviTimestamp);
    function getTruncatedCVIValue(int256 cviOracleValue) external view returns (uint32);
    function getTruncatedMaxCVIValue() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IVolatilityTokenActionHandler.sol";

interface IHedgedThetaVaultActionHandler {
    function depositForOwner(address owner, uint168 tokenAmount, uint32 realTimeCVIValue, bool shouldStake) external returns (uint256 hedgedThetaTokensMinted);
    function withdrawForOwner(address owner, uint168 hedgedThetaTokenAmount, uint32 realTimeCVIValue) external returns (uint256 tokenWithdrawnAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IRequestFulfillerV3.sol";
import "./IRequestFulfillerV3ManagementConfig.sol";

enum OrderType {
    NONE,
    CVI_LIMIT,
    CVI_TP,
    CVI_SL,
    UCVI_LIMIT,
    UCVI_TP,
    UCVI_SL,
    REVERSE_LIMIT,
    REVERSE_TP,
    REVERSE_SL
}

interface ILimitOrderHandler {

    function createOrder(OrderType orderType, uint256 requestId, address requester, uint256 executionFee, uint32 triggerIndex, bytes memory eventData) external;
    function editOrder(uint256 requestId, uint32 triggerIndex, bytes memory eventData, address sender) external;
    function cancelOrder(uint256 requestId, address sender) external returns(address requester, uint256 executionFee);
    function removeExpiredOrder(uint256 requestId) external returns(address requester, uint256 executionFee);

    function getActiveOrders() external view returns(uint256[] memory ids);
    function checkOrders(int256 cviValue, uint256[] calldata idsToCheck) external view returns(bool[] memory isTriggerable);
    function checkAllOrders(int256 cviValue) external view returns(uint256[] memory triggerableIds);

    function triggerOrder(uint256 requestId, int256 cviValue) external returns(RequestType orderType, address requester, uint256 executionFee, bytes memory eventData);

    function setRequestFulfiller(address newRequestFulfiller) external;
    function setRequestFulfillerConfig(IRequestFulfillerV3ManagementConfig newRequestFulfillerConfig) external;
    function setOrderExpirationPeriod(uint32 newOrderExpirationPeriod) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IThetaVaultActionHandler.sol";

interface IMegaThetaVaultActionHandler {
    function depositForOwner(address owner, uint168 tokenAmount, uint32 realTimeCVIValue) external returns (uint256 megaThetaTokensMinted);
    function withdrawForOwner(address owner, uint168 thetaTokenAmount, uint32 realTimeCVIValue) external returns (uint256 tokenWithdrawnAmount);
    function thetaVault() external view returns (IThetaVaultActionHandler);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./ICVIOracle.sol";

interface IPlatformPositionHandler {
    function openPositionForOwner(address owner, bytes32 referralCode, uint168 tokenAmount, uint32 maxCVI, uint32 maxBuyingPremiumFeePercentage, uint8 leverage, uint32 realTimeCVIValue) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount, uint168 openPositionFee, uint168 buyingPremiumFee);
    function closePositionForOwner(address owner, uint168 positionUnitsAmount, uint32 minCVI, uint32 realTimeCVIValue) external returns (uint256 tokenAmount, uint256 closePositionFee, uint256 closingPremiumFee);
    function cviOracle() external view returns (ICVIOracle);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IRequestFulfillerV3ManagementConfig.sol";

enum RequestType {
    NONE,
    CVI_OPEN,
    CVI_CLOSE,
    UCVI_OPEN,
    UCVI_CLOSE,
    REVERSE_OPEN,
    REVERSE_CLOSE,
    CVI_MINT,
    CVI_BURN,
    UCVI_MINT,
    UCVI_BURN,
    HEDGED_DEPOSIT,
    HEDGED_WITHDRAW,
    MEGA_DEPOSIT,
    MEGA_WITHDRAW
}

interface IRequestFulfillerV3 {
    event RequestFulfillerV3ManagementConfigSet(address newRequestFulfillerConfig);

    function setRequestFulfillerV3ManagementConfig(IRequestFulfillerV3ManagementConfig newRequestFulfillerConfig) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IRequestFulfillerV3ManagementConfig.sol";

interface IRequestFulfillerV3Management is IRequestFulfillerV3ManagementConfig {

    event MinPlatformAmountsSet(uint168 newMinOpenAmount, uint168 newMinCloseAmount);
    event MinVolTokenAmountsSet(uint168 newMinMintAmount, uint168 newMinBurnAmount);
    event MinThetaVaultAmountsSet(uint168 newMinDepositAmount, uint168 newMinWithdrawAmount);
    event CVIPlatformSet(address newCVIPlatform);
    event UCVIPlatformSet(address newUCVIPlatform);
    event ReversePlatformSet(address newReversePlatform);
    event CVIVolTokenSet(address newCVIVolToken);
    event UCVIVolTokenSet(address newUCVIVolToken);
    event HedgedVaultSet(address newHedgedVault);
    event MegaVaultSet(address newMegaVault);
    event MinCVIDiffAllowedPercentageSet(uint32 newWithdarwFeePercentage);
    event LimitOrderHandlerSet(address newLimitOrderHandler);

    function setMinPlatformAmounts(uint168 newMinOpenAmount, uint168 newMinCloseAmount) external;
    function setMinVolTokenAmounts(uint168 newMinMintAmount, uint168 newMinBurnAmount) external;
    function setMinThetaVaultAmounts(uint168 newMinDepositAmount, uint168 newMinWithdrawAmount) external;
    function setCVIPlatform(IPlatformPositionHandler cviPlatform) external;
    function setUCVIPlatform(IPlatformPositionHandler ucviPlatform) external;
    function setReversePlatform(IPlatformPositionHandler reversePlatform) external;
    function setCVIVolToken(IVolatilityTokenActionHandler cviVolToken) external;
    function setUCVIVolToken(IVolatilityTokenActionHandler ucviVolToken) external;
    function setHedgedVault(IHedgedThetaVaultActionHandler newHedgedVault) external;
    function setMegaVault(IMegaThetaVaultActionHandler newMegaVault) external;
    function setMinCVIDiffAllowedPercentage(uint32 newMinCVIDiffAllowedPercentage) external;
    function setLimitOrderHandler(ILimitOrderHandler newLimitOrderHandler) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IPlatformPositionHandler.sol";
import "./IVolatilityTokenActionHandler.sol";
import "./IVolatilityTokenActionHandler.sol";
import "./IHedgedThetaVaultActionHandler.sol";
import "./IMegaThetaVaultActionHandler.sol";
import "./ILimitOrderHandler.sol";

interface IRequestFulfillerV3ManagementConfig {

    function minOpenAmount() external view returns(uint168);
    function minCloseAmount() external view returns(uint168);

    function minMintAmount() external view returns(uint168);
    function minBurnAmount() external view returns(uint168);

    function minDepositAmount() external view returns(uint256);
    function minWithdrawAmount() external view returns(uint256);

    function platformCVI() external view returns(IPlatformPositionHandler);
    function platformUCVI() external view returns(IPlatformPositionHandler);
    function platformReverse() external view returns(IPlatformPositionHandler);

    function volTokenCVI() external view returns(IVolatilityTokenActionHandler);
    function volTokenUCVI() external view returns(IVolatilityTokenActionHandler);

    function hedgedVault() external view returns(IHedgedThetaVaultActionHandler);
    function megaVault() external view returns(IMegaThetaVaultActionHandler);

    function minCVIDiffAllowedPercentage() external view returns(uint32);

    function limitOrderHandler() external view returns(ILimitOrderHandler);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IPlatformPositionHandler.sol";

interface IThetaVaultActionHandler {
    function platform() external view returns (IPlatformPositionHandler);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IPlatformPositionHandler.sol";

interface IVolatilityTokenActionHandler {
    function mintTokensForOwner(address owner, uint168 tokenAmount, uint32 maxBuyingPremiumFeePercentage, uint32 realTimeCVIValue) external returns (uint256 tokensMinted);
    function burnTokensForOwner(address owner,  uint168 burnAmount, uint32 realTimeCVIValue) external returns (uint256 tokensReceived);
    function platform() external view returns (IPlatformPositionHandler);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import "./interfaces/IRequestFulfillerV3Management.sol";

contract RequestFulfillerV3Management is IRequestFulfillerV3Management, OwnableUpgradeable {
    uint168 public minOpenAmount;
    uint168 public minCloseAmount;

    uint168 public minMintAmount;
    uint168 public minBurnAmount;

    uint256 public minDepositAmount;
    uint256 public minWithdrawAmount;

    IPlatformPositionHandler public platformCVI;
    IPlatformPositionHandler public platformUCVI;
    IPlatformPositionHandler public platformReverse;

    IVolatilityTokenActionHandler public volTokenCVI;
    IVolatilityTokenActionHandler public volTokenUCVI;

    IHedgedThetaVaultActionHandler public hedgedVault;
    IMegaThetaVaultActionHandler public megaVault;

    uint32 public minCVIDiffAllowedPercentage;

    ILimitOrderHandler public limitOrderHandler;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) external initializer {
        OwnableUpgradeable.__Ownable_init();

        _transferOwnership(_owner);

        minOpenAmount = 1e6;
        minCloseAmount = 1e4;

        minMintAmount = 1e6;
        minBurnAmount = 0;

        minDepositAmount = 1e4;
        minWithdrawAmount = 1e16;

        minCVIDiffAllowedPercentage = 10000;
    }

    function setMinPlatformAmounts(uint168 _newMinOpenAmount, uint168 _newMinCloseAmount) external override onlyOwner {
        minOpenAmount = _newMinOpenAmount;
        minCloseAmount = _newMinCloseAmount;

        emit MinPlatformAmountsSet(_newMinOpenAmount, _newMinCloseAmount);
    }

    function setMinVolTokenAmounts(uint168 _newMinMintAmount, uint168 _newMinBurnAmount) external override onlyOwner {
        minMintAmount = _newMinMintAmount;
        minBurnAmount = _newMinBurnAmount;

        emit MinVolTokenAmountsSet(_newMinMintAmount, _newMinBurnAmount);
    }

    function setMinThetaVaultAmounts(uint168 _newMinDepositAmount, uint168 _newMinWithdrawAmount) external override onlyOwner {
        minDepositAmount = _newMinDepositAmount;
        minWithdrawAmount = _newMinWithdrawAmount;

        emit MinThetaVaultAmountsSet(_newMinDepositAmount, _newMinWithdrawAmount);
    }

    function setCVIPlatform(IPlatformPositionHandler _newCVIPlatform) external override onlyOwner {
        platformCVI = _newCVIPlatform;

        emit CVIPlatformSet(address(_newCVIPlatform));
    }

    function setUCVIPlatform(IPlatformPositionHandler _newUCVIPlatform) external override onlyOwner {
        platformUCVI = _newUCVIPlatform;

        emit UCVIPlatformSet(address(_newUCVIPlatform));
    }

    function setReversePlatform(IPlatformPositionHandler _newReversePlatform) external override onlyOwner {
        platformReverse = _newReversePlatform;

        emit ReversePlatformSet(address(_newReversePlatform));
    }

    function setCVIVolToken(IVolatilityTokenActionHandler _newCVIVolToken) external override onlyOwner {
        volTokenCVI = _newCVIVolToken;

        emit CVIVolTokenSet(address(_newCVIVolToken));
    }

    function setUCVIVolToken(IVolatilityTokenActionHandler _newUCVIVolToken) external override onlyOwner {
        volTokenUCVI = _newUCVIVolToken;

        emit UCVIVolTokenSet(address(_newUCVIVolToken));
    }

    function setHedgedVault(IHedgedThetaVaultActionHandler _newHedgedVault) external override onlyOwner {
        hedgedVault = _newHedgedVault;

        emit HedgedVaultSet(address(_newHedgedVault));
    }

    function setMegaVault(IMegaThetaVaultActionHandler _newMegaVault) external override onlyOwner {
        megaVault = _newMegaVault;

        emit MegaVaultSet(address(_newMegaVault));
    }

    function setMinCVIDiffAllowedPercentage(uint32 _newMinCVIDiffAllowedPercentage) external override onlyOwner {
        minCVIDiffAllowedPercentage = _newMinCVIDiffAllowedPercentage;

        emit MinCVIDiffAllowedPercentageSet(_newMinCVIDiffAllowedPercentage);   
    }

    function setLimitOrderHandler(ILimitOrderHandler _newLimitOrderHandler) external override onlyOwner {
        limitOrderHandler = _newLimitOrderHandler;

        emit LimitOrderHandlerSet(address(_newLimitOrderHandler));   
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}