// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract CABIN is Ownable {


    address public sheppard; //this is the address of who made the LP
    address public herd; //this is the LP token
    address public kindling; //this is the donation token
    uint256 public pyre; //this is the amount of donation required
    uint256 public woodpile; //this is the amount of donation already given
    uint256 public water; //this is the cooldown start time for rescuing the LP tokens

    bool public collectingWater; //this starts the cooldown on retrieveing the LPs
    bool public built; //used for init
    uint256 public immutable ONE_WEEK = 604800; //this is the delay on retrieving the LPs

    event cabinBurntDown(address _arsonist);
    event sheppardSavingCabin(uint256 _timestamp);
    event sheppardSavedCabin();
    event addedToWoodPile(uint256 _woodpile);

    /// @notice this function is used to initialize the cabin and set the params.
    function buildTheCabin(address _herd, address _kindling, uint256 _pyre, address _sheppard) public onlyOwner {
        require(!built, 'the cabin is immutable');
        herd = _herd;
        kindling = _kindling;
        pyre = _pyre;
        sheppard = _sheppard;
        built = true;
    }

    /// @notice this function is used by the LP owner to deposit the LP inside
    function sheppardGoHome(uint256 _amount) public onlyOwner {
        IERC20(herd).transferFrom(msg.sender, address(this), _amount);
    }
    /// @notice this function is used to check the balance of LP tokens in this contract
    function cabinBalance() public view returns(uint _cabinBal) {
        return IERC20(herd).balanceOf(address(this));
    }
    /// @notice this function is used to donate some WETH to the LP depositor, There are NO refunds.
    function addToWoodPile(uint256 _logs) public {
        require (IERC20(herd).balanceOf(address(this)) > 0, 'cabin is already burnt down');
        IERC20(kindling).transferFrom(msg.sender, sheppard, _logs);
        woodpile = woodpile + _logs;

        emit addedToWoodPile(woodpile);
    }
    /// @notice this function is used to send the LPs in the contract to the dead addres
    /// requires that enough WETH has been donated with addToWoodPile
    function burnTheCabin() public {
        require (woodpile >= pyre, 'there arent enough logs yet');
        uint256 herdSize = cabinBalance();
        IERC20(herd).transfer(0x000000000000000000000000000000000000dEaD, herdSize);

        emit cabinBurntDown(msg.sender);
    }
    /// @notice this function starts the cooldown period (1 week) for owner to retrieve LPs
    function collectWater() public onlyOwner {
        water = block.timestamp;
        collectingWater = true;

        emit sheppardSavingCabin(block.timestamp);
    }
    /// @notice after one week has passed, the owner can call this to retrieve the LP tokens. 
    function saveTheCabin() public onlyOwner {
        require (water + ONE_WEEK < block.timestamp, 'sheppard, you dont have enough water');
        require (collectingWater == true, 'sheppard, you didnt even start collecting water');
        uint256 herdSize = cabinBalance();
        IERC20(herd).transfer(sheppard, herdSize);

        emit sheppardSavedCabin();
    }


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