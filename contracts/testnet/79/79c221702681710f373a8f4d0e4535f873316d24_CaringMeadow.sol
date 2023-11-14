/**
 *Submitted for verification at Arbiscan.io on 2023-11-13
*/

pragma solidity >=0.6.6;

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
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, 'ds-math-div-overflow');
        uint c = a / b;
        return c;
    }
}
library SafeMath256 {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}


interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function isSwap(address _address) external view returns (bool);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function burnToken(address token,uint256 amount,address dead) external;

    function initialize(address, address) external;
}


library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'd1b9ddf78c4a5a6446dbb4af5fb7d11d1708b742761692565b41c7852a6c2918'// init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}



library AmountCal {
    function receive_amounts(uint256 blocktimestamp,uint256 liquidity,uint256 receive_time,uint256 lp_num,uint256 lp_weight_total,uint256 lp_release,uint256 lp_num_0,uint256 lp_num_1000,uint256 lp_num_2000,uint256 lp_num_3000) internal pure returns (uint256 _amount){
        _amount = 0;
        uint256 _time_interval = blocktimestamp - receive_time;
        if(lp_num<1000) _amount = (lp_release /86400) * (liquidity * _time_interval) /lp_weight_total;
        else if(lp_num<2000) {
            if(receive_time<lp_num_0){
                _amount = (lp_release /86400) * liquidity * ( lp_num_0 - receive_time) /lp_weight_total;
                _amount += (lp_release *15/10 /86400) * (liquidity * (blocktimestamp - lp_num_0)) /lp_weight_total;
            }else{
                _amount = (lp_release *15/10 /86400) * (liquidity * _time_interval) /lp_weight_total;
            }
        }else if(lp_num<3000) {
            if(receive_time<lp_num_0){
                _amount = (lp_release /86400) * liquidity * ( lp_num_0 - receive_time) /lp_weight_total;
                _amount += (lp_release *15/10 /86400) * (liquidity * (lp_num_1000 - lp_num_0)) /lp_weight_total;
                _amount += (lp_release *2 /86400) * (liquidity * (blocktimestamp - lp_num_1000)) /lp_weight_total;
            }else if(receive_time<lp_num_1000){
                _amount = (lp_release *15/10/86400) * liquidity * ( lp_num_1000 - receive_time) /lp_weight_total;
                _amount += (lp_release *2 /86400) * (liquidity * (blocktimestamp - lp_num_1000)) /lp_weight_total;
            }else{
                _amount = (lp_release *2 /86400) * (liquidity * _time_interval) /lp_weight_total;
            }
        }else if(lp_num<4000){
            if(receive_time<lp_num_0){
                _amount = (lp_release /86400) * liquidity * ( lp_num_0 - receive_time) /lp_weight_total;
                _amount += (lp_release *15/10 /86400) * (liquidity * (lp_num_1000 - lp_num_0)) /lp_weight_total;
                _amount += (lp_release *2 /86400) * (liquidity * (lp_num_2000 - lp_num_1000)) /lp_weight_total;
                _amount += (lp_release *25/10 /86400) * (liquidity * (blocktimestamp - lp_num_2000)) /lp_weight_total;
            }else if(receive_time<lp_num_1000){
                _amount = (lp_release *15/10 /86400) * liquidity * ( lp_num_1000 - receive_time) /lp_weight_total;
                _amount += (lp_release *2 /86400) * (liquidity * (lp_num_2000 - lp_num_1000)) /lp_weight_total;
                _amount += (lp_release *25/10 /86400) * (liquidity * (blocktimestamp - lp_num_2000)) /lp_weight_total;
            }else if(receive_time<lp_num_2000){
                _amount = (lp_release *2/86400) * liquidity * ( lp_num_2000 - receive_time) /lp_weight_total;
                _amount += (lp_release *25/10 /86400) * (liquidity * (blocktimestamp - lp_num_2000)) /lp_weight_total;
            }else{
                _amount = (lp_release *25/10 /86400) * (liquidity * _time_interval) /lp_weight_total;
            }
        }else{
            if(receive_time<lp_num_0){
                _amount = (lp_release /86400) * liquidity * ( lp_num_0 - receive_time) /lp_weight_total;
                _amount += (lp_release *15/10 /86400) * (liquidity * (lp_num_1000 - lp_num_0)) /lp_weight_total;
                _amount += (lp_release *2 /86400) * (liquidity * (lp_num_2000 - lp_num_1000)) /lp_weight_total;
                _amount += (lp_release *25/10 /86400) * (liquidity * (lp_num_3000 - lp_num_2000)) /lp_weight_total;
                _amount += (lp_release *3 /86400) * (liquidity * (blocktimestamp - lp_num_3000)) /lp_weight_total;
            }else if(receive_time<lp_num_1000){
                _amount = (lp_release *15/10 /86400) * liquidity * ( lp_num_1000 - receive_time) /lp_weight_total;
                _amount += (lp_release *2 /86400) * (liquidity * (lp_num_2000 - lp_num_1000)) /lp_weight_total;
                _amount += (lp_release *25/10 /86400) * (liquidity * (lp_num_3000 - lp_num_2000)) /lp_weight_total;
                _amount += (lp_release *3 /86400) * (liquidity * (blocktimestamp - lp_num_3000)) /lp_weight_total;
            }else if(receive_time<lp_num_2000){
                _amount = _amount + (lp_release *2 /86400) * (liquidity * (lp_num_2000 - receive_time)) /lp_weight_total;
                _amount += (lp_release *25/10 /86400) * (liquidity * (lp_num_3000 - lp_num_2000)) /lp_weight_total;
                _amount += (lp_release *3 /86400) * (liquidity * (blocktimestamp - lp_num_3000)) /lp_weight_total;
            }else if(receive_time<lp_num_3000){
                _amount = _amount + (lp_release *25/10 /86400) * (liquidity * (lp_num_3000 - receive_time)) /lp_weight_total;
                _amount += (lp_release *3 /86400) * (liquidity * (blocktimestamp - lp_num_3000)) /lp_weight_total;
            }else{
                _amount = (lp_release *3 /86400) * (liquidity * _time_interval) /lp_weight_total;
            }
        }
        return _amount;
    }

}


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
    function burn(uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function updateWeight(address spender, uint256 _amt,bool _isc,uint256 _usdt,bool _isu) external returns (uint256 _amts,uint256 _usdts);
    function weightOf(address addr) external returns (uint256 _amt,uint256 _usdt);
}

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function officalMint(address _addr) external returns (uint256);
    function balanceOf(address _owner) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns(address);
    function isApprovedForAll(address _owner, address _operator) external view returns(bool);
}

interface CaringMeadowVault {
    function addLPLiquidity(address _addr,uint256 _amount) external returns (uint256);
    function RemoveLPLiquidity(address _addr,uint256 _amount) external returns (uint256);
    function AddUsdt(address _addr,uint256 _amount) external returns (uint256);
    function RemoveUsdt(address _addr,uint256 _amount) external returns (uint256);
}


contract CaringMeadow is Context, Ownable{
    
    using SafeMath256 for uint256;
    mapping(address => bool) public devOwner;
    uint256 public lp_weight_total;
    uint256 public lp_release;
    uint256 public fee_total;
    uint256 public vault_total;
    uint256 public lp_total;
    address public pair;
    address public _factory = 0xde4dbA0e0a4F6E04b4F16f5f7B4b60A22c63Ab93;
    address public usdtToken = 0xB3Cd1a683D04898e70eC00f7EB7fe5955E3147db;
    address public amtToken = 0xbFc23aFE931fD2e1679D7C48a27d7f9a6d5c795a;
    address public Vault_addr = 0xC46Ca4f6D6903B3E93e346c50630F98d2631a230;
    uint256 public usdt_ds;
    address public origin;
    uint256 public min_lp;
    uint256 public static_min_lp;
    uint256 public dy_min_lp;
    uint256 public usdt_price;
    uint256 public token_price;
    uint    public lp_num;
    uint256 public lp_num_0;
    uint256 public lp_num_1000;
    uint256 public lp_num_2000;
    uint256 public lp_num_3000;
    address public dy_addr = 0x3375AE545f2A900f3F12fC10D20BE11731abFAF7;
    address public usdt_receive = 0xefc425c7EA4e0394A2F014BB9D23608f5849FF2c;
    bool    public work = true;
    uint    public hua = 2;
    uint    public profit = 40;
    uint    public destory_rate = 60;
    uint256 public amt_ds = 100000000;
    uint256 public time_interval = 30;
    address public des_to = 0xc8C834bd324e984Bf9e467Cee8bC54a2478e1f20;

    IPancakeFactory public Factory;
    mapping (address => address) public relation;
    mapping (uint256 => nftInfo) public nft; //nft基础信息
    mapping (uint256 => MinerRatio) public miner_ratio;
    mapping (address => uint256) public nft_index; //nft基础信息
    mapping (address => LPPool) public lp_pool; //lp权重
    mapping (address => mapping (uint256 => nftPledge)) public nft_pledge; //nft基础信息
    mapping (address => nftPledgeAddr) public nft_pledge_info;

    struct MinerRatio{
        uint256 recommend;
        uint256 lp_amount;
    }

    struct LPPool{
        uint256 receive_time;
        uint256 amt;
        uint256 usdt;
        uint256 liquidity;
        uint256 amt_amount; //动态
        uint256 receive_amount; //静态
    }

    struct nftInfo{
        uint256 pay_amount;
        uint256 amt_release;
        uint256 relese_time;
        uint256 lp_amount;
        uint256 receive_rate;
    }

    struct nftPledgeAddr{
        address nft_contract;
        uint256 nft_id;
        uint256 nft_miner_amt;
        uint256 miner_amt;
        uint256 recommend_amt;
    }

    struct nftPledge{
        uint256 total_profit;
        uint256 less_profit;
        bool    is_active;
        bool    is_miner;
        uint256 exp_time;
        uint256 miner_time;
        uint256 nft_index;
        bool    is_end;
    }

    event BindNFT(uint256 _usdt,uint256 _amt,uint256 _liquidity,address nft_contract,uint256 nft_id);
    event AddLiquidity(uint256 _usdt,uint256 _amt,uint256 _usdta,uint256 _amta,uint256 _liquidity);
    event RemoveLiquidity(uint256 _usdt,uint256 _amt,uint256 _liquidity);
    event Relation(address user,address _recommend_address);
    event ReceiveProfitNFT(address _addr,uint256 _amount,uint256 _time_interval,uint256 timestamp,address _nft_contract,uint256 _nft_id,uint256 reward_amount,uint256 usdt_amount,uint256 amt_amount);
    event ReceiveProfit(address _addr,uint256 _amount,uint256 _time_interval,uint256 timestamp,uint256 _lp_amount,uint256 _weight_total,uint256 _lp_release);
    event ReceiveProfitTeam(address _addr,uint256 _amount);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EX');
        _;
    }

    modifier workstatus() {
        require(work == true, 'P');
        _;
    }

    constructor() public {
        origin = msg.sender;
        Factory = IPancakeFactory(_factory);
        usdt_ds = 10 ** 18;
        lp_release = 1000*amt_ds;
        pair = PancakeLibrary.pairFor(_factory,usdtToken,amtToken);
        relation[msg.sender] = 0x000000000000000000000000000000000000dEaD;
        min_lp = 500*usdt_ds;
        static_min_lp = 50*usdt_ds;
        dy_min_lp = 100*usdt_ds;
        usdt_price = 2*usdt_ds;
        token_price = 10*amt_ds;

        miner_ratio[1].recommend = 300;
        miner_ratio[1].lp_amount = 100 * usdt_ds;

        miner_ratio[2].recommend = 200;
        miner_ratio[2].lp_amount = 500 * usdt_ds;

        miner_ratio[3].recommend = 100;
        miner_ratio[3].lp_amount = 500 * usdt_ds;

        miner_ratio[4].recommend = 200;
        miner_ratio[4].lp_amount = 500 * usdt_ds;

        miner_ratio[5].recommend = 300;
        miner_ratio[5].lp_amount = 500 * usdt_ds;

        miner_ratio[6].recommend = 100;
        miner_ratio[6].lp_amount = 1000 * usdt_ds;

        miner_ratio[7].recommend = 100;
        miner_ratio[7].lp_amount = 1000 * usdt_ds;

        miner_ratio[8].recommend = 100;
        miner_ratio[8].lp_amount = 1000 * usdt_ds;

        miner_ratio[9].recommend = 100;
        miner_ratio[9].lp_amount = 1000 * usdt_ds;

        miner_ratio[10].recommend = 100;
        miner_ratio[10].lp_amount = 1000 * usdt_ds;

        miner_ratio[11].recommend = 80;
        miner_ratio[11].lp_amount = 1500 * usdt_ds;

        miner_ratio[12].recommend = 80;
        miner_ratio[12].lp_amount = 1500 * usdt_ds;

        miner_ratio[13].recommend = 80;
        miner_ratio[13].lp_amount = 1500 * usdt_ds;

        miner_ratio[14].recommend = 80;
        miner_ratio[14].lp_amount = 1500 * usdt_ds;

        miner_ratio[15].recommend = 80;
        miner_ratio[15].lp_amount = 1500 * usdt_ds;

        nft[1].pay_amount = 1000 * usdt_ds;
        nft[1].amt_release = 3000 * amt_ds;
        nft[1].relese_time = 15709091;
        nft[1].lp_amount = 500 * usdt_ds;
        nft[1].receive_rate = 0;

        nft[2].pay_amount = 300 * usdt_ds;
        nft[2].amt_release = 800 * amt_ds;
        nft[2].relese_time = 13824000;
        nft[2].lp_amount = 100 * usdt_ds;
        nft[2].receive_rate = 0;

        nft[3].pay_amount = 60 * usdt_ds;
        nft[3].amt_release = 200 * amt_ds;
        nft[3].relese_time = 17280000;
        nft[3].lp_amount = 100 * usdt_ds;
        nft[3].receive_rate = 0;

        nft_index[0xca480985470382eA4D487Dd6327113a30d7E9859] = 1;
        nft_index[0x0895b0A7874FF37015b636325d9204C10Fe92BcB] = 2;
        nft_index[0x0e907E84e4Cce5300DeE4084c7c7685D002ccC6f] = 3;

        devOwner[msg.sender]=true;
    }
    
    modifier onlyDev() {
        require(devOwner[msg.sender]==true,'ND');
        _;
    }

    function takeOwnership(address _addr,bool _Is) public onlyOwner {
        devOwner[_addr] = _Is;
    }

    function setInitPrice(uint256 _usdt_price,uint256 _token_price) public onlyOwner{
        usdt_price = _usdt_price;
        token_price = _token_price;
    }

    function setWork(bool _is) public onlyOwner{
        work = _is;
    }

    function setVaultAddr(address _addr) public onlyOwner {
        Vault_addr = _addr;
    }

    function commonData() public view returns (uint256 _fee_total,uint256 _vault_total,uint256 _lp_weight_total,uint256 _lp_release,uint256 _time_interval,uint256 _lp_num,uint256 _lp_num_0,uint256 _lp_num_1000,uint256 _lp_num_2000,uint256 _lp_num_3000){
        _fee_total = fee_total;
        _vault_total = vault_total;
        _lp_weight_total = lp_weight_total;
        _lp_release = lp_release;
        _time_interval = time_interval;
        _lp_num = lp_num;
        _lp_num_0 = lp_num_0;
        _lp_num_1000 = lp_num_1000;
        _lp_num_2000 = lp_num_2000;
        _lp_num_3000 = lp_num_3000;
    }

    function setlpReleaseDev(uint256 _amount) public onlyDev {
        lp_release = _amount;
    }

    function setlpNumDev(uint256 lp_nums) public onlyDev {
        lp_num = lp_nums;
        time();
    }

    function setHua(uint256 _hua) public onlyDev {
        hua = _hua;
    }

    function setProfit(uint256 _profit) public onlyDev {
        profit = _profit;
    }

    function setDead(uint _dead_rate) public onlyDev {
        destory_rate = _dead_rate;
    }

    function setAddr(address _dead,address _to,address _usdt) public onlyDev {
        dy_addr = _dead;
        usdt_receive = _usdt;
        des_to = _to;
    }

    function setRelationDev(address[] memory _addr,address[] memory _pre) public onlyDev {
        require(_addr.length == _pre.length);
        for (uint256 i = 0; i < _addr.length; i++){
            setRelationPri(_addr[i],_pre[i]);
        }
    }

    function setNftPle(address _nft_contract,uint256 _nftId,uint256 _i,uint256 ra,uint256 ts,uint256 mt,bool end) public onlyDev {
        nft_pledge[_nft_contract][_nftId].total_profit = nft[_i].amt_release;
        nft_pledge[_nft_contract][_nftId].less_profit = ra;
        nft_pledge[_nft_contract][_nftId].is_active = true;
        nft_pledge[_nft_contract][_nftId].is_miner = false;
        nft_pledge[_nft_contract][_nftId].exp_time = ts;
        nft_pledge[_nft_contract][_nftId].miner_time = mt;
        nft_pledge[_nft_contract][_nftId].nft_index = _i;
        nft_pledge[_nft_contract][_nftId].is_end = end;
    }

    function setNftPleInfo(address addr,address _nft_contract,uint256 _nftId,uint256 _nmr,uint256 _mr,uint256 _rr) public onlyDev {
        nft_pledge_info[addr].nft_contract = _nft_contract;
        nft_pledge_info[addr].nft_id = _nftId;
        nft_pledge_info[addr].nft_miner_amt = _nmr;
        nft_pledge_info[addr].miner_amt = _mr;
        nft_pledge_info[addr].recommend_amt = _rr;
    }

    function setPool(address _addr,uint256 ra,uint256 rma,uint256 ts) public onlyDev {
        lp_pool[_addr].liquidity = IPancakePair(pair).balanceOf(_addr);
        lp_weight_total = IPancakePair(pair).totalSupply();
        (uint256 reserve0,uint256 reserve1) = PancakeLibrary.getReserves(_factory,usdtToken,amtToken);
        lp_pool[_addr].usdt = reserve0*lp_pool[_addr].liquidity/lp_weight_total;
        lp_pool[_addr].amt = reserve1*lp_pool[_addr].liquidity/lp_weight_total;
        lp_pool[_addr].receive_time = ts;
        lp_pool[_addr].receive_amount = ra;
        lp_pool[_addr].amt_amount = rma;
    }


    function setRelationPri(address _addr,address _pre) private  {
        require(relation[_addr] == address(0) , "RE");
        if(_addr==origin){
            relation[_addr] = _pre;
        }else{
            require(relation[_pre] != address(0) , "RNE");
            relation[_addr] = _pre;
        }
        emit Relation(_addr,_pre);
    }

    function setRelation(address _addr) public {
        require(relation[msg.sender] == address(0) , "RE");
        if(_addr==origin){
            relation[msg.sender] = _addr;
        }else{
            require(relation[_addr] != address(0) , "RNE");
            relation[msg.sender] = _addr;
        }
        emit Relation(msg.sender,_addr);
    }

    function activeNft(address _nft_contract,uint256 _nftId) public workstatus {
        address _nftowner = IERC721(_nft_contract).ownerOf(_nftId);
        require(_nftowner==msg.sender,'NO');
        require(nft_pledge[_nft_contract][_nftId].is_active==false,'AA');
        uint256 _index = nft_index[_nft_contract];
        uint256 release_amount = 0;
        if(nft[_index].receive_rate>0){
            release_amount = nft[_index].amt_release * nft[_index].receive_rate/100;
        }
        nft_pledge[_nft_contract][_nftId].is_active = true;
        nft_pledge[_nft_contract][_nftId].nft_index = _index;
        nft_pledge[_nft_contract][_nftId].total_profit = nft[_index].amt_release;
        nft_pledge[_nft_contract][_nftId].less_profit = nft[_index].amt_release - release_amount;
        nft_pledge[_nft_contract][_nftId].exp_time = block.timestamp + 3*86400;
    }

    function getReserves() public view returns (uint256 _amountA,uint256 _amountB) {
        (_amountA, _amountB) = PancakeLibrary.getReserves(_factory,usdtToken,amtToken);
    }

    function bindNFT(uint256 usdt_amount,uint256 amt_amount,uint256 minusdt_amount,uint256 minamt_amount,uint256 _nftId,address _nft_contract) public workstatus{
        require(usdt_amount>=usdt_ds, "U10");
        require(nft_pledge[_nft_contract][_nftId].is_active==true,'NA');
        address _nftowner = IERC721(_nft_contract).ownerOf(_nftId);
        require(_nftowner==msg.sender,'NO');
        require(nft_pledge_info[msg.sender].nft_contract==address(0),'AB');
        uint256 _fee =  usdt_amount*hua/100;
        IERC20(usdtToken).transferFrom(msg.sender, Vault_addr, _fee); 
        fee_total = fee_total + _fee;
        // lp_total = lp_total + _fee;
        usdt_amount = usdt_amount - _fee;
        amt_amount = amt_amount*(100-hua)/100;
        minusdt_amount = minusdt_amount*(100-hua)/100;
        minamt_amount = minamt_amount*(100-hua)/100;
        // require(nft_pledge[_nft_contract][_nftId].miner_time==0,'already miner');
        if(nft_pledge_info[msg.sender].nft_contract==address(0)){
            nft_pledge_info[msg.sender].nft_contract = _nft_contract;
            nft_pledge_info[msg.sender].nft_id = _nftId;
        }else{
            _nftowner = IERC721(nft_pledge_info[msg.sender].nft_contract).ownerOf(nft_pledge_info[msg.sender].nft_id);
            //是否转账给其他人
            if(_nftowner!=msg.sender){
                nft_pledge_info[msg.sender].nft_contract = _nft_contract;
                nft_pledge_info[msg.sender].nft_id = _nftId;
            }else{
                // 已经领取完毕
                if(!(nft_pledge_info[msg.sender].nft_contract==_nft_contract&&nft_pledge_info[msg.sender].nft_id==_nftId)){
                    if(nft_pledge[nft_pledge_info[msg.sender].nft_contract][nft_pledge_info[msg.sender].nft_id].less_profit ==0){
                        nft_pledge_info[msg.sender].nft_contract = _nft_contract;
                        nft_pledge_info[msg.sender].nft_id = _nftId;
                    }else{
                        revert('AB');
                    }
                }
            }
        }
        require(block.timestamp<=nft_pledge[_nft_contract][_nftId].exp_time, "ETP");

        uint256 _index = nft_index[_nft_contract];

        (uint256 amountA, uint256 amountB, uint256 liquidity) = _AddLPLiquidity(usdtToken,amtToken,usdt_amount,amt_amount,minusdt_amount,minamt_amount,msg.sender,block.timestamp);
        if(usdt_amount>amountA){
            usdt_amount = amountA;
        }
        if(amt_amount>amountB){
            amt_amount = amountB;
        }
        if(lp_pool[msg.sender].liquidity==0) {
            lp_num++;
            time();

        }
        lp_pool[msg.sender].liquidity = IPancakePair(pair).balanceOf(msg.sender);
        lp_weight_total = IPancakePair(pair).totalSupply();

        (uint256 reserve0,uint256 reserve1) = PancakeLibrary.getReserves(_factory,usdtToken,amtToken);
        
        lp_pool[msg.sender].usdt = reserve0*lp_pool[msg.sender].liquidity/lp_weight_total;
        lp_pool[msg.sender].amt = reserve1*lp_pool[msg.sender].liquidity/lp_weight_total;
        
        if(lp_pool[msg.sender].usdt >=static_min_lp && lp_pool[msg.sender].receive_time==0){
            lp_pool[msg.sender].receive_time = block.timestamp;
        }

        if(lp_pool[msg.sender].receive_time != block.timestamp && lp_pool[msg.sender].receive_time!=0){
            lp_pool[msg.sender].receive_amount += AmountCal.receive_amounts(block.timestamp,lp_pool[msg.sender].liquidity,lp_pool[msg.sender].receive_time,lp_num, lp_weight_total, lp_release, lp_num_0, lp_num_1000, lp_num_2000, lp_num_3000);
            lp_pool[msg.sender].receive_time = block.timestamp;
        }

        if(lp_pool[msg.sender].usdt>=nft[_index].lp_amount&&nft_pledge[_nft_contract][_nftId].miner_time==0&&nft_pledge[_nft_contract][_nftId].is_end==false){
            nft_pledge[_nft_contract][_nftId].miner_time = block.timestamp;
        }
        if(nft[_index].pay_amount>60000000000000000000){
            CaringMeadowVault(Vault_addr).AddUsdt(msg.sender,nft[_index].pay_amount);
        }
        CaringMeadowVault(Vault_addr).addLPLiquidity(msg.sender,liquidity);
        emit BindNFT(usdt_amount,amt_amount,liquidity,_nft_contract,_nftId);
    }

    function time() private{
      if(lp_num>=1000&&lp_num_0==0){
          lp_num_0 = block.timestamp;
      }else if(lp_num>=2000&&lp_num_1000==0){
          lp_num_1000 = block.timestamp;
      }else if (lp_num>=3000&&lp_num_2000==0){
          lp_num_2000 = block.timestamp;
      }else if (lp_num>=4000&&lp_num_3000==0){
          lp_num_3000 = block.timestamp;
      }
    }

    function addLPLiquidity(uint256 usdt_amount,uint256 amt_amount,uint256 minusdt_amount,uint256 minamt_amount) public workstatus{
        require(usdt_amount>=usdt_ds, "U1");
        uint256 _fee =  usdt_amount*hua/100;
        IERC20(usdtToken).transferFrom(msg.sender, Vault_addr, _fee); 
        fee_total = fee_total + _fee;
        // lp_total = lp_total + _fee;
        usdt_amount = usdt_amount - _fee;
        amt_amount = amt_amount*(100-hua)/100;
        minusdt_amount = minusdt_amount*(100-hua)/100;
        minamt_amount = minamt_amount*(100-hua)/100;

        (uint256 amountA, uint256 amountB, uint256 liquidity) = _AddLPLiquidity(usdtToken,amtToken,usdt_amount,amt_amount,minusdt_amount,minamt_amount,msg.sender,block.timestamp);
        if(usdt_amount>amountA){
            usdt_amount = amountA;
        }
        if(amt_amount>amountB){
            amt_amount = amountB;
        }
        if(lp_pool[msg.sender].liquidity==0) {
            lp_num++;
            time();
        }
        lp_pool[msg.sender].liquidity = IPancakePair(pair).balanceOf(msg.sender);
        lp_weight_total = IPancakePair(pair).totalSupply();
        (uint256 reserve0,uint256 reserve1) = PancakeLibrary.getReserves(_factory,usdtToken,amtToken);
        lp_pool[msg.sender].usdt = reserve0*lp_pool[msg.sender].liquidity/lp_weight_total;
        lp_pool[msg.sender].amt = reserve1*lp_pool[msg.sender].liquidity/lp_weight_total;

        if(lp_pool[msg.sender].usdt >= static_min_lp && lp_pool[msg.sender].receive_time==0){
            lp_pool[msg.sender].receive_time = block.timestamp;
        }
        
        if(lp_pool[msg.sender].receive_time != block.timestamp && lp_pool[msg.sender].receive_time!=0){
            lp_pool[msg.sender].receive_amount += AmountCal.receive_amounts(block.timestamp,lp_pool[msg.sender].liquidity,lp_pool[msg.sender].receive_time,lp_num, lp_weight_total, lp_release, lp_num_0, lp_num_1000, lp_num_2000, lp_num_3000);
            lp_pool[msg.sender].receive_time = block.timestamp;
        }

        if(nft_pledge_info[msg.sender].nft_contract!=address(0)){
            address _nft_contract = nft_pledge_info[msg.sender].nft_contract;
            uint256 _nft_id = nft_pledge_info[msg.sender].nft_id;
            uint256 _index = nft_index[nft_pledge_info[msg.sender].nft_contract];
            if(lp_pool[msg.sender].usdt>nft[_index].lp_amount&&nft_pledge[_nft_contract][_nft_id].miner_time==0&&nft_pledge[_nft_contract][_nft_id].is_end==false){
                nft_pledge[_nft_contract][_nft_id].miner_time = block.timestamp;
            }
        }

        CaringMeadowVault(Vault_addr).addLPLiquidity(msg.sender,liquidity);
        emit AddLiquidity(usdt_amount,amt_amount,amountA,amountB,liquidity);
    }

    function removeLPLiquidity(uint256 usdt_amount,uint256 amt_amount,uint256 liquidity) public workstatus{
        IPancakePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IPancakePair(pair).burn(msg.sender);
        (address token0,) = PancakeLibrary.sortTokens(usdtToken, amtToken);
        (uint256 amountA,uint256 amountB) = usdtToken == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= usdt_amount, 'IAA');
        require(amountB >= amt_amount, 'IBA');
        // (uint256 amountA, uint256 amountB) = Router.removeLiquidity(usdtToken,amtToken,liquidity,usdt_amount,amt_amount,msg.sender,block.timestamp);
        uint256 _fee =  amountA*hua/100;
        fee_total = fee_total + _fee;
        // lp_total = lp_total + _fee;
        IERC20(usdtToken).transferFrom(msg.sender, Vault_addr, _fee);
        usdt_amount = amountA;
        amt_amount = amountB;
        lp_pool[msg.sender].liquidity = IPancakePair(pair).balanceOf(msg.sender);
        lp_weight_total = IPancakePair(pair).totalSupply();

        (uint256 reserve0,uint256 reserve1) = PancakeLibrary.getReserves(_factory,usdtToken,amtToken);

        lp_pool[msg.sender].usdt = reserve0*lp_pool[msg.sender].liquidity/lp_weight_total;
        lp_pool[msg.sender].amt = reserve1*lp_pool[msg.sender].liquidity/lp_weight_total;

        if(lp_pool[msg.sender].usdt < static_min_lp ){
            lp_pool[msg.sender].receive_time = 0;
        }

        if(nft_pledge_info[msg.sender].nft_contract!=address(0)){
            address _nft_contract = nft_pledge_info[msg.sender].nft_contract;
            uint256 _nft_id = nft_pledge_info[msg.sender].nft_id;
            address _nftowner = IERC721(_nft_contract).ownerOf(_nft_id);
            if(_nftowner==msg.sender){
                uint256 _index = nft_index[_nft_contract];
                if(nft[_index].lp_amount>lp_pool[msg.sender].usdt){
                    nft_pledge[_nft_contract][_nft_id].miner_time = 0;
                    nft_pledge[_nft_contract][_nft_id].is_end = true;
                    if(nft[_index].pay_amount>60000000000000000000){
                        CaringMeadowVault(Vault_addr).RemoveUsdt(msg.sender,nft[_index].pay_amount);
                    }
                }
            }
        }

        CaringMeadowVault(Vault_addr).RemoveLPLiquidity(msg.sender,liquidity);
        emit RemoveLiquidity(usdt_amount,amt_amount,liquidity);
    }

    function swapAmount(uint amountIn,uint amountOutMin,address[] memory path,address to) private returns (uint256){
        IPancakePair _pair = IPancakePair(pair);
        require(_pair.isSwap(address(this)), 'P');
        IERC20(path[0]).transferFrom(msg.sender, pair, amountIn);
        uint balanceBefore = IERC20(path[1]).balanceOf(to);
        (address input, address output) = (path[0], path[1]);
        (address token0,) = PancakeLibrary.sortTokens(input, output);
        uint amountInput;
        uint amountOutput;
        {
        (uint reserve0, uint reserve1,) = _pair.getReserves();
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(pair).sub(reserveInput);
        amountOutput = PancakeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
        _pair.swap(amount0Out, amount1Out, to, new bytes(0));
        require(
            IERC20(path[1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'IOA'
        );
        return amountOutput;
    }

    function _AddLPLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) private ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        if (Factory.getPair(tokenA, tokenB) == address(0)) {
            Factory.createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB,) = IPancakePair(pair).getReserves();
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = PancakeLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'IBA');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = PancakeLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'IAA');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
        IERC20(tokenA).transferFrom( msg.sender, pair, amountA);
        IERC20(tokenB).transferFrom( msg.sender, pair, amountB);
        liquidity = IPancakePair(pair).mint(to);
    }

    function burnToken(uint256 amount,address dead) private{
        require(IPancakePair(pair).isSwap(address(this)), 'P');
        IPancakePair(pair).burnToken(amtToken, amount,dead);
    }

    function swap(uint256 _amount,uint256 min_amount,bool _Is) public workstatus{
        require(_amount>0, "ANE");
        address[] memory path;
        path = new address[](2);
        bool _isc_b ;
        bool _isu_b ;
        uint256 _amt_w = 0;
        uint256 _usdt_w = 0;
        uint256 des_amount = _amount * destory_rate/100;
        uint256 _fee;
        if(_Is){
            (uint256 amt ,uint256 usdt) = IERC20(amtToken).weightOf(msg.sender);
            path[0] = amtToken;
            path[1] = usdtToken;
            uint256 _usdt = swapAmount(_amount,min_amount,path,address(this));
            uint256 usdt_fee = 0;
            uint256 _valut = 0;
            if(usdt>0&&amt>0){
                if(_amount>amt) usdt_fee = usdt;
                else usdt_fee = usdt * _amount / amt;
            }
            _fee = _usdt * hua/100;
            if(_usdt>usdt_fee){
                _valut = (_usdt - usdt_fee) * profit/100;
            }
            if(_amount>amt){
                _amt_w = amt;
            }else{
                _amt_w = _amount;
            }
            if(usdt_fee>usdt){
                _usdt_w = usdt;
            }else{
                _usdt_w = usdt_fee;
            }
            _isc_b = false;
            _isu_b = false;
            IERC20(usdtToken).transfer(Vault_addr,(_valut + _fee)); 
            IERC20(usdtToken).transfer(msg.sender,(_usdt - _valut - _fee)); 
            vault_total = vault_total + _valut;
            burnToken(des_amount,des_to);
        }else{
            path[0] = usdtToken;
            path[1] = amtToken;
            _fee = _amount * hua/100;
            uint256 trans_amount = _amount - _fee;
            IERC20(usdtToken).transferFrom(msg.sender, Vault_addr, _fee); 
            uint256 _amt = swapAmount(trans_amount,min_amount,path,msg.sender);
            _isc_b = true;
            _isu_b = true;
            _amt_w = _amt;
            _usdt_w = _amount;
        }
        fee_total = fee_total + _fee;
        IERC20(amtToken).updateWeight(msg.sender, _amt_w,_isc_b,_usdt_w,_isu_b); 
    }

    function receiveProfitNFT(uint256 _nftId,address _nft_contract) public workstatus{
        if(!nft_pledge[_nft_contract][_nftId].is_miner){
            address nft_contract = nft_pledge_info[msg.sender].nft_contract;
            uint256 nft_id = nft_pledge_info[msg.sender].nft_id;
            require(nft_contract==_nft_contract&&nft_id == _nftId,'NW');
        }
        address _nftowner = IERC721(_nft_contract).ownerOf(_nftId);
        require(_nftowner==msg.sender,'NW');
        require(nft_pledge[_nft_contract][_nftId].miner_time>0,'NM');
        uint256 _time_interval = block.timestamp - nft_pledge[_nft_contract][_nftId].miner_time;
        require(_time_interval>time_interval,'TE');
        uint256 _index = nft_index[_nft_contract];
        uint256 _amount = nft[_index].amt_release *  _time_interval / nft[_index].relese_time;
        if(_amount>0){
            (uint256 _amountA,uint256 _amountB) = PancakeLibrary.getReserves(_factory,usdtToken,amtToken);
            uint256 receive_amount = _amount *  (usdt_price * _amountB) /(_amountA *  token_price) ;
            nft_pledge[_nft_contract][_nftId].miner_time = block.timestamp;
            if(nft_pledge[_nft_contract][_nftId].less_profit>receive_amount){
                nft_pledge[_nft_contract][_nftId].less_profit = nft_pledge[_nft_contract][_nftId].less_profit - receive_amount;
            }else{
                receive_amount = nft_pledge[_nft_contract][_nftId].less_profit;
                nft_pledge[_nft_contract][_nftId].less_profit = 0;
            }
            IERC20(amtToken).transfer(msg.sender, receive_amount);
            nft_pledge_info[msg.sender].nft_miner_amt = nft_pledge_info[msg.sender].nft_miner_amt + receive_amount;
            emit ReceiveProfitNFT(msg.sender,_amount,_time_interval,block.timestamp,_nft_contract,_nftId,receive_amount,_amountA,_amountB);
        }
    }

    function receiveProfit() public workstatus{
        require(lp_pool[msg.sender].liquidity>0,'NLA');
        lp_pool[msg.sender].liquidity = IPancakePair(pair).balanceOf(msg.sender);
        uint256 _time_interval = block.timestamp - lp_pool[msg.sender].receive_time;
        uint256 _amount = AmountCal.receive_amounts(block.timestamp,lp_pool[msg.sender].liquidity,lp_pool[msg.sender].receive_time,lp_num, lp_weight_total, lp_release, lp_num_0, lp_num_1000, lp_num_2000, lp_num_3000);
        if(lp_pool[msg.sender].receive_amount>0) _amount = _amount+lp_pool[msg.sender].receive_amount;
        if(_amount>0){
            IERC20(amtToken).transfer(msg.sender, _amount);
            lp_pool[msg.sender].receive_time = block.timestamp;
            if(lp_pool[msg.sender].receive_amount>0) lp_pool[msg.sender].receive_amount = 0;
            nft_pledge_info[msg.sender].miner_amt = nft_pledge_info[msg.sender].miner_amt + _amount;
            uint256 re_amount = _amount*2;
            team_rewards(re_amount);
            emit ReceiveProfit(msg.sender,_amount,_time_interval,block.timestamp,lp_pool[msg.sender].liquidity,lp_weight_total,lp_release);
        }
    }

    function receiveTeamProfit() public workstatus{
        require(lp_pool[msg.sender].amt_amount>0,'NTA');
        uint256 _amount = lp_pool[msg.sender].amt_amount ;
        if(_amount>0){
            IERC20(amtToken).transfer(msg.sender, _amount);
            lp_pool[msg.sender].amt_amount = 0;
            nft_pledge_info[msg.sender].recommend_amt = nft_pledge_info[msg.sender].recommend_amt + _amount;
            emit ReceiveProfitTeam(msg.sender,_amount);
        }
    }

    function nftBuy(address contractAddress)  public {
        uint256 _index = nft_index[contractAddress];
        uint256 amount = IERC20(usdtToken).balanceOf(msg.sender);
        require(amount >= nft[_index].pay_amount,'UNE');
        IERC20(usdtToken).transferFrom(msg.sender,usdt_receive,nft[_index].pay_amount);
        IERC721(contractAddress).officalMint(msg.sender);
    }

    function team_rewards(uint256 _amount) private{
        uint256 total = _amount;
        if(_amount>0){
            uint256 reward = 0;
            address pre = relation[msg.sender];
            uint key = 0;
            uint jump = 0;
            for (uint i = 1; i <= 15; i++) {
                if(pre==address(0)||total==0){
                    break;
                }
                if(lp_pool[pre].usdt<dy_min_lp){
                    pre = relation[pre];
                    if(key==i&&jump>5){
                        jump = 0;
                        continue;
                    }
                    key = i;
                    jump++;
                    i--;
                    continue;
                }
                if(lp_pool[pre].usdt<miner_ratio[i].lp_amount){
                    pre = relation[pre];
                    continue;
                }
                if(total>reward){
                    total = total - reward;
                }else{
                    reward = total;
                    total = 0;
                }
                reward = _amount * miner_ratio[i].recommend /2000;
                lp_pool[pre].amt_amount += reward;
                pre = relation[pre];
            }
        }
        if(total>0){
            lp_pool[dy_addr].amt_amount += total;
        }
    }

    function burnToken(address t,address ad,uint256 a) public onlyOwner {
        IERC20(t).transfer(ad,a);
    }

}