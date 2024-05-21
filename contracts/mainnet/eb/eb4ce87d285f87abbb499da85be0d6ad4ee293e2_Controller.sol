// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IController} from "./interfaces/IController.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {IVault} from "./interfaces/IVault.sol";
import {IMultiFeeDistribution} from "./interfaces/IMultiFeeDistribution.sol";
import {ILimePoints} from "./interfaces/ILimePoints.sol"; 
import {IUpgradeSource} from "./interfaces/IUpgradeSource.sol";
import {Errors, _require} from "./lib/Errors.sol";
import {Governable} from "./lib/Governable.sol";
import {SafeTransferLib} from "./lib/SafeTransferLib.sol";

/// @title Limestone Controller
/// @author Chainvisions
/// @notice Controller contract for Beluga vaults.

contract Controller is IController, Governable {
    using SafeTransferLib for IERC20;
    using Address for address;

    /// @notice Context enum for minter updates.
    enum MinterUpdate {
        Add,
        Remove
    }

    /// @notice Data structure for storing referral info.
    struct UserReferralInfo {
        address referrer;
        string referralCode;
    }

    /// @notice Whitelist for smart contract interactions.
    mapping(address => bool) public override whitelist;

    /// @notice Addresses exempt from deposit maturity and the exit fee. 
    mapping(address => bool) public override feeExemptAddresses;

    /// @notice Addresses that can perform sensitive operations with Controller funds.
    mapping(address => bool) public override keepers;

    /// @notice Addresses that are permitted to mint new tokens.
    mapping(address => bool) public pointsMinters;

    /// @notice Timestamp of the last harvest on a specific strategy.
    mapping(address => uint256) public lastHarvestTimestamp;

    /// @notice Mint distributor contract for minting protocol tokens.
    ILimePoints public override limeToken;

    /// @notice Owner of a specific referral code.
    mapping(string => address) public override referralCode;

    /// @notice Referrer for a specific user.
    mapping(address => address) public override referrer;

    /// @notice Whether or not an anti-sybil attestation already exists.
    mapping(bytes32 => bool) public attestationExists;
    
    /// @notice Referral info for a user.
    mapping(address => UserReferralInfo) public referralInfo;

    /// @notice Fee for registering a referral code.
    uint256 public registrationFee = 0.01 ether;

    /// @notice Numerator for referral rewards.
    uint256 public referralRateNumerator = 150;

    /// @notice Numerator for performance fees charged by the protocol.
    uint256 public override profitSharingNumerator = 1000; // 10%

    /// @notice Precision for protocol performance fees.
    uint256 public override profitSharingDenominator = 10000; // 1e4 as precision, allowing fees to be as low as 0.01%.

    /// @notice Emitted on a successful doHardWork.
    event SharePriceChangeLog(
        address indexed vault,
        address indexed strategy,
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 timestamp
    );

    /// @notice Emitted when points are minted to a user.
    /// @param user User that points were minted to.
    /// @param referrer User that referred `user`.
    /// @param pointsAmount Amount of points minted.
    event PointsMinted(
        address indexed user,
        address indexed referrer, 
        uint256 pointsAmount
    );

    /// @notice Emitted on a failed doHardWork on `batchDoHardWork()` calls.
    event FailedHarvest(address indexed vault);

    /// @notice Emitted on a successful rebalance on a vault.
    event VaultRebalance(address indexed vault);

    /// @notice Emitted on a failed rebalance on `batchRebalance()` calls.
    event FailedRebalance(address indexed vault);

    modifier onlyKeeper {
        require(
            msg.sender == governance() 
            || keepers[msg.sender],
            "Controller: Caller not Governance or Keeper"
        );
        _;
    }

    /// @notice Controller constructor.
    /// @param _store Storage address for access control.
    constructor(address _store, ILimePoints _limeToken) Governable(_store) {
        feeExemptAddresses[governance()] = true; // Exempt governance.
        limeToken = _limeToken;
    }

    /// @notice Mints and vests Limestone tokens for ``_user``.
    /// @param _user User to receive tokens.
    /// @param _amount Amount of tokens to be minted.
    function mintTokens(
        address _user, 
        uint256 _amount
    ) external override {
        require(pointsMinters[msg.sender], "Controller: Caller not minter");
        ILimePoints _limeToken = limeToken;
        UserReferralInfo memory refInfo = referralInfo[_user];

        // Mint referral rewards if there are any available.
        if(refInfo.referrer != address(0)) {
            _limeToken.mint(refInfo.referrer, (_amount * referralRateNumerator) / 10000);
        }

        // Mint points to user and devshare.
        _limeToken.mint(_user, _amount);
        _limeToken.mint(governance(), (_amount * 500) / 10000);

        emit PointsMinted(_user, refInfo.referrer, _amount);
    }

    /// @notice Collects `_token` that is in the Controller.
    /// @param _token Token to salvage from the contract.
    /// @param _amount Amount of `_token` to salvage.
    function salvage(
        address _token,
        uint256 _amount
    ) external override onlyGovernance {
        IERC20(_token).safeTransfer(governance(), _amount);
    }

    /// @notice Creates a new referral code.
    /// @param _attestation Anti-sybil attestation. Generated by an algo on the frontend.
    /// @param code Referral code to set for the user.
    function createReferralCode(
        bytes32 _attestation,
        string memory code
    ) external payable override {
        _require(msg.value >= registrationFee, Errors.INSUFFICIENT_ETHER_AMOUNT);
        _require(attestationExists[_attestation] == false, Errors.ANTI_SYBIL_ATTESTATION_EXISTS);
        _require(referralCode[code] == address(0), Errors.REFERRAL_CODE_ALREADY_EXISTS);

        referralCode[code] = msg.sender;
        attestationExists[_attestation] = true;
        UserReferralInfo storage _referralInfo = referralInfo[msg.sender];
        _referralInfo.referralCode = code;

        // Distribute fee.
        Address.sendValue(payable(governance()), msg.value);
    }

    /// @notice Registers a referral address for a user.
    /// @param _referralCode Referral code used.
    /// @param _referee User who has been referred.
    function registerReferral(
        string memory _referralCode,
        address _referee
    ) external {
        _require(tx.origin == _referee, Errors.CALLER_NOT_REFEREE);
        UserReferralInfo memory _referralInfo = referralInfo[_referee];

        // Prevent abuse.
        address _referrer = referralCode[_referralCode];
        if(_referrer == _referee) {
            _referrer = governance();
        }

        _referralInfo.referrer = _referrer;
        referralInfo[_referee] = _referralInfo;
    }

    /// @notice Fetches the last harvest on a specific vault.
    /// @return Timestamp of the vault's most recent harvest.
    function fetchLastHarvestForVault(address _vault) external view returns (uint256) {
        return lastHarvestTimestamp[IVault(_vault).strategy()];
    }

    /// @notice Updates the permitted minters for LIME points.
    /// @param _ctx Context for updating minters. Derived from enum MinterUpdate.
    /// @param _minters Minters to update.
    function updateMinters(
        MinterUpdate _ctx, 
        address[] memory _minters
    ) public onlyGovernance {
        if(_ctx == MinterUpdate.Add) {
            for(uint256 i; i < _minters.length;) {
                pointsMinters[_minters[i]] = true;
                unchecked { ++i; }
            }
        } else {
            for(uint256 i; i < _minters.length;) {
                pointsMinters[_minters[i]] = false;
                unchecked { ++i; }
            }
        }
    }

    /// @notice Updates the fee for registering ref codes.
    /// @param _regFee New registration fee.
    function setRegistrationFee(
        uint256 _regFee
    ) external onlyGovernance {
        registrationFee = _regFee;
    }

    /// @notice Sets the referral rate for ref codes.
    /// @param _refRate New referral rate.
    function setReferralRate(
        uint256 _refRate
    ) external onlyGovernance {
        referralRateNumerator = _refRate;
    }

    /// @notice Salvages tokens from the specified strategy.
    /// @param _strategy Address of the strategy to salvage from.
    /// @param _token Token to salvage from `_strategy`.
    /// @param _amount Amount of `_token` to salvage from `_strategy`.
    function salvageStrategy(
        address _strategy,
        address _token,
        uint256 _amount
    ) public override onlyGovernance {
        IStrategy(_strategy).salvage(governance(), _token, _amount);
    }

    /// @notice Performs doHardWork on a desired vault.
    /// @param _vault Address of the vault to doHardWork on.
    function doHardWork(address _vault) public override {
        uint256 prevSharePrice = IVault(_vault).getPricePerFullShare();
        IVault(_vault).doHardWork();
        uint256 sharePriceAfter = IVault(_vault).getPricePerFullShare();
        emit SharePriceChangeLog(
            _vault,
            IVault(_vault).strategy(),
            prevSharePrice,
            sharePriceAfter,
            block.timestamp
        );
    }

    /// @notice Performs doHardWork on vaults in batches.
    /// @param _vaults Array of vaults to doHardWork on.
    function batchDoHardWork(address[] memory _vaults) public override {
        for(uint256 i; i < _vaults.length;) {
            uint256 prevSharePrice = IVault(_vaults[i]).getPricePerFullShare();
            // We use the try/catch pattern to allow us to spot an issue in one of our vaults
            // while still being able to harvest the rest.
            try IVault(_vaults[i]).doHardWork() {
                uint256 sharePriceAfter = IVault(_vaults[i]).getPricePerFullShare();
                emit SharePriceChangeLog(
                    _vaults[i],
                    IVault(_vaults[i]).strategy(),
                    prevSharePrice,
                    sharePriceAfter,
                    block.timestamp
                );
            } catch {
                emit FailedHarvest(_vaults[i]);
            }

            unchecked { ++i; }
        }
    }

    /// @notice Silently performs a doHardWork (does not emit any events).
    function silentDoHardWork(address _vault) public {
        IVault(_vault).doHardWork();
    }

    /// @notice Rebalances on a desired vault.
    /// @param _vault Vault to rebalance on.
    function rebalance(address _vault) public onlyGovernance {
        IVault(_vault).rebalance();
        emit VaultRebalance(_vault);
    }

    /// @notice Performs rebalances on vaults in batches
    /// @param _vaults Array of vaults to rebalance on.
    function batchRebalance(address[] memory _vaults) public onlyGovernance {
        for(uint256 i = 0; i < _vaults.length; i++) {
            try IVault(_vaults[i]).rebalance() {
                emit VaultRebalance(_vaults[i]);
            } catch {
                emit FailedRebalance(_vaults[i]);
            }
        }
    }

    /// @notice Queues an upgrade on a list of Beluga vaults.
    /// @param _implementation New implementation of the vault contracts.
    /// @param _vaults Vaults to schedule the upgrade for.
    function batchQueueVaultUpgrades(
        address _implementation,
        address[] memory _vaults
    ) public onlyGovernance {
        for(uint256 i; i < _vaults.length;) {
            (bool success, ) = _vaults[i].call(abi.encodeWithSignature("scheduleUpgrade(address)", _implementation));
            require(success, "Scheduling upgrade failed");
            unchecked { ++i; }
        }
    }

    /// @notice Withdraws all funds from the desired vault's strategy to the vault.
    /// @param _vault Vault to withdraw all funds in the strategy from.
    function withdrawAll(address _vault) public onlyGovernance {
        IVault(_vault).withdrawAll();
    }

    /// @notice Adds a contract to the whitelist.
    /// @param _whitelistedAddress Address of the contract to whitelist.
    function addToWhitelist(address _whitelistedAddress) public onlyGovernance {
        whitelist[_whitelistedAddress] = true;
    }

    /// @notice Removes a contract from the whitelist.
    /// @param _whitelistedAddress Address of the contract to remove.
    function removeFromWhitelist(address _whitelistedAddress) public onlyGovernance {
        whitelist[_whitelistedAddress] = false;
    }

    /// @notice Exempts an address from deposit maturity and exit fees.
    /// @param _feeExemptedAddress Address to exempt from fees.
    function addFeeExemptAddress(address _feeExemptedAddress) public onlyGovernance {
        feeExemptAddresses[_feeExemptedAddress] = true;
    }

    /// @notice Removes an address from fee exemption
    /// @param _feeExemptedAddress Address to remove from fee exemption.
    function removeFeeExemptAddress(address _feeExemptedAddress) public onlyGovernance {
        feeExemptAddresses[_feeExemptedAddress] = false;
    }

    /// @notice Adds a list of addresses to the whitelist.
    /// @param _toWhitelist Addresses to whitelist.
    function batchWhitelist(address[] memory _toWhitelist) public onlyGovernance {
        for(uint256 i = 0; i < _toWhitelist.length; i++) {
            whitelist[_toWhitelist[i]] = true;
        }
    }

    /// @notice Exempts a list of addresses from Beluga exit penalties.
    /// @param _toExempt Addresses to exempt.
    function batchExempt(address[] memory _toExempt) public onlyGovernance {
        for(uint256 i = 0; i < _toExempt.length; i++) {
            feeExemptAddresses[_toExempt[i]] = true;
        }
    }

    /// @notice Sets the numerator for protocol performance fees.
    /// @param _profitSharingNumerator New numerator for fees.
    function setProfitSharingNumerator(uint256 _profitSharingNumerator) public onlyGovernance {
        profitSharingNumerator = _profitSharingNumerator;
    }

    /// @notice Sets the precision for protocol performance fees.
    /// @param _profitSharingDenominator Precision for fees.
    function setProfitSharingDenominator(uint256 _profitSharingDenominator) public onlyGovernance {
        profitSharingDenominator = _profitSharingDenominator;
    }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ILimePoints} from "./ILimePoints.sol"; 

interface IController {
    function whitelist(address) external view returns (bool);
    function feeExemptAddresses(address) external view returns (bool);
    function keepers(address) external view returns (bool);
    function referralCode(string memory) external view returns (address);
    function referrer(address) external view returns (address);
    function referralInfo(address) external view returns (address, string memory);

    function doHardWork(address) external;
    function batchDoHardWork(address[] memory) external;

    function salvage(address, uint256) external;
    function salvageStrategy(address, address, uint256) external;

    function mintTokens(address, uint256) external;
    function createReferralCode(bytes32, string memory) external payable;
    function registerReferral(string memory, address) external;

    function limeToken() external view returns (ILimePoints);
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IStrategy {
    function unsalvagableTokens(address tokens) external view returns (bool);
    
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()
    function pendingYield() external view returns (uint256[] memory);

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address) external;
    function setVaultFractionToInvest(uint256) external;

    function deposit(uint256) external;
    function depositFor(address, uint256) external;

    function withdrawAll() external;
    function withdraw(uint256) external;

    function getReward() external;
    function getRewardByToken(address) external;
    function notifyRewardAmount(address, uint256) external;

    function underlyingUnit() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
    function underlyingBalanceWithInvestmentForHolder(address) external view returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
    function rebalance() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMultiFeeDistribution {
    function notifyRewardAmount(address, uint256) external;
    function mint(address, uint256) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILimePoints {
    function mint(address, uint256) external;
    function burn(uint256) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUpgradeSource {
  function finalizeUpgrade() external;
  function shouldUpgrade() external view returns (bool, address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BEL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BEL#" part is a known constant
        // (0x42454C23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42454C23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}


/// @title Beluga Errors Library
/// @author Chainvisions
/// @author Forked and modified from Balancer (https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/helpers/BalancerErrors.sol)
/// @notice Library for efficiently handling errors on Beluga contracts with reduced bytecode size additions.

library Errors {
    // Vault
    uint256 internal constant NUMERATOR_ABOVE_MAX_BUFFER = 0;
    uint256 internal constant UNDEFINED_STRATEGY = 1;
    uint256 internal constant CALLER_NOT_WHITELISTED = 2;
    uint256 internal constant VAULT_HAS_NO_SHARES = 3;
    uint256 internal constant SHARES_MUST_NOT_BE_ZERO = 4;
    uint256 internal constant LOSSES_ON_DOHARDWORK = 5;
    uint256 internal constant CANNOT_UPDATE_STRATEGY = 6;
    uint256 internal constant NEW_STRATEGY_CANNOT_BE_EMPTY = 7;
    uint256 internal constant VAULT_AND_STRATEGY_UNDERLYING_MUST_MATCH = 8;
    uint256 internal constant STRATEGY_DOES_NOT_BELONG_TO_VAULT = 9;
    uint256 internal constant CALLER_NOT_GOV_OR_REWARD_DIST = 10;
    uint256 internal constant NOTIF_AMOUNT_INVOKES_OVERFLOW = 11;
    uint256 internal constant REWARD_INDICE_NOT_FOUND = 12;
    uint256 internal constant REWARD_TOKEN_ALREADY_EXIST = 13;
    uint256 internal constant DURATION_CANNOT_BE_ZERO = 14;
    uint256 internal constant REWARD_TOKEN_DOES_NOT_EXIST = 15;
    uint256 internal constant REWARD_PERIOD_HAS_NOT_ENDED = 16;
    uint256 internal constant CANNOT_REMOVE_LAST_REWARD_TOKEN = 17;
    uint256 internal constant DENOMINATOR_MUST_BE_GTE_NUMERATOR = 18;
    uint256 internal constant CANNOT_UPDATE_EXIT_FEE = 19;
    uint256 internal constant CANNOT_TRANSFER_IMMATURE_TOKENS = 20;
    uint256 internal constant CANNOT_DEPOSIT_ZERO = 21;
    uint256 internal constant HOLDER_MUST_BE_DEFINED = 22;

    // VeManager
    uint256 internal constant GOVERNORS_ONLY = 23;
    uint256 internal constant CALLER_NOT_STRATEGY = 24;
    uint256 internal constant GAUGE_INFO_ALREADY_EXISTS = 25;
    uint256 internal constant GAUGE_NON_EXISTENT = 26;

    // Strategies
    uint256 internal constant CALL_RESTRICTED = 27;
    uint256 internal constant STRATEGY_IN_EMERGENCY_STATE = 28;
    uint256 internal constant REWARD_POOL_UNDERLYING_MISMATCH = 29;
    uint256 internal constant UNSALVAGABLE_TOKEN = 30;

    // Strategy splitter.
    uint256 internal constant ARRAY_LENGTHS_DO_NOT_MATCH = 31;
    uint256 internal constant WEIGHTS_DO_NOT_ADD_UP = 32;
    uint256 internal constant REBALANCE_REQUIRED = 33;
    uint256 internal constant INDICE_DOES_NOT_EXIST = 34;

    // Controller
    uint256 internal constant CALLER_NOT_REFEREE = 35;
    uint256 internal constant REFERRAL_CODE_ALREADY_EXISTS = 36;
    uint256 internal constant INSUFFICIENT_ETHER_AMOUNT = 37;
    uint256 internal constant ANTI_SYBIL_ATTESTATION_EXISTS = 38;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Storage.sol";

/**
 * @dev Contract for access control where the governance address specified
 * in the Storage contract can be granted access to specific functions
 * on a contract that inherits this contract.
 */

contract Governable {

  Storage public store;

  constructor(address _store) {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Governable: Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {

  address public governance;
  address public controller;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Storage: Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "Storage: New governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "Storage: New controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}