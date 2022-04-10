/**
 *Submitted for verification at Arbiscan on 2022-04-10
*/

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}interface Randomizer {
    // Sets the number of blocks that must pass between increment the commitId and seeding the random
    // Admin
    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement)
        external;

    // Increments the commit id.
    // Admin
    function incrementCommitId() external;

    // Adding the random number needs to be done AFTER incrementing the commit id on a separate transaction. If
    // these are done together, there is a potential vulnerability to front load a commit when the bad actor
    // sees the value of the random number.
    function addRandomForCommit(uint256 _seed) external;

    // Returns a request ID for a random number. This is unique.
    function requestRandomNumber() external returns (uint256);

    // Returns the random number for the given request ID. Will revert
    // if the random is not ready.
    function revealRandomNumber(uint256 _requestId)
        external
        view
        returns (uint256);

    // Returns if the random number for the given request ID is ready or not. Call
    // before calling revealRandomNumber.
    function isRandomReady(uint256 _requestId) external view returns (bool);
}enum Lock {
    twoWeeks,
    oneMonth,
    threeMonths,
    sixMonths,
    twelveMonths
}

interface AtlasMine {
    function deposit(uint256 _amount, Lock _lock) external;

    function withdrawPosition(uint256 _depositId, uint256 _amount)
        external
        returns (bool);

    function withdrawAll() external;

    function harvestPosition(uint256 _depositId) external;

    function harvestAll() external;

    function withdrawAndHarvestPosition(uint256 _depositId, uint256 _amount)
        external;

    function withdrawAndHarvestAll() external;

    function currentId(address) external returns (uint256);
}
struct Lottery {
    uint256 depositId;
    uint256 requestId;
    uint256 total;
    address[] contestants;
    uint256[] balances;
    uint256 startTime;
}

contract MagicLottery {
    /// Storage ///

    ERC20 public magicToken;
    AtlasMine public atlasMine;
    Randomizer public randomizer;

    address public operator;
    bool public paused = false;
    bool private locked;

    uint256 public lastLottery;
    uint256 public MIN_TIME_ELAPSED = 1 days;

    address[] public nextLotteryContestants;
    uint256[] public nextLotteryBalances;
    uint256 public nextLotteryTotalBalance;
    mapping(address => uint256) public indexOfNextLotteryContestant;
    mapping(address => bool) public nextLotteryContestantExists;

    Lottery[] private allLotteries;

    mapping(address => uint256) public postLotteryBalances;

    uint256 public fee;
    uint256 public feeReserve;
    uint256 public constant MAX_FEE = 3000;
    uint256 public constant FEE_DENOMINATOR = 10000;

    /// Errors ///

    error InvalidAmount(uint256 amount);
    error InvalidOperator(address operator);
    error InvalidFeeAmount(uint256 amount);
    error NotEnoughContestants();
    error NotEnoughTimeElapsed();
    error Unauthorized();
    error ContractPaused();
    error NonReentrant();

    /// Events ///

    event EnteredLottery(address indexed contestant, uint256 amount);
    event CancelledEntry(address indexed contestant);
    event LotteryStarted(
        uint256 indexed depositId,
        uint256 requestId,
        uint256 total
    );
    event LotteryEnded(
        uint256 indexed depositId,
        address indexed winner,
        uint256 jackpot
    );
    event PostLotteryBalancesWithdrawn(
        address indexed contestant,
        uint256 amount
    );
    event FeesWithdrawn(address indexed operator, uint256 amount);
    event OperatorChanged(address indexed operator);
    event FeeChanged(uint256 fee);
    event PauseStatusChanged(bool paused);

    /// Modifiers ///

    modifier onlyOperator() {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyWhenNotPaused() {
        if (paused) {
            revert ContractPaused();
        }
        _;
    }

    modifier nonReentrant() {
        if (locked) {
            revert NonReentrant();
        }
        locked = true;
        _;
        locked = false;
    }

    /// Constructor ///

    constructor(
        ERC20 _magicToken,
        AtlasMine _atlasMine,
        Randomizer _randomizer,
        uint256 _fee
    ) {
        if (_fee <= 0 || _fee > MAX_FEE) {
            revert InvalidFeeAmount(_fee);
        }

        magicToken = _magicToken;
        atlasMine = _atlasMine;
        randomizer = _randomizer;
        fee = _fee;
        operator = msg.sender;
        lastLottery = block.timestamp;

        emit FeeChanged(_fee);
        emit OperatorChanged(msg.sender);
    }

    /// Public Methods ///

    function enterNextLottery(uint256 _amount)
        external
        onlyWhenNotPaused
        returns (uint256)
    {
        if (_amount <= 0) {
            revert InvalidAmount(_amount);
        }

        // Effects
        magicToken.transferFrom(msg.sender, address(this), _amount);

        if (!nextLotteryContestantExists[msg.sender]) {
            indexOfNextLotteryContestant[msg.sender] = nextLotteryContestants
                .length;
            nextLotteryContestants.push(msg.sender);
            nextLotteryBalances.push(0);
            nextLotteryContestantExists[msg.sender] = true;
        }
        uint256 index = indexOfNextLotteryContestant[msg.sender];
        nextLotteryBalances[index] += _amount;
        nextLotteryTotalBalance += _amount;

        // Interactions
        emit EnteredLottery(msg.sender, nextLotteryBalances[index]);

        return nextLotteryBalances[index];
    }

    function cancelEntry() external returns (bool) {
        if (!nextLotteryContestantExists[msg.sender]) {
            return false;
        }

        uint256 indexToDelete = indexOfNextLotteryContestant[msg.sender];
        uint256 balance = nextLotteryBalances[indexToDelete];

        // Effects
        nextLotteryContestantExists[msg.sender] = false;
        nextLotteryBalances[indexToDelete] = nextLotteryBalances[
            nextLotteryBalances.length - 1
        ];
        nextLotteryBalances.pop();
        nextLotteryContestants[indexToDelete] = nextLotteryContestants[
            nextLotteryContestants.length - 1
        ];
        nextLotteryContestants.pop();
        indexOfNextLotteryContestant[
            nextLotteryContestants[indexToDelete]
        ] = indexToDelete;
        nextLotteryTotalBalance -= balance;
        magicToken.transfer(msg.sender, balance);

        // Interactions
        emit CancelledEntry(msg.sender);

        return true;
    }

    function beginNextLottery()
        external
        onlyWhenNotPaused
        nonReentrant
        returns (uint256)
    {
        if (lastLottery + MIN_TIME_ELAPSED > block.timestamp) {
            revert NotEnoughTimeElapsed();
        }
        if (nextLotteryContestants.length < 2) {
            revert NotEnoughContestants();
        }

        magicToken.approve(address(atlasMine), nextLotteryTotalBalance);

        // Interactions
        atlasMine.deposit(nextLotteryTotalBalance, Lock.twoWeeks);
        uint256 requestId = randomizer.requestRandomNumber();
        uint256 depositId = atlasMine.currentId(address(this));
        emit LotteryStarted(depositId, requestId, nextLotteryTotalBalance);

        // Effects
        allLotteries.push(
            Lottery({
                depositId: depositId,
                requestId: requestId,
                total: nextLotteryTotalBalance,
                contestants: nextLotteryContestants,
                balances: nextLotteryBalances,
                startTime: block.timestamp
            })
        );

        _resetNextLottery();

        return depositId;
    }

    function drawWinner() external nonReentrant returns (address) {
        Lottery memory lottery = allLotteries[0];
        uint256 preDrawBalance = magicToken.balanceOf(address(this));
        atlasMine.withdrawAndHarvestPosition(
            lottery.depositId,
            type(uint256).max
        );
        uint256 harvestedAmount = magicToken.balanceOf(address(this)) -
            preDrawBalance;
        uint256 totalRewards = harvestedAmount - lottery.total;
        uint256 totalFee = (totalRewards * fee) / FEE_DENOMINATOR;
        uint256 randomNum = randomizer.revealRandomNumber(lottery.requestId);
        address winner = _getWinner(randomNum, lottery);

        feeReserve += totalFee;

        uint256 contestantsLength = lottery.contestants.length;
        for (uint256 i; i < contestantsLength; ++i) {
            if (winner == lottery.contestants[i]) {
                postLotteryBalances[winner] +=
                    lottery.balances[i] +
                    (totalRewards - totalFee);
                continue;
            }
            postLotteryBalances[lottery.contestants[i]] = lottery.balances[i];
        }

        uint256 lotteriesLength = allLotteries.length;
        for (uint256 i; i < lotteriesLength - 1; ++i) {
            allLotteries[i] = allLotteries[i + 1];
        }
        allLotteries.pop();

        emit LotteryEnded(lottery.depositId, winner, totalRewards);

        return winner;
    }

    function withdrawWinnings() external returns (bool) {
        uint256 balance = postLotteryBalances[msg.sender];

        if (balance == 0) {
            return false;
        }

        postLotteryBalances[msg.sender] = 0;

        magicToken.transfer(msg.sender, balance);
        emit PostLotteryBalancesWithdrawn(msg.sender, balance);
        return true;
    }

    function enterLotteryWithWinnings()
        external
        onlyWhenNotPaused
        returns (uint256)
    {
        uint256 balance = postLotteryBalances[msg.sender];

        if (balance <= 0) {
            revert InvalidAmount(balance);
        }

        postLotteryBalances[msg.sender] = 0;

        if (!nextLotteryContestantExists[msg.sender]) {
            indexOfNextLotteryContestant[msg.sender] = nextLotteryContestants
                .length;
            nextLotteryContestants.push(msg.sender);
            nextLotteryBalances.push(0);
            nextLotteryContestantExists[msg.sender] = true;
        }
        uint256 index = indexOfNextLotteryContestant[msg.sender];
        nextLotteryBalances[index] += balance;
        nextLotteryTotalBalance += balance;

        // Interactions
        emit EnteredLottery(msg.sender, nextLotteryBalances[index]);

        return nextLotteryBalances[index];
    }

    function withdrawFees() external onlyOperator {
        uint256 amount = feeReserve;

        if (amount == 0) {
            return;
        }

        feeReserve = 0;
        magicToken.transfer(msg.sender, amount);
        emit FeesWithdrawn(msg.sender, amount);
    }

    function changeOperator(address _operator) external onlyOperator {
        if (_operator == address(0)) {
            revert InvalidOperator(_operator);
        }

        operator = _operator;

        emit OperatorChanged(_operator);
    }

    function setFee(uint256 _fee) external onlyOperator {
        if (_fee <= 0 || _fee > MAX_FEE) {
            revert InvalidFeeAmount(_fee);
        }

        fee = _fee;

        emit FeeChanged(_fee);
    }

    function setPaused(bool _paused) external onlyOperator {
        paused = _paused;

        emit PauseStatusChanged(_paused);
    }

    function canBeginNextLottery() external view returns (bool, bytes memory) {
        return (
            !paused &&
                lastLottery + MIN_TIME_ELAPSED <= block.timestamp &&
                nextLotteryContestants.length >= 2,
            abi.encodeWithSelector(this.beginNextLottery.selector)
        );
    }

    function canDrawWinner() external view returns (bool, bytes memory) {
        return (
            allLotteries.length > 0 &&
                allLotteries[0].startTime + 2 weeks <= block.timestamp,
            abi.encodeWithSelector(this.drawWinner.selector)
        );
    }

    /// Private Methods ///

    function _resetNextLottery() internal {
        for (uint256 i; i < nextLotteryContestants.length; i++) {
            delete indexOfNextLotteryContestant[nextLotteryContestants[i]];
            delete nextLotteryContestantExists[nextLotteryContestants[i]];
        }

        delete nextLotteryContestants;
        delete nextLotteryBalances;
        nextLotteryTotalBalance = 0;
        lastLottery = block.timestamp;
    }

    function _getWinner(uint256 _randomNum, Lottery memory _lottery)
        internal
        pure
        returns (address)
    {
        uint256 rand = _randomNum % _lottery.total;
        for (uint256 i; i < _lottery.contestants.length; i++) {
            uint256 val = _lottery.balances[i];
            if (rand < val) {
                return _lottery.contestants[i];
            }
            rand -= val;
        }
        // should never reach here
        return _lottery.contestants[_lottery.contestants.length - 1];
    }
}