// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/IVariableRateTransfers.sol";
import "../base/Access.sol";
import "../base/CommonState.sol";
import "../base/ProcessorManagerV2.sol";
import "../base/TokenManagerV2.sol";
import "../../libraries/FeeMath.sol";
import "../../libraries/TokenMath.sol";
import "./SigUtils.sol";

contract VariableRateTransfers is
    IVariableRateTransfers,
    Ownable,
    Initializable,
    CommonState,
    ProcessorManagerV2,
    TokenManagerV2,
    SigUtils,
    Pausable
{
    address public inboundTreasury;
    address public outboundTreasury;
    address public certifiedSigner;
    mapping(uint256 => bool) public transfers;
    SecurityLevel public securityLevel;

    event TransferProcessed(
        address indexed caller,
        string id,
        bool success,
        bool inbound,
        address token,
        address endUser,
        uint256 amount,
        uint256 processingFee,
        bytes err
    );

    event SecurityLevelUpdated(
        address indexed caller,
        SecurityLevel oldSecurityLevel,
        SecurityLevel newSecurityLevel
    );

    event OperatorAddressUpdated(
        address indexed caller,
        OperatorAddress indexed account,
        address oldAddress,
        address newAddress
    );

    function initialize(
        ProcessorManagerInitParams calldata processorManagerInitParams_,
        TokenManagerInitParams calldata tokenManagerInitParams_,
        OperatorInitParams calldata operatorInitParams_,
        SecurityLevel securityLevel_,
        CommonStateInitParams calldata commonStateInitParams_,
        address multiRoleGrantee_
    ) external initializer {
        _transferOwnership(msg.sender);
        __Access_init(multiRoleGrantee_);
        __CommonState_init(
            commonStateInitParams_.factory,
            commonStateInitParams_.WETH
        );
        __ProcessorManager_init(processorManagerInitParams_);
        __TokenManager_init(
            tokenManagerInitParams_.acceptedTokens,
            tokenManagerInitParams_.chainlinkAggregators
        );
        _setOperatorAddress(
            address(0),
            OperatorAddress.INBOUND_TREASURY,
            operatorInitParams_.inboundTreasury
        );
        _setOperatorAddress(
            address(0),
            OperatorAddress.OUTBOUND_TREASURY,
            operatorInitParams_.outboundTreasury
        );
        _setOperatorAddress(
            address(0),
            OperatorAddress.SIGNER,
            operatorInitParams_.signer
        );

        _setSecurityLevel(address(0), securityLevel_);
    }

    /*************************************************/
    /*************   EXTERNAL  FUNCTIONS   *************/
    /*************************************************/

    // TODO non-reentrant (?)
    function processTransfers(TransferParams[] calldata transfers_)
        external
        onlyValidProcessorExt
        whenNotPaused
    {
        if (securityLevel == SecurityLevel.DIRECT) {
            _processDirectTransfers(transfers_);
        } else {
            _processPlatformTransfers(transfers_);
        }
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function setOperatorAddress(OperatorAddress account_, address addr_)
        external
        onlyOperator
    {
        _setOperatorAddress(msg.sender, account_, addr_);
    }

    function setSecurityLevel(SecurityLevel securityLevel_)
        external
        onlyGovernor
    {
        _setSecurityLevel(msg.sender, securityLevel_);
    }

    function processTransfer(
        Transfer calldata transfer_,
        Signature calldata signature_,
        bool inbound_,
        address processor_
    ) external returns (uint256 amount, uint256 processingFee) {
        require(msg.sender == address(this), "LC:SELF_ONLY");

        require(tokenInfo[transfer_.token].accepted > 0, "LC:INVALID_TOKEN");

        /* Validate Signature */
        address transferSigner = _getSigner(transfer_, signature_);

        require(transferSigner == certifiedSigner, "LC:INVALID_SIGNER");

        /* Validate Transfer Uniqueness */
        uint256 transferHash = _hashTransfer(transfer_);

        require(!transfers[transferHash], "LC:TRANSFER_ALREADY_PROCESSED");
        transfers[transferHash] = true;

        (uint256 exchangeRate, uint8 exchangeRatedecimals) = _getTokenToUsdRate(
            transfer_.token
        );

        uint256 tokenDecimals = IERC20Metadata(transfer_.token).decimals();

        /* Convert USD Amounts to Given Token */
        amount = transfer_.usd
            ? TokenMath.convertUsdToTokenAmount(
                transfer_.amount,
                exchangeRate,
                exchangeRatedecimals,
                tokenDecimals
            )
            : transfer_.amount;

        /* Process Fee */
        uint256 baseFeeTokenAmt = TokenMath.convertUsdToTokenAmount(
            baseFee,
            exchangeRate,
            exchangeRatedecimals,
            tokenDecimals
        );
        processingFee = FeeMath.calculateProcessingFee(
            baseFeeTokenAmt,
            variableFee,
            amount
        );

        amount = inbound_ ? amount - processingFee : amount;

        if (processingFee > 0) {
            IERC20Metadata(transfer_.token).transferFrom(
                transfer_.from,
                processor_,
                processingFee
            );
        }

        /* Execute Transfer */
        IERC20Metadata(transfer_.token).transferFrom(
            transfer_.from,
            transfer_.to,
            amount
        );
    }

    function _processDirectTransfers(TransferParams[] calldata transfers_)
        internal
    {
        bool success;
        bytes memory returnData;
        bytes memory err;
        bool inbound;
        address endUser;
        uint256 _amount;
        uint256 _processingFee;

        for (uint256 i = 0; i < transfers_.length; i++) {
            if (transfers_[i].data.to == inboundTreasury) {
                inbound = true;
                endUser = transfers_[i].data.from;

                (success, returnData) = address(this).call(
                    abi.encodeWithSelector(
                        this.processTransfer.selector,
                        transfers_[i].data,
                        transfers_[i].signature,
                        inbound,
                        msg.sender
                    )
                );
            } else if (transfers_[i].data.from == outboundTreasury) {
                inbound = false;
                endUser = transfers_[i].data.to;

                (success, returnData) = address(this).call(
                    abi.encodeWithSelector(
                        this.processTransfer.selector,
                        transfers_[i].data,
                        transfers_[i].signature,
                        inbound,
                        msg.sender
                    )
                );
            } else {
                success = false;
                returnData = bytes("LC:INVALID_TO_FROM_ADDRESS");
            }

            if (success) {
                (_amount, _processingFee) = abi.decode(
                    returnData,
                    (uint256, uint256)
                );
                err = bytes("");
            } else {
                err = returnData;
                _amount = transfers_[i].data.amount;
                _processingFee = 0;
            }

            emit TransferProcessed(
                msg.sender,
                transfers_[i].data.id,
                success,
                inbound,
                transfers_[i].data.token,
                endUser,
                _amount,
                _processingFee,
                err
            );
        }
    }

    function _processPlatformTransfers(TransferParams[] calldata transfers_)
        internal
    {
        bool success;
        bytes memory returnData;
        bytes memory err;
        uint256 _amount;
        uint256 _processingFee;

        for (uint256 i = 0; i < transfers_.length; i++) {
            (success, returnData) = address(this).call(
                abi.encodeWithSelector(
                    this.processTransfer.selector,
                    transfers_[i].data,
                    transfers_[i].signature,
                    true,
                    msg.sender
                )
            );

            if (success) {
                (_amount, _processingFee) = abi.decode(
                    returnData,
                    (uint256, uint256)
                );
                err = bytes("");
            } else {
                err = returnData;
                _amount = transfers_[i].data.amount;
                _processingFee = 0;
            }

            emit TransferProcessed(
                msg.sender,
                transfers_[i].data.id,
                success,
                true,
                transfers_[i].data.token,
                transfers_[i].data.from,
                _amount,
                _processingFee,
                err
            );
        }
    }

    function _hashTransfer(Transfer calldata transfer_)
        internal
        pure
        returns (uint256 transferHash)
    {
        transferHash = uint256(
            keccak256(
                abi.encode(
                    transfer_.invoiceId,
                    transfer_.from,
                    transfer_.to,
                    transfer_.token,
                    transfer_.amount,
                    transfer_.usd
                )
            )
        );
    }

    function _setOperatorAddress(
        address sender_,
        OperatorAddress account_,
        address addr_
    ) internal {
        if (account_ == OperatorAddress.INBOUND_TREASURY) {
            emit OperatorAddressUpdated(
                sender_,
                account_,
                inboundTreasury,
                addr_
            );
            inboundTreasury = addr_;
        } else if (account_ == OperatorAddress.OUTBOUND_TREASURY) {
            emit OperatorAddressUpdated(
                sender_,
                account_,
                outboundTreasury,
                addr_
            );
            outboundTreasury = addr_;
        } else if (account_ == OperatorAddress.SIGNER) {
            emit OperatorAddressUpdated(
                sender_,
                account_,
                certifiedSigner,
                addr_
            );
            certifiedSigner = addr_;
        } else {
            revert("LC:INVALID_ACCOUNT_NAME");
        }
    }

    function _setSecurityLevel(address sender_, SecurityLevel securityLevel_)
        private
    {
        emit SecurityLevelUpdated(sender_, securityLevel, securityLevel_);
        securityLevel = securityLevel_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ConstantsLib.sol";

library FeeMath {
    /**
     * @notice Calculate the processing fee for the given percentage based on the total amount due.
     *
     * @dev baseFee_ and totalPayable_ need to be denominated in the same token.
     *
     * @param baseFee_ the base or 'fixed' fee, denominated in a ERC-20 token.
     * @param feePercentage_ the percentage fee to take. Must be 6 decimal precision.
     * @param totalPayable_ the amount to calculate the fee on, denominated in a ERC-20 token.
     *
     * @return processingFee - the processing fee amount.
     */
    function calculateProcessingFee(
        uint256 baseFee_,
        uint256 feePercentage_,
        uint256 totalPayable_
    ) internal pure returns (uint256 processingFee) {
        processingFee =
            baseFee_ +
            ((totalPayable_ * feePercentage_) / ConstantsLib.FEE_PRECISION);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ConstantsLib.sol";

library TokenMath {
    function convertUsdToTokenAmount(
        uint256 usdAmount_,
        uint256 usdExchangeRate_,
        uint8 exchangeRateDecimals_,
        uint256 tokenDecimals_
    ) internal pure returns (uint256 tokenAmount) {
        // usdAmount_ is in USD cents -> normalize to USD_DECIMALS
        uint256 normalizedUsdAmount = usdAmount_ * 10**6;

        // Normalize exchange rate to USD_DECIMALS
        uint256 _usdExchangeRate = exchangeRateDecimals_ >=
            ConstantsLib.USD_DECIMALS
            ? usdExchangeRate_ /
                (10**(exchangeRateDecimals_ - ConstantsLib.USD_DECIMALS))
            : usdExchangeRate_ *
                (10**(ConstantsLib.USD_DECIMALS - exchangeRateDecimals_));

        tokenAmount =
            (normalizedUsdAmount * 10**ConstantsLib.USD_DECIMALS) /
            _usdExchangeRate;

        // Convert token amount to payment token decimals
        tokenAmount = ConstantsLib.USD_DECIMALS > tokenDecimals_
            ? tokenAmount / 10**(ConstantsLib.USD_DECIMALS - tokenDecimals_)
            : tokenAmount * 10**(tokenDecimals_ - ConstantsLib.USD_DECIMALS);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../interfaces/ICommonState.sol";

/**
 * @title Base contract for commonly used state
 * @author Jonas Sota
 */
abstract contract CommonState is ICommonState, Initializable {
    address public factory;
    address public WETH; // solhint-disable-line var-name-mixedcase

    // solhint-disable-next-line func-name-mixedcase, var-name-mixedcase
    function __CommonState_init(address factory_, address WETH_)
        internal
        onlyInitializing
    {
        factory = factory_;
        WETH = WETH_;
    }

    uint256[18] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

abstract contract Access is AccessControlEnumerable, Initializable {
    bytes32 public constant GOVERNOR_ROLE = keccak256("LC_GOVERNOR");
    bytes32 public constant OPERATOR_ROLE = keccak256("LC_OPERATOR");

    // solhint-disable-next-line func-name-mixedcase
    function __Access_init(address granteeAddress_) internal onlyInitializing {
        _setRoleAdmin(GOVERNOR_ROLE, GOVERNOR_ROLE);
        _setRoleAdmin(OPERATOR_ROLE, OPERATOR_ROLE);
        _grantRole(GOVERNOR_ROLE, granteeAddress_);
        _grantRole(OPERATOR_ROLE, granteeAddress_);
    }

    modifier onlyGovernor() {
        require(hasRole(GOVERNOR_ROLE, msg.sender), "LC:CALLER_NOT_GOVERNOR");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "LC:CALLER_NOT_OPERATOR");
        _;
    }

    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "../interfaces/IProcessorManagerV2.sol";
import "../interfaces/IProcessorValidationManager.sol";
import "./Access.sol";
import "./CommonState.sol";
import "./Constants.sol";

/**
 * @title Base contract for handling processor-related functions
 * @author Shane van Coller, Jonas Sota
 */
abstract contract ProcessorManagerV2 is
    IProcessorManagerV2,
    Ownable,
    Initializable,
    CommonState,
    Constants,
    Access
{
    /**
     * @notice Structure for keeping balances of fees earned for a processor. Balances are kept per token
     * per processor. Fees are accumulated in the token taken for payment
     *
     * @dev Processor Address => Token Address => Token Balance
     */
    mapping(address => mapping(address => uint256)) public processorBalances;

    /**
     * @notice The maximum number of items to process per batch. Prevents unbounded loops and ensures
     * that the transaction will not run out of gas by processing too many items
     */
    uint8 public maxFeeWithdrawalBatchSize;

    /**
     * @notice The base or 'fixed' fee.
     * @dev This value is denominated in USD @ 8 decimal places.
     */
    uint256 public baseFee;

    /**
     * @notice The variable fee.
     *
     * @dev The precision is 1e6, making `1000` equivalent to 0.1%
     */
    uint128 public variableFee;

    event FeesWithdrawn(
        address indexed caller,
        address indexed token,
        uint256 amount,
        uint256 createdAt
    );

    event MaxFeeWithdrawalBatchSizeUpdated(
        address indexed caller,
        uint8 oldValue,
        uint8 newValue,
        uint256 createdAt
    );

    event BaseFeeUpdated(
        address indexed caller,
        uint256 oldValue,
        uint256 newValue,
        uint256 createdAt
    );

    event VariableFeeUpdated(
        address indexed caller,
        uint256 oldValue,
        uint256 newValue,
        uint256 createdAt
    );

    // solhint-disable-next-line func-name-mixedcase
    function __ProcessorManager_init(
        ProcessorManagerInitParams calldata initParams_
    ) internal onlyInitializing {
        baseFee = initParams_.baseFee;
        variableFee = initParams_.variableFee;
        maxFeeWithdrawalBatchSize = initParams_.maxFeeWithdrawalBatchSize;
    }

    /**********************************************/
    /********   MODIFIER FUNCTIONS   *******/
    /**********************************************/
    /**
     * @notice Validates that the given caller is a validated payment processor
     *
     * @dev Can only be called by senders that have been added to the allow list
     *
     */
    modifier onlyValidProcessorExt() {
        require(
            IProcessorValidationManager(factory).validProcessors(msg.sender),
            "LC:CALLER_NOT_ALLOWED"
        );
        _;
    }

    /**********************************************/
    /********   PUBLIC/EXTERNAL FUNCTIONS   *******/
    /**********************************************/
    /**
     * @notice Allows a processor to withdraw their accumulated fees
     *
     * @dev Fees are accumulated per token and balances kept individually for each
     *
     * @param tokenAddresses_ list of token addresses to withdraw the balance from
     */
    function withdrawProcessorFees(address[] calldata tokenAddresses_)
        external
        virtual
    {
        require(
            tokenAddresses_.length <= maxFeeWithdrawalBatchSize,
            "LC:BATCH_SIZE_TOO_BIG"
        );

        for (uint8 i = 0; i < tokenAddresses_.length; i++) {
            address _token = tokenAddresses_[i];
            uint256 _totalFeesForToken = processorBalances[msg.sender][_token];
            require(_totalFeesForToken > 0, "LC:NO_PROCESSOR_FEES");

            processorBalances[msg.sender][_token] = 0;
            TransferHelper.safeTransfer(_token, msg.sender, _totalFeesForToken);

            emit FeesWithdrawn(
                msg.sender,
                _token,
                _totalFeesForToken,
                block.timestamp // solhint-disable-line not-rely-on-time
            );
        }
    }

    /**********************************************/
    /********   GOVERNOR ONLY FUNCTIONS   *********/
    /**********************************************/
    /**
     * @notice Update max number of iterations to process in any given batch
     *
     * @dev Should be small enough as to not reach the block gas limit
     *
     * @param newBatchSize_ new max batch size
     */
    function updateMaxFeeWithdrawalBatchSize(uint8 newBatchSize_)
        external
        onlyGovernor
    {
        emit MaxFeeWithdrawalBatchSizeUpdated(
            msg.sender,
            maxFeeWithdrawalBatchSize,
            newBatchSize_,
            block.timestamp // solhint-disable-line not-rely-on-time
        );
        maxFeeWithdrawalBatchSize = newBatchSize_;
    }

    /**
     * @notice Update the base fee
     *
     * @param newBaseFee_ new base fee
     */
    function updateBaseFee(uint256 newBaseFee_) external onlyGovernor {
        emit BaseFeeUpdated(msg.sender, baseFee, newBaseFee_, block.timestamp); // solhint-disable-line not-rely-on-time
        baseFee = newBaseFee_;
    }

    /**
     * @notice Update the variable fee
     *
     * @param newVariableFee_ new variable fee
     */
    function updateVariableFee(uint128 newVariableFee_) external onlyGovernor {
        emit VariableFeeUpdated(
            msg.sender,
            variableFee,
            newVariableFee_,
            block.timestamp // solhint-disable-line not-rely-on-time
        );
        variableFee = newVariableFee_;
    }

    /**********************************************/
    /***********   INTERNAL FUNCTIONS   ***********/
    /**********************************************/
    /**
     * @notice Calculate the processing fee for the given percentage based on the total amount due.
     *
     * @dev baseFee_ and totalPayable_ need to be denominated in the same token.
     *
     * @param baseFee_ the base or 'fixed' fee, denominated in a ERC-20 token.
     * @param feePercentage_ the percentage fee to take. Must be 6 decimal precision.
     * @param totalPayable_ the amount to calculate the fee on, denominated in a ERC-20 token.
     *
     * @return processingFee - the processing fee amount.
     */
    function _calculateProcessingFee(
        uint256 baseFee_,
        uint256 feePercentage_,
        uint256 totalPayable_
    ) internal virtual returns (uint256 processingFee) {
        processingFee =
            baseFee_ +
            ((totalPayable_ * feePercentage_) / FEE_PRECISION);
    }

    uint256[16] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../interfaces/ITokenManager.sol";
import "./Access.sol";
import "./CommonState.sol";
import "./Constants.sol";

/**
 * @title Base contract for handling the token whitelist
 * @author Shane van Coller, Jonas Sota
 */
abstract contract TokenManagerV2 is
    ITokenManager,
    Ownable,
    Initializable,
    CommonState,
    Constants,
    Access
{
    using SafeCast for int256;
    using SafeCast for uint256;

    /**
     * @dev List of addresses of the tokens that are accepted as payment for the subscription.
     * Only tokens in this list will be accepted as payment when subscribing, all other tokens
     * will be rejected
     */
    address[] public acceptedTokensList;

    /**
     * @dev Details for each of the accepted tokens including how much has accumulated to it. Each
     * token has the following attributes:
     *
     * uint8 accepted - non zero value indicates that the token is accepted as payment. The actual
     * value represent the idx of the token in the array
     * AggregatorV3Interface chainlinkAggregator - address of the aggregator to get price info
     */
    mapping(address => TokenDetails) public tokenInfo;

    struct TokenDetails {
        uint8 accepted;
        AggregatorV3Interface chainlinkAggregator;
    }

    event TokenAdded(
        address indexed caller,
        address newToken,
        address chainlinkAggregator,
        uint256 createdAt
    );

    event TokenRemoved(
        address indexed caller,
        address removedToken,
        uint256 createdAt
    );

    // solhint-disable-next-line func-name-mixedcase
    function __TokenManager_init(
        address[] calldata acceptedTokens_,
        address[] calldata chainlinkAggregators_
    ) internal onlyInitializing {
        require(
            acceptedTokens_.length != 0 && chainlinkAggregators_.length != 0,
            "LC:MISSING_TOKEN_INFO"
        );
        _addTokens(acceptedTokens_, chainlinkAggregators_);
    }

    /*************************************************/
    /*************   EXTERNAL  GETTERS   *************/
    /*************************************************/
    /**
     * @notice Gets the number of accepted payment tokens
     *
     * @return number of payment tokens
     */
    function getAcceptedTokensCount() external view returns (uint256) {
        return acceptedTokensList.length;
    }

    /**********************************************/
    /*********   OPERATOR ONLY FUNCTIONS   ********/
    /**********************************************/
    /**
     * @notice Add a new payment token option
     *
     * @param tokens_ address of tokens to accept
     * @param chainlinkAggregators_ address of the chainlink aggregators
     */
    function addTokens(
        address[] calldata tokens_,
        address[] calldata chainlinkAggregators_
    ) external onlyOperator {
        _addTokens(tokens_, chainlinkAggregators_);
    }

    /**
     * @notice Remove a payment token option
     *
     * @param tokens_ address of token to remove
     */
    function removeTokens(address[] calldata tokens_) external onlyOperator {
        for (uint8 i = 0; i < tokens_.length; i++) {
            require(
                tokenInfo[tokens_[i]].accepted > 0,
                "LC:TOKEN_NOT_ACCEPTED"
            );

            uint256 removedIdx = tokenInfo[tokens_[i]].accepted - 1;
            address lastTokenAddress = acceptedTokensList[
                acceptedTokensList.length - 1
            ];
            tokenInfo[lastTokenAddress].accepted = (removedIdx + 1).toUint8();
            tokenInfo[tokens_[i]].accepted = 0;
            acceptedTokensList[removedIdx] = lastTokenAddress;
            acceptedTokensList.pop();

            emit TokenRemoved(msg.sender, tokens_[i], block.timestamp); // solhint-disable-line not-rely-on-time
        }
    }

    /**********************************************/
    /*******   INTERNAL/PRIVATE FUNCTIONS   *******/
    /**********************************************/
    /**
     * @notice Add a new payment token option
     *
     * @param tokens_ address of tokens to accept
     * @param chainlinkAggregators_ address of the chainlink aggregators
     */
    function _addTokens(
        address[] calldata tokens_,
        address[] calldata chainlinkAggregators_
    ) private {
        require(
            tokens_.length == chainlinkAggregators_.length,
            "LC:PRICE_FEED_PARITY_MISMATCH"
        );

        for (uint8 i = 0; i < tokens_.length; i++) {
            require(
                tokenInfo[tokens_[i]].accepted == 0,
                "LC:TOKEN_ALREADY_ACCEPTED"
            );
            require(
                chainlinkAggregators_[i] != address(0),
                "LC:INVALID_AGGREGATOR"
            );

            acceptedTokensList.push(tokens_[i]);

            TokenDetails storage tokenDetails = tokenInfo[tokens_[i]];
            tokenDetails.accepted = (acceptedTokensList.length).toUint8();
            tokenDetails.chainlinkAggregator = AggregatorV3Interface(
                chainlinkAggregators_[i]
            );

            emit TokenAdded(
                msg.sender,
                tokens_[i],
                chainlinkAggregators_[i],
                block.timestamp // solhint-disable-line not-rely-on-time
            );
        }
    }

    /**
     * @notice Gets the exchange rate to USD for a given token
     *
     * @param token_ address of token to get the exchange rate for
     *
     * @return exchangeRate Number of dollars per token
     * @return decimals Decimals of the exchangeRate figure, typically 8
     */
    function _getTokenToUsdRate(address token_)
        internal
        view
        returns (uint256 exchangeRate, uint8 decimals)
    {
        if (token_ == address(0)) {
            token_ = WETH;
        }
        AggregatorV3Interface chainlinkAggregator = tokenInfo[token_]
            .chainlinkAggregator;
        (, int256 usdToTokenRate, , , ) = chainlinkAggregator.latestRoundData();

        exchangeRate = (usdToTokenRate).toUint256();
        decimals = chainlinkAggregator.decimals();
    }

    /**
     * @notice Converts the USD value to the equivalent token value
     *
     * @dev - USD amount must be 8 decimal precision
     *
     * @param token_ Address of the token to convert to
     * @param usdAmount_ USD amount to convert from
     *
     * @return tokenAmount Token equivalent value
     * @return exchangeRate Number of dollars per token
     */
    function _convertUsdToTokenAmount(address token_, uint256 usdAmount_)
        internal
        view
        returns (uint256 tokenAmount, uint256 exchangeRate)
    {
        (
            uint256 _usdExchangeRate,
            uint8 _exchangeDecimals
        ) = _getTokenToUsdRate(token_);

        uint256 _tokenDecimals = IERC20Metadata(token_).decimals();

        // Normalize exchange rate to USD_DECIMALS
        _usdExchangeRate = _exchangeDecimals >= USD_DECIMALS
            ? _usdExchangeRate / (10**(_exchangeDecimals - USD_DECIMALS))
            : _usdExchangeRate * (10**(USD_DECIMALS - _exchangeDecimals));

        tokenAmount = (usdAmount_ * 10**USD_DECIMALS) / _usdExchangeRate;

        // Convert token amount to payment token decimals
        tokenAmount = USD_DECIMALS > _tokenDecimals
            ? tokenAmount / 10**(USD_DECIMALS - _tokenDecimals)
            : tokenAmount * 10**(_tokenDecimals - USD_DECIMALS);
        exchangeRate = _usdExchangeRate;
    }

    uint256[18] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IVariableRateTransfers {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Transfer {
        string id;
        string invoiceId;
        address from;
        address to;
        address token;
        uint256 amount;
        bool usd;
    }

    struct TransferParams {
        Transfer data;
        Signature signature;
    }

    struct OperatorInitParams {
        address inboundTreasury;
        address outboundTreasury;
        address signer;
    }

    enum SecurityLevel {
        DIRECT,
        PLATFORM
    }

    enum OperatorAddress {
        INBOUND_TREASURY,
        OUTBOUND_TREASURY,
        SIGNER
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../interfaces/IVariableRateTransfers.sol";
import "../../libraries/ChainUtils.sol";

contract SigUtils {
    bytes32 private constant DOMAIN_SEPARATOR =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 private constant TRANSFER_TYPEHASH =
        keccak256(
            "Transfer(string invoiceId,address from,address to,address token,uint256 amount,bool usd)"
        );

    // TODO set in initialize fxn?
    string public constant NAME = "LoopVariableRatesContract";
    string public constant VERSION = "1";

    function _generateDigest(
        IVariableRateTransfers.Transfer calldata transfer_,
        address contract_
    ) internal view returns (bytes32 digest) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_SEPARATOR,
                keccak256(bytes(NAME)),
                keccak256(bytes(VERSION)),
                ChainUtils.getChainId(),
                contract_
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                TRANSFER_TYPEHASH,
                keccak256(bytes(transfer_.invoiceId)),
                transfer_.from,
                transfer_.to,
                transfer_.token,
                transfer_.amount,
                transfer_.usd
            )
        );

        digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
    }

    function _getSigner(
        IVariableRateTransfers.Transfer calldata transfer_,
        IVariableRateTransfers.Signature calldata signature_
    ) internal view returns (address signer) {
        bytes32 digest = _generateDigest(transfer_, address(this));
        signer = ecrecover(digest, signature_.v, signature_.r, signature_.s);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library ConstantsLib {
    uint256 public constant FEE_PRECISION = 1e6;
    uint256 public constant SLIPPAGE_PRECISION = 1e6;
    uint256 public constant USD_DECIMALS = 8;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ICommonState {
    struct CommonStateInitParams {
        address factory;
        address WETH;
    }

    function WETH() external returns (address); // solhint-disable-line func-name-mixedcase

    function factory() external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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
pragma solidity 0.8.10;

interface IProcessorManagerV2 {
    struct ProcessorManagerInitParams {
        uint256 baseFee;
        uint128 variableFee;
        uint8 maxFeeWithdrawalBatchSize;
    }

    function processorBalances(address processor_, address token_)
        external
        returns (uint256 balance);

    function maxFeeWithdrawalBatchSize() external returns (uint8 batchSize);

    function withdrawProcessorFees(address[] calldata tokens_) external;

    function updateMaxFeeWithdrawalBatchSize(uint8 newBatchSize_) external;

    function updateBaseFee(uint256 newBaseFee_) external;

    function updateVariableFee(uint128 newVariableFee_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IProcessorValidationManager {
    function validProcessors(address) external returns (bool);

    function validateProcessors(address[] calldata) external;

    function invalidateProcessors(address[] calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title Base contract for managing commonly-used constants
 * @author Jonas Sota
 */

// TODO deprecate for Constants library
abstract contract Constants {
    uint256 public constant FEE_PRECISION = 1e6;
    uint256 public constant SLIPPAGE_PRECISION = 1e6;
    uint256 public constant USD_DECIMALS = 8;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface ITokenManager {
    struct TokenManagerInitParams {
        address[] acceptedTokens;
        address[] chainlinkAggregators;
    }

    function acceptedTokensList(uint256 index_)
        external
        returns (address token);

    function tokenInfo(address token_)
        external
        returns (uint8 accepted, AggregatorV3Interface chainlinkAggregator);

    function getAcceptedTokensCount()
        external
        view
        returns (uint256 tokenCount);

    function addTokens(
        address[] calldata tokens_,
        address[] calldata chainlinkAggregators_
    ) external;

    function removeTokens(address[] calldata tokens_) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library ChainUtils {
    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}