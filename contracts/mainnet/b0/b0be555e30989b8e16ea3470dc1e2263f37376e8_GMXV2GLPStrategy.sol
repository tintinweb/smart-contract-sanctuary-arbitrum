// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IGMXV2GLPStrategy } from "./interfaces/IGMXV2GLPStrategy.sol";
import { StrategyErrors } from "../../libraries/StrategyErrors.sol";
import { IStrategy } from "../../interfaces/dollet/IStrategy.sol";
import { AddressUtils } from "../../libraries/AddressUtils.sol";
import { ERC20Lib } from "../../libraries/ERC20Lib.sol";
import { IRewardRouter } from "./interfaces/IGMXV2.sol";
import { Strategy } from "../Strategy.sol";

/**
 * @title Dollet GMXV2GLPStrategy contract
 * @author Dollet Team
 * @notice An implementation of the GMXV2GLPStrategy contract.
 */
contract GMXV2GLPStrategy is Strategy, IGMXV2GLPStrategy {
    using AddressUtils for address;

    IRewardRouter public gmxGlpHandler;
    IRewardRouter public gmxRewardsHandler;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes this contract with initial values.
     * @param _initParams Strategy initialization parameters structure.
     */
    function initialize(InitParams calldata _initParams) external initializer {
        AddressUtils.onlyContract(_initParams.gmxGlpHandler);
        AddressUtils.onlyContract(_initParams.gmxRewardsHandler);

        gmxGlpHandler = IRewardRouter(_initParams.gmxGlpHandler);
        gmxRewardsHandler = IRewardRouter(_initParams.gmxRewardsHandler);

        _strategyInitUnchained(
            _initParams.adminStructure,
            _initParams.strategyHelper,
            _initParams.feeManager,
            _initParams.weth,
            _initParams.want,
            _initParams.calculations,
            _initParams.tokensToCompound,
            _initParams.minimumsToCompound
        );
    }

    /// @inheritdoc IGMXV2GLPStrategy
    function setGmxGlpHandler(address _newGmxGlpHandler) external {
        _onlySuperAdmin();

        AddressUtils.onlyContract(_newGmxGlpHandler);

        gmxGlpHandler = IRewardRouter(_newGmxGlpHandler);
    }

    /// @inheritdoc IGMXV2GLPStrategy
    function setGmxRewardsHandler(address _newGmxRewardsHandler) external {
        _onlySuperAdmin();

        AddressUtils.onlyContract(_newGmxRewardsHandler);

        gmxRewardsHandler = IRewardRouter(_newGmxRewardsHandler);
    }

    /// @inheritdoc IStrategy
    function balance() public view override returns (uint256) {
        return _getTokenBalance(want);
    }

    /**
     * @notice Performs a deposit operation. Adds `_token` as the liquidity to the GMX V2 protocol.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of the token to deposit.
     * @param _additionalData Encoded data which will be used in the time of deposit.
     */
    function _deposit(address _token, uint256 _amount, bytes calldata _additionalData) internal override {
        uint256 _amountOut;
        (uint256 _minTokenOut) = abi.decode(_additionalData, (uint256));
        IRewardRouter _gmxGlpHandler = gmxGlpHandler;

        ERC20Lib.safeApprove(_token, address(_gmxGlpHandler.glpManager()), _amount);

        _amountOut = _gmxGlpHandler.mintAndStakeGlp(_token, _amount, 0, 0);

        if (_amountOut < _minTokenOut) revert StrategyErrors.InsufficientDepositTokenOut();
    }

    /**
     * @notice Performs a withdrawal operation. Removes the liquidity in `_tokenOut` from the GMX V2 protocol.
     * @param _tokenOut Address of the token to withdraw in.
     * @param _wantToWithdraw The want tokens amount to withdraw.
     * @param _additionalData Encoded data which will be used in the time of withdraw.
     */
    function _withdraw(address _tokenOut, uint256 _wantToWithdraw, bytes calldata _additionalData) internal override {
        uint256 _amountOut;
        (uint256 _minTokenOut) = abi.decode(_additionalData, (uint256));
        IRewardRouter _gmxGlpHandler = gmxGlpHandler;

        ERC20Lib.safeApprove(want, address(_gmxGlpHandler), _wantToWithdraw);

        _amountOut = _gmxGlpHandler.unstakeAndRedeemGlp(_tokenOut, _wantToWithdraw, 0, address(this));

        if (_amountOut < _minTokenOut) revert StrategyErrors.InsufficientWithdrawalTokenOut();
    }

    /**
     * @notice Compounds rewards from GMX V2. Optional param: encoded data containing information about the compound
     *         operation.
     */
    function _compound(bytes memory) internal override {
        IRewardRouter _gmxRewardsHandler = gmxRewardsHandler;
        address _weth = address(weth);
        uint256 _claimableWeth = _gmxRewardsHandler.feeGlpTracker().claimable(address(this)) + _getTokenBalance(_weth);

        if (_claimableWeth != 0 && _claimableWeth >= minimumToCompound[_weth]) {
            _gmxRewardsHandler.handleRewards(true, true, true, true, true, true, false);

            uint256 _wethAmount = _getTokenBalance(_weth);
            IRewardRouter _gmxGlpHandler = gmxGlpHandler;

            ERC20Lib.safeApprove(_weth, address(_gmxGlpHandler.glpManager()), _wethAmount);

            uint256 _amountOut = _gmxGlpHandler.mintAndStakeGlp(_weth, _wethAmount, 0, 0);

            emit Compounded(_amountOut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IRewardRouter } from "./IGMXV2.sol";

/**
 * @title Dollet GMXV2GLPStrategy interface
 * @author Dollet Team
 * @notice An interface of the GMXV2GLPStrategy contract.
 */
interface IGMXV2GLPStrategy {
    /**
     * @notice Strategy initialization parameters structure.
     * @param adminStructure AdminStructure contract address.
     * @param strategyHelper StrategyHelper contract address.
     * @param feeManager FeeManager contract address.
     * @param weth WETH token contract address.
     * @param want Want token contract address.
     * @param calculations Calculations contract address.
     * @param gmxGlpHandler GMX's GLP handler contract address.
     * @param gmxRewardsHandler GMX's rewards handler contract address.
     * @param tokensToCompound An array of the tokens to set the minimum to compound.
     * @param minimumsToCompound An array of the minimum amounts to compound.
     */
    struct InitParams {
        address adminStructure;
        address strategyHelper;
        address feeManager;
        address weth;
        address want;
        address calculations;
        address gmxGlpHandler;
        address gmxRewardsHandler;
        address[] tokensToCompound;
        uint256[] minimumsToCompound;
    }

    /**
     * @notice Sets a new GMX's GLP handler contract address by super admin.
     * @param _newGmxGlpHandler A new GMX's GLP handler contract address.
     */
    function setGmxGlpHandler(address _newGmxGlpHandler) external;

    /**
     * @notice Sets a new GMX's rewards handler contract address by super admin.
     * @param _newGmxRewardsHandler A new GMX's rewards handler contract address.
     */
    function setGmxRewardsHandler(address _newGmxRewardsHandler) external;

    /**
     * @notice Returns an address of the GMX's GLP handler contract.
     * @return An address of the GMX's GLP handler contract.
     */
    function gmxGlpHandler() external view returns (IRewardRouter);

    /**
     * @notice Returns an address of the GMX's rewards handler contract.
     * @return An address of the GMX's rewards handler contract.
     */
    function gmxRewardsHandler() external view returns (IRewardRouter);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Dollet StrategyErrors library
 * @author Dollet Team
 * @notice Library with all Strategy errors.
 */
library StrategyErrors {
    error InsufficientWithdrawalTokenOut();
    error InsufficientDepositTokenOut();
    error SlippageToleranceTooHigh();
    error NotVault(address _caller);
    error ETHTransferError();
    error WrongStuckToken();
    error LengthsMismatch();
    error UseWantToken();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IAdminStructure } from "./IAdminStructure.sol";
import { IStrategyHelper } from "./IStrategyHelper.sol";
import { IFeeManager } from "./IFeeManager.sol";
import { IVault } from "./IVault.sol";
import { IWETH } from "../IWETH.sol";

/**
 * @title Dollet IStrategy
 * @author Dollet Team
 * @notice Interface with all types, events, external, and public methods for the Strategy contract.
 */
interface IStrategy {
    struct MinimumToCompound {
        address token;
        uint256 minAmount;
    }

    /**
     * @notice Logs information about deposit operation.
     * @param _token A token address that was used at the time of deposit.
     * @param _amount An amount of tokens that were deposited.
     * @param _user A user address who executed a deposit operation.
     * @param _depositedWant An amount of want tokens that were deposited in the underlying protocol.
     */
    event Deposit(address _token, uint256 _amount, address _user, uint256 _depositedWant);

    /**
     * @notice Logs information about withdrawal operation.
     * @param _token A token address that was used at the time of withdrawal.
     * @param _amount An amount of tokens that were withdrawn.
     * @param _user A user address who executed a withdraw operation.
     * @param _withdrawnWant An amount of want tokens that were withdrawn from the underlying protocol.
     */
    event Withdraw(address _token, uint256 _amount, address _user, uint256 _withdrawnWant);

    /**
     * @notice Logs information about compound operation.
     * @param _amount An amount of want tokens that were compounded and deposited in the underlying protocol.
     */
    event Compounded(uint256 _amount);

    /**
     * @notice Logs information when a new Vault contract address was set.
     * @param _vault A new Vault contract address.
     */
    event VaultSet(address indexed _vault);

    /**
     * @notice Logs information about the withdrawal of stuck tokens.
     * @param _caller An address of the admin who executed the withdrawal operation.
     * @param _token An address of a token that was withdrawn.
     * @param _amount An amount of tokens that were withdrawn.
     */
    event WithdrawStuckTokens(address _caller, address _token, uint256 _amount);

    /**
     * @notice Logs information about new slippage tolerance.
     * @param _slippageTolerance A new slippage tolerance that was set.
     */
    event SlippageToleranceSet(uint16 _slippageTolerance);

    /**
     * @notice Logs information when a fee is charged.
     * @param _feeType A type of fee charged.
     * @param _feeAmount An amount of fee charged.
     * @param _feeRecipient A recipient of the charged fee.
     * @param _token The addres of the token used.
     */
    event ChargedFees(IFeeManager.FeeType _feeType, uint256 _feeAmount, address _feeRecipient, address _token);

    /**
     * @notice Logs information when the minimum amount to compound is changed.
     * @param _token The address of the token.
     * @param _minimum The new minimum amount to compound.
     */
    event MinimumToCompoundChanged(address _token, uint256 _minimum);

    /**
     * @notice Deposit to the strategy.
     * @param _user Address of the user providing the deposit tokens.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of tokens to deposit.
     * @param _additionalData Additional encoded data for the deposit.
     */
    function deposit(address _user, address _token, uint256 _amount, bytes calldata _additionalData) external;

    /**
     * @notice Withdraw from the strategy.
     * @param _recipient Address of the recipient to receive the tokens.
     * @param _user Address of the owner of the deposit (shares).
     * @param _originalToken Address of the token deposited (useful when using ETH).
     * @param _token Address of the token to withdraw.
     * @param _wantToWithdraw Amount of want tokens to withdraw from the strategy.
     * @param _maxUserWant Maximum user want tokens available to withdraw.
     * @param _additionalData Additional encoded data for the withdrawal.
     */
    function withdraw(
        address _recipient,
        address _user,
        address _originalToken,
        address _token,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        bytes calldata _additionalData
    )
        external;

    /**
     * @notice Executes a compound on the strategy.
     * @param _data Encoded data which will be used in the time of compound.
     */
    function compound(bytes calldata _data) external;

    /**
     * @notice Allows the super admin to change the admin structure.
     * @param _adminStructure Admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Sets a Vault contract address. Only super admin is able to set a new Vault address.
     * @param _vault A new Vault contract address.
     */
    function setVault(address _vault) external;

    /**
     * @notice Sets a new slippage tolerance by super admin.
     * @param _slippageTolerance A new slippage tolerance (with 2 decimals).
     */
    function setSlippageTolerance(uint16 _slippageTolerance) external;

    /**
     * @notice Handles the case where tokens get stuck in the contract. Allows the admin to send the tokens to the super
     *         admin.
     * @param _token The address of the stuck token.
     */
    function inCaseTokensGetStuck(address _token) external;

    /**
     * @notice Edits the minimum token compound amounts.
     * @param _tokens An array of token addresses to edit.
     * @param _minAmounts An array of minimum harvest amounts corresponding to the tokens.
     */
    function editMinimumTokenCompound(address[] calldata _tokens, uint256[] calldata _minAmounts) external;

    /**
     * @notice Returns the balance of the strategy held in the strategy or underlying protocols.
     * @return The balance of the strategy.
     */
    function balance() external view returns (uint256);

    /**
     * @notice Returns the total deposited want token amount by a user.
     * @param _user A user address to get the total deposited want token amount for.
     * @return The total deposited want token amount by a user.
     */
    function userWantDeposit(address _user) external view returns (uint256);

    /**
     * @notice Returns the minimum amount required to execute reinvestment for a specific token.
     * @param _token The address of the token.
     * @return The minimum amount required for reinvestment.
     */
    function minimumToCompound(address _token) external view returns (uint256);

    /**
     * @notice Returns AdminStructure contract address.
     * @return AdminStructure contract address.
     */
    function adminStructure() external view returns (IAdminStructure);

    /**
     * @notice Returns StrategyHelper contract address.
     * @return StrategyHelper contract address.
     */
    function strategyHelper() external view returns (IStrategyHelper);

    /**
     * @notice Returns FeeManager contract address.
     * @return FeeManager contract address.
     */
    function feeManager() external view returns (IFeeManager);

    /**
     * @notice Returns Vault contract address.
     * @return Vault contract address.
     */
    function vault() external view returns (IVault);

    /**
     * @notice Returns WETH token contract address.
     * @return WETH token contract address.
     */
    function weth() external view returns (IWETH);

    /**
     * @notice Returns total deposited want token amount.
     * @return Total deposited want token amount.
     */
    function totalWantDeposits() external view returns (uint256);

    /**
     * @notice Returns the token address that should be deposited in the underlying protocol.
     * @return The token address that should be deposited in the underlying protocol.
     */
    function want() external view returns (address);

    /**
     * @notice Returns a default slippage tolerance percentage (with 2 decimals).
     * @return A default slippage tolerance percentage (with 2 decimals).
     */
    function slippageTolerance() external view returns (uint16);

    /**
     * @notice Returns maximum slipage tolerance value (with two decimals).
     * @return Maximum slipage tolerance value (with two decimals).
     */
    function MAX_SLIPPAGE_TOLERANCE() external view returns (uint16);

    /**
     * @notice Returns 100% value (with two decimals).
     * @return 100% value (with two decimals).
     */
    function ONE_HUNDRED_PERCENTS() external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @title Dollet AddressUtils library
 * @author Dollet Team
 * @notice A collection of helpers related to the address type.
 */
library AddressUtils {
    using AddressUpgradeable for address;

    error NotContract(address _address);
    error ZeroAddress();

    /**
     * @notice Checks if an address is a contract.
     * @param _address An address to check.
     */
    function onlyContract(address _address) internal view {
        if (!_address.isContract()) revert NotContract(_address);
    }

    /**
     * @notice Checks if an address is not zero address.
     * @param _address An address to check.
     */
    function onlyNonZeroAddress(address _address) internal pure {
        if (_address == address(0)) revert ZeroAddress();
    }

    /**
     * @notice Checks if a token address is a contract or native token.
     * @param _address An address to check.
     */
    function onlyTokenContract(address _address) internal view {
        if (_address == address(0)) return; // ETH
        if (!_address.isContract()) revert NotContract(_address);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IERC20PermitUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20PermitUpgradeable.sol";

/**
 * @notice Secp256k1 signature values.
 * @param deadline Timestamp at which the signature expires.
 * @param v `v` portion of the signature.
 * @param r `r` portion of the signature.
 * @param s `s` portion of the signature.
 */
struct Signature {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @title Dollet ERC20Lib
 * @author Dollet Team
 * @notice Helper library that implements some additional methods for interacting with ERC-20 tokens.
 */
library ERC20Lib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Transfers specified amount of token from `_from` to `_to`.
     * @param _token A token to transfer.
     * @param _from A sender of tokens.
     * @param _to A recipient of tokens.
     * @param _amount A number of tokens to transfer.
     */
    function pull(address _token, address _from, address _to, uint256 _amount) internal {
        IERC20Upgradeable(_token).safeTransferFrom(_from, _to, _amount);
    }

    /**
     * @notice Transfers specified amount of token from `_from` to `_to` using permit.
     * @param _token A token to transfer.
     * @param _from A sender of tokens.
     * @param _to A recipient of tokens.
     * @param _amount A number of tokens to transfer.
     * @param _signature A signature of the permit to use at the time of transfer.
     */
    function pullPermit(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        Signature memory _signature
    )
        internal
    {
        IERC20PermitUpgradeable(_token).permit(
            _from, address(this), _amount, _signature.deadline, _signature.v, _signature.r, _signature.s
        );
        pull(_token, _from, _to, _amount);
    }

    /**
     * @notice Transfers a specified amount of ERC-20 tokens to `_to`.
     * @param _token A token to transfer.
     * @param _to A recipient of tokens.
     * @param _amount A number of tokens to transfer.
     */
    function push(address _token, address _to, uint256 _amount) internal {
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    /**
     * @notice Transfers the current balance of ERC-20 tokens to `_to`.
     * @param _token A token to transfer.
     * @param _to A recipient of tokens.
     */
    function pushAll(address _token, address _to) internal {
        uint256 _amount = IERC20Upgradeable(_token).balanceOf(address(this));

        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    /**
     * @notice Executes a safe approval operation on a token. If the previous allowance is GT 0, it sets it to 0 and
     *         then executes a new approval.
     * @param _token A token to approve.
     * @param _spender A spender of the token to approve for.
     * @param _amount An amount of tokens to approve.
     */
    function safeApprove(address _token, address _spender, uint256 _amount) internal {
        if (IERC20Upgradeable(_token).allowance(address(this), _spender) != 0) {
            IERC20Upgradeable(_token).safeApprove(_spender, 0);
        }

        IERC20Upgradeable(_token).safeApprove(_spender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IGLPManager {
    function getPrice(bool _maximise) external view returns (uint256);
}

interface IRewardTracker {
    function claimable(address _account) external view returns (uint256);
}

interface IRewardRouter {
    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    )
        external
        returns (uint256);

    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    )
        external
        returns (uint256);

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    )
        external;

    function glpManager() external view returns (IGLPManager);

    function feeGlpTracker() external view returns (IRewardTracker);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IAdminStructure } from "../interfaces/dollet/IAdminStructure.sol";
import { IStrategyHelper } from "../interfaces/dollet/IStrategyHelper.sol";
import { ICalculations } from "./../interfaces/dollet/ICalculations.sol";
import { IFeeManager } from "../interfaces/dollet/IFeeManager.sol";
import { StrategyErrors } from "../libraries/StrategyErrors.sol";
import { IStrategy } from "../interfaces/dollet/IStrategy.sol";
import { AddressUtils } from "../libraries/AddressUtils.sol";
import { IVault } from "../interfaces/dollet/IVault.sol";
import { ERC20Lib } from "../libraries/ERC20Lib.sol";
import { IWETH } from "./../interfaces/IWETH.sol";

/**
 * @title Dollet Strategy contract
 * @author Dollet Team
 * @notice Abstract Strategy contract. All strategies should inherit from it because it contains the common logic for
 *         all strategies.
 */
abstract contract Strategy is Initializable, ReentrancyGuardUpgradeable, IStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUtils for address;

    uint16 public constant ONE_HUNDRED_PERCENTS = 10_000; // 100.00%
    uint16 public constant MAX_SLIPPAGE_TOLERANCE = 3000; // 30.00%

    mapping(address user => uint256 amount) public userWantDeposit;
    mapping(address token => uint256 minimum) public minimumToCompound;
    IAdminStructure public adminStructure;
    IStrategyHelper public strategyHelper;
    IFeeManager public feeManager;
    IVault public vault;
    IWETH public weth;
    ICalculations public calculations;
    uint256 public totalWantDeposits;
    address public want;
    uint16 public slippageTolerance;

    // Allows to receive native tokens
    receive() external payable { }

    /// @inheritdoc IStrategy
    function deposit(address _user, address _token, uint256 _amount, bytes calldata _additionalData) external {
        _onlyVault();

        uint256 _wantBefore = balance();

        _deposit(_token, _amount, _additionalData);

        uint256 _depositedWant = balance() - _wantBefore;

        totalWantDeposits += _depositedWant;
        unchecked {
            userWantDeposit[_user] += _depositedWant;
        }

        emit Deposit(_token, _amount, _user, _depositedWant);
    }

    /// @inheritdoc IStrategy
    function withdraw(
        address _recipient,
        address _user,
        address _originalToken,
        address _token,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        bytes calldata _additionalData
    )
        external
    {
        _onlyVault();

        uint256 _tokenBalanceBefore = _getTokenBalance(_token);

        _withdraw(_token, _wantToWithdraw, _additionalData);

        uint256 _withdrawalTokenOut = _getTokenBalance(_token) - _tokenBalanceBefore;
        (uint256 _depositUsed, uint256 _rewardsUsed, uint256 _wantDepositUsed,) =
            calculations.calculateUsedAmounts(_user, _wantToWithdraw, _maxUserWant, _withdrawalTokenOut);

        if (_wantDepositUsed != 0) {
            userWantDeposit[_user] -= _wantDepositUsed;
            unchecked {
                totalWantDeposits -= _wantDepositUsed;
            }
        }

        _withdrawalTokenOut -= _chargeFees(IFeeManager.FeeType.MANAGEMENT, _token, _depositUsed);
        _withdrawalTokenOut -= _chargeFees(IFeeManager.FeeType.PERFORMANCE, _token, _rewardsUsed);

        _pushTokens(_originalToken, _recipient, _withdrawalTokenOut);

        emit Withdraw(_originalToken, _withdrawalTokenOut, _recipient, _wantToWithdraw);
    }

    /// @inheritdoc IStrategy
    function compound(bytes memory _data) external nonReentrant {
        _compound(_data);
    }

    /// @inheritdoc IStrategy
    function setAdminStructure(address _adminStructure) external {
        _onlySuperAdmin();

        AddressUtils.onlyContract(_adminStructure);

        adminStructure = IAdminStructure(_adminStructure);
    }

    /// @inheritdoc IStrategy
    function setVault(address _vault) external {
        _onlySuperAdmin();

        AddressUtils.onlyContract(_vault);

        vault = IVault(_vault);

        emit VaultSet(_vault);
    }

    /// @inheritdoc IStrategy
    function setSlippageTolerance(uint16 _slippageTolerance) external {
        _onlySuperAdmin();

        if (_slippageTolerance > MAX_SLIPPAGE_TOLERANCE) revert StrategyErrors.SlippageToleranceTooHigh();

        slippageTolerance = _slippageTolerance;

        emit SlippageToleranceSet(_slippageTolerance);
    }

    /// @inheritdoc IStrategy
    function inCaseTokensGetStuck(address _token) external {
        _onlyAdmin();

        if (_token == want) revert StrategyErrors.WrongStuckToken();

        uint256 _amount;

        if (_token != address(0)) {
            _amount = IERC20Upgradeable(_token).balanceOf(address(this));

            ERC20Lib.push(_token, adminStructure.superAdmin(), _amount);
        } else {
            _amount = address(this).balance;

            payable(adminStructure.superAdmin()).transfer(_amount);
        }

        emit WithdrawStuckTokens(adminStructure.superAdmin(), _token, _amount);
    }

    /// @inheritdoc IStrategy
    function editMinimumTokenCompound(address[] calldata _tokens, uint256[] calldata _minAmounts) external {
        _onlyAdmin();
        _editMinimumTokenCompound(_tokens, _minAmounts);
    }

    /// @inheritdoc IStrategy
    function balance() public view virtual returns (uint256);

    /**
     * @notice Initializes this Strategy contract.
     * @param _adminStructure AdminStructure contract address.
     * @param _strategyHelper A helper contract address that is used in every strategy.
     * @param _feeManager FeeManager contract address.
     * @param _weth WETH token contract address.
     * @param _want A token address that should be deposited in the underlying protocol.
     * @param _tokensToCompound An array of the tokens to set the minimum to compound.
     * @param _minimumsToCompound An array of the minimum amounts to compound.
     */
    function _strategyInitUnchained(
        address _adminStructure,
        address _strategyHelper,
        address _feeManager,
        address _weth,
        address _want,
        address _calculations,
        address[] calldata _tokensToCompound,
        uint256[] calldata _minimumsToCompound
    )
        internal
        onlyInitializing
    {
        AddressUtils.onlyContract(_adminStructure);
        AddressUtils.onlyContract(_strategyHelper);
        AddressUtils.onlyContract(_feeManager);
        AddressUtils.onlyContract(_weth);
        AddressUtils.onlyContract(_want);
        AddressUtils.onlyContract(_calculations);

        adminStructure = IAdminStructure(_adminStructure);
        strategyHelper = IStrategyHelper(_strategyHelper);
        feeManager = IFeeManager(_feeManager);
        weth = IWETH(_weth);
        want = _want;
        calculations = ICalculations(_calculations);

        _editMinimumTokenCompound(_tokensToCompound, _minimumsToCompound);
    }

    /**
     * @notice Transfers ETH/ERC-20 tokens to the user.
     * @param _token A token address to transfer. Zero address for ETH.
     * @param _recipient A recipient of the tokens.
     * @param _amount An amount of tokens to transfer.
     */
    function _pushTokens(address _token, address _recipient, uint256 _amount) internal {
        if (_token == address(0)) {
            weth.withdraw(_amount);

            (bool _success,) = _recipient.call{ value: _amount }("");

            if (!_success) revert StrategyErrors.ETHTransferError();
        } else {
            ERC20Lib.push(_token, _recipient, _amount);
        }
    }

    /**
     * @notice Edits the minimum token compound amounts.
     * @param _tokens An array of token addresses to edit.
     * @param _minAmounts An array of minimum harvest amounts corresponding to the tokens.
     */
    function _editMinimumTokenCompound(address[] calldata _tokens, uint256[] calldata _minAmounts) internal {
        uint256 _tokensLength = _tokens.length;

        if (_tokensLength != _minAmounts.length) revert StrategyErrors.LengthsMismatch();

        for (uint256 _i; _i < _tokensLength;) {
            minimumToCompound[_tokens[_i]] = _minAmounts[_i];

            emit MinimumToCompoundChanged(_tokens[_i], _minAmounts[_i]);

            unchecked {
                ++_i;
            }
        }
    }

    /**
     * @notice Prototype of the `_deposit()` method that should be implemented in each strategy.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of the token to deposit.
     * @param _additionalData Encoded data which will be used in the time of deposit.
     */
    function _deposit(address _token, uint256 _amount, bytes calldata _additionalData) internal virtual;

    /**
     * @notice Prototype of the `_withdraw()` method that should be implemented in each strategy.
     * @param _tokenOut Address of the token to withdraw in.
     * @param _wantToWithdraw The want amount to withdraw.
     * @param _additionalData Encoded data which will be used in the time of withdraw.
     */
    function _withdraw(address _tokenOut, uint256 _wantToWithdraw, bytes calldata _additionalData) internal virtual;

    /**
     * @notice Prototype of the `_compound()` method that should be implemented in each strategy.
     * @param _data Encoded data to use at the time of the compound operation.
     */
    function _compound(bytes memory _data) internal virtual;

    /**
     * @notice Checks if a transaction sender is a super admin.
     */
    function _onlySuperAdmin() internal view {
        adminStructure.isValidSuperAdmin(msg.sender);
    }

    /**
     * @notice Checks if a transaction sender is an admin.
     */
    function _onlyAdmin() internal view {
        adminStructure.isValidAdmin(msg.sender);
    }

    /**
     * @notice Checks if a transaction sender is a vault contract.
     */
    function _onlyVault() internal view {
        if (msg.sender != address(vault)) revert StrategyErrors.NotVault(msg.sender);
    }

    /**
     * @notice Retrieves the balance of the specified token held by the strategy,
     * @param _token The address of the token to retrieve the balance for.
     * @return The balance of the token.
     */
    function _getTokenBalance(address _token) internal view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(this));
    }

    /**
     * @notice Charges fees in the specified token.
     * @param _feeType The type of fee to charge.
     * @param _token The token in which to charge the fees.
     * @param _amount The amount of tokens to charge fees on.
     * @return The amount taken charged as fee.
     */
    function _chargeFees(IFeeManager.FeeType _feeType, address _token, uint256 _amount) private returns (uint256) {
        if (_amount == 0) return 0;

        IFeeManager _feeManager = feeManager;
        (address _feeRecipient, uint16 _fee) = _feeManager.fees(address(this), _feeType);

        if (_fee == 0) return 0;

        uint256 _feeAmount = (_amount * _fee) / ONE_HUNDRED_PERCENTS;

        IERC20Upgradeable(_token).safeTransfer(_feeRecipient, _feeAmount);

        emit ChargedFees(_feeType, _feeAmount, _feeRecipient, _token);

        return _feeAmount;
    }

    uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Dollet ISuperAdmin
 * @author Dollet Team
 * @notice Interface for managing the super admin role.
 */
interface ISuperAdmin {
    /**
     * @notice Logs the information about nomination of a potential super admin.
     * @param _potentialSuperAdmin The address of the potential super admin.
     */
    event SuperAdminNominated(address _potentialSuperAdmin);

    /**
     * @notice Logs the information when the super admin role is transferred.
     * @param _oldSuperAdmin The address of the old super admin.
     * @param _newSuperAdmin The address of the new super admin.
     */
    event SuperAdminChanged(address _oldSuperAdmin, address _newSuperAdmin);

    /**
     * @notice Transfers the super admin role to a potential super admin address using pull-over-push pattern.
     * @param _superAdmin An address of a potential super admin.
     */
    function transferSuperAdmin(address _superAdmin) external;

    /**
     * @notice Accepts the super admin role by a potential super admin.
     */
    function acceptSuperAdmin() external;

    /**
     * @notice Returns the address of the super admin.
     * @return The address of the super admin.
     */
    function superAdmin() external view returns (address);

    /**
     * @notice Returns the address of the potential super admin.
     * @return The address of the potential super admin.
     */
    function potentialSuperAdmin() external view returns (address);

    /**
     * @notice Checks if the caller is a valid super admin.
     * @param caller The address to check.
     */
    function isValidSuperAdmin(address caller) external view;
}

/**
 * @title Dollet IAdminStructure
 * @author Dollet Team
 * @notice Interface for managing admin roles.
 */
interface IAdminStructure is ISuperAdmin {
    /**
     * @notice Logs the information when an admin is added.
     * @param admin The address of the added admin.
     */
    event AddedAdmin(address admin);

    /**
     * @notice Logs the information when an admin is removed.
     * @param admin The address of the removed admin.
     */
    event RemovedAdmin(address admin);

    /**
     * @notice Adds multiple addresses as admins.
     * @param _admins The addresses to add as admins.
     */
    function addAdmins(address[] calldata _admins) external;

    /**
     * @notice Removes multiple addresses from admins.
     * @param _admins The addresses to remove from admins.
     */
    function removeAdmins(address[] calldata _admins) external;

    /**
     * @notice Checks if the caller is a valid admin.
     * @param caller The address to check.
     */
    function isValidAdmin(address caller) external view;

    /**
     * @notice Checks if an account is an admin.
     * @param account The address to check.
     * @return A boolean indicating if the account is an admin.
     */
    function isAdmin(address account) external view returns (bool);

    /**
     * @notice Returns all the admin addresses.
     * @return An array of admin addresses.
     */
    function getAllAdmins() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IAdminStructure } from "./IAdminStructure.sol";

/**
 * @title Dollet IStrategyHelper
 * @author Dollet Team
 * @notice Interface for StrategyHelper contract.
 */
interface IStrategyHelper {
    /**
     * Structure for storing of swap path and the swap venue.
     */
    struct Path {
        address venue;
        bytes path;
    }

    /**
     * @notice Logs information when a new oracle was set.
     * @param _asset An asset address for which oracle was set.
     * @param _oracle A new oracle address.
     */
    event OracleSet(address indexed _asset, address indexed _oracle);

    /**
     * @notice Logs information when a new swap path was set.
     * @param _from From asset.
     * @param _to To asset.
     * @param _venue A venue which swap path was used.
     * @param _path A swap path itself.
     */
    event PathSet(address indexed _from, address indexed _to, address indexed _venue, bytes _path);

    /**
     * @notice Allows the super admin to change the admin structure contract.
     * @param _adminStructure Admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Sets a new oracle for the specified asset.
     * @param _asset An asset address for which to set an oracle.
     * @param _oracle A new oracle address.
     */
    function setOracle(address _asset, address _oracle) external;

    /**
     * @notice Sets a new swap path for two assets.
     * @param _from From asset.
     * @param _to To asset.
     * @param _venue A venue which swap path is used.
     * @param _path A swap path itself.
     */
    function setPath(address _from, address _to, address _venue, bytes calldata _path) external;

    /**
     * @notice Executes a swap of two assets.
     * @param _from From asset.
     * @param _to To asset.
     * @param _amount Amount of the first asset to swap.
     * @param _slippageTolerance Slippage tolerance percentage (with 2 decimals).
     * @param _recipient Recipient of the second asset.
     * @return _amountOut The second asset output amount.
     */
    function swap(
        address _from,
        address _to,
        uint256 _amount,
        uint16 _slippageTolerance,
        address _recipient
    )
        external
        returns (uint256 _amountOut);

    /**
     * @notice Returns an oracle address for the specified asset.
     * @param _asset An address of the asset for which to get the oracle address.
     * @return _oracle An oracle address for the specified asset.
     */
    function oracles(address _asset) external view returns (address _oracle);

    /**
     * @notice Returns the address of the venue where the swap should be executed and the swap path.
     * @param _from From asset.
     * @param _to To asset.
     * @return _venue The address of the venue where the swap should be executed.
     * @return _path The swap path.
     */
    function paths(address _from, address _to) external view returns (address _venue, bytes memory _path);

    /**
     * @notice Returns AdminStructure contract address.
     * @return _adminStructure AdminStructure contract address.
     */
    function adminStructure() external returns (IAdminStructure _adminStructure);

    /**
     * @notice Returns the price of the specified asset.
     * @param _asset The asset to get the price for.
     * @return _price The price of the specified asset.
     */
    function price(address _asset) external view returns (uint256 _price);

    /**
     * @notice Returns the value of the specified amount of the asset.
     * @param _asset The asset to value.
     * @param _amount The amount of asset to value.
     * @return _value The value of the specified amount of the asset.
     */
    function value(address _asset, uint256 _amount) external view returns (uint256 _value);

    /**
     * @notice Converts the first asset to the second asset.
     * @param _from From asset.
     * @param _to To asset.
     * @param _amount Amount of the first asset to convert.
     * @return _amountOut Amount of the second asset after the conversion.
     */
    function convert(address _from, address _to, uint256 _amount) external view returns (uint256 _amountOut);

    /**
     * @notice Returns 100.00% constant value (with to decimals).
     * @return 100.00% constant value (with to decimals).
     */
    function ONE_HUNDRED_PERCENTS() external pure returns (uint16);
}

/**
 * @title Dollet IStrategyHelperVenue
 * @author Dollet Team
 * @notice Interface for StrategyHelperVenue contracts.
 */
interface IStrategyHelperVenue {
    /**
     * @notice Executes a swap of two assets.
     * @param _asset First asset.
     * @param _path Path of the swap.
     * @param _amount Amount of the first asset to swap.
     * @param _minAmountOut Minimum output amount of the second asset.
     * @param _recipient Recipient of the second asset.
     * @param _deadline Deadline of the swap.
     */
    function swap(
        address _asset,
        bytes calldata _path,
        uint256 _amount,
        uint256 _minAmountOut,
        address _recipient,
        uint256 _deadline
    )
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IAdminStructure } from "./IAdminStructure.sol";

/**
 * @title Dollet IFeeManager
 * @author Dollet Team
 * @notice Interface for FeeManager contract.
 */
interface IFeeManager {
    /**
     * @notice Fee type enumeration.
     * @param MANAGEMENT Fee type: management
     * @param PERFORMANCE Fee type: performance
     */
    enum FeeType {
        MANAGEMENT, // 0
        PERFORMANCE // 1

    }

    /**
     * @notice Fee structure.
     * @param recipient recipient of the fee.
     * @param fee The fee (as percentage with 2 decimals).
     */
    struct Fee {
        address recipient;
        uint16 fee;
    }

    /**
     * @notice Logs the information when a new fee is set.
     * @param _strategy Strategy contract address for which the fee is set.
     * @param _feeType Type of the fee.
     * @param _fee The fee structure itself.
     */
    event FeeSet(address indexed _strategy, FeeType indexed _feeType, Fee _fee);

    /**
     * @notice Allows the super admin to change the admin structure contract.
     * @param _adminStructure Admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Sets a new fee to provided strategy.
     * @param _strategy The strategy contract address to set a new fee for.
     * @param _feeType The fee type to set.
     * @param _recipient The recipient of the fee.
     * @param _fee The fee (as percentage with 2 decimals).
     */
    function setFee(address _strategy, FeeType _feeType, address _recipient, uint16 _fee) external;

    /**
     * @notice Retrieves a fee and its recipient for the provided strategy and fee type.
     * @param _strategy The strategy contract address to get the fee for.
     * @param _feeType The fee type to get the fee for.
     * @return _recipient The recipient of the fee.
     * @return _fee The fee (as percentage with 2 decimals).
     */
    function fees(address _strategy, FeeType _feeType) external view returns (address _recipient, uint16 _fee);

    /**
     * @notice Returns an address of the AdminStructure contract.
     * @return The address of the AdminStructure contract.
     */
    function adminStructure() external returns (IAdminStructure);

    /**
     * @notice Returns MAX_FEE constant value (with two decimals).
     * @return MAX_FEE constant value (with two decimals).
     */
    function MAX_FEE() external pure returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { Signature } from "../../libraries/ERC20Lib.sol";
import { IAdminStructure } from "./IAdminStructure.sol";
import { IStrategy } from "./IStrategy.sol";
import { IWETH } from "../IWETH.sol";
import { ICalculations } from "../../interfaces/dollet/ICalculations.sol";

/**
 * @title Dollet IVault
 * @author Dollet Team
 * @notice Interface with all types, events, external, and public methods for the Vault contract.
 */
interface IVault {
    /**
     * @notice Token types enumeration.
     */
    enum TokenType {
        Deposit,
        Withdrawal
    }

    /**
     * @notice Structure of the values to store the token min deposit limit.
     */
    struct DepositLimit {
        address token;
        uint256 minAmount;
    }

    /**
     * @notice Logs information when token changes its status (allowed/disallowed).
     * @param _tokenType A type of the token.
     * @param _token A token address.
     * @param _status A new status of the token.
     */
    event TokenStatusChanged(TokenType _tokenType, address _token, uint256 _status);

    /**
     * @notice Logs information when the pause status is changed.
     * @param _status The new pause status (true or false).
     */
    event PauseStatusChanged(bool _status);

    /**
     * @notice Logs information about the withdrawal of stuck tokens.
     * @param _caller An address of the admin who executed the withdrawal operation.
     * @param _token An address of a token that was withdrawn.
     * @param _amount An amount of tokens that were withdrawn.
     */
    event WithdrawStuckTokens(address _caller, address _token, uint256 _amount);

    /**
     * @notice Logs when the deposit limit of a token has been set.
     * @param _limitBefore The deposit limit before.
     * @param _limitAfter The deposit limit after.
     */
    event DepositLimitsSet(DepositLimit _limitBefore, DepositLimit _limitAfter);

    /**
     * @notice Deposit to the strategy.
     * @param _user Address of the user providing the deposit tokens.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of tokens to deposit.
     * @param _additionalData Additional encoded data for the deposit.
     */
    function deposit(address _user, address _token, uint256 _amount, bytes calldata _additionalData) external payable;

    /**
     * @notice Deposit to the strategy.
     * @param _user Address of the user providing the deposit tokens.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of tokens to deposit.
     * @param _additionalData Additional encoded data for the deposit.
     * @param _signature Signature to make a deposit with permit.
     */
    function depositWithPermit(
        address _user,
        address _token,
        uint256 _amount,
        bytes calldata _additionalData,
        Signature calldata _signature
    )
        external;

    /**
     * @notice Withdraw from the strategy.
     * @param _recipient Address of the recipient to receive the tokens.
     * @param _token Address of the token to withdraw.
     * @param _amountShares Amount of shares to withdraw from the user.
     * @param _additionalData Additional encoded data for the withdrawal.
     */
    function withdraw(
        address _recipient,
        address _token,
        uint256 _amountShares,
        bytes calldata _additionalData
    )
        external;

    /**
     * @notice Allows the super admin to change the admin structure contract address.
     * @param _adminStructure admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Edits deposit allowed tokens list.
     * @param _token An address of the token to allow/disallow.
     * @param _status A marker (true/false) that indicates if to allow/disallow a token.
     */
    function editDepositAllowedTokens(address _token, uint256 _status) external;

    /**
     * @notice Edits withdrawal allowed tokens list.
     * @param _token An address of the token to allow/disallow.
     * @param _status A marker (true/false) that indicates if to allow/disallow a token.
     */
    function editWithdrawalAllowedTokens(address _token, uint256 _status) external;

    /**
     * @notice Edits the deposit limits for specific tokens.
     * @param _depositLimits The array of DepositLimit struct to set.
     */
    function editDepositLimit(DepositLimit[] calldata _depositLimits) external;

    /**
     * @notice Pauses and unpauses the contract deposits.
     * @dev Sets the opposite of the current state of the pause.
     */
    function togglePause() external;

    /**
     * @notice Handles the case where tokens get stuck in the contract. Allows the admin to send the tokens to the super
     *         admin.
     * @param _token The address of the stuck token.
     */
    function inCaseTokensGetStuck(address _token) external;

    /**
     * @notice Returns a list of allowed tokens for a specified token type.
     * @param _tokenType A token type for which to return a list of tokens.
     * @return A list of allowed tokens for a specified token type.
     */
    function getListAllowedTokens(TokenType _tokenType) external view returns (address[] memory);

    /**
     * @notice Converts want tokens to vault shares.
     * @param _wantAmount An amount of want tokens to convert to vault shares.
     * @return An amount of vault shares in the specified want tokens amount.
     */
    function wantToShares(uint256 _wantAmount) external view returns (uint256);

    /**
     * @notice Returns the amount of the user deposit in terms of the token specified when possible, or in terms of want
     *         (to be processed off-chain).
     * @param _user The address of the user to get the deposit value for.
     * @param _token The address of the token to use.
     * @return The user deposit in the provided token.
     */
    function userDeposit(address _user, address _token) external view returns (uint256);

    /**
     * @notice Returns the amount of the total deposits in terms of the token specified when possible, or in terms of
     *         want (to be processed off-chain).
     * @param _token The address of the token to use.
     * @return The total deposit in the provided token.
     */
    function totalDeposits(address _token) external view returns (uint256);

    /**
     * @notice Returns the maximum number of want tokens that the user can withdraw.
     * @param _user A user address for whom to calculate the maximum number of want tokens that the user can withdraw.
     * @return The maximum number of want tokens that the user can withdraw.
     */
    function getUserMaxWant(address _user) external view returns (uint256);

    /**
     * @notice Helper function to calculate the required share to withdraw a specific amount of want tokens.
     * @dev The _wantToWithdraw must be taken from the function `estimateWithdrawal()`, the maximum amount is equivalent
     *      to `(_wantDepositAfterFee + _wantRewardsAfterFee)`.
     * @dev The flag `_withdrawAll` helps to avoid leaving remaining funds due to changes in the estimate since the user
     *      called `estimateWithdrawal()`.
     * @param _user The user to calculate the withdraw for.
     * @param _wantToWithdraw The amount of want tokens to withdraw (after compound and fees charging).
     * @param _slippageTolerance Slippage to use for the calculation.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @param _withdrawAll Indicated whether to make a full withdrawal.
     * @return _sharesToWithdraw The amount of shares to withdraw for the specified amount of want tokens.
     */
    function calculateSharesToWithdraw(
        address _user,
        uint256 _wantToWithdraw,
        uint16 _slippageTolerance,
        bytes calldata _addionalData,
        bool _withdrawAll
    )
        external
        view
        returns (uint256 _sharesToWithdraw);

    /**
     * @notice Returns the deposit limit for a token.
     * @param _token The address of the token.
     * @return _limit The deposit limit for the specified token.
     */
    function getDepositLimit(address _token) external view returns (DepositLimit memory _limit);

    /**
     * @notice Estimates the deposit details for a specific token and amount.
     * @param _token The address to deposit.
     * @param _amount The amount of tokens to deposit.
     * @param _slippageTolerance The allowed slippage percentage.
     * @param _data Extra information used to estimate.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @return _amountShares The amount of shares to receive from the vault.
     * @return _amountWant The minimum amount of LP tokens to get.
     */
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint16 _slippageTolerance,
        bytes calldata _data,
        bytes calldata _addionalData
    )
        external
        view
        returns (uint256 _amountShares, uint256 _amountWant);

    /**
     * @notice Converts vault shares to want tokens.
     * @param _sharesAmount An amount of vault shares to convert to want tokens.
     * @return An amount of want tokens in the specified vault shares amount.
     */
    function sharesToWant(uint256 _sharesAmount) external view returns (uint256);

    /**
     * @notice Shows the equivalent amount of shares converted to want tokens, considering compounding.
     * @dev Since this function uses slippage the actual result after a real compound might be slightly different.
     * @dev The result does not consider the system fees.
     * @param _sharesAmount The amount of shares.
     * @param _slippageTolerance The slippage for the compounding.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @return The amount of want tokens equivalent to the shares considering compounding.
     */
    function sharesToWantAfterCompound(
        uint256 _sharesAmount,
        uint16 _slippageTolerance,
        bytes calldata _addionalData
    )
        external
        view
        returns (uint256);

    /**
     * @notice Shows the maximum want tokens that a user could obtain considering compounding.
     * @dev Since this function uses slippage the actual result after a real compound might be slightly different.
     * @dev The result does not consider the system fees.
     * @param _user The user to be analyzed. Use strategy address to calculate for all users.
     * @param _slippageTolerance The slippage for the compounding.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @return The maximum amount of want tokens that the user has.
     */
    function getUserMaxWantWithCompound(
        address _user,
        uint16 _slippageTolerance,
        bytes calldata _addionalData
    )
        external
        view
        returns (uint256);

    /**
     * @notice Shows the maximum want tokens from the deposit and rewards that the user has, it estimates the want
     *         tokens that the user can withdraw after compounding and fees. Use strategy address to calculate for all
     *         users.
     * @dev Combine this function with the function `calculateSharesToWithdraw()`.
     * @dev Since this function uses slippage tolerance the actual result after a real compound might be slightly
     *      different.
     * @param _user The user to be analyzed.
     * @param _slippageTolerance The slippage tolerance for the compounding.
     * @param _addionalData Encoded bytes with information about the reward tokens and slippage tolerance.
     * @param _token The token to use for the withdrawal.
     * @return WithdrawalEstimation a struct including the data about the withdrawal:
     * wantDepositUsed Portion of the total want tokens that belongs to the deposit of the user.
     * wantRewardsUsed Portion of the total want tokens that belongs to the rewards of the user.
     * wantDepositAfterFee Portion of the total want tokens after fee that belongs to the deposit of the user.
     * wantRewardsAfterFee Portion of the total want tokens after fee that belongs to the rewards of the user.
     * depositInToken Deposit amount valued in token.
     * rewardsInToken Rewards amount valued in token.
     * depositInTokenAfterFee Deposit after fee amount valued in token.
     * rewardsInTokenAfterFee Rewards after fee amount valued in token.
     */
    function estimateWithdrawal(
        address _user,
        uint16 _slippageTolerance,
        bytes calldata _addionalData,
        address _token
    )
        external
        view
        returns (ICalculations.WithdrawalEstimation memory);

    /**
     * @notice Calculates the total balance of the want token that belong to the startegy. It takes into account the
     *         strategy contract balance and any underlying protocol that holds the want tokens.
     * @return The total balance of the want token.
     */
    function balance() external view returns (uint256);

    /**
     * @notice Mapping to track the amount of shares owned by each user.
     * @return An amount of shares dedicated for a user.
     */
    function userShares(address user) external view returns (uint256);

    /**
     * @notice Mapping to check if a token is allowed for deposit (1 - allowed, 2 - not allowed).
     * @return A flag that indicates if the token is allowed for deposits or not.
     */
    function depositAllowedTokens(address token) external view returns (uint256);

    /**
     * @notice Mapping to check if a token is allowed for withdrawal (1 - allowed, 2 - not allowed).
     * @return A flag that indicates if the token is allowed for withdrawals or not.
     */
    function withdrawalAllowedTokens(address token) external view returns (uint256);

    /**
     * @notice Returns a list of tokens allowed for deposit.
     * @return A list of tokens allowed for deposit.
     */
    function listDepositAllowedTokens(uint256 index) external view returns (address);

    /**
     * @notice Returns a list of tokens allowed for withdrawal.
     * @return A list of tokens allowed for withdrawal.
     */
    function listWithdrawalAllowedTokens(uint256 index) external view returns (address);

    /**
     * @notice Returns an address of the AdminStructure contract.
     * @return An address of the AdminStructure contract.
     */
    function adminStructure() external view returns (IAdminStructure);

    /**
     * @notice Returns an address of the Strategy contract.
     * @return An address of the Strategy contract.
     */
    function strategy() external view returns (IStrategy);

    /**
     * @notice Returns an address of the WETH token contract.
     * @return An address of the WETH token contract.
     */
    function weth() external view returns (IWETH);

    /**
     * @notice Returns total number of shares across all users.
     * @return Total number of shares across all users.
     */
    function totalShares() external view returns (uint256);

    /**
     * @notice Returns calculation contract.
     * @return An address of the calculations contract.
     */
    function calculations() external view returns (ICalculations);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IERC20 } from "./IERC20.sol";

/**
 * @title Dollet IWETH
 * @author Dollet Team
 * @notice Wrapped Ether (WETH) Interface. This interface defines the functions for interacting with the Wrapped Ether
 *         (WETH) contract.
 */
interface IWETH is IERC20 {
    /**
     * @notice Deposits ETH to mint WETH tokens. This function is payable, and the amount of ETH sent will be converted
     *         to WETH.
     */
    function deposit() external payable;

    /**
     * @notice Withdraws WETH and receives ETH.
     * @param _amount The amount of WETH to burn, represented in wei.
     */
    function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
        if (_initialized != type(uint8).max) {
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

pragma solidity 0.8.21;

import { IAdminStructure } from "./IAdminStructure.sol";
import { IStrategyHelper } from "./IStrategyHelper.sol";

/**
 * @title Dollet ICalculations
 * @author Dollet Team
 * @notice Interface for Calculations contract.
 */
interface ICalculations {
    /**
     * @param wantDeposit Portion of the total want tokens that belongs to the deposit of the user.
     * @param wantRewards Portion of the total want tokens that belongs to the rewards of the user.
     * @param wantDepositAfterFee Portion of the total want tokens after fee that belongs to the deposit of the user.
     * @param wantRewardsAfterFee Portion of the total want tokens after fee that belongs to the rewards of the user.
     * @param depositInToken Deposit amount valued in token.
     * @param rewardsInToken Rewards amount valued in token.
     * @param depositInTokenAfterFee Deposit after fee amount valued in token.
     * @param rewardsInTokenAfterFee Rewards after fee amount valued in token.
     */
    struct WithdrawalEstimation {
        uint256 wantDeposit;
        uint256 wantRewards;
        uint256 wantDepositAfterFee;
        uint256 wantRewardsAfterFee;
        uint256 depositInToken;
        uint256 rewardsInToken;
        uint256 depositInTokenAfterFee;
        uint256 rewardsInTokenAfterFee;
    }

    /**
     * @notice Logs information when a Strategy contract is set.
     * @param _strategy Strategy contract address.
     */
    event StrategySet(address _strategy);

    /**
     * @notice Logs information when a StrategyHelper contract is set.
     * @param _strategyHelper StrategyHelper contract address.
     */
    event StrategyHelperSet(address _strategyHelper);

    /**
     * @notice Allows the super admin to set the strategy values (Strategy and StrategyHelper contracts' addresses).
     * @param _strategy Address of the Strategy contract.
     */
    function setStrategyValues(address _strategy) external;

    /**
     * @notice Returns the value of 100% with 2 decimals.
     * @return The value of 100% with 2 decimals.
     */
    function ONE_HUNDRED_PERCENTS() external view returns (uint16);

    /**
     * @notice Returns AdminStructure contract address.
     * @return AdminStructure contract address.
     */
    function adminStructure() external view returns (IAdminStructure);

    /**
     * @notice Returns StrategyHelper contract address.
     * @return StrategyHelper contract address.
     */
    function strategyHelper() external view returns (IStrategyHelper);

    /**
     * @notice Returns the Strategy contract address.
     * @return Strategy contract address.
     */
    function strategy() external view returns (address payable);

    /**
     * @notice Returns the amount of the user deposit in terms of the token specified.
     * @param _user The address of the user to get the deposit value for.
     * @param _token The address of the token to use.
     * @return The estimated user deposit in the specified token.
     */
    function userDeposit(address _user, address _token) external view returns (uint256);

    /**
     * @notice Returns the amount of the total deposits in terms of the token specified.
     * @param _token The address of the token to use.
     * @return The amount of total deposit in the specified token.
     */
    function totalDeposits(address _token) external view returns (uint256);

    /**
     * @notice Returns the balance of the want token of the strategy after making a compound.
     * @param _slippageTolerance Slippage to use for the calculation.
     * @param _rewardData Encoded bytes with information about the reward tokens.
     * @return The want token balance after a compound.
     */
    function estimateWantAfterCompound(
        uint16 _slippageTolerance,
        bytes calldata _rewardData
    )
        external
        view
        returns (uint256);

    /**
     * @notice Returns the expected amount of want tokens to be obtained from a deposit.
     * @param _token The token to be used for deposit.
     * @param _amount The amount of tokens to be deposited.
     * @param _slippageTolerance The slippage tolerance for the deposit.
     * @param _data Extra information used to estimate.
     * @return The minimum want tokens expected to be obtained from the deposit.
     */
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippageTolerance,
        bytes calldata _data
    )
        external
        view
        returns (uint256);

    /**
     * @notice Estimates the price of an amount of want tokens in the specified token.
     * @param _token The address of the token.
     * @param _amount The amount of want tokens.
     * @param _slippageTolerance The allowed slippage percentage.
     * @return _amountInToken The minimum amount of tokens to get from the want amount.
     */
    function estimateWantToToken(
        address _token,
        uint256 _amount,
        uint16 _slippageTolerance
    )
        external
        view
        returns (uint256 _amountInToken);

    /**
     * @notice Calculates the withdrawable amount of a user.
     * @param _user The address of the user to get the withdrawable amount. (Use strategy address to calculate for all
     *              users).
     * @param _wantToWithdraw The amount of want to withdraw.
     * @param _maxUserWant The maximum amount of want that the user can withdraw.
     * @param _token Address of the to use for the calculation.
     * @param _slippageTolerance Slippage to use for the calculation.
     * @return _estimation WithdrawalEstimation struct including the data about the withdrawal:
     *         wantDepositUsed Portion of the total want tokens that belongs to the deposit of the user.
     *         wantRewardsUsed Portion of the total want tokens that belongs to the rewards of the user.
     *         wantDepositAfterFee Portion of the total want tokens after fee that belongs to the deposit of the user.
     *         wantRewardsAfterFee Portion of the total want tokens after fee that belongs to the rewards of the user.
     *         depositInToken Deposit amount valued in token.
     *         rewardsInToken Rewards amount valued in token.
     *         depositInTokenAfterFee Deposit after fee amount valued in token.
     *         rewardsInTokenAfterFee Rewards after fee amount valued in token.
     */
    function getWithdrawableAmount(
        address _user,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        address _token,
        uint16 _slippageTolerance
    )
        external
        view
        returns (WithdrawalEstimation memory _estimation);

    /**
     * @notice Calculates the used amounts from a given token amount on a withdrawal.
     * @param _user User to read the information from. (Use strategy address to calculate for all users).
     * @param _wantToWithdraw Amount from the total want tokens of the user wants to withdraw.
     * @param _maxUserWant The maximum user want to withdraw.
     * @param _withdrawalTokenOut The expected amount of tokens for the want tokens withdrawn.
     * @return _depositUsed Distibution of the token out amount that belongs to the deposit.
     * @return _rewardsUsed Distibution of the token out amount that belongs to the rewards.
     * @return _wantDepositUsed Portion the total want tokens that belongs to the deposit of the user.
     * @return _wantRewardsUsed Portion the total want tokens that belongs to the rewards of the user.
     */
    function calculateUsedAmounts(
        address _user,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        uint256 _withdrawalTokenOut
    )
        external
        view
        returns (uint256 _depositUsed, uint256 _rewardsUsed, uint256 _wantDepositUsed, uint256 _wantRewardsUsed);

    /**
     * @notice Calculates the withdrawable distribution of a user.
     * @param _user A user to read the proportional distribution. (Use strategy address to calculate for all users).
     * @param _wantToWithdraw Amount from the total want tokens of the user wants to withdraw.
     * @param _maxUserWant The maximum user want to withdraw.
     * @return _wantDepositUsed Portion the total want tokens that belongs to the deposit of the user.
     * @return _wantRewardsUsed Portion the total want tokens that belongs to the rewards of the user.
     */
    function calculateWithdrawalDistribution(
        address _user,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant
    )
        external
        view
        returns (uint256 _wantDepositUsed, uint256 _wantRewardsUsed);

    /**
     * @notice Calculates the minimum output amount applying a slippage tolerance percentage to the amount.
     * @param _amount The amount of tokens to use.
     * @param _minusPercentage The percentage to reduce from the amount.
     * @return _result The minimum output amount.
     */
    function getMinimumOutputAmount(
        uint256 _amount,
        uint256 _minusPercentage
    )
        external
        pure
        returns (uint256 _result);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title Dollet IERC20
 * @author Dollet Team
 * @notice Default IERC20 interface with additional view methods.
 */
interface IERC20 is IERC20Upgradeable {
    /**
     * @notice Returns the number of decimals used by the token.
     * @return The number of decimals used by the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the name of the token.
     * @return A string representing the token name.
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the token.
     * @return A string representing the token symbol.
     */
    function symbol() external view returns (string memory);
}