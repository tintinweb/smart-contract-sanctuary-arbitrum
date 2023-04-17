// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ILpDepositor {
    function tokenID() external view returns (uint256);
    function setTokenID(uint256 tokenID) external returns (bool);
    function totalBalances(address pool) external view returns (uint256);
    function getReward(address pool, address token) external;
    function claimRewards(address pool, address token) external;
    function pendingRewards(address pool, address reward) external view returns (uint);
 
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ILpDepositor.sol";


contract Rewarder is Initializable, IERC20 {

    // Reward data vars
    struct Reward {
        uint integral;
        uint delta;
    }

    // account -> token -> integral
    mapping(address => mapping(address => uint)) public rewardIntegralFor;
    // token -> integral
    mapping(address => Reward) public rewardIntegral;
    // account -> token -> claimable
    mapping(address => mapping(address => uint)) public claimable;
    // list of reward tokens
    address[] public rewards;
    mapping(address => bool) isReward;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    // ERC20 vars
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    mapping(address => mapping(address => uint)) public allowance;

    address depositor;
    address pool;

    // events
    event TransferDeposit(address indexed from, address indexed to, uint amount);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);

    constructor() {
        _disableInitializers();
        }

    function initialize(address _pool, address _reward, address _depositor) external initializer {
        require(pool == address(0));
        pool = _pool;
        
        if (!isReward[_reward]) isReward[_reward] = true;
        rewards.push(_reward);

        depositor = _depositor;
        string memory _symbol = IERC20(pool).symbol();
        name = string(abi.encodePacked("Ennead ", _symbol, " Deposit"));
        symbol = string(abi.encodePacked("nead-", _symbol));
    }

    function stakeFor(address account, uint amount) external  {
        require(msg.sender == depositor);

        updateAllIntegrals(account);
        mint(account, amount);
        // gas savings, it's highly unlikely for totalSupply and balanceOf to exceed max uint
        unchecked {
            totalSupply += amount;
            balanceOf[account] += amount;
        }
    }

    function withdraw(address account, uint amount) external  {
        require(msg.sender == depositor);

        updateAllIntegrals(account);
        totalSupply -= amount;
        balanceOf[account] -= amount;
        burn(account, amount);
    }

    // @notice earned is an estimation and is not exact until checkpoints have actually been updated.
    function earned(address account, address[] calldata tokens) external view returns (uint[] memory) {
        uint len = tokens.length;
        uint[] memory pending = new uint[](len);
        uint bal = balanceOf[account];
        uint _totalSupply = totalSupply;
        address _pool = pool;

        if (bal > 0) {
            for(uint i; i < len; ++i) {
                pending[i] += claimable[account][tokens[i]];
                uint integral = rewardIntegral[tokens[i]].integral;

                if(totalSupply > 0) {
                uint256 delta = ILpDepositor(depositor).pendingRewards(_pool, tokens[i]);
                delta -= delta * 15 / 100;
                integral += 1e18 * delta / _totalSupply;
                }

                uint integralFor = rewardIntegralFor[account][tokens[i]];
                if (integralFor < integral) pending[i] += bal * (integral - integralFor) / 1e18;
            }
        } else {
            for(uint i; i < len; ++i) {
                 pending[i] = claimable[account][tokens[i]];
            }
        }
        return pending;
    }

    function updateAllIntegrals(address account) internal {
        // always update integrals before any balance changes
        uint len = rewards.length;
        // gas savings, only do a for loop if rewards > 1
        if(len > 1) {
            address[] memory _rewards = rewards;
            for(uint i; i < len;) {
                _updateIntegralPerReward(account, _rewards[i]);
                // gas savings, since `i` is constrained by `len`, it is impossible to overflow.
                unchecked {
                    ++i;
                }
            }
        } else {
            // ram will always be index 0. It's highly unlikely for a gauge to have other rewards without having ram too.
            _updateIntegralPerReward(account, rewards[0]);
            }
    }

    function _updateIntegralPerReward(address account, address token) internal {
        Reward memory _integral = rewardIntegral[token];
        uint total = totalSupply;

        // gas savings, delta will never be negative, and it is extremely unlikely for integral to overflow
        unchecked {
            if (total > 0) {
                uint _delta = _integral.delta;
                ILpDepositor(depositor).claimRewards(pool,token);
                uint bal = IERC20(token).balanceOf(address(this));
                _delta =  bal - _delta;

            
            if (_delta > 0) {
                _integral.integral += 1e18 * _delta / total;
                _integral.delta = bal;
                rewardIntegral[token] = _integral;
            }
        }
            if (account != address(0)) {
                uint integralFor = rewardIntegralFor[account][token];
                if (integralFor < _integral.integral) {
                    claimable[account][token] += balanceOf[account] * (_integral.integral - integralFor) / 1e18;
                    rewardIntegralFor[account][token] = _integral.integral;
                }
            }   
        } 
    }

    function getReward(address account) external {
        require(msg.sender == account || msg.sender == depositor);

        uint len = rewards.length;
        if (len > 1) {
            address[] memory _rewards = rewards;
            
            for (uint i; i < len;) {
                _updateIntegralPerReward(account, _rewards[i]);
                uint claims = claimable[account][_rewards[i]];
                unchecked {
                    rewardIntegral[_rewards[i]].delta -= claims;
                }
                delete claimable[account][rewards[i]];

                IERC20(rewards[i]).transfer(account, claims);
                emit RewardPaid(account, _rewards[i], claims);
                unchecked {
                    ++i;
                }
            }
        } else {
            address _reward = rewards[0];
            _updateIntegralPerReward(account, _reward);
            uint claims = claimable[account][_reward];
            // gas savings, balance will never go below claimable
            unchecked {
                rewardIntegral[_reward].delta -= claims;
            }
            delete claimable[account][_reward];

            IERC20(_reward).transfer(account, claims);
            emit RewardPaid(account, _reward, claims);
        }
        

    }
    // @notice In case a new reward token is added, to allow distribution to stakers.
    function addRewardToken(address token) external {
        require(msg.sender == depositor);

        if(!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
        }
    }
    
    /* 
     *   @notice Remove reward tokens if there haven't been emissions to it in awhile. Saves a lot of gas on interactions.
     *   @dev Must be very careful when calling this function as users will not be able to claim rewards for the token that was removed.
     *   While there is some security measure in place, the caller must still ensure that all users have claimed rewards before this is called.
     */
    function removeRewardToken(address token) external {
        require(msg.sender == depositor);
        // 0 balance assumes each user has already claimed their rewards.
        require(IERC20(token).balanceOf(address(this)) == 0);
        // ram will always be index 0, can't remove that.
        require(token != rewards[0]);

        address[] memory _rewards = rewards;
        uint len = _rewards.length;
        uint idx;

        isReward[token] = false;

        // get reward token index
        for (uint i; i < len; ++i) {
            if (_rewards[i] == token) {
                idx = i;
            }
        }
        
        // remove from rewards list
        for (uint256 i = idx; i < len - 1; ++i) {
            rewards[i] = rewards[i + 1];
        }
        rewards.pop();

    }

    function approve(address _spender, uint _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferDeposit(address from, address to, uint amount) internal returns (bool) {
        // update rewards of sender before any balance change
        updateAllIntegrals(from);
        balanceOf[from] -= amount;

        // update rewards of receiver before any balance change.
        updateAllIntegrals(to);
        unchecked {
            balanceOf[to] += amount;
        }
        emit TransferDeposit(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint amount) internal {
        require(amount > 0, "Can't transfer 0!");
        transferDeposit( from, to, amount);
        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

  
    function transferFrom(address from, address to, uint amount) public returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] -= amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    function mint(address _to, uint _value) internal returns (bool) {
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function burn(address _from, uint _value) internal returns (bool) {
        emit Transfer(_from, address(0), _value);
        return true;
    }

    function rewardsListLength() external view returns (uint) {
        return rewards.length;
    }

}