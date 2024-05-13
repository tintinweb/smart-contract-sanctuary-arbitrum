/**
 *Submitted for verification at Arbiscan.io on 2024-05-13
*/

// SPDX-License-Identifier: MIT
// --------------------------------------------------------------------
// Slot Game Contract: 5 May 2024
// Version: 2.0
// Written by: Web3Akash(https://www.x.com/web3akash)
// --------------------------------------------------------------------
// Website: https://kekw.gg/
// telegram: https://t.me/kekw_gg
// X.com/Twtter: https://x.com/kekw_gg
// Token: ($KEKW) 0x0DF596AD12F927e41EC317AF7DD666cA3574845f
// Uniswap: https://app.uniswap.org/swap?outputCurrency=0x0DF596AD12F927e41EC317AF7DD666cA3574845f
// Dextools: https://www.dextools.io/app/en/ether/pair-explorer/0x14ba508aaf2c15231f9df265980d1d461e54192b
// --------------------------------------------------------------------

pragma solidity 0.8.18;

interface Casino {
	function winnerCallback(address winnerAddress, uint256 totalBetAmount) external;

	function debitUserBalance(address _user, uint256 _amount) external;
}

contract SlotGame {
	Casino public casino;
	uint256 public MIN_BET = 0.00032 ether;
	uint256 public MAX_BET = 0.0032 ether;

	struct Game {
		uint256 index;
		uint256 betAmount;
		address player;
		address gameContractAddress;
		string playerOutcome;
	}

	Game[] public games;
	address public casinoAddress;
	address public manager;
	bool public paused;
	uint256 private randomness = 64;

	event GamePlayed(uint256 gameIndex, address playerAddress, string randomSeed, string playerOutcome);

	constructor(address _casino) {
		manager = msg.sender;
		casino = Casino(_casino);
		casinoAddress = _casino;
	}

	function updateCasino(address _casino) public restricted {
		casino = Casino(_casino);
		casinoAddress = _casino;
	}

	function updateMinBet(uint256 _betAmount) public restricted {
		require(_betAmount > 0, 'MIN_BET Amount should be greater than ZERO.');
		MIN_BET = _betAmount;
	}

	function updateMaxBet(uint256 _betAmount) public restricted {
		require(_betAmount > 0, 'MAX_BET Amount should be greater than ZERO.');
		MAX_BET = _betAmount;
	}

	function generateRandomString(uint256 length) private view returns (string memory) {
		require(length > 0, 'Length must be greater than 0');

		// Use block information and user address as a seed for randomness
		bytes32 previousBlockNumberHash = blockhash(block.number - 1);
		uint256 seed = uint256(keccak256(abi.encodePacked(previousBlockNumberHash, block.timestamp, msg.sender)));

		// Define characters to include in the random string
		string memory characters = 'zGdFr0xHfPwKs43yhRJDepMjX6mEai8OSIWqQTZclUYoB95tnvbLV2Ag17uCNk';

		// Generate the random string
		bytes memory randomString = new bytes(length);
		for (uint256 i = 0; i < length; i++) {
			// Get a pseudo-random index based on the seed
			uint256 charIndex = (seed + i) % bytes(characters).length;

			// Set the character in the random string
			randomString[i] = bytes(characters)[charIndex];
		}

		return string(randomString);
	}

	function random(address _player, string memory _userSeed) private view returns (uint256) {
		bytes32 previousBlockNumberHash = blockhash(block.number - 1);
		uint256 randomNumber = uint256(keccak256(abi.encodePacked(previousBlockNumberHash, _player, _userSeed)));
		return randomNumber;
	}

	function roll(address _player, string memory _userSeed) private view returns (uint256) {
		uint256 randomNumber = random(_player, _userSeed);
		return (randomNumber % 1000);
	}

	function calculatePayout(uint256 randomNumber) internal pure returns (uint256) {
		if (randomNumber > 0 && randomNumber % 111 == 0) {
			return 5; // Jackpot!
		} else if (randomNumber < 670) {
			return 0; // No win
		} else if (randomNumber < 849) {
			return 1; // Medium win
		} else if (randomNumber < 946) {
			return 2; // Big win
		} else {
			return 3; // Mega Win!
		}
	}

	function play(uint256 _betAmount) public notPaused returns (uint256, uint256) {
		require(_betAmount >= MIN_BET, 'Bet Amount should be greater or equal to MIN_BET.');
		require(_betAmount <= MAX_BET, 'Bet Amount should be lesser or equal to MAX_BET.');
		casino.debitUserBalance(msg.sender, _betAmount);
		Game storage game = games.push();
		uint256 _index = games.length - 1;
		game.index = _index;
		game.betAmount = _betAmount;
		game.gameContractAddress = address(this);
		game.player = msg.sender;

		string memory randomUserSeed = generateRandomString(randomness);
		uint256 playerOutcome = roll(game.player, randomUserSeed);
		uint256 payout = calculatePayout(playerOutcome) * game.betAmount;

		string memory playerOutcomeString = uintToString(playerOutcome);
		game.playerOutcome = playerOutcomeString;

		if (payout > 0) {
			casino.winnerCallback(game.player, payout);
		} else {
			casino.winnerCallback(casinoAddress, _betAmount);
		}
		emit GamePlayed(_index, game.player, randomUserSeed, playerOutcomeString);
		return (playerOutcome, payout);
	}

	function uintToString(uint256 value) private pure returns (string memory) {
		if (value == 0) {
			return '0';
		}

		uint256 temp = value;
		uint256 digits;

		while (temp > 0) {
			digits++;
			temp /= 10;
		}

		bytes memory buffer = new bytes(digits);
		while (value > 0) {
			digits--;
			buffer[digits] = bytes1(uint8(48 + (value % 10)));
			value /= 10;
		}

		return string(buffer);
	}

	function updateGameState(bool _paused) public restricted {
		paused = _paused;
	}

	modifier notPaused() {
		require(paused == false);
		_;
	}

	modifier restricted() {
		require(msg.sender == manager);
		_;
	}
}