// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import '../interfaces/StorageInterfaceV5.sol';

pragma solidity 0.8.17;

contract GNSReferralsV6_2 is Initializable {

    // CONSTANTS
    uint constant PRECISION = 1e10;
    StorageInterfaceV5 public storageT;

    // ADJUSTABLE PARAMETERS
    uint public allyFeeP;           // % (of referrer fees going to allies, eg. 10)
    uint public startReferrerFeeP;  // % (of referrer fee when 0 volume referred, eg. 75)
    uint public openFeeP;           // % (of opening fee used for referral system, eg. 33)
    uint public targetVolumeDai;    // DAI (to reach maximum referral system fee, eg. 1e8)

    // CUSTOM TYPES
    struct AllyDetails{
        address[] referrersReferred;
        uint volumeReferredDai;    // 1e18
        uint pendingRewardsToken;  // 1e18
        uint totalRewardsToken;    // 1e18
        uint totalRewardsValueDai; // 1e18
        bool active;
    }

    struct ReferrerDetails{
        address ally;
        address[] tradersReferred;
        uint volumeReferredDai;    // 1e18
        uint pendingRewardsToken;  // 1e18
        uint totalRewardsToken;    // 1e18
        uint totalRewardsValueDai; // 1e18
        bool active;
    }

    // STATE (MAPPINGS)
    mapping(address => AllyDetails) public allyDetails;
    mapping(address => ReferrerDetails) public referrerDetails;

    mapping(address => address) public referrerByTrader;

    // EVENTS
    event UpdatedAllyFeeP(uint value);
    event UpdatedStartReferrerFeeP(uint value);
    event UpdatedOpenFeeP(uint value);
    event UpdatedTargetVolumeDai(uint value);

    event AllyWhitelisted(address indexed ally);
    event AllyUnwhitelisted(address indexed ally);

    event ReferrerWhitelisted(
        address indexed referrer,
        address indexed ally
    );
    event ReferrerUnwhitelisted(address indexed referrer);
    event ReferrerRegistered(
        address indexed trader,
        address indexed referrer
    );

    event AllyRewardDistributed(
        address indexed ally,
        address indexed trader,
        uint volumeDai,
        uint amountToken,
        uint amountValueDai
    );
    event ReferrerRewardDistributed(
        address indexed referrer,
        address indexed trader,
        uint volumeDai,
        uint amountToken,
        uint amountValueDai
    );

    event AllyRewardsClaimed(
        address indexed ally,
        uint amountToken
    );
    event ReferrerRewardsClaimed(
        address indexed referrer,
        uint amountToken
    );

    function initialize(
        StorageInterfaceV5 _storageT,
        uint _allyFeeP,
        uint _startReferrerFeeP,
        uint _openFeeP,
        uint _targetVolumeDai
    ) external initializer {
        require(address(_storageT) != address(0)
            && _allyFeeP <= 50
            && _startReferrerFeeP <= 100
            && _openFeeP <= 50
            && _targetVolumeDai > 0, "WRONG_PARAMS");

        storageT = _storageT;

        allyFeeP = _allyFeeP;
        startReferrerFeeP = _startReferrerFeeP;
        openFeeP = _openFeeP;
        targetVolumeDai = _targetVolumeDai;
    }

    // MODIFIERS
    modifier onlyGov(){
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyTrading(){
        require(msg.sender == storageT.trading(), "TRADING_ONLY");
        _;
    }
    modifier onlyCallbacks(){
        require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY");
        _;
    }

    // MANAGE PARAMETERS
    function updateAllyFeeP(uint value) external onlyGov{
        require(value <= 50, "VALUE_ABOVE_50");

        allyFeeP = value;
        
        emit UpdatedAllyFeeP(value);
    }
    function updateStartReferrerFeeP(uint value) external onlyGov{
        require(value <= 100, "VALUE_ABOVE_100");

        startReferrerFeeP = value;

        emit UpdatedStartReferrerFeeP(value);
    }
    function updateOpenFeeP(uint value) external onlyGov{
        require(value <= 50, "VALUE_ABOVE_50");

        openFeeP = value;

        emit UpdatedOpenFeeP(value);
    }
    function updateTargetVolumeDai(uint value) external onlyGov{
        require(value > 0, "VALUE_0");

        targetVolumeDai = value;
        
        emit UpdatedTargetVolumeDai(value);
    }

    // MANAGE ALLIES
    function whitelistAlly(address ally) external onlyGov{
        require(ally != address(0), "ADDRESS_0");

        AllyDetails storage a = allyDetails[ally];
        require(!a.active, "ALLY_ALREADY_ACTIVE");

        a.active = true;

        emit AllyWhitelisted(ally);
    }
    function unwhitelistAlly(address ally) external onlyGov{
        AllyDetails storage a = allyDetails[ally];
        require(a.active, "ALREADY_UNACTIVE");

        a.active = false;

        emit AllyUnwhitelisted(ally);
    }

    // MANAGE REFERRERS
    function whitelistReferrer(
        address referrer,
        address ally
    ) external onlyGov{
        
        require(referrer != address(0), "ADDRESS_0");

        ReferrerDetails storage r = referrerDetails[referrer];      
        require(!r.active, "REFERRER_ALREADY_ACTIVE");

        r.active = true;
        
        if(ally != address(0)){
            AllyDetails storage a = allyDetails[ally];
            require(a.active, "ALLY_NOT_ACTIVE");

            r.ally = ally;
            a.referrersReferred.push(referrer);
        }

        emit ReferrerWhitelisted(referrer, ally);
    }
    function unwhitelistReferrer(address referrer) external onlyGov{
        ReferrerDetails storage r = referrerDetails[referrer];
        require(r.active, "ALREADY_UNACTIVE");

        r.active = false;

        emit ReferrerUnwhitelisted(referrer);
    }

    function registerPotentialReferrer(
        address trader,
        address referrer
    ) external onlyTrading{

        ReferrerDetails storage r = referrerDetails[referrer];

        if(referrerByTrader[trader] != address(0)
        || referrer == address(0)
        || !r.active){
            return;
        }

        referrerByTrader[trader] = referrer;
        r.tradersReferred.push(trader);

        emit ReferrerRegistered(trader, referrer);
    }

    // REWARDS DISTRIBUTION
    function distributePotentialReward(
        address trader,
        uint volumeDai,
        uint pairOpenFeeP,
        uint tokenPriceDai
    ) external onlyCallbacks returns(uint){

        address referrer = referrerByTrader[trader];
        ReferrerDetails storage r = referrerDetails[referrer];

        if(!r.active){
            return 0;
        }

        uint referrerRewardValueDai = volumeDai * getReferrerFeeP(
            pairOpenFeeP,
            r.volumeReferredDai
        ) / PRECISION / 100;

        uint referrerRewardToken = referrerRewardValueDai * PRECISION / tokenPriceDai;

        storageT.handleTokens(address(this), referrerRewardToken, true);

        AllyDetails storage a = allyDetails[r.ally];
        
        uint allyRewardValueDai;
        uint allyRewardToken;

        if(a.active){
            allyRewardValueDai = referrerRewardValueDai * allyFeeP / 100;
            allyRewardToken = referrerRewardToken * allyFeeP / 100;

            a.volumeReferredDai += volumeDai;
            a.pendingRewardsToken += allyRewardToken;
            a.totalRewardsToken += allyRewardToken;
            a.totalRewardsValueDai += allyRewardValueDai;

            referrerRewardValueDai -= allyRewardValueDai;
            referrerRewardToken -= allyRewardToken;

            emit AllyRewardDistributed(
                r.ally,
                trader,
                volumeDai,
                allyRewardToken,
                allyRewardValueDai
            );
        }

        r.volumeReferredDai += volumeDai;
        r.pendingRewardsToken += referrerRewardToken;
        r.totalRewardsToken += referrerRewardToken;
        r.totalRewardsValueDai += referrerRewardValueDai;

        emit ReferrerRewardDistributed(
            referrer,
            trader,
            volumeDai,
            referrerRewardToken,
            referrerRewardValueDai
        );

        return referrerRewardValueDai + allyRewardValueDai;
    }

    // REWARDS CLAIMING
    function claimAllyRewards() external{
        AllyDetails storage a = allyDetails[msg.sender];
        uint rewardsToken = a.pendingRewardsToken;
        
        require(rewardsToken > 0, "NO_PENDING_REWARDS");

        a.pendingRewardsToken = 0;
        storageT.token().transfer(msg.sender, rewardsToken);

        emit AllyRewardsClaimed(msg.sender, rewardsToken);
    }
    function claimReferrerRewards() external{
        ReferrerDetails storage r = referrerDetails[msg.sender];
        uint rewardsToken = r.pendingRewardsToken;
        
        require(rewardsToken > 0, "NO_PENDING_REWARDS");

        r.pendingRewardsToken = 0;
        storageT.token().transfer(msg.sender, rewardsToken);

        emit ReferrerRewardsClaimed(msg.sender, rewardsToken);
    }

    // VIEW FUNCTIONS
    function getReferrerFeeP(
        uint pairOpenFeeP,
        uint volumeReferredDai
    ) public view returns(uint){

        uint maxReferrerFeeP = pairOpenFeeP * 2 * openFeeP / 100;
        uint minFeeP = maxReferrerFeeP * startReferrerFeeP / 100;

        uint feeP = minFeeP + (maxReferrerFeeP - minFeeP)
            * volumeReferredDai / 1e18 / targetVolumeDai;

        return feeP > maxReferrerFeeP ? maxReferrerFeeP : feeP;
    }

    function getPercentOfOpenFeeP(
        address trader
    ) external view returns(uint){
        return getPercentOfOpenFeeP_calc(referrerDetails[referrerByTrader[trader]].volumeReferredDai);
    }

    function getPercentOfOpenFeeP_calc(
        uint volumeReferredDai
    ) public view returns(uint resultP){
        resultP = (openFeeP * (
            startReferrerFeeP * PRECISION +
            volumeReferredDai * PRECISION * (100 - startReferrerFeeP) / 1e18 / targetVolumeDai)
        ) / 100;

        resultP = resultP > openFeeP * PRECISION ?
            openFeeP * PRECISION :
            resultP;
    }

    function getTraderReferrer(
        address trader
    ) external view returns(address){
        address referrer = referrerByTrader[trader];

        return referrerDetails[referrer].active ? referrer : address(0);
    }
    function getReferrersReferred(
        address ally
    ) external view returns (address[] memory){
        return allyDetails[ally].referrersReferred;
    }
    function getTradersReferred(
        address referred
    ) external view returns (address[] memory){
        return referrerDetails[referred].tradersReferred;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface TokenInterfaceV5{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
import './TokenInterfaceV5.sol';
import './NftInterfaceV5.sol';
import './IGToken.sol';
import './PairsStorageInterfaceV6.sol';

pragma solidity 0.8.17;

interface PoolInterfaceV5{
    function increaseAccTokensPerLp(uint) external;
}

interface PausableInterfaceV5{
    function isPaused() external view returns (bool);
}

interface StorageInterfaceV5{
    enum LimitOrder { TP, SL, LIQ, OPEN }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken;       // 1e18
        uint positionSizeDai;       // 1e18
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }
    struct TradeInfo{
        uint tokenId;
        uint tokenPriceDai;         // PRECISION
        uint openInterestDai;       // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize;          // 1e18 (DAI or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION (%)
        uint sl;                    // PRECISION (%)
        uint minPrice;              // PRECISION
        uint maxPrice;              // PRECISION
        uint block;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingMarketOrder{
        Trade trade;
        uint block;
        uint wantedPrice;           // PRECISION
        uint slippageP;             // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingNftOrder{
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    function PRECISION() external pure returns(uint);
    function gov() external view returns(address);
    function dev() external view returns(address);
    function dai() external view returns(TokenInterfaceV5);
    function token() external view returns(TokenInterfaceV5);
    function linkErc677() external view returns(TokenInterfaceV5);
    function priceAggregator() external view returns(AggregatorInterfaceV6_2);
    function vault() external view returns(IGToken);
    function trading() external view returns(address);
    function callbacks() external view returns(address);
    function handleTokens(address,uint,bool) external;
    function transferDai(address, address, uint) external;
    function transferLinkToAggregator(address, uint, uint) external;
    function unregisterTrade(address, uint, uint) external;
    function unregisterPendingMarketOrder(uint, bool) external;
    function unregisterOpenLimitOrder(address, uint, uint) external;
    function hasOpenLimitOrder(address, uint, uint) external view returns(bool);
    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;
    function openTrades(address, uint, uint) external view returns(Trade memory);
    function openTradesInfo(address, uint, uint) external view returns(TradeInfo memory);
    function updateSl(address, uint, uint, uint) external;
    function updateTp(address, uint, uint, uint) external;
    function getOpenLimitOrder(address, uint, uint) external view returns(OpenLimitOrder memory);
    function spreadReductionsP(uint) external view returns(uint);
    function storeOpenLimitOrder(OpenLimitOrder memory) external;
    function reqID_pendingMarketOrder(uint) external view returns(PendingMarketOrder memory);
    function storePendingNftOrder(PendingNftOrder memory, uint) external;
    function updateOpenLimitOrder(OpenLimitOrder calldata) external;
    function firstEmptyTradeIndex(address, uint) external view returns(uint);
    function firstEmptyOpenLimitIndex(address, uint) external view returns(uint);
    function increaseNftRewards(uint, uint) external;
    function nftSuccessTimelock() external view returns(uint);
    function reqID_pendingNftOrder(uint) external view returns(PendingNftOrder memory);
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint) external view returns(uint);
    function unregisterPendingNftOrder(uint) external;
    function handleDevGovFees(uint, uint, bool, bool) external returns(uint);
    function distributeLpRewards(uint) external;
    function storeTrade(Trade memory, TradeInfo memory) external;
    function openLimitOrdersCount(address, uint) external view returns(uint);
    function openTradesCount(address, uint) external view returns(uint);
    function pendingMarketOpenCount(address, uint) external view returns(uint);
    function pendingMarketCloseCount(address, uint) external view returns(uint);
    function maxTradesPerPair() external view returns(uint);
    function pendingOrderIdsCount(address) external view returns(uint);
    function maxPendingMarketOrders() external view returns(uint);
    function openInterestDai(uint, uint) external view returns(uint);
    function getPendingOrderIds(address) external view returns(uint[] memory);
    function nfts(uint) external view returns(NftInterfaceV5);
    function fakeBlockNumber() external view returns(uint); // Testing
}

interface AggregatorInterfaceV6_2{
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE, UPDATE_SL }
    function pairsStorage() external view returns(PairsStorageInterfaceV6);
    function getPrice(uint,OrderType,uint) external returns(uint);
    function tokenPriceDai() external returns(uint);
    function linkFee(uint,uint) external view returns(uint);
    function openFeeP(uint) external view returns(uint);
    function pendingSlOrders(uint) external view returns(PendingSl memory);
    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;
    function unregisterPendingSlOrder(uint orderId) external;
    struct PendingSl{address trader; uint pairIndex; uint index; uint openPrice; bool buy; uint newSl; }
}

interface NftRewardsInterfaceV6{
    struct TriggeredLimitId{ address trader; uint pairIndex; uint index; StorageInterfaceV5.LimitOrder order; }
    enum OpenLimitOrderType{ LEGACY, REVERSAL, MOMENTUM }
    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;
    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;
    function unregisterTrigger(TriggeredLimitId calldata) external;
    function distributeNftReward(TriggeredLimitId calldata, uint) external;
    function openLimitOrderTypes(address, uint, uint) external view returns(OpenLimitOrderType);
    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;
    function triggered(TriggeredLimitId calldata) external view returns(bool);
    function timedOut(TriggeredLimitId calldata) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface PairsStorageInterfaceV6{
    enum FeedCalculation { DEFAULT, INVERT, COMBINE }    // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed{ address feed1; address feed2; FeedCalculation feedCalculation; uint maxDeviationP; } // PRECISION (%)
    function incrementCurrentOrderId() external returns(uint);
    function updateGroupCollateral(uint, uint, bool, bool) external;
    function pairJob(uint) external returns(string memory, string memory, bytes32, uint);
    function pairFeed(uint) external view returns(Feed memory);
    function pairSpreadP(uint) external view returns(uint);
    function pairMinLeverage(uint) external view returns(uint);
    function pairMaxLeverage(uint) external view returns(uint);
    function groupMaxCollateral(uint) external view returns(uint);
    function groupCollateral(uint, bool) external view returns(uint);
    function guaranteedSlEnabled(uint) external view returns(bool);
    function pairOpenFeeP(uint) external view returns(uint);
    function pairCloseFeeP(uint) external view returns(uint);
    function pairOracleFeeP(uint) external view returns(uint);
    function pairNftLimitOrderFeeP(uint) external view returns(uint);
    function pairReferralFeeP(uint) external view returns(uint);
    function pairMinLevPosDai(uint) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface NftInterfaceV5{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGToken{
    function manager() external view returns(address);
    function admin() external view returns(address);
    function currentEpoch() external view returns(uint);
    function currentEpochStart() external view returns(uint);
    function currentEpochPositiveOpenPnl() external view returns(uint);
    function updateAccPnlPerTokenUsed(uint prevPositiveOpenPnl, uint newPositiveOpenPnl) external returns(uint);

    struct LockedDeposit {
        address owner;
        uint shares;          // 1e18
        uint assetsDeposited; // 1e18
        uint assetsDiscount;  // 1e18
        uint atTimestamp;     // timestamp
        uint lockDuration;    // timestamp
    }
    function getLockedDeposit(uint depositId) external view returns(LockedDeposit memory);

    function sendAssets(uint assets, address receiver) external;
    function receiveAssets(uint assets, address user) external;
    function distributeReward(uint assets) external;

    function currentBalanceDai() external view returns(uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}