/**
 *Submitted for verification at Arbiscan.io on 2024-01-10
*/

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

/**
 * @author Christoph Krpoun
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */


/**
 * @dev Purpose of this contract is to organize fee distribution from wiseLending.
 * The feeManager aquires fee token in form of shares from each pool and can call them
 * with "claimWiseFees()" for each pool.
 *
 * Furthermore, this contracts has two different incentive
 * structures which can be used to bootstrap the WISE ecosystem (beneficial and incnetiveOwner roles).
 *
 * Additionally, this contract keeps track of the bad debt of each postion and has a simple mechanism
 * to pay them back via incentives. The incentive amount is funded by the gathered fees.
 */

contract FeeManagerEvents {

    event ClaimedFeesWiseBulk(
        uint256 timestamp
    );

    event PoolTokenRemoved(
        address indexed poolToken,
        uint256 timestamp
    );

    event PoolTokenAdded(
        address indexed poolToken,
        uint256 timestamp
    );

    event IncentiveOwnerBChanged(
        address indexed newIncentiveOwnerB,
        uint256 timestamp
    );

    event IncentiveOwnerAChanged(
        address indexed newIncentiveOwnerA,
        uint256 timestamp
    );

    event ClaimedOwnershipIncentiveMaster(
        address indexed newIncentiveMaster,
        uint256 timestamp
    );

    event IncentiveMasterProposed(
        address indexed proposedIncentiveMaster,
        uint256 timestamp
    );

    event PoolFeeChanged(
        address indexed poolToken,
        uint256 indexed newPoolFee,
        uint256 timestamp
    );

    event ClaimedIncentives(
        address indexed sender,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event ClaimedIncentivesBulk(
        uint256 timestamp
    );

    event IncentiveIncreasedB(
        uint256 indexed amount,
        uint256 timestamp
    );

    event IncentiveIncreasedA(
        uint256 indexed amount,
        uint256 timestamp
    );

    event BadDebtIncreasedLiquidation(
        uint256 amount,
        uint256 timestamp
    );

    event TotalBadDebtIncreased(
        uint256 amount,
        uint256 timestamp
    );

    event TotalBadDebtDecreased(
        uint256 amount,
        uint256 timestamp
    );

    event SetBadDebtPosition(
        uint256 indexed nftId,
        uint256 amount,
        uint256 timestamp
    );

    event UpdateBadDebtPosition(
        uint256 indexed nftId,
        uint256 newAmount,
        uint256 timestamp
    );

    event SetBeneficial(
        address indexed user,
        address[] token,
        uint256 timestamp
    );

    event RevokeBeneficial(
        address indexed user,
        address[] token,
        uint256 timestamp
    );

    event ClaimedFeesWise(
        address indexed token,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    event ClaimedFeesBeneficial(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 indexed timestamp
    );

    event PayedBackBadDebt(
        uint256 indexed nftId,
        address indexed sender,
        address indexed paybackToken,
        address receivingToken,
        uint256 paybackAmount,
        uint256 timestamp
    );

    event PayedBackBadDebtFree(
        uint256 indexed nftId,
        address indexed sender,
        address indexed paybackToken,
        uint256  paybackAmount,
        uint256 timestampp
    );
}

error NoValue();
error NotMaster();
error NotProposed();

contract OwnableMaster {

    address public master;
    address private proposedMaster;

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

    event ClaimedOwnership(
        address indexed newMaster,
        address indexed previousMaster
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

        emit ClaimedOwnership(
            master,
            msg.sender
        );
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

interface IPositionNFTs {

    function ownerOf(
        uint256 _nftId
    )
        external
        view
        returns (address);

    function getOwner(
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

    function overallETHBorrowHeartbeat(
        uint256 _nftId
    )
        external
        view
        returns (uint256 buffer);

    function checkBadDebt(
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

    function getPositionBorrowAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getPositionLendingAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getLiveDebtRatio(
        uint256 _nftId
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

    function checksWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksBorrow(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksSolelyWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

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

interface IFeeManager {

    function underlyingToken(
        address _poolToken
    )
        external
        view
        returns (address);

    function isAaveToken(
        address _poolToken
    )
        external
        view
        returns (bool);

    function setBadDebtUserLiquidation(
        uint256 _nftId,
        uint256 _amount
    )
        external;

    function increaseTotalBadDebtLiquidation(
        uint256 _amount
    )
        external;

    function FEE_MANAGER_NFT()
        external
        view
        returns (uint256);

    function addPoolTokenAddress(
        address _poolToken
    )
        external;

    function getPoolTokenAdressesByIndex(
        uint256 _index
    )
        external
        view
        returns (address);

    function getPoolTokenAddressesLength()
        external
        view
        returns (uint256);
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

    function solelyWithdrawOnBehalf(
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
        address _receiver,
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

    function deposit(
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

error NotWiseLiquidation();
error AlreadySet();
error ExistingBadDebt();
error NotWiseLending();
error NotIncentiveMaster();
error PoolAlreadyAdded();
error TooHighValue();
error TooLowValue();
error NotAllowed();
error PoolNotPresent();
error ZeroAddress();
error NoIncentive();
error Reentered();
error PoolNotActive();

contract DeclarationsFeeManager is FeeManagerEvents, OwnableMaster {

    constructor(
        address _master,
        address _aaveAddress,
        address _wiseLendingAddress,
        address _oracleHubAddress,
        address _wiseSecurityAddress,
        address _positionNFTAddress
    )
        OwnableMaster(
            _master
        )
    {
        if (_aaveAddress == ZERO_ADDRESS) {
            revert NoValue();
        }

        if (_wiseLendingAddress == ZERO_ADDRESS) {
            revert NoValue();
        }

        if (_oracleHubAddress == ZERO_ADDRESS) {
            revert NoValue();
        }

        if (_wiseSecurityAddress == ZERO_ADDRESS) {
            revert NoValue();
        }

        if (_positionNFTAddress == ZERO_ADDRESS) {
            revert NoValue();
        }

        WISE_LENDING = IWiseLending(
            _wiseLendingAddress
        );

        AAVE = IAave(
            _aaveAddress
        );

        ORACLE_HUB = IWiseOracleHub(
            _oracleHubAddress
        );

        WISE_SECURITY = IWiseSecurity(
            _wiseSecurityAddress
        );

        POSITION_NFTS = IPositionNFTs(
            _positionNFTAddress
        );

        FEE_MANAGER_NFT = POSITION_NFTS.FEE_MANAGER_NFT();

        incentiveMaster = _master;
        paybackIncentive = 5 * PRECISION_FACTOR_E16;

        incentiveOwnerA = 0xf69A0e276664997357BF987df83f32a1a3F80944;
        incentiveOwnerB = 0x8f741ea9C9ba34B5B8Afc08891bDf53faf4B3FE7;

        incentiveUSD[incentiveOwnerA] = 98000 * PRECISION_FACTOR_E18;
        incentiveUSD[incentiveOwnerB] = 106500 * PRECISION_FACTOR_E18;
    }

    // ---- Interfaces ----

    // Interface aave V3 contract
    IAave public immutable AAVE;

    // Interface wiseLending contract
    IWiseLending public immutable WISE_LENDING;

    // Interface position NFT contract
    IPositionNFTs public immutable POSITION_NFTS;

    // Interface wiseSecurity contract
    IWiseSecurity public immutable WISE_SECURITY;

    // Interface wise oracleHub contract
    IWiseOracleHub public immutable ORACLE_HUB;

    // ---- Variables ----

    // Global total bad debt variable
    uint256 public totalBadDebtETH;

    // Incentive percentage for paying back bad debt
    uint256 public paybackIncentive;

    // Array of pool tokens in wiseLending
    address[] public poolTokenAddresses;

    // Address of incentive master
    address public incentiveMaster;

    // Proposed incentive master (for changing)
    address public proposedIncentiveMaster;

    // Address of incentive owner A
    address public incentiveOwnerA;

    // Address of incentive owner B
    address public incentiveOwnerB;

    // ---- Mappings ----

    // Bad debt of a specific position
    mapping(uint256 => uint256) public badDebtPosition;

    // Amount of fee token inside feeManager
    mapping(address => uint256) public feeTokens;

    // Open incetive amount for incentiveOwner in ETH
    mapping(address => uint256) public incentiveUSD;

    // Flag that specific token is already added
    mapping(address => bool) public poolTokenAdded;

    // Flag for token being aToken
    mapping(address => bool) public isAaveToken;

    // Getting underlying token of aave aToken
    mapping(address => address) public underlyingToken;

    // Showing which token are allowed to claim for beneficial address
    mapping(address => mapping(address => bool)) public allowedTokens;

    // Gives claimable token amount for incentiveOwner per token
    mapping(address => mapping(address => uint256)) public gatheredIncentiveToken;

    // Position NFT id of the feeManager
    uint256 public immutable FEE_MANAGER_NFT;

    // Precision factors for computations
    uint256 internal constant PRECISION_FACTOR_E15 = 1E15;
    uint256 internal constant PRECISION_FACTOR_E16 = 1E16;
    uint256 internal constant PRECISION_FACTOR_E18 = 1E18;

    // Base portion from gathered fees for incentiveOwners (0.5%)
    uint256 public constant INCENTIVE_PORTION = 5 * PRECISION_FACTOR_E15;

    // ---- Modifier ----

    modifier onlyWiseSecurity() {
        _onlyWiseSecurity();
        _;
    }

    modifier onlyWiseLending() {
        _onlyWiseLending();
        _;
    }

    modifier onlyIncentiveMaster() {
        _onlyIncentiveMaster();
        _;
    }

    function _onlyIncentiveMaster()
        private
        view
    {
        if (msg.sender == incentiveMaster) {
            return;
        }

        revert NotIncentiveMaster();
    }

    function _onlyWiseSecurity()
        private
        view
    {
        if (msg.sender == address(WISE_SECURITY)) {
            return;
        }

        revert NotWiseLiquidation();
    }

    function _onlyWiseLending()
        private
        view
    {
        if (msg.sender == address(WISE_LENDING)) {
            return;
        }

        revert NotWiseLending();
    }
}

abstract contract FeeManagerHelper is DeclarationsFeeManager, TransferHelper {

    /**
     * @dev Internal update function which adds latest aquired token from borrow rate
     * for all borrow tokens of the position. Idnetical implementation like in wiseSecurity
     * or wiseLending.
     */
    function _prepareBorrows(
        uint256 _nftId
    )
        internal
    {
        uint256 i;
        uint256 l = WISE_LENDING.getPositionBorrowTokenLength(
            _nftId
        );

        while (i < l) {

            address currentAddress = WISE_LENDING.getPositionBorrowTokenByIndex(
                _nftId,
                i
            );

            WISE_LENDING.syncManually(
                currentAddress
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Internal update function which adds latest aquired token from borrow rate
     * for all collateral tokens of the position. Idnetical implementation like in wiseSecurity
     * or wiseLending.
     */
    function _prepareCollaterals(
        uint256 _nftId
    )
        internal
    {
        uint256 i;
        uint256 l = WISE_LENDING.getPositionLendingTokenLength(
            _nftId
        );

        while (i < l) {

            address currentAddress = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            WISE_LENDING.syncManually(
                currentAddress
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Internal set function for adjusting bad debt amount of a position.
     */
    function _setBadDebtPosition(
        uint256 _nftId,
        uint256 _amount
    )
        internal
    {
        badDebtPosition[_nftId] = _amount;
    }

    /**
     * @dev Internal increase function for global bad debt amount.
     */
    function _increaseTotalBadDebt(
        uint256 _amount
    )
        internal
    {
        totalBadDebtETH += _amount;

        emit TotalBadDebtIncreased(
            _amount,
            block.timestamp
        );
    }

    /**
     * @dev Internal decrease function for global bad debt amount.
     */
    function _decreaseTotalBadDebt(
        uint256 _amount
    )
        internal
    {
        totalBadDebtETH -= _amount;

        emit TotalBadDebtDecreased(
            _amount,
            block.timestamp
        );
    }

    /**
     * @dev Internal erease function to delete bad debt amount of a postion.
     */
    function _eraseBadDebtUser(
        uint256 _nftId
    )
        internal
    {
        delete badDebtPosition[_nftId];
    }

    /**
     * @dev Internal function updating bad debt amount of a position and global one (in ETH).
     * Compares totalBorrow and totalCollateral of the postion in ETH and adjustes bad debt
     * variables. Pseudo pool amounts needed to be updated before this function is called.
     */
    function _updateUserBadDebt(
        uint256 _nftId
    )
        internal
    {
        uint256 currentBorrowETH = WISE_SECURITY.overallETHBorrowHeartbeat(
            _nftId
        );

        uint256 currentCollateralBareETH = WISE_SECURITY.overallETHCollateralsBare(
            _nftId
        );

        uint256 currentBadDebt = badDebtPosition[
            _nftId
        ];

        if (currentBorrowETH < currentCollateralBareETH) {

            _eraseBadDebtUser(
                _nftId
            );

            _decreaseTotalBadDebt(
                currentBadDebt
            );

            emit UpdateBadDebtPosition(
                _nftId,
                0,
                block.timestamp
            );

            return;
        }

        unchecked {
            uint256 newBadDebt = currentBorrowETH
                - currentCollateralBareETH;

            _setBadDebtPosition(
                _nftId,
                newBadDebt
            );

            newBadDebt > currentBadDebt
                ? _increaseTotalBadDebt(newBadDebt - currentBadDebt)
                : _decreaseTotalBadDebt(currentBadDebt - newBadDebt);

            emit UpdateBadDebtPosition(
                _nftId,
                newBadDebt,
                block.timestamp
            );
        }
    }

    /**
     * @dev Internal increase function for tracking gathered fee token. No need for
     * balanceOf() checks.
     */
    function _increaseFeeTokens(
        address _feeToken,
        uint256 _amount
    )
        internal
    {
        feeTokens[_feeToken] += _amount;
    }

    /**
     * @dev Internal decrease function for tracking gathered fee token. No need for
     * balanceOf() checks.
     */
    function _decreaseFeeTokens(
        address _feeToken,
        uint256 _amount
    )
        internal
    {
        feeTokens[_feeToken] -= _amount;
    }

    /**
     * @dev Internal function to set benefical mapping for a certain token.
     */
    function _setAllowedTokens(
        address _user,
        address _feeToken,
        bool _state
    )
        internal
    {
        allowedTokens[_user][_feeToken] = _state;
    }

    function _setAaveFlag(
        address _poolToken,
        address _underlyingToken
    )
        internal
    {
        isAaveToken[_poolToken] = true;
        underlyingToken[_poolToken] = _underlyingToken;
    }

    /**
     * @dev Internal function calculating receive amount for the caller.
     * paybackIncentive is set to 5E16 => 5% incentive for paying back bad debt.
     */
    function getReceivingToken(
        address _paybackToken,
        address _receivingToken,
        uint256 _paybackAmount
    )
        public
        view
        returns (uint256 receivingAmount)
    {
        uint256 increasedAmount = _paybackAmount
            * (PRECISION_FACTOR_E18 + paybackIncentive)
            / PRECISION_FACTOR_E18;

        return ORACLE_HUB.getTokensFromETH(
            _receivingToken,
            ORACLE_HUB.getTokensInETH(
                _paybackToken,
                increasedAmount
            )
        );
    }

    /**
     * @dev Updates bad debt of a postion. Combines preparation of all
     * collaterals and borrows for passed _nftId with _updateUserBadDebt().
     */
    function updatePositionCurrentBadDebt(
        uint256 _nftId
    )
        public
    {
        _prepareCollaterals(
            _nftId
        );

        _prepareBorrows(
            _nftId
        );

        _updateUserBadDebt(
            _nftId
        );
    }

    /**
     * @dev Internal function for distributing incentives to incentiveOwnerA
     * and incentiveOwnerB.
     */
    function _distributeIncentives(
        uint256 _amount,
        address _poolToken,
        address _underlyingToken
    )
        internal
        returns (uint256)
    {
        uint256 reduceAmount;

        if (incentiveUSD[incentiveOwnerA] > 0) {

            reduceAmount += _gatherIncentives(
                _poolToken,
                _underlyingToken,
                incentiveOwnerA,
                _amount
            );
        }

        if (incentiveUSD[incentiveOwnerB] > 0) {

            reduceAmount += _gatherIncentives(
                _poolToken,
                _underlyingToken,
                incentiveOwnerB,
                _amount
            );
        }

        return _amount - reduceAmount;
    }

    /**
     * @dev Internal function computing the incentive amount for an incentiveOwner
     * depending of the amount per fee token. Reduces the open incentive amount for
     * the owner.
     */
    function _gatherIncentives(
        address _poolToken,
        address _underlyingToken,
        address _incentiveOwner,
        uint256 _amount
    )
        internal
        returns (uint256)
    {
        uint256 incentiveAmount = _amount
            * INCENTIVE_PORTION
            / WISE_LENDING.globalPoolData(_poolToken).poolFee;

        uint256 usdEquivalent = ORACLE_HUB.getTokensPriceInUSD(
            _poolToken,
            incentiveAmount
        );

        uint256 reduceUSD = usdEquivalent < incentiveUSD[_incentiveOwner]
            ? usdEquivalent
            : incentiveUSD[_incentiveOwner];

        if (reduceUSD == usdEquivalent) {

            incentiveUSD[_incentiveOwner] -= usdEquivalent;

            gatheredIncentiveToken
                [_incentiveOwner]
                [_underlyingToken] += incentiveAmount;

            return incentiveAmount;
        }

        incentiveAmount = ORACLE_HUB.getTokensPriceFromUSD(
            _poolToken,
            reduceUSD
        );

        delete incentiveUSD[
            _incentiveOwner
        ];

        gatheredIncentiveToken
            [_incentiveOwner]
            [_underlyingToken] += incentiveAmount;

        return incentiveAmount;
    }

    /**
     * @dev Internal function checking if the
     * passed value is smaller 100% and bigger 1%.
     */
    function _checkValue(
        uint256 _value
    )
        internal
        pure
    {
        if (_value < PRECISION_FACTOR_E16) {
            revert TooLowValue();
        }

        if (_value > PRECISION_FACTOR_E18) {
            revert TooHighValue();
        }
    }
}

contract FeeManager is FeeManagerHelper {

    constructor(
        address _master,
        address _aaveAddress,
        address _wiseLendingAddress,
        address _oracleHubAddress,
        address _wiseSecurityAddress,
        address _positionNFTAddress
    )
        DeclarationsFeeManager(
            _master,
            _aaveAddress,
            _wiseLendingAddress,
            _oracleHubAddress,
            _wiseSecurityAddress,
            _positionNFTAddress
        )
    {}

    /**
     * @dev Allows to adjust the paid out incentive
     * percentage for user to reduce bad debt.
     */
    function setRepayBadDebtIncentive(
        uint256 _percent
    )
        external
        onlyMaster
    {
        _checkValue(
            _percent
        );

        paybackIncentive = _percent;
    }

    /**
     * @dev Maps underlying token with corresponding aToken.
     * Sets bool to identify pool token as aToken.
     */
    function setAaveFlag(
        address _poolToken,
        address _underlyingToken
    )
        external
        onlyMaster
    {
        _setAaveFlag(
            _poolToken,
            _underlyingToken
        );
    }

    /**
     * @dev Bulk function for setting aave flag for multiple pools.
     */
    function setAaveFlagBulk(
        address[] calldata _poolTokens,
        address[] calldata _underlyingTokens
    )
        external
        onlyMaster
    {
        uint256 i;
        uint256 l = _poolTokens.length;

        while (i < l) {
            _setAaveFlag(
                _poolTokens[i],
                _underlyingTokens[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Function to adjust pool fee. Fee can not be greater than 100%
     * or lower than 1%. Can be adjusted for each pool individually.
     */
    function setPoolFee(
        address _poolToken,
        uint256 _newFee
    )
        external
        onlyMaster
    {
        _checkValue(
            _newFee
        );

        WISE_LENDING.setPoolFee(
            _poolToken,
            _newFee
        );

        emit PoolFeeChanged(
            _poolToken,
            _newFee,
            block.timestamp
        );
    }

    /**
    * @dev Function to adjust pool fees in bulk. Fee for each pool can not be
    * greater than 100% or lower than 1%. Can be adjusted for each pool individually.
    */
    function setPoolFeeBulk(
        address[] calldata _poolTokens,
        uint256[] calldata _newFees
    )
        external
        onlyMaster
    {
        uint256 i;
        uint256 l = _poolTokens.length;

        while (i < l) {

            _checkValue(
                _newFees[i]
            );

            WISE_LENDING.setPoolFee(
                _poolTokens[i],
                _newFees[i]
            );

            emit PoolFeeChanged(
                _poolTokens[i],
                _newFees[i],
                block.timestamp
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Function to propose new incentive master. This role can increase
     * the incentive amount for both incentive mappings. These are two roles
     * for incentivising external persons e.g. developers.
     */
    function proposeIncentiveMaster(
        address _proposedIncentiveMaster
    )
        external
        onlyIncentiveMaster
    {
        if (_proposedIncentiveMaster == ZERO_ADDRESS) {
            revert ZeroAddress();
        }

        proposedIncentiveMaster = _proposedIncentiveMaster;

        emit IncentiveMasterProposed(
            _proposedIncentiveMaster,
            block.timestamp
        );
    }

    /**
     * @dev Claim proposed incentive master by proposed entity.
     */
    function claimOwnershipIncentiveMaster()
        external
    {
        if (msg.sender != proposedIncentiveMaster) {
            revert NotAllowed();
        }

        incentiveMaster = proposedIncentiveMaster;
        proposedIncentiveMaster = ZERO_ADDRESS;

        emit ClaimedOwnershipIncentiveMaster(
            incentiveMaster,
            block.timestamp
        );
    }

    /**
     * @dev Increase function for increasing incentive amount for entity A.
     * Only callable by incentive master.
     */
    function increaseIncentiveA(
        uint256 _value
    )
        external
        onlyIncentiveMaster
    {
        incentiveUSD[incentiveOwnerA] += _value;

        emit IncentiveIncreasedA(
            _value,
            block.timestamp
        );
    }

    /**
     * @dev Increase function for increasing incentive amount for entity B.
     * Only callable by incentive master.
     */
    function increaseIncentiveB(
        uint256 _value
    )
        external
        onlyIncentiveMaster
    {
        incentiveUSD[incentiveOwnerB] += _value;

        emit IncentiveIncreasedB(
            _value,
            block.timestamp
        );
    }

    /**
     * @dev Function to claim all gathered incetives.
     */
    function claimIncentivesBulk()
        external
    {
        address tokenAddress;

        uint256 i;
        uint256 l = getPoolTokenAddressesLength();

        while (i < l) {

            tokenAddress = poolTokenAddresses[i];

            if (isAaveToken[tokenAddress] == true) {
                tokenAddress = underlyingToken[
                    tokenAddress
                ];
            }

            claimIncentives(
                tokenAddress
            );

            unchecked {
                ++i;
            }
        }

        emit ClaimedIncentivesBulk(
            block.timestamp
        );
    }

    /**
     * @dev Claims gathered incentives for a specific token.
     */
    function claimIncentives(
        address _feeToken
    )
        public
    {
        uint256 amount = gatheredIncentiveToken[msg.sender][_feeToken];

        if (amount == 0) {
            revert NoIncentive();
        }

        delete gatheredIncentiveToken[msg.sender][_feeToken];

        emit ClaimedIncentives(
            msg.sender,
            _feeToken,
            amount,
            block.timestamp
        );

        _safeTransfer(
            _feeToken,
            msg.sender,
            amount
        );
    }

    /**
     * @dev Function changing incentiveOwnerA! Only callable by
     * incentiveOwnerA.
     */
    function changeIncentiveUSDA(
        address _newOwner
    )
        external
    {
        if (msg.sender != incentiveOwnerA) {
            revert NotAllowed();
        }

        if (_newOwner == incentiveOwnerA) {
            revert NotAllowed();
        }

        if (_newOwner == incentiveOwnerB) {
            revert NotAllowed();
        }

        incentiveUSD[_newOwner] = incentiveUSD[
            incentiveOwnerA
        ];

        delete incentiveUSD[
            incentiveOwnerA
        ];

        incentiveOwnerA = _newOwner;

        emit IncentiveOwnerAChanged(
            _newOwner,
            block.timestamp
        );
    }

    /**
     * @dev Function changing incentiveOwnerB! Only callable by
     * incentiveOwnerB.
     */
    function changeIncentiveUSDB(
        address _newOwner
    )
        external
    {
        if (msg.sender != incentiveOwnerB) {
            revert NotAllowed();
        }

        if (_newOwner == incentiveOwnerA) {
            revert NotAllowed();
        }

        if (_newOwner == incentiveOwnerB) {
            revert NotAllowed();
        }

        incentiveUSD[_newOwner] = incentiveUSD[
            incentiveOwnerB
        ];

        delete incentiveUSD[
            incentiveOwnerB
        ];

        incentiveOwnerB = _newOwner;

        emit IncentiveOwnerBChanged(
            _newOwner,
            block.timestamp
        );
    }

    /**
     * @dev Function adding new pool token to pool token list.
     * Called during pool creation and only callable by wiseLending
     * contract.
     */
    function addPoolTokenAddress(
        address _poolToken
    )
        external
        onlyWiseLending
    {
        poolTokenAddresses.push(
            _poolToken
        );

        poolTokenAdded[_poolToken] = true;

        emit PoolTokenAdded(
            _poolToken,
            block.timestamp
        );
    }

    /**
     * @dev Function to add pool token manualy. Only
     * callable by feeManager master.
     */
    function addPoolTokenAddressManual(
        address _poolToken
    )
        external
        onlyMaster
    {
        if (poolTokenAdded[_poolToken] == true) {
            revert PoolAlreadyAdded();
        }

        poolTokenAddresses.push(
            _poolToken
        );

        poolTokenAdded[_poolToken] = true;

        emit PoolTokenAdded(
            _poolToken,
            block.timestamp
        );
    }

    /**
     * @dev Function to remove pool token manualy from pool
     * token list. Only callable by feeManager master.
     */
    function removePoolTokenManual(
        address _poolToken
    )
        external
        onlyMaster
    {
        uint256 i;
        uint256 len = getPoolTokenAddressesLength();
        uint256 lastEntry = len - 1;
        bool found;

        if (poolTokenAdded[_poolToken] == false) {
            revert PoolNotPresent();
        }

        while (i < len) {

            if (_poolToken != poolTokenAddresses[i]) {

                unchecked {
                    ++i;
                }

                continue;
            }

            found = true;

            if (i != lastEntry) {
                poolTokenAddresses[i] = poolTokenAddresses[lastEntry];
            }

            break;
        }

        if (found == true) {

            poolTokenAddresses.pop();
            poolTokenAdded[_poolToken] = false;

            emit PoolTokenRemoved(
                _poolToken,
                block.timestamp
            );

            return;
        }

        revert PoolNotPresent();
    }

    /**
     * @dev Increase function for total bad debt of
     * wiseLending. Only callable by wiseSecurity contract
     * during liquidation.
     */
    function increaseTotalBadDebtLiquidation(
        uint256 _amount
    )
        external
        onlyWiseSecurity
    {
        _increaseTotalBadDebt(
            _amount
        );

        emit BadDebtIncreasedLiquidation(
            _amount,
            block.timestamp
        );
    }

    /**
     * @dev Increase function for bad debt of a position.
     * Only callable by wiseSecurity contract during liquidation.
     */
    function setBadDebtUserLiquidation(
        uint256 _nftId,
        uint256 _amount
    )
        external
        onlyWiseSecurity
    {
        _setBadDebtPosition(
            _nftId,
            _amount
        );

        emit SetBadDebtPosition(
            _nftId,
            _amount,
            block.timestamp
        );
    }

    /**
     * @dev Set function to declare an address as beneficial for
     * a fee token. Address can claim gathered fee token as long as
     * it is declared as beneficial. Only setable by master.
     */
    function setBeneficial(
        address _user,
        address[] calldata _feeTokens
    )
        external
        onlyMaster
    {
        uint256 i;
        uint256 l = _feeTokens.length;

        while (i < l) {
            _setAllowedTokens(
                _user,
                _feeTokens[i],
                true
            );

            unchecked {
                ++i;
            }
        }

        emit SetBeneficial(
            _user,
            _feeTokens,
            block.timestamp
        );
    }

    /**
     * @dev Set function to remove an address as beneficial for
     * a fee token. Only setable by master.
     */
    function revokeBeneficial(
        address _user,
        address[] memory _feeTokens
    )
        external
        onlyMaster
    {
        uint256 i;
        uint256 l = _feeTokens.length;

        while (i < l) {
            _setAllowedTokens(
                _user,
                _feeTokens[i],
                false
            );

            unchecked {
                ++i;
            }
        }

        emit RevokeBeneficial(
            _user,
            _feeTokens,
            block.timestamp
        );
    }

    /**
     * @dev Claim all fees from wiseLending and send them to feeManager.
     */
    function claimWiseFeesBulk()
        external
    {
        uint256 i;
        uint256 l = getPoolTokenAddressesLength();

        while (i < l) {
            claimWiseFees(
                poolTokenAddresses[i]
            );

            unchecked {
                ++i;
            }
        }

        emit ClaimedFeesWiseBulk(
            block.timestamp
        );
    }

    /**
     * @dev Claim fees from wiseLending and send them to feeManager for
     * a specific pool.
     */
    function claimWiseFees(
        address _poolToken
    )
        public
    {
        address underlyingTokenAddress = _poolToken;

        uint256 shares = WISE_LENDING.getPositionLendingShares(
            FEE_MANAGER_NFT,
            _poolToken
        );

        if (shares == 0) {
            return;
        }

        uint256 tokenAmount = WISE_LENDING.withdrawExactShares(
            FEE_MANAGER_NFT,
            _poolToken,
            shares
        );

        if (isAaveToken[_poolToken] == true) {

            underlyingTokenAddress = underlyingToken[
                _poolToken
            ];

            tokenAmount = AAVE.withdraw(
                underlyingTokenAddress,
                tokenAmount,
                address(this)
            );
        }

        if (totalBadDebtETH == 0) {

            tokenAmount = _distributeIncentives(
                tokenAmount,
                _poolToken,
                underlyingTokenAddress
            );
        }

        _increaseFeeTokens(
            underlyingTokenAddress,
            tokenAmount
        );

        emit ClaimedFeesWise(
            underlyingTokenAddress,
            tokenAmount,
            block.timestamp
        );
    }

    /**
     * @dev Function for beneficial to claim gathered fees. Can only
     * claim fees for which the beneficial is allowed. Can only claim
     * token which are inside the feeManager.
     */
    function claimFeesBeneficial(
        address _feeToken,
        uint256 _amount
    )
        external
    {
        address caller = msg.sender;

        if (totalBadDebtETH > 0) {
            revert ExistingBadDebt();
        }

        if (allowedTokens[caller][_feeToken] == false) {
            revert NotAllowed();
        }

        _decreaseFeeTokens(
            _feeToken,
            _amount
        );

        _safeTransfer(
            _feeToken,
            caller,
            _amount
        );

        emit ClaimedFeesBeneficial(
            caller,
            _feeToken,
            _amount,
            block.timestamp
        );
    }

    /**
     * @dev Function for paying back bad debt of a position. Caller
     * chooses postion, token and receive token. Only gathered fee token
     * can be distributed as receive token. Caller gets 5% more
     * in ETH value as incentive.
     */
    function paybackBadDebtForToken(
        uint256 _nftId,
        address _paybackToken,
        address _receivingToken,
        uint256 _shares
    )
        external
        returns (
            uint256 paybackAmount,
            uint256 receivingAmount
        )
    {
        updatePositionCurrentBadDebt(
            _nftId
        );

        if (badDebtPosition[_nftId] == 0) {
            return (
                0,
                0
            );
        }

        if (WISE_LENDING.getTotalDepositShares(_receivingToken) == 0) {
            revert PoolNotActive();
        }

        if (WISE_LENDING.getTotalDepositShares(_paybackToken) == 0) {
            revert PoolNotActive();
        }

        paybackAmount = WISE_LENDING.paybackAmount(
            _paybackToken,
            _shares
        );

        WISE_LENDING.corePaybackFeeManager(
            _paybackToken,
            _nftId,
            paybackAmount,
            _shares
        );

        _updateUserBadDebt(
            _nftId
        );

        receivingAmount = getReceivingToken(
            _paybackToken,
            _receivingToken,
            paybackAmount
        );

        _decreaseFeeTokens(
            _receivingToken,
            receivingAmount
        );

        _safeTransferFrom(
            _paybackToken,
            msg.sender,
            address(WISE_LENDING),
            paybackAmount
        );

        _safeTransfer(
            _receivingToken,
            msg.sender,
            receivingAmount
        );

        emit PayedBackBadDebt(
            _nftId,
            msg.sender,
            _paybackToken,
            _receivingToken,
            paybackAmount,
            block.timestamp
        );
    }

    /**
     * @dev Function for paying back bad debt of a position. Caller
     * chooses postion, token and receive token. Caller gets no
     * receive token!
     */
    function paybackBadDebtNoReward(
        uint256 _nftId,
        address _paybackToken,
        uint256 _shares
    )
        external
        returns (uint256 paybackAmount)
    {
        updatePositionCurrentBadDebt(
            _nftId
        );

        if (badDebtPosition[_nftId] == 0) {
            return 0;
        }

        if (WISE_LENDING.getTotalDepositShares(_paybackToken) == 0) {
            revert PoolNotActive();
        }

        paybackAmount = WISE_LENDING.paybackAmount(
            _paybackToken,
            _shares
        );

        WISE_LENDING.corePaybackFeeManager(
            _paybackToken,
            _nftId,
            paybackAmount,
            _shares
        );

        _updateUserBadDebt(
            _nftId
        );

        emit PayedBackBadDebtFree(
            _nftId,
            msg.sender,
            _paybackToken,
            paybackAmount,
            block.timestamp
        );

        _safeTransferFrom(
            _paybackToken,
            msg.sender,
            address(WISE_LENDING),
            paybackAmount
        );
    }

    /**
     * @dev Returning the number of pool token
     * addresses saved inside the feeManager.
     */
    function getPoolTokenAddressesLength()
        public
        view
        returns (uint256)
    {
        return poolTokenAddresses.length;
    }

    /**
     * @dev Returns the pool token address
     * at the _index postion of the array.
     */
    function getPoolTokenAdressesByIndex(
        uint256 _index
    )
        external
        view
        returns (address)
    {
        return poolTokenAddresses[_index];
    }

    /**
     * @dev Bulk function for updating pools - loops through
     * all pools saved inside the poolTokenAddresses array.
     */
    function syncAllPools()
        external
    {
        uint256 i;
        uint256 l = poolTokenAddresses.length;

        while (i < l) {
            WISE_LENDING.syncManually(
                poolTokenAddresses[i]
            );

            unchecked {
                ++i;
            }
        }
    }
}