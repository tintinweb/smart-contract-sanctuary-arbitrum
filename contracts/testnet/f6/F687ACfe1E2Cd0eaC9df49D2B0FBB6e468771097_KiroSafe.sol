// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./AccessControl.sol";

contract KiroSafe is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant DAO_ROLE = keccak256("DAO");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
    bytes32 public constant MANAGER_ADMIN_ROLE = keccak256("MANAGER_ADMIN");
    bytes32 public constant DAO_ADMIN_ROLE = keccak256("DAO_ADMIN");
    uint256 public constant PPM_WHOLE = 1_000_000;

    mapping(address => uint256) public s_currentBalance;
    mapping(address => uint256) public s_startingBalance;
    mapping(address => uint256) public s_votingBalance;
    mapping(address => mapping(address => uint256)) public s_virtualBalance;

    uint256 public s_totalCurrentBalance;
    uint256 public s_lockedPPM;

    bool public s_locked = false;
    bool public s_freezed = false;

    IERC20 public immutable KIRO;

    event FundsAdded(
        address indexed from,
        address indexed to,
        uint256 indexed amount
    );
    event FundsRemoved(
        address indexed from,
        address indexed to,
        uint256 indexed amount
    );
    event FundsWithdrawn(address indexed from, uint256 indexed amount);
    event StateChanged(bool freezed, bool locked);
    event LockedPPMChanged(uint256 amount);
    event LeftoversWithdrawal(uint256 amount);

    modifier onlyLocked() {
        require(s_locked, "not locked");
        _;
    }

    modifier onlyUnlocked() {
        require(!s_locked, "locked");
        _;
    }

    modifier onlyFreezed() {
        require(s_freezed, "not freezed");
        _;
    }

    modifier onlyUnfreezed() {
        require(!s_freezed, "freezed");
        _;
    }

    modifier onlyActive() {
        require(!s_locked && !s_freezed, "locked or freezed");
        _;
    }

    constructor(IERC20 kiro) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setRoleAdmin(DAO_ROLE, DAO_ADMIN_ROLE);
        _grantRole(DAO_ADMIN_ROLE, msg.sender);

        _setRoleAdmin(MANAGER_ROLE, MANAGER_ADMIN_ROLE);
        _grantRole(MANAGER_ADMIN_ROLE, msg.sender);

        KIRO = kiro;
        s_lockedPPM = PPM_WHOLE;
    }

    function withdrawLeftOvers() external onlyRole(MANAGER_ROLE) {
        uint256 contractBalance = KIRO.balanceOf(address(this));
        if (contractBalance > s_totalCurrentBalance) {
            uint256 leftovers = contractBalance - s_totalCurrentBalance;
            KIRO.safeTransfer(msg.sender, leftovers);
            emit LeftoversWithdrawal(leftovers);
        }
    }

    function setLockedPPM(
        uint256 newPPM
    ) external onlyRole(DAO_ROLE) onlyLocked {
        require(newPPM < s_lockedPPM, "too high");
        s_lockedPPM = newPPM;
        emit LockedPPMChanged(newPPM);
    }

    function freezeFunds() external onlyRole(MANAGER_ROLE) onlyUnlocked {
        s_freezed = true;
        emit StateChanged(s_freezed, s_locked);
    }

    function unfreezeFunds() external onlyRole(MANAGER_ROLE) onlyUnlocked {
        s_freezed = false;
        emit StateChanged(s_freezed, s_locked);
    }

    function lockFunds() external onlyRole(MANAGER_ROLE) onlyFreezed {
        s_freezed = false;
        s_locked = true;
        emit StateChanged(s_freezed, s_locked);
    }

    function addFunds(uint256 amount) external onlyActive {
        _addFundsTo(amount, msg.sender);
    }

    function addFundsTo(
        uint256 amount,
        address to
    ) external onlyRole(MANAGER_ROLE) onlyUnfreezed {
        _addFundsTo(amount, to);
    }

    function removeFunds(uint256 amount) external onlyActive {
        _removeFundsFrom(amount, msg.sender);
    }

    function removeFundsFrom(
        uint256 amount,
        address from
    ) external onlyRole(MANAGER_ROLE) onlyActive {
        _removeFundsFrom(amount, from);
    }

    function withdraw(uint256 amount) external onlyLocked {
        require(amount > 0, "zero amount");
        uint256 maxAllowed = s_currentBalance[msg.sender] -
            ((s_startingBalance[msg.sender] * s_lockedPPM) / PPM_WHOLE);
        require(amount <= maxAllowed, "amount too high");
        s_currentBalance[msg.sender] -= amount;
        s_totalCurrentBalance -= amount;
        KIRO.safeTransfer(msg.sender, amount);
        emit FundsWithdrawn(msg.sender, amount);
    }

    function _addFundsTo(uint256 amount, address to) private {
        require(to != address(0), "zero address");
        require(amount > 0, "zero amount");
        if (s_locked) {
            require(s_startingBalance[to] == 0, "allready a member");
            uint256 staringBalnace = (amount * PPM_WHOLE) / s_lockedPPM;
            s_startingBalance[to] = staringBalnace;
        } else {
            s_virtualBalance[msg.sender][to] += amount;
            s_startingBalance[to] += amount;
        }
        s_votingBalance[to] += amount;
        s_currentBalance[to] += amount;
        s_totalCurrentBalance += amount;
        KIRO.safeTransferFrom(msg.sender, address(this), amount);
        emit FundsAdded(msg.sender, to, amount);
    }

    function _removeFundsFrom(uint256 amount, address from) private {
        require(from != address(0), "zero address");
        require(amount > 0, "zero amount");
        s_startingBalance[from] -= amount;
        s_votingBalance[from] -= amount;
        s_currentBalance[from] -= amount;
        s_virtualBalance[msg.sender][from] -= amount;
        s_totalCurrentBalance -= amount;
        KIRO.safeTransfer(msg.sender, amount);
        emit FundsRemoved(from, msg.sender, amount);
    }
}