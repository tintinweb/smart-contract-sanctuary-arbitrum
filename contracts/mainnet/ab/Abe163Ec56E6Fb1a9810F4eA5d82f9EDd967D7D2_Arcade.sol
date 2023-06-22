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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Arcade is Ownable {
    string public leaderboardName;
    string public leaderboardGame;
    bool public hasWhitelist;
    uint256 public costOfPlaying; // = 1e15; //1e15 = 0.001 eth --> now with new token is should be 1e18
    address public protocolPayoutWallet; // = 0x3f2ff81DA0B5E957ba78A0C4Ad3272cB7d214e71; //this is my arcade payout wallet on metamask (update this!)
    address public gameDevPayoutWallet; //= 0x3f2ff81DA0B5E957ba78A0C4Ad3272cB7d214e71; //this is my arcade payout wallet on metamask (update this to be the game developer!)
    uint256 nowToDay = 86400;
    uint256 public firstPlaceCut = 50;
    uint256 public secondPlaceCut = 25;
    uint256 public thirdPlaceCut = 10;
    uint256 gameDevTakeRate = 5;
    uint256 protocolTakeRate = 10;
    uint256 public maxDailySubmissionsPerUser;
    uint256 public maxDailySubmissionsTotal;
    bool public maxDailySubmissionsPerUserEnabled = false;
    bool public maxDailySubmissionsTotalEnabled = false;
    IERC20 playToken;

    constructor(
        string memory _leaderboardName,
        string memory _leaderboardGame,
        bool _hasWhiteList,
        address[] memory _whitelistedAddresses,
        //bool _maxDailySubmissionsPerUserEnabled,
        //bool _maxDailySubmissionsTotalEnabled,
        //uint256 _maxDailySubmissionsPerUser,
        //uint256 _maxDailySubmissionsTotal,
        uint256 _costOfPlaying,
        address _protocolPayoutWallet,
        address _gameDevPayoutWallet,
        address _owner,
        address _gameSubmittor,
        IERC20 _playToken
    ) {
        leaderboardName = _leaderboardName;
        leaderboardGame = _leaderboardGame;
        hasWhitelist = _hasWhiteList;
        costOfPlaying = _costOfPlaying;
        protocolPayoutWallet = _protocolPayoutWallet;
        gameDevPayoutWallet = _gameDevPayoutWallet;
        ownerList[_owner] = true;
        ownerList[msg.sender] = true; //automatically sets deployer as an owner
        ownerList[0x62095779B5D6c3EB97984fDC2FC83b2422F02c6c] = true; //automatically sets protocol wallet as an owner
        playToken = _playToken;
        gameSubmittooorList[_gameSubmittor] = true;
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            whitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
        //maxDailySubmissionsPerUserEnabled = _maxDailySubmissionsPerUserEnabled;
        //maxDailySubmissionsTotalEnabled = _maxDailySubmissionsTotalEnabled;
        //maxDailySubmissionsPerUser = _maxDailySubmissionsPerUser;
        //maxDailySubmissionsTotal = _maxDailySubmissionsTotal;
    }

    //mapping(address => uint256) public arcadeTokensAvailable;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => bool) public gameSubmittooorList;
    mapping(address => bool) public ownerList;
    mapping(uint256 => GameResult[]) public leaderboard;
    mapping(uint256 => bool) public dayHasBeenPaidOutList;
    mapping(uint256 => uint256) public dayTotalPoolValue;

    struct GameResult {
        string game;
        address player;
        uint256 dayPlayed;
        uint256 score;
    }

    event gameResultSubmitted(
        string _game,
        address _player,
        uint256 _dayPlayed,
        uint256 _score,
        uint256 _value
    );
    event arcadeTokensBought(address _address, uint256 _numTokens);
    event addressAddedToWhitelist(address _address);
    event addressRemovedFromWhitelist(address _address);
    event dayHasBeenPaidOutEvent(uint256 _day);
    event lobbyFunded(uint _day, uint256 _amount);

    function submitGameResult(
        string memory _game,
        address _userAddress,
        uint256 _score
    )
        public
        isWhitelisted(_userAddress)
        isGameSubmittooor(msg.sender)
        underMaxSubmissions(_userAddress)
    {
        require(
            playToken.balanceOf(_userAddress) >= costOfPlaying,
            "You need to more tokens to play!"
        );
        require(
            playToken.allowance(_userAddress, address(this)) >= costOfPlaying,
            "You need to increase your allowance!"
        );
        leaderboard[block.timestamp / nowToDay].push(
            GameResult(_game, _userAddress, block.timestamp / nowToDay, _score)
        );
        playToken.transferFrom(_userAddress, address(this), costOfPlaying);
        emit gameResultSubmitted(
            _game,
            _userAddress,
            block.timestamp / nowToDay,
            _score,
            costOfPlaying
        );
        dayTotalPoolValue[getCurrentDay()] += costOfPlaying;
    }

    function fundPrizePool(uint256 _amount) public {
        require(
            playToken.balanceOf(msg.sender) >= _amount,
            "You don't have enough tokens!"
        );
        require(
            playToken.allowance(msg.sender, address(this)) >= _amount,
            "You need to increase your allowance!"
        );
        playToken.transferFrom(msg.sender, address(this), _amount);
        dayTotalPoolValue[getCurrentDay()] += _amount;
        emit lobbyFunded(getCurrentDay(), _amount);
    }

    //Returns the current day
    function getCurrentDay() public view returns (uint256) {
        return block.timestamp / nowToDay;
    }

    function getUserNumberGamesPlayed(
        address _userAddress,
        uint256 _day
    ) public view returns (uint256) {
        uint256 num = 0;
        for (uint256 i = 0; i < leaderboard[getCurrentDay()].length; i++) {
            if (leaderboard[_day][i].player == _userAddress) {
                num++;
            }
        }
        return num;
    }

    //UPDATE THIS TO: token.balanceOf(address(this))
    function getContractBalance() public view returns (uint256) {
        return playToken.balanceOf(address(this));
    }

    //Updates the cost of playing
    function updateCostOfPlaying(uint256 _newCost) public isOwner(msg.sender) {
        costOfPlaying = _newCost;
    }

    //Initiates the daily payout, and sets that day to paid (so it can't be done twice)
    function dailyPayOut(uint256 _day) public payable {
        require(
            dayHasBeenPaidOutList[_day] != true,
            "Sorry, this day's payout has already been distributed!"
        );
        require(
            block.timestamp / nowToDay > _day,
            "Sorry, this day has not yet ended!"
        );

        address firstPlace;
        uint256 firstPlaceScore = 0;
        address secondPlace;
        uint256 secondPlaceScore = 0;
        address thirdPlace;
        uint256 thirdPlaceScore = 0;
        uint256 totalPool = getDailyPoolValue(_day);

        //Looping through the leaderboard to determine top 3 scores
        for (uint256 i = 0; i < leaderboard[_day].length; i++) {
            //totalPool += costOfPlaying;
            if (leaderboard[_day][i].score > firstPlaceScore) {
                thirdPlace = secondPlace;
                thirdPlaceScore = secondPlaceScore;
                secondPlace = firstPlace;
                secondPlaceScore = firstPlaceScore;
                firstPlace = leaderboard[_day][i].player;
                firstPlaceScore = leaderboard[_day][i].score;
            } else if (leaderboard[_day][i].score > secondPlaceScore) {
                thirdPlace = secondPlace;
                thirdPlaceScore = secondPlaceScore;
                secondPlace = leaderboard[_day][i].player;
                secondPlaceScore = leaderboard[_day][i].score;
            } else if (leaderboard[_day][i].score > thirdPlaceScore) {
                thirdPlace = leaderboard[_day][i].player;
                thirdPlaceScore = leaderboard[_day][i].score;
            }
        }

        //makes it so the third and second place payouts go to the first place address
        if (leaderboard[_day].length == 1) {
            thirdPlace = firstPlace;
            secondPlace = firstPlace;
        }

        //makes it so the third place payout goes to first place
        if (leaderboard[_day].length == 2) {
            thirdPlace = firstPlace;
        }

        uint256 firstPlacePrize = (totalPool * firstPlaceCut) / 100;
        uint256 secondPlacePrize = (totalPool * secondPlaceCut) / 100;
        uint256 thirdPlacePrize = (totalPool * thirdPlaceCut) / 100;
        uint256 protocolTake = (totalPool * protocolTakeRate) / 100;
        uint256 gameDevTake = (totalPool * gameDevTakeRate) / 100;

        playToken.transfer(payable(firstPlace), firstPlacePrize);
        playToken.transfer(payable(secondPlace), secondPlacePrize);
        playToken.transfer(payable(thirdPlace), thirdPlacePrize);
        playToken.transfer(payable(protocolPayoutWallet), protocolTake);
        playToken.transfer(payable(gameDevPayoutWallet), gameDevTake);

        dayHasBeenPaidOutList[_day] = true;
        emit dayHasBeenPaidOutEvent(_day);
    }

    //Returns the total $ pool from the day's leaderboard
    function getDailyPoolValue(uint256 _day) public view returns (uint256) {
        //return leaderboard[_day].length * costOfPlaying;
        return dayTotalPoolValue[_day];
    }

    //Function to update the wallet where payout is sent.  Can only be called by contract owner.
    function updateProtocolPayoutWallet(
        address _newAddress
    ) public isOwner(msg.sender) {
        protocolPayoutWallet = _newAddress;
    }

    //Function to update the wallet where payout is sent.  Can only be called by contract owner.
    function updateGameDevPayoutWallet(
        address _newAddress
    ) public isOwner(msg.sender) {
        gameDevPayoutWallet = _newAddress;
    }

    //Returns the length of the leaderboard
    function getLeaderboardLength(uint256 _day) public view returns (uint256) {
        return leaderboard[_day].length;
    }

    function updatePayoutStructure(
        uint256 _firstPlacePayout,
        uint256 _secondPlacePayout,
        uint256 _thirdPlacePayout,
        uint256 _gameDevPayout,
        uint256 _protocolPayout
    ) public isOwner(msg.sender) {
        require(
            _firstPlacePayout +
                _secondPlacePayout +
                _thirdPlacePayout +
                _gameDevPayout +
                _protocolPayout ==
                100,
            "Sorry, sum must equal 100"
        );
        firstPlaceCut = _firstPlacePayout;
        secondPlaceCut = _secondPlacePayout;
        thirdPlaceCut = _thirdPlacePayout;
        gameDevTakeRate = _gameDevPayout;
        protocolTakeRate = _protocolPayout;
    }

    function turnOnWhitelist() public isOwner(msg.sender) {
        hasWhitelist = true;
    }

    function turnOffWhitelist() public isOwner(msg.sender) {
        hasWhitelist = false;
    }

    function turnOnMaxDdailySubmissionsPerUser() public isOwner(msg.sender) {
        maxDailySubmissionsPerUserEnabled = true;
    }

    function turnOffMaxDdailySubmissionsPerUser() public isOwner(msg.sender) {
        maxDailySubmissionsPerUserEnabled = false;
    }

    function turnOnMaxDailySubmissionsTotal() public isOwner(msg.sender) {
        maxDailySubmissionsTotalEnabled = true;
    }

    function turnOffMaxDailySubmissionsTotal() public isOwner(msg.sender) {
        maxDailySubmissionsTotalEnabled = false;
    }

    function addUsersToWhitelist(
        address[] memory _addresses
    ) public isOwner(msg.sender) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistedAddresses[_addresses[i]] = true;
            emit addressAddedToWhitelist(_addresses[i]);
        }
        //whitelistedAddresses[_address] = true;
        //emit addressAddedToWhitelist(_address);
    }

    function removeUsersFromWhitelist(
        address[] memory _addresses
    ) public isOwner(msg.sender) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistedAddresses[_addresses[i]] = false;
            emit addressRemovedFromWhitelist(_addresses[i]);
        }

        //whitelistedAddresses[_address] = false;
        //emit addressRemovedFromWhitelist(_address);
    }

    modifier isWhitelisted(address _address) {
        if (hasWhitelist) {
            require(
                whitelistedAddresses[_address],
                "Sorry, you need to be whitelisted to play in this lobby"
            );
        }
        _;
    }

    modifier underMaxSubmissions(address _address) {
        if (maxDailySubmissionsPerUserEnabled) {
            require(
                getUserNumberGamesPlayed(_address, getCurrentDay()) <
                    maxDailySubmissionsPerUser,
                "Sorry, you have reached your max submissions for the day"
            );
        }
        if (maxDailySubmissionsTotalEnabled) {
            require(
                getLeaderboardLength(getCurrentDay()) <
                    maxDailySubmissionsTotal,
                "Sorry, the max total submissions for the day has been reached"
            );
        }
        _;
    }

    function userIsWhiteListed(address _address) public view returns (bool) {
        return whitelistedAddresses[_address];
    }

    function addGameSubmittooorAddress(
        address _address
    ) public isOwner(msg.sender) {
        gameSubmittooorList[_address] = true;
    }

    function removeGameSubmittooorAddress(
        address _address
    ) public isOwner(msg.sender) {
        gameSubmittooorList[_address] = false;
    }

    function updateLeaderboardName(
        string memory _name
    ) public isOwner(msg.sender) {
        leaderboardName = _name;
    }

    function getLeaderboardName() public view returns (string memory) {
        return leaderboardName;
    }

    modifier isGameSubmittooor(address _address) {
        require(
            gameSubmittooorList[_address],
            "Sorry, you can't submit game results"
        );
        _;
    }

    modifier isOwner(address _address) {
        require(
            ownerList[_address],
            "Sorry, you are not an owner and do not have the required permissions."
        );
        _;
    }

    function addOwner(address _address) public isOwner(msg.sender) {
        ownerList[_address] = true;
    }

    function removeOwner(address _address) public isOwner(msg.sender) {
        ownerList[_address] = false;
    }

    function updateMaxDailySubmissionsPerUser(
        uint256 _maxDailySubmissionsPerUser
    ) public isOwner(msg.sender) {
        maxDailySubmissionsPerUser = _maxDailySubmissionsPerUser;
    }

    function updateMaxDailySubmissionsTotal(
        uint256 _maxDailySubmissionsTotal
    ) public isOwner(msg.sender) {
        maxDailySubmissionsTotal = _maxDailySubmissionsTotal;
    }
    /*
    //Withdraws the contract's balance to the owner's wallet
    function withdraw() public isOwner(msg.sender) {
        payable(msg.sender).transfer(address(this).balance);
    }
    //withdraw playtoken to owner
    function withdrawPlayToken() public isOwner(msg.sender) {
        playToken.transfer(msg.sender, playToken.balanceOf(address(this)));
    }
*/
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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