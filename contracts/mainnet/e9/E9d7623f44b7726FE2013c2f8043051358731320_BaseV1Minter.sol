// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import './libraries/Math.sol';
import './interfaces/IVotingEscrow.sol';
import './interfaces/IUnderlying.sol';
import './interfaces/IBaseV1Voter.sol';
import './interfaces/IVotingEscrowDistributor.sol';

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract BaseV1Minter {

    uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint internal constant emission = 98;
    uint internal constant tail_emission = 2;
    uint internal constant target_base = 100; // 2% per week target emission
    uint internal constant tail_base = 100; // 2% per week target emission
    IUnderlying public immutable _token;
    IBaseV1Voter public immutable _voter;
    IVotingEscrow public immutable _ve;
    IVotingEscrowDistributor public immutable _ve_dist;
    uint public weekly = 20000000e18;
    uint public active_period;
    uint internal constant lock = 86400 * 7 * 52 * 4;

    address internal initializer;
    address public team;
    address public pendingTeam;
    uint public teamRate;
    uint public constant MAX_TEAM_RATE = 50; // 50 bps = 0.05%

    event Mint(address indexed sender, uint weekly, uint circulating_supply, uint circulating_emission);

    constructor(
        address __voter, // the voting & distribution system
        address  __ve, // the ve(3,3) system that will be locked into
        address __ve_dist // the distribution system that ensures users aren't diluted
    ) {
        initializer = msg.sender;
        team = 0x0c5D52630c982aE81b78AB2954Ddc9EC2797bB9c;
        teamRate = 30; // 30 bps = 0.03%
        _token = IUnderlying(IVotingEscrow(__ve).token());
        _voter = IBaseV1Voter(__voter);
        _ve = IVotingEscrow(__ve);
        _ve_dist = IVotingEscrowDistributor(__ve_dist);
        active_period = ((block.timestamp + (2 * week)) / week) * week;
    }

    function initialize(
        address[] memory claimants,
        uint[] memory amounts,
        uint max // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
    ) external {
        require(initializer == msg.sender);
        _token.mint(address(this), max);
        _token.approve(address(_ve), type(uint).max);
        for (uint i = 0; i < claimants.length; i++) {
            _ve.create_lock_for(amounts[i], lock, claimants[i]);
        }
        initializer = address(0);
        active_period = (block.timestamp / week) * week;
    }
    
    function setTeam(address _team) external {
        require(msg.sender == team, "not team");
        pendingTeam = _team;
    }

    function acceptTeam() external {
        require(msg.sender == pendingTeam, "not pending team");
        team = pendingTeam;
    }

    function setTeamRate(uint _teamRate) external {
        require(msg.sender == team, "not team");
        require(_teamRate <= MAX_TEAM_RATE, "rate too high");
        teamRate = _teamRate;
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint) {
        return _token.totalSupply() - _ve.totalSupply();
    }

    // emission calculation is 2% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint) {
        return weekly * emission * circulating_supply() / target_base / _token.totalSupply();
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint) {
        return Math.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint) {
        return circulating_supply() * tail_emission / tail_base;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_growth(uint _minted) public view returns (uint) {
        return _ve.totalSupply() * _minted / _token.totalSupply();
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint) {
        uint _period = active_period;
        if (block.timestamp >= _period + week && initializer == address(0)) { // only trigger if new week
            _period = block.timestamp / week * week;
            active_period = _period;
            weekly = weekly_emission();

            uint _growth = calculate_growth(weekly);
            uint _teamEmissions = (teamRate * (_growth + weekly)) / 1000;
            uint _required = _growth + weekly + _teamEmissions;
            uint _balanceOf = _token.balanceOf(address(this));
            if (_balanceOf < _required) {
                _token.mint(address(this), _required - _balanceOf);
            }

            require(_token.transfer(team, _teamEmissions));
            require(_token.transfer(address(_ve_dist), _growth));
            _ve_dist.checkpoint_token(); // checkpoint token balance that was just minted in ve_dist
            _ve_dist.checkpoint_total_supply(); // checkpoint supply

            _token.approve(address(_voter), weekly);
            _voter.notifyRewardAmount(weekly);

            emit Mint(msg.sender, weekly, circulating_supply(), circulating_emission());
        }
        return _period;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Math {
    
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
    function locked__amount(uint _tokenId) external view returns (uint);
    function approve(address spender, uint tokenId) external;
    function balanceOfNFT(uint) external view returns (uint);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function totalSupply() external view returns (uint);
    function supply() external view returns (uint);
    function create_lock_for(uint, uint, address) external returns (uint);
    function lockVote(uint tokenId) external;
    function isVoteExpired(uint tokenId) external view returns (bool);
    function voteExpiry(uint _tokenId) external view returns (uint);
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
    function burn(uint _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IUnderlying {
    function approve(address spender, uint value) external returns (bool);
    function mint(address, uint) external;
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBaseV1Voter {

    function attachTokenToGauge(uint tokenId, address account) external;
    function detachTokenFromGauge(uint tokenId, address account) external;
    function emitDeposit(uint tokenId, address account, uint amount) external;
    function emitWithdraw(uint tokenId, address account, uint amount) external;
    function notifyRewardAmount(uint amount) external;
    function _ve() external view returns (address);
    function createGauge(address _pair) external returns (address);
    function factory() external view returns (address);
    function listing_fee() external view returns (uint);
    function whitelist(address _token) external;
    function isWhitelisted(address _token) external view returns (bool);
    function delist(address _token) external;
    function bribeFactory() external view returns (address);
    function bribes(address gauge) external view returns (address);
    function gauges(address pair) external view returns (address);
    function isGauge(address gauge) external view returns (bool);
    function allGauges(uint index) external view returns (address);
    function vote(uint tokenId, address[] calldata gaugeVote, uint[] calldata weights) external;
    function gaugeVote(uint tokenId) external view returns (address[] memory);
    function votes(uint tokenId, address gauge) external view returns (uint);
    function weights(address gauge) external view returns (uint);
    function usedWeights(uint tokenId) external view returns (uint);
    function claimable(address gauge) external view returns (uint);
    function totalWeight() external view returns (uint);
    function reset(uint _tokenId) external;
    function claimFees(address[] memory _fees, address[][] memory _tokens, uint _tokenId) external;
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external;
    function distributeFees(address[] memory _gauges) external;
    function updateGauge(address _gauge) external;
    function poke(uint _tokenId) external;
    function initialize(address[] memory _tokens, address _minter) external;
    function minter() external view returns (address);
    function admin() external view returns (address);
    function claimRewards(address[] memory _gauges, address[][] memory _tokens) external;
    function isReward(address gauge, address token) external view returns (bool);
    function isBribe(address bribe, address token) external view returns (bool);
    function isLive(address gauge) external view returns (bool);
    function setBribe(address _bribe, address _token, bool _status) external;
    function setReward(address _gauge, address _token, bool _status) external;
    function killGauge(address _gauge) external;
    function reviveGauge(address _gauge) external;
    function distroFees() external;
    function distro() external;
    function distribute() external;
    function distribute(address _gauge) external;
    function distribute(uint start, uint finish) external;
    function distribute(address[] memory _gauges) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVotingEscrowDistributor {
    function checkpoint_token() external;
    function checkpoint_total_supply() external;
}