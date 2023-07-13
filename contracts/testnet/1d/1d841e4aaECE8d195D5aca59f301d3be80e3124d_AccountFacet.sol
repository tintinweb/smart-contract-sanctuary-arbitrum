// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PaymentStorage } from "../storage/PaymentStorage.sol";
import "../libraries/Structs.sol";

contract AccountFacet {

    error AddressIsZero();
    error InvalidAmount();
    error InvalidToken();
    error InvalidServiceID();
    error UnauthService();
    error ServiceTerminated();
    error InsufficientBalance();

    event DepositBalance(address indexed caller, address indexed token, uint amount);
    event DepositSecurity(address indexed caller, address token, uint amount, bytes32 id);
    event WithdrawBalance(address indexed caller, address indexed token, address indexed to, uint amount);
    event WithdrawSecurity(address indexed caller, address token, address indexed to, uint amount, bytes32 id);

    function getAccountType(address _user) external view returns (AccountType) {
        return PaymentStorage.layout().userAccounts[_user].accountType;
    }

    function getTokenBalance(address _user, address _token) external view returns (uint) {
        return PaymentStorage.layout().userAccounts[_user].balances[_token];
    }

    function getUserFeeDiscount(address _user) external view returns (uint) {
        return PaymentStorage.layout().userAccounts[_user].feeDiscount;
    }

    function getUserAccount(address _user, address[] calldata _tokens) external view returns (uint8, uint, uint[] memory) {
        Account storage account = PaymentStorage.layout().userAccounts[_user];
        uint len = _tokens.length;
        uint[] memory tokenBalance = new uint[](len);
        for (uint i; i < len; i++) {
            tokenBalance[i] = account.balances[_tokens[i]];
        }
        
        return (
            uint8(account.accountType),
            account.feeDiscount,
            tokenBalance
        );
    }

    function getService(bytes32 _id) external view returns (Service memory) {
        return PaymentStorage.layout().subscription[_id];
    }

    function getWithdrawSecurityQuota(bytes32 _id) external view returns (uint) {
        return _withdrawSecurityQuota(_id);
    }

    function isTerminated(bytes32 _id) external view returns (bool) {
        return PaymentStorage.layout().subscription[_id].terminated;
    }

    function depositBalance(address _token, uint _amount) external {
        if (_token == address(0)) revert AddressIsZero();
        if (_amount == 0) revert InvalidAmount();

        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        if (!layout.registeredToken[_token]) revert InvalidToken();
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // Overflow not possible: the sum of all balances is capped by usdt totalSupply, and the sum is preserved by
        unchecked {
            layout.userAccounts[msg.sender].balances[_token] += _amount;
        }

        emit DepositBalance(msg.sender, _token, _amount);
    }

    function depositSecurity(bytes32 _id, address _token, uint _amount) external {
        if (_id == bytes32(0)) revert InvalidServiceID();
        if (_amount == 0) revert InvalidAmount();

        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        Service storage service = layout.subscription[_id];
        if (service.terminated) revert ServiceTerminated();
        if (service.token != _token) revert InvalidToken();

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        service.security += _amount;

        emit DepositSecurity(msg.sender, _token, _amount, _id);
    }

    function withdrawBalance(address _token, address _to, uint _amount) external {
        if (_token == address(0)) revert AddressIsZero();
        if (_to == address(0)) revert AddressIsZero();
        if (_amount == 0) revert InvalidAmount();
        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        Account storage account = layout.userAccounts[msg.sender];
        if (account.balances[_token] < _amount) revert InsufficientBalance();

        IERC20(_token).transfer(_to, _amount);
        unchecked {
            account.balances[_token] -= _amount;
        }

        emit WithdrawBalance(msg.sender, _token, _to, _amount);
    }

    function withdrawSecurity(bytes32 _id, address _to, uint _amount) external {
        if (_id == bytes32(0)) revert InvalidServiceID();
        if (_to == address(0)) revert AddressIsZero();
        if (_amount == 0) revert InvalidAmount();
        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        Service storage service = layout.subscription[_id];
        if (service.buyer != msg.sender) revert UnauthService();
        if (service.terminated) revert ServiceTerminated();
        
        uint quota = _withdrawSecurityQuota(_id);
        if (quota < _amount) revert InsufficientBalance();
        IERC20(service.token).transfer(_to, _amount);

        unchecked {
            service.security -= _amount;
        }

        emit WithdrawSecurity(msg.sender, service.token, _to, _amount, _id);
    }

    function _withdrawSecurityQuota(bytes32 _id) internal view returns (uint) {
        Service memory service = PaymentStorage.layout().subscription[_id];
        unchecked {
            uint security = service.security;
            uint double = service.lastConsume * 2;
            return double < security ? security - double : 0;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum AccountType {
    Personal,
    Business
}

// user account
struct Account {
    AccountType accountType;
    uint feeDiscount;
    mapping(address => uint) balances;
}

struct Service {
    bool terminated;
    address token;
    address buyer;
    address seller;
    uint security;
    uint lastConsume;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../libraries/Structs.sol";

library PaymentStorage {

    bytes32 internal constant STORAGE_SLOT = keccak256('contracts.storage.Payment');

    struct Layout {
        address template;
        uint baseFee;
        mapping(address => bool) registeredToken;
        mapping(address => uint) protocolIncome;
        mapping(address => Account) userAccounts;
        mapping(bytes32 => Service) subscription;

        uint[60] _gaps;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}