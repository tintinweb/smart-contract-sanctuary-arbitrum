// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IAuthority {
	/* ========== EVENTS ========== */

	event GovernorPushed(address indexed from, address indexed to);
	event GuardianPushed(address indexed to);
	event ManagerPushed(address indexed from, address indexed to);

	event GovernorPulled(address indexed from, address indexed to);
	event GuardianRevoked(address indexed to);
	event ManagerPulled(address indexed from, address indexed to);

	/* ========== VIEW ========== */

	function governor() external view returns (address);

	function guardian(address _target) external view returns (bool);

	function manager() external view returns (address);

	function pullManager() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IAuthority.sol";

error UNAUTHORIZED();

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./libraries/AccessControl.sol";

/**
 *  @title Contract used for storage of important contracts for the liquidity pool
 */
contract Protocol is AccessControl {
	////////////////////////
	/// static variables ///
	////////////////////////

	address public immutable optionRegistry;

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	address public volatilityFeed;
	address public portfolioValuesFeed;
	address public accounting;
	address public priceFeed;

	constructor(
		address _optionRegistry,
		address _priceFeed,
		address _volatilityFeed,
		address _portfolioValuesFeed,
		address _authority
	) AccessControl(IAuthority(_authority)) {
		optionRegistry = _optionRegistry;
		priceFeed = _priceFeed;
		volatilityFeed = _volatilityFeed;
		portfolioValuesFeed = _portfolioValuesFeed;
	}

	///////////////
	/// setters ///
	///////////////

	function changeVolatilityFeed(address _volFeed) external {
		_onlyGovernor();
		volatilityFeed = _volFeed;
	}

	function changePortfolioValuesFeed(address _portfolioValuesFeed) external {
		_onlyGovernor();
		portfolioValuesFeed = _portfolioValuesFeed;
	}

	function changeAccounting(address _accounting) external {
		_onlyGovernor();
		accounting = _accounting;
	}

	function changePriceFeed(address _priceFeed) external {
		_onlyGovernor();
		priceFeed = _priceFeed;
	}
}