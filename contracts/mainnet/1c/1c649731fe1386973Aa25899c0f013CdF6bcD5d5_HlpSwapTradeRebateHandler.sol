// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./BaseRebateHandler.sol";
import "../interfaces/IHandle.sol";
import "./WeeklyRebateLimit.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract HlpSwapTradeRebateHandler is BaseRebateHandler, WeeklyRebateLimit {
    using Address for address;

    bytes32 public constant HLP_SWAP_ACTION = keccak256("HLP_SWAP_ACTION");
    bytes32 public constant HLP_TRADE_ACTION = keccak256("HLP_TRADE_ACTION");

    uint256 public baseRebateFraction = 0.3 * 1 ether;
    uint256 public userReferralRebateFraction = 0.05 * 1 ether;
    uint256 public referrerReferralRebateFraction = 0.15 * 1 ether;

    address public immutable handle;
    address public immutable fxUsd;

    event UpdateRebateFractions(
        uint256 baseRebateFraction,
        uint256 userReferralRebateFraction,
        uint256 referrerReferralRebateFraction
    );

    constructor(
        address _rebatesContract,
        address _referralContract,
        address _forex,
        address _handle,
        uint256 _weeklyLimit,
        address _fxUsd
    )
        BaseRebateHandler(_rebatesContract, _referralContract, _forex)
        WeeklyRebateLimit(_weeklyLimit)
    {
        require(_handle.isContract(), "Handle not contract");
        require(_fxUsd.isContract(), "fxUSD not contract");
        handle = _handle;
        fxUsd = _fxUsd;
    }

    /**
     * @dev sets the rebate distribution fractions, where 100% = 1 ether
     * Note these values may, individually or combined, exceed 100%
     */
    function setRebateDistribution(
        uint256 _baseRebateFraction,
        uint256 _userReferralRebateFraction,
        uint256 _referrerReferralRebateFraction
    ) external onlyOwner {
        baseRebateFraction = _baseRebateFraction;
        userReferralRebateFraction = _userReferralRebateFraction;
        referrerReferralRebateFraction = _referrerReferralRebateFraction;

        emit UpdateRebateFractions(
            _baseRebateFraction,
            _userReferralRebateFraction,
            _referrerReferralRebateFraction
        );
    }

    /// @dev see {IRebateHandler-executeRebates}
    function executeRebates(bytes32 action, bytes calldata params)
        external
        override
        onlyRebates
    {
        (
            address account,
            uint256 feeUsd,
            bool isValidAction
        ) = _getValidAccountAndFeeUsd(action, params);

        // if not valid action, return early. This does not need to revert
        if (!isValidAction) return;

        (address referrer, bool isReferrerValid) = _getReferral(account);
        (
            uint256 rebateToUser,
            uint256 rebateToReferrer
        ) = _getRebateToUserAndReferrer(
                _getForexAmountFromUsd(feeUsd),
                isReferrerValid
            );

        if (_isRebateOverWeeklyLimit(rebateToUser + rebateToReferrer)) return;
        _increaseCumulativeWeeklyRebates(rebateToUser + rebateToReferrer);

        if (rebateToUser > 0) {
            rebatesContract.registerRebate(
                account,
                address(forex),
                rebateToUser,
                action
            );
        }

        if (rebateToReferrer > 0) {
            rebatesContract.registerRebate(
                referrer,
                address(forex),
                rebateToReferrer,
                action
            );
        }
    }

    /**
     * @dev returns the account, fee in USD with 18 decimals, and whether or not the action
     * is valid for this handler
     */
    function _getValidAccountAndFeeUsd(bytes32 action, bytes calldata params)
        private
        pure
        returns (
            address account,
            uint256 feeUsd,
            bool isValidAction
        )
    {
        if (action == HLP_SWAP_ACTION) {
            (feeUsd, account, , ) = abi.decode(
                params,
                (uint256, address, address, address)
            );
            // fee from swap has 18 decimals already
            return (account, feeUsd, true);
        }

        if (action == HLP_TRADE_ACTION) {
            // feeUsd has precision of 18
            (feeUsd, account, , , , ) = abi.decode(
                params,
                (uint256, address, address, address, bool, bool)
            );

            // convert from 30 decimals to 18 decimals
            feeUsd = feeUsd / 10**12;

            return (account, feeUsd, true);
        }

        // no action for this handler, so return without calculating rebates
        return (address(0), 0, false);
    }

    /// @dev calculates the rebate to the user and referrer in forex
    function _getRebateToUserAndReferrer(uint256 forex, bool isReferrerValid)
        private
        view
        returns (uint256 rebateToUser, uint256 rebateToReferrer)
    {
        (
            uint256 baseUserRebate,
            uint256 userReferralRebate,
            uint256 referrerReferralRebate
        ) = _divideForex(forex);
        rebateToUser = baseUserRebate;

        if (isReferrerValid) {
            rebateToUser += userReferralRebate;
            rebateToReferrer = referrerReferralRebate;
        }
    }

    /**
     * @param feeUsd the usd amount (18 decimals) for which to get the forex equivilant
     * @return forexAmount the forex amount equal to {feeUsd}
     */
    function _getForexAmountFromUsd(uint256 feeUsd)
        private
        view
        returns (uint256)
    {
        // amount of ETH equal to 1 FOREX
        uint256 ethPerForex = IHandle(handle).getTokenPrice(address(forex));
        // amount of ETH equal to 1 USD
        uint256 ethPerFxUsd = IHandle(handle).getTokenPrice(fxUsd);

        // amount of FOREX equal to 1 USD
        uint256 forexPerUsd = (1 ether * ethPerFxUsd) / ethPerForex;

        // usd amount * forex per usd = forex equivilant of usd amount
        return (feeUsd * forexPerUsd) / 1 ether;
    }

    /**
     * @param forexAmount the forex to divide
     * @return baseUserRebate the base rebate to go to the user
     * @return userReferralRebate the rebate to go to the user if they have a valid referrer
     * @return referrerReferralRebate the rebate to go to the referrer if the refferer is valid
     */
    function _divideForex(uint256 forexAmount)
        private
        view
        returns (
            uint256 baseUserRebate,
            uint256 userReferralRebate,
            uint256 referrerReferralRebate
        )
    {
        baseUserRebate = (forexAmount * baseRebateFraction) / 1 ether;
        userReferralRebate =
            (forexAmount * userReferralRebateFraction) /
            1 ether;
        referrerReferralRebate =
            (forexAmount * referrerReferralRebateFraction) /
            1 ether;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../interfaces/IRebateHandler.sol";
import "../interfaces/IReferral.sol";
import "../interfaces/IRebates.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract BaseRebateHandler is IRebateHandler {
    using Address for address;

    /// @dev address of the referral manager contract
    IReferral public immutable referralContract;
    /// @dev address of forex, which is the reward sent to users
    IERC20 public immutable forex;
    /// @dev address of the Rebates contract
    IRebates public immutable rebatesContract;

    constructor(
        address _rebatesContract,
        address _referralContract,
        address _forex
    ) {
        require(_rebatesContract.isContract(), "Rebates not contract");
        require(_referralContract.isContract(), "Referral not contract");
        require(_forex.isContract(), "FOREX not contract");

        rebatesContract = IRebates(_rebatesContract);
        referralContract = IReferral(_referralContract);
        forex = IERC20(_forex);
    }

    /// @dev throws if the caller is not {rebatesContract}
    modifier onlyRebates() {
        require(
            msg.sender == address(rebatesContract),
            "BaseRebateHandler: Unauthorized caller"
        );
        _;
    }

    /**
     * @dev gets the referral for {user} and checks if the referral is valid
     * @param user the user to get the referral for
     * @return referrer the referrer of {user}
     * @return isReferrerEligible whether or not {referrer} is valid
     */
    function _getReferral(address user)
        internal
        view
        returns (address referrer, bool isReferrerEligible)
    {
        referrer = referralContract.getReferral(user);
        isReferrerEligible = referrer != address(0) && referrer != user;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IHandle {
    struct Vault {
        // Collateral token address => balance
        mapping(address => uint256) collateralBalance;
        uint256 debt;
        // Collateral token address => R0
        mapping(address => uint256) R0;
    }

    struct CollateralData {
        uint256 mintCR;
        uint256 liquidationFee;
        uint256 interestRate;
    }

    event UpdateDebt(address indexed account, address indexed fxToken);

    event UpdateCollateral(
        address indexed account,
        address indexed fxToken,
        address indexed collateralToken
    );

    event ConfigureCollateralToken(address indexed collateralToken);

    event ConfigureFxToken(address indexed fxToken, bool removed);

    function setCollateralUpperBoundPCT(uint256 ratio) external;

    function setPaused(bool value) external;

    function setFxToken(address token) external;

    function removeFxToken(address token) external;

    function setCollateralToken(
        address token,
        uint256 mintCR,
        uint256 liquidationFee,
        uint256 interestRatePerMille
    ) external;

    function removeCollateralToken(address token) external;

    function getAllCollateralTypes()
        external
        view
        returns (address[] memory collateral);

    function getCollateralDetails(address collateral)
        external
        view
        returns (CollateralData memory);

    function WETH() external view returns (address);

    function treasury() external view returns (address payable);

    function comptroller() external view returns (address);

    function vaultLibrary() external view returns (address);

    function fxKeeperPool() external view returns (address);

    function pct() external view returns (address);

    function liquidator() external view returns (address);

    function interest() external view returns (address);

    function referral() external view returns (address);

    function forex() external view returns (address);

    function rewards() external view returns (address);

    function pctCollateralUpperBound() external view returns (uint256);

    function isFxTokenValid(address fxToken) external view returns (bool);

    function isCollateralValid(address collateral) external view returns (bool);

    function setComponents(address[] memory components) external;

    function updateDebtPosition(
        address account,
        uint256 amount,
        address fxToken,
        bool increase
    ) external;

    function updateCollateralBalance(
        address account,
        uint256 amount,
        address fxToken,
        address collateralToken,
        bool increase
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFees(
        uint256 withdrawFeePerMille,
        uint256 depositFeePerMille,
        uint256 mintFeePerMille,
        uint256 burnFeePerMille
    ) external;

    function getCollateralBalance(
        address account,
        address collateralType,
        address fxToken
    ) external view returns (uint256 balance);

    function getBalance(address account, address fxToken)
        external
        view
        returns (address[] memory collateral, uint256[] memory balances);

    function getDebt(address owner, address fxToken)
        external
        view
        returns (uint256 _debt);

    function getPrincipalDebt(address owner, address fxToken)
        external
        view
        returns (uint256 _debt);

    function getCollateralR0(
        address account,
        address fxToken,
        address collateral
    ) external view returns (uint256 R0);

    function getTokenPrice(address token) external view returns (uint256 quote);

    function setOracle(address fxToken, address oracle) external;

    function FeeRecipient() external view returns (address);

    function mintFeePerMille() external view returns (uint256);

    function burnFeePerMille() external view returns (uint256);

    function withdrawFeePerMille() external view returns (uint256);

    function depositFeePerMille() external view returns (uint256);

    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WeeklyRebateLimit is Ownable {
    uint256 public weeklyLimit;
    uint256 public cumulativeWeeklyRebates;
    uint256 public weekNum = block.timestamp / 1 weeks;

    event UpdateWeeklyLimit(uint256 limit);

    /// @param _weeklyLimit the initial weekly limit of rebates
    constructor(uint256 _weeklyLimit) {
        weeklyLimit = _weeklyLimit;
        emit UpdateWeeklyLimit(_weeklyLimit);
    }

    /**
     * @dev sets the weekly limit of forex to be distributed
     * @param newLimit the new weekly limit
     */
    function setWeeklyLimit(uint256 newLimit) external onlyOwner {
        require(
            newLimit != weeklyLimit,
            "HpsmRebateHandler: State already set"
        );
        weeklyLimit = newLimit;
        emit UpdateWeeklyLimit(newLimit);
    }

    /**
     * @dev increases the cumulative weekly amount of rebates
     * @param increaseAmount the amount to increase
     */
    function _increaseCumulativeWeeklyRebates(uint256 increaseAmount) internal {
        cumulativeWeeklyRebates += increaseAmount;
    }

    /**
     * @dev returns whether increasing the weekly limit by {rebate} will cause it to be over the
     * weekly limit. Updates the weekly limit if a week has passed.
     * @param rebate the rebate to check
     */
    function _isRebateOverWeeklyLimit(uint256 rebate) internal returns (bool) {
        uint256 currentWeek = block.timestamp / 1 weeks;
        if (currentWeek > weekNum) {
            cumulativeWeeklyRebates = 0;
            weekNum = currentWeek;
        }

        return cumulativeWeeklyRebates + rebate > weeklyLimit;
    }
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
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IRebateHandler {
    struct Rebate {
        address receiver;
        uint256 amount;
        address token;
    }

    /**
     * @dev calculates zero or more rebates given arbitrary parameters
     * @param params the abi encoded parameters for this handler
     */
    function executeRebates(bytes32 action, bytes calldata params) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IReferral {
    function setReferral(address userAccount, address referralAccount) external;

    function getReferral(address userAccount) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/**
 * @title IRebates
 * @notice Interface for Rebates
 */
interface IRebates {
    /**
     * @dev sets whether {rebater} can allocate rebates
     * @param rebater the address that can call rebates
     * @param canRebate whether or not {rebater} can rebate
     */
    function setCanInitiateRebate(address rebater, bool canRebate) external;

    /**
     * @dev sets the address that handles actions
     * @param action the id of the rebate action
     * @param handler the address of the contract that handles {action}
     */
    function setRebateHandler(bytes32 action, address handler) external;

    /**
     * @dev allocates rebates based on an arbitrary action / params
     * @param action the id of the rebate action
     * @param params the abi encoded parameters to pass to the handler
     */
    function initiateRebate(bytes32 action, bytes calldata params) external;

    /**
     * @dev creates a rebate of {amount} of {token} to {rebateReceiver}.
     * @param token the token to rebate to {rebateReceiver}
     * @param amount the amount of {token} to rebate to {rebateReceiver}
     * @param rebateReceiver the receiver of the rebate
     * @param action the action corresponding to this rebate
     */
    function registerRebate(
        address rebateReceiver,
        address token,
        uint256 amount,
        bytes32 action
    ) external;

    /**
     * @dev withdraws rebates of {token} to msg.sender
     * @param token the token to claim rebates for
     */
    function claim(address token) external;

    /**
     * @dev withdraws rebates of {token} to {receiver}
     * @param token the token to claim rebates for
     * @param receiver the receiver of the rebate
     */
    function claimFor(address token, address receiver) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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