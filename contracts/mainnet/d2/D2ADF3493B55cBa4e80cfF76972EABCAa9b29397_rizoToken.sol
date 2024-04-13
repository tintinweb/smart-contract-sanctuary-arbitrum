// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract rizoToken is IERC20 {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public _minted;
    uint public _redeemed;
    uint public mintCount;
    uint public redeemCount;
    address owner;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    uint[] _ids;
    mapping (uint256 => bool) _exists;
    mapping (address => bool) _admin;

    bool contractActive;

 

    constructor() {
        symbol = "RIZO";
        name = "Rizo Bot Token";
        decimals = 6;
        _totalSupply = 0;
        _minted = 0;
        _redeemed = 0;
        mintCount = 0;
        redeemCount = 0;
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        _admin[owner] = true;
        contractActive = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");

    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "SafeMath: subtraction overflow");
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "SafeMath: division by zero");
        c = a / b;
    }

    function enableContract() external returns (bool) {
        require( msg.sender == owner, "Contract enabling is allowed only for the contract owner" );
        contractActive = true;
        return( true );
    }

    function disableContract() external returns (bool) {
        require( msg.sender == owner, "Contract disabling is allowed only for the contract owner" );
        contractActive = false;
        return( true );
    }


    function getOwner() public view returns (address) {
        return( owner );
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) external view returns (uint balance) {
        return balances[tokenOwner];
    }
 
    function updateWalletCount( address w ) internal {
        uint256 addr = uint256(uint160(w));
         if (!_exists[addr]) {
             _ids.push(addr);
             _exists[addr] = true;
         }


    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require( contractActive == true, "Contract is not active." );
 
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        updateWalletCount( to );
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        require( contractActive == true, "Contract is not active." );

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require( contractActive == true, "Contract is not active." );

        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][to], tokens);
        balances[to] = safeAdd(balances[to], tokens);

        updateWalletCount( to );


        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    event Burn(address indexed burner, uint256 amount);
    event Mint(address indexed receiver, uint256 amount);

    function burnToken(address frm, uint256 amount) external returns (bool) {
        require( contractActive == true, "Contract is not active." );

        require( _admin[msg.sender] == true, "Burning is allowed only for the admin" );
        require( balances[frm] >= amount, "Insufficient balance" );
        balances[frm] -= amount;
        _totalSupply -= amount;
        _redeemed += amount;
        redeemCount += 1;
        emit Burn(frm, amount);
        return true;
    }

    function mint(address receiver, uint256 amount) external returns (bool) {
        require( contractActive == true, "Contract is not active." );

        require( _admin[msg.sender] == true, "Minting is allowed only for the admin" );
        balances[receiver] += amount;

        updateWalletCount( receiver );

        _totalSupply += amount;
        _minted += amount;
        mintCount += 1;
        emit Mint(receiver, amount);
        return true;
    }

    function isAdmin(address addr) public view returns (bool) {
        return( _admin[addr] );
    }


    function addAdmin(address addr) public returns (bool) {
        require( contractActive == true, "Contract is not active." );

        require( msg.sender == owner, "Only contract owner can add admin" );
        _admin[addr] = true;
        return( true );
    }

    function getCirculatingSupply() public view returns (uint) {
        return _totalSupply;
    }

    function getWalletCount() public view returns (uint) {
        return _ids.length;
    }

    function getMinted() public view returns (uint) {
        return _minted;
    }

    function getRedeemed() public view returns (uint) {
        return _redeemed;
    }

    function getMintCount() public view returns (uint) {
        return mintCount;
    }

    function getRedeemCount() public view returns (uint) {
        return redeemCount;
    }


    function getWallets() public view returns (uint[] memory) {
        return _ids;
    }


    function endContract() public {
        require( msg.sender == owner, "Contract destruction is allowed only for the contract owner" );
        selfdestruct(payable(owner));
    }



}