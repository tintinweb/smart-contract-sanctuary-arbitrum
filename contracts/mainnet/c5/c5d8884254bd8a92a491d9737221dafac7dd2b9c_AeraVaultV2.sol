// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/ERC165.sol";
import "@openzeppelin/ERC165Checker.sol";
import "@openzeppelin/IERC4626.sol";
import "@openzeppelin/Math.sol";
import "@openzeppelin/Ownable2Step.sol";
import "@openzeppelin/Pausable.sol";
import "@openzeppelin/ReentrancyGuard.sol";
import "@openzeppelin/SafeERC20.sol";
import "./interfaces/IAeraV2Factory.sol";
import "./interfaces/IHooks.sol";
import "./interfaces/IVault.sol";
import {ONE} from "./Constants.sol";

/// @title AeraVaultV2.
/// @notice Aera Vault V2 Vault contract.
contract AeraVaultV2 is
    IVault,
    ERC165,
    Ownable2Step,
    Pausable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    /// @notice Largest possible fee earned proportion per one second.
    /// @dev 0.0000001% per second, i.e. 3.1536% per year.
    ///      0.0000001% * (365 * 24 * 60 * 60) = 3.1536%
    ///      or 3.16224% per year in leap years.
    uint256 private constant _MAX_FEE = 10 ** 9;

    /// @notice Number of decimals for fee token.
    uint256 private immutable _feeTokenDecimals;

    /// @notice Number of decimals for numeraire token.
    uint256 private immutable _numeraireTokenDecimals;

    /// @notice Fee token used by asset registry.
    IERC20 private immutable _feeToken;

    /// @notice Fee per second in 18 decimal fixed point format.
    uint256 public immutable fee;

    /// @notice Asset registry address.
    IAssetRegistry public immutable assetRegistry;

    /// @notice The address of wrapped native token.
    address public immutable wrappedNativeToken;

    /// STORAGE ///

    /// @notice Hooks module address.
    IHooks public hooks;

    /// @notice Guardian address.
    address public guardian;

    /// @notice Fee recipient address.
    address public feeRecipient;

    /// @notice True if vault has been finalized.
    bool public finalized;

    /// @notice Last measured value of assets in vault.
    uint256 public lastValue;

    /// @notice Last spot price of fee token.
    uint256 public lastFeeTokenPrice;

    /// @notice Fee earned amount for each prior fee recipient.
    mapping(address => uint256) public fees;

    /// @notice Total fee earned and unclaimed amount by all fee recipients.
    uint256 public feeTotal;

    /// @notice Last timestamp when fee index was reserved.
    uint256 public lastFeeCheckpoint;

    /// MODIFIERS ///

    /// @dev Throws if called by any account other than the owner or guardian.
    modifier onlyOwnerOrGuardian() {
        if (msg.sender != owner() && msg.sender != guardian) {
            revert Aera__CallerIsNotOwnerAndGuardian();
        }
        _;
    }

    /// @dev Throws if called by any account other than the guardian.
    modifier onlyGuardian() {
        if (msg.sender != guardian) {
            revert Aera__CallerIsNotGuardian();
        }
        _;
    }

    /// @dev Throws if called after the vault is finalized.
    modifier whenNotFinalized() {
        if (finalized) {
            revert Aera__VaultIsFinalized();
        }
        _;
    }

    /// @dev Throws if hooks is not set
    modifier whenHooksSet() {
        if (address(hooks) == address(0)) {
            revert Aera__HooksIsZeroAddress();
        }
        _;
    }

    /// @dev Calculate current guardian fees.
    modifier reserveFees() {
        _reserveFees();
        _;
    }

    /// @dev Check insolvency of fee token was not made worse.
    modifier checkReservedFees() {
        uint256 prevFeeTokenBalance =
            IERC20(_feeToken).balanceOf(address(this));
        _;
        _checkReservedFees(prevFeeTokenBalance);
    }

    /// FUNCTIONS ///

    constructor() Ownable() ReentrancyGuard() {
        (
            address owner_,
            address assetRegistry_,
            address hooks_,
            address guardian_,
            address feeRecipient_,
            uint256 fee_
        ) = IAeraV2Factory(msg.sender).parameters();

        // Requirements: check provided addresses.
        _checkAssetRegistryAddress(assetRegistry_);
        _checkHooksAddress(hooks_);
        _checkGuardianAddress(guardian_, owner_);
        _checkFeeRecipientAddress(feeRecipient_, owner_);

        // Requirements: check that initial owner is not zero address.
        if (owner_ == address(0)) {
            revert Aera__InitialOwnerIsZeroAddress();
        }
        // Requirements: check if fee is within bounds.
        if (fee_ > _MAX_FEE) {
            revert Aera__FeeIsAboveMax(fee_, _MAX_FEE);
        }

        // Effects: initialize vault state.
        wrappedNativeToken = IAeraV2Factory(msg.sender).wrappedNativeToken();
        assetRegistry = IAssetRegistry(assetRegistry_);
        hooks = IHooks(hooks_);
        guardian = guardian_;
        feeRecipient = feeRecipient_;
        fee = fee_;
        lastFeeCheckpoint = block.timestamp;

        // Effects: cache numeraire and fee token decimals.
        _feeToken = IAssetRegistry(assetRegistry_).feeToken();
        _feeTokenDecimals = IERC20Metadata(address(_feeToken)).decimals();
        _numeraireTokenDecimals =
            IERC20Metadata(address(assetRegistry.numeraireToken())).decimals();

        // Effects: set new owner.
        _transferOwnership(owner_);

        // Effects: pause vault.
        _pause();

        // Log setting of asset registry.
        emit SetAssetRegistry(assetRegistry_);

        // Log new hooks address.
        emit SetHooks(hooks_);

        // Log the current guardian and fee recipient.
        emit SetGuardianAndFeeRecipient(guardian_, feeRecipient_);
    }

    /// @inheritdoc IVault
    function deposit(AssetValue[] calldata amounts)
        external
        override
        nonReentrant
        onlyOwner
        whenHooksSet
        whenNotFinalized
        reserveFees
    {
        // Hooks: before transferring assets.
        hooks.beforeDeposit(amounts);

        // Requirements: check that provided amounts are sorted by asset and unique.
        _checkAmountsSorted(amounts);

        IAssetRegistry.AssetInformation[] memory assets =
            assetRegistry.assets();

        uint256 numAmounts = amounts.length;
        AssetValue memory assetValue;
        bool isRegistered;

        for (uint256 i = 0; i < numAmounts;) {
            assetValue = amounts[i];
            (isRegistered,) = _isAssetRegistered(assetValue.asset, assets);

            // Requirements: check that deposited assets are registered.
            if (!isRegistered) {
                revert Aera__AssetIsNotRegistered(assetValue.asset);
            }

            // Interactions: transfer asset from owner to vault.
            assetValue.asset.safeTransferFrom(
                msg.sender, address(this), assetValue.value
            );

            unchecked {
                i++; // gas savings
            }

            // Log deposit for this asset.
            emit Deposit(msg.sender, assetValue.asset, assetValue.value);
        }

        // Hooks: after transferring assets.
        hooks.afterDeposit(amounts);
    }

    /// @inheritdoc IVault
    function withdraw(AssetValue[] calldata amounts)
        external
        override
        nonReentrant
        onlyOwner
        whenHooksSet
        whenNotFinalized
        reserveFees
    {
        IAssetRegistry.AssetInformation[] memory assets =
            assetRegistry.assets();

        // Requirements: check the withdraw request.
        _checkWithdrawRequest(assets, amounts);

        // Requirements: check that provided amounts are sorted by asset and unique.
        _checkAmountsSorted(amounts);

        // Hooks: before transferring assets.
        hooks.beforeWithdraw(amounts);

        uint256 numAmounts = amounts.length;
        AssetValue memory assetValue;

        for (uint256 i = 0; i < numAmounts;) {
            assetValue = amounts[i];

            if (assetValue.value == 0) {
                unchecked {
                    i++; // gas savings
                }

                continue;
            }

            // Interactions: withdraw assets.
            assetValue.asset.safeTransfer(msg.sender, assetValue.value);

            // Log withdrawal for this asset.
            emit Withdraw(msg.sender, assetValue.asset, assetValue.value);

            unchecked {
                i++; // gas savings
            }
        }

        // Hooks: after transferring assets.
        hooks.afterWithdraw(amounts);
    }

    /// @inheritdoc IVault
    function setGuardianAndFeeRecipient(
        address newGuardian,
        address newFeeRecipient
    ) external override onlyOwner whenNotFinalized reserveFees {
        // Requirements: check guardian and fee recipient addresses.
        _checkGuardianAddress(newGuardian, msg.sender);
        _checkFeeRecipientAddress(newFeeRecipient, msg.sender);

        // Effects: update guardian and fee recipient addresses.
        guardian = newGuardian;
        // slither-disable-next-line missing-zero-check
        feeRecipient = newFeeRecipient;

        // Log new guardian and fee recipient addresses.
        emit SetGuardianAndFeeRecipient(newGuardian, newFeeRecipient);
    }

    /// @inheritdoc IVault
    function setHooks(address newHooks)
        external
        override
        nonReentrant
        onlyOwner
        whenNotFinalized
        reserveFees
    {
        // Requirements: validate hooks address.
        _checkHooksAddress(newHooks);

        // Effects: decommission old hooks contract.
        if (address(hooks) != address(0)) {
            hooks.decommission();
        }

        // Effects: set new hooks address.
        hooks = IHooks(newHooks);

        // Log new hooks address.
        emit SetHooks(newHooks);
    }

    /// @inheritdoc IVault
    /// @dev reserveFees modifier is not used to avoid reverts.
    function execute(Operation calldata operation)
        external
        override
        nonReentrant
        onlyOwner
    {
        // Requirements: check that the target contract is not hooks.
        if (operation.target == address(hooks)) {
            revert Aera__ExecuteTargetIsHooksAddress();
        }
        // Requirements: check that the target contract is not vault itself.
        if (operation.target == address(this)) {
            revert Aera__ExecuteTargetIsVaultAddress();
        }

        // Interactions: execute operation.
        (bool success, bytes memory result) =
            operation.target.call{value: operation.value}(operation.data);

        // Invariants: check that the operation was successful.
        if (!success) {
            revert Aera__ExecutionFailed(result);
        }

        // Log that the operation was executed.
        emit Executed(msg.sender, operation);
    }

    /// @inheritdoc IVault
    function finalize()
        external
        override
        nonReentrant
        onlyOwner
        whenHooksSet
        whenNotFinalized
        reserveFees
    {
        // Hooks: before finalizing.
        hooks.beforeFinalize();

        // Effects: mark the vault as finalized.
        finalized = true;

        IAssetRegistry.AssetInformation[] memory assets =
            assetRegistry.assets();
        AssetValue[] memory assetAmounts = _getHoldings(assets);
        uint256 numAssetAmounts = assetAmounts.length;

        for (uint256 i = 0; i < numAssetAmounts;) {
            // Effects: transfer registered assets to owner.
            // Excludes reserved fee tokens and native token (e.g., ETH).
            if (assetAmounts[i].value > 0) {
                assetAmounts[i].asset.safeTransfer(
                    msg.sender, assetAmounts[i].value
                );
            }
            unchecked {
                i++; // gas savings
            }
        }

        // Hooks: after finalizing.
        hooks.afterFinalize();

        // Log finalization.
        emit Finalized(msg.sender, assetAmounts);
    }

    /// @inheritdoc IVault
    function pause()
        external
        override
        nonReentrant
        onlyOwnerOrGuardian
        whenNotFinalized
        reserveFees
    {
        // Requirements and Effects: checks contract is unpaused and pauses it.
        _pause();
    }

    /// @inheritdoc IVault
    function resume()
        external
        override
        onlyOwner
        whenHooksSet
        whenNotFinalized
    {
        // Effects: start a new fee checkpoint.
        lastFeeCheckpoint = block.timestamp;

        // Requirements and Effects: checks contract is paused and unpauses it.
        _unpause();
    }

    /// @inheritdoc IVault
    function submit(Operation[] calldata operations)
        external
        override
        nonReentrant
        onlyGuardian
        whenHooksSet
        whenNotFinalized
        whenNotPaused
        reserveFees
        checkReservedFees
    {
        // Hooks: before executing operations.
        hooks.beforeSubmit(operations);

        uint256 numOperations = operations.length;

        Operation calldata operation;
        bytes4 selector;
        bool success;
        bytes memory result;
        address hooksAddress = address(hooks);

        for (uint256 i = 0; i < numOperations;) {
            operation = operations[i];
            selector = bytes4(operation.data[0:4]);

            // Requirements: validate that it doesn't transfer asset from owner.
            if (
                selector == IERC20.transferFrom.selector
                    && abi.decode(operation.data[4:], (address)) == owner()
            ) {
                revert Aera__SubmitTransfersAssetFromOwner();
            }

            // Requirements: check that operation is not trying to redeem ERC4626 shares from owner.
            // This could occur if the owner had a pre-existing allowance introduced during deposit.
            if (
                selector == IERC4626.withdraw.selector
                    || selector == IERC4626.redeem.selector
            ) {
                (,, address assetOwner) =
                    abi.decode(operation.data[4:], (uint256, address, address));

                if (assetOwner == owner()) {
                    revert Aera__SubmitRedeemERC4626AssetFromOwner();
                }
            }

            // Requirements: check that the target contract is not hooks.
            if (operation.target == hooksAddress) {
                revert Aera__SubmitTargetIsHooksAddress(i);
            }
            // Requirements: check that the target contract is not vault itself.
            if (operation.target == address(this)) {
                revert Aera__SubmitTargetIsVaultAddress();
            }

            // Interactions: execute operation.
            (success, result) =
                operation.target.call{value: operation.value}(operation.data);

            // Invariants: confirm that operation succeeded.
            if (!success) {
                revert Aera__SubmissionFailed(i, result);
            }
            unchecked {
                i++; // gas savings
            }
        }

        if (address(this).balance > 0) {
            wrappedNativeToken.call{value: address(this).balance}("");
        }

        // Hooks: after executing operations.
        hooks.afterSubmit(operations);

        // Log submission.
        emit Submitted(guardian, operations);
    }

    /// @inheritdoc IVault
    function claim() external override nonReentrant reserveFees {
        uint256 reservedFee = fees[msg.sender];

        // Requirements: check that there are fees to claim.
        if (reservedFee == 0) {
            revert Aera__NoClaimableFeesForCaller(msg.sender);
        }

        uint256 availableFee =
            Math.min(_feeToken.balanceOf(address(this)), reservedFee);

        // Requirements: check that fees are available to claim.
        if (availableFee == 0) {
            revert Aera__NoAvailableFeesForCaller(msg.sender);
        }

        // Effects: update fee total.
        feeTotal -= availableFee;
        reservedFee -= availableFee;

        // Effects: update leftover fee.
        fees[msg.sender] = reservedFee;

        // Interactions: transfer fee to caller.
        _feeToken.safeTransfer(msg.sender, availableFee);

        // Log the claim.
        emit Claimed(msg.sender, availableFee, reservedFee, feeTotal);
    }

    /// @inheritdoc IVault
    function holdings() external view override returns (AssetValue[] memory) {
        IAssetRegistry.AssetInformation[] memory assets =
            assetRegistry.assets();

        return _getHoldings(assets);
    }

    /// @inheritdoc IVault
    function value() external view override returns (uint256 vaultValue) {
        IAssetRegistry.AssetPriceReading[] memory erc20SpotPrices =
            assetRegistry.spotPrices();

        (vaultValue,) = _value(erc20SpotPrices);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return interfaceId == type(IVault).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc Ownable
    function renounceOwnership() public view override onlyOwner {
        revert Aera__CannotRenounceOwnership();
    }

    /// @inheritdoc Ownable2Step
    function transferOwnership(address newOwner) public override onlyOwner {
        // Requirements: check that new owner is disaffiliated from existing roles.
        if (newOwner == guardian) {
            revert Aera__GuardianIsOwner();
        }
        if (newOwner == feeRecipient) {
            revert Aera__FeeRecipientIsOwner();
        }

        // Effects: initiate ownership transfer.
        super.transferOwnership(newOwner);
    }

    /// @notice Only accept native token from the wrapped native token contract
    ///         when burning wrapped native tokens.
    receive() external payable {
        // Requirements: verify that the sender is wrapped native token.
        if (msg.sender != wrappedNativeToken) {
            revert Aera__NotWrappedNativeTokenContract();
        }
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate guardian fee index.
    /// @return feeIndex Guardian fee index.
    function _getFeeIndex() internal view returns (uint256 feeIndex) {
        if (block.timestamp > lastFeeCheckpoint) {
            unchecked {
                feeIndex = block.timestamp - lastFeeCheckpoint;
            }
        }

        return feeIndex;
    }

    /// @notice Calculate current guardian fees.
    function _reserveFees() internal {
        // Requirements: check if fees are being accrued.
        if (fee == 0 || paused() || finalized) {
            return;
        }

        uint256 feeIndex = _getFeeIndex();

        // Requirements: check if fees have been accruing.
        if (feeIndex == 0) {
            return;
        }

        // Calculate vault value using oracle or backup value if oracle is reverting.
        try assetRegistry.spotPrices() returns (
            IAssetRegistry.AssetPriceReading[] memory erc20SpotPrices
        ) {
            (lastValue, lastFeeTokenPrice) = _value(erc20SpotPrices);
        } catch (bytes memory reason) {
            // Check if there is a clear reason for the revert.
            if (reason.length == 0) {
                revert Aera__SpotPricesReverted();
            }
            emit SpotPricesReverted(reason);
        }

        // Requirements: check that fee token has a positive price.
        if (lastFeeTokenPrice == 0) {
            emit NoFeesReserved(lastFeeCheckpoint, lastValue, feeTotal);
            return;
        }

        // Calculate new fee for current fee recipient.
        // It calculates the fee in fee token decimals.
        uint256 newFee = lastValue * feeIndex * fee;

        if (_numeraireTokenDecimals < _feeTokenDecimals) {
            newFee =
                newFee * (10 ** (_feeTokenDecimals - _numeraireTokenDecimals));
        } else if (_numeraireTokenDecimals > _feeTokenDecimals) {
            newFee =
                newFee / (10 ** (_numeraireTokenDecimals - _feeTokenDecimals));
        }

        newFee /= lastFeeTokenPrice;

        if (newFee == 0) {
            return;
        }

        // Move fee checkpoint only if fee is nonzero
        lastFeeCheckpoint = block.timestamp;

        // Effects: accrue fee to fee recipient and remember new fee total.
        fees[feeRecipient] += newFee;
        feeTotal += newFee;

        // Log fee reservation.
        emit FeesReserved(
            feeRecipient,
            newFee,
            lastFeeCheckpoint,
            lastValue,
            lastFeeTokenPrice,
            feeTotal
        );
    }

    /// @notice Get current total value of assets in vault and price of fee token.
    /// @dev It calculates the value in Numeraire token decimals.
    /// @param erc20SpotPrices Spot prices of ERC20 assets.
    /// @return vaultValue Current total value.
    /// @return feeTokenPrice Fee token price.
    function _value(IAssetRegistry.AssetPriceReading[] memory erc20SpotPrices)
        internal
        view
        returns (uint256 vaultValue, uint256 feeTokenPrice)
    {
        IAssetRegistry.AssetInformation[] memory assets =
            assetRegistry.assets();
        AssetValue[] memory assetAmounts = _getHoldings(assets);

        (uint256[] memory spotPrices, uint256[] memory assetUnits) =
            _getSpotPricesAndUnits(assets, erc20SpotPrices);

        uint256 numAssets = assets.length;
        uint256 balance;

        for (uint256 i = 0; i < numAssets;) {
            if (assets[i].isERC4626) {
                balance = IERC4626(address(assets[i].asset)).convertToAssets(
                    assetAmounts[i].value
                );
            } else {
                balance = assetAmounts[i].value;
            }

            if (assets[i].asset == _feeToken) {
                feeTokenPrice = spotPrices[i];
            }

            vaultValue += (balance * spotPrices[i]) / assetUnits[i];
            unchecked {
                i++; // gas savings
            }
        }

        uint256 numeraireUnit = 10 ** _numeraireTokenDecimals;

        if (numeraireUnit != ONE) {
            vaultValue = vaultValue * numeraireUnit / ONE;
        }
    }

    /// @notice Check that assets in provided amounts are sorted and unique.
    /// @param amounts Struct details for assets and amounts to withdraw.
    function _checkAmountsSorted(AssetValue[] memory amounts) internal pure {
        uint256 numAssets = amounts.length;

        for (uint256 i = 1; i < numAssets;) {
            if (amounts[i - 1].asset >= amounts[i].asset) {
                revert Aera__AmountsOrderIsIncorrect(i);
            }
            unchecked {
                i++; // gas savings
            }
        }
    }

    /// @notice Check request to withdraw.
    /// @param assets Struct details for asset information from asset registry.
    /// @param amounts Struct details for assets and amounts to withdraw.
    function _checkWithdrawRequest(
        IAssetRegistry.AssetInformation[] memory assets,
        AssetValue[] memory amounts
    ) internal view {
        uint256 numAmounts = amounts.length;

        AssetValue[] memory assetAmounts = _getHoldings(assets);

        bool isRegistered;
        AssetValue memory assetValue;
        uint256 assetIndex;

        for (uint256 i = 0; i < numAmounts;) {
            assetValue = amounts[i];
            (isRegistered, assetIndex) =
                _isAssetRegistered(assetValue.asset, assets);

            if (!isRegistered) {
                revert Aera__AssetIsNotRegistered(assetValue.asset);
            }

            if (assetAmounts[assetIndex].value < assetValue.value) {
                revert Aera__AmountExceedsAvailable(
                    assetValue.asset,
                    assetValue.value,
                    assetAmounts[assetIndex].value
                );
            }
            unchecked {
                i++; // gas savings
            }
        }
    }

    /// @notice Get spot prices and units of requested assets.
    /// @dev Spot prices are scaled to 18 decimals.
    /// @param assets Registered assets in asset registry and their information.
    /// @param erc20SpotPrices Struct details for spot prices of ERC20 assets.
    /// @return spotPrices Spot prices of assets.
    /// @return assetUnits Units of assets.
    function _getSpotPricesAndUnits(
        IAssetRegistry.AssetInformation[] memory assets,
        IAssetRegistry.AssetPriceReading[] memory erc20SpotPrices
    )
        internal
        view
        returns (uint256[] memory spotPrices, uint256[] memory assetUnits)
    {
        uint256 numAssets = assets.length;
        uint256 numERC20SpotPrices = erc20SpotPrices.length;

        spotPrices = new uint256[](numAssets);
        assetUnits = new uint256[](numAssets);

        IAssetRegistry.AssetInformation memory asset;

        for (uint256 i = 0; i < numAssets;) {
            asset = assets[i];

            IERC20 assetToFind = (
                asset.isERC4626
                    ? IERC20(IERC4626(address(asset.asset)).asset())
                    : asset.asset
            );
            uint256 j = 0;
            for (; j < numERC20SpotPrices;) {
                if (assetToFind == erc20SpotPrices[j].asset) {
                    break;
                }
                unchecked {
                    j++; // gas savings
                }
            }
            spotPrices[i] = erc20SpotPrices[j].spotPrice;
            assetUnits[i] =
                10 ** IERC20Metadata(address(assetToFind)).decimals();

            unchecked {
                i++; // gas savings
            }
        }
    }

    /// @notice Get total amount of assets in vault.
    /// @param assets Struct details for registered assets in asset registry.
    /// @return assetAmounts Amount of assets.
    function _getHoldings(IAssetRegistry.AssetInformation[] memory assets)
        internal
        view
        returns (AssetValue[] memory assetAmounts)
    {
        uint256 numAssets = assets.length;

        assetAmounts = new AssetValue[](numAssets);
        IAssetRegistry.AssetInformation memory assetInfo;

        for (uint256 i = 0; i < numAssets;) {
            assetInfo = assets[i];
            assetAmounts[i] = AssetValue({
                asset: assetInfo.asset,
                value: assetInfo.asset.balanceOf(address(this))
            });

            if (assetInfo.asset == _feeToken) {
                assetAmounts[i].value -=
                    Math.min(feeTotal, assetAmounts[i].value);
            }

            unchecked {
                i++; //gas savings
            }
        }
    }

    /// @notice Check if balance of fee becomes insolvent or becomes more insolvent.
    /// @param prevFeeTokenBalance Balance of fee token before action.
    function _checkReservedFees(uint256 prevFeeTokenBalance) internal view {
        uint256 feeTokenBalance = IERC20(_feeToken).balanceOf(address(this));

        if (
            feeTokenBalance < feeTotal && feeTokenBalance < prevFeeTokenBalance
        ) {
            revert Aera__CannotUseReservedFees();
        }
    }

    /// @notice Check if the address can be a guardian.
    /// @param newGuardian Address to check.
    /// @param owner_ Owner address.
    function _checkGuardianAddress(
        address newGuardian,
        address owner_
    ) internal pure {
        if (newGuardian == address(0)) {
            revert Aera__GuardianIsZeroAddress();
        }
        if (newGuardian == owner_) {
            revert Aera__GuardianIsOwner();
        }
    }

    /// @notice Check if the address can be a fee recipient.
    /// @param newFeeRecipient Address to check.
    /// @param owner_ Owner address.
    function _checkFeeRecipientAddress(
        address newFeeRecipient,
        address owner_
    ) internal pure {
        if (newFeeRecipient == address(0)) {
            revert Aera__FeeRecipientIsZeroAddress();
        }
        if (newFeeRecipient == owner_) {
            revert Aera__FeeRecipientIsOwner();
        }
    }

    /// @notice Check if the address can be an asset registry.
    /// @param newAssetRegistry Address to check.
    function _checkAssetRegistryAddress(address newAssetRegistry)
        internal
        view
    {
        if (newAssetRegistry == address(0)) {
            revert Aera__AssetRegistryIsZeroAddress();
        }
        if (
            !ERC165Checker.supportsInterface(
                newAssetRegistry, type(IAssetRegistry).interfaceId
            )
        ) {
            revert Aera__AssetRegistryIsNotValid(newAssetRegistry);
        }
        if (IAssetRegistry(newAssetRegistry).vault() != address(this)) {
            revert Aera__AssetRegistryHasInvalidVault();
        }
    }

    /// @notice Check if the address can be a hooks contract.
    /// @param newHooks Address to check.
    function _checkHooksAddress(address newHooks) internal view {
        if (newHooks == address(0)) {
            revert Aera__HooksIsZeroAddress();
        }
        if (
            !ERC165Checker.supportsInterface(newHooks, type(IHooks).interfaceId)
        ) {
            revert Aera__HooksIsNotValid(newHooks);
        }
        if (IHooks(newHooks).vault() != address(this)) {
            revert Aera__HooksHasInvalidVault();
        }
    }

    /// @notice Check whether asset is registered to asset registry or not.
    /// @param asset Asset to check.
    /// @param registeredAssets Array of registered assets.
    /// @return isRegistered True if asset is registered.
    /// @return index Index of asset in asset registry.
    function _isAssetRegistered(
        IERC20 asset,
        IAssetRegistry.AssetInformation[] memory registeredAssets
    ) internal pure returns (bool isRegistered, uint256 index) {
        uint256 numAssets = registeredAssets.length;

        for (uint256 i = 0; i < numAssets;) {
            if (registeredAssets[i].asset < asset) {
                unchecked {
                    i++; // gas savings
                }

                continue;
            }

            if (registeredAssets[i].asset == asset) {
                return (true, i);
            }

            break;
        }
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

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
abstract contract Ownable2Step is Ownable {
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
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./Address.sol";

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
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {
    AssetRegistryParameters,
    HooksParameters,
    VaultParameters
} from "../Types.sol";

/// @title IAeraV2Factory
/// @notice Interface for the V2 vault factory.
interface IAeraV2Factory {
    /// @notice Create V2 vault.
    /// @param saltInput The salt input value to generate salt.
    /// @param description Vault description.
    /// @param vaultParameters Struct details for vault deployment.
    /// @param assetRegistryParameters Struct details for asset registry deployment.
    /// @param hooksParameters Struct details for hooks deployment.
    /// @return deployedVault The address of deployed vault.
    /// @return deployedAssetRegistry The address of deployed asset registry.
    /// @return deployedHooks The address of deployed hooks.
    function create(
        bytes32 saltInput,
        string calldata description,
        VaultParameters calldata vaultParameters,
        AssetRegistryParameters memory assetRegistryParameters,
        HooksParameters memory hooksParameters
    )
        external
        returns (
            address deployedVault,
            address deployedAssetRegistry,
            address deployedHooks
        );

    /// @notice Calculate deployment address of V2 vault.
    /// @param saltInput The salt input value to generate salt.
    /// @param description Vault description.
    /// @param vaultParameters Struct details for vault deployment.
    function computeVaultAddress(
        bytes32 saltInput,
        string calldata description,
        VaultParameters calldata vaultParameters
    ) external view returns (address);

    /// @notice Returns the address of wrapped native token.
    function wrappedNativeToken() external view returns (address);

    /// @notice Returns vault parameters for vault deployment.
    /// @return owner Initial owner address.
    /// @return assetRegistry Asset registry address.
    /// @return hooks Hooks address.
    /// @return guardian Guardian address.
    /// @return feeRecipient Fee recipient address.
    /// @return fee Fees accrued per second, denoted in 18 decimal fixed point format.
    function parameters()
        external
        view
        returns (
            address owner,
            address assetRegistry,
            address hooks,
            address guardian,
            address feeRecipient,
            uint256 fee
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {AssetValue, Operation} from "../Types.sol";

/// @title IHooks
/// @notice Interface for the hooks module.
interface IHooks {
    /// @notice Get address of vault.
    /// @return vault Vault address.
    function vault() external view returns (address vault);

    /// @notice Hook that runs before deposit.
    /// @param amounts Struct details for assets and amounts to deposit.
    /// @dev MUST revert if not called by vault.
    function beforeDeposit(AssetValue[] memory amounts) external;

    /// @notice Hook that runs after deposit.
    /// @param amounts Struct details for assets and amounts to deposit.
    /// @dev MUST revert if not called by vault.
    function afterDeposit(AssetValue[] memory amounts) external;

    /// @notice Hook that runs before withdraw.
    /// @param amounts Struct details for assets and amounts to withdraw.
    /// @dev MUST revert if not called by vault.
    function beforeWithdraw(AssetValue[] memory amounts) external;

    /// @notice Hook that runs after withdraw.
    /// @param amounts Struct details for assets and amounts to withdraw.
    /// @dev MUST revert if not called by vault.
    function afterWithdraw(AssetValue[] memory amounts) external;

    /// @notice Hook that runs before submit.
    /// @param operations Array of struct details for target and calldata to submit.
    /// @dev MUST revert if not called by vault.
    function beforeSubmit(Operation[] memory operations) external;

    /// @notice Hook that runs after submit.
    /// @param operations Array of struct details for target and calldata to submit.
    /// @dev MUST revert if not called by vault.
    function afterSubmit(Operation[] memory operations) external;

    /// @notice Hook that runs before finalize.
    /// @dev MUST revert if not called by vault.
    function beforeFinalize() external;

    /// @notice Hook that runs after finalize.
    /// @dev MUST revert if not called by vault.
    function afterFinalize() external;

    /// @notice Take hooks out of use.
    function decommission() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/IERC20.sol";
import "./IAssetRegistry.sol";
import "./IVaultEvents.sol";
import "./IHooks.sol";

/// @title IVault
/// @notice Interface for the vault.
/// @dev Any implementation MUST also implement Ownable2Step.
interface IVault is IVaultEvents {
    /// ERRORS ///

    error Aera__AssetRegistryIsZeroAddress();
    error Aera__AssetRegistryIsNotValid(address assetRegistry);
    error Aera__AssetRegistryHasInvalidVault();
    error Aera__HooksIsZeroAddress();
    error Aera__HooksIsNotValid(address hooks);
    error Aera__HooksHasInvalidVault();
    error Aera__GuardianIsZeroAddress();
    error Aera__GuardianIsOwner();
    error Aera__InitialOwnerIsZeroAddress();
    error Aera__FeeRecipientIsZeroAddress();
    error Aera__ExecuteTargetIsHooksAddress();
    error Aera__ExecuteTargetIsVaultAddress();
    error Aera__SubmitTransfersAssetFromOwner();
    error Aera__SubmitRedeemERC4626AssetFromOwner();
    error Aera__SubmitTargetIsVaultAddress();
    error Aera__SubmitTargetIsHooksAddress(uint256 index);
    error Aera__FeeRecipientIsOwner();
    error Aera__FeeIsAboveMax(uint256 actual, uint256 max);
    error Aera__CallerIsNotOwnerAndGuardian();
    error Aera__CallerIsNotGuardian();
    error Aera__AssetIsNotRegistered(IERC20 asset);
    error Aera__AmountExceedsAvailable(
        IERC20 asset, uint256 amount, uint256 available
    );
    error Aera__ExecutionFailed(bytes result);
    error Aera__VaultIsFinalized();
    error Aera__SubmissionFailed(uint256 index, bytes result);
    error Aera__CannotUseReservedFees();
    error Aera__SpotPricesReverted();
    error Aera__AmountsOrderIsIncorrect(uint256 index);
    error Aera__NoAvailableFeesForCaller(address caller);
    error Aera__NoClaimableFeesForCaller(address caller);
    error Aera__NotWrappedNativeTokenContract();
    error Aera__CannotRenounceOwnership();

    /// FUNCTIONS ///

    /// @notice Deposit assets.
    /// @param amounts Assets and amounts to deposit.
    /// @dev MUST revert if not called by owner.
    function deposit(AssetValue[] memory amounts) external;

    /// @notice Withdraw assets.
    /// @param amounts Assets and amounts to withdraw.
    /// @dev MUST revert if not called by owner.
    function withdraw(AssetValue[] memory amounts) external;

    /// @notice Set current guardian and fee recipient.
    /// @param guardian New guardian address.
    /// @param feeRecipient New fee recipient address.
    /// @dev MUST revert if not called by owner.
    function setGuardianAndFeeRecipient(
        address guardian,
        address feeRecipient
    ) external;

    /// @notice Sets the current hooks module.
    /// @param hooks New hooks module address.
    /// @dev MUST revert if not called by owner.
    function setHooks(address hooks) external;

    /// @notice Execute a transaction via the vault.
    /// @dev Execution still should work when vault is finalized.
    /// @param operation Struct details for target and calldata to execute.
    /// @dev MUST revert if not called by owner.
    function execute(Operation memory operation) external;

    /// @notice Terminate the vault and return all funds to owner.
    /// @dev MUST revert if not called by owner.
    function finalize() external;

    /// @notice Stops the guardian from submission and halts fee accrual.
    /// @dev MUST revert if not called by owner or guardian.
    function pause() external;

    /// @notice Resume fee accrual and guardian submissions.
    /// @dev MUST revert if not called by owner.
    function resume() external;

    /// @notice Submit a series of transactions for execution via the vault.
    /// @param operations Sequence of operations to execute.
    /// @dev MUST revert if not called by guardian.
    function submit(Operation[] memory operations) external;

    /// @notice Claim fees on behalf of a current or previous fee recipient.
    function claim() external;

    /// @notice Get the current guardian.
    /// @return guardian Address of guardian.
    function guardian() external view returns (address guardian);

    /// @notice Get the current fee recipient.
    /// @return feeRecipient Address of fee recipient.
    function feeRecipient() external view returns (address feeRecipient);

    /// @notice Get the current asset registry.
    /// @return assetRegistry Address of asset registry.
    function assetRegistry()
        external
        view
        returns (IAssetRegistry assetRegistry);

    /// @notice Get the current hooks module address.
    /// @return hooks Address of hooks module.
    function hooks() external view returns (IHooks hooks);

    /// @notice Get fee per second.
    /// @return fee Fee per second in 18 decimal fixed point format.
    function fee() external view returns (uint256 fee);

    /// @notice Get current balances of all assets.
    /// @return assetAmounts Amounts of registered assets.
    function holdings()
        external
        view
        returns (AssetValue[] memory assetAmounts);

    /// @notice Get current total value of assets in vault.
    /// @return value Current total value.
    function value() external view returns (uint256 value);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

// Constants.sol
//
// This file defines the constants used across several contracts in V2.

/// @dev Fixed point multiplier.
uint256 constant ONE = 1e18;

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/IERC20.sol";
import "./interfaces/IAssetRegistry.sol";

// Types.sol
//
// This file defines the types used in V2.

/// @notice Combination of contract address and sighash to be used in allowlist.
/// @dev It's packed as follows:
///      [target 160 bits] [selector 32 bits] [<empty> 64 bits]
type TargetSighash is bytes32;

/// @notice Struct encapulating an asset and an associated value.
/// @param asset Asset address.
/// @param value The associated value for this asset (e.g., amount or price).
struct AssetValue {
    IERC20 asset;
    uint256 value;
}

/// @notice Execution details for a vault operation.
/// @param target Target contract address.
/// @param value Native token amount.
/// @param data Calldata.
struct Operation {
    address target;
    uint256 value;
    bytes data;
}

/// @notice Contract address and sighash struct to be used in the public interface.
struct TargetSighashData {
    address target;
    bytes4 selector;
}

/// @notice Parameters for vault deployment.
/// @param owner Initial owner address.
/// @param assetRegistry Asset registry address.
/// @param hooks Hooks address.
/// @param guardian Guardian address.
/// @param feeRecipient Fee recipient address.
/// @param fee Fees accrued per second, denoted in 18 decimal fixed point format.
struct Parameters {
    address owner;
    address assetRegistry;
    address hooks;
    address guardian;
    address feeRecipient;
    uint256 fee;
}

/// @notice Vault parameters for vault deployment.
/// @param owner Initial owner address.
/// @param guardian Guardian address.
/// @param feeRecipient Fee recipient address.
/// @param fee Fees accrued per second, denoted in 18 decimal fixed point format.
struct VaultParameters {
    address owner;
    address guardian;
    address feeRecipient;
    uint256 fee;
}

/// @notice Asset registry parameters for asset registry deployment.
/// @param factory Asset registry factory address.
/// @param owner Initial owner address.
/// @param assets Initial list of registered assets.
/// @param numeraireToken Numeraire token address.
/// @param feeToken Fee token address.
/// @param sequencer Sequencer Uptime Feed address for L2.
struct AssetRegistryParameters {
    address factory;
    address owner;
    IAssetRegistry.AssetInformation[] assets;
    IERC20 numeraireToken;
    IERC20 feeToken;
    AggregatorV2V3Interface sequencer;
}

/// @notice Hooks parameters for hooks deployment.
/// @param factory Hooks factory address.
/// @param owner Initial owner address.
/// @param minDailyValue The fraction of value that the vault has to retain per day
///                      in the course of submissions.
/// @param targetSighashAllowlist Array of target contract and sighash combinations to allow.
struct HooksParameters {
    address factory;
    address owner;
    uint256 minDailyValue;
    TargetSighashData[] targetSighashAllowlist;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import "@openzeppelin/IERC20.sol";

/// @title IAssetRegistry
/// @notice Asset registry interface.
/// @dev Any implementation MUST also implement Ownable2Step and ERC165.
interface IAssetRegistry {
    /// @param asset Asset address.
    /// @param heartbeat Frequency of oracle price updates.
    /// @param isERC4626 True if yield-bearing asset, false if just an ERC20 asset.
    /// @param oracle If applicable, oracle address for asset.
    struct AssetInformation {
        IERC20 asset;
        uint256 heartbeat;
        bool isERC4626;
        AggregatorV2V3Interface oracle;
    }

    /// @param asset Asset address.
    /// @param spotPrice Spot price of an asset in Numeraire token terms.
    struct AssetPriceReading {
        IERC20 asset;
        uint256 spotPrice;
    }

    /// @notice Get address of vault.
    /// @return vault Address of vault.
    function vault() external view returns (address vault);

    /// @notice Get a list of all registered assets.
    /// @return assets List of assets.
    /// @dev MUST return assets in an order sorted by address.
    function assets()
        external
        view
        returns (AssetInformation[] memory assets);

    /// @notice Get address of fee token.
    /// @return feeToken Address of fee token.
    /// @dev Represented as an address for efficiency reasons.
    /// @dev MUST be present in assets array.
    function feeToken() external view returns (IERC20 feeToken);

    /// @notice Get the index of the Numeraire token in the assets array.
    /// @return numeraireToken Numeraire token address.
    /// @dev Represented as an index for efficiency reasons.
    /// @dev MUST be a number between 0 (inclusive) and the length of assets array (exclusive).
    function numeraireToken() external view returns (IERC20 numeraireToken);

    /// @notice Calculate spot prices of non-ERC4626 assets.
    /// @return spotPrices Spot prices of non-ERC4626 assets in 18 decimals.
    /// @dev MUST return assets in the same order as in assets but with ERC4626 assets filtered out.
    /// @dev MUST also include Numeraire token (spot price = 1).
    /// @dev MAY revert if oracle prices for any asset are unreliable at the time.
    function spotPrices()
        external
        view
        returns (AssetPriceReading[] memory spotPrices);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/IERC20.sol";

import {AssetValue, Operation} from "../Types.sol";

/// @title Interface for vault events.
interface IVaultEvents {
    /// @notice Emitted when deposit is called.
    /// @param owner Owner address.
    /// @param asset Deposited asset.
    /// @param amount Deposited asset amount.
    event Deposit(address indexed owner, IERC20 indexed asset, uint256 amount);

    /// @notice Emitted when withdraw is called.
    /// @param owner Owner address.
    /// @param asset Withdrawn asset.
    /// @param amount Withdrawn asset amount.
    event Withdraw(
        address indexed owner, IERC20 indexed asset, uint256 amount
    );

    /// @notice Emitted when guardian is set.
    /// @param guardian Address of new guardian.
    /// @param feeRecipient Address of new fee recipient.
    event SetGuardianAndFeeRecipient(
        address indexed guardian, address indexed feeRecipient
    );

    /// @notice Emitted when asset registry is set.
    /// @param assetRegistry Address of new asset registry.
    event SetAssetRegistry(address assetRegistry);

    /// @notice Emitted when hooks is set.
    /// @param hooks Address of new hooks.
    event SetHooks(address hooks);

    /// @notice Emitted when execute is called.
    /// @param owner Owner address.
    /// @param operation Struct details for target and calldata.
    event Executed(address indexed owner, Operation operation);

    /// @notice Emitted when vault is finalized.
    /// @param owner Owner address.
    /// @param withdrawnAmounts Struct details for withdrawn assets and amounts (sent to owner).
    event Finalized(address indexed owner, AssetValue[] withdrawnAmounts);

    /// @notice Emitted when submit is called.
    /// @param guardian Guardian address.
    /// @param operations Array of struct details for targets and calldatas.
    event Submitted(address indexed guardian, Operation[] operations);

    /// @notice Emitted when guardian fees are claimed.
    /// @param feeRecipient Fee recipient address.
    /// @param claimedFee Claimed amount of fee token.
    /// @param unclaimedFee Unclaimed amount of fee token (unclaimed because Vault does not have enough balance of feeToken).
    /// @param feeTotal New total reserved fee value.
    event Claimed(
        address indexed feeRecipient,
        uint256 claimedFee,
        uint256 unclaimedFee,
        uint256 feeTotal
    );

    /// @notice Emitted when new fees are reserved for recipient.
    /// @param feeRecipient Fee recipient address.
    /// @param newFee Fee amount reserved.
    /// @param lastFeeCheckpoint Updated fee checkpoint.
    /// @param lastValue Last registered vault value.
    /// @param lastFeeTokenPrice Last registered fee token price.
    /// @param feeTotal New total reserved fee value.
    event FeesReserved(
        address indexed feeRecipient,
        uint256 newFee,
        uint256 lastFeeCheckpoint,
        uint256 lastValue,
        uint256 lastFeeTokenPrice,
        uint256 feeTotal
    );

    /// @notice Emitted when no fees are reserved.
    /// @param lastFeeCheckpoint Updated fee checkpoint.
    /// @param lastValue Last registered vault value.
    /// @param feeTotal New total reserved fee value.
    event NoFeesReserved(
        uint256 lastFeeCheckpoint,
        uint256 lastValue,
        uint256 feeTotal
    );

    /// @notice Emitted when the call to get spot prices from the asset registry reverts.
    /// @param reason Revert reason.
    event SpotPricesReverted(bytes reason);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}