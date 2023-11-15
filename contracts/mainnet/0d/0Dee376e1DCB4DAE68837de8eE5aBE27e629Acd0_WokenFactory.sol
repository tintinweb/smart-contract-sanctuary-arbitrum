pragma solidity 0.6.6;

import './WokenERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWokenFactory.sol';
import './interfaces/IWokenCallee.sol';
import './WokenFactory.sol';


contract WokenPair is WokenERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;
    WokenFactory public _WokenFactory;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
    uint32 public swapFee = 3; // uses 0.3% default
   
    

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Woken: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Woken: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, address _wokenFactory) external {
        require(msg.sender == factory, 'Woken: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        _WokenFactory= WokenFactory(_wokenFactory);
    }

    function setSwapFee(uint32 _swapFee) external {
        require(_swapFee >= 3, "Woken: lower then 3");
        require(msg.sender == factory, 'Woken: FORBIDDEN');
        require(_swapFee <= 10, 'Woken: FORBIDDEN_FEE');
        swapFee = _swapFee;
    }
    

    modifier tradingMustbeOpen() { 
        if (_WokenFactory.isTKEnabled(address(this)) == true) {
            require(_WokenFactory.isTradingOpen(address(this)) == true, 'blocktime is outside trading hours' );
        }  
        _;
    }
 
    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Woken: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IWokenFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock tradingMustbeOpen returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'Woken: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock tradingMustbeOpen returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Woken: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock tradingMustbeOpen {
        require(amount0Out > 0 || amount1Out > 0, 'Woken: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Woken: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'Woken: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IWokenCallee(to).wokenCall(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Woken: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint _swapFee = swapFee;
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(_swapFee));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(_swapFee));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'Woken: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

pragma solidity 0.6.6; 

import './WokenPair.sol';
import './Timekeeper.sol';

contract WokenFactory is Timekeeper {

    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(WokenPair).creationCode));
    address public feeTo;
    address public feeToSetter;
    address public dexAdmin;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    mapping(address => bool) public isTimekeeperEnabledLP;
    mapping(address => bool) public isTimekeeperEnabledLPProposal;
    mapping(address => address) public pairAdmin;
    mapping(address => address) public pairAdminDao;
    mapping(address => bool ) public moderators;
    mapping(address => address) public roleRequests;
    mapping(address => uint256) private timelock;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event TimekeeperEnable(address indexed pair);
    event TimekeeperEnableProposal(address indexed pair, bool enable);
    event DexAdminChanged(address oldAdmin, address newAdmin);
    event PairAdminChanged(address indexed oldPairAdmin, address indexed newPairAdmin);
    event TimekeeperProposal(address indexed pair);
    event TimekeeperChange(address indexed pair);
    event ForceOpenTimelock(address indexed pair, bool isOpen);
    event ForceOpen(address indexed pair);
    event ModeratorChanged(address moderator, bool isModerator);
    event RolePairAdminRequested(address indexed pair, address indexed pairAdminAddr);
    event RolePairAdminDaoRequested(address indexed pair, address indexed pairAdminDaoAddr);
    event RolePairAdminApproved(address indexed pair, address indexed newPairAdmin);
    event RolePairAdminDaoApproved(address indexed pair, address indexed newPairAdminDao);
    event SwapFeeChange(address indexed pair, uint32 newSwapFee, address indexed Pairadmin);


    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
        dexAdmin=msg.sender;
    }

    modifier isDexAdmin(){
        require(msg.sender==dexAdmin, "you are not the dex Admin");
        _;
    }

    modifier isPairAdmin(address _pair){
        require(pairAdmin[_pair]==msg.sender, "you are not the pair Admin");
        _;
    }

    modifier isPairAdminDao(address _pair){
        require (pairAdminDao[_pair]==msg.sender, "you are not the pair Admin DAO");
        _;
    }


    modifier isModerators(){
        require (moderators[msg.sender]==true, "you are not DAO Moderator");
        _;
    }

    modifier isDexOrModerators(){
        require (moderators[msg.sender]==true || dexAdmin==msg.sender, "you are not allowed to do so");
        _;
    }

    function isTradingOpen(address _pair) public view override returns (bool) {
          if  (isTKEnabled(_pair) == true){
            return Timekeeper.isTradingOpen(_pair);
        } else return true;
    }

    function getSwapFee(address _pair) public view returns (uint32) {
        return WokenPair(_pair).swapFee();
    }

    function isTKEnabled(address _addr) public view returns (bool){
        return isTimekeeperEnabledLP[_addr];
    }

    function getDaysOpenLP(address _addr) public view returns (uint8[7] memory){
        return TimekeeperPerLp[_addr].closedDays;
    }

    function getDaysOpenLPProposal(address _addr) public view returns (uint8[7] memory){
        return TimekeeperPerLpWaitingForApproval[_addr].closedDays;
    }

    function setDexAdmin(address _addr) public isDexAdmin{
        address temp = dexAdmin;
        dexAdmin = _addr;
        emit DexAdminChanged(temp, _addr);
    }
    
    function setPairAdmin(address _addr, address _pair) public isPairAdmin(_pair){
        address temp = pairAdmin[_pair];
        pairAdmin[_pair] = _addr;
        emit PairAdminChanged(temp, _addr);
    }

    function setPairAdminDao(address _addr, address _pair) public isPairAdminDao(_pair){
        address temp = pairAdminDao[_pair];
        pairAdminDao[_pair] = _addr;
        emit PairAdminChanged(temp, _addr);
    }

    function setModerator(address _addr, bool _moderator) public isDexAdmin{
        moderators[_addr] = _moderator;
        emit ModeratorChanged(_addr, _moderator);
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Woken: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Woken: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Woken: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(WokenPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        WokenPair(pair).initialize(token0, token1, address(this));
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        pairAdmin[pair]=tx.origin;
        TimekeeperPerLp[pair]= pairTimekeeper(0, 0, 23, 59, [0,0,0,0,0,1,1], 0, true);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setEnableProposal(address _pair, bool _enable) public isPairAdminDao(_pair)  {
        isTimekeeperEnabledLPProposal[_pair]=_enable;
        emit TimekeeperEnableProposal(_pair,_enable);
    }
 
   function setEnableDao(address _pair) public isDexOrModerators  {
        isTimekeeperEnabledLP[_pair]=isTimekeeperEnabledLPProposal[_pair];
        emit TimekeeperEnable(_pair);
    }


    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Woken: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Woken: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }


    function setTimeForPairDao(address _pair, uint8 openingHour, uint8 openingMinute, uint8 closingHour, uint8 closingMin, uint8[7] memory ClosedDays, int8 utcOffset, bool onlyDay) public isPairAdminDao(_pair)  {
        require (isTKEnabled(_pair), "You must Enable your Timekeeper to edit your Trading Hours");
        _setKeeperGlobal(_pair, openingHour, openingMinute , closingHour, closingMin, ClosedDays, utcOffset, onlyDay);
        emit TimekeeperProposal(_pair);
    } 
   
    // DAO : Dex Admin and Moderators approvals  
    function setTimekeeperFromProposal(address _pair) public isDexOrModerators{
        TimekeeperPerLp[_pair]=TimekeeperPerLpWaitingForApproval[_pair];
        delete TimekeeperPerLpWaitingForApproval[_pair];
        emit TimekeeperChange(_pair);
    }

    function refuseProposal(address _pair) public isDexOrModerators{
        delete TimekeeperPerLpWaitingForApproval[_pair];
        emit TimekeeperProposal(_pair);
    }

    // for Pair Admin 
    function setTimeForPair(address _pair, uint8 openingHour, uint8 openingMinute, uint8 closingHour, uint8 closingMin, uint8[7] memory ClosedDays, int8 utcOffset, bool onlyDay) public isPairAdmin(_pair)  {
        require (isTKEnabled(_pair), "You must Enable your Timekeeper to edit your Trading Hours");
        _setKeeperGlobal(_pair, openingHour, openingMinute , closingHour, closingMin, ClosedDays, utcOffset, onlyDay);
        TimekeeperPerLp[_pair]=TimekeeperPerLpWaitingForApproval[_pair];
        delete TimekeeperPerLpWaitingForApproval[_pair];
        emit TimekeeperChange(_pair);
        
    }
    function setEnable(address _pair, bool _enable) public isPairAdmin(_pair) {
        isTimekeeperEnabledLP[_pair] = _enable;
        emit TimekeeperEnable(_pair);
    }   
    

    // Role Request
     function requestPairAdminDao(address _pair) public isPairAdmin(_pair) {
        require(roleRequests[_pair] == address(0), "Role Request already done");
        roleRequests[_pair] = msg.sender; 
        emit RolePairAdminDaoRequested(_pair, msg.sender);
    }

    function requestPairAdmin(address _pair) public isPairAdminDao(_pair) {
        require(roleRequests[_pair] == address(0), "Role Request already done");
        roleRequests[_pair] = msg.sender; 
        emit RolePairAdminRequested(_pair, msg.sender);
    }

    function approvePairAdminDao(address _pair) public isDexAdmin {
        address requester = roleRequests[_pair];
        require(requester != address(0), "No pending request for this pair");
        require(pairAdmin[_pair] == requester, "Only the current PairAdmin can be approved as PairAdminDao");
    
        pairAdminDao[_pair] = requester; 
        pairAdmin[_pair] = address(0); 
        roleRequests[_pair] = address(0); 
        emit RolePairAdminDaoApproved(_pair, msg.sender);
    }

    function approvePairAdmin(address _pair) public isDexAdmin {
        address requester = roleRequests[_pair];
        require(requester != address(0), "No pending request for this pair");
        require(pairAdminDao[_pair] == requester, "Only the current PairAdminDao can be approved as PairAdmin");
    
        pairAdmin[_pair] = requester; 
        pairAdminDao[_pair] = address(0); 
        roleRequests[_pair] = address(0); 
        emit RolePairAdminApproved(_pair, msg.sender);
    }

    function refuseRole(address _pair) public isDexAdmin {
        delete roleRequests[_pair];
    }

    //setSwapFee
    function setSwapFee(address _pair, uint32 _swapFee) external isPairAdminDao(_pair) {
        WokenPair(_pair).setSwapFee(_swapFee);
        emit SwapFeeChange(_pair, _swapFee, msg.sender);
    }

    //security option for DexAdmin to avoid closed pair for lifetime
    function setForceOpenTimelock(address _pair, bool _enable) public isDexAdmin {
        require (isTKEnabled(_pair), "Timekeeper is Disabled, market is already open");
        timelock[_pair] = block.timestamp + 172800; // 48h timelock
        isForceOpenTimelock[_pair] = _enable;
        emit ForceOpenTimelock(_pair, _enable);
    }

    function setForceOpen(address _pair) public isDexAdmin {
        require(block.timestamp >= timelock[_pair], "Timelock not yet expired");
        isForceOpen[_pair] = isForceOpenTimelock[_pair];
        emit ForceOpen(_pair);
    }
}

pragma solidity 0.6.6;

interface IWokenCallee {
    function wokenCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity 0.6.6;

interface IWokenFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setSwapFee(address pair, uint32 swapFee) external;
}

pragma solidity 0.6.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity 0.6.6;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

pragma solidity 0.6.6;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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

pragma solidity 0.6.6;

// import './interfaces/IWokenERC20.sol';
import './libraries/SafeMath.sol';

contract WokenERC20  {
    using SafeMath for uint;

    string public constant name = 'Woken LP Token';
    string public constant symbol = 'WLP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);


       constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'Woken: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Woken: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.6;

import "./BokkyPooBahsDateTimeLibrary.sol";

interface ITimekeeper {
    function isTradingOpen(address _pair) external view returns (bool);
}

contract Timekeeper is ITimekeeper {
    event Log(string str);

    int256 constant EARLY_OFFSET = 14;
    int256 constant LATE_OFFSET = -12;

    struct pairTimekeeper {
        uint8 openingHour;
        uint8 openingMinute;
        uint8 closingHour;
        uint8 closingMinute;
        uint8[7] closedDays; // if 1 : closed, if 0 : open
        int8 utcOffset;
        bool isOnlyDay;
    }
    mapping(address => pairTimekeeper) public TimekeeperPerLp;
    mapping(address => pairTimekeeper) public TimekeeperPerLpWaitingForApproval;

    mapping(address => bool) public isForceOpen;
    mapping(address => bool) public isForceOpenTimelock;

    constructor() public {}

    function isTradingOpen(
        address _pair
    ) public view virtual override returns (bool) {
        uint256 blockTime = block.timestamp;
        return isTradingOpenAt(blockTime, _pair);
    }

    function isTradingOpenAt(
        uint256 timestamp,
        address _pair
    ) public view returns (bool) {
        if (!isForceOpen[_pair]) {
            uint256 localTimeStamp = applyOffset(timestamp, _pair);

            uint day = BokkyPooBahsDateTimeLibrary.getDayOfWeek(localTimeStamp);

            if (TimekeeperPerLp[_pair].closedDays[day - 1] == 1) {
                return false;
            }

            uint256 now_hour;
            uint256 now_minute;

            if (!TimekeeperPerLp[_pair].isOnlyDay) {
                (, , , now_hour, now_minute, ) = BokkyPooBahsDateTimeLibrary
                    .timestampToDateTime(localTimeStamp);

                return isOpeningHour(now_hour, now_minute, _pair);
            } else return true;
        } else return true;
    }

    function applyOffset(
        uint256 timestamp,
        address _pair
    ) internal view returns (uint256) {
        uint256 localTimeStamp;
        if (TimekeeperPerLp[_pair].utcOffset >= 0) {
            localTimeStamp = BokkyPooBahsDateTimeLibrary.addHours(
                timestamp,
                uint256(TimekeeperPerLp[_pair].utcOffset)
            );
        } else {
            localTimeStamp = BokkyPooBahsDateTimeLibrary.subHours(
                timestamp,
                uint256(-TimekeeperPerLp[_pair].utcOffset)
            );
        }
        return localTimeStamp;
    }

    function isOpeningHour(
        uint256 hour,
        uint256 minute,
        address _pair
    ) internal view returns (bool) {
        uint256 openingHour = TimekeeperPerLp[_pair].openingHour;
        uint256 closingHour = TimekeeperPerLp[_pair].closingHour;
        uint256 openingMinute = TimekeeperPerLp[_pair].openingMinute;
        uint256 closingMinute = TimekeeperPerLp[_pair].closingMinute;

        if (
            openingHour < closingHour ||
            (openingHour == closingHour && openingMinute < closingMinute)
        ) {
            if (hour < openingHour || hour > closingHour) {
                return false;
            }
            if (hour == openingHour && minute < openingMinute) {
                return false;
            }
            if (hour == closingHour && minute >= closingMinute) {
                return false;
            }
        } else if (
            openingHour == closingHour && openingMinute == closingMinute
        ) {
            return false; // if both hours and minutes are same, then it's not open at any time
        } else {
            // this block handles the case when the business opens on one day and closes on the next
            // dont understand
            if (hour < openingHour && hour > closingHour) {
                return false;
            }
            if (hour == openingHour && minute < openingMinute) {
                return false;
            }
            if (hour == closingHour && minute >= closingMinute) {
                return false;
            }
        }

        return true;
    }

    function _setUTCOffset(int8 utcOffset, address _pair) internal {
        require(utcOffset < EARLY_OFFSET, "Invalid UCT offset");
        require(utcOffset > LATE_OFFSET, "Invalid UCT offset");
        TimekeeperPerLpWaitingForApproval[_pair].utcOffset = utcOffset;
    }

    function _setClosingDays(
        uint8[7] memory ClosedDays,
        address _pair
    ) internal {
        for (uint256 i = 0; i < ClosedDays.length; i++) {
            require(ClosedDays[i] == 0 || ClosedDays[i] == 1);
        }
        TimekeeperPerLpWaitingForApproval[_pair].closedDays = ClosedDays;
    }


    function _setHoursAndMinutes( uint8 openingHour,uint8 closingHour,uint8 openingMinute, uint8 closingMin, address _pair) internal {
        require(0 <= openingHour && openingHour <= 23, " invalid Opening hour");
        require(0 <= closingHour && closingHour <= 23, " invalid Closing hour");
        require(0 <= openingMinute && openingMinute <= 59," invalid Opening minutes");
        require(0 <= closingMin && closingMin <= 59," invalid Closing minutes");

        require(openingHour < closingHour || (openingHour == closingHour && openingMinute < closingMin)," invalid logic for time");

        TimekeeperPerLpWaitingForApproval[_pair].openingHour = openingHour;
        TimekeeperPerLpWaitingForApproval[_pair].closingHour = closingHour;

        TimekeeperPerLpWaitingForApproval[_pair].openingMinute = openingMinute;
        TimekeeperPerLpWaitingForApproval[_pair].closingMinute = closingMin;
    }

    function _setKeeperGlobal(
        address _pair,
        uint8 openingHour,
        uint8 openingMinute,
        uint8 closingHour,
        uint8 closingMin,
        uint8[7] memory ClosedDays,
        int8 utcOffset,
        bool onlyDay
    ) internal {
        delete TimekeeperPerLpWaitingForApproval[_pair];
        _setHoursAndMinutes(openingHour, closingHour, openingMinute, closingMin, _pair);
        _setClosingDays(ClosedDays, _pair);
        _setUTCOffset(utcOffset, _pair);
        _setIsOnlyDays(onlyDay, _pair);
    }


    function _setIsOnlyDays(bool isOnlyDay, address _pair) internal {
        TimekeeperPerLpWaitingForApproval[_pair].isOnlyDay = isOnlyDay;
    }
}

pragma solidity 0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}