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

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IClaim {
    function claim(address _recipient) external returns (uint256 claimed);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import { IClaim } from "../../interfaces/IClaim.sol";
import { ICommonReward } from "./ICommonReward.sol";

interface IBaseReward is ICommonReward, IClaim {
    function stakeFor(address _recipient, uint256 _amountIn) external;

    function withdraw(uint256 _amountOut) external returns (uint256);

    function withdrawFor(address _recipient, uint256 _amountOut) external returns (uint256);

    function pendingRewards(address _recipient) external view returns (uint256);

    function balanceOf(address _recipient) external view returns (uint256);

    event StakeFor(address indexed _recipient, uint256 _amountIn, uint256 _totalSupply, uint256 _totalUnderlying);
    event Withdraw(address indexed _recipient, uint256 _amountOut, uint256 _totalSupply, uint256 _totalUnderlying);
    event Claim(address indexed _recipient, uint256 _claimed);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ICommonReward {
    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function distribute(uint256 _rewards) external;

    event Distribute(uint256 _rewards, uint256 _totalSupply, uint256 _accRewardPerShare);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IStorageAddresses {
    function setAddress(address _finder, address _storageAddress, bool _force) external;

    function setAddress(bytes32 _key, address _storageAddress, bool _force) external;

    function getAddress(address _finder) external view returns (address);

    function getAddress(bytes32 _key) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IAbstractVault {
    function borrow(uint256 _borrowedAmount) external returns (uint256);

    function repay(uint256 _borrowedAmount, uint256 _repayAmountDuringLiquidation, bool _liquidating) external;

    function supplyRewardPool() external view returns (address);

    function borrowedRewardPool(address _creditManager) external view returns (address);

    function borrowedRewardPool() external view returns (address);

    function underlyingToken() external view returns (address);

    function rewardPools() external view returns (address);

    function verificationRuler() external view returns (address);

    function creditManagersShareLocker(address _creditManager) external view returns (address);

    function creditManagersCanBorrow(address _creditManager) external view returns (bool);

    function creditManagersCanRepay(address _creditManager) external view returns (bool);

    event AddLiquidity(address indexed _recipient, uint256 _amountIn, uint256 _timestamp);
    event RemoveLiquidity(address indexed _recipient, uint256 _amountOut, uint256 _timestamp);
    event Borrow(address indexed _creditManager, uint256 _borrowedAmount);
    event Repay(address indexed _creditManager, uint256 _borrowedAmount, uint256 _repayAmountDuringLiquidatio, bool _liquidating);
    event SetRewardTracker(address _tracker);
    event SetVerificationRuler(address _ruler);
    event AddCreditManager(address _creditManager, address _shareLocker);
    event ToggleCreditManagerToBorrow(address _creditManager, bool _oldState);
    event ToggleCreditManagersCanRepay(address _creditManager, bool _oldState);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IVerificationRuler {
    function canBorrow(address _vault, uint256 _borrowedAmount) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IAbstractVault as IOriginAbstractVault } from "./interfaces/IAbstractVault.sol";
import { IVerificationRuler } from "./interfaces/IVerificationRuler.sol";
import { IStorageAddresses } from "../storages/interfaces/IStorageAddresses.sol";
import { IBaseReward as IOriginBaseReward } from "../rewards/interfaces/IBaseReward.sol";

interface IAbstractVault is IOriginAbstractVault, IERC20 {
    function creditManagersCount() external view returns (uint256);

    function creditManagers(uint256 _idx) external view returns (address);
}

contract VerificationRuler is IVerificationRuler, Ownable {
    uint256 public maxRatio = 90;

    event SetMaxRatio(uint256 _maxRatio);

    constructor(uint256 _maxRatio) {
        maxRatio = _maxRatio;
    }

    function setMaxRatio(uint256 _maxRatio) public onlyOwner {
        require(_maxRatio > 50, "VerificationRuler: The maximum ratio must be greater than 50");

        maxRatio = _maxRatio;

        emit SetMaxRatio(maxRatio);
    }

    function canBorrow(address _vault, uint256 _borrowedAmount) external view override returns (bool) {
        uint256 creditManagersCount = IAbstractVault(_vault).creditManagersCount();
        address rewardPools = IAbstractVault(_vault).rewardPools();
        address supplyRewardPool = IStorageAddresses(rewardPools).getAddress(_vault);
        uint256 denominator = IAbstractVault(_vault).balanceOf(supplyRewardPool);
        uint256 numerator = _borrowedAmount;

        address[] memory borrowedRewardPools = new address[](creditManagersCount);

        for (uint256 i = 0; i < creditManagersCount; i++) {
            address creditManager = IAbstractVault(_vault).creditManagers(i);
            address borrowedRewardPool = IStorageAddresses(rewardPools).getAddress(creditManager);

            for (uint256 j = 0; j < borrowedRewardPools.length; j++) {
                if (borrowedRewardPools[j] == borrowedRewardPool) break;
                else borrowedRewardPools[i] = borrowedRewardPool;
            }
        }

        for (uint256 i = 0; i < borrowedRewardPools.length; i++) {
            if (borrowedRewardPools[i] == address(0)) continue;
            numerator += IAbstractVault(_vault).balanceOf(borrowedRewardPools[i]);
        }

        uint256 ratio = (((numerator * 1e18) / denominator) * 100) / 1e18;

        if (ratio >= maxRatio) return false;

        return true;
    }
}