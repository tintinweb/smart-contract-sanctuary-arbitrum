// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {IVester} from "./interfaces/IVester.sol";
import {ERC20Vote} from "./vendor/ERC20Vote.sol";
import {Util} from "./Util.sol";

interface ITokenStakingPlugin {
    function onAllocate(address who, uint256 amount) external;
    function onDeallocate(address who, uint256 amount) external;
}

contract TokenStaking is Util {
    error NotWhitelisted();
    error NotEnoughAllocatedTokens();
    error NotEnoughUnallocatedTokens();
    error BurnTimeTooShort();

    struct Checkpoint {
        uint32 fromTimestamp;
        uint96 votes;
    }
    struct Plugin {
        uint256 amount;
        address target;
        uint256 deallocationFee;
        address deallocationTarget;
    }

    string public constant name = "Staked Rodeo";
    string public constant symbol = "xRDO";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public allocated;
    mapping(address => mapping(uint256 => uint256)) public allocations;
    mapping(address => address) internal _delegates;
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;
    mapping(address => uint256) public numCheckpoints;
    mapping(address => bool) public whitelist;
    IERC20 public token;
    IVester public vester;
    uint256 public vestingTimeMin = 15 days;
    uint256 public vestingTimeMax = 180 days;
    uint256 public vestingFee = 0.5e18;
    address public vestingFeeTarget;
    mapping(uint256 => Plugin) public plugins;

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event SetPlugin(uint256 indexed index, address plugin, uint256 deallocationFee, address deallocationTarget);
    event Mint(address indexed recipient, uint256 amount);
    event Burn(address indexed recipient, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
    event Allocated(address indexed who, uint256 indexed index, uint256 amount);
    event Deallocated(address indexed who, uint256 indexed index, uint256 amount, uint256 fee);

    constructor(address _token, address _vester) {
        token = IERC20(_token);
        vester = IVester(_vester);
        exec[msg.sender] = true;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "paused") paused = data == 1;
        if (what == "vestingTimeMin") vestingTimeMin = data;
        if (what == "vestingTimeMax") vestingTimeMax = data;
        if (what == "vestingFee") vestingFee = data;
        emit File(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        if (what == "token") token = IERC20(data);
        if (what == "vester") vester = IVester(data);
        if (what == "whitelist") whitelist[data] = !whitelist[data];
        if (what == "vestingFeeTarget") vestingFeeTarget = data;
        emit File(what, data);
    }

    function setPlugin(uint256 index, address target, uint256 deallocationFee, address deallocationTarget) external auth {
        Plugin storage plugin = plugins[index];
        plugin.target = target;
        plugin.deallocationFee = deallocationFee;
        plugin.deallocationTarget = deallocationTarget;
        emit SetPlugin(index, target, deallocationFee, deallocationTarget);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        if (!whitelist[msg.sender]) revert NotWhitelisted();
        balanceOf[msg.sender] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }
        _moveDelegates(delegates(msg.sender), delegates(to), amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (!whitelist[msg.sender]) revert NotWhitelisted();
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }
        _moveDelegates(delegates(from), delegates(to), amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function delegates(address delegator) public view returns (address delegatee) {
        address current = _delegates[delegator];
        delegatee = current == address(0) ? delegator : current;
    }

    function getCurrentVotes(address account) public view returns (uint256 votes) {
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account];
            votes = nCheckpoints != 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        }
    }

    function delegate(address delegatee) public {
        address currentDelegate = delegates(msg.sender);
        _delegates[msg.sender] = delegatee;
        _moveDelegates(currentDelegate, delegatee, balanceOf[msg.sender]);
        emit DelegateChanged(msg.sender, currentDelegate, delegatee);
    }

    function getPriorVotes(address account, uint256 timestamp) public view returns (uint96 votes) {
        require(block.timestamp > timestamp, "NOT_YET_DETERMINED");
        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) return 0;
        unchecked {
            if (checkpoints[account][nCheckpoints - 1].fromTimestamp <= timestamp) {
                return checkpoints[account][nCheckpoints - 1].votes;
            }
            if (checkpoints[account][0].fromTimestamp > timestamp) return 0;
            uint256 lower;
            uint256 upper = nCheckpoints - 1;
            while (upper > lower) {
                uint256 center = upper - (upper - lower) / 2;
                Checkpoint memory cp = checkpoints[account][center];
                if (cp.fromTimestamp == timestamp) {
                    return cp.votes;
                } else if (cp.fromTimestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }
            return checkpoints[account][lower].votes;
        }
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount != 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum != 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld - amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum != 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint256 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        unchecked {
            if (nCheckpoints != 0 && checkpoints[delegatee][nCheckpoints - 1].fromTimestamp == block.timestamp) {
                checkpoints[delegatee][nCheckpoints - 1].votes = safeCastTo96(newVotes);
            } else {
                checkpoints[delegatee][nCheckpoints] = Checkpoint(safeCastTo32(block.timestamp), safeCastTo96(newVotes));
                numCheckpoints[delegatee] = nCheckpoints + 1;
            }
        }
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function mint(uint256 amount) external live loop {
        token.transferFrom(msg.sender, address(this), amount);
        totalSupply += amount;
        unchecked {
            balanceOf[msg.sender] += amount;
        }
        _moveDelegates(address(0), delegates(msg.sender), amount);
        emit Transfer(address(0), msg.sender, amount);
        emit Mint(msg.sender, amount);
    }

    function burn(uint256 amount, uint256 time) external live loop {
        uint256 available = balanceOf[msg.sender] - allocated[msg.sender];
        if (available < amount) revert NotEnoughUnallocatedTokens();
        _burn(msg.sender, amount);
        // TODO, shorter for private participants
        if (time < vestingTimeMin) revert BurnTimeTooShort();
        if (time > vestingTimeMax) time = vestingTimeMax;
        uint256 size = vestingTimeMax - vestingTimeMin;
        uint256 rate = vestingFee * (size - (time - vestingTimeMin)) / size;
        uint256 fee = amount * rate / 1e18;
        token.transfer(vestingFeeTarget, fee);
        token.approve(address(vester), amount - fee);
        vester.vest(1, msg.sender, address(token), amount - fee, 0, 0, time);
        emit Burn(msg.sender, amount);
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;
        unchecked {
            totalSupply -= amount;
        }
        _moveDelegates(delegates(from), address(0), amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function allocate(uint256 index, uint256 amount) public live loop {
        uint256 available = balanceOf[msg.sender] - allocated[msg.sender];
        if (available < amount) revert NotEnoughUnallocatedTokens();
        allocated[msg.sender] += amount;
        allocations[msg.sender][index] += amount;

        Plugin storage plugin = plugins[index];
        plugin.amount += amount;
        if (plugin.target != address(0)) {
            ITokenStakingPlugin(plugin.target).onAllocate(msg.sender, amount);
        }

        emit Allocated(msg.sender, index, amount);
    }

    function deallocate(uint256 index, uint256 amount) public live loop {
        uint256 available = allocations[msg.sender][index];
        if (available < amount) revert NotEnoughAllocatedTokens();
        allocated[msg.sender] -= amount;
        allocations[msg.sender][index] -= amount;

        Plugin storage plugin = plugins[index];
        plugin.amount -= amount;
        uint256 fee;
        if (plugin.target != address(0)) {
            ITokenStakingPlugin(plugin.target).onDeallocate(msg.sender, amount);
            fee = amount * plugin.deallocationFee / 1e18;
            if (fee > 0) {
                _burn(msg.sender, fee);
                token.transfer(plugin.deallocationTarget, fee);
            }
        }

        emit Deallocated(msg.sender, index, amount, fee);
    }

    function getUser(address user, uint256 indexes) public view returns (uint256, uint256, uint256[] memory) {
        uint256[] memory amounts = new uint256[](indexes);
        for (uint256 i = 0; i < indexes; i++) {
            amounts[i] = allocations[user][i];
        }
        return (balanceOf[user], allocated[user], amounts);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x <= type(uint32).max);
        y = uint32(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x <= type(uint96).max);
        y = uint96(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVester {
    function vest(uint256 source, address target, address token, uint256 amount, uint256 initial, uint256 cliff, uint256 time)
        external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/// @notice Modern and gas-optimized ERC20 + EIP-2612 implementation with COMP-style governance.
abstract contract ERC20Vote {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

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
                            DAO STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) internal _delegates;

    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    mapping(address => uint256) public numCheckpoints;

    struct Checkpoint {
        uint32 fromTimestamp;
        uint96 votes;
    }

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

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
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

        // this is safe from overflow because the sum of all user
        // balances can't exceed 'type(uint256).max'
        unchecked {
            balanceOf[to] += amount;
        }

        _moveDelegates(delegates(msg.sender), delegates(to), amount);

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;

        // this is safe from overflow because the sum of all user
        // balances can't exceed 'type(uint256).max'
        unchecked {
            balanceOf[to] += amount;
        }

        _moveDelegates(delegates(from), delegates(to), amount);

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                            DAO LOGIC
    //////////////////////////////////////////////////////////////*/

    function delegates(address delegator) public view virtual returns (address delegatee) {
        address current = _delegates[delegator];

        delegatee = current == address(0) ? delegator : current;
    }

    function getCurrentVotes(address account) public view virtual returns (uint256 votes) {
        // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account];

            votes = nCheckpoints != 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        }
    }

    function delegate(address delegatee) public virtual {
        _delegate(msg.sender, delegatee);
    }

    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s)
        public
        virtual
    {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));

        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "ZERO_ADDRESS");

        // this is reasonably safe from overflow because incrementing `nonces` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits
        unchecked {
            require(nonce == nonces[signatory]++, "INVALID_NONCE");
        }

        require(block.timestamp <= expiry, "SIGNATURE_EXPIRED");

        _delegate(signatory, delegatee);
    }

    function getPriorVotes(address account, uint256 timestamp) public view virtual returns (uint96 votes) {
        require(block.timestamp > timestamp, "NOT_YET_DETERMINED");

        uint256 nCheckpoints = numCheckpoints[account];

        if (nCheckpoints == 0) return 0;

        // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
        unchecked {
            if (checkpoints[account][nCheckpoints - 1].fromTimestamp <= timestamp) {
                return checkpoints[account][nCheckpoints - 1].votes;
            }

            if (checkpoints[account][0].fromTimestamp > timestamp) return 0;

            uint256 lower;

            // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
            uint256 upper = nCheckpoints - 1;

            while (upper > lower) {
                // this is safe from underflow because `upper` ceiling is provided
                uint256 center = upper - (upper - lower) / 2;

                Checkpoint memory cp = checkpoints[account][center];

                if (cp.fromTimestamp == timestamp) {
                    return cp.votes;
                } else if (cp.fromTimestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }

            return checkpoints[account][lower].votes;
        }
    }

    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = _delegates[delegator];

        _delegates[delegator] = delegatee;

        _moveDelegates(currentDelegate, delegatee, balanceOf[delegator]);

        emit DelegateChanged(delegator, currentDelegate, delegatee);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal virtual {
        if (srcRep != dstRep && amount != 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];

                uint256 srcRepOld = srcRepNum != 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;

                uint256 srcRepNew = srcRepOld - amount;

                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
        }

        if (dstRep != address(0)) {
            uint256 dstRepNum = numCheckpoints[dstRep];

            uint256 dstRepOld = dstRepNum != 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;

            uint256 dstRepNew = dstRepOld + amount;

            _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
        }
    }

    function _writeCheckpoint(address delegatee, uint256 nCheckpoints, uint256 oldVotes, uint256 newVotes)
        internal
        virtual
    {
        unchecked {
            // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
            if (nCheckpoints != 0 && checkpoints[delegatee][nCheckpoints - 1].fromTimestamp == block.timestamp) {
                checkpoints[delegatee][nCheckpoints - 1].votes = safeCastTo96(newVotes);
            } else {
                checkpoints[delegatee][nCheckpoints] = Checkpoint(safeCastTo32(block.timestamp), safeCastTo96(newVotes));

                // this is reasonably safe from overflow because incrementing `nCheckpoints` beyond
                // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits
                numCheckpoints[delegatee] = nCheckpoints + 1;
            }
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /*///////////////////////////////////////////////////////////////
                            EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
        virtual
    {
        require(block.timestamp <= deadline, "PERMIT_DEADLINE_EXPIRED");

        // this is reasonably safe from overflow because incrementing `nonces` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32 domainSeparator) {
        domainSeparator = block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32 domainSeparator) {
        domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /*///////////////////////////////////////////////////////////////
                            MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // this is safe because the sum of all user
        // balances can't exceed 'type(uint256).max'
        unchecked {
            balanceOf[to] += amount;
        }

        _moveDelegates(address(0), delegates(to), amount);

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // this is safe because a user won't ever
        // have a balance larger than `totalSupply`
        unchecked {
            totalSupply -= amount;
        }

        _moveDelegates(delegates(from), address(0), amount);

        emit Transfer(from, address(0), amount);
    }

    /*///////////////////////////////////////////////////////////////
                            SAFECAST LOGIC
    //////////////////////////////////////////////////////////////*/

    function safeCastTo32(uint256 x) internal pure virtual returns (uint32 y) {
        require(x <= type(uint32).max);

        y = uint32(x);
    }

    function safeCastTo96(uint256 x) internal pure virtual returns (uint96 y) {
        require(x <= type(uint96).max);

        y = uint96(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";

contract Util {
    error Paused();
    error NoReentering();
    error Unauthorized();
    error TransferFailed();

    bool internal entered;
    bool public paused;
    mapping(address => bool) public exec;

    modifier loop() {
        if (entered) revert NoReentering();
        entered = true;
        _;
        entered = false;
    }

    modifier live() {
        if (paused) revert Paused();
        _;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    // from OZ SignedMath
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            return uint256(n >= 0 ? n : -n);
        }
    }

    // from OZ Math
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 result = 1 << (log2(a) >> 1);
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) result += 1;
        }
        return result;
    }

    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 1e18;
        if (x == 0) return 0;
        require(x >> 255 == 0, "xoob");
        int256 x_int256 = int256(x);
        require(y < uint256(2 ** 254) / 1e20, "yoob");
        int256 y_int256 = int256(y);
        int256 logx_times_y = _ln(x_int256) * y_int256 / 1e18;
        require(-41e18 <= logx_times_y && logx_times_y <= 130e18, "poob");
        return uint256(_exp(logx_times_y));
    }

    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    function _ln(int256 a) private pure returns (int256) {
        if (a < 1e18) return -_ln((1e18 * 1e18) / a);
        int256 sum = 0;
        if (a >= a0 * 1e18) {
            a /= a0;
            sum += x0;
        }
        if (a >= a1 * 1e18) {
            a /= a1;
            sum += x1;
        }
        sum *= 100;
        a *= 100;
        if (a >= a2) {
            a = (a * 1e20) / a2;
            sum += x2;
        }
        if (a >= a3) {
            a = (a * 1e20) / a3;
            sum += x3;
        }
        if (a >= a4) {
            a = (a * 1e20) / a4;
            sum += x4;
        }
        if (a >= a5) {
            a = (a * 1e20) / a5;
            sum += x5;
        }
        if (a >= a6) {
            a = (a * 1e20) / a6;
            sum += x6;
        }
        if (a >= a7) {
            a = (a * 1e20) / a7;
            sum += x7;
        }
        if (a >= a8) {
            a = (a * 1e20) / a8;
            sum += x8;
        }
        if (a >= a9) {
            a = (a * 1e20) / a9;
            sum += x9;
        }
        if (a >= a10) {
            a = (a * 1e20) / a10;
            sum += x10;
        }
        if (a >= a11) {
            a = (a * 1e20) / a11;
            sum += x11;
        }
        int256 z = ((a - 1e20) * 1e20) / (a + 1e20);
        int256 z_squared = (z * z) / 1e20;
        int256 num = z;
        int256 seriesSum = num;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 3;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 5;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 7;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 9;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 11;
        seriesSum *= 2;
        return (sum + seriesSum) / 100;
    }

    function _exp(int256 x) internal pure returns (int256) {
        require(x >= -41e18 && x <= 130e18, "ie");
        if (x < 0) return ((1e18 * 1e18) / _exp(-x));
        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1;
        }
        x *= 100;
        int256 product = 1e20;
        if (x >= x2) {
            x -= x2;
            product = (product * a2) / 1e20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / 1e20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / 1e20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / 1e20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / 1e20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / 1e20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / 1e20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / 1e20;
        }
        int256 seriesSum = 1e20;
        int256 term;
        term = x;
        seriesSum += term;
        term = ((term * x) / 1e20) / 2;
        seriesSum += term;
        term = ((term * x) / 1e20) / 3;
        seriesSum += term;
        term = ((term * x) / 1e20) / 4;
        seriesSum += term;
        term = ((term * x) / 1e20) / 5;
        seriesSum += term;
        term = ((term * x) / 1e20) / 6;
        seriesSum += term;
        term = ((term * x) / 1e20) / 7;
        seriesSum += term;
        term = ((term * x) / 1e20) / 8;
        seriesSum += term;
        term = ((term * x) / 1e20) / 9;
        seriesSum += term;
        term = ((term * x) / 1e20) / 10;
        seriesSum += term;
        term = ((term * x) / 1e20) / 11;
        seriesSum += term;
        term = ((term * x) / 1e20) / 12;
        seriesSum += term;
        return (((product * seriesSum) / 1e20) * firstAN) / 100;
    }

    function pull(IERC20 asset, address usr, uint256 amt) internal {
        if (amt == 0) return;
        if (!asset.transferFrom(usr, address(this), amt)) revert TransferFailed();
    }

    function pullTo(IERC20 asset, address usr, address to, uint256 amt) internal {
        if (amt == 0) return;
        if (!asset.transferFrom(usr, to, amt)) revert TransferFailed();
    }

    function push(IERC20 asset, address usr, uint256 amt) internal {
        if (amt == 0) return;
        if (!asset.transfer(usr, amt)) revert TransferFailed();
    }

    function emergencyForTesting(address target, uint256 value, bytes calldata data) external auth {
        target.call{value: value}(data);
    }
}