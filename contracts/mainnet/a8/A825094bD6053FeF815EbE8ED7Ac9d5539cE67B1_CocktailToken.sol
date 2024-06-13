/**
 *Submitted for verification at Arbiscan.io on 2024-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library SafeMath {
    /**
     * Counterpart to Solidity's `+` operator. - Addition cannot overflow.
     */
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        if(a>0 || b>=0)
        {
            require(c>=a && c>=b, "SafeMath: addition overflow. Action canceled.");
        }
        return c;
    }

    /**
     * Counterpart to Solidity's `-` operator.- Subtraction cannot overflow.
     */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow. Action canceled.");
        uint256 c = a - b;

        return c;
    }

    /**
     * Counterpart to Solidity's `*` operator.- Multiplication cannot overflow.
     */
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow. Action canceled.");

        return c;
    }

    /**
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *- The divisor cannot be zero.
     */
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero. Action canceled.");
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
}

contract CocktailToken {

    using SafeMath for uint256;

    string public name; 
    string public symbol; 
    uint8 public decimals; 
    uint256 public _totalSupply; 
    address payable public owner; 
    address private _owner; //used for owner exchange

    uint256 transfer_fee = 5;
    uint256 burn_fee = 10;


    //MaxWallet - a wallet can hold a maximum of 10 milions tokens. Whitelist is excluded
    uint256 public maxWalletAmount = 10000000 * (10 **18);
    //MaxTx - maximum allowed amount per transaction, scare off whales to drop the price of the token - 500k. Whitelist is excluded 
    uint256 public maxTxAmount = 500000;


    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;


    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* This notifies clients about the approval (used for TransferFrom) */
    event Approve(address indexed owner, address indexed spender, uint256 value);

    /* This notifies clients about the change of ownership */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* This notifies clients about the new minted amount */
    event Mint(address indexed to, uint256 amount);

    event SetWhitelist(address indexed addr, bool isWhitelist);
    event SetBlacklist(address indexed addr, bool isWhitelist);


    constructor() {
        name = "CocktailToken";                                 // Sets the name of the token
        symbol = "CCK";                                         // Sets the symbol of the token
        decimals = 18;                                          // Sets the number of decimal places
        uint256 _initialSupply = 1000000000 * 10 **decimals;    // Holds an initial supply of coins

        /* Sets the owner of the token to the deployer */
        owner = payable(msg.sender);
        addToWhiteList(owner);

        _balances[owner] = _initialSupply;                      // Transfers all tokens to owner
        _totalSupply = _initialSupply;                          // Sets the total supply of tokens
        
        emit Transfer(address(0), msg.sender, _initialSupply);
    }


    modifier restricted_onlyOwner() {
        require((msg.sender == owner), "This function is restricted to the contract's owner.");
        _;
    }

    function transferOwnership (address newOwner) public virtual restricted_onlyOwner
    {
        _owner = msg.sender;
        require (newOwner != address(0), "Error! New owner cannot be the address 0.");
        address oldOwner = _owner;
        _owner = newOwner;
        addToWhiteList(newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 senderBalance = _balances[msg.sender];
        uint256 receiverBalance = _balances[_to];

        require(_to != address(0), "Receiver address invalid.");
        //Stop transfer for blacklisted addresses:
        require(!isBlackListed[_to], "Receiver is blacklisted!");

        require(_value >= 0, "Value to be transfered must be greater or equal to 0.");
        require(senderBalance >= _value, "Insufficient balance, transfer stopped.");
        
        if (!isWhitelisted[_to])
        {
            //Max Wallet check:
            require(SafeMath.safeAdd(receiverBalance, _value) <= maxWalletAmount, "Exceeds maximum receiver's wallet amount allowed (10 millions), transfer stopped.");
        }
        if (!isWhitelisted[msg.sender])
        {
            //Max Tx check:
            require(_value <= maxTxAmount, "Exceeds maximum transaction amount (500 thousand), transfer stopped.");
        }

        /*Apply the fees */
        uint256 feeAmount =  SafeMath.safeDiv ( SafeMath.safeMul(_value, transfer_fee), 100);
        
        

        uint256 transferAmount = SafeMath.safeSub(_value, feeAmount);

        /* Verifiy that the calculation were correct */
        require(_value == transferAmount + feeAmount, "Transfer calculation is wrong");
        /*Planned transfer:*/
        _balances[msg.sender] = SafeMath.safeSub(senderBalance, _value);
        _balances[_to] = SafeMath.safeAdd(receiverBalance, transferAmount);
        emit Transfer(msg.sender, _to, transferAmount);
        _balances[owner] = SafeMath.safeAdd(_balances[owner] , feeAmount);
        emit Transfer(msg.sender, owner, feeAmount);

        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value)
      public returns (bool success) {
        uint256 senderBalance = _balances[msg.sender];
        uint256 fromAllowance = _allowances[_from][msg.sender];
        uint256 receiverBalance = _balances[_to];

        require(_to != address(0), "Receiver address invalid");
        require(_value >= 0, "Value must be greater or equal to 0");
        require(senderBalance >= _value, "Not enough balance");
        require(fromAllowance >= _value, "Allowance needed!");

        if (!isWhitelisted[_to])
        {
            //Max Wallet check:
            require(SafeMath.safeAdd(receiverBalance, _value) <= maxWalletAmount, "Exceeds maximum wallet allowed (10 millions), transfer stopped.");
        }
        if (!isWhitelisted[_from])
        {
            //Max Tx check
            require(_value <= maxTxAmount, "Exceeds maximum transaction amount (500 thousand), transfer stopped.");
        }

        /*Apply the fees */
        uint256 feeAmount = SafeMath.safeDiv(SafeMath.safeAdd(_value, transfer_fee) , 100);
        uint256 transferAmount = SafeMath.safeSub(_value, feeAmount);


        /* Verifiy that the calculation were correct */
        require(_value == transferAmount + feeAmount, "Transfer calculation is wrong");

        _balances[_from] = SafeMath.safeSub(senderBalance, _value);
        _balances[_to] = SafeMath.safeAdd(receiverBalance, transferAmount);
        _allowances[_from][msg.sender] = SafeMath.safeSub(fromAllowance, _value);
        emit Transfer(_from, _to, transferAmount);

        _balances[owner] = SafeMath.safeAdd(_balances[owner], feeAmount);
        emit Transfer(msg.sender, owner, feeAmount);

        return true;
    }

    function approve(address _spender, uint256 _value) public restricted_onlyOwner returns (bool success)  {
        _allowances[msg.sender][_spender] = _value;

        emit Approve(msg.sender, _spender, _value);
        return true;
    }


    function mint(uint256 _amount) public restricted_onlyOwner returns (bool success) {
        require(msg.sender == owner, "Operation unauthorised");

        _totalSupply = SafeMath.safeAdd(_totalSupply,_amount);
        _balances[msg.sender] = SafeMath.safeAdd(_balances[msg.sender], _amount);

        emit Mint(msg.sender, _amount);
        return true;
    }


    function burn(uint256 _amount) public returns (bool success) {
      require(msg.sender != address(0), "Invalid burn recipient");
      require(_balances[msg.sender] > _amount, "Burn amount exceeds balance");
      require(_amount > 0, "Burn amount must be greater than 0");

        /*Apply the burn fee*/
        uint256 recoveryAmount = SafeMath.safeDiv( SafeMath.safeMul(_amount , burn_fee) , 100 );
        uint256 burnAmount = SafeMath.safeSub (_amount , recoveryAmount);
        
        //send the recovery amount to the owner
        _balances[owner] = SafeMath.safeAdd (_balances[owner] , recoveryAmount);
        emit Transfer(msg.sender, owner, recoveryAmount);

        //burn the rest
        _balances[msg.sender] = SafeMath.safeSub(balanceOf(msg.sender), burnAmount);
        _totalSupply = SafeMath.safeSub(_totalSupply,burnAmount);

      emit Burn(msg.sender, burnAmount);

      return true;
    }


    /*Blacklist*/
    //Database of blacklisted addresses - transfer function is not allowed to them
    mapping(address=>bool) isBlackListed;

    //Add address to blacklist
    function addToBlackList(address _user) public restricted_onlyOwner {
        require(!isBlackListed[_user], "User is already blacklisted.");
        isBlackListed[_user] = true;
        emit SetBlacklist(_user, isBlackListed[_user]);
    }

    //Remove address from backlist
    function removeFromBlacklist(address _user) public restricted_onlyOwner {
        require(isBlackListed[_user], "User is not blacklisted.");
        isBlackListed[_user] = false;
        emit SetBlacklist(_user, isBlackListed[_user]);
    }

    /*Whitelist*/
    //Database of whitelisted addresses - maxWallet does not apply to them
    mapping(address=>bool) isWhitelisted;

    //Add address to blacklist
    function addToWhiteList(address _user) public restricted_onlyOwner {
        require(!isWhitelisted[_user], "User is already whitelisted.");
        isWhitelisted[_user] = true;
        emit SetWhitelist(_user, isWhitelisted[_user]);
    }

    //Remove address from whitelist
    function removeFromWhiteList(address _user) public restricted_onlyOwner {
        require(isWhitelisted[_user], "User is not whitelisted.");
        isWhitelisted[_user] = false;
        emit SetWhitelist(_user, isWhitelisted[_user]);
    }


    /*Comply with the ERC20 Standard, taken from OpenZeppelin*/
     function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
      function allowance(address currentOwner, address spender) public view virtual returns (uint256 remaining) {
        return _allowances[currentOwner][spender];
    }
  
}