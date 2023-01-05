/**
 *Submitted for verification at Arbiscan on 2023-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function internalOwnerCheck() internal view {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        internalOwnerCheck();
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
}

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

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IBoosterNFT {
    function getNftType(uint256 tokenId) external view returns (uint8 index);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

interface IUniwFarm {
    function deposit(uint256 _pid, uint256 _amount, address _referrer) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingToken(uint256 _pid, address _user) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
}

/**
 * @dev LockedFarm
 */
contract LockedFarm is Ownable, ReentrancyGuard{
    using SafeBEP20 for IBEP20;


    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 unlockTimestamp;
        uint256 harvestUnlockTimestamp;
    }

    struct NFTDetails {
        address nftAddress;
        uint256 tokenId;
    }

    mapping(address => UserInfo) public userInfo;
    address public devWallet;

    uint256 public lastRewardBlock;
    uint256 public accTokenPerShare;

    IBEP20 public stakeToken;
    IBEP20 public rewardToken;

    IUniwFarm public uniwFarm;
    uint256 public FARM_PID = 0;

    uint256 public startBlock;
    uint256 public totalStakedAmount;

    uint256 public depositFeeInPer;
    uint256 public minDepositAllowed;
    uint256 public emergencyWithdrawFee;
    uint256 public depositLockingPeriod;
    uint256 public harvestLockingPeriod;

    uint256 public constant PRECISION = 10**18;

    address public boosterNFT;
    mapping(uint8 => uint256) public nftBoostDiscount;
    mapping(address => NFTDetails) public stakedNFTDetails; // user => nft Details;

    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 depositFee,
        uint256 unlockTimestamp
    );
    event Withdraw(
        address indexed user, 
        uint256 amount
    );
    event DepositNFT(
        address indexed user, 
        address indexed nftAddress, 
        uint256 _nftIndex
    );
    event WithdrawNFT(
        address indexed user, 
        address indexed nftAddress, 
        uint256 _nftIndex
    );
    event Harvest(
        address indexed user,
        uint256 amount
    );
    event UpdateDepositFee(
        address indexed user, 
        uint256 depositFeeInPer
    );
    event UpdateEmergWithdrawFee(
        address indexed user, 
        uint256 feeInPer
    );
    event UpdateMinDepositValue(
        address indexed user, 
        uint256 minDepositValue
    );
    event UpdateDepositLockingPeriod(
        address indexed user, 
        uint256 lockingPeriod
    );
    event UpdateHarvestLockingPeriod(
        address indexed user, 
        uint256 lockingPeriod
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount
    );
    event UpdateNFTBoostDiscount(
        address indexed user, 
        uint8 nftType, 
        uint256 discountPer
    );
    event BEP20Withdraw(
        address indexed user,
        address indexed token, 
        address to, 
        uint256 amount
    );


    constructor(
        IBEP20 _stakeToken,
        IBEP20 _rewardToken,
        address _boosterNFT,
        IUniwFarm _uniwFarm,
        uint256 _farmPid,
        uint256 _startBlock,
        uint256 _depositFeeInPer,
        uint256 _depositLockingPeriod,
        uint256 _harvestLockingPeriod,
        uint256[] memory  _nftBoostDiscount,
        address _devWallet
    ) {
        require(_depositFeeInPer <= 1000, "DepositFee cannot be > 10%");

        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        boosterNFT = _boosterNFT;
        uniwFarm = _uniwFarm;
        FARM_PID = _farmPid;
        startBlock = _startBlock;
        depositFeeInPer = _depositFeeInPer;
        depositLockingPeriod = _depositLockingPeriod; 
        harvestLockingPeriod = _harvestLockingPeriod;
        devWallet = _devWallet;
        lastRewardBlock = _startBlock;
        minDepositAllowed = 1e18; // min 1 LP token need to contributed for deposit
        emergencyWithdrawFee = 5000; // 50% fee will be deducted

        for(uint8 i; i < _nftBoostDiscount.length; i++) {
            nftBoostDiscount[i] = _nftBoostDiscount[i];
        }

        stakeToken.approve(address(uniwFarm), type(uint256).max);
    }

    function getBoostDiscount(address _user) public view returns (uint256) {
        NFTDetails memory nftDetail = stakedNFTDetails[_user];
        if (nftDetail.nftAddress == address(0x0)) {
            return 0;
        }
        uint8 _nftType = IBoosterNFT(boosterNFT).getNftType(nftDetail.tokenId);

        return nftBoostDiscount[_nftType];
    }

    function getStakedNFTDetails(address _account) public view returns (address, uint256, uint256) {
        return (stakedNFTDetails[_account].nftAddress, stakedNFTDetails[_account].tokenId, userInfo[_account].unlockTimestamp);
    }

    function getUserInfo(address _user) external view returns (uint256, uint256, uint256, uint256) {
        return (userInfo[_user].amount, userInfo[_user].rewardDebt, userInfo[_user].unlockTimestamp, userInfo[_user].harvestUnlockTimestamp);
    }

    function pendingReward(address _user) external view returns (uint256) {
        UserInfo memory user = userInfo[_user];

        if (user.amount == 0) {
            return 0;
        }

        uint256 pendingUniwInFarm = uniwFarm.pendingToken(FARM_PID, address(this));
        return
            (user.amount * (accTokenPerShare + ((PRECISION * pendingUniwInFarm) / totalStakedAmount))) /
            PRECISION -
            user.rewardDebt;
    }

    // Depositing of NFTs
    function depositNFT(address _nft, uint256 _tokenId) public nonReentrant {
        require(_nft == boosterNFT, "Not a BoosterNFT!!");
        require(IBoosterNFT(_nft).ownerOf(_tokenId) == msg.sender, "user does not have specified NFT");

        NFTDetails memory nftDetail = stakedNFTDetails[msg.sender];
        require(nftDetail.nftAddress == address(0x0), "user have already boosted pool by Staking NFT");
        
        IBoosterNFT(_nft).transferFrom(msg.sender, address(this), _tokenId);

        nftDetail.nftAddress = _nft;
        nftDetail.tokenId = _tokenId;

        stakedNFTDetails[msg.sender] = nftDetail;

        UserInfo storage user = userInfo[msg.sender];
        if (user.amount > 0 && user.unlockTimestamp > block.timestamp) {
            uint256 boostDiscount = getBoostDiscount(msg.sender);
            if (boostDiscount > 0) {
                uint256 remainingLockingPeriod = user.unlockTimestamp - block.timestamp;
                uint256 reducedLockingPeriod = (remainingLockingPeriod * boostDiscount) / 10000;
                user.unlockTimestamp = user.unlockTimestamp - reducedLockingPeriod;

                if (user.harvestUnlockTimestamp > block.timestamp) {
                    remainingLockingPeriod = user.harvestUnlockTimestamp - block.timestamp;
                    reducedLockingPeriod = (remainingLockingPeriod * boostDiscount) / 10000;
                    user.harvestUnlockTimestamp = user.harvestUnlockTimestamp - reducedLockingPeriod;
                }
            }
        }

        emit DepositNFT(msg.sender, _nft, _tokenId);
    }


    // Withdrawing of NFTs
    function withdrawNFT() public nonReentrant {
        NFTDetails memory nftDetail = stakedNFTDetails[msg.sender];
        require(nftDetail.nftAddress != address(0x0), "user has not staked any NFT!!!");
        require(block.timestamp >= userInfo[msg.sender].unlockTimestamp, "NFT is Locked!!");

        address _nft = nftDetail.nftAddress;
        uint256 _tokenId = nftDetail.tokenId;

        delete stakedNFTDetails[msg.sender];
        
        IBoosterNFT(_nft).transferFrom(address(this), msg.sender, _tokenId);

        emit WithdrawNFT(msg.sender, _nft, _tokenId);
    }

    function deposit(uint256 _amount) public nonReentrant {
        require(block.number >= startBlock, "LockedFarm: Farm is yet to started!!");
        require(_amount >= minDepositAllowed, "LockedFarm: deposit value should be > min Value");

        farmHarvest();

        UserInfo storage user = userInfo[msg.sender];

        if (user.amount > 0) {
            if (_amount == 0){
                require(block.timestamp >= user.harvestUnlockTimestamp, "harvest is in locking time!!");
            }

            uint256 pending = (user.amount * accTokenPerShare) / PRECISION - user.rewardDebt;
            if (pending > 0) {
                // In case of rounding error, contract does not have enough uniw
                uint256 tokenBalance = rewardToken.balanceOf(address(this));
                if (tokenBalance < pending) {
                  pending = tokenBalance;
                }
                if (_amount == 0) {
                    uint256 boostDiscount = getBoostDiscount(msg.sender);
                    uint256 discountedLockingPeriod = harvestLockingPeriod - ((harvestLockingPeriod * boostDiscount) / 10000);
                    user.harvestUnlockTimestamp = block.timestamp + discountedLockingPeriod;
                }

                rewardToken.safeTransfer(msg.sender, pending);

                emit Harvest(msg.sender, pending);
            }
        }

        uint256 depositFee;
        if (_amount > 0) {
            stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
            if (depositFeeInPer > 0) {
                depositFee = _amount * depositFeeInPer / 10000;
                stakeToken.safeTransfer(devWallet, depositFee);
            }

            user.amount += (_amount - depositFee);
            uint256 boostDiscount = getBoostDiscount(msg.sender);
            uint256 discountedLockingPeriod = depositLockingPeriod - ((depositLockingPeriod * boostDiscount) / 10000);
            user.unlockTimestamp = block.timestamp + discountedLockingPeriod;

            totalStakedAmount += (_amount - depositFee);
            farmDeposit();
        }

        user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION;
        userInfo[msg.sender] = user;

        emit Deposit( msg.sender, _amount, depositFee, user.unlockTimestamp);
    }

    function withdraw(uint256 _amount) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(_amount <= user.amount, "LockedFarm: Requested amount is more then staked!!");
        require(block.timestamp >= user.unlockTimestamp, "LockedFarm: Not Ready for Withdrawal");

        farmHarvest();

        if (user.amount > 0) {
            uint256 pending = (user.amount * accTokenPerShare) / PRECISION - user.rewardDebt;
            if (pending > 0) {
                // In case of rounding error, contract does not have enough reward Token
                uint256 tokenBalance = rewardToken.balanceOf(address(this));
                if (tokenBalance < pending) {
                  pending = tokenBalance;
                }
                rewardToken.safeTransfer(msg.sender, pending);

                uint256 boostDiscount = getBoostDiscount(msg.sender);
                uint256 discountedLockingPeriod = harvestLockingPeriod - ((harvestLockingPeriod * boostDiscount) / 10000);
                user.harvestUnlockTimestamp = block.timestamp + discountedLockingPeriod;

                emit Harvest(msg.sender, pending);
            }
        }

        if (_amount < user.amount) {
            uint256 boostDiscount = getBoostDiscount(msg.sender);
            uint256 discountedLockingPeriod = depositLockingPeriod - ((depositLockingPeriod * boostDiscount) / 10000);
            user.unlockTimestamp = block.timestamp + discountedLockingPeriod;
        }
        
        user.amount = user.amount - _amount;
        totalStakedAmount = totalStakedAmount - _amount;

        user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION;
        userInfo[msg.sender] = user;

        uint256 stakedTokenBalance = stakeToken.balanceOf(address(this));
        if (stakedTokenBalance < _amount) {
            farmWithdraw(_amount - stakedTokenBalance);
        }
        
        stakeToken.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    function harvestReward() public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "LockedFarm: deposit value should be > then 0");
        require(block.timestamp >= user.harvestUnlockTimestamp, "harvest is in locking time!!");

        farmHarvest();

        uint256 pending = (user.amount * accTokenPerShare) / PRECISION - user.rewardDebt;
        if (pending > 0) {
            // In case of rounding error, contract does not have enough uniw
            uint256 tokenBalance = rewardToken.balanceOf(address(this));
            if (tokenBalance < pending) {
                pending = tokenBalance;
            }
            
            uint256 boostDiscount = getBoostDiscount(msg.sender);
            uint256 discountedLockingPeriod = harvestLockingPeriod - ((harvestLockingPeriod * boostDiscount) / 10000);

            user.harvestUnlockTimestamp = block.timestamp + discountedLockingPeriod;
            user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION;
            userInfo[msg.sender] = user;

            rewardToken.safeTransfer(msg.sender, pending);

            emit Harvest(msg.sender, pending);
        }
    }

    function emergencyWithdraw() public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "LockedFarm: Nothing to withdraw!!");

        farmHarvest();

        uint256 withdrawFee;
        uint256 pending = (user.amount * accTokenPerShare) / PRECISION - user.rewardDebt;
        if (pending > 0) {
            // In case of rounding error, contract does not have enough reward Token
            uint256 tokenBalance = rewardToken.balanceOf(address(this));
            if (tokenBalance < pending) {
                pending = tokenBalance;
            }
            withdrawFee = (pending * emergencyWithdrawFee) / 10000;
            rewardToken.safeTransfer(msg.sender, pending - withdrawFee);
            if (withdrawFee > 0) {
                rewardToken.safeTransfer(devWallet, withdrawFee);
            }

            emit Harvest(msg.sender, pending);
        }
        uint256 stakeAmount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.unlockTimestamp = 0;
        user.harvestUnlockTimestamp = 0;

        // User will get 50% of staked Amount and other 50% will go to dev
        withdrawFee = (stakeAmount * emergencyWithdrawFee) / 10000;
        uint256 withdrawAmount = stakeAmount - withdrawFee;
        totalStakedAmount = totalStakedAmount - stakeAmount;

        uint256 stakedTokenBalance = stakeToken.balanceOf(address(this));
        if (stakedTokenBalance < stakeAmount) {
            farmWithdraw(stakeAmount - stakedTokenBalance);
        }
        
        stakeToken.safeTransfer(msg.sender, withdrawAmount);
        if (withdrawFee > 0) {
            stakeToken.safeTransfer(devWallet, withdrawFee);
        }

        emit EmergencyWithdraw(msg.sender, withdrawAmount);

        NFTDetails memory nftDetail = stakedNFTDetails[msg.sender];
        if (nftDetail.nftAddress != address(0x0)) {
            address _nft = nftDetail.nftAddress;
            uint256 _tokenId = nftDetail.tokenId;

            delete stakedNFTDetails[msg.sender];
            
            IBoosterNFT(_nft).transferFrom(address(this), msg.sender, _tokenId);

            emit WithdrawNFT(msg.sender, _nft, _tokenId);
        }
    }
 

    /**Masterchef Functions */
    function farmDeposit() internal {
        uint256 tokenBalance = stakeToken.balanceOf(address(this));
        uniwFarm.deposit(FARM_PID, tokenBalance, address(0x0));
    }

    function farmWithdraw(uint256 _amount) internal {
        uniwFarm.withdraw(FARM_PID, _amount);
    }

    function farmHarvest() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalStakedAmount == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 lastRewardTokenBalance = rewardToken.balanceOf(address(this));
        uniwFarm.deposit(FARM_PID, 0, address(0x0));
        uint256 harvestedAmount = rewardToken.balanceOf(address(this)) - lastRewardTokenBalance;
        
        accTokenPerShare += (PRECISION * harvestedAmount) / totalStakedAmount;
        lastRewardBlock = block.number;
    }

    function farmEmergencyWithdraw() public onlyOwner {
        uniwFarm.emergencyWithdraw(FARM_PID);
    }
    /**End of Masterchef Functions */

    function updateDepositLockingPeriod(uint256 _lockingPeriod) public onlyOwner {
        depositLockingPeriod = _lockingPeriod;

        emit UpdateDepositLockingPeriod(msg.sender, depositLockingPeriod);
    }

    function updateHarvestLockingPeriod(uint256 _lockingPeriod) public onlyOwner {
        harvestLockingPeriod = _lockingPeriod;
        
        emit UpdateHarvestLockingPeriod(msg.sender, harvestLockingPeriod);
    }

    function updateDepositFee(uint256 _depositFeeInPer) public onlyOwner {
        require(_depositFeeInPer <= 1000, "_depositFeeInPer cannot be > 10%");

        depositFeeInPer = _depositFeeInPer;

        emit UpdateDepositFee(msg.sender, depositFeeInPer);
    }

    function updateEmergWithdrawFee(uint256 _feeInPer) public onlyOwner {
        require(_feeInPer <= 10000, "emergencyWithdrawFee cannot be > 100%");

        emergencyWithdrawFee = _feeInPer;

        emit UpdateEmergWithdrawFee(msg.sender, _feeInPer);
    }

    function updateMinDepositValue(uint256 _amount) public onlyOwner {
        minDepositAllowed = _amount;

        emit UpdateMinDepositValue(msg.sender, _amount);
    }

    function updateFarmPid(uint256 _farmPid) public onlyOwner {
        (uint256 stakedAmount, ) = uniwFarm.userInfo(FARM_PID, address(this));
        require(stakedAmount == 0, "you can't modify PID!!");

        FARM_PID = _farmPid;
    }
    
    function setdevWallet(address _devWallet) public onlyOwner {
        require(_devWallet != address(0x0), "_devWallet address should be valid address");

        devWallet = _devWallet;
    }
    
    function setNftBoostDiscount(uint8 _nftType, uint256 _rate) public onlyOwner {
        nftBoostDiscount[_nftType] = _rate;
        emit UpdateNFTBoostDiscount(msg.sender, _nftType, _rate);
    }
    
    function setBoosterNFT(address _booterNFT) public onlyOwner {
        require(_booterNFT != address(0x0), "_booterNFT address should be valid address");

        boosterNFT = _booterNFT;
    }

    function bep20Withdraw(address _token, address _to, uint256 _amount) public onlyOwner {
        IBEP20(_token).transfer(_to, _amount);

        emit BEP20Withdraw(msg.sender, _token, _to, _amount);
    }
}