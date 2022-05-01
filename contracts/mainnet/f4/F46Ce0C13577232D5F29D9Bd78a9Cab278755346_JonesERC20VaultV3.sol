// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {JonesVaultV3} from "./JonesVaultV3.sol";

contract JonesERC20VaultV3 is JonesVaultV3 {
    constructor(
        address _asset,
        address _share,
        address _governor,
        address _feeDistributor,
        uint256 _vaultCap
    ) JonesVaultV3(_asset, _share, _governor, _feeDistributor, _vaultCap) {}

    /**
     * @inheritdoc JonesVaultV3
     */
    function _afterCloseManagementWindow() internal virtual override {}

    /**
     * @inheritdoc JonesVaultV3
     */
    function _afterOpenManagementWindow() internal virtual override {}

    /**
     * @inheritdoc JonesVaultV3
     */
    function _afterDeposit(uint256 assets, uint256 shares)
        internal
        virtual
        override
    {}

    /**
     * @inheritdoc JonesVaultV3
     */
    function _beforeWithdraw(uint256 assets, uint256 shares)
        internal
        virtual
        override
    {}
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {JonesAsset} from "../VaultsV2/JonesAsset.sol";
import {IVault} from "./IVault.sol";
import {FixedPointMath} from "./library/FixedPointMath.sol";

/**
 * @title Jones Abstract Vault V3
 * @author JonesDAO
 */
abstract contract JonesVaultV3 is IVault, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using FixedPointMath for uint256;

    /// Role for the entities that will manage the vault
    bytes32 public constant GOVERNOR = keccak256("GOVERNOR_ROLE");
    /// Role for the strategies that will use the vault's assets
    bytes32 public constant STRATEGIES = keccak256("STRATEGIES_ROLE");

    /// The asset that can be deposited into the vault
    address public immutable asset;
    /// The shares that will represent the deposits
    address public immutable share;

    /// Snapshot of total shares supply from previous epoch / before management starts
    uint256 public snapshotSharesSupply;

    /// Snapshot of total asset supply from previous epoch / before management starts
    uint256 public snapshotAssetBalance;

    /// Max amount of assets that can be deposited into the vault
    uint256 public vaultCap;

    /// `true` if the vault should charge management & performance fees, `false` otherwise
    bool public chargeFees;
    /// The address that will receive the fees
    address public feeDistributor;

    /// By default, deposits and withdrawals can only be called by
    /// allowed users (ie when `msg.sender` is not a contract). This
    /// mapping can be used to whitelist contracts that need to be able to
    /// perform deposits and withdrawals.
    mapping(address => bool) public whitelistedContract;

    /// The current state of the vault
    State public state = State.INITIAL;

    /**
     * @param _asset The address of the asset that can be deposited into the vault
     * @param _share The address of the asset that will represent deposits
     * @param _governor The address of the entity that will manage the vault
     * @param _feeDistributor The address of the entity that will receive fees
     * @param _vaultCap The initial vault cap
     */
    constructor(
        address _asset,
        address _share,
        address _governor,
        address _feeDistributor,
        uint256 _vaultCap
    ) {
        if (_asset == address(0)) {
            revert INVALID_ADDRESS();
        }

        if (_share == address(0)) {
            revert INVALID_ADDRESS();
        }

        if (_governor == address(0)) {
            revert INVALID_ADDRESS();
        }

        if (_feeDistributor == address(0)) {
            revert INVALID_ADDRESS();
        }

        asset = _asset;
        share = _share;
        feeDistributor = _feeDistributor;
        vaultCap = _vaultCap;

        // Default value for snapshot. Will be overridden when calling `initialRun`
        snapshotSharesSupply = 1;
        snapshotAssetBalance = 1;

        // Grant roles
        _grantRole(GOVERNOR, _governor);
    }

    // ============================= View functions ================================

    /**
     * @inheritdoc IVault
     */
    function convertToShares(uint256 _assets)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 supply = snapshotSharesSupply;
        return
            supply == 0
                ? _assets
                : _assets.mulDivDown(supply, snapshotAssetBalance);
    }

    /**
     * @dev We charge fees at the end of an epoch so it doens't make sense to calculate fees here
     * @inheritdoc IVault
     */
    function previewDeposit(uint256 _assets)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return convertToShares(_assets);
    }

    /**
     * @inheritdoc IVault
     */
    function convertToAssets(uint256 _shares)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 supply = snapshotSharesSupply;
        return
            supply == 0
                ? _shares
                : _shares.mulDivDown(snapshotAssetBalance, supply);
    }

    /**
     * @inheritdoc IVault
     */
    function maxWithdraw(address _owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return convertToAssets(JonesAsset(share).balanceOf(_owner));
    }

    /**
     * @inheritdoc IVault
     */
    function maxDeposit(address)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // If management window is open deposits are disabled
        if (state == State.INITIAL || state == State.MANAGED) {
            return 0;
        }

        // If vault cap was breached deposits are disabled
        if (totalAssets() >= vaultCap) {
            return 0;
        }

        return vaultCap;
    }

    /**
     * @dev If the vault deposit assets in farms, those should be considered here too
     * @inheritdoc IVault
     */
    function totalAssets() public view virtual override returns (uint256) {
        if (state == State.MANAGED) {
            return snapshotAssetBalance;
        }

        return IERC20(asset).balanceOf(address(this));
    }

    /**
     * @inheritdoc IVault
     */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @inheritdoc IVault
     */
    function previewMint(uint256 _shares)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 supply = snapshotSharesSupply;
        return
            supply == 0
                ? _shares
                : _shares.mulDivUp(snapshotAssetBalance, supply);
    }

    /**
     * @inheritdoc IVault
     */
    function previewWithdraw(uint256 _assets)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 supply = snapshotSharesSupply;
        return
            supply == 0
                ? _assets
                : _assets.mulDivUp(supply, snapshotAssetBalance);
    }

    /**
     * @inheritdoc IVault
     */
    function maxRedeem(address _owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return JonesAsset(share).balanceOf(_owner);
    }

    /**
     * @inheritdoc IVault
     */
    function previewRedeem(uint256 _shares)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return convertToAssets(_shares);
    }

    // ============================= User functions ================================

    /**
     * @inheritdoc IVault
     */
    function deposit(uint256 _assets, address _receiver)
        public
        virtual
        override
        nonReentrant
        returns (uint256 shares)
    {
        _senderIsEligible();
        _onState(State.UNMANAGED);

        if (_assets == 0) {
            revert INVALID_ASSETS_AMOUNT();
        }

        _checkDepositAmountIsValid(_assets);
        shares = previewDeposit(_assets);

        // Check for rounding error since we round down in previewDeposit.
        if (shares == 0) {
            revert ZERO_SHARES_AVAILABLE_WHEN_DEPOSITING();
        }

        _mint(_receiver, _assets, shares);
    }

    /**
     * @inheritdoc IVault
     */
    function mint(uint256 _shares, address _receiver)
        public
        virtual
        override
        nonReentrant
        returns (uint256 assets)
    {
        _senderIsEligible();
        _onState(State.UNMANAGED);

        if (_shares == 0) {
            revert INVALID_SHARES_AMOUNT();
        }

        assets = previewMint(_shares); // No need to check for rounding error, previewMint rounds up.
        _checkDepositAmountIsValid(assets);
        _mint(_receiver, assets, _shares);
    }

    /**
     * @inheritdoc IVault
     */
    function withdraw(
        uint256 _assets,
        address _receiver,
        address
    ) public virtual override nonReentrant returns (uint256 shares) {
        _onState(State.UNMANAGED);
        if (_assets == 0) {
            revert INVALID_ASSETS_AMOUNT();
        }
        shares = previewWithdraw(_assets); // No need to check for rounding error, previewWithdraw rounds up.

        _burn(_receiver, _assets, shares);
    }

    /**
     * @inheritdoc IVault
     */
    function redeem(
        uint256 _shares,
        address _receiver,
        address
    ) public virtual override nonReentrant returns (uint256 assets) {
        _onState(State.UNMANAGED);

        assets = previewRedeem(_shares);
        // Check for rounding error since we round down in previewRedeem.
        if (assets == 0) {
            revert INVALID_ASSETS_AMOUNT();
        }

        _burn(_receiver, assets, _shares);
    }

    // ============================= Strategy functions ================================

    /**
     * @inheritdoc IVault
     */
    function pull(uint256 _assets)
        public
        virtual
        override
        onlyRole(STRATEGIES)
    {
        _onState(State.MANAGED);
        if (_assets == 0) {
            revert INVALID_ASSETS_AMOUNT();
        }
        IERC20(asset).safeTransfer(msg.sender, _assets);
    }

    /**
     * @inheritdoc IVault
     */
    function depositStrategyFunds(uint256 _assets)
        public
        virtual
        override
        onlyRole(STRATEGIES)
    {
        _onState(State.MANAGED);
        if (_assets == 0) {
            revert INVALID_ASSETS_AMOUNT();
        }
        IERC20(asset).safeTransferFrom(msg.sender, address(this), _assets);
    }

    // ============================= Admin functions ================================

    /**
     * @inheritdoc IVault
     */
    function whitelistStrategy(address _strategyAddress)
        public
        virtual
        override
        onlyRole(GOVERNOR)
    {
        _grantRole(STRATEGIES, _strategyAddress);
    }

    /**
     * @inheritdoc IVault
     */
    function removeStrategyFromWhitelist(address _strategyAddress)
        public
        virtual
        override
        onlyRole(GOVERNOR)
    {
        _revokeRole(STRATEGIES, _strategyAddress);
    }

    /**
     * @inheritdoc IVault
     */
    function addContractAddressToWhitelist(address _contractAddress)
        public
        virtual
        override
        onlyRole(GOVERNOR)
    {
        whitelistedContract[_contractAddress] = true;
    }

    /**
     * @inheritdoc IVault
     */
    function removeContractAddressFromWhitelist(address _contractAddress)
        public
        virtual
        override
        onlyRole(GOVERNOR)
    {
        whitelistedContract[_contractAddress] = false;
    }

    /**
     * @inheritdoc IVault
     */
    function migrate(address _to, address[] memory _tokens)
        public
        virtual
        override
        onlyRole(GOVERNOR)
    {
        // migrate other ERC20 Tokens
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            uint256 assetBalance = token.balanceOf(address(this));
            if (assetBalance > 0) {
                token.transfer(_to, assetBalance);
            }
        }

        // migrate ETH balance
        uint256 balanceGwei = address(this).balance;
        if (balanceGwei > 0) {
            payable(_to).transfer(balanceGwei);
        }
    }

    /**
     * @inheritdoc IVault
     */
    function setVaultCap(uint256 _amount)
        public
        virtual
        override
        onlyRole(GOVERNOR)
    {
        vaultCap = _amount;
    }

    /**
     * @inheritdoc IVault
     */
    function setChargeFees(bool _status)
        public
        virtual
        override
        onlyRole(GOVERNOR)
    {
        chargeFees = _status;
    }

    function setFeeDistributor(address _feeDistributor)
        public
        virtual
        override
        onlyRole(GOVERNOR)
    {
        if (_feeDistributor == address(0)) {
            revert INVALID_ADDRESS();
        }

        feeDistributor = _feeDistributor;
    }

    /**
     * @inheritdoc IVault
     */
    function initialRun(
        uint256 _snapshotAssetBalance,
        uint256 _snapshotSharesSupply
    ) public virtual override onlyRole(GOVERNOR) {
        _onState(State.INITIAL);

        if (_snapshotAssetBalance == 0 || _snapshotSharesSupply == 0) {
            revert INVALID_SNAPSHOT_VALUE();
        }

        snapshotAssetBalance = _snapshotAssetBalance;
        snapshotSharesSupply = _snapshotSharesSupply;

        state = State.UNMANAGED;

        emit EpochEnded(
            block.timestamp,
            snapshotAssetBalance,
            snapshotSharesSupply
        );
    }

    /**
     * @inheritdoc IVault
     */
    function openManagementWindow() public virtual override onlyRole(GOVERNOR) {
        _onState(State.UNMANAGED);

        _beforeOpenManagementWindow();

        state = State.MANAGED;

        emit EpochStarted(
            block.timestamp,
            snapshotAssetBalance,
            snapshotSharesSupply
        );

        _afterOpenManagementWindow();
    }

    /**
     * @inheritdoc IVault
     */
    function closeManagementWindow()
        public
        virtual
        override
        onlyRole(GOVERNOR)
    {
        _onState(State.MANAGED);

        _beforeCloseManagementWindow();

        state = State.UNMANAGED;

        emit EpochEnded(
            block.timestamp,
            snapshotAssetBalance,
            snapshotSharesSupply
        );

        _afterCloseManagementWindow();
    }

    // ============================= INTERNAL HOOKS LOGIC ================================
    function _beforeWithdraw(uint256 _assets, uint256 _shares) internal virtual;

    function _afterDeposit(uint256 _assets, uint256 _shares) internal virtual;

    /**
     * @notice Executed before updating the `state` on `closeManagementWindow()`
     */
    function _beforeOpenManagementWindow() internal virtual {
        // Snapshot asset and share supply
        _executeSnapshot();
    }

    /**
     * @notice Executed after updating the `state` on `closeManagementWindow()`
     */
    function _afterOpenManagementWindow() internal virtual;

    /**
     * @notice Executed before updating the `state` on `openmanagementWindow()`
     */
    function _beforeCloseManagementWindow() internal virtual {
        // Charge fees
        _chargeFees();

        // Snapshot asset and share supply
        _executeSnapshot();
    }

    /**
     * @notice Executed after updating the `state` on `openmanagementWindow()`
     */
    function _afterCloseManagementWindow() internal virtual;

    // ============================== Helpers ==============================
    /**
     * @notice Mint `_shares` to `_receiver` and receives `_assets`
     * @dev It doesn't provide any checks so use carefully
     * @param _receiver The address that will receive the minted shares
     * @param _assets The amount of assets to transfer to the vault
     * @param _shares The amount of shares to mint
     */
    function _mint(
        address _receiver,
        uint256 _assets,
        uint256 _shares
    ) internal virtual {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), _assets);
        JonesAsset(share).mint(_receiver, _shares);
        emit Deposit(msg.sender, _receiver, _assets, _shares);
        _afterDeposit(_assets, _shares);
    }

    /**
     * @notice Burn `_shares` from `msg.sender` transfer `_assets` to `_receiver`
     * @dev It doesn't provide any checks so use carefully
     * @param _receiver The address that will receive the asset tokens
     * @param _assets The amount of assets to transfer to `_receiver`
     * @param _shares The amount of shares to burn from `owner`
     */
    function _burn(
        address _receiver,
        uint256 _assets,
        uint256 _shares
    ) internal virtual {
        _beforeWithdraw(_assets, _shares);

        JonesAsset(share).burnFrom(msg.sender, _shares);
        emit Withdraw(msg.sender, _receiver, msg.sender, _assets, _shares);
        IERC20(asset).safeTransfer(_receiver, _assets);
    }

    function _senderIsEligible() internal view {
        if (msg.sender != tx.origin) {
            if (!whitelistedContract[msg.sender]) {
                revert CONTRACT_ADDRESS_MAKING_PROHIBITED_FUNCTION_CALL();
            }
        }
    }

    /**
     * Checks if `assets` amount is depositable given the vault cap. Reverts if amount is invalid.
     */
    function _checkDepositAmountIsValid(uint256 _assets) internal virtual {
        if (vaultCap < type(uint256).max) {
            if (totalAssets() + _assets > vaultCap) {
                revert DEPOSIT_ASSET_AMOUNT_EXCEEDS_MAX_DEPOSIT();
            }
        }
    }

    /**
     * @notice Checks if the vault is on `_expectedState`
     * @dev Will revert if `_expectedState != state`
     */
    function _onState(State _expectedState) internal view virtual {
        if (state != _expectedState) {
            revert INVALID_STATE(_expectedState, state);
        }
    }

    /**
     * @notice Takes a snapshot of the deposited assets and the minted shares
     */
    function _executeSnapshot() internal virtual {
        snapshotSharesSupply = JonesAsset(share).totalSupply();
        snapshotAssetBalance = IERC20(asset).balanceOf(address(this));

        emit Snapshot(
            block.timestamp,
            snapshotAssetBalance,
            snapshotSharesSupply
        );
    }

    /**
     * @notice Charges management & performance fees.
     * @dev Fees are transferred to `feeDistributor`.
     * @dev Only if `chargeFees == true`.
     */
    function _chargeFees() internal virtual {
        if (chargeFees) {
            uint256 balanceNow = IERC20(asset).balanceOf(address(this));

            if (balanceNow > snapshotAssetBalance) {
                // send performance fee to fee distributor (20% on profit wrt benchmark)
                // 1 / 5 = 20 / 100
                IERC20(asset).safeTransfer(
                    feeDistributor,
                    (balanceNow - snapshotAssetBalance) / 5
                );
            }
            // send management fee to fee distributor (2% annually)
            // 1 / 600 = 2 / (100 * 12)
            IERC20(asset).safeTransfer(
                feeDistributor,
                snapshotAssetBalance / 600
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   ********************* 
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Jones Asset Token (jAsset)
/// @author Jones DAO
/// @notice Token used in Jones DAO's vaults for claiming back rewards.

contract JonesAsset is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @param _multisigAddr address of the multisig wallet
    /// @param _name the name of the token
    /// @param _symbol the symbol of the token
    constructor(
        address _multisigAddr,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        require(_multisigAddr != address(0), "Invalid multisig address");
        _grantRole(DEFAULT_ADMIN_ROLE, _multisigAddr);
    }

    /// Mints jAsset to address.
    /// @param _to The address to send jAsset to.
    /// @param _amount The amount of jAsset to be minted.
    function mint(address _to, uint256 _amount) public onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    /// Allows address to mint new jAsset.
    /// @dev The address should be set to the JonesAssetVault contract.
    /// @param _minterContract The address that will be set as the minter.
    function giveMinterRole(address _minterContract)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(MINTER_ROLE, _minterContract);
    }

    /// @notice Revokes address's token minting rights.
    /// @param _minterContract The address that will no longer be able to mint jAsset.
    function revokeMinterRole(address _minterContract)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(MINTER_ROLE, _minterContract);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IVault {
    // ============================= View functions ================================

    /**
     * The amount of `shares` that the Vault would exchange for the amount of `assets` provided, in an ideal scenario where all the conditions are met.
     *
     * Does not show any variations depending on the caller.
     * Does not reflect slippage or other on-chain conditions, when performing the actual exchange.
     * Does not revert unless due to integer overflow caused by an unreasonably large input.
     * This calculation does not reflect the “per-user” price-per-share, and instead reflects the “average-user’s” price-per-share, meaning what the average user can expect to see when exchanging to and from.
     *
     * @param assets Amount of assets to convert.
     * @return shares Amount of shares calculated for the amount of given assets, rounded down towards 0. Does not include any fees that are charged against assets in the Vault.
     */
    function convertToShares(uint256 assets)
        external
        view
        returns (uint256 shares);

    /**
     * The amount of `assets` that the Vault would exchange for the amount of `shares` provided, in an ideal scenario where all the conditions are met.
     *
     * Does not show any variations depending on the caller.
     * Does not reflect slippage or other on-chain conditions, when performing the actual exchange.
     * Does not revert unless due to integer overflow caused by an unreasonably large input.
     * This calculation does not reflect the “per-user” price-per-share, and instead reflects the “average-user’s” price-per-share, meaning what the average user can expect to see when exchanging to and from.
     *
     * @return assets Amount of assets calculated for the given amount of shares, rounded down towards 0. Does not include fees that are charged against assets in the Vault.
     */
    function convertToAssets(uint256 shares)
        external
        view
        returns (uint256 assets);

    /**
     * Maximum amount of the underlying asset that can be deposited into the Vault for the receiver, through a deposit call.
     * Returns the maximum amount of assets deposit would allow to be deposited for receiver and not cause a revert, which should be higher than the actual maximum that would be accepted (it should underestimate if necessary). This assumes that the user has infinite assets, i.e. does not rely on balanceOf of asset.
     *
     * Does not revert.
     * This is akin to `vaultCap` in legacy vaults.
     *
     * The `receiver` parameter is added for ERC-4626 parity and is not relevant to our use case
     * since we are not going to have user specific limits for deposits. Either deposits are limited
     * to everyone or no one.
     *
     * @return maxAssets Max assets that can be deposited for receiver. Returns 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited. Returns 0 if deposits are entirely disabled (even temporarily).
     */
    function maxDeposit(address receiver)
        external
        view
        returns (uint256 maxAssets);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
     *
     * Returns as close to and no more than the exact amount of Vault shares that would be minted in a deposit call in the same transaction. I.e. deposit will return the same or more shares as previewDeposit if called in the same transaction.
     * Does not account for deposit limits like those returned from maxDeposit and always acts as though the deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * Does not revert due to vault specific user/global limits. May revert due to other conditions that would also cause deposit to revert.
     *
     * Any unfavorable discrepancy between convertToShares and previewDeposit will be considered slippage in share price or some other type of condition, meaning the depositor will lose assets by depositing.
     *
     * @return shares exact amount of shares that would be minted in a deposit call. That includes deposit fees. Integrators should be aware of the existence of deposit fees.
     */
    function previewDeposit(uint256 assets)
        external
        view
        returns (uint256 shares);

    /**
     * @return The current vault State
     */
    function state() external view returns (State);

    /**
     * The address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     */
    function asset() external view returns (address);

    /**
     * The address of the underlying shares token used used to represent tokenized vault.
     */
    function share() external view returns (address);

    /**
     * Total amount of the underlying asset that is managed by this vault.
     *
     * This includes any compounding that occurs from yield.
     * It must be inclusive of any fees that are charged against assets in the Vault.
     * Must not revert.
     *
     * @return totalManagedAssets amount of underlying asset managed by vault.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * Maximum amount of shares that can be minted from the Vault for the `receiver`, through a `mint` call.
     *
     * Returns `2 ** 256 - 1` if there is no limit on the maximum amount of shares that may be minted.
     */
    function maxMint(address receiver)
        external
        view
        returns (uint256 maxShares);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
     * MUST NOT revert due to vault specific user/global limits. MAY revert due to other conditions that would also cause mint to revert.
     * note: Any unfavorable discrepancy between `convertToAssets` and `previewMint` should be considered slippage in share price or some other type of condition, meaning the depositor will lose assets by minting.
     *
     * Does not account for mint limits like those returned from maxMint and always acts as though the mint would be accepted, regardless if the user has enough tokens approved, etc.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * Maximum amount of the underlying asset that can be withdrawn from the `owner` balance in the Vault, through a `withdraw` call.
     *
     * Factors in both global and user-specific limits, like if withdrawals are entirely disabled (even temporarily) it must return 0.
     * Does not revert.
     *
     * @return maxAssets The maximum amount of assets that could be transferred from `owner` through `withdraw` and not cause a revert, which must not be higher than the actual maximum that would be accepted (it should underestimate if necessary).
     */
    function maxWithdraw(address owner)
        external
        view
        returns (uint256 maxAssets);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
     *
     * Does not revert due to vault specific user/global limits. May revert due to other conditions that would also cause withdraw to revert.
     * Any unfavorable discrepancy between convertToShares and previewWithdraw should be considered slippage in share price or some other type of condition, meaning the depositor will lose assets by depositing.
     *
     * @return shares Shares available to withdraw for specified assets. This includes of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     */
    function previewWithdraw(uint256 assets)
        external
        view
        returns (uint256 shares);

    /**
     * Maximum amount of Vault shares that can be redeemed from the `owner` balance in the Vault, through a `redeem` call.
     *
     * @return maxShares Max shares that can be redeemed. Factors in both global and user-specific limits, like if redemption is entirely disabled (even temporarily) it will return 0.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.
     * Does not account for redemption limits like those returned from maxRedeem and should always act as though the redemption would be accepted, regardless if the user has enough shares, etc.
     *
     * Does not revert due to vault specific user/global limits. May revert due to other conditions that would also cause redeem to revert.
     *
     * @return assets Amount of assets redeemable for given shares. Includes of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     */
    function previewRedeem(uint256 shares)
        external
        view
        returns (uint256 assets);

    // ============================= User functions ================================

    /**
     * @dev Mints `shares` Vault shares to `receiver` by depositing `amount` of underlying tokens. This should only be called outside the management window.
     *
     * Reverts if all of assets cannot be deposited (ex due to deposit limit, slippage, approvals, etc).
     *
     * Emits a {Deposit} event
     */
    function deposit(uint256 assets, address receiver)
        external
        returns (uint256 shares);

    /**
     * Mints exactly `shares` Vault shares to `receiver` by depositing `amount` of underlying tokens.
     *
     * Reverts if all of shares cannot be minted (ex. due to deposit limit being reached, slippage, etc).
     *
     * Emits a {Deposit} event
     */
    function mint(uint256 shares, address receiver)
        external
        returns (uint256 assets);

    /**
     * Burns `shares` from `owner` and sends exactly `assets` of underlying tokens to `receiver`. Only available outside of management window.
     *
     * Reverts if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
     * Any pre-requesting methods before withdrawal should be performed separately.
     *
     * Emits a {Withdraw} event
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * Burns exactly `shares` from `owner` and sends `assets` of underlying tokens to `receiver`. Only available outside of management window.
     *
     * Reverts if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
     * Any pre-requesting methods before withdrawal should be performed separately.
     *
     * Emits a {Withdraw} event
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    // ============================= Strategy functions ================================

    /**
     * Sends the required amount of Asset from this vault to the calling strategy.
     * @dev can only be called by whitelisted strategies (KEEPER role)
     * @dev reverts if management window is closed.
     * @param assets the amount of tokens to pull
     */
    function pull(uint256 assets) external;

    /**
     * Deposits funds from Strategy (both profits and principal amounts).
     * @dev can only be called by whitelisted strategies (KEEPER role)
     * @dev reverts if management window is closed.
     * @param assets the amount of Assets being deposited from the strategy.
     */
    function depositStrategyFunds(uint256 assets) external;

    // ============================= Admin functions ================================

    /**
     * Sets the max deposit `amount` for vault. Akin to setting vault cap in v2 vaults.
     * Since we will not be limiting deposits per user there is no need to add `receiver` input
     * in the argument.
     */
    function setVaultCap(uint256 amount) external;

    /**
     * Adds a strategy to the whitelist.
     * @dev can only be called by governor (GOVERNOR role)
     * @param _address of the strategy to whitelist
     */
    function whitelistStrategy(address _address) external;

    /**
     * Removes a strategy from the whitelist.
     * @dev can only be called by governor (GOVERNOR role)
     * @param _address of the strategy to remove from whitelist
     */
    function removeStrategyFromWhitelist(address _address) external;

    /**
     * @notice Adds a contract to the whitelist.
     * @dev By default only EOA cann interact with the vault.
     * @dev Whitelisted contracts will be able to interact with the vault too.
     * @param contractAddress The address of the contract to whitelist.
     */
    function addContractAddressToWhitelist(address contractAddress) external;

    /**
     * @notice Used to check wheter a contract address is whitelisted to use the vault
     * @param _contractAddress The address of the contract to check
     * @return `true` if the contract is whitelisted, `false` otherwise
     */
    function whitelistedContract(address _contractAddress)
        external
        view
        returns (bool);

    /**
     * @notice Removes a contract from the whitelist.
     * @dev Removed contracts wont be able to interact with the vault.
     * @param contractAddress The address of the contract to whitelist.
     */
    function removeContractAddressFromWhitelist(address contractAddress)
        external;

    /**
     * Migrate vault to new vault contract.
     * @dev acts as emergency withdrawal if needed.
     * @dev can only be called by governor (GOVERNOR role)
     * @param _to New vault contract address.
     * @param _tokens Addresses of tokens to be migrated.
     *
     */
    function migrate(address _to, address[] memory _tokens) external;

    /**
     * Deposits and withdrawals close, assets are under vault control.
     * @dev can only be called by governor (GOVERNOR role)
     */
    function openManagementWindow() external;

    /**
     * Open vault for deposits and claims.
     * @dev can only be called by governor (GOVERNOR role)
     */
    function closeManagementWindow() external;

    /**
     * Open vault for deposits and claims, sets the snapshot of assets balance manually
     * @dev can only be called by governor (GOVERNOR role)
     * @dev can only be called on `State.INITIAL`
     * @param _snapshotAssetBalance Overrides the value of the snapshotted asset balance
     * @param _snapshotShareSupply Overrides the value of the snapshotted share supply
     */
    function initialRun(
        uint256 _snapshotAssetBalance,
        uint256 _snapshotShareSupply
    ) external;

    /**
     * Enable/diable charging performance & management fees
     * @dev can only be called by GOVERNOR role
     * @param _status `true` if the vault should charge fees, `false` otherwise
     */
    function setChargeFees(bool _status) external;

    /**
     * Updated the fee distributor address
     * @dev can only be called by GOVERNOR role
     * @param _feeDistributor The address of the new fee distributor
     */
    function setFeeDistributor(address _feeDistributor) external;

    // ============================= Enums =================================

    /**
     * Enum to represent the current state of the vault
     * INITIAL = Right after deployment, can move to `UNMANAGED` by calling `initialRun`
     * UNMANAGED = Users are able to interact with the vault, can move to `MANAGED` by calling `openManagementWindow`
     * MANAGED = Strategies will be able to borrow & repay, can move to `UNMANAGED` by calling `closeManagementWindow`
     */
    enum State {
        INITIAL,
        UNMANAGED,
        MANAGED
    }

    // ============================= Events ================================

    /**
     * `caller` has exchanged `assets` for `shares`, and transferred those `shares` to `owner`.
     * Emitted when tokens are deposited into the Vault via the `mint` and `deposit` methods.
     */
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * `caller` has exchanged `shares`, owned by `owner`, for `assets`, and transferred those `assets` to `receiver`.
     * Will be emitted when shares are withdrawn from the Vault in `ERC4626.redeem` or `ERC4626.withdraw` methods.
     */
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * emitted when vault balance snapshot is taken
     * @param _timestamp snapshot timestamp (indexed)
     * @param _vaultBalance vault balance value
     * @param _jonesAssetSupply jDPX total supply value
     */
    event Snapshot(
        uint256 indexed _timestamp,
        uint256 _vaultBalance,
        uint256 _jonesAssetSupply
    );

    /**
     * emitted when asset management window is opened
     * @param _timestamp snapshot timestamp (indexed)
     * @param _assetBalance new vault balance value
     * @param _shareSupply share token total supply at this time
     */
    event EpochStarted(
        uint256 indexed _timestamp,
        uint256 _assetBalance,
        uint256 _shareSupply
    );

    /** emitted when claim and deposit windows are open
     * @param _timestamp snapshot timestamp (indexed)
     * @param _assetBalance new vault balance value
     * @param _shareSupply share token total supply at this time
     */
    event EpochEnded(
        uint256 indexed _timestamp,
        uint256 _assetBalance,
        uint256 _shareSupply
    );

    // ============================= Errors ================================
    error MSG_SENDER_NOT_WHITELISTED_USER();
    error DEPOSIT_ASSET_AMOUNT_EXCEEDS_MAX_DEPOSIT();
    error MINT_SHARE_AMOUNT_EXCEEDS_MAX_MINT();
    error ZERO_SHARES_AVAILABLE_WHEN_DEPOSITING();
    error INVALID_STATE(State _expected, State _actual);
    error INVALID_ASSETS_AMOUNT();
    error INVALID_SHARES_AMOUNT();
    error CONTRACT_ADDRESS_MAKING_PROHIBITED_FUNCTION_CALL();
    error INVALID_ADDRESS();
    error INVALID_SNAPSHOT_VALUE();
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// Solmate functions
library FixedPointMath {
    // Source: https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol
    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    // Source: https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol
    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
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
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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