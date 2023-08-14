// SPDX-License-Identifier: 0BSD
pragma solidity 0.8.13;

import "./interfaces/IVoterV3.sol";
import "./interfaces/IERC20.sol";


interface IDysonVault {
    function pool() external view returns(address);
}

interface IV3pool {
    function token0() external view returns(address);
    function token1() external view returns(address);

    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

interface IBribe {
    function notifyRewardAmount(address _rewardsToken, uint256 reward) external;
}

contract CLFeeSplitter {


    IVoterV3 public voter;
    address public dReceiver;
    address public stakingConverter;

    uint constant public PRECISSION = 10000;
    uint public stakingConverterPercentage;
    uint public dReceiverAmount;

    constructor( address _stakingConverter, address _dAddress, address _voter ) {

        stakingConverter = _stakingConverter;
        dReceiver = _dAddress;
        voter = IVoterV3(_voter);

        stakingConverterPercentage = 2000;
        dReceiverAmount = 600;
    }

    function getFeesAndSend(address[] memory _gauges) external {

        uint len = _gauges.length;

        IV3pool v3pool;
        IDysonVault _dysonVault;

        address _internalBribe;
        IERC20 _token0;
        IERC20 _token1;
        address _gauge;

        uint _amount0;
        uint _amount1;

        for ( uint i; i < len; i++ ) {
            _gauge = _gauges[i];

            _dysonVault = IDysonVault(voter.poolForGauge(_gauge));
            v3pool = IV3pool( _dysonVault.pool() );

            _token0 = IERC20(v3pool.token0());
            _token1 = IERC20(v3pool.token1());

            _internalBribe = voter.internal_bribes(_gauge);

            
            v3pool.collectProtocol(address(this), type(uint128).max, type(uint128).max );

            _amount0 = _token0.balanceOf(address(this));
            _amount1 = _token1.balanceOf(address(this));

            //transfer to Staking Converter:
            _token0.transfer(stakingConverter, _amount0 * stakingConverterPercentage / PRECISSION);
            _token1.transfer(stakingConverter, _amount1 * stakingConverterPercentage / PRECISSION);

            //transfer to dReceiver:
            _token0.transfer(dReceiver, _amount0 * dReceiverAmount / PRECISSION);
            _token1.transfer(dReceiver, _amount1 * dReceiverAmount / PRECISSION);


            //make internal Bribe ( fee bribe )
            _amount0 = _token0.balanceOf(address(this));
            _amount1 = _token1.balanceOf(address(this));
            _token0.approve(_internalBribe, _amount0);
            _token1.approve(_internalBribe, _amount1);

            IBribe(_internalBribe).notifyRewardAmount(address(_token0), _amount0);
            IBribe(_internalBribe).notifyRewardAmount(address(_token1), _amount1);
            
        }
    }
}

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

    function weightsPerEpoch(uint,address) external view returns(uint);

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
    function clLength() external view returns (uint256);

    function minter() external view returns (address);

    function notifyRewardAmount(uint256 amount) external;

    function poke(uint256 _tokenId) external;

    function poolForGauge(address) external view returns (address);

    function poolVote(uint256, uint256) external view returns (address);

    function poolVoteLength(uint256 tokenId) external view returns (uint256);

    function pools(uint256) external view returns (address);

    function poolsList() external view returns (address[] memory);

    function clPools(uint256) external view returns (address);

    function clPoolsList() external view returns (address[] memory);

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