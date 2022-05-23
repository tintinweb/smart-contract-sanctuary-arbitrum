// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVault} from "./IVault.sol";
import {IwETH} from "../interfaces/IwETH.sol";

/**
 * @notice Contract that allows users to deposit and redeem native ETH on the Jones wETH vault
 */
contract JonesWETHVaultV3Adapter is Ownable, ReentrancyGuard {
    IVault public vault;
    IwETH public wETH;
    IERC20 public share;

    /**
     * @param _vault The vault address
     * @param _wETH The wETH address
     * @param _governor The address of the owner of the adapter
     */
    constructor(
        address _vault,
        address _wETH,
        address _governor
    ) {
        if (_vault == address(0)) {
            revert INVALID_ADDRESS();
        }

        if (_wETH == address(0)) {
            revert INVALID_ADDRESS();
        }

        if (_governor == address(0)) {
            revert INVALID_ADDRESS();
        }

        vault = IVault(_vault);
        wETH = IwETH(_wETH);
        share = IERC20(vault.share());

        // Set the new owner
        _transferOwnership(_governor);
    }

    /**
     * @notice Wraps ETH and deposits into the Jones wETH vault
     * @dev Will revert if the contract is not whitelisted on the vault
     * @param _receiver The address that will receive the shares
     */
    function deposit(address _receiver) public payable virtual nonReentrant {
        _senderIsEligible();

        if (msg.value == 0) {
            revert INVALID_ETH_AMOUNT();
        }

        // Wrap the incoming ETH
        wETH.deposit{value: msg.value}();

        // Deposit and transfer shares to `msg.sender`
        wETH.approve(address(vault), msg.value);
        vault.deposit(msg.value, _receiver);
    }

    /**
     * @notice Redeems wETH from the Jones wETH vault and unwraps it
     * @dev Will revert fail if the contract is not whitelisted on the vault
     * @param _shares The amount of shares to burn
     * @param _receiver The address that will receive the ETH
     */
    function redeem(uint256 _shares, address _receiver)
        public
        payable
        virtual
        nonReentrant
    {
        if (_shares == 0) {
            revert INVALID_SHARES_AMOUNT();
        }

        // Transfer the `_shares` to the adapter
        share.transferFrom(msg.sender, address(this), _shares);

        // Redeem the `_shares` for `assets`
        share.approve(address(vault), _shares);
        uint256 assets = vault.redeem(_shares, address(this), address(this));

        // Unwrap the wETH
        wETH.withdraw(assets);

        // Transfer the unwrapped ETH to `_receiver`
        payable(_receiver).transfer(assets);
    }

    /**
     * @notice Updates the current vault to a new one
     * @dev Will revert if it's not called by `owner`
     * @param _newVault the address of the new vault
     */
    function updateVault(address _newVault) external onlyOwner {
        if (_newVault == address(0)) {
            revert INVALID_ADDRESS();
        }

        vault = IVault(_newVault);
        share = IERC20(vault.share());
    }

    /**
     * @notice Check if the message sender is a smart contract, if it is it will check if the
     * address is whitelisted on the vault contract
     * @dev This is needed because the adapter will be whitelisted so it can be used by other
     * contracts to bypass the vault whitelist
     */
    function _senderIsEligible() internal view {
        if (msg.sender != tx.origin) {
            if (!vault.whitelistedContract(msg.sender)) {
                revert UNAUTHORIZED();
            }
        }
    }

    receive() external payable {}

    /**
     * Used just in case someone sends ETH by mistake to the adapter.
     * @param _to user to send the funds
     * @param _amount amount to send
     */
    function emergencyReturn(address _to, uint256 _amount) external onlyOwner {
        payable(_to).transfer(_amount);
    }

    error INVALID_ETH_AMOUNT();
    error INVALID_SHARES_AMOUNT();
    error UNAUTHORIZED();
    error INVALID_ADDRESS();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IwETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
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