/**
 *Submitted for verification at Arbiscan.io on 2023-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
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
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        //   require(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        //   require(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract MetaFight is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bool public genesisStartOnce = false;
    uint256 public currentRound; // current round for betting round
    uint256 public fee; // platform fee
    uint256 public treasuryAmount; // treasury amount that was not claimed
    uint256 public minimumBet; // minimum betting amount (denominated in wei)
    uint256 public baseRate = 10000; // 10,000 base rate is equal to 100%

    enum Position {
        Red,
        Blue,
        DrawOrRefund
    }

    struct Round {
        uint256 idGame;
        uint256 idSI;
        uint256 totalAmountBet;
        uint256 RedAmount;
        uint256 BlueAmount;
        uint256 oddsAmount;
        bool gameStatus;
        Position gameResult;
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(uint256 => Round) public rounds;
    mapping(address => uint256[]) public userRounds;
    mapping(address => bool) public Agent;

    event BetBlue(
        address indexed sender,
        uint256 indexed idGame,
        uint256 amount
    );
    event BetRed(
        address indexed sender,
        uint256 indexed idGame,
        uint256 amount
    );
    event Claim(address indexed sender, uint256 indexed idGame, uint256 amount);
    event Result(uint256 indexed idGame, Position gameResult);
    event StartRound(uint256 indexed idGame);
    event RewardsCalculated(
        uint256 indexed idGame,
        uint256 oddsAmount,
        uint256 treasuryAmount
    );
    event TokenRecovery(address indexed token, uint256 amount);
    event TreasuryClaim(uint256 amount);

    event NewFee(uint256 fee, uint256 baseRate);
    event NewMinimumBet(uint256 minimumBet);
    event NewAgent(address Agent, bool state);

    /**
     * @notice Constructor
     * @param _minAmountBet: minimum bet amounts (in wei)
     * @param _fee: platform fee (9450 = 94.5% || 100 - 94.5 = 5.5%)
     */
    constructor(uint256 _minAmountBet, uint256 _fee) {
        minimumBet = _minAmountBet;
        fee = _fee;

        Agent[msg.sender] = true;
    }

    receive() external payable {}

    /**
     * @notice Bet Blue position
     * @param roundID: roundID
     */
    function betBlue(uint256 roundID) external payable nonReentrant {
        require(roundID == currentRound, "Bet is too early/late");
        require(_bettable(roundID), "Round not bettable");
        require(
            msg.value >= minimumBet,
            "Bet amount must be greater than minBetAmount"
        );
        require(
            ledger[roundID][msg.sender].amount == 0 ||
                ledger[roundID][msg.sender].position == Position.Blue,
            "Can only bet in one team"
        );

        Round storage round = rounds[roundID];
        BetInfo storage betInfo = ledger[roundID][msg.sender];
        uint256 amountBlue = msg.value;

        if (ledger[roundID][msg.sender].amount == 0) {
            // Update round data
            round.totalAmountBet = round.totalAmountBet + amountBlue;
            round.BlueAmount = round.BlueAmount + amountBlue;

            // Update user data
            betInfo.position = Position.Blue;
            betInfo.amount = amountBlue;
            userRounds[msg.sender].push(roundID);
        } else {
            // Update round and user data
            round.totalAmountBet = round.totalAmountBet + amountBlue;
            round.BlueAmount = round.BlueAmount + amountBlue;
            betInfo.amount += amountBlue;
        }

        uint256 updateAmount = betInfo.amount;

        emit BetBlue(msg.sender, roundID, updateAmount);
    }

    /**
     * @notice Bet Red position
     * @param roundID: roundID
     */
    function betRed(uint256 roundID) external payable nonReentrant {
        require(roundID == currentRound, "Bet is too early/late");
        require(_bettable(roundID), "Round not bettable");
        require(
            msg.value >= minimumBet,
            "Bet amount must be greater than minBetAmount"
        );
        require(
            ledger[roundID][msg.sender].amount == 0 ||
                ledger[roundID][msg.sender].position == Position.Red,
            "Can only bet in one team"
        );

        Round storage round = rounds[roundID];
        BetInfo storage betInfo = ledger[roundID][msg.sender];
        uint256 amountRed = msg.value;

        if (ledger[roundID][msg.sender].amount == 0) {
            // Update round data
            round.totalAmountBet = round.totalAmountBet + amountRed;
            round.RedAmount = round.RedAmount + amountRed;

            // Update user data
            betInfo.position = Position.Red;
            betInfo.amount = amountRed;
            userRounds[msg.sender].push(roundID);
        } else {
            // Update round and user data
            round.totalAmountBet = round.totalAmountBet + amountRed;
            round.RedAmount = round.RedAmount + amountRed;
            betInfo.amount += amountRed;
        }

        uint256 updateAmount = betInfo.amount;

        emit BetRed(msg.sender, roundID, updateAmount);
    }

    /**
     * @notice Claim reward for an array of roundIDs
     * @param roundIDs: array of roundIDs
     */
    function claim(uint256[] calldata roundIDs) external nonReentrant {
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < roundIDs.length; i++) {
            require(
                rounds[roundIDs[i]].gameStatus == false,
                "Round has not started"
            );

            uint256 addedReward = 0;
            Round memory round = rounds[roundIDs[i]];
            // Round valid, claim rewards
            if (round.gameResult == Position.Red) {
                require(
                    claimable(roundIDs[i], msg.sender),
                    "Not eligible for claim"
                );
                addedReward =
                    (ledger[roundIDs[i]][msg.sender].amount *
                        round.oddsAmount) /
                    baseRate;
            } else if (round.gameResult == Position.Blue) {
                require(
                    claimable(roundIDs[i], msg.sender),
                    "Not eligible for claim"
                );
                addedReward =
                    (ledger[roundIDs[i]][msg.sender].amount *
                        round.oddsAmount) /
                    baseRate;
            }
            // Round invalid, refund bet amount
            else if (round.gameResult == Position.DrawOrRefund) {
                require(
                    refundable(roundIDs[i], msg.sender),
                    "Not eligible for refund"
                );
                addedReward = ledger[roundIDs[i]][msg.sender].amount;
            }

            ledger[roundIDs[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, roundIDs[i], addedReward);
        }

        if (reward > 0) {
            payable(msg.sender).transfer(reward);
        }
    }

    /**
     * @notice Start the next round, set result and calculateRewards
     * @dev Callable by Agent
     */
    function executeRound(Position _gameResult, uint256 _idSI)
        external
        onlyAgent
    {
        require(_notBettable(currentRound), "Round bettable");
        Round storage round = rounds[currentRound];

        if (round.totalAmountBet == 0 || _gameResult == Position.DrawOrRefund) {
            round.gameResult = _gameResult;
            round.idSI = _idSI;

            currentRound = currentRound + 1;
            _safeStartRound(currentRound);
        } else {
            round.gameResult = _gameResult;
            round.idSI = _idSI;
            _calculateRewards(currentRound);

            currentRound = currentRound + 1;
            _safeStartRound(currentRound);
        }

        emit Result(currentRound - 1, _gameResult);
    }

    /**
     * @notice Start genesis round
     * @dev Callable by Agent
     */
    function genesisStartRound() external onlyAgent {
        require(!genesisStartOnce, "Can only run genesisStartRound once");

        _startRound(currentRound);
        genesisStartOnce = true;
    }

    /**
     * @notice Set bettable status
     * @dev Callable by Agent
     */
    function _setBettableStatus(uint256 roundID, bool _status)
        external
        onlyAgent
    {
        rounds[roundID].gameStatus = _status;
    }

    /**
     * @notice Set new platform fee and baseRate
     * @dev Callable by contract owner
     */
    function setFee(uint256 newFee, uint256 newRate) external onlyOwner {
        fee = newFee;
        baseRate = newRate;

        emit NewFee(newFee, newRate);
    }

    /**
     * @notice Set new minimum bet amount
     * @dev Callable by contract owner
     */
    function setMinBet(uint256 newMinBet) external onlyOwner {
        minimumBet = newMinBet;

        emit NewMinimumBet(newMinBet);
    }

    /**
     * @notice Set new agent/operator
     * @dev Callable by contract owner
     */
    function setNewAgent(address _agentAddress, bool state) external onlyOwner {
        Agent[_agentAddress] = state;

        emit NewAgent(_agentAddress, state);
    }

    /**
     * @notice Claim all rewards in treasury
     * @dev Callable by admin
     */
    function claimTreasury() external nonReentrant onlyOwner {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        payable(msg.sender).transfer(currentTreasuryAmount);

        emit TreasuryClaim(currentTreasuryAmount);
    }

    /**
     * @notice Returns round roundIDs and bet information for a user that has participated
     * @param user: user address
     * @param cursor: cursor
     * @param size: size
     */
    function getUserRounds(
        address user,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            uint256[] memory,
            BetInfo[] memory,
            uint256
        )
    {
        uint256 length = size;

        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][cursor + i];
            betInfo[i] = ledger[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }

    /**
     * @notice Returns round roundIDs length
     * @param user: user address
     */
    function getUserRoundsLength(address user) external view returns (uint256) {
        return userRounds[user].length;
    }

    /**
     * @notice Get the claimable stats of specific roundID and user account
     * @param roundID: roundID
     * @param user: user address
     */
    function claimable(uint256 roundID, address user)
        public
        view
        returns (bool)
    {
        BetInfo memory betInfo = ledger[roundID][user];
        Round memory round = rounds[roundID];
        if (
            round.gameResult != Position.Red &&
            round.gameResult != Position.Blue
        ) {
            return false;
        }
        return
            !round.gameStatus &&
            betInfo.amount != 0 &&
            !betInfo.claimed &&
            ((betInfo.position == round.gameResult));
    }

    /**
     * @notice Get the refundable stats of specific roundID and user account
     * @param roundID: roundID
     * @param user: user address
     */
    function refundable(uint256 roundID, address user)
        public
        view
        returns (bool)
    {
        BetInfo memory betInfo = ledger[roundID][user];
        Round memory round = rounds[roundID];
        if (
            round.gameResult == Position.Red ||
            round.gameResult == Position.Blue
        ) {
            return false;
        }
        return !round.gameStatus && !betInfo.claimed && betInfo.amount != 0;
    }

    /**
     * @notice Start round
     * @param roundID: roundID
     */
    function _safeStartRound(uint256 roundID) internal {
        require(
            genesisStartOnce,
            "Can only run after genesisStartRound is triggered"
        );
        _startRound(roundID);
    }

    /**
     * @notice Start round
     * @param roundID: roundID
     */
    function _startRound(uint256 roundID) internal {
        Round storage round = rounds[roundID];
        round.idGame = roundID;
        round.gameStatus = false;
        round.totalAmountBet = 0;

        emit StartRound(roundID);
    }

    /**
     * @notice Calculate rewards for round
     * @param roundID: roundID
     */
    function _calculateRewards(uint256 roundID) internal {
        require(rounds[roundID].oddsAmount == 0, "Rewards calculated");
        Round storage round = rounds[roundID];
        uint256 treasuryAmt;
        uint256 rewardAmount;
        uint256 totalBets = 0;
        uint256 ads = 0;

        // Red wins
        if (round.gameResult == Position.Red) {
            totalBets = round.totalAmountBet;
            ads = (totalBets * fee) / round.RedAmount;
            rewardAmount = ads;
            treasuryAmt = totalBets - ((totalBets * fee) / baseRate);
        }
        // Blue wins
        else if (round.gameResult == Position.Blue) {
            totalBets = round.totalAmountBet;
            ads = (totalBets * fee) / round.BlueAmount;
            rewardAmount = ads;
            treasuryAmt = totalBets - ((totalBets * fee) / baseRate);
        }

        round.oddsAmount = rewardAmount;

        // Add to treasury
        treasuryAmount += treasuryAmt;

        emit RewardsCalculated(roundID, rewardAmount, treasuryAmt);
    }

    /**
     * @notice Determine if a round(roundID) is valid for receiving bets
     * Round must have open
     */
    function _bettable(uint256 roundID) internal view returns (bool) {
        return rounds[roundID].gameStatus == true;
    }

    /**
     * @notice Determine if a round(roundID) is closed
     * Round must have closed
     */
    function _notBettable(uint256 roundID) internal view returns (bool) {
        return rounds[roundID].gameStatus == false;
    }

    modifier onlyAgent() {
        require(Agent[msg.sender], "Not Agent");
        _;
    }
}