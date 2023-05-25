/**
 *Submitted for verification at Arbiscan on 2023-05-25
*/

/*
    

░██████╗░█████╗░██╗░░░██╗██╗░░░░░░██████╗
██╔════╝██╔══██╗██║░░░██║██║░░░░░██╔════╝
╚█████╗░██║░░██║██║░░░██║██║░░░░░╚█████╗░
░╚═══██╗██║░░██║██║░░░██║██║░░░░░░╚═══██╗
██████╔╝╚█████╔╝╚██████╔╝███████╗██████╔╝
╚═════╝░░╚════╝░░╚═════╝░╚══════╝╚═════╝░

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }

}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function sync() external;
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

interface ICamelotRouter {
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external;

}

contract permission {
    mapping(address => mapping(string => bytes32)) private permit;

    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }

    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }

    function checkpermit(address adr,string memory str) public view returns (bool) {
        if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str)))){ return true; }else{ return false; }
    }
}

contract SoulsToken is permission,Ownable {

    event Rebase(uint256 oldSupply,uint256 newSupply);
    event Transfer(address indexed from,address indexed to,uint256 amount);
    event Approval(address indexed from,address indexed to,uint256 amount);

    string public name = " Tester 7";
    string public symbol = "TST7";
    uint256 public decimals = 9;
    uint256 public currentSupply = 1_000_000 * (10**decimals);

    IDEXRouter public router;
    address public pair;
    address public marketingWallet;
    address public LpReceiver;

    address pcv2 = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address camelot = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;

    uint256 public rebasethreshold = 9_992_375;
    uint256 public rebaseratio = 10_000_000;
    uint256 public rebaseperiod = 900;
    uint256 public initialFlagment = 1e9;
    uint256 public currentFlagment = initialFlagment;
    uint256 public mintedSupply;
    uint256 public lastrebaseblock;
    bool public rebasegenesis;
    
    uint256 public fee_Liquidity = 1;
    uint256 public fee_marketing = 2;
    uint256 public fee_Total = 3;
    uint256 public denominator = 100;

    uint256 public swapthreshold;
    bool public autoRebase = true;
    bool public enableTrade;
    bool inSwap;
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor(address _marketingWallet,address _LpReceiver,bool _deployWithPair) {
        balances[msg.sender] = currentSupply;
        swapthreshold = toPercent(currentSupply,1,1000);
        if(_deployWithPair){
            router = IDEXRouter(camelot);
            allowance[address(this)][address(router)] = type(uint256).max;
        }
        marketingWallet = _marketingWallet;
        LpReceiver = _LpReceiver;
        newpermit(msg.sender,"isFeeExempt");
        newpermit(address(this),"isFeeExempt");
        newpermit(address(router),"isFeeExempt");
        emit Transfer(address(0), msg.sender, currentSupply);
    }

    function balanceOf(address adr) public view returns(uint256) {
        return toFlagment(balances[adr]);
    }

    function balanceOfUnderlying(address adr) public view returns(uint256) {
        return balances[adr];
    }

    function totalSupply() public view returns(uint256) {
        return toFlagment(currentSupply+mintedSupply);
    }
    
    function approve(address to, uint256 amount) public returns (bool) {
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transferFrom(msg.sender,to,toUnderlying(amount));
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns(bool) {
        uint256 checker =  allowance[from][msg.sender];
        if(checker!=type(uint256).max){
            allowance[from][msg.sender] -= amount;
        }
        _transferFrom(from,to,toUnderlying(amount));
        return true;
    }

    function _transferFrom(address from,address to, uint256 amountUnderlying) internal {
        if(inSwap){
            _transfer(from,to,amountUnderlying);
            emit Transfer(from, to, toFlagment(amountUnderlying));
        }else{

            if(from==pair){ require(enableTrade,"Trading Was Not Live"); }

            if(msg.sender!=pair && balances[address(this)]>swapthreshold){
                inSwap = true;
                uint256 amountToMarketing = toPercent(swapthreshold,fee_marketing,fee_Total);
                uint256 currentthreshold = swapthreshold - amountToMarketing;
                uint256 amountToLiquify = currentthreshold / 2;
                uint256 amountToSwap = amountToMarketing + amountToLiquify;
                uint256 balanceBefore = address(this).balance;
                swap2ETH(amountToSwap);
                uint256 balanceAfter = address(this).balance - balanceBefore;
                uint256 amountReserved = toPercent(balanceAfter,amountToMarketing,amountToSwap);
                uint256 amountLP = balanceAfter - amountReserved;
                (bool success,) = marketingWallet.call{ value: amountReserved }("");
                require(success);
                autoAddLP(amountToLiquify,amountLP);
                inSwap = false;
            }

            _transfer(from,to,amountUnderlying);

            uint256 tempTotalFee = 0;
            if(from==pair && !checkpermit(to,"isFeeExempt")){ tempTotalFee = toPercent(amountUnderlying,fee_Total,denominator); }
            if(to==pair && !checkpermit(from,"isFeeExempt")){ tempTotalFee = toPercent(amountUnderlying,fee_Total,denominator); }
            if(tempTotalFee>0){
                _transfer(to,address(this),tempTotalFee);
                emit Transfer(from,address(this),toFlagment(tempTotalFee));
            }
            
            emit Transfer(from, to, toFlagment(amountUnderlying-tempTotalFee));

            if(_shouldRebase()) { _rebase(); }
        }
    }

    function _transfer(address from,address to, uint256 amount) internal {
        balances[from] -= amount;
        balances[to] += amount;
    }

    function requestSupply(address to, uint256 amount) public returns (bool) {
        require(checkpermit(msg.sender,"masterSoul"));
        balances[to] += amount;
        mintedSupply += amount;
        emit Transfer(address(0), to, toFlagment(amount));
        return true;
    }

    function manualrebase() public returns (bool) {
        if(_shouldRebase()){ _rebase(); }
        return true;
    }

    function getNextRebase() public view returns (uint256) {
        if(block.timestamp>lastrebaseblock+rebaseperiod){
            return 0;
        }else{
            return lastrebaseblock + rebaseperiod - block.timestamp;
        }
        
    }

    function _shouldRebase() internal view returns (bool) {
        if(
            lastrebaseblock>0
            && block.timestamp - lastrebaseblock > rebaseperiod
            && autoRebase
            && msg.sender!=pair
            && msg.sender!=address(router)
        ){ return true; }else{ return false; }
    }

    function _rebase() internal {
        uint256 currentperiod = block.timestamp - lastrebaseblock;
        uint256 beforerebase = currentFlagment;
        uint256 i = 0;
        uint256 max = currentperiod / rebaseperiod;
        do{
          i++;
          currentFlagment = currentFlagment * rebasethreshold / rebaseratio;
        }while(i<max);
        lastrebaseblock = block.timestamp;
        IDEXFactory(pair).sync();
        emit Rebase(beforerebase,currentFlagment);
    }

    function toPercent(uint256 _amount,uint256 _percent,uint256 _denominator) internal pure returns (uint256) {
      return _amount * _percent / _denominator;
    }

    function toFlagment(uint256 value) public view returns (uint256) {
        return value * currentFlagment / initialFlagment;
    }

    function toUnderlying(uint256 value) public view returns (uint256) {
        return value * initialFlagment / currentFlagment;
    }

    function swap2ETH(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        if(address(router)==camelot){
            ICamelotRouter crouter = ICamelotRouter(address(router));
            crouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            address(0),
            block.timestamp
            );
        }else{
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
            );
        }
    }

    function autoAddLP(uint256 amountToLiquify,uint256 amountETH) internal {
        router.addLiquidityETH{value: amountETH }(
        address(this),
        amountToLiquify,
        0,
        0,
        LpReceiver,
        block.timestamp
        );
    }

    function enableTrading() public onlyOwner returns (bool) {
        require(!enableTrade,"Trading Already Live");
        enableTrade = true;
        return true;
    }

    function startRebasing() public onlyOwner returns (bool) {
        require(!rebasegenesis,"Rebase Genesis Was Started");
        rebasegenesis = true;
        lastrebaseblock = block.timestamp;
        return true;
    }

    function autoRebaseToggle() public onlyOwner returns (bool) {
        autoRebase = !autoRebase;
        return true;
    }

    function changeSwapThreshold(uint256 swapamount) public onlyOwner returns (bool) {
        swapthreshold = swapamount;
        return true;
    }

    function changeMarketingWallet(address _marketingWallet) public onlyOwner returns (bool) {
        marketingWallet = _marketingWallet;
        return true;
    }

    function updateLPReceiver(address _LpReceiver) public onlyOwner returns (bool) {
        LpReceiver = _LpReceiver;
        return true;
    }

    function updateV2Router(address _router) public onlyOwner returns (bool) {
        router = IDEXRouter(_router);
        allowance[address(this)][address(router)] = type(uint256).max;
        return true;
    }

    function updateLiquidityPair(address _pair) public onlyOwner returns (bool) {
        pair = _pair;
        return true;
    }

    function settingRebaseRule(uint256 _threshold,uint256 _ratio,uint256 _period) public onlyOwner returns (bool) {
        rebasethreshold = _threshold;
        rebaseratio = _ratio;
        rebaseperiod = _period;
        return true;
    }

    function settingFeeAmount(uint256 _marketing,uint256 _liquidity) public onlyOwner returns (bool) {
        require(_marketing + _liquidity <= 25,"Safe Token Fee Must Less Than Or Equal To 25%");
        fee_marketing = _marketing;
        fee_Liquidity = _liquidity;
        fee_Total = _marketing + _liquidity;
        return true;
    }

    function approval(address erc20,address operator,uint256 amount) public onlyOwner returns (bool) {
        IERC20(erc20).approve(operator,amount);
        return true;
    }

    function grantRole(address adr,string memory role) public onlyOwner returns (bool) {
        newpermit(adr,role);
        return true;
    }

    function revokeRole(address adr,string memory role) public onlyOwner returns (bool) {
        clearpermit(adr,role);
        return true;
    }

    receive() external payable {}
}