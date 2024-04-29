// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IAuthority} from "./../utils/interfaces/IAuthority.sol";
import {Permission} from "./../utils/auth/Permission.sol";

import {ExternalCallUtils} from "../utils/ExternalCallUtils.sol";

/**
 * @title Router
 * @dev Users will approve this router for token spenditures
 */
contract Router is Permission {
    uint transferGasLimit;

    constructor(IAuthority _authority, uint _trasnferGasLimit) Permission(_authority) {
        authority = _authority;
        transferGasLimit = _trasnferGasLimit;
    }

    /**
     * @dev low level call to an ERC20 contract, return raw data to be handled by authorised contract
     * @param token the token to transfer
     * @param from the account to transfer from
     * @param to the account to transfer to
     * @param amount the amount to transfer
     */
    function transfer(IERC20 token, address from, address to, uint amount) external auth {
        ExternalCallUtils.callTarget(transferGasLimit, address(token), abi.encodeCall(token.transferFrom, (from, to, amount)));
    }

    function setTransferGasLimit(uint _trasnferGasLimit) external auth {
        transferGasLimit = _trasnferGasLimit;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IAuthority {
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IAuthority} from "./../interfaces/IAuthority.sol";

abstract contract Permission {
    IAuthority public immutable authority;

    mapping(address => mapping(bytes4 signatureHash => bool)) public permissionMap;

    function canCall(address user, bytes4 signatureHash) public view returns (bool) {
        return permissionMap[user][signatureHash];
    }

    constructor(IAuthority _authority) {
        authority = _authority;
    }

    modifier auth() {
        if (canCall(msg.sender, msg.sig)) {
            _;
        } else {
            revert Auth_Unauthorized();
        }
    }

    modifier checkAuthority() {
        if (msg.sender == address(authority)) {
            _;
        } else {
            revert Auth_Unauthorized();
        }
    }

    function setPermission(address user, bytes4 functionSig) external checkAuthority {
        permissionMap[user][functionSig] = true;
    }

    function removePermission(address user, bytes4 functionSig) external checkAuthority {
        delete permissionMap[user][functionSig];
    }

    error Auth_Unauthorized();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

/**
 * @title ExternalCallUtils
 * @dev Various utility functions for external calls, including checks for contract existence and call success
 * native token functions
 */
library ExternalCallUtils {
    /**
     * @dev Checks if the specified address is a contract.
     *
     * @param account The address to check.
     * @return a boolean indicating whether the specified address is a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d246... is returned for accounts without code, i.e., `keccak256('')`
        uint size;
        // inline assembly is used to access the EVM's `extcodesize` operation
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Validates that the specified destination address is not the zero address.
     *
     * @param destination The address to validate.
     */
    function validateDestination(address destination) internal pure {
        if (destination == address(0)) {
            revert ExternalCallUtils__EmptyReceiver();
        }
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function callTarget(uint gasLimit, address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.call{gas: gasLimit}(data);

        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert ExternalCallUtils__SafeERC20FailedOperation(target);
        }

        if (success) {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert ExternalCallUtils__AddressEmptyCode(target);
            }
            return returndata;
        } else {
            _revert(returndata);
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
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
            revert ExternalCallUtils__FailedInnerCall();
        }
    }

    error ExternalCallUtils__EmptyReceiver();
    error ExternalCallUtils__AddressEmptyCode(address target);
    error ExternalCallUtils__FailedInnerCall();
    error ExternalCallUtils__SafeERC20FailedOperation(address token);
}