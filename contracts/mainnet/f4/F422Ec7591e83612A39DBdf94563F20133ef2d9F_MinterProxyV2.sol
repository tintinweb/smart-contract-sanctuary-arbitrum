/**
 *Submitted for verification at Arbiscan.io on 2024-04-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Controller is Ownable {
    event ControllerAdded(address controller);
    event ControllerRemoved(address controller);
    mapping(address => bool) controllers;
    uint8 public controllerCnt = 0;

    modifier onlyController() {
        require(isController(_msgSender()), "no controller rights");
        _;
    }

    function isController(address _controller) public view returns (bool) {
        return _controller == owner() || controllers[_controller];
    }

    function addController(address _controller) public onlyOwner {
        if (controllers[_controller] == false) {
            controllers[_controller] = true;
            controllerCnt++;
        }
        emit ControllerAdded(_controller);
    }

    function removeController(address _controller) public onlyOwner {
        if (controllers[_controller] == true) {
            controllers[_controller] = false;
            controllerCnt--;
        }
        emit ControllerRemoved(_controller);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
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

interface IWrapToken {
    function deposit() external payable;
    function withdraw(uint256) external;
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                oldAllowance + value
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    oldAllowance - value
                )
            );
        }
    }

    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeWithSelector(
            token.approve.selector,
            spender,
            value
        );

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, 0)
            );
            _callOptionalReturn(token, approvalCall);
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        require(
            returndata.length == 0 || abi.decode(returndata, (bool)),
            "SafeERC20: ERC20 operation did not succeed"
        );
    }

    function _callOptionalReturnBool(
        IERC20 token,
        bytes memory data
    ) private returns (bool) {
        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool))) &&
            Address.isContract(address(token));
    }
}

library TransferHelper {
    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: NATIVE_TRANSFER_FAILED");
    }
}

interface IMintBurnToken {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

contract MinterProxyV2 is Controller, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    address public immutable NATIVE =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public wNATIVE;

    uint256 MAX_UINT256 =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    mapping(uint256 => bool) public completedOrder;

    address public _liquidpool;

    uint256 public _orderID;

    bool private _paused;

    event Paused(address account);

    event Unpaused(address account);

    event LogVaultIn(
        address indexed token,
        uint256 indexed orderID,
        address indexed receiver,
        uint256 amount,
        uint256 serviceFee,
        uint256 gasFee
    );
    event LogVaultOut(
        address indexed token,
        address indexed from,
        uint256 indexed orderID,
        uint256 amount,
        address vault,
        bytes order
    );

    event LogVaultCall(
        address indexed target,
        uint256 amount,
        bool success,
        bytes reason
    );

    constructor(uint256 _id_prefix, address _lp, address _wNative) {
        _liquidpool = _lp;
        _paused = false;
        _orderID = _id_prefix * (10 ** 9);
        wNATIVE = _wNative;
    }

    receive() external payable {}

    fallback() external payable {}

    modifier whenNotPaused() {
        require(!_paused, "MP: paused");
        _;
    }

    function chainID() public view returns (uint) {
        return block.chainid;
    }

    function setLiquidpool(address _lp) external onlyOwner {
        _liquidpool = _lp;
    }

    function setWrapNative(address _wNative) external onlyOwner {
        wNATIVE = _wNative;
    }

    function needWrapNative() internal view returns (bool) {
        return wNATIVE != address(0);
    }

    function liquidpool() internal view returns (address) {
        if (_liquidpool != address(0)) {
            return _liquidpool;
        }
        return address(this);
    }

    function pause() external onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() external onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    function isUUIDCompleted(uint256 uuid) external view returns (bool) {
        return completedOrder[uuid];
    }

    function _registerOrder(uint256 uuid) internal {
        require(!completedOrder[uuid], "MP: already completed");
        completedOrder[uuid] = true;
    }

    function _balanceOf(address receiveToken) internal view returns (uint256) {
        uint256 _balance;
        if (receiveToken == NATIVE) {
            if (needWrapNative()) {
                _balance = IERC20(wNATIVE).balanceOf(liquidpool());
            } else {
                _balance = address(this).balance;
            }
        } else {
            _balance = IERC20(receiveToken).balanceOf(liquidpool());
        }
        return _balance;
    }

    function _balanceOfSelf(
        address receiveToken
    ) internal view returns (uint256) {
        uint256 _balance;
        if (receiveToken == NATIVE) {
            _balance = address(this).balance;
        } else {
            _balance = IERC20(receiveToken).balanceOf(address(this));
        }
        return _balance;
    }

    function _checkVaultOut(
        address tokenAddr,
        uint256 amount,
        bytes calldata order
    ) internal pure {
        require(tokenAddr != address(0), "MP: tokenAddress is invalid");
        require(amount > 0, "MP: amount is 0");
        require(order.length > 0, "MP: order is empty");
    }

    function vaultOut(
        address tokenAddr,
        uint256 amount,
        bool burnable,
        bytes calldata order
    ) external payable nonReentrant whenNotPaused {
        _checkVaultOut(tokenAddr, amount, order);

        if (tokenAddr == NATIVE) {
            require(amount == msg.value, "MP: amount is invalid");
            if (needWrapNative()) {
                uint256 old = IERC20(wNATIVE).balanceOf(address(this));
                IWrapToken(wNATIVE).deposit{value: msg.value}();
                uint256 val = IERC20(wNATIVE).balanceOf(address(this));
                require(val - old == amount, "MP: warp token dismatch");
                IERC20(wNATIVE).safeTransfer(_liquidpool, amount);
            } else {
                TransferHelper.safeTransferNative(_liquidpool, amount);
            }
        } else if (burnable) {
            uint256 old = IERC20(tokenAddr).balanceOf(_msgSender());
            IMintBurnToken(tokenAddr).burn(_msgSender(), amount);
            uint256 val = IERC20(tokenAddr).balanceOf(_msgSender());
            require(val == old - amount, "MP: burn failed");
        } else {
            IERC20(tokenAddr).safeTransferFrom(
                _msgSender(),
                liquidpool(),
                amount
            );
        }

        _orderID++;
        emit LogVaultOut(
            tokenAddr,
            _msgSender(),
            _orderID,
            amount,
            burnable ? address(0) : liquidpool(),
            order
        );
    }

    function vaultIn(
        uint256 orderID,
        address receiveToken,
        address receiver,
        bool burnable,
        uint256 amount
    ) external onlyController whenNotPaused {
        require(orderID > 0, "MP: orderID empty");
        require(receiver != address(0), "MP: receiver invaild");
        require(amount > 0, "MP: amount is empty");
        if (!burnable) {
            require(
                _balanceOf(receiveToken) >= amount,
                "MP: insufficient balance"
            );
        }
        _registerOrder(orderID);
        if (receiveToken == NATIVE) {
            if (needWrapNative()) {
                IERC20(wNATIVE).safeTransferFrom(
                    liquidpool(),
                    address(this),
                    amount
                );
                uint256 old = address(this).balance;
                IWrapToken(wNATIVE).withdraw(amount);
                uint256 val = address(this).balance;
                require(
                    val - old == amount,
                    "MP: native token amount dismatch"
                );
            }
            TransferHelper.safeTransferNative(receiver, amount);
        } else if (burnable) {
            uint256 old = IERC20(receiveToken).balanceOf(receiver);
            IMintBurnToken(receiveToken).mint(receiver, amount);
            uint256 val = IERC20(receiveToken).balanceOf(receiver);
            require(val == old + amount, "MP: mint failed");
        } else {
            IERC20(receiveToken).safeTransferFrom(
                liquidpool(),
                receiver,
                amount
            );
        }
        emit LogVaultIn(receiveToken, orderID, receiver, amount, 0, 0);
    }

    // Fees[] struct
    // 0: uint256 expectAmount
    // 1: uint256 minAmount
    // 2: uint256 feeRate
    // 3: uint256 gasFee
    function vaultInAndCall(
        uint256 orderID,
        address tokenAddr,
        address toAddr,
        bool burnable,
        uint256 amount,
        address receiver,
        address receiveToken,
        uint256[] memory fees,
        bytes calldata data
    ) external onlyController whenNotPaused {
        require(orderID > 0, "MP: orderID empty");
        require(data.length > 0, "MP: data empty");
        require(fees.length == 4, "MP: fees mismatch");
        require(amount > 0, "MP: amount is empty");
        require(fees[1] > 0, "MP: minAmount is empty");
        require(fees[0] > 0, "MP: expectAmount is empty");
        if (!burnable) {
            require(
                _balanceOf(tokenAddr) >= amount,
                "MP: insufficient balance"
            );
        }
        require(receiver != address(0), "MP: receiver is empty");
        require(
            toAddr != address(this) && toAddr != address(0),
            "MP: toAddr invaild"
        );
        _registerOrder(orderID);
        bool fromTokenNative = (tokenAddr == NATIVE);
        if (fromTokenNative) {
            if (needWrapNative()) {
                IERC20(wNATIVE).safeTransferFrom(
                    liquidpool(),
                    address(this),
                    amount
                );
                uint256 old = address(this).balance;
                IWrapToken(wNATIVE).withdraw(amount);
                uint256 val = address(this).balance;
                require(
                    val - old == amount,
                    "MP: native token amount dismatch"
                );
            } else {
                // the native token in this contract, so ignore
                require(
                    address(this).balance >= amount,
                    "MP: native token insuffient"
                );
            }
        } else {
            if (burnable) {
                uint256 old = IERC20(tokenAddr).balanceOf(address(this));
                IMintBurnToken(tokenAddr).mint(address(this), amount);
                uint256 val = IERC20(tokenAddr).balanceOf(address(this));
                require(val == old + amount, "MP: mint failed");
            } else {
                IERC20(tokenAddr).safeTransferFrom(
                    _liquidpool,
                    address(this),
                    amount
                );
            }
            if (IERC20(tokenAddr).allowance(address(this), toAddr) < amount) {
                IERC20(tokenAddr).safeApprove(toAddr, MAX_UINT256);
            }
        }

        (uint256 realOut, uint256 serviceFee) = _callAndTransfer(
            toAddr,
            fromTokenNative ? amount : 0,
            receiveToken,
            fees,
            data
        );
        if (receiver != address(this)) {
            if (receiveToken == NATIVE) {
                TransferHelper.safeTransferNative(receiver, realOut);
            } else {
                IERC20(receiveToken).safeTransfer(receiver, realOut);
            }
        }
        uint256 totalfee = serviceFee + fees[3];
        if (totalfee > 0) {
            if (receiveToken == NATIVE) {
                if (needWrapNative()) {
                    IWrapToken(wNATIVE).deposit{value: totalfee}();
                    IERC20(wNATIVE).safeTransfer(_liquidpool, totalfee);
                }
            } else {
                IERC20(receiveToken).safeTransfer(_liquidpool, totalfee);
            }
        }

        emit LogVaultIn(
            receiveToken,
            orderID,
            receiver,
            realOut,
            serviceFee,
            fees[3]
        );
    }

    // Fees[] struct
    // 0: uint256 expectAmount
    // 1: uint256 minAmount
    // 2: uint256 feeRate
    // 3: uint256 gasFee
    function _callAndTransfer(
        address contractAddr,
        uint256 fromNativeAmount,
        address receiveToken,
        uint256[] memory fees,
        bytes calldata data
    ) internal returns (uint256, uint256) {
        uint256 old_balance = _balanceOfSelf(receiveToken);

        if (fromNativeAmount > 0) {
            contractAddr.functionCallWithValue(
                data,
                fromNativeAmount,
                "MP: CallWithValue failed"
            );
        } else {
            contractAddr.functionCall(data, "MP: FunctionCall failed");
        }
        uint256 real = 0;
        uint256 serviceFee = 0;
        {
            uint256 expectAmount = fees[0];
            uint256 minAmount = fees[1];
            uint256 feeRate = fees[2];
            uint256 gasFee = fees[3];
            uint256 new_balance = _balanceOfSelf(receiveToken);
            require(
                new_balance > old_balance,
                "MP: receiver should get assets"
            );
            uint256 amountOut = new_balance - old_balance;
            require(amountOut >= minAmount, "MP: receive amount not enough");
            require(amountOut >= minAmount + gasFee, "MP: gasFee not enough");

            serviceFee = (amountOut * feeRate) / 10000;

            require(
                amountOut >= minAmount + gasFee + serviceFee,
                "MP: fee not enough"
            );
            real = amountOut - serviceFee - gasFee;
            if (real > expectAmount) {
                serviceFee += real - expectAmount;
                real = expectAmount;
            }
        }
        return (real, serviceFee);
    }

    function call(
        address target,
        bytes calldata _data
    ) external payable onlyOwner {
        (bool success, bytes memory result) = target.call{value: msg.value}(
            _data
        );
        emit LogVaultCall(target, msg.value, success, result);
    }

    function withdrawFee(
        address token,
        uint256 amount
    ) external onlyController {
        if (token == NATIVE) {
            uint256 balance = address(this).balance;
            uint256 tmp = balance > amount ? amount : balance;
            TransferHelper.safeTransferNative(owner(), tmp);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            uint256 tmp = balance > amount ? amount : balance;
            IERC20(token).safeTransfer(owner(), tmp);
        }
    }
}