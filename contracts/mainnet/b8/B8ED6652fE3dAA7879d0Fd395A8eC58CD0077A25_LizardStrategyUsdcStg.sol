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

pragma solidity ^0.8.15;

import "../../interface/IMasterChef.sol";
import "../../interface/IERC20.sol";
import "../../interface/IStargateRouter.sol";
import "../../interface/IPoolLpToken.sol";
import "../../interface/IERC20Burnable.sol";
import "../../lib/Math.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LizardStrategyUsdcStg is Initializable {
    address public owner;

    address public stg;
    address public usdc;

    address public susdc;
    uint16 public susdcPoolId;
    address public stgRouter;

    address public chefStg;
    uint256 public chefPoolId;

    address public lizardUsdc;
    address public timelock;

    bool public isExit;

    uint256 public maximumMint;

    mapping(address => bool) public whitelist;

    bool private locked;

    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);

    function initialize(address _lizardUsdc) public initializer {
        stg = 0x6694340fc020c5E6B96567843da2df01b2CE1eb6;
        usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

        susdc = 0x892785f33CdeE22A30AEF750F285E18c18040c3e;
        susdcPoolId = 1;
        stgRouter = 0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614;

        chefStg = 0xeA8DfEE1898a7e0a59f7527F076106d7e44c2176;
        chefPoolId = 0;
        maximumMint = 500000 * 1000000;
        isExit = false;

        lizardUsdc = _lizardUsdc;
        owner = msg.sender;
        timelock = msg.sender;
        _giveAllowances();
    }

    // MODIFIERS
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    // TIMELOCK
    function changeTimelock(address _timelock) public {
        require(msg.sender == timelock, "Not old timelock");
        timelock = _timelock;
    }

    function withdrawUsdcGrowth() public {
        require(msg.sender == timelock, "not timelock");
        uint256 susdcTotalLiquidity = IPoolLpToken(susdc).totalLiquidity();
        uint256 susdcTotalSupply = IPoolLpToken(susdc).totalSupply();

        require(
            susdcTotalLiquidity > 0 && susdcTotalSupply > 0,
            "cant convert (S*USDC) to USDC when (S*USDC).totalLiquidity == 0 || totalSupply == 0"
        );

        uint256 lizardUsdcTotalSupply = IERC20(lizardUsdc).totalSupply();

        (uint256 balanceSusdcChef, ) = IMasterChef(chefStg).userInfo(
            chefPoolId,
            address(this)
        );
        uint256 balanceSusdc = IERC20(susdc).balanceOf(address(this));
        uint256 balanceUsdc = IERC20(usdc).balanceOf(address(this));

        uint256 balanceSusdcInUsdc = ((balanceSusdc + balanceSusdcChef) *
            susdcTotalLiquidity) / susdcTotalSupply; // /!\ can be done juste like that because decimal susdc == decimal usdc

        // do we have enough susdc and usdc to redeem all LizardUsdc supplies ?
        if (balanceSusdcInUsdc + balanceUsdc > lizardUsdcTotalSupply) {
            //we have more than necessary to redeem 100% of the LizardUsdc supply.

            // we unstack the growth
            uint256 amountUsdcGrowth = balanceSusdcInUsdc +
                balanceUsdc -
                lizardUsdcTotalSupply;
            if (amountUsdcGrowth > balanceUsdc) {
                uint256 amountSusdcToRedeem = ((amountUsdcGrowth -
                    balanceUsdc) * susdcTotalSupply) / susdcTotalLiquidity;

                if (amountSusdcToRedeem > balanceSusdc) {
                    IMasterChef(chefStg).withdraw(
                        chefPoolId,
                        Math.min(
                            amountSusdcToRedeem - balanceSusdc,
                            balanceSusdcChef
                        )
                    );
                }

                // we prefert to keep usdc on the contract than susdc so we redeem all
                IStargateRouter(stgRouter).instantRedeemLocal(
                    susdcPoolId,
                    IERC20(susdc).balanceOf(address(this)),
                    address(this)
                );
            }
            // we transfert the growth usdc
            IERC20(usdc).transfer(
                msg.sender,
                Math.min(
                    amountUsdcGrowth,
                    IERC20(usdc).balanceOf(address(this))
                )
            );
        }
    }

    // ONLYOWNER

    function setMaximumMint(uint256 _maximumMint) public onlyOwner {
        maximumMint = _maximumMint;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        if (whitelist[_address]) {
            delete whitelist[_address];
        }
    }

    function withdrawReward() public onlyOwner {
        IMasterChef(chefStg).deposit(chefPoolId, 0);
        IERC20(stg).transfer(msg.sender, IERC20(stg).balanceOf(address(this)));
    }

    function giveAllowances() public onlyOwner {
        _giveAllowances();
    }

    function exit() public onlyOwner {
        (uint256 balanceSusdcChef, ) = IMasterChef(chefStg).userInfo(
            chefPoolId,
            address(this)
        );

        IMasterChef(chefStg).withdraw(chefPoolId, balanceSusdcChef);
        IStargateRouter(stgRouter).instantRedeemLocal(
            susdcPoolId,
            IERC20(susdc).balanceOf(address(this)),
            address(this)
        );
        isExit = true;
    }

    function stopExit() public onlyOwner {
        isExit = false;
    }

    //PUBLIC
    function pegStatus()
        public
        view
        returns (uint256 lizardusdc, uint256 stackedUsdc)
    {
        uint256 susdcTotalLiquidity = IPoolLpToken(susdc).totalLiquidity();
        uint256 susdcTotalSupply = IPoolLpToken(susdc).totalSupply();
        require(
            susdcTotalLiquidity > 0 && susdcTotalSupply > 0,
            "cant convert (S*USDC) to USDC when (S*USDC).totalLiquidity == 0 || totalSupply == 0"
        );
        uint256 lizardUsdcTotalSupply = IERC20(lizardUsdc).totalSupply();

        (uint256 balanceSusdcChef, ) = IMasterChef(chefStg).userInfo(
            chefPoolId,
            address(this)
        );

        uint256 balanceSusdcInUsdc = ((balanceSusdcChef +
            IERC20(susdc).balanceOf(address(this))) * susdcTotalLiquidity) /
            susdcTotalSupply;

        return (
            lizardUsdcTotalSupply,
            balanceSusdcInUsdc + IERC20(usdc).balanceOf(address(this))
        );
    }

    function deposit(uint256 _amountUsdc) public nonReentrant {
        require(
            tx.origin == msg.sender || whitelist[msg.sender],
            "only no smart contract or whitelist"
        );
        require(
            IERC20Burnable(lizardUsdc).totalSupply() + _amountUsdc <
                maximumMint,
            "maximum lizardUsdc minted"
        );

        uint256 oldBalUsdc = IERC20(usdc).balanceOf(address(this));
        IERC20(usdc).transferFrom(msg.sender, address(this), _amountUsdc);
        uint256 balUsdc = IERC20(usdc).balanceOf(address(this));

        require(
            balUsdc >= _amountUsdc + oldBalUsdc,
            "transfert usdc from sender failed"
        );

        IERC20Burnable(lizardUsdc).mint(msg.sender, _amountUsdc);

        if (!isExit) //we stack the usdc
        {
            // convert all usdc we have to susdc
            IStargateRouter(stgRouter).addLiquidity(
                susdcPoolId,
                balUsdc,
                address(this)
            );

            IMasterChef(chefStg).deposit(
                chefPoolId,
                IERC20(susdc).balanceOf(address(this))
            ); //deposit all we have
        }
        emit Deposit(_amountUsdc);
    }

    function withdraw(uint256 _amountUsdc) public nonReentrant {
        require(
            tx.origin == msg.sender || whitelist[msg.sender],
            "only no smart contract or whitelist"
        );
        require(_amountUsdc > 0, "amount must be greater than 0");

        uint256 susdcTotalLiquidity = IPoolLpToken(susdc).totalLiquidity();
        uint256 susdcTotalSupply = IPoolLpToken(susdc).totalSupply();
        require(
            susdcTotalLiquidity > 0 && susdcTotalSupply > 0,
            "cant convert (S*USDC) to USDC when (S*USDC).totalLiquidity == 0 || totalSupply == 0"
        );

        uint256 lizardUsdcTotalSupply = IERC20(lizardUsdc).totalSupply();

        IERC20Burnable(lizardUsdc).burn(msg.sender, _amountUsdc); // burn after read totalSupply

        (uint256 balanceSusdcChef, ) = IMasterChef(chefStg).userInfo(
            chefPoolId,
            address(this)
        );
        uint256 balanceSusdc = IERC20(susdc).balanceOf(address(this));
        uint256 balanceUsdc = IERC20(usdc).balanceOf(address(this));

        uint256 balanceSusdcInUsdc = ((balanceSusdc + balanceSusdcChef) *
            susdcTotalLiquidity) / susdcTotalSupply;

        uint256 canAmountUsdc = _amountUsdc;

        if (
            balanceSusdcInUsdc + balanceUsdc < lizardUsdcTotalSupply
        ) //not enough  to redeem with 1/1 ratio
        {
            canAmountUsdc =
                (canAmountUsdc * (balanceSusdcInUsdc + balanceUsdc)) /
                lizardUsdcTotalSupply;
        }

        if (canAmountUsdc > balanceUsdc) {
            uint256 amountSusdcToRedeem = ((canAmountUsdc - balanceUsdc) *
                susdcTotalSupply) / susdcTotalLiquidity;

            if (amountSusdcToRedeem > balanceSusdc) {
                IMasterChef(chefStg).withdraw(
                    chefPoolId,
                    Math.min(
                        amountSusdcToRedeem - balanceSusdc,
                        balanceSusdcChef
                    )
                );
            }

            IStargateRouter(stgRouter).instantRedeemLocal( // we prefert to keep usdc on the contract than susdc so we redeem all
                susdcPoolId,
                IERC20(susdc).balanceOf(address(this)),
                address(this)
            );
        }

        IERC20(usdc).transfer(
            msg.sender,
            Math.min(canAmountUsdc, IERC20(usdc).balanceOf(address(this)))
        );

        emit Withdraw(_amountUsdc);
    }

    // INTERNAL
    function _giveAllowances() internal {
        IERC20(usdc).approve(stgRouter, type(uint256).max);
        IERC20(susdc).approve(chefStg, type(uint256).max);
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Burnable {
    function mint(address account, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external returns (bool);

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

pragma solidity 0.8.15;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface IPoolLpToken {
    function totalSupply() external view returns (uint256);

    function totalLiquidity() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library Math {

  function max(uint a, uint b) internal pure returns (uint) {
    return a >= b ? a : b;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function positiveInt128(int128 value) internal pure returns (int128) {
    return value < 0 ? int128(0) : value;
  }

  function closeTo(uint a, uint b, uint target) internal pure returns (bool) {
    if (a > b) {
      if (a - b <= target) {
        return true;
      }
    } else {
      if (b - a <= target) {
        return true;
      }
    }
    return false;
  }

  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

}