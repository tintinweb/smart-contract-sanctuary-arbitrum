/**
 *Submitted for verification at Arbiscan on 2023-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract VRFConsumerBaseV2 {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private immutable vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    constructor(address _vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

interface VRFCoordinatorV2Interface {
    /**
     * @notice Get configuration relevant for making requests
     * @return minimumRequestConfirmations global min for request confirmations
     * @return maxGasLimit global max for request gas limit
     * @return s_provingKeyHashes list of registered key hashes
     */
    function getRequestConfig()
        external
        view
        returns (
            uint16,
            uint32,
            bytes32[] memory
        );

    /**
     * @notice Request a set of random words.
     * @param keyHash - Corresponds to a particular oracle job which uses
     * that key for generating the VRF proof. Different keyHash's have different gas price
     * ceilings, so you can select a specific one to bound your maximum per request cost.
     * @param subId  - The ID of the VRF subscription. Must be funded
     * with the minimum subscription balance required for the selected keyHash.
     * @param minimumRequestConfirmations - How many blocks you'd like the
     * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
     * for why you may want to request more. The acceptable range is
     * [minimumRequestBlockConfirmations, 200].
     * @param callbackGasLimit - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is
     * [0, maxGasLimit]
     * @param numWords - The number of uint256 random values you'd like to receive
     * in your fulfillRandomWords callback. Note these numbers are expanded in a
     * secure way by the VRFCoordinator from a single random value supplied by the oracle.
     * @return requestId - A unique identifier of the request. Can be used to match
     * a request to a response in fulfillRandomWords.
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     * @dev Note to fund the subscription, use transferAndCall. For example
     * @dev  LINKTOKEN.transferAndCall(
     * @dev    address(COORDINATOR),
     * @dev    amount,
     * @dev    abi.encode(subId));
     */
    function createSubscription() external returns (uint64 subId);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return balance - LINK balance of the subscription in juels.
     * @return reqCount - number of requests for this subscription, determines fee tier.
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(uint64 subId)
        external
        view
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        );

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner)
        external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     * @param to - Where to send the remaining LINK to
     */
    function cancelSubscription(uint64 subId, address to) external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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


interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

interface IERC721 {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract GenSlots is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // VRF settings
    uint64 s_subscriptionId;

    address vrfCoordinator = 0x41034678D6C633D8a95c75e1138A360a28bA15d1;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 public keyHash =
        0x08ba8f62ff6c40a58877a106147661db43bc58dabfb814793847a839aa03367f;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 public callbackGasLimit = 250000; //100k for mainnet

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 3;

    // Number of random numbers
    uint32 numWords = 1;

    event Spin(
        address indexed roller,
        uint256 indexed round,
        uint8[3] symbols,
        uint256 payout,
        bool isFreeSpin
    );

    IV3SwapRouter public immutable uniswapRouter;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    uint24 public poolFee = 3000; // Uniswap pool fee, default 0.3%
    uint256 public amountOutMin = 0; // Uniswap minimum output amount

    address public owner;

    uint256 public idsFulfilled;

    mapping(address => uint256[]) private roundsPlayed;

    Roll[] public rolls; // Array of all rolls in order

    mapping(uint256 => Roll) idToRoll; // Map each ID to a roll

    struct Roll {
        uint256 id; // id for VRF
        uint256 payout; // amount won
        uint256 round; // round number
        uint256 cost; // The net cost of the spin (exluding all fees)
        uint8[3] symbols; // symbols
        bool finished; // Spin completely finished
        bool isFreeSpin;
        bool isTokenSpin;
        address roller; // user address
    }

    /*
    0 - Best -> worst
    */
    uint8[][] private s_wheels = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8],
        [0, 1, 2, 3, 4, 5, 6, 7, 8],
        [0, 1, 2, 3, 4, 5, 6, 7, 8]
    ];

    uint256[] private s_symbolOdds = [
        1900,
        1800,
        1600,
        1400,
        1400,
        900,
        700,
        250,
        50
    ];
    uint256 public maxRelativePayout = 1000;
    uint256 public relativeJackpotPayout = 1000;
    uint256[] private s_payouts = [
        800,
        1500,
        4000,
        5000,
        10000,
        25000,
        40000,
        90000,
        100
    ];

    uint256 public sameSymbolOdds = 6000;

    // Precision for calculating the odds and payouts.
    uint256 public PRECISION = 10000;

    uint256 public prizePool = 0; // amount of tokens to win

    uint256 public minEthSpinPrice = 100000000000000;
    uint256 public maxEthSpinPrice = 10**18;
    uint256 public minTokenSpinPrice = 100 * 10**18;
    uint256 public maxTokenSpinPrice = 1000000 * 10**18;

    uint256 public freeSpinTokenPrice; // The token price that a free spin will emulate.

    uint256 public freeSpinTimeout;
    uint256 public freeSpinTier1MinTokenBalance = 1000000000 * 10**18;
    uint256 public freeSpinTier2MinTokenBalance = 2000000000 * 10**18;
    uint256 public freeSpinTier3MinTokenBalance = 3000000000 * 10**18;

    uint256 public constant maxSupplyFreeSpinTier1 = 200;
    uint256 public constant maxSupplyFreeSpinTier2 = 50;
    uint256 public constant maxSupplyFreeSpinTier3 = 25;

    // Roll fee division
    uint256 public vrfFee; // VRF fee amount in ETH
    uint256 public potFee;
    uint256 public teamFee;
    uint256[] private s_stakingFees;

    address payable public vrfFeeAddress; // Address that will receive the VRF fee
    address payable public teamAddress;
    address public immutable tokenAddress;
    address public freeSpinNFTAddress;
    address[] private s_stakingAddresses;

    bool public tokenSpinningEnabled = true;
    bool public ethSpinningEnabled = true;
    bool public freeSpinningEnabled = true;

    mapping(address => bool) public hasFreeSpin;
    mapping(address => uint256) public lastFreeSpinTimeAddress;
    mapping(uint256 => uint256) public lastFreeSpinTimeNFT;

    constructor(
        uint64 subscriptionId,
        address _token,
        address payable _teamAddress
    ) VRFConsumerBaseV2(vrfCoordinator) {
        owner = msg.sender;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        tokenAddress = _token;
        vrfFee = 100000000000000;
        potFee = 5000;
        teamFee = 5000;
        vrfFeeAddress = payable(owner);
        teamAddress = _teamAddress;
        uniswapRouter = IV3SwapRouter(
            0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
        ); // Change for mainnet to 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    }

    function tokenSpin(uint256 tokenSpinPrice) external payable{
        // Play with tokens
        require(tokenSpinningEnabled, "Token spinning disabled.");
        require(msg.value >= vrfFee, "Insufficient value.");
        require(tokenSpinPrice >= minTokenSpinPrice && tokenSpinPrice <= maxTokenSpinPrice, "Incorrect spin price.");

        vrfFeeAddress.transfer(msg.value);

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokenSpinPrice
        );

        uint256 prizePoolTokens = (tokenSpinPrice * potFee) / PRECISION;
        prizePool += prizePoolTokens;

        if(teamFee > 0){
            IERC20(tokenAddress).transfer(
                teamAddress,
                (tokenSpinPrice * teamFee) / PRECISION
            );
        }

        address[] memory stakingAddresses = s_stakingAddresses;
        uint256[] memory stakingFees = s_stakingFees;

        for (uint256 i; i < stakingAddresses.length; i++) {
            if(stakingFees[i] > 0){
                IERC20(tokenAddress).transfer(
                    stakingAddresses[i],
                    (tokenSpinPrice * stakingFees[i]) / PRECISION
                );
            }
        }

        spin(prizePoolTokens, false, true);
    }

    function ethSpin() external payable {
        // Play with eth
        uint256 ethSpinPrice = msg.value - vrfFee;
        require(ethSpinPrice >= minEthSpinPrice && ethSpinPrice <= maxEthSpinPrice, "Insufficient value to roll");
        require(tokenSpinningEnabled, "ETH spinning disabled.");

        vrfFeeAddress.transfer(vrfFee);

        uint256 teamFeeETH = (ethSpinPrice * teamFee) / PRECISION;

        if(teamFee > 0){
            teamAddress.transfer(teamFeeETH);
        }

        uint256 swapETH = ethSpinPrice - teamFeeETH;
        uint256 tokenBalanceBefore = IERC20(tokenAddress).balanceOf(
            address(this)
        );

        IV3SwapRouter.ExactInputSingleParams memory params =
            IV3SwapRouter.ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: tokenAddress,
                fee: poolFee,
                recipient: address(this),
                amountIn: swapETH,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 swappedTokens = uniswapRouter.exactInputSingle{ value: swapETH }(params);

        address[] memory stakingAddresses = s_stakingAddresses;
        uint256[] memory stakingFees = s_stakingFees;

        for (uint256 i; i < stakingAddresses.length; i++) {
            if(stakingFees[i] > 0){
                IERC20(tokenAddress).transfer(
                    stakingAddresses[i],
                    (swappedTokens * stakingFees[i]) / (PRECISION - teamFee)
                );
            }
        }

        uint256 prizePoolTokens = IERC20(tokenAddress).balanceOf(
            address(this)
        ) - tokenBalanceBefore;
        prizePool += prizePoolTokens;

        spin(prizePoolTokens, false, false);
    }

    function freeSpin() external payable {
        require(hasFreeSpin[msg.sender] == true, "Free spin not available.");
        require(freeSpinningEnabled, "Free spinning disabled.");
        require(msg.value >= vrfFee, "Insufficient value.");

        hasFreeSpin[msg.sender] = false;
        vrfFeeAddress.transfer(msg.value);
        spin(freeSpinTokenPrice, true, true);
    }

    // Assumes the subscription is funded sufficiently.
    function spin(
        uint256 cost,
        bool isFreeSpin,
        bool isTokenSpin
    ) internal {
        // Will revert if subscription is not set and funded.
        uint256 id = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        idToRoll[id].round = rolls.length;
        idToRoll[id].roller = msg.sender;
        idToRoll[id].id = id;
        idToRoll[id].cost = cost;
        idToRoll[id].finished = false;
        idToRoll[id].isFreeSpin = isFreeSpin;
        idToRoll[id].isTokenSpin = isTokenSpin;

        roundsPlayed[msg.sender].push(rolls.length);

        // Push roll to master roll array
        rolls.push(idToRoll[id]);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint8 symbol = 0;
        uint8[] memory wheel = s_wheels[0];
        uint256[] memory _symbolOdds = s_symbolOdds;
        uint256 oddsCounter = _symbolOdds[0];
        uint256 randomNumber = randomWords[0];
        for (uint8 i; i < _symbolOdds.length; i++) {
            if ((randomNumber % PRECISION) + 1 <= oddsCounter) {
                symbol = wheel[i];
                break;
            } else {
                oddsCounter += _symbolOdds[i + 1];
            }
        }

        idToRoll[requestId].symbols[0] = symbol;
        if (
            (uint256(keccak256(abi.encode(randomNumber, 1))) % PRECISION) + 1 <=
            sameSymbolOdds
        ) {
            idToRoll[requestId].symbols[1] = symbol;
        } else {
            idToRoll[requestId].symbols[1] = wheel[
                uint256(keccak256(abi.encode(randomNumber, 2))) % wheel.length
            ];
        }

        if (
            (uint256(keccak256(abi.encode(randomNumber, 3))) % PRECISION) + 1 <=
            sameSymbolOdds
        ) {
            idToRoll[requestId].symbols[2] = symbol;
        } else {
            idToRoll[requestId].symbols[2] = wheel[
                uint256(keccak256(abi.encode(randomNumber, 4))) % wheel.length
            ];
        }

        idsFulfilled++;

        game(requestId);
    }

    function game(uint256 requestId) internal {
        if (
            idToRoll[requestId].symbols[0] == idToRoll[requestId].symbols[1] &&
            idToRoll[requestId].symbols[1] == idToRoll[requestId].symbols[2]
        ) {
            // all 3 match

            uint256 prize = calculatePrize(
                idToRoll[requestId].symbols[0],
                idToRoll[requestId].cost
            );
            idToRoll[requestId].payout = prize;
            IERC20(tokenAddress).transfer(idToRoll[requestId].roller, prize);
            prizePool -= prize; // decrease prizepool to prevent giving away already won tokens
        }

        idToRoll[requestId].finished = true;
        rolls[idToRoll[requestId].round] = idToRoll[requestId]; // copy
        emit Spin(
            idToRoll[requestId].roller,
            idToRoll[requestId].round,
            idToRoll[requestId].symbols,
            idToRoll[requestId].payout,
            idToRoll[requestId].isFreeSpin
        );
    }

    /*
    Get round info and symbols
    */

    function symbolsOfRound(uint256 _round)
        public
        view
        returns (uint8[3] memory)
    {
        return (rolls[_round].symbols);
    }

    function roundInfo(uint256 _round) public view returns (Roll memory) {
        return (rolls[_round]);
    }

    // Return multiple round info
    function getMultipleRoundInfo(uint256[] memory rounds) public view returns (Roll[] memory) {
        Roll[] memory subset = new Roll[](rounds.length);

        for (uint256 i; i < rounds.length; ) {
            subset[i] = rolls[rounds[i]];
            unchecked {++i;}
        }

        return subset;
    }

    function getRoundsPlayed(address player)
        public
        view
        returns (uint256[] memory)
    {
        return (roundsPlayed[player]);
    }

    // Return the total amount of rounds from a player.
    function getTotalRoundsPlayed(address player) public view returns (uint256) {
        return roundsPlayed[player].length;
    }

    function getTotalRoundsPlayed() public view returns (uint256) {
        return (rolls.length);
    }

    // Return only the last x amount of rounds by a player.
    function getLastRoundsPlayed(address player, uint256 amount) public view returns (uint256[] memory) {
        if(roundsPlayed[player].length <= amount){
            return roundsPlayed[player];
        }

        uint256[] memory subset = new uint256[](amount);
        uint256 startIndex = roundsPlayed[player].length - amount;

        for (uint256 i; i < amount; ) {
            subset[i] = roundsPlayed[player][i+startIndex];
            unchecked {++i;}
        }

        return subset;
    }

    function getSymbolsCount() public view returns (uint256) {
        return (s_wheels[0].length);
    }

    function getStakingAddressesCount() public view returns (uint256) {
        return (s_stakingAddresses.length);
    }

    function getWheels() public view returns (uint8[][] memory){
        return s_wheels;
    }

    function getSymbolOdds() public view returns (uint256[] memory){
        return s_symbolOdds;
    }

    function getPayouts() public view returns (uint256[] memory){
        return s_payouts;
    }

    function getStakingAddresses() public view returns (address[] memory){
        return s_stakingAddresses;
    }

    function getStakingFees() public view returns (uint256[] memory){
        return s_stakingFees;
    }

    /* 
    Prize clacluations and payout 
    */

    function totalWinnings(address player) public view returns (uint256) {
        // Total winnings of contestant, including already paid
        uint256 payout;
        uint256[] memory _rounds = roundsPlayed[player];

        for (uint256 i; i < _rounds.length; i++) {
            payout += rolls[_rounds[i]].payout;
        }

        return (payout);
    }

    function calculatePrize(uint8 _symbol, uint256 amountPaid)
        internal
        view
        returns (uint256)
    {
        uint256 prize;

        if (_symbol == s_wheels[0].length - 1) {
            prize = (prizePool * relativeJackpotPayout) / PRECISION;
        } else {
            uint256 currentMaxPayout = (prizePool * maxRelativePayout) /
                PRECISION;
            prize = (amountPaid * s_payouts[_symbol]) / PRECISION;
            prize = prize > currentMaxPayout ? currentMaxPayout : prize;
        }

        return prize;
    }

    function addTokensToPot(uint256 amount) public {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        prizePool += amount;
    }

    /*
    Setters
    */

    function setSubscriptionId(uint64 subscriptionId) public onlyOwner {
        s_subscriptionId = subscriptionId;
    }

    function setCallbackGasLimit(uint32 gas) public onlyOwner {
        callbackGasLimit = gas;
    }

    function setCallbackRequestConfirmations(
        uint16 _callbackRequestConfirmations
    ) public onlyOwner {
        requestConfirmations = _callbackRequestConfirmations;
    }

    function setVrfKeyHash(bytes32 _keyHash) public onlyOwner {
        keyHash = _keyHash;
    }

    function setUniswapPoolFee(uint24 _poolFee) public onlyOwner{
        poolFee = _poolFee;
    }

    function setAmountOutMin(uint256 _amountOutMin) public onlyOwner{
        amountOutMin = _amountOutMin;
    }

    function setSymbolOdds(uint256[] memory _symbolOdds) public onlyOwner {
        s_symbolOdds = _symbolOdds;
    }

    function setSameSymbolOdds(uint256 _sameSymbolOdds) public onlyOwner {
        require(_sameSymbolOdds <= PRECISION, "Percentage too big.");
        sameSymbolOdds = _sameSymbolOdds;
    }

    function setPayouts(uint256[] memory _payouts) public onlyOwner {
        // Set the payout % of each symbol. Also can add new symbols.
        s_payouts = _payouts;
    }

    function setMinEthSpinPrice(uint256 _minEthSpinPrice) public onlyOwner {
        require(_minEthSpinPrice < maxEthSpinPrice, "Price too high.");
        minEthSpinPrice = _minEthSpinPrice;
    }

    function setMaxEthSpinPrice(uint256 _maxEthSpinPrice) public onlyOwner {
        require(_maxEthSpinPrice > minEthSpinPrice, "Price too low.");
        maxEthSpinPrice = _maxEthSpinPrice;
    }

    function setMinTokenSpinPrice(uint256 _minTokenSpinPrice) public onlyOwner {
        require(_minTokenSpinPrice < maxTokenSpinPrice, "Price too high.");
        minTokenSpinPrice = _minTokenSpinPrice;
    }

    function setMaxTokenSpinPrice(uint256 _maxTokenSpinPrice) public onlyOwner {
        require(_maxTokenSpinPrice > minTokenSpinPrice, "Price too low.");
        maxTokenSpinPrice = _maxTokenSpinPrice;
    }

    function setFreeSpinTokenPrice(uint256 _freeSpinTokenPrice) public onlyOwner {
        freeSpinTokenPrice = _freeSpinTokenPrice;
    }

    function setMaxRelativePayout(uint256 _maxRelativePayout) public onlyOwner {
        // Set the max payout
        require(_maxRelativePayout <= PRECISION, "Percentage too big.");
        maxRelativePayout = _maxRelativePayout;
    }

    function setRelativeJackpotPayout(uint256 _relativeJackpotPayout) public onlyOwner {
        // Set the jackpot payout
        require(_relativeJackpotPayout <= PRECISION, "Percentage too big.");
        relativeJackpotPayout = _relativeJackpotPayout;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function setWheels(uint8[][] memory _wheels) public onlyOwner {
        // Set the number of each symbol per wheel.
        s_wheels = _wheels;
    }

    function setPrizePool(uint256 _prizePool) public onlyOwner {
        // Set number of tokens to be won. Must have desired amount deposited.
        require(
            _prizePool <= IERC20(tokenAddress).balanceOf(address(this)),
            "Not enough tokens deposited."
        );
        prizePool = _prizePool;
    }

    function setTokenSpinningEnabled(bool _tokenSpinningEnabled)
        public
        onlyOwner
    {
        // Enable or disable spinning with tokens
        tokenSpinningEnabled = _tokenSpinningEnabled;
    }

    function setEthSpinningEnabled(bool _ethSpinningEnabled) public onlyOwner {
        // Enable or disable spinning with ETH
        ethSpinningEnabled = _ethSpinningEnabled;
    }

    function setFreeSpinningEnabled(bool _freeSpinningEnabled) public onlyOwner {
        // Enable or disable free spins
        freeSpinningEnabled = _freeSpinningEnabled;
    }

    function setVrfFee(uint256 _vrfFee) public onlyOwner {
        vrfFee = _vrfFee;
    }

    function setAllFees(
        uint256 _potFee,
        uint256 _teamFee,
        address[] memory stakingAddresses,
        uint256[] memory stakingFees
    ) public onlyOwner {
        require(
            stakingAddresses.length == stakingFees.length,
            "The amount of staking addresses must equal the amount of staking fees."
        );
        uint256 stakingFeesSum = 0;
        for (uint256 i; i < stakingFees.length; i++) {
            stakingFeesSum += stakingFees[i];
        }
        require(
            _potFee + _teamFee + stakingFeesSum == PRECISION,
            "Total fees must equal 100%."
        );
        potFee = _potFee;
        teamFee = _teamFee;
        s_stakingAddresses = stakingAddresses;
        s_stakingFees = stakingFees;
    }

    function setVrfFeeAddress(address _vrfFeeAddress) public onlyOwner {
        vrfFeeAddress = payable(_vrfFeeAddress);
    }

    function setTeamAddress(address _newTeamAddress) public onlyOwner {
        teamAddress = payable(_newTeamAddress);
    }

    function setFreeSpinNFTAddress(address _freeSpinNFTAddress)
        public
        onlyOwner
    {
        freeSpinNFTAddress = _freeSpinNFTAddress;
    }

    function setFreeSpinTimeout(uint256 timeout) public onlyOwner {
        freeSpinTimeout = timeout;
    }

    function setFreeSpinTier1MinTokenBalance(
        uint256 _freeSpinTier1MinTokenBalance
    ) public onlyOwner {
        freeSpinTier1MinTokenBalance = _freeSpinTier1MinTokenBalance;
    }

    function setFreeSpinTier2MinTokenBalance(
        uint256 _freeSpinTier2MinTokenBalance
    ) public onlyOwner {
        freeSpinTier2MinTokenBalance = _freeSpinTier2MinTokenBalance;
    }

    function setFreeSpinTier3MinTokenBalance(
        uint256 _freeSpinTier3MinTokenBalance
    ) public onlyOwner {
        freeSpinTier3MinTokenBalance = _freeSpinTier3MinTokenBalance;
    }

    function claimFreeSpinFromNFT(uint256 tokenId) public {
        require(
            IERC721(freeSpinNFTAddress).ownerOf(tokenId) == msg.sender,
            "User doesn't own the NFT."
        );
        require(!hasFreeSpin[msg.sender], "User already has a free spin.");
        require(
            lastFreeSpinTimeAddress[msg.sender] + freeSpinTimeout <
                block.timestamp,
            "User was given a free spin recently."
        );
        require(
            lastFreeSpinTimeNFT[tokenId] + freeSpinTimeout < block.timestamp,
            "NFT was given a free spin recently."
        );

        if (tokenId <= maxSupplyFreeSpinTier1) {
            require(
                IERC20(tokenAddress).balanceOf(msg.sender) >=
                    freeSpinTier1MinTokenBalance,
                "User has insufficient token balance."
            );
        } else if (tokenId <= maxSupplyFreeSpinTier1 + maxSupplyFreeSpinTier2) {
            require(
                IERC20(tokenAddress).balanceOf(msg.sender) >=
                    freeSpinTier2MinTokenBalance,
                "User has insufficient token balance."
            );
        } else {
            require(
                IERC20(tokenAddress).balanceOf(msg.sender) >=
                    freeSpinTier3MinTokenBalance,
                "User has insufficient token balance."
            );
        }

        lastFreeSpinTimeAddress[msg.sender] = block.timestamp;
        lastFreeSpinTimeNFT[tokenId] = block.timestamp;
        hasFreeSpin[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    receive() external payable {}
}