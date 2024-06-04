//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for access related errors.
 */
library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for address related errors.
 */
library AddressError {
    /**
     * @dev Thrown when a zero address was passed as a function parameter (0x0000000000000000000000000000000000000000).
     */
    error ZeroAddress();

    /**
     * @dev Thrown when an address representing a contract is expected, but no code is found at the address.
     * @param contr The address that was expected to be a contract.
     */
    error NotAContract(address contr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for errors related with expected function parameters.
 */
library ParameterError {
    /**
     * @dev Thrown when an invalid parameter is used in a function.
     * @param parameter The name of the parameter.
     * @param reason The reason why the received parameter is invalid.
     */
    error InvalidParameter(string parameter, string reason);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC165 interface for determining if a contract supports a given interface.
 */
interface IERC165 {
    /**
     * @notice Determines if the contract in question supports the specified interface.
     * @param interfaceID XOR of all selectors in the contract.
     * @return True if the contract supports the specified interface.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC20 token implementation.
 */
interface IERC20 {
    /**
     * @notice Emitted when tokens have been transferred.
     * @param from The address that originally owned the tokens.
     * @param to The address that received the tokens.
     * @param amount The number of tokens that were transferred.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice Emitted when a user has provided allowance to another user for transferring tokens on its behalf.
     * @param owner The address that is providing the allowance.
     * @param spender The address that received the allowance.
     * @param amount The number of tokens that were added to `spender`'s allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient allowance to transfer tokens from another contract.
     * @param required The necessary allowance.
     * @param existing The current allowance.
     */
    error InsufficientAllowance(uint256 required, uint256 existing);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient tokens.
     * @param required The necessary balance.
     * @param existing The current balance.
     */
    error InsufficientBalance(uint256 required, uint256 existing);

    /**
     * @notice Retrieves the name of the token, e.g. "Synthetix Network Token".
     * @return A string with the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieves the symbol of the token, e.g. "SNX".
     * @return A string with the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retrieves the number of decimals used by the token. The default is 18.
     * @return The number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the total number of tokens in circulation (minted - burnt).
     * @return The total number of tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the balance of a user.
     * @param owner The address whose balance is being retrieved.
     * @return The number of tokens owned by the user.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Returns how many tokens a user has allowed another user to transfer on its behalf.
     * @param owner The user who has given the allowance.
     * @param spender The user who was given the allowance.
     * @return The amount of tokens `spender` can transfer on `owner`'s behalf.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Transfer tokens from one address to another.
     * @param to The address that will receive the tokens.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean which is true if the operation succeeded.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @notice Allows users to provide allowance to other users so that they can transfer tokens on their behalf.
     * @param spender The address that is receiving the allowance.
     * @param amount The amount of tokens that are being added to the allowance.
     * @return A boolean which is true if the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @notice Allows a user who has been given allowance to transfer tokens on another user's behalf.
     * @param from The address that owns the tokens that are being transferred.
     * @param to The address that will receive the tokens.
     * @param amount The number of tokens to transfer.
     * @return A boolean which is true if the operation succeeded.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./SafeCast.sol";

/**
 * @title Utility library used to represent "decimals" (fixed point numbers) with integers, with two different levels of precision.
 *
 * They are represented by N * UNIT, where UNIT is the number of decimals of precision in the representation.
 *
 * Examples:
 * 1) Given UNIT = 100
 * then if A = 50, A represents the decimal 0.50
 * 2) Given UNIT = 1000000000000000000
 * then if A = 500000000000000000, A represents the decimal 0.500000000000000000
 *
 * Note: An accompanying naming convention of the postfix "D<Precision>" is helpful with this utility. I.e. if a variable "myValue" represents a low resolution decimal, it should be named "myValueD18", and if it was a high resolution decimal "myValueD27". While scaling, intermediate precision decimals like "myValue45" could arise. Non-decimals should have no postfix, i.e. just "myValue".
 *
 * Important: Multiplication and division operations are currently not supported for high precision decimals. Using these operations on them will yield incorrect results and fail silently.
 */
library DecimalMath {
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;

    // solhint-disable numcast/safe-cast

    // Numbers representing 1.0 (low precision).
    uint256 public constant UNIT = 1e18;
    int256 public constant UNIT_INT = int256(UNIT);
    uint128 public constant UNIT_UINT128 = uint128(UNIT);
    int128 public constant UNIT_INT128 = int128(UNIT_INT);

    // Numbers representing 1.0 (high precision).
    uint256 public constant UNIT_PRECISE = 1e27;
    int256 public constant UNIT_PRECISE_INT = int256(UNIT_PRECISE);
    int128 public constant UNIT_PRECISE_INT128 = int128(UNIT_PRECISE_INT);

    // Precision scaling, (used to scale down/up from one precision to the other).
    uint256 public constant PRECISION_FACTOR = 9; // 27 - 18 = 9 :)

    // solhint-enable numcast/safe-cast

    // -----------------
    // uint256
    // -----------------

    /**
     * @dev Multiplies two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) * (y * UNIT) = x * y * UNIT ^ 2,
     * the result is divided by UNIT to remove double scaling.
     */
    function mulDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * y) / UNIT;
    }

    /**
     * @dev Divides two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) / (y * UNIT) = x / y (Decimal representation is lost),
     * x is first scaled up to end up with a decimal representation.
     */
    function divDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * UNIT) / y;
    }

    /**
     * @dev Scales up a value.
     *
     * E.g. if value is not a decimal, a scale up by 18 makes it a low precision decimal.
     * If value is a low precision decimal, a scale up by 9 makes it a high precision decimal.
     */
    function upscale(uint256 x, uint256 factor) internal pure returns (uint256) {
        return x * 10 ** factor;
    }

    /**
     * @dev Scales down a value.
     *
     * E.g. if value is a high precision decimal, a scale down by 9 makes it a low precision decimal.
     * If value is a low precision decimal, a scale down by 9 makes it a regular integer.
     *
     * Scaling down a regular integer would not make sense.
     */
    function downscale(uint256 x, uint256 factor) internal pure returns (uint256) {
        return x / 10 ** factor;
    }

    // -----------------
    // uint128
    // -----------------

    // Note: Overloading doesn't seem to work for similar types, i.e. int256 and int128, uint256 and uint128, etc, so explicitly naming the functions differently here.

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * y) / UNIT_UINT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * UNIT_UINT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleUint128(uint128 x, uint256 factor) internal pure returns (uint128) {
        return x * (10 ** factor).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleUint128(uint128 x, uint256 factor) internal pure returns (uint128) {
        return x / (10 ** factor).to128();
    }

    // -----------------
    // int256
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * y) / UNIT_INT;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * UNIT_INT) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscale(int256 x, uint256 factor) internal pure returns (int256) {
        return x * (10 ** factor).toInt();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscale(int256 x, uint256 factor) internal pure returns (int256) {
        return x / (10 ** factor).toInt();
    }

    // -----------------
    // int128
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * y) / UNIT_INT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * UNIT_INT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleInt128(int128 x, uint256 factor) internal pure returns (int128) {
        return x * ((10 ** factor).toInt()).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleInt128(int128 x, uint256 factor) internal pure returns (int128) {
        return x / ((10 ** factor).toInt().to128());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IERC165.sol";

library ERC165Helper {
    function safeSupportsInterface(
        address candidate,
        bytes4 interfaceID
    ) internal returns (bool supportsInterface) {
        (bool success, bytes memory response) = candidate.call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceID)
        );

        if (!success) {
            return false;
        }

        if (response.length == 0) {
            return false;
        }

        assembly {
            supportsInterface := mload(add(response, 32))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* solhint-disable meta-transactions/no-msg-sender */
/* solhint-disable meta-transactions/no-msg-data */

library ERC2771Context {
    // This is the trusted-multicall-forwarder. The address is constant due to CREATE2.
    address private constant TRUSTED_FORWARDER = 0xE2C5658cC5C448B48141168f3e475dF8f65A1e3e;

    function _msgSender() internal view returns (address sender) {
        if (isTrustedForwarder(msg.sender) && msg.data.length >= 20) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender) && msg.data.length >= 20) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    function isTrustedForwarder(address forwarder) internal pure returns (bool) {
        return forwarder == TRUSTED_FORWARDER;
    }

    function trustedForwarder() internal pure returns (address) {
        return TRUSTED_FORWARDER;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

// Eth Heap
// Author: Zac Mitton
// License: MIT

library HeapUtil {
    // default max-heap

    uint256 private constant _ROOT_INDEX = 1;

    struct Data {
        uint128 idCount;
        Node[] nodes; // root is index 1; index 0 not used
        mapping(uint128 => uint256) indices; // unique id => node index
    }
    struct Node {
        uint128 id; //use with another mapping to store arbitrary object types
        int128 priority;
    }

    //call init before anything else
    function init(Data storage self) internal {
        if (self.nodes.length == 0) self.nodes.push(Node(0, 0));
    }

    function insert(Data storage self, uint128 id, int128 priority) internal returns (Node memory) {
        //√
        if (self.nodes.length == 0) {
            init(self);
        } // test on-the-fly-init

        Node memory n;

        // MODIFIED: support updates
        extractById(self, id);

        self.idCount++;
        self.nodes.push();
        n = Node(id, priority);
        _bubbleUp(self, n, self.nodes.length - 1);

        return n;
    }

    function extractMax(Data storage self) internal returns (Node memory) {
        //√
        return _extract(self, _ROOT_INDEX);
    }

    function extractById(Data storage self, uint128 id) internal returns (Node memory) {
        //√
        return _extract(self, self.indices[id]);
    }

    //view
    function dump(Data storage self) internal view returns (Node[] memory) {
        //note: Empty set will return `[Node(0,0)]`. uninitialized will return `[]`.
        return self.nodes;
    }

    function getById(Data storage self, uint128 id) internal view returns (Node memory) {
        return getByIndex(self, self.indices[id]); //test that all these return the emptyNode
    }

    function getByIndex(Data storage self, uint256 i) internal view returns (Node memory) {
        return self.nodes.length > i ? self.nodes[i] : Node(0, 0);
    }

    function getMax(Data storage self) internal view returns (Node memory) {
        return getByIndex(self, _ROOT_INDEX);
    }

    function size(Data storage self) internal view returns (uint256) {
        return self.nodes.length > 0 ? self.nodes.length - 1 : 0;
    }

    function isNode(Node memory n) internal pure returns (bool) {
        return n.id > 0;
    }

    //private
    function _extract(Data storage self, uint256 i) private returns (Node memory) {
        //√
        if (self.nodes.length <= i || i <= 0) {
            return Node(0, 0);
        }

        Node memory extractedNode = self.nodes[i];
        delete self.indices[extractedNode.id];

        Node memory tailNode = self.nodes[self.nodes.length - 1];
        self.nodes.pop();

        if (i < self.nodes.length) {
            // if extracted node was not tail
            _bubbleUp(self, tailNode, i);
            _bubbleDown(self, self.nodes[i], i); // then try bubbling down
        }
        return extractedNode;
    }

    function _bubbleUp(Data storage self, Node memory n, uint256 i) private {
        //√
        if (i == _ROOT_INDEX || n.priority <= self.nodes[i / 2].priority) {
            _insert(self, n, i);
        } else {
            _insert(self, self.nodes[i / 2], i);
            _bubbleUp(self, n, i / 2);
        }
    }

    function _bubbleDown(Data storage self, Node memory n, uint256 i) private {
        //
        uint256 length = self.nodes.length;
        uint256 cIndex = i * 2; // left child index

        if (length <= cIndex) {
            _insert(self, n, i);
        } else {
            Node memory largestChild = self.nodes[cIndex];

            if (length > cIndex + 1 && self.nodes[cIndex + 1].priority > largestChild.priority) {
                largestChild = self.nodes[++cIndex]; // TEST ++ gets executed first here
            }

            if (largestChild.priority <= n.priority) {
                //TEST: priority 0 is valid! negative ints work
                _insert(self, n, i);
            } else {
                _insert(self, largestChild, i);
                _bubbleDown(self, n, cIndex);
            }
        }
    }

    function _insert(Data storage self, Node memory n, uint256 i) private {
        //√
        self.nodes[i] = n;
        self.indices[n.id] = i;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * Utilities that convert numeric types avoiding silent overflows.
 */
import "./SafeCast/SafeCastU32.sol";
import "./SafeCast/SafeCastI32.sol";
import "./SafeCast/SafeCastI24.sol";
import "./SafeCast/SafeCastU56.sol";
import "./SafeCast/SafeCastI56.sol";
import "./SafeCast/SafeCastU64.sol";
import "./SafeCast/SafeCastI64.sol";
import "./SafeCast/SafeCastI128.sol";
import "./SafeCast/SafeCastI256.sol";
import "./SafeCast/SafeCastU128.sol";
import "./SafeCast/SafeCastU160.sol";
import "./SafeCast/SafeCastU256.sol";
import "./SafeCast/SafeCastAddress.sol";
import "./SafeCast/SafeCastBytes32.sol";

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastAddress {
    function toBytes32(address x) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(x)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastBytes32 {
    function toAddress(bytes32 x) internal pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function toUint(bytes32 x) internal pure returns (uint) {
        return uint(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI128 {
    error OverflowInt128ToUint128();
    error OverflowInt128ToInt32();

    function toUint(int128 x) internal pure returns (uint128) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxxxxxo===============>----------------
        if (x < 0) {
            revert OverflowInt128ToUint128();
        }

        return uint128(x);
    }

    function to256(int128 x) internal pure returns (int256) {
        return int256(x);
    }

    function to32(int128 x) internal pure returns (int32) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxx<==o==>xxxxxxxxxxxx-----------------
        if (x < int256(type(int32).min) || x > int256(type(int32).max)) {
            revert OverflowInt128ToInt32();
        }

        return int32(x);
    }

    function zero() internal pure returns (int128) {
        return int128(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI24 {
    function to256(int24 x) internal pure returns (int256) {
        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI256 {
    error OverflowInt256ToUint256();
    error OverflowInt256ToInt128();
    error OverflowInt256ToInt24();

    function to128(int256 x) internal pure returns (int128) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxx<==============o==============>xxxxxxxxxxxxx----
        if (x < int256(type(int128).min) || x > int256(type(int128).max)) {
            revert OverflowInt256ToInt128();
        }

        return int128(x);
    }

    function to24(int256 x) internal pure returns (int24) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxx<======o=======>xxxxxxxxxxxxxxxxxxxx----
        if (x < int256(type(int24).min) || x > int256(type(int24).max)) {
            revert OverflowInt256ToInt24();
        }

        return int24(x);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxxxxxxxxxo===============================>
        if (x < 0) {
            revert OverflowInt256ToUint256();
        }

        return uint256(x);
    }

    function zero() internal pure returns (int256) {
        return int256(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI32 {
    error OverflowInt32ToUint32();

    function toUint(int32 x) internal pure returns (uint32) {
        // ----------------------<========o========>----------------------
        // ----------------------xxxxxxxxxo=========>----------------------
        if (x < 0) {
            revert OverflowInt32ToUint32();
        }

        return uint32(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI56 {
    error OverflowInt56ToInt24();

    function to24(int56 x) internal pure returns (int24) {
        // ----------------------<========o========>-----------------------
        // ----------------------xxx<=====o=====>xxx-----------------------
        if (x < int256(type(int24).min) || x > int256(type(int24).max)) {
            revert OverflowInt56ToInt24();
        }

        return int24(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI64 {
    error OverflowInt64ToUint64();

    function toUint(int64 x) internal pure returns (uint64) {
        // ----------------------<========o========>----------------------
        // ----------------------xxxxxxxxxo=========>----------------------
        if (x < 0) {
            revert OverflowInt64ToUint64();
        }

        return uint64(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU128 {
    error OverflowUint128ToInt128();

    function to256(uint128 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function toInt(uint128 x) internal pure returns (int128) {
        // -------------------------------o===============>----------------
        // ----------------<==============o==============>x----------------
        if (x > uint128(type(int128).max)) {
            revert OverflowUint128ToInt128();
        }

        return int128(x);
    }

    function toBytes32(uint128 x) internal pure returns (bytes32) {
        return bytes32(uint256(x));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU160 {
    function to256(uint160 x) internal pure returns (uint256) {
        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU256 {
    error OverflowUint256ToUint128();
    error OverflowUint256ToInt256();
    error OverflowUint256ToUint64();
    error OverflowUint256ToUint32();
    error OverflowUint256ToUint160();

    function to128(uint256 x) internal pure returns (uint128) {
        // -------------------------------o===============================>
        // -------------------------------o===============>xxxxxxxxxxxxxxxx
        if (x > type(uint128).max) {
            revert OverflowUint256ToUint128();
        }

        return uint128(x);
    }

    function to64(uint256 x) internal pure returns (uint64) {
        // -------------------------------o===============================>
        // -------------------------------o======>xxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint64).max) {
            revert OverflowUint256ToUint64();
        }

        return uint64(x);
    }

    function to32(uint256 x) internal pure returns (uint32) {
        // -------------------------------o===============================>
        // -------------------------------o===>xxxxxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint32).max) {
            revert OverflowUint256ToUint32();
        }

        return uint32(x);
    }

    function to160(uint256 x) internal pure returns (uint160) {
        // -------------------------------o===============================>
        // -------------------------------o==================>xxxxxxxxxxxxx
        if (x > type(uint160).max) {
            revert OverflowUint256ToUint160();
        }

        return uint160(x);
    }

    function toBytes32(uint256 x) internal pure returns (bytes32) {
        return bytes32(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        // -------------------------------o===============================>
        // ----<==========================o===========================>xxxx
        if (x > uint256(type(int256).max)) {
            revert OverflowUint256ToInt256();
        }

        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU32 {
    error OverflowUint32ToInt32();

    function toInt(uint32 x) internal pure returns (int32) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint32(type(int32).max)) {
            revert OverflowUint32ToInt32();
        }

        return int32(x);
    }

    function to256(uint32 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function to56(uint32 x) internal pure returns (uint56) {
        return uint56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU56 {
    error OverflowUint56ToInt56();

    function toInt(uint56 x) internal pure returns (int56) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint56(type(int56).max)) {
            revert OverflowUint56ToInt56();
        }

        return int56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU64 {
    error OverflowUint64ToInt64();

    function toInt(uint64 x) internal pure returns (int64) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint64(type(int64).max)) {
            revert OverflowUint64ToInt64();
        }

        return int64(x);
    }

    function to256(uint64 x) internal pure returns (uint256) {
        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./SafeCast.sol";

library SetUtil {
    using SafeCastAddress for address;
    using SafeCastBytes32 for bytes32;
    using SafeCastU256 for uint256;

    // ----------------------------------------
    // Uint support
    // ----------------------------------------

    struct UintSet {
        Bytes32Set raw;
    }

    function add(UintSet storage set, uint256 value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(UintSet storage set, uint256 value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(UintSet storage set, uint256 value, uint256 newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return length(set.raw);
    }

    function valueAt(UintSet storage set, uint256 position) internal view returns (uint256) {
        return valueAt(set.raw, position).toUint();
    }

    function positionOf(UintSet storage set, uint256 value) internal view returns (uint256) {
        return positionOf(set.raw, value.toBytes32());
    }

    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = values(set.raw);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Address support
    // ----------------------------------------

    struct AddressSet {
        Bytes32Set raw;
    }

    function add(AddressSet storage set, address value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(AddressSet storage set, address value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(AddressSet storage set, address value, address newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return length(set.raw);
    }

    function valueAt(AddressSet storage set, uint256 position) internal view returns (address) {
        return valueAt(set.raw, position).toAddress();
    }

    function positionOf(AddressSet storage set, address value) internal view returns (uint256) {
        return positionOf(set.raw, value.toBytes32());
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = values(set.raw);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Core bytes32 support
    // ----------------------------------------

    error PositionOutOfBounds();
    error ValueNotInSet();
    error ValueAlreadyInSet();

    struct Bytes32Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _positions; // Position zero is never used.
    }

    function add(Bytes32Set storage set, bytes32 value) internal {
        if (contains(set, value)) {
            revert ValueAlreadyInSet();
        }

        set._values.push(value);
        set._positions[value] = set._values.length;
    }

    function remove(Bytes32Set storage set, bytes32 value) internal {
        uint256 position = set._positions[value];
        if (position == 0) {
            revert ValueNotInSet();
        }

        uint256 index = position - 1;
        uint256 lastIndex = set._values.length - 1;

        // If the element being deleted is not the last in the values,
        // move the last element to its position.
        if (index != lastIndex) {
            bytes32 lastValue = set._values[lastIndex];

            set._values[index] = lastValue;
            set._positions[lastValue] = position;
        }

        // Remove the last element in the values.
        set._values.pop();
        delete set._positions[value];
    }

    function replace(Bytes32Set storage set, bytes32 value, bytes32 newValue) internal {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        if (contains(set, newValue)) {
            revert ValueAlreadyInSet();
        }

        uint256 position = set._positions[value];
        delete set._positions[value];

        uint256 index = position - 1;

        set._values[index] = newValue;
        set._positions[newValue] = position;
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return set._positions[value] != 0;
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function valueAt(Bytes32Set storage set, uint256 position) internal view returns (bytes32) {
        if (position == 0 || position > set._values.length) {
            revert PositionOutOfBounds();
        }

        uint256 index = position - 1;

        return set._values[index];
    }

    function positionOf(Bytes32Set storage set, bytes32 value) internal view returns (uint256) {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        return set._positions[value];
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return set._values;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for connecting a system with other associated systems.

 * Associated systems become available to all system modules for communication and interaction, but as opposed to inter-modular communications, interactions with associated systems will require the use of `CALL`.
 *
 * Associated systems can be managed or unmanaged.
 * - Managed systems are connected via a proxy, which means that their implementation can be updated, and the system controls the execution context of the associated system. Example, an snxUSD token connected to the system, and controlled by the system.
 * - Unmanaged systems are just addresses tracked by the system, for which it has no control whatsoever. Example, Uniswap v3, Curve, etc.
 *
 * Furthermore, associated systems are typed in the AssociatedSystem utility library (See AssociatedSystem.sol):
 * - KIND_ERC20: A managed associated system specifically wrapping an ERC20 implementation.
 * - KIND_ERC721: A managed associated system specifically wrapping an ERC721 implementation.
 * - KIND_UNMANAGED: Any unmanaged associated system.
 */
interface IAssociatedSystemsModule {
    /**
     * @notice Emitted when an associated system is set.
     * @param kind The type of associated system (managed ERC20, managed ERC721, unmanaged, etc - See the AssociatedSystem util).
     * @param id The bytes32 identifier of the associated system.
     * @param proxy The main external contract address of the associated system.
     * @param impl The address of the implementation of the associated system (if not behind a proxy, will equal `proxy`).
     */
    event AssociatedSystemSet(
        bytes32 indexed kind,
        bytes32 indexed id,
        address proxy,
        address impl
    );

    /**
     * @notice Emitted when the function you are calling requires an associated system, but it
     * has not been registered
     */
    error MissingAssociatedSystem(bytes32 id);

    /**
     * @notice Creates or initializes a managed associated ERC20 token.
     * @param id The bytes32 identifier of the associated system. If the id is new to the system, it will create a new proxy for the associated system.
     * @param name The token name that will be used to initialize the proxy.
     * @param symbol The token symbol that will be used to initialize the proxy.
     * @param decimals The token decimals that will be used to initialize the proxy.
     * @param impl The ERC20 implementation of the proxy.
     */
    function initOrUpgradeToken(
        bytes32 id,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address impl
    ) external;

    /**
     * @notice Creates or initializes a managed associated ERC721 token.
     * @param id The bytes32 identifier of the associated system. If the id is new to the system, it will create a new proxy for the associated system.
     * @param name The token name that will be used to initialize the proxy.
     * @param symbol The token symbol that will be used to initialize the proxy.
     * @param uri The token uri that will be used to initialize the proxy.
     * @param impl The ERC721 implementation of the proxy.
     */
    function initOrUpgradeNft(
        bytes32 id,
        string memory name,
        string memory symbol,
        string memory uri,
        address impl
    ) external;

    /**
     * @notice Registers an unmanaged external contract in the system.
     * @param id The bytes32 identifier to use to reference the associated system.
     * @param endpoint The address of the associated system.
     *
     * Note: The system will not be able to control or upgrade the associated system, only communicate with it.
     */
    function registerUnmanagedSystem(bytes32 id, address endpoint) external;

    /**
     * @notice Retrieves an associated system.
     * @param id The bytes32 identifier used to reference the associated system.
     * @return addr The external contract address of the associated system.
     * @return kind The type of associated system (managed ERC20, managed ERC721, unmanaged, etc - See the AssociatedSystem util).
     */
    function getAssociatedSystem(bytes32 id) external view returns (address addr, bytes32 kind);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

/**
 * @title Module wrapping an ERC20 token implementation.
 */
interface ITokenModule is IERC20 {
    /**
     * @notice Returns wether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external view returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and decimals.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param from The address whose tokens will be burnt.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param from The address that is providing allowance.
     * @param spender The address that is given allowance.
     * @param amount The amount of allowance being given.
     */
    function setAllowance(address from, address spender, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/ERC2771Context.sol";

library FeatureFlag {
    using SetUtil for SetUtil.AddressSet;

    error FeatureUnavailable(bytes32 which);

    struct Data {
        bytes32 name;
        bool allowAll;
        bool denyAll;
        SetUtil.AddressSet permissionedAddresses;
        address[] deniers;
    }

    function load(bytes32 featureName) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.core-modules.FeatureFlag", featureName));
        assembly {
            store.slot := s
        }
    }

    function ensureAccessToFeature(bytes32 feature) internal view {
        if (!hasAccess(feature, ERC2771Context._msgSender())) {
            revert FeatureUnavailable(feature);
        }
    }

    function hasAccess(bytes32 feature, address value) internal view returns (bool) {
        Data storage store = FeatureFlag.load(feature);

        if (store.denyAll) {
            return false;
        }

        return store.allowAll || store.permissionedAddresses.contains(value);
    }

    function isDenier(Data storage self, address possibleDenier) internal view returns (bool) {
        for (uint256 i = 0; i < self.deniers.length; i++) {
            if (self.deniers[i] == possibleDenier) {
                return true;
            }
        }

        return false;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/// @title Interface for markets integrated with Synthetix
interface IMarket is IERC165 {
    /// @notice returns a human-readable name for a given market
    function name(uint128 marketId) external view returns (string memory);

    /// @notice returns amount of USD that the market would try to mint if everything was withdrawn
    function reportedDebt(uint128 marketId) external view returns (uint256);

    /// @notice prevents reduction of available credit capacity by specifying this amount, for which withdrawals will be disallowed
    function minimumCredit(uint128 marketId) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";

/// @title Effective interface for the oracle manager
// solhint-disable-next-line no-empty-blocks
interface IOracleManager is INodeModule {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/// @title Interface a reward distributor.
interface IRewardDistributor is IERC165 {
    /// @notice Returns a human-readable name for the reward distributor
    function name() external view returns (string memory);

    /// @notice This function should revert if ERC2771Context._msgSender() is not the Synthetix CoreProxy address.
    /// @return whether or not the payout was executed
    function payout(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address sender,
        uint256 amount
    ) external returns (bool);

    /// @notice This function is called by the Synthetix Core Proxy whenever
    /// a position is updated on a pool which this distributor is registered
    function onPositionUpdated(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 newShares
    ) external;

    /// @notice Address to ERC-20 token distributed by this distributor, for display purposes only
    /// @dev Return address(0) if providing non ERC-20 rewards
    function token() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/CollateralConfiguration.sol";

/**
 * @title Module for configuring system wide collateral.
 * @notice Allows the owner to configure collaterals at a system wide level.
 */
interface ICollateralConfigurationModule {
    /**
     * @notice Emitted when a collateral type’s configuration is created or updated.
     * @param collateralType The address of the collateral type that was just configured.
     * @param config The object with the newly configured details.
     */
    event CollateralConfigured(address indexed collateralType, CollateralConfiguration.Data config);

    /**
     * @notice Creates or updates the configuration for the given `collateralType`.
     * @param config The CollateralConfiguration object describing the new configuration.
     *
     * Requirements:
     *
     * - `ERC2771Context._msgSender()` must be the owner of the system.
     *
     * Emits a {CollateralConfigured} event.
     *
     */
    function configureCollateral(CollateralConfiguration.Data memory config) external;

    /**
     * @notice Returns a list of detailed information pertaining to all collateral types registered in the system.
     * @dev Optionally returns only those that are currently enabled.
     * @param hideDisabled Wether to hide disabled collaterals or just return the full list of collaterals in the system.
     * @return collaterals The list of collateral configuration objects set in the system.
     */
    function getCollateralConfigurations(
        bool hideDisabled
    ) external view returns (CollateralConfiguration.Data[] memory collaterals);

    /**
     * @notice Returns detailed information pertaining the specified collateral type.
     * @param collateralType The address for the collateral whose configuration is being queried.
     * @return collateral The configuration object describing the given collateral.
     */
    function getCollateralConfiguration(
        address collateralType
    ) external view returns (CollateralConfiguration.Data memory collateral);

    /**
     * @notice Returns the current value of a specified collateral type.
     * @param collateralType The address for the collateral whose price is being queried.
     * @return priceD18 The price of the given collateral, denominated with 18 decimals of precision.
     */
    function getCollateralPrice(address collateralType) external view returns (uint256 priceD18);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/CollateralLock.sol";

/**
 * @title Module for managing user collateral.
 * @notice Allows users to deposit and withdraw collateral from the system.
 */
interface ICollateralModule {
    /**
     * @notice Thrown when an interacting account does not have sufficient collateral for an operation (withdrawal, lock, etc).
     */
    error InsufficientAccountCollateral(uint256 amount);

    /**
     * @notice Emitted when `tokenAmount` of collateral of type `collateralType` is deposited to account `accountId` by `sender`.
     * @param accountId The id of the account that deposited collateral.
     * @param collateralType The address of the collateral that was deposited.
     * @param tokenAmount The amount of collateral that was deposited, denominated in the token's native decimal representation.
     * @param sender The address of the account that triggered the deposit.
     */
    event Deposited(
        uint128 indexed accountId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender
    );

    /**
     * @notice Emitted when a lock is created on someone's account
     * @param accountId The id of the account that received a lock
     * @param collateralType The address of the collateral type that was locked
     * @param tokenAmount The amount of collateral that was locked, demoninated in system units (1e18)
     * @param expireTimestamp unix timestamp at which the lock is due to expire
     */
    event CollateralLockCreated(
        uint128 indexed accountId,
        address indexed collateralType,
        uint256 tokenAmount,
        uint64 expireTimestamp
    );

    /**
     * @notice Emitted when a lock is cleared from an account due to expiration
     * @param accountId The id of the account that has the expired lock
     * @param collateralType The address of the collateral type that was unlocked
     * @param tokenAmount The amount of collateral that was unlocked, demoninated in system units (1e18)
     * @param expireTimestamp unix timestamp at which the unlock is due to expire
     */
    event CollateralLockExpired(
        uint128 indexed accountId,
        address indexed collateralType,
        uint256 tokenAmount,
        uint64 expireTimestamp
    );

    /**
     * @notice Emitted when `tokenAmount` of collateral of type `collateralType` is withdrawn from account `accountId` by `sender`.
     * @param accountId The id of the account that withdrew collateral.
     * @param collateralType The address of the collateral that was withdrawn.
     * @param tokenAmount The amount of collateral that was withdrawn, denominated in the token's native decimal representation.
     * @param sender The address of the account that triggered the withdrawal.
     */
    event Withdrawn(
        uint128 indexed accountId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender
    );

    /**
     * @notice Deposits `tokenAmount` of collateral of type `collateralType` into account `accountId`.
     * @dev Anyone can deposit into anyone's active account without restriction.
     * @param accountId The id of the account that is making the deposit.
     * @param collateralType The address of the token to be deposited.
     * @param tokenAmount The amount being deposited, denominated in the token's native decimal representation.
     *
     * Emits a {Deposited} event.
     */
    function deposit(uint128 accountId, address collateralType, uint256 tokenAmount) external;

    /**
     * @notice Withdraws `tokenAmount` of collateral of type `collateralType` from account `accountId`.
     * @param accountId The id of the account that is making the withdrawal.
     * @param collateralType The address of the token to be withdrawn.
     * @param tokenAmount The amount being withdrawn, denominated in the token's native decimal representation.
     *
     * Requirements:
     *
     * - `ERC2771Context._msgSender()` must be the owner of the account, have the `ADMIN` permission, or have the `WITHDRAW` permission.
     *
     * Emits a {Withdrawn} event.
     *
     */
    function withdraw(uint128 accountId, address collateralType, uint256 tokenAmount) external;

    /**
     * @notice Returns the total values pertaining to account `accountId` for `collateralType`.
     * @param accountId The id of the account whose collateral is being queried.
     * @param collateralType The address of the collateral type whose amount is being queried.
     * @return totalDeposited The total collateral deposited in the account, denominated with 18 decimals of precision.
     * @return totalAssigned The amount of collateral in the account that is delegated to pools, denominated with 18 decimals of precision.
     * @return totalLocked The amount of collateral in the account that cannot currently be undelegated from a pool, denominated with 18 decimals of precision.
     */
    function getAccountCollateral(
        uint128 accountId,
        address collateralType
    ) external view returns (uint256 totalDeposited, uint256 totalAssigned, uint256 totalLocked);

    /**
     * @notice Returns the amount of collateral of type `collateralType` deposited with account `accountId` that can be withdrawn or delegated to pools.
     * @param accountId The id of the account whose collateral is being queried.
     * @param collateralType The address of the collateral type whose amount is being queried.
     * @return amountD18 The amount of collateral that is available for withdrawal or delegation, denominated with 18 decimals of precision.
     */
    function getAccountAvailableCollateral(
        uint128 accountId,
        address collateralType
    ) external view returns (uint256 amountD18);

    /**
     * @notice Clean expired locks from locked collateral arrays for an account/collateral type. It includes offset and items to prevent gas exhaustion. If both, offset and items, are 0 it will traverse the whole array (unlimited).
     * @param accountId The id of the account whose locks are being cleared.
     * @param collateralType The address of the collateral type to clean locks for.
     * @param offset The index of the first lock to clear.
     * @param count The number of slots to check for cleaning locks. Set to 0 to clean all locks at/after offset
     * @return cleared the number of locks that were actually expired (and therefore cleared)
     */
    function cleanExpiredLocks(
        uint128 accountId,
        address collateralType,
        uint256 offset,
        uint256 count
    ) external returns (uint256 cleared);

    /**
     * @notice Get a list of locks existing in account. Lists all locks in storage, even if they are expired
     * @param accountId The id of the account whose locks we want to read
     * @param collateralType The address of the collateral type for locks we want to read
     * @param offset The index of the first lock to read
     * @param count The number of slots to check for cleaning locks. Set to 0 to read all locks after offset
     */
    function getLocks(
        uint128 accountId,
        address collateralType,
        uint256 offset,
        uint256 count
    ) external view returns (CollateralLock.Data[] memory locks);

    /**
     * @notice Create a new lock on the given account. you must have `admin` permission on the specified account to create a lock.
     * @dev Collateral can be withdrawn from the system if it is not assigned or delegated to a pool. Collateral locks are an additional restriction that applies on top of that. I.e. if collateral is not assigned to a pool, but has a lock, it cannot be withdrawn.
     * @dev Collateral locks are initially intended for the Synthetix v2 to v3 migration, but may be used in the future by the Spartan Council, for example, to create and hand off accounts whose withdrawals from the system are locked for a given amount of time.
     * @param accountId The id of the account for which a lock is to be created.
     * @param collateralType The address of the collateral type for which the lock will be created.
     * @param amount The amount of collateral tokens to wrap in the lock being created, denominated with 18 decimals of precision.
     * @param expireTimestamp The date in which the lock will become clearable.
     */
    function createLock(
        uint128 accountId,
        address collateralType,
        uint256 amount,
        uint64 expireTimestamp
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for allowing markets to directly increase their credit capacity by providing their own collateral.
 */
interface IMarketCollateralModule {
    /**
     * @notice Thrown when a user attempts to deposit more collateral than that allowed by a market.
     */
    error InsufficientMarketCollateralDepositable(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmountToDeposit
    );

    /**
     * @notice Thrown when a user attempts to withdraw more collateral from the market than what it has provided.
     */
    error InsufficientMarketCollateralWithdrawable(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmountToWithdraw
    );

    /**
     * @notice Emitted when `amount` of collateral of type `collateralType` is deposited to market `marketId` by `sender`.
     * @param marketId The id of the market in which collateral was deposited.
     * @param collateralType The address of the collateral that was directly deposited in the market.
     * @param tokenAmount The amount of tokens that were deposited, denominated in the token's native decimal representation.
     * @param sender The address that triggered the deposit.
     * @param creditCapacity Updated credit capacity of the market after depositing collateral.
     * @param netIssuance Updated net issuance.
     * @param depositedCollateralValue Updated deposited collateral value of the market.
     * @param reportedDebt Updated reported debt of the market after depositing collateral.
     */
    event MarketCollateralDeposited(
        uint128 indexed marketId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender,
        int128 creditCapacity,
        int128 netIssuance,
        uint256 depositedCollateralValue,
        uint256 reportedDebt
    );

    /**
     * @notice Emitted when `amount` of collateral of type `collateralType` is withdrawn from market `marketId` by `sender`.
     * @param marketId The id of the market from which collateral was withdrawn.
     * @param collateralType The address of the collateral that was withdrawn from the market.
     * @param tokenAmount The amount of tokens that were withdrawn, denominated in the token's native decimal representation.
     * @param sender The address that triggered the withdrawal.
     * @param creditCapacity Updated credit capacity of the market after withdrawing.
     * @param netIssuance Updated net issuance.
     * @param depositedCollateralValue Updated deposited collateral value of the market.
     * @param reportedDebt Updated reported debt of the market after withdrawing collateral.
     */
    event MarketCollateralWithdrawn(
        uint128 indexed marketId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender,
        int128 creditCapacity,
        int128 netIssuance,
        uint256 depositedCollateralValue,
        uint256 reportedDebt
    );

    /**
     * @notice Emitted when the system owner specifies the maximum depositable collateral of a given type in a given market.
     * @param marketId The id of the market for which the maximum was configured.
     * @param collateralType The address of the collateral for which the maximum was configured.
     * @param systemAmount The amount to which the maximum was set, denominated with 18 decimals of precision.
     * @param owner The owner of the system, which triggered the configuration change.
     */
    event MaximumMarketCollateralConfigured(
        uint128 indexed marketId,
        address indexed collateralType,
        uint256 systemAmount,
        address indexed owner
    );

    /**
     * @notice Allows a market to deposit collateral.
     * @param marketId The id of the market in which the collateral was directly deposited.
     * @param collateralType The address of the collateral that was deposited in the market.
     * @param amount The amount of collateral that was deposited, denominated in the token's native decimal representation.
     */
    function depositMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 amount
    ) external;

    /**
     * @notice Allows a market to withdraw collateral that it has previously deposited.
     * @param marketId The id of the market from which the collateral was withdrawn.
     * @param collateralType The address of the collateral that was withdrawn from the market.
     * @param amount The amount of collateral that was withdrawn, denominated in the token's native decimal representation.
     */
    function withdrawMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 amount
    ) external;

    /**
     * @notice Allow the system owner to configure the maximum amount of a given collateral type that a specified market is allowed to deposit.
     * @param marketId The id of the market for which the maximum is to be configured.
     * @param collateralType The address of the collateral for which the maximum is to be applied.
     * @param amount The amount that is to be set as the new maximum, denominated with 18 decimals of precision.
     */
    function configureMaximumMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 amount
    ) external;

    /**
     * @notice Return the total maximum amount of a given collateral type that a specified market is allowed to deposit.
     * @param marketId The id of the market for which the maximum is being queried.
     * @param collateralType The address of the collateral for which the maximum is being queried.
     * @return amountD18 The maximum amount of collateral set for the market, denominated with 18 decimals of precision.
     */
    function getMaximumMarketCollateral(
        uint128 marketId,
        address collateralType
    ) external view returns (uint256 amountD18);

    /**
     * @notice Return the total amount of a given collateral type that a specified market has deposited.
     * @param marketId The id of the market for which the directly deposited collateral amount is being queried.
     * @param collateralType The address of the collateral for which the amount is being queried.
     * @return amountD18 The total amount of collateral of this type delegated to the market, denominated with 18 decimals of precision.
     */
    function getMarketCollateralAmount(
        uint128 marketId,
        address collateralType
    ) external view returns (uint256 amountD18);

    /**
     * @notice Return the total value of collateral that a specified market has deposited.
     * @param marketId The id of the market for which the directly deposited collateral amount is being queried.
     * @return valueD18 The total value of collateral deposited by the market, denominated with 18 decimals of precision.
     */
    function getMarketCollateralValue(uint128 marketId) external view returns (uint256 valueD18);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";
import "./external/IOracleManager.sol";

/**
 * @title System-wide entry point for the management of markets connected to the system.
 */
interface IMarketManagerModule {
    /**
     * @notice Thrown when a market does not have enough liquidity for a withdrawal.
     */
    error NotEnoughLiquidity(uint128 marketId, uint256 amount);

    /**
     * @notice Thrown when an attempt to register a market that does not conform to the IMarket interface is made.
     */
    error IncorrectMarketInterface(address market);

    /**
     * @notice Emitted when a new market is registered in the system.
     * @param market The address of the external market that was registered in the system.
     * @param marketId The id with which the market was registered in the system.
     * @param sender The account that trigger the registration of the market.
     */
    event MarketRegistered(
        address indexed market,
        uint128 indexed marketId,
        address indexed sender
    );

    /**
     * @notice Emitted when a market deposits snxUSD in the system.
     * @param marketId The id of the market that deposited snxUSD in the system.
     * @param target The address of the account that provided the snxUSD in the deposit.
     * @param amount The amount of snxUSD deposited in the system, denominated with 18 decimals of precision.
     * @param market The address of the external market that is depositing.
     * @param creditCapacity Updated credit capacity of the market after depositing.
     * @param netIssuance Updated net issuance.
     * @param depositedCollateralValue Updated deposited collateral value of the market.
     */
    event MarketUsdDeposited(
        uint128 indexed marketId,
        address indexed target,
        uint256 amount,
        address indexed market,
        int128 creditCapacity,
        int128 netIssuance,
        uint256 depositedCollateralValue
    );

    /**
     * @notice Emitted when a market withdraws snxUSD from the system.
     * @param marketId The id of the market that withdrew snxUSD from the system.
     * @param target The address of the account that received the snxUSD in the withdrawal.
     * @param amount The amount of snxUSD withdrawn from the system, denominated with 18 decimals of precision.
     * @param market The address of the external market that is withdrawing.
     * @param creditCapacity Updated credit capacity of the market after withdrawing.
     * @param netIssuance Updated net issuance.
     * @param depositedCollateralValue Updated deposited collateral value of the market
     */
    event MarketUsdWithdrawn(
        uint128 indexed marketId,
        address indexed target,
        uint256 amount,
        address indexed market,
        int128 creditCapacity,
        int128 netIssuance,
        uint256 depositedCollateralValue
    );

    event MarketSystemFeePaid(uint128 indexed marketId, uint256 feeAmount);

    /**
     * @notice Emitted when a market sets an updated minimum delegation time
     * @param marketId The id of the market that the setting is applied to
     * @param minDelegateTime The minimum amount of time between delegation changes
     */
    event SetMinDelegateTime(uint128 indexed marketId, uint32 minDelegateTime);

    /**
     * @notice Emitted when a market-specific minimum liquidity ratio is set
     * @param marketId The id of the market that the setting is applied to
     * @param minLiquidityRatio The new market-specific minimum liquidity ratio
     */
    event SetMarketMinLiquidityRatio(uint128 indexed marketId, uint256 minLiquidityRatio);

    /**
     * @notice Connects an external market to the system.
     * @dev Creates a Market object to track the external market, and returns the newly created market id.
     * @param market The address of the external market that is to be registered in the system.
     * @return newMarketId The id with which the market will be registered in the system.
     */
    function registerMarket(address market) external returns (uint128 newMarketId);

    /**
     * @notice Allows an external market connected to the system to deposit USD in the system.
     * @dev The system burns the incoming USD, increases the market's credit capacity, and reduces its issuance.
     * @dev See `IMarket`.
     * @param marketId The id of the market in which snxUSD will be deposited.
     * @param target The address of the account on who's behalf the deposit will be made.
     * @param amount The amount of snxUSD to be deposited, denominated with 18 decimals of precision.
     * @return feeAmount the amount of fees paid (billed as additional debt towards liquidity providers)
     */
    function depositMarketUsd(
        uint128 marketId,
        address target,
        uint256 amount
    ) external returns (uint256 feeAmount);

    /**
     * @notice Allows an external market connected to the system to withdraw snxUSD from the system.
     * @dev The system mints the requested snxUSD (provided that the market has sufficient credit), reduces the market's credit capacity, and increases its net issuance.
     * @dev See `IMarket`.
     * @param marketId The id of the market from which snxUSD will be withdrawn.
     * @param target The address of the account that will receive the withdrawn snxUSD.
     * @param amount The amount of snxUSD to be withdraw, denominated with 18 decimals of precision.
     * @return feeAmount the amount of fees paid (billed as additional debt towards liquidity providers)
     */
    function withdrawMarketUsd(
        uint128 marketId,
        address target,
        uint256 amount
    ) external returns (uint256 feeAmount);

    /**
     * @notice Get the amount of fees paid in USD for a call to `depositMarketUsd` and `withdrawMarketUsd` for the given market and amount
     * @param marketId The market to check fees for
     * @param amount The amount deposited or withdrawn in USD
     * @return depositFeeAmount the amount of USD paid for a call to `depositMarketUsd`
     * @return withdrawFeeAmount the amount of USD paid for a call to `withdrawMarketUsd`
     */
    function getMarketFees(
        uint128 marketId,
        uint256 amount
    ) external view returns (uint256 depositFeeAmount, uint256 withdrawFeeAmount);

    /**
     * @notice Returns the total withdrawable snxUSD amount for the specified market.
     * @param marketId The id of the market whose withdrawable USD amount is being queried.
     * @return withdrawableD18 The total amount of snxUSD that the market could withdraw at the time of the query, denominated with 18 decimals of precision.
     */
    function getWithdrawableMarketUsd(
        uint128 marketId
    ) external view returns (uint256 withdrawableD18);

    /**
     * @notice Returns the contract address for the specified market.
     * @param marketId The id of the market
     * @return marketAddress The contract address for the specified market
     */
    function getMarketAddress(uint128 marketId) external view returns (address marketAddress);

    /**
     * @notice Returns the net issuance of the specified market (snxUSD withdrawn - snxUSD deposited).
     * @param marketId The id of the market whose net issuance is being queried.
     * @return issuanceD18 The net issuance of the market, denominated with 18 decimals of precision.
     */
    function getMarketNetIssuance(uint128 marketId) external view returns (int128 issuanceD18);

    /**
     * @notice Returns the reported debt of the specified market.
     * @param marketId The id of the market whose reported debt is being queried.
     * @return reportedDebtD18 The market's reported debt, denominated with 18 decimals of precision.
     */
    function getMarketReportedDebt(
        uint128 marketId
    ) external view returns (uint256 reportedDebtD18);

    /**
     * @notice Returns the total debt of the specified market.
     * @param marketId The id of the market whose debt is being queried.
     * @return totalDebtD18 The total debt of the market, denominated with 18 decimals of precision.
     */
    function getMarketTotalDebt(uint128 marketId) external view returns (int256 totalDebtD18);

    /**
     * @notice Returns the total snxUSD value of the collateral for the specified market.
     * @param marketId The id of the market whose collateral is being queried.
     * @return valueD18 The market's total snxUSD value of collateral, denominated with 18 decimals of precision.
     */
    function getMarketCollateral(uint128 marketId) external view returns (uint256 valueD18);

    /**
     * @notice Returns the value per share of the debt of the specified market.
     * @dev This is not a view function, and actually updates the entire debt distribution chain.
     * @param marketId The id of the market whose debt per share is being queried.
     * @return debtPerShareD18 The market's debt per share value, denominated with 18 decimals of precision.
     */
    function getMarketDebtPerShare(uint128 marketId) external returns (int256 debtPerShareD18);

    /**
     * @notice Returns whether the capacity of the specified market is locked.
     * @param marketId The id of the market whose capacity is being queried.
     * @return isLocked A boolean that is true if the market's capacity is locked at the time of the query.
     */
    function isMarketCapacityLocked(uint128 marketId) external view returns (bool isLocked);

    /**
     * @notice Returns the USD token associated with this synthetix core system
     */
    function getUsdToken() external view returns (IERC20);

    /**
     * @notice Retrieve the systems' configured oracle manager address
     */
    function getOracleManager() external view returns (IOracleManager);

    /**
     * @notice Update a market's current debt registration with the system.
     * This function is provided as an escape hatch for pool griefing, preventing
     * overwhelming the system with a series of very small pools and creating high gas
     * costs to update an account.
     * @param marketId the id of the market that needs pools bumped
     * @return finishedDistributing whether or not all bumpable pools have been bumped and target price has been reached
     */
    function distributeDebtToPools(
        uint128 marketId,
        uint256 maxIter
    ) external returns (bool finishedDistributing);

    /**
     * @notice allows for a market to set its minimum delegation time. This is useful for preventing stakers from frontrunning rewards or losses
     * by limiting the frequency of `delegateCollateral` (or `setPoolConfiguration`) calls. By default, there is no minimum delegation time.
     * @param marketId the id of the market that wants to set delegation time.
     * @param minDelegateTime the minimum number of seconds between delegation calls. Note: this value must be less than the globally defined maximum minDelegateTime
     */
    function setMarketMinDelegateTime(uint128 marketId, uint32 minDelegateTime) external;

    /**
     * @notice Retrieve the minimum delegation time of a market
     * @param marketId the id of the market
     */
    function getMarketMinDelegateTime(uint128 marketId) external view returns (uint32);

    /**
     * @notice Allows the system owner (not the pool owner) to set a market-specific minimum liquidity ratio.
     * @param marketId the id of the market
     * @param minLiquidityRatio The new market-specific minimum liquidity ratio, denominated with 18 decimals of precision. (100% is represented by 1 followed by 18 zeros.)
     */
    function setMinLiquidityRatio(uint128 marketId, uint256 minLiquidityRatio) external;

    /**
     * @notice Retrieves the market-specific minimum liquidity ratio.
     * @param marketId the id of the market
     * @return minRatioD18 The current market-specific minimum liquidity ratio, denominated with 18 decimals of precision. (100% is represented by 1 followed by 18 zeros.)
     */
    function getMinLiquidityRatio(uint128 marketId) external view returns (uint256 minRatioD18);

    function getMarketPools(
        uint128 marketId
    ) external returns (uint128[] memory inRangePoolIds, uint128[] memory outRangePoolIds);

    function getMarketPoolDebtDistribution(
        uint128 marketId,
        uint128 poolId
    ) external returns (uint256 sharesD18, uint128 totalSharesD18, int128 valuePerShareD27);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {IERC165} from "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/**
 * @title Module with assorted utility functions.
 */
interface IUtilsModule is IERC165 {
    /**
     * @notice Emitted when a new cross chain network becomes supported by the protocol
     */
    event NewSupportedCrossChainNetwork(uint64 newChainId);

    /**
     * @notice Configure CCIP addresses on the stablecoin.
     * @param ccipRouter The address on this chain to which CCIP messages will be sent or received.
     * @param ccipTokenPool The address where CCIP fees will be sent to when sending and receiving cross chain messages.
     */
    function configureChainlinkCrossChain(address ccipRouter, address ccipTokenPool) external;

    /**
     * @notice Used to add new cross chain networks to the protocol
     * Ignores a network if it matches the current chain id
     * Ignores a network if it has already been added
     * @param supportedNetworks array of all networks that are supported by the protocol
     * @param ccipSelectors the ccip "selector" which maps to the chain id on the same index. must be same length as `supportedNetworks`
     * @return numRegistered the number of networks that were actually registered
     */
    function setSupportedCrossChainNetworks(
        uint64[] memory supportedNetworks,
        uint64[] memory ccipSelectors
    ) external returns (uint256 numRegistered);

    /**
     * @notice Configure the system's single oracle manager address.
     * @param oracleManagerAddress The address of the oracle manager.
     */
    function configureOracleManager(address oracleManagerAddress) external;

    /**
     * @notice Configure a generic value in the KV system
     * @param k the key of the value to set
     * @param v the value that the key should be set to
     */
    function setConfig(bytes32 k, bytes32 v) external;

    /**
     * @notice Read a generic value from the KV system
     * @param k the key to read
     * @return v the value set on the specified k
     */
    function getConfig(bytes32 k) external view returns (bytes32 v);

    /**
     * @notice Read a UINT value from the KV system
     * @param k the key to read
     * @return v the value set on the specified k
     */
    function getConfigUint(bytes32 k) external view returns (uint256 v);

    /**
     * @notice Read a Address value from the KV system
     * @param k the key to read
     * @return v the value set on the specified k
     */
    function getConfigAddress(bytes32 k) external view returns (address v);

    /**
     * @notice Checks if the address is the trusted forwarder
     * @param forwarder The address to check
     * @return Whether the address is the trusted forwarder
     */
    function isTrustedForwarder(address forwarder) external pure returns (bool);

    /**
     * @notice Provides the address of the trusted forwarder
     * @return Address of the trusted forwarder
     */
    function getTrustedForwarder() external pure returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./AccountRBAC.sol";
import "./Collateral.sol";
import "./Pool.sol";

import "../interfaces/ICollateralModule.sol";

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/utils/ERC2771Context.sol";

/**
 * @title Object for tracking accounts with access control and collateral tracking.
 */
library Account {
    using AccountRBAC for AccountRBAC.Data;
    using Pool for Pool.Data;
    using Collateral for Collateral.Data;
    using SetUtil for SetUtil.UintSet;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    /**
     * @dev Thrown when the given target address does not have the given permission with the given account.
     */
    error PermissionDenied(uint128 accountId, bytes32 permission, address target);

    /**
     * @dev Thrown when an account cannot be found.
     */
    error AccountNotFound(uint128 accountId);

    /**
     * @dev Thrown when the requested operation requires an activity timeout before the
     */
    error AccountActivityTimeoutPending(
        uint128 accountId,
        uint256 currentTime,
        uint256 requiredTime
    );

    struct Data {
        /**
         * @dev Numeric identifier for the account. Must be unique.
         * @dev There cannot be an account with id zero (See ERC721._mint()).
         */
        uint128 id;
        /**
         * @dev Role based access control data for the account.
         */
        AccountRBAC.Data rbac;
        uint64 lastInteraction;
        uint64 __slotAvailableForFutureUse;
        uint128 __slot2AvailableForFutureUse;
        /**
         * @dev Address set of collaterals that are being used in the system by this account.
         */
        mapping(address => Collateral.Data) collaterals;
    }

    /**
     * @dev Returns the account stored at the specified account id.
     */
    function load(uint128 id) internal pure returns (Data storage account) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.Account", id));
        assembly {
            account.slot := s
        }
    }

    /**
     * @dev Creates an account for the given id, and associates it to the given owner.
     *
     * Note: Will not fail if the account already exists, and if so, will overwrite the existing owner. Whatever calls this internal function must first check that the account doesn't exist before re-creating it.
     */
    function create(uint128 id, address owner) internal returns (Data storage account) {
        account = load(id);

        account.id = id;
        account.rbac.owner = owner;
    }

    /**
     * @dev Reverts if the account does not exist with appropriate error. Otherwise, returns the account.
     */
    function exists(uint128 id) internal view returns (Data storage account) {
        Data storage a = load(id);
        if (a.rbac.owner == address(0)) {
            revert AccountNotFound(id);
        }

        return a;
    }

    /**
     * @dev Given a collateral type, returns information about the total collateral assigned, deposited, and locked by the account
     */
    function getCollateralTotals(
        Data storage self,
        address collateralType
    )
        internal
        view
        returns (uint256 totalDepositedD18, uint256 totalAssignedD18, uint256 totalLockedD18)
    {
        totalAssignedD18 = getAssignedCollateral(self, collateralType);
        totalDepositedD18 =
            totalAssignedD18 +
            self.collaterals[collateralType].amountAvailableForDelegationD18;
        totalLockedD18 = self.collaterals[collateralType].getTotalLocked();

        return (totalDepositedD18, totalAssignedD18, totalLockedD18);
    }

    /**
     * @dev Returns the total amount of collateral that has been delegated to pools by the account, for the given collateral type.
     */
    function getAssignedCollateral(
        Data storage self,
        address collateralType
    ) internal view returns (uint256) {
        uint256 totalAssignedD18 = 0;

        SetUtil.UintSet storage pools = self.collaterals[collateralType].pools;

        for (uint256 i = 1; i <= pools.length(); i++) {
            uint128 poolIdx = pools.valueAt(i).to128();

            Pool.Data storage pool = Pool.load(poolIdx);

            (uint256 collateralAmountD18, ) = pool.currentAccountCollateral(
                collateralType,
                self.id
            );
            totalAssignedD18 += collateralAmountD18;
        }

        return totalAssignedD18;
    }

    function recordInteraction(Data storage self) internal {
        // solhint-disable-next-line numcast/safe-cast
        self.lastInteraction = uint64(block.timestamp);
    }

    /**
     * @dev Loads the Account object for the specified accountId,
     * and validates that sender has the specified permission. It also resets
     * the interaction timeout. These
     * are different actions but they are merged in a single function
     * because loading an account and checking for a permission is a very
     * common use case in other parts of the code.
     */
    function loadAccountAndValidatePermission(
        uint128 accountId,
        bytes32 permission
    ) internal returns (Data storage account) {
        account = Account.load(accountId);

        if (!account.rbac.authorized(permission, ERC2771Context._msgSender())) {
            revert PermissionDenied(accountId, permission, ERC2771Context._msgSender());
        }

        recordInteraction(account);
    }

    /**
     * @dev Loads the Account object for the specified accountId,
     * and validates that sender has the specified permission. It also resets
     * the interaction timeout. These
     * are different actions but they are merged in a single function
     * because loading an account and checking for a permission is a very
     * common use case in other parts of the code.
     */
    function loadAccountAndValidatePermissionAndTimeout(
        uint128 accountId,
        bytes32 permission,
        uint256 timeout
    ) internal view returns (Data storage account) {
        account = Account.load(accountId);

        if (!account.rbac.authorized(permission, ERC2771Context._msgSender())) {
            revert PermissionDenied(accountId, permission, ERC2771Context._msgSender());
        }

        uint256 endWaitingPeriod = account.lastInteraction + timeout;
        if (block.timestamp < endWaitingPeriod) {
            revert AccountActivityTimeoutPending(accountId, block.timestamp, endWaitingPeriod);
        }
    }

    /**
     * @dev Ensure that the account has the required amount of collateral funds remaining
     */
    function requireSufficientCollateral(
        uint128 accountId,
        address collateralType,
        uint256 amountD18
    ) internal view {
        if (
            Account.load(accountId).collaterals[collateralType].amountAvailableForDelegationD18 <
            amountD18
        ) {
            revert ICollateralModule.InsufficientAccountCollateral(amountD18);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/errors/AddressError.sol";

/**
 * @title Object for tracking an accounts permissions (role based access control).
 */
library AccountRBAC {
    using SetUtil for SetUtil.Bytes32Set;
    using SetUtil for SetUtil.AddressSet;

    /**
     * @dev All permissions used by the system
     * need to be hardcoded here.
     */
    bytes32 internal constant _ADMIN_PERMISSION = "ADMIN";
    bytes32 internal constant _WITHDRAW_PERMISSION = "WITHDRAW";
    bytes32 internal constant _DELEGATE_PERMISSION = "DELEGATE";
    bytes32 internal constant _MINT_PERMISSION = "MINT";
    bytes32 internal constant _REWARDS_PERMISSION = "REWARDS";
    bytes32 internal constant _PERPS_MODIFY_COLLATERAL_PERMISSION = "PERPS_MODIFY_COLLATERAL";
    bytes32 internal constant _PERPS_COMMIT_ASYNC_ORDER_PERMISSION = "PERPS_COMMIT_ASYNC_ORDER";
    bytes32 internal constant _BURN_PERMISSION = "BURN";

    /**
     * @dev Thrown when a permission specified by a user does not exist or is invalid.
     */
    error InvalidPermission(bytes32 permission);

    struct Data {
        /**
         * @dev The owner of the account and admin of all permissions.
         */
        address owner;
        /**
         * @dev Set of permissions for each address enabled by the account.
         */
        mapping(address => SetUtil.Bytes32Set) permissions;
        /**
         * @dev Array of addresses that this account has given permissions to.
         */
        SetUtil.AddressSet permissionAddresses;
    }

    /**
     * @dev Reverts if the specified permission is unknown to the account RBAC system.
     */
    function isPermissionValid(bytes32 permission) internal pure {
        if (
            permission != AccountRBAC._WITHDRAW_PERMISSION &&
            permission != AccountRBAC._DELEGATE_PERMISSION &&
            permission != AccountRBAC._MINT_PERMISSION &&
            permission != AccountRBAC._ADMIN_PERMISSION &&
            permission != AccountRBAC._REWARDS_PERMISSION &&
            permission != AccountRBAC._PERPS_MODIFY_COLLATERAL_PERMISSION &&
            permission != AccountRBAC._PERPS_COMMIT_ASYNC_ORDER_PERMISSION &&
            permission != AccountRBAC._BURN_PERMISSION
        ) {
            revert InvalidPermission(permission);
        }
    }

    /**
     * @dev Sets the owner of the account.
     */
    function setOwner(Data storage self, address owner) internal {
        self.owner = owner;
    }

    /**
     * @dev Grants a particular permission to the specified target address.
     */
    function grantPermission(Data storage self, bytes32 permission, address target) internal {
        if (target == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (permission == "") {
            revert InvalidPermission("");
        }

        if (!self.permissionAddresses.contains(target)) {
            self.permissionAddresses.add(target);
        }

        self.permissions[target].add(permission);
    }

    /**
     * @dev Revokes a particular permission from the specified target address.
     */
    function revokePermission(Data storage self, bytes32 permission, address target) internal {
        self.permissions[target].remove(permission);

        if (self.permissions[target].length() == 0) {
            self.permissionAddresses.remove(target);
        }
    }

    /**
     * @dev Revokes all permissions for the specified target address.
     * @notice only removes permissions for the given address, not for the entire account
     */
    function revokeAllPermissions(Data storage self, address target) internal {
        bytes32[] memory permissions = self.permissions[target].values();

        if (permissions.length == 0) {
            return;
        }

        for (uint256 i = 0; i < permissions.length; i++) {
            self.permissions[target].remove(permissions[i]);
        }

        self.permissionAddresses.remove(target);
    }

    /**
     * @dev Returns wether the specified address has the given permission.
     */
    function hasPermission(
        Data storage self,
        bytes32 permission,
        address target
    ) internal view returns (bool) {
        return target != address(0) && self.permissions[target].contains(permission);
    }

    /**
     * @dev Returns wether the specified target address has the given permission, or has the high level admin permission.
     */
    function authorized(
        Data storage self,
        bytes32 permission,
        address target
    ) internal view returns (bool) {
        return ((target == self.owner) ||
            hasPermission(self, _ADMIN_PERMISSION, target) ||
            hasPermission(self, permission, target));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "./CollateralLock.sol";

/**
 * @title Stores information about a deposited asset for a given account.
 *
 * Each account will have one of these objects for each type of collateral it deposited in the system.
 */
library Collateral {
    using SafeCastU256 for uint256;

    /**
     * @dev Thrown when a specified market is not found.
     */
    error InsufficentAvailableCollateral(
        uint256 amountAvailableForDelegationD18,
        uint256 amountD18
    );

    struct Data {
        /**
         * @dev The amount that can be withdrawn or delegated in this collateral.
         */
        uint256 amountAvailableForDelegationD18;
        /**
         * @dev The pools to which this collateral delegates to.
         */
        SetUtil.UintSet pools;
        /**
         * @dev Marks portions of the collateral as locked,
         * until a given unlock date.
         *
         * Note: Locks apply to delegated collateral and to collateral not
         * assigned or delegated to a pool (see ICollateralModule).
         */
        CollateralLock.Data[] locks;
    }

    /**
     * @dev Increments the entry's availableCollateral.
     */
    function increaseAvailableCollateral(Data storage self, uint256 amountD18) internal {
        self.amountAvailableForDelegationD18 += amountD18;
    }

    /**
     * @dev Decrements the entry's availableCollateral.
     */
    function decreaseAvailableCollateral(Data storage self, uint256 amountD18) internal {
        if (self.amountAvailableForDelegationD18 < amountD18) {
            revert InsufficentAvailableCollateral(self.amountAvailableForDelegationD18, amountD18);
        }
        self.amountAvailableForDelegationD18 -= amountD18;
    }

    /**
     * @dev Returns the total amount in this collateral entry that is locked.
     *
     * Sweeps through all existing locks and accumulates their amount,
     * if their unlock date is in the future.
     */
    function getTotalLocked(Data storage self) internal view returns (uint256) {
        uint64 currentTime = block.timestamp.to64();

        uint256 lockedD18;
        for (uint256 i = 0; i < self.locks.length; i++) {
            CollateralLock.Data storage lock = self.locks[i];

            if (lock.lockExpirationTime > currentTime) {
                lockedD18 += lock.amountD18;
            }
        }

        return lockedD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";
import "@synthetixio/oracle-manager/contracts/storage/NodeOutput.sol";
import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "./OracleManager.sol";

/**
 * @title Tracks system-wide settings for each collateral type, as well as helper functions for it, such as retrieving its current price from the oracle manager.
 */
library CollateralConfiguration {
    bytes32 private constant _SLOT_AVAILABLE_COLLATERALS =
        keccak256(
            abi.encode("io.synthetix.synthetix.CollateralConfiguration_availableCollaterals")
        );

    using SetUtil for SetUtil.AddressSet;
    using DecimalMath for uint256;
    using SafeCastI256 for int256;

    /**
     * @dev Thrown when the token address of a collateral cannot be found.
     */
    error CollateralNotFound();

    /**
     * @dev Thrown when deposits are disabled for the given collateral type.
     * @param collateralType The address of the collateral type for which depositing was disabled.
     */
    error CollateralDepositDisabled(address collateralType);

    /**
     * @dev Thrown when collateral ratio is not sufficient in a given operation in the system.
     * @param collateralValue The net USD value of the position.
     * @param debt The net USD debt of the position.
     * @param ratio The collateralization ratio of the position.
     * @param minRatio The minimum c-ratio which was not met. Could be issuance ratio or liquidation ratio, depending on the case.
     */
    error InsufficientCollateralRatio(
        uint256 collateralValue,
        uint256 debt,
        uint256 ratio,
        uint256 minRatio
    );

    /**
     * @dev Thrown when the amount being delegated is less than the minimum expected amount.
     * @param minDelegation The current minimum for deposits and delegation set to this collateral type.
     */
    error InsufficientDelegation(uint256 minDelegation);

    /**
     * @dev Thrown when attempting to convert a token to the system amount and the conversion results in a loss of precision.
     * @param tokenAmount The amount of tokens that were attempted to be converted.
     * @param decimals The number of decimals of the token that was attempted to be converted.
     */
    error PrecisionLost(uint256 tokenAmount, uint8 decimals);

    struct Data {
        /**
         * @dev Allows the owner to control deposits and delegation of collateral types.
         */
        bool depositingEnabled;
        /**
         * @dev System-wide collateralization ratio for issuance of snxUSD.
         * Accounts will not be able to mint snxUSD if they are below this issuance c-ratio.
         */
        uint256 issuanceRatioD18;
        /**
         * @dev System-wide collateralization ratio for liquidations of this collateral type.
         * Accounts below this c-ratio can be immediately liquidated.
         */
        uint256 liquidationRatioD18;
        /**
         * @dev Amount of tokens to award when an account is liquidated.
         */
        uint256 liquidationRewardD18;
        /**
         * @dev The oracle manager node id which reports the current price for this collateral type.
         */
        bytes32 oracleNodeId;
        /**
         * @dev The token address for this collateral type.
         */
        address tokenAddress;
        /**
         * @dev Minimum amount that accounts can delegate to pools.
         * Helps prevent spamming on the system.
         * Note: If zero, liquidationRewardD18 will be used.
         */
        uint256 minDelegationD18;
    }

    /**
     * @dev Loads the CollateralConfiguration object for the given collateral type.
     * @param token The address of the collateral type.
     * @return collateralConfiguration The CollateralConfiguration object.
     */
    function load(address token) internal pure returns (Data storage collateralConfiguration) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.CollateralConfiguration", token));
        assembly {
            collateralConfiguration.slot := s
        }
    }

    /**
     * @dev Loads all available collateral types configured in the system.
     * @return availableCollaterals An array of addresses, one for each collateral type supported by the system.
     */
    function loadAvailableCollaterals()
        internal
        pure
        returns (SetUtil.AddressSet storage availableCollaterals)
    {
        bytes32 s = _SLOT_AVAILABLE_COLLATERALS;
        assembly {
            availableCollaterals.slot := s
        }
    }

    /**
     * @dev Configures a collateral type.
     * @param config The CollateralConfiguration object with all the settings for the collateral type being configured.
     */
    function set(Data memory config) internal {
        SetUtil.AddressSet storage collateralTypes = loadAvailableCollaterals();

        if (!collateralTypes.contains(config.tokenAddress)) {
            collateralTypes.add(config.tokenAddress);
        }

        if (config.minDelegationD18 < config.liquidationRewardD18) {
            revert ParameterError.InvalidParameter(
                "minDelegation",
                "must be greater than liquidationReward"
            );
        }

        if (config.issuanceRatioD18 <= 1e18) {
            revert ParameterError.InvalidParameter("issuanceRatioD18", "must be greater than 100%");
        }

        if (config.liquidationRatioD18 <= 1e18) {
            revert ParameterError.InvalidParameter(
                "liquidationRatioD18",
                "must be greater than 100%"
            );
        }

        if (config.issuanceRatioD18 < config.liquidationRatioD18) {
            revert ParameterError.InvalidParameter(
                "issuanceRatioD18",
                "must be greater than liquidationRatioD18"
            );
        }

        Data storage storedConfig = load(config.tokenAddress);

        storedConfig.tokenAddress = config.tokenAddress;
        storedConfig.issuanceRatioD18 = config.issuanceRatioD18;
        storedConfig.liquidationRatioD18 = config.liquidationRatioD18;
        storedConfig.oracleNodeId = config.oracleNodeId;
        storedConfig.liquidationRewardD18 = config.liquidationRewardD18;
        storedConfig.minDelegationD18 = config.minDelegationD18;
        storedConfig.depositingEnabled = config.depositingEnabled;
    }

    /**
     * @dev Shows if a given collateral type is enabled for deposits and delegation.
     * @param token The address of the collateral being queried.
     */
    function collateralEnabled(address token) internal view {
        if (!load(token).depositingEnabled) {
            revert CollateralDepositDisabled(token);
        }
    }

    /**
     * @dev Reverts if the amount being delegated is insufficient for the system.
     * @param token The address of the collateral type.
     * @param amountD18 The amount being checked for sufficient delegation.
     */
    function requireSufficientDelegation(address token, uint256 amountD18) internal view {
        CollateralConfiguration.Data storage config = load(token);

        uint256 minDelegationD18 = config.minDelegationD18;

        if (minDelegationD18 == 0) {
            minDelegationD18 = config.liquidationRewardD18;
        }

        if (amountD18 < minDelegationD18) {
            revert InsufficientDelegation(minDelegationD18);
        }
    }

    /**
     * @dev Returns the price of this collateral configuration object.
     * @param self The CollateralConfiguration object.
     * @param collateralAmount The amount of collateral to get the price for.
     * @return The price of the collateral with 18 decimals of precision.
     */
    function getCollateralPrice(
        Data storage self,
        uint256 collateralAmount
    ) internal view returns (uint256) {
        OracleManager.Data memory oracleManager = OracleManager.load();

        bytes32[] memory runtimeKeys = new bytes32[](1);
        bytes32[] memory runtimeValues = new bytes32[](1);
        runtimeKeys[0] = bytes32("size");
        runtimeValues[0] = bytes32(collateralAmount);
        NodeOutput.Data memory node = INodeModule(oracleManager.oracleManagerAddress)
            .processWithRuntime(self.oracleNodeId, runtimeKeys, runtimeValues);

        return node.price.toUint();
    }

    /**
     * @dev Reverts if the specified collateral and debt values produce a collateralization ratio which is below the amount required for new issuance of snxUSD.
     * @param self The CollateralConfiguration object whose collateral and settings are being queried.
     * @param debtD18 The debt component of the ratio.
     * @param collateralValueD18 The collateral component of the ratio.
     */
    function verifyIssuanceRatio(
        Data storage self,
        uint256 debtD18,
        uint256 collateralValueD18,
        uint256 minIssuanceRatioD18
    ) internal view {
        uint256 issuanceRatioD18 = self.issuanceRatioD18 > minIssuanceRatioD18
            ? self.issuanceRatioD18
            : minIssuanceRatioD18;

        if (
            debtD18 != 0 &&
            (collateralValueD18 == 0 || collateralValueD18.divDecimal(debtD18) < issuanceRatioD18)
        ) {
            revert InsufficientCollateralRatio(
                collateralValueD18,
                debtD18,
                collateralValueD18.divDecimal(debtD18),
                issuanceRatioD18
            );
        }
    }

    /**
     * @dev Converts token amounts with non-system decimal precisions, to 18 decimals of precision.
     * E.g: $TOKEN_A uses 6 decimals of precision, so this would upscale it by 12 decimals.
     * E.g: $TOKEN_B uses 20 decimals of precision, so this would downscale it by 2 decimals.
     * @param self The CollateralConfiguration object corresponding to the collateral type being converted.
     * @param tokenAmount The token amount, denominated in its native decimal precision.
     * @return amountD18 The converted amount, denominated in the system's 18 decimal precision.
     */
    function convertTokenToSystemAmount(
        Data storage self,
        uint256 tokenAmount
    ) internal view returns (uint256 amountD18) {
        // this extra condition is to prevent potentially malicious untrusted code from being executed on the next statement
        if (self.tokenAddress == address(0)) {
            revert CollateralNotFound();
        }

        /// @dev this try-catch block assumes there is no malicious code in the token's fallback function
        try IERC20(self.tokenAddress).decimals() returns (uint8 decimals) {
            if (decimals == 18) {
                amountD18 = tokenAmount;
            } else if (decimals < 18) {
                amountD18 = (tokenAmount * DecimalMath.UNIT) / (10 ** decimals);
            } else {
                // ensure no precision is lost when converting to 18 decimals
                if (tokenAmount % (10 ** (decimals - 18)) != 0) {
                    revert PrecisionLost(tokenAmount, decimals);
                }

                // this will scale down the amount by the difference between the token's decimals and 18
                amountD18 = (tokenAmount * DecimalMath.UNIT) / (10 ** decimals);
            }
        } catch {
            // if the token doesn't have a decimals function, assume it's 18 decimals
            amountD18 = tokenAmount;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Represents a given amount of collateral locked until a given date.
 */
library CollateralLock {
    struct Data {
        /**
         * @dev The amount of collateral that has been locked.
         */
        uint128 amountD18;
        /**
         * @dev The date when the locked amount becomes unlocked.
         */
        uint64 lockExpirationTime;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title System wide configuration for anything
 */
library Config {
    struct Data {
        uint256 __unused;
    }

    /**
     * @dev Returns a config value
     */
    function read(bytes32 k, bytes32 zeroValue) internal view returns (bytes32 v) {
        bytes32 s = keccak256(abi.encode("Config", k));
        assembly {
            v := sload(s)
        }

        if (v == bytes32(0)) {
            v = zeroValue;
        }
    }

    function readUint(bytes32 k, uint256 zeroValue) internal view returns (uint256 v) {
        // solhint-disable-next-line numcast/safe-cast
        return uint(read(k, bytes32(zeroValue)));
    }

    function readAddress(bytes32 k, address zeroValue) internal view returns (address v) {
        // solhint-disable-next-line numcast/safe-cast
        return address(uint160(readUint(k, uint160(zeroValue))));
    }

    function put(bytes32 k, bytes32 v) internal {
        bytes32 s = keccak256(abi.encode("Config", k));
        assembly {
            sstore(s, v)
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "./DistributionActor.sol";

/**
 * @title Data structure that allows you to track some global value, distributed amongst a set of actors.
 *
 * The total value can be scaled with a valuePerShare multiplier, and individual actor shares can be calculated as their amount of shares times this multiplier.
 *
 * Furthermore, changes in the value of individual actors can be tracked since their last update, by keeping track of the value of the multiplier, per user, upon each interaction. See DistributionActor.lastValuePerShare.
 *
 * A distribution is similar to a ScalableMapping, but it has the added functionality of being able to remember the previous value of the scalar multiplier for each actor.
 *
 * Whenever the shares of an actor of the distribution is updated, you get information about how the actor's total value changed since it was last updated.
 */
library Distribution {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using DecimalMath for int256;

    /**
     * @dev Thrown when an attempt is made to distribute value to a distribution
     * with no shares.
     */
    error EmptyDistribution();

    struct Data {
        /**
         * @dev The total number of shares in the distribution.
         */
        uint128 totalSharesD18;
        /**
         * @dev The value per share of the distribution, represented as a high precision decimal.
         */
        int128 valuePerShareD27;
        /**
         * @dev Tracks individual actor information, such as how many shares an actor has, their lastValuePerShare, etc.
         */
        mapping(bytes32 => DistributionActor.Data) actorInfo;
    }

    /**
     * @dev Inflates or deflates the total value of the distribution by the given value.
     *
     * The value being distributed ultimately modifies the distribution's valuePerShare.
     */
    function distributeValue(Data storage self, int256 valueD18) internal {
        if (valueD18 == 0) {
            return;
        }

        uint256 totalSharesD18 = self.totalSharesD18;

        if (totalSharesD18 == 0) {
            revert EmptyDistribution();
        }

        int256 valueD45 = valueD18 * DecimalMath.UNIT_PRECISE_INT;
        int256 deltaValuePerShareD27 = valueD45 / totalSharesD18.toInt();

        self.valuePerShareD27 += deltaValuePerShareD27.to128();
    }

    /**
     * @dev Updates an actor's number of shares in the distribution to the specified amount.
     *
     * Whenever an actor's shares are changed in this way, we record the distribution's current valuePerShare into the actor's lastValuePerShare record.
     *
     * Returns the the amount by which the actors value changed since the last update.
     */
    function setActorShares(
        Data storage self,
        bytes32 actorId,
        uint256 newActorSharesD18
    ) internal returns (int256 valueChangeD18) {
        valueChangeD18 = getActorValueChange(self, actorId);

        DistributionActor.Data storage actor = self.actorInfo[actorId];

        uint128 sharesUint128D18 = newActorSharesD18.to128();
        self.totalSharesD18 = self.totalSharesD18 + sharesUint128D18 - actor.sharesD18;

        actor.sharesD18 = sharesUint128D18;
        _updateLastValuePerShare(self, actor, newActorSharesD18);
    }

    /**
     * @dev Updates an actor's lastValuePerShare to the distribution's current valuePerShare, and
     * returns the change in value for the actor, since their last update.
     */
    function accumulateActor(
        Data storage self,
        bytes32 actorId
    ) internal returns (int256 valueChangeD18) {
        DistributionActor.Data storage actor = self.actorInfo[actorId];
        return _updateLastValuePerShare(self, actor, actor.sharesD18);
    }

    /**
     * @dev Calculates how much an actor's value has changed since its shares were last updated.
     *
     * This change is calculated as:
     * Since `value = valuePerShare * shares`,
     * then `delta_value = valuePerShare_now * shares - valuePerShare_then * shares`,
     * which is `(valuePerShare_now - valuePerShare_then) * shares`,
     * or just `delta_valuePerShare * shares`.
     */
    function getActorValueChange(
        Data storage self,
        bytes32 actorId
    ) internal view returns (int256 valueChangeD18) {
        return _getActorValueChange(self, self.actorInfo[actorId]);
    }

    /**
     * @dev Returns the number of shares owned by an actor in the distribution.
     */
    function getActorShares(
        Data storage self,
        bytes32 actorId
    ) internal view returns (uint256 sharesD18) {
        return self.actorInfo[actorId].sharesD18;
    }

    /**
     * @dev Returns the distribution's value per share in normal precision (18 decimals).
     * @param self The distribution whose value per share is being queried.
     * @return The value per share in 18 decimal precision.
     */
    function getValuePerShare(Data storage self) internal view returns (int256) {
        return self.valuePerShareD27.to256().downscale(DecimalMath.PRECISION_FACTOR);
    }

    function _updateLastValuePerShare(
        Data storage self,
        DistributionActor.Data storage actor,
        uint256 newActorShares
    ) private returns (int256 valueChangeD18) {
        valueChangeD18 = _getActorValueChange(self, actor);

        actor.lastValuePerShareD27 = newActorShares == 0
            ? SafeCastI128.zero()
            : self.valuePerShareD27;
    }

    function _getActorValueChange(
        Data storage self,
        DistributionActor.Data storage actor
    ) private view returns (int256 valueChangeD18) {
        int256 deltaValuePerShareD27 = self.valuePerShareD27 - actor.lastValuePerShareD27;

        int256 changedValueD45 = deltaValuePerShareD27 * actor.sharesD18.toInt();
        valueChangeD18 = changedValueD45 / DecimalMath.UNIT_PRECISE_INT;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Stores information for specific actors in a Distribution.
 */
library DistributionActor {
    struct Data {
        /**
         * @dev The actor's current number of shares in the associated distribution.
         */
        uint128 sharesD18;
        /**
         * @dev The value per share that the associated distribution had at the time that the actor's number of shares was last modified.
         *
         * Note: This is also a high precision decimal. See Distribution.valuePerShare.
         */
        int128 lastValuePerShareD27;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/HeapUtil.sol";

import "./Distribution.sol";
import "./CollateralConfiguration.sol";
import "./MarketPoolInfo.sol";

import "../interfaces/external/IMarket.sol";

/**
 * @title Connects external contracts that implement the `IMarket` interface to the system.
 *
 * Pools provide credit capacity (collateral) to the markets, and are reciprocally exposed to the associated market's debt.
 *
 * The Market object's main responsibility is to track collateral provided by the pools that support it, and to trace their debt back to such pools.
 */
library Market {
    using Distribution for Distribution.Data;
    using HeapUtil for HeapUtil.Data;
    using DecimalMath for uint256;
    using DecimalMath for uint128;
    using DecimalMath for int256;
    using DecimalMath for int128;
    using SafeCastU256 for uint256;
    using SafeCastU128 for uint128;
    using SafeCastI256 for int256;
    using SafeCastI128 for int128;

    /**
     * @dev Thrown when a specified market is not found.
     */
    error MarketNotFound(uint128 marketId);

    struct Data {
        /**
         * @dev Numeric identifier for the market. Must be unique.
         * @dev There cannot be a market with id zero (See MarketCreator.create()). Id zero is used as a null market reference.
         */
        uint128 id;
        /**
         * @dev Address for the external contract that implements the `IMarket` interface, which this Market objects connects to.
         *
         * Note: This object is how the system tracks the market. The actual market is external to the system, i.e. its own contract.
         */
        address marketAddress;
        /**
         * @dev Issuance can be seen as how much USD the Market "has issued", printed, or has asked the system to mint on its behalf.
         *
         * More precisely it can be seen as the net difference between the USD burnt and the USD minted by the market.
         *
         * More issuance means that the market owes more USD to the system.
         *
         * A market burns USD when users deposit it in exchange for some asset that the market offers.
         * The Market object calls `MarketManager.depositUSD()`, which burns the USD, and decreases its issuance.
         *
         * A market mints USD when users return the asset that the market offered and thus withdraw their USD.
         * The Market object calls `MarketManager.withdrawUSD()`, which mints the USD, and increases its issuance.
         *
         * Instead of burning, the Market object could transfer USD to and from the MarketManager, but minting and burning takes the USD out of circulation, which doesn't affect `totalSupply`, thus simplifying accounting.
         *
         * How much USD a market can mint depends on how much credit capacity is given to the market by the pools that support it, and reflected in `Market.capacity`.
         *
         */
        int128 netIssuanceD18;
        /**
         * @dev The total amount of USD that the market could withdraw if it were to immediately unwrap all its positions.
         *
         * The Market's credit capacity increases when the market burns USD, i.e. when it deposits USD in the MarketManager.
         *
         * It decreases when the market mints USD, i.e. when it withdraws USD from the MarketManager.
         *
         * The Market's credit capacity also depends on how much credit is given to it by the pools that support it.
         *
         * The Market's credit capacity also has a dependency on the external market reported debt as it will respond to that debt (and hence change the credit capacity if it increases or decreases)
         *
         * The credit capacity can go negative if all of the collateral provided by pools is exhausted, and there is market provided collateral available to consume. in this case, the debt is still being
         * appropriately assigned, but the market has a dynamic cap based on deposited collateral types.
         *
         */
        int128 creditCapacityD18;
        /**
         * @dev The total balance that the market had the last time that its debt was distributed.
         *
         * A Market's debt is distributed when the reported debt of its associated external market is rolled into the pools that provide credit capacity to it.
         */
        int128 lastDistributedMarketBalanceD18;
        /**
         * @dev A heap of pools for which the market has not yet hit its maximum credit capacity.
         *
         * The heap is ordered according to this market's max value per share setting in the pools that provide credit capacity to it. See `MarketConfiguration.maxDebtShareValue`.
         *
         * The heap's getMax() and extractMax() functions allow us to retrieve the pool with the lowest `maxDebtShareValue`, since its elements are inserted and prioritized by negating their `maxDebtShareValue`.
         *
         * Lower max values per share are on the top of the heap. I.e. the heap could look like this:
         *  .    -1
         *      / \
         *     /   \
         *    -2    \
         *   / \    -3
         * -4   -5
         *
         * TL;DR: This data structure allows us to easily find the pool with the lowest or "most vulnerable" max value per share and process it if its actual value per share goes beyond this limit.
         */
        HeapUtil.Data inRangePools;
        /**
         * @dev A heap of pools for which the market has hit its maximum credit capacity.
         *
         * Used to reconnect pools to the market, when it falls back below its maximum credit capacity.
         *
         * See inRangePools for why a heap is used here.
         */
        HeapUtil.Data outRangePools;
        /**
         * @dev A market's debt distribution connects markets to the debt distribution chain, in this case pools. Pools are actors in the market's debt distribution, where the amount of shares they possess depends on the amount of collateral they provide to the market. The value per share of this distribution depends on the total debt or balance of the market (netIssuance + reportedDebt).
         *
         * The debt distribution chain will move debt from the market into its connected pools.
         *
         * Actors: Pools.
         * Shares: The USD denominated credit capacity that the pool provides to the market.
         * Value per share: Debt per dollar of credit that the associated external market accrues.
         *
         */
        Distribution.Data poolsDebtDistribution;
        /**
         * @dev Additional info needed to remember pools when they are removed from the distribution (or subsequently re-added).
         */
        mapping(uint128 => MarketPoolInfo.Data) pools;
        /**
         * @dev Array of entries of market provided collateral.
         *
         * Markets may obtain additional liquidity, beyond that coming from depositors, by providing their own collateral.
         *
         */
        DepositedCollateral[] depositedCollateral;
        /**
         * @dev The maximum amount of market provided collateral, per type, that this market can deposit.
         */
        mapping(address => uint256) maximumDepositableD18;
        uint32 minDelegateTime;
        uint32 __reservedForLater1;
        uint64 __reservedForLater2;
        uint64 __reservedForLater3;
        uint64 __reservedForLater4;
        /**
         * @dev Market-specific override of the minimum liquidity ratio
         */
        uint256 minLiquidityRatioD18;
    }

    /**
     * @dev Data structure that allows the Market to track the amount of market provided collateral, per type.
     */
    struct DepositedCollateral {
        address collateralType;
        uint256 amountD18;
    }

    /**
     * @dev Returns the market stored at the specified market id.
     */
    function load(uint128 id) internal pure returns (Data storage market) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.Market", id));
        assembly {
            market.slot := s
        }
    }

    /**
     * @dev Queries the external market contract for the amount of debt it has issued.
     *
     * The reported debt of a market represents the amount of USD that the market would ask the system to mint, if all of its positions were to be immediately closed.
     *
     * The reported debt of a market is collateralized by the assets in the pools which back it.
     *
     * See the `IMarket` interface.
     */
    function getReportedDebt(Data storage self) internal view returns (uint256) {
        return IMarket(self.marketAddress).reportedDebt(self.id);
    }

    /**
     * @dev Queries the market for the amount of collateral which should be prevented from withdrawal.
     */
    function getLockedCreditCapacity(Data storage self) internal view returns (uint256) {
        return IMarket(self.marketAddress).minimumCredit(self.id);
    }

    /**
     * @dev Returns the total debt of the market.
     *
     * A market's total debt represents its debt plus its issuance, and thus represents the total outstanding debt of the market.
     *
     * Note: it also takes into account the deposited collateral value. See note in  getDepositedCollateralValue()
     *
     * Example:
     * (1 EUR = 1.11 USD)
     * If an Euro market has received 100 USD to mint 90 EUR, its reported debt is 90 EUR or 100 USD, and its issuance is -100 USD.
     * Thus, its total balance is 100 USD of reported debt minus 100 USD of issuance, which is 0 USD.
     *
     * Additionally, the market's totalDebt might be affected by price fluctuations via reportedDebt, or fees.
     *
     */
    function totalDebt(Data storage self) internal view returns (int256) {
        return
            getReportedDebt(self).toInt() +
            self.netIssuanceD18 -
            getDepositedCollateralValue(self).toInt();
    }

    /**
     * @dev Returns the USD value for the total amount of collateral provided by the market itself.
     *
     * Note: This is not credit capacity provided by depositors through pools.
     */
    function getDepositedCollateralValue(Data storage self) internal view returns (uint256) {
        uint256 totalDepositedCollateralValueD18 = 0;

        // Sweep all DepositedCollateral entries and aggregate their USD value.
        for (uint256 i = 0; i < self.depositedCollateral.length; i++) {
            DepositedCollateral memory entry = self.depositedCollateral[i];
            CollateralConfiguration.Data storage collateralConfiguration = CollateralConfiguration
                .load(entry.collateralType);

            if (entry.amountD18 == 0) {
                continue;
            }

            uint256 priceD18 = CollateralConfiguration.getCollateralPrice(
                collateralConfiguration,
                entry.amountD18
            );

            totalDepositedCollateralValueD18 += priceD18.mulDecimal(entry.amountD18);
        }

        return totalDepositedCollateralValueD18;
    }

    /**
     * @dev Returns the amount of credit capacity that a certain pool provides to the market.

     * This credit capacity is obtained by reading the amount of shares that the pool has in the market's debt distribution, which represents the amount of USD denominated credit capacity that the pool has provided to the market.
     */
    function getPoolCreditCapacity(
        Data storage self,
        uint128 poolId
    ) internal view returns (uint256) {
        return self.poolsDebtDistribution.getActorShares(poolId.toBytes32());
    }

    /**
     * @dev Given an amount of shares that represent USD credit capacity from a pool, and a maximum value per share, returns the potential contribution to credit capacity that these shares could accrue, if their value per share was to hit the maximum.
     *
     * The resulting value is calculated multiplying the amount of creditCapacity provided by the pool by the delta between the maxValue per share vs current value.
     *
     * This function is used when the Pools are rebalanced to adjust each pool credit capacity based on a change in the amount of shares provided and/or a new maxValue per share
     *
     */
    function getCreditCapacityContribution(
        Data storage self,
        uint256 creditCapacitySharesD18,
        int256 maxShareValueD18
    ) internal view returns (int256 contributionD18) {
        // Determine how much the current value per share deviates from the maximum.
        uint256 deltaValuePerShareD18 = (maxShareValueD18 -
            self.poolsDebtDistribution.getValuePerShare()).toUint();

        return deltaValuePerShareD18.mulDecimal(creditCapacitySharesD18).toInt();
    }

    /**
     * @dev Returns true if the market's current capacity is below the amount of locked capacity.
     *
     */
    function isCapacityLocked(Data storage self) internal view returns (bool) {
        return self.creditCapacityD18 < getLockedCreditCapacity(self).toInt();
    }

    /**
     * @dev Gets any outstanding debt. Do not call this method except in tests
     *
     * Note: This function should only be used in tests!
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_getOutstandingDebt(
        Data storage self,
        uint128 poolId
    ) internal returns (int256 debtChangeD18) {
        return
            self.pools[poolId].pendingDebtD18.toInt() +
            self.poolsDebtDistribution.accumulateActor(poolId.toBytes32());
    }

    /**
     * Returns the number of pools currently active in the market
     *
     * Note: this is test only
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_inRangePools(Data storage self) internal view returns (uint256) {
        return self.inRangePools.size();
    }

    /**
     * Returns the number of pools currently active in the market
     *
     * Note: this is test only
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_outRangePools(Data storage self) internal view returns (uint256) {
        return self.outRangePools.size();
    }

    /**
     * @dev Returns the debt value per share
     */
    function getDebtPerShare(Data storage self) internal view returns (int256 debtPerShareD18) {
        return self.poolsDebtDistribution.getValuePerShare();
    }

    /**
     * @dev Determine the amount of debt the pool would assume if its lastValue was updated
     * Needed for optimization.
     *
     * Called by a pool when it distributes its debt.
     *
     */
    function accumulateDebtChange(
        Data storage self,
        uint128 poolId
    ) internal returns (int256 debtChangeD18) {
        int256 changedValueD18 = self.poolsDebtDistribution.accumulateActor(poolId.toBytes32());
        debtChangeD18 = self.pools[poolId].pendingDebtD18.toInt() + changedValueD18;
        self.pools[poolId].pendingDebtD18 = 0;
    }

    /**
     * @dev Wrapper that adjusts a pool's shares in the market's credit capacity, making sure that the market's outstanding debt is first passed on to its connected pools.
     *
     * Called by a pool when it distributes its debt.
     *
     */
    function rebalancePools(
        uint128 marketId,
        uint128 poolId,
        int256 maxDebtShareValueD18, // (in USD)
        uint256 newCreditCapacityD18 // in collateralValue (USD)
    ) internal returns (int256 debtChangeD18) {
        Data storage self = load(marketId);

        if (self.marketAddress == address(0)) {
            revert MarketNotFound(marketId);
        }

        return adjustPoolShares(self, poolId, newCreditCapacityD18, maxDebtShareValueD18);
    }

    /**
     * @dev Called by pools when they modify the credit capacity provided to the market, as well as the maximum value per share they tolerate for the market.
     *
     * These two settings affect the market in the following ways:
     * - Updates the pool's shares in `poolsDebtDistribution`.
     * - Moves the pool in and out of inRangePools/outRangePools.
     * - Updates the market credit capacity property.
     */
    function adjustPoolShares(
        Data storage self,
        uint128 poolId,
        uint256 newCreditCapacityD18,
        int256 newPoolMaxShareValueD18
    ) internal returns (int256 debtChangeD18) {
        uint256 oldCreditCapacityD18 = getPoolCreditCapacity(self, poolId);
        int256 oldPoolMaxShareValueD18 = -self.inRangePools.getById(poolId).priority;

        // Sanity checks
        // require(oldPoolMaxShareValue == 0, "value is not 0");
        // require(newPoolMaxShareValue == 0, "new pool max share value is in fact set");

        self.pools[poolId].creditCapacityAmountD18 = newCreditCapacityD18.to128();

        int128 valuePerShareD18 = self.poolsDebtDistribution.getValuePerShare().to128();

        if (newCreditCapacityD18 == 0) {
            self.inRangePools.extractById(poolId);
            self.outRangePools.extractById(poolId);
        } else if (newPoolMaxShareValueD18 < valuePerShareD18) {
            // this will ensure calculations below can correctly gauge shares changes
            newCreditCapacityD18 = 0;
            self.inRangePools.extractById(poolId);
            self.outRangePools.insert(poolId, newPoolMaxShareValueD18.to128());
        } else {
            self.inRangePools.insert(poolId, -newPoolMaxShareValueD18.to128());
            self.outRangePools.extractById(poolId);
        }

        int256 changedValueD18 = self.poolsDebtDistribution.setActorShares(
            poolId.toBytes32(),
            newCreditCapacityD18
        );
        debtChangeD18 = self.pools[poolId].pendingDebtD18.toInt() + changedValueD18;
        self.pools[poolId].pendingDebtD18 = 0;

        // recalculate market capacity
        if (newPoolMaxShareValueD18 > valuePerShareD18) {
            self.creditCapacityD18 += getCreditCapacityContribution(
                self,
                newCreditCapacityD18,
                newPoolMaxShareValueD18
            ).to128();
        }

        if (oldPoolMaxShareValueD18 > valuePerShareD18) {
            self.creditCapacityD18 -= getCreditCapacityContribution(
                self,
                oldCreditCapacityD18,
                oldPoolMaxShareValueD18
            ).to128();
        }
    }

    /**
     * @dev Moves debt from the market into the pools that connect to it.
     *
     * This function should be called before any of the pools' shares are modified in `poolsDebtDistribution`.
     *
     * Note: The parameter `maxIter` is used as an escape hatch to discourage griefing.
     */
    function distributeDebtToPools(
        Data storage self,
        uint256 maxIter
    ) internal returns (bool fullyDistributed) {
        // Get the current and last distributed market balances.
        // Note: The last distributed balance will be cached within this function's execution.
        int256 targetBalanceD18 = totalDebt(self);
        int256 outstandingBalanceD18 = targetBalanceD18 - self.lastDistributedMarketBalanceD18;

        (, bool exhausted) = bumpPools(self, outstandingBalanceD18, maxIter);

        if (!exhausted && self.poolsDebtDistribution.totalSharesD18 > 0) {
            // cannot use `outstandingBalance` here because `self.lastDistributedMarketBalance`
            // may have changed after calling the bump functions above
            self.poolsDebtDistribution.distributeValue(
                targetBalanceD18 - self.lastDistributedMarketBalanceD18
            );
            self.lastDistributedMarketBalanceD18 = targetBalanceD18.to128();
        }

        return !exhausted;
    }

    /**
     * @dev Determine the target valuePerShare of the poolsDebtDistribution, given the value that is yet to be distributed.
     */
    function getTargetValuePerShare(
        Market.Data storage self,
        int256 valueToDistributeD18
    ) internal view returns (int256 targetValuePerShareD18) {
        return
            self.poolsDebtDistribution.getValuePerShare() +
            (
                self.poolsDebtDistribution.totalSharesD18 > 0
                    ? valueToDistributeD18.divDecimal(
                        self.poolsDebtDistribution.totalSharesD18.toInt()
                    ) // solhint-disable-next-line numcast/safe-cast
                    : int256(0)
            );
    }

    /**
     * @dev Finds pools for which this market's max value per share limit is hit, distributes their debt, and disconnects the market from them.
     *
     * The debt is distributed up to the limit of the max value per share that the pool tolerates on the market.
     */
    function bumpPools(
        Data storage self,
        int256 maxDistributedD18,
        uint256 maxIter
    ) internal returns (int256 actuallyDistributedD18, bool exhausted) {
        if (maxDistributedD18 == 0) {
            return (0, false);
        }

        // Determine the direction based on the amount to be distributed.
        int128 k;
        HeapUtil.Data storage fromHeap;
        HeapUtil.Data storage toHeap;
        if (maxDistributedD18 > 0) {
            k = 1;
            fromHeap = self.inRangePools;
            toHeap = self.outRangePools;
        } else {
            k = -1;
            fromHeap = self.outRangePools;
            toHeap = self.inRangePools;
        }

        // Note: This loop should rarely execute its main body. When it does, it only executes once for each pool that exceeds the limit since `distributeValue` is not run for most pools. Thus, market users are not hit with any overhead as a result of this.
        uint256 iters;
        for (iters = 0; iters < maxIter; iters++) {
            // Exit if there are no pools that can be moved
            if (fromHeap.size() == 0) {
                break;
            }

            // Identify the pool with the lowest maximum value per share.
            HeapUtil.Node memory edgePool = fromHeap.getMax();

            // 2 cases where we want to break out of this loop
            if (
                // If there is no pool in range, and we are going down
                (maxDistributedD18 - actuallyDistributedD18 > 0 &&
                    self.poolsDebtDistribution.totalSharesD18 == 0) ||
                // If there is a pool in ragne, and the lowest max value per share does not hit the limit, exit
                // Note: `-edgePool.priority` is actually the max value per share limit of the pool
                (self.poolsDebtDistribution.totalSharesD18 > 0 &&
                    -edgePool.priority >=
                    k * getTargetValuePerShare(self, (maxDistributedD18 - actuallyDistributedD18)))
            ) {
                break;
            }

            // The pool has hit its maximum value per share and needs to be removed.
            // Note: No need to update capacity because pool max share value = valuePerShare when this happens.
            togglePool(fromHeap, toHeap);

            // Distribute the market's debt to the limit, i.e. for that which exceeds the maximum value per share.
            if (self.poolsDebtDistribution.totalSharesD18 > 0) {
                int256 debtToLimitD18 = self
                    .poolsDebtDistribution
                    .totalSharesD18
                    .toInt()
                    .mulDecimal(
                        -k * edgePool.priority - self.poolsDebtDistribution.getValuePerShare() // Diff between current value and max value per share.
                    );
                self.poolsDebtDistribution.distributeValue(debtToLimitD18);

                // Update the global distributed and outstanding balances with the debt that was just distributed.
                actuallyDistributedD18 += debtToLimitD18;
            } else {
                self.poolsDebtDistribution.valuePerShareD27 = (-k * edgePool.priority)
                    .to256()
                    .upscale(DecimalMath.PRECISION_FACTOR)
                    .to128();
            }

            // Detach the market from this pool by removing the pool's shares from the market.
            // The pool will remain "detached" until the pool manager specifies a new poolsDebtDistribution.
            if (maxDistributedD18 > 0) {
                // the below requires are only for sanity
                require(
                    self.poolsDebtDistribution.getActorShares(edgePool.id.toBytes32()) > 0,
                    "no shares before actor removal"
                );

                uint256 newPoolDebtD18 = self
                    .poolsDebtDistribution
                    .setActorShares(edgePool.id.toBytes32(), 0)
                    .toUint();
                self.pools[edgePool.id].pendingDebtD18 += newPoolDebtD18.to128();
            } else {
                require(
                    self.poolsDebtDistribution.getActorShares(edgePool.id.toBytes32()) == 0,
                    "actor has shares before add"
                );

                self.poolsDebtDistribution.setActorShares(
                    edgePool.id.toBytes32(),
                    self.pools[edgePool.id].creditCapacityAmountD18
                );
            }
        }

        // Record the accumulated distributed balance.
        self.lastDistributedMarketBalanceD18 += actuallyDistributedD18.to128();

        exhausted = iters == maxIter;
    }

    /**
     * @dev Moves a pool from one heap into another.
     */
    function togglePool(HeapUtil.Data storage from, HeapUtil.Data storage to) internal {
        HeapUtil.Node memory node = from.extractMax();
        to.insert(node.id, -node.priority);
    }

    /**
     * @dev Returns whether or not a pool is past its maxDebtPerShare configuration for this market
     */
    function isPoolInRange(Data storage self, uint128 poolId) internal view returns (bool) {
        return self.inRangePools.getById(poolId).id == poolId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Tracks a market's weight within a Pool, and its maximum debt.
 *
 * Each pool has an array of these, with one entry per market managed by the pool.
 *
 * A market's weight determines how much liquidity the pool provides to the market, and how much debt exposure the market gives the pool.
 *
 * Weights are used to calculate percentages by adding all the weights in the pool and dividing the market's weight by the total weights.
 *
 * A market's maximum debt in a pool is indicated with a maximum debt value per share.
 */
library MarketConfiguration {
    struct Data {
        /**
         * @dev Numeric identifier for the market.
         *
         * Must be unique, and in a list of `MarketConfiguration[]`, must be increasing.
         */
        uint128 marketId;
        /**
         * @dev The ratio of each market's `weight` to the pool's `totalWeights` determines the pro-rata share of the market to the pool's total liquidity.
         */
        uint128 weightD18;
        /**
         * @dev Maximum value per share that a pool will tolerate for this market.
         *
         * If the the limit is met, the markets exceeding debt will be distributed, and it will be disconnected from the pool that no longer provides credit to it.
         *
         * Note: This value will have no effect if the system wide limit is hit first. See `PoolConfiguration.minLiquidityRatioD18`.
         */
        int128 maxDebtShareValueD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Stores information regarding a pool's relationship to a market, such that it can be added or removed from a distribution
 */
library MarketPoolInfo {
    struct Data {
        /**
         * @dev The credit capacity that this pool is providing to the relevant market. Needed to re-add the pool to the distribution when going back in range.
         */
        uint128 creditCapacityAmountD18;
        /**
         * @dev The amount of debt the pool has which hasn't been passed down the debt distribution chain yet.
         */
        uint128 pendingDebtD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Represents Oracle Manager
 */
library OracleManager {
    bytes32 private constant _SLOT_ORACLE_MANAGER =
        keccak256(abi.encode("io.synthetix.synthetix.OracleManager"));

    struct Data {
        /**
         * @dev The oracle manager address.
         */
        address oracleManagerAddress;
    }

    /**
     * @dev Loads the singleton storage info about the oracle manager.
     */
    function load() internal pure returns (Data storage oracleManager) {
        bytes32 s = _SLOT_ORACLE_MANAGER;
        assembly {
            oracleManager.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./Config.sol";
import "./Distribution.sol";
import "./MarketConfiguration.sol";
import "./Vault.sol";
import "./Market.sol";
import "./PoolCollateralConfiguration.sol";
import "./SystemPoolConfiguration.sol";
import "./PoolCollateralConfiguration.sol";

import "@synthetixio/core-contracts/contracts/errors/AccessError.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";

/**
 * @title Aggregates collateral from multiple users in order to provide liquidity to a configurable set of markets.
 *
 * The set of markets is configured as an array of MarketConfiguration objects, where the weight of the market can be specified. This weight, and the aggregated total weight of all the configured markets, determines how much collateral from the pool each market has, as well as in what proportion the market passes on debt to the pool and thus to all its users.
 *
 * The pool tracks the collateral provided by users using an array of Vaults objects, for which there will be one per collateral type. Each vault tracks how much collateral each user has delegated to this pool, how much debt the user has because of minting USD, as well as how much corresponding debt the pool has passed on to the user.
 */
library Pool {
    using CollateralConfiguration for CollateralConfiguration.Data;
    using Market for Market.Data;
    using Vault for Vault.Data;
    using VaultEpoch for VaultEpoch.Data;
    using Distribution for Distribution.Data;
    using DecimalMath for uint256;
    using DecimalMath for int256;
    using DecimalMath for int128;
    using SafeCastAddress for address;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    /**
     * @dev Thrown when the specified pool is not found.
     */
    error PoolNotFound(uint128 poolId);

    /**
     * @dev Thrown when attempting to create a pool that already exists.
     */
    error PoolAlreadyExists(uint128 poolId);

    /**
     * @dev Thrown when min delegation time for a market connected to the pool has not elapsed
     */
    error MinDelegationTimeoutPending(uint128 poolId, uint32 timeRemaining);

    /**
     * @dev Thrown when pool has surpassed max collateral deposit
     */
    error PoolCollateralLimitExceeded(
        uint128 poolId,
        address collateralType,
        uint256 currentCollateral,
        uint256 maxCollateral
    );

    bytes32 private constant _CONFIG_SET_MARKET_MIN_DELEGATE_MAX = "setMarketMinDelegateTime_max";

    struct Data {
        /**
         * @dev Numeric identifier for the pool. Must be unique.
         * @dev A pool with id zero exists! (See Pool.loadExisting()). Users can delegate to this pool to be able to mint USD without being exposed to fluctuating debt.
         */
        uint128 id;
        /**
         * @dev Text identifier for the pool.
         *
         * Not required to be unique.
         */
        string name;
        /**
         * @dev Creator of the pool, which has configuration access rights for the pool.
         *
         * See onlyPoolOwner.
         */
        address owner;
        /**
         * @dev Allows the current pool owner to nominate a new owner, and thus transfer pool configuration credentials.
         */
        address nominatedOwner;
        /**
         * @dev Sum of all market weights.
         *
         * Market weights are tracked in `MarketConfiguration.weight`, one for each market. The ratio of each market's `weight` to the pool's `totalWeights` determines the pro-rata share of the market to the pool's total liquidity.
         *
         * Reciprocally, this pro-rata share also determines how much the pool is exposed to each market's debt.
         */
        uint128 totalWeightsD18;
        /**
         * @dev Accumulated cache value of all vault collateral debts
         */
        int128 totalVaultDebtsD18;
        /**
         * @dev Array of markets connected to this pool, and their configurations. I.e. weight, etc.
         *
         * See totalWeights.
         */
        MarketConfiguration.Data[] marketConfigurations;
        /**
         * @dev A pool's debt distribution connects pools to the debt distribution chain, i.e. vaults and markets. Vaults are actors in the pool's debt distribution, where the amount of shares they possess depends on the amount of collateral each vault delegates to the pool.
         *
         * The debt distribution chain will move debt from markets into this pools, and then from pools to vaults.
         *
         * Actors: Vaults.
         * Shares: USD value, proportional to the amount of collateral that the vault delegates to the pool.
         * Value per share: Debt per dollar of collateral. Depends on aggregated debt of connected markets.
         *
         */
        Distribution.Data vaultsDebtDistribution;
        /**
         * @dev Reference to all the vaults that provide liquidity to this pool.
         *
         * Each collateral type will have its own vault, specific to this pool. I.e. if two pools both use SNX collateral, each will have its own SNX vault.
         *
         * Vaults track user collateral and debt using a debt distribution, which is connected to the debt distribution chain.
         */
        mapping(address => Vault.Data) vaults;
        uint64 lastConfigurationTime;
        uint64 __reserved1;
        uint64 __reserved2;
        uint64 __reserved3;
        mapping(address => PoolCollateralConfiguration.Data) collateralConfigurations;
        /**
         * @dev A switch to make the pool opt-in for new collateral
         *
         * By default it's set to false, which means any new collateral accepeted by the system will be accpeted by the pool.
         *
         * If the pool owner sets this value to true, then new collaterals will be disabled for the pool unless a maxDeposit is set for a that collateral.
         */
        bool collateralDisabledByDefault;
    }

    /**
     * @dev Returns the pool stored at the specified pool id.
     */
    function load(uint128 id) internal pure returns (Data storage pool) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.Pool", id));
        assembly {
            pool.slot := s
        }
    }

    /**
     * @dev Creates a pool for the given pool id, and assigns the caller as its owner.
     *
     * Reverts if the specified pool already exists.
     */
    function create(uint128 id, address owner) internal returns (Pool.Data storage pool) {
        if (id == 0 || load(id).id == id) {
            revert PoolAlreadyExists(id);
        }

        pool = load(id);

        pool.id = id;
        pool.owner = owner;
    }

    /**
     * @dev Ticker function that updates the debt distribution chain downwards, from markets into the pool, according to each market's weight.
     * IMPORTANT: debt must be distributed downstream before invoking this function.
     *
     * It updates the chain by performing these actions:
     * - Splits the pool's total liquidity of the pool into each market, pro-rata. The amount of shares that the pool has on each market depends on how much liquidity the pool provides to the market.
     * - Accumulates the change in debt value from each market into the pools own vault debt distribution's value per share.
     */
    function rebalanceMarketsInPool(Data storage self) internal {
        uint256 totalWeightsD18 = self.totalWeightsD18;

        if (totalWeightsD18 == 0) {
            return; // Nothing to rebalance.
        }

        // Read from storage once, before entering the loop below.
        // These values should not change while iterating through each market.
        uint256 totalCreditCapacityD18 = self.vaultsDebtDistribution.totalSharesD18;
        int128 debtPerShareD18 = totalCreditCapacityD18 > 0 // solhint-disable-next-line numcast/safe-cast
            ? int256(self.totalVaultDebtsD18).divDecimal(totalCreditCapacityD18.toInt()).to128() // solhint-disable-next-line numcast/safe-cast
            : int128(0);

        uint256 systemMinLiquidityRatioD18 = SystemPoolConfiguration.load().minLiquidityRatioD18;

        // Loop through the pool's markets, applying market weights, and tracking how this changes the amount of debt that this pool is responsible for.
        // This debt extracted from markets is then applied to the pool's vault debt distribution, which thus exposes debt to the pool's vaults.
        for (uint256 i = 0; i < self.marketConfigurations.length; i++) {
            MarketConfiguration.Data storage marketConfiguration = self.marketConfigurations[i];

            uint256 weightD18 = marketConfiguration.weightD18;

            // Calculate each market's pro-rata USD liquidity.
            // Note: the factor `(weight / totalWeights)` is not deduped in the operations below to maintain numeric precision.

            uint256 marketCreditCapacityD18 = (totalCreditCapacityD18 * weightD18) /
                totalWeightsD18;

            Market.Data storage marketData = Market.load(marketConfiguration.marketId);

            // Use market-specific minimum liquidity ratio if set, otherwise use system default.
            uint256 minLiquidityRatioD18 = marketData.minLiquidityRatioD18 > 0
                ? marketData.minLiquidityRatioD18
                : systemMinLiquidityRatioD18;

            // Contain the pool imposed market's maximum debt share value.
            // Imposed by system.
            int256 effectiveMaxShareValueD18 = getSystemMaxValuePerShare(
                marketData.id,
                minLiquidityRatioD18,
                debtPerShareD18
            );
            // Imposed by pool.
            int256 configuredMaxShareValueD18 = marketConfiguration.maxDebtShareValueD18;
            effectiveMaxShareValueD18 = effectiveMaxShareValueD18 < configuredMaxShareValueD18
                ? effectiveMaxShareValueD18
                : configuredMaxShareValueD18;

            // Update each market's corresponding credit capacity.
            // The returned value represents how much the market's debt changed after changing the shares of this pool actor, which is aggregated to later be passed on the pools debt distribution.
            Market.rebalancePools(
                marketConfiguration.marketId,
                self.id,
                effectiveMaxShareValueD18,
                marketCreditCapacityD18
            );
        }
    }

    /**
     * @dev Determines the resulting maximum value per share for a market, according to a system-wide minimum liquidity ratio. This prevents markets from assigning more debt to pools than they have collateral to cover.
     *
     * Note: There is a market-wide fail safe for each market at `MarketConfiguration.maxDebtShareValue`. The lower of the two values should be used.
     *
     * See `SystemPoolConfiguration.minLiquidityRatio`.
     */
    function getSystemMaxValuePerShare(
        uint128 marketId,
        uint256 minLiquidityRatioD18,
        int256 debtPerShareD18
    ) internal view returns (int256) {
        // Retrieve the current value per share of the market.
        Market.Data storage marketData = Market.load(marketId);
        int256 valuePerShareD18 = marketData.poolsDebtDistribution.getValuePerShare();

        // Calculate the margin of debt that the market would incur if it hit the system wide limit.
        uint256 marginD18 = minLiquidityRatioD18 == 0
            ? DecimalMath.UNIT
            : DecimalMath.UNIT.divDecimal(minLiquidityRatioD18);

        // The resulting maximum value per share is the distribution's value per share,
        // plus the margin to hit the limit, minus the current debt per share.
        return valuePerShareD18 + marginD18.toInt() - debtPerShareD18;
    }

    /**
     * @dev Reverts if the pool does not exist with appropriate error. Otherwise, returns the pool.
     */
    function loadExisting(uint128 id) internal view returns (Data storage) {
        Data storage p = load(id);
        if (id != 0 && p.id != id) {
            revert PoolNotFound(id);
        }

        return p;
    }

    /**
     * @dev Returns true if the pool is exposed to the specified market.
     */
    function hasMarket(Data storage self, uint128 marketId) internal view returns (bool) {
        for (uint256 i = 0; i < self.marketConfigurations.length; i++) {
            if (
                self.marketConfigurations[i].marketId == marketId &&
                Market.load(marketId).isPoolInRange(self.id)
            ) {
                return true;
            }
        }

        return false;
    }

    /**
     * IMPORTANT: after this function, you should accumulateVaultDebt
     */
    function distributeDebtToVaults(
        Data storage self,
        address optionalCollateralType
    ) internal returns (int256 cumulativeDebtChange) {
        // Update each market's pro-rata liquidity and collect accumulated debt into the pool's debt distribution.
        uint128 myPoolId = self.id;
        for (uint256 i = 0; i < self.marketConfigurations.length; i++) {
            Market.Data storage market = Market.load(self.marketConfigurations[i].marketId);

            market.distributeDebtToPools(9999999999);
            cumulativeDebtChange += market.accumulateDebtChange(myPoolId);
        }

        assignDebt(self, cumulativeDebtChange);

        // Transfer the debt change from the pool into the vault.
        if (optionalCollateralType != address(0)) {
            bytes32 actorId = optionalCollateralType.toBytes32();
            self.vaults[optionalCollateralType].distributeDebtToAccounts(
                self.vaultsDebtDistribution.accumulateActor(actorId)
            );
        }
    }

    function assignDebt(Data storage self, int256 debtAmountD18) internal {
        // Accumulate the change in total liquidity, from the vault, into the pool.
        self.totalVaultDebtsD18 = self.totalVaultDebtsD18 + debtAmountD18.to128();

        self.vaultsDebtDistribution.distributeValue(debtAmountD18);
    }

    function assignDebtToAccount(
        Data storage self,
        address collateralType,
        uint128 accountId,
        int256 debtAmountD18
    ) internal {
        self.totalVaultDebtsD18 = self.totalVaultDebtsD18 + debtAmountD18.to128();

        self.vaults[collateralType].currentEpoch().assignDebtToAccount(accountId, debtAmountD18);
    }

    /**
     * @dev Ticker function that updates the debt distribution chain for a specific collateral type downwards, from the pool into the corresponding the vault, according to changes in the collateral's price.
     * IMPORTANT: *should* call distributeDebtToVaults() to ensure that deltaDebtD18 is referencing the latest
     *
     * It updates the chain by performing these actions:
     * - Collects the latest price of the corresponding collateral and updates the vault's liquidity.
     * - Updates the vaults shares in the pool's debt distribution, according to the collateral provided by the vault.
     * - Updates the value per share of the vault's debt distribution.
     */
    function recalculateVaultCollateral(
        Data storage self,
        address collateralType
    ) internal returns (uint256 collateralPriceD18) {
        // Get the latest collateral price.
        collateralPriceD18 = CollateralConfiguration.load(collateralType).getCollateralPrice(
            DecimalMath.UNIT
        );

        // Changes in price update the corresponding vault's total collateral value as well as its liquidity (collateral - debt).
        (uint256 usdWeightD18, ) = self.vaults[collateralType].updateCreditCapacity(
            collateralPriceD18
        );

        // Update the vault's shares in the pool's debt distribution, according to the value of its collateral.
        self.vaultsDebtDistribution.setActorShares(collateralType.toBytes32(), usdWeightD18);

        // now that available vault collateral has been recalculated, we should also rebalance the pool markets
        rebalanceMarketsInPool(self);
    }

    /**
     * @dev Updates the debt distribution chain for this pool, and consolidates the given account's debt.
     */
    function updateAccountDebt(
        Data storage self,
        address collateralType,
        uint128 accountId
    ) internal returns (int256 debtD18) {
        distributeDebtToVaults(self, collateralType);
        return self.vaults[collateralType].consolidateAccountDebt(accountId);
    }

    /**
     * @dev Clears all vault data for the specified collateral type.
     */
    function resetVault(Data storage self, address collateralType) internal {
        // Creates a new epoch in the vault, effectively zeroing out all values.
        self.vaults[collateralType].reset();

        // Ensure that the vault's values update the debt distribution chain.
        recalculateVaultCollateral(self, collateralType);
    }

    /**
     * @dev Calculates the collateralization ratio of the vault that tracks the given collateral type.
     *
     * The c-ratio is the vault's share of the total debt of the pool, divided by the collateral it delegates to the pool.
     *
     * Note: This is not a view function. It updates the debt distribution chain before performing any calculations.
     */
    function currentVaultCollateralRatio(
        Data storage self,
        address collateralType
    ) internal returns (uint256) {
        int256 vaultDebtD18 = currentVaultDebt(self, collateralType);
        (, uint256 collateralValueD18) = currentVaultCollateral(self, collateralType);

        return vaultDebtD18 > 0 ? collateralValueD18.divDecimal(vaultDebtD18.toUint()) : 0;
    }

    /**
     * @dev Finds a connected market whose credit capacity has reached its locked limit.
     *
     * Note: Returns market zero (null market) if none is found.
     */
    function findMarketWithCapacityLocked(
        Data storage self
    ) internal view returns (Market.Data storage lockedMarket) {
        for (uint256 i = 0; i < self.marketConfigurations.length; i++) {
            Market.Data storage market = Market.load(self.marketConfigurations[i].marketId);

            if (market.isCapacityLocked()) {
                return market;
            }
        }

        // Market zero = null market.
        return Market.load(0);
    }

    function getRequiredMinDelegationTime(
        Data storage self
    ) internal view returns (uint32 requiredMinDelegateTime) {
        for (uint256 i = 0; i < self.marketConfigurations.length; i++) {
            uint32 marketMinDelegateTime = Market
                .load(self.marketConfigurations[i].marketId)
                .minDelegateTime;

            if (marketMinDelegateTime > requiredMinDelegateTime) {
                requiredMinDelegateTime = marketMinDelegateTime;
            }
        }

        // solhint-disable-next-line numcast/safe-cast
        uint32 maxMinDelegateTime = uint32(
            Config.readUint(_CONFIG_SET_MARKET_MIN_DELEGATE_MAX, 86400 * 30)
        );
        return
            maxMinDelegateTime < requiredMinDelegateTime
                ? maxMinDelegateTime
                : requiredMinDelegateTime;
    }

    /**
     * @dev Returns the debt of the vault that tracks the given collateral type.
     *
     * The vault's debt is the vault's share of the total debt of the pool, or its share of the total debt of the markets connected to the pool. The size of this share depends on how much collateral the pool provides to the pool.
     *
     * Note: This is not a view function. It updates the debt distribution chain before performing any calculations.
     */
    function currentVaultDebt(Data storage self, address collateralType) internal returns (int256) {
        // TODO: assert that all debts have been paid, otherwise vault cant be reset (its so critical here)
        distributeDebtToVaults(self, collateralType);
        rebalanceMarketsInPool(self);
        return self.vaults[collateralType].currentDebt();
    }

    /**
     * @dev Returns the total amount and value of the specified collateral delegated to this pool.
     */
    function currentVaultCollateral(
        Data storage self,
        address collateralType
    ) internal view returns (uint256 collateralAmountD18, uint256 collateralValueD18) {
        uint256 collateralPriceD18 = CollateralConfiguration
            .load(collateralType)
            .getCollateralPrice(collateralAmountD18);

        collateralAmountD18 = self.vaults[collateralType].currentCollateral();
        collateralValueD18 = collateralPriceD18.mulDecimal(collateralAmountD18);
    }

    /**
     * @dev Returns the amount and value of collateral that the specified account has delegated to this pool.
     */
    function currentAccountCollateral(
        Data storage self,
        address collateralType,
        uint128 accountId
    ) internal view returns (uint256 collateralAmountD18, uint256 collateralValueD18) {
        collateralAmountD18 = self.vaults[collateralType].currentAccountCollateral(accountId);
        uint256 collateralPriceD18 = CollateralConfiguration
            .load(collateralType)
            .getCollateralPrice(collateralAmountD18);
        collateralValueD18 = collateralPriceD18.mulDecimal(collateralAmountD18);
    }

    /**
     * @dev Returns the specified account's collateralization ratio (collateral / debt).
     * @dev If the account's debt is negative or zero, returns an "infinite" c-ratio.
     */
    function currentAccountCollateralRatio(
        Data storage self,
        address collateralType,
        uint128 accountId
    ) internal returns (uint256) {
        int256 positionDebtD18 = updateAccountDebt(self, collateralType, accountId);
        rebalanceMarketsInPool(self);
        if (positionDebtD18 <= 0) {
            return type(uint256).max;
        }

        (, uint256 positionCollateralValueD18) = currentAccountCollateral(
            self,
            collateralType,
            accountId
        );

        return positionCollateralValueD18.divDecimal(positionDebtD18.toUint());
    }

    /**
     * @dev Reverts if the caller is not the owner of the specified pool.
     */
    function onlyPoolOwner(uint128 poolId, address caller) internal view {
        if (Pool.load(poolId).owner != caller) {
            revert AccessError.Unauthorized(caller);
        }
    }

    function requireMinDelegationTimeElapsed(
        Data storage self,
        uint64 lastDelegationTime
    ) internal view {
        uint32 requiredMinDelegationTime = getRequiredMinDelegationTime(self);
        if (block.timestamp < lastDelegationTime + requiredMinDelegationTime) {
            revert MinDelegationTimeoutPending(
                self.id,
                // solhint-disable-next-line numcast/safe-cast
                uint32(lastDelegationTime + requiredMinDelegationTime - block.timestamp)
            );
        }
    }

    function checkPoolCollateralLimit(
        Data storage self,
        address collateralType,
        uint256 collateralAmountD18
    ) internal view {
        uint256 collateralLimitD18 = self
            .collateralConfigurations[collateralType]
            .collateralLimitD18;
        uint256 currentCollateral = self.vaults[collateralType].currentCollateral();

        if (
            (self.collateralDisabledByDefault && collateralLimitD18 == 0) ||
            (collateralLimitD18 > 0 && currentCollateral + collateralAmountD18 > collateralLimitD18)
        ) {
            revert PoolCollateralLimitExceeded(
                self.id,
                collateralType,
                currentCollateral + collateralAmountD18,
                collateralLimitD18
            );
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library PoolCollateralConfiguration {
    bytes32 private constant _SLOT =
        keccak256(abi.encode("io.synthetix.synthetix.PoolCollateralConfiguration"));

    struct Data {
        uint256 collateralLimitD18;
        uint256 issuanceRatioD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "../interfaces/external/IRewardDistributor.sol";

import "./Distribution.sol";
import "./RewardDistributionClaimStatus.sol";

/**
 * @title Used by vaults to track rewards for its participants. There will be one of these for each pool, collateral type, and distributor combination.
 */
library RewardDistribution {
    using DecimalMath for int256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using SafeCastU64 for uint64;
    using SafeCastU32 for uint32;
    using SafeCastI32 for int32;

    struct Data {
        /**
         * @dev The 3rd party smart contract which holds/mints tokens for distributing rewards to vault participants.
         */
        IRewardDistributor distributor;
        /**
         * @dev Available slot.
         */
        uint128 __slotAvailableForFutureUse;
        /**
         * @dev The value of the rewards in this entry.
         */
        uint128 rewardPerShareD18;
        /**
         * @dev The status for each actor, regarding this distribution's entry.
         */
        mapping(uint256 => RewardDistributionClaimStatus.Data) claimStatus;
        /**
         * @dev Value to be distributed as rewards in a scheduled form.
         */
        int128 scheduledValueD18;
        /**
         * @dev Date at which the entry's rewards will begin to be claimable.
         *
         * Note: Set to <= block.timestamp to distribute immediately to currently participating users.
         */
        uint64 start;
        /**
         * @dev Time span after the start date, in which the whole of the entry's rewards will become claimable.
         */
        uint32 duration;
        /**
         * @dev Date on which this distribution entry was last updated.
         */
        uint32 lastUpdate;
    }

    /**
     * @dev Distributes rewards into a new rewards distribution entry.
     *
     * Note: this function allows for more special cases such as distributing at a future date or distributing over time.
     * If you want to apply the distribution to the pool, call `distribute` with the return value. Otherwise, you can
     * record this independently as well.
     */
    function distribute(
        Data storage self,
        Distribution.Data storage dist,
        int256 amountD18,
        uint64 start,
        uint32 duration
    ) internal returns (int256 diffD18) {
        uint256 totalSharesD18 = dist.totalSharesD18;

        if (totalSharesD18 == 0) {
            revert ParameterError.InvalidParameter(
                "amount",
                "can't distribute to empty distribution"
            );
        }

        uint256 curTime = block.timestamp;

        // Unlocks the entry's distributed amount into its value per share.
        diffD18 += updateEntry(self, totalSharesD18);

        // If the current time is past the end of the entry's duration,
        // update any rewards which may have accrued since last run.
        // (instant distribution--immediately disperse amount).
        if (start + duration <= curTime) {
            diffD18 += amountD18.divDecimal(totalSharesD18.toInt());

            self.lastUpdate = 0;
            self.start = 0;
            self.duration = 0;
            self.scheduledValueD18 = 0;
            // Else, schedule the amount to distribute.
        } else {
            self.scheduledValueD18 = amountD18.to128();

            self.start = start;
            self.duration = duration;

            // The amount is actually the amount distributed already *plus* whatever has been specified now.
            self.lastUpdate = 0;

            diffD18 += updateEntry(self, totalSharesD18);
        }
    }

    /**
     * @dev Gets the total shares of a reward distribution entry.
     */
    function getEntry(
        Data storage self,
        uint256 totalSharesAmountD18
    ) internal view returns (int256) {
        // No balance if a pool is empty or if it has no rewards
        if (self.scheduledValueD18 == 0 || totalSharesAmountD18 == 0) {
            return 0;
        }

        uint256 curTime = block.timestamp;

        int256 valuePerShareChangeD18 = 0;

        // No balance if current time is before start time
        if (curTime < self.start) {
            return 0;
        }

        // If the entry's duration is zero and its last update was before the start time,
        // consider the entry to be an instant distribution.
        if (self.duration == 0 && self.lastUpdate < self.start) {
            // Simply update the value per share to the total value divided by the total shares.
            valuePerShareChangeD18 = self.scheduledValueD18.to256().divDecimal(
                totalSharesAmountD18.toInt()
            );
            // Else, if the last update was before the end of the duration.
        } else if (self.lastUpdate < self.start + self.duration) {
            // Determine how much was previously distributed.
            // If the last update is zero, then nothing was distributed,
            // otherwise the amount is proportional to the time elapsed since the start.
            int256 lastUpdateDistributedD18 = self.lastUpdate < self.start
                ? SafeCastI128.zero()
                : (self.scheduledValueD18 * (self.lastUpdate - self.start).toInt()) /
                    self.duration.toInt();

            // If the current time is beyond the duration, then consider all scheduled value to be distributed.
            // Else, the amount distributed is proportional to the elapsed time.
            int256 curUpdateDistributedD18 = self.scheduledValueD18;
            if (curTime < self.start + self.duration) {
                // Note: Not using an intermediate time ratio variable
                // in the following calculation to maintain precision.
                curUpdateDistributedD18 =
                    (curUpdateDistributedD18 * (curTime - self.start).toInt()) /
                    self.duration.toInt();
            }

            // The final value per share change is the difference between what is to be distributed and what was distributed.
            valuePerShareChangeD18 = (curUpdateDistributedD18 - lastUpdateDistributedD18)
                .divDecimal(totalSharesAmountD18.toInt());
        }

        return valuePerShareChangeD18;
    }

    /**
     * @dev Updates the total shares of a reward distribution entry, and releases its unlocked value into its value per share, depending on the time elapsed since the start of the distribution's entry.
     *
     * Note: call every time before `totalShares` changes.
     */
    function updateEntry(
        Data storage self,
        uint256 totalSharesAmountD18
    ) internal returns (int256) {
        // Cannot process distributed rewards if a pool is empty or if it has no rewards.
        if (self.scheduledValueD18 == 0 || totalSharesAmountD18 == 0) {
            return 0;
        }

        uint256 curTime = block.timestamp;

        int256 valuePerShareChangeD18 = 0;

        // Cannot update an entry whose start date has not being reached.
        if (curTime < self.start) {
            return 0;
        }

        // If the entry's duration is zero and its last update was before the start time,
        // consider the entry to be an instant distribution.
        if (self.duration == 0 && self.lastUpdate < self.start) {
            // Simply update the value per share to the total value divided by the total shares.
            valuePerShareChangeD18 = self.scheduledValueD18.to256().divDecimal(
                totalSharesAmountD18.toInt()
            );
            // Else, if the last update was before the end of the duration.
        } else if (self.lastUpdate < self.start + self.duration) {
            // Determine how much was previously distributed.
            // If the last update is zero, then nothing was distributed,
            // otherwise the amount is proportional to the time elapsed since the start.
            int256 lastUpdateDistributedD18 = 0;

            if (self.lastUpdate >= self.start) {
                // solhint-disable numcast/safe-cast
                lastUpdateDistributedD18 =
                    (int256(self.scheduledValueD18) * (self.lastUpdate - self.start).toInt()) /
                    self.duration.toInt();
                // solhint-enable numcast/safe-cast
            }

            // If the current time is beyond the duration, then consider all scheduled value to be distributed.
            // Else, the amount distributed is proportional to the elapsed time.
            int256 curUpdateDistributedD18 = self.scheduledValueD18;
            if (curTime < self.start + self.duration) {
                // Note: Not using an intermediate time ratio variable
                // in the following calculation to maintain precision.
                curUpdateDistributedD18 =
                    (curUpdateDistributedD18 * (curTime - self.start).toInt()) /
                    self.duration.toInt();
            }

            // The final value per share change is the difference between what is to be distributed and what was distributed.
            valuePerShareChangeD18 = (curUpdateDistributedD18 - lastUpdateDistributedD18)
                .divDecimal(totalSharesAmountD18.toInt());
        }

        self.lastUpdate = curTime.to32();

        return valuePerShareChangeD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Tracks information per actor within a RewardDistribution.
 */
library RewardDistributionClaimStatus {
    struct Data {
        /**
         * @dev The last known reward per share for this actor.
         */
        uint128 lastRewardPerShareD18;
        /**
         * @dev The amount of rewards pending to be claimed by this actor.
         */
        uint128 pendingSendD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Data structure that wraps a mapping with a scalar multiplier.
 *
 * If you wanted to modify all the values in a mapping by the same amount, you would normally have to loop through each entry in the mapping. This object allows you to modify all of them at once, by simply modifying the scalar multiplier.
 *
 * I.e. a regular mapping represents values like this:
 * value = mapping[id]
 *
 * And a scalable mapping represents values like this:
 * value = mapping[id] * scalar
 *
 * This reduces the number of computations needed for modifying the balances of N users from O(n) to O(1).

 * Note: Notice how users are tracked by a generic bytes32 id instead of an address. This allows the actors of the mapping not just to be addresses. They can be anything, for example a pool id, an account id, etc.
 *
 * *********************
 * Conceptual Examples
 * *********************
 *
 * 1) Socialization of collateral during a liquidation.
 *
 * Scalable mappings are very useful for "socialization" of collateral, that is, the re-distribution of collateral when an account is liquidated. Suppose 1000 ETH are liquidated, and would need to be distributed amongst 1000 depositors. With a regular mapping, every depositor's balance would have to be modified in a loop that iterates through every single one of them. With a scalable mapping, the scalar would simply need to be incremented so that the total value of the mapping increases by 1000 ETH.
 *
 * 2) Socialization of debt during a liquidation.
 *
 * Similar to the socialization of collateral during a liquidation, the debt of the position that is being liquidated can be re-allocated using a scalable mapping with a single action. Supposing a scalable mapping tracks each user's debt in the system, and that 1000 sUSD has to be distributed amongst 1000 depositors, the debt data structure's scalar would simply need to be incremented so that the total value or debt of the distribution increments by 1000 sUSD.
 *
 */
library ScalableMapping {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using DecimalMath for int256;
    using DecimalMath for uint256;

    /**
     * @dev Thrown when attempting to scale a mapping with an amount that is lower than its resolution.
     */
    error InsufficientMappedAmount();

    /**
     * @dev Thrown when attempting to scale a mapping with no shares.
     */
    error CannotScaleEmptyMapping();

    struct Data {
        uint128 totalSharesD18;
        int128 scaleModifierD27;
        mapping(bytes32 => uint256) sharesD18;
    }

    /**
     * @dev Inflates or deflates the total value of the distribution by the given value.
     * @dev The incoming value is split per share, and used as a delta that is *added* to the existing scale modifier. The resulting scale modifier must be in the range [-1, type(int128).max).
     */
    function scale(Data storage self, int256 valueD18) internal {
        if (valueD18 == 0) {
            return;
        }

        uint256 totalSharesD18 = self.totalSharesD18;
        if (totalSharesD18 == 0) {
            revert CannotScaleEmptyMapping();
        }

        int256 valueD45 = valueD18 * DecimalMath.UNIT_PRECISE_INT;
        int256 deltaScaleModifierD27 = valueD45 / totalSharesD18.toInt();

        self.scaleModifierD27 += deltaScaleModifierD27.to128();

        if (self.scaleModifierD27 < -DecimalMath.UNIT_PRECISE_INT) {
            revert InsufficientMappedAmount();
        }
    }

    /**
     * @dev Updates an actor's individual value in the distribution to the specified amount.
     *
     * The change in value is manifested in the distribution by changing the actor's number of shares in it, and thus the distribution's total number of shares.
     *
     * Returns the resulting amount of shares that the actor has after this change in value.
     */
    function set(
        Data storage self,
        bytes32 actorId,
        uint256 newActorValueD18
    ) internal returns (uint256 resultingSharesD18) {
        // Represent the actor's change in value by changing the actor's number of shares,
        // and keeping the distribution's scaleModifier constant.

        resultingSharesD18 = getSharesForAmount(self, newActorValueD18);

        // Modify the total shares with the actor's change in shares.
        self.totalSharesD18 = (self.totalSharesD18 + resultingSharesD18 - self.sharesD18[actorId])
            .to128();

        self.sharesD18[actorId] = resultingSharesD18.to128();
    }

    /**
     * @dev Returns the value owned by the actor in the distribution.
     *
     * i.e. actor.shares * scaleModifier
     */
    function get(Data storage self, bytes32 actorId) internal view returns (uint256 valueD18) {
        uint256 totalSharesD18 = self.totalSharesD18;
        if (totalSharesD18 == 0) {
            return 0;
        }

        return (self.sharesD18[actorId] * totalAmount(self)) / totalSharesD18;
    }

    /**
     * @dev Returns the total value held in the distribution.
     *
     * i.e. totalShares * scaleModifier
     */
    function totalAmount(Data storage self) internal view returns (uint256 valueD18) {
        return
            ((self.scaleModifierD27 + DecimalMath.UNIT_PRECISE_INT).toUint() *
                self.totalSharesD18) / DecimalMath.UNIT_PRECISE;
    }

    function getSharesForAmount(
        Data storage self,
        uint256 amountD18
    ) internal view returns (uint256 sharesD18) {
        sharesD18 =
            (amountD18 * DecimalMath.UNIT_PRECISE) /
            (self.scaleModifierD27 + DecimalMath.UNIT_PRECISE_INT128).toUint();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

/**
 * @title System wide configuration for pools.
 */
library SystemPoolConfiguration {
    bytes32 private constant _SLOT_SYSTEM_POOL_CONFIGURATION =
        keccak256(abi.encode("io.synthetix.synthetix.SystemPoolConfiguration"));

    struct Data {
        /**
         * @dev Owner specified system-wide limiting factor that prevents markets from minting too much debt, similar to the issuance ratio to a collateral type.
         *
         * Note: If zero, then this value defaults to 100%.
         */
        uint256 minLiquidityRatioD18;
        uint128 __reservedForFutureUse;
        /**
         * @dev Id of the main pool set by the system owner.
         */
        uint128 preferredPool;
        /**
         * @dev List of pools approved by the system owner.
         */
        SetUtil.UintSet approvedPools;
    }

    /**
     * @dev Returns the configuration singleton.
     */
    function load() internal pure returns (Data storage systemPoolConfiguration) {
        bytes32 s = _SLOT_SYSTEM_POOL_CONFIGURATION;
        assembly {
            systemPoolConfiguration.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./VaultEpoch.sol";
import "./RewardDistribution.sol";

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Tracks collateral and debt distributions in a pool, for a specific collateral type.
 *
 * I.e. if a pool supports SNX and ETH collaterals, it will have an SNX Vault, and an ETH Vault.
 *
 * The Vault data structure is itself split into VaultEpoch sub-structures. This facilitates liquidations,
 * so that whenever one occurs, a clean state of all data is achieved by simply incrementing the epoch index.
 *
 * It is recommended to understand VaultEpoch before understanding this object.
 */
library Vault {
    using VaultEpoch for VaultEpoch.Data;
    using Distribution for Distribution.Data;
    using RewardDistribution for RewardDistribution.Data;
    using ScalableMapping for ScalableMapping.Data;
    using DecimalMath for uint256;
    using DecimalMath for int128;
    using DecimalMath for int256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using SetUtil for SetUtil.Bytes32Set;

    /**
     * @dev Thrown when a non-existent reward distributor is referenced
     */
    error RewardDistributorNotFound();

    struct Data {
        /**
         * @dev The vault's current epoch number.
         *
         * Vault data is divided into epochs. An epoch changes when an entire vault is liquidated.
         */
        uint256 epoch;
        /**
         * @dev Unused property, maintained for backwards compatibility in storage layout.
         */
        // solhint-disable-next-line private-vars-leading-underscore
        bytes32 __slotAvailableForFutureUse;
        /**
         * @dev The previous debt of the vault, when `updateCreditCapacity` was last called by the Pool.
         */
        // solhint-disable-next-line var-name-mixedcase
        int128 _unused_prevTotalDebtD18;
        /**
         * @dev Vault data for all the liquidation cycles divided into epochs.
         */
        mapping(uint256 => VaultEpoch.Data) epochData;
        /**
         * @dev Tracks available rewards, per user, for this vault.
         */
        mapping(bytes32 => RewardDistribution.Data) rewards;
        /**
         * @dev Tracks reward ids, for this vault.
         */
        SetUtil.Bytes32Set rewardIds;
    }

    struct PositionSelector {
        uint128 accountId;
        uint128 poolId;
        address collateralType;
    }

    /**
     * @dev Return's the VaultEpoch data for the current epoch.
     */
    function currentEpoch(Data storage self) internal view returns (VaultEpoch.Data storage) {
        return self.epochData[self.epoch];
    }

    /**
     * @dev Updates the vault's credit capacity as the value of its collateral minus its debt.
     *
     * Called as a ticker when users interact with pools, allowing pools to set
     * vaults' credit capacity shares within them.
     *
     * Returns the amount of collateral that this vault is providing in net USD terms.
     */
    function updateCreditCapacity(
        Data storage self,
        uint256 collateralPriceD18
    ) internal view returns (uint256 usdWeightD18, int256 totalDebtD18) {
        VaultEpoch.Data storage epochData = currentEpoch(self);

        usdWeightD18 = (epochData.collateralAmounts.totalAmount()).mulDecimal(collateralPriceD18);

        totalDebtD18 = epochData.totalDebt();

        //self.prevTotalDebtD18 = totalDebtD18.to128();
    }

    /**
     * @dev Updated the value per share of the current epoch's incoming debt distribution.
     */
    function distributeDebtToAccounts(Data storage self, int256 debtChangeD18) internal {
        currentEpoch(self).distributeDebtToAccounts(debtChangeD18);
    }

    /**
     * @dev Consolidates an accounts debt.
     */
    function consolidateAccountDebt(
        Data storage self,
        uint128 accountId
    ) internal returns (int256) {
        return currentEpoch(self).consolidateAccountDebt(accountId);
    }

    function updateRewards(
        Data storage self,
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) internal returns (uint256[] memory rewards, address[] memory distributors) {
        uint256 totalSharesD18 = currentEpoch(self).accountsDebtDistribution.totalSharesD18;
        uint256 actorSharesD18 = currentEpoch(self).accountsDebtDistribution.getActorShares(
            accountId.toBytes32()
        );

        return
            updateRewards(
                self,
                PositionSelector(accountId, poolId, collateralType),
                totalSharesD18,
                actorSharesD18
            );
    }

    /**
     * @dev Traverses available rewards for this vault, and updates an accounts
     * claim on them according to the amount of debt shares they have.
     */
    function updateRewards(
        Data storage self,
        PositionSelector memory pos,
        uint256 totalSharesD18,
        uint256 actorSharesD18
    ) internal returns (uint256[] memory rewards, address[] memory distributors) {
        rewards = new uint256[](self.rewardIds.length());
        distributors = new address[](self.rewardIds.length());

        uint256 numRewards = self.rewardIds.length();
        for (uint256 i = 0; i < numRewards; i++) {
            RewardDistribution.Data storage dist = self.rewards[self.rewardIds.valueAt(i + 1)];

            if (address(dist.distributor) == address(0)) {
                continue;
            }

            distributors[i] = address(dist.distributor);
            rewards[i] = updateReward(
                self,
                pos,
                self.rewardIds.valueAt(i + 1),
                totalSharesD18,
                actorSharesD18
            );
        }
    }

    /**
     * @dev Traverses available rewards for this vault and the reward id, and returns an accounts
     * pending claim on them according to the amount of debt shares they have.
     */
    function getReward(
        Data storage self,
        uint128 accountId,
        bytes32 rewardId
    ) internal view returns (uint256) {
        uint256 totalSharesD18 = currentEpoch(self).accountsDebtDistribution.totalSharesD18;
        uint256 actorSharesD18 = currentEpoch(self).accountsDebtDistribution.getActorShares(
            accountId.toBytes32()
        );

        RewardDistribution.Data storage dist = self.rewards[rewardId];

        if (address(dist.distributor) == address(0)) {
            revert RewardDistributorNotFound();
        }

        uint256 currentRewardPerShare = dist.rewardPerShareD18;

        currentRewardPerShare += dist.getEntry(totalSharesD18).toUint().to128();

        uint256 currentPending = dist.claimStatus[accountId].pendingSendD18 +
            actorSharesD18.mulDecimal(
                currentRewardPerShare - dist.claimStatus[accountId].lastRewardPerShareD18
            );

        return currentPending;
    }

    /**
     * @dev Traverses available rewards for this vault and the reward id, and updates an accounts
     * claim on them according to the amount of debt shares they have.
     */
    function updateReward(
        Data storage self,
        PositionSelector memory pos,
        bytes32 rewardId,
        uint256 totalSharesD18,
        uint256 actorSharesD18
    ) internal returns (uint256) {
        RewardDistribution.Data storage dist = self.rewards[rewardId];

        if (address(dist.distributor) == address(0)) {
            revert RewardDistributorNotFound();
        }

        dist.distributor.onPositionUpdated(
            pos.accountId,
            pos.poolId,
            pos.collateralType,
            actorSharesD18
        );

        dist.rewardPerShareD18 += dist.updateEntry(totalSharesD18).toUint().to128();

        dist.claimStatus[pos.accountId].pendingSendD18 += actorSharesD18
            .mulDecimal(
                dist.rewardPerShareD18 - dist.claimStatus[pos.accountId].lastRewardPerShareD18
            )
            .to128();

        dist.claimStatus[pos.accountId].lastRewardPerShareD18 = dist.rewardPerShareD18;

        return dist.claimStatus[pos.accountId].pendingSendD18;
    }

    /**
     * @dev Increments the current epoch index, effectively producing a
     * completely blank new VaultEpoch data structure in the vault.
     */
    function reset(Data storage self) internal {
        self.epoch++;
    }

    /**
     * @dev Returns the vault's combined debt (consolidated and unconsolidated),
     * for the current epoch.
     */
    function currentDebt(Data storage self) internal view returns (int256) {
        return currentEpoch(self).totalDebt();
    }

    /**
     * @dev Returns the total value in the Vault's collateral distribution, for the current epoch.
     */
    function currentCollateral(Data storage self) internal view returns (uint256) {
        return currentEpoch(self).collateralAmounts.totalAmount();
    }

    /**
     * @dev Returns an account's collateral value in this vault's current epoch.
     */
    function currentAccountCollateral(
        Data storage self,
        uint128 accountId
    ) internal view returns (uint256) {
        return currentEpoch(self).getAccountCollateral(accountId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./Distribution.sol";
import "./ScalableMapping.sol";

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Tracks collateral and debt distributions in a pool, for a specific collateral type, in a given epoch.
 *
 * Collateral is tracked with a distribution as opposed to a regular mapping because liquidations cause collateral to be socialized. If collateral was tracked using a regular mapping, such socialization would be difficult and require looping through individual balances, or some other sort of complex and expensive mechanism. Distributions make socialization easy.
 *
 * Debt is also tracked in a distribution for the same reason, but it is additionally split in two distributions: incoming and consolidated debt.
 *
 * Incoming debt is modified when a liquidations occurs.
 * Consolidated debt is updated when users interact with the system.
 */
library VaultEpoch {
    using Distribution for Distribution.Data;
    using DecimalMath for uint256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using ScalableMapping for ScalableMapping.Data;

    struct Data {
        /**
         * @dev Amount of debt in this Vault that is yet to be consolidated.
         *
         * E.g. when a given amount of debt is socialized during a liquidation, but it yet hasn't been rolled into
         * the consolidated debt distribution.
         */
        int128 unconsolidatedDebtD18;
        /**
         * @dev Amount of debt in this Vault that has been consolidated.
         */
        int128 totalConsolidatedDebtD18;
        /**
         * @dev Tracks incoming debt for each user.
         *
         * The value of shares in this distribution change as the associate market changes, i.e. price changes in an asset in
         * a spot market.
         *
         * Also, when debt is socialized in a liquidation, it is done onto this distribution. As users
         * interact with the system, their independent debt is consolidated or rolled into consolidatedDebtDist.
         */
        Distribution.Data accountsDebtDistribution;
        /**
         * @dev Tracks collateral delegated to this vault, for each user.
         *
         * Uses a distribution instead of a regular market because of the way collateral is socialized during liquidations.
         *
         * A regular mapping would require looping over the mapping of each account's collateral, or moving the liquidated
         * collateral into a place where it could later be claimed. With a distribution, liquidated collateral can be
         * socialized very easily.
         */
        ScalableMapping.Data collateralAmounts;
        /**
         * @dev Tracks consolidated debt for each user.
         *
         * Updated when users interact with the system, consolidating changes from the fluctuating accountsDebtDistribution,
         * and directly when users mint or burn USD, or repay debt.
         */
        mapping(uint256 => int256) consolidatedDebtAmountsD18;
        /**
         * @dev Tracks last time a user delegated to this vault.
         *
         * Needed to validate min delegation time compliance to prevent small scale debt pool frontrunning
         */
        mapping(uint128 => uint64) lastDelegationTime;
    }

    /**
     * @dev Updates the value per share of the incoming debt distribution.
     * Used for socialization during liquidations, and to bake in market changes.
     *
     * Called from:
     * - LiquidationModule.liquidate
     * - Pool.recalculateVaultCollateral (ticker)
     */
    function distributeDebtToAccounts(Data storage self, int256 debtChangeD18) internal {
        self.accountsDebtDistribution.distributeValue(debtChangeD18);

        // Cache total debt here.
        // Will roll over to individual users as they interact with the system.
        self.unconsolidatedDebtD18 += debtChangeD18.to128();
    }

    /**
     * @dev Adjusts the debt associated with `accountId` by `amountD18`.
     * Used to add or remove debt from/to a specific account, instead of all accounts at once (use distributeDebtToAccounts for that)
     */
    function assignDebtToAccount(
        Data storage self,
        uint128 accountId,
        int256 amountD18
    ) internal returns (int256 newDebtD18) {
        int256 currentDebtD18 = self.consolidatedDebtAmountsD18[accountId];
        self.consolidatedDebtAmountsD18[accountId] += amountD18;
        self.totalConsolidatedDebtD18 += amountD18.to128();
        return currentDebtD18 + amountD18;
    }

    /**
     * @dev Consolidates user debt as they interact with the system.
     *
     * Fluctuating debt is moved from incoming to consolidated debt.
     *
     * Called as a ticker from various parts of the system, usually whenever the
     * real debt of a user needs to be known.
     */
    function consolidateAccountDebt(
        Data storage self,
        uint128 accountId
    ) internal returns (int256 currentDebtD18) {
        int256 newDebtD18 = self.accountsDebtDistribution.accumulateActor(accountId.toBytes32());

        currentDebtD18 = assignDebtToAccount(self, accountId, newDebtD18);
        self.unconsolidatedDebtD18 -= newDebtD18.to128();
    }

    /**
     * @dev Updates a user's collateral value, and sets their exposure to debt
     * according to the collateral they delegated and the leverage used.
     *
     * Called whenever a user's collateral changes.
     */
    function updateAccountPosition(
        Data storage self,
        uint128 accountId,
        uint256 collateralAmountD18,
        uint256 leverageD18
    ) internal {
        bytes32 actorId = accountId.toBytes32();

        // Ensure account debt is consolidated before we do next things.
        consolidateAccountDebt(self, accountId);

        self.collateralAmounts.set(actorId, collateralAmountD18);
        self.accountsDebtDistribution.setActorShares(
            actorId,
            self.collateralAmounts.sharesD18[actorId].mulDecimal(leverageD18)
        );
    }

    /**
     * @dev Returns the vault's total debt in this epoch, including the debt
     * that hasn't yet been consolidated into individual accounts.
     */
    function totalDebt(Data storage self) internal view returns (int256) {
        return self.unconsolidatedDebtD18 + self.totalConsolidatedDebtD18;
    }

    /**
     * @dev Returns an account's value in the Vault's collateral distribution.
     */
    function getAccountCollateral(
        Data storage self,
        uint128 accountId
    ) internal view returns (uint256 amountD18) {
        return self.collateralAmounts.get(accountId.toBytes32());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/// @title Interface an aggregator needs to adhere.
interface IAggregatorV3Interface {
    /// @notice decimals used by the aggregator
    function decimals() external view returns (uint8);

    /// @notice aggregator's description
    function description() external view returns (string memory);

    /// @notice aggregator's version
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    /// @notice get's round data for requested id
    function getRoundData(
        uint80 id
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    /// @notice get's latest round data
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

import "../../storage/NodeOutput.sol";
import "../../storage/NodeDefinition.sol";

/// @title Interface for an external node
interface IExternalNode is IERC165 {
    function process(
        NodeOutput.Data[] memory parentNodeOutputs,
        bytes memory parameters,
        bytes32[] memory runtimeKeys,
        bytes32[] memory runtimeValues
    ) external view returns (NodeOutput.Data memory);

    function isValid(NodeDefinition.Data memory nodeDefinition) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.11 <0.9.0;

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth {
    /// @dev Emitted when an update for price feed with `id` is processed successfully.
    /// @param id The Pyth Price Feed ID.
    /// @param fresh True if the price update is more recent and stored.
    /// @param chainId ID of the source chain that the batch price update containing this price.
    /// This value comes from Wormhole, and you can find the corresponding chains at https://docs.wormholenetwork.com/wormhole/contracts.
    /// @param sequenceNumber Sequence number of the batch price update containing this price.
    /// @param lastPublishTime Publish time of the previously stored price.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        bool indexed fresh,
        uint16 chainId,
        uint64 sequenceNumber,
        uint256 lastPublishTime,
        uint256 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    /// @param batchSize Number of prices within the batch price update.
    /// @param freshPricesInBatch Number of prices that were more recent and were stored.
    event BatchPriceFeedUpdate(
        uint16 chainId,
        uint64 sequenceNumber,
        uint256 batchSize,
        uint256 freshPricesInBatch
    );

    /// @dev Emitted when a call to `updatePriceFeeds` is processed successfully.
    /// @param sender Sender of the call (`msg.sender`).
    /// @param batchCount Number of batches that this function processed.
    /// @param fee Amount of paid fee for updating the prices.
    event UpdatePriceFeeds(address indexed sender, uint256 batchCount, uint256 fee);

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
    function getPriceNoOlderThan(
        bytes32 id,
        uint256 age
    ) external view returns (PythStructs.Price memory price);

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
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint256 age
    ) external view returns (PythStructs.Price memory price);

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

    /// @notice Similar to `parsePriceFeedUpdates` but ensures the updates returned are
    /// the first updates published in minPublishTime. That is, if there are multiple updates for a given timestamp,
    /// this method will return the first update.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range and uniqueness condition.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdatesUnique(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.11 <0.9.0;

interface IUniswapV3Pool {
    function observe(
        uint32[] calldata secondsAgos
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/NodeOutput.sol";
import "../storage/NodeDefinition.sol";

/// @title Module for managing nodes
interface INodeModule {
    /**
     * @notice Thrown when the specified nodeId has not been registered in the system.
     */
    error NodeNotRegistered(bytes32 nodeId);

    /**
     * @notice Thrown when a node is registered without a valid definition.
     */
    error InvalidNodeDefinition(NodeDefinition.Data nodeType);

    /**
     * @notice Emitted when `registerNode` is called.
     * @param nodeId The id of the registered node.
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @param parents The parents assigned to this node.
     */
    event NodeRegistered(
        bytes32 nodeId,
        NodeDefinition.NodeType nodeType,
        bytes parameters,
        bytes32[] parents
    );

    /**
     * @notice Registers a node
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @param parents The parents assigned to this node.
     * @return nodeId The id of the registered node.
     */
    function registerNode(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32 nodeId);

    /**
     * @notice Returns the ID of a node, whether or not it has been registered.
     * @param parents The parents assigned to this node.
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @return nodeId The id of the node.
     */
    function getNodeId(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external pure returns (bytes32 nodeId);

    /**
     * @notice Returns a node's definition (type, parameters, and parents)
     * @param nodeId The node ID
     * @return node The node's definition data
     */
    function getNode(bytes32 nodeId) external pure returns (NodeDefinition.Data memory node);

    /**
     * @notice Returns a node current output data
     * @param nodeId The node ID
     * @return node The node's output data
     */
    function process(bytes32 nodeId) external view returns (NodeOutput.Data memory node);

    /**
     * @notice Returns a node current output data
     * @param nodeId The node ID
     * @param runtimeKeys Keys corresponding to runtime values which could be used by the node graph
     * @param runtimeValues The values used by the node graph
     * @return node The node's output data
     */
    function processWithRuntime(
        bytes32 nodeId,
        bytes32[] memory runtimeKeys,
        bytes32[] memory runtimeValues
    ) external view returns (NodeOutput.Data memory node);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";
import "../interfaces/external/IAggregatorV3Interface.sol";

library ChainlinkNode {
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;
    using DecimalMath for int256;

    uint256 public constant PRECISION = 18;

    function process(
        bytes memory parameters
    ) internal view returns (NodeOutput.Data memory nodeOutput) {
        (address chainlinkAddr, uint256 twapTimeInterval, uint8 decimals) = abi.decode(
            parameters,
            (address, uint256, uint8)
        );
        IAggregatorV3Interface chainlink = IAggregatorV3Interface(chainlinkAddr);
        (uint80 roundId, int256 price, , uint256 updatedAt, ) = chainlink.latestRoundData();

        int256 finalPrice = twapTimeInterval == 0
            ? price
            : getTwapPrice(chainlink, roundId, price, twapTimeInterval);

        finalPrice = decimals > PRECISION
            ? finalPrice.downscale(decimals - PRECISION)
            : finalPrice.upscale(PRECISION - decimals);

        return NodeOutput.Data(finalPrice, updatedAt, 0, 0);
    }

    function getTwapPrice(
        IAggregatorV3Interface chainlink,
        uint80 latestRoundId,
        int256 latestPrice,
        uint256 twapTimeInterval
    ) internal view returns (int256 price) {
        int256 priceSum = latestPrice;
        uint256 priceCount = 1;

        uint256 startTime = block.timestamp - twapTimeInterval;

        while (latestRoundId > 0) {
            try chainlink.getRoundData(--latestRoundId) returns (
                uint80,
                int256 answer,
                uint256,
                uint256 updatedAt,
                uint80
            ) {
                if (updatedAt < startTime) {
                    break;
                }
                priceSum += answer;
                priceCount++;
            } catch {
                break;
            }
        }

        return priceSum / priceCount.toInt();
    }

    function isValid(NodeDefinition.Data memory nodeDefinition) internal view returns (bool valid) {
        // Must have no parents
        if (nodeDefinition.parents.length > 0) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 32 * 3) {
            return false;
        }

        (address chainlinkAddr, , uint8 decimals) = abi.decode(
            nodeDefinition.parameters,
            (address, uint256, uint8)
        );
        IAggregatorV3Interface chainlink = IAggregatorV3Interface(chainlinkAddr);

        // Must return latestRoundData without error
        chainlink.latestRoundData();

        // Must return decimals that match the definition
        if (decimals != chainlink.decimals()) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";

library ConstantNode {
    function process(
        bytes memory parameters
    ) internal view returns (NodeOutput.Data memory nodeOutput) {
        return NodeOutput.Data(abi.decode(parameters, (int256)), block.timestamp, 0, 0);
    }

    function isValid(NodeDefinition.Data memory nodeDefinition) internal pure returns (bool valid) {
        // Must have no parents
        if (nodeDefinition.parents.length > 0) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length < 32) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/ERC165Helper.sol";

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";
import "../interfaces/external/IExternalNode.sol";

library ExternalNode {
    function process(
        NodeOutput.Data[] memory prices,
        bytes memory parameters,
        bytes32[] memory runtimeKeys,
        bytes32[] memory runtimeValues
    ) internal view returns (NodeOutput.Data memory nodeOutput) {
        IExternalNode externalNode = IExternalNode(abi.decode(parameters, (address)));
        return externalNode.process(prices, parameters, runtimeKeys, runtimeValues);
    }

    function isValid(NodeDefinition.Data memory nodeDefinition) internal returns (bool valid) {
        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length < 32) {
            return false;
        }

        address externalNode = abi.decode(nodeDefinition.parameters, (address));
        if (!ERC165Helper.safeSupportsInterface(externalNode, type(IExternalNode).interfaceId)) {
            return false;
        }

        if (!IExternalNode(externalNode).isValid(nodeDefinition)) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";

library PriceDeviationCircuitBreakerNode {
    using SafeCastU256 for uint256;
    using DecimalMath for int256;

    error DeviationToleranceExceeded(int256 deviation);
    error InvalidInputPrice();

    function process(
        NodeOutput.Data[] memory parentNodeOutputs,
        bytes memory parameters
    ) internal pure returns (NodeOutput.Data memory nodeOutput) {
        uint256 deviationTolerance = abi.decode(parameters, (uint256));

        int256 primaryPrice = parentNodeOutputs[0].price;
        int256 comparisonPrice = parentNodeOutputs[1].price;

        if (primaryPrice != comparisonPrice) {
            int256 difference = abs(primaryPrice - comparisonPrice).upscale(18);
            if (
                primaryPrice == 0 || deviationTolerance.toInt() < (difference / abs(primaryPrice))
            ) {
                if (parentNodeOutputs.length > 2) {
                    return parentNodeOutputs[2];
                } else {
                    if (primaryPrice == 0) {
                        revert InvalidInputPrice();
                    } else {
                        revert DeviationToleranceExceeded(difference / abs(primaryPrice));
                    }
                }
            }
        }

        return parentNodeOutputs[0];
    }

    function abs(int256 x) private pure returns (int256 result) {
        return x >= 0 ? x : -x;
    }

    function isValid(NodeDefinition.Data memory nodeDefinition) internal pure returns (bool valid) {
        // Must have 2-3 parents
        if (!(nodeDefinition.parents.length == 2 || nodeDefinition.parents.length == 3)) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 32) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "../../storage/NodeDefinition.sol";
import "../../storage/NodeOutput.sol";
import "../../interfaces/external/IPyth.sol";

library PythNode {
    using DecimalMath for int64;
    using SafeCastI256 for int256;

    int256 public constant PRECISION = 18;

    function process(
        bytes memory parameters
    ) internal view returns (NodeOutput.Data memory nodeOutput) {
        (address pythAddress, bytes32 priceFeedId, bool useEma) = abi.decode(
            parameters,
            (address, bytes32, bool)
        );
        IPyth pyth = IPyth(pythAddress);
        PythStructs.Price memory pythData = useEma
            ? pyth.getEmaPriceUnsafe(priceFeedId)
            : pyth.getPriceUnsafe(priceFeedId);

        int256 factor = PRECISION + pythData.expo;
        int256 price = factor > 0
            ? pythData.price.upscale(factor.toUint())
            : pythData.price.downscale((-factor).toUint());

        return NodeOutput.Data(price, pythData.publishTime, 0, 0);
    }

    function isValid(NodeDefinition.Data memory nodeDefinition) internal view returns (bool valid) {
        // Must have no parents
        if (nodeDefinition.parents.length > 0) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 32 * 3) {
            return false;
        }

        (address pythAddress, bytes32 priceFeedId, bool useEma) = abi.decode(
            nodeDefinition.parameters,
            (address, bytes32, bool)
        );
        IPyth pyth = IPyth(pythAddress);

        // Must return relevant function without error
        useEma ? pyth.getEmaPriceUnsafe(priceFeedId) : pyth.getPriceUnsafe(priceFeedId);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "../../storage/NodeDefinition.sol";
import "../../storage/NodeOutput.sol";

library PythOffchainLookupNode {
    using DecimalMath for int64;
    using SafeCastI256 for int256;

    error OracleDataRequired(address oracleContract, bytes oracleQuery);

    int256 public constant PRECISION = 18;

    function process(
        bytes memory parameters,
        bytes32[] memory runtimeKeys,
        bytes32[] memory runtimeValues
    ) internal pure returns (NodeOutput.Data memory) {
        (address pythAddress, bytes32 priceId, uint256 stalenessTolerance) = abi.decode(
            parameters,
            (address, bytes32, uint256)
        );

        for (uint256 i = 0; i < runtimeKeys.length; i++) {
            if (runtimeKeys[i] == "stalenessTolerance") {
                // solhint-disable-next-line numcast/safe-cast
                stalenessTolerance = uint256(runtimeValues[i]);
            }
        }

        bytes32[] memory priceIds = new bytes32[](1);
        priceIds[0] = priceId;

        // In the future Pyth revert data will have the following
        // Query schema:
        //
        // Enum PythQuery {
        //  Latest = 0 {
        //    bytes32[] priceIds,
        //  },
        //  NoOlderThan = 1 {
        //    uint64 stalenessTolerance,
        //    bytes32[] priceIds,
        //  },
        //  Benchmark = 2 {
        //    uint64 publishTime,
        //    bytes32[] priceIds,
        //  }
        // }
        //
        // This contract only implements the PythQuery::NoOlderThan
        revert OracleDataRequired(
            pythAddress,
            abi.encode(
                // solhint-disable-next-line numcast/safe-cast
                uint8(1), // PythQuery::NoOlderThan tag
                // solhint-disable-next-line numcast/safe-cast
                uint64(stalenessTolerance),
                priceIds
            )
        );
    }

    function isValid(NodeDefinition.Data memory nodeDefinition) internal pure returns (bool valid) {
        // Must have no parents
        if (nodeDefinition.parents.length > 0) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 32 * 3) {
            return false;
        }

        abi.decode(nodeDefinition.parameters, (address, bytes32, uint256));

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";

library ReducerNode {
    using SafeCastI256 for int256;
    using SafeCastU256 for uint256;
    using DecimalMath for int256;

    error UnsupportedOperation(Operations operation);
    error InvalidPrice(int256 price);

    enum Operations {
        RECENT,
        MIN,
        MAX,
        MEAN,
        MEDIAN,
        MUL,
        DIV,
        MULDECIMAL,
        DIVDECIMAL
    }

    function process(
        NodeOutput.Data[] memory parentNodeOutputs,
        bytes memory parameters
    ) internal pure returns (NodeOutput.Data memory nodeOutput) {
        Operations operation = abi.decode(parameters, (Operations));

        if (operation == Operations.RECENT) {
            return recent(parentNodeOutputs);
        }
        if (operation == Operations.MIN) {
            return min(parentNodeOutputs);
        }
        if (operation == Operations.MAX) {
            return max(parentNodeOutputs);
        }
        if (operation == Operations.MEAN) {
            return mean(parentNodeOutputs);
        }
        if (operation == Operations.MEDIAN) {
            return median(parentNodeOutputs);
        }
        if (operation == Operations.MUL) {
            return mul(parentNodeOutputs);
        }
        if (operation == Operations.DIV) {
            return div(parentNodeOutputs);
        }
        if (operation == Operations.MULDECIMAL) {
            return mulDecimal(parentNodeOutputs);
        }
        if (operation == Operations.DIVDECIMAL) {
            return divDecimal(parentNodeOutputs);
        }

        revert UnsupportedOperation(operation);
    }

    function median(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory medianPrice) {
        quickSort(parentNodeOutputs, SafeCastI256.zero(), (parentNodeOutputs.length - 1).toInt());
        if (parentNodeOutputs.length % 2 == 0) {
            NodeOutput.Data[] memory middleSet = new NodeOutput.Data[](2);
            middleSet[0] = parentNodeOutputs[(parentNodeOutputs.length / 2) - 1];
            middleSet[1] = parentNodeOutputs[(parentNodeOutputs.length / 2)];
            return mean(middleSet);
        } else {
            return parentNodeOutputs[parentNodeOutputs.length / 2];
        }
    }

    function mean(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory meanPrice) {
        for (uint256 i = 0; i < parentNodeOutputs.length; i++) {
            meanPrice.price += parentNodeOutputs[i].price;
            meanPrice.timestamp += parentNodeOutputs[i].timestamp;
        }

        meanPrice.price = meanPrice.price / parentNodeOutputs.length.toInt();
        meanPrice.timestamp = meanPrice.timestamp / parentNodeOutputs.length;
    }

    function recent(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory recentPrice) {
        for (uint256 i = 0; i < parentNodeOutputs.length; i++) {
            if (parentNodeOutputs[i].timestamp > recentPrice.timestamp) {
                recentPrice = parentNodeOutputs[i];
            }
        }
    }

    function max(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory maxPrice) {
        maxPrice = parentNodeOutputs[0];
        for (uint256 i = 1; i < parentNodeOutputs.length; i++) {
            if (parentNodeOutputs[i].price > maxPrice.price) {
                maxPrice = parentNodeOutputs[i];
            }
        }
    }

    function min(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory minPrice) {
        minPrice = parentNodeOutputs[0];
        for (uint256 i = 1; i < parentNodeOutputs.length; i++) {
            if (parentNodeOutputs[i].price < minPrice.price) {
                minPrice = parentNodeOutputs[i];
            }
        }
    }

    function mul(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory mulPrice) {
        mulPrice.price = parentNodeOutputs[0].price;
        mulPrice.timestamp = parentNodeOutputs[0].timestamp;
        for (uint256 i = 1; i < parentNodeOutputs.length; i++) {
            mulPrice.price *= parentNodeOutputs[i].price;
            mulPrice.timestamp += parentNodeOutputs[i].timestamp;
        }
        mulPrice.timestamp = mulPrice.timestamp / parentNodeOutputs.length;
    }

    function div(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory divPrice) {
        divPrice.price = parentNodeOutputs[0].price;
        divPrice.timestamp = parentNodeOutputs[0].timestamp;
        for (uint256 i = 1; i < parentNodeOutputs.length; i++) {
            if (parentNodeOutputs[i].price == 0) {
                revert InvalidPrice(parentNodeOutputs[i].price);
            }
            divPrice.price /= parentNodeOutputs[i].price;
            divPrice.timestamp += parentNodeOutputs[i].timestamp;
        }
        divPrice.timestamp = divPrice.timestamp / parentNodeOutputs.length;
    }

    function mulDecimal(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory mulPrice) {
        mulPrice.price = parentNodeOutputs[0].price;
        mulPrice.timestamp = parentNodeOutputs[0].timestamp;
        for (uint256 i = 1; i < parentNodeOutputs.length; i++) {
            mulPrice.price = mulPrice.price.mulDecimal(parentNodeOutputs[i].price);
            mulPrice.timestamp += parentNodeOutputs[i].timestamp;
        }
        mulPrice.timestamp = mulPrice.timestamp / parentNodeOutputs.length;
    }

    function divDecimal(
        NodeOutput.Data[] memory parentNodeOutputs
    ) internal pure returns (NodeOutput.Data memory divPrice) {
        divPrice.price = parentNodeOutputs[0].price;
        divPrice.timestamp = parentNodeOutputs[0].timestamp;
        for (uint256 i = 1; i < parentNodeOutputs.length; i++) {
            if (parentNodeOutputs[i].price == 0) {
                revert InvalidPrice(parentNodeOutputs[i].price);
            }
            divPrice.price = divPrice.price.divDecimal(parentNodeOutputs[i].price);
            divPrice.timestamp += parentNodeOutputs[i].timestamp;
        }
        divPrice.timestamp = divPrice.timestamp / parentNodeOutputs.length;
    }

    function quickSort(NodeOutput.Data[] memory arr, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        int256 pivot = arr[(left + (right - left) / 2).toUint()].price;
        while (i <= j) {
            while (arr[i.toUint()].price < pivot) i++;
            while (pivot < arr[j.toUint()].price) j--;
            if (i <= j) {
                (arr[i.toUint()], arr[j.toUint()]) = (arr[j.toUint()], arr[i.toUint()]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    function isValid(NodeDefinition.Data memory nodeDefinition) internal pure returns (bool valid) {
        // Must have at least 2 parents
        if (nodeDefinition.parents.length < 2) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 32) {
            return false;
        }

        // Must have valid operation
        uint256 operationId = abi.decode(nodeDefinition.parameters, (uint256));
        if (operationId > 8) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {SafeCastBytes32} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {NodeDefinition} from "../storage/NodeDefinition.sol";
import {NodeOutput} from "../storage/NodeOutput.sol";

library StalenessCircuitBreakerNode {
    using SafeCastBytes32 for bytes32;

    error StalenessToleranceExceeded();

    function process(
        NodeDefinition.Data memory nodeDefinition,
        bytes32[] memory runtimeKeys,
        bytes32[] memory runtimeValues
    ) internal view returns (NodeOutput.Data memory nodeOutput) {
        uint256 stalenessTolerance = abi.decode(nodeDefinition.parameters, (uint256));

        for (uint256 i = 0; i < runtimeKeys.length; i++) {
            if (runtimeKeys[i] == "stalenessTolerance") {
                stalenessTolerance = runtimeValues[i].toUint();
                break;
            }
        }

        bytes32 priceNodeId = nodeDefinition.parents[0];
        NodeOutput.Data memory priceNodeOutput = NodeDefinition.process(
            priceNodeId,
            runtimeKeys,
            runtimeValues
        );

        if (block.timestamp - priceNodeOutput.timestamp <= stalenessTolerance) {
            return priceNodeOutput;
        } else if (nodeDefinition.parents.length == 1) {
            revert StalenessToleranceExceeded();
        }
        // If there are two parents, return the output of the second parent (which in this case, should revert with OracleDataRequired)
        return NodeDefinition.process(nodeDefinition.parents[1], runtimeKeys, runtimeValues);
    }

    function isValid(NodeDefinition.Data memory nodeDefinition) internal pure returns (bool valid) {
        // Must have 1-2 parents
        if (!(nodeDefinition.parents.length == 1 || nodeDefinition.parents.length == 2)) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 32) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

import "../utils/FullMath.sol";
import "../utils/TickMath.sol";

import "../storage/NodeDefinition.sol";
import "../storage/NodeOutput.sol";
import "../interfaces/external/IUniswapV3Pool.sol";

library UniswapNode {
    using SafeCastU256 for uint256;
    using SafeCastU160 for uint160;
    using SafeCastU56 for uint56;
    using SafeCastU32 for uint32;
    using SafeCastI56 for int56;
    using SafeCastI256 for int256;

    using DecimalMath for int256;

    uint8 public constant PRECISION = 18;

    function process(
        bytes memory parameters
    ) internal view returns (NodeOutput.Data memory nodeOutput) {
        (
            address token,
            address stablecoin,
            uint8 decimalsToken,
            uint8 decimalsStablecoin,
            address pool,
            uint32 secondsAgo
        ) = abi.decode(parameters, (address, address, uint8, uint8, address, uint32));

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        int24 tick = (tickCumulativesDelta / secondsAgo.to56().toInt()).to24();

        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo.to256().toInt() != 0)) {
            tick--;
        }

        uint256 baseAmount = 10 ** PRECISION;
        int256 price = getQuoteAtTick(tick, baseAmount, token, stablecoin).toInt();

        // solhint-disable-next-line numcast/safe-cast
        int256 scale = uint256(decimalsToken).toInt() - uint256(decimalsStablecoin).toInt();

        int256 finalPrice = scale > 0
            ? price.upscale(scale.toUint())
            : price.downscale((-scale).toUint());

        return NodeOutput.Data(finalPrice, block.timestamp, 0, 0);
    }

    function getQuoteAtTick(
        int24 tick,
        uint256 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = sqrtRatioX96.to256() * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    function isValid(NodeDefinition.Data memory nodeDefinition) internal view returns (bool valid) {
        // Must have no parents
        if (nodeDefinition.parents.length > 0) {
            return false;
        }

        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length != 192) {
            return false;
        }

        (
            address token,
            address stablecoin,
            uint8 decimalsToken,
            uint8 decimalsStablecoin,
            address pool,
            uint32 secondsAgo
        ) = abi.decode(
                nodeDefinition.parameters,
                (address, address, uint8, uint8, address, uint32)
            );

        if (IERC20(token).decimals() != decimalsToken) {
            return false;
        }

        if (IERC20(stablecoin).decimals() != decimalsStablecoin) {
            return false;
        }

        address poolToken0 = IUniswapV3Pool(pool).token0();
        address poolToken1 = IUniswapV3Pool(pool).token1();

        if (
            !(poolToken0 == token && poolToken1 == stablecoin) &&
            !(poolToken0 == stablecoin && poolToken1 == token)
        ) {
            return false;
        }

        if (decimalsToken > 18 || decimalsStablecoin > 18) {
            return false;
        }

        if (secondsAgo == 0) {
            return false;
        }

        // Must call relevant function without error
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;
        IUniswapV3Pool(pool).observe(secondsAgos);

        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {ParameterError} from "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import {NodeOutput} from "./NodeOutput.sol";

import "../nodes/ReducerNode.sol";
import "../nodes/ExternalNode.sol";
import "../nodes/pyth/PythNode.sol";
import "../nodes/pyth/PythOffchainLookupNode.sol";
import "../nodes/ChainlinkNode.sol";
import "../nodes/PriceDeviationCircuitBreakerNode.sol";
import "../nodes/StalenessCircuitBreakerNode.sol";
import "../nodes/UniswapNode.sol";
import "../nodes/ConstantNode.sol";

library NodeDefinition {
    /**
     * @notice Thrown when a node cannot be processed
     */
    error UnprocessableNode(bytes32 nodeId);

    enum NodeType {
        NONE,
        REDUCER,
        EXTERNAL,
        CHAINLINK,
        UNISWAP,
        PYTH,
        PRICE_DEVIATION_CIRCUIT_BREAKER,
        STALENESS_CIRCUIT_BREAKER,
        CONSTANT,
        PYTH_OFFCHAIN_LOOKUP // works in conjunction with PYTH node
    }

    struct Data {
        /**
         * @dev Oracle node type enum
         */
        NodeType nodeType;
        /**
         * @dev Node parameters, specific to each node type
         */
        bytes parameters;
        /**
         * @dev Parent node IDs, if any
         */
        bytes32[] parents;
    }

    /**
     * @dev Returns the node stored at the specified node ID.
     */
    function load(bytes32 id) internal pure returns (Data storage node) {
        bytes32 s = keccak256(abi.encode("io.synthetix.oracle-manager.Node", id));
        assembly {
            node.slot := s
        }
    }

    /**
     * @dev Register a new node for a given node definition. The resulting node is a function of the definition.
     */
    function create(
        Data memory nodeDefinition
    ) internal returns (NodeDefinition.Data storage node, bytes32 id) {
        id = getId(nodeDefinition);

        node = load(id);

        node.nodeType = nodeDefinition.nodeType;
        node.parameters = nodeDefinition.parameters;
        node.parents = nodeDefinition.parents;
    }

    /**
     * @dev Returns a node ID based on its definition
     */
    function getId(Data memory nodeDefinition) internal pure returns (bytes32 id) {
        return
            keccak256(
                abi.encode(
                    nodeDefinition.nodeType,
                    nodeDefinition.parameters,
                    nodeDefinition.parents
                )
            );
    }

    /**
     * @dev Returns the output of a specified node.
     */
    function process(
        bytes32 nodeId,
        bytes32[] memory runtimeKeys,
        bytes32[] memory runtimeValues
    ) internal view returns (NodeOutput.Data memory price) {
        if (runtimeKeys.length != runtimeValues.length) {
            revert ParameterError.InvalidParameter(
                "runtimeValues",
                "must be same length as runtimeKeys"
            );
        }

        Data storage nodeDefinition = load(nodeId);
        NodeType nodeType = nodeDefinition.nodeType;

        if (nodeType == NodeType.REDUCER) {
            return
                ReducerNode.process(
                    _processParentNodeOutputs(nodeDefinition, runtimeKeys, runtimeValues),
                    nodeDefinition.parameters
                );
        } else if (nodeType == NodeType.EXTERNAL) {
            return
                ExternalNode.process(
                    _processParentNodeOutputs(nodeDefinition, runtimeKeys, runtimeValues),
                    nodeDefinition.parameters,
                    runtimeKeys,
                    runtimeValues
                );
        } else if (nodeType == NodeType.CHAINLINK) {
            return ChainlinkNode.process(nodeDefinition.parameters);
        } else if (nodeType == NodeType.UNISWAP) {
            return UniswapNode.process(nodeDefinition.parameters);
        } else if (nodeType == NodeType.PYTH) {
            return PythNode.process(nodeDefinition.parameters);
        } else if (nodeType == NodeType.PYTH_OFFCHAIN_LOOKUP) {
            return
                PythOffchainLookupNode.process(
                    nodeDefinition.parameters,
                    runtimeKeys,
                    runtimeValues
                );
        } else if (nodeType == NodeType.PRICE_DEVIATION_CIRCUIT_BREAKER) {
            return
                PriceDeviationCircuitBreakerNode.process(
                    _processParentNodeOutputs(nodeDefinition, runtimeKeys, runtimeValues),
                    nodeDefinition.parameters
                );
        } else if (nodeType == NodeType.STALENESS_CIRCUIT_BREAKER) {
            return StalenessCircuitBreakerNode.process(nodeDefinition, runtimeKeys, runtimeValues);
        } else if (nodeType == NodeType.CONSTANT) {
            return ConstantNode.process(nodeDefinition.parameters);
        }
        revert UnprocessableNode(nodeId);
    }

    /**
     * @dev helper function that calls process on parent nodes.
     */
    function _processParentNodeOutputs(
        Data storage nodeDefinition,
        bytes32[] memory runtimeKeys,
        bytes32[] memory runtimeValues
    ) private view returns (NodeOutput.Data[] memory parentNodeOutputs) {
        parentNodeOutputs = new NodeOutput.Data[](nodeDefinition.parents.length);
        for (uint256 i = 0; i < nodeDefinition.parents.length; i++) {
            parentNodeOutputs[i] = process(nodeDefinition.parents[i], runtimeKeys, runtimeValues);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library NodeOutput {
    struct Data {
        /**
         * @dev Price returned from the oracle node, expressed with 18 decimals of precision
         */
        int256 price;
        /**
         * @dev Timestamp associated with the price
         */
        uint256 timestamp;
        // solhint-disable-next-line private-vars-leading-underscore
        uint256 __slotAvailableForFutureUse1;
        // solhint-disable-next-line private-vars-leading-underscore
        uint256 __slotAvailableForFutureUse2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;

    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0, "Handle non-overflow cases");
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1, "prevents denominator == 0");

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (-denominator.toInt() & denominator.toInt()).toUint();
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max, "result more than max");
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;
    using SafeCastI24 for int24;
    using SafeCastU160 for uint160;

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? (-tick.to256()).toUint() : tick.to256().toUint();
        require(absTick <= MAX_TICK.to256().toUint(), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = ((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)).to160();
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
        uint256 ratio = sqrtPriceX96.to256() << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 _log2 = (msb.toInt() - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            _log2 := or(_log2, shl(50, f))
        }

        int256 logSqrt10001 = _log2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = (logSqrt10001 - 3402992956809132418596140100660247210).to24() >> 128;
        int24 tickHi = (logSqrt10001 + 291339464771989622907027621153398088495).to24() >> 128;

        if (tickLow == tickHi) {
            tick = tickLow;
        } else {
            tick = getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-modules/contracts/interfaces/IAssociatedSystemsModule.sol";
import "@synthetixio/main/contracts/interfaces/IMarketManagerModule.sol";
import "@synthetixio/main/contracts/interfaces/IMarketCollateralModule.sol";
import "@synthetixio/main/contracts/interfaces/IUtilsModule.sol";

// solhint-disable no-empty-blocks
interface ISynthetixSystem is
    IAssociatedSystemsModule,
    IMarketCollateralModule,
    IMarketManagerModule,
    IUtilsModule
{}
// solhint-enable no-empty-blocks

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {OrderFees} from "../storage/OrderFees.sol";
import {Price} from "../storage/Price.sol";

/**
 * @title Module for atomic buy and sell orders for traders.
 */
interface IAtomicOrderModule {
    /**
     * @notice Thrown when trade is charging more USD than the max amount specified by the trader.
     * @dev Used in buyExactOut
     */
    error ExceedsMaxUsdAmount(uint256 maxUsdAmount, uint256 usdAmountCharged);
    /**
     * @notice Thrown when trade is charging more synth than the max amount specified by the trader.
     * @dev Used in sellExactOut
     */
    error ExceedsMaxSynthAmount(uint256 maxSynthAmount, uint256 synthAmountCharged);
    /**
     * @notice Thrown when a trade doesn't meet minimum expected return amount.
     */
    error InsufficientAmountReceived(uint256 expected, uint256 current);

    /**
     * @notice Thrown when the sell price is higher than the buy price
     */
    error InvalidPrices();

    /**
     * @notice Gets fired when buy trade is complete
     * @param synthMarketId Id of the market used for the trade.
     * @param synthReturned Synth received on the trade based on amount provided by trader.
     * @param fees breakdown of all fees incurred for transaction.
     * @param collectedFees Fees collected by the configured FeeCollector for the market (rest of the fees are deposited to market manager).
     * @param referrer Optional address of the referrer, for fee share
     */
    event SynthBought(
        uint256 indexed synthMarketId,
        uint256 synthReturned,
        OrderFees.Data fees,
        uint256 collectedFees,
        address referrer,
        uint256 price
    );

    /**
     * @notice Gets fired when sell trade is complete
     * @param synthMarketId Id of the market used for the trade.
     * @param amountReturned Amount of snxUSD returned to user based on synth provided by trader.
     * @param fees breakdown of all fees incurred for transaction.
     * @param collectedFees Fees collected by the configured FeeCollector for the market (rest of the fees are deposited to market manager).
     * @param referrer Optional address of the referrer, for fee share
     */
    event SynthSold(
        uint256 indexed synthMarketId,
        uint256 amountReturned,
        OrderFees.Data fees,
        uint256 collectedFees,
        address referrer,
        uint256 price
    );

    /**
     * @notice Initiates a buy trade returning synth for the specified amountUsd.
     * @dev Transfers the specified amountUsd, collects fees through configured fee collector, returns synth to the trader.
     * @dev Leftover fees not collected get deposited into the market manager to improve market PnL.
     * @dev Uses the buyFeedId configured for the market.
     * @param synthMarketId Id of the market used for the trade.
     * @param amountUsd Amount of snxUSD trader is providing allowance for the trade.
     * @param minAmountReceived Min Amount of synth is expected the trader to receive otherwise the transaction will revert.
     * @param referrer Optional address of the referrer, for fee share
     * @return synthAmount Synth received on the trade based on amount provided by trader.
     * @return fees breakdown of all the fees incurred for the transaction.
     */
    function buyExactIn(
        uint128 synthMarketId,
        uint256 amountUsd,
        uint256 minAmountReceived,
        address referrer
    ) external returns (uint256 synthAmount, OrderFees.Data memory fees);

    /**
     * @notice  alias for buyExactIn
     * @param   marketId  (see buyExactIn)
     * @param   usdAmount  (see buyExactIn)
     * @param   minAmountReceived  (see buyExactIn)
     * @param   referrer  (see buyExactIn)
     * @return  synthAmount  (see buyExactIn)
     * @return  fees  (see buyExactIn)
     */
    function buy(
        uint128 marketId,
        uint256 usdAmount,
        uint256 minAmountReceived,
        address referrer
    ) external returns (uint256 synthAmount, OrderFees.Data memory fees);

    /**
     * @notice  user provides the synth amount they'd like to buy, and the function charges the USD amount which includes fees
     * @dev     the inverse of buyExactIn
     * @param   synthMarketId  market id value
     * @param   synthAmount  the amount of synth the trader wants to buy
     * @param   maxUsdAmount  max amount the trader is willing to pay for the specified synth
     * @param   referrer  optional address of the referrer, for fee share
     * @return  usdAmountCharged  amount of USD charged for the trade
     * @return  fees  breakdown of all the fees incurred for the transaction
     */
    function buyExactOut(
        uint128 synthMarketId,
        uint256 synthAmount,
        uint256 maxUsdAmount,
        address referrer
    ) external returns (uint256 usdAmountCharged, OrderFees.Data memory fees);

    /**
     * @notice  quote for buyExactIn.  same parameters and return values as buyExactIn
     * @param   synthMarketId  market id value
     * @param   usdAmount  amount of USD to use for the trade
     * @param   stalenessTolerance  this enum determines what staleness tolerance to use
     * @return  synthAmount  return amount of synth given the USD amount - fees
     * @return  fees  breakdown of all the quoted fees for the buy txn
     */
    function quoteBuyExactIn(
        uint128 synthMarketId,
        uint256 usdAmount,
        Price.Tolerance stalenessTolerance
    ) external view returns (uint256 synthAmount, OrderFees.Data memory fees);

    /**
     * @notice  quote for buyExactOut.  same parameters and return values as buyExactOut
     * @param   synthMarketId  market id value
     * @param   synthAmount  amount of synth requested
     * @param   stalenessTolerance  this enum determines what staleness tolerance to use
     * @return  usdAmountCharged  USD amount charged for the synth requested - fees
     * @return  fees  breakdown of all the quoted fees for the buy txn
     */
    function quoteBuyExactOut(
        uint128 synthMarketId,
        uint256 synthAmount,
        Price.Tolerance stalenessTolerance
    ) external view returns (uint256 usdAmountCharged, OrderFees.Data memory);

    /**
     * @notice Initiates a sell trade returning snxUSD for the specified amount of synth (sellAmount)
     * @dev Transfers the specified synth, collects fees through configured fee collector, returns snxUSD to the trader.
     * @dev Leftover fees not collected get deposited into the market manager to improve market PnL.
     * @param synthMarketId Id of the market used for the trade.
     * @param sellAmount Amount of synth provided by trader for trade into snxUSD.
     * @param minAmountReceived Min Amount of snxUSD trader expects to receive for the trade
     * @param referrer Optional address of the referrer, for fee share
     * @return returnAmount Amount of snxUSD returned to user
     * @return fees breakdown of all the fees incurred for the transaction.
     */
    function sellExactIn(
        uint128 synthMarketId,
        uint256 sellAmount,
        uint256 minAmountReceived,
        address referrer
    ) external returns (uint256 returnAmount, OrderFees.Data memory fees);

    /**
     * @notice  initiates a trade where trader specifies USD amount they'd like to receive
     * @dev     the inverse of sellExactIn
     * @param   marketId  synth market id
     * @param   usdAmount  amount of USD trader wants to receive
     * @param   maxSynthAmount  max amount of synth trader is willing to use to receive the specified USD amount
     * @param   referrer  optional address of the referrer, for fee share
     * @return  synthToBurn amount of synth charged for the specified usd amount
     * @return  fees breakdown of all the fees incurred for the transaction
     */
    function sellExactOut(
        uint128 marketId,
        uint256 usdAmount,
        uint256 maxSynthAmount,
        address referrer
    ) external returns (uint256 synthToBurn, OrderFees.Data memory fees);

    /**
     * @notice  alias for sellExactIn
     * @param   marketId  (see sellExactIn)
     * @param   synthAmount  (see sellExactIn)
     * @param   minUsdAmount  (see sellExactIn)
     * @param   referrer  (see sellExactIn)
     * @return  usdAmountReceived  (see sellExactIn)
     * @return  fees  (see sellExactIn)
     */
    function sell(
        uint128 marketId,
        uint256 synthAmount,
        uint256 minUsdAmount,
        address referrer
    ) external returns (uint256 usdAmountReceived, OrderFees.Data memory fees);

    /**
     * @notice  quote for sellExactIn
     * @dev     returns expected USD amount trader would receive for the specified synth amount
     * @param   marketId  synth market id
     * @param   synthAmount  synth amount trader is providing for the trade
     * @param   stalenessTolerance  this enum determines what staleness tolerance to use
     * @return  returnAmount  amount of USD expected back
     * @return  fees  breakdown of all the quoted fees for the txn
     */
    function quoteSellExactIn(
        uint128 marketId,
        uint256 synthAmount,
        Price.Tolerance stalenessTolerance
    ) external view returns (uint256 returnAmount, OrderFees.Data memory fees);

    /**
     * @notice  quote for sellExactOut
     * @dev     returns expected synth amount expected from trader for the requested USD amount
     * @param   marketId  synth market id
     * @param   usdAmount  USD amount trader wants to receive
     * @param   stalenessTolerance  this enum determines what staleness tolerance to use
     * @return  synthToBurn  amount of synth expected from trader
     * @return  fees  breakdown of all the quoted fees for the txn
     */
    function quoteSellExactOut(
        uint128 marketId,
        uint256 usdAmount,
        Price.Tolerance stalenessTolerance
    ) external view returns (uint256 synthToBurn, OrderFees.Data memory fees);

    /**
     * @notice  gets the current market skew
     * @param   marketId  synth market id
     * @return  marketSkew  the skew
     */
    function getMarketSkew(uint128 marketId) external view returns (int256 marketSkew);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {IMarket} from "@synthetixio/main/contracts/interfaces/external/IMarket.sol";
import {ISynthetixSystem} from "./external/ISynthetixSystem.sol";

/**
 * @title Module for spot market factory
 */
interface ISpotMarketFactoryModule is IMarket {
    /**
     * @notice Thrown when an address tries to accept market ownership but has not been nominated.
     * @param addr The address that is trying to accept ownership.
     */
    error NotNominated(address addr);

    /**
     * @notice Thrown when createSynth is called with zero-address synth owner
     */
    error InvalidMarketOwner();

    /**
     * @notice Gets fired when the synthetix is set
     * @param synthetix address of the synthetix core contract
     * @param usdTokenAddress address of the USDToken contract
     * @param oracleManager address of the Oracle Manager contract
     */
    event SynthetixSystemSet(address synthetix, address usdTokenAddress, address oracleManager);
    /**
     * @notice Gets fired when the synth implementation is set
     * @param synthImplementation address of the synth implementation
     */
    event SynthImplementationSet(address synthImplementation);
    /**
     * @notice Gets fired when the synth is registered as a market.
     * @param synthMarketId Id of the synth market that was created
     * @param synthTokenAddress address of the newly created synth token
     */
    event SynthRegistered(uint256 indexed synthMarketId, address synthTokenAddress);
    /**
     * @notice Gets fired when the synth's implementation is updated on the corresponding proxy.
     * @param proxy the synth proxy servicing the latest implementation
     * @param implementation the latest implementation of the synth
     */
    event SynthImplementationUpgraded(
        uint256 indexed synthMarketId,
        address indexed proxy,
        address implementation
    );
    /**
     * @notice Gets fired when the market's price feeds are updated, compatible with oracle manager
     * @param buyFeedId the oracle manager feed id for the buy price
     * @param sellFeedId the oracle manager feed id for the sell price
     */
    event SynthPriceDataUpdated(
        uint256 indexed synthMarketId,
        bytes32 indexed buyFeedId,
        bytes32 indexed sellFeedId,
        uint256 strictStalenessTolerance
    );
    /**
     * @notice Gets fired when the market's price feeds are updated, compatible with oracle manager
     * @param marketId Id of the synth market
     * @param rate the new decay rate (1e16 means 1% decay per year)
     */
    event DecayRateUpdated(uint128 indexed marketId, uint256 rate);

    /**
     * @notice Emitted when an address has been nominated.
     * @param marketId id of the market
     * @param newOwner The address that has been nominated.
     */
    event MarketOwnerNominated(uint128 indexed marketId, address newOwner);

    /**
     * @notice Emitted when market nominee renounces nomination.
     * @param marketId id of the market
     * @param nominee The address that has been nominated.
     */
    event MarketNominationRenounced(uint128 indexed marketId, address nominee);

    /**
     * @notice Emitted when the owner of the market has changed.
     * @param marketId id of the market
     * @param oldOwner The previous owner of the market.
     * @param newOwner The new owner of the market.
     */
    event MarketOwnerChanged(uint128 indexed marketId, address oldOwner, address newOwner);

    /**
     * @notice Sets the v3 synthetix core system.
     * @dev Pulls in the USDToken and oracle manager from the synthetix core system and sets those appropriately.
     * @param synthetix synthetix v3 core system address
     */
    function setSynthetix(ISynthetixSystem synthetix) external;

    /**
     * @notice When a new synth is created, this is the erc20 implementation that is used.
     * @param synthImplementation erc20 implementation address
     */
    function setSynthImplementation(address synthImplementation) external;

    /**
     * @notice Creates a new synth market with synthetix v3 core system via market manager
     * @dev The synth is created using the initial synth implementation and creates a proxy for future upgrades of the synth implementation.
     * @dev Sets up the market owner who can update configuration for the synth.
     * @param tokenName name of synth (i.e Synthetix ETH)
     * @param tokenSymbol symbol of synth (i.e snxETH)
     * @param synthOwner owner of the market that's created.
     * @return synthMarketId id of the synth market that was created
     */
    function createSynth(
        string memory tokenName,
        string memory tokenSymbol,
        address synthOwner
    ) external returns (uint128 synthMarketId);

    /**
     * @notice Get the proxy address of the synth for the provided marketId
     * @dev Uses associated systems module to retrieve the token address.
     * @param marketId id of the market
     * @return synthAddress address of the proxy for the synth
     */
    function getSynth(uint128 marketId) external view returns (address synthAddress);

    /**
     * @notice Get the implementation address of the synth for the provided marketId.
     * This address should not be used directly--use `getSynth` instead
     * @dev Uses associated systems module to retrieve the token address.
     * @param marketId id of the market
     * @return implAddress address of the proxy for the synth
     */
    function getSynthImpl(uint128 marketId) external view returns (address implAddress);

    /**
     * @notice Update the price data for a given market.
     * @dev Only the market owner can call this function.
     * @param marketId id of the market
     * @param buyFeedId the oracle manager buy feed node id
     * @param sellFeedId the oracle manager sell feed node id
     * @param strictPriceStalenessTolerance configurable price staleness tolerance used for transacting
     */
    function updatePriceData(
        uint128 marketId,
        bytes32 buyFeedId,
        bytes32 sellFeedId,
        uint256 strictPriceStalenessTolerance
    ) external;

    /**
     * @notice Gets the price data for a given market.
     * @dev Only the market owner can call this function.
     * @param marketId id of the market
     * @return buyFeedId the oracle manager buy feed node id
     * @return sellFeedId the oracle manager sell feed node id
     * @return strictPriceStalenessTolerance configurable price staleness tolerance used for transacting
     */
    function getPriceData(
        uint128 marketId
    )
        external
        view
        returns (bytes32 buyFeedId, bytes32 sellFeedId, uint256 strictPriceStalenessTolerance);

    /**
     * @notice upgrades the synth implementation to the current implementation for the specified market.
     * Anyone who is willing and able to spend the gas can call this method.
     * @dev The synth implementation is upgraded via the proxy.
     * @param marketId id of the market
     */
    function upgradeSynthImpl(uint128 marketId) external;

    /**
     * @notice Allows market to adjust decay rate of the synth
     * @param marketId the market to update the synth decay rate for
     * @param rate APY to decay of the synth to decay by, as a 18 decimal ratio
     */
    function setDecayRate(uint128 marketId, uint256 rate) external;

    /**
     * @notice Allows the current market owner to nominate a new owner.
     * @dev The nominated owner will have to call `acceptOwnership` in a separate transaction in order to finalize the action and become the new contract owner.
     * @param synthMarketId synth market id value
     * @param newNominatedOwner The address that is to become nominated.
     */
    function nominateMarketOwner(uint128 synthMarketId, address newNominatedOwner) external;

    /**
     * @notice Allows a nominated address to accept ownership of the market.
     * @dev Reverts if the caller is not nominated.
     * @param synthMarketId synth market id value
     */
    function acceptMarketOwnership(uint128 synthMarketId) external;

    /**
     * @notice Allows a nominated address to renounce ownership of the market.
     * @dev Reverts if the caller is not nominated.
     * @param synthMarketId synth market id value
     */
    function renounceMarketNomination(uint128 synthMarketId) external;

    /**
     * @notice Allows the market owner to renounce his ownership.
     * @dev Reverts if the caller is not the owner.
     * @param synthMarketId synth market id value
     */
    function renounceMarketOwnership(uint128 synthMarketId) external;

    /**
     * @notice Returns market owner.
     * @param synthMarketId synth market id value
     */
    function getMarketOwner(uint128 synthMarketId) external view returns (address);

    /**
     * @notice Returns nominated market owner.
     * @param synthMarketId synth market id value
     */
    function getNominatedMarketOwner(uint128 synthMarketId) external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {SafeCastU256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @notice  A convenience library that includes a Data struct which is used to track fees across different trade types
 */
library OrderFees {
    using SafeCastU256 for uint256;

    struct Data {
        uint256 fixedFees;
        uint256 utilizationFees;
        int256 skewFees;
        int256 wrapperFees;
    }

    function total(Data memory self) internal pure returns (int256 amount) {
        return
            self.fixedFees.toInt() +
            self.utilizationFees.toInt() +
            self.skewFees +
            self.wrapperFees;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {INodeModule} from "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";
import {NodeOutput} from "@synthetixio/oracle-manager/contracts/storage/NodeOutput.sol";
import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import {SafeCastI256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {SpotMarketFactory} from "./SpotMarketFactory.sol";
import {Transaction} from "../utils/TransactionUtil.sol";

/**
 * @title Price storage for a specific synth market.
 */
library Price {
    using DecimalMath for int256;
    using DecimalMath for uint256;
    using SafeCastI256 for int256;

    enum Tolerance {
        DEFAULT,
        STRICT
    }

    struct Data {
        /**
         * @dev The oracle manager node id used for buy transactions.
         */
        bytes32 buyFeedId;
        /**
         * @dev The oracle manager node id used for all non-buy transactions.
         * @dev also used to for calculating reported debt
         */
        bytes32 sellFeedId;
        /**
         * @dev configurable staleness tolerance to use when fetching prices.
         */
        uint256 strictStalenessTolerance;
    }

    function load(uint128 marketId) internal pure returns (Data storage price) {
        bytes32 s = keccak256(abi.encode("io.synthetix.spot-market.Price", marketId));
        assembly {
            price.slot := s
        }
    }

    function getCurrentPrice(
        uint128 marketId,
        Transaction.Type transactionType,
        Tolerance priceTolerance
    ) internal view returns (uint256 price) {
        Data storage self = load(marketId);
        SpotMarketFactory.Data storage factory = SpotMarketFactory.load();
        bytes32 feedId = Transaction.isBuy(transactionType) ? self.buyFeedId : self.sellFeedId;

        NodeOutput.Data memory output;

        if (priceTolerance == Tolerance.STRICT) {
            bytes32[] memory runtimeKeys = new bytes32[](1);
            bytes32[] memory runtimeValues = new bytes32[](1);
            runtimeKeys[0] = bytes32("stalenessTolerance");
            runtimeValues[0] = bytes32(self.strictStalenessTolerance);
            output = INodeModule(factory.oracle).processWithRuntime(
                feedId,
                runtimeKeys,
                runtimeValues
            );
        } else {
            output = INodeModule(factory.oracle).process(feedId);
        }

        price = output.price.toUint();
    }

    /**
     * @dev Updates price feeds.  Function resides in SpotMarketFactory to update these values.
     * Only market owner can update these values.
     */
    function update(
        Data storage self,
        bytes32 buyFeedId,
        bytes32 sellFeedId,
        uint256 strictStalenessTolerance
    ) internal {
        self.buyFeedId = buyFeedId;
        self.sellFeedId = sellFeedId;
        self.strictStalenessTolerance = strictStalenessTolerance;
    }

    /**
     * @dev Utility function that returns the amount denominated with 18 decimals of precision.
     */
    function scale(int256 amount, uint256 decimals) internal pure returns (int256 scaledAmount) {
        return (decimals > 18 ? amount.downscale(decimals - 18) : amount.upscale(18 - decimals));
    }

    /**
     * @dev Utility function that receive amount with 18 decimals
     * returns the amount denominated with number of decimals as arg of 18.
     */
    function scaleTo(int256 amount, uint256 decimals) internal pure returns (int256 scaledAmount) {
        return (decimals > 18 ? amount.upscale(decimals - 18) : amount.downscale(18 - decimals));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/ERC2771Context.sol";
import {ITokenModule} from "@synthetixio/core-modules/contracts/interfaces/ITokenModule.sol";
import {INodeModule} from "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";
import {ISynthetixSystem} from "../interfaces/external/ISynthetixSystem.sol";

/**
 * @title Main factory library that registers synths.  Also houses global configuration for all synths.
 */
library SpotMarketFactory {
    bytes32 private constant _SLOT_SPOT_MARKET_FACTORY =
        keccak256(abi.encode("io.synthetix.spot-market.SpotMarketFactory"));

    error OnlyMarketOwner(address marketOwner, address sender);
    error InvalidMarket(uint128 marketId);
    error InvalidSynthImplementation(uint256 synthImplementation);

    struct Data {
        /**
         * @dev snxUSD token address
         */
        ITokenModule usdToken;
        /**
         * @dev oracle manager address used for price feeds
         */
        INodeModule oracle;
        /**
         * @dev Synthetix core v3 proxy
         */
        ISynthetixSystem synthetix;
        /**
         * @dev erc20 synth implementation address.  associated systems creates a proxy backed by this implementation.
         */
        address synthImplementation;
        /**
         * @dev mapping of marketId to marketOwner
         */
        mapping(uint128 => address) marketOwners;
        /**
         * @dev mapping of marketId to marketNominatedOwner
         */
        mapping(uint128 => address) nominatedMarketOwners;
    }

    function load() internal pure returns (Data storage spotMarketFactory) {
        bytes32 s = _SLOT_SPOT_MARKET_FACTORY;
        assembly {
            spotMarketFactory.slot := s
        }
    }

    /**
     * @notice ensures synth implementation is set before creating synth
     */
    function checkSynthImplemention(Data storage self) internal view {
        if (self.synthImplementation == address(0)) {
            revert InvalidSynthImplementation(0);
        }
    }

    /**
     * @notice only owner of market passes check, otherwise reverts
     */
    function onlyMarketOwner(Data storage self, uint128 marketId) internal view {
        address marketOwner = self.marketOwners[marketId];

        if (marketOwner != ERC2771Context._msgSender()) {
            revert OnlyMarketOwner(marketOwner, ERC2771Context._msgSender());
        }
    }

    /**
     * @notice validates market id by checking that an owner exists for the market
     */
    function validateMarket(Data storage self, uint128 marketId) internal view {
        if (self.marketOwners[marketId] == address(0)) {
            revert InvalidMarket(marketId);
        }
    }

    /**
     * @dev first creates an allowance entry in usdToken for market manager, then deposits snxUSD amount into mm.
     */
    function depositToMarketManager(Data storage self, uint128 marketId, uint256 amount) internal {
        self.usdToken.approve(address(this), amount);
        self.synthetix.depositMarketUsd(marketId, address(this), amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Transaction types supported by the spot market system
 */
library Transaction {
    error InvalidAsyncTransactionType(Type transactionType);

    enum Type {
        NULL, // reserved for 0 (default value)
        BUY,
        SELL,
        ASYNC_BUY,
        ASYNC_SELL,
        WRAP,
        UNWRAP
    }

    function validateAsyncTransaction(Type orderType) internal pure {
        if (orderType != Type.ASYNC_BUY && orderType != Type.ASYNC_SELL) {
            revert InvalidAsyncTransactionType(orderType);
        }
    }

    function isBuy(Type orderType) internal pure returns (bool) {
        return orderType == Type.BUY || orderType == Type.ASYNC_BUY;
    }

    function isSell(Type orderType) internal pure returns (bool) {
        return orderType == Type.SELL || orderType == Type.ASYNC_SELL;
    }

    function isWrapper(Type orderType) internal pure returns (bool) {
        return orderType == Type.WRAP || orderType == Type.UNWRAP;
    }

    function isAsync(Type orderType) internal pure returns (bool) {
        return orderType == Type.ASYNC_BUY || orderType == Type.ASYNC_SELL;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

interface IFeeCollector is IERC165 {
    /**
     * @notice  .This function is called by the spot market proxy to get the fee amount to be collected.
     * @dev     .The quoted fee amount is then transferred directly to the fee collector.
     * @param   marketId  .synth market id value
     * @param   feeAmount  .max fee amount that can be collected
     * @param   transactor  .the trader the fee was collected from
     * @return  feeAmountToCollect  .quoted fee amount
     */
    function quoteFees(
        uint128 marketId,
        uint256 feeAmount,
        address transactor
    ) external returns (uint256 feeAmountToCollect);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {IAtomicOrderModule} from "@synthetixio/spot-market/contracts/interfaces/IAtomicOrderModule.sol";
import {ISpotMarketFactoryModule} from "@synthetixio/spot-market/contracts/interfaces/ISpotMarketFactoryModule.sol";

// solhint-disable-next-line no-empty-blocks
interface ISpotMarketSystem is IAtomicOrderModule, ISpotMarketFactoryModule {}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {IAssociatedSystemsModule} from "@synthetixio/core-modules/contracts/interfaces/IAssociatedSystemsModule.sol";
import {IMarketManagerModule} from "@synthetixio/main/contracts/interfaces/IMarketManagerModule.sol";
import {IMarketCollateralModule} from "@synthetixio/main/contracts/interfaces/IMarketCollateralModule.sol";
import {IUtilsModule} from "@synthetixio/main/contracts/interfaces/IUtilsModule.sol";
import {ICollateralConfigurationModule} from "@synthetixio/main/contracts/interfaces/ICollateralConfigurationModule.sol";

// solhint-disable-next-line no-empty-blocks
interface ISynthetixSystem is
    IAssociatedSystemsModule,
    IMarketCollateralModule,
    IMarketManagerModule,
    IUtilsModule,
    ICollateralConfigurationModule
{}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {AsyncOrder} from "../storage/AsyncOrder.sol";
import {SettlementStrategy} from "../storage/SettlementStrategy.sol";

/**
 * @title Module for committing and settling async orders.
 */
interface IAsyncOrderModule {
    /**
     * @notice Gets fired when a new order is committed.
     * @param marketId Id of the market used for the trade.
     * @param accountId Id of the account used for the trade.
     * @param orderType Should send 0 (at time of writing) that correlates to the transaction type enum defined in SettlementStrategy.Type.
     * @param sizeDelta requested change in size of the order sent by the user.
     * @param acceptablePrice maximum or minimum, depending on the sizeDelta direction, accepted price to settle the order, set by the user.
     * @param commitmentTime Time at which the order was committed.
     * @param settlementTime start time of the settlement window.
     * @param expirationTime Time at which the order expired.
     * @param trackingCode Optional code for integrator tracking purposes.
     * @param sender address of the sender of the order. Authorized to commit by account owner.
     */
    event OrderCommitted(
        uint128 indexed marketId,
        uint128 indexed accountId,
        SettlementStrategy.Type orderType,
        int128 sizeDelta,
        uint256 acceptablePrice,
        uint256 commitmentTime,
        uint256 expectedPriceTime,
        uint256 settlementTime,
        uint256 expirationTime,
        bytes32 indexed trackingCode,
        address sender
    );

    /**
     * @notice Gets fired when a new order is committed while a previous one was expired.
     * @param marketId Id of the market used for the trade.
     * @param accountId Id of the account used for the trade.
     * @param sizeDelta requested change in size of the order sent by the user.
     * @param acceptablePrice maximum or minimum, depending on the sizeDelta direction, accepted price to settle the order, set by the user.
     * @param commitmentTime Time at which the order was committed.
     * @param trackingCode Optional code for integrator tracking purposes.
     */
    event PreviousOrderExpired(
        uint128 indexed marketId,
        uint128 indexed accountId,
        int128 sizeDelta,
        uint256 acceptablePrice,
        uint256 commitmentTime,
        bytes32 indexed trackingCode
    );

    /**
     * @notice Commit an async order via this function
     * @param commitment Order commitment data (see AsyncOrder.OrderCommitmentRequest struct).
     * @return retOrder order details (see AsyncOrder.Data struct).
     * @return fees order fees (protocol + settler)
     */
    function commitOrder(
        AsyncOrder.OrderCommitmentRequest memory commitment
    ) external returns (AsyncOrder.Data memory retOrder, uint256 fees);

    /**
     * @notice Get async order claim details
     * @param accountId id of the account.
     * @return order async order claim details (see AsyncOrder.Data struct).
     */
    function getOrder(uint128 accountId) external view returns (AsyncOrder.Data memory order);

    /**
     * @notice Simulates what the order fee would be for the given market with the specified size.
     * @dev    Note that this does not include the settlement reward fee, which is based on the strategy type used
     * @param marketId id of the market.
     * @param sizeDelta size of position.
     * @return orderFees incurred fees.
     * @return fillPrice price at which the order would be filled.
     */
    function computeOrderFees(
        uint128 marketId,
        int128 sizeDelta
    ) external view returns (uint256 orderFees, uint256 fillPrice);

    /**
     * @notice Simulates what the order fee would be for the given market with the specified size.
     * @dev    Note that this does not include the settlement reward fee, which is based on the strategy type used
     * @param marketId id of the market.
     * @param sizeDelta size of position.
     * @param price price of the market.
     * @return orderFees incurred fees.
     * @return fillPrice price at which the order would be filled.
     */
    function computeOrderFeesWithPrice(
        uint128 marketId,
        int128 sizeDelta,
        uint256 price
    ) external view returns (uint256 orderFees, uint256 fillPrice);

    /**
     * @notice Gets the settlement cost including keeper rewards and keeper costs.
     * @param marketId Id of the market.
     * @param settlementStrategyId Order size.
     * @return settlement cost.
     */
    function getSettlementRewardCost(
        uint128 marketId,
        uint128 settlementStrategyId
    ) external view returns (uint256);

    /**
     * @notice For a given market, account id, and a position size, returns the required total account margin for this order to succeed
     * @dev    Useful for integrators to determine if an order will succeed or fail
     * @param marketId id of the market.
     * @param accountId id of the trader account.
     * @param sizeDelta size of position.
     * @return requiredMargin margin required for the order to succeed.
     */
    function requiredMarginForOrder(
        uint128 marketId,
        uint128 accountId,
        int128 sizeDelta
    ) external view returns (uint256 requiredMargin);

    /**
     * @notice For a given market, account id, and a position size, and expected price returns the required total account margin for this order to succeed
     * @dev    Useful for integrators to determine if an order will succeed or fail faking different price scenarios
     * @param marketId id of the market.
     * @param accountId id of the trader account.
     * @param sizeDelta size of position.
     * @param price price of the market.
     * @return requiredMargin margin required for the order to succeed.
     */
    function requiredMarginForOrderWithPrice(
        uint128 marketId,
        uint128 accountId,
        int128 sizeDelta,
        uint256 price
    ) external view returns (uint256 requiredMargin);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {ERC2771Context} from "@synthetixio/core-contracts/contracts/utils/ERC2771Context.sol";
import {FeatureFlag} from "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";
import {Account} from "@synthetixio/main/contracts/storage/Account.sol";
import {AccountRBAC} from "@synthetixio/main/contracts/storage/AccountRBAC.sol";
import {IAsyncOrderModule} from "../interfaces/IAsyncOrderModule.sol";
import {PerpsMarket} from "../storage/PerpsMarket.sol";
import {PerpsAccount} from "../storage/PerpsAccount.sol";
import {AsyncOrder} from "../storage/AsyncOrder.sol";
import {Position} from "../storage/Position.sol";
import {PerpsPrice} from "../storage/PerpsPrice.sol";
import {GlobalPerpsMarket} from "../storage/GlobalPerpsMarket.sol";
import {PerpsMarketConfiguration} from "../storage/PerpsMarketConfiguration.sol";
import {SettlementStrategy} from "../storage/SettlementStrategy.sol";
import {Flags} from "../utils/Flags.sol";

/**
 * @title Module for committing async orders.
 * @dev See IAsyncOrderModule.
 */
contract AsyncOrderModule is IAsyncOrderModule {
    using AsyncOrder for AsyncOrder.Data;
    using PerpsAccount for PerpsAccount.Data;
    using GlobalPerpsMarket for GlobalPerpsMarket.Data;

    /**
     * @inheritdoc IAsyncOrderModule
     */
    function commitOrder(
        AsyncOrder.OrderCommitmentRequest memory commitment
    ) external override returns (AsyncOrder.Data memory retOrder, uint256 fees) {
        FeatureFlag.ensureAccessToFeature(Flags.PERPS_SYSTEM);
        PerpsMarket.loadValid(commitment.marketId);

        // Check if commitment.accountId is valid
        Account.exists(commitment.accountId);

        // Check ERC2771Context._msgSender() can commit order for commitment.accountId
        Account.loadAccountAndValidatePermission(
            commitment.accountId,
            AccountRBAC._PERPS_COMMIT_ASYNC_ORDER_PERMISSION
        );

        GlobalPerpsMarket.load().checkLiquidation(commitment.accountId);

        SettlementStrategy.Data storage strategy = PerpsMarketConfiguration
            .loadValidSettlementStrategy(commitment.marketId, commitment.settlementStrategyId);

        AsyncOrder.Data storage order = AsyncOrder.load(commitment.accountId);

        // if order (previous) sizeDelta is not zero and didn't revert while checking, it means the previous order expired
        if (order.request.sizeDelta != 0) {
            // @notice not including the expiration time since it requires the previous settlement strategy to be loaded and enabled, otherwise loading it will revert and will prevent new orders to be committed
            emit PreviousOrderExpired(
                order.request.marketId,
                order.request.accountId,
                order.request.sizeDelta,
                order.request.acceptablePrice,
                order.commitmentTime,
                order.request.trackingCode
            );
        }

        order.updateValid(commitment);

        (, uint256 feesAccrued, , ) = order.validateRequest(
            strategy,
            PerpsPrice.getCurrentPrice(commitment.marketId, PerpsPrice.Tolerance.DEFAULT)
        );

        emit OrderCommitted(
            commitment.marketId,
            commitment.accountId,
            strategy.strategyType,
            commitment.sizeDelta,
            commitment.acceptablePrice,
            order.commitmentTime,
            order.commitmentTime + strategy.commitmentPriceDelay,
            order.commitmentTime + strategy.settlementDelay,
            order.commitmentTime + strategy.settlementDelay + strategy.settlementWindowDuration,
            commitment.trackingCode,
            ERC2771Context._msgSender()
        );

        return (order, feesAccrued);
    }

    /**
     * @inheritdoc IAsyncOrderModule
     */
    // solc-ignore-next-line func-mutability
    function getOrder(
        uint128 accountId
    ) external view override returns (AsyncOrder.Data memory order) {
        order = AsyncOrder.load(accountId);
    }

    /**
     * @inheritdoc IAsyncOrderModule
     */
    function computeOrderFees(
        uint128 marketId,
        int128 sizeDelta
    ) external view override returns (uint256 orderFees, uint256 fillPrice) {
        (orderFees, fillPrice) = _computeOrderFees(
            marketId,
            sizeDelta,
            PerpsPrice.getCurrentPrice(marketId, PerpsPrice.Tolerance.DEFAULT)
        );
    }

    /**
     * @inheritdoc IAsyncOrderModule
     */
    function computeOrderFeesWithPrice(
        uint128 marketId,
        int128 sizeDelta,
        uint256 price
    ) external view override returns (uint256 orderFees, uint256 fillPrice) {
        (orderFees, fillPrice) = _computeOrderFees(marketId, sizeDelta, price);
    }

    /**
     * @inheritdoc IAsyncOrderModule
     */
    function getSettlementRewardCost(
        uint128 marketId,
        uint128 settlementStrategyId
    ) external view override returns (uint256) {
        return
            AsyncOrder.settlementRewardCost(
                PerpsMarketConfiguration.loadValidSettlementStrategy(marketId, settlementStrategyId)
            );
    }

    function requiredMarginForOrder(
        uint128 accountId,
        uint128 marketId,
        int128 sizeDelta
    ) external view override returns (uint256 requiredMargin) {
        return
            _requiredMarginForOrder(
                accountId,
                marketId,
                sizeDelta,
                PerpsPrice.getCurrentPrice(marketId, PerpsPrice.Tolerance.DEFAULT)
            );
    }

    function requiredMarginForOrderWithPrice(
        uint128 accountId,
        uint128 marketId,
        int128 sizeDelta,
        uint256 price
    ) external view override returns (uint256 requiredMargin) {
        return _requiredMarginForOrder(accountId, marketId, sizeDelta, price);
    }

    function _requiredMarginForOrder(
        uint128 accountId,
        uint128 marketId,
        int128 sizeDelta,
        uint256 orderPrice
    ) internal view returns (uint256 requiredMargin) {
        PerpsMarketConfiguration.Data storage marketConfig = PerpsMarketConfiguration.load(
            marketId
        );

        Position.Data storage oldPosition = PerpsMarket.accountPosition(marketId, accountId);
        PerpsAccount.Data storage account = PerpsAccount.load(accountId);
        (uint256 currentInitialMargin, , ) = account.getAccountRequiredMargins(
            PerpsPrice.Tolerance.DEFAULT
        );
        (uint256 orderFees, uint256 fillPrice) = _computeOrderFees(marketId, sizeDelta, orderPrice);

        return
            AsyncOrder.getRequiredMarginWithNewPosition(
                account,
                marketConfig,
                marketId,
                oldPosition.size,
                oldPosition.size + sizeDelta,
                fillPrice,
                currentInitialMargin
            ) + orderFees;
    }

    function _computeOrderFees(
        uint128 marketId,
        int128 sizeDelta,
        uint256 orderPrice
    ) private view returns (uint256 orderFees, uint256 fillPrice) {
        int256 skew = PerpsMarket.load(marketId).skew;
        PerpsMarketConfiguration.Data storage marketConfig = PerpsMarketConfiguration.load(
            marketId
        );
        fillPrice = AsyncOrder.calculateFillPrice(
            skew,
            marketConfig.skewScale,
            sizeDelta,
            orderPrice
        );

        orderFees = AsyncOrder.calculateOrderFee(
            sizeDelta,
            fillPrice,
            skew,
            marketConfig.orderFees
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import {SafeCastI256, SafeCastU256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {SettlementStrategy} from "./SettlementStrategy.sol";
import {Position} from "./Position.sol";
import {PerpsMarketConfiguration} from "./PerpsMarketConfiguration.sol";
import {PerpsMarket} from "./PerpsMarket.sol";
import {PerpsPrice} from "./PerpsPrice.sol";
import {PerpsAccount} from "./PerpsAccount.sol";
import {MathUtil} from "../utils/MathUtil.sol";
import {OrderFee} from "./OrderFee.sol";
import {KeeperCosts} from "./KeeperCosts.sol";

/**
 * @title Async order top level data storage
 */
library AsyncOrder {
    using DecimalMath for int256;
    using DecimalMath for int128;
    using DecimalMath for uint256;
    using SafeCastI256 for int256;
    using SafeCastU256 for uint256;
    using PerpsMarketConfiguration for PerpsMarketConfiguration.Data;
    using PerpsMarket for PerpsMarket.Data;
    using PerpsAccount for PerpsAccount.Data;
    using KeeperCosts for KeeperCosts.Data;

    /**
     * @notice Thrown when settlement window is not open yet.
     */
    error SettlementWindowNotOpen(uint256 timestamp, uint256 settlementTime);

    /**
     * @notice Thrown when attempting to settle an expired order.
     */
    error SettlementWindowExpired(
        uint256 timestamp,
        uint256 settlementTime,
        uint256 settlementExpiration
    );

    /**
     * @notice Thrown when order does not exist.
     * @dev Order does not exist if the order sizeDelta is 0.
     */
    error OrderNotValid();

    /**
     * @notice Thrown when fill price exceeds the acceptable price set at submission.
     */
    error AcceptablePriceExceeded(uint256 fillPrice, uint256 acceptablePrice);

    /**
     * @notice Gets thrown when attempting to cancel an order and price does not exceeds acceptable price.
     */
    error AcceptablePriceNotExceeded(uint256 fillPrice, uint256 acceptablePrice);

    /**
     * @notice Gets thrown when pending orders exist and attempts to modify collateral.
     */
    error PendingOrderExists();

    /**
     * @notice Thrown when commiting an order with sizeDelta is zero.
     * @dev Size delta 0 is used to flag a non-valid order since it's a non-update order.
     */
    error ZeroSizeOrder();

    /**
     * @notice Thrown when there's not enough margin to cover the order and settlement costs associated.
     */
    error InsufficientMargin(int256 availableMargin, uint256 minMargin);

    struct Data {
        /**
         * @dev Time at which the order was committed.
         */
        uint256 commitmentTime;
        /**
         * @dev Order request details.
         */
        OrderCommitmentRequest request;
    }

    struct OrderCommitmentRequest {
        /**
         * @dev Order market id.
         */
        uint128 marketId;
        /**
         * @dev Order account id.
         */
        uint128 accountId;
        /**
         * @dev Order size delta (of asset units expressed in decimal 18 digits). It can be positive or negative.
         */
        int128 sizeDelta;
        /**
         * @dev Settlement strategy used for the order.
         */
        uint128 settlementStrategyId;
        /**
         * @dev Acceptable price set at submission.
         */
        uint256 acceptablePrice;
        /**
         * @dev An optional code provided by frontends to assist with tracking the source of volume and fees.
         */
        bytes32 trackingCode;
        /**
         * @dev Referrer address to send the referrer fees to.
         */
        address referrer;
    }

    /**
     * @notice Updates the order with the commitment request data and settlement time.
     */
    function load(uint128 accountId) internal pure returns (Data storage order) {
        bytes32 s = keccak256(abi.encode("io.synthetix.perps-market.AsyncOrder", accountId));

        assembly {
            order.slot := s
        }
    }

    /**
     * @dev Reverts if order was not committed by checking the sizeDelta.
     * @dev Reverts if order is not in the settlement window.
     */
    function loadValid(
        uint128 accountId
    ) internal view returns (Data storage order, SettlementStrategy.Data storage strategy) {
        order = load(accountId);
        if (order.request.sizeDelta == 0) {
            revert OrderNotValid();
        }

        strategy = PerpsMarketConfiguration.loadValidSettlementStrategy(
            order.request.marketId,
            order.request.settlementStrategyId
        );
        checkWithinSettlementWindow(order, strategy);
    }

    /**
     * @dev Updates the order with the new commitment request data and settlement time.
     * @dev Reverts if there's a pending order.
     * @dev Reverts if accont cannot open a new position (due to max allowed reached).
     */
    function updateValid(Data storage self, OrderCommitmentRequest memory newRequest) internal {
        checkPendingOrder(newRequest.accountId);

        PerpsAccount.validateMaxPositions(newRequest.accountId, newRequest.marketId);

        // Replace previous (or empty) order with the commitment request
        self.commitmentTime = block.timestamp;
        self.request = newRequest;
    }

    /**
     * @dev Reverts if there is a pending order.
     * @dev A pending order is one that has a sizeDelta and isn't expired yet.
     */
    function checkPendingOrder(uint128 accountId) internal view returns (Data storage order) {
        order = load(accountId);

        if (order.request.sizeDelta != 0) {
            SettlementStrategy.Data storage strategy = PerpsMarketConfiguration
                .load(order.request.marketId)
                .settlementStrategies[order.request.settlementStrategyId];

            if (!expired(order, strategy)) {
                revert PendingOrderExists();
            }
        }
    }

    /**
     * @notice Resets the order.
     * @dev This function is called after the order is settled.
     * @dev Just setting the sizeDelta to 0 is enough, since is the value checked to identify an active order at settlement time.
     * @dev The rest of the fields will be updated on the next commitment. Not doing it here is more gas efficient.
     */
    function reset(Data storage self) internal {
        self.request.sizeDelta = 0;
    }

    /**
     * @notice Checks if the order window settlement is opened and expired.
     * @dev Reverts if block.timestamp is < settlementTime (not <=, so even if the settlementDelay is set to zero, it will require at least 1 second waiting time)
     * @dev Reverts if block.timestamp is > settlementTime + settlementWindowDuration
     */
    function checkWithinSettlementWindow(
        Data storage self,
        SettlementStrategy.Data storage settlementStrategy
    ) internal view {
        uint256 settlementTime = self.commitmentTime + settlementStrategy.settlementDelay;
        uint256 settlementExpiration = settlementTime + settlementStrategy.settlementWindowDuration;

        if (block.timestamp < settlementTime) {
            revert SettlementWindowNotOpen(block.timestamp, settlementTime);
        }

        if (block.timestamp > settlementExpiration) {
            revert SettlementWindowExpired(block.timestamp, settlementTime, settlementExpiration);
        }
    }

    /**
     * @notice Returns if order is expired or not
     */
    function expired(
        Data storage self,
        SettlementStrategy.Data storage settlementStrategy
    ) internal view returns (bool) {
        uint256 settlementExpiration = self.commitmentTime +
            settlementStrategy.settlementDelay +
            settlementStrategy.settlementWindowDuration;
        return block.timestamp > settlementExpiration;
    }

    /**
     * @dev Struct used internally in validateOrder() to prevent stack too deep error.
     */
    struct SimulateDataRuntime {
        bool isEligible;
        int128 sizeDelta;
        uint128 accountId;
        uint128 marketId;
        uint256 fillPrice;
        uint256 orderFees;
        uint256 availableMargin;
        uint256 currentLiquidationMargin;
        uint256 accumulatedLiquidationRewards;
        uint256 currentLiquidationReward;
        int128 newPositionSize;
        uint256 newNotionalValue;
        int256 currentAvailableMargin;
        uint256 requiredInitialMargin;
        uint256 initialRequiredMargin;
        uint256 totalRequiredMargin;
        Position.Data newPosition;
        bytes32 trackingCode;
    }

    /**
     * @notice Checks if the order request can be settled.
     * @dev it recomputes market funding rate, calculates fill price and fees for the order
     * @dev and with that data it checks that:
     * @dev - the account is eligible for liquidation
     * @dev - the fill price is within the acceptable price range
     * @dev - the position size doesn't exceed market configured limits
     * @dev - the account has enough margin to cover for the fees
     * @dev - the account has enough margin to not be liquidable immediately after the order is settled
     * @dev if the order can be executed, it returns (newPosition, orderFees, fillPrice, oldPosition)
     */
    function validateRequest(
        Data storage order,
        SettlementStrategy.Data storage strategy,
        uint256 orderPrice
    ) internal returns (Position.Data memory, uint256, uint256, Position.Data storage oldPosition) {
        SimulateDataRuntime memory runtime;
        runtime.sizeDelta = order.request.sizeDelta;
        runtime.accountId = order.request.accountId;
        runtime.marketId = order.request.marketId;

        if (runtime.sizeDelta == 0) {
            revert ZeroSizeOrder();
        }

        PerpsAccount.Data storage account = PerpsAccount.load(runtime.accountId);

        (
            runtime.isEligible,
            runtime.currentAvailableMargin,
            runtime.requiredInitialMargin,
            ,
            runtime.currentLiquidationReward
        ) = account.isEligibleForLiquidation(PerpsPrice.Tolerance.DEFAULT);

        if (runtime.isEligible) {
            revert PerpsAccount.AccountLiquidatable(runtime.accountId);
        }

        PerpsMarket.Data storage perpsMarketData = PerpsMarket.load(runtime.marketId);
        perpsMarketData.recomputeFunding(orderPrice);

        PerpsMarketConfiguration.Data storage marketConfig = PerpsMarketConfiguration.load(
            runtime.marketId
        );

        runtime.fillPrice = calculateFillPrice(
            perpsMarketData.skew,
            marketConfig.skewScale,
            runtime.sizeDelta,
            orderPrice
        );

        if (acceptablePriceExceeded(order, runtime.fillPrice)) {
            revert AcceptablePriceExceeded(runtime.fillPrice, order.request.acceptablePrice);
        }

        runtime.orderFees =
            calculateOrderFee(
                runtime.sizeDelta,
                runtime.fillPrice,
                perpsMarketData.skew,
                marketConfig.orderFees
            ) +
            settlementRewardCost(strategy);

        oldPosition = PerpsMarket.accountPosition(runtime.marketId, runtime.accountId);
        runtime.newPositionSize = oldPosition.size + runtime.sizeDelta;

        // only account for negative pnl
        runtime.currentAvailableMargin += MathUtil.min(
            calculateStartingPnl(runtime.fillPrice, orderPrice, runtime.newPositionSize),
            0
        );

        if (runtime.currentAvailableMargin < runtime.orderFees.toInt()) {
            revert InsufficientMargin(runtime.currentAvailableMargin, runtime.orderFees);
        }

        PerpsMarket.validatePositionSize(
            perpsMarketData,
            marketConfig.maxMarketSize,
            marketConfig.maxMarketValue,
            orderPrice,
            oldPosition.size,
            runtime.newPositionSize
        );

        runtime.totalRequiredMargin =
            getRequiredMarginWithNewPosition(
                account,
                marketConfig,
                runtime.marketId,
                oldPosition.size,
                runtime.newPositionSize,
                runtime.fillPrice,
                runtime.requiredInitialMargin
            ) +
            runtime.orderFees;

        if (runtime.currentAvailableMargin < runtime.totalRequiredMargin.toInt()) {
            revert InsufficientMargin(runtime.currentAvailableMargin, runtime.totalRequiredMargin);
        }

        runtime.newPosition = Position.Data({
            marketId: runtime.marketId,
            latestInteractionPrice: runtime.fillPrice.to128(),
            latestInteractionFunding: perpsMarketData.lastFundingValue.to128(),
            latestInterestAccrued: 0,
            size: runtime.newPositionSize
        });
        return (runtime.newPosition, runtime.orderFees, runtime.fillPrice, oldPosition);
    }

    /**
     * @notice Checks if the order request can be cancelled.
     * @notice This function doesn't check for liquidation or available margin since the fees to be paid are small and we did that check at commitment less than the settlement window time.
     * @notice it won't check if the order exists since it was already checked when loading the order (loadValid)
     * @dev it calculates fill price the order
     * @dev and with that data it checks that:
     * @dev - settlement window is open
     * @dev - the fill price is outside the acceptable price range
     * @dev if the order can be cancelled, it returns the fillPrice
     */
    function validateCancellation(
        Data storage order,
        SettlementStrategy.Data storage strategy,
        uint256 orderPrice
    ) internal view returns (uint256 fillPrice) {
        checkWithinSettlementWindow(order, strategy);

        PerpsMarket.Data storage perpsMarketData = PerpsMarket.load(order.request.marketId);

        PerpsMarketConfiguration.Data storage marketConfig = PerpsMarketConfiguration.load(
            order.request.marketId
        );

        fillPrice = calculateFillPrice(
            perpsMarketData.skew,
            marketConfig.skewScale,
            order.request.sizeDelta,
            orderPrice
        );

        // check if fill price exceeded acceptable price
        if (!acceptablePriceExceeded(order, fillPrice)) {
            revert AcceptablePriceNotExceeded(fillPrice, order.request.acceptablePrice);
        }
    }

    /**
     * @notice Calculates the settlement rewards.
     */
    function settlementRewardCost(
        SettlementStrategy.Data storage strategy
    ) internal view returns (uint256) {
        return KeeperCosts.load().getSettlementKeeperCosts() + strategy.settlementReward;
    }

    /**
     * @notice Calculates the order fees.
     */
    function calculateOrderFee(
        int128 sizeDelta,
        uint256 fillPrice,
        int256 marketSkew,
        OrderFee.Data storage orderFeeData
    ) internal view returns (uint256) {
        int256 notionalDiff = sizeDelta.mulDecimal(fillPrice.toInt());

        // does this trade keep the skew on one side?
        if (MathUtil.sameSide(marketSkew + sizeDelta, marketSkew)) {
            // use a flat maker/taker fee for the entire size depending on whether the skew is increased or reduced.
            //
            // if the order is submitted on the same side as the skew (increasing it) - the taker fee is charged.
            // otherwise if the order is opposite to the skew, the maker fee is charged.

            uint256 staticRate = MathUtil.sameSide(notionalDiff, marketSkew)
                ? orderFeeData.takerFee
                : orderFeeData.makerFee;
            return MathUtil.abs(notionalDiff.mulDecimal(staticRate.toInt()));
        }

        // this trade flips the skew.
        //
        // the proportion of size that moves in the direction after the flip should not be considered
        // as a maker (reducing skew) as it's now taking (increasing skew) in the opposite direction. hence,
        // a different fee is applied on the proportion increasing the skew.

        // The proportions are computed as follows:
        // makerSize = abs(marketSkew) => since we are reversing the skew, the maker size is the current skew
        // takerSize = abs(marketSkew + sizeDelta) => since we are reversing the skew, the taker size is the new skew
        //
        // we then multiply the sizes by the fill price to get the notional value of each side, and that times the fee rate for each side

        uint256 makerFee = MathUtil.abs(marketSkew).mulDecimal(fillPrice).mulDecimal(
            orderFeeData.makerFee
        );

        uint256 takerFee = MathUtil.abs(marketSkew + sizeDelta).mulDecimal(fillPrice).mulDecimal(
            orderFeeData.takerFee
        );

        return takerFee + makerFee;
    }

    /**
     * @notice Calculates the fill price for an order.
     */
    function calculateFillPrice(
        int256 skew,
        uint256 skewScale,
        int128 size,
        uint256 price
    ) internal pure returns (uint256) {
        // How is the p/d-adjusted price calculated using an example:
        //
        // price      = $1200 USD (oracle)
        // size       = 100
        // skew       = 0
        // skew_scale = 1,000,000 (1M)
        //
        // Then,
        //
        // pd_before = 0 / 1,000,000
        //           = 0
        // pd_after  = (0 + 100) / 1,000,000
        //           = 100 / 1,000,000
        //           = 0.0001
        //
        // price_before = 1200 * (1 + pd_before)
        //              = 1200 * (1 + 0)
        //              = 1200
        // price_after  = 1200 * (1 + pd_after)
        //              = 1200 * (1 + 0.0001)
        //              = 1200 * (1.0001)
        //              = 1200.12
        // Finally,
        //
        // fill_price = (price_before + price_after) / 2
        //            = (1200 + 1200.12) / 2
        //            = 1200.06
        if (skewScale == 0) {
            return price;
        }
        // calculate pd (premium/discount) before and after trade
        int256 pdBefore = skew.divDecimal(skewScale.toInt());
        int256 newSkew = skew + size;
        int256 pdAfter = newSkew.divDecimal(skewScale.toInt());

        // calculate price before and after trade with pd applied
        int256 priceBefore = price.toInt() + (price.toInt().mulDecimal(pdBefore));
        int256 priceAfter = price.toInt() + (price.toInt().mulDecimal(pdAfter));

        // the fill price is the average of those prices
        return (priceBefore + priceAfter).toUint().divDecimal(DecimalMath.UNIT * 2);
    }

    struct RequiredMarginWithNewPositionRuntime {
        uint256 newRequiredMargin;
        uint256 oldRequiredMargin;
        uint256 requiredMarginForNewPosition;
        uint256 accumulatedLiquidationRewards;
        uint256 maxNumberOfWindows;
        uint256 numberOfWindows;
        uint256 requiredRewardMargin;
    }

    /**
     * @notice Initial pnl of a position after it's opened due to p/d fill price delta.
     */
    function calculateStartingPnl(
        uint256 fillPrice,
        uint256 marketPrice,
        int128 size
    ) internal pure returns (int256) {
        return size.mulDecimal(marketPrice.toInt() - fillPrice.toInt());
    }

    /**
     * @notice After the required margins are calculated with the old position, this function replaces the
     * old position initial margin with the new position initial margin requirements and returns them.
     * @dev SIP-359: If the position is being reduced, required margin is 0.
     */
    function getRequiredMarginWithNewPosition(
        PerpsAccount.Data storage account,
        PerpsMarketConfiguration.Data storage marketConfig,
        uint128 marketId,
        int128 oldPositionSize,
        int128 newPositionSize,
        uint256 fillPrice,
        uint256 currentTotalInitialMargin
    ) internal view returns (uint256) {
        RequiredMarginWithNewPositionRuntime memory runtime;

        if (MathUtil.isSameSideReducing(oldPositionSize, newPositionSize)) {
            return 0;
        }

        // get initial margin requirement for the new position
        (, , runtime.newRequiredMargin, ) = marketConfig.calculateRequiredMargins(
            newPositionSize,
            fillPrice
        );

        // get initial margin of old position
        (, , runtime.oldRequiredMargin, ) = marketConfig.calculateRequiredMargins(
            oldPositionSize,
            PerpsPrice.getCurrentPrice(marketId, PerpsPrice.Tolerance.DEFAULT)
        );

        // remove the old initial margin and add the new initial margin requirement
        // this gets us our total required margin for new position
        runtime.requiredMarginForNewPosition =
            currentTotalInitialMargin +
            runtime.newRequiredMargin -
            runtime.oldRequiredMargin;

        (runtime.accumulatedLiquidationRewards, runtime.maxNumberOfWindows) = account
            .getKeeperRewardsAndCosts(marketId);
        runtime.accumulatedLiquidationRewards += marketConfig.calculateFlagReward(
            MathUtil.abs(newPositionSize).mulDecimal(fillPrice)
        );
        runtime.numberOfWindows = marketConfig.numberOfLiquidationWindows(
            MathUtil.abs(newPositionSize)
        );
        runtime.maxNumberOfWindows = MathUtil.max(
            runtime.numberOfWindows,
            runtime.maxNumberOfWindows
        );

        runtime.requiredRewardMargin = account.getPossibleLiquidationReward(
            runtime.accumulatedLiquidationRewards,
            runtime.maxNumberOfWindows
        );

        // this is the required margin for the new position (minus any order fees)
        return runtime.requiredMarginForNewPosition + runtime.requiredRewardMargin;
    }

    /**
     * @notice Checks if the fill price exceeds the acceptable price set at submission.
     */
    function acceptablePriceExceeded(
        Data storage order,
        uint256 fillPrice
    ) internal view returns (bool exceeded) {
        return
            (order.request.sizeDelta > 0 && fillPrice > order.request.acceptablePrice) ||
            (order.request.sizeDelta < 0 && fillPrice < order.request.acceptablePrice);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import {SetUtil} from "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import {MathUtil} from "../utils/MathUtil.sol";
import {GlobalPerpsMarketConfiguration} from "./GlobalPerpsMarketConfiguration.sol";
import {SafeCastU256, SafeCastI256, SafeCastU128} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {Price} from "@synthetixio/spot-market/contracts/storage/Price.sol";
import {PerpsAccount, SNX_USD_MARKET_ID} from "./PerpsAccount.sol";
import {PerpsMarket} from "./PerpsMarket.sol";
import {PerpsMarketFactory} from "./PerpsMarketFactory.sol";
import {ISpotMarketSystem} from "../interfaces/external/ISpotMarketSystem.sol";

/**
 * @title This library contains all global perps market data
 */
library GlobalPerpsMarket {
    using SafeCastI256 for int256;
    using SafeCastU256 for uint256;
    using SafeCastU128 for uint128;
    using DecimalMath for uint256;
    using SetUtil for SetUtil.UintSet;

    bytes32 private constant _SLOT_GLOBAL_PERPS_MARKET =
        keccak256(abi.encode("io.synthetix.perps-market.GlobalPerpsMarket"));

    /**
     * @notice Thrown when attempting to deposit more than enabled collateral.
     */
    error MaxCollateralExceeded(
        uint128 synthMarketId,
        uint256 maxAmount,
        uint256 collateralAmount,
        uint256 depositAmount
    );

    /**
     * @notice Thrown when attempting to use a synth that is not enabled as collateral.
     */
    error SynthNotEnabledForCollateral(uint128 synthMarketId);

    /**
     * @notice Thrown when attempting to withdraw more collateral than is available.
     */
    error InsufficientCollateral(
        uint128 synthMarketId,
        uint256 collateralAmount,
        uint256 withdrawAmount
    );

    struct Data {
        /**
         * @dev Set of liquidatable account ids.
         */
        SetUtil.UintSet liquidatableAccounts;
        /**
         * @dev Collateral amounts running total, by collateral synth market id.
         */
        mapping(uint128 => uint256) collateralAmounts;
        SetUtil.UintSet activeCollateralTypes;
        SetUtil.UintSet activeMarkets;
    }

    function load() internal pure returns (Data storage marketData) {
        bytes32 s = _SLOT_GLOBAL_PERPS_MARKET;
        assembly {
            marketData.slot := s
        }
    }

    function utilizationRate(
        Data storage self
    ) internal view returns (uint128 rate, uint256 delegatedCollateralValue, uint256 lockedCredit) {
        uint256 withdrawableUsd = PerpsMarketFactory.totalWithdrawableUsd();
        int256 delegatedCollateralValueInt = withdrawableUsd.toInt() -
            totalCollateralValue(self).toInt();
        lockedCredit = minimumCredit(self);
        if (delegatedCollateralValueInt <= 0) {
            return (DecimalMath.UNIT_UINT128, 0, lockedCredit);
        }

        delegatedCollateralValue = delegatedCollateralValueInt.toUint();

        rate = lockedCredit.divDecimal(delegatedCollateralValue).to128();
    }

    function minimumCredit(
        Data storage self
    ) internal view returns (uint256 accumulatedMinimumCredit) {
        uint256 activeMarketsLength = self.activeMarkets.length();
        for (uint256 i = 1; i <= activeMarketsLength; i++) {
            uint128 marketId = self.activeMarkets.valueAt(i).to128();

            accumulatedMinimumCredit += PerpsMarket.requiredCredit(marketId);
        }
    }

    function totalCollateralValue(Data storage self) internal view returns (uint256 total) {
        ISpotMarketSystem spotMarket = PerpsMarketFactory.load().spotMarket;
        SetUtil.UintSet storage activeCollateralTypes = self.activeCollateralTypes;
        uint256 activeCollateralLength = activeCollateralTypes.length();
        for (uint256 i = 1; i <= activeCollateralLength; i++) {
            uint128 synthMarketId = activeCollateralTypes.valueAt(i).to128();

            if (synthMarketId == SNX_USD_MARKET_ID) {
                total += self.collateralAmounts[synthMarketId];
            } else {
                (uint256 collateralValue, ) = spotMarket.quoteSellExactIn(
                    synthMarketId,
                    self.collateralAmounts[synthMarketId],
                    Price.Tolerance.DEFAULT
                );
                total += collateralValue;
            }
        }
    }

    function updateCollateralAmount(
        Data storage self,
        uint128 synthMarketId,
        int256 amountDelta
    ) internal returns (uint256 collateralAmount) {
        collateralAmount = (self.collateralAmounts[synthMarketId].toInt() + amountDelta).toUint();
        self.collateralAmounts[synthMarketId] = collateralAmount;

        bool isActiveCollateral = self.activeCollateralTypes.contains(synthMarketId);
        if (collateralAmount > 0 && !isActiveCollateral) {
            self.activeCollateralTypes.add(synthMarketId.to256());
        } else if (collateralAmount == 0 && isActiveCollateral) {
            self.activeCollateralTypes.remove(synthMarketId.to256());
        }
    }

    /**
     * @notice Check if the account is set as liquidatable.
     */
    function checkLiquidation(Data storage self, uint128 accountId) internal view {
        if (self.liquidatableAccounts.contains(accountId)) {
            revert PerpsAccount.AccountLiquidatable(accountId);
        }
    }

    /**
     * @notice Check the collateral is enabled and amount acceptable and adjusts accounting.
     * @dev called when the account is modifying collateral.
     * @dev 1. checks to ensure max cap isn't hit
     * @dev 2. adjusts accounting for collateral amounts
     */
    function validateCollateralAmount(
        Data storage self,
        uint128 synthMarketId,
        int256 synthAmount
    ) internal view {
        uint256 collateralAmount = self.collateralAmounts[synthMarketId];
        if (synthAmount > 0) {
            uint256 maxAmount = GlobalPerpsMarketConfiguration.load().maxCollateralAmounts[
                synthMarketId
            ];
            if (maxAmount == 0) {
                revert SynthNotEnabledForCollateral(synthMarketId);
            }
            uint256 newCollateralAmount = collateralAmount + synthAmount.toUint();
            if (newCollateralAmount > maxAmount) {
                revert MaxCollateralExceeded(
                    synthMarketId,
                    maxAmount,
                    collateralAmount,
                    synthAmount.toUint()
                );
            }
        } else {
            uint256 synthAmountAbs = MathUtil.abs(synthAmount);
            if (collateralAmount < synthAmountAbs) {
                revert InsufficientCollateral(synthMarketId, collateralAmount, synthAmountAbs);
            }
        }
    }

    function addMarket(Data storage self, uint128 marketId) internal {
        self.activeMarkets.add(marketId.to256());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/ERC2771Context.sol";
import {SafeCastU128} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {SetUtil} from "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import {MathUtil} from "../utils/MathUtil.sol";
import {IFeeCollector} from "../interfaces/external/IFeeCollector.sol";
import {PerpsMarketFactory} from "./PerpsMarketFactory.sol";

/**
 * @title This library contains all global perps market configuration data
 */
library GlobalPerpsMarketConfiguration {
    using DecimalMath for uint256;
    using PerpsMarketFactory for PerpsMarketFactory.Data;
    using SetUtil for SetUtil.UintSet;
    using SafeCastU128 for uint128;

    bytes32 private constant _SLOT_GLOBAL_PERPS_MARKET_CONFIGURATION =
        keccak256(abi.encode("io.synthetix.perps-market.GlobalPerpsMarketConfiguration"));

    struct Data {
        /**
         * @dev fee collector contract
         * @dev portion or all of the order fees are sent to fee collector contract based on quote.
         */
        IFeeCollector feeCollector;
        /**
         * @dev Percentage share of fees for each referrer address
         */
        mapping(address => uint256) referrerShare;
        /**
         * @dev mapping of configured synthMarketId to max collateral amount.
         * @dev USD token synth market id = 0
         */
        mapping(uint128 => uint256) maxCollateralAmounts;
        /**
         * @dev when deducting from user's margin which is made up of many synths, this priority governs which synth to sell for deduction
         */
        uint128[] synthDeductionPriority;
        /**
         * @dev minimum configured keeper reward for the sender who liquidates the account
         */
        uint256 minKeeperRewardUsd;
        /**
         * @dev maximum configured keeper reward for the sender who liquidates the account
         */
        uint256 maxKeeperRewardUsd;
        /**
         * @dev maximum configured number of concurrent positions per account.
         * @notice If set to zero it means no new positions can be opened, but existing positions can be increased or decreased.
         * @notice If set to a larger number (larger than number of markets created) it means is unlimited.
         */
        uint128 maxPositionsPerAccount;
        /**
         * @dev maximum configured number of concurrent collaterals per account.
         * @notice If set to zero it means no new collaterals can be added accounts, but existing collaterals can be increased or decreased.
         * @notice If set to a larger number (larger than number of collaterals enabled) it means is unlimited.
         */
        uint128 maxCollateralsPerAccount;
        /**
         * @dev used together with minKeeperRewardUsd to get the minumum keeper reward for the sender who settles, or liquidates the account
         */
        uint256 minKeeperProfitRatioD18;
        /**
         * @dev used together with maxKeeperRewardUsd to get the maximum keeper reward for the sender who settles, or liquidates the account
         */
        uint256 maxKeeperScalingRatioD18;
        /**
         * @dev set of supported collateral types. By supported we mean collateral types that have a maxCollateralAmount > 0
         */
        SetUtil.UintSet supportedCollateralTypes;
        /**
         * @dev interest rate gradient applied to utilization prior to hitting the gradient breakpoint
         */
        uint128 lowUtilizationInterestRateGradient;
        /**
         * @dev breakpoint at which the interest rate gradient changes from low to high
         */
        uint128 interestRateGradientBreakpoint;
        /**
         * @dev interest rate gradient applied to utilization after hitting the gradient breakpoint
         */
        uint128 highUtilizationInterestRateGradient;
    }

    function load() internal pure returns (Data storage globalMarketConfig) {
        bytes32 s = _SLOT_GLOBAL_PERPS_MARKET_CONFIGURATION;
        assembly {
            globalMarketConfig.slot := s
        }
    }

    function loadInterestRateParameters() internal view returns (uint128, uint128, uint128) {
        Data storage self = load();
        return (
            self.lowUtilizationInterestRateGradient,
            self.interestRateGradientBreakpoint,
            self.highUtilizationInterestRateGradient
        );
    }

    function minimumKeeperRewardCap(
        Data storage self,
        uint256 costOfExecutionInUsd
    ) internal view returns (uint256) {
        return
            MathUtil.max(
                costOfExecutionInUsd + self.minKeeperRewardUsd,
                costOfExecutionInUsd.mulDecimal(self.minKeeperProfitRatioD18 + DecimalMath.UNIT)
            );
    }

    function maximumKeeperRewardCap(
        Data storage self,
        uint256 availableMarginInUsd
    ) internal view returns (uint256) {
        // Note: if availableMarginInUsd is zero, it means the account was flagged, so the maximumKeeperRewardCap will just be maxKeeperRewardUsd
        if (availableMarginInUsd == 0) {
            return self.maxKeeperRewardUsd;
        }

        return
            MathUtil.min(
                availableMarginInUsd.mulDecimal(self.maxKeeperScalingRatioD18),
                self.maxKeeperRewardUsd
            );
    }

    /**
     * @dev returns the keeper reward based on total keeper rewards from all markets compared against min/max
     */
    function keeperReward(
        Data storage self,
        uint256 keeperRewards,
        uint256 costOfExecutionInUsd,
        uint256 availableMarginInUsd
    ) internal view returns (uint256) {
        uint256 minCap = minimumKeeperRewardCap(self, costOfExecutionInUsd);
        uint256 maxCap = maximumKeeperRewardCap(self, availableMarginInUsd);
        return MathUtil.min(MathUtil.max(minCap, keeperRewards + costOfExecutionInUsd), maxCap);
    }

    function updateSynthDeductionPriority(
        Data storage self,
        uint128[] memory newSynthDeductionPriority
    ) internal {
        delete self.synthDeductionPriority;

        for (uint256 i = 0; i < newSynthDeductionPriority.length; i++) {
            self.synthDeductionPriority.push(newSynthDeductionPriority[i]);
        }
    }

    function collectFees(
        Data storage self,
        uint256 orderFees,
        address referrer,
        PerpsMarketFactory.Data storage factory
    ) internal returns (uint256 referralFees, uint256 feeCollectorFees) {
        referralFees = _collectReferrerFees(self, orderFees, referrer, factory);
        uint256 remainingFees = orderFees - referralFees;

        if (remainingFees == 0 || self.feeCollector == IFeeCollector(address(0))) {
            return (referralFees, 0);
        }

        uint256 feeCollectorQuote = self.feeCollector.quoteFees(
            factory.perpsMarketId,
            remainingFees,
            ERC2771Context._msgSender()
        );

        if (feeCollectorQuote == 0) {
            return (referralFees, 0);
        }

        if (feeCollectorQuote > remainingFees) {
            feeCollectorQuote = remainingFees;
        }

        factory.withdrawMarketUsd(address(self.feeCollector), feeCollectorQuote);

        return (referralFees, feeCollectorQuote);
    }

    function updateCollateral(
        Data storage self,
        uint128 synthMarketId,
        uint256 maxCollateralAmount
    ) internal {
        self.maxCollateralAmounts[synthMarketId] = maxCollateralAmount;

        bool isSupportedCollateral = self.supportedCollateralTypes.contains(synthMarketId);
        if (maxCollateralAmount > 0 && !isSupportedCollateral) {
            self.supportedCollateralTypes.add(synthMarketId.to256());
        } else if (maxCollateralAmount == 0 && isSupportedCollateral) {
            self.supportedCollateralTypes.remove(synthMarketId.to256());
        }
    }

    function _collectReferrerFees(
        Data storage self,
        uint256 fees,
        address referrer,
        PerpsMarketFactory.Data storage factory
    ) private returns (uint256 referralFeesSent) {
        if (referrer == address(0)) {
            return 0;
        }

        uint256 referrerShareRatio = self.referrerShare[referrer];
        if (referrerShareRatio > 0) {
            referralFeesSent = fees.mulDecimal(referrerShareRatio);
            factory.withdrawMarketUsd(referrer, referralFeesSent);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {SafeCastU256, SafeCastU128, SafeCastI256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import {GlobalPerpsMarket} from "./GlobalPerpsMarket.sol";
import {Position} from "./Position.sol";
import {GlobalPerpsMarketConfiguration} from "../storage/GlobalPerpsMarketConfiguration.sol";

library InterestRate {
    using DecimalMath for uint256;
    using DecimalMath for uint128;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;
    using GlobalPerpsMarket for GlobalPerpsMarket.Data;
    using Position for Position.Data;
    // 4 year average which includes leap
    uint256 private constant AVERAGE_SECONDS_PER_YEAR = 31557600;

    bytes32 private constant _SLOT_INTEREST_RATE =
        keccak256(abi.encode("io.synthetix.perps-market.InterestRate"));

    struct Data {
        uint256 interestAccrued; // per $1 of OI
        uint128 interestRate;
        uint256 lastTimestamp;
    }

    function load() internal pure returns (Data storage interestRate) {
        bytes32 s = _SLOT_INTEREST_RATE;
        assembly {
            interestRate.slot := s
        }
    }

    function update() internal returns (uint128 newInterestRate, uint256 currentInterestAccrued) {
        Data storage self = load();

        (
            uint128 lowUtilizationInterestRateGradient,
            uint128 interestRateGradientBreakpoint,
            uint128 highUtilizationInterestRateGradient
        ) = GlobalPerpsMarketConfiguration.loadInterestRateParameters();

        // if no interest parameters are set, interest rate is 0 and the interest accrued stays the same
        if (
            lowUtilizationInterestRateGradient == 0 &&
            interestRateGradientBreakpoint == 0 &&
            highUtilizationInterestRateGradient == 0
        ) {
            self.interestRate = 0;
            return (0, self.interestAccrued);
        }

        (uint128 currentUtilizationRate, , ) = GlobalPerpsMarket.load().utilizationRate();

        self.interestAccrued = calculateNextInterest(self);

        self.interestRate = currentInterestRate(
            currentUtilizationRate,
            lowUtilizationInterestRateGradient,
            interestRateGradientBreakpoint,
            highUtilizationInterestRateGradient
        );
        self.lastTimestamp = block.timestamp;

        return (self.interestRate, self.interestAccrued);
    }

    function proportionalElapsed(Data storage self) internal view returns (uint128) {
        // even though timestamps here are not D18, divDecimal multiplies by 1e18 to preserve decimals into D18
        return (block.timestamp - self.lastTimestamp).divDecimal(AVERAGE_SECONDS_PER_YEAR).to128();
    }

    function calculateNextInterest(Data storage self) internal view returns (uint256) {
        return self.interestAccrued + unrecordedInterest(self);
    }

    function unrecordedInterest(Data storage self) internal view returns (uint256) {
        return self.interestRate.mulDecimalUint128(proportionalElapsed(self)).to256();
    }

    function currentInterestRate(
        uint128 currentUtilizationRate,
        uint128 lowUtilizationInterestRateGradient,
        uint128 interestRateGradientBreakpoint,
        uint128 highUtilizationInterestRateGradient
    ) internal pure returns (uint128 rate) {
        // if utilization rate is below breakpoint, multiply low utilization * # of percentage points of utilizationRate
        // otherwise multiply low utilization until breakpoint, then use high utilization gradient for the rest
        if (currentUtilizationRate < interestRateGradientBreakpoint) {
            rate =
                lowUtilizationInterestRateGradient.mulDecimalUint128(currentUtilizationRate) *
                100;
        } else {
            uint128 highUtilizationRate = currentUtilizationRate - interestRateGradientBreakpoint;
            uint128 highUtilizationRateInterest = highUtilizationInterestRateGradient
                .mulDecimalUint128(highUtilizationRate) * 100;
            uint128 lowUtilizationRateInterest = lowUtilizationInterestRateGradient
                .mulDecimalUint128(interestRateGradientBreakpoint) * 100;
            rate = highUtilizationRateInterest + lowUtilizationRateInterest;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {SafeCastI256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {SetUtil} from "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import {INodeModule} from "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";
import {PerpsMarketFactory} from "./PerpsMarketFactory.sol";
import {PerpsAccount} from "./PerpsAccount.sol";
import {PerpsMarketConfiguration} from "./PerpsMarketConfiguration.sol";

uint128 constant SNX_USD_MARKET_ID = 0;

/**
 * @title Keeper txn execution costs for rewards calculation based on gas price
 */
library KeeperCosts {
    using SafeCastI256 for int256;
    using SetUtil for SetUtil.UintSet;
    using PerpsAccount for PerpsAccount.Data;
    using PerpsMarketConfiguration for PerpsMarketConfiguration.Data;

    uint256 private constant KIND_SETTLEMENT = 0;
    uint256 private constant KIND_FLAG = 1;
    uint256 private constant KIND_LIQUIDATE = 2;

    struct Data {
        bytes32 keeperCostNodeId;
    }

    function load() internal pure returns (Data storage price) {
        bytes32 s = keccak256(abi.encode("io.synthetix.perps-market.KeeperCosts"));
        assembly {
            price.slot := s
        }
    }

    function update(Data storage self, bytes32 keeperCostNodeId) internal {
        self.keeperCostNodeId = keeperCostNodeId;
    }

    function getSettlementKeeperCosts(Data storage self) internal view returns (uint256 sUSDCost) {
        PerpsMarketFactory.Data storage factory = PerpsMarketFactory.load();

        sUSDCost = _processWithRuntime(self.keeperCostNodeId, factory, 0, KIND_SETTLEMENT);
    }

    function getFlagKeeperCosts(
        Data storage self,
        uint128 accountId
    ) internal view returns (uint256 sUSDCost) {
        PerpsMarketFactory.Data storage factory = PerpsMarketFactory.load();

        PerpsAccount.Data storage account = PerpsAccount.load(accountId);
        uint256 numberOfCollateralFeeds = account.activeCollateralTypes.contains(SNX_USD_MARKET_ID)
            ? account.activeCollateralTypes.length() - 1
            : account.activeCollateralTypes.length();
        uint256 numberOfUpdatedFeeds = numberOfCollateralFeeds +
            account.openPositionMarketIds.length();

        sUSDCost = _processWithRuntime(
            self.keeperCostNodeId,
            factory,
            numberOfUpdatedFeeds,
            KIND_FLAG
        );
    }

    function getLiquidateKeeperCosts(Data storage self) internal view returns (uint256 sUSDCost) {
        PerpsMarketFactory.Data storage factory = PerpsMarketFactory.load();

        sUSDCost = _processWithRuntime(self.keeperCostNodeId, factory, 0, KIND_LIQUIDATE);
    }

    function _processWithRuntime(
        bytes32 keeperCostNodeId,
        PerpsMarketFactory.Data storage factory,
        uint256 numberOfUpdatedFeeds,
        uint256 executionKind
    ) private view returns (uint256 sUSDCost) {
        bytes32[] memory runtimeKeys = new bytes32[](4);
        bytes32[] memory runtimeValues = new bytes32[](4);
        runtimeKeys[0] = bytes32("numberOfUpdatedFeeds");
        runtimeKeys[1] = bytes32("executionKind");
        runtimeValues[0] = bytes32(numberOfUpdatedFeeds);
        runtimeValues[1] = bytes32(executionKind);

        sUSDCost = INodeModule(factory.oracle)
            .processWithRuntime(keeperCostNodeId, runtimeKeys, runtimeValues)
            .price
            .toUint();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Liquidation data used for determining max liquidation amounts
 */
library Liquidation {
    struct Data {
        /**
         * @dev Accumulated amount for this corresponding timestamp
         */
        uint128 amount;
        /**
         * @dev timestamp of the accumulated liqudation amount
         */
        uint256 timestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title MarketUpdateData
 */
library MarketUpdate {
    // this data struct returns the data required to emit a MarketUpdated event
    struct Data {
        uint128 marketId;
        uint128 interestRate;
        int256 skew;
        uint256 size;
        int256 currentFundingRate;
        int256 currentFundingVelocity;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Orders Fee data
 */
library OrderFee {
    struct Data {
        /**
         * @dev Maker fee. Applied when order (or partial order) is reducing skew.
         */
        uint256 makerFee;
        /**
         * @dev Taker fee. Applied when order (or partial order) is increasing skew.
         */
        uint256 takerFee;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {Price} from "@synthetixio/spot-market/contracts/storage/Price.sol";
import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import {SafeCastI256, SafeCastU256, SafeCastU128} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {SetUtil} from "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import {ISpotMarketSystem} from "../interfaces/external/ISpotMarketSystem.sol";
import {Position} from "./Position.sol";
import {PerpsMarket} from "./PerpsMarket.sol";
import {MathUtil} from "../utils/MathUtil.sol";
import {PerpsPrice} from "./PerpsPrice.sol";
import {MarketUpdate} from "./MarketUpdate.sol";
import {PerpsMarketFactory} from "./PerpsMarketFactory.sol";
import {GlobalPerpsMarket} from "./GlobalPerpsMarket.sol";
import {InterestRate} from "./InterestRate.sol";
import {GlobalPerpsMarketConfiguration} from "./GlobalPerpsMarketConfiguration.sol";
import {PerpsMarketConfiguration} from "./PerpsMarketConfiguration.sol";
import {KeeperCosts} from "../storage/KeeperCosts.sol";
import {AsyncOrder} from "../storage/AsyncOrder.sol";

uint128 constant SNX_USD_MARKET_ID = 0;

/**
 * @title Data for a single perps market
 */
library PerpsAccount {
    using SetUtil for SetUtil.UintSet;
    using SafeCastI256 for int256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using Position for Position.Data;
    using PerpsPrice for PerpsPrice.Data;
    using PerpsMarket for PerpsMarket.Data;
    using PerpsMarketConfiguration for PerpsMarketConfiguration.Data;
    using PerpsMarketFactory for PerpsMarketFactory.Data;
    using GlobalPerpsMarket for GlobalPerpsMarket.Data;
    using GlobalPerpsMarketConfiguration for GlobalPerpsMarketConfiguration.Data;
    using DecimalMath for int256;
    using DecimalMath for uint256;
    using KeeperCosts for KeeperCosts.Data;
    using AsyncOrder for AsyncOrder.Data;

    struct Data {
        // @dev synth marketId => amount
        mapping(uint128 => uint256) collateralAmounts;
        // @dev account Id
        uint128 id;
        // @dev set of active collateral types. By active we mean collateral types that have a non-zero amount
        SetUtil.UintSet activeCollateralTypes;
        // @dev set of open position market ids
        SetUtil.UintSet openPositionMarketIds;
    }

    error InsufficientCollateralAvailableForWithdraw(
        uint256 availableUsdDenominated,
        uint256 requiredUsdDenominated
    );

    error InsufficientSynthCollateral(
        uint128 synthMarketId,
        uint256 collateralAmount,
        uint256 withdrawAmount
    );

    error InsufficientAccountMargin(uint256 leftover);

    error AccountLiquidatable(uint128 accountId);

    error MaxPositionsPerAccountReached(uint128 maxPositionsPerAccount);

    error MaxCollateralsPerAccountReached(uint128 maxCollateralsPerAccount);

    function load(uint128 id) internal pure returns (Data storage account) {
        bytes32 s = keccak256(abi.encode("io.synthetix.perps-market.Account", id));

        assembly {
            account.slot := s
        }
    }

    /**
        @notice allows us to update the account id in case it needs to be
     */
    function create(uint128 id) internal returns (Data storage account) {
        account = load(id);
        if (account.id == 0) {
            account.id = id;
        }
    }

    function validateMaxPositions(uint128 accountId, uint128 marketId) internal view {
        if (PerpsMarket.accountPosition(marketId, accountId).size == 0) {
            uint128 maxPositionsPerAccount = GlobalPerpsMarketConfiguration
                .load()
                .maxPositionsPerAccount;
            if (maxPositionsPerAccount <= load(accountId).openPositionMarketIds.length()) {
                revert MaxPositionsPerAccountReached(maxPositionsPerAccount);
            }
        }
    }

    function validateMaxCollaterals(uint128 accountId, uint128 synthMarketId) internal view {
        Data storage account = load(accountId);

        if (account.collateralAmounts[synthMarketId] == 0) {
            uint128 maxCollateralsPerAccount = GlobalPerpsMarketConfiguration
                .load()
                .maxCollateralsPerAccount;
            if (maxCollateralsPerAccount <= account.activeCollateralTypes.length()) {
                revert MaxCollateralsPerAccountReached(maxCollateralsPerAccount);
            }
        }
    }

    function isEligibleForLiquidation(
        Data storage self,
        PerpsPrice.Tolerance stalenessTolerance
    )
        internal
        view
        returns (
            bool isEligible,
            int256 availableMargin,
            uint256 requiredInitialMargin,
            uint256 requiredMaintenanceMargin,
            uint256 liquidationReward
        )
    {
        availableMargin = getAvailableMargin(self, stalenessTolerance);

        (
            requiredInitialMargin,
            requiredMaintenanceMargin,
            liquidationReward
        ) = getAccountRequiredMargins(self, stalenessTolerance);
        isEligible = (requiredMaintenanceMargin + liquidationReward).toInt() > availableMargin;
    }

    function flagForLiquidation(
        Data storage self
    ) internal returns (uint256 flagKeeperCost, uint256 marginCollected) {
        SetUtil.UintSet storage liquidatableAccounts = GlobalPerpsMarket
            .load()
            .liquidatableAccounts;

        if (!liquidatableAccounts.contains(self.id)) {
            flagKeeperCost = KeeperCosts.load().getFlagKeeperCosts(self.id);
            liquidatableAccounts.add(self.id);
            marginCollected = convertAllCollateralToUsd(self);
            AsyncOrder.load(self.id).reset();
        }
    }

    function updateOpenPositions(
        Data storage self,
        uint256 positionMarketId,
        int256 size
    ) internal {
        if (size == 0 && self.openPositionMarketIds.contains(positionMarketId)) {
            self.openPositionMarketIds.remove(positionMarketId);
        } else if (!self.openPositionMarketIds.contains(positionMarketId)) {
            self.openPositionMarketIds.add(positionMarketId);
        }
    }

    function updateCollateralAmount(
        Data storage self,
        uint128 synthMarketId,
        int256 amountDelta
    ) internal returns (uint256 collateralAmount) {
        collateralAmount = (self.collateralAmounts[synthMarketId].toInt() + amountDelta).toUint();
        self.collateralAmounts[synthMarketId] = collateralAmount;

        bool isActiveCollateral = self.activeCollateralTypes.contains(synthMarketId);
        if (collateralAmount > 0 && !isActiveCollateral) {
            self.activeCollateralTypes.add(synthMarketId);
        } else if (collateralAmount == 0 && isActiveCollateral) {
            self.activeCollateralTypes.remove(synthMarketId);
        }

        // always update global values when account collateral is changed
        GlobalPerpsMarket.load().updateCollateralAmount(synthMarketId, amountDelta);
    }

    /**
     * @notice This function validates you have enough margin to withdraw without being liquidated.
     * @dev    This is done by checking your collateral value against your initial maintenance value.
     * @dev    It also checks the synth collateral for this account is enough to cover the withdrawal amount.
     * @dev    All price checks are not checking strict staleness tolerance.
     */
    function validateWithdrawableAmount(
        Data storage self,
        uint128 synthMarketId,
        uint256 amountToWithdraw,
        ISpotMarketSystem spotMarket
    ) internal view returns (uint256 availableWithdrawableCollateralUsd) {
        uint256 collateralAmount = self.collateralAmounts[synthMarketId];
        if (collateralAmount < amountToWithdraw) {
            revert InsufficientSynthCollateral(synthMarketId, collateralAmount, amountToWithdraw);
        }

        (
            bool isEligible,
            int256 availableMargin,
            uint256 initialRequiredMargin,
            ,
            uint256 liquidationReward
        ) = isEligibleForLiquidation(self, PerpsPrice.Tolerance.STRICT);

        if (isEligible) {
            revert AccountLiquidatable(self.id);
        }

        uint256 requiredMargin = initialRequiredMargin + liquidationReward;
        // availableMargin can be assumed to be positive since we check for isEligible for liquidation prior
        availableWithdrawableCollateralUsd = availableMargin.toUint() - requiredMargin;

        uint256 amountToWithdrawUsd;
        if (synthMarketId == SNX_USD_MARKET_ID) {
            amountToWithdrawUsd = amountToWithdraw;
        } else {
            (amountToWithdrawUsd, ) = spotMarket.quoteSellExactIn(
                synthMarketId,
                amountToWithdraw,
                Price.Tolerance.DEFAULT
            );
        }

        if (amountToWithdrawUsd > availableWithdrawableCollateralUsd) {
            revert InsufficientCollateralAvailableForWithdraw(
                availableWithdrawableCollateralUsd,
                amountToWithdrawUsd
            );
        }
    }

    function getTotalCollateralValue(
        Data storage self,
        PerpsPrice.Tolerance stalenessTolerance
    ) internal view returns (uint256) {
        uint256 totalCollateralValue;
        ISpotMarketSystem spotMarket = PerpsMarketFactory.load().spotMarket;
        for (uint256 i = 1; i <= self.activeCollateralTypes.length(); i++) {
            uint128 synthMarketId = self.activeCollateralTypes.valueAt(i).to128();
            uint256 amount = self.collateralAmounts[synthMarketId];

            uint256 amountToAdd;
            if (synthMarketId == SNX_USD_MARKET_ID) {
                amountToAdd = amount;
            } else {
                (amountToAdd, ) = spotMarket.quoteSellExactIn(
                    synthMarketId,
                    amount,
                    Price.Tolerance(uint256(stalenessTolerance)) // solhint-disable-line numcast/safe-cast
                );
            }
            totalCollateralValue += amountToAdd;
        }
        return totalCollateralValue;
    }

    function getAccountPnl(
        Data storage self,
        PerpsPrice.Tolerance stalenessTolerance
    ) internal view returns (int256 totalPnl) {
        for (uint256 i = 1; i <= self.openPositionMarketIds.length(); i++) {
            uint128 marketId = self.openPositionMarketIds.valueAt(i).to128();
            Position.Data storage position = PerpsMarket.load(marketId).positions[self.id];
            (int256 pnl, , , , , ) = position.getPnl(
                PerpsPrice.getCurrentPrice(marketId, stalenessTolerance)
            );
            totalPnl += pnl;
        }
    }

    function getAvailableMargin(
        Data storage self,
        PerpsPrice.Tolerance stalenessTolerance
    ) internal view returns (int256) {
        int256 totalCollateralValue = getTotalCollateralValue(self, stalenessTolerance).toInt();
        int256 accountPnl = getAccountPnl(self, stalenessTolerance);

        return totalCollateralValue + accountPnl;
    }

    function getTotalNotionalOpenInterest(
        Data storage self
    ) internal view returns (uint256 totalAccountOpenInterest) {
        for (uint256 i = 1; i <= self.openPositionMarketIds.length(); i++) {
            uint128 marketId = self.openPositionMarketIds.valueAt(i).to128();

            Position.Data storage position = PerpsMarket.load(marketId).positions[self.id];
            uint256 openInterest = position.getNotionalValue(
                PerpsPrice.getCurrentPrice(marketId, PerpsPrice.Tolerance.DEFAULT)
            );
            totalAccountOpenInterest += openInterest;
        }
    }

    /**
     * @notice  This function returns the required margins for an account
     * @dev The initial required margin is used to determine withdrawal amount and when opening positions
     * @dev The maintenance margin is used to determine when to liquidate a position
     */
    function getAccountRequiredMargins(
        Data storage self,
        PerpsPrice.Tolerance stalenessTolerance
    )
        internal
        view
        returns (
            uint256 initialMargin,
            uint256 maintenanceMargin,
            uint256 possibleLiquidationReward
        )
    {
        uint256 openPositionMarketIdsLength = self.openPositionMarketIds.length();
        if (openPositionMarketIdsLength == 0) {
            return (0, 0, 0);
        }

        // use separate accounting for liquidation rewards so we can compare against global min/max liquidation reward values
        for (uint256 i = 1; i <= openPositionMarketIdsLength; i++) {
            uint128 marketId = self.openPositionMarketIds.valueAt(i).to128();
            Position.Data storage position = PerpsMarket.load(marketId).positions[self.id];
            PerpsMarketConfiguration.Data storage marketConfig = PerpsMarketConfiguration.load(
                marketId
            );
            (, , uint256 positionInitialMargin, uint256 positionMaintenanceMargin) = marketConfig
                .calculateRequiredMargins(
                    position.size,
                    PerpsPrice.getCurrentPrice(marketId, stalenessTolerance)
                );

            maintenanceMargin += positionMaintenanceMargin;
            initialMargin += positionInitialMargin;
        }

        (
            uint256 accumulatedLiquidationRewards,
            uint256 maxNumberOfWindows
        ) = getKeeperRewardsAndCosts(self, 0);
        possibleLiquidationReward = getPossibleLiquidationReward(
            self,
            accumulatedLiquidationRewards,
            maxNumberOfWindows
        );

        return (initialMargin, maintenanceMargin, possibleLiquidationReward);
    }

    function getKeeperRewardsAndCosts(
        Data storage self,
        uint128 skipMarketId
    ) internal view returns (uint256 accumulatedLiquidationRewards, uint256 maxNumberOfWindows) {
        // use separate accounting for liquidation rewards so we can compare against global min/max liquidation reward values
        for (uint256 i = 1; i <= self.openPositionMarketIds.length(); i++) {
            uint128 marketId = self.openPositionMarketIds.valueAt(i).to128();
            if (marketId == skipMarketId) continue;
            Position.Data storage position = PerpsMarket.load(marketId).positions[self.id];
            PerpsMarketConfiguration.Data storage marketConfig = PerpsMarketConfiguration.load(
                marketId
            );

            uint256 numberOfWindows = marketConfig.numberOfLiquidationWindows(
                MathUtil.abs(position.size)
            );

            uint256 flagReward = marketConfig.calculateFlagReward(
                MathUtil.abs(position.size).mulDecimal(
                    PerpsPrice.getCurrentPrice(marketId, PerpsPrice.Tolerance.DEFAULT)
                )
            );
            accumulatedLiquidationRewards += flagReward;

            maxNumberOfWindows = MathUtil.max(numberOfWindows, maxNumberOfWindows);
        }
    }

    function getPossibleLiquidationReward(
        Data storage self,
        uint256 accumulatedLiquidationRewards,
        uint256 numOfWindows
    ) internal view returns (uint256 possibleLiquidationReward) {
        GlobalPerpsMarketConfiguration.Data storage globalConfig = GlobalPerpsMarketConfiguration
            .load();
        KeeperCosts.Data storage keeperCosts = KeeperCosts.load();
        uint256 costOfFlagging = keeperCosts.getFlagKeeperCosts(self.id);
        uint256 costOfLiquidation = keeperCosts.getLiquidateKeeperCosts();
        uint256 liquidateAndFlagCost = globalConfig.keeperReward(
            accumulatedLiquidationRewards,
            costOfFlagging,
            getTotalCollateralValue(self, PerpsPrice.Tolerance.DEFAULT)
        );
        uint256 liquidateWindowsCosts = numOfWindows == 0
            ? 0
            : globalConfig.keeperReward(0, costOfLiquidation, 0) * (numOfWindows - 1);

        possibleLiquidationReward = liquidateAndFlagCost + liquidateWindowsCosts;
    }

    function convertAllCollateralToUsd(
        Data storage self
    ) internal returns (uint256 totalConvertedCollateral) {
        PerpsMarketFactory.Data storage factory = PerpsMarketFactory.load();
        uint256[] memory activeCollateralTypes = self.activeCollateralTypes.values();

        // 1. withdraw all collateral from synthetix
        // 2. sell all collateral for snxUSD
        // 3. deposit snxUSD into synthetix
        for (uint256 i = 0; i < activeCollateralTypes.length; i++) {
            uint128 synthMarketId = activeCollateralTypes[i].to128();
            if (synthMarketId == SNX_USD_MARKET_ID) {
                totalConvertedCollateral += self.collateralAmounts[synthMarketId];
                updateCollateralAmount(
                    self,
                    synthMarketId,
                    -(self.collateralAmounts[synthMarketId].toInt())
                );
            } else {
                totalConvertedCollateral += _deductAllSynth(self, factory, synthMarketId);
            }
        }
    }

    /**
     * @notice  This function deducts snxUSD from an account
     * @dev It uses the synth deduction priority to determine which synth to deduct from first
     * @dev if the synth is not snxUSD it will sell the synth for snxUSD
     * @dev Returns two arrays with the synth ids and amounts deducted
     */
    function deductFromAccount(
        Data storage self,
        uint256 amount // snxUSD
    ) internal returns (uint128[] memory deductedSynthIds, uint256[] memory deductedAmount) {
        uint256 leftoverAmount = amount;
        uint128[] storage synthDeductionPriority = GlobalPerpsMarketConfiguration
            .load()
            .synthDeductionPriority;
        PerpsMarketFactory.Data storage factory = PerpsMarketFactory.load();
        ISpotMarketSystem spotMarket = factory.spotMarket;

        deductedSynthIds = new uint128[](synthDeductionPriority.length);
        deductedAmount = new uint256[](synthDeductionPriority.length);

        for (uint256 i = 0; i < synthDeductionPriority.length; i++) {
            uint128 synthMarketId = synthDeductionPriority[i];
            uint256 availableAmount = self.collateralAmounts[synthMarketId];
            if (availableAmount == 0) {
                continue;
            }
            deductedSynthIds[i] = synthMarketId;

            if (synthMarketId == SNX_USD_MARKET_ID) {
                // snxUSD
                if (availableAmount >= leftoverAmount) {
                    deductedAmount[i] = leftoverAmount;
                    updateCollateralAmount(self, synthMarketId, -(leftoverAmount.toInt()));
                    leftoverAmount = 0;
                    break;
                } else {
                    deductedAmount[i] = availableAmount;
                    updateCollateralAmount(self, synthMarketId, -(availableAmount.toInt()));
                    leftoverAmount -= availableAmount;
                }
            } else {
                (uint256 synthAmountRequired, ) = spotMarket.quoteSellExactOut(
                    synthMarketId,
                    leftoverAmount,
                    Price.Tolerance.STRICT
                );

                address synthToken = factory.spotMarket.getSynth(synthMarketId);

                if (availableAmount >= synthAmountRequired) {
                    factory.synthetix.withdrawMarketCollateral(
                        factory.perpsMarketId,
                        synthToken,
                        synthAmountRequired
                    );

                    (uint256 amountToDeduct, ) = spotMarket.sellExactOut(
                        synthMarketId,
                        leftoverAmount,
                        type(uint256).max,
                        address(0)
                    );

                    factory.depositMarketUsd(leftoverAmount);

                    deductedAmount[i] = amountToDeduct;
                    updateCollateralAmount(self, synthMarketId, -(amountToDeduct.toInt()));
                    leftoverAmount = 0;
                    break;
                } else {
                    factory.synthetix.withdrawMarketCollateral(
                        factory.perpsMarketId,
                        synthToken,
                        availableAmount
                    );

                    (uint256 amountToDeductUsd, ) = spotMarket.sellExactIn(
                        synthMarketId,
                        availableAmount,
                        0,
                        address(0)
                    );

                    factory.depositMarketUsd(amountToDeductUsd);

                    deductedAmount[i] = availableAmount;
                    updateCollateralAmount(self, synthMarketId, -(availableAmount.toInt()));
                    leftoverAmount -= amountToDeductUsd;
                }
            }
        }

        if (leftoverAmount > 0) {
            revert InsufficientAccountMargin(leftoverAmount);
        }
    }

    function liquidatePosition(
        Data storage self,
        uint128 marketId,
        uint256 price
    )
        internal
        returns (
            uint128 amountToLiquidate,
            int128 newPositionSize,
            int128 sizeDelta,
            uint128 oldPositionAbsSize,
            MarketUpdate.Data memory marketUpdateData
        )
    {
        PerpsMarket.Data storage perpsMarket = PerpsMarket.load(marketId);
        Position.Data storage position = perpsMarket.positions[self.id];

        perpsMarket.recomputeFunding(price);

        int128 oldPositionSize = position.size;
        oldPositionAbsSize = MathUtil.abs128(oldPositionSize);
        amountToLiquidate = perpsMarket.maxLiquidatableAmount(oldPositionAbsSize);

        if (amountToLiquidate == 0) {
            return (0, oldPositionSize, 0, oldPositionAbsSize, marketUpdateData);
        }

        int128 amtToLiquidationInt = amountToLiquidate.toInt();
        // reduce position size
        newPositionSize = oldPositionSize > 0
            ? oldPositionSize - amtToLiquidationInt
            : oldPositionSize + amtToLiquidationInt;

        // create new position in case of partial liquidation
        Position.Data memory newPosition;
        if (newPositionSize != 0) {
            newPosition = Position.Data({
                marketId: marketId,
                latestInteractionPrice: price.to128(),
                latestInteractionFunding: perpsMarket.lastFundingValue.to128(),
                latestInterestAccrued: 0,
                size: newPositionSize
            });
        }

        // update position markets
        updateOpenPositions(self, marketId, newPositionSize);

        // update market data
        marketUpdateData = perpsMarket.updatePositionData(self.id, newPosition);
        sizeDelta = newPositionSize - oldPositionSize;

        return (
            amountToLiquidate,
            newPositionSize,
            sizeDelta,
            oldPositionAbsSize,
            marketUpdateData
        );
    }

    function _deductAllSynth(
        Data storage self,
        PerpsMarketFactory.Data storage factory,
        uint128 synthMarketId
    ) private returns (uint256 amountUsd) {
        uint256 amount = self.collateralAmounts[synthMarketId];
        address synth = factory.spotMarket.getSynth(synthMarketId);

        // 1. withdraw collateral from market manager
        factory.synthetix.withdrawMarketCollateral(factory.perpsMarketId, synth, amount);

        // 2. sell collateral for snxUSD
        (amountUsd, ) = PerpsMarketFactory.load().spotMarket.sellExactIn(
            synthMarketId,
            amount,
            0,
            address(0)
        );

        // 3. deposit snxUSD into market manager
        factory.depositMarketUsd(amountUsd);

        // 4. update account collateral amount
        updateCollateralAmount(self, synthMarketId, -(amount.toInt()));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {ERC2771Context} from "@synthetixio/core-contracts/contracts/utils/ERC2771Context.sol";
import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import {SafeCastU256, SafeCastI256, SafeCastU128} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {Position} from "./Position.sol";
import {AsyncOrder} from "./AsyncOrder.sol";
import {PerpsMarketConfiguration} from "./PerpsMarketConfiguration.sol";
import {MarketUpdate} from "./MarketUpdate.sol";
import {MathUtil} from "../utils/MathUtil.sol";
import {PerpsPrice} from "./PerpsPrice.sol";
import {Liquidation} from "./Liquidation.sol";
import {KeeperCosts} from "./KeeperCosts.sol";
import {InterestRate} from "./InterestRate.sol";

/**
 * @title Data for a single perps market
 */
library PerpsMarket {
    using DecimalMath for int256;
    using DecimalMath for uint256;
    using SafeCastI256 for int256;
    using SafeCastU256 for uint256;
    using SafeCastU128 for uint128;
    using Position for Position.Data;
    using PerpsMarketConfiguration for PerpsMarketConfiguration.Data;

    /**
     * @notice Thrown when attempting to create a market that already exists or invalid id was passed in
     */
    error InvalidMarket(uint128 marketId);

    /**
     * @notice Thrown when attempting to load a market without a configured price feed
     */
    error PriceFeedNotSet(uint128 marketId);

    /**
     * @notice Thrown when attempting to load a market without a configured keeper costs
     */
    error KeeperCostsNotSet();

    struct Data {
        string name;
        string symbol;
        uint128 id;
        int256 skew;
        uint256 size;
        int256 lastFundingRate;
        int256 lastFundingValue;
        uint256 lastFundingTime;
        // solhint-disable-next-line var-name-mixedcase
        uint128 __unused_1;
        // solhint-disable-next-line var-name-mixedcase
        uint128 __unused_2;
        // debt calculation
        // accumulates total notional size of the market including accrued funding until the last time any position changed
        int256 debtCorrectionAccumulator;
        // accountId => asyncOrder
        mapping(uint256 => AsyncOrder.Data) asyncOrders;
        // accountId => position
        mapping(uint256 => Position.Data) positions;
        // liquidation amounts
        Liquidation.Data[] liquidationData;
    }

    function load(uint128 marketId) internal pure returns (Data storage market) {
        bytes32 s = keccak256(abi.encode("io.synthetix.perps-market.PerpsMarket", marketId));

        assembly {
            market.slot := s
        }
    }

    function createValid(
        uint128 id,
        string memory name,
        string memory symbol
    ) internal returns (Data storage market) {
        if (id == 0 || load(id).id == id) {
            revert InvalidMarket(id);
        }

        market = load(id);

        market.id = id;
        market.name = name;
        market.symbol = symbol;
    }

    /**
     * @dev Reverts if the market does not exist with appropriate error. Otherwise, returns the market.
     */
    function loadValid(uint128 marketId) internal view returns (Data storage market) {
        market = load(marketId);
        if (market.id == 0) {
            revert InvalidMarket(marketId);
        }

        if (PerpsPrice.load(marketId).feedId == "") {
            revert PriceFeedNotSet(marketId);
        }

        if (KeeperCosts.load().keeperCostNodeId == "") {
            revert KeeperCostsNotSet();
        }
    }

    /**
     * @dev Returns the max amount of liquidation that can occur based on the market configuration
     * @notice Based on the configured liquidation window, a trader can only be liquidated for a certain
     *   amount within that window.  If the amount requested is greater than the amount allowed, the
     *   smaller amount is returned.  The function also updates its accounting to ensure the results on
     *   subsequent liquidations work appropriately.
     */
    function maxLiquidatableAmount(
        Data storage self,
        uint128 requestedLiquidationAmount
    ) internal returns (uint128 liquidatableAmount) {
        PerpsMarketConfiguration.Data storage marketConfig = PerpsMarketConfiguration.load(self.id);

        // if endorsedLiquidator is configured and is the sender, allow full liquidation
        if (ERC2771Context._msgSender() == marketConfig.endorsedLiquidator) {
            _updateLiquidationData(self, requestedLiquidationAmount);
            return requestedLiquidationAmount;
        }

        (
            uint256 liquidationCapacity,
            uint256 maxLiquidationInWindow,
            uint256 latestLiquidationTimestamp
        ) = currentLiquidationCapacity(self, marketConfig);

        // this would only occur if there was a misconfiguration (like skew scale not being set)
        // or the max liquidation window not being set etc.
        // in this case, return the entire requested liquidation amount
        if (maxLiquidationInWindow == 0) {
            return requestedLiquidationAmount;
        }

        uint256 maxLiquidationPd = marketConfig.maxLiquidationPd;
        // if liquidation capacity exists, update accordingly
        if (liquidationCapacity != 0) {
            liquidatableAmount = MathUtil.min128(
                liquidationCapacity.to128(),
                requestedLiquidationAmount
            );
        } else if (
            maxLiquidationPd != 0 &&
            // only allow this if the last update was not in the current block
            latestLiquidationTimestamp != block.timestamp
        ) {
            /**
                if capacity is at 0, but the market is under configured liquidation p/d,
                another block of liquidation becomes allowable.
             */
            uint256 currentPd = MathUtil.abs(self.skew).divDecimal(marketConfig.skewScale);
            if (currentPd < maxLiquidationPd) {
                liquidatableAmount = MathUtil.min128(
                    maxLiquidationInWindow.to128(),
                    requestedLiquidationAmount
                );
            }
        }

        if (liquidatableAmount > 0) {
            _updateLiquidationData(self, liquidatableAmount);
        }
    }

    function _updateLiquidationData(Data storage self, uint128 liquidationAmount) private {
        uint256 liquidationDataLength = self.liquidationData.length;
        uint256 currentTimestamp = liquidationDataLength == 0
            ? 0
            : self.liquidationData[liquidationDataLength - 1].timestamp;

        if (currentTimestamp == block.timestamp) {
            self.liquidationData[liquidationDataLength - 1].amount += liquidationAmount;
        } else {
            self.liquidationData.push(
                Liquidation.Data({amount: liquidationAmount, timestamp: block.timestamp})
            );
        }
    }

    /**
     * @dev Returns the current liquidation capacity for the market
     * @notice This function sums up the liquidation amounts in the current liquidation window
     * and returns the capacity left.
     */
    function currentLiquidationCapacity(
        Data storage self,
        PerpsMarketConfiguration.Data storage marketConfig
    )
        internal
        view
        returns (
            uint256 capacity,
            uint256 maxLiquidationInWindow,
            uint256 latestLiquidationTimestamp
        )
    {
        maxLiquidationInWindow = marketConfig.maxLiquidationAmountInWindow();
        uint256 accumulatedLiquidationAmounts;
        uint256 liquidationDataLength = self.liquidationData.length;
        if (liquidationDataLength == 0) return (maxLiquidationInWindow, maxLiquidationInWindow, 0);

        uint256 currentIndex = liquidationDataLength - 1;
        latestLiquidationTimestamp = self.liquidationData[currentIndex].timestamp;
        uint256 windowStartTimestamp = block.timestamp - marketConfig.maxSecondsInLiquidationWindow;

        while (self.liquidationData[currentIndex].timestamp > windowStartTimestamp) {
            accumulatedLiquidationAmounts += self.liquidationData[currentIndex].amount;

            if (currentIndex == 0) break;
            currentIndex--;
        }
        int256 availableLiquidationCapacity = maxLiquidationInWindow.toInt() -
            accumulatedLiquidationAmounts.toInt();
        // solhint-disable-next-line numcast/safe-cast
        capacity = MathUtil.max(availableLiquidationCapacity, int256(0)).toUint();
    }

    struct PositionDataRuntime {
        uint256 currentPrice;
        int256 sizeDelta;
        int256 fundingDelta;
        int256 notionalDelta;
    }

    /**
     * @dev Use this function to update both market/position size/skew.
     * @dev Size and skew should not be updated directly.
     * @dev The return value is used to emit a MarketUpdated event.
     */
    function updatePositionData(
        Data storage self,
        uint128 accountId,
        Position.Data memory newPosition
    ) internal returns (MarketUpdate.Data memory) {
        PositionDataRuntime memory runtime;
        Position.Data storage oldPosition = self.positions[accountId];

        self.size =
            (self.size + MathUtil.abs128(newPosition.size)) -
            MathUtil.abs128(oldPosition.size);
        self.skew += newPosition.size - oldPosition.size;

        runtime.currentPrice = newPosition.latestInteractionPrice;
        (, int256 pricePnl, , int256 fundingPnl, , ) = oldPosition.getPnl(runtime.currentPrice);

        runtime.sizeDelta = newPosition.size - oldPosition.size;
        runtime.fundingDelta = calculateNextFunding(self, runtime.currentPrice).mulDecimal(
            runtime.sizeDelta
        );
        runtime.notionalDelta = runtime.currentPrice.toInt().mulDecimal(runtime.sizeDelta);

        // update the market debt correction accumulator before losing oldPosition details
        // by adding the new updated notional (old - new size) plus old position pnl
        self.debtCorrectionAccumulator +=
            runtime.fundingDelta +
            runtime.notionalDelta +
            pricePnl +
            fundingPnl;

        // update position to new position
        // Note: once market interest rate is updated, the current accrued interest is saved
        // to figure out the unrealized interest for the position
        (uint128 interestRate, uint256 currentInterestAccrued) = InterestRate.update();
        oldPosition.update(newPosition, currentInterestAccrued);

        return
            MarketUpdate.Data(
                self.id,
                interestRate,
                self.skew,
                self.size,
                self.lastFundingRate,
                currentFundingVelocity(self)
            );
    }

    function recomputeFunding(
        Data storage self,
        uint256 price
    ) internal returns (int256 fundingRate, int256 fundingValue) {
        fundingRate = currentFundingRate(self);
        fundingValue = calculateNextFunding(self, price);

        self.lastFundingRate = fundingRate;
        self.lastFundingValue = fundingValue;
        self.lastFundingTime = block.timestamp;

        return (fundingRate, fundingValue);
    }

    function calculateNextFunding(
        Data storage self,
        uint256 price
    ) internal view returns (int256 nextFunding) {
        nextFunding = self.lastFundingValue + unrecordedFunding(self, price);
    }

    function unrecordedFunding(Data storage self, uint256 price) internal view returns (int256) {
        int256 fundingRate = currentFundingRate(self);
        // note the minus sign: funding flows in the opposite direction to the skew.
        int256 avgFundingRate = -(self.lastFundingRate + fundingRate).divDecimal(
            (DecimalMath.UNIT * 2).toInt()
        );

        return avgFundingRate.mulDecimal(proportionalElapsed(self)).mulDecimal(price.toInt());
    }

    function currentFundingRate(Data storage self) internal view returns (int256) {
        // calculations:
        //  - velocity          = proportional_skew * max_funding_velocity
        //  - proportional_skew = skew / skew_scale
        //
        // example:
        //  - prev_funding_rate     = 0
        //  - prev_velocity         = 0.0025
        //  - time_delta            = 29,000s
        //  - max_funding_velocity  = 0.025 (2.5%)
        //  - skew                  = 300
        //  - skew_scale            = 10,000
        //
        // note: prev_velocity just refs to the velocity _before_ modifying the market skew.
        //
        // funding_rate = prev_funding_rate + prev_velocity * (time_delta / seconds_in_day)
        // funding_rate = 0 + 0.0025 * (29,000 / 86,400)
        //              = 0 + 0.0025 * 0.33564815
        //              = 0.00083912
        return
            self.lastFundingRate +
            (currentFundingVelocity(self).mulDecimal(proportionalElapsed(self)));
    }

    function currentFundingVelocity(Data storage self) internal view returns (int256) {
        PerpsMarketConfiguration.Data storage marketConfig = PerpsMarketConfiguration.load(self.id);
        int256 maxFundingVelocity = marketConfig.maxFundingVelocity.toInt();
        int256 skewScale = marketConfig.skewScale.toInt();
        // Avoid a panic due to div by zero. Return 0 immediately.
        if (skewScale == 0) {
            return 0;
        }
        // Ensures the proportionalSkew is between -1 and 1.
        int256 pSkew = self.skew.divDecimal(skewScale);
        int256 pSkewBounded = MathUtil.min(
            MathUtil.max(-(DecimalMath.UNIT).toInt(), pSkew),
            (DecimalMath.UNIT).toInt()
        );
        return pSkewBounded.mulDecimal(maxFundingVelocity);
    }

    function proportionalElapsed(Data storage self) internal view returns (int256) {
        // even though timestamps here are not D18, divDecimal multiplies by 1e18 to preserve decimals into D18
        return (block.timestamp - self.lastFundingTime).divDecimal(1 days).toInt();
    }

    function validatePositionSize(
        Data storage self,
        uint256 maxSize,
        uint256 maxValue,
        uint256 price,
        int128 oldSize,
        int128 newSize
    ) internal view {
        // Allow users to reduce an order no matter the market conditions.
        bool isReducingInterest = MathUtil.isSameSideReducing(oldSize, newSize);
        if (!isReducingInterest) {
            int256 newSkew = self.skew - oldSize + newSize;

            int256 newMarketSize = self.size.toInt() -
                MathUtil.abs(oldSize).toInt() +
                MathUtil.abs(newSize).toInt();

            int256 newSideSize;
            if (0 < newSize) {
                // long case: marketSize + skew
                //            = (|longSize| + |shortSize|) + (longSize + shortSize)
                //            = 2 * longSize
                newSideSize = newMarketSize + newSkew;
            } else {
                // short case: marketSize - skew
                //            = (|longSize| + |shortSize|) - (longSize + shortSize)
                //            = 2 * -shortSize
                newSideSize = newMarketSize - newSkew;
            }

            // newSideSize still includes an extra factor of 2 here, so we will divide by 2 in the actual condition
            if (maxSize < MathUtil.abs(newSideSize / 2)) {
                revert PerpsMarketConfiguration.MaxOpenInterestReached(
                    self.id,
                    maxSize,
                    newSideSize / 2
                );
            }

            // same check but with value (size * price)
            // note that if maxValue param is set to 0, this validation is skipped
            if (maxValue > 0 && maxValue < MathUtil.abs(newSideSize / 2).mulDecimal(price)) {
                revert PerpsMarketConfiguration.MaxUSDOpenInterestReached(
                    self.id,
                    maxValue,
                    newSideSize / 2,
                    price
                );
            }
        }
    }

    /**
     * @dev Returns the market debt incurred by all positions
     * @notice  Market debt is the sum of all position sizes multiplied by the price, and old positions pnl that is included in the debt correction accumulator.
     */
    function marketDebt(Data storage self, uint256 price) internal view returns (int256) {
        // all positions sizes multiplied by the price is equivalent to skew times price
        // and the debt correction accumulator is the  sum of all positions pnl
        int256 positionPnl = self.skew.mulDecimal(price.toInt());
        int256 fundingPnl = self.skew.mulDecimal(calculateNextFunding(self, price));

        return positionPnl + fundingPnl - self.debtCorrectionAccumulator;
    }

    function requiredCredit(uint128 marketId) internal view returns (uint256) {
        return
            PerpsMarket
                .load(marketId)
                .size
                .mulDecimal(PerpsPrice.getCurrentPrice(marketId, PerpsPrice.Tolerance.DEFAULT))
                .mulDecimal(PerpsMarketConfiguration.load(marketId).lockedOiRatioD18);
    }

    function accountPosition(
        uint128 marketId,
        uint128 accountId
    ) internal view returns (Position.Data storage position) {
        position = load(marketId).positions[accountId];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import {SafeCastI128} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {OrderFee} from "./OrderFee.sol";
import {SettlementStrategy} from "./SettlementStrategy.sol";
import {MathUtil} from "../utils/MathUtil.sol";

library PerpsMarketConfiguration {
    using DecimalMath for int256;
    using DecimalMath for uint256;
    using SafeCastI128 for int128;

    error MaxOpenInterestReached(uint128 marketId, uint256 maxMarketSize, int256 newSideSize);

    error MaxUSDOpenInterestReached(
        uint128 marketId,
        uint256 maxMarketValue,
        int256 newSideSize,
        uint256 price
    );

    error InvalidSettlementStrategy(uint256 settlementStrategyId);

    struct Data {
        OrderFee.Data orderFees;
        SettlementStrategy.Data[] settlementStrategies;
        uint256 maxMarketSize; // oi cap in units of asset
        uint256 maxFundingVelocity;
        uint256 skewScale;
        /**
         * @dev the initial margin requirements for this market when opening a position
         * @dev this fraction is multiplied by the impact of the position on the skew (open position size / skewScale)
         */
        uint256 initialMarginRatioD18;
        /**
         * @dev This scalar is applied to the calculated initial margin ratio
         * @dev this generally will be lower than initial margin but is used to determine when to liquidate a position
         * @dev this fraction is multiplied by the impact of the position on the skew (position size / skewScale)
         */
        uint256 maintenanceMarginScalarD18;
        /**
         * @dev This ratio is multiplied by the market's notional size (size * currentPrice) to determine how much credit is required for the market to be sufficiently backed by the LPs
         */
        uint256 lockedOiRatioD18;
        /**
         * @dev This multiplier is applied to the max liquidation value when calculating max liquidation for a given market
         */
        uint256 maxLiquidationLimitAccumulationMultiplier;
        /**
         * @dev This configured window is the max liquidation amount that can be accumulated.
         * @dev If you multiply maxLiquidationPerSecond * this window in seconds, you get the max liquidation amount that can be accumulated within this window
         */
        uint256 maxSecondsInLiquidationWindow;
        /**
         * @dev This value is multiplied by the notional value of a position to determine flag reward
         */
        uint256 flagRewardRatioD18;
        /**
         * @dev minimum position value in USD, this is a constant value added to position margin requirements (initial/maintenance)
         */
        uint256 minimumPositionMargin;
        /**
         * @dev This value gets applied to the initial margin ratio to ensure there's a cap on the max leverage regardless of position size
         */
        uint256 minimumInitialMarginRatioD18;
        /**
         * @dev Threshold for allowing further liquidations when max liquidation amount is reached
         */
        uint256 maxLiquidationPd;
        /**
         * @dev if the msg.sender is this endorsed liquidator during an account liquidation, the max liquidation amount doesn't apply.
         * @dev this address is allowed to fully liquidate any account eligible for liquidation.
         */
        address endorsedLiquidator;
        /**
         * @dev OI cap in USD denominated.
         * @dev If set to zero then there is no cap with value, just units
         */
        uint256 maxMarketValue;
    }

    function load(uint128 marketId) internal pure returns (Data storage store) {
        bytes32 s = keccak256(
            abi.encode("io.synthetix.perps-market.PerpsMarketConfiguration", marketId)
        );
        assembly {
            store.slot := s
        }
    }

    function maxLiquidationAmountInWindow(Data storage self) internal view returns (uint256) {
        OrderFee.Data storage orderFeeData = self.orderFees;
        return
            (orderFeeData.makerFee + orderFeeData.takerFee).mulDecimal(self.skewScale).mulDecimal(
                self.maxLiquidationLimitAccumulationMultiplier
            ) * self.maxSecondsInLiquidationWindow;
    }

    function numberOfLiquidationWindows(
        Data storage self,
        uint256 positionSize
    ) internal view returns (uint256) {
        return MathUtil.ceilDivide(positionSize, maxLiquidationAmountInWindow(self));
    }

    function calculateFlagReward(
        Data storage self,
        uint256 notionalValue
    ) internal view returns (uint256) {
        return notionalValue.mulDecimal(self.flagRewardRatioD18);
    }

    function calculateRequiredMargins(
        Data storage self,
        int128 size,
        uint256 price
    )
        internal
        view
        returns (
            uint256 initialMarginRatio,
            uint256 maintenanceMarginRatio,
            uint256 initialMargin,
            uint256 maintenanceMargin
        )
    {
        if (size == 0) {
            return (0, 0, 0, 0);
        }
        uint256 sizeAbs = MathUtil.abs(size.to256());
        uint256 impactOnSkew = self.skewScale == 0 ? 0 : sizeAbs.divDecimal(self.skewScale);

        initialMarginRatio =
            impactOnSkew.mulDecimal(self.initialMarginRatioD18) +
            self.minimumInitialMarginRatioD18;
        maintenanceMarginRatio = initialMarginRatio.mulDecimal(self.maintenanceMarginScalarD18);

        uint256 notional = sizeAbs.mulDecimal(price);

        initialMargin = notional.mulDecimal(initialMarginRatio) + self.minimumPositionMargin;
        maintenanceMargin =
            notional.mulDecimal(maintenanceMarginRatio) +
            self.minimumPositionMargin;
    }

    /**
     * @notice given a strategy id, returns the entire settlement strategy struct
     */
    function loadValidSettlementStrategy(
        uint128 marketId,
        uint256 settlementStrategyId
    ) internal view returns (SettlementStrategy.Data storage strategy) {
        Data storage self = load(marketId);
        validateStrategyExists(self, settlementStrategyId);

        strategy = self.settlementStrategies[settlementStrategyId];
        if (strategy.disabled) {
            revert InvalidSettlementStrategy(settlementStrategyId);
        }
    }

    function validateStrategyExists(
        Data storage config,
        uint256 settlementStrategyId
    ) internal view {
        if (settlementStrategyId >= config.settlementStrategies.length) {
            revert InvalidSettlementStrategy(settlementStrategyId);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {ITokenModule} from "@synthetixio/core-modules/contracts/interfaces/ITokenModule.sol";
import {INodeModule} from "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";
import {ISynthetixSystem} from "../interfaces/external/ISynthetixSystem.sol";
import {ISpotMarketSystem} from "../interfaces/external/ISpotMarketSystem.sol";
import {GlobalPerpsMarket} from "../storage/GlobalPerpsMarket.sol";
import {PerpsMarket} from "../storage/PerpsMarket.sol";
import {NodeOutput} from "@synthetixio/oracle-manager/contracts/storage/NodeOutput.sol";
import {NodeDefinition} from "@synthetixio/oracle-manager/contracts/storage/NodeDefinition.sol";
import {SafeCastI256, SafeCastU256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {SetUtil} from "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

/**
 * @title Main factory library that registers perps markets.  Also houses global configuration for all perps markets.
 */
library PerpsMarketFactory {
    using SafeCastI256 for int256;
    using SafeCastU256 for uint256;
    using SetUtil for SetUtil.UintSet;
    using GlobalPerpsMarket for GlobalPerpsMarket.Data;
    using PerpsMarket for PerpsMarket.Data;

    bytes32 private constant _SLOT_PERPS_MARKET_FACTORY =
        keccak256(abi.encode("io.synthetix.perps-market.PerpsMarketFactory"));

    error PerpsMarketNotInitialized();
    error PerpsMarketAlreadyInitialized();

    struct Data {
        /**
         * @dev oracle manager address used for price feeds
         */
        INodeModule oracle;
        ITokenModule usdToken;
        /**
         * @dev Synthetix core v3 proxy address
         */
        ISynthetixSystem synthetix;
        ISpotMarketSystem spotMarket;
        uint128 perpsMarketId;
        string name;
    }

    function onlyIfInitialized(Data storage self) internal view {
        if (self.perpsMarketId == 0) {
            revert PerpsMarketNotInitialized();
        }
    }

    function onlyIfNotInitialized(Data storage self) internal view {
        if (self.perpsMarketId != 0) {
            revert PerpsMarketAlreadyInitialized();
        }
    }

    function load() internal pure returns (Data storage perpsMarketFactory) {
        bytes32 s = _SLOT_PERPS_MARKET_FACTORY;
        assembly {
            perpsMarketFactory.slot := s
        }
    }

    function initialize(
        Data storage self,
        ISynthetixSystem synthetix,
        ISpotMarketSystem spotMarket
    ) internal returns (uint128 perpsMarketId) {
        onlyIfNotInitialized(self); // redundant check, but kept here in case this internal is called somewhere else

        (address usdTokenAddress, ) = synthetix.getAssociatedSystem("USDToken");
        perpsMarketId = synthetix.registerMarket(address(this));

        self.spotMarket = spotMarket;
        self.synthetix = synthetix;
        self.usdToken = ITokenModule(usdTokenAddress);
        self.oracle = synthetix.getOracleManager();
        self.perpsMarketId = perpsMarketId;
    }

    function totalWithdrawableUsd() internal view returns (uint256) {
        Data storage self = load();
        return self.synthetix.getWithdrawableMarketUsd(self.perpsMarketId);
    }

    function depositMarketCollateral(
        Data storage self,
        ITokenModule collateral,
        uint256 amount
    ) internal {
        collateral.approve(address(self.synthetix), amount);
        self.synthetix.depositMarketCollateral(self.perpsMarketId, address(collateral), amount);
    }

    function depositMarketUsd(Data storage self, uint256 amount) internal {
        self.usdToken.approve(address(this), amount);
        self.synthetix.depositMarketUsd(self.perpsMarketId, address(this), amount);
    }

    function withdrawMarketUsd(Data storage self, address to, uint256 amount) internal {
        self.synthetix.withdrawMarketUsd(self.perpsMarketId, to, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {INodeModule} from "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";
import {NodeOutput} from "@synthetixio/oracle-manager/contracts/storage/NodeOutput.sol";
import {SafeCastI256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {PerpsMarketFactory} from "./PerpsMarketFactory.sol";

/**
 * @title Price storage for a specific synth market.
 */
library PerpsPrice {
    using SafeCastI256 for int256;

    enum Tolerance {
        DEFAULT,
        STRICT
    }

    struct Data {
        /**
         * @dev the price feed id for the market.  this node is processed using the oracle manager which returns the price.
         * @dev the staleness tolerance is provided as a runtime argument to this feed for processing.
         */
        bytes32 feedId;
        /**
         * @dev strict tolerance in seconds, mainly utilized for liquidations.
         */
        uint256 strictStalenessTolerance;
    }

    function load(uint128 marketId) internal pure returns (Data storage price) {
        bytes32 s = keccak256(abi.encode("io.synthetix.perps-market.Price", marketId));
        assembly {
            price.slot := s
        }
    }

    function getCurrentPrice(
        uint128 marketId,
        Tolerance priceTolerance
    ) internal view returns (uint256 price) {
        Data storage self = load(marketId);
        PerpsMarketFactory.Data storage factory = PerpsMarketFactory.load();
        NodeOutput.Data memory output;
        if (priceTolerance == Tolerance.STRICT) {
            bytes32[] memory runtimeKeys = new bytes32[](1);
            bytes32[] memory runtimeValues = new bytes32[](1);
            runtimeKeys[0] = bytes32("stalenessTolerance");
            runtimeValues[0] = bytes32(self.strictStalenessTolerance);
            output = INodeModule(factory.oracle).processWithRuntime(
                self.feedId,
                runtimeKeys,
                runtimeValues
            );
        } else {
            output = INodeModule(factory.oracle).process(self.feedId);
        }

        return output.price.toUint();
    }

    function update(Data storage self, bytes32 feedId, uint256 strictStalenessTolerance) internal {
        self.feedId = feedId;
        self.strictStalenessTolerance = strictStalenessTolerance;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {SafeCastU256, SafeCastU128} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import {PerpsMarket} from "./PerpsMarket.sol";
import {PerpsMarketConfiguration} from "./PerpsMarketConfiguration.sol";
import {InterestRate} from "./InterestRate.sol";
import {MathUtil} from "../utils/MathUtil.sol";

library Position {
    using SafeCastU256 for uint256;
    using SafeCastU128 for uint128;
    using DecimalMath for uint256;
    using DecimalMath for int128;
    using PerpsMarket for PerpsMarket.Data;
    using InterestRate for InterestRate.Data;

    struct Data {
        uint128 marketId;
        int128 size;
        uint128 latestInteractionPrice;
        int128 latestInteractionFunding;
        uint256 latestInterestAccrued;
    }

    function update(
        Data storage self,
        Data memory newPosition,
        uint256 latestInterestAccrued
    ) internal {
        self.size = newPosition.size;
        self.marketId = newPosition.marketId;
        self.latestInteractionPrice = newPosition.latestInteractionPrice;
        self.latestInteractionFunding = newPosition.latestInteractionFunding;
        self.latestInterestAccrued = latestInterestAccrued;
    }

    function getPositionData(
        Data storage self,
        uint256 price
    )
        internal
        view
        returns (
            uint256 notionalValue,
            int256 totalPnl,
            int256 pricePnl,
            uint256 chargedInterest,
            int256 accruedFunding,
            int256 netFundingPerUnit,
            int256 nextFunding
        )
    {
        (
            totalPnl,
            pricePnl,
            chargedInterest,
            accruedFunding,
            netFundingPerUnit,
            nextFunding
        ) = getPnl(self, price);
        notionalValue = getNotionalValue(self, price);
    }

    function getPnl(
        Data storage self,
        uint256 price
    )
        internal
        view
        returns (
            int256 totalPnl,
            int256 pricePnl,
            uint256 chargedInterest,
            int256 accruedFunding,
            int256 netFundingPerUnit,
            int256 nextFunding
        )
    {
        nextFunding = PerpsMarket.load(self.marketId).calculateNextFunding(price);
        netFundingPerUnit = nextFunding - self.latestInteractionFunding;
        accruedFunding = self.size.mulDecimal(netFundingPerUnit);

        int256 priceShift = price.toInt() - self.latestInteractionPrice.toInt();
        pricePnl = self.size.mulDecimal(priceShift);

        chargedInterest = interestAccrued(self, price);

        totalPnl = pricePnl + accruedFunding - chargedInterest.toInt();
    }

    function interestAccrued(
        Data storage self,
        uint256 price
    ) internal view returns (uint256 chargedInterest) {
        uint256 nextInterestAccrued = InterestRate.load().calculateNextInterest();
        uint256 netInterestPerDollar = nextInterestAccrued - self.latestInterestAccrued;

        // The interest is charged pro-rata on this position's contribution to the locked OI requirement
        chargedInterest = getLockedNotionalValue(self, price).mulDecimal(netInterestPerDollar);
    }

    function getLockedNotionalValue(
        Data storage self,
        uint256 price
    ) internal view returns (uint256) {
        return
            getNotionalValue(self, price).mulDecimal(
                PerpsMarketConfiguration.load(self.marketId).lockedOiRatioD18
            );
    }

    function getNotionalValue(Data storage self, uint256 price) internal view returns (uint256) {
        return MathUtil.abs(self.size).mulDecimal(price);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import {SafeCastI256, SafeCastU256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {MathUtil} from "../utils/MathUtil.sol";

library SettlementStrategy {
    using DecimalMath for uint256;
    using SafeCastI256 for int256;
    using SafeCastU256 for uint256;

    struct Data {
        /**
         * @dev see Type for more details
         */
        Type strategyType;
        /**
         * @dev the delay added to commitment time after which committed orders can be settled.
         * @dev this ensures settlements aren't on the same block as commitment.
         */
        uint256 settlementDelay;
        /**
         * @dev the duration of the settlement window, after which committed orders can be cancelled.
         */
        uint256 settlementWindowDuration;
        /**
         * @dev the address of the contract that returns the benchmark price at a given timestamp
         * @dev generally this contract orchestrates the erc7412 logic to force push an offchain price for a given timestamp.
         */
        address priceVerificationContract; // For Chainlink and Pyth settlement strategies
        /**
         * @dev configurable feed id for chainlink and pyth
         */
        bytes32 feedId;
        /**
         * @dev the amount of reward paid to the keeper for settling the order.
         */
        uint256 settlementReward;
        /**
         * @dev whether the strategy is disabled or not.
         */
        bool disabled;
        /**
         * @dev the delay added to commitment time for determining valid price. Defines the expected price timestamp.
         * @dev this ensures price aren't on the same block as commitment in case of blockchain drift in timestamp or bad actors timestamp manipulation.
         */
        uint256 commitmentPriceDelay;
    }

    enum Type {
        PYTH
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library Flags {
    bytes32 public constant PERPS_SYSTEM = "perpsSystem";
    bytes32 public constant CREATE_MARKET = "createMarket";
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {SafeCastI256, SafeCastI128, SafeCastU256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

library MathUtil {
    using SafeCastI256 for int256;
    using SafeCastI128 for int128;
    using SafeCastU256 for uint256;

    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? x.toUint() : (-x).toUint();
    }

    function abs128(int128 x) internal pure returns (uint128) {
        return x >= 0 ? x.toUint() : (-x).toUint();
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? y : x;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? y : x;
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? x : y;
    }

    function min128(int128 x, int128 y) internal pure returns (int128) {
        return x < y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    function min128(uint128 x, uint128 y) internal pure returns (uint128) {
        return x < y ? x : y;
    }

    function sameSide(int256 a, int256 b) internal pure returns (bool) {
        return (a == 0) || (b == 0) || (a > 0) == (b > 0);
    }

    function isSameSideReducing(int128 a, int128 b) internal pure returns (bool) {
        return sameSide(a, b) && abs(b) < abs(a);
    }

    function ceilDivide(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) return 0;
        return a / b + (a % b == 0 ? 0 : 1);
    }
}