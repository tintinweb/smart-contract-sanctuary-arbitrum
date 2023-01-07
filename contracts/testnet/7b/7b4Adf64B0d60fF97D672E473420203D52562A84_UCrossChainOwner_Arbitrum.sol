// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/crosschain/CrossChainEnabled.sol";
import "../UOwnable.sol";
import "../../../storage/UStorage.sol";

/**
 * @title UCrossChainOwnable
 * @notice Library to manage the cross-chain ownership lifecycle of upgradeable contracts.
 * @dev This contract has been extended from the Open Zeppelin library to include an
 *      unstructured storage pattern so that it can be safely mixed in with upgradeable
 *      contracts without affecting their storage patterns through inheritance.
 *
 *      Upon initialization, the `owner` will be set to the `msg.sender` of the initialize method.
 *      Ownership should then be transferred to the cross-chain owner via the `updatePendingOwner`
 *      and `acceptedPending` owner methods. Upon accepting ownership via the cross-chain address,
 *      a fuse will be tripped, preventing same-chain ownership going forward.
 */
abstract contract UCrossChainOwnable is UOwnable, CrossChainEnabled {
    BoolStorage private constant _crossChainRestricted = BoolStorage.wrap(keccak256("equilibria.root.UCrossChainOwnable.crossChainRestricted"));
    function crossChainRestricted() public view returns (bool) { return _crossChainRestricted.read(); }

    function _beforeAcceptOwner() internal override {
        if (!crossChainRestricted()) _crossChainRestricted.store(true);
    }

    function _sender() internal view override returns (address) {
        if (crossChainRestricted()) return _crossChainSender();
        return msg.sender;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/crosschain/arbitrum/CrossChainEnabledArbitrumL2.sol";
import "./UCrossChainOwnable.sol";

/**
 * @title UCrossChainOwnable_Arbitrum
 * @notice Library to manage the cross-chain ownership lifecycle of Arbitrum upgradeable contracts.
 * @dev This contract has been extended from the Open Zeppelin library to include an
 *      unstructured storage pattern so that it can be safely mixed in with upgradeable
 *      contracts without affecting their storage patterns through inheritance. This contract
 *      is specific to the Arbitrum L2-side and should not be used on other chains.
 *
 *      See {UCrossChainOwnable} for initialization and update usage.
 */
abstract contract UCrossChainOwnable_Arbitrum is CrossChainEnabledArbitrumL2, UCrossChainOwnable {
    constructor() CrossChainEnabledArbitrumL2() {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "../CrossChainOwnable/UCrossChainOwnable.sol";

/**
 * @title UCrossChainOwner
 * @notice Contract to act as an owner of other contracts
 * @dev This contract is designed to act as an owner of any Ownable contract, allowing
 *      Cross Chain Ownership without modification to the underlying ownable contract
 */
abstract contract UCrossChainOwner is UCrossChainOwnable {
    function initialize() external initializer(1) {
        super.__UOwnable__initialize();
    }

    function execute(
        address payable to,
        bytes memory data,
        uint256 value
    ) payable external onlyOwner returns (bytes memory ret) {
        if (data.length == 0) {
            Address.sendValue(to, value);
        } else {
            ret = Address.functionCallWithValue(to, data, value);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../CrossChainOwnable/UCrossChainOwnable_Arbitrum.sol";
import "./UCrossChainOwner.sol";

/**
 * @title UCrossChainOwner_Arbitrum
 * @notice Contract to act as an owner of other contracts
 * @dev This contract is designed to act as an owner of any Ownable contract, allowing
 *      Cross Chain Ownership without modification to the underlying ownable contract. This contract
 *      is specific to the Arbitrum L2-side and should not be used on other chains.
 *
 *      See {UCrossChainOwner} for initialization and usage.
 */
contract UCrossChainOwner_Arbitrum is UCrossChainOwner, UCrossChainOwnable_Arbitrum { }

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../storage/UStorage.sol";

/**
 * @title UInitializable
 * @notice Library to manage the initialization lifecycle of upgradeable contracts
 * @dev `UInitializable` allows the creation of pseudo-constructors for upgradeable contracts. One
 *      `initializer` should be declared per top-level contract. Child contracts can use the `onlyInitializer`
 *      modifier to tag their internal initialization functions to ensure that they can only be called
 *      from a top-level `initializer` or a constructor.
 */
abstract contract UInitializable {
    error UInitializableZeroVersionError();
    error UInitializableAlreadyInitializedError(uint256 version);
    error UInitializableNotInitializingError();

    event Initialized(uint256 version);

    /// @dev The initialized flag
    Uint256Storage private constant _version = Uint256Storage.wrap(keccak256("equilibria.root.UInitializable.version"));

    /// @dev The initializing flag
    BoolStorage private constant _initializing = BoolStorage.wrap(keccak256("equilibria.root.UInitializable.initializing"));

    /// @dev Can only be called once per version, `version` is 1-indexed
    modifier initializer(uint256 version) {
        if (version == 0) revert UInitializableZeroVersionError();
        if (_version.read() >= version) revert UInitializableAlreadyInitializedError(version);

        _version.store(version);
        _initializing.store(true);

        _;

        _initializing.store(false);
        emit Initialized(version);
    }

    /// @dev Can only be called from an initializer or constructor
    modifier onlyInitializer() {
        if (!_constructing() && !_initializing.read()) revert UInitializableNotInitializingError();
        _;
    }

    /**
     * @notice Returns whether the contract is currently being constructed
     * @dev {Address.isContract} returns false for contracts currently in the process of being constructed
     * @return Whether the contract is currently being constructed
     */
    function _constructing() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./UInitializable.sol";
import "../../storage/UStorage.sol";

/**
 * @title UOwnable
 * @notice Library to manage the ownership lifecycle of upgradeable contracts.
 * @dev This contract has been extended from the Open Zeppelin library to include an
 *      unstructured storage pattern so that it can be safely mixed in with upgradeable
 *      contracts without affecting their storage patterns through inheritance.
 */
abstract contract UOwnable is UInitializable {
    event OwnerUpdated(address indexed newOwner);
    event PendingOwnerUpdated(address indexed newPendingOwner);

    error UOwnableNotOwnerError(address sender);
    error UOwnableNotPendingOwnerError(address sender);

    /// @dev The owner address
    AddressStorage private constant _owner = AddressStorage.wrap(keccak256("equilibria.root.UOwnable.owner"));
    function owner() public view returns (address) { return _owner.read(); }

    /// @dev The pending owner address
    AddressStorage private constant _pendingOwner = AddressStorage.wrap(keccak256("equilibria.root.UOwnable.pendingOwner"));
    function pendingOwner() public view returns (address) { return _pendingOwner.read(); }

    /**
     * @notice Initializes the contract setting `msg.sender` as the initial owner
     */
    function __UOwnable__initialize() internal onlyInitializer {
        _updateOwner(_sender());
    }

    /**
     * @notice Updates the new pending owner
     * @dev Can only be called by the current owner
     *      New owner does not take affect until that address calls `acceptOwner()`
     * @param newPendingOwner New pending owner address
     */
    function updatePendingOwner(address newPendingOwner) public onlyOwner {
        _pendingOwner.store(newPendingOwner);
        emit PendingOwnerUpdated(newPendingOwner);
    }

    /**
     * @notice Accepts and transfers the ownership of the contract to the pending owner
     * @dev Can only be called by the pending owner to ensure correctness. Calls to the `_beforeAcceptOwner` hook
     *      to perform logic before updating ownership.
     */
    function acceptOwner() public {
        _beforeAcceptOwner();

        if (_sender() != pendingOwner()) revert UOwnableNotPendingOwnerError(_sender());

        _updateOwner(pendingOwner());
        updatePendingOwner(address(0));
    }


    /// @dev Hook for inheriting contracts to perform logic before accepting ownership
    function _beforeAcceptOwner() internal virtual {}

    /**
     * @notice Updates the owner address
     * @param newOwner New owner address
     */
    function _updateOwner(address newOwner) private {
        _owner.store(newOwner);
        emit OwnerUpdated(newOwner);
    }

    function _sender() internal view virtual returns (address) {
        return msg.sender;
    }

    /// @dev Throws if called by any account other than the owner
    modifier onlyOwner {
        if (owner() != _sender()) revert UOwnableNotOwnerError(_sender());
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "./UFixed18.sol";
import "./PackedFixed18.sol";

/// @dev Fixed18 type
type Fixed18 is int256;
using Fixed18Lib for Fixed18 global;
type Fixed18Storage is bytes32;
using Fixed18StorageLib for Fixed18Storage global;

/**
 * @title Fixed18Lib
 * @notice Library for the signed fixed-decimal type.
 */
library Fixed18Lib {
    error Fixed18OverflowError(uint256 value);
    error Fixed18PackingOverflowError(int256 value);
    error Fixed18PackingUnderflowError(int256 value);

    int256 private constant BASE = 1e18;
    Fixed18 public constant ZERO = Fixed18.wrap(0);
    Fixed18 public constant ONE = Fixed18.wrap(BASE);
    Fixed18 public constant NEG_ONE = Fixed18.wrap(-1 * BASE);
    Fixed18 public constant MAX = Fixed18.wrap(type(int256).max);
    Fixed18 public constant MIN = Fixed18.wrap(type(int256).min);

    /**
     * @notice Creates a signed fixed-decimal from an unsigned fixed-decimal
     * @param a Unsigned fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed18 a) internal pure returns (Fixed18) {
        uint256 value = UFixed18.unwrap(a);
        if (value > uint256(type(int256).max)) revert Fixed18OverflowError(value);
        return Fixed18.wrap(int256(value));
    }

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param s Sign
     * @param m Unsigned fixed-decimal magnitude
     * @return New signed fixed-decimal
     */
    function from(int256 s, UFixed18 m) internal pure returns (Fixed18) {
        if (s > 0) return from(m);
        if (s < 0) return Fixed18.wrap(-1 * Fixed18.unwrap(from(m)));
        return ZERO;
    }

    /**
     * @notice Creates a signed fixed-decimal from a signed integer
     * @param a Signed number
     * @return New signed fixed-decimal
     */
    function from(int256 a) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE);
    }

    /**
     * @notice Creates a packed signed fixed-decimal from an signed fixed-decimal
     * @param a signed fixed-decimal
     * @return New packed signed fixed-decimal
     */
    function pack(Fixed18 a) internal pure returns (PackedFixed18) {
        int256 value = Fixed18.unwrap(a);
        if (value > type(int128).max) revert Fixed18PackingOverflowError(value);
        if (value < type(int128).min) revert Fixed18PackingUnderflowError(value);
        return PackedFixed18.wrap(int128(value));
    }

    /**
     * @notice Returns whether the signed fixed-decimal is equal to zero.
     * @param a Signed fixed-decimal
     * @return Whether the signed fixed-decimal is zero.
     */
    function isZero(Fixed18 a) internal pure returns (bool) {
        return Fixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting summed signed fixed-decimal
     */
    function add(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) + Fixed18.unwrap(b));
    }

    /**
     * @notice Subtracts signed fixed-decimal `b` from `a`
     * @param a Signed fixed-decimal to subtract from
     * @param b Signed fixed-decimal to subtract
     * @return Resulting subtracted signed fixed-decimal
     */
    function sub(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) - Fixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mul(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function div(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * BASE / Fixed18.unwrap(b));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed18 a, int256 b, int256 c) internal pure returns (Fixed18) {
        return muldiv(a, Fixed18.wrap(b), Fixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed18 a, Fixed18 b, Fixed18 c) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / Fixed18.unwrap(c));
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the signed fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(Fixed18 a, Fixed18 b) internal pure returns (uint256) {
        (int256 au, int256 bu) = (Fixed18.unwrap(a), Fixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a signed fixed-decimal representing the ratio of `a` over `b`
     * @param a First signed number
     * @param b Second signed number
     * @return Ratio of `a` over `b`
     */
    function ratio(int256 a, int256 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(SignedMath.min(Fixed18.unwrap(a), Fixed18.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(SignedMath.max(Fixed18.unwrap(a), Fixed18.unwrap(b)));
    }

    /**
     * @notice Converts the signed fixed-decimal into an integer, truncating any decimal portion
     * @param a Signed fixed-decimal
     * @return Truncated signed number
     */
    function truncate(Fixed18 a) internal pure returns (int256) {
        return Fixed18.unwrap(a) / BASE;
    }

    /**
     * @notice Returns the sign of the signed fixed-decimal
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a Signed fixed-decimal
     * @return Sign of the signed fixed-decimal
     */
    function sign(Fixed18 a) internal pure returns (int256) {
        if (Fixed18.unwrap(a) > 0) return 1;
        if (Fixed18.unwrap(a) < 0) return -1;
        return 0;
    }

    /**
     * @notice Returns the absolute value of the signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return Absolute value of the signed fixed-decimal
     */
    function abs(Fixed18 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(SignedMath.abs(Fixed18.unwrap(a)));
    }
}

library Fixed18StorageLib {
    function read(Fixed18Storage self) internal view returns (Fixed18 value) {
        assembly {
            value := sload(self)
        }
    }

    function store(Fixed18Storage self, Fixed18 value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./Fixed18.sol";

/// @dev PackedFixed18 type
type PackedFixed18 is int128;
using PackedFixed18Lib for PackedFixed18 global;

/**
 * @title PackedFixed18Lib
 * @dev A packed version of the Fixed18 which takes up half the storage space (two PackedFixed18 can be packed
 *      into a single slot). Only valid within the range -1.7014118e+20 <= x <= 1.7014118e+20.
 * @notice Library for the packed signed fixed-decimal type.
 */
library PackedFixed18Lib {
    PackedFixed18 public constant MAX = PackedFixed18.wrap(type(int128).max);
    PackedFixed18 public constant MIN = PackedFixed18.wrap(type(int128).min);

    /**
     * @notice Creates an unpacked signed fixed-decimal from a packed signed fixed-decimal
     * @param self packed signed fixed-decimal
     * @return New unpacked signed fixed-decimal
     */
    function unpack(PackedFixed18 self) internal pure returns (Fixed18) {
        return Fixed18.wrap(int256(PackedFixed18.unwrap(self)));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./UFixed18.sol";

/// @dev PackedUFixed18 type
type PackedUFixed18 is uint128;
using PackedUFixed18Lib for PackedUFixed18 global;

/**
 * @title PackedUFixed18Lib
 * @dev A packed version of the UFixed18 which takes up half the storage space (two PackedUFixed18 can be packed
 *      into a single slot). Only valid within the range 0 <= x <= 3.4028237e+20.
 * @notice Library for the packed unsigned fixed-decimal type.
 */
library PackedUFixed18Lib {
    PackedUFixed18 public constant MAX = PackedUFixed18.wrap(type(uint128).max);

    /**
     * @notice Creates an unpacked unsigned fixed-decimal from a packed unsigned fixed-decimal
     * @param self packed unsigned fixed-decimal
     * @return New unpacked unsigned fixed-decimal
     */
    function unpack(PackedUFixed18 self) internal pure returns (UFixed18) {
        return UFixed18.wrap(uint256(PackedUFixed18.unwrap(self)));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Fixed18.sol";
import "./PackedUFixed18.sol";

/// @dev UFixed18 type
type UFixed18 is uint256;
using UFixed18Lib for UFixed18 global;
type UFixed18Storage is bytes32;
using UFixed18StorageLib for UFixed18Storage global;

/**
 * @title UFixed18Lib
 * @notice Library for the unsigned fixed-decimal type.
 */
library UFixed18Lib {
    error UFixed18UnderflowError(int256 value);
    error UFixed18PackingOverflowError(uint256 value);

    uint256 private constant BASE = 1e18;
    UFixed18 public constant ZERO = UFixed18.wrap(0);
    UFixed18 public constant ONE = UFixed18.wrap(BASE);
    UFixed18 public constant MAX = UFixed18.wrap(type(uint256).max);

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(Fixed18 a) internal pure returns (UFixed18) {
        int256 value = Fixed18.unwrap(a);
        if (value < 0) revert UFixed18UnderflowError(value);
        return UFixed18.wrap(uint256(value));
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a unsigned integer
     * @param a Unsigned number
     * @return New unsigned fixed-decimal
     */
    function from(uint256 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE);
    }

    /**
     * @notice Creates a packed unsigned fixed-decimal from an unsigned fixed-decimal
     * @param a unsigned fixed-decimal
     * @return New packed unsigned fixed-decimal
     */
    function pack(UFixed18 a) internal pure returns (PackedUFixed18) {
        uint256 value = UFixed18.unwrap(a);
        if (value > type(uint128).max) revert UFixed18PackingOverflowError(value);
        return PackedUFixed18.wrap(uint128(value));
    }

    /**
     * @notice Returns whether the unsigned fixed-decimal is equal to zero.
     * @param a Unsigned fixed-decimal
     * @return Whether the unsigned fixed-decimal is zero.
     */
    function isZero(UFixed18 a) internal pure returns (bool) {
        return UFixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting summed unsigned fixed-decimal
     */
    function add(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) + UFixed18.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `b` from `a`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function sub(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) - UFixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mul(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function div(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * BASE / UFixed18.unwrap(b));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed18 a, uint256 b, uint256 c) internal pure returns (UFixed18) {
        return muldiv(a, UFixed18.wrap(b), UFixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed18 a, UFixed18 b, UFixed18 c) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / UFixed18.unwrap(c));
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the unsigned fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(UFixed18 a, UFixed18 b) internal pure returns (uint256) {
        (uint256 au, uint256 bu) = (UFixed18.unwrap(a), UFixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a unsigned fixed-decimal representing the ratio of `a` over `b`
     * @param a First unsigned number
     * @param b Second unsigned number
     * @return Ratio of `a` over `b`
     */
    function ratio(uint256 a, uint256 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(Math.min(UFixed18.unwrap(a), UFixed18.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(Math.max(UFixed18.unwrap(a), UFixed18.unwrap(b)));
    }

    /**
     * @notice Converts the unsigned fixed-decimal into an integer, truncating any decimal portion
     * @param a Unsigned fixed-decimal
     * @return Truncated unsigned number
     */
    function truncate(UFixed18 a) internal pure returns (uint256) {
        return UFixed18.unwrap(a) / BASE;
    }
}

library UFixed18StorageLib {
    function read(UFixed18Storage self) internal view returns (UFixed18 value) {
        assembly {
            value := sload(self)
        }
    }

    function store(UFixed18Storage self, UFixed18 value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../number/types/UFixed18.sol";

/// @dev Stored boolean slot
type BoolStorage is bytes32;
using BoolStorageLib for BoolStorage global;

/// @dev Stored uint256 slot
type Uint256Storage is bytes32;
using Uint256StorageLib for Uint256Storage global;

/// @dev Stored int256 slot
type Int256Storage is bytes32;
using Int256StorageLib for Int256Storage global;

/// @dev Stored address slot
type AddressStorage is bytes32;
using AddressStorageLib for AddressStorage global;

/// @dev Stored bytes32 slot
type Bytes32Storage is bytes32;
using Bytes32StorageLib for Bytes32Storage global;

/**
 * @title BoolStorageLib
 * @notice Library to manage storage and retrival of a boolean at a fixed storage slot
 */
library BoolStorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored bool value
     */
    function read(BoolStorage self) internal view returns (bool value) {
        assembly {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value boolean value to store
     */
    function store(BoolStorage self, bool value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

/**
 * @title Uint256StorageLib
 * @notice Library to manage storage and retrival of an uint256 at a fixed storage slot
 */
library Uint256StorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored uint256 value
     */
    function read(Uint256Storage self) internal view returns (uint256 value) {
        assembly {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value uint256 value to store
     */
    function store(Uint256Storage self, uint256 value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

/**
 * @title Int256StorageLib
 * @notice Library to manage storage and retrival of an int256 at a fixed storage slot
 */
library Int256StorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored int256 value
     */
    function read(Int256Storage self) internal view returns (int256 value) {
        assembly {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value int256 value to store
     */
    function store(Int256Storage self, int256 value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

/**
 * @title AddressStorageLib
 * @notice Library to manage storage and retrival of an address at a fixed storage slot
 */
library AddressStorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored address value
     */
    function read(AddressStorage self) internal view returns (address value) {
        assembly {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value address value to store
     */
    function store(AddressStorage self, address value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

/**
 * @title Bytes32StorageLib
 * @notice Library to manage storage and retrival of a bytes32 at a fixed storage slot
 */
library Bytes32StorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored bytes32 value
     */
    function read(Bytes32Storage self) internal view returns (bytes32 value) {
        assembly {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value bytes32 value to store
     */
    function store(Bytes32Storage self, bytes32 value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/CrossChainEnabled.sol)

pragma solidity ^0.8.4;

import "./errors.sol";

/**
 * @dev Provides information for building cross-chain aware contracts. This
 * abstract contract provides accessors and modifiers to control the execution
 * flow when receiving cross-chain messages.
 *
 * Actual implementations of cross-chain aware contracts, which are based on
 * this abstraction, will  have to inherit from a bridge-specific
 * specialization. Such specializations are provided under
 * `crosschain/<chain>/CrossChainEnabled<chain>.sol`.
 *
 * _Available since v4.6._
 */
abstract contract CrossChainEnabled {
    /**
     * @dev Throws if the current function call is not the result of a
     * cross-chain execution.
     */
    modifier onlyCrossChain() {
        if (!_isCrossChain()) revert NotCrossChainCall();
        _;
    }

    /**
     * @dev Throws if the current function call is not the result of a
     * cross-chain execution initiated by `account`.
     */
    modifier onlyCrossChainSender(address expected) {
        address actual = _crossChainSender();
        if (expected != actual) revert InvalidCrossChainSender(actual, expected);
        _;
    }

    /**
     * @dev Returns whether the current function call is the result of a
     * cross-chain message.
     */
    function _isCrossChain() internal view virtual returns (bool);

    /**
     * @dev Returns the address of the sender of the cross-chain message that
     * triggered the current function call.
     *
     * IMPORTANT: Should revert with `NotCrossChainCall` if the current function
     * call is not the result of a cross-chain message.
     */
    function _crossChainSender() internal view virtual returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (crosschain/arbitrum/CrossChainEnabledArbitrumL2.sol)

pragma solidity ^0.8.4;

import "../CrossChainEnabled.sol";
import "./LibArbitrumL2.sol";

/**
 * @dev https://arbitrum.io/[Arbitrum] specialization or the
 * {CrossChainEnabled} abstraction the L2 side (arbitrum).
 *
 * This version should only be deployed on L2 to process cross-chain messages
 * originating from L1. For the other side, use {CrossChainEnabledArbitrumL1}.
 *
 * Arbitrum L2 includes the `ArbSys` contract at a fixed address. Therefore,
 * this specialization of {CrossChainEnabled} does not include a constructor.
 *
 * _Available since v4.6._
 *
 * WARNING: There is currently a bug in Arbitrum that causes this contract to
 * fail to detect cross-chain calls when deployed behind a proxy. This will be
 * fixed when the network is upgraded to Arbitrum Nitro, currently scheduled for
 * August 31st 2022.
 */
abstract contract CrossChainEnabledArbitrumL2 is CrossChainEnabled {
    /**
     * @dev see {CrossChainEnabled-_isCrossChain}
     */
    function _isCrossChain() internal view virtual override returns (bool) {
        return LibArbitrumL2.isCrossChain(LibArbitrumL2.ARBSYS);
    }

    /**
     * @dev see {CrossChainEnabled-_crossChainSender}
     */
    function _crossChainSender() internal view virtual override onlyCrossChain returns (address) {
        return LibArbitrumL2.crossChainSender(LibArbitrumL2.ARBSYS);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (crosschain/arbitrum/LibArbitrumL2.sol)

pragma solidity ^0.8.4;

import {IArbSys as ArbitrumL2_Bridge} from "../../vendor/arbitrum/IArbSys.sol";
import "../errors.sol";

/**
 * @dev Primitives for cross-chain aware contracts for
 * https://arbitrum.io/[Arbitrum].
 *
 * This version should only be used on L2 to process cross-chain messages
 * originating from L1. For the other side, use {LibArbitrumL1}.
 *
 * WARNING: There is currently a bug in Arbitrum that causes this contract to
 * fail to detect cross-chain calls when deployed behind a proxy. This will be
 * fixed when the network is upgraded to Arbitrum Nitro, currently scheduled for
 * August 31st 2022.
 */
library LibArbitrumL2 {
    /**
     * @dev Returns whether the current function call is the result of a
     * cross-chain message relayed by `arbsys`.
     */
    address public constant ARBSYS = 0x0000000000000000000000000000000000000064;

    function isCrossChain(address arbsys) internal view returns (bool) {
        return ArbitrumL2_Bridge(arbsys).wasMyCallersAddressAliased();
    }

    /**
     * @dev Returns the address of the sender that triggered the current
     * cross-chain message through `arbsys`.
     *
     * NOTE: {isCrossChain} should be checked before trying to recover the
     * sender, as it will revert with `NotCrossChainCall` if the current
     * function call is not the result of a cross-chain message.
     */
    function crossChainSender(address arbsys) internal view returns (address) {
        if (!isCrossChain(arbsys)) revert NotCrossChainCall();

        return ArbitrumL2_Bridge(arbsys).myCallersAddressWithoutAliasing();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/errors.sol)

pragma solidity ^0.8.4;

error NotCrossChainCall();
error InvalidCrossChainSender(address actual, address expected);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.8.0) (vendor/arbitrum/IArbSys.sol)

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface IArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused) external pure returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data) external payable returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(uint256 indexed reserved, bytes32 indexed hash, uint256 indexed position);
}