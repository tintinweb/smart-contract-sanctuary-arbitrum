// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "../../../security-council-mgmt/interfaces/IGnosisSafe.sol";
import "../../address-registries/L2AddressRegistryInterfaces.sol";
import "./SecurityCouncilMgmtUpgradeLib.sol";
import "../../../interfaces/IArbitrumDAOConstitution.sol";
import "../../../interfaces/IUpgradeExecutor.sol";
import "../../../interfaces/ICoreTimelock.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract GovernanceChainSCMgmtActivationAction {
    IGnosisSafe public immutable newEmergencySecurityCouncil;
    IGnosisSafe public immutable newNonEmergencySecurityCouncil;

    IGnosisSafe public immutable prevEmergencySecurityCouncil;
    IGnosisSafe public immutable prevNonEmergencySecurityCouncil;

    uint256 public immutable emergencySecurityCouncilThreshold;
    uint256 public immutable nonEmergencySecurityCouncilThreshold;

    address public immutable securityCouncilManager;
    IL2AddressRegistry public immutable l2AddressRegistry;

    bytes32 public constant newConstitutionHash = 0x60acde40ad14f4ecdb1bea0704d1e3889264fb029231c9016352c670703b35d6;

    constructor(
        IGnosisSafe _newEmergencySecurityCouncil,
        IGnosisSafe _newNonEmergencySecurityCouncil,
        IGnosisSafe _prevEmergencySecurityCouncil,
        IGnosisSafe _prevNonEmergencySecurityCouncil,
        uint256 _emergencySecurityCouncilThreshold,
        uint256 _nonEmergencySecurityCouncilThreshold,
        address _securityCouncilManager,
        IL2AddressRegistry _l2AddressRegistry
    ) {
        newEmergencySecurityCouncil = _newEmergencySecurityCouncil;
        newNonEmergencySecurityCouncil = _newNonEmergencySecurityCouncil;

        prevEmergencySecurityCouncil = _prevEmergencySecurityCouncil;
        prevNonEmergencySecurityCouncil = _prevNonEmergencySecurityCouncil;

        emergencySecurityCouncilThreshold = _emergencySecurityCouncilThreshold;
        nonEmergencySecurityCouncilThreshold = _nonEmergencySecurityCouncilThreshold;

        securityCouncilManager = _securityCouncilManager;
        l2AddressRegistry = _l2AddressRegistry;
    }

    function perform() external {
        IUpgradeExecutor upgradeExecutor = IUpgradeExecutor(l2AddressRegistry.coreGov().owner());

        // swap in new emergency security council
        SecurityCouncilMgmtUpgradeLib.replaceEmergencySecurityCouncil({
            _prevSecurityCouncil: prevEmergencySecurityCouncil,
            _newSecurityCouncil: newEmergencySecurityCouncil,
            _threshold: emergencySecurityCouncilThreshold,
            _upgradeExecutor: upgradeExecutor
        });

        // swap in new nonEmergency security council
        SecurityCouncilMgmtUpgradeLib.requireSafesEquivalent(
            prevNonEmergencySecurityCouncil,
            newNonEmergencySecurityCouncil,
            nonEmergencySecurityCouncilThreshold
        );

        ICoreTimelock l2CoreGovTimelock =
            ICoreTimelock(address(l2AddressRegistry.coreGovTimelock()));

        bytes32 TIMELOCK_PROPOSAL_ROLE = l2CoreGovTimelock.PROPOSER_ROLE();
        bytes32 TIMELOCK_CANCELLER_ROLE = l2CoreGovTimelock.CANCELLER_ROLE();

        require(
            l2CoreGovTimelock.hasRole(
                TIMELOCK_PROPOSAL_ROLE, address(prevNonEmergencySecurityCouncil)
            ),
            "GovernanceChainSCMgmtActivationAction: prev nonemergency council doesn't have proposal role"
        );
        require(
            !l2CoreGovTimelock.hasRole(
                TIMELOCK_PROPOSAL_ROLE, address(newNonEmergencySecurityCouncil)
            ),
            "GovernanceChainSCMgmtActivationAction: new nonemergency council already has proposal role"
        );

        l2CoreGovTimelock.revokeRole(
            TIMELOCK_PROPOSAL_ROLE, address(prevNonEmergencySecurityCouncil)
        );

        l2CoreGovTimelock.grantRole(TIMELOCK_PROPOSAL_ROLE, address(newNonEmergencySecurityCouncil));

        // give timelock access to manager
        require(
            Address.isContract(securityCouncilManager),
            "GovernanceChainSCMgmtActivationAction: manager address isn't a contract"
        );

        require(
            !l2CoreGovTimelock.hasRole(TIMELOCK_PROPOSAL_ROLE, securityCouncilManager),
            "GovernanceChainSCMgmtActivationAction: securityCouncilManager already has proposal role"
        );
        l2CoreGovTimelock.grantRole(TIMELOCK_PROPOSAL_ROLE, securityCouncilManager);

        // revoke old security council cancel role; it is unnecessary to grant it to explicitly grant it to new security council since the security council can already cancel via the core governor's relay method.
        require(
            l2CoreGovTimelock.hasRole(
                TIMELOCK_CANCELLER_ROLE, address(prevEmergencySecurityCouncil)
            ),
            "GovernanceChainSCMgmtActivationAction: prev emergency security council should have cancellor role"
        );

        l2CoreGovTimelock.revokeRole(TIMELOCK_CANCELLER_ROLE, address(prevEmergencySecurityCouncil));

        // confirm updates
        bytes32 EXECUTOR_ROLE = upgradeExecutor.EXECUTOR_ROLE();
        require(
            upgradeExecutor.hasRole(EXECUTOR_ROLE, address(newEmergencySecurityCouncil)),
            "NonGovernanceChainSCMgmtActivationAction: new emergency security council not set"
        );
        require(
            !upgradeExecutor.hasRole(EXECUTOR_ROLE, address(prevEmergencySecurityCouncil)),
            "NonGovernanceChainSCMgmtActivationAction: prev emergency security council still set"
        );

        require(
            !l2CoreGovTimelock.hasRole(
                TIMELOCK_PROPOSAL_ROLE, address(prevNonEmergencySecurityCouncil)
            ),
            "GovernanceChainSCMgmtActivationAction: prev nonemergency council still has proposal role"
        );
        require(
            l2CoreGovTimelock.hasRole(
                TIMELOCK_PROPOSAL_ROLE, address(newNonEmergencySecurityCouncil)
            ),
            "GovernanceChainSCMgmtActivationAction: new nonemergency doesn't have proposal role"
        );

        require(
            l2CoreGovTimelock.hasRole(TIMELOCK_PROPOSAL_ROLE, securityCouncilManager),
            "GovernanceChainSCMgmtActivationAction: securityCouncilManager doesn't have proposal role"
        );
        require(
            !l2CoreGovTimelock.hasRole(
                TIMELOCK_CANCELLER_ROLE, address(prevEmergencySecurityCouncil)
            ),
            "GovernanceChainSCMgmtActivationAction: prev emergency security council still has cancellor role"
        );
        IArbitrumDAOConstitution arbitrumDaoConstitution =
            l2AddressRegistry.arbitrumDAOConstitution();
        arbitrumDaoConstitution.setConstitutionHash(newConstitutionHash);
        require(
            arbitrumDaoConstitution.constitutionHash() == newConstitutionHash,
            "GovernanceChainSCMgmtActivationAction: new constitution hash not set"
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

abstract contract OpEnum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface IGnosisSafe {
    function getOwners() external view returns (address[] memory);
    function getThreshold() external view returns (uint256);
    function isOwner(address owner) external view returns (bool);
    function isModuleEnabled(address module) external view returns (bool);
    function addOwnerWithThreshold(address owner, uint256 threshold) external;
    function removeOwner(address prevOwner, address owner, uint256 threshold) external;
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        OpEnum.Operation operation
    ) external returns (bool success);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../interfaces/IArbitrumTimelock.sol";
import "../../interfaces/IFixedDelegateErc20Wallet.sol";
import "../../interfaces/IL2ArbitrumToken.sol";
import "../../interfaces/IL2ArbitrumGovernor.sol";
import "../../interfaces/IArbitrumDAOConstitution.sol";

interface ICoreGovTimelockGetter {
    function coreGovTimelock() external view returns (IArbitrumTimelock);
}

interface ICoreGovGetter {
    function coreGov() external view returns (IL2ArbitrumGoverner);
}

interface ITreasuryGovTimelockGetter {
    function treasuryGovTimelock() external view returns (IArbitrumTimelock);
}

interface ITreasuryGovGetter {
    function treasuryGov() external view returns (IL2ArbitrumGoverner);
}

interface IDaoTreasuryGetter {
    function treasuryWallet() external view returns (IFixedDelegateErc20Wallet);
}

interface IL2ArbitrumTokenGetter {
    function l2ArbitrumToken() external view returns (IL2ArbitrumToken);
}

interface IArbitrumDAOConstitutionGetter {
    function arbitrumDAOConstitution() external view returns (IArbitrumDAOConstitution);
}

interface IL2AddressRegistry is
    ICoreGovGetter,
    ICoreGovTimelockGetter,
    ITreasuryGovTimelockGetter,
    IDaoTreasuryGetter,
    ITreasuryGovGetter,
    IL2ArbitrumTokenGetter,
    IArbitrumDAOConstitutionGetter
{}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "../../../security-council-mgmt/interfaces/IGnosisSafe.sol";
import "../../../interfaces/IUpgradeExecutor.sol";

library SecurityCouncilMgmtUpgradeLib {
    function replaceEmergencySecurityCouncil(
        IGnosisSafe _prevSecurityCouncil,
        IGnosisSafe _newSecurityCouncil,
        uint256 _threshold,
        IUpgradeExecutor _upgradeExecutor
    ) internal {
        requireSafesEquivalent(_prevSecurityCouncil, _newSecurityCouncil, _threshold);
        bytes32 EXECUTOR_ROLE = _upgradeExecutor.EXECUTOR_ROLE();
        require(
            _upgradeExecutor.hasRole(EXECUTOR_ROLE, address(_prevSecurityCouncil)),
            "SecurityCouncilMgmtUpgradeLib: prev council not executor"
        );
        require(
            !_upgradeExecutor.hasRole(EXECUTOR_ROLE, address(_newSecurityCouncil)),
            "SecurityCouncilMgmtUpgradeLib: new council already executor"
        );

        _upgradeExecutor.revokeRole(EXECUTOR_ROLE, address(_prevSecurityCouncil));
        _upgradeExecutor.grantRole(EXECUTOR_ROLE, address(_newSecurityCouncil));
    }

    function requireSafesEquivalent(
        IGnosisSafe _safe1,
        IGnosisSafe safe2,
        uint256 _expectedThreshold
    ) internal view {
        uint256 newSecurityCouncilThreshold = safe2.getThreshold();
        require(
            _safe1.getThreshold() == newSecurityCouncilThreshold,
            "SecurityCouncilMgmtUpgradeLib: threshold mismatch"
        );
        require(
            newSecurityCouncilThreshold == _expectedThreshold,
            "SecurityCouncilMgmtUpgradeLib: unexpected threshold"
        );

        address[] memory prevOwners = _safe1.getOwners();
        address[] memory newOwners = safe2.getOwners();
        require(
            areUniqueAddressArraysEqual(prevOwners, newOwners),
            "SecurityCouncilMgmtUpgradeLib: owners mismatch"
        );
    }

    /// @notice assumes each address array has no repeated elements (i.e., as is the enforced for gnosis safe owners)
    function areUniqueAddressArraysEqual(address[] memory array1, address[] memory array2)
        public
        pure
        returns (bool)
    {
        if (array1.length != array2.length) {
            return false;
        }

        for (uint256 i = 0; i < array1.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < array2.length; j++) {
                if (array1[i] == array2[j]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                return false;
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

interface IArbitrumDAOConstitution {
    function constitutionHash() external view returns (bytes32);
    function setConstitutionHash(bytes32 _constitutionHash) external;
    function owner() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IUpgradeExecutor is IAccessControlUpgradeable {
    function execute(address upgrade, bytes memory upgradeCallData) external;
    function ADMIN_ROLE() external returns (bytes32);
    function EXECUTOR_ROLE() external returns (bytes32);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "./IArbitrumTimelock.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface ICoreTimelock is IArbitrumTimelock, IAccessControlUpgradeable {
    function TIMELOCK_ADMIN_ROLE() external returns (bytes32);
    function PROPOSER_ROLE() external returns (bytes32);
    function EXECUTOR_ROLE() external returns (bytes32);
    function CANCELLER_ROLE() external returns (bytes32);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

interface IArbitrumTimelock {
    function cancel(bytes32 id) external;
    function scheduleBatch(
        address[] calldata target,
        uint256[] calldata payloads,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) external;
    function getMinDelay() external view returns (uint256 duration);
    function updateDelay(uint256 newDelay) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

interface IFixedDelegateErc20Wallet {
    function transfer(address _token, address _to, uint256 _amount) external returns (bool);
    function owner() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";

interface IL2ArbitrumToken is IERC20Upgradeable, IVotesUpgradeable {
    function mint(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "./IL2ArbitrumToken.sol";

interface IL2ArbitrumGoverner {
    // token() is inherited from GovernorVotesUpgradeable
    function token() external view returns (IL2ArbitrumToken);
    function relay(address target, uint256 value, bytes calldata data) external;
    function timelock() external view returns (address);
    function votingDelay() external view returns (uint256);
    function setVotingDelay(uint256 newVotingDelay) external;
    function votingPeriod() external view returns (uint256);
    function setVotingPeriod(uint256 newVotingPeriod) external;
    function EXCLUDE_ADDRESS() external view returns (address);
    function owner() external view returns (address);
    function proposalThreshold() external view returns (uint256);
    function setProposalThreshold(uint256 newProposalThreshold) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}