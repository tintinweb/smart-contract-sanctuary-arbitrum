/**
 *Submitted for verification at Arbiscan.io on 2023-09-14
*/

// Sources flattened with hardhat v2.13.1 https://hardhat.org

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}


// File @openzeppelin/contracts/interfaces/[email protected]


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)




// File contracts/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File contracts/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)



abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)



library Address {
    error AddressInsufficientBalance(address account);
    error AddressEmptyCode(address target);
    error FailedInnerCall();

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}


// File contracts/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)




library SafeERC20 {
    using Address for address;

    error SafeERC20FailedOperation(address token);

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeCall(
            token.approve,
            (spender, value)
        );
        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(
                token,
                abi.encodeCall(token.approve, (spender, 0))
            );
            _callOptionalReturn(token, approvalCall);
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCallWithValue(data, 0);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    function _callOptionalReturnBool(
        IERC20 token,
        bytes memory data
    ) private returns (bool) {
        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool))) &&
            address(token).code.length > 0;
    }
}


// File contracts/SwapAdaptor.sol





contract SwapAdaptor is Ownable(msg.sender) {
    using SafeERC20 for IERC20;
    using Address for address;

    error SwapAdaptorInvalidSignature(address _signer);

    modifier onlyVerifiedOrigin(bytes calldata signature) {
        _verifyOrigin(signature);
        _;
    }

    function swap(
        IERC20 tokenIn,
        uint256 amountIn,
        address callee,
        bytes calldata payload,
        bytes calldata signature
    ) external payable onlyVerifiedOrigin(signature) {
        _swap(tokenIn, amountIn, callee, payload);
    }

    function swap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address to,
        address callee,
        bytes calldata payload,
        bytes calldata signature
    ) external payable onlyVerifiedOrigin(signature) {
        _swap(tokenIn, amountIn, callee, payload);
        tokenOut.safeTransfer(to, amountOut);
    }

    function transfer(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    function _swap(
        IERC20 tokenIn,
        uint256 amountIn,
        address callee,
        bytes calldata payload
    ) internal {
        tokenIn.forceApprove(callee, amountIn);
        callee.functionCallWithValue(payload, msg.value);
    }

    function _verifyOrigin(bytes calldata signature) internal view {
        address signer = recover(_originHash(), signature);
        if (signer != owner()) {
            revert SwapAdaptorInvalidSignature(signer);
        }
    }

    function recover(
        bytes32 _hash,
        bytes calldata _signature
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        /// @solidity memory-safe-assembly
        assembly {
            r := calldataload(_signature.offset)
            s := calldataload(add(_signature.offset, 0x20))
            v := byte(0x0, calldataload(add(_signature.offset, 0x40)))
        }
        return ecrecover(_hash, v, r, s);
    }

    function _originHash() internal view returns (bytes32 _hash) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0, origin())
            _hash := keccak256(0xc, 0x14)
        }
        // return keccak256(abi.encodePacked(tx.origin));
    }
}