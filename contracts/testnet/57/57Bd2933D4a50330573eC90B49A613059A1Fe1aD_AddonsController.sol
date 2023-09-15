// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import { PrimarySkill, INeandersmol } from "./interface/INeandersmol.sol";

import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Trait, Skill, AddonsSkill, TokenAddons } from "./lib/StructEnums.sol";

error CsTooLow();
error NotYourToken();
error SkillLevelIsLow(Skill);
error ZeroAddressNotAllowed();
error AddonAlreadyExists(TokenAddons);
error AddonsNotAllowed(Trait, string);

contract AddonsController is Initializable, OwnableUpgradeable {
    INeandersmol public token;

    bytes3 public constant CS_TYPE = (0x63735f);

    function initialize(address _token) public initializer {
        __Ownable_init();
        if (_token == address(0)) revert ZeroAddressNotAllowed();
        token = INeandersmol(_token);
    }

    mapping(uint256 => TokenAddons) public tokenAddons;

    mapping(Skill => mapping(Trait => mapping(string => bool)))
        public allowedAddons;

    /**
     * @dev Checks if a specific addon is allowed for a given skill and trait combination.
     * @param _skill  skill category of the addon.
     * @param _trait  trait associated with the addon.
     * @param _addons The name of the addon being checked.
     * @return A boolean to get the addons state
     */

    function isAdddons(
        Skill _skill,
        Trait _trait,
        string calldata _addons
    ) external view returns (bool) {
        return allowedAddons[_skill][_trait][_addons];
    }

    /**
     * @dev Allows the contract owner to set multiple addons as allowed for a specific skill and trait combination
     * @param _skill skill category of the addon.
     * @param _trait  trait associated with the addon.
     * @param _addons an array of addons to be set as allowed
     */

    function setAllowedAddons(
        Skill _skill,
        Trait _trait,
        string[] calldata _addons
    ) external onlyOwner {
        for (uint256 i; i < _addons.length; ++i) {
            allowedAddons[_skill][_trait][_addons[i]] = true;
            emit SetAddons(_skill, _trait, _addons[i], true);
        }
    }

    /**
     * @dev Allows the contract owner to reset multiple addons for a specific skill and trait combination
     * @param _skill skill category of the addon.
     * @param _trait  trait associated with the addon.
     * @param _addons an array of addons to reset as not allowed
     */
    function resetAllowedAddons(
        Skill _skill,
        Trait _trait,
        string[] calldata _addons
    ) external onlyOwner {
        for (uint256 i; i < _addons.length; ++i) {
            allowedAddons[_skill][_trait][_addons[i]] = false;
            emit SetAddons(_skill, _trait, _addons[i], false);
        }
    }

    /**
     * @dev Allows the addition of addons to a specific token, provided they meet the necessary conditions.
     * @param _tokenId Id of the Neandersmol
     * @param _addonsSkill The skill type associated with the addons being added.
     * @param tokenAddon The addons to be added to the token.
     */

    function setAddons(
        uint256 _tokenId,
        AddonsSkill calldata _addonsSkill,
        TokenAddons calldata tokenAddon
    ) external {
        isTokenAllowed(_tokenId, tokenAddon);
        if (
            !isAddonAllowed(
                _tokenId,
                Trait.Hat,
                _addonsSkill.hat,
                tokenAddon.hat
            )
        ) revert AddonsNotAllowed(Trait.Hat, tokenAddon.hat);

        if (
            !isAddonAllowed(
                _tokenId,
                Trait.Mask,
                _addonsSkill.mask,
                tokenAddon.mask
            )
        ) revert AddonsNotAllowed(Trait.Mask, tokenAddon.mask);

        if (
            !isAddonAllowed(
                _tokenId,
                Trait.Hand,
                _addonsSkill.hand,
                tokenAddon.hand
            )
        ) revert AddonsNotAllowed(Trait.Hand, tokenAddon.hand);

        if (
            !isAddonAllowed(
                _tokenId,
                Trait.Special,
                _addonsSkill.special,
                tokenAddon.special
            )
        ) revert AddonsNotAllowed(Trait.Special, tokenAddon.special);

        tokenAddons[_tokenId] = tokenAddon;
        emit SetEnabledAddon(_tokenId, tokenAddon);
    }

    /**
     * @dev Checks if a token is eligible to receive the specified addons.
     * @param _tokenId Id of the Neandersmol
     * @param tokenAddon The addons being considered for addition.
     */

    function isTokenAllowed(
        uint256 _tokenId,
        TokenAddons calldata tokenAddon
    ) internal view {
        if (token.ownerOf(_tokenId) != msg.sender) revert NotYourToken();
        TokenAddons memory addon = tokenAddons[_tokenId];
        string memory hand = tokenAddon.hand;

        bool hatExists = compareStrings(addon.hat, tokenAddon.hat) &&
            bytes(addon.hat).length > 0;
        bool handExists = compareStrings(addon.hand, hand) &&
            bytes(addon.hand).length > 0;
        bool maskExists = compareStrings(addon.mask, tokenAddon.mask) &&
            bytes(addon.mask).length > 0;
        bool specialExists = compareStrings(
            addon.special,
            tokenAddon.special
        ) && bytes(addon.special).length > 0;
        if (hatExists || handExists || maskExists || specialExists)
            revert AddonAlreadyExists(tokenAddon);
        bytes memory inBytes = bytes(hand);
        bytes3 a;
        assembly {
            a := mload(add(inBytes, 0x20))
        }
        if (
            keccak256(abi.encode(CS_TYPE)) == keccak256(abi.encode(a)) &&
            token.commonSense(_tokenId) < 100 ether
        ) revert CsTooLow();
    }

    /**
     * @dev Checks if a specific addon is allowed for a given skill and trait combination.
     * @param _tokenId The unique identifier of the token.
     * @param _trait The trait associated with the addon.
     * @param _skill The skill category of the addon.
     * @param _addon The name of the addon being checked.
     * @return A boolean indicating whether the specified addon is allowed.
     */

    function isAddonAllowed(
        uint256 _tokenId,
        Trait _trait,
        Skill _skill,
        string calldata _addon
    ) internal view returns (bool) {
        PrimarySkill memory skills = token.getPrimarySkill(_tokenId);

        if (_skill == Skill.Farmers && skills.farmers < 100 ether)
            revert SkillLevelIsLow(_skill);

        if (_skill == Skill.Mystics && skills.mystics < 100 ether)
            revert SkillLevelIsLow(_skill);

        if (_skill == Skill.Fighters && skills.fighters < 100 ether)
            revert SkillLevelIsLow(_skill);

        return
            allowedAddons[_skill][_trait][_addon] || compareStrings(_addon, "");
    }

    /**
     * @dev Compares two strings for equality.
     * @param a The first string.
     * @param b The second string.
     * @return A boolean indicating whether the two strings are equal.
     */

    function compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    event SetEnabledAddon(uint256 indexed tokenId, TokenAddons addons);
    event SetAddons(
        Skill indexed skill,
        Trait indexed Trait,
        string indexed addons,
        bool state
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

struct PrimarySkill {
    uint256 mystics;
    uint256 farmers;
    uint256 fighters;
}

interface INeandersmol {
    function getPrimarySkill(
        uint256 _tokenId
    ) external view returns (PrimarySkill memory);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function commonSense(uint256 _tokenId) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;
enum Trait {
    Hat,
    Hand,
    Mask,
    Special
}

enum Skill {
    Mystics,
    Farmers,
    Fighters
}

struct AddonsSkill {
    Skill hat;
    Skill hand;
    Skill mask;
    Skill special;
}

struct TokenAddons {
    string hat;
    string hand;
    string mask;
    string special;
}