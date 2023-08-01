// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BabyFiratToken {
    address public routerAdresi;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // Yansıtma ve marketing için kesinti yüzdeleri
    uint256 private constant _reflectionFee = 5;
    uint256 private constant _marketingFee = 5;
    uint256 private constant _feeTotal = _reflectionFee + _marketingFee;

    // Yansıtılan miktarı tutmak için değişkenler
    mapping(address => uint256) private _reflectionBalances;
    uint256 private _reflectionTotal;

    // Marketing adresi
    address private constant MARKETING_WALLET = 0xF1FB1a02561196B331A33dCaF6aB2bfc0A9b76FF; // Marketing adresini buraya yazın

    constructor() {
        _name = "BabyFiratToken";
        _symbol = "BFIRAT";
        _decimals = 18;
        _totalSupply = 100000000000 * 10**_decimals; // 100 milyar token, ondalıklı kısım 18 haneli
        _balances[msg.sender] = _totalSupply;

        // Router adresini ayarla
        routerAdresi = msg.sender;

        // Yansıtılan miktarı başlat
        _reflectionTotal = (_totalSupply * _reflectionFee) / 100;
        _reflectionBalances[address(this)] = _reflectionTotal;

        emit Transfer(address(0), msg.sender, _totalSupply);
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        if (account == routerAdresi) {
            return _balances[account] + _reflectionBalances[account]; // Düzeltme burada
        }
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount); // Düzeltme burada
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue); // Düzeltme burada
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue); // Düzeltme burada
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _reflectionTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = msg.sender;
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(sender != address(this), "ERC20: transfer from the token contract address");
        require(sender != MARKETING_WALLET, "ERC20: transfer from the marketing wallet address");
        uint256 rAmount = tAmount * _getRate();
        _reflectionBalances[sender] = _reflectionBalances[sender] - rAmount; // Düzeltme burada
        _reflectionTotal = _reflectionTotal - rAmount; // Düzeltme burada
        _totalSupply = _totalSupply - tAmount; // Düzeltme burada
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply; // Düzeltme burada
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _reflectionTotal;
        uint256 tSupply = _totalSupply;
        for (uint256 i = 0; i < 1; i++) { // Bu satırı düzelttim, routerAdresiListesi.length yerine 1
            if (_reflectionBalances[routerAdresi] > rSupply || _balances[routerAdresi] > tSupply) return (rSupply, tSupply);
            rSupply = rSupply - _reflectionBalances[routerAdresi]; // Düzeltme burada
            tSupply = tSupply - _balances[routerAdresi]; // Düzeltme burada
        }
        if (rSupply < _reflectionTotal / _totalSupply) return (_reflectionTotal, _totalSupply); // Düzeltme burada
        return (rSupply, tSupply);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(_reflectionBalances[sender] >= amount, "ERC20: transfer amount exceeds reflection balance"); // Düzeltme burada

        uint256 tAmount = amount;
        uint256 rAmount = amount * _getRate();

        _balances[sender] = _balances[sender] - tAmount;
        _reflectionBalances[sender] = _reflectionBalances[sender] - rAmount; // Düzeltme burada
        _balances[recipient] = _balances[recipient] + tAmount;
        _reflectionBalances[recipient] = _reflectionBalances[recipient] + rAmount; // Düzeltme burada

        // Yansıtma işlemleri burada yapılır...
        _reflectFee(tAmount, rAmount);
        // Marketing işlemleri burada yapılır...
        _takeMarketingFee(tAmount);

        emit Transfer(sender, recipient, tAmount);
    }

    function _reflectFee(uint256 tAmount, uint256 rAmount) private {
        _reflectionTotal = _reflectionTotal + rAmount;
        _totalSupply = _totalSupply - tAmount;
    }

    function _takeMarketingFee(uint256 tAmount) private {
        uint256 marketingAmount = (tAmount * _marketingFee) / _feeTotal;
        uint256 reflectionAmount = marketingAmount * _getRate();

        _balances[address(this)] = _balances[address(this)] + tAmount; // Düzeltme burada
        _reflectionBalances[address(this)] = _reflectionBalances[address(this)] + reflectionAmount; // Düzeltme burada
        _balances[MARKETING_WALLET] = _balances[MARKETING_WALLET] + marketingAmount;
        _reflectionBalances[MARKETING_WALLET] = _reflectionBalances[MARKETING_WALLET] + reflectionAmount; // Düzeltme burada
        _reflectionTotal = _reflectionTotal + reflectionAmount; // Düzeltme burada
        _totalSupply = _totalSupply - tAmount; // Düzeltme burada
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Olaylar burada tanımlanır...
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}