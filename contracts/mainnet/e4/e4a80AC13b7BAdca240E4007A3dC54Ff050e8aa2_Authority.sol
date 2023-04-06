/**
 *Submitted for verification at Arbiscan on 2023-04-05
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

interface IAuthority {
    function treasury() external view returns (address);

    function controller() external view returns (address);

    function empyreal() external view returns (address);

    function firmament() external view returns (address);

    function horizon() external view returns (address);

    function empyrealMinters(address) external view returns (bool);

    function firmamentMinters(address) external view returns (bool);
}

abstract contract AccessControlled {
    /* ========== EVENTS ========== */
    event AuthorityUpdated(IAuthority indexed authority);
    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */
    IAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyTreasury() {
        require(msg.sender == authority.treasury(), UNAUTHORIZED);
        _;
    }

    modifier onlyController() {
        require(msg.sender == authority.controller(), UNAUTHORIZED);
        _;
    }

    modifier onlyEmpyrealMinter() {
        require(authority.empyrealMinters(msg.sender), UNAUTHORIZED);
        _;
    }

    modifier onlyFirmamentMinter() {
        require(authority.firmamentMinters(msg.sender), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IAuthority _newAuthority) external onlyController {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    function empyreal() public view returns (address) {
        return authority.empyreal();
    }

    function firmament() public view returns (address) {
        return authority.firmament();
    }

    function horizon() public view returns (address) {
        return authority.horizon();
    }

    function treasury() public view returns (address) {
        return authority.treasury();
    }
}

contract Authority is IAuthority {
    /* ========== EVENTS ========== */
    event TreasuryPushed(address indexed from, address indexed to);
    event ControllerPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event FirmamentSet(address);
    event EmpyrealSet(address);
    event ControllerPulled(address indexed from, address indexed to);
    event Renounced();

    /* ========== STATE VARIABLES ========== */

    address public controller;
    address public newController;
    address public treasury;
    address public firmament;
    address public empyreal;
    address public horizon;

    mapping(address => bool) _empyrealMinters;
    mapping(address => bool) _firmamentMinters;

    /* ========== Constructor ========== */

    constructor(address _controller) {
        controller = _controller;
    }

    /* ========== CONTROLLER ONLY ========== */

    function setFirmament(address _firmament) external {
        require(msg.sender == controller, "only controller");
        firmament = _firmament;
        emit FirmamentSet(_firmament);
    }

    function setHorizon(address _horizon) external {
        require(msg.sender == controller, "only controller");
        horizon = _horizon;
    }

    function setEmpyreal(address _empyreal) external {
        require(msg.sender == controller, "only controller");
        empyreal = _empyreal;
        emit EmpyrealSet(_empyreal);
    }

    function setTreasury(address _newTreasury) external {
        require(msg.sender == controller, "only controller");
        treasury = _newTreasury;
        _empyrealMinters[treasury] = true;
        emit TreasuryPushed(treasury, _newTreasury);
    }

    function setEmpyrealMinter(address _minterAddress, bool isMinter) external {
        require(msg.sender == controller, "only controller");
        _empyrealMinters[_minterAddress] = isMinter;
    }

    function setFirmamentMinter(
        address _minterAddress,
        bool isMinter
    ) external {
        require(msg.sender == controller, "only controller");
        _firmamentMinters[_minterAddress] = isMinter;
    }

    function pushController(
        address _newController,
        bool _effectiveImmediately
    ) external {
        require(msg.sender == controller, "only controller");

        if (_effectiveImmediately) controller = _newController;
        newController = _newController;
        emit ControllerPushed(controller, newController, _effectiveImmediately);
    }

    /* ========== PENDING ROLE ONLY ========== */

    function pullController() external {
        require(msg.sender == newController, "!newController");
        emit ControllerPulled(controller, newController);
        controller = newController;
    }

    /* ========= VIEW ======== */

    function empyrealMinters(address _minter) external view returns (bool) {
        return _empyrealMinters[_minter];
    }

    function firmamentMinters(address _minter) external view returns (bool) {
        return _firmamentMinters[_minter];
    }
}