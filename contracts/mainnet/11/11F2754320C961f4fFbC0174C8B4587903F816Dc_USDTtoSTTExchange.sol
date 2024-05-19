// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Access control contract,
 * functions names are self explanatory
 */
contract AccessControl {
    modifier onlyOwner() {
        require(msg.sender == _owner, 'Caller is not the owner');
        _;
    }
    modifier hasRole(bytes32 role) {
        require(_checkRole(role, msg.sender), 'Caller is not authorized for this action'
        );
        _;
    }

    mapping (bytes32 => mapping(address => bool)) internal _roles;
    address internal _owner;

    constructor () {
        _owner = msg.sender;
    }

    /**
     * @dev Transfer ownership to another account
     */
    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), 'newOwner should not be zero address');
        _owner = newOwner;
        return true;
    }

    /**
     * @dev Grant role to account
     */
    function _grantRole (
        bytes32 role,
        address userAddress
    ) internal returns (bool) {
        _roles[role][userAddress] = true;
        return true;
    }

    /**
     * @dev Grant role to account
     */
    function grantRole (
        string memory role,
        address userAddress
    ) external onlyOwner returns (bool) {
        _grantRole(keccak256(abi.encode(role)), userAddress);
        return true;
    }

    /**
     * @dev Revoke role from account
     */
    function _revokeRole (
        bytes32 role,
        address userAddress
    ) internal returns (bool) {
        _roles[role][userAddress] = false;
        return true;
    }

    /**
     * @dev Revoke role from account
     */
    function revokeRole (
        string memory role,
        address userAddress
    ) external onlyOwner returns (bool) {
        _revokeRole(keccak256(abi.encode(role)), userAddress);
        return true;
    }

    /**
     * @dev Check is account has specific role
     */
    function _checkRole (
        bytes32 role,
        address userAddress
    ) internal view returns (bool) {
        return _roles[role][userAddress];
    }

    /**
     * @dev Check is account has specific role
     */
    function checkRole (
        string memory role,
        address userAddress
    ) external view returns (bool) {
        return _checkRole(keccak256(abi.encode(role)), userAddress);
    }

    /**
     * @dev Owner address getter
     */
    function owner() public view returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import './TransferHelper.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Utils is ReentrancyGuard {
    function _takeAsset (
        address tokenAddress, address fromAddress, uint256 amount
    ) internal returns (bool) {
        require(tokenAddress != address(0), 'Token address should not be zero');
        TransferHelper.safeTransferFrom(
            tokenAddress, fromAddress, address(this), amount
        );
        return true;
    }

    function _sendAsset (
        address tokenAddress, address toAddress, uint256 amount
    ) internal nonReentrant returns (bool) {
        if (tokenAddress == address(0)) {
            require(address(this).balance >= amount,
                'Not enough contract balance');
            payable(toAddress).transfer(amount);
        } else {
            TransferHelper.safeTransfer(
                tokenAddress, toAddress, amount
            );
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './common/AccessControl.sol';
import './common/Utils.sol';

interface ISTTExchange {
  function swap (uint256) external;
  function deposit (uint256) external;
}

/**
 * @dev Exchange contract,
 * functions names are self explanatory
 */
contract USDTtoSTTExchange is AccessControl, Utils {
  ISTTExchange public sttExchange;
  IERC20 public usdtToken;
  IERC20 public sttToken;
  address public burnSttAutomationContractAddress;
  address public depositUsdtAutomationContractAddress;
  uint256 public minUsdt;
  uint256 public factor; // with 18 decimals
  uint256 internal constant MULTIPLICATOR = 1 ether;
  uint256 internal constant MAX_INT = 
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  constructor (
    address ownerAddress,
    address sttExchangeAddress,
    address usdtTokenAddress,
    address sttTokenAddress,
    uint256 _factor,
    uint256 _minUsdt
  ) {
    require(ownerAddress != address(0), 'ownerAddress can not be zero');
    require(sttExchangeAddress != address(0), 'sttExchangeAddress can not be zero');
    require(usdtTokenAddress != address(0), 'usdtTokenAddress can not be zero');
    require(_factor >= 0.1 ether, 'Should be greater than or equal to 0.1');
    require(_factor <= 1 ether, 'Should be less than or equal to 1');
    require(sttTokenAddress != address(0), 'sttTokenAddress can not be zero');
    _owner = ownerAddress;
    sttExchange = ISTTExchange(sttExchangeAddress);
    usdtToken = IERC20(usdtTokenAddress);
    sttToken = IERC20(sttTokenAddress);
    minUsdt = _minUsdt;
    factor = _factor;
    sttToken.approve(sttExchangeAddress, MAX_INT);
    usdtToken.approve(sttExchangeAddress, MAX_INT);
  }

  function swap (uint256 usdtAmount) external returns (bool) {
    require(usdtAmount >= minUsdt, 'Less than minimal amount');
    uint256 sttAmount = usdtAmount
      * sttToken.totalSupply()
      / usdtToken.balanceOf(address(sttExchange))
      * factor
      / MULTIPLICATOR;
    require(sttAmount <= sttToken.balanceOf(address(this)), 'Not enough STT');
    require(_takeAsset(address(usdtToken), msg.sender, usdtAmount));
    require(_sendAsset(address(sttToken), msg.sender, sttAmount));
    return true;
  }

  function setFactor (
    uint256 _factor
  ) external onlyOwner returns (bool) {
    require(_factor >= 0.1 ether, 'Should be greater than or equal to 0.1');
    require(_factor <= 1 ether, 'Should be less than or equal to 1');
    factor = _factor;
    return true;
  }

  function setMinUsdt (
    uint256 _minUsdt
  ) external onlyOwner returns (bool) {
    minUsdt = _minUsdt;
    return true;
  }

  function adminWithdraw (
    address paymentToken, uint256 amount
  ) external onlyOwner returns (bool) {
    require (amount > 0, 'Amount should be greater than zero');
    _sendAsset(paymentToken, msg.sender, amount);
    return true;
  }

  function _burnStt () internal returns (bool) {
    uint256 sttAmount = sttToken.balanceOf(address(this));
    sttExchange.swap(sttAmount);
    return true;
  }

  function _depositUsdt () internal returns (bool) {
    uint256 usdtAmount = usdtToken.balanceOf(address(this));
    sttExchange.deposit(usdtAmount);
    return true;
  }

  function burnStt () external onlyOwner returns (bool) {
    return _burnStt();
  }

  function depositUsdt () external onlyOwner returns (bool) {
    return _depositUsdt();
  }

  function setBurnSttAutomationContractAddress (
    address _burnSttAutomationContractAddress
  ) external onlyOwner returns (bool) {
    burnSttAutomationContractAddress = _burnSttAutomationContractAddress;
    return true;
  }

  function setDepositUsdtAutomationContractAddress (
    address _depositUsdtAutomationContractAddress
  ) external onlyOwner returns (bool) {
    depositUsdtAutomationContractAddress = _depositUsdtAutomationContractAddress;
    return true;
  }

  function burnSttAutomation () external returns (bool) {
    require(msg.sender == burnSttAutomationContractAddress, 'Not allowed');
    return _burnStt();
  }

  function depositUsdtAutomation () external returns (bool) {
    require(msg.sender == depositUsdtAutomationContractAddress, 'Not allowed');
    return _depositUsdt();
  }
}