// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract ChildChainVoterInterface {
    uint256 internal constant DURATION = 7 days; // rewards are released over 7 days
    uint256 internal _unlocked = 1; // simple re-entrancy check

    // Important addressess
  
    address public generalFees;
    address public rewardDistributor; // Plays the role of Minter on ChildChain

    address public base; // ChildChain Solid Token 
    address public ve; // ChildChain Ve NFT
    address[] public pools; // all pools viable for incentives


    uint256 public chainId; // ChildChain ChainId;
    uint256 public activePeriod; // Active period mirror to mainnet
    bool public trainingWheels;
    uint256 public listingFeeRatio;
    

    // Our Structs
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    struct Gauges {
        address gauge;
        address bribe;
        address fees;
    }

    struct VoteInfo {
        address[] poolVote;
        int256[] weights;
    }

    struct Factory {
        address poolFactory;
        address bribeFactory;
        address gaugeFactory; 
        address feeFactory;
    }
    Factory public factories;

    // Mappings
    mapping (address => Gauges) public gauges; // Pool -> Gauges Struct 
    mapping (address => bool) public isGauge; // Gauge -> bool, Is this a gauge? 
    mapping (address => address) public poolForGauge; // Pool -> Gauge
    mapping(address => mapping(uint256 => int256)) public periodWeights; // pool => period => weight
    mapping(address => mapping(uint256 => bool)) public periodUpdated; //whether pool has updated for this period pool => activePeriod => periodUpdated
    mapping(uint256 => mapping(uint256 => mapping(address => int256)))
        public periodVotes; // nft => period => pool => votes
    mapping(uint256 => mapping(uint256 => address[])) public periodPoolVote; // nft => period => pools
    mapping(uint256 => mapping(uint256 => uint256)) public periodUsedWeights;// nft => total voting weight of user
    mapping(uint256 => uint256) public periodTotalWeight; // period => total voting weight
    mapping(address => uint256) public claimable; // gauge => claimable
    mapping(uint256 => uint256) public rewards; // period => rewards
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isBlacklisted;

    // For white/blacklisting
    mapping(address => bool) public isOperator;

    event RegisteredPair(address indexed pair, uint256 time);
    event NotifyReward(
        address indexed sender,
        address indexed reward,
        uint256 amount
    );
    event SetGeneralFees(address oldFees, address newFees);

    event GaugeCreated(
        address indexed gauge,
        address creator,
        address indexed bribe,
        address indexed pool
    );

    event DistributeReward(
        address indexed sender,
        address indexed gauge,
        uint256 amount
    );

    event Voted(
        address indexed voter,
        uint256 indexed tokenId,
        address indexed pool,
        int256 weight
    );
    event Abstained(
        uint256 indexed tokenId,
        address indexed pool,
        int256 weight
    );

    event Whitelisted(address indexed whitelister, address indexed token);
    event Blacklisted(address indexed blacklister, address indexed token);
    event OperatorStatus(address indexed operator, bool state);

    function initialize (
        Factory calldata _factories,
        address _generalFees,
        address _rewardDistributor,
        address _base,
        address _ve,
        uint256 _chainId
    ) external {}

    function usedWeights(uint256 tokenId) external view returns (uint256) {}
/* Can be implemented if we enable whitelisting 
    function listing_fee() public view returns (uint256) {}
*/
    function setTrainingWheels(bool _status) external {}

    function setListingFeeRatio(uint256 _listingFeeRatio)
        external {}

     /**
     * @notice Sets operator status
     * @dev Operators are allowed to pause and set pool fees
     */
    function setOperator(address operator, bool state) external {}


    function governanceWhitelist(address[] memory _tokens)
        external {}

    function governanceBlacklist(address[] memory _tokens)
        external{}

/* Can be implemented in the future
    function whitelist(address _token, uint256 _tokenId) public {}
*/

    /// Voting Functions Vote and Reset, pretty much mainnet mirror ///
    function vote(
        uint256 _tokenId,
        address[] memory _poolVote,
        int256[] memory _weights
    ) external {}

    function reset(uint256 _tokenId) external {}

    /// Claim Rewards from Gauges, Bribes and Fees ///
    function claimRewards(address[] calldata _gauges, address[][] calldata _tokens)
        external {}

    function claimBribes(
        address[] calldata _bribes,
        address[][] calldata _tokens,
        uint256 _tokenId
    ) external {}

    function claimFees(
        address[] calldata _fees,
        address[][] calldata _tokens,
        uint256 _tokenId
    ) external {}

    /// Rewards Processing. Notify is called by rewards distributor. ///

    function notifyRewardAmount(uint256 amount) external {}

    function syncActivePeriod() public returns (uint256) {}

    /// Update the gauges with fresh accruedRewards 

    function updateFor(address[] memory _gauges) external {}

    function updateForRange(uint256 start, uint256 end) public {}

    function updateAll() external {}

    function updateGauge(address _gauge) external {}

    function updateGauge(address _gauge, uint256 _activePeriod) external { }

    /// Distribute Fees and Rewards ///

    function distributeFees(address[] calldata _gauges) external {}

    // By default distribute latest confirmed week
    function distribute(address _gauge) public {}

    function distro() external { }

    function distribute() external { }

    function distribute(uint256 start, uint256 finish) public {}

    function distribute(address[] memory _gauges) external {}

    function distribute(address _gauge, uint256 _activePeriod) public {}

    function createGauge(address _pool) external returns (address) {}

    function setGeneralFees(address _fees) external {}
}