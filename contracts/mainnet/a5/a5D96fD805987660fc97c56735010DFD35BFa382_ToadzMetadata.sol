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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BBase64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in BBase64
/// @notice NOT BUILT BY ETHERORCS (or Toadz) TEAM. Thanks Bretch Devos!
library BBase64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)

               // read 3 bytes
               let input := mload(dataPtr)

               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ToadTraitConstants {

    string constant public SVG_HEADER = '<svg id="toad" width="100%" height="100%" version="1.1" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string constant public SVG_FOOTER = '<style>#toad{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';

    string constant public RARITY = "Rarity";
    string constant public BACKGROUND = "Background";
    string constant public MUSHROOM = "Mushroom";
    string constant public SKIN = "Skin";
    string constant public CLOTHES = "Clothes";
    string constant public MOUTH = "Mouth";
    string constant public EYES = "Eyes";
    string constant public ITEM = "Item";
    string constant public HEAD = "Head";
    string constant public ACCESSORY = "Accessory";

    string constant public RARITY_COMMON = "Common";
    string constant public RARITY_1_OF_1 = "1 of 1";
}

enum ToadRarity {
    COMMON,
    ONE_OF_ONE
}

enum ToadBackground {
    GREY,
    PURPLE,
    GREEN,
    BROWN,
    YELLOW,
    PINK,
    SKY_BLUE,
    MINT,
    ORANGE,
    RED,
    SKY,
    SUNRISE,
    SPRING,
    WATERMELON,
    SPACE,
    CLOUDS,
    SWAMP,
    GOLDEN,
    DARK_PURPLE
}

enum ToadMushroom {
    COMMON,
    ORANGE,
    BROWN,
    RED_SPOTS,
    GREEN,
    BLUE,
    YELLOW,
    GREY,
    PINK,
    ICE,
    GOLDEN,
    RADIOACTIVE,
    CRYSTAL,
    ROBOT
}

enum ToadSkin {
    OG_GREEN,
    BROWN,
    DARK_GREEN,
    ORANGE,
    GREY,
    BLUE,
    PURPLE,
    PINK,
    RAINBOW,
    GOLDEN,
    RADIOACTIVE,
    CRYSTAL,
    SKELETON,
    ROBOT,
    SKIN
}

enum ToadClothes {
    NONE,
    TURTLENECK_BLUE,
    TURTLENECK_GREY,
    T_SHIRT_ROCKET_GREY,
    T_SHIRT_ROCKET_BLUE,
    T_SHIRT_FLY_GREY,
    T_SHIRT_FLY_BLUE,
    T_SHIRT_FLY_RED,
    T_SHIRT_HEART_BLACK,
    T_SHIRT_HEART_PINK,
    T_SHIRT_RAINBOW,
    T_SHIRT_SKULL,
    HOODIE_GREY,
    HOODIE_PINK,
    HOODIE_LIGHT_BLUE,
    HOODIE_DARK_BLUE,
    HOODIE_WHITE,
    T_SHIRT_CAMO,
    HOODIE_CAMO,
    CONVICT,
    ASTRONAUT,
    FARMER,
    RED_OVERALLS,
    GREEN_OVERALLS,
    ZOMBIE,
    SAMURI,
    SAIAN,
    HAWAIIAN_SHIRT,
    SUIT_BLACK,
    SUIT_RED,
    ROCKSTAR,
    PIRATE,
    ASTRONAUT_SUIT,
    CHICKEN_COSTUME,
    DINOSAUR_COSTUME,
    SMOL,
    STRAW_HAT,
    TRACKSUIT
}

enum ToadMouth {
    SMILE,
    O,
    GASP,
    SMALL_GASP,
    LAUGH,
    LAUGH_TEETH,
    SMILE_BIG,
    TONGUE,
    RAINBOW_VOM,
    PIPE,
    CIGARETTE,
    BLUNT,
    MEH,
    GUM,
    FIRE,
    NONE
}

enum ToadEyes {
    RIGHT_UP,
    RIGHT_DOWN,
    TIRED,
    EYE_ROLL,
    WIDE_UP,
    CONTENTFUL,
    LASERS,
    CROAKED,
    SUSPICIOUS,
    WIDE_DOWN,
    BORED,
    STONED,
    HEARTS,
    WINK,
    GLASSES_HEART,
    GLASSES_3D,
    GLASSES_SUN,
    EYE_PATCH_LEFT,
    EYE_PATCH_RIGHT,
    EYE_PATCH_BORED_LEFT,
    EYE_PATCH_BORED_RIGHT,
    EXCITED,
    NONE
}

enum ToadItem {
    NONE,
    LIGHTSABER_RED,
    LIGHTSABER_GREEN,
    LIGHTSABER_BLUE,
    SWORD,
    WAND_LEFT,
    WAND_RIGHT,
    FIRE_SWORD,
    ICE_SWORD,
    AXE_LEFT,
    AXE_RIGHT
}

enum ToadHead {
    NONE,
    CAP_BROWN,
    CAP_BLACK,
    CAP_RED,
    CAP_PINK,
    CAP_MUSHROOM,
    STRAW_HAT,
    SAILOR_HAT,
    PIRATE_HAT,
    WIZARD_PURPLE_HAT,
    WIZARD_BROWN_HAT,
    CAP_KIDS,
    TOP_HAT,
    PARTY_HAT,
    CROWN,
    BRAIN,
    MOHAWK_PURPLE,
    MOHAWK_GREEN,
    MOHAWK_PINK,
    AFRO,
    BACK_CAP_WHITE,
    BACK_CAP_RED,
    BACK_CAP_BLUE,
    BANDANA_PURPLE,
    BANDANA_RED,
    BANDANA_BLUE,
    BEANIE_GREY,
    BEANIE_BLUE,
    BEANIE_YELLOW,
    HALO,
    COOL_CAT_HEAD,
    FIRE
}

enum ToadAccessory {
    NONE,
    FLIES,
    GOLD_CHAIN,
    NECKTIE_RED,
    NECKTIE_BLUE,
    NECKTIE_PINK
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/ToadTraitConstants.sol";

interface IToadzMetadata {
    function tokenURI(uint256 _tokenId) external view returns(string memory);

    function setMetadataForToad(uint256 _tokenId, ToadTraits calldata _traits) external;

    function setHasPurchasedBlueprint(uint256 _tokenId) external;

    function hasPurchasedBlueprint(uint256 _tokenId) external view returns(bool);
}

// Immutable Traits.
// Do not change.
struct ToadTraits {
    ToadRarity rarity;
    ToadBackground background;
    ToadMushroom mushroom;
    ToadSkin skin;
    ToadClothes clothes;
    ToadMouth mouth;
    ToadEyes eyes;
    ToadItem item;
    ToadHead head;
    ToadAccessory accessory;
}

struct ToadTraitStrings {
    string rarity;
    string background;
    string mushroom;
    string skin;
    string clothes;
    string mouth;
    string eyes;
    string item;
    string head;
    string accessory;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "../libraries/BBase64.sol";
import "./ToadzMetadataContracts.sol";

contract ToadzMetadata is Initializable, ToadzMetadataContracts {

    using StringsUpgradeable for uint256;

    function initialize() external initializer {
        ToadzMetadataContracts.__ToadzMetadataContracts_init();
    }

    function hasPurchasedBlueprint(uint256 _tokenId) external view returns(bool) {
        return tokenIdToSettableTraits[_tokenId].hasPurchasedBlueprint;
    }

    function setHasPurchasedBlueprint(uint256 _tokenId) external whenNotPaused onlyAdminOrOwner {
        require(!tokenIdToSettableTraits[_tokenId].hasPurchasedBlueprint, "Already purchased blueprint");

        tokenIdToSettableTraits[_tokenId].hasPurchasedBlueprint = true;

        emit HasPurchasedBlueprintChanged(_tokenId, true);
    }

    function setMetadataForToad(uint256 _tokenId, ToadTraits calldata _traits) external whenNotPaused onlyAdminOrOwner {
        tokenIdToTraits[_tokenId] = _traits;

        emit ToadzMetadataChanged(_tokenId, _toadTraitsToToadTraitStrings(_traits));
    }

    function _toadTraitsToToadTraitStrings(ToadTraits calldata _traits) private view returns(ToadTraitStrings memory) {
        return ToadTraitStrings(
            rarityToString[_traits.rarity],
            backgroundToString[_traits.background],
            mushroomToString[_traits.mushroom],
            skinToString[_traits.skin],
            clothesToString[_traits.clothes],
            mouthToString[_traits.mouth],
            eyesToString[_traits.eyes],
            itemToString[_traits.item],
            headToString[_traits.head],
            accessoryToString[_traits.accessory]
        );
    }

    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        ToadTraits memory _traits = tokenIdToTraits[_tokenId];
        SettableToadTraits memory _settableToadTraits = tokenIdToSettableTraits[_tokenId];

        bytes memory _beginningJSON = _getBeginningJSON(_tokenId);
        string memory _svg = getSVG(_traits);
        string memory _attributes = _getAttributes(_traits, _settableToadTraits);

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                BBase64.encode(
                    bytes(
                        abi.encodePacked(
                            _beginningJSON,
                            _svg,
                            '",',
                            _attributes,
                            '}'
                        )
                    )
                )
            )
        );
    }

    function _getBeginningJSON(uint256 _tokenId) private pure returns(bytes memory) {
        return abi.encodePacked(
            '{"name":"Toad #',
            _tokenId.toString(),
            '", "description":"Toadstoolz is an on-chain toad life simulation NFT game. Toadz love to hunt for $BUGZ, go on adventures and are obsessed with collecting NFTs.", "image": "',
            'data:image/svg+xml;base64,');
    }

    function _getAttributes(ToadTraits memory _traits, SettableToadTraits memory _settableToadTraits) private view returns(string memory) {
        return string(abi.encodePacked(
            '"attributes": [',
                _getTopAttributes(_traits),
                _getBottomAttributes(_traits, _settableToadTraits),
            ']'
        ));
    }

    function _getTopAttributes(ToadTraits memory _traits) private view returns(string memory) {
        return string(abi.encodePacked(
            _getRarityJSON(_traits.rarity), ',',
            _getBackgroundJSON(_traits.background), ',',
            _getMushroomJSON(_traits.mushroom), ',',
            _getSkinJSON(_traits.skin), ',',
            _getClothesJSON(_traits.clothes), ','
        ));
    }

    function _getBottomAttributes(ToadTraits memory _traits, SettableToadTraits memory _settableToadTraits) private view returns(string memory) {
        return string(abi.encodePacked(
            _getMouthJSON(_traits.mouth), ',',
            _getEyesJSON(_traits.eyes), ',',
            _getItemJSON(_traits.item), ',',
            _getHeadJSON(_traits.head), ',',
            _getAccessoryJSON(_traits.accessory), ',',
            _getBlueprintPurchasedJSON(_settableToadTraits.hasPurchasedBlueprint)
        ));
    }

    function _getRarityJSON(ToadRarity _rarity) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.RARITY,
            '","value":"',
            rarityToString[_rarity],
            '"}'
        ));
    }

    function _getBackgroundJSON(ToadBackground _background) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.BACKGROUND,
            '","value":"',
            backgroundToString[_background],
            '"}'
        ));
    }

    function _getMushroomJSON(ToadMushroom _mushroom) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.MUSHROOM,
            '","value":"',
            mushroomToString[_mushroom],
            '"}'
        ));
    }

    function _getSkinJSON(ToadSkin _skin) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.SKIN,
            '","value":"',
            skinToString[_skin],
            '"}'
        ));
    }

    function _getClothesJSON(ToadClothes _clothes) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.CLOTHES,
            '","value":"',
            clothesToString[_clothes],
            '"}'
        ));
    }

    function _getMouthJSON(ToadMouth _mouth) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.MOUTH,
            '","value":"',
            mouthToString[_mouth],
            '"}'
        ));
    }

    function _getEyesJSON(ToadEyes _eyes) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.EYES,
            '","value":"',
            eyesToString[_eyes],
            '"}'
        ));
    }

    function _getItemJSON(ToadItem _item) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.ITEM,
            '","value":"',
            itemToString[_item],
            '"}'
        ));
    }

    function _getHeadJSON(ToadHead _head) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.HEAD,
            '","value":"',
            headToString[_head],
            '"}'
        ));
    }

    function _getAccessoryJSON(ToadAccessory _accessory) private view returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            ToadTraitConstants.ACCESSORY,
            '","value":"',
            accessoryToString[_accessory],
            '"}'
        ));
    }

    function _getBlueprintPurchasedJSON(bool _hasBlueprintBeenPurchased) private pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"Blueprint Purchased","value":"',
            _hasBlueprintBeenPurchased ? "Yes" : "No",
            '"}'
        ));
    }

    function getSVG(ToadTraits memory _traits) public view returns(string memory) {
        return BBase64.encode(bytes(string(abi.encodePacked(
            '<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" xmlns:xhtml="http://www.w3.org/1999/xhtml" style="shape-rendering:crispedges;image-rendering:pixelated;-ms-interpolation-mode:nearest-neighbor">',
            _getTopSVGParts(_traits),
            _getBottomSVGParts(_traits),
            '</svg>'
        ))));
    }

    function _getTopSVGParts(ToadTraits memory _traits) private view returns(string memory) {
        return string(abi.encodePacked(
            _getBackgroundSVGPart(_traits.background),
            _getMushroomSVGPart(_traits.mushroom),
            _getSkinSVGPart(_traits.skin),
            _getClothesSVGPart(_traits.clothes),
            _getAccessorySVGPart(_traits.accessory)
        ));
    }

    function _getBottomSVGParts(ToadTraits memory _traits) private view returns(string memory) {
        return string(abi.encodePacked(
            _getMouthSVGPart(_traits.mouth),
            _getEyesSVGPart(_traits.eyes),
            _getHeadSVGPart(_traits.head),
            _getItemSVGPart(_traits.item)
        ));
    }

    function _getBackgroundSVGPart(ToadBackground _background) private view returns(string memory) {
        return wrapPNG(backgroundToPNG[_background]);
    }

    function _getMushroomSVGPart(ToadMushroom _mushroom) private view returns(string memory) {
        return wrapPNG(mushroomToPNG[_mushroom]);
    }

    function _getSkinSVGPart(ToadSkin _skin) private view returns(string memory) {
        return wrapPNG(skinToPNG[_skin]);
    }

    function _getClothesSVGPart(ToadClothes _clothes) private view returns(string memory) {
        if(_clothes == ToadClothes.NONE) {
            return "";
        }
        return wrapPNG(clothesToPNG[_clothes]);
    }

    function _getMouthSVGPart(ToadMouth _mouth) private view returns(string memory) {
        if(_mouth == ToadMouth.NONE) {
            return "";
        }
        return wrapPNG(mouthToPNG[_mouth]);
    }

    function _getEyesSVGPart(ToadEyes _eyes) private view returns(string memory) {
        if(_eyes == ToadEyes.NONE) {
            return "";
        }
        return wrapPNG(eyesToPNG[_eyes]);
    }

    function _getItemSVGPart(ToadItem _item) private view returns(string memory) {
        if(_item == ToadItem.NONE) {
            return "";
        }
        return wrapPNG(itemToPNG[_item]);
    }

    function _getHeadSVGPart(ToadHead _head) private view returns(string memory) {
        if(_head == ToadHead.NONE) {
            return "";
        }
        return wrapPNG(headToPNG[_head]);
    }

    function _getAccessorySVGPart(ToadAccessory _accessory) private view returns(string memory) {
        if(_accessory == ToadAccessory.NONE) {
            return "";
        }
        return wrapPNG(accessoryToPNG[_accessory]);
    }

    function wrapPNG(string memory _png) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '<foreignObject x="0" y="0" height="64" width="64"><xhtml:img src="data:image/png;base64,',
            _png,
            '"/></foreignObject>'
        ));
    }

    function setTraitStrings(
        string calldata _category,
        uint8[] calldata _traits,
        string[] calldata _strings)
    external
    onlyAdminOrOwner
    {
        require(_traits.length == _strings.length, "ToadzMetadata: Invalid array lengths");

        for(uint256 i = 0; i < _traits.length; i++) {
            if(compareStrings(_category, ToadTraitConstants.BACKGROUND)) {
                backgroundToString[ToadBackground(_traits[i])] = _strings[i];
            } else if(compareStrings(_category, ToadTraitConstants.MUSHROOM)) {
                mushroomToString[ToadMushroom(_traits[i])] = _strings[i];
            } else if(compareStrings(_category, ToadTraitConstants.SKIN)) {
                skinToString[ToadSkin(_traits[i])] = _strings[i];
            } else if(compareStrings(_category, ToadTraitConstants.CLOTHES)) {
                clothesToString[ToadClothes(_traits[i])] = _strings[i];
            } else if(compareStrings(_category, ToadTraitConstants.MOUTH)) {
                mouthToString[ToadMouth(_traits[i])] = _strings[i];
            } else if(compareStrings(_category, ToadTraitConstants.EYES)) {
                eyesToString[ToadEyes(_traits[i])] = _strings[i];
            } else if(compareStrings(_category, ToadTraitConstants.ITEM)) {
                itemToString[ToadItem(_traits[i])] = _strings[i];
            } else if(compareStrings(_category, ToadTraitConstants.HEAD)) {
                headToString[ToadHead(_traits[i])] = _strings[i];
            } else if(compareStrings(_category, ToadTraitConstants.ACCESSORY)) {
                accessoryToString[ToadAccessory(_traits[i])] = _strings[i];
            } else {
                revert("ToadzMetadata: Invalid category");
            }
        }
    }

    function setPNGData(
        string calldata _category,
        uint8[] calldata _traits,
        string[] calldata _pngDatas)
    external
    onlyAdminOrOwner
    {
        require(_traits.length == _pngDatas.length, "ToadzMetadata: Invalid array lengths");

        for(uint256 i = 0; i < _traits.length; i++) {
            if(compareStrings(_category, ToadTraitConstants.BACKGROUND)) {
                backgroundToPNG[ToadBackground(_traits[i])] = _pngDatas[i];
            } else if(compareStrings(_category, ToadTraitConstants.MUSHROOM)) {
                mushroomToPNG[ToadMushroom(_traits[i])] = _pngDatas[i];
            } else if(compareStrings(_category, ToadTraitConstants.SKIN)) {
                skinToPNG[ToadSkin(_traits[i])] = _pngDatas[i];
            } else if(compareStrings(_category, ToadTraitConstants.CLOTHES)) {
                clothesToPNG[ToadClothes(_traits[i])] = _pngDatas[i];
            } else if(compareStrings(_category, ToadTraitConstants.MOUTH)) {
                mouthToPNG[ToadMouth(_traits[i])] = _pngDatas[i];
            } else if(compareStrings(_category, ToadTraitConstants.EYES)) {
                eyesToPNG[ToadEyes(_traits[i])] = _pngDatas[i];
            } else if(compareStrings(_category, ToadTraitConstants.ITEM)) {
                itemToPNG[ToadItem(_traits[i])] = _pngDatas[i];
            } else if(compareStrings(_category, ToadTraitConstants.HEAD)) {
                headToPNG[ToadHead(_traits[i])] = _pngDatas[i];
            } else if(compareStrings(_category, ToadTraitConstants.ACCESSORY)) {
                accessoryToPNG[ToadAccessory(_traits[i])] = _pngDatas[i];
            } else {
                revert("ToadzMetadata: Invalid category");
            }
        }
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ToadzMetadataState.sol";

abstract contract ToadzMetadataContracts is Initializable, ToadzMetadataState {

    function __ToadzMetadataContracts_init() internal initializer {
        ToadzMetadataState.__ToadzMetadataState_init();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./IToadzMetadata.sol";
import "../../shared/AdminableUpgradeable.sol";
import "../libraries/ToadTraitConstants.sol";

abstract contract ToadzMetadataState is Initializable, IToadzMetadata, AdminableUpgradeable {

    event ToadzMetadataChanged(uint256 indexed _tokenId, ToadTraitStrings _traits);
    event HasPurchasedBlueprintChanged(uint256 indexed _tokenId, bool _hasPurchasedBlueprint);

    mapping(uint256 => ToadTraits) public tokenIdToTraits;

    mapping(ToadRarity => string) public rarityToString;
    mapping(ToadBackground => string) public backgroundToString;
    mapping(ToadMushroom => string) public mushroomToString;
    mapping(ToadSkin => string) public skinToString;
    mapping(ToadClothes => string) public clothesToString;
    mapping(ToadMouth => string) public mouthToString;
    mapping(ToadEyes => string) public eyesToString;
    mapping(ToadItem => string) public itemToString;
    mapping(ToadHead => string) public headToString;
    mapping(ToadAccessory => string) public accessoryToString;

    mapping(ToadBackground => string) public backgroundToPNG;
    mapping(ToadMushroom => string) public mushroomToPNG;
    mapping(ToadSkin => string) public skinToPNG;
    mapping(ToadClothes => string) public clothesToPNG;
    mapping(ToadMouth => string) public mouthToPNG;
    mapping(ToadEyes => string) public eyesToPNG;
    mapping(ToadItem => string) public itemToPNG;
    mapping(ToadHead => string) public headToPNG;
    mapping(ToadAccessory => string) public accessoryToPNG;

    mapping(uint256 => SettableToadTraits) public tokenIdToSettableTraits;

    function __ToadzMetadataState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();

        rarityToString[ToadRarity.COMMON] = ToadTraitConstants.RARITY_COMMON;
        rarityToString[ToadRarity.ONE_OF_ONE] = ToadTraitConstants.RARITY_1_OF_1;
    }
}

// For toad metadata that may be set post mint.
//
struct SettableToadTraits {
    bool hasPurchasedBlueprint;
    uint248 emptySpace;
}