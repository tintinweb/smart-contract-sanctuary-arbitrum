// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import "./interfaces/IAuthority.sol";

import "./libraries/AccessControl.sol";

/**
 *  @title Contract used as the source of truth for all protocol authority and access control, based off of OlympusDao Access Control
 */
contract Authority is IAuthority, AccessControl {
	/* ========== STATE VARIABLES ========== */

	address public override governor;

	mapping(address => bool) public override guardian;

	address public override manager;

	address public newGovernor;

	address public newManager;

	/* ========== Constructor ========== */

	constructor(
		address _governor,
		address _guardian,
		address _manager
	) AccessControl(IAuthority(address(this))) {
		governor = _governor;
		emit GovernorPushed(address(0), governor, true);
		guardian[_guardian] = true;
		emit GuardianPushed(_guardian, true);
		manager = _manager;
		emit ManagerPushed(address(0), manager, true);
	}

	/* ========== GOV ONLY ========== */

	function pushGovernor(address _newGovernor, bool _effectiveImmediately) external {
		_onlyGovernor();
		if (_effectiveImmediately) governor = _newGovernor;
		newGovernor = _newGovernor;
		emit GovernorPushed(governor, newGovernor, _effectiveImmediately);
	}

	function pushGuardian(address _newGuardian) external {
		_onlyGovernor();
		guardian[_newGuardian] = true;
	}

	function pushManager(address _newManager, bool _effectiveImmediately) external {
		_onlyGovernor();
		if (_effectiveImmediately) manager = _newManager;
		newManager = _newManager;
		emit ManagerPushed(manager, newManager, _effectiveImmediately);
	}

	function pullGovernor() external {
		require(msg.sender == newGovernor, "!newGovernor");
		emit GovernorPulled(governor, newGovernor);
		governor = newGovernor;
	}

	function revokeGuardian(address _guardian) external {
		_onlyGovernor();
		emit GuardianPulled(_guardian);
		guardian[_guardian] = false;
	}

	function pullManager() external {
		require(msg.sender == newManager, "!newManager");
		emit ManagerPulled(manager, newManager);
		manager = newManager;
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IAuthority {
	/* ========== EVENTS ========== */

	event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
	event GuardianPushed(address indexed to, bool _effectiveImmediately);
	event ManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);

	event GovernorPulled(address indexed from, address indexed to);
	event GuardianPulled(address indexed to);
	event ManagerPulled(address indexed from, address indexed to);

	/* ========== VIEW ========== */

	function governor() external view returns (address);

	function guardian(address _target) external view returns (bool);

	function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IAuthority.sol";

error UNAUTHORIZED();
error AUTHORITY_INITIALIZED();

/**
 *  @title Contract used for access control functionality, based off of OlympusDao Access Control
 */
abstract contract AccessControl {
	/* ========== EVENTS ========== */

	event AuthorityUpdated(IAuthority authority);

	/* ========== STATE VARIABLES ========== */

	IAuthority public authority;

	/* ========== Constructor ========== */

	constructor(IAuthority _authority) {
		authority = _authority;
		emit AuthorityUpdated(_authority);
	}

	/* ========== GOV ONLY ========== */

	function setAuthority(IAuthority _newAuthority) external {
		_onlyGovernor();
		authority = _newAuthority;
		emit AuthorityUpdated(_newAuthority);
	}

	/* ========== INTERNAL CHECKS ========== */

	function _onlyGovernor() internal view {
		if (msg.sender != authority.governor()) revert UNAUTHORIZED();
	}

	function _onlyGuardian() internal view {
		if (!authority.guardian(msg.sender) && msg.sender != authority.governor()) revert UNAUTHORIZED();
	}

	function _onlyManager() internal view {
		if (msg.sender != authority.manager() && msg.sender != authority.governor())
			revert UNAUTHORIZED();
	}
}