// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../../interface/IERC20.sol";
import "../../interface/IVe.sol";
import "../../lib/SafeERC20.sol";
import "../../lib/ReentrancyGuard.sol";

contract AirDropCommon is ReentrancyGuard{
    using SafeERC20 for IERC20;

    IERC20 public immutable token;

    uint256 internal constant LOCK_TIME = 2 * 365 * 86400;

    uint256 public startTime;

    mapping(address => uint256) public whiteList;
    mapping(address => uint256) public userClimedAmount;

    address public owner;

    uint256 internal constant PRECISION = 10**18;

    address public ve;

    constructor(address _ve,uint256 _startTime, IERC20 _token) {
        ve = _ve;
        startTime = _startTime;
        token = _token;
        owner = msg.sender;
    }

    function setStartTime(uint256 _startTime) external  {
        require(owner == msg.sender, "not owner");
        startTime = _startTime;
    }

    function setOwner(address _newOwner) external  {
        require(owner == msg.sender, "not owner");
        owner = _newOwner;
    }

    function addWhiteList(address[] memory addressList,uint256[] memory amounts) external {
        require(owner == msg.sender, "not owner");
        require(addressList.length == amounts.length, "error data");
        for (uint256 i = 0; i < addressList.length; i++) {
            whiteList[addressList[i]] += amounts[i];   
        }
    }

   function claim() external nonReentrant {
        require(
            block.timestamp >= startTime ,
            "not start"
        );

        require(
            whiteList[msg.sender] > 0,
            "error amount"
        );

        uint256 useramount = whiteList[msg.sender] ;

        IERC20(token).approve(address(ve), type(uint).max);

        IVe(ve).createLockFor(useramount, LOCK_TIME, msg.sender);
        
        userClimedAmount[msg.sender] += useramount;
        whiteList[msg.sender] = 0;
    }
    

    function finish() external {
        require(owner == msg.sender, "not owner");
        uint256 _balanceOf = token.balanceOf(address(this));

        if(_balanceOf > 0) {
            token.safeTransfer(owner, _balanceOf);   
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IVe {

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE
    }

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint ts;
        uint blk; // block
    }
    /* We cannot really do block numbers per se b/c slope is per time, not per block
    * and per block could be fairly bad b/c Ethereum changes blocktimes.
    * What we can do is to extrapolate ***At functions */

    struct LockedBalance {
        int128 amount;
        uint end;
    }

    function token() external view returns (address);

    function balanceOfNFT(uint) external view returns (uint);

    function isApprovedOrOwner(address, uint) external view returns (bool);

    function createLockFor(uint, uint, address) external returns (uint);

    function userPointEpoch(uint tokenId) external view returns (uint);

    function epoch() external view returns (uint);

    function userPointHistory(uint tokenId, uint loc) external view returns (Point memory);

    function pointHistory(uint loc) external view returns (Point memory);

    function checkpoint() external;

    function depositFor(uint tokenId, uint value) external;

    function attachToken(uint tokenId) external;

    function detachToken(uint tokenId) external;

    function voting(uint tokenId) external;

    function abstain(uint tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.15;

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

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call(data);
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
pragma solidity 0.8.15;

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.15;

import "../interface/IERC20.sol";
import "./Address.sol";

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
        uint value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint value
    ) internal {
        uint newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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