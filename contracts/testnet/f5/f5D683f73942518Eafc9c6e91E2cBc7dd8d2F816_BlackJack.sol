// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";



pragma solidity >= 0.8.17;

interface RandomOracle {
    function showSeed() external view returns (uint256 seed);
}

library Random {
  function fetchSeed(RandomOracle oracle) internal view returns (uint256) {
    return oracle.showSeed();
  }

  
}

contract BlackJack is Ownable {
    using Random for RandomOracle;
     using SafeERC20 for IERC20;
    mapping (uint => uint) cardsPower;
    uint randNonce = 0;
    RandomOracle private random;
    IERC20 public chipz;
    ISwapRouter public immutable swapRouter;
    address public constant WETH9 = 0xB47e6A5f8b33b3F17603C83a0535A9dcD7E32681; //arb
    address public CHIPZ;
    uint24 public constant feeTier = 3000;


    constructor(address _oracle) {
        cardsPower[0] = 11; // aces
        cardsPower[1] = 2;
        cardsPower[2] = 3;
        cardsPower[3] = 4;
        cardsPower[4] = 5;
        cardsPower[5] = 6;
        cardsPower[6] = 7;
        cardsPower[7] = 8;
        cardsPower[8] = 9;
        cardsPower[9] = 10;
        cardsPower[10] = 10; // j
        cardsPower[11] = 10; // q
        cardsPower[12] = 10; // k

        random = RandomOracle(_oracle);
        minBet = 0.001 ether;
        maxBet = 0.005 ether;
        requiredHouseBankroll = 0.1 ether;
        autoWithdrawBuffer = 0.001 ether;
        swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    }


    uint public minBet;
    uint public maxBet;
    uint public requiredHouseBankroll; 
    uint public autoWithdrawBuffer; // only automatically withdraw if requiredHouseBankroll is exceeded by this amount
 



    mapping (address => bool) public isActive;
    mapping (address => bool) public isPlayerActive;
    mapping (address => uint) public betAmount;
    mapping (address => uint) public gamestatus; //1 = Player Turn, 2 = Player Blackjack!, 3 = Dealer Blackjack!, 4 = Push, 5 = Game Finished. Bets resolved.
    mapping (address => uint) public payoutAmount;
    mapping (address => uint) dealTime;
    mapping (address => uint) blackJackHouseProhibited;
    mapping (address => uint[]) playerCards;
    mapping (address => uint[]) houseCards;
    mapping (address => bool) playerExists; //check whether the player has played before, if so, he must have a playerHand

    event NewGame(address player, uint256 bet, bool result);
    

    //set chips address
    function setChipsAddress(address _address) public onlyOwner {
        chipz = IERC20(_address);
        CHIPZ = _address;
    }
    

    //set min bet
    function setMinBet(uint _minBet) public onlyOwner {
        minBet = _minBet;
    }

    //set max bet
    function setMaxBet(uint _maxBet) public onlyOwner {
        maxBet = _maxBet;
    }

    //set required house bankroll
    function setRequiredHouseBankroll(uint _requiredHouseBankroll) public onlyOwner {
        requiredHouseBankroll = _requiredHouseBankroll;
    }


    function card2PowerConverter(uint[] storage cards) internal view returns (uint) { //converts an array of cards to their actual power. 1 is 1 or 11 (Ace)
        uint powerMax = 0;
        uint aces = 0; //count number of aces
        uint power;
        for (uint i = 0; i < cards.length; i++) {
             power = cardsPower[(cards[i] + 13) % 13];
             powerMax += power;
             if (power == 11) {
                 aces += 1;
             }
        }
        if (powerMax > 21) { //remove 10 for each ace until under 21, if possible.
            for (uint i2=0; i2<aces; i2++) {
                powerMax-=10;
                if (powerMax <= 21) {
                    break;
                }
            }
        }
        return uint(powerMax);
    }
    
    function randgenNewHand() internal returns(uint,uint,uint) { //returns 3 numbers from 0-51.
        //If new hand, generate 3 cards. If not, generate just 1.
        randNonce = random.fetchSeed();
        uint a = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 52;
        randNonce++;
        uint b = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 52;
        randNonce++;
        uint c = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 52;
        return (a,b,c);
      }

    function randgen() internal returns(uint) { //returns number from 0-51.
        //If new hand, generate 3 cards. If not, generate just 1.
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 52; //range: 0-51
      }

    
    modifier requireHandActive(bool truth) {
        require(isActive[msg.sender] == truth);
        _;
    }

    modifier requirePlayerActive(bool truth) {
        require(isPlayerActive[msg.sender] == truth);
        _;
    }

    function _play() public payable { 
        if (playerExists[msg.sender]) {
            require(isActive[msg.sender] == false);
        }
        else {
            playerExists[msg.sender] = true;
        }
        require(msg.value >= minBet); 
        require(msg.value <= maxBet); 
        uint a; //generate 3 cards, 2 for player, 1 for the house
        uint b;
        uint c;
        (a,b,c) = randgenNewHand();
        gamestatus[msg.sender] = 1;
        payoutAmount[msg.sender] = 0;
        isActive[msg.sender] = true;
        isPlayerActive[msg.sender] = true;
        betAmount[msg.sender] = msg.value;
        dealTime[msg.sender] = block.timestamp;
        playerCards[msg.sender] = new uint[](0);
        playerCards[msg.sender].push(a);
        playerCards[msg.sender].push(b);
        houseCards[msg.sender] = new uint[](0);
        houseCards[msg.sender].push(c);
        isBlackjack();
        withdrawToOwnerCheck();

        //rewards chips for playing equal to bet amount
        chipz.transfer(msg.sender, msg.value);

    }

    function _Hit() public requireHandActive(true) requirePlayerActive(true) { //both the hand and player turn must be active in order to hit
        uint a=randgen(); //generate a new card
        playerCards[msg.sender].push(a);
        checkGameState();
    }

    function _Double() public requireHandActive(true) requirePlayerActive(true) payable { //both the hand and player turn must be active in order to hit
        require(msg.value == betAmount[msg.sender]); //require player to double bet
        uint a=randgen(); //generate a new card
        playerCards[msg.sender].push(a); //draw only one card allowed 
        isPlayerActive[msg.sender] = false; //stand as you can only double once
        betAmount[msg.sender] = betAmount[msg.sender] * 2; //double bet value
        checkGameState();
    }

    function _Stand() public requireHandActive(true) requirePlayerActive(true) { //both the hand and player turn must be active in order to stand
        isPlayerActive[msg.sender] = false; //Player ends their turn, now dealer's turn
        checkGameState();
    }

    function checkGameState() internal requireHandActive(true) { //checks game state, processing it as needed. Should be called after any card is dealt or action is made (eg: stand).
        //IMPORTANT: Make sure this function is NOT called in the event of a blackjack. Blackjack should calculate things separately
        if (isPlayerActive[msg.sender] == true) {
            uint handPower = card2PowerConverter(playerCards[msg.sender]);
            if (handPower > 21) { //player busted
                processHandEnd(false);
            }
            else if (handPower == 21) { //autostand. Ensure same logic in stand is used
                isPlayerActive[msg.sender] = false;
                dealerHit();
            }
            else if (handPower <21) {
                //do nothing, player is allowed another action
            }
        }
        else if (isPlayerActive[msg.sender] == false) {
            dealerHit();
        }

    }

    function dealerHit() internal requireHandActive(true) requirePlayerActive(false)  { //dealer hits after player ends turn legally. Nounces can be incrimented with hits until turn finished.
        uint[] storage houseCardstemp = houseCards[msg.sender];
        uint[] storage playerCardstemp = playerCards[msg.sender];

        uint tempCard;
        while (card2PowerConverter(houseCardstemp) < 17) { //keep hitting on the same block for everything under 17. Same block is fine for dealer due to Nounce increase
            //The house cannot cheat here since the player is forcing the NEXT BLOCK to be the source of randomness for all hits, and this contract cannot voluntarily skip blocks.
            tempCard = randgen();
            if (blackJackHouseProhibited[msg.sender] != 0) {
                while (cardsPower[(tempCard + 13) % 13] == blackJackHouseProhibited[msg.sender]) { //don't deal the first card as prohibited card
                    tempCard = randgen();
                }
                blackJackHouseProhibited[msg.sender] = 0;
                }
            houseCardstemp.push(tempCard);
        }
        //First, check if the dealer busted for an auto player win
        if (card2PowerConverter(houseCardstemp) > 21 ) {
            processHandEnd(true);
        }
        //If not, we do win logic here, since this is the natural place to do it (after dealer hitting). 3 Scenarios are possible... =>
        if (card2PowerConverter(playerCardstemp) == card2PowerConverter(houseCardstemp)) {
            //push, return bet
            payable(msg.sender).transfer(betAmount[msg.sender]);
            payoutAmount[msg.sender]=betAmount[msg.sender];
            gamestatus[msg.sender] = 4;
            isActive[msg.sender] = false; //let's declare this manually only here, since processHandEnd is not called. Not needed for other scenarios.
        }
        else if (card2PowerConverter(playerCardstemp) > card2PowerConverter(houseCardstemp)) {
            //player hand has more strength
            processHandEnd(true);
        }
        else {
            //only one possible scenario remains.. dealer hand has more strength
            processHandEnd(false);
        }
    }

    function processHandEnd(bool _win) internal { //hand is over and win is either true or false, now process it
        uint winAmount;
        if (_win == false) {
            //do nothing, as player simply lost
            winAmount = 0;
        }
        else if (_win == true) {
            winAmount = betAmount[msg.sender] * 2;
            payable(msg.sender).transfer(winAmount);
            payoutAmount[msg.sender]=winAmount;
        }
        gamestatus[msg.sender] = 5;
        isActive[msg.sender] = false;

        emit NewGame(msg.sender, winAmount, _win);
    }


    function isBlackjack() internal { //fill this function later to check both player and dealer for a blackjack after _play is called, then process
        //4 possibilities: dealer blackjack, player blackjack (paying 3:2), both blackjack (push), no blackjack
        //copy processHandEnd for remainder
        blackJackHouseProhibited[msg.sender]=0; //set to 0 incase it already has a value
        bool houseIsBlackjack = false;
        bool playerIsBlackjack = false;
        //First thing: For dealer check, ensure if dealer doesn't get blackjack they are prohibited from their first hit resulting in a blackjack
        uint housePower = card2PowerConverter(houseCards[msg.sender]); //read the 1 and only house card, if it's 11 or 10, then deal temporary new card for bj check
        if (housePower == 10 || housePower == 11) {
            uint _card = randgen();
            if (housePower == 10) {
                if (cardsPower[_card] == 11) {
                    //dealer has blackjack, process
                    houseCards[msg.sender].push(_card); //push card as record, since game is now over
                    houseIsBlackjack = true;
                }
                else {
                    blackJackHouseProhibited[msg.sender]=uint(11); //ensure dealerHit doesn't draw this powerMax
                }
            }
            else if (housePower == 11) {
                if (cardsPower[_card] == 10) { //all 10s
                    //dealer has blackjack, process
                    houseCards[msg.sender].push(_card);  //push card as record, since game is now over
                    houseIsBlackjack = true;
                }
                else{
                    blackJackHouseProhibited[msg.sender]=uint(10); //ensure dealerHit doesn't draw this powerMax
                }

            }
        }
        //Second thing: Check if player has blackjack
        uint playerPower = card2PowerConverter(playerCards[msg.sender]);
        if (playerPower == 21) {
            playerIsBlackjack = true;
        }
        //Third thing: Return all four possible outcomes: Win 1.5x, Push, Loss, or Nothing (no blackjack, continue game)
        if (playerIsBlackjack == false && houseIsBlackjack == false) {
            //do nothing. Call this first since it's the most likely outcome
        }
        else if (playerIsBlackjack == true && houseIsBlackjack == false) {
            //Player has blackjack, dealer doesn't, reward 1.5x bet (plus bet return)
            uint winAmount = betAmount[msg.sender] * 5/2;
            payable(msg.sender).transfer(winAmount);
            payoutAmount[msg.sender] = betAmount[msg.sender] * 5/2;
            gamestatus[msg.sender] = 2;
            isActive[msg.sender] = false;
        }
        else if (playerIsBlackjack == true && houseIsBlackjack == true) {
            //Both player and dealer have blackjack. Push - return bet only
            uint winAmountPush = betAmount[msg.sender];
            payable(msg.sender).transfer(winAmountPush);
            payoutAmount[msg.sender] = winAmountPush;
            gamestatus[msg.sender] = 4;
            isActive[msg.sender] = false;
        }
        else if (playerIsBlackjack == false && houseIsBlackjack == true) {
            //Only dealer has blackjack, player loses
            gamestatus[msg.sender] = 3;
            isActive[msg.sender] = false;
        }
    }

    function readCards() external view returns(uint[] memory ,uint[] memory) { //returns the cards in play, as an array of playercards, then houseCards
        return (playerCards[msg.sender],houseCards[msg.sender]);
    }

    function readPower() external view returns(uint, uint) { //returns current card power of player and house
        return (card2PowerConverter(playerCards[msg.sender]),card2PowerConverter(houseCards[msg.sender]));
    }

    function donateEther() public payable { //donate ether to the contract
        //do nothing
    }

    function withdrawToOwnerCheck() internal { //auto call this
        //Contract profit withdrawal to the current contract owner is disabled unless contract balance exceeds requiredHouseBankroll
        //If this condition is  met, requiredHouseBankroll must still always remain in the contract and cannot be withdrawn.
        uint houseBalance = address(this).balance;
        if (houseBalance > requiredHouseBankroll + autoWithdrawBuffer) { //see comments at top of contract
            uint permittedWithdraw = houseBalance - requiredHouseBankroll; //leave the required bankroll behind, withdraw the rest
            //payable(dividends).transfer(permittedWithdraw);
            swapWETHForChipz(permittedWithdraw);
        }

    }

    function swapWETHForChipz(uint256 amountIn) public returns (uint256 amountOut) {
        // Transfer the specified amount of WETH9 to this contract.
        //TransferHelper.safeTransferFrom(WETH9, msg.sender, address(this), amountIn);
        // Approve the router to spend WETH9.
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);
        // Create the params that will be used to execute the swap
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: CHIPZ,
                fee: feeTier,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}