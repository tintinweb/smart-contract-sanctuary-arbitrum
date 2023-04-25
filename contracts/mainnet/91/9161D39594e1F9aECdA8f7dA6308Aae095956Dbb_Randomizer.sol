/**
 *Submitted for verification at Arbiscan on 2023-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }
    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }
}

// Randomizer protocol interface
interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);
    function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);
    function clientWithdrawTo(address _to, uint256 _amount) external;
    function estimateFee(uint256 callbackGasLimit) external returns (uint256);
}

// Jackpot contract interface
interface IJackpot {
    function rewardSwapper(address _swapper) external;
    function payFees() external;
}

struct swap {
    uint256 requestId;
    uint256 winningPercentage;
    uint256 randomNum;
    address swapperAddress;
}

struct winRule {
    uint256 amount;
    uint256 percentage;
    uint256 numerator;
    uint256 denominator;
}

// Reward handling contract
contract Randomizer {
    using SafeMath for uint256;

    address public owner;
    uint256 public winCount;
    uint256 public notWinCount;
    uint256[] public requestsIds;
    uint256 public requestsCount;
    uint256 public callbackGasLimit;
    winRule[] public winRules;
    IJackpot public jackpot;
    IRandomizer public randomizer = IRandomizer(0x5b8bB80f2d72D0C85caB8fB169e8170A05C94bAF);

    mapping (uint256 => swap) public swaps;

    event ProbabilityCalculated(bool hasWon, address swapper, uint256 requestId, uint256 randomNum, uint256 winningPercentage);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owner");
        _;
    }

    modifier onlyRandomizer() {
        require(msg.sender == address(randomizer), "Caller is not Randomizer");
        _;
    }
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        owner = msg.sender;
        callbackGasLimit = 100000;
        winRules.push(winRule(100000000000000000, 1, 1000, 100));
        winRules.push(winRule(200000000000000000, 2, 1000, 100));
        winRules.push(winRule(300000000000000000, 3, 1000, 100));
        winRules.push(winRule(300000000000000000, 3, 1000, 100));
        winRules.push(winRule(400000000000000000, 4, 1000, 100));
        winRules.push(winRule(500000000000000000, 5, 1000, 100));
        winRules.push(winRule(600000000000000000, 6, 1000, 100));
        winRules.push(winRule(700000000000000000, 7, 1000, 100));
        winRules.push(winRule(800000000000000000, 8, 1000, 100));
        winRules.push(winRule(900000000000000000, 9, 1000, 100));
        winRules.push(winRule(1000000000000000000, 10, 1000, 100));
    }

    // Callback function called by the randomizer contract when the random value is generated
    function randomizerCallback(uint256 _id, bytes32 _value) external onlyRandomizer {
        // Convert the random bytes to a number between 1 and 100
        swaps[_id].randomNum = uint256(_value).mod(1000);
        // update the winning or not winning counters
        bool hasWon = swaps[_id].randomNum <= swaps[_id].winningPercentage;
        hasWon ? winCount += 1 : notWinCount += 1;
        emit ProbabilityCalculated(hasWon, swaps[_id].swapperAddress, _id, swaps[_id].randomNum, swaps[_id].winningPercentage);
        // reward swapper in case of winning
        if(hasWon) jackpot.rewardSwapper(swaps[_id].swapperAddress);
    }

    function onSwapEvent(
        uint256 _swapAmount, // swap amount
        address _swapper // swapper address
    ) external onlyOwner {
        // require the jackpot balance to be bigger than 0
        require((address(jackpot).balance) > 0, "jackpot's balance is 0");
        uint256 winPercentage;
        for (uint i = 0; i < winRules.length; i++) {
            if (i < winRules.length - 1) {
                if (_swapAmount >= winRules[i].amount && _swapAmount < winRules[i+1].amount)
                winPercentage = winRules[i].percentage.mul(winRules[i].numerator).div(winRules[i].denominator);
            }
            else {
                if (_swapAmount >= winRules[i].amount)
                winPercentage = winRules[i].percentage.mul(winRules[i].numerator).div(winRules[i].denominator);
            }
        }
        // get tx & randomization fees from the jackpot 
        jackpot.payFees();
        // require win chane to be bigger than 0 to continue
        require(winPercentage > 0, "Swap amount doesn't qualify to win");

        // Request a random number from the randomizer contract
        uint256 requestId = randomizer.request(callbackGasLimit);
        swaps[requestId].requestId = requestId;
        swaps[requestId].winningPercentage = winPercentage;
        swaps[requestId].swapperAddress = _swapper;
        requestsIds.push(requestId);
        requestsCount = requestsIds.length;
    }

    /* GETTERS */

    // returns the qualifiers count
    function qualifiersCount() public view returns(uint256) {
        return winCount + notWinCount;
    }

    // returns the winning rules by index
    function rule(uint256 _index) public view returns(uint256 amount, uint256 percentage) {
        return (winRules[_index].amount, winRules[_index].percentage.mul(winRules[_index].numerator).div(winRules[_index].denominator).div(10));
    }

    // returns the rules count
    function rulesCount() public view returns(uint256) {
        return winRules.length;
    }

    /* SETTERS */

    // update jackpot contract
    function setJackpot(address _newJackpot) external onlyOwner {
        jackpot = IJackpot(_newJackpot);
    }

    // update randomizer contract
    function setRandomizer(address _newRandomizer) external onlyOwner {
        randomizer = IRandomizer(_newRandomizer);
    }

    // update callback gas limit
    function setCallbackGasLimit(uint256 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    // updates rules by index
    function updateRule(uint256 _index, uint256 amount, uint256 percentage, uint256 numerator, uint256 denominator) external onlyOwner {
        winRules[_index] = winRule(amount, percentage, numerator, denominator);
    }

    // add rules by index
    function addRule(uint256 amount, uint256 percentage, uint256 numerator, uint256 denominator) external onlyOwner {
        winRules[winRules.length] = winRule(amount, percentage, numerator, denominator);
    }

    // transfers ownership
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    fallback() external payable {}
    receive() external payable {}
}