// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract BaseV2GeneralFeesInterface {
    uint256 public constant DURATION = 7 days; // rewards are released over 7 days
    uint256 internal constant PRECISION = 10**18;

    /**
     * @dev storage slots start here
     */

    // simple re-entrancy check
    uint256 internal _unlocked = 1;
    uint256 internal deploymentPeriod;

    address public _voter; // only voter can modify balances (since it only happens on vote())
    address public _ve;
    address public _minter;

    mapping(uint256 => address[]) public periodRewards; // period -> rewards
    mapping(uint256 => mapping(address => bool)) public periodIsReward; // period -> token -> isReward
    mapping(uint256 => mapping(address => uint256)) public periodRewardAmount; // period -> token -> rewardAmount

    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        public periodUserRewardClaimedFrom; // period -> tokenId -> reward -> claimed
    mapping(uint256 => mapping(address => uint256)) public userLastClaimed; // tokenId -> reward -> last claimed timestamp

    mapping(uint256 => mapping(address => uint256)) public earnedStored; // tokenId -> reward -> earned stored

    // historic states
    address[] public historicRewards;
    mapping(address => bool) public historicIsReward;

    event ClaimRewards(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event Deposit(address indexed from, uint256 tokenId, uint256 amount);
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event StoredRewards(address indexed reward, uint256 amount);
    event Withdraw(address indexed from, uint256 tokenId, uint256 amount);

    function balanceOf(uint256 tokenId) external view returns (uint256) {}

    function claimFees(address pool) external {}

    function earned(address token, uint256 tokenId)
        external
        view
        returns (uint256)
    {}

    function getPeriodReward(
        uint256[] memory timestamps,
        uint256 tokenId,
        address[] memory tokens
    ) external {}

    function getReward(uint256 tokenId, address[] memory tokens) external {}

    function getRewardForOwner(uint256 tokenId, address[] memory tokens)
        external
    {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function initialize(address voter) external {}

    function isReward(address token) external view returns (bool) {}

    function lastWeekRewardRate(address token)
        external
        view
        returns (uint256 _rewardRate)
    {}

    function left(address token) external view returns (uint256) {}

    function notifyRewardAmount(address token, uint256 amount) external {}

    function periodBalanceOf(uint256 _period, uint256 _tokenId)
        external
        view
        returns (uint256)
    {}

    function periodEarned(
        uint256 timestamp,
        address token,
        uint256 tokenId
    ) external view returns (uint256) {}

    function periodRewardPerToken(uint256 timestamp, address token)
        external
        view
        returns (uint256)
    {}

    function periodRewardsList() external view returns (address[] memory) {}

    function periodRewardsList(uint256 timestamp)
        external
        view
        returns (address[] memory)
    {}

    function periodRewardsListLength(uint256 timestamp)
        external
        view
        returns (uint256)
    {}

    function periodRewardsListLength() external view returns (uint256) {}

    function periodTotalSupply(uint256 _period)
        external
        view
        returns (uint256)
    {}

    function rewardPerToken(address token) external view returns (uint256) {}

    function rewardRate(address token)
        external
        view
        returns (uint256 _rewardRate)
    {}

    function rewards(uint256 index) external view returns (address) {}

    function rewardsList() external view returns (address[] memory) {}

    function rewardsListLength() external view returns (uint256) {}

    function totalSupply() external view returns (uint256) {}
}