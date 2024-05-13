/**
 *Submitted for verification at Arbiscan.io on 2024-05-13
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

contract CryGIA {

    using SafeMath for uint256;

    string public name; 
    string public symbol; 
    uint8 public decimals; 
    uint256 public _totalSupply; 
    address payable public owner; 
    address private _owner; //used for owner exchange

    uint8 burn_fee = 5;

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


    constructor() {
        name = "CryGIA";                                 // Sets the name of the token
        symbol = "GIA";                                         // Sets the symbol of the token
        decimals = 18;                                          // Sets the number of decimal places
        uint256 _initialSupply = 1000000000 * 10 **decimals;    // Holds an initial supply of coins

        /* Sets the owner of the token to the deployer */
        owner = payable(msg.sender);

        _balances[owner] = _initialSupply;                      // Transfers all tokens to owner
        _totalSupply = _initialSupply;                          // Sets the total supply of tokens
        
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    /* Mechanism for functions which only the owner can execute */
    modifier restricted_onlyOwner() {
        require((msg.sender == owner), "This function is restricted to the contract's owner.");
        _;
    }

    /* Function to transfer the owner, only executable by the current owner */
    function transferOwnership (address newOwner) public virtual restricted_onlyOwner
    {
        _owner = msg.sender;
        require (newOwner != address(0), "Error! New owner cannot be the address 0.");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /* Usual transfer function */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 senderBalance = _balances[msg.sender];
        uint256 receiverBalance = _balances[_to];

        require(_to != address(0), "Receiver address invalid.");
        require(_value >= 0, "Value to be transfered must be greater or equal to 0.");
        require(senderBalance >= _value, "Insufficient balance, transfer stopped.");
        
        _balances[msg.sender] = SafeMath.safeSub(senderBalance, _value);
        _balances[_to] = SafeMath.safeAdd(receiverBalance, _value);
        emit Transfer(msg.sender, _to, _value);

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

        _balances[_from] = SafeMath.safeSub(senderBalance, _value);
        _balances[_to] = SafeMath.safeAdd(receiverBalance, _value);
        _allowances[_from][msg.sender] = SafeMath.safeSub(fromAllowance, _value);
        emit Transfer(_from, _to, _value);

        return true;
    }

    /* Standard approve function */
    function approve(address _spender, uint256 _value) public restricted_onlyOwner returns (bool success)  {
        _allowances[msg.sender][_spender] = _value;

        emit Approve(msg.sender, _spender, _value);
        return true;
    }

    /* Mint function, only the owner can execute */
    function mint(uint256 _amount) public returns (bool success) {
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
        uint256 burnAmount = _amount;
        
        //send the recovery amount to the owner
        _balances[owner] = SafeMath.safeAdd (_balances[owner] , recoveryAmount);
        emit Transfer(msg.sender, owner, recoveryAmount);

        //burn the rest
        _balances[msg.sender] = SafeMath.safeSub(balanceOf(msg.sender), burnAmount);
        _totalSupply = SafeMath.safeSub(_totalSupply,burnAmount);

      emit Burn(msg.sender, burnAmount);

      return true;
    }


    /* Comply with the ERC20 Standard, taken from OpenZeppelin */
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