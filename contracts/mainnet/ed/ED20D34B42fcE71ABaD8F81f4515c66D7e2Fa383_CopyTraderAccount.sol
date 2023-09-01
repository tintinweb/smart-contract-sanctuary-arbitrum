// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICopyTraderIndex, IVault, IRouter, IPositionRouter} from "./gmxInterfaces.sol";

contract CopyTraderAccount {
    using Address for address;

    /* ========== CONSTANTS ========== */
    address private constant _usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address private constant _wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address private constant _weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address private constant _uni = 0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0;
    address private constant _link = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;

    address public gmxVault = address(0);
    address public gmxRouter = address(0);
    address public gmxPositionRouter = address(0);

    bytes32 private constant _referralCode = 0x0000000000000000000000000000000000000000000000000000000000000000;
    address private constant _callbackTarget = 0x0000000000000000000000000000000000000000;

    /* ========== STATE VARIABLES ========== */
    address public owner;
    address public copyTraderIndex = address(0);
    bool public isCopyTrading = false;

    /* ========== CONSTRUCTOR ========== */
    constructor(address _owner, address _copyTraderIndex, address _gmxVault, address _gmxRouter, address _gmxPositionRouter) {
        owner = _owner;
        copyTraderIndex = _copyTraderIndex;
        gmxVault = _gmxVault;
        gmxRouter = _gmxRouter;
        gmxPositionRouter = _gmxPositionRouter;
        IRouter(gmxRouter).approvePlugin(gmxPositionRouter);
    }

    receive() external payable {}

    /* ========== Modifier ========== */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /* ========== VIEWS ========== */
    function balanceOfEth() public view returns (uint256) {
        return address(this).balance;
    }

    function balanceOfToken(address _tokenAddr) public view returns (uint256) {
        return IERC20(_tokenAddr).balanceOf(address(this));
    }

    function _validateIndexToken(address _indexToken) private pure returns (bool) {
        return _indexToken == _wbtc || _indexToken == _weth || _indexToken == _uni || _indexToken == _link;
    }

    function _getCollateralInUsd(address _tokenAddr, address _indexToken, bool _isLong) private view returns (uint256) {
        uint256 _currentCollateralUsd; // decimals 30
        (, _currentCollateralUsd, , , , , , ) = IVault(gmxVault).getPosition(address(this), _tokenAddr, _indexToken, _isLong);
        return _currentCollateralUsd;
    }

    function _getTokenPrice(address _indexToken, bool _isLong) private view returns (uint256) {
        uint256 _minTokenPrice = IVault(gmxVault).getMinPrice(_indexToken); // decimals 30
        uint256 _maxTokenPrice = IVault(gmxVault).getMaxPrice(_indexToken); // decimals 30
        return _isLong ? _minTokenPrice : _maxTokenPrice; // decimals 30
    }

    function _getAcceptableTokenPrice(bool is_increase, address _indexToken, bool _isLong) private view returns (uint256) {
        uint256 indexTokenPrice = _getTokenPrice(_indexToken, _isLong); // decimals 30
        uint256 offset_indexTokenPrice = (indexTokenPrice * 2) / 100; //  2 %  // decimals 30
        if (is_increase) {
            return _isLong ? indexTokenPrice + offset_indexTokenPrice : indexTokenPrice - offset_indexTokenPrice; // decimals 30
        } else {
            return _isLong ? indexTokenPrice - offset_indexTokenPrice : indexTokenPrice + offset_indexTokenPrice; // decimals 30
        }
    }

    function _getNewCollateralInUsd(uint256 _amountInEth, address _collateralToken, address _indexToken, bool _isLong) private view returns (uint256) {
        uint256 currentCollateralUsd = _getCollateralInUsd(_collateralToken, _indexToken, _isLong); // decimals 30
        uint256 priceEth = _getTokenPrice(_weth, _isLong); // decimals 30
        uint256 addedCollateralUsd = (_amountInEth * priceEth) / 1e18; // decimals 30
        return currentCollateralUsd + addedCollateralUsd; // decimals 30
    }

    function _getGmxMinExecutionFee() private view returns (uint256) {
        return IPositionRouter(gmxPositionRouter).minExecutionFee(); //decimals 18
    }

    function _getGmxExecutionFee() private view returns (uint256) {
        uint256 _minExecutionFee = _getGmxMinExecutionFee();
        return (_minExecutionFee * 120) / 100; // decimals 18	1.2 x minExecutionFee
    }

    function _getMinCollateralUsd() private view returns (uint256) {
        return ICopyTraderIndex(copyTraderIndex).MIN_COLLATERAL_USD(); //decimals 30
    }

    function _getCopyTraderFee() private view returns (uint256) {
        return ICopyTraderIndex(copyTraderIndex).COPY_TRADER_FEE(); //decimals 2
    }

    function _getCtExecuteFee() private view returns (uint256) {
        return ICopyTraderIndex(copyTraderIndex).CT_EXECUTE_FEE(); //decimals 18
    }

    function _getTreasury() private view returns (address) {
        return ICopyTraderIndex(copyTraderIndex).TREASURY();
    }

    function _getBackend() private view returns (address) {
        return ICopyTraderIndex(copyTraderIndex).BACKEND();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function startCopyTrading() external onlyOwner {
        require(!isCopyTrading, "started already");
        isCopyTrading = true;
    }

    function stopCopyTrading() external onlyOwner {
        require(isCopyTrading, "stopped already");
        isCopyTrading = false;
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        require(!isCopyTrading, "copy trading...");
        require(_amount > 0, "must be greater than zero");
        require(_amount <= balanceOfEth(), "must be less than balance of contract");
        payable(owner).transfer(_amount);
    }

    function withdrawToken(address _tokenAddr, uint256 _amount) external onlyOwner {
        require(!isCopyTrading, "copy trading...");
        require(_amount > 0, "must be greater than zero");
        require(_amount <= balanceOfToken(_tokenAddr), "must be less than balance of contract");
        IERC20(_tokenAddr).transfer(owner, _amount);
    }

    function createIncreasePositionETH(address collateralToken, address indexToken, uint256 amountInEth, uint256 sizeDeltaUsd, bool isLong) external returns (bytes32) {
        if (isCopyTrading) {
            require(copyTraderIndex == msg.sender, "sender is not copy trader index");
        } else {
            require(owner == msg.sender, "sender is not owner");
        }
        require(_validateIndexToken(indexToken), "invalid token."); // weth, wbtc, uni, link
        require(amountInEth > 0, "amountIn must be greater than zero"); // decimals 18
        require(_getNewCollateralInUsd(amountInEth, collateralToken, indexToken, isLong) >= _getMinCollateralUsd(), "amountIn must be greater than minColateralUsd.");

        uint256 gmxExecutionFee = _getGmxExecutionFee(); // decimals 18

        // Calc AmountIn of Eth
        uint256 incAmountInEth = 0; // decimals 18
        if (isCopyTrading) {
            uint256 feeAmountEth = (amountInEth * _getCopyTraderFee()) / 10000; // decimals 18
            uint256 executeFeeEth = _getCtExecuteFee(); // decimals 18
            incAmountInEth = amountInEth - feeAmountEth + gmxExecutionFee; // decimals 18
            require(incAmountInEth + executeFeeEth <= balanceOfEth(), "insufficient funds in copy trader account");
            payable(_getTreasury()).transfer(feeAmountEth);
            payable(_getBackend()).transfer(executeFeeEth);
        } else {
            incAmountInEth = amountInEth + gmxExecutionFee; // decimals 18
            require(incAmountInEth <= balanceOfEth(), "insufficient funds in copy trader account");
        }

        //Calc acceptablePrice
        uint256 acceptableIndexTokenPrice = _getAcceptableTokenPrice(true, indexToken, isLong); // decimals 30

        // execute increase Position
        bytes32 returnValue;
        if (isLong) {
            if (indexToken == _weth) {
                address[] memory path = new address[](1);
                path[0] = _weth;
                returnValue = IPositionRouter(gmxPositionRouter).createIncreasePositionETH{value: incAmountInEth}(path, indexToken, 0, sizeDeltaUsd, isLong, acceptableIndexTokenPrice, gmxExecutionFee, _referralCode, _callbackTarget);
            } else {
                address[] memory path = new address[](2);
                path[0] = _weth;
                path[1] = indexToken;
                returnValue = IPositionRouter(gmxPositionRouter).createIncreasePositionETH{value: incAmountInEth}(path, indexToken, 0, sizeDeltaUsd, isLong, acceptableIndexTokenPrice, gmxExecutionFee, _referralCode, _callbackTarget);
            }
        } else {
            address[] memory path = new address[](2);
            path[0] = _weth;
            path[1] = _usdc;
            returnValue = IPositionRouter(gmxPositionRouter).createIncreasePositionETH{value: incAmountInEth}(path, indexToken, 0, sizeDeltaUsd, isLong, acceptableIndexTokenPrice, gmxExecutionFee, _referralCode, _callbackTarget);
        }
        return returnValue;
    }

    function createDecreasePosition(address collateralToken, address indexToken, uint256 collateralDeltaUsd, uint256 sizeDeltaUsd, bool isLong, bool _isClose) external returns (bytes32) {
        if (isCopyTrading) {
            require(copyTraderIndex == msg.sender, "sender is not copy trader index");
        } else {
            require(owner == msg.sender, "sender is not owner");
        }
        require(_validateIndexToken(indexToken), "invalid token."); // weth, wbtc, uni, link
        // require(collateralDeltaUsd > 0, "collateralDeltaUsd must be greater than zero"); // decimals 18
        if (!_isClose) {
            uint256 currentCollateralUsd = _getCollateralInUsd(collateralToken, indexToken, isLong); // decimals 30
            require(currentCollateralUsd - collateralDeltaUsd >= _getMinCollateralUsd(), "new CollateralUsd must be greater than minColateralUsd.");
        }

        uint256 gmxExecutionFee = _getGmxExecutionFee(); // decimals 18

        //Calc acceptablePrice
        uint256 acceptableIndexTokenPrice = _getAcceptableTokenPrice(false, indexToken, isLong); // decimals 30

        // execute decrease Position
        bytes32 returnValue;
        if (isLong) {
            if (indexToken == _weth) {
                address[] memory path = new address[](1);
                path[0] = _weth;
                returnValue = IPositionRouter(gmxPositionRouter).createDecreasePosition{value: gmxExecutionFee}(path, indexToken, collateralDeltaUsd, sizeDeltaUsd, isLong, address(this), acceptableIndexTokenPrice, 0, gmxExecutionFee, true, _callbackTarget);
            } else {
                address[] memory path = new address[](2);
                path[0] = indexToken;
                path[1] = _weth;
                returnValue = IPositionRouter(gmxPositionRouter).createDecreasePosition{value: gmxExecutionFee}(path, indexToken, collateralDeltaUsd, sizeDeltaUsd, isLong, address(this), acceptableIndexTokenPrice, 0, gmxExecutionFee, true, _callbackTarget);
            }
        } else {
            address[] memory path = new address[](2);
            path[0] = _usdc;
            path[1] = _weth;
            returnValue = IPositionRouter(gmxPositionRouter).createDecreasePosition{value: gmxExecutionFee}(path, indexToken, collateralDeltaUsd, sizeDeltaUsd, isLong, address(this), acceptableIndexTokenPrice, 0, gmxExecutionFee, true, _callbackTarget);
        }

        // Calc fee of Eth
        if (isCopyTrading) {
            uint256 priceEth = _getTokenPrice(_weth, isLong); // decimals 30
            uint256 feeAmountUsd = (collateralDeltaUsd * _getCopyTraderFee()) / 10000; // decimals 30
            uint256 feeAmountEth = (feeAmountUsd * 1e18) / priceEth; // decimals 18
            payable(_getTreasury()).transfer(feeAmountEth);
            payable(_getBackend()).transfer(_getCtExecuteFee());
        }

        return returnValue;
    }
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
pragma solidity ^0.8.1;

interface ICopyTraderIndex {
    function MIN_COLLATERAL_USD() external view returns (uint256);

    function COPY_TRADER_FEE() external view returns (uint256);

    function CT_EXECUTE_FEE() external view returns (uint256);

    function TREASURY() external view returns (address);

    function BACKEND() external view returns (address);
}

interface IVault {
    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
}

interface IRouter {
    function approvePlugin(address) external;
}

interface IPositionRouter {
    function minExecutionFee() external view returns (uint256);

    function createIncreasePositionETH(address[] memory _path, address _indexToken, uint256 _minOut, uint256 _sizeDelta, bool _isLong, uint256 _acceptablePrice, uint256 _executionFee, bytes32 _referralCode, address _callbackTarget) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);
}

interface ICopyTraderAccount {
    function createIncreasePositionETH(address collateralToken, address indexToken, uint256 amountInEth, uint256 sizeDeltaUsd, bool isLong) external returns (bytes32);

    function createDecreasePosition(address collateralToken, address indexToken, uint256 collateralDeltaUsd, uint256 sizeDeltaUsd, bool isLong, bool _isClose) external returns (bytes32);
}