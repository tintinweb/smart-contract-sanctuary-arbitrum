// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

/**
 * @author Christoph Krpoun
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

import "./AaveHelper.sol";
import "../TransferHub/TransferHelper.sol";
import "../TransferHub/ApprovalHelper.sol";

/**
 * @dev Purpose of this contract is to optimize capital efficency by using
 * aave pools. Not borrowed funds are deposited into correspoding aave pools
 * to earn supply APY.
 *
 * The aToken are holded by the wiseLending contract but the accounting
 * is managed by the position NFTs. This is possible due to the included
 * onBehlaf functionallity inside wiseLending.
 */

contract AaveHub is AaveHelper, TransferHelper, ApprovalHelper {

    constructor(
        address _master,
        address _aaveAddress,
        address _lendingAddress
    )
        Declarations(
            _master,
            _aaveAddress,
            _lendingAddress
        )
    {}

    /**
     * @dev Adds new mapping to aaveHub. Needed
     * to link underlying assets with corresponding
     * aTokens. Can only be called by master.
     */
    function setAaveTokenAddress(
        address _underlyingAsset,
        address _aaveToken
    )
        external
        onlyMaster
    {
        _setAaveTokenAddress(
            _underlyingAsset,
            _aaveToken
        );

    }

    /**
     * @dev Adds new mapping to aaveHub in bulk.
     * Needed to link underlying assets with
     * corresponding aTokens. Can only be called by master.
     */

    function setAaveTokenAddressBulk(
        address[] calldata _underlyingAssets,
        address[] calldata _aaveTokens
    )
        external
        onlyMaster
    {
        for (uint256 i = 0; i < _underlyingAssets.length; i++) {
            _setAaveTokenAddress(
                _underlyingAssets[i],
                _aaveTokens[i]
            );
        }
    }

    /**
     * @dev Receive functions forwarding
     * sent ETH to the master address
     */
    receive()
        external
        payable
    {
        if (msg.sender == WETH_ADDRESS) {
            return;
        }

        _sendValue(
            master,
            msg.value
        );
    }

    /**
     * @dev Allows deposit ERC20 token to
     * wiseLending and takes token amount
     * as arguement. Also mints position
     * NFT to reduce needed transactions.
     */
    function depositExactAmountMint(
        address _underlyingAsset,
        uint256 _amount
    )
        external
        returns (uint256)
    {
        return depositExactAmount(
            _reservePosition(),
            _underlyingAsset,
            _amount
        );
    }

    /**
     * @dev Allows deposit ERC20 token to
     * wiseLending and takes token amount as
     * argument.
     */
    function depositExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _amount
    )
        public
        nonReentrant
        validToken(_underlyingAsset)
        returns (uint256)
    {
        _safeTransferFrom(
            _underlyingAsset,
            msg.sender,
            address(this),
            _amount
        );

        uint256 lendingShares = _wrapDepositExactAmount(
            _nftId,
            _underlyingAsset,
            _amount
        );

        emit IsDepositAave(
            _nftId,
            block.timestamp
        );

        return lendingShares;
    }

    /**
     * @dev Allows to deposit ETH token directly to
     * wiseLending and takes token amount as argument.
     * Also mints position NFT to avoid extra transaction.
     */
    function depositExactAmountETHMint()
        external
        payable
        returns (uint256)
    {
        return depositExactAmountETH(
            _reservePosition()
        );
    }

    /**
     * @dev Allows to deposit ETH token directly to
     * wiseLending and takes token amount as argument.
     */
    function depositExactAmountETH(
        uint256 _nftId
    )
        public
        payable
        nonReentrant
        returns (uint256)
    {
        _wrapETH(
            msg.value
        );

        uint256 lendingShares = _wrapDepositExactAmount(
            _nftId,
            WETH_ADDRESS,
            msg.value
        );

        emit IsDepositAave(
            _nftId,
            block.timestamp
        );

        return lendingShares;
    }

    /**
     * @dev Allows to withdraw deposited ERC20 token.
     * Takes _withdrawAmount as argument.
     */
    function withdrawExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _withdrawAmount
    )
        external
        nonReentrant
        validToken(_underlyingAsset)
        returns (uint256)
    {
        _checkOwner(
            _nftId
        );

        uint256 withdrawnShares = _wrapWithdrawExactAmount(
            _nftId,
            _underlyingAsset,
            msg.sender,
            _withdrawAmount
        );

        emit IsWithdrawAave(
            _nftId,
            block.timestamp
        );

        return withdrawnShares;
    }

    /**
     * @dev Allows to withdraw deposited ETH token.
     * Takes token amount as argument.
     */
    function withdrawExactAmountETH(
        uint256 _nftId,
        uint256 _withdrawAmount
    )
        external
        nonReentrant
        returns (uint256)
    {
        _checkOwner(
            _nftId
        );

        uint256 withdrawnShares = _wrapWithdrawExactAmount(
            _nftId,
            WETH_ADDRESS,
            address(this),
            _withdrawAmount
        );

        _unwrapETH(
            _withdrawAmount
        );

        _sendValue(
            msg.sender,
            _withdrawAmount
        );

        emit IsWithdrawAave(
            _nftId,
            block.timestamp
        );

        return withdrawnShares;
    }

    /**
     * @dev Allows to withdraw deposited ERC20 token.
     * Takes _shareAmount as argument.
     */
    function withdrawExactShares(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _shareAmount
    )
        external
        nonReentrant
        validToken(_underlyingAsset)
        returns (uint256)
    {
        _checkOwner(
            _nftId
        );

        uint256 withdrawAmount = _wrapWithdrawExactShares(
            _nftId,
            _underlyingAsset,
            msg.sender,
            _shareAmount
        );

        emit IsWithdrawAave(
            _nftId,
            block.timestamp
        );

        return withdrawAmount;
    }

    /**
     * @dev Allows to withdraw deposited ETH token.
     * Takes _shareAmount as argument.
     */
    function withdrawExactSharesETH(
        uint256 _nftId,
        uint256 _shareAmount
    )
        external
        nonReentrant
        returns (uint256)
    {
        _checkOwner(
            _nftId
        );

        uint256 withdrawAmount = _wrapWithdrawExactShares(
            _nftId,
            WETH_ADDRESS,
            address(this),
            _shareAmount
        );

        _unwrapETH(
            withdrawAmount
        );

        _sendValue(
            msg.sender,
            withdrawAmount
        );

        emit IsWithdrawAave(
            _nftId,
            block.timestamp
        );

        return withdrawAmount;
    }

    /**
     * @dev Allows to borrow ERC20 token from a
     * wiseLending pool. Needs supplied collateral
     * inside the same position and to approve
     * aaveHub to borrow onBehalf for the caller.
     * Takes token amount as argument.
     */
    function borrowExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _borrowAmount
    )
        external
        nonReentrant
        validToken(_underlyingAsset)
        returns (uint256)
    {
        _checkOwner(
            _nftId
        );

        uint256 borrowShares = _wrapBorrowExactAmount(
            _nftId,
            _underlyingAsset,
            msg.sender,
            _borrowAmount
        );

        emit IsBorrowAave(
            _nftId,
            block.timestamp
        );

        return borrowShares;
    }

    /**
     * @dev Allows to borrow ETH token from
     * wiseLending. Needs supplied collateral
     * inside the same position and to approve
     * aaveHub to borrow onBehalf for the caller.
     * Takes token amount as argument.
     */
    function borrowExactAmountETH(
        uint256 _nftId,
        uint256 _borrowAmount
    )
        external
        nonReentrant
        returns (uint256)
    {
        _checkOwner(
            _nftId
        );

        uint256 borrowShares = _wrapBorrowExactAmount(
            _nftId,
            WETH_ADDRESS,
            address(this),
            _borrowAmount
        );

        _unwrapETH(
            _borrowAmount
        );

        _sendValue(
            msg.sender,
            _borrowAmount
        );

        emit IsBorrowAave(
            _nftId,
            block.timestamp
        );

        return borrowShares;
    }

    /**
     * @dev Allows to payback ERC20 token for
     * any postion. Takes _paybackAmount as argument.
     */
    function paybackExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _paybackAmount
    )
        external
        nonReentrant
        validToken(_underlyingAsset)
        returns (uint256)
    {
        _checkPositionLocked(
            _nftId
        );

        address aaveToken = aaveTokenAddress[
            _underlyingAsset
        ];

        _safeTransferFrom(
            _underlyingAsset,
            msg.sender,
            address(this),
            _paybackAmount
        );

        uint256 actualAmountDeposit = _wrapAaveReturnValueDeposit(
            _underlyingAsset,
            _paybackAmount,
            address(this)
        );

        uint256 borrowSharesReduction = WISE_LENDING.paybackExactAmount(
            _nftId,
            aaveToken,
            actualAmountDeposit
        );

        emit IsPaybackAave(
            _nftId,
            block.timestamp
        );

        return borrowSharesReduction;
    }

    /**
     * @dev Allows to payback ETH token for
     * any postion. Takes token amount as argument.
     */
    function paybackExactAmountETH(
        uint256 _nftId
    )
        external
        payable
        nonReentrant
        returns (uint256)
    {
        _checkPositionLocked(
            _nftId
        );

        address aaveWrappedETH = aaveTokenAddress[
            WETH_ADDRESS
        ];

        uint256 userBorrowShares = WISE_LENDING.getPositionBorrowShares(
            _nftId,
            aaveWrappedETH
        );

        WISE_LENDING.syncManually(
            aaveWrappedETH
        );

        uint256 maxPaybackAmount = WISE_LENDING.paybackAmount(
            aaveWrappedETH,
            userBorrowShares
        );

        (
            uint256 paybackAmount,
            uint256 ethRefundAmount

        ) = _getInfoPayback(
            msg.value,
            maxPaybackAmount
        );

        _wrapETH(
            paybackAmount
        );

        uint256 actualAmountDeposit = _wrapAaveReturnValueDeposit(
            WETH_ADDRESS,
            paybackAmount,
            address(this)
        );

        uint256 borrowSharesReduction = WISE_LENDING.paybackExactAmount(
            _nftId,
            aaveWrappedETH,
            actualAmountDeposit
        );

        if (ethRefundAmount > 0) {
            _sendValue(
                msg.sender,
                ethRefundAmount
            );
        }

        emit IsPaybackAave(
            _nftId,
            block.timestamp
        );

        return borrowSharesReduction;
    }

    /**
     * @dev Allows to payback ERC20 token for
     * any postion. Takes shares as argument.
     */
    function paybackExactShares(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _shares
    )
        external
        nonReentrant
        validToken(_underlyingAsset)
        returns (uint256)
    {
        _checkPositionLocked(
            _nftId
        );

        address aaveToken = aaveTokenAddress[
            _underlyingAsset
        ];

        WISE_LENDING.syncManually(
            aaveToken
        );

        uint256 paybackAmount = WISE_LENDING.paybackAmount(
            aaveToken,
            _shares
        );

        _safeTransferFrom(
            _underlyingAsset,
            msg.sender,
            address(this),
            paybackAmount
        );

        AAVE.supply(
            _underlyingAsset,
            paybackAmount,
            address(this),
            REF_CODE
        );

        WISE_LENDING.paybackExactShares(
            _nftId,
            aaveToken,
            _shares
        );

        emit IsPaybackAave(
            _nftId,
            block.timestamp
        );

        return paybackAmount;
    }

    /**
     * @dev View functions returning the combined rate
     * from aave supply APY and wiseLending borrow APY
     * of a pool.
     */
    function getLendingRate(
        address _underlyingAsset
    )
        external
        view
        returns (uint256)
    {
        address aToken = aaveTokenAddress[
            _underlyingAsset
        ];

        uint256 lendingRate = WISE_SECURITY.getLendingRate(
            aToken
        );

        uint256 aaveRate = getAavePoolAPY(
            _underlyingAsset
        );

        uint256 utilization = WISE_LENDING.globalPoolData(
            aToken
        ).utilization;

        return aaveRate
            * (PRECISION_FACTOR_E18 - utilization)
            / PRECISION_FACTOR_E18
            + lendingRate;
    }

    function _setAaveTokenAddress(
        address _underlyingAsset,
        address _aaveToken
    )
        internal
    {
        if (aaveTokenAddress[_underlyingAsset] > ZERO_ADDRESS) {
            revert AlreadySet();
        }

        aaveTokenAddress[_underlyingAsset] = _aaveToken;

        _safeApprove(
            _aaveToken,
            address(WISE_LENDING),
            MAX_AMOUNT
        );

        _safeApprove(
            _underlyingAsset,
            AAVE_ADDRESS,
            MAX_AMOUNT
        );

        emit SetAaveTokenAddress(
            _underlyingAsset,
            _aaveToken,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./Declarations.sol";

abstract contract AaveHelper is Declarations {

    modifier nonReentrant() {
        _nonReentrantCheck();
        _;
    }

    modifier validToken(
        address _poolToken
    ) {
        _validToken(
            aaveTokenAddress[_poolToken]
        );
        _;
    }

    function _validToken(
        address _poolToken
    )
        internal
        view
    {
        if (WISE_LENDING.getTotalDepositShares(_poolToken) == 0) {
            revert InvalidToken();
        }
    }

    function _nonReentrantCheck()
        internal
        view
    {
        if (sendingProgressAaveHub == true) {
            revert InvalidAction();
        }

        if (WISE_LENDING.sendingProgress() == true) {
            revert InvalidAction();
        }
    }

    function _reservePosition()
        internal
        returns (uint256)
    {
        return POSITION_NFT.reservePositionForUser(
            msg.sender
        );
    }

    function _wrapDepositExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        uint256 _depositAmount
    )
        internal
        returns (uint256)
    {
        uint256 actualDepositAmount = _wrapAaveReturnValueDeposit(
            _underlyingAsset,
            _depositAmount,
            address(this)
        );

        uint256 lendingShares = WISE_LENDING.depositExactAmount(
            _nftId,
            aaveTokenAddress[_underlyingAsset],
            actualDepositAmount
        );

        return lendingShares;
    }

    function _wrapWithdrawExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        address _underlyingAssetRecipient,
        uint256 _withdrawAmount
    )
        internal
        returns (uint256)
    {
        uint256 withdrawnShares = WISE_LENDING.withdrawOnBehalfExactAmount(
            _nftId,
            aaveTokenAddress[_underlyingAsset],
            _withdrawAmount
        );

        AAVE.withdraw(
            _underlyingAsset,
            _withdrawAmount,
            _underlyingAssetRecipient
        );

        return withdrawnShares;
    }

    function _wrapWithdrawExactShares(
        uint256 _nftId,
        address _underlyingAsset,
        address _underlyingAssetRecipient,
        uint256 _shareAmount
    )
        internal
        returns (uint256)
    {
        address aaveToken = aaveTokenAddress[
            _underlyingAsset
        ];

        uint256 withdrawAmount = WISE_LENDING.withdrawOnBehalfExactShares(
            _nftId,
            aaveToken,
            _shareAmount
        );

        withdrawAmount = AAVE.withdraw(
            _underlyingAsset,
            withdrawAmount,
            _underlyingAssetRecipient
        );

        return withdrawAmount;
    }

    function _wrapBorrowExactAmount(
        uint256 _nftId,
        address _underlyingAsset,
        address _underlyingAssetRecipient,
        uint256 _borrowAmount
    )
        internal
        returns (uint256)
    {
        uint256 borrowShares = WISE_LENDING.borrowOnBehalfExactAmount(
            _nftId,
            aaveTokenAddress[_underlyingAsset],
            _borrowAmount
        );

        AAVE.withdraw(
            _underlyingAsset,
            _borrowAmount,
            _underlyingAssetRecipient
        );

        return borrowShares;
    }

    function _wrapAaveReturnValueDeposit(
        address _underlyingAsset,
        uint256 _depositAmount,
        address _targetAddress
    )
        internal
        returns (uint256 res)
    {
        IERC20 token = IERC20(
            aaveTokenAddress[_underlyingAsset]
        );

        uint256 balanceBefore = token.balanceOf(
            address(this)
        );

        AAVE.supply(
            _underlyingAsset,
            _depositAmount,
            _targetAddress,
            REF_CODE
        );

        uint256 balanceAfter = token.balanceOf(
            address(this)
        );

        res = balanceAfter
            - balanceBefore;
    }

    function _sendValue(
        address _recipient,
        uint256 _amount
    )
        internal
    {
        if (address(this).balance < _amount) {
            revert InvalidValue();
        }

        sendingProgressAaveHub = true;

        (bool success, ) = payable(_recipient).call{
            value: _amount
        }("");

        sendingProgressAaveHub = false;

        if (success == false) {
            revert FailedInnerCall();
        }
    }

    function _getInfoPayback(
        uint256 _ethSent,
        uint256 _maxPaybackAmount
    )
        internal
        pure
        returns (
            uint256,
            uint256
        )
    {
        if (_ethSent > _maxPaybackAmount) {
            return (
                _maxPaybackAmount,
                _ethSent - _maxPaybackAmount
            );
        }

        return (
            _ethSent,
            0
        );
    }

    function _prepareCollaterals(
        uint256 _nftId,
        address _poolToken
    )
        private
    {
        uint256 i;
        uint256 l = WISE_LENDING.getPositionLendingTokenLength(
            _nftId
        );

        for (i; i < l;) {

            address currentAddress = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            unchecked {
                ++i;
            }

            if (currentAddress == _poolToken) {
                continue;
            }

            WISE_LENDING.preparePool(
                currentAddress
            );

            WISE_LENDING.newBorrowRate(
                _poolToken
            );
        }
    }

    function _prepareBorrows(
        uint256 _nftId,
        address _poolToken
    )
        private
    {
        uint256 i;
        uint256 l = WISE_LENDING.getPositionBorrowTokenLength(
            _nftId
        );

        for (i; i < l;) {

            address currentAddress = WISE_LENDING.getPositionBorrowTokenByIndex(
                _nftId,
                i
            );

            unchecked {
                ++i;
            }

            if (currentAddress == _poolToken) {
                continue;
            }

            WISE_LENDING.preparePool(
                currentAddress
            );

            WISE_LENDING.newBorrowRate(
                _poolToken
            );
        }
    }

    function getAavePoolAPY(
        address _underlyingAsset
    )
        public
        view
        returns (uint256)
    {
        return AAVE.getReserveData(_underlyingAsset).currentLiquidityRate
            / PRECISION_FACTOR_E9;
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./CallOptionalReturn.sol";

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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./CallOptionalReturn.sol";

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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./AaveEvents.sol";

import "../InterfaceHub/IAave.sol";
import "../InterfaceHub/IWiseLending.sol";
import "../InterfaceHub/IWiseSecurity.sol";
import "../InterfaceHub/IPositionNFTs.sol";

import "../OwnableMaster.sol";
import "../TransferHub/WrapperHelper.sol";

error AlreadySet();
error InvalidValue();
error InvalidAction();
error FailedInnerCall();
error InvalidToken();

contract Declarations is OwnableMaster, AaveEvents, WrapperHelper {

    IAave internal immutable AAVE;

    bool public sendingProgressAaveHub;

    uint16 internal constant REF_CODE = 0;

    IWiseLending immutable public WISE_LENDING;
    IPositionNFTs immutable public POSITION_NFT;

    IWiseSecurity public WISE_SECURITY;

    address immutable public WETH_ADDRESS;
    address immutable public AAVE_ADDRESS;

    uint256 internal constant PRECISION_FACTOR_E9 = 1E9;
    uint256 internal constant PRECISION_FACTOR_E18 = 1E18;
    uint256 internal constant MAX_AMOUNT = type(uint256).max;

    mapping(address => address) public aaveTokenAddress;

    constructor(
        address _master,
        address _aaveAddress,
        address _lendingAddress
    )
        OwnableMaster(
            _master
        )
        WrapperHelper(
            IWiseLending(
                _lendingAddress
            ).WETH_ADDRESS()
        )
    {
        if (_aaveAddress == ZERO_ADDRESS) {
            revert NoValue();
        }

        if (_lendingAddress == ZERO_ADDRESS) {
            revert NoValue();
        }

        AAVE_ADDRESS = _aaveAddress;
        WISE_LENDING = IWiseLending(
            _lendingAddress
        );

        WETH_ADDRESS = WISE_LENDING.WETH_ADDRESS();

        AAVE = IAave(
            AAVE_ADDRESS
        );

        POSITION_NFT = IPositionNFTs(
            WISE_LENDING.POSITION_NFT()
        );
    }

    function _checkOwner(
        uint256 _nftId
    )
        internal
        view
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            msg.sender
        );
    }

    function _checkPositionLocked(
        uint256 _nftId
    )
        internal
        view
    {
        WISE_LENDING.checkPositionLocked(
            _nftId,
            msg.sender
        );
    }

    function setWiseSecurity(
        address _securityAddress
    )
        external
        onlyMaster
    {
        if (address(WISE_SECURITY) > ZERO_ADDRESS) {
            revert AlreadySet();
        }

        WISE_SECURITY = IWiseSecurity(
            _securityAddress
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "../InterfaceHub/IERC20.sol";

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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

contract AaveEvents {

    event SetAaveTokenAddress(
        address underlyingAsset,
        address aaveToken,
        uint256 timestamp
    );

    event IsDepositAave(
        uint256 nftId,
        uint256 timestamp
    );

    event IsWithdrawAave(
        uint256 nftId,
        uint256 timestamp
    );

    event IsBorrowAave(
        uint256 nftId,
        uint256 timestamp
    );

    event IsPaybackAave(
        uint256 nftId,
        uint256 timestamp
    );

    event IsSolelyDepositAave(
        uint256 nftId,
        uint256 timestamp
    );

    event IsSolelyWithdrawAave(
        uint256 nftId,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

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
        view;

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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

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
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "../InterfaceHub/IWETH.sol";

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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./IERC20.sol";

interface IWETH is IERC20 {

    function deposit()
        external
        payable;

    function withdraw(
        uint256
    )
        external;
}