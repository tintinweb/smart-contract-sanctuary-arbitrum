// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
interface IMaGauge {
  function DISTRIBUTION (  ) external view returns ( address );
  function DURATION (  ) external view returns ( uint256 );
  function TOKEN (  ) external view returns ( address );
  function _VE (  ) external view returns ( address );
  function _balances ( uint256 ) external view returns ( uint256 );
  function _depositEpoch ( uint256 ) external view returns ( uint256 );
  function _periodFinish (  ) external view returns ( uint256 );
  function _start ( uint256 ) external view returns ( uint256 );
  function _totalSupply (  ) external view returns ( uint256 );
  function balanceOfToken ( uint256 tokenId ) external view returns ( uint256 );
  function balanceOf(address _user) external view returns (uint256);
  function claimFees (  ) external returns ( uint256 claimed0, uint256 claimed1 );
  function deposit ( uint256 amount ) external returns ( uint256 _tokenId );
  function depositAll (  ) external returns ( uint256 _tokenId );
  function earned ( uint256 _tokenId ) external view returns ( uint256 );
  function external_bribe (  ) external view returns ( address );
  function fees0 (  ) external view returns ( uint256 );
  function fees1 (  ) external view returns ( uint256 );
  function gaugeRewarder (  ) external view returns ( address );
  function weightOfUser(address _user ) external view returns (uint256);
  function earned(address _user) external view returns (uint256);
  function getReward ( uint256 _tokenId ) external;
  function internal_bribe (  ) external view returns ( address );
  function isForPair (  ) external view returns ( bool );
  function lastTimeRewardApplicable (  ) external view returns ( uint256 );
  function lastUpdateTime (  ) external view returns ( uint256 );
  function maGaugeId (  ) external view returns ( uint256 );
  function maNFTs (  ) external view returns ( address );
  function maturityLevelOfTokenMaxArray ( uint256 _tokenId ) external view returns ( uint256 _matLevel );
  function maturityLevelOfTokenMaxBoost ( uint256 _tokenId ) external view returns ( uint256 _matLevel );
  function notifyRewardAmount ( address token, uint256 reward ) external;
  function owner (  ) external view returns ( address );
  function periodFinish (  ) external view returns ( uint256 );
  function renounceOwnership (  ) external;
  function rewardForDuration (  ) external view returns ( uint256 );
  function rewardPerToken (  ) external view returns ( uint256 );
  function rewardPerTokenStored (  ) external view returns ( uint256 );
  function rewardRate (  ) external view returns ( uint256 );
  function rewardToken (  ) external view returns ( address );
  function rewards ( uint256 ) external view returns ( uint256 );
  function setDistribution ( address _distribution ) external;
  function setGaugeRewarder ( address _gaugeRewarder ) external;
  function totalSupply (  ) external view returns ( uint256 );
  function totalWeight (  ) external view returns ( uint256 _totalWeight );
  function transferOwnership ( address newOwner ) external;
  function updateReward ( uint256 _tokenId ) external;
  function userRewardPerTokenPaid ( uint256 ) external view returns ( uint256 );
  function weightOfToken ( uint256 _tokenId ) external view returns ( uint256 );
  function withdraw ( uint256 _tokenId ) external;
  function withdrawAndHarvest ( uint256 _tokenId ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMaGaugeStruct {
    struct MaGauge {
        bool active;
        bool stablePair;
        address pair;
        address token0;
        address token1;
        address maGaugeAddress;
        string name;
        string symbol;
        uint maGaugeId;
    }


    struct MaNftInfo {
        // pair info
        uint token_id;
        string name;
        string symbol;
        address pair_address; 			// pair contract address
        address vault_address;      //dyson vault address if it's a cl gauge
        address gauge;  		// maGauge contract address
        address owner;
        uint lp_balance;
        uint weight;
        uint emissions_claimable;
        uint maturity_time;
        uint maturity_multiplier;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IMaGaugeStruct.sol";


interface IMaGaugeV2 {
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event ClaimFees(address indexed from, uint256 claimed0, uint256 claimed1);
    event Deposit(address indexed user, uint256 amount);
    event DistributionSet(address distribution);
    event EmergencyModeSet(bool isEmergency);
    event Harvest(address indexed user, uint256 reward);
    event Increase(
        address indexed user,
        uint256 id,
        uint256 oldAmount,
        uint256 newAmount
    );
    event Initialized(uint8 version);
    event InternalBribeSet(address bribe);
    event Merge(address indexed user, uint256 fromId, uint256 toId);
    event RewardAdded(uint256 reward);
    event Split(address indexed user, uint256 id);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Withdraw(address indexed user, uint256 amount);

    function DISTRIBUTION() external view returns (address);

    function DURATION() external view returns (uint256);

    function LP_LAST_EPOCH_ID() external view returns (uint256);

    function TOKEN() external view returns (address);

    function _VE() external view returns (address);

    function _epochs(uint256) external view returns (uint256);

    function _lastTotalWeightUpdateTime() external view returns (uint256);
    
    function allInfo(uint _tokenId) external view returns(IMaGaugeStruct.MaNftInfo memory _maNftInfo);

    function _lpTotalSupplyPostLimit() external view returns (uint256);

    function _lpTotalSupplyPreLimit() external view returns (uint256);

    function _periodFinish() external view returns (uint256);

    function _positionEntries(uint256) external view returns (uint256);

    function _weightIncrement() external view returns (uint256);

    function activateEmergencyMode() external;

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function deposit(uint256 amount) external returns (uint256 _maNFTId);

    function depositAll() external returns (uint256 _maNFTId);

    function depositTo(uint256 amount, address _to)
        external
        returns (uint256 _maNFTId);

    function update() external returns(bool);

    function depositFromMigration(
        uint amount,
        address _to,
        uint entry
    ) external returns (uint _maNFTId);

    function earned(uint256 _maNFTId) external view returns (uint256);

    function earned(address _user) external view returns (uint256);

    function emergency() external view returns (bool);

    function emergencyWithdraw(uint256 _maNFTId) external;

    function emergencyWithdrawAll() external;

    function external_bribe() external view returns (address);

    function fees0() external view returns (uint256);

    function fees1() external view returns (uint256);

    function gaugeFactory() external view returns (address);

    function getAllReward() external;

    function getApproved(uint256 tokenId) external view returns (address);

    function getReward(uint256 _maNFTId) external;

    function getRewardFromVoter(uint256 _maNFTId) external;

    function idRewardPerTokenPaid(uint256) external view returns (uint256);

    function increase(uint256 _maNFTId, uint256 amount) external;

    function _maturityMultiplier(uint256 _maNFTId) external view returns(uint _multiplier);

    function initialize(
        address _rewardToken,
        address _ve,
        address _token,
        address _distribution,
        address _internal_bribe,
        address _external_bribe,
        bool _isForPair
    ) external;

    function internal_bribe() external view returns (address);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function isApprovedOrOwner(address user, uint256 _maNFTId)
        external
        view
        returns (bool);

    function isForPair() external view returns (bool);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function lpBalanceOfUser(address account)
        external
        view
        returns (uint256 amount);

    function weightOfUser(address account)
        external
        view
        returns (uint256 amount);

    function lpBalanceOfmaNFT(uint256 _maNFTId) external view returns (uint256);

    function lpTotalSupply() external view returns (uint256);

    function maNFTWeight(uint256 _maNFTId) external view returns (uint256);

    function merge(uint256 _maNFTIdFrom, uint256 _maNFTIdTo) external;

    function name() external view returns (string memory);

    function notifyRewardAmount(address token, uint256 reward) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function periodFinish() external view returns (uint256);

    function rewardForDuration() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function rewards(uint256) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setDistribution(address _distribution) external;

    function setInternalBribe(address _int) external;

    function split(uint256 _maNFTId, uint256[] memory weights) external;

    function stopEmergencyMode() external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function sync() external;

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenId() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenURI(uint256 _maNFTId) external view returns (string memory);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function totalSupply() external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function version() external view returns (string memory);

    function withdraw(uint256 _maNFTId) external;

    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMaLPNFT {
  

  function addGauge ( address _maGaugeAddress, address _pool, address _token0, address _token1, uint _maGaugeId ) external;
  function approve ( address _approved, uint256 _tokenId ) external;
  function artProxy (  ) external view returns ( address );
  function balanceOf ( address _owner ) external view returns ( uint256 );
  function burn ( uint256 _tokenId ) external;
  function getApproved ( uint256 _tokenId ) external view returns ( address );
  function initialize ( address art_proxy ) external;
  function isApprovedForAll ( address _owner, address _operator ) external view returns ( bool );
  function isApprovedOrOwner ( address _spender, uint256 _tokenId ) external view returns ( bool );
  function killGauge ( address _gauge ) external;
  function maGauges ( address ) external view returns (
    bool active,
    bool stablePair,
    address pair,
    address token0,
    address token1,
    address maGaugeAddress,
    string memory name,
    string memory symbol,
    uint maGaugeId
  );
  function mint ( address _to ) external returns ( uint256 _tokenId );
  function ms (  ) external view returns ( address );
  function name (  ) external view returns ( string memory );
  function ownerOf ( uint256 _tokenId ) external view returns ( address );
  function ownership_change ( uint256 ) external view returns ( uint256 );
  function reset (  ) external;
  function reviveGauge ( address _gauge ) external;
  function maGaugeTokensOfOwner(address _owner, address _gauge) external view returns (uint256[] memory);
  function fromThisGauge(uint _tokenId) external view returns(bool);
  function safeTransferFrom ( address _from, address _to, uint256 _tokenId ) external;
  function safeTransferFrom ( address _from, address _to, uint256 _tokenId, bytes memory _data  ) external;
  function setApprovalForAll ( address _operator, bool _approved ) external;
  function setArtProxy ( address _proxy ) external;
  function setBoostParams ( uint256 _maxBonusEpoch, uint256 _maxBonusPercent ) external;
  function setTeam ( address _team ) external;
  function supportsInterface ( bytes4 _interfaceID ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function team (  ) external view returns ( address );
  function getWeightByEpoch() external view returns (uint[] memory weightsByEpochs);
  function totalMaLevels() external view returns (uint _totalMaLevels);
  function tokenOfOwnerByIndex ( address _owner, uint256 _tokenIndex ) external view returns ( uint256 );
  function tokenToGauge ( uint256 ) external view returns ( address );
  function tokenURI ( uint256 _tokenId ) external view returns ( string memory );
  function transferFrom ( address _from, address _to, uint256 _tokenId ) external;
  function version (  ) external view returns ( string memory );
  function voter (  ) external view returns ( address );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IVoterV3 {
    event Abstained(uint256 tokenId, uint256 weight);
    event AddFactories(
        address indexed pairfactory,
        address indexed gaugefactory
    );
    event Blacklisted(address indexed blacklister, address indexed token);
    event DistributeReward(
        address indexed sender,
        address indexed gauge,
        uint256 amount
    );
    event GaugeCreated(
        address indexed gauge,
        address creator,
        address internal_bribe,
        address indexed external_bribe,
        address indexed pool
    );
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event Initialized(uint8 version);
    event NotifyReward(
        address indexed sender,
        address indexed reward,
        uint256 amount
    );
    event SetBribeFactory(address indexed old, address indexed latest);
    event SetBribeFor(
        bool isInternal,
        address indexed old,
        address indexed latest,
        address indexed gauge
    );
    event SetGaugeFactory(address indexed old, address indexed latest);
    event SetMinter(address indexed old, address indexed latest);
    event SetPairFactory(address indexed old, address indexed latest);
    event SetVoteDelay(uint256 old, uint256 latest);
    event Voted(address indexed voter, uint256 tokenId, uint256 weight);
    event Whitelisted(address indexed whitelister, address indexed token);

    function MAX_VOTE_DELAY() external view returns (uint256);

    function VOTE_DELAY() external view returns (uint256);

    function _epochTimestamp() external view returns (uint256);

    function _init(address[] memory _tokens, address _minter) external;

    function _ve() external view returns (address);

    function addFactory(address _pairFactory, address _gaugeFactory) external;

    function admin() external view returns (address);

    function blacklist(address[] memory _token) external;

    function bribefactory() external view returns (address);

    function claimBribes(
        address[] memory _bribes,
        address[][] memory _tokens,
        uint256 _tokenId
    ) external;

    function claimBribes(address[] memory _bribes, address[][] memory _tokens)
        external;

    function claimFees(
        address[] memory _fees,
        address[][] memory _tokens,
        uint256 _tokenId
    ) external;

    function claimFees(address[] memory _bribes, address[][] memory _tokens)
        external;

    function claimRewards(address[] memory _gauges) external;

    function claimable(address) external view returns (uint256);

    function createGauge(address _pool, uint256 _gaugeType)
        external
        returns (
            address _gauge,
            address _internal_bribe,
            address _external_bribe
        );

    function createGauges(address[] memory _pool, uint256[] memory _gaugeTypes)
        external
        returns (
            address[] memory,
            address[] memory,
            address[] memory
        );

    function distribute(address[] memory _gauges) external;

    function distribute(uint256 start, uint256 finish) external;

    function distributeAll() external;

    function distributeFees(address[] memory _gauges) external;

    function external_bribes(address) external view returns (address);

    function factories() external view returns (address[] memory);

    function factoryLength() external view returns (uint256);

    function gaugeFactories() external view returns (address[] memory);

    function gaugeFactoriesLength() external view returns (uint256);

    function gauges(address) external view returns (address);

    function gaugesDistributionTimestmap(address)
        external
        view
        returns (uint256);

    function governance() external view returns (address);

    function initialize(
        address __ve,
        address _pairFactory,
        address _gaugeFactory,
        address _bribes
    ) external;

    function internal_bribes(address) external view returns (address);

    function isAlive(address) external view returns (bool);

    function isFactory(address) external view returns (bool);

    function isGauge(address) external view returns (bool);

    function isGaugeFactory(address) external view returns (bool);

    function isWhitelisted(address) external view returns (bool);

    function killGauge(address _gauge) external;

    function lastVoted(uint256) external view returns (uint256);

    function length() external view returns (uint256);

    function minter() external view returns (address);

    function notifyRewardAmount(uint256 amount) external;

    function poke(uint256 _tokenId) external;

    function poolForGauge(address) external view returns (address);

    function poolVote(uint256, uint256) external view returns (address);

    function poolVoteLength(uint256 tokenId) external view returns (uint256);

    function pools(uint256) external view returns (address);

    function poolsList() external view returns (address[] memory);

    function removeFactory(uint256 _pos) external;

    function replaceFactory(
        address _pairFactory,
        address _gaugeFactory,
        uint256 _pos
    ) external;

    function reset(uint256 _tokenId) external;

    function reviveGauge(address _gauge) external;

    function setBribeFactory(address _bribeFactory) external;

    function setExternalBribeFor(address _gauge, address _external) external;

    function setInternalBribeFor(address _gauge, address _internal) external;

    function setMinter(address _minter) external;

    function setNewBribes(
        address _gauge,
        address _internal,
        address _external
    ) external;

    function setVoteDelay(uint256 _delay) external;

    function totalWeight() external view returns (uint256);

    function totalWeightAt(uint256 _time) external view returns (uint256);

    function vote(
        uint256 _tokenId,
        address[] memory _poolVote,
        uint256[] memory _weights
    ) external;

    function votes(uint256, address) external view returns (uint256);

    function weights(address _pool) external view returns (uint256);

    function weightsAt(address _pool, uint256 _time)
        external
        view
        returns (uint256);

    function whitelist(address[] memory _token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IMaLPNFT.sol";
import "./interfaces/IMaGauge.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IVoterV3.sol";
import "./interfaces/IMaGaugeV2.sol";

// The base pair of pools, either stable or volatile
contract MigrateMaNFT {

    IMaLPNFT public maNFT;
    IVoterV3 public voterV3;
    IVoterV3 public oldVoter;

    uint public constant WEEK = 24*60*60*7;
    uint public constant maturityIncrement = 3628800;
    uint public constant MATURITY_PRECISION = 1e18;

    constructor( address _maNFT, address _voterV3, address _oldVoter) {
        maNFT = IMaLPNFT(_maNFT);
        voterV3 = IVoterV3(_voterV3);
        oldVoter = IVoterV3(_oldVoter);

    }

    function migrate(uint[] memory _tokenIds) external {

        uint len = _tokenIds.length;

        for ( uint i ; i<len; i++) {
            uint _tokenId = _tokenIds[i];
            address _oldGaugeAddress = maNFT.tokenToGauge(_tokenId);
            address _owner = maNFT.ownerOf(_tokenId);
            

            IMaGauge _oldGauge = IMaGauge(_oldGaugeAddress);

            address pairOfGauge = oldVoter.poolForGauge(_oldGaugeAddress);

            uint maturity = _oldGauge.maturityLevelOfTokenMaxBoost(_tokenId);
            uint _lpAmountBefore = IERC20(pairOfGauge).balanceOf(address(this));

            _oldGauge.withdrawAndHarvest(_tokenId);


            uint _lpAmountAfter = IERC20(pairOfGauge).balanceOf(address(this));


            uint _lpAmount = _lpAmountAfter - _lpAmountBefore;

            

            address _newGauge = voterV3.gauges(pairOfGauge);

            IERC20(pairOfGauge).approve(_newGauge,_lpAmount);

            uint entry = block.timestamp - maturity * WEEK;

            IMaGaugeV2(_newGauge).depositFromMigration(_lpAmount, _owner, entry);

            
        }
    }
    
}