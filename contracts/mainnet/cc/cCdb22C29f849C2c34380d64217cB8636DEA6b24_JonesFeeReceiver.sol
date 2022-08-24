// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFeeReceiver} from "../interfaces/IFeeReceiver.sol";

contract JonesFeeReceiver is IFeeReceiver, Ownable {
    // Registry of allowed depositors
    mapping(address => bool) public depositors;

    /**
     * @param _governor The address of the owner of this contract
     */
    constructor(address _governor) {
        _transferOwnership(_governor);
    }

    /**
     * @notice To enforce only allowed depositors to deposit funds
     */
    modifier onlyDepositors() {
        if (!depositors[msg.sender]) {
            revert NotAuthorized();
        }
        _;
    }

    /**
     * @notice Used by depositors to deposit fees
     * @param _token the address of the asset to be deposited
     * @param _amount the amount of `_token` to deposit
     */
    function deposit(address _token, uint256 _amount) external onlyDepositors {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _token, _amount);
    }

    /**
     * @notice Used to register new depositors
     * @param _depositor the address of the new depositor
     */
    function addDepositor(address _depositor) external onlyOwner {
        _isValidAddress(_depositor);

        depositors[_depositor] = true;

        emit DepositorAdded(msg.sender, _depositor);
    }

    /**
     * @notice Used to remove depositors
     * @param _depositor the address of the depositor to remove
     */
    function removeDepositor(address _depositor) external onlyOwner {
        depositors[_depositor] = false;

        emit DepositorRemoved(msg.sender, _depositor);
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function withdraw(
        address _to,
        address[] memory _assets,
        bool _withdrawNative
    ) external onlyOwner {
        _isValidAddress(_to);

        for (uint256 i; i < _assets.length; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            // No need to transfer
            if (assetBalance == 0) {
                continue;
            }

            // Transfer the ERC20 tokens
            asset.transfer(_to, assetBalance);
        }

        uint256 nativeBalance = address(this).balance;

        // Nothing else to do
        if (_withdrawNative && nativeBalance > 0) {
            // Transfer the native currency
            payable(_to).transfer(nativeBalance);
        }

        emit Withdrawal(msg.sender, _to, _assets, _withdrawNative);
    }

    function _isValidAddress(address _address) internal {
        if (_address == address(0)) {
            revert InvalidAddress();
        }
    }

    /**
     * @notice Emitted when a depositor deposits fees
     * @param depositor the contract that deposited
     * @param token the address of the asset that was deposited
     * @param amount the amount of `token` that was deposited
     */
    event Deposit(
        address indexed depositor,
        address indexed token,
        uint256 amount
    );

    /**
     * @notice Emitted when a new depositor is registered
     * @param owner the current owner of this contract
     * @param depositor the address of the new depositor
     */
    event DepositorAdded(address indexed owner, address indexed depositor);

    /**
     * @notice Emitted when a new depositor is registered
     * @param owner the current owner of this contract
     * @param depositor the address of the new depositor
     */
    event DepositorRemoved(address indexed owner, address indexed depositor);

    event Withdrawal(
        address owner,
        address receiver,
        address[] assets,
        bool includeNative
    );

    error NotAuthorized();
    error InvalidAddress();
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IFeeReceiver {
    function deposit(address _token, uint256 _amount) external;
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