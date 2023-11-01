// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ReaderDatatype } from "../ReaderDatatype.sol";

interface IDLPRush {
    struct UserInfo {
        uint256 converted;
        uint256 factor;
    }
    
    function totalConverted() external view returns (uint256);
    function userInfos(address _user) external view returns(UserInfo memory); 
}

interface IVlmgp
{
    function totalLocked() external view returns (uint256);
    function getUserTotalLocked(address _user) external view returns (uint256);
}

interface IBurnEventManager
{
    function eventInfos(uint256 _eventId) external view returns( uint256, string memory, uint256, bool); 
    function userMgpBurnAmountForEvent(address _user, uint256 evntId) external view returns(uint256);
}

interface IRadpieReader is ReaderDatatype
{
    function getRadpieInfo(address account) external view returns (RadpieInfo memory);
    function getRadpiePoolInfo(
        uint256 poolId,
        address account,
        RadpieInfo memory systemInfo
    ) external view returns (RadpiePool memory);
}

interface IPendleRushV4
{
    function totalAccumulated() external view returns (uint256);
    function userInfos(address _user) external view returns(uint256, uint256); 
}

interface IDlpHelper
{
   	function getPrice() external view returns (uint256 priceInEth);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
pragma abicoder v2;

struct LockedBalance {
	uint256 amount;
	uint256 unlockTime;
	uint256 multiplier;
	uint256 duration;
}

struct EarnedBalance {
	uint256 amount;
	uint256 unlockTime;
	uint256 penalty;
}

struct Reward {
	uint256 periodFinish;
	uint256 rewardPerSecond;
	uint256 lastUpdateTime;
	uint256 rewardPerTokenStored;
	// tracks already-added balances to handle accrued interest in aToken rewards
	// for the stakingToken this value is unused and will always be 0
	uint256 balance;
}

struct Balances {
	uint256 total; // sum of earnings and lockings; no use when LP and RDNT is different
	uint256 unlocked; // RDNT token
	uint256 locked; // LP token or RDNT token
	uint256 lockedWithMultiplier; // Multiplied locked amount
	uint256 earned; // RDNT token
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct VestingSchedule {
    uint256 amount;
    uint256 endTime;
}    

interface IRDNTVestManagerReader {

    function nextVestingTime() external view returns(uint256);

    function getAllVestingInfo(
        address _user
    ) external view returns (VestingSchedule[] memory , uint256 totalRDNTRewards, uint256 totalVested, uint256 totalVesting);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IDLPRush } from "./interfaces/IRadpieIDODataReader.sol";
import { IVlmgp } from "./interfaces/IRadpieIDODataReader.sol";
import { IBurnEventManager } from "./interfaces/IRadpieIDODataReader.sol";
import { IRadpieReader } from "./interfaces/IRadpieIDODataReader.sol";
import { IPendleRushV4 } from "./interfaces/IRadpieIDODataReader.sol";
import { IDlpHelper } from "./interfaces/IRadpieIDODataReader.sol";

import { ReaderDatatype } from "./ReaderDatatype.sol";

/// @title RadpieIdoDataReader
/// @author Magpie Team

contract RadpieIdoDataReader is Initializable, OwnableUpgradeable, ReaderDatatype {

       /* ============ State Variables ============ */

       IDLPRush public dlpRush;
       IVlmgp public vlmgp;
       IBurnEventManager public burnEventManager;
       IRadpieReader public radpieReader;
       IPendleRushV4 public pendleRushV4;

       uint256 public totalWomConvereted;
       mapping(address => uint256) public userConvertedWom;

       address public radpieAdmin = 0x0CdB34e6a4D635142BB92fe403D38F636BbB77b8;

       /* ============ Structs ============ */

       struct RadpieIdoData {
              uint256 totalMdlpConverterd;
              uint256 userConvertedMdlp;
              uint256 totalLockedMgp;
              uint256 userLockedMgp;
              uint256 totelBurnedMgpInEventByUser;
              uint256  totelBurnedMgpInGivenEvent;
              uint256 totalRadpieTvl;
              uint256 userTotalTvlInRadpieExcludeMDlp;
              userTvlInfo[] usertvlinfo; 
              uint256 totelmPendleConverted;
              uint256 totelmPendleConvertedByUser;
              uint256 totalWomConvereted;
              uint256 userConvertedWom;
       }

       struct userTvlInfo {
              address poolAddress;
              uint256 usersTvl;
       }

       IDlpHelper public dlpHelper;

    /* ============ Errors ============ */

       error IsZeroAddress();
       error IsZeroAmount();

    /* ============ Constructor ============ */

       function __RadpieIdoDataReader_init(
              address _dlpRush, 
              address _vlMgp, 
              address _burnEventManager, 
              address _radpieReader,
              address _pendleRushV4,
              address _dlpHelper
       ) 
       public initializer 
       {
              __Ownable_init();
              dlpRush = IDLPRush(_dlpRush);
              vlmgp = IVlmgp(_vlMgp);
              burnEventManager = IBurnEventManager(_burnEventManager);
              radpieReader = IRadpieReader(_radpieReader);
              pendleRushV4 = IPendleRushV4(_pendleRushV4);
              dlpHelper = IDlpHelper(_dlpHelper);
       }

    /* ============ External Getters ============ */

       function getMDlpHoldersData( address _user ) external view returns( uint256 totalMdlpConverterd, uint256 userConvertedMdlp)
       {   
              if(address(dlpRush) != address(0)) 
              {
                     totalMdlpConverterd = dlpRush.totalConverted() * dlpHelper.getPrice() ; 
                     userConvertedMdlp = dlpRush.userInfos(_user).converted * dlpHelper.getPrice();
              }
       }

       function getvlLMgpHoldersData( address _user ) external view returns( uint256 totalLockedMgp, uint256 userLockedMgp )
       {   
              if(address(vlmgp) != address(0)) 
              {
                     totalLockedMgp = vlmgp.totalLocked(); 
                     userLockedMgp = vlmgp.getUserTotalLocked(_user);
              }
       }

       function getMgpBurnersData( uint256 _eventId, address _user ) external view returns( uint256 totelBurnedMgpInEventByUser, uint256 totelBurnedMgpInGivenEvent)
       {   
              if(address(burnEventManager) != address(0)) 
              {
                     totelBurnedMgpInEventByUser = burnEventManager.userMgpBurnAmountForEvent(_user, _eventId);
                     (,, totelBurnedMgpInGivenEvent, ) = burnEventManager.eventInfos(_eventId);
              }
       }

       function getRadpieTvlProvidersData( address _user ) external view returns( uint256 totalRadpieTvl, userTvlInfo[] memory, uint256 userTotalTvlInRadpieExcludeMDLp )
       {
              uint256 _userTotalTvlInRadpieExcludeMDlp;
              userTvlInfo[] memory usertvlinfo;

              if(address(radpieReader) != address(0)) 
              {
                     RadpieInfo memory radpieinfo = radpieReader.getRadpieInfo(radpieAdmin);

                     for(uint256 i = 1; i < radpieinfo.pools.length; i++) // at 0 index mPendle that excluded.
                     {
                            totalRadpieTvl += radpieinfo.pools[i].tvl;
                     }   

                     RadpiePool[] memory pools = new RadpiePool[](radpieinfo.pools.length);
                     usertvlinfo = new userTvlInfo[](radpieinfo.pools.length - 1);   

                     for (uint256 i = 1; i < radpieinfo.pools.length; ++i) { // at 0 index mPendle that excluded.
                            pools[i] =  radpieReader.getRadpiePoolInfo(i, _user, radpieinfo);
                            usertvlinfo[i - 1].poolAddress = pools[i].asset;
                            usertvlinfo[i - 1].usersTvl = pools[i].accountInfo.tvl;
                            _userTotalTvlInRadpieExcludeMDlp += pools[i].accountInfo.tvl;
                     }  
              }

              return (totalRadpieTvl, usertvlinfo, _userTotalTvlInRadpieExcludeMDlp);
       }

       function getmPendleConverterData( address _user ) external view returns( uint256 totelmPendleConverted, uint256 totelmPendleConvertedByUser)
       {   
              if(address(pendleRushV4) != address(0)) 
              {
                     totelmPendleConverted =  pendleRushV4.totalAccumulated();     
                     ( totelmPendleConvertedByUser, ) = pendleRushV4.userInfos(_user); 
              }
       }

       function getWomConverterDataInWomUp(address _user) external view returns(uint256 _totalWomConvereted, uint256 _userConvertedWom)
       {
             
              _userConvertedWom = userConvertedWom[_user];
              _totalWomConvereted = totalWomConvereted;
       } 

       function getRadpieIdoData( uint256 _mgpBurnEventId, address _user ) external view returns ( RadpieIdoData memory )
       {
              RadpieIdoData memory radpieidodata;

              if(address(dlpRush) != address(0)) 
              {
                     radpieidodata.totalMdlpConverterd = dlpRush.totalConverted(); 
                     radpieidodata.userConvertedMdlp = dlpRush.userInfos(_user).converted;
              } 
              if(address(vlmgp) != address(0)) 
              {
                     radpieidodata.totalLockedMgp = vlmgp.totalLocked(); 
                     radpieidodata.userLockedMgp = vlmgp.getUserTotalLocked(_user);
              }
              if(address(burnEventManager) != address(0)) 
              {
                     radpieidodata.totelBurnedMgpInEventByUser = burnEventManager.userMgpBurnAmountForEvent(_user, _mgpBurnEventId);
                     (,, radpieidodata.totelBurnedMgpInGivenEvent, ) = burnEventManager.eventInfos(_mgpBurnEventId);
              }
              
              if(address(radpieReader) != address(0)) 
              {
                     // uint256 totalRadpieTvl;
                     RadpieInfo memory radpieinfo = radpieReader.getRadpieInfo(radpieAdmin);       
                     for(uint256 i = 1; i < radpieinfo.pools.length; i++) // at 0 index mPendle that excluded.
                     {
                            radpieidodata.totalRadpieTvl += radpieinfo.pools[i].tvl;
                     }   

                     RadpiePool[] memory pools = new RadpiePool[](radpieinfo.pools.length);
                     userTvlInfo[] memory _usertvlinfo = new userTvlInfo[](radpieinfo.pools.length - 1);   

                     for (uint256 i = 1; i < radpieinfo.pools.length; ++i) { // at 0 index mPendle that excluded.
                            pools[i] =  radpieReader.getRadpiePoolInfo(i, _user, radpieinfo);
                            _usertvlinfo[i - 1].poolAddress = pools[i].asset;
                            _usertvlinfo[i - 1].usersTvl = pools[i].accountInfo.tvl;
                            radpieidodata.userTotalTvlInRadpieExcludeMDlp += pools[i].accountInfo.tvl;
                     }  
                     radpieidodata.usertvlinfo = _usertvlinfo;
              }
              if(address(pendleRushV4) != address(0)) 
              {
                     radpieidodata.totelmPendleConverted =  pendleRushV4.totalAccumulated();     
                     (radpieidodata.totelmPendleConvertedByUser, ) = pendleRushV4.userInfos(_user); 
              }

              radpieidodata.totalWomConvereted = totalWomConvereted;
              radpieidodata.userConvertedWom = userConvertedWom[_user];

              return radpieidodata;
       }

    /* ============ Admin functions ============ */

       function config(
              address _dlpRush, 
              address _vlMgp, 
              address _burnEventManager, 
              address _radpieReader,
              address _pendleRushV4,
              address _dlpHelper,
              address _radpieAdmin
       ) external onlyOwner {
              dlpRush = IDLPRush(_dlpRush);
              vlmgp = IVlmgp(_vlMgp);
              burnEventManager = IBurnEventManager(_burnEventManager);
              radpieReader = IRadpieReader(_radpieReader);
              pendleRushV4 = IPendleRushV4(_pendleRushV4);
              dlpHelper = IDlpHelper(_dlpHelper);
              radpieAdmin = _radpieAdmin;
       }

       function setUsersWomConvertedDataInWomUp(address[] memory _users, uint256[] memory _amounts) external onlyOwner
       {
              for( uint256 i = 0; i < _users.length; i++)
              {
                     totalWomConvereted += _amounts[i];
                     userConvertedWom[_users[i]] = _amounts[i];
              }
       }

       function setDlpHelper(address _dlpHelper) external onlyOwner
       {
              dlpHelper = IDlpHelper(_dlpHelper);
       }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/radiant/LockedBalance.sol";
import "./interfaces/radpieReader/IRDNTVestManagerReader.sol";


interface ReaderDatatype {

    struct RadpieInfo {
        address masterRadpie;
        address radpieStaking;
        address rdntRewardManager;
        address rdntVestManager;
        address vlRDP;
        address radpieOFT;
        address RDNT;
        address WETH;
        address RDNT_LP;  
        address mDLP;
        uint256 minHealthFactor;
        uint256 systemHealthFactor;
        RadpieRDNTInfo systemRDNTInfo;
        RadpieEsRDNTInfo esRDNTInfo;
        RadpiePool[] pools;
    }    

    struct RadpieRDNTInfo {
        uint256 lockedDLPUSD;
        uint256 requiredDLPUSD;
        uint256 totalCollateralUSD;
        uint256 nextStartVestTime;
        uint256 lastHarvestTime;
        uint256 totalEarnedRDNT;
        uint256 systemVestable;
        uint256 systemVested;
        uint256 systemVesting;
        uint256 totalRDNTpersec;
        EarnedBalance[] vestingInfos;

        uint256 userVestedRDNT;
        uint256 userVestingRDNT;
        VestingSchedule[] userVestingSchedules;
    }

    struct RadpieEsRDNTInfo {
        address tokenAddress;
        uint256 balance;
        uint256 vestAllowance;
    }
    
    // by pools
    struct RadpiePool {
        uint256 poolId;
        uint256 sizeOfPool;
        uint256 tvl;
        uint256 debt;
        uint256 leveragedTVL;
        address stakingToken; // Address of staking token contract to be staked.
        address receiptToken; // Address of receipt token contract represent a staking position
        address asset;
        address rToken;
        address vdToken;
        address rewarder;
        address helper;
        bool    isActive;
        bool    isNative;
        string  poolType;
        uint256 assetPrice;
        uint256 maxCap;
        uint256 quotaLeft;
        RadpieLendingInfo radpieLendingInfo;
        ERC20TokenInfo stakedTokenInfo;
        RadpieAccountInfo  accountInfo;
        RadpieRewardInfo rewardInfo;
        RadpieLegacyRewardInfo legacyRewardInfo;
    }

    struct RadpieAccountInfo {
        uint256 balance;
        uint256 stakedAmount;  // receipttoken
        uint256 stakingAllowance; // asset allowance
        uint256 availableAmount; // current stake amount
        uint256 mDLPAllowance;
        uint256 lockRDPAllowance;
        uint256 rdntBalance;
        uint256 rdntDlpBalance;
        uint256 tvl;
    }

    struct RadpieRewardInfo {
        uint256 pendingRDP;
        address[]  bonusTokenAddresses;
        string[]  bonusTokenSymbols;
        uint256[]  pendingBonusRewards;
        uint256 entitledRDNT;
    }

    struct RadpieLendingInfo {
        uint256 healthFactor;
        uint256 depositRate;
        uint256 borrowRate;
        uint256 RDNTDepositRate;
        uint256 RDNTDBorrowRate;
        uint256 depositAPR;
        uint256 borrowAPR;
        uint256 RDNTAPR;
        uint256 RDNTpersec;
    }        

    struct RadpieLegacyRewardInfo {
        uint256[]  pendingBonusRewards;
        address[]  bonusTokenAddresses;
        string[] bonusTokenSymbols;
    }

    struct ERC20TokenInfo {
        address tokenAddress;
        string symbol;
        uint256 decimals;
    }
}