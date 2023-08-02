// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "../address-registries/L2AddressRegistry.sol";

/// @notice Governance action for constitution update relevant to security council elections, prior to their actual activation. See https://forum.arbitrum.foundation/t/proposal-update-security-council-election-start-date-to-ensure-time-for-security-audit/15426
contract AIP4Action {
    IL2AddressRegistry public immutable l2GovAddressRegistry;

    bytes32 public constant newConstitutionHash =
        0x2498ca4a737c2d06c43799b5ddf5183b6e169359f68bea4b34775751528a2ee1;

    constructor(IL2AddressRegistry _l2GovAddressRegistry) {
        l2GovAddressRegistry = _l2GovAddressRegistry;
    }

    /// @notice set new constitution hash
    function perform() external {
        require(newConstitutionHash != bytes32(0x0), "AIP4Action: 0 constitution hash");

        IArbitrumDAOConstitution arbitrumDaoConstitution =
            l2GovAddressRegistry.arbitrumDAOConstitution();
        arbitrumDaoConstitution.setConstitutionHash(newConstitutionHash);

        require(
            arbitrumDaoConstitution.constitutionHash() == newConstitutionHash,
            "AIP4Action: new constitution hash not set"
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "./L2AddressRegistryInterfaces.sol";

contract L2AddressRegistry is IL2AddressRegistry {
    IL2ArbitrumGoverner public immutable coreGov;
    IL2ArbitrumGoverner public immutable treasuryGov;
    IFixedDelegateErc20Wallet public immutable treasuryWallet;
    IArbitrumDAOConstitution public immutable arbitrumDAOConstitution;

    constructor(
        IL2ArbitrumGoverner _coreGov,
        IL2ArbitrumGoverner _treasuryGov,
        IFixedDelegateErc20Wallet _treasuryWallet,
        IArbitrumDAOConstitution _arbitrumDAOConstitution
    ) {
        require(
            _treasuryWallet.owner() == _treasuryGov.timelock(),
            "L2AddressRegistry: treasury gov timelock must own treasuryWallet"
        );
        require(
            _arbitrumDAOConstitution.owner() == _coreGov.owner(),
            "L2AddressRegistry DAO must own ArbitrumDAOConstitution"
        );
        coreGov = _coreGov;
        treasuryGov = _treasuryGov;
        treasuryWallet = _treasuryWallet;
        arbitrumDAOConstitution = _arbitrumDAOConstitution;
    }

    function coreGovTimelock() external view returns (IArbitrumTimelock) {
        return IArbitrumTimelock(coreGov.timelock());
    }

    function treasuryGovTimelock() external view returns (IArbitrumTimelock) {
        return IArbitrumTimelock(treasuryGov.timelock());
    }

    function l2ArbitrumToken() external view returns (IL2ArbitrumToken) {
        return IL2ArbitrumGoverner(address(coreGov)).token();
    }
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

interface IArbitrumDAOConstitution {
    function constitutionHash() external view returns (bytes32);
    function setConstitutionHash(bytes32 _constitutionHash) external;
    function owner() external view returns (address);
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