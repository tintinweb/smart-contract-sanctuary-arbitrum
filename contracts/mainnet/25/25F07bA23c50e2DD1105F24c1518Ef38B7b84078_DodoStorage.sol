/**
 *Submitted for verification at Arbiscan on 2023-07-06
*/

// SPDX-License-Identifier: MIT


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

pragma solidity ^0.8.0;

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
     * https:
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

pragma solidity >=0.4.22 <0.9.0;

struct PlayerData {
    uint256 dataVersion; 
    uint256 gameTimes; 
    uint256 casinoTimes; 
    uint256 incomeLevel; 
    uint256 bonusLevel; 
    uint256 bonus; 
}

struct PlayerStorage {
    PlayerData data;
    mapping (string => uint256) extraData;
}

interface DodoStorageInterface {

    function getPlayerExtraData(address player, string memory key) external view returns (uint256);

    function setPlayerExtraData(address player, string memory key, uint256 value) external;

    function getPlayerData(address player) external view returns (PlayerData memory);

    function updatePlayerData(
        address player,
        uint256 dataVersion,
        int256 gameTimesDelta,
        int256 casinoTimesDelta,
        int256 incomeLevelDelta,
        int256 bonusLevelDelta,
        int256 bonusDelta
    ) external;

    function transferCoin(address to, uint256 amount) external;

}

pragma solidity >=0.4.22 <0.9.0;

contract DodoStorage is Ownable, DodoStorageInterface {
  mapping(address => PlayerStorage) private playerStorage; 
  address public gameContract; 
  address public tokenContract; 

    
    modifier onlyGameContract() {
        require(
            msg.sender == gameContract,
            "MakeMoneyGameData: caller is not the game contract"
        );
        _;
    }

    
    function setGameContract(address _gameContract) public onlyOwner {
        gameContract = _gameContract;
    }

    
    function setTokenContract(address _tokenAddress) public onlyOwner {
        tokenContract = _tokenAddress;
    }

    
    function getPlayerData(address player) public view returns (PlayerData memory) {
        return playerStorage[player].data;
    }

    
    function updatePlayerData(
        address player,
        uint256 dataVersion,
        int256 gameTimesDelta,
        int256 casinoTimesDelta,
        int256 incomeLevelDelta,
        int256 bonusLevelDelta,
        int256 bonusDelta
    ) public onlyGameContract {
        PlayerData memory _data = playerStorage[player].data;
        require(_data.dataVersion == dataVersion, "MakeMoneyGameData: data version error"); 
        if(gameTimesDelta < 0) {
            playerStorage[player].data.gameTimes -= uint256(-gameTimesDelta);
        } else {
            playerStorage[player].data.gameTimes += uint256(gameTimesDelta);
        }
        if(casinoTimesDelta < 0) {
            playerStorage[player].data.casinoTimes -= uint256(-casinoTimesDelta);
        } else {
            playerStorage[player].data.casinoTimes += uint256(casinoTimesDelta);
        }
        if(incomeLevelDelta < 0) {
            playerStorage[player].data.incomeLevel -= uint256(-incomeLevelDelta);
        } else {
            playerStorage[player].data.incomeLevel += uint256(incomeLevelDelta);
        }
        if(bonusLevelDelta < 0) {
            playerStorage[player].data.bonusLevel -= uint256(-bonusLevelDelta);
        } else {
            playerStorage[player].data.bonusLevel += uint256(bonusLevelDelta);
        }
        if(bonusDelta < 0) {
            playerStorage[player].data.bonus -= uint256(-bonusDelta);
        } else {
            playerStorage[player].data.bonus += uint256(bonusDelta);
        }
        playerStorage[player].data.dataVersion += 1;
    }

    
    function getPlayerExtraData(address player, string memory key) public view returns (uint256) {
        return playerStorage[player].extraData[key];
    }

    
    function setPlayerExtraData(address player, string memory key, uint256 value) public onlyGameContract {
        playerStorage[player].extraData[key] = value;
    }

    
    function transferCoin(address to, uint256 amount) public onlyGameContract {
        IERC20(tokenContract).transfer(to, amount);
    }
}