/**
 *Submitted for verification at Arbiscan on 2023-06-12
*/

//SPDX-License-Identifier: MIT
// File: IPancakeRouter.sol


pragma solidity >=0.6.2;

interface IPancakeRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}
// File: IPancakeFactory.sol


pragma solidity >=0.5.0;

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
// File: IPancakePair.sol


pragma solidity >=0.5.0;

interface IPancakePair {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
// File: Structs.sol


pragma solidity ^0.8.0;

struct DataParam{
    address tokenAddress;
    uint256 presaleStartTime;
    uint256 hardCap;
    uint256 rate;
    bool Vesting;
    bool usetoken;
    uint256 usdtToBNBValue;
    bool whitelist;
    uint256 maximumSpend;
    uint256 minimumSpend;
    bool lock;
    uint256 exchangeListingRate;
    uint256 locktime;
    uint256 liquidityAmount;
}

struct vestingStruct{
    uint256 firstPercent;
    uint256 firstReleaseTime;
    uint256 cyclePercent;
    uint256 cycleReleaseTime;
    uint256 cycleCount;
}

struct NewToken{
    string name;
    string symbols;
    uint8 decimals;
    uint256 supply;
}
// File: IstakingPoolVerify.sol


pragma solidity ^0.8.0;

interface PoolsRankVerify{
    
    function getStakeAmount(address staker) external view returns(uint);
    function getStakeActive(address staker) external view returns(bool);
    function getRemainingDuration(address staker) external view returns(uint);
    function getRank(address staker) external view returns(uint);
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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


// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// File: IDO.sol


pragma solidity ^0.8.0;








interface ILaunch{
    function getAuthorized(address sender) external view returns(bool);
    function getlock() external view returns(address);
    function getBuyToken() external view returns(address);
    function getStaking() external view returns(bool);

}

interface ILock{
    function launchLock(address owner,  address token_, address beneficiary_, uint256 releaseTime_, uint256 amount_, bool _liquidity) external;
    function launchBNbLock( address owner,  address beneficiary_,uint256 releaseTime_, uint256 amount_) external;
}



contract IDO is Initializable{

    address public owner;
    address public factory;
    IERC20Upgradeable token;
    IERC20Upgradeable buyToken;
    uint ID;
    DataParam saleData;
    uint presaleSupply;
    uint totalTkensSold;
    uint startDate;
    uint totalRaised;
    uint public whitelistCount;
    
    bool whitelist;
    bool finalised;
    bool presaleCancelled;

    PoolsRankVerify pool;

    mapping(address => uint) arrayIndexForAddress;
    mapping(address => uint) maxallocation;
    mapping(address => bool) whitelisted;
    mapping(address => uint) tokenBalance;
    mapping(address => uint) spentAllocation;
    mapping(address => bool) public claimedRefund;
    mapping(address => bool) firstBuy;    
    
    address[] public whitelistedAddresses;
    address[] public buyerAddresses;

    //Liquidity
    address pancakeRouterAddress;
    IPancakeRouter02 pancakeSwapRouter;
    address public pancakeSwapPair;


    
     //Vesting
    
    struct VestingPeriod{
        uint percent;
        uint startTime;
        uint vestingCount;
       uint MaxClaim;   
    }
    
    uint maxPercent;
    bool Vesting;
    uint VestingCount;

    VestingPeriod _vestingPeriod;
    vestingStruct vesting;

    mapping(uint => VestingPeriod) PeriodtoPercent;
    mapping(address => uint) TotalBalance;
    mapping(address => uint) claimCount;
    mapping(address => uint) claimedAmount;
    mapping(address => uint) claimmable;
    
    



    function initialize(address _owner, uint id, DataParam memory data, uint _presalesupply, address staking, vestingStruct calldata _vesting) external initializer{
        owner = _owner;
        ID = id;
        saleData = data;
        pool = PoolsRankVerify(staking);
        token = IERC20Upgradeable(data.tokenAddress);
        Vesting = data.Vesting;
        presaleSupply = _presalesupply;
        vesting = _vesting;
        whitelist = data.whitelist;
        startDate = data.presaleStartTime;
        factory = msg.sender;
        buyToken = IERC20Upgradeable(ILaunch(factory).getBuyToken()); 
        
    }


    function setWhitelist(bool newStatus) external{
        require(ILaunch(factory).getAuthorized(msg.sender),"UN");//unauthorised

        whitelist = newStatus;
    }


    
    function requestWhitelist() external{
        require(ILaunch(factory).getStaking(), "!SNA");//Staking Not Active
        require(whitelist, "PPB");//Presale Public
        require(!finalised, "F");//Finalised
        require(!whitelisted[msg.sender], "WA");//Whitelisted Already
        
        uint rank = pool.getRank(msg.sender);
        
        uint _bnbrate = saleData.usdtToBNBValue/ (10 ** IERC20MetadataUpgradeable(address(buyToken)).decimals());
    
        require(rank > 0, "U,SM");//Unqualified, Stake More

        if(rank == 4){
            if(saleData.usetoken){
                maxallocation[msg.sender] += (500 * (10 ** IERC20MetadataUpgradeable(address(buyToken)).decimals()));
            }else{
                maxallocation[msg.sender] += ((500 * 1e18)/ _bnbrate);
            }
            
        }else{
            if(rank == 3){
                if(saleData.usetoken){
                    maxallocation[msg.sender] += (300 * (10 ** IERC20MetadataUpgradeable(address(buyToken)).decimals()));
                }else{
                    maxallocation[msg.sender] += ((300 * 1e18)/ _bnbrate);
                }
                
            }else{
                if(rank == 2){
                    if(saleData.usetoken){
                        maxallocation[msg.sender] += (200 * (10 ** IERC20MetadataUpgradeable(address(buyToken)).decimals()));
                    }else{
                        maxallocation[msg.sender] += ((200 * 1e18)/ _bnbrate);
                    }
                    
                }else{
                    if(rank == 1){
                        if(saleData.usetoken){
                            maxallocation[msg.sender] += (100* (10 ** IERC20MetadataUpgradeable(address(buyToken)).decimals()));
                        }else{
                            maxallocation[msg.sender] += ((100 * 1e18)/ _bnbrate);
                        }
                        
                    }
                }
            }
        }

            whitelistedAddresses.push(msg.sender);
            arrayIndexForAddress[msg.sender] = whitelistedAddresses.length;
            whitelisted[msg.sender] = true;   
            whitelistCount++;
    }

    function addToWhitelist(address[] calldata whitelists) external{
        require(ILaunch(factory).getAuthorized(msg.sender),"UN");//unauthorise
        require(whitelist, "PPB");//Presale Public


        for(uint i = 1; i <= whitelists.length; i++){
            if(!whitelisted[whitelists[i-1]]){
                
                whitelistedAddresses.push(whitelists[i-1]);
                arrayIndexForAddress[whitelists[i-1]] = whitelistedAddresses.length;
                whitelisted[whitelists[i-1]] = true;   
                whitelistCount++;
                maxallocation[whitelists[i-1]] = saleData.maximumSpend;

            }else{
                continue;
            }
        }
    }

    function removeFromWhitelist(address[] calldata user) external{
        require(ILaunch(factory).getAuthorized(msg.sender),"UN");//unauthorised
        require(whitelist, "PPB");//Presale Public


        for(uint i = 1; i <= user.length; i++){
            whitelisted[user[i-1]] = false;  
            maxallocation[user[i-1]] = 0;
            internalRefund(user[ i - 1]);
            whitelistCount --;
        }
    }

    function internalRefund(address user) internal{
        if(spentAllocation[user] > 0){
            
            uint debit = spentAllocation[user];
            
            totalRaised -= spentAllocation[user];
            totalTkensSold -= tokenBalance[user];
            
            delete spentAllocation[user];
            delete tokenBalance[user];
                
                if(saleData.usetoken){
                    buyToken.transfer(user, debit);
                }else{
                    payable(user).transfer(debit);
                }
        }
    }


    function adminCancelPresale() external{
        require(ILaunch(factory).getAuthorized(msg.sender),"UN");//unauthorised
        require(!finalised, "PF");
        require(!presaleCancelled, "C");
        
        presaleCancelled = true;
        delete totalTkensSold;
        
        remaningTokens();
    }


    function finalisePresale() external{
        require(ILaunch(factory).getAuthorized(msg.sender),"UN");//unauthorised
        require(startDate < block.timestamp, "NS ");//Not STarted
        require(!finalised, "F");//Finalised
        require(!presaleCancelled, "PF");

        if(totalRaised == 0){

            remaningTokens();

        }else{
            
            if(saleData.lock){

                uint percentageToUse = saleData.liquidityAmount * totalRaised / 10000;
                

                if(saleData.usetoken){

                        uint _tokenamt = (saleData.exchangeListingRate * percentageToUse) / (10**IERC20MetadataUpgradeable(address(buyToken)).decimals());
                
                        distribute(percentageToUse , _tokenamt);
                    
                        buyToken.transfer(owner, buyToken.balanceOf(address(this)));

                }else{
                    
                    
                    uint _tokenamt = (saleData.exchangeListingRate * percentageToUse)  / 1e18;

                    addLiquidity(percentageToUse, _tokenamt);

                    payable(owner).transfer(address(this).balance);

                }

            }else{

                if(saleData.usetoken){

                    uint debit = totalRaised / 2;

                    buyToken.transfer(owner, debit);

                   _lockLPTokens(address(buyToken), debit, 7 days, false);

                }else{
                    
                    uint debit = totalRaised;

                    payable(owner).transfer(debit);

                    // lockBNB(7 days, debit);

                }
            
            }

            if(saleData.lock){
                uint256 tokenAmount = IERC20Upgradeable(pancakeSwapPair).balanceOf(address(this));

                _lockLPTokens(pancakeSwapPair, tokenAmount, saleData.locktime, true);
            }

            remaningTokens();
        
        }

        finalised = true;

    }

    function setPair() internal{
        //////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////
        /////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////


        pancakeRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        /////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////


        IPancakeRouter02 _uniswapV2Router = IPancakeRouter02(pancakeRouterAddress);
        pancakeSwapRouter = _uniswapV2Router;
        address p;
        if(saleData.usetoken){
            p = address(buyToken);
        }else{
            p = _uniswapV2Router.WETH();
        }

        pancakeSwapPair = IPancakeFactory(_uniswapV2Router.factory()).getPair(address(token), p);    

     
       if(pancakeSwapPair == address(0)){
                        
            pancakeSwapPair = IPancakeFactory(_uniswapV2Router.factory()).createPair(address(token), p);               
            
        }
         
    }
    
    function _lockLPTokens(address token__,uint256 _amount, uint _time, bool liquidity__) internal{ 
        
        ILock locker = ILock(ILaunch(factory).getlock());
        
        IERC20Upgradeable(token__).approve(address(locker), _amount);

        locker.launchLock(owner, token__, owner , _time + block.timestamp, _amount, liquidity__);
        
    }

    // function lockBNB(uint _time, uint amount_) public {

    //     ILock locker = ILock(0xf56Cf4202AC192dA3967b0ce1BACdd23324FD288);

    //     //ILaunch(factory).getlock()
        
    //     locker.launchBNbLock(msg.sender, msg.sender, (block.timestamp + _time), amount_);

    //     payable(0xf56Cf4202AC192dA3967b0ce1BACdd23324FD288).transfer(amount_);

    // }


    function distribute(uint buyTokenAmount, uint tokenamount)internal{
        setPair();
        
    
        buyToken.approve(address(pancakeSwapRouter), buyTokenAmount);
        token.approve(address(pancakeSwapRouter), tokenamount);
        buyToken.approve(address(pancakeSwapPair), buyTokenAmount);
        token.approve(address(pancakeSwapPair), tokenamount);

        IPancakeRouter02(pancakeSwapRouter).addLiquidity(
            address(buyToken),
            address(token),
            buyTokenAmount,
            tokenamount,
            1,
            1,
            address(this),
            block.timestamp
        );

        
    }

    function AIrdrop() external{
        require(ILaunch(factory).getAuthorized(msg.sender),"UN");//unauthorised
        require(finalised, "NF");//Not Finalised

        for(uint i = 0; i < buyerAddresses.length; i++){
            if(tokenBalance[buyerAddresses[i]] > 0){
                
                token.transfer(buyerAddresses[i], tokenBalance[buyerAddresses[i]]);
                delete tokenBalance[buyerAddresses[i]];
                delete spentAllocation[buyerAddresses[i]];

            }else{
                continue;
            }
        }

    }

    function massRefund() external{
        require(presaleCancelled, "C");
        require(!finalised, "F");//Finalised
        require(ILaunch(factory).getAuthorized(msg.sender),"UN");//unauthorised

             for(uint i = 0; i < buyerAddresses.length; i++){
                
                if(!claimedRefund[buyerAddresses[i]]){
                    totalRaised -= spentAllocation[buyerAddresses[i]];    
                    claimedRefund[buyerAddresses[i]] = true;

                    if(saleData.usetoken){
                        buyToken.transfer(buyerAddresses[i], spentAllocation[buyerAddresses[i]]);
                    }else{
                        payable(buyerAddresses[i]).transfer(spentAllocation[buyerAddresses[i]]);
                    }
                    
                    delete spentAllocation[buyerAddresses[i]];
        
                }else{

                    continue;

                }

            }
        

       

    }


    function addLiquidity(uint bnbAmount, uint tokenAmount) internal{

        setPair();
        
        token.approve(pancakeRouterAddress, tokenAmount);
        token.approve(pancakeSwapPair, tokenAmount);


        // add the liquidity
        pancakeSwapRouter.addLiquidityETH{value: bnbAmount}(
            address(token),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this), // Liquidity Locker or Creator Wallet
            block.timestamp
        );
    }

    function remaningTokens() internal{

        uint debit = token.balanceOf(address(this)) - totalTkensSold;

        token.transfer(owner, debit);
    
      }


    receive() external payable{
        buy(msg.value);
    }
    fallback() external payable{
        buy(msg.value);
    }

    function buy(uint amountInUSD) public{
        require(startDate <= block.timestamp, "NS");//Not Started
        require(!finalised, "F");//Finaliased
        require(!presaleCancelled, "C");//Cancelled
        

        bool cancall;

        if(whitelist){
            if(whitelisted[msg.sender] || spentAllocation[msg.sender] > 0){
                cancall = true;
            }else{
                cancall = false;
            }

            if(!firstBuy[msg.sender]){
                require(amountInUSD >= saleData.minimumSpend, "LTM");//Less than minimum
                firstBuy[msg.sender] = true;
            }

        }else{
            cancall = true;
             if(!firstBuy[msg.sender]){
                
                require(amountInUSD >= saleData.minimumSpend, "LTM");//Less than minimum

                firstBuy[msg.sender] = true;
                maxallocation[msg.sender] = saleData.maximumSpend;
            }
        }

        require(cancall, "NW");//Not Whitelisted
        
   
            require(maxallocation[msg.sender] > 0, "ZA");//Zero Allocation
            require(amountInUSD <= maxallocation[msg.sender], "AGTAM");//Allocation greater than amount
            require(totalRaised + amountInUSD <= saleData.hardCap, "GTC");//Greater than cap
            
            uint amount;
            
            if(saleData.usetoken){
                buyToken.transferFrom(msg.sender, address(this), amountInUSD);
            
                uint __amount = amountInUSD / (10 ** IERC20MetadataUpgradeable(address(buyToken)).decimals());
                
                amount = __amount * saleData.rate;

            } else{ 

                amount = (amountInUSD * saleData.rate) / 1e18;
        
            }
   
            
            spentAllocation[msg.sender] += amountInUSD;
            maxallocation[msg.sender] -= amountInUSD;
            
            tokenBalance[msg.sender] += amount;
            TotalBalance[msg.sender]+= amount;
            totalRaised += amountInUSD;
            totalTkensSold += amount;
            buyerAddresses.push(msg.sender);
            

    }

    function withdraw(uint amountInUSD) external{
        require(!finalised, "AF");
        require(!presaleCancelled, "AC");
        require(tokenBalance[msg.sender] > 0, "ZB");//Zero Balance
        require(amountInUSD <= spentAllocation[msg.sender], "");
 

        if(amountInUSD == spentAllocation[msg.sender]){
            
            cancelContribution();

        }else{
                            
            uint __amount = amountInUSD / (10 ** IERC20MetadataUpgradeable(address(buyToken)).decimals());
           
            uint debitAmount = __amount * saleData.rate;

            tokenBalance[msg.sender] -= debitAmount;
                    
            spentAllocation[msg.sender] -= amountInUSD;
            maxallocation[msg.sender] += amountInUSD;

            totalRaised -= amountInUSD;    

        }

            if(saleData.usetoken){
                buyToken.transfer(msg.sender, amountInUSD);

            }else{
                payable(msg.sender).transfer(amountInUSD);
            }                
         

    }

    function cancelContribution() internal{
        
        uint transferAmount = spentAllocation[msg.sender];
        uint tokenBal = tokenBalance[msg.sender];

        totalRaised -= transferAmount;
        totalTkensSold -= tokenBal;

        maxallocation[msg.sender] += transferAmount;

        delete spentAllocation[msg.sender];
        delete tokenBalance[msg.sender];

    
        if(saleData.usetoken){
            buyToken.transfer(msg.sender, transferAmount);

        }else{
            payable(msg.sender).transfer(transferAmount);
        }
    
    }

    

    
    function Claim() external{
        require(finalised, "NF");
        require(tokenBalance[msg.sender] > 0, "0Bal");
        
        if(!Vesting){
        
            _normalClaim();    
        
        }else {
        
            _vestingClaim();
        
        }
    }

    function claimRefund() external{
        require(presaleCancelled, "NC");//Not Cancelled
        require(!claimedRefund[msg.sender], "CL");//Claimed
        require(tokenBalance[msg.sender] > 0, "ZB");//Zero Balance
        
        
        uint spent = spentAllocation[msg.sender];
        
        delete spentAllocation[msg.sender];
        delete tokenBalance[msg.sender];
        delete whitelisted[msg.sender];

        claimedRefund[msg.sender] = true;

         
        totalRaised -= spent;
        

        if(saleData.usetoken){
           buyToken.transfer(msg.sender, spent);
        }else{
            payable(msg.sender).transfer(spent);
        }


    }


    function _normalClaim() internal {
        require(spentAllocation[msg.sender] > 0, "ZB");//Zero Balance
        
        uint bal = tokenBalance[msg.sender];

        delete spentAllocation[msg.sender];
        delete maxallocation[msg.sender];
        delete tokenBalance[msg.sender];
        

        token.transfer(msg.sender, bal);
        
    }

    

    function updateVesting(bool newStatus, vestingStruct calldata newvesting) external {
        require(ILaunch(factory).getAuthorized(msg.sender),"UN");//unauthorised
        require(Vesting != newStatus);

        Vesting = newStatus;
        vesting = newvesting;
    }

    uint[] time;
    uint[] percent;

    function getVesting() external view returns(uint[] memory, uint[] memory){
        return(time, percent);
    }

    function setVesting() external {

        VestingCount = 0;
        uint count = vesting.cycleCount; 

        uint totalPrecent = ((count-1) * vesting.cyclePercent) +vesting.firstPercent;

        require(totalPrecent >= 10000, "ALT100");//Amount less than 100

           VestingCount++;
           maxPercent += vesting.firstPercent;

           PeriodtoPercent[VestingCount] = VestingPeriod({
            percent : vesting.firstPercent,
            startTime : vesting.firstReleaseTime,
            vestingCount : VestingCount,
            MaxClaim : maxPercent
        });

        vestingDetails.push(PeriodtoPercent[VestingCount]);

        time.push(vesting.firstReleaseTime);
        percent.push(vesting.firstPercent);

        uint lastime = vesting.firstReleaseTime;
        uint percentAmount;

        
            for(uint i = 2; i<= vesting.cycleCount; i++){
            
            lastime += vesting.cycleReleaseTime;
            
            require(lastime > PeriodtoPercent[VestingCount-1].startTime);
            
            maxPercent += vesting.cyclePercent;
            percentAmount = vesting.cyclePercent;

                if(maxPercent > 10000){

                    maxPercent -= vesting.cyclePercent;
                    percentAmount = 10000 - maxPercent;  

                    maxPercent += percentAmount; 

                }
            
            time.push(lastime);
            percent.push(percentAmount);

            VestingCount++;

            PeriodtoPercent[VestingCount] = VestingPeriod({

                        percent : percentAmount,
                        startTime : lastime,
                        vestingCount : VestingCount,
                        MaxClaim : maxPercent
                    });
                    vestingDetails.push(PeriodtoPercent[VestingCount]);
            }

        
    }

    mapping(address => mapping(uint => bool)) public vestingToClaimed;
    mapping(address => mapping(uint => uint)) public recievedTokens;

    VestingPeriod[] vestingDetails;

    function getVestingDetailes() external view returns(VestingPeriod[] memory){
        return vestingDetails;
    }

  
    function _vestingClaim() public {
        
        require(claimCount[msg.sender] <= VestingCount,"CC");//Claiming Complete

        for(uint i = claimCount[msg.sender]; i<= VestingCount; i++){
            if(PeriodtoPercent[i].startTime <= block.timestamp){

                claimmable[msg.sender] += PeriodtoPercent[i].percent;

                claimCount[msg.sender] ++;

            }
            else {
                break;
            }
            
        }
        
            
        require(claimmable[msg.sender] <= 10000, "OTL");//Over the limit
        
        uint _amount = (claimmable[msg.sender] * TotalBalance[msg.sender]) /10000;

        tokenBalance[msg.sender] -= _amount;
        claimedAmount[msg.sender] += claimmable[msg.sender]; 
  
        delete claimmable[msg.sender];
        
        token.transfer(msg.sender, _amount);

    }

    
    function getWhitelisted(address user) external view returns(bool){
        return whitelisted[user];
    }
    function getMaxAllocationForPresale(address user) external view returns(uint){
        if(whitelist){
            return (maxallocation[user] + spentAllocation[user]);
        }else{
            return saleData.maximumSpend;
        }
    }
    function getTokenBalance(address user) external view returns(uint){
        return tokenBalance[user];
    }
    function getSpentAllocation(address user) external view returns(uint){
        return spentAllocation[user];
    }
    
    function getTarget() external view returns(uint){
        return saleData.hardCap;
    }
    function getTotalRaised() external view returns(uint){
        return totalRaised;
    }
    function getRate() external view returns(uint){
        return saleData.rate;
    }
    function getPresaleToken() external view returns(address){
        return address(token);
    }
    
    function getPresaleStarted() external view returns(bool){
        if(block.timestamp >= startDate){
            return true;
        }else{
            return false;
        }
    }
    function getPresaleStartTime() external view returns(uint){
        return startDate;
    }
    function getFinalised() external view returns(bool){
        return finalised;
    }
    function getUseToken() external view returns(bool){
        return saleData.usetoken;
    }
    function getlocktime() external view returns(uint){
        return saleData.locktime;
    }
    function getMinimumSpend() external view returns(uint){
        return saleData.minimumSpend;
    }
    function getMaximumSpend() external view returns(uint){
        return saleData.maximumSpend;
    }
    function getWhitelist() external view returns(bool){
        return whitelist;
    }
    function getUSDTToBNBValue() external view returns(uint){
        return saleData.usdtToBNBValue;
    }


}