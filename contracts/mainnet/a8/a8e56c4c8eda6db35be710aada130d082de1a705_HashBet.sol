/**
 *Submitted for verification at Arbiscan.io on 2023-09-13
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/HashBetV.sol



pragma solidity ^0.8.0;






contract HashBet is Ownable, ReentrancyGuard {
    // Modulo is the number of equiprobable outcomes in a game:
    //  2 for coin flip
    //  6 for dice roll
    //  6*6 = 36 for double dice
    //  37 for roulette
    //  100 for hashroll
    uint constant MAX_MODULO = 100;

    // Modulos below MAX_MASK_MODULO are checked against a bit mask, allowing betting on specific outcomes. 
    // For example in a dice roll (modolo = 6), 
    // 000001 mask means betting on 1. 000001 converted from binary to decimal becomes 1.
    // 101000 mask means betting on 4 and 6. 101000 converted from binary to decimal becomes 40.
    // The specific value is dictated by the fact that 256-bit intermediate
    // multiplication result allows implementing population count efficiently
    // for numbers that are up to 42 bits, and 40 is the highest multiple of
    // eight below 42.
    uint constant MAX_MASK_MODULO = 40;
    
    // EVM BLOCKHASH opcode can query no further than 256 blocks into the
    // past. Given that settleBet uses block hash of placeBet as one of
    // complementary entropy sources, we cannot process bets older than this
    // threshold. On rare occasions dice2.win croupier may fail to invoke
    // settleBet in this timespan due to technical issues or extreme Ethereum
    // congestion; such bets can be refunded via invoking refundBet.
    uint constant BET_EXPIRATION_BLOCKS = 250;

    // Some deliberately invalid address to initialize the secret signer with.
    // Forces maintainers to invoke setSecretSigner before processing any bets.
    address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

     // This is a check on bet mask overflow. Maximum mask is equivalent to number of possible binary outcomes for maximum modulo.
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    // These are constants taht make O(1) population count in placeBet possible.
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;

    // Sum of all historical deposits and withdrawals. Used for calculating profitability. Profit = Balance - cumulativeDeposit + cumulativeWithdrawal
    uint public cumulativeDeposit;
    uint public cumulativeWithdrawal;

    // In addition to house edge, wealth tax is added every time the bet amount exceeds a multiple of a threshold.
    // For example, if wealthTaxIncrementThreshold = 3000 ether,
    // A bet amount of 3000 ether will have a wealth tax of 1% in addition to house edge.
    // A bet amount of 6000 ether will have a wealth tax of 2% in addition to house edge.
    uint public wealthTaxIncrementThreshold = 3000 ether;
    uint public wealthTaxIncrementPercent = 1;

    // The minimum and maximum bets.
    uint public minBetAmount = 0.01 ether;
    uint public maxBetAmount = 10000 ether;

    // max bet profit. Used to cap bets against dynamic odds.
    uint public maxProfit = 300000 ether;

    // Funds that are locked in potentially winning bets. Prevents contract from committing to new bets that it cannot pay out.
    uint public lockedInBets;

    // The minimum larger comparison value.
    uint public minOverValue = 1;

    // The maximum smaller comparison value.
    uint public maxUnderValue = 98;

    // The address corresponding to a private key used to sign placeBet commits.
    address public secretSigner;

    // Croupier account.
    address public croupier;

    // Info of each bet.
    struct Bet {
        // Wager amount in wei.
        uint amount;
        // Modulo of a game.
        uint8 modulo;
        // Number of winning outcomes, used to compute winning payment (* modulo/rollEdge),
        // and used instead of mask for games with modulo > MAX_MASK_MODULO.
        uint8 rollEdge;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint40 mask;
        // Block number of placeBet tx.
        uint placeBlockNumber;
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;
        // Status of bet settlement.
        bool isSettled;
        // Outcome of bet.
        uint outcome;
        // Win amount.
        uint winAmount;
        // Random number used to settle bet.
        uint randomNumber;
        // Keccak256 hash of some secret "reveal" random number.
        uint commit;
        // Comparison method.
        bool isLarger;
    }
    
    // Each bet is deducted dynamic
    uint public defaultHouseEdgePercent = 2;

    // Mapping from commits to all currently active & processed bets.
    mapping (uint => Bet) public bets;

    mapping(uint32 => uint32) public houseEdgePercents;

    // Events
    event BetPlaced(address indexed gambler, uint amount, uint8 indexed modulo, uint8 rollEdge, uint40 mask, uint commit, bool isLarger);
    event BetSettled(address indexed gambler, uint amount, uint8 indexed modulo, uint8 rollEdge, uint40 mask, uint commit, uint outcome, uint winAmount);
    event BetRefunded(address indexed gambler, uint amount);

    constructor () Ownable() {
        secretSigner = DUMMY_ADDRESS;
        croupier = DUMMY_ADDRESS;
        houseEdgePercents[2] = 1;
        houseEdgePercents[6] = 1;
        houseEdgePercents[36] = 1;
        houseEdgePercents[37] = 3;
        houseEdgePercents[100] = 5;
    }

     // Standard modifier on methods invokable only by contract owner.
    modifier onlyCroupier {
        require (msg.sender == croupier, "OnlyCroupier methods called by non-croupier.");
        _;
    }

    // Fallback payable function used to top up the bank roll.
    fallback() external payable {
        cumulativeDeposit += msg.value;
    }
    receive() external payable {
        cumulativeDeposit += msg.value;
    }

    // See comment for "secretSigner" variable.
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

    // Change the croupier address.
    function setCroupier(address newCroupier) external onlyOwner {
        croupier = newCroupier;
    }

    // See ETH balance.
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

        // Set default house edge percent
    function setDefaultHouseEdgePercent(uint _houseEdgePercent) external onlyOwner {
        require(
            _houseEdgePercent >= 1 && _houseEdgePercent <= 100,
            "houseEdgePercent must be a sane number"
        );
        defaultHouseEdgePercent = _houseEdgePercent;
    }

    // Set modulo house edge percent
    function setModuloHouseEdgePercent(uint32 _houseEdgePercent, uint32 modulo) external onlyOwner {
        require(
            _houseEdgePercent >= 1 && _houseEdgePercent <= 100,
            "houseEdgePercent must be a sane number"
        );
        houseEdgePercents[modulo] = _houseEdgePercent;
    }

    // Set min bet amount. minBetAmount should be large enough such that its house edge fee can cover the Chainlink oracle fee.
    function setMinBetAmount(uint _minBetAmount) external onlyOwner {
        minBetAmount = _minBetAmount * 1 gwei;
    }

    // Set max bet amount.
    function setMaxBetAmount(uint _maxBetAmount) external onlyOwner {
        require (_maxBetAmount < 5000000 ether, "maxBetAmount must be a sane number");
        maxBetAmount = _maxBetAmount;
    }

    // Set max bet reward. Setting this to zero effectively disables betting.
    function setMaxProfit(uint _maxProfit) external onlyOwner {
        require (_maxProfit < 50000000 ether, "maxProfit must be a sane number");
        maxProfit = _maxProfit;
    }

    // Set wealth tax percentage to be added to house edge percent. Setting this to zero effectively disables wealth tax.
    function setWealthTaxIncrementPercent(uint _wealthTaxIncrementPercent) external onlyOwner {
        wealthTaxIncrementPercent = _wealthTaxIncrementPercent;
    }

    // Set threshold to trigger wealth tax.
    function setWealthTaxIncrementThreshold(uint _wealthTaxIncrementThreshold) external onlyOwner {
        wealthTaxIncrementThreshold = _wealthTaxIncrementThreshold;
    }

    // Owner can withdraw funds not exceeding balance minus potential win prizes by open bets
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance, "Withdrawal amount larger than balance.");
        require (withdrawAmount <= address(this).balance - lockedInBets, "Withdrawal amount larger than balance minus lockedInBets");
        beneficiary.transfer(withdrawAmount);
        cumulativeWithdrawal += withdrawAmount;
    }

    function emitBetPlacedEvent(address gambler, uint amount, uint8 modulo, uint8 rollEdge, uint40 mask, uint commit, bool isLarger) private
    {
        // Record bet in event logs
        emit BetPlaced(gambler, amount, uint8(modulo), uint8(rollEdge), uint40(mask), commit, isLarger);
    }

    // Place bet
    function placeBet(uint betMask, uint modulo, uint commitLastBlock, uint commit, bool isLarger, bytes32 r, bytes32 s) external payable nonReentrant {

        Bet storage bet = bets[commit];
        require (bet.gambler == address(0), "Bet should be in a 'clean' state.");

        uint amount = msg.value;

        validateArguments(amount, betMask, modulo, commitLastBlock, commit, isLarger, r, s);

        uint rollEdge;
        uint mask;

        if (modulo <= MAX_MASK_MODULO) {
            // Small modulo games can specify exact bet outcomes via bit mask.
            // rollEdge is a number of 1 bits in this mask (population count).
            // This magic looking formula is an efficient way to compute population
            // count on EVM for numbers below 2**40. 
            rollEdge = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else {
            // Larger modulos games specify the right edge of half-open interval of winning bet outcomes.
            require (betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollEdge = betMask;
        }

        // Winning amount.
        uint possibleWinAmount = getDiceWinAmount(amount, modulo, rollEdge, isLarger);

        // Check whether contract has enough funds to accept this bet.
        require (lockedInBets + possibleWinAmount <= address(this).balance, "Unable to accept bet due to insufficient funds");

        // Update lock funds.
        lockedInBets += possibleWinAmount;

        // Store bet
        bet.amount=amount;
        bet.modulo=uint8(modulo);
        bet.rollEdge=uint8(rollEdge);
        bet.mask=uint40(mask);
        bet.placeBlockNumber=block.number;
        bet.gambler=payable(msg.sender);
        bet.isSettled=false;
        bet.outcome=0;
        bet.winAmount=possibleWinAmount;
        bet.randomNumber=0;
        bet.commit=commit;
        bet.isLarger=isLarger;

        // Record bet in event logs
        emitBetPlacedEvent(bet.gambler, amount, uint8(modulo), uint8(rollEdge), uint40(mask), commit, isLarger);
    }

    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(uint amount, uint modulo, uint rollEdge, bool isLarger) private view returns (uint winAmount) {
        require (0 < rollEdge && rollEdge <= modulo, "Win probability out of range.");
        uint houseEdge = amount * (getModuloHouseEdgePercent(uint32(modulo)) + getWealthTax(amount)) / 100;
        uint realRollEdge = rollEdge;
        if (modulo == MAX_MODULO && isLarger) {
            realRollEdge = MAX_MODULO - rollEdge - 1;
        }
        winAmount = (amount - houseEdge) * modulo / realRollEdge;

        // round down to multiple 1000Gweis
        winAmount = (winAmount / 1e12) * 1e12;

        uint maxWinAmount = amount + maxProfit;

        if(winAmount > maxWinAmount) {
            winAmount = maxWinAmount;
        }
    }

    // Get wealth tax 
    function getWealthTax(uint amount) private view returns (uint wealthTax) {
        wealthTax = amount / wealthTaxIncrementThreshold * wealthTaxIncrementPercent;
    }
    
    // This is the method used to settle 99% of bets. To process a bet with a specific
    // "commit", settleBet should supply a "reveal" number that would Keccak256-hash to
    // "commit". "blockHash" is the block hash of placeBet block as seen by croupier; it
    // is additionally asserted to prevent changing the bet outcomes on Ethereum reorgs.
    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;

        require (bet.gambler != address(0), "Bet should be in a 'bet' state.");

        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require (block.number > placeBlockNumber, "settleBet before placeBet");

        // Settle bet using reveal and blockHash as entropy sources.
        settleBetCommon(bet, reveal, blockHash);
    }

    // Common settlement code for settleBet & settleBetUncleMerkleProof.
    function settleBetCommon(Bet storage bet, uint reveal, bytes32 entropyBlockHash) private {
        // Fetch bet parameters into local variables (to save gas).
        uint amount = bet.amount;
        
        // Validation check
        require (amount > 0, "Bet does not exist."); // Check that bet exists
        require(bet.isSettled == false, "Bet is settled already"); // Check that bet is not settled yet

        // Fetch bet parameters into local variables (to save gas).
        uint modulo = bet.modulo;
        uint rollEdge = bet.rollEdge;
        address payable gambler = bet.gambler;
        bool isLarger = bet.isLarger;
        
        // The RNG - combine "reveal" and blockhash of placeBet using Keccak256. Miners
        // are not aware of "reveal" and cannot deduce it from "commit" (as Keccak256
        // preimage is intractable), and house is unable to alter the "reveal" after
        // placeBet have been mined (as Keccak256 collision finding is also intractable).
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));

        // Do a roll by taking a modulo of entropy. Compute winning amount.
        uint outcome = uint(entropy) % modulo;

        // Win amount if gambler wins this bet
        uint possibleWinAmount = bet.winAmount;

        // Actual win amount by gambler
        uint winAmount = 0;

        // Determine dice outcome.
        if (modulo <= MAX_MASK_MODULO) {
            // For small modulo games, check the outcome against a bit mask.
            if ((2 ** outcome) & bet.mask != 0) {
                winAmount = possibleWinAmount;
            }
        } else {
            // For larger modulos, check inclusion into half-open interval.
            if (isLarger){
                if (outcome > rollEdge) {
                    winAmount = possibleWinAmount;
                }
            }
            else{
                if (outcome < rollEdge) {
                    winAmount = possibleWinAmount;
                }
            }
            
        }

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = winAmount;
        bet.randomNumber = uint(entropy);
        bet.outcome = outcome;

        // Send win amount to gambler.
        if (bet.winAmount > 0) {
            gambler.transfer(bet.winAmount);
        }

        emitSettledEvent(bet);
    }

    function emitSettledEvent(Bet storage bet) private
    {
        uint amount = bet.amount;
        uint outcome = bet.outcome;
        uint winAmount = bet.winAmount;
        // Fetch bet parameters into local variables (to save gas).
        uint modulo = bet.modulo;
        uint rollEdge = bet.rollEdge;
        address payable gambler = bet.gambler;
        // Record bet settlement in event log.
        emit BetSettled(gambler, amount, uint8(modulo), uint8(rollEdge), bet.mask, bet.commit, outcome, winAmount);
    }

    // Return the bet in extremely unlikely scenario it was not settled by Chainlink VRF. 
    // In case you ever find yourself in a situation like this, just contact hashbet support.
    // However, nothing precludes you from calling this method yourself.
    function refundBet(uint commit) external nonReentrant payable {
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        // Validation check
        require (amount > 0, "Bet does not exist."); // Check that bet exists
        require (bet.isSettled == false, "Bet is settled already."); // Check that bet is still open
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Wait after placing bet before requesting refund.");

        uint possibleWinAmount = bet.winAmount;

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = amount;

        // Send the refund.
        bet.gambler.transfer(amount);

        // Record refund in event logs
        emit BetRefunded(bet.gambler, amount);
    }

    // Check arguments
    function validateArguments(uint amount, uint betMask, uint modulo, uint commitLastBlock, uint commit, bool isLarger, bytes32 r, bytes32 s) view private {
        // Validate input data.
        require (modulo == 2 || modulo == 6  || modulo == 36 || modulo == 37  || modulo == 100, "Modulo should be valid value.");
        require (amount >= minBetAmount && amount <= maxBetAmount, "Bet amount should be within range.");
        require (betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");
        
        // Check that commit is valid - it has not expired and its signature is valid.
        require (block.number <= commitLastBlock, "Commit has expired.");
        bytes32 signatureHash = keccak256(abi.encodePacked(betMask, modulo, commitLastBlock, commit, isLarger));
        require (secretSigner == ecrecover(signatureHash, 27, r, s), "ECDSA signature is not valid.");

        if (modulo > MAX_MASK_MODULO) {
            if (isLarger){
                require (betMask >= minOverValue && betMask <= modulo, "High modulo range, betMask must larger than minimum larger comparison value.");
            }
            else{
                require (betMask > 0 && betMask <= maxUnderValue, "High modulo range, betMask must smaller than maximum smaller comparison value.");
            }
        }
    }
    
    function getModuloHouseEdgePercent(uint32 modulo) internal view returns (uint32 houseEdgePercent)  {
        houseEdgePercent = houseEdgePercents[modulo];
        if(houseEdgePercent == 0){
            houseEdgePercent = uint32(defaultHouseEdgePercent);
        }
    }
}