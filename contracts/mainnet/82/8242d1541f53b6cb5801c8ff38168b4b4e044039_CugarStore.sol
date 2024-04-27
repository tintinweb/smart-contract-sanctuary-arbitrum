// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {Auth, Authority} from "@solmate/contracts/auth/Auth.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {BankStore} from "./../../shared/store/BankStore.sol";
import {Router} from "./../../shared/Router.sol";

contract CugarStore is BankStore {
    mapping(IERC20 => mapping(uint cursorTime => uint)) cursorBalanceMap;
    mapping(IERC20 => mapping(uint cursorTime => uint)) cursorVeSupplyMap;

    mapping(IERC20 => mapping(address => uint)) userSeedContributionMap;
    mapping(IERC20 => mapping(address => uint)) public userTokenCursorMap;

    constructor(Authority _authority, Router _router, address _initSetter) BankStore(_authority, _router, _initSetter) {}

    function getSeedContribution(IERC20 _token, address _user) external view returns (uint) {
        return userSeedContributionMap[_token][_user];
    }

    function increaseUserSeedContributionList(
        IERC20 _token, //
        uint _cursor,
        address _depositor,
        address[] calldata _userList,
        uint[] calldata _valueList
    ) external isSetter {
        uint _valueListLength = _valueList.length;
        uint _totalAmount = 0;

        if (_valueListLength != _valueList.length) revert CugarStore__InvalidLength();

        for (uint i = 0; i < _valueListLength; i++) {
            userSeedContributionMap[_token][_userList[i]] += _valueList[i];
            _totalAmount += _valueList[i];
        }

        cursorBalanceMap[_token][_cursor] += _totalAmount;
        _transferIn(_token, _depositor, _totalAmount);
    }

    function increaseUserSeedContribution(IERC20 _token, uint _cursor, address _depositor, address _user, uint _value) external isSetter {
        userSeedContributionMap[_token][_user] += _value;
        cursorBalanceMap[_token][_cursor] += _value;
        _transferIn(_token, _depositor, _value);
    }

    function decreaseUserSeedContribution(IERC20 _token, address _user, uint _value) external isSetter {
        userSeedContributionMap[_token][_user] -= _value;
    }

    function setCursorBalance(IERC20 _token, uint _cursor, uint _value) external isSetter {
        cursorBalanceMap[_token][_cursor] = _value;
    }

    function getCursorBalance(IERC20 _token, uint _cursor) external view returns (uint) {
        return cursorBalanceMap[_token][_cursor];
    }

    function getCursorVeSupply(IERC20 _token, uint _cursor) external view returns (uint) {
        return cursorVeSupplyMap[_token][_cursor];
    }

    function getCursorVeSupplyAndBalance(IERC20 _token, uint _cursor) external view returns (uint _veSupply, uint _cursorBalance) {
        _veSupply = cursorVeSupplyMap[_token][_cursor];
        _cursorBalance = cursorBalanceMap[_token][_cursor];
    }

    function setVeSupply(IERC20 _token, uint _cursor, uint _value) external isSetter {
        cursorVeSupplyMap[_token][_cursor] = _value;
    }

    function transferOut(IERC20 _token, address _receiver, uint _value) external isSetter {
        _transferOut(_token, _receiver, _value);
    }

    function getSeedContributionList(
        IERC20 _token, //
        address[] calldata _userList
    ) external view returns (uint _totalAmount, uint[] memory _valueList) {
        uint _userListLength = _userList.length;

        _valueList = new uint[](_userListLength);
        _totalAmount = 0;

        for (uint i = 0; i < _userListLength; i++) {
            _valueList[i] = userSeedContributionMap[_token][_userList[i]];
            _totalAmount += _valueList[i];
        }
    }

    function getUserTokenCursor(IERC20 _token, address _account) external view returns (uint) {
        return userTokenCursorMap[_token][_account];
    }

    function setUserTokenCursor(IERC20 _token, address _account, uint _cursor) external isSetter {
        userTokenCursorMap[_token][_account] = _cursor;
    }

    error CugarStore__InvalidLength();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnershipTransferred(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function transferOwnership(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {Auth, Authority} from "@solmate/contracts/auth/Auth.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Router} from "../Router.sol";
import {StoreController} from "./StoreController.sol";

// @title Bank
// @dev Contract to handle storing and transferring of tokens
abstract contract BankStore is StoreController {
    mapping(IERC20 => uint) public tokenBalanceMap;

    Router router;

    constructor(Authority _authority, Router _router, address _initSetter) StoreController(_authority, _initSetter) {
        router = _router;
    }

    function getTokenBalance(IERC20 _token) external view returns (uint) {
        return tokenBalanceMap[_token];
    }

    function recordedTransferIn(IERC20 _token) public returns (uint) {
        return _recordTransferIn(_token);
    }

    function syncTokenBalance(IERC20 _token) external isSetter {
        tokenBalanceMap[_token] = _token.balanceOf(address(this));
    }

    function _transferOut(IERC20 _token, address _receiver, uint _value) internal {
        _token.transfer(_receiver, _value);
        tokenBalanceMap[_token] -= _value;
    }

    function _transferIn(IERC20 _token, address _user, uint _value) internal {
        router.transfer(_token, _user, address(this), _value);
        tokenBalanceMap[_token] += _value;
    }

    function _recordTransferIn(IERC20 _token) internal returns (uint) {
        uint prevBalance = tokenBalanceMap[_token];
        uint currentBalance = _syncTokenBalance(_token);

        return currentBalance - prevBalance;
    }

    function _syncTokenBalance(IERC20 _token) internal returns (uint) {
        uint currentBalance = _token.balanceOf(address(this));
        tokenBalanceMap[_token] = currentBalance;
        return currentBalance;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Auth, Authority} from "@solmate/contracts/auth/Auth.sol";

import {ExternalCallUtils} from "../utils/ExternalCallUtils.sol";

/**
 * @title Router
 * @dev Users will approve this router for token spenditures
 */
contract Router is Auth {
    uint transferGasLimit;

    constructor(Authority _authority, uint _trasnferGasLimit) Auth(address(0), _authority) {
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
    function transfer(IERC20 token, address from, address to, uint amount) external requiresAuth {
        ExternalCallUtils.callTarget(transferGasLimit, address(token), abi.encodeCall(token.transferFrom, (from, to, amount)));
    }

    function setTransferGasLimit(uint _trasnferGasLimit) external requiresAuth {
        transferGasLimit = _trasnferGasLimit;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {Auth, Authority} from "@solmate/contracts/auth/Auth.sol";

abstract contract StoreController is Auth {
    address public setter;

    modifier isSetter() {
        if (setter != msg.sender) revert Unauthorized(setter, msg.sender);
        _;
    }

    constructor(Authority _authority, address _setter) Auth(address(0), _authority) {
        setter = _setter;

        emit AssignSetter(address(0), _setter, block.timestamp);
    }

    function switchSetter(address nextSetter) external requiresAuth {
        address oldSetter = setter;
        setter = nextSetter;

        emit AssignSetter(oldSetter, nextSetter, block.timestamp);
    }

    event AssignSetter(address from, address to, uint timestamp);

    error Unauthorized(address currentSetter, address sender);
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