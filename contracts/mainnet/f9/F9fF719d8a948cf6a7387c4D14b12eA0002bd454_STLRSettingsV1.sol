/**
 *Submitted for verification at Arbiscan on 2023-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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
}

// 
// Inheritance
// https://docs.synthetix.io/contracts/Pausable
abstract contract Pausable is Ownable {
    uint256 public lastPauseTime;
    bool public paused;

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner() != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(
            !paused,
            "This action cannot be performed while the contract is paused"
        );
        _;
    }
}

// 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
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

// 
interface ISTLRHelperV1 {
    function pair() external view returns (address);
    function router() external view returns (address);
}

// 
contract STLRSettingsV1 is Pausable {
    
    /** GLOBAL PARAMETERS */

    address public STLR;
    address public USDC;
    address public dao;
    address public treasury;
    address public manager;
    address public helper;
    address public presale;
    address public oracle;
    uint public claimFee = 500; // 5.0 % claim fee

    /** TOKEN PARAMETERS */

    uint public transferLimit;
    uint public walletMax;
    bool public feeOnTransfer = true;
    uint public constant SELL_FEE = 750; // 7.5 % sell fee

    /** DAO PARAMETERS */

    uint public interestRate = 10000;
    uint public claimCooldown = 6 hours;
    uint public rewardFeePercentage = 500; // 5 %
    uint public maxRewardFee = 0.1 ether;
    uint public rotDeduction = 2500; // 25 %
    uint public maxRotCount = 3; // max. 75 % deduction

    uint public constant MAX_SETTLEMENTS = 100;
    uint public constant REWARD_FREQUENCY = 1 minutes; // less than or equal to 1 day
    uint public constant BASE_DENOMINATOR = 10000;

    /** FARMING PARAMETERS */

    uint public farmingWithdrawDelay = 1 weeks; // 1 week after deposit
    uint public farmingClaimCooldown = 1 days; // claim cooldown

    uint public constant LOCKED_PERCENT = 15;

    /** PRIVATE VARIABLES */

    mapping(address => bool) private _operators;
    mapping(address => bool) private _exemptFromFees;
    mapping(address => bool) private _marketPairs;

    constructor(
        address _stlr,
        address _usdc,
        address _treasury
    ) {
        STLR = _stlr;
        USDC = _usdc;
        treasury = _treasury;

        setExemptFromFee(owner(), true);
        setExemptFromFee(treasury, true);
        transferLimit = IERC20(STLR).totalSupply() * 5 / 1000; // 0.5% of total supply
        walletMax = IERC20(STLR).totalSupply() * 15 / 1000; // 1.5% of total supply
    }

    /** VIEW FUNCTIONS */

    function isOperator(
        address operator
    ) 
        external 
        view 
        returns (bool)
    {
        return _operators[operator];
    }

    function isExemptFromFee(
        address account
    )
        external
        view
        returns (bool)
    {
        return _exemptFromFees[account];
    }

    function isMarketPair(
        address pair
    )
        external
        view
        returns (bool)
    {
        return _marketPairs[pair];
    }

    /** RESTRICTED FUNCTIONS */

    function setDao(
        address _dao
    )
        external
        onlyOwner
    {
        require(_dao != address(0), 'Dao can not be null address');
        dao = _dao;
        setExemptFromFee(dao, true);
        emit DaoUpdated(dao);
    }

    function setTreasury(
        address _treasury
    ) 
        external 
        onlyOwner 
    {
        require(_treasury != address(0), 'Treasury can not be null address');
        treasury = _treasury;
        setExemptFromFee(treasury, true);
        emit TreasuryUpdated(treasury);
    }

    function setManager(
        address _manager
    )
        external
        onlyOwner
    {
        require(_manager != address(0), 'Manager can not be null address');
        manager = _manager;
        setExemptFromFee(manager, true);
        emit ManagerUpdated(manager);
    }

    function setHelper(
        address _helper
    )
        external
        onlyOwner
    {
        require(_helper != address(0), 'Helper can not be null address');
        helper = _helper;
        setExemptFromFee(helper, true);
        setMarketPair(ISTLRHelperV1(helper).pair(), true);
        emit HelperUpdated(helper);
    }

    function setPresale(
        address _presale
    )
        external
        onlyOwner
    {
        require(_presale != address(0), 'Presale can not be null address');
        presale = _presale;
        setOperator(presale, true);
        emit PresaleUpdated(presale);
    }

    function setOracle(
        address _oracle
    )
        external
        onlyOwner
    {
        require(_oracle != address(0), 'Oracle can not be null address');
        oracle = _oracle;
        emit OracleUpdated(oracle);
    }

    function setInterestRate(
        uint _rate
    ) 
        external 
        onlyOwner
    {
        require(_rate != uint(0), 'Interest rate can not be null');
        interestRate = _rate;
        emit InterestRateUpdated(interestRate);
    }

    function setClaimFee(
        uint _fee
    )
        external 
        onlyOwner 
    {
        require(_fee <= 1000, 'Claim fee not within bounds');
        claimFee = _fee;
        emit ClaimFeeUpdated(claimFee);
    }

    function setClaimCooldown(
        uint _cooldown
    ) 
        external 
        onlyOwner 
    {
        require(_cooldown <= 24 hours, 'Cooldown not within bounds');
        claimCooldown = _cooldown;
        emit ClaimCooldownUpdated(claimCooldown);
    }

    function setRewardFeeParameters(
        uint _rewardFeePercentage,
        uint _maxRewardFee
    ) 
        external 
        onlyOwner 
    {
        require(_rewardFeePercentage <= 2000, 'Reward fee percentage not within bounds'); // 20%
        require(_maxRewardFee <= 0.5 ether, 'Max reward fee not within bounds');
        rewardFeePercentage = _rewardFeePercentage;
        maxRewardFee = _maxRewardFee;
        emit RewardFeeParametersUpdated(rewardFeePercentage, maxRewardFee);
    }

    function setRotParameters(
        uint _rotDeduction, 
        uint _maxRotCount
    ) 
        external 
        onlyOwner 
    {
        rotDeduction = _rotDeduction;
        maxRotCount = _maxRotCount;
        emit RotParametersUpdated(rotDeduction, maxRotCount);
    }

    function setFarmingParameters(
        uint _withdrawDelay,
        uint _claimCooldown
    )
        external
        onlyOwner
    {
        require(_withdrawDelay <= 30 days, 'Withdraw delay not within bounds');
        require(_claimCooldown <= 24 hours, 'Cooldown not within bounds');
        farmingWithdrawDelay = _withdrawDelay;
        farmingClaimCooldown = _claimCooldown;
        emit FarmingParametersUpdated(farmingWithdrawDelay, farmingClaimCooldown);
    }

    function setOperator(
        address operator, 
        bool status
    ) 
        public 
        onlyOwner 
    {
        _operators[operator] = status;
        if (status) {
            setExemptFromFee(operator, true);
        } else {
            setExemptFromFee(operator, false);
        }
        emit OperatorUpdated(operator, status);
    }

    /** TOKEN FUNCTIONS */

    function setTransferLimit(
        uint _prcnt
    ) 
        external 
        onlyOwner 
    {
        require(_prcnt > 0, 'Transfer limit can not be zero');
        transferLimit = IERC20(STLR).totalSupply() * _prcnt / 1000;
        emit TransferLimitUpdated(transferLimit);
    }

    function setWalletLimit(
        uint _prcnt
    ) 
        external 
        onlyOwner 
    {
        walletMax = IERC20(STLR).totalSupply() * _prcnt / 1000;
        emit WalletLimitUpdated(walletMax);
    }

    function setExemptFromFee(
        address account, 
        bool status
    ) 
        public 
        onlyOwner 
    {
        _exemptFromFees[account] = status;
        emit ExemptFromFeeUpdated(account, status);
    }

    function setMarketPair(
        address pair, 
        bool status
    ) 
        public 
        onlyOwner 
    {
        _marketPairs[pair] = status;
        emit MarketPairUpdated(pair, status);
    }

    function setFeeOnTransfer(
        bool status
    ) 
        external 
        onlyOwner 
    {
        feeOnTransfer = status;
        emit FeeOnTransferUpdated(status);
    }

    /** RECOVERY FUNCTIONS */

    function recover(
        address token
    )
        external
        onlyOwner
    {
        uint balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(treasury, balance);
        emit Recovered(token, balance);
    }

    function recover(
    ) 
        external 
        onlyOwner 
    {
        uint balance = address(this).balance;
        Address.sendValue(payable(treasury), balance);
        emit Recovered(balance);
    }

    /** EVENTS */

    event DaoUpdated(address dao);
    event TreasuryUpdated(address treasury);
    event ManagerUpdated(address manager);
    event HelperUpdated(address helper);
    event PresaleUpdated(address presale);
    event OracleUpdated(address oracle);
    event InterestRateUpdated(uint rate);
    event ClaimFeeUpdated(uint fee);
    event ClaimCooldownUpdated(uint cooldown);
    event RewardFeeParametersUpdated(uint rewardFeePercentage, uint maxRewardFee);
    event RotParametersUpdated(uint deduction, uint maxCount);
    event FarmingParametersUpdated(uint delay, uint cooldown);
    event OperatorUpdated(address operator, bool status);
    event TransferLimitUpdated(uint limit);
    event WalletLimitUpdated(uint limit);
    event ExemptFromFeeUpdated(address account, bool status);
    event MarketPairUpdated(address pair, bool status);
    event FeeOnTransferUpdated(bool status);
    event Recovered(address token, uint amount);
    event Recovered(uint amount);
}