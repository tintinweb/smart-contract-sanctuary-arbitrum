/**
 *Submitted for verification at Arbiscan on 2023-05-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.19;

abstract contract Adminable {
    address public admin;
    address public candidate;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event AdminCandidateRegistered(address indexed admin, address indexed candidate);

    constructor(address _admin) {
        require(_admin != address(0), "admin is the zero address");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return account == admin;
    }

    function registerAdminCandidate(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "new admin is the zero address");
        candidate = _newAdmin;
        emit AdminCandidateRegistered(admin, _newAdmin);
    }

    function confirmAdmin() external {
        require(msg.sender == candidate, "only candidate");
        emit AdminChanged(admin, candidate);
        admin = candidate;
        candidate = address(0);
    }
}


interface IConfig {
    function MIN_DELAY_TIME() external pure returns (uint256);
    function upgradeDelayTime() external view returns (uint256);
    function setUpgradeDelayTime(uint256 time) external;
    function getUpgradeableAt() external view returns (uint256);
}


contract Config is IConfig, Adminable {

    uint256 public constant MIN_DELAY_TIME = 2 days;

    uint256 public upgradeDelayTime;

    constructor(address _admin) Adminable(_admin) {
        upgradeDelayTime = MIN_DELAY_TIME;
    }

    /**
     * @notice Set a delay period for upgrades. Upgrades can only be performed after the specified delay time has passed.
     * @param time The delay time in seconds
     */
    function setUpgradeDelayTime(uint256 time) external onlyAdmin {
        require(time >= MIN_DELAY_TIME, "Config: delay time too short");
        upgradeDelayTime = time;
    }

    /**
     * @notice Retrieve the timestamp, in seconds, when the upgrade is allowed to be performed.
     */
    function getUpgradeableAt() external view returns (uint256) {
        return block.timestamp + upgradeDelayTime;
    }
}