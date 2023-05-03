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

import "./interfaces/core/IManager.sol";

import "./libraries/OperationsLib.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract holding configuration for everything
/// @author Cosmin Grigore (@gcosmintech)
// solhint-disable-next-line max-states-count
contract Manager is IManager, Ownable {
    /// @notice returns holding manager address
    address public override holdingManager;

    /// @notice returns holding manager address
    address public override liquidationManager;

    /// @notice returns stablecoin manager address
    address public override stablesManager;

    /// @notice returns the available strategy manager
    address public override strategyManager;

    /// @notice returns the available dex manager
    address public override dexManager;

    /// @notice returns the protocol token address
    address public override protocolToken;

    /// @notice returns the default performance fee
    uint256 public override performanceFee = 1500; //15%

    /// @notice returns the fee address
    address public override feeAddress;

    /// @notice returns the address of the ReceiptTokenFactory
    address public override receiptTokenFactory;

    /// @notice returns the address of the LiquidityGaugeFactory
    address public override liquidityGaugeFactory;

    /// @notice USDC address
    // solhint-disable-next-line var-name-mixedcase
    address public immutable override USDC;

    /// @notice WETH address
    // solhint-disable-next-line var-name-mixedcase
    address public immutable override WETH;

    /// @notice Fee for withdrawing from a holding
    /// @dev 2 decimals precission so 500 == 5%
    uint256 public override withdrawalFee;

    /// @notice the % amount a liquidator gets
    uint256 public override liquidatorBonus;

    /// @notice the % amount the protocol gets when a liquidation operation happens
    uint256 public override liquidationFee;

    /// @notice returns vault address
    address public override vault;

    /// @notice returns true/false for contracts' whitelist status
    mapping(address => bool) public override isContractWhitelisted;

    /// @notice returns true if token is whitelisted
    mapping(address => bool) public override isTokenWhitelisted;

    /// @notice returns true if the token cannot be withdrawn from a holding
    mapping(address => bool) public override isTokenNonWithdrawable;

    /// @notice returns whitelisted components
    mapping(address => bool) public override allowedInvokers;

    /// @notice represents the collateral rate precision
    /// @dev should be less than exchange rate precision due to optimization in math
    uint256 public constant override PRECISION = 1e5;
    /// @notice exchange rate precision
    uint256 public constant override EXCHANGE_RATE_PRECISION = 1e18;

    /// @notice creates a new Manager contract
    /// @param _usdc the USDC address
    constructor(address _usdc, address _weth) {
        require(_usdc != address(0), "3000");
        require(_weth != address(0), "3000");
        USDC = _usdc;
        WETH = _weth;
    }

    /// @notice Sets the liquidator bonus
    /// @param _val The new value
    function setLiquidatorBonus(uint256 _val) external override onlyOwner {
        require(_val <= PRECISION, "3066");
        emit LiquidatorBonusUpdated(liquidatorBonus, _val);
        liquidatorBonus = _val;
    }

    /// @notice Sets the liquidator bonus
    /// @param _val The new value
    function setLiquidationFee(uint256 _val) external override onlyOwner {
        require(_val <= PRECISION, "3066");
        emit LiquidationFeeUpdated(liquidationFee, _val);
        liquidationFee = _val;
    }

    /// @notice sets invoker as allowed or forbidden
    /// @param _component invoker's address
    /// @param _allowed true/false
    function updateInvoker(address _component, bool _allowed)
        external
        override
        onlyOwner
        validAddress(_component)
    {
        allowedInvokers[_component] = _allowed;
        emit InvokerUpdated(_component, _allowed);
    }

    /// @notice Sets the vault address
    /// @param _val The address of the receiver.
    function setVault(address _val)
        external
        override
        onlyOwner
        validAddress(_val)
    {
        require(vault != _val, "3017");
        emit VaultUpdated(vault, _val);
        vault = _val;
    }

    /// @notice Sets the global fee address
    /// @param _val The address of the receiver.
    function setFeeAddress(address _val)
        external
        override
        onlyOwner
        validAddress(_val)
    {
        require(feeAddress != _val, "3017");
        emit FeeAddressUpdated(feeAddress, _val);
        feeAddress = _val;
    }

    /// @notice updates the strategy manager address
    /// @param _manager liquidation manager's address
    function setLiquidationManager(address _manager)
        external
        override
        onlyOwner
        validAddress(_manager)
    {
        require(liquidationManager != _manager, "3017");
        emit LiquidationManagerUpdated(liquidationManager, _manager);
        liquidationManager = _manager;
    }

    /// @notice updates the strategy manager address
    /// @param _strategy strategy manager's address
    function setStrategyManager(address _strategy)
        external
        override
        onlyOwner
        validAddress(_strategy)
    {
        require(strategyManager != _strategy, "3017");
        emit StrategyManagerUpdated(strategyManager, _strategy);
        strategyManager = _strategy;
    }

    /// @notice updates the dex manager address
    /// @param _dex dex manager's address
    function setDexManager(address _dex)
        external
        override
        onlyOwner
        validAddress(_dex)
    {
        require(dexManager != _dex, "3017");
        emit DexManagerUpdated(dexManager, _dex);
        dexManager = _dex;
    }

    /// @notice sets the holding manager address
    /// @param _holding strategy's address
    function setHoldingManager(address _holding)
        external
        override
        onlyOwner
        validAddress(_holding)
    {
        require(holdingManager != _holding, "3017");
        emit HoldingManagerUpdated(holdingManager, _holding);
        holdingManager = _holding;
    }

    /// @notice sets the stablecoin manager address
    /// @param _stables strategy's address
    function setStablecoinManager(address _stables)
        external
        override
        onlyOwner
        validAddress(_stables)
    {
        require(stablesManager != _stables, "3017");
        emit StablecoinManagerUpdated(stablesManager, _stables);
        stablesManager = _stables;
    }

    /// @notice sets the protocol token address
    /// @param _protocolToken protocol token address
    function setProtocolToken(address _protocolToken)
        external
        override
        onlyOwner
        validAddress(_protocolToken)
    {
        require(protocolToken != _protocolToken, "3017");
        emit ProtocolTokenUpdated(protocolToken, _protocolToken);
        protocolToken = _protocolToken;
    }

    /// @notice sets the performance fee
    /// @dev should be less than FEE_FACTOR
    /// @param _fee fee amount
    function setPerformanceFee(uint256 _fee)
        external
        override
        onlyOwner
        validAmount(_fee)
    {
        require(_fee < OperationsLib.FEE_FACTOR, "3018");
        emit PerformanceFeeUpdated(performanceFee, _fee);
        performanceFee = _fee;
    }

    /// @notice whitelists a contract
    /// @param _contract contract's address
    function whitelistContract(address _contract)
        external
        override
        onlyOwner
        validAddress(_contract)
    {
        require(!isContractWhitelisted[_contract], "3019");
        isContractWhitelisted[_contract] = true;
        emit ContractWhitelisted(_contract);
    }

    /// @notice removes a contract from the whitelisted list
    /// @param _contract contract's address
    function blacklistContract(address _contract)
        external
        override
        onlyOwner
        validAddress(_contract)
    {
        require(isContractWhitelisted[_contract], "1000");
        isContractWhitelisted[_contract] = false;
        emit ContractBlacklisted(_contract);
    }

    /// @notice whitelists a token
    /// @param _token token's address
    function whitelistToken(address _token)
        external
        override
        onlyOwner
        validAddress(_token)
    {
        require(!isTokenWhitelisted[_token], "3019");
        isTokenWhitelisted[_token] = true;
        emit TokenWhitelisted(_token);
    }

    /// @notice removes a token from whitelist
    /// @param _token token's address
    function removeToken(address _token)
        external
        override
        onlyOwner
        validAddress(_token)
    {
        require(isTokenWhitelisted[_token], "1000");
        isTokenWhitelisted[_token] = false;
        emit TokenRemoved(_token);
    }

    /// @notice adds a token to the mapping of non-withdrawable tokens
    /// @param _token the token to be marked as non-withdrawable
    function addNonWithdrawableToken(address _token)
        external
        override
        validAddress(_token)
    {
        require(owner() == msg.sender || strategyManager == msg.sender, "1000");
        require(!isTokenNonWithdrawable[_token], "3069");
        isTokenNonWithdrawable[_token] = true;
        emit NonWithdrawableTokenAdded(_token);
    }

    /// @notice removes a token from the mapping of non-withdrawable tokens
    /// @param _token the token to be marked as withdrawable
    function removeNonWithdrawableToken(address _token)
        external
        override
        onlyOwner
        validAddress(_token)
    {
        require(isTokenNonWithdrawable[_token], "3070");
        isTokenNonWithdrawable[_token] = false;
        emit NonWithdrawableTokenRemoved(_token);
    }

    /// @notice sets the receipt token factory address
    /// @param _factory receipt token factory address
    function setReceiptTokenFactory(address _factory)
        external
        override
        onlyOwner
        validAddress(_factory)
    {
        require(receiptTokenFactory != _factory, "3017");
        emit ReceiptTokenFactoryUpdated(receiptTokenFactory, _factory);
        receiptTokenFactory = _factory;
    }

    /// @notice sets the liquidity factory address
    /// @param _factory liquidity factory address
    function setLiquidityGaugeFactory(address _factory)
        external
        override
        onlyOwner
        validAddress(_factory)
    {
        require(liquidityGaugeFactory != _factory, "3017");
        emit LiquidityGaugeFactoryUpdated(liquidityGaugeFactory, _factory);
        liquidityGaugeFactory = _factory;
    }

    /// @notice sets the fee for withdrawing from a holding
    /// @param _fee fee amount
    function setWithdrawalFee(uint256 _fee) external override onlyOwner {
        require(withdrawalFee != _fee, "3017");
        require(_fee <= OperationsLib.FEE_FACTOR, "2066");
        emit WithdrawalFeeUpdated(withdrawalFee, _fee);
        withdrawalFee = _fee;
    }

    // @dev renounce ownership override to avoid losing contract's ownership
    function renounceOwnership() public pure override {
        revert("1000");
    }

    // -- modifiers --

    modifier validAddress(address _address) {
        require(_address != address(0), "3000");
        _;
    }
    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "2001");
        _;
    }
}