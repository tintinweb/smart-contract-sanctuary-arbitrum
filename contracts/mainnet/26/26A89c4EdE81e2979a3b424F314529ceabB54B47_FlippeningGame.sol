// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./../interfaces/external/AggregatorV3Interface.sol";
import "./../interfaces/games/IFlippeningGame.sol";
import "./../interfaces/games/IFlippeningGameManagement.sol";
import "./../interfaces/external/ISwapRouter.sol";
import "./../interfaces/external/IWETH9.sol";

import "./HunchGame.sol";

import "./../MultiplierLib.sol";

contract FlippeningGame is IFlippeningGame, IFlippeningGameManagement, ReentrancyGuard, HunchGame {

	struct FlippeningBetInfo {
        uint256 marketCapRatio; // Ratio is [0, MAX_PERCENTAGE], with MAX_PERCENTAGE being 1.0
        uint256 date;
        bool claimedWin;
        bool claimedReward;
    }

    uint256 public constant MAX_ALLOWED_RATIO = 9500;

    uint256 public constant FLIPPENING_GAME_ID = 1;

    uint256 public constant BETS_STATE = 0;
    uint256 public constant CLAIM_STATE = 1;

    uint256 public constant FLIPPENING_WIN_MIN_DIST_PERIOD = 1 weeks;
    uint256 public constant CLAIM_WIN_PERIOD = 1 weeks;
    uint256 public constant COLLECT_REWARD_MAX_PERIOD = 1 weeks;

    uint256 public constant MAX_POSITIONS_TO_COLLECT = 1000;

    uint256 public constant COLLECT_REWARDS_SLIPPAGE = 100;

    uint256 public constant FINDERS_FEE_PERCENTAGE = 100;
    uint256 public constant MAX_FINDERS_FEE_AMOUNT = 1 ether;

    mapping(uint256 => FlippeningBetInfo) public bets;

    uint256[] public notCollectedTicketIds;
    uint256 public nextNonCollectedTicketIdIndex;

    uint256 public state = BETS_STATE;
    uint256 public flippeningDate;
    uint256 public totalClaimedAmount;
    uint256 public totalReward;

    AggregatorV3Interface public ethMarketCapOracle;
    AggregatorV3Interface public btcMarketCapOracle;

    IWETH9 public weth;
    ISwapRouter public router;

    bool public isAlpha = true;
    bool public isCanceled = false;
    bool public hasWon = false;

    uint256[] public amountMultiplierXValues = [0.01 ether, 0.1 ether, 1 ether, 2 ether, 4 ether, 10 ether];
    uint256[] public amountMultiplierYValues = [1e4, 2e4, 2.5e4, 3e4, 3.5e4, 4e4];

    uint256[] public ratioMultiplierXValues = [0, 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000, 6500, 7000, 7500, 8000, 8500, 9000, 9500];
    uint256[] public ratioMultiplierYValues = [1000e4, 300e4, 100e4, 80e4, 50e4, 25e4, 14e4, 10e4, 7e4, 5.5e4, 
    	5e4, 4.5e4, 4e4, 3.5e4, 3e4, 2.5e4, 2e4, 1.5e4, 1e4, 1000];

    uint256[] public proximityMultiplierXValues = [1 hours, 4 hours, 12 hours, 1 days, 2 days, 3 days, 4 days, 5 days, 6 days, 7 days];
    uint256[] public proximityMultiplierYValues = [25e4, 16e4, 12e4, 9e4, 6e4, 4e4, 3e4, 2e4, 1.3e4, 1e4];

    modifier notCanceled {
    	require(!isCanceled, "Game canceled");
    	_;
    }

    constructor(AggregatorV3Interface _ethMarketCapOracle, AggregatorV3Interface _btcMarketCapOracle, ITicketFundsProvider _ticketFundsProvider, ISwapRouter _router, IWETH9 _weth, address payable _treasury) 
    		HunchGame("Hunch Flippening Ticket", "HUNCH-FLIP", _ticketFundsProvider, _treasury) {
    	gameId = FLIPPENING_GAME_ID;

        ethMarketCapOracle = _ethMarketCapOracle;
        btcMarketCapOracle = _btcMarketCapOracle;
        router = _router;
        weth = _weth;
    }
	
	function buyETHTicket(uint256 _flippeningDate) external payable override nonReentrant notCanceled returns (uint256 ticketId) {
		require(msg.value >= amountMultiplierXValues[0], "Not enough ETH");
		validateBet(_flippeningDate);

		TicketFundsInfo memory ticket;
		uint256 treasuryFees;
		uint256 multiplier;

		(ticketId, ticket, treasuryFees, multiplier) = createETHTicket(msg.value);

		uint256 marketCapRatio = createBet(ticketId, _flippeningDate);

		emit BuyETHTicket(msg.sender, ticketId, _flippeningDate, marketCapRatio, msg.value, 
			treasuryFees, ticket.amount, ticket.multipliedAmount, multiplier);
	}

	function buyPositionETHTicket(uint256 _positionTokenId, uint256 _flippeningDate, uint256 _token0ETHPrice, uint256 _token1ETHPrice) external override nonReentrant notCanceled returns (uint256 ticketId) {
		validateBet(_flippeningDate);

		TicketFundsInfo memory ticket;
		uint256 treasuryFees;
		uint256 multiplier;

		(ticketId, ticket, treasuryFees, multiplier) = createETHTicketFromPosition(_positionTokenId, _token0ETHPrice, _token1ETHPrice);
		uint256 marketCapRatio = createBet(ticketId, _flippeningDate);

		emit BuyPositionETHTicket(msg.sender, ticketId, _flippeningDate, marketCapRatio, _positionTokenId, ticket.amount + treasuryFees, 
			treasuryFees, ticket.amount, ticket.multipliedAmount, multiplier);
	}

	function buyPositionTicket(uint256 _positionTokenId, uint256 _flippeningDate) external override nonReentrant notCanceled returns (uint256 ticketId) {
		validateBet(_flippeningDate);
		ticketId = createPositionTicket(_positionTokenId);
		uint256 marketCapRatio = createBet(ticketId, _flippeningDate);
		notCollectedTicketIds.push(ticketId);

		emit BuyPositionTicket(msg.sender, ticketId, _flippeningDate, marketCapRatio, _positionTokenId);
	}

	function closePositionTicket(uint256 _ticketId, uint256 _token0ETHPrice, uint256 _token1ETHPrice) external override nonReentrant notCanceled {
		updatePositionTicket(_ticketId, _token0ETHPrice, _token1ETHPrice, true);
	}

	function flip() external override nonReentrant notCanceled {
		require(state == BETS_STATE, "Already flipped");

		(, int256 ethMarketCap,,,) = ethMarketCapOracle.latestRoundData();
		(, int256 btcMarketCap,,,) = btcMarketCapOracle.latestRoundData();
		require(ethMarketCap > btcMarketCap, "No flippening");

		flippeningDate = block.timestamp;
		state = CLAIM_STATE;

		emit Flip(block.timestamp);
	}

	function claimWin(uint256 _ticketId, uint256 _token0ETHPrice, uint256 _token1ETHPrice) external override nonReentrant notCanceled {
		require(ownerOf(_ticketId) == msg.sender, "Not allowed");
		require(state == CLAIM_STATE, "Not allowed");
		require(block.timestamp - flippeningDate < CLAIM_WIN_PERIOD, "Too late");

		FlippeningBetInfo memory betInfo = bets[_ticketId];
		require(betInfo.date > 0, "No ticket");

		TicketFundsInfo memory fundsInfo = tickets[_ticketId];
		verifyTicketExists(fundsInfo);

		require(!betInfo.claimedWin, "Already claimed");

		require(betInfo.date >= flippeningDate - FLIPPENING_WIN_MIN_DIST_PERIOD && betInfo.date <= flippeningDate + FLIPPENING_WIN_MIN_DIST_PERIOD, "Losing bet");

		uint256 multipliedAmount = fundsInfo.multipliedAmount;
		if (fundsInfo.tokenId != 0) {
			(multipliedAmount,,) = updatePositionTicket(_ticketId, _token0ETHPrice, _token1ETHPrice, true);
		}

		uint256 ratioMultiplier = getRatioMultiplier(betInfo.marketCapRatio);
		multipliedAmount = multipliedAmount * ratioMultiplier / ONE_MULTIPLIER;
		uint256 distanceMultiplier = getFlippeningDistanceMultiplier(betInfo.date);
		multipliedAmount = multipliedAmount * distanceMultiplier / ONE_MULTIPLIER;

		totalClaimedAmount += multipliedAmount;
		tickets[_ticketId].multipliedAmount = multipliedAmount;
		bets[_ticketId].claimedWin = true;
		hasWon = true;

		emit ClaimWin(msg.sender, _ticketId, multipliedAmount, ratioMultiplier, distanceMultiplier);
	}

	function convertFunds(IERC20 _token, uint256 _amount, uint24 _poolFee, uint256 _tokenPrice) external override onlyOwner notCanceled returns (uint256 ethAmount) {
		verifyCollectRewardsState();

		_token.approve(address(router), _amount);
		ethAmount = router.exactInput(ISwapRouter.ExactInputParams(abi.encodePacked(address(_token), _poolFee, address(weth)), address(this), block.timestamp, 
            _amount, _amount * _tokenPrice / 10 ** ticketFundsProvider.getPricePrecisionDecimals()));
		weth.withdraw(ethAmount);

		emit ConvertFunds(_token, _amount, _poolFee, _tokenPrice, ethAmount);
	}

	function collectRewards(uint256 _maxPositionsToCollect) external override nonReentrant notCanceled returns (uint256 findersFee) {
		require(_maxPositionsToCollect > 0, "Max positions must be non-zero");
		verifyCollectRewardsState();

		uint256 notCollectedTicketIdsNum = notCollectedTicketIds.length;
		require(nextNonCollectedTicketIdIndex < notCollectedTicketIdsNum, "Collection already done");

		uint256 ethCollected = 0;
		uint256 nonCollectedTicketIdIndex = nextNonCollectedTicketIdIndex;

		uint256 nonCollectedTicketIdsIndexMax = notCollectedTicketIdsNum - nonCollectedTicketIdIndex >= _maxPositionsToCollect ? 
			nonCollectedTicketIdIndex + _maxPositionsToCollect : notCollectedTicketIdsNum;
		while (nonCollectedTicketIdIndex < nonCollectedTicketIdsIndexMax) {
			uint256 ticketId = notCollectedTicketIds[nonCollectedTicketIdIndex];
			uint256 positionId = tickets[ticketId].tokenId;

			// Make sure ticket was not closed already
			if (positionId != 0) {
				(uint256 ethAmount,) = ticketFundsProvider.getFundsWithoutPrices(positionId, ticketId, COLLECT_REWARDS_SLIPPAGE);
				ethCollected += ethAmount;

				emit CollectRewards(ticketId, positionId, ethAmount);
			}

			nonCollectedTicketIdIndex++;
		}

		nextNonCollectedTicketIdIndex = nonCollectedTicketIdIndex;

		findersFee = ethCollected * FINDERS_FEE_PERCENTAGE / MAX_PERCENTAGE;
		if (findersFee > MAX_FINDERS_FEE_AMOUNT) {
			findersFee = MAX_FINDERS_FEE_AMOUNT;
		}

		uint256 treasuryAmount = getTreasuryAmount(ethCollected - findersFee);

		(bool sentFindersFee, ) = payable(msg.sender).call{value: findersFee}("");
		require(sentFindersFee, "Failed to send finders fee");

		sendToTreasury(treasuryAmount);
	}

	function claimReward(uint256 _ticketId) external nonReentrant override {
		require(ownerOf(_ticketId) == msg.sender, "Not allowed");
		require(canClaimReward(), "Not allowed");

		FlippeningBetInfo memory betInfo = bets[_ticketId];
		require(betInfo.date > 0, "No ticket");

		TicketFundsInfo memory fundsInfo = tickets[_ticketId];
		verifyTicketExists(fundsInfo);

		require(!betInfo.claimedReward, "Already rewarded");

		uint256 reward = 0;
		if (isCanceled || !hasWon) {
			// If ticket not closed, just unstake it, no ETH reward
			if (fundsInfo.tokenId != 0) {
				ticketFundsProvider.unstakeForOwner(fundsInfo.tokenId, msg.sender, _ticketId);
			} else {
				reward = fundsInfo.amount;	
			}
		} else if (!betInfo.claimedWin) {
			// If game was not cancelled and there is a winner, then revert if win was not claimed
			revert("Nothing to claim");
		} else {
			if (totalReward == 0) {
				totalReward = address(this).balance;
			}

			reward = fundsInfo.multipliedAmount * totalReward / totalClaimedAmount;
		}

		bets[_ticketId].claimedReward = true;

		if (reward > 0) {
			(bool sentReward, ) = payable(msg.sender).call{value: reward}("");
			require(sentReward, "Failed to send reward");
		}

		emit ClaimReward(msg.sender, _ticketId, reward, fundsInfo.multipliedAmount, totalReward, totalClaimedAmount);
	}

	function setNonAlpha() external override onlyOwner notCanceled {
		isAlpha = false;

		emit SetNonAlpha();
	}

	function cancelGame() external override onlyOwner notCanceled {
		require(isAlpha, "Not allowed");
		isCanceled = true;

		emit CancelGame();
	}

	function setAmountMultiplier(uint256[] calldata _amounts, uint256[] calldata _multipliers) external override onlyOwner {
		require(isAlpha, "Not allowed");
		require(_amounts.length > 0, "Array empty");
		require(_amounts.length == _multipliers.length, "Lengths differ");
		MultiplierLib.validateOrder(_amounts, true, false);
		MultiplierLib.validateOrder(_multipliers, true, true);

		amountMultiplierXValues = _amounts;
		amountMultiplierYValues = _multipliers;

		emit SetAmountMultiplier(_amounts, _multipliers);
	}

	function setRatioMultiplier(uint256[] calldata _ratios, uint256[] calldata _multipliers) external override onlyOwner {
		require(isAlpha, "Not allowed");
		require(_ratios.length > 0, "Array empty");
		require(_ratios.length == _multipliers.length, "Lengths differ");
		MultiplierLib.validateOrder(_ratios, true, false);
		MultiplierLib.validateOrder(_multipliers, false, true);
		MultiplierLib.validateRatio(_ratios);

		ratioMultiplierXValues = _ratios;
		ratioMultiplierYValues = _multipliers;

		emit SetRatioMultiplier(_ratios, _multipliers);
	}

	function setProximityMultiplier(uint256[] calldata _timeDiffs, uint256[] calldata _multipliers) external override onlyOwner {
		require(isAlpha, "Not allowed");
		require(_timeDiffs.length > 0, "Array empty");
		require(_timeDiffs.length == _multipliers.length, "Lengths differ");
		MultiplierLib.validateOrder(_timeDiffs, true, false);
		MultiplierLib.validateProximity(_timeDiffs);
		MultiplierLib.validateOrder(_multipliers, false, true);

		proximityMultiplierXValues = _timeDiffs;
		proximityMultiplierYValues = _multipliers;

		emit SetProximityMultiplier(_timeDiffs, _multipliers);
	}

	function getMultipliedETHAmount(uint256 _ethAmount, uint256 /*_ticketId*/) public view override(HunchGame, IFlippeningGame)
		returns (uint256 multipliedETHAmount, uint256 multiplier) {
			multiplier = MultiplierLib.calculateMultiplier(_ethAmount, amountMultiplierXValues, amountMultiplierYValues);
			multipliedETHAmount = _ethAmount * multiplier / ONE_MULTIPLIER;
	}

	function getRatioMultiplier(uint256 _ratio) public view override returns (uint256 multiplier) {
		return MultiplierLib.calculateMultiplier(_ratio, ratioMultiplierXValues, ratioMultiplierYValues);
	}

	function getFlippeningDistanceMultiplier(uint256 _betDate) public view override returns (uint256) {
		uint256 _proximity = _betDate > flippeningDate ? _betDate - flippeningDate : flippeningDate - _betDate;
		return MultiplierLib.calculateMultiplier(_proximity, proximityMultiplierXValues, proximityMultiplierYValues);
	}

	function canClaimReward() public view override returns (bool) {
		return isCanceled || (state == CLAIM_STATE && block.timestamp - flippeningDate > CLAIM_WIN_PERIOD + COLLECT_REWARD_MAX_PERIOD);
	}

	function strengthOf(uint256 _ticketId) external view override returns (uint256 strength, uint256 amountMultiplier, uint256 ratioMultiplier, uint256 proximityMultiplier) {
		TicketFundsInfo memory fundsInfo = tickets[_ticketId];
		verifyTicketExists(fundsInfo);

		FlippeningBetInfo memory betInfo = bets[_ticketId];

		if (fundsInfo.tokenId != 0) {
			(uint256 totalTimeMultipliedETHFees,, ) = 
				ticketFundsProvider.getTimeMultipliedFees(fundsInfo.tokenId);
			(strength, amountMultiplier) = getMultipliedETHAmount(totalTimeMultipliedETHFees, _ticketId);
		} else {
			strength = fundsInfo.multipliedAmount;

			// Reverse treasury calculation to get original amount, and get amount multiplier
			(, amountMultiplier) = getMultipliedETHAmount(getAmountBeforeTreasury(fundsInfo.amount), _ticketId);
		}

		ratioMultiplier = getRatioMultiplier(betInfo.marketCapRatio);
		
		if (!betInfo.claimedWin) {
			strength = strength * ratioMultiplier / ONE_MULTIPLIER;
		}

		proximityMultiplier = ONE_MULTIPLIER;
		if (flippeningDate != 0) {
			proximityMultiplier = getFlippeningDistanceMultiplier(betInfo.date);
			
			if (!betInfo.claimedWin) {
				strength = strength * proximityMultiplier / ONE_MULTIPLIER;
			}
		}
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
		require(tickets[tokenId].tokenId == 0, "Cannot transfer open ticket");
		super._beforeTokenTransfer(from, to, tokenId);
    }

	function createBet(uint256 _ticketId, uint256 _flippeningDate) private returns (uint256 marketCapRatio) {
		(, int256 ethMarketCap,,,) = ethMarketCapOracle.latestRoundData();
		(, int256 btcMarketCap,,,) = btcMarketCapOracle.latestRoundData();
		marketCapRatio = uint256(ethMarketCap) * MAX_PERCENTAGE / uint256(btcMarketCap);

		require(marketCapRatio <= MAX_ALLOWED_RATIO, "Flippening too close");

		bets[_ticketId] = FlippeningBetInfo(marketCapRatio, _flippeningDate, false, false);
	}

	function validateBet(uint256 _flippeningDate) private view {
		require(state == BETS_STATE, "Bets over");
		require(_flippeningDate > block.timestamp, "Cannot bet on past");
	}

	function verifyTicketExists(TicketFundsInfo memory fundsInfo) private pure {
		require(fundsInfo.amount > 0 || fundsInfo.tokenId != 0, "No ticket");
	}

	function verifyCollectRewardsState() private view {
		require(state == CLAIM_STATE && hasWon, "Not allowed");
		require(block.timestamp - flippeningDate >= CLAIM_WIN_PERIOD, "Too early");
		require(block.timestamp - flippeningDate <= CLAIM_WIN_PERIOD + COLLECT_REWARD_MAX_PERIOD, "Too late");
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IFlippeningGame  {

	// Note: In all events, marketCapRatio is the market cap btc/eth ratio with 1.0 defined as 10000,
	// and all multiplier (amount, ratio and distance) are based on 1.0 equaling 10000 (defined in ONE_MULTIPLIER)
	// Fees parameters are fees paid to treasury in ETH

	event BuyETHTicket(address indexed account, uint256 indexed ticketId, uint256 flippeningDate, uint256 marketCapRatio,
		uint256 ethAmount, uint256 fees, uint256 ticketETHAmount, uint256 ticketMultipliedETHAmount, uint256 amountMultiplier);
	event BuyPositionETHTicket(address indexed account, uint256 indexed ticketId, uint256 flippeningDate, uint256 marketCapRatio,
		uint256 indexed positionTokenId, uint256 ethAmount, uint256 fees, uint256 ticketETHAmount, 
		uint256 ticketMultipliedETHAmount, uint256 amountMultiplier);
	event BuyPositionTicket(address indexed account, uint256 indexed ticketId, uint256 flippeningDate, uint256 marketCapRatio, 
		uint256 indexed positionTokenId);

	event Flip(uint256 flippeningDate);
	event ClaimWin(address indexed account, uint256 ticketId, uint256 multipliedAmount, uint256 ratioMultiplier, 
		uint256 distanceMultiplier);
	event CollectRewards(uint256 ticketId, uint256 positionTokenId, uint256 ethAmount);
	event ClaimReward(address indexed account, uint256 ticketId, uint256 reward, 
		uint256 multipliedAmount, uint256 totalReward, uint256 totalClaimedMultipliedAmount);

	function buyETHTicket(uint256 flippeningDate) external payable returns (uint256 ticketId);

	// Note: price values are pool token prices with 12 decimals (defined in PRECISION_DECIMALS of the UniswapHelper contract)
	function buyPositionETHTicket(uint256 positionTokenId, uint256 flippeningDate, uint256 token0ETHPrice, uint256 token1ETHPrice) external returns (uint256 ticketId);

	function buyPositionTicket(uint256 positionTokenId, uint256 flippeningDate) external returns (uint256 ticketId);

	// Note: price values are pool token prices with 12 decimals (defined in PRECISION_DECIMALS of the UniswapHelper contract)
	function closePositionTicket(uint256 ticketId, uint256 token0ETHPrice, uint256 token1ETHPrice) external;

	function flip() external;

	// Note: price values are pool token prices with 12 decimals (defined in PRECISION_DECIMALS of the UniswapHelper contract),
	function claimWin(uint256 ticketId, uint256 token0ETHPrice, uint256 token1ETHPrice) external;

	function collectRewards(uint256 maxPositionsToCollect) external returns (uint256 findersFee);
	function claimReward(uint256 ticketId) external;

	// Multiplier is based on 1.0 equaling 10000 (defined in ONE_MULTIPLIER)
	function getMultipliedETHAmount(uint256 ethAmount, uint256 /*ticketId*/) external view returns (uint256 multipliedETHAmount, uint256 multiplier);

	// Note: ratio is the market cap btc/eth ratio with 1.0 defined as 10000
	// Multiplier is based on 1.0 equaling 10000 (defined in ONE_MULTIPLIER)
	function getRatioMultiplier(uint256 ratio) external view returns (uint256 multiplier);

	function getFlippeningDistanceMultiplier(uint256 betDate) external view returns (uint256);
	function canClaimReward() external view returns (bool);

	// Note: all multipliers are based on 1.0 equaling 10000 (defined in ONE_MULTIPLIER)
	// Strength is a virtual amount based on initial eth amount in the ticket, multiplied by all mutlipliers	
	function strengthOf(uint256 ticketId) external view returns (uint256 strength, uint256 amountMultiplier, uint256 ratioMultiplier, uint256 proximityMultiplier);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlippeningGameManagement {
	event SetNonAlpha();
	event CancelGame();
	event ConvertFunds(IERC20 token, uint256 amount, uint24 poolFee, uint256 tokenPrice, uint256 ethAmount);
	event SetAmountMultiplier(uint256[] amounts, uint256[] multipliers);
	event SetRatioMultiplier(uint256[] ratios, uint256[] multipliers);
	event SetProximityMultiplier(uint256[] timeDiffs, uint256[] multipliers);

	function setNonAlpha() external;
	function cancelGame() external;

	// Note: price is a pool token price with 12 decimals (defined in PRECISION_DECIMALS of the UniswapHelper contract)
	function convertFunds(IERC20 token, uint256 amount, uint24 poolFee, uint256 tokenPrice) external returns (uint256 ethAmount);

	// Note: all multipliers are based on 1.0 equaling 10000 (defined in ONE_MULTIPLIER)
	function setAmountMultiplier(uint256[] calldata amounts, uint256[] calldata multipliers) external;
	function setRatioMultiplier(uint256[] calldata ratios, uint256[] calldata multipliers) external;
	function setProximityMultiplier(uint256[] calldata timeDiffs, uint256[] calldata multipliers) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./../interfaces/games/IHunchGame.sol";
import "./../interfaces/ITicketFundsProvider.sol";

abstract contract HunchGame is ERC721Enumerable, IHunchGame, Ownable {
    struct TicketFundsInfo {
        uint256 amount;
        uint256 multipliedAmount;
        uint256 tokenId;
    }

    uint256 public constant ONE_MULTIPLIER = 10000;
    uint256 public constant TREASURY_PERCENTAGE = 500;
    uint256 public constant MAX_PERCENTAGE = 10000;

    uint256 public override gameId;
    uint256 public nextTicketId = 1;

    ITicketFundsProvider public ticketFundsProvider;

    mapping(uint256 => TicketFundsInfo) public tickets;

    address payable public treasury;

    constructor(
        string memory _name,
        string memory _symbol,
        ITicketFundsProvider _ticketFundsProvider,
        address payable _treasury
    ) ERC721(_name, _symbol) {
        require(_treasury != address(0), "Bad address");
        require(address(_ticketFundsProvider) != address(0), "Bad address");

        ticketFundsProvider = _ticketFundsProvider;
        treasury = _treasury;
    }

    receive() external payable {
        // Declared empty to simply allow contract to accept ETH (for ETH bet tickets)
    }

    function setTreasury(address payable _treasury) external override onlyOwner {
        require(_treasury != address(0), "Bad address");
        treasury = _treasury;
    }

    function createETHTicket(uint256 _ethAmount) internal 
            returns (uint256 ticketId, TicketFundsInfo memory ticket, uint256 treasuryAmount, uint256 multiplier) {

        require(_ethAmount > 0, "Amount not positive");
        return createAmountTicket(_ethAmount, _ethAmount);
    }

    function createETHTicketFromPosition(uint256 _tokenId, uint256 _token0ETHPrice, uint256 _token1ETHPrice) internal 
            returns (uint256 ticketId, TicketFundsInfo memory ticket, uint256 treasuryAmount, uint256 multiplier) {
        ticketId = createPositionTicket(_tokenId);
        (, multiplier, treasuryAmount) = updatePositionTicket(ticketId, _token0ETHPrice, _token1ETHPrice, false);

        ticket = tickets[ticketId];
    }

    function createPositionTicket(uint256 _tokenId) internal returns (uint256 ticketId)
    {
        (address owner,,,,,) = ticketFundsProvider.stakedPositions(_tokenId);
        if (owner != address(0)) {
            require(owner == msg.sender, "Not allowed");
        }

        ticketId = mintTicket();
        tickets[ticketId] = TicketFundsInfo(0, 0, _tokenId);

        if (owner == address(0)) {
            ticketFundsProvider.stakeWithTicket(_tokenId, msg.sender, ticketId);
        } else {
            ticketFundsProvider.updateTicketInfo(_tokenId, msg.sender, ticketId);
        }
    }

    // Multiplier returend format: ONE_MULTIPLIER (10000) represents a multiplier of 1.0
    function updatePositionTicket(uint256 _ticketId, uint256 _token0ETHPrice, uint256 _token1ETHPrice, bool _raiseCloseEvent) internal returns (uint256 multipliedAmount, uint256 multiplier, uint256 treasuryAmount) {
        require(ownerOf(_ticketId) == msg.sender, "Not allowed");

        TicketFundsInfo storage ticket = tickets[_ticketId];

        require(ticket.tokenId != 0, "Not position ticket");

        (uint256 ethAmount, uint256 timeMultipliedETHAmount) = ticketFundsProvider.getFunds(
            ticket.tokenId, msg.sender, _ticketId, _token0ETHPrice, _token1ETHPrice);
        require(ethAmount > 0, "No fees");

        treasuryAmount = getTreasuryAmount(ethAmount);
        uint256 tokenId = ticket.tokenId;
        ticket.tokenId = 0;
        ticket.amount = ethAmount - treasuryAmount;

        (multipliedAmount, multiplier) = getMultipliedETHAmount(timeMultipliedETHAmount, _ticketId);

        ticket.multipliedAmount = multipliedAmount;

        sendToTreasury(treasuryAmount);

        if (_raiseCloseEvent) {
            emit ClosePositionTicket(msg.sender, _ticketId, tokenId, ticket.amount + treasuryAmount, 
                treasuryAmount, ticket.amount, ticket.multipliedAmount, multiplier);
        }
    }

    function getMultipliedETHAmount(uint256 _ethAmount, uint256 _ticketId) public virtual 
        returns (uint256 multipliedETHAmount, uint256 multiplier);

    function createAmountTicket(uint256 _ethAmount, uint256 _timeMultipliedETHAmount) private 
            returns (uint256 ticketId, TicketFundsInfo memory ticket, uint256 treasuryAmount, uint256 multiplier) {

        treasuryAmount = getTreasuryAmount(_ethAmount);

        ticketId = mintTicket();

        uint256 multipliedAmount;
        (multipliedAmount, multiplier) = getMultipliedETHAmount(_timeMultipliedETHAmount, ticketId);
        ticket = TicketFundsInfo(_ethAmount - treasuryAmount, multipliedAmount, 0);
        tickets[ticketId] = ticket;

        sendToTreasury(treasuryAmount);   
    }

    function mintTicket() private returns (uint256 ticketId) {
        ticketId = nextTicketId++;
        _safeMint(msg.sender, ticketId);
    }

    function sendToTreasury(uint256 _ethAmount) internal {
        (bool sentToTreasury, ) = treasury.call{value: _ethAmount}("");
        require(sentToTreasury, "Failed to send to treasury");
    }

    function getTreasuryAmount(uint256 _ethAmount) internal pure returns (uint256 treasuryAmount)
    {
        treasuryAmount = _ethAmount * TREASURY_PERCENTAGE / MAX_PERCENTAGE;
    }

    function getAmountBeforeTreasury(uint256 _ethAmount) internal pure returns (uint256 amountBeforeTreasury) {
        amountBeforeTreasury = _ethAmount * MAX_PERCENTAGE / (MAX_PERCENTAGE - TREASURY_PERCENTAGE);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library MultiplierLib {

	uint256 public constant MAX_REWARDED_PROXIMITY = 1 weeks;
	uint256 public constant MAX_POSSIBLE_RATIO = 10000;

	function calculateMultiplier(uint256 _x, uint256[] memory _xValues, uint256[] memory _yValues) internal pure returns (uint256) {
		uint256 xValuesNum = _xValues.length;
		uint256 firstBiggerIndex = xValuesNum;
		uint256 currXValue = 0;
		uint256 lastXValue = 0;
		for (uint256 i = 0; i < xValuesNum; i++) {

			if (i > 0) {
				lastXValue = currXValue;
			}
			currXValue = _xValues[i];

			if (currXValue > _x) {
				firstBiggerIndex = i;
				break;
			}
		}

		if (firstBiggerIndex == xValuesNum) {
			return _yValues[_yValues.length - 1];
		} else if (firstBiggerIndex == 0) {
			return _yValues[0];
		} else {
			return (_yValues[firstBiggerIndex] * (_x - lastXValue) + _yValues[firstBiggerIndex - 1] * (currXValue - _x)) / 
				(currXValue - lastXValue);
		}
	}

	function validateOrder(uint256[] memory _yValues, bool isAscending, bool notZero) internal pure {
		for (uint256 i = 0; i < _yValues.length - 1; i++) {
			require(!notZero || _yValues[i] > 0, "Not positive");

			if (isAscending) {
				require(_yValues[i] <= _yValues[i + 1], "Not ascending");
			} else {
				require(_yValues[i] >= _yValues[i + 1], "Not descending");
			}
		}
	}

	function validateProximity(uint256[] memory _values) internal pure {
		for (uint256 i = 0; i < _values.length; i++) {	
			require (_values[i] <= MAX_REWARDED_PROXIMITY, "Proximity domain too big");
		}
	}

	function validateRatio(uint256[] memory _values) internal pure {
		for (uint256 i = 0; i < _values.length; i++) {	
			require (_values[i] < MAX_POSSIBLE_RATIO, "Ratio domain too big");
		}
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IHunchGame {

	// Note: Amount multiplier is based on 1.0 equaling 10000 (defined in ONE_MULTIPLIER),
	// sees parameter consist of fees paid to treasury in ETH
	event ClosePositionTicket(address indexed account, uint256 indexed ticketId, uint256 indexed positionTokenId, 
		uint256 ethAmount, uint256 fees, uint256 ticketETHAmount, uint256 ticketMultipliedETHAmount, uint256 amountMultiplier);
	
	function gameId() view external returns (uint256 id);

	function setTreasury(address payable treasury) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface ITicketFundsProvider {
	event GetConvertedFunds(address indexed owner, uint256 indexed tokenId, uint256 ethAmount, uint256 timeMultipliedETHAmount,
		uint256 timeMultiplier, uint256 initialToken0Fees, uint256 initialToken1Fees, 
		uint256 collectedToken0Fees, uint256 collectedToken1Fees, uint256 token0ETHAmount, uint256 token1ETHAmount);
	event GetFunds(address indexed owner, uint256 indexed tokenId, uint256 collectedToken0Fees, uint256 collectedToken1Fees);

	// Note: price values are pool token prices with 12 decimals (defined in PRECISION_DECIMALS of the UniswapHelper contract)
	function getFunds(uint256 tokenId, address owner, uint256 ticketId, uint256 token0ETHPrice, uint256 token1ETHPrice) external returns (uint256 ethAmount, uint256 timeMultipliedETHAmount);
	function getFundsWithoutPrices(uint256 tokenId, uint256 ticketId, uint256 slippage) external returns (uint256 ethAmount, uint256 timeMultipliedETHAmount);

	function stakeWithTicket(uint256 tokenId, address owner, uint256 ticketId) external;
	function updateTicketInfo(uint256 tokenId, address owner, uint256 ticketId) external;
	function unstakeForOwner(uint256 tokenId, address owner, uint256 ticketId) external;

	function stakedPositions(uint256 tokenId) view external returns (address owner, uint256 timestamp, uint256 token0SFees, uint256 token1Fees, uint256 gameId, uint256 ticketId);
	function getTimeMultipliedFees(uint256 tokenId) external view returns (uint256 totalTimeMultipliedETHFees, uint256 timeMultiplier, uint256 totalETHFees);
	function getPricePrecisionDecimals() view external returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}