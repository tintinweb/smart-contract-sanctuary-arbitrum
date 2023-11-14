/**
 *Submitted for verification at Arbiscan.io on 2023-11-14
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
pragma solidity ^0.8.14;

contract PharosVault is Ownable {
    PharosStatus public PharosGameStatus;

    uint256 public roundPharosTimestamp;
    uint256 public endTimestamp;
    address public currentHolyMessenger;
    uint256 public currentCaressPharosPrice;
    uint256 public currentRound = 1;
    uint256 private _status;

    uint256 public singlePharosPowerPrice = 0.02 ether;
    uint256 public gamePharosToken = 100_000 ether;
    uint256 public singlePharosToken = 500_000 ether;
    uint256 public remainPharosPowerCopies = 7500;
    mapping(address => uint256) public injectUserInfos;

    uint256 public holyMoment = 8 * 60 * 60;
    uint256 public addMoment = 0;

    mapping(uint256 => address) public holyMessengers;
    mapping(uint256 => mapping(address => uint256)) public currentPlayerInfo;

    address public teamAddress;
    address public PharosCoin;
    address public PharosGameFeeAddress;

    event eveBestowPower(address account, uint256 quantity);
    event evePharosSoul(
        address newAccount,
        uint256 amount,
        uint256 PharosTimestamp,
        address lastAccount
    );
    event evePharosSoulWin(address account, uint256 amount, uint256 timestamp);
    event Swept(address indexed sender, uint256 amount);
    enum PharosStatus {
        NotStart,
        GamePause,
        BestowPower,
        PrayPharosPower
    }

    constructor(address TeamAddress_) {
        teamAddress = TeamAddress_;
    }

    receive() external payable {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Invalid");
        _;
    }
    modifier nonReentrant() {
        require(_status == 0, "ReentrancyGuard: reentrant call");
        _status = 1;
        _;
        _status = 0;
    }

    function StartPower() external onlyOwner {
        require(
            PharosGameStatus == PharosStatus.NotStart,
            "Not in the stage of NotStart."
        );
        PharosGameStatus = PharosStatus.BestowPower;
    }

    function BestowPower(
        uint256 _quantity,
        address inviter
    ) public payable callerIsUser nonReentrant {
        require(
            PharosGameStatus == PharosStatus.BestowPower,
            "Not in the stage of BestowPower."
        );
        require(remainPharosPowerCopies >= _quantity, "The numbers exceed.");
        require(
            injectUserInfos[msg.sender] + _quantity <= 20,
            "Number exceeds maximum single address limit."
        );
        require(
            msg.value >= _quantity * singlePharosPowerPrice,
            "Not enough Ether."
        );
        if (msg.value > _quantity * singlePharosPowerPrice) {
            (bool success, ) = msg.sender.call{
                value: msg.value - _quantity * singlePharosPowerPrice
            }("");
            require(success, "Transfer failed.");
        }
        IERC20(PharosCoin).transfer(msg.sender, _quantity * singlePharosToken);
        remainPharosPowerCopies -= _quantity;
        emit eveBestowPower(msg.sender, _quantity);
        injectUserInfos[msg.sender] += _quantity;
        //inviter reward
        if (inviter != address(0) && msg.sender != inviter) {
            (bool success, ) = inviter.call{
                value: (_quantity * singlePharosPowerPrice) / 20
            }("");
            require(success, "Transfer failed.");
        }
    }

    function PausePharosGame() external onlyOwner {
        require(
            PharosGameStatus == PharosStatus.BestowPower,
            "Not in the stage of BestowPower."
        );
        PharosGameStatus = PharosStatus.GamePause;
    }

    function CancelPausePharosGame() external onlyOwner {
        require(
            PharosGameStatus == PharosStatus.GamePause,
            "Not in the stage of GamePause."
        );
        PharosGameStatus = PharosStatus.BestowPower;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function sweep(address payable to) external onlyOwner {
        require(to != address(0), "Mint: ADDRESS_INVALID");
        uint256 minttotal = address(this).balance;
        uint256 fortyEther = 40e18;
        uint256 poolreward = min(fortyEther, (minttotal * 40) / 100);
        uint256 ebal = minttotal - poolreward;
        to.transfer(ebal);

        uint256 bal = IERC20(PharosCoin).balanceOf(address(this));
        if (bal > 0) {
            IERC20(PharosCoin).transfer(to, bal);
        }

        emit Swept(to, ebal);
    }

    function startGame() external {
        require(msg.sender == owner(), "Not the correct address.");
        require(
            PharosGameStatus == PharosStatus.GamePause,
            "Not in the stage of GamePause."
        );
        PharosGameStatus = PharosStatus.PrayPharosPower;
        currentHolyMessenger = teamAddress;
        currentCaressPharosPrice = gamePharosToken;
        roundPharosTimestamp = block.timestamp;
        (bool openTransferSuccess, ) = address(PharosCoin).call(
            abi.encodeWithSignature("openTransfer()")
        );
        require(openTransferSuccess, "openTransfer failed");
    }

    function PharosSoul() public payable callerIsUser {
        if (block.timestamp > roundPharosTimestamp + holyMoment + addMoment) {
            require(
                PharosGameStatus == PharosStatus.PrayPharosPower,
                "Not in the stage of PrayPharosPower."
            );
            uint256 totalbalance = address(this).balance;
            uint256 rewardBalance = (totalbalance * 20) / 100;
            (bool success, ) = currentHolyMessenger.call{value: rewardBalance}(
                ""
            );
            require(success, "Failed to obtain divine envoy reward.");
            uint256 tokenbalance = IERC20(PharosCoin).balanceOf(address(this));
            IERC20(PharosCoin).transfer(currentHolyMessenger, tokenbalance);
            holyMessengers[currentRound] = currentHolyMessenger;
            currentRound++;
            currentHolyMessenger = teamAddress;
            currentCaressPharosPrice = gamePharosToken;
            roundPharosTimestamp = block.timestamp;
            addMoment = 0;
            emit evePharosSoulWin(msg.sender, rewardBalance, block.timestamp);
        } else {
            require(
                PharosGameStatus == PharosStatus.PrayPharosPower,
                "Not in the stage of PrayPharosPower."
            );
            require(
                IERC20(PharosCoin).balanceOf(msg.sender) >=
                    currentCaressPharosPrice,
                "Not enough $PharosCoin."
            );
            require(
                currentPlayerInfo[currentRound][msg.sender] <= 10,
                "Up to ten times per round per user, Please switch accounts."
            );
            uint256 holyCashback = (currentCaressPharosPrice * 60) / 100;
            uint256 teamCashBack = (currentCaressPharosPrice * 20) / 100;
            uint256 poolCashBack = (currentCaressPharosPrice * 10) / 100;
            emit evePharosSoul(
                msg.sender,
                currentCaressPharosPrice,
                block.timestamp,
                currentHolyMessenger
            );
            IERC20(PharosCoin).transferFrom(
                msg.sender,
                address(this),
                currentCaressPharosPrice
            );
            IERC20(PharosCoin).transfer(currentHolyMessenger, holyCashback);
            IERC20(PharosCoin).transfer(teamAddress, teamCashBack);
            IERC20(PharosCoin).transfer(PharosGameFeeAddress, poolCashBack);
            currentHolyMessenger = msg.sender;
            currentCaressPharosPrice += gamePharosToken;
            addMoment += 6 * 60;
            endTimestamp = addMoment + roundPharosTimestamp + holyMoment;
            currentPlayerInfo[currentRound][msg.sender]++;
        }
    }

    function SetPharosCoin(address PharosCoin_) external onlyOwner {
        PharosCoin = PharosCoin_;
    }

    function SetPharosGameFeeAddress(
        address PharosGameFeeAddress_
    ) external onlyOwner {
        PharosGameFeeAddress = PharosGameFeeAddress_;
    }
}