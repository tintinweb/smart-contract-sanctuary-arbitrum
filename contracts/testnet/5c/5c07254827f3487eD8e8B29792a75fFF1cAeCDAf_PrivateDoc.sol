// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/development-recommendations/general/external-calls/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

uint256 constant ARBITRUM_ONE = 42161;
uint256 constant ARBITRUM_GOERLI = 421613;

interface ArbSys {
    function arbBlockNumber() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

// parts extracted/inspired from https://github.com/keep-network/keep-core/edit/main/solidity/random-beacon/contracts/libraries/AltBn128.sol
pragma solidity ^0.8.17;

// G1Point implements a point in G1 group.

struct G1Point {
    uint256 x;
    uint256 y;
}

struct DleqProof {
    uint256 f;
    uint256 e;
}

/// @title Operations on bn128
/// @dev Implementations of common elliptic curve operations on Ethereum's
///      alt_bn128 curve. Whenever possible, use post-Byzantium
///      pre-compiled contracts to offset gas costs.
library Bn128 {
    using ModUtils for uint256;

    // p is a prime over which we form a basic field
    // Taken from go-ethereum/crypto/bn256/cloudflare/constants.go
    uint256 internal constant p = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    /// @dev Gets generator of G1 group.
    ///      Taken from go-ethereum/crypto/bn256/cloudflare/curve.go
    uint256 internal constant g1x = 1;
    uint256 internal constant g1y = 2;

    //// --------------------
    ////       DLEQ PART
    //// --------------------
    uint256 internal constant base2x = 5671920232091439599101938152932944148754342563866262832106763099907508111378;
    uint256 internal constant base2y = 2648212145371980650762357218546059709774557459353804686023280323276775278879;
    uint256 internal constant r = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// TODO XXX Can't extract that in its own library because then can't instantiate in Typescript correctly
    /// Seems like a linked library problem with typechain.
    function dleqverify(G1Point calldata _rg1, G1Point calldata _rg2, DleqProof calldata _proof, uint256 _label)
        internal
        view
        returns (
            //) internal view returns (G1Point memory) {
            bool
        )
    {
        // w1 = f*G1 + rG1 * e
        G1Point memory w1 = g1Add(scalarMultiply(g1(), _proof.f), scalarMultiply(_rg1, _proof.e));
        // w2 = f*G2 + rG2 * e
        G1Point memory w2 = g1Add(scalarMultiply(G1Point(base2x, base2y), _proof.f), scalarMultiply(_rg2, _proof.e));
        uint256 challenge =
            uint256(sha256(abi.encodePacked(_label, _rg1.x, _rg1.y, _rg2.x, _rg2.y, w1.x, w1.y, w2.x, w2.y))) % r;
        if (challenge == _proof.e) {
            return true;
        }
        return false;
    }

    function g1Zero() internal pure returns (G1Point memory) {
        return G1Point(0, 0);
    }

    /// @dev Decompress a point on G1 from a single uint256.
    function g1Decompress(bytes32 m) internal view returns (G1Point memory) {
        unchecked {
            bytes32 mX = bytes32(0);
            bytes1 leadX = m[0] & 0x7f;
            // slither-disable-next-line incorrect-shift
            uint256 mask = 0xff << (31 * 8);
            mX = (m & ~bytes32(mask)) | (leadX >> 0);

            uint256 x = uint256(mX);
            uint256 y = g1YFromX(x);

            if (parity(y) != (m[0] & 0x80) >> 7) {
                y = p - y;
            }

            require(isG1PointOnCurve(G1Point(x, y)), "Malformed bn256.G1 point.");

            return G1Point(x, y);
        }
    }

    /// @dev Wraps the scalar point multiplication pre-compile introduced in
    ///      Byzantium. The result of a point from G1 multiplied by a scalar
    ///      should match the point added to itself the same number of times.
    ///      Revert if the provided point isn't on the curve.
    function scalarMultiply(G1Point memory p_1, uint256 scalar) internal view returns (G1Point memory p_2) {
        // 0x07     id of the bn256ScalarMul precompile
        // 0        number of ether to transfer
        // 96       size of call parameters, i.e. 96 bytes total (256 bit for x, 256 bit for y, 256 bit for scalar)
        // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
        assembly {
            let arg := mload(0x40)
            mstore(arg, mload(p_1))
            mstore(add(arg, 0x20), mload(add(p_1, 0x20)))
            mstore(add(arg, 0x40), scalar)
            // 0x07 is the ECMUL precompile address
            if iszero(staticcall(not(0), 0x07, arg, 0x60, p_2, 0x40)) { revert(0, 0) }
        }
    }

    /// @dev Wraps the point addition pre-compile introduced in Byzantium.
    ///      Returns the sum of two points on G1. Revert if the provided points
    ///      are not on the curve.
    function g1Add(G1Point memory a, G1Point memory b) internal view returns (G1Point memory c) {
        assembly {
            let arg := mload(0x40)
            mstore(arg, mload(a))
            mstore(add(arg, 0x20), mload(add(a, 0x20)))
            mstore(add(arg, 0x40), mload(b))
            mstore(add(arg, 0x60), mload(add(b, 0x20)))
            // 0x60 is the ECADD precompile address
            if iszero(staticcall(not(0), 0x06, arg, 0x80, c, 0x40)) { revert(0, 0) }
        }
    }

    /// @dev Returns true if G1 point is on the curve.
    function isG1PointOnCurve(G1Point memory point) internal view returns (bool) {
        return point.y.modExp(2, p) == (point.x.modExp(3, p) + 3) % p;
    }

    /// @dev Compress a point on G1 to a single uint256 for serialization.
    function g1Compress(G1Point memory point) internal pure returns (bytes32) {
        bytes32 m = bytes32(point.x);

        // first byte with the first bit set as parity -> 1 = even, 0 = odd
        // even <-- 1xxxxxxx
        bytes1 leadM = m[0] | (parity(point.y) << 7);
        // slither-disable-next-line incorrect-shift
        // 0xff000....00
        uint256 mask = 0xff << (31 * 8);
        // m & 00ffffffff -> that keeps the lowest parts of m  and then add the
        // lead bit
        // even <-- 1xxxxxxx  m[1..j]
        m = (m & ~bytes32(mask)) | (leadM >> 0);

        return m;
    }

    /// @dev g1YFromX computes a Y value for a G1 point based on an X value.
    ///      This computation is simply evaluating the curve equation for Y on a
    ///      given X, and allows a point on the curve to be represented by just
    ///      an X value + a sign bit.
    // TODO: Sqrt can be cheaper by giving the y value directly and computing
    // the check y_witness^2 = y^2
    function g1YFromX(uint256 x) internal view returns (uint256) {
        return ((x.modExp(3, p) + 3) % p).modSqrt(p);
    }

    /// @dev Calculates whether the provided number is even or odd.
    /// @return 0x01 if y is an even number and 0x00 if it's odd.
    function parity(uint256 value) public pure returns (bytes1) {
        return bytes32(value)[31] & 0x01;
    }

    function g1() public pure returns (G1Point memory) {
        return G1Point(g1x, g1y);
    }
}

library ModUtils {
    /// @dev Wraps the modular exponent pre-compile introduced in Byzantium.
    ///      Returns base^exponent mod p.
    function modExp(uint256 base, uint256 exponent, uint256 p) internal view returns (uint256 o) {
        assembly {
            // Args for the precompile: [<length_of_BASE> <length_of_EXPONENT>
            // <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>]
            let output := mload(0x40)
            let args := add(output, 0x20)
            mstore(args, 0x20)
            mstore(add(args, 0x20), 0x20)
            mstore(add(args, 0x40), 0x20)
            mstore(add(args, 0x60), base)
            mstore(add(args, 0x80), exponent)
            mstore(add(args, 0xa0), p)

            // 0x05 is the modular exponent contract address
            if iszero(staticcall(not(0), 0x05, args, 0xc0, output, 0x20)) { revert(0, 0) }
            o := mload(output)
        }
    }

    /// @dev Calculates and returns the square root of a mod p if such a square
    ///      root exists. The modulus p must be an odd prime. If a square root
    ///      does not exist, function returns 0.
    // TODO avoid thiisssssss by giving witness
    function modSqrt(uint256 a, uint256 p) internal view returns (uint256) {
        unchecked {
            if (legendre(a, p) != 1) {
                return 0;
            }

            if (a == 0) {
                return 0;
            }

            if (p % 4 == 3) {
                return modExp(a, (p + 1) / 4, p);
            }

            uint256 s = p - 1;
            uint256 e = 0;

            while (s % 2 == 0) {
                s = s / 2;
                e = e + 1;
            }

            // Note the smaller int- finding n with Legendre symbol or -1
            // should be quick
            uint256 n = 2;
            while (legendre(n, p) != -1) {
                n = n + 1;
            }

            uint256 x = modExp(a, (s + 1) / 2, p);
            uint256 b = modExp(a, s, p);
            uint256 g = modExp(n, s, p);
            uint256 r = e;
            uint256 gs = 0;
            uint256 m = 0;
            uint256 t = b;

            while (true) {
                t = b;
                m = 0;

                for (m = 0; m < r; m++) {
                    if (t == 1) {
                        break;
                    }
                    t = modExp(t, 2, p);
                }

                if (m == 0) {
                    return x;
                }

                gs = modExp(g, uint256(2) ** (r - m - 1), p);
                g = (gs * gs) % p;
                x = (x * gs) % p;
                b = (b * g) % p;
                r = m;
            }
        }
        return 0;
    }

    /// @dev Calculates the Legendre symbol of the given a mod p.
    /// @return Returns 1 if a is a quadratic residue mod p, -1 if it is
    ///         a non-quadratic residue, and 0 if a is 0.
    function legendre(uint256 a, uint256 p) internal view returns (int256) {
        unchecked {
            uint256 raised = modExp(a, (p - 1) / uint256(2), p);

            if (raised == 0 || raised == 1) {
                return int256(raised);
            } else if (raised == p - 1) {
                return -1;
            }

            require(false, "Failed to calculate legendre.");
            return 0;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {EncryptionOracle} from "./EncryptionOracle.sol";
import {G1Point} from "./Bn128.sol";
import {Suite} from "./OracleFactory.sol";

contract BN254EncryptionOracle is EncryptionOracle {
    constructor(
        G1Point memory _distKey,
        address _relayer
    ) EncryptionOracle(_distKey) {}

    function suite() external pure override returns (Suite) {
        return Suite.BN254_KEYG1_HGAMAL;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Bn128, G1Point} from "./Bn128.sol";
import {DKGFactory} from "./DKGFactory.sol";
import {ArbSys, ARBITRUM_ONE, ARBITRUM_GOERLI} from "./ArbSys.sol";

error InvalidPhase();
error ParticipantLimit();
error AlreadyRegistered();
error NotAuthorized();
error NotRegistered();
error InvalidSharesCount();
error InvalidCommitmentsCount();
error InvalidCommitment(uint256 index);

/// @title ThresholdNetwork
/// @author Cryptonet
/// @notice This contract represents a threshold network.
/// @dev All threshold networks have a distributed key;
/// the DKG contract facilitates the generation of a key, whereas Oracle contracts are given a key
abstract contract ThresholdNetwork {
    G1Point internal distKey;

    constructor(G1Point memory _distKey) {
        distKey = _distKey;
    }

    function distributedKey() external view virtual returns (G1Point memory) {
        return distKey;
    }
}

/// @notice A bundle of deals submitted by each participant.
struct DealBundle {
    G1Point random;
    uint32[] indices;
    uint256[] encryptedShares;
    G1Point[] commitment;
}

interface IDKG {
    enum Phase {
        REGISTRATION,
        DEAL,
        COMPLAINT,
        DONE
    }

    /// @notice Emitted when a new participant registers during the registration phase.
    /// @param from The address of the participant.
    /// @param index The index of the participant.
    /// @param tmpKey The temporary key of the participant.
    event NewParticipant(address from, uint32 index, uint256 tmpKey);

    /// @notice Emitted when a deal is submitted during the deal phase.
    /// @param dealerIdx The index of the dealer submitting the deal.
    /// @param bundle The deal bundle submitted by the dealer.
    event DealBundleSubmitted(uint256 dealerIdx, DealBundle bundle);

    /// @notice Emitted when a valid complaint is submitted during the complaint phase.
    /// @param from The address of the participant who submitted the complaint.
    /// @param evicted The index of the dealer who is evicted from the network.
    event ValidComplaint(address from, uint32 evicted);
}

/// @title Distributed Key Generation
/// @notice This contract implements the trusted mediator for the Deji DKG protocol.
/// @dev The DKG protocol is a three-phase protocol. In the first phase, authorized nodes register as partcipants
/// In the second phase, participants submit their deals.
/// In the third phase, participants submit complaints for invalid deals.
/// The contract verifies the commitments and computes the public key based on valid commitments.
/// @author Cryptonet
contract DKG is ThresholdNetwork, IDKG {
    using Bn128 for G1Point;

    /// @notice The maximum number of participants
    uint16 public constant MAX_PARTICIPANTS = 1000;

    /// @notice Each phase lasts 10 blocks
    uint8 public constant BLOCKS_PER_PHASE = 10;

    /// @notice The block number at which this contract is deployed
    uint256 public initTime;

    /// @notice The ending block number for each phase
    uint256 public registrationTime;
    uint256 public dealTime;
    uint256 public complaintTime;

    /// @notice Maps participant index to hash of their deal
    mapping(uint32 => uint256) private dealHashes;

    /// @notice Maps participant address to their index in the DKG
    mapping(address => uint32) private addressIndex;

    /// @notice List of index of the nodes currently registered
    uint32[] private nodeIndex;

    /// @notice Number of nodes registered
    /// @dev serves to designate the index
    uint32 private nbRegistered = 0;

    /// @notice The parent factory which deployed this contract
    DKGFactory private factory;

    modifier onlyRegistered() {
        if (addressIndex[msg.sender] == 0) {
            revert NotRegistered();
        }
        _;
    }

    modifier onlyAuthorized() {
        if (!factory.isAuthorizedNode(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyPhase(Phase phase) {
        if (phase == Phase.REGISTRATION) {
            if (!isInRegistrationPhase()) {
                revert InvalidPhase();
            }
        } else if (phase == Phase.DEAL) {
            if (!isInDealPhase()) {
                revert InvalidPhase();
            }
        } else if (phase == Phase.COMPLAINT) {
            if (!isInComplaintPhase()) {
                revert InvalidPhase();
            }
        } else if (phase == Phase.DONE) {
            if (!isDone()) {
                revert InvalidPhase();
            }
        }
        _;
    }

    /// @notice Create a new DKG with an empty public key
    /// @dev The public key is aggregated in "real time" for each new deal or new valid complaint transaction
    constructor(DKGFactory _factory) ThresholdNetwork(Bn128.g1Zero()) {
        initTime = blockNumber();
        registrationTime = initTime + BLOCKS_PER_PHASE;
        dealTime = registrationTime + BLOCKS_PER_PHASE;
        complaintTime = dealTime + BLOCKS_PER_PHASE;
        factory = _factory;
    }

    function isInRegistrationPhase() public view returns (bool) {
        uint256 blockNum = blockNumber();
        return blockNum >= initTime && blockNum < registrationTime;
    }

    function isInDealPhase() public view returns (bool) {
        uint256 blockNum = blockNumber();
        return blockNum >= registrationTime && blockNum < dealTime;
    }

    function isInComplaintPhase() public view returns (bool) {
        uint256 blockNum = blockNumber();
        return blockNum >= dealTime && blockNum < complaintTime;
    }

    function isDone() public view returns (bool) {
        uint256 blockNum = blockNumber();
        return blockNum >= complaintTime;
    }

    /// @notice Registers a participant and assigns it an index in the group
    /// @dev Only authorized nodes from the factory can register
    /// @param _tmpKey The temporary key of the participant
    /// @custom:todo make it payable in a super contract
    function registerParticipant(uint256 _tmpKey) external onlyAuthorized onlyPhase(Phase.REGISTRATION) {
        if (nbRegistered >= MAX_PARTICIPANTS) {
            revert ParticipantLimit();
        }
        // TODO check for BN128 subgroup instead
        //require(_tmpKey != 0, "Invalid key");
        // TODO check for uniqueness of the key as well
        if (addressIndex[msg.sender] != 0) {
            revert AlreadyRegistered();
        }
        // index will start at 1
        nbRegistered++;
        uint32 index = nbRegistered;
        nodeIndex.push(index);
        addressIndex[msg.sender] = index;
        emit NewParticipant(msg.sender, index, _tmpKey);
    }

    // TODO
    //function dealHash(DealBundle memory _bundle) pure returns (uint256) {
    //uint comm_len = 2 * 32 * _bundle.commitment.length;
    //share_len = _bundle.shares.length * (2 + 32*2 + 32);
    //uint32 len32 = (comm_len + share_len) / 4;
    //uint32[] memory hash = new uint32[](len32);
    //for
    //}

    /// @notice Submit a deal bundle
    /// @dev Can only be called by registered nodes while in the deal phase
    /// @param _bundle The deal bundle; a struct containing the random point, the indices of the nodes to which the shares are encrypted,
    /// the encrypted shares and the commitments to the shares
    function submitDealBundle(DealBundle calldata _bundle) external onlyRegistered onlyPhase(Phase.DEAL) {
        uint32 index = indexOfSender();
        // 1. Check he submitted enough encrypted shares
        // We expect the dealer to submit his own too.
        // TODO : do we have too ?
        if (_bundle.encryptedShares.length != numberParticipants()) {
            revert InvalidSharesCount();
        }
        // 2. Check he submitted enough committed coefficients
        // TODO Check actual bn128 check on each of them
        uint256 len = threshold();
        if (_bundle.commitment.length != len) {
            revert InvalidCommitmentsCount();
        }
        // 3. Check that commitments are all on the bn128 curve by decompressing
        // them
        // TODO hash
        //uint256[] memory compressed = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            // TODO save the addition of those if successful later
            //comms[i] = Bn128.g1Decompress(bytes32(_commitment[i]));
            if (!_bundle.commitment[i].isG1PointOnCurve()) {
                revert InvalidCommitment(i);
            }
            //compressed[i] = uint256(Bn128.g1Compress(_commitment[i]));
        }
        // 3. Compute and store the hash
        //bytes32 comm = keccak256(abi.encodePacked(_encrypted_shares,compressed));
        // TODO check it is not done before
        //deal_hashes[indexOfSender()] = uint256(comm);
        // 4. add the key to the aggregated key
        distKey = distKey.g1Add(_bundle.commitment[0]);
        // 5. emit event
        //emit DealBundleSubmitted(index, _bundle);
        emitDealBundle(index, _bundle);
    }

    /// @notice Submit a complaint against a deal
    /// @dev The complaint is valid if the deal is not valid and the complainer
    /// has a share of the deal
    /* /// @param _index The index of the deal to complain against
    /// @param _encryptedShare The encrypted share of the complainer
    /// @param _commitment The commitment of the complainer
    /// @param _deal The deal to complain against */
    /// @custom:todo Implement
    function submitComplaintBundle() external onlyRegistered onlyPhase(Phase.COMPLAINT) {
        // TODO
        emit ValidComplaint(msg.sender, 0);
    }

    function numberParticipants() public view returns (uint256) {
        return nbRegistered;
    }

    // Returns the list of indexes of QUALIFIED participants at the end of the DKG.
    function participantIndexes() public view onlyPhase(Phase.DONE) returns (uint32[] memory) {
        return nodeIndex;
    }

    function distributedKey() public view override onlyPhase(Phase.DONE) returns (G1Point memory) {
        //return uint256(Bn128.g1Compress(distKey));
        return distKey;
    }

    function threshold() public view returns (uint256) {
        return numberParticipants() / 2 + 1;
    }

    function indexOfSender() public view returns (uint32) {
        return addressIndex[msg.sender];
    }

    function emitDealBundle(uint32 _index, DealBundle memory _bundle) private {
        emit DealBundleSubmitted(_index, _bundle);
    }

    /// @notice returns the current block number of the chain of execution
    /// @dev Calling block.number on Arbitrum returns the L1 block number, which is not desired
    function blockNumber() private view returns (uint256) {
        if (block.chainid == ARBITRUM_ONE || block.chainid == ARBITRUM_GOERLI) {
            return ArbSys(address(100)).arbBlockNumber();
        } else {
            return block.number;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DKG} from "./DKG.sol";

/// @title DKGFactory
/// @author Cryptonet
/// @notice Factory contract for creating DKGs
/// @dev Deploys new DKGs and registers a unique id for each
contract DKGFactory is Ownable {
    /// @notice List of launched dkg addresses
    mapping(address => bool) public dkgAddresses;

    /// @notice Mapping of authorized node addresses
    mapping(address => bool) public authorizedNodes;

    /// @notice Emitted when a new DKG is deployed
    /// @param dkg The address of the deployed DKG
    event NewDKGCreated(address dkg);

    /// @notice Deploys a new DKG
    /// @dev Only the Factory owner can deploy a new DKG
    /// @return The id and address of the new DKG
    function deployNewDKG() public onlyOwner returns (address) {
        DKG dkg = new DKG(this);
        dkgAddresses[address(dkg)] = true;
        emit NewDKGCreated(address(dkg));
        return address(dkg);
    }

    function isAuthorizedNode(address node) external view returns (bool) {
        return authorizedNodes[node];
    }

    function addAuthorizedNode(address node) external onlyOwner {
        authorizedNodes[node] = true;
    }

    function removeAuthorizedNode(address node) external onlyOwner {
        delete authorizedNodes[node];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Suite} from "./OracleFactory.sol";
import {ThresholdNetwork} from "./DKG.sol";
import {Bn128, G1Point, DleqProof} from "./Bn128.sol";

/// @notice A 32-byte encrypted ciphertext
struct Ciphertext {
    G1Point random;
    uint256 cipher;
    /// DLEQ part
    G1Point random2;
    DleqProof dleq;
}

interface IEncryptionClient {
    /// @notice Callback to client contract when medusa posts a result
    /// @dev Implement in client contracts of medusa
    /// @param requestId The id of the original request
    /// @param _cipher the reencryption result
    function oracleResult(
        uint256 requestId,
        Ciphertext calldata _cipher
    ) external;
}

interface IEncryptionOracle {
    function requestReencryption(
        uint256 _cipherId,
        G1Point calldata _publickey
    ) external returns (uint256);

    /// @notice submit a ciphertext that can be retrieved at the given link and
    /// has been created by this encryptor address. The ciphertext proof is checked
    /// and if correct, being signalled to Medusa.
    function submitCiphertext(
        Ciphertext calldata _cipher,
        bytes calldata _link,
        address _encryptor
    ) external returns (uint256);

    function deliverReencryption(
        uint256 _requestId,
        Ciphertext calldata _cipher
    ) external returns (bool);

    /// @notice All instance contracts must implement their own encryption suite
    /// @dev e.g. BN254_KEYG1_HGAMAL
    /// @return suite of curve + encryption params supported by this contract
    function suite() external pure virtual returns (Suite);

    /// @notice Emitted when a new cipher text is registered with medusa
    /// @dev Broadcasts the id, cipher text, and client or owner of the cipher text
    event NewCiphertext(
        uint256 indexed id,
        Ciphertext ciphertext,
        bytes link,
        address client
    );

    /// @notice Emitted when a new request is sent to medusa
    /// @dev Requests can be sent by clients that do not own the cipher text; must verify the request off-chain
    event ReencryptionRequest(
        uint256 indexed cipherId,
        uint256 requestId,
        G1Point publicKey,
        address client
    );
}

/// @notice Reverts when delivering a response for a non-existent request
error RequestDoesNotExist();

/// @notice Reverts when the client's callback function reverts
error OracleResultFailed(string errorMsg);

/// @notice invalid ciphertext proof. This can happen when one submits a ciphertext
/// being made for one chainid, or for one smart contract  but is being submitted
/// to another.
error InvalidCiphertextProof();

/// @title An abstract EncryptionOracle that receives requests and posts results for reencryption
/// @notice You must implement your encryption suite when inheriting from this contract
/// @dev DOES NOT currently validate reencryption results OR implement fees for the medusa oracle network
abstract contract EncryptionOracle is
    ThresholdNetwork,
    IEncryptionOracle,
    Ownable,
    Pausable
{
    /// @notice A pending reencryption request
    /// @dev client client's address to callback with a response
    struct PendingRequest {
        address client;
    }

    /// @notice pendingRequests tracks the reencryption requests
    /// @dev We use this to determine the client to callback with the result
    mapping(uint256 => PendingRequest) private pendingRequests;

    /// @notice counter to derive unique nonces for each ciphertext
    uint256 private cipherNonce = 0;

    /// @notice counter to derive unique nonces for each reencryption request
    uint256 private requestNonce = 0;

    /// @notice Create a new oracle contract with a distributed public key
    /// @dev The distributed key is created by an on-chain DKG process
    /// @dev Verify the key by checking all DKG contracts deployed by Medusa operators
    /// @notice The public key corresponding to the distributed private key registered for this contract
    /// @dev This is passed in by the OracleFactory. Corresponds to an x-y point on an elliptic curve
    /// @param _distKey An x-y point representing a public key previously created by medusa nodes
    constructor(G1Point memory _distKey) ThresholdNetwork(_distKey) {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Submit a new ciphertext and emit an event
    /// @dev We only emit an event; no storage. We authorize future requests for this ciphertext off-chain.
    /// @param _cipher The ciphertext of an encrypted key
    /// @param _link The link to the encrypted contents
    /// @return the id of the newly registered ciphertext
    function submitCiphertext(
        Ciphertext calldata _cipher,
        bytes calldata _link,
        address _encryptor
    ) external whenNotPaused returns (uint256) {
        uint256 label = uint256(
            sha256(
                abi.encodePacked(distKey.x, distKey.y, msg.sender, _encryptor)
            )
        );
        if (
            !Bn128.dleqverify(
                _cipher.random,
                _cipher.random2,
                _cipher.dleq,
                label
            )
        ) {
            revert InvalidCiphertextProof();
        }
        uint256 id = newCipherId();
        emit NewCiphertext(id, _cipher, _link, msg.sender);
        return id;
    }

    /// @notice Request reencryption of a cipher text for a user
    /// @dev msg.sender must be The "owner" or submitter of the ciphertext or the oracle will not reply
    /// @param _cipherId the id of the ciphertext to reencrypt
    /// @param _publicKey the public key of the recipient
    /// @return the reencryption request id
    /// @custom:todo Payable; users pay for the medusa network somehow (oracle gas + platform fee)
    function requestReencryption(
        uint256 _cipherId,
        G1Point calldata _publicKey
    ) external whenNotPaused returns (uint256) {
        /// @custom:todo check correct key
        uint256 requestId = newRequestId();
        pendingRequests[requestId] = PendingRequest(msg.sender);
        emit ReencryptionRequest(_cipherId, requestId, _publicKey, msg.sender);
        return requestId;
    }

    /// @notice Oracle delivers the reencryption result
    /// @dev Needs to verify the request, result and then callback to the client
    /// @param _requestId the pending request id; used to callback the correct client
    /// @param _cipher The reencryption result for the request
    /// @return true if the client callback succeeds, otherwise reverts with OracleResultFailed
    function deliverReencryption(
        uint256 _requestId,
        Ciphertext calldata _cipher
    ) external whenNotPaused returns (bool) {
        /// @custom:todo We need to verify a threshold signature to verify the cipher result
        if (!requestExists(_requestId)) {
            revert RequestDoesNotExist();
        }
        PendingRequest memory pr = pendingRequests[_requestId];
        delete pendingRequests[_requestId];
        IEncryptionClient client = IEncryptionClient(pr.client);
        try client.oracleResult(_requestId, _cipher) {
            return true;
        } catch Error(string memory reason) {
            revert OracleResultFailed(reason);
        } catch {
            revert OracleResultFailed(
                "Client does not support oracleResult() method"
            );
        }
    }

    function newCipherId() private returns (uint256) {
        cipherNonce += 1;
        return cipherNonce;
    }

    function newRequestId() private returns (uint256) {
        requestNonce += 1;
        return requestNonce;
    }

    function requestExists(uint256 id) private view returns (bool) {
        PendingRequest memory pr = pendingRequests[id];
        return pr.client != address(0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BN254EncryptionOracle} from "./BN254EncryptionOracle.sol";
import {EncryptionOracle} from "./EncryptionOracle.sol";
import {G1Point} from "./Bn128.sol";

/// @notice An enum of supported encryption suites
/// @dev The format is CURVE_KEYGROUP_ENCRYPTION
enum Suite {
    BN254_KEYG1_HGAMAL
}

/// @title OracleFactory
/// @author Cryptonet
/// @notice Factory contract for creating encryption oracles
/// @dev Deploys new oracles with a specified distributed key and encryption suite
/// @dev The factory contract is the owner of all oracles it deploys
contract OracleFactory is Ownable {
    /// @notice List of running oracles
    mapping(address => bool) public oracles;

    /// @notice Emitted when a new oracle is deployed
    event NewOracleDeployed(address oracle, Suite suite);

    /// @notice Deploys a new oracle with the specified distributed key and encryption suite
    /// @dev Only the Factory owner can deploy a new oracle
    /// @param _distKey The distributed key previously created by a DKG process
    /// @return The id and address of the new oracle
    function deployReencryption_BN254_G1_HGAMAL(
        G1Point calldata _distKey,
        address relayer
    ) external onlyOwner returns (address) {
        EncryptionOracle oracle;
        oracle = new BN254EncryptionOracle(_distKey, relayer);

        oracles[address(oracle)] = true;

        emit NewOracleDeployed(address(oracle), Suite.BN254_KEYG1_HGAMAL);
        return address(oracle);
    }

    function pauseOracle(address _oracle) public onlyOwner {
        require(oracles[_oracle], "no oracle at this address registered");
        EncryptionOracle oracle = EncryptionOracle(_oracle);
        oracle.pause();
    }

    function unpauseOracle(address _oracle) public onlyOwner {
        require(oracles[_oracle], "no oracle at this address registered");
        EncryptionOracle oracle = EncryptionOracle(_oracle);
        oracle.unpause();
    }

    function updateRelayer(
        address _oracle,
        address _newRelayer
    ) public onlyOwner {
        require(oracles[_oracle], "no oracle at this address registered");
        EncryptionOracle oracle = EncryptionOracle(_oracle);
        // oracle.updateRelayer(_newRelayer);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {BN254EncryptionOracle as Oracle} from "./medusa/BN254EncryptionOracle.sol";
import {IEncryptionClient, Ciphertext} from "./medusa/EncryptionOracle.sol";
import {G1Point} from "./medusa/Bn128.sol";
import {PullPayment} from "@openzeppelin/contracts/security/PullPayment.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error CallbackNotAuthorized();
error ListingDoesNotExist();
error CallerIsNotNftOwner();

// struct Listing {
//     address seller;
//     uint256 cipherId;
// }

contract PrivateDoc is IEncryptionClient, PullPayment {
    /// @notice The Encryption Oracle Instance
    Oracle public oracle;
    address public nft;

    /// @notice A mapping from cipherId to listing
    mapping(string => uint256) public listings;

    event ListingDecryption(uint256 indexed requestId, Ciphertext ciphertext);

    event NewListing(
        address indexed seller,
        uint256 indexed cipherId,
        string uri
    );

    event NewSale(
        address indexed seller,
        uint256 requestId,
        uint256 cipherId,
        string uri
    );

    modifier onlyOracle() {
        if (msg.sender != address(oracle)) {
            revert CallbackNotAuthorized();
        }
        _;
    }

    constructor(Oracle _oracle, address _nft) {
        oracle = _oracle;
        nft = _nft;
    }

    /// @notice Create a new listing
    /// @dev Submits a ciphertext to the oracle, stores a listing, and emits an event
    /// @return cipherId The id of the ciphertext associated with the new listing
    function createListing(
        Ciphertext calldata cipher,
        string calldata uri
    ) external returns (uint256 cipherId) {
        try oracle.submitCiphertext(cipher, bytes("0x"), msg.sender) returns (
            uint256
        ) {
            listings[uri] = cipherId;
            emit NewListing(msg.sender, cipherId, uri);
            return cipherId;
        } catch {
            require(false, "Call to Medusa oracle failed");
        }
    }

    /// @notice Pay for a listing
    /// @dev Buyer pays the price for the listing, which can be withdrawn by the seller later; emits an event
    /// @return requestId The id of the reencryption request associated with the purchase
    function buyListing(
        string memory _uri,
        G1Point calldata buyerPublicKey
    ) external payable returns (uint256) {
        // Listing memory listing = listings[uri];
        // if (listing.seller == address(0)) {
        //     revert ListingDoesNotExist();
        // }

        // if (ERC721(nft).balanceOf(msg.sender) < 1) {
        //     revert InsufficentFunds();
        // }
        (bool success, bytes memory check) = nft.call(
            abi.encodeWithSignature("balanceOf(address)", msg.sender)
        );

        if (!success || check[0] == 0) {
            revert CallerIsNotNftOwner();
        }

        // _asyncTransfer(listing.seller, msg.value);
        uint256 requestId = oracle.requestReencryption(
            listings[_uri],
            buyerPublicKey
        );
        emit NewSale(msg.sender, requestId, listings[_uri], _uri);
        return requestId;
    }

    function getCipherIdFromUri(
        string memory _uri
    ) public view returns (uint256) {
        return listings[_uri];
    }

    /// @inheritdoc IEncryptionClient
    function oracleResult(
        uint256 requestId,
        Ciphertext calldata cipher
    ) external onlyOracle {
        emit ListingDecryption(requestId, cipher);
    }

    /// @notice Convenience function to get the public key of the oracle
    /// @dev This is the public key that sellers should use to encrypt their listing ciphertext
    /// @dev Note: This feels like a nice abstraction, but it's not strictly necessary
    function publicKey() external view returns (G1Point memory) {
        return oracle.distributedKey();
    }
}