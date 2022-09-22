// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./interfaces/IVotingEscrow.sol";
import "../core/interfaces/ISwapPair.sol";
import "./interfaces/IGaugeFactory.sol";
import "./interfaces/IBribeFactory.sol";
import "./interfaces/IGauge.sol";
import "./interfaces/IBribe.sol";
import "../core/interfaces/ISwapFactory.sol";
import "./interfaces/IMinter.sol";
import {IVoter} from "./interfaces/IVoter.sol";

contract Voter is IVoter {

    address public immutable _ve;
    address public immutable factory;
    address public convenience;
    address internal immutable base;
    address public gaugeFactory;
    address public immutable bribeFactory;
    uint internal constant DURATION = 7 days; // rewards are released over 7 days
    address public minter;

    uint public totalWeight; // total voting weight

    address[] public allGauges; // all gauges viable for incentives
    mapping(address => address) public gauges; // pair => maturity => gauge
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => address) public bribes; // gauge => bribe
    mapping(address => uint256) public weights; // gauge => weight
    mapping(uint => mapping(address => uint256)) public votes; // nft => gauge => votes
    mapping(uint => address[]) public gaugeVote; // nft => gauge
    mapping(uint => uint) public usedWeights;  // nft => total voting weight of user
    mapping(uint => uint) public lastVote; // nft id => timestamp of last vote 
    mapping(address => bool) public isGauge;
    mapping(address => bool) public isWhitelisted;

    mapping(address => uint) public claimable;
    uint internal index;
    mapping(address => uint) internal supplyIndex;

    event GaugeCreated(address indexed gauge, address creator, address indexed bribe, address indexed pair);
    event Voted(address indexed voter, uint tokenId, uint256 weight);
    event Abstained(uint tokenId, uint256 weight);
    event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event NotifyReward(address indexed sender, address indexed reward, uint amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event Attach(address indexed owner, address indexed gauge, uint tokenId);
    event Detach(address indexed owner, address indexed gauge, uint tokenId);
    event Whitelisted(address indexed whitelister, address indexed token);

    constructor(address __ve, address _factory, address  _gauges, address _bribes) {
        _ve = __ve;
        factory = _factory;
        base = IVotingEscrow(__ve).token();
        gaugeFactory = _gauges;
        bribeFactory = _bribes;
        minter = msg.sender;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    //TODO: decide which tokens to whitelist after deployment
    // @param _tokens list of ERC20 tokens to whitelist
    // @param _minter address of the minter contract
    function initialize(/*address[] memory _tokens*/address _minter) external {
        require(msg.sender == minter);
        // for (uint i = 0; i < _tokens.length; i++) {
        //     _whitelist(_tokens[i]);
        // }
        minter = _minter;
    }

    // TODO: change denominator
    //@return the fee that needs to be paid or held in a lock to be allowed to whitelist tokens
    function listing_fee() public view returns (uint) {
        return (IERC20(base).totalSupply() - IERC20(_ve).totalSupply()) / 10000;
    }

    // @param _tokenId the ID of the veNFT to reset votes for
    function reset(uint _tokenId) external { // OR msg.sender == votingescrow when withdrawing
        require(_activePeriod() > lastVote[_tokenId], "voted recently");
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        lastVote[_tokenId] = block.timestamp;
        _reset(_tokenId);
        IVotingEscrow(_ve).abstain(_tokenId);
    }

    function _reset(uint _tokenId) internal {
        address[] storage _gaugeVote = gaugeVote[_tokenId];
        uint _gaugeVoteCnt = _gaugeVote.length;
        uint256 _totalWeight = 0;
        for (uint i = 0; i < _gaugeVoteCnt; i++) {
            address _gauge = _gaugeVote[i];
            uint256 _votes = votes[_tokenId][_gauge];
            if (_votes != 0) {
                _updateFor(_gauge);
                weights[_gauge] -= _votes;
                votes[_tokenId][_gauge] -= _votes;
                if (_votes > 0) {
                    IBribe(bribes[_gauge])._withdraw(uint256(_votes), _tokenId);
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[_tokenId] = 0;
        delete gaugeVote[_tokenId];
    }

    // @param _tokenId the ID of the NFT to poke
    // @dev To be called on voters abusing their voting power
    // @dev _weights are the same as the last ID's vote !
    function poke(uint _tokenId) external {
        address[] memory _gaugeVote = gaugeVote[_tokenId];
        uint _gaugeCnt = _gaugeVote.length;
        uint256[] memory _weights = new uint256[](_gaugeCnt);

        for (uint i = 0; i < _gaugeCnt; i++) {
            _weights[i] = votes[_tokenId][_gaugeVote[i]];
        }

        _vote(_tokenId, _gaugeVote, _weights);
    }

    function _vote(uint _tokenId, address[] memory _gaugeVote, uint256[] memory _weights) internal {
        _reset(_tokenId);
        uint _gaugeCnt = _gaugeVote.length;
        uint256 _weight = IVotingEscrow(_ve).balanceOfNFT(_tokenId);
        uint256 _totalVoteWeight = 0;
        uint256 _totalWeight = 0;
        uint256 _usedWeight = 0;

        for (uint i = 0; i < _gaugeCnt; i++) {
            _totalVoteWeight += _weights[i];
        }

        for (uint i = 0; i < _gaugeCnt; i++) {
            address _gauge = _gaugeVote[i];
            if (isGauge[_gauge]) {
                uint256 _gaugeWeight = _weights[i] * _weight / _totalVoteWeight;
                require(votes[_tokenId][_gauge] == 0);
                require(_gaugeWeight != 0);
                _updateFor(_gauge);

                gaugeVote[_tokenId].push(_gauge);

                weights[_gauge] += _gaugeWeight;
                votes[_tokenId][_gauge] += _gaugeWeight;
                IBribe(bribes[_gauge])._deposit(_gaugeWeight, _tokenId);
                _usedWeight += _gaugeWeight;
                _totalWeight += _gaugeWeight;
                emit Voted(msg.sender, _tokenId, _gaugeWeight);
            }
        }
        if (_usedWeight > 0) IVotingEscrow(_ve).voting(_tokenId);
        totalWeight += _totalWeight;
        usedWeights[_tokenId] = _usedWeight;
    }

    // @param _tokenId The id of the veNFT to vote with
    // @param _gaugeVote The list of gauges to vote for
    // @param _weights The list of weights to vote for each gauge
    // @dev the sum of weights is the total weight of the veNFT at max
    function vote(uint tokenId, address[] calldata _gaugeVote, uint256[] calldata _weights) external {
        uint _lockEnd = IVotingEscrow(_ve).locked__end(tokenId);
        require(_activePeriod() > lastVote[tokenId], "already voted");
        require(_nextPeriod() < _lockEnd, "lock expires soon");
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, tokenId));
        require(_gaugeVote.length == _weights.length);
        lastVote[tokenId] = block.timestamp;
        _vote(tokenId, _gaugeVote, _weights);
    }

    // TODO: decide on gauge whitelisting model
    // @param _token the ERC20 token to whitelist
    // @param _tokenId the ID of veNFT whitelisting
    function whitelist(address _token, uint _tokenId) public {
        if (_tokenId > 0) {
            require(msg.sender == IVotingEscrow(_ve).ownerOf(_tokenId));
            require(IVotingEscrow(_ve).balanceOfNFT(_tokenId) > listing_fee());
        } else {
            _safeTransferFrom(base, msg.sender, minter, listing_fee());
        }

        _whitelist(_token);
    }

    function _whitelist(address _token) internal {
        require(!isWhitelisted[_token]);
        isWhitelisted[_token] = true;
        emit Whitelisted(msg.sender, _token);
    }

    // @param _pair the pair to create a gauge for
    // @return the address of the gauge 
    function createSwapGauge(address _pair) external returns (address gauge) {
        require(ISwapFactory(factory).isPair(_pair), "!pair");
        require(gauges[_pair] == address(0x0), "exists");
        (address _tokenA, address _tokenB) = ISwapPair(_pair).tokens();
        require(isWhitelisted[_tokenA] && isWhitelisted[_tokenB], "!whitelisted");
        address _bribe = IBribeFactory(bribeFactory).createBribe();
        address _gauge = IGaugeFactory(gaugeFactory).createGauge(_pair, _bribe, _ve);
        IERC20(base).approve(_gauge, type(uint).max);
        bribes[_gauge] = _bribe;
        gauges[_pair] = _gauge;
        poolForGauge[_gauge] = _pair;
        isGauge[_gauge] = true;
        _updateFor(_gauge);
        allGauges.push(_gauge);
        emit GaugeCreated(_gauge, msg.sender, _bribe, _pair);
        return _gauge;
    }

    function attachTokenToGauge(uint tokenId, address account) external {
        require(isGauge[msg.sender]);
        if (tokenId > 0) IVotingEscrow(_ve).attach(tokenId);
        emit Attach(account, msg.sender, tokenId);
    }

    function emitDeposit(uint tokenId, address account, uint amount) external {
        require(isGauge[msg.sender]);
        emit Deposit(account, msg.sender, tokenId, amount);
    }

    function detachTokenFromGauge(uint tokenId, address account) external {
        require(isGauge[msg.sender]);
        if (tokenId > 0) IVotingEscrow(_ve).detach(tokenId);
        emit Detach(account, msg.sender, tokenId);
    }

    function emitWithdraw(uint tokenId, address account, uint amount) external {
        require(isGauge[msg.sender]);
        emit Withdraw(account, msg.sender, tokenId, amount);
    }

    function length() external view returns (uint) {
        return allGauges.length;
    }

    // @dev called by Minter contract to distribute weekly rewards
    // @param _amount the amount of tokens distributed
    function notifyRewardAmount(uint _amount) external {
        _safeTransferFrom(base, msg.sender, address(this), _amount); // transfer the distro in
        uint256 _ratio = _amount * 1e18 / totalWeight; // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
            index += _ratio;
        }
        emit NotifyReward(msg.sender, base, _amount);
    }

    function updateFor(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            _updateFor(_gauges[i]);
        }
    }

    function updateForRange(uint start, uint end) public {
        for (uint i = start; i < end; i++) {
            _updateFor(allGauges[i]);
        }
    }

    function updateAll() external {
        updateForRange(0, allGauges.length);
    }

    // @dev update a gauge eligibility for rewards to the current index
    // @param _gauge the gauge to update
    function updateGauge(address _gauge) external {
        _updateFor(_gauge);
    }

    function _updateFor(address _gauge) internal {
        uint256 _supplied = weights[_gauge];
        if (_supplied > 0) {
            uint _supplyIndex = supplyIndex[_gauge];
            uint _index = index; // get global index0 for accumulated distro
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta > 0) {
                uint _share = uint(_supplied) * _delta / 1e18; // add accrued difference for each supplied token
                claimable[_gauge] += _share;
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

    // @dev allow a gauge depositor to claim earned rewards if any
    // @param _gauges list of gauges contracts to claim rewards on
    // @param _tokens list of  tokens to claim
    function claimRewards(address[] memory _gauges, address[][] memory _tokens) external {
        for (uint i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
        }
    }

    // @dev allow a voter to claim earned bribes if any
    // @param _bribes list of bribes contracts to claims bribes on
    // @param _tokens list of the tokens to claim
    // @param _tokenId the ID of veNFT to claim bribes for
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        for (uint i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    // @dev allow voter to claim earned fees
    // @param _fees list of bribes contracts to claim fees on
    // @param _tokens list of the tokens to claim
    // @param _tokenId the ID of veNFT to claim fees for
    function claimFees(address[] memory _fees, address[][] memory _tokens, uint _tokenId) external {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        for (uint i = 0; i < _fees.length; i++) {
            IBribe(_fees[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    // @dev distribute earned fees to the bribe contract for a given gauge
    // @param _gauges the gauges to distribute fees for
    function distributeFees(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).claimFees();
        }
    }

    // @dev distribute fair share of rewards to a gauge
    // @param _gauge the gauge to distribute rewards to
    function distribute(address _gauge) public lock {
        IMinter(minter).update_period();
        _updateFor(_gauge);
        uint _claimable = claimable[_gauge];
        if (_claimable > IGauge(_gauge).left(base) && _claimable / DURATION > 0) {
            claimable[_gauge] = 0;
            IGauge(_gauge).notifyRewardAmount(base, _claimable);
            emit DistributeReward(msg.sender, _gauge, _claimable);
        }
    }

    function distro() external {
        distribute(0, allGauges.length);
    }

    function distribute() external {
        distribute(0, allGauges.length);
    }

    function distribute(uint start, uint finish) public {
        for (uint x = start; x < finish; x++) {
            distribute(allGauges[x]);
        }
    }

    function distribute(address[] memory _gauges) external {
        for (uint x = 0; x < _gauges.length; x++) {
            distribute(_gauges[x]);
        }
    }

    // @dev current active vote period
    // @return the UNIX timestamp of the beginning of the current vote period
    function _activePeriod() internal view returns (uint activePeriod) {
        activePeriod = block.timestamp / DURATION * DURATION;
    }

    // @dev next vote period
    // @return the UNIX timestamp of the beginning of the next vote period
    function _nextPeriod() internal view returns(uint nextPeriod) {
        nextPeriod = (block.timestamp + DURATION) / DURATION * DURATION;
    }


    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    // ADMIN METHODS
     
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
    function user_point_history__ts(uint _tokenId, uint _idx) external view returns (uint);
    function locked__end(uint _tokenId) external view returns (uint);

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

    function create_lock(uint value, uint duration) external returns (uint);
    function setVoter(address voter) external;
    function balanceOf(address owner) external view returns (uint);
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
    function tokens() external returns (address, address);
    function claimable0(address _account) external view returns (uint);
    function claimable1(address _account) external view returns (uint);
    function index0() external view returns (uint);
    function index1() external view returns (uint);
    function balanceOf(address _account) external view returns (uint);
    function approve(address _spender, uint _value) external returns (bool);
    function reserve0() external view returns (uint);
    function reserve1() external view returns (uint);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IGaugeFactory {
    function createGauge(address _pair, address _bribe, address _ve) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBribeFactory {
    function createBribe() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IGauge {
    function notifyRewardAmount(address token, uint amount) external;
    function getReward(address account, address[] memory tokens) external;
    function claimFees() external returns (uint claimed0, uint claimed1);
    function left(address token) external view returns (uint);
    function deposit(uint amount, uint tokenId) external;
    function withdrawAll() external;
    function totalSupply() external view returns (uint);
    function earned(address token, address account) external view returns (uint);
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISwapFactory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function fee(bool stable) external view returns (uint);
    function feeCollector() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IMinter {
    function update_period() external returns (uint);
    // function initialize(address[] memory claimants, uint[] memory amounts, uint max) external;
    function initialize() external;
    function active_period() external view returns (uint);
    function weekly_emission() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoter {

    enum PoolType {
        SWAP,
        LENDING
    } 

    struct Pool {
        address poolAddress;
        uint maturity; // type(uint).max if SWAP type
        PoolType poolType;
    }

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
    function whitelist(address token, uint tokenId) external;
    function isWhitelisted(address token) external view returns (bool);
    function bribeFactory() external view returns (address);
    function bribes(address gauge) external view returns (address);
    function gauges(address pair) external view returns (address);
    function isGauge(address gauge) external view returns (bool);
    function allGauges(uint index) external view returns (address);
    function vote(uint tokenId, address[] calldata gaugeVote, uint[] calldata weights) external;
    function lastVote(uint tokenId) external view returns(uint);
    //function gaugeVote(uint tokenId) external view returns (address[] memory);
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

}