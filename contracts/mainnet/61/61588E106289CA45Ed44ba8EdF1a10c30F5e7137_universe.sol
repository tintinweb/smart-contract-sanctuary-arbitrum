/**
 *Submitted for verification at Arbiscan.io on 2023-11-30
*/

//etherclips.com
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract universe {

    string internal _name;
    string internal _symbol;
    uint internal _decimals;
    uint private _totalSupply;
    uint public maxSupply;
    uint private initMinerCost;
    uint private initTPH;
    uint public globalContributed;
    uint public globalMultiplier;
    uint public globalCost;
    address public proxy = address(1);
    address private dev;

    mapping(address => bool) public minter;
    mapping(address => uint) private lastMintBlock;
    mapping(address => uint) internal _balanceOf;
    mapping(address => mapping(address => uint)) internal _allowance;
    mapping(address => autoClipper[]) public miners;
    mapping(address => uint) public minerCost;
    mapping(address => uint) public userMultiplier;

    struct autoClipper {
        uint start;
        uint CPH;
        uint upgradeCost;
        bool exists;
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    modifier onlyProxy() {require(address(this) == proxy, "Function can only be called through the proxy");_;}
    modifier onlyDev() {require(msg.sender == dev, "Only the developer may call this function");_;}

    function name() public view virtual returns (string memory) { return "Ethereum Paperclip Simulator"; }
    function symbol() public view virtual returns (string memory) { return "eCLIPS"; }
    function decimals() public view virtual returns (uint) { return _decimals; }
    function totalSupply() public view virtual returns (uint) { return _totalSupply; }
    function balanceOf(address account) public view virtual returns (uint) { return _balanceOf[account]; }
    function allowance(address owner, address spender) public view virtual returns (uint) { return _allowance[owner][spender]; }
    function minerCount(address user) public view returns (uint count) {return miners[user].length;}

    function approve(address spender, uint amount) public virtual returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public virtual returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint amount) internal virtual {
        require(_balanceOf[from] >= amount, "Transfer amount exceeds balance");
        _balanceOf[from] -= amount;
        _balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _spendAllowance(address owner, address spender, uint amount) internal virtual {
        require(_allowance[owner][spender] >= amount, "Insufficient allowance");
        _allowance[owner][spender] -= amount;
    }

    function totalUserCPH(address user) public view returns (uint totalCPH) {
        uint userMultiplierEffect = 2 ** userMultiplier[user]; totalCPH = 0;
        for (uint i = 0; i < miners[user].length; i++) {totalCPH += miners[user][i].CPH * userMultiplierEffect;}
    }

    function minedAmount(address user, uint minerIndex) public view returns (uint) {
        require(minerIndex < miners[user].length, "Miner does not exist");
        autoClipper memory miner = miners[user][minerIndex];
        uint timeElapsed = block.timestamp - miner.start;
        return timeElapsed * (2 ** globalMultiplier) *(2 ** userMultiplier[user]) * miner.CPH / 60 / 60;
    }

    function withdraw() public onlyDev {
        uint amount = address(this).balance;
        require(amount > 0, "No Ether left to withdraw");
        (bool success, ) = dev.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function clip() public payable onlyProxy{
        require(_totalSupply + (1 * (10**_decimals)) <= maxSupply, "Max supply exceeded");
        require(lastMintBlock[msg.sender] < block.number, "Already minted this block");
        require(tx.origin == msg.sender, "Mints can only be done by EOAs");
        lastMintBlock[msg.sender] = block.number;
        _totalSupply += 1 * (10**_decimals);
        _balanceOf[msg.sender] += 1 * (10**_decimals);
        emit Transfer(address(0), msg.sender, 1 * (10**_decimals));
    }

    function buyAutoclipper() public payable{
        uint _minerCost = minerCost[msg.sender]; 
        if (minerCost[msg.sender] == 0) {minerCost[msg.sender] = initMinerCost;} else {minerCost[msg.sender] = (_minerCost * 11) / 10;}
        require(_balanceOf[msg.sender] >= _minerCost, "Insufficient balance to buy autominer");
        _burn(msg.sender, minerCost[msg.sender]);

        autoClipper memory newMiner = autoClipper(block.timestamp, initTPH, initMinerCost * 2, true);
        miners[msg.sender].push(newMiner);
    }

    function upgradeAutoclipper(uint minerIndex) public payable{
        require(minerIndex < miners[msg.sender].length, "Miner does not exist");
        autoClipper storage miner = miners[msg.sender][minerIndex];

        require(_balanceOf[msg.sender] >= miner.upgradeCost, "Insufficient balance to upgrade");
        uint mined = minedAmount(msg.sender, minerIndex);
        require(_totalSupply + mined <= maxSupply, "Max supply exceeded");
        
        _totalSupply += mined;
        _balanceOf[msg.sender] += mined;
        emit Transfer(address(0), msg.sender, mined);

        _burn(msg.sender, miner.upgradeCost);
        miner.start = block.timestamp;
        miner.upgradeCost = miner.upgradeCost * 22 / 10;
        miner.CPH *= 2;
    }

    function buyMultiplier() public payable {
        uint currentMultiplierCount = userMultiplier[msg.sender];
        uint multiplierCost = 10 * (10 ** _decimals) * (10 ** currentMultiplierCount); // Cost increases by 10x each time

        require(_balanceOf[msg.sender] >= multiplierCost, "Insufficient balance to buy multiplier");
        _burn(msg.sender, multiplierCost);
        userMultiplier[msg.sender] = currentMultiplierCount + 1;
    }

    function buyGlobal(uint amount) public payable{
        require(_balanceOf[msg.sender] >= amount, "Insufficient balance to contribute");
        _burn(msg.sender, amount); globalContributed += amount;
        if (globalContributed >= globalCost) {globalCost *= 10; globalMultiplier += 1;}
    }

    function claimMinedBatch(uint startIndex, uint endIndex) public payable {
        require(startIndex <= endIndex, "Invalid index range");
        require(endIndex < miners[msg.sender].length, "End index out of range");

        uint totalAmount = 0;
        for (uint i = startIndex; i <= endIndex; i++) {
            uint amount = minedAmount(msg.sender, i);
            require(_totalSupply + amount <= maxSupply, "Max supply exceeded");
            _totalSupply += amount;
            _balanceOf[msg.sender] += amount;
            miners[msg.sender][i].start = block.timestamp; // Reset mining start time
            totalAmount += amount;
        }

        if (totalAmount > 0) {emit Transfer(address(0), msg.sender, totalAmount);}
    }

    function _burn(address from, uint amount) internal {
        require(_balanceOf[from] >= amount, "Burn amount exceeds balance");
        _totalSupply -= amount;
        _balanceOf[from] -= amount;
        emit Transfer(from, address(0), amount);
    }

    function initialize() public {
    require(proxy == address(0) || dev == msg.sender, "Fuck you");
        _decimals = 4;
        maxSupply = 1 * 10 ** (33 + 4); // 1 decillion
        initMinerCost = 10 * (10**4);
        initTPH = 6 * (10**4);
        globalCost = 10 * (10**4);
        proxy = address(this);
        dev = tx.origin;
    }

}