// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {ImmutableClone} from "joe-v2/libraries/ImmutableClone.sol";
import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "openzeppelin-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-upgradeable/access/Ownable2StepUpgradeable.sol";
import {StringsUpgradeable} from "openzeppelin-upgradeable/utils/StringsUpgradeable.sol";

import {IStrategy} from "./interfaces/IStrategy.sol";
import {IBaseVault} from "./interfaces/IBaseVault.sol";
import {IOracleVault} from "./interfaces/IOracleVault.sol";
import {IVaultFactory} from "./interfaces/IVaultFactory.sol";
import {IAggregatorV3} from "./interfaces/IAggregatorV3.sol";

/**
 * @title Liquidity Book Vault Factory contract
 * @author Trader Joe
 * @notice This contract is used to deploy new vaults. It is made to be used with the transparent proxy pattern.
 * The vaults are deployed using the ImmutableClone library that allows to deploy a clone of a contract
 * and initialize it with immutable data.
 * Two vaults are available:
 * - SimpleVault: This vault is used to interact with pairs where one of the tokens has no oracle. Deposits need to be
 *                made in the same ratio as the vault's current balance.
 * - OracleVault: This vault is used to interact with pairs where both tokens have an oracle. Deposits don't need to
 *                be made in the same ratio as the vault's current balance.
 * Only one strategy is available:
 * - Strategy: This strategy allows the operator to rebalance and withdraw with no real limitation.
 */
contract VaultFactory is IVaultFactory, Ownable2StepUpgradeable {
    using StringsUpgradeable for uint256;

    address private immutable _wnative;

    mapping(VaultType => address[]) private _vaults;
    mapping(StrategyType => address[]) private _strategies;

    mapping(address => VaultType) private _vaultType;
    mapping(address => StrategyType) private _strategyType;

    mapping(VaultType => address) private _vaultImplementation;
    mapping(StrategyType => address) private _strategyImplementation;

    address private _feeRecipient;
    address private _defaultOperator;

    /**
     * @dev Modifier to check if the type id is valid.
     * @param typeId The type id to check.
     */
    modifier isValidType(uint8 typeId) {
        if (typeId == 0) revert VaultFactory__InvalidType();

        _;
    }

    /**
     * @dev Constructor of the contract.
     * @param wnative The address of the wrapped native token.
     */
    constructor(address wnative) {
        _disableInitializers();

        // safety check
        IERC20Upgradeable(wnative).balanceOf(address(this));

        _wnative = wnative;
    }

    /**
     * @dev Initialize the contract.
     * @param owner The address of the owner of the contract.
     */
    function initialize(address owner) public initializer {
        if (owner == address(0)) revert VaultFactory__InvalidOwner();

        __Ownable2Step_init();
        _transferOwnership(owner);

        _setDefaultOperator(owner);
        _setFeeRecipient(owner);
    }

    /**
     * @notice Returns the address of the wrapped native token.
     * @return The address of the wrapped native token.
     */
    function getWNative() external view override returns (address) {
        return _wnative;
    }

    /**
     * @notice Returns the address of the vault at the given index.
     * @param vType The type of the vault. (0: SimpleVault, 1: OracleVault)
     * @param index The index of the vault.
     * @return The address of the vault.
     */
    function getVaultAt(VaultType vType, uint256 index) external view override returns (address) {
        return _vaults[vType][index];
    }

    /**
     * @notice Returns the type of the vault at the given address.
     * @dev Returns 0 (VaultType.None) if the vault doesn't exist.
     * @param vault The address of the vault.
     * @return The type of the vault.
     */
    function getVaultType(address vault) external view override returns (VaultType) {
        return _vaultType[vault];
    }

    /**
     * @notice Returns the address of the strategy at the given index.
     * @param sType The type of the strategy. (0: DefaultStrategy)
     * @param index The index of the strategy.
     * @return The address of the strategy.
     */
    function getStrategyAt(StrategyType sType, uint256 index) external view override returns (address) {
        return _strategies[sType][index];
    }

    /**
     * @notice Returns the type of the strategy at the given address.
     * @dev Returns 0 (StrategyType.None) if the strategy doesn't exist.
     * @param strategy The address of the strategy.
     * @return The type of the strategy.
     */
    function getStrategyType(address strategy) external view override returns (StrategyType) {
        return _strategyType[strategy];
    }

    /**
     * @notice Returns the number of vaults of the given type.
     * @param vType The type of the vault. (0: SimpleVault, 1: OracleVault)
     * @return The number of vaults of the given type.
     */
    function getNumberOfVaults(VaultType vType) external view override returns (uint256) {
        return _vaults[vType].length;
    }

    /**
     * @notice Returns the number of strategies of the given type.
     * @param sType The type of the strategy. (0: DefaultStrategy)
     * @return The number of strategies of the given type.
     */
    function getNumberOfStrategies(StrategyType sType) external view override returns (uint256) {
        return _strategies[sType].length;
    }

    /**
     * @notice Returns the address of the default operator.
     * @return The address of the default operator.
     */
    function getDefaultOperator() external view override returns (address) {
        return _defaultOperator;
    }

    /**
     * @notice Returns the address of the fee recipient.
     * @return The address of the fee recipient.
     */
    function getFeeRecipient() external view override returns (address) {
        return _feeRecipient;
    }

    /**
     * @notice Returns the address of the vault implementation of the given type.
     * @param vType The type of the vault. (0: SimpleVault, 1: OracleVault)
     * @return The address of the vault implementation.
     */
    function getVaultImplementation(VaultType vType) external view override returns (address) {
        return _vaultImplementation[vType];
    }

    /**
     * @notice Returns the address of the strategy implementation of the given type.
     * @param sType The type of the strategy. (0: DefaultStrategy)
     * @return The address of the strategy implementation.
     */
    function getStrategyImplementation(StrategyType sType) external view override returns (address) {
        return _strategyImplementation[sType];
    }

    function batchRedeemQueuedWithdrawals(
        address[] calldata vaults,
        uint256[] calldata rounds,
        bool[] calldata withdrawNative
    ) external override {
        if (vaults.length != rounds.length || vaults.length != withdrawNative.length) {
            revert VaultFactory__InvalidLength();
        }

        for (uint256 i; i < vaults.length;) {
            if (withdrawNative[i]) IBaseVault(vaults[i]).redeemQueuedWithdrawalNative(rounds[i], msg.sender);
            else IBaseVault(vaults[i]).redeemQueuedWithdrawal(rounds[i], msg.sender);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Sets the address of the vault implementation of the given type.
     * @param vType The type of the vault. (0: SimpleVault, 1: OracleVault)
     * @param vaultImplementation The address of the vault implementation.
     */
    function setVaultImplementation(VaultType vType, address vaultImplementation) external override onlyOwner {
        _setVaultImplementation(vType, vaultImplementation);
    }

    /**
     * @notice Sets the address of the strategy implementation of the given type.
     * @param sType The type of the strategy. (0: DefaultStrategy)
     * @param strategyImplementation The address of the strategy implementation.
     */
    function setStrategyImplementation(StrategyType sType, address strategyImplementation)
        external
        override
        onlyOwner
    {
        _setStrategyImplementation(sType, strategyImplementation);
    }

    /**
     * @notice Sets the address of the default operator.
     * @param defaultOperator The address of the default operator.
     */
    function setDefaultOperator(address defaultOperator) external override onlyOwner {
        _setDefaultOperator(defaultOperator);
    }

    /**
     * @notice Sets the address of the operator of the given strategy.
     * @param strategy The address of the strategy.
     * @param operator The address of the operator.
     */
    function setOperator(IStrategy strategy, address operator) external override onlyOwner {
        strategy.setOperator(operator);
    }

    /**
     * @notice Sets the pending AUM annual fee of the given vault's strategy.
     * @param vault The address of the vault.
     * @param pendingAumAnnualFee The pending AUM annual fee.
     */
    function setPendingAumAnnualFee(IBaseVault vault, uint16 pendingAumAnnualFee) external override onlyOwner {
        vault.getStrategy().setPendingAumAnnualFee(pendingAumAnnualFee);
    }

    /**
     * @notice Resets the pending AUM annual fee of the given vault's strategy.
     * @param vault The address of the vault.
     */
    function resetPendingAumAnnualFee(IBaseVault vault) external override onlyOwner {
        vault.getStrategy().resetPendingAumAnnualFee();
    }

    /**
     * @notice Sets the address of the fee recipient.
     * @param feeRecipient The address of the fee recipient.
     */
    function setFeeRecipient(address feeRecipient) external override onlyOwner {
        _setFeeRecipient(feeRecipient);
    }

    /**
     * @notice Creates a new oracle vault and a default strategy for the given LBPair.
     * @dev The oracle vault will be linked to the default strategy.
     * @param lbPair The address of the LBPair.
     * @param dataFeedX The address of the data feed for token X.
     * @param dataFeedY The address of the data feed for token Y.
     * @return vault The address of the new vault.
     * @return strategy The address of the new strategy.
     */
    function createOracleVaultAndDefaultStrategy(ILBPair lbPair, IAggregatorV3 dataFeedX, IAggregatorV3 dataFeedY)
        external
        override
        onlyOwner
        returns (address vault, address strategy)
    {
        if (dataFeedX.decimals() != dataFeedY.decimals()) revert VaultFactory__InvalidDecimals();

        address tokenX = address(lbPair.getTokenX());
        address tokenY = address(lbPair.getTokenY());

        vault = _createOracleVault(lbPair, tokenX, tokenY, dataFeedX, dataFeedY);
        strategy = _createDefaultStrategy(vault, lbPair, tokenX, tokenY);

        _linkVaultToStrategy(IBaseVault(vault), strategy);
    }

    /**
     * @notice Creates a new simple vault and a default strategy for the given LBPair.
     * @dev The simple vault will be linked to the default strategy.
     * @param lbPair The address of the LBPair.
     * @return vault The address of the new vault.
     * @return strategy The address of the new strategy.
     */
    function createSimpleVaultAndDefaultStrategy(ILBPair lbPair)
        external
        override
        onlyOwner
        returns (address vault, address strategy)
    {
        address tokenX = address(lbPair.getTokenX());
        address tokenY = address(lbPair.getTokenY());

        vault = _createSimpleVault(lbPair, tokenX, tokenY);
        strategy = _createDefaultStrategy(vault, lbPair, tokenX, tokenY);

        _linkVaultToStrategy(IBaseVault(vault), strategy);
    }

    /**
     * @notice Creates a new simple vault for the given LBPair.
     * @param lbPair The address of the LBPair.
     * @return vault The address of the new vault.
     */
    function createSimpleVault(ILBPair lbPair) external override onlyOwner returns (address vault) {
        address tokenX = address(lbPair.getTokenX());
        address tokenY = address(lbPair.getTokenY());

        return _createSimpleVault(lbPair, tokenX, tokenY);
    }

    /**
     * @notice Creates a new oracle vault for the given LBPair.
     * @param lbPair The address of the LBPair.
     * @param dataFeedX The address of the data feed for token X.
     * @param dataFeedY The address of the data feed for token Y.
     * @return vault The address of the new vault.
     */
    function createOracleVault(ILBPair lbPair, IAggregatorV3 dataFeedX, IAggregatorV3 dataFeedY)
        external
        override
        onlyOwner
        returns (address vault)
    {
        address tokenX = address(lbPair.getTokenX());
        address tokenY = address(lbPair.getTokenY());

        return _createOracleVault(lbPair, tokenX, tokenY, dataFeedX, dataFeedY);
    }

    /**
     * @notice Creates a new default strategy for the given vault.
     * @param vault The address of the vault.
     * @return strategy The address of the new strategy.
     */
    function createDefaultStrategy(IBaseVault vault) external override onlyOwner returns (address strategy) {
        ILBPair lbPair = vault.getPair();
        address tokenX = address(lbPair.getTokenX());
        address tokenY = address(lbPair.getTokenY());

        return _createDefaultStrategy(address(vault), lbPair, tokenX, tokenY);
    }

    /**
     * @notice Links the given vault to the given strategy.
     * @param vault The address of the vault.
     * @param strategy The address of the strategy.
     */
    function linkVaultToStrategy(IBaseVault vault, address strategy) external override onlyOwner {
        if (_strategyType[strategy] == StrategyType.None) revert VaultFactory__InvalidStrategy();

        _linkVaultToStrategy(vault, strategy);
    }

    /**
     * @notice Sets the whitelist state of the given vault.
     * @param vault The address of the vault.
     * @param isWhitelisted The whitelist state.
     */
    function setWhitelistState(IBaseVault vault, bool isWhitelisted) external override onlyOwner {
        vault.setWhitelistState(isWhitelisted);
    }

    /**
     * @notice Adds addresses to the whitelist of the given vault.
     * @param vault The address of the vault.
     * @param addresses The addresses to add.
     */
    function addToWhitelist(IBaseVault vault, address[] calldata addresses) external override onlyOwner {
        vault.addToWhitelist(addresses);
    }

    /**
     * @notice Removes addresses from the whitelist of the given vault.
     * @param vault The address of the vault.
     * @param addresses The addresses to remove.
     */
    function removeFromWhitelist(IBaseVault vault, address[] calldata addresses) external override onlyOwner {
        vault.removeFromWhitelist(addresses);
    }

    /**
     * @notice Pauses the deposits of the given vault.
     * @param vault The address of the vault.
     */
    function pauseDeposits(IBaseVault vault) external override onlyOwner {
        vault.pauseDeposits();
    }

    /**
     * @notice Resumes the deposits of the given vault.
     * @param vault The address of the vault.
     */
    function resumeDeposits(IBaseVault vault) external override onlyOwner {
        vault.resumeDeposits();
    }

    /**
     * @notice Sets the vault to emergency mode.
     * @param vault The address of the vault.
     */
    function setEmergencyMode(IBaseVault vault) external override onlyOwner {
        vault.setEmergencyMode();
    }

    /**
     * @notice Recover ERC20 tokens from the given vault.
     * @param vault The address of the vault.
     * @param token The address of the token.
     * @param recipient The address of the recipient.
     * @param amount The amount of tokens to recover.
     */
    function recoverERC20(IBaseVault vault, IERC20Upgradeable token, address recipient, uint256 amount)
        external
        override
        onlyOwner
    {
        vault.recoverERC20(token, recipient, amount);
    }

    /**
     * @dev Sets the vault implementation of the given type.
     * @param vType The type of the vault.
     * @param vaultImplementation The address of the vault implementation.
     */
    function _setVaultImplementation(VaultType vType, address vaultImplementation) internal {
        _vaultImplementation[vType] = vaultImplementation;

        emit VaultImplementationSet(vType, vaultImplementation);
    }

    /**
     * @dev Sets the strategy implementation of the given type.
     * @param sType The type of the strategy.
     * @param strategyImplementation The address of the strategy implementation.
     */
    function _setStrategyImplementation(StrategyType sType, address strategyImplementation) internal {
        _strategyImplementation[sType] = strategyImplementation;

        emit StrategyImplementationSet(sType, strategyImplementation);
    }

    /**
     * @dev Returns the name of the vault of the given type and id.
     * @param vType The type of the vault.
     * @param vaultId The id of the vault.
     * @return vName The name of the vault.
     */
    function _getName(VaultType vType, uint256 vaultId) internal pure returns (string memory) {
        string memory vName;

        if (vType == VaultType.Simple) vName = "Simple";
        else if (vType == VaultType.Oracle) vName = "Oracle";
        else revert VaultFactory__InvalidType();

        return string(abi.encodePacked("Automated Pool Token - ", vName, " Vault #", vaultId.toString()));
    }

    /**
     * @dev Internal function to create a new simple vault.
     * @param lbPair The address of the LBPair.
     * @param tokenX The address of token X.
     * @param tokenY The address of token Y.
     */
    function _createSimpleVault(ILBPair lbPair, address tokenX, address tokenY) internal returns (address vault) {
        uint8 decimalsX = IERC20MetadataUpgradeable(tokenX).decimals();
        uint8 decimalsY = IERC20MetadataUpgradeable(tokenY).decimals();

        bytes memory vaultImmutableData = abi.encodePacked(lbPair, tokenX, tokenY, decimalsX, decimalsY);

        return _createVault(VaultType.Simple, lbPair, tokenX, tokenY, vaultImmutableData);
    }

    /**
     * @dev Internal function to create a new oracle vault.
     * @param lbPair The address of the LBPair.
     * @param tokenX The address of token X.
     * @param tokenY The address of token Y.
     * @param dataFeedX The address of the data feed for token X.
     * @param dataFeedY The address of the data feed for token Y.
     */
    function _createOracleVault(
        ILBPair lbPair,
        address tokenX,
        address tokenY,
        IAggregatorV3 dataFeedX,
        IAggregatorV3 dataFeedY
    ) internal returns (address vault) {
        uint8 decimalsX = IERC20MetadataUpgradeable(tokenX).decimals();
        uint8 decimalsY = IERC20MetadataUpgradeable(tokenY).decimals();

        bytes memory vaultImmutableData =
            abi.encodePacked(lbPair, tokenX, tokenY, decimalsX, decimalsY, dataFeedX, dataFeedY);

        vault = _createVault(VaultType.Oracle, lbPair, tokenX, tokenY, vaultImmutableData);

        // Safety check to ensure the oracles are set correctly
        if (IOracleVault(vault).getPrice() == 0) revert VaultFactory__InvalidOraclePrice();
    }

    /**
     * @dev Internal function to create a new vault of the given type.
     * @param vType The type of the vault.
     * @param lbPair The address of the LBPair.
     * @param tokenX The address of token X.
     * @param tokenY The address of token Y.
     * @param vaultImmutableData The immutable data to pass to the vault.
     */
    function _createVault(
        VaultType vType,
        ILBPair lbPair,
        address tokenX,
        address tokenY,
        bytes memory vaultImmutableData
    ) private isValidType(uint8(vType)) returns (address vault) {
        address vaultImplementation = _vaultImplementation[vType];
        if (vaultImplementation == address(0)) revert VaultFactory__VaultImplementationNotSet(vType);

        uint256 vaultId = _vaults[vType].length;

        bytes32 salt = keccak256(abi.encodePacked(vType, vaultId));
        vault = ImmutableClone.cloneDeterministic(vaultImplementation, vaultImmutableData, salt);

        _vaults[vType].push(vault);
        _vaultType[vault] = vType;

        IBaseVault(vault).initialize(_getName(vType, vaultId), "APT");

        emit VaultCreated(vType, vault, lbPair, vaultId, tokenX, tokenY);
    }

    /**
     * @dev Internal function to create a new default strategy for the given vault.
     * @param vault The address of the vault.
     * @param lbPair The address of the LBPair.
     * @param tokenX The address of token X.
     * @param tokenY The address of token Y.
     */
    function _createDefaultStrategy(address vault, ILBPair lbPair, address tokenX, address tokenY)
        internal
        returns (address strategy)
    {
        bytes memory strategyImmutableData = abi.encodePacked(vault, lbPair, tokenX, tokenY);

        return _createStrategy(StrategyType.Default, address(vault), lbPair, strategyImmutableData);
    }

    /**
     * @dev Internal function to create a new strategy of the given type.
     * @param sType The type of the strategy.
     * @param vault The address of the vault.
     * @param lbPair The address of the LBPair.
     * @param strategyImmutableData The immutable data to pass to the strategy.
     */
    function _createStrategy(StrategyType sType, address vault, ILBPair lbPair, bytes memory strategyImmutableData)
        internal
        isValidType(uint8(sType))
        returns (address strategy)
    {
        address strategyImplementation = _strategyImplementation[sType];
        if (strategyImplementation == address(0)) revert VaultFactory__StrategyImplementationNotSet(sType);

        uint256 strategyId = _strategies[sType].length;

        bytes32 salt = keccak256(abi.encodePacked(sType, strategyId));
        strategy = ImmutableClone.cloneDeterministic(strategyImplementation, strategyImmutableData, salt);

        _strategies[sType].push(strategy);
        _strategyType[strategy] = sType;

        IStrategy(strategy).initialize();

        emit StrategyCreated(sType, strategy, vault, lbPair, strategyId);
    }

    /**
     * @dev Internal function to set the default operator.
     * @param defaultOperator The address of the default operator.
     */
    function _setDefaultOperator(address defaultOperator) internal {
        _defaultOperator = defaultOperator;

        emit DefaultOperatorSet(msg.sender, defaultOperator);
    }

    /**
     * @dev Internal function to set the fee recipient.
     * @param feeRecipient The address of the fee recipient.
     */
    function _setFeeRecipient(address feeRecipient) internal {
        if (feeRecipient == address(0)) revert VaultFactory__InvalidFeeRecipient();

        _feeRecipient = feeRecipient;

        emit FeeRecipientSet(msg.sender, feeRecipient);
    }

    /**
     * @dev Internal function to link the given vault to the given strategy.
     * @param vault The address of the vault.
     * @param strategy The address of the strategy.
     */
    function _linkVaultToStrategy(IBaseVault vault, address strategy) internal {
        vault.setStrategy(IStrategy(strategy));
    }

    /**
     * @dev This is a gap filler to allow us to add new variables in the future without breaking
     *      the storage layout of the contract.
     */
    uint256[42] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title Liquidity Book Immutable Clone Library
 * @notice Minimal immutable proxy library.
 * @author Trader Joe
 * @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
 * @author Minimal proxy by 0age (https://github.com/0age)
 * @author Clones with immutable args by wighawag, zefram.eth, Saw-mon & Natalie
 * (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
 * @dev Minimal proxy:
 * Although the sw0nt pattern saves 5 gas over the erc-1167 pattern during runtime,
 * it is not supported out-of-the-box on Etherscan. Hence, we choose to use the 0age pattern,
 * which saves 4 gas over the erc-1167 pattern during runtime, and has the smallest bytecode.
 * @dev Clones with immutable args (CWIA):
 * The implementation of CWIA here doesn't implements a `receive()` as it is not needed for LB.
 */
library ImmutableClone {
    error DeploymentFailed();
    error PackedDataTooBig();

    /**
     * @dev Deploys a deterministic clone of `implementation` using immutable arguments encoded in `data`, with `salt`
     * @param implementation The address of the implementation
     * @param data The encoded immutable arguments
     * @param salt The salt
     */
    function cloneDeterministic(address implementation, bytes memory data, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)
            // The `creationSize` is `extraLength + 63`
            // The `runSize` is `creationSize - 10`.

            // if `extraLength` is greater than `0xffca` revert as the `creationSize` would be greater than `0xffff`.
            if gt(extraLength, 0xffca) {
                // Store the function selector of `PackedDataTooBig()`.
                mstore(0x00, 0xc8c78139)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            /**
             * ---------------------------------------------------------------------------------------------------+
             * CREATION (10 bytes)                                                                                |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                                                |
             * ---------------------------------------------------------------------------------------------------|
             * 61 runSize | PUSH2 runSize     | r         |                                                       |
             * 3d         | RETURNDATASIZE    | 0 r       |                                                       |
             * 81         | DUP2              | r 0 r     |                                                       |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                                                       |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                                                       |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code                            |
             * f3         | RETURN            |           | [0..runSize): runtime code                            |
             * ---------------------------------------------------------------------------------------------------|
             * RUNTIME (98 bytes + extraLength)                                                                   |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode   | Mnemonic       | Stack                    | Memory                                      |
             * ---------------------------------------------------------------------------------------------------|
             *                                                                                                    |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                      |                                             |
             * 3d       | RETURNDATASIZE | 0 cds                    |                                             |
             * 3d       | RETURNDATASIZE | 0 0 cds                  |                                             |
             * 37       | CALLDATACOPY   |                          | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: keep some values in stack :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | 0                        | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0                      | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0                    | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0 0                  | [0..cds): calldata                          |
             * 61 extra | PUSH2 extra    | e 0 0 0 0                | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: copy extra data to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 80       | DUP1           | e e 0 0 0 0              | [0..cds): calldata                          |
             * 60 0x35  | PUSH1 0x35     | 0x35 e e 0 0 0 0         | [0..cds): calldata                          |
             * 36       | CALLDATASIZE   | cds 0x35 e e 0 0 0 0     | [0..cds): calldata                          |
             * 39       | CODECOPY       | e 0 0 0 0                | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: delegate call to the implementation contract ::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 01       | ADD            | cds+e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | 0 cds+e 0 0 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 73 addr  | PUSH20 addr    | addr 0 cds+e 0 0 0 0     | [0..cds): calldata, [cds..cds+e): extraData |
             * 5a       | GAS            | gas addr 0 cds+e 0 0 0 0 | [0..cds): calldata, [cds..cds+e): extraData |
             * f4       | DELEGATECALL   | success 0 0              | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: copy return data to memory ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | rds success 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | rds rds success 0 0      | [0..cds): calldata, [cds..cds+e): extraData |
             * 93       | SWAP4          | 0 rds success 0 rds      | [0..cds): calldata, [cds..cds+e): extraData |
             * 80       | DUP1           | 0 0 rds success 0 rds    | [0..cds): calldata, [cds..cds+e): extraData |
             * 3e       | RETURNDATACOPY | success 0 rds            | [0..rds): returndata                        |
             *                                                                                                    |
             * 60 0x33  | PUSH1 0x33     | 0x33 success 0 rds       | [0..rds): returndata                        |
             * 57       | JUMPI          | 0 rds                    | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: revert ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd       | REVERT         |                          | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: return ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b       | JUMPDEST       | 0 rds                    | [0..rds): returndata                        |
             * f3       | RETURN         |                          | [0..rds): returndata                        |
             * ---------------------------------------------------------------------------------------------------+
             */
            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e603357fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            mstore(
                sub(data, 0x21),
                or(
                    shl(0xd8, add(extraLength, 0x35)),
                    or(shl(0x48, extraLength), 0x6100003d81600a3d39f3363d3d373d3d3d3d610000806035363936013d73)
                )
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            instance := create2(0, sub(data, 0x1f), add(extraLength, 0x3f), salt)

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
        }
    }

    /**
     * @dev Returns the initialization code hash of the clone of `implementation`
     * using immutable arguments encoded in `data`.
     * Used for mining vanity addresses with create2crunch.
     * @param implementation The address of the implementation contract.
     * @param data The encoded immutable arguments.
     * @return hash The initialization code hash.
     */
    function initCodeHash(address implementation, bytes memory data) internal pure returns (bytes32 hash) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)
            // The `creationSize` is `extraLength + 63`
            // The `runSize` is `creationSize - 10`.

            // if `extraLength` is greater than `0xffca` revert as the `creationSize` would be greater than `0xffff`.
            if gt(extraLength, 0xffca) {
                // Store the function selector of `PackedDataTooBig()`.
                mstore(0x00, 0xc8c78139)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e603357fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            mstore(
                sub(data, 0x21),
                or(
                    shl(0xd8, add(extraLength, 0x35)),
                    or(shl(0x48, extraLength), 0x6100003d81600a3d39f3363d3d373d3d3d3d610000806035363936013d73)
                )
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            hash := keccak256(sub(data, 0x1f), add(extraLength, 0x3f))

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
        }
    }

    /**
     * @dev Returns the address of the deterministic clone of
     * `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
     * @param implementation The address of the implementation.
     * @param data The immutable arguments of the implementation.
     * @param salt The salt used to compute the address.
     * @param deployer The address of the deployer.
     * @return predicted The predicted address.
     */
    function predictDeterministicAddress(address implementation, bytes memory data, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        bytes32 hash = initCodeHash(implementation, data);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /**
     * @dev Returns the address when a contract with initialization code hash,
     * `hash`, is deployed with `salt`, by `deployer`.
     * @param hash The initialization code hash.
     * @param salt The salt used to compute the address.
     * @param deployer The address of the deployer.
     * @return predicted The predicted address.
     */
    function predictDeterministicAddress(bytes32 hash, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore := mload(0x35)

            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)

            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, mBefore)
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBFactory} from "./ILBFactory.sol";
import {ILBFlashLoanCallback} from "./ILBFlashLoanCallback.sol";
import {ILBToken} from "./ILBToken.sol";

interface ILBPair is ILBToken {
    error LBPair__ZeroBorrowAmount();
    error LBPair__AddressZero();
    error LBPair__AlreadyInitialized();
    error LBPair__EmptyMarketConfigs();
    error LBPair__FlashLoanCallbackFailed();
    error LBPair__FlashLoanInsufficientAmount();
    error LBPair__InsufficientAmountIn();
    error LBPair__InsufficientAmountOut();
    error LBPair__InvalidInput();
    error LBPair__InvalidStaticFeeParameters();
    error LBPair__OnlyFactory();
    error LBPair__OnlyProtocolFeeRecipient();
    error LBPair__OutOfLiquidity();
    error LBPair__TokenNotSupported();
    error LBPair__ZeroAmount(uint24 id);
    error LBPair__ZeroAmountsOut(uint24 id);
    error LBPair__ZeroShares(uint24 id);
    error LBPair__MaxTotalFeeExceeded();

    struct MintArrays {
        uint256[] ids;
        bytes32[] amounts;
        uint256[] liquidityMinted;
    }

    event DepositedToBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event WithdrawnFromBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event CompositionFees(address indexed sender, uint24 id, bytes32 totalFees, bytes32 protocolFees);

    event CollectedProtocolFees(address indexed feeRecipient, bytes32 protocolFees);

    event Swap(
        address indexed sender,
        address indexed to,
        uint24 id,
        bytes32 amountsIn,
        bytes32 amountsOut,
        uint24 volatilityAccumulator,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event StaticFeeParametersSet(
        address indexed sender,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    );

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        uint24 activeId,
        bytes32 amounts,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event OracleLengthIncreased(address indexed sender, uint16 oracleLength);

    event ForcedDecay(address indexed sender, uint24 idReference, uint24 volatilityReference);

    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external;

    function getFactory() external view returns (ILBFactory factory);

    function getTokenX() external view returns (IERC20 tokenX);

    function getTokenY() external view returns (IERC20 tokenY);

    function getBinStep() external view returns (uint16 binStep);

    function getReserves() external view returns (uint128 reserveX, uint128 reserveY);

    function getActiveId() external view returns (uint24 activeId);

    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);

    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);

    function getProtocolFees() external view returns (uint128 protocolFeeX, uint128 protocolFeeY);

    function getStaticFeeParameters()
        external
        view
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        );

    function getVariableFeeParameters()
        external
        view
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate);

    function getOracleParameters()
        external
        view
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp);

    function getOracleSampleAt(uint40 lookupTimestamp)
        external
        view
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed);

    function getPriceFromId(uint24 id) external view returns (uint256 price);

    function getIdFromPrice(uint256 price) external view returns (uint24 id);

    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);

    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data) external;

    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted);

    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        returns (bytes32[] memory amounts);

    function collectProtocolFees() external returns (bytes32 collectedProtocolFees);

    function increaseOracleLength(uint16 newLength) external;

    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function forceDecay() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {IOneInchRouter} from "./IOneInchRouter.sol";
import {IVaultFactory} from "./IVaultFactory.sol";

/**
 * @title Strategy Interface
 * @author Trader Joe
 * @notice Interface used to interact with Liquidity Book Vaults' Strategies
 */
interface IStrategy {
    error Strategy__OnlyFactory();
    error Strategy__OnlyVault();
    error Strategy__OnlyOperators();
    error Strategy__ZeroAmounts();
    error Strategy__InvalidAmount();
    error Strategy__InvalidToken();
    error Strategy__InvalidReceiver();
    error Strategy__InvalidRange();
    error Strategy__InvalidFee();
    error Strategy__ActiveIdSlippage();
    error Strategy__RangeAlreadySet();
    error Strategy__RangeTooWide();
    error Strategy__InvalidLength();

    event OperatorSet(address operator);

    event AumFeeCollected(
        address indexed sender, uint256 totalBalanceX, uint256 totalBalanceY, uint256 feeX, uint256 feeY
    );

    event AumAnnualFeeSet(uint256 fee);

    event PendingAumAnnualFeeSet(uint256 fee);

    event PendingAumAnnualFeeReset();

    event RangeSet(uint24 low, uint24 upper);

    function getFactory() external view returns (IVaultFactory);

    function getVault() external pure returns (address);

    function getPair() external pure returns (ILBPair);

    function getTokenX() external pure returns (IERC20Upgradeable);

    function getTokenY() external pure returns (IERC20Upgradeable);

    function getRange() external view returns (uint24 low, uint24 upper);

    function getAumAnnualFee() external view returns (uint256 aumAnnualFee);

    function getLastRebalance() external view returns (uint256 lastRebalance);

    function getPendingAumAnnualFee() external view returns (bool isSet, uint256 pendingAumAnnualFee);

    function getOperator() external view returns (address);

    function getBalances() external view returns (uint256 amountX, uint256 amountY);

    function getIdleBalances() external view returns (uint256 amountX, uint256 amountY);

    function initialize() external;

    function withdrawAll() external;

    function rebalance(
        uint24 newLower,
        uint24 newUpper,
        uint24 desiredActiveId,
        uint24 slippageActiveId,
        uint256 amountX,
        uint256 amountY,
        bytes calldata distributions
    ) external;

    function swap(address executor, IOneInchRouter.SwapDescription memory desc, bytes memory data) external;

    function setOperator(address operator) external;

    function setPendingAumAnnualFee(uint16 pendingAumAnnualFee) external;

    function resetPendingAumAnnualFee() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {IStrategy} from "./IStrategy.sol";
import {IVaultFactory} from "./IVaultFactory.sol";

/**
 * @title Base Vault Interface
 * @author Trader Joe
 * @notice Interface used to interact with Liquidity Book Vaults
 */
interface IBaseVault is IERC20Upgradeable {
    error BaseVault__AlreadyWhitelisted(address user);
    error BaseVault__BurnMinShares();
    error BaseVault__DepositsPaused();
    error BaseVault__InvalidNativeAmount();
    error BaseVault__InvalidRecipient();
    error BaseVault__InvalidShares();
    error BaseVault__InvalidStrategy();
    error BaseVault__InvalidToken();
    error BaseVault__NoNativeToken();
    error BaseVault__NoQueuedWithdrawal();
    error BaseVault__MaxSharesExceeded();
    error BaseVault__NativeTransferFailed();
    error BaseVault__NotInEmergencyMode();
    error BaseVault__NotWhitelisted(address user);
    error BaseVault__OnlyFactory();
    error BaseVault__OnlyWNative();
    error BaseVault__OnlyStrategy();
    error BaseVault__SameStrategy();
    error BaseVault__SameWhitelistState();
    error BaseVault__ZeroAmount();
    error BaseVault__ZeroShares();
    error BaseVault__InvalidRound();
    error BaseVault__Unauthorized();

    struct QueuedWithdrawal {
        mapping(address => uint256) userWithdrawals;
        uint256 totalQueuedShares;
        uint128 totalAmountX;
        uint128 totalAmountY;
    }

    event Deposited(address indexed user, uint256 amountX, uint256 amountY, uint256 shares);

    event WithdrawalQueued(address indexed sender, address indexed user, uint256 indexed round, uint256 shares);

    event WithdrawalCancelled(address indexed sender, address indexed recipient, uint256 indexed round, uint256 shares);

    event WithdrawalRedeemed(
        address indexed sender,
        address indexed recipient,
        uint256 indexed round,
        uint256 shares,
        uint256 amountX,
        uint256 amountY
    );

    event WithdrawalExecuted(uint256 indexed round, uint256 totalQueuedQhares, uint256 amountX, uint256 amountY);

    event StrategySet(IStrategy strategy);

    event WhitelistStateChanged(bool state);

    event WhitelistAdded(address[] addresses);

    event WhitelistRemoved(address[] addresses);

    event Recovered(address token, address recipient, uint256 amount);

    event DepositsPaused();

    event DepositsResumed();

    event EmergencyMode();

    event EmergencyWithdrawal(address indexed sender, uint256 shares, uint256 amountX, uint256 amountY);

    function getFactory() external view returns (IVaultFactory);

    function getPair() external view returns (ILBPair);

    function getTokenX() external view returns (IERC20Upgradeable);

    function getTokenY() external view returns (IERC20Upgradeable);

    function getStrategy() external view returns (IStrategy);

    function getAumAnnualFee() external view returns (uint256);

    function getRange() external view returns (uint24 low, uint24 upper);

    function getOperators() external view returns (address defaultOperator, address operator);

    function getBalances() external view returns (uint256 amountX, uint256 amountY);

    function previewShares(uint256 amountX, uint256 amountY)
        external
        view
        returns (uint256 shares, uint256 effectiveX, uint256 effectiveY);

    function previewAmounts(uint256 shares) external view returns (uint256 amountX, uint256 amountY);

    function isDepositsPaused() external view returns (bool);

    function isWhitelistedOnly() external view returns (bool);

    function isWhitelisted(address user) external view returns (bool);

    function getCurrentRound() external view returns (uint256 round);

    function getQueuedWithdrawal(uint256 round, address user) external view returns (uint256 shares);

    function getTotalQueuedWithdrawal(uint256 round) external view returns (uint256 totalQueuedShares);

    function getCurrentTotalQueuedWithdrawal() external view returns (uint256 totalQueuedShares);

    function getRedeemableAmounts(uint256 round, address user)
        external
        view
        returns (uint256 amountX, uint256 amountY);

    function deposit(uint256 amountX, uint256 amountY)
        external
        returns (uint256 shares, uint256 effectiveX, uint256 effectiveY);

    function depositNative(uint256 amountX, uint256 amountY)
        external
        payable
        returns (uint256 shares, uint256 effectiveX, uint256 effectiveY);

    function queueWithdrawal(uint256 shares, address recipient) external returns (uint256 round);

    function cancelQueuedWithdrawal(uint256 shares) external returns (uint256 round);

    function redeemQueuedWithdrawal(uint256 round, address recipient)
        external
        returns (uint256 amountX, uint256 amountY);

    function redeemQueuedWithdrawalNative(uint256 round, address recipient)
        external
        returns (uint256 amountX, uint256 amountY);

    function emergencyWithdraw() external;

    function executeQueuedWithdrawals() external;

    function initialize(string memory name, string memory symbol) external;

    function setStrategy(IStrategy newStrategy) external;

    function setWhitelistState(bool state) external;

    function addToWhitelist(address[] calldata addresses) external;

    function removeFromWhitelist(address[] calldata addresses) external;

    function pauseDeposits() external;

    function resumeDeposits() external;

    function setEmergencyMode() external;

    function recoverERC20(IERC20Upgradeable token, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {IStrategy} from "./IStrategy.sol";
import {IBaseVault} from "./IBaseVault.sol";
import {IAggregatorV3} from "./IAggregatorV3.sol";

/**
 * @title Oracle Vault Interface
 * @author Trader Joe
 * @notice Interface used to interact with Liquidity Book Oracle Vaults
 */
interface IOracleVault is IBaseVault {
    error OracleVault__InvalidPrice();
    error OracleVault__StalePrice();

    function getOracleX() external pure returns (IAggregatorV3 oracleX);

    function getOracleY() external pure returns (IAggregatorV3 oracleY);

    function getPrice() external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {IAggregatorV3} from "./IAggregatorV3.sol";
import {IStrategy} from "./IStrategy.sol";
import {IBaseVault} from "./IBaseVault.sol";

/**
 * @title Vault Factory Interface
 * @author Trader Joe
 * @notice Interface used to interact with the Factory for Liquidity Book Vaults
 */
interface IVaultFactory {
    error VaultFactory__VaultImplementationNotSet(VaultType vType);
    error VaultFactory__StrategyImplementationNotSet(StrategyType sType);
    error VaultFactory__InvalidType();
    error VaultFactory__InvalidOraclePrice();
    error VaultFactory__InvalidStrategy();
    error VaultFactory__InvalidFeeRecipient();
    error VaultFactory__InvalidOwner();
    error VaultFactory__InvalidLength();
    error VaultFactory__InvalidDecimals();

    enum VaultType {
        None,
        Simple,
        Oracle
    }

    enum StrategyType {
        None,
        Default
    }

    event VaultCreated(
        VaultType indexed vType,
        address indexed vault,
        ILBPair indexed lbPair,
        uint256 vaultIndex,
        address tokenX,
        address tokenY
    );

    event StrategyCreated(
        StrategyType indexed sType,
        address indexed strategy,
        address indexed vault,
        ILBPair lbPair,
        uint256 strategyIndex
    );

    event VaultImplementationSet(VaultType indexed vType, address indexed vaultImplementation);

    event StrategyImplementationSet(StrategyType indexed sType, address indexed strategyImplementation);

    event DefaultOperatorSet(address indexed sender, address indexed defaultOperator);

    event FeeRecipientSet(address indexed sender, address indexed feeRecipient);

    function getWNative() external view returns (address);

    function getVaultAt(VaultType vType, uint256 index) external view returns (address);

    function getVaultType(address vault) external view returns (VaultType);

    function getStrategyAt(StrategyType sType, uint256 index) external view returns (address);

    function getStrategyType(address strategy) external view returns (StrategyType);

    function getNumberOfVaults(VaultType vType) external view returns (uint256);

    function getNumberOfStrategies(StrategyType sType) external view returns (uint256);

    function getDefaultOperator() external view returns (address);

    function getFeeRecipient() external view returns (address);

    function getVaultImplementation(VaultType vType) external view returns (address);

    function getStrategyImplementation(StrategyType sType) external view returns (address);

    function batchRedeemQueuedWithdrawals(
        address[] calldata vaults,
        uint256[] calldata rounds,
        bool[] calldata withdrawNative
    ) external;

    function setVaultImplementation(VaultType vType, address vaultImplementation) external;

    function setStrategyImplementation(StrategyType sType, address strategyImplementation) external;

    function setDefaultOperator(address defaultOperator) external;

    function setOperator(IStrategy strategy, address operator) external;

    function setPendingAumAnnualFee(IBaseVault vault, uint16 pendingAumAnnualFee) external;

    function resetPendingAumAnnualFee(IBaseVault vault) external;

    function setFeeRecipient(address feeRecipient) external;

    function createOracleVaultAndDefaultStrategy(ILBPair lbPair, IAggregatorV3 dataFeedX, IAggregatorV3 dataFeedY)
        external
        returns (address vault, address strategy);

    function createSimpleVaultAndDefaultStrategy(ILBPair lbPair) external returns (address vault, address strategy);

    function createOracleVault(ILBPair lbPair, IAggregatorV3 dataFeedX, IAggregatorV3 dataFeedY)
        external
        returns (address vault);

    function createSimpleVault(ILBPair lbPair) external returns (address vault);

    function createDefaultStrategy(IBaseVault vault) external returns (address strategy);

    function linkVaultToStrategy(IBaseVault vault, address strategy) external;

    function setWhitelistState(IBaseVault vault, bool state) external;

    function addToWhitelist(IBaseVault vault, address[] calldata addresses) external;

    function removeFromWhitelist(IBaseVault vault, address[] calldata addresses) external;

    function pauseDeposits(IBaseVault vault) external;

    function resumeDeposits(IBaseVault vault) external;

    function setEmergencyMode(IBaseVault vault) external;

    function recoverERC20(IBaseVault vault, IERC20Upgradeable token, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Aggregator V3 Interface
 * @author Trader Joe
 * @notice Interface used to interact with Chainlink datafeeds.
 */
interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
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

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBPair} from "./ILBPair.sol";
import {IPendingOwnable} from "./IPendingOwnable.sol";

/**
 * @title Liquidity Book Factory Interface
 * @author Trader Joe
 * @notice Required interface of LBFactory contract
 */
interface ILBFactory is IPendingOwnable {
    error LBFactory__IdenticalAddresses(IERC20 token);
    error LBFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset);
    error LBFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset);
    error LBFactory__AddressZero();
    error LBFactory__LBPairAlreadyExists(IERC20 tokenX, IERC20 tokenY, uint256 _binStep);
    error LBFactory__LBPairDoesNotExist(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__LBPairNotCreated(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__FlashLoanFeeAboveMax(uint256 fees, uint256 maxFees);
    error LBFactory__BinStepTooLow(uint256 binStep);
    error LBFactory__PresetIsLockedForUsers(address user, uint256 binStep);
    error LBFactory__LBPairIgnoredIsAlreadyInTheSameState();
    error LBFactory__BinStepHasNoPreset(uint256 binStep);
    error LBFactory__PresetOpenStateIsAlreadyInTheSameState();
    error LBFactory__SameFeeRecipient(address feeRecipient);
    error LBFactory__SameFlashLoanFee(uint256 flashLoanFee);
    error LBFactory__LBPairSafetyCheckFailed(address LBPairImplementation);
    error LBFactory__SameImplementation(address LBPairImplementation);
    error LBFactory__ImplementationNotSet();

    /**
     * @dev Structure to store the LBPair information, such as:
     * binStep: The bin step of the LBPair
     * LBPair: The address of the LBPair
     * createdByOwner: Whether the pair was created by the owner of the factory
     * ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
     */
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event PresetOpenStateChanged(uint256 indexed binStep, bool indexed isOpen);

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function getMinBinStep() external pure returns (uint256);

    function getFeeRecipient() external view returns (address);

    function getMaxFlashLoanFee() external pure returns (uint256);

    function getFlashLoanFee() external view returns (uint256);

    function getLBPairImplementation() external view returns (address);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairAtIndex(uint256 id) external returns (ILBPair);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAssetAtIndex(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint256 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            bool isOpen
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getOpenBinSteps() external view returns (uint256[] memory openBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address lbPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint16 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        bool isOpen
    ) external;

    function setPresetOpenState(uint16 binStep, bool isOpen) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair lbPair) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/// @title Liquidity Book Flashloan Callback Interface
/// @author Trader Joe
/// @notice Required interface to interact with LB flash loans
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(
        address sender,
        IERC20 tokenX,
        IERC20 tokenY,
        bytes32 amounts,
        bytes32 totalFees,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title Liquidity Book Token Interface
 * @author Trader Joe
 * @notice Interface to interact with the LBToken.
 */
interface ILBToken {
    error LBToken__AddressThisOrZero();
    error LBToken__InvalidLength();
    error LBToken__SelfApproval(address owner);
    error LBToken__SpenderNotApproved(address from, address spender);
    error LBToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
    error LBToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approveForAll(address spender, bool approved) external;

    function batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external;
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
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
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
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
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IOneInchRouter {
    struct SwapDescription {
        IERC20Upgradeable srcToken;
        IERC20Upgradeable dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(address executor, SwapDescription calldata desc, bytes calldata permit, bytes calldata data)
        external
        payable
        returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title Liquidity Book Pending Ownable Interface
 * @author Trader Joe
 * @notice Required interface of Pending Ownable contract used for LBFactory
 */
interface IPendingOwnable {
    error PendingOwnable__AddressZero();
    error PendingOwnable__NoPendingOwner();
    error PendingOwnable__NotOwner();
    error PendingOwnable__NotPendingOwner();
    error PendingOwnable__PendingOwnerAlreadySet();

    event PendingOwnerSet(address indexed pendingOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
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