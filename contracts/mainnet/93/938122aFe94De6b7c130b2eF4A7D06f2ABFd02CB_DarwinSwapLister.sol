// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.14;

import "./interfaces/IDarwinSwapLister.sol";
import "./interfaces/IDarwinSwapRouter.sol";
import "./interfaces/IERC20.sol";
import "../darwin-token-contracts/contracts/interface/IDarwin.sol";

import "./libraries/Tokenomics2Library.sol";

contract DarwinSwapLister is IDarwinSwapLister {
    address public dev;
    address public factory;

    uint public maxTok1Tax;
    uint public maxTok2Tax;
    uint public maxTotalTax;

    mapping(address => TokenInfo) private _tokenInfo;

    mapping(address => bool) public isValidator;
    mapping(address => bool) public isUserBannedFromListing;

    constructor() {
        dev = msg.sender;
        isValidator[msg.sender] = true;
        maxTotalTax = 2000; // Max add-on percentage of taxation (on users or LP from buys or sells). (20.00%)
        maxTok1Tax = 1000; // Max add-on user percentage of taxation (on both buys and sells). (10.00%)
        maxTok2Tax = 500; // Max add-on LP percentage of taxation (on both buys and sells). (5.00%)
    }

    modifier onlyDev() {
        require(msg.sender == dev, "DarwinSwap: CALLER_NOT_DEV");
        _;
    }

    modifier onlyValidators() {
        require(isValidator[msg.sender], "DarwinSwap: CALLER_NOT_VALIDATOR");
        _;
    }

    // Pairs 2 tokens by skipping validation (no DEX-added-features allowed). Callable by anyone.
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(_tokenInfo[tokenA].status != TokenStatus.BANNED && !isUserBannedFromListing[tx.origin], "DarwinSwap: TOKENA_OR_CALLER_BANNED");
        require(_tokenInfo[tokenB].status != TokenStatus.BANNED && !isUserBannedFromListing[tx.origin], "DarwinSwap: TOKENB_OR_CALLER_BANNED");

        pair = IDarwinSwapFactory(factory).createPair(tokenA, tokenB);
    }

    function getPair(address tokenA, address tokenB) external view returns (address pair) {
        pair = IDarwinSwapFactory(factory).getPair(tokenA, tokenB);
    }

    // Allows a token owner (or the Dev address, in case the token is owned by address(0) et similia) to ask for the validation and listing of his token. This way users are able to put add-ons Tokenomics (1.0 or 2.0) on their tokens. (only if they get validated)
    // Also allows to propose modifies to an already listed token.
    function listToken(address tokenAddress, TokenInfo memory listingInfo) external {
        require(block.timestamp > _tokenInfo[tokenAddress].unlockTime, "DarwinSwap: TAXES_LOCKED");
        require(tokenAddress != address(0), "DarwinSwap: ZERO_ADDRESS");
        require(bytes(listingInfo.purpose).length > 0, "DarwinSwap: EMPTY_PURPOSE");
        require(_tokenInfo[tokenAddress].status != TokenStatus.BANNED && !isUserBannedFromListing[msg.sender], "DarwinSwap: TOKEN_OR_BANNED");
        address owner = _getTokenOwner(tokenAddress);
        require(msg.sender == owner || isValidator[msg.sender], "DarwinSwap: CALLER_NOT_TOKEN_OWNER_OR_VALIDATOR");

        // Makes sure the fields in the proposal are setted as they should by default
        listingInfo.owner = owner;
        listingInfo.status = TokenStatus.LISTED;
        listingInfo.valid = true;
        listingInfo.official = false;
        if (listingInfo.feeReceiver == address(0)) {
            listingInfo.feeReceiver = msg.sender;
        }

        bool valid = Tokenomics2Library.ensureTokenomics(listingInfo, maxTok1Tax, maxTok2Tax, maxTotalTax);
        require(valid, "DarwinSwap: INVALID_REQUESTED_TOKENOMICS");

        listingInfo.addedToks = Tokenomics2Library.adjustTokenomics(listingInfo.addedToks);

        _tokenInfo[tokenAddress] = listingInfo;

        emit TokenListed(tokenAddress, listingInfo);
    }

    function increaseLockPeriod(address _tokenAddress, uint _newUnlockDate) external {
        require(_newUnlockDate > _tokenInfo[_tokenAddress].unlockTime, "DarwinSwap: LOCK_BEFORE_LOCK_END");
        address owner = _getTokenOwner(_tokenAddress);
        require(msg.sender == owner || isValidator[msg.sender], "DarwinSwap: CALLER_NOT_TOKEN_OWNER_OR_VALIDATOR");

        _tokenInfo[_tokenAddress].unlockTime = _newUnlockDate;

        emit TaxLockPeriodUpdated(_tokenAddress, _newUnlockDate);
    }

    // Lists DARWIN and pairs with WETH, with 5% tax on LP on buys
    function listDarwinWithWETH(address darwin, address weth, address darwinCommunity) external onlyDev {
        // DARWIN validate
        _tokenInfo[darwin].addedToks.tokenA2TaxOnBuy = 200;
        _tokenInfo[darwin].status = TokenStatus.LISTED;
        _tokenInfo[darwin].validator = msg.sender;
        _tokenInfo[darwin].valid = true;
        _tokenInfo[darwin].official = true;
        _tokenInfo[darwin].owner = msg.sender;
        _tokenInfo[darwin].feeReceiver = darwinCommunity;
        _tokenInfo[darwin].addedToks.tokenB1SellToLI = 200;

        address pair = IDarwinSwapFactory(factory).getPair(darwin, weth);
        if (pair == address(0)) {
            pair = IDarwinSwapFactory(factory).createPair(darwin, weth);
        }
        IDarwin(darwin).registerDarwinSwapPair(pair);
    }

    // transfer ownership
    function setDev(address _dev) external onlyDev {
        dev = _dev;
    }

    // adds or removes a validator
    function setValidator(address _user, bool _isValidator) external onlyDev {
        isValidator[_user] = _isValidator;
    }

    // getter for the tokenInfo mapping
    function tokenInfo(address _token) external view returns(TokenInfo memory) {
        return _tokenInfo[_token];
    }

    // setter for max add-on user percentage of taxation
    function setMaxTok1Tax(uint _maxTok1Tax) external onlyDev {
        maxTok1Tax = _maxTok1Tax;
    }

    // setter for max add-on LP percentage of taxation
    function setMaxTok2Tax(uint _maxTok2Tax) external onlyDev {
        maxTok2Tax = _maxTok2Tax;
    }

    // setter for max add-on total percentage of taxation
    function setMaxTotalTax(uint _maxTotalTax) external onlyDev {
        maxTotalTax = _maxTotalTax;
    }

    // bans or unbans a user from listing
    function setBanUser(address _user, bool _ban) external onlyValidators {
        isUserBannedFromListing[_user] = _ban;
    }

    // bans or unbans a token from being listed
    function setBanToken(address _token, bool _ban) external onlyValidators {
        if (_ban) {
            _tokenInfo[_token].status = TokenStatus.BANNED;
            _tokenInfo[_token].valid = false;
        } else {
            _tokenInfo[_token].status = TokenStatus.UNLISTED;
        }
    }

    // lists an official token
    function listOfficialToken(address _token) external onlyValidators {
        _tokenInfo[_token].status = TokenStatus.LISTED;
        _tokenInfo[_token].validator = msg.sender;
        _tokenInfo[_token].valid = true;
        _tokenInfo[_token].official = true;
    }

    function setFactory(address _factory) external onlyDev {
        factory = _factory;
    }

    // Gets the owner of the token (if any). Some tokens do not have an "owner" state variable or a "getOwner" function, so this uses a try/catch.
    function _getTokenOwner(address _tokenAddress) internal view returns(address) {
        try IERC20(_tokenAddress).owner() returns (address owner) {
            return owner;
        } catch {
            try IERC20(_tokenAddress).getOwner() returns (address owner) {
                return owner;
            } catch {
                return 0x0000000000000000000000000000000000000000;
            }
        }
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: BSL-1.1

import {IDarwinMasterChef} from "./IMasterChef.sol";

interface IDarwinLiquidityBundles {

    struct User {
        uint256 lpAmount;
        uint256 lockEnd;
        uint256 bundledEth;
        uint256 bundledToken;
        bool inMasterchef;
    }

    event EnterBundle(
        address indexed user,
        uint256 amountToken,
        uint256 amountETH,
        uint256 timestamp,
        uint256 lockEnd
    );

    event ExitBundle(
        address indexed user,
        uint256 amountToken,
        uint256 amountETH,
        uint256 timestamp
    );

    event StakeInMasterchef(
        address indexed user,
        uint256 liquidity,
        uint256 timestamp
    );

    event HarvestAndRelock(
        address indexed user,
        uint256 amountDarwin,
        uint256 timestamp
    );

    function initialize(address _darwinRouter, IDarwinMasterChef _masterChef, address _WETH) external;
    function update(address _lpToken) external;
}

pragma solidity ^0.8.14;

import "./IDarwinLiquidityBundles.sol";
import "./IMasterChef.sol";

interface IDarwinSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function dev() external view returns (address);
    function lister() external view returns (address);
    function feeTo() external view returns (address);
    function router() external view returns (address);
    function liquidityBundles() external view returns (IDarwinLiquidityBundles);
    function masterChef() external view returns (IDarwinMasterChef);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function INIT_CODE_HASH() external pure returns(bytes32);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setDev(address) external;
    function setLister(address) external;
    function setRouter(address) external;
}

// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.14;

interface IDarwinSwapLister {
    struct TokenInfo {
        OwnTokenomicsInfo ownToks; //? The original token's tokenomics
        TokenomicsInfo addedToks; //? Tokenomics "added" by DarwinSwap
        TokenStatus status; //? Token status
        address validator; //? If a Darwin team validator has verified this token (with whatever outcome), this is their address. Otherwise it equals the address(0)
        address owner; //? The owner of the token contract
        address feeReceiver; //? Where will the fees go
        bool valid; //? Only true if the token has been POSITIVELY validated by a Darwin team validator
        bool official; //? Only true if the token is either Darwin, WBNB, or a selected list of tokens like USDT, USDC, etc. If "official" is true, other tokens paired with this token will be able to execute tokenomics, if any
        string purpose; //? Why are you sending the fees to the feeReceiver address? Is it a treasury? Will it be used for buybacks? Marketing?
        uint unlockTime; //? Time when the tax lock will end (and taxes will be modifiable again). 0 if no lock.
    }

    struct OwnTokenomicsInfo {
        uint tokenTaxOnSell; //? The Toks 1.0 taxation applied to tokenA on sells (100%: 10000)
        uint tokenTaxOnBuy; //? The Toks 1.0 taxation applied to tokenA on buys (100%: 10000)
    }

    struct TokenomicsInfo {
        uint tokenA1TaxOnSell; //? The Toks 1.0 taxation applied to tokenA on sells (100%: 10000)
        uint tokenB1TaxOnSell; //? The Toks 1.0 taxation applied to tokenB on sells (100%: 10000)
        uint tokenA1TaxOnBuy; //? The Toks 1.0 taxation applied to tokenA on buys (100%: 10000)
        uint tokenB1TaxOnBuy; //? The Toks 1.0 taxation applied to tokenB on buys (100%: 10000)
        uint tokenA2TaxOnSell; //? The Toks 2.0 taxation applied to tokenA on sells (100%: 10000)
        uint tokenB2TaxOnSell; //? The Toks 2.0 taxation applied to tokenB on sells (100%: 10000)
        uint tokenA2TaxOnBuy; //? The Toks 2.0 taxation applied to tokenA on buys (100%: 10000)
        uint tokenB2TaxOnBuy; //? The Toks 2.0 taxation applied to tokenB on buys (100%: 10000)
        uint refundOnSell; //? Percentage (summed, not subtracted from the other toks) of Tokenomics 2.0 that will be used to refund users of own-toks-1.0 on sells
        uint refundOnBuy; //? Percentage (summed, not subtracted from the other toks) of Tokenomics 2.0 that will be used to refund users of own-toks-1.0 on buys
        uint tokenB1SellToLI; //? Percentage (summed, not subtracted from tokenB1TaxOnSell) of Tokenomics 1.0 applied to the other token that will be used, on sells, to refill the LI
        uint tokenB1BuyToLI; //? Percentage (summed, not subtracted from tokenB1TaxOnBuy) of Tokenomics 1.0 applied to the other token that will be used, on buys, to refill the LI
        uint tokenB2SellToLI; //? Percentage (summed, not subtracted from tokenB2TaxOnSell) of Tokenomics 2.0 applied to the other token that will be used, on sells, to refill the LI
        uint tokenB2BuyToLI; //? Percentage (summed, not subtracted from tokenB2TaxOnBuy) of Tokenomics 2.0 applied to the other token that will be used, on buys, to refill the LI
    }

    enum TokenStatus {
        UNLISTED, //? This token is not listed on DarwinSwap
        LISTED, //? This token has been listed on DarwinSwap
        BANNED //? This token and its owner are banned from listing on DarwinSwap (because it has been recognized as harmful during a verification)
    }

    struct Token {
        string name;
        string symbol;
        address addr;
        uint decimals;
    }

    event TokenListed(address indexed tokenAddress, TokenInfo indexed listingInfo);
    event TaxLockPeriodUpdated(address indexed tokenAddress, uint indexed newUnlockDate);
    event TokenBanned(address indexed tokenAddress, address indexed ownerAddress);

    function maxTok1Tax() external view returns (uint);
    function maxTok2Tax() external view returns (uint);

    function isValidator(address user) external view returns (bool);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function tokenInfo(address _token) external view returns(TokenInfo memory);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

pragma solidity ^0.8.14;

interface IDarwinSwapPair {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function liquidityInjector() external view returns (address);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, address[2] memory firstAndLastInPath) external;
    function skim(address to) external;
    function sync() external;

    function swapWithoutToks(address tokenIn, uint amountIn) external;

    function initialize(address, address, address) external;
}

pragma solidity ^0.8.14;

interface IDarwinSwapRouter {
    // [[[[[ ROUTER 01 FUNCTIONS ]]]]]

    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidityWithoutReceipt(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB,
        uint deadline
    ) external;
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);


    // [[[[[ ROUTER 02 FUNCTIONS ]]]]]

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.14;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function owner() external view returns (address);
    function getOwner() external view returns (address);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function mint(address to, uint value) external;
    function burn(address from, uint value) external;
}

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

import "./IERC20.sol";

interface IDarwinMasterChef {
    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 lockedAmount;   // The part of `amount` that is locked.
        uint256 lockEnd;        // Timestamp of end of lock of the locked amount.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DARWINs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDarwinPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDarwinPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. DARWINs to distribute per second.
        uint256 lastRewardTime;     // Last time DARWINs distribution occurs.
        uint256 accDarwinPerShare;  // Accumulated DARWINs per share, times 1e18. See below.
        uint16 depositFeeBP;        // Deposit fee in basis points.
        uint16 withdrawFeeBP;       // Withdraw fee in basis points.
        uint256 harvestInterval;    // Harvest interval in seconds.
    }

    function withdrawByLPToken(IERC20 lpToken, uint256 _amount) external returns (bool);
    function depositByLPToken(IERC20 lpToken, uint256 _amount, bool _lock, uint256 _lockDuration) external returns (bool);
    function pendingDarwin(uint256 _pid, address _user) external view returns (uint256);
    function poolLength() external view returns (uint256);
    function poolInfo() external view returns (PoolInfo[] memory);
    function poolExistence(IERC20) external view returns (bool);
    function userInfo(uint256, address) external view returns (UserInfo memory);
    function darwin() external view returns (IERC20);
    function dev() external view returns (address);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 newEmissionRate);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event StartTimeChanged(uint256 oldStartTime, uint256 newStartTime);
}

pragma solidity ^0.8.14;

import "../interfaces/IDarwinSwapPair.sol";
import "../interfaces/IDarwinSwapFactory.sol";

library DarwinSwapLibrary {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "DarwinSwapLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "DarwinSwapLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                IDarwinSwapFactory(factory).INIT_CODE_HASH()
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IDarwinSwapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "DarwinSwapLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "DarwinSwapLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, "DarwinSwapLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "DarwinSwapLibrary: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, "DarwinSwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "DarwinSwapLibrary: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "DarwinSwapLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "DarwinSwapLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.14;

import "../interfaces/IDarwinSwapLister.sol";
import "../interfaces/IDarwinSwapPair.sol";
import "../libraries/DarwinSwapLibrary.sol";

library Tokenomics2Library {

    bytes4 private constant _TRANSFER = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant _TRANSFERFROM = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    // TODO: Make sure this actually does correct and enough calculations
    // Taxes the sender with Tokenomics 1.0 on the sold token, both from the sold token and the bought token. Returns the taxed amount.
    function handleToks1Sell(
        address sellToken,
        address from,
        uint256 value,
        address buyToken,
        address factory
    ) public returns(uint sellTaxAmount) {
        IDarwinSwapLister.TokenInfo memory sellTokenInfo = IDarwinSwapLister(IDarwinSwapFactory(factory).lister()).tokenInfo(sellToken);
        IDarwinSwapLister.TokenInfo memory buyTokenInfo = IDarwinSwapLister(IDarwinSwapFactory(factory).lister()).tokenInfo(buyToken);

        if (sellTokenInfo.valid && buyTokenInfo.official) {
            // SELLTOKEN tokenomics1.0 sell tax value applied to itself
            uint sellTokenA1 = (value * sellTokenInfo.addedToks.tokenA1TaxOnSell) / 10000;

            if (sellTokenA1 > 0) {
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFERFROM, from, sellTokenInfo.feeReceiver, sellTokenA1));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_SELL_A1");
            }

            sellTaxAmount += sellTokenA1;
        }

        if (buyTokenInfo.valid && sellTokenInfo.official) {
            // If BUYTOKEN's liqInj is active, send the tokenomics1.0 buy tax value applied to SELLTOKEN to the pair's liqInj guard
            //? liqInj ONLY WORKS ON [2]PATH SWAPS
            address pair = IDarwinSwapFactory(factory).getPair(sellToken, buyToken);
            if (buyTokenInfo.addedToks.tokenB1BuyToLI > 0 && pair != address(0)) {
                uint refill = handleLIRefill(sellToken, buyToken, factory, value, buyTokenInfo.addedToks.tokenB1BuyToLI);
                address liqInj = IDarwinSwapPair(pair).liquidityInjector();
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFERFROM, from, liqInj, refill));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: ANTIDUMP_FAILED_BUY_B1");
            }

            // BUYTOKEN tokenomics1.0 buy tax value applied to SELLTOKEN
            uint buyTokenB1 = (value * buyTokenInfo.addedToks.tokenB1TaxOnBuy) / 10000;

            if (buyTokenB1 > 0) {
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFERFROM, from, buyTokenInfo.feeReceiver, buyTokenB1));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_BUY_B1");
            }

            sellTaxAmount += buyTokenB1;
        }
    }

    // TODO: Make sure this actually does correct and enough calculations
    // Taxes the receiver (well, actually sends LESS tokens to the receiver) with Tokenomics 1.0 on the bought token, both from the sold token and the bought token. Returns the taxed amount.
    function handleToks1Buy(
        address buyToken,
        uint value,
        address sellToken,
        address factory
    ) public returns(uint buyTaxAmount) {
        IDarwinSwapLister.TokenInfo memory buyTokenInfo = IDarwinSwapLister(IDarwinSwapFactory(factory).lister()).tokenInfo(buyToken);
        IDarwinSwapLister.TokenInfo memory sellTokenInfo = IDarwinSwapLister(IDarwinSwapFactory(factory).lister()).tokenInfo(sellToken);

        if (buyTokenInfo.valid && sellTokenInfo.official) {
            // BUYTOKEN tokenomics1.0 buy tax value applied to itself
            uint buyTokenA1 = (value * buyTokenInfo.addedToks.tokenA1TaxOnBuy) / 10000;

            if (buyTokenA1 > 0) {
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, buyTokenInfo.feeReceiver, buyTokenA1));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_BUY_A1");
            }

            buyTaxAmount += buyTokenA1;
        }

        if (sellTokenInfo.valid && buyTokenInfo.official) {
            // If SELLTOKEN's liqInj is active, send the tokenomics1.0 sell tax value applied to BUYTOKEN to the pair's liqInj guard
            //? liqInj ONLY WORKS ON [2]PATH SWAPS
            address pair = IDarwinSwapFactory(factory).getPair(sellToken, buyToken);
            if (sellTokenInfo.addedToks.tokenB1SellToLI > 0 && pair != address(0)) {
                uint refill = handleLIRefill(buyToken, sellToken, factory, value, sellTokenInfo.addedToks.tokenB1SellToLI);
                address liqInj = IDarwinSwapPair(pair).liquidityInjector();
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, liqInj, refill));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: ANTIDUMP_FAILED_SELL_B1");
            }

            // SELLTOKEN tokenomics1.0 sell tax value applied to BUYTOKEN
            uint sellTokenB1 = (value * sellTokenInfo.addedToks.tokenB1TaxOnSell) / 10000;

            if (sellTokenB1 > 0) {
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, sellTokenInfo.feeReceiver, sellTokenB1));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_SELL_B1");
            }

            buyTaxAmount += sellTokenB1;
        }
    }

    // TODO: Make sure this actually does correct and enough calculations
    // Taxes the LP with Tokenomics 2.0 on the sold token, both from the sold token and the bought token.
    function handleToks2Sell(
        address sellToken,
        uint value,
        address buyToken,
        address factory
    ) public {
        IDarwinSwapLister lister = IDarwinSwapLister(IDarwinSwapFactory(factory).lister());
        IDarwinSwapLister.TokenInfo memory sellTokenInfo = lister.tokenInfo(sellToken);
        IDarwinSwapLister.TokenInfo memory buyTokenInfo = lister.tokenInfo(buyToken);

        if (sellTokenInfo.valid && buyTokenInfo.official) {
            // Calculates eventual tokenomics1.0 refund and makes it
            if (sellTokenInfo.addedToks.refundOnSell > 0) {
                uint refundA1WithA2 = (value * sellTokenInfo.addedToks.refundOnSell) / 10000;

                // TODO: SHOULD AVOID USING TX.ORIGIN
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFER, tx.origin, refundA1WithA2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: REFUND_FAILED_SELL_A2");
            }

            // If SELLTOKEN's liqInj is active, send the tokenomics2.0 sell tax value applied to BUYTOKEN to the pair's liqInj guard
            //? liqInj ONLY WORKS ON [2]PATH SWAPS
            address pair = IDarwinSwapFactory(factory).getPair(sellToken, buyToken);
            if (sellTokenInfo.addedToks.tokenB2SellToLI > 0 && pair != address(0)) {
                uint refill = handleLIRefill(buyToken, sellToken, factory, value, sellTokenInfo.addedToks.tokenB2SellToLI);
                address liqInj = IDarwinSwapPair(pair).liquidityInjector();
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, liqInj, refill));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: ANTIDUMP_FAILED_SELL_B2");
            }

            // SELLTOKEN tokenomics2.0 sell tax value applied to itself
            uint sellTokenA2 = (value * sellTokenInfo.addedToks.tokenA2TaxOnSell) / 10000;

            if (sellTokenA2 > 0) {
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFER, sellTokenInfo.feeReceiver, sellTokenA2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_SELL_A2");
            }
        }

        if (buyTokenInfo.valid && sellTokenInfo.official) {
            // BUYTOKEN tokenomics2.0 buy tax value applied to SELLTOKEN
            uint buyTokenB2 = (value * buyTokenInfo.addedToks.tokenB2TaxOnBuy) / 10000;

            if (buyTokenB2 > 0) {
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFER, buyTokenInfo.feeReceiver, buyTokenB2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_BUY_B2");
            }
        }
    }

    // TODO: Make sure this actually does correct and enough calculations
    // Taxes the LP with Tokenomics 2.0 on the bought token, both from the bought token and the sold token.
    function handleToks2Buy(
        address buyToken,
        uint value,
        address sellToken,
        address to,
        address factory
    ) public {
        IDarwinSwapLister lister = IDarwinSwapLister(IDarwinSwapFactory(factory).lister());
        IDarwinSwapLister.TokenInfo memory buyTokenInfo = lister.tokenInfo(buyToken);
        IDarwinSwapLister.TokenInfo memory sellTokenInfo = lister.tokenInfo(sellToken);

        if (buyTokenInfo.valid && sellTokenInfo.official) {
            // Calculates eventual tokenomics1.0 refund
            if (buyTokenInfo.addedToks.refundOnBuy > 0) {
                uint refundA1WithA2 = (value * buyTokenInfo.addedToks.refundOnBuy) / 10000;

                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, to, refundA1WithA2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: REFUND_FAILED_BUY_A2");
            }

            // If BUYTOKEN's liqInj is active, send the tokenomics2.0 buy tax value applied to SELLTOKEN to the pair's liqInj guard
            //? liqInj ONLY WORKS ON [2]PATH SWAPS
            address pair = IDarwinSwapFactory(factory).getPair(sellToken, buyToken);
            if (buyTokenInfo.addedToks.tokenB2BuyToLI > 0 && pair != address(0)) {
                uint refill = handleLIRefill(sellToken, buyToken, factory, value, buyTokenInfo.addedToks.tokenB2BuyToLI);
                address liqInj = IDarwinSwapPair(pair).liquidityInjector();
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFER, liqInj, refill));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: ANTIDUMP_FAILED_BUY_B2");
            }

            // BUYTOKEN tokenomics2.0 buy tax value applied to itself
            uint buyTokenA2 = (value * buyTokenInfo.addedToks.tokenA2TaxOnBuy) / 10000;

            if (buyTokenA2 > 0) {
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, buyTokenInfo.feeReceiver, buyTokenA2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_BUY_A2");
            }
        }

        if (sellTokenInfo.valid && buyTokenInfo.official) {
            // SELLTOKEN tokenomics2.0 sell tax value applied to BUYTOKEN
            uint sellTokenB2 = (value * sellTokenInfo.addedToks.tokenB2TaxOnSell) / 10000;

            if (sellTokenB2 > 0) {
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, sellTokenInfo.feeReceiver, sellTokenB2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_SELL_B2");
            }
        }
    }

    function handleLIRefill(address antiDumpToken, address otherToken, address factory, uint value, uint otherTokenB2OtherToLI) public view returns(uint refill) {
        (uint antiDumpReserve, uint otherReserve) = DarwinSwapLibrary.getReserves(factory, antiDumpToken, otherToken);
        refill = (DarwinSwapLibrary.getAmountOut(value, otherReserve, antiDumpReserve) * otherTokenB2OtherToLI) / 10000;
    }

    // Ensures that the limitations we've set for taxes are respected
    function ensureTokenomics(IDarwinSwapLister.TokenInfo memory tokInfo, uint maxTok1Tax, uint maxTok2Tax, uint maxTotalTax) public pure returns(bool valid) {
        IDarwinSwapLister.TokenomicsInfo memory toks = tokInfo.addedToks;
        IDarwinSwapLister.OwnTokenomicsInfo memory ownToks = tokInfo.ownToks;

        uint tax1OnSell =   toks.tokenA1TaxOnSell + toks.tokenB1TaxOnSell + toks.tokenB1SellToLI;
        uint tax1OnBuy =    toks.tokenA1TaxOnBuy +  toks.tokenB1TaxOnBuy +  toks.tokenB1BuyToLI;
        uint tax2OnSell =   toks.tokenA2TaxOnSell + toks.tokenB2TaxOnSell + toks.refundOnSell +     toks.tokenB2SellToLI;
        uint tax2OnBuy =    toks.tokenA2TaxOnBuy +  toks.tokenB2TaxOnBuy +  toks.refundOnBuy +      toks.tokenB2BuyToLI;

        valid = tax1OnSell <= maxTok1Tax && tax1OnBuy <= maxTok1Tax && tax2OnSell <= maxTok2Tax && tax2OnBuy <= maxTok2Tax &&
                (toks.refundOnSell <= (ownToks.tokenTaxOnSell / 2)) && (toks.refundOnBuy <= (ownToks.tokenTaxOnBuy / 2)) &&
                (tax1OnBuy + tax1OnSell + tax2OnBuy + tax2OnSell <= maxTotalTax);
    }

    // Removes 5% from added tokenomics, to leave it for LP providers.
    function adjustTokenomics(IDarwinSwapLister.TokenomicsInfo calldata addedToks) public pure returns(IDarwinSwapLister.TokenomicsInfo memory returnToks) {
        returnToks.tokenA1TaxOnBuy = addedToks.tokenA1TaxOnBuy - (addedToks.tokenA1TaxOnBuy * 5) / 100;
        returnToks.tokenA1TaxOnSell = addedToks.tokenA1TaxOnSell - (addedToks.tokenA1TaxOnSell * 5) / 100;
        returnToks.tokenA2TaxOnBuy = addedToks.tokenA2TaxOnBuy - (addedToks.tokenA2TaxOnBuy * 5) / 100;
        returnToks.tokenA2TaxOnSell = addedToks.tokenA2TaxOnSell - (addedToks.tokenA2TaxOnSell * 5) / 100;
        returnToks.tokenB1TaxOnBuy = addedToks.tokenB1TaxOnBuy - (addedToks.tokenB1TaxOnBuy * 5) / 100;
        returnToks.tokenB1TaxOnSell = addedToks.tokenB1TaxOnSell - (addedToks.tokenB1TaxOnSell * 5) / 100;
        returnToks.tokenB2TaxOnBuy = addedToks.tokenB2TaxOnBuy - (addedToks.tokenB2TaxOnBuy * 5) / 100;
        returnToks.tokenB2TaxOnSell = addedToks.tokenB2TaxOnSell - (addedToks.tokenB2TaxOnSell * 5) / 100;
        returnToks.refundOnBuy = addedToks.refundOnBuy - (addedToks.refundOnBuy * 5) / 100;
        returnToks.refundOnSell = addedToks.refundOnSell - (addedToks.refundOnSell * 5) / 100;
        returnToks.tokenB1SellToLI = addedToks.tokenB1SellToLI - (addedToks.tokenB1SellToLI * 5) / 100;
        returnToks.tokenB1BuyToLI = addedToks.tokenB1BuyToLI - (addedToks.tokenB1BuyToLI * 5) / 100;
        returnToks.tokenB2SellToLI = addedToks.tokenB2SellToLI - (addedToks.tokenB2SellToLI * 5) / 100;
        returnToks.tokenB2BuyToLI = addedToks.tokenB2BuyToLI - (addedToks.tokenB2BuyToLI * 5) / 100;
    }
}

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

import {IStakedDarwin} from "./IStakedDarwin.sol";

interface IDarwin {

    event ExcludedFromReflection(address account, bool isExcluded);
    event SetPaused(uint timestamp);
    event SetUnpaused(uint timestamp);

    // PUBLIC
    function distributeRewards(uint256 amount) external;
    function bulkTransfer(address[] calldata recipients, uint256[] calldata amounts) external;

    // COMMUNITY
    // function upgradeTo(address newImplementation) external; RESTRICTED
    // function upgradeToAndCall(address newImplementation, bytes memory data) external payable; RESTRICTED
    function setMinter(address user_, bool canMint_) external; // RESTRICTED
    function setMaintenance(address _addr, bool _hasRole) external; // RESTRICTED
    function setSecurity(address _addr, bool _hasRole) external; // RESTRICTED
    function setUpgrader(address _account, bool _hasRole) external; // RESTRICTED
    function setReceiveRewards(address account, bool shouldReceive) external; // RESTRICTED
    function communityPause() external; // RESTRICTED
    function communityUnPause() external;

    // FACTORY
    function registerDarwinSwapPair(address _pair) external;

    // MAINTENANCE
    function setDarwinSwapFactory(address _darwinSwapFactory) external;
    function setDarwinStaking(address _darwinStaking) external;
    function setMasterChef(address _masterChef) external;

    // MINTER
    function mint(address account, uint256 amount) external;

    // VIEW
    function isPaused() external view returns (bool);
    function stakedDarwin() external view returns(IStakedDarwin);
    function MAX_SUPPLY() external pure returns(uint256);

    // BURN
    function burn(uint256 amount) external;

    /// TransferFrom amount is greater than allowance
    error InsufficientAllowance();
    /// Only the DarwinCommunity can call this function
    error OnlyDarwinCommunity();

    /// Input cannot be the zero address
    error ZeroAddress();
    /// Amount cannot be 0
    error ZeroAmount();
    /// Arrays must be the same length
    error InvalidArrayLengths();

    /// Holding limit exceeded
    error HoldingLimitExceeded();
    /// Sell limit exceeded
    error SellLimitExceeded();
    /// Paused
    error Paused();
    error AccountAlreadyExcluded();
    error AccountNotExcluded();

    /// Max supply reached, cannot mint more Darwin
    error MaxSupplyReached();
}

pragma solidity ^0.8.14;

interface IStakedDarwin {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns(string calldata);
    function symbol() external pure returns(string calldata);
    function decimals() external pure returns(uint8);

    function darwinStaking() external view returns (address);
    function totalSupply() external view returns (uint);
    function balanceOf(address user) external view returns (uint);

    function mint(address to, uint value) external;
    function burn(address from, uint value) external;

    function setDarwinStaking(address _darwinStaking) external;
}