/**
 *Submitted for verification at Arbiscan on 2023-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IArbiDexRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface ISmartChefInitializable {
    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
    }
    function userInfo(address user) external view returns (uint256, uint256);
    function stakedToken() external view returns (address);
    function rewardToken() external view returns (address);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
}

/*
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

// File: @openzeppelin/contracts/access/Ownable.sol

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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
     * by making the `nonReentrant` function external, and make it call a
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

// File: @openzeppelin/contracts/utils/Address.sol

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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

// File: "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

contract AutoCompound is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;
    // The address of the treasury where all of the deposit and performance fees are sent
    address public treasury;

    // The address of the router that is used for conducting swaps
    address immutable public router;

    // The address of the underlying staker where the deposits and withdrawals are made
    address immutable public staker;

    // The reward token
    address immutable public rewardToken;

    // The staked token
    address immutable public stakedToken;

    // The address of the USDC token
    address immutable USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    // The address of the USDT token
    address immutable USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    // The fee associated with depositing into the Auto Compounder
    uint256 public depositFee = 100;

    // The performance fee associated whenever the farm/pool is Auto Compounded
    uint256 public performanceFee = 450;

    // The minimum amount of reward tokens required for swapping of harvested tokens to occur
    uint256 public minimumHarvest;

    // The total supply of staked tokens, that have be deposited by users
    uint256 totalSupply;

    // An array of the tokens utilized in swapping from reward token back into staked token (during harvesting)
    address[] path;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
    }

    constructor(
        address _treasury,
        address _router,
        address _staker,
        uint256 _minimumHarvest
    ) {
        treasury = _treasury;
        router = _router;
        staker = _staker;
        rewardToken = ISmartChefInitializable(staker).rewardToken();
        stakedToken = ISmartChefInitializable(staker).stakedToken();
        minimumHarvest = _minimumHarvest;

        if (rewardToken != USDC) {
            path = new address[](4);
            path[0] = rewardToken; path[1] = USDT; path[2] = USDC; path[3] = stakedToken;
        } else {
            path = new address[](2);
            path[0] = rewardToken; path[1] = stakedToken;
        }
    }

    event Harvest(uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event TokenRecovery(address indexed token, uint256 amount);
    event NewMinimumHarvest(uint256 amount);
    event NewPerformanceFee(uint256 amount);
    event NewDepositFee(uint256 amount);
    event DepositFeeCharged(uint256 amount);
    event PerformanceFeeCharged(uint256 amount);
    event TreasuryAddressChanged(address treasury);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    /*
     * @notice Harvest all avaiable rewards and then convert them back into the staked token to compound the interest being made
     */
    function harvest() public {
        // Lets harvest the tokens from the underlying staker
        ISmartChefInitializable(staker).deposit(0);
        uint256 harvested = IERC20Metadata(rewardToken).balanceOf(address(this));

        // Check to see if we have the minimum amount of reward tokens harvested
        if (harvested < minimumHarvest || harvested == 0 || totalSupply == 0) {return;}

        // Check allowance and see if we need to update
        if (harvested > IERC20Metadata(rewardToken).allowance(address(this), router)) {
            IERC20Metadata(rewardToken).safeApprove(router, type(uint256).max);
        }

        // Calculate the performance fee for this harvest, and send it to the treasury
        if (performanceFee > 0) {
            uint256 feeAmount = (harvested * performanceFee)/10000;
            harvested -= feeAmount;
            IERC20Metadata(rewardToken).safeTransfer(treasury, feeAmount);
            emit PerformanceFeeCharged(feeAmount);
        }

        // Lets' compute the amount of tokens we will get out for swapping from reward to staked token
        uint256[] memory amounts = IArbiDexRouter(router).getAmountsOut(harvested, path);
        // As long as we get 90% of our tokens back from the swap we are good to go
        uint256 amountOutMin = (amounts[amounts.length-1] * 90)/100;
        // Execute the swap and get the staked token
        IArbiDexRouter(router).swapExactTokensForTokens(harvested, amountOutMin, path, address(this), block.timestamp);

        // Lets' see how many staked token we received from doing the swap and then deposit those into the underlying staker
        uint256 compounded = IERC20(stakedToken).balanceOf(address(this));
        ISmartChefInitializable(staker).deposit(compounded);

        emit Harvest(compounded);
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(_amount > 0, "Deposit: Amount to deposit must be greater than zero");

        // Check allowance and see if we need to update
        if (_amount > IERC20Metadata(stakedToken).allowance(address(this), staker)) {
            IERC20Metadata(stakedToken).safeApprove(staker, type(uint256).max);
        }

        harvest();

        IERC20Metadata(stakedToken).safeTransferFrom(address(msg.sender), address(this), _amount);
        
        if (depositFee > 0) {
            uint256 feeAmount = (_amount * depositFee)/10000;
            _amount -= feeAmount;
            IERC20Metadata(stakedToken).safeTransfer(treasury, feeAmount);
            emit DepositFeeCharged(feeAmount);
        }
        
        user.amount += _amount;
        totalSupply += _amount;


        ISmartChefInitializable(staker).deposit(_amount);

        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount - _amount >= 0, "Withdraw: Amount to withdraw too high");
        require(_amount > 0, "Withdraw: Amount to withdraw cannot be zero");

        harvest();

        uint256 adjustedAmount = (_amount * getTotalSupply()) / totalSupply; 
        totalSupply -= _amount;
        user.amount -= _amount;
        ISmartChefInitializable(staker).withdraw(adjustedAmount);
        IERC20Metadata(stakedToken).safeTransfer(address(msg.sender), adjustedAmount);

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Withdraw all staked tokens without carrying about rewards or recompounding
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "Withdraw: Nothing to withdraw");

        uint256 adjustedAmount = (user.amount * getTotalSupply()) / totalSupply; 
        totalSupply -= user.amount;
        user.amount = 0;
        ISmartChefInitializable(staker).withdraw(adjustedAmount);
        IERC20Metadata(stakedToken).safeTransfer(address(msg.sender), adjustedAmount);

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /*
     * @notice Returns the adjusted share price
    */
    function adjustedTokenPerShare() public view returns (uint256 _amount) {
        if (getTotalSupply() == 0) {return 0;}
        return ((10 ** 18) * getTotalSupply()) / totalSupply;
    }
    
    /*
     * @notice Returns the total supply of the staked token in this contract and the underlying staker
    */
    function getTotalSupply() public view returns (uint256 _amount) {
        (uint256 supply, ) = ISmartChefInitializable(staker).userInfo(address(this));
        supply += IERC20Metadata(stakedToken).balanceOf(address(this));
        return supply;
    }

    /*
     * @notce Recover a token that was accidentally sent to this contract
     * @param _token: The token that needs to be retrieved
     * @param _amount: The amount of tokens to be recovered
    */
    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(0), "Operations: Cannot be zero address");
        require(_token != address(stakedToken), "Operations: Cannot be staked token");
        require(_token != address(rewardToken), "Operations: Cannot be reward token");
        IERC20(_token).transfer(treasury, _amount);
        emit TokenRecovery(_token, _amount);
    }

    /*
     * @notce Update the minimum amount of tokens required for swapping the harvested (reward) tokens
     * @param _amount: The new minimum amount
    */
    function setMinimumHarvest(uint256 _amount) external onlyOwner {
        minimumHarvest = _amount;
        emit NewMinimumHarvest(_amount);
    }

    /*
     * @notce update the treasury's address
     * @param _treasury: New address that should receive treasury fees
    */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Operations: Address cannot be null");
        treasury = _treasury;
        emit TreasuryAddressChanged(_treasury);
    }

    /*
     * @notce Update the deposit fee
     * @param _amount: New amount for the deposit fee
    */
    function setDepositFee(uint256 _amount) external onlyOwner {
        require(_amount <= 250, "Operations: Invalid deposit fee amount");
        depositFee = _amount;
        emit NewDepositFee(_amount);
    }

    /*
     * @notce Update the performance fee
     * @param _amount: New amount for the performance fee
    */
    function setPerformanceFee(uint256 _amount) external onlyOwner {
        require(_amount <= 500, "Operations: Invalid performance fee amount");
        performanceFee = _amount;
        emit NewPerformanceFee(_amount);
    }
}