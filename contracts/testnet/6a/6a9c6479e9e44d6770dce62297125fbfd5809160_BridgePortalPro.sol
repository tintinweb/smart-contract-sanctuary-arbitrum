// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Chain.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Governable.sol";

contract BridgePortalPro is ReentrancyGuard, Governable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /**
     * @notice Determines if cross domain messaging is paused. When set to true,
     *         withdrawals are paused. This may be removed in the future.
     */
    bool public paused;
    uint256 public targetChainId;
    uint256 public minDepositValue = 100000000000000;
    mapping (uint256 => bool) public depositIdToStatus;
    mapping (address => bool) public isOrderKeeper;

    event TransactionDeposited(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 targetChainId
    );

    /**
     * @notice Emitted when the pause is triggered.
     *
     * @param account Address of the account triggering the pause.
     */
    event Paused(address account);

    /**
     * @notice Emitted when the pause is lifted.
     *
     * @param account Address of the account triggering the unpause.
     */
    event Unpaused(address account);

    event SendTokenEvent(address indexed receiver, uint256 amount, uint256 depositId);

    event SetOrderKeeper(address indexed account, bool isActive);

    /**
     * @notice Reverts when paused.
     */
    modifier whenNotPaused() {
        require(paused == false, "paused");
        _;
    }

    modifier onlyOrderKeeper() {
        require(isOrderKeeper[msg.sender], "BridgePortalV2: forbidden1");
        _;
    }

    constructor(uint256 _targetChainId) {
        targetChainId = _targetChainId;
    }

    function setOrderKeeper(address _account, bool _isActive) external onlyGov {
        isOrderKeeper[_account] = _isActive;
        emit SetOrderKeeper(_account, _isActive);
    }

    function pause() external onlyGov {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpause deposits and withdrawals.
     */
    function unpause() external onlyGov {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function setMinDepositValue(uint256 _minDepositValue) external onlyGov {
        minDepositValue = _minDepositValue;
    }

    receive() external payable {
        require(paused == false, "paused");
        _depositTransaction(msg.sender, msg.sender, msg.value);
    }

    /**
     * @notice Accepts ETH value without triggering a deposit to L2. This function mainly exists
     *         for the sake of the migration between the legacy Optimism system and Bedrock.
     */
    function donateETH() external payable nonReentrant {
        // Intentionally empty.
    }

    function depositTransaction(address _to) external payable {
        _depositTransaction(msg.sender, _to, msg.value);
    }

    function _depositTransaction(
        address _from,
        address _to,
        uint256 _value
    ) private nonReentrant whenNotPaused {
        require(_value >= minDepositValue, "invalid _value");

        // Emit a TransactionDeposited event so that the rollup node can derive a deposit
        // transaction for this deposit.
        emit TransactionDeposited(_from, _to, _value, targetChainId);
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov nonReentrant {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    //use by relayer to send token to target wallet
    function sendToken(address payable _receiver, uint256 _outAmount, uint256 _depositId) external onlyOrderKeeper nonReentrant {
        require(depositIdToStatus[_depositId] == false, "depositId already processed");
        require(_outAmount > 0, "invalid _outAmount");
        require(_receiver != address(0), "invalid _receiver");
        require(_outAmount <= address(this).balance, "_outAmount large than contract balance");
        require(_receiver != address(this), "can not send eth to myself");

        depositIdToStatus[_depositId] = true;
        _receiver.sendValue(_outAmount);

        emit SendTokenEvent(_receiver, _outAmount, _depositId);
    }

    function balanceOf() external view returns (uint256) {
        return address(this).balance;
    }
}