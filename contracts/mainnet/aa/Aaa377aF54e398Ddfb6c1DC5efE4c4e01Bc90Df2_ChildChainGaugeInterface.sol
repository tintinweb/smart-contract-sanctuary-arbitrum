// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
contract ChildChainGaugeInterface {
    uint256 internal constant DURATION = 7 days; // rewards are released over 7 days
    uint256 internal constant PRECISION = 10**44;
    /**
     * @dev storage slots start here
     */

    // simple re-entrancy check
    uint256 internal _unlocked = 1;

    address public stake; // the LP token that needs to be staked for rewards
    address public solid;
    address public bribe;
    address public voter;
    address public ve;

    uint256 public derivedSupply;
    mapping(address => uint128) public derivedBalances;
    mapping(address => uint256) public tokenIds;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => bool)) public isOptIn; // userAddress => rewardAddress => bool
    mapping(address => address[]) public userOptIns; // array of rewards the user is opted into
    mapping(address => mapping(address => uint256)) public userOptInsIndex; // index of pools within userOptIns userAddress =>rewardAddress => index

    // default snx staking contract implementation
    mapping(address => RewardData) public rewardData;

    struct RewardData {
        uint128 rewardRatePerWeek;
        uint128 derivedSupply;
        uint256 rewardPerTokenStored;
        uint40 periodFinish;
        uint40 lastUpdateTime;
    }
    struct UserRewardData {
        uint256 userRewardPerTokenPaid;
        uint256 userEarnedStored;
    }

    mapping(address => mapping(address => UserRewardData))
        public userRewardData; // userAddress => tokenAddress => userRewardData

    uint256 public totalSupply;

    address[] public rewards;
    mapping(address => bool) public isReward;

    uint256 public fees0;
    uint256 public fees1;

    event Deposit(address indexed from, uint256 tokenId, uint256 amount);
    event OptIn(address indexed from, address indexed reward);
    event OptOut(address indexed from, address indexed reward);
    event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event ClawbackRewards(address indexed reward, uint256 amount);
    event ClaimFees(address indexed from, uint256 claimed0, uint256 claimed1);
    event ClaimRewards(
        address indexed from,
        address indexed reward,
        uint256 amount
    );

    function initialize(
        address _stake,
        address _bribe,
        address _voter,
        address _ve
    ) external {}

    function derivedBalance(address account) public view returns (uint256) {}

    function earned(address token, address account)
        external
        view
        returns (uint256) {}

    function lastTimeRewardApplicable(address token)
        external
        view
        returns (uint256) {}

    function lastUpdateTime(address token) external view returns (uint256) {}

    function left(address token) external view returns (uint256) {}

    function periodFinish(address token) external view returns (uint256) {}

    function rewardPerTokenStored(address token)
        external
        view
        returns (uint256) {}

    function rewardRate(address token) external view returns (uint256) {}

    function rewardsListLength() external view returns (uint256) {}

    function rewardPerToken(address token) external view returns (uint256) {}

    function _rewardPerToken(RewardData memory _rewardData)
        internal
        view
        returns (uint256) {}

    function userRewardPerTokenStored(address token, address account)
        external
        view
        returns (uint256) {}

    /**************************************** 
                Protocol Interaction
    ****************************************/
    /**
     * @notice Calls the feeDist to claimFees from the pair
     * @dev Kept for backwards compatibility
     */
    function claimFees() external returns (uint256 claimed0, uint256 claimed1) {}

    function depositAll(uint256 tokenId) external {}

    function deposit(uint256 amount, uint256 tokenId) public {}

    function depositAndOptIn(
        uint256 amount,
        uint256 tokenId,
        address[] memory optInPools
    ) public {}

    function optIn(address[] calldata tokens)
        external {}

    function optOut(address[] calldata tokens)
        external {}

 
    function emergencyOptOut(address[] calldata tokens) external {}

    function withdrawAll() external {}

    function withdraw(uint256 amount) public {}

    function withdrawToken(uint256 amount, uint256 tokenId)
        public {}

    function getReward(address account, address[] memory tokens)
        external {}

    function notifyRewardAmount(address token, uint256 amount) external {}

    function clawbackRewards(address token, uint256 amount)
         external {}
     
}