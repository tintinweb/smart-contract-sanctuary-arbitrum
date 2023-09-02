/**
 *Submitted for verification at Arbiscan.io on 2023-09-01
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// File: StakingTT.sol


pragma solidity ^0.8.0;



struct NetWork {
    uint256 id;
    uint level;
    uint time;
    address sender_;
    address super_;
}

interface Invitation {

    function getAutoIds() external view returns (uint256);

    function getInfoForId(uint256 _id) external view returns (NetWork memory);

    function getInfo(address _sender) external view returns (NetWork memory);

    function getSuper(address _sender) external view returns (address);

    function getChildrenLength(address _sender) external view returns (uint256);

    function getChildrenInfos(address _sender, uint256 start, uint256 count) external view returns (NetWork[] memory);

    function getChildrenAddresss(address _sender, uint256 start, uint256 count) external view returns (address[] memory);

    function post(address _sender, address _super) external;
}

interface TdexToken  {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
 
    function burn(uint256 amount) external;
}

interface DEX {

    function getPrice(address _tokenContract) external view returns (uint256);
}

struct AnnualInterestRateConfig {
    uint index;
    uint256 rQuantity;
    uint256 annualInterestRate;
}

struct DPosMove {
    address root;
    uint256 dpos;
}

struct AccountInfo {
    address account;
    uint256 dpos;
    uint time;
}

library Math {

    function MAX(uint256 x, uint256 y) internal pure returns (uint256)
    {
        return (x >= y ? x : y);
    }

    function MIN(uint256 x, uint256 y) internal pure returns (uint256)
    {
        return (x <= y ? x : y);
    }
}

contract StakingPool is Ownable {

    function balance(TdexToken ttToken) external view returns (uint256) {
        return ttToken.balanceOf(address(this));
    }

    function withdraw(TdexToken ttToken, address to, uint256 amount) external onlyOwner {
        ttToken.transfer(to, amount);
    }
}

contract StakingTT is Ownable, Initializable {
    address private ttPool;
    address private ttTokenAddress;
    TdexToken private ttToken;
    Invitation private invitation;
    DEX private dex;
    uint256 private totalPos;
    uint256 private totalFPos;
    uint256 private totalDPos;
    mapping(address => uint256) private poss;
    mapping(address => uint256) private fposs;
    mapping(address => uint256) private dposs;
    mapping(address => uint256) private dpossFrozen;
    mapping(address => uint256) private dpossGain;
    mapping(address => uint256) private interests;
    mapping(address => uint256) private lastUpdateTime;
    mapping(uint => AnnualInterestRateConfig) private annualInterestRateConfig;
    uint[] private poolLevelUpdateTimes;
    uint256 private nextRQuantity;
    uint256 private annualEarnings;
    mapping(address => DPosMove) private dposMoves;
    mapping(address => address) private stakingPools;

    event Deposit(address indexed account, uint256 amount, uint256 pos);
    event Redeposit(address indexed account, uint256 amount, uint256 pos);
    event Withdrawal(address indexed account, uint256 amount, uint256 pos);
    event InterestClaimed(address indexed account, uint interest);
    event UpdatedDPosMove(address indexed account, address root, uint256 dpos);

    function initialize() public initializer() {
        _transferOwnership(_msgSender());
    }

    function setPool(address _ttPool) external onlyOwner
    {
        ttPool = _ttPool;
    }

    function init(address _ttTokenAddress) external onlyOwner {
        require(ttTokenAddress == address(0), "");
        ttTokenAddress = _ttTokenAddress;
        ttToken = TdexToken(ttTokenAddress);
    }

    function setInvitation(address _invitation) external onlyOwner {
        invitation = Invitation(_invitation);
    }

    function setDex(address _dex) external onlyOwner {
        dex = DEX(_dex);
    }

    function verifyAddress(address account) external view returns (bool)
    {
        return bool(invitation.getInfo(account).id > 0);
    }

    function getBgtAddress() external view returns (address)
    {
        return ttTokenAddress;
    }

    function getSuper(address account) external view returns (address) {
        return invitation.getSuper(account);
    }

    function postSuperAddress(address super_) external {
        invitation.post(msg.sender, super_);
    }

    function getDPosDquity() internal view returns (uint256) {
        return 1000 * (10 ** ttToken.decimals());
    }

    function setAnnualEarnings(uint256 _annualEarnings) public onlyOwner {

        annualEarnings = _annualEarnings * 10 ** ttToken.decimals();

        if (poolLevelUpdateTimes.length == 0)
        {
            poolLevelUpdateTimes.push(0);
        }
        else 
        {
            poolLevelUpdateTimes.push(block.timestamp);
        }
        nextRQuantity = _setConfig(poolLevelUpdateTimes.length - 1, 0);
    }

    function getUserInfo(address account) public view returns (uint256 pos, uint256 fpos, uint256 dpos, uint256 totalPos_, uint256 totalFPos_, uint256 totalDPos_)
    {
        return (poss[account], fposs[account], _getDPoss(account), totalPos, totalFPos, totalDPos);
    }

    function createPool(address account) internal {
        if (account != address(0) && stakingPools[account] == address(0))
        {
            StakingPool pool = new StakingPool();
            stakingPools[account] = address(pool);
            if (poss[account] > 0) 
                ttToken.transfer(stakingPools[account], poss[account]);
        }
    }

    function addPoss(address account, uint256 amount) internal {
        poss[account] += amount;
        totalPos += amount;
        ttToken.transferFrom(account, stakingPools[account], amount);

        uint256 dposDquity = getDPosDquity();
        if (poss[account] < dposDquity)
        {
            dpossGain[account] = 0;
        }
        else 
        {
            dpossGain[account] = (poss[account] - dposDquity) / 190 + 100;
        }
    }

    function depositTT(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        address account = msg.sender;
        require(ttToken.allowance(account, address(this)) >= amount, "Insufficient allowance");
        settlementInterest(account);
        
        require(invitation.getSuper(account) != address(0), "No bond, no pledge");

        createPool(account);
        
        uint256 dposDquity = getDPosDquity();
        recycleDPos(account);
        // Update the pos
        addPoss(account, amount);

        addDPosMoves(account, amount, dposDquity);
        updateSuperDPos(account, dposDquity);
        updateDPos(account, dposDquity);

        upgrades();

        emit Deposit(msg.sender, amount, poss[account]);
    }

    function decPoss(address account, uint256 amount) internal {
        poss[account] -= amount;
        totalPos -= amount;
        StakingPool(stakingPools[account]).withdraw(ttToken, account, amount);
        if (fposs[account] > 0)
        {
            uint256 subfposs = Math.MIN(fposs[account], amount);
            fposs[msg.sender] = fposs[account] -  subfposs;
            totalFPos -= subfposs;
        }
    }

    function withdrawTT(uint256 amount) external {
        require(amount <= poss[msg.sender], "Insufficient balance");
        require(amount > 0, "Amount must be greater than zero");
        address account = msg.sender;
        settlementInterest(account);

        createPool(account);

        uint256 dposDquity = getDPosDquity();
        recycleDPos(account);
        decPoss(account, amount);
        
        decDPosMoves(account, amount, dposDquity);
        updateSuperDPos(account, dposDquity);
        updateDPos(account, dposDquity);
        
        emit Withdrawal(account, amount, poss[msg.sender]);
    }
 
    function isDoUpdateDPosToSuper(address account) external view returns (bool) {
        if (dposMoves[account].dpos == 0)
            return false;
        if (invitation.getSuper(account) == address(0))
            return false;
        uint256 dposDquity = getDPosDquity();
        address root = getSuperRoot(account, dposDquity);
        return isUppdatedDpos(account, dposDquity) || (root != dposMoves[account].root);
    }

    function doUpdateDPosToSuper() external {
        require(poss[msg.sender] > 0, "Task need pos > 0");
        address account = msg.sender;
        _doUpdateDPosToSuper(account);
        fposs[account] += 1e18;
        totalFPos += 1e18;
        createPool(account);
    }

    function doOtherUpdateDPosToSuper(address account) external {
        require(poss[msg.sender] > 0, "Task need pos > 0");
        // require(msg.sender == invitation.getSuper(account), "No permission");
        _doUpdateDPosToSuper(account);
        fposs[msg.sender] += 1e18;
        totalFPos += 1e18;
        createPool(account);
    }

    function _doUpdateDPosToSuper(address account) internal {
        settlementInterest(account);
        uint256 dposDquity = getDPosDquity();
        address root = getSuperRoot(account, dposDquity);
        bool isUpdated = updateDPos(account, dposDquity) || (root != dposMoves[account].root);
        require(isUpdated, "There are no tasks to do");
        recycleDPos(account);
        updateDPosMovesRoot(account, dposDquity);
        updateSuperDPos(account, dposDquity);
    }

    function claimInterestTT() external {
        address account = msg.sender;
        settlementInterest(account);

        createPool(account);

        uint256 interest = interests[account];
        require(interest > 0, "No interest available");

        interests[account] = 0;
        // Transfer the interest to the user
        ttToken.transfer(account, interest);

        emit InterestClaimed(account, interest);
    }

    function upgrades() internal {
        
        if (totalPos + totalFPos >= nextRQuantity)
        {
            poolLevelUpdateTimes.push(block.timestamp);
            nextRQuantity = _setConfig(poolLevelUpdateTimes.length - 1, nextRQuantity);
        }
    }

    // 变更前，先收回
    function recycleDPos(address account) internal {
        address root = dposMoves[account].root;
        settlementInterest(root);
        uint256 dpos = dposMoves[account].dpos;
        if (root != address(0) && dpos > 0)
        {
            if (dposs[root] > 0)
            {
                dposs[root] -= dpos;
                totalDPos -= dpos;
            }
            else 
            {
                dpossFrozen[root] -= dpos;
            }
        }
    }

    function updateDPosMovesRoot(address account, uint256 dposDquity) internal {
        address root = getSuperRoot(account, dposDquity);
        if (dposMoves[account].dpos > 0)
        {
            dposMoves[account].root = root;
            emit UpdatedDPosMove(account, dposMoves[account].root, dposMoves[account].dpos);
        }
    }

    // 变更后，更新DPOS信息
    function addDPosMoves(address account, uint256 amount, uint256 dposDquity) internal {
        address superFrom = invitation.getSuper(account);
        if (superFrom != address(0))
        {
            address root = getSuperRoot(account, dposDquity);
            if (dposMoves[account].dpos > 0)
            {
                dposMoves[account].root = root;
                dposMoves[account].dpos += amount;
            }
            else
            {
                dposMoves[account] = DPosMove(root, amount);
            }
            emit UpdatedDPosMove(account, dposMoves[account].root, dposMoves[account].dpos);
        }
    }

    // 变更后，更新DPOS信息
    function decDPosMoves(address account, uint256 amount, uint256 dposDquity) internal {
        address superFrom = invitation.getSuper(account);
        if (superFrom != address(0))
        {
            address root = getSuperRoot(account, dposDquity);
            if (dposMoves[account].dpos > amount)
            {
                dposMoves[account].root = root;
                dposMoves[account].dpos -= amount;
            }
            else 
            {
                delete dposMoves[account];
            }
            emit UpdatedDPosMove(account, dposMoves[account].root, dposMoves[account].dpos);
        }
    }

    // 根据DPOS信息，添加DPOS
    function updateSuperDPos(address account, uint256 dposDquity) internal {
        address root = dposMoves[account].root;
        settlementInterest(root);
        uint256 dpos = dposMoves[account].dpos;
        if (root != address(0) && dpos > 0)
        {
            if (poss[root] >= dposDquity || poss[account] >= dposDquity)
            {
                dposs[root] += dpos;
                totalDPos += dpos;
            }
            else 
            {
                dpossFrozen[root] += dpos;
            }
        }
    }

    function isUppdatedDpos(address account, uint256 dposDquity) internal view returns (bool) {
        bool result = false;
        if (poss[account] >= dposDquity && dpossFrozen[account] > 0)
        {
            result = true;
        }
        else if (poss[account] < dposDquity && dposs[account] > 0)
        {
            result = true;
        }
        return result;
    }

    function updateDPos(address account, uint256 dposDquity) internal returns (bool) {
        bool result = false;
        if (poss[account] >= dposDquity && dpossFrozen[account] > 0)
        {
            totalDPos += dpossFrozen[account];
            dposs[account] += dpossFrozen[account]; 
            dpossFrozen[account] = 0;
            result = true;
        }
        else if (poss[account] < dposDquity && dposs[account] > 0)
        {
            totalDPos -= dposs[account];
            dpossFrozen[account] += dposs[account]; 
            dposs[account] = 0;
            result = true;
        }
        return result;
    }

    function getSuperRoot(address account, uint256 dposDquity) public view returns (address) {
        
        address super_ = invitation.getSuper(account);
        address result;
        if (poss[account] < dposDquity)
        {
            if (poss[super_] < dposDquity)
            {
                result = address(0);
            }
            else 
            {
                result = super_;
            }
        }
        else
        {
            result = super_;
            uint index = 0;
            while (true)
            {
                if (result == address(0))
                    break ;
                if (poss[result] >= dposDquity)
                    break;
                index += 1;
                result = invitation.getSuper(result);
                if (index >= 50)
                {
                    result = address(0);
                }
            }
        }
        return result;
    }

    function doSettlementInterest() external {
        address account = msg.sender;
        require(poss[account] > 0, "There are no tasks to do");

        uint256 total = poss[account] + _getDPoss(account) + fposs[account];

        uint currentTime = block.timestamp;
        uint lastUpdate = lastUpdateTime[account];

        uint userIndex = getIndex(account);
        
        uint length = poolLevelUpdateTimes.length > 30 ? 30 : poolLevelUpdateTimes.length;
        uint interest = 0;
        for (uint i=userIndex; i<length; i++)
        {
            uint endTime = (i == poolLevelUpdateTimes.length - 1) ? currentTime : poolLevelUpdateTimes[i+1];
            uint elapsedTime = endTime - Math.MAX(lastUpdate, poolLevelUpdateTimes[i]);
            interest += annualInterestRateConfig[i].annualInterestRate * elapsedTime * total / (365 days) / 100;
        }

        if (interest > 0)
        {
            // Update the last update time
            interests[account] += interest;
            ttToken.transferFrom(ttPool, address(this), interest);
        }
        lastUpdateTime[account] = block.timestamp;
    }

    function getInterest(address account) public view returns (uint256) {
        uint256 interest = calculateInterest(account);
        interest += interests[account];
        return interest;
    }

    function settlementInterest(address account) internal {
        uint256 interest = calculateInterest(account);
        if (interest > 0)
        {
            // Update the last update time
            interests[account] += interest;
            ttToken.transferFrom(ttPool, address(this), interest);
        }
        lastUpdateTime[account] = block.timestamp;
    }

    function calculateInterest(address account) internal view returns (uint256) {
        if (poss[account] == 0)
            return 0;

        uint256 total = poss[account] + _getDPoss(account) + fposs[account];

        uint userIndex = getIndex(account);
        
        uint interest = 0;
        for (uint i=userIndex; i<poolLevelUpdateTimes.length; i++)
        {
            uint endTime = (i == poolLevelUpdateTimes.length - 1) ? block.timestamp : poolLevelUpdateTimes[i+1];
            uint elapsedTime = endTime - Math.MAX(lastUpdateTime[account], poolLevelUpdateTimes[i]);
            interest += annualInterestRateConfig[i].annualInterestRate * elapsedTime * total / (365 days) / 100;
        }
        return interest;
    }

    function getIndex(address account) public view returns (uint) {
        uint index = poolLevelUpdateTimes.length - 1;
        uint i = poolLevelUpdateTimes.length;
        while (true)
        {
            i--;
            if (lastUpdateTime[account] >= poolLevelUpdateTimes[i] || i == 0)
            {
                index = i;
                break; 
            }
        }
        return index;
    }

    function getPoolLevelUpdateTimesLength() public view returns (uint)
    {
        return poolLevelUpdateTimes.length;
    }

    function getPoolLevelUpdateTimesAtIndex(uint index) public view returns (uint256)
    {
        return poolLevelUpdateTimes[index];
    }

    function getAnnualInterestRateConfigAtIndex(uint index) public view returns (AnnualInterestRateConfig memory)
    {
        return annualInterestRateConfig[index];
    }

    function getNextRQuantity() public view returns (uint256)
    {
        return nextRQuantity;
    }

    function getDposMoves(address account) public view returns (DPosMove memory)
    {
        return dposMoves[account];
    }

    function getChildrenInfos(address _sender, uint256 start, uint256 count) external view returns (AccountInfo[] memory)
    {
        NetWork[] memory networkList = invitation.getChildrenInfos(_sender, start, count);
        AccountInfo[] memory list = new AccountInfo[](networkList.length);
        for (uint i=0; i< networkList.length; i++)
        {
            address account = networkList[i].sender_;
            list[i] = AccountInfo(account, poss[account], networkList[i].time);
        }
        return list;
    }

    function _setConfig(uint256 _index, uint256 _rQuantity) internal returns (uint256) {
        uint256 _nextRQuantity = _rQuantity == 0 ? 18000000 * 10 ** ttToken.decimals() : (_rQuantity * (5263157 + 100000000) / 100000000);
        uint256 _annualInterestRate = 100 * annualEarnings * 7 / 30 / _nextRQuantity;
        annualInterestRateConfig[_index] = AnnualInterestRateConfig(_index, _rQuantity, _annualInterestRate);
        return _nextRQuantity;
    }

    function _getDPoss(address account) internal view returns (uint256)
    {
        return (dposs[account] * dpossGain[account] / 100);
    }

    function getDPoss(address account) external view returns (uint256)
    {
        return _getDPoss(account);
    }

    function getDpossFrozen(address account) external view returns (uint256)
    {
        return dpossFrozen[account];
    }

    function getStakingPool(address account) external view returns (address)
    {
        return stakingPools[account];
    }

    function getVersion() public pure returns (string memory)
    {
        return "v1.0";
    }
}