// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import "../lib/OwnableAdmin.sol";
import "../lib/SafeERC20.sol";
import "../lib/int/IERC20.sol";
import "../lib/int/IMultiVesting.sol";

contract LaunchTreasury is OwnableAdmin {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;

    /* ======== STATE VARIABLS ======== */

    address public immutable payoutToken;

    mapping(address => bool) public launchContract;

    /* ======== EVENTS ======== */

    event LaunchContractToggled(address launchContract, bool approved);
    event Withdraw(address token, address destination, uint256 amount);

    /* ======== CONSTRUCTOR ======== */

    constructor(address _payoutToken, address _initialOwner) OwnableAdmin(_initialOwner) {
        require(_payoutToken != address(0));
        payoutToken = _payoutToken;
        require(_initialOwner != address(0));
        admin = _initialOwner;
    }

    /* ======== LAUNCH CONTRACT FUNCTION ======== */

    /**
     *  @notice deposit principle token and recieve back payout token
     *  @param _amountPayoutToken uint amount of tokens needed as payout for depositr
     *  @param _tokensForLiquidity uint amount of tokens needed to add liquidity
     */
    function deposit(address _payinToken, uint _payinAmount, uint256 _amountPayoutToken, uint256 _tokensForLiquidity) external {
        require(launchContract[msg.sender], "not a launch");
        if (_payinAmount > 0) {
        IERC20(_payinToken).safeTransferFrom(msg.sender, address(this), _payinAmount);
        }
        IERC20(payoutToken).safeTransfer(msg.sender, (_amountPayoutToken + _tokensForLiquidity));
    }

    /* ======== OWNER FUNCTIONS ======== */

    /**
     *  @notice owner can withdraw ERC20 token to desired address
     *  @param _token uint
     *  @param _destination address
     *  @param _amount uint
     */
    function withdraw(address _token, address _destination, uint256 _amount) external onlyAdmin {
        IERC20(_token).safeTransfer(_destination, _amount);
        emit Withdraw(_token, _destination, _amount);
    }

    /**
     * @notice toggle launch contract
     * @param _launchContract address
     */
    function toggleLaunchContract(address _launchContract) external onlyAdmin {
        launchContract[_launchContract] = !launchContract[_launchContract];
        emit LaunchContractToggled(_launchContract, launchContract[_launchContract]);
    }
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value: amount}("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage)
        internal
        returns (bytes memory)
    {
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage)
        internal
        view
        returns (bytes memory)
    {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
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
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage)
        internal
        pure
        returns (bytes memory)
    {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMultiVesting {
    function Affiliate() external view returns (address);

    function AffiliateEarnings() external view returns (uint256);

    function MizuRegistry() external view returns (address);

    function ReferralEarnings(address) external view returns (uint256);

    function Router() external view returns (address);

    function admin() external view returns (address);

    function bondInfo(address) external view returns (uint256 nonce);

    function claimAffiliate() external;

    function claimReferral(address _referrer) external;

    function currentDebt() external view returns (uint256 currentDebt_);

    function currentDebtID(uint256 _vestingID) external view returns (uint256 currentDebt_);

    function currentMizuFee() external view returns (uint256 currentFee_);

    function customTreasury() external view returns (address);

    function debtDecayAll() external view returns (uint256 totalDecay_);

    function debtDecayID(uint256 _vestingID) external view returns (uint256 decay_);

    function debtRatio(uint256 _vestingID) external view returns (uint256 debtRatio_);

    function deposit(uint256 _amount, address _depositor, address _referrer, uint256 _vestingID, uint256 _minBonus)
        external
        returns (uint256);

    function factory() external view returns (address);

    function getBonus(uint256 _ID) external view returns (uint256 bonus_);

    function getMizuTreasury() external view returns (address mizuTreasury);

    function getPayout(uint256 _amountIn, uint256 _vestingID) external view returns (uint256 payout_);

    function getTerms()
        external
        view
        returns (
            uint256[10] memory vestings_,
            uint256[10] memory bonuses_,
            uint256 maxPayout_,
            uint256[10] memory maxDebts_
        );

    function initializeBond(
        uint256[10] memory _vestingTerms,
        uint256[10] calldata _bonus,
        uint256 _maxPayout,
        uint256[10] calldata _maxDebt
    ) external;

    function isLpBond() external view returns (bool);

    function isPriceVariable() external view returns (bool);

    function lastDecay() external view returns (uint256);

    function maxDebt(uint256 _vestingID) external view returns (uint256);

    function maxPayout() external view returns (uint256);

    function minBonus() external view returns (uint256);

    function payinToken() external view returns (address);

    function payoutToken() external view returns (address);

    function pendingPayoutFor(address _depositor, uint256 _vestingID) external view returns (uint256 pendingPayout_);

    function percentVestedFor(address _depositor, uint256 _vestingID) external view returns (uint256 percentVested_);

    function quoteToken() external view returns (address);

    function redeem(address _depositor, uint256 _vestingID) external returns (uint256);

    function setAffiliate(address _affiliate) external;

    function setBondBonuses(uint256[10] calldata _bonuses) external;

    function setBondMaxDebt(uint256[10] calldata _maxDebt) external;

    function setBondMaxPayout(uint256 _maxPayout) external;

    function setBondMinBonus(uint256 _minBonus) external;

    function setBondTerms(
        uint256[10] memory _vestings,
        uint256[10] memory _bonuses,
        uint256 _minBonus,
        uint256 _maxPayout,
        uint256[10] memory _maxDebt,
        bool _isVariable
    ) external;

    function setBondTermsByVestingId(uint256 _vestingID, uint256 _vesting, uint256 _bonus, uint256 _maxDebt) external;

    function setBondVestings(uint256[10] memory _vestings) external;

    function setSlippageRatio(uint256 _slippageRatio) external;

    function slippageRatio() external view returns (uint256);

    function terms() external view returns (uint256 maxPayout);

    function totalDebt() external view returns (uint256 totalDebt_);

    function totalDebts(uint256) external view returns (uint256);

    function totalPayinBonded() external view returns (uint256);

    function totalPayoutGiven() external view returns (uint256);

    function transferManagment(address _newOwner) external;

    function updateQuoteToken(address _newQuoteToken) external;

    function updateRouter(address _newRouter) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

contract OwnableAdmin {
    address public admin;

    constructor(address _initialOwner) {
        admin = _initialOwner;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "Ownable: caller is not the admin");
        _;
    }

    function transferManagment(address _newOwner) external onlyAdmin {
        require(_newOwner != address(0));
        admin = _newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./int/IERC20.sol";
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}