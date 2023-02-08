// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/IExternalBribeFactory.sol";
import './ExternalBribe.sol';

contract ExternalBribeFactory is IExternalBribeFactory {
    address public last_external_bribe;

    function createExternalBribe(address voter, address[] memory allowedRewards) external returns (address) {
        last_external_bribe = address(new ExternalBribe(voter, msg.sender, allowedRewards));
        return last_external_bribe;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IExternalBribeFactory {
    function createExternalBribe(address voter, address[] memory allowedRewards) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '../core/libraries/Math.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './interfaces/IExternalBribe.sol';
import './interfaces/IVoter.sol';
import './interfaces/IVotingEscrow.sol';

// Bribes pay out rewards for a given pool based on the votes that were received from the user (goes hand in hand with Voter.vote())
contract ExternalBribe is IExternalBribe {
    address public immutable voter;
    address public immutable voterAux; // only voterAux can modify balances (since it only happens on vote())
    address public immutable _ve; // VotingEscrow

    uint internal constant DURATION = 7 days; // rewards are released over the voting period
    uint internal constant MAX_REWARD_TOKENS = 16;

    uint internal constant PRECISION = 10 ** 18;

    uint public totalSupply;
    mapping(uint => uint) public balanceOf;
    mapping(address => mapping(uint => uint)) public tokenRewardsPerEpoch;
    mapping(address => uint) public periodFinish;
    mapping(address => mapping(uint => uint)) public lastEarn;

    address[] public rewards;
    mapping(address => bool) public isReward;

    /// @notice A checkpoint for marking balance
    struct Checkpoint {
        uint timestamp;
        uint balanceOf;
    }

    /// @notice A checkpoint for marking supply
    struct SupplyCheckpoint {
        uint timestamp;
        uint supply;
    }

    /// @notice A record of balance checkpoints for each account, by index
    mapping (uint => mapping (uint => Checkpoint)) public checkpoints;
    /// @notice The number of checkpoints for each account
    mapping (uint => uint) public numCheckpoints;
    /// @notice A record of balance checkpoints for each token, by index
    mapping (uint => SupplyCheckpoint) public supplyCheckpoints;
    /// @notice The number of checkpoints
    uint public supplyNumCheckpoints;

    event Deposit(address indexed from, uint tokenId, uint amount);
    event Withdraw(address indexed from, uint tokenId, uint amount);
    event NotifyReward(address indexed from, address indexed reward, uint epoch, uint amount);
    event ClaimRewards(address indexed from, address indexed reward, uint amount);

    constructor(address _voter, address _voterAux, address[] memory _allowedRewardTokens) {
        voter = _voter;
        voterAux = _voterAux;
        _ve = IVoter(_voter)._ve();

        for (uint i; i < _allowedRewardTokens.length; i++) {
            if (_allowedRewardTokens[i] != address(0)) {
                isReward[_allowedRewardTokens[i]] = true;
                rewards.push(_allowedRewardTokens[i]);
            }
        }
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function _bribeStart(uint timestamp) internal pure returns (uint) {
        return timestamp - (timestamp % (7 days));
    }

    function getEpochStart(uint timestamp) public pure returns (uint) {
        uint bribeStart = _bribeStart(timestamp);
        uint bribeEnd = bribeStart + DURATION;
        return timestamp < bribeEnd ? bribeStart : bribeStart + 7 days;
    }

    /**
    * @notice Determine the prior balance for an account as of a block number
    * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    * @param tokenId The token of the NFT to check
    * @param timestamp The timestamp to get the balance at
    * @return The balance the account had as of the given block
    */
    function getPriorBalanceIndex(uint tokenId, uint timestamp) public view returns (uint) {
        uint nCheckpoints = numCheckpoints[tokenId];
        if (nCheckpoints == 0) {
            return 0;
        }
        // First check most recent balance
        if (checkpoints[tokenId][nCheckpoints - 1].timestamp <= timestamp) {
            return (nCheckpoints - 1);
        }
        // Next check implicit zero balance
        if (checkpoints[tokenId][0].timestamp > timestamp) {
            return 0;
        }

        uint lower = 0;
        uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[tokenId][center];
            if (cp.timestamp == timestamp) {
                return center;
            } else if (cp.timestamp < timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    function getPriorSupplyIndex(uint timestamp) public view returns (uint) {
        uint nCheckpoints = supplyNumCheckpoints;
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (supplyCheckpoints[nCheckpoints - 1].timestamp <= timestamp) {
            return (nCheckpoints - 1);
        }

        // Next check implicit zero balance
        if (supplyCheckpoints[0].timestamp > timestamp) {
            return 0;
        }

        uint lower = 0;
        uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            SupplyCheckpoint memory cp = supplyCheckpoints[center];
            if (cp.timestamp == timestamp) {
                return center;
            } else if (cp.timestamp < timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    function _writeCheckpoint(uint tokenId, uint balance) internal {
        uint _timestamp = block.timestamp;
        uint _nCheckPoints = numCheckpoints[tokenId];
        if (_nCheckPoints > 0 && checkpoints[tokenId][_nCheckPoints - 1].timestamp == _timestamp) {
            checkpoints[tokenId][_nCheckPoints - 1].balanceOf = balance;
        } else {
            checkpoints[tokenId][_nCheckPoints] = Checkpoint(_timestamp, balance);
            numCheckpoints[tokenId] = _nCheckPoints + 1;
        }
    }

    function _writeSupplyCheckpoint() internal {
        uint _nCheckPoints = supplyNumCheckpoints;
        uint _timestamp = block.timestamp;

        if (_nCheckPoints > 0 && supplyCheckpoints[_nCheckPoints - 1].timestamp == _timestamp) {
            supplyCheckpoints[_nCheckPoints - 1].supply = totalSupply;
        } else {
            supplyCheckpoints[_nCheckPoints] = SupplyCheckpoint(_timestamp, totalSupply);
            supplyNumCheckpoints = _nCheckPoints + 1;
        }
    }

    function rewardsListLength() external view returns (uint) {
        return rewards.length;
    }

    // returns the last time the reward was modified or periodFinish if the reward has ended
    function lastTimeRewardApplicable(address token) public view returns (uint) {
        return Math.min(block.timestamp, periodFinish[token]);
    }

    // allows a user to claim rewards for a given token
    function getReward(uint tokenId, address[] memory tokens) external lock  {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, tokenId));
        for (uint i = 0; i < tokens.length; i++) {
            uint _reward = earned(tokens[i], tokenId);
            lastEarn[tokens[i]][tokenId] = block.timestamp;
            if (_reward > 0) _safeTransfer(tokens[i], msg.sender, _reward);

            emit ClaimRewards(msg.sender, tokens[i], _reward);
        }
    }

    // used by VoterAux to allow batched reward claims
    function getRewardForOwner(uint tokenId, address[] memory tokens) external lock  {
        require(msg.sender == voterAux, "!voter");
        address _owner = IVotingEscrow(_ve).ownerOf(tokenId);
        for (uint i = 0; i < tokens.length; i++) {
            uint _reward = earned(tokens[i], tokenId);
            lastEarn[tokens[i]][tokenId] = block.timestamp;
            if (_reward > 0) _safeTransfer(tokens[i], _owner, _reward);

            emit ClaimRewards(_owner, tokens[i], _reward);
        }
    }

    function earned(address token, uint tokenId) public view returns (uint) {
        uint _startTimestamp = lastEarn[token][tokenId];
        if (numCheckpoints[tokenId] == 0) {
            return 0;
        }

        uint _startIndex = getPriorBalanceIndex(tokenId, _startTimestamp);
        uint _endIndex = numCheckpoints[tokenId]-1;

        uint reward = 0;
        // you only earn once per epoch (after it's over)
        Checkpoint memory prevRewards; // reuse struct to avoid stack too deep
        prevRewards.timestamp = _bribeStart(_startTimestamp);
        uint _prevSupply = 1;

        if (_endIndex > 0) {
            for (uint i = _startIndex; i <= _endIndex - 1; i++) {
                Checkpoint memory cp0 = checkpoints[tokenId][i];
                uint _nextEpochStart = _bribeStart(cp0.timestamp);
                // check that you've earned it
                // this won't happen until a week has passed
                if (_nextEpochStart > prevRewards.timestamp) {
                    reward += prevRewards.balanceOf;
                }

                prevRewards.timestamp = _nextEpochStart;
                _prevSupply = supplyCheckpoints[getPriorSupplyIndex(_nextEpochStart + DURATION)].supply;
                prevRewards.balanceOf = cp0.balanceOf * tokenRewardsPerEpoch[token][_nextEpochStart] / _prevSupply;
            }
        }

        Checkpoint memory cp = checkpoints[tokenId][_endIndex];
        uint _lastEpochStart = _bribeStart(cp.timestamp);
        uint _lastEpochEnd = _lastEpochStart + DURATION;

        if (block.timestamp > _lastEpochEnd) {
          reward += cp.balanceOf * tokenRewardsPerEpoch[token][_lastEpochStart] / supplyCheckpoints[getPriorSupplyIndex(_lastEpochEnd)].supply;
        }

        return reward;
    }

    // This is an external function, but internal notation is used since it can only be called "internally" from Gauges
    function _deposit(uint amount, uint tokenId) external {
        require(msg.sender == voterAux);

        totalSupply += amount;
        balanceOf[tokenId] += amount;

        _writeCheckpoint(tokenId, balanceOf[tokenId]);
        _writeSupplyCheckpoint();

        emit Deposit(msg.sender, tokenId, amount);
    }

    function _withdraw(uint amount, uint tokenId) external {
        require(msg.sender == voterAux);

        totalSupply -= amount;
        balanceOf[tokenId] -= amount;

        _writeCheckpoint(tokenId, balanceOf[tokenId]);
        _writeSupplyCheckpoint();

        emit Withdraw(msg.sender, tokenId, amount);
    }

    function left(address token) external view returns (uint) {
        uint adjustedTstamp = getEpochStart(block.timestamp);
        return tokenRewardsPerEpoch[token][adjustedTstamp];
    }

    function notifyRewardAmount(address token, uint amount) external lock {
        require(amount > 0);
        if (!isReward[token]) {
            require(IVoter(voter).isBribe(address(this), token), "bribe tokens must be whitelisted");
            require(rewards.length < MAX_REWARD_TOKENS, "too many rewards tokens");
        }
        // bribes kick in at the start of next bribe period
        uint adjustedTstamp = getEpochStart(block.timestamp);
        uint epochRewards = tokenRewardsPerEpoch[token][adjustedTstamp];

        _safeTransferFrom(token, msg.sender, address(this), amount);
        tokenRewardsPerEpoch[token][adjustedTstamp] = epochRewards + amount;

        periodFinish[token] = adjustedTstamp + DURATION;

        if (!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
        }

        emit NotifyReward(msg.sender, token, adjustedTstamp, amount);
    }

    function swapOutReward(uint i, address oldToken, address newToken) external {
        require(msg.sender == IVoter(voter).admin());
        require(rewards[i] == oldToken);
        isReward[oldToken] = false;
        isReward[newToken] = true;
        rewards[i] = newToken;
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Math {
    function divUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
        if (x % y != 0) z++;
    }

    function shiftRightUp(uint256 x, uint8 y) internal pure returns (uint256 z) {
        z = x >> y;
        if (x != z << y) z++;
    }

    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IExternalBribe {
    function balanceOf(uint tokenId) external view returns (uint);
    function earned(address token, uint tokenId) external view returns (uint);
    function swapOutReward(uint i, address oldToken, address newToken) external;
    function totalSupply() external view returns (uint);
    function _deposit(uint amount, uint tokenId) external;
    function _withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] memory tokens) external;
    function notifyRewardAmount(address token, uint amount) external;
    function left(address token) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoter {

    function attachTokenToGauge(uint _tokenId, address account) external;
    function detachTokenFromGauge(uint _tokenId, address account) external;
    function emitDeposit(uint _tokenId, address account, uint amount) external;
    function emitWithdraw(uint _tokenId, address account, uint amount) external;
    function distribute(address _gauge) external;
    function notifyRewardAmount(uint amount) external;
    function _ve() external view returns (address);
    function createSwapGauge(address pair) external returns (address);
    function factory() external view returns (address);
    function listing_fee() external view returns (uint);
    function whitelist(address token) external;
    function isWhitelisted(address token) external view returns (bool);
    function bribeFactory() external view returns (address);
    function bribes(address gauge) external view returns (address);
    function gauges(address pair) external view returns (address);
    function isGauge(address gauge) external view returns (bool);
    function allGauges(uint index) external view returns (address);
    function vote(uint tokenId, address[] calldata gaugeVote, uint[] calldata weights) external;
    function lastVote(uint tokenId) external view returns(uint);
    function gaugeVote(uint tokenId) external view returns (address[] memory);
    function votes(uint tokenId, address gauge) external view returns (uint);
    function weights(address gauge) external view returns (uint);
    function usedWeights(uint tokenId) external view returns (uint);
    function claimable(address gauge) external view returns (uint);
    function totalWeight() external view returns (uint);
    function reset(uint tokenId) external;
    function claimFees(address[] memory bribes, address[][] memory tokens, uint tokenId) external;
    function distributeFees(address[] memory gauges) external;
    function updateGauge(address gauge) external;
    function poke(uint tokenId) external;
    function initialize(address minter) external;
    function minter() external view returns (address);
    function claimRewards(address[] memory gauges, address[][] memory rewards) external;
    function admin() external view returns (address);
    function isReward(address gauge, address token) external view returns (bool);
    function claimBribes(address[] memory, address[][] memory, uint) external;
    function isBribe(address bribe, address token) external view returns (bool);
    function isLive(address gauge) external view returns (bool);
    function setBribe(address bribe, address token, bool status) external;
    function setReward(address gauge, address token, bool status) external;
    function killGauge(address _gauge) external;
    function reviveGauge(address _gauge) external;
    function distroFees() external;
    function length() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVotingEscrow {

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function user_point_epoch(uint tokenId) external view returns (uint);
    function epoch() external view returns (uint);
    function user_point_history(uint tokenId, uint loc) external view returns (Point memory);
    function point_history(uint loc) external view returns (Point memory);
    function checkpoint() external;
    function deposit_for(uint tokenId, uint value) external;
    function token() external view returns (address);
    function user_point_history__ts(uint tokenId, uint idx) external view returns (uint);
    function locked__end(uint _tokenId) external view returns (uint);
    function approve(address spender, uint tokenId) external;
    function balanceOfNFT(uint) external view returns (uint);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function totalSupply() external view returns (uint);
    function supply() external view returns (uint);
    function create_lock_for(uint, uint, address) external returns (uint);
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;
    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
    function voted(uint tokenId) external view returns (bool);
    function withdraw(uint tokenId) external;
    function create_lock(uint value, uint duration) external returns (uint);
    function setVoter(address voter) external;
    function balanceOf(address owner) external view returns (uint);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function increase_amount(uint tokenId, uint value) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function tokenOfOwnerByIndex(address _owner, uint _tokenIndex) external view returns (uint);
}