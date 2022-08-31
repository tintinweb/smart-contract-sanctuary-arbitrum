// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "../libraries/Address.sol";
import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/ITreasury.sol";

import "../types/OlympusAccessControlled.sol";

interface ILendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface IStakedTokenIncentivesController {
    function claimRewards(
        address[] memory assets,
        uint256 amount,
        address to
    ) external;

    function claimRewardsOnBehalf(
        address[] memory assets,
        uint256 amount,
        address user,
        address to
    ) external;

    function getRewardsBalance(address[] memory assets, address user) external view returns (uint256);
}

/**
 *  Contract deploys reserves from treasury into the Aave lending pool,
 *  earning interest and $stkAAVE.
 */

contract AaveAllocator is OlympusAccessControlled {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct aTokenData {
        address underlying;
        address aToken;
        uint256 deployed;
        uint256 limit;
        uint256 newLimit;
        uint256 limitChangeTimelockEnd;
    }

    /* ======== STATE VARIABLES ======== */

    // stkAave incentive controller
    IStakedTokenIncentivesController internal immutable incentives =
        IStakedTokenIncentivesController(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);
    // Aave Lending Pool
    ILendingPool internal immutable lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    // Olympus Treasury
    ITreasury internal immutable treasury = ITreasury(0x9A315BdF513367C0377FB36545857d12e85813Ef);

    // all relevant aTokens
    address[] public aTokens;
    // corresponding aTokens for tokens
    mapping(address => aTokenData) public aTokenInfo;
    // total RFV deployed into lending pool
    uint256 public totalValueDeployed;

    // timelock to raise deployment limit
    uint256 public immutable timelockInBlocks = 6600;
    // rebates portion of lending pool fees
    uint16 public referralCode;

    /* ======== CONSTRUCTOR ======== */

    constructor(IOlympusAuthority _authority) OlympusAccessControlled(_authority) {
        referralCode = 0;
    }

    /* ======== OPEN FUNCTIONS ======== */

    /**
     * @notice claims accrued stkAave rewards for all tracked aTokens
     */
    function harvest() public {
        incentives.claimRewards(aTokens, rewardsPending(), address(treasury));
    }

    /**
     * @notice claims accrued stkAave rewards for given aTokens
     */
    function harvestFor(address[] calldata _aTokens) external {
        incentives.claimRewards(_aTokens, rewardsPendingFor(_aTokens), address(treasury));
    }

    /* ======== POLICY FUNCTIONS ======== */

    /**
     * @notice withdraws asset from treasury, deposits asset into lending pool, then deposits aToken into treasury
     */
    function deposit(address token, uint256 amount) public onlyPolicy {
        require(!exceedsLimit(token, amount), "Exceeds deposit limit");

        // retrieve amount of asset from treasury
        treasury.manage(token, amount);

        // approve and deposit into lending pool, returning aToken
        IERC20(token).approve(address(lendingPool), amount);
        lendingPool.deposit(token, amount, address(this), referralCode);

        // account for deposit
        accountingFor(token, amount, treasury.tokenValue(token, amount), true);
    }

    /**
     * @notice withdraws aToken from treasury, withdraws from lending pool, and deposits asset into treasury
     */
    function withdraw(address token, uint256 amount) public onlyPolicy {
        // approve and withdraw from lending pool, returning asset
        IERC20(aTokenInfo[token].aToken).approve(address(lendingPool), amount);
        lendingPool.withdraw(token, amount, address(this));

        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 value = treasury.tokenValue(token, balance);

        // account for withdrawal
        accountingFor(token, balance, value, false);

        // approve and deposit asset into treasury
        IERC20(token).approve(address(treasury), balance);
        treasury.deposit(balance, token, value);
    }

    /**
     * @notice adds asset and corresponding aToken to mapping
     */
    function addToken(
        address token,
        address aToken,
        uint256 max
    ) external onlyPolicy {
        require(token != address(0), "Token: Zero address");
        require(aToken != address(0), "aToken: Zero address");
        require(aTokenInfo[token].deployed == 0, "Token added");

        aTokenInfo[token] = aTokenData({
            underlying: token,
            aToken: aToken,
            deployed: 0,
            limit: max,
            newLimit: 0,
            limitChangeTimelockEnd: 0
        });
    }

    /**
     * @notice lowers max can be deployed for asset (no timelock)
     */
    function lowerLimit(address token, uint256 newMax) external onlyPolicy {
        require(newMax < aTokenInfo[token].limit, "Must be lower");
        require(newMax > aTokenInfo[token].deployed, "Must be less than deployed");
        aTokenInfo[token].limit = newMax;
    }

    /**
     * @notice starts timelock to raise max allocation for asset
     */
    function queueRaiseLimit(address token, uint256 newMax) external onlyPolicy {
        aTokenInfo[token].limitChangeTimelockEnd = block.number.add(timelockInBlocks);
        aTokenInfo[token].newLimit = newMax;
    }

    /**
     * @notice changes max allocation for asset when timelock elapsed
     */
    function raiseLimit(address token) external onlyPolicy {
        aTokenData storage info = aTokenInfo[token];
        require(block.number >= info.limitChangeTimelockEnd, "Timelock not expired");
        info.limit = info.newLimit;
        info.newLimit = 0;
        info.limitChangeTimelockEnd = 0;
    }

    /**
     * @notice set referral code for rebate on fees
     */
    function setReferralCode(uint16 code) external onlyPolicy {
        referralCode = code;
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    /**
     * @notice accounting of deposits/withdrawals of assets
     */
    function accountingFor(
        address token,
        uint256 amount,
        uint256 value,
        bool add
    ) internal {
        if (add) {
            aTokenInfo[token].deployed = aTokenInfo[token].deployed.add(amount); // track amount allocated into pool
            totalValueDeployed = totalValueDeployed.add(value); // track total value allocated into pools
        } else {
            // track amount allocated into pool
            if (amount < aTokenInfo[token].deployed) {
                aTokenInfo[token].deployed = aTokenInfo[token].deployed.sub(amount);
            } else aTokenInfo[token].deployed = 0;

            // track total value allocated into pools
            if (value < totalValueDeployed) {
                totalValueDeployed = totalValueDeployed.sub(value);
            } else totalValueDeployed = 0;
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     * @notice query all pending rewards
     */
    function rewardsPending() public view returns (uint256) {
        return incentives.getRewardsBalance(aTokens, address(this));
    }

    /**
     * @notice query pending rewards for provided aTokens
     */
    function rewardsPendingFor(address[] calldata tokens) public view returns (uint256) {
        return incentives.getRewardsBalance(tokens, address(this));
    }

    /**
     * @notice checks to ensure deposit does not exceed max allocation for asset
     */
    function exceedsLimit(address token, uint256 amount) public view returns (bool) {
        uint256 willBeDeployed = aTokenInfo[token].deployed.add(amount);
        return (willBeDeployed > aTokenInfo[token].limit);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

// TODO(zx): replace with OZ implementation.
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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
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
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    // function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     return _functionCallWithValue(target, data, value, errorMessage);
    // }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IOlympusAuthority.sol";

abstract contract OlympusAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOlympusAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;
pragma abicoder v2;

import "./libraries/SafeERC20.sol";
import "./libraries/SafeMath.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IsOHM.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IDistributor.sol";
import "./interfaces/IStaking.sol";

import "./types/OlympusAccessControlled.sol";

/// @notice Patched distributor for fixing rebase miscalculation error
contract HotfixMintRebaseIssueStakingRewards is OlympusAccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    /* ====== CONSTANTS ====== */
    uint256 public constant EXTRA_REWARDS_MINT_AMOUNT = 0;

    // Deduplicate strings to save gas
    string private constant ERROR_ZERO_ADDRESS = "Zero address: ";

    /* ====== VARIABLES ====== */

    IERC20 public immutable HDX;
    IsOHM public immutable sHDX;
    ITreasury public immutable treasury;
    IStaking public immutable staking;

    bool finished = false;
    

    /* ====== CONSTRUCTOR ====== */

    constructor(
        address _authority,
        address _HDX,
        address _sHDX,
        address _treasury,
        address _staking
    ) OlympusAccessControlled(IOlympusAuthority(_authority)) {
        require(_HDX != address(0), stringConcat(ERROR_ZERO_ADDRESS, "HDX"));
        HDX = IERC20(_HDX);
        require(_sHDX != address(0), stringConcat(ERROR_ZERO_ADDRESS, "sHDX"));
        sHDX = IsOHM(_sHDX);
        require(_treasury != address(0), stringConcat(ERROR_ZERO_ADDRESS, "Treasury"));
        treasury = ITreasury(_treasury);
        require(_staking != address(0), stringConcat(ERROR_ZERO_ADDRESS, "Staking"));
        staking = IStaking(_staking);
    }


    /* ====== VIEW FUNCTIONS ====== */

    /**
        @notice View function for current gap between HDX and total staked HDX.
                Calculated using 
                StakingContract.balancOf(HDX)
                - circulatingSuppy(sHDX)
                + circulatingSupply(gHDX) * gHDX.index
        @return uint
     */
    function currentGap() public view returns (int256) {
        return int256(sHDX.circulatingSupply()) - int256(HDX.balanceOf(address(staking)));
    }

    /* ====== GOVERNOR FUNCTIONS ====== */

    /**
        @notice Execute logic for closing the staking gap discovered in HDX-44
                by minting gap + EXTRA_REWARDS_MINT_AMOUNT HDX tokens
                and transferring them to the staking contract
     */
    function closeStakingGap() external onlyGovernor returns (uint256) {
        require(!finished, "Hotfix has already been executed. This contract is a One Pump Chump, if you need it a gain -> deploy new instance");
        int256 gap = currentGap();
        int256 mintAmount = gap + int256(EXTRA_REWARDS_MINT_AMOUNT);
        require(mintAmount > 0, "Gap < 0, cannot be solved by this hotfix");
        treasury.mint(address(staking), uint256(mintAmount));
        return uint256(mintAmount);
    }

    /**
        @notice Destroy contract to receive refund for storage.
                Separated into it's own function to allow tracking
                the current staking gap for a while after closing the gap
     */
    function kill() external onlyGovernor {
        selfdestruct(msg.sender);
    }


    /* ====== HELPER FUNCTIONS ====== */

    /**
        @notice Helper function to concatenate two strings.
                Most gas efficient implementation available in Solidity 0.7.5
                which we are restrained to because of the currently deployed contracts.
        @return string
     */
    function stringConcat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IsOHM is IERC20 {
    function rebase(uint256 ohmProfit_, uint256 epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function gonsForBalance(uint256 amount) external view returns (uint256);

    function balanceForGons(uint256 gons) external view returns (uint256);

    function index() external view returns (uint256);

    function toG(uint256 amount) external view returns (uint256);

    function fromG(uint256 amount) external view returns (uint256);

    function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external;

    function debtBalances(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IDistributor {
    function distribute() external;

    function bounty() external view returns (uint256);

    function retrieveBounty() external returns (uint256);

    function nextRewardAt(uint256 _rate) external view returns (uint256);

    function nextRewardFor(address _recipient) external view returns (uint256);

    function setBounty(uint256 _bounty) external;

    function addRecipient(address _recipient, uint256 _rewardRate) external;

    function removeRecipient(uint256 _index) external;

    function setAdjustment(
        uint256 _index,
        bool _add,
        uint256 _rate,
        uint256 _target
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later\
pragma solidity 0.7.5;
pragma abicoder v2;

import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IgOHM.sol";
import "../interfaces/IStaking.sol";
import "../types/Ownable.sol";

interface IClaim {
    struct Term {
        uint256 percent; // 4 decimals ( 5000 = 0.5% )
        uint256 wClaimed; // static number
        uint256 max; // maximum nominal OHM amount can claim
    }

    function terms(address _address) external view returns (Term memory);
}

/**
 *  This contract allows Olympus seed investors and advisors to claim tokens.
 *  It has been revised to consider claims as staked immediately for accounting purposes.
 *  This ensures that network ownership does not exceed disclosed levels.
 *  Claimants remain protected from network dilution that may arise, but claim and stake
 *  does not allow them to grow ownership beyond predefined levels. This change also penalizes
 *  sellers, since the tokens sold are still considered staked within this contract. This
 *  step was taken to ensure fair distribution of exposure in the network.
 */
contract InvestorClaimV2 is Ownable {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STRUCTS ========== */

    struct Term {
        uint256 percent; // 4 decimals ( 5000 = 0.5% )
        uint256 gClaimed; // rebase-agnostic number
        uint256 max; // maximum nominal OHM amount can claim
    }

    /* ========== STATE VARIABLES ========== */

    // claim token
    IERC20 internal immutable ohm = IERC20(0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5);
    // payment token
    IERC20 internal immutable dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // mints claim token
    ITreasury internal immutable treasury = ITreasury(0x9A315BdF513367C0377FB36545857d12e85813Ef);
    // stake OHM for sOHM
    IStaking internal immutable staking = IStaking(0xB63cac384247597756545b500253ff8E607a8020);
    // holds non-circulating supply
    address internal immutable dao = 0x245cc372C84B3645Bf0Ffe6538620B04a217988B;
    // tracks rebase-agnostic balance
    IgOHM internal immutable gOHM = IgOHM(0x0ab87046fBb341D058F17CBC4c1133F25a20a52f);
    // previous deployment of contract (to migrate terms)
    IClaim internal immutable previous = IClaim(0xaCCC8306455BaA01593Fa6267809fEA72F684169);

    // tracks address info
    mapping(address => Term) public terms;
    // facilitates address change
    mapping(address => address) public walletChange;
    // as percent of supply (4 decimals: 10000 = 1%)
    uint256 public totalAllocated;
    // maximum portion of supply can allocate. == 4%
    uint256 public maximumAllocated = 40000;

    constructor() {}

    /* ========== MUTABLE FUNCTIONS ========== */

    /**
     * @notice allows wallet to claim OHM
     * @param _to address
     * @param _amount uint256
     */
    function claim(address _to, uint256 _amount) external {
        ohm.safeTransfer(_to, _claim(_amount));
    }

    /**
     * @notice allows wallet to claim OHM and stake. set _claim = true if warmup is 0.
     * @param _to address
     * @param _amount uint256
     * @param _rebasing bool
     * @param _claimFromStaking bool
     */
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claimFromStaking
    ) external {
        staking.stake(_to, _claim(_amount), _rebasing, _claimFromStaking);
    }

    /**
     * @notice logic for claiming OHM
     * @param _amount uint256
     * @return toSend_ uint256
     */
    function _claim(uint256 _amount) internal returns (uint256 toSend_) {
        Term memory info = terms[msg.sender];

        dai.safeTransferFrom(msg.sender, address(this), _amount);
        toSend_ = treasury.deposit(_amount, address(dai), 0);

        require(redeemableFor(msg.sender).div(1e9) >= toSend_, "Claim more than vested");
        require(info.max.sub(claimed(msg.sender)) >= toSend_, "Claim more than max");

        terms[msg.sender].gClaimed = info.gClaimed.add(gOHM.balanceTo(toSend_));
    }

    /**
     * @notice allows address to push terms to new address
     * @param _newAddress address
     */
    function pushWalletChange(address _newAddress) external {
        require(terms[msg.sender].percent != 0, "No wallet to change");
        walletChange[msg.sender] = _newAddress;
    }

    /**
     * @notice allows new address to pull terms
     * @param _oldAddress address
     */
    function pullWalletChange(address _oldAddress) external {
        require(walletChange[_oldAddress] == msg.sender, "Old wallet did not push");
        require(terms[msg.sender].percent != 0, "Wallet already exists");

        walletChange[_oldAddress] = address(0);
        terms[msg.sender] = terms[_oldAddress];
        delete terms[_oldAddress];
    }

    /**
     * @notice mass approval saves gas
     */
    function approve() external {
        ohm.approve(address(staking), 1e33);
        dai.approve(address(treasury), 1e33);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice view OHM claimable for address. DAI decimals (18).
     * @param _address address
     * @return uint256
     */
    function redeemableFor(address _address) public view returns (uint256) {
        Term memory info = terms[_address];
        uint256 max = circulatingSupply().mul(info.percent).div(1e6);
        if (max > info.max) max = info.max;
        return max.sub(claimed(_address)).mul(1e9);
    }

    /**
     * @notice view OHM claimed by address. OHM decimals (9).
     * @param _address address
     * @return uint256
     */
    function claimed(address _address) public view returns (uint256) {
        return gOHM.balanceFrom(terms[_address].gClaimed);
    }

    /**
     * @notice view circulating supply of OHM
     * @notice calculated as total supply minus DAO holdings
     * @return uint256
     */
    function circulatingSupply() public view returns (uint256) {
        return treasury.baseSupply().sub(ohm.balanceOf(dao));
    }

    /* ========== OWNER FUNCTIONS ========== */

    /**
     * @notice bulk migrate users from previous contract
     * @param _addresses address[] memory
     */
    function migrate(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            IClaim.Term memory term = previous.terms(_addresses[i]);
            setTerms(_addresses[i], term.percent, term.wClaimed, term.max);
        }
    }

    /**
     *  @notice set terms for new address
     *  @notice cannot lower for address or exceed maximum total allocation
     *  @param _address address
     *  @param _percent uint256
     *  @param _gClaimed uint256
     *  @param _max uint256
     */
    function setTerms(
        address _address,
        uint256 _percent,
        uint256 _gClaimed,
        uint256 _max
    ) public onlyOwner {
        require(terms[_address].max == 0, "address already exists");
        terms[_address] = Term({percent: _percent, gClaimed: _gClaimed, max: _max});
        require(totalAllocated.add(_percent) <= maximumAllocated, "Cannot allocate more");
        totalAllocated = totalAllocated.add(_percent);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IgOHM is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function index() external view returns (uint256);

    function balanceFrom(uint256 _amount) external view returns (uint256);

    function balanceTo(uint256 _amount) external view returns (uint256);

    function migrate(address _staking, address _sOHM) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "../interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyOwner {
        emit OwnershipPulled(_owner, address(0));
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyOwner {
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later\
pragma solidity 0.7.5;
pragma abicoder v2;

import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IgOHM.sol";
import "../interfaces/IStaking.sol";
import "../types/Ownable.sol";

interface IClaim {
    struct Term {
        uint256 percent; // 4 decimals ( 5000 = 0.5% )
        uint256 claimed; // static number
        uint256 wClaimed; // rebase-tracking number
        uint256 max; // maximum nominal OHM amount can claim
    }

    function terms(address _address) external view returns (Term memory);
}

/**
 *  This contract allows Olympus genesis contributors to claim OHM. It has been
 *  revised to consider 9/10 tokens as staked at the time of claim; previously,
 *  no claims were treated as staked. This change keeps network ownership in check.
 *  100% can be treated as staked, if the DAO sees fit to do so.
 */
contract GenesisClaim is Ownable {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STRUCTS ========== */

    struct Term {
        uint256 percent; // 4 decimals ( 5000 = 0.5% )
        uint256 claimed; // static number
        uint256 gClaimed; // rebase-tracking number
        uint256 max; // maximum nominal OHM amount can claim
    }

    /* ========== STATE VARIABLES ========== */

    // claim token
    IERC20 internal immutable ohm = IERC20(0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5);
    // payment token
    IERC20 internal immutable dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // mints claim token
    ITreasury internal immutable treasury = ITreasury(0x9A315BdF513367C0377FB36545857d12e85813Ef);
    // stake OHM for sOHM
    IStaking internal immutable staking = IStaking(0xB63cac384247597756545b500253ff8E607a8020);
    // holds non-circulating supply
    address internal immutable dao = 0x245cc372C84B3645Bf0Ffe6538620B04a217988B;
    // tracks rebase-agnostic balance
    IgOHM internal immutable gOHM = IgOHM(0x0ab87046fBb341D058F17CBC4c1133F25a20a52f);
    // previous deployment of contract (to migrate terms)
    IClaim internal immutable previous = IClaim(0xEaAA9d97Be33a764031eDdEbA1cB6Cb385350Ca3);

    // track 1/10 as static. governance can disable if desired.
    bool public useStatic;
    // tracks address info
    mapping(address => Term) public terms;
    // facilitates address change
    mapping(address => address) public walletChange;
    // as percent of supply (4 decimals: 10000 = 1%)
    uint256 public totalAllocated;
    // maximum portion of supply can allocate. == 7.8%
    uint256 public maximumAllocated = 78000;

    constructor() {
        useStatic = true;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    /**
     * @notice allows wallet to claim OHM
     * @param _to address
     * @param _amount uint256
     */
    function claim(address _to, uint256 _amount) external {
        ohm.safeTransfer(_to, _claim(_amount));
    }

    /**
     * @notice allows wallet to claim OHM and stake. set _claim = true if warmup is 0.
     * @param _to address
     * @param _amount uint256
     * @param _rebasing bool
     * @param _claimFromStaking bool
     */
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claimFromStaking
    ) external {
        staking.stake(_to, _claim(_amount), _rebasing, _claimFromStaking);
    }

    /**
     * @notice logic for claiming OHM
     * @param _amount uint256
     * @return toSend_ uint256
     */
    function _claim(uint256 _amount) internal returns (uint256 toSend_) {
        Term memory info = terms[msg.sender];

        dai.safeTransferFrom(msg.sender, address(this), _amount);
        toSend_ = treasury.deposit(_amount, address(dai), 0);

        require(redeemableFor(msg.sender).div(1e9) >= toSend_, "Claim more than vested");
        require(info.max.sub(claimed(msg.sender)) >= toSend_, "Claim more than max");

        if (useStatic) {
            terms[msg.sender].gClaimed = info.gClaimed.add(gOHM.balanceTo(toSend_.mul(9).div(10)));
            terms[msg.sender].claimed = info.claimed.add(toSend_.div(10));
        } else terms[msg.sender].gClaimed = info.gClaimed.add(gOHM.balanceTo(toSend_));
    }

    /**
     * @notice allows address to push terms to new address
     * @param _newAddress address
     */
    function pushWalletChange(address _newAddress) external {
        require(terms[msg.sender].percent != 0, "No wallet to change");
        walletChange[msg.sender] = _newAddress;
    }

    /**
     * @notice allows new address to pull terms
     * @param _oldAddress address
     */
    function pullWalletChange(address _oldAddress) external {
        require(walletChange[_oldAddress] == msg.sender, "Old wallet did not push");
        require(terms[msg.sender].percent != 0, "Wallet already exists");

        walletChange[_oldAddress] = address(0);
        terms[msg.sender] = terms[_oldAddress];
        delete terms[_oldAddress];
    }

    /**
     * @notice mass approval saves gas
     */
    function approve() external {
        ohm.approve(address(staking), 1e33);
        dai.approve(address(treasury), 1e33);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice view OHM claimable for address. DAI decimals (18).
     * @param _address address
     * @return uint256
     */
    function redeemableFor(address _address) public view returns (uint256) {
        Term memory info = terms[_address];
        uint256 max = circulatingSupply().mul(info.percent).div(1e6);
        if (max > info.max) max = info.max;
        return max.sub(claimed(_address)).mul(1e9);
    }

    /**
     * @notice view OHM claimed by address. OHM decimals (9).
     * @param _address address
     * @return uint256
     */
    function claimed(address _address) public view returns (uint256) {
        return gOHM.balanceFrom(terms[_address].gClaimed).add(terms[_address].claimed);
    }

    /**
     * @notice view circulating supply of OHM
     * @notice calculated as total supply minus DAO holdings
     * @return uint256
     */
    function circulatingSupply() public view returns (uint256) {
        return treasury.baseSupply().sub(ohm.balanceOf(dao));
    }

    /* ========== OWNER FUNCTIONS ========== */

    /**
     * @notice bulk migrate users from previous contract
     * @param _addresses address[] memory
     */
    function migrate(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            IClaim.Term memory term = previous.terms(_addresses[i]);
            setTerms(_addresses[i], term.percent, term.claimed, term.wClaimed, term.max);
        }
    }

    /**
     *  @notice set terms for new address
     *  @notice cannot lower for address or exceed maximum total allocation
     *  @param _address address
     *  @param _percent uint256
     *  @param _claimed uint256
     *  @param _gClaimed uint256
     *  @param _max uint256
     */
    function setTerms(
        address _address,
        uint256 _percent,
        uint256 _claimed,
        uint256 _gClaimed,
        uint256 _max
    ) public onlyOwner {
        require(terms[_address].max == 0, "address already exists");
        terms[_address] = Term({percent: _percent, claimed: _claimed, gClaimed: _gClaimed, max: _max});
        require(totalAllocated.add(_percent) <= maximumAllocated, "Cannot allocate more");
        totalAllocated = totalAllocated.add(_percent);
    }

    /* ========== DAO FUNCTIONS ========== */

    /**
     * @notice all claims tracked under gClaimed (and track rebase)
     */
    function treatAllAsStaked() external {
        require(msg.sender == dao, "Sender is not DAO");
        useStatic = false;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IsOHM.sol";
import "./interfaces/IgOHM.sol";
import "./interfaces/IDistributor.sol";

import "./types/OlympusAccessControlled.sol";

contract OlympusStaking is OlympusAccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IsOHM;
    using SafeERC20 for IgOHM;

    /* ========== EVENTS ========== */

    event DistributorSet(address distributor);
    event WarmupSet(uint256 warmup);

    /* ========== DATA STRUCTURES ========== */

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    struct Claim {
        uint256 deposit; // if forfeiting
        uint256 gons; // staked balance
        uint256 expiry; // end of warmup period
        bool lock; // prevents malicious delays for claim
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable OHM;
    IsOHM public immutable sOHM;
    IgOHM public immutable gOHM;

    Epoch public epoch;

    IDistributor public distributor;

    mapping(address => Claim) public warmupInfo;
    uint256 public warmupPeriod;
    uint256 private gonsInWarmup;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _ohm,
        address _sOHM,
        address _gOHM,
        uint256 _epochLength,
        uint256 _firstEpochNumber,
        uint256 _firstEpochTime,
        address _authority
    ) OlympusAccessControlled(IOlympusAuthority(_authority)) {
        require(_ohm != address(0), "Zero address: OHM");
        OHM = IERC20(_ohm);
        require(_sOHM != address(0), "Zero address: sOHM");
        sOHM = IsOHM(_sOHM);
        require(_gOHM != address(0), "Zero address: gOHM");
        gOHM = IgOHM(_gOHM);

        epoch = Epoch({length: _epochLength, number: _firstEpochNumber, end: _firstEpochTime, distribute: 0});
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice stake OHM to enter warmup
     * @param _to address
     * @param _amount uint
     * @param _claim bool
     * @param _rebasing bool
     * @return uint
     */
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256) {
        OHM.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = _amount.add(rebase()); // add bounty if rebase occurred
        if (_claim && warmupPeriod == 0) {
            return _send(_to, _amount, _rebasing);
        } else {
            Claim memory info = warmupInfo[_to];
            if (!info.lock) {
                require(_to == msg.sender, "External deposits for account are locked");
            }

            warmupInfo[_to] = Claim({
                deposit: info.deposit.add(_amount),
                gons: info.gons.add(sOHM.gonsForBalance(_amount)),
                expiry: epoch.number.add(warmupPeriod),
                lock: info.lock
            });

            gonsInWarmup = gonsInWarmup.add(sOHM.gonsForBalance(_amount));

            return _amount;
        }
    }

    /**
     * @notice retrieve stake from warmup
     * @param _to address
     * @param _rebasing bool
     * @return uint
     */
    function claim(address _to, bool _rebasing) public returns (uint256) {
        Claim memory info = warmupInfo[_to];

        if (!info.lock) {
            require(_to == msg.sender, "External claims for account are locked");
        }

        if (epoch.number >= info.expiry && info.expiry != 0) {
            delete warmupInfo[_to];

            gonsInWarmup = gonsInWarmup.sub(info.gons);

            return _send(_to, sOHM.balanceForGons(info.gons), _rebasing);
        }
        return 0;
    }

    /**
     * @notice forfeit stake and retrieve OHM
     * @return uint
     */
    function forfeit() external returns (uint256) {
        Claim memory info = warmupInfo[msg.sender];
        delete warmupInfo[msg.sender];

        gonsInWarmup = gonsInWarmup.sub(info.gons);

        OHM.safeTransfer(msg.sender, info.deposit);

        return info.deposit;
    }

    /**
     * @notice prevent new deposits or claims from ext. address (protection from malicious activity)
     */
    function toggleLock() external {
        warmupInfo[msg.sender].lock = !warmupInfo[msg.sender].lock;
    }

    /**
     * @notice redeem sOHM for OHMs
     * @param _to address
     * @param _amount uint
     * @param _trigger bool
     * @param _rebasing bool
     * @return amount_ uint
     */
    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256 amount_) {
        amount_ = _amount;
        uint256 bounty;
        if (_trigger) {
            bounty = rebase();
        }
        if (_rebasing) {
            sOHM.safeTransferFrom(msg.sender, address(this), _amount);
            amount_ = amount_.add(bounty);
        } else {
            gOHM.burn(msg.sender, _amount); // amount was given in gOHM terms
            amount_ = gOHM.balanceFrom(amount_).add(bounty); // convert amount to OHM terms & add bounty
        }

        require(amount_ <= OHM.balanceOf(address(this)), "Insufficient OHM balance in contract");
        OHM.safeTransfer(_to, amount_);
    }

    /**
     * @notice convert _amount sOHM into gBalance_ gOHM
     * @param _to address
     * @param _amount uint
     * @return gBalance_ uint
     */
    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_) {
        sOHM.safeTransferFrom(msg.sender, address(this), _amount);
        gBalance_ = gOHM.balanceTo(_amount);
        gOHM.mint(_to, gBalance_);
    }

    /**
     * @notice convert _amount gOHM into sBalance_ sOHM
     * @param _to address
     * @param _amount uint
     * @return sBalance_ uint
     */
    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_) {
        gOHM.burn(msg.sender, _amount);
        sBalance_ = gOHM.balanceFrom(_amount);
        sOHM.safeTransfer(_to, sBalance_);
    }

    /**
     * @notice trigger rebase if epoch over
     * @return uint256
     */
    function rebase() public returns (uint256) {
        uint256 bounty;
        if (epoch.end <= block.timestamp) {
            sOHM.rebase(epoch.distribute, epoch.number);

            epoch.end = epoch.end.add(epoch.length);
            epoch.number++;

            if (address(distributor) != address(0)) {
                distributor.distribute();
                bounty = distributor.retrieveBounty(); // Will mint ohm for this contract if there exists a bounty
            }
            uint256 balance = OHM.balanceOf(address(this));
            uint256 staked = sOHM.circulatingSupply();
            if (balance <= staked.add(bounty)) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub(staked).sub(bounty);
            }
        }
        return bounty;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice send staker their amount as sOHM or gOHM
     * @param _to address
     * @param _amount uint
     * @param _rebasing bool
     */
    function _send(
        address _to,
        uint256 _amount,
        bool _rebasing
    ) internal returns (uint256) {
        if (_rebasing) {
            sOHM.safeTransfer(_to, _amount); // send as sOHM (equal unit as OHM)
            return _amount;
        } else {
            gOHM.mint(_to, gOHM.balanceTo(_amount)); // send as gOHM (convert units from OHM)
            return gOHM.balanceTo(_amount);
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns the sOHM index, which tracks rebase growth
     * @return uint
     */
    function index() public view returns (uint256) {
        return sOHM.index();
    }

    /**
     * @notice total supply in warmup
     */
    function supplyInWarmup() public view returns (uint256) {
        return sOHM.balanceForGons(gonsInWarmup);
    }

    /**
     * @notice seconds until the next epoch begins
     */
    function secondsToNextEpoch() external view returns (uint256) {
        return epoch.end.sub(block.timestamp);
    }

    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice sets the contract address for LP staking
     * @param _distributor address
     */
    function setDistributor(address _distributor) external onlyGovernor {
        distributor = IDistributor(_distributor);
        emit DistributorSet(_distributor);
    }

    /**
     * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmupLength(uint256 _warmupPeriod) external onlyGovernor {
        warmupPeriod = _warmupPeriod;
        emit WarmupSet(_warmupPeriod);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;
pragma abicoder v2;

import "./libraries/SafeERC20.sol";
import "./libraries/SafeMath.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IDistributor.sol";
import "./interfaces/IStaking.sol";

import "./types/OlympusAccessControlled.sol";

interface IEpoch {
    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    function epoch() external returns (Epoch memory);
}

/// @notice Patched distributor for fixing rebase miscalculation error
contract Distributor is IDistributor, OlympusAccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ====== VARIABLES ====== */

    IERC20 private immutable ohm;
    ITreasury private immutable treasury;
    address private immutable staking;

    mapping(uint256 => Adjust) public adjustments;
    uint256 public override bounty;

    uint256 private immutable rateDenominator = 1_000_000;

    // Used as patch for staking inconsistency bug. Restricts `rebase` logic to
    // only be called from here.
    bool private unlockRebase;

    /* ====== STRUCTS ====== */

    struct Info {
        uint256 rate; // in ten-thousandths ( 5000 = 0.5% )
        address recipient;
    }
    Info[] public info;

    struct Adjust {
        bool add;
        uint256 rate;
        uint256 target;
    }

    /* ====== CONSTRUCTOR ====== */

    constructor(
        address _treasury,
        address _ohm,
        address _staking,
        address _authority
    ) OlympusAccessControlled(IOlympusAuthority(_authority)) {
        require(_treasury != address(0), "Zero address: Treasury");
        treasury = ITreasury(_treasury);
        require(_ohm != address(0), "Zero address: OHM");
        ohm = IERC20(_ohm);
        require(_staking != address(0), "Zero address: Staking");
        staking = _staking;
    }

    /* ====== PUBLIC FUNCTIONS ====== */

    /**
        @notice Patch to trigger rebases via distributor. There is an error in the staking's
                `stake` function which, if it triggers a rebase, pulls forward part of the
                rebase for the next epoch. This patch triggers a rebase by calling unstake
                (which does not have the issue). The patch also restricts `distribute` to
                only be able to be called from a tx originating this function.

                Unfortunately this is the _only_ way to resolve this bug without a migrate.
     */
    function triggerRebase() external {
        require(IEpoch(staking).epoch().end <= block.timestamp, "Epoch has not ended yet");
        unlockRebase = true;
        IStaking(staking).unstake(msg.sender, 0, true, true); // Give the caller the bounty ohm.
        unlockRebase = false;
    }

    /**
        @notice send epoch reward to staking contract
     */
    function distribute() external override {
        require(msg.sender == staking, "Only staking");
        require(unlockRebase, "Rebase locked. Must call from `triggerRebase`.");

        // distribute rewards to each recipient
        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].rate > 0) {
                treasury.mint(info[i].recipient, nextRewardAt(info[i].rate)); // mint and send tokens
                adjust(i); // check for adjustment
            }
        }
    }

    function retrieveBounty() external override returns (uint256) {
        require(msg.sender == staking, "Only staking");
        // If the distributor bounty is > 0, mint it for the staking contract.
        if (bounty > 0) {
            treasury.mint(address(staking), bounty);
        }

        return bounty;
    }

    /* ====== INTERNAL FUNCTIONS ====== */

    /**
        @notice increment reward rate for collector
     */
    function adjust(uint256 _index) internal {
        Adjust memory adjustment = adjustments[_index];
        if (adjustment.rate != 0) {
            if (adjustment.add) {
                // if rate should increase
                info[_index].rate = info[_index].rate.add(adjustment.rate); // raise rate
                if (info[_index].rate >= adjustment.target) {
                    // if target met
                    adjustments[_index].rate = 0; // turn off adjustment
                    info[_index].rate = adjustment.target; // set to target
                }
            } else {
                // if rate should decrease
                if (info[_index].rate > adjustment.rate) {
                    // protect from underflow
                    info[_index].rate = info[_index].rate.sub(adjustment.rate); // lower rate
                } else {
                    info[_index].rate = 0;
                }

                if (info[_index].rate <= adjustment.target) {
                    // if target met
                    adjustments[_index].rate = 0; // turn off adjustment
                    info[_index].rate = adjustment.target; // set to target
                }
            }
        }
    }

    /* ====== VIEW FUNCTIONS ====== */

    /**
        @notice view function for next reward at given rate
        @param _rate uint
        @return uint
     */
    function nextRewardAt(uint256 _rate) public view override returns (uint256) {
        return treasury.baseSupply().mul(_rate).div(rateDenominator);
    }

    /**
        @notice view function for next reward for specified address
        @param _recipient address
        @return uint
     */
    function nextRewardFor(address _recipient) public view override returns (uint256) {
        uint256 reward;
        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].recipient == _recipient) {
                reward = reward.add(nextRewardAt(info[i].rate));
            }
        }
        return reward;
    }

    /* ====== POLICY FUNCTIONS ====== */

    /**
     * @notice set bounty to incentivize keepers
     * @param _bounty uint256
     */
    function setBounty(uint256 _bounty) external override onlyGovernor {
        require(_bounty <= 2e9, "Too much");
        bounty = _bounty;
    }

    /**
        @notice adds recipient for distributions
        @param _recipient address
        @param _rewardRate uint
     */
    function addRecipient(address _recipient, uint256 _rewardRate) external override onlyGovernor {
        require(_recipient != address(0), "Zero address: Recipient");
        require(_rewardRate <= rateDenominator, "Rate cannot exceed denominator");
        info.push(Info({recipient: _recipient, rate: _rewardRate}));
    }

    /**
        @notice removes recipient for distributions
        @param _index uint
     */
    function removeRecipient(uint256 _index) external override {
        require(
            msg.sender == authority.governor() || msg.sender == authority.guardian(),
            "Caller is not governor or guardian"
        );
        require(info[_index].recipient != address(0), "Recipient does not exist");
        info[_index].recipient = address(0);
        info[_index].rate = 0;
    }

    /**
        @notice set adjustment info for a collector's reward rate
        @param _index uint
        @param _add bool
        @param _rate uint
        @param _target uint
     */
    function setAdjustment(
        uint256 _index,
        bool _add,
        uint256 _rate,
        uint256 _target
    ) external override {
        require(
            msg.sender == authority.governor() || msg.sender == authority.guardian(),
            "Caller is not governor or guardian"
        );
        require(info[_index].recipient != address(0), "Recipient does not exist");

        if (msg.sender == authority.guardian()) {
            require(_rate <= info[_index].rate.mul(25).div(1000), "Limiter: cannot adjust by >2.5%");
        }

        if (!_add) {
            require(_rate <= info[_index].rate, "Cannot decrease rate by more than it already is");
        }

        adjustments[_index] = Adjust({add: _add, rate: _rate, target: _target});
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

import "./interfaces/IOwnable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IOHM.sol";
import "./interfaces/IsOHM.sol";
import "./interfaces/IBondingCalculator.sol";
import "./interfaces/ITreasury.sol";

import "./types/OlympusAccessControlled.sol";

contract OlympusTreasury is OlympusAccessControlled, ITreasury {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */

    event Deposit(address indexed token, uint256 amount, uint256 value);
    event Withdrawal(address indexed token, uint256 amount, uint256 value);
    event CreateDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event RepayDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event Managed(address indexed token, uint256 amount);
    event ReservesAudited(uint256 indexed totalReserves);
    event Minted(address indexed caller, address indexed recipient, uint256 amount);
    event PermissionQueued(STATUS indexed status, address queued);
    event Permissioned(address addr, STATUS indexed status, bool result);

    /* ========== DATA STRUCTURES ========== */

    enum STATUS {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        RESERVEDEBTOR,
        REWARDMANAGER,
        SOHM,
        OHMDEBTOR
    }

    struct Queue {
        STATUS managing;
        address toPermit;
        address calculator;
        uint256 timelockEnd;
        bool nullify;
        bool executed;
    }

    /* ========== STATE VARIABLES ========== */

    IOHM public immutable OHM;
    IsOHM public sOHM;

    mapping(STATUS => address[]) public registry;
    mapping(STATUS => mapping(address => bool)) public permissions;
    mapping(address => address) public bondCalculator;

    mapping(address => uint256) public debtLimit;

    uint256 public totalReserves;
    uint256 public totalDebt;
    uint256 public ohmDebt;

    Queue[] public permissionQueue;
    uint256 public immutable blocksNeededForQueue;

    bool public timelockEnabled;
    bool public initialized;

    uint256 public onChainGovernanceTimelock;

    string internal notAccepted = "Treasury: not accepted";
    string internal notApproved = "Treasury: not approved";
    string internal invalidToken = "Treasury: invalid token";
    string internal insufficientReserves = "Treasury: insufficient reserves";

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _ohm,
        uint256 _timelock,
        address _authority
    ) OlympusAccessControlled(IOlympusAuthority(_authority)) {
        require(_ohm != address(0), "Zero address: OHM");
        OHM = IOHM(_ohm);

        timelockEnabled = false;
        initialized = false;
        blocksNeededForQueue = _timelock;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice allow approved address to deposit an asset for OHM
     * @param _amount uint256
     * @param _token address
     * @param _profit uint256
     * @return send_ uint256
     */
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external override returns (uint256 send_) {
        if (permissions[STATUS.RESERVETOKEN][_token]) {
            require(permissions[STATUS.RESERVEDEPOSITOR][msg.sender], notApproved);
        } else if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            require(permissions[STATUS.LIQUIDITYDEPOSITOR][msg.sender], notApproved);
        } else {
            revert(invalidToken);
        }

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 value = tokenValue(_token, _amount);
        // mint OHM needed and store amount of rewards for distribution
        send_ = value.sub(_profit);
        OHM.mint(msg.sender, send_);

        totalReserves = totalReserves.add(value);

        emit Deposit(_token, _amount, value);
    }

    /**
     * @notice allow approved address to burn OHM for reserves
     * @param _amount uint256
     * @param _token address
     */
    function withdraw(uint256 _amount, address _token) external override {
        require(permissions[STATUS.RESERVETOKEN][_token], notAccepted); // Only reserves can be used for redemptions
        require(permissions[STATUS.RESERVESPENDER][msg.sender], notApproved);

        uint256 value = tokenValue(_token, _amount);
        OHM.burnFrom(msg.sender, value);

        totalReserves = totalReserves.sub(value);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit Withdrawal(_token, _amount, value);
    }

    /**
     * @notice allow approved address to withdraw assets
     * @param _token address
     * @param _amount uint256
     */
    function manage(address _token, uint256 _amount) external override {
        if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            require(permissions[STATUS.LIQUIDITYMANAGER][msg.sender], notApproved);
        } else {
            require(permissions[STATUS.RESERVEMANAGER][msg.sender], notApproved);
        }
        if (permissions[STATUS.RESERVETOKEN][_token] || permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            uint256 value = tokenValue(_token, _amount);
            require(value <= excessReserves(), insufficientReserves);
            totalReserves = totalReserves.sub(value);
        }
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Managed(_token, _amount);
    }

    /**
     * @notice mint new OHM using excess reserves
     * @param _recipient address
     * @param _amount uint256
     */
    function mint(address _recipient, uint256 _amount) external override {
        require(permissions[STATUS.REWARDMANAGER][msg.sender], notApproved);
        require(_amount <= excessReserves(), insufficientReserves);
        OHM.mint(_recipient, _amount);
        emit Minted(msg.sender, _recipient, _amount);
    }

    /**
     * DEBT: The debt functions allow approved addresses to borrow treasury assets
     * or OHM from the treasury, using sOHM as collateral. This might allow an
     * sOHM holder to provide OHM liquidity without taking on the opportunity cost
     * of unstaking, or alter their backing without imposing risk onto the treasury.
     * Many of these use cases are yet to be defined, but they appear promising.
     * However, we urge the community to think critically and move slowly upon
     * proposals to acquire these permissions.
     */

    /**
     * @notice allow approved address to borrow reserves
     * @param _amount uint256
     * @param _token address
     */
    function incurDebt(uint256 _amount, address _token) external override {
        uint256 value;
        if (_token == address(OHM)) {
            require(permissions[STATUS.OHMDEBTOR][msg.sender], notApproved);
            value = _amount;
        } else {
            require(permissions[STATUS.RESERVEDEBTOR][msg.sender], notApproved);
            require(permissions[STATUS.RESERVETOKEN][_token], notAccepted);
            value = tokenValue(_token, _amount);
        }
        require(value != 0, invalidToken);

        sOHM.changeDebt(value, msg.sender, true);
        require(sOHM.debtBalances(msg.sender) <= debtLimit[msg.sender], "Treasury: exceeds limit");
        totalDebt = totalDebt.add(value);

        if (_token == address(OHM)) {
            OHM.mint(msg.sender, value);
            ohmDebt = ohmDebt.add(value);
        } else {
            totalReserves = totalReserves.sub(value);
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
        emit CreateDebt(msg.sender, _token, _amount, value);
    }

    /**
     * @notice allow approved address to repay borrowed reserves with reserves
     * @param _amount uint256
     * @param _token address
     */
    function repayDebtWithReserve(uint256 _amount, address _token) external override {
        require(permissions[STATUS.RESERVEDEBTOR][msg.sender], notApproved);
        require(permissions[STATUS.RESERVETOKEN][_token], notAccepted);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 value = tokenValue(_token, _amount);
        sOHM.changeDebt(value, msg.sender, false);
        totalDebt = totalDebt.sub(value);
        totalReserves = totalReserves.add(value);
        emit RepayDebt(msg.sender, _token, _amount, value);
    }

    /**
     * @notice allow approved address to repay borrowed reserves with OHM
     * @param _amount uint256
     */
    function repayDebtWithOHM(uint256 _amount) external {
        require(
            permissions[STATUS.RESERVEDEBTOR][msg.sender] || permissions[STATUS.OHMDEBTOR][msg.sender],
            notApproved
        );
        OHM.burnFrom(msg.sender, _amount);
        sOHM.changeDebt(_amount, msg.sender, false);
        totalDebt = totalDebt.sub(_amount);
        ohmDebt = ohmDebt.sub(_amount);
        emit RepayDebt(msg.sender, address(OHM), _amount, _amount);
    }

    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice takes inventory of all tracked assets
     * @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external onlyGovernor {
        uint256 reserves;
        address[] memory reserveToken = registry[STATUS.RESERVETOKEN];
        for (uint256 i = 0; i < reserveToken.length; i++) {
            if (permissions[STATUS.RESERVETOKEN][reserveToken[i]]) {
                reserves = reserves.add(tokenValue(reserveToken[i], IERC20(reserveToken[i]).balanceOf(address(this))));
            }
        }
        address[] memory liquidityToken = registry[STATUS.LIQUIDITYTOKEN];
        for (uint256 i = 0; i < liquidityToken.length; i++) {
            if (permissions[STATUS.LIQUIDITYTOKEN][liquidityToken[i]]) {
                reserves = reserves.add(
                    tokenValue(liquidityToken[i], IERC20(liquidityToken[i]).balanceOf(address(this)))
                );
            }
        }
        totalReserves = reserves;
        emit ReservesAudited(reserves);
    }

    /**
     * @notice set max debt for address
     * @param _address address
     * @param _limit uint256
     */
    function setDebtLimit(address _address, uint256 _limit) external onlyGovernor {
        debtLimit[_address] = _limit;
    }

    /**
     * @notice enable permission from queue
     * @param _status STATUS
     * @param _address address
     * @param _calculator address
     */
    function enable(
        STATUS _status,
        address _address,
        address _calculator
    ) external onlyGovernor {
        require(timelockEnabled == false, "Use queueTimelock");
        if (_status == STATUS.SOHM) {
            sOHM = IsOHM(_address);
        } else {
            permissions[_status][_address] = true;

            if (_status == STATUS.LIQUIDITYTOKEN) {
                bondCalculator[_address] = _calculator;
            }

            (bool registered, ) = indexInRegistry(_address, _status);
            if (!registered) {
                registry[_status].push(_address);

                if (_status == STATUS.LIQUIDITYTOKEN || _status == STATUS.RESERVETOKEN) {
                    (bool reg, uint256 index) = indexInRegistry(_address, _status);
                    if (reg) {
                        delete registry[_status][index];
                    }
                }
            }
        }
        emit Permissioned(_address, _status, true);
    }

    /**
     *  @notice disable permission from address
     *  @param _status STATUS
     *  @param _toDisable address
     */
    function disable(STATUS _status, address _toDisable) external {
        require(msg.sender == authority.governor() || msg.sender == authority.guardian(), "Only governor or guardian");
        permissions[_status][_toDisable] = false;
        emit Permissioned(_toDisable, _status, false);
    }

    /**
     * @notice check if registry contains address
     * @return (bool, uint256)
     */
    function indexInRegistry(address _address, STATUS _status) public view returns (bool, uint256) {
        address[] memory entries = registry[_status];
        for (uint256 i = 0; i < entries.length; i++) {
            if (_address == entries[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /* ========== TIMELOCKED FUNCTIONS ========== */

    // functions are used prior to enabling on-chain governance

    /**
     * @notice queue address to receive permission
     * @param _status STATUS
     * @param _address address
     * @param _calculator address
     */
    function queueTimelock(
        STATUS _status,
        address _address,
        address _calculator
    ) external onlyGovernor {
        require(_address != address(0));
        require(timelockEnabled == true, "Timelock is disabled, use enable");

        uint256 timelock = block.number.add(blocksNeededForQueue);
        if (_status == STATUS.RESERVEMANAGER || _status == STATUS.LIQUIDITYMANAGER) {
            timelock = block.number.add(blocksNeededForQueue.mul(2));
        }
        permissionQueue.push(
            Queue({
                managing: _status,
                toPermit: _address,
                calculator: _calculator,
                timelockEnd: timelock,
                nullify: false,
                executed: false
            })
        );
        emit PermissionQueued(_status, _address);
    }

    /**
     *  @notice enable queued permission
     *  @param _index uint256
     */
    function execute(uint256 _index) external {
        require(timelockEnabled == true, "Timelock is disabled, use enable");

        Queue memory info = permissionQueue[_index];

        require(!info.nullify, "Action has been nullified");
        require(!info.executed, "Action has already been executed");
        require(block.number >= info.timelockEnd, "Timelock not complete");

        if (info.managing == STATUS.SOHM) {
            // 9
            sOHM = IsOHM(info.toPermit);
        } else {
            permissions[info.managing][info.toPermit] = true;

            if (info.managing == STATUS.LIQUIDITYTOKEN) {
                bondCalculator[info.toPermit] = info.calculator;
            }
            (bool registered, ) = indexInRegistry(info.toPermit, info.managing);
            if (!registered) {
                registry[info.managing].push(info.toPermit);

                if (info.managing == STATUS.LIQUIDITYTOKEN) {
                    (bool reg, uint256 index) = indexInRegistry(info.toPermit, STATUS.RESERVETOKEN);
                    if (reg) {
                        delete registry[STATUS.RESERVETOKEN][index];
                    }
                } else if (info.managing == STATUS.RESERVETOKEN) {
                    (bool reg, uint256 index) = indexInRegistry(info.toPermit, STATUS.LIQUIDITYTOKEN);
                    if (reg) {
                        delete registry[STATUS.LIQUIDITYTOKEN][index];
                    }
                }
            }
        }
        permissionQueue[_index].executed = true;
        emit Permissioned(info.toPermit, info.managing, true);
    }

    /**
     * @notice cancel timelocked action
     * @param _index uint256
     */
    function nullify(uint256 _index) external onlyGovernor {
        permissionQueue[_index].nullify = true;
    }

    /**
     * @notice disables timelocked functions
     */
    function disableTimelock() external onlyGovernor {
        require(timelockEnabled == true, "timelock already disabled");
        if (onChainGovernanceTimelock != 0 && onChainGovernanceTimelock <= block.number) {
            timelockEnabled = false;
        } else {
            onChainGovernanceTimelock = block.number.add(blocksNeededForQueue.mul(7)); // 7-day timelock
        }
    }

    /**
     * @notice enables timelocks after initilization
     */
    function initialize() external onlyGovernor {
        require(initialized == false, "Already initialized");
        timelockEnabled = true;
        initialized = true;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns excess reserves not backing tokens
     * @return uint
     */
    function excessReserves() public view override returns (uint256) {
        return totalReserves.sub(OHM.totalSupply().sub(totalDebt));
    }

    /**
     * @notice returns OHM valuation of asset
     * @param _token address
     * @param _amount uint256
     * @return value_ uint256
     */
    function tokenValue(address _token, uint256 _amount) public view override returns (uint256 value_) {
        value_ = _amount.mul(10**IERC20Metadata(address(OHM)).decimals()).div(10**IERC20Metadata(_token).decimals());

        if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            value_ = IBondingCalculator(bondCalculator[_token]).valuation(_token, _amount);
        }
    }

    /**
     * @notice returns supply metric that cannot be manipulated by debt
     * @dev use this any time you need to query supply
     * @return uint256
     */
    function baseSupply() external view override returns (uint256) {
        return OHM.totalSupply() - ohmDebt;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IOHM is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IBondingCalculator {
    function markdown(address _LP) external view returns (uint256);

    function valuation(address pair_, uint256 amount_) external view returns (uint256 _value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./libraries/SafeMath.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/Address.sol";
import "./libraries/SafeERC20.sol";

import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IBondingCalculator.sol";
import "./interfaces/IUniswapV2ERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract OlympusBondingCalculator is IBondingCalculator {
    using FixedPoint for *;
    using SafeMath for uint256;

    IERC20 internal immutable OHM;

    constructor(address _OHM) {
        require(_OHM != address(0), "Zero address: OHM");
        OHM = IERC20(_OHM);
    }

    function getKValue(address _pair) public view returns (uint256 k_) {
        uint256 token0 = IERC20Metadata(IUniswapV2Pair(_pair).token0()).decimals();
        uint256 token1 = IERC20Metadata(IUniswapV2Pair(_pair).token1()).decimals();
        uint256 decimals = token0.add(token1).sub(IERC20Metadata(_pair).decimals());

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair).getReserves();
        k_ = reserve0.mul(reserve1).div(10**decimals);
    }

    function getTotalValue(address _pair) public view returns (uint256 _value) {
        _value = getKValue(_pair).sqrrt().mul(2);
    }

    function valuation(address _pair, uint256 amount_) external view override returns (uint256 _value) {
        uint256 totalValue = getTotalValue(_pair);
        uint256 totalSupply = IUniswapV2Pair(_pair).totalSupply();

        _value = totalValue.mul(FixedPoint.fraction(amount_, totalSupply).decode112with18()).div(1e18);
    }

    function markdown(address _pair) external view override returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair).getReserves();

        uint256 reserve;
        if (IUniswapV2Pair(_pair).token0() == address(OHM)) {
            reserve = reserve1;
        } else {
            require(IUniswapV2Pair(_pair).token1() == address(OHM), "Invalid pair");
            reserve = reserve0;
        }
        return reserve.mul(2 * (10**IERC20Metadata(address(OHM)).decimals())).div(getTotalValue(_pair));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./FullMath.sol";

library Babylonian {
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

library BitMath {
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::mostSignificantBit: zero");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}

library FixedPoint {
    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint256) {
        return uint256(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint::fraction: division by zero");
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        }
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function mint(address to) external returns (uint256 liquidity);

    function sync() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, "FullMath: FULLDIV_OVERFLOW");
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import "../interfaces/IERC20.sol";
import "../types/Ownable.sol";

contract OhmFaucet is Ownable {
    IERC20 public ohm;

    constructor(address _ohm) {
        ohm = IERC20(_ohm);
    }

    function setOhm(address _ohm) external onlyOwner {
        ohm = IERC20(_ohm);
    }

    function dispense() external {
        ohm.transfer(msg.sender, 1e9);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import "../interfaces/IERC20.sol";
import "../interfaces/IsOHM.sol";
import "../interfaces/IwsOHM.sol";
import "../interfaces/IgOHM.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IStakingV1.sol";
import "../interfaces/ITreasuryV1.sol";

import "../types/OlympusAccessControlled.sol";

import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

contract OlympusTokenMigrator is OlympusAccessControlled {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IgOHM;
    using SafeERC20 for IsOHM;
    using SafeERC20 for IwsOHM;

    /* ========== MIGRATION ========== */

    event TimelockStarted(uint256 block, uint256 end);
    event Migrated(address staking, address treasury);
    event Funded(uint256 amount);
    event Defunded(uint256 amount);

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable oldOHM;
    IsOHM public immutable oldsOHM;
    IwsOHM public immutable oldwsOHM;
    ITreasuryV1 public immutable oldTreasury;
    IStakingV1 public immutable oldStaking;

    IUniswapV2Router public immutable sushiRouter;
    IUniswapV2Router public immutable uniRouter;

    IgOHM public gOHM;
    ITreasury public newTreasury;
    IStaking public newStaking;
    IERC20 public newOHM;

    bool public ohmMigrated;
    bool public shutdown;

    uint256 public immutable timelockLength;
    uint256 public timelockEnd;

    uint256 public oldSupply;

    constructor(
        address _oldOHM,
        address _oldsOHM,
        address _oldTreasury,
        address _oldStaking,
        address _oldwsOHM,
        address _sushi,
        address _uni,
        uint256 _timelock,
        address _authority
    ) OlympusAccessControlled(IOlympusAuthority(_authority)) {
        require(_oldOHM != address(0), "Zero address: OHM");
        oldOHM = IERC20(_oldOHM);
        require(_oldsOHM != address(0), "Zero address: sOHM");
        oldsOHM = IsOHM(_oldsOHM);
        require(_oldTreasury != address(0), "Zero address: Treasury");
        oldTreasury = ITreasuryV1(_oldTreasury);
        require(_oldStaking != address(0), "Zero address: Staking");
        oldStaking = IStakingV1(_oldStaking);
        require(_oldwsOHM != address(0), "Zero address: wsOHM");
        oldwsOHM = IwsOHM(_oldwsOHM);
        require(_sushi != address(0), "Zero address: Sushi");
        sushiRouter = IUniswapV2Router(_sushi);
        require(_uni != address(0), "Zero address: Uni");
        uniRouter = IUniswapV2Router(_uni);
        timelockLength = _timelock;
    }

    /* ========== MIGRATION ========== */

    enum TYPE {
        UNSTAKED,
        STAKED,
        WRAPPED
    }

    // migrate OHMv1, sOHMv1, or wsOHM for OHMv2, sOHMv2, or gOHM
    function migrate(
        uint256 _amount,
        TYPE _from,
        TYPE _to
    ) external {
        require(!shutdown, "Shut down");

        uint256 wAmount = oldwsOHM.sOHMTowOHM(_amount);

        if (_from == TYPE.UNSTAKED) {
            require(ohmMigrated, "Only staked until migration");
            oldOHM.safeTransferFrom(msg.sender, address(this), _amount);
        } else if (_from == TYPE.STAKED) {
            oldsOHM.safeTransferFrom(msg.sender, address(this), _amount);
        } else {
            oldwsOHM.safeTransferFrom(msg.sender, address(this), _amount);
            wAmount = _amount;
        }

        if (ohmMigrated) {
            require(oldSupply >= oldOHM.totalSupply(), "OHMv1 minted");
            _send(wAmount, _to);
        } else {
            gOHM.mint(msg.sender, wAmount);
        }
    }

    // migrate all olympus tokens held
    function migrateAll(TYPE _to) external {
        require(!shutdown, "Shut down");

        uint256 ohmBal = 0;
        uint256 sOHMBal = oldsOHM.balanceOf(msg.sender);
        uint256 wsOHMBal = oldwsOHM.balanceOf(msg.sender);

        if (oldOHM.balanceOf(msg.sender) > 0 && ohmMigrated) {
            ohmBal = oldOHM.balanceOf(msg.sender);
            oldOHM.safeTransferFrom(msg.sender, address(this), ohmBal);
        }
        if (sOHMBal > 0) {
            oldsOHM.safeTransferFrom(msg.sender, address(this), sOHMBal);
        }
        if (wsOHMBal > 0) {
            oldwsOHM.safeTransferFrom(msg.sender, address(this), wsOHMBal);
        }

        uint256 wAmount = wsOHMBal.add(oldwsOHM.sOHMTowOHM(ohmBal.add(sOHMBal)));
        if (ohmMigrated) {
            require(oldSupply >= oldOHM.totalSupply(), "OHMv1 minted");
            _send(wAmount, _to);
        } else {
            gOHM.mint(msg.sender, wAmount);
        }
    }

    // send preferred token
    function _send(uint256 wAmount, TYPE _to) internal {
        if (_to == TYPE.WRAPPED) {
            gOHM.safeTransfer(msg.sender, wAmount);
        } else if (_to == TYPE.STAKED) {
            newStaking.unwrap(msg.sender, wAmount);
        } else if (_to == TYPE.UNSTAKED) {
            newStaking.unstake(msg.sender, wAmount, false, false);
        }
    }

    // bridge back to OHM, sOHM, or wsOHM
    function bridgeBack(uint256 _amount, TYPE _to) external {
        if (!ohmMigrated) {
            gOHM.burn(msg.sender, _amount);
        } else {
            gOHM.safeTransferFrom(msg.sender, address(this), _amount);
        }

        uint256 amount = oldwsOHM.wOHMTosOHM(_amount);
        // error throws if contract does not have enough of type to send
        if (_to == TYPE.UNSTAKED) {
            oldOHM.safeTransfer(msg.sender, amount);
        } else if (_to == TYPE.STAKED) {
            oldsOHM.safeTransfer(msg.sender, amount);
        } else if (_to == TYPE.WRAPPED) {
            oldwsOHM.safeTransfer(msg.sender, _amount);
        }
    }

    /* ========== OWNABLE ========== */

    // halt migrations (but not bridging back)
    function halt() external onlyPolicy {
        require(!ohmMigrated, "Migration has occurred");
        shutdown = !shutdown;
    }

    // withdraw backing of migrated OHM
    function defund(address reserve) external onlyGovernor {
        require(ohmMigrated, "Migration has not begun");
        require(timelockEnd < block.number && timelockEnd != 0, "Timelock not complete");

        oldwsOHM.unwrap(oldwsOHM.balanceOf(address(this)));

        uint256 amountToUnstake = oldsOHM.balanceOf(address(this));
        oldsOHM.approve(address(oldStaking), amountToUnstake);
        oldStaking.unstake(amountToUnstake, false);

        uint256 balance = oldOHM.balanceOf(address(this));

        if (balance > oldSupply) {
            oldSupply = 0;
        } else {
            oldSupply -= balance;
        }

        uint256 amountToWithdraw = balance.mul(1e9);
        oldOHM.approve(address(oldTreasury), amountToWithdraw);
        oldTreasury.withdraw(amountToWithdraw, reserve);
        IERC20(reserve).safeTransfer(address(newTreasury), IERC20(reserve).balanceOf(address(this)));

        emit Defunded(balance);
    }

    // start timelock to send backing to new treasury
    function startTimelock() external onlyGovernor {
        require(timelockEnd == 0, "Timelock set");
        timelockEnd = block.number.add(timelockLength);

        emit TimelockStarted(block.number, timelockEnd);
    }

    // set gOHM address
    function setgOHM(address _gOHM) external onlyGovernor {
        require(address(gOHM) == address(0), "Already set");
        require(_gOHM != address(0), "Zero address: gOHM");

        gOHM = IgOHM(_gOHM);
    }

    // call internal migrate token function
    function migrateToken(address token) external onlyGovernor {
        _migrateToken(token, false);
    }

    /**
     *   @notice Migrate LP and pair with new OHM
     */
    function migrateLP(
        address pair,
        bool sushi,
        address token,
        uint256 _minA,
        uint256 _minB
    ) external onlyGovernor {
        uint256 oldLPAmount = IERC20(pair).balanceOf(address(oldTreasury));
        oldTreasury.manage(pair, oldLPAmount);

        IUniswapV2Router router = sushiRouter;
        if (!sushi) {
            router = uniRouter;
        }

        IERC20(pair).approve(address(router), oldLPAmount);
        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            token,
            address(oldOHM),
            oldLPAmount,
            _minA,
            _minB,
            address(this),
            block.timestamp
        );

        newTreasury.mint(address(this), amountB);

        IERC20(token).approve(address(router), amountA);
        newOHM.approve(address(router), amountB);

        router.addLiquidity(
            token,
            address(newOHM),
            amountA,
            amountB,
            amountA,
            amountB,
            address(newTreasury),
            block.timestamp
        );
    }

    // Failsafe function to allow owner to withdraw funds sent directly to contract in case someone sends non-ohm tokens to the contract
    function withdrawToken(
        address tokenAddress,
        uint256 amount,
        address recipient
    ) external onlyGovernor {
        require(tokenAddress != address(0), "Token address cannot be 0x0");
        require(tokenAddress != address(gOHM), "Cannot withdraw: gOHM");
        require(tokenAddress != address(oldOHM), "Cannot withdraw: old-OHM");
        require(tokenAddress != address(oldsOHM), "Cannot withdraw: old-sOHM");
        require(tokenAddress != address(oldwsOHM), "Cannot withdraw: old-wsOHM");
        require(amount > 0, "Withdraw value must be greater than 0");
        if (recipient == address(0)) {
            recipient = msg.sender; // if no address is specified the value will will be withdrawn to Owner
        }

        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 contractBalance = tokenContract.balanceOf(address(this));
        if (amount > contractBalance) {
            amount = contractBalance; // set the withdrawal amount equal to balance within the account.
        }
        // transfer the token from address of this contract
        tokenContract.safeTransfer(recipient, amount);
    }

    // migrate contracts
    function migrateContracts(
        address _newTreasury,
        address _newStaking,
        address _newOHM,
        address _newsOHM,
        address _reserve
    ) external onlyGovernor {
        require(!ohmMigrated, "Already migrated");
        ohmMigrated = true;
        shutdown = false;

        require(_newTreasury != address(0), "Zero address: Treasury");
        newTreasury = ITreasury(_newTreasury);
        require(_newStaking != address(0), "Zero address: Staking");
        newStaking = IStaking(_newStaking);
        require(_newOHM != address(0), "Zero address: OHM");
        newOHM = IERC20(_newOHM);

        oldSupply = oldOHM.totalSupply(); // log total supply at time of migration

        gOHM.migrate(_newStaking, _newsOHM); // change gOHM minter

        _migrateToken(_reserve, true); // will deposit tokens into new treasury so reserves can be accounted for

        _fund(oldsOHM.circulatingSupply()); // fund with current staked supply for token migration

        emit Migrated(_newStaking, _newTreasury);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    // fund contract with gOHM
    function _fund(uint256 _amount) internal {
        newTreasury.mint(address(this), _amount);
        newOHM.approve(address(newStaking), _amount);
        newStaking.stake(address(this), _amount, false, true); // stake and claim gOHM

        emit Funded(_amount);
    }

    /**
     *   @notice Migrate token from old treasury to new treasury
     */
    function _migrateToken(address token, bool deposit) internal {
        uint256 balance = IERC20(token).balanceOf(address(oldTreasury));

        uint256 excessReserves = oldTreasury.excessReserves();
        uint256 tokenValue = oldTreasury.valueOf(token, balance);

        if (tokenValue > excessReserves) {
            tokenValue = excessReserves;
            balance = excessReserves * 10**9;
        }

        oldTreasury.manage(token, balance);

        if (deposit) {
            IERC20(token).safeApprove(address(newTreasury), balance);
            newTreasury.deposit(balance, token, tokenValue);
        } else {
            IERC20(token).safeTransfer(address(newTreasury), balance);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

// Old wsOHM interface
interface IwsOHM is IERC20 {
    function wrap(uint256 _amount) external returns (uint256);

    function unwrap(uint256 _amount) external returns (uint256);

    function wOHMTosOHM(uint256 _amount) external view returns (uint256);

    function sOHMTowOHM(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IStakingV1 {
    function unstake(uint256 _amount, bool _trigger) external;

    function index() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasuryV1 {
    function withdraw(uint256 amount, address token) external;

    function manage(address token, uint256 amount) external;

    function valueOf(address token, uint256 amount) external view returns (uint256);

    function excessReserves() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./libraries/Address.sol";
import "./libraries/SafeMath.sol";

import "./types/ERC20Permit.sol";

import "./interfaces/IgOHM.sol";
import "./interfaces/IsOHM.sol";
import "./interfaces/IStaking.sol";

contract sOlympus is IsOHM, ERC20Permit {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;

    /* ========== EVENTS ========== */

    event LogSupply(uint256 indexed epoch, uint256 totalSupply);
    event LogRebase(uint256 indexed epoch, uint256 rebase, uint256 index);
    event LogStakingContractUpdated(address stakingContract);

    /* ========== MODIFIERS ========== */

    modifier onlyStakingContract() {
        require(msg.sender == stakingContract, "StakingContract:  call is not staking contract");
        _;
    }

    /* ========== DATA STRUCTURES ========== */

    struct Rebase {
        uint256 epoch;
        uint256 rebase; // 18 decimals
        uint256 totalStakedBefore;
        uint256 totalStakedAfter;
        uint256 amountRebased;
        uint256 index;
        uint256 blockNumberOccured;
    }

    /* ========== STATE VARIABLES ========== */

    address internal initializer;

    uint256 internal INDEX; // Index Gons - tracks rebase growth

    address public stakingContract; // balance used to calc rebase
    IgOHM public gOHM; // additional staked supply (governance token)

    Rebase[] public rebases; // past rebase data

    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 150_000_000 * 10**9;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0); // (2^128) - 1

    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping(address => mapping(address => uint256)) private _allowedValue;

    address public treasury;
    mapping(address => uint256) public override debtBalances;

    /* ========== CONSTRUCTOR ========== */

    constructor() ERC20("Staked Hydranet", "sHDX", 9) ERC20Permit("Staked Hydranet") {
        initializer = msg.sender;
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
    }

    /* ========== INITIALIZATION ========== */

    function setIndex(uint256 _index) external {
        require(msg.sender == initializer, "Initializer:  caller is not initializer");
        require(INDEX == 0, "Cannot set INDEX again");
        INDEX = gonsForBalance(_index);
    }

    function setgOHM(address _gOHM) external {
        require(msg.sender == initializer, "Initializer:  caller is not initializer");
        require(address(gOHM) == address(0), "gOHM:  gOHM already set");
        require(_gOHM != address(0), "gOHM:  gOHM is not a valid contract");
        gOHM = IgOHM(_gOHM);
    }

    // do this last
    function initialize(address _stakingContract, address _treasury) external {
        require(msg.sender == initializer, "Initializer:  caller is not initializer");

        require(_stakingContract != address(0), "Staking");
        stakingContract = _stakingContract;
        _gonBalances[stakingContract] = TOTAL_GONS;

        require(_treasury != address(0), "Zero address: Treasury");
        treasury = _treasury;

        emit Transfer(address(0x0), stakingContract, _totalSupply);
        emit LogStakingContractUpdated(stakingContract);

        initializer = address(0);
    }

    /* ========== REBASE ========== */

    /**
        @notice increases rOHM supply to increase staking balances relative to profit_
        @param profit_ uint256
        @return uint256
     */
    function rebase(uint256 profit_, uint256 epoch_) public override onlyStakingContract returns (uint256) {
        uint256 rebaseAmount;
        uint256 circulatingSupply_ = circulatingSupply();
        if (profit_ == 0) {
            emit LogSupply(epoch_, _totalSupply);
            emit LogRebase(epoch_, 0, index());
            return _totalSupply;
        } else if (circulatingSupply_ > 0) {
            rebaseAmount = profit_.mul(_totalSupply).div(circulatingSupply_);
        } else {
            rebaseAmount = profit_;
        }

        _totalSupply = _totalSupply.add(rebaseAmount);

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        _storeRebase(circulatingSupply_, profit_, epoch_);

        return _totalSupply;
    }

    /**
        @notice emits event with data about rebase
        @param previousCirculating_ uint
        @param profit_ uint
        @param epoch_ uint
     */
    function _storeRebase(
        uint256 previousCirculating_,
        uint256 profit_,
        uint256 epoch_
    ) internal {
        uint256 rebasePercent = profit_.mul(1e18).div(previousCirculating_);
        rebases.push(
            Rebase({
                epoch: epoch_,
                rebase: rebasePercent, // 18 decimals
                totalStakedBefore: previousCirculating_,
                totalStakedAfter: circulatingSupply(),
                amountRebased: profit_,
                index: index(),
                blockNumberOccured: block.number
            })
        );

        emit LogSupply(epoch_, _totalSupply);
        emit LogRebase(epoch_, rebasePercent, index());
    }

    /* ========== MUTATIVE FUNCTIONS =========== */

    function transfer(address to, uint256 value) public override(IERC20, ERC20) returns (bool) {
        uint256 gonValue = value.mul(_gonsPerFragment);

        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);

        require(balanceOf(msg.sender) >= debtBalances[msg.sender], "Debt: cannot transfer amount");
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override(IERC20, ERC20) returns (bool) {
        _allowedValue[from][msg.sender] = _allowedValue[from][msg.sender].sub(value);
        emit Approval(from, msg.sender, _allowedValue[from][msg.sender]);

        uint256 gonValue = gonsForBalance(value);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);

        require(balanceOf(from) >= debtBalances[from], "Debt: cannot transfer amount");
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public override(IERC20, ERC20) returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _approve(msg.sender, spender, _allowedValue[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 oldValue = _allowedValue[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _approve(msg.sender, spender, 0);
        } else {
            _approve(msg.sender, spender, oldValue.sub(subtractedValue));
        }
        return true;
    }

    // this function is called by the treasury, and informs sOHM of changes to debt.
    // note that addresses with debt balances cannot transfer collateralized sOHM
    // until the debt has been repaid.
    function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external override {
        require(msg.sender == treasury, "Only treasury");
        if (add) {
            debtBalances[debtor] = debtBalances[debtor].add(amount);
        } else {
            debtBalances[debtor] = debtBalances[debtor].sub(amount);
        }
        require(debtBalances[debtor] <= balanceOf(debtor), "sOHM: insufficient balance");
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual override {
        _allowedValue[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function balanceOf(address who) public view override(IERC20, ERC20) returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function gonsForBalance(uint256 amount) public view override returns (uint256) {
        return amount.mul(_gonsPerFragment);
    }

    function balanceForGons(uint256 gons) public view override returns (uint256) {
        return gons.div(_gonsPerFragment);
    }

    // toG converts an sOHM balance to gOHM terms. gOHM is an 18 decimal token. balance given is in 18 decimal format.
    function toG(uint256 amount) external view override returns (uint256) {
        return gOHM.balanceTo(amount);
    }

    // fromG converts a gOHM balance to sOHM terms. sOHM is a 9 decimal token. balance given is in 9 decimal format.
    function fromG(uint256 amount) external view override returns (uint256) {
        return gOHM.balanceFrom(amount);
    }

    // Staking contract holds excess sOHM
    function circulatingSupply() public view override returns (uint256) {
        return
            _totalSupply.sub(balanceOf(stakingContract)).add(gOHM.balanceFrom(IERC20(address(gOHM)).totalSupply())).add(
                IStaking(stakingContract).supplyInWarmup()
            );
    }

    function index() public view override returns (uint256) {
        return balanceForGons(INDEX);
    }

    function allowance(address owner_, address spender) public view override(IERC20, ERC20) returns (uint256) {
        return _allowedValue[owner_][spender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;

import "../interfaces/IERC20Permit.sol";
import "./ERC20.sol";
import "../cryptography/EIP712.sol";
import "../cryptography/ECDSA.sol";
import "../libraries/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as th xe allowance of `spender` over ``owner``'s tokens,
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "../libraries/SafeMath.sol";

import "../interfaces/IERC20.sol";

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal immutable _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = chainID;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        if (chainID == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        return keccak256(abi.encode(typeHash, nameHash, versionHash, chainID, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./SafeMath.sol";

library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../libraries/SafeMath.sol";
import "../libraries/Address.sol";

import "../interfaces/IsOHM.sol";
import "../interfaces/IgOHM.sol";
import "../types/ERC20.sol";

contract gOHM is IgOHM, ERC20 {
    /* ========== DEPENDENCIES ========== */

    using Address for address;
    using SafeMath for uint256;

    /* ========== MODIFIERS ========== */

    modifier onlyApproved() {
        require(msg.sender == approved, "Only approved");
        _;
    }

    /* ========== EVENTS ========== */

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /* ========== DATA STRUCTURES ========== */

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }

    /* ========== STATE VARIABLES ========== */

    IsOHM public sOHM;
    address public approved; // minter
    bool public migrated;

    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;
    mapping(address => uint256) public numCheckpoints;
    mapping(address => address) public delegates;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _migrator, address _sOHM) ERC20("Governance HDX", "gHDX", 18) {
        require(_migrator != address(0), "Zero address: Migrator");
        approved = _migrator;
        require(_sOHM != address(0), "Zero address: sOHM");
        sOHM = IsOHM(_sOHM);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice transfer mint rights from migrator to staking
     * @notice can only be done once, at the time of contract migration
     * @param _staking address
     * @param _sOHM address
     */
    function migrate(address _staking, address _sOHM) external override onlyApproved {
        require(!migrated, "Migrated");
        migrated = true;

        require(_staking != approved, "Invalid argument");
        require(_staking != address(0), "Zero address found");
        approved = _staking;

        require(_sOHM != address(0), "Zero address found");
        sOHM = IsOHM(_sOHM);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
        @notice mint gOHM
        @param _to address
        @param _amount uint
     */
    function mint(address _to, uint256 _amount) external override onlyApproved {
        _mint(_to, _amount);
    }

    /**
        @notice burn gOHM
        @param _from address
        @param _amount uint
     */
    function burn(address _from, uint256 _amount) external override onlyApproved {
        _burn(_from, _amount);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice pull index from sOHM token
     */
    function index() public view override returns (uint256) {
        return sOHM.index();
    }

    /**
        @notice converts gOHM amount to OHM
        @param _amount uint
        @return uint
     */
    function balanceFrom(uint256 _amount) public view override returns (uint256) {
        return _amount.mul(index()).div(10**decimals());
    }

    /**
        @notice converts OHM amount to gOHM
        @param _amount uint
        @return uint
     */
    function balanceTo(uint256 _amount) public view override returns (uint256) {
        return _amount.mul(10**decimals()).div(index());
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint256 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
        require(blockNumber < block.number, "gOHM::getPriorVotes: not yet determined");

        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = _balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == block.number) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(block.number, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /**
        @notice Ensure delegation moves when token is transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _moveDelegates(delegates[from], delegates[to], amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./libraries/SafeMath.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IOHM.sol";
import "./interfaces/IERC20Permit.sol";

import "./types/ERC20Permit.sol";
import "./types/OlympusAccessControlled.sol";

contract OlympusERC20Token is ERC20Permit, IOHM, OlympusAccessControlled {
    using SafeMath for uint256;

    constructor(address _authority)
        ERC20("Hydranet", "HDX", 9)
        ERC20Permit("Hydranet")
        OlympusAccessControlled(IOlympusAuthority(_authority))
    {}

    function mint(address account_, uint256 amount_) external override onlyVault {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external override {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(
            amount_,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
import "../libraries/Address.sol";
import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IAllocator.sol";

import "../types/Ownable.sol";

interface IMasterChef {
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;
}

interface ISushiBar {
    function enter(uint256 _amount) external;

    function leave(uint256 _share) external;
}

/**
 *  Contract deploys liquidity from treasury into the Onsen program,
 *  earning $SUSHI that can be staked and/or deposited into the treasury.
 */
contract OnsenAllocator is Ownable {
    /* ========== DEPENDENCIES ========== */

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    uint256[] public pids; // Pool IDs
    mapping(uint256 => address) public pools; // Pool Addresses index by PID

    address immutable sushi; // $SUSHI token
    address immutable xSushi; // $xSUSHI token

    address immutable masterChef; // Onsen contract

    address immutable treasury; // Olympus Treasury

    uint256 public totalValueDeployed; // Total RFV deployed

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _chef,
        address _treasury,
        address _sushi,
        address _xSushi
    ) {
        require(_chef != address(0));
        masterChef = _chef;
        require(_treasury != address(0));
        treasury = _treasury;
        require(_sushi != address(0));
        sushi = _sushi;
        require(_xSushi != address(0));
        xSushi = _xSushi;
    }

    /* ========== OPEN FUNCTIONS ========== */

    /**
     * @notice harvest Onsen rewards from all pools
     * @param _stake bool
     */
    function harvest(bool _stake) external {
        for (uint256 i = 0; i < pids.length; i++) {
            uint256 pid = pids[i];
            if (pid != 0) {
                // pid of 0 is invalid
                IMasterChef(masterChef).withdraw(pid, 0); // withdrawing 0 harvests rewards
            }
        }
        enterSushiBar(_stake);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice stake sushi rewards if enter is true. return funds to treasury.
     * @param _stake bool
     */
    function enterSushiBar(bool _stake) internal {
        uint256 balance = IERC20(sushi).balanceOf(address(this));
        if (balance > 0) {
            if (!_stake) {
                IERC20(sushi).safeTransfer(treasury, balance); // transfer sushi to treasury
            } else {
                IERC20(sushi).approve(xSushi, balance);
                ISushiBar(xSushi).enter(balance); // stake sushi

                uint256 xBalance = IERC20(xSushi).balanceOf(address(this));
                IERC20(xSushi).safeTransfer(treasury, xBalance); // transfer xSushi to treasury
            }
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     *  @notice pending $SUSHI rewards
     *  @return uint
     */
    function pendingSushi() external view returns (uint256) {
        uint256 pending;
        for (uint256 i = 0; i < pids.length; i++) {
            uint256 pid = pids[i];
            if (pid != 0) {
                pending = pending.add(IMasterChef(masterChef).pendingSushi(pid, address(this)));
            }
        }
        return pending;
    }

    /* ========== POLICY FUNCTIONS ========== */

    /**
     * @notice deposit LP from treasury to Onsen and collect rewards
     * @param _amount uint
     * @param _stake bool
     */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external onlyOwner {
        address LP = pools[_pid];
        require(LP != address(0));

        ITreasury(treasury).manage(LP, _amount); // retrieve LP from treasury

        IERC20(LP).approve(masterChef, _amount);
        IMasterChef(masterChef).deposit(_pid, _amount); // deposit into Onsen

        uint256 value = ITreasury(treasury).tokenValue(LP, _amount);
        totalValueDeployed = totalValueDeployed.add(value); // add to deployed value tracker

        enterSushiBar(_stake); // manage rewards
    }

    /**
     * @notice collect rewards and withdraw LP from Onsen and return to treasury.
     * @param _amount uint
     * @param _stake bool
     */
    function withdraw(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external onlyOwner {
        address LP = pools[_pid];
        require(LP != address(0));

        IMasterChef(masterChef).withdraw(_pid, _amount); // withdraw from Onsen

        uint256 value = ITreasury(treasury).tokenValue(LP, _amount);
        // remove from deployed value tracker
        if (value < totalValueDeployed) {
            totalValueDeployed = totalValueDeployed.sub(value);
        } else {
            // LP value grows from fees and may exceed total deployed
            totalValueDeployed = 0;
        }

        // approve and deposit LP into treasury
        IERC20(LP).approve(treasury, _amount);
        // use value for profit so that no OHM is minted
        ITreasury(treasury).deposit(_amount, LP, value);

        enterSushiBar(_stake); // manage rewards
    }

    /**
     * @notice withdraw Sushi from treasury and stake to xSushi
     * @param _amount uint
     */
    function enterSushiBarFromTreasury(uint256 _amount) external onlyOwner {
        ITreasury(treasury).manage(sushi, _amount); // retrieve $SUSHI from treasury

        enterSushiBar(true); // stake $SUSHI
    }

    /**
     * @notice withdraw xSushi from treasury and unstake to sushi
     * @param _amount uint
     */
    function exitSushiBar(uint256 _amount) external onlyOwner {
        ITreasury(treasury).manage(xSushi, _amount); // retrieve $xSUSHI from treasury

        ISushiBar(xSushi).leave(_amount); // unstake $xSUSHI

        IERC20(sushi).safeTransfer(treasury, IERC20(sushi).balanceOf(address(this))); // return $SUSHI to treasury
    }

    /**
     *  @notice add new PID and corresponding liquidity pool
     *  @param _pool address
     *  @param _pid uint
     */
    function addPool(address _pool, uint256 _pid) external onlyOwner {
        require(_pool != address(0));
        require(pools[_pid] == address(0));

        pids.push(_pid);
        pools[_pid] = _pool;
    }

    /**
     *  @notice remove liquidity pool and corresponding PID
     *  @param _pool address
     *  @param _index uint
     */
    function removePool(address _pool, uint256 _index) external onlyOwner {
        uint256 pid = pids[_index];
        require(pools[pid] == _pool);

        pids[_index] = 0;
        pools[pid] = address(0);
    }

    /**
     *  @notice withdraw liquidity without regard for rewards
     *  @param _pid uint
     */
    function emergencyWithdraw(uint256 _pid) external onlyOwner {
        address LP = pools[_pid];

        IMasterChef(masterChef).emergencyWithdraw(_pid); // withdraws LP without returning rewards

        uint256 balance = IERC20(LP).balanceOf(address(this));
        uint256 value = ITreasury(treasury).tokenValue(LP, balance);
        if (value < totalValueDeployed) {
            totalValueDeployed = totalValueDeployed.sub(value); // remove from value deployed tracker
        } else {
            // value increases with fees and would otherwise cause underflow
            totalValueDeployed = 0;
        }

        // approve and deposit LP into treasury
        IERC20(LP).approve(treasury, balance);
        // use value for profit so that no OHM is minted
        ITreasury(treasury).deposit(balance, LP, value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface IAllocator {
    // Should have deposit/withdraw methods (interfaces aren't standardized)
    function harvest() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "../interfaces/IAllocator.sol";

import "../types/Ownable.sol";

interface IOnsenAllocator {
    function harvest(bool _stake) external;
}

// @notice contract will claim rewards from multiple allocators in one function call
contract RewardHarvester is Ownable {
    /* ======== STATE VARIABLES ======== */

    address public immutable onsenAllocator;
    address[] public allocators;

    /* ======== CONSTRUCTOR ======== */

    constructor(address _onsenAllocator, address[] memory _allocators) {
        require(_onsenAllocator != address(0));
        onsenAllocator = _onsenAllocator;
        for (uint256 i; i < _allocators.length; i++) {
            require(_allocators[i] != address(0));
        }
        allocators = _allocators;
    }

    /* ======== PUBLIC FUNCTION ======== */

    /**
     *  @notice harvest rewards from allocators
     *  @param _useOnsen bool
     */
    function harvest(bool _useOnsen) external {
        for (uint256 i; i < allocators.length; i++) {
            IAllocator(allocators[i]).harvest();
        }
        if (_useOnsen) {
            IOnsenAllocator(onsenAllocator).harvest(true);
        }
    }

    /* ======== POLICY FUNCTION ======== */

    /**
     *  @notice update array of allocators
     *  @param _allocators address[]
     */
    function updateAllocator(address[] calldata _allocators) external onlyOwner {
        allocators = _allocators;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
import "../libraries/Address.sol";
import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IAllocator.sol";

import "../types/Ownable.sol";

interface IGroDepositHandler {
    // deposit DAI to Gro
    function depositPwrd(
        uint256[3] memory inAmounts,
        uint256 minAmount,
        address _referral
    ) external;
}

interface IGroWithdrawHandler {
    // withdraw DAI from Gro
    function withdrawAllSingle(
        bool pwrd,
        uint256 index,
        uint256 minAmount
    ) external;
}

/**
 *  Contract deploys reserves from treasury into the Gro
 */

contract GroDAIAllocator is Ownable {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ======== STATE VARIABLES ======== */

    IGroDepositHandler public immutable groDepositHandler; // GRO deposit handler
    IGroWithdrawHandler public immutable groWithdrawHandler; // GRO withdraw handler
    ITreasury public immutable treasury;

    address public immutable DAI;

    uint256 public totalValueDeployed; // total RFV deployed into lending pool
    uint256 public deployed;
    uint256 public limit;
    uint256 public newLimit;
    uint256 public limitChangeTimelockEnd;
    uint256 public immutable timelockInBlocks; // timelock to raise deployment limit

    /* ======== CONSTRUCTOR ======== */

    constructor(
        address _treasury,
        address _groDepositHandler,
        address _groWithdrawHandler,
        address _DAI,
        uint256 _timelockInBlocks,
        uint256 _limit
    ) {
        require(_treasury != address(0));
        treasury = ITreasury(_treasury);

        require(_groDepositHandler != address(0));
        groDepositHandler = IGroDepositHandler(_groDepositHandler);

        require(_groWithdrawHandler != address(0));
        groWithdrawHandler = IGroWithdrawHandler(_groWithdrawHandler);

        require(_DAI != address(0));
        DAI = _DAI;

        timelockInBlocks = _timelockInBlocks;

        limit = _limit;
    }

    /* ======== POLICY FUNCTIONS ======== */

    /**
     *  @notice withdraws asset from treasury, deposits asset into Gro
     *  @param amount uint
     *  @param minAmount uint
     */
    function deposit(uint256 amount, uint256 minAmount) public onlyOwner {
        require(!exceedsLimit(amount)); // ensure deposit is within bounds

        treasury.manage(DAI, amount); // retrieve amount of asset from treasury

        // account for deposit
        uint256 value = treasury.tokenValue(DAI, amount);
        accountingFor(amount, value, true);

        IERC20(DAI).approve(address(groDepositHandler), amount); // approve Gro deposit handler to spend tokens

        groDepositHandler.depositPwrd([amount, 0, 0], minAmount, address(0)); // deposit into Gro
    }

    /**
     *  @notice withdraws DAI from Gro, then deposits asset into treasury
     *  @param minAmount uint
     */
    function withdraw(uint256 minAmount) public onlyOwner {
        groWithdrawHandler.withdrawAllSingle(true, 0, minAmount); // withdraw from Gro

        uint256 balance = IERC20(DAI).balanceOf(address(this)); // balance of asset withdrawn

        // account for withdrawal
        uint256 value = treasury.tokenValue(DAI, balance);
        accountingFor(balance, value, false);

        IERC20(DAI).approve(address(treasury), balance); // approve to deposit asset into treasury
        treasury.deposit(balance, DAI, value); // deposit using value as profit so no OHM is minted
    }

    /**
     *  @notice lowers max can be deployed for asset (no timelock)
     *  @param newMax uint
     */
    function lowerLimit(uint256 newMax) external onlyOwner {
        require(newMax < limit);
        require(newMax > deployed); // cannot set limit below what has been deployed already
        limit = newMax;
    }

    /**
     *  @notice starts timelock to raise max allocation for asset
     *  @param newMax uint
     */
    function queueRaiseLimit(uint256 newMax) external onlyOwner {
        limitChangeTimelockEnd = block.number.add(timelockInBlocks);
        newLimit = newMax;
    }

    /**
     *  @notice changes max allocation for asset when timelock elapsed
     */
    function raiseLimit() external onlyOwner {
        require(block.number >= limitChangeTimelockEnd, "Timelock not expired");
        require(limitChangeTimelockEnd != 0, "Timelock not started");

        limit = newLimit;
        newLimit = 0;
        limitChangeTimelockEnd = 0;
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    /**
     *  @notice accounting of deposits/withdrawals of assets
     *  @param amount uint
     *  @param value uint
     *  @param add bool
     */
    function accountingFor(
        uint256 amount,
        uint256 value,
        bool add
    ) internal {
        if (add) {
            deployed = deployed.add(amount); // track amount allocated into pool

            totalValueDeployed = totalValueDeployed.add(value); // track total value allocated into pools
        } else {
            // track amount allocated into pool
            if (amount < deployed) {
                deployed = deployed.sub(amount);
            } else {
                deployed = 0;
            }

            // track total value allocated into pools
            if (value < totalValueDeployed) {
                totalValueDeployed = totalValueDeployed.sub(value);
            } else {
                totalValueDeployed = 0;
            }
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice checks to ensure deposit does not exceed max allocation for asset
     *  @param amount uint
     */
    function exceedsLimit(uint256 amount) public view returns (bool) {
        uint256 willBeDeployed = deployed.add(amount);

        return (willBeDeployed > limit);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "../interfaces/ITreasury.sol";
import "../interfaces/IAllocator.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

interface IveFXS is IERC20 {
    /**
     * @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
     * @param _value Amount to deposit
     * @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
     */
    function create_lock(uint256 _value, uint256 _unlock_time) external;

    /**
     * @notice Deposit `_value` additional tokens for `msg.sender` without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increase_amount(uint256 _value) external;

    /**
     * @notice Extend the unlock time for `msg.sender` to `_unlock_time`
     * @param _unlock_time New epoch time for unlocking
     */
    function increase_unlock_time(uint256 _unlock_time) external;

    /**
     * @notice Get timestamp when `_addr`'s lock finishes
     * @param _addr wallet address
     * @return Epoch time of the lock end
     */
    function locked__end(address _addr) external view returns (uint256);
}

interface IveFXSYieldDistributorV4 {
    /**
     * @notice transfers FXS earned by locking veFXS
     * @return the amount of FXS transferred
     */
    function getYield() external returns (uint256);

    /**
     * @notice returns the pending rewards for an address
     */
    function earned(address _address) external view returns (uint256);

    /* BELOW USED ONLY IN TESTS */

    /**
     * @notice forces an update of a user's rewards
     */
    function checkpointOtherUser(address _address) external;

    /**
     * @notice requests FXS rewards to pulled from msg.sender
     */
    function notifyRewardAmount(uint256 amount) external;

    /**
     * @notice allows an address to call notifyRewardAmount
     */
    function toggleRewardNotifier(address notifier_addr) external;

    /**
     * @notice returns the number of seconds until a reward is fully distributed
     */
    function yieldDuration() external returns (uint256);
}

contract FraxSharesAllocator is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMathUpgradeable for uint256;

    /* ======== STATE VARIABLES ======== */
    /* !!!! UPGRADABLE CONTRACT !!!! */
    /* NEW STATE VARIABLES MUST BE APPENDED TO END */

    uint256 private constant MAX_TIME = 4 * 365 * 86400 + 1; // 4 years and 1 second
    ITreasury public treasury;
    IERC20 public fxs; // $FXS token
    IveFXS public veFXS; // $veFXS token
    IveFXSYieldDistributorV4 public veFXSYieldDistributorV4;

    // uint256 public totalValueDeployed; // FXS isn't a reserve token, so will always be 0
    uint256 public totalAmountDeployed;
    uint256 public lockEnd; // tracks the expiry of veFXS to know if can be extended

    /* ======== INITIALIZER ======== */
    function initialize(
        address _treasury,
        address _fxs,
        address _veFXS,
        address _veFXSYieldDistributorV4
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        require(_treasury != address(0), "zero treasury address");
        treasury = ITreasury(_treasury);

        require(_fxs != address(0), "zero FXS address");
        fxs = IERC20(_fxs);

        require(_veFXS != address(0), "zero veFXS address");
        veFXS = IveFXS(_veFXS);

        require(_veFXSYieldDistributorV4 != address(0), "zero veFXSYieldDistributorV4 address");
        veFXSYieldDistributorV4 = IveFXSYieldDistributorV4(_veFXSYieldDistributorV4);

        totalAmountDeployed = 0;
    }

    /* ======== POLICY FUNCTIONS ======== */

    /**
     * @notice harvest FXS rewards, will relock all veFXS for the maximum amount of time (4 years)
     */
    function harvest() external {
        uint256 amount = veFXSYieldDistributorV4.getYield();

        if (amount > 0) {
            totalAmountDeployed = totalAmountDeployed.add(amount);

            fxs.safeApprove(address(veFXS), amount);
            veFXS.increase_amount(amount);
            if (_canExtendLock()) {
                lockEnd = block.timestamp + MAX_TIME;
                veFXS.increase_unlock_time(block.timestamp + MAX_TIME);
            }
        }
    }

    /**
     *  @notice withdraws FXS from treasury, locks as veFXS for maximum time (4 years).
     *  @param _amount uint
     */
    function deposit(uint256 _amount) external onlyOwner {
        treasury.manage(address(fxs), _amount);

        uint256 prevAmount = totalAmountDeployed;
        totalAmountDeployed = totalAmountDeployed.add(_amount);

        fxs.safeApprove(address(veFXS), _amount);
        if (prevAmount == 0) {
            lockEnd = block.timestamp + MAX_TIME;
            veFXS.create_lock(_amount, lockEnd);
        } else {
            veFXS.increase_amount(_amount);
            if (_canExtendLock()) {
                lockEnd = block.timestamp + MAX_TIME;
                veFXS.increase_unlock_time(block.timestamp + MAX_TIME);
            }
        }
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "zero treasury address");
        treasury = ITreasury(_treasury);
    }

    /* ======== VIEW FUNCTIONS ======== */

    function getPendingRewards() public view returns (uint256) {
        return veFXSYieldDistributorV4.earned(address(this));
    }

    function _canExtendLock() internal view returns (bool) {
        return lockEnd < block.timestamp + MAX_TIME - 7 * 86400;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/ITreasury.sol";
import "../interfaces/IERC20.sol";
import "./FraxSharesAllocator.sol";

/**
 * @notice this allows us to test proxy upgrades
 */
contract FraxSharesAllocatorVNext is Initializable, OwnableUpgradeable {
    /* ======== STATE VARIABLES ======== */
    /* !!!! UPGRADABLE CONTRACT !!!! */
    /* NEW STATE VARIABLES MUST BE APPENDED TO END */

    uint256 private constant MAX_TIME = 4 * 365 * 86400 + 1; // 4 years and 1 second
    ITreasury public treasury;
    IERC20 public fxs; // $FXS token
    IveFXS public veFXS; // $veFXS token
    IveFXSYieldDistributorV4 public veFXSYieldDistributorV4;

    // uint256 public totalValueDeployed; // FXS isn't a reserve token, so will always be 0
    uint256 public totalAmountDeployed;
    uint256 public lockEnd; // tracks the expiry of veFXS to know if can be extended

    function didUpgrade() external pure returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "../libraries/Address.sol";
import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IAllocator.sol";

import "../types/OlympusAccessControlled.sol";

interface ICurve3Pool {
    // add liquidity to Curve to receive back 3CRV tokens
    function add_liquidity(
        address _pool,
        uint256[4] memory _deposit_amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);

    // remove liquidity Curve liquidity to recieve back base token
    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);
}

//main Convex contract(booster.sol) basic interface
interface IConvex {
    //deposit into convex, receive a tokenized deposit.  parameter to stake immediately
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);
}

//sample convex reward contracts interface
interface IConvexRewards {
    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns (bool);

    //claim rewards
    function getReward() external returns (bool);

    //get rewards for an address
    function earned(address _account) external view returns (uint256);
}

/**
 *  Contract deploys reserves from treasury into the Convex lending pool,
 *  earning interest and $CVX.
 */

contract ConvexAllocator is OlympusAccessControlled {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ======== STRUCTS ======== */

    struct TokenData {
        address underlying;
        address curveToken;
        IConvexRewards rewardPool;
        address[] rewardTokens;
        int128 index;
        uint256 deployed;
        uint256 limit;
        uint256 newLimit;
        uint256 limitChangeTimelockEnd;
    }

    /* ======== STATE VARIABLES ======== */

    // Convex deposit contract
    IConvex internal immutable booster = IConvex(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    // Curve 3Pool
    ICurve3Pool internal immutable curve3Pool = ICurve3Pool(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
    // Olympus Treasury
    ITreasury internal treasury = ITreasury(0x9A315BdF513367C0377FB36545857d12e85813Ef);

    // info for deposited tokens
    mapping(address => TokenData) public tokenInfo;
    // convex pid for token
    mapping(address => uint256) public pidForReserve;
    // total RFV deployed into lending pool
    uint256 public totalValueDeployed;
    // timelock to raise deployment limit
    uint256 public immutable timelockInBlocks = 6600;

    /* ======== CONSTRUCTOR ======== */

    constructor(IOlympusAuthority _authority) OlympusAccessControlled(_authority) {}

    /* ======== OPEN FUNCTIONS ======== */

    /**
     * @notice claims accrued CVX rewards for all tracked crvTokens
     */
    function harvest(address[] memory tokens) external {
        for (uint256 i; i < tokens.length; i++) {
            TokenData memory tokenData = tokenInfo[tokens[i]];
            address[] memory rewardTokens = tokenData.rewardTokens;

            tokenData.rewardPool.getReward();

            for (uint256 r = 0; r < rewardTokens.length; r++) {
                uint256 balance = IERC20(rewardTokens[r]).balanceOf(address(this));

                if (balance > 0) {
                    IERC20(rewardTokens[r]).safeTransfer(address(treasury), balance);
                }
            }
        }
    }

    /* ======== POLICY FUNCTIONS ======== */

    function updateTreasury() external onlyGuardian {
        require(authority.vault() != address(0), "Zero address: Vault");
        require(address(authority.vault()) != address(treasury), "No change");
        treasury = ITreasury(authority.vault());
    }

    /**
     * @notice withdraws asset from treasury, deposits asset into lending pool, then deposits crvToken into convex
     */
    function deposit(
        address token,
        uint256 amount,
        uint256[4] calldata amounts,
        uint256 minAmount
    ) public onlyGuardian {
        require(!exceedsLimit(token, amount), "Exceeds deployment limit");
        address curveToken = tokenInfo[token].curveToken;

        // retrieve amount of asset from treasury
        treasury.manage(token, amount);

        // account for deposit
        uint256 value = treasury.tokenValue(token, amount);
        accountingFor(token, amount, value, true);

        // approve and deposit into curve
        IERC20(token).approve(address(curve3Pool), amount);
        uint256 curveAmount = curve3Pool.add_liquidity(curveToken, amounts, minAmount);

        // approve and deposit into convex
        IERC20(curveToken).approve(address(booster), curveAmount);
        booster.deposit(pidForReserve[token], curveAmount, true);
    }

    /**
     * @notice withdraws crvToken from convex, withdraws from lending pool, then deposits asset into treasury
     */
    function withdraw(
        address token,
        uint256 amount,
        uint256 minAmount,
        bool reserve
    ) public onlyGuardian {
        address curveToken = tokenInfo[token].curveToken;

        // withdraw from convex
        tokenInfo[token].rewardPool.withdrawAndUnwrap(amount, false);

        // approve and withdraw from curve
        IERC20(curveToken).approve(address(curve3Pool), amount);
        curve3Pool.remove_liquidity_one_coin(curveToken, amount, tokenInfo[token].index, minAmount);

        uint256 balance = IERC20(token).balanceOf(address(this));

        // account for withdrawal
        uint256 value = treasury.tokenValue(token, balance);
        accountingFor(token, balance, value, false);

        if (reserve) {
            // approve and deposit asset into treasury
            IERC20(token).approve(address(treasury), balance);
            treasury.deposit(balance, token, value);
        } else IERC20(token).safeTransfer(address(treasury), balance);
    }

    /**
     * @notice adds asset and corresponding crvToken to mapping
     */
    function addToken(
        address token,
        address curveToken,
        address rewardPool,
        address[] memory rewardTokens,
        int128 index,
        uint256 max,
        uint256 pid
    ) external onlyGuardian {
        require(token != address(0), "Zero address: Token");
        require(curveToken != address(0), "Zero address: Curve Token");
        require(tokenInfo[token].deployed == 0, "Token added");

        tokenInfo[token] = TokenData({
            underlying: token,
            curveToken: curveToken,
            rewardPool: IConvexRewards(rewardPool),
            rewardTokens: rewardTokens,
            index: index,
            deployed: 0,
            limit: max,
            newLimit: 0,
            limitChangeTimelockEnd: 0
        });

        pidForReserve[token] = pid;
    }

    /**
     * @notice add new reward token to be harvested
     */
    function addRewardTokens(address baseToken, address[] memory rewardTokens) external onlyGuardian {
        tokenInfo[baseToken].rewardTokens = rewardTokens;
    }

    /**
     * @notice lowers max can be deployed for asset (no timelock)
     */
    function lowerLimit(address token, uint256 newMax) external onlyGuardian {
        require(newMax < tokenInfo[token].limit, "Must be lower");
        require(newMax > tokenInfo[token].deployed, "Greater than deployed");
        tokenInfo[token].limit = newMax;
    }

    /**
     * @notice starts timelock to raise max allocation for asset
     */
    function queueRaiseLimit(address token, uint256 newMax) external onlyGuardian {
        tokenInfo[token].limitChangeTimelockEnd = block.number.add(timelockInBlocks);
        tokenInfo[token].newLimit = newMax;
    }

    /**
     * @notice changes max allocation for asset when timelock elapsed
     */
    function raiseLimit(address token) external onlyGuardian {
        require(block.number >= tokenInfo[token].limitChangeTimelockEnd, "Timelock not expired");
        require(tokenInfo[token].limitChangeTimelockEnd != 0, "Timelock not started");

        tokenInfo[token].limit = tokenInfo[token].newLimit;
        tokenInfo[token].newLimit = 0;
        tokenInfo[token].limitChangeTimelockEnd = 0;
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    /**
     * @notice accounting of deposits/withdrawals of assets
     */
    function accountingFor(
        address token,
        uint256 amount,
        uint256 value,
        bool add
    ) internal {
        if (add) {
            tokenInfo[token].deployed = tokenInfo[token].deployed.add(amount); // track amount allocated into pool
            totalValueDeployed = totalValueDeployed.add(value); // track total value allocated into pools
        } else {
            // track amount allocated into pool
            if (amount < tokenInfo[token].deployed) {
                tokenInfo[token].deployed = tokenInfo[token].deployed.sub(amount);
            } else tokenInfo[token].deployed = 0;

            // track total value allocated into pools
            if (value < totalValueDeployed) {
                totalValueDeployed = totalValueDeployed.sub(value);
            } else totalValueDeployed = 0;
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     * @notice query all pending rewards for a specific base token
     */
    function rewardsPending(address baseToken) external view returns (uint256) {
        return tokenInfo[baseToken].rewardPool.earned(address(this));
    }

    /**
     * @notice checks to ensure deposit does not exceed max allocation for asset
     */
    function exceedsLimit(address token, uint256 amount) public view returns (bool) {
        uint256 willBeDeployed = tokenInfo[token].deployed.add(amount);
        return (willBeDeployed > tokenInfo[token].limit);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IOlympusAuthority.sol";
import "../types/OlympusAccessControlled.sol";
import "../interfaces/ITreasury.sol";

interface IMigrator {
    enum TYPE {
        UNSTAKED,
        STAKED,
        WRAPPED
    }

    // migrate OHMv1, sOHMv1, or wsOHM for OHMv2, sOHMv2, or gOHM
    function migrate(
        uint256 _amount,
        TYPE _from,
        TYPE _to
    ) external;
}

contract LiquidityMigrator is OlympusAccessControlled {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ITreasury internal immutable oldTreasury = ITreasury(0x31F8Cc382c9898b273eff4e0b7626a6987C846E8);
    ITreasury internal immutable newTreasury = ITreasury(0x9A315BdF513367C0377FB36545857d12e85813Ef);
    IERC20 internal immutable oldOHM = IERC20(0x383518188C0C6d7730D91b2c03a03C837814a899);
    IERC20 internal immutable newOHM = IERC20(0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5);
    IMigrator internal immutable migrator = IMigrator(0x184f3FAd8618a6F458C16bae63F70C426fE784B3);

    constructor(IOlympusAuthority _authority) OlympusAccessControlled(_authority) {}

    /**
     * @notice Migrate LP and pair with new OHM
     */
    function migrateLP(
        address pair,
        IUniswapV2Router routerFrom,
        IUniswapV2Router routerTo,
        address token,
        uint256 _minA,
        uint256 _minB,
        uint256 _deadline
    ) external onlyGovernor {
        // Since we are adding liquidity, any existing balance should be excluded
        uint256 initialNewOHMBalance = newOHM.balanceOf(address(this));
        // Fetch the treasury balance of the given liquidity pair
        uint256 oldLPAmount = IERC20(pair).balanceOf(address(oldTreasury));
        oldTreasury.manage(pair, oldLPAmount);

        // Remove the V1 liquidity
        IERC20(pair).approve(address(routerFrom), oldLPAmount);
        (uint256 amountToken, uint256 amountOHM) = routerFrom.removeLiquidity(
            token,
            address(oldOHM),
            oldLPAmount,
            _minA,
            _minB,
            address(this),
            _deadline
        );

        // Migrate the V1 OHM to V2 OHM
        oldOHM.approve(address(migrator), amountOHM);
        migrator.migrate(amountOHM, IMigrator.TYPE.UNSTAKED, IMigrator.TYPE.UNSTAKED);
        uint256 amountNewOHM = newOHM.balanceOf(address(this)).sub(initialNewOHMBalance); // # V1 out != # V2 in

        // Add the V2 liquidity
        IERC20(token).approve(address(routerTo), amountToken);
        newOHM.approve(address(routerTo), amountNewOHM);
        routerTo.addLiquidity(
            token,
            address(newOHM),
            amountToken,
            amountNewOHM,
            amountToken,
            amountNewOHM,
            address(newTreasury),
            _deadline
        );

        // Send any leftover balance to the governor
        newOHM.safeTransfer(authority.governor(), newOHM.balanceOf(address(this)));
        oldOHM.safeTransfer(authority.governor(), oldOHM.balanceOf(address(this)));
        IERC20(token).safeTransfer(authority.governor(), IERC20(token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import "../interfaces/IERC20.sol";
import "../interfaces/IOwnable.sol";
import "../types/Ownable.sol";
import "../libraries/SafeERC20.sol";

contract CrossChainMigrator is Ownable {
    using SafeERC20 for IERC20;

    IERC20 internal immutable wsOHM; // v1 token
    IERC20 internal immutable gOHM; // v2 token

    constructor(address _wsOHM, address _gOHM) {
        require(_wsOHM != address(0), "Zero address: wsOHM");
        wsOHM = IERC20(_wsOHM);
        require(_gOHM != address(0), "Zero address: gOHM");
        gOHM = IERC20(_gOHM);
    }

    // migrate wsOHM to gOHM - 1:1 like kind
    function migrate(uint256 amount) external {
        wsOHM.safeTransferFrom(msg.sender, address(this), amount);
        gOHM.safeTransfer(msg.sender, amount);
    }

    // withdraw wsOHM so it can be bridged on ETH and returned as more gOHM
    function replenish() external onlyOwner {
        wsOHM.safeTransfer(msg.sender, wsOHM.balanceOf(address(this)));
    }

    // withdraw migrated wsOHM and unmigrated gOHM
    function clear() external onlyOwner {
        wsOHM.safeTransfer(msg.sender, wsOHM.balanceOf(address(this)));
        gOHM.safeTransfer(msg.sender, gOHM.balanceOf(address(this)));
    }
}

/**
 *Submitted for verification at Etherscan.io on 2021-06-12
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../interfaces/IERC20.sol";

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
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
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

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
        // solhint-disable-next-line max-line-length
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
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
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IsOHMOLD {
    function INDEX() external view returns (uint256);
}

contract wOHM is ERC20 {
    using SafeERC20 for ERC20;
    using Address for address;
    using SafeMath for uint256;

    address public immutable sOHM;

    constructor(address _sOHM) ERC20("Wrapped sOHM", "wsOHM") {
        require(_sOHM != address(0));
        sOHM = _sOHM;
    }

    /**
        @notice wrap sOHM
        @param _amount uint
        @return uint
     */
    function wrap(uint256 _amount) external returns (uint256) {
        IERC20(sOHM).transferFrom(msg.sender, address(this), _amount);

        uint256 value = sOHMTowOHM(_amount);
        _mint(msg.sender, value);
        return value;
    }

    /**
        @notice unwrap sOHM
        @param _amount uint
        @return uint
     */
    function unwrap(uint256 _amount) external returns (uint256) {
        _burn(msg.sender, _amount);

        uint256 value = wOHMTosOHM(_amount);
        IERC20(sOHM).transfer(msg.sender, value);
        return value;
    }

    /**
        @notice converts wOHM amount to sOHM
        @param _amount uint
        @return uint
     */
    function wOHMTosOHM(uint256 _amount) public view returns (uint256) {
        return _amount.mul(IsOHMOLD(sOHM).INDEX()).div(10**decimals());
    }

    /**
        @notice converts sOHM amount to wOHM
        @param _amount uint
        @return uint
     */
    function sOHMTowOHM(uint256 _amount) public view returns (uint256) {
        return _amount.mul(10**decimals()).div(IsOHMOLD(sOHM).INDEX());
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.5;

import "../types/OlympusAccessControlled.sol";

contract AccessControlledMock is OlympusAccessControlled {
    constructor(address _auth) OlympusAccessControlled(IOlympusAuthority(_auth)) {}

    bool public governorOnlyTest;

    bool public guardianOnlyTest;

    bool public policyOnlyTest;

    bool public vaultOnlyTest;

    function governorTest() external onlyGovernor returns (bool) {
        governorOnlyTest = true;
        return governorOnlyTest;
    }

    function guardianTest() external onlyGuardian returns (bool) {
        guardianOnlyTest = true;
        return guardianOnlyTest;
    }

    function policyTest() external onlyPolicy returns (bool) {
        policyOnlyTest = true;
        return policyOnlyTest;
    }

    function vaultTest() external onlyVault returns (bool) {
        governorOnlyTest = true;
        return governorOnlyTest;
    }
}