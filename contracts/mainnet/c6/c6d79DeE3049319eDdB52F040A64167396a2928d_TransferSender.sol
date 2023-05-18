/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.19;

interface IRewardRouter {
    function gmx() external view returns (address);
    function esGmx() external view returns (address);
    function glp() external view returns (address);
    function weth() external view returns (address);
    function bnGmx() external view returns (address);

    function stakedGmxTracker() external view returns (address);
    function bonusGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function gmxVester() external view returns (address);
    function glpVester() external view returns (address);

    function stakeEsGmx(uint256 _amount) external;
    
    function signalTransfer(address _receiver) external;
    function acceptTransfer(address _sender) external;

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver) external returns (uint256);

    function claim() external;
    function pendingReceivers(address _account) external view returns (address);
}



interface IConverter {
    function gmx() external view returns (address);
    function esGmx() external view returns (address);
    function bnGmx() external view returns (address);
    function rewardRouter() external view returns (IRewardRouter);
    function stakedGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGlp() external view returns (address);
    function GMXkey() external view returns (address);
    function esGMXkey() external view returns (address);
    function MPkey() external view returns (address);
    function rewards() external view returns (address);
    function treasury() external view returns (address);
    function operator() external view returns (address);
    function transferReceiver() external view returns (address);
    function feeCalculator() external view returns (address);
    function receivers(address _account) external view returns (address);
    function minGmxAmount() external view returns (uint128);
    function qualifiedRatio() external view returns (uint32);
    function isForMpKey(address sender) external view returns (bool);
    function registeredReceivers(uint256 index) external view returns (address);
    function registeredReceiversLength() external view returns (uint256);
    function isValidReceiver(address _receiver) external view returns (bool);
    function convertedAmount(address account, address token) external view returns (uint256);
    function feeCalculatorReserved() external view returns (address, uint256);
    function setTransferReceiver(address _transferReceiver) external;
    function setQualification(uint128 _minGmxAmount, uint32 _qualifiedRatio) external;
    function createTransferReceiver() external;
    function approveMpKeyConversion(address _receiver, bool _approved) external;
    function completeConversion() external;
    function completeConversionToMpKey(address sender) external;
    event ReceiverRegistered(address indexed receiver, uint256 activeAt);
    event ReceiverCreated(address indexed account, address indexed receiver);
    event ConvertCompleted(address indexed account, address indexed receiver, uint256 gmxAmount, uint256 esGmxAmount, uint256 mpAmount);
    event ConvertForMpCompleted(address indexed account, address indexed receiver, uint256 amount);
    event ConvertingFeeCalculatorReserved(address to, uint256 at);

}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool); //
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); //
    function balanceOf(address account) external view returns (uint256); //
    function mint(address account, uint256 amount) external returns (bool); //
    function approve(address spender, uint256 amount) external returns (bool); //
    function allowance(address owner, address spender) external view returns (uint256); //
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external returns (bool); //
}


interface IReserved {

    struct Reserved {
        address to;
        uint256 at;
    }

}


interface ITransferReceiver is IReserved {
    function initialize(
        address _admin,
        address _config,
        address _converter,
        IRewardRouter _rewardRouter,
        address _stakedGlp,
        address _rewards
    ) external;
    function rewardRouter() external view returns (IRewardRouter);
    function stakedGlpTracker() external view returns (address);
    function weth() external view returns (address);
    function esGmx() external view returns (address);
    function stakedGlp() external view returns (address);
    function converter() external view returns (address);
    function rewards() external view returns (address);
    function transferSender() external view returns (address);
    function transferSenderReserved() external view returns (address to, uint256 at);
    function newTransferReceiverReserved() external view returns (address to, uint256 at);
    function accepted() external view returns (bool);
    function isForMpKey() external view returns (bool);
    function reserveTransferSender(address _transferSender, uint256 _at) external;
    function setTransferSender() external;
    function reserveNewTransferReceiver(address _newTransferReceiver, uint256 _at) external;
    function claimAndUpdateReward(address feeTo) external;
    function signalTransfer(address to) external;
    function acceptTransfer(address sender, bool _isForMpKey) external;
    function version() external view returns (uint256);
    event TransferAccepted(address indexed sender);
    event SignalTransfer(address indexed from, address indexed to);
    event TokenWithdrawn(address token, address to, uint256 balance);
    event TransferSenderReserved(address transferSender, uint256 at);
    event NewTransferReceiverReserved(address indexed to, uint256 at);
}


interface ITransferReceiverV2 is ITransferReceiver {
    function claimAndUpdateRewardFromTransferSender(address feeTo) external;
    function defaultTransferSender() external view returns (address);
}


interface ITransferSender {
    struct Lock {
        address account;
        uint256 startedAt;
    }

    struct Price {
        uint256 gmxKey;
        uint256 gmxKeyFee;
        uint256 esGmxKey;
        uint256 esGmxKeyFee;
        uint256 mpKey;
        uint256 mpKeyFee;
    }

    function gmx() external view returns (address);
    function esGmx() external view returns (address);
    function bnGmx() external view returns (address);
    function stakedGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function gmxVester() external view returns (address);
    function glpVester() external view returns (address);
    function GMXkey() external view returns (address);
    function esGMXkey() external view returns (address);
    function MPkey() external view returns (address);
    function converter() external view returns (address);
    function treasury() external view returns (address);
    function converterReserved() external view returns (address, uint256);
    function feeCalculator() external view returns (address);
    function feeCalculatorReserved() external view returns (address, uint256);
    function addressLock(address _receiver) external view returns (address, uint256);
    function addressPrice(address _receiver) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
    function unwrappedReceivers(uint256 index) external view returns (address);
    function unwrappedReceiverLength() external view returns (uint256);
    function isUnwrappedReceiver(address _receiver) external view returns (bool);
    function unwrappedAmount(address account, address token) external view returns (uint256);
    function setTreasury(address _treasury) external;
    function reserveConverter(address _converter, uint256 _at) external;
    function setConverter() external;
    function reserveFeeCalculator(address _feeCalculator, uint256 _at) external;
    function setFeeCalculator() external;
    function lock(address _receiver) external returns (Lock memory, Price memory);
    function unwrap(address _receiver) external;
    function changeAcceptableAccount(address _receiver, address account) external;
    function isUnlocked(address _receiver) external view returns (bool);


    event ConverterReserved(address to, uint256 at);
    event ConverterSet(address to, uint256 at);
    event FeeCalculatorReserved(address to, uint256 at);
    event FeeCalculatorSet(address to, uint256 at);
    event UnwrapLocked(address indexed account, address indexed receiver, Lock _lock, Price _price);
    event UnwrapCompleted(address indexed account, address indexed receiver, Price _price);
    event AcceptableAccountChanged(address indexed account, address indexed receiver, address indexed to);
}



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


abstract contract Adminable {
    address public admin;
    address public candidate;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event AdminCandidateRegistered(address indexed admin, address indexed candidate);

    constructor(address _admin) {
        require(_admin != address(0), "admin is the zero address");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return account == admin;
    }

    function registerAdminCandidate(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "new admin is the zero address");
        candidate = _newAdmin;
        emit AdminCandidateRegistered(admin, _newAdmin);
    }

    function confirmAdmin() external {
        require(msg.sender == candidate, "only candidate");
        emit AdminChanged(admin, candidate);
        admin = candidate;
        candidate = address(0);
    }
}

contract ConfigUser {
    address public immutable config;

    constructor(address _config) {
        require(_config != address(0), "ConfigUser: config is the zero address");
        config = _config;
    }
}



interface IConfig {
    function MIN_DELAY_TIME() external pure returns (uint256);
    function upgradeDelayTime() external view returns (uint256);
    function setUpgradeDelayTime(uint256 time) external;
    function getUpgradeableAt() external view returns (uint256);
}

interface IRewardTracker {
    function unstake(address _depositToken, uint256 _amount) external;
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function stakedAmounts(address account) external view returns (uint256);
    function depositBalances(address account, address depositToken) external view returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function glp() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function averageStakedAmounts(address account) external view returns (uint256);
    function cumulativeRewards(address account) external view returns (uint256);

}



interface ITransferSenderFeeCalculator {
    function calculateTransferSenderFee(
        address account,
        uint256 amount,
        address token
    ) external view returns (uint256);
}



interface IVester {
    function transferredAverageStakedAmounts(address account) external view returns (uint256);
    function transferredCumulativeRewards(address account) external view returns (uint256);
    function withdraw() external;
    function balanceOf(address account) external view returns (uint256);
}





contract TransferSender is ITransferSender, Adminable, ConfigUser, IReserved, ReentrancyGuard {

    // constant
    uint256 constant public LOCK_VALID_TIME = 5 minutes;

    // external contracts
    address public immutable gmx;
    address public immutable esGmx;
    address public immutable bnGmx;
    address public immutable stakedGmxTracker;
    address public immutable bonusGmxTracker;
    address public immutable feeGmxTracker;
    address public immutable stakedGlpTracker;
    address public immutable feeGlpTracker;
    address public immutable gmxVester;
    address public immutable glpVester;

    // key protocol contracts & addresses
    address public immutable GMXkey;
    address public immutable esGMXkey;
    address public immutable MPkey;
    address public converter;
    address public treasury;
    address public feeCalculator;
    Reserved public feeCalculatorReserved;
    Reserved public converterReserved;

    mapping(address => Lock) public addressLock;
    mapping(address => Price) public addressPrice;

    address[] public unwrappedReceivers;
    mapping(address => bool) public isUnwrappedReceiver;
    mapping(address => mapping(address => uint256)) public unwrappedAmount;
    mapping(address => address) public unwrappedReceiverToUnwrapper;

    constructor(
        address _admin,
        address _config,
        address _GMXkey,
        address _esGMXkey,
        address _MPkey,
        address _converter,
        address _treasury,
        address _feeCalculator,
        IRewardRouter _rewardRouter
    ) Adminable(_admin) ConfigUser(_config) {
        require(_GMXkey != address(0), "TransferSender: GMXkey is the zero address");
        require(_esGMXkey != address(0), "TransferSender: esGMXkey is the zero address");
        require(_MPkey != address(0), "TransferSender: MPkey is the zero address");
        require(_converter != address(0), "TransferSender: converter is the zero address");
        require(_treasury != address(0), "TransferSender: treasury is the zero address");
        require(_feeCalculator != address(0), "TransferSender: feeCalculator is the zero address");
        GMXkey = _GMXkey;
        esGMXkey = _esGMXkey;
        MPkey = _MPkey;
        converter = _converter;
        treasury = _treasury;
        feeCalculator = _feeCalculator;

        gmx = _rewardRouter.gmx();
        esGmx = _rewardRouter.esGmx();
        bnGmx = _rewardRouter.bnGmx();
        stakedGmxTracker = _rewardRouter.stakedGmxTracker();
        bonusGmxTracker = _rewardRouter.bonusGmxTracker();
        feeGmxTracker = _rewardRouter.feeGmxTracker();
        stakedGlpTracker = _rewardRouter.stakedGlpTracker();
        feeGlpTracker = _rewardRouter.feeGlpTracker();
        gmxVester = _rewardRouter.gmxVester();
        glpVester = _rewardRouter.glpVester();
        require(gmx != address(0), "TransferSender: gmx is the zero address");
        require(esGmx != address(0), "TransferSender: esGmx is the zero address");
        require(bnGmx != address(0), "TransferSender: bnGmx is the zero address");
        require(stakedGmxTracker != address(0), "TransferSender: stakedGmxTracker is the zero address");
        require(bonusGmxTracker != address(0), "TransferSender: bonusGmxTracker is the zero address");
        require(feeGmxTracker != address(0), "TransferSender: feeGmxTracker is the zero address");
        require(stakedGlpTracker != address(0), "TransferSender: stakedGlpTracker is the zero address");
        require(feeGlpTracker != address(0), "TransferSender: feeGlpTracker is the zero address");
        require(gmxVester != address(0), "TransferSender: gmxVester is the zero address");
        require(glpVester != address(0), "TransferSender: glpVester is the zero address");
    }

    // Sets treasury address
    function setTreasury(address _treasury) external onlyAdmin {
        require(_treasury != address(0), "TransferSender: treasury is the zero address");
        treasury = _treasury;
    }

    function reserveConverter(address _converter, uint256 _at) external onlyAdmin {
        require(_converter != address(0), "TransferSender: converter is the zero address");
        require(_at >= IConfig(config).getUpgradeableAt(), "TransferSender: at should be later");
        converterReserved = Reserved(_converter, _at);
        emit ConverterReserved(_converter, _at);
    }

    // Sets reserved converter contract.
    function setConverter() external onlyAdmin {
        require(converterReserved.at != 0 && converterReserved.at <= block.timestamp, "TransferSender: converter is not yet available");
        converter = converterReserved.to;
        emit ConverterSet(converter, converterReserved.at);
    }

    function reserveFeeCalculator(address _feeCalculator, uint256 _at) external onlyAdmin {
        require(_feeCalculator != address(0), "TransferSender: feeCalculator is the zero address");
        require(_at >= IConfig(config).getUpgradeableAt(), "TransferSender: at should be later");
        feeCalculatorReserved = Reserved(_feeCalculator, _at);
        emit FeeCalculatorReserved(_feeCalculator, _at);
    }

    // Sets reserved FeeCalculator contract.
    function setFeeCalculator() external onlyAdmin {
        require(feeCalculatorReserved.at != 0 && feeCalculatorReserved.at <= block.timestamp, "TransferSender: feeCalculator is not yet available");
        feeCalculator = feeCalculatorReserved.to;
        emit FeeCalculatorSet(feeCalculator, feeCalculatorReserved.at);
    }

    function lock(address _receiver) external nonReentrant returns (Lock memory, Price memory) {
        require(IConverter(converter).isValidReceiver(_receiver), "TransferSender: invalid receiver");
        require(ITransferReceiverV2(_receiver).version() >= 1, "TransferSender: invalid receiver version");
        require(!isUnwrappedReceiver[_receiver], "TransferSender: already unwrapped");
        require(_isUnlocked(addressLock[_receiver]), "TransferSender: already locked");

        _validateReceiver(msg.sender);

        Price memory _price = _claimRewardAndGetPrice(_receiver);

        // lock
        Lock memory _lock = Lock(msg.sender, block.timestamp);

        addressLock[_receiver] = _lock;
        addressPrice[_receiver] = _price;

        emit UnwrapLocked(msg.sender, _receiver, _lock, _price);

        return (_lock, _price);
    }

    function unwrap(address _receiver) external nonReentrant {
        // lock check
        Lock memory _lock = addressLock[_receiver];
        require(msg.sender == _lock.account, "TransferSender: invalid account");
        require(!isUnwrappedReceiver[_receiver], "TransferSender: already unwrapped");
        require(!_isUnlocked(_lock), "TransferSender: unlocked. Lock the receiver first");

        Price memory _price = addressPrice[_receiver];

        _settleFeeAndSignalTransfer(_receiver, _price);

        emit UnwrapCompleted(msg.sender, _receiver, _price);
    }

    function claimAndUnwrap(address _receiver) external nonReentrant {
        require(IConverter(converter).isValidReceiver(_receiver), "TransferSender: invalid receiver");
        require(ITransferReceiverV2(_receiver).version() >= 1, "TransferSender: invalid receiver version");
        require(!isUnwrappedReceiver[_receiver], "TransferSender: already unwrapped");

        _unlock(_receiver);

        Price memory _price = _claimRewardAndGetPrice(_receiver);

        _settleFeeAndSignalTransfer(_receiver, _price);

        emit UnwrapCompleted(msg.sender, _receiver, _price);
    }

    function changeAcceptableAccount(address _receiver, address account) external nonReentrant {
        require(msg.sender == unwrappedReceiverToUnwrapper[_receiver], "TransferSender: invalid account");
        require(isUnwrappedReceiver[_receiver], "TransferSender: not unwrapped");

        ITransferReceiverV2(_receiver).signalTransfer(account);

        emit AcceptableAccountChanged(msg.sender, _receiver, account);
    }

    function unwrappedReceiverLength() external view returns (uint256) {
        return unwrappedReceivers.length;
    }

    function isUnlocked(address _receiver) external view returns (bool) {
        Lock memory _lock = addressLock[_receiver];
        return _isUnlocked(_lock);
    }

    function _claimRewardAndGetPrice(address _receiver) private returns (Price memory _price) {
        // reward claim
        ITransferReceiverV2(_receiver).claimAndUpdateRewardFromTransferSender(treasury);

        // balance check
        uint256 gmxAmount = IRewardTracker(stakedGmxTracker).depositBalances(_receiver, gmx);
        uint256 esGmxAmount = IRewardTracker(stakedGmxTracker).depositBalances(_receiver, esGmx);
        uint256 mpAmount = IRewardTracker(feeGmxTracker).depositBalances(_receiver, bnGmx);

        // price
        uint256 _gmxKeyFee = ITransferSenderFeeCalculator(feeCalculator).calculateTransferSenderFee(msg.sender, gmxAmount, GMXkey);
        uint256 _esGmxKeyFee = ITransferSenderFeeCalculator(feeCalculator).calculateTransferSenderFee(msg.sender, esGmxAmount, esGMXkey);
        uint256 _mpKeyFee = ITransferSenderFeeCalculator(feeCalculator).calculateTransferSenderFee(msg.sender, mpAmount, MPkey);
        _price = Price(gmxAmount, _gmxKeyFee, esGmxAmount, _esGmxKeyFee, mpAmount, _mpKeyFee);
    }

    function _settleFeeAndSignalTransfer(address _receiver, Price memory _price) private {
        // burn & transfer token
        if (_price.gmxKey > 0) _burnAndTransferFee(treasury, GMXkey, _price.gmxKey, _price.gmxKeyFee);
        if (_price.esGmxKey > 0) _burnAndTransferFee(treasury, esGMXkey, _price.esGmxKey, _price.esGmxKeyFee);
        if (_price.mpKey > 0) _burnAndTransferFee(treasury, MPkey, _price.mpKey, _price.mpKeyFee);

        unwrappedAmount[msg.sender][GMXkey] = _price.gmxKey;
        unwrappedAmount[msg.sender][esGMXkey] = _price.esGmxKey;
        unwrappedAmount[msg.sender][MPkey] = _price.mpKey;

        // signal transfer
        ITransferReceiverV2(_receiver).signalTransfer(msg.sender);

        _addToUnwrappedReceivers(_receiver);
        unwrappedReceiverToUnwrapper[_receiver] = msg.sender;
    }

    function _unlock(address _receiver) private {
        Lock storage _lock = addressLock[_receiver];
        _lock.account = address(0);
        _lock.startedAt = 0;
    }

    function _burnAndTransferFee(address to, address _token, uint256 amount, uint256 fee) private {
        // These calls are safe, because _token is based on BaseToken contract.
        IERC20Burnable(_token).transferFrom(msg.sender, address(this), amount + fee);
        IERC20Burnable(_token).burn(amount);
        IERC20Burnable(_token).transfer(to, fee);
    }

    function _addToUnwrappedReceivers(address _receiver) private {
        unwrappedReceivers.push(_receiver);
        isUnwrappedReceiver[_receiver] = true;
    }

    function _isUnlocked(Lock memory _lock) private view returns (bool) {
        return _lock.startedAt + LOCK_VALID_TIME < block.timestamp;
    }

    // https://github.com/gmx-io/gmx-contracts/blob/6a6a7fd7c387d0b6b159e2a11d65a9e08bd2c099/contracts/staking/RewardRouterV2.sol#L346
    function _validateReceiver(address _receiver) private view {
        require(IRewardTracker(stakedGmxTracker).averageStakedAmounts(_receiver) == 0, "TransferSender: stakedGmxTracker.averageStakedAmounts > 0");
        require(IRewardTracker(stakedGmxTracker).cumulativeRewards(_receiver) == 0, "TransferSender: stakedGmxTracker.cumulativeRewards > 0");

        require(IRewardTracker(bonusGmxTracker).averageStakedAmounts(_receiver) == 0, "TransferSender: bonusGmxTracker.averageStakedAmounts > 0");
        require(IRewardTracker(bonusGmxTracker).cumulativeRewards(_receiver) == 0, "TransferSender: bonusGmxTracker.cumulativeRewards > 0");

        require(IRewardTracker(feeGmxTracker).averageStakedAmounts(_receiver) == 0, "TransferSender: feeGmxTracker.averageStakedAmounts > 0");
        require(IRewardTracker(feeGmxTracker).cumulativeRewards(_receiver) == 0, "TransferSender: feeGmxTracker.cumulativeRewards > 0");

        require(IVester(gmxVester).transferredAverageStakedAmounts(_receiver) == 0, "TransferSender: gmxVester.transferredAverageStakedAmounts > 0");
        require(IVester(gmxVester).transferredCumulativeRewards(_receiver) == 0, "TransferSender: gmxVester.transferredCumulativeRewards > 0");

        require(IRewardTracker(stakedGlpTracker).averageStakedAmounts(_receiver) == 0, "TransferSender: stakedGlpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(stakedGlpTracker).cumulativeRewards(_receiver) == 0, "TransferSender: stakedGlpTracker.cumulativeRewards > 0");

        require(IRewardTracker(feeGlpTracker).averageStakedAmounts(_receiver) == 0, "TransferSender: feeGlpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(feeGlpTracker).cumulativeRewards(_receiver) == 0, "TransferSender: feeGlpTracker.cumulativeRewards > 0");

        require(IVester(glpVester).transferredAverageStakedAmounts(_receiver) == 0, "TransferSender: glpVester.transferredAverageStakedAmounts > 0");
        require(IVester(glpVester).transferredCumulativeRewards(_receiver) == 0, "TransferSender: glpVester.transferredCumulativeRewards > 0");

        require(IERC20(gmxVester).balanceOf(_receiver) == 0, "TransferSender: gmxVester.balance > 0");
        require(IERC20(glpVester).balanceOf(_receiver) == 0, "TransferSender: glpVester.balance > 0");
    }
}