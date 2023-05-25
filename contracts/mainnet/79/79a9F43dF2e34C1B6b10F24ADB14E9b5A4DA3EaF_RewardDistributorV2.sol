// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IRewardDistributor {
    function getRewardTokens() external view returns (address[] memory);

    function getTokensPerIntervals(address _rewardToken) external view returns (uint256);

    function pendingRewards(address _rewardToken) external view returns (uint256);

    function distribute() external returns (uint256[] memory);

    function setTokensPerInterval(address _rewardToken, uint256 _amounts) external;

    function getRewardTokensLength() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;

    function tokensPerInterval(address _rewardToken) external view returns (uint256);

    function claim(address _receiver) external returns (uint256[] memory);

    function claimForAccount(address _account, address _receiver) external returns (uint256[] memory);

    function claimable(address _account, address _token) external view returns (uint256);

    function claimables(address _account) external view returns (uint256[] memory);

    function averageStakedAmounts(address _account) external view returns (uint256);

    function cumulativeRewards(address _rewardToken, address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        require(_gov != address(0), "Governable: invalid address");
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {IERC20} from "../../interfaces/IERC20.sol";
import {Governable} from "../../libraries/Governable.sol";
import {IRewardDistributor} from "../../interfaces/IRewardDistributor.sol";
import {IRewardTracker} from "../../interfaces/IRewardTracker.sol";

contract RewardDistributorV2 is IRewardDistributor, Governable {
    address[] public rewardTokens;
    uint256 public lastDistributionTime;
    address public rewardTracker;

    mapping(address => uint256) public tokensPerIntervals;
    mapping(address => bool) public isHandler;

    event Distribute(address token, uint256 amount);
    event TokensPerIntervalChange(address rewardToken, uint256 amount);
    event SetHandler(address handler, bool isActive);
    event AddRewardToken(address _rewardToken, uint256 _amount);

    constructor(address[] memory _rewardTokens, address _rewardTracker) {
        rewardTokens = _rewardTokens;
        rewardTracker = _rewardTracker;
        isHandler[msg.sender] = true;
    }

    modifier onlyHandlerAndAbove() {
        _onlyHandlerAndAbove();
        _;
    }

    function getRewardTokens() external view returns (address[] memory) {
        return rewardTokens;
    }

    function rewardTokensLength() external view returns (uint256) {
        return rewardTokens.length;
    }

    function getTokensPerIntervals(address _rewardToken) external view returns (uint256) {
        return tokensPerIntervals[_rewardToken];
    }

    function _onlyHandlerAndAbove() internal view {
        require(isHandler[msg.sender] || msg.sender == gov, "rewardDistributor: not handler");
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;

        emit SetHandler(_handler, _isActive);
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).transfer(_account, _amount);
    }

    function addRewardToken(address _rewardToken, uint256 _amount) external onlyGov {
        rewardTokens.push(_rewardToken);
        tokensPerIntervals[_rewardToken] = _amount;
        emit AddRewardToken(_rewardToken, _amount);
    }

    // migration purpose
    // do not use unless it is a migration case.
    function migrateRewardToken(uint256 _index, address _rewardToken) external onlyGov {
        rewardTokens[_index] = _rewardToken;
    }

    function getRewardTokensLength() public view returns (uint256) {
        return rewardTokens.length;
    }

    function setHandlers(address[] memory _handler, bool[] memory _isActive) external onlyGov {
        for (uint256 i = 0; i < _handler.length; i++) {
            isHandler[_handler[i]] = _isActive[i];
        }
    }

    function updateLastDistributionTime() external onlyGov {
        lastDistributionTime = block.timestamp;
    }

    function setTokensPerInterval(address _rewardToken, uint256 _amount) external onlyHandlerAndAbove {
        require(lastDistributionTime != 0, "RewardDistributor: invalid lastDistributionTime");
        IRewardTracker(rewardTracker).updateRewards();
        tokensPerIntervals[_rewardToken] = _amount;
        emit TokensPerIntervalChange(_rewardToken, _amount);
    }

    function setTokensPerIntervals(uint256[] memory _amounts) external onlyHandlerAndAbove {
        require(lastDistributionTime != 0, "RewardDistributor: invalid lastDistributionTime");
        require(_amounts.length == rewardTokens.length, "invalid input length");
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint256 amount = _amounts[i];
            tokensPerIntervals[rewardToken] = amount;
            emit TokensPerIntervalChange(rewardToken, amount);
        }
    }

    function pendingRewards(address _rewardToken) public view returns (uint256) {
        if (block.timestamp == lastDistributionTime) {
            return 0;
        }

        uint256 timeDiff = block.timestamp - lastDistributionTime;
        return tokensPerIntervals[_rewardToken] * timeDiff;
    }

    function distribute() external returns (uint256[] memory) {
        require(msg.sender == rewardTracker, "RewardDistributor: invalid msg.sender");
        uint256 len = getRewardTokensLength();
        uint256[] memory rewardAmounts = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            address rewardToken = rewardTokens[i];
            uint256 amount = pendingRewards(rewardToken);

            if (amount == 0) {
                continue;
            }

            uint256 balance = IERC20(rewardToken).balanceOf(address(this));

            if (amount > balance) {
                amount = balance;
            }

            IERC20(rewardToken).transfer(msg.sender, amount);
            rewardAmounts[i] = amount;
            emit Distribute(rewardToken, amount);
        }

        lastDistributionTime = block.timestamp;

        return rewardAmounts;
    }
}