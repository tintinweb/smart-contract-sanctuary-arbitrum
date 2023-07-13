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
pragma solidity ^0.8.0;

/// @title Interface for a the manager contract
/// @author Cosmin Grigore (@gcosmintech)
interface IManager {
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/oracle/IOracle.sol";
import "../interfaces/core/IStablesManager.sol";
import "../interfaces/core/IManager.sol";
import "../interfaces/stablecoin/ISharesRegistry.sol";

/// @title SharesRegistry contract
/// @author Cosmin Grigore (@gcosmintech)
// solhint-disable-next-line max-states-count
contract SharesRegistry is ISharesRegistry {
    /// @notice returns the address of the manager container contract
    IManagerContainer public immutable override managerContainer;

    /// @notice collateralization rate for token
    uint256 public override collateralizationRate;

    /// @notice registry token
    address public immutable override token;

    /// @notice current owner
    address public override owner;

    /// @notice possible new owner
    /// @dev if different than `owner` an ownership transfer is in  progress and has to be accepted by the new owner
    address public override temporaryOwner;

    /// @notice borrowed amount for holding; holding > amount
    mapping(address => uint256) public override borrowed;

    /// @notice total collateral for Holding (Holding=>collateral amount)
    mapping(address => uint256) public override collateral;

    /// @notice info about the accrued data
    AccrueInfo public override accrueInfo;

    /// @notice oracle contract associated with this share registry
    IOracle public override oracle;
    address private _newOracle;
    uint256 private _newOracleTimestamp;

    /// @notice extra oracle data if needed
    bytes public oracleData;
    bytes private _newOracleData;
    uint256 private _newOracleDataTimestamp;

    /// @notice timelock amount in seconds for changing the oracle data
    uint256 public override timelockAmount = 2 * 86400; //2 days by default
    uint256 private _oldTimelock;
    uint256 private _newTimelock;
    uint256 private _newTimelockTimestamp;

    bool private _isActiveChange = false;

    /// @notice creates a SharesRegistry for a specific token
    /// @param _owner the owner of the contract
    /// @param _managerContainer contract that contains the address of the manager contract
    /// @param _token the parent token of this contract
    /// @param _oracle the oracle used to retrieve price data for this token
    /// @param _oracleData extra data for the oracle
    /// @param _collateralizationRate collateralization value
    constructor(
        address _owner,
        address _managerContainer,
        address _token,
        address _oracle,
        bytes memory _oracleData,
        uint256 _collateralizationRate
    ) {
        require(_owner != address(0), "3032");
        require(_token != address(0), "3001");
        require(_oracle != address(0), "3034");
        require(_managerContainer != address(0), "3065");
        require(_collateralizationRate > 0, "3060");

        owner = _owner;
        token = _token;
        oracle = IOracle(_oracle);
        oracleData = _oracleData;
        managerContainer = IManagerContainer(_managerContainer);
        collateralizationRate = _collateralizationRate;

        require(
            _collateralizationRate <=
                IManager(IManagerContainer(_managerContainer).manager())
                    .PRECISION(),
            "3066"
        );
    }

    // -- Owner specific methods --
    /// @notice requests a change for the oracle address
    /// @param _oracle the new oracle address
    function requestNewOracle(address _oracle) external override onlyOwner {
        require(!_isActiveChange, "1000");
        _isActiveChange = true;
        _newOracle = _oracle;
        _newOracleTimestamp = block.timestamp;
        emit NewOracleRequested(_oracle);
    }

    /// @notice updates the oracle
    function setOracle() external onlyOwner {
        require(_isActiveChange, "1000");
        require(
            _newOracleTimestamp + timelockAmount <= block.timestamp,
            "3066"
        );
        oracle = IOracle(_newOracle);
        _isActiveChange = false;
        _newOracle = address(0);
        _newOracleTimestamp = 0;
        emit OracleUpdated();
    }

    /// @notice sets an new interest per second
    /// @param _newVal the new value
    function setInterestPerSecond(uint64 _newVal) external onlyOwner {
        emit InterestUpdated(accrueInfo.INTEREST_PER_SECOND, _newVal);
        accrueInfo.INTEREST_PER_SECOND = _newVal;
    }

    /// @notice requests a timelock update
    /// @param _newVal the new value in seconds
    function requestTimelockAmountChange(uint256 _newVal) external onlyOwner {
        require(!_isActiveChange, "1000");
        require(_oldTimelock == 0, "2100");
        require(_newVal != 0, "2001");
        _isActiveChange = true;
        _oldTimelock = timelockAmount;
        _newTimelock = _newVal;
        _newTimelockTimestamp = block.timestamp;
        emit TimelockAmountUpdateRequested(_oldTimelock, _newTimelock);
    }

    /// @notice updates the timelock amount
    function acceptTimelockAmountChange() external onlyOwner {
        require(_isActiveChange, "1000");
        require(_newTimelock != 0, "2001");
        require(
            _newTimelockTimestamp + _oldTimelock <= block.timestamp,
            "3066"
        );
        timelockAmount = _newTimelock;
        emit TimelockAmountUpdated(_oldTimelock, _newTimelock);
        _oldTimelock = 0;
        _newTimelock = 0;
        _newTimelockTimestamp = 0;
    }

    /// @notice updates the colalteralization rate
    /// @param _newVal the new value
    function setCollateralizationRate(uint256 _newVal)
        external
        override
        onlyOwner
    {
        emit CollateralizationRateUpdated(collateralizationRate, _newVal);
        collateralizationRate = _newVal;
    }

    /// @notice requests a change for oracle data
    /// @param _data the new data
    function requestNewOracleData(bytes calldata _data) external onlyOwner {
        require(!_isActiveChange, "1000");
        _isActiveChange = true;
        _newOracleData = _data;
        _newOracleDataTimestamp = block.timestamp;
        emit NewOracleDataRequested(_newOracleData);
    }

    /// @notice updates the oracle data
    function setOracleData() external onlyOwner {
        require(_isActiveChange, "1000");
        require(
            _newOracleDataTimestamp + timelockAmount <= block.timestamp,
            "3066"
        );
        oracleData = _newOracleData;
        _isActiveChange = false;
        delete _newOracleData;
        _newOracleDataTimestamp = 0;
        emit OracleDataUpdated();
    }

    /// @notice initiates the ownership transferal
    /// @param _newOwner the address of the new owner
    function transferOwnership(address _newOwner) external override onlyOwner {
        require(_newOwner != owner, "3035");
        temporaryOwner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }

    /// @notice finalizes the ownership transferal process
    /// @dev must be called after `transferOwnership` was executed successfully, by the new temporary onwer
    function acceptOwnership() external override {
        require(msg.sender == temporaryOwner, "1000");
        owner = temporaryOwner;
        emit OwnershipAccepted(temporaryOwner);
        temporaryOwner = address(0);
    }

    // -- View type methods --
    /// @notice returns the up to date exchange rate
    function getExchangeRate() external view override returns (uint256) {
        (bool updated, uint256 rate) = oracle.peek(oracleData);
        require(updated, "3037");
        require(rate > 0, "2100");

        return rate;
    }

    // -- Write type methods --

    /// @notice sets a new value for borrowed
    /// @param _holding the address of the user
    /// @param _newVal the new amount
    function setBorrowed(address _holding, uint256 _newVal)
        external
        override
        onlyStableManager
    {
        emit BorrowedSet(_holding, borrowed[_holding], _newVal);
        borrowed[_holding] = _newVal;
    }

    /// @notice registers collateral for user
    /// @param _holding the address of the user
    /// @param _share the new collateral shares
    function registerCollateral(address _holding, uint256 _share)
        external
        override
        onlyStableManager
    {
        collateral[_holding] += _share;
        emit CollateralAdded(_holding, _share);
    }

    /// @notice registers a collateral removal operation
    /// @param _holding the address of the user
    /// @param _share the new collateral shares
    function unregisterCollateral(address _holding, uint256 _share)
        external
        override
        onlyStableManager
    {
        if (_share > collateral[_holding]) {
            _share = collateral[_holding];
        }
        collateral[_holding] = collateral[_holding] - _share;
        emit CollateralRemoved(_holding, _share);
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    /// @param _totalBorrow total borrow amount
    function accrue(uint256 _totalBorrow)
        public
        override
        onlyStableManager
        returns (uint256)
    {
        AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return _totalBorrow;
        }
        _accrueInfo.lastAccrued = uint64(block.timestamp);

        if (_totalBorrow == 0) {
            accrueInfo = _accrueInfo;
            return _totalBorrow;
        }

        // Accrue interest
        uint256 extraAmount = (_totalBorrow *
            _accrueInfo.INTEREST_PER_SECOND *
            elapsedTime) / 1e18;

        _totalBorrow += extraAmount;
        _accrueInfo.feesEarned += uint128(extraAmount);

        accrueInfo = _accrueInfo;
        emit Accrued(_totalBorrow, extraAmount);

        return _totalBorrow;
    }

    modifier onlyStableManager() {
        require(
            msg.sender == IManager(managerContainer.manager()).stablesManager(),
            "1000"
        );
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "1000");
        _;
    }
}