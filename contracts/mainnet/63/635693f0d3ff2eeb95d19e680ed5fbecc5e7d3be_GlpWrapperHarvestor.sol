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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

interface IGmxRewardTracker {
    function rewardToken() external view returns (address);

    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function averageStakedAmounts(address _account) external view returns (uint256);

    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IMimCauldronDistributor {
    function distribute() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/BoringOwnable.sol";
import "OpenZeppelin/utils/Address.sol";
import "interfaces/IGmxGlpRewardHandler.sol";
import "interfaces/IMimCauldronDistributor.sol";
import "interfaces/IGmxRewardRouterV2.sol";
import "interfaces/IGmxRewardTracker.sol";

contract GlpWrapperHarvestor is BoringOwnable {
    using Address for address;
    event OperatorChanged(address indexed, bool);
    event DistributorChanged(IMimCauldronDistributor indexed, IMimCauldronDistributor indexed);
    error NotAllowedOperator();
    error ReturnRewardBalance(uint256 balance);

    IGmxGlpRewardHandler public immutable wrapper;
    IERC20 public immutable rewardToken;
    IERC20 public immutable outputToken;
    IGmxRewardRouterV2 public immutable rewardRouterV2;

    IMimCauldronDistributor public distributor;
    mapping(address => bool) public operators;
    uint64 public lastExecution;

    modifier onlyOperators() {
        if (msg.sender != owner && !operators[msg.sender]) {
            revert NotAllowedOperator();
        }
        _;
    }

    constructor(
        IERC20 _rewardToken,
        IERC20 _outputToken,
        IGmxRewardRouterV2 _rewardRouterV2,
        IGmxGlpRewardHandler _wrapper,
        IMimCauldronDistributor _distributor
    ) {
        operators[msg.sender] = true;

        rewardToken = _rewardToken;
        outputToken = _outputToken;
        rewardRouterV2 = _rewardRouterV2;
        wrapper = _wrapper;
        distributor = _distributor;
    }

    function claimable() external view returns (uint256) {
        return
            IGmxRewardTracker(rewardRouterV2.feeGmxTracker()).claimable(address(wrapper)) +
            IGmxRewardTracker(rewardRouterV2.feeGlpTracker()).claimable(address(wrapper));
    }

    function totalRewardsBalanceAfterClaiming() external view returns (uint256) {
        return
            rewardToken.balanceOf(address(wrapper)) +
            IGmxRewardTracker(rewardRouterV2.feeGmxTracker()).claimable(address(wrapper)) +
            IGmxRewardTracker(rewardRouterV2.feeGlpTracker()).claimable(address(wrapper));
    }

    function run(uint256 amountOutMin, bytes calldata data) external onlyOperators {
        wrapper.harvest();
        wrapper.swapRewards(amountOutMin, rewardToken, outputToken, address(distributor), data);
        distributor.distribute();
        lastExecution = uint64(block.timestamp);
    }

    function setDistributor(IMimCauldronDistributor _distributor) external onlyOwner {
        emit DistributorChanged(distributor, _distributor);
        distributor = _distributor;
    }

    function setOperator(address operator, bool status) external onlyOwner {
        operators[operator] = status;
        emit OperatorChanged(operator, status);
    }
}