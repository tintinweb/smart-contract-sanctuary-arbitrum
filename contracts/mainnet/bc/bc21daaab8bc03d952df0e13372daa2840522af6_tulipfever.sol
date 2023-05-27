pragma solidity ^0.8.4;

import './Context.sol';
import './IERC20.sol';
import './Ownable.sol';
import './SafeMath.sol';
import './IUniswapV2Router02.sol';
import './IUniswapV2Factory.sol';

contract tulipfever is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    mapping (address => uint256) public _rOwned;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1 * (10**9) * (10**18);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    
    uint256 private _redisFeeOnSell = 0;
    uint256 private _taxFeeOnSell = 6;

    uint256 private _redisFeeOnBuy = 0;
    uint256 private _taxFeeOnBuy = 6;
    
    uint256 private _redisFee;
    uint256 private _taxFee;
    
    string private constant _name = "tulipfever";
    string private constant _symbol = "TULIP";
    uint8 private constant _decimals = 18;

    address payable private _marketingAddress = payable(0x4222FefF33b84ed0F973e8DA7b1E52AC1DC2ddbE);
    address payable private _marketing2Address = payable(0x4222FefF33b84ed0F973e8DA7b1E52AC1DC2ddbE);
    address payable private _marketing3Address = payable(0x44381EE85405c19d2D18D3552c7fa8D8Fb7490f6);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool private inSwap = false;
    bool private swapEnabled = true;
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_marketing2Address] = true;
        _isExcludedFromFee[_marketing3Address] = true;

        emit Transfer(address(0x0000000000000000000000000000000000000000), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _redisFee = 0;
        _taxFee = 0;
        
        if (from != owner() && to != owner()) {
            
            uint256 contractTokenBalance = balanceOf(address(this));

            bool isJustTransfer = false;

            if (from != address(uniswapV2Pair) && to != address(uniswapV2Pair)) {
                isJustTransfer = true;
            }

            if (!isJustTransfer && !inSwap && from != uniswapV2Pair && swapEnabled && contractTokenBalance > 0) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
            
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnBuy;
                _taxFee = _taxFeeOnBuy;
            }
    
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnSell;
                _taxFee = _taxFeeOnSell;
            }

            if (isJustTransfer) {
                _redisFee = 0;
                _taxFee = 0;
            }
            
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                _redisFee = 0;
                _taxFee = 0;
            }
            
        }

        _tokenTransfer(from,to,amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        uint256 mktAmount = amount.mul(1).div(3);
        uint256 mkt2Amount = amount.mul(1).div(3);
        uint256 mkt3Amount = amount.sub(mktAmount).sub(mkt2Amount);
        _marketingAddress.transfer(mktAmount);
        _marketing2Address.transfer(mkt2Amount);
        _marketing3Address.transfer(mkt3Amount);
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        uint256 tTransferAmount = tAmount.sub(tAmount.mul(_redisFee).div(100)).sub(tAmount.mul(_taxFee).div(100));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tAmount.mul(_redisFee).div(100).mul(currentRate);
        uint256 rTeam = tAmount.mul(_taxFee).div(100).mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * only thing to change _rTotal
     */
    function _reflectFee(uint256 rFee) private {
        _rTotal = _rTotal.sub(rFee);
    }

    receive() external payable {}

	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function manualswap() external {
        require(_msgSender() == owner());
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == owner());
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    event ExcludeFromFees(address indexed account, bool isExcluded);
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

}