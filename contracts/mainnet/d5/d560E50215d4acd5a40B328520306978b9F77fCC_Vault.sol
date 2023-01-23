// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IVUSDC.sol";
import "./interfaces/IPositionVault.sol";
import "./interfaces/IPriceManager.sol";
import "./interfaces/ISettingsManager.sol";
import "./interfaces/IVault.sol";
import {Constants} from "../access/Constants.sol";
import {OrderStatus, OrderType} from "./structs.sol";

contract Vault is Constants, ReentrancyGuard, Ownable, IVault {
    using SafeERC20 for IERC20;

    uint256 public totalVLP;
    uint256 public totalUSDC;
    IPositionVault private positionVault;
    IPriceManager private priceManager;
    ISettingsManager private settingsManager;
    address private immutable vlp;
    address private immutable vUSDC;
    bool private isInitialized;

    mapping(address => uint256) public lastStakedAt;

    event Deposit(address indexed account, address indexed token, uint256 amount);
    event Stake(address indexed account, address token, uint256 amount, uint256 mintAmount);
    event Unstake(address indexed account, address token, uint256 vlpAmount, uint256 amountOut);
    event Withdraw(address indexed account, address indexed token, uint256 amount);
    event TakeVUSDIn(address indexed account, address indexed refer, uint256 amount, uint256 fee);
    event TakeVUSDOut(address indexed account, address indexed refer, uint256 amount, uint256 fee);
    event TransferBounty(address indexed account, uint256 amount);

    modifier onlyVault() {
        require(msg.sender == address(positionVault), "Only vault has access");
        _;
    }

    constructor(address _vlp, address _vUSDC) {
        vlp = _vlp;
        vUSDC = _vUSDC;
    }

    function accountDeltaAndFeeIntoTotalUSDC(
        bool _hasProfit,
        uint256 _adjustDelta,
        uint256 _fee
    ) external override onlyVault {
        _accountDeltaAndFeeIntoTotalUSDC(_hasProfit, _adjustDelta, _fee);
    }

    function addOrRemoveCollateral(
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool isPlus,
        uint256 _amount
    ) external nonReentrant {
        positionVault.addOrRemoveCollateral(msg.sender, _indexToken, _isLong, _posId, isPlus, _amount);
    }

    function addPosition(
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) external payable nonReentrant {
        require(msg.value == settingsManager.triggerGasFee(), "invalid triggerGasFee");
        payable(settingsManager.positionManager()).transfer(msg.value);
        positionVault.addPosition(msg.sender, _indexToken, _isLong, _posId, _collateralDelta, _sizeDelta);
    }

    function addTrailingStop(
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params
    ) external payable nonReentrant {
        require(msg.value == settingsManager.triggerGasFee(), "invalid triggerGasFee");
        payable(settingsManager.positionManager()).transfer(msg.value);
        positionVault.addTrailingStop(msg.sender, _indexToken, _isLong, _posId, _params);
    }

    function cancelPendingOrder(address _indexToken, bool _isLong, uint256 _posId) external nonReentrant {
        positionVault.cancelPendingOrder(msg.sender, _indexToken, _isLong, _posId);
    }

    function decreasePosition(
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _posId
    ) external nonReentrant {
        positionVault.decreasePosition(msg.sender, _indexToken, _sizeDelta, _isLong, _posId);
    }

    function deposit(address _account, address _token, uint256 _amount) external nonReentrant {
        uint256 collateralDeltaUsd = priceManager.tokenToUsd(_token, _amount);
        require(settingsManager.isDeposit(_token), "deposit not allowed");
        require(
            (settingsManager.checkDelegation(_account, msg.sender)) && _amount > 0,
            "zero amount or not allowed for depositFor"
        );
        _transferIn(_account, _token, _amount);
        uint256 fee = (collateralDeltaUsd * settingsManager.depositFee()) / BASIS_POINTS_DIVISOR;
        uint256 afterFeeAmount = collateralDeltaUsd - fee;
        _accountDeltaAndFeeIntoTotalUSDC(true, 0, fee);
        IVUSDC(vUSDC).mint(_account, afterFeeAmount);
        _distributeFee(_account, ZERO_ADDRESS, fee);
        emit Deposit(_account, _token, _amount);
    }

    function distributeFee(address _account, address _refer, uint256 _fee) external override onlyVault {
        _distributeFee(_account, _refer, _fee);
    }

    function newPositionOrder(
        address _indexToken,
        bool _isLong,
        OrderType _orderType,
        uint256[] memory _params,
        address _refer
    ) external payable nonReentrant {
        if (_orderType != OrderType.MARKET) {
            require(msg.value == settingsManager.triggerGasFee(), "invalid triggerGasFee");
            payable(settingsManager.positionManager()).transfer(msg.value);
        }
        positionVault.newPositionOrder(msg.sender, _indexToken, _isLong, _orderType, _params, _refer);
    }

    function setVaultSettings(
        IPriceManager _priceManager,
        ISettingsManager _settingsManager,
        IPositionVault _positionVault
    ) external {
        require(!isInitialized, "Not initialized");
        require(Address.isContract(address(_priceManager)), "priceManager address is invalid");
        require(Address.isContract(address(_settingsManager)), "settingsManager address is invalid");
        require(Address.isContract(address(_positionVault)), "positionVault address is invalid");
        priceManager = _priceManager;
        settingsManager = _settingsManager;
        positionVault = _positionVault;
        isInitialized = true;
    }

    function stake(address _account, address _token, uint256 _amount) external nonReentrant {
        require(settingsManager.isStaking(_token), "stake not allowed");
        require(
            (settingsManager.checkDelegation(_account, msg.sender)) && _amount > 0,
            "zero amount or not allowed for stakeFor"
        );
        uint256 usdAmount = priceManager.tokenToUsd(_token, _amount);
        _transferIn(_account, _token, _amount);
        uint256 usdAmountFee = (usdAmount * settingsManager.stakingFee()) / BASIS_POINTS_DIVISOR;
        uint256 usdAmountAfterFee = usdAmount - usdAmountFee;
        uint256 mintAmount;
        if (totalVLP == 0) {
            mintAmount =
                (usdAmountAfterFee * DEFAULT_VLP_PRICE * (10 ** VLP_DECIMALS)) /
                (PRICE_PRECISION * BASIS_POINTS_DIVISOR);
        } else {
            mintAmount = (usdAmountAfterFee * totalVLP) / totalUSDC;
        }
        _accountDeltaAndFeeIntoTotalUSDC(true, 0, usdAmountFee);
        _distributeFee(_account, ZERO_ADDRESS, usdAmountFee);
        IMintable(vlp).mint(_account, mintAmount);
        lastStakedAt[_account] = block.timestamp;
        totalVLP += mintAmount;
        totalUSDC += usdAmountAfterFee;
        emit Stake(_account, _token, _amount, mintAmount);
    }

    function takeVUSDIn(address _account, address _refer, uint256 _amount, uint256 _fee) external override onlyVault {
        IVUSDC(vUSDC).burn(_account, _amount);
        _mintOrBurnVUSDForVault(true, _amount, _fee, _refer);
        emit TakeVUSDIn(_account, _refer, _amount, _fee);
    }

    function takeVUSDOut(address _account, address _refer, uint256 _fee, uint256 _usdOut) external override onlyVault {
        uint256 _usdOutAfterFee = _usdOut - _fee;
        IVUSDC(vUSDC).mint(_account, _usdOutAfterFee);
        _mintOrBurnVUSDForVault(false, _usdOutAfterFee, _fee, _refer);
        emit TakeVUSDOut(_account, _refer, _usdOut, _fee);
    }

    function unstake(address _tokenOut, uint256 _vlpAmount, address _receiver) external nonReentrant {
        require(settingsManager.isStaking(_tokenOut), "unstake not allowed");
        require(_vlpAmount > 0 && _vlpAmount <= totalVLP, "zero amount not allowed and cant exceed totalVLP");
        require(
            lastStakedAt[msg.sender] + settingsManager.cooldownDuration() <= block.timestamp,
            "cooldown duration not yet passed"
        );
        IMintable(vlp).burn(msg.sender, _vlpAmount);
        uint256 usdAmount = (_vlpAmount * totalUSDC) / totalVLP;
        totalVLP -= _vlpAmount;
        uint256 usdAmountFee = (usdAmount * settingsManager.stakingFee()) / BASIS_POINTS_DIVISOR;
        uint256 usdAmountAfterFee = usdAmount - usdAmountFee;
        totalUSDC -= usdAmount;
        uint256 amountOut = priceManager.usdToToken(_tokenOut, usdAmountAfterFee);
        _accountDeltaAndFeeIntoTotalUSDC(true, 0, usdAmountFee);
        _distributeFee(msg.sender, ZERO_ADDRESS, usdAmountFee);
        _transferOut(_tokenOut, amountOut, _receiver);
        emit Unstake(msg.sender, _tokenOut, _vlpAmount, amountOut);
    }

    function withdraw(address _token, address _account, uint256 _amount) external nonReentrant {
        uint256 fee = (_amount * settingsManager.depositFee()) / BASIS_POINTS_DIVISOR;
        uint256 afterFeeAmount = _amount - fee;
        uint256 collateralDelta = priceManager.usdToToken(_token, afterFeeAmount);
        require(settingsManager.isDeposit(_token), "withdraw not allowed");
        _accountDeltaAndFeeIntoTotalUSDC(true, 0, fee);
        IVUSDC(vUSDC).burn(address(msg.sender), _amount);
        _distributeFee(_account, ZERO_ADDRESS, fee);
        _transferOut(_token, collateralDelta, _account);
        emit Withdraw(address(msg.sender), _token, collateralDelta);
    }

    function transferBounty(address _account, uint256 _amount) external override onlyVault {
        IVUSDC(vUSDC).burn(address(this), _amount);
        IVUSDC(vUSDC).mint(_account, _amount);
        totalUSDC -= _amount;
        emit TransferBounty(_account, _amount);
    }

    function _accountDeltaAndFeeIntoTotalUSDC(bool _hasProfit, uint256 _adjustDelta, uint256 _fee) internal {
        if (_adjustDelta != 0) {
            uint256 _feeRewardOnDelta = (_adjustDelta * settingsManager.feeRewardBasisPoints()) / BASIS_POINTS_DIVISOR;
            if (_hasProfit) {
                totalUSDC += _feeRewardOnDelta;
            } else {
                require(totalUSDC >= _feeRewardOnDelta, "exceeded VLP bottom");
                totalUSDC -= _feeRewardOnDelta;
            }
        }
        totalUSDC += (_fee * settingsManager.feeRewardBasisPoints()) / BASIS_POINTS_DIVISOR;
    }

    function _distributeFee(address _account, address _refer, uint256 _fee) internal {
        _mintOrBurnVUSDForVault(true, _fee, _fee, _refer);
        emit TakeVUSDIn(_account, _refer, 0, _fee);
    }

    function _transferIn(address _account, address _token, uint256 _amount) internal {
        IERC20(_token).safeTransferFrom(_account, address(this), _amount);
    }

    function _transferOut(address _token, uint256 _amount, address _receiver) internal {
        IERC20(_token).safeTransfer(_receiver, _amount);
    }

    function _mintOrBurnVUSDForVault(bool _mint, uint256 _amount, uint256 _fee, address _refer) internal {
        address _feeManager = settingsManager.feeManager();
        if (_fee != 0 && _feeManager != ZERO_ADDRESS) {
            uint256 feeReward = (_fee * settingsManager.feeRewardBasisPoints()) / BASIS_POINTS_DIVISOR;
            uint256 feeMinusFeeReward = _fee - feeReward;
            IVUSDC(vUSDC).mint(_feeManager, feeMinusFeeReward);
            if (_mint) {
                _amount -= feeMinusFeeReward;
            } else {
                _amount += feeMinusFeeReward;
            }
            _fee = feeReward;
        }
        if (_refer != ZERO_ADDRESS && settingsManager.referEnabled()) {
            uint256 referFee = (_fee * settingsManager.referFee()) / BASIS_POINTS_DIVISOR;
            IVUSDC(vUSDC).mint(_refer, referFee);
            if (_mint) {
                _amount -= referFee;
            } else {
                _amount += referFee;
            }
        }
        if (_mint) {
            IVUSDC(vUSDC).mint(address(this), _amount);
        } else {
            IVUSDC(vUSDC).burn(address(this), _amount);
        }
    }

    function getVLPPrice() external view returns (uint256) {
        if (totalVLP == 0) {
            return DEFAULT_VLP_PRICE;
        } else {
            return (BASIS_POINTS_DIVISOR * (10 ** VLP_DECIMALS) * totalUSDC) / (totalVLP * PRICE_PRECISION);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

pragma solidity 0.8.9;

interface IMintable {
    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;

    function setMinter(address _minter, bool _isActive) external;

    function isMinter(address _account) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IVUSDC {
    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;

    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Position, OrderInfo, OrderType, ConfirmInfo} from "../structs.sol";

interface IPositionVault {
    function addOrRemoveCollateral(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool isPlus,
        uint256 _amount
    ) external;

    function addPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) external;

    function addTrailingStop(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params
    ) external;

    function cancelPendingOrder(address _account, address _indexToken, bool _isLong, uint256 _posId) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _posId
    ) external;

    function newPositionOrder(
        address _account,
        address _indexToken,
        bool _isLong,
        OrderType _orderType,
        uint256[] memory _params,
        address _refer
    ) external;

    function getPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external view returns (Position memory, OrderInfo memory, ConfirmInfo memory);

    function poolAmounts(address _token, bool _isLong) external view returns (uint256);

    function reservedAmounts(address _token, bool _isLong) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPriceManager {
    function setTokenConfig(address _token, uint256 _tokenDecimals, uint256 _maxLeverage) external;

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong
    ) external view returns (bool, uint256);

    function getLastPrice(address _token) external view returns (uint256);

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function maxLeverage(address _token) external view returns (uint256);

    function usdToToken(address _token, uint256 _usdAmount) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenToUsd(address _token, uint256 _tokenAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISettingsManager {
    function decreaseBorrowedUsd(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function increaseBorrowedUsd(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function setCustomFeeForUser(address _account, uint256 _feePoints, bool _isEnabled) external;

    function updateCumulativeFundingRate(address _token, bool _isLong) external;

    function borrowedUsdPerAsset(address _token) external view returns (uint256);

    function borrowedUsdPerSide(bool _isLong) external view returns (uint256);

    function borrowedUsdPerUser(address _sender) external view returns (uint256);

    function bountyPercent() external view returns (uint256);

    function checkDelegation(address _master, address _delegate) external view returns (bool);

    function closeDeltaTime() external view returns (uint256);

    function collectMarginFees(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function cumulativeFundingRates(address _token, bool _isLong) external view returns (uint256);

    function delayDeltaTime() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function feeManager() external view returns (address);

    function feeRewardBasisPoints() external view returns (uint256);

    function fundingInterval() external view returns (uint256);

    function fundingRateFactor(address _token, bool _isLong) external view returns (uint256);

    function getFundingFee(
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getPositionFee(address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);

    function getDelegates(address _master) external view returns (address[] memory);

    function isDeposit(address _token) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function isStaking(address _token) external view returns (bool);

    function lastFundingTimes(address _token, bool _isLong) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function liquidateThreshold(address) external view returns (uint256);

    function marginFeeBasisPoints(address _token, bool _isLong) external view returns (uint256);

    function marketOrderEnabled() external view returns (bool);

    function positionManager() external view returns (address);

    function priceMovementPercent() external view returns (uint256);

    function referFee() external view returns (uint256);

    function referEnabled() external view returns (bool);

    function stakingFee() external view returns (uint256);

    function triggerGasFee() external view returns (uint256);

    function validatePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _collateral
    ) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IVault {
    function accountDeltaAndFeeIntoTotalUSDC(bool _hasProfit, uint256 _adjustDelta, uint256 _fee) external;

    function distributeFee(address _account, address _refer, uint256 _fee) external;

    function takeVUSDIn(address _account, address _refer, uint256 _amount, uint256 _fee) external;

    function takeVUSDOut(address _account, address _refer, uint256 _fee, uint256 _usdOut) external;

    function transferBounty(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Constants {
    address public constant ZERO_ADDRESS = address(0);
    uint8 public constant ORDER_FILLED = 1;
    uint8 public constant ORDER_NOT_FILLED = 0;
    uint8 public constant STAKING_PID_FOR_CHARGE_FEE = 1;
    uint256 public constant BASIS_POINTS_DIVISOR = 100000;
    uint256 public constant DEFAULT_FUNDING_RATE_FACTOR = 100;
    uint256 public constant DEFAULT_MAX_BORROW_AMOUNT = 10000000000 * PRICE_PRECISION;
    uint256 public constant DEFAULT_VLP_PRICE = 100000;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000;
    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;
    uint256 public constant MAX_CUSTOM_FEE_POINTS = 50000; // 50%
    uint256 public constant MAX_DEPOSIT_FEE = 10000; // 10%
    uint256 public constant MAX_DELTA_TIME = 24 hours;
    uint256 public constant MAX_COOLDOWN_DURATION = 48 hours;
    uint256 public constant MAX_FEE_BASIS_POINTS = 5000; // 5%
    uint256 public constant MAX_FEE_REWARD_BASIS_POINTS = BASIS_POINTS_DIVISOR; // 100%
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%
    uint256 public constant MAX_FUNDING_RATE_INTERVAL = 48 hours;
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MAX_STAKING_FEE = 10000; // 10%
    uint256 public constant MAX_TOKENFARM_COOLDOWN_DURATION = 4 weeks;
    uint256 public constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;
    uint256 public constant MAX_VESTING_DURATION = 700 days;
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;
    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant MIN_FEE_REWARD_BASIS_POINTS = 50000; // 50%
    uint256 public constant POSITION_MARKET = 0;
    uint256 public constant POSITION_LIMIT = 1;
    uint256 public constant POSITION_STOP_MARKET = 2;
    uint256 public constant POSITION_STOP_LIMIT = 3;
    uint256 public constant POSITION_TRAILING_STOP = 4;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant TRAILING_STOP_TYPE_AMOUNT = 0;
    uint256 public constant TRAILING_STOP_TYPE_PERCENT = 1;
    uint256 public constant VLP_DECIMALS = 18;

    function _getPositionKey(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _indexToken, _isLong, _posId));
    }

    function checkSlippage(
        bool isLong,
        uint256 expectedMarketPrice,
        uint256 slippageBasisPoints,
        uint256 actualMarketPrice
    ) internal pure {
        if (isLong) {
            require(
                actualMarketPrice <=
                    (expectedMarketPrice * (BASIS_POINTS_DIVISOR + slippageBasisPoints)) / BASIS_POINTS_DIVISOR,
                "slippage exceeded"
            );
        } else {
            require(
                (expectedMarketPrice * (BASIS_POINTS_DIVISOR - slippageBasisPoints)) / BASIS_POINTS_DIVISOR <=
                    actualMarketPrice,
                "slippage exceeded"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

enum OrderType {
    MARKET,
    LIMIT,
    STOP,
    STOP_LIMIT,
    TRAILING_STOP
}

enum OrderStatus {
    NONE,
    PENDING,
    FILLED,
    CANCELED
}

enum PositionStatus {
    NONE,
    PENDING,
    FILLED,
    CANCELED
}

enum TriggerStatus {
    OPEN,
    TRIGGERED,
    CANCELLED
}

struct ConfirmInfo {
    bool confirmDelayStatus;
    uint256 pendingDelayCollateral;
    uint256 pendingDelaySize;
    uint256 delayStartTime;
}

struct OrderInfo {
    OrderStatus status;
    uint256 lmtPrice;
    uint256 pendingSize;
    uint256 pendingCollateral;
    uint256 positionType;
    uint256 stepAmount;
    uint256 stepType;
    uint256 stpPrice;
}

struct Position {
    address owner;
    address refer;
    int256 realisedPnl;
    uint256 averagePrice;
    uint256 collateral;
    uint256 entryFundingRate;
    uint256 lastIncreasedTime;
    uint256 lastPrice;
    uint256 reserveAmount;
    uint256 size;
}

struct TriggerOrder {
    bytes32 key;
    uint256[] slPrices;
    uint256[] slAmountPercents;
    uint256[] slTriggeredAmounts;
    uint256[] tpPrices;
    uint256[] tpAmountPercents;
    uint256[] tpTriggeredAmounts;
    TriggerStatus status;
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