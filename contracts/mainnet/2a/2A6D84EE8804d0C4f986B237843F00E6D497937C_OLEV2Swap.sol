// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./common/Adminable.sol";
import "./common/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";

contract OLEV2Swap is Adminable, ReentrancyGuard {
    using TransferHelper for IERC20;

    IERC20 public immutable oleV1;
    IERC20 public immutable oleV2;
    uint64 public immutable expireTime;

    event Swapped (address account, uint amount);

    constructor (IERC20 _oleV1, IERC20 _oleV2, uint64 _expireTime){
        admin = payable(msg.sender);
        oleV1 = _oleV1;
        oleV2 = _oleV2;
        expireTime = _expireTime;
    }

    function swap(uint256 _amount) external nonReentrant(){
        require(expireTime > block.timestamp, 'Expired');
        uint oleV2BalanceBefore = oleV2.balanceOf(address(this));
        require(oleV2BalanceBefore >= _amount, 'NE');

        uint oleV1BalanceBefore = oleV1.balanceOf(address(this));
        oleV1.safeTransferFrom(msg.sender, address(this), _amount);
        uint oleV1BalanceAfter = oleV1.balanceOf(address(this));
        require(oleV1BalanceAfter - oleV1BalanceBefore == _amount, "CKP1");

        oleV2.safeTransfer(msg.sender, _amount);
        uint oleV2BalanceAfter = oleV2.balanceOf(address(this));
        require(oleV2BalanceBefore - oleV2BalanceAfter == _amount, "CKP2");
        emit Swapped(msg.sender, _amount);
    }

    function recycle(address _account, uint256 _amount) external onlyAdmin {
        require(oleV2.balanceOf(address(this)) >= _amount, "NE");
        oleV2.safeTransfer(_account, _amount);
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TransferHelper
 * @dev Wrappers around ERC20 operations that returns the value received by recipent and the actual allowance of approval.
 * To use this library you can add a `using TransferHelper for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library TransferHelper {
    function safeTransfer(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256 amountReceived) {
        if (_amount > 0) {
            bool success;
            uint256 balanceBefore = _token.balanceOf(_to);
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.transfer.selector, _to, _amount));
            require(success, "TF");
            uint256 balanceAfter = _token.balanceOf(_to);
            require(balanceAfter > balanceBefore, "TF");
            amountReceived = balanceAfter - balanceBefore;
        }
    }

    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256 amountReceived) {
        if (_amount > 0) {
            bool success;
            uint256 balanceBefore = _token.balanceOf(_to);
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.transferFrom.selector, _from, _to, _amount));
            require(success, "TFF");
            uint256 balanceAfter = _token.balanceOf(_to);
            require(balanceAfter > balanceBefore, "TFF");
            amountReceived = balanceAfter - balanceBefore;
        }
    }

    function safeApprove(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) internal returns (uint256) {
        bool success;
        if (_token.allowance(address(this), _spender) != 0) {
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.approve.selector, _spender, 0));
            require(success, "AF");
        }
        (success, ) = address(_token).call(abi.encodeWithSelector(_token.approve.selector, _spender, _amount));
        require(success, "AF");

        return _token.allowance(address(this), _spender);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        check();
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }

    function check() private view {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

abstract contract Adminable {
    address payable public admin;
    address payable public pendingAdmin;
    address payable public developer;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() {
        developer = payable(msg.sender);
    }

    modifier onlyAdmin() {
        checkAdmin();
        _;
    }
    modifier onlyAdminOrDeveloper() {
        require(msg.sender == admin || msg.sender == developer, "Only admin or dev");
        _;
    }

    function setPendingAdmin(address payable newPendingAdmin) external virtual onlyAdmin {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external virtual {
        require(msg.sender == pendingAdmin, "Only pendingAdmin");
        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        // Store admin with value pendingAdmin
        admin = pendingAdmin;
        // Clear the pending value
        pendingAdmin = payable(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function checkAdmin() private view {
        require(msg.sender == admin, "caller must be admin");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}