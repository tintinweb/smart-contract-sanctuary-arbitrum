/**
 *Submitted for verification at Arbiscan.io on 2024-06-07
*/

//Powered By DxSale
// visit DxSale at https://dx.app for more info!

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
    
    function decimals() external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


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
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}



contract DxReferralManager is Ownable {
    using SafeMath for uint256;    
   
    // new vars
    address public refReferrer;
    address public referrer;
    uint256 public refReferrerPer;
    string public refCode;
    string public refName;
    string public refReferrerName;
    mapping(address => bool) public admin;
    constructor( address _refReferrer, address _referrer, uint256 _refReferrerPer, string memory _code, string memory _refName, string memory _refReferrerName) {

        refReferrer = _refReferrer;
        referrer = _referrer;
        refReferrerPer = _refReferrerPer;
        refCode = _code;
        refName = _refName;
        refReferrerName = _refReferrerName;
        admin[_referrer] = true;
        admin[_refReferrer] = true;
    }

    function claimReferralRewardsNative() public {
        
        require(admin[msg.sender] || msg.sender == owner,"not admin or owner or ref address");
       // require(msg.sender == referrer || msg.sender == refReferer,"not the referrer or refereferrer");
        uint256 ethBalance = address(this).balance;
        uint256 ethAmountForRefReferrer = ethBalance * refReferrerPer / 100;
        Address.sendValue(payable(refReferrer),ethAmountForRefReferrer);
        Address.sendValue(payable(referrer),address(this).balance);
    }
    function claimReferralRewardsToken(address _token) public {
        
        require(admin[msg.sender] || msg.sender == owner,"not admin or owner or ref address");
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        require(tokenBalance > 0,"token balance zero");
        uint256 tokenAmountForRefReferrer = tokenBalance * refReferrerPer / 100;
       // uint256 tokenAmountForReferrer = tokenBalance - tokenAmountForRefReferrer;
        IERC20(_token).transfer(refReferrer, tokenAmountForRefReferrer);
        IERC20(_token).transfer(referrer, IERC20(_token).balanceOf(address(this)));
    }
    function claimReferralRewardsToken(address _token, uint256 _tokenAmount) public {
        
        require(admin[msg.sender] || msg.sender == owner,"not admin or owner or ref address");
        
        require(_tokenAmount > 0,"invalid token amount");
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        require(tokenBalance >= _tokenAmount,"token balance not enough");
        uint256 tokenAmountForRefReferrer = _tokenAmount * refReferrerPer / 100;
       // uint256 tokenAmountForReferrer = tokenBalance - tokenAmountForRefReferrer;
        IERC20(_token).transfer(refReferrer, tokenAmountForRefReferrer);
        IERC20(_token).transfer(referrer, _tokenAmount - tokenAmountForRefReferrer);
    }

   function withdrawETH(uint256 ethAmount) public payable onlyOwner {

        //payable(platform_wallet).transfer(ethAmount);
        Address.sendValue(payable(msg.sender),ethAmount);
    }


    function withdrawToken(address _tokenAddress, uint256 _Amount) public payable onlyOwner {

        IERC20(_tokenAddress).transfer(msg.sender, _Amount);

    }


    function changeRefReferrerPer(uint256 _newPer) public onlyOwner {
        
        require(_newPer <= 100,"invalid amount");
        refReferrerPer = _newPer;
        
    }
    function changeRefReferrerAddress(address _newAddress) public onlyOwner {
        
        require(refReferrer != _newAddress,"refReferrer address same as last");
        refReferrer = _newAddress;
        
    }

    function changeReferrerAddress(address _newRefAddress) public onlyOwner {
        
        require(referrer != _newRefAddress,"referrer address same as last");
        referrer = _newRefAddress;
        
    }


    function changeRefReferrerName(string memory _newRefReferrerName) public onlyOwner {
        
        refReferrerName = _newRefReferrerName;
        
    }
    
    function changeReferrerName(string memory _newRefName) public onlyOwner {
        
        refName = _newRefName;
        
    }
    function addAdmin(address _newAdmin) public onlyOwner {

        require(!admin[_newAdmin],"already admin");
        admin[_newAdmin] = true;

    }
    function removeAdmin(address _oldAdmin) public onlyOwner {

        require(admin[_oldAdmin],"address not admin");
        admin[_oldAdmin] = false;

    }
    function getRefCode() public view returns (string memory) {

        return refCode;


    }
    function getRefName() public view returns (string memory) {

        return refName;


    }
    function getReferrer() public view returns (address){

        return referrer;

    }
    function getRefReferrer() public view returns (address){

        return refReferrer;

    }
    receive() external payable {

    }
}