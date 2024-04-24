// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

import "./PendlePowerFarmTokenFactory.sol";
import "./PendlePowerFarmControllerHelper.sol";

contract PendlePowerFarmController is PendlePowerFarmControllerHelper {

    PendlePowerFarmTokenFactory public immutable PENDLE_POWER_FARM_TOKEN_FACTORY;

    constructor(
        address _vePendle,
        address _pendleToken,
        address _voterContract,
        address _voterRewardsClaimerAddress,
        address _wiseOracleHub
    )
        PendlePowerFarmControllerBase(
            _vePendle,
            _pendleToken,
            _voterContract,
            _voterRewardsClaimerAddress,
            _wiseOracleHub
        )
    {
        PENDLE_POWER_FARM_TOKEN_FACTORY = new PendlePowerFarmTokenFactory(
            address(this)
        );
    }

    function withdrawLp(
        address _pendleMarket,
        address _to,
        uint256 _amount
    )
        external
        onlyChildContract(_pendleMarket)
    {
        _safeTransfer(
            _pendleMarket,
            _to,
            _amount
        );

        emit WithdrawLp(
            _pendleMarket,
            _to,
            _amount
        );
    }

    function exchangeRewardsForCompoundingWithIncentive(
        address _pendleMarket,
        address _rewardToken,
        uint256 _rewardAmount
    )
        external
        syncSupply(_pendleMarket)
        returns (uint256)
    {
        CompoundStruct memory childInfo = pendleChildCompoundInfo[
            _pendleMarket
        ];

        uint256 index = _findIndex(
            childInfo.rewardTokens,
            _rewardToken
        );

        if (childInfo.reservedForCompound[index] < _rewardAmount) {
            revert NotEnoughCompound();
        }

        uint256 sendingAmount = _getAmountToSend(
            _pendleMarket,
            _getTokensInETH(
                _rewardToken,
                _rewardAmount
            )
        );

        childInfo.reservedForCompound[index] -= _rewardAmount;
        pendleChildCompoundInfo[_pendleMarket] = childInfo;

        _safeTransferFrom(
            _pendleMarket,
            msg.sender,
            address(this),
            sendingAmount
        );

        IPendlePowerFarmToken(pendleChildAddress[_pendleMarket]).addCompoundRewards(
            sendingAmount
        );

        _safeTransfer(
            childInfo.rewardTokens[index],
            msg.sender,
            _rewardAmount
        );

        emit ExchangeRewardsForCompounding(
            _pendleMarket,
            _rewardToken,
            _rewardAmount,
            sendingAmount
        );

        return sendingAmount;
    }

    function exchangeLpFeesForPendleWithIncentive(
        address _pendleMarket,
        uint256 _pendleChildShares
    )
        external
        syncSupply(_pendleMarket)
        returns (
            uint256,
            uint256
        )
    {
        if (_pendleChildShares == 0) {
            revert ZeroShares();
        }

        address pendleChild = pendleChildAddress[
            _pendleMarket
        ];

        uint256 tokenAmountSend = _getAmountToSend(
            PENDLE_TOKEN_ADDRESS,
            _getTokensInETH(
                pendleChild,
                _pendleChildShares
            )
        );

        reservedPendleForLocking += tokenAmountSend;

        _safeTransferFrom(
            PENDLE_TOKEN_ADDRESS,
            msg.sender,
            address(this),
            tokenAmountSend
        );

        uint256 withdrawnAmount = IPendlePowerFarmToken(pendleChild).withdrawExactShares(
            _pendleChildShares
        );

        _safeTransfer(
            _pendleMarket,
            msg.sender,
            withdrawnAmount
        );

        emit ExchangeLpFeesForPendle(
            _pendleMarket,
            _pendleChildShares,
            tokenAmountSend,
            withdrawnAmount
        );

        return(
            tokenAmountSend,
            withdrawnAmount
        );
    }

    function skim(
        address _pendleMarket
    )
        external
        returns (uint256)
    {
        address childMarket = pendleChildAddress[
            _pendleMarket
        ];

        if (childMarket == ZERO_ADDRESS) {
            revert WrongAddress();
        }

        uint256 balance = IPendleMarket(_pendleMarket).balanceOf(
            address(this)
        );

        uint256 totalAssets = IPendlePowerFarmToken(
            childMarket
        ).totalLpAssets();

        if (balance < totalAssets + 1) {
            revert NothingToSkim();
        }

        uint256 difference = balance
            - totalAssets
            + 1;

        _safeTransfer(
            _pendleMarket,
            master,
            difference
        );

        return difference;
    }

    function changeCompoundRoleState(
        address _pendleMarket,
        address _roleReceiver,
        bool _state
    )
        public
        onlyMaster
    {
        address pendleChild = pendleChildAddress[
            _pendleMarket
        ];

        if (pendleChild == ZERO_ADDRESS) {
            revert WrongAddress();
        }

        IPendlePowerFarmToken(pendleChild).changeCompoundRoleState(
            _roleReceiver,
            _state
        );
    }

    function changeMinDepositAmount(
        address _pendleMarket,
        uint256 _newAmount
    )
        external
        onlyMaster
    {
        address pendleChild = pendleChildAddress[
            _pendleMarket
        ];

        if (pendleChild == ZERO_ADDRESS) {
            revert WrongAddress();
        }

        IPendlePowerFarmToken(pendleChild).changeMinDepositAmount(
            _newAmount
        );
    }

    function claimAirdropSafe(
        bytes[] memory _calldataArray,
        address[] memory _contractAddresses
    )
        external
        onlyMaster
    {
        uint256 callDataLength = _calldataArray.length;

        if (callDataLength != _contractAddresses.length) {
            revert InvalidLength();
        }

        bytes32 initialHashChainResult = _getHashChainResult();

        uint256 i;

        address currentAddress;

        while (i < callDataLength) {
            currentAddress = _contractAddresses[i];

            if (currentAddress == ZERO_ADDRESS) {
                revert ZeroAddress();
            }

            if (currentAddress == address(this)) {
                revert SelfCallNotAllowed();
            }

            if (_calldataArray[i].length < 4) {
                revert CallDataTooShort(i);
            }

            if (_forbiddenSelector(_calldataArray[i]) == true) {
                revert ForbiddenSelector();
            }

            (
                bool success
                ,
            ) = currentAddress.call(
                _calldataArray[i]
            );

            if (success == false) {
                revert AirdropFailed();
            }

            unchecked {
                ++i;
            }
        }

        if (_getHashChainResult() != initialHashChainResult) {
            revert HashChainManipulated();
        }
    }

    function addPendleMarket(
        address _pendleMarket,
        string memory _tokenName,
        string memory _symbolName,
        uint16 _maxCardinality
    )
        external
        onlyMaster
    {
        if (pendleChildAddress[_pendleMarket] > ZERO_ADDRESS) {
            revert AlreadySet();
        }

        if (activePendleMarketsLength() == MAX_PENDLE_MARKETS) {
            revert MaxPendleMarketsReached();
        }

        if (_pendleMarket == ZERO_ADDRESS) {
            revert WrongAddress();
        }

        address pendleChild = PENDLE_POWER_FARM_TOKEN_FACTORY.deploy(
            _pendleMarket,
            _tokenName,
            _symbolName,
            _maxCardinality
        );

        pendleChildAddress[_pendleMarket] = pendleChild;

        _setRewardTokens(
            _pendleMarket,
            _getRewardTokens(
                _pendleMarket
            )
        );

        CompoundStruct storage childInfo = pendleChildCompoundInfo[
            _pendleMarket
        ];

        uint256 rewardTokensLength = childInfo
            .rewardTokens
            .length;

        childInfo.lastIndex = new uint128[](
            rewardTokensLength
        );

        childInfo.reservedForCompound = new uint256[](
            rewardTokensLength
        );

        uint256 i;

        while (i < rewardTokensLength) {

            address token = childInfo.rewardTokens[i];

            childInfo.lastIndex[i] = _getUserRewardIndex(
                _pendleMarket,
                token,
                address(this)
            );

            childInfo.reservedForCompound[i] = 0;

            _checkFeed(
                token
            );

            unchecked {
                ++i;
            }
        }

        _checkFeed(
            _pendleMarket
        );

        activePendleMarkets.push(
            _pendleMarket
        );

        changeCompoundRoleState({
            _pendleMarket: _pendleMarket,
            _roleReceiver: address(this),
            _state: true
        });

        emit AddPendleMarket(
            _pendleMarket,
            pendleChild
        );
    }

    function updateRewardTokens(
        address _pendleMarket
    )
        external
        onlyChildContract(_pendleMarket)
        returns (bool)
    {
        address[] memory rewardTokens = _getRewardTokens(
            _pendleMarket
        );

        if (_compareHashes(_pendleMarket, rewardTokens) == true) {
            return false;
        }

        _setRewardTokens(
            _pendleMarket,
            rewardTokens
        );

        emit UpdateRewardTokens(
            _pendleMarket,
            rewardTokens
        );

        return true;
    }

    function changeExchangeIncentive(
        uint256 _newExchangeIncentive
    )
        external
        onlyMaster
    {
        exchangeIncentive = _newExchangeIncentive;

        emit ChangeExchangeIncentive(
            _newExchangeIncentive
        );
    }

    function changeMintFee(
        address _pendleMarket,
        uint256 _newFee
    )
        external
        onlyMaster
    {
        address child = pendleChildAddress[
            _pendleMarket
        ];

        if (child == ZERO_ADDRESS) {
            revert WrongAddress();
        }

        IPendlePowerFarmToken(
            child
        ).changeMintFee(
            _newFee
        );

        emit ChangeMintFee(
            _pendleMarket,
            _newFee
        );
    }

    /**
     * @dev Can also be used to extend existing lock.
     */
    function lockPendle(
        uint256 _amount,
        uint128 _weeks,
        bool _fromInside,
        bool _sameExpiry
    )
        external
        onlyMaster
        returns (uint256 newVeBalance)
    {
        syncAllSupply();

        uint256 currentExpiry = _getExpiry();

        uint128 expiry = _sameExpiry
            ? uint128(currentExpiry)
            : _calcExpiry(
                _weeks
            );

        if (uint256(expiry) < currentExpiry) {
            revert LockTimeTooShort();
        }

        if (_amount > 0) {

            _safeApprove(
                PENDLE_TOKEN_ADDRESS,
                VE_PENDLE_CONTRACT_ADDRESS,
                _amount
            );

            if (_fromInside == false) {
                _safeTransferFrom(
                    PENDLE_TOKEN_ADDRESS,
                    msg.sender,
                    address(this),
                    _amount
                );
            }
        }

        newVeBalance = PENDLE_LOCK.increaseLockPosition(
            uint128(_amount),
            expiry
        );

        syncAllSupply();

        if (_fromInside == false) {
            return newVeBalance;
        }

        if (_amount > 0) {
            reservedPendleForLocking -= _amount;
        }

        emit LockPendle(
            _amount,
            expiry,
            newVeBalance,
            _fromInside,
            _sameExpiry,
            block.timestamp
        );
    }

    function claimArb(
        uint256 _accrued,
        bytes32[] calldata _proof
    )
        external
        onlyArbitrum
    {
        ARB_REWARDS.claim(
            master,
            _accrued,
            _proof
        );

        emit ClaimArb(
            _accrued,
            _proof,
            block.timestamp
        );
    }

    function withdrawLock()
        external
        onlyMaster
        returns (uint256 amount)
    {
        if (IS_ETH_MAIN == false) {

            amount = reservedPendleForLocking;
            reservedPendleForLocking = 0;

            _safeTransfer(
                PENDLE_TOKEN_ADDRESS,
                master,
                amount
            );

            emit WithdrawLock(
                amount,
                block.timestamp
            );

            return amount;
        }

        if (_getExpiry() > block.timestamp) {
            revert NotExpired();
        }

        syncAllSupply();

        amount = PENDLE_LOCK.withdraw();

        _safeTransfer(
            PENDLE_TOKEN_ADDRESS,
            master,
            amount
        );

        syncAllSupply();

        emit WithdrawLock(
            amount,
            block.timestamp
        );
    }

    function increaseReservedForCompound(
        address _pendleMarket,
        uint256[] calldata _amounts
    )
        external
        onlyChildContract(_pendleMarket)
    {
        CompoundStruct memory childInfo = pendleChildCompoundInfo[
            _pendleMarket
        ];

        uint256 i;
        uint256 length = childInfo.rewardTokens.length;

        while (i < length) {
            childInfo.reservedForCompound[i] += _amounts[i];
            unchecked {
                ++i;
            }
        }

        pendleChildCompoundInfo[_pendleMarket] = childInfo;

        emit IncreaseReservedForCompound(
            _pendleMarket,
            _amounts
        );
    }

    function overWriteIndex(
        address _pendleMarket,
        uint256 _tokenIndex
    )
        public
        onlyChildContract(_pendleMarket)
    {
        CompoundStruct storage childInfo = pendleChildCompoundInfo[
            _pendleMarket
        ];

        childInfo.lastIndex[_tokenIndex] = _getUserRewardIndex(
            _pendleMarket,
            childInfo.rewardTokens[_tokenIndex],
            address(this)
        );
    }

    function overWriteIndexAll(
        address _pendleMarket
    )
        external
        onlyChildContract(_pendleMarket)
    {
        uint256 i;
        uint256 length = pendleChildCompoundInfo[
            _pendleMarket
        ].rewardTokens.length;

        while (i < length) {
            overWriteIndex(
                _pendleMarket,
                i
            );
            unchecked {
                ++i;
            }
        }
    }

    function overWriteAmounts(
        address _pendleMarket
    )
        external
        onlyChildContract(_pendleMarket)
    {
        CompoundStruct storage childInfo = pendleChildCompoundInfo[
            _pendleMarket
        ];

        childInfo.reservedForCompound = new uint256[](
            childInfo.rewardTokens.length
        );
    }

    function claimVoteRewards(
        uint256 _amount,
        bytes32[] calldata _merkleProof
    )
        external
    {
        PENDLE_VOTE_REWARDS.claimRetail(
            address(this),
            _amount,
            _merkleProof
        );

        emit ClaimVoteRewards(
            _amount,
            _merkleProof,
            block.timestamp
        );
    }

    function forwardETH(
        address _to,
        uint256 _amount
    )
        public
        onlyMaster
    {
        if (sendingProgress == true) {
            revert CheckSendingOnGoing();
        }

        _sendValue(
            _to,
            _amount
        );

        sendingProgress = false;
    }

    function vote(
        address[] calldata _pools,
        uint64[] calldata _weights
    )
        external
        onlyMaster
    {
        if (_weights.length != _pools.length) {
            revert InvalidLength();
        }

        uint256 i;
        uint256 len = _weights.length;

        uint256 weightSum;

        while (i < len) {
            unchecked {
                weightSum += _weights[i];
                ++i;
            }
        }

        if (weightSum > PRECISION_FACTOR_E18) {
            revert InvalidWeightSum();
        }

        PENDLE_VOTER.vote(
            _pools,
            _weights
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

import "./PendlePowerFarmToken.sol";

error DeployForbidden();

contract PendlePowerFarmTokenFactory {

    address internal constant ZERO_ADDRESS = address(0x0);

    address public immutable IMPLEMENTATION_TARGET;
    address public immutable PENDLE_POWER_FARM_CONTROLLER;

    constructor(
        address _pendlePowerFarmController
    )
    {
        PENDLE_POWER_FARM_CONTROLLER = _pendlePowerFarmController;

        PendlePowerFarmToken implementation = new PendlePowerFarmToken{
            salt: keccak256(
                abi.encodePacked(
                    _pendlePowerFarmController
                )
            )
        }();

        IMPLEMENTATION_TARGET = address(
            implementation
        );
    }

    function deploy(
        address _underlyingPendleMarket,
        string memory _tokenName,
        string memory _symbolName,
        uint16 _maxCardinality
    )
        external
        returns (address)
    {
        if (msg.sender != PENDLE_POWER_FARM_CONTROLLER) {
            revert DeployForbidden();
        }

        return _clone(
            _underlyingPendleMarket,
            _tokenName,
            _symbolName,
            _maxCardinality
        );
    }

    function _clone(
        address _underlyingPendleMarket,
        string memory _tokenName,
        string memory _symbolName,
        uint16 _maxCardinality
    )
        private
        returns (address pendlePowerFarmTokenAddress)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                _underlyingPendleMarket
            )
        );

        bytes20 targetBytes = bytes20(
            IMPLEMENTATION_TARGET
        );

        assembly {

            let clone := mload(0x40)

            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )

            mstore(
                add(clone, 0x14),
                targetBytes
            )

            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            pendlePowerFarmTokenAddress := create2(
                0,
                clone,
                0x37,
                salt
            )
        }

        PendlePowerFarmToken(pendlePowerFarmTokenAddress).initialize(
            _underlyingPendleMarket,
            PENDLE_POWER_FARM_CONTROLLER,
            _tokenName,
            _symbolName,
            _maxCardinality
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

import "./PendlePowerFarmControllerBase.sol";

abstract contract PendlePowerFarmControllerHelper is PendlePowerFarmControllerBase {

    function _findIndex(
        address[] memory _array,
        address _value
    )
        internal
        pure
        returns (uint256)
    {
        uint256 i;
        uint256 len = _array.length;

        while (i < len) {
            if (_array[i] == _value) {
                return i;
            }
            unchecked {
                ++i;
            }
        }

        revert NotFound();
    }

    function _calcExpiry(
        uint128 _weeks
    )
        internal
        view
        returns (uint128)
    {
        uint128 startTime = uint128(
            (block.timestamp / WEEK) * WEEK
        );

        return startTime + (_weeks * WEEK);
    }

    function _getExpiry()
        internal
        view
        returns (uint256)
    {
        return _getPositionData(address(this)).expiry;
    }

    function _getLockAmount()
        internal
        view
        returns (uint256)
    {
        return _getPositionData(address(this)).amount;
    }

    function _getPositionData(
        address _user
    )
        private
        view
        returns (LockedPosition memory)
    {
        return PENDLE_LOCK.positionData(
            _user
        );
    }

    function _getAmountToSend(
        address _tokenAddress,
        uint256 _rewardValue
    )
        internal
        view
        returns (uint256)
    {
        uint256 sendingValue = _rewardValue
            * (PRECISION_FACTOR_E6 - exchangeIncentive)
            / PRECISION_FACTOR_E6;

        if (sendingValue < PRECISION_FACTOR_E10) {
            revert ValueTooSmall();
        }

        return _getTokensFromETH(
            _tokenAddress,
            sendingValue
        );
    }

    function pendleChildCompoundInfoReservedForCompound(
        address _pendleMarket
    )
        external
        view
        returns (uint256[] memory)
    {
        return pendleChildCompoundInfo[_pendleMarket].reservedForCompound;
    }

    function pendleChildCompoundInfoLastIndex(
        address _pendleMarket
    )
        external
        view
        returns (uint128[] memory)
    {
        return pendleChildCompoundInfo[_pendleMarket].lastIndex;
    }

    function pendleChildCompoundInfoRewardTokens(
        address _pendleMarket
    )
        external
        view
        returns (address[] memory)
    {
        return pendleChildCompoundInfo[_pendleMarket].rewardTokens;
    }

    function activePendleMarketsLength()
        public
        view
        returns (uint256)
    {
        return activePendleMarkets.length;
    }

    function _checkFeed(
        address token
    )
        internal
        view
    {
        if (ORACLE_HUB.priceFeed(token) == ZERO_ADDRESS) {
            revert WrongAddress();
        }
    }

    function _getRewardTokens(
        address _pendleMarket
    )
        internal
        view
        returns (address[] memory)
    {
        return IPendleMarket(
            _pendleMarket
        ).getRewardTokens();
    }

    function _getUserReward(
        address _pendleMarket,
        address _rewardToken,
        address _user
    )
        internal
        view
        returns (UserReward memory)
    {
        return IPendleMarket(
            _pendleMarket
        ).userReward(
            _rewardToken,
            _user
        );
    }

    function _getUserRewardIndex(
        address _pendleMarket,
        address _rewardToken,
        address _user
    )
        internal
        view
        returns (uint128)
    {
        return _getUserReward(
            _pendleMarket,
            _rewardToken,
            _user
        ).index;
    }

    function _getTokensInETH(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        internal
        view
        returns (uint256)
    {
        return ORACLE_HUB.getTokensInETH(
            _tokenAddress,
            _tokenAmount
        );
    }

    function _getTokensFromETH(
        address _tokenAddress,
        uint256 _ethValue
    )
        internal
        view
        returns (uint256)
    {
        return ORACLE_HUB.getTokensFromETH(
            _tokenAddress,
            _ethValue
        );
    }

    function _compareHashes(
        address _pendleMarket,
        address[] memory rewardTokensToCompare
    )
        internal
        view
        returns (bool)
    {
        return keccak256(
            abi.encode(
                rewardTokensToCompare
            )
        ) == keccak256(
            abi.encode(
                pendleChildCompoundInfo[_pendleMarket].rewardTokens
            )
        );
    }

    function _forbiddenSelector(
        bytes memory _callData
    )
        internal
        pure
        returns (bool forbidden)
    {
        bytes4 selector;

        assembly {
            selector := mload(add(_callData, 32))
        }

        if (selector == APPROVE_SELECTOR) {
            return true;
        }

        if (selector == PERMIT_SELECTOR) {
            return true;
        }
    }

    function _getHashChainResult()
        internal
        view
        returns (bytes32)
    {
        uint256 pendleTokenBalance = PENDLE_TOKEN_INSTANCE.balanceOf(
            address(this)
        );

        bytes32 floatingHash = keccak256(
            abi.encodePacked(
                INITIAL_HASH,
                pendleTokenBalance
            )
        );

        uint256 i;
        address currentMarket;
        uint256 marketLength = activePendleMarkets.length;

        while (i < marketLength) {

            currentMarket = activePendleMarkets[i];

            floatingHash = _getRewardTokenHashes(
                currentMarket,
                floatingHash
            );

            floatingHash = _encodeFloatingHash(
                floatingHash,
                currentMarket
            );

            unchecked{
                ++i;
            }
        }

        return floatingHash;
    }

    function _encodeFloatingHash(
        bytes32 _floatingHash,
        address _currentMarket
    )
        internal
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _floatingHash,
                IERC20(_currentMarket).balanceOf(
                    address(this)
                )
            )
        );
    }

    function _getRewardTokenHashes(
        address _pendleMarket,
        bytes32 _floatingHash
    )
        internal
        view
        returns (bytes32)
    {
        address[] memory rewardTokens = pendleChildCompoundInfo[_pendleMarket].rewardTokens;
        uint256 l = rewardTokens.length;
        uint256 i = 0;

        while (i < l) {

            if (rewardTokens[i] == PENDLE_TOKEN_ADDRESS) {
                unchecked{
                    ++i;
                }
                continue;
            }

            _floatingHash = _encodeFloatingHash(
                _floatingHash,
                rewardTokens[i]
            );

            unchecked{
                ++i;
            }
        }

        return _floatingHash;
    }

    function _setRewardTokens(
        address _pendleMarket,
        address[] memory _rewardTokens
    )
        internal
    {
        pendleChildCompoundInfo[_pendleMarket].rewardTokens = _rewardTokens;
    }

    function getExpiry()
        external
        view
        returns (uint256)
    {
        return _getExpiry();
    }

    function getLockAmount()
        external
        view
        returns (uint256)
    {
        return _getLockAmount();
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

import "./SimpleERC20Clone.sol";

import "../../InterfaceHub/IPendle.sol";
import "../../InterfaceHub/IPendleController.sol";

import "../../TransferHub/TransferHelper.sol";

error MarketExpired();
error NotController();
error ZeroFee();
error TooMuchFee();
error NotEnoughLpAssetsTransferred();
error InsufficientShares();
error ZeroAmount();
error FeeTooHigh();
error NotEnoughShares();
error InvalidSharePriceGrowth();
error InvalidSharePrice();
error AlreadyInitialized();
error compoundRoleNotApproved();
error AmountBelowMinDeposit();

contract PendlePowerFarmToken is SimpleERC20, TransferHelper {

    // Pendle - LP token address
    address public UNDERLYING_PENDLE_MARKET;
    address public PENDLE_POWER_FARM_CONTROLLER;

    // Total balance of LPs backing at current compound distribution
    uint256 public underlyingLpAssetsCurrent;

    // Lp assets from compound left to distribute
    uint256 public totalLpAssetsToDistribute;

    // Interface Object for underlying Market
    IPendleMarket public PENDLE_MARKET;

    // InterfaceObject for pendle Sy
    IPendleSy public PENDLE_SY;

    // Interface for Pendle Controller
    IPendleController public PENDLE_CONTROLLER;

    // Max cardinality of Pendle Market
    uint16 public MAX_CARDINALITY;

    uint256 public mintFee;
    uint256 public lastInteraction;

    uint256 private constant ONE_WEEK = 7 days;
    uint256 internal constant ONE_YEAR = 365 days;
    uint256 private constant MAX_MINT_FEE = 10000;

    uint256 private constant PRECISION_FACTOR_E6 = 1E6;
    uint256 private constant PRECISION_FACTOR_E18 = 1E18;
    uint256 internal constant PRECISION_FACTOR_E36 = PRECISION_FACTOR_E18 * PRECISION_FACTOR_E18;
    uint256 internal constant PRECISION_FACTOR_YEAR = PRECISION_FACTOR_E18 * ONE_YEAR;

    uint256 MIN_DEPOSIT_AMOUNT = 1E6;

    uint256 private INITIAL_TIME_STAMP;

    uint256 internal constant RESTRICTION_FACTOR = 10
        * PRECISION_FACTOR_E36
        / PRECISION_FACTOR_YEAR;

    mapping (address => bool) public compoundRole;

    modifier onlyController() {
        _onlyController();
        _;
    }

    function _onlyController()
        private
        view
    {
        if (msg.sender != PENDLE_POWER_FARM_CONTROLLER) {
            revert NotController();
        }
    }

    modifier syncSupply()
    {
        _triggerIndexUpdate();
        _overWriteCheck();
        _syncSupply();
        _updateRewards();
        _setLastInteraction();
        _increaseCardinalityNext();
        uint256 sharePriceBefore = _getSharePrice();
        _;
        _validateSharePriceGrowth(
            _validateSharePrice(
                sharePriceBefore
            )
        );
    }

    modifier onlyCompoundRole()
    {
        _onlyCompoundRole();
        _;
    }

    function _onlyCompoundRole()
        private
        view
    {
        if (compoundRole[msg.sender] == false) {
            revert compoundRoleNotApproved();
        }
    }

    function _validateSharePrice(
        uint256 _sharePriceBefore
    )
        private
        view
        returns (uint256)
    {
        uint256 sharePricenNow = _getSharePrice();

        if (sharePricenNow < _sharePriceBefore) {
            revert InvalidSharePrice();
        }

        return sharePricenNow;
    }

    function _validateSharePriceGrowth(
        uint256 _sharePriceNow
    )
        private
        view
    {
        uint256 timeDifference = block.timestamp
            - INITIAL_TIME_STAMP;

        uint256 maximum = timeDifference
            * RESTRICTION_FACTOR
            + PRECISION_FACTOR_E18;

        if (_sharePriceNow > maximum) {
            revert InvalidSharePriceGrowth();
        }
    }

    function _overWriteCheck()
        internal
    {
        _wrapOverWrites(
            _updateRewardTokens()
        );
    }

    function _triggerIndexUpdate()
        internal
    {
        _withdrawLp(
            UNDERLYING_PENDLE_MARKET,
            0
        );
    }

    function _wrapOverWrites(
        bool _overWritten
    )
        internal
    {
        if (_overWritten == true) {
            _overWriteIndexAll();
            _overWriteAmounts();
        }
    }

    function _updateRewardTokens()
        private
        returns (bool)
    {
        return PENDLE_CONTROLLER.updateRewardTokens(
            UNDERLYING_PENDLE_MARKET
        );
    }

    function _overWriteIndexAll()
        private
    {
        PENDLE_CONTROLLER.overWriteIndexAll(
            UNDERLYING_PENDLE_MARKET
        );
    }

    function _overWriteIndex(
        uint256 _index
    )
        private
    {
        PENDLE_CONTROLLER.overWriteIndex(
            UNDERLYING_PENDLE_MARKET,
            _index
        );
    }

    function _overWriteAmounts()
        private
    {
        PENDLE_CONTROLLER.overWriteAmounts(
            UNDERLYING_PENDLE_MARKET
        );
    }

    function _updateRewards()
        private
    {
        uint256[] memory rewardsOutsideArray = _calculateRewardsClaimedOutside();

        uint256 i;
        uint256 l = rewardsOutsideArray.length;

        while (i < l) {
            if (rewardsOutsideArray[i] > 0) {
                PENDLE_CONTROLLER.increaseReservedForCompound(
                    UNDERLYING_PENDLE_MARKET,
                    rewardsOutsideArray
                );
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function _calculateRewardsClaimedOutside()
        internal
        returns (uint256[] memory)
    {
        IPendleController PENDLE_CONTROLLER_INSTANCE = PENDLE_CONTROLLER;
        address UNDERLYING_PENDLE_MARKET_ADDRESS = UNDERLYING_PENDLE_MARKET;

        address[] memory rewardTokens = PENDLE_CONTROLLER_INSTANCE.pendleChildCompoundInfoRewardTokens(
            UNDERLYING_PENDLE_MARKET_ADDRESS
        );

        uint128[] memory lastIndex = PENDLE_CONTROLLER_INSTANCE.pendleChildCompoundInfoLastIndex(
            UNDERLYING_PENDLE_MARKET_ADDRESS
        );

        uint256 l = rewardTokens.length;
        uint256[] memory rewardsOutsideArray = new uint256[](l);

        uint256 i;
        uint128 index;

        uint256 activeBalance = _getActiveBalance();
        uint256 totalLpAssetsCurrent = totalLpAssets();
        uint256 lpBalanceController = _getBalanceLpBalanceController();

        address PENDLE_POWER_FARM_CONTROLLER_ADDRESS = PENDLE_POWER_FARM_CONTROLLER;
        IPendleMarket PENDLE_MARKET_INSTANCE = PENDLE_MARKET;

        while (i < l) {
            UserReward memory userReward = _getUserReward(
                rewardTokens[i],
                PENDLE_POWER_FARM_CONTROLLER_ADDRESS
            );

            if (userReward.accrued > 0) {
                PENDLE_MARKET_INSTANCE.redeemRewards(
                    PENDLE_POWER_FARM_CONTROLLER_ADDRESS
                );

                userReward = _getUserReward(
                    rewardTokens[i],
                    PENDLE_POWER_FARM_CONTROLLER_ADDRESS
                );
            }

            index = userReward.index;

            if (lastIndex[i] == 0 && index > 0) {
                rewardsOutsideArray[i] = 0;
                _overWriteIndex(
                    i
                );
                unchecked {
                    ++i;
                }
                continue;
            }

            if (index == lastIndex[i]) {
                rewardsOutsideArray[i] = 0;
                unchecked {
                    ++i;
                }
                continue;
            }

            uint256 indexDiff = index
                - lastIndex[i];

            bool scaleNecessary = totalLpAssetsCurrent < lpBalanceController;

            rewardsOutsideArray[i] = scaleNecessary
                ? indexDiff
                    * activeBalance
                    * totalLpAssetsCurrent
                    / lpBalanceController
                    / PRECISION_FACTOR_E18
                : indexDiff
                    * activeBalance
                    / PRECISION_FACTOR_E18;

            _overWriteIndex(
                i
            );

            unchecked {
                ++i;
            }
        }

        return rewardsOutsideArray;
    }

    function _getBalanceLpBalanceController()
        private
        view
        returns (uint256)
    {
        return PENDLE_MARKET.balanceOf(
            PENDLE_POWER_FARM_CONTROLLER
        );
    }

    function _getActiveBalance()
        private
        view
        returns (uint256)
    {
        return PENDLE_MARKET.activeBalance(
            PENDLE_POWER_FARM_CONTROLLER
        );
    }

    function _getSharePrice()
        private
        view
        returns (uint256)
    {
        return previewUnderlyingLpAssets() * PRECISION_FACTOR_E18
            / totalSupply();
    }

    function _syncSupply()
        private
    {
        uint256 additonalAssets = previewDistribution();

        if (additonalAssets == 0) {
            return;
        }

        underlyingLpAssetsCurrent += additonalAssets;
        totalLpAssetsToDistribute -= additonalAssets;
    }

    function _increaseCardinalityNext()
        internal
    {
        MarketStorage memory storageMarket = PENDLE_MARKET._storage();

        if (storageMarket.observationCardinalityNext < MAX_CARDINALITY) {
            PENDLE_MARKET.increaseObservationsCardinalityNext(
                storageMarket.observationCardinalityNext + 1
            );
        }
    }

    function _withdrawLp(
        address _to,
        uint256 _amount
    )
        internal
    {
        PENDLE_CONTROLLER.withdrawLp(
            UNDERLYING_PENDLE_MARKET,
            _to,
            _amount
        );
    }

    function _getUserReward(
        address _rewardToken,
        address _user
    )
        internal
        view
        returns (UserReward memory)
    {
        return PENDLE_MARKET.userReward(
            _rewardToken,
            _user
        );
    }

    function previewDistribution()
        public
        view
        returns (uint256)
    {
        uint256 lastInteractioCached = lastInteraction;

        if (totalLpAssetsToDistribute == 0) {
            return 0;
        }

        if (block.timestamp == lastInteractioCached) {
            return 0;
        }

        if (totalLpAssetsToDistribute < ONE_WEEK) {
            return totalLpAssetsToDistribute;
        }

        uint256 currentRate = totalLpAssetsToDistribute
            / ONE_WEEK;

        uint256 additonalAssets = currentRate
            * (block.timestamp - lastInteractioCached);

        if (additonalAssets > totalLpAssetsToDistribute) {
            return totalLpAssetsToDistribute;
        }

        return additonalAssets;
    }

    function _setLastInteraction()
        private
    {
        lastInteraction = block.timestamp;
    }

    function _applyMintFee(
        uint256 _amount
    )
        internal
        view
        returns (uint256)
    {
        return _amount
            * (PRECISION_FACTOR_E6 - mintFee)
            / PRECISION_FACTOR_E6;
    }

    function totalLpAssets()
        public
        view
        returns (uint256)
    {
        return underlyingLpAssetsCurrent
            + totalLpAssetsToDistribute;
    }

    function previewUnderlyingLpAssets()
        public
        view
        returns (uint256)
    {
        return previewDistribution()
            + underlyingLpAssetsCurrent;
    }

    function previewMintShares(
        uint256 _underlyingAssetAmount,
        uint256 _underlyingLpAssetsCurrent
    )
        public
        view
        returns (uint256)
    {
        return _underlyingAssetAmount
            * totalSupply()
            / _underlyingLpAssetsCurrent;
    }

    function previewAmountWithdrawShares(
        uint256 _shares,
        uint256 _underlyingLpAssetsCurrent
    )
        public
        view
        returns (uint256)
    {
        return _shares
            * _underlyingLpAssetsCurrent
            / totalSupply();
    }

    function previewBurnShares(
        uint256 _underlyingAssetAmount,
        uint256 _underlyingLpAssetsCurrent
    )
        public
        view
        returns (uint256)
    {
        uint256 product = _underlyingAssetAmount
            * totalSupply();

        return product % _underlyingLpAssetsCurrent == 0
            ? product / _underlyingLpAssetsCurrent
            : product / _underlyingLpAssetsCurrent + 1;
    }

    function changeCompoundRoleState(
        address _compoundRole,
        bool _state
    )
        external
        onlyController
    {
        compoundRole[_compoundRole] = _state;
    }

    function changeMinDepositAmount(
        uint256 _newMinDepositAmount
    )
        external
        onlyController
    {
        MIN_DEPOSIT_AMOUNT = _newMinDepositAmount;
    }

    function manualSync()
        external
        syncSupply
        returns (bool)
    {
        return true;
    }

    function addCompoundRewards(
        uint256 _amount
    )
        external
        syncSupply
        onlyCompoundRole
    {
        if (_amount == 0) {
            revert ZeroAmount();
        }

        totalLpAssetsToDistribute += _amount;

        if (msg.sender == PENDLE_POWER_FARM_CONTROLLER) {
            return;
        }

        _safeTransferFrom(
            UNDERLYING_PENDLE_MARKET,
            msg.sender,
            PENDLE_POWER_FARM_CONTROLLER,
            _amount
        );
    }

    /**
     * @dev External wrapper for mint function.
     */
    function depositExactAmount(
        uint256 _underlyingLpAssetAmount
    )
        external
        syncSupply
        returns (
            uint256,
            uint256
        )
    {
        if (_underlyingLpAssetAmount < MIN_DEPOSIT_AMOUNT) {
            revert AmountBelowMinDeposit();
        }

        uint256 shares = previewMintShares(
            _underlyingLpAssetAmount,
            underlyingLpAssetsCurrent
        );

        if (shares == 0) {
            revert NotEnoughLpAssetsTransferred();
        }

        uint256 reducedShares = _applyMintFee(
            shares
        );

        uint256 feeShares = shares
            - reducedShares;

        if (feeShares == 0) {
            revert ZeroFee();
        }

        if (reducedShares == feeShares) {
            revert TooMuchFee();
        }

        _mint(
            msg.sender,
            reducedShares
        );

        _mint(
            PENDLE_POWER_FARM_CONTROLLER,
            feeShares
        );

        underlyingLpAssetsCurrent += _underlyingLpAssetAmount;

        _safeTransferFrom(
            UNDERLYING_PENDLE_MARKET,
            msg.sender,
            PENDLE_POWER_FARM_CONTROLLER,
            _underlyingLpAssetAmount
        );

        return (
            reducedShares,
            feeShares
        );
    }

    function changeMintFee(
        uint256 _newFee
    )
        external
        onlyController
    {
        if (_newFee > MAX_MINT_FEE) {
            revert FeeTooHigh();
        }

        mintFee = _newFee;
    }

    /**
     * @dev External wrapper for burn function.
     */
    function withdrawExactShares(
        uint256 _shares
    )
        external
        syncSupply
        returns (uint256)
    {
        if (_shares == 0) {
            revert ZeroAmount();
        }

        if (_shares > balanceOf(msg.sender)) {
            revert InsufficientShares();
        }

        uint256 tokenAmount = previewAmountWithdrawShares(
            _shares,
            underlyingLpAssetsCurrent
        );

        underlyingLpAssetsCurrent -= tokenAmount;

        _burn(
            msg.sender,
            _shares
        );

        if (msg.sender == PENDLE_POWER_FARM_CONTROLLER) {
            return tokenAmount;
        }

        _withdrawLp(
            msg.sender,
            tokenAmount
        );

        return tokenAmount;
    }

    function withdrawExactAmount(
        uint256 _underlyingLpAssetAmount
    )
        external
        syncSupply
        returns (uint256)
    {
        if (_underlyingLpAssetAmount == 0) {
            revert ZeroAmount();
        }

        uint256 shares = previewBurnShares(
            _underlyingLpAssetAmount,
            underlyingLpAssetsCurrent
        );

        if (shares > balanceOf(msg.sender)) {
            revert NotEnoughShares();
        }

        _burn(
            msg.sender,
            shares
        );

        underlyingLpAssetsCurrent -= _underlyingLpAssetAmount;

        _withdrawLp(
            msg.sender,
            _underlyingLpAssetAmount
        );

        return shares;
    }

    function initialize(
        address _underlyingPendleMarket,
        address _pendleController,
        string memory _tokenName,
        string memory _symbolName,
        uint16 _maxCardinality
    )
        external
    {
        if (address(PENDLE_MARKET) != address(0)) {
            revert AlreadyInitialized();
        }

        PENDLE_MARKET = IPendleMarket(
            _underlyingPendleMarket
        );

        if (PENDLE_MARKET.isExpired() == true) {
            revert MarketExpired();
        }

        PENDLE_CONTROLLER = IPendleController(
            _pendleController
        );

        MAX_CARDINALITY = _maxCardinality;

        _name = _tokenName;
        _symbol = _symbolName;

        PENDLE_POWER_FARM_CONTROLLER = _pendleController;
        UNDERLYING_PENDLE_MARKET = _underlyingPendleMarket;

        (
            address pendleSyAddress,
            ,
        ) = PENDLE_MARKET.readTokens();

        PENDLE_SY = IPendleSy(
            pendleSyAddress
        );

        _decimals = PENDLE_SY.decimals();

        lastInteraction = block.timestamp;

        _totalSupply = 1;
        underlyingLpAssetsCurrent = 1;
        mintFee = 3000;
        INITIAL_TIME_STAMP = block.timestamp;
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

import "../../OwnableMaster.sol";

import "../../TransferHub/TransferHelper.sol";
import "../../TransferHub/ApprovalHelper.sol";
import "../../TransferHub/SendValueHelper.sol";

import "../../InterfaceHub/IPendle.sol";
import "../../InterfaceHub/IArbRewardsClaimer.sol";
import "../../InterfaceHub/IWiseOracleHub.sol";
import "../../InterfaceHub/IPendlePowerFarmToken.sol";
import "../../InterfaceHub/IPendlePowerFarmTokenFactory.sol";

error NotAllowed();
error AlreadySet();
error NotExpired();
error LockTimeTooShort();
error ZeroShares();
error ValueTooSmall();
error InvalidLength();
error InvalidWeightSum();
error ZeroAddress();
error SelfCallNotAllowed();
error NothingToSkim();
error NotFound();
error NotEnoughCompound();
error NotArbitrum();
error CheckSendingOnGoing();
error MaxPendleMarketsReached();
error AirdropFailed();
error HashChainManipulated();
error ForbiddenSelector();
error WrongAddress();
error CallDataTooShort(uint256);

contract PendlePowerFarmControllerBase is
    OwnableMaster,
    TransferHelper,
    ApprovalHelper,
    SendValueHelper
{
    struct CompoundStruct {
        uint256[] reservedForCompound;
        uint128[] lastIndex;
        address[] rewardTokens;
    }

    address internal immutable PENDLE_TOKEN_ADDRESS;

    address internal immutable VOTER_CONTRACT_ADDRESS;
    address internal immutable VOTER_REWARDS_CLAIMER_ADDRESS;

    address internal immutable WISE_ORACLE_HUB_ADDRESS;
    address internal immutable VE_PENDLE_CONTRACT_ADDRESS;

    uint256 internal constant PRECISION_FACTOR_E6 = 1E6;
    uint256 internal constant PRECISION_FACTOR_E10 = 1E10;
    uint256 internal constant PRECISION_FACTOR_E18 = 1E18;

    uint256 internal constant MAINNET_CHAIN_ID = 1;
    uint256 internal constant ARBITRUM_CHAIN_ID = 42161;

    uint256 public reservedPendleForLocking;

    mapping(address => address) public pendleChildAddress;
    mapping(address => CompoundStruct) pendleChildCompoundInfo;

    address[] public activePendleMarkets;

    bool immutable IS_ETH_MAIN;

    uint128 internal constant WEEK = 7 days;
    uint256 public exchangeIncentive;

    uint256 internal constant MAX_PENDLE_MARKETS = 42;

    IPendleLock immutable public PENDLE_LOCK;
    IPendleVoter immutable public PENDLE_VOTER;
    IPendleVoteRewards immutable public PENDLE_VOTE_REWARDS;

    IArbRewardsClaimer public ARB_REWARDS;

    address internal constant ARB_REWARDS_ADDRESS = 0x23a102e78D1FF1645a3666691495174764a5FCAF;
    address internal constant ARB_TOKEN_ADDRESS = 0x912CE59144191C1204E64559FE8253a0e49E6548;

    IWiseOracleHub immutable internal ORACLE_HUB;

    bytes4 internal constant APPROVE_SELECTOR = 0x095ea7b3;
    bytes4 internal constant PERMIT_SELECTOR = 0xd505accf;

    bytes32 internal constant INITIAL_HASH = keccak256(
        abi.encodePacked(ZERO_ADDRESS, uint256(0))
    );

    IERC20 immutable PENDLE_TOKEN_INSTANCE;

    constructor(
        address _vePendle,
        address _pendleToken,
        address _voterContract,
        address _voterRewardsClaimerAddress,
        address _wiseOracleHub
    )
        OwnableMaster(
            msg.sender
        )
    {
        IS_ETH_MAIN = block.chainid == MAINNET_CHAIN_ID
            ? true
            : false;

        PENDLE_TOKEN_ADDRESS = _pendleToken;

        PENDLE_TOKEN_INSTANCE = IERC20(
            _pendleToken
        );

        VOTER_CONTRACT_ADDRESS = _voterContract;
        VOTER_REWARDS_CLAIMER_ADDRESS = _voterRewardsClaimerAddress;

        WISE_ORACLE_HUB_ADDRESS = _wiseOracleHub;
        VE_PENDLE_CONTRACT_ADDRESS = _vePendle;

        PENDLE_LOCK = IPendleLock(
            _vePendle
        );

        PENDLE_VOTER = IPendleVoter(
            _voterContract
        );

        PENDLE_VOTE_REWARDS = IPendleVoteRewards(
            _voterRewardsClaimerAddress
        );

        ORACLE_HUB = IWiseOracleHub(
            _wiseOracleHub
        );

        ARB_REWARDS = IArbRewardsClaimer(
            ARB_REWARDS_ADDRESS
        );

        exchangeIncentive = 50000;
    }

    receive()
        external
        payable
    {
        _checkReentrancy();

        emit ETHReceived(
            msg.value,
            msg.sender
        );
    }

    event ETHReceived(
        uint256 _amount,
        address _sender
    );

    event ChangeExchangeIncentive(
        uint256 _newExchangeIncentive
    );

    event WithdrawLp(
        address indexed _pendleMarket,
        address indexed _to,
        uint256 _amount
    );

    event ExchangeRewardsForCompounding(
        address indexed _pendleMarket,
        address indexed _rewardToken,
        uint256 _rewardAmount,
        uint256 _sendingAmount
    );

    event ExchangeLpFeesForPendle(
        address indexed _pendleMarket,
        uint256 _pendleChildShares,
        uint256 _tokenAmountSend,
        uint256 _withdrawnAmount
    );

    event AddPendleMarket(
        address indexed _pendleMarket,
        address indexed _pendleChildAddress
    );

    event UpdateRewardTokens(
        address indexed _pendleMarket,
        address[] _rewardTokens
    );

    event ChangeMintFee(
        address indexed _pendleMarket,
        uint256 _newFee
    );

    event LockPendle(
        uint256 _amount,
        uint128 _expiry,
        uint256 _newVeBalance,
        bool _fromInside,
        bool _sameExpiry,
        uint256 _timestamp
    );

    event ClaimArb(
        uint256 _accrued,
        bytes32[] _proof,
        uint256 _timestamp
    );

    event IncreaseReservedForCompound(
        address indexed _pendleMarket,
        uint256[] _amounts
    );

    event ClaimVoteRewards(
        uint256 _amount,
        bytes32[] _merkleProof,
        uint256 _timestamp
    );

    event WithdrawLock(
        uint256 _amount,
        uint256 _timestamp
    );

    modifier syncSupply(
        address _pendleMarket
    )
    {
        _syncSupply(
            _pendleMarket
        );
        _;
    }

    modifier onlyChildContract(
        address _pendleMarket
    )
    {
        _onlyChildContract(
            _pendleMarket
        );
        _;
    }

    modifier onlyArbitrum()
    {
        _onlyArbitrum();
        _;
    }

    function _onlyArbitrum()
        private
        view
    {
        if (block.chainid != ARBITRUM_CHAIN_ID) {
            revert NotArbitrum();
        }
    }

    function _onlyChildContract(
        address _pendleMarket
    )
        private
        view
    {
        if (msg.sender != pendleChildAddress[_pendleMarket]) {
            revert NotAllowed();
        }
    }

    function _syncSupply(
        address _pendleMarket
    )
        internal
    {
        address child = pendleChildAddress[
            _pendleMarket
        ];

        if (child == ZERO_ADDRESS) {
            revert WrongAddress();
        }

        IPendlePowerFarmToken(child).manualSync();
    }

    function syncAllSupply()
        public
    {
        uint256 i;
        uint256 length = activePendleMarkets.length;

        while (i < length) {
            _syncSupply(
                activePendleMarkets[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function _checkReentrancy()
        internal
        view
    {
        if (sendingProgress == true) {
            revert CheckSendingOnGoing();
        }
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

error AllowanceBelowZero();
error ApproveWithZeroAddress();
error BurnExceedsBalance();
error BurnFromZeroAddress();
error InsufficientAllowance();
error MintToZeroAddress();
error TransferAmountExceedsBalance();
error TransferZeroAddress();

contract SimpleERC20 {

    string internal _name;
    string internal _symbol;

    uint8 internal _decimals;
    uint256 internal _totalSupply;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    // Miscellaneous constants
    uint256 internal constant UINT256_MAX = type(uint256).max;
    address internal constant ZERO_ADDRESS = address(0);

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

    function name()
        external
        view
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        external
        view
        returns (string memory)
    {
        return _symbol;
    }

    function decimals()
        external
        view
        returns (uint8)
    {
        return _decimals;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(
        address _account
    )
        public
        view
        returns (uint256)
    {
        return _balances[_account];
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    )
        internal
    {
        if (_from == ZERO_ADDRESS || _to == ZERO_ADDRESS) {
            revert TransferZeroAddress();
        }

        uint256 fromBalance = _balances[_from];

        if (fromBalance < _amount) {
            revert TransferAmountExceedsBalance();
        }

        unchecked {
            _balances[_from] = fromBalance - _amount;
            _balances[_to] += _amount;
        }

        emit Transfer(
            _from,
            _to,
            _amount
        );
    }

    function _mint(
        address _account,
        uint256 _amount
    )
        internal
    {
        if (_account == ZERO_ADDRESS) {
            revert MintToZeroAddress();
        }

        _totalSupply += _amount;

        unchecked {
            _balances[_account] += _amount;
        }

        emit Transfer(
            ZERO_ADDRESS,
            _account,
            _amount
        );
    }

    function _burn(
        address _account,
        uint256 _amount
    )
        internal
    {
        if (_account == ZERO_ADDRESS) {
            revert BurnFromZeroAddress();
        }

        uint256 accountBalance = _balances[
            _account
        ];

        if (accountBalance < _amount) {
            revert BurnExceedsBalance();
        }

        unchecked {
            _balances[_account] = accountBalance - _amount;
            _totalSupply -= _amount;
        }

        emit Transfer(
            _account,
            ZERO_ADDRESS,
            _amount
        );
    }

    function transfer(
        address _to,
        uint256 _amount
    )
        external
        returns (bool)
    {
        _transfer(
            _msgSender(),
            _to,
            _amount
        );

        return true;
    }

    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            _spender,
            _amount
        );

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        external
        returns (bool)
    {
        _spendAllowance(
            _from,
            _msgSender(),
            _amount
        );

        _transfer(
            _from,
            _to,
            _amount
        );

        return true;
    }

    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    )
        external
        returns (bool)
    {
        address owner = _msgSender();

        _approve(
            owner,
            _spender,
            allowance(owner, _spender) + _addedValue
        );

        return true;
    }

    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    )
        external
        returns (bool)
    {
        address owner = _msgSender();

        uint256 currentAllowance = allowance(
            owner,
            _spender
        );

        if (currentAllowance < _subtractedValue) {
            revert AllowanceBelowZero();
        }

        unchecked {
            _approve(
                owner,
                _spender,
                currentAllowance - _subtractedValue
            );
        }

        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    )
        internal
    {
        if (_owner == ZERO_ADDRESS || _spender == ZERO_ADDRESS) {
            revert ApproveWithZeroAddress();
        }

        _allowances[_owner][_spender] = _amount;

        emit Approval(
            _owner,
            _spender,
            _amount
        );
    }

    function _spendAllowance(
        address _owner,
        address _spender,
        uint256 _amount
    )
        internal
    {
        uint256 currentAllowance = allowance(
            _owner,
            _spender
        );

        if (currentAllowance != UINT256_MAX) {

            if (currentAllowance < _amount) {
                revert InsufficientAllowance();
            }

            unchecked {
                _approve(
                    _owner,
                    _spender,
                    currentAllowance - _amount
                );
            }
        }
    }

    function _msgSender()
        internal
        view
        returns (address)
    {
        return msg.sender;
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

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

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

interface IPendleController {

    struct compoundStruct {
        uint256[] reservedForCompound;
        uint128[] lastIndex;
        address[] rewardTokens;
    }

    function withdrawLp(
        address _pendleMarket,
        address _to,
        uint256 _amount
    )
        external;

    function increaseReservedForCompound(
        address _pendleMarket,
        uint256[] memory _amounts
    )
        external;

    function pendleChildCompoundInfoReservedForCompound(
        address _pendleMarket
    )
        external
        view
        returns (uint256[] memory);

    function pendleChildCompoundInfoLastIndex(
        address _pendleMarket
    )
        external
        view
        returns (uint128[] memory);

    function pendleChildCompoundInfoRewardTokens(
        address _pendleMarket
    )
        external
        view
        returns (address[] memory);

    function updateRewardTokens(
        address _pendleMarket
    )
        external
        returns (bool);

    function overWriteIndexAll(
        address _pendleMarket
    )
        external;

    function overWriteIndex(
        address _pendleMarket,
        uint256 _index
    )
        external;

    function overWriteAmounts(
        address _pendleMarket
    )
        external;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

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

pragma solidity =0.8.25;

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
        master = msg.sender;
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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

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
        if (_spender == address(0)) {
            return;
        }

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

pragma solidity =0.8.25;

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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

interface IArbRewardsClaimer{
    function claim(
        address _receiver,
        uint256 _accrued,
        bytes32[] calldata _proof
    )
        external;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

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

    function latestResolverTwap(
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

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

interface IPendlePowerFarmToken {

    function changeMinDepositAmount(
        uint256 _newMinDepositAmount
    )
        external;

    function changeCompoundRoleState(
        address _roleReceiver,
        bool _state
    )
        external;

    function changeMintFee(
        uint256 _newFee
    )
        external;

    function manualSync()
        external;

    function addCompoundRewards(
        uint256 _amount
    )
        external;

    function withdrawExactShares(
        uint256 _shares
    )
        external
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

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function withdrawExactAmount(
        uint256 _underlyingLpAssetAmount
    )
        external
        returns (uint256);

    function depositExactAmount(
        uint256 _underlyingLpAssetAmount
    )
        external
        returns (
            uint256,
            uint256
        );

    function underlyingLpAssetsCurrent()
        external
        view
        returns (uint256);

    function totalLpAssetsToDistribute()
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

interface IPendlePowerFarmTokenFactory {
    function deploy(
        address _underlyingPendleMarket,
        string memory _tokenName,
        string memory _symbolName,
        uint16 _maxCardinality
    )
        external
        returns (address);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

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

pragma solidity =0.8.25;

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