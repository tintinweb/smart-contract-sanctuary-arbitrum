// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import "./interfaces/IChainlinkLowLatencyOracleBase.sol";

abstract contract ChainlinkLowLatencyOracleBase is IChainlinkLowLatencyOracleBase, OwnableUpgradeable, AccessControlUpgradeable {

    bytes32 public constant EXECUTOR_ROLE = keccak256('EXECUTOR_ROLE');
    bytes32 public constant feedLabelStrHash = keccak256(abi.encodePacked("feedIDStr"));
    bytes32 public constant feedLabelHexHash = keccak256(abi.encodePacked("feedIDHex"));
    bytes32 public constant blockNumberQueryLabelHash = keccak256(abi.encodePacked("BlockNumber"));
    bytes32 public constant timestampQueryLabelHash = keccak256(abi.encodePacked("Timestamp"));

    OracleLookupData public oracleLookupData;
    IVerifierProxy public verifier;

    // modifier onlyValidLookupData(OracleLookupData calldata _oracleLookupData) {
    //     bytes32 oracleLookupFeedLabel = keccak256(abi.encodePacked(_oracleLookupData.feedLabel));
    //     bytes32 oracleLookhapQueryLabelHash = keccak256(abi.encodePacked(_oracleLookupData.queryLabel));

    //     require(oracleLookupFeedLabel == feedLabelStrHash || oracleLookupFeedLabel == feedLabelHexHash, "Invalid feed label");
    //     require(_oracleLookupData.feeds.length > 0, "Feeds array is empty");
    //     require(oracleLookhapQueryLabelHash == blockNumberQueryLabelHash || oracleLookhapQueryLabelHash == timestampQueryLabelHash, "Invalid query label");

    //     _;
    // }

    function __ChainlinkLowLatencyOracleBase_init(address _owner, OracleLookupData calldata _oracleLookupData, IVerifierProxy _verifier) internal onlyInitializing {
        OwnableUpgradeable.__Ownable_init();
        AccessControlUpgradeable.__AccessControl_init();

        _transferOwnership(_owner);
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);

        verifier = _verifier;
        oracleLookupData = OracleLookupData({
            feedLabel: _oracleLookupData.feedLabel,
            feeds: _oracleLookupData.feeds,
            queryLabel: _oracleLookupData.queryLabel
        });
    }

    function setVerifier(IVerifierProxy _verifier) external onlyOwner {
        verifier = _verifier;
    }

    function checkUpkeep(bytes calldata _data) external view returns (bool upkeepNeeded, bytes memory performData) {
        bytes4 eventType = bytes4(_data[:4]);
        bytes memory eventData = _data[4:];
        
        (bool isEventMatch, bytes memory processedData) = performEventMatch(eventType, eventData);

        uint256 queryValue;
        bytes32 oracleLookupQueryLabelHash = keccak256(abi.encodePacked(oracleLookupData.queryLabel));

        if(oracleLookupQueryLabelHash == blockNumberQueryLabelHash) {
            queryValue = block.number;
        }
        else {
            queryValue = block.timestamp;
        }

        if(isEventMatch) {
            revert OracleLookup(oracleLookupData.feedLabel, oracleLookupData.feeds, oracleLookupData.queryLabel, queryValue, processedData);
        }

        return (false, "");
    }

    function oracleCallback(bytes[] calldata _values, bytes calldata _extraData) external pure returns (bool upkeepNeeded, bytes memory performData) {
        performData = abi.encode(_values, _extraData);
        
        return (true, performData);
    }

    function performUpkeep(bytes calldata _performData) external onlyRole(EXECUTOR_ROLE) {
        (bytes[] memory chainlinkReports, bytes memory data) = abi.decode(_performData, (bytes[], bytes));

        bytes memory verifierResponse = verifier.verify(chainlinkReports[0]);

        execute(verifierResponse, chainlinkReports, data);
    }

    function performEventMatch(bytes4 eventType, bytes memory eventData) internal view virtual returns (bool, bytes memory);
    function execute(bytes memory verifierResponse, bytes[] memory chainlinkReports, bytes memory data) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IVerifierProxy {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier, and bills the user if applicable.
   * @param payload The encoded data to be verified, including the signed
   * report and any metadata for billing.
   * @return verifierResponse The encoded report from the verifier.
   */
  function verify(bytes calldata payload) external payable returns (bytes memory verifierResponse);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import "../external/IVerifierProxy.sol";

struct OracleLookupData {
    string feedLabel;
    string[] feeds;
    string queryLabel;
}

struct ReportsData {
    int256 cviValue;
    uint256 eventTimestamp;
}

interface IChainlinkLowLatencyOracleBase {
    error OracleLookup(string feedLabel, string[] feeds, string queryLabel, uint256 query, bytes data);

    function setVerifier(IVerifierProxy verifier) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface ICVIOracle {
    function getCVIRoundData(uint80 roundId) external view returns (uint32 cviValue, uint256 cviTimestamp);
    function getCVILatestRoundData() external view returns (uint32 cviValue, uint80 cviRoundId, uint256 cviTimestamp);
    function getTruncatedCVIValue(int256 cviOracleValue) external view returns (uint32);
    function getTruncatedMaxCVIValue() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IVolatilityTokenActionHandler.sol";

interface IHedgedThetaVaultActionHandler {
    function depositForOwner(address owner, uint168 tokenAmount, uint32 realTimeCVIValue, bool shouldStake) external returns (uint256 hedgedThetaTokensMinted);
    function withdrawForOwner(address owner, uint168 hedgedThetaTokenAmount, uint32 realTimeCVIValue) external returns (uint256 tokenWithdrawnAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IRequestFulfillerV3.sol";
import "./IRequestFulfillerV3ManagementConfig.sol";

enum OrderType {
    NONE,
    CVI_LIMIT,
    CVI_TP,
    CVI_SL,
    UCVI_LIMIT,
    UCVI_TP,
    UCVI_SL,
    REVERSE_LIMIT,
    REVERSE_TP,
    REVERSE_SL
}

interface ILimitOrderHandler {

    function createOrder(OrderType orderType, uint256 requestId, address requester, uint256 executionFee, uint32 triggerIndex, bytes memory eventData) external;
    function editOrder(uint256 requestId, uint32 triggerIndex, bytes memory eventData, address sender) external;
    function cancelOrder(uint256 requestId, address sender) external returns(address requester, uint256 executionFee);
    function removeExpiredOrder(uint256 requestId) external returns(address requester, uint256 executionFee);

    function getActiveOrders() external view returns(uint256[] memory ids);
    function checkOrders(int256 cviValue, uint256[] calldata idsToCheck) external view returns(bool[] memory isTriggerable);
    function checkAllOrders(int256 cviValue) external view returns(uint256[] memory triggerableIds);

    function triggerOrder(uint256 requestId, int256 cviValue) external returns(RequestType orderType, address requester, uint256 executionFee, bytes memory eventData);

    function setRequestFulfiller(address newRequestFulfiller) external;
    function setRequestFulfillerConfig(IRequestFulfillerV3ManagementConfig newRequestFulfillerConfig) external;
    function setOrderExpirationPeriod(uint32 newOrderExpirationPeriod) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IThetaVaultActionHandler.sol";

interface IMegaThetaVaultActionHandler {
    function depositForOwner(address owner, uint168 tokenAmount, uint32 realTimeCVIValue) external returns (uint256 megaThetaTokensMinted);
    function withdrawForOwner(address owner, uint168 thetaTokenAmount, uint32 realTimeCVIValue) external returns (uint256 tokenWithdrawnAmount);
    function thetaVault() external view returns (IThetaVaultActionHandler);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./ICVIOracle.sol";

interface IPlatformPositionHandler {
    function openPositionForOwner(address owner, bytes32 referralCode, uint168 tokenAmount, uint32 maxCVI, uint32 maxBuyingPremiumFeePercentage, uint8 leverage, uint32 realTimeCVIValue) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount, uint168 openPositionFee, uint168 buyingPremiumFee);
    function closePositionForOwner(address owner, uint168 positionUnitsAmount, uint32 minCVI, uint32 realTimeCVIValue) external returns (uint256 tokenAmount, uint256 closePositionFee, uint256 closingPremiumFee);
    function cviOracle() external view returns (ICVIOracle);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface IPlatformPositionRequester {
    function openCVIPlatformPosition(bytes32 referralCode, uint168 tokenAmount, uint32 maxCVI, uint32 maxBuyingPremiumFeePercentage, uint8 leverage) payable external; 
    function closeCVIPlatformPosition(uint168 positionUnitsAmount, uint32 minCVI) payable external;

    function openUCVIPlatformPosition(bytes32 referralCode, uint168 tokenAmount, uint32 maxCVI, uint32 maxBuyingPremiumFeePercentage, uint8 leverage) payable external; 
    function closeUCVIPlatformPosition(uint168 positionUnitsAmount, uint32 minCVI) payable external;

    function openReversePlatformPosition(bytes32 referralCode, uint168 tokenAmount, uint32 maxCVI, uint32 maxBuyingPremiumFeePercentage, uint8 leverage) payable external; 
    function closeReversePlatformPosition(uint168 positionUnitsAmount, uint32 minCVI) payable external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IRequestFulfillerV3ManagementConfig.sol";

enum RequestType {
    NONE,
    CVI_OPEN,
    CVI_CLOSE,
    UCVI_OPEN,
    UCVI_CLOSE,
    REVERSE_OPEN,
    REVERSE_CLOSE,
    CVI_MINT,
    CVI_BURN,
    UCVI_MINT,
    UCVI_BURN,
    HEDGED_DEPOSIT,
    HEDGED_WITHDRAW,
    MEGA_DEPOSIT,
    MEGA_WITHDRAW
}

interface IRequestFulfillerV3 {
    event RequestFulfillerV3ManagementConfigSet(address newRequestFulfillerConfig);

    function setRequestFulfillerV3ManagementConfig(IRequestFulfillerV3ManagementConfig newRequestFulfillerConfig) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IPlatformPositionHandler.sol";
import "./IVolatilityTokenActionHandler.sol";
import "./IVolatilityTokenActionHandler.sol";
import "./IHedgedThetaVaultActionHandler.sol";
import "./IMegaThetaVaultActionHandler.sol";
import "./ILimitOrderHandler.sol";

interface IRequestFulfillerV3ManagementConfig {

    function minOpenAmount() external view returns(uint168);
    function minCloseAmount() external view returns(uint168);

    function minMintAmount() external view returns(uint168);
    function minBurnAmount() external view returns(uint168);

    function minDepositAmount() external view returns(uint256);
    function minWithdrawAmount() external view returns(uint256);

    function platformCVI() external view returns(IPlatformPositionHandler);
    function platformUCVI() external view returns(IPlatformPositionHandler);
    function platformReverse() external view returns(IPlatformPositionHandler);

    function volTokenCVI() external view returns(IVolatilityTokenActionHandler);
    function volTokenUCVI() external view returns(IVolatilityTokenActionHandler);

    function hedgedVault() external view returns(IHedgedThetaVaultActionHandler);
    function megaVault() external view returns(IMegaThetaVaultActionHandler);

    function minCVIDiffAllowedPercentage() external view returns(uint32);

    function limitOrderHandler() external view returns(ILimitOrderHandler);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IPlatformPositionHandler.sol";

interface IThetaVaultActionHandler {
    function platform() external view returns (IPlatformPositionHandler);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface IThetaVaultRequester {
    function depositMegaThetaVault(uint168 tokenAmount) payable external;
    function withdrawMegaThetaVault(uint168 thetaTokenAmount) payable external;

    function depositHedgedThetaVault(uint168 tokenAmount, bool shouldStake) payable external;
    function withdrawHedgedThetaVault(uint168 hedgeTokenAmount) payable external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IPlatformPositionHandler.sol";

interface IVolatilityTokenActionHandler {
    function mintTokensForOwner(address owner, uint168 tokenAmount, uint32 maxBuyingPremiumFeePercentage, uint32 realTimeCVIValue) external returns (uint256 tokensMinted);
    function burnTokensForOwner(address owner,  uint168 burnAmount, uint32 realTimeCVIValue) external returns (uint256 tokensReceived);
    function platform() external view returns (IPlatformPositionHandler);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface IVolatilityTokenRequester {
    function mintCVIVolatilityToken(uint168 tokenAmount, uint32 maxBuyingPremiumFeePercentage) payable external;
    function burnCVIVolatilityToken(uint168 burnAmount) payable external;
    
    function mintUCVIVolatilityToken(uint168 tokenAmount, uint32 maxBuyingPremiumFeePercentage) payable external;
    function burnUCVIVolatilityToken(uint168 burnAmount) payable external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import "./ChainlinkLowLatencyOracleBase.sol";

abstract contract LowLatencyRequestFulfiller is ChainlinkLowLatencyOracleBase {
    struct RequestData {
        uint8 requestType;
        uint256 requestId;
        address requester;
        uint256 executionFee;
    }

    event ActionRequest(uint8 indexed requestType, uint256 indexed requestId, address indexed requester, uint256 executionFee, bytes eventData);
    event ActionSuccess(uint8 indexed requestType, uint256 indexed requestId, address indexed requester, uint256 executionFee);
    event ActionFailure(uint8 indexed requestType, uint256 indexed requestId, address indexed requester, uint256 refundedExecutionFee, string reason, bytes data);

    bytes4 public constant actionRequest = bytes4(keccak256("ActionRequest(uint8,uint256,address,uint256,bytes)"));

    uint256 public currentRequestId;
    mapping(uint256 => bool) public pendingRequests;
    uint256 public expirationPeriodSec;
    bool public catchErrors;

    uint256 public pendingExecutionFees;
    uint256 public requiredExecutionFee;

    function __LowLatencyRequestFulfiller_init(address _owner, OracleLookupData calldata _oracleLookupData, IVerifierProxy _verifier, uint256 _expirationPeriodSec) internal onlyInitializing {
        ChainlinkLowLatencyOracleBase.__ChainlinkLowLatencyOracleBase_init(_owner, _oracleLookupData, _verifier);

        expirationPeriodSec = _expirationPeriodSec;
        catchErrors = true;
        requiredExecutionFee = 1e14;
    }

    function setRequiredExecutionFee(uint256 _newRequiredExecutionFee) external onlyOwner {
        requiredExecutionFee = _newRequiredExecutionFee;
    }

    function setCatchErrors(bool _catchErrors) external onlyOwner {
        catchErrors = _catchErrors;
    }

    function setExpirationPeriodSec(uint256 _expirationPeriodSec) external onlyOwner {
        require(_expirationPeriodSec > 0, "expirationPeriodSec must be > 0");
        
        expirationPeriodSec = _expirationPeriodSec;
    }

    function getNextRequest() internal returns (uint256 requestId, address requester, uint256 executionFee) {
        require(msg.value == requiredExecutionFee, 'Execution Fee');

        pendingExecutionFees += msg.value;
        currentRequestId += 1;
        return (currentRequestId, msg.sender, msg.value);
    }

    function createActionRequest(uint8 _requestType, bytes memory _eventData) internal {
        (uint256 requestId, address requester, uint256 executionFee) = getNextRequest();
        pendingRequests[requestId] = true;
        emit ActionRequest(_requestType, requestId, requester, executionFee, _eventData);
    }

    function refundExecutionFee(address _requester, uint256 _executionFee) internal {
        if (_executionFee > 0) {
            pendingExecutionFees -= _executionFee;
            (bool sent,) = payable(_requester).call{value: _executionFee}("");
            require(sent, "Failed to send refund");
        }
    }

    function withdrawExecutionFees() external onlyRole(EXECUTOR_ROLE) {
        uint256 availableToWithdraw = address(this).balance - pendingExecutionFees;
        require(availableToWithdraw > 0, "Nothing to withdraw");
        (bool sent,) = payable(msg.sender).call{value: availableToWithdraw}("");
        require(sent, "Failed to withdraw");
    }

    function performEventMatch(bytes4 _eventType, bytes memory _eventData) internal view override returns (bool, bytes memory) {
        bool isEventMatch = false;
        if (_eventType == actionRequest) { 
            (uint8 requestType, uint256 requestId,,,) = abi.decode(_eventData, (uint8, uint256, address, uint256, bytes));
            if (requestType != 0) {
                isEventMatch = pendingRequests[requestId];
            }
        }

        return (isEventMatch, _eventData);
    }

    function execute(bytes memory _verifierResponse, bytes[] memory _chainlinkReports, bytes memory _data) internal override {
        ReportsData memory reportsData;

        reportsData.cviValue = abi.decode(_verifierResponse, (int256));
        reportsData.eventTimestamp = abi.decode(_chainlinkReports[1], (uint256));

        RequestData memory requestData;
        bytes memory requestDataEncoded;
        (requestData.requestType, requestData.requestId, requestData.requester, requestData.executionFee, requestDataEncoded) = abi.decode(_data, (uint8, uint256, address, uint256, bytes));
        require(pendingRequests[requestData.requestId], 'Request not pending');

        if (block.timestamp - reportsData.eventTimestamp >= expirationPeriodSec) {
            executionFailure(requestData, "RequestTimeout", "0x");
        } else {
            executeEvent(requestData, requestDataEncoded, reportsData.cviValue);
        }

        delete pendingRequests[requestData.requestId];
    }

    function executionSuccess(RequestData memory _requestData) internal {
        pendingExecutionFees -= _requestData.executionFee;
        emit ActionSuccess(_requestData.requestType, _requestData.requestId, _requestData.requester, _requestData.executionFee);
    }

    function executionFailure(RequestData memory _requestData, string memory reason, bytes memory lowLevelData) internal {
        refundExecutionFee(_requestData.requester, _requestData.executionFee);
        emit ActionFailure(_requestData.requestType, _requestData.requestId, _requestData.requester, _requestData.executionFee, reason, lowLevelData);
    }

    function executeEvent(RequestData memory _requestData, bytes memory _requestDataEncoded, int256 _cviValue) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import "./LowLatencyRequestFulfiller.sol";
import "./interfaces/IRequestFulfillerV3.sol";

import "./interfaces/IPlatformPositionRequester.sol";
import "./interfaces/IVolatilityTokenRequester.sol";
import "./interfaces/IThetaVaultRequester.sol";

contract RequestFulfillerV3 is LowLatencyRequestFulfiller, IRequestFulfillerV3, IPlatformPositionRequester, IVolatilityTokenRequester, IThetaVaultRequester {
    uint32 private constant MAX_PERCENTAGE = 1000000;

    uint168 private _minOpenAmount; // Obsolete
    uint168 private _minCloseAmount; // Obsolete

    uint168 private _minMintAmount; // Obsolete
    uint168 private _minBurnAmount; // Obsolete

    uint256 private _minDepositAmount; // Obsolete
    uint256 private _minWithdrawAmount; // Obsolete

    IPlatformPositionHandler private _platformCVI; // Obsolete
    IPlatformPositionHandler private _platformUCVI; // Obsolete
    IPlatformPositionHandler private _platformReverse; // Obsolete

    IVolatilityTokenActionHandler private _volTokenCVI; // Obsolete
    IVolatilityTokenActionHandler private _volTokenUCVI; // Obsolete

    IHedgedThetaVaultActionHandler private _hedgedVault; // Obsolete
    IMegaThetaVaultActionHandler private _megaVault; // Obsolete

    uint32 private _minCVIDiffAllowedPercentage; // Obsolete

    IRequestFulfillerV3ManagementConfig public config;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, OracleLookupData calldata _oracleLookupData, IVerifierProxy _verifier, uint256 _expirationPeriodSec) external initializer {
        LowLatencyRequestFulfiller.__LowLatencyRequestFulfiller_init(_owner, _oracleLookupData, _verifier, _expirationPeriodSec);
    }

    function setRequestFulfillerV3ManagementConfig(IRequestFulfillerV3ManagementConfig _config) external override onlyOwner {
        config = _config;

        emit RequestFulfillerV3ManagementConfigSet(address(_config));
    }

    function createOrder(OrderType _orderType, uint32 _triggerIndex, bytes memory _eventData) payable external {
        (uint256 requestId, address requester, uint256 executionFee) = getNextRequest();
        limitOrderHandler().createOrder(_orderType, requestId, requester, executionFee, _triggerIndex, _eventData);
    }

    function editOrder(uint256 _requestId, uint32 _triggerIndex, bytes memory _eventData) external {
        limitOrderHandler().editOrder(_requestId, _triggerIndex, _eventData, msg.sender);
    }

    function cancelOrder(uint256 _requestId) external {
        (address requester, uint256 executionFee) = limitOrderHandler().cancelOrder(_requestId, msg.sender);
        refundExecutionFee(requester, executionFee);
    }

    function removeExpiredOrders(uint256[] calldata _requestIds) external {
        for (uint256 i = 0; i < _requestIds.length; i++) {
            (address requester, uint256 executionFee) = limitOrderHandler().removeExpiredOrder(_requestIds[i]);
            refundExecutionFee(requester, executionFee);
        }
    }

    function triggerOrders(int256 _cviValue, uint256[] calldata _triggerableIds) external onlyRole(EXECUTOR_ROLE) {
        uint256 startGas = gasleft();

        for (uint256 i = 0; i < _triggerableIds.length; i++) {
            if(startGas - gasleft() > 4500000) {
                break;
            }

            (RequestType requestType, address requester, uint256 executionFee, bytes memory eventData) = limitOrderHandler().triggerOrder(_triggerableIds[i], _cviValue);
            pendingRequests[_triggerableIds[i]] = true;
            emit ActionRequest(uint8(requestType), _triggerableIds[i], requester, executionFee, eventData);
        }
    }

    function openCVIPlatformPosition(bytes32 _referralCode, uint168 _tokenAmount, uint32 _maxCVI, uint32 _maxBuyingPremiumFeePercentage, uint8 _leverage) payable external override { 
        require(address(platformCVI()) != address(0), 'CVI platform is unset');
        openPlatformPosition(RequestType.CVI_OPEN, _referralCode, _tokenAmount, _maxCVI, _maxBuyingPremiumFeePercentage, _leverage);
    }

    function closeCVIPlatformPosition(uint168 _positionUnitsAmount, uint32 _minCVI) payable external override {
        require(address(platformCVI()) != address(0), 'CVI platform is unset');
        closePlatformPosition(RequestType.CVI_CLOSE, _positionUnitsAmount, _minCVI);
    }

    function openUCVIPlatformPosition(bytes32 _referralCode, uint168 _tokenAmount, uint32 _maxCVI, uint32 _maxBuyingPremiumFeePercentage, uint8 _leverage) payable external override { 
        require(address(platformUCVI()) != address(0), 'UCVI platform is unset');
        openPlatformPosition(RequestType.UCVI_OPEN, _referralCode, _tokenAmount, _maxCVI, _maxBuyingPremiumFeePercentage, _leverage);
    }

    function closeUCVIPlatformPosition(uint168 _positionUnitsAmount, uint32 _minCVI) payable external override {
        require(address(platformUCVI()) != address(0), 'UCVI platform is unset');
        closePlatformPosition(RequestType.UCVI_CLOSE, _positionUnitsAmount, _minCVI);
    }

    function openReversePlatformPosition(bytes32 _referralCode, uint168 _tokenAmount, uint32 _maxCVI, uint32 _maxBuyingPremiumFeePercentage, uint8 _leverage) payable external override { 
        require(address(platformReverse()) != address(0), 'Reverse platform is unset');
        openPlatformPosition(RequestType.REVERSE_OPEN, _referralCode, _tokenAmount, _maxCVI, _maxBuyingPremiumFeePercentage, _leverage);
    }

    function closeReversePlatformPosition(uint168 _positionUnitsAmount, uint32 _minCVI) payable external override {
        require(address(platformReverse()) != address(0), 'Reverse platform is unset');
        closePlatformPosition(RequestType.REVERSE_CLOSE, _positionUnitsAmount, _minCVI);
    }
    
    function mintCVIVolatilityToken(uint168 _tokenAmount, uint32 _maxBuyingPremiumFeePercentage) payable external override {
        require(address(volTokenCVI()) != address(0), 'CVI Volatility Token is unset');
        mintVolatilityToken(RequestType.CVI_MINT, _tokenAmount, _maxBuyingPremiumFeePercentage);
    }

    function burnCVIVolatilityToken(uint168 _burnAmount) payable external override {
        require(address(volTokenCVI()) != address(0), 'CVI Volatility Token is unset');
        burnVolatilityToken(RequestType.CVI_BURN, _burnAmount);
    }

    function mintUCVIVolatilityToken(uint168 _tokenAmount, uint32 _maxBuyingPremiumFeePercentage) payable external override {
        require(address(volTokenUCVI()) != address(0), 'UCVI Volatility Token is unset');
        mintVolatilityToken(RequestType.UCVI_MINT, _tokenAmount, _maxBuyingPremiumFeePercentage);
    }

    function burnUCVIVolatilityToken(uint168 _burnAmount) payable external override {
        require(address(volTokenUCVI()) != address(0), 'UCVI Volatility Token is unset');
        burnVolatilityToken(RequestType.UCVI_BURN, _burnAmount);
    }

    function depositMegaThetaVault(uint168 _tokenAmount) payable external override {
        require(address(megaVault()) != address(0), 'Mega Vault is unset');
        require(_tokenAmount >= minDepositAmount(), 'Min Deposit');
        createActionRequest(uint8(RequestType.MEGA_DEPOSIT), abi.encode(_tokenAmount));
    }

    function withdrawMegaThetaVault(uint168 _thetaTokenAmount) payable external override {
        require(address(megaVault()) != address(0), 'Mega Vault is unset');
        require(_thetaTokenAmount >= minWithdrawAmount(), 'Min Withdraw');
        createActionRequest(uint8(RequestType.MEGA_WITHDRAW), abi.encode(_thetaTokenAmount));
    }

    function depositHedgedThetaVault(uint168 _tokenAmount, bool _shouldStake) payable external override {
        require(address(hedgedVault()) != address(0), 'Hedged Vault is unset');
        require(_tokenAmount >= minDepositAmount(), 'Min Deposit');
        createActionRequest(uint8(RequestType.HEDGED_DEPOSIT), abi.encode(_tokenAmount,_shouldStake));
    }

    function withdrawHedgedThetaVault(uint168 _hedgeTokenAmount) payable external override {
        require(address(hedgedVault()) != address(0), 'Hedged Vault is unset');
        require(_hedgeTokenAmount >= minWithdrawAmount(), 'Min Withdraw');
        createActionRequest(uint8(RequestType.HEDGED_WITHDRAW), abi.encode(_hedgeTokenAmount));
    }

    function openPlatformPosition(RequestType _requestType, bytes32 _referralCode, uint168 _tokenAmount, uint32 _maxCVI, uint32 _maxBuyingPremiumFeePercentage, uint8 _leverage) internal {
        require(_tokenAmount >= minOpenAmount(), 'Min Open');
        createActionRequest(uint8(_requestType), abi.encode(_referralCode, _tokenAmount, _maxCVI, _maxBuyingPremiumFeePercentage, _leverage));
    }

    function closePlatformPosition(RequestType _requestType, uint168 _positionUnitsAmount, uint32 _minCVI) internal {
        require(_positionUnitsAmount >= minCloseAmount(), 'Min Close');
        createActionRequest(uint8(_requestType), abi.encode(_positionUnitsAmount, _minCVI));
    }

    function mintVolatilityToken(RequestType _requestType, uint168 _tokenAmount, uint32 _maxBuyingPremiumFeePercentage) internal {
        require(_tokenAmount >= minMintAmount(), 'Min Mint');
        createActionRequest(uint8(_requestType), abi.encode(_tokenAmount, _maxBuyingPremiumFeePercentage));
    }

    function burnVolatilityToken(RequestType _requestType, uint168 _burnAmount) internal {
        require(_burnAmount >= minBurnAmount(), 'Min Burn');
        createActionRequest(uint8(_requestType), abi.encode(_burnAmount));
    }

    function executeEvent(RequestData memory _requestData, bytes memory _encodedEventData, int256 _cviValue) internal override {
        RequestType requestType = RequestType(_requestData.requestType);
        if (requestType == RequestType.CVI_OPEN) {
            executeOpenPosition(platformCVI(), _requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.CVI_CLOSE) {
            executeClosePosition(platformCVI(), _requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.UCVI_OPEN) {
            executeOpenPosition(platformUCVI(), _requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.UCVI_CLOSE) {
            executeClosePosition(platformUCVI(), _requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.REVERSE_OPEN) {
            executeOpenPosition(platformReverse(), _requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.REVERSE_CLOSE) {
            executeClosePosition(platformReverse(), _requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.CVI_MINT) {
            executeMint(volTokenCVI(), _requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.CVI_BURN) {
            executeBurn(volTokenCVI(), _requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.UCVI_MINT) {
            executeMint(volTokenUCVI(), _requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.UCVI_BURN) {
            executeBurn(volTokenUCVI(), _requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.MEGA_DEPOSIT) {
            executeMegaDeposit(_requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.MEGA_WITHDRAW) {
            executeMegaWithdraw(_requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.HEDGED_DEPOSIT) {
            executeHedgedDeposit(_requestData, _encodedEventData, _cviValue);
        } else if (requestType == RequestType.HEDGED_WITHDRAW) {
            executeHedgedWithdraw(_requestData, _encodedEventData, _cviValue);
        } else revert("Invalid request type");
    }

    function executeOpenPosition(IPlatformPositionHandler _platform, RequestData memory _requestData, bytes memory _encodedEventData, int256 _cviValue) internal {
        uint32 truncatedCVIValue = _platform.cviOracle().getTruncatedCVIValue(_cviValue);
        uint32 verifyDiffCVIValue = platformCVI().cviOracle().getTruncatedCVIValue(_cviValue);
        verifyCVIDiff(verifyDiffCVIValue);
        (
            bytes32 referralCode,
            uint168 tokenAmount,
            uint32 maxCVI,
            uint32 maxBuyingPremiumFeePercentage,
            uint8 leverage
        ) = abi.decode(_encodedEventData, (bytes32, uint168, uint32, uint32, uint8));

        if (catchErrors) {
            try _platform.openPositionForOwner(_requestData.requester, referralCode, tokenAmount, maxCVI, maxBuyingPremiumFeePercentage, leverage, truncatedCVIValue) {
                executionSuccess(_requestData);
            } catch Error(string memory reason) {
                executionFailure(_requestData, reason, "0x");
            } catch (bytes memory lowLevelData) {
                executionFailure(_requestData, 'Unknown', lowLevelData);
            }
        } else {
            _platform.openPositionForOwner(_requestData.requester, referralCode, tokenAmount, maxCVI, maxBuyingPremiumFeePercentage, leverage, truncatedCVIValue);
            executionSuccess(_requestData);
        }
    }

    function executeClosePosition(IPlatformPositionHandler _platform, RequestData memory _requestData, bytes memory _encodedEventData, int256 _cviValue) internal {
        uint32 truncatedCVIValue = _platform.cviOracle().getTruncatedCVIValue(_cviValue);
        uint32 verifyDiffCVIValue = platformCVI().cviOracle().getTruncatedCVIValue(_cviValue);
        verifyCVIDiff(verifyDiffCVIValue);
        (uint168 positionUnitsAmount, uint32 minCVI) = abi.decode(_encodedEventData, (uint168, uint32));

        if (catchErrors) {
            try _platform.closePositionForOwner(_requestData.requester, positionUnitsAmount, minCVI, truncatedCVIValue) {
                executionSuccess(_requestData);
            } catch Error(string memory reason) {
                executionFailure(_requestData, reason, "0x");
            } catch (bytes memory lowLevelData) {
                executionFailure(_requestData, 'Unknown', lowLevelData);
            }
        } else {
            _platform.closePositionForOwner(_requestData.requester, positionUnitsAmount, minCVI, truncatedCVIValue);
            executionSuccess(_requestData);
        }
    }

    function executeMint(IVolatilityTokenActionHandler _volToken, RequestData memory _requestData, bytes memory _encodedEventData, int256 _cviValue) internal {
        uint32 truncatedCVIValue = _volToken.platform().cviOracle().getTruncatedCVIValue(_cviValue);
        uint32 verifyDiffCVIValue = platformCVI().cviOracle().getTruncatedCVIValue(_cviValue);
        verifyCVIDiff(verifyDiffCVIValue);
        (uint168 tokenAmount, uint32 maxBuyingPremiumFeePercentage) = abi.decode(_encodedEventData, (uint168, uint32));

        if (catchErrors) {
            try _volToken.mintTokensForOwner(_requestData.requester, tokenAmount, maxBuyingPremiumFeePercentage, truncatedCVIValue) {
                executionSuccess(_requestData);
            }  catch Error(string memory reason) {
                executionFailure(_requestData, reason, "0x");
            } catch (bytes memory lowLevelData) {
                executionFailure(_requestData, 'Unknown', lowLevelData);
            }
        } else {
            _volToken.mintTokensForOwner(_requestData.requester, tokenAmount, maxBuyingPremiumFeePercentage, truncatedCVIValue);
            executionSuccess(_requestData);
        }
    }

    function executeBurn(IVolatilityTokenActionHandler _volToken, RequestData memory _requestData, bytes memory _encodedEventData, int256 _cviValue) internal {
        uint32 truncatedCVIValue = _volToken.platform().cviOracle().getTruncatedCVIValue(_cviValue);
        uint32 verifyDiffCVIValue = platformCVI().cviOracle().getTruncatedCVIValue(_cviValue);
        verifyCVIDiff(verifyDiffCVIValue);
        (uint168 burnAmount) = abi.decode(_encodedEventData, (uint168));

        if (catchErrors) {
            try _volToken.burnTokensForOwner(_requestData.requester, burnAmount, truncatedCVIValue) {
                executionSuccess(_requestData);
            }  catch Error(string memory reason) {
                executionFailure(_requestData, reason, "0x");
            } catch (bytes memory lowLevelData) {
                executionFailure(_requestData, 'Unknown', lowLevelData);
            }
        } else {
            _volToken.burnTokensForOwner(_requestData.requester, burnAmount, truncatedCVIValue);
            executionSuccess(_requestData);
        }
    }

    function executeMegaDeposit(RequestData memory _requestData, bytes memory _encodedEventData, int256 _cviValue) internal {
        uint32 truncatedCVIValue = platformCVI().cviOracle().getTruncatedCVIValue(_cviValue);
        verifyCVIDiff(truncatedCVIValue);
        (uint168 tokenAmount) = abi.decode(_encodedEventData, (uint168));

        if (catchErrors) {
            try megaVault().depositForOwner(_requestData.requester, tokenAmount, truncatedCVIValue) {
                executionSuccess(_requestData);
            } catch Error(string memory reason) {
                executionFailure(_requestData, reason, "0x");
            } catch (bytes memory lowLevelData) {
                executionFailure(_requestData, 'Unknown', lowLevelData);
            }
        } else {
            megaVault().depositForOwner(_requestData.requester, tokenAmount, truncatedCVIValue);
            executionSuccess(_requestData);
        }
    }

    function executeMegaWithdraw(RequestData memory _requestData, bytes memory _encodedEventData, int256 _cviValue) internal {
        uint32 truncatedCVIValue = platformCVI().cviOracle().getTruncatedCVIValue(_cviValue);
        verifyCVIDiff(truncatedCVIValue);
        (uint168 burnAmount) = abi.decode(_encodedEventData, (uint168));

        if (catchErrors) {
            try megaVault().withdrawForOwner(_requestData.requester, burnAmount, truncatedCVIValue) {
                executionSuccess(_requestData);
            } catch Error(string memory reason) {
                executionFailure(_requestData, reason, "0x");
            } catch (bytes memory lowLevelData) {
                executionFailure(_requestData, 'Unknown', lowLevelData);
            }
        } else {
            megaVault().withdrawForOwner(_requestData.requester, burnAmount, truncatedCVIValue);
            executionSuccess(_requestData);
        }
    }

    function executeHedgedDeposit(RequestData memory _requestData, bytes memory _encodedEventData, int256 _cviValue) internal {
        uint32 truncatedCVIValue = platformCVI().cviOracle().getTruncatedCVIValue(_cviValue);
        verifyCVIDiff(truncatedCVIValue);
        (uint168 tokenAmount, bool shouldStake) = abi.decode(_encodedEventData, (uint168, bool));

        if (catchErrors) {
            try hedgedVault().depositForOwner(_requestData.requester, tokenAmount, truncatedCVIValue, shouldStake) {
                executionSuccess(_requestData);
            } catch Error(string memory reason) {
                executionFailure(_requestData, reason, "0x");
            } catch (bytes memory lowLevelData) {
                executionFailure(_requestData, 'Unknown', lowLevelData);
            }
        } else {
            hedgedVault().depositForOwner(_requestData.requester, tokenAmount, truncatedCVIValue, shouldStake);
            executionSuccess(_requestData);
        }
    }

    function executeHedgedWithdraw(RequestData memory _requestData, bytes memory _encodedEventData, int256 _cviValue) internal {
        uint32 truncatedCVIValue = platformCVI().cviOracle().getTruncatedCVIValue(_cviValue);
        verifyCVIDiff(truncatedCVIValue);
        (uint168 burnAmount) = abi.decode(_encodedEventData, (uint168));

        if (catchErrors) {
            try hedgedVault().withdrawForOwner(_requestData.requester, burnAmount, truncatedCVIValue) {
                executionSuccess(_requestData);
            } catch Error(string memory reason) {
                executionFailure(_requestData, reason, "0x");
            } catch (bytes memory lowLevelData) {
                executionFailure(_requestData, 'Unknown', lowLevelData);
            }
        } else {
            hedgedVault().withdrawForOwner(_requestData.requester, burnAmount, truncatedCVIValue);
            executionSuccess(_requestData);
        }
    }

    function verifyCVIDiff(uint32 _realTimeCVIValue) private view {
        (uint32 cviOracle,,) = platformCVI().cviOracle().getCVILatestRoundData();
        uint256 cviDiff = cviOracle > _realTimeCVIValue ? cviOracle - _realTimeCVIValue : _realTimeCVIValue - cviOracle;
        require(cviDiff * MAX_PERCENTAGE / cviOracle <= minCVIDiffAllowedPercentage(), "CVI diff too big");
    }

    function platformCVI() internal view returns(IPlatformPositionHandler) {
        return config.platformCVI();
    }

    function platformUCVI() internal view returns(IPlatformPositionHandler) {
        return config.platformUCVI();
    }

    function platformReverse() internal view returns(IPlatformPositionHandler) {
        return config.platformReverse();
    }

    function volTokenCVI() internal view returns(IVolatilityTokenActionHandler) {
        return config.volTokenCVI();
    }

    function volTokenUCVI() internal view returns(IVolatilityTokenActionHandler) {
        return config.volTokenUCVI();
    }

    function hedgedVault() internal view returns(IHedgedThetaVaultActionHandler) {
        return config.hedgedVault();
    }

    function megaVault() internal view returns(IMegaThetaVaultActionHandler) {
        return config.megaVault();
    }

    function minOpenAmount() internal view returns(uint168) {
        return config.minOpenAmount();
    }

    function minCloseAmount() internal view returns(uint168) {
        return config.minCloseAmount();
    }

    function minMintAmount() internal view returns(uint168) {
        return config.minMintAmount();
    }

    function minBurnAmount() internal view returns(uint168) {
        return config.minBurnAmount();
    }

    function minDepositAmount() internal view returns(uint256) {
        return config.minDepositAmount();
    }

    function minWithdrawAmount() internal view returns(uint256) {
        return config.minWithdrawAmount();
    }

    function minCVIDiffAllowedPercentage() internal view returns(uint32) {
        return config.minCVIDiffAllowedPercentage();
    }

    function limitOrderHandler() internal view returns(ILimitOrderHandler) {
        return config.limitOrderHandler();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}