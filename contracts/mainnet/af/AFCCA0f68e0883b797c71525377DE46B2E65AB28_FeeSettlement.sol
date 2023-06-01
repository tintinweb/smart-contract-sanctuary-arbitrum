// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeTransferLib} from 'lib/solmate/src/utils/SafeTransferLib.sol';
import {IWETH} from "../interfaces/IWETH.sol";
import {IReferralStorage} from "../../referrals/interfaces/IReferralStorage.sol";
import {AdminUpgradeable} from "../../libraries/AdminUpgradeable.sol";
import {IFeeSettlement} from "../interfaces/IFeeSettlement.sol";
import {Constants} from "../../libraries/Constants.sol";
import {IZLKDiscountReader} from "../interfaces/IZLKDiscountReader.sol";

contract FeeSettlement is IFeeSettlement, ReentrancyGuard, AdminUpgradeable {
    using SafeERC20 for IERC20;
    using SafeTransferLib for address;

    address public immutable weth;

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MAX_FEE_POINTS = 30; // 0.3%

    IReferralStorage public referralStorage;
    uint256 public feeShare; // e.g. 10 for 0.1%
    uint256 public feeDiscount; // e.g. 2000 for 20%
    uint256 public feeRebate; // e.g. 5000 for 50%/50%, 2500 for 75% fee/25% rebate
    address public feeTo;

    IZLKDiscountReader public zlkDiscountReader;

    error InvalidFeeShare();
    error InvalidFeeDiscount();
    error InvalidFeeRebate();
    error InsufficientOutAmount();

    event PayRebates(
        address trader,
        address referrer,
        address tokenOut,
        uint256 discountAmount,
        uint256 rebateAmount
    );
    event SetReferralStorage(IReferralStorage referralStorage);
    event SetZLKDiscountReader(IZLKDiscountReader zlkDiscountReader);
    event SetFeeShare(uint256 feeShare);
    event SetFeeDiscount(uint256 feeDiscount);
    event SetFeeRebate(uint256 feeRebate);
    event SetFeeTo(address feeTo);

    constructor(
        address _weth, 
        IReferralStorage _referralStorage,
        uint256 _feeShare,
        uint256 _feeDiscount,
        uint256 _feeRebate,
        address _feeTo
    ) {
        weth = _weth;
        referralStorage = _referralStorage;

        if (_feeShare > MAX_FEE_POINTS) revert InvalidFeeShare();
        if (_feeDiscount > BASIS_POINTS) revert InvalidFeeDiscount();
        if (_feeRebate > BASIS_POINTS) revert InvalidFeeRebate();
        feeShare = _feeShare;
        feeDiscount = _feeDiscount;
        feeRebate = _feeRebate;
        feeTo = _feeTo;
        _initializeAdmin(msg.sender);
    }

    /// @notice To receive ETH from router
    receive() external payable {}

    /// @notice Executes the fee settlement, including pay referrer rebates
    /// @param tokenOut Address of the output token
    /// @param amountOutMin Minimum amount of the output token
    /// @param from Trader address
    /// @param to Receiver address
    function processSettlement(
        address tokenOut,
        uint256 amountOutMin,
        address from,
        address to
    ) external override nonReentrant {
        bool isNative = tokenOut == Constants.NATIVE_ADDRESS;
        uint256 amount = isNative 
            ? address(this).balance 
            : IERC20(tokenOut).balanceOf(address(this));
        if (amount < amountOutMin) revert InsufficientOutAmount();
        (, address referrer) = referralStorage.getReferralInfo(from);
        uint256 basisfee = (amount * feeShare) / BASIS_POINTS;
        if (address(zlkDiscountReader) != address(0)) {
            (uint256 zlkdiscount, uint256 basis) = zlkDiscountReader.getZLKDiscount(from);
            basisfee = (basisfee * (basis - zlkdiscount)) / basis;
        }
        uint256 fee = referrer == address(0) 
            ? basisfee
            : (basisfee * (BASIS_POINTS - feeDiscount)) / BASIS_POINTS;
        if (amount - fee < amountOutMin) {
            // ensure that fee do not cause the transaction to fail 
            fee = amount - amountOutMin;
        }
        if (referrer != address(0)) {
            uint256 rebateAmount = (fee * feeRebate) / BASIS_POINTS;
            if (isNative) {
                IWETH(weth).deposit{value: fee}();
                IERC20(weth).safeTransfer(referrer, rebateAmount);
                IERC20(weth).safeTransfer(feeTo, IERC20(weth).balanceOf(address(this)));
            } else {
                IERC20(tokenOut).safeTransfer(referrer, rebateAmount);
                IERC20(tokenOut).safeTransfer(feeTo, fee - rebateAmount);
            }
            emit PayRebates(from, referrer, tokenOut, basisfee - fee, rebateAmount);
        } else {
            if (isNative) {
                IWETH(weth).deposit{value: fee}();
                IERC20(weth).safeTransfer(feeTo, IERC20(weth).balanceOf(address(this)));
            } else {
                IERC20(tokenOut).safeTransfer(feeTo, fee);
            }
        }
        if (isNative) {
            to.safeTransferETH(amount - fee);
        } else {
            IERC20(tokenOut).safeTransfer(to, amount - fee);
        }
    }

    // @notice Set referralStorage by admin
    /// @param _referralStorage ReferralStorage address
    function setReferralStorage(IReferralStorage _referralStorage) external onlyAdmin {
        referralStorage = _referralStorage;
        emit SetReferralStorage(_referralStorage);
    }

    // @notice Set zlkDiscountReader by admin
    /// @param _zlkDiscountReader ZLKDiscountReader address
    function setZLKDiscountReader(IZLKDiscountReader _zlkDiscountReader) external onlyAdmin {
        zlkDiscountReader = _zlkDiscountReader;
        emit SetZLKDiscountReader(_zlkDiscountReader);
    }

    /// @notice Set feeShare by admin
    /// @param _feeShare Percent of fee
    function setFeeShare(uint256 _feeShare) external onlyAdmin {
        if (_feeShare > MAX_FEE_POINTS) revert InvalidFeeShare();
        feeShare = _feeShare;
        emit SetFeeShare(_feeShare);
    }

    /// @notice Set feeDicount by admin
    /// @param _feeDiscount Percent of feeDiscount
    function setFeeDiscount(uint256 _feeDiscount) external onlyAdmin {
        if (_feeDiscount > BASIS_POINTS) revert InvalidFeeDiscount();
        feeDiscount = _feeDiscount;
        emit SetFeeDiscount(_feeDiscount);
    }

    /// @notice Set feeRebate by admin
    /// @param _feeRebate Percent of feeRebate
    function setFeeRebate(uint256 _feeRebate) external onlyAdmin {
        if (_feeRebate > BASIS_POINTS) revert InvalidFeeRebate();
        feeRebate = _feeRebate;
        emit SetFeeRebate(_feeRebate);
    }

    /// @notice Set feeTo by admin
    /// @param _feeTo FeeTo address
    function setFeeTo(address _feeTo) external onlyAdmin {
        feeTo = _feeTo;
        emit SetFeeTo(_feeTo);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IReferralStorage {
    function codeOwners(bytes32 _code) external view returns (address);
    function getReferralInfo(address _account) external view returns (bytes32, address);
    function getOwnedCodes(address _account) external view returns (bytes32[] memory);
    function setReferralCodeByUser(bytes32 _code) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

abstract contract AdminUpgradeable {
    address public admin;
    address public adminCandidate;

    function _initializeAdmin(address _admin) internal {
        require(admin == address(0), "admin already set");

        admin = _admin;
    }

    function candidateConfirm() external {
        require(msg.sender == adminCandidate, "not Candidate");
        emit AdminChanged(admin, adminCandidate);

        admin = adminCandidate;
        adminCandidate = address(0);
    }

    function setAdminCandidate(address _candidate) external onlyAdmin {
        adminCandidate = _candidate;
        emit Candidate(_candidate);
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "not admin");
        _;
    }

    event Candidate(address indexed newAdmin);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IFeeSettlement {
    function processSettlement(address tokenOut, uint256 amountOutMin, address from, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Constants {
    /// @dev Used as a flag for identifying the transfer of ETH instead of a token
    address internal constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev Used as a impossible pool address
    address internal constant IMPOSSIBLE_POOL_ADDRESS = 0x0000000000000000000000000000000000000001;
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IZLKDiscountReader {
    function getZLKDiscount(address user) external view returns (uint256 discount, uint256 basis);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {InputStream} from './InputStream.sol';
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeTransferLib} from 'lib/solmate/src/utils/SafeTransferLib.sol';
import {IPair} from "../core/interfaces/IPair.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IStableSwapDispatcher} from "./interfaces/IStableSwapDispatcher.sol";
import {IFeeSettlement} from "./interfaces/IFeeSettlement.sol";
import {AdminUpgradeable} from "../libraries/AdminUpgradeable.sol";
import {Constants} from "../libraries/Constants.sol";
import {IUniswapV3Pool} from "./interfaces/uniswap/v3/IUniswapV3Pool.sol";
import {IAlgebraPool} from "./interfaces/algebra/IAlgebraPool.sol";
import {IVault} from "./interfaces/gmx/IVault.sol";
import {ILBPair} from "./interfaces/joe/v2/ILBPair.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ICurveStableDispatcher} from "./interfaces/curve/ICurveStableDispatcher.sol";

contract UniversalRouter2 is ReentrancyGuard, AdminUpgradeable, Pausable {
    using SafeERC20 for IERC20;
    using SafeTransferLib for address;
    using InputStream for uint256;

    IStableSwapDispatcher public stableSwapDispatcher;
    ICurveStableDispatcher public curveStableDispatcher;
    IFeeSettlement public feeSettlement;
    address private lastCalledPool;

    error UnknownCommandCode(uint8 code);
    error UnknownPoolType(uint8 poolType);
    error MinimalInputBalanceViolation();
    error MinimalOutputBalanceViolation();
    error InvalidPool(address pool);
    error UnexpectedAddress(address addr);
    error UnexpectedUniV3Swap();
    error UnexpectedAlgebraSwap();

    event SetCurveStableDispatcher(ICurveStableDispatcher curveStableDispatcher);
    event SetStableSwapDispatcher(IStableSwapDispatcher stableSwapDispatcher);
    event SetFeeSettlement(IFeeSettlement feeSettlement);
    
    constructor(
        IStableSwapDispatcher _stableSwapDispatcher,
        ICurveStableDispatcher _curveStableDispatcher,
        IFeeSettlement _feeSettlement
    ) {
        stableSwapDispatcher = _stableSwapDispatcher;
        curveStableDispatcher = _curveStableDispatcher;
        feeSettlement = _feeSettlement;
        lastCalledPool = Constants.IMPOSSIBLE_POOL_ADDRESS;
        _initializeAdmin(msg.sender);
    }

    /// @notice To receive ETH from WETH
    receive() external payable {}

    /// @notice Set StableSwapDispatcher by admin
    /// @param _stableSwapDispatcher StableSwapDispatcher address
    function setStableSwapDispatcher(IStableSwapDispatcher _stableSwapDispatcher) external onlyAdmin {
        stableSwapDispatcher = _stableSwapDispatcher;
        emit SetStableSwapDispatcher(_stableSwapDispatcher);
    }

    /// @notice Set CurveStableDispatcher by admin
    /// @param _curveStableDispatcher CurveStableDispatcher address
    function setCurveStableDispatcher(ICurveStableDispatcher _curveStableDispatcher) external onlyAdmin {
        curveStableDispatcher = _curveStableDispatcher;
        emit SetCurveStableDispatcher(_curveStableDispatcher);
    }

    /// @notice Set FeeSettlement by admin
    /// @param _feeSettlement FeeSettlement address
    function setFeeSettlement(IFeeSettlement _feeSettlement) external onlyAdmin {
        feeSettlement = _feeSettlement;
        emit SetFeeSettlement(_feeSettlement);
    }

    /// @notice Decodes and executes the given route
    /// @param tokenIn Address of the input token
    /// @param amountIn Amount of the input token
    /// @param tokenOut Address of the output token
    /// @param amountOutMin Minimum amount of the output token
    /// @param to Receiver address
    /// @param route The encoded route to execute with
    /// @return amountOut Actual amount of the output token
    function processRoute(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        address to,
        bytes memory route
    ) external payable nonReentrant whenNotPaused returns (uint256 amountOut) {
        return processRouteInternal(tokenIn, amountIn, tokenOut, amountOutMin, to, route);
    }

    function transferValueAndprocessRoute(
        address transferValueTo,
        uint256 amountValueTransfer,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        address to,
        bytes memory route
    ) external payable nonReentrant whenNotPaused returns (uint256 amountOut) {
        transferValueTo.safeTransferETH(amountValueTransfer);
        return processRouteInternal(tokenIn, amountIn, tokenOut, amountOutMin, to, route);
    }

    /// @notice Decodes and executes the given route
    /// @param tokenIn Address of the input token
    /// @param amountIn Amount of the input token
    /// @param tokenOut Address of the output token
    /// @param amountOutMin Minimum amount of the output token
    /// @param to Receiver address
    /// @param route The encoded route to execute with
    /// @return amountOut Actual amount of the output token
    function processRouteInternal(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        address to,
        bytes memory route
    ) private returns (uint256 amountOut) {
        uint256 balanceInInitial = tokenIn == Constants.NATIVE_ADDRESS 
            ? address(this).balance 
            : IERC20(tokenIn).balanceOf(msg.sender);
        uint256 balanceOutInitial = tokenOut == Constants.NATIVE_ADDRESS 
            ? address(to).balance 
            : IERC20(tokenOut).balanceOf(to);

        uint256 stream = InputStream.createStream(route);
        while (stream.isNotEmpty()) {
            uint8 commandCode = stream.readUint8();
            if (commandCode == 1) _processMyERC20(stream);
            else if (commandCode == 2) _processUserERC20(stream, amountIn);
            else if (commandCode == 3) _processNative(stream);
            else if (commandCode == 4) _processOnePool(stream);
            else revert UnknownCommandCode(commandCode);
        }

        uint256 balanceInFinal = tokenIn == Constants.NATIVE_ADDRESS 
            ? address(this).balance 
            : IERC20(tokenIn).balanceOf(msg.sender);
        if (balanceInFinal + amountIn < balanceInInitial) revert MinimalInputBalanceViolation();

        feeSettlement.processSettlement(tokenOut, amountOutMin, msg.sender, to);

        uint256 balanceOutFinal = tokenOut == Constants.NATIVE_ADDRESS 
            ? address(to).balance 
            : IERC20(tokenOut).balanceOf(to);
        if (balanceOutFinal < balanceOutInitial + amountOutMin) revert MinimalOutputBalanceViolation();

        amountOut = balanceOutFinal - balanceOutInitial;
    }

    /// @notice Processes native coin: call swap for all pools that swap from native coin
    /// @param stream Streamed process program
    function _processNative(uint256 stream) private {
        uint256 amountTotal = address(this).balance;
        _distributeAndSwap(stream, address(this), Constants.NATIVE_ADDRESS, amountTotal);
    }

    /// @notice Processes ERC20 token from this contract balance:
    /// @notice Call swap for all pools that swap from this token
    /// @param stream Streamed process program
    function _processMyERC20(uint256 stream) private {
        address token = stream.readAddress();
        uint256 amountTotal = IERC20(token).balanceOf(address(this));
        unchecked {
            if (amountTotal > 0) amountTotal -= 1;     // slot undrain protection
        }
        _distributeAndSwap(stream, address(this), token, amountTotal);
    }

    /// @notice Processes ERC20 token from msg.sender balance:
    /// @notice Call swap for all pools that swap from this token
    /// @param stream Streamed process program
    /// @param amountTotal Amount of tokens to take from msg.sender
    function _processUserERC20(uint256 stream, uint256 amountTotal) private {
        address token = stream.readAddress();
        _distributeAndSwap(stream, msg.sender, token, amountTotal);
    }

    /// @notice Distributes amountTotal to several pools according to their shares and calls swap for each pool
    /// @param stream Streamed process program
    /// @param from Where to take liquidity for swap
    /// @param tokenIn Input token
    /// @param amountTotal Total amount of tokenIn for swaps 
    function _distributeAndSwap(
        uint256 stream, 
        address from, 
        address tokenIn, 
        uint256 amountTotal
    ) private {
        uint8 num = stream.readUint8();
        for (uint256 i = 0; i < num; ++i) {
            uint16 share = stream.readUint16();
            uint256 amount = (amountTotal * share) / 65535;
            amountTotal -= amount;
            _swap(stream, from, tokenIn, amount);
        }
    }

    /// @notice Processes ERC20 token for cases when the token has only one output pool
    /// @notice In this case liquidity is already at pool balance. This is an optimization
    /// @notice Call swap for all pools that swap from this token
    /// @param stream Streamed process program
    function _processOnePool(uint256 stream) private {
        address token = stream.readAddress();
        _swap(stream, address(this), token, 0);
    }

    /// @notice Makes swap
    /// @param stream Streamed process program
    /// @param from Where to take liquidity for swap
    /// @param tokenIn Input token
    /// @param amountIn Amount of tokenIn to take for swap
    function _swap(uint256 stream, address from, address tokenIn, uint256 amountIn) private {
        uint8 poolType = stream.readUint8();
        if (poolType == 0) _swapUniV2(stream, from, tokenIn, amountIn);
        else if (poolType == 1) _swapUniV3(stream, from, tokenIn, amountIn);
        else if (poolType == 2) _wrapNative(stream, from, tokenIn, amountIn);
        else if (poolType == 3) _swapStableSwap(stream, from, tokenIn, amountIn);
        else if (poolType == 4) _swapGmx(stream, from, tokenIn, amountIn);
        else if (poolType == 5) _swapJoeV2(stream, from, tokenIn, amountIn);
        else if (poolType == 6) _swapAlgebra(stream, from, tokenIn, amountIn);
        else if (poolType == 7) _swapCurveStable(stream, from, tokenIn, amountIn);
        else revert UnknownPoolType(poolType);
    }

    /// @notice UniswapV2 pool swap
    /// @param stream [pool, direction, recipient]
    /// @param from Where to take liquidity for swap
    /// @param tokenIn Input token
    /// @param amountIn Amount of tokenIn to take for swap
    function _swapUniV2(
        uint256 stream, 
        address from, 
        address tokenIn, 
        uint256 amountIn
    ) private returns (uint256 amountOut) {
        address pool = stream.readAddress();
        uint8 direction = stream.readUint8();
        address to = stream.readAddress();

        (uint256 reserve0, uint256 reserve1, ) = IPair(pool).getReserves();
        if (reserve0 == 0 || reserve1 == 0) revert InvalidPool(pool);
        (uint256 reserveIn, uint256 reserveOut) = direction == 1 
            ? (reserve0, reserve1) 
            : (reserve1, reserve0);

        if (amountIn != 0) {
            if (from == address(this)) {
                IERC20(tokenIn).safeTransfer(pool, amountIn);
            } else {
                IERC20(tokenIn).safeTransferFrom(from, pool, amountIn);
            }
        } else {
            amountIn = IERC20(tokenIn).balanceOf(pool) - reserveIn;  // tokens already were transferred
        }
        uint256 amountInWithFee = amountIn * 997;
        amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
        (uint256 amount0Out, uint256 amount1Out) = direction == 1 
            ? (uint256(0), amountOut) 
            : (amountOut, uint256(0));

        IPair(pool).swap(amount0Out, amount1Out, to, new bytes(0));
    }

    /// @notice UniswapV3 pool swap
    /// @param stream [pool, direction, recipient]
    /// @param from Where to take liquidity for swap
    /// @param tokenIn Input token
    /// @param amountIn Amount of tokenIn to take for swap
    function _swapUniV3(
        uint256 stream,
        address from,
        address tokenIn,
        uint256 amountIn
    ) private {
        address pool = stream.readAddress();
        bool zeroForOne = stream.readUint8() > 0;
        address recipient = stream.readAddress();

        if (from != address(this)) {
            if (from !=  msg.sender) revert UnexpectedAddress(from);
            IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        }

        lastCalledPool = pool;
        IUniswapV3Pool(pool).swap(
            recipient,
            zeroForOne,
            int256(amountIn),
            zeroForOne ? Constants.MIN_SQRT_RATIO + 1 : Constants.MAX_SQRT_RATIO - 1,
            abi.encode(tokenIn)
        );
        if (lastCalledPool != Constants.IMPOSSIBLE_POOL_ADDRESS) revert UnexpectedUniV3Swap();
    }

    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
      int256 amount0Delta,
      int256 amount1Delta,
      bytes calldata data
    ) external {
        if (msg.sender != lastCalledPool) revert UnexpectedUniV3Swap();
        lastCalledPool = Constants.IMPOSSIBLE_POOL_ADDRESS;
        (address tokenIn) = abi.decode(data, (address));
        int256 amount = amount0Delta > 0 ? amount0Delta : amount1Delta;
        if (amount <= 0) revert UnexpectedUniV3Swap();
        IERC20(tokenIn).safeTransfer(msg.sender, uint256(amount));
    }

    /// @notice Algebra pool swap
    /// @param stream [pool, direction, recipient]
    /// @param from Where to take liquidity for swap
    /// @param tokenIn Input token
    /// @param amountIn Amount of tokenIn to take for swap
    function _swapAlgebra(
        uint256 stream,
        address from,
        address tokenIn,
        uint256 amountIn
    ) private {
        address pool = stream.readAddress();
        bool zeroForOne = stream.readUint8() > 0;
        address recipient = stream.readAddress();

        if (from != address(this)) {
            if (from !=  msg.sender) revert UnexpectedAddress(from);
            IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        }

        lastCalledPool = pool;
        IAlgebraPool(pool).swap(
            recipient,
            zeroForOne,
            int256(amountIn),
            zeroForOne ? Constants.MIN_SQRT_RATIO + 1 : Constants.MAX_SQRT_RATIO - 1,
            abi.encode(tokenIn)
        );
        if (lastCalledPool != Constants.IMPOSSIBLE_POOL_ADDRESS) revert UnexpectedUniV3Swap();
    }

    /// @notice Called to `msg.sender` after executing a swap via IAlgebraPool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be an AlgebraPool deployed by the canonical AlgebraFactory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IAlgebraPoolActions#swap call
    function algebraSwapCallback(
      int256 amount0Delta,
      int256 amount1Delta,
      bytes calldata data
    ) external {
        if (msg.sender != lastCalledPool) revert UnexpectedAlgebraSwap();
        lastCalledPool = Constants.IMPOSSIBLE_POOL_ADDRESS;
        (address tokenIn) = abi.decode(data, (address));
        int256 amount = amount0Delta > 0 ? amount0Delta : amount1Delta;
        if (amount <= 0) revert UnexpectedAlgebraSwap();
        IERC20(tokenIn).safeTransfer(msg.sender, uint256(amount));
    }

    /// @notice Wraps/unwraps native token
    /// @param stream [direction & fake, recipient, wrapToken?]
    /// @param from Where to take liquidity for swap
    /// @param tokenIn Input token
    /// @param amountIn Amount of tokenIn to take for swap
    function _wrapNative(
        uint256 stream, 
        address from, 
        address tokenIn, 
        uint256 amountIn
    ) private {
        uint8 direction = stream.readUint8();
        address to = stream.readAddress();

        if (direction & 1 == 1) {
            address wrapToken = stream.readAddress();
            IWETH(wrapToken).deposit{value: amountIn}();
            if (to != address(this)) IERC20(wrapToken).safeTransfer(to, amountIn);
        } else {
            if (from != address(this)) IERC20(tokenIn).safeTransferFrom(from, address(this), amountIn);
            IWETH(tokenIn).withdraw(amountIn);
            to.safeTransferETH(address(this).balance);
        }
    }

    /// @notice Performs a Zenlink stable pool swap
    /// @param stream [isMetaSwap, To, [Pool, Option(isNativePool), TokenInIndex, TokenOutIndex, TokenOut]]
    /// @param from Where to take liquidity for swap
    /// @param tokenIn Input token
    /// @param amountIn Amount of tokenIn to take for swap
    function _swapStableSwap(
        uint256 stream, 
        address from, 
        address tokenIn, 
        uint256 amountIn
    ) private {
        uint8 isMetaSwap = stream.readUint8();
        address to = stream.readAddress();
        bytes memory swapData = stream.readBytes();
        if (amountIn != 0) {
            if (from == address(this)) {
                IERC20(tokenIn).safeTransfer(address(stableSwapDispatcher), amountIn);
            } else {
                IERC20(tokenIn).safeTransferFrom(from, address(stableSwapDispatcher), amountIn);
            }
        } else {
            amountIn = IERC20(tokenIn).balanceOf(address(stableSwapDispatcher));  // tokens already were transferred
        }
        
        if (isMetaSwap == 1) {
            (address pool, uint8 tokenInIndex, uint8 tokenOutIndex, address tokenOut) = abi.decode(
                swapData, 
                (address, uint8, uint8, address)
            );
            stableSwapDispatcher.swapUnderlying(pool, tokenInIndex, tokenOutIndex, tokenIn, tokenOut, to);
        } else {
            (address pool, bool isNativePool, uint8 tokenInIndex, uint8 tokenOutIndex, address tokenOut) = abi.decode(
                swapData, 
                (address, bool, uint8, uint8, address)
            );
            stableSwapDispatcher.swap(pool, isNativePool, tokenInIndex, tokenOutIndex, tokenIn, tokenOut, to);
        }
    }

    /// @notice Performs a Curve stable pool swap
    /// @param stream [isMetaSwap, To, [Pool, Option(isNativePool), TokenInIndex, TokenOutIndex, TokenOut]]
    /// @param from Where to take liquidity for swap
    /// @param tokenIn Input token
    /// @param amountIn Amount of tokenIn to take for swap
    function _swapCurveStable(
        uint256 stream, 
        address from, 
        address tokenIn, 
        uint256 amountIn
    ) private {
        uint8 isMetaSwap = stream.readUint8();
        address to = stream.readAddress();
        bytes memory swapData = stream.readBytes();
        if (amountIn != 0) {
            if (from == address(this)) {
                IERC20(tokenIn).safeTransfer(address(curveStableDispatcher), amountIn);
            } else {
                IERC20(tokenIn).safeTransferFrom(from, address(curveStableDispatcher), amountIn);
            }
        } else {
            amountIn = IERC20(tokenIn).balanceOf(address(curveStableDispatcher));  // tokens already were transferred
        }
        
        if (isMetaSwap == 1) {
            (address pool, int128 tokenInIndex, int128 tokenOutIndex, address tokenOut) = abi.decode(
                swapData, 
                (address, int128, int128, address)
            );
            curveStableDispatcher.exchange_underlying(pool, tokenInIndex, tokenOutIndex, tokenIn, tokenOut, to);
        } else {
            (address pool, bool isNativePool, int128 tokenInIndex, int128 tokenOutIndex, address tokenOut) = abi.decode(
                swapData, 
                (address, bool, int128, int128, address)
            );
            curveStableDispatcher.exchange(pool, isNativePool, tokenInIndex, tokenOutIndex, tokenIn, tokenOut, to);
        }
    }

    /// @notice GMX vault swap
    /// @param stream [tokenOut, receiver]
    /// @param from Where to take liquidity for swap
    /// @param tokenIn Input token
    /// @param amountIn Amount of tokenIn to take for swap
    function _swapGmx(
        uint256 stream, 
        address from, 
        address tokenIn, 
        uint256 amountIn
    ) private {
        address vault = stream.readAddress();
        address tokenOut = stream.readAddress();
        address receiver = stream.readAddress();

        if (amountIn != 0) {
            if (from == address(this)) {
                IERC20(tokenIn).safeTransfer(vault, amountIn);
            } else {
                IERC20(tokenIn).safeTransferFrom(from, vault, amountIn);
            }
        } else {
            amountIn = IERC20(tokenIn).balanceOf(vault) - IVault(vault).tokenBalances(tokenIn);  // tokens already were transferred
        }
        IVault(vault).swap(tokenIn, tokenOut, receiver);
    }

    /// @notice Trader Joe V2 swap
    /// @param stream [pool, swapForY, receiver]
    /// @param from Where to take liquidity for swap
    /// @param tokenIn Input token
    /// @param amountIn Amount of tokenIn to take for swap
    function _swapJoeV2(
        uint256 stream, 
        address from, 
        address tokenIn, 
        uint256 amountIn
    ) private {
        address pool = stream.readAddress();
        bool swapForY = stream.readUint8() > 0;
        address recipient = stream.readAddress();

        (uint128 reserveX, uint128 reserveY) = ILBPair(pool).getReserves();
        if (reserveX == 0 || reserveY == 0) revert InvalidPool(pool);
        (uint256 reserveIn, ) = swapForY
            ? (reserveX, reserveY) 
            : (reserveY, reserveX);

        if (amountIn != 0) {
            if (from == address(this)) {
                IERC20(tokenIn).safeTransfer(pool, amountIn);
            } else {
                IERC20(tokenIn).safeTransferFrom(from, pool, amountIn);
            }
        } else {
            amountIn = IERC20(tokenIn).balanceOf(pool) - reserveIn;  // tokens already were transferred
        }

        ILBPair(pool).swap(swapForY, recipient);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library InputStream {
    function createStream(bytes memory data) internal pure returns (uint256 stream) {
        assembly {
            stream := mload(0x40)
            mstore(0x40, add(stream, 64))
            mstore(stream, data)
            let length := mload(data)
            mstore(add(stream, 32), add(data, length))
        }
    }

    function isNotEmpty(uint256 stream) internal pure returns (bool) {
        uint256 pos;
        uint256 finish;
        assembly {
            pos := mload(stream)
            finish := mload(add(stream, 32))
        }
        return pos < finish;
    }

    function readUint8(uint256 stream) internal pure returns (uint8 res) {
        assembly {
            let pos := mload(stream)
            pos := add(pos, 1)
            res := mload(pos)
            mstore(stream, pos)
        }
    }

    function readUint16(uint256 stream) internal pure returns (uint16 res) {
        assembly {
            let pos := mload(stream)
            pos := add(pos, 2)
            res := mload(pos)
            mstore(stream, pos)
        }
    }

    function readUint32(uint256 stream) internal pure returns (uint32 res) {
        assembly {
            let pos := mload(stream)
            pos := add(pos, 4)
            res := mload(pos)
            mstore(stream, pos)
        }
    }

    function readUint(uint256 stream) internal pure returns (uint256 res) {
        assembly {
            let pos := mload(stream)
            pos := add(pos, 32)
            res := mload(pos)
            mstore(stream, pos)
        }
    }

    function readAddress(uint256 stream) internal pure returns (address res) {
        assembly {
            let pos := mload(stream)
            pos := add(pos, 20)
            res := mload(pos)
            mstore(stream, pos)
        }
    }

    function readBytes(uint256 stream) internal pure returns (bytes memory res) {
        assembly {
            let pos := mload(stream)
            res := add(pos, 32)
            let length := mload(res)
            mstore(stream, add(res, length))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IPair {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IStableSwapDispatcher {
    function swap(
        address pool, 
        bool isNativePool,
        uint8 tokenInIndex, 
        uint8 tokenOutIndex, 
        address tokenIn,
        address tokenOut,
        address to
    ) external;
    function swapUnderlying(
        address pool, 
        uint8 tokenInIndex, 
        uint8 tokenOutIndex,
        address tokenIn,
        address tokenOut,
        address to
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IUniswapV3PoolImmutables} from "./IUniswapV3PoolImmutables.sol";
import {IUniswapV3PoolState} from "./IUniswapV3PoolState.sol";
import {IUniswapV3PoolActions} from "./IUniswapV3PoolActions.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
// solhint-disable-next-line no-empty-blocks
interface IUniswapV3Pool is 
  IUniswapV3PoolImmutables, 
  IUniswapV3PoolState,
  IUniswapV3PoolActions
{
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IAlgebraPoolState} from './IAlgebraPoolState.sol';
import {IAlgebraPoolActions} from './IAlgebraPoolActions.sol';
import {IAlgebraPoolImmutables} from "./IAlgebraPoolImmutables.sol";

/**
 * @title The interface for a Algebra Pool
 * @dev The pool interface is broken up into many smaller pieces.
 * Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPool is
  IAlgebraPoolState,
  IAlgebraPoolActions,
  IAlgebraPoolImmutables
{
  // used only for combining interfaces
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IVaultUtils} from "./IVaultUtils.sol";

interface IVault {
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);
    function usdg() external view returns (address);
    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);
    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function fundingInterval() external view returns (uint256);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdgAmount(address _token) external view returns (uint256);

    function inManagerMode() external view returns (bool);
    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);
    function tokenBalances(address _token) external view returns (uint256);
    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setIsLeverageEnabled(bool _isLeverageEnabled) external;
    function setMaxGasPrice(uint256 _maxGasPrice) external;
    function setUsdgAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;
    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;
    function buyUSDG(address _token, address _receiver) external returns (uint256);
    function sellUSDG(address _token, address _receiver) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external;
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);
    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function cumulativeFundingRates(address _token) external view returns (uint256);
    function getNextFundingRate(address _token) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function shortableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function globalShortSizes(address _token) external view returns (uint256);
    function globalShortAveragePrices(address _token) external view returns (uint256);
    function maxGlobalShortSizes(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function reservedAmounts(address _token) external view returns (uint256);
    function usdgAmounts(address _token) external view returns (uint256);
    function maxUsdgAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ILBFactory} from "./ILBFactory.sol";
import {ILBFlashLoanCallback} from "./ILBFlashLoanCallback.sol";
import {ILBToken} from "./ILBToken.sol";

interface ILBPair is ILBToken {
    error LBPair__ZeroBorrowAmount();
    error LBPair__AddressZero();
    error LBPair__AlreadyInitialized();
    error LBPair__EmptyMarketConfigs();
    error LBPair__FlashLoanCallbackFailed();
    error LBPair__FlashLoanInsufficientAmount();
    error LBPair__InsufficientAmountIn();
    error LBPair__InsufficientAmountOut();
    error LBPair__InvalidInput();
    error LBPair__InvalidStaticFeeParameters();
    error LBPair__OnlyFactory();
    error LBPair__OnlyProtocolFeeRecipient();
    error LBPair__OutOfLiquidity();
    error LBPair__TokenNotSupported();
    error LBPair__ZeroAmount(uint24 id);
    error LBPair__ZeroAmountsOut(uint24 id);
    error LBPair__ZeroShares(uint24 id);
    error LBPair__MaxTotalFeeExceeded();

    struct MintArrays {
        uint256[] ids;
        bytes32[] amounts;
        uint256[] liquidityMinted;
    }

    event DepositedToBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event WithdrawnFromBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event CompositionFees(address indexed sender, uint24 id, bytes32 totalFees, bytes32 protocolFees);

    event CollectedProtocolFees(address indexed feeRecipient, bytes32 protocolFees);

    event Swap(
        address indexed sender,
        address indexed to,
        uint24 id,
        bytes32 amountsIn,
        bytes32 amountsOut,
        uint24 volatilityAccumulator,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event StaticFeeParametersSet(
        address indexed sender,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    );

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        uint24 activeId,
        bytes32 amounts,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event OracleLengthIncreased(address indexed sender, uint16 oracleLength);

    event ForcedDecay(address indexed sender, uint24 idReference, uint24 volatilityReference);

    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external;

    function getFactory() external view returns (ILBFactory factory);

    function getTokenX() external view returns (IERC20 tokenX);

    function getTokenY() external view returns (IERC20 tokenY);

    function getBinStep() external view returns (uint16 binStep);

    function getReserves() external view returns (uint128 reserveX, uint128 reserveY);

    function getActiveId() external view returns (uint24 activeId);

    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);

    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);

    function getProtocolFees() external view returns (uint128 protocolFeeX, uint128 protocolFeeY);

    function getStaticFeeParameters()
        external
        view
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        );

    function getVariableFeeParameters()
        external
        view
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate);

    function getOracleParameters()
        external
        view
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp);

    function getOracleSampleAt(uint40 lookupTimestamp)
        external
        view
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed);

    function getPriceFromId(uint24 id) external view returns (uint256 price);

    function getIdFromPrice(uint256 price) external view returns (uint24 id);

    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);

    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data) external;

    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted);

    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        returns (bytes32[] memory amounts);

    function collectProtocolFees() external returns (bytes32 collectedProtocolFees);

    function increaseOracleLength(uint16 newLength) external;

    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function forceDecay() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICurveStableDispatcher {
    function exchange(
        address pool, 
        bool isNativePool,
        int128 tokenInIndex, 
        int128 tokenOutIndex, 
        address tokenIn,
        address tokenOut,
        address to
    ) external;
    function exchange_underlying(
        address pool, 
        int128 tokenInIndex, 
        int128 tokenOutIndex,
        address tokenIn,
        address tokenOut,
        address to
    ) external;
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
pragma solidity >=0.8.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees()
        external
        view
        returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Pool state that can change
interface IAlgebraPoolState {
  /**
   * @notice The globalState structure in the pool stores many values but requires only one slot
   * and is exposed as a single method to save gas when accessed externally.
   * @return price The current price of the pool as a sqrt(token1/token0) Q64.96 value;
   * Returns tick The current tick of the pool, i.e. according to the last tick transition that was run;
   * Returns This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick
   * boundary;
   * Returns fee The last pool fee value in hundredths of a bip, i.e. 1e-6;
   * Returns timepointIndex The index of the last written timepoint;
   * Returns communityFeeToken0 The community fee percentage of the swap fee in thousandths (1e-3) for token0;
   * Returns communityFeeToken1 The community fee percentage of the swap fee in thousandths (1e-3) for token1;
   * Returns unlocked Whether the pool is currently locked to reentrancy;
   */
  function globalState()
    external
    view
    returns (
      uint160 price,
      int24 tick,
      uint16 fee,
      uint16 timepointIndex,
      uint8 communityFeeToken0,
      uint8 communityFeeToken1,
      bool unlocked
    );

  /**
   * @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
   * @dev This value can overflow the uint256
   */
  function totalFeeGrowth0Token() external view returns (uint256);

  /**
   * @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
   * @dev This value can overflow the uint256
   */
  function totalFeeGrowth1Token() external view returns (uint256);

  /**
   * @notice The currently in range liquidity available to the pool
   * @dev This value has no relationship to the total liquidity across all ticks.
   * Returned value cannot exceed type(uint128).max
   */
  function liquidity() external view returns (uint128);

  /**
   * @notice Look up information about a specific tick in the pool
   * @dev This is a public structure, so the `return` natspec tags are omitted.
   * @param tick The tick to look up
   * @return liquidityTotal the total amount of position liquidity that uses the pool either as tick lower or
   * tick upper;
   * Returns liquidityDelta how much liquidity changes when the pool price crosses the tick;
   * Returns outerFeeGrowth0Token the fee growth on the other side of the tick from the current tick in token0;
   * Returns outerFeeGrowth1Token the fee growth on the other side of the tick from the current tick in token1;
   * Returns outerTickCumulative the cumulative tick value on the other side of the tick from the current tick;
   * Returns outerSecondsPerLiquidity the seconds spent per liquidity on the other side of the tick from the current tick;
   * Returns outerSecondsSpent the seconds spent on the other side of the tick from the current tick;
   * Returns initialized Set to true if the tick is initialized, i.e. liquidityTotal is greater than 0
   * otherwise equal to false. Outside values can only be used if the tick is initialized.
   * In addition, these values are only relative and must be used only in comparison to previous snapshots for
   * a specific position.
   */
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityTotal,
      int128 liquidityDelta,
      uint256 outerFeeGrowth0Token,
      uint256 outerFeeGrowth1Token,
      int56 outerTickCumulative,
      uint160 outerSecondsPerLiquidity,
      uint32 outerSecondsSpent,
      bool initialized
    );

  /** @notice Returns 256 packed tick initialized boolean values. See TickTable for more information */
  function tickTable(int16 wordPosition) external view returns (uint256);

  /**
   * @notice Returns the information about a position by the position's key
   * @dev This is a public mapping of structures, so the `return` natspec tags are omitted.
   * @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
   * @return liquidityAmount The amount of liquidity in the position;
   * Returns lastLiquidityAddTimestamp Timestamp of last adding of liquidity;
   * Returns innerFeeGrowth0Token Fee growth of token0 inside the tick range as of the last mint/burn/poke;
   * Returns innerFeeGrowth1Token Fee growth of token1 inside the tick range as of the last mint/burn/poke;
   * Returns fees0 The computed amount of token0 owed to the position as of the last mint/burn/poke;
   * Returns fees1 The computed amount of token1 owed to the position as of the last mint/burn/poke
   */
  function positions(bytes32 key)
    external
    view
    returns (
      uint128 liquidityAmount,
      uint32 lastLiquidityAddTimestamp,
      uint256 innerFeeGrowth0Token,
      uint256 innerFeeGrowth1Token,
      uint128 fees0,
      uint128 fees1
    );

  /**
   * @notice Returns data about a specific timepoint index
   * @param index The element of the timepoints array to fetch
   * @dev You most likely want to use #getTimepoints() instead of this method to get an timepoint as of some amount of time
   * ago, rather than at a specific index in the array.
   * This is a public mapping of structures, so the `return` natspec tags are omitted.
   * @return initialized whether the timepoint has been initialized and the values are safe to use;
   * Returns blockTimestamp The timestamp of the timepoint;
   * Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp;
   * Returns secondsPerLiquidityCumulative the seconds per in range liquidity for the life of the pool as of the timepoint timestamp;
   * Returns volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp;
   * Returns averageTick Time-weighted average tick;
   * Returns volumePerLiquidityCumulative Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp;
   */
  function timepoints(uint256 index)
    external
    view
    returns (
      bool initialized,
      uint32 blockTimestamp,
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint88 volatilityCumulative,
      int24 averageTick,
      uint144 volumePerLiquidityCumulative
    );

  /**
   * @notice Returns the information about active incentive
   * @dev if there is no active incentive at the moment, virtualPool,endTimestamp,startTimestamp would be equal to 0
   * @return virtualPool The address of a virtual pool associated with the current active incentive
   */
  function activeIncentive() external view returns (address virtualPool);

  /**
   * @notice Returns the lock time for added liquidity
   */
  function liquidityCooldown() external view returns (uint32 cooldownInSeconds);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Permissionless pool actions
interface IAlgebraPoolActions {
  /**
   * @notice Sets the initial price for the pool
   * @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
   * @param price the initial sqrt price of the pool as a Q64.96
   */
  function initialize(uint160 price) external;

  /**
   * @notice Adds liquidity for the given recipient/bottomTick/topTick position
   * @dev The caller of this method receives a callback in the form of IAlgebraMintCallback# AlgebraMintCallback
   * in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
   * on bottomTick, topTick, the amount of liquidity, and the current price.
   * @param sender The address which will receive potential surplus of paid tokens
   * @param recipient The address for which the liquidity will be created
   * @param bottomTick The lower tick of the position in which to add liquidity
   * @param topTick The upper tick of the position in which to add liquidity
   * @param amount The desired amount of liquidity to mint
   * @param data Any data that should be passed through to the callback
   * @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
   * @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
   * @return liquidityActual The actual minted amount of liquidity
   */
  function mint(
    address sender,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount,
    bytes calldata data
  )
    external
    returns (
      uint256 amount0,
      uint256 amount1,
      uint128 liquidityActual
    );

  /**
   * @notice Collects tokens owed to a position
   * @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
   * Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
   * amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
   * actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
   * @param recipient The address which should receive the fees collected
   * @param bottomTick The lower tick of the position for which to collect fees
   * @param topTick The upper tick of the position for which to collect fees
   * @param amount0Requested How much token0 should be withdrawn from the fees owed
   * @param amount1Requested How much token1 should be withdrawn from the fees owed
   * @return amount0 The amount of fees collected in token0
   * @return amount1 The amount of fees collected in token1
   */
  function collect(
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  /**
   * @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
   * @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
   * @dev Fees must be collected separately via a call to #collect
   * @param bottomTick The lower tick of the position for which to burn liquidity
   * @param topTick The upper tick of the position for which to burn liquidity
   * @param amount How much liquidity to burn
   * @return amount0 The amount of token0 sent to the recipient
   * @return amount1 The amount of token1 sent to the recipient
   */
  function burn(
    int24 bottomTick,
    int24 topTick,
    uint128 amount
  ) external returns (uint256 amount0, uint256 amount1);

  /**
   * @notice Swap token0 for token1, or token1 for token0
   * @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback# AlgebraSwapCallback
   * @param recipient The address to receive the output of the swap
   * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
   * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
   * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
   * value after the swap. If one for zero, the price cannot be greater than this value after the swap
   * @param data Any data to be passed through to the callback. If using the Router it should contain
   * SwapRouter#SwapCallbackData
   * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
   * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
   */
  function swap(
    address recipient,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /**
   * @notice Swap token0 for token1, or token1 for token0 (tokens that have fee on transfer)
   * @dev The caller of this method receives a callback in the form of I AlgebraSwapCallback# AlgebraSwapCallback
   * @param sender The address called this function (Comes from the Router)
   * @param recipient The address to receive the output of the swap
   * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
   * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
   * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
   * value after the swap. If one for zero, the price cannot be greater than this value after the swap
   * @param data Any data to be passed through to the callback. If using the Router it should contain
   * SwapRouter#SwapCallbackData
   * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
   * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
   */
  function swapSupportingFeeOnInputTokens(
    address sender,
    address recipient,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /**
   * @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
   * @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback# AlgebraFlashCallback
   * @dev All excess tokens paid in the callback are distributed to liquidity providers as an additional fee. So this method can be used
   * to donate underlying tokens to currently in-range liquidity providers by calling with 0 amount{0,1} and sending
   * the donation amount(s) from the callback
   * @param recipient The address which will receive the token0 and token1 amounts
   * @param amount0 The amount of token0 to send
   * @param amount1 The amount of token1 to send
   * @param data Any data to be passed through to the callback
   */
  function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Pool state that never changes
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolImmutables {
  /**
   * @notice The contract that stores all the timepoints and can perform actions with them
   * @return The operator address
   */
  function dataStorageOperator() external view returns (address);

  /**
   * @notice The contract that deployed the pool, which must adhere to the IAlgebraFactory interface
   * @return The contract address
   */
  function factory() external view returns (address);

  /**
   * @notice The first of the two tokens of the pool, sorted by address
   * @return The token contract address
   */
  function token0() external view returns (address);

  /**
   * @notice The second of the two tokens of the pool, sorted by address
   * @return The token contract address
   */
  function token1() external view returns (address);

  /**
   * @notice The pool tick spacing
   * @dev Ticks can only be used at multiples of this value
   * e.g.: a tickSpacing of 60 means ticks can be initialized every 60th tick, i.e., ..., -120, -60, 0, 60, 120, ...
   * This value is an int24 to avoid casting even though it is always positive.
   * @return The tick spacing
   */
  function tickSpacing() external view returns (int24);

  /**
   * @notice The maximum amount of position liquidity that can use any tick in the range
   * @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
   * also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
   * @return The max amount of liquidity per tick
   */
  function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVaultUtils {
    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);
    function validateIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external view;
    function validateDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external view;
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256);
    function getPositionFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);
    function getFundingFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);
    function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdgAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ILBPair} from "./ILBPair.sol";
import {IPendingOwnable} from "./IPendingOwnable.sol";

/**
 * @title Liquidity Book Factory Interface
 * @author Trader Joe
 * @notice Required interface of LBFactory contract
 */
interface ILBFactory is IPendingOwnable {
    error LBFactory__IdenticalAddresses(IERC20 token);
    error LBFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset);
    error LBFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset);
    error LBFactory__AddressZero();
    error LBFactory__LBPairAlreadyExists(IERC20 tokenX, IERC20 tokenY, uint256 _binStep);
    error LBFactory__LBPairDoesNotExist(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__LBPairNotCreated(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__FlashLoanFeeAboveMax(uint256 fees, uint256 maxFees);
    error LBFactory__BinStepTooLow(uint256 binStep);
    error LBFactory__PresetIsLockedForUsers(address user, uint256 binStep);
    error LBFactory__LBPairIgnoredIsAlreadyInTheSameState();
    error LBFactory__BinStepHasNoPreset(uint256 binStep);
    error LBFactory__PresetOpenStateIsAlreadyInTheSameState();
    error LBFactory__SameFeeRecipient(address feeRecipient);
    error LBFactory__SameFlashLoanFee(uint256 flashLoanFee);
    error LBFactory__LBPairSafetyCheckFailed(address LBPairImplementation);
    error LBFactory__SameImplementation(address LBPairImplementation);
    error LBFactory__ImplementationNotSet();

    /**
     * @dev Structure to store the LBPair information, such as:
     * binStep: The bin step of the LBPair
     * LBPair: The address of the LBPair
     * createdByOwner: Whether the pair was created by the owner of the factory
     * ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
     */
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event PresetOpenStateChanged(uint256 indexed binStep, bool indexed isOpen);

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function getMinBinStep() external pure returns (uint256);

    function getFeeRecipient() external view returns (address);

    function getMaxFlashLoanFee() external pure returns (uint256);

    function getFlashLoanFee() external view returns (uint256);

    function getLBPairImplementation() external view returns (address);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairAtIndex(uint256 id) external returns (ILBPair);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAssetAtIndex(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint256 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            bool isOpen
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getOpenBinSteps() external view returns (uint256[] memory openBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address lbPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint16 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        bool isOpen
    ) external;

    function setPresetOpenState(uint16 binStep, bool isOpen) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair lbPair) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Liquidity Book Flashloan Callback Interface
/// @author Trader Joe
/// @notice Required interface to interact with LB flash loans
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(
        address sender,
        IERC20 tokenX,
        IERC20 tokenY,
        bytes32 amounts,
        bytes32 totalFees,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title Liquidity Book Token Interface
 * @author Trader Joe
 * @notice Interface to interact with the LBToken.
 */
interface ILBToken {
    error LBToken__AddressThisOrZero();
    error LBToken__InvalidLength();
    error LBToken__SelfApproval(address owner);
    error LBToken__SpenderNotApproved(address from, address spender);
    error LBToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
    error LBToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approveForAll(address spender, bool approved) external;

    function batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title Liquidity Book Pending Ownable Interface
 * @author Trader Joe
 * @notice Required interface of Pending Ownable contract used for LBFactory
 */
interface IPendingOwnable {
    error PendingOwnable__AddressZero();
    error PendingOwnable__NoPendingOwner();
    error PendingOwnable__NotOwner();
    error PendingOwnable__NotPendingOwner();
    error PendingOwnable__PendingOwnerAlreadySet();

    event PendingOwnerSet(address indexed pendingOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
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
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {InputStream} from './InputStream.sol';
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeTransferLib} from 'lib/solmate/src/utils/SafeTransferLib.sol';
import {IPair} from "../core/interfaces/IPair.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IStableSwapDispatcher} from "./interfaces/IStableSwapDispatcher.sol";
import {IFeeSettlement} from "./interfaces/IFeeSettlement.sol" ;
import {AdminUpgradeable} from "../libraries/AdminUpgradeable.sol";
import {Constants} from "../libraries/Constants.sol";
import {Commands} from "./modules/Commands.sol";

contract UniversalRouter is ReentrancyGuard, AdminUpgradeable {
    using SafeERC20 for IERC20;
    using SafeTransferLib for address;
    using InputStream for uint256;

    IStableSwapDispatcher public stableSwapDispatcher;
    IFeeSettlement public feeSettlement;

    error InvalidCommandCode(uint8 code);
    error WrongAmountInValue(uint256 accAmount, uint256 amountIn);
    error InsufficientOutAmount();
    error InvalidPool(address pool);

    event SetStableSwapDispatcher(IStableSwapDispatcher stableSwapDispatcher);
    event SetFeeSettlement(IFeeSettlement feeSettlement);
    
    constructor(
        IStableSwapDispatcher _stableSwapDispatcher,
        IFeeSettlement _feeSettlement
    ) {
        stableSwapDispatcher = _stableSwapDispatcher;
        feeSettlement = _feeSettlement;
        _initializeAdmin(msg.sender);
    }

    /// @notice To receive ETH from WETH
    receive() external payable {}

    /// @notice Set StableSwapDispatcher by admin
    /// @param _stableSwapDispatcher StableSwapDispatcher address
    function setStableSwapDispatcher(IStableSwapDispatcher _stableSwapDispatcher) external onlyAdmin {
        stableSwapDispatcher = _stableSwapDispatcher;
        emit SetStableSwapDispatcher(_stableSwapDispatcher);
    }

    /// @notice Set FeeSettlement by admin
    /// @param _feeSettlement FeeSettlement address
    function setFeeSettlement(IFeeSettlement _feeSettlement) external onlyAdmin {
        feeSettlement = _feeSettlement;
        emit SetFeeSettlement(_feeSettlement);
    }

    /// @notice Decodes and executes the given route
    /// @param tokenIn Address of the input token
    /// @param amountIn Amount of the input token
    /// @param tokenOut Address of the output token
    /// @param amountOutMin Minimum amount of the output token
    /// @param to Receiver address
    /// @param route The encoded route to execute with
    /// @return amountOut Actual amount of the output token
    function processRoute(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        address to,
        bytes memory route
    ) external payable nonReentrant returns (uint256 amountOut) {
        return processRouteInternal(tokenIn, amountIn, tokenOut, amountOutMin, to, route);
    }

    /// @notice Decodes and executes the given route
    /// @param tokenIn Address of the input token
    /// @param amountIn Amount of the input token
    /// @param tokenOut Address of the output token
    /// @param amountOutMin Minimum amount of the output token
    /// @param to Receiver address
    /// @param route The encoded route to execute with
    /// @return amountOut Actual amount of the output token
    function processRouteInternal(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        address to,
        bytes memory route
    ) private returns (uint256 amountOut) {
        uint256 amountInAcc = 0;
        uint256 balanceInitial = tokenOut == Constants.NATIVE_ADDRESS ? 
            address(to).balance 
            : IERC20(tokenOut).balanceOf(to);

        uint256 stream = InputStream.createStream(route);
        while (stream.isNotEmpty()) {
            uint8 commandCode = stream.readUint8();
            if (commandCode < 20) {
                // 0 <= command < 20
                if (commandCode == Commands.SWAP_UNISWAPV2_POOL) {
                    // UniswapV2 pool swap
                    swapUniswapV2Pool(stream);
                } else if (commandCode == Commands.DISTRIBUTE_ERC20_SHARES) {
                    // distribute ERC20 tokens from this router to pools
                    distributeERC20Shares(stream);
                } else if (commandCode == Commands.DISTRIBUTE_ERC20_AMOUNTS) {
                    // initial distribution
                    amountInAcc += distributeERC20Amounts(stream, tokenIn);
                } else if (commandCode == Commands.WRAP_AND_DISTRIBUTE_ERC20_AMOUNTS) {
                    // wrap natives and initial distribution 
                    amountInAcc += wrapAndDistributeERC20Amounts(stream, amountIn);
                } else if (commandCode == Commands.UNWRAP_NATIVE) {
                    // unwrap natives
                    unwrapNative(stream);
                } else {    
                    revert InvalidCommandCode(commandCode);
                }
            } else if (commandCode < 24) {
                // 20 <= command < 24
                if (commandCode == Commands.SWAP_ZENLINK_STABLESWAP) {
                    // Zenlink stable pool swap
                    swapZenlinkStableSwap(stream);
                } else {
                    revert InvalidCommandCode(commandCode);
                }
            } else {
                // placeholder area for commands 24-255
                revert InvalidCommandCode(commandCode);
            }
        }

        if (amountInAcc != amountIn) revert WrongAmountInValue(amountInAcc, amountIn);
        
        feeSettlement.processSettlement(tokenOut, amountOutMin, msg.sender, to);
        uint256 balanceFinal = tokenOut == Constants.NATIVE_ADDRESS ? 
            address(to).balance 
            : IERC20(tokenOut).balanceOf(to);
        if (balanceFinal < balanceInitial + amountOutMin) revert InsufficientOutAmount();
        amountOut = balanceFinal - balanceInitial;
    }

    /// @notice Performs a UniswapV2 pool swap
    /// @param stream [Pool, TokenIn, Direction, To]
    /// @return amountOut Amount of the output token
    function swapUniswapV2Pool(uint256 stream) private returns (uint256 amountOut) {
        address pool = stream.readAddress();
        address tokenIn = stream.readAddress();
        uint8 direction = stream.readUint8();
        address to = stream.readAddress();

        (uint256 reserve0, uint256 reserve1, ) = IPair(pool).getReserves();
        if (reserve0 == 0 || reserve1 == 0) revert InvalidPool(pool);
        (uint256 reserveIn, uint256 reserveOut) = direction == 1 
            ? (reserve0, reserve1) 
            : (reserve1, reserve0);

        uint256 amountIn = IERC20(tokenIn).balanceOf(pool) - reserveIn;
        uint256 amountInWithFee = amountIn * 997;
        amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
        (uint256 amount0Out, uint256 amount1Out) = direction == 1 
            ? (uint256(0), amountOut) 
            : (amountOut, uint256(0));

        IPair(pool).swap(amount0Out, amount1Out, to, new bytes(0));
    }

    /// @notice Performs a Zenlink stable pool swap
    /// @param stream [isMetaSwap, To, [Pool, Option(isNativePool), TokenInIndex, TokenOutIndex, TokenIn, TokenOut]]
    function swapZenlinkStableSwap(uint256 stream) private {
        uint8 isMetaSwap = stream.readUint8();
        address to = stream.readAddress();
        bytes memory swapData = stream.readBytes();
        
        if (isMetaSwap == 1) {
            (
                address pool,
                uint8 tokenInIndex, 
                uint8 tokenOutIndex, 
                address tokenIn,
                address tokenOut
            ) = abi.decode(
                swapData, 
                (address, uint8, uint8, address, address)
            );
            stableSwapDispatcher.swapUnderlying(
                pool, 
                tokenInIndex, 
                tokenOutIndex, 
                tokenIn, 
                tokenOut, 
                to
            );
        } else {
            (
                address pool,
                bool isNativePool,
                uint8 tokenInIndex, 
                uint8 tokenOutIndex, 
                address tokenIn,
                address tokenOut
            ) = abi.decode(
                swapData, 
                (address, bool, uint8, uint8, address, address)
            );
            stableSwapDispatcher.swap(
                pool, 
                isNativePool, 
                tokenInIndex, 
                tokenOutIndex, 
                tokenIn, 
                tokenOut, 
                to
            );
        }
    
    }

    /// @notice Distributes input ERC20 tokens from msg.sender to addresses. Tokens should be approved
    /// @param stream [ArrayLength, ...[To, Amount][]]. An array of destinations and token amounts
    /// @param token Token to distribute
    /// @return amountTotal Total amount distributed
    function distributeERC20Amounts(uint256 stream, address token) private returns (uint256 amountTotal) {
        uint8 num = stream.readUint8();
        amountTotal = 0;
        for (uint256 i = 0; i < num; ++i) {
            address to = stream.readAddress();
            uint256 amount = stream.readUint();
            amountTotal += amount;
            IERC20(token).safeTransferFrom(msg.sender, to, amount);
        }
    }

    /// @notice Wraps all native inputs and distributes wrapped ERC20 tokens from router to addresses
    /// @param stream [WrapToken, ArrayLength, ...[To, Amount][]]. An array of destinations and token amounts
    /// @return amountTotal Total amount distributed
    function wrapAndDistributeERC20Amounts(uint256 stream, uint256 amountIn) private returns (uint256 amountTotal) {
        address token = stream.readAddress();
        IWETH(token).deposit{value: amountIn}();
        uint8 num = stream.readUint8();
        amountTotal = 0;
        for (uint256 i = 0; i < num; ++i) {
            address to = stream.readAddress();
            uint256 amount = stream.readUint();
            amountTotal += amount;
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /// @notice Distributes ERC20 tokens from router to addresses
    /// @notice Quantity for sending is determined by share in 1/65535
    /// @notice During routing we can't predict in advance the actual value of internal swaps because of slippage,
    /// @notice so we have to work with shares - not fixed amounts
    /// @param stream [Token, ArrayLength, ...[To, ShareAmount][]]. Token to distribute. An array of destinations and token share amounts
    function distributeERC20Shares(uint256 stream) private {
        address token = stream.readAddress();
        uint8 num = stream.readUint8();
        // slot undrain protection
        uint256 amountTotal = IERC20(token).balanceOf(address(this)) - 1;     

        for (uint256 i = 0; i < num; ++i) {
            address to = stream.readAddress();
            uint16 share = stream.readUint16();
            uint256 amount = (amountTotal * share) / 65535;
            amountTotal -= amount;
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /// @notice Unwraps the Native Token
    /// @param stream [Token]. Token to unwrap native
    function unwrapNative(uint256 stream) private {
        address token = stream.readAddress();
        address receiver = stream.readAddress();
        uint256 amount = IERC20(token).balanceOf(address(this)) - 1;
        // slot undrain protection
        IWETH(token).withdraw(amount);     
        receiver.safeTransferETH(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Commands {
    // Command Types. Maximum supported command at this moment is 255.

    // Command Types where value<20, executed in the first nested-if block
    uint8 constant DISTRIBUTE_ERC20_AMOUNTS = 3;
    uint8 constant DISTRIBUTE_ERC20_SHARES = 4;
    uint8 constant WRAP_AND_DISTRIBUTE_ERC20_AMOUNTS = 5;
    uint8 constant UNWRAP_NATIVE = 6;
    uint8 constant SWAP_UNISWAPV2_POOL = 10;

    // Command Types where 20<=value<24, executed in the second nested-if block
    uint8 constant SWAP_ZENLINK_STABLESWAP = 20;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ICurveStableSwap} from "../../interfaces/curve/ICurveStableSwap.sol";
import {ICurveStableDispatcher} from "../../interfaces/curve/ICurveStableDispatcher.sol";
import {IWETH} from "../../interfaces/IWETH.sol";

contract CurveStableDispatcher is ICurveStableDispatcher {
    using SafeERC20 for IERC20;

    address public immutable weth;

    error InsufficientAmountIn();

    constructor(address _weth) {
        weth = _weth;
    }

    /// @notice To receive ETH from WETH
    receive() external payable {}

    function exchange(
        address _pool,
        bool _isNativePool,
        int128 _tokenInIndex,
        int128 _tokenOutIndex,
        address _tokenIn,
        address _tokenOut,
        address _to
    ) external override {
        ICurveStableSwap pool = ICurveStableSwap(_pool);
        IERC20 tokenIn = IERC20(_tokenIn);
        IERC20 tokenOut = IERC20(_tokenOut);
        bool isNativeTokenIn = _tokenIn == weth && _isNativePool;
        bool isNatvieTokenOut = _tokenOut == weth && _isNativePool;
        uint256 amountIn = tokenIn.balanceOf(address(this));
        if (amountIn == 0) revert InsufficientAmountIn();
        if (isNativeTokenIn) {
            IWETH(_tokenIn).withdraw(amountIn); 
            pool.exchange{value: address(this).balance}(
                _tokenInIndex, 
                _tokenOutIndex, 
                address(this).balance, 
                0
            );
        } else {
            tokenIn.safeIncreaseAllowance(address(pool), amountIn);
            pool.exchange(_tokenInIndex, _tokenOutIndex, amountIn, 0);
        }
        if (isNatvieTokenOut) {
            IWETH(_tokenOut).deposit{value: address(this).balance}();
        }
        tokenOut.safeTransfer(_to, tokenOut.balanceOf(address(this)));
    }

    function exchange_underlying(
        address _pool,
        int128 _tokenInIndex,
        int128 _tokenOutIndex,
        address _tokenIn,
        address _tokenOut,
        address _to
    ) external override {
        ICurveStableSwap metaPool = ICurveStableSwap(_pool);
        IERC20 tokenIn = IERC20(_tokenIn);
        IERC20 tokenOut = IERC20(_tokenOut);
        uint256 amountIn = tokenIn.balanceOf(address(this));
        if (amountIn == 0) revert InsufficientAmountIn();
        tokenIn.safeIncreaseAllowance(address(metaPool), amountIn);
        metaPool.exchange_underlying(
            _tokenInIndex,
            _tokenOutIndex,
            amountIn,
            0
        );
        tokenOut.safeTransfer(_to, tokenOut.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICurveStableSwap {
    // state modifying functions
    function exchange(
        int128 tokenIndexFrom,
        int128 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external payable returns (uint256);

    function exchange_underlying(
        int128 tokenIndexFrom,
        int128 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ILBFactory} from "../../../interfaces/joe/v2/ILBFactory.sol";
import {ILBPair} from "../../../interfaces/joe/v2/ILBPair.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract JoeV2StateMulticall {
    struct BinInfo {
        uint24 id;
        uint128 reserveX;
        uint128 reserveY;
    }

    struct StateResult {
        ILBPair pair;
        address tokenX;
        address tokenY;
        uint24 activeId;
        uint16 binStep;
        uint256 reserve0;
        uint256 reserve1;
        uint256 totalFee;
        BinInfo[] binInfos;
    }

    function getFullState(
        ILBFactory factory,
        IERC20 tokenX,
        IERC20 tokenY,
        uint256 leftBinLength,
        uint256 rightBinLength
    ) external view returns (StateResult[] memory states) {
        ILBFactory.LBPairInformation[] memory pairsInformation = factory.getAllLBPairs(tokenX, tokenY);
        uint256 numOfAvailablePairs = 0;

        for (uint256 i = 0; i < pairsInformation.length; i++) {
            if (pairsInformation[i].ignoredForRouting) {
                continue;
            } else {
                numOfAvailablePairs++;
            }
        }

        states = new StateResult[](numOfAvailablePairs);
        for (uint256 i = 0; i < pairsInformation.length; i++) {
            ILBFactory.LBPairInformation memory pairInformation = pairsInformation[i];
            if (pairInformation.ignoredForRouting) {
                continue;
            } else {
                ILBPair pair = pairInformation.LBPair;
                uint16 binStep = pairInformation.binStep;
                uint24 activeId = pair.getActiveId();
                StateResult memory state;
                state.pair = pair;
                state.tokenX = address(pair.getTokenX());
                state.tokenY = address(pair.getTokenY());
                state.activeId = activeId;
                state.binStep = binStep;
                (state.reserve0, state.reserve1) = pair.getReserves();
                {
                    (uint16 baseFactor, , , , uint24 variableFeeControl, , ) = pair.getStaticFeeParameters();
                    (uint24 volatilityAccumulator, , , ) = pair.getVariableFeeParameters();
                    uint256 baseFee = uint256(baseFactor) * binStep * 1e10;
                    uint256 variableFee;
                    if (variableFeeControl != 0) {
                        uint256 prod = uint256(volatilityAccumulator) * binStep;
                        variableFee = (prod * prod * variableFeeControl + 99) / 100;
                    }
                    state.totalFee = baseFee + variableFee;
                }
                state.binInfos = _getBinInfos(pair, leftBinLength, rightBinLength);
                states[i] = state;
            }
        }
    }

    function _getBinInfo( ILBPair pair, uint24 id) internal view returns (BinInfo memory) {
        (uint128 binReserveX, uint128 binReserveY) = pair.getBin(id);
        return BinInfo({
            id: id,
            reserveX: binReserveX,
            reserveY: binReserveY
        });
    }

    function _getBinInfos(
        ILBPair pair,
        uint256 leftBinLength,
        uint256 rightBinLength
    ) internal view returns (BinInfo[] memory binInfos) {
        binInfos = new BinInfo[](leftBinLength + rightBinLength + 1);
        uint24 activeId = pair.getActiveId();
        binInfos[leftBinLength] = _getBinInfo(pair, activeId);

        uint24 leftBinId = activeId;
        for (uint256 i = 0; i < leftBinLength; i++) {
            uint24 nextLeftBinId = pair.getNextNonEmptyBin(false, leftBinId);
            binInfos[leftBinLength - i - 1] = _getBinInfo(pair, nextLeftBinId);
            leftBinId = nextLeftBinId;
        }

        uint24 rightBinId = activeId;
        for (uint256 i = 0; i < rightBinLength; i++) {
            uint24 nextRightBinId = pair.getNextNonEmptyBin(true, rightBinId);
            binInfos[leftBinLength + i + 1] = _getBinInfo(pair, nextRightBinId);
            rightBinId = nextRightBinId;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IAlgebraPool} from "../../interfaces/algebra/IAlgebraPool.sol";
import {IAlgebraFactory} from "../../interfaces/algebra/IAlgebraFactory.sol";
import {IERC20Minimal} from "../../interfaces/IERC20Minimal.sol";

contract AlgebraStateMulticall {
    struct Slot0 {
        uint160 sqrtPriceX96;
        uint16 fee;
        int24 tick;
        uint16 observationIndex;
        uint8 communityFeeToken0;
        uint8 communityFeeToken1;
        bool unlocked;
    }

    struct TickBitMapMappings {
        int16 index;
        uint256 value;
    }

    struct TickInfo {
        uint128 liquidityGross;
        int128 liquidityNet;
        int56 tickCumulativeOutside;
        uint160 secondsPerLiquidityOutsideX128;
        uint32 secondsOutside;
        bool initialized;
    }

    struct TickInfoMappings {
        int24 index;
        TickInfo value;
    }

    struct Observation {
        uint32 blockTimestamp;
        int56 tickCumulative;
        uint160 secondsPerLiquidityCumulativeX128;
        bool initialized;
    }

    struct StateResult {
        IAlgebraPool pool;
        uint256 blockTimestamp;
        Slot0 slot0;
        uint128 liquidity;
        int24 tickSpacing;
        uint128 maxLiquidityPerTick;
        uint256 balance0;
        uint256 balance1;
        Observation observation;
        TickBitMapMappings[] tickBitmap;
        TickInfoMappings[] ticks;
    }

    function getFullStateWithRelativeBitmaps(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut,
        int16 leftBitmapAmount,
        int16 rightBitmapAmount
    ) external view returns (StateResult memory state) {
        require(leftBitmapAmount > 0, "leftBitmapAmount <= 0");
        require(rightBitmapAmount > 0, "rightBitmapAmount <= 0");

        state = _fillStateWithoutBitmapsAndTicks(
            factory,
            tokenIn,
            tokenOut
        );
        int16 currentBitmapIndex = _getBitmapIndexFromTick(
            state.slot0.tick / state.tickSpacing
        );

        state.tickBitmap = _calcTickBitmaps(
            factory,
            tokenIn,
            tokenOut,
            currentBitmapIndex - leftBitmapAmount,
            currentBitmapIndex + rightBitmapAmount
        );
    }

    function _fillStateWithoutBitmapsAndTicks(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut
    ) internal view returns (StateResult memory state) {
        IAlgebraPool pool = _getPool(factory, tokenIn, tokenOut);

        state.pool = pool;
        state.blockTimestamp = block.timestamp;
        state.liquidity = pool.liquidity();
        state.tickSpacing = pool.tickSpacing();
        state.maxLiquidityPerTick = pool.maxLiquidityPerTick();
        state.balance0 = _getBalance(pool.token0(), address(pool));
        state.balance1= _getBalance(pool.token1(), address(pool));

        (
            state.slot0.sqrtPriceX96,
            state.slot0.tick,
            state.slot0.fee,
            state.slot0.observationIndex,
            state.slot0.communityFeeToken0,
            state.slot0.communityFeeToken1,
            state.slot0.unlocked
        ) = pool.globalState();

        (
            state.observation.initialized,
            state.observation.blockTimestamp,
            state.observation.tickCumulative,
            state.observation.secondsPerLiquidityCumulativeX128,
            ,
            ,
        ) = pool.timepoints(state.slot0.observationIndex);
    }

    function _calcTickBitmaps(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) internal view returns (TickBitMapMappings[] memory tickBitmap) {
        IAlgebraPool pool = _getPool(factory, tokenIn, tokenOut);
        uint256 numberOfPopulatedBitmaps = 0;
        for (int256 i = tickBitmapStart; i <= tickBitmapEnd; i++) {
            uint256 bitmap = pool.tickTable(int16(i));
            if (bitmap == 0) continue;
            numberOfPopulatedBitmaps++;
        }

        tickBitmap = new TickBitMapMappings[](numberOfPopulatedBitmaps);
        uint256 globalIndex = 0;
        for (int256 i = tickBitmapStart; i <= tickBitmapEnd; i++) {
            int16 index = int16(i);
            uint256 bitmap = pool.tickTable(index);
            if (bitmap == 0) continue;

            tickBitmap[globalIndex] = TickBitMapMappings({
                index: index,
                value: bitmap
            });
            globalIndex++;
        }
    }

    function _getPool(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut
    ) internal view returns (IAlgebraPool pool) {
        pool = IAlgebraPool(factory.poolByPair(tokenIn, tokenOut));
        require(address(pool) != address(0), "Pool does not exist");
    }

    function _getBitmapIndexFromTick(int24 tick) internal pure returns (int16) {
        return int16(tick >> 8);
    }

    function _getBalance(address token, address pool) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, pool)
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title The interface for the Algebra Factory
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraFactory {
  /**
   *  @notice Emitted when the owner of the factory is changed
   *  @param newOwner The owner after the owner was changed
   */
  event Owner(address indexed newOwner);

  /**
   *  @notice Emitted when the vault address is changed
   *  @param newVaultAddress The vault address after the address was changed
   */
  event VaultAddress(address indexed newVaultAddress);

  /**
   *  @notice Emitted when a pool is created
   *  @param token0 The first token of the pool by address sort order
   *  @param token1 The second token of the pool by address sort order
   *  @param pool The address of the created pool
   */
  event Pool(address indexed token0, address indexed token1, address pool);

  /**
   *  @notice Emitted when the farming address is changed
   *  @param newFarmingAddress The farming address after the address was changed
   */
  event FarmingAddress(address indexed newFarmingAddress);

  event FeeConfiguration(
    uint16 alpha1,
    uint16 alpha2,
    uint32 beta1,
    uint32 beta2,
    uint16 gamma1,
    uint16 gamma2,
    uint32 volumeBeta,
    uint16 volumeGamma,
    uint16 baseFee
  );

  /**
   *  @notice Returns the current owner of the factory
   *  @dev Can be changed by the current owner via setOwner
   *  @return The address of the factory owner
   */
  function owner() external view returns (address);

  /**
   *  @notice Returns the current poolDeployerAddress
   *  @return The address of the poolDeployer
   */
  function poolDeployer() external view returns (address);

  /**
   * @dev Is retrieved from the pools to restrict calling
   * certain functions not by a tokenomics contract
   * @return The tokenomics contract address
   */
  function farmingAddress() external view returns (address);

  function vaultAddress() external view returns (address);

  /**
   *  @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
   *  @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
   *  @param tokenA The contract address of either token0 or token1
   *  @param tokenB The contract address of the other token
   *  @return pool The pool address
   */
  function poolByPair(address tokenA, address tokenB) external view returns (address pool);

  /**
   *  @notice Creates a pool for the given two tokens and fee
   *  @param tokenA One of the two tokens in the desired pool
   *  @param tokenB The other of the two tokens in the desired pool
   *  @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
   *  from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
   *  are invalid.
   *  @return pool The address of the newly created pool
   */
  function createPool(address tokenA, address tokenB) external returns (address pool);

  /**
   *  @notice Updates the owner of the factory
   *  @dev Must be called by the current owner
   *  @param _owner The new owner of the factory
   */
  function setOwner(address _owner) external;

  /**
   * @dev updates tokenomics address on the factory
   * @param _farmingAddress The new tokenomics contract address
   */
  function setFarmingAddress(address _farmingAddress) external;

  /**
   * @dev updates vault address on the factory
   * @param _vaultAddress The new vault contract address
   */
  function setVaultAddress(address _vaultAddress) external;

  /**
   * @notice Changes initial fee configuration for new pools
   * @dev changes coefficients for sigmoids: α / (1 + e^( (β-x) / γ))
   * alpha1 + alpha2 + baseFee (max possible fee) must be <= type(uint16).max
   * gammas must be > 0
   * @param alpha1 max value of the first sigmoid
   * @param alpha2 max value of the second sigmoid
   * @param beta1 shift along the x-axis for the first sigmoid
   * @param beta2 shift along the x-axis for the second sigmoid
   * @param gamma1 horizontal stretch factor for the first sigmoid
   * @param gamma2 horizontal stretch factor for the second sigmoid
   * @param volumeBeta shift along the x-axis for the outer volume-sigmoid
   * @param volumeGamma horizontal stretch factor the outer volume-sigmoid
   * @param baseFee minimum possible fee
   */
  function setBaseFeeConfiguration(
    uint16 alpha1,
    uint16 alpha2,
    uint32 beta1,
    uint32 beta2,
    uint16 gamma1,
    uint16 gamma2,
    uint32 volumeBeta,
    uint16 volumeGamma,
    uint16 baseFee
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IUniswapV3Pool} from "../../../interfaces/uniswap/v3/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "../../../interfaces/uniswap/v3/IUniswapV3Factory.sol";
import {IUniswapV3StateMulticall} from "../../../interfaces/uniswap/v3/IUniswapV3StateMulticall.sol";
import {IERC20Minimal} from "../../../interfaces/IERC20Minimal.sol";

contract UniswapV3StateMulticall is IUniswapV3StateMulticall {
    function getFullState(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view override returns (StateResult memory state) {
        require(
            tickBitmapEnd >= tickBitmapStart,
            "tickBitmapEnd < tickBitmapStart"
        );

        state = _fillStateWithoutTicks(
            factory,
            tokenIn,
            tokenOut,
            fee,
            tickBitmapStart,
            tickBitmapEnd
        );
        state.ticks = _calcTicksFromBitMap(
            factory,
            tokenIn,
            tokenOut,
            fee,
            state.tickBitmap
        );
    }

    function getFullStateWithoutTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view override returns (StateResult memory state) {
        require(
            tickBitmapEnd >= tickBitmapStart,
            "tickBitmapEnd < tickBitmapStart"
        );

        return
            _fillStateWithoutTicks(
                factory,
                tokenIn,
                tokenOut,
                fee,
                tickBitmapStart,
                tickBitmapEnd
            );
    }

    function getFullStateWithRelativeBitmaps(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int16 leftBitmapAmount,
        int16 rightBitmapAmount
    ) external view override returns (StateResult memory state) {
        require(leftBitmapAmount > 0, "leftBitmapAmount <= 0");
        require(rightBitmapAmount > 0, "rightBitmapAmount <= 0");

        state = _fillStateWithoutBitmapsAndTicks(
            factory,
            tokenIn,
            tokenOut,
            fee
        );
        int16 currentBitmapIndex = _getBitmapIndexFromTick(
            state.slot0.tick / state.tickSpacing
        );

        state.tickBitmap = _calcTickBitmaps(
            factory,
            tokenIn,
            tokenOut,
            fee,
            currentBitmapIndex - leftBitmapAmount,
            currentBitmapIndex + rightBitmapAmount
        );
    }

    function getAdditionalBitmapWithTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    )
        external
        view
        override
        returns (
            TickBitMapMappings[] memory tickBitmap,
            TickInfoMappings[] memory ticks
        )
    {
        require(
            tickBitmapEnd >= tickBitmapStart,
            "tickBitmapEnd < tickBitmapStart"
        );

        tickBitmap = _calcTickBitmaps(
            factory,
            tokenIn,
            tokenOut,
            fee,
            tickBitmapStart,
            tickBitmapEnd
        );
        ticks = _calcTicksFromBitMap(
            factory,
            tokenIn,
            tokenOut,
            fee,
            tickBitmap
        );
    }

    function getAdditionalBitmapWithoutTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view override returns (TickBitMapMappings[] memory tickBitmap) {
        require(
            tickBitmapEnd >= tickBitmapStart,
            "tickBitmapEnd < tickBitmapStart"
        );

        return
            _calcTickBitmaps(
                factory,
                tokenIn,
                tokenOut,
                fee,
                tickBitmapStart,
                tickBitmapEnd
            );
    }

    function _fillStateWithoutTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) internal view returns (StateResult memory state) {
        state = _fillStateWithoutBitmapsAndTicks(
            factory,
            tokenIn,
            tokenOut,
            fee
        );
        state.tickBitmap = _calcTickBitmaps(
            factory,
            tokenIn,
            tokenOut,
            fee,
            tickBitmapStart,
            tickBitmapEnd
        );
    }

    function _fillStateWithoutBitmapsAndTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) internal view returns (StateResult memory state) {
        IUniswapV3Pool pool = _getPool(factory, tokenIn, tokenOut, fee);

        state.pool = pool;
        state.blockTimestamp = block.timestamp;
        state.liquidity = pool.liquidity();
        state.tickSpacing = pool.tickSpacing();
        state.maxLiquidityPerTick = pool.maxLiquidityPerTick();
        state.balance0 = _getBalance(pool.token0(), address(pool));
        state.balance1= _getBalance(pool.token1(), address(pool));

        (
            state.slot0.sqrtPriceX96,
            state.slot0.tick,
            state.slot0.observationIndex,
            state.slot0.observationCardinality,
            state.slot0.observationCardinalityNext,
            state.slot0.feeProtocol,
            state.slot0.unlocked
        ) = pool.slot0();

        (
            state.observation.blockTimestamp,
            state.observation.tickCumulative,
            state.observation.secondsPerLiquidityCumulativeX128,
            state.observation.initialized
        ) = pool.observations(state.slot0.observationIndex);
    }

    function _calcTickBitmaps(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) internal view returns (TickBitMapMappings[] memory tickBitmap) {
        IUniswapV3Pool pool = _getPool(factory, tokenIn, tokenOut, fee);
        uint256 numberOfPopulatedBitmaps = 0;
        for (int256 i = tickBitmapStart; i <= tickBitmapEnd; i++) {
            uint256 bitmap = pool.tickBitmap(int16(i));
            if (bitmap == 0) continue;
            numberOfPopulatedBitmaps++;
        }

        tickBitmap = new TickBitMapMappings[](numberOfPopulatedBitmaps);
        uint256 globalIndex = 0;
        for (int256 i = tickBitmapStart; i <= tickBitmapEnd; i++) {
            int16 index = int16(i);
            uint256 bitmap = pool.tickBitmap(index);
            if (bitmap == 0) continue;

            tickBitmap[globalIndex] = TickBitMapMappings({
                index: index,
                value: bitmap
            });
            globalIndex++;
        }
    }

    function _calcTicksFromBitMap(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        TickBitMapMappings[] memory tickBitmap
    ) internal view returns (TickInfoMappings[] memory ticks) {
        IUniswapV3Pool pool = _getPool(factory, tokenIn, tokenOut, fee);

        uint256 numberOfPopulatedTicks = 0;
        for (uint256 i = 0; i < tickBitmap.length; i++) {
            uint256 bitmap = tickBitmap[i].value;

            for (uint256 j = 0; j < 256; j++) {
                if (bitmap & (1 << j) > 0) numberOfPopulatedTicks++;
            }
        }

        ticks = new TickInfoMappings[](numberOfPopulatedTicks);
        int24 tickSpacing = pool.tickSpacing();

        uint256 globalIndex = 0;
        for (uint256 i = 0; i < tickBitmap.length; i++) {
            uint256 bitmap = tickBitmap[i].value;

            for (uint256 j = 0; j < 256; j++) {
                if (bitmap & (1 << j) > 0) {
                    int24 populatedTick = ((int24(tickBitmap[i].index) << 8) +
                        int24(uint24(j))) * tickSpacing;

                    ticks[globalIndex].index = populatedTick;
                    TickInfo memory newTickInfo = ticks[globalIndex].value;

                    (
                        newTickInfo.liquidityGross,
                        newTickInfo.liquidityNet,
                        ,
                        ,
                        newTickInfo.tickCumulativeOutside,
                        newTickInfo.secondsPerLiquidityOutsideX128,
                        newTickInfo.secondsOutside,
                        newTickInfo.initialized
                    ) = pool.ticks(populatedTick);

                    globalIndex++;
                }
            }
        }
    }

    function _getPool(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool) {
        pool = IUniswapV3Pool(factory.getPool(tokenIn, tokenOut, fee));
        require(address(pool) != address(0), "Pool does not exist");
    }

    function _getBitmapIndexFromTick(int24 tick) internal pure returns (int16) {
        return int16(tick >> 8);
    }

    function _getBalance(address token, address pool) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, pool)
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IUniswapV3Pool} from "./IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "./IUniswapV3Factory.sol";

interface IUniswapV3StateMulticall {
    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint8 feeProtocol;
        bool unlocked;
    }

    struct TickBitMapMappings {
        int16 index;
        uint256 value;
    }

    struct TickInfo {
        uint128 liquidityGross;
        int128 liquidityNet;
        int56 tickCumulativeOutside;
        uint160 secondsPerLiquidityOutsideX128;
        uint32 secondsOutside;
        bool initialized;
    }

    struct TickInfoMappings {
        int24 index;
        TickInfo value;
    }

    struct Observation {
        uint32 blockTimestamp;
        int56 tickCumulative;
        uint160 secondsPerLiquidityCumulativeX128;
        bool initialized;
    }

    struct StateResult {
        IUniswapV3Pool pool;
        uint256 blockTimestamp;
        Slot0 slot0;
        uint128 liquidity;
        int24 tickSpacing;
        uint128 maxLiquidityPerTick;
        uint256 balance0;
        uint256 balance1;
        Observation observation;
        TickBitMapMappings[] tickBitmap;
        TickInfoMappings[] ticks;
    }

    function getFullState(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view returns (StateResult memory state);

    function getFullStateWithoutTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view returns (StateResult memory state);

    function getFullStateWithRelativeBitmaps(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int16 leftBitmapAmount,
        int16 rightBitmapAmount
    ) external view returns (StateResult memory state);

    function getAdditionalBitmapWithTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    )
        external
        view
        returns (
            TickBitMapMappings[] memory tickBitmap,
            TickInfoMappings[] memory ticks
        );

    function getAdditionalBitmapWithoutTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view returns (TickBitMapMappings[] memory tickBitmap);
}