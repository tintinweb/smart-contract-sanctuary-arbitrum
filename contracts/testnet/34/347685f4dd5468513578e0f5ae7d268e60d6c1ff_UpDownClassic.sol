// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {SupraOracle, ISupraSValueFeed} from "./SupraOracle.sol";
import {IClassic} from "./interfaces/IClassic.sol";
import {IERC20} from "./interfaces/IERC20.sol";

/**
 * @title UpDownClassic
 */
contract UpDownClassic is IClassic, SupraOracle, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    bool public genesisLockOnce = false;
    bool public genesisStartOnce = false;

    address public adminAddress; // address of the admin
    address public operatorAddress; // address of the operator
    address public stakingPoolAddress; // address of the staking pool
    IERC20 public chips; // address of token used in bets

    uint256 public bufferSeconds; // number of seconds for valid execution of a prediction round
    uint256 public intervalSeconds; // interval in seconds between two prediction rounds

    uint256 public minBetAmount; // minimum betting amount (denominated in 6 decimals)
    uint256 public maxBetAmount; // maximum betting amount (denominated in 6 decimals)
    uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public stakingFee; // staking pool rate (e.g. 5000 = 50%, 150 = 1.50%, deducted from treasury fee)
    uint256 public treasuryAmount; // treasury amount that was not claimed

    uint256 public currentEpoch; // current epoch for prediction round

    uint256 public constant MAX_TREASURY_FEE = 1000; // 10%
    uint256 public constant MAX_STAKING_FEE = 10000; // 10%

    uint256 public oracleUpdateAllowance; // time + 1

    address[] public tokens;
    uint256[] public tokenIdexes;
    string[] public tokenSymbols;
    mapping(address token => Oracle) public supportedTokens;
    mapping(uint256 epoch => mapping(address user => mapping(address token => BetInfo))) public ledger;
    mapping(uint256 epoch => mapping(address => TokenRound)) public tokenRounds;
    mapping(uint256 epoch => Round) public rounds;
    mapping(address user => mapping(address token => uint256[])) public userRounds;

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(msg.sender == adminAddress || msg.sender == operatorAddress, "Not operator/admin");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier notContract() {
        //TODO: remove
        // require(!_isContract(msg.sender), "Contract not allowed");
        // require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
     * @notice Constructor
     * @param _adminAddress: admin address
     * @param _oracleAddress: oracle address
     * @param _operatorAddress: operator address
     * @param _chips: betting token address
     * @param _intervalSeconds: number of time within an interval
     * @param _bufferSeconds: buffer of time for resolution of price
     * @param _oracleUpdateAllowance: oracle update allowance
     * @param _minBetAmount: minimum bet amounts (in wei)
     * @param _maxBetAmount: maximum bet amounts (in wei)
     * @param _treasuryFee: treasury fee (1000 = 10%)
     * @param _stakingFee: staking fee (1000 = 10%), deducted from treasury fee
     */
    function initialize(
        address _adminAddress,
        address _oracleAddress,
        address _operatorAddress,
        address _chips,
        uint256 _intervalSeconds,
        uint256 _bufferSeconds,
        uint256 _oracleUpdateAllowance,
        uint256 _minBetAmount,
        uint256 _maxBetAmount,
        uint256 _treasuryFee,
        uint256 _stakingFee
    ) public initializer {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Fee too high");
        require(_stakingFee <= MAX_STAKING_FEE, "Staking fee too high");
        chips = IERC20(_chips);
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        intervalSeconds = _intervalSeconds;
        bufferSeconds = _bufferSeconds;
        oracleUpdateAllowance = _oracleUpdateAllowance;
        minBetAmount = (_minBetAmount * 10 ** chips.decimals()) - 1;
        maxBetAmount = (_maxBetAmount * 10 ** chips.decimals()) + 1;
        treasuryFee = _treasuryFee;
        stakingFee = _stakingFee;
        _setSValueFeed(_oracleAddress);
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @notice Bet down position
     * @param token: token address
     * @param epoch: epoch
     * @param amount: amount to bet in USDT (6 decimals)
     */
    function betDown(address token, uint256 epoch, uint256 amount) external whenNotPaused nonReentrant notContract {
        require(epoch == currentEpoch, "Bet is too early/late");
        require(amount > minBetAmount, "Bet amount must be greater than minBetAmount");
        require(amount < maxBetAmount, "Bet amount must be lower than maxBetAmount");
        require(ledger[epoch][msg.sender][token].amount == 0, "Can only bet once per round");
        require(supportedTokens[token].supported, "Token not supported");
        require(_bettable(epoch), "Round not bettable");

        // Deposit USDT
        _safeTransfer(msg.sender, address(this), amount);

        // Update token round data
        TokenRound storage tokenRound = tokenRounds[epoch][token];
        tokenRound.downAmount += amount;

        // Update user data
        BetInfo storage betInfo = ledger[epoch][msg.sender][token];
        betInfo.position = Position.Down;
        betInfo.amount = amount;
        userRounds[msg.sender][token].push(epoch);

        emit BetDown(msg.sender, epoch, token, amount);
    }

    /**
     * @notice Bet up position
     * @param token: token address
     * @param epoch: epoch
     * @param amount: amount to bet in USDT (6 decimals)
     */
    function betUp(address token, uint256 epoch, uint256 amount) external whenNotPaused nonReentrant notContract {
        require(epoch == currentEpoch, "Bet is too early/late");
        require(amount > minBetAmount, "Bet amount must be greater than minBetAmount");
        require(amount < maxBetAmount, "Bet amount must be lower than maxBetAmount");
        require(ledger[epoch][msg.sender][token].amount == 0, "Can only bet once per round");
        require(supportedTokens[token].supported, "Token not supported");
        require(_bettable(epoch), "Round not bettable");

        // Deposit USDT
        _safeTransfer(msg.sender, address(this), amount);

        // Update token round data
        TokenRound storage tokenRound = tokenRounds[epoch][token];
        tokenRound.upAmount += amount;

        // Update user data
        BetInfo storage betInfo = ledger[epoch][msg.sender][token];
        betInfo.position = Position.Up;
        betInfo.amount = amount;
        userRounds[msg.sender][token].push(epoch);

        emit BetUp(msg.sender, epoch, token, amount);
    }

    /**
     * @notice Claim reward for an array of epochs
     * @param betTokens: array of tokens to claim
     * @param epochs: array of epochs
     */
    function claim(address[][] calldata betTokens, uint256[] calldata epochs) external nonReentrant notContract {
        require(betTokens.length == epochs.length, "Invalid input length");
        uint256 reward; // Initializes total reward

        for (uint256 i; i < epochs.length; i++) {
            require(rounds[epochs[i]].startTimestamp != 0, "Round has not started");
            require(block.timestamp > rounds[epochs[i]].closeTimestamp, "Round has not ended");

            uint256 roundReward;

            Round memory round = rounds[epochs[i]];
            // Round valid, claim rewards
            if (round.oracleCalled) {
                for (uint256 j; j < betTokens[i].length; j++) {
                    require(claimable(betTokens[i][j], epochs[i], msg.sender), "Not eligible for claim");
                    uint256 tokenReward = ledger[epochs[i]][msg.sender][betTokens[i][j]].amount * round.rewardAmount
                        / round.rewardBaseCalAmount;
                    roundReward += tokenReward;
                    ledger[epochs[i]][msg.sender][betTokens[i][j]].claimed = true;
                    emit Claim(msg.sender, epochs[i], betTokens[i][j], tokenReward);
                }
            }
            // Round invalid, refund bet amount
            else {
                for (uint256 j; j < betTokens[i].length; j++) {
                    require(refundable(betTokens[i][j], epochs[i], msg.sender), "Not eligible for refund");
                    uint256 tokenReward = ledger[epochs[i]][msg.sender][betTokens[i][j]].amount;
                    roundReward += tokenReward;
                    ledger[epochs[i]][msg.sender][betTokens[i][j]].claimed = true;
                    emit Claim(msg.sender, epochs[i], betTokens[i][j], tokenReward);
                }
            }

            reward += roundReward;
        }

        if (reward > 0) {
            chips.transfer(msg.sender, reward);
        }
    }

    /**
     * @notice Add a new token
     * @param _token: token address
     * @param _oracleIndex: oracle index used by supra oracle
     */
    function addToken(address _token, uint256 _oracleIndex, string calldata _tokenSymbol)
        external
        onlyAdmin
        whenPaused
    {
        tokens.push(_token);
        tokenIdexes.push(_oracleIndex);
        tokenSymbols.push(_tokenSymbol);

        supportedTokens[_token] = Oracle({oracleIndex: _oracleIndex, oracleLatestRoundId: 0, supported: true});

        emit TokenAdded(_token, _oracleIndex, _tokenSymbol);
    }

    /**
     * @notice Update supported token
     * @param _token: token address
     * @param _oracleIndex: oracle index used by supra oracle
     * @param _oracleLatestRound: latest round id of the oracle
     * @param _supported: If token is to be supported
     */
    function updateToken(
        address _token,
        uint256 _oracleIndex,
        string calldata _tokenSymbol,
        uint256 _oracleLatestRound,
        bool _supported
    ) external onlyAdmin whenPaused {
        supportedTokens[_token] =
            Oracle({oracleIndex: _oracleIndex, oracleLatestRoundId: _oracleLatestRound, supported: _supported});
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                tokenIdexes[i] = _oracleIndex;
                tokenSymbols[i] = _tokenSymbol;
                break;
            }
        }
        emit TokenUpdated(_token, _oracleIndex, _oracleLatestRound, _supported, _tokenSymbol);
    }

    /**
     * @notice Remove a supported token
     * @param _token: token address
     */
    function removeToken(address _token) external onlyAdmin whenPaused {
        // remove token from supportedTokens mapping
        delete supportedTokens[_token];
        // remove token from tokens array
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                tokens[i] = tokens[tokens.length - 1];
                tokenIdexes[i] = tokenIdexes[tokenIdexes.length - 1];
                tokenSymbols[i] = tokenSymbols[tokenSymbols.length - 1];
                tokens.pop();
                tokenIdexes.pop();
                tokenSymbols.pop();
                break;
            }
        }
        emit TokenRemoved(_token);
    }

    /**
     * @notice Start the next round n, lock price for round n-1, end round n-2
     * @dev Callable by admin or operator
     */
    function executeRound() external whenNotPaused onlyAdminOrOperator {
        require(
            genesisStartOnce && genesisLockOnce,
            "Can only run after genesisStartRound and genesisLockRound is triggered"
        );

        (uint256[] memory currentRoundIds, uint256[] memory currentPrices) = _getPricesFromOracle();

        for (uint256 i = 0; i < tokens.length; i++) {
            supportedTokens[tokens[i]].oracleLatestRoundId = uint256(currentRoundIds[i]);
            // CurrentEpoch refers to previous round (n-1)
            _safeLockRound(tokens[i], currentEpoch, currentRoundIds[i], currentPrices[i]);
            _safeEndRound(tokens[i], currentEpoch - 1, currentRoundIds[i], currentPrices[i]);
        }
        Round storage round = rounds[currentEpoch - 1];
        round.oracleCalled = true;

        _calculateRewards(currentEpoch - 1);

        // Increment currentEpoch to current round (n)
        _safeStartRound(++currentEpoch);
    }

    /**
     * @notice Start genesis round
     * @dev Callable by admin or operator
     */
    function genesisStartRound() external whenNotPaused onlyAdminOrOperator {
        require(!genesisStartOnce, "Can only run genesisStartRound once");
        require(tokens.length != 0, "Can only run after at least one token is added");

        currentEpoch++;
        _startRound(currentEpoch);
        genesisStartOnce = true;
    }

    /**
     * @notice Lock genesis round
     * @dev Callable by operator
     */
    function genesisLockRound() external whenNotPaused onlyAdminOrOperator {
        require(genesisStartOnce, "Can only run after genesisStartRound is triggered");
        require(!genesisLockOnce, "Can only run genesisLockRound once");

        (uint256[] memory currentRoundIds, uint256[] memory currentPrices) = _getPricesFromOracle();

        for (uint256 i; i < tokens.length; i++) {
            supportedTokens[tokens[i]].oracleLatestRoundId = uint256(currentRoundIds[i]);

            _safeLockRound(tokens[i], currentEpoch, currentRoundIds[i], currentPrices[i]);
        }

        currentEpoch++;
        _startRound(currentEpoch);
        genesisLockOnce = true;
    }

    /**
     * @notice Claim all rewards in treasury
     * @dev Callable by admin
     */
    function claimTreasury() external nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        chips.transfer(adminAddress, currentTreasuryAmount);

        emit TreasuryClaim(currentTreasuryAmount);
    }

    /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin or operator
     */
    function pause() external whenNotPaused onlyAdminOrOperator {
        _pause();

        emit Pause(currentEpoch);
    }

    /**
     * @notice called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
    function unpause() external whenPaused onlyAdminOrOperator {
        genesisStartOnce = false;
        genesisLockOnce = false;
        _unpause();

        emit Unpause(currentEpoch);
    }

    /**
     * @notice Set buffer and interval (in seconds)
     * @dev Callable by admin
     */
    function setBufferAndIntervalSeconds(uint256 _bufferSeconds, uint256 _intervalSeconds)
        external
        whenPaused
        onlyAdminOrOperator
    {
        require(_bufferSeconds < _intervalSeconds, "bufferSeconds must be inferior to intervalSeconds");
        bufferSeconds = _bufferSeconds;
        intervalSeconds = _intervalSeconds;

        emit NewBufferAndIntervalSeconds(_bufferSeconds, _intervalSeconds);
    }

    /**
     * @notice Set minBetAmount
     * @dev Callable by admin
     */
    function setMinBetAmount(uint256 _minBetAmount) external whenPaused onlyAdmin {
        require(_minBetAmount != 0, "Must be superior to 0");
        minBetAmount = _minBetAmount;

        emit NewMinBetAmount(currentEpoch, minBetAmount);
    }

    /**
     * @notice Set maxBetAmount
     * @dev Callable by admin
     */
    function setMaxBetAmount(uint256 _maxBetAmount) external whenPaused onlyAdmin {
        require(_maxBetAmount != 0, "Must be superior to 0");
        maxBetAmount = _maxBetAmount;

        emit NewMaxBetAmount(currentEpoch, maxBetAmount);
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     */
    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;

        emit NewOperatorAddress(_operatorAddress);
    }

    /**
     * @notice Set oracle address
     * @dev Callable by admin
     * @param _oracleAddress: address of the oracle
     */
    function setOracle(address _oracleAddress) external onlyAdmin {
        require(_oracleAddress != address(0), "Cannot be zero address");
        _setSValueFeed(_oracleAddress);

        emit NewOracle(_oracleAddress);
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setFees(uint256 _treasuryFee, uint256 _stakingFee) external whenPaused onlyAdmin {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        require(_stakingFee <= MAX_STAKING_FEE, "Staking fee too high");
        treasuryFee = _treasuryFee;
        stakingFee = _stakingFee;

        emit NewFees(currentEpoch, treasuryFee, _stakingFee);
    }

    /**
     * @notice Set staking pool address and fee
     * @dev Callable by admin
     */
    function setStakingPool(address _stakingPoolAddress) external onlyAdmin {
        require(_stakingPoolAddress != address(0), "Cannot be zero address");
        stakingPoolAddress = _stakingPoolAddress;

        emit NewStakingPoolAddress(_stakingPoolAddress);
    }

    /**
     * @notice Set admin address
     * @dev Callable by owner
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;

        emit NewAdminAddress(_adminAddress);
    }

    /**
     * @notice Get a list of tokens
     */
    function getTokens() external view returns (address[] memory _tokens) {
        return tokens;
    }

    /**
     * @notice Get a list of token indexes
     */
    function getIndexes() external view returns (uint256[] memory _indexes) {
        return tokenIdexes;
    }

    /**
     * @notice Get a list of token symbols
     */
    function getSymbols() external view returns (string[] memory _symbols) {
        return tokenSymbols;
    }

    /**
     * @notice Returns round epochs and bet information for a user that has participated
     * @param user: user address
     * @param cursor: cursor
     * @param size: size
     */
    function getUserTokenRounds(address user, address token, uint256 cursor, uint256 size)
        external
        view
        returns (uint256[] memory, BetInfo[] memory, uint256)
    {
        uint256 length = size;

        if (length > userRounds[user][token].length - cursor) {
            length = userRounds[user][token].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][token][cursor + i];
            betInfo[i] = ledger[values[i]][user][token];
        }

        return (values, betInfo, cursor + length);
    }

    /**
     * @notice Returns round epochs length
     * @param user: user address
     */
    function getUserTokenRoundsLength(address user, address token) external view returns (uint256) {
        return userRounds[user][token].length;
    }

    /**
     * @notice Get the claimable amount stats of specific epoch and user account
     * @param token: token address
     * @param epoch: epoch
     * @param user: user address
     */
    function claimableAmount(address token, uint256 epoch, address user) public view returns (uint256 amount) {
        BetInfo memory betInfo = ledger[epoch][user][token];
        Round memory round = rounds[epoch];
        TokenRound memory tokenRound = tokenRounds[epoch][token];

        if (tokenRound.lockPrice == tokenRound.closePrice) {
            return 0;
        }
        return round.oracleCalled && betInfo.amount != 0 && !betInfo.claimed
            && (
                (tokenRound.closePrice > tokenRound.lockPrice && betInfo.position == Position.Up)
                    || (tokenRound.closePrice < tokenRound.lockPrice && betInfo.position == Position.Down)
            ) ? betInfo.amount * round.rewardAmount / round.rewardBaseCalAmount : 0;
    }

    /**
     * @notice Get the claimable stats of specific epoch and user account
     * @param token: token address
     * @param epoch: epoch
     * @param user: user address
     */
    function claimable(address token, uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user][token];
        Round memory round = rounds[epoch];
        TokenRound memory tokenRound = tokenRounds[epoch][token];

        if (tokenRound.lockPrice == tokenRound.closePrice) {
            return false;
        }
        return round.oracleCalled && betInfo.amount != 0 && !betInfo.claimed
            && (
                (tokenRound.closePrice > tokenRound.lockPrice && betInfo.position == Position.Up)
                    || (tokenRound.closePrice < tokenRound.lockPrice && betInfo.position == Position.Down)
            );
    }

    /**
     * @notice Get the refundable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function refundable(address token, uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user][token];
        Round memory round = rounds[epoch];
        return !round.oracleCalled && !betInfo.claimed && block.timestamp > round.closeTimestamp + bufferSeconds
            && betInfo.amount != 0;
    }

    /**
     * @notice Returns current pooled amount
     * @param epoch: epoch
     */
    function pooledRewards(uint256 epoch) external view returns (uint256 pooledAmount) {
        for (uint256 i; i < tokens.length; i++) {
            TokenRound memory tokenRound = tokenRounds[epoch][tokens[i]];
            pooledAmount += tokenRound.upAmount + tokenRound.downAmount;
        }
    }

    /**
     * @notice Calculate rewards for round
     * @param epoch: epoch
     */
    function _calculateRewards(uint256 epoch) internal {
        require(rounds[epoch].rewardBaseCalAmount == 0 && rounds[epoch].rewardAmount == 0, "Rewards calculated");

        Round storage round = rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 treasuryAmt;
        uint256 rewardAmount;
        uint256 unrewardedAmount;
        bool hasWinner;
        for (uint256 i; i < tokens.length; i++) {
            TokenRound storage tokenRound = tokenRounds[epoch][tokens[i]];
            uint256 totalAmount = tokenRound.upAmount + tokenRound.downAmount;
            // Up wins
            if (tokenRound.closePrice > tokenRound.lockPrice) {
                if (tokenRound.upAmount > 0) {
                    if (!hasWinner) hasWinner = true;
                    rewardBaseCalAmount += tokenRound.upAmount;
                    uint256 amountToTreasury = (totalAmount * treasuryFee) / 10000;
                    treasuryAmt += amountToTreasury;
                    rewardAmount += totalAmount - amountToTreasury;
                } else {
                    unrewardedAmount += totalAmount;
                }
            }
            // Down wins
            else if (tokenRound.closePrice < tokenRound.lockPrice) {
                if (tokenRound.downAmount > 0) {
                    if (!hasWinner) hasWinner = true;
                    rewardBaseCalAmount += tokenRound.downAmount;
                    uint256 amountToTreasury = (totalAmount * treasuryFee) / 10000;
                    treasuryAmt += amountToTreasury;
                    rewardAmount += totalAmount - amountToTreasury;
                } else {
                    unrewardedAmount += totalAmount;
                }
            }
            // House wins
            else {
                treasuryAmt += totalAmount;
            }
            if (unrewardedAmount > 0 && hasWinner) {
                uint256 toTreasury = (unrewardedAmount * treasuryFee) / 10000;
                rewardAmount += unrewardedAmount - toTreasury;
            } else {
                treasuryAmt += unrewardedAmount;
            }
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

        if (stakingPoolAddress != address(0)) {
            uint256 toStakingPool = treasuryAmt * stakingFee / 10000;
            chips.transfer(stakingPoolAddress, toStakingPool);
            treasuryAmt -= toStakingPool;
        }

        treasuryAmount += treasuryAmt;

        emit RewardsCalculated(epoch, round.rewardBaseCalAmount, round.rewardAmount, treasuryAmt);
    }

    /**
     * @notice End round
     * @param token: token address
     * @param epoch: epoch
     * @param roundId: roundId
     * @param price: price of the round
     */
    function _safeEndRound(address token, uint256 epoch, uint256 roundId, uint256 price) internal {
        require(rounds[epoch].lockTimestamp != 0, "Can only end round after round has locked");
        require(block.timestamp >= rounds[epoch].closeTimestamp, "Can only end round after closeTimestamp");
        require(
            block.timestamp <= rounds[epoch].closeTimestamp + bufferSeconds, "Can only end round within bufferSeconds"
        );

        TokenRound storage tokenRound = tokenRounds[epoch][token];
        tokenRound.closePrice = price;
        tokenRound.closeOracleId = roundId;

        emit EndRound(epoch, token, roundId, tokenRound.closePrice);
    }

    /**
     * @notice Lock round
     * @param token: token address
     * @param epoch: epoch
     * @param roundId: roundId
     * @param price: price of the round
     */
    function _safeLockRound(address token, uint256 epoch, uint256 roundId, uint256 price) internal {
        require(rounds[epoch].startTimestamp != 0, "Can only lock round after round has started");
        require(block.timestamp >= rounds[epoch].lockTimestamp, "Can only lock round after lockTimestamp");
        require(
            block.timestamp <= rounds[epoch].lockTimestamp + bufferSeconds, "Can only lock round within bufferSeconds"
        );
        Round storage round = rounds[epoch];
        round.closeTimestamp = block.timestamp + intervalSeconds;

        TokenRound storage tokenRound = tokenRounds[epoch][token];
        tokenRound.lockPrice = price;
        tokenRound.lockOracleId = roundId;

        emit LockRound(epoch, token, roundId, tokenRound.lockPrice);
    }

    /**
     * @notice Start round
     * Previous round n-2 must end
     * @param epoch: epoch
     */
    function _safeStartRound(uint256 epoch) internal {
        require(genesisStartOnce, "Can only run after genesisStartRound is triggered");
        require(rounds[epoch - 2].closeTimestamp != 0, "Can only start round after round n-2 has ended");
        require(
            block.timestamp >= rounds[epoch - 2].closeTimestamp,
            "Can only start new round after round n-2 closeTimestamp"
        );
        _startRound(epoch);
    }

    /**
     * @notice Start round
     * Previous round n-2 must end
     * @param epoch: epoch
     */
    function _startRound(uint256 epoch) internal {
        Round storage round = rounds[epoch];
        round.startTimestamp = block.timestamp;
        round.lockTimestamp = block.timestamp + intervalSeconds;
        round.closeTimestamp = block.timestamp + (2 * intervalSeconds);
        round.epoch = epoch;

        emit StartRound(epoch);
    }

    /**
     * @notice Transfer USDT in a safe way
     * @param to: address to transfer USDT to
     * @param value: USDT amount to transfer (6 decimals)
     */
    function _safeTransfer(address from, address to, uint256 value) internal {
        (bool success) = chips.transferFrom(from, to, value);
        require(success, "Transfer failed");
    }

    /**
     * @notice Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current timestamp must be within startTimestamp and closeTimestamp
     */
    function _bettable(uint256 epoch) internal view returns (bool) {
        return rounds[epoch].startTimestamp != 0 && rounds[epoch].lockTimestamp != 0
            && block.timestamp > rounds[epoch].startTimestamp && block.timestamp < rounds[epoch].lockTimestamp;
    }

    /**
     * @notice Get latest recorded price from oracle
     * If it falls below allowed buffer or has not updated, it would be invalid.
     */
    function _getPricesFromOracle() internal view returns (uint256[] memory, uint256[] memory) {
        uint256 leastAllowedTimestamp = block.timestamp + oracleUpdateAllowance;

        uint256[] memory roundIds = new uint256[](tokens.length);
        uint256[] memory prices = new uint256[](tokens.length);
        ISupraSValueFeed.dataWithoutHcc[] memory data;

        data = getPriceForMultiplePair(tokenIdexes);

        for (uint256 i; i < tokens.length; i++) {
            roundIds[i] = data[i].round;
            prices[i] = data[i].price;
            require(data[i].time / 1000 < leastAllowedTimestamp, "Oracle update exceeded max timestamp allowance");
            require(
                uint256(roundIds[i]) > supportedTokens[tokens[i]].oracleLatestRoundId,
                "Oracle update roundId must be larger than oracleLatestRoundId"
            );
        }

        return (roundIds, prices);
    }

    /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISupraSValueFeed {
    struct dataWithoutHcc {
        uint256 round;
        uint256 decimals;
        uint256 time;
        uint256 price;
    }

    function getSvalues(uint256[] memory _pairIndexes) external view returns (dataWithoutHcc[] memory);
}

contract SupraOracle {
    ISupraSValueFeed internal sValueFeed;

    function getPriceForMultiplePair(uint256[] memory _pairIndexes)
        public
        view
        returns (ISupraSValueFeed.dataWithoutHcc[] memory)
    {
        return sValueFeed.getSvalues(_pairIndexes);
    }

    function _setSValueFeed(address _sValueFeed) internal {
        sValueFeed = ISupraSValueFeed(_sValueFeed);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IClassic {
    enum Position {
        Up,
        Down
    }

    struct Oracle {
        uint256 oracleIndex;
        uint256 oracleLatestRoundId;
        bool supported;
    }

    struct Round {
        uint256 epoch;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool oracleCalled;
    }

    struct TokenRound {
        uint256 lockPrice;
        uint256 closePrice;
        uint256 lockOracleId;
        uint256 closeOracleId;
        uint256 upAmount;
        uint256 downAmount;
    }

    struct BetInfo {
        Position position;
        bool claimed;
        uint256 amount;
    }

    event BetDown(address indexed sender, uint256 indexed epoch, address indexed token, uint256 amount);
    event BetUp(address indexed sender, uint256 indexed epoch, address indexed token, uint256 amount);
    event Claim(address indexed sender, uint256 indexed epoch, address indexed token, uint256 amount);
    event EndRound(uint256 indexed epoch, address indexed token, uint256 indexed roundId, uint256 price);
    event LockRound(uint256 indexed epoch, address indexed token, uint256 indexed roundId, uint256 price);

    event NewAdminAddress(address admin);
    event NewBufferAndIntervalSeconds(uint256 bufferSeconds, uint256 intervalSeconds);
    event NewMinBetAmount(uint256 indexed epoch, uint256 minBetAmount);
    event NewMaxBetAmount(uint256 indexed epoch, uint256 maxBetAmount);
    event NewFees(uint256 indexed epoch, uint256 treasuryFee, uint256 stakingFee);
    event NewOperatorAddress(address operator);
    event NewOracle(address oracle);
    event NewOracleUpdateAllowance(uint256 oracleUpdateAllowance);
    event NewStakingPoolAddress(address stakingPool);
    event Pause(uint256 indexed epoch);
    event RewardsCalculated(
        uint256 indexed epoch, uint256 rewardBaseCalAmount, uint256 rewardAmount, uint256 treasuryAmount
    );

    event StartRound(uint256 indexed epoch);
    event TokenRecovery(address indexed token, uint256 amount);
    event TreasuryClaim(uint256 amount);
    event Unpause(uint256 indexed epoch);

    event TokenAdded(address token, uint256 oracleIndex, string symbol);
    event TokenUpdated(address token, uint256 oracleIndex, uint256 oracledLatestRound, bool supported, string symbol);
    event TokenRemoved(address token);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}