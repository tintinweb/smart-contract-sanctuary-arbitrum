// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVault {
    function transferToCDX(
        address _token_address,
        uint256 _amount,
        uint256 _customerId,
        uint256 _pid,
        uint256 _purchaseProductAmount,
        uint256 _releaseHeight
    ) external;

    function hedgeTreatment(
        bool _isSell,
        address _token,
        uint256 _amount,
        uint256 _releaseHeight
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-3.0

/// This contract is the main contract for customer transactions.
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@cdxprotocol/vault/contracts/core/interfaces/IVault.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {IRetireOption} from "../interfaces/IRetireOption.sol";
import {IApplyBuyIntent} from "../interfaces/IApplyBuyIntent.sol";
import {IExecution} from "../interfaces/IExecution.sol";
import {IJudgementCondition} from "../interfaces/IJudgementCondition.sol";

import "../library/uniswap/interfaces/ISwap.sol";
import {Auxiliary} from "../library/common/Auxiliary.sol";
import {DataTypes} from "../library/common/DataTypes.sol";

import {IProductPool} from "../product/interfaces/IProductPool.sol";
import {ICustomerPool} from "../product/interfaces/ICustomerPool.sol";

import {Initializable} from "../library/common/Initializable.sol";
import {Ownable} from "../library/common/Ownable.sol";
import {ReentrancyGuard} from "../library/common/ReentrancyGuard.sol";
import {ICDXNFT} from "../interfaces/ICDXNFT.sol";
import {ConfigurationParam} from "../library/common/ConfigurationParam.sol";

contract CDX is Ownable, Initializable, ReentrancyGuard {
    address public ownerAddress;
    IRetireOption public retireOption;
    ICustomerPool public customerPool;
    IJudgementCondition public judgmentCondition;
    ISwap public swap;
    IExecution public execution;
    IProductPool public productPool;
    IApplyBuyIntent public applyBuyIntent;
    IVault public vault;
    ICDXNFT public CDXNFT;
    bool public notFreezeStatus;
    address public guardianAddress;
    bool public locked;
    uint256 public applyBuyFee;
    uint256 public rewardFee;
    address public stableC;

    /// @dev Initialise important addresses for the contract.
    function initialize() external initializer {
        _transferOwnership(_msgSender());
        _initNonReentrant();
        ownerAddress = msg.sender;
        notFreezeStatus = true;
        applyBuyFee = 1000;
        rewardFee = 100000;
        stableC = ConfigurationParam.USDT;
        guardianAddress = ConfigurationParam.GUARDIAN;
    }

    function updateApplyBuyFee(uint256 _applyBuyFee) external onlyOwner {
        require(_applyBuyFee > 0, "applyBuyFee is zero");
        applyBuyFee = _applyBuyFee;
    }

    function updateRewardFee(uint256 _rewardFee) external onlyOwner {
        require(_rewardFee > 0, "rewardFee is zero");
        rewardFee = _rewardFee;
    }

    /// @dev Update StableC addresses for the contract.
    function updateStableC(address _stableC) external onlyOwner {
        require(
            _stableC == ConfigurationParam.USDC || _stableC == ConfigurationParam.USDT,
            "BasePositionManager: the parameter is error address"
        );
        stableC = _stableC;
    }

    /// @dev Update CDXNFT contract addresses for the contract.
    function updateCDXNFTAddress(address _NFTAddress) external onlyOwner {
        require(Address.isContract(_NFTAddress), "BasePositionManager: the parameter is not the contract address");
        CDXNFT = ICDXNFT(_NFTAddress);
    }

    /// @dev Update Vault addresses for the contract.
    function updateVaultAddress(address _vaultAddress) external onlyOwner {
        require(Address.isContract(_vaultAddress), "BasePositionManager: the parameter is not the contract address");
        vault = IVault(_vaultAddress);
    }

    /**
     * notice Call vault to get the reward amount.
     * @param _pid Product id.
     * @param _customerId Customer id.
     * @param _customerReward Reward.
     */
    function updateCustomerReward(
        uint256 _pid,
        uint256 _customerId,
        uint256 _customerReward
    ) external nonReentrant synchronized onlyOwner {
        require(notFreezeStatus, "BasePositionManager: this operation cannot be performed.");
        require(_customerReward > 0, "BasePositionManager: must be greater than zero");
        DataTypes.PurchaseProduct memory purchaseProduct = customerPool.getSpecifiedProduct(_pid, _customerId);
        require(purchaseProduct.amount > 0, "CustomerPoolManager: purchase record not found");
        vault.transferToCDX(
            stableC,
            _customerReward,
            _customerId,
            _pid,
            purchaseProduct.amount,
            purchaseProduct.releaseHeight
        );
        bool result = customerPool.updateCustomerReward(_pid, _customerId, _customerReward);
        require(result, "CustomerPoolManager: update failed");
    }

    /**
     * notice Customers purchase products.
     * @param _pid Product id.
     * @param amount Purchase quota.
     */
    function _c_applyBuyIntent(uint256 amount, uint256 _pid) external nonReentrant synchronized returns (bool) {
        require(notFreezeStatus, "BasePositionManager: this operation cannot be performed.");
        uint256 manageFee = (amount * applyBuyFee) / ConfigurationParam.FEE_DECIMAL;
        uint256 buyAmount = amount - manageFee;
        (uint256 cryptoQuantity, address ercToken) = applyBuyIntent.dealApplyBuyCryptoQuantity(
            buyAmount,
            _pid,
            productPool,
            stableC
        );
        uint256 customerId = CDXNFT.mintCDX(msg.sender);
        bool success = customerPool.addCustomerByProduct(
            _pid,
            customerId,
            msg.sender,
            buyAmount,
            ercToken,
            0,
            cryptoQuantity
        );
        require(success, "CustomerPoolManager: applyBuyIntent failed");
        bool updateSoldTotalAmount = productPool.updateSoldTotalAmount(_pid, buyAmount);
        require(updateSoldTotalAmount, "ProductManager: updateSoldTotalAmount failed");
        TransferHelper.safeTransferFrom(ercToken, msg.sender, address(this), amount);
        TransferHelper.safeTransfer(ercToken, guardianAddress, manageFee);
        DataTypes.TransferHelperInfo[] memory transferHelperInfo = new DataTypes.TransferHelperInfo[](2);
        transferHelperInfo[0] = DataTypes.TransferHelperInfo(
            msg.sender,
            address(this),
            amount,
            ercToken,
            DataTypes.TransferHelperStatus.TOTHIS
        );
        transferHelperInfo[1] = DataTypes.TransferHelperInfo(
            address(this),
            guardianAddress,
            manageFee,
            ercToken,
            DataTypes.TransferHelperStatus.TOMANAGE
        );
        emit ApplyBuyIntent(_pid, msg.sender, amount, ercToken, customerId, transferHelperInfo);
        return success;
    }

    fallback() external payable {
        emit Log(msg.sender, msg.value);
    }

    receive() external payable {
        emit Log(msg.sender, msg.value);
    }

    /// @dev Update Judgment contract addresses for the contract.
    function updateJudgmentAddress(address _judgmentAddress) external onlyOwner {
        require(Address.isContract(_judgmentAddress), "BasePositionManager: the parameter is not the contract address");
        judgmentCondition = IJudgementCondition(_judgmentAddress);
    }

    /// @dev Update Swap contract addresses for the contract.
    function updateSwapExactAddress(address _swapAddress) external onlyOwner {
        require(Address.isContract(_swapAddress), "BasePositionManager: the parameter is not the contract address");
        swap = ISwap(_swapAddress);
    }

    /// @dev Update ApplyBuyIntent contract addresses for the contract.
    function updateApplyBuyIntentAddress(address _applyBuyIntent) external onlyOwner {
        require(Address.isContract(_applyBuyIntent), "BasePositionManager: the parameter is not the contract address");
        applyBuyIntent = IApplyBuyIntent(_applyBuyIntent);
    }

    /// @dev Update RetireOption contract addresses for the contract.
    function updateRetireOptionAddress(address _retireOptionAddress) external onlyOwner {
        require(
            Address.isContract(_retireOptionAddress),
            "BasePositionManager: the parameter is not the contract address"
        );
        retireOption = IRetireOption(_retireOptionAddress);
    }

    /// @dev Update Execution contract addresses for the contract.
    function updateExecutionAddress(address _executionAddress) external onlyOwner {
        require(
            Address.isContract(_executionAddress),
            "BasePositionManager: the parameter is not the contract address"
        );
        execution = IExecution(_executionAddress);
    }

    /// @dev Update ProductPool contract addresses for the contract.
    function updateProductPoolAddress(address _productPoolAddress) external onlyOwner {
        require(
            Address.isContract(_productPoolAddress),
            "BasePositionManager: the parameter is not the contract address"
        );
        productPool = IProductPool(_productPoolAddress);
    }

    /// @dev Update CustomerPool contract addresses for the contract.
    function updateCustomerPoolAddress(address _customerPoolAddress) external onlyOwner {
        require(
            Address.isContract(_customerPoolAddress),
            "BasePositionManager: the parameter is not the contract address"
        );
        customerPool = ICustomerPool(_customerPoolAddress);
    }

    /**
     * notice Retire of specified products.
     * @param _s_pid Product id.
     */
    function _s_retireOneProduct(uint256 _s_pid) external onlyOwner synchronized nonReentrant returns (bool) {
        DataTypes.ProgressStatus result = judgmentCondition.judgementConditionAmount(address(productPool), _s_pid);
        uint256 amount;
        DataTypes.TransferHelperInfo memory transferHelperInfo;
        if (DataTypes.ProgressStatus.UNREACHED == result) {
            Auxiliary.updateProductStatus(productPool, _s_pid, result);
        } else {
            Auxiliary.updateProductStatus(productPool, _s_pid, result);
            (, amount) = Auxiliary.swapExchange(productPool, retireOption, swap, applyBuyIntent, _s_pid, stableC);
            if (amount > 0) {
                TransferHelper.safeTransfer(stableC, address(vault), amount);
                transferHelperInfo = DataTypes.TransferHelperInfo(
                    address(this),
                    address(vault),
                    amount,
                    stableC,
                    DataTypes.TransferHelperStatus.TOVALUT
                );
            }
        }
        emit RetireOneProduct(_s_pid, msg.sender, result, transferHelperInfo);
        return true;
    }

    /**
     * notice Specify purchase record exercise.
     * @param _s_pid Product id.
     * @param _customerId Customer id.
     */
    function _c_executeOneCustomer(
        uint256 _s_pid,
        uint256 _customerId
    ) external synchronized nonReentrant returns (bool) {
        require(notFreezeStatus, "BasePositionManager: this operation cannot be performed.");
        DataTypes.ProductInfo memory product = productPool.getProductInfoByPid(_s_pid);
        require(
            DataTypes.ProgressStatus.UNDELIVERED != product.resultByCondition,
            "ProductManager: undelivered product"
        );
        (DataTypes.CustomerByCrypto memory principal, DataTypes.CustomerByCrypto memory rewards) = execution
            .executeWithRewards(address(productPool), _customerId, msg.sender, _s_pid, customerPool, stableC);
        uint256 rewardFeeValue = (rewards.amount * rewardFee) / ConfigurationParam.FEE_DECIMAL;
        Auxiliary.delCustomerFromProductList(_s_pid, _customerId, customerPool);
        TransferHelper.safeTransfer(rewards.cryptoAddress, guardianAddress, rewardFeeValue);
        TransferHelper.safeTransfer(principal.cryptoAddress, principal.customerAddress, principal.amount);
        TransferHelper.safeTransfer(rewards.cryptoAddress, rewards.customerAddress, rewards.amount - rewardFeeValue);
        DataTypes.TransferHelperInfo[] memory transferHelperInfo = new DataTypes.TransferHelperInfo[](3);
        transferHelperInfo[0] = DataTypes.TransferHelperInfo(
            address(this),
            guardianAddress,
            rewardFeeValue,
            rewards.cryptoAddress,
            DataTypes.TransferHelperStatus.TOMANAGE
        );
        transferHelperInfo[1] = DataTypes.TransferHelperInfo(
            address(this),
            principal.customerAddress,
            principal.amount,
            principal.cryptoAddress,
            DataTypes.TransferHelperStatus.TOCUSTOMERP
        );
        transferHelperInfo[2] = DataTypes.TransferHelperInfo(
            address(this),
            rewards.customerAddress,
            rewards.amount - rewardFeeValue,
            rewards.cryptoAddress,
            DataTypes.TransferHelperStatus.TOCUSTOMERR
        );
        emit ExecuteOneCustomer(_s_pid, _customerId, msg.sender, transferHelperInfo);
        return true;
    }

    function withdraw(
        address token,
        address recipient,
        uint256 amount
    ) external onlyGuardian nonReentrant returns (bool) {
        require(recipient != address(0), "BasePositionManager: the recipient address cannot be empty");
        require(token != address(0), "TokenManager: the token address cannot be empty");
        uint256 balance = getBalanceOf(token);
        require(balance > 0, "BasePositionManager: insufficient balance");
        require(balance >= amount, "TransferManager: excess balance");
        TransferHelper.safeTransfer(token, recipient, amount);
        emit Withdraw(address(this), recipient, token, amount);
        return true;
    }

    function allowanceFrom(address ercToken, address from) public view returns (uint256) {
        IERC20 tokenErc20 = IERC20(ercToken);
        uint256 amount = tokenErc20.allowance(from, address(this));
        return amount;
    }

    /// @dev Gets the token balance specified in the contract.
    function getBalanceOf(address token) public view returns (uint256) {
        IERC20 tokenInToken = IERC20(token);
        return tokenInToken.balanceOf(address(this));
    }

    modifier onlyGuardian() {
        require(guardianAddress == msg.sender, "Ownable: caller is not the Guardian");
        _;
    }

    modifier synchronized() {
        require(!locked, "BasePositionManager: Please wait");
        locked = true;
        _;
        locked = false;
    }

    event ApplyBuyIntent(
        uint256 _pid,
        address sender,
        uint256 amount,
        address ercToken,
        uint256 customerId,
        DataTypes.TransferHelperInfo[] transferHelperInfoList
    );
    event RetireOneProduct(
        uint256 productId,
        address msgSend,
        DataTypes.ProgressStatus status,
        DataTypes.TransferHelperInfo transferHelperInfo
    );
    event ExecuteOneCustomer(
        uint256 productAddr,
        uint256 releaseHeight,
        address msgSend,
        DataTypes.TransferHelperInfo[] transferHelperInfoList
    );
    event Withdraw(address from, address to, address cryptoAddress, uint256 amount);
    event Log(address from, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../library/common/DataTypes.sol";
import "../product/interfaces/IProductPool.sol";
import "../product/interfaces/ICustomerPool.sol";

interface IApplyBuyIntent {
    function dealApplyBuyCryptoQuantity(
        uint256 amount,
        uint256 _pid,
        IProductPool productPool,
        address stableC
    ) external view returns (uint256, address);

    function dealSoldCryptoQuantity(
        uint256 amount,
        DataTypes.ProductInfo memory product,
        address stableC
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ICDXNFT {
    function mintCDX(address player) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../library/common/DataTypes.sol";
import "../product/interfaces/ICustomerPool.sol";

interface IExecution {
    function executeWithRewards(
        address productPoolAddress,
        uint256 customerId,
        address customerAddress,
        uint256 productId,
        ICustomerPool customerPool,
        address stableC
    ) external view returns (DataTypes.CustomerByCrypto memory, DataTypes.CustomerByCrypto memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../library/common/DataTypes.sol";

interface IJudgementCondition {
    function judgementConditionAmount(
        address productPoolAddress,
        uint256 productId
    ) external view returns (DataTypes.ProgressStatus);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../library/common/DataTypes.sol";
import "../product/interfaces/ICustomerPool.sol";

interface IRetireOption {
    function closeWithSwapAmt(
        uint256 tokenInAmount,
        uint256 tokenOutAmount,
        DataTypes.ProductInfo memory product,
        address stableC
    ) external view returns (DataTypes.ExchangeTotal memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@cdxprotocol/vault/contracts/core/interfaces/IVault.sol";
import "./DataTypes.sol";
import "../../product/interfaces/ICustomerPool.sol";
import "../../interfaces/IRetireOption.sol";
import "../uniswap/interfaces/ISwap.sol";
import "./ConfigurationParam.sol";
import "../../interfaces/IApplyBuyIntent.sol";
import "../../product/interfaces/IProductPool.sol";

/// @dev Collection of functions related to the address type
library Auxiliary {
    /// @dev Use a Swap contract to swap coins.
    function swapExchange(
        IProductPool productPool,
        IRetireOption dealData,
        ISwap swap,
        IApplyBuyIntent applyBuyIntent,
        uint256 productId,
        address stableC
    ) internal returns (bool, uint256) {
        DataTypes.ProductInfo memory product = productPool.getProductInfoByPid(productId);
        uint256 tokenInAmount = product.soldTotalAmount;
        uint256 tokenOutAmount = applyBuyIntent.dealSoldCryptoQuantity(tokenInAmount, product, stableC);
        DataTypes.ExchangeTotal memory exchangeTotal = dealData.closeWithSwapAmt(
            tokenInAmount,
            tokenOutAmount,
            product,
            stableC
        );
        TransferHelper.safeApprove(exchangeTotal.tokenIn, address(swap), exchangeTotal.tokenInAmount);
        bool swapResult;
        uint256 amountResult;
        uint256 amount;
        if (stableC == exchangeTotal.tokenIn) {
            (swapResult, amountResult) = swap.swapExactOutputSingle(
                exchangeTotal.tokenOutAmount,
                exchangeTotal.tokenInAmount,
                exchangeTotal.tokenIn,
                exchangeTotal.tokenOut,
                address(this)
            );
            amount = exchangeTotal.tokenInAmount - amountResult;
        } else {
            (swapResult, amountResult) = swap.swapExactInputSingle(
                exchangeTotal.tokenInAmount,
                exchangeTotal.tokenIn,
                exchangeTotal.tokenOut,
                address(this)
            );
            amount = amountResult - exchangeTotal.tokenOutAmount;
        }
        require(swapResult, "UniswapManager: uniswap failed");
        return (swapResult, amount);
    }

    /// @dev Update product status.
    function updateProductStatus(
        IProductPool productPool,
        uint256 productId,
        DataTypes.ProgressStatus result
    ) internal returns (bool) {
        bool updateResultByConditionSuccess = productPool._s_retireProductAndUpdateInfo(productId, result);
        require(updateResultByConditionSuccess, "Failed to update the product status");
        return true;
    }

    /// @dev Clear purchase record.
    function delCustomerFromProductList(
        uint256 productId,
        uint256 customerId,
        ICustomerPool customerPool
    ) internal returns (bool) {
        bool delProductByCustomer = customerPool.deleteSpecifiedProduct(productId, customerId);
        require(delProductByCustomer, "Failed to clear the purchase record. Procedure");
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library ConfigurationParam {
    address internal constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address internal constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address internal constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address internal constant WBTCCHAIN = 0xd0C7101eACbB49F3deCcCc166d238410D6D46d57;
    address internal constant WETHCHAIN = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    address internal constant ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address internal constant GUARDIAN = 0x366e2E5Ed08AA510c45138035d0F502A13F4718A;
    uint256 internal constant STABLEC_DECIMAL = 1e6;
    uint256 internal constant WETH_DECIMAL = 1e18;
    uint256 internal constant WBTC_DECIMAL = 1e8;
    uint256 internal constant ORACLE_DECIMAL = 1e8;
    uint256 internal constant FEE_DECIMAL = 1e6;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library DataTypes {
    struct PurchaseProduct {
        uint256 customerId;
        address customerAddress;
        uint256 amount;
        uint256 releaseHeight;
        address tokenAddress;
        uint256 customerReward;
        uint256 cryptoQuantity;
    }

    struct CustomerByCrypto {
        address customerAddress;
        address cryptoAddress;
        uint256 amount;
    }

    struct ExchangeTotal {
        address tokenIn;
        address tokenOut;
        uint256 tokenInAmount;
        uint256 tokenOutAmount;
    }

    struct ProductInfo {
        uint256 productId;
        uint256 conditionAmount;
        uint256 customerQuantity;
        address cryptoType;
        ProgressStatus resultByCondition;
        address cryptoExchangeAddress;
        uint256 releaseHeight;
        ProductType productType;
        uint256 soldTotalAmount;
        uint256 sellStartTime;
        uint256 sellEndTime;
        uint256 saleTotalAmount;
        uint256 maturityDate;
    }

    struct HedgingAggregatorInfo {
        uint256 customerId;
        uint256 productId;
        address customerAddress;
        uint256 amount;
        uint256 releaseHeight;
    }

    struct TransferHelperInfo {
        address from;
        address to;
        uint256 amount;
        address tokenAddress;
        TransferHelperStatus typeValue;
    }

    enum ProductType {
        BUY_LOW,
        SELL_HIGH
    }

    enum ProgressStatus {
        UNDELIVERED,
        REACHED,
        UNREACHED
    }

    //typeValue 0: customer to this, 1: this to customer principal, 2: this to customer reward, 3: this to valut, 4: this to manageWallet, 5 guardian withdraw
    enum TransferHelperStatus {
        TOTHIS,
        TOCUSTOMERP,
        TOCUSTOMERR,
        TOVALUT,
        TOMANAGE,
        GUARDIANW
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title Initializable
 *
 * @dev Deprecated. This contract is kept in the Upgrades Plugins for backwards compatibility purposes.
 * Users should use openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol instead.
 *
 * Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.9;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.9;

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

    // constructor() {
    //     _status = _NOT_ENTERED;
    // }

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

    function _initNonReentrant() internal virtual {
        _status = _NOT_ENTERED;
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
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ISwap {
    function swapExactInputSingle(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address recipient
    ) external returns (bool, uint256);

    function swapExactOutputSingle(
        uint256 amountOut,
        uint256 amountInMaximum,
        address tokenIn,
        address tokenOut,
        address recipient
    ) external returns (bool, uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "../../library/common/DataTypes.sol";

interface ICustomerPool {
    function deleteSpecifiedProduct(uint256 _prod, uint256 _customerId) external returns (bool);

    function addCustomerByProduct(
        uint256 _pid,
        uint256 _customerId,
        address _customerAddress,
        uint256 _amount,
        address _token,
        uint256 _customerReward,
        uint256 _cryptoQuantity
    ) external returns (bool);

    function updateCustomerReward(uint256 _pid, uint256 _customerId, uint256 _customerReward) external returns (bool);

    function getProductList(uint256 _prod) external view returns (DataTypes.PurchaseProduct[] memory);

    function getSpecifiedProduct(
        uint256 _pid,
        uint256 _customerId
    ) external view returns (DataTypes.PurchaseProduct memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../../library/common/DataTypes.sol";

interface IProductPool {
    function getProductInfoByPid(uint256 productId) external view returns (DataTypes.ProductInfo memory);

    function getProductInfoList() external view returns (DataTypes.ProductInfo[] memory);

    function _s_retireProductAndUpdateInfo(
        uint256 productId,
        DataTypes.ProgressStatus resultByCondition
    ) external returns (bool);

    function updateSoldTotalAmount(uint256 productId, uint256 sellAmount) external returns (bool);
}