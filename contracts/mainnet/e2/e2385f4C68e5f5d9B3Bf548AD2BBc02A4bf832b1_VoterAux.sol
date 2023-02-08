// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/IGauge.sol";
import "./interfaces/IBribe.sol";
import "./interfaces/IExternalBribe.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IExternalBribeFactory.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingDist.sol";
import "../core/interfaces/ISwapPair.sol";

contract VoterAux {

    error InvalidArguments();
    error UnknownAction(uint8 action);
    error BribeExists();
    error InvalidGauge();

    uint8 private constant ACTION_VOTE = 0;
    uint8 private constant ACTION_CLAIM_INTERNAL_BRIBES = 1;
    uint8 private constant ACTION_CLAIM_EXTERNAL_BRIBES = 2;
    uint8 private constant ACTION_CLAIM_REWARDS = 3;
    uint8 private constant ACTION_CLAIM_REBASE = 4;
    
    bool internal locked;
    IVoter public immutable voter;
    IVotingDist public immutable votingDist;
    IVotingEscrow public immutable ve;
    IExternalBribeFactory public immutable externalBribeFactory;
    address public immutable token;

    mapping(address => address) public externalBribes; // gauge => external bribe
    mapping(address => uint256[]) public pendingTokens; // gauge => pending tokens

    event ExternalBribeCreated(address indexed gauge, address creator, address indexed bribe, address indexed pair);

    /// @param _voter The voting system contract
    /// @param _votingDist Voting Distributor contract
    constructor(address _voter, address _votingDist, address _ve, address _externalBribeFactory) {
        voter = IVoter(_voter);
        votingDist = IVotingDist(_votingDist);
        ve = IVotingEscrow(_ve);
        externalBribeFactory = IExternalBribeFactory(_externalBribeFactory);
        token = ve.token();
    }

    modifier nonReentrant() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    /// @notice Allows to execute multiple actions in a single transaction.
    /// @param _actions The actions to execute.
    /// @param _datas The abi encoded parameters for the actions to execute.
    function batchActions(uint8[] calldata _actions, bytes[] calldata _datas)
        external
        nonReentrant
    {
        if (_actions.length != _datas.length) revert InvalidArguments();

        for (uint256 i; i < _actions.length; ++i) {
            uint8 action = _actions[i];

            if (action == ACTION_VOTE) {
                (uint256 tokenId, address[] memory gauges, uint256[] memory weights) = abi
                    .decode(_datas[i], (uint256, address[], uint256[]));

                vote(tokenId, gauges, weights);
            } else if (action == ACTION_CLAIM_INTERNAL_BRIBES) {
                (address[] memory bribes, address[][] memory tokens, uint tokenId) = abi
                    .decode(_datas[i], (address[], address[][], uint));

                voter.claimBribes(bribes, tokens, tokenId);
            } else if (action == ACTION_CLAIM_EXTERNAL_BRIBES) {
                (address[] memory bribes, address[][] memory tokens, uint tokenId) = abi
                    .decode(_datas[i], (address[], address[][], uint));

                _claimExternalBribes(bribes, tokens, tokenId);
            } else if (action == ACTION_CLAIM_REWARDS) {
                (address[] memory gauges, address[][] memory tokens) = abi
                    .decode(_datas[i], (address[], address[][]));

                voter.claimRewards(gauges, tokens);
            } else if (action == ACTION_CLAIM_REBASE) {
                (uint256 tokenId) = abi.decode(_datas[i], (uint256));
                votingDist.claim(tokenId);
            } else {
                revert UnknownAction(action);
            }
        }
    }

    /// @notice Allow creating a gauge for an existing swap pair
    /// @param _pair The swap pair to create gauge for
    /// @return gauge The newly created gauge
    function createSwapGauge(address _pair) external returns (address gauge) {
        address _gauge = voter.createSwapGauge(_pair);    

        _createExternalBribe(_gauge);

        return _gauge;
    }


    /// @notice the sum of weights is the total weight of the veNFT at max
    /// @param _tokenId The id of the veNFT to vote with
    /// @param _gaugeVote The list of gauges to vote for
    /// @param _weights The list of weights to vote for each gauge
    function vote(uint _tokenId, address[] memory _gaugeVote, uint256[] memory _weights) public {
        _reset(_tokenId);

        voter.vote(_tokenId, _gaugeVote, _weights);
        
        _deposit(_tokenId, _gaugeVote, _weights);
    }

    /// @notice Allows vote reset for a veNFT
    /// @param _tokenId the ID of the veNFT to reset votes for
    function reset(uint _tokenId) public { 
        voter.reset(_tokenId);
        _reset(_tokenId);
    }

    /// @notice To be called on voters abusing their voting power
    /// @notice _weights are the same as the last ID's vote 
    /// @param _tokenId the ID of the NFT to poke
    function poke(uint _tokenId) external {
        _reset(_tokenId);

        voter.poke(_tokenId);
        
        address[] memory _gaugeVote = voter.gaugeVote(_tokenId);
        uint _gaugeCnt = _gaugeVote.length;
        uint256[] memory _weights = new uint256[](_gaugeCnt);

        for (uint i = 0; i < _gaugeCnt; i++) {
            _weights[i] = voter.votes(_tokenId, _gaugeVote[i]);
        }

        _deposit(_tokenId, _gaugeVote, _weights);
    }

    function createExternalBribe(address _gauge, uint256[] calldata _tokenIds, bool _shouldSplit) external {
        if (externalBribes[_gauge] != address(0)) revert BribeExists();
        
        address _bribe = voter.bribes(_gauge);
        if (_bribe == address(0)) revert InvalidGauge();
        
        _createExternalBribe(_gauge);

        if (_shouldSplit) {
            // usdc/xcal votes cannot be migrated in 1 tx
            pendingTokens[_gauge] = _tokenIds; 
        } else {
            _populate(_gauge, _bribe, _tokenIds);
        }
    }

    function populatePendingTokens(address _gauge, uint256 _batchSize) external {
        if (_batchSize == 0) revert InvalidArguments();

        uint256[] memory _tokenIds = new uint256[](_batchSize);
        uint256 _length = pendingTokens[_gauge].length;
        for (uint256 i; i < _batchSize && _length > 0; i++) {
            _tokenIds[i] = pendingTokens[_gauge][_length - 1];
            pendingTokens[_gauge].pop();
            _length = pendingTokens[_gauge].length;
        }
        if (_length == 0) delete pendingTokens[_gauge];

        address _bribe = voter.bribes(_gauge);
        if (_bribe == address(0)) revert InvalidGauge();

        _populate(_gauge, _bribe, _tokenIds);
    }

    function pendingTokensLength(address _gauge) external view returns (uint256) {
        return pendingTokens[_gauge].length;
    }

    /// =================================== INTERNAL ===================================

    /// @dev see {createExternalBribe}
    function _createExternalBribe(address _gauge) internal {
        ISwapPair _pair = ISwapPair(IGauge(_gauge).stake());
        address[] memory allowedRewards = new address[](3);
        (address tokenA, address tokenB) = _pair.tokens();
        allowedRewards[0] = tokenA;
        allowedRewards[1] = tokenB;

        if (token != tokenA && token != tokenB) {
            allowedRewards[2] = token;
        }
        
        address _bribe = externalBribeFactory.createExternalBribe(address(voter), allowedRewards);
        externalBribes[_gauge] = _bribe;
        
        emit ExternalBribeCreated(_gauge, msg.sender, _bribe, address(_pair));
    }

    // @notice allow a voter to claim earned bribes if any
    // @param _bribes list of external bribes contracts to claims bribes on
    // @param _tokens list of the tokens to claim
    // @param _tokenId the ID of veNFT to claim bribes for
    function _claimExternalBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) internal {
        require(IVotingEscrow(ve).isApprovedOrOwner(msg.sender, _tokenId));
        for (uint256 i = 0; i < _bribes.length; i++) {
            IExternalBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    /// @dev see {reset}
    function _reset(uint256 _tokenId) internal {
        uint256 _gaugeCnt = voter.length();
        for (uint i = 0; i < _gaugeCnt; i++) {
            address _gauge = voter.allGauges(i);
            uint256 _votes = voter.votes(_tokenId, _gauge);
            if (_votes != 0) {
                IExternalBribe(externalBribes[_gauge])._withdraw(uint256(_votes), _tokenId);
            }
        }
    }

    function _deposit(uint _tokenId, address[] memory _gaugeVote, uint256[] memory _weights) internal {
        uint256 _gaugeCnt = _gaugeVote.length;
        uint256 _weight = ve.balanceOfNFT(_tokenId);
        uint256 _totalVoteWeight = 0;

        for (uint256 i = 0; i < _gaugeCnt; i++) {
            _totalVoteWeight += _weights[i];
        }

        for (uint256 i = 0; i < _gaugeCnt; i++) {
            address _gauge = _gaugeVote[i];
            if (voter.isGauge(_gauge)) {
                uint256 _gaugeWeight = _weights[i] * _weight / _totalVoteWeight;
                IExternalBribe(externalBribes[_gauge])._deposit(_gaugeWeight, _tokenId);
            }
        }
    }

    function _populate(address _gauge, address __bribe, uint256[] memory _tokenIds) internal {
        IExternalBribe _externalBribe = IExternalBribe(externalBribes[_gauge]);
        IBribe _bribe = IBribe(__bribe);

        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            uint256 _balanceOf = _bribe.balanceOf(_tokenId);
            if (_balanceOf > 0) {
                _externalBribe._deposit(_balanceOf, _tokenId);
                if (_balanceOf != _externalBribe.balanceOf(_tokenId)) revert();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

struct SupplyCheckpoint {
    uint timestamp;
    uint supply;
}

struct Checkpoint {
    uint timestamp;
    uint balanceOf;
}

interface IGauge {
    function getReward(address account, address[] memory tokens) external;
    function claimFees() external returns (uint claimed0, uint claimed1);
    function left(address token) external view returns (uint);
    function deposit(uint amount, uint tokenId) external;
    function withdrawAll() external;
    function withdraw(uint amount) external;
    function totalSupply() external view returns (uint);
    function earned(address token, address account) external view returns (uint);
    function getPriorBalanceIndex(address account, uint timestamp) external view returns (uint);
    function getPriorSupplyIndex(uint timestamp) external view returns (uint);
    function getPriorRewardPerToken(address token, uint timestamp) external view returns (uint, uint);
    function batchRewardPerToken(address token, uint maxRuns) external;
    function notifyRewardAmount(address token, uint amount) external;
    function supplyNumCheckpoints() external view returns (uint);
    function supplyCheckpoints(uint i) external view returns (SupplyCheckpoint memory);
    function checkpoints(address account, uint index) external view returns (Checkpoint memory);
    function numCheckpoints(address account) external view returns (uint);
    function swapOutReward(uint i, address oldToken, address newToken) external;
    function stake() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBribe {
    function notifyRewardAmount(address token, uint amount) external;
    function left(address token) external view returns (uint);
    function _deposit(uint amount, uint tokenId) external;
    function _withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] memory tokens) external;
    function balanceOf(uint tokenId) external view returns (uint);
    function earned(address token, uint tokenId) external view returns (uint);
    function batchRewardPerToken(address token, uint maxRuns) external;
    function swapOutReward(uint i, address oldToken, address newToken) external;
    function totalSupply() external view returns (uint);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IExternalBribeFactory {
    function createExternalBribe(address voter, address[] memory allowedRewards) external returns (address);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

interface IVotingDist {
    function checkpoint_token() external;
    function checkpoint_total_supply() external;
    function claim(uint _tokenId) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISwapPair {
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function getAmountOut(uint, address) external view returns (uint);
    function claimFees() external returns (uint, uint);
    function tokens() external view returns (address, address);
    function claimable0(address _account) external view returns (uint);
    function claimable1(address _account) external view returns (uint);
    function index0() external view returns (uint);
    function index1() external view returns (uint);
    function balanceOf(address _account) external view returns (uint);
    function approve(address _spender, uint _value) external returns (bool);
    function reserve0() external view returns (uint);
    function reserve1() external view returns (uint);
    function current(address tokenIn, uint amountIn) external view returns (uint amountOut);
    function currentCumulativePrices() external view returns (uint reserve0Cumulative, uint reserve1Cumulative, uint blockTimestamp);
    function sample(address tokenIn, uint amountIn, uint points, uint window) external view returns (uint[] memory);
    function quote(address tokenIn, uint amountIn, uint granularity) external view returns (uint amountOut);
    function skim(address to) external;
}