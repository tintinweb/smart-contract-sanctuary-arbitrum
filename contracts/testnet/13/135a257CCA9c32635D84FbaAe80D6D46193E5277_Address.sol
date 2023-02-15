/**
 *Submitted for verification at Arbiscan on 2023-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return payable(address(uint160(account)));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IBaseV1Pair {
    function claimFees() external returns (uint, uint);
    function tokens() external returns (address, address);
    function stable() external returns (bool);
}

interface IBaseV1Factory {
    function isPair(address _tokenLP) external returns (bool);
}

interface MasterChef {
    function deposit(uint256, uint256) external;
    function withdraw(uint256, uint256) external;
    function userInfo(uint256, address) external view returns (uint256, uint256);
}

interface IGaugeFactory {
    function createGauge(address _owner, address _token, address _gaugeProxy) external returns (address);
}

interface IBribeFactory {
    function createBribe(address _owner, address _gaugeProxy) external returns (address);
}

interface IGauge {
    function addReward(address rewardToken, address rewardDistributor) external;
    function notifyRewardAmount(address rewardToken, uint256 amount) external;
}

interface IBribe {
    function _deposit(uint256 amount, address voter) external;
    function _withdraw(uint256 amount, address voter) external;
    function left(address rewardToken) external view returns (uint256);
    function notifyRewardAmount(address _rewardsToken, uint256 reward) external;
    function addReward(address rewardToken) external;
    function getRewardForOwner(address voter) external;
}

contract ProtocolGovernance {
    /// @notice governance address for the governance contract
    address public governance;
    address public pendingGovernance;

    /**
     * @notice Allows governance to change governance (for future upgradability)
     * @param _governance new governance address to set
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "setGovernance: !gov");
        pendingGovernance = _governance;
    }

    /**
     * @notice Allows pendingGovernance to accept their role as governance (protection pattern)
     */
    function acceptGovernance() external {
        require(
            msg.sender == pendingGovernance,
            "acceptGovernance: !pendingGov"
        );
        governance = pendingGovernance;
    }
}

contract MasterHIBERO {

    /// @notice EIP-20 token name for this token
    string public constant name = "Master hiBERO";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "mhiBERO";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint256 public totalSupply = 1e18;

    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(address => uint256) internal balances;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    constructor() {
        balances[msg.sender] = 1e18;
        emit Transfer(address(0x0), msg.sender, 1e18);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) internal {
        require(src != address(0), "_transferTokens: zero address");
        require(dst != address(0), "_transferTokens: zero address");

        balances[src] = balances[src] - amount;
        balances[dst] = balances[dst] + amount;
        emit Transfer(src, dst, amount);
    }
}

contract GaugeProxy is ProtocolGovernance, ReentrancyGuard {
    using SafeERC20 for IERC20;

    MasterChef public MASTER;
    IERC20 public hiBERO;
    IERC20 public BERO;
    IERC20 public immutable TOKEN; // mhiBERO

    address public admin; //Admin address to manage gauges like add/deprecate/resurrect

    // Address for bribeFactory
    address public bribeFactory;
    address public gaugeFactory;

    uint256 public pid = type(uint256).max; // -1 means 0xFFF....F and hasn't been set yet
    uint256 public totalWeight;

    // Time delays
    uint256 public voteDelay = 604800;
    uint256 public distributeDelay = 604800;
    uint256 public lastDistribute;
    mapping(address => uint256) public lastVote; // msg.sender => time of users last vote

    // V2 added variables for pre-distribute
    uint256 public lockedTotalWeight;
    uint256 public lockedBalance;
    uint256 public locktime;
    mapping(address => uint256) public lockedWeights; // token => weight
    mapping(address => bool) public hasDistributed; // LPtoken => bool

    // Variables verified tokens
    mapping(address => bool) public verifiedTokens; // verified tokens
    address public pairFactory;

    // VE bool
    bool public ve = false;

    address[] internal _tokens;
    address public feeDistAddr; // fee distributor address
    mapping(address => address) public gauges; // tokenLP => gauge
    mapping(address => bool) public gaugeStatus; // token => bool : false = deprecated

    // Add Guage to Bribe Mapping
    mapping(address => address) public bribes; // gauge => bribes
    mapping(address => uint256) public weights; // token => weight
    mapping(address => mapping(address => uint256)) public votes; // msg.sender => votes
    mapping(address => address[]) public tokenVote; // msg.sender => token
    mapping(address => uint256) public usedWeights; // msg.sender => total voting weight of user

    // Modifiers
    modifier hasVoted(address voter) {
        uint256 time = block.timestamp - lastVote[voter];
        require(time > voteDelay, "You voted in the last 7 days");
        _;
    }

    modifier hasDistribute() {
        uint256 time = block.timestamp - lastDistribute;
        require(
            time > distributeDelay,
            "this has been distributed in the last 7 days"
        );
        _;
    }

    constructor(
        address _masterChef,
        address _bero,
        address _hiBero,
        address _feeDist,
        address _gaugeFactory,
        address _bribeFactory, 
        address _pairFactory
    ) {
        MASTER = MasterChef(_masterChef);
        BERO = IERC20(_bero);
        hiBERO = IERC20(_hiBero);
        TOKEN = IERC20(address(new MasterHIBERO()));
        governance = msg.sender;
        admin = msg.sender;
        feeDistAddr = _feeDist;
        gaugeFactory = _gaugeFactory;
        bribeFactory = _bribeFactory;
        pairFactory = _pairFactory;
    }

    function tokens() external view returns (address[] memory) {
        return _tokens;
    }

    function getGauge(address _token) external view returns (address) {
        return gauges[_token];
    }

    function getBribes(address _gauge) external view returns (address) {
        return bribes[_gauge];
    }

    function setVerifiedToken(address _tokenLP, bool _flag) external {
        require(
            (msg.sender == governance || msg.sender == admin),
            "!gov or !admin"
        );
        verifiedTokens[_tokenLP] = _flag;
    }

    // Reset votes to 0
    function reset() external {
        _reset(msg.sender);
    }

    // Reset votes to 0
    function _reset(address _owner) internal {
        address[] storage _tokenVote = tokenVote[_owner];
        uint256 _tokenVoteCnt = _tokenVote.length;

        for (uint256 i = 0; i < _tokenVoteCnt; i++) {
            address _token = _tokenVote[i];
            uint256 _votes = votes[_owner][_token];

            if (_votes > 0) {
                totalWeight = totalWeight - _votes;
                weights[_token] = weights[_token] - _votes;
                // Bribe vote withdrawal
                IBribe(bribes[gauges[_token]])._withdraw(uint256(_votes),_owner);
                votes[_owner][_token] = 0;
            }
        }
        usedWeights[_owner] = 0;
        delete tokenVote[_owner];
    }

    // Adjusts _owner's votes according to latest _owner's inSPIRIT balance
    function poke(address _owner) public {
        address[] memory _tokenVote = tokenVote[_owner];
        uint256 _tokenCnt = _tokenVote.length;
        uint256[] memory _weights = new uint256[](_tokenCnt);
        uint256 _prevUsedWeight = usedWeights[_owner];
        uint256 _weight = hiBERO.balanceOf(_owner);

        for (uint256 i = 0; i < _tokenCnt; i++) {
            // Need to make this reflect the value deposited into bribes, anyone should be able to call this on
            // other addresses to stop them from gaming the system with outdated votes that dont lose voting power
            uint256 _prevWeight = votes[_owner][_tokenVote[i]];
            _weights[i] = _prevWeight * _weight / _prevUsedWeight;
        }

        _vote(_owner, _tokenVote, _weights);
    }

    function _vote(
        address _owner,
        address[] memory _tokenVote,
        uint256[] memory _weights
    ) internal {
        _reset(_owner);
        uint256 _tokenCnt = _tokenVote.length;
        uint256 _weight = hiBERO.balanceOf(_owner);
        uint256 _totalVoteWeight = 0;
        uint256 _usedWeight = 0;

        for (uint256 i = 0; i < _tokenCnt; i++) {
            _totalVoteWeight = _totalVoteWeight + _weights[i];
        }

        for (uint256 i = 0; i < _tokenCnt; i++) {
            address _token = _tokenVote[i];
            uint256 _tokenWeight = _weights[i] * _weight / _totalVoteWeight;

            if (_token != address(0x0) && gaugeStatus[_token]) {
                _usedWeight = _usedWeight + _tokenWeight;
                totalWeight = totalWeight + _tokenWeight;
                weights[_token] = weights[_token] + _tokenWeight;
                tokenVote[_owner].push(_token);
                votes[_owner][_token] = _tokenWeight;
                // Bribe vote deposit
                IBribe(bribes[gauges[_token]])._deposit(uint256(_tokenWeight), _owner);
            }
        }

        usedWeights[_owner] = _usedWeight;
    }

    function vote(address[] calldata _tokenVote, uint256[] calldata _weights)
        external
        hasVoted(msg.sender)
    {
        require(_tokenVote.length == _weights.length);
        lastVote[msg.sender] = block.timestamp;
        _vote(msg.sender, _tokenVote, _weights);
    }

    function setAdmin(address _admin) external {
        require(msg.sender == governance, "!gov");
        admin = _admin;
    }

    // Add new token gauge
    function addGauge(address _tokenLP)
        external
        returns (address)
    {
        require(gauges[_tokenLP] == address(0x0), "exists");
        require(IBaseV1Factory(pairFactory).isPair(_tokenLP), "!_tokenLP");
        (address _token0, address _token1) = IBaseV1Pair(_tokenLP).tokens();
        require(verifiedTokens[_token0] && verifiedTokens[_token1], "!verified");
        require(hiBERO.balanceOf(msg.sender) > hiBERO.totalSupply() / 1000 || msg.sender == governance || msg.sender == admin, "!supply");

        _tokens.push(_tokenLP);
        gaugeStatus[_tokenLP] = true;

        // Deploy Gauge 
        address _gauge = IGaugeFactory(gaugeFactory).createGauge(governance, _tokenLP, address(this));
        gauges[_tokenLP] = _gauge;
        IGauge(_gauge).addReward(address(BERO), address(this));

        // Deploy Bribe
        address _bribe = IBribeFactory(bribeFactory).createBribe(governance, address(this));
        bribes[_gauge] = _bribe;
        IBribe(_bribe).addReward(_token0);
        IBribe(_bribe).addReward(_token1);
        
        emit GaugeAdded(_tokenLP);
        return gauges[_tokenLP];
    }

    // Deprecate existing gauge
    function deprecateGauge(address _token) external {
        require(
            (msg.sender == governance || msg.sender == admin),
            "!gov or !admin"
        );
        require(gauges[_token] != address(0x0), "does not exist");
        require(gaugeStatus[_token], "gauge is not active");
        gaugeStatus[_token] = false;
        emit GaugeDeprecated(_token);
    }

    // Bring Deprecated gauge back into use
    function resurrectGauge(address _token) external {
        require(
            (msg.sender == governance || msg.sender == admin),
            "!gov or !admin"
        );
        require(gauges[_token] != address(0x0), "does not exist");
        require(!gaugeStatus[_token], "gauge is active");
        gaugeStatus[_token] = true;
        emit GaugeResurrected(_token);
    }

    // Sets MasterChef PID
    function setPID(uint256 _pid) external {
        require(msg.sender == governance, "!gov");
        pid = _pid;
    }

    // Deposits mhiBERO into MasterChef
    function deposit() public {
        require(pid != type(uint256).max, "pid not initialized");
        IERC20 _token = TOKEN;
        uint256 _balance = _token.balanceOf(address(this));
        _token.safeApprove(address(MASTER), 0);
        _token.safeApprove(address(MASTER), _balance);
        MASTER.deposit(pid, _balance);
    }

    // Fetches BERO
    // Change from public to internal, ONLY preDistribute should be able to call
    function collect() internal {
        (uint256 _locked, ) = MASTER.userInfo(pid, address(this));
        MASTER.withdraw(pid, _locked);
        deposit();
    }

    function length() external view returns (uint256) {
        return _tokens.length;
    }

    function preDistribute() external nonReentrant hasDistribute {
        lockedTotalWeight = totalWeight;
        for (uint256 i = 0; i < _tokens.length; i++) {
            lockedWeights[_tokens[i]] = weights[_tokens[i]];
            hasDistributed[_tokens[i]] = false;
        }
        collect();
        lastDistribute = block.timestamp;
        uint256 _balance = BERO.balanceOf(address(this));
        lockedBalance = _balance;
        uint256 _hiBERORewards = 0;
        if (ve) {
            uint256 _lockedBERO = BERO.balanceOf(address(hiBERO));
            uint256 _beroSupply = BERO.totalSupply();
            _hiBERORewards = _balance * ((_lockedBERO / _beroSupply) ** 2) / 2;

            if (_hiBERORewards > 0) {
                BERO.safeTransfer(feeDistAddr, _hiBERORewards);
                lockedBalance = BERO.balanceOf(address(this));
            }
        }
        locktime = block.timestamp;
        emit PreDistributed(_hiBERORewards);
    }

    function distribute(uint256 _start, uint256 _end) external nonReentrant {
        require(_start < _end, "bad _start");
        require(_end <= _tokens.length, "bad _end");

        if (lockedBalance > 0 && lockedTotalWeight > 0) {
            for (uint256 i = _start; i < _end; i++) {
                address _token = _tokens[i];
                if (!hasDistributed[_token] && gaugeStatus[_token]) {
                    address _gauge = gauges[_token];
                    uint256 _reward = lockedBalance * lockedWeights[_token] / lockedTotalWeight;
                    if (_reward > 0) {
                        BERO.safeApprove(_gauge, 0);
                        BERO.safeApprove(_gauge, _reward);
                        IGauge(_gauge).notifyRewardAmount(address(BERO), _reward);
                    }
                    hasDistributed[_token] = true;
                }
            }
        }
    }

    function claimBribes(address[] memory _bribes, address _user) external {
        for (uint256 i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForOwner(_user);
        }
    }

    // Update fee distributor address
    function updateFeeDistributor(address _feeDistAddr) external {
        require(msg.sender == governance, "!AUTH");
        feeDistAddr = _feeDistAddr;
    }

    function setGaugeFactory(address _gaugeFactory) external {
        require(msg.sender == governance, "!AUTH");
        gaugeFactory = _gaugeFactory;
    }

    function setBribeFactory(address _bribeFactory) external {
        require(msg.sender == governance, "!AUTH");
        bribeFactory = _bribeFactory;
    }

    function toggleVE() external {
        require(
            (msg.sender == governance || msg.sender == admin),
            "turnVeOn: permission is denied!"
        );
        ve = !ve;
    }

    event GaugeAdded(address tokenLP);
    event GaugeAddedByOwner(address tokenLP, address token0, address token1);
    event GaugeDeprecated(address tokenLP);
    event GaugeResurrected(address tokenLP);
    event PreDistributed(uint256 beroRewards);
}