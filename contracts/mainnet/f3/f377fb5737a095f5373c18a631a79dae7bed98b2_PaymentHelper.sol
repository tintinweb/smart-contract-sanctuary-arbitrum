// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IPaymentHelper } from "src/interfaces/IPaymentHelper.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";
import { Error } from "src/libraries/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { ArrayCastLib } from "src/libraries/ArrayCastLib.sol";
import {
    SingleDirectSingleVaultStateReq,
    SingleXChainSingleVaultStateReq,
    SingleDirectMultiVaultStateReq,
    SingleXChainMultiVaultStateReq,
    MultiDstSingleVaultStateReq,
    MultiDstMultiVaultStateReq,
    LiqRequest,
    AMBMessage,
    MultiVaultSFData,
    SingleVaultSFData,
    AMBExtraData,
    InitMultiVaultData,
    InitSingleVaultData,
    ReturnMultiData,
    ReturnSingleData
} from "src/types/DataTypes.sol";
import { AggregatorV3Interface } from "src/vendor/chainlink/AggregatorV3Interface.sol";

/// @dev interface to read public variable from state registry
interface ReadOnlyBaseRegistry is IBaseStateRegistry {
    function payloadsCount() external view returns (uint256);
}

/// @title PaymentHelper
/// @dev Helps estimate the cost for the entire transaction lifecycle
/// @author ZeroPoint Labs
contract PaymentHelper is IPaymentHelper {
    using DataLib for uint256;
    using ArrayCastLib for LiqRequest;
    using ArrayCastLib for bool;
    using ProofLib for bytes;
    using ProofLib for AMBMessage;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    uint256 private constant PROOF_LENGTH = 160;
    uint8 private constant SUPPORTED_FEED_PRECISION = 8;
    uint32 private constant TIMELOCK_FORM_ID = 2;
    uint256 private constant MAX_UINT256 = type(uint256).max;

    ISuperRegistry public immutable superRegistry;
    uint64 public immutable CHAIN_ID;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev xchain params
    mapping(uint64 chainId => AggregatorV3Interface) public nativeFeedOracle;
    mapping(uint64 chainId => AggregatorV3Interface) public gasPriceOracle;
    mapping(uint64 chainId => uint256 gasForSwap) public swapGasUsed;
    mapping(uint64 chainId => uint256 gasForUpdateDeposit) public updateDepositGasUsed;
    mapping(uint64 chainId => uint256 gasForUpdateWithdraw) public updateWithdrawGasUsed;
    mapping(uint64 chainId => uint256 gasForDeposit) public depositGasUsed;
    mapping(uint64 chainId => uint256 gasForWithdraw) public withdrawGasUsed;
    mapping(uint64 chainId => uint256 defaultNativePrice) public nativePrice;
    mapping(uint64 chainId => uint256 defaultGasPrice) public gasPrice;
    mapping(uint64 chainId => uint256 gasPerByte) public gasPerByte;
    mapping(uint64 chainId => uint256 gasForAck) public ackGasCost;
    mapping(uint64 chainId => uint256 gasForTimelock) public timelockCost;
    mapping(uint64 chainId => uint256 gasForEmergency) public emergencyCost;

    /// @dev register transmuter params
    bytes public extraDataForTransmuter;

    //////////////////////////////////////////////////////////////
    //                           STRUCTS                        //
    //////////////////////////////////////////////////////////////

    struct EstimateAckCostVars {
        uint256 currPayloadId;
        uint256 payloadHeader;
        uint8 callbackType;
        bytes payloadBody;
        uint8[] ackAmbIds;
        uint8 isMulti;
        uint64 srcChainId;
        bytes message;
    }

    struct LocalEstimateVars {
        uint256 len;
        uint256 superformIdsLen;
        uint256 totalGas;
        uint256 ambFees;
        bool paused;
    }

    struct CalculateAmountsReq {
        uint256 i;
        uint64[] dstChainIds;
        uint8[] ambIds;
        MultiVaultSFData[] superformsData;
        SingleVaultSFData[] superformData;
        ISuperformFactory factory;
        bool isDeposit;
    }

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(_getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    modifier onlyPaymentAdmin() {
        if (
            !ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(
                keccak256("PAYMENT_ADMIN_ROLE"), msg.sender
            )
        ) {
            revert Error.NOT_PAYMENT_ADMIN();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) {
        if (superRegistry_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);
        superRegistry = ISuperRegistry(superRegistry_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IPaymentHelper
    function calculateAMBData(
        uint64 dstChainId_,
        uint8[] calldata ambIds_,
        bytes memory message_
    )
        external
        view
        override
        returns (uint256 totalFees, bytes memory extraData)
    {
        (uint256[] memory gasPerAMB, bytes[] memory extraDataPerAMB, uint256 fees) =
            _estimateAMBFeesReturnExtraData(dstChainId_, ambIds_, message_);

        extraData = abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB));
        totalFees = fees;
    }

    /// @inheritdoc IPaymentHelper
    function getRegisterTransmuterAMBData() external view override returns (bytes memory) {
        return extraDataForTransmuter;
    }

    /// @inheritdoc IPaymentHelper
    function estimateMultiDstMultiVault(
        MultiDstMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 len = req_.dstChainIds.length;
        uint256 liqAmountIndex;
        uint256 srcAmountIndex;
        uint256 dstAmountIndex;

        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));
        SingleVaultSFData[] memory temp;

        for (uint256 i; i < len; ++i) {
            (liqAmountIndex, srcAmountIndex, dstAmountIndex) = _calculateAmounts(
                CalculateAmountsReq(i, req_.dstChainIds, req_.ambIds[i], req_.superformsData, temp, factory, isDeposit_)
            );
            liqAmount += liqAmountIndex;
            srcAmount += srcAmountIndex;
            dstAmount += dstAmountIndex;
        }

        totalAmount = srcAmount + dstAmount + liqAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateMultiDstSingleVault(
        MultiDstSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 len = req_.dstChainIds.length;
        uint256 liqAmountIndex;
        uint256 srcAmountIndex;
        uint256 dstAmountIndex;
        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));
        MultiVaultSFData[] memory temp;
        for (uint256 i; i < len; ++i) {
            (liqAmountIndex, srcAmountIndex, dstAmountIndex) = _calculateAmounts(
                CalculateAmountsReq(i, req_.dstChainIds, req_.ambIds[i], temp, req_.superformsData, factory, isDeposit_)
            );
            liqAmount += liqAmountIndex;
            srcAmount += srcAmountIndex;
            dstAmount += dstAmountIndex;
        }

        totalAmount = srcAmount + dstAmount + liqAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleXChainMultiVault(
        SingleXChainMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));

        uint64[] memory dstChainIds = new uint64[](1);
        dstChainIds[0] = req_.dstChainId;

        SingleVaultSFData[] memory temp;

        MultiVaultSFData[] memory sfData = new MultiVaultSFData[](1);
        sfData[0] = req_.superformsData;

        (liqAmount, srcAmount, dstAmount) =
            _calculateAmounts(CalculateAmountsReq(0, dstChainIds, req_.ambIds, sfData, temp, factory, isDeposit_));

        totalAmount = srcAmount + dstAmount + liqAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleXChainSingleVault(
        SingleXChainSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));

        uint64[] memory dstChainIds = new uint64[](1);
        dstChainIds[0] = req_.dstChainId;

        MultiVaultSFData[] memory temp;

        SingleVaultSFData[] memory sfData = new SingleVaultSFData[](1);
        sfData[0] = req_.superformData;

        (liqAmount, srcAmount, dstAmount) =
            _calculateAmounts(CalculateAmountsReq(0, dstChainIds, req_.ambIds, temp, sfData, factory, isDeposit_));

        totalAmount = srcAmount + dstAmount + liqAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleDirectSingleVault(
        SingleDirectSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 dstOrSameChainAmt, uint256 totalAmount)
    {
        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));

        uint64[] memory dstChainIds = new uint64[](1);
        dstChainIds[0] = CHAIN_ID;

        SingleVaultSFData[] memory sfData = new SingleVaultSFData[](1);
        sfData[0] = req_.superformData;

        MultiVaultSFData[] memory temp;

        uint8[] memory ambIds;

        (liqAmount,, dstOrSameChainAmt) =
            _calculateAmounts(CalculateAmountsReq(0, dstChainIds, ambIds, temp, sfData, factory, isDeposit_));

        totalAmount = liqAmount + dstOrSameChainAmt;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleDirectMultiVault(
        SingleDirectMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 dstOrSameChainAmt, uint256 totalAmount)
    {
        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));

        uint64[] memory dstChainIds = new uint64[](1);
        dstChainIds[0] = CHAIN_ID;

        SingleVaultSFData[] memory temp;

        MultiVaultSFData[] memory sfData = new MultiVaultSFData[](1);
        sfData[0] = req_.superformData;

        uint8[] memory ambIds;

        (liqAmount,, dstOrSameChainAmt) =
            _calculateAmounts(CalculateAmountsReq(0, dstChainIds, ambIds, sfData, temp, factory, isDeposit_));

        totalAmount = liqAmount + dstOrSameChainAmt;
    }

    /// @inheritdoc IPaymentHelper
    function estimateAMBFees(
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes[] memory extraData_
    )
        public
        view
        override
        returns (uint256 totalFees, uint256[] memory)
    {
        uint256 len = ambIds_.length;
        uint256[] memory fees = new uint256[](len);

        /// @dev just checks the estimate for sending message from src -> dst
        if (CHAIN_ID != dstChainId_) {
            for (uint256 i; i < len; ++i) {
                fees[i] = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                    dstChainId_, message_, extraData_[i]
                );

                totalFees += fees[i];
            }
        }

        return (totalFees, fees);
    }

    /// @inheritdoc IPaymentHelper
    function estimateAckCost(uint256 payloadId_) external view override returns (uint256 totalFees) {
        EstimateAckCostVars memory v;
        IBaseStateRegistry coreStateRegistry = IBaseStateRegistry(_getAddress(keccak256("CORE_STATE_REGISTRY")));
        v.currPayloadId = coreStateRegistry.payloadsCount();

        if (payloadId_ > v.currPayloadId) revert Error.INVALID_PAYLOAD_ID();

        v.payloadHeader = coreStateRegistry.payloadHeader(payloadId_);
        v.payloadBody = coreStateRegistry.payloadBody(payloadId_);

        (, v.callbackType, v.isMulti,,, v.srcChainId) = DataLib.decodeTxInfo(v.payloadHeader);

        /// if callback type is return then return 0
        if (v.callbackType != 0) return 0;

        if (v.isMulti == 1) {
            InitMultiVaultData memory data = abi.decode(v.payloadBody, (InitMultiVaultData));
            v.payloadBody = abi.encode(ReturnMultiData(v.currPayloadId, data.superformIds, data.amounts));
        } else {
            InitSingleVaultData memory data = abi.decode(v.payloadBody, (InitSingleVaultData));
            v.payloadBody = abi.encode(ReturnSingleData(v.currPayloadId, data.superformId, data.amount));
        }

        v.ackAmbIds = coreStateRegistry.getMessageAMB(payloadId_);

        v.message = abi.encode(AMBMessage(coreStateRegistry.payloadHeader(payloadId_), v.payloadBody));

        return _estimateAMBFees(v.ackAmbIds, v.srcChainId, v.message);
    }

    /// @inheritdoc IPaymentHelper
    function estimateAckCostDefault(
        bool multi,
        uint8[] memory ackAmbIds,
        uint64 srcChainId
    )
        public
        view
        override
        returns (uint256 totalFees)
    {
        bytes memory payloadBody;
        if (multi) {
            uint256 vaultLimitPerDst = superRegistry.getVaultLimitPerDestination(srcChainId);
            uint256[] memory maxUints = new uint256[](vaultLimitPerDst);

            for (uint256 i; i < vaultLimitPerDst; ++i) {
                maxUints[i] = type(uint256).max;
            }
            payloadBody = abi.encode(ReturnMultiData(type(uint256).max, maxUints, maxUints));
        } else {
            payloadBody = abi.encode(ReturnSingleData(type(uint256).max, type(uint256).max, type(uint256).max));
        }

        return _estimateAMBFees(ackAmbIds, srcChainId, abi.encode(AMBMessage(type(uint256).max, payloadBody)));
    }

    /// @inheritdoc IPaymentHelper
    function estimateAckCostDefaultNativeSource(
        bool multi,
        uint8[] memory ackAmbIds,
        uint64 srcChainId
    )
        external
        view
        override
        returns (uint256)
    {
        return _convertToSrcNativeAmount(srcChainId, estimateAckCostDefault(multi, ackAmbIds, srcChainId));
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IPaymentHelper
    function addRemoteChain(uint64 chainId_, PaymentHelperConfig calldata config_) public override onlyProtocolAdmin {
        _addRemoteChain(chainId_, config_);
    }

    /// @inheritdoc IPaymentHelper
    function addRemoteChains(
        uint64[] calldata chainIds_,
        PaymentHelperConfig[] calldata configs_
    )
        external
        override
        onlyProtocolAdmin
    {
        uint256 len = chainIds_.length;

        if (len == 0) revert Error.ZERO_INPUT_VALUE();

        if (len != configs_.length) revert Error.ARRAY_LENGTH_MISMATCH();

        for (uint256 i; i < len; ++i) {
            _addRemoteChain(chainIds_[i], configs_[i]);
        }
    }

    /// @inheritdoc IPaymentHelper
    function updateRemoteChain(
        uint64 chainId_,
        uint256 configType_,
        bytes memory config_
    )
        external
        override
        onlyPaymentAdmin
    {
        _updateRemoteChain(chainId_, configType_, config_);
    }

    /// @inheritdoc IPaymentHelper
    function batchUpdateRemoteChain(
        uint64 chainId_,
        uint256[] calldata configTypes_,
        bytes[] calldata configs_
    )
        external
        override
        onlyPaymentAdmin
    {
        _batchUpdateRemoteChain(chainId_, configTypes_, configs_);
    }

    /// @inheritdoc IPaymentHelper
    function batchUpdateRemoteChains(
        uint64[] calldata chainIds_,
        uint256[][] calldata configTypes_,
        bytes[][] calldata configs_
    )
        external
        override
        onlyPaymentAdmin
    {
        uint256 len = chainIds_.length;

        if (len == 0) revert Error.ZERO_INPUT_VALUE();

        if (!(len == configTypes_.length && len == configs_.length)) revert Error.ARRAY_LENGTH_MISMATCH();

        for (uint256 i; i < len; ++i) {
            _batchUpdateRemoteChain(chainIds_[i], configTypes_[i], configs_[i]);
        }
    }

    /// @inheritdoc IPaymentHelper
    function updateRegisterAERC20Params(bytes memory extraDataForTransmuter_) external onlyPaymentAdmin {
        extraDataForTransmuter = extraDataForTransmuter_;
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    function _getOracleDecimals(AggregatorV3Interface oracle_) internal view returns (uint8) {
        return oracle_.decimals();
    }

    /// @dev PROTOCOL_ADMIN can perform the configuration of a remote chain for the first time
    function _addRemoteChain(uint64 chainId_, PaymentHelperConfig calldata config_) internal {
        if (config_.nativeFeedOracle != address(0)) {
            AggregatorV3Interface nativeFeedOracleContract = AggregatorV3Interface(config_.nativeFeedOracle);
            if (_getOracleDecimals(nativeFeedOracleContract) != SUPPORTED_FEED_PRECISION) {
                revert Error.CHAINLINK_UNSUPPORTED_DECIMAL();
            }

            nativeFeedOracle[chainId_] = nativeFeedOracleContract;
        }

        if (config_.gasPriceOracle != address(0)) {
            AggregatorV3Interface gasPriceOracleContract = AggregatorV3Interface(config_.gasPriceOracle);
            if (_getOracleDecimals(gasPriceOracleContract) != SUPPORTED_FEED_PRECISION) {
                revert Error.CHAINLINK_UNSUPPORTED_DECIMAL();
            }

            gasPriceOracle[chainId_] = gasPriceOracleContract;
        }

        swapGasUsed[chainId_] = config_.swapGasUsed;
        updateDepositGasUsed[chainId_] = config_.updateDepositGasUsed;
        depositGasUsed[chainId_] = config_.depositGasUsed;
        withdrawGasUsed[chainId_] = config_.withdrawGasUsed;
        nativePrice[chainId_] = config_.defaultNativePrice;
        gasPrice[chainId_] = config_.defaultGasPrice;
        gasPerByte[chainId_] = config_.dstGasPerByte;
        ackGasCost[chainId_] = config_.ackGasCost;
        timelockCost[chainId_] = config_.timelockCost;
        emergencyCost[chainId_] = config_.emergencyCost;
        updateWithdrawGasUsed[chainId_] = config_.updateWithdrawGasUsed;

        emit ChainConfigAdded(chainId_, config_);
    }

    /// @dev PAYMENT_ADMIN can update the configuration of a remote chain on a need basis
    function _updateRemoteChain(uint64 chainId_, uint256 configType_, bytes memory config_) internal {
        /// @dev Type 1: DST TOKEN PRICE FEED ORACLE
        if (configType_ == 1) {
            AggregatorV3Interface nativeFeedOracleContract = AggregatorV3Interface(abi.decode(config_, (address)));

            /// @dev allows setting price feed to address(0), equivalent for resetting native price
            if (
                address(nativeFeedOracleContract) != address(0)
                    && _getOracleDecimals(nativeFeedOracleContract) != SUPPORTED_FEED_PRECISION
            ) {
                revert Error.CHAINLINK_UNSUPPORTED_DECIMAL();
            }

            nativeFeedOracle[chainId_] = nativeFeedOracleContract;
        }

        /// @dev Type 2: DST GAS PRICE ORACLE
        if (configType_ == 2) {
            AggregatorV3Interface gasPriceOracleContract = AggregatorV3Interface(abi.decode(config_, (address)));

            /// @dev allows setting gas price to address(0), equivalent for resetting gas price
            if (
                address(gasPriceOracleContract) != address(0)
                    && _getOracleDecimals(gasPriceOracleContract) != SUPPORTED_FEED_PRECISION
            ) {
                revert Error.CHAINLINK_UNSUPPORTED_DECIMAL();
            }

            gasPriceOracle[chainId_] = gasPriceOracleContract;
        }

        /// @dev Type 3: SWAP GAS USED
        if (configType_ == 3) {
            swapGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 4: PAYLOAD UPDATE DEPOSIT GAS COST PER TX
        if (configType_ == 4) {
            updateDepositGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 5: DEPOSIT GAS COST PER TX
        if (configType_ == 5) {
            depositGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 6: WITHDRAW GAS COST PER TX
        if (configType_ == 6) {
            withdrawGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 7: DEFAULT NATIVE PRICE
        if (configType_ == 7) {
            nativePrice[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 8: DEFAULT GAS PRICE
        if (configType_ == 8) {
            gasPrice[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 9: GAS PRICE PER Byte of Message
        if (configType_ == 9) {
            gasPerByte[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 10: ACK GAS COST
        if (configType_ == 10) {
            ackGasCost[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 11: TIMELOCK PROCESSING COST
        if (configType_ == 11) {
            timelockCost[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 12: EMERGENCY PROCESSING COST
        if (configType_ == 12) {
            emergencyCost[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 13: PAYLOAD UPDATE WITHDRAW GAS COST PER TX
        if (configType_ == 13) {
            updateWithdrawGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        emit ChainConfigUpdated(chainId_, configType_, config_);
    }

    /// @dev batch updates the configuration of a remote chain. Performed by PAYMENT_ADMIN
    function _batchUpdateRemoteChain(
        uint64 chainId_,
        uint256[] calldata configTypes_,
        bytes[] calldata configs_
    )
        internal
    {
        uint256 len = configTypes_.length;

        if (len == 0) revert Error.ZERO_INPUT_VALUE();

        if (len != configs_.length) revert Error.ARRAY_LENGTH_MISMATCH();

        for (uint256 i; i < len; ++i) {
            _updateRemoteChain(chainId_, configTypes_[i], configs_[i]);
        }
    }

    /// @dev helps generate extra data per amb
    function _generateExtraData(
        uint64 dstChainId_,
        uint8[] memory ambIds_,
        bytes memory message_
    )
        internal
        view
        returns (bytes[] memory extraDataPerAMB)
    {
        AMBMessage memory ambIdEncodedMessage = abi.decode(message_, (AMBMessage));
        ambIdEncodedMessage.params = abi.encode(ambIds_, ambIdEncodedMessage.params);

        uint256 len = ambIds_.length;
        uint256 gasReqPerByte = gasPerByte[dstChainId_];
        uint256 totalDstGasReqInWei = abi.encode(ambIdEncodedMessage).length * gasReqPerByte;

        /// @dev proof length is always of fixed length
        uint256 totalDstGasReqInWeiForProof = PROOF_LENGTH * gasReqPerByte;

        extraDataPerAMB = new bytes[](len);

        for (uint256 i; i < len; ++i) {
            uint256 gasReq = i != 0 ? totalDstGasReqInWeiForProof : totalDstGasReqInWei;
            extraDataPerAMB[i] = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).generateExtraData(gasReq);
        }
    }

    /// @dev helps estimate the cross-chain message costs
    function _estimateAMBFees(
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_
    )
        internal
        view
        returns (uint256 totalFees)
    {
        uint256 len = ambIds_.length;

        bytes[] memory extraDataPerAMB = _generateExtraData(dstChainId_, ambIds_, message_);

        AMBMessage memory ambIdEncodedMessage = abi.decode(message_, (AMBMessage));
        ambIdEncodedMessage.params = abi.encode(ambIds_, ambIdEncodedMessage.params);

        bytes memory proof_ = abi.encode(AMBMessage(MAX_UINT256, abi.encode(keccak256(message_))));

        /// @dev just checks the estimate for sending message from src -> dst
        /// @dev only ambIds_[0] = primary amb (rest of the ambs send only the proof)
        if (CHAIN_ID != dstChainId_) {
            for (uint256 i; i < len; ++i) {
                uint256 tempFee = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                    dstChainId_, i != 0 ? proof_ : abi.encode(ambIdEncodedMessage), extraDataPerAMB[i]
                );

                totalFees += tempFee;
            }
        }
    }

    /// @dev helps estimate the cross-chain message costs
    function _estimateAMBFeesReturnExtraData(
        uint64 dstChainId_,
        uint8[] calldata ambIds_,
        bytes memory message_
    )
        internal
        view
        returns (uint256[] memory feeSplitUp, bytes[] memory extraDataPerAMB, uint256 totalFees)
    {
        AMBMessage memory ambIdEncodedMessage = abi.decode(message_, (AMBMessage));
        ambIdEncodedMessage.params = abi.encode(ambIds_, ambIdEncodedMessage.params);

        uint256 len = ambIds_.length;

        extraDataPerAMB = _generateExtraData(dstChainId_, ambIds_, message_);

        feeSplitUp = new uint256[](len);

        bytes memory proof_ = abi.encode(AMBMessage(MAX_UINT256, abi.encode(keccak256(message_))));

        /// @dev just checks the estimate for sending message from src -> dst
        if (CHAIN_ID != dstChainId_) {
            for (uint256 i; i < len; ++i) {
                uint256 tempFee = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                    dstChainId_, i != 0 ? proof_ : abi.encode(ambIdEncodedMessage), extraDataPerAMB[i]
                );

                totalFees += tempFee;
                feeSplitUp[i] = tempFee;
            }
        }
    }

    /// @dev helps estimate the liq amount involved in the tx
    function _estimateLiqAmount(LiqRequest[] memory req_) internal pure returns (uint256 liqAmount) {
        uint256 len = req_.length;
        for (uint256 i; i < len; ++i) {
            liqAmount += req_[i].nativeAmount;
        }
    }

    /// @dev helps estimate the dst chain swap gas limit (if multi-tx is involved)
    function _estimateSwapFees(
        uint64 dstChainId_,
        bool[] memory hasDstSwaps_
    )
        internal
        view
        returns (uint256 gasUsed)
    {
        uint256 totalSwaps;

        if (CHAIN_ID == dstChainId_) {
            return 0;
        }

        uint256 len = hasDstSwaps_.length;
        for (uint256 i; i < len; ++i) {
            /// @dev checks if hasDstSwap is true
            if (hasDstSwaps_[i]) {
                ++totalSwaps;
            }
        }

        if (totalSwaps == 0) {
            return 0;
        }

        return totalSwaps * swapGasUsed[dstChainId_];
    }

    /// @dev helps estimate the dst chain update payload gas limit
    function _estimateUpdateDepositCost(
        uint64 dstChainId_,
        uint256 vaultsCount_
    )
        internal
        view
        returns (uint256 gasUsed)
    {
        return vaultsCount_ * updateDepositGasUsed[dstChainId_];
    }

    /// @dev helps estimate the dst chain update payload gas limit
    function _estimateUpdateWithdrawCost(
        uint64 dstChainId_,
        LiqRequest[] memory liqRequests_
    )
        internal
        view
        returns (uint256 gasUsed)
    {
        uint256 len = liqRequests_.length;
        for (uint256 i; i < len; i++) {
            /// @dev liqRequests[i].token on withdraws is the desired token
            /// @dev if token is address(0) -> user wants settlement without any liq data
            /// @dev this means that if no txData is present and token is different than address(0) an update is
            /// required in destination
            if (liqRequests_[i].txData.length == 0 && liqRequests_[i].token != address(0)) {
                gasUsed += updateWithdrawGasUsed[dstChainId_];
            }
        }
    }

    /// @dev helps estimate the dst chain processing cost including the dst->src message cost
    /// @dev assumes that withdrawals optimisically succeed
    function _estimateDstExecutionCost(
        bool isDeposit_,
        uint64 dstChainId_,
        uint256 vaultsCount_
    )
        internal
        view
        returns (uint256 gasUsed)
    {
        uint256 executionGasPerVault = isDeposit_ ? depositGasUsed[dstChainId_] : withdrawGasUsed[dstChainId_];
        gasUsed = executionGasPerVault * vaultsCount_;
    }

    /// @dev helps estimate the src chain processing fee
    function _estimateAckProcessingCost(uint256 vaultsCount_) internal view returns (uint256 nativeFee) {
        uint256 gasCost = vaultsCount_ * ackGasCost[CHAIN_ID];

        return gasCost * _getGasPrice(CHAIN_ID);
    }

    /// @dev generates the amb message for single vault data
    function _generateSingleVaultMessage(SingleVaultSFData memory sfData_)
        internal
        view
        returns (bytes memory message_)
    {
        bytes memory ambData = abi.encode(
            InitSingleVaultData(
                _getNextPayloadId(),
                sfData_.superformId,
                sfData_.amount,
                sfData_.outputAmount,
                sfData_.maxSlippage,
                sfData_.liqRequest,
                sfData_.hasDstSwap,
                sfData_.retain4626,
                sfData_.receiverAddress,
                sfData_.extraFormData
            )
        );
        message_ = abi.encode(AMBMessage(MAX_UINT256, ambData));
    }

    /// @dev generates the amb message for multi vault data
    function _generateMultiVaultMessage(MultiVaultSFData memory sfData_)
        internal
        view
        returns (bytes memory message_)
    {
        bytes memory ambData = abi.encode(
            InitMultiVaultData(
                _getNextPayloadId(),
                sfData_.superformIds,
                sfData_.amounts,
                sfData_.outputAmounts,
                sfData_.maxSlippages,
                sfData_.liqRequests,
                sfData_.hasDstSwaps,
                sfData_.retain4626s,
                sfData_.receiverAddress,
                sfData_.extraFormData
            )
        );
        message_ = abi.encode(AMBMessage(MAX_UINT256, ambData));
    }

    /// @dev helps convert the dst gas fee into src chain native fee
    /// @dev https://docs.soliditylang.org/en/v0.8.4/units-and-global-variables.html#ether-units
    /// @dev all native tokens should be 18 decimals across all EVMs
    function _convertToNativeFee(
        uint64 dstChainId_,
        uint256 dstGas_,
        bool xChain_
    )
        internal
        view
        returns (uint256 nativeFee)
    {
        /// @dev gas fee * gas price (to get the gas amounts in dst chain's native token)
        /// @dev gas price is 9 decimal (in gwei)
        /// @dev assumption: all evm native tokens are 18 decimals
        uint256 dstNativeFee = dstGas_ * _getGasPrice(dstChainId_);

        if (dstNativeFee == 0) {
            return 0;
        }
        if (!xChain_) {
            return dstNativeFee;
        }

        /// @dev converts the gas to pay in terms of native token to usd value
        /// @dev native token price is 8 decimal
        uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); // native token price - 8 decimal

        if (dstUsdValue == 0) {
            return 0;
        }

        /// @dev converts the usd value to source chain's native token
        /// @dev native token price is 8 decimal which cancels the 8 decimal multiplied in previous step
        uint256 nativeTokenPrice = _getNativeTokenPrice(CHAIN_ID); // native token price - 8 decimal
        if (nativeTokenPrice == 0) revert Error.INVALID_NATIVE_TOKEN_PRICE();
        nativeFee = (dstUsdValue) / nativeTokenPrice;
    }

    /// @dev helps convert a native token of one chain to another
    /// @dev https://docs.soliditylang.org/en/v0.8.4/units-and-global-variables.html#ether-units
    /// @dev all native tokens should be 18 decimals across all EVMs
    function _convertToSrcNativeAmount(
        uint64 srcChainId_,
        uint256 dstAmount_
    )
        internal
        view
        returns (uint256 nativeFee)
    {
        if (dstAmount_ == 0) {
            return 0;
        }

        /// @dev converts the native token value to usd value
        /// @dev dstAmount_ is 18 decimal
        /// @dev native token price is 8 decimal
        uint256 dstUsdValue = dstAmount_ * _getNativeTokenPrice(CHAIN_ID);

        if (dstUsdValue == 0) {
            return 0;
        }

        /// @dev converts the usd value to source chain's native token
        /// @dev native token price is 8 decimal which cancels the 8 decimal multiplied in previous step
        uint256 nativeTokenPrice = _getNativeTokenPrice(srcChainId_);
        if (nativeTokenPrice == 0) revert Error.INVALID_NATIVE_TOKEN_PRICE();

        nativeFee = dstUsdValue / nativeTokenPrice;
    }

    /// @dev helps generate the new payload id
    /// @dev next payload id = current payload id + 1
    function _getNextPayloadId() internal view returns (uint256 nextPayloadId) {
        nextPayloadId = ReadOnlyBaseRegistry(_getAddress(keccak256("CORE_STATE_REGISTRY"))).payloadsCount();
        ++nextPayloadId;
    }

    /// @dev helps return the current gas price of different networks
    /// @return native token price
    function _getGasPrice(uint64 chainId_) internal view returns (uint256) {
        address oracleAddr = address(gasPriceOracle[chainId_]);
        if (oracleAddr != address(0)) {
            try AggregatorV3Interface(oracleAddr).latestRoundData() returns (
                uint80, int256 value, uint256, uint256 updatedAt, uint80
            ) {
                if (value <= 0) revert Error.CHAINLINK_MALFUNCTION();
                if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
                return uint256(value);
            } catch {
                /// @dev do nothing and return the default price at the end of the function
            }
        }

        return gasPrice[chainId_];
    }

    /// @dev helps return the dst chain token price of different networks
    /// @return native token price
    function _getNativeTokenPrice(uint64 chainId_) internal view returns (uint256) {
        address oracleAddr = address(nativeFeedOracle[chainId_]);
        if (oracleAddr != address(0)) {
            try AggregatorV3Interface(oracleAddr).latestRoundData() returns (
                uint80, int256 dstTokenPrice, uint256, uint256 updatedAt, uint80
            ) {
                if (dstTokenPrice <= 0) revert Error.CHAINLINK_MALFUNCTION();
                if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
                return uint256(dstTokenPrice);
            } catch {
                /// @dev do nothing and return the default price at the end of the function
            }
        }

        return nativePrice[chainId_];
    }

    /// @dev returns the address from super registry
    function _getAddress(bytes32 id_) internal view returns (address) {
        return superRegistry.getAddress(id_);
    }

    /// @dev calculates different cost amounts involved in the tx
    function _calculateAmounts(CalculateAmountsReq memory req_)
        internal
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstOrSameChainAmt)
    {
        LocalEstimateVars memory v;

        bool xChain = req_.dstChainIds[req_.i] != CHAIN_ID;

        /// @dev in xChain this is gas on the destination chain and in !xChain this is gas on the same chain
        v.totalGas = 0;

        bool multiVaults = req_.superformsData.length > 0;
        bytes memory message = multiVaults
            ? _generateMultiVaultMessage(req_.superformsData[req_.i])
            : _generateSingleVaultMessage(req_.superformData[req_.i]);

        /// @dev step 1: estimate amb costs
        v.ambFees = xChain ? _estimateAMBFees(req_.ambIds, req_.dstChainIds[req_.i], message) : 0;

        v.superformIdsLen = multiVaults ? req_.superformsData[req_.i].superformIds.length : 1;

        srcAmount += v.ambFees;
        LiqRequest[] memory liqRequests = multiVaults
            ? req_.superformsData[req_.i].liqRequests
            : req_.superformData[req_.i].liqRequest.castLiqRequestToArray();

        if (req_.isDeposit) {
            /// @dev step 2: estimate liq amount
            liqAmount += _estimateLiqAmount(liqRequests);

            if (xChain) {
                /// @dev step 3: estimate update cost (only for deposit)
                v.totalGas += _estimateUpdateDepositCost(req_.dstChainIds[req_.i], v.superformIdsLen);

                uint256 ackLen;
                if (multiVaults) {
                    for (uint256 j; j < v.superformIdsLen; ++j) {
                        if (!req_.superformsData[req_.i].retain4626s[j]) ++ackLen;
                    }
                } else {
                    if (!req_.superformData[req_.i].retain4626) ++ackLen;
                }

                /// @dev step 4: estimation processing cost of acknowledgement on source
                srcAmount += _estimateAckProcessingCost(ackLen);
                bool[] memory hasDstSwaps = multiVaults
                    ? req_.superformsData[req_.i].hasDstSwaps
                    : req_.superformData[req_.i].hasDstSwap.castBoolToArray();
                /// @dev step 5: estimate dst swap cost if it exists
                v.totalGas += _estimateSwapFees(req_.dstChainIds[req_.i], hasDstSwaps);
            }
        } else {
            if (multiVaults) {
                /// @dev step 6: estimate if timelock form processing costs are involved
                for (uint256 j; j < v.superformIdsLen; ++j) {
                    v.totalGas += _calculateTotalDstGasTimelockEmergency(
                        req_.superformsData[req_.i].superformIds[j], req_.dstChainIds[req_.i], req_.factory
                    );
                }
            } else {
                v.totalGas += _calculateTotalDstGasTimelockEmergency(
                    req_.superformData[req_.i].superformId, req_.dstChainIds[req_.i], req_.factory
                );
            }
            if (xChain) {
                /// @dev step 7: estimate update withdraw cost if no txData is present
                v.totalGas += _estimateUpdateWithdrawCost(req_.dstChainIds[req_.i], liqRequests);
            }
        }

        /// @dev step 7: estimate execution costs in destination including sending acknowledgement to source
        /// @dev ensure that acknowledgement costs from dst to src are not double counted
        v.totalGas +=
            xChain ? _estimateDstExecutionCost(req_.isDeposit, req_.dstChainIds[req_.i], v.superformIdsLen) : 0;

        /// @dev step 8: convert all dst/same chain gas estimates to src chain estimate  (withdraw / deposit)
        dstOrSameChainAmt += _convertToNativeFee(req_.dstChainIds[req_.i], v.totalGas, xChain);
    }

    /// @dev calculates the srcAmount cost for single direct withdrawal
    function _calculateTotalDstGasTimelockEmergency(
        uint256 superformId_,
        uint64 dstChainId_,
        ISuperformFactory factory_
    )
        internal
        view
        returns (uint256 totalDstGas)
    {
        (, uint32 formId,) = superformId_.getSuperform();
        bool paused = factory_.isFormImplementationPaused(formId);

        if (!paused && formId == TIMELOCK_FORM_ID) {
            totalDstGas += timelockCost[dstChainId_];
        } else if (paused) {
            totalDstGas += emergencyCost[dstChainId_];
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {
    MultiDstMultiVaultStateReq,
    MultiDstSingleVaultStateReq,
    SingleXChainMultiVaultStateReq,
    SingleXChainSingleVaultStateReq,
    SingleDirectSingleVaultStateReq,
    SingleDirectMultiVaultStateReq
} from "src/types/DataTypes.sol";

/// @title IPaymentHelper
/// @dev Interface for PaymentHelper
/// @author ZeroPoint Labs
interface IPaymentHelper {
    //////////////////////////////////////////////////////////////
    //                           STRUCTS                         //
    //////////////////////////////////////////////////////////////

    /// @param nativeFeedOracle is the native price feed oracle
    /// @param gasPriceOracle is the gas price oracle
    /// @param swapGasUsed is the swap gas params
    /// @param updateDepositGasUsed is the update gas params
    /// @param depositGasUsed is the deposit per vault gas on the chain
    /// @param withdrawGasUsed is the withdraw per vault gas on the chain
    /// @param defaultNativePrice is the native price on the specified chain
    /// @param defaultGasPrice is the gas price on the specified chain
    /// @param dstGasPerByte is the gas per size of data on the specified chain
    /// @param ackGasCost is the gas cost for sending and processing from dst->src
    /// @param timelockCost is the extra cost for processing timelocked payloads
    /// @param emergencyCost is the extra cost for processing emergency payloads
    /// @param updateWithdrawGasUsed is the update gas params for withdraws
    struct PaymentHelperConfig {
        address nativeFeedOracle;
        address gasPriceOracle;
        uint256 swapGasUsed;
        uint256 updateDepositGasUsed;
        uint256 depositGasUsed;
        uint256 withdrawGasUsed;
        uint256 defaultNativePrice;
        uint256 defaultGasPrice;
        uint256 dstGasPerByte;
        uint256 ackGasCost;
        uint256 timelockCost;
        uint256 emergencyCost;
        uint256 updateWithdrawGasUsed;
    }

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event ChainConfigUpdated(uint64 indexed chainId_, uint256 indexed configType_, bytes config_);
    event ChainConfigAdded(uint64 chainId_, PaymentHelperConfig config_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns the amb overrides & gas to be used
    /// @param dstChainId_ is the unique dst chain identifier
    /// @param ambIds_ is the identifiers of arbitrary message bridges to be used
    /// @param message_ is the encoded cross-chain payload
    function calculateAMBData(
        uint64 dstChainId_,
        uint8[] calldata ambIds_,
        bytes memory message_
    )
        external
        view
        returns (uint256 totalFees, bytes memory extraData);

    /// @dev returns the amb overrides & gas to be used
    /// @return extraData the amb specific override information
    function getRegisterTransmuterAMBData() external view returns (bytes memory extraData);

    /// @dev estimates the gas fees for multiple destination and multi vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @param isDeposit_ indicated if the datatype will be used for a deposit
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateMultiDstMultiVault(
        MultiDstMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for multiple destination and single vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @param isDeposit_ indicated if the datatype will be used for a deposit
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateMultiDstSingleVault(
        MultiDstSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for single destination and multi vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @param isDeposit_ indicated if the datatype will be used for a deposit
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateSingleXChainMultiVault(
        SingleXChainMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for single destination and single vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @param isDeposit_ indicated if the datatype will be used for a deposit
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateSingleXChainSingleVault(
        SingleXChainSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for same chain operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @param isDeposit_ indicated if the datatype will be used for a deposit
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateSingleDirectSingleVault(
        SingleDirectSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for multiple same chain operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @param isDeposit_ indicated if the datatype will be used for a deposit
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateSingleDirectMultiVault(
        SingleDirectMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 totalAmount);

    /// @dev returns the gas fees estimation in native tokens if we send message through a combination of AMBs
    /// @param ambIds_ is the identifier of different AMBs
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message
    /// @param extraData_ is any amb-specific information
    /// @return ambFees is the native_tokens to be sent along the transaction for all the ambIds_ included
    function estimateAMBFees(
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes[] memory extraData_
    )
        external
        view
        returns (uint256 ambFees, uint256[] memory);

    /// @dev helps estimate the acknowledgement costs for amb processing
    /// @param payloadId_ is the payload identifier
    /// @return totalFees is the total fees to be paid in native tokens
    function estimateAckCost(uint256 payloadId_) external view returns (uint256 totalFees);

    /// @dev helps estimate the acknowledgement costs for amb processing without relying on payloadId (using max values)
    /// @param multi is the flag indicating if the payload is multi or single
    /// @param ackAmbIds is the list of ambIds to be used for acknowledgement
    /// @param srcChainId is the source chain identifier
    /// @return totalFees is the total fees to be paid in native tokens
    function estimateAckCostDefault(
        bool multi,
        uint8[] memory ackAmbIds,
        uint64 srcChainId
    )
        external
        view
        returns (uint256 totalFees);

    /// @dev helps estimate the acknowledgement costs for amb processing without relying on payloadId (using max values)
    /// with source native amounts
    /// @param multi is the flag indicating if the payload is multi or single
    /// @param ackAmbIds is the list of ambIds to be used for acknowledgement
    /// @param srcChainId is the source chain identifier
    /// @return totalFees is the total fees to be paid in native tokens
    function estimateAckCostDefaultNativeSource(
        bool multi,
        uint8[] memory ackAmbIds,
        uint64 srcChainId
    )
        external
        view
        returns (uint256 totalFees);
    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev admin can configure a remote chain for the first time
    /// @param chainId_ is the identifier of new chain id
    /// @param config_ is the chain config
    function addRemoteChain(uint64 chainId_, PaymentHelperConfig calldata config_) external;

    /// @dev admin can configure various remote chain for the first time in a single call
    /// @param chainIds_ is the identifier of new chain id
    /// @param configs_ is the chain config
    function addRemoteChains(uint64[] calldata chainIds_, PaymentHelperConfig[] calldata configs_) external;

    /// @dev admin can specifically configure/update certain configuration of a remote chain
    /// @param chainId_ is the remote chain's identifier
    /// @param configType_ is the type of config from 1 -> 6
    /// @param config_ is the encoded new configuration
    function updateRemoteChain(uint64 chainId_, uint256 configType_, bytes memory config_) external;

    /// @dev admin can specifically configure/update certain configurations on a single remote chain
    /// @param chainId_ are the remote chain's identifier
    /// @param configTypes_ are the type of config from 1 -> 6 for the given chain
    /// @param configs_ are the encoded new configurations for each config type for the given chain
    function batchUpdateRemoteChain(
        uint64 chainId_,
        uint256[] calldata configTypes_,
        bytes[] calldata configs_
    )
        external;

    /// @dev admin can specifically configure/update certain configurations on various remote chains at the same time
    /// @param chainIds_ are the remote chain's identifier
    /// @param configTypes_ are the type of config from 1 -> 6 for each chain
    /// @param configs_ are the encoded new configurations for each config type and chains
    function batchUpdateRemoteChains(
        uint64[] calldata chainIds_,
        uint256[][] calldata configTypes_,
        bytes[][] calldata configs_
    )
        external;

    /// @dev admin updates config for register transmuter amb params
    /// @param extraDataForTransmuter_ is the broadcast extra data
    function updateRegisterAERC20Params(bytes memory extraDataForTransmuter_) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IAccessControl } from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

/// @title ISuperRBAC
/// @dev Interface for SuperRBAC
/// @author Zeropoint Labs
interface ISuperRBAC is IAccessControl {

    //////////////////////////////////////////////////////////////
    //                           STRUCTS                         //
    //////////////////////////////////////////////////////////////

    struct InitialRoleSetup {
        address admin;
        address emergencyAdmin;
        address paymentAdmin;
        address csrProcessor;
        address tlProcessor;
        address brProcessor;
        address csrUpdater;
        address srcVaaRelayer;
        address dstSwapper;
        address csrRescuer;
        address csrDisputer;
    }

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when superRegistry is set
    event SuperRegistrySet(address indexed superRegistry);

    /// @dev is emitted when an admin is set for a role
    event RoleAdminSet(bytes32 role, bytes32 adminRole);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns the id of the protocol admin role
    function PROTOCOL_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the emergency admin role
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the payment admin role
    function PAYMENT_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the broadcaster role
    function BROADCASTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry processor role
    function CORE_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the timelock state registry processor role
    function TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the broadcast state registry processor role
    function BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater role
    function CORE_STATE_REGISTRY_UPDATER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the dst swapper role
    function DST_SWAPPER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry rescuer role
    function CORE_STATE_REGISTRY_RESCUER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry rescue disputer role
    function CORE_STATE_REGISTRY_DISPUTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of wormhole vaa relayer role
    function WORMHOLE_VAA_RELAYER_ROLE() external view returns (bytes32);

    /// @dev returns whether the given address has the protocol admin role
    /// @param admin_ the address to check
    function hasProtocolAdminRole(address admin_) external view returns (bool);

    /// @dev returns whether the given address has the emergency admin role
    /// @param admin_ the address to check
    function hasEmergencyAdminRole(address admin_) external view returns (bool);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev updates the super registry address
    function setSuperRegistry(address superRegistry_) external;

    /// @dev configures a new role in superForm
    /// @param role_ the role to set
    /// @param adminRole_ the admin role to set as admin
    function setRoleAdmin(bytes32 role_, bytes32 adminRole_) external;

    /// @dev revokes the role_ from superRegistryAddressId_ on all chains
    /// @param role_ the role to revoke
    /// @param extraData_ amb config if broadcasting is required
    /// @param superRegistryAddressId_ the super registry address id
    function revokeRoleSuperBroadcast(
        bytes32 role_,
        bytes memory extraData_,
        bytes32 superRegistryAddressId_
    )
        external
        payable;

    /// @dev allows sync of global roles from different chains using broadcast registry
    /// @notice may not work for all roles
    function stateSyncBroadcast(bytes memory data_) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title ISuperRegistry
/// @dev Interface for SuperRegistry
/// @author Zeropoint Labs
interface ISuperRegistry {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev emitted when permit2 is set.
    event SetPermit2(address indexed permit2);

    /// @dev is emitted when an address is set.
    event AddressUpdated(
        bytes32 indexed protocolAddressId, uint64 indexed chainId, address indexed oldAddress, address newAddress
    );

    /// @dev is emitted when a new token bridge is configured.
    event SetBridgeAddress(uint256 indexed bridgeId, address indexed bridgeAddress);

    /// @dev is emitted when a new bridge validator is configured.
    event SetBridgeValidator(uint256 indexed bridgeId, address indexed bridgeValidator);

    /// @dev is emitted when a new amb is configured.
    event SetAmbAddress(uint8 indexed ambId_, address indexed ambAddress_, bool indexed isBroadcastAMB_);

    /// @dev is emitted when a new state registry is configured.
    event SetStateRegistryAddress(uint8 indexed registryId_, address indexed registryAddress_);

    /// @dev is emitted when a new delay is configured.
    event SetDelay(uint256 indexed oldDelay_, uint256 indexed newDelay_);

    /// @dev is emitted when a new vault limit is configured
    event SetVaultLimitPerDestination(uint64 indexed chainId_, uint256 indexed vaultLimit_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev gets the deposit rescue delay
    function delay() external view returns (uint256);

    /// @dev returns the permit2 address
    function PERMIT2() external view returns (address);

    /// @dev returns the id of the superform router module
    function SUPERFORM_ROUTER() external view returns (bytes32);

    /// @dev returns the id of the superform factory module
    function SUPERFORM_FACTORY() external view returns (bytes32);

    /// @dev returns the id of the superform paymaster contract
    function PAYMASTER() external view returns (bytes32);

    /// @dev returns the id of the superform payload helper contract
    function PAYMENT_HELPER() external view returns (bytes32);

    /// @dev returns the id of the core state registry module
    function CORE_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the timelock form state registry module
    function TIMELOCK_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the broadcast state registry module
    function BROADCAST_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the super positions module
    function SUPER_POSITIONS() external view returns (bytes32);

    /// @dev returns the id of the super rbac module
    function SUPER_RBAC() external view returns (bytes32);

    /// @dev returns the id of the payload helper module
    function PAYLOAD_HELPER() external view returns (bytes32);

    /// @dev returns the id of the dst swapper keeper
    function DST_SWAPPER() external view returns (bytes32);

    /// @dev returns the id of the emergency queue
    function EMERGENCY_QUEUE() external view returns (bytes32);

    /// @dev returns the id of the superform receiver
    function SUPERFORM_RECEIVER() external view returns (bytes32);

    /// @dev returns the id of the payment admin keeper
    function PAYMENT_ADMIN() external view returns (bytes32);

    /// @dev returns the id of the core state registry processor keeper
    function CORE_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the broadcast registry processor keeper
    function BROADCAST_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the timelock form state registry processor keeper
    function TIMELOCK_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_UPDATER() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_RESCUER() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_DISPUTER() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function DST_SWAPPER_PROCESSOR() external view returns (bytes32);

    /// @dev gets the address of a contract on current chain
    /// @param id_ is the id of the contract
    function getAddress(bytes32 id_) external view returns (address);

    /// @dev gets the address of a contract on a target chain
    /// @param id_ is the id of the contract
    /// @param chainId_ is the chain id of that chain
    function getAddressByChainId(bytes32 id_, uint64 chainId_) external view returns (address);

    /// @dev gets the address of a bridge
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeAddress_ is the address of the form
    function getBridgeAddress(uint8 bridgeId_) external view returns (address bridgeAddress_);

    /// @dev gets the address of a bridge validator
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeValidator_ is the address of the form
    function getBridgeValidator(uint8 bridgeId_) external view returns (address bridgeValidator_);

    /// @dev gets the address of a amb
    /// @param ambId_ is the id of a bridge
    /// @return ambAddress_ is the address of the form
    function getAmbAddress(uint8 ambId_) external view returns (address ambAddress_);

    /// @dev gets the id of the amb
    /// @param ambAddress_ is the address of an amb
    /// @return ambId_ is the identifier of an amb
    function getAmbId(address ambAddress_) external view returns (uint8 ambId_);

    /// @dev gets the address of the registry
    /// @param registryId_ is the id of the state registry
    /// @return registryAddress_ is the address of the state registry
    function getStateRegistry(uint8 registryId_) external view returns (address registryAddress_);

    /// @dev gets the id of the registry
    /// @notice reverts if the id is not found
    /// @param registryAddress_ is the address of the state registry
    /// @return registryId_ is the id of the state registry
    function getStateRegistryId(address registryAddress_) external view returns (uint8 registryId_);

    /// @dev gets the safe vault limit
    /// @param chainId_ is the id of the remote chain
    /// @return vaultLimitPerDestination_ is the safe number of vaults to deposit
    /// without hitting out of gas error
    function getVaultLimitPerDestination(uint64 chainId_) external view returns (uint256 vaultLimitPerDestination_);

    /// @dev helps validate if an address is a valid state registry
    /// @param registryAddress_ is the address of the state registry
    /// @return valid_ a flag indicating if its valid.
    function isValidStateRegistry(address registryAddress_) external view returns (bool valid_);

    /// @dev helps validate if an address is a valid amb implementation
    /// @param ambAddress_ is the address of the amb implementation
    /// @return valid_ a flag indicating if its valid.
    function isValidAmbImpl(address ambAddress_) external view returns (bool valid_);

    /// @dev helps validate if an address is a valid broadcast amb implementation
    /// @param ambAddress_ is the address of the broadcast amb implementation
    /// @return valid_ a flag indicating if its valid.
    function isValidBroadcastAmbImpl(address ambAddress_) external view returns (bool valid_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev sets the deposit rescue delay
    /// @param delay_ the delay in seconds before the deposit rescue can be finalized
    function setDelay(uint256 delay_) external;

    /// @dev sets the permit2 address
    /// @param permit2_ the address of the permit2 contract
    function setPermit2(address permit2_) external;

    /// @dev sets the safe vault limit
    /// @param chainId_ is the remote chain identifier
    /// @param vaultLimit_ is the max limit of vaults per transaction
    function setVaultLimitPerDestination(uint64 chainId_, uint256 vaultLimit_) external;

    /// @dev sets new addresses on specific chains.
    /// @param ids_ are the identifiers of the address on that chain
    /// @param newAddresses_  are the new addresses on that chain
    /// @param chainIds_ are the chain ids of that chain
    function batchSetAddress(
        bytes32[] calldata ids_,
        address[] calldata newAddresses_,
        uint64[] calldata chainIds_
    )
        external;

    /// @dev sets a new address on a specific chain.
    /// @param id_ the identifier of the address on that chain
    /// @param newAddress_ the new address on that chain
    /// @param chainId_ the chain id of that chain
    function setAddress(bytes32 id_, address newAddress_, uint64 chainId_) external;

    /// @dev allows admin to set the bridge address for an bridge id.
    /// @notice this function operates in an APPEND-ONLY fashion.
    /// @param bridgeId_         represents the bridge unique identifier.
    /// @param bridgeAddress_    represents the bridge address.
    /// @param bridgeValidator_  represents the bridge validator address.
    function setBridgeAddresses(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_,
        address[] memory bridgeValidator_
    )
        external;

    /// @dev allows admin to set the amb address for an amb id.
    /// @notice this function operates in an APPEND-ONLY fashion.
    /// @param ambId_         represents the bridge unique identifier.
    /// @param ambAddress_    represents the bridge address.
    /// @param isBroadcastAMB_ represents whether the amb implementation supports broadcasting
    function setAmbAddress(
        uint8[] memory ambId_,
        address[] memory ambAddress_,
        bool[] memory isBroadcastAMB_
    )
        external;

    /// @dev allows admin to set the state registry address for an state registry id.
    /// @notice this function operates in an APPEND-ONLY fashion.
    /// @param registryId_    represents the state registry's unique identifier.
    /// @param registryAddress_    represents the state registry's address.
    function setStateRegistryAddress(uint8[] memory registryId_, address[] memory registryAddress_) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title ISuperformFactory
/// @dev Interface for SuperformFactory
/// @author ZeroPoint Labs
interface ISuperformFactory {
    
    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    enum PauseStatus {
        NON_PAUSED,
        PAUSED
    }

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev emitted when a new formImplementation is entered into the factory
    /// @param formImplementation is the address of the new form implementation
    /// @param formImplementationId is the id of the formImplementation
    /// @param formStateRegistryId is any additional state registry id of the formImplementation
    event FormImplementationAdded(
        address indexed formImplementation, uint256 indexed formImplementationId, uint8 indexed formStateRegistryId
    );

    /// @dev emitted when a new Superform is created
    /// @param formImplementationId is the id of the form implementation
    /// @param vault is the address of the vault
    /// @param superformId is the id of the superform
    /// @param superform is the address of the superform
    event SuperformCreated(
        uint256 indexed formImplementationId, address indexed vault, uint256 indexed superformId, address superform
    );

    /// @dev emitted when a new SuperRegistry is set
    /// @param superRegistry is the address of the super registry
    event SuperRegistrySet(address indexed superRegistry);

    /// @dev emitted when a form implementation is paused
    /// @param formImplementationId is the id of the form implementation
    /// @param paused is the new paused status
    event FormImplementationPaused(uint256 indexed formImplementationId, PauseStatus indexed paused);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns the number of forms
    /// @return forms_ is the number of forms
    function getFormCount() external view returns (uint256 forms_);

    /// @dev returns the number of superforms
    /// @return superforms_ is the number of superforms
    function getSuperformCount() external view returns (uint256 superforms_);

    /// @dev returns the address of a form implementation
    /// @param formImplementationId_ is the id of the form implementation
    /// @return formImplementation_ is the address of the form implementation
    function getFormImplementation(uint32 formImplementationId_) external view returns (address formImplementation_);

    /// @dev returns the form state registry id of a form implementation
    /// @param formImplementationId_ is the id of the form implementation
    /// @return stateRegistryId_ is the additional state registry id of the form
    function getFormStateRegistryId(uint32 formImplementationId_) external view returns (uint8 stateRegistryId_);

    /// @dev returns the paused status of form implementation
    /// @param formImplementationId_ is the id of the form implementation
    /// @return paused_ is the current paused status of the form formImplementationId_
    function isFormImplementationPaused(uint32 formImplementationId_) external view returns (bool paused_);

    /// @dev returns the address of a superform
    /// @param superformId_ is the id of the superform
    /// @return superform_ is the address of the superform
    /// @return formImplementationId_ is the id of the form implementation
    /// @return chainId_ is the chain id
    function getSuperform(uint256 superformId_)
        external
        pure
        returns (address superform_, uint32 formImplementationId_, uint64 chainId_);

    /// @dev returns if an address has been added to a Form
    /// @param superformId_ is the id of the superform
    /// @return isSuperform_ bool if it exists
    function isSuperform(uint256 superformId_) external view returns (bool isSuperform_);

    /// @dev Reverse query of getSuperform, returns all superforms for a given vault
    /// @param vault_ is the address of a vault
    /// @return superformIds_ is the id of the superform
    /// @return superforms_ is the address of the superform
    function getAllSuperformsFromVault(address vault_)
        external
        view
        returns (uint256[] memory superformIds_, address[] memory superforms_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev allows an admin to add a Form implementation to the factory
    /// @param formImplementation_ is the address of a form implementation
    /// @param formImplementationId_ is the id of the form implementation (generated off-chain and equal in all chains)
    /// @param formStateRegistryId_ is the id of any additional state registry for that form
    /// @dev formStateRegistryId_ 1 is default for all form implementations, pass in formStateRegistryId_ only if an
    /// additional state registry is required
    function addFormImplementation(
        address formImplementation_,
        uint32 formImplementationId_,
        uint8 formStateRegistryId_
    )
        external;

    /// @dev To add new vaults to Form implementations, fusing them together into Superforms
    /// @param formImplementationId_ is the form implementation we want to attach the vault to
    /// @param vault_ is the address of the vault
    /// @return superformId_ is the id of the created superform
    /// @return superform_ is the address of the created superform
    function createSuperform(
        uint32 formImplementationId_,
        address vault_
    )
        external
        returns (uint256 superformId_, address superform_);

    /// @dev to synchronize superforms added to different chains using broadcast registry
    /// @param data_ is the cross-chain superform id
    function stateSyncBroadcast(bytes memory data_) external payable;

    /// @dev allows an admin to change the status of a form
    /// @param formImplementationId_ is the id of the form implementation
    /// @param status_ is the new status
    /// @param extraData_ is optional & passed when broadcasting of status is needed
    function changeFormImplementationPauseStatus(
        uint32 formImplementationId_,
        PauseStatus status_,
        bytes memory extraData_
    )
        external
        payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { PayloadState } from "src/types/DataTypes.sol";

/// @title IBaseStateRegistry
/// @dev Interface for BaseStateRegistry
/// @author ZeroPoint Labs
interface IBaseStateRegistry {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when a cross-chain payload is received in the state registry
    event PayloadReceived(uint64 indexed srcChainId, uint64 indexed dstChainId, uint256 indexed payloadId);

    /// @dev is emitted when a cross-chain proof is received in the state registry
    /// NOTE: comes handy if quorum required is more than 0
    event ProofReceived(bytes32 indexed proof);

    /// @dev is emitted when a payload id gets updated
    event PayloadUpdated(uint256 indexed payloadId);

    /// @dev is emitted when a payload id gets processed
    event PayloadProcessed(uint256 indexed payloadId);

    /// @dev is emitted when the super registry address is updated
    event SuperRegistryUpdated(address indexed superRegistry);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev allows users to read the total payloads received by the registry
    function payloadsCount() external view returns (uint256);

    /// @dev allows user to read the payload state
    /// uint256 payloadId_ is the unique payload identifier allocated on the destination chain
    function payloadTracking(uint256 payloadId_) external view returns (PayloadState payloadState_);

    /// @dev allows users to read the bytes payload_ stored per payloadId_
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return payloadBody_ the crosschain data received
    function payloadBody(uint256 payloadId_) external view returns (bytes memory payloadBody_);

    /// @dev allows users to read the uint256 payloadHeader stored per payloadId_
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return payloadHeader_ the crosschain header received
    function payloadHeader(uint256 payloadId_) external view returns (uint256 payloadHeader_);

    /// @dev allows users to read the ambs that delivered the payload id
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return ambIds_ is the identifier of ambs that delivered the message and proof
    function getMessageAMB(uint256 payloadId_) external view returns (uint8[] memory ambIds_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev allows core contracts to send payload to a destination chain.
    /// @param srcSender_ is the caller of the function (used for gas refunds).
    /// @param ambIds_ is the identifier of the arbitrary message bridge to be used
    /// @param dstChainId_ is the internal chainId used throughout the protocol
    /// @param message_ is the crosschain payload to be sent
    /// @param extraData_ defines all the message bridge related overrides
    /// NOTE: dstChainId_ is mapped to message bridge's destination id inside it's implementation contract
    /// NOTE: ambIds_ are superform assigned unique identifier for arbitrary message bridges
    function dispatchPayload(
        address srcSender_,
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable;

    /// @dev allows state registry to receive messages from message bridge implementations
    /// @param srcChainId_ is the superform chainId from which the payload is dispatched/sent
    /// @param message_ is the crosschain payload received
    /// NOTE: Only {IMPLEMENTATION_CONTRACT} role can call this function.
    function receivePayload(uint64 srcChainId_, bytes memory message_) external;

    /// @dev allows privileged actors to process cross-chain payloads
    /// @param payloadId_ is the identifier of the cross-chain payload
    /// NOTE: Only {CORE_STATE_REGISTRY_PROCESSOR_ROLE} role can call this function
    /// NOTE: this should handle reverting the state on source chain in-case of failure
    /// (or) can implement scenario based reverting like in coreStateRegistry
    function processPayload(uint256 payloadId_) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title IAmbImplementation
/// @dev Interface for arbitrary message bridge (AMB) implementations
/// @author ZeroPoint Labs
interface IAmbImplementation {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event ChainAdded(uint64 indexed superChainId);
    event AuthorizedImplAdded(uint64 indexed superChainId, address indexed authImpl);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns the gas fees estimation in native tokens
    /// @notice not all AMBs will have on-chain estimation for which this function will return 0
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message
    /// @param extraData_ is any amb-specific information
    /// @return fees is the native_tokens to be sent along the transaction
    function estimateFees(
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        view
        returns (uint256 fees);

    /// @dev returns the extra data for the given gas request
    /// @param gasLimit is the amount of gas limit in wei to override
    /// @return extraData is the bytes encoded extra data
    /// NOTE: this process is unique to the message bridge
    function generateExtraData(uint256 gasLimit) external pure returns (bytes memory extraData);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev allows state registry to send message via implementation.
    /// @param srcSender_ is the caller (used for gas refunds)
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is message amb specific override information
    function dispatchPayload(
        address srcSender_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable;

    /// @dev allows for the permissionless calling of the retry mechanism for encoded data
    /// @param data_ is the encoded retry data (different per AMB implementation)
    function retryPayload(bytes memory data_) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

library Error {
    //////////////////////////////////////////////////////////////
    //                  CONFIGURATION ERRORS                    //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown in protocol setup

    /// @dev thrown if chain id exceeds max(uint64)
    error BLOCK_CHAIN_ID_OUT_OF_BOUNDS();

    /// @dev thrown if not possible to revoke a role in broadcasting
    error CANNOT_REVOKE_NON_BROADCASTABLE_ROLES();

    /// @dev thrown if not possible to revoke last admin
    error CANNOT_REVOKE_LAST_ADMIN();

    /// @dev thrown if trying to set again pseudo immutables in super registry
    error DISABLED();

    /// @dev thrown if rescue delay is not yet set for a chain
    error DELAY_NOT_SET();

    /// @dev thrown if get native token price estimate in paymentHelper is 0
    error INVALID_NATIVE_TOKEN_PRICE();

    /// @dev thrown if wormhole refund chain id is not set
    error REFUND_CHAIN_ID_NOT_SET();

    /// @dev thrown if wormhole relayer is not set
    error RELAYER_NOT_SET();

    /// @dev thrown if a role to be revoked is not assigned
    error ROLE_NOT_ASSIGNED();

    //////////////////////////////////////////////////////////////
    //                  AUTHORIZATION ERRORS                    //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown if functions cannot be called

    /// COMMON AUTHORIZATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if caller is not address(this), internal call
    error INVALID_INTERNAL_CALL();

    /// @dev thrown if msg.sender is not a valid amb implementation
    error NOT_AMB_IMPLEMENTATION();

    /// @dev thrown if msg.sender is not an allowed broadcaster
    error NOT_ALLOWED_BROADCASTER();

    /// @dev thrown if msg.sender is not broadcast amb implementation
    error NOT_BROADCAST_AMB_IMPLEMENTATION();

    /// @dev thrown if msg.sender is not broadcast state registry
    error NOT_BROADCAST_REGISTRY();

    /// @dev thrown if msg.sender is not core state registry
    error NOT_CORE_STATE_REGISTRY();

    /// @dev thrown if msg.sender is not emergency admin
    error NOT_EMERGENCY_ADMIN();

    /// @dev thrown if msg.sender is not emergency queue
    error NOT_EMERGENCY_QUEUE();

    /// @dev thrown if msg.sender is not minter
    error NOT_MINTER();

    /// @dev thrown if msg.sender is not minter state registry
    error NOT_MINTER_STATE_REGISTRY_ROLE();

    /// @dev thrown if msg.sender is not paymaster
    error NOT_PAYMASTER();

    /// @dev thrown if msg.sender is not payment admin
    error NOT_PAYMENT_ADMIN();

    /// @dev thrown if msg.sender is not protocol admin
    error NOT_PROTOCOL_ADMIN();

    /// @dev thrown if msg.sender is not state registry
    error NOT_STATE_REGISTRY();

    /// @dev thrown if msg.sender is not super registry
    error NOT_SUPER_REGISTRY();

    /// @dev thrown if msg.sender is not superform router
    error NOT_SUPERFORM_ROUTER();

    /// @dev thrown if msg.sender is not a superform
    error NOT_SUPERFORM();

    /// @dev thrown if msg.sender is not superform factory
    error NOT_SUPERFORM_FACTORY();

    /// @dev thrown if msg.sender is not timelock form
    error NOT_TIMELOCK_SUPERFORM();

    /// @dev thrown if msg.sender is not timelock state registry
    error NOT_TIMELOCK_STATE_REGISTRY();

    /// @dev thrown if msg.sender is not user or disputer
    error NOT_VALID_DISPUTER();

    /// @dev thrown if the msg.sender is not privileged caller
    error NOT_PRIVILEGED_CALLER(bytes32 role);

    /// STATE REGISTRY AUTHORIZATION ERRORS
    /// ---------------------------------------------------------

    /// @dev layerzero adapter specific error, thrown if caller not layerzero endpoint
    error CALLER_NOT_ENDPOINT();

    /// @dev hyperlane adapter specific error, thrown if caller not hyperlane mailbox
    error CALLER_NOT_MAILBOX();

    /// @dev wormhole relayer specific error, thrown if caller not wormhole relayer
    error CALLER_NOT_RELAYER();

    /// @dev thrown if src chain sender is not valid
    error INVALID_SRC_SENDER();

    //////////////////////////////////////////////////////////////
    //                  INPUT VALIDATION ERRORS                 //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown if input variables are not valid

    /// COMMON INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if there is an array length mismatch
    error ARRAY_LENGTH_MISMATCH();

    /// @dev thrown if payload id does not exist
    error INVALID_PAYLOAD_ID();

    /// @dev error thrown when msg value should be zero in certain payable functions
    error MSG_VALUE_NOT_ZERO();

    /// @dev thrown if amb ids length is 0
    error ZERO_AMB_ID_LENGTH();

    /// @dev thrown if address input is address 0
    error ZERO_ADDRESS();

    /// @dev thrown if amount input is 0
    error ZERO_AMOUNT();

    /// @dev thrown if final token is address 0
    error ZERO_FINAL_TOKEN();

    /// @dev thrown if value input is 0
    error ZERO_INPUT_VALUE();

    /// SUPERFORM ROUTER INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if the vaults data is invalid
    error INVALID_SUPERFORMS_DATA();

    /// @dev thrown if receiver address is not set
    error RECEIVER_ADDRESS_NOT_SET();

    /// SUPERFORM FACTORY INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if a form is not ERC165 compatible
    error ERC165_UNSUPPORTED();

    /// @dev thrown if a form is not form interface compatible
    error FORM_INTERFACE_UNSUPPORTED();

    /// @dev error thrown if form implementation address already exists
    error FORM_IMPLEMENTATION_ALREADY_EXISTS();

    /// @dev error thrown if form implementation id already exists
    error FORM_IMPLEMENTATION_ID_ALREADY_EXISTS();

    /// @dev thrown if a form does not exist
    error FORM_DOES_NOT_EXIST();

    /// @dev thrown if form id is larger than max uint16
    error INVALID_FORM_ID();

    /// @dev thrown if superform not on factory
    error SUPERFORM_ID_NONEXISTENT();

    /// @dev thrown if same vault and form implementation is used to create new superform
    error VAULT_FORM_IMPLEMENTATION_COMBINATION_EXISTS();

    /// FORM INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if in case of no txData, if liqData.token != vault.asset()
    /// in case of txData, if token output of swap != vault.asset()
    error DIFFERENT_TOKENS();

    /// @dev thrown if the amount in direct withdraw is not correct
    error DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

    /// @dev thrown if the amount in xchain withdraw is not correct
    error XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();

    /// LIQUIDITY BRIDGE INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if route id is blacklisted in socket
    error BLACKLISTED_ROUTE_ID();

    /// @dev thrown if route id is not blacklisted in socket
    error NOT_BLACKLISTED_ROUTE_ID();

    /// @dev error thrown when txData selector of lifi bridge is a blacklisted selector
    error BLACKLISTED_SELECTOR();

    /// @dev error thrown when txData selector of lifi bridge is not a blacklisted selector
    error NOT_BLACKLISTED_SELECTOR();

    /// @dev thrown if a certain action of the user is not allowed given the txData provided
    error INVALID_ACTION();

    /// @dev thrown if in deposits, the liqDstChainId doesn't match the stateReq dstChainId
    error INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();

    /// @dev thrown if index is invalid
    error INVALID_INDEX();

    /// @dev thrown if the chain id in the txdata is invalid
    error INVALID_TXDATA_CHAIN_ID();

    /// @dev thrown if the validation of bridge txData fails due to a destination call present
    error INVALID_TXDATA_NO_DESTINATIONCALL_ALLOWED();

    /// @dev thrown if the validation of bridge txData fails due to wrong receiver
    error INVALID_TXDATA_RECEIVER();

    /// @dev thrown if the validation of bridge txData fails due to wrong token
    error INVALID_TXDATA_TOKEN();

    /// @dev thrown if txData is not present (in case of xChain actions)
    error NO_TXDATA_PRESENT();

    /// STATE REGISTRY INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if payload is being updated with final amounts length different than amounts length
    error DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH();

    /// @dev thrown if payload is being updated with tx data length different than liq data length
    error DIFFERENT_PAYLOAD_UPDATE_TX_DATA_LENGTH();

    /// @dev thrown if keeper update final token is different than the vault underlying
    error INVALID_UPDATE_FINAL_TOKEN();

    /// @dev thrown if broadcast finality for wormhole is invalid
    error INVALID_BROADCAST_FINALITY();

    /// @dev thrown if amb id is not valid leading to an address 0 of the implementation
    error INVALID_BRIDGE_ID();

    /// @dev thrown if chain id involved in xchain message is invalid
    error INVALID_CHAIN_ID();

    /// @dev thrown if payload update amount isn't equal to dst swapper amount
    error INVALID_DST_SWAP_AMOUNT();

    /// @dev thrown if message amb and proof amb are the same
    error INVALID_PROOF_BRIDGE_ID();

    /// @dev thrown if order of proof AMBs is incorrect, either duplicated or not incrementing
    error INVALID_PROOF_BRIDGE_IDS();

    /// @dev thrown if rescue data lengths are invalid
    error INVALID_RESCUE_DATA();

    /// @dev thrown if delay is invalid
    error INVALID_TIMELOCK_DELAY();

    /// @dev thrown if amounts being sent in update payload mean a negative slippage
    error NEGATIVE_SLIPPAGE();

    /// @dev thrown if slippage is outside of bounds
    error SLIPPAGE_OUT_OF_BOUNDS();

    /// SUPERPOSITION INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if src senders mismatch in state sync
    error SRC_SENDER_MISMATCH();

    /// @dev thrown if src tx types mismatch in state sync
    error SRC_TX_TYPE_MISMATCH();

    //////////////////////////////////////////////////////////////
    //                  EXECUTION ERRORS                        //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown due to function execution logic

    /// COMMON EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if the swap in a direct deposit resulted in insufficient tokens
    error DIRECT_DEPOSIT_SWAP_FAILED();

    /// @dev thrown if payload is not unique
    error DUPLICATE_PAYLOAD();

    /// @dev thrown if native tokens fail to be sent to superform contracts
    error FAILED_TO_SEND_NATIVE();

    /// @dev thrown if allowance is not correct to deposit
    error INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();

    /// @dev thrown if contract has insufficient balance for operations
    error INSUFFICIENT_BALANCE();

    /// @dev thrown if native amount is not at least equal to the amount in the request
    error INSUFFICIENT_NATIVE_AMOUNT();

    /// @dev thrown if payload cannot be decoded
    error INVALID_PAYLOAD();

    /// @dev thrown if payload status is invalid
    error INVALID_PAYLOAD_STATUS();

    /// @dev thrown if payload type is invalid
    error INVALID_PAYLOAD_TYPE();

    /// LIQUIDITY BRIDGE EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if we try to decode the final swap output token in a xChain liquidity bridging action
    error CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();

    /// @dev thrown if liquidity bridge fails for erc20 or native tokens
    error FAILED_TO_EXECUTE_TXDATA(address token);

    /// @dev thrown if asset being used for deposit mismatches in multivault deposits
    error INVALID_DEPOSIT_TOKEN();

    /// STATE REGISTRY EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /// @dev thrown if withdrawal tx data cannot be updated
    error CANNOT_UPDATE_WITHDRAW_TX_DATA();

    /// @dev thrown if rescue passed dispute deadline
    error DISPUTE_TIME_ELAPSED();

    /// @dev thrown if message failed to reach the specified level of quorum needed
    error INSUFFICIENT_QUORUM();

    /// @dev thrown if broadcast payload is invalid
    error INVALID_BROADCAST_PAYLOAD();

    /// @dev thrown if broadcast fee is invalid
    error INVALID_BROADCAST_FEE();

    /// @dev thrown if retry fees is less than required
    error INVALID_RETRY_FEE();

    /// @dev thrown if broadcast message type is wrong
    error INVALID_MESSAGE_TYPE();

    /// @dev thrown if payload hash is invalid during `retryMessage` on Layezero implementation
    error INVALID_PAYLOAD_HASH();

    /// @dev thrown if update payload function was called on a wrong payload
    error INVALID_PAYLOAD_UPDATE_REQUEST();

    /// @dev thrown if a state registry id is 0
    error INVALID_REGISTRY_ID();

    /// @dev thrown if a form state registry id is 0
    error INVALID_FORM_REGISTRY_ID();

    /// @dev thrown if trying to finalize the payload but the withdraw is still locked
    error LOCKED();

    /// @dev thrown if payload is already updated (during xChain deposits)
    error PAYLOAD_ALREADY_UPDATED();

    /// @dev thrown if payload is already processed
    error PAYLOAD_ALREADY_PROCESSED();

    /// @dev thrown if payload is not in UPDATED state
    error PAYLOAD_NOT_UPDATED();

    /// @dev thrown if rescue is still in timelocked state
    error RESCUE_LOCKED();

    /// @dev thrown if rescue is already proposed
    error RESCUE_ALREADY_PROPOSED();

    /// @dev thrown if payload hash is zero during `retryMessage` on Layezero implementation
    error ZERO_PAYLOAD_HASH();

    /// DST SWAPPER EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if process dst swap is tried for processed payload id
    error DST_SWAP_ALREADY_PROCESSED();

    /// @dev thrown if indices have duplicates
    error DUPLICATE_INDEX();

    /// @dev thrown if failed dst swap is already updated
    error FAILED_DST_SWAP_ALREADY_UPDATED();

    /// @dev thrown if indices are out of bounds
    error INDEX_OUT_OF_BOUNDS();

    /// @dev thrown if failed swap token amount is 0
    error INVALID_DST_SWAPPER_FAILED_SWAP();

    /// @dev thrown if failed swap token amount is not 0 and if token balance is less than amount (non zero)
    error INVALID_DST_SWAPPER_FAILED_SWAP_NO_TOKEN_BALANCE();

    /// @dev thrown if failed swap token amount is not 0 and if native amount is less than amount (non zero)
    error INVALID_DST_SWAPPER_FAILED_SWAP_NO_NATIVE_BALANCE();

    /// @dev forbid xChain deposits with destination swaps without interim token set (for user protection)
    error INVALID_INTERIM_TOKEN();

    /// @dev thrown if dst swap output is less than minimum expected
    error INVALID_SWAP_OUTPUT();

    /// FORM EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if try to forward 4626 share from the superform
    error CANNOT_FORWARD_4646_TOKEN();

    /// @dev thrown in KYCDAO form if no KYC token is present
    error NO_VALID_KYC_TOKEN();

    /// @dev thrown in forms where a certain functionality is not allowed or implemented
    error NOT_IMPLEMENTED();

    /// @dev thrown if form implementation is PAUSED, users cannot perform any action
    error PAUSED();

    /// @dev thrown if shares != deposit output or assets != redeem output when minting SuperPositions
    error VAULT_IMPLEMENTATION_FAILED();

    /// @dev thrown if withdrawal tx data is not updated
    error WITHDRAW_TOKEN_NOT_UPDATED();

    /// @dev thrown if withdrawal tx data is not updated
    error WITHDRAW_TX_DATA_NOT_UPDATED();

    /// @dev thrown when redeeming from vault yields zero collateral
    error WITHDRAW_ZERO_COLLATERAL();

    /// PAYMENT HELPER EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if chainlink is reporting an improper price
    error CHAINLINK_MALFUNCTION();

    /// @dev thrown if chainlink is reporting an incomplete round
    error CHAINLINK_INCOMPLETE_ROUND();

    /// @dev thrown if feed decimals is not 8
    error CHAINLINK_UNSUPPORTED_DECIMAL();

    /// EMERGENCY QUEUE EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if emergency withdraw is not queued
    error EMERGENCY_WITHDRAW_NOT_QUEUED();

    /// @dev thrown if emergency withdraw is already processed
    error EMERGENCY_WITHDRAW_PROCESSED_ALREADY();

    /// SUPERPOSITION EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if uri cannot be updated
    error DYNAMIC_URI_FROZEN();

    /// @dev thrown if tx history is not found while state sync
    error TX_HISTORY_NOT_FOUND();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";

library DataLib {
    function packTxInfo(
        uint8 txType_,
        uint8 callbackType_,
        uint8 multi_,
        uint8 registryId_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        pure
        returns (uint256 txInfo)
    {
        txInfo = uint256(txType_);
        txInfo |= uint256(callbackType_) << 8;
        txInfo |= uint256(multi_) << 16;
        txInfo |= uint256(registryId_) << 24;
        txInfo |= uint256(uint160(srcSender_)) << 32;
        txInfo |= uint256(srcChainId_) << 192;
    }

    function decodeTxInfo(uint256 txInfo_)
        internal
        pure
        returns (uint8 txType, uint8 callbackType, uint8 multi, uint8 registryId, address srcSender, uint64 srcChainId)
    {
        txType = uint8(txInfo_);
        callbackType = uint8(txInfo_ >> 8);
        multi = uint8(txInfo_ >> 16);
        registryId = uint8(txInfo_ >> 24);
        srcSender = address(uint160(txInfo_ >> 32));
        srcChainId = uint64(txInfo_ >> 192);
    }

    /// @dev returns the vault-form-chain pair of a superform
    /// @param superformId_ is the id of the superform
    /// @return superform_ is the address of the superform
    /// @return formImplementationId_ is the form id
    /// @return chainId_ is the chain id
    function getSuperform(uint256 superformId_)
        internal
        pure
        returns (address superform_, uint32 formImplementationId_, uint64 chainId_)
    {
        superform_ = address(uint160(superformId_));
        formImplementationId_ = uint32(superformId_ >> 160);
        chainId_ = uint64(superformId_ >> 192);

        if (chainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }
    }

    /// @dev returns the vault-form-chain pair of an array of superforms
    /// @param superformIds_  array of superforms
    /// @return superforms_ are the address of the vaults
    function getSuperforms(uint256[] memory superformIds_) internal pure returns (address[] memory superforms_) {
        uint256 len = superformIds_.length;
        superforms_ = new address[](len);

        for (uint256 i; i < len; ++i) {
            (superforms_[i],,) = getSuperform(superformIds_[i]);
        }
    }

    /// @dev returns the destination chain of a given superform
    /// @param superformId_ is the id of the superform
    /// @return chainId_ is the chain id
    function getDestinationChain(uint256 superformId_) internal pure returns (uint64 chainId_) {
        chainId_ = uint64(superformId_ >> 192);

        if (chainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }
    }

    /// @dev generates the superformId
    /// @param superform_ is the address of the superform
    /// @param formImplementationId_ is the type of the form
    /// @param chainId_ is the chain id on which the superform is deployed
    function packSuperform(
        address superform_,
        uint32 formImplementationId_,
        uint64 chainId_
    )
        internal
        pure
        returns (uint256 superformId_)
    {
        superformId_ = uint256(uint160(superform_));
        superformId_ |= uint256(formImplementationId_) << 160;
        superformId_ |= uint256(chainId_) << 192;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AMBMessage } from "src/types/DataTypes.sol";

/// @dev generates proof for amb message and bytes encoded message
library ProofLib {
    function computeProof(AMBMessage memory message_) internal pure returns (bytes32) {
        return keccak256(abi.encode(message_));
    }

    function computeProofBytes(AMBMessage memory message_) internal pure returns (bytes memory) {
        return abi.encode(keccak256(abi.encode(message_)));
    }

    function computeProof(bytes memory message_) internal pure returns (bytes32) {
        return keccak256(message_);
    }

    function computeProofBytes(bytes memory message_) internal pure returns (bytes memory) {
        return abi.encode(keccak256(message_));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { InitSingleVaultData, InitMultiVaultData, LiqRequest } from "src/types/DataTypes.sol";

/// @dev library to cast single values into array for streamlining helper functions
/// @notice not gas optimized, suggested for usage only in view/pure functions
library ArrayCastLib {
    function castLiqRequestToArray(LiqRequest memory value_) internal pure returns (LiqRequest[] memory values) {
        values = new LiqRequest[](1);

        values[0] = value_;
    }

    function castBoolToArray(bool value_) internal pure returns (bool[] memory values) {
        values = new bool[](1);

        values[0] = value_;
    }

    function castToMultiVaultData(InitSingleVaultData memory data_)
        internal
        pure
        returns (InitMultiVaultData memory castedData_)
    {
        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = data_.superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = data_.amount;

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = data_.outputAmount;

        uint256[] memory maxSlippage = new uint256[](1);
        maxSlippage[0] = data_.maxSlippage;

        LiqRequest[] memory liqData = new LiqRequest[](1);
        liqData[0] = data_.liqData;

        castedData_ = InitMultiVaultData(
            data_.payloadId,
            superformIds,
            amounts,
            outputAmounts,
            maxSlippage,
            liqData,
            castBoolToArray(data_.hasDstSwap),
            castBoolToArray(data_.retain4626),
            data_.receiverAddress,
            data_.extraFormData
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @dev contains all the common struct and enums used for data communication between chains.

/// @dev There are two transaction types in Superform Protocol
enum TransactionType {
    DEPOSIT,
    WITHDRAW
}

/// @dev Message types can be INIT, RETURN (for successful Deposits) and FAIL (for failed withdraws)
enum CallbackType {
    INIT,
    RETURN,
    FAIL
}

/// @dev Payloads are stored, updated (deposits) or processed (finalized)
enum PayloadState {
    STORED,
    UPDATED,
    PROCESSED
}

/// @dev contains all the common struct used for interchain token transfers.
struct LiqRequest {
    /// @dev generated data
    bytes txData;
    /// @dev input token for deposits, desired output token on target liqDstChainId for withdraws. Must be set for
    /// txData to be updated on destination for withdraws
    address token;
    /// @dev intermediary token on destination. Relevant for xChain deposits where a destination swap is needed for
    /// validation purposes
    address interimToken;
    /// @dev what bridge to use to move tokens
    uint8 bridgeId;
    /// @dev dstChainId = liqDstchainId for deposits. For withdraws it is the target chain id for where the underlying
    /// is to be delivered
    uint64 liqDstChainId;
    /// @dev currently this amount is used as msg.value in the txData call.
    uint256 nativeAmount;
}

/// @dev main struct that holds required multi vault data for an action
struct MultiVaultSFData {
    // superformids must have same destination. Can have different underlyings
    uint256[] superformIds;
    uint256[] amounts; // on deposits, amount of token to deposit on dst, on withdrawals, superpositions to burn
    uint256[] outputAmounts; // on deposits, amount of shares to receive, on withdrawals, amount of assets to receive
    uint256[] maxSlippages;
    LiqRequest[] liqRequests; // if length = 1; amount = sum(amounts) | else  amounts must match the amounts being sent
    bytes permit2data;
    bool[] hasDstSwaps;
    bool[] retain4626s; // if true, we don't mint SuperPositions, and send the 4626 back to the user instead
    address receiverAddress;
    /// this address must always be an EOA otherwise funds may be lost
    address receiverAddressSP;
    /// this address can be a EOA or a contract that implements onERC1155Receiver. must always be set for deposits
    bytes extraFormData; // extraFormData
}

/// @dev main struct that holds required single vault data for an action
struct SingleVaultSFData {
    // superformids must have same destination. Can have different underlyings
    uint256 superformId;
    uint256 amount;
    uint256 outputAmount; // on deposits, amount of shares to receive, on withdrawals, amount of assets to receive
    uint256 maxSlippage;
    LiqRequest liqRequest; // if length = 1; amount = sum(amounts)| else  amounts must match the amounts being sent
    bytes permit2data;
    bool hasDstSwap;
    bool retain4626; // if true, we don't mint SuperPositions, and send the 4626 back to the user instead
    address receiverAddress;
    /// this address must always be an EOA otherwise funds may be lost
    address receiverAddressSP;
    /// this address can be a EOA or a contract that implements onERC1155Receiver. must always be set for deposits
    bytes extraFormData; // extraFormData
}

/// @dev overarching struct for multiDst requests with multi vaults
struct MultiDstMultiVaultStateReq {
    uint8[][] ambIds;
    uint64[] dstChainIds;
    MultiVaultSFData[] superformsData;
}

/// @dev overarching struct for single cross chain requests with multi vaults
struct SingleXChainMultiVaultStateReq {
    uint8[] ambIds;
    uint64 dstChainId;
    MultiVaultSFData superformsData;
}

/// @dev overarching struct for multiDst requests with single vaults
struct MultiDstSingleVaultStateReq {
    uint8[][] ambIds;
    uint64[] dstChainIds;
    SingleVaultSFData[] superformsData;
}

/// @dev overarching struct for single cross chain requests with single vaults
struct SingleXChainSingleVaultStateReq {
    uint8[] ambIds;
    uint64 dstChainId;
    SingleVaultSFData superformData;
}

/// @dev overarching struct for single direct chain requests with single vaults
struct SingleDirectSingleVaultStateReq {
    SingleVaultSFData superformData;
}

/// @dev overarching struct for single direct chain requests with multi vaults
struct SingleDirectMultiVaultStateReq {
    MultiVaultSFData superformData;
}

/// @dev struct for SuperRouter with re-arranged data for the message (contains the payloadId)
/// @dev realize that receiverAddressSP is not passed, only needed on source chain to mint
struct InitMultiVaultData {
    uint256 payloadId;
    uint256[] superformIds;
    uint256[] amounts;
    uint256[] outputAmounts;
    uint256[] maxSlippages;
    LiqRequest[] liqData;
    bool[] hasDstSwaps;
    bool[] retain4626s;
    address receiverAddress;
    bytes extraFormData;
}

/// @dev struct for SuperRouter with re-arranged data for the message (contains the payloadId)
struct InitSingleVaultData {
    uint256 payloadId;
    uint256 superformId;
    uint256 amount;
    uint256 outputAmount;
    uint256 maxSlippage;
    LiqRequest liqData;
    bool hasDstSwap;
    bool retain4626;
    address receiverAddress;
    bytes extraFormData;
}

/// @dev struct for Emergency Queue
struct QueuedWithdrawal {
    address receiverAddress;
    uint256 superformId;
    uint256 amount;
    uint256 srcPayloadId;
    bool isProcessed;
}

/// @dev all statuses of the timelock payload
enum TimelockStatus {
    UNAVAILABLE,
    PENDING,
    PROCESSED
}

/// @dev holds information about the timelock payload
struct TimelockPayload {
    uint8 isXChain;
    uint64 srcChainId;
    uint256 lockedTill;
    InitSingleVaultData data;
    TimelockStatus status;
}

/// @dev struct that contains the type of transaction, callback flags and other identification, as well as the vaults
/// data in params
struct AMBMessage {
    uint256 txInfo; // tight packing of  TransactionType txType,  CallbackType flag  if multi/single vault, registry id,
        // srcSender and srcChainId
    bytes params; // decoding txInfo will point to the right datatype of params. Refer PayloadHelper.sol
}

/// @dev struct that contains the information required for broadcasting changes
struct BroadcastMessage {
    bytes target;
    bytes32 messageType;
    bytes message;
}

/// @dev struct that contains info on returned data from destination
struct ReturnMultiData {
    uint256 payloadId;
    uint256[] superformIds;
    uint256[] amounts;
}

/// @dev struct that contains info on returned data from destination
struct ReturnSingleData {
    uint256 payloadId;
    uint256 superformId;
    uint256 amount;
}

/// @dev struct that contains the data on the fees to pay to the AMBs
struct AMBExtraData {
    uint256[] gasPerAMB;
    bytes[] extraDataPerAMB;
}

/// @dev struct that contains the data on the fees to pay to the AMBs on broadcasts
struct BroadCastAMBExtraData {
    uint256[] gasPerDst;
    bytes[] extraDataPerDst;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC-165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
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
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}