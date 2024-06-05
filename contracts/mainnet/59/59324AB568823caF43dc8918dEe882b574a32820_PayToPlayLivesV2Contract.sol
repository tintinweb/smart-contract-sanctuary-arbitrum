/**
 *Submitted for verification at basescan.org on 2024-02-20
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: DeepShotContracts/Deepshot_V2_RevisedContracts/PayToPlayLivesV2.sol


pragma solidity ^0.8.19;




contract PayToPlayLivesV2Contract is ReentrancyGuard{
    using SafeMath for uint256;

    ////////////////////////////////////////////////////////////////
    // VARIABLES
    ////////////////////////////////////////////////////////////////

    address public PermissionedServerWallet = 0xD5123f4B3d14B27E74e2E0Fe943494ED53D7B945; //kill payments
    address public BotSpawnerWallet = 0x48eD1558A8435c664B2Fc4a6C0938283124567fc;
    address public TeamWallet = 0x8998F85603737687fAd85EEdF45f43E79ceb608b; //Address is used to store TeamFunds
    address public Erc20TokenAddress = 0xD5954c3084a1cCd70B4dA011E67760B8e78aeE84; //ARX 

    bool private _locked;

    mapping(address => uint256) public lives;
    mapping(address => uint256) public kills;
    mapping(address => uint256) public Revives;

    address public owner;

    uint256 public CostOfLives = 3 ether;  //5 ARX  for 1 life
    uint256 public CostOfBotKills = 1 ether; //1 ARX  for 1 life
    
    //25% OUT || 75% KILLS
    uint256 public ProtocolPercentageTake = 20;
    uint256 public PercentageForBots = 5; //this is less than the cost of bot lives (roughly 4 purchased = 1 bot) 
    uint256 public PercentageForKills = 75;

    event LivesPurchased(address indexed user, uint256 amount);
    event UserHasSpawned(address indexed user);
    event PlayerMadeAKill(address indexed user);
    event PlayerKilledABot(address indexed user);
    event BotKilledaPlayer(address indexed user);

    constructor() {
    owner = msg.sender;
    }

    ////////////////////////////////////////////////////////////////
    // MODIFIERS & OWNER/PERMISSIONED WALLET SET
    ////////////////////////////////////////////////////////////////

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier onlyPermissionedServerWallet() {
        require(msg.sender == PermissionedServerWallet, "Only the set Permissioned wallet can call this function");
        _;
    }
    modifier  BotPaymentWallet(){
        require(msg.sender == BotSpawnerWallet,"Only allow the bot spanwer wallet to pay for bot kills");
        _;
    }

    //-----------------------------------------------------------------------------------------------------

    function SetNewPermissionedServerWallet(address newAddr) public onlyOwner {
        PermissionedServerWallet = newAddr;
    }

    function SetNewTeamWallet(address newAddr) public onlyOwner {
        TeamWallet = newAddr;
    }
    
    function SetNewERC20TokenAddress(address newAddr) public onlyOwner {
        Erc20TokenAddress = newAddr;
    }
    
    function SetNewContractOwner(address newAddr) public onlyOwner {
        owner = newAddr;
    }
    
    function SetNewBotPaymentWallet(address newAddr) public onlyOwner {
        BotSpawnerWallet = newAddr;
    }
 
 
    modifier isGuardedReentrant() {
        require(!_locked, "Reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
    ////////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////////
    
    function withdrawToken(address tokenAddress) external onlyOwner {
       IERC20 token = IERC20(tokenAddress);
       uint256 balance = token.balanceOf(address(this));
       require(balance > 0, "No tokens to withdraw");
       token.transfer(owner, balance);
    }

    function withdrawErc20Tokens(address token) external onlyOwner {
      IERC20 erc20Token = IERC20(token);
      require(erc20Token.transfer(owner, erc20Token.balanceOf(address(this))), "Failed to withdraw ERC-20 tokens");
    }

    function withdrawGas() public  onlyOwner {
       payable(owner).transfer(address(this).balance);
    }

    function PurchaseLives(uint256 numberOfLivesToPurchase) external isGuardedReentrant {

        uint256 totalCost = numberOfLivesToPurchase * CostOfLives;
        require(IERC20(Erc20TokenAddress).balanceOf(msg.sender) >= totalCost, "Not enough ERC20 tokens to purchase lives");
        require(IERC20(Erc20TokenAddress).transferFrom(msg.sender, address(this), totalCost), "ERC20 transfer failed");

        uint256 amountForBots = totalCost * PercentageForBots / 100; // 5% default
        uint256 amountforTeam = totalCost * ProtocolPercentageTake / 100; // 20%
        uint256 amountPermissionedServerWallet = totalCost * PercentageForKills / 100; //75% Player Killed Player rewards.

        require(IERC20(Erc20TokenAddress).transfer(PermissionedServerWallet,amountPermissionedServerWallet),"ERC20 transfer to PermissionedServerWallet failed");
        require(IERC20(Erc20TokenAddress).transfer(BotSpawnerWallet, amountForBots), "ERC20 transfer to BotSpawnerWallet failed");
        require(IERC20(Erc20TokenAddress).transfer(TeamWallet, amountforTeam), "ERC20 transfer to TeamWallet failed");

        uint256 senderLives = lives[msg.sender];
        lives[msg.sender] = senderLives.add(numberOfLivesToPurchase);
        //Increase the number of lives for the sender
        emit LivesPurchased(msg.sender, numberOfLivesToPurchase);
    }

    function Player_Killed_Player(address _to) external onlyPermissionedServerWallet {  
        uint256 PayoutAmount = CostOfLives * PercentageForKills / 100; //75% Player Killed Player rewards.
        require(IERC20(Erc20TokenAddress).allowance(msg.sender, address(this)) >= PayoutAmount, "Allowance not enough");
        require(IERC20(Erc20TokenAddress).balanceOf(msg.sender) >= PayoutAmount, "Not Enough Funds to pay for Kill");
        IERC20(Erc20TokenAddress).transferFrom(msg.sender, _to, PayoutAmount);
        
        emit PlayerMadeAKill(_to);
    }

    function Bot_Killed_Player(address Killed) external onlyPermissionedServerWallet{

        uint256 PayoutAmount = CostOfLives * PercentageForKills / 100; //75% Player Killed Player rewards.
        // Ensure contract has enough allowance
        require(IERC20(Erc20TokenAddress).allowance(msg.sender, address(this)) >= PayoutAmount, "Allowance not enough");
        // Transfer ERC20 tokens
        require(IERC20(Erc20TokenAddress).balanceOf(msg.sender) >= PayoutAmount, "Not Enough Funds to pay for Kill");

        IERC20(Erc20TokenAddress).transferFrom(msg.sender, TeamWallet, PayoutAmount);

        emit BotKilledaPlayer(Killed);
    }

    function Player_Killed_Bot(address payable _to) external BotPaymentWallet {
        require(IERC20(Erc20TokenAddress).allowance(msg.sender, address(this)) >= CostOfBotKills, "Allowance not enough");
        require(IERC20(Erc20TokenAddress).balanceOf(msg.sender) >= CostOfBotKills, "Not Enough Funds to pay for Kill");
        
        IERC20(Erc20TokenAddress).transferFrom(msg.sender, _to, CostOfBotKills);
        emit PlayerKilledABot(_to);
    }
    
    function UserSpawned(address user) external onlyPermissionedServerWallet {
        require(lives[user] > 0, "User Has No Lives");
        lives[user] = lives[user].sub(1);
        Revives[user] = Revives[user].add(1);
        emit UserHasSpawned(user);
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    /////////////////////////////
    // ADJUST FEE SPLIT VALUES //
    /////////////////////////////
    
    function setCostOfLives(uint256 _newCost) public  onlyOwner {
        CostOfLives = _newCost;
    }
   
    function setCostOfBotKills(uint256 _newCost)public  onlyOwner{
       CostOfBotKills = _newCost;
    }
   
    function setProtocolPercentageTake(uint256 _newPercentage) public onlyOwner {
        ProtocolPercentageTake = _newPercentage;
    }

    function setPercentageForBots(uint256 _newPercentage) public onlyOwner {
        PercentageForBots = _newPercentage;
    }
    
    function setPercentageForKills(uint256 _newPercentage) public onlyOwner {
        PercentageForKills = _newPercentage;
    }
    ////////////////////////////
    // RETURN VALUE FUNCTIONS //
    ////////////////////////////
    function GetCostOfLives() public view returns (uint256) {
        return CostOfLives;
    }

    function HasLife(address user) public view returns (bool) {
        return lives[user] > 0;
    }

    function LivesCount(address user) public view returns (uint256) {
        return lives[user];
    }

    function RevivesCount(address user) public view returns (uint256) {
        return Revives[user];
    }

    function getCostOfLives() external view returns (uint256) {
        return CostOfLives;
    }

    function getProtocolPercentageTake() external view returns (uint256) {
        return ProtocolPercentageTake;
    }

    function getPercentageForBots() external view returns (uint256) {
        return PercentageForBots;
    }
}