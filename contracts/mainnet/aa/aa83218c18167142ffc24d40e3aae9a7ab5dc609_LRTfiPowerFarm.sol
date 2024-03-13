/**
 *Submitted for verification at Arbiscan.io on 2024-03-11
*/

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.24;

error NoValue();
error NotMaster();
error NotProposed();

contract OwnableMaster {

    address public master;
    address public proposedMaster;

    address internal constant ZERO_ADDRESS = address(0x0);

    modifier onlyProposed() {
        _onlyProposed();
        _;
    }

    function _onlyMaster()
        private
        view
    {
        if (msg.sender == master) {
            return;
        }

        revert NotMaster();
    }

    modifier onlyMaster() {
        _onlyMaster();
        _;
    }

    function _onlyProposed()
        private
        view
    {
        if (msg.sender == proposedMaster) {
            return;
        }

        revert NotProposed();
    }

    event MasterProposed(
        address indexed proposer,
        address indexed proposedMaster
    );

    event RenouncedOwnership(
        address indexed previousMaster
    );

    constructor(
        address _master
    ) {
        if (_master == ZERO_ADDRESS) {
            revert NoValue();
        }
        master = _master;
    }

    /**
     * @dev Allows to propose next master.
     * Must be claimed by proposer.
     */
    function proposeOwner(
        address _proposedOwner
    )
        external
        onlyMaster
    {
        if (_proposedOwner == ZERO_ADDRESS) {
            revert NoValue();
        }

        proposedMaster = _proposedOwner;

        emit MasterProposed(
            msg.sender,
            _proposedOwner
        );
    }

    /**
     * @dev Allows to claim master role.
     * Must be called by proposer.
     */
    function claimOwnership()
        external
        onlyProposed
    {
        master = proposedMaster;
    }

    /**
     * @dev Removes master role.
     * No ability to be in control.
     */
    function renounceOwnership()
        external
        onlyMaster
    {
        master = ZERO_ADDRESS;
        proposedMaster = ZERO_ADDRESS;

        emit RenouncedOwnership(
            msg.sender
        );
    }
}




interface IERC20 {

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool);

    function decimals()
        external
        view
        returns (uint8);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event  Deposit(
        address indexed dst,
        uint wad
    );

    event  Withdrawal(
        address indexed src,
        uint wad
    );
}




interface IAave {

    struct ReserveData {

        // Stores the reserve configuration
        ReserveConfigurationMap configuration;

        // Liquidity index. Expressed in ray
        uint128 liquidityIndex;

        // Current supply rate. Expressed in ray
        uint128 currentLiquidityRate;

        // Variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;

        // Current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;

        // Current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;

        // Timestamp of last update
        uint40 lastUpdateTimestamp;

        // Id of the reserve.
        uint16 id;

        // aToken address
        address aTokenAddress;

        // stableDebtToken address
        address stableDebtTokenAddress;

        // VariableDebtToken address
        address variableDebtTokenAddress;

        // Address of the interest rate strategy
        address interestRateStrategyAddress;

        // Current treasury balance, scaled
        uint128 accruedToTreasury;

        // Outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;

        // Outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        uint256 data;
    }

    function supply(
        address _token,
        uint256 _amount,
        address _owner,
        uint16 _referralCode
    )
        external;

    function withdraw(
        address _token,
        uint256 _amount,
        address _recipient
    )
        external
        returns (uint256);

    function getReserveData(
        address asset
    )
        external
        view
        returns (ReserveData memory);

}




struct MarketStorage {
    int128 totalPt;
    int128 totalSy;
    uint96 lastLnImpliedRate;
    uint16 observationIndex;
    uint16 observationCardinality;
    uint16 observationCardinalityNext;
}

struct MarketState {
    int256 totalPt;
    int256 totalSy;
    int256 totalLp;
    address treasury;
    int256 scalarRoot;
    uint256 expiry;
    uint256 lnFeeRateRoot;
    uint256 reserveFeePercent;
    uint256 lastLnImpliedRate;
}

struct LockedPosition {
    uint128 amount;
    uint128 expiry;
}

struct UserReward {
    uint128 index;
    uint128 accrued;
}

struct ApproxParams {
    uint256 guessMin;
    uint256 guessMax;
    uint256 guessOffchain;
    uint256 maxIteration;
    uint256 eps;
}

interface IPendleSy {

    function decimals()
        external
        view
        returns (uint8);

    function previewDeposit(
        address _tokenIn,
        uint256 _amountTokenToDeposit
    )
        external
        view
        returns (uint256 sharesAmount);

    function deposit(
        address _receiver,
        address _tokenIn,
        uint256 _amountTokenToDeposit,
        uint256 _minSharesOut
    )
        external
        returns (uint256 sharesAmount);

    function exchangeRate()
        external
        view
        returns (uint256);

    function redeem(
        address _receiver,
        uint256 _amountSharesToRedeem,
        address _tokenOut,
        uint256 _minTokenOut,
        bool _burnFromInternalBalance
    )
        external
        returns (uint256 amountTokenOut);
}

interface IPendleYt {

    function mintPY(
        address _receiverPT,
        address _receiverYT
    )
        external
        returns (uint256 pyAmount);

    function redeemPY(
        address _receiver
    )
        external
        returns (uint256);

    function redeemDueInterestAndRewards(
        address _user,
        bool _redeemInterest,
        bool _redeemRewards
    )
        external
        returns (
            uint256 interestOut,
            uint256[] memory rewardsOut
        );

    function getRewardTokens()
        external
        view
        returns (address[] memory);

    function userReward(
        address _token,
        address _user
    )
        external
        view
        returns (UserReward memory);

    function userInterest(
        address user
    )
        external
        view
        returns (
            uint128 lastPYIndex,
            uint128 accruedInterest
        );

    function pyIndexStored()
        external
        view
        returns (uint256);
}

interface IPendleMarket {

    function readTokens()
        external
        view
        returns (
            address SY,
            address PT,
            address YT
        );

    function activeBalance(
        address _user
    )
        external
        view
        returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        external;

    function balanceOf(
        address _user
    )
        external
        view
        returns (uint256);

    function isExpired()
        external
        view
        returns (bool);

    function decimals()
        external
        view
        returns (uint8);

    function increaseObservationsCardinalityNext(
        uint16 _newObservationCardinalityNext
    )
        external;

    function swapExactPtForSy(
        address receiver,
        uint256 exactPtIn,
        bytes calldata data
    )
        external
        returns (
            uint256 netSyOut,
            uint256 netSyFee
        );

    function _storage()
        external
        view
        returns (MarketStorage memory);

    function getRewardTokens()
        external
        view
        returns (address[] memory);

    function readState(
        address _router
    )
        external
        view
        returns (MarketState memory marketState);

    function mint(
        address _receiver,
        uint256 _netSyDesired,
        uint256 _netPtDesired
    )
        external
        returns (uint256[3] memory);

    function burn(
        address _receiverAddressSy,
        address _receiverAddressPt,
        uint256 _lpToBurn
    )
        external
        returns (
            uint256 syOut,
            uint256 ptOut
        );

    function redeemRewards(
        address _user
    )
        external
        returns (uint256[] memory);

    function totalSupply()
        external
        view
        returns (uint256);

    function userReward(
        address _token,
        address _user
    )
        external
        view
        returns (UserReward memory);
}

interface IPendleChild {

    function underlyingLpAssetsCurrent()
        external
        view
        returns (uint256);

    function totalLpAssets()
        external
        view
        returns (uint256);

    function totalSupply()
        external
        view
        returns (uint256);

    function previewUnderlyingLpAssets()
        external
        view
        returns (uint256);

    function previewMintShares(
        uint256 _underlyingAssetAmount,
        uint256 _underlyingLpAssetsCurrent
    )
        external
        view
        returns (uint256);

    function previewAmountWithdrawShares(
        uint256 _shares,
        uint256 _underlyingLpAssetsCurrent
    )
        external
        view
        returns (uint256);

    function previewBurnShares(
        uint256 _underlyingAssetAmount,
        uint256 _underlyingLpAssetsCurrent
    )
        external
        view
        returns (uint256);

    function depositExactAmount(
        uint256 _amount
    )
        external
        returns (
            uint256,
            uint256
        );

    function withdrawExactShares(
        uint256 _shares
    )
        external
        returns (uint256);
}

interface IPendleLock {

    function increaseLockPosition(
        uint128 _additionalAmountToLock,
        uint128 _newExpiry
    )
        external
        returns (uint128 newVeBalance);

    function withdraw()
        external
        returns (uint128);

    function positionData(
        address _user
    )
        external
        view
        returns (LockedPosition memory);

    function getBroadcastPositionFee(
        uint256[] calldata _chainIds
    )
        external
        view
        returns (uint256);
}

interface IPendleVoteRewards {
    function claimRetail(
        address _user,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    )
        external
        returns (uint256);
}

interface IPendleVoter {
    function vote(
        address[] memory _pools,
        uint64[] memory _weights
    )
        external;
}

interface IPendleRouter {

    function swapSyForExactYt(
        address _receiver,
        address _market,
        uint256 _exactYtOut,
        uint256 _maxSyIn
    )
        external
        returns (
            uint256 netSyIn,
            uint256 netSyFee
        );

    function swapExactSyForYt(
        address _receiver,
        address _market,
        uint256 _exactSyIn,
        uint256 _minYtOut
    )
        external
        returns (
            uint256 netYtOut,
            uint256 netSyFee
        );

    function swapSyForExactPt(
        address _receiver,
        address _market,
        uint256 _exactPtOut,
        uint256 _maxSyIn
    )
        external
        returns (
            uint256 netSyIn,
            uint256 netSyFee
        );

    function swapExactSyForPt(
        address _receiver,
        address _market,
        uint256 _exactSyIn,
        uint256 _minPtOut
    )
        external
        returns (
            uint256 netPtOut,
            uint256 netSyFee
        );

    function removeLiquiditySingleSy(
        address _receiver,
        address _market,
        uint256 _netLpToRemove,
        uint256 _minSyOut
    )
        external
        returns (
            uint256 netSyOut,
            uint256 netSyFee
        );

    function addLiquiditySingleSy(
        address _receiver,
        address _market,
        uint256 _netSyIn,
        uint256 _minLpOut,
        ApproxParams calldata _guessPtReceivedFromSy
    )
        external
        returns (
            uint256 netLpOut,
            uint256 netSyFee
        );
}

interface IPendleRouterStatic {

    function addLiquiditySingleSyStatic(
        address _market,
        uint256 _netSyIn
    )
        external
        view
        returns (
            uint256 netLpOut,
            uint256 netPtFromSwap,
            uint256 netSyFee,
            uint256 priceImpact,
            uint256 exchangeRateAfter,
            uint256 netSyToSwap
        );

    function swapExactPtForSyStatic(
        address _market,
        uint256 _exactPtIn
    )
        external
        view
        returns (
            uint256 netSyOut,
            uint256 netSyFee,
            uint256 priceImpact,
            uint256 exchangeRateAfter
        );
}




interface IAaveHub {

    function AAVE_ADDRESS()
        external
        view
        returns (address);

    function WETH_ADDRESS()
        external
        view
        returns (address);

    function aaveTokenAddress(
        address _underlyingToken
    )
        external
        view
        returns (address);

    function setAaveTokenAddress(
        address _underlyingToken,
        address _aaveToken
    )
        external;

    function borrowExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _borrowAmount
    )
        external
        returns (uint256);

    function paybackExactShares(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _shares
    )
        external
        returns (uint256);

    function paybackExactAmountETH(
        uint256 _nftId
    )
        external
        payable
        returns (uint256);

    function paybackExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _shares
    )
        external
        returns (uint256);

    function depositExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _amount
    )
        external
        returns (uint256);

    function depositExactAmountETH(
        uint256 _nftId
    )
        external
        payable
        returns (uint256);

    function depositExactAmountETHMint()
        external
        payable
        returns (uint256);

    function withdrawExactShares(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _shares
    )
        external
        returns (uint256);

    function withdrawExactAmount(
        uint256 _nftId,
        address _token,
        uint256 _amount
    )
        external
        returns (uint256);

    function sendingProgressAaveHub()
        external
        view
        returns (bool);
}




struct GlobalPoolEntry {
    uint256 totalPool;
    uint256 utilization;
    uint256 totalBareToken;
    uint256 poolFee;
}

struct BorrowPoolEntry {
    bool allowBorrow;
    uint256 pseudoTotalBorrowAmount;
    uint256 totalBorrowShares;
    uint256 borrowRate;
}

struct LendingPoolEntry {
    uint256 pseudoTotalPool;
    uint256 totalDepositShares;
    uint256 collateralFactor;
}

struct PoolEntry {
    uint256 totalPool;
    uint256 utilization;
    uint256 totalBareToken;
    uint256 poolFee;
}

struct BorrowRatesEntry {
    uint256 pole;
    uint256 deltaPole;
    uint256 minPole;
    uint256 maxPole;
    uint256 multiplicativeFactor;
}

interface IWiseLending {

    function borrowRatesData(
        address _pooToken
    )
        external
        view
        returns (BorrowRatesEntry memory);

    function newBorrowRate(
        address _poolToken
    )
        external;

    function calculateBorrowShares(
        address _poolToken,
        uint256 _amount,
        bool _maxSharePrice
    )
        external
        view
        returns (uint256);

    function borrowPoolData(
        address _poolToken
    )
        external
        view
        returns (BorrowPoolEntry memory);

    function lendingPoolData(
        address _poolToken
    )
        external
        view
        returns (LendingPoolEntry memory);

    function getPositionBorrowShares(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getTimeStamp(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getPureCollateralAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function isUncollateralized(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (bool);

    function verifiedIsolationPool(
        address _poolAddress
    )
        external
        view
        returns (bool);

    function positionLocked(
        uint256 _nftId
    )
        external
        view
        returns (bool);

    function getTotalBareToken(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function maxDepositValueToken(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function master()
        external
        view
        returns (address);

    function WETH_ADDRESS()
        external
        view
        returns (address);

    function WISE_ORACLE()
        external
        view
        returns (address);

    function POSITION_NFT()
        external
        view
        returns (address);

    function FEE_MANAGER()
        external
        view
        returns (address);

    function WISE_SECURITY()
        external
        view
        returns (address);

    function lastUpdated(
        address _poolAddress
    )
        external
        view
        returns (uint256);

    function isolationPoolRegistered(
        uint256 _nftId,
        address _isolationPool
    )
        external
        view
        returns (bool);

    function calculateLendingShares(
        address _poolToken,
        uint256 _amount,
        bool _maxSharePrice
    )
        external
        view
        returns (uint256);

    function pureCollateralAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        returns (uint256);

    function getTotalPool(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function depositExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256);

    function withdrawOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256);

    function syncManually(
        address _poolToken
    )
        external;

    function withdrawOnBehalfExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        returns (uint256);

    function borrowOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256);

    function borrowExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256);

    function paybackExactAmountETH(
        uint256 _nftId
    )
        external
        payable
        returns (uint256);

    function solelyDeposit(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external;

    function paybackExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256);

    function paybackExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        returns (uint256);

    function setPoolFee(
        address _poolToken,
        uint256 _newFee
    )
        external;

    function getPositionLendingShares(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function collateralizeDeposit(
        uint256 _nftId,
        address _poolToken
    )
        external;

    function approve(
        address _spender,
        address _poolToken,
        uint256 _amount
    )
        external;

    function withdrawExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        returns (uint256);

    function withdrawExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256);

    function poolTokenAddresses()
        external
        returns (address[] memory);

    function corePaybackFeeManager(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        external;

    function sendingProgress()
        external
        view
        returns (bool);

    function depositExactAmountETH(
        uint256 _nftId
    )
        external
        payable
        returns (uint256);

    function coreLiquidationIsolationPools(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _caller,
        address _tokenToPayback,
        address _tokenToRecieve,
        uint256 _paybackAmount,
        uint256 _shareAmountToPay
    )
        external
        returns (uint256 reveiveAmount);

    function preparePool(
        address _poolToken
    )
        external;

    function getPositionBorrowTokenLength(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function getPositionBorrowTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        external
        view
        returns (address);

    function getPositionLendingTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        external
        view
        returns (address);

    function getPositionLendingTokenLength(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function globalPoolData(
        address _poolToken
    )
        external
        view
        returns (GlobalPoolEntry memory);


    function getGlobalBorrowAmount(
        address _token
    )
        external
        view
        returns (uint256);

    function getPseudoTotalBorrowAmount(
        address _token
    )
        external
        view
        returns (uint256);

    function getInitialBorrowAmountUser(
        address _user,
        address _token
    )
        external
        view
        returns (uint256);

    function getPseudoTotalPool(
        address _token
    )
        external
        view
        returns (uint256);

    function getInitialDepositAmountUser(
        address _user,
        address _token
    )
        external
        view
        returns (uint256);

    function getGlobalDepositAmount(
        address _token
    )
        external
        view
        returns (uint256);

    function paybackAmount(
        address _token,
        uint256 _shares
    )
        external
        view
        returns (uint256);

    function getPositionLendingShares(
        address _user,
        address _token
    )
        external
        view
        returns (uint256);

    function cashoutAmount(
        address _poolToken,
        uint256 _shares
    )
        external
        view
        returns (uint256);

    function getTotalDepositShares(
        address _token
    )
        external
        view
        returns (uint256);

    function getTotalBorrowShares(
        address _token
    )
        external
        view
        returns (uint256);

    function checkPositionLocked(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function checkDeposit(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function setRegistrationIsolationPool(
        uint256 _nftId,
        bool _state
    )
        external;
}




interface IStETH {

    function submit(
        address _referral
    )
        external
        payable
        returns (uint256);

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function getPooledEthByShares(
        uint256 _sharesAmount
    )
        external
        view
        returns (uint256);
}




struct CurveSwapStructToken {
    uint256 curvePoolTokenIndexFrom;
    uint256 curvePoolTokenIndexTo;
    uint256 curveMetaPoolTokenIndexFrom;
    uint256 curveMetaPoolTokenIndexTo;
}

struct CurveSwapStructData {
    address curvePool;
    address curveMetaPool;
    bytes swapBytesPool;
    bytes swapBytesMeta;
}

interface IWiseSecurity {

    function checkMinDepositValue(
        address _poolToken,
        uint256 _amount
    )
        external
        view
        returns (bool);

    function overallETHBorrow(
        uint256 _nftId
    )
        external
        view
        returns (uint256 buffer);

    function overallETHCollateralsBoth(
        uint256 _nftId
    )
        external
        view
        returns (uint256 weighted, uint256 unweightedamount);

    function getLiveDebtRatio(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function checkHealthState(
        uint256 _nftId,
        bool _isPowerFarm
    )
        external
        view;

    function checkPoolCondition(
        address _token
    )
        external
        view;

    function checkPoolWithMinDeposit(
        address _poolToken,
        uint256 _amount
    )
        external
        view
        returns (bool);

    function overallETHBorrowHeartbeat(
        uint256 _nftId
    )
        external
        view
        returns (uint256 buffer);

    function checkBadDebtLiquidation(
        uint256 _nftId
    )
        external;

    function checksLiquidation(
        uint256 _nftIdLiquidate,
        address _tokenToPayback,
        uint256 _shareAmountToPay
    )
        external
        view;

    function getPositionLendingAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getBorrowRate(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getPositionBorrowAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function overallUSDCollateralsBare(
        uint256 _nftId
    )
        external
        view
        returns (uint256 amount);

    function overallETHCollateralsBare(
        uint256 _nftId
    )
        external
        view
        returns (uint256 amount);

    function FEE_MANAGER()
        external
        view
        returns (address);

    function AAVE_HUB()
        external
        view
        returns (address);

    function curveSecurityCheck(
        address _poolAddress
    )
        external;

    function prepareCurvePools(
        address _poolToken,
        CurveSwapStructData calldata _curveSwapStructData,
        CurveSwapStructToken calldata _curveSwapStructToken
    )
        external;

    function overallETHBorrowBare(
        uint256 _nftId
    )
        external
        view
        returns (uint256 amount);

    function checksWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken
    )
        external
        view
        returns (bool);

    function checksBorrow(
        uint256 _nftId,
        address _caller,
        address _poolToken
    )
        external
        view
        returns (bool);

    function checksSolelyWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken
    )
        external
        view
        returns (bool);

    function checkOwnerPosition(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function checksCollateralizeDeposit(
        uint256 _nftIdCaller,
        address _caller,
        address _poolAddress
    )
        external
        view;

    function calculateWishPercentage(
        uint256 _nftId,
        address _receiveToken,
        uint256 _paybackETH,
        uint256 _maxFeeETH,
        uint256 _baseRewardLiquidation
    )
        external
        view
        returns (uint256);

    function checkUncollateralizedDeposit(
        uint256 _nftIdCaller,
        address _poolToken
    )
        external
        view;

    function checkPositionLocked(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function maxFeeETH()
        external
        view
        returns (uint256);

    function maxFeeFarmETH()
        external
        view
        returns (uint256);

    function baseRewardLiquidation()
        external
        view
        returns (uint256);

    function baseRewardLiquidationFarm()
        external
        view
        returns (uint256);

    function checksRegister(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function getLendingRate(
        address _poolToken
    )
        external
        view
        returns (uint256);
}




interface IPositionNFTs {

    function ownerOf(
        uint256 _nftId
    )
        external
        view
        returns (address);

    function totalSupply()
        external
        view
        returns (uint256);

    function reserved(
        address _owner
    )
        external
        view
        returns (uint256);

    function reservePosition()
        external;

    function mintPosition()
        external
        returns (uint256);

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        external
        view
        returns (uint256);

    function walletOfOwner(
        address _owner
    )
        external
        view
        returns (uint256[] memory);

    function mintPositionForUser(
        address _user
    )
        external
        returns (uint256);

    function reservePositionForUser(
        address _user
    )
        external
        returns (uint256);

    function getNextExpectedId()
        external
        view
        returns (uint256);

    function getApproved(
        uint256 _nftId
    )
        external
        view
        returns (address);

    function approve(
        address _to,
        uint256 _nftId
    )
        external;

    function isOwner(
        uint256 _nftId,
        address _caller
    )
        external
        view
        returns (bool);

    function FEE_MANAGER_NFT()
        external
        view
        returns (uint256);
}




interface IWiseOracleHub {

    function getTokensPriceFromUSD(
        address _tokenAddress,
        uint256 _usdValue
    )
        external
        view
        returns (uint256);

    function getTokensPriceInUSD(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        external
        view
        returns (uint256);

    function latestResolver(
        address _tokenAddress
    )
        external
        view
        returns (uint256);

    function getTokensFromUSD(
        address _tokenAddress,
        uint256 _usdValue
    )
        external
        view
        returns (uint256);

    function getTokensFromETH(
        address _tokenAddress,
        uint256 _ethValue
    )
        external
        view
        returns (uint256);

    function getTokensInUSD(
        address _tokenAddress,
        uint256 _amount
    )
        external
        view
        returns (uint256);

    function getTokensInETH(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        external
        view
        returns (uint256);

    function chainLinkIsDead(
        address _tokenAddress
    )
        external
        view
        returns (bool);

    function decimalsUSD()
        external
        pure
        returns (uint8);

    function addOracle(
        address _tokenAddress,
        address _priceFeedAddress,
        address[] calldata _underlyingFeedTokens
    )
        external;

    function recalibrate(
        address _tokenAddress
    )
        external;

    function WETH_ADDRESS()
        external
        view
        returns (address);

    function priceFeed(
        address _tokenAddress
    )
        external
        view
        returns (address);
}

interface IBalancerVault {

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient _recipient,
        IERC20[] memory _tokens,
        uint256[] memory _amounts,
        bytes memory _userData
    )
        external;
}

interface IFlashLoanRecipient {

    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _feeAmounts,
        bytes memory _userData
    )
        external;
}




interface ICurve {

    function add_liquidity(
        address _pool,
        uint256[4] memory _depositAmounts,
        uint256 _minOutAmount
    )
        external
        returns (uint256);

    function balanceOf(
        address _userAddress
    )
        external
        view
        returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    )
        external
        view
        returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    )
        external
        view
        returns (uint256);

    function exchange(
        int128 fromIndex,
        int128 toIndex,
        uint256 exactAmountFrom,
        uint256 minReceiveAmount
    )
        external
        returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    )
        external;

    function remove_liquidity(
        address _pool,
        uint256 _burnAmount,
        uint256[4] memory _coins
    )
        external;

    function remove_liquidity_one_coin(
        address _addy,
        uint256 _burnAmount,
        int128 _i,
        uint256 _minReceived
    )
        external;

    function coins(
        uint256 arg0
    )
        external
        view
        returns (address);

    function decimals()
        external
        view
        returns (uint8);

    function totalSupply()
        external
        view
        returns (uint256);

    function balances(
        uint256 arg0
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool);
}




interface IUniswapV3SwapCallback {

    function uniswapV3SwapCallback(
        int256 _amount0Delta,
        int256 _amount1Delta,
        bytes calldata _data
    )
        external;
}

interface IUniswapV3 is IUniswapV3SwapCallback {

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

    function exactInputSingle(
        ExactInputSingleParams calldata _params
    )
        external
        payable
        returns (uint256 amountOut);

    function exactOutputSingle(
        ExactOutputSingleParams calldata _params
    )
        external
        payable
        returns (uint256 amountIn);
}




interface IOraclePendle {
    function getOracleState(
        address market,
        uint32 duration
    )
        external
        view
        returns (
            bool increaseCardinalityRequired,
            uint16 cardinalityRequired,
            bool oldestObservationSatisfied
        );

    function getPtToAssetRate(
        address market,
        uint32 duration
    )
        external
        view
        returns (uint256 ptToAssetRate);

    function getPtToSyRate(
        address market,
        uint32 duration
    )
        external
        view
        returns (uint256 ptToSyRate);

}




interface IWETH is IERC20 {

    function deposit()
        external
        payable;

    function withdraw(
        uint256
    )
        external;
}




contract WrapperHelper {

    IWETH internal immutable WETH;

    constructor(
        address _wethAddress
    )
    {
        WETH = IWETH(
            _wethAddress
        );
    }

    /**
     * @dev Wrapper for wrapping
     * ETH call.
     */
    function _wrapETH(
        uint256 _value
    )
        internal
    {
        WETH.deposit{
            value: _value
        }();
    }

    /**
     * @dev Wrapper for unwrapping
     * ETH call.
     */
    function _unwrapETH(
        uint256 _value
    )
        internal
    {
        WETH.withdraw(
            _value
        );
    }
}




contract CallOptionalReturn {

    /**
     * @dev Helper function to do low-level call
     */
    function _callOptionalReturn(
        address token,
        bytes memory data
    )
        internal
        returns (bool call)
    {
        (
            bool success,
            bytes memory returndata
        ) = token.call(
            data
        );

        bool results = returndata.length == 0 || abi.decode(
            returndata,
            (bool)
        );

        if (success == false) {
            revert();
        }

        call = success
            && results
            && token.code.length > 0;
    }
}




contract TransferHelper is CallOptionalReturn {

    /**
     * @dev
     * Allows to execute safe transfer for a token
     */
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                _to,
                _value
            )
        );
    }

    /**
     * @dev
     * Allows to execute safe transferFrom for a token
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                _from,
                _to,
                _value
            )
        );
    }
}




contract ApprovalHelper is CallOptionalReturn {

    /**
     * @dev
     * Allows to execute safe approve for a token
     */
    function _safeApprove(
        address _token,
        address _spender,
        uint256 _value
    )
        internal
    {
        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                IERC20.approve.selector,
                _spender,
                _value
            )
        );
    }
}




error AmountTooSmall();
error SendValueFailed();

contract SendValueHelper {

    bool public sendingProgress;

    function _sendValue(
        address _recipient,
        uint256 _amount
    )
        internal
    {
        if (address(this).balance < _amount) {
            revert AmountTooSmall();
        }

        sendingProgress = true;

        (
            bool success
            ,
        ) = payable(_recipient).call{
            value: _amount
        }("");

        sendingProgress = false;

        if (success == false) {
            revert SendValueFailed();
        }
    }
}



















error GenericDeactivated();
error GenericAccessDenied();
error GenericInvalidParam();
error GenericTooMuchShares();
error GenericAmountTooSmall();
error GenericLevergeTooHigh();
error GenericDebtRatioTooLow();
error GenericNotBalancerVault();
error GenericDebtRatioTooHigh();

contract GenericDeclarations is
    WrapperHelper,
    TransferHelper,
    ApprovalHelper,
    SendValueHelper
{
    bool public isShutdown;
    bool public allowEnter;
    uint256 public collateralFactor;
    uint256 public minDepositEthAmount;

    uint256 internal constant MAX_PROPORTION = 96
        * PRECISION_FACTOR_E18
        / 100;

    address public immutable aaveTokenAddresses;
    address public immutable borrowTokenAddresses;

    address public FARM_ASSET;
    address public POOL_ASSET_AAVE;

    address public immutable ENTRY_ASSET;
    address public immutable PENDLE_CHILD;

    IAave public immutable AAVE;
    IAaveHub public immutable AAVE_HUB;
    IWiseLending public immutable WISE_LENDING;
    IWiseOracleHub public immutable ORACLE_HUB;
    IWiseSecurity public immutable WISE_SECURITY;
    IBalancerVault public immutable BALANCER_VAULT;
    IPositionNFTs public immutable POSITION_NFT;
    ICurve public immutable CURVE;
    IUniswapV3 public immutable UNISWAP_V3_ROUTER;

    IPendleSy public immutable PENDLE_SY;
    IPendleRouter public immutable PENDLE_ROUTER;
    IPendleMarket public immutable PENDLE_MARKET;
    IPendleRouterStatic public immutable PENDLE_ROUTER_STATIC;
    IOraclePendle public immutable PT_ORACLE_PENDLE;

    address internal immutable WETH_ADDRESS;
    address immutable AAVE_ADDRESS;
    address immutable AAVE_HUB_ADDRESS;
    address immutable AAVE_WETH_ADDRESS;

    address public collateralFactorRole;

    address internal constant PT_ORACLE_ADDRESS_MAINNET = 0x66a1096C6366b2529274dF4f5D8247827fe4CEA8;
    address internal constant PT_ORACLE_ADDRESS_ARBITRUM = 0x1Fd95db7B7C0067De8D45C0cb35D59796adfD187;

    bool public ethBack;
    bool public specialDepegCase;

    mapping(uint256 => bool) public isAave;

    event FarmEntry(
        uint256 indexed keyId,
        uint256 indexed wiseLendingNFT,
        uint256 indexed leverage,
        uint256 amount,
        uint256 timestamp
    );

    event FarmExit(
        uint256 indexed keyId,
        uint256 indexed wiseLendingNFT,
        uint256 amount,
        uint256 timestamp
    );

    event FarmStatus(
        bool indexed state,
        uint256 timestamp
    );

    event ManualPaybackShares(
        uint256 indexed keyId,
        uint256 indexed wiseLendingNFT,
        uint256 amount,
        uint256 timestamp
    );

    event ManualWithdrawShares(
        uint256 indexed keyId,
        uint256 indexed wiseLendingNFT,
        uint256 amount,
        uint256 timestamp
    );

    event MinDepositChange(
        uint256 minDepositEthAmount,
        uint256 timestamp
    );

    event ETHReceived(
        uint256 amount,
        address from
    );

    event RegistrationFarm(
        uint256 nftId,
        uint256 timestamp
    );

    uint256 internal constant ETH_CHAIN_ID = 1;
    uint256 internal constant ARB_CHAIN_ID = 42161;

    uint256 internal constant FIFTY_PERCENT = 50E16;
    uint256 internal constant PRECISION_FACTOR_E18 = 1E18;
    uint256 internal constant PRECISION_FACTOR_E16 = 1E16;

    uint256 internal constant MAX_AMOUNT = type(uint256).max;
    uint256 internal constant MAX_LEVERAGE = 15 * PRECISION_FACTOR_E18;

    uint24 public constant UNISWAP_V3_FEE = 100;
    address internal constant BALANCER_ADDRESS = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    constructor(
        address _wiseLendingAddress,
        address _pendleChildTokenAddress,
        address _pendleRouter,
        address _entryAsset,
        address _pendleSy,
        address _underlyingMarket,
        address _routerStatic,
        address _dexAddress,
        uint256 _collateralFactor
    )
        WrapperHelper(
            IWiseLending(_wiseLendingAddress).WETH_ADDRESS()
        )
    {
        PENDLE_ROUTER_STATIC = IPendleRouterStatic(
            _routerStatic
        );

        PENDLE_MARKET = IPendleMarket(
            _underlyingMarket
        );

        PENDLE_SY = IPendleSy(
            _pendleSy
        );

        PENDLE_ROUTER = IPendleRouter(
            _pendleRouter
        );

        CURVE = ICurve(
            _dexAddress
        );

        UNISWAP_V3_ROUTER = IUniswapV3(
            _dexAddress
        );

        ENTRY_ASSET = _entryAsset;
        PENDLE_CHILD = _pendleChildTokenAddress;

        WISE_LENDING = IWiseLending(
            _wiseLendingAddress
        );

        ORACLE_HUB = IWiseOracleHub(
            WISE_LENDING.WISE_ORACLE()
        );

        BALANCER_VAULT = IBalancerVault(
            BALANCER_ADDRESS
        );

        WISE_SECURITY = IWiseSecurity(
            WISE_LENDING.WISE_SECURITY()
        );

        WETH_ADDRESS = WISE_LENDING.WETH_ADDRESS();

        AAVE_HUB = IAaveHub(
            WISE_SECURITY.AAVE_HUB()
        );

        AAVE_ADDRESS = AAVE_HUB.AAVE_ADDRESS();

        AAVE = IAave(
            AAVE_ADDRESS
        );

        AAVE_HUB_ADDRESS = address(
            AAVE_HUB
        );

        POSITION_NFT = IPositionNFTs(
            WISE_LENDING.POSITION_NFT()
        );

        collateralFactor = _collateralFactor;
        borrowTokenAddresses = AAVE_HUB.WETH_ADDRESS();

        aaveTokenAddresses = AAVE_HUB.aaveTokenAddress(
            borrowTokenAddresses
        );

        AAVE_WETH_ADDRESS = aaveTokenAddresses;

        if (block.chainid == ETH_CHAIN_ID) {
            minDepositEthAmount = 3 ether;
        } else {
            minDepositEthAmount = 0.03 ether;
        }

        address PT_ORACLE_ADDRESS = block.chainid == 1
            ? PT_ORACLE_ADDRESS_MAINNET
            : PT_ORACLE_ADDRESS_ARBITRUM;

        PT_ORACLE_PENDLE = IOraclePendle(
            PT_ORACLE_ADDRESS
        );
    }

    function doApprovals()
        external
        virtual
    {
        _doApprovals(
            address(WISE_LENDING)
        );
    }

    function _doApprovals(
        address _wiseLendingAddress
    )
        internal
        virtual
    {}

    modifier isActive()
    {
        _isActive();
        _;
    }

    function _isActive()
        internal
        virtual
        view
    {
        if (isShutdown == true) {
            revert GenericDeactivated();
        }
    }

    modifier onlyCollateralFactorRole() {
        _onlyCollateralFactorRole();
        _;
    }

    function _onlyCollateralFactorRole()
        internal
        virtual
    {
        if (msg.sender != collateralFactorRole) {
            revert GenericAccessDenied();
        }
    }
}




abstract contract GenericMathLogic is GenericDeclarations {

    modifier updatePools() {
        _checkReentrancy();
        _updatePools();
        _;
    }

    /**
     * @dev Update logic for pools via wise lending
     * interfaces
     */
    function _updatePools()
        internal
        virtual
    {
        WISE_LENDING.syncManually(
            FARM_ASSET
        );

        WISE_LENDING.syncManually(
            POOL_ASSET_AAVE
        );

        WISE_LENDING.syncManually(
            PENDLE_CHILD
        );
    }

    function _checkReentrancy()
        internal
        virtual
        view
    {
        if (sendingProgress == true) {
            revert GenericAccessDenied();
        }

        if (WISE_LENDING.sendingProgress() == true) {
            revert GenericAccessDenied();
        }

        if (AAVE_HUB.sendingProgressAaveHub() == true) {
            revert GenericAccessDenied();
        }
    }

    /**
     * @dev Internal function getting the
     * borrow shares from position {_nftId}
     * with token {_borrowToken}
     */
    function _getPositionBorrowShares(
        uint256 _nftId
    )
        internal
        virtual
        view
        returns (uint256)
    {
        return WISE_LENDING.getPositionBorrowShares(
            _nftId,
            FARM_ASSET
        );
    }

    /**
     * @dev Internal function getting the
     * borrow shares of aave from position {_nftId}
     * with token {_borrowToken}
     */
    function _getPositionBorrowSharesAave(
        uint256 _nftId
    )
        internal
        virtual
        view
        returns (uint256)
    {
        return WISE_LENDING.getPositionBorrowShares(
            _nftId,
            POOL_ASSET_AAVE
        );
    }

    /**
     * @dev Internal function converting
     * borrow shares into tokens.
     */
    function _getPositionBorrowTokenAmount(
        uint256 _nftId
    )
        internal
        virtual
        view
        returns (uint256 tokenAmount)
    {
        uint256 positionBorrowShares = _getPositionBorrowShares(
            _nftId
        );

        if (positionBorrowShares > 0) {
            tokenAmount = WISE_LENDING.paybackAmount(
                FARM_ASSET,
                positionBorrowShares
            );
        }
    }

    function _getPositionBorrowTokenAmountAave(
        uint256 _nftId
    )
        internal
        virtual
        view
        returns (uint256 tokenAmountAave)
    {
        uint256 positionBorrowSharesAave = _getPositionBorrowSharesAave(
            _nftId
        );

        if (positionBorrowSharesAave == 0) {
            return 0;
        }

        tokenAmountAave = WISE_LENDING.paybackAmount(
            POOL_ASSET_AAVE,
            positionBorrowSharesAave
        );
    }
    /**
     * @dev Internal function getting the
     * lending shares from position {_nftId}
     * with token {_borrowToken}
     */
    function _getPositionLendingShares(
        uint256 _nftId
    )
        internal
        virtual
        view
        returns (uint256)
    {
        return WISE_LENDING.getPositionLendingShares(
            _nftId,
            PENDLE_CHILD
        );
    }

    /**
     * @dev Internal function converting
     * lending shares into tokens.
     */
    function _getPostionCollateralTokenAmount(
        uint256 _nftId
    )
        internal
        virtual
        view
        returns (uint256)
    {
        return WISE_LENDING.cashoutAmount(
            {
                _poolToken: PENDLE_CHILD,
                _shares: _getPositionLendingShares(
                    _nftId
                )
            }
        );
    }

    /**
     * @dev Read function returning the total
     * borrow amount in ETH from postion {_nftId}
     */
    function getPositionBorrowETH(
        uint256 _nftId
    )
        public
        virtual
        view
        returns (uint256)
    {
        uint256 borrowTokenAmount;
        uint256 borrowShares = _getPositionBorrowShares(
            _nftId
        );

        if (borrowShares > 0) {
            borrowTokenAmount = _getPositionBorrowTokenAmount(
                _nftId
            );
        }

        uint256 borrowSharesAave = _getPositionBorrowSharesAave(
            _nftId
        );

        uint256 borrowTokenAmountAave;

        if (borrowSharesAave > 0) {
            borrowTokenAmountAave = _getPositionBorrowTokenAmountAave(
                _nftId
            );
        }

        uint256 tokenValueEth;

        if (borrowShares > 0) {
            tokenValueEth = _getTokensInETH(
                FARM_ASSET,
                borrowTokenAmount
            );
        }

        if (borrowTokenAmountAave == 0) {
            return tokenValueEth;
        }

        uint256 tokenValueAaveEth = _getTokensInETH(
            POOL_ASSET_AAVE,
            borrowTokenAmountAave
        );

        return tokenValueEth + tokenValueAaveEth;
    }

    /**
     * @dev Read function returning the total
     * lending amount in ETH from postion {_nftId}
     */
    function getTotalWeightedCollateralETH(
        uint256 _nftId
    )
        public
        virtual
        view
        returns (uint256)
    {
        return _getTokensInETH(
            PENDLE_CHILD,
            _getPostionCollateralTokenAmount(_nftId)
        )
            * collateralFactor
            / PRECISION_FACTOR_E18;
    }

    function _getTokensInETH(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        internal
        virtual
        view
        returns (uint256)
    {
        return ORACLE_HUB.getTokensInETH(
            _tokenAddress,
            _tokenAmount
        );
    }

    function _getEthInTokens(
        address _tokenAddress,
        uint256 _ethAmount
    )
        internal
        virtual
        view
        returns (uint256)
    {
        return ORACLE_HUB.getTokensFromETH(
            _tokenAddress,
            _ethAmount
        );
    }

    function getLeverageAmount(
        uint256 _initialAmount,
        uint256 _leverage
    )
        public
        pure
        virtual
        returns (uint256)
    {
        return _initialAmount
            * _leverage
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev Internal function with math logic for approximating
     * the net APY for the postion aftrer creation.
     */
    function _getApproxNetAPY(
        uint256 _initialAmount,
        uint256 _leverage,
        uint256 _wstETHAPY
    )
        internal
        virtual
        view
        returns (
            uint256,
            bool
        )
    {
        if (_leverage < PRECISION_FACTOR_E18) {
            return (
                0,
                false
            );
        }

        uint256 leveragedAmount = getLeverageAmount(
            _initialAmount,
            _leverage
        );

        uint256 flashloanAmount = leveragedAmount
            - _initialAmount;

        uint256 newBorrowRate = _getNewBorrowRate(
            flashloanAmount
        );

        uint256 leveragedPositivAPY = _wstETHAPY
            * _leverage
            / PRECISION_FACTOR_E18;

        uint256 leveragedNegativeAPY = newBorrowRate
            * (_leverage - PRECISION_FACTOR_E18)
            / PRECISION_FACTOR_E18;

        bool isPositive = leveragedPositivAPY >= leveragedNegativeAPY;

        uint256 netAPY = isPositive == true
            ? leveragedPositivAPY - leveragedNegativeAPY
            : leveragedNegativeAPY - leveragedPositivAPY;

        return (
            netAPY,
            isPositive
        );
    }

    function _isOutOfRangeAmount(
        uint256 _lpWithdrawAmount
    )
        internal
        virtual
        view
        returns (bool)
    {
        MarketState memory marketState = PENDLE_MARKET.readState(
            address(PENDLE_MARKET)
        );

        (
            ,
            uint256 userSy,
            uint256 userPt
        )
            = _getUserAssetInfo(
                _lpWithdrawAmount,
                uint256(marketState.totalLp),
                uint256(marketState.totalSy),
                uint256(marketState.totalPt)
        );

        uint256 reducedSy = uint256(marketState.totalSy)
            - userSy
            - (
                PT_ORACLE_PENDLE.getPtToSyRate(
                    address(PENDLE_MARKET),
                    1 seconds
                )
                * userPt
                / PRECISION_FACTOR_E18
        );

        uint256 totalAssetsReduced = (
            PENDLE_SY.exchangeRate()
                * reducedSy
                / PRECISION_FACTOR_E18
            + uint256(marketState.totalPt)
        );

        return uint256(marketState.totalPt)
            * PRECISION_FACTOR_E18
            / totalAssetsReduced
            > MAX_PROPORTION;
    }

    /**
     * @dev Internal function with math logic for detecting
     * if market is out of range.
     */
    function _isOutOfRange(
        uint256 _nftId
    )
        internal
        virtual
        view
        returns (bool)
    {
        return _isOutOfRangeAmount(
            IPendleChild(PENDLE_CHILD).previewAmountWithdrawShares(
                WISE_LENDING.cashoutAmount(
                    PENDLE_CHILD,
                    WISE_LENDING.getPositionLendingShares(
                        _nftId,
                        PENDLE_CHILD
                    )
                ),
                IPendleChild(PENDLE_CHILD).underlyingLpAssetsCurrent()
            )
        );
    }

    function _getUserAssetInfo(
        uint256 _lpToWithdraw,
        uint256 _totalLp,
        uint256 _totalSy,
        uint256 _totalPt
    )
        internal
        virtual
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 userProportion = _lpToWithdraw
            * PRECISION_FACTOR_E18
            / _totalLp;

        return (
            userProportion,
            userProportion
                * _totalSy
                / PRECISION_FACTOR_E18,
            userProportion
                * _totalPt
                / PRECISION_FACTOR_E18
        );
    }

    /**
     * @dev Internal function with math logic for approximating
     * the new borrow APY.
     */
    function _getNewBorrowRate(
        uint256 _borrowAmount
    )
        internal
        virtual
        view
        returns (uint256)
    {
        uint256 totalPool = WISE_LENDING.getTotalPool(
            ENTRY_ASSET
        );

        uint256 pseudoPool = WISE_LENDING.getPseudoTotalPool(
            ENTRY_ASSET
        );

        if (totalPool > pseudoPool) {
            return 0;
        }

        uint256 newUtilization = PRECISION_FACTOR_E18 - (PRECISION_FACTOR_E18
            * (totalPool - _borrowAmount)
            / pseudoPool
        );

        uint256 pole = WISE_LENDING.borrowRatesData(
            ENTRY_ASSET
        ).pole;

        uint256 mulFactor = WISE_LENDING.borrowRatesData(
            ENTRY_ASSET
        ).multiplicativeFactor;

        uint256 baseDivider = pole
            * (pole - newUtilization);

        return mulFactor
            * PRECISION_FACTOR_E18
            * newUtilization
            / baseDivider;
    }

    /**
     * @dev Internal function checking if a position
     * with {_nftId} has a debt ratio under 100%.
     */
    function _checkDebtRatio(
        uint256 _nftId
    )
        internal
        virtual
        view
        returns (bool)
    {
        uint256 borrowShares = isAave[_nftId]
            ? _getPositionBorrowSharesAave(
                _nftId
            )
            : _getPositionBorrowShares(
                _nftId
            );

        if (borrowShares == 0) {
            return true;
        }

        return getTotalWeightedCollateralETH(_nftId)
            >= getPositionBorrowETH(_nftId);
    }

    /**
     * @dev Internal function checking if the leveraged
     * amount not below {minDepositEthAmount} in value.
     */
    function _notBelowMinDepositAmount(
        uint256 _amount
    )
        internal
        virtual
        view
        returns (bool)
    {
        uint256 equivETH = _getTokensInETH(
            ENTRY_ASSET,
            _amount
        );

        return equivETH >= minDepositEthAmount;
    }
}




abstract contract GenericLeverageLogic is
    GenericMathLogic,
    IFlashLoanRecipient
{
    /**
     * @dev Wrapper function preparing balancer flashloan and
     * loading data to pass into receiver.
     */
    function _executeBalancerFlashLoan(
        uint256 _nftId,
        uint256 _flashAmount,
        uint256 _initialAmount,
        uint256 _lendingShares,
        uint256 _borrowShares,
        uint256 _allowedSpread,
        bool _ethBack,
        bool _isAave
    )
        internal
        virtual
    {
        IERC20[] memory tokens = new IERC20[](1);
        uint256[] memory amount = new uint256[](1);

        address flashAsset = FARM_ASSET;

        tokens[0] = IERC20(flashAsset);
        amount[0] = _flashAmount;

        allowEnter = true;

        BALANCER_VAULT.flashLoan(
            this,
            tokens,
            amount,
            abi.encode(
                _nftId,
                _initialAmount,
                _lendingShares,
                _borrowShares,
                _allowedSpread,
                msg.sender,
                _ethBack,
                _isAave
            )
        );
    }

    /**
     * @dev Receive function from balancer flashloan. Body
     * is called from balancer at the end of their {flashLoan()}
     * logic. Overwritten with opening flows.
     */
    function receiveFlashLoan(
        IERC20[] memory _flashloanToken,
        uint256[] memory _flashloanAmounts,
        uint256[] memory _feeAmounts,
        bytes memory _userData
    )
        external
        virtual
    {
        if (allowEnter == false) {
            revert GenericAccessDenied();
        }

        allowEnter = false;

        if (_flashloanToken.length == 0) {
            revert GenericInvalidParam();
        }

        if (msg.sender != BALANCER_ADDRESS) {
            revert GenericNotBalancerVault();
        }

        uint256 totalDebtBalancer = _flashloanAmounts[0]
            + _feeAmounts[0];

        (
            uint256 nftId,
            uint256 initialAmount,
            uint256 lendingShares,
            uint256 borrowShares,
            uint256 allowedSpread,
            address caller,
            bool ethBack,
            bool isAave
        ) = abi.decode(
            _userData,
            (
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                address,
                bool,
                bool
            )
        );

        if (initialAmount > 0) {
            _logicOpenPosition(
                isAave,
                nftId,
                _flashloanAmounts[0] + initialAmount,
                totalDebtBalancer,
                allowedSpread
            );

            return;
        }

        _logicClosePosition(
            nftId,
            borrowShares,
            lendingShares,
            totalDebtBalancer,
            allowedSpread,
            caller,
            ethBack,
            isAave
        );
    }

    function _logicClosePosition(
        uint256 _nftId,
        uint256 _borrowShares,
        uint256 _lendingShares,
        uint256 _totalDebtBalancer,
        uint256 _allowedSpread,
        address _caller,
        bool _ethBack,
        bool _isAave
    )
        internal
        virtual
    {}

    function _getEthBack(
        uint256 _swapAmount,
        uint256 _minOutAmount
    )
        internal
        virtual
        returns (uint256)
    {
        uint256 wethAmount = _getTokensUniV3(
            _swapAmount,
            _minOutAmount,
            ENTRY_ASSET,
            FARM_ASSET
        );

        _unwrapETH(
            wethAmount
        );

        return wethAmount;
    }

    function _getTokensUniV3(
        uint256 _amountIn,
        uint256 _minOutAmount,
        address _tokenIn,
        address _tokenOut
    )
        internal
        virtual
        returns (uint256)
    {
        return UNISWAP_V3_ROUTER.exactInputSingle(
            IUniswapV3.ExactInputSingleParams(
                {
                    tokenIn: _tokenIn,
                    tokenOut: _tokenOut,
                    fee: UNISWAP_V3_FEE,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: _amountIn,
                    amountOutMinimum: _minOutAmount,
                    sqrtPriceLimitX96: 0
                }
            )
        );
    }

    function _swapStETHintoETH(
        uint256 _swapAmount,
        uint256 _minOutAmount
    )
        internal
        virtual
        returns (uint256)
    {}

    function _withdrawPendleLPs(
        uint256 _nftId,
        uint256 _lendingShares
    )
        internal
        virtual
        returns (uint256 withdrawnLpsAmount)
    {
        return IPendleChild(PENDLE_CHILD).withdrawExactShares(
            WISE_LENDING.withdrawExactShares(
                _nftId,
                PENDLE_CHILD,
                _lendingShares
            )
        );
    }

    function _paybackExactShares(
        bool _isAave,
        uint256 _nftId,
        uint256 _borrowShares
    )
        internal
        virtual
    {
        if (_isAave == true) {
            AAVE_HUB.paybackExactShares(
                _nftId,
                FARM_ASSET,
                _borrowShares
            );

            return;
        }

        WISE_LENDING.paybackExactShares(
            _nftId,
            FARM_ASSET,
            _borrowShares
        );
    }

    /**
     * @dev Internal wrapper function for a closing route
     * which returns {ENTRY_ASSET} to the owner in the end.
     */
    function _closingRouteToken(
        uint256 _tokenAmount,
        uint256 _totalDebtBalancer,
        address _caller
    )
        internal
        virtual
    {
        if (FARM_ASSET == WETH_ADDRESS) {
            _wrapETH(
                _tokenAmount
            );
        }

        _safeTransfer(
            FARM_ASSET,
            msg.sender,
            _totalDebtBalancer
        );

        _safeTransfer(
            FARM_ASSET,
            _caller,
            _tokenAmount - _totalDebtBalancer
        );
    }

    /**
     * @dev Internal wrapper function for a closing route
     * which returns ETH to the owner in the end.
     */
    function _closingRouteETH(
        uint256 _ethAmount,
        uint256 _totalDebtBalancer,
        address _caller
    )
        internal
        virtual
    {
        _wrapETH(
            _totalDebtBalancer
        );

        _safeTransfer(
            FARM_ASSET,
            msg.sender,
            _totalDebtBalancer
        );

        _sendValue(
            _caller,
            _ethAmount - _totalDebtBalancer
        );
    }

    function _logicOpenPosition(
        bool _isAave,
        uint256 _nftId,
        uint256 _depositAmount,
        uint256 _totalDebtBalancer,
        uint256 _allowedSpread
    )
        internal
        virtual
    {}

    function _borrowExactAmount(
        bool _isAave,
        uint256 _nftId,
        uint256 _totalDebtBalancer
    )
        internal
        virtual
    {
        if (_isAave == true) {
            AAVE_HUB.borrowExactAmount(
                _nftId,
                FARM_ASSET,
                _totalDebtBalancer
            );

            return;
        }

        WISE_LENDING.borrowExactAmount(
            _nftId,
            FARM_ASSET,
            _totalDebtBalancer
        );
    }

    /**
     * @dev Internal function summarizing liquidation
     * checks and interface call for core liquidation
     * from wise lending.
     */
    function _coreLiquidation(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        uint256 _shareAmountToPay
    )
        internal
        virtual
        returns (
            uint256 paybackAmount,
            uint256 receivingAmount
        )
    {
        _checkLiquidatability(
            _nftId
        );

        address paybackToken = isAave[_nftId] == true
            ? POOL_ASSET_AAVE
            : FARM_ASSET;

        paybackAmount = WISE_LENDING.paybackAmount(
            paybackToken,
            _shareAmountToPay
        );

        uint256 cutoffShares = isAave[_nftId] == true
            ? _getPositionBorrowSharesAave(_nftId)
                * FIFTY_PERCENT
                / PRECISION_FACTOR_E18
            : _getPositionBorrowShares(_nftId)
                * FIFTY_PERCENT
                / PRECISION_FACTOR_E18;

        if (_shareAmountToPay > cutoffShares) {
            revert GenericTooMuchShares();
        }

        receivingAmount = WISE_LENDING.coreLiquidationIsolationPools(
            _nftId,
            _nftIdLiquidator,
            msg.sender,
            paybackToken,
            PENDLE_CHILD,
            paybackAmount,
            _shareAmountToPay
        );
    }

    function _checkLiquidatability(
        uint256 _nftId
    )
        internal
        virtual
        view
    {
        if (specialDepegCase == true) {
            return;
        }

        if (_checkDebtRatio(_nftId) == true) {
            revert GenericDebtRatioTooLow();
        }
    }
}




abstract contract GenericPowerFarm is GenericLeverageLogic {

    /**
     * @dev External view function approximating the
     * new resulting net APY for a position setup.
     *
     * Note: Not 100% accurate because no syncPool is performed.
     */
    function getApproxNetAPY(
        uint256 _initialAmount,
        uint256 _leverage,
        uint256 _pendleChildApy
    )
        external
        virtual
        view
        returns (
            uint256,
            bool
        )
    {
        return _getApproxNetAPY(
            _initialAmount,
            _leverage,
            _pendleChildApy
        );
    }

    /**
     * @dev External view function approximating the
     * new borrow amount for the pool when {_borrowAmount}
     * is borrowed.
     *
     * Note: Not 100% accurate because no syncPool is performed.
     */
    function getNewBorrowRate(
        uint256 _borrowAmount
    )
        external
        virtual
        view
        returns (uint256)
    {
        return _getNewBorrowRate(
            _borrowAmount
        );
    }

    function isOutOfRange(
        uint256 _nftId
    )
        external
        virtual
        view
        returns (bool)
    {
        return _isOutOfRange(
            _nftId
        );
    }

    function isOutOfRangeAmount(
        uint256 _lpAmount
    )
        external
        virtual
        view
        returns (bool)
    {
        return _isOutOfRangeAmount(
            _lpAmount
        );
    }

    /**
     * @dev View functions returning the current
     * debt ratio of the postion with {_nftId}
     */
    function getLiveDebtRatio(
        uint256 _nftId
    )
        external
        virtual
        view
        returns (uint256)
    {
        uint256 borrowShares = isAave[_nftId]
            ? _getPositionBorrowSharesAave(
                _nftId
            )
            : _getPositionBorrowShares(
                _nftId
            );

        if (borrowShares == 0) {
            return 0;
        }

        uint256 totalCollateral = getTotalWeightedCollateralETH(
            _nftId
        );

        if (totalCollateral == 0) {
            return 0;
        }

        return getPositionBorrowETH(_nftId)
            * PRECISION_FACTOR_E18
            / totalCollateral;
    }

    function setCollateralFactor(
        uint256 _newCollateralFactor
    )
        external
        virtual
    {}

    /**
     * @dev Liquidation function for open power farm
     * postions which have a debtratio greater than 100%.
     */
    function liquidatePartiallyFromToken(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        uint256 _shareAmountToPay
    )
        external
        virtual
        updatePools
        returns (
            uint256 paybackAmount,
            uint256 receivingAmount
        )
    {
        return _coreLiquidation(
            _nftId,
            _nftIdLiquidator,
            _shareAmountToPay
        );
    }

    /**
     * @dev Manually payback function for users. Takes
     * {_paybackShares} which can be converted
     * into token with {paybackAmount()} or vice verse
     * with {calculateBorrowShares()} from wise lending
     * contract.
     */
    function _manuallyPaybackShares(
        uint256 _nftId,
        uint256 _paybackShares
    )
        internal
        virtual
    {
        address poolAddress = FARM_ASSET;

        if (isAave[_nftId] == true) {
            poolAddress = POOL_ASSET_AAVE;
        }

        uint256 paybackAmount = WISE_LENDING.paybackAmount(
            poolAddress,
            _paybackShares
        );

        _safeTransferFrom(
            poolAddress,
            msg.sender,
            address(this),
            paybackAmount
        );

        WISE_LENDING.paybackExactShares(
            _nftId,
            poolAddress,
            _paybackShares
        );
    }

    /**
     * @dev Manually withdraw function for users. Takes
     * {_withdrawShares} which can be converted
     * into token with {cashoutAmount()} or vice verse
     * with {calculateLendingShares()} from wise lending
     * contract.
     */
    function _manuallyWithdrawShares(
        uint256 _nftId,
        uint256 _withdrawShares
    )
        internal
        virtual
    {
        uint256 withdrawAmount = WISE_LENDING.cashoutAmount(
            PENDLE_CHILD,
            _withdrawShares
        );

        withdrawAmount = WISE_LENDING.withdrawExactShares(
            _nftId,
            PENDLE_CHILD,
            _withdrawShares
        );

        _safeTransfer(
            PENDLE_CHILD,
            msg.sender,
            withdrawAmount
        );
    }

    /**
     * @dev Internal function combining the core
     * logic for {openPosition()}.
     */
    function _openPosition(
        bool _isAave,
        uint256 _nftId,
        uint256 _initialAmount,
        uint256 _leverage,
        uint256 _allowedSpread
    )
        internal
        virtual
    {
        if (_leverage > MAX_LEVERAGE) {
            revert GenericLevergeTooHigh();
        }

        uint256 leveragedAmount = getLeverageAmount(
            _initialAmount,
            _leverage
        );

        if (_notBelowMinDepositAmount(leveragedAmount) == false) {
            revert GenericAmountTooSmall();
        }

        _executeBalancerFlashLoan(
            {
                _nftId: _nftId,
                _flashAmount: leveragedAmount - _initialAmount,
                _initialAmount: _initialAmount,
                _lendingShares: 0,
                _borrowShares: 0,
                _allowedSpread: _allowedSpread,
                _ethBack: ethBack,
                _isAave: _isAave
            }
        );
    }

    /**
     * @dev Internal function combining the core
     * logic for {closingPosition()}.
     *
     * Note: {_allowedSpread} passed through UI by asking user
     * the percentage of acceptable value loss by closing position.
     * Units are in ether where 100% = 1 ether -> 0% loss acceptable
     * 1.01 ether -> 1% loss acceptable and so on.
     */
    function _closingPosition(
        bool _isAave,
        uint256 _nftId,
        uint256 _allowedSpread,
        bool _ethBack
    )
        internal
        virtual
    {
        uint256 borrowShares = _isAave == false
            ? _getPositionBorrowShares(
                _nftId
            )
            : _getPositionBorrowSharesAave(
                _nftId
            );

        uint256 borrowTokenAmount = _isAave == false
            ? _getPositionBorrowTokenAmount(
                _nftId
            )
            : _getPositionBorrowTokenAmountAave(
                _nftId
            );

        _executeBalancerFlashLoan(
            {
                _nftId: _nftId,
                _flashAmount: borrowTokenAmount,
                _initialAmount: 0,
                _lendingShares: _getPositionLendingShares(
                    _nftId
                ),
                _borrowShares: borrowShares,
                _allowedSpread: _allowedSpread,
                _ethBack: _ethBack,
                _isAave: _isAave
            }
        );
    }

    function _registrationFarm(
        uint256 _nftId
    )
        internal
        virtual
    {
        WISE_LENDING.setRegistrationIsolationPool(
            _nftId,
            true
        );


        emit RegistrationFarm(
            _nftId,
            block.timestamp
        );
    }
}




interface IPowerFarmsNFTs {

    function ownerOf(
        uint256 _tokenId
    )
        external
        view
        returns (address);

    function mintKey(
        address _keyOwner,
        uint256 _keyId
    )
        external;

    /**
     * @dev Burns farming NFT
     */
    function burnKey(
        uint256 _keyId
    )
        external;
}




error InvalidKey();
error AlreadyReserved();

contract MinterReserver {

    IPowerFarmsNFTs immutable FARMS_NFTS;

    // Tracks increment of keys
    uint256 public totalMinted;

    // Tracks reserved counter
    uint256 public totalReserved;

    // Tracks amount of reusable NFTs
    uint256 public availableNFTCount;

    // Maps access to wiseLendingNFT through farmNFT
    mapping(uint256 => uint256) public farmingKeys;

    // Tracks reserved NFTs mapped to address
    mapping(address => uint256) public reservedKeys;

    // Tracks reusable wiseLendingNFTs after burn
    mapping(uint256 => uint256) public availableNFTs;

    modifier onlyKeyOwner(
        uint256 _keyId
    ) {
        _onlyKeyOwner(
            _keyId
        );
        _;
    }

    function _onlyKeyOwner(
        uint256 _keyId
    )
        private
        view
    {
        require(
            isOwner(
                _keyId,
                msg.sender
            ) == true
        );
    }

    constructor(
        address _powerFarmNFTs
    ) {
        FARMS_NFTS = IPowerFarmsNFTs(
            _powerFarmNFTs
        );
    }

    function _incrementReserved()
        internal
        returns (uint256)
    {
        return ++totalReserved;
    }

    function _getNextReserveKey()
        internal
        returns (uint256)
    {
        return totalMinted + _incrementReserved();
    }

    function _reserveKey(
        address _userAddress,
        uint256 _wiseLendingNFT
    )
        internal
        returns (uint256)
    {
        if (reservedKeys[_userAddress] > 0) {
            revert AlreadyReserved();
        }

        uint256 keyId = _getNextReserveKey();

        reservedKeys[_userAddress] = keyId;
        farmingKeys[keyId] = _wiseLendingNFT;

        return keyId;
    }

    function isOwner(
        uint256 _keyId,
        address _owner
    )
        public
        view
        returns (bool)
    {
        if (reservedKeys[_owner] == _keyId) {
            return true;
        }

        if (FARMS_NFTS.ownerOf(_keyId) == _owner) {
            return true;
        }

        return false;
    }

    function _mintKeyForUser(
        uint256 _keyId,
        address _userAddress
    )
        internal
        returns (uint256)
    {
        if (_keyId == 0) {
            revert InvalidKey();
        }

        delete reservedKeys[
            _userAddress
        ];

        FARMS_NFTS.mintKey(
            _userAddress,
            _keyId
        );

        totalMinted++;
        totalReserved--;

        return _keyId;
    }

    function mintReserved()
        external
        returns (uint256)
    {
        return _mintKeyForUser(
            reservedKeys[
                msg.sender
            ],
            msg.sender
        );
    }

    event ERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes _data
    );

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        returns (bytes4)
    {
        emit ERC721Received(
            _operator,
            _from,
            _tokenId,
            _data
        );

        return this.onERC721Received.selector;
    }
}

contract GenericPowerManager is
    OwnableMaster,
    GenericPowerFarm,
    MinterReserver
{
    receive()
        external
        payable
        virtual
    {
        emit ETHReceived(
            msg.value,
            msg.sender
        );
    }

    constructor(
        address _wiseLendingAddress,
        address _pendleChildTokenAddress,
        address _pendleRouter,
        address _entryAsset,
        address _pendleSy,
        address _underlyingMarket,
        address _routerStatic,
        address _dexAddress,
        uint256 _collateralFactor,
        address _powerFarmNFTs
    )
        OwnableMaster(msg.sender)
        MinterReserver(_powerFarmNFTs)
        GenericDeclarations(
            _wiseLendingAddress,
            _pendleChildTokenAddress,
            _pendleRouter,
            _entryAsset,
            _pendleSy,
            _underlyingMarket,
            _routerStatic,
            _dexAddress,
            _collateralFactor
        )
    {}

    function setSpecialDepegCase(
        bool _state
    )
        external
        virtual
        onlyMaster
    {
        specialDepegCase = _state;
    }

    function revokeCollateralFactorRole()
        public
        virtual
        onlyCollateralFactorRole
    {
        collateralFactorRole = ZERO_ADDRESS;
    }

    function setCollateralFactor(
        uint256 _newCollateralFactor
    )
        external
        override
        onlyCollateralFactorRole()
    {
        collateralFactor = _newCollateralFactor;
    }

    function changeMinDeposit(
        uint256 _newMinDeposit
    )
        external
        virtual
        onlyMaster
    {
        minDepositEthAmount = _newMinDeposit;

        emit MinDepositChange(
            _newMinDeposit,
            block.timestamp
        );
    }

    /**
     * @dev External function deactivating the power farm by
     * disableing the openPosition function. Allowing user
     * to manualy payback and withdraw.
     */
    function shutDownFarm(
        bool _state
    )
        external
        virtual
        onlyMaster
    {
        isShutdown = _state;

        emit FarmStatus(
            _state,
            block.timestamp
        );
    }

    function enterFarm(
        bool _isAave,
        uint256 _amount,
        uint256 _leverage,
        uint256 _allowedSpread
    )
        external
        virtual
        isActive
        updatePools
        returns (uint256)
    {
        uint256 wiseLendingNFT = _getWiseLendingNFT();

        _safeTransferFrom(
            FARM_ASSET,
            msg.sender,
            address(this),
            _amount
        );

        _openPosition(
            _isAave,
            wiseLendingNFT,
            _amount,
            _leverage,
            _allowedSpread
        );

        uint256 keyId = _reserveKey(
            msg.sender,
            wiseLendingNFT
        );

        isAave[keyId] = _isAave;

        emit FarmEntry(
            keyId,
            wiseLendingNFT,
            _leverage,
            _amount,
            block.timestamp
        );

        return keyId;
    }

    function enterFarmETH(
        bool _isAave,
        uint256 _leverage,
        uint256 _allowedSpread
    )
        external
        virtual
        payable
        isActive
        updatePools
        returns (uint256)
    {
        uint256 wiseLendingNFT = _getWiseLendingNFT();

        _wrapETH(
            msg.value
        );

        _openPosition(
            _isAave,
            wiseLendingNFT,
            msg.value,
            _leverage,
            _allowedSpread
        );

        uint256 keyId = _reserveKey(
            msg.sender,
            wiseLendingNFT
        );

        isAave[keyId] = _isAave;

        emit FarmEntry(
            keyId,
            wiseLendingNFT,
            _leverage,
            msg.value,
            block.timestamp
        );

        return keyId;
    }

    function _getWiseLendingNFT()
        internal
        virtual
        returns (uint256)
    {
        if (availableNFTCount == 0) {

            uint256 nftId = POSITION_NFT.mintPosition();

            _registrationFarm(
                nftId
            );

            POSITION_NFT.approve(
                AAVE_HUB_ADDRESS,
                nftId
            );

            return nftId;
        }

        return availableNFTs[
            availableNFTCount--
        ];
    }

    function exitFarm(
        uint256 _keyId,
        uint256 _allowedSpread,
        bool _ethBack
    )
        external
        virtual
        updatePools
        onlyKeyOwner(_keyId)
    {
        uint256 wiseLendingNFT = farmingKeys[
            _keyId
        ];

        delete farmingKeys[
            _keyId
        ];

        if (reservedKeys[msg.sender] == _keyId) {
            reservedKeys[msg.sender] = 0;
        } else {
            FARMS_NFTS.burnKey(
                _keyId
            );
        }

        availableNFTs[
            ++availableNFTCount
        ] = wiseLendingNFT;

        _closingPosition(
            isAave[_keyId],
            wiseLendingNFT,
            _allowedSpread,
            _ethBack
        );

        emit FarmExit(
            _keyId,
            wiseLendingNFT,
            _allowedSpread,
            block.timestamp
        );
    }

    function manuallyPaybackShares(
        uint256 _keyId,
        uint256 _paybackShares
    )
        external
        virtual
        updatePools
    {
        _manuallyPaybackShares(
            farmingKeys[_keyId],
            _paybackShares
        );

        emit ManualPaybackShares(
            _keyId,
            farmingKeys[_keyId],
            _paybackShares,
            block.timestamp
        );
    }

    function manuallyWithdrawShares(
        uint256 _keyId,
        uint256 _withdrawShares
    )
        external
        virtual
        updatePools
        onlyKeyOwner(_keyId)
    {
        uint256 wiseLendingNFT = farmingKeys[
            _keyId
        ];

        _manuallyWithdrawShares(
            wiseLendingNFT,
            _withdrawShares
        );

        if (_checkDebtRatio(wiseLendingNFT) == false) {
            revert GenericDebtRatioTooHigh();
        }

        emit ManualWithdrawShares(
            _keyId,
            wiseLendingNFT,
            _withdrawShares,
            block.timestamp
        );
    }
}

error LRTfi_DebtRatioTooHigh();
error LRTfi_TooMuchValueLost();

contract LRTfiPowerFarm is GenericPowerManager {

    constructor(
        address _wiseLendingAddress,
        address _pendleChildTokenAddress,
        address _pendleRouter,
        address _entryAsset,
        address _pendleSy,
        address _underlyingMarket,
        address _routerStatic,
        address _dexAddress,
        uint256 _collateralFactor,
        address _powerFarmNFTs
    )
        GenericPowerManager(
            _wiseLendingAddress,
            _pendleChildTokenAddress,
            _pendleRouter,
            _entryAsset,
            _pendleSy,
            _underlyingMarket,
            _routerStatic,
            _dexAddress,
            _collateralFactor,
            _powerFarmNFTs
        )
    {
        _doApprovals(
            _wiseLendingAddress
        );

        collateralFactorRole = msg.sender;

        FARM_ASSET = WETH_ADDRESS;
        POOL_ASSET_AAVE = AAVE_WETH_ADDRESS;
    }

    function _doApprovals(
        address _wiseLendingAddress
    )
        internal
        override
    {
        _safeApprove(
            address(ENTRY_ASSET),
            address(UNISWAP_V3_ROUTER),
            MAX_AMOUNT
        );

        _safeApprove(
            WETH_ADDRESS,
            address(UNISWAP_V3_ROUTER),
            MAX_AMOUNT
        );

        _safeApprove(
            WETH_ADDRESS,
            _wiseLendingAddress,
            MAX_AMOUNT
        );

        _safeApprove(
            PENDLE_CHILD,
            _wiseLendingAddress,
            MAX_AMOUNT
        );

        _safeApprove(
            ENTRY_ASSET,
            address(PENDLE_ROUTER),
            MAX_AMOUNT
        );

        _safeApprove(
            address(PENDLE_MARKET),
            PENDLE_CHILD,
            MAX_AMOUNT
        );

        _safeApprove(
            address(PENDLE_MARKET),
            address(PENDLE_ROUTER),
            MAX_AMOUNT
        );

        _safeApprove(
            address(ENTRY_ASSET),
            address(PENDLE_SY),
            MAX_AMOUNT
        );

        _safeApprove(
            address(PENDLE_SY),
            address(PENDLE_ROUTER),
            MAX_AMOUNT
        );

        _safeApprove(
            WETH_ADDRESS,
            address(AAVE_HUB),
            MAX_AMOUNT
        );
    }

    /**
     * @dev Internal function executing the
     * collateral deposit by converting ETH
     * into {ENTRY_ASSET}, adding it as collateral and
     * borrowing the flashloan token to pay
     * back {_totalDebtBalancer}.
     */
    function _logicOpenPosition(
        bool _isAave,
        uint256 _nftId,
        uint256 _depositAmount,
        uint256 _totalDebtBalancer,
        uint256 _allowedSpread
    )
        internal
        override
    {
        uint256 reverseAllowedSpread = 2
            * PRECISION_FACTOR_E18
            - _allowedSpread;

        _depositAmount = _getTokensUniV3(
            _depositAmount,
            _getEthInTokens(
                ENTRY_ASSET,
                _depositAmount
            )
                * reverseAllowedSpread
                / PRECISION_FACTOR_E18,
            WETH_ADDRESS,
            ENTRY_ASSET
        );

        uint256 syReceived = PENDLE_SY.deposit(
            {
                _receiver: address(this),
                _tokenIn: ENTRY_ASSET,
                _amountTokenToDeposit: _depositAmount,
                _minSharesOut: PENDLE_SY.previewDeposit(
                    ENTRY_ASSET,
                    _depositAmount
                )
            }
        );

        (   ,
            uint256 netPtFromSwap,
            ,
            ,
            ,
        ) = PENDLE_ROUTER_STATIC.addLiquiditySingleSyStatic(
            address(PENDLE_MARKET),
            syReceived
        );

        (
            uint256 netLpOut
            ,
        ) = PENDLE_ROUTER.addLiquiditySingleSy(
            {
                _receiver: address(this),
                _market: address(PENDLE_MARKET),
                _netSyIn: syReceived,
                _minLpOut: 0,
                _guessPtReceivedFromSy: ApproxParams(
                    {
                        guessMin: netPtFromSwap - 100,
                        guessMax: netPtFromSwap + 100,
                        guessOffchain: 0,
                        maxIteration: 50,
                        eps: 1e15
                    }
                )
            }
        );

        uint256 ethValueBefore = _getTokensInETH(
            ENTRY_ASSET,
            _depositAmount
        );

        (
            uint256 receivedShares
            ,
        ) = IPendleChild(PENDLE_CHILD).depositExactAmount(
            netLpOut
        );

        uint256 ethValueAfter = _getTokensInETH(
            PENDLE_CHILD,
            receivedShares
        )
            * _allowedSpread
            / PRECISION_FACTOR_E18;

        if (ethValueAfter < ethValueBefore) {
            revert LRTfi_TooMuchValueLost();
        }

        WISE_LENDING.depositExactAmount(
            _nftId,
            PENDLE_CHILD,
            receivedShares
        );

        _borrowExactAmount(
            _isAave,
            _nftId,
            _totalDebtBalancer
        );

        if (_checkDebtRatio(_nftId) == false) {
            revert LRTfi_DebtRatioTooHigh();
        }

        _safeTransfer(
            WETH_ADDRESS,
            BALANCER_ADDRESS,
            _totalDebtBalancer
        );
    }

    /**
     * @dev Closes position using balancer flashloans.
     */
    function _logicClosePosition(
        uint256 _nftId,
        uint256 _borrowShares,
        uint256 _lendingShares,
        uint256 _totalDebtBalancer,
        uint256 _allowedSpread,
        address _caller,
        bool _ethBack,
        bool _isAave
    )
        internal
        override
    {
        _paybackExactShares(
            _isAave,
            _nftId,
            _borrowShares
        );

        uint256 withdrawnLpsAmount = _withdrawPendleLPs(
            _nftId,
            _lendingShares
        );

        uint256 ethValueBefore = _getTokensInETH(
            PENDLE_CHILD,
            withdrawnLpsAmount
        );

        (
            uint256 netSyOut
            ,
        ) = PENDLE_ROUTER.removeLiquiditySingleSy(
            {
                _receiver: address(this),
                _market: address(PENDLE_MARKET),
                _netLpToRemove: withdrawnLpsAmount,
                _minSyOut: 0
            }
        );

        address tokenOut = ENTRY_ASSET;

        uint256 tokenOutAmount = PENDLE_SY.redeem(
            {
                _receiver: address(this),
                _amountSharesToRedeem: netSyOut,
                _tokenOut: tokenOut,
                _minTokenOut: 0,
                _burnFromInternalBalance: false
            }
        );

        uint256 reverseAllowedSpread = 2
            * PRECISION_FACTOR_E18
            - _allowedSpread;

        uint256 ethAmount = _getEthBack(
            tokenOutAmount,
            _getTokensInETH(
                WETH_ADDRESS,
                _getTokensInETH(
                    tokenOut,
                    tokenOutAmount
                )
            )
                * reverseAllowedSpread
                / PRECISION_FACTOR_E18
        );

        uint256 ethValueAfter = _getTokensInETH(
            WETH_ADDRESS,
            ethAmount
        )
            * _allowedSpread
            / PRECISION_FACTOR_E18;

        if (ethValueAfter < ethValueBefore) {
            revert LRTfi_TooMuchValueLost();
        }

        if (_ethBack == true) {
            _closingRouteETH(
                ethAmount,
                _totalDebtBalancer,
                _caller
            );

            return;
        }

        _closingRouteToken(
            ethAmount,
            _totalDebtBalancer,
            _caller
        );
    }
}