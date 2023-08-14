//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IMasterChefV2, UserStruct, IRewarder} from "src/interfaces/IMasterChefV2.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract PatchOfThePatch is IMasterChefV2, Ownable {
    mapping(address => bool) public isAdapter;

    uint256 public constant DPX_FARM_PID = 17;
    uint256 public constant RDPX_FARM_PID = 23;

    address public constant DPX_LP = 0x0C1Cf6883efA1B496B01f654E247B9b419873054;
    address public constant RDPX_LP =
        0x7418F5A2621E13c05d1EFBd71ec922070794b90a;

    mapping(uint256 => mapping(address => uint256)) public balances;

    function adminDeposit(
        address _to,
        uint256 _amount,
        uint256 _pid
    ) external onlyOwner {
        if (_pid == DPX_FARM_PID) {
            IERC20(DPX_LP).transferFrom(msg.sender, address(this), _amount);
        } else {
            IERC20(RDPX_LP).transferFrom(msg.sender, address(this), _amount);
        }

        balances[_pid][_to] = _amount;
    }

    constructor(address[] memory _adapters) {
        for (uint256 i; i < _adapters.length; i++) {
            isAdapter[_adapters[i]] = true;
        }
    }

    function userInfo(
        uint256 _pid,
        address _user
    ) external view override returns (UserStruct.UserInfo memory) {
        return UserStruct.UserInfo(balances[_pid][_user], 0);
    }

    function pendingSushi(
        uint256 _pid,
        address _user
    ) external view override returns (uint256 pending) {}

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external override {
        require(isAdapter[msg.sender], "onlyAdapter()");

        if (pid == DPX_FARM_PID) {
            IERC20(DPX_LP).transferFrom(msg.sender, address(this), amount);
        } else {
            IERC20(RDPX_LP).transferFrom(msg.sender, address(this), amount);
        }

        balances[pid][msg.sender] = balances[pid][msg.sender] + amount;
    }

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external override {
        require(isAdapter[msg.sender], "onlyAdapter()");

        if (pid == DPX_FARM_PID) {
            IERC20(DPX_LP).transfer(to, amount);
        } else {
            IERC20(RDPX_LP).transfer(to, amount);
        }

        balances[pid][msg.sender] = balances[pid][msg.sender] - amount;
    }

    function harvest(uint256 pid, address to) external override {}

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external override {
        require(isAdapter[msg.sender], "onlyAdapter()");

        if (pid == DPX_FARM_PID) {
            IERC20(DPX_LP).transfer(to, amount);
        } else {
            IERC20(RDPX_LP).transfer(to, amount);
        }

        balances[pid][msg.sender] = balances[pid][msg.sender] - amount;
    }

    function rescue(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function updateMapping(
        address _adapter,
        bool _authorized
    ) external onlyOwner {
        isAdapter[_adapter] = _authorized;
    }

    function rewarder(
        uint256 _pid
    ) external view override returns (IRewarder) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
    function onSushiReward(uint256 pid, address user, address recipient, uint256 sushiAmount, uint256 newLpAmount)
        external;
    function pendingTokens(uint256 pid, address user, uint256 sushiAmount)
        external
        view
        returns (IERC20[] memory, uint256[] memory);
}

library UserStruct {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }
}

interface IMasterChefV2 {
    function userInfo(uint256 _pid, address _user) external view returns (UserStruct.UserInfo memory);

    function pendingSushi(uint256 _pid, address _user) external view returns (uint256 pending);

    function deposit(uint256 pid, uint256 amount, address to) external;

    function withdraw(uint256 pid, uint256 amount, address to) external;

    function harvest(uint256 pid, address to) external;

    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;

    function rewarder(uint256 _pid) external view returns (IRewarder);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}