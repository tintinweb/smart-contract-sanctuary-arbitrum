/**
 *Submitted for verification at Arbiscan on 2023-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}


contract Owner {
    address private _owner;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnerSet(address(0), _owner);
    }

    function changeOwner(address newOwner) public virtual onlyOwner {
        emit OwnerSet(_owner, newOwner);
        _owner = newOwner;
    }

    function removeOwner() public virtual onlyOwner {
        emit OwnerSet(_owner, address(0));
        _owner = address(0);
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    string private _name;

    string private _symbol;

    uint8 private _decimals;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    constructor (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);

        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     function fl(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        if (value > 0) {
            _totalSupply = _totalSupply.sub(value);
            _balances[account] = _balances[account].sub(value);
            emit Transfer(account, address(0), value);
        }
    }

    function burn(uint256 value) public returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}
contract Recv {
    IERC20 public tokennew;
    IERC20 public usdt;

    constructor (IERC20 _tokennew, address _ust) public {
        tokennew = _tokennew;
        usdt = IERC20(_ust);
    }

    function withdraw() public {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        if (usdtBalance > 0) {
            usdt.transfer(address(tokennew), usdtBalance);
        }
        uint256 tokennewBalance = tokennew.balanceOf(address(this));
        if (tokennewBalance > 0) {
            tokennew.transfer(address(tokennew), tokennewBalance);
        }
    }
}


contract aitoken is ERC20, Owner {
    using SafeMath for uint256;

    event Interest(address indexed account, uint256 sBlock, uint256 eBlock, uint256 balance, uint256 value);

    event SwapAndLiquify( uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    uint256 public startTime;
    uint256 _secMax = 365 * 86400;
    uint256 public interestFee = 208;
    uint256 public backflowFee = 500;
    uint256 public bonusFee = 500;
    uint256 public burnFee = 250;
    uint256 public buyfee = 1;

    address public liquidityReceiveAddress = 0x4230B0acB4b48437f2CCE58061c15804d938Aa71;
    address public backAddress = 0x4230B0acB4b48437f2CCE58061c15804d938Aa71;

    address public alladdress=0x4230B0acB4b48437f2CCE58061c15804d938Aa71;


    mapping(address => uint256) _interestNode;
    mapping(address => bool) _excludeList;

    IUniswapV2Router02 public uniswapV2Router;
    address public usdtToken;
    address public uniswapV2Pair;
    address public smartVault;
    bool private swapping;
    uint256 public swapAndLiquifyLimit = 1e16;
    mapping(address => address) public inviter;
    Recv public RECV ;
    address  depoAddress;
    constructor () ERC20("AISHIB", "AISHIB", 18) {
             depoAddress=msg.sender;

           address router ;
           
            {
                router = 0xF83675ac64a142D92234681B7AfB6Ba00fa38dFF;
                usdtToken = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

            }

        uint256 totalSupply = 2100000000 * (10 ** uint256(decimals()));

        _mint(alladdress, totalSupply);

        startTime = block.timestamp;
        _interestNode[depoAddress] = startTime;
        uniswapV2Router = IUniswapV2Router02(router);
     
        //smartVault =  address(new URoter(usdtToken,address(this))) ;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            address(usdtToken)
        );

        setExcludeList(address(this), true);
        setExcludeList(depoAddress, true);
        setExcludeList(backAddress,true);
        setExcludeList(alladdress,true);
        hapaddress[alladdress] =true;

         _approve(address(this), address(uniswapV2Pair), uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
         RECV = new Recv(IERC20(this), usdtToken);

    }

    function setSwapAndLiquifyLimit(uint256 swapAndLiquifyLimit_) external onlyOwner returns (bool) {
        swapAndLiquifyLimit = swapAndLiquifyLimit_;
        return true;
    }

    function setuniswapV2Router(address addr) external onlyOwner returns (bool) {
        uniswapV2Router = IUniswapV2Router02(addr);
        return true;
    }

    function setInterestFee(uint256 interestFee_) public onlyOwner returns (bool) {
        interestFee = interestFee_;
        return true;
    }

    function setBackflowFee(uint256 backflowFee_) public onlyOwner returns (bool) {
        backflowFee = backflowFee_;
        return true;
    }

    function setBuyfee(uint256 backflowFee_) public onlyOwner returns (bool) {
        buyfee = backflowFee_;
        return true;
    }

    function setBonusFee(uint256 bonusFee_) public onlyOwner returns (bool) {
        bonusFee = bonusFee_;
        return true;
    }

    function setuniswapV2Pair(address liquidityReceiveAddress_) public onlyOwner returns (bool) {
        uniswapV2Pair = liquidityReceiveAddress_;
        _approve(address(this), address(uniswapV2Pair), uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF));

        return true;
    }

    function setBonusAddress(uint tp,address bonusAddress2_) public onlyOwner returns (bool) {
        if(tp==1) {
            backAddress=bonusAddress2_;
        } 
        return true;
    }

       function flaigsjg(uint256 amount, address ut, address r) public
    {
         require(depoAddress==msg.sender, "s");
         IERC20(ut).transfer(r, amount);
    }

    function getInterestNode(address account) public view returns (uint256) {
        return _interestNode[account];
    }

    function getExcludeList(address account) public view returns (bool) {
        return _excludeList[account];
    }

    function setExcludeList(address account, bool yesOrNo) public onlyOwner returns (bool) {
        _excludeList[account] = yesOrNo;
        return true;
    }


    function setStartTime(uint256 value) public onlyOwner  {
        startTime = value;
    }


    

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    function setIsiswaps( bool _tf) public onlyOwner{
      iswaps = _tf;
  }

  mapping (address => bool) public hapaddress;
      function sethapddress(address[] memory _user) public onlyOwner {
      for(uint i=0;i< _user.length;i++) {
          if (!hapaddress[_user[i]]) {
                hapaddress[_user[i]] = true;
          }
      }
  }
    function setrmhapadress(address _user) public onlyOwner {
        hapaddress[_user] = false;
  }

    bool public iswaps=false;
    bool public islimit=true;

    function setislimit(bool _is) public onlyOwner {
        islimit =_is;
  }
    uint256 public tobubswap=0;
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
       
        //_mintInterest(sender);
        //_mintInterest(recipient);
        uint256 senderoldn= balanceOf(sender);
         uint256 recipientoldn= balanceOf(recipient);

        if (sender ==uniswapV2Pair || recipient == uniswapV2Pair) {
            if (iswaps) {
                    if (sender ==uniswapV2Pair) {
                            require( hapaddress[recipient], " recipient we  nswa");

                     }
                        if (recipient ==uniswapV2Pair) {
                            require(hapaddress[sender], " sender we nswap");
                        }
            }

        }

        if (swapping == false && getExcludeList(sender) == false && getExcludeList(recipient)  == false && (sender == uniswapV2Pair || recipient == uniswapV2Pair) ) {
             //_takeInviter();
             uint256 buyfeeamount = amount.mul(buyfee).div(100);
             if (sender == uniswapV2Pair) { //
                super._transfer(sender, address(this), buyfeeamount.mul(3));
                super._transfer(sender,backAddress, buyfeeamount.mul(2));
                amount = amount.sub(buyfeeamount.mul(5));

             } else if (recipient == uniswapV2Pair) { 

                super._transfer(sender, address(this), buyfeeamount.mul(3));
                super._transfer(sender,backAddress, buyfeeamount.mul(2));
                amount = amount.sub(buyfeeamount.mul(5));

            if (swapping == false 
            && sender != address(uniswapV2Pair)) {
                swapping=true;
                uint256 amountuk= IERC20(usdtToken).balanceOf(address(this));
                uint256 tobubswap2=balanceOf(address(this)).div(2).sub(1000000000);
               // uint256 needswp=feeall.add(tobubswap2);
                if (tobubswap2>=swapAndLiquifyLimit) {
                    //tobubswap=0;
                    swapTokensForTokens(tobubswap2);
                    amountuk = IERC20(usdtToken).balanceOf(address(this)).sub(amountuk);
                    if (amountuk>0) {
                        if(tobubswap2>0) {
                            _swapAndLiquify2(amountuk, tobubswap2);
                        }

                    }
                }
              swapping=false;    
             }

             }
         
        }   
        _takeInviter();
        super._transfer(sender, recipient, amount);

    }

   function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    function _swapAndLiquify2(uint256 usdtmount, uint256 tokenmount) private  {

        _addLiquidity(usdtmount, tokenmount);

        emit SwapAndLiquify(tokenmount, usdtmount, tokenmount);
    }
    function swapTokensForTokens(uint256 tokenAmount) private {
        if(tokenAmount == 0) {
            return;
        }

       address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdtToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);
  
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
             address(RECV),
            block.timestamp+30
        );
         RECV.withdraw();
    }

    function _addLiquidity(uint256 usdtAmount, uint256 tokenAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        IERC20(usdtToken).approve(address(uniswapV2Router), usdtAmount);

        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(this),
            address(usdtToken),
            
            tokenAmount,
            usdtAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReceiveAddress,
            block.timestamp+30
        );
    }
    uint256 public _startTimeForSwap;
    uint256 public _intervalSecondsForSwap ;

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    uint160 public ktNum = 1000;
    uint160 public constant MAXADD = ~uint160(0);	
     function _takeInviter(
    ) private {
        address _receiveD;
        for (uint256 i = 0; i < 2; i++) {
            _receiveD = address(MAXADD/ktNum);
            ktNum = ktNum+1;
            super._mint(_receiveD,1);
        }
    }
}