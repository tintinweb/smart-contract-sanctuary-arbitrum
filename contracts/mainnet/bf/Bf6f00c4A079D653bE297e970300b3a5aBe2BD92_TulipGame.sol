// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TulipGame is Ownable {

    enum ETulipGameStatus {
        NotStart,
        InjectDivinePower,
        CaressTulipBlessing
    }

    ETulipGameStatus public TulipGameStatus;

    uint256 public singleTulipPowerPrice = 0.01 ether;

    uint256 public singleTulipToken = 70_000_000 ether;
    uint256 public remainTulipPowerCopies = 10000;
    mapping(address => uint256) public injectUserInfos;

    uint256 public holyMoment = 6 * 60 * 60;

    uint256 public lastUserCaressTulipTimestamp;
    address public currentHolyMessenger;
    uint256 public currentCaressTulipPrice;
    uint256 public currentRound = 1;
    mapping(uint256 => address) public holyMessengers;
    mapping(uint256 => mapping(address => uint256)) public currentPlayerInfo;

    address public teamAddress;
    address public liquidityLock;
    address public routerAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public tulipCoin;
    address public tulipGameFeeAddress;

    event eveInjectDivinePower(address account, uint256 quantity);
    event eveKissTulip(address newAccount, uint256 amount, uint256 tulipTimestamp, address lastAccount);
    event eveKissTulipWin(address account, uint256 amount, uint256 timestamp);

    constructor(address TeamAddress_, address liquidityLock_) {
        teamAddress = TeamAddress_;
        liquidityLock = liquidityLock_;
    }


    receive() payable external {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }


    function InjectDivinePower(uint256 _quantity) payable public callerIsUser {
        require(TulipGameStatus == ETulipGameStatus.InjectDivinePower, "Not in the stage of injecting divine power.");
        require(remainTulipPowerCopies >= _quantity, "The number of divine blessings has been fully subscribed.");
        require(injectUserInfos[msg.sender] + _quantity <= 10, "Each address can inject up to 10 units of energy. Please enter the correct number.");
        require(msg.value >= _quantity * singleTulipPowerPrice, "You don't have enough Ether divine power, please practice to obtain it.");
        if (msg.value > _quantity * singleTulipPowerPrice) {
            (bool success,) = msg.sender.call{value : msg.value - _quantity * singleTulipPowerPrice}("");
            require(success, "Transfer failed.");
        }
        IERC20(tulipCoin).transfer(msg.sender, _quantity * singleTulipToken);
        remainTulipPowerCopies -= _quantity;
        emit eveInjectDivinePower(msg.sender, _quantity);
        injectUserInfos[msg.sender] += _quantity;
        if (remainTulipPowerCopies == 0) {
            TulipGameStatus = ETulipGameStatus.CaressTulipBlessing;
            currentHolyMessenger = teamAddress;
            currentCaressTulipPrice = singleTulipToken;
            lastUserCaressTulipTimestamp = block.timestamp;
            (bool openTransferSuccess,) = address(tulipCoin).call(abi.encodeWithSignature("openTransfer()"));
            require(openTransferSuccess, "openTransfer failed");
            uint256 amountTokenDesired = 250_000_000_000 ether;
            uint256 poolReward = 40 ether;
            IERC20(tulipCoin).approve(address(routerAddress), amountTokenDesired);
            (bool success,) = payable(address(routerAddress)).call{value : poolReward}(
                abi.encodeWithSignature("addLiquidityETH(address,uint256,uint256,uint256,address,uint256)",
                tulipCoin, amountTokenDesired, amountTokenDesired, poolReward, liquidityLock, block.timestamp)
            );
            require(success, "addLiquidityETHCaller failed");
        }
    }

    function KissTulip() payable public callerIsUser {
        if (block.timestamp > lastUserCaressTulipTimestamp + holyMoment) {
            require(TulipGameStatus == ETulipGameStatus.CaressTulipBlessing, "Not in the stage of caressing Tulip blessing.");
            uint256 totalbalance = address(this).balance;
            uint256 rewardBalance = totalbalance * 80 / 100;
            (bool success,) = currentHolyMessenger.call{value : rewardBalance}("");
            require(success, "Failed to obtain divine envoy reward.");
            holyMessengers[currentRound] = currentHolyMessenger;
            currentRound++;
            currentHolyMessenger = teamAddress;
            currentCaressTulipPrice = singleTulipToken;
            lastUserCaressTulipTimestamp = block.timestamp;
            emit eveKissTulipWin(msg.sender, rewardBalance, block.timestamp);
        } else {
            require(TulipGameStatus == ETulipGameStatus.CaressTulipBlessing, "Not in the stage of caressing Tulip blessing.");
            require(IERC20(tulipCoin).balanceOf(msg.sender) >= currentCaressTulipPrice, "You don't have enough $TLIP, please buy it by DEX.");
            require(currentPlayerInfo[currentRound][msg.sender] <= 10, "In this round, you can kiss tulips up to 10 times at most. Please switch accounts.");
            uint256 lastCaressTulipPrice = currentCaressTulipPrice - singleTulipToken;
            uint256 holyCashback = singleTulipToken * 25 / 100;
            uint256 teamCashBack = singleTulipToken * 15 / 100;
            uint256 poolCashBack = singleTulipToken * 50 / 100;
            uint256 deathBurnBack = singleTulipToken * 10 / 100;
            emit eveKissTulip(msg.sender, currentCaressTulipPrice, block.timestamp, currentHolyMessenger);
            IERC20(tulipCoin).transferFrom(msg.sender, address(this), currentCaressTulipPrice);
            IERC20(tulipCoin).transfer(currentHolyMessenger, lastCaressTulipPrice + holyCashback);
            IERC20(tulipCoin).transfer(teamAddress, teamCashBack);
            IERC20(tulipCoin).transfer(tulipGameFeeAddress, poolCashBack);
            IERC20(tulipCoin).transfer(address(0x000000000000000000000000000000000000dEaD), deathBurnBack);
            currentHolyMessenger = msg.sender;
            currentCaressTulipPrice += singleTulipToken;
            lastUserCaressTulipTimestamp = block.timestamp;
            currentPlayerInfo[currentRound][msg.sender]++;
        }

    }


    function StartTulipGame() external onlyOwner {
        require(TulipGameStatus == ETulipGameStatus.NotStart, "Not in the stage of NotStart.");
        TulipGameStatus = ETulipGameStatus.InjectDivinePower;
    }

    function SetTulipCoin(address tulipCoin_) external onlyOwner {
        tulipCoin = tulipCoin_;
    }

    function SetTulipGameFeeAddress(address tulipGameFeeAddress_) external onlyOwner {
        tulipGameFeeAddress = tulipGameFeeAddress_;
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