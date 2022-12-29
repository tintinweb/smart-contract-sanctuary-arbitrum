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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// Abstract contract that implements access check functions
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../../interfaces/admin/IEntity.sol";
import "../../interfaces/access/IDAOAuthority.sol";

abstract contract DAOAccessControlled is Context {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IDAOAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IDAOAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IDAOAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAuthority() {
        require(address(authority) == _msgSender(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyGovernor() {
        require(authority.governor() == _msgSender(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(authority.policy() == _msgSender(), UNAUTHORIZED);
        _;
    }

    modifier onlyAdmin() {
        require(authority.admin() == _msgSender(), UNAUTHORIZED);
        _;
    }

    modifier onlyEntityAdmin(address _entity) {
        require(IEntity(_entity).getEntityAdminDetails(_msgSender()).isActive, UNAUTHORIZED);
        _;
    }

    modifier onlyBartender(address _entity) {
        require(IEntity(_entity).getBartenderDetails(_msgSender()).isActive, UNAUTHORIZED);
        _;
    }
         
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IDAOAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    /* ========= ERC2771 ============ */
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == authority.forwarder();
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    modifier onlyForwarder() {
        // this modifier must check msg.sender directly (not through _msgSender()!)
        require(isTrustedForwarder(msg.sender), UNAUTHORIZED);
        _;
    }
}

/**************************************************************************************************************
    This is an administrative contract for entities(brands, establishments or partners)
    in the DAO eco-system. The contract is spinned up by the DAO Governor using the Entity Factory.
    An Entity Admin is set up on each contract to perform managerial tasks for the entity.
**************************************************************************************************************/
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/admin/IEntity.sol";
import "../access/DAOAccessControlled.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../../interfaces/access/IDAOAuthority.sol";
import "../../interfaces/collectibles/ICollectible.sol";

contract Entity is IEntity, DAOAccessControlled {

    using Counters for Counters.Counter;

    // Unique Ids for Operator
    Counters.Counter private operatorIds;  

    // Area where the entity is located
    Area area;

    // Entity wallet address
    address public walletAddress;
    
    // Flag to indicate whether entity is active or not
    bool public isActive;

    // Data URI where file containing entity details resides
    string public dataURI;

    // List of all admins for this entity
    address[] public entityAdmins;

    // List of all bartenders for this entity
    address[] public bartenders;

    // List of all collectibles linked to this entity
    address[] public collectibles;

    // List of whitelisted third-party collectible contracts 
    ContractDetails[] public whitelistedCollectibles;
    
    // (address => chainId => index) 1-based index lookup for third-party collectibles whitelisting/delisting
    mapping( address => mapping( uint256 => uint256 ) ) whitelistedCollectiblesLookup;

    // Blacklisted patrons
    mapping( address => BlacklistDetails ) public blacklist;

    // Entity Admin Address => Entity Admin Details
    mapping( address => Operator ) entityAdminDetails;

    // Bartender Address => Bartender Details
    mapping( address => Operator ) bartenderDetails;

    constructor(
        Area memory _area,
        string memory _dataURI,
        address _walletAddress,
        address _authority
    ) DAOAccessControlled(IDAOAuthority(_authority)){
        area = _area;
        dataURI = _dataURI;
        walletAddress = _walletAddress;
        isActive = true;

        operatorIds.increment(); // Start from 1 as 0 is used for existence check
    }

    /******************************************************************************************
    // Allows the DAO administration to enable/disable an entity.
    // When an entity is disabled all collectibles for the given entity are also retired.
    // Enabling the same entity back again will need configuration of new Collectibles.
    /******************************************************************************************/
    function toggleEntity() external onlyGovernor returns(bool _status) {

        // Activates/deactivates the entity
        isActive = !isActive;

        // Poll status to pass as return value
        _status = isActive;

        // If the entity was deactivated, then disable all collectibles for it
        if(!_status) {

            for(uint256 i = 0; i < collectibles.length; i++) {
                ICollectible(collectibles[i]).retire();
            }
        }

        // Emit an entity toggling event with relevant details
        emit EntityToggled(address(this), _status);
    }

    // Allows DAO Operator to modify the data for an entity
    // Entity area, wallet address and ipfs location can be modified
    function updateEntity(
        Area memory _area,
        string memory _dataURI,
        address _walletAddress
    ) external onlyGovernor {

        area = _area;
        dataURI = _dataURI;
        walletAddress = _walletAddress;

        // Emit an event for entity updation with the relevant details
        emit EntityUpdated(address(this), _area, _dataURI, _walletAddress);
    }

    // Adds a new collectible linked to the entity
    function addCollectibleToEntity(address _collectible) external onlyEntityAdmin(address(this)) {

        collectibles.push(_collectible);

        // Emit a collectible addition event with entity details and collectible address
        emit CollectibleAdded(address(this), _collectible);
    }

    // Grants entity admin role for an entity to a given wallet address
    function addEntityAdmin(address _entAdmin, string memory _dataURI) external onlyGovernor {

        // Admin cannot be zero address
        require(_entAdmin != address(0), "ZERO ADDRESS");

        // Check if address already an entity admin
        require(entityAdminDetails[_entAdmin].id == 0, "ADDRESS ALREADY ADMIN FOR ENTITY");

        // Add entity admin to list of admins
        entityAdmins.push(_entAdmin);

        // Set details for the entity admin
        // Data Loc for admin details: dataURI, "/admins/" , adminId
        entityAdminDetails[_entAdmin] = Operator({
            id: operatorIds.current(),
            dataURI: _dataURI,
            isActive: true
        });

        // Increment the Id for next admin addition
        operatorIds.increment();

        // Emit event to signal grant of entity admin role to an address
        emit EntityAdminGranted(address(this), _entAdmin);
    }

    // Grants bartender role for an entity to a given wallet address
    function addBartender(address _bartender, string memory _dataURI) external onlyEntityAdmin(address(this)) {
        
        // Bartender cannot be zero address
        require(_bartender != address(0), "ZERO ADDRESS");

        // Check if address already an entity admin
        require(bartenderDetails[_bartender].id == 0, "ADDRESS ALREADY BARTENDER FOR ENTITY");

        // Add bartender to list of bartenders
        bartenders.push(_bartender);

        // Set details for the bartender
        // Data Loc for admin details: dataURI, "/admins/" , adminId
        bartenderDetails[_bartender] = Operator({
            id: operatorIds.current(),
            dataURI: _dataURI,
            isActive: true
        });

        // Increment the Id for next admin addition
        operatorIds.increment();

        // Emit event to signal grant of bartender role to an address
        emit BartenderGranted(address(this), _bartender);
    }

    function toggleEntityAdmin(address _entAdmin) external onlyGovernor returns(bool _status) {

        require(entityAdminDetails[_entAdmin].id != 0, "No such entity admin for this entity");
    
        entityAdminDetails[_entAdmin].isActive = !entityAdminDetails[_entAdmin].isActive;

        // Poll status to pass as return value
        _status = entityAdminDetails[_entAdmin].isActive;

        // Emit event to signal toggling of entity admin role
        emit EntityAdminToggled(address(this), _entAdmin, _status);
    }

    function toggleBartender(address _bartender) external onlyEntityAdmin(address(this)) returns(bool _status) {
        
        require(bartenderDetails[_bartender].id != 0, "No such bartender for this entity");

        bartenderDetails[_bartender].isActive = !bartenderDetails[_bartender].isActive;

        // Poll status to pass as return value
        _status = bartenderDetails[_bartender].isActive;

        // Emit event to signal toggling of bartender role
        emit BartenderToggled(address(this), _bartender, _status);
    }

    function getEntityAdminDetails(address _entAdmin) public view returns(Operator memory) {
        return entityAdminDetails[_entAdmin];
    }

    function getBartenderDetails(address _bartender) public view returns(Operator memory) {
        return bartenderDetails[_bartender];
    }

    function addPatronToBlacklist(address _patron, uint256 _end) external onlyEntityAdmin(address(this)) {
        blacklist[_patron] = BlacklistDetails({
            end: _end
        });
    }

    function removePatronFromBlacklist(address _patron) external onlyEntityAdmin(address(this)) {
        require(blacklist[_patron].end > 0, "Patron not blacklisted");
        blacklist[_patron].end = 0;
    }

    /**
     * @notice          add an address to third-party collectibles whitelist
     * @param _source   collectible contract address
     * @param _chainId  chainId where contract is deployed
     */
    function whitelistCollectible(address _source, uint256 _chainId) onlyEntityAdmin(address(this)) external {
        uint256 index = whitelistedCollectiblesLookup[_source][_chainId];
        require(index == 0, "Collectible already whitelisted");

        whitelistedCollectibles.push(ContractDetails({
            source: _source,
            chainId: _chainId
        }));

        whitelistedCollectiblesLookup[_source][_chainId] = whitelistedCollectibles.length; // store as 1-based index
        emit CollectibleWhitelisted(address(this), _source, _chainId);
    }

    /**
     * @notice          remove an address from third-party collectibles whitelist
     * @param _source   collectible contract address
     * @param _chainId  chainId where contract is deployed
     */
    function delistCollectible(address _source, uint256 _chainId) onlyEntityAdmin(address(this)) external {
        uint256 index = whitelistedCollectiblesLookup[_source][_chainId];
        require(index > 0, "Collectible is not whitelisted");

        delete whitelistedCollectibles[index - 1]; // convert to 0-based index
        delete whitelistedCollectiblesLookup[_source][_chainId];

        emit CollectibleDelisted(address(this), _source, _chainId);
    }

    function getLocationDetails() public view returns(string[] memory, uint256) {
        return (area.points, area.radius);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../admin/Entity.sol";
import "../access/DAOAccessControlled.sol";
import "../../interfaces/factories/IEntityFactory.sol";

contract EntityFactory is IEntityFactory, DAOAccessControlled {

    // List of all entities
    address[] public allEntities;

    // Used to check for existence of an entity in the DAO eco-system
    mapping(address => bool) public entityExists;

    constructor(
        address _authority
    ) DAOAccessControlled(IDAOAuthority(_authority)) {
     
    }

    function createEntity( 
        Area memory _area,
        string memory _dataURI,
        address _walletAddress
    ) external onlyGovernor returns (address _entity) {

        bytes memory bytecode = abi.encodePacked(
                                    type(Entity).creationCode, 
                                    abi.encode(
                                        _area,
                                        _dataURI,
                                        _walletAddress
                                    )
                                );

        bytes32 salt = keccak256(abi.encodePacked(_walletAddress));

        assembly {
            _entity := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        allEntities.push(_entity);

        entityExists[_entity] =  true;

        emit CreatedEntity(_entity);
    }

    function isDAOEntity(address _entity) public view returns(bool) {
        return entityExists[_entity];
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IDAOAuthority {

    /*********** EVENTS *************/
    event ChangedGovernor(address);
    event ChangedPolicy(address);
    event ChangedAdmin(address);
    event ChangedForwarder(address);

    function governor() external returns(address);
    function policy() external returns(address);
    function admin() external returns(address);
    function forwarder() external view returns(address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/location/ILocationBased.sol";

interface IEntity is ILocationBased {

    /* ========== EVENTS ========== */
    event EntityToggled(address _entity, bool _status);
    event EntityUpdated(address _entity, Area _area, string _dataURI, address _walletAddress);
    event EntityAdminGranted(address _entity, address _entAdmin);
    event BartenderGranted(address _entity, address _bartender);
    event EntityAdminToggled(address _entity, address _entAdmin, bool _status);
    event BartenderToggled(address _entity, address _bartender, bool _status);
    event CollectibleAdded(address _entity, address _collectible);

    event CollectibleWhitelisted(address indexed _entity, address indexed _collectible, uint256 indexed _chainId);
    event CollectibleDelisted(address indexed _entity, address indexed _collectible, uint256 indexed _chainId);

    struct Operator {
        uint256 id;
        string dataURI;
        bool isActive;
    }

    struct BlacklistDetails {
        // Timestamp after which the patron should be removed from blacklist
        uint256 end; 
    }

    struct ContractDetails {
        // Contract address
        address source;

        // ChainId where the contract deployed
        uint256 chainId;
    }

    function updateEntity(
        Area memory _area,
        string memory _dataURI,
        address _walletAddress
    ) external;

    function toggleEntity() external returns(bool _status);

    function addCollectibleToEntity(address _collectible) external;

    function addEntityAdmin(address _entAdmin, string memory _dataURI) external;

    function addBartender(address _bartender, string memory _dataURI) external;

    function toggleEntityAdmin(address _entAdmin) external returns(bool _status);

    function toggleBartender(address _bartender) external returns(bool _status);

    function getEntityAdminDetails(address _entAdmin) external view returns(Operator memory);

    function getBartenderDetails(address _bartender) external view returns(Operator memory);

    function addPatronToBlacklist(address _patron, uint256 _end) external;

    function removePatronFromBlacklist(address _patron) external;

    function whitelistedCollectibles(uint256 index) external view returns(address, uint256);

    function whitelistCollectible(address _source, uint256 _chainId) external;

    function delistCollectible(address _source, uint256 _chainId) external;

    function getLocationDetails() external view returns(string[] memory, uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/location/ILocationBased.sol";

interface ICollectible is ILocationBased {

    event CollectibleMinted (
        uint256 _collectibleId,
        address _patron,
        uint256 _expiry,
        bool _transferable,
        string _tokenURI
    );

    event CollectibleToggled(uint256 _collectibleId, bool _status);

    event CollectiblesLinked(address, address);

    event CreditRewardsToCollectible(uint256 _collectibleId, address _patron, uint256 _amount);

    event BurnRewardsFromCollectible(uint256 _collectibleId, address _patron, uint256 _amount);

    event RetiredCollectible(address _collectible);

    event Visited(uint256 _collectibleId);

    event FriendVisited(uint256 _collectibleId);

    enum CollectibleType {
        PASSPORT,
        OFFER,
        DIGITALCOLLECTIBLE,
        BADGE
    }

    struct CollectibleDetails {
        uint256 id;
        uint256 mintTime; // timestamp
        uint256 expiry; // timestamp
        bool isActive;
        bool transferable;
        int256 rewardBalance; // used for passports only
        uint256 visits; // // used for passports only
        uint256 friendVisits; // used for passports only
        // A flag indicating whether the collectible was redeemed
        // This can be useful in scenarios such as cancellation of orders
        // where the the NFT minted to patron is supposed to be burnt/demarcated
        // in some way when the payment is reversed to patron
        bool redeemed;
    }

    function mint (
        address _patron,
        uint256 _expiry,
        bool _transferable
    ) external returns (uint256);

    // Activates/deactivates the collectible
    function toggle(uint256 _collectibleId) external returns(bool _status);

    function retire() external;

    function creditRewards(address _patron, uint256 _amount) external;

    function debitRewards(address _patron, uint256 _amount) external;

    function addVisit(uint256 _collectibleId) external;

    function addFriendsVisit(uint256 _collectibleId) external;

    function isRetired(address _patron) external view returns(bool);

    function getPatronNFT(address _patron) external view returns(uint256);

    function getNFTDetails(uint256 _nftId) external view returns(CollectibleDetails memory);

    function linkCollectible(address _collectible) external;

    function completeOrder(uint256 _offerId) external;

    function rewards() external returns(uint256);

    function getLinkedCollectibles() external returns(address[] memory);

    function collectibleType() external returns(CollectibleType);

    function getLocationDetails() external view returns(string[] memory, uint256);

    function ownerOf(uint256 tokenId) external view returns(address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/location/ILocationBased.sol";

interface IEntityFactory is ILocationBased {

    /* ========== EVENTS ========== */
    event CreatedEntity(address _entity);

    function createEntity( 
        Area memory _area,
        string memory _dataURI,
        address _walletAddress
    ) external returns (address _entity);

    function isDAOEntity(address _entity) external view returns(bool);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILocationBased {

    struct Area {
        // Area Co-ordinates.
        // For circular area, points[] length = 1 and radius > 0
        // For arbitrary area, points[] length > 1 and radius = 0
        // For arbitrary areas UI should connect the points with a
        // straight line in the same sequence as specified in the points array
        string[] points; // Each element in this array should be specified in "lat,long" format
        uint256 radius; // Unit: Meters. 2 decimals(5000 = 50 meters)
    }
    
}