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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';

import {IRandomizer} from "../interfaces/IRandomizer.sol";
import {IL2Unicorn} from "../interfaces/IL2Unicorn.sol";

contract L2UnicornMinter is Ownable {

    address public l2Unicorn;

    address public l2;

    uint256 public costAmount;

    struct LotteryInfo {
        address user;
        uint256 seed;
        uint256 result;
    }

    event Lottery(address indexed user, uint256 indexed id);

    event LotteryResult(address indexed user, uint256 indexed id, uint256 seed, uint256 result, uint256 tokenId);

    mapping(uint256 => LotteryInfo) LotteryInfoMapping;

    mapping(address => uint256[]) userLotteryIdsMapping;

    mapping(uint256 => uint256) private levelTokenId;

    IRandomizer private _randomizer;

    constructor(address randomizer_, address l2Unicorn_, address l2_) {
        _randomizer = IRandomizer(randomizer_);
        l2Unicorn = l2Unicorn_;
        l2 = l2_;
        costAmount = 10e18;
    }

    function setCostAmount(uint256 costAmount_) public onlyOwner {
        require(costAmount_ > 0, "L2Unicorn: cost amount is zero");
        costAmount = costAmount_;
    }

    function lottery() external {
        require(!Pausable(l2Unicorn).paused(), "L2UnicornMinter: L2Unicorn already paused");
        IERC20(l2).transferFrom(_msgSender(), address(this), costAmount);
        uint256 id = IRandomizer(_randomizer).request(100000);
        userLotteryIdsMapping[msg.sender].push(id);
        LotteryInfoMapping[id] = LotteryInfo(msg.sender, 0, 0);
        emit Lottery(msg.sender, id);
    }

    function randomizerCallback(uint256 _id, bytes32 _value) external {
        require(msg.sender == address(_randomizer), "L2UnicornMinter: caller isn't randomizer contract");
        LotteryInfo storage lotteryInfo = LotteryInfoMapping[_id];
        uint256 seed = uint256(_value);
        lotteryInfo.seed = seed;
        uint256 result = getResult(seed);
        lotteryInfo.result = result;
        //tokenId
        uint256 tokenId = _getTokenIdByRandomNumber(lotteryInfo.result);
        //mint nft
        IL2Unicorn(l2Unicorn).mintForMinter(lotteryInfo.user, tokenId);
        //
        emit LotteryResult(lotteryInfo.user, _id, seed, result, tokenId);
    }

    function getResult(uint256 seed) public pure returns (uint256) {
        return seed % 1e8;
    }

    function getLotteryInfo(uint256 _id) external view returns (LotteryInfo memory) {
        return LotteryInfoMapping[_id];
    }

    function getUserLotteryIds(address _player) external view returns (uint256[] memory){
        return userLotteryIdsMapping[_player];
    }

    function previewResult(bytes32 _value) external pure returns (bool) {
        bool headsOrTails = (uint256(_value) % 2 == 0);
        return headsOrTails;
    }

    function depositFund() external payable {
        IRandomizer(_randomizer).clientDeposit{value : msg.value}(address(this));
    }

    function withdrawFund(uint256 amount) external onlyOwner {
        IRandomizer(_randomizer).clientWithdrawTo(msg.sender, amount);
    }

    function balanceOfFund() external view returns (uint256, uint256){
        return IRandomizer(_randomizer).clientBalanceOf(address(this));
    }

    function estimateFee(uint256 callbackGasLimit) external view returns (uint256) {
        return IRandomizer(_randomizer).estimateFee(callbackGasLimit);
    }

    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256) {
        return IRandomizer(_randomizer).estimateFee(callbackGasLimit, confirmations);
    }

    function estimateFeeUsingGasPrice(uint256 callbackGasLimit, uint256 gasPrice) external view returns (uint256) {
        return IRandomizer(_randomizer).estimateFeeUsingGasPrice(callbackGasLimit, gasPrice);
    }

    function estimateFeeUsingConfirmationsAndGasPrice(uint256 callbackGasLimit, uint256 confirmations, uint256 gasPrice) external view returns (uint256) {
        return IRandomizer(_randomizer).estimateFeeUsingConfirmationsAndGasPrice(callbackGasLimit, confirmations, gasPrice);
    }

    function getLevelInfo(uint256 randomNumber) public pure returns (uint, uint, uint) {
        if (randomNumber >= 1 && randomNumber <= 4388888500) {
            return (0, 100000000001, 200000000000);
        } else if (randomNumber >= 4388888501 && randomNumber <= 9388888500) {
            return (1, 10000000001, 20000000000);
        } else if (randomNumber >= 9388888501 && randomNumber <= 9888888500) {
            return (2, 1000000001, 2999900000);
        } else if (randomNumber >= 9888888501 && randomNumber <= 9988888500) {
            return (3, 100000001, 200000000);
        } else if (randomNumber >= 9988888501 && randomNumber <= 9998888500) {
            return (4, 10000001, 20000000);
        } else if (randomNumber >= 9998888501 && randomNumber <= 9999888500) {
            return (5, 1000001, 2000000);
        } else if (randomNumber >= 9999888501 && randomNumber <= 9999988500) {
            return (6, 100001, 200000);
        } else if (randomNumber >= 9999988501 && randomNumber <= 9999998500) {
            return (7, 10001, 20000);
        } else if (randomNumber >= 9999998501 && randomNumber <= 9999999500) {
            return (8, 1001, 2000);
        } else if (randomNumber >= 9999999501 && randomNumber <= 10000000000) {
            return (9, 1, 500);
        } else {
            return (type(uint).max, 0, 0);
        }
    }

    function _getTokenIdByRandomNumber(uint256 randomNumber) private returns (uint256) {
        (uint level, uint startTokenId, uint endTokenId) = getLevelInfo(randomNumber);
        uint256 tokenId;
        if (level != type(uint8).max) {
            if (levelTokenId[level] == 0) {
                levelTokenId[level] = startTokenId;
            }
            tokenId = levelTokenId[level];
            if (tokenId <= endTokenId) {
                unchecked {levelTokenId[level]++;}
            } else {
                tokenId = 0;
            }
        } else {
            tokenId = 0;
        }
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IL2Unicorn {

    function minter() external view returns (address);

    function mintForMinter(address to_, uint256 tokenId_) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRandomizer {

    function request(uint256 callbackGasLimit) external returns (uint256);

    function clientDeposit(address client) external payable;

    function clientWithdrawTo(address to, uint256 amount) external;

    function clientBalanceOf(address client) external view returns (uint256, uint256);

    function estimateFee(uint256 callbackGasLimit) external view returns (uint256);

    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256);

    function estimateFeeUsingGasPrice(uint256 callbackGasLimit, uint256 gasPrice) external view returns (uint256);

    function estimateFeeUsingConfirmationsAndGasPrice(uint256 callbackGasLimit, uint256 confirmations, uint256 gasPrice) external view returns (uint256);

}