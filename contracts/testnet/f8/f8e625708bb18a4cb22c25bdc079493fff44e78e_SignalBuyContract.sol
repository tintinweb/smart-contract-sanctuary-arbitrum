// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { ISignalBuyContract } from "./interfaces/ISignalBuyContract.sol";
import { IWETH } from "./interfaces/IWETH.sol";
import { Asset } from "./utils/Asset.sol";
import { BaseLibEIP712 } from "./utils/BaseLibEIP712.sol";
import { LibConstant } from "./utils/LibConstant.sol";
import { LibSignalBuyContractOrderStorage } from "./utils/LibSignalBuyContractOrderStorage.sol";
import { Ownable } from "./utils/Ownable.sol";
import { Order, getOrderStructHash, Fill, getFillStructHash, AllowFill, getAllowFillStructHash } from "./utils/SignalBuyContractLibEIP712.sol";
import { SignatureValidator } from "./utils/SignatureValidator.sol";

/// @title SignalBuy Contract
/// @notice Order can be filled as long as the provided dealerToken/userToken ratio is better than or equal to user's specfied dealerToken/userToken ratio.
/// @author imToken Labs
contract SignalBuyContract is ISignalBuyContract, BaseLibEIP712, SignatureValidator, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Asset for address;

    IWETH public immutable weth;
    uint256 public immutable factorActivateDelay;

    // Below are the variables which consume storage slots.
    address public coordinator;
    address public feeCollector;

    // Factors
    uint256 public factorsTimeLock;
    uint16 public tokenlonFeeFactor = 0;
    uint16 public pendingTokenlonFeeFactor;

    mapping(bytes32 => uint256) public filledAmount;

    /// @notice Emitted when allowing another account to spend assets
    /// @param spender The address that is allowed to transfer tokens
    event AllowTransfer(address indexed spender, address token);

    /// @notice Emitted when disallowing an account to spend assets
    /// @param spender The address that is removed from allow list
    event DisallowTransfer(address indexed spender, address token);

    /// @notice Emitted when ETH converted to WETH
    /// @param amount The amount of converted ETH
    event DepositETH(uint256 amount);

    constructor(
        address _owner,
        address _weth,
        address _coordinator,
        uint256 _factorActivateDelay,
        address _feeCollector
    ) Ownable(_owner) {
        weth = IWETH(_weth);
        coordinator = _coordinator;
        factorActivateDelay = _factorActivateDelay;
        feeCollector = _feeCollector;
    }

    receive() external payable {}

    /// @notice Set allowance of tokens to an address
    /// @notice Only owner can call
    /// @param _tokenList The list of tokens
    /// @param _spender The address that will be allowed
    function setAllowance(address[] calldata _tokenList, address _spender) external onlyOwner {
        for (uint256 i = 0; i < _tokenList.length; ++i) {
            IERC20(_tokenList[i]).safeApprove(_spender, LibConstant.MAX_UINT);

            emit AllowTransfer(_spender, _tokenList[i]);
        }
    }

    /// @notice Clear allowance of tokens to an address
    /// @notice Only owner can call
    /// @param _tokenList The list of tokens
    /// @param _spender The address that will be cleared
    function closeAllowance(address[] calldata _tokenList, address _spender) external onlyOwner {
        for (uint256 i = 0; i < _tokenList.length; ++i) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);

            emit DisallowTransfer(_spender, _tokenList[i]);
        }
    }

    /// @notice Convert ETH in this contract to WETH
    /// @notice Only owner can call
    function depositETH() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            weth.deposit{ value: balance }();

            emit DepositETH(balance);
        }
    }

    /// @notice Only owner can call
    /// @param _newCoordinator The new address of coordinator
    function upgradeCoordinator(address _newCoordinator) external onlyOwner {
        require(_newCoordinator != address(0), "SignalBuyContract: coordinator can not be zero address");
        coordinator = _newCoordinator;

        emit UpgradeCoordinator(_newCoordinator);
    }

    /// @notice Only owner can call
    /// @param _tokenlonFeeFactor The new fee factor for user
    function setFactors(uint16 _tokenlonFeeFactor) external onlyOwner {
        require(_tokenlonFeeFactor <= LibConstant.BPS_MAX, "SignalBuyContract: Invalid user fee factor");

        pendingTokenlonFeeFactor = _tokenlonFeeFactor;

        factorsTimeLock = block.timestamp + factorActivateDelay;
    }

    /// @notice Only owner can call
    function activateFactors() external onlyOwner {
        require(factorsTimeLock != 0, "SignalBuyContract: no pending fee factors");
        require(block.timestamp >= factorsTimeLock, "SignalBuyContract: fee factors timelocked");
        factorsTimeLock = 0;
        tokenlonFeeFactor = pendingTokenlonFeeFactor;
        pendingTokenlonFeeFactor = 0;

        emit FactorsUpdated(tokenlonFeeFactor);
    }

    /// @notice Only owner can call
    /// @param _newFeeCollector The new address of fee collector
    function setFeeCollector(address _newFeeCollector) external onlyOwner {
        require(_newFeeCollector != address(0), "SignalBuyContract: fee collector can not be zero address");
        feeCollector = _newFeeCollector;

        emit SetFeeCollector(_newFeeCollector);
    }

    /// @inheritdoc ISignalBuyContract
    function fillSignalBuy(
        Order calldata _order,
        bytes calldata _orderUserSig,
        TraderParams calldata _params,
        CoordinatorParams calldata _crdParams
    ) external payable override nonReentrant returns (uint256, uint256) {
        bytes32 orderHash = getEIP712Hash(getOrderStructHash(_order));

        _validateOrder(_order, orderHash, _orderUserSig);
        bytes32 allowFillHash = _validateFillPermission(orderHash, _params.dealerTokenAmount, _params.dealer, _crdParams);
        _validateOrderTaker(_order, _params.dealer);

        // Check gas fee factor and dealer strategy fee factor do not exceed limit
        require(
            (_params.gasFeeFactor <= LibConstant.BPS_MAX) &&
                (_params.dealerStrategyFeeFactor <= LibConstant.BPS_MAX) &&
                (_params.gasFeeFactor + _params.dealerStrategyFeeFactor <= LibConstant.BPS_MAX - tokenlonFeeFactor),
            "SignalBuyContract: Invalid dealer fee factor"
        );

        {
            Fill memory fill = Fill({
                orderHash: orderHash,
                dealer: _params.dealer,
                recipient: _params.recipient,
                userTokenAmount: _params.userTokenAmount,
                dealerTokenAmount: _params.dealerTokenAmount,
                dealerSalt: _params.salt,
                expiry: _params.expiry
            });
            _validateTraderFill(fill, _params.dealerSig);
        }

        (uint256 userTokenAmount, uint256 remainingUserTokenAmount) = _quoteOrderFromUserToken(_order, orderHash, _params.userTokenAmount);
        // Calculate dealerTokenAmount according to the provided dealerToken/userToken ratio
        uint256 dealerTokenAmount = userTokenAmount.mul(_params.dealerTokenAmount).div(_params.userTokenAmount);
        // Calculate minimum dealerTokenAmount according to the offer's dealerToken/userToken ratio
        uint256 minDealerTokenAmount = userTokenAmount.mul(_order.minDealerTokenAmount).div(_order.userTokenAmount);

        _settleForTrader(
            TraderSettlement({
                orderHash: orderHash,
                allowFillHash: allowFillHash,
                trader: _params.dealer,
                recipient: _params.recipient,
                user: _order.user,
                userToken: _order.userToken,
                dealerToken: _order.dealerToken,
                userTokenAmount: userTokenAmount,
                dealerTokenAmount: dealerTokenAmount,
                minDealerTokenAmount: minDealerTokenAmount,
                remainingUserTokenAmount: remainingUserTokenAmount,
                gasFeeFactor: _params.gasFeeFactor,
                dealerStrategyFeeFactor: _params.dealerStrategyFeeFactor
            })
        );

        _recordUserTokenFilled(orderHash, userTokenAmount);

        return (dealerTokenAmount, userTokenAmount);
    }

    function _validateTraderFill(Fill memory _fill, bytes memory _fillTakerSig) internal {
        require(_fill.expiry > uint64(block.timestamp), "SignalBuyContract: Fill request is expired");
        require(_fill.recipient != address(0), "SignalBuyContract: recipient can not be zero address");

        bytes32 fillHash = getEIP712Hash(getFillStructHash(_fill));
        require(!LibSignalBuyContractOrderStorage.getStorage().fillSeen[fillHash], "SignalBuyContract: Fill seen before");
        require(isValidSignature(_fill.dealer, fillHash, bytes(""), _fillTakerSig), "SignalBuyContract: Fill is not signed by dealer");

        // Set fill seen to avoid replay attack.
        LibSignalBuyContractOrderStorage.getStorage().fillSeen[fillHash] = true;
    }

    function _validateFillPermission(
        bytes32 _orderHash,
        uint256 _fillAmount,
        address _executor,
        CoordinatorParams memory _crdParams
    ) internal returns (bytes32) {
        require(_crdParams.expiry > uint64(block.timestamp), "SignalBuyContract: Fill permission is expired");

        bytes32 allowFillHash = getEIP712Hash(
            getAllowFillStructHash(
                AllowFill({ orderHash: _orderHash, executor: _executor, fillAmount: _fillAmount, salt: _crdParams.salt, expiry: _crdParams.expiry })
            )
        );
        require(!LibSignalBuyContractOrderStorage.getStorage().allowFillSeen[allowFillHash], "SignalBuyContract: AllowFill seen before");
        require(isValidSignature(coordinator, allowFillHash, bytes(""), _crdParams.sig), "SignalBuyContract: AllowFill is not signed by coordinator");

        // Set allow fill seen to avoid replay attack
        LibSignalBuyContractOrderStorage.getStorage().allowFillSeen[allowFillHash] = true;

        return allowFillHash;
    }

    struct TraderSettlement {
        bytes32 orderHash;
        bytes32 allowFillHash;
        address trader;
        address recipient;
        address user;
        IERC20 userToken;
        IERC20 dealerToken;
        uint256 userTokenAmount;
        uint256 dealerTokenAmount;
        uint256 minDealerTokenAmount;
        uint256 remainingUserTokenAmount;
        uint16 gasFeeFactor;
        uint16 dealerStrategyFeeFactor;
    }

    function _settleForTrader(TraderSettlement memory _settlement) internal {
        // memory cache
        address _feeCollector = feeCollector;

        // Calculate user fee (user receives dealer token so fee is charged in dealer token)
        // 1. Fee for Tokenlon
        uint256 tokenlonFee = _mulFactor(_settlement.dealerTokenAmount, tokenlonFeeFactor);
        // 2. Fee for SignalBuy, including gas fee and strategy fee
        uint256 dealerFee = _mulFactor(_settlement.dealerTokenAmount, _settlement.gasFeeFactor + _settlement.dealerStrategyFeeFactor);
        uint256 dealerTokenForUserAndTokenlon = _settlement.dealerTokenAmount.sub(dealerFee);
        uint256 dealerTokenForUser = dealerTokenForUserAndTokenlon.sub(tokenlonFee);
        require(dealerTokenForUser >= _settlement.minDealerTokenAmount, "SignalBuyContract: dealer token amount not enough");

        // trader -> user
        address _weth = address(weth); // cache
        if (address(_settlement.dealerToken).isETH()) {
            if (msg.value > 0) {
                // User wants ETH and dealer pays in ETH
                require(msg.value == dealerTokenForUserAndTokenlon, "SignalBuyContract: mismatch dealer token (ETH) amount");
            } else {
                // User wants ETH but dealer pays in WETH
                IERC20(_weth).safeTransferFrom(_settlement.trader, address(this), dealerTokenForUserAndTokenlon);
                weth.withdraw(dealerTokenForUserAndTokenlon);
            }
            // Send ETH to user
            LibConstant.ETH_ADDRESS.transferTo(payable(_settlement.user), dealerTokenForUser);
        } else if (address(_settlement.dealerToken) == _weth) {
            if (msg.value > 0) {
                // User wants WETH but dealer pays in ETH
                require(msg.value == dealerTokenForUserAndTokenlon, "SignalBuyContract: mismatch dealer token (ETH) amount");
                weth.deposit{ value: dealerTokenForUserAndTokenlon }();
                weth.transfer(_settlement.user, dealerTokenForUser);
            } else {
                // User wants WETH and dealer pays in WETH
                IERC20(_weth).safeTransferFrom(_settlement.trader, _settlement.user, dealerTokenForUser);
            }
        } else {
            _settlement.dealerToken.safeTransferFrom(_settlement.trader, _settlement.user, dealerTokenForUser);
        }

        // user -> recipient
        _settlement.userToken.safeTransferFrom(_settlement.user, _settlement.recipient, _settlement.userTokenAmount);

        // Collect user fee (charged in dealer token)
        if (tokenlonFee > 0) {
            if (address(_settlement.dealerToken).isETH()) {
                LibConstant.ETH_ADDRESS.transferTo(payable(_feeCollector), tokenlonFee);
            } else if (address(_settlement.dealerToken) == _weth) {
                if (msg.value > 0) {
                    weth.transfer(_feeCollector, tokenlonFee);
                } else {
                    weth.transferFrom(_settlement.trader, _feeCollector, tokenlonFee);
                }
            } else {
                _settlement.dealerToken.safeTransferFrom(_settlement.trader, _feeCollector, tokenlonFee);
            }
        }

        // bypass stack too deep error
        _emitSignalBuyFilledByTrader(
            SignalBuyFilledByTraderParams({
                orderHash: _settlement.orderHash,
                user: _settlement.user,
                dealer: _settlement.trader,
                allowFillHash: _settlement.allowFillHash,
                recipient: _settlement.recipient,
                userToken: address(_settlement.userToken),
                dealerToken: address(_settlement.dealerToken),
                userTokenFilledAmount: _settlement.userTokenAmount,
                dealerTokenFilledAmount: _settlement.dealerTokenAmount,
                remainingUserTokenAmount: _settlement.remainingUserTokenAmount,
                tokenlonFee: tokenlonFee,
                dealerFee: dealerFee
            })
        );
    }

    /// @inheritdoc ISignalBuyContract
    function cancelSignalBuy(Order calldata _order, bytes calldata _cancelOrderUserSig) external override nonReentrant {
        require(_order.expiry > uint64(block.timestamp), "SignalBuyContract: Order is expired");
        bytes32 orderHash = getEIP712Hash(getOrderStructHash(_order));
        bool isCancelled = LibSignalBuyContractOrderStorage.getStorage().orderHashToCancelled[orderHash];
        require(!isCancelled, "SignalBuyContract: Order is cancelled already");
        {
            Order memory cancelledOrder = _order;
            cancelledOrder.minDealerTokenAmount = 0;

            bytes32 cancelledOrderHash = getEIP712Hash(getOrderStructHash(cancelledOrder));
            require(
                isValidSignature(_order.user, cancelledOrderHash, bytes(""), _cancelOrderUserSig),
                "SignalBuyContract: Cancel request is not signed by user"
            );
        }

        // Set cancelled state to storage
        LibSignalBuyContractOrderStorage.getStorage().orderHashToCancelled[orderHash] = true;
        emit OrderCancelled(orderHash, _order.user);
    }

    /* order utils */

    function _validateOrder(
        Order memory _order,
        bytes32 _orderHash,
        bytes memory _orderUserSig
    ) internal view {
        require(_order.expiry > uint64(block.timestamp), "SignalBuyContract: Order is expired");
        bool isCancelled = LibSignalBuyContractOrderStorage.getStorage().orderHashToCancelled[_orderHash];
        require(!isCancelled, "SignalBuyContract: Order is cancelled");

        require(isValidSignature(_order.user, _orderHash, bytes(""), _orderUserSig), "SignalBuyContract: Order is not signed by user");
    }

    function _validateOrderTaker(Order memory _order, address _dealer) internal pure {
        if (_order.dealer != address(0)) {
            require(_order.dealer == _dealer, "SignalBuyContract: Order cannot be filled by this dealer");
        }
    }

    function _quoteOrderFromUserToken(
        Order memory _order,
        bytes32 _orderHash,
        uint256 _userTokenAmount
    ) internal view returns (uint256, uint256) {
        uint256 userTokenFilledAmount = LibSignalBuyContractOrderStorage.getStorage().orderHashToUserTokenFilledAmount[_orderHash];

        require(userTokenFilledAmount < _order.userTokenAmount, "SignalBuyContract: Order is filled");

        uint256 userTokenFillableAmount = _order.userTokenAmount.sub(userTokenFilledAmount);
        uint256 userTokenQuota = Math.min(_userTokenAmount, userTokenFillableAmount);
        uint256 remainingAfterFill = userTokenFillableAmount.sub(userTokenQuota);

        require(userTokenQuota != 0, "SignalBuyContract: zero token amount");
        return (userTokenQuota, remainingAfterFill);
    }

    function _recordUserTokenFilled(bytes32 _orderHash, uint256 _userTokenAmount) internal {
        LibSignalBuyContractOrderStorage.Storage storage stor = LibSignalBuyContractOrderStorage.getStorage();
        uint256 userTokenFilledAmount = stor.orderHashToUserTokenFilledAmount[_orderHash];
        stor.orderHashToUserTokenFilledAmount[_orderHash] = userTokenFilledAmount.add(_userTokenAmount);
    }

    /* math utils */

    function _mulFactor(uint256 amount, uint256 factor) internal pure returns (uint256) {
        return amount.mul(factor).div(LibConstant.BPS_MAX);
    }

    /* event utils */

    struct SignalBuyFilledByTraderParams {
        bytes32 orderHash;
        address user;
        address dealer;
        bytes32 allowFillHash;
        address recipient;
        address userToken;
        address dealerToken;
        uint256 userTokenFilledAmount;
        uint256 dealerTokenFilledAmount;
        uint256 remainingUserTokenAmount;
        uint256 tokenlonFee;
        uint256 dealerFee;
    }

    function _emitSignalBuyFilledByTrader(SignalBuyFilledByTraderParams memory _params) internal {
        emit SignalBuyFilledByTrader(
            _params.orderHash,
            _params.user,
            _params.dealer,
            _params.allowFillHash,
            _params.recipient,
            FillReceipt({
                userToken: _params.userToken,
                dealerToken: _params.dealerToken,
                userTokenFilledAmount: _params.userTokenFilledAmount,
                dealerTokenFilledAmount: _params.dealerTokenFilledAmount,
                remainingUserTokenAmount: _params.remainingUserTokenAmount,
                tokenlonFee: _params.tokenlonFee,
                dealerFee: _params.dealerFee
            })
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
pragma solidity >=0.7.0;
pragma abicoder v2;

import { Order } from "../utils/SignalBuyContractLibEIP712.sol";

/// @title ISignalBuyContract Interface
/// @author imToken Labs
interface ISignalBuyContract {
    /// @notice Emitted when coordinator address is updated
    /// @param newCoordinator The address of the new coordinator
    event UpgradeCoordinator(address newCoordinator);

    /// @notice Emitted when fee factors are updated
    /// @param userFeeFactor The new fee factor for user
    event FactorsUpdated(uint16 userFeeFactor);

    /// @notice Emitted when fee collector address is updated
    /// @param newFeeCollector The address of the new fee collector
    event SetFeeCollector(address newFeeCollector);

    /// @notice Emitted when an order is filled by dealer
    /// @param orderHash The EIP-712 hash of the target order
    /// @param user The address of the user
    /// @param dealer The address of the dealer
    /// @param allowFillHash The EIP-712 hash of the fill permit granted by coordinator
    /// @param recipient The address of the recipient which will receive tokens from user
    /// @param fillReceipt Contains details of this single fill
    event SignalBuyFilledByTrader(
        bytes32 indexed orderHash,
        address indexed user,
        address indexed dealer,
        bytes32 allowFillHash,
        address recipient,
        FillReceipt fillReceipt
    );

    /// @notice Emitted when order is cancelled
    /// @param orderHash The EIP-712 hash of the target order
    /// @param user The address of the user
    event OrderCancelled(bytes32 orderHash, address user);

    struct FillReceipt {
        address userToken;
        address dealerToken;
        uint256 userTokenFilledAmount;
        uint256 dealerTokenFilledAmount;
        uint256 remainingUserTokenAmount;
        uint256 tokenlonFee;
        uint256 dealerFee;
    }

    struct CoordinatorParams {
        bytes sig;
        uint256 salt;
        uint64 expiry;
    }

    struct TraderParams {
        address dealer;
        address recipient;
        uint256 userTokenAmount;
        uint256 dealerTokenAmount;
        uint16 gasFeeFactor;
        uint16 dealerStrategyFeeFactor;
        uint256 salt;
        uint64 expiry;
        bytes dealerSig;
    }

    /// @notice Fill an order by a trader
    /// @notice Only user proxy can call
    /// @param _order The order that is going to be filled
    /// @param _orderUserSig The signature of the order from user
    /// @param _params Trader specific filling parameters
    /// @param _crdParams Contains details of the fill permit
    function fillSignalBuy(
        Order calldata _order,
        bytes calldata _orderUserSig,
        TraderParams calldata _params,
        CoordinatorParams calldata _crdParams
    ) external payable returns (uint256, uint256);

    /// @notice Cancel an order
    /// @notice Only user proxy can call
    /// @param _order The order that is going to be cancelled
    /// @param _cancelUserSig The cancelling signature signed by user
    function cancelSignalBuy(Order calldata _order, bytes calldata _cancelUserSig) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { LibConstant } from "./LibConstant.sol";

library Asset {
    using SafeERC20 for IERC20;

    function isETH(address addr) internal pure returns (bool) {
        return (addr == LibConstant.ETH_ADDRESS || addr == LibConstant.ZERO_ADDRESS);
    }

    function transferTo(
        address asset,
        address payable to,
        uint256 amount
    ) internal {
        if (to == address(this)) {
            return;
        }
        if (isETH(asset)) {
            // @dev forward all available gas and may cause reentrancy
            require(address(this).balance >= amount, "insufficient balance");
            (bool success, ) = to.call{ value: amount }("");
            require(success, "unable to send ETH");
        } else {
            IERC20(asset).safeTransfer(to, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

abstract contract BaseLibEIP712 {
    // EIP-191 Header
    string public constant EIP191_HEADER = "\x19\x01";

    // EIP712Domain
    string public constant EIP712_DOMAIN_NAME = "Tokenlon";
    string public constant EIP712_DOMAIN_VERSION = "v5";

    // EIP712Domain Separator
    bytes32 public immutable originalEIP712DomainSeparator;
    uint256 public immutable originalChainId;

    constructor() {
        originalEIP712DomainSeparator = _buildDomainSeparator();
        originalChainId = getChainID();
    }

    /**
     * @dev Return `chainId`
     */
    function getChainID() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(EIP712_DOMAIN_NAME)),
                    keccak256(bytes(EIP712_DOMAIN_VERSION)),
                    getChainID(),
                    address(this)
                )
            );
    }

    function _getDomainSeparator() private view returns (bytes32) {
        if (getChainID() == originalChainId) {
            return originalEIP712DomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function getEIP712Hash(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(EIP191_HEADER, _getDomainSeparator(), structHash));
    }

    function EIP712_DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _getDomainSeparator();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library LibConstant {
    int256 internal constant MAX_INT = 2**255 - 1;
    uint256 internal constant MAX_UINT = 2**256 - 1;
    uint16 internal constant BPS_MAX = 10000;
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant ZERO_ADDRESS = address(0);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library LibSignalBuyContractOrderStorage {
    bytes32 private constant STORAGE_SLOT = 0x1360fb69f36f46eb45cf50ca3a6184b38e4ef3bde9e5aff734dccec027d7b9f7;
    /// @dev Storage bucket for this feature.
    struct Storage {
        // Has the fill been executed.
        mapping(bytes32 => bool) fillSeen;
        // Has the allowFill been executed.
        mapping(bytes32 => bool) allowFillSeen;
        // How much maker token has been filled in order.
        mapping(bytes32 => uint256) orderHashToUserTokenFilledAmount;
        // Whether order is cancelled or not.
        mapping(bytes32 => bool) orderHashToCancelled;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("signalbuycontract.order.storage")) - 1));

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := STORAGE_SLOT
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/// @title Ownable Contract
/// @author imToken Labs
abstract contract Ownable {
    address public owner;
    address public nominatedOwner;

    event OwnerNominated(address indexed newOwner);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor(address _owner) {
        require(_owner != address(0), "owner should not be 0");
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// @notice Activate new ownership
    /// @notice Only nominated owner can call
    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "not nominated");
        emit OwnerChanged(owner, nominatedOwner);

        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    /// @notice Give up the ownership
    /// @notice Only owner can call
    /// @notice Ownership cannot be recovered
    function renounceOwnership() external onlyOwner {
        require(nominatedOwner == address(0), "pending nomination exists");
        emit OwnerChanged(owner, address(0));
        owner = address(0);
    }

    /// @notice Nominate new owner
    /// @notice Only owner can call
    /// @param newOwner The address of the new owner
    function nominateNewOwner(address newOwner) external onlyOwner {
        nominatedOwner = newOwner;
        emit OwnerNominated(newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Order {
    IERC20 userToken;
    IERC20 dealerToken;
    uint256 userTokenAmount;
    uint256 minDealerTokenAmount;
    address user;
    address dealer;
    uint256 salt;
    uint64 expiry;
}

string constant ORDER_TYPESTRING = "Order(address userToken,address dealerToken,uint256 userTokenAmount,uint256 minDealerTokenAmount,address user,address dealer,uint256 salt,uint64 expiry)";

bytes32 constant ORDER_TYPEHASH = keccak256(bytes(ORDER_TYPESTRING));

// solhint-disable-next-line func-visibility
function getOrderStructHash(Order memory _order) pure returns (bytes32) {
    return
        keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                address(_order.userToken),
                address(_order.dealerToken),
                _order.userTokenAmount,
                _order.minDealerTokenAmount,
                _order.user,
                _order.dealer,
                _order.salt,
                _order.expiry
            )
        );
}

struct Fill {
    bytes32 orderHash; // EIP712 hash
    address dealer;
    address recipient;
    uint256 userTokenAmount;
    uint256 dealerTokenAmount;
    uint256 dealerSalt;
    uint64 expiry;
}

string constant FILL_TYPESTRING = "Fill(bytes32 orderHash,address dealer,address recipient,uint256 userTokenAmount,uint256 dealerTokenAmount,uint256 dealerSalt,uint64 expiry)";

bytes32 constant FILL_TYPEHASH = keccak256(bytes(FILL_TYPESTRING));

// solhint-disable-next-line func-visibility
function getFillStructHash(Fill memory _fill) pure returns (bytes32) {
    return
        keccak256(
            abi.encode(
                FILL_TYPEHASH,
                _fill.orderHash,
                _fill.dealer,
                _fill.recipient,
                _fill.userTokenAmount,
                _fill.dealerTokenAmount,
                _fill.dealerSalt,
                _fill.expiry
            )
        );
}

struct AllowFill {
    bytes32 orderHash; // EIP712 hash
    address executor;
    uint256 fillAmount;
    uint256 salt;
    uint64 expiry;
}

string constant ALLOW_FILL_TYPESTRING = "AllowFill(bytes32 orderHash,address executor,uint256 fillAmount,uint256 salt,uint64 expiry)";

bytes32 constant ALLOW_FILL_TYPEHASH = keccak256(bytes(ALLOW_FILL_TYPESTRING));

// solhint-disable-next-line func-visibility
function getAllowFillStructHash(AllowFill memory _allowFill) pure returns (bytes32) {
    return keccak256(abi.encode(ALLOW_FILL_TYPEHASH, _allowFill.orderHash, _allowFill.executor, _allowFill.fillAmount, _allowFill.salt, _allowFill.expiry));
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../interfaces/IERC1271Wallet.sol";
import "./LibBytes.sol";

interface IWallet {
    /// @dev Verifies that a signature is valid.
    /// @param hash Message hash that is signed.
    /// @param signature Proof of signing.
    /// @return isValid Validity of order signature.
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bool isValid);
}

/**
 * @dev Contains logic for signature validation.
 * Signatures from wallet contracts assume ERC-1271 support (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1271.md)
 * Notes: Methods are strongly inspired by contracts in https://github.com/0xProject/0x-monorepo/blob/development/
 */
contract SignatureValidator {
    using LibBytes for bytes;

    /***********************************|
  |             Variables             |
  |__________________________________*/

    // bytes4(keccak256("isValidSignature(bytes,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE = 0x20c13b0b;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

    // Allowed signature types.
    enum SignatureType {
        Illegal, // 0x00, default value
        Invalid, // 0x01
        EIP712, // 0x02
        EthSign, // 0x03
        WalletBytes, // 0x04  standard 1271 wallet type
        WalletBytes32, // 0x05  standard 1271 wallet type
        Wallet, // 0x06  0x wallet type for signature compatibility
        NSignatureTypes // 0x07, number of signature types. Always leave at end.
    }

    /***********************************|
  |        Signature Functions        |
  |__________________________________*/

    /**
     * @dev Verifies that a hash has been signed by the given signer.
     * @param _signerAddress  Address that should have signed the given hash.
     * @param _hash           Hash of the EIP-712 encoded data
     * @param _data           Full EIP-712 data structure that was hashed and signed
     * @param _sig            Proof that the hash has been signed by signer.
     *      For non wallet signatures, _sig is expected to be an array tightly encoded as
     *      (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType)
     * @return isValid True if the address recovered from the provided signature matches the input signer address.
     */
    function isValidSignature(
        address _signerAddress,
        bytes32 _hash,
        bytes memory _data,
        bytes memory _sig
    ) public view returns (bool isValid) {
        require(_sig.length > 0, "SignatureValidator#isValidSignature: length greater than 0 required");

        require(_signerAddress != address(0x0), "SignatureValidator#isValidSignature: invalid signer");

        // Pop last byte off of signature byte array.
        uint8 signatureTypeRaw = uint8(_sig.popLastByte());

        // Ensure signature is supported
        require(signatureTypeRaw < uint8(SignatureType.NSignatureTypes), "SignatureValidator#isValidSignature: unsupported signature");

        // Extract signature type
        SignatureType signatureType = SignatureType(signatureTypeRaw);

        // Variables are not scoped in Solidity.
        uint8 v;
        bytes32 r;
        bytes32 s;
        address recovered;

        // Always illegal signature.
        // This is always an implicit option since a signer can create a
        // signature array with invalid type or length. We may as well make
        // it an explicit option. This aids testing and analysis. It is
        // also the initialization value for the enum type.
        if (signatureType == SignatureType.Illegal) {
            revert("SignatureValidator#isValidSignature: illegal signature");

            // Signature using EIP712
        } else if (signatureType == SignatureType.EIP712) {
            require(_sig.length == 65 || _sig.length == 97, "SignatureValidator#isValidSignature: length 65 or 97 required");
            r = _sig.readBytes32(0);
            s = _sig.readBytes32(32);
            v = uint8(_sig[64]);
            recovered = ecrecover(_hash, v, r, s);
            isValid = _signerAddress == recovered;
            return isValid;

            // Signed using web3.eth_sign() or Ethers wallet.signMessage()
        } else if (signatureType == SignatureType.EthSign) {
            require(_sig.length == 65 || _sig.length == 97, "SignatureValidator#isValidSignature: length 65 or 97 required");
            r = _sig.readBytes32(0);
            s = _sig.readBytes32(32);
            v = uint8(_sig[64]);
            recovered = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), v, r, s);
            isValid = _signerAddress == recovered;
            return isValid;

            // Signature verified by wallet contract with data validation.
        } else if (signatureType == SignatureType.WalletBytes) {
            isValid = ERC1271_MAGICVALUE == IERC1271Wallet(_signerAddress).isValidSignature(_data, _sig);
            return isValid;

            // Signature verified by wallet contract without data validation.
        } else if (signatureType == SignatureType.WalletBytes32) {
            isValid = ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(_signerAddress).isValidSignature(_hash, _sig);
            return isValid;
        } else if (signatureType == SignatureType.Wallet) {
            isValid = isValidWalletSignature(_hash, _signerAddress, _sig);
            return isValid;
        }

        // Anything else is illegal (We do not return false because
        // the signature may actually be valid, just not in a format
        // that we currently support. In this case returning false
        // may lead the caller to incorrectly believe that the
        // signature was invalid.)
        revert("SignatureValidator#isValidSignature: unsupported signature");
    }

    /// @dev Verifies signature using logic defined by Wallet contract.
    /// @param hash Any 32 byte hash.
    /// @param walletAddress Address that should have signed the given hash
    ///                      and defines its own signature verification method.
    /// @param signature Proof that the hash has been signed by signer.
    /// @return isValid True if signature is valid for given wallet..
    function isValidWalletSignature(
        bytes32 hash,
        address walletAddress,
        bytes memory signature
    ) internal view returns (bool isValid) {
        bytes memory _calldata = abi.encodeWithSelector(IWallet(walletAddress).isValidSignature.selector, hash, signature);
        bytes32 magic_salt = bytes32(bytes4(keccak256("isValidWalletSignature(bytes32,address,bytes)")));
        assembly {
            if iszero(extcodesize(walletAddress)) {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            let cdStart := add(_calldata, 32)
            let success := staticcall(
                gas(), // forward all gas
                walletAddress, // address of Wallet contract
                cdStart, // pointer to start of input
                mload(_calldata), // length of input
                cdStart, // write output over input
                32 // output size is 32 bytes
            )

            if iszero(eq(returndatasize(), 32)) {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            switch success
            case 0 {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }
            case 1 {
                // Signature is valid if call did not revert and returned true
                isValid := eq(
                    and(mload(cdStart), 0xffffffff00000000000000000000000000000000000000000000000000000000),
                    and(magic_salt, 0xffffffff00000000000000000000000000000000000000000000000000000000)
                )
            }
        }
        return isValid;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity >=0.7.0;

interface IERC1271Wallet {
    /**
     * @notice Verifies whether the provided signature is valid with respect to the provided data
     * @dev MUST return the correct magic value if the signature provided is valid for the provided data
     *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
     *   > This function MAY modify Ethereum's state
     * @param _data       Arbitrary length data signed on the behalf of address(this)
     * @param _signature  Signature byte array associated with _data
     * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
     *
     */
    function isValidSignature(bytes calldata _data, bytes calldata _signature) external view returns (bytes4 magicValue);

    /**
     * @notice Verifies whether the provided signature is valid with respect to the provided hash
     * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
     *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
     *   > This function MAY modify Ethereum's state
     * @param _hash       keccak256 hash that was signed
     * @param _signature  Signature byte array associated with _data
     * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
     */
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4 magicValue);
}

/*
  Copyright 2018 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  This is a truncated version of the original LibBytes.sol library from ZeroEx.
*/
// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.6;

library LibBytes {
    using LibBytes for bytes;

    /***********************************|
  |        Pop Bytes Functions        |
  |__________________________________*/

    /**
     * @dev Pops the last byte off of a byte array by modifying its length.
     * @param b Byte array that will be modified.
     * @return result The byte that was popped off.
     */
    function popLastByte(bytes memory b) internal pure returns (bytes1 result) {
        require(b.length > 0, "LibBytes#popLastByte: greater than zero length required");

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(bytes memory b, uint256 index) internal pure returns (address result) {
        require(
            b.length >= index + 20, // 20 is length of address
            "LibBytes#readAddress greater or equal to 20 length required"
        );

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /***********************************|
  |        Read Bytes Functions       |
  |__________________________________*/

    /**
     * @dev Reads a bytes32 value from a position in a byte array.
     * @param b Byte array containing a bytes32 value.
     * @param index Index in byte array of bytes32 value.
     * @return result bytes32 value from byte array.
     */
    function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
        require(b.length >= index + 32, "LibBytes#readBytes32 greater or equal to 32 length required");

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index) internal pure returns (bytes4 result) {
        require(b.length >= index + 4, "LibBytes#readBytes4 greater or equal to 4 length required");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    function readBytes2(bytes memory b, uint256 index) internal pure returns (bytes2 result) {
        require(b.length >= index + 2, "LibBytes#readBytes2 greater or equal to 2 length required");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFF000000000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}