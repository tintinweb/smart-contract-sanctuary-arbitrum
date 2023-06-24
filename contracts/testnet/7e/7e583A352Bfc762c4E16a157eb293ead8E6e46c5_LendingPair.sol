// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library AddressLibrary {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.6;

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
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt)
        internal
        returns (address instance)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address master,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./AddressLibrary.sol";

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
    using SafeMath for uint256;
    using AddressLibrary for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

import "../interfaces/IOwnable.sol";

contract SafeOwnable is IOwnable {
    uint public constant RENOUNCE_TIMEOUT = 1 hours;

    address public override owner;
    address public pendingOwner;
    uint public renouncedAt;

    event OwnershipTransferInitiated(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferConfirmed(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferConfirmed(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function transferOwnership(address _newOwner) external override onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferInitiated(owner, _newOwner);
        pendingOwner = _newOwner;
    }

    function acceptOwnership() external override {
        require(
            msg.sender == pendingOwner,
            "Ownable: caller is not pending owner"
        );
        emit OwnershipTransferConfirmed(msg.sender, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function initiateRenounceOwnership() external onlyOwner {
        require(renouncedAt == 0, "Ownable: already initiated");
        renouncedAt = block.timestamp;
    }

    function acceptRenounceOwnership() external onlyOwner {
        require(renouncedAt > 0, "Ownable: not initiated");
        require(
            block.timestamp - renouncedAt > RENOUNCE_TIMEOUT,
            "Ownable: too early"
        );
        owner = address(0);
        pendingOwner = address(0);
        renouncedAt = 0;
    }

    function cancelRenounceOwnership() external onlyOwner {
        require(renouncedAt > 0, "Ownable: not initiated");
        renouncedAt = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

interface ICallee {
    function wildCall(bytes calldata _data) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function decimals() external view returns (uint8);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

import "./IOwnable.sol";
import "./IUnifiedOracleAggregator.sol";

interface ILendingController is IOwnable {
    function oracleAggregator()
        external
        view
        returns (IUnifiedOracleAggregator);

    function liqFeeSystem(address _token) external view returns (uint256);

    function liqFeeCaller(address _token) external view returns (uint256);

    function uniMinOutputPct() external view returns (uint256);

    function colFactor(address _token) external view returns (uint256);

    function defaultColFactor() external view returns (uint256);

    function depositLimit(address _lendingPair, address _token)
        external
        view
        returns (uint256);

    function borrowLimit(address _lendingPair, address _token)
        external
        view
        returns (uint256);

    function depositsEnabled() external view returns (bool);

    function borrowingEnabled() external view returns (bool);

    function tokenPrice(address _token) external view returns (uint256);

    function minBorrow(address _token) external view returns (uint256);

    function tokenPrices(address _tokenA, address _tokenB)
        external
        view
        returns (uint256, uint256);

    function tokenSupported(address _token) external view returns (bool);

    function isBaseAsset(address _token) external view returns (bool);

    function minObservationCardinalityNext() external view returns (uint16);

    function preparePool(address _tokenA, address _tokenB) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

interface ILendingPair {
    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function lpToken(address _token) external view returns (address);

    function transferLp(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function supplySharesOf(
        address _token,
        address _account
    ) external view returns (uint256);

    function totalSupplyShares(address _token) external view returns (uint256);

    function totalSupplyAmount(address _token) external view returns (uint256);

    function totalDebtShares(address _token) external view returns (uint256);

    function totalDebtAmount(address _token) external view returns (uint256);

    function debtOf(
        address _token,
        address _account
    ) external view returns (uint256);

    function supplyOf(
        address _token,
        address _account
    ) external view returns (uint256);

    function pendingSystemFees(address _token) external view returns (uint256);

    function supplyBalanceConverted(
        address _account,
        address _suppliedToken,
        address _returnToken
    ) external view returns (uint256);

    function initialize(
        address _lpTokenMaster,
        address _lendingController,
        address _feeRecipient,
        address _tokenA,
        address _tokenB
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

import "./IOwnable.sol";
import "./IERC20.sol";

interface ILPTokenMaster is IOwnable, IERC20 {
    function initialize(address _underlying, address _lendingController)
        external;

    function underlying() external view returns (address);

    function lendingPair() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

interface IPriceOracle {
    function tokenPrice(address _token) external view returns (uint256);

    function tokenSupported(address _token) external view returns (bool);

    function convertTokenValues(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./IPriceOracle.sol";
import "../external/SafeOwnable.sol";

interface IExternalOracle {
    function price(address _token) external view returns (uint256);

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

/// @title Oracle aggergator for uni and link oracles
/// @author flora.loans
/// @notice Owner can set Chainlink oracles for specific tokens
/// @notice returns the token price from chainlink oracle (if available) otherwise the uni oracle will be used
/// @dev
/// @custom:this contract is configured for Arbitrum mainnet
interface IUnifiedOracleAggregator {
    function setOracle(address, IExternalOracle) external;

    function preparePool(
        address,
        address,
        uint16
    ) external;

    function tokenSupported(address) external view returns (bool);

    function tokenPrice(address) external view returns (uint256);

    function tokenPrices(address, address)
        external
        view
        returns (uint256, uint256);

    /// @dev Not used in any code to save gas. But useful for external usage.
    function convertTokenValues(
        address,
        address,
        uint256
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) FloraLoans - All rights reserved
// https://twitter.com/Flora_Loans

/* TODO`s
    - to think about: locking withdrawals user based for some blocks after deposit(check for oracle manipulation)

*/
pragma solidity ^0.8.6;

import "./interfaces/IERC20.sol";
import "./interfaces/ICallee.sol";
import "./interfaces/ILendingPair.sol";
import "./interfaces/ILPTokenMaster.sol";
import "./interfaces/ILendingController.sol";

import "./external/Math.sol";
import "./external/Clones.sol";
import "./external/ReentrancyGuard.sol";
import "./external/AddressLibrary.sol";

import "./LPTokenMaster.sol";
import "./TransferHelper.sol";
import "./LendingPairEvents.sol";

/// @title Lending Pair Contract
/// @author 0xdev and flora.loans
/// @notice This contract contains all functionality of an effective LendingPair, including deposit, borrow, withdraw and the liquidation mechanism

contract LendingPair is
    ILendingPair,
    LendingPairEvents,
    ReentrancyGuard,
    TransferHelper
{
    using AddressLibrary for address;
    using Clones for address;

    struct InterestRateModel {
        uint256 lpRate;
        uint256 minRate;
        uint256 lowRate;
        uint256 highRate;
        uint256 targetUtilization;
    }

    struct AccountingData {
        uint256 totalSupplyShares;
        uint256 totalSupplyAmount;
        uint256 totalDebtShares;
        uint256 totalDebtAmount;
        mapping(address => uint256) supplySharesOf;
        mapping(address => uint256) debtSharesOf;
    }

    /// CONSTANTS
    uint256 public constant LIQ_MIN_HEALTH = 1e18;
    uint256 private constant MIN_DECIMALS = 6;
    address public feeRecipient;
    ILendingController public lendingController;

    /// Token related
    address public override tokenA;
    address public override tokenB;
    mapping(address => uint256) private decimals;
    mapping(address => uint256) public colFactor;
    mapping(address => address) public override lpToken;
    mapping(address => uint256) public override pendingSystemFees;
    mapping(address => uint256) public lastBlockAccrued;

    /// Protocol
    InterestRateModel public irm;
    mapping(address => AccountingData) internal accounting;

    /// Modifier
    modifier onlyLpToken() {
        require(
            lpToken[tokenA] == msg.sender || lpToken[tokenB] == msg.sender,
            "LendingController: caller must be LP token"
        );
        _;
    }
    modifier onlyOwner() {
        require(
            msg.sender == lendingController.owner(),
            "LendingPair: caller is not the owner"
        );
        _;
    }

    constructor(IWETH _WETH) TransferHelper(_WETH) {}

    /// =======================================================================
    /// ======================= INIT ==========================================
    /// =======================================================================

    /// @notice called once by the PairFactory after the creation of a new Pair
    function initialize(
        address _lpTokenMaster,
        address _lendingController,
        address _feeRecipient,
        address _tokenA,
        address _tokenB
    ) external override {
        require(tokenA == address(0), "LendingPair: already initialized");

        lendingController = ILendingController(_lendingController);

        feeRecipient = _feeRecipient;
        tokenA = _tokenA;
        tokenB = _tokenB;
        lastBlockAccrued[tokenA] = block.number;
        lastBlockAccrued[tokenB] = block.number;

        decimals[tokenA] = IERC20(tokenA).decimals();
        decimals[tokenB] = IERC20(tokenB).decimals();

        require(
            decimals[tokenA] >= MIN_DECIMALS &&
                decimals[tokenB] >= MIN_DECIMALS,
            "LendingPair: MIN_DECIMALS"
        );

        lpToken[tokenA] = _createLpToken(_lpTokenMaster, tokenA);
        lpToken[tokenB] = _createLpToken(_lpTokenMaster, tokenB);

        colFactor[_tokenA] = lendingController.defaultColFactor();
        colFactor[_tokenB] = lendingController.defaultColFactor();

        // Initialize Interest rate model
        // Need to check then if calculations still match with new units
        irm.lpRate = 70e18; // Percentage of debt-interest received by the suppliers
        irm.minRate = 0;
        irm.lowRate = 7642059868087; // 20%
        irm.highRate = 382102993404363; // 1,000%
        irm.targetUtilization = 90e18; // Must be < 100e18; @todo could also use uint16: 90
    }

    ///
    ///
    /// =======================================================================
    /// ======================= USER CORE ACTIONS =============================
    /// =======================================================================
    ///
    ///

    /// @notice deposit either tokenA or tokenB
    /// @param _account address of the account to credit the deposit to
    /// @param _token token to deposit
    /// @param _amount amount to deposit
    function deposit(
        address _account,
        address _token,
        uint256 _amount
    ) external payable nonReentrant {
        if (msg.value > 0) {
            _depositWeth();
            _safeTransfer(address(WETH), msg.sender, msg.value);
        }
        _deposit(_account, _token, _amount);
    }

    /// @notice withdraw either tokenA or tokenB
    /// @param _recipient address of the account receiving the tokens
    /// @param _token token to withdraw
    /// @param _amount amount to withdraw
    function withdraw(
        address _recipient,
        address _token,
        uint256 _amount
    ) external nonReentrant {
        _withdraw(_recipient, _token, _amount);
        _checkAccountHealth(msg.sender);
        _checkReserve(_token);
    }

    /// @notice withdraw the whole amount of either tokenA or tokenB
    /// @param _recipient address of the account to transfer the tokens to
    /// @param _token token to withdraw
    function withdrawAll(
        address _recipient,
        address _token
    ) external nonReentrant {
        _withdrawAll(_recipient, _token);
        _checkAccountHealth(msg.sender);
        _checkReserve(_token);
    }

    /// @notice borrow either tokenA or tokenB
    /// @param _recipient address of the account to transfer the tokens to
    /// @param _token token to borrow
    /// @param _amount amount to borrow
    function borrow(
        address _recipient,
        address _token,
        uint256 _amount
    ) external nonReentrant {
        _borrow(_recipient, _token, _amount);
        _checkAccountHealth(msg.sender);
        _checkReserve(_token);
    }

    /// @notice repay either tokenA or tokenB
    /// @param _account address of the account to reduce the debt for
    /// @param _token token to repay
    /// @param _maxAmount maximum amount willing to repay
    /// @dev debt can increase due to accrued interest
    function repay(
        address _account,
        address _token,
        uint256 _maxAmount
    ) external payable nonReentrant {
        if (msg.value > 0) {
            _depositWeth();
            _safeTransfer(address(WETH), msg.sender, msg.value);
        }
        _repay(_account, _token, _maxAmount);
    }

    ///
    ///
    /// =======================================================================
    /// ======================= USER ADVANCED ACTIONS =========================
    /// =======================================================================
    ///
    ///

    /// @notice transfers tokens _from -> _to
    /// @dev Non erc20 compliant, but can be wrapped by an erc20 interface
    function transferLp(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external override onlyLpToken {
        require(
            accounting[_token].debtSharesOf[_to] == 0,
            "LendingPair: cannot receive borrowed token"
        );
        accounting[_token].supplySharesOf[_from] -= _amount;
        accounting[_token].supplySharesOf[_to] += _amount;
        _checkAccountHealth(_from);
    }

    /// @notice liquidate an account to keep the protocol with good debt
    function liquidateAccount(
        address _account,
        address _repayToken,
        uint256 _repayAmount
    ) external nonReentrant {
        _liquidateAccount(_account, _repayToken, _repayAmount);
        _checkAccountHealth(msg.sender);
        _checkReserve(tokenA);
        _checkReserve(tokenB);
    }

    ///
    ///
    /// =======================================================================
    /// ======================= ADMIN & PROTOCOL ACTIONS ======================
    /// =======================================================================
    ///
    ///

    /// @notice charge interest on debt and add interest to supply
    /// @dev first accrueDebt, then credit a proportion of the newDebt to the totalSupply
    /// @dev the other part of newDebt is credited to pendingSystemFees
    function accrue(address _token) public {
        if (lastBlockAccrued[_token] < block.number) {
            uint256 newDebt = _accrueDebt(_token);
            uint256 newSupply = (newDebt * irm.lpRate) / 100e18;
            accounting[_token].totalSupplyAmount += newSupply;

            // @Note rounding errors should not exsits anymore, but leave it here to be save
            // '-1' helps prevent _checkReserve fails due to rounding errors
            uint256 newFees = (newDebt - newSupply) == 0
                ? 0
                : (newDebt - newSupply - 1);
            pendingSystemFees[_token] += newFees;

            lastBlockAccrued[_token] = block.number;
        }
    }

    /// @notice transfer the current pending fees (protocol fees) to the feeRecipient
    function collectSystemFee(
        address _token,
        uint256 _amount
    ) external nonReentrant {
        _validateToken(_token);
        pendingSystemFees[_token] -= _amount;
        _safeTransfer(_token, feeRecipient, _amount);
        _checkReserve(_token);
        emit CollectSystemFee(_token, _amount);
    }

    ///
    /// =======================================================================
    /// ======================= SETTER functions ==============================
    /// =======================================================================
    ///

    /// @notice change the collateral factor for a token
    function setColFactor(address _token, uint256 _value) external onlyOwner {
        require(_value <= 99e18, "LendingPair: _value <= 99e18");
        _validateToken(_token);
        colFactor[_token] = _value;
        emit NewColFactor(_token, _value);
    }

    /// @notice sets the lpRate
    /// @notice lpRate defines the amount of interest going to the lendingPair -> liquidity providers
    /// @dev remaining percent goes to the feeRecipient -> protocol
    /// @dev 1e18 = 1%
    function setlpRate(uint256 _lpRate) external onlyOwner {
        require(_lpRate != 0, "Cannot be Zero");
        require(_lpRate <= 100e18);
        irm.lpRate = _lpRate;
        emit NewlpRate(_lpRate);
    }

    /// @notice set the parameter of the interest rate model
    function setInterestRateModel(
        uint256 _minRate,
        uint256 _lowRate,
        uint256 _highRate,
        uint256 _targetUtilization
    ) external onlyOwner {
        require(
            _targetUtilization < 100e18,
            "Target Utilization must be < 100e18"
        );
        irm.minRate = _minRate;
        irm.lowRate = _lowRate;
        irm.highRate = _highRate;
        irm.targetUtilization = _targetUtilization;

        emit NewInterestRateParameters(
            irm.minRate,
            irm.lowRate,
            irm.highRate,
            irm.targetUtilization
        );
    }

    ///
    ///
    /// =======================================================================
    /// ======================= ADVANCED GETTER ===============================
    /// =======================================================================
    ///
    ///

    /// @notice Unit conversion. Get the amount of borrowed tokens and convert it to the same value of _returnToken
    /// @return balanced borrowed represented in the units of _returnToken
    function borrowBalanceConverted(
        address _account,
        address _borrowedToken,
        address _returnToken
    ) external view returns (uint256) {
        _validateToken(_borrowedToken);
        _validateToken(_returnToken);

        (uint256 borrowPrice, uint256 returnPrice) = tokenPrices(
            _borrowedToken,
            _returnToken
        );
        return
            _borrowBalanceConverted(
                _account,
                _borrowedToken,
                _returnToken,
                borrowPrice,
                returnPrice
            );
    }

    /// @notice Unit conversion. Get the amount of supplied tokens and convert it to the same value of _returnToken
    /// @return balanced supplied represented in the units of _returnToken
    function supplyBalanceConverted(
        address _account,
        address _suppliedToken,
        address _returnToken
    ) external view override returns (uint256) {
        _validateToken(_suppliedToken);
        _validateToken(_returnToken);

        (uint256 supplyPrice, uint256 returnPrice) = tokenPrices(
            _suppliedToken,
            _returnToken
        );
        return
            _supplyBalanceConverted(
                _account,
                _suppliedToken,
                _returnToken,
                supplyPrice,
                returnPrice
            );
    }

    /// @notice Interest Rate model - supply.
    /// @dev depending on current interestRate (which depends on utilization),
    /// @return interest received on supplied tokens for the current block
    function supplyRatePerBlock(
        address _token
    ) external view returns (uint256) {
        _validateToken(_token);
        if (
            accounting[_token].totalSupplyAmount == 0 ||
            accounting[_token].totalDebtAmount == 0
        ) {
            return 0;
        }
        return
            (((_interestRatePerBlock(_token) * utilizationRate(_token)) /
                100e18) * irm.lpRate) / 100e18; // 1e18: annual interest split into interest per Block // 0e18 - 100e18 // e18
    }

    /// @notice Interest Rate model - borrow.
    /// @return interest payed on borrowed tokens for the current block
    function borrowRatePerBlock(
        address _token
    ) external view returns (uint256) {
        _validateToken(_token);
        return _interestRatePerBlock(_token);
    }

    /// @notice returns the proportion of borrowed tokens to supplied tokens
    /// @dev 0 <= x <= 100e18
    function utilizationRate(address _token) public view returns (uint256) {
        uint256 totalSupply = accounting[_token].totalSupplyAmount; //e18
        uint256 totalDebt = accounting[_token].totalDebtAmount; //e18
        if (totalSupply == 0 || totalDebt == 0) {
            return 0;
        }
        return Math.min((totalDebt * 100e18) / totalSupply, 100e18); // e20
    }

    /// @notice Unit conversion. convert the input amount (_fromToken) to the same value of _toToken
    /// @return amount of _toTokens having the same value as _inputAmount
    function convertTokenValues(
        address _fromToken,
        address _toToken,
        uint256 _inputAmount
    ) external view returns (uint256) {
        _validateToken(_fromToken);
        _validateToken(_toToken);

        (uint256 fromPrice, uint256 toPrice) = tokenPrices(
            _fromToken,
            _toToken
        );
        return
            _convertTokenValues(
                _fromToken,
                _toToken,
                _inputAmount,
                fromPrice,
                toPrice
            );
    }

    ///
    /// =======================================================================
    /// ======================= GETTER functions ==============================
    /// =======================================================================
    ///

    /// @notice Fetches the current token price
    /// @dev For the native asset: uses the oracle set in the controller
    /// @dev For the permissionless asset: uses the uniswap TWAP oracle
    /// @param _token token for which the Oracle price should be received
    /// @return quote for 1 unit of the token, priced in ETH
    function tokenPrice(address _token) public view returns (uint256) {
        return lendingController.tokenPrice(_token);
    }

    /// @notice Fetches the current token prices for both assets
    /// @dev calls tokenPrice() for each asset
    /// @param _tokenA first token for which the Oracle price should be received
    /// @param _tokenB second token for which the Oracle price should be received
    /// @return oracle price of each asset priced in 1 unit swapped for eth
    /// Note: Might adapt this call to be called without any argutments
    /// Note: check if I should use external internal pattern
    function tokenPrices(
        address _tokenA,
        address _tokenB
    ) public view returns (uint256, uint256) {
        return lendingController.tokenPrices(_tokenA, _tokenB);
    }

    /// @notice checks the current health of an _account, the health represents the ratio of collateral to debt
    /// @notice health should be > 1
    function accountHealth(address _account) external view returns (uint256) {
        (uint256 priceA, uint256 priceB) = tokenPrices(tokenA, tokenB);
        return _accountHealth(_account, priceA, priceB);
    }

    /// ======================================================================
    /// =============== Accounting for tokens and shares =====================
    /// ======================================================================

    /// @notice check the debt of an account
    /// @return number of _token owed
    function debtOf(
        address _token,
        address _account
    ) external view override returns (uint256) {
        _validateToken(_token);
        return _debtOf(_token, _account);
    }

    /// @notice check the balance of an account
    /// @return balance of _token supplied
    function supplyOf(
        address _token,
        address _account
    ) external view override returns (uint256) {
        _validateToken(_token);
        return _supplyOf(_token, _account);
    }

    /// @notice Returns the debt shares of a user for a specific token
    /// @param token The address of the token
    /// @param user The address of the user
    /// @return The amount of debt shares for the user and token
    function debtSharesOf(
        address token,
        address user
    ) public view returns (uint256) {
        return accounting[token].debtSharesOf[user];
    }

    /// @notice Returns the supply shares of a user for a specific token
    /// @param token The address of the token
    /// @param user The address of the user
    /// @return The amount of supply shares for the user and token
    function supplySharesOf(
        address token,
        address user
    ) public view returns (uint256) {
        return accounting[token].supplySharesOf[user];
    }

    /// @notice Returns the total supply shares of a specific token
    /// @param token The address of the token
    /// @return The total supply shares for the token
    function totalSupplyShares(address token) public view returns (uint256) {
        return accounting[token].totalSupplyShares;
    }

    /// @notice Returns the total supply amount of a specific token
    /// @param token The address of the token
    /// @return The total supply amount for the token
    function totalSupplyAmount(address token) public view returns (uint256) {
        return accounting[token].totalSupplyAmount;
    }

    /// @notice Returns the total debt shares of a specific token
    /// @param token The address of the token
    /// @return The total debt shares for the token
    function totalDebtShares(address token) public view returns (uint256) {
        return accounting[token].totalDebtShares;
    }

    /// @notice Returns the total debt amount of a specific token
    /// @param token The address of the token
    /// @return The total debt amount for the token
    function totalDebtAmount(address token) public view returns (uint256) {
        return accounting[token].totalDebtAmount;
    }

    ///
    ///
    /// =======================================================================
    /// ======================= INTERNAL functions ============================
    /// =======================================================================
    ///
    ///

    /// @notice deposit a token into the pair (as collateral)
    /// @dev mints new supply shares
    /// @dev folding is prohibited (deposit and borrow the same token)
    function _deposit(
        address _account,
        address _token,
        uint256 _amount
    ) internal {
        _validateToken(_token);
        accrue(_token);

        require(
            accounting[_token].debtSharesOf[_account] == 0,
            "LendingPair: cannot deposit borrowed token"
        );

        _mintSupplyAmount(_token, _account, _amount);
        _safeTransferFrom(_token, msg.sender, _amount);

        emit Deposit(_account, _token, _amount);
    }

    /// @notice withdraw a specified amount of collateral to a recipient
    /// @dev health and credit are not checked
    /// @dev accrues interest and calls _withdrawShares with updated supply
    function _withdraw(
        address _recipient,
        address _token,
        uint256 _amount
    ) internal {
        _validateToken(_token);
        accrue(_token);

        // Fix rounding error:
        uint256 _shares = _supplyToShares(_token, _amount);
        if (_sharesToSupply(_token, _shares) < _amount) {
            ++_shares;
        }

        _withdrawShares(_token, _shares);
        _transferAsset(_token, _recipient, _amount);
    }

    /// @notice borrow a specified amount and check pair related boundary conditions.
    /// @dev the health/collateral is not checked. Calling this can borrow any amount available
    function _borrow(
        address _recipient,
        address _token,
        uint256 _amount
    ) internal {
        _validateToken(_token);
        accrue(_token);

        require(
            accounting[_token].supplySharesOf[msg.sender] == 0,
            "LendingPair: cannot borrow supplied token"
        );

        _mintDebtAmount(_token, msg.sender, _amount);
        _transferAsset(_token, _recipient, _amount);

        emit Borrow(msg.sender, _token, _amount);
    }

    /// @notice withdraw all collateral of _token to a recipient
    function _withdrawAll(address _recipient, address _token) internal {
        _validateToken(_token);
        accrue(_token);

        uint256 shares = accounting[_token].supplySharesOf[msg.sender];
        uint256 amount = _sharesToSupply(_token, shares);
        _withdrawShares(_token, shares);
        _transferAsset(_token, _recipient, amount);
    }

    /// @notice repays a specified _maxAmount of _token debt
    /// @dev if _maxAmount > debt defaults to repaying all debt of selected token
    function _repay(
        address _account,
        address _token,
        uint256 _maxAmount
    ) internal {
        _validateToken(_token);
        accrue(_token);

        uint256 maxShares = _debtToShares(_token, _maxAmount);

        uint256 sharesAmount = Math.min(
            accounting[_token].debtSharesOf[_account],
            maxShares
        );
        uint256 repayAmount = _repayShares(_account, _token, sharesAmount);

        _safeTransferFrom(_token, msg.sender, repayAmount);
    }

    /// @notice checks the current account health is greater than required min health (based on provided collateral, debt and token prices)
    /// @dev reverts if health is below liquidation limit
    function _checkAccountHealth(address _account) internal view {
        (uint256 priceA, uint256 priceB) = tokenPrices(tokenA, tokenB);
        uint256 health = _accountHealth(_account, priceA, priceB);
        require(
            health >= LIQ_MIN_HEALTH,
            "LendingPair: insufficient accountHealth"
        );
    }

    /// @notice liquidation: Sell collateral to reduce debt and increase accountHealth
    /// @notice the liquidator needs to provide enought tokens to repay debt and receives supply tokens
    /// @dev Set _repayAmount to type(uint).max to repay all debt, inc. pending interest
    function _liquidateAccount(
        address _account,
        address _repayToken,
        uint256 _repayAmount
    ) internal {
        // Input validation and adjustments

        _validateToken(_repayToken);

        address supplyToken = _repayToken == tokenA ? tokenB : tokenA;

        // Check account is underwater after interest

        accrue(supplyToken);
        accrue(_repayToken);

        (uint256 priceA, uint256 priceB) = tokenPrices(tokenA, tokenB);

        uint256 health = _accountHealth(_account, priceA, priceB);
        require(
            health < LIQ_MIN_HEALTH,
            "LendingPair: account health < LIQ_MIN_HEALTH"
        );

        // Calculate balance adjustments

        _repayAmount = Math.min(_repayAmount, _debtOf(_repayToken, _account));

        // Calculates the amount of collateral to liquidate for _repayAmount
        // Avoiding stack too deep error
        uint256 supplyDebt = _convertTokenValues(
            _repayToken,
            supplyToken,
            _repayAmount,
            _repayToken == tokenA ? priceA : priceB, // repayPrice
            supplyToken == tokenA ? priceA : priceB // supplyPrice
        );

        // Adding fees
        uint256 callerFee = (supplyDebt *
            lendingController.liqFeeCaller(_repayToken)) / 100e18;
        uint256 systemFee = (supplyDebt *
            lendingController.liqFeeSystem(_repayToken)) / 100e18;
        uint256 supplyBurn = supplyDebt + callerFee + systemFee;
        uint256 supplyOutput = supplyDebt + callerFee;

        // Adjust balances

        _burnSupplyShares(
            supplyToken,
            _account,
            _supplyToShares(supplyToken, supplyBurn)
        );
        pendingSystemFees[supplyToken] += systemFee;
        _burnDebtShares(
            _repayToken,
            _account,
            _debtToShares(_repayToken, _repayAmount)
        );

        // Settle token transfers

        _safeTransferFrom(_repayToken, msg.sender, _repayAmount);
        // Better to just send the Liquidated tokens to the liquidator
        // todo: Implement direct transfer of tokens to liquidator, but first check for vulnarabilities:
        // _safeTransfer(supplyToken, msg.sender, supplyOutput);
        _mintSupplyAmount(supplyToken, msg.sender, supplyOutput);

        emit Liquidation(
            _account,
            _repayToken,
            supplyToken,
            _repayAmount,
            supplyOutput
        );
    }

    /// @notice calls the function wildCall of any contract
    /// @param _callee contract to call
    /// @param _data calldata
    function _call(address _callee, bytes memory _data) internal {
        ICallee(_callee).wildCall(_data);
    }

    /// @notice Supply tokens.
    /// @dev Mint new supply shares (corresponding to supply _amount) and credit them to _account.
    /// @dev increase total supply amount and shares
    /// @return shares | number of supply shares newly minted
    function _mintSupplyAmount(
        address _token,
        address _account,
        uint256 _amount
    ) internal returns (uint256 shares) {
        if (_amount > 0) {
            shares = _supplyToShares(_token, _amount);
            accounting[_token].supplySharesOf[_account] += shares;
            accounting[_token].totalSupplyShares += shares;
            accounting[_token].totalSupplyAmount += _amount;
        }
    }

    /// @notice Withdraw Tokens.
    /// @dev burns supply shares credited to _account by the number of _shares specified
    /// @dev reduces totalSupplyShares. Reduces totalSupplyAmount by the corresponding amount
    /// @return amount of tokens corresponding to _shares
    function _burnSupplyShares(
        address _token,
        address _account,
        uint256 _shares
    ) internal returns (uint256 amount) {
        if (_shares > 0) {
            // Fix rounding error which can make issues during depositRepay / withdrawBorrow
            if (accounting[_token].supplySharesOf[_account] - _shares == 1) {
                _shares += 1;
            }

            amount = _sharesToSupply(_token, _shares);
            accounting[_token].supplySharesOf[_account] -= _shares;
            accounting[_token].totalSupplyShares -= _shares;
            accounting[_token].totalSupplyAmount -= amount;
        }
    }

    /// @notice Make debt.
    /// @dev Mint new debt shares (corresponding to debt _amount) and credit them to _account.
    /// @dev increase total debt amount and shares
    /// @return shares | number of debt shares newly minted
    function _mintDebtAmount(
        address _token,
        address _account,
        uint256 _amount
    ) internal returns (uint256 shares) {
        if (_amount > 0) {
            shares = _debtToShares(_token, _amount);
            // Borrowing costs 1 share to account for later underpayment
            ++shares;

            accounting[_token].debtSharesOf[_account] += shares;
            accounting[_token].totalDebtShares += shares;
            accounting[_token].totalDebtAmount += _amount;
        }
    }

    /// @notice Repay Debt.
    /// @dev burns debt shares credited to _account by the number of _shares specified
    /// @dev reduces totalDebtShares. Reduces totalDebtAmount by the corresponding amount
    /// @return amount of tokens corresponding to _shares
    function _burnDebtShares(
        address _token,
        address _account,
        uint256 _shares
    ) internal returns (uint256 amount) {
        if (_shares > 0) {
            // Fix rounding error which can make issues during depositRepay / withdrawBorrow
            if (accounting[_token].debtSharesOf[_account] - _shares == 1) {
                _shares += 1;
            }
            amount = _sharesToDebt(_token, _shares);
            accounting[_token].debtSharesOf[_account] -= _shares;
            accounting[_token].totalDebtShares -= _shares;
            accounting[_token].totalDebtAmount -= amount;
        }
    }

    /// @notice accrue interest on debt, by adding newDebt since last accrue to totalDebtAmount.
    /// @dev done by: applying the interest per Block on the oustanding debt times blocks elapsed
    /// @dev using _interestRatePerBlock() interest rate Model
    /// @return newDebt
    function _accrueDebt(address _token) internal returns (uint256 newDebt) {
        // If borrowed or existing Debt, else skip
        if (accounting[_token].totalDebtAmount > 0) {
            uint256 blocksElapsed = block.number - lastBlockAccrued[_token];
            uint256 pendingInterestRate = _interestRatePerBlock(_token) *
                blocksElapsed;
            newDebt =
                (accounting[_token].totalDebtAmount * pendingInterestRate) /
                100e18;
            accounting[_token].totalDebtAmount += newDebt;
        }
    }

    /// @notice reduces the SupplyShare of msg.sender by the defined amount, emits Withdraw event
    function _withdrawShares(address _token, uint256 _shares) internal {
        uint256 amount = _burnSupplyShares(_token, msg.sender, _shares);
        emit Withdraw(msg.sender, _token, amount);
    }

    /// @notice repay debt shares
    /// @return amount of tokens repayed for _shares
    function _repayShares(
        address _account,
        address _token,
        uint256 _shares
    ) internal returns (uint256 amount) {
        amount = _burnDebtShares(_token, _account, _shares);
        emit Repay(_account, _token, amount);
    }

    /// @notice Safe withdraw of ERC-20 tokens (revert on failure)
    function _transferAsset(
        address _asset,
        address _to,
        uint256 _amount
    ) internal {
        if (_asset == address(WETH)) {
            //Withdraw as ETH
            _wethWithdrawTo(_to, _amount);
        } else {
            _safeTransfer(_asset, _to, _amount);
        }
    }

    /// @notice creates a new ERC-20 token representing collateral amounts within this pair
    /// @dev called during pair initialization
    /// @dev acts as an interface to the information stored in this contract
    function _createLpToken(
        address _lpTokenMaster,
        address _underlying
    ) internal returns (address) {
        ILPTokenMaster newLPToken = ILPTokenMaster(_lpTokenMaster.clone());
        newLPToken.initialize(_underlying, address(lendingController));
        return address(newLPToken);
    }

    /// @notice checks the current health of an _account, the health represents the ratio of collateral to debt
    /// @dev Query all supply & borrow balances and convert the amounts into the the same token (tokenA)
    /// @dev then calculates the ratio
    function _accountHealth(
        address _account,
        uint256 _priceA,
        uint256 _priceB
    ) internal view returns (uint256) {
        // No Debt:
        if (
            accounting[tokenA].debtSharesOf[_account] == 0 &&
            accounting[tokenB].debtSharesOf[_account] == 0
        ) {
            return LIQ_MIN_HEALTH;
        }

        uint256 colFactorA = colFactor[tokenA];
        uint256 colFactorB = colFactor[tokenB];

        uint256 creditA = (_supplyOf(tokenA, _account) * colFactorA) / 100e18;
        uint256 creditB = (_supplyBalanceConverted(
            _account,
            tokenB,
            tokenA,
            _priceB,
            _priceA
        ) * colFactorB) / 100e18;

        uint256 totalAccountBorrow = _debtOf(tokenA, _account) +
            _borrowBalanceConverted(_account, tokenB, tokenA, _priceB, _priceA);

        return ((creditA + creditB) * 1e18) / totalAccountBorrow;
    }

    /// @notice returns the amount of shares representing X tokens (_inputSupply)
    /// @param _totalShares total shares in circulation
    /// @param _totalAmount total amount of token X deposited in the pair
    /// @param _inputSupply amount of tokens to find the proportional amount of shares for
    /// @return shares representing _inputSupply
    function _amountToShares(
        uint256 _totalShares,
        uint256 _totalAmount,
        uint256 _inputSupply
    ) internal pure returns (uint256) {
        if (_totalShares > 0 && _totalAmount > 0) {
            return (_inputSupply * _totalShares) / _totalAmount;
        } else {
            return _inputSupply;
        }
    }

    /// @notice returns the amount of tokens representing X shares (_inputShares)
    /// @param _totalShares total shares in circulation
    /// @param _totalAmount total amount of token X deposited in the pair
    /// @param _inputShares amount of shares to find the proportional amount of tokens for
    /// @return the underlying amount of tokens for _inputShares
    function _sharesToAmount(
        uint256 _totalShares,
        uint256 _totalAmount,
        uint256 _inputShares
    ) internal pure returns (uint256) {
        if (_totalShares > 0 && _totalAmount > 0) {
            return (_inputShares * _totalAmount) / _totalShares;
        } else {
            return _inputShares;
        }
    }

    /// @notice converts an input debt amount to the corresponding number of DebtShares representing it
    /// @dev calls _amountToShares with the arguments of totalDebtShares, totalDebtAmount, and debt amount to convert to DebtShares
    function _debtToShares(
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        return
            _amountToShares(
                accounting[_token].totalDebtShares,
                accounting[_token].totalDebtAmount,
                _amount
            );
    }

    /// @notice converts a number of DebtShares to the underlying amount of token debt
    /// @dev calls _sharesToAmount with the arguments of totalDebtShares, totalDebtAmount, and the number of shares to convert to the underlying debt amount
    function _sharesToDebt(
        address _token,
        uint256 _shares
    ) internal view returns (uint256) {
        return
            _sharesToAmount(
                accounting[_token].totalDebtShares,
                accounting[_token].totalDebtAmount,
                _shares
            );
    }

    /// @notice converts an input amount to the corresponding number of shares representing it
    /// @dev calls _amountToShares with the arguments of totalSupplyShares, totalSupplyAmount, and amount to convert to shares
    function _supplyToShares(
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        return
            _amountToShares(
                accounting[_token].totalSupplyShares,
                accounting[_token].totalSupplyAmount,
                _amount
            );
    }

    /// @notice converts a number of shares to the underlying amount of tokens
    /// @dev calls _sharesToAmount with the arguments of totalSupplyShares, totalSupplyAmount, and the number of shares to convert to the underlying amount
    function _sharesToSupply(
        address _token,
        uint256 _shares
    ) internal view returns (uint256) {
        return
            _sharesToAmount(
                accounting[_token].totalSupplyShares,
                accounting[_token].totalSupplyAmount,
                _shares
            );
    }

    /// @return amount of tokens (including interest) borrowed by _account
    /// @dev gets the number of debtShares owed by _account and converts it into the amount of underlying tokens (_sharesToDebt)
    function _debtOf(
        address _token,
        address _account
    ) internal view returns (uint256) {
        return _sharesToDebt(_token, accounting[_token].debtSharesOf[_account]);
    }

    /// @return amount of tokens (including interest) supplied by _account
    /// @dev gets the number of shares credited to _account and converts it into the amount of underlying tokens (_sharesToSupply)
    function _supplyOf(
        address _token,
        address _account
    ) internal view returns (uint256) {
        return
            _sharesToSupply(
                _token,
                accounting[_token].supplySharesOf[_account]
            );
    }

    /// @notice Unit conversion. Get the amount of borrowed tokens and convert it to the same value of _returnToken
    /// @return amount borrowed converted to _returnToken
    function _borrowBalanceConverted(
        address _account,
        address _borrowedToken,
        address _returnToken,
        uint256 _borrowPrice,
        uint256 _returnPrice
    ) internal view returns (uint256) {
        return
            _convertTokenValues(
                _borrowedToken,
                _returnToken,
                _debtOf(_borrowedToken, _account),
                _borrowPrice,
                _returnPrice
            );
    }

    /// @notice Unit conversion. Get the amount of supplied tokens and convert it to the same value of _returnToken
    /// @return amount supplied converted to _returnToken
    function _supplyBalanceConverted(
        address _account,
        address _suppliedToken,
        address _returnToken,
        uint256 _supplyPrice,
        uint256 _returnPrice
    ) internal view returns (uint256) {
        return
            _convertTokenValues(
                _suppliedToken,
                _returnToken,
                _supplyOf(_suppliedToken, _account), //input amount
                _supplyPrice,
                _returnPrice
            );
    }

    /// @notice converts an _inputAmount (_fromToken) to the same value of _toToken
    /// @notice like a price quote of _fromToken -> _toToken with an amount of _inputAmout
    /// @dev  Not calling priceOracle.convertTokenValues() to save gas by reusing already fetched prices
    function _convertTokenValues(
        address _fromToken,
        address _toToken,
        uint256 _inputAmount,
        uint256 _fromPrice,
        uint256 _toPrice
    ) internal view returns (uint256) {
        uint256 fromPrice = (_fromPrice * 1e18) / 10 ** decimals[_fromToken];
        uint256 toPrice = (_toPrice * 1e18) / 10 ** decimals[_toToken];

        return (_inputAmount * fromPrice) / toPrice;
    }

    /// @notice calculates the interest rate per block based on current supply+borrow amounts and limits
    /// @dev we have two interest rate curves in place:
    /// @dev                     1) 0%->loweRate               : if ultilization < targetUtilization
    /// @dev                     2) lowerRate + 0%->higherRate : if ultilization >= targetUtilization
    /// @dev
    /// @dev To convert time rate to block rate, use this formula:
    /// @dev RATE FORMULAR: annualRate [0-100] * BLOCK_TIME [s] * 1e18 / (365 * 86400); BLOCK_TIME_MAIN_OLD=13.2s
    /// @dev where annualRate is in format: 1e18 = 1%
    /// @dev Arbitrum uses ethereum blocknumbers. block.number is updated every ~1min
    /// @dev Ethereum PoS-blocktime is 12.05s
    /// @dev Ethereum Blocks per year: ~2617095
    function _interestRatePerBlock(
        address _token
    ) internal view returns (uint256) {
        uint256 totalSupply = accounting[_token].totalSupplyAmount;
        uint256 totalDebt = accounting[_token].totalDebtAmount;

        if (totalSupply == 0 || totalDebt == 0) {
            return irm.minRate;
        }

        uint256 utilization = (((totalDebt * 100e18) / totalSupply) * 100e18) /
            irm.targetUtilization;

        // If current utilization is below targetUtilization
        if (utilization < 100e18) {
            uint256 rate = (irm.lowRate * utilization) / 100e18; //[e2-e0] with lowRate
            return Math.max(rate, irm.minRate);
        } else {
            // This "utilization" represents the utilization of funds between target-utilization and totalSupply
            // E.g. totalSupply=100 totalDebt=95 taget=90 -> utilization=50%
            uint256 targetSupplyUtilization = (totalSupply *
                irm.targetUtilization) / 100e18;
            uint256 excessUtilization = ((totalDebt - targetSupplyUtilization));
            uint256 maxExcessUtiization = totalSupply *
                (100e18 - irm.targetUtilization);

            utilization =
                (excessUtilization * 100e18) /
                (maxExcessUtiization / 100e18);

            utilization = Math.min(utilization, 100e18);
            return
                irm.lowRate +
                ((irm.highRate - irm.lowRate) * utilization) /
                100e18;
        }
    }

    /// @notice accounting! Makes sure balances, debt, supply, and fees add up.
    function _checkReserve(address _token) internal view {
        IERC20 token = IERC20(_token);

        uint256 balance = token.balanceOf(address(this));
        uint256 debt = accounting[_token].totalDebtAmount;
        uint256 supply = accounting[_token].totalSupplyAmount;
        uint256 fees = pendingSystemFees[_token];

        require(
            int256(balance) + int256(debt) - int256(supply) - int256(fees) >= 0,
            "LendingPair: reserve check failed"
        );
    }

    /// @notice validates that the input token is one of the pair Tokens (tokenA or tokenB).
    function _validateToken(address _token) internal view {
        require(
            _token == tokenA || _token == tokenB,
            "LendingPair: invalid token"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

contract LendingPairEvents {
    event Liquidation(
        address indexed account,
        address indexed repayToken,
        address indexed supplyToken,
        uint256 repayAmount,
        uint256 supplyAmount
    );
    event Deposit(
        address indexed account,
        address indexed token,
        uint256 amount
    );
    event Withdraw(
        address indexed account,
        address indexed token,
        uint256 amount
    );
    event Borrow(
        address indexed account,
        address indexed token,
        uint256 amount
    );
    event Repay(address indexed account, address indexed token, uint256 amount);
    event CollectSystemFee(address indexed token, uint256 amount);
    event NewColFactor(address indexed token, uint256 value);
    event NewlpRate(uint256 lpRate);
    event NewInterestRateParameters(
        uint256 minRate,
        uint256 lowRate,
        uint256 highRate,
        uint256 targetUtilization
    );
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) FloraLoans - All rights reserved
// https://twitter.com/Flora_Loans

// This contract is a wrapper around the LendingPair contract
// Each new LendingPair implementation delegates its calls to this contract
// It enables ERC20 functionality around the postion tokens

pragma solidity ^0.8.6;

import "./interfaces/ILPTokenMaster.sol";
import "./interfaces/ILendingPair.sol";
import "./interfaces/ILendingController.sol";
import "./external/SafeOwnable.sol";

/// @title LendingPairTokenMaster: An ERC20-like Master contract
/// @author 0xdev & flora.loans
/// @notice Serves as a fungible token
/// @dev Implements the ERC20 standard
contract LPTokenMaster is ILPTokenMaster, SafeOwnable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address => mapping(address => uint256)) public override allowance;

    address public override underlying;
    address public lendingController;
    string public constant name = "Flora-Lendpair";
    string public constant symbol = "FLORA-LP";
    uint8 public constant override decimals = 18;
    bool private initialized;

    modifier onlyOperator() {
        require(
            msg.sender == ILendingController(lendingController).owner(),
            "LPToken: caller is not an operator"
        );
        _;
    }

    function initialize(address _underlying, address _lendingController)
        external
        override
    {
        require(initialized != true, "LPToken: already intialized");
        owner = msg.sender;
        underlying = _underlying;
        lendingController = _lendingController;
        initialized = true;
    }

    /// @dev Transfer token to a specified address
    /// @param _recipient The address to transfer to
    /// @param _amount The amount to be transferred
    /// @return a boolean value indicating whether the operation succeeded.
    /// @notice Emits a {Transfer} event.
    function transfer(address _recipient, uint256 _amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    /// @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
    /// @param _spender The address which will spend the funds
    /// @param _amount The amount of tokens to be spent
    /// @return bool
    /// @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
    /// and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    /// race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address _spender, uint256 _amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    /// @notice Transfer tokens from one address to another.
    /// @param _sender The address which you want to send tokens from
    /// @param _recipient The address which you want to transfer to
    /// @param _amount The amount of tokens to be transferred
    /// @return bool
    /// @dev Note that while this function emits an Approval event, this is not required as per the specification and other compliant implementations may not emit the event.
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        _approve(_sender, msg.sender, allowance[_sender][msg.sender] - _amount);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    /// @notice returns associated LendingPair Contract
    function lendingPair() external view override returns (address) {
        return owner;
    }

    /// @notice Gets the balance of the specified address
    /// @param _account The address to query the balance of
    /// @return A uint256 representing the amount owned by the passed address
    function balanceOf(address _account)
        external
        view
        override
        returns (uint256)
    {
        return ILendingPair(owner).supplySharesOf(underlying, _account);
    }

    /// @notice Total number of tokens in existence
    function totalSupply() external view override returns (uint256) {
        return ILendingPair(owner).totalSupplyShares(underlying);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(
            _recipient != address(0),
            "ERC20: transfer to the zero address"
        );

        ILendingPair(owner).transferLp(
            underlying,
            _sender,
            _recipient,
            _amount
        );

        emit Transfer(_sender, _recipient, _amount);
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowance[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";
import "./external/SafeERC20.sol";

contract TransferHelper {
    using SafeERC20 for IERC20;

    IWETH internal immutable WETH;

    constructor(IWETH _WETH) {
        WETH = _WETH;
    }

    function _safeTransferFrom(
        address _token,
        address _sender,
        uint256 _amount
    ) internal {
        require(_amount > 0, "TransferHelper: amount must be > 0");
        IERC20(_token).safeTransferFrom(_sender, address(this), _amount);
    }

    function _safeTransfer(
        address _token,
        address _recipient,
        uint256 _amount
    ) internal {
        require(_amount > 0, "TransferHelper: amount must be > 0");
        IERC20(_token).safeTransfer(_recipient, _amount);
    }

    function _wethWithdrawTo(address _to, uint256 _amount) internal {
        require(_amount > 0, "TransferHelper: amount must be > 0");
        require(_to != address(0), "TransferHelper: invalid recipient");

        WETH.withdraw(_amount);
        (bool success, ) = _to.call{value: _amount}(new bytes(0));
        require(success, "TransferHelper: ETH transfer failed");
    }

    function _depositWeth() internal {
        require(msg.value > 0, "TransferHelper: amount must be > 0");
        WETH.deposit{value: msg.value}();
    }
}