/**
 *Submitted for verification at Arbiscan on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract TokenToPoint {
    using SafeMath for uint256;
    address public multisigWallet; 
    uint256 private constant DECIMALS = 10**18;
    uint256 constant ANGEL_ROUND_COUNT = 10;
    uint256 constant BEGIN_ROUND_COUNT = 20;
    uint256 constant DEEPEN_ROUND_COUNT = 60;
    uint256 constant ANGEL_ROUND_INITIAL_RATE = 20000;
    uint256 constant BEGIN_ROUND_RATE = 13000;
    uint256 constant DEEPEN_ROUND_RATE = 9047;
    uint256 constant ANGEL_ROUND_TOKEN = 100 * DECIMALS;
    uint256 constant BEGIN_ROUND_TOKEN = 100 * DECIMALS;
    uint256 constant DEEPEN_ROUND_TOKEN = 100 * DECIMALS;
    address public owner;
    mapping(address => uint256) userPoints;
    uint256 public roundType = 1;
    uint256 public round = 0;
    uint256 public tokensInCurrentRound = 0;
    uint256 globalAngelRoundRate = ANGEL_ROUND_INITIAL_RATE;

    // Add the InviterData struct
    struct InviterData {
        uint256 totalInvitedPoints;
        address[] invitedAddresses;
    }

    // Add mapping to keep track of the inviter data
    mapping(address => InviterData) private inviterDataMap;
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    event DepositCompleted(uint256 currentRoundType, uint256 currentRound);
    
    

    constructor(address _multisigWallet) {
        owner = msg.sender;
        multisigWallet = _multisigWallet;  // Initialize the multisig wallet address

    }
    function setMultisigWallet(address _newMultisigWallet) public onlyOwner {
        multisigWallet = _newMultisigWallet;
    }
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function withdrawEther(uint256 amount) public {
        require(msg.sender == multisigWallet, "Only the multisig wallet can withdraw ether");
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Not enough ether in the contract");
        payable(multisigWallet).transfer(amount); // Transfer ether to the multisig wallet
    }
    
    function depositTokens(address inviter) public payable {
        // Minimum token requirement
        uint256 minEther = 1000000000000000; // 0.001 in 18 decimal places
        require(msg.value >= minEther, "Minimum deposit is 0.001 ether");

        uint256 points = calculatePoints(msg.value);
        userPoints[msg.sender] = userPoints[msg.sender].add(points);

        // If inviter address is not zero and not the sender, assign 10% of points to inviter
        if (inviter != address(0) && inviter != msg.sender) {
            uint256 inviterPoints = points.div(5);

            // Update the inviter data
            InviterData storage inviterData = inviterDataMap[inviter];
            inviterData.totalInvitedPoints = inviterData.totalInvitedPoints.add(inviterPoints);
            inviterData.invitedAddresses.push(msg.sender);
        }

        emit DepositCompleted(roundType, round);
    }

    function calculatePoints(uint256 etherAmount) internal returns (uint256) {
        uint256 remainingTokens = etherAmount;
        uint256 result = 0;

        while (remainingTokens > 0) {
            uint256 tokensToDeposit = (getCurrentRoundTokenLimit() - tokensInCurrentRound < remainingTokens) ?
                                        getCurrentRoundTokenLimit() - tokensInCurrentRound :
                                        remainingTokens;
            uint256 rate = getCurrentRoundRate();
            remainingTokens = remainingTokens.sub(tokensToDeposit);
            result = result.add(tokensToDeposit.mul(rate));

            updateRound(tokensToDeposit);
        }

        return result;
    }

    function getCurrentRoundTokenLimit() public view returns (uint256) {
        if (roundType == 1) {
            return ANGEL_ROUND_TOKEN;
        } else if (roundType == 2) {
            return BEGIN_ROUND_TOKEN;
        } else {
            return DEEPEN_ROUND_TOKEN;
        }
    }

    function getCurrentRoundRate() public view returns (uint256) {
        if (roundType == 1) {
            return globalAngelRoundRate;
        } else if (roundType == 2) {
            return BEGIN_ROUND_RATE;
        } else {
            return DEEPEN_ROUND_RATE;
        }
    }

    function updateRound(uint256 tokensToDeposit) internal {
        tokensInCurrentRound = tokensInCurrentRound.add(tokensToDeposit);
        if (tokensInCurrentRound == getCurrentRoundTokenLimit()) {
            round = round.add(1);
            tokensInCurrentRound = 0;

            if (roundType == 1) {
                globalAngelRoundRate = globalAngelRoundRate.mul(995).div(1000);
            }

            if (roundType == 1 && round == ANGEL_ROUND_COUNT) {
               
                round = 0;
                roundType = 2;
            } else if (roundType == 2 && round == BEGIN_ROUND_COUNT) {
                round = 0;
                roundType = 3;
            } else if (roundType == 3 && round == DEEPEN_ROUND_COUNT) {
                // No more rounds available for deposit
                round = 0;
                roundType = 4;
            }
        }
        require(roundType != 4, "No more rounds available for deposit");
    }

    function getUserPoints(address user) public view returns (uint256) {
        return userPoints[user];
    }
    function getContractTokenBalance() public view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }
    function getInviterData(address inviter) public view returns (uint256 totalInvitedPoints, address[] memory invitedAddresses) {
        InviterData memory inviterData = inviterDataMap[inviter];
        return (inviterData.totalInvitedPoints, inviterData.invitedAddresses);
    }

    
}