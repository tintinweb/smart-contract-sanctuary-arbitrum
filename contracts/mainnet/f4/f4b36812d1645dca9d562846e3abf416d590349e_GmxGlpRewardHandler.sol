// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
    }

    constructor() {
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = block.chainid);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        return block.chainid == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, _domainSeparator(), dataHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TOTALSUPPLY = 0x18160ddd; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a gas-optimized totalSupply to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @return totalSupply The token totalSupply.
    function safeTotalSupply(IERC20 token) internal view returns (uint256 totalSupply) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_TOTALSUPPLY));
        require(success && data.length >= 32, "BoringERC20: totalSupply failed");
        totalSupply = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxGlpManager {
    function usdg() external view returns (address);

    function cooldownDuration() external returns (uint256);

    function getAumInUsdg(bool maximise) external view returns (uint256);

    function getAum(bool maximise) external view returns (uint256);

    function lastAddedAt(address _account) external returns (uint256);

    function addLiquidity(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function removeLiquidity(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";

interface IGmxGlpRewardHandler {
    function harvest() external;

    function swapRewards(
        uint256 amountOutMin,
        IERC20 rewardToken,
        IERC20 outputToken,
        address recipient,
        bytes calldata data
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGmxRewardRouterV2 {
    event StakeGlp(address account, uint256 amount);
    event StakeGmx(address account, address token, uint256 amount);
    event UnstakeGlp(address account, uint256 amount);
    event UnstakeGmx(address account, address token, uint256 amount);

    function acceptTransfer(address _sender) external;

    function batchCompoundForAccounts(address[] memory _accounts) external;

    function batchStakeGmxForAccount(address[] memory _accounts, uint256[] memory _amounts) external;

    function bnGmx() external view returns (address);

    function bonusGmxTracker() external view returns (address);

    function claim() external;

    function claimEsGmx() external;

    function claimFees() external;

    function compound() external;

    function compoundForAccount(address _account) external;

    function esGmx() external view returns (address);

    function feeGlpTracker() external view returns (address);

    function feeGmxTracker() external view returns (address);

    function glp() external view returns (address);

    function glpManager() external view returns (address);

    function glpVester() external view returns (address);

    function gmx() external view returns (address);

    function gmxVester() external view returns (address);

    function gov() external view returns (address);

    function handleRewards(
        bool shouldClaimGmx,
        bool shouldStakeGmx,
        bool shouldClaimEsGmx,
        bool shouldStakeEsGmx,
        bool shouldStakeMultiplierPoints,
        bool shouldClaimWeth,
        bool shouldConvertWethToEth
    ) external;

    function initialize(
        address _weth,
        address _gmx,
        address _esGmx,
        address _bnGmx,
        address _glp,
        address _stakedGmxTracker,
        address _bonusGmxTracker,
        address _feeGmxTracker,
        address _feeGlpTracker,
        address _stakedGlpTracker,
        address _glpManager,
        address _gmxVester,
        address _glpVester
    ) external;

    function isInitialized() external view returns (bool);

    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);

    function pendingReceivers(address) external view returns (address);

    function setGov(address _gov) external;

    function signalTransfer(address _receiver) external;

    function stakeEsGmx(uint256 _amount) external;

    function stakeGmx(uint256 _amount) external;

    function stakeGmxForAccount(address _account, uint256 _amount) external;

    function stakedGlpTracker() external view returns (address);

    function stakedGmxTracker() external view returns (address);

    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function unstakeAndRedeemGlpETH(
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function unstakeEsGmx(uint256 _amount) external;

    function unstakeGmx(uint256 _amount) external;

    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGmxStakedGlp {
    function allowance(address _owner, address _spender) external view returns (uint256);

    function allowances(address, address) external view returns (uint256);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function balanceOf(address _account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function feeGlpTracker() external view returns (address);

    function glp() external view returns (address);

    function glpManager() external view returns (address);

    function name() external view returns (string memory);

    function stakedGlpTracker() external view returns (address);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address _recipient, uint256 _amount) external returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGmxVester {
    function rewardTracker() external view returns (address);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function setHasMaxVestableAmount(bool _hasMaxVestableAmount) external;

    function cumulativeClaimAmounts(address _account) external view returns (uint256);

    function claimedAmounts(address _account) external view returns (uint256);

    function pairAmounts(address _account) external view returns (uint256);

    function getVestedAmount(address _account) external view returns (uint256);

    function transferredAverageStakedAmounts(address _account) external view returns (uint256);

    function transferredCumulativeRewards(address _account) external view returns (uint256);

    function cumulativeRewardDeductions(address _account) external view returns (uint256);

    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;

    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;

    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;

    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;

    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(address _account) external view returns (uint256);

    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);

    function deposit(uint256 _amount) external;

    function withdraw() external;

    function claim() external returns (uint256);

    function getTotalVested(address _account) external view returns (uint256);

    function balances(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";

interface ITokenWrapper is IERC20 {
    function underlying() external view returns (IERC20);

    function unwrap(uint256 amount) external;

    function unwrapAll() external;

    function unwrapAllTo(address recipient) external;

    function unwrapTo(uint256 amount, address recipient) external;

    function wrap(uint256 amount) external;

    function wrapFor(uint256 amount, address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/libraries/BoringERC20.sol";
import "BoringSolidity/BoringOwnable.sol";
import {GmxGlpWrapperData} from "tokens/GmxGlpWrapper.sol";
import "interfaces/IGmxGlpManager.sol";
import "interfaces/IGmxRewardRouterV2.sol";
import "interfaces/IGmxStakedGlp.sol";
import "interfaces/IGmxVester.sol";
import "interfaces/IGmxGlpRewardHandler.sol";

/// @dev in case of V2, if adding new variable create GmxGlpRewardHandlerDataV2 that inherits
/// from GmxGlpRewardHandlerDataV1
contract GmxGlpRewardHandlerDataV1 is GmxGlpWrapperData {
    /// @dev V1 variables, do not change.
    IGmxRewardRouterV2 public rewardRouter;
    address public feeCollector;
    uint8 public feePercent;
    address public swapper;
    mapping(IERC20 => bool) public rewardTokenEnabled;
    mapping(IERC20 => bool) public swappingTokenOutEnabled;
    mapping(address => bool) public allowedSwappingRecipient;

    /// @dev always leave constructor empty since this won't change GmxGlpWrapper storage anyway.
    constructor() GmxGlpWrapperData(address(0)) {}
}

/// @dev When making a new version, never change existing variables, always add after
/// the existing one. Ex: Inherit from GmxGlpRewardHandlerDataV2 in case of a V2 version.
contract GmxGlpRewardHandler is GmxGlpRewardHandlerDataV1, IGmxGlpRewardHandler {
    using BoringERC20 for IERC20;

    error ErrInvalidFeePercent();
    error ErrUnsupportedRewardToken(IERC20 token);
    error ErrUnsupportedOutputToken(IERC20 token);

    error ErrSwapFailed();
    error ErrInsufficientAmountOut();
    error ErrRecipientNotAllowed(address recipient);

    event LogFeeParametersChanged(address indexed feeCollector, uint256 feeAmount);
    event LogRewardRouterChanged(IGmxRewardRouterV2 indexed previous, IGmxRewardRouterV2 indexed current);
    event LogFeeChanged(uint256 previousFee, uint256 newFee, address previousFeeCollector, address newFeeCollector);
    event LogSwapperChanged(address indexed oldSwapper, address indexed newSwapper);
    event LogRewardSwapped(IERC20 indexed token, uint256 total, uint256 amountOut, uint256 feeAmount);
    event LogRewardTokenUpdated(IERC20 indexed token, bool enabled);
    event LogSwappingTokenOutUpdated(IERC20 indexed token, bool enabled);
    event LogAllowedSwappingRecipientUpdated(address indexed previous, bool enabled);

    ////////////////////////////////////////////////////////////////////////////////
    /// @dev Avoid adding storage variable here
    /// Should use GmxGlpRewardHandlerData instead.
    ////////////////////////////////////////////////////////////////////////////////

    function harvest() external onlyStrategyExecutor {
        rewardRouter.handleRewards({
            shouldClaimGmx: true,
            shouldStakeGmx: true,
            shouldClaimEsGmx: true,
            shouldStakeEsGmx: true,
            shouldStakeMultiplierPoints: true,
            shouldClaimWeth: true,
            shouldConvertWethToEth: false
        });
    }

    function swapRewards(
        uint256 amountOutMin,
        IERC20 rewardToken,
        IERC20 outputToken,
        address recipient,
        bytes calldata data
    ) external onlyStrategyExecutor returns (uint256 amountOut) {
        if (!rewardTokenEnabled[rewardToken]) {
            revert ErrUnsupportedRewardToken(rewardToken);
        }
        if (!swappingTokenOutEnabled[outputToken]) {
            revert ErrUnsupportedOutputToken(outputToken);
        }
        if (!allowedSwappingRecipient[recipient]) {
            revert ErrRecipientNotAllowed(recipient);
        }

        uint256 amountBefore = IERC20(outputToken).balanceOf(address(this));
        rewardToken.approve(swapper, rewardToken.balanceOf(address(this)));

        (bool success, ) = swapper.call(data);
        if (!success) {
            revert ErrSwapFailed();
        }

        uint256 total = IERC20(outputToken).balanceOf(address(this)) - amountBefore;

        if (total < amountOutMin) {
            revert ErrInsufficientAmountOut();
        }

        amountOut = total;

        uint256 feeAmount = (total * feePercent) / 100;
        if (feeAmount > 0) {
            amountOut = total - feeAmount;
            IERC20(outputToken).safeTransfer(feeCollector, feeAmount);
        }

        IERC20(outputToken).safeTransfer(recipient, amountOut);

        rewardToken.approve(swapper, 0);
        emit LogRewardSwapped(rewardToken, total, amountOut, feeAmount);
    }

    function setFeeParameters(address _feeCollector, uint8 _feePercent) external onlyOwner {
        if (feePercent > 100) {
            revert ErrInvalidFeePercent();
        }

        feeCollector = _feeCollector;
        feePercent = _feePercent;

        emit LogFeeParametersChanged(_feeCollector, _feePercent);
    }

    /// @param token The allowed reward tokens to swap
    function setRewardTokenEnabled(IERC20 token, bool enabled) external onlyOwner {
        rewardTokenEnabled[token] = enabled;
        emit LogRewardTokenUpdated(token, enabled);
    }

    /// @param token The allowed token out support when swapping rewards
    function setSwappingTokenOutEnabled(IERC20 token, bool enabled) external onlyOwner {
        swappingTokenOutEnabled[token] = enabled;
        emit LogSwappingTokenOutUpdated(token, enabled);
    }

    /// @param recipient Allowed recipient for token out when swapping
    function setAllowedSwappingRecipient(address recipient, bool enabled) external onlyOwner {
        allowedSwappingRecipient[recipient] = enabled;
        emit LogAllowedSwappingRecipientUpdated(recipient, enabled);
    }

    function setRewardRouter(IGmxRewardRouterV2 _rewardRouter) external onlyOwner {
        emit LogRewardRouterChanged(rewardRouter, _rewardRouter);
        rewardRouter = _rewardRouter;
    }

    function setSwapper(address _swapper) external onlyOwner {
        emit LogSwapperChanged(swapper, _swapper);
        swapper = _swapper;
    }

    ///////////////////////////////////////////////////////////////////////
    // esGMX Vesting Handling
    // Adapted from RageTrade contract code

    /// @notice unstakes and vest protocol esGmx to convert it to Gmx
    function unstakeGmx(uint256 amount, uint256 amountTransferToFeeCollector) external onlyOwner {
        IERC20 gmx = IERC20(rewardRouter.gmx());

        if (amount > 0) {
            rewardRouter.unstakeGmx(amount);
        }
        if (amountTransferToFeeCollector > 0) {
            uint256 gmxAmount = gmx.balanceOf(address(this));

            if (amountTransferToFeeCollector < gmxAmount) {
                gmxAmount = amountTransferToFeeCollector;
            }

            gmx.safeTransfer(feeCollector, gmxAmount);
        }
    }

    /// @notice unstakes and vest protocol esGmx to convert it to Gmx
    function unstakeEsGmxAndVest(
        uint256 amount,
        uint256 glpVesterDepositAmount,
        uint256 gmxVesterDepositAmount
    ) external onlyOwner {
        if (amount > 0) {
            rewardRouter.unstakeEsGmx(amount);
        }
        if (glpVesterDepositAmount > 0) {
            IGmxVester(rewardRouter.glpVester()).deposit(glpVesterDepositAmount);
        }
        if (gmxVesterDepositAmount > 0) {
            IGmxVester(rewardRouter.gmxVester()).deposit(gmxVesterDepositAmount);
        }
    }

    /// @notice claims vested gmx tokens (i.e. stops vesting esGmx so that the relevant glp amount is unlocked)
    /// This will withdraw and unreserve all tokens as well as pause vesting. esGMX tokens that have been converted
    /// to GMX will remain as GMX tokens.
    function withdrawFromVesting(
        bool withdrawFromGlpVester,
        bool withdrawFromGmxVester,
        bool stake
    ) external onlyOwner {
        if (withdrawFromGlpVester) {
            IGmxVester(rewardRouter.glpVester()).withdraw();
        }
        if (withdrawFromGmxVester) {
            IGmxVester(rewardRouter.gmxVester()).withdraw();
        }

        if (stake) {
            uint256 esGmxWithdrawn = IERC20(rewardRouter.esGmx()).balanceOf(address(this));
            rewardRouter.stakeEsGmx(esGmxWithdrawn);
        }
    }

    /// @notice claims vested gmx tokens and optionnaly stake or transfer to feeRecipient
    /// @dev vested esGmx gets converted to GMX every second, so whatever amount is vested gets claimed
    function claimVestedGmx(
        bool withdrawFromGlpVester,
        bool withdrawFromGmxVester,
        bool stake,
        bool transferToFeeCollecter
    ) external onlyOwner {
        IERC20 gmx = IERC20(rewardRouter.gmx());

        if (withdrawFromGlpVester) {
            IGmxVester(rewardRouter.glpVester()).claim();
        }
        if (withdrawFromGmxVester) {
            IGmxVester(rewardRouter.gmxVester()).claim();
        }

        uint256 gmxAmount = gmx.balanceOf(address(this));

        if (stake) {
            gmx.approve(address(rewardRouter.stakedGmxTracker()), gmxAmount);
            rewardRouter.stakeGmx(gmxAmount);
        } else if (transferToFeeCollecter) {
            gmx.safeTransfer(feeCollector, gmxAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/Domain.sol";

abstract contract ERC20WithPreApprove is IERC20, Domain {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public _allowance;

    address internal immutable preApprovedContract;

    uint256 public totalSupply;

    constructor(address _preApprovedContract) {
        preApprovedContract = _preApprovedContract;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        if (spender == preApprovedContract) {
            return type(uint256).max;
        }

        return _allowance[owner][spender];
    }

    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param amount of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 amount) public returns (bool) {
        // If `amount` is 0, or `msg.sender` is `to` nothing happens
        if (amount != 0 || msg.sender == to) {
            uint256 srcBalance = balanceOf[msg.sender];
            require(srcBalance >= amount, "ERC20: balance too low");
            if (msg.sender != to) {
                require(to != address(0), "ERC20: no zero address"); // Moved down so low balance calls safe some gas

                balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param amount The token amount to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // If `amount` is 0, or `from` is `to` nothing happens
        if (amount != 0) {
            uint256 srcBalance = balanceOf[from];
            require(srcBalance >= amount, "ERC20: balance too low");

            if (from != to) {
                if (msg.sender != preApprovedContract) {
                    uint256 spenderAllowance = _allowance[from][msg.sender];
                    // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
                    if (spenderAllowance != type(uint256).max) {
                        require(spenderAllowance >= amount, "ERC20: allowance too low");
                        _allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
                    }
                }

                require(to != address(0), "ERC20: no zero address"); // Moved down so other failed calls safe some gas
                balanceOf[from] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public returns (bool) {
        if (spender == preApprovedContract) {
            return true;
        }

        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        if (spender == preApprovedContract) {
            return;
        }

        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(
                _getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))),
                v,
                r,
                s
            ) == owner_,
            "ERC20: Invalid Signature"
        );
        _allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }

    function _mint(address user, uint256 amount) internal {
        uint256 newTotalSupply = totalSupply + amount;
        require(newTotalSupply >= totalSupply, "Mint overflow");
        totalSupply = newTotalSupply;
        balanceOf[user] += amount;
        emit Transfer(address(0), user, amount);
    }

    function _burn(address user, uint256 amount) internal {
        require(balanceOf[user] >= amount, "Burn too much");
        totalSupply -= amount;
        balanceOf[user] -= amount;
        emit Transfer(user, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/libraries/BoringERC20.sol";
import "BoringSolidity/BoringOwnable.sol";
import "tokens/ERC20WithPreApprove.sol";
import "interfaces/ITokenWrapper.sol";

contract GmxGlpWrapperData is BoringOwnable, ERC20WithPreApprove {
    error ErrNotStrategyExecutor(address);

    IERC20 public sGlp;
    string public name;
    string public symbol;
    address public rewardHandler;
    mapping(address => bool) public strategyExecutors;

    modifier onlyStrategyExecutor() {
        if (msg.sender != owner && !strategyExecutors[msg.sender]) {
            revert ErrNotStrategyExecutor(msg.sender);
        }
        _;
    }

    constructor(address _preApprovedContract) ERC20WithPreApprove(_preApprovedContract) {}
}

contract GmxGlpWrapper is GmxGlpWrapperData, ITokenWrapper {
    using BoringERC20 for IERC20;

    event LogRewardHandlerChanged(address indexed previous, address indexed current);
    event LogStrategyExecutorChanged(address indexed executor, bool allowed);
    event LogStakedGlpChanged(IERC20 indexed previous, IERC20 indexed current);

    constructor(
        IERC20 _sGlp,
        string memory _name,
        string memory _symbol,
        address _preApprovedContract
    ) GmxGlpWrapperData(_preApprovedContract) {
        name = _name;
        symbol = _symbol;
        sGlp = _sGlp;
    }

    function underlying() external view override returns (IERC20) {
        return sGlp;
    }

    function decimals() external view returns (uint8) {
        return sGlp.safeDecimals();
    }

    function _wrap(uint256 amount, address recipient) internal {
        _mint(recipient, amount);
        sGlp.safeTransferFrom(msg.sender, address(this), amount);
    }

    function _unwrap(uint256 amount, address recipient) internal {
        _burn(msg.sender, amount);
        sGlp.safeTransfer(recipient, amount);
    }

    function wrap(uint256 amount) external override {
        _wrap(amount, msg.sender);
    }

    function wrapFor(uint256 amount, address recipient) external override {
        _wrap(amount, recipient);
    }

    function unwrap(uint256 amount) external override {
        _unwrap(amount, msg.sender);
    }

    function unwrapTo(uint256 amount, address recipient) external override {
        _unwrap(amount, recipient);
    }

    function unwrapAll() external override {
        _unwrap(balanceOf[msg.sender], msg.sender);
    }

    function unwrapAllTo(address recipient) external override {
        _unwrap(balanceOf[msg.sender], recipient);
    }

    function setStrategyExecutor(address executor, bool value) external onlyOwner {
        strategyExecutors[executor] = value;
        emit LogStrategyExecutorChanged(executor, value);
    }

    function setRewardHandler(address _rewardHandler) external onlyOwner {
        emit LogRewardHandlerChanged(rewardHandler, _rewardHandler);
        rewardHandler = _rewardHandler;
    }

    function setStakedGlp(IERC20 _sGlp) external onlyOwner {
        emit LogStakedGlpChanged(sGlp, _sGlp);
        sGlp = _sGlp;
    }

    // Forward unknown function calls to the reward handler.
    fallback() external {
        _delegate(rewardHandler);
    }

    /**
     * From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol
     *
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) private {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}