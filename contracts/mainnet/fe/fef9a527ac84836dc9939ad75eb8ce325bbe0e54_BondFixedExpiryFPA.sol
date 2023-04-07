// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {BondBaseFPA, IBondAggregator, Authority} from "./bases/BondBaseFPA.sol";
import {IBondTeller} from "./interfaces/IBondTeller.sol";
import {IBondFixedExpiryTeller} from "./interfaces/IBondFixedExpiryTeller.sol";

/// @title Bond Fixed-Expiry Fixed Price Auctioneer
/// @notice Bond Fixed-Expiry Fixed Price Auctioneer Contract
/// @dev Bond Protocol is a permissionless system to create bond markets
///      for any token pair. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev An Auctioneer contract allows users to create and manage bond markets.
///      All bond pricing logic and market data is stored in the Auctioneer.
///      An Auctioneer is dependent on a Teller to serve external users and
///      an Aggregator to register new markets. Th Fixed Price Auctioneer
///      lets issuers set a Fixed Price to buy a target amount of quote tokens or sell
///      a target amount of payout tokens over the duration of a market.
///      See IBondFPA.sol for price format details.
///
/// @dev The Fixed-Expiry Fixed Price Auctioneer is an implementation of the
///      Bond Base Fixed Price Auctioneer contract specific to creating bond markets where
///      all purchases on that market vest at a certain timestamp.
///
/// @author Oighty
contract BondFixedExpiryFPA is BondBaseFPA {
    /* ========== CONSTRUCTOR ========== */
    constructor(
        IBondTeller teller_,
        IBondAggregator aggregator_,
        address guardian_,
        Authority authority_
    ) BondBaseFPA(teller_, aggregator_, guardian_, authority_) {}

    /// @inheritdoc BondBaseFPA
    function createMarket(bytes calldata params_) external override returns (uint256) {
        // Decode params into the struct type expected by this auctioneer
        MarketParams memory params = abi.decode(params_, (MarketParams));

        // Vesting is rounded to the nearest day at 0000 UTC (in seconds) since bond tokens
        // are only unique to a day, not a specific timestamp.
        params.vesting = (params.vesting / 1 days) * 1 days;

        // Get conclusion from start time and duration
        // Don't need to check valid start time or duration here since it will be checked in _createMarket
        uint48 start = params.start == 0 ? uint48(block.timestamp) : params.start;
        uint48 conclusion = start + params.duration;

        // Check that the vesting parameter is valid for a fixed-expiry market
        if (params.vesting != 0 && params.vesting < conclusion) revert Auctioneer_InvalidParams();

        // Create market with provided params
        uint256 marketId = _createMarket(params);

        // Create bond token (ERC20 for fixed expiry) if not instant swap
        if (params.vesting != 0)
            IBondFixedExpiryTeller(address(_teller)).deploy(params.payoutToken, params.vesting);

        // Return market ID
        return marketId;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {CloneERC20} from "./lib/CloneERC20.sol";

/// @title ERC20 Bond Token
/// @notice ERC20 Bond Token Contract
/// @dev Bond Protocol is a permissionless system to create Olympus-style bond markets
///      for any token pair. The markets do not require maintenance and will manage
///      bond prices based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev The ERC20 Bond Token contract is issued by a Fixed Expiry Teller to
///      represent bond positions until they vest. Bond tokens can be redeemed for
//       the underlying token 1:1 at or after expiry.
///
/// @dev This contract uses Clones (https://github.com/wighawag/clones-with-immutable-args)
///      to save gas on deployment and is based on VestedERC20 (https://github.com/ZeframLou/vested-erc20)
///
/// @author Oighty, Zeus, Potted Meat, indigo
contract ERC20BondToken is CloneERC20 {
    /* ========== ERRORS ========== */
    error BondToken_OnlyTeller();

    /* ========== IMMUTABLE PARAMETERS ========== */

    /// @notice The token to be redeemed when the bond vests
    /// @return _underlying The address of the underlying token
    function underlying() external pure returns (ERC20 _underlying) {
        return ERC20(_getArgAddress(0x41));
    }

    /// @notice Timestamp at which the BondToken can be redeemed for the underlying
    /// @return _expiry The vest start timestamp
    function expiry() external pure returns (uint48 _expiry) {
        return uint48(_getArgUint256(0x55));
    }

    /// @notice Address of the Teller that created the token
    function teller() public pure returns (address _teller) {
        return _getArgAddress(0x75);
    }

    /* ========== MINT/BURN ========== */

    function mint(address to, uint256 amount) external {
        if (msg.sender != teller()) revert BondToken_OnlyTeller();
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        if (msg.sender != teller()) revert BondToken_OnlyTeller();
        _burn(from, amount);
    }
}

/// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {IBondFPA, IBondAuctioneer} from "../interfaces/IBondFPA.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";
import {IBondCallback} from "../interfaces/IBondCallback.sol";
import {IBondAggregator} from "../interfaces/IBondAggregator.sol";

import {TransferHelper} from "../lib/TransferHelper.sol";
import {FullMath} from "../lib/FullMath.sol";

/// @title Bond Fixed Price Auctioneer
/// @notice Bond Fixed Price Auctioneer Base Contract
/// @dev Bond Protocol is a system to create markets for any token pair.
///      Bond issuers create BondMarkets that pay out a Payout Token in exchange
///      for deposited Quote Tokens. Users can purchase future-dated Payout Tokens
///      with Quote Tokens at the current market price and receive Bond Tokens to
///      represent their position while their bond vests. Once the Bond Tokens vest,
///      they can redeem it for the Quote Tokens. Alternatively, markets can be
///      instant swap and payouts are made immediately to the user.
///
/// @dev An Auctioneer contract allows users to create and manage bond markets.
///      All bond pricing logic and market data is stored in the Auctioneer.
///      An Auctioneer is dependent on a Teller to serve external users and
///      an Aggregator to register new markets. The Fixed Price Auctioneer
///      lets issuers set a Fixed Price to buy a target amount of quote tokens or sell
///      a target amount of payout tokens over the duration of a market.
///      See IBondFPA.sol for price format details.
///
/// @author Oighty
abstract contract BondBaseFPA is IBondFPA, Auth {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    /* ========== ERRORS ========== */

    error Auctioneer_OnlyMarketOwner();
    error Auctioneer_MarketNotActive();
    error Auctioneer_MaxPayoutExceeded();
    error Auctioneer_AmountLessThanMinimum();
    error Auctioneer_NotEnoughCapacity();
    error Auctioneer_InvalidCallback();
    error Auctioneer_BadExpiry();
    error Auctioneer_InvalidParams();
    error Auctioneer_NotAuthorized();
    error Auctioneer_NewMarketsNotAllowed();

    /* ========== EVENTS ========== */

    event MarketCreated(
        uint256 indexed id,
        address indexed payoutToken,
        address indexed quoteToken,
        uint48 vesting,
        uint256 fixedPrice
    );
    event MarketClosed(uint256 indexed id);

    /* ========== STATE VARIABLES ========== */

    /// @notice Information pertaining to bond markets
    mapping(uint256 => BondMarket) public markets;

    /// @notice Information pertaining to market vesting and duration
    mapping(uint256 => BondTerms) public terms;

    /// @notice New address to designate as market owner. They must accept ownership to transfer permissions.
    mapping(uint256 => address) public newOwners;

    /// @notice Whether or not the auctioneer allows new markets to be created
    /// @dev    Changing to false will sunset the auctioneer after all active markets end
    bool public allowNewMarkets;

    // Minimum time parameter values. Can be updated by admin.
    /// @notice Minimum deposit interval for a market
    uint48 public minDepositInterval;

    /// @notice Minimum market duration in seconds
    uint48 public minMarketDuration;

    /// @notice Whether or not the market creator is authorized to use a callback address
    mapping(address => bool) public callbackAuthorized;

    // A 'vesting' param longer than 50 years is considered a timestamp for fixed expiry.
    uint48 internal constant MAX_FIXED_TERM = 52 weeks * 50;
    uint48 internal constant ONE_HUNDRED_PERCENT = 1e5; // one percent equals 1000.

    // BondAggregator contract with utility functions
    IBondAggregator internal immutable _aggregator;

    // BondTeller contract that handles interactions with users and issues tokens
    IBondTeller internal immutable _teller;

    constructor(
        IBondTeller teller_,
        IBondAggregator aggregator_,
        address guardian_,
        Authority authority_
    ) Auth(guardian_, authority_) {
        _aggregator = aggregator_;
        _teller = teller_;

        minDepositInterval = 1 hours;
        minMarketDuration = 1 days;

        allowNewMarkets = true;
    }

    /* ========== MARKET FUNCTIONS ========== */

    /// @inheritdoc IBondAuctioneer
    function createMarket(bytes calldata params_) external virtual returns (uint256);

    /// @notice core market creation logic, see IBondFPA.MarketParams documentation
    function _createMarket(MarketParams memory params_) internal returns (uint256) {
        {
            // Check that the auctioneer is allowing new markets to be created
            if (!allowNewMarkets) revert Auctioneer_NewMarketsNotAllowed();

            // Ensure params are in bounds
            uint8 payoutTokenDecimals = params_.payoutToken.decimals();
            uint8 quoteTokenDecimals = params_.quoteToken.decimals();

            if (payoutTokenDecimals < 6 || payoutTokenDecimals > 18)
                revert Auctioneer_InvalidParams();
            if (quoteTokenDecimals < 6 || quoteTokenDecimals > 18)
                revert Auctioneer_InvalidParams();
            if (params_.scaleAdjustment < -24 || params_.scaleAdjustment > 24)
                revert Auctioneer_InvalidParams();

            // Restrict the use of a callback address unless allowed
            if (!callbackAuthorized[msg.sender] && params_.callbackAddr != address(0))
                revert Auctioneer_NotAuthorized();

            // Start time must be zero or in the future
            if (params_.start > 0 && params_.start < block.timestamp)
                revert Auctioneer_InvalidParams();
        }

        // Unit to scale calculation for this market by to ensure reasonable values.
        // See IBondFPA for more details.
        //
        // scaleAdjustment should be equal to (payoutDecimals - quoteDecimals) - ((payoutPriceDecimals - quotePriceDecimals) / 2)
        uint256 scale;
        unchecked {
            scale = 10**uint8(36 + params_.scaleAdjustment);
        }

        // Check that price is not zero
        if (params_.formattedPrice == 0) revert Auctioneer_InvalidParams();

        // Check time bounds
        if (
            params_.duration < minMarketDuration ||
            params_.depositInterval < minDepositInterval ||
            params_.depositInterval > params_.duration
        ) revert Auctioneer_InvalidParams();

        // Calculate the maximum payout amount for this market
        uint256 _maxPayout = (
            params_.capacityInQuote
                ? params_.capacity.mulDiv(scale, params_.formattedPrice)
                : params_.capacity
        ).mulDiv(uint256(params_.depositInterval), uint256(params_.duration));

        // Register new market on aggregator and get marketId
        uint256 marketId = _aggregator.registerMarket(params_.payoutToken, params_.quoteToken);

        markets[marketId] = BondMarket({
            owner: msg.sender,
            payoutToken: params_.payoutToken,
            quoteToken: params_.quoteToken,
            callbackAddr: params_.callbackAddr,
            capacityInQuote: params_.capacityInQuote,
            capacity: params_.capacity,
            maxPayout: _maxPayout,
            price: params_.formattedPrice,
            scale: scale,
            purchased: 0,
            sold: 0
        });

        // Calculate and store time terms
        uint48 start = params_.start == 0 ? uint48(block.timestamp) : params_.start;

        terms[marketId] = BondTerms({
            start: start,
            conclusion: start + params_.duration,
            vesting: params_.vesting
        });

        emit MarketCreated(
            marketId,
            address(params_.payoutToken),
            address(params_.quoteToken),
            params_.vesting,
            params_.formattedPrice
        );

        return marketId;
    }

    /// @inheritdoc IBondAuctioneer
    function pushOwnership(uint256 id_, address newOwner_) external override {
        if (msg.sender != markets[id_].owner) revert Auctioneer_OnlyMarketOwner();
        newOwners[id_] = newOwner_;
    }

    /// @inheritdoc IBondAuctioneer
    function pullOwnership(uint256 id_) external override {
        if (msg.sender != newOwners[id_]) revert Auctioneer_NotAuthorized();
        markets[id_].owner = newOwners[id_];
    }

    /// @inheritdoc IBondFPA
    function setMinMarketDuration(uint48 duration_) external override requiresAuth {
        // Restricted to authorized addresses

        // Require duration to be greater than minimum deposit interval and at least 1 day
        if (duration_ < minDepositInterval || duration_ < 1 days) revert Auctioneer_InvalidParams();

        minMarketDuration = duration_;
    }

    /// @inheritdoc IBondFPA
    function setMinDepositInterval(uint48 depositInterval_) external override requiresAuth {
        // Restricted to authorized addresses

        // Require min deposit interval to be less than minimum market duration and at least 1 hour
        if (depositInterval_ > minMarketDuration || depositInterval_ < 1 hours)
            revert Auctioneer_InvalidParams();

        minDepositInterval = depositInterval_;
    }

    // Unused, but required by interface
    function setIntervals(uint256 id_, uint32[3] calldata intervals_) external override {}

    // Unused, but required by interface
    function setDefaults(uint32[6] memory defaults_) external override {}

    /// @inheritdoc IBondAuctioneer
    function setAllowNewMarkets(bool status_) external override requiresAuth {
        // Restricted to authorized addresses
        allowNewMarkets = status_;
    }

    /// @inheritdoc IBondAuctioneer
    function setCallbackAuthStatus(address creator_, bool status_) external override requiresAuth {
        // Restricted to authorized addresses
        callbackAuthorized[creator_] = status_;
    }

    /// @inheritdoc IBondAuctioneer
    function closeMarket(uint256 id_) external override {
        if (msg.sender != markets[id_].owner) revert Auctioneer_OnlyMarketOwner();
        terms[id_].conclusion = uint48(block.timestamp);
        markets[id_].capacity = 0;

        emit MarketClosed(id_);
    }

    /* ========== TELLER FUNCTIONS ========== */

    /// @inheritdoc IBondAuctioneer
    function purchaseBond(
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external override returns (uint256 payout) {
        if (msg.sender != address(_teller)) revert Auctioneer_NotAuthorized();

        BondMarket storage market = markets[id_];

        // If market uses a callback, check that owner is still callback authorized
        if (market.callbackAddr != address(0) && !callbackAuthorized[market.owner])
            revert Auctioneer_NotAuthorized();

        // Check if market is live, if not revert
        if (!isLive(id_)) revert Auctioneer_MarketNotActive();

        // Calculate payout amount from fixed price
        payout = amount_.mulDiv(market.scale, market.price);

        // Payout must be greater than user inputted minimum
        if (payout < minAmountOut_) revert Auctioneer_AmountLessThanMinimum();

        // Markets have a max payout amount per transaction
        if (payout > market.maxPayout) revert Auctioneer_MaxPayoutExceeded();

        // Update Capacity

        // Capacity is either the number of payout tokens that the market can sell
        // (if capacity in quote is false),
        //
        // or the number of quote tokens that the market can buy
        // (if capacity in quote is true)

        // If amount/payout is greater than capacity remaining, revert
        if (market.capacityInQuote ? amount_ > market.capacity : payout > market.capacity)
            revert Auctioneer_NotEnoughCapacity();
        // Capacity is decreased by the deposited or paid amount
        market.capacity -= market.capacityInQuote ? amount_ : payout;

        // Markets keep track of how many quote tokens have been
        // purchased, and how many payout tokens have been sold
        market.purchased += amount_;
        market.sold += payout;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /// @inheritdoc IBondAuctioneer
    function getMarketInfoForPurchase(uint256 id_)
        external
        view
        returns (
            address owner,
            address callbackAddr,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 vesting,
            uint256 maxPayout_
        )
    {
        BondMarket memory market = markets[id_];
        return (
            market.owner,
            market.callbackAddr,
            market.payoutToken,
            market.quoteToken,
            terms[id_].vesting,
            maxPayout(id_)
        );
    }

    /// @inheritdoc IBondAuctioneer
    function marketPrice(uint256 id_) public view override returns (uint256) {
        return markets[id_].price;
    }

    /// @inheritdoc IBondAuctioneer
    function marketScale(uint256 id_) external view override returns (uint256) {
        return markets[id_].scale;
    }

    /// @inheritdoc IBondAuctioneer
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) public view override returns (uint256) {
        // Calculate the payout for the given amount of tokens
        uint256 fee = amount_.mulDiv(_teller.getFee(referrer_), ONE_HUNDRED_PERCENT);
        uint256 payout = (amount_ - fee).mulDiv(markets[id_].scale, marketPrice(id_));

        // Check that the payout is less than or equal to the maximum payout,
        // Revert if not, otherwise return the payout
        if (payout > maxPayout(id_)) {
            revert Auctioneer_MaxPayoutExceeded();
        } else {
            return payout;
        }
    }

    /// @inheritdoc IBondAuctioneer
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256) {
        // Calculate maximum amount of quote tokens that correspond to max bond size
        // Maximum of the maxPayout and the remaining capacity converted to quote tokens
        BondMarket memory market = markets[id_];
        uint256 price = marketPrice(id_);
        uint256 quoteCapacity = market.capacityInQuote
            ? market.capacity
            : market.capacity.mulDiv(price, market.scale);
        uint256 maxQuote = market.maxPayout.mulDiv(price, market.scale);
        uint256 amountAccepted = quoteCapacity < maxQuote ? quoteCapacity : maxQuote;

        // Take into account teller fees and return
        // Estimate fee based on amountAccepted. Fee taken will be slightly larger than
        // this given it will be taken off the larger amount, but this avoids rounding
        // errors with trying to calculate the exact amount.
        // Therefore, the maxAmountAccepted is slightly conservative.
        uint256 estimatedFee = amountAccepted.mulDiv(
            _teller.getFee(referrer_),
            ONE_HUNDRED_PERCENT
        );

        return amountAccepted + estimatedFee;
    }

    /// @inheritdoc IBondFPA
    function maxPayout(uint256 id_) public view override returns (uint256) {
        // Get current price
        uint256 price = marketPrice(id_);

        BondMarket memory market = markets[id_];

        // Convert capacity to payout token units for comparison with max payout
        uint256 capacity = market.capacityInQuote
            ? market.capacity.mulDiv(market.scale, price)
            : market.capacity;

        // Cap max payout at the remaining capacity
        return market.maxPayout > capacity ? capacity : market.maxPayout;
    }

    /// @inheritdoc IBondAuctioneer
    function isInstantSwap(uint256 id_) public view returns (bool) {
        uint256 vesting = terms[id_].vesting;
        return (vesting <= MAX_FIXED_TERM) ? vesting == 0 : vesting <= block.timestamp;
    }

    /// @inheritdoc IBondAuctioneer
    function isLive(uint256 id_) public view override returns (bool) {
        return (markets[id_].capacity != 0 &&
            terms[id_].conclusion > uint48(block.timestamp) &&
            terms[id_].start <= uint48(block.timestamp));
    }

    /// @inheritdoc IBondAuctioneer
    function ownerOf(uint256 id_) external view override returns (address) {
        return markets[id_].owner;
    }

    /// @inheritdoc IBondAuctioneer
    function getTeller() external view override returns (IBondTeller) {
        return _teller;
    }

    /// @inheritdoc IBondAuctioneer
    function getAggregator() external view override returns (IBondAggregator) {
        return _aggregator;
    }

    /// @inheritdoc IBondAuctioneer
    function currentCapacity(uint256 id_) external view override returns (uint256) {
        return markets[id_].capacity;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondAuctioneer} from "../interfaces/IBondAuctioneer.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";

interface IBondAggregator {
    /// @notice             Register a auctioneer with the aggregator
    /// @notice             Only Guardian
    /// @param auctioneer_  Address of the Auctioneer to register
    /// @dev                A auctioneer must be registered with an aggregator to create markets
    function registerAuctioneer(IBondAuctioneer auctioneer_) external;

    /// @notice             Register a new market with the aggregator
    /// @notice             Only registered depositories
    /// @param payoutToken_ Token to be paid out by the market
    /// @param quoteToken_  Token to be accepted by the market
    /// @param marketId     ID of the market being created
    function registerMarket(ERC20 payoutToken_, ERC20 quoteToken_)
        external
        returns (uint256 marketId);

    /// @notice     Get the auctioneer for the provided market ID
    /// @param id_  ID of Market
    function getAuctioneer(uint256 id_) external view returns (IBondAuctioneer);

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @dev                Accounts for debt and control variable decay since last deposit (vs _marketPrice())
    /// @param id_          ID of market
    /// @return             Price for market (see the specific auctioneer for units)
    //
    // if price is below minimum price, minimum price is returned
    // this is enforced on deposits by manipulating total debt (see _decay())
    function marketPrice(uint256 id_) external view returns (uint256);

    /// @notice             Scale value to use when converting between quote token and payout token amounts with marketPrice()
    /// @param id_          ID of market
    /// @return             Scaling factor for market in configured decimals
    function marketScale(uint256 id_) external view returns (uint256);

    /// @notice             Payout due for amount of quote tokens
    /// @dev                Accounts for debt and control variable decay so it is up to date
    /// @param amount_      Amount of quote tokens to spend
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    /// @return             amount of payout tokens to be paid
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) external view returns (uint256);

    /// @notice             Returns maximum amount of quote token accepted by the market
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256);

    /// @notice             Does market send payout immediately
    /// @param id_          Market ID to search for
    function isInstantSwap(uint256 id_) external view returns (bool);

    /// @notice             Is a given market accepting deposits
    /// @param id_          ID of market
    function isLive(uint256 id_) external view returns (bool);

    /// @notice             Returns array of active market IDs within a range
    /// @dev                Should be used if length exceeds max to query entire array
    function liveMarketsBetween(uint256 firstIndex_, uint256 lastIndex_)
        external
        view
        returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given quote token
    /// @param token_       Address of token to query by
    /// @param isPayout_    If true, search by payout token, else search for quote token
    function liveMarketsFor(address token_, bool isPayout_)
        external
        view
        returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given owner
    /// @param owner_       Address of owner to query by
    /// @param firstIndex_  Market ID to start at
    /// @param lastIndex_   Market ID to end at (non-inclusive)
    function liveMarketsBy(
        address owner_,
        uint256 firstIndex_,
        uint256 lastIndex_
    ) external view returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given payout and quote token
    /// @param payout_      Address of payout token
    /// @param quote_       Address of quote token
    function marketsFor(address payout_, address quote_) external view returns (uint256[] memory);

    /// @notice                 Returns the market ID with the highest current payoutToken payout for depositing quoteToken
    /// @param payout_          Address of payout token
    /// @param quote_           Address of quote token
    /// @param amountIn_        Amount of quote tokens to deposit
    /// @param minAmountOut_    Minimum amount of payout tokens to receive as payout
    /// @param maxExpiry_       Latest acceptable vesting timestamp for bond
    ///                         Inputting the zero address will take into account just the protocol fee.
    function findMarketFor(
        address payout_,
        address quote_,
        uint256 amountIn_,
        uint256 minAmountOut_,
        uint256 maxExpiry_
    ) external view returns (uint256 id);

    /// @notice             Returns the Teller that services the market ID
    function getTeller(uint256 id_) external view returns (IBondTeller);

    /// @notice             Returns current capacity of a market
    function currentCapacity(uint256 id_) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";
import {IBondAggregator} from "../interfaces/IBondAggregator.sol";

interface IBondAuctioneer {
    /// @notice                 Creates a new bond market
    /// @param params_          Configuration data needed for market creation, encoded in a bytes array
    /// @dev                    See specific auctioneer implementations for details on encoding the parameters.
    /// @return id              ID of new bond market
    function createMarket(bytes memory params_) external returns (uint256);

    /// @notice                 Disable existing bond market
    /// @notice                 Must be market owner
    /// @param id_              ID of market to close
    function closeMarket(uint256 id_) external;

    /// @notice                 Exchange quote tokens for a bond in a specified market
    /// @notice                 Must be teller
    /// @param id_              ID of the Market the bond is being purchased from
    /// @param amount_          Amount to deposit in exchange for bond (after fee has been deducted)
    /// @param minAmountOut_    Minimum acceptable amount of bond to receive. Prevents frontrunning
    /// @return payout          Amount of payout token to be received from the bond
    function purchaseBond(
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external returns (uint256 payout);

    /// @notice                         Set market intervals to different values than the defaults
    /// @notice                         Must be market owner
    /// @dev                            Changing the intervals could cause markets to behave in unexpected way
    ///                                 tuneInterval should be greater than tuneAdjustmentDelay
    /// @param id_                      Market ID
    /// @param intervals_               Array of intervals (3)
    ///                                 1. Tune interval - Frequency of tuning
    ///                                 2. Tune adjustment delay - Time to implement downward tuning adjustments
    ///                                 3. Debt decay interval - Interval over which debt should decay completely
    function setIntervals(uint256 id_, uint32[3] calldata intervals_) external;

    /// @notice                      Designate a new owner of a market
    /// @notice                      Must be market owner
    /// @dev                         Doesn't change permissions until newOwner calls pullOwnership
    /// @param id_                   Market ID
    /// @param newOwner_             New address to give ownership to
    function pushOwnership(uint256 id_, address newOwner_) external;

    /// @notice                      Accept ownership of a market
    /// @notice                      Must be market newOwner
    /// @dev                         The existing owner must call pushOwnership prior to the newOwner calling this function
    /// @param id_                   Market ID
    function pullOwnership(uint256 id_) external;

    /// @notice             Set the auctioneer defaults
    /// @notice             Must be policy
    /// @param defaults_    Array of default values
    ///                     1. Tune interval - amount of time between tuning adjustments
    ///                     2. Tune adjustment delay - amount of time to apply downward tuning adjustments
    ///                     3. Minimum debt decay interval - minimum amount of time to let debt decay to zero
    ///                     4. Minimum deposit interval - minimum amount of time to wait between deposits
    ///                     5. Minimum market duration - minimum amount of time a market can be created for
    ///                     6. Minimum debt buffer - the minimum amount of debt over the initial debt to trigger a market shutdown
    /// @dev                The defaults set here are important to avoid edge cases in market behavior, e.g. a very short market reacts doesn't tune well
    /// @dev                Only applies to new markets that are created after the change
    function setDefaults(uint32[6] memory defaults_) external;

    /// @notice             Change the status of the auctioneer to allow creation of new markets
    /// @dev                Setting to false and allowing active markets to end will sunset the auctioneer
    /// @param status_      Allow market creation (true) : Disallow market creation (false)
    function setAllowNewMarkets(bool status_) external;

    /// @notice             Change whether a market creator is allowed to use a callback address in their markets or not
    /// @notice             Must be guardian
    /// @dev                Callback is believed to be safe, but a whitelist is implemented to prevent abuse
    /// @param creator_     Address of market creator
    /// @param status_      Allow callback (true) : Disallow callback (false)
    function setCallbackAuthStatus(address creator_, bool status_) external;

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice                 Provides information for the Teller to execute purchases on a Market
    /// @param id_              Market ID
    /// @return owner           Address of the market owner (tokens transferred from this address if no callback)
    /// @return callbackAddr    Address of the callback contract to get tokens for payouts
    /// @return payoutToken     Payout Token (token paid out) for the Market
    /// @return quoteToken      Quote Token (token received) for the Market
    /// @return vesting         Timestamp or duration for vesting, implementation-dependent
    /// @return maxPayout       Maximum amount of payout tokens you can purchase in one transaction
    function getMarketInfoForPurchase(uint256 id_)
        external
        view
        returns (
            address owner,
            address callbackAddr,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 vesting,
            uint256 maxPayout
        );

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @param id_          ID of market
    /// @return             Price for market in configured decimals
    //
    // if price is below minimum price, minimum price is returned
    function marketPrice(uint256 id_) external view returns (uint256);

    /// @notice             Scale value to use when converting between quote token and payout token amounts with marketPrice()
    /// @param id_          ID of market
    /// @return             Scaling factor for market in configured decimals
    function marketScale(uint256 id_) external view returns (uint256);

    /// @notice             Payout due for amount of quote tokens
    /// @dev                Accounts for debt and control variable decay so it is up to date
    /// @param amount_      Amount of quote tokens to spend
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    /// @return             amount of payout tokens to be paid
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) external view returns (uint256);

    /// @notice             Returns maximum amount of quote token accepted by the market
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256);

    /// @notice             Does market send payout immediately
    /// @param id_          Market ID to search for
    function isInstantSwap(uint256 id_) external view returns (bool);

    /// @notice             Is a given market accepting deposits
    /// @param id_          ID of market
    function isLive(uint256 id_) external view returns (bool);

    /// @notice             Returns the address of the market owner
    /// @param id_          ID of market
    function ownerOf(uint256 id_) external view returns (address);

    /// @notice             Returns the Teller that services the Auctioneer
    function getTeller() external view returns (IBondTeller);

    /// @notice             Returns the Aggregator that services the Auctioneer
    function getAggregator() external view returns (IBondAggregator);

    /// @notice             Returns current capacity of a market
    function currentCapacity(uint256 id_) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBondCallback {
    /// @notice                 Send payout tokens to Teller while allowing market owners to perform custom logic on received or paid out tokens
    /// @notice                 Market ID on Teller must be whitelisted
    /// @param id_              ID of the market
    /// @param inputAmount_     Amount of quote tokens bonded to the market
    /// @param outputAmount_    Amount of payout tokens to be paid out to the market
    /// @dev Must transfer the output amount of payout tokens back to the Teller
    /// @dev Should check that the quote tokens have been transferred to the contract in the _callback function
    function callback(
        uint256 id_,
        uint256 inputAmount_,
        uint256 outputAmount_
    ) external;

    /// @notice         Returns the number of quote tokens received and payout tokens paid out for a market
    /// @param id_      ID of the market
    /// @return in_     Amount of quote tokens bonded to the market
    /// @return out_    Amount of payout tokens paid out to the market
    function amountsForMarket(uint256 id_) external view returns (uint256 in_, uint256 out_);

    /// @notice         Whitelist a teller and market ID combination
    /// @notice         Must be callback owner
    /// @param teller_  Address of the Teller contract which serves the market
    /// @param id_      ID of the market
    function whitelist(address teller_, uint256 id_) external;

    /// @notice Remove a market ID on a teller from the whitelist
    /// @dev    Shutdown function in case there's an issue with the teller
    /// @param  teller_ Address of the Teller contract which serves the market
    /// @param  id_     ID of the market to remove from whitelist
    function blacklist(address teller_, uint256 id_) external;

    /// @notice         Withdraw tokens from the callback and update balances
    /// @notice         Only callback owner
    /// @param to_      Address of the recipient
    /// @param token_   Address of the token to withdraw
    /// @param amount_  Amount of tokens to withdraw
    function withdraw(
        address to_,
        ERC20 token_,
        uint256 amount_
    ) external;

    /// @notice         Deposit tokens to the callback and update balances
    /// @notice         Only callback owner
    /// @param token_   Address of the token to deposit
    /// @param amount_  Amount of tokens to deposit
    function deposit(ERC20 token_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondAuctioneer} from "../interfaces/IBondAuctioneer.sol";

interface IBondFPA is IBondAuctioneer {
    /// @notice Information pertaining to bond market
    struct BondMarket {
        address owner; // market owner. sends payout tokens, receives quote tokens (defaults to creator)
        ERC20 payoutToken; // token to pay depositors with
        ERC20 quoteToken; // token to accept as payment
        address callbackAddr; // address to call for any operations on bond purchase. Must inherit to IBondCallback.
        bool capacityInQuote; // capacity limit is in payment token (true) or in payout (false, default)
        uint256 capacity; // capacity remaining
        uint256 maxPayout; // max payout tokens out in one order
        uint256 price; // fixed price of the market (see MarketParams struct)
        uint256 scale; // scaling factor for the market (see MarketParams struct)
        uint256 sold; // payout tokens out
        uint256 purchased; // quote tokens in
    }

    /// @notice Information pertaining to market duration and vesting
    struct BondTerms {
        uint48 start; // timestamp when market starts
        uint48 conclusion; // timestamp when market no longer offered
        uint48 vesting; // length of time from deposit to expiry if fixed-term, vesting timestamp if fixed-expiry
    }

    /// @notice             Parameters to create a new bond market
    /// @dev                Note price should be passed in a specific format:
    ///                     formatted price = (payoutPriceCoefficient / quotePriceCoefficient)
    ///                             * 10**(36 + scaleAdjustment + quoteDecimals - payoutDecimals + payoutPriceDecimals - quotePriceDecimals)
    ///                     where:
    ///                         payoutDecimals - Number of decimals defined for the payoutToken in its ERC20 contract
    ///                         quoteDecimals - Number of decimals defined for the quoteToken in its ERC20 contract
    ///                         payoutPriceCoefficient - The coefficient of the payoutToken price in scientific notation (also known as the significant digits)
    ///                         payoutPriceDecimals - The significand of the payoutToken price in scientific notation (also known as the base ten exponent)
    ///                         quotePriceCoefficient - The coefficient of the quoteToken price in scientific notation (also known as the significant digits)
    ///                         quotePriceDecimals - The significand of the quoteToken price in scientific notation (also known as the base ten exponent)
    ///                         scaleAdjustment - see below
    ///                         * In the above definitions, the "prices" need to have the same unit of account (i.e. both in OHM, $, ETH, etc.)
    ///                         If price is not provided in this format, the market will not behave as intended.
    /// @param params_      Encoded bytes array, with the following elements
    /// @dev                    0. Payout Token (token paid out)
    /// @dev                    1. Quote Token (token to be received)
    /// @dev                    2. Callback contract address, should conform to IBondCallback. If 0x00, tokens will be transferred from market.owner
    /// @dev                    3. Is Capacity in Quote Token?
    /// @dev                    4. Capacity (amount in quoteDecimals or amount in payoutDecimals)
    /// @dev                    5. Formatted price (see note above)
    /// @dev                    6. Deposit interval (seconds). Desired frequency of bonds. Used to calculate max payout of market (maxPayout = length / depositInterval * capacity).
    /// @dev                    7. Is fixed term ? Vesting length (seconds) : Vesting expiry (timestamp).
    /// @dev                        A 'vesting' param longer than 50 years is considered a timestamp for fixed expiry.
    /// @dev                    8. Start Time of the Market (timestamp) - Allows starting a market in the future.
    /// @dev                        If a start time is provided, the txn must be sent prior to the start time (functions as a deadline).
    /// @dev                        If start time is not provided (i.e. 0), the market will start immediately.
    /// @dev                    9. Market Duration (seconds) - Duration of the market in seconds.
    /// @dev                    10. Market scaling factor adjustment, ranges from -24 to +24 within the configured market bounds.
    /// @dev                        Should be calculated as: (payoutDecimals - quoteDecimals) - ((payoutPriceDecimals - quotePriceDecimals) / 2)
    /// @dev                        Providing a scaling factor adjustment that doesn't follow this formula could lead to under or overflow errors in the market.
    /// @return                 ID of new bond market
    struct MarketParams {
        ERC20 payoutToken;
        ERC20 quoteToken;
        address callbackAddr;
        bool capacityInQuote;
        uint256 capacity;
        uint256 formattedPrice;
        uint48 depositInterval;
        uint48 vesting;
        uint48 start;
        uint48 duration;
        int8 scaleAdjustment;
    }

    /// @notice Set the minimum market duration
    /// @notice Access controlled
    /// @param duration_ Minimum market duration in seconds
    function setMinMarketDuration(uint48 duration_) external;

    /// @notice Set the minimum deposit interval
    /// @notice Access controlled
    /// @param depositInterval_ Minimum deposit interval in seconds
    function setMinDepositInterval(uint48 depositInterval_) external;

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @param id_          ID of market
    /// @return             Price for market in configured decimals (see MarketParams)
    /// @dev price is derived from the equation:
    //
    // p = f_p
    //
    // where
    // p = price
    // f_p = fixed price provided on creation
    //
    function marketPrice(uint256 id_) external view override returns (uint256);

    /// @notice             Calculate max payout of the market in payout tokens
    /// @dev                Returns a dynamically calculated payout or the maximum set by the creator, whichever is less.
    /// @param id_          ID of market
    /// @return             Current max payout for the market in payout tokens
    function maxPayout(uint256 id_) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20BondToken} from "../ERC20BondToken.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBondFixedExpiryTeller {
    /// @notice          Redeem a fixed-expiry bond token for the underlying token (bond token must have matured)
    /// @param token_    Token to redeem
    /// @param amount_   Amount to redeem
    function redeem(ERC20BondToken token_, uint256 amount_) external;

    /// @notice              Deposit an ERC20 token and mint a future-dated ERC20 bond token
    /// @param underlying_   ERC20 token redeemable when the bond token vests
    /// @param expiry_       Timestamp at which the bond token can be redeemed for the underlying token
    /// @param amount_       Amount of underlying tokens to deposit
    /// @return              Address of the ERC20 bond token received
    /// @return              Amount of the ERC20 bond token received
    function create(
        ERC20 underlying_,
        uint48 expiry_,
        uint256 amount_
    ) external returns (ERC20BondToken, uint256);

    /// @notice             Deploy a new ERC20 bond token for an (underlying, expiry) pair and return its address
    /// @dev                ERC20 used for fixed-expiry
    /// @dev                If a bond token exists for the (underlying, expiry) pair, it returns that address
    /// @param underlying_  ERC20 token redeemable when the bond token vests
    /// @param expiry_      Timestamp at which the bond token can be redeemed for the underlying token
    /// @return             Address of the ERC20 bond token being created
    function deploy(ERC20 underlying_, uint48 expiry_) external returns (ERC20BondToken);

    /// @notice         Get the ERC20BondToken contract corresponding to a market
    /// @param id_      ID of the market
    /// @return         ERC20BondToken contract address
    function getBondTokenForMarket(uint256 id_) external view returns (ERC20BondToken);

    /// @notice             Get the ERC20BondToken contract corresponding to an (underlying, expiry) pair, reverts if no token exists
    /// @param underlying_  ERC20 token redeemable when the bond token vests
    /// @param expiry_      Timestamp at which the bond token can be redeemed for the underlying token (this is rounded to the nearest day)
    /// @return             ERC20BondToken contract address
    function getBondToken(ERC20 underlying_, uint48 expiry_) external view returns (ERC20BondToken);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBondTeller {
    /// @notice                 Exchange quote tokens for a bond in a specified market
    /// @param recipient_       Address of recipient of bond. Allows deposits for other addresses
    /// @param referrer_        Address of referrer who will receive referral fee. For frontends to fill.
    ///                         Direct calls can use the zero address for no referrer fee.
    /// @param id_              ID of the Market the bond is being purchased from
    /// @param amount_          Amount to deposit in exchange for bond
    /// @param minAmountOut_    Minimum acceptable amount of bond to receive. Prevents frontrunning
    /// @return                 Amount of payout token to be received from the bond
    /// @return                 Timestamp at which the bond token can be redeemed for the underlying token
    function purchase(
        address recipient_,
        address referrer_,
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external returns (uint256, uint48);

    /// @notice          Get current fee charged by the teller based on the combined protocol and referrer fee
    /// @param referrer_ Address of the referrer
    /// @return          Fee in basis points (3 decimal places)
    function getFee(address referrer_) external view returns (uint48);

    /// @notice         Set protocol fee
    /// @notice         Must be guardian
    /// @param fee_     Protocol fee in basis points (3 decimal places)
    function setProtocolFee(uint48 fee_) external;

    /// @notice          Set the discount for creating bond tokens from the base protocol fee
    /// @dev             The discount is subtracted from the protocol fee to determine the fee
    ///                  when using create() to mint bond tokens without using an Auctioneer
    /// @param discount_ Create Fee Discount in basis points (3 decimal places)
    function setCreateFeeDiscount(uint48 discount_) external;

    /// @notice         Set your fee as a referrer to the protocol
    /// @notice         Fee is set for sending address
    /// @param fee_     Referrer fee in basis points (3 decimal places)
    function setReferrerFee(uint48 fee_) external;

    /// @notice         Claim fees accrued by sender in the input tokens and sends them to the provided address
    /// @param tokens_  Array of tokens to claim fees for
    /// @param to_      Address to send fees to
    function claimFees(ERC20[] memory tokens_, address to_) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Clone} from "clones/Clone.sol";

/// @notice Modern and gas efficient ERC20 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract CloneERC20 is Clone {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                               METADATA
    //////////////////////////////////////////////////////////////*/

    function name() external pure returns (string memory) {
        return string(abi.encodePacked(_getArgUint256(0)));
    }

    function symbol() external pure returns (string memory) {
        return string(abi.encodePacked(_getArgUint256(0x20)));
    }

    function decimals() external pure returns (uint8) {
        return _getArgUint8(0x40);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] += amount;

        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);

        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] -= amount;

        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    function _getImmutableVariablesOffset() internal pure returns (uint256 offset) {
        assembly {
            offset := sub(calldatasize(), add(shr(240, calldataload(sub(calldatasize(), 2))), 2))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice Safe ERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// @author Taken from Solmate.
library TransferHelper {
    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, amount)
        );

        require(
            success &&
                (data.length == 0 || abi.decode(data, (bool))) &&
                address(token).code.length > 0,
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transfer.selector, to, amount)
        );

        require(
            success &&
                (data.length == 0 || abi.decode(data, (bool))) &&
                address(token).code.length > 0,
            "TRANSFER_FAILED"
        );
    }

    // function safeApprove(
    //     ERC20 token,
    //     address to,
    //     uint256 amount
    // ) internal {
    //     (bool success, bytes memory data) = address(token).call(
    //         abi.encodeWithSelector(ERC20.approve.selector, to, amount)
    //     );

    //     require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    // }

    // function safeTransferETH(address to, uint256 amount) internal {
    //     (bool success, ) = to.call{value: amount}(new bytes(0));

    //     require(success, "ETH_TRANSFER_FAILED");
    // }
}