// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
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
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
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
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ContextUpgradeable} from "../../utils/ContextUpgradeable.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20, IERC20Metadata, IERC20Errors {
    /// @custom:storage-location erc7201:openzeppelin.storage.ERC20
    struct ERC20Storage {
        mapping(address account => uint256) _balances;

        mapping(address account => mapping(address spender => uint256)) _allowances;

        uint256 _totalSupply;

        string _name;
        string _symbol;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC20")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC20StorageLocation = 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

    function _getERC20Storage() private pure returns (ERC20Storage storage $) {
        assembly {
            $.slot := ERC20StorageLocation
        }
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC20Storage storage $ = _getERC20Storage();
        $._name = name_;
        $._symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        ERC20Storage storage $ = _getERC20Storage();
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            $._totalSupply += value;
        } else {
            uint256 fromBalance = $._balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                $._balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                $._totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                $._balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        ERC20Storage storage $ = _getERC20Storage();
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        $._allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC20Upgradeable} from "../ERC20Upgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Initializable} from "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * [CAUTION]
 * ====
 * In empty (or nearly empty) ERC-4626 vaults, deposits are at high risk of being stolen through frontrunning
 * with a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well as unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * Since v4.9, this implementation uses virtual assets and shares to mitigate that risk. The `_decimalsOffset()`
 * corresponds to an offset in the decimal representation between the underlying asset's decimals and the vault
 * decimals. This offset also determines the rate of virtual shares to virtual assets in the vault, which itself
 * determines the initial exchange rate. While not fully preventing the attack, analysis shows that the default offset
 * (0) makes it non-profitable, as a result of the value being captured by the virtual shares (out of the attacker's
 * donation) matching the attacker's expected gains. With a larger offset, the attack becomes orders of magnitude more
 * expensive than it is profitable. More details about the underlying math can be found
 * xref:erc4626.adoc#inflation-attack[here].
 *
 * The drawback of this approach is that the virtual shares do capture (a very small) part of the value being accrued
 * to the vault. Also, if the vault experiences losses, the users try to exit the vault, the virtual shares and assets
 * will cause the first user to exit to experience reduced losses in detriment to the last users that will experience
 * bigger losses. Developers willing to revert back to the pre-v4.9 behavior just need to override the
 * `_convertToShares` and `_convertToAssets` functions.
 *
 * To learn more, check out our xref:ROOT:erc4626.adoc[ERC-4626 guide].
 * ====
 */
abstract contract ERC4626Upgradeable is Initializable, ERC20Upgradeable, IERC4626 {
    using Math for uint256;

    /// @custom:storage-location erc7201:openzeppelin.storage.ERC4626
    struct ERC4626Storage {
        IERC20 _asset;
        uint8 _underlyingDecimals;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC4626")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC4626StorageLocation = 0x0773e532dfede91f04b12a73d3d2acd361424f41f76b4fb79f090161e36b4e00;

    function _getERC4626Storage() private pure returns (ERC4626Storage storage $) {
        assembly {
            $.slot := ERC4626StorageLocation
        }
    }

    /**
     * @dev Attempted to deposit more assets than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxDeposit(address receiver, uint256 assets, uint256 max);

    /**
     * @dev Attempted to mint more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxMint(address receiver, uint256 shares, uint256 max);

    /**
     * @dev Attempted to withdraw more assets than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxWithdraw(address owner, uint256 assets, uint256 max);

    /**
     * @dev Attempted to redeem more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    function __ERC4626_init(IERC20 asset_) internal onlyInitializing {
        __ERC4626_init_unchained(asset_);
    }

    function __ERC4626_init_unchained(IERC20 asset_) internal onlyInitializing {
        ERC4626Storage storage $ = _getERC4626Storage();
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        $._underlyingDecimals = success ? assetDecimals : 18;
        $._asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeCall(IERC20Metadata.decimals, ())
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20Upgradeable) returns (uint8) {
        ERC4626Storage storage $ = _getERC4626Storage();
        return $._underlyingDecimals + _decimalsOffset();
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual returns (address) {
        ERC4626Storage storage $ = _getERC4626Storage();
        return address($._asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual returns (uint256) {
        ERC4626Storage storage $ = _getERC4626Storage();
        return $._asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Ceil);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Ceil);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual returns (uint256) {
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(uint256 assets, address receiver, address owner) public virtual returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256) {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual {
        ERC4626Storage storage $ = _getERC4626Storage();
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom($._asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        ERC4626Storage storage $ = _getERC4626Storage();
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer($._asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";
import {IERC20Metadata} from "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
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
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

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
    function protocolFees() external view returns (uint128 token0, uint128 token1);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IUniswapV3FlashCallback} from "./interfaces/uniswap/IUniswapV3FlashCallback.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {PeripheryImmutableState} from "./Utils/PeripheryImmutableState.sol";
import {PoolAddress} from "./Utils/PoolAddress.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import {TickMath} from "./Utils/TickMath.sol";
import {FullMath, LiquidityAmounts} from "./Utils/LiquidityAmounts.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/// @title Flashloan contract implementation
/// @notice contract using the Uniswap V3 flash function
interface IGNOME {
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint value) external returns (bool);
    function getID(address gnome) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function increaseHP(uint256 tokenId, uint256 _HP) external;
    function increaseXP(uint256 tokenId, uint256 _XP) external;
    function increaseGnomeActivityAmount(string memory activity, uint256 tokenId, uint256 _amount) external;
    function increaseGnomeBoopAmount(uint256 tokenId, uint256 _boopAmount) external;
    function setBoopTimeStamp(uint256 tokenId, uint256 _lastAtackTimeStamp) external;
    function decreaseHP(uint256 tokenId, uint256 _HP) external;
    function canGetBooped(uint256 tokenId) external returns (bool);
    function useGameRewards(address fren, address to, uint256 itemPrice) external;
    function getTokenUserName(uint256 tokenId) external view returns (string memory);
    function getXP(uint256 tokenId) external view returns (uint256);
    function getHP(uint256 tokenId) external view returns (uint256);
    function currentHP(uint256 tokenId) external view returns (uint256);
    function setMeditateTimeStamp(uint256 tokenId, uint256 _meditateTimeStamp) external;
    function isMeditating(uint256 tokenId) external view returns (bool);
    function decreaseXP(uint256 tokenId, uint256 _XP) external;
    function increaseETHSpentAmount(uint256 tokenId, uint256 _ethAmount) external;
    function increaseGnomeSpentAmount(uint256 tokenId, uint256 _gnomeAmount) external;
    function getIsSleeping(uint256 tokenId) external view returns (bool);
    function wakeUpGnome(uint256 tokenId) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
}

interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract GnomeActions is IUniswapV3FlashCallback, Ownable {
    IUniswapV3Pool public pool;
    IGNOME public gnome;
    struct FlashCallbackData {
        address token;
        uint256 amount;
        address payer;
    }
    struct Call {
        address to;
        bytes data;
    }
    uint24 public flashPoolFee = 1000; //  flash from the 0.05% fee of pool
    address private GNOME;
    ISwapRouter public constant swapRouter = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    address WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    mapping(address => uint256) public boopAmountGnome;
    mapping(address => uint256) public boopAmountETH;
    mapping(address => uint256) public activityAmountGnome;
    mapping(address => uint256) public activityAmountETH;
    mapping(address => uint256) public lastBoop;
    uint24 multiplier = 1;
    uint256 priceMultiplier = 100;
    uint256 margin = 100;
    uint256 pricePerBoopETH = 0.01 ether;
    uint256 pricePerBoopGNOME = 420 ether;
    uint256 pricePerFlashBoop = 42000 ether;
    uint256 boopOdds = 40;
    uint256 boopWin = 10;
    uint256 boopLoose = 1;
    uint256 boopHP = 3;
    uint256 meditationTime = 1 hours;
    uint256 boopCoolDown = 30 minutes;
    uint256 public mul = 1;
    uint256 public div = 1;
    uint32 _twapInterval = 100;
    uint256 loopMultiplier = 10;

    mapping(string => uint256) public activityPriceETH;
    mapping(string => uint256) public activityPriceGnome;
    mapping(string => uint256) public activityHP;
    event Boop(address indexed from, string booperName, string boopedName, bool isETH, bool boopResult);
    event MultiBoop(
        address indexed from,
        string booperName,
        string boopedName,
        bool isETH,
        uint256 totalAmount,
        uint256 successfullBoopAmount,
        uint256 volume
    );
    event Activity(address indexed from, string gnomeName, string activity, uint256 newHP);
    event MultiActivity(
        address indexed from,
        string activity,
        string gnomeName,
        bool isETH,
        uint256 totalAmount,
        uint256 newHP,
        uint256 volume
    );

    constructor(address _gnome, address _gnomePlayer) Ownable(msg.sender) {
        //pool = IUniswapV3Pool(0x4762A162bB535b736b83d49a87B3e1AE3267c80c);
        gnome = IGNOME(_gnomePlayer);
        GNOME = _gnome;
        activityPriceGnome["mushroom"] = 420 ether;
        activityPriceGnome["rice"] = 420 ether;
        activityPriceGnome["pea"] = 420 ether;
        activityPriceGnome["banana"] = 69 ether;
        activityPriceGnome["dance"] = 420 ether;
        activityPriceGnome["meditate"] = 420 ether;
        activityPriceGnome["wakeup"] = 4200 ether;
        activityPriceETH["mushroom"] = 0.00069 ether;
        activityPriceETH["rice"] = 0.00069 ether;
        activityPriceETH["pea"] = 0.00069 ether;
        activityPriceETH["banana"] = 0.00042 ether;
        activityPriceETH["dance"] = 0.00069 ether;
        activityPriceETH["meditate"] = 0.00420 ether;
        activityPriceETH["wakeup"] = 0.01 ether;
        activityHP["mushroom"] = 10;
        activityHP["rice"] = 20;
        activityHP["pea"] = 30;
        activityHP["banana"] = 1;
        activityHP["dance"] = 15;
        activityHP["meditate"] = 20;
        activityHP["wakeup"] = 0;
        IGNOME(_gnome).approve(address(swapRouter), type(uint256).max);
    }

    function setPool(address _pool) public onlyOwner {
        pool = IUniswapV3Pool(_pool);
    }

    function gnomeAction(string memory activity) external {
        uint256 tokenId = gnome.getID(msg.sender);
        if (keccak256(abi.encodePacked(activity)) != keccak256(abi.encodePacked("wakeup")))
            require(!gnome.getIsSleeping(tokenId), "You need to wake up your Gnome First!");
        require(
            !gnome.isMeditating(tokenId),
            "Meditating Gnomes must focus on the astral mission they can't indulge in such activities"
        );
        require(tokenId > 0, "User Not SignedUp");
        require(activityPriceGnome[activity] > 0, "Gnomes can't eat that");

        address feedToken = GNOME;
        uint256 amount = activityPriceGnome[activity];

        address otherToken = feedToken == WETH9 ? GNOME : WETH9;
        (address token0, address token1) = feedToken < otherToken ? (feedToken, otherToken) : (otherToken, feedToken);
        uint256 amount0 = feedToken == token0 ? amount : 0;
        uint256 amount1 = feedToken == token1 ? amount : 0;

        FlashCallbackData memory callbackData = FlashCallbackData({token: feedToken, amount: amount, payer: tx.origin});
        IUniswapV3Pool(pool).flash(address(this), amount0, amount1, abi.encode(callbackData, pool));

        gnome.increaseHP(tokenId, activityHP[activity]);
        gnome.increaseGnomeActivityAmount(activity, tokenId, 1);

        if (keccak256(abi.encodePacked(activity)) == keccak256(abi.encodePacked("meditate")))
            gnome.setMeditateTimeStamp(tokenId, block.timestamp + meditationTime);

        if (keccak256(abi.encodePacked(activity)) == keccak256(abi.encodePacked("wakeup"))) gnome.wakeUpGnome(tokenId);

        emit Activity(msg.sender, gnome.getTokenUserName(tokenId), activity, gnome.currentHP(tokenId));
    }

    function setBoopOdds(uint256 _odds, uint256 _boopWin, uint256 _boopLoose) public onlyOwner {
        boopOdds = _odds;
        boopWin = _boopWin;
        boopLoose = _boopLoose;
    }

    function setBoopPrice(uint256 _boopOdds, uint256 _pricePerBoopETH, uint256 _pricePerBoopGNOME) public onlyOwner {
        boopOdds = _boopOdds;
        pricePerBoopETH = _pricePerBoopETH;
        pricePerBoopGNOME = _pricePerBoopGNOME;
    }

    function setBoopHP(uint256 _boopHP) public onlyOwner {
        boopHP = _boopHP;
    }

    function setLoopMultiplier(uint256 _loopMultiplier) public onlyOwner {
        loopMultiplier = _loopMultiplier;
    }

    function currentBoopPrice(bool isFlash, bool isETH) public view returns (uint256) {
        uint256 timeSinceLastBoop = block.timestamp - lastBoop[msg.sender];
        uint256 basePrice = isFlash ? pricePerFlashBoop : isETH ? pricePerBoopETH : pricePerBoopGNOME;
        uint256 startPrice = basePrice * priceMultiplier;

        // Check if it's within the cooldown period to adjust the price
        if (timeSinceLastBoop < boopCoolDown) {
            uint256 priceDecreasePerSecond = (startPrice - basePrice) / boopCoolDown;
            uint256 priceDecrease = timeSinceLastBoop * priceDecreasePerSecond;
            uint256 currentPrice = startPrice - priceDecrease;
            return currentPrice;
        } else {
            return basePrice; // After cooldown, return to base price
        }
    }

    function boopResult(uint256 booperGnome, uint256 boopedGnome, uint256 i) internal returns (bool) {
        uint256 booperGnomeXP = gnome.getXP(booperGnome);
        uint256 boopedGnomeXP = gnome.getXP(boopedGnome);
        // Generate a random number using block.timestamp
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp * i, booperGnome, boopedGnome)));

        // Convert the random number into a boolean
        bool result = (randomNumber % 100) < boopOdds;
        if (result) {
            gnome.increaseXP(booperGnome, (boopedGnomeXP * boopWin) / 100);
            gnome.decreaseHP(boopedGnome, boopHP);

            gnome.setBoopTimeStamp(boopedGnome, block.timestamp);
            if (boopedGnomeXP > 10000) {
                uint256 amount = (booperGnomeXP * boopWin) / 100;
                gnome.decreaseXP(boopedGnome, amount > boopedGnomeXP ? boopedGnomeXP : amount);
            }
        } else {
            if (booperGnomeXP > 10000) {
                uint256 amount = (booperGnomeXP * boopLoose) / 100;
                gnome.decreaseXP(booperGnome, amount > booperGnomeXP ? booperGnomeXP : amount);
            }
        }

        return result;
    }

    function boopGnome(uint256 boopedTokenId) public {
        uint256 booperTokenId = gnome.getID(msg.sender);
        uint256 booperGnomeXP = gnome.getXP(booperTokenId);
        uint256 boopedGnomeXP = gnome.getXP(boopedTokenId);
        require(booperTokenId > 0, "User Not SignedUp");
        require(booperTokenId != boopedGnomeXP, "you can't Boop yourself");
        require(boopedGnomeXP >= booperGnomeXP, "You Can only Boop players with moreXP than you");
        require(
            !gnome.isMeditating(booperTokenId),
            "Meditating Gnomes must focus on the astral mission they can't indulge in such activities"
        );

        require(!gnome.getIsSleeping(booperTokenId), "You need to wake up your Gnome First!");
        require(gnome.canGetBooped(boopedTokenId), "Gnome has been booped rencently or has a shield try again later");

        uint256 boopAmount = currentBoopPrice(true, false);
        address boopToken = GNOME;
        address otherToken = boopToken == WETH9 ? GNOME : WETH9;
        (address token0, address token1) = boopToken < otherToken ? (boopToken, otherToken) : (otherToken, boopToken);
        uint256 amount0 = boopToken == token0 ? boopAmount : 0;
        uint256 amount1 = boopToken == token1 ? boopAmount : 0;
        bool result = boopResult(booperTokenId, boopedTokenId, 1);
        FlashCallbackData memory callbackData = FlashCallbackData({
            token: boopToken,
            amount: boopAmount,
            payer: tx.origin
        });
        IUniswapV3Pool(pool).flash(address(this), amount0, amount1, abi.encode(callbackData, pool));
        emit Boop(
            msg.sender,
            gnome.getTokenUserName(booperTokenId),
            gnome.getTokenUserName(boopedTokenId),
            false,
            result
        );
        lastBoop[msg.sender] = block.timestamp;
    }

    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external override {
        (FlashCallbackData memory callback, address flashPool) = abi.decode(data, (FlashCallbackData, address));
        require(msg.sender == address(pool), "Only Pool can call!");

        address feedToken = callback.token;
        uint256 amount = callback.amount;
        uint256 fee = fee0 > 0 ? fee0 : fee1;
        // start trade
        uint256 amountOwed = amount + fee;
        getFeeFromGnome(feedToken, multiplier * fee, callback.payer);

        IWETH(feedToken).transfer(flashPool, amountOwed);
    }

    function setMulDiv(uint256 _mul, uint256 _div) external onlyOwner {
        mul = _mul;
        div = _div;
    }

    function buyGnome(
        uint256 slip,
        bool isWETH,
        bool slipOn
    ) public payable returns (uint amountGnome, uint amountWeth) {
        if (!isWETH) {
            // Wrap ETH to WETH
            IWETH(WETH9).deposit{value: msg.value}();
            assert(IWETH(WETH9).transfer(address(this), msg.value));
        }

        uint amountToSwap = msg.value;
        uint amountOutMinimum;
        // Approve the router to spend WETH
        IWETH(WETH9).approve(address(swapRouter), msg.value);
        if (slipOn) {
            // Estimate the amount of GNOME to be received
            uint expectedAmountGnome = getExpectedAmountGnome(amountToSwap);

            // Calculate the minimum amount after slippage
            amountOutMinimum = (expectedAmountGnome * (10000 - slip)) / 10000;
        }
        // Set up swap parameters with amountOutMinimum based on slippage tolerance
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: GNOME,
            fee: 10000, // Assuming a 0.1% pool fee
            recipient: msg.sender,
            amountIn: amountToSwap,
            amountOutMinimum: slipOn ? amountOutMinimum : 0,
            sqrtPriceLimitX96: 0
        });

        // Perform the swap
        amountGnome = swapRouter.exactInputSingle(params);
    }

    function getExpectedAmountGnome(uint amountWeth) public view returns (uint expectedAmountGnome) {
        uint price = gnomePrice(address(pool), _twapInterval); // Get the current price of GNOME in terms of WETH
        // Assuming the price is the amount of WETH needed to buy 1 GNOME,
        // and both tokens have the same decimals (e.g., 18),
        // you can calculate the expected amount of GNOME as follows:
        expectedAmountGnome = (amountWeth * (10 ** 18)) / price;
        return expectedAmountGnome;
    }

    function multiActionWeth(string memory activity) public payable returns (uint amountGnome, uint amountWeth) {
        require(activityPriceETH[activity] > 0, "Gnomes can't do that yet");

        uint256 tokenId = gnome.getID(msg.sender);
        require(
            !gnome.isMeditating(tokenId),
            "Meditating Gnomes must focus on the astral mission they can't indulge in such activities"
        );
        if (keccak256(abi.encodePacked(activity)) != keccak256(abi.encodePacked("wakeup")))
            require(!gnome.getIsSleeping(tokenId), "You need to wake up your Gnome First!");
        require(msg.value >= activityPriceETH[activity], "You Need to send more ETH");
        IWETH(WETH9).deposit{value: msg.value}();
        assert(IWETH(WETH9).transfer(address(this), msg.value));

        amountWeth = msg.value;
        gnome.increaseETHSpentAmount(tokenId, amountWeth);
        uint amount = amountWeth / activityPriceETH[activity];
        gnome.increaseHP(tokenId, amount * activityHP[activity]);
        gnome.increaseGnomeActivityAmount(activity, tokenId, amount);
        uint256 volGenerated;
        // Approve the router to spend WETH
        IWETH(WETH9).approve(address(swapRouter), type(uint256).max);
        IWETH(GNOME).approve(address(swapRouter), type(uint256).max);
        activityAmountETH[msg.sender] += msg.value;
        if (keccak256(abi.encodePacked(activity)) == keccak256(abi.encodePacked("meditate")))
            gnome.setMeditateTimeStamp(tokenId, block.timestamp + amount * meditationTime);
        if (keccak256(abi.encodePacked(activity)) == keccak256(abi.encodePacked("wakeup"))) gnome.wakeUpGnome(tokenId);
        // Set up swap parameters
        for (uint256 i = 0; i < amount; i++) {
            // Buy
            for (uint256 j = 0; j < loopMultiplier; j++) {
                volGenerated += amountWeth;
                ISwapRouter.ExactInputSingleParams memory paramsBuy = ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH9,
                    tokenOut: GNOME,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: amountWeth,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                amountGnome = swapRouter.exactInputSingle(paramsBuy);

                // Sell

                ISwapRouter.ExactInputSingleParams memory paramsSell = ISwapRouter.ExactInputSingleParams({
                    tokenIn: GNOME,
                    tokenOut: WETH9,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: (amountGnome * margin) / 100,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                amountWeth = swapRouter.exactInputSingle(paramsSell);
            }
        }

        emit MultiActivity(
            msg.sender,
            activity,
            gnome.getTokenUserName(tokenId),
            true,
            amount,
            gnome.currentHP(tokenId),
            volGenerated
        );
    }

    function multiActionGnome(string memory activity, uint amount) public returns (uint amountGnome, uint amountWeth) {
        require(activityPriceGnome[activity] > 0, "Gnomes can't do that yet");
        uint256 tokenId = gnome.getID(msg.sender);
        require(
            !gnome.isMeditating(tokenId),
            "Meditating Gnomes must focus on the astral mission they can't indulge in such activities"
        );
        if (keccak256(abi.encodePacked(activity)) != keccak256(abi.encodePacked("wakeup")))
            require(!gnome.getIsSleeping(tokenId), "You need to wake up your Gnome First!");
        uint256 _gnomeAmount = activityPriceGnome[activity] * amount;

        IGNOME(GNOME).transferFrom(msg.sender, address(this), _gnomeAmount);
        gnome.increaseHP(tokenId, amount * activityHP[activity]);
        gnome.increaseGnomeActivityAmount(activity, tokenId, amount);
        gnome.increaseGnomeSpentAmount(tokenId, _gnomeAmount);
        uint256 volGenerated;
        // Approve the router to spend WETH

        activityAmountGnome[msg.sender] += activityPriceGnome[activity] * amount;
        IWETH(GNOME).approve(address(swapRouter), type(uint256).max);
        IWETH(WETH9).approve(address(swapRouter), type(uint256).max);
        if (keccak256(abi.encodePacked(activity)) == keccak256(abi.encodePacked("meditate")))
            gnome.setMeditateTimeStamp(tokenId, block.timestamp + amount * meditationTime);

        if (keccak256(abi.encodePacked(activity)) == keccak256(abi.encodePacked("wakeup"))) gnome.wakeUpGnome(tokenId);
        // Set up swap parameters
        for (uint256 i = 0; i < amount; i++) {
            for (uint256 j = 0; j < loopMultiplier; j++) {
                volGenerated += (_gnomeAmount * margin) / 100;
                ISwapRouter.ExactInputSingleParams memory paramsSell = ISwapRouter.ExactInputSingleParams({
                    tokenIn: GNOME,
                    tokenOut: WETH9,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: (activityPriceGnome[activity] * amount * margin) / 100,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                amountWeth = swapRouter.exactInputSingle(paramsSell);

                ISwapRouter.ExactInputSingleParams memory paramsBuy = ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH9,
                    tokenOut: GNOME,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: amountWeth,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                _gnomeAmount = swapRouter.exactInputSingle(paramsBuy);
            }
        }
        emit MultiActivity(
            msg.sender,
            activity,
            gnome.getTokenUserName(tokenId),
            false,
            amount,
            gnome.currentHP(tokenId),
            volGenerated
        );
    }

    function multiBoopWeth(uint256 boopedTokenId) public payable returns (uint amountGnome, uint amountWeth) {
        uint256 booperTokenId = gnome.getID(msg.sender);
        uint256 booperGnomeXP = gnome.getXP(booperTokenId);
        uint256 boopedGnomeXP = gnome.getXP(boopedTokenId);
        require(booperTokenId > 0, "User Not SignedUp");
        require(booperTokenId != boopedGnomeXP, "you can't Boop yourself");
        require(boopedGnomeXP > booperGnomeXP, "You Can only Boop players with moreXP than you");
        require(!gnome.getIsSleeping(booperTokenId), "You need to wake up your Gnome First!");
        require(msg.value >= currentBoopPrice(false, true), "You Need to send more ETH");
        require(
            !gnome.isMeditating(booperTokenId),
            "Meditating Gnomes must focus on the astral mission they can't indulge in such activities"
        );
        require(
            gnome.canGetBooped(boopedTokenId),
            "Gnome has been booped rencently, has a shield or its Meditating try again later"
        );

        IWETH(WETH9).deposit{value: msg.value}();
        assert(IWETH(WETH9).transfer(address(this), msg.value));
        gnome.increaseETHSpentAmount(booperTokenId, msg.value);
        uint amountWeth = msg.value;
        activityAmountETH[msg.sender] += msg.value;
        uint boopAmount = amountWeth / currentBoopPrice(false, true);
        uint256 boopedAmount;
        uint256 volGenerated;

        // Approve the router to spend WETH
        IWETH(WETH9).approve(address(swapRouter), type(uint256).max);
        IWETH(GNOME).approve(address(swapRouter), type(uint256).max);
        boopAmountETH[msg.sender] = msg.value;

        // Set up swap parameters
        for (uint256 i = 0; i < boopAmount; i++) {
            // Buy
            for (uint256 j = 0; j < loopMultiplier; j++) {
                volGenerated += amountWeth;
                ISwapRouter.ExactInputSingleParams memory paramsBuy = ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH9,
                    tokenOut: GNOME,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: amountWeth,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                amountGnome = swapRouter.exactInputSingle(paramsBuy);

                // Sell

                ISwapRouter.ExactInputSingleParams memory paramsSell = ISwapRouter.ExactInputSingleParams({
                    tokenIn: GNOME,
                    tokenOut: WETH9,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: (amountGnome * margin) / 100,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                amountWeth = swapRouter.exactInputSingle(paramsSell);
            }

            bool result = boopResult(booperTokenId, boopedTokenId, i);
            if (result) {
                boopedAmount++;
            }
        }
        emit MultiBoop(
            msg.sender,
            gnome.getTokenUserName(booperTokenId),
            gnome.getTokenUserName(boopedTokenId),
            true,
            boopAmount,
            boopedAmount,
            volGenerated
        );
    }

    function multiBoopGnome(
        uint256 boopedTokenId,
        uint256 _gnomeAmount
    ) public returns (uint amountGnome, uint amountWeth) {
        uint256 booperTokenId = gnome.getID(msg.sender);
        IGNOME(GNOME).transferFrom(msg.sender, address(this), _gnomeAmount);
        require(booperTokenId > 0, "User Not SignedUp");
        require(
            !gnome.isMeditating(booperTokenId),
            "Meditating Gnomes must focus on the astral mission they can't indulge in such activities"
        );
        require(!gnome.getIsSleeping(booperTokenId), "You need to wake up your Gnome First!");
        require(gnome.canGetBooped(boopedTokenId), "Gnome has been booped rencently or has a shield try again later");
        gnome.increaseGnomeSpentAmount(booperTokenId, _gnomeAmount);
        uint boopAmount = _gnomeAmount / currentBoopPrice(false, false);
        uint256 boopedAmount;
        uint256 volume;
        activityAmountGnome[msg.sender] += _gnomeAmount;
        // Approve the router to spend WETH

        boopAmountGnome[msg.sender] = _gnomeAmount;
        IWETH(GNOME).approve(address(swapRouter), type(uint256).max);
        IWETH(WETH9).approve(address(swapRouter), type(uint256).max);
        // Set up swap parameters
        for (uint256 i = 0; i < boopAmount; i++) {
            for (uint256 j = 0; j < loopMultiplier; j++) {
                volume += (_gnomeAmount * margin) / 100;
                ISwapRouter.ExactInputSingleParams memory paramsSell = ISwapRouter.ExactInputSingleParams({
                    tokenIn: GNOME,
                    tokenOut: WETH9,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: (_gnomeAmount * margin) / 100,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                amountWeth = swapRouter.exactInputSingle(paramsSell);

                ISwapRouter.ExactInputSingleParams memory paramsBuy = ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH9,
                    tokenOut: GNOME,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: amountWeth,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                _gnomeAmount = swapRouter.exactInputSingle(paramsBuy);
            }
            bool result = boopResult(booperTokenId, boopedTokenId, 1);
            if (result) {
                boopedAmount++;
            }
        }
        emit MultiBoop(
            msg.sender,
            gnome.getTokenUserName(booperTokenId),
            gnome.getTokenUserName(boopedTokenId),
            false,
            boopAmount,
            boopedAmount,
            volume
        );
    }

    function getFeeFromGnome(address token, uint256 amount, address fren) internal {
        IGNOME(token).transferFrom(fren, address(this), amount);
        activityAmountGnome[fren] += amount;
        uint256 booperTokenId = gnome.getID(fren);
        gnome.increaseGnomeSpentAmount(booperTokenId, amount);
    }

    function changeFlashPoolFee(uint24 poolFee) public onlyOwner {
        flashPoolFee = poolFee;
    }

    function setGameContract(address _gameAddress) public onlyOwner {
        gnome = IGNOME(_gameAddress);
    }

    function setMultiplier(uint24 _multiplier, uint256 _priceMultiplier) public onlyOwner {
        multiplier = _multiplier;
        priceMultiplier = _priceMultiplier;
    }

    function setMargin(uint24 _margin) public onlyOwner {
        margin = _margin;
    }

    function setActionPrice(string memory action, uint256 _priceETH, uint256 _priceGnome) public onlyOwner {
        activityPriceGnome[action] = _priceGnome;
        activityPriceETH[action] = _priceETH;
    }

    function frensFundus() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function somethingAboutTokens(address token) external onlyOwner {
        uint256 balance = IGNOME(token).balanceOf(address(this));
        IGNOME(token).transfer(msg.sender, balance);
    }

    function gnomePrice(address uniswapV3Pool, uint32 twapInterval) public view returns (uint256 price) {
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();

            uint256 amount0 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                FixedPoint96.Q96,
                sqrtPriceX96
            );

            uint256 amount1 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                sqrtPriceX96,
                FixedPoint96.Q96
            );
            price = (amount1 * mul) / (amount0 * div);
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int32(twapInterval)))
            );

            uint256 amount0 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                FixedPoint96.Q96,
                sqrtPriceX96
            );

            uint256 amount1 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                sqrtPriceX96,
                FixedPoint96.Q96
            );

            price = (amount1 * mul) / (amount0 * div);
        }
    }

    function setTwap(uint32 twapInterval) public onlyOwner {
        _twapInterval = twapInterval;
    }

    fallback() external payable {}

    receive() external payable {}
}

/*

░██████╗░███╗░░██╗░█████╗░███╗░░░███╗███████╗██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔════╝░████╗░██║██╔══██╗████╗░████║██╔════╝██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██╗░██╔██╗██║██║░░██║██╔████╔██║█████╗░░██║░░░░░███████║██╔██╗██║██║░░██║
██║░░╚██╗██║╚████║██║░░██║██║╚██╔╝██║██╔══╝░░██║░░░░░██╔══██║██║╚████║██║░░██║
╚██████╔╝██║░╚███║╚█████╔╝██║░╚═╝░██║███████╗███████╗██║░░██║██║░╚███║██████╔╝
░╚═════╝░╚═╝░░╚══╝░╚════╝░╚═╝░░░░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

                                   ╓╓╓▄▄▄▓▓█▓▓▓▓▀▀▀▀▀▀▓█
                             ╓▄██▀╙╙░░░░░░░░░░░░░░░░╠╬║█
                        ╓▄▓▀╙░░░░░░░░░░░░░░░░░░░░░░╠╠╠║▌
                     ╓█╩░░░░░░░░░░░░░░░░░░░░░░░░░░╠╠╠╠║▌
                   ▄█▒░░░░░░░░░░░░░▒▄██████▄▄░░░░░╠╠╠╠║▌
                 ╓██▀▀▀╙╙╚▀░░░░░▄██╩░░░░░░░░╙▀█▄▒░╠╠╠╠╬█
              ╓▓▀╙░░░░░░░░░░░░░╚╩░░░░░░░░░░░░░░╙▀█╠╠╠╠╬▓
             ▄╩░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╠╠╠╠╠║▌
            ║██▓▓▓▓▓▄▄▒░░░░░░░░░░░▄▄██▓█▄▄▒░░░░░░░╠╠╠╠╠╬█
           ╔▀         ╙▀▀█▓▄▄▄██▀╙       └╙▀█▄▒░░░╠╠╠╠╠╠║▌
          ║█▀▀╙╙╙▀▀▓▄╖       ▄▄▓▓▓▓╗▄▄╓      ╙╙█▄▒░╠╠╠╠╠╬█
        ╓▀   ╓╓╓╓╓╓   ╙█▄ ▄▀╙          ╙▀▓▄      ╙▀▓▒▒╠╠╠║▌
        ▐██████████╙╙▀█▄ ╙█▄▓████████▀▀╗▄           █▀███╬█
        █║██████▌ ██    ╙██╓███████╙▀█   └▀╗╓       ║▒   ╙╙▓
       ╒▌╫███████╦╫█     ║ ╫███████╓▄█▌     └█╕     ║▌    ▀█▀▀
        █╚██████████    ╓╣ ║██████████▒    ╔▀╙      ║▒     └█
       ┌╣█╣████████╓╓▄▓▓▒▄█▄║████████▌╓╗╗▀╙        ╓█        ╚▄
       │█▄╗▀▀╙      ╙▀╙         ╙▀▀██▒            ▄█          ╙▄
     █▒                               ╙▀▀▀▀╠█▌╓▄▓▀             ║
      ╙█╓           ╓╓                   ╓██╩║▌                ║
       ╓╣███▄▄▄▄▓██╬╬╠╬███▄▄▄▄╓╓╓╓╓▄▄▄▓█╬╬▒░░╠█             ╔ ┌█
      ╓▌  ▀█╬╬▒╠╠╠╠░▒░░░╠╠╠╚╚╚╩╠╠╠╠╬███▀╩░░░▄█        ▓      █▀
     ╒▌   ╘█░╚╚╚╚╚▀▀▀▀▀▀▀▀▀▀▀▀▀▀╚╚╚░░░░░░▄█▀╙         ║      ▐▌
     ╟     └▀█▄▒▒▒░░░░░░░░░░░▒▒▒▒▒▄▄█▓╝▀╙                    ▐▌
     ║░        ╙╙▀▀▀▀▀▀▀▀▀▀▀▀▀▀╙╙                        ╓   █
      █                                                  ▓ ╓█
      ║▌   ╔                                            ╔█▀
       █   ╚▄                              ╓╩          ╔▀
       ╚▌   ╙                             ▓▀         ╓█╙
        ╙▌          ▐                  ╓═    ▄    ╓▄▀╙
          ▀▄        ╙▒                      ▄██▄█▀
            ╙▀▄╓║▄   └                    ▄╩
                ╙▀█                   ╓▄▀▀
                   ▀▓        ▄▄▓▀▀▀▀╙
                     └▀╗▄╓▄▀╙
    
    
https://www.gnomeland.money/
https://twitter.com/Gnome0xLand

$GNOME

Everywhere...

// SPDX-License-Identifier: MIT

 */
// File: https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/libraries/ExcessivelySafeCall.sol
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File @openzeppelin/contracts/token/ERC20/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

// File @openzeppelin/contracts/utils/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// File @openzeppelin/contracts/token/ERC20/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

pragma solidity >=0.7.6;

abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

library ExcessivelySafeCall {
    uint constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                0, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
        require(_buf.length >= 4);
        uint _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// File: https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/libraries/BytesLib.sol

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes memory _bytes, uint _start, uint _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint _start) internal pure returns (uint) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// File: https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/interfaces/ILayerZeroUserApplicationConfig.sol

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// File: https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/interfaces/ILayerZeroEndpoint.sol

pragma solidity >=0.5.0;

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// File: https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/interfaces/ILayerZeroReceiver.sol

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

// File: https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/LzApp.sol

pragma solidity ^0.8.0;

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;

    // ua can not send payload larger than this by default, but it can be changed by the ua owner
    uint public constant DEFAULT_PAYLOAD_SIZE_LIMIT = 10000;

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint)) public minDstGasLookup;
    mapping(uint16 => uint) public payloadSizeLimitLookup;
    address public precrime;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint _minDstGas);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            _srcAddress.length == trustedRemote.length &&
                trustedRemote.length > 0 &&
                keccak256(_srcAddress) == keccak256(trustedRemote),
            "LzApp: invalid source sending contract"
        );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint _nativeFee
    ) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        _checkPayloadSize(_dstChainId, _payload.length);
        lzEndpoint.send{value: _nativeFee}(
            _dstChainId,
            trustedRemote,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    function _checkGasLimit(
        uint16 _dstChainId,
        uint16 _type,
        bytes memory _adapterParams,
        uint _extraGas
    ) internal view virtual {
        uint providedGasLimit = _getGasLimit(_adapterParams);
        uint minGasLimit = minDstGasLookup[_dstChainId][_type];
        require(minGasLimit > 0, "LzApp: minGasLimit not set");
        require(providedGasLimit >= minGasLimit + _extraGas, "LzApp: gas limit is too low");
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint gasLimit) {
        require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function _checkPayloadSize(uint16 _dstChainId, uint _payloadSize) internal view virtual {
        uint payloadSizeLimit = payloadSizeLimitLookup[_dstChainId];
        if (payloadSizeLimit == 0) {
            // use default if not set
            payloadSizeLimit = DEFAULT_PAYLOAD_SIZE_LIMIT;
        }
        require(_payloadSize <= payloadSizeLimit, "LzApp: payload size is too large");
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address,
        uint _configType
    ) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint _configType,
        bytes calldata _config
    ) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // _path = abi.encodePacked(remoteAddress, localAddress)
    // this function set the trusted path for the cross-chain communication
    function setTrustedRemote(uint16 _remoteChainId, bytes calldata _path) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = _path;
        emit SetTrustedRemote(_remoteChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        require(path.length != 0, "LzApp: no trusted path record");
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    function setPrecrime(address _precrime) external onlyOwner {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint _minGas) external onlyOwner {
        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    // if the size is 0, it means default size limit
    function setPayloadSizeLimit(uint16 _dstChainId, uint _size) external onlyOwner {
        payloadSizeLimitLookup[_dstChainId] = _size;
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// File: https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/NonblockingLzApp.sol

pragma solidity ^0.8.0;

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload)
        );
        if (!success) {
            _storeFailedMessage(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function _storeFailedMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload,
        bytes memory _reason
    ) internal virtual {
        failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
        emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, _reason);
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function retryMessage(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
}

interface IGNOME {
    function authMint(address to) external returns (uint32);
    function fatalizeGnomeAuth(uint32 tokenId) external;
}

pragma solidity 0.8.20;

contract GnomesBridge is NonblockingLzApp {
    address public admin;
    address public GNOME_NFT_ADDRESS;
    mapping(address => bool) public isAuth;
    mapping(address => bool) public isGnome;

    uint256 public maxBridge = 720000e18; //1%
    uint256 public bridgeFee = 1;

    bool public onlyWL = true;

    bool public bridgeHasFee = true;
    mapping(string => uint16) public destChainId;

    constructor(address _lzEndpoint, address _gnomesNFT) NonblockingLzApp(_lzEndpoint) Ownable(msg.sender) {
        admin = msg.sender;
        destChainId["eth"] = 101; //lzendpoint: 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675
        destChainId["base"] = 184; //lzendpoint: 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7
        destChainId["arb"] = 110; //lzendpoint: 0x3c2269811836af69497E5F486A85D7316753cf62
        GNOME_NFT_ADDRESS = _gnomesNFT;
        isGnome[msg.sender] = true;
        isAuth[msg.sender] = true;
    }

    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal override {
        (address toAddress, uint amount) = abi.decode(_payload, (address, uint));
        IGNOME(GNOME_NFT_ADDRESS).authMint(toAddress);
    }

    function bridge(string memory _chainTo, uint32 _tokenId) public payable {
        uint amount;
        if (onlyWL) {
            require(isGnome[msg.sender], "Caller is not the authorized to bridge");
        }
        IGNOME(GNOME_NFT_ADDRESS).fatalizeGnomeAuth(_tokenId);

        bytes memory payload = abi.encode(msg.sender, amount);
        _lzSend(destChainId[_chainTo], payload, payable(msg.sender), address(0x0), bytes(""), msg.value);
    }

    function trustAddress(string memory _chainTo, address _otherContract) public onlyOwner {
        trustedRemoteLookup[destChainId[_chainTo]] = abi.encodePacked(_otherContract, address(this));
    }

    modifier onlyAuth() {
        require(msg.sender == admin || isAuth[msg.sender], "Caller is not the authorized");
        _;
    }

    function setIsAuth(address fren, bool isAuthorized) external onlyAuth {
        isAuth[fren] = isAuthorized;
    }

    function setChainId(string memory _chain, uint16 _ID) external onlyAuth {
        destChainId[_chain] = _ID;
    }

    function setBridgeWL(bool _bool) external onlyAuth {
        onlyWL = _bool;
    }

    function setBridgeHasFee(bool _bool) external onlyAuth {
        bridgeHasFee = _bool;
    }

    function setBridgeFee(uint256 _fee) external onlyAuth {
        require(_fee <= 10, "Bridge Fee can't be bigger than 10%");
        bridgeFee = _fee;
    }
}

// SPDX-License-Identifier: MIT
/*

░██████╗░███╗░░██╗░█████╗░███╗░░░███╗███████╗██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔════╝░████╗░██║██╔══██╗████╗░████║██╔════╝██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██╗░██╔██╗██║██║░░██║██╔████╔██║█████╗░░██║░░░░░███████║██╔██╗██║██║░░██║
██║░░╚██╗██║╚████║██║░░██║██║╚██╔╝██║██╔══╝░░██║░░░░░██╔══██║██║╚████║██║░░██║
╚██████╔╝██║░╚███║╚█████╔╝██║░╚═╝░██║███████╗███████╗██║░░██║██║░╚███║██████╔╝
░╚═════╝░╚═╝░░╚══╝░╚════╝░╚═╝░░░░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

                                   ╓╓╓▄▄▄▓▓█▓▓▓▓▀▀▀▀▀▀▓█
                             ╓▄██▀╙╙░░░░░░░░░░░░░░░░╠╬║█
                        ╓▄▓▀╙░░░░░░░░░░░░░░░░░░░░░░╠╠╠║▌
                     ╓█╩░░░░░░░░░░░░░░░░░░░░░░░░░░╠╠╠╠║▌
                   ▄█▒░░░░░░░░░░░░░▒▄██████▄▄░░░░░╠╠╠╠║▌
                 ╓██▀▀▀╙╙╚▀░░░░░▄██╩░░░░░░░░╙▀█▄▒░╠╠╠╠╬█
              ╓▓▀╙░░░░░░░░░░░░░╚╩░░░░░░░░░░░░░░╙▀█╠╠╠╠╬▓
             ▄╩░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╠╠╠╠╠║▌
            ║██▓▓▓▓▓▄▄▒░░░░░░░░░░░▄▄██▓█▄▄▒░░░░░░░╠╠╠╠╠╬█
           ╔▀         ╙▀▀█▓▄▄▄██▀╙       └╙▀█▄▒░░░╠╠╠╠╠╠║▌
          ║█▀▀╙╙╙▀▀▓▄╖       ▄▄▓▓▓▓╗▄▄╓      ╙╙█▄▒░╠╠╠╠╠╬█
        ╓▀   ╓╓╓╓╓╓   ╙█▄ ▄▀╙          ╙▀▓▄      ╙▀▓▒▒╠╠╠║▌
        ▐██████████╙╙▀█▄ ╙█▄▓████████▀▀╗▄           █▀███╬█
        █║██████▌ ██    ╙██╓███████╙▀█   └▀╗╓       ║▒   ╙╙▓
       ╒▌╫███████╦╫█     ║ ╫███████╓▄█▌     └█╕     ║▌    ▀█▀▀
        █╚██████████    ╓╣ ║██████████▒    ╔▀╙      ║▒     └█
       ┌╣█╣████████╓╓▄▓▓▒▄█▄║████████▌╓╗╗▀╙        ╓█        ╚▄
       │█▄╗▀▀╙      ╙▀╙         ╙▀▀██▒            ▄█          ╙▄
     █▒                               ╙▀▀▀▀╠█▌╓▄▓▀             ║
      ╙█╓           ╓╓                   ╓██╩║▌                ║
       ╓╣███▄▄▄▄▓██╬╬╠╬███▄▄▄▄╓╓╓╓╓▄▄▄▓█╬╬▒░░╠█             ╔ ┌█
      ╓▌  ▀█╬╬▒╠╠╠╠░▒░░░╠╠╠╚╚╚╩╠╠╠╠╬███▀╩░░░▄█        ▓      █▀
     ╒▌   ╘█░╚╚╚╚╚▀▀▀▀▀▀▀▀▀▀▀▀▀▀╚╚╚░░░░░░▄█▀╙         ║      ▐▌
     ╟     └▀█▄▒▒▒░░░░░░░░░░░▒▒▒▒▒▄▄█▓╝▀╙                    ▐▌
     ║░        ╙╙▀▀▀▀▀▀▀▀▀▀▀▀▀▀╙╙                        ╓   █
      █                                                  ▓ ╓█
      ║▌   ╔                                            ╔█▀
       █   ╚▄                              ╓╩          ╔▀
       ╚▌   ╙                             ▓▀         ╓█╙
        ╙▌          ▐                  ╓═    ▄    ╓▄▀╙
          ▀▄        ╙▒                      ▄██▄█▀
            ╙▀▄╓║▄   └                    ▄╩
                ╙▀█                   ╓▄▀▀
                   ▀▓        ▄▄▓▀▀▀▀╙
                     └▀╗▄╓▄▀╙
    

Gnome Factory:
    Mints $GNOMES and creates UniV3 concentrated liquidity position for $GNOME/WETH.
https://www.gnomeland.money/
https://twitter.com/Gnome0xLand




 */
pragma solidity ^0.8.20;
import {TickMath} from "./Utils/TickMath.sol";
import {FullMath, LiquidityAmounts} from "./Utils/LiquidityAmounts.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
pragma abicoder v2;
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
//import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

interface IUniswapV3Factory {
    function owner() external view returns (address);

    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
    function setOwner(address _owner) external;
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
}

interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface IMinimalNonfungiblePositionManager {
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    function mint(
        MintParams calldata params
    ) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    function burn(uint256 tokenId) external;

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}

interface IGNOME {
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint value) external returns (bool);
    function enableTrading() external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function initialize(uint160 sqrtPriceX96) external;
    function getTokenId() external view returns (uint256);
    function factoryMint(address fren) external returns (uint256);
    function signUpReferral(string memory code, address sender, uint gnomeAmount) external;
    function signUpFactory(uint256 _id, string memory _Xusr, uint256 baseEmotion) external;
    function setTreasuryMintTimeStamp(address gnome, uint256 timeStamp) external;
    function setGnomeEmotion(uint256 tokenId, uint256 _gnomeEmotion) external;
}

contract GnomesFactory is ReentrancyGuard {
    IMinimalNonfungiblePositionManager private positionManager;

    struct StakedPosition {
        uint256 tokenId;
        uint128 liquidity;
        uint256 stakedAt;
        uint256 lastRewardTime;
    }

    IUniswapV3Pool private pool;
    ISwapRouter private constant swapRouter = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    address private constant WETH_ADDRESS = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address private POSITION_MANAGER_ADDRESS = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    mapping(address => bool) public isAuth;
    mapping(address => bool) public isRewarder;
    mapping(address => uint256) public gnomeReward;
    mapping(address => uint256) public gameReward;

    mapping(address => StakedPosition) public stakedPositions;
    address public GNOME_ADDRESS;
    address public GNOME_REFERRAL;
    address public GNOME_NFT_ADDRESS;
    address public GNOME_GAME_ADDRESS;
    address public GNOME_NFT_POOL;
    address public GNOME_POOL;
    int24 public tickSpacing = 200; // spacing of the gnome/ETH pool

    uint256 private SQRT_0005_PERCENT = 223606797784075547; //
    uint256 private SQRT_2000_PERCENT = 4472135955099137979; //
    uint256 private positionIndex = 0; //
    mapping(uint256 => uint256) public positionByIndex;
    uint160 private sqrtPriceLimitX96 = type(uint160).max;
    uint256 public treasuryDiscount = 86;
    uint256 public referralDiscount = 66;

    bool private mintOpened = false;
    bool private mintReferral = false;
    bool private communityOwned = false;
    bool flip = false;
    uint256[] public stakedTokenIds;
    address public owner;
    uint32 _twapInterval = 0;

    bool fullrange = true;
    bool nftPoolWeth = true;
    int24 MinTick = -887200; // Replace with actual min tick for the pool
    int24 MaxTick = 887200; // Replace with actual max tick for the pool
    uint128 public totalStakedLiquidity;

    uint256 private mul = 10 ** 18;
    uint256 private div = 1;
    uint256 private finalDiv = 1;
    uint256 private treasuryDelay = 15 minutes; //CHANGE THIS
    uint256 public factoryMints = 0;
    uint256 public maxfactoryMint = 690;

    constructor(address gnomeNFT, address gnome, address gnomeReferral, address gnomeGame) {
        owner = msg.sender;
        isAuth[owner] = true;
        isAuth[address(this)] = true;
        GNOME_ADDRESS = gnome;
        GNOME_NFT_ADDRESS = gnomeNFT;
        GNOME_REFERRAL = gnomeReferral;
        GNOME_GAME_ADDRESS = gnomeGame;

        positionManager = IMinimalNonfungiblePositionManager(POSITION_MANAGER_ADDRESS); //
    }

    event mintedGnomeReferral(address indexed from, string gnomeName, uint256 gnomePrice);
    event mintedGnome(address indexed from, string gnomeName, uint256 gnomePrice);
    event feesCollected(uint256 amount0, uint256 amount1);
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the authorized");
        _;
    }
    // Modifier to restrict access to owner only
    modifier onlyAuth() {
        require(msg.sender == owner || isAuth[msg.sender], "Caller is not the authorized");
        _;
    }
    modifier onlyRewarder() {
        require(msg.sender == owner || isRewarder[msg.sender], "Caller is not the rewarder contract");
        _;
    }

    function setSqrtPriceLimitX96(uint160 _sqrtPriceLimitX96) external onlyAuth {
        sqrtPriceLimitX96 = _sqrtPriceLimitX96;
    }

    function setMulDiv(uint256 _mul, uint256 _div, uint256 _divfinal, bool _nftPoolWeth) external onlyAuth {
        mul = _mul;
        div = _div;
        nftPoolWeth = _nftPoolWeth;
        finalDiv = _divfinal;
    }

    function setIsCommunityOwned(bool _communityOwned) external onlyAuth {
        communityOwned = _communityOwned;
    }

    function openMint(bool _mintOpened) external onlyAuth {
        mintOpened = _mintOpened;
    }

    function openReferral(bool _mintOpened) external onlyAuth {
        mintReferral = _mintOpened;
    }

    function setIsAuth(address fren, bool isAuthorized) external onlyAuth {
        isAuth[fren] = isAuthorized;
    }

    function setIsRewarder(address fren, bool _isRewarder) external onlyAuth {
        isRewarder[fren] = _isRewarder;
    }

    function setPool741(address _gnomePool404) external onlyAuth {
        require(_gnomePool404 != address(0), "Invalid Pool address");

        GNOME_NFT_POOL = _gnomePool404;
    }

    function setMiContracts(
        address _gnome,
        address _gnomeNFT,
        address _gnomeReferral,
        address _gnomeGame
    ) external onlyAuth {
        require(_gnome != address(0), "Invalid GNOME address");
        require(_gnomeNFT != address(0), "Invalid GNOME NFT address");
        require(_gnomeReferral != address(0), "Invalid GNOME Referral address");
        require(_gnomeGame != address(0), "Invalid GNOME Game address");
        GNOME_ADDRESS = _gnome;
        GNOME_NFT_ADDRESS = _gnomeNFT;
        GNOME_REFERRAL = _gnomeReferral;
        GNOME_GAME_ADDRESS = _gnomeGame;
    }

    function setPool(address _pool) public onlyAuth {
        GNOME_POOL = _pool;
        pool = IUniswapV3Pool(_pool);
    }

    function getPositionValue(
        uint256 tokenId
    ) public view returns (uint128 liquidity, address token0, address token1, int24 tickLower, int24 tickUpper) {
        (
            ,
            ,
            // nonce
            // operator
            address _token0, // token0
            address _token1, // token1 // fee
            ,
            int24 _tickLower, // tickLower
            int24 _tickUpper, // tickUpper
            uint128 _liquidity, // liquidity // feeGrowthInside0LastX128 // feeGrowthInside1LastX128 // tokensOwed0 // tokensOwed1
            ,
            ,
            ,

        ) = positionManager.positions(tokenId);

        return (_liquidity, _token0, _token1, _tickLower, _tickUpper);
    }

    function pendingRewards(address user) public view returns (uint256 rewards) {
        rewards = gnomeReward[user];
    }

    function div64x64(uint128 x, uint128 y) internal pure returns (uint128) {
        unchecked {
            require(y != 0);

            uint256 answer = (uint256(x) << 64) / y;

            require(answer <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(answer);
        }
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function collectAllFees(
        address _recipient
    ) external onlyRewarder returns (uint256 totalAmount0, uint256 totalAmount1) {
        uint256 amount0;
        uint256 amount1;

        for (uint i = 0; i < stakedTokenIds.length; i++) {
            IMinimalNonfungiblePositionManager.CollectParams memory params = IMinimalNonfungiblePositionManager
                .CollectParams({
                    tokenId: stakedTokenIds[i],
                    recipient: _recipient,
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                });

            (amount0, amount1) = positionManager.collect(params);
            totalAmount0 += amount0;
            totalAmount1 += amount1;
        }
        emit feesCollected(amount0, amount1);
    }

    function frensFundus() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function setDiscounts(uint256 _treasuryDiscount, uint256 _referralDiscount) external onlyAuth {
        treasuryDiscount = _treasuryDiscount;
        referralDiscount = _referralDiscount;
    }

    function somethingAboutTokens(address token) external onlyOwner {
        uint256 balance = IGNOME(token).balanceOf(address(this));
        IGNOME(token).transfer(msg.sender, balance);
    }

    function swapETH_Half(uint value, bool isWETH) public payable returns (uint amountGnome) {
        if (!isWETH) {
            // Wrap ETH to WETH
            IWETH(WETH_ADDRESS).deposit{value: msg.value}();
            assert(IWETH(WETH_ADDRESS).transfer(address(this), value));
        }

        uint amountToSwap = msg.value / 2;

        // Approve the router to spend WETH
        IWETH(WETH_ADDRESS).approve(address(swapRouter), msg.value);

        // Set up swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH_ADDRESS,
            tokenOut: GNOME_ADDRESS,
            fee: 10000, // Assuming a 0.1% pool fee
            recipient: address(this),
            amountIn: amountToSwap,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Perform the swap
        amountGnome = swapRouter.exactInputSingle(params);
    }

    function mintGnome(
        string memory userX,
        uint256 baseEmotion
    )
        public
        payable
        returns (uint _tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund0, uint refund1)
    {
        uint256 gnomePrice = getGnomeNFTPriceReferral();
        require(msg.value >= getGnomeNFTPrice(), "Not Enough to mint Gnome");
        if (!isAuth[msg.sender]) {
            require(mintOpened, "Minting Not Opened to Public");
        }
        require(factoryMints < maxfactoryMint, "Factory Can't mint more Gnomes");
        // uint numberOfGnomes = msg.value / (getGnomeNFTPrice()); // 1 Gnome costs 0.0333 ETH
        uint amountWETHBefore = IWETH(WETH_ADDRESS).balanceOf(address(this));
        uint amountGnome = swapETH_Half(msg.value, false);
        uint amountWETHAfter = IWETH(WETH_ADDRESS).balanceOf(address(this));
        uint amountWETH = amountWETHAfter - amountWETHBefore;

        // For this example, we will provide equal amounts of liquidity in both assets.
        // Providing liquidity in both assets means liquidity will be earning fees and is considered in-range.
        uint amount0ToMint = amountGnome;
        uint amount1ToMint = amountWETH;

        // Approve the position manager
        TransferHelper.safeApprove(GNOME_ADDRESS, address(POSITION_MANAGER_ADDRESS), amount0ToMint);
        TransferHelper.safeApprove(WETH_ADDRESS, address(POSITION_MANAGER_ADDRESS), amount1ToMint);
        //  for (uint i = 0; i < numberOfGnomes; i++) {
        uint256 id = IGNOME(GNOME_NFT_ADDRESS).factoryMint(msg.sender);
        IGNOME(GNOME_GAME_ADDRESS).signUpFactory(id, userX, baseEmotion);

        // }
        IGNOME(GNOME_NFT_ADDRESS).setTreasuryMintTimeStamp(msg.sender, block.timestamp + treasuryDelay);
        factoryMints++;
        emit mintedGnome(msg.sender, userX, gnomePrice);
        if (isGnomeInRange(msg.sender, true)) {
            return increasePosition(msg.sender, amountGnome, amountWETH);
        } else {
            return mintPosition(msg.sender, msg.sender, amountGnome, amountWETH);
        }
    }

    function mintGnomeReferral(
        string memory code,
        string memory userX,
        uint256 baseEmotion
    )
        public
        payable
        returns (uint _tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund0, uint refund1)
    {
        uint256 gnomePrice = getGnomeNFTPriceReferral();
        if (!isAuth[msg.sender]) {
            require(mintOpened, "Minting Not Opened to Public");
        }
        require(msg.value >= gnomePrice, "Not Enough to mint Gnome");
        if (!isAuth[msg.sender]) {
            require(mintReferral, "Minting Not Opened to Referrals");
        }
        require(factoryMints < maxfactoryMint, "Factory Can't mint more Gnomes");
        // uint numberOfGnomes = msg.value / getGnomeNFTPriceReferral(); // 1 Gnome costs 0.0111 ETH

        IGNOME(GNOME_REFERRAL).signUpReferral(code, msg.sender, 1);
        uint amountWETHBefore = IWETH(WETH_ADDRESS).balanceOf(address(this));
        uint amountGnome = swapETH_Half(msg.value, false);
        uint amountWETHAfter = IWETH(WETH_ADDRESS).balanceOf(address(this));
        uint amountWETH = amountWETHAfter - amountWETHBefore;

        // For this example, we will provide equal amounts of liquidity in both assets.
        // Providing liquidity in both assets means liquidity will be earning fees and is considered in-range.
        uint amount0ToMint = amountGnome;
        uint amount1ToMint = amountWETH;

        // Approve the position manager
        TransferHelper.safeApprove(GNOME_ADDRESS, address(POSITION_MANAGER_ADDRESS), amount0ToMint);
        TransferHelper.safeApprove(WETH_ADDRESS, address(POSITION_MANAGER_ADDRESS), amount1ToMint);
        // for (uint i = 0; i < numberOfGnomes; i++) {
        uint256 id = IGNOME(GNOME_NFT_ADDRESS).factoryMint(msg.sender);
        IGNOME(GNOME_GAME_ADDRESS).signUpFactory(id, userX, baseEmotion);

        //  }
        IGNOME(GNOME_NFT_ADDRESS).setTreasuryMintTimeStamp(msg.sender, block.timestamp + treasuryDelay);
        factoryMints++;
        emit mintedGnomeReferral(msg.sender, userX, gnomePrice);
        if (isGnomeInRange(msg.sender, true)) {
            return increasePosition(msg.sender, amountGnome, amountWETH);
        } else {
            return mintPosition(msg.sender, msg.sender, amountGnome, amountWETH);
        }
    }

    function withdrawOutOfRangePositionAuth(uint256 tokenId) public nonReentrant onlyAuth {
        (uint128 liquidity, , , , ) = getPositionValue(tokenId);
        // Transfer the NFT back to the user
        positionManager.safeTransferFrom(address(this), msg.sender, tokenId, "");

        totalStakedLiquidity -= liquidity;
        // Clear the staked position data
        // Remove the tokenId from the stakedTokenIds array
        for (uint i = 0; i < stakedTokenIds.length; i++) {
            if (stakedTokenIds[i] == tokenId) {
                stakedTokenIds[i] = stakedTokenIds[stakedTokenIds.length - 1];
                stakedTokenIds.pop();
                break;
            }
        }

        removeTokenIdFromArray(tokenId);
    }

    function getTwapX96(address uniswapV3Pool, uint32 twapInterval, bool _isNFT) public view returns (uint256 price) {
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();

            uint256 amount0 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                FixedPoint96.Q96,
                sqrtPriceX96
            );

            uint256 amount1 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                sqrtPriceX96,
                FixedPoint96.Q96
            );
            price = (_isNFT)
                ? (flip) ? ((amount1 * mul) / (amount0 * div)) : ((amount0 * div) / (amount1 * mul))
                : (amount1 * 10 ** 18) / (amount0 * finalDiv);
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int32(twapInterval)))
            );

            uint256 amount0 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                FixedPoint96.Q96,
                sqrtPriceX96
            );

            uint256 amount1 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                sqrtPriceX96,
                FixedPoint96.Q96
            );

            price = (_isNFT)
                ? (flip) ? ((amount1 * mul) / (amount0 * div)) : ((amount0 * div) / (amount1 * mul))
                : (amount1 * 10 ** 18) / (amount0 * finalDiv);
        }
    }

    function setFlip(bool _flip) external onlyAuth {
        flip = _flip;
    }

    function getGnomeNFTPrice() public view returns (uint256 priceGnome) {
        if (nftPoolWeth) {
            priceGnome = (getTwapX96(GNOME_NFT_POOL, _twapInterval, true) * treasuryDiscount) / 100;
        } else {
            priceGnome =
                (getTwapX96(GNOME_POOL, _twapInterval, false) *
                    getTwapX96(GNOME_NFT_POOL, _twapInterval, true) *
                    treasuryDiscount) /
                100;
        }

        return priceGnome;
    }

    function getGnomeNFTPriceReferral() public view returns (uint256 priceGnome) {
        if (nftPoolWeth) {
            priceGnome = (getTwapX96(GNOME_NFT_POOL, _twapInterval, true) * referralDiscount) / 100;
        } else {
            priceGnome =
                (getTwapX96(GNOME_POOL, _twapInterval, false) *
                    getTwapX96(GNOME_NFT_POOL, _twapInterval, true) *
                    referralDiscount) /
                100;
        }

        return priceGnome;
    }

    function isGnomeInRange(address fren, bool isFactory) public view returns (bool) {
        int24 tick = getCurrentTick();

        StakedPosition memory frenposition = stakedPositions[fren];
        uint256 position;
        if (isFactory) {
            position = positionByIndex[positionIndex];
            if (position == 0) return false;
        } else {
            position = frenposition.tokenId;
        }
        (, , , int24 minTick, int24 maxTick) = getPositionValue(position);

        if (minTick < tick && tick < maxTick) {
            return true;
        } else {
            return false;
        }
    }

    function getCurrentTick() public view returns (int24) {
        (, int24 tick, , , , , ) = pool.slot0();
        return tick;
    }

    function swapGnome_Half(uint value) public payable returns (uint amountGnome, uint amountWeth) {
        uint amountToSwap = value / 2;

        // Approve the router to spend Gnome
        IGNOME(GNOME_ADDRESS).approve(address(swapRouter), value);

        // Set up swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: GNOME_ADDRESS,
            tokenOut: WETH_ADDRESS,
            fee: 10000, // Assuming a 0.3% pool fee
            recipient: address(this),
            amountIn: amountToSwap,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Perform the swap
        amountWeth = swapRouter.exactInputSingle(params);
    }

    function mintPosition(
        address fren,
        address rafundAddress,
        uint _amountGnome,
        uint _amountWETH
    ) internal returns (uint _tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund1, uint refund0) {
        uint256 _deadline = block.timestamp + 3360;
        int24 lowerTick;
        int24 upperTick;

        if (fullrange) {
            (lowerTick, upperTick) = (MinTick, MaxTick);
        } else {
            (lowerTick, upperTick) = _getSpreadTicks();
        }

        IMinimalNonfungiblePositionManager.MintParams memory params = IMinimalNonfungiblePositionManager.MintParams({
            token0: GNOME_ADDRESS,
            token1: WETH_ADDRESS,
            fee: 10000,
            tickLower: lowerTick,
            tickUpper: upperTick,
            amount0Desired: _amountGnome,
            amount1Desired: _amountWETH,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: _deadline
        });

        // Note that the pool defined by gnome/WETH and fee tier 0.1% must
        // already be created and initialized in order to mint
        (_tokenId, liquidity, amount0, amount1) = positionManager.mint(params);

        stakedPositions[fren] = StakedPosition(_tokenId, liquidity, block.timestamp, block.timestamp);
        stakedTokenIds.push(_tokenId); // Add the token ID to the array
        positionIndex++;
        positionByIndex[positionIndex] = _tokenId;
        totalStakedLiquidity += liquidity;

        if (amount0 < _amountGnome) {
            refund0 = _amountGnome - amount0;
            //TransferHelper.safeTransfer(GNOME_ADDRESS, rafundAddress, refund0);
            gnomeReward[rafundAddress] += refund0;
        }

        if (amount1 < _amountWETH) {
            refund1 = _amountWETH - amount1;
            TransferHelper.safeTransfer(WETH_ADDRESS, rafundAddress, refund1);
            // uint256 amountGnome = swapWETH(refund1);
            //TransferHelper.safeTransfer(GNOME_ADDRESS, rafundAddress, amountGnome);
            //gnomeReward[rafundAddress] += amountGnome;
        }
    }

    function calculateSumOfLiquidity() public view returns (uint128) {
        uint128 totalLiq = 0;

        for (uint256 i = 0; i < stakedTokenIds.length; i++) {
            uint256 tokenId = stakedTokenIds[i];

            (uint128 liquidity, , , , ) = getPositionValue(tokenId);

            // Add up the liquidity
            totalLiq += liquidity;
        }

        return totalLiq;
    }

    function increasePosition(
        address fren,
        uint _amountGnome,
        uint _amountWETH
    ) internal returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund0, uint refund1) {
        tokenId = positionByIndex[positionIndex];

        uint256 _deadline = block.timestamp + 100;
        IMinimalNonfungiblePositionManager.IncreaseLiquidityParams memory params = IMinimalNonfungiblePositionManager
            .IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: _amountGnome,
                amount1Desired: _amountWETH,
                amount0Min: 0,
                amount1Min: 0,
                deadline: _deadline
            });

        (liquidity, amount0, amount1) = positionManager.increaseLiquidity(params);
        uint128 curr_liquidity = stakedPositions[fren].liquidity + liquidity;

        stakedPositions[fren] = StakedPosition(tokenId, curr_liquidity, block.timestamp, block.timestamp);

        totalStakedLiquidity += liquidity;

        if (amount0 < _amountGnome) {
            refund0 = _amountGnome - amount0;
            // TransferHelper.safeTransfer(GNOME_ADDRESS, fren, refund0);
            gnomeReward[fren] += refund0;
        }

        if (amount1 < _amountWETH) {
            refund1 = _amountWETH - amount1;
            TransferHelper.safeTransfer(WETH_ADDRESS, fren, refund1);
        }
    }

    function removeTokenIdFromArray(uint256 tokenId) internal {
        uint256 length = stakedTokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (stakedTokenIds[i] == tokenId) {
                // Swap with the last element
                stakedTokenIds[i] = stakedTokenIds[length - 1];
                // Remove the last element
                stakedTokenIds.pop();
                break;
            }
        }
    }

    function _getStakedPositionID(address fren) public view returns (uint256 tokenId) {
        StakedPosition memory position = stakedPositions[fren];
        return position.tokenId;
    }

    function _getSpreadTicks() public view returns (int24 _lowerTick, int24 _upperTick) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        (uint160 sqrtRatioAX96, uint160 sqrtRatioBX96) = (
            uint160(FullMath.mulDiv(sqrtPriceX96, SQRT_0005_PERCENT, 1e18)),
            uint160(FullMath.mulDiv(sqrtPriceX96, SQRT_2000_PERCENT, 1e18))
        );

        _lowerTick = TickMath.getTickAtSqrtRatio(sqrtRatioAX96);
        _upperTick = TickMath.getTickAtSqrtRatio(sqrtRatioBX96);

        _lowerTick = _lowerTick % tickSpacing == 0
            ? _lowerTick // accept valid tickSpacing
            : _lowerTick > 0 // else, round up to closest valid tickSpacing
            ? (_lowerTick / tickSpacing + 1) * tickSpacing
            : (_lowerTick / tickSpacing) * tickSpacing;
        _upperTick = _upperTick % tickSpacing == 0
            ? _upperTick // accept valid tickSpacing
            : _upperTick > 0 // else, round down to closest valid tickSpacing
            ? (_upperTick / tickSpacing) * tickSpacing
            : (_upperTick / tickSpacing - 1) * tickSpacing;
    }

    function setTicks(int24 _minTick, int24 _maxTick, int24 _tickSpacing) public onlyOwner {
        MaxTick = _maxTick;
        MinTick = _minTick;
        tickSpacing = _tickSpacing;
    }

    function setTwap(uint32 twapInterval, bool _fullrange) public onlyOwner {
        _twapInterval = twapInterval;
        fullrange = _fullrange;
    }

    function setDelay(uint256 _delay) public onlyOwner {
        treasuryDelay = _delay;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma abicoder v2;

import {IUniswapV3FlashCallback} from "./interfaces/uniswap/IUniswapV3FlashCallback.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {PeripheryImmutableState} from "./Utils/PeripheryImmutableState.sol";
import {PoolAddress} from "./Utils/PoolAddress.sol";
import {SafeMath} from "./Utils/SafeMath.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import {TickMath} from "./Utils/TickMath.sol";
import {FullMath, LiquidityAmounts} from "./Utils/LiquidityAmounts.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/// @title Flashloan contract implementation
/// @notice contract using the Uniswap V3 flash function
interface IGNOME {
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint value) external returns (bool);
    function getID(address gnome) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function increaseHP(uint256 tokenId, uint256 _HP) external;
    function increaseXP(uint256 tokenId, uint256 _XP) external;
    function increaseGnomeActivityAmount(string memory activity, uint256 tokenId, uint256 _amount) external;
    function increaseGnomeBoopAmount(uint256 tokenId, uint256 _boopAmount) external;
    function setGnomeBoopTimeStamp(uint256 tokenId, uint256 _lastAtackTimeStamp) external;
    function decreaseHP(uint256 tokenId, uint256 _HP) external;
    function canGetBooped(uint256 tokenId) external returns (bool);
    function useGameRewards(address fren, address to, uint256 itemPrice) external;
    function getXP(uint256 tokenId) external view returns (uint256);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
}

interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract GnomeShort is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    IUniswapV3Pool public pool;
    IGNOME public gnome;
    uint256 public mul = 10 ** 18;
    uint256 public div = 1;

    address private GNOME;
    ISwapRouter public constant swapRouter = ISwapRouter(0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E);
    address WETH9 = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    uint256 public minShort = 0.01 ether;
    uint256 public minTax = 69 ether;
    uint256 public maxShort = 100 ether;
    uint256 public taxForShort = 10;
    uint256 public maxShorters = 108;
    uint256 public maxLoanTime = 3 days;
    uint256 public margin = 95;
    uint256 public minNFT = 1;
    uint32 twapInterval;
    bool public autoLiquidate = true;
    bool public swapLiquidations = false;
    bool public liqAdded = false;
    bool public canShort = true;
    mapping(address => bool) public _isExcludedFromFee;

    mapping(address => ShortPosition) public shortPositions;
    mapping(address => uint256) public addressIndex;
    address[] public shortHolders;
    event ShortOpened(address _address, uint256 CollateralAmount, uint256 borrowedTokens, uint256 liqPrice);
    event ShortClosed(address _address, uint256 profit, uint256 ETHbuyBack);
    event Liquidated(address _address, uint256 CollateralAmount, uint256 liqPrice);
    struct ShortPosition {
        uint256 amountBorrowed;
        uint256 collateralValue;
        uint256 openTime;
        uint256 tokenPrice;
        uint256 liquidationPrice;
    }

    constructor(address _gnome, address _pool) Ownable(msg.sender) {
        //pool = IUniswapV3Pool(0x4762A162bB535b736b83d49a87B3e1AE3267c80c);
        //gnome = IGNOME(_gnomePlayer);
        GNOME = _gnome;
        pool = IUniswapV3Pool(_pool);

        IGNOME(_gnome).approve(address(swapRouter), type(uint256).max);
    }

    function setPool(address _pool) public onlyOwner {
        pool = IUniswapV3Pool(_pool);
    }

    function setTwap(uint32 _twapInterval) public onlyOwner {
        twapInterval = twapInterval;
    }

    function _swapEthForTokens(uint value, bool isWETH) public payable returns (uint amountGnome, uint amountWeth) {
        if (!isWETH) {
            // Wrap ETH to WETH
            IWETH(WETH9).deposit{value: value}();
            assert(IWETH(WETH9).transfer(address(this), value));
        }

        uint amountToSwap = value;

        // Approve the router to spend WETH
        IWETH(WETH9).approve(address(swapRouter), type(uint256).max);

        // Set up swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: GNOME,
            fee: 10000, // Assuming a 0.1% pool fee
            recipient: address(this),
            amountIn: amountToSwap,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Perform the swap
        amountGnome = swapRouter.exactInputSingle(params);
    }

    function _swapTokensForWeth(uint value) public payable returns (uint amountGnome, uint amountWeth) {
        amountGnome = value;

        // Approve the router to spend WETH
        IWETH(GNOME).approve(address(swapRouter), amountGnome);

        // Set up swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: GNOME,
            tokenOut: WETH9,
            fee: 10000, // Assuming a 0.1% pool fee
            recipient: address(this),
            amountIn: amountGnome,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Perform the swap
        amountWeth = swapRouter.exactInputSingle(params);
    }

    function changeAutoLiquidate(bool _autoliq, bool _swapLiquidations) public onlyOwner returns (bool) {
        autoLiquidate = _autoliq;
        swapLiquidations = _swapLiquidations;

        return true;
    }

    function openFutures(bool _canShort) public onlyOwner returns (bool) {
        canShort = _canShort;

        return true;
    }

    function changeShortConstants(
        uint256 _minShort,
        uint256 _maxShort,
        uint256 _maxShorters,
        uint256 _maxLoanTime,
        uint256 _margin,
        uint256 _taxForShort
    ) public onlyOwner returns (bool) {
        minShort = _minShort;
        maxShort = _maxShort;
        maxShorters = _maxShorters;
        maxLoanTime = _maxLoanTime;
        margin = _margin;
        taxForShort = _taxForShort;
        return true;
    }

    function openShort() public payable nonReentrant {
        uint256 tokenPrice = TokenPrice(address(pool), twapInterval);
        uint256 collateralValue = msg.value;
        IWETH(WETH9).deposit{value: collateralValue}();
        assert(IWETH(WETH9).transfer(address(this), collateralValue));
        uint256 amountBorrowed = (collateralValue / tokenPrice);
        uint256 amountSold = (amountBorrowed * margin) / 100;

        uint256 NftBalance = IGNOME(GNOME).balanceOf(msg.sender);
        require(canShort, "Shorting not Opened");
        require(NftBalance > minNFT, "You dont own Gnome NFTs");
        require(amountBorrowed <= IGNOME(GNOME).balanceOf(address(this)), "No more tokens to lend");
        require(shortHolders.length < maxShorters, "No more shorting spaces");
        require(shortPositions[msg.sender].collateralValue == 0, "Address has Open Short");
        require(msg.value >= minShort, "minimum Short not met");
        require(msg.value <= maxShort, "maximum Short exceded");

        // _addLiquidity(amountBorrowed, collateralValue);

        _swapTokensForWeth(amountBorrowed * 10 ** 18);

        tokenPrice = TokenPrice(address(pool), twapInterval);
        uint256 liquidationPrice = (tokenPrice * (100 + margin)) / 100;
        // Insert the new address into the shortHolders array in sorted order

        uint256 i = shortHolders.length;
        shortHolders.push(msg.sender);

        while (i > 0 && shortPositions[shortHolders[i - 1]].liquidationPrice > liquidationPrice) {
            shortHolders[i] = shortHolders[i - 1];
            addressIndex[shortHolders[i]] = i;
            i--;
        }
        shortHolders[i] = msg.sender;
        addressIndex[msg.sender] = i;
        shortPositions[msg.sender] = ShortPosition(
            amountBorrowed,
            collateralValue,
            block.timestamp,
            tokenPrice,
            liquidationPrice
        );
        emit ShortOpened(msg.sender, collateralValue, amountBorrowed, liquidationPrice);
    }

    function calcProfit(address user) public view returns (uint256) {
        uint256 currTokenPrice = TokenPrice(address(pool), twapInterval);
        uint256 opentokenPrice = shortPositions[user].tokenPrice;
        uint256 collateralValue = shortPositions[user].collateralValue;

        uint256 profitRatio = (100 * opentokenPrice) / currTokenPrice;
        uint256 remainingCollateral = (collateralValue * profitRatio) / 100;

        return remainingCollateral;
    }

    function calcInterest(address user) public view returns (uint256) {
        uint256 currTimeStamp = block.timestamp;
        uint256 openTime = shortPositions[user].openTime;
        uint256 duration = currTimeStamp - openTime;
        uint256 interest = (100 * duration) / maxLoanTime;

        return interest;
    }

    function calcDuration(address user) public view returns (uint256) {
        uint256 currTimeStamp = block.timestamp;
        uint256 openTime = shortPositions[user].openTime;
        uint256 duration = currTimeStamp - openTime;

        return duration;
    }

    address public treasuryWallet = 0xc81b7F012f1bdD97211c9627cDe726cc7e1B28Ab;

    function triggerTreasuryBuyback(uint256 amount) external onlyOwner {
        _swapEthForTokens(amount, false);
    }

    function closeShort() public nonReentrant {
        uint256 closeTokenPrice = TokenPrice(address(pool), twapInterval);
        uint256 liqPrice = shortPositions[msg.sender].liquidationPrice;
        require(shortPositions[msg.sender].collateralValue > 0, "No Open Short");
        require(closeTokenPrice < liqPrice, "YOU BEEN LIQUIDATED");

        uint256 amountBorrowed = shortPositions[msg.sender].amountBorrowed;
        uint256 loanDuration = calcDuration(msg.sender);
        //    uint buybackmargin= (100+ slipage)/100;

        uint256 amountETHrepay = (closeTokenPrice * amountBorrowed);
        uint256 profit = calcProfit(msg.sender);

        uint256 interestFee = (taxForShort * profit * loanDuration) / (100 * maxLoanTime);
        uint256 userFunds = profit - interestFee;
        require(amountETHrepay * 10 ** 18 > IWETH(WETH9).balanceOf(address(this)), "Not Enough WETH in contract");
        (uint amountGnome, uint amountWeth) = _swapEthForTokens(amountETHrepay * 10 ** 18, true);

        if (userFunds > 0 && userFunds <= IWETH(WETH9).balanceOf(address(this))) {
            IWETH(WETH9).approve(address(this), userFunds);
            IWETH(WETH9).withdraw(userFunds);
            bool sentuser = payable(msg.sender).send(userFunds);
            //IWETH(WETH9).transfer(msg.sender, userFunds);
            require(sentuser, "Failed to send ETH");
        }
        if (interestFee > 0 && interestFee <= IWETH(WETH9).balanceOf(address(this))) {
            IWETH(WETH9).approve(address(this), interestFee);
            IWETH(WETH9).withdraw(interestFee);
            bool sent = payable(treasuryWallet).send(interestFee);
            //IWETH(WETH9).transfer(treasuryWallet, interestFee);

            // require(sent, "Failed to send ETH");
        }
        emit ShortClosed(msg.sender, userFunds, amountETHrepay);
        delete shortPositions[msg.sender];

        //  Remove the address from the shortHolders array
        for (uint j = addressIndex[msg.sender]; j < shortHolders.length - 1; j++) {
            shortHolders[j] = shortHolders[j + 1];
        }
        shortHolders.pop();
        delete addressIndex[msg.sender];
    }

    function liquidateAll() public {
        uint256 currentTokenPrice = TokenPrice(address(pool), twapInterval);
        uint256 length = shortHolders.length;
        if (length == 0) return;

        // Iterate over shortHolders array
        for (uint256 i = 0; i < length; i++) {
            // Get the short position for the current holder
            ShortPosition storage position = shortPositions[shortHolders[0]];

            // If the current token price is above the liquidation price, liquidate the position
            if (currentTokenPrice > position.liquidationPrice) {
                uint256 amountETHrepay = (position.collateralValue * margin) / 100;
                // Add any necessary liquidation logic here, such as transferring the collateral
                if (swapLiquidations) _swapEthForTokens(amountETHrepay, true);

                emit Liquidated(shortHolders[0], position.collateralValue, position.liquidationPrice);
                // Remove the position from the shortPositions mapping
                delete shortPositions[shortHolders[0]];

                // Remove the address from the shortHolders array
                if (shortHolders.length > 1)
                    for (uint j = i; j < shortHolders.length - 1; j++) {
                        shortHolders[j] = shortHolders[j + 1];
                    }
                shortHolders.pop();

                length--;
            } else {
                // As the array is sorted, we can stop the loop once we find a position that doesn't meet the criteria
                break;
            }
        }
    }

    function liquidateUser(address user) public {
        uint256 currentTokenPrice = TokenPrice(address(pool), twapInterval);
        uint256 index = addressIndex[user];

        // Iterate over shortHolders array

        // Get the short position for the current holder
        ShortPosition storage position = shortPositions[user];

        // If the current token price is above the liquidation price, liquidate the position
        if (currentTokenPrice > position.liquidationPrice) {
            uint256 amountETHrepay = (position.collateralValue * margin) / 100;
            // Add any necessary liquidation logic here, such as transferring the collateral

            if (swapLiquidations) _swapEthForTokens(amountETHrepay, true);

            emit Liquidated(shortHolders[index], position.collateralValue, position.liquidationPrice);
            // Remove the position from the shortPositions mapping
            delete shortPositions[shortHolders[index]];

            // Remove the address from the shortHolders array
            for (uint j = index; j < shortHolders.length - 1; j++) {
                shortHolders[j] = shortHolders[j + 1];
            }
            shortHolders.pop();
        }
    }

    function frensFundus() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function somethingAboutTokens(address token) external onlyOwner {
        uint256 balance = IGNOME(token).balanceOf(address(this));
        IGNOME(token).transfer(msg.sender, balance);
    }

    function setMulDiv(uint256 _mul, uint256 _div) external onlyOwner {
        mul = _mul;
        div = _div;
    }

    function TokenPrice(address uniswapV3Pool, uint32 twapInterval) public view returns (uint256 price) {
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();

            uint256 amount0 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                FixedPoint96.Q96,
                sqrtPriceX96
            );

            uint256 amount1 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                sqrtPriceX96,
                FixedPoint96.Q96
            );
            price = (amount1 * mul) / (amount0 * div);
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int32(twapInterval)))
            );

            uint256 amount0 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                FixedPoint96.Q96,
                sqrtPriceX96
            );

            uint256 amount1 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                sqrtPriceX96,
                FixedPoint96.Q96
            );

            price = (amount1 * mul) / (amount0 * div);
        }
    }

    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma abicoder v2;

import {IUniswapV3FlashCallback} from "./interfaces/uniswap/IUniswapV3FlashCallback.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {PeripheryImmutableState} from "./Utils/PeripheryImmutableState.sol";
import {PoolAddress} from "./Utils/PoolAddress.sol";
import {SafeMath} from "./Utils/SafeMath.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import {TickMath} from "./Utils/TickMath.sol";
import {FullMath, LiquidityAmounts} from "./Utils/LiquidityAmounts.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/// @title Flashloan contract implementation
/// @notice contract using the Uniswap V3 flash function
interface IGNOME {
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint value) external returns (bool);
    function getID(address gnome) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function increaseHP(uint256 tokenId, uint256 _HP) external;
    function increaseXP(uint256 tokenId, uint256 _XP) external;
    function increaseGnomeActivityAmount(string memory activity, uint256 tokenId, uint256 _amount) external;
    function increaseGnomeBoopAmount(uint256 tokenId, uint256 _boopAmount) external;
    function setGnomeBoopTimeStamp(uint256 tokenId, uint256 _lastAtackTimeStamp) external;
    function decreaseHP(uint256 tokenId, uint256 _HP) external;
    function canGetBooped(uint256 tokenId) external returns (bool);
    function useGameRewards(address fren, address to, uint256 itemPrice) external;
    function getXP(uint256 tokenId) external view returns (uint256);
    function collectAllFees(address _recipient) external returns (uint256 totalAmount0, uint256 totalAmount1);
    function getRankedGnomes()
        external
        view
        returns (uint256[] memory, address[] memory, string[] memory, uint256[] memory, uint256[] memory);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
}

interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract GnomeRewards is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    IUniswapV3Pool public pool;
    IGNOME public gnomeGame;
    IGNOME public gnomeFactory;
    address public feeSource; // Address of the contract from which fees are claimed
    uint256 public lastClaimTime;
    mapping(uint256 => uint256) public rewards; // Maps tokenId to rewards
    uint256 public totalClaimmedETH;
    uint256 public totalClaimmedGNOME;

    uint256 public mul = 10 ** 18;
    uint256 public div = 1;

    address private GNOME;
    ISwapRouter public constant swapRouter = ISwapRouter(0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E);
    address WETH9 = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

    uint32 twapInterval;

    bool public canClaim = true;
    event RewardsDistributed();
    event FeesClaimed(uint256 amount);
    event RewardsDistributed(uint256 totalAmount0, uint256 totalAmount1);

    constructor(address _gnome, address _gnomeGame, address _gnomeFactoryAddress, address _pool) Ownable(msg.sender) {
        //pool = IUniswapV3Pool(0x4762A162bB535b736b83d49a87B3e1AE3267c80c);
        //gnome = IGNOME(_gnomePlayer);
        GNOME = _gnome;
        gnomeGame = IGNOME(_gnomeGame);
        gnomeFactory = IGNOME(_gnomeFactoryAddress);
        pool = IUniswapV3Pool(_pool);
        lastClaimTime = block.timestamp;
        IGNOME(_gnome).approve(address(swapRouter), type(uint256).max);
    }

    function distributeRewards() public {
        require(block.timestamp >= lastClaimTime + 3 days, "Too early to distribute");

        // Collect fees from the GnomeFactory
        (uint256 totalAmount0, uint256 totalAmount1) = gnomeFactory.collectAllFees(address(this));
        totalClaimmedETH += totalAmount0;
        totalClaimmedGNOME += totalAmount1;

        // Fetch the leaderboard
        (uint256[] memory sortedTokenIds, , , , ) = gnomeGame.getRankedGnomes();

        // Example distribution logic
        uint256 totalParticipants = sortedTokenIds.length;

        // Define the reward distribution logic
        uint256 totalWeight = calculateTotalWeight(totalParticipants);

        // Distribute rewards based on rank
        for (uint256 i = 0; i < totalParticipants; i++) {
            // Higher rank (lower index) gets more, inversely proportional to their rank position + 1
            uint256 rankWeight = totalParticipants - i;
            uint256 rewardAmount0 = (totalAmount0 * rankWeight) / totalWeight;
            uint256 rewardAmount1 = (totalAmount1 * rankWeight) / totalWeight;

            // Placeholder for transferring rewards to the owners
            // You'll need to implement logic here to transfer `rewardAmount0` and `rewardAmount1`
            // to the owner of `sortedTokenIds[i]`
            // This might involve ERC20 token transfers or other mechanisms
        }

        lastClaimTime = block.timestamp;
        emit RewardsDistributed(totalAmount0, totalAmount1);
    }

    // Helper function to calculate the total weight
    // This is the sum of all rank weights, where rank weight decreases from totalParticipants to 1
    function calculateTotalWeight(uint256 totalParticipants) private pure returns (uint256) {
        return (totalParticipants * (totalParticipants + 1)) / 2;
    }

    function setPool(address _pool) public onlyOwner {
        pool = IUniswapV3Pool(_pool);
    }

    function setTwap(uint32 _twapInterval) public onlyOwner {
        twapInterval = twapInterval;
    }

    function _swapEthForTokens(uint value, bool isWETH) public payable returns (uint amountGnome, uint amountWeth) {
        if (!isWETH) {
            // Wrap ETH to WETH
            IWETH(WETH9).deposit{value: value}();
            assert(IWETH(WETH9).transfer(address(this), value));
        }

        uint amountToSwap = value;

        // Approve the router to spend WETH
        IWETH(WETH9).approve(address(swapRouter), type(uint256).max);

        // Set up swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: GNOME,
            fee: 10000, // Assuming a 0.1% pool fee
            recipient: address(this),
            amountIn: amountToSwap,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Perform the swap
        amountGnome = swapRouter.exactInputSingle(params);
    }

    function _swapTokensForWeth(uint value) public payable returns (uint amountGnome, uint amountWeth) {
        amountGnome = value;

        // Approve the router to spend WETH
        IWETH(GNOME).approve(address(swapRouter), amountGnome);

        // Set up swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: GNOME,
            tokenOut: WETH9,
            fee: 10000, // Assuming a 0.1% pool fee
            recipient: address(this),
            amountIn: amountGnome,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Perform the swap
        amountWeth = swapRouter.exactInputSingle(params);
    }

    function openRewards(bool _canClaim) public onlyOwner returns (bool) {
        canClaim = _canClaim;

        return true;
    }

    function frensFundus() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function somethingAboutTokens(address token) external onlyOwner {
        uint256 balance = IGNOME(token).balanceOf(address(this));
        IGNOME(token).transfer(msg.sender, balance);
    }

    function setMulDiv(uint256 _mul, uint256 _div) external onlyOwner {
        mul = _mul;
        div = _div;
    }

    function TokenPrice(address uniswapV3Pool, uint32 twapInterval) public view returns (uint256 price) {
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();

            uint256 amount0 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                FixedPoint96.Q96,
                sqrtPriceX96
            );

            uint256 amount1 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                sqrtPriceX96,
                FixedPoint96.Q96
            );
            price = (amount1 * mul) / (amount0 * div);
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int32(twapInterval)))
            );

            uint256 amount0 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                FixedPoint96.Q96,
                sqrtPriceX96
            );

            uint256 amount1 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                sqrtPriceX96,
                FixedPoint96.Q96
            );

            price = (amount1 * mul) / (amount0 * div);
        }
    }

    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Callback for IUniswapV3PoolActions#flash
/// @notice Any contract that calls IUniswapV3PoolActions#flash must implement this interface
interface IUniswapV3FlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from IUniswapV3Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#flash call
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {TickMath} from "./Utils/TickMath.sol";
import {FullMath, LiquidityAmounts} from "./Utils/LiquidityAmounts.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
pragma abicoder v2;
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

interface IUniswapV3Factory {
    function owner() external view returns (address);

    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
    function setOwner(address _owner) external;
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
}

interface IFACTORY {
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external returns (bool);
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
}

interface IMinimalNonfungiblePositionManager {
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    function mint(
        MintParams calldata params
    ) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    function burn(uint256 tokenId) external;

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}

interface IFren {
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint value) external returns (bool);
    function enableTrading() external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function initialize(uint160 sqrtPriceX96) external;
}

interface IGameContract {
    function applyHeal(address player) external;
    function applyProtect(address player) external;
}

contract MagicInternetCauldron is ERC4626Upgradeable, ReentrancyGuard {
    IMinimalNonfungiblePositionManager public positionManager;

    struct StakedPosition {
        uint256 tokenId;
        uint128 liquidity;
        uint256 stakedAt;
        uint256 lastRewardTime;
    }

    IUniswapV3Pool public pool;
    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public constant WETH_ADDRESS = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //BASE
    address public POSITION_MANAGER_ADDRESS = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88; // BASE
    mapping(address => bool) public isAuth;
    mapping(uint256 => address) public positionOwner;
    mapping(address => uint256) public frenReward;

    mapping(address => StakedPosition) public stakedPositions;
    address public MIMANA_ADDRESS;
    address public MIFREN_ADDRESS;

    int24 public tickSpacing = 200; // spacing of the miMana/ETH pool
    uint256 public SQRT_70_PERCENT = 836660026534075547; //
    uint256 public SQRT_130_PERCENT = 1140175425099137979; //
    uint160 public sqrtPriceLimitX96 = type(uint160).max;
    bool printerBrrr = false;
    uint256[] public stakedTokenIds;
    address public owner;
    int24 MinTick = -887200; // Replace with actual min tick for the pool
    int24 MaxTick = 887200; // Replace with actual max tick for the pool
    uint128 public totalStakedLiquidity;
    uint256 public dailyRewardAmount = 1 * 10 ** 18; // Daily reward amount in miMana tokens
    uint256 public initRewardTime;
    uint256 public constant HEAL_POTION_COST = 100;
    uint256 public constant PROTECT_POTION_COST = 200;
    IGameContract public gameContract;

    event PositionDeposited(uint256 indexed tokenId, address indexed from, address indexed to);

    constructor(address miFren, address miMana) {
        owner = msg.sender;
        isAuth[owner] = true;
        isAuth[address(this)] = true;
        MIMANA_ADDRESS = miMana;
        MIFREN_ADDRESS = miFren;
        positionManager = IMinimalNonfungiblePositionManager(POSITION_MANAGER_ADDRESS); // Base UniV3 Position Manager
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the authorized");
        _;
    }
    // Modifier to restrict access to owner only
    modifier onlyAuth() {
        require(msg.sender == owner || isAuth[msg.sender], "Caller is not the authorized");
        _;
    }

    function setSqrtPriceLimitX96(uint160 _sqrtPriceLimitX96) external onlyAuth {
        sqrtPriceLimitX96 = _sqrtPriceLimitX96;
    }

    function setIsAuth(address fren, bool isAuthorized) external onlyAuth {
        isAuth[fren] = isAuthorized;
    }

    function setMiContracts(address _mimana, address _mifrens) external onlyAuth {
        MIMANA_ADDRESS = _mimana;
        MIFREN_ADDRESS = _mifrens;
    }

    function setGameContract(address GameContract) public onlyOwner {
        gameContract = IGameContract(GameContract);
    }

    function setPool(address _pool) public onlyAuth {
        pool = IUniswapV3Pool(_pool);
    }

    function initRewards() public onlyAuth {
        initRewardTime = block.timestamp;
        printerBrrr = true;
    }

    function getPositionValue(
        uint256 tokenId
    ) public view returns (uint128 liquidity, address token0, address token1, int24 tickLower, int24 tickUpper) {
        (
            ,
            ,
            // nonce
            // operator
            address _token0, // token0
            address _token1, // token1 // fee
            ,
            int24 _tickLower, // tickLower
            int24 _tickUpper, // tickUpper
            uint128 _liquidity, // liquidity // feeGrowthInside0LastX128 // feeGrowthInside1LastX128 // tokensOwed0 // tokensOwed1
            ,
            ,
            ,

        ) = positionManager.positions(tokenId);

        return (_liquidity, _token0, _token1, _tickLower, _tickUpper);
    }

    function setDailyRewardAmount(uint256 _amount) external onlyOwner {
        dailyRewardAmount = _amount;
    }

    function stakePosition(uint256 tokenId) public nonReentrant {
        (uint128 liquidity, address token0, address token1, int24 tickLower, int24 tickUpper) = getPositionValue(
            tokenId
        );
        require(IFren(MIFREN_ADDRESS).balanceOf(msg.sender) > 0, "You need to own a Fren to stake");
        require(stakedPositions[msg.sender].tokenId == 0, "You Already have a staked position Fren");
        require(
            (token0 == MIMANA_ADDRESS && token1 == WETH_ADDRESS) ||
                (token0 == WETH_ADDRESS && token1 == MIMANA_ADDRESS),
            "Position does not involve the correct token pair"
        );
        require(liquidity > 0, "Invalid liquidity");
        require(tickLower == MinTick && tickUpper == MaxTick, "Position does not span full range");

        // Transfer the NFT to this contract for staking
        // Ensure the NFT contract supports safeTransferFrom and the sender is the NFT owner
        positionManager.safeTransferFrom(msg.sender, address(this), tokenId, "");

        positionOwner[tokenId] = msg.sender;
        stakedPositions[msg.sender] = StakedPosition(tokenId, liquidity, block.timestamp, block.timestamp);
        stakedTokenIds.push(tokenId); // Add the token ID to the array
        totalStakedLiquidity += liquidity;

        // Additional logic for reward calculation start
    }

    function withdrawPosition(uint256 tokenId) external nonReentrant {
        StakedPosition memory stakedPosition = stakedPositions[msg.sender];

        require(stakedPosition.tokenId == tokenId, "Not staked token");
        require(positionOwner[tokenId] == msg.sender, "Not position owner");

        // Transfer the NFT back to the user
        positionManager.safeTransferFrom(address(this), msg.sender, tokenId, "");

        totalStakedLiquidity -= stakedPosition.liquidity;
        // Clear the staked position data
        // Remove the tokenId from the stakedTokenIds array
        for (uint i = 0; i < stakedTokenIds.length; i++) {
            if (stakedTokenIds[i] == tokenId) {
                stakedTokenIds[i] = stakedTokenIds[stakedTokenIds.length - 1];
                stakedTokenIds.pop();
                break;
            }
        }
        delete positionOwner[tokenId];
        delete stakedPositions[msg.sender];
        removeTokenIdFromArray(tokenId);
    }

    function pendingInflactionaryRewards(address user) public view returns (uint256 rewards) {
        StakedPosition memory position = stakedPositions[user];

        if (position.liquidity == 0 || calculateSumOfLiquidity() == 0 || !printerBrrr) {
            return 0;
        }
        uint128 userLiq = position.liquidity;
        uint128 totalLiq = calculateSumOfLiquidity();
        uint256 _timeElapsed;
        if (position.lastRewardTime < initRewardTime) {
            _timeElapsed = block.timestamp - initRewardTime;
        } else {
            _timeElapsed = block.timestamp - position.lastRewardTime;
        }

        uint128 userShare = div64x64(userLiq, totalLiq);

        rewards = (dailyRewardAmount * _timeElapsed * userShare) / 1e18;
    }

    function pendingRewards(address user) public view returns (uint256 rewards) {
        rewards = frenReward[user] + pendingInflactionaryRewards(user);
    }

    function div64x64(uint128 x, uint128 y) internal pure returns (uint128) {
        unchecked {
            require(y != 0);

            uint256 answer = (uint256(x) << 64) / y;

            require(answer <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(answer);
        }
    }

    function claimRewards() public nonReentrant {
        StakedPosition storage position = stakedPositions[msg.sender];
        require(isCauldronInRange(msg.sender), "Rebalance the fire in your Cauldron");

        // Add pending inflationary rewards to rewards
        uint256 rewards = pendingInflactionaryRewards(msg.sender) + frenReward[msg.sender];

        require(rewards > 0, "No rewards available");

        // Set frenReward[msg.sender] to zero
        frenReward[msg.sender] = 0;

        position.lastRewardTime = block.timestamp; // Update the last reward time

        // Transfer miMana tokens to the user
        // Ensure that the contract has enough miMana tokens and is authorized to distribute them
        require(IFren(MIMANA_ADDRESS).balanceOf(address(this)) >= rewards, "No more $miMana to give");

        IFren(MIMANA_ADDRESS).transfer(msg.sender, rewards);

        // Emit an event if necessary
        // emit RewardsClaimed(msg.sender, rewards);
    }

    function claimRewardsAuth(address fren, uint256 itemPrice) public onlyAuth nonReentrant {
        StakedPosition storage position = stakedPositions[fren];
        require(isCauldronInRange(fren), "Rebalance the fire in your Cauldron");

        // Add pending inflationary rewards to rewards
        uint256 rewards = pendingInflactionaryRewards(fren) + frenReward[fren] - itemPrice;

        require(rewards > 0, "No rewards available");

        // Set frenReward[msg.sender] to zero
        frenReward[fren] = 0;

        position.lastRewardTime = block.timestamp; // Update the last reward time

        // Transfer miMana tokens to the user
        // Ensure that the contract has enough miMana tokens and is authorized to distribute them
        require(IFren(MIMANA_ADDRESS).balanceOf(address(this)) >= rewards, "No more $miMana to give");

        IFren(MIMANA_ADDRESS).transfer(fren, rewards);

        // Emit an event if necessary
        // emit RewardsClaimed(msg.sender, rewards);
    }

    function drinkHealPotion() public nonReentrant {
        consumePotion(HEAL_POTION_COST);
    }

    function drinkProtectPotion() public nonReentrant {
        consumePotion(PROTECT_POTION_COST);
    }

    function consumePotion(uint256 potionCost) private {
        StakedPosition storage position = stakedPositions[msg.sender];
        require(position.tokenId != 0, "No staked position");
        uint256 rewards;
        if (printerBrrr) {
            rewards = pendingInflactionaryRewards(msg.sender);
        } else {
            rewards = pendingRewards(msg.sender);
        }

        require(rewards >= potionCost, "Insufficient rewards to drink potion");

        position.lastRewardTime = block.timestamp; // Update the last reward time

        uint256 remainingRewards = rewards - potionCost;
        // Transfer remaining rewards to the user
        // miManaToken.transfer(msg.sender, remainingRewards);
        require(IFren(MIMANA_ADDRESS).balanceOf(address(this)) > remainingRewards, "No more $miMana to give");

        IFren(MIMANA_ADDRESS).transfer(msg.sender, remainingRewards);
        // Emit an event for drinking the potion
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes memory) public virtual returns (bytes4) {
        emit PositionDeposited(tokenId, from, address(this));
        return this.onERC721Received.selector;
    }

    function collectAllFees() external returns (uint256 totalAmount0, uint256 totalAmount1) {
        uint256 amount0;
        uint256 amount1;

        for (uint i = 0; i < stakedTokenIds.length; i++) {
            IMinimalNonfungiblePositionManager.CollectParams memory params = IMinimalNonfungiblePositionManager
                .CollectParams({
                    tokenId: stakedTokenIds[i],
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                });

            (amount0, amount1) = positionManager.collect(params);
            totalAmount0 += amount0;
            totalAmount1 += amount1;
        }
    }

    function frensFundus() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function somethingAboutTokens(address token) external onlyOwner {
        uint256 balance = IFren(token).balanceOf(address(this));
        IFren(token).transfer(msg.sender, balance);
    }

    function swapWETH(uint value) public payable returns (uint amountOut) {
        // Approve the router to spend WETH
        IWETH(WETH_ADDRESS).approve(address(swapRouter), value);

        // Set up swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH_ADDRESS,
            tokenOut: MIMANA_ADDRESS,
            fee: 10000, // Assuming a 0.1% pool fee
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: value,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Perform the swap
        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapETH_Half(uint value, bool isWETH) public payable returns (uint amountMana, uint amountWeth) {
        if (!isWETH) {
            // Wrap ETH to WETH
            IWETH(WETH_ADDRESS).deposit{value: value}();
            assert(IWETH(WETH_ADDRESS).transfer(address(this), value));
        }

        uint amountToSwap = value / 2;

        // Approve the router to spend WETH
        IWETH(WETH_ADDRESS).approve(address(pool), value);

        // Set up swap parameters
        /* ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH_ADDRESS,
            tokenOut: MIMANA_ADDRESS,
            fee: 10000, // Assuming a 0.1% pool fee
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountToSwap,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });*/

        // Perform the swap
        (int256 amount0, int256 amount1) = pool.swap(address(this), false, int256(amountToSwap), sqrtPriceLimitX96, "");
        amountMana = uint(amount0);
        amountWeth = uint(amount1);
    }

    function brewManaFromETH()
        public
        payable
        returns (uint _tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund0, uint refund1)
    {
        require(msg.value > 0, "Must send ETH to the Cauldron");

        (uint amountMana, uint amountWeth) = swapETH_Half(msg.value, false);

        uint amountWETH = IWETH(WETH_ADDRESS).balanceOf(address(this));

        // For this example, we will provide equal amounts of liquidity in both assets.
        // Providing liquidity in both assets means liquidity will be earning fees and is considered in-range.
        uint amount0ToMint = amountMana;
        uint amount1ToMint = amountWETH;

        // Approve the position manager
        TransferHelper.safeApprove(MIMANA_ADDRESS, address(POSITION_MANAGER_ADDRESS), amount0ToMint);
        TransferHelper.safeApprove(WETH_ADDRESS, address(POSITION_MANAGER_ADDRESS), amount1ToMint);

        if (stakedPositions[msg.sender].tokenId != 0) {
            // User already has a staked position, call function to increase liquidity
            return increasePosition(msg.sender, amountMana, amountWETH);
        } else {
            // User does not have a staked position, proceed with minting a new one
            return mintPosition(msg.sender, msg.sender, amountMana, amountWETH);
        }
    }

    function brewManaFromMANA_ETH(
        uint _amountMana
    )
        public
        payable
        returns (uint _tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund0, uint refund1)
    {
        require(msg.value > 0, "Must send ETH to the Cauldron");

        // Wrap ETH to WETH
        IWETH(WETH_ADDRESS).deposit{value: msg.value}();
        assert(IWETH(WETH_ADDRESS).transfer(address(this), msg.value));

        uint amountWETH = IWETH(WETH_ADDRESS).balanceOf(address(this));
        IFren(MIMANA_ADDRESS).transferFrom(msg.sender, address(this), _amountMana);
        // For this example, we will provide equal amounts of liquidity in both assets.
        // Providing liquidity in both assets means liquidity will be earning fees and is considered in-range.
        uint amount0ToMint = _amountMana;
        uint amount1ToMint = msg.value;

        // Approve the position manager
        TransferHelper.safeApprove(MIMANA_ADDRESS, address(POSITION_MANAGER_ADDRESS), amount0ToMint);
        TransferHelper.safeApprove(WETH_ADDRESS, address(POSITION_MANAGER_ADDRESS), amount1ToMint);

        if (stakedPositions[msg.sender].tokenId != 0) {
            // User already has a staked position, call function to increase liquidity
            return increasePosition(msg.sender, _amountMana, amountWETH);
        } else {
            // User does not have a staked position, proceed with minting a new one
            return mintPosition(msg.sender, msg.sender, _amountMana, amountWETH);
        }
    }

    function isCauldronInRange(address fren) public view returns (bool) {
        int24 tick = getCurrentTick();
        StakedPosition memory position = stakedPositions[fren];
        (, , , int24 minTick, int24 maxTick) = getPositionValue(position.tokenId);

        if (minTick < tick && tick < maxTick) {
            return true;
        } else {
            return false;
        }
    }

    function getCurrentTick() public view returns (int24) {
        (, int24 tick, , , , , ) = pool.slot0();
        return tick;
    }

    function swapMana_Half(uint value) public payable returns (uint amountMana, uint amountWeth) {
        uint amountToSwap = value / 2;

        // Approve the router to spend WETH
        IFren(MIMANA_ADDRESS).approve(address(swapRouter), value);

        // Set up swap parameters
        /*  ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: MIMANA_ADDRESS,
            tokenOut: WETH_ADDRESS,
            fee: 10000, // Assuming a 0.3% pool fee
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountToSwap,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
*/
        // Perform the swap
        //amountOut = swapRouter.exactInputSingle(params);
        (int256 amount0, int256 amount1) = pool.swap(address(this), true, int256(amountToSwap), 0, "");
        amountMana = uint(amount0);
        amountWeth = uint(amount1);
    }

    function mintCauldron(
        address fren,
        address rafundAddress,
        uint _amountMana,
        uint _amountWETH
    ) external returns (uint _tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund1, uint refund0) {
        return mintPosition(fren, rafundAddress, _amountMana, _amountWETH);
    }

    function mintPosition(
        address fren,
        address rafundAddress,
        uint _amountMana,
        uint _amountWETH
    ) internal returns (uint _tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund1, uint refund0) {
        uint256 _deadline = block.timestamp + 3360;
        (int24 lowerTick, int24 upperTick) = _getSpreadTicks();
        IMinimalNonfungiblePositionManager.MintParams memory params = IMinimalNonfungiblePositionManager.MintParams({
            token0: MIMANA_ADDRESS,
            token1: WETH_ADDRESS,
            fee: 10000,
            // By using TickMath.MIN_TICK and TickMath.MAX_TICK,
            // we are providing liquidity across the whole range of the pool.
            // Not recommended in production.
            tickLower: lowerTick,
            tickUpper: upperTick,
            amount0Desired: _amountMana,
            amount1Desired: _amountWETH,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: _deadline
        });

        // Note that the pool defined by miMana/WETH and fee tier 0.1% must
        // already be created and initialized in order to mint
        (_tokenId, liquidity, amount0, amount1) = positionManager.mint(params);
        positionOwner[_tokenId] = fren;

        stakedPositions[fren] = StakedPosition(_tokenId, liquidity, block.timestamp, block.timestamp);
        stakedTokenIds.push(_tokenId); // Add the token ID to the array
        totalStakedLiquidity += liquidity;

        if (amount0 < _amountMana) {
            refund0 = _amountMana - amount0;
            //TransferHelper.safeTransfer(MIMANA_ADDRESS, rafundAddress, refund0);
            frenReward[rafundAddress] += refund0;
        }

        if (amount1 < _amountWETH) {
            refund1 = _amountWETH - amount1;
            TransferHelper.safeTransfer(WETH_ADDRESS, rafundAddress, refund1);
            // uint256 amountMana = swapWETH(refund1);
            //TransferHelper.safeTransfer(MIMANA_ADDRESS, rafundAddress, amountMana);
            //frenReward[rafundAddress] += amountMana;
        }
    }

    function rebalancePosition(address fren) public returns (uint _refund0, uint _refund1) {
        return _rebalancePosition(fren, fren);
    }

    function _rebalancePosition(address fren, address refund) public returns (uint _refund0, uint _refund1) {
        // require(msg.sender == owner || isAuth[msg.sender] || fren == tx.origin, "Caller is not the authorized");
        if (!isCauldronInRange(fren)) {
            StakedPosition storage position = stakedPositions[fren];
            uint256 oldTokenID = position.tokenId;
            int24 currentTick = getCurrentTick();
            (, , , int24 minTick, int24 maxTick) = getPositionValue(position.tokenId);

            // Determine if the current price is above or below the range
            if (currentTick > maxTick) {
                // Decrease the entire position, assuming all liquidity is in WETH

                // Swap half of the WETH to another asset and then mint a new position
                uint amountWETHBeforeSwap = IWETH(WETH_ADDRESS).balanceOf(address(this));
                (, uint amountWeth) = _decreaseLiquidity(position.liquidity, fren, address(this));

                (uint _amountMana, ) = swapETH_Half(amountWeth, true);
                uint amountWETHAfterSwap = IWETH(WETH_ADDRESS).balanceOf(address(this));
                uint amountWethADD = amountWETHAfterSwap - amountWETHBeforeSwap;

                TransferHelper.safeApprove(MIMANA_ADDRESS, address(POSITION_MANAGER_ADDRESS), _amountMana);
                TransferHelper.safeApprove(WETH_ADDRESS, address(POSITION_MANAGER_ADDRESS), amountWethADD);
                (, , , , _refund0, _refund1) = mintPosition(fren, refund, _amountMana, amountWethADD);
            } else if (currentTick < minTick) {
                uint amountManaBeforeSwap = IWETH(WETH_ADDRESS).balanceOf(address(this));
                (uint amountMana, ) = _decreaseLiquidity(position.liquidity, fren, address(this));

                (, uint _amountWeth) = swapMana_Half(amountMana);
                uint amountManaAfterSwap = IWETH(WETH_ADDRESS).balanceOf(address(this));
                uint amountManaADD = amountManaAfterSwap - amountManaBeforeSwap;

                TransferHelper.safeApprove(MIMANA_ADDRESS, address(POSITION_MANAGER_ADDRESS), amountManaADD);
                TransferHelper.safeApprove(WETH_ADDRESS, address(POSITION_MANAGER_ADDRESS), _amountWeth);
                (, , , , _refund0, _refund1) = mintPosition(fren, refund, amountManaADD, _amountWeth);
            }
        }
    }

    function calculateSumOfLiquidity() public view returns (uint128) {
        uint128 totalLiq = 0;

        for (uint256 i = 0; i < stakedTokenIds.length; i++) {
            uint256 tokenId = stakedTokenIds[i];
            address fren = positionOwner[tokenId];

            // Check if the position owner satisfies the condition
            if (isCauldronInRange(fren)) {
                StakedPosition storage position = stakedPositions[fren];

                // Add up the liquidity
                totalLiq += position.liquidity;
            }
        }

        return totalLiq;
    }

    function increasePosition(
        address fren,
        uint _amountMana,
        uint _amountWETH
    ) internal returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund0, uint refund1) {
        tokenId = stakedPositions[fren].tokenId;

        uint256 _deadline = block.timestamp + 100;
        IMinimalNonfungiblePositionManager.IncreaseLiquidityParams memory params = IMinimalNonfungiblePositionManager
            .IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: _amountMana,
                amount1Desired: _amountWETH,
                amount0Min: 0,
                amount1Min: 0,
                deadline: _deadline
            });

        (liquidity, amount0, amount1) = positionManager.increaseLiquidity(params);
        uint128 curr_liquidity = stakedPositions[msg.sender].liquidity + liquidity;

        stakedPositions[msg.sender] = StakedPosition(tokenId, curr_liquidity, block.timestamp, block.timestamp);
        stakedTokenIds.push(tokenId); // Add the token ID to the array
        totalStakedLiquidity += liquidity;

        if (amount0 < _amountMana) {
            refund0 = _amountMana - amount0;
            TransferHelper.safeTransfer(MIMANA_ADDRESS, fren, refund0);
        }

        if (amount1 < _amountWETH) {
            refund1 = _amountWETH - amount1;
            TransferHelper.safeTransfer(WETH_ADDRESS, fren, refund1);
        }
    }

    function removeTokenIdFromArray(uint256 tokenId) internal {
        uint256 length = stakedTokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (stakedTokenIds[i] == tokenId) {
                // Swap with the last element
                stakedTokenIds[i] = stakedTokenIds[length - 1];
                // Remove the last element
                stakedTokenIds.pop();
                break;
            }
        }
    }

    function _getStakedPositionID(address fren) public view returns (uint256 tokenId) {
        StakedPosition memory position = stakedPositions[fren];
        return position.tokenId;
    }

    function _getSpreadTicks() public view returns (int24 _lowerTick, int24 _upperTick) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        (uint160 sqrtRatioAX96, uint160 sqrtRatioBX96) = (
            uint160(FullMath.mulDiv(sqrtPriceX96, SQRT_70_PERCENT, 1e18)),
            uint160(FullMath.mulDiv(sqrtPriceX96, SQRT_130_PERCENT, 1e18))
        );

        _lowerTick = TickMath.getTickAtSqrtRatio(sqrtRatioAX96);
        _upperTick = TickMath.getTickAtSqrtRatio(sqrtRatioBX96);

        _lowerTick = _lowerTick % tickSpacing == 0
            ? _lowerTick // accept valid tickSpacing
            : _lowerTick > 0 // else, round up to closest valid tickSpacing
            ? (_lowerTick / tickSpacing + 1) * tickSpacing
            : (_lowerTick / tickSpacing) * tickSpacing;
        _upperTick = _upperTick % tickSpacing == 0
            ? _upperTick // accept valid tickSpacing
            : _upperTick > 0 // else, round down to closest valid tickSpacing
            ? (_upperTick / tickSpacing) * tickSpacing
            : (_upperTick / tickSpacing - 1) * tickSpacing;
    }

    function decreaseLiquidity(uint128 liquidity, address fren) public returns (uint amount0, uint amount1) {
        return _decreaseLiquidity(liquidity, fren, fren);
    }

    function _decreaseLiquidity(
        uint128 liquidity,
        address fren,
        address receiver
    ) internal returns (uint amount0, uint amount1) {
        //require(msg.sender == owner || isAuth[msg.sender] || tx.origin == fren, "Caller is not the authorized");
        require(stakedPositions[fren].tokenId != 0, "No positions in Cauldron");
        uint256 tokenId = stakedPositions[fren].tokenId;
        uint128 currentLiquidity = stakedPositions[fren].liquidity;
        require(currentLiquidity >= liquidity, "Not Enough Liquidity in your Cauldron");
        uint128 newliq = currentLiquidity - liquidity;
        IMinimalNonfungiblePositionManager.DecreaseLiquidityParams memory params = IMinimalNonfungiblePositionManager
            .DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });
        totalStakedLiquidity -= liquidity;
        uint amountManaBefore = IWETH(MIMANA_ADDRESS).balanceOf(address(this));
        uint amountWETHBefore = IWETH(WETH_ADDRESS).balanceOf(address(this));
        stakedPositions[fren] = StakedPosition(tokenId, newliq, block.timestamp, block.timestamp);
        (amount0, amount1) = positionManager.decreaseLiquidity(params);
        IMinimalNonfungiblePositionManager.CollectParams memory colectparams = IMinimalNonfungiblePositionManager
            .CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = positionManager.collect(colectparams);
        uint amountManaAfter = IWETH(MIMANA_ADDRESS).balanceOf(address(this));
        uint amountWETHAfter = IWETH(WETH_ADDRESS).balanceOf(address(this));
        uint refund0 = amountManaAfter - amountManaBefore;
        uint refund1 = amountWETHAfter - amountWETHBefore;

        if (refund0 > 0) {
            TransferHelper.safeTransfer(MIMANA_ADDRESS, receiver, refund0);
        }

        if (refund1 > 0) {
            //IERC20(WETH_ADDRESS).approve(address(this), refund1);
            //IWETH(WETH_ADDRESS).withdraw(refund1);
            //payable(receiver).transfer(refund1);
            TransferHelper.safeTransfer(WETH_ADDRESS, receiver, refund1);
        }

        if (newliq == 0) {
            positionManager.burn(stakedPositions[fren].tokenId);
            delete positionOwner[stakedPositions[fren].tokenId];
            removeTokenIdFromArray(stakedPositions[fren].tokenId);
            delete stakedPositions[fren];
        }
    }

    function _decreaseLiquidityExternal(
        uint128 liquidity,
        address fren,
        address receiver
    ) external returns (uint amount0, uint amount1) {
        require(msg.sender == owner || isAuth[msg.sender] || tx.origin == fren, "Caller is not the authorized");
        require(stakedPositions[fren].tokenId != 0, "No positions in Cauldron");
        uint256 tokenId = stakedPositions[fren].tokenId;
        uint128 currentLiquidity = stakedPositions[fren].liquidity;
        require(currentLiquidity >= liquidity, "Not Enough Liquidity in your Cauldron");
        uint128 newliq = currentLiquidity - liquidity;
        IMinimalNonfungiblePositionManager.DecreaseLiquidityParams memory params = IMinimalNonfungiblePositionManager
            .DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });
        totalStakedLiquidity -= liquidity;
        uint amountManaBefore = IWETH(MIMANA_ADDRESS).balanceOf(address(this));
        uint amountWETHBefore = IWETH(WETH_ADDRESS).balanceOf(address(this));
        stakedPositions[fren] = StakedPosition(tokenId, newliq, block.timestamp, block.timestamp);
        (amount0, amount1) = positionManager.decreaseLiquidity(params);
        IMinimalNonfungiblePositionManager.CollectParams memory colectparams = IMinimalNonfungiblePositionManager
            .CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = positionManager.collect(colectparams);
        uint amountManaAfter = IWETH(MIMANA_ADDRESS).balanceOf(address(this));
        uint amountWETHAfter = IWETH(WETH_ADDRESS).balanceOf(address(this));
        uint refund0 = amountManaAfter - amountManaBefore;
        uint refund1 = amountWETHAfter - amountWETHBefore;

        if (refund0 > 0) {
            TransferHelper.safeTransfer(MIMANA_ADDRESS, receiver, refund0);
        }

        if (refund1 > 0) {
            //IERC20(WETH_ADDRESS).approve(address(this), refund1);
            //IWETH(WETH_ADDRESS).withdraw(refund1);
            //payable(receiver).transfer(refund1);
            TransferHelper.safeTransfer(WETH_ADDRESS, receiver, refund1);
        }

        if (newliq == 0) {
            positionManager.burn(stakedPositions[fren].tokenId);
            delete positionOwner[stakedPositions[fren].tokenId];
            removeTokenIdFromArray(stakedPositions[fren].tokenId);
            delete stakedPositions[fren];
        }
    }

    function setTicks(int24 _minTick, int24 _maxTick, int24 _tickSpacing) public onlyOwner {
        MaxTick = _maxTick;
        MinTick = _minTick;
        tickSpacing = _tickSpacing;
    }

    function uniswapV3SwapCallback(int256 amount0, int256 amount1, bytes calldata data) external {
        //CallbackValidation.verifyCallback(factory, tokenIn, tokenOut, fee);
    }
}

/*





*/ // SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MiMana is ERC20 {
    address public admin;

    uint256 public constant maxSupply = 108_000_000e18;
    uint256 public maxTradeAmount = 1000e18;
    uint256 public maxWalletSize = 1100e18;
    mapping(address => bool) public isAuth;
    mapping(address => bool) public isWhitelisted;
    address public frenRewarder;
    address public uniswapV3pool;
    address public uniswapV3positionManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    uint256 public startTimestamp;
    bool public isLimit = true;

    mapping(uint256 => bool) public isRewardMinted;

    constructor(address admin_) ERC20("GnomeLand", "GNOME") {
        admin = admin_;

        _mint(admin, 72_000_000e18);
    }

    modifier onlyAuth() {
        require(msg.sender == admin || isAuth[msg.sender], "Caller is not the authorized");
        _;
    }

    function setIsAuth(address fren, bool isAuthorized) external onlyAuth {
        isAuth[fren] = isAuthorized;
    }

    function setPool(address _pool) external onlyAuth {
        uniswapV3pool = _pool;
    }

    function setMaxWallet(uint256 newMaxWalletSize) external onlyAuth {
        require(newMaxWalletSize > maxWalletSize, "New max wallet size must be greater than current size");
        maxWalletSize = newMaxWalletSize;
    }

    function removeLimits() external onlyAuth {
        isLimit = false;
    }

    function increaseMaxTradeAmount(uint256 newMaxTradeAmount) external onlyAuth {
        require(newMaxTradeAmount >= maxTradeAmount, "Cannot decrease max trade amount");
        maxTradeAmount = newMaxTradeAmount;
    }

    function initialize(address frenRewarder_, uint256 startTimestamp_) external {
        require(msg.sender == admin, "ONLY ADMIN");
        require(frenRewarder_ != address(0) && startTimestamp_ > block.timestamp, "BAD PARAMS");

        frenRewarder = frenRewarder_;
        startTimestamp = startTimestamp_;

        _approve(address(this), frenRewarder, maxSupply - totalSupply());

        admin = address(0);
    }

    function whitelistAddress(address wallet, bool isWhitelisted_) external onlyAuth {
        isWhitelisted[wallet] = isWhitelisted_;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (isLimit) {
            require(amount <= maxTradeAmount, "Exceeds max trade amount");
            if (to != uniswapV3pool) {
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds max wallet size");
            }

            super.transfer(to, amount);

            return true;
        }
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (isLimit) {
            require(amount <= maxTradeAmount, "Exceeds max trade amount");
            if (to != uniswapV3pool || to != uniswapV3pool) {
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds max wallet size");
            }
            super.transferFrom(from, to, amount);

            return true;
        }
        return super.transferFrom(from, to, amount);
    }

    function getGnomeRewardAmount(uint256 day) public view returns (uint256) {
        if (day < 21) return 96396396396396300000000;
        if (day < 21 * 2) return 63963963963963000000000;
        if (day < 21 * 3) return 39639639639630000000000;
        if (day < 21 * 4) return 9639639639639630000000;
        if (maxSupply - totalSupply() < 96396396396396300000000) return maxSupply - totalSupply();
        return 0;
    }

    function fillGnomeRewarder(uint256 day) external {
        require(block.timestamp >= startTimestamp, "NOT STARTED");
        require(startTimestamp + day * 1 days < block.timestamp, "NOT REACHED DAY");

        if (!isRewardMinted[day]) {
            isRewardMinted[day] = true;

            uint256 amount = getGnomeRewardAmount(day);
            if (amount > 0) {
                _mint(admin, amount);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // EDIT for 0.8 compatibility:
            // see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
            uint256 twos = denominator & (~denominator + 1);

            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import { FullMath } from "./FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate =
            FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount0,
                    intermediate,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount1,
                    FixedPoint96.Q96,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 =
                getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 =
                getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount1
            );
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                liquidity,
                sqrtRatioBX96 - sqrtRatioAX96,
                FixedPoint96.Q96
            );
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(
                sqrtRatioX96,
                sqrtRatioBX96,
                liquidity
            );
            amount1 = getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioX96,
                liquidity
            );
        } else {
            amount1 = getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        uint256 absTick =
            tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));

        // EDIT: 0.8 compatibility
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio =
            absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96)
        internal
        pure
        returns (int24 tick)
    {
        // second inequality must be < because the price can never reach the price at the max tick
        require(
            sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO,
            "R"
        );
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow =
            int24(
                (log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
            );
        int24 tickHi =
            int24(
                (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
            );

        tick = tickLow == tickHi
            ? tickLow
            : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: MIT
/*





 */
pragma solidity ^0.8.20;
import {TickMath} from "./Utils/TickMath.sol";
import {FullMath, LiquidityAmounts} from "./Utils/LiquidityAmounts.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
pragma abicoder v2;
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

interface IUniswapV3Factory {
    function owner() external view returns (address);

    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
    function setOwner(address _owner) external;
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
}

interface IFACTORY {
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external returns (bool);
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
}

interface IMinimalNonfungiblePositionManager {
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    function mint(
        MintParams calldata params
    ) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    function burn(uint256 tokenId) external;

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}

interface IGNOME {
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint value) external returns (bool);
    function enableTrading() external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function initialize(uint160 sqrtPriceX96) external;
    function getTokenId() external view returns (uint256);
    function factoryMint(address fren) external returns (uint256);
    function signUpReferral(string memory code, address sender, uint gnomeAmount) external;
    function signUp(uint256 _id, string memory _Xusr) external;
    function setTreasuryMintTimeStamp(address gnome, uint256 timeStamp) external;
    function setGnomeEmotion(uint256 tokenId, uint256 _gnomeEmotion) external;
}

contract SwapTest is ReentrancyGuard {
    IMinimalNonfungiblePositionManager private positionManager;

    struct StakedPosition {
        uint256 tokenId;
        uint128 liquidity;
        uint256 stakedAt;
        uint256 lastRewardTime;
    }

    IUniswapV3Pool private pool;
    ISwapRouter private constant swapRouter = ISwapRouter(0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E);
    address private constant WETH_ADDRESS = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address private POSITION_MANAGER_ADDRESS = 0x1238536071E1c677A632429e3655c799b22cDA52;
    mapping(address => bool) public isAuth;

    mapping(address => uint256) public gnomeReward;
    mapping(address => uint256) public gameReward;

    mapping(address => StakedPosition) public stakedPositions;
    address public GNOME_ADDRESS = 0xB5729c31087966d6Db80971FB7734a2C63CE4aA6;
    address public GNOME_REFERRAL;
    address public GNOME_NFT_ADDRESS;
    address public GNOME_GAME_ADDRESS;
    address public GNOME_NFT_POOL;
    address public GNOME_POOL;
    int24 public tickSpacing = 200; // spacing of the gnome/ETH pool

    uint256 private SQRT_0005_PERCENT = 223606797784075547; //
    uint256 private SQRT_2000_PERCENT = 4472135955099137979; //
    uint256 private positionIndex = 0; //
    mapping(uint256 => uint256) public positionByIndex;
    uint160 private sqrtPriceLimitX96 = type(uint160).max;
    uint256 public treasuryDiscount = 86;
    uint256 public referralDiscount = 66;
    bool private printerBrrr = false;
    bool private mintOpened = false;
    bool private mintReferral = false;
    bool private communityOwned = false;
    uint256[] public stakedTokenIds;
    address public owner;
    uint32 _twapInterval = 0;
    bool canWithdraw = false;
    bool nftPoolWeth = true;
    int24 MinTick = -887200; // Replace with actual min tick for the pool
    int24 MaxTick = 887200; // Replace with actual max tick for the pool
    uint128 public totalStakedLiquidity;
    uint256 public dailyRewardAmount = 1 * 10 ** 18; // Daily reward amount in gnome tokens
    uint256 private initRewardTime;
    uint256 private mul = 10 ** 8;
    uint256 private div = 1;
    uint256 private treasuryDelay = 5 minutes; //CHANGE THIS

    constructor() {
        owner = msg.sender;
        isAuth[owner] = true;
        isAuth[address(this)] = true;

        positionManager = IMinimalNonfungiblePositionManager(POSITION_MANAGER_ADDRESS); //
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the authorized");
        _;
    }
    // Modifier to restrict access to owner only
    modifier onlyAuth() {
        require(msg.sender == owner || isAuth[msg.sender], "Caller is not the authorized");
        _;
    }

    function setSqrtPriceLimitX96(uint160 _sqrtPriceLimitX96) external onlyAuth {
        sqrtPriceLimitX96 = _sqrtPriceLimitX96;
    }

    function setMulDiv(uint256 _mul, uint256 _div) external onlyAuth {
        mul = _mul;
        div = _div;
    }

    function setIsCommunityOwned(bool _communityOwned) external onlyAuth {
        communityOwned = _communityOwned;
    }

    function openMint(bool _mintOpened) external onlyAuth {
        mintOpened = _mintOpened;
    }

    function openReferral(bool _mintOpened) external onlyAuth {
        mintReferral = _mintOpened;
    }

    function setIsCommunityWithdraw(bool _canWithdraw) external onlyAuth {
        canWithdraw = _canWithdraw;
    }

    function setIsAuth(address fren, bool isAuthorized) external onlyAuth {
        isAuth[fren] = isAuthorized;
    }

    function setPool741(address _gnomePool404) external onlyAuth {
        require(_gnomePool404 != address(0), "Invalid Pool address");

        GNOME_NFT_POOL = _gnomePool404;
    }

    function setMiContracts(
        address _gnome,
        address _gnomeNFT,
        address _gnomeReferral,
        address _gnomeGame
    ) external onlyAuth {
        require(_gnome != address(0), "Invalid GNOME address");
        require(_gnomeNFT != address(0), "Invalid GNOME NFT address");
        require(_gnomeReferral != address(0), "Invalid GNOME Referral address");
        require(_gnomeGame != address(0), "Invalid GNOME Game address");
        GNOME_ADDRESS = _gnome;
        GNOME_NFT_ADDRESS = _gnomeNFT;
        GNOME_REFERRAL = _gnomeReferral;
        GNOME_GAME_ADDRESS = _gnomeGame;
    }

    function setPool(address _pool) public onlyAuth {
        GNOME_POOL = _pool;
        pool = IUniswapV3Pool(_pool);
    }

    function initRewards() public onlyAuth {
        initRewardTime = block.timestamp;
        printerBrrr = true;
    }

    function getPositionValue(
        uint256 tokenId
    ) public view returns (uint128 liquidity, address token0, address token1, int24 tickLower, int24 tickUpper) {
        (
            ,
            ,
            // nonce
            // operator
            address _token0, // token0
            address _token1, // token1 // fee
            ,
            int24 _tickLower, // tickLower
            int24 _tickUpper, // tickUpper
            uint128 _liquidity, // liquidity // feeGrowthInside0LastX128 // feeGrowthInside1LastX128 // tokensOwed0 // tokensOwed1
            ,
            ,
            ,

        ) = positionManager.positions(tokenId);

        return (_liquidity, _token0, _token1, _tickLower, _tickUpper);
    }

    function setDailyRewardAmount(uint256 _amount) external onlyOwner {
        dailyRewardAmount = _amount;
    }

    function div64x64(uint128 x, uint128 y) internal pure returns (uint128) {
        unchecked {
            require(y != 0);

            uint256 answer = (uint256(x) << 64) / y;

            require(answer <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(answer);
        }
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function collectAllFees() external returns (uint256 totalAmount0, uint256 totalAmount1) {
        uint256 amount0;
        uint256 amount1;

        for (uint i = 0; i < stakedTokenIds.length; i++) {
            IMinimalNonfungiblePositionManager.CollectParams memory params = IMinimalNonfungiblePositionManager
                .CollectParams({
                    tokenId: stakedTokenIds[i],
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                });

            (amount0, amount1) = positionManager.collect(params);
            totalAmount0 += amount0;
            totalAmount1 += amount1;
        }
    }

    function frensFundus() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function setDiscounts(uint256 _treasuryDiscount, uint256 _referralDiscount) external onlyAuth {
        treasuryDiscount = _treasuryDiscount;
        referralDiscount = _referralDiscount;
    }

    function somethingAboutTokens(address token) external onlyOwner {
        uint256 balance = IGNOME(token).balanceOf(address(this));
        IGNOME(token).transfer(msg.sender, balance);
    }

    function swapWETH(uint value) public payable returns (uint amountOut) {
        // Approve the router to spend WETH
        IWETH(WETH_ADDRESS).approve(address(swapRouter), value);

        // Set up swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH_ADDRESS,
            tokenOut: GNOME_ADDRESS,
            fee: 10000, // Assuming a 0.1% pool fee
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: value,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Perform the swap
        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapETH_Half(uint value, bool isWETH) public payable returns (uint amountGnome, uint amountWeth) {
        if (!isWETH) {
            // Wrap ETH to WETH
            IWETH(WETH_ADDRESS).deposit{value: msg.value}();
            assert(IWETH(WETH_ADDRESS).transfer(address(this), msg.value));
        }

        uint amountToSwap = msg.value / 2;

        // Approve the router to spend WETH
        IWETH(WETH_ADDRESS).approve(address(swapRouter), msg.value);

        // Set up swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH_ADDRESS,
            tokenOut: GNOME_ADDRESS,
            fee: 10000, // Assuming a 0.1% pool fee
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountToSwap,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Perform the swap
        amountGnome = swapRouter.exactInputSingle(params);
    }

    function mintGnome(
        string memory userX,
        uint256 baseEmotion
    )
        public
        payable
        returns (uint _tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund0, uint refund1)
    {
        require(msg.value >= getGnomeNFTPrice(), "Not Enough to mint Gnome");
        if (!isAuth[msg.sender]) {
            require(mintOpened, "Minting Not Opened to Public");
        }
        // uint numberOfGnomes = msg.value / (getGnomeNFTPrice()); // 1 Gnome costs 0.0333 ETH
        uint amountWETHBefore = IWETH(WETH_ADDRESS).balanceOf(address(this));
        (uint amountGnome, uint amountWeth) = swapETH_Half(msg.value, false);
        uint amountWETHAfter = IWETH(WETH_ADDRESS).balanceOf(address(this));
        uint amountWETH = amountWETHAfter - amountWETHBefore;

        // For this example, we will provide equal amounts of liquidity in both assets.
        // Providing liquidity in both assets means liquidity will be earning fees and is considered in-range.
        uint amount0ToMint = amountGnome;
        uint amount1ToMint = amountWETH;

        // Approve the position manager
        TransferHelper.safeApprove(GNOME_ADDRESS, address(POSITION_MANAGER_ADDRESS), amount0ToMint);
        TransferHelper.safeApprove(WETH_ADDRESS, address(POSITION_MANAGER_ADDRESS), amount1ToMint);
        //  for (uint i = 0; i < numberOfGnomes; i++) {
        uint256 id = IGNOME(GNOME_NFT_ADDRESS).factoryMint(msg.sender);
        IGNOME(GNOME_GAME_ADDRESS).signUp(id, userX);
        IGNOME(GNOME_GAME_ADDRESS).setGnomeEmotion(id, baseEmotion);
        // }
        IGNOME(GNOME_NFT_ADDRESS).setTreasuryMintTimeStamp(msg.sender, block.timestamp + treasuryDelay);

        if (isGnomeInRange(msg.sender, true)) {
            return increasePosition(msg.sender, amountGnome, amountWETH);
        } else {
            return mintPosition(msg.sender, msg.sender, amountGnome, amountWETH);
        }
    }

    function mintGnomeReferral(
        string memory code,
        string memory userX,
        uint256 baseEmotion
    )
        public
        payable
        returns (uint _tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund0, uint refund1)
    {
        if (!isAuth[msg.sender]) {
            require(mintOpened, "Minting Not Opened to Public");
        }
        require(msg.value >= getGnomeNFTPriceReferral(), "Not Enough to mint Gnome");
        if (!isAuth[msg.sender]) {
            require(mintReferral, "Minting Not Opened to Referrals");
        }
        // uint numberOfGnomes = msg.value / getGnomeNFTPriceReferral(); // 1 Gnome costs 0.0111 ETH

        IGNOME(GNOME_REFERRAL).signUpReferral(code, msg.sender, 1);
        uint amountWETHBefore = IWETH(WETH_ADDRESS).balanceOf(address(this));
        (uint amountGnome, uint amountWeth) = swapETH_Half(msg.value, false);
        uint amountWETHAfter = IWETH(WETH_ADDRESS).balanceOf(address(this));
        uint amountWETH = amountWETHAfter - amountWETHBefore;

        // For this example, we will provide equal amounts of liquidity in both assets.
        // Providing liquidity in both assets means liquidity will be earning fees and is considered in-range.
        uint amount0ToMint = amountGnome;
        uint amount1ToMint = amountWETH;

        // Approve the position manager
        TransferHelper.safeApprove(GNOME_ADDRESS, address(POSITION_MANAGER_ADDRESS), amount0ToMint);
        TransferHelper.safeApprove(WETH_ADDRESS, address(POSITION_MANAGER_ADDRESS), amount1ToMint);
        // for (uint i = 0; i < numberOfGnomes; i++) {
        uint256 id = IGNOME(GNOME_NFT_ADDRESS).factoryMint(msg.sender);
        IGNOME(GNOME_GAME_ADDRESS).signUp(id, userX);
        IGNOME(GNOME_GAME_ADDRESS).setGnomeEmotion(id, baseEmotion);
        //  }
        IGNOME(GNOME_NFT_ADDRESS).setTreasuryMintTimeStamp(msg.sender, block.timestamp + treasuryDelay);
        if (isGnomeInRange(msg.sender, true)) {
            return increasePosition(msg.sender, amountGnome, amountWETH);
        } else {
            return mintPosition(msg.sender, msg.sender, amountGnome, amountWETH);
        }
    }

    function withdrawOutOfRangePositionAuth(uint256 tokenId) public nonReentrant onlyAuth {
        (uint128 liquidity, , , , ) = getPositionValue(tokenId);
        // Transfer the NFT back to the user
        positionManager.safeTransferFrom(address(this), msg.sender, tokenId, "");

        totalStakedLiquidity -= liquidity;
        // Clear the staked position data
        // Remove the tokenId from the stakedTokenIds array
        for (uint i = 0; i < stakedTokenIds.length; i++) {
            if (stakedTokenIds[i] == tokenId) {
                stakedTokenIds[i] = stakedTokenIds[stakedTokenIds.length - 1];
                stakedTokenIds.pop();
                break;
            }
        }

        removeTokenIdFromArray(tokenId);
    }

    function getTwapX96(address uniswapV3Pool, uint32 twapInterval, bool _isNFT) public view returns (uint256 price) {
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();

            uint256 amount0 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                FixedPoint96.Q96,
                sqrtPriceX96
            );

            uint256 amount1 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                sqrtPriceX96,
                FixedPoint96.Q96
            );
            price = (_isNFT) ? (amount1 * mul) / (amount0 * div) : (amount1 * 10 ** 18) / (amount0 * div);
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int32(twapInterval)))
            );

            uint256 amount0 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                FixedPoint96.Q96,
                sqrtPriceX96
            );

            uint256 amount1 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                sqrtPriceX96,
                FixedPoint96.Q96
            );

            price = (_isNFT) ? (amount1 * mul) / (amount0 * div) : (amount1 * 10 ** 18) / (amount0 * div);
        }
    }

    function getGnomeNFTPrice() public view returns (uint256 priceGnome) {
        if (nftPoolWeth) {
            priceGnome = (getTwapX96(GNOME_NFT_POOL, _twapInterval, true) * treasuryDiscount) / 100;
        } else {
            priceGnome =
                (getTwapX96(GNOME_POOL, _twapInterval, false) *
                    getTwapX96(GNOME_NFT_POOL, _twapInterval, true) *
                    treasuryDiscount) /
                100;
        }

        return priceGnome;
    }

    function getGnomeNFTPriceReferral() public view returns (uint256 priceGnome) {
        if (nftPoolWeth) {
            priceGnome = (getTwapX96(GNOME_NFT_POOL, _twapInterval, true) * referralDiscount) / 100;
        } else {
            priceGnome =
                (getTwapX96(GNOME_POOL, _twapInterval, false) *
                    getTwapX96(GNOME_NFT_POOL, _twapInterval, true) *
                    referralDiscount) /
                100;
        }

        return priceGnome;
    }

    function isGnomeInRange(address fren, bool isFactory) public view returns (bool) {
        int24 tick = getCurrentTick();

        StakedPosition memory frenposition = stakedPositions[fren];
        uint256 position;
        if (isFactory) {
            position = positionByIndex[positionIndex];
            if (position == 0) return false;
        } else {
            position = frenposition.tokenId;
        }
        (, , , int24 minTick, int24 maxTick) = getPositionValue(position);

        if (minTick < tick && tick < maxTick) {
            return true;
        } else {
            return false;
        }
    }

    function getCurrentTick() public view returns (int24) {
        (, int24 tick, , , , , ) = pool.slot0();
        return tick;
    }

    function swapGnome_Half(uint value) public payable returns (uint amountGnome, uint amountWeth) {
        uint amountToSwap = value / 2;

        // Approve the router to spend Gnome
        IGNOME(GNOME_ADDRESS).approve(address(swapRouter), value);

        // Set up swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: GNOME_ADDRESS,
            tokenOut: WETH_ADDRESS,
            fee: 10000, // Assuming a 0.3% pool fee
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountToSwap,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Perform the swap
        amountWeth = swapRouter.exactInputSingle(params);
    }

    function mintPosition(
        address fren,
        address rafundAddress,
        uint _amountGnome,
        uint _amountWETH
    ) internal returns (uint _tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund1, uint refund0) {
        uint256 _deadline = block.timestamp + 3360;
        (int24 lowerTick, int24 upperTick) = _getSpreadTicks();
        IMinimalNonfungiblePositionManager.MintParams memory params = IMinimalNonfungiblePositionManager.MintParams({
            token0: GNOME_ADDRESS,
            token1: WETH_ADDRESS,
            fee: 10000,
            // By using TickMath.MIN_TICK and TickMath.MAX_TICK,
            // we are providing liquidity across the whole range of the pool.
            // Not recommended in production.
            tickLower: lowerTick,
            tickUpper: upperTick,
            amount0Desired: _amountGnome,
            amount1Desired: _amountWETH,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: _deadline
        });

        // Note that the pool defined by gnome/WETH and fee tier 0.1% must
        // already be created and initialized in order to mint
        (_tokenId, liquidity, amount0, amount1) = positionManager.mint(params);

        stakedPositions[fren] = StakedPosition(_tokenId, liquidity, block.timestamp, block.timestamp);
        stakedTokenIds.push(_tokenId); // Add the token ID to the array
        positionIndex++;
        positionByIndex[positionIndex] = _tokenId;
        totalStakedLiquidity += liquidity;

        if (amount0 < _amountGnome) {
            refund0 = _amountGnome - amount0;
            //TransferHelper.safeTransfer(GNOME_ADDRESS, rafundAddress, refund0);
            gnomeReward[rafundAddress] += refund0;
        }

        if (amount1 < _amountWETH) {
            refund1 = _amountWETH - amount1;
            TransferHelper.safeTransfer(WETH_ADDRESS, rafundAddress, refund1);
            // uint256 amountGnome = swapWETH(refund1);
            //TransferHelper.safeTransfer(GNOME_ADDRESS, rafundAddress, amountGnome);
            //gnomeReward[rafundAddress] += amountGnome;
        }
    }

    function calculateSumOfLiquidity() public view returns (uint128) {
        uint128 totalLiq = 0;

        for (uint256 i = 0; i < stakedTokenIds.length; i++) {
            uint256 tokenId = stakedTokenIds[i];

            (uint128 liquidity, , , , ) = getPositionValue(tokenId);

            // Add up the liquidity
            totalLiq += liquidity;
        }

        return totalLiq;
    }

    function increasePosition(
        address fren,
        uint _amountGnome,
        uint _amountWETH
    ) internal returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1, uint refund0, uint refund1) {
        tokenId = positionByIndex[positionIndex];

        uint256 _deadline = block.timestamp + 100;
        IMinimalNonfungiblePositionManager.IncreaseLiquidityParams memory params = IMinimalNonfungiblePositionManager
            .IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: _amountGnome,
                amount1Desired: _amountWETH,
                amount0Min: 0,
                amount1Min: 0,
                deadline: _deadline
            });

        (liquidity, amount0, amount1) = positionManager.increaseLiquidity(params);
        uint128 curr_liquidity = stakedPositions[fren].liquidity + liquidity;

        stakedPositions[fren] = StakedPosition(tokenId, curr_liquidity, block.timestamp, block.timestamp);

        totalStakedLiquidity += liquidity;

        if (amount0 < _amountGnome) {
            refund0 = _amountGnome - amount0;
            // TransferHelper.safeTransfer(GNOME_ADDRESS, fren, refund0);
            gnomeReward[fren] += refund0;
        }

        if (amount1 < _amountWETH) {
            refund1 = _amountWETH - amount1;
            TransferHelper.safeTransfer(WETH_ADDRESS, fren, refund1);
        }
    }

    function removeTokenIdFromArray(uint256 tokenId) internal {
        uint256 length = stakedTokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (stakedTokenIds[i] == tokenId) {
                // Swap with the last element
                stakedTokenIds[i] = stakedTokenIds[length - 1];
                // Remove the last element
                stakedTokenIds.pop();
                break;
            }
        }
    }

    function _getStakedPositionID(address fren) public view returns (uint256 tokenId) {
        StakedPosition memory position = stakedPositions[fren];
        return position.tokenId;
    }

    function _getSpreadTicks() public view returns (int24 _lowerTick, int24 _upperTick) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        (uint160 sqrtRatioAX96, uint160 sqrtRatioBX96) = (
            uint160(FullMath.mulDiv(sqrtPriceX96, SQRT_0005_PERCENT, 1e18)),
            uint160(FullMath.mulDiv(sqrtPriceX96, SQRT_2000_PERCENT, 1e18))
        );

        _lowerTick = TickMath.getTickAtSqrtRatio(sqrtRatioAX96);
        _upperTick = TickMath.getTickAtSqrtRatio(sqrtRatioBX96);

        _lowerTick = _lowerTick % tickSpacing == 0
            ? _lowerTick // accept valid tickSpacing
            : _lowerTick > 0 // else, round up to closest valid tickSpacing
            ? (_lowerTick / tickSpacing + 1) * tickSpacing
            : (_lowerTick / tickSpacing) * tickSpacing;
        _upperTick = _upperTick % tickSpacing == 0
            ? _upperTick // accept valid tickSpacing
            : _upperTick > 0 // else, round down to closest valid tickSpacing
            ? (_upperTick / tickSpacing) * tickSpacing
            : (_upperTick / tickSpacing - 1) * tickSpacing;
    }

    function setTicks(int24 _minTick, int24 _maxTick, int24 _tickSpacing) public onlyOwner {
        MaxTick = _maxTick;
        MinTick = _minTick;
        tickSpacing = _tickSpacing;
    }

    function setTwap(uint32 twapInterval) public onlyOwner {
        _twapInterval = twapInterval;
    }

    function setDelay(uint256 _delay) public onlyOwner {
        treasuryDelay = _delay;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // EDIT for 0.8 compatibility:
            // see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
            uint256 twos = denominator & (~denominator + 1);

            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import { FullMath } from "./FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate =
            FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount0,
                    intermediate,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount1,
                    FixedPoint96.Q96,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 =
                getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 =
                getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount1
            );
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                liquidity,
                sqrtRatioBX96 - sqrtRatioAX96,
                FixedPoint96.Q96
            );
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(
                sqrtRatioX96,
                sqrtRatioBX96,
                liquidity
            );
            amount1 = getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioX96,
                liquidity
            );
        } else {
            amount1 = getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;


/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract PeripheryImmutableState {
    address public immutable factory;
    address public immutable WETH9;

    constructor(address _factory, address _WETH9) {
        factory = _factory;
        WETH9 = _WETH9;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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
        require(c >= a, "SafeMath: addition overflow");
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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        uint256 absTick =
            tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));

        // EDIT: 0.8 compatibility
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio =
            absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96)
        internal
        pure
        returns (int24 tick)
    {
        // second inequality must be < because the price can never reach the price at the max tick
        require(
            sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO,
            "R"
        );
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow =
            int24(
                (log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
            );
        int24 tickHi =
            int24(
                (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
            );

        tick = tickLow == tickHi
            ? tickLow
            : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
            ? tickHi
            : tickLow;
    }
}