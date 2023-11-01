// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title   Deposit Assets Whitelister.
 * @author  Pulsar Finance
 * @dev     VERSION: 1.0
 *          DATE:    2023.10.04
 */

import {Enums} from "Enums.sol";
import {Errors} from "Errors.sol";
import {ConfigTypes} from "ConfigTypes.sol";
import {Ownable} from "Ownable.sol";
import {IStrategyManager} from "IStrategyManager.sol";
import {PercentageMath} from "PercentageMath.sol";
import {IPriceFeedsDataConsumer} from "IPriceFeedsDataConsumer.sol";

contract StrategyManager is IStrategyManager, Ownable {
    uint256 public constant SAFETY_FACTORS_PRECISION_MULTIPLIER = 1000;
    uint256 private _MAX_EXPECTED_GAS_UNITS_WEI = 2_500_000;

    mapping(Enums.BuyFrequency => uint256)
        private _maxNumberOfActionsPerFrequency;

    mapping(Enums.StrategyTimeLimitsInDays => uint256)
        private _gasCostSafetyFactors;

    mapping(Enums.AssetTypes => mapping(Enums.StrategyTimeLimitsInDays => uint256))
        private _depositTokenPriceSafetyFactors;

    mapping(Enums.BuyFrequency => uint256) private _numberOfDaysPerBuyFrequency;

    address[] private _whitelistedDepositAssetAddresses;
    mapping(address => ConfigTypes.WhitelistedDepositAsset)
        private _whitelistedDepositAssets;

    IPriceFeedsDataConsumer public priceFeedsDataConsumer;

    constructor(address _priceFeedsDataConsumer) Ownable(msg.sender) {
        _fillNumberOfDaysPerBuyFrequency();
        _fillMaxNumberOfActionsPerFrequencyDefaultMap();
        _fillGasCostSafetyFactorsDefaultMap();
        _fillDepositTokenPriceSafetyFactorsDefaultMap();
        priceFeedsDataConsumer = IPriceFeedsDataConsumer(
            _priceFeedsDataConsumer
        );
    }

    function addWhitelistedDepositAssets(
        ConfigTypes.WhitelistedDepositAsset[] calldata depositAssetsToWhitelist
    ) external onlyOwner {
        uint256 _assetsLength = depositAssetsToWhitelist.length;
        for (uint256 i; i < _assetsLength; ) {
            if (
                _whitelistedDepositAssets[
                    depositAssetsToWhitelist[i].assetAddress
                ].assetAddress == address(0) /** @dev Avoid duplicates */
            ) {
                _whitelistedDepositAssetAddresses.push(
                    depositAssetsToWhitelist[i].assetAddress
                );
            }
            _whitelistedDepositAssets[
                depositAssetsToWhitelist[i].assetAddress
            ] = depositAssetsToWhitelist[i];
            unchecked {
                ++i;
            }
        }
    }

    function deactivateWhitelistedDepositAsset(
        address depositTokenAddress
    ) external onlyOwner {
        _whitelistedDepositAssets[depositTokenAddress].isActive = false;
    }

    function setMaxExpectedGasUnits(
        uint256 maxExpectedGasUnits
    ) external onlyOwner {
        if (maxExpectedGasUnits <= 0) {
            revert Errors.InvalidParameters(
                "Max expected gas units value must be greater than zero"
            );
        }
        _MAX_EXPECTED_GAS_UNITS_WEI = maxExpectedGasUnits;
    }

    function setGasCostSafetyFactor(
        Enums.StrategyTimeLimitsInDays strategyTimeLimitsInDays,
        uint32 gasCostSafetyFactor
    ) external onlyOwner {
        _gasCostSafetyFactors[strategyTimeLimitsInDays] = gasCostSafetyFactor;
    }

    function setDepositTokenPriceSafetyFactor(
        Enums.AssetTypes assetType,
        Enums.StrategyTimeLimitsInDays strategyTimeLimitsInDays,
        uint32 depositTokenPriceSafetyFactor
    ) external onlyOwner {
        _depositTokenPriceSafetyFactors[assetType][
            strategyTimeLimitsInDays
        ] = depositTokenPriceSafetyFactor;
    }

    function getMaxNumberOfActionsPerFrequency(
        Enums.BuyFrequency buyFrequency
    ) external view returns (uint256) {
        return _maxNumberOfActionsPerFrequency[buyFrequency];
    }

    function getMaxExpectedGasUnits() public view returns (uint256) {
        return _MAX_EXPECTED_GAS_UNITS_WEI;
    }

    /**
        @dev Assets returned can already be deactivated. Check getWhitelistedDepositAsset(address)
    */
    function getWhitelistedDepositAssetAddresses()
        external
        view
        returns (address[] memory)
    {
        return _whitelistedDepositAssetAddresses;
    }

    function getWhitelistedDepositAsset(
        address depositAssetAddress
    ) external view returns (ConfigTypes.WhitelistedDepositAsset memory) {
        return _whitelistedDepositAssets[depositAssetAddress];
    }

    /**
        @dev The `getGasCostSafetyFactor` does not have a `fallback return` in case any of the if conditions 
        are met because it implies that maxNumberOfDays > 365. 
        In this case isMaxNumberOfStrategyActionsValid (previously checked) MUST return false.
        Keep this in mind if you need to modify any of the following mapping parameters hardcoded in this contract:
        - _numberOfDaysPerBuyFrequency
        - _maxNumberOfActionsPerFrequency
    */
    function getGasCostSafetyFactor(
        uint256 maxNumberOfStrategyActions,
        Enums.BuyFrequency buyFrequency
    ) public view returns (uint256) {
        uint256 buyFrequencyInDays = _numberOfDaysPerBuyFrequency[buyFrequency];
        uint256 maxNumberOfDays = buyFrequencyInDays *
            maxNumberOfStrategyActions;
        bool isMaxNumberOfStrategyActionsValidBool = this
            .isMaxNumberOfStrategyActionsValid(
                maxNumberOfStrategyActions,
                buyFrequency
            );
        if (!isMaxNumberOfStrategyActionsValidBool) {
            revert Errors.InvalidParameters(
                "Max number of actions exceeds the limit"
            );
        }
        if (maxNumberOfDays <= 30) {
            return _gasCostSafetyFactors[Enums.StrategyTimeLimitsInDays.THIRTY];
        }
        if (maxNumberOfDays <= 90) {
            return _gasCostSafetyFactors[Enums.StrategyTimeLimitsInDays.NINETY];
        }
        if (maxNumberOfDays <= 180) {
            return
                _gasCostSafetyFactors[
                    Enums.StrategyTimeLimitsInDays.ONE_HUNDRED_AND_EIGHTY
                ];
        }
        if (maxNumberOfDays <= 365) {
            return
                _gasCostSafetyFactors[
                    Enums.StrategyTimeLimitsInDays.THREE_HUNDRED_AND_SIXTY_FIVE
                ];
        }
    }

    /**
        @dev The `getDepositTokenPriceSafetyFactor` does not have a `fallback return` in case any of the if conditions 
        are met because it implies that maxNumberOfDays > 365. 
        In this case isMaxNumberOfStrategyActionsValid (previously checked) MUST return false.
        Keep this in mind if you need to modify any of the following mapping parameters hardcoded in this contract:
        - _numberOfDaysPerBuyFrequency
        - _maxNumberOfActionsPerFrequency
    */
    function getDepositTokenPriceSafetyFactor(
        Enums.AssetTypes assetType,
        uint256 maxNumberOfStrategyActions,
        Enums.BuyFrequency buyFrequency
    ) public view returns (uint256) {
        uint256 buyFrequencyInDays = _numberOfDaysPerBuyFrequency[buyFrequency];
        bool isMaxNumberOfStrategyActionsValidBool = this
            .isMaxNumberOfStrategyActionsValid(
                maxNumberOfStrategyActions,
                buyFrequency
            );
        if (!isMaxNumberOfStrategyActionsValidBool) {
            revert Errors.InvalidParameters(
                "Max number of actions exceeds the limit"
            );
        }
        uint256 maxNumberOfDays = buyFrequencyInDays *
            maxNumberOfStrategyActions;
        if (maxNumberOfDays <= 30) {
            return
                _depositTokenPriceSafetyFactors[assetType][
                    Enums.StrategyTimeLimitsInDays.THIRTY
                ];
        }
        if (maxNumberOfDays <= 90) {
            return
                _depositTokenPriceSafetyFactors[assetType][
                    Enums.StrategyTimeLimitsInDays.NINETY
                ];
        }
        if (maxNumberOfDays <= 180) {
            return
                _depositTokenPriceSafetyFactors[assetType][
                    Enums.StrategyTimeLimitsInDays.ONE_HUNDRED_AND_EIGHTY
                ];
        }
        if (maxNumberOfDays <= 365) {
            return
                _depositTokenPriceSafetyFactors[assetType][
                    Enums.StrategyTimeLimitsInDays.THREE_HUNDRED_AND_SIXTY_FIVE
                ];
        }
    }

    function simulateMinDepositValue(
        ConfigTypes.WhitelistedDepositAsset calldata whitelistedDepositAsset,
        uint256 maxNumberOfStrategyActions,
        Enums.BuyFrequency buyFrequency,
        uint256 treasuryPercentageFeeOnBalanceUpdate,
        uint256 depositAssetDecimals,
        uint256 previousBalance,
        uint256 gasPriceWei
    ) external view returns (uint256 minDepositValue) {
        (
            uint256 nativeTokenPrice,
            uint256 nativeTokenPriceDecimals
        ) = priceFeedsDataConsumer
                .getNativeTokenDataFeedLatestPriceAndDecimals();
        (
            uint256 tokenPrice,
            uint256 tokenPriceDecimals
        ) = priceFeedsDataConsumer.getDataFeedLatestPriceAndDecimals(
                whitelistedDepositAsset.oracleAddress
            );
        // prettier-ignore
        minDepositValue = ((
            nativeTokenPrice 
            * PercentageMath.PERCENTAGE_FACTOR 
            * getMaxExpectedGasUnits() 
            * maxNumberOfStrategyActions 
            * gasPriceWei 
            * getGasCostSafetyFactor(maxNumberOfStrategyActions,buyFrequency) 
            * (10 ** (tokenPriceDecimals + depositAssetDecimals))
        ) / (
            tokenPrice 
            * treasuryPercentageFeeOnBalanceUpdate 
            * getDepositTokenPriceSafetyFactor(whitelistedDepositAsset.assetType, maxNumberOfStrategyActions,buyFrequency)
            * (10 ** (18 + nativeTokenPriceDecimals))
        ));
        minDepositValue = minDepositValue > previousBalance
            ? minDepositValue - previousBalance
            : 0;
    }

    function isMaxNumberOfStrategyActionsValid(
        uint256 maxNumberOfStrategyActions,
        Enums.BuyFrequency buyFrequency
    ) external view returns (bool) {
        uint256 buyFrequencyInDays = _numberOfDaysPerBuyFrequency[buyFrequency];
        uint256 maxNumberOfDays = buyFrequencyInDays *
            maxNumberOfStrategyActions;
        uint256 maxNumberOfDaysAllowed = _maxNumberOfActionsPerFrequency[
            buyFrequency
        ] * buyFrequencyInDays;
        return maxNumberOfDays <= maxNumberOfDaysAllowed;
    }

    function _fillNumberOfDaysPerBuyFrequency() private {
        _numberOfDaysPerBuyFrequency[Enums.BuyFrequency.DAILY] = 1;
        _numberOfDaysPerBuyFrequency[Enums.BuyFrequency.WEEKLY] = 7;
        _numberOfDaysPerBuyFrequency[Enums.BuyFrequency.BI_WEEKLY] = 14;
        _numberOfDaysPerBuyFrequency[Enums.BuyFrequency.MONTHLY] = 30;
    }

    function _fillMaxNumberOfActionsPerFrequencyDefaultMap() private {
        _maxNumberOfActionsPerFrequency[Enums.BuyFrequency.DAILY] = 60;
        _maxNumberOfActionsPerFrequency[Enums.BuyFrequency.WEEKLY] = 52;
        _maxNumberOfActionsPerFrequency[Enums.BuyFrequency.BI_WEEKLY] = 26;
        _maxNumberOfActionsPerFrequency[Enums.BuyFrequency.MONTHLY] = 12;
    }

    function _fillGasCostSafetyFactorsDefaultMap() private {
        _gasCostSafetyFactors[Enums.StrategyTimeLimitsInDays.THIRTY] = 1000;
        _gasCostSafetyFactors[Enums.StrategyTimeLimitsInDays.NINETY] = 2250;
        _gasCostSafetyFactors[
            Enums.StrategyTimeLimitsInDays.ONE_HUNDRED_AND_EIGHTY
        ] = 3060;
        _gasCostSafetyFactors[
            Enums.StrategyTimeLimitsInDays.THREE_HUNDRED_AND_SIXTY_FIVE
        ] = 4000;
    }

    function _fillDepositTokenPriceSafetyFactorsDefaultMap() private {
        _depositTokenPriceSafetyFactors[Enums.AssetTypes.STABLE][
            Enums.StrategyTimeLimitsInDays.THIRTY
        ] = 1000;
        _depositTokenPriceSafetyFactors[Enums.AssetTypes.STABLE][
            Enums.StrategyTimeLimitsInDays.NINETY
        ] = 1000;
        _depositTokenPriceSafetyFactors[Enums.AssetTypes.STABLE][
            Enums.StrategyTimeLimitsInDays.ONE_HUNDRED_AND_EIGHTY
        ] = 1000;
        _depositTokenPriceSafetyFactors[Enums.AssetTypes.STABLE][
            Enums.StrategyTimeLimitsInDays.THREE_HUNDRED_AND_SIXTY_FIVE
        ] = 1000;
        _depositTokenPriceSafetyFactors[Enums.AssetTypes.ETH_BTC][
            Enums.StrategyTimeLimitsInDays.THIRTY
        ] = 1000;
        _depositTokenPriceSafetyFactors[Enums.AssetTypes.ETH_BTC][
            Enums.StrategyTimeLimitsInDays.NINETY
        ] = 1000;
        _depositTokenPriceSafetyFactors[Enums.AssetTypes.ETH_BTC][
            Enums.StrategyTimeLimitsInDays.ONE_HUNDRED_AND_EIGHTY
        ] = 1000;
        _depositTokenPriceSafetyFactors[Enums.AssetTypes.ETH_BTC][
            Enums.StrategyTimeLimitsInDays.THREE_HUNDRED_AND_SIXTY_FIVE
        ] = 1000;
        _depositTokenPriceSafetyFactors[Enums.AssetTypes.BLUE_CHIP][
            Enums.StrategyTimeLimitsInDays.THIRTY
        ] = 900;
        _depositTokenPriceSafetyFactors[Enums.AssetTypes.BLUE_CHIP][
            Enums.StrategyTimeLimitsInDays.NINETY
        ] = 800;
        _depositTokenPriceSafetyFactors[Enums.AssetTypes.BLUE_CHIP][
            Enums.StrategyTimeLimitsInDays.ONE_HUNDRED_AND_EIGHTY
        ] = 650;
        _depositTokenPriceSafetyFactors[Enums.AssetTypes.BLUE_CHIP][
            Enums.StrategyTimeLimitsInDays.THREE_HUNDRED_AND_SIXTY_FIVE
        ] = 500;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Enums {
    enum BuyFrequency {
        DAILY,
        WEEKLY,
        BI_WEEKLY,
        MONTHLY
    }

    enum AssetTypes {
        STABLE,
        ETH_BTC,
        BLUE_CHIP
    }

    enum StrategyTimeLimitsInDays {
        THIRTY,
        NINETY,
        ONE_HUNDRED_AND_EIGHTY,
        THREE_HUNDRED_AND_SIXTY_FIVE
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

library Errors {
    error Forbidden(string message);

    error InvalidParameters(string message);

    /**
     * @dev Attempted to deposit more assets than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxDeposit(
        address receiver,
        uint256 assets,
        uint256 max
    );

    error SwapPathNotFound(string message);

    error InvalidTxEtherAmount(string message);

    error NotEnoughEther(string message);

    error EtherTransferFailed(string message);

    error TokenTransferFailed(string message);

    error InvalidTokenBalance(string message);

    error PriceFeedError(string message);

    error UpdateConditionsNotMet();

    error ZeroOrNegativeVaultWithdrawAmount();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Enums} from "Enums.sol";
import {IERC20} from "ERC20.sol";

library ConfigTypes {
    struct InitMultiAssetVaultParams {
        string name;
        string symbol;
        address payable treasury;
        address payable creator;
        address factory;
        bool isActive;
        IERC20 depositAsset;
        IERC20[] buyAssets;
        uint256 creatorPercentageFeeOnDeposit;
        uint256 treasuryPercentageFeeOnBalanceUpdate;
    }
    struct InitMultiAssetVaultFactoryParams {
        string name;
        string symbol;
        address depositAsset;
        address[] buyAssets;
    }

    /**
     * @notice Each strategy requires a `strategyWorker` address as input enabling:
     * - future upgrades of `strategyWorker` without breaking compatibility.
     * - scalability of Gelato Automation in case of to many strategies managed by 1 Resolver contract.
     *
     * @dev When deploying a new `strategyWorker`, ensure a corresponding Resolver
     * is deployed and Gelato Automation is configured accordingly.
     */
    struct StrategyParams {
        uint256[] buyPercentages;
        Enums.BuyFrequency buyFrequency;
        address strategyWorker;
        address strategyManager;
    }

    struct WhitelistedDepositAsset {
        address assetAddress;
        Enums.AssetTypes assetType;
        address oracleAddress;
        bool isActive;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "IERC20.sol";
import {IERC20Metadata} from "IERC20Metadata.sol";
import {Context} from "Context.sol";
import {IERC20Errors} from "draft-IERC6093.sol";

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "IERC20.sol";

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
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "Context.sol";

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
pragma solidity 0.8.21;

import {Enums} from "Enums.sol";
import {ConfigTypes} from "ConfigTypes.sol";

interface IStrategyManager {
    function addWhitelistedDepositAssets(
        ConfigTypes.WhitelistedDepositAsset[] calldata depositAssetsToWhitelist
    ) external;

    function deactivateWhitelistedDepositAsset(
        address depositTokenAddress
    ) external;

    function setMaxExpectedGasUnits(uint256 maxExpectedGasUnits) external;

    function setGasCostSafetyFactor(
        Enums.StrategyTimeLimitsInDays strategyTimeLimitsInDays,
        uint32 gasCostSafetyFactor
    ) external;

    function setDepositTokenPriceSafetyFactor(
        Enums.AssetTypes assetType,
        Enums.StrategyTimeLimitsInDays strategyTimeLimitsInDays,
        uint32 depositTokenPriceSafetyFactor
    ) external;

    function getMaxNumberOfActionsPerFrequency(
        Enums.BuyFrequency buyFrequency
    ) external view returns (uint256);

    function getWhitelistedDepositAssetAddresses()
        external
        view
        returns (address[] memory);

    function getWhitelistedDepositAsset(
        address depositAssetAddress
    ) external view returns (ConfigTypes.WhitelistedDepositAsset memory);

    function simulateMinDepositValue(
        ConfigTypes.WhitelistedDepositAsset calldata whitelistedDepositAsset,
        uint256 maxNumberOfStrategyActions,
        Enums.BuyFrequency buyFrequency,
        uint256 treasuryPercentageFeeOnBalanceUpdate,
        uint256 depositAssetDecimals,
        uint256 previousBalance,
        uint256 gasPriceWei
    ) external view returns (uint256 minDepositValue);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.21;

/**
 * @title PercentageMath library
 * @author Pulsar Finance (Adapted from Bend DAO)
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;
    uint256 constant ONE_PERCENT = 1e2; //100, 1%
    uint256 constant TEN_PERCENT = 1e3; //1000, 10%
    uint256 constant ONE_THOUSANDTH_PERCENT = 1e1; //10, 0.1%
    uint256 constant ONE_TEN_THOUSANDTH_PERCENT = 1; //1, 0.01%

    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(
        uint256 value,
        uint256 percentage
    ) internal pure returns (uint256) {
        if (value == 0 || percentage == 0) {
            return 0;
        }

        require(
            value <= (type(uint256).max - HALF_PERCENT) / percentage,
            "Percentage Math: Multiplication Overflow"
        );

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(
        uint256 value,
        uint256 percentage
    ) internal pure returns (uint256) {
        require(percentage != 0, "Percentage Math: Division by Zero");
        uint256 halfPercentage = percentage / 2;

        require(
            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
            "Percentage Math: Multiplication Overflow"
        );

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPriceFeedsDataConsumer {
    function getDataFeedLatestPriceAndDecimals(
        address oracleAddress
    ) external view returns (uint256, uint256);

    function getNativeTokenDataFeedLatestPriceAndDecimals()
        external
        view
        returns (uint256, uint256);
}