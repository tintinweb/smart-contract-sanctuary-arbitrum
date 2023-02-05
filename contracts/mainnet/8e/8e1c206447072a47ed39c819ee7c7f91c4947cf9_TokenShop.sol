/**
 *Submitted for verification at Arbiscan on 2023-02-05
*/

// File: Shop/ShopMath.sol

pragma solidity ^0.5.17;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: Shop/TokenShop.sol

pragma solidity ^0.5.17;


interface Token {
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function name() external view returns(string memory);
  function symbol() external view returns(string memory);
  function decimals() external view returns(uint8);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function getOwner() public view returns(address) {
    return owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner_ The address to transfer ownership to.
   */
  function transferOwnership(address newOwner_) public onlyOwner {
    _transferOwnership(newOwner_);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner_ The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner_) internal {
    require(newOwner_ != address(0));
    emit OwnershipTransferred(owner, newOwner_);
    owner = newOwner_;
  }
}

contract TokenShop is Ownable {
  using SafeMath for uint256;

  string public native;
  mapping(string => address) public tokens;

  event LogBuyToken(address eSender, uint256 eTokenAmount);
  event LogApproval(address eSender, uint256 eAmount);
  event LogDeposit(address eSender, uint256 eValue);
  event LogWithdraw(address eSender, uint256 eValue);

  constructor(string memory name_, address instance_) public {
     native = name_;
     tokens[native] = instance_;
  }

  //Token functions
  function getTokenSupply()
    public
    view
    returns (uint256)
  {
    Token tokenContract = Token(tokens[native]);
    return tokenContract.totalSupply();
  }

  function getTokenBalance(string memory tokenName_, address account_)
    public
    view
    returns (uint256)
  {
    Token tokenContract = Token(tokens[tokenName_]);
    return tokenContract.balanceOf(account_);
  }

  function getTokenName()
    public
    view
    returns (string memory)
  {
    Token tokenContract = Token(tokens[native]);
    return tokenContract.name();
  }

  function getTokenSymbol()
    public
    view
    returns (string memory)
  {
    Token tokenContract = Token(tokens[native]);
    return tokenContract.symbol();
  }

  function getTokenDecimals()
    public
    view
    returns (uint8)
  {
    Token tokenContract = Token(tokens[native]);
    return tokenContract.decimals();
  }

  //User functions

  function buyToken(string memory swapTokenName_, uint256 nativeTokenAmount_)
    public
    returns (bool)
  {
    // check stable token known to shop
    require(tokens[swapTokenName_] != address(0), "stable token not recognized");
    Token nativeTokenContract = Token(tokens[native]);
    Token stableTokenContract = Token(tokens[swapTokenName_]);
    // check not asking for more than shop balance
    // amount expects 18 decimal resolution
    require(nativeTokenContract.balanceOf(address(this)) >= nativeTokenAmount_, "insufficient shop balance");
    // check not asking for more than user balance
    uint8 _stableDecimals = stableTokenContract.decimals();
    uint256 _stableAmount = nativeTokenAmount_ / 10**(18 - uint256(_stableDecimals));
    require(stableTokenContract.balanceOf(msg.sender) >= _stableAmount, "insufficient user balance");
    require(stableTokenContract.allowance(msg.sender, address(this)) >= _stableAmount, "insufficient allowance");
    require(stableTokenContract.transferFrom(msg.sender, address(this), _stableAmount), "stable token transfer failed");
    require(nativeTokenContract.transfer(msg.sender, nativeTokenAmount_), "native token transfer filed");
    emit LogBuyToken(msg.sender, nativeTokenAmount_);
    return true;
  }

  //Shop functions
  function getShopStock()
    public
    view
    returns (uint256)
  {
    Token nativeTokenContract = Token(tokens[native]);
    return nativeTokenContract.balanceOf(address(this));
  }

  function getStableToken(string memory name_)
    public
    view
    returns (address)
  {
    return tokens[name_];
  }

  function getStableAllowance(string memory name_)
    public
    view
    returns (uint256)
  {
    Token stableTokenContract = Token(tokens[name_]);
    return stableTokenContract.allowance(msg.sender, address(this));
  }

  // Admin Functions
  function setStableToken(string memory name_, address address_)
    onlyOwner
    public
    returns (bool)
  {
    tokens[name_] = address_;
    return true;
  }

  function deposit(uint256 amount_)
    onlyOwner
    public
    returns (bool)
  {
    Token nativeTokenContract = Token(tokens[native]);
    require(nativeTokenContract.transferFrom(msg.sender, address(this), amount_), "transfer failed");
    emit LogDeposit(msg.sender, amount_);
    return true;
  }

  function withdraw(string memory name_, uint256 amount_)
    onlyOwner
    public
    returns (bool)
  {
    Token tokenContract = Token(tokens[name_]);
    require(tokenContract.balanceOf(address(this)) >= amount_, "insufficient balance");
    require(tokenContract.transfer(msg.sender, amount_), "transfer failed");
    emit LogWithdraw(msg.sender, amount_);
    return true;
  }

  function kill()
    onlyOwner
    public
  {
    selfdestruct(msg.sender);
  }


}