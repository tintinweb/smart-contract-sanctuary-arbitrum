/**
 *Submitted for verification at Arbiscan on 2023-04-14
*/

// SPDX-License-Identifier: MIT

// File: @api3/airnode-protocol/contracts/rrp/interfaces/IAirnodeRrpV0.sol


pragma solidity ^0.8.0;


interface IAirnodeRrpV0 {
    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);
}

// File: @api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol


pragma solidity ^0.8.0;


/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequesterV0 {
    IAirnodeRrpV0 public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrpV0(_airnodeRrp);
        IAirnodeRrpV0(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
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

// IUniswapV2Router01.sol
interface IUniswapV2Router01 {
  function WETH() external pure returns (address);
}


// ICamelotRouter.sol
interface ICamelotRouter is IUniswapV2Router01 {
  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external payable;
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

contract GenSlots is RrpRequesterV0 {
    event RequestedUint256(bytes32 indexed requestId);
    event ReceivedUint256(bytes32 indexed requestId, uint256 response);
    event Spin(address indexed roller, uint256 indexed round, uint8[3] symbols, uint256 payout, bool isFreeSpin);

    address public airnode;
    bytes32 public endpointIdUint256;
    address public sponsorWallet;

    ICamelotRouter camelotRouter;

    address owner;

    uint256 public idsFulfilled;

    mapping (address => uint256[]) private roundsPlayed;
 
    Roll[] public rolls; // Array of all rolls in order

    mapping (bytes32 => Roll) idToRoll; // Map each ID to a roll

    struct Roll{
        bytes32 id; // id for VRF
        uint256 payout; // amount won
        uint256 round; // round number
        uint256 cost;
        uint8[3] symbols; // symbols
        bool finished; // Spin completely finished
        bool isFreeSpin;
        bool isTokenSpin;
        address roller; // user address 
    }

    /*
    0 - Best -> worst
    */
    uint8[][] s_wheels = [[0,1,2,3,4,5,6,7,8],
                        [0,1,2,3,4,5,6,7,8],
                        [0,1,2,3,4,5,6,7,8]];

    uint256[] s_symbolOdds = [1900, 1800, 1600, 1400, 1400, 900, 700, 250, 50];
    uint256 public maxRelativePayout = 1000;
    uint256[] s_payouts = [800, 1500, 4000, 5000, 10000, 25000, 40000, 90000, 100];

    uint256 public sameSymbolOdds = 6000;

    uint256 public prizePool = 0; // amount of tokens to win

    uint256 public ethSpinPrice;
    uint256 public tokenSpinPrice;

    uint256 public freeSpinTimeout;
    uint256 public freeSpinTier1MinTokenBalance = 1000000000 * 10**18;
    uint256 public freeSpinTier2MinTokenBalance = 2000000000 * 10**18;
    uint256 public freeSpinTier3MinTokenBalance = 3000000000 * 10**18;

    uint256 public constant maxSupplyFreeSpinTier1 = 200;
    uint256 public constant maxSupplyFreeSpinTier2 = 50;
    uint256 public constant maxSupplyFreeSpinTier3 = 25;

    // Roll fee division
    uint256 public potFee;
    uint256 public teamFee;
    uint256[] public s_stakingFees;

    address payable public teamAddress;
    address public immutable tokenAddress;
    address public freeSpinNFTAddress;
    address[] public s_stakingAddresses;

    bool public tokenSpinningEnabled = true;

    mapping (address => bool) public freeSpin;
    mapping (address => uint256) public lastFreeSpinTimeAddress;
    mapping (uint256 => uint256) public lastFreeSpinTimeNFT;

    constructor(address _airnodeRrp, address _token, address payable _teamAddress) RrpRequesterV0(_airnodeRrp) {
        owner = msg.sender;
        tokenAddress = _token;
        potFee = 5000;
        teamFee = 5000;
        teamAddress = _teamAddress;
        camelotRouter = ICamelotRouter(0xA91527e5a4CE620e5a18728e52572769DcEcdb99); // Change for mainnet to 0x10ED43C718714eb63d5aA57B78B54704E256024E
    }

    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256,
        address _sponsorWallet
    ) external onlyOwner {
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        sponsorWallet = _sponsorWallet;
    }

    function tokenSpin() public { // Play with tokens
        require(tokenSpinningEnabled, "Token spinning disabled.");

        if(freeSpin[msg.sender]){
            freeSpin[msg.sender] = false;
            spin(tokenSpinPrice, true, true);
        }else{
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenSpinPrice);

            uint256 prizePoolTokens = tokenSpinPrice * potFee / 10000;
            prizePool += prizePoolTokens;
            IERC20(tokenAddress).transfer(teamAddress, tokenSpinPrice * teamFee / 10000);

            address[] memory stakingAddresses = s_stakingAddresses;
            uint256[] memory stakingFees = s_stakingFees;

            for(uint256 i; i < stakingAddresses.length; i++){
                IERC20(tokenAddress).transfer(stakingAddresses[i], tokenSpinPrice * stakingFees[i] / 10000);
            }

            spin(prizePoolTokens, false, true);
        }
    }

    function ethSpin() public payable{ // Play with eth
        require(msg.value >= ethSpinPrice, "Insufficient value to roll");

        uint256 teamFeeETH = ethSpinPrice * teamFee / 10000;
        teamAddress.transfer(teamFeeETH);

        uint256 swapETH = msg.value - teamFeeETH;

        address[] memory path = new address[](2);
        path[0] = camelotRouter.WETH();
        path[1] = tokenAddress;
        uint deadline = block.timestamp + 180;
        uint256 tokenBalanceBefore = IERC20(tokenAddress).balanceOf(address(this));
        camelotRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapETH}(0, path, address(this), address(0), deadline);
        uint256 swappedTokens = IERC20(tokenAddress).balanceOf(address(this)) - tokenBalanceBefore;

        address[] memory stakingAddresses = s_stakingAddresses;
        uint256[] memory stakingFees = s_stakingFees;

        for(uint256 i; i < stakingAddresses.length; i++){
            IERC20(tokenAddress).transfer(stakingAddresses[i], swappedTokens * stakingFees[i] / (10000 - potFee));
        }

        uint256 prizePoolTokens = IERC20(tokenAddress).balanceOf(address(this)) - tokenBalanceBefore;
        prizePool += prizePoolTokens;
        spin(prizePoolTokens, false, false);
    }

    // Assumes the subscription is funded sufficiently.
    function spin(uint256 cost, bool isFreeSpin, bool isTokenSpin) internal {        
        bytes32 id = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillUint256.selector,
            ""
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
    
    function fulfillUint256(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp{
        require(
            idToRoll[requestId].finished == false,
            "Request ID not known"
        );

        uint8 symbol = 0;
        uint8[] memory wheel = s_wheels[0];
        uint256[] memory _symbolOdds = s_symbolOdds;
        uint256 oddsCounter = _symbolOdds[0];
        uint256 randomNumber = abi.decode(data, (uint256));
        for(uint8 i; i < _symbolOdds.length; i++){
            if((randomNumber % 10000) + 1 <= oddsCounter){
                symbol = wheel[i];
                break;
            }else{
                oddsCounter += _symbolOdds[i+1];
            }
        }

        idToRoll[requestId].symbols[0] = symbol;
        if((uint256(keccak256(abi.encode(randomNumber, 1))) % 10000) + 1 <= sameSymbolOdds){
            idToRoll[requestId].symbols[1] = symbol;
        }else{
            idToRoll[requestId].symbols[1] = wheel[uint256(keccak256(abi.encode(randomNumber, 2))) % wheel.length];
        }

        if((uint256(keccak256(abi.encode(randomNumber, 3))) % 10000) + 1 <= sameSymbolOdds){
            idToRoll[requestId].symbols[2] = symbol;
        }else{
            idToRoll[requestId].symbols[2] = wheel[uint256(keccak256(abi.encode(randomNumber, 4))) % wheel.length];
        }

        

        idsFulfilled++;
        
        game(requestId);
    }

    function game(bytes32 requestId) internal { 
        if(idToRoll[requestId].symbols[0] == idToRoll[requestId].symbols[1] &&
            idToRoll[requestId].symbols[1] == idToRoll[requestId].symbols[2]) { // all 3 match

            uint256 prize = calculatePrize(idToRoll[requestId].symbols[0], idToRoll[requestId].cost);
            idToRoll[requestId].payout = prize;
            IERC20(tokenAddress).transfer(idToRoll[requestId].roller, prize);
            prizePool -= prize; // decrease prizepool to prevent giving away already won tokens
        }
        
        idToRoll[requestId].finished = true;
        rolls[idToRoll[requestId].round] = idToRoll[requestId]; // copy
        emit Spin(idToRoll[requestId].roller, idToRoll[requestId].round, idToRoll[requestId].symbols, idToRoll[requestId].payout, idToRoll[requestId].isFreeSpin);
    }

    /*
    Get round info and symbols
    */

    function symbolsOfRound(uint256 _round) public view returns(uint8[3] memory){
        return(rolls[_round].symbols);
    }

    function roundInfo(uint256 _round) public view returns(Roll memory) {
        return(rolls[_round]);
    }

    function getRoundsPlayed (address player) public view returns(uint256[] memory) {
        return(roundsPlayed[player]);
    }

    function getTotalRoundsPlayed() public view returns(uint256){
        return(rolls.length);
    }

    /* 
    Prize clacluations and payout 
    */
    
    function totalWinnings(address player) public view returns(uint256){ // Total winnings of contestant, including already paid
        uint256 payout;
        uint256[] memory _rounds = roundsPlayed[player];

        for(uint256 i; i < _rounds.length; i++){
            payout += rolls[_rounds[i]].payout;
        }

        return(payout);
    }

    function calculatePrize(uint8 _symbol, uint256 amountPaid) public view returns(uint256) {
        uint256 currentMaxPayout = prizePool * maxRelativePayout / 10000;
        uint256 prize = amountPaid * s_payouts[_symbol] / 10000;
        prize = prize > currentMaxPayout ? currentMaxPayout : prize;
        prize = _symbol == s_wheels[0].length - 1 ? currentMaxPayout : prize; // jackpot
        return prize;
    }

    function addTokensToPot(uint256 amount) public {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        prizePool += amount;
    }

    /*
    Setters
    */

    function setSymbolOdds(uint256[] memory _symbolOdds) public onlyOwner {
        s_symbolOdds = _symbolOdds;
    }

    function setSameSymbolOdds(uint256 _sameSymbolOdds) public onlyOwner {
        sameSymbolOdds = _sameSymbolOdds;
    }

    function setPayouts(uint256[] memory _payouts) public onlyOwner { // Set the payout % of each symbol. Also can add new symbols.
        s_payouts = _payouts;
    }

    function setEthSpinPrice(uint256 _ethSpinPrice) public onlyOwner {
        ethSpinPrice = _ethSpinPrice;
    }

    function setTokenSpinPrice(uint256 _tokenSpinPrice) public onlyOwner { // Set price of a spin
        tokenSpinPrice = _tokenSpinPrice;
    }

    function setMaxRelativePayout(uint256 _maxRelativePayout) public onlyOwner { // Set the max jackpot
        maxRelativePayout = _maxRelativePayout;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function setWheels(uint8[][] memory _wheels) public onlyOwner { // Set the number of each symbol per wheel.
        s_wheels = _wheels;
    }

    function setPrizePool(uint256 _prizePool) public onlyOwner { // Set number of tokens to be won. Must have desired amount deposited.
        require(_prizePool <= IERC20(tokenAddress).balanceOf(address(this)), "Not enough tokens deposited.");
        prizePool = _prizePool;
    }

    function setTokenSpinningEnabled(bool _tokenSpinningEnabled) public onlyOwner { // Enable or disable spinning with tokens
        tokenSpinningEnabled = _tokenSpinningEnabled;
    }

    function setAllFees(uint256 _potFee, uint256 _teamFee, address[] memory stakingAddresses, uint256[] memory stakingFees) public onlyOwner {
        require(stakingAddresses.length == stakingFees.length, "The amount of staking addresses must equal the amount of staking fees.");
        uint256 stakingFeesSum = 0;
        for(uint256 i; i < stakingFees.length; i++){
            stakingFeesSum += stakingFees[i];
        }
        require(_potFee + _teamFee + stakingFeesSum == 10000, "Total fees must equal 100%.");
        potFee = _potFee;
        teamFee = _teamFee;
        s_stakingAddresses = stakingAddresses;
        s_stakingFees = stakingFees;
    }

    function setTeamAddress(address _newTeamAddress) public onlyOwner {
        teamAddress = payable(_newTeamAddress);
    }

    function setFreeSpinNFTAddress(address _freeSpinNFTAddress) public onlyOwner {
        freeSpinNFTAddress = _freeSpinNFTAddress;
    }

    function setFreeSpinTimeout(uint256 timeout) public onlyOwner {
        freeSpinTimeout = timeout;
    }

    function setFreeSpinTier1MinTokenBalance(uint256 _freeSpinTier1MinTokenBalance) public onlyOwner {
        freeSpinTier1MinTokenBalance = _freeSpinTier1MinTokenBalance;
    }

    function setFreeSpinTier2MinTokenBalance(uint256 _freeSpinTier2MinTokenBalance) public onlyOwner {
        freeSpinTier2MinTokenBalance = _freeSpinTier2MinTokenBalance;
    }

    function setFreeSpinTier3MinTokenBalance(uint256 _freeSpinTier3MinTokenBalance) public onlyOwner {
        freeSpinTier3MinTokenBalance = _freeSpinTier3MinTokenBalance;
    }

    function claimFreeSpinFromNFT(uint256 tokenId) public {
        require(IERC721(freeSpinNFTAddress).ownerOf(tokenId) == msg.sender, "User doesn't own the NFT.");
        require(!freeSpin[msg.sender], "User already has a free spin.");
        require(lastFreeSpinTimeAddress[msg.sender] + freeSpinTimeout < block.timestamp, "User was given a free spin recently.");
        require(lastFreeSpinTimeNFT[tokenId] + freeSpinTimeout < block.timestamp, "NFT was given a free spin recently.");

        if(tokenId <= maxSupplyFreeSpinTier1){
            require(IERC20(tokenAddress).balanceOf(msg.sender) >= freeSpinTier1MinTokenBalance, "User has insufficient token balance.");
        }else if(tokenId <= maxSupplyFreeSpinTier1 + maxSupplyFreeSpinTier2){
            require(IERC20(tokenAddress).balanceOf(msg.sender) >= freeSpinTier2MinTokenBalance, "User has insufficient token balance.");
        }else{
            require(IERC20(tokenAddress).balanceOf(msg.sender) >= freeSpinTier3MinTokenBalance, "User has insufficient token balance.");
        }

        lastFreeSpinTimeAddress[msg.sender] = block.timestamp;
        lastFreeSpinTimeNFT[tokenId] = block.timestamp;
        freeSpin[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    receive() external payable {}
}