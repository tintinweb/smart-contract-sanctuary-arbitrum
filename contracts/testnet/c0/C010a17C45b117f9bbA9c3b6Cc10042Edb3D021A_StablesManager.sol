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
pragma solidity ^0.8.0;

import "./IManagerContainer.sol";
import "../ISwap.sol";

/// @title Interface for the HoldingManager contract
interface IHoldingManager {
    /// @notice emitted when a new holding is crated
    event HoldingCreated(address indexed user, address indexed holdingAddress);

    /// @notice emitted when rewards are sent to the holding contract
    event ReceivedRewards(
        address indexed holding,
        address indexed strategy,
        address indexed token,
        uint256 amount
    );

    /// @notice emitted when rewards were exchanged to another token
    event RewardsExchanged(
        address indexed holding,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice emitted when rewards are withdrawn by the user
    event RewardsWithdrawn(
        address indexed holding,
        address indexed token,
        uint256 amount
    );

    /// @notice emitted when a deposit is created
    event Deposit(
        address indexed holding,
        address indexed token,
        uint256 amount
    );

    /// @notice emitted when tokens are withdrawn from the holding
    event Withdrawal(
        address indexed holding,
        address indexed token,
        uint256 totalAmount,
        uint256 feeAmount
    );

    /// @notice event emitted when a borrow action was performed
    event Borrowed(
        address indexed holding,
        address indexed token,
        uint256 amount,
        bool mintToUser
    );

    /// @notice event emitted when a repay action was performed
    event Repayed(
        address indexed holding,
        address indexed token,
        uint256 amount,
        bool repayFromUser
    );

    /// @notice event emitted when fee is moved from liquidated holding to fee addres
    event CollateralFeeTaken(
        address token,
        address holdingFrom,
        address to,
        uint256 amount
    );

    /// @notice event emitted when borrow event happened for multiple users
    event BorrowedMultiple(
        address indexed holding,
        uint256 length,
        bool mintedToUser
    );

    /// @notice event emitted when a multiple repay operation happened
    event RepayedMultiple(
        address indexed holding,
        uint256 length,
        bool repayedFromUser
    );

    /// @notice event emitted when pause state is changed
    event PauseUpdated(bool oldVal, bool newVal);

    /// @notice event emitted when the user wraps native coin
    event NativeCoinWrapped(address user, uint256 amount);

    /// @notice event emitted when the user unwraps into native coin
    event NativeCoinUnwrapped(address user, uint256 amount);

    /// @notice data used for multiple borrow
    struct BorrowOrRepayData {
        address token;
        uint256 amount;
    }

    /// @notice returns the pause state of the contract
    function paused() external view returns (bool);

    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external;

    /// @notice returns user for holding
    function holdingUser(address holding) external view returns (address);

    /// @notice returns holding for user
    function userHolding(address _user) external view returns (address);

    /// @notice returns true if holding was created
    function isHolding(address _holding) external view returns (bool);

    /// @notice returns the address of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    // -- User specific methods --

    /// @notice deposits a whitelisted token into the holding
    /// @param _token token's address
    /// @param _amount amount to deposit
    function deposit(address _token, uint256 _amount) external;

    /// @notice wraps native coin and deposits WETH into the holding
    /// @dev this function must receive ETH in the transaction
    function wrapAndDeposit() external payable;

    /// @notice withdraws a token from the contract
    /// @param _token token user wants to withdraw
    /// @param _amount withdrawal amount
    function withdraw(address _token, uint256 _amount) external;

    /// @notice withdraws WETH from holding and unwraps it before sending it to the user
    function withdrawAndUnwrap(uint256 _amount) external;

    /// @notice mints Pandora Token
    /// @param _minter IMinter address
    /// @param _gauge gauge to mint for
    function mint(address _minter, address _gauge) external;

    /// @notice exchanges an existing token with a whitelisted one
    /// @param _dex selected dex
    /// @param _tokenIn token available in the contract
    /// @param _tokenOut token resulting from the swap operation
    /// @param _amountIn exchange amount
    /// @param _minAmountOut min amount of tokenOut to receive when the swap is performed
    /// @param _data specific amm data
    /// @return the amount obtained
    function exchange(
        ISwap _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice mints stablecoin to the user or to the holding contract
    /// @param _token collateral token
    /// @param _amount the borrowed amount
    /// @param _mintDirectlyToUser if true, bypasses the holding and mints directly to EOA account
    function borrow(
        address _token,
        uint256 _amount,
        bool _mintDirectlyToUser
    ) external;

    /// @notice borrows from multiple assets
    /// @param _data struct containing data for each collateral type
    /// @param _mintDirectlyToUser if true mints to user instead of holding
    function borrowMultiple(
        BorrowOrRepayData[] calldata _data,
        bool _mintDirectlyToUser
    ) external;

    /// @notice registers a repay operation
    /// @param _token collateral token
    /// @param _amount the repayed amount
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    function repay(
        address _token,
        uint256 _amount,
        bool _repayFromUser
    ) external;

    /// @notice repays multiple assets
    /// @param _data struct containing data for each collateral type
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    function repayMultiple(
        BorrowOrRepayData[] calldata _data,
        bool _repayFromUser
    ) external;

    /// @notice creates holding for the msg sender
    /// @dev must be called from an EOA or whitelisted contract
    function createHolding() external returns (address);

    /// @notice user wraps native coin
    /// @dev this function must receive ETH in the transaction
    function wrap() external payable;

    /// @notice user unwraps wrapped native coin
    /// @param _amount the amount to unwrap
    function unwrap(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for a the manager contract
/// @author Cosmin Grigore (@gcosmintech)
interface IManager {
    /// @notice emitted when the dex manager is set
    event DexManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the liquidation manager is set
    event LiquidationManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the strategy manager is set
    event StrategyManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the holding manager is set
    event HoldingManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the WETH is set
    event StablecoinManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the protocol token address is changed
    event ProtocolTokenUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the protocol token reward for minting is updated
    event MintingTokenRewardUpdated(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    /// @notice emitted when the max amount of available holdings is updated
    event MaxAvailableHoldingsUpdated(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    /// @notice emitted when the fee address is changed
    event FeeAddressUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the default fee is updated
    event PerformanceFeeUpdated(uint256 indexed oldFee, uint256 indexed newFee);

    /// @notice emmited when the receipt token factory is updated
    event ReceiptTokenFactoryUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emmited when the liquidity gauge factory is updated
    event LiquidityGaugeFactoryUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emmited when the liquidator's bonus is updated
    event LiquidatorBonusUpdated(uint256 oldAmount, uint256 newAmount);

    /// @notice emmited when the liquidation fee is updated
    event LiquidationFeeUpdated(uint256 oldAmount, uint256 newAmount);

    /// @notice emitted when the vault is updated
    event VaultUpdated(address indexed oldAddress, address indexed newAddress);

    /// @notice emitted when the withdraw fee is updated
    event WithdrawalFeeUpdated(uint256 indexed oldFee, uint256 indexed newFee);

    /// @notice emitted when a new contract is whitelisted
    event ContractWhitelisted(address indexed contractAddress);

    /// @notice emitted when a contract is removed from the whitelist
    event ContractBlacklisted(address indexed contractAddress);

    /// @notice emitted when a new token is whitelisted
    event TokenWhitelisted(address indexed token);

    /// @notice emitted when a new token is removed from the whitelist
    event TokenRemoved(address indexed token);

    /// @notice event emitted when a non-withdrawable token is added
    event NonWithdrawableTokenAdded(address indexed token);

    /// @notice event emitted when a non-withdrawable token is removed
    event NonWithdrawableTokenRemoved(address indexed token);

    /// @notice event emitted when invoker is updated
    event InvokerUpdated(address indexed component, bool allowed);

    /// @notice returns true/false for contracts' whitelist status
    function isContractWhitelisted(address _contract)
        external
        view
        returns (bool);

    /// @notice returns state of invoker
    function allowedInvokers(address _invoker) external view returns (bool);

    /// @notice returns true/false for token's whitelist status
    function isTokenWhitelisted(address _token) external view returns (bool);

    /// @notice returns vault address
    function vault() external view returns (address);

    /// @notice returns holding manager address
    function liquidationManager() external view returns (address);

    /// @notice returns holding manager address
    function holdingManager() external view returns (address);

    /// @notice returns stablecoin manager address
    function stablesManager() external view returns (address);

    /// @notice returns the available strategy manager
    function strategyManager() external view returns (address);

    /// @notice returns the available dex manager
    function dexManager() external view returns (address);

    /// @notice returns the protocol token address
    function protocolToken() external view returns (address);

    /// @notice returns the default performance fee
    function performanceFee() external view returns (uint256);

    /// @notice returns the fee address
    function feeAddress() external view returns (address);

    /// @notice returns the address of the ReceiptTokenFactory
    function receiptTokenFactory() external view returns (address);

    /// @notice returns the address of the LiquidityGaugeFactory
    function liquidityGaugeFactory() external view returns (address);

    /// @notice USDC address
    // solhint-disable-next-line func-name-mixedcase
    function USDC() external view returns (address);

    /// @notice WETH address
    // solhint-disable-next-line func-name-mixedcase
    function WETH() external view returns (address);

    /// @notice Fee for withdrawing from a holding
    /// @dev 2 decimals precission so 500 == 5%
    function withdrawalFee() external view returns (uint256);

    /// @notice the % amount a liquidator gets
    function liquidatorBonus() external view returns (uint256);

    /// @notice the % amount the protocol gets when a liquidation operation happens
    function liquidationFee() external view returns (uint256);

    /// @notice exchange rate precision
    // solhint-disable-next-line func-name-mixedcase
    function EXCHANGE_RATE_PRECISION() external view returns (uint256);

    /// @notice used in various operations
    // solhint-disable-next-line func-name-mixedcase
    function PRECISION() external view returns (uint256);

    /// @notice Sets the liquidator bonus
    /// @param _val The new value
    function setLiquidatorBonus(uint256 _val) external;

    /// @notice Sets the liquidator bonus
    /// @param _val The new value
    function setLiquidationFee(uint256 _val) external;

    /// @notice updates the fee address
    /// @param _fee the new address
    function setFeeAddress(address _fee) external;

    /// @notice uptes the vault address
    /// @param _vault the new address
    function setVault(address _vault) external;

    /// @notice updates the liquidation manager address
    /// @param _manager liquidation manager's address
    function setLiquidationManager(address _manager) external;

    /// @notice updates the strategy manager address
    /// @param _strategy strategy manager's address
    function setStrategyManager(address _strategy) external;

    /// @notice updates the dex manager address
    /// @param _dex dex manager's address
    function setDexManager(address _dex) external;

    /// @notice sets the holding manager address
    /// @param _holding strategy's address
    function setHoldingManager(address _holding) external;

    /// @notice sets the protocol token address
    /// @param _protocolToken protocol token address
    function setProtocolToken(address _protocolToken) external;

    /// @notice sets the stablecoin manager address
    /// @param _stables strategy's address
    function setStablecoinManager(address _stables) external;

    /// @notice sets the performance fee
    /// @param _fee fee amount
    function setPerformanceFee(uint256 _fee) external;

    /// @notice sets the fee for withdrawing from a holding
    /// @param _fee fee amount
    function setWithdrawalFee(uint256 _fee) external;

    /// @notice whitelists a contract
    /// @param _contract contract's address
    function whitelistContract(address _contract) external;

    /// @notice removes a contract from the whitelisted list
    /// @param _contract contract's address
    function blacklistContract(address _contract) external;

    /// @notice whitelists a token
    /// @param _token token's address
    function whitelistToken(address _token) external;

    /// @notice removes a token from whitelist
    /// @param _token token's address
    function removeToken(address _token) external;

    /// @notice sets invoker as allowed or forbidden
    /// @param _component invoker's address
    /// @param _allowed true/false
    function updateInvoker(address _component, bool _allowed) external;

    /// @notice returns true if the token cannot be withdrawn from a holding
    function isTokenNonWithdrawable(address _token)
        external
        view
        returns (bool);

    /// @notice adds a token to the mapping of non-withdrawable tokens
    /// @param _token the token to be marked as non-withdrawable
    function addNonWithdrawableToken(address _token) external;

    /// @notice removes a token from the mapping of non-withdrawable tokens
    /// @param _token the token to be marked as non-withdrawable
    function removeNonWithdrawableToken(address _token) external;

    /// @notice sets the receipt token factory address
    /// @param _factory receipt token factory address
    function setReceiptTokenFactory(address _factory) external;

    /// @notice sets the liquidity factory address
    /// @param _factory liquidity factory address
    function setLiquidityGaugeFactory(address _factory) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IManagerContainer {
    /// @notice emitted when the strategy manager is set
    event ManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice returns the manager address
    function manager() external view returns (address);

    /// @notice Updates the manager address
    /// @param _address The address of the manager
    function updateManager(address _address) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/RebaseLib.sol";

import "./IManagerContainer.sol";
import "../stablecoin/IPandoraUSD.sol";
import "../stablecoin/ISharesRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for stables manager
/// @author Cosmin Grigore (@gcosmintech)
interface IStablesManager {
    /// @notice event emitted when collateral was registered
    event AddedCollateral(
        address indexed holding,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when collateral was registered by the owner
    event ForceAddedCollateral(
        address indexed holding,
        address indexed token,
        uint256 amount
    );

    /// @notice event emitted when collateral was unregistered
    event RemovedCollateral(
        address indexed holding,
        address indexed token,
        uint256 amount
    );

    /// @notice event emitted when collateral was unregistered by the owner
    event ForceRemovedCollateral(
        address indexed holding,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when a borrow action was performed
    event Borrowed(address indexed holding, uint256 amount, bool mintToUser);
    /// @notice event emitted when a repay action was performed
    event Repayed(
        address indexed holding,
        uint256 amount,
        address indexed burnFrom
    );

    /// @notice event emitted when a registry is added
    event RegistryAdded(address indexed token, address indexed registry);

    /// @notice event emitted when a registry is updated
    event RegistryUpdated(address indexed token, address indexed registry);

    /// @notice event emmitted when a liquidation operation happened
    event Liquidated(
        address indexed liquidatedHolding,
        address indexed liquidator,
        address indexed token,
        uint256 obtainedCollateral,
        uint256 protocolCollateral,
        uint256 liquidatedAmount
    );

    /// @notice event emitted when data is migrated to another collateral token
    event CollateralMigrated(
        address indexed holding,
        address indexed tokenFrom,
        address indexed tokenTo,
        uint256 borrowedAmount,
        uint256 collateralTo
    );

    /// @notice emitted when an existing strategy info is updated
    event RegistryConfigUpdated(address indexed registry, bool active);

    struct ShareRegistryInfo {
        bool active;
        address deployedAt;
    }

    /// @notice event emitted when pause state is changed
    event PauseUpdated(bool oldVal, bool newVal);

    /// @notice returns the pause state of the contract
    function paused() external view returns (bool);

    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external;

    /// @notice share -> info
    function shareRegistryInfo(address _registry)
        external
        view
        returns (bool, address);

    /// @notice total borrow per token
    function totalBorrowed(address _token) external view returns (uint256);

    /// @notice returns the address of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice Pandora project stablecoin address
    function pandoraUSD() external view returns (IPandoraUSD);

    /// @notice Returns true if user is solvent for the specified token
    /// @dev the method reverts if block.timestamp - _maxTimeRange > exchangeRateUpdatedAt
    /// @param _token the token for which the check is done
    /// @param _holding the user address
    /// @return true/false
    function isSolvent(address _token, address _holding)
        external
        view
        returns (bool);

    /// @notice get liquidation info for holding and token
    /// @dev returns borrowed amount, collateral amount, collateral's value ratio, current borrow ratio, solvency status; colRatio needs to be >= borrowRaio
    /// @param _holding address of the holding to check for
    /// @param _token address of the token to check for
    function getLiquidationInfo(address _holding, address _token)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @notice migrates collateral and share to a new registry
    /// @param _holding the holding for which collateral is added
    /// @param _tokenFrom collateral token source
    /// @param _tokenTo collateral token destination
    /// @param _collateralFrom collateral amount to be removed from source
    /// @param _collateralTo collateral amount to be added to destination
    function migrateDataToRegistry(
        address _holding,
        address _tokenFrom,
        address _tokenTo,
        uint256 _collateralFrom,
        uint256 _collateralTo
    ) external;

    /// @notice registers new collateral
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function addCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice unregisters collateral
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function removeCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice unregisters collateral
    /// @dev does not check solvency status
    ///      - callable by the LiquidationManager only
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function forceRemoveCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice mints stablecoin to the user
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount the borrowed amount
    function borrow(
        address _holding,
        address _token,
        uint256 _amount,
        bool _mintDirectlyToUser
    ) external;

    /// @notice registers a repay operation
    /// @param _holding the holding for which repay is performed
    /// @param _token collateral token
    /// @param _amount the repayed pUsd amount
    /// @param _burnFrom the address to burn from
    function repay(
        address _holding,
        address _token,
        uint256 _amount,
        address _burnFrom
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISwap {
    /// @notice calculate output amount without performin a swap
    /// @param tokenIn input token address
    /// @param amountIn amount to calculate for
    /// @param data custom DEX data like swapPath for UniswapV2, tokenIndexes for Curve or tokenOut for UniswapV3
    function getOutputAmount(
        address tokenIn,
        uint256 amountIn,
        bytes calldata data
    ) external view returns (uint256 amountOut);

    /// @notice swaps 'tokenIn' with 'tokenOut'
    /// @param tokenIn input token address
    /// @param tokenOut output token address
    /// @param amountIn swap amount
    /// @param to tokenOut receiver
    /// @param amountOutMin minimum amount to be received
    /// @param data custom DEX data like swapPath for UniswapV2, tokenIndexes for Curve or deadline for UniswapV3
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address to,
        uint256 amountOutMin,
        bytes calldata data
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @dev MAKE SURE THIS HAS 10^18 decimals
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data)
        external
        returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data)
        external
        view
        returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/IManagerContainer.sol";

interface IPandoraUSD {
    /// @notice event emitted when the mint limit is updated
    event MintLimitUpdated(uint256 oldLimit, uint256 newLimit);

    /// @notice sets the manager address
    /// @param _limit the new mint limit
    function updateMintLimit(uint256 _limit) external;

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice returns the max mint limitF
    function mintLimit() external view returns (uint256);

    /// @notice mint tokens
    /// @dev no need to check if '_to' is a valid address if the '_mint' method is used
    /// @param _to address of the user receiving minted tokens
    /// @param _amount the amount to be minted
    function mint(address _to, uint256 _amount) external;

    /// @notice burns token from sender
    /// @param _amount the amount of tokens to be burnt
    function burn(uint256 _amount) external;

    /// @notice burns token from an address
    /// @param _user the user to burn it from
    /// @param _amount the amount of tokens to be burnt
    function burnFrom(address _user, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../oracle/IOracle.sol";
import "../core/IManagerContainer.sol";

/// @title Interface for SharesRegistry contract
/// @author Cosmin Grigore (@gcosmintech)
/// @dev based on MIM CauldraonV2 contract
interface ISharesRegistry {
    /// @notice event emitted when contract new ownership is accepted
    event OwnershipAccepted(address indexed newOwner);
    /// @notice event emitted when contract ownership transferal was initated
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );
    /// @notice event emitted when collateral was registered
    event CollateralAdded(address indexed user, uint256 share);
    /// @notice event emitted when collateral was unregistered
    event CollateralRemoved(address indexed user, uint256 share);
    /// @notice event emitted when exchange rate was updated
    event ExchangeRateUpdated(uint256 rate);
    /// @notice event emitted when the borrowing opening fee is updated
    event BorrowingOpeningFeeUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the liquidation mutiplier is updated
    event LiquidationMultiplierUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the collateralization rate is updated
    event CollateralizationRateUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when fees are accrued
    event FeesAccrued(uint256 amount);
    /// @notice event emitted when accrue was called
    event Accrued(uint256 updatedTotalBorrow, uint256 extraAmount);
    /// @notice oracle data updated
    event OracleDataUpdated();
    /// @notice emitted when new oracle data is requested
    event NewOracleDataRequested(bytes newData);
    /// @notice emitted when new oracle is requested
    event NewOracleRequested(address newOracle);
    /// @notice oracle updated
    event OracleUpdated();
    /// @notice event emitted when borrowed amount is set
    event BorrowedSet(address indexed _holding, uint256 oldVal, uint256 newVal);
    /// @notice event emitted when borrowed shares amount is set
    event BorrowedSharesSet(
        address indexed _holding,
        uint256 oldVal,
        uint256 newVal
    );
    // @notice event emitted when timelock amount is updated
    event TimelockAmountUpdated(uint256 oldVal, uint256 newVal);
    // @notice event emitted when a new timelock amount is requested
    event TimelockAmountUpdateRequested(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when interest per second is updated
    event InterestUpdated(uint256 oldVal, uint256 newVal);

    /// @notice accure info data
    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
        // solhint-disable-next-line var-name-mixedcase
        uint64 INTEREST_PER_SECOND;
    }

    /// @notice borrowed amount for holding; holding > amount
    function borrowed(address _holding) external view returns (uint256);

    /// @notice info about the accrued data
    function accrueInfo()
        external
        view
        returns (
            uint64,
            uint128,
            uint64
        );

    /// @notice current timelock amount
    function timelockAmount() external view returns (uint256);

    /// @notice current owner
    function owner() external view returns (address);

    /// @notice possible new owner
    /// @dev if different than `owner` an ownership transfer is in  progress and has to be accepted by the new owner
    function temporaryOwner() external view returns (address);

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice returns the token address for which this registry was created
    function token() external view returns (address);

    /// @notice oracle contract associated with this share registry
    function oracle() external view returns (IOracle);

    /// @notice returns the up to date exchange rate
    function getExchangeRate() external view returns (uint256);

    /// @notice updates the colalteralization rate
    /// @param _newVal the new value
    function setCollateralizationRate(uint256 _newVal) external;

    /// @notice collateralization rate for token
    // solhint-disable-next-line func-name-mixedcase
    function collateralizationRate() external view returns (uint256);

    /// @notice returns the collateral shares for user
    /// @param _user the address for which the query is performed
    function collateral(address _user) external view returns (uint256);

    /// @notice requests a change for the oracle address
    /// @param _oracle the new oracle address
    function requestNewOracle(address _oracle) external;

    /// @notice sets a new value for borrowed
    /// @param _holding the address of the user
    /// @param _newVal the new amount
    function setBorrowed(address _holding, uint256 _newVal) external;

    /// @notice updates the AccrueInfo object
    /// @param _totalBorrow total borrow amount
    function accrue(uint256 _totalBorrow) external returns (uint256);

    /// @notice registers collateral for token
    /// @param _holding the user's address for which collateral is registered
    /// @param _share amount of shares
    function registerCollateral(address _holding, uint256 _share) external;

    /// @notice registers a collateral removal operation
    /// @param _holding the address of the user
    /// @param _share the new collateral shares
    function unregisterCollateral(address _holding, uint256 _share) external;

    /// @notice initiates the ownership transferal
    /// @param _newOwner the address of the new owner
    function transferOwnership(address _newOwner) external;

    /// @notice finalizes the ownership transferal process
    /// @dev must be called after `transferOwnership` was executed successfully, by the new temporary onwer
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @notice common operations
library OperationsLib {
    uint256 internal constant FEE_FACTOR = 10000;

    /// @notice gets the amount used as a fee
    function getFeeAbsolute(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / FEE_FACTOR;
    }

    /// @notice retrieves ratio between 2 numbers
    function getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    /// @notice approves token for spending
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool successEmtptyApproval, ) = token.call(
            abi.encodeWithSelector(
                bytes4(keccak256("approve(address,uint256)")),
                to,
                0
            )
        );
        require(
            successEmtptyApproval,
            "OperationsLib::safeApprove: approval reset failed"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                bytes4(keccak256("approve(address,uint256)")),
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "OperationsLib::safeApprove: approve failed"
        );
    }

    /// @notice gets the revert message string
    function getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library RebaseLib {
    struct Rebase {
        uint128 elastic;
        uint128 base;
    }

    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && ((base * total.elastic) / total.base) < elastic) {
                base = base + 1;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && ((elastic * total.base) / total.elastic) < base) {
                elastic = elastic + 1;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = uint128(total.elastic + elastic);
        total.base = uint128(total.base + base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = uint128(total.elastic - elastic);
        total.base = uint128(total.base - base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = uint128(total.elastic + elastic);
        total.base = uint128(total.base + base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = uint128(total.elastic - elastic);
        total.base = uint128(total.base - base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic)
        internal
        returns (uint256 newElastic)
    {
        newElastic = total.elastic = uint128(total.elastic + elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic)
        internal
        returns (uint256 newElastic)
    {
        newElastic = total.elastic = uint128(total.elastic - elastic);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./libraries/RebaseLib.sol";
import "./libraries/OperationsLib.sol";

import "./interfaces/core/IManager.sol";
import "./interfaces/core/IHoldingManager.sol";
import "./interfaces/core/IStablesManager.sol";
import "./interfaces/stablecoin/IPandoraUSD.sol";
import "./interfaces/stablecoin/ISharesRegistry.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title StablesManager contract
/// @author Cosmin Grigore (@gcosmintech)
contract StablesManager is IStablesManager, Ownable {
    /// @notice Pandora project stablecoin address
    IPandoraUSD public immutable override pandoraUSD;

    /// @notice contract that contains the address of the manager contract
    IManagerContainer public immutable override managerContainer;

    /// @notice returns the pause state of the contract
    bool public override paused;

    /// @notice total borrow per token
    mapping(address => uint256) public override totalBorrowed;

    /// @notice returns config info for each share
    mapping(address => ShareRegistryInfo) public override shareRegistryInfo;

    // Rebase from amount to share

    /// @notice creates a new StablesManager contract
    /// @param _managerContainer contract that contains the address of the manager contract
    /// @param _pandoraUSD the protocol's stablecoin address
    constructor(address _managerContainer, address _pandoraUSD) {
        require(_managerContainer != address(0), "3065");
        require(_pandoraUSD != address(0), "3001");
        managerContainer = IManagerContainer(_managerContainer);
        pandoraUSD = IPandoraUSD(_pandoraUSD);
    }

    // -- Owner specific methods --
    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external override onlyOwner {
        emit PauseUpdated(paused, _val);
        paused = _val;
    }

    /// @notice registers a share registry contract for a token
    /// @param _registry registry contract address
    /// @param _token token address
    /// @param _active set it as active or inactive
    function registerOrUpdateShareRegistry(
        address _registry,
        address _token,
        bool _active
    ) external onlyOwner {
        require(_token != address(0), "3007");
        require(_token == ISharesRegistry(_registry).token(), "3008");

        ShareRegistryInfo memory info;
        info.active = _active;

        if (shareRegistryInfo[_token].deployedAt == address(0)) {
            info.deployedAt = _registry;
            emit RegistryAdded(_token, _registry);
        } else {
            info.deployedAt = shareRegistryInfo[_token].deployedAt;
            emit RegistryUpdated(_token, _registry);
        }

        shareRegistryInfo[_token] = info;
    }

    // -- View type methods --

    /// @notice Returns true if user is solvent for the specified token
    /// @dev the method reverts if block.timestamp - _maxTimeRange > exchangeRateUpdatedAt
    /// @param _token the token for which the check is done
    /// @param _holding the user address
    /// @return true/false
    function isSolvent(address _token, address _holding)
        public
        view
        override
        returns (bool)
    {
        require(_holding != address(0), "3031");
        ISharesRegistry registry = _getRegistry(_token);
        require(address(registry) != address(0), "3008");

        if (registry.borrowed(_holding) == 0) return true;

        return
            _getSolvencyRatio(_holding, registry) >=
            registry.borrowed(_holding);
    }

    /// @notice get liquidation info for holding and token
    /// @dev returns borrowed amount, collateral amount, collateral's value ratio, current borrow ratio, solvency status; colRatio needs to be >= borrowRaio
    /// @param _holding address of the holding to check for
    /// @param _token address of the token to check for
    function getLiquidationInfo(address _holding, address _token)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        ISharesRegistry registry = _getRegistry(_token);
        return (
            registry.borrowed(_holding),
            registry.collateral(_holding),
            _getSolvencyRatio(_holding, registry)
        );
    }

    // -- Write type methods --

    /// @notice registers new collateral
    /// @dev the amount will be transformed to shares
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of tokens to be added as collateral
    function addCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external override notPaused onlyAllowed {
        if (shareRegistryInfo[_token].deployedAt == address(0)) {
            return;
        }

        require(shareRegistryInfo[_token].active, "1201");
        _getRegistry(_token).registerCollateral(_holding, _amount);

        emit AddedCollateral(_holding, _token, _amount);
    }

    /// @notice unregisters collateral
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function removeCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external override onlyAllowed notPaused {
        if (shareRegistryInfo[_token].deployedAt == address(0)) {
            return;
        }
        require(shareRegistryInfo[_token].active, "1201");
        _getRegistry(_token).unregisterCollateral(_holding, _amount);

        // require(isSolvent(_token, _holding), "3009");
        emit RemovedCollateral(_holding, _token, _amount);
    }

    /// @notice unregisters collateral
    /// @dev does not check solvency status
    ///      - callable by the LiquidationManager only
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function forceRemoveCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external override notPaused {
        if (shareRegistryInfo[_token].deployedAt == address(0)) {
            return;
        }
        require(msg.sender == _getManager().liquidationManager(), "1000");
        require(shareRegistryInfo[_token].active, "1201");
        _getRegistry(_token).unregisterCollateral(_holding, _amount);

        emit RemovedCollateral(_holding, _token, _amount);
    }

    /// @notice migrates collateral and share to a new registry
    /// @param _holding the holding for which collateral is added
    /// @param _tokenFrom collateral token source
    /// @param _tokenTo collateral token destination
    /// @param _collateralFrom collateral amount to be removed from source
    /// @param _collateralTo collateral amount to be added to destination
    function migrateDataToRegistry(
        address _holding,
        address _tokenFrom,
        address _tokenTo,
        uint256 _collateralFrom,
        uint256 _collateralTo
    ) external override onlyAllowed notPaused {
        ISharesRegistry registryFrom = ISharesRegistry(
            shareRegistryInfo[_tokenFrom].deployedAt
        );
        ISharesRegistry registryTo = ISharesRegistry(
            shareRegistryInfo[_tokenTo].deployedAt
        );

        uint256 _migratedRatio = OperationsLib.getRatio(
            _collateralFrom,
            registryFrom.collateral(_holding),
            18
        );

        //remove collateral from source
        registryFrom.accrue(totalBorrowed[_tokenFrom]);
        registryFrom.unregisterCollateral(_holding, _collateralFrom);

        //add collateral for destination
        if (shareRegistryInfo[_tokenTo].deployedAt != address(0)) {
            registryTo.accrue(totalBorrowed[_tokenTo]);
            registryTo.registerCollateral(_holding, _collateralTo);
        }

        //migrate borrow
        uint256 _borrowedFrom = _migrateBorrow(
            registryFrom,
            registryTo,
            _holding,
            _migratedRatio
        );

        emit CollateralMigrated(
            _holding,
            _tokenFrom,
            _tokenTo,
            _borrowedFrom,
            _collateralTo
        );
    }

    /// @notice mints stablecoin to the user
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount the collateral amount used for borrowing
    /// @param _mintDirectlyToUser if true mints to user instead of holding
    function borrow(
        address _holding,
        address _token,
        uint256 _amount,
        bool _mintDirectlyToUser
    ) external override onlyAllowed notPaused {
        require(_amount > 0, "3010");
        require(shareRegistryInfo[_token].active, "1201");

        // update exchange rate and get USD value of the collateral
        ISharesRegistry registry = ISharesRegistry(
            shareRegistryInfo[_token].deployedAt
        );

        uint256 amountValue = (_transformTo18Decimals(
            _amount,
            IERC20Metadata(_token).decimals()
        ) * registry.getExchangeRate()) /
            _getManager().EXCHANGE_RATE_PRECISION();

        // update internal values
        totalBorrowed[_token] = registry.accrue(totalBorrowed[_token]);
        totalBorrowed[_token] += amountValue;
        registry.setBorrowed(
            _holding,
            registry.borrowed(_holding) + amountValue
        );

        if (!_mintDirectlyToUser) {
            pandoraUSD.mint(_holding, amountValue);
        } else {
            pandoraUSD.mint(
                _getHoldingManager().holdingUser(_holding),
                amountValue
            );
        }

        // make sure user is solvent
        require(isSolvent(_token, _holding), "3009");

        emit Borrowed(_holding, amountValue, _mintDirectlyToUser);
    }

    /// @notice registers a repay operation
    /// @param _holding the holding for which repay is performed
    /// @param _token collateral token
    /// @param _amount the repayed pUsd amount
    /// @param _burnFrom the address to burn from
    function repay(
        address _holding,
        address _token,
        uint256 _amount,
        address _burnFrom
    ) external override onlyAllowed notPaused {
        require(shareRegistryInfo[_token].active, "1201");

        ISharesRegistry registry = ISharesRegistry(
            shareRegistryInfo[_token].deployedAt
        );
        require(registry.borrowed(_holding) > 0, "3011");
        require(registry.borrowed(_holding) >= _amount, "2100");
        require(_amount > 0, "3012");

        //update internal value
        totalBorrowed[_token] = registry.accrue(totalBorrowed[_token]);
        totalBorrowed[_token] -= _amount;
        registry.setBorrowed(_holding, registry.borrowed(_holding) - _amount);

        //burn pUsd
        if (_burnFrom != address(0)) {
            pandoraUSD.burnFrom(_burnFrom, _amount);
        }

        emit Repayed(_holding, _amount, _burnFrom);
    }

    // @dev renounce ownership override to avoid losing contract's ownership
    function renounceOwnership() public pure override {
        revert("1000");
    }

    // -- Private methods --
    function _transformTo18Decimals(uint256 _amount, uint256 _decimals)
        private
        pure
        returns (uint256)
    {
        uint256 result = _amount;

        if (_decimals < 18) {
            result = result * (10**(18 - _decimals));
        } else if (_decimals > 18) {
            result = result / (10**(_decimals - 18));
        }

        return result;
    }

    function _migrateBorrow(
        ISharesRegistry _registryFrom,
        ISharesRegistry _registryTo,
        address _holding,
        uint256 _migratedRatio
    ) private returns (uint256 _borrowedFrom) {
        _borrowedFrom = 0;
        if (address(_registryFrom) != address(0)) {
            _borrowedFrom =
                (_registryFrom.borrowed(_holding) * _migratedRatio) /
                1e18;
        }

        //remove borrow data from source
        if (_borrowedFrom > 0) {
            _registryFrom.setBorrowed(
                _holding,
                _registryFrom.borrowed(_holding) - _borrowedFrom
            );
            totalBorrowed[_registryFrom.token()] -= _borrowedFrom;
        }

        if (address(_registryTo) != address(0)) {
            //add borrow data to destination
            if (_borrowedFrom > 0) {
                ISharesRegistry registryTo = ISharesRegistry(
                    shareRegistryInfo[_registryTo.token()].deployedAt
                );

                registryTo.setBorrowed(
                    _holding,
                    _borrowedFrom + registryTo.borrowed(_holding)
                );
                totalBorrowed[registryTo.token()] += _borrowedFrom;
            }
        }
    }

    function _getSolvencyRatio(address _holding, ISharesRegistry registry)
        private
        view
        returns (uint256)
    {
        uint256 _colRate = registry.collateralizationRate();
        uint256 _exchangeRate = registry.getExchangeRate();

        uint256 _result = ((1e18 *
            registry.collateral(_holding) *
            _exchangeRate *
            _colRate) /
            (_getManager().EXCHANGE_RATE_PRECISION() *
                _getManager().PRECISION())) / 1e18;

        _result = _transformTo18Decimals(
            _result,
            IERC20Metadata(registry.token()).decimals()
        );

        return _result;
    }

    function _getRegistry(address _token)
        private
        view
        returns (ISharesRegistry)
    {
        return ISharesRegistry(shareRegistryInfo[_token].deployedAt);
    }

    function _getManager() private view returns (IManager) {
        return IManager(managerContainer.manager());
    }

    function _getHoldingManager() private view returns (IHoldingManager) {
        return IHoldingManager(_getManager().holdingManager());
    }

    // -- modifiers --
    modifier onlyAllowed() {
        require(
            msg.sender == _getManager().holdingManager() ||
                msg.sender == _getManager().liquidationManager() ||
                msg.sender == _getManager().strategyManager(),
            "1000"
        );
        _;
    }

    modifier notPaused() {
        require(!paused, "1200");
        _;
    }
}