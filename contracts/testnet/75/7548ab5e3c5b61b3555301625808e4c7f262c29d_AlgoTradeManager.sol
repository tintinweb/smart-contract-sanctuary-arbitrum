// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../Base/AlgoTradingHandler.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {GelatoRelayContext} from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";
import {IPolicyManager} from "../Interfaces/IPolicyManager.sol";
import {IPolicy} from "../policies/IPolicy.sol";
import {ITradingExtension} from "../Interfaces/ITradingExtension.sol";
import {ITradingExtensionV2, Price} from "../Interfaces/ITradingExtensionV2.sol";
import {UtilLib} from "../libraries/UtilLib.sol";
import "../libraries/Errors.sol";

/**
 * @title AlgoTradeManager
 *
 * This contract implements functionalities such as follow, unfollow, deposit, withdraw, partial-withdraw
 * copy v1 and v2 trades, force-copy already opened positions of the followed trader
 *
 * - User calls deployAlgoTradeManager function on FundManagerFactory contract and deploys this strategy contract
 *   with this function call, the User can set the below details:
 * 1. followed or master trader
 * 2. Policy Setting Parameters (such as max amount per trade, trade factor, Max-Min leverage, etc.)
 * whose trades should be copied, and invest initial amount (in usdc/usdc.e)
 *
 */
contract AlgoTradeManager is AlgoTradingHandler, GelatoRelayContext {
    using SafeMath for uint256;

    ITradingExtension private tradingExtension;

    ITradingExtensionV2 private tradingExtensionV2;

    event Follow(address followedTrader);

    event Unfollow(address unfollowedTrader);

    event WithdrawFunds(address user, uint256 fundsValue);

    event PartialWithdraw(address user, uint256 fundsValue, uint256 totalGav);

    /**@notice Initializer function for the contract
    @dev initialize function for the wrapper implementation contract with initializer modifier established
    @param _configAddresses array of addresses of USDC, fundDeployer, integrationManager and externalPositionManager
    @param _user deployer Address,
    */
    function init(
        address[] memory _configAddresses,
        address _user,
        uint256 _shareActionTimeLock,
        uint256 _shareActionBlockNumberLock
    ) public initializer {
        uint256 _configLength = _configAddresses.length;

        for (uint256 i; i < _configLength; ) {
            UtilLib.checkNonZeroAddress(_configAddresses[i]);
            unchecked {
                ++i;
            }
        }
        __ReentrancyGuard_init();

        unchecked {
            ALFRED_FACTORY = msg.sender;
            strategyCreator = _user;
            shareActionTimeLock = _shareActionTimeLock;
            shareActionBlockNumberLock = _shareActionBlockNumberLock;

            denominationAsset = _configAddresses[0];
            //ToDo: All these addreses will be stored in projectConfig by factory owner in the future
            // and read from the projectConfig variable, so that any malicious address can't be set
            FUND_DEPLOYER = _configAddresses[1];
            gmxHelper = IGmxHelper(_configAddresses[2]);
            policyManager = _configAddresses[3];
            tradingExtension = ITradingExtension(_configAddresses[4]);
            // removing opengsn contract suppot
            // _setTrustedForwarder(_configAddresses[5]);
            //TODO: Set this address in projectConfig mapping in factory contract
            tradingExtensionV2 = ITradingExtensionV2(_configAddresses[6]);
        }
    }

    /**
     * @notice Function to deploy vault and invest in a strategy without ERC20 Permit Approval
     *  @dev atomic function to create a vault, deposit assets, swap for required assets,
     *  mint shares of the vault and add liquidity for a strategy
     *  @param _fundName The name of the fund's shares token
     *  @param _fundSymbol The symbol of the fund's shares token
     *  @param _feeManagerConfigData Bytes data for the fees to be enabled for the fund
     *  @param _policyManagerConfigData Bytes data for the policies to be enabled for the fund
     *  @param _amount the amount of USDC being deposited
     *  @param _swapArgs The array of arguments for swap calls on an extension of the enzyme protocol
     *  @param _positionArgs The array of arguments for external position calls
     *         using an extension of the enzyme protocol
     *  @param _followingTraders list of following traders
     */
    function fundDeploy(
        string memory _fundName,
        string memory _fundSymbol,
        bytes memory _feeManagerConfigData,
        bytes memory _policyManagerConfigData,
        uint256 _amount,
        ExtensionArgs[] memory _swapArgs,
        ExtensionArgs[] memory _positionArgs,
        address[] memory _followingTraders
    ) external isFactory nonReentrant {
        // Creates new vault for the user
        (address comptrollerProxy_, address vaultProxy_) = createNewFund(
            _fundName,
            _fundSymbol,
            shareActionTimeLock,
            _feeManagerConfigData,
            _policyManagerConfigData,
            strategyCreator
        );

        vaultProxy = vaultProxy_;

        setupNewFund(
            comptrollerProxy_,
            strategyCreator,
            _amount,
            _swapArgs,
            _positionArgs
        );

        uint256 _tradersLength = _followingTraders.length;

        if (_tradersLength != 0) {
            for (uint256 i; i < _tradersLength; ++i) {
                _follow(_followingTraders[i]);
            }
        }
    }

    /**@notice This function is used for following the master trader
    @param trader_ Trader address to be followed,
    */
    function follow(address trader_) external isCreator {
        _follow(trader_);
    }

    /**@notice This function is used to unfollow the master trader
     */
    function unfollow() external isCreator {
        _unfollow();
    }

    //ToDO: This function will get removed in later releases
    function setTradingExtension(
        address _tradingExtension,
        uint256 _typeId
    ) external {
        require(
            msg.sender == IFundManagerFactory(getFundManagerFactory()).owner(),
            "setTradingExtension: Invalid caller"
        );
        if (_typeId == 1)
            tradingExtension = ITradingExtension(_tradingExtension);
        else if (_typeId == 2)
            tradingExtensionV2 = ITradingExtensionV2(_tradingExtension);
    }

    /**
     * @notice an invester can deposit denomination asset to add funds to take positions in a deployed vault
     * @dev transfers USDC to the contract and approves the amount for enzymes vault
     * @param _swapArgs swap assets payload
     * @param _positionArgs position data payload
     * @param _amount the amount of USDC being deposited
     */
    function deposit(
        uint256 _amount,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        ExtensionArgs[] memory _swapArgs,
        ExtensionArgs[] memory _positionArgs
    ) external isCreator nonReentrant {
        address _comptrollerProxy = __getComptrollerProxyForVault(vaultProxy);
        //deposit funds in the vault,
        if (_amount != 0) {
            _permitTransfer(msg.sender, _amount, _deadline, v, r, s);
            bool successfulApproval = IERC20(denominationAsset).approve(
                _comptrollerProxy,
                _amount
            );
            require(successfulApproval, "addFund:approval failed");

            // buy user's shares on behalf
            uint256 sharesReceived_ = _buyShares(
                msg.sender,
                _comptrollerProxy,
                _amount
            );

            emit FundsAdded(msg.sender, _amount, sharesReceived_);
        }

        addFund(_comptrollerProxy, _swapArgs, _positionArgs);
    }

    /**
     * @notice This function is used to copy trades of followed trader (Gmx-V1)
     * @dev It can be called by anyone
     * @param txData The transaction data object containing information of trader's trade
     * @param v, @param r, and @param s, v, r, s parameters corresponding to transaction data object (Signed by backend signer)
     * @param _swapArgs The structured data for a swap call on an extension of the enzyme contract
     */
    function executeTradeFromSigner(
        TransactionMetaData calldata txData,
        uint8 v,
        bytes32 r,
        bytes32 s,
        ExtensionArgs[] memory _swapArgs
    ) external {
        _executeTradeInternal(txData, v, r, s, _swapArgs);
    }

    /**
     * @notice This function is used to copy a trade for gmx-v1 trader (Gmx-V1) via a backend indexer
     * @dev It can only be called by gelato relay
     * @param txData The transaction data object containing information of trader's trade
     * @param v, @param r, and @param s, v, r, s parameters corresponding to transaction data (Signed by backend signer)
     * @param _swapArgs The structured data for a swap call on an extension of the enzyme contract
     */
    function executeTrade(
        TransactionMetaData calldata txData,
        uint8 v,
        bytes32 r,
        bytes32 s,
        ExtensionArgs[] memory _swapArgs
    ) external onlyGelatoRelay {
        _executeTradeInternal(txData, v, r, s, _swapArgs);

        //withdraw USDC from vault for relayer fee
        IVault(vaultProxy).withdrawAsset(
            denominationAsset,
            address(this),
            _getFee()
        );

        //hardcoded fee cap value
        _transferRelayFeeCapped(10e6);
    }

    /**
     * @notice This function is used to copy a trade for gmx-v2 trader (Gmx-V2) via a backend indexer
     * @dev It can only be called by gelato relay
     * @param txData The transaction data object containing information of trader's trade
     * @param v, @param r, and @param s, v, r, s parameters corresponding to transaction data object (Signed by backend signer)
     * @param _swapArgs The structured data for a swap call on an extension of the enzyme contract
     */
    function executeTradeOnGmxV2(
        TransactionMetaDataV2 calldata txData,
        uint8 v,
        bytes32 r,
        bytes32 s,
        ExtensionArgs[] memory _swapArgs
    ) external onlyGelatoRelay {
        _executeTradeInternalV2(txData, v, r, s, _swapArgs);

        //withdraw USDC from vault for relayer fee
        IVault(vaultProxy).withdrawAsset(
            denominationAsset,
            address(this),
            _getFee()
        );
        //hardcoded fee cap value
        _transferRelayFeeCapped(10e6);
    }

    /**
     * @notice This function helps in copying an already opened trade of the followed trader (GMX-V1)
     * @dev It can only be called by strategy creator
     * @param collateralTokens an array of collateral tokens of opened positions of followed trader
     * @param indexTokens an array of index tokens of opened positions of the followed trader
     * @param positionTypes an array of position types of opened positions of the followed trader
     */
    function executeForceTrade(
        address[] memory collateralTokens,
        address[] memory indexTokens,
        bool[] memory positionTypes
    ) external isCreator {
        address comptrollerProxy_ = __getComptrollerProxyForVault(vaultProxy);

        address trader = followedTrader;
        address externalPosition = IVault(vaultProxy)
            .getActiveExternalPositions()[0];

        (
            bool canExec,
            string memory message,
            bytes[] memory actionArgs
        ) = tradingExtension.validateForceTradeData(
                address(this),
                externalPosition,
                indexTokens,
                collateralTokens,
                positionTypes
            );

        require(canExec, message);

        for (uint256 i; i < indexTokens.length; ++i) {
            _buildTransaction(
                trader,
                indexTokens[i],
                collateralTokens[i],
                comptrollerProxy_,
                externalPosition,
                positionTypes[i],
                bytes4(0xf2ae372f), //IPositionRouter.CreateIncreasePosition.selector
                actionArgs[i]
            );
        }
    }

    /**
     * @notice This function helps in copying an already opened trade of the followed trader (Gmx-v2)
     * @dev It can only be called by strategy creator
     * @param collateralTokens an array of collateral tokens of opened positions of followed trader
     * @param markets an array of gmx-v2 markets of opened positions of the followed trader
     * @param positionTypes an array of position types of opened positions of the followed trader
     * @param prices an array of market prices of the collateral tokens
     */
    function executeForceTradeV2(
        address[] calldata collateralTokens,
        address[] calldata markets,
        bool[] calldata positionTypes,
        Price.Props[] calldata prices
    ) external isCreator {
        //ToDo: Add a check of all these arrays of should be same
        address comptrollerProxy_ = __getComptrollerProxyForVault(vaultProxy);

        address trader = followedTrader;

        address externalPosition = IVault(vaultProxy)
            .getActiveExternalPositions()[0];

        (
            bool canExec,
            string memory message,
            bytes[] memory actionArgs
        ) = tradingExtensionV2.validateForceTradeData(
                address(this),
                trader,
                externalPosition,
                collateralTokens,
                markets,
                positionTypes,
                prices
            );

        require(canExec, message);

        ExtensionArgs memory positionArgs;

        address _externalPositionManager = IComptroller(comptrollerProxy_)
            .getExternalPositionManager();

        uint256 count = actionArgs.length;

        for (uint256 i; i < count; ++i) {
            positionArgs = BaseStorage.ExtensionArgs({
                _extension: _externalPositionManager,
                _actionId: uint256(1), //Call On External Position
                _callArgs: abi.encode(externalPosition, 0, actionArgs[i]) // '0' here refers to create gmxV2 order
            });
            //call comptroller proxy
            _externalPositionsInternal(comptrollerProxy_, positionArgs);

            bytes memory data = abi.encode(
                collateralTokens[i],
                markets[i],
                positionTypes[i]
            );
            if (!shouldStartCopy[trader][data])
                shouldStartCopy[trader][data] = true;
        }
    }

    /**
     * @notice This function is used to validate trader transaction details and determine
     * whether to copy the trade or not
     * @dev This function calls on TradingExtension contract to validate trade data
     * @param _externalPosition an address that takes positions on gmx-v1
     * @param trader The followed trader
     * @param selector function selector of gmx-v1 position router contract
     * @param _path an array of input token path in context to gmx-v1
     * @param indexToken index token address corresponding to trader's position
     * @param collateralDelta collateral amount change in trader's position
     * @param sizeDelta position size change in trader's position
     * @param isLong position type
     * @param executionFee gmx-v1 execution fee incurred in trader's transaction
     * @return canExec This boolean variable indicates whether to copy this trade or not
     * @return message if canExec true, then success message will populate, otherwise, error codes will popultate
     * @return execPayload execution payload
     */
    function validateTradeData(
        address _externalPosition,
        address trader,
        bytes4 selector,
        address[] memory _path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 executionFee
    )
        public
        returns (bool canExec, string memory message, bytes memory execPayload)
    {
        (canExec, message, execPayload) = tradingExtension.validateTradeData(
            address(this),
            _externalPosition,
            trader,
            selector,
            _path,
            indexToken,
            collateralDelta,
            sizeDelta,
            isLong,
            executionFee
        );
    }

    /**
     * @notice This function is used to validate trader transaction details and determine
     * whether to copy the trade or not
     * @dev This function calls on TradingExtensionV2 contract to validate trade data
     * @param data encoded data containing fundmanager address, external position, and trader
     * @param addresses an array containing collateral token and market addresses
     * @param collateralDeltaUsd collateral amount change (in usd) in trader's position
     * @param sizeDeltaUsd position size change in trader's position
     * @param isLong position type
     * @param executionFee gmx-v1 execution fee incurred in trader's transaction
     * @param numbers encoded data containing sizeUsd, collateralUsd, executionPrice,
     * CollateralTokenPriceMin and collateralTokenPriceMax
     * @param orderType order type as gmx-v2 e.g., 2 -> MarketIncrease, 4 -> MarketDecrease
     * @return canExec This boolean variable indicates whether to copy this trade or not
     * @return message if canExec true, then success message will populate, otherwise, error codes will popultate
     * @return execPayload execution payload
     */
    function validateTradeDataForGmxV2(
        bytes memory data, //abi.encode(_fundmanager, externalPosition, trader)
        address[] memory addresses,
        uint256 collateralDeltaUsd,
        uint256 sizeDeltaUsd,
        bool isLong,
        uint256 executionFee,
        bytes memory numbers,
        uint8 orderType
    )
        public
        returns (bool canExec, string memory message, bytes memory execPayload)
    {
        (canExec, message, execPayload) = tradingExtensionV2
            .validateTradeDataForGmxV2(
                data,
                addresses,
                collateralDeltaUsd,
                sizeDeltaUsd,
                isLong,
                executionFee,
                numbers,
                orderType
            );
    }

    ////////////////////
    //CallBack Functions//
    ////////////////////
    function successCallBack() external {
        require(
            msg.sender == IVault(vaultProxy).getActiveExternalPositions()[0],
            "invalid caller"
        );

        if (pendingTxHash != "") {
            require(
                !relayedTxns[pendingTxHash].status,
                "successCallBack:already executed"
            );
            relayedTxns[pendingTxHash].status = true;
            relayedTxns[pendingTxHash].retryCount += 1;
            pendingTxHash = "";
        }
    }

    function failCallBack() external {
        require(
            msg.sender == IVault(vaultProxy).getActiveExternalPositions()[0],
            "invalid caller"
        );

        if (pendingTxHash != "") {
            require(
                !relayedTxns[pendingTxHash].status,
                "failCallBack: already executed"
            );
            relayedTxns[pendingTxHash].retryCount += 1;
            // emit TransactionNotCopied(pendingTxHash);
            pendingTxHash = "";
        }
    }

    ////////////////////
    // Close Position//
    ////////////////////
    /**
     * @notice This function is used to close the positions and to unfollow the trader
     * @param withdrawArgs It is used to close positions
     * @param _swapArgs The structured data for a swap call on an extension of the enzyme contract
     */
    function closeOpenPositions(
        ExtensionArgs[] memory withdrawArgs,
        ExtensionArgs[] memory _swapArgs
    ) external isCreator {
        uint256 iterations = withdrawArgs.length;

        require(
            iterations != 0 || followedTrader != address(0),
            "invalid action"
        );

        if (followedTrader != address(0)) _unfollow();

        address _comptrollerProxy = __getComptrollerProxyForVault(vaultProxy);

        address externalPosition = IVault(vaultProxy)
            .getActiveExternalPositions()[0];

        if (_swapArgs.length != 0)
            _callOnIntegration(_comptrollerProxy, _swapArgs);

        if (
            IExternalPositionProxy(externalPosition)
                .getExternalPositionType() == uint256(0)
        ) {
            if (iterations != 0)
                for (uint256 i; i < iterations; ) {
                    _externalPositionsInternal(
                        _comptrollerProxy,
                        withdrawArgs[i]
                    );
                    unchecked {
                        ++i;
                    }
                }
        } else if (
            IExternalPositionProxy(externalPosition)
                .getExternalPositionType() == uint256(2)
        ) {
            bytes[] memory actionArgs = tradingExtensionV2.getClosePositionArgs(
                address(this),
                externalPosition
            );
            iterations = actionArgs.length;
            //ToDO: add a check of weth balance in vault sufficient for closing all the positions
            for (uint256 i; i < iterations; ++i) {
                _callOnGmxV2(
                    actionArgs[i],
                    _comptrollerProxy,
                    externalPosition
                );
            }
            _claimFundingFees(_comptrollerProxy, externalPosition);
        }
    }

    ////////////////////
    // Withdraw funds //
    ////////////////////

    /**
     * @notice This function is used to withdraw funds from vault contract to user's address
     * @param _withdrawArgs It is used to transfer funds from external position to vault contract
     * @param redeemInUsdc redeemInUsdc can be 0 or 1
     * @param _swapArgs The structured data for a swap call on an extension of the enzyme contract
     */
    function withdrawFunds(
        ExtensionArgs[] memory _withdrawArgs,
        uint256 redeemInUsdc,
        ExtensionArgs[] memory _swapArgs
    ) external isCreator {
        address _canonicalSender = msg.sender;

        __assertSharesActionNotlocked(_canonicalSender);

        address _comptrollerProxy = __getComptrollerProxyForVault(vaultProxy);

        uint256 iterations = _withdrawArgs.length;

        for (uint256 i; i < iterations; ++i) {
            _externalPositionsInternal(_comptrollerProxy, _withdrawArgs[i]);
        }

        uint256 fundsValue = IComptroller(_comptrollerProxy).calcGav();
        //redeemShares
        if (redeemInUsdc == uint256(1)) {
            if (_swapArgs.length != 0) {
                _callOnIntegration(_comptrollerProxy, _swapArgs);
            }
            //Only redeeem in usdc available
            _redeemInUsdc(
                _canonicalSender,
                _comptrollerProxy,
                type(uint256).max
            );
        } else {
            _redeemAssets(
                _canonicalSender,
                _comptrollerProxy,
                type(uint256).max
            );
        }
        emit WithdrawFunds(_canonicalSender, fundsValue);
        //deleting the share action snapshot details of user after withdraw funds
        delete acctToLastSharesBought[_canonicalSender];
    }

    /**
     * @notice This function is used to partial withdraw funds from vault contract to user's address
     * @param _withdrawArgs It is used to transfer funds from external position to vault contract
     * @param redeemInUsdc redeemInUsdc can be 0 or 1
     * @param _swapArgs The structured data for a swap call on an extension of the enzyme contract
     */
    function partialWithdraw(
        ExtensionArgs[] memory _withdrawArgs,
        uint256 redeemInUsdc,
        ExtensionArgs[] memory _swapArgs,
        uint256 sharesToRedeem
    ) external isCreator {
        address _canonicalSender = msg.sender;

        address _comptrollerProxy = __getComptrollerProxyForVault(vaultProxy);

        uint256 totalSupply = IERC20(vaultProxy).totalSupply();

        uint256 iterations = _withdrawArgs.length;

        for (uint256 i; i < iterations; ++i)
            _externalPositionsInternal(_comptrollerProxy, _withdrawArgs[i]);

        require(sharesToRedeem <= totalSupply, "withdrawFunds: invalid shares");

        uint256 totalGav = IComptroller(_comptrollerProxy).calcGav();

        uint256 sharesValue = totalGav.mul(sharesToRedeem).div(totalSupply);

        if (sharesToRedeem == totalSupply && followedTrader != address(0))
            _unfollow();

        if (_swapArgs.length != 0)
            _callOnIntegration(_comptrollerProxy, _swapArgs);

        //redeemShares
        if (redeemInUsdc == uint256(1)) {
            require(
                sharesValue <= IERC20(denominationAsset).balanceOf(vaultProxy),
                "insufficient usdc available"
            );
            //Only redeeem in usdc available
            _redeemInUsdc(_canonicalSender, _comptrollerProxy, sharesToRedeem);
        } else {
            _redeemAssets(_canonicalSender, _comptrollerProxy, sharesToRedeem);
        }

        emit PartialWithdraw(_canonicalSender, sharesValue, totalGav);
    }

    ///////////////////////////////////
    // Private and Internal Functions//
    //////////////////////////////////
    /**
     * @notice Function to mint vault shares, and swap assets
     *  @param _comptrollerProxy comptroller of deployed vault
     *  @param _buyer address where the shares are minted
     *  @param _amount the amount of USDC being deposited
     *  @param _swapArgs The array of arguments for swap calls on an extension of the enzyme protocol
     *  @param _positionArgs The array of arguments for external position calls
     *          using an extension of the enzyme protocol
     */
    function setupNewFund(
        address _comptrollerProxy,
        address _buyer,
        uint256 _amount,
        ExtensionArgs[] memory _swapArgs,
        ExtensionArgs[] memory _positionArgs
    ) private {
        uint256 sharesReceived = _buyShares(_buyer, _comptrollerProxy, _amount);

        // Swaps USDC for required assets
        _callOnIntegration(_comptrollerProxy, _swapArgs);

        // Take position as per the strategy
        _createExternalPositions(_comptrollerProxy, _positionArgs);

        emit FundsAdded(_buyer, _amount, sharesReceived);
    }

    /**
     * @notice Add funds to the vault
     * @dev private funcion which calls external position to take further gmx or uniswapv3 positions
     * @custom:calledfrom addFund function
     * @custom:enzymecall internal call on enzyme's callOnExtension function
     * @param _comptrollerProxy fund Accessor
     * @param _swapArgs The structured data for a swap call on an extension of the enzyme protocol
     * @param _positionArgs The structured data for a position call on an extension of the enzyme protocol
     */
    function addFund(
        address _comptrollerProxy,
        ExtensionArgs[] memory _swapArgs,
        ExtensionArgs[] memory _positionArgs
    ) private {
        // Swaps denomination asset for required assets
        if (_swapArgs.length != 0) {
            _callOnIntegration(_comptrollerProxy, _swapArgs);
        }
        // Take position as per the strategy
        if (_positionArgs.length != 0) {
            for (uint256 i; i < _positionArgs.length; ) {
                _externalPositionsInternal(_comptrollerProxy, _positionArgs[i]);
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice a function called for swapping tokens
     * @param _comptrollerProxy enzyme comptroller proxy
     * @param _swapArgs The structured data for a swap call on an extension of the enzyme contract
     */
    function _swap(
        address _comptrollerProxy,
        ExtensionArgs[] memory _swapArgs
    ) private {
        if (_swapArgs.length != 0)
            _callOnIntegration(_comptrollerProxy, _swapArgs);
    }

    function _follow(address trader_) private {
        UtilLib.checkNonZeroAddress(trader_);
        require(trader_ != address(this), "_follow:Invalid");

        require(followedTrader != trader_, "_follow: already followed");
        followedTrader = trader_;
        IFundManagerFactory(getFundManagerFactory()).addStrategy();
        emit Follow(trader_);
    }

    function _unfollow() private {
        require(followedTrader != address(0), "unfollow: invalid request");
        address trader_ = followedTrader;
        IFundManagerFactory(getFundManagerFactory()).removeStrategy();

        followedTrader = address(0);

        emit Unfollow(trader_);
    }

    /**
     * @notice a function called from executeTrade external call
     * @param txData The transaction object containing trader transaction data
     * @param v, @param r, and @param s, v, r, s parameters corresponding to transaction data (Signed by backend signer)
     * @param _swapArgs The structured data for a swap call on an extension of the enzyme contract
     */
    function _executeTradeInternal(
        TransactionMetaData calldata txData,
        uint8 v,
        bytes32 r,
        bytes32 s,
        ExtensionArgs[] memory _swapArgs
    ) private {
        bool result = validateSigner(txData, v, r, s);

        require(result, "_executeTradeInternal: Signer not recognized");

        address vaultProxyCopy = vaultProxy;

        address _comptrollerProxy = __getComptrollerProxyForVault(
            vaultProxyCopy
        );

        if (_swapArgs.length != 0) {
            _callOnIntegration(_comptrollerProxy, _swapArgs);
        }

        (
            bytes4 selector,
            bytes32 txHash,
            bool isLong,
            address trader,
            address[] memory path,
            address indexToken,
            uint256 amountIn,
            uint256 sizeDelta,
            uint256 executionFee
        ) = _decodeCalldata(txData);

        require(
            !relayedTxns[txHash].status,
            Errors.RELAYED_TRANSACTION_ALREADY_EXECUTED //This txHash is already executed
        );

        address externalPosition = IVault(vaultProxyCopy)
            .getActiveExternalPositions()[0];

        //call validation function
        (
            bool canExec,
            string memory message,
            bytes memory actionArgs
        ) = validateTradeData(
                externalPosition,
                trader,
                selector,
                path,
                indexToken,
                amountIn,
                sizeDelta,
                isLong,
                executionFee
            );

        require(canExec, message);

        _buildTransaction(
            trader,
            indexToken,
            UtilLib.getCollateralToken(path, selector),
            _comptrollerProxy,
            externalPosition,
            isLong,
            selector,
            actionArgs
        );
        pendingTxHash = txHash;
    }

    /**
     * @notice an internal function called from executeTradeOnGmxV2 external call
     * @param txData The transaction object containing trader transaction data
     * @param v, @param r, and @param s, v, r, s parameters corresponding to transaction data object (Signed by backend signer)
     * @param _swapArgs The structured data for a swap call on an extension of the enzyme contract
     */
    function _executeTradeInternalV2(
        TransactionMetaDataV2 calldata txData,
        uint8 v,
        bytes32 r,
        bytes32 s,
        ExtensionArgs[] memory _swapArgs
    ) private {
        require(
            validateSigner(txData, v, r, s),
            "_executeTradeInternalV2: Signer not recognized"
        );

        address vaultProxyCopy = vaultProxy;

        address _comptrollerProxy = __getComptrollerProxyForVault(
            vaultProxyCopy
        );

        _swap(_comptrollerProxy, _swapArgs);

        (
            uint8 orderType,
            bytes32 txHash,
            bool isLong,
            address account,
            address[] memory addresses,
            uint256 amountIn,
            uint256 sizeDelta,
            uint256 executionFee,
            bytes memory numbers
        ) = _decodeCalldata(txData);

        require(
            !relayedTxns[txHash].status,
            Errors.RELAYED_TRANSACTION_ALREADY_EXECUTED //This trade is already copied
        );

        address externalPosition = IVault(vaultProxyCopy)
            .getActiveExternalPositions()[0];

        (
            bool canExec,
            string memory message,
            bytes memory actionArgs
        ) = validateTradeDataForGmxV2(
                abi.encode(address(this), externalPosition, account),
                addresses,
                amountIn,
                sizeDelta,
                isLong,
                executionFee,
                numbers,
                orderType
            );

        require(canExec, message);

        _callOnGmxV2(actionArgs, _comptrollerProxy, externalPosition);

        pendingTxHash = txHash;

        bytes memory data = abi.encode(addresses[0], addresses[1], isLong);

        if (!shouldStartCopy[account][data])
            shouldStartCopy[account][data] = true;
    }

    /**
     * @notice an internal function for taking gmx-v1 positions
     * @dev This function formats action data and calls on enzyme comptroller proxy contract
     * @param trader The followed trader
     * @param indexToken index token address corresponding to trader's position
     * @param collateralToken collateral token address corresponding to trader's position
     * @param externalPosition an address that takes positions on gmx-v1
     * @param isLong position type
     * @param selector function selector of gmx-v1 position router contract
     * @param actionArgs actionArgs data
     */
    function _buildTransaction(
        address trader,
        address indexToken,
        address collateralToken,
        address _comptrollerProxy,
        address externalPosition,
        bool isLong,
        bytes4 selector,
        bytes memory actionArgs
    ) private {
        //After successful validations, encode positionArgs
        ExtensionArgs memory positionArgs;

        address _externalPositionManager = IComptroller(_comptrollerProxy)
            .getExternalPositionManager();

        //Function selectors
        //0xf2ae372f - It indicates createIncreasePosition function call on gmx V1 positionRouter contract
        //0x5b88e8c6 - It indicates createIncreasePositionEth function call on gmx v1 positionRouter contract
        //0x7be7d141 - It indicates createDecreasePosition function call on gmx v1 positionRouter contract
        if (selector == bytes4(0xf2ae372f) || selector == bytes4(0x5b88e8c6)) {
            positionArgs = BaseStorage.ExtensionArgs({
                _extension: _externalPositionManager,
                _actionId: uint256(1),
                _callArgs: abi.encode(externalPosition, 0, actionArgs)
            });
        } else
            positionArgs = BaseStorage.ExtensionArgs({
                _extension: _externalPositionManager,
                _actionId: uint256(1),
                _callArgs: abi.encode(externalPosition, 1, actionArgs)
            });

        //call comptroller proxy
        _externalPositionsInternal(_comptrollerProxy, positionArgs);

        //update positionInfo variable in mapping of trader;
        _saveTraderInfo(trader, collateralToken, indexToken, isLong);

        emit LeveragePositionUpdated(
            externalPosition,
            trader,
            isLong,
            indexToken,
            selector
        );
    }

    /**
     * @notice It saves trader details on the contract
     * @param trader The followed trader
     * @param collateralToken collateral token address corresponding to trader's position
     * @param indexToken index token address corresponding to trader's position
     * @param isLong position type
     */
    function _saveTraderInfo(
        address trader,
        address collateralToken,
        address indexToken,
        bool isLong
    ) private {
        (uint256 positionSize, uint256 collateral, , , , , , ) = gmxHelper
            .getPosition(trader, collateralToken, indexToken, isLong);

        bytes32 key = gmxHelper.getPositionKey(
            trader,
            collateralToken,
            indexToken,
            isLong
        );

        traderPositions[trader][key] = PositionInfo(positionSize, collateral);

        if (!shouldFollow[trader][collateralToken][indexToken])
            shouldFollow[trader][collateralToken][indexToken] = true;
    }

    /**
     * @notice This function is used to call on external position for interacting with gmx-v2 protocol
     * @param actionArgs action args data
     * @param _comptrollerProxy comptrollerProxy address
     * @param externalPosition external position address
     */
    function _callOnGmxV2(
        bytes memory actionArgs,
        address _comptrollerProxy,
        address externalPosition
    ) private {
        ExtensionArgs memory positionArgs;

        address _externalPositionManager = IComptroller(_comptrollerProxy)
            .getExternalPositionManager();

        positionArgs = BaseStorage.ExtensionArgs({
            _extension: _externalPositionManager,
            _actionId: uint256(1), //Call On External Position
            _callArgs: abi.encode(externalPosition, 0, actionArgs) // '0' here refers to create order enum id
        });

        //call comptroller proxy
        _externalPositionsInternal(_comptrollerProxy, positionArgs);
    }

    /**
     * @notice This function is used to claim funding fees from gmx-v2 positions
     * @param comptrollerProxy comptrollerProxy address
     * @param externalPosition external position address
    */
    function _claimFundingFees(
        address comptrollerProxy,
        address externalPosition
    ) private {
        ExtensionArgs memory positionArgs;

        address _externalPositionManager = IComptroller(comptrollerProxy)
            .getExternalPositionManager();

        positionArgs = BaseStorage.ExtensionArgs({
            _extension: _externalPositionManager,
            _actionId: uint256(1), //Call On External Position
            _callArgs: abi.encode(externalPosition, 1, "") // '1' here refers to ClaimCollateral enum id
        });

        //call comptroller proxy
        _externalPositionsInternal(comptrollerProxy, positionArgs);
    }

    function _redeemInUsdc(
        address _canonicalSender,
        address _comptrollerProxy,
        uint256 _sharesAmount
    ) private {
        address[] memory _payOutAssets = new address[](1);
        _payOutAssets[0] = denominationAsset;

        uint256[] memory _payOutPercentages = new uint256[](1);
        _payOutPercentages[0] = 10000;
        IComptroller(_comptrollerProxy).redeemSharesOnBehalf(
            _canonicalSender,
            _sharesAmount,
            _payOutAssets,
            _payOutPercentages
        );
    }

    function _redeemAssets(
        address _canonicalSender,
        address _comptrollerProxy,
        uint256 _sharesAmount
    ) private {
        address[] memory _additionalAssets = getIndexTokens();
        address[] memory _assetsToSkip = new address[](1);
        _assetsToSkip[0] = address(0);
        IComptroller(_comptrollerProxy).redeemSharesInKindOnBehalf(
            _canonicalSender,
            _sharesAmount,
            _additionalAssets,
            _assetsToSkip
        );
    }

    ////////////////////
    //Utility Functions//
    ////////////////////
    function _decodeCalldata(
        TransactionMetaData calldata data
    )
        internal
        pure
        returns (
            bytes4 selector,
            bytes32 txHash,
            bool isLong,
            address account,
            address[] memory path,
            address indexToken,
            uint256 amountIn,
            uint256 sizeDelta,
            uint256 executionFee
        )
    {
        selector = data.selector;
        txHash = data.txHash;
        isLong = data.isLong;
        account = data.account;
        path = data.path;
        indexToken = data.indexToken;
        amountIn = data.amountIn;
        sizeDelta = data.sizeDelta;
        executionFee = data.executionFee;
    }

    function _decodeCalldata(
        TransactionMetaDataV2 calldata data
    )
        internal
        pure
        returns (
            uint8 orderType,
            bytes32 txHash,
            bool isLong,
            address account,
            address[] memory addresses,
            uint256 amountIn,
            uint256 sizeDelta,
            uint256 executionFee,
            bytes memory numbers
        )
    {
        orderType = data.orderType;
        txHash = data.txHash;
        isLong = data.isLong;
        account = data.account;
        addresses = data.addresses;
        amountIn = data.amountIn;
        sizeDelta = data.sizeDelta;
        executionFee = data.executionFee;
        numbers = data.numbers;
    }

    function validateSigner(
        TransactionMetaData calldata metadata,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {
        require(
            block.timestamp < metadata.deadline,
            "validateSigner: signature expired"
        );

        address signer = tradingExtension.getSigner(
            metadata,
            v,
            r,
            s,
            _useNonce(metadata.account),
            address(this)
        );

        UtilLib.checkNonZeroAddress(signer);
        return IFundManagerFactory(ALFRED_FACTORY).isSigner(signer);
    }

    function validateSigner(
        TransactionMetaDataV2 calldata metadata,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {
        require(
            block.timestamp < metadata.deadline,
            "validateSigner: signature expired"
        );

        address signer = tradingExtensionV2.getSigner(
            metadata,
            v,
            r,
            s,
            _useNonce(metadata.account),
            address(this)
        );

        UtilLib.checkNonZeroAddress(signer);
        return IFundManagerFactory(ALFRED_FACTORY).isSigner(signer);
    }

    function _useNonce(address account) internal returns (uint256 current) {
        current = _nonces[account];
        _nonces[account]++;
    }

    function getPolicyManager() public view returns (address) {
        return policyManager;
    }

    function getTraderPositionInfo(
        address _trader,
        bytes32 _key
    ) public view returns (PositionInfo memory) {
        return traderPositions[_trader][_key];
    }

    //Gmx supported index tokens
    function getIndexTokens()
        public
        pure
        returns (address[] memory _indexTokens)
    {
        _indexTokens = new address[](3);
        _indexTokens[0] = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f; //Wbtc
        _indexTokens[1] = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4; //link
        _indexTokens[2] = 0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0; //uni
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AlgoTradingStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {IFundManagerFactory} from "../Interfaces/IFundManagerFactory.sol";


/**
 *     @title AlgoTradingHandler Contract
 *     @notice basic enzyme contract calls
 *     @dev DO NOT ADD STATE VARIABLES - APPEND THEM TO AlgoTradingStorage
 */
abstract contract AlgoTradingHandler is AlgoTradingStorage {
    modifier isCreator() {
        require(strategyCreator == msg.sender, "NOT_AUTHORIZED");
        _;
    }

    modifier isFactory() {
        require(ALFRED_FACTORY == msg.sender, "NOT_AUTHORIZED");
        _;
    }

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "Transaction too old");
        _;
    }

    function __assertSharesActionNotlocked(address _account) internal view {
        uint256 lastSharesBoughtBlockNumber = acctToLastSharesBought[_account];

        require(
            block.number - lastSharesBoughtBlockNumber >=
                shareActionBlockNumberLock,
            "Shares action block locked"
        );
    }

    /**
     * @notice Creates a new fund
     *  @dev internal function only responsible for deploying a vault
     *  @custom:calledfrom fundDeploy function
     *  @custom:enzymecall internal call on enzyme's createNewFund function
     *  @custom:emits vaultCreated event
     *  @param _fundName The name of the fund's shares token
     *  @param _fundSymbol The symbol of the fund's shares token
     *  (buying or selling shares) by the same user
     *  @param _feeManagerConfigData Bytes data for the fees to be enabled for the fund
     *  @param _policyManagerConfigData Bytes data for the policies to be enabled for the fund
     *  @return comptrollerProxy_ The address of the ComptrollerProxy deployed during this action
     *  @return vaultProxy_ The address of the VaultProxy deployed during this action
     */
    function createNewFund(
        string memory _fundName,
        string memory _fundSymbol,
        uint256 _sharesActionTimelock,
        bytes memory _feeManagerConfigData,
        bytes memory _policyManagerConfigData,
        address _fundCreator
    ) internal returns (address comptrollerProxy_, address vaultProxy_) {
        (comptrollerProxy_, vaultProxy_) = IFundDeployer(FUND_DEPLOYER)
            .createNewFund(
                address(this),
                _fundName,
                _fundSymbol,
                denominationAsset,
                _sharesActionTimelock, // time lock set to 0
                _feeManagerConfigData,
                _policyManagerConfigData
            );

        emit VaultCreated(
            _fundCreator,
            address(this),
            comptrollerProxy_,
            vaultProxy_
        );
    }

    /**
     * @notice deposits USDC to this contract to add liquidity and take positions in a deployed vault
     * @dev transfers USDC to the contract using ERC20 permit and approves the amount for enzymes vault
     * @param _depositer sender address
     * @param _amount the amount of USDC being deposited,
     * @param _deadline  permit
     * @param v, @param r, and @param s signature parameters
     */
    function _permitTransfer(
        address _depositer,
        uint256 _amount,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(_amount != 0, "PermitTransfer:Invalid Amount");

        if (v != uint8(0)) {
            IERC20Permit(denominationAsset).permit(
                _depositer,
                address(this),
                _amount,
                _deadline,
                v,
                r,
                s
            );
        }

        bool successfulTransfer = IERC20(denominationAsset).transferFrom(
            _depositer,
            address(this),
            _amount
        );

        require(successfulTransfer, "PermitTransfer:deposit failed");
    }

    /**
     * @notice deposits USDC to this contract to add liquidity and take positions in a deployed vault
     * @dev calculates shares amount for deposit usdc
     * @param _comptrollerProxy sender address
     * @param _amount the amount of USDC deposited,
     */
    function _buyShares(
        address _buyer,
        address _comptrollerProxy,
        uint256 _amount
    ) internal returns (uint256 sharesReceived) {
        bool successfulApproval = IERC20(denominationAsset).approve(
            _comptrollerProxy,
            _amount
        );
        require(successfulApproval, "buyShares:ERC20 approval failed");

        // Add User's shares in the vault
        sharesReceived = IComptroller(_comptrollerProxy).buySharesOnBehalf(
            _buyer,
            _amount,
            1 //minimum shares
        );

        acctToLastSharesBought[msg.sender] = block.number;
    }

    /**
     * @notice swaps assets
     * @dev internal funcion which calls on integration manager
     * @custom:called for converting assets
     * @custom:enzymecall internal call on enzyme's callOnExtension function
     * @param _integrationArgs The structured data for a swap call on an extension of the enzyme protocol
     */
    function _callOnIntegration(
        address _comptrollerProxy,
        ExtensionArgs[] memory _integrationArgs
    ) internal {
        uint256 iterations = _integrationArgs.length;
        for (uint256 i; i < iterations; ) {
            require(
                _integrationArgs[i]._extension ==
                    IComptroller(_comptrollerProxy).getIntegrationManager(),
                "_callOnIntegration:Invalid Extension"
            );
            // require(
            //     _integrationArgs[i]._actionId == uint256(0),
            //     "_callOnIntegration:Invalid Action"
            // );
            //Enzyme contract call
            IComptroller(_comptrollerProxy).callOnExtension(
                _integrationArgs[i]._extension,
                _integrationArgs[i]._actionId,
                _integrationArgs[i]._callArgs
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice create external position on a strategy
     * @dev internal function which creates a protocol (such as gmx) interacting contract
     * @custom:calledfrom addFund function
     * @custom:enzymecall internal call on enzyme's callOnExtension function
     * @param _comptrollerProxy fund Accessor
     * @param _positionArgs The structured data for a swap call on an extension of the enzyme protocol
     */
    function _createExternalPositions(
        address _comptrollerProxy,
        ExtensionArgs[] memory _positionArgs
    ) internal {
        uint256 iterations = _positionArgs.length;
        for (uint256 i; i < iterations; ) {
            _externalPositionsInternal(_comptrollerProxy, _positionArgs[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _externalPositionsInternal(
        address _comptrollerProxy,
        ExtensionArgs memory _positionArgs
    ) internal {
        require(
            _positionArgs._extension ==
                IComptroller(_comptrollerProxy).getExternalPositionManager(),
            "_externalPositionsInternal: Invalid Extension"
        );
        IComptroller(_comptrollerProxy).callOnExtension(
            _positionArgs._extension,
            _positionArgs._actionId,
            _positionArgs._callArgs
        );
    }

    function setSharesActionLock(
        uint256 _duration,
        uint256 _blockNumberDiff
    ) external {
        require(
            msg.sender == IFundManagerFactory(getFundManagerFactory()).owner(),
            "setSharesActionLock: Invalid caller"
        );

        shareActionTimeLock = _duration;

        shareActionBlockNumberLock = _blockNumberDiff;
    }
    /**
     * @dev Helper to get the ComptrollerProxy for a given VaultProxy\
     */
    function __getComptrollerProxyForVault(
        address _vaultProxy
    ) internal view returns (address comptrollerProxyContract_) {
        return IVault(payable(_vaultProxy)).getAccessor();
    }

    function getFundManagerFactory() public view returns (address) {
        return ALFRED_FACTORY;
    }

    function nonces(address account) public view returns (uint256) {
        return _nonces[account];
    }

    //#start ============ ===============  Upgradeable settings  ==================
    function proxiableUUID() public pure override returns (bytes32) {
        return keccak256("org.alfred.v2");
    }

    function updateCode(address newAddress) external override isFactory {
        return _updateCodeAddress(newAddress);
    }
    //#end  ==================  Upgradeable settings  ==================
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {GelatoRelayBase} from "./base/GelatoRelayBase.sol";
import {TokenUtils} from "./lib/TokenUtils.sol";

uint256 constant _FEE_COLLECTOR_START = 72; // offset: address + address + uint256
uint256 constant _FEE_TOKEN_START = 52; // offset: address + uint256
uint256 constant _FEE_START = 32; // offset: uint256

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContext
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeCollectorRelayContext() pure returns (address feeCollector) {
    assembly {
        feeCollector := shr(
            96,
            calldataload(sub(calldatasize(), _FEE_COLLECTOR_START))
        )
    }
}

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContext
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeTokenRelayContext() pure returns (address feeToken) {
    assembly {
        feeToken := shr(96, calldataload(sub(calldatasize(), _FEE_TOKEN_START)))
    }
}

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContext
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeRelayContext() pure returns (uint256 fee) {
    assembly {
        fee := calldataload(sub(calldatasize(), _FEE_START))
    }
}

/**
 * @dev Context variant with feeCollector, feeToken and fee appended to msg.data
 * Expects calldata encoding:
 * abi.encodePacked( _data,
 *                   _feeCollector,
 *                   _feeToken,
 *                   _fee);
 * Therefore, we're expecting 20 + 20 + 32 = 72 bytes to be appended to normal msgData
 * 32bytes start offsets from calldatasize:
 *     feeCollector: - 72 bytes
 *     feeToken: - 52 bytes
 *     fee: - 32 bytes
 */
/// @dev Do not use with GelatoRelayFeeCollector - pick only one
abstract contract GelatoRelayContext is GelatoRelayBase {
    using TokenUtils for address;

    // DANGER! Only use with onlyGelatoRelay `_isGelatoRelay` before transferring
    function _transferRelayFee() internal {
        _getFeeToken().transfer(_getFeeCollector(), _getFee());
    }

    // DANGER! Only use with onlyGelatoRelay `_isGelatoRelay` before transferring
    function _transferRelayFeeCapped(uint256 _maxFee) internal {
        uint256 fee = _getFee();
        require(
            fee <= _maxFee,
            "GelatoRelayContext._transferRelayFeeCapped: maxFee"
        );
        _getFeeToken().transfer(_getFeeCollector(), fee);
    }

    function _getMsgData() internal view returns (bytes calldata) {
        return
            _isGelatoRelay(msg.sender)
                ? msg.data[:msg.data.length - _FEE_COLLECTOR_START]
                : msg.data;
    }

    // Only use with GelatoRelayBase onlyGelatoRelay or `_isGelatoRelay` checks
    function _getFeeCollector() internal pure returns (address) {
        return _getFeeCollectorRelayContext();
    }

    // Only use with previous onlyGelatoRelay or `_isGelatoRelay` checks
    function _getFeeToken() internal pure returns (address) {
        return _getFeeTokenRelayContext();
    }

    // Only use with previous onlyGelatoRelay or `_isGelatoRelay` checks
    function _getFee() internal pure returns (uint256) {
        return _getFeeRelayContext();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/** @title PolicyManager Interface
    @notice Interface for the PolicyManager
*/
interface IPolicyManager {
    // When updating PolicyHook, also update these functions in PolicyManager:
    // 1. __getAllPolicyHooks()
    // 2. __policyHookRestrictsCurrentInvestorActions()
    enum PolicyHook {
        MinMaxLeverage,
        MaxOpenPositions,
        PreExecuteTrade,
        TradeFactor,
        MaxAmountPerTrade,
        MinAssetBalances,
        TrailingStopLoss,
        PostExecuteTrade
    }

    function validatePolicies(
        address,
        PolicyHook,
        bytes calldata
    ) external returns (bool, bytes memory);

    function setConfigForFund(
        address _fundManager,
        bytes calldata _configData
    ) external;

    function getEnabledPoliciesForFund(
        address
    ) external view returns (address[] memory);

    function fundManagerFactory() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IPolicyManager} from "../Interfaces/IPolicyManager.sol";

interface IPolicy {
    function addTradeSettings(
        address _fundManager,
        bytes calldata _encodedSettings
    ) external;

    function canDisable() external pure returns (bool canDisable_);

    function implementedHooks()
        external
        pure
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_);

    function updateTradeSettings(
        address _fundManager,
        bytes calldata _encodedSettings
    ) external;

    function validateRule(
        address _fundManagers,
        IPolicyManager.PolicyHook _hook,
        bytes calldata _encodedArgs
    ) external returns (bool isValid_, bytes memory message);

    function getTradeSettings(
        address _fundManager
    ) external view returns (bytes memory);

    function identifier() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AlgoTradingStorage} from "../Base/AlgoTradingStorage.sol";
interface ITradingExtension {
    function getSigner(
        AlgoTradingStorage.TransactionMetaData calldata metadata,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 nonce,
        address _fundManager
    ) external view returns (address signer);

    function getSigner(
        AlgoTradingStorage.TransactionMetaDataV2 calldata metadata,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 nonce,
        address _fundManager
    ) external view returns (address signer);

    function validateTradeData(
        address _fundManager,
        address _externalPosition,
        address trader,
        bytes4 selector,
        address[] memory _path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 executionFee
    )
        external
        returns (bool canExec, string memory message, bytes memory execPayload);

    function validateForceTradeData(
        address fundManager,
        address externalPosition,
        address[] memory indexToken,
        address[] memory collateralToken,
        bool[] memory positionTypes
    )
        external
        returns (
            bool canExec,
            string memory message,
            bytes[] memory execPayload
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AlgoTradingStorage} from "../Base/AlgoTradingStorage.sol";
import {Price} from "@gmx-synthetics/contracts/price/Price.sol";

interface ITradingExtensionV2 {
    function getSigner(
        AlgoTradingStorage.TransactionMetaDataV2 calldata metadata,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 nonce,
        address _fundManager
    ) external view returns (address signer);

    function validateForceTradeData(
        address fundManager,
        address trader,
        address externalPosition,
        address[] calldata collateralTokens,
        address[] calldata markets,
        bool[] calldata positionTypes,
        Price.Props[] calldata prices
    )
        external
        returns (
            bool canExec,
            string memory message,
            bytes[] memory execPayload
        );

    function validateTradeDataForGmxV2(
        bytes memory data, //abi.encode(_fundmanager, externalPosition, trader)
        address[] memory addresses,
        uint256 collateralDeltaUsd,
        uint256 sizeDeltaUsd,
        bool isLong,
        uint256 executionFee,
        bytes memory prices,
        uint8 orderType
    )
        external
        returns (bool canExec, string memory message, bytes memory execPayload);

    function getClosePositionArgs(
        address fundManager,
        address externalPosition
    ) external view returns (bytes[] memory actionArgs);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library UtilLib {
    /// @notice zero address check modifier
    function checkNonZeroAddress(address _address) internal pure {
        require(_address != address(0), "empty address");
    }

    // function checkExecutionFee(
    //     uint256 _fee,
    //     address _weth,
    //     address vault
    // ) internal view returns (bool) {
    //     if (_fee > IERC20(_weth).balanceOf(vault)) return true;
    //     else return false;
    // }

    // function checkLeverage(
    //     uint256 leverage,
    //     uint256 maxLeverage,
    //     uint256 minLeverage
    // ) internal pure returns (uint256) {
    //     uint256 _leverage = leverage / 10e25;
    //     if (_leverage / 10e25 > maxLeverage) return maxLeverage * 10e25;
    //     else if (_leverage < minLeverage) return minLeverage * 10e25;
    //     else return leverage;
    // }

    /**
     * @notice Create and return an array of 1 item.
     * @param _token Address of the token.
     * @return path
     */
    function get1TokenSwapPath(
        address _token
    ) internal pure returns (address[] memory path) {
        path = new address[](1);
        path[0] = _token;
    }

    /**
     * @notice Create and return an 2 item array of addresses used for
     *         swapping.
     * @param _token1 Token in or input token.
     * @param _token2 Token out or output token.
     * @return path
     */
    function get2TokenSwapPath(
        address _token1,
        address _token2
    ) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;
    }

    /**
     * @dev Hash function for the EIP712 domain separator
     */
    // function eip712domainSeparator() internal view returns (bytes32) {
    //     return
    //         keccak256(
    //             abi.encode(
    //                 keccak256(
    //                     "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    //                 ),
    //                 keccak256(bytes("AlgoTradeManager")),
    //                 keccak256(bytes("1")),
    //                 block.chainid,
    //                 address(this)
    //             )
    //         );
    // }

    function compareString(
        string memory s1,
        string memory s2
    ) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function getCollateralToken(
        address[] memory path,
        bytes4 selector
    ) internal pure returns (address collateralToken) {
        collateralToken = path[0];

        if (path.length == 2)
            if (
                selector == bytes4(0xf2ae372f) || selector == bytes4(0x5b88e8c6)
            ) collateralToken = path[1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts
 */
library Errors {
    //validate trade data errors
    string public constant GMX_EXECUTION_FEE_LOW = "1"; // 'The WETH balance in vault is low to copy the trade'
    string public constant INSUFFICIENT__AMOUNT_FOR_TRADE = "2"; //
    string public constant EITHER_TRADER_NOT_SQUARED_OFF_OR_NOT_HOLD_POSITIONS =
        "3"; // 'Trades will start getting copied once the trader opens a fresh leveraged position'
    string public constant TRADER_NOT_HOLD_POSITIONS = "4"; // 'The trade will not be copied, when the trader has already closed the position before getting it copied'
    string public constant STRATEGY_NOT_HOLD_POSITIONS = "5"; // 'The position is not opened, so decrease position transaction can't ne copied
    string public constant RELAYED_TRANSACTION_ALREADY_EXECUTED = "6"; // 'The backend signed data is not authorized'
    string public constant RELAYED_TRANSACTION_RETRY_VIOLATIONS = "7"; //'If the retry count of the relayed transaction goes more than max retrsy limit'
    string public constant SIGNATURE_EXPIRED_IN_VALIDATE_SIGNER = "8"; //'The deadline in backend signed data is surpassed
    string public constant SIGNATURE_INVALID = "9"; // 'The signature is invalid in backend signed data'
    string public constant CALLER_NOT_STRATEGY_CREATOR = "10"; // 'The caller of the function is not a strategy creator'
    string public constant CALLER_NOT_VALID_SIGNER = "11"; // 'The copying trade is already copied'
    string public constant NOT_A_FOLLOWED_TRADER = "12"; // 'There is no followed trader for the strategy'
    string public constant MAX_OPEN_POSITIONS_VIOLATION = "13"; //'A number of open positions can't be opened more than set limit by the strategy creator'
    string public constant LEVERAGE_VIOLATION = "14"; // 'Max leverage limit breached'
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./BaseStorage.sol";
import {IGmxHelper} from "../Interfaces/IGmxHelper.sol";

/**
 * @title AlgoTradingStorage Base Contract for containing all storage variables
 */
abstract contract AlgoTradingStorage is BaseStorage {
    struct PositionInfo {
        uint256 size;
        uint256 collateral;
    }

    struct TransactionMetaData {
        bytes4 selector;
        bytes32 txHash;
        bool isLong;
        address account;
        address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 sizeDelta;
        uint256 executionFee;
        uint256 nonce;
        uint256 deadline;
    }

    struct TransactionMetaDataV2 {
        uint8 orderType;
        bytes32 txHash;
        bool isLong;
        address account;
        address[] addresses; // array of collateralToken, marketAddress
        uint256 amountIn;
        uint256 sizeDelta;
        uint256 executionFee;
        bytes numbers; //abi.encode(sizeInUsd, Collateral,executionPrice, priceMin, priceMax)
        uint256 nonce;
        uint256 deadline;
    }

    struct TradeExecutionInfo {
        bool status;
        uint256 retryCount;
    }

    address public strategyCreator;

    IGmxHelper internal gmxHelper;

    address internal policyManager;

    /**
     * @notice a list of traders whose trades will be copied for the user
     */
    address public followedTrader;

    /**
     * @notice pendingTxHash indicates a transaction of the master trader that is to be copied 
    */
    bytes32 public pendingTxHash;

    mapping(address => mapping(bytes32 => PositionInfo)) public traderPositions;

    /**
     * @dev stores the hashes of relayed txns to avoid replay transaction.
     */
    mapping(bytes32 => TradeExecutionInfo) public relayedTxns;

    mapping(address => uint256) internal _nonces;
    /**
     * @dev This variable becomes true when the master trader takes a position after squaring off
     * for first-time copy trade
     */
    mapping(address => mapping(address => mapping(address => bool)))
        public shouldFollow;

    mapping(address => mapping(bytes => bool)) public shouldStartCopy; //This for v2 trades

    /**
     * @notice Emits after add external addition
     *  @dev emits after successful requesting GMX positions
     *  @param externalPosition external position proxy addres
     *  @param followedTrader  trader address
     *  @param isLong position type
     *  @param indexToken position token
     *  @param selector position direction type (increase or decrease position)
     */
    event LeveragePositionUpdated(
        address externalPosition,
        address followedTrader,
        bool isLong,
        address indexToken,
        bytes4 selector
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


interface IFundManagerFactory {
    function getProtocolLibForType(uint256) external view returns (address);

    function owner() external view returns (address);

    function isSigner(address) external view returns (bool);

    function isGelatoFeeCollector(address) external view returns (bool);

    function addStrategy() external;

    function removeStrategy() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {GELATO_RELAY} from "../constants/GelatoRelay.sol";

abstract contract GelatoRelayBase {
    modifier onlyGelatoRelay() {
        require(_isGelatoRelay(msg.sender), "onlyGelatoRelay");
        _;
    }

    function _isGelatoRelay(address _forwarder) internal pure returns (bool) {
        return _forwarder == GELATO_RELAY;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {NATIVE_TOKEN} from "../constants/Tokens.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library TokenUtils {
    using SafeERC20 for IERC20;

    modifier onlyERC20(address _token) {
        require(_token != NATIVE_TOKEN, "TokenUtils.onlyERC20");
        _;
    }

    function transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        _token == NATIVE_TOKEN
            ? Address.sendValue(payable(_to), _amount)
            : IERC20(_token).safeTransfer(_to, _amount);
    }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal onlyERC20(_token) {
        if (_amount == 0) return;
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
    }

    function getBalance(address token, address user)
        internal
        view
        returns (uint256)
    {
        return
            token == NATIVE_TOKEN
                ? user.balance
                : IERC20(token).balanceOf(user);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title Price
// @dev Struct for prices
library Price {
    // @param min the min price
    // @param max the max price
    struct Props {
        uint256 min;
        uint256 max;
    }

    // @dev check if a price is empty
    // @param props Props
    // @return whether a price is empty
    function isEmpty(Props memory props) internal pure returns (bool) {
        return props.min == 0 || props.max == 0;
    }

    // @dev get the average of the min and max values
    // @param props Props
    // @return the average of the min and max values
    function midPrice(Props memory props) internal pure returns (uint256) {
        return (props.max + props.min) / 2;
    }

    // @dev pick either the min or max value
    // @param props Props
    // @param maximize whether to pick the min or max value
    // @return either the min or max value
    function pickPrice(Props memory props, bool maximize) internal pure returns (uint256) {
        return maximize ? props.max : props.min;
    }

    // @dev pick the min or max price depending on whether it is for a long or short position
    // and whether the pending pnl should be maximized or not
    // @param props Props
    // @param isLong whether it is for a long or short position
    // @param maximize whether the pnl should be maximized or not
    // @return the min or max price
    function pickPriceForPnl(Props memory props, bool isLong, bool maximize) internal pure returns (uint256) {
        // for long positions, pick the larger price to maximize pnl
        // for short positions, pick the smaller price to maximize pnl
        if (isLong) {
            return maximize ? props.max : props.min;
        }

        return maximize ? props.min : props.max;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../Interfaces/IComptroller.sol";
import "../Interfaces/IVault.sol";
import "../Interfaces/IFundDeployer.sol";
import {IExternalPositionProxy} from "../Interfaces/IExternalPositionProxy.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSProxiable} from "../upgradability/UUPSProxiable.sol";

/**
 * @title BaseStorage Base Contract for containing all storage variables
 */
abstract contract BaseStorage is
    Initializable,
    UUPSProxiable,
    ReentrancyGuardUpgradeable
{
    /**
     * @dev struct for callOnExtension methods
     */
    struct ExtensionArgs {
        address _extension;
        uint256 _actionId;
        bytes _callArgs;
    }

    /**
     * @notice address of denomination Asset
     * @dev is set at initializer
     */
    address internal denominationAsset;

    /**
     * @notice address of enzyme fund deployer contract
     * @dev is set at initializer
     */
    address public FUND_DEPLOYER;

    /**
     * @notice address of vault
     */
    address public vaultProxy;

    /**
     * @notice address of the alfred factory
     * @dev is set at initializer
     */
    address internal ALFRED_FACTORY;

    /**
     * @notice share action time lock
     * @dev is set at initializer
     */
    uint256 public shareActionTimeLock;

    /**
     * @notice share action block number difference
     * @dev is set at initializer
     */
    uint256 public shareActionBlockNumberLock;

    /**
    A blockNumber after the last time shares were bought for an account
        that must expire before that account transfers or redeems their shares
    */
    mapping(address => uint256) internal acctToLastSharesBought;

    /**
     * @notice Emits after fund investment
     *  @dev emits after successful asset deposition, shares miniting and creation of LP position
     *  @custom:emittedby addFund function
     *  @param _user the end user interacting with Alfred wrapper
     *  @param _investmentAmount the amount of USDC being deposited
     *  @param _sharesReceived The actual amount of shares received
     */
    event FundsAdded(
        address _user,
        uint256 _investmentAmount,
        uint256 _sharesReceived
    );

    /**
     * @notice Emits at vault creation
     * @custom:emitted by createNewFund function
     * @param _user the end user interacting with Alfred wrapper
     * @param _comptrollerProxy The address of the comptroller deployed for this user
     * @param _vaultProxy The address of the vault deployed for this user
     */
    event VaultCreated(
        address _user,
        address _fundOwner,
        address _comptrollerProxy,
        address _vaultProxy
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IGmxVault} from "./IGmxVault.sol";

interface IGmxHelper {
    function tokenDecimals(address) external returns (uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function usdToTokenMin(address, uint256) external returns (uint256);

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external returns (bytes32);

    function tokenToUsdMin(address, uint256) external returns (uint256);

    function getMaxPrice(address) external returns (uint256);

    function getMinPrice(address) external returns (uint256);

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);

    function getWethToken() external view returns (address);

    function getGmxDecimals() external view returns (uint256);

    function calculateCollateralDelta(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta
    ) external returns (uint256 collateral);

    function validateLongIncreaseExecution(
        uint256 collateralSize,
        uint256 positionSize,
        address collateralToken,
        address indexToken
    ) external view returns (bool);

    function validateShortIncreaseExecution(
        uint256 collateralSize,
        uint256 positionSize,
        address indexToken
    ) external view returns (bool);

    function gmxVault() external view returns (IGmxVault);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

address constant GELATO_RELAY = 0xaBcC9b596420A9E9172FD5938620E265a0f9Df92;
address constant GELATO_RELAY_ERC2771 = 0xb539068872230f20456CF38EC52EF2f91AF4AE49;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.*/

pragma solidity 0.8.19;

// import "../vault/IVault.sol";

/// @title IComptroller Interface
/// @author Enzyme Council <[email protected]>
interface IComptroller {
    function activate(bool) external;

    function calcGav() external returns (uint256);

    function calcGrossShareValue() external returns (uint256);

    function callOnExtension(address, uint256, bytes calldata) external;

    function destructActivated(uint256, uint256) external;

    function destructUnactivated() external;

    function getDenominationAsset() external view returns (address);

    function getExternalPositionManager() external view returns (address);

    function vaultCallOnContract(
        address,
        bytes4,
        bytes memory
    ) external returns (bytes memory);

    function getFeeManager() external view returns (address);

    function getFundDeployer() external view returns (address);

    function getGasRelayPaymaster() external view returns (address);

    function getIntegrationManager() external view returns (address);

    function getPolicyManager() external view returns (address);

    function getVaultProxy() external view returns (address);

    function getValueInterpreter() external view returns (address);

    function init(address, uint256) external;

    // function permissionedVaultAction(IVault.VaultAction, bytes calldata) external;

    function preTransferSharesHook(address, address, uint256) external;

    function preTransferSharesHookFreelyTransferable(address) external view;

    function setGasRelayPaymaster(address) external;

    function setVaultProxy(address) external;

    function buySharesOnBehalf(
        address,
        uint256,
        uint256
    ) external returns (uint256);

    function redeemSharesOnBehalf(
        address _recipient,
        uint256 _sharesQuantity,
        address[] calldata _payoutAssets,
        uint256[] calldata _payoutAssetPercentages
    ) external returns (uint256[] memory payoutAmounts_);

    function redeemSharesInKindOnBehalf(
        address _recipient,
        uint256 _sharesQuantity,
        address[] calldata _additionalAssets,
        address[] calldata _assetsToSkip
    )
        external
        returns (
            address[] memory payoutAssets_,
            uint256[] memory payoutAmounts_
        );
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.*/

pragma solidity 0.8.19;

// import "../../../../persistent/vault/interfaces/IExternalPositionVault.sol";
// import "../../../../persistent/vault/interfaces/IFreelyTransferableSharesVault.sol";
// import "../../../../persistent/vault/interfaces/IMigratableVault.sol";

/// @title IVault Interface
/// @author Enzyme Council <[email protected]>
interface IVault {
    enum VaultAction {
        None,
        // Shares management
        BurnShares,
        MintShares,
        TransferShares,
        // Asset management
        AddTrackedAsset,
        ApproveAssetSpender,
        RemoveTrackedAsset,
        WithdrawAssetTo,
        // External position management
        AddExternalPosition,
        CallOnExternalPosition,
        RemoveExternalPosition
    }

    function addTrackedAsset(address) external;

    function burnShares(address, uint256) external;

    function buyBackProtocolFeeShares(uint256, uint256, uint256) external;

    function callOnContract(
        address,
        bytes calldata
    ) external returns (bytes memory);

    function canManageAssets(address) external view returns (bool);

    function canRelayCalls(address) external view returns (bool);

    function getAccessor() external view returns (address);

    function getOwner() external view returns (address);

    function getWethToken() external view returns (address);

    function getActiveExternalPositions()
        external
        view
        returns (address[] memory);

    function getTrackedAssets() external view returns (address[] memory);

    function isActiveExternalPosition(address) external view returns (bool);

    function isTrackedAsset(address) external view returns (bool);

    function mintShares(address, uint256) external;

    function payProtocolFee() external;

    function receiveValidatedVaultAction(VaultAction, bytes calldata) external;

    function setAccessorForFundReconfiguration(address) external;

    function setSymbol(string calldata) external;

    function transferShares(address, address, uint256) external;

    function withdrawAssetTo(address, address, uint256) external;

    function setNominatedOwner(address) external;

    function setFreelyTransferableShares() external;

    function withdrawAsset(
        address _asset,
        address _target,
        uint256 _amount
    ) external;

    function totalSupply() external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

interface IFundDeployer {
    function createNewFund(
        address,
        string memory,
        string memory,
        address,
        uint256,
        bytes memory,
        bytes memory
    ) external returns (address, address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IExternalPositionProxy {
    function getExternalPositionType() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {UUPSUtils} from "./UUPSUtils.sol";

/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Proxiable contract.
 */
abstract contract UUPSProxiable {
    /**
     * @dev Get current implementation code address.
     */
    function getCodeAddress() public view returns (address codeAddress) {
        return UUPSUtils.implementation();
    }

    function updateCode(address newAddress) external virtual;

    /**
     * @dev Proxiable UUID marker function, this would help to avoid wrong logic
     *      contract to be used for upgrading.
     *
     * NOTE: The semantics of the UUID deviates from the actual UUPS standard,
     *       where it is equivalent of _IMPLEMENTATION_SLOT.
     */
    function proxiableUUID() public view virtual returns (bytes32);

    /**
     * @dev Update code address function.
     *      It is internal, so the derived contract could setup its own permission logic.
     */
    function _updateCodeAddress(address newAddress) internal {
        // require UUPSProxy.initializeProxy first
        require(
            UUPSUtils.implementation() != address(0),
            "UUPSProxiable: not upgradable"
        );
        require(
            proxiableUUID() == UUPSProxiable(newAddress).proxiableUUID(),
            "UUPSProxiable: not compatible logic"
        );
        require(address(this) != newAddress, "UUPSProxiable: proxy loop");
        UUPSUtils.setImplementation(newAddress);
        emit CodeUpdated(proxiableUUID(), newAddress);
    }

    event CodeUpdated(bytes32 uuid, address codeAddress);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGmxVault {
    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    function updateCumulativeFundingRate(address _indexToken) external;

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);

    function positions(bytes32) external view returns (Position memory);

    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);

    function usdg() external view returns (address);

    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function fundingInterval() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function getTargetUsdgAmount(
        address _token
    ) external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(
        address _account,
        address _router
    ) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(
        address _token
    ) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(address _manager, bool _isManager) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdgAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setInPrivateLiquidationMode(
        bool _inPrivateLiquidationMode
    ) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(
        address _token
    ) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getPositionFee(
        address /* _account */,
        address /* _collateralToken */,
        address /* _indexToken */,
        bool /* _isLong */,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getFundingFee(
        address /* _account */,
        address _collateralToken,
        address /* _indexToken */,
        bool /* _isLong */,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function getPositionLeverage(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bytes32);
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
pragma solidity 0.8.19;

/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Shared Library
 */
library UUPSUtils {
    /**
     * @dev Implementation slot constant.
     * Using https://eips.ethereum.org/EIPS/eip-1967 standard
     * Storage slot 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
     * (obtained as bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)).
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Get implementation address.
    function implementation() internal view returns (address impl) {
        assembly {
            // solium-disable-line
            impl := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /// @dev Set new implementation address.
    function setImplementation(address codeAddress) internal {
        assembly {
            // solium-disable-line
            sstore(_IMPLEMENTATION_SLOT, codeAddress)
        }
    }
}