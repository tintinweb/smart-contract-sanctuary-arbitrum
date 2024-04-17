// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Interface for factory contract to create more GammaPool contracts.
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev All instantiated GammaPoolFactory contracts must implement this interface
interface IGammaPoolFactory {
    /// @dev Event emitted when a new GammaPool is instantiated
    /// @param pool - address of new pool that is created
    /// @param cfmm - address of CFMM the GammaPool is created for
    /// @param protocolId - id identifier of GammaPool protocol (can be thought of as version)
    /// @param implementation - implementation address of GammaPool proxy contract. Because all GammaPools are created as proxy contracts
    /// @param tokens - ERC20 tokens of CFMM
    /// @param count - number of GammaPools instantiated including this contract
    event PoolCreated(address indexed pool, address indexed cfmm, uint16 indexed protocolId, address implementation, address[] tokens, uint256 count);

    /// @dev Event emitted when a GammaPool fee is updated
    /// @param pool - address of new pool whose fee is updated (zero address is default params)
    /// @param to - receiving address of protocol fees
    /// @param protocolFee - protocol fee share charged from interest rate accruals
    /// @param origFeeShare - protocol fee share charged on origination fees
    /// @param isSet - bool flag, true use fee information, false use GammaSwap default fees
    event FeeUpdate(address indexed pool, address indexed to, uint16 protocolFee, uint16 origFeeShare, bool isSet);

    /// @dev Event emitted when a GammaPool parameters are updated
    /// @param pool - address of GammaPool whose origination fee parameters will be updated
    /// @param origFee - loan opening origination fee in basis points
    /// @param extSwapFee - external swap fee in basis points, max 255 basis points = 2.55%
    /// @param emaMultiplier - multiplier used in EMA calculation of utilization rate
    /// @param minUtilRate1 - minimum utilization rate to calculate dynamic origination fee using exponential model
    /// @param minUtilRate2 - minimum utilization rate to calculate dynamic origination fee using linear model
    /// @param feeDivisor - fee divisor for calculating origination fee, based on 2^(maxUtilRate - minUtilRate1)
    /// @param liquidationFee - liquidation fee to charge during liquidations in basis points (1 - 255 => 0.01% to 2.55%)
    /// @param ltvThreshold - ltv threshold (1 - 255 => 0.1% to 25.5%)
    /// @param minBorrow - minimum liquidity amount that can be borrowed or left unpaid in a loan
    event PoolParamsUpdate(address indexed pool, uint16 origFee, uint8 extSwapFee, uint8 emaMultiplier, uint8 minUtilRate1, uint8 minUtilRate2, uint16 feeDivisor, uint8 liquidationFee, uint8 ltvThreshold, uint72 minBorrow);

    /// @dev Check if protocol is restricted. Which means only owner of GammaPoolFactory is allowed to instantiate GammaPools using this protocol
    /// @param _protocolId - id identifier of GammaPool protocol (can be thought of as version) that is being checked
    /// @return _isRestricted - true if protocol is restricted, false otherwise
    function isProtocolRestricted(uint16 _protocolId) external view returns(bool);

    /// @dev Set a protocol to be restricted or unrestricted. That means only owner of GammaPoolFactory is allowed to instantiate GammaPools using this protocol
    /// @param _protocolId - id identifier of GammaPool protocol (can be thought of as version) that is being restricted
    /// @param _isRestricted - set to true for restricted, set to false for unrestricted
    function setIsProtocolRestricted(uint16 _protocolId, bool _isRestricted) external;

    /// @notice Only owner of GammaPoolFactory can call this function
    /// @dev Add a protocol implementation to GammaPoolFactory contract. Which means GammaPoolFactory can create GammaPools with this implementation (protocol)
    /// @param _implementation - implementation address of GammaPool proxy contract. Because all GammaPools are created as proxy contracts
    function addProtocol(address _implementation) external;

    /// @notice Only owner of GammaPoolFactory can call this function
    /// @dev Update protocol implementation for a protocol.
    /// @param _protocolId - id identifier of GammaPool implementation
    /// @param _newImplementation - implementation address of GammaPool proxy contract. Because all GammaPools are created as proxy contracts
    function updateProtocol(uint16 _protocolId, address _newImplementation) external;

    /// @notice Only owner of GammaPoolFactory can call this function
    /// @dev Locks protocol implementation for upgradable protocols (<10000) so GammaPoolFactory can no longer update the implementation contract for this upgradable protocol
    /// @param _protocolId - id identifier of GammaPool implementation
    function lockProtocol(uint16 _protocolId) external;

    /// @dev Get implementation address that maps to protocolId. This is the actual implementation code that a GammaPool implements for a protocolId
    /// @param _protocolId - id identifier of GammaPool implementation (can be thought of as version)
    /// @return _address - implementation address of GammaPool proxy contract. Because all GammaPools are created as proxy contracts
    function getProtocol(uint16 _protocolId) external view returns (address);

    /// @dev Get beacon address that maps to protocolId. This beacon contract contains the implementation address of the GammaPool proxy
    /// @param _protocolId - id identifier of GammaPool implementation (can be thought of as version)
    /// @return _address - address of beacon of GammaPool proxy contract. Because all GammaPools are created as proxy contracts if there is one
    function getProtocolBeacon(uint16 _protocolId) external view returns (address);

    /// @dev Instantiate a new GammaPool for a CFMM based on an existing implementation (protocolId)
    /// @param _protocolId - id identifier of GammaPool protocol (can be thought of as version)
    /// @param _cfmm - address of CFMM the GammaPool is created for
    /// @param _tokens - addresses of ERC20 tokens in CFMM, used for validation during runtime of function
    /// @param _data - custom struct containing additional information used to verify the `_cfmm`
    /// @return _address - address of new GammaPool proxy contract that was instantiated
    function createPool(uint16 _protocolId, address _cfmm, address[] calldata _tokens, bytes calldata _data) external returns(address);

    /// @dev Mapping of bytes32 salts (key) to GammaPool addresses. The salt is predetermined and used to instantiate a GammaPool with a unique address
    /// @param _salt - the bytes32 key that is unique to the GammaPool and therefore also used as a unique identifier of the GammaPool
    /// @return _address - address of GammaPool that maps to bytes32 salt (key)
    function getPool(bytes32 _salt) external view returns(address);

    /// @dev Mapping of bytes32 salts (key) to GammaPool addresses. The salt is predetermined and used to instantiate a GammaPool with a unique address
    /// @param _pool - address of GammaPool that maps to bytes32 salt (key)
    /// @return _salt - the bytes32 key that is unique to the GammaPool and therefore also used as a unique identifier of the GammaPool
    function getKey(address _pool) external view returns(bytes32);

    /// @return count - number of GammaPools that have been instantiated through this GammaPoolFactory contract
    function allPoolsLength() external view returns (uint256);

    /// @dev Get pool fee parameters used to calculate protocol fees
    /// @param _pool - pool address identifier
    /// @return _to - address receiving fee
    /// @return _protocolFee - protocol fee share charged from interest rate accruals
    /// @return _origFeeShare - protocol fee share charged on origination fees
    /// @return _isSet - bool flag, true use fee information, false use GammaSwap default fees
    function getPoolFee(address _pool) external view returns (address _to, uint256 _protocolFee, uint256 _origFeeShare, bool _isSet);

    /// @dev Set pool fee parameters used to calculate protocol fees
    /// @param _pool - id identifier of GammaPool protocol (can be thought of as version)
    /// @param _to - address receiving fee
    /// @param _protocolFee - protocol fee share charged from interest rate accruals
    /// @param _origFeeShare - protocol fee share charged on origination fees
    /// @param _isSet - bool flag, true use fee information, false use GammaSwap default fees
    function setPoolFee(address _pool, address _to, uint16 _protocolFee, uint16 _origFeeShare, bool _isSet) external;

    /// @dev Call admin function in GammaPool contract
    /// @param _pool - address of GammaPool whose admin function will be called
    /// @param _data - custom struct containing information to execute in pool contract
    function execute(address _pool, bytes calldata _data) external;

    /// @dev Pause a GammaPool's function identified by a `_functionId`
    /// @param _pool - address of GammaPool whose functions we will pause
    /// @param _functionId - id of function in GammaPool we want to pause
    /// @return _functionIds - uint256 number containing all turned on (paused) function ids
    function pausePoolFunction(address _pool, uint8 _functionId) external returns(uint256 _functionIds) ;

    /// @dev Unpause a GammaPool's function identified by a `_functionId`
    /// @param _pool - address of GammaPool whose functions we will unpause
    /// @param _functionId - id of function in GammaPool we want to unpause
    /// @return _functionIds - uint256 number containing all turned on (paused) function ids
    function unpausePoolFunction(address _pool, uint8 _functionId) external returns(uint256 _functionIds) ;

    /// @return fee - protocol fee charged by GammaPool to liquidity borrowers in terms of basis points
    function fee() external view returns(uint16);

    /// @return origFeeShare - protocol fee share charged on origination fees
    function origFeeShare() external view returns(uint16);

    /// @return feeTo - address that receives protocol fees
    function feeTo() external view returns(address);

    /// @return feeToSetter - address that has the power to set protocol fees
    function feeToSetter() external view returns(address);

    /// @return feeTo - address that receives protocol fees
    /// @return fee - protocol fee charged by GammaPool to liquidity borrowers in terms of basis points
    /// @return origFeeShare - protocol fee share charged on origination fees
    function feeInfo() external view returns(address,uint256,uint256);

    /// @dev Get list of pools from start index to end index. If it goes over index it returns up to the max size of allPools array
    /// @param start - start index of pools to search
    /// @param end - end index of pools to search
    /// @return _pools - all pools requested
    function getPools(uint256 start, uint256 end) external view returns(address[] memory _pools);

    /// @dev See {IGammaPoolFactory-setFee}
    function setFee(uint16 _fee) external;

    /// @dev See {IGammaPoolFactory-setFeeTo}
    function setFeeTo(address _feeTo) external;

    /// @dev See {IGammaPoolFactory-setOrigFeeShare}
    function setOrigFeeShare(uint16 _origFeeShare) external;

    /// @dev See {IGammaPoolFactory-setFeeToSetter}
    function setFeeToSetter(address _feeToSetter) external;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Interface for LoanObserver
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface used for LoanObserver. External contract that can hold collateral for loan or implement after loan update hook
/// @notice GammaSwap team will create LoanObservers that will either work as Collateral Managers or hooks to update code
interface ILoanObserver {

    struct LoanObserved {
        /// @dev Loan counter, used to generate unique tokenId which indentifies the loan in the GammaPool
        uint256 id;

        // 1x256 bits
        /// @dev Index of GammaPool interest rate at time loan is created/updated, max 7.9% trillion
        uint96 rateIndex; // 96 bits

        // 1x256 bits
        /// @dev Initial loan debt in liquidity invariant units. Only increase when more liquidity is borrowed, decreases when liquidity is paid
        uint128 initLiquidity; // 128 bits
        /// @dev Loan debt in liquidity invariant units, increases with every update according to how many blocks have passed
        uint128 liquidity; // 128 bits

        /// @dev Initial loan debt in terms of LP tokens at time liquidity was borrowed, updates along with initLiquidity
        uint256 lpTokens;
        /// @dev Reserve tokens held as collateral for the liquidity debt, indices match GammaPool's tokens[] array indices
        uint128[] tokensHeld; // array of 128 bit numbers

        /// @dev price at which loan was opened
        uint256 px;
    }

    /// @dev Unique identifier of observer
    function refId() external view returns(uint16);

    /// @dev Observer type (2 = does not track collateral and onLoanUpdate returns zero, 3 = tracks collateral and onLoanUpdate returns collateral held outside of GammaPool)
    function refType() external view returns(uint16);

    /// @dev Validate observer can work with GammaPool
    /// @param gammaPool - address of GammaPool observer contract will observe
    /// @return validated - true if observer can work with `gammaPool`, false otherwise
    function validate(address gammaPool) external view returns(bool);

    /// @notice Used to identify requests from GammaPool
    /// @dev Factory contract of GammaPool observer will receive updates from
    function factory() external view returns(address);

    /// @notice Should require authentication that msg.sender is GammaPool of tokenId and GammaPool is registered
    /// @dev Update observer when a loan update occurs
    /// @dev If an observer does not hold collateral for loan it should return 0
    /// @param cfmm - address of the CFMM GammaPool is for
    /// @param protocolId - protocol id of the implementation contract for this GammaPool
    /// @param tokenId - unique identifier of loan in GammaPool
    /// @param data - data passed by gammaPool (e.g. LoanObserved)
    /// @return collateral - loan collateral held outside of GammaPool (Only significant when the loan tracks collateral)
    function onLoanUpdate(address cfmm, uint16 protocolId, uint256 tokenId, bytes memory data) external returns(uint256 collateral);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Interface for Loan Observer Store
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Interface used for Loan Observer Store implementations
interface ILoanObserverStore {

    /// @dev Get external collateral reference for a new position being opened
    /// @param refId - address of GammaPool we're setting an external reference for
    /// @param refAddr - address asking collateral reference for (if not permissioned, it should revert. Normally a PositionManager)
    /// @param refFee - discount on origination fee to be applied to loans using collateral reference address
    /// @param refType - discount on origination fee to be applied to loans using collateral reference address
    /// @param active - discount on origination fee to be applied to loans using collateral reference address
    /// @param restricted - discount on origination fee to be applied to loans using collateral reference address
    function setLoanObserver(uint256 refId, address refAddr, uint16 refFee, uint8 refType, bool active, bool restricted) external;

    /// @dev Allow users to create loans in pool that will be observed by observer with reference id `refId`
    /// @param refId - reference id of observer
    /// @param pool - address of GammaPool we are requesting information for
    function setPoolObserved(uint256 refId, address pool) external;

    /// @dev Prohibit users to create loans in pool that will be observed by observer with reference id `refId`
    /// @param refId - reference id of observer
    /// @param pool - address of GammaPool we are requesting information for
    function unsetPoolObserved(uint256 refId, address pool) external;

    /// @dev Check if a pool can use observer
    /// @param refId - reference id of observer
    /// @param pool - address of GammaPool we are requesting information for
    /// @return observed - if true observer can observe loans from pool
    function isPoolObserved(uint256 refId, address pool) external view returns(bool);

    /// @dev Allow a user address to open loans that can be observed by observer
    /// @param refId - reference id of observer
    /// @param user - address that can open loans that use observer
    /// @param isAllowed - if true observer can observe loans created by user
    function allowToBeObserved(uint256 refId, address user, bool isAllowed) external;

    /// @dev Check if a user can open loans that are observed by observer
    /// @param refId - reference id of observer
    /// @param user - address that can open loans that use observer
    /// @return allowed - if true observer can observe loans created by user
    function isAllowedToBeObserved(uint256 refId, address user) external view returns(bool);

    /// @dev Get observer identified with reference id `refId`
    /// @param refId - reference id of information containing collateral reference
    /// @return refAddr - address of ICollateralManager contract. Provides external collateral information
    /// @return refFee - discount for loan associated with this reference id
    /// @return refType - discount for loan associated with this reference id
    /// @return active - discount on origination fee to be applied to loans using collateral reference address
    /// @return restricted - discount on origination fee to be applied to loans using collateral reference address
    function getLoanObserver(uint256 refId) external view returns(address, uint16, uint8, bool, bool);

    /// @dev Get observer for a new loan being opened if the observer exists, the pool is registered with the observer,
    /// @dev and the user is allowed to create loans observed by observer identified by `refId`
    /// @param refId - reference id of information containing collateral reference
    /// @param pool - address asking collateral reference for (if not permissioned, it should revert. Normally a PositionManager)
    /// @param user - address asking collateral reference for
    /// @return refAddr - address of ICollateralManager contract. Provides external collateral information
    /// @return refFee - discount for loan associated with this reference id
    /// @return refType - discount for loan associated with this reference id
    function getPoolObserverByUser(uint16 refId, address pool, address user) external view returns(address, uint16, uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./IRateModel.sol";

/// @title Interface of Rate Model that calculates borrow rate according to a linear kinked rate model
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Interface for Linear Kinked rate model contract
/// @dev Inheritors of this interface has to also inherit AbstractRateModel
interface ILinearKinkedRateModel is IRateModel {
    /// @notice Base rate of Linear Kinked Rate model. This percentage is fixed and same amount is charged to every borrower
    /// @dev Base rate is expected to be of 18 decimals but of size uint64, therefore max value is approximately 1,844%
    /// @return baseRate - fixed rate that will be charged to liquidity borrowers
    function baseRate() external view returns(uint64);

    /// @notice Optimal Utilization rate of Linear Kinked Rate model. This percentage is the target utilization rate of the model
    /// @dev Optimal Utilization rate is expected to be of 18 decimals but of size uint64, although it must never be greater than 1e18
    /// @return optimalUtilRate - target utilization rate of model
    function optimalUtilRate() external view returns(uint64);

    /// @notice Slope1 of Linear Kinked Rate model. Rate of rate increase when utilization rate is below the target rate
    /// @dev Slope1 is expected to be lower than slope2
    /// @return slope1 - rate of increase of interest rate when utilization rate is below target rate
    function slope1() external view returns(uint64);

    /// @notice Slope2 of Linear Kinked Rate model. Rate of rate increase when utilization rate is above the target rate
    /// @dev Slope2 is expected to be greater than slope1
    /// @return slope2 - rate of increase of interest rate when utilization rate is above target rate
    function slope2() external view returns(uint64);

    /// @dev Get interest rate model parameters
    /// @param paramsStore - address storing rate params
    /// @param pool - address of contract to get parameters for
    /// @return baseRate - baseRate parameter of model
    /// @return optimalUtilRate - target utilization rate of model
    /// @return slope1 - factor parameter of model
    /// @return slope2 - maxApy parameter of model
    function getRateModelParams(address paramsStore, address pool) external view returns(uint64, uint64, uint64, uint64);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Interface of Interest Rate Model Store
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Interface of contract that saves and retrieves interest rate model parameters
interface IRateModel {
    /// @dev Function to validate interest rate model parameters
    /// @param _data - bytes parameters containing interest rate model parameters
    /// @return validation - true if parameters passed validation
    function validateParameters(bytes calldata _data) external view returns(bool);

    /// @dev Gets address of contract containing parameters for interest rate model
    /// @return address - address of smart contract that stores interest rate parameters
    function rateParamsStore() external view returns(address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Interface of Interest Rate Model Store
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Interface of contract that saves and retrieves interest rate model parameters
interface IRateParamsStore {

    /// @dev Rate model parameters
    struct RateParams {
        /// @dev Model parameters as bytes, needs to be decoded into model's specific struct
        bytes data;
        /// @dev Boolean value specifying if model parameters from store should be used
        bool active;
    }

    /// @dev Event emitted when an interest rate model's parameters are updated
    /// @param pool - address of GammaPool whose rate model parameters will be updated
    /// @param data - rate parameter model
    /// @param active - set rate parameter model active (if false bytes(0) should be returned)
    event RateParamsUpdate(address indexed pool, bytes data, bool active);

    /// @dev Update rate model parameters of `pool`
    /// @param pool - address of GammaPool whose rate model parameters will be updated
    /// @param data - rate parameter model
    /// @param active - set rate parameter model active (if false bytes(0) should be returned)
    function setRateParams(address pool, bytes calldata data, bool active) external;

    /// @dev Get rate model parameters for `pool`
    /// @param pool - address of GammaPool whose rate model parameters will be returned
    /// @return params - rate model parameters for `pool` as bytes
    function getRateParams(address pool) external view returns(RateParams memory params);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "../events/ILongStrategyEvents.sol";

/// @title Interface for Long Strategy
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used in strategies that borrow and repay liquidity loans
interface ILongStrategy is ILongStrategyEvents {
    /// @return loan to value threshold over which a loan is eligible for liquidation
    function ltvThreshold() external view returns(uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./IStrategyEvents.sol";

/// @title Long Strategy Events Interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Events emitted by all long strategy implementations
interface ILongStrategyEvents is IStrategyEvents {
    /// @dev Event emitted when a Loan is updated
    /// @param tokenId - unique id that identifies the loan in question
    /// @param tokensHeld - amounts of tokens held as collateral against the loan
    /// @param liquidity - liquidity invariant that was borrowed including accrued interest
    /// @param initLiquidity - initial liquidity borrowed excluding interest (principal)
    /// @param lpTokens - LP tokens borrowed excluding interest (principal)
    /// @param rateIndex - interest rate index of GammaPool at time loan is updated
    /// @param txType - transaction type. Possible values come from enum TX_TYPE
    event LoanUpdated(uint256 indexed tokenId, uint128[] tokensHeld, uint128 liquidity, uint128 initLiquidity, uint256 lpTokens, uint96 rateIndex, TX_TYPE indexed txType);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Strategy Events interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Events that should be emitted by all strategy implementations (root of all strategy events interfaces)
interface IStrategyEvents {
    enum TX_TYPE {
        DEPOSIT_LIQUIDITY,      // 0
        WITHDRAW_LIQUIDITY,     // 1
        DEPOSIT_RESERVES,       // 2
        WITHDRAW_RESERVES,      // 3
        INCREASE_COLLATERAL,    // 4
        DECREASE_COLLATERAL,    // 5
        REBALANCE_COLLATERAL,   // 6
        BORROW_LIQUIDITY,       // 7
        REPAY_LIQUIDITY,        // 8
        REPAY_LIQUIDITY_SET_RATIO,// 9
        REPAY_LIQUIDITY_WITH_LP,// 10
        LIQUIDATE,              // 11
        LIQUIDATE_WITH_LP,      // 12
        BATCH_LIQUIDATION,      // 13
        SYNC,                   // 14
        EXTERNAL_REBALANCE,     // 15
        EXTERNAL_LIQUIDATION,   // 16
        UPDATE_POOL }           // 17

    /// @dev Event emitted when the Pool's global state variables is updated
    /// @param lpTokenBalance - quantity of CFMM LP tokens deposited in the pool
    /// @param lpTokenBorrowed - quantity of CFMM LP tokens that have been borrowed from the pool (principal)
    /// @param lastBlockNumber - last block the Pool's where updated
    /// @param accFeeIndex - interest of total accrued interest in the GammaPool until current update
    /// @param lpTokenBorrowedPlusInterest - quantity of CFMM LP tokens that have been borrowed from the pool including interest
    /// @param lpInvariant - lpTokenBalance as invariant units
    /// @param borrowedInvariant - lpTokenBorrowedPlusInterest as invariant units
    /// @param cfmmReserves - reserves in CFMM. Used to track price
    /// @param txType - transaction type. Possible values come from enum TX_TYPE
    event PoolUpdated(uint256 lpTokenBalance, uint256 lpTokenBorrowed, uint40 lastBlockNumber, uint80 accFeeIndex,
        uint256 lpTokenBorrowedPlusInterest, uint128 lpInvariant, uint128 borrowedInvariant, uint128[] cfmmReserves, TX_TYPE indexed txType);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "../base/ILongStrategy.sol";

/// @title Interface for Borrow Strategy
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used in strategies that borrow liquidity
interface IBorrowStrategy is ILongStrategy {
    /// @dev Calculate and return dynamic origination fee in basis points
    /// @param baseOrigFee - base origination fee charge
    /// @param utilRate - current utilization rate of GammaPool
    /// @param lowUtilRate - low utilization rate threshold, used as a lower bound for the utilization rate
    /// @param minUtilRate1 - minimum utilization rate after which origination fee will start increasing exponentially
    /// @param minUtilRate2 - minimum utilization rate after which origination fee will start increasing linearly
    /// @param feeDivisor - fee divisor of formula for dynamic origination fee
    /// @return origFee - origination fee that will be applied to loan
    function calcDynamicOriginationFee(uint256 baseOrigFee, uint256 utilRate, uint256 lowUtilRate, uint256 minUtilRate1, uint256 minUtilRate2, uint256 feeDivisor) external view returns(uint256 origFee);

    /// @dev Deposit more collateral in loan identified by tokenId
    /// @param tokenId - unique id identifying loan
    /// @param ratio - ratio to rebalance collateral after increasing collateral
    /// @return tokensHeld - updated collateral token amounts backing loan
    function _increaseCollateral(uint256 tokenId, uint256[] calldata ratio) external returns(uint128[] memory tokensHeld);

    /// @dev Withdraw collateral from loan identified by tokenId
    /// @param tokenId - unique id identifying loan
    /// @param amounts - amounts of collateral tokens requested to withdraw
    /// @param to - destination address of receiver of collateral withdrawn
    /// @param ratio - ratio to rebalance collateral after withdrawing collateral
    /// @return tokensHeld - updated collateral token amounts backing loan
    function _decreaseCollateral(uint256 tokenId, uint128[] memory amounts, address to, uint256[] calldata ratio) external returns(uint128[] memory tokensHeld);

    /// @dev Borrow liquidity from the CFMM and add it to the debt and collateral of loan identified by tokenId
    /// @param tokenId - unique id identifying loan
    /// @param lpTokens - amount of CFMM LP tokens requested to short
    /// @param ratio - weights of collateral after borrowing liquidity
    /// @return liquidityBorrowed - liquidity amount that has been borrowed
    /// @return amounts - reserves quantities withdrawn from CFMM that correspond to the LP tokens shorted, now used as collateral
    /// @return tokensHeld - updated collateral token amounts backing loan
    function _borrowLiquidity(uint256 tokenId, uint256 lpTokens, uint256[] calldata ratio) external returns(uint256 liquidityBorrowed, uint256[] memory amounts, uint128[] memory tokensHeld);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "../base/ILongStrategy.sol";

/// @title Interface for Rebalance Strategy
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used in strategies that rebalance collateral from liquidity loans
interface IRebalanceStrategy is ILongStrategy {

    /// @dev Rebalance collateral amounts of loan identified by tokenId by purchasing or selling some of the collateral
    /// @param tokenId - unique id identifying loan
    /// @param deltas - collateral amounts being bought or sold (>0 buy, <0 sell), index matches tokensHeld[] index. Only n-1 tokens can be traded
    /// @param ratio - weights of collateral after borrowing liquidity
    /// @return tokensHeld - updated collateral token amounts backing loan
    function _rebalanceCollateral(uint256 tokenId, int256[] memory deltas, uint256[] calldata ratio) external returns(uint128[] memory tokensHeld);

    /// @dev Update pool liquidity debt and loan liquidity debt
    /// @param tokenId - (optional) unique id identifying loan
    /// @return loanLiquidityDebt - updated liquidity debt amount of loan
    /// @return poolLiquidityDebt - updated liquidity debt amount of pool
    function _updatePool(uint256 tokenId) external returns(uint256 loanLiquidityDebt, uint256 poolLiquidityDebt);

    /// @dev Calculate quantities to trade to rebalance collateral to desired `ratio`
    /// @param tokensHeld - loan collateral to rebalance
    /// @param reserves - reserve token quantities in CFMM
    /// @param ratio - desired ratio of collateral
    /// @return deltas - amount of collateral to trade to achieve desired `ratio`
    function calcDeltasForRatio(uint128[] memory tokensHeld, uint128[] memory reserves, uint256[] calldata ratio) external view returns(int256[] memory deltas);

    /// @dev Calculate quantities to trade to be able to close the `liquidity` amount
    /// @param tokensHeld - tokens held as collateral for liquidity to pay
    /// @param reserves - reserve token quantities in CFMM
    /// @param liquidity - amount of liquidity to pay
    /// @param collateralId - index of tokensHeld array to rebalance to (e.g. the collateral of the chosen index will be completely used up in repayment)
    /// @return deltas - amounts of collateral to trade to be able to repay `liquidity`
    function calcDeltasToClose(uint128[] memory tokensHeld, uint128[] memory reserves, uint256 liquidity, uint256 collateralId) external view returns(int256[] memory deltas);

    /// @dev Calculate quantities to trade to rebalance collateral so that after withdrawing `amounts` we achieve desired `ratio`
    /// @param amounts - amounts that will be withdrawn from collateral
    /// @param tokensHeld - loan collateral to rebalance
    /// @param reserves - reserve token quantities in CFMM
    /// @param ratio - desired ratio of collateral after withdrawing `amounts`
    /// @return deltas - amount of collateral to trade to achieve desired `ratio`
    function calcDeltasForWithdrawal(uint128[] memory amounts, uint128[] memory tokensHeld, uint128[] memory reserves, uint256[] calldata ratio) external view returns(int256[] memory deltas);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Library used to perform common ERC20 transactions
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Library performs approvals, transfers and views ERC20 state fields
library GammaSwapLibrary {

    error ST_Fail();
    error STF_Fail();
    error SA_Fail();
    error STE_Fail();

    /// @dev Check the ERC20 balance of an address
    /// @param _token - address of ERC20 token we're checking the balance of
    /// @param _address - Ethereum address we're checking for balance of ERC20 token
    /// @return balanceOf - amount of _token held in _address
    function balanceOf(address _token, address _address) internal view returns (uint256) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeCall(IERC20.balanceOf, _address));

        require(success && data.length >= 32);

        return abi.decode(data, (uint256));
    }

    /// @dev Get how much of an ERC20 token is in existence (minted)
    /// @param _token - address of ERC20 token we're checking the total minted amount of
    /// @return totalSupply - total amount of _token that is in existence (minted and not burned)
    function totalSupply(address _token) internal view returns (uint256) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeCall(IERC20.totalSupply,()));

        require(success && data.length >= 32);

        return abi.decode(data, (uint256));
    }

    /// @dev Get decimals of ERC20 token
    /// @param _token - address of ERC20 token we are getting the decimal information from
    /// @return decimals - decimals of ERC20 token
    function decimals(address _token) internal view returns (uint8) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("decimals()")); // requesting via ERC20 decimals implementation

        require(success && data.length >= 1);

        return abi.decode(data, (uint8));
    }

    /// @dev Get symbol of ERC20 token
    /// @param _token - address of ERC20 token we are getting the symbol information from
    /// @return symbol - symbol of ERC20 token
    function symbol(address _token) internal view returns (string memory) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("symbol()")); // requesting via ERC20 symbol implementation

        require(success && data.length >= 1);

        return abi.decode(data, (string));
    }

    /// @dev Get name of ERC20 token
    /// @param _token - address of ERC20 token we are getting the name information from
    /// @return name - name of ERC20 token
    function name(address _token) internal view returns (string memory) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("name()")); // requesting via ERC20 name implementation

        require(success && data.length >= 1);

        return abi.decode(data, (string));
    }

    /// @dev Safe transfer any ERC20 token, only used internally
    /// @param _token - address of ERC20 token that will be transferred
    /// @param _to - destination address where ERC20 token will be sent to
    /// @param _amount - quantity of ERC20 token to be transferred
    function safeTransfer(address _token, address _to, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeCall(IERC20.transfer, (_to, _amount)));

        if(!(success && (data.length == 0 || abi.decode(data, (bool))))) revert ST_Fail();
    }

    /// @dev Moves `amount` of ERC20 token `_token` from `_from` to `_to` using the allowance mechanism. `_amount` is then deducted from the caller's allowance.
    /// @param _token - address of ERC20 token that will be transferred
    /// @param _from - address sending _token (not necessarily caller's address)
    /// @param _to - address receiving _token
    /// @param _amount - amount of _token being sent
    function safeTransferFrom(address _token, address _from, address _to, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeCall(IERC20.transferFrom, (_from, _to, _amount)));

        if(!(success && (data.length == 0 || abi.decode(data, (bool))))) revert STF_Fail();
    }

    /// @dev Safe approve any ERC20 token to be spent by another address (`_spender`), only used internally
    /// @param _token - address of ERC20 token that will be approved
    /// @param _spender - address that will be granted approval to spend msg.sender tokens
    /// @param _amount - quantity of ERC20 token that `_spender` will be approved to spend
    function safeApprove(address _token, address _spender, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeCall(IERC20.approve, (_spender, _amount)));

        if(!(success && (data.length == 0 || abi.decode(data, (bool))))) revert SA_Fail();
    }

    /// @dev Safe transfer any ERC20 token, only used internally
    /// @param _to - destination address where ETH will be sent to
    /// @param _amount - quantity of ERC20 token to be transferred
    function safeTransferETH(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");

        if(!success) revert STE_Fail();
    }

    /// @dev Check if `account` is a smart contract's address and it has been instantiated (has code)
    /// @param account - Ethereum address to check if it's a smart contract address
    /// @return bool - true if it is a smart contract address
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function convertUint128ToUint256Array(uint128[] memory arr) internal pure returns(uint256[] memory res) {
        res = new uint256[](arr.length);
        for(uint256 i = 0; i < arr.length;) {
            res[i] = uint256(arr[i]);
            unchecked {
                ++i;
            }
        }
    }

    function convertUint128ToRatio(uint128[] memory arr) internal pure returns(uint256[] memory res) {
        res = new uint256[](arr.length);
        for(uint256 i = 0; i < arr.length;) {
            res[i] = uint256(arr[i]) * 1000;
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Math Library
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Library for performing various math operations
library GSMath {
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    /// @dev Returns the square root of `a`.
    /// @param a number to square root
    /// @return z square root of a
    function sqrt(uint256 a) internal pure returns (uint256 z) {
        if (a == 0) return 0;

        assembly {
            z := 181 // Should be 1, but this saves a multiplication later.

            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, a))
            r := or(shl(6, lt(0xffffffffffffffffff, shr(r, a))), r)
            r := or(shl(5, lt(0xffffffffff, shr(r, a))), r)
            r := or(shl(4, lt(0xffffff, shr(r, a))), r)
            z := shl(shr(1, r), z)

            // Doesn't overflow since y < 2**136 after above.
            z := shr(18, mul(z, add(shr(r, a), 65536))) // A mul() saved from z = 181.

            // Given worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))

            // If x+1 is a perfect square, the Babylonian method cycles between floor(sqrt(x)) and ceil(sqrt(x)).
            // We always return floor. Source https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            z := sub(z, lt(div(a, z), z))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "../interfaces/observer/ILoanObserverStore.sol";
import "../interfaces/IGammaPoolFactory.sol";

/// @title Library containing global storage variables for GammaPools according to App Storage pattern
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Structs are packed to minimize storage size
library LibStorage {

    /// @dev Loan struct used to track relevant liquidity loan information
    struct Loan {
        /// @dev Loan counter, used to generate unique tokenId which indentifies the loan in the GammaPool
        uint256 id;

        // 1x256 bits
        /// @dev GammaPool address loan belongs to
        address poolId; // 160 bits
        /// @dev Index of GammaPool interest rate at time loan is created/updated, max 7.9% trillion
        uint96 rateIndex; // 96 bits

        // 1x256 bits
        /// @dev Initial loan debt in liquidity invariant units. Only increase when more liquidity is borrowed, decreases when liquidity is paid
        uint128 initLiquidity; // 128 bits
        /// @dev Loan debt in liquidity invariant units, increases with every update according to how many blocks have passed
        uint128 liquidity; // 128 bits

        /// @dev Initial loan debt in terms of LP tokens at time liquidity was borrowed, updates along with initLiquidity
        uint256 lpTokens;
        /// @dev Reserve tokens held as collateral for the liquidity debt, indices match GammaPool's tokens[] array indices
        uint128[] tokensHeld; // array of 128 bit numbers

        /// @dev price at which loan was opened
        uint256 px;

        /// @dev reference address holding additional collateral information for the loan
        address refAddr;
        /// @dev reference fee, typically used for loans using a collateral reference addresses
        uint16 refFee;
        /// @dev reference type, typically used for loans using a collateral reference addresses
        uint8 refType;
    }

    /// @dev Storage struct used to track GammaPool's state variables
    /// @notice `LP_TOKEN_TOTAL = LP_TOKEN_BALANCE + LP_TOKEN_BORROWED_PLUS_INTEREST` and `TOTAL_INVARIANT = BORROWED_INVARIANT + LP_INVARIANT`
    struct Storage {
        // 1x256 bits
        /// @dev factory - address of factory contract that instantiated this GammaPool
        address factory; // 160 bits
        /// @dev Protocol id of the implementation contract for this GammaPool
        uint16 protocolId; // 16 bits
        /// @dev unlocked - flag used in mutex implementation (1 = unlocked, 0 = locked). Initialized at 1
        uint8 unlocked; // 8 bits
        /// @dev EMA of utilization rate
        uint32 emaUtilRate; // 32 bits, 6 decimal number
        /// @dev Multiplier of EMA used to calculate emaUtilRate
        uint8 emaMultiplier; // 8 bits, 1 decimals (0 = 0%, 1 = 0.1%, max 255 = 25.5%)
        /// @dev Minimum utilization rate at which point we start using the dynamic fee
        uint8 minUtilRate1; // 8 bits, 0 decimals (0 = 0%, 100 = 100%), default is 85. If set to 100, dynamic orig fee is disabled
        /// @dev Minimum utilization rate at which point we start using the dynamic fee
        uint8 minUtilRate2; // 8 bits, 0 decimals (0 = 0%, 100 = 100%), default is 65. If set to 100, dynamic orig fee is disabled
        /// @dev Dynamic origination fee divisor, to cap at 99% use 16384 = 2^(99-85)
        uint16 feeDivisor; // 16 bits, 0 decimals, max is 5 digit integer 65535, formula is 2^(maxUtilRate - minUtilRate1)

        // 3x256 bits, LP Tokens
        /// @dev Quantity of CFMM's LP tokens deposited in GammaPool by liquidity providers
        uint256 LP_TOKEN_BALANCE;
        /// @dev Quantity of CFMM's LP tokens that have been borrowed by liquidity borrowers excluding accrued interest (principal)
        uint256 LP_TOKEN_BORROWED;
        /// @dev Quantity of CFMM's LP tokens that have been borrowed by liquidity borrowers including accrued interest
        uint256 LP_TOKEN_BORROWED_PLUS_INTEREST;

        // 1x256 bits, Invariants
        /// @dev Quantity of CFMM's liquidity invariant that has been borrowed including accrued interest, maps to LP_TOKEN_BORROWED_PLUS_INTEREST
        uint128 BORROWED_INVARIANT; // 128 bits
        /// @dev Quantity of CFMM's liquidity invariant held in GammaPool as LP tokens, maps to LP_TOKEN_BALANCE
        uint128 LP_INVARIANT; // 128 bits

        // 3x256 bits, Rates & CFMM
        /// @dev cfmm - address of CFMM this GammaPool is for
        address cfmm; // 160 bits
        /// @dev GammaPool's ever increasing interest rate index, tracks interest accrued through CFMM and liquidity loans, max 120.8% million
        uint80 accFeeIndex; // 80 bits
        /// @dev GammaPool's Margin threshold (1 - 255 => 0.1% to 25.5%) LTV = 1 - ltvThreshold
        uint8 ltvThreshold; // 8 bits
        /// @dev GammaPool's liquidation fee in basis points (1 - 255 => 0.01% to 2.55%)
        uint8 liquidationFee; // 8 bits
        /// @dev External swap fee in basis points, max 255 basis points = 2.55%
        uint8 extSwapFee; // 8 bits
        /// @dev Loan opening origination fee in basis points
        uint16 origFee; // 16 bits
        /// @dev LAST_BLOCK_NUMBER - last block an update to the GammaPool's global storage variables happened
        uint40 LAST_BLOCK_NUMBER; // 40 bits
        /// @dev Percent accrual in CFMM invariant since last update in a different block, max 1,844.67%
        uint64 lastCFMMFeeIndex; // 64 bits
        /// @dev Total liquidity invariant amount in CFMM (from GammaPool and others), read in last update to GammaPool's storage variables
        uint128 lastCFMMInvariant; // 128 bits
        /// @dev Total LP token supply from CFMM (belonging to GammaPool and others), read in last update to GammaPool's storage variables
        uint256 lastCFMMTotalSupply;

        /// @dev The ID of the next loan that will be minted. Initialized at 1
        uint256 nextId;

        /// @dev Function IDs so that we can pause individual functions
        uint256 funcIds;

        // ERC20 fields
        /// @dev Total supply of GammaPool's own ERC20 token representing the liquidity of depositors to the CFMM through the GammaPool
        uint256 totalSupply;
        /// @dev Balance of GammaPool's ERC20 token, this is used to keep track of the balances of different addresses as defined in the ERC20 standard
        mapping(address => uint256) balanceOf;
        /// @dev Spending allowance of GammaPool's ERC20 token, this is used to keep track of the spending allowance of different addresses as defined in the ERC20 standard
        mapping(address => mapping(address => uint256)) allowance;

        /// @dev Mapping of all loans issued by the GammaPool, the key is the tokenId (unique identifier) of the loan
        mapping(uint256 => Loan) loans;

        /// @dev Minimum liquidity that can be borrowed or remain for a loan
        uint72 minBorrow;

        // tokens and balances
        /// @dev ERC20 tokens of CFMM
        address[] tokens;
        /// @dev Decimals of tokens in CFMM, indices match tokens[] array
        uint8[] decimals;
        /// @dev Amounts of ERC20 tokens from the CFMM held as collateral in the GammaPool. Equals to the sum of all tokensHeld[] quantities in all loans
        uint128[] TOKEN_BALANCE;
        /// @dev Amounts of ERC20 tokens from the CFMM held in the CFMM as reserve quantities. Used to log prices quoted by the CFMM during updates to the GammaPool
        uint128[] CFMM_RESERVES;
        /// @dev List of all tokenIds created in GammaPool
        uint256[] tokenIds;

        // Custom parameters
        /// @dev Custom fields
        mapping(uint256 => bytes32) fields;
        /// @dev Custom object (e.g. struct)
        bytes obj;
    }

    error Initialized();

    /// @dev Initializes global storage variables of GammaPool, must be called right after instantiating GammaPool
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param _factory - address of factory that created this GammaPool
    /// @param _cfmm - address of CFMM this GammaPool is for
    /// @param _protocolId - protocol id of the implementation contract for this GammaPool
    /// @param _tokens - tokens of CFMM this GammaPool is for
    /// @param _decimals -decimals of the tokens of the CFMM the GammaPool is for, indices must match tokens array
    /// @param _minBorrow - minimum amount of liquidity that can be borrowed or left unpaid in a loan
    function initialize(Storage storage self, address _factory, address _cfmm, uint16 _protocolId, address[] calldata _tokens, uint8[] calldata _decimals, uint72 _minBorrow) internal {
        if(self.factory != address(0)) revert Initialized();// cannot initialize twice

        self.factory = _factory;
        self.protocolId = _protocolId;
        self.cfmm = _cfmm;
        self.tokens = _tokens;
        self.decimals = _decimals;
        self.minBorrow =_minBorrow;

        self.lastCFMMFeeIndex = 1e18;
        self.accFeeIndex = 1e18; // initialized as 1 with 18 decimal places
        self.LAST_BLOCK_NUMBER = uint40(block.number); // first block update number is block at initialization

        self.nextId = 1; // loan counter starts at 1
        self.unlocked = 1; // mutex initialized as unlocked

        self.ltvThreshold = 5; // 50 basis points
        self.liquidationFee = 25; // 25 basis points
        self.origFee = 2;
        self.extSwapFee = 10;

        self.emaMultiplier = 10; // ema smoothing factor is 10/1000 = 1%
        self.minUtilRate1 = 90; // min util rate 1 is 90%
        self.minUtilRate2 = 85; // min util rate 2 is 85%
        self.feeDivisor = 2048; // 25% orig fee at 99% util rate

        self.TOKEN_BALANCE = new uint128[](_tokens.length);
        self.CFMM_RESERVES = new uint128[](_tokens.length);
    }

    /// @dev Creates an empty loan struct in the GammaPool and initializes it to start tracking borrowed liquidity
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param _tokenCount - number of tokens in the CFMM the loan is for
    /// @param refId - reference id of CollateralManager set up in CollateralReferenceStore (e.g. GammaPoolFactory)
    /// @return _tokenId - unique tokenId used to get and update loan
    function createLoan(Storage storage self, uint256 _tokenCount, uint16 refId) internal returns(uint256 _tokenId) {
        // get loan counter for GammaPool and increase it by 1 for the next loan
        uint256 id = self.nextId++;

        // create unique tokenId to identify loan across all GammaPools. _tokenId is hash of GammaPool address, sender address, and loan counter
        _tokenId = uint256(keccak256(abi.encode(msg.sender, address(this), id)));

        address refAddr;
        uint16 refFee;
        uint8 refType;
        if(refId > 0 ) {
            (refAddr, refFee, refType) = ILoanObserverStore(self.factory).getPoolObserverByUser(refId, address(this), msg.sender);
        }

        // instantiate Loan struct and store it mapped to _tokenId
        self.loans[_tokenId] = Loan({
            id: id, // loan counter
            poolId: address(this), // GammaPool address loan belongs to
            rateIndex: self.accFeeIndex, // initialized as current interest rate index
            initLiquidity: 0,
            liquidity: 0,
            lpTokens: 0,
            tokensHeld: new uint128[](_tokenCount),
            px: 0,
            refAddr: refAddr,
            refFee: refFee,
            refType: refType
        });

        self.tokenIds.push(_tokenId);
    }

    /// @dev Get custom field as uint256
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of uint256 field
    /// @return field - value of custom field from storage as uint256
    function getUint256(Storage storage self, uint256 idx) internal view returns(uint256) {
        return uint256(self.fields[idx]);
    }

    /// @dev Set custom field as uint256
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of uint256 field
    /// @param val - value of custom field to store in storage as uint256
    function setUint256(Storage storage self, uint256 idx, uint256 val) internal {
        self.fields[idx] = bytes32(val);
    }

    /// @dev Get custom field as int256
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of int256 field
    /// @return field - value of custom field from storage as int256
    function getInt256(Storage storage self, uint256 idx) internal view returns(int256) {
        return int256(uint256(self.fields[idx]));
    }

    /// @dev Set custom field as int256
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of int256 field
    /// @param val - value of custom field to store in storage as int256
    function setInt256(Storage storage self, uint256 idx, int256 val) internal {
        self.fields[idx] = bytes32(uint256(val));
    }

    /// @dev Get custom field as bytes32
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of bytes32 field
    /// @return field - value of custom field from storage as bytes32
    function getBytes32(Storage storage self, uint256 idx) internal view returns(bytes32) {
        return self.fields[idx];
    }

    /// @dev Set custom field as bytes32
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of bytes32 field
    /// @param val - value of custom field to store in storage as bytes32
    function setBytes32(Storage storage self, uint256 idx, bytes32 val) internal {
        self.fields[idx] = val;
    }

    /// @dev Get custom field as address
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of address field
    /// @return field - value of custom field from storage as address
    function getAddress(Storage storage self, uint256 idx) internal view returns(address) {
        return address(uint160(uint256(self.fields[idx])));
    }

    /// @dev Set custom field as address
    /// @param self - pointer to storage variables (doesn't need to be passed)
    /// @param idx - index of mapping of address field
    /// @param val - value of custom field to store in storage as address
    function setAddress(Storage storage self, uint256 idx, address val) internal {
        self.fields[idx] = bytes32(uint256(uint160(val)));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "../interfaces/rates/IRateModel.sol";

/// @title Abstract contract to calculate the utilization rate of the GammaPool.
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice All rate models inherit this contract since all rate models depend on utilization rate
/// @dev All strategies inherit a rate model in its base and therefore all strategies inherit this contract.
abstract contract AbstractRateModel is IRateModel {
    /// @notice Calculates the utilization rate of the pool. How much borrowed out of how much liquidity is in the AMM through GammaSwap
    /// @dev The utilization rate always has 18 decimal places, even if the reserve tokens do not. Everything is adjusted to 18 decimal points
    /// @param lpInvariant - invariant amount available to be borrowed from LP tokens deposited in GammaSwap
    /// @param borrowedInvariant - invariant amount borrowed from GammaSwap
    /// @return utilizationRate - borrowedInvariant / (lpInvariant + borrowedInvairant)
    function calcUtilizationRate(uint256 lpInvariant, uint256 borrowedInvariant) internal virtual view returns(uint256) {
        uint256 totalInvariant = lpInvariant + borrowedInvariant; // total invariant belonging to liquidity depositors in GammaSwap
        if(totalInvariant == 0) // avoid division by zero
            return 0;

        return borrowedInvariant * 1e18 / totalInvariant; // utilization rate will always have 18 decimals
    }

    /// @notice Calculates the borrow rate according to an implementation formula
    /// @dev The borrow rate is expected to always have 18 decimal places
    /// @param lpInvariant - invariant amount available to be borrowed from LP tokens deposited in GammaSwap
    /// @param borrowedInvariant - invariant amount borrowed from GammaSwap
    /// @param paramsStore - address of rate params store, to get overriding parameter values
    /// @param pool - address of pool asking for rate calculation
    /// @return borrowRate - rate that will be charged to liquidity borrowers
    /// @return utilizationRate - utilization rate used to calculate the borrow rate
    /// @return maxCFMMFeeLeverage - maxLeverage number with 3 decimals. E.g. 5000 = 5
    /// @return spread - additional fee to add to cfmmFeeIndex to create spread
    function calcBorrowRate(uint256 lpInvariant, uint256 borrowedInvariant, address paramsStore, address pool) public virtual view returns(uint256, uint256, uint256, uint256);

    /// @dev See {IRateModel-rateParamsStore}
    function rateParamsStore() public override virtual view returns(address) {
        return _rateParamsStore();
    }

    /// @dev Return contract holding rate parameters
    function _rateParamsStore() internal virtual view returns(address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "../interfaces/rates/storage/IRateParamsStore.sol";
import "../interfaces/rates/ILinearKinkedRateModel.sol";
import "../libraries/GSMath.sol";
import "./AbstractRateModel.sol";

/// @title Linear Kinked Rate Model used to calculate the yearly rate charged to liquidity borrowers according to the current utilization rate of the pool
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Function that is defined here is the calcBorrowRate
/// @dev This contract is abstract and therefore supposed to be inherited by BaseStrategy. Modeled after AAVE's rate model
abstract contract LinearKinkedRateModel is AbstractRateModel, ILinearKinkedRateModel {

    /// @dev Error thrown when optimal util rate set to 0 or greater or equal to 1e18
    error OptimalUtilRate();
    /// @dev Error thrown when slope2 < slope1
    error Slope2LtSlope1();

    /// @dev struct containing model rate parameters, used in validation
    struct ModelRateParams {
        /// @dev baseRate - minimum rate charged to all loans
        uint64 baseRate;
        /// @dev optimalUtilRate - target utilization rate of model
        uint64 optimalUtilRate;
        /// @dev slope1 - factor parameter of model
        uint64 slope1;
        /// @dev slope2 - maxApy parameter of model
        uint64 slope2;
    }

    /// @dev See {ILinearKinkedRateModel-baseRate}.
    uint64 immutable public override baseRate;

    /// @dev See {ILinearKinkedRateModel-optimalUtilRate}.
    uint64 immutable public override optimalUtilRate;

    /// @dev See {ILinearKinkedRateModel-slope1}.
    uint64 immutable public override slope1;

    /// @dev See {ILinearKinkedRateModel-slope2}.
    uint64 immutable public override slope2;

    /// @dev Initializes the contract by setting `_baseRate`, `_optimalUtilRate`, `_slope1`, and `_slope2`. the target rate (`_optimalUtilRate`) cannot be greater than 1e18
    constructor(uint64 _baseRate, uint64 _optimalUtilRate, uint64 _slope1, uint64 _slope2) {
        if(!(_optimalUtilRate > 0 && _optimalUtilRate < 1e18)) revert OptimalUtilRate();
        if(_slope2 < _slope1) revert Slope2LtSlope1();

        baseRate = _baseRate;
        optimalUtilRate = _optimalUtilRate;
        slope1 = _slope1;
        slope2 = _slope2;
    }

    /// @notice formula is as follows: max{ baseRate + (utilRate * slope1) / optimalRate, baseRate + slope1 + slope2 * (utilRate - optimalRate) / (1 - optimalUtilRate) }
    /// @dev See {AbstractRateModel-calcBorrowRate}.
    function calcBorrowRate(uint256 lpInvariant, uint256 borrowedInvariant, address paramsStore, address pool) public virtual override view returns(uint256 borrowRate, uint256 utilizationRate, uint256 maxLeverage, uint256 spread) {
        utilizationRate = calcUtilizationRate(lpInvariant, borrowedInvariant); // at most 1e18 < max(uint64)
        (uint64 _baseRate, uint64 _optimalUtilRate, uint64 _slope1, uint64 _slope2) = getRateModelParams(paramsStore, pool);
        maxLeverage = _calcMaxLeverage(_optimalUtilRate);
        if(utilizationRate == 0) { // if utilization rate is zero, the borrow rate is zero
            return (0, 0, maxLeverage, 1e18);
        }
        unchecked {
            if(utilizationRate <= _optimalUtilRate) { // if pool funds are underutilized use slope1
                uint256 variableRate = (utilizationRate * _slope1) / _optimalUtilRate; // at most uint128
                borrowRate = _baseRate + variableRate;
            } else { // if pool funds are overutilized use slope2
                uint256 utilizationRateDiff = utilizationRate - _optimalUtilRate; // at most 1e18 - 1 < max(uint64)
                uint256 variableRate = (utilizationRateDiff * _slope2) / (1e18 - _optimalUtilRate); // at most uint128
                borrowRate = _baseRate + _slope1 + variableRate;
            }
            spread = _calcSpread(borrowRate);
        }
    }

    /// @dev return max leverage based on optimal utilization rate times 1000 (e.g. 1000 / (1 - optimalRate)
    function _calcMaxLeverage(uint256 _optimalUtilRate) internal virtual view returns(uint256) {
        return GSMath.min(1e21 / (1e18 - _optimalUtilRate), 100000); // capped at 100
    }

    /// @dev return spread to add to the CFMMFeeIndex as the borrow rate * 10
    function _calcSpread(uint256 borrowRate) internal virtual view returns(uint256) {
        return 1e18 + borrowRate * 10;
    }

    /// @dev Get interest rate model parameters
    /// @param paramsStore - address storing rate params
    /// @param pool - address of contract to get parameters for
    /// @return baseRate - baseRate parameter of model
    /// @return optimalUtilRate - target utilization rate of model
    /// @return slope1 - factor parameter of model
    /// @return slope2 - maxApy parameter of model
    function getRateModelParams(address paramsStore, address pool) public override virtual view returns(uint64, uint64, uint64, uint64) {
        IRateParamsStore.RateParams memory rateParams = IRateParamsStore(paramsStore).getRateParams(pool);
        if(!rateParams.active) {
            return (baseRate, optimalUtilRate, slope1, slope2);
        }
        ModelRateParams memory params = abi.decode(rateParams.data, (ModelRateParams));
        return (params.baseRate, params.optimalUtilRate, params.slope1, params.slope2);
    }

    /// @dev See {IRateModel-validateParameters}.
    function validateParameters(bytes calldata _data) external override virtual view returns(bool) {
        ModelRateParams memory params = abi.decode(_data, (ModelRateParams));
        _validateParameters(params.baseRate, params.optimalUtilRate, params.slope1, params.slope2);
        return true;
    }

    /// @dev Validate interest rate model parameters
    /// @param _baseRate - baseRate parameter of model
    /// @param _optimalUtilRate - target utilization rate of model
    /// @param _slope1 - factor parameter of model
    /// @param _slope2 - maxApy parameter of model
    /// @return bool - return true if model passed validation or error if it failed
    function _validateParameters(uint64 _baseRate, uint64 _optimalUtilRate, uint64 _slope1, uint64 _slope2) internal virtual view returns(bool) {
        if(!(_optimalUtilRate > 0 && _optimalUtilRate < 1e18)) revert OptimalUtilRate();
        if(_slope2 < _slope1) revert Slope2LtSlope1();
        return true;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "../libraries/LibStorage.sol";

/// @title Contract that implements App Storage pattern in GammaPool contracts
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice This pattern is based on Nick Mudge's App Storage implementation (https://dev.to/mudgen/appstorage-pattern-for-state-variables-in-solidity-3lki)
/// @dev This contract has to be inherited as the root contract in an inheritance hierarchy
abstract contract AppStorage {

    /// @notice Global storage variables of GammaPool according to App Storage pattern
    /// @dev No other state variable should be defined before this state variable
    LibStorage.Storage internal s;

    error Locked();

    /// @dev Mutex implementation to prevent a contract from calling itself, directly or indirectly.
    modifier lock() {
        _lock();
        _;
        _unlock();
    }

    function _lock() internal {
        if(s.unlocked != 1) revert Locked();
        s.unlocked = 0;
    }

    function _unlock() internal {
        s.unlocked = 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BaseLongStrategy.sol";

/// @title Abstract base contract for Borrow Strategy implementation
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice All functions here are internal, external functions implemented in BaseLongStrategy as part of ILongStrategy implementation
/// @dev Only defines common functions that would be used by all contracts that borrow liquidity
abstract contract BaseBorrowStrategy is BaseLongStrategy {
    /// @dev Calculate loan price every time more liquidity is borrowed
    /// @param newLiquidity - new added liquidity debt to loan
    /// @param currPrice - current entry price of loan
    /// @param liquidity - existing liquidity debt of loan
    /// @param lastPx - current entry price of loan
    /// @return px - reserve token amounts in CFMM that liquidity invariant converted to
    function updateLoanPrice(uint256 newLiquidity, uint256 currPrice, uint256 liquidity, uint256 lastPx) internal virtual view returns(uint256) {
        uint256 totalLiquidity = newLiquidity + liquidity;
        uint256 totalLiquidityPx = newLiquidity * currPrice + liquidity * lastPx;
        return totalLiquidityPx / totalLiquidity;
    }

    /// @return origFee - base origination fee charged to every new loan that is issued
    function originationFee() internal virtual view returns(uint16) {
        return s.origFee;
    }

    /// @dev Calculate and return dynamic origination fee in basis points
    /// @param liquidityBorrowed - new liquidity borrowed from GammaSwap
    /// @param borrowedInvariant - invariant amount already borrowed from GammaSwap (before liquidityBorrowed is applied)
    /// @param lpInvariant - invariant amount available to be borrowed from LP tokens deposited in GammaSwap (before liquidityBorrowed is applied)
    /// @param lowUtilRate - low utilization rate threshold
    /// @param discount - discount in basis points to apply to origination fee
    /// @return origFee - origination fee that will be applied to loan
    function _calcOriginationFee(uint256 liquidityBorrowed, uint256 borrowedInvariant, uint256 lpInvariant, uint256 lowUtilRate, uint256 discount) internal virtual view returns(uint256 origFee) {
        uint256 utilRate = calcUtilizationRate(lpInvariant - liquidityBorrowed, borrowedInvariant + liquidityBorrowed) / 1e16;// convert utilizationRate to integer
        // check if the new utilizationRate is higher than lowUtilRate or less than lowUtilRate. If less than lowUtilRate, take lowUtilRate, if higher than lowUtilRate take higher one
        lowUtilRate = lowUtilRate / 1e4; // convert lowUtilRate to integer

        origFee = _calcDynamicOriginationFee(originationFee(), utilRate, lowUtilRate, s.minUtilRate1, s.minUtilRate2, s.feeDivisor);

        unchecked {
            origFee = origFee - GSMath.min(origFee, discount);
        }
    }

    /// @dev Calculate and return dynamic origination fee in basis points
    /// @param baseOrigFee - base origination fee charge
    /// @param utilRate - current utilization rate of GammaPool
    /// @param lowUtilRate - low utilization rate threshold, used as a lower bound for the utilization rate
    /// @param minUtilRate1 - minimum utilization rate 1 after which origination fee will start increasing exponentially
    /// @param minUtilRate2 - minimum utilization rate 2 after which origination fee will start increasing linearly
    /// @param feeDivisor - fee divisor of formula for dynamic origination fee
    /// @return origFee - origination fee that will be applied to loan
    function _calcDynamicOriginationFee(uint256 baseOrigFee, uint256 utilRate, uint256 lowUtilRate, uint256 minUtilRate1, uint256 minUtilRate2, uint256 feeDivisor) internal virtual view returns(uint256) {
        utilRate = GSMath.max(utilRate, lowUtilRate);
        if(utilRate > minUtilRate2) {
            unchecked {
                baseOrigFee = GSMath.max(utilRate - minUtilRate2, baseOrigFee);
            }
        }
        if(utilRate > minUtilRate1) {
            uint256 diff;
            unchecked {
                diff = utilRate - minUtilRate1;
            }
            baseOrigFee = GSMath.min(GSMath.max(baseOrigFee, (2 ** diff) * 10000 / feeDivisor), 10000);
        }
        return baseOrigFee;
    }

    /// @dev Mint GS LP tokens as origination fees payments to protocol
    /// @param origFeeInv - origination fee in liquidity invariant terms
    /// @param totalInvariant - total liquidity invariant in GammaPool (borrowed and in CFMM)
    function mintOrigFeeToDevs(uint256 origFeeInv, uint256 totalInvariant) internal virtual {
        (address _to, ,uint256 _origFeeShare,) = IGammaPoolFactory(s.factory).getPoolFee(address(this));
        if(_to != address(0) && _origFeeShare > 0) {
            uint256 devShares = origFeeInv * s.totalSupply * _origFeeShare / (totalInvariant * 1000);
            if(devShares > 0) {
                _mint(_to, devShares); // protocol fee is paid as dilution
            }
        }
    }

    /// @dev Account for newly borrowed liquidity debt
    /// @param _loan - loan that incurred debt
    /// @param lpTokens - CFMM LP tokens borrowed
    /// @return liquidityBorrowed - increase in liquidity debt
    /// @return liquidity - new loan liquidity debt
    function openLoan(LibStorage.Loan storage _loan, uint256 lpTokens) internal virtual returns(uint256 liquidityBorrowed, uint256 liquidity) {
        // Liquidity invariant in CFMM, updated at start of transaction that opens loan. Overstated after loan opening
        uint256 lastCFMMInvariant = s.lastCFMMInvariant;
        // Total CFMM LP tokens in existence, updated at start of transaction that opens loan. Overstated after loan opening
        uint256 lastCFMMTotalSupply = s.lastCFMMTotalSupply;

        // Calculate borrowed liquidity invariant excluding loan origination fee
        // Irrelevant that lastCFMMInvariant and lastCFMMInvariant are overstated since their conversion rate did not change
        uint256 liquidityBorrowedExFee = convertLPToInvariantRoundUp(lpTokens, lastCFMMInvariant, lastCFMMTotalSupply, true);

        liquidity = _loan.liquidity;
        uint256 initLiquidity = minBorrow(); // avoid second sload

        // Can't borrow less than minimum liquidity to avoid rounding issues
        if (liquidity == 0 && liquidityBorrowedExFee < initLiquidity) revert MinBorrow();

        uint256 borrowedInvariant = s.BORROWED_INVARIANT;

        // Calculate loan origination fee
        uint256 lpTokenOrigFee = lpTokens * _calcOriginationFee(liquidityBorrowedExFee, borrowedInvariant, s.LP_INVARIANT, s.emaUtilRate, _loan.refFee) / 10000;

        checkExpectedUtilizationRate(lpTokens + lpTokenOrigFee, true);

        // Pay origination fee share as protocol revenue
        liquidityBorrowed = convertLPToInvariantRoundUp(lpTokenOrigFee, lastCFMMInvariant, lastCFMMTotalSupply, true);
        mintOrigFeeToDevs(liquidityBorrowed, borrowedInvariant + s.LP_INVARIANT);

        // Calculate borrowed liquidity invariant including origination fee
        liquidityBorrowed = liquidityBorrowed + liquidityBorrowedExFee;

        // Add liquidity invariant borrowed including origination fee to total pool liquidity invariant borrowed
        borrowedInvariant = borrowedInvariant + liquidityBorrowed;

        s.BORROWED_INVARIANT = uint128(borrowedInvariant);
        s.LP_TOKEN_BORROWED = s.LP_TOKEN_BORROWED + lpTokens; // Track total CFMM LP tokens borrowed from pool (principal)

        // Update CFMM LP tokens deposited in GammaPool, this could be higher than expected. Excess CFMM LP tokens accrue to GS LPs
        uint256 lpTokenBalance = GammaSwapLibrary.balanceOf(s.cfmm, address(this));
        s.LP_TOKEN_BALANCE = lpTokenBalance;

        // Update liquidity invariant from CFMM LP tokens deposited in GammaPool
        uint256 lpInvariant = convertLPToInvariant(lpTokenBalance, lastCFMMInvariant, lastCFMMTotalSupply);
        s.LP_INVARIANT = uint128(lpInvariant);

        // Add CFMM LP tokens borrowed (principal) plus origination fee to pool's total CFMM LP tokens borrowed including accrued interest
        s.LP_TOKEN_BORROWED_PLUS_INTEREST = s.LP_TOKEN_BORROWED_PLUS_INTEREST + lpTokens + lpTokenOrigFee;

        liquidity = liquidity + liquidityBorrowed;
        if(liquidity < initLiquidity) revert MinBorrow();

        // Update loan's total liquidity debt and principal amounts
        initLiquidity = _loan.initLiquidity;
        _loan.px = updateLoanPrice(liquidityBorrowedExFee, getCurrentCFMMPrice(), initLiquidity, _loan.px);
        _loan.liquidity = uint128(liquidity);
        _loan.initLiquidity = uint128(initLiquidity + liquidityBorrowedExFee);
        _loan.lpTokens = _loan.lpTokens + lpTokens;
    }

    /// @return currPrice - calculates and gets current price at CFMM
    function getCurrentCFMMPrice() internal virtual view returns(uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "../../interfaces/strategies/base/ILongStrategy.sol";
import "../../interfaces/observer/ILoanObserver.sol";
import "./BaseStrategy.sol";

/// @title Base Long Strategy abstract contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Common functions used by all strategy implementations that need access to loans
/// @dev This contract inherits from BaseStrategy and should normally be inherited by Borrow, Repay, Rebalance, and Liquidation strategies
abstract contract BaseLongStrategy is ILongStrategy, BaseStrategy {

    error Forbidden();
    error Margin();
    error MinBorrow();
    error LoanDoesNotExist();
    error InvalidAmountsLength();

    /// @dev Minimum number of liquidity borrowed to avoid rounding issues. Assumes invariant >= CFMM LP Token. Default should be 1e3
    function minBorrow() internal view virtual returns(uint256) {
        return s.minBorrow;
    }

    /// @dev Minimum amount of liquidity to pay to avoid rounding issues. Assumes invariant >= CFMM LP Token. Default should be 1e3
    function minPay() internal view virtual returns(uint256);

    /// @dev Perform necessary transaction before repaying liquidity debt
    /// @param _loan - liquidity loan that will be repaid
    /// @param amounts - collateral amounts that will be used to repay liquidity loan
    function beforeRepay(LibStorage.Loan storage _loan, uint256[] memory amounts) internal virtual;

    /// @dev Calculate token amounts the liquidity invariant amount converts to in the CFMM
    /// @param reserves - token quantites in CFMM used to calculate tokens to repay
    /// @param liquidity - liquidity invariant units from CFMM
    /// @param maxAmounts - max token amounts to repay
    /// @return amounts - reserve token amounts in CFMM that liquidity invariant converted to
    function calcTokensToRepay(uint128[] memory reserves, uint256 liquidity, uint128[] memory maxAmounts) internal virtual view returns(uint256[] memory amounts);

    /// @dev Perform necessary transaction before repaying swapping tokens
    /// @param _loan - liquidity loan whose collateral will be swapped
    /// @param deltas - collateral amounts that will be swapped (> 0 buy, < 0 sell, 0 ignore)
    /// @param reserves - most up to date CFMM reserves
    /// @return outAmts - collateral amounts that will be sent out of GammaPool (sold)
    /// @return inAmts - collateral amounts that will be received in GammaPool (bought)
    function beforeSwapTokens(LibStorage.Loan storage _loan, int256[] memory deltas, uint128[] memory reserves) internal virtual returns(uint256[] memory outAmts, uint256[] memory inAmts);

    /// @dev Calculate tokens liquidity invariant amount converts to in CFMM
    /// @param _loan - liquidity loan whose collateral will be traded
    /// @param outAmts - expected amounts to send to CFMM (sold),
    /// @param inAmts - expected amounts to receive from CFMM (bought)
    function swapTokens(LibStorage.Loan storage _loan, uint256[] memory outAmts, uint256[] memory inAmts) internal virtual;

    /// @return ltvThreshold - max ltv ratio acceptable before a loan is eligible for liquidation
    function _ltvThreshold() internal virtual view returns(uint16) {
        unchecked {
            return 10000 - uint16(s.ltvThreshold) * 10;
        }
    }

    /// @dev See {ILongStrategy-ltvThreshold}.
    function ltvThreshold() external virtual override view returns(uint256) {
        return _ltvThreshold();
    }

    /// @dev Update loan observer or collateral manager with updated loan information, return externally held collateral for loan if using collateral manager
    /// @param _loan - loan being observed by loan observer or collateral manager
    /// @param tokenId - identifier of liquidity loan that will be observed
    /// @return externalCollateral - collateral held in the collateral manager for liquidity loan `_loan`
    function onLoanUpdate(LibStorage.Loan storage _loan, uint256 tokenId) internal virtual returns(uint256 externalCollateral) {
        uint256 refType = _loan.refType;
        address refAddr = _loan.refAddr;
        uint256 collateral = 0;
        if(refAddr != address(0) && refType > 1) {
            collateral = ILoanObserver(refAddr).onLoanUpdate(s.cfmm, s.protocolId, tokenId,
                abi.encode(ILoanObserver.LoanObserved({ id: _loan.id, rateIndex: _loan.rateIndex, initLiquidity: _loan.initLiquidity,
                liquidity: _loan.liquidity, lpTokens: _loan.lpTokens, tokensHeld: _loan.tokensHeld, px: _loan.px})));
        }
        externalCollateral = refType == 3 ? collateral : 0;
    }

    /// @dev Get `loan` from `tokenId` if it exists
    /// @param tokenId - identifier of liquidity loan whose collateral will be traded
    /// @return _loan - existing loan (id > 0)
    function _getExistingLoan(uint256 tokenId) internal virtual view returns(LibStorage.Loan storage _loan) {
        _loan = s.loans[tokenId]; // Get loan
        if(_loan.id == 0) revert LoanDoesNotExist();
    }

    /// @dev Get `loan` from `tokenId` and authenticate
    /// @param tokenId - liquidity loan whose collateral will be traded
    /// @return _loan - existing loan created by caller
    function _getLoan(uint256 tokenId) internal virtual view returns(LibStorage.Loan storage _loan) {
        _loan = _getExistingLoan(tokenId);

        // Revert if msg.sender is not the creator of this loan
        if(tokenId != uint256(keccak256(abi.encode(msg.sender, address(this), _loan.id)))) revert Forbidden();
    }

    /// @dev Check if loan is undercollateralized
    /// @param collateral - liquidity invariant collateral
    /// @param liquidity - liquidity invariant debt
    function checkMargin(uint256 collateral, uint256 liquidity) internal virtual view;

    /// @dev Check if loan is over collateralized
    /// @param collateral - liquidity invariant collateral
    /// @param liquidity - liquidity invariant debt
    /// @param limit - loan to value ratio limit in hundredths of a percent (e.g. 8000 => 80%)
    /// @return bool - true if loan is over collateralized, false otherwise
    function hasMargin(uint256 collateral, uint256 liquidity, uint256 limit) internal virtual pure returns(bool) {
        return collateral * limit / 1e4 >= liquidity;
    }

    /// @dev Send tokens `amounts` from `loan` collateral to receiver (`to`)
    /// @param _loan - loan whose collateral we are sending to recipient
    /// @param to - recipient of token `amounts`
    /// @param amounts - quantities of loan's collateral tokens being sent to recipient
    function sendTokens(LibStorage.Loan storage _loan, address to, uint128[] memory amounts) internal virtual {
        address[] memory tokens = s.tokens;
        uint128[] memory balance = s.TOKEN_BALANCE;
        uint128[] memory tokensHeld = _loan.tokensHeld;
        for (uint256 i; i < tokens.length;) {
            if(amounts[i] > 0) {
                sendToken(tokens[i], to, amounts[i], balance[i], tokensHeld[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Repay loan's liquidity debt
    /// @param _loan - loan whose debt we're repaying
    /// @param amounts - reserve token amounts used to repay liquidity debt
    /// @return lpTokens - CFMM LP tokens received for liquidity repayment
    function repayTokens(LibStorage.Loan storage _loan, uint256[] memory amounts) internal virtual returns(uint256) {
        beforeRepay(_loan, amounts); // Perform necessary transactions before depositing to CFMM
        return depositToCFMM(s.cfmm, address(this), amounts); // Reserve token amounts sent to CFMM
    }

    /// @dev Update GammaPool's state variables (interest rate index) and loan's liquidity debt
    /// @param _loan - loan whose debt is being updated
    /// @return liquidity - new liquidity debt of loan including interest
    function updateLoan(LibStorage.Loan storage _loan) internal virtual returns(uint256) {
        (uint256 accFeeIndex,,) = updateIndex();
        return updateLoanLiquidity(_loan, accFeeIndex);
    }

    /// @dev Update loan's liquidity debt
    /// @param _loan - loan whose debt is being updated
    /// @param accFeeIndex - GammaPool's interest rate index
    /// @return liquidity - new liquidity debt of loan including interest
    function updateLoanLiquidity(LibStorage.Loan storage _loan, uint256 accFeeIndex) internal virtual returns(uint256 liquidity) {
        uint256 rateIndex = _loan.rateIndex;
        liquidity = rateIndex == 0 ? 0 : (_loan.liquidity * accFeeIndex) / rateIndex;
        _loan.liquidity = uint128(liquidity);
        _loan.rateIndex = uint80(accFeeIndex);
    }

    /// @dev Send collateral amount from loan out of GammaPool
    /// @param token - address of ERC20 token being transferred
    /// @param to - receiver of `token` amount
    /// @param amount - amount of `token` being transferred
    /// @param balance - amount of `token` in GammaPool
    /// @param collateral - amount of `token` collateral in loan
    function sendToken(address token, address to, uint256 amount, uint256 balance, uint256 collateral) internal {
        if(amount > collateral) revert NotEnoughCollateral(); // Check enough collateral in loan
        if(amount > balance) revert NotEnoughBalance(); // Check enough in pool's accounted balance
        GammaSwapLibrary.safeTransfer(token, to, amount); // Send token amount
    }

    /// @dev Update collateral amounts in loan (increased/decreased)
    /// @param _loan - address of ERC20 token being transferred
    /// @return tokensHeld - current CFMM LP token balance in GammaPool
    /// @return tokenChange - change in token amounts
    function updateCollateral(LibStorage.Loan storage _loan) internal returns(uint128[] memory tokensHeld, int256[] memory tokenChange) {
        address[] memory tokens = s.tokens; // GammaPool collateral tokens (saves gas)
        uint128[] memory tokenBalance = s.TOKEN_BALANCE; // Tracked collateral token balances in GammaPool (saves gas)
        tokenChange = new int256[](tokens.length);
        tokensHeld = _loan.tokensHeld; // Loan's collateral token amounts (saves gas)
        for (uint256 i; i < tokens.length;) {
            // Get i token's balance
            uint128 balanceChange;
            uint128 oldTokenBalance = tokenBalance[i];
            uint128 newTokenBalance = uint128(GammaSwapLibrary.balanceOf(tokens[i], address(this)));
            tokenBalance[i] = newTokenBalance;
            if(newTokenBalance > oldTokenBalance) { // If balance increased
                unchecked {
                    balanceChange = newTokenBalance - oldTokenBalance;
                }
                tokensHeld[i] += balanceChange;
                tokenChange[i] = int256(uint256(balanceChange));
            } else if(newTokenBalance < oldTokenBalance) { // If balance decreased
                unchecked {
                    balanceChange = oldTokenBalance - newTokenBalance;
                }
                if(balanceChange > oldTokenBalance) revert NotEnoughBalance(); // Withdrew more than expected tracked balance, must synchronize
                if(balanceChange > tokensHeld[i]) revert NotEnoughCollateral(); // Withdrew more than available collateral
                unchecked {
                    tokensHeld[i] -= balanceChange; // Update loan collateral
                }
                tokenChange[i] = -int256(uint256(balanceChange));
            }
            unchecked {
                ++i;
            }
        }
        _loan.tokensHeld = tokensHeld; // Update storage
        s.TOKEN_BALANCE = tokenBalance; // Update storage
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "./BaseLongStrategy.sol";

/// @title Base Rebalance Strategy abstract contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Common internal functions used by all strategy implementations that need rebalance loan collateral
/// @dev This contract inherits from BaseLongStrategy and should be inherited by strategies that need to rebalance collateral
abstract contract BaseRebalanceStrategy is BaseLongStrategy {

    /// @dev Calculate quantities to trade to rebalance collateral to desired `ratio`
    /// @param deltas - amount of collateral to trade to achieve desired final collateral amount
    /// @param tokensHeld - loan collateral to rebalance
    /// @param reserves - reserve token quantities in CFMM
    /// @return collateral - collateral amount
    function _calcCollateralPostTrade(int256[] memory deltas, uint128[] memory tokensHeld, uint128[] memory reserves) internal virtual view returns(uint256 collateral);

    /// @dev Calculate quantities to trade to rebalance collateral to desired `ratio`
    /// @param tokensHeld - loan collateral to rebalance
    /// @param reserves - reserve token quantities in CFMM
    /// @return deltas - amount of collateral to trade to achieve desired `ratio`
    function _calcDeltasForMaxLP(uint128[] memory tokensHeld, uint128[] memory reserves) internal virtual view returns(int256[] memory deltas);

    /// @dev Calculate quantities to trade to rebalance collateral to desired `ratio`
    /// @param tokensHeld - loan collateral to rebalance
    /// @param reserves - reserve token quantities in CFMM
    /// @param ratio - desired ratio of collateral
    /// @return deltas - amount of collateral to trade to achieve desired `ratio`
    function _calcDeltasForRatio(uint128[] memory tokensHeld, uint128[] memory reserves, uint256[] calldata ratio) internal virtual view returns(int256[] memory deltas);

    /// @dev Calculate quantities to trade to be able to close the `liquidity` amount
    /// @param tokensHeld - tokens held as collateral for liquidity to pay
    /// @param reserves - reserve token quantities in CFMM
    /// @param liquidity - amount of liquidity to pay
    /// @param collateralId - index of tokensHeld array to rebalance to (e.g. the collateral of the chosen index will be completely used up in repayment)
    /// @return deltas - amounts of collateral to trade to be able to repay `liquidity`
    function _calcDeltasToClose(uint128[] memory tokensHeld, uint128[] memory reserves, uint256 liquidity, uint256 collateralId) internal virtual view returns(int256[] memory deltas);

    /// @dev Calculate quantities to trade to be able to close the `liquidity` amount
    /// @param tokensHeld - tokens held as collateral for liquidity to pay
    /// @param reserves - reserve token quantities in CFMM
    /// @param liquidity - amount of liquidity to pay
    /// @param ratio - desired ratio of collateral
    /// @return deltas - amounts of collateral to trade to be able to repay `liquidity`
    function _calcDeltasToCloseSetRatio(uint128[] memory tokensHeld, uint128[] memory reserves, uint256 liquidity, uint256[] memory ratio) internal virtual view returns(int256[] memory deltas);

    /// @dev Calculate quantities to trade to rebalance collateral so that after withdrawing `amounts` we achieve desired `ratio`
    /// @param amounts - amounts that will be withdrawn from collateral
    /// @param tokensHeld - loan collateral to rebalance
    /// @param reserves - reserve token quantities in CFMM
    /// @param ratio - desired ratio of collateral after withdrawing `amounts`
    /// @return deltas - amount of collateral to trade to achieve desired `ratio`
    function _calcDeltasForWithdrawal(uint128[] memory amounts, uint128[] memory tokensHeld, uint128[] memory reserves, uint256[] calldata ratio) internal virtual view returns(int256[] memory deltas);

    /// @dev Check if loan is undercollateralized
    /// @param collateral - liquidity invariant collateral
    /// @param liquidity - liquidity invariant debt
    function checkMargin(uint256 collateral, uint256 liquidity) internal override virtual view {
        if(!hasMargin(collateral, liquidity, _ltvThreshold())) revert Margin(); // revert if collateral below ltvThreshold
    }

    /// @dev Check if ratio parameter is valid
    /// @param ratio - ratio parameter to rebalance collateral
    /// @return isValid - true if ratio parameter is valid, false otherwise
    function isRatioValid(uint256[] memory ratio) internal virtual view returns(bool) {
        uint256 len = s.tokens.length;
        if(ratio.length != len) {
            return false;
        }
        for(uint256 i = 0; i < len;) {
            if(ratio[i] < 1000) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

    /// @dev Check if deltas parameter is valid
    /// @param deltas - deltas parameter to rebalance collateral
    /// @return isValid - true if ratio parameter is valid, false otherwise
    function isDeltasValid(int256[] memory deltas) internal virtual view returns(bool) {
        uint256 len = s.tokens.length;
        if(deltas.length != len) {
            return false;
        }
        uint256 nonZeroCount = 0;
        for(uint256 i = 0; i < len;) {
            if(deltas[i] != 0) {
                ++nonZeroCount;
            }
            unchecked {
                ++i;
            }
        }
        return nonZeroCount == 1;
    }

    /// @dev Rebalance loan collateral through a swap with the CFMM
    /// @param _loan - loan whose collateral will be rebalanced
    /// @param deltas - collateral amounts being bought or sold (>0 buy, <0 sell), index matches tokensHeld[] index. Only n-1 tokens can be traded
    /// @return tokensHeld - loan collateral after rebalancing
    /// @return tokenChange - change in token amounts
    function rebalanceCollateral(LibStorage.Loan storage _loan, int256[] memory deltas, uint128[] memory reserves) internal virtual returns(uint128[] memory tokensHeld, int256[] memory tokenChange) {
        // Calculate amounts to swap from deltas and available loan collateral
        (uint256[] memory outAmts, uint256[] memory inAmts) = beforeSwapTokens(_loan, deltas, reserves);

        // Swap tokens
        swapTokens(_loan, outAmts, inAmts);

        // Update loan collateral tokens after swap
        (tokensHeld,tokenChange) = updateCollateral(_loan);
    }

    /// @dev Withdraw loan collateral
    /// @param _loan - loan whose collateral will bee withdrawn
    /// @param amounts - amounts of collateral to withdraw
    /// @param to - address that will receive collateral withdrawn
    /// @return tokensHeld - remaining loan collateral after withdrawal
    function withdrawCollateral(LibStorage.Loan storage _loan, uint128[] memory amounts, address to) internal virtual returns(uint128[] memory tokensHeld) {
        if(amounts.length != _loan.tokensHeld.length) revert InvalidAmountsLength();

        // Withdraw collateral tokens from loan
        sendTokens(_loan, to, amounts);

        // Update loan collateral token amounts after withdrawal
        (tokensHeld,) = updateCollateral(_loan);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "../../interfaces/IGammaPoolFactory.sol";
import "../../storage/AppStorage.sol";
import "../../libraries/GammaSwapLibrary.sol";
import "../../libraries/GSMath.sol";
import "../../rates/AbstractRateModel.sol";

/// @title Base Strategy abstract contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Common functions used by all strategy implementations
/// @dev Root Strategy contract. Only place where AppStorage and AbstractRateModel should be inherited
abstract contract BaseStrategy is AppStorage, AbstractRateModel {
    error ZeroAmount();
    error ZeroAddress();
    error ExcessiveBurn();
    error NotEnoughLPDeposit();
    error NotEnoughBalance();
    error NotEnoughCollateral();
    error MaxUtilizationRate();

    /// @dev Emitted when transferring GS LP token from one address (`from`) to another (`to`)
    /// @param from - address sending `amount`
    /// @param to - address receiving `to`
    /// @param amount - amount of GS LP tokens transferred
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Update token balances in CFMM
    /// @param cfmm - address of GammaPool's CFMM
    function syncCFMM(address cfmm) internal virtual;

    /// @dev Get reserves token quantities from CFMM
    /// @param cfmm - address of GammaPool's CFMM
    /// @return reserves - amounts that will be deposited in CFMM
    function getReserves(address cfmm) internal virtual view returns(uint128[] memory);

    /// @dev Get LP reserves token quantities from CFMM
    /// @param cfmm - address of GammaPool's CFMM
    /// @param isLatest - if true get latest reserves information
    /// @return reserves - amounts that will be deposited in CFMM
    function getLPReserves(address cfmm, bool isLatest) internal virtual view returns(uint128[] memory);

    /// @dev Calculates liquidity invariant from amounts quantities
    /// @param cfmm - address sending `amount`
    /// @param amounts - amount of GS LP tokens transferred
    /// @return invariant - liquidity invariant from CFMM
    function calcInvariant(address cfmm, uint128[] memory amounts) internal virtual view returns(uint256);

    /// @dev Deposits amounts of reserve tokens to CFMM to get CFMM LP tokens and send them to recipient (`to`)
    /// @param cfmm - address of CFMM
    /// @param to - receiver of CFMM LP tokens that will be minted after reserves deposit
    /// @param amounts - amount of reserve tokens deposited in CFMM
    /// @return lpTokens - LP tokens issued by CFMM for liquidity deposit
    function depositToCFMM(address cfmm, address to, uint256[] memory amounts) internal virtual returns(uint256 lpTokens);

    /// @dev Deposits amounts of reserve tokens to CFMM to get CFMM LP tokens and send them to recipient (`to`)
    /// @param cfmm - address of CFMM
    /// @param to - receiver of reserve tokens withdrawn from CFMM
    /// @param lpTokens - CFMM LP token amount redeemed from CFMM to withdraw reserve tokens
    /// @return amounts - amounts of reserve tokens withdrawn from CFMM
    function withdrawFromCFMM(address cfmm, address to, uint256 lpTokens) internal virtual returns(uint256[] memory amounts);

    /// @return maxTotalApy - maximum combined APY of CFMM fees and GammaPool's interest rate
    function maxTotalApy() internal virtual view returns(uint256);

    /// @return blocksPerYear - blocks created per year by network
    function blocksPerYear() internal virtual view returns(uint256);

    /// @dev See {AbstractRateModel-_rateParamsStore}
    function _rateParamsStore() internal override virtual view returns(address) {
        return s.factory;
    }

    /// @dev Update CFMM_RESERVES with reserve quantities in CFMM
    /// @param cfmm - address of CFMM
    function updateReserves(address cfmm) internal virtual {
        syncCFMM(cfmm);
        s.CFMM_RESERVES = getReserves(cfmm);
    }

    /// @dev Calculate fees accrued from fees in CFMM, and if leveraged, cap the leveraged yield at max yield leverage
    /// @param borrowedInvariant - liquidity invariant borrowed from CFMM
    /// @param lastCFMMInvariant - current liquidity invariant in CFMM
    /// @param lastCFMMTotalSupply - current CFMM LP token supply
    /// @param prevCFMMInvariant - liquidity invariant in CFMM in previous GammaPool update
    /// @param prevCFMMTotalSupply - CFMM LP token supply in previous GammaPool update
    /// @param maxCFMMFeeLeverage - max leverage of CFMM yield with 3 decimals. E.g. 5000 = 5
    /// @return cfmmFeeIndex - index tracking accrued fees from CFMM since last GammaPool update
    ///
    /// CFMM Fee Index = 1 + CFMM Yield = (cfmmInvariant1 / cfmmInvariant0) * (cfmmTotalSupply0 / cfmmTotalSupply1)
    ///
    /// Leverage Multiplier = (cfmmInvariant0 + borrowedInvariant) / cfmmInvariant0
    ///
    /// Deleveraged CFMM Yield = CFMM Yield / Leverage Multiplier = CFMM Yield * prevCFMMInvariant / (prevCFMMInvariant + borrowedInvariant)
    ///
    /// Releveraged CFMM Yield = Deleveraged CFMM Yield * Max CFMM Yield Leverage = Deleveraged CFMM Yield * maxCFMMFeeLeverage / 1000
    ///
    /// Releveraged CFMM Fee Index = 1 + Releveraged CFMM Yield
    function calcCFMMFeeIndex(uint256 borrowedInvariant, uint256 lastCFMMInvariant, uint256 lastCFMMTotalSupply, uint256 prevCFMMInvariant, uint256 prevCFMMTotalSupply, uint256 maxCFMMFeeLeverage) internal virtual view returns(uint256) {
        if(lastCFMMInvariant > 0 && lastCFMMTotalSupply > 0 && prevCFMMInvariant > 0 && prevCFMMTotalSupply > 0) {
            uint256 cfmmFeeIndex = lastCFMMInvariant * prevCFMMTotalSupply * 1e18 / (prevCFMMInvariant * lastCFMMTotalSupply);
            if(cfmmFeeIndex > 1e18 && borrowedInvariant > maxCFMMFeeLeverage * prevCFMMInvariant / 1000) { // exceeds max cfmm yield leverage
                unchecked {
                    cfmmFeeIndex = cfmmFeeIndex - 1e18;
                }
                cfmmFeeIndex = 1e18 + cfmmFeeIndex * prevCFMMInvariant * maxCFMMFeeLeverage / ((prevCFMMInvariant + borrowedInvariant) * 1000); // cap leverage
            }
            return cfmmFeeIndex;
        }
        return 1e18; // first update
    }

    /// @dev Add spread to lastCFMMFeeIndex based on borrowRate. If such logic is defined
    /// @notice borrowRate depends on utilization rate and BaseStrategy inherits AbstractRateModel
    /// @notice Therefore, utilization rate information is included in borrow rate to calculate spread
    /// @param lastCFMMFeeIndex - percentage of fees accrued in CFMM since last update to GammaPool
    /// @param spread - spread to add to cfmmFeeIndex
    /// @return cfmmFeeIndex - cfmmFeeIndex + spread
    function addSpread(uint256 lastCFMMFeeIndex, uint256 spread) internal virtual view returns(uint256) {
        if(lastCFMMFeeIndex > 1e18 && spread > 1e18) {
            unchecked {
                lastCFMMFeeIndex = lastCFMMFeeIndex - 1e18;
            }
            return lastCFMMFeeIndex * spread / 1e18 + 1e18;
        }
        return lastCFMMFeeIndex;
    }

    /// @dev Calculate total interest rate charged by GammaPool since last update
    /// @param lastCFMMFeeIndex - percentage of fees accrued in CFMM since last update to GammaPool
    /// @param borrowRate - annual borrow rate calculated from utilization rate of GammaPool
    /// @param blockDiff - change in blcoks since last update
    /// @param spread - spread fee to add to CFMM Fee Index
    /// @return feeIndex - (1 + total fee yield) since last update
    function calcFeeIndex(uint256 lastCFMMFeeIndex, uint256 borrowRate, uint256 blockDiff, uint256 spread) internal virtual view returns(uint256) {
        uint256 _blocksPerYear = blocksPerYear(); // Expected network blocks per year
        uint256 adjBorrowRate = 1e18 + blockDiff * borrowRate / _blocksPerYear; // De-annualized borrow rate
        uint256 _maxTotalApy = 1e18 + (blockDiff * maxTotalApy()) / _blocksPerYear; // De-annualized APY cap

        // Minimum of max de-annualized Max APY or max of CFMM fee yield + spread or de-annualized borrow yield
        return GSMath.min(_maxTotalApy, GSMath.max(addSpread(lastCFMMFeeIndex, spread), adjBorrowRate));
    }

    /// @dev Calculate total interest rate charged by GammaPool since last update
    /// @param borrowedInvariant - liquidity invariant borrowed in the GammaPool
    /// @param maxCFMMFeeLeverage - max leverage of CFMM yield
    /// @return lastCFMMFeeIndex - (1 + cfmm fee yield) since last update
    /// @return lastCFMMInvariant - current liquidity invariant in CFMM
    /// @return lastCFMMTotalSupply - current CFMM LP token supply
    function updateCFMMIndex(uint256 borrowedInvariant, uint256 maxCFMMFeeLeverage) internal virtual returns(uint256 lastCFMMFeeIndex, uint256 lastCFMMInvariant, uint256 lastCFMMTotalSupply) {
        address cfmm = s.cfmm; // Saves gas
        updateReserves(cfmm); // Update CFMM_RESERVES with reserves in CFMM
        lastCFMMInvariant = calcInvariant(cfmm, getLPReserves(cfmm,false)); // Calculate current total invariant in CFMM
        lastCFMMTotalSupply = GammaSwapLibrary.totalSupply(cfmm); // Get current total CFMM LP token supply

        // Get CFMM fee yield growth since last update by checking current invariant vs previous invariant discounting with change in total supply
        lastCFMMFeeIndex = calcCFMMFeeIndex(borrowedInvariant, lastCFMMInvariant, lastCFMMTotalSupply, s.lastCFMMInvariant, s.lastCFMMTotalSupply, maxCFMMFeeLeverage);

        // Update storage
        s.lastCFMMInvariant = uint128(lastCFMMInvariant);
        s.lastCFMMTotalSupply = lastCFMMTotalSupply;
    }

    /// @dev Accrue interest to borrowed invariant amount
    /// @param borrowedInvariant - liquidity invariant borrowed in the GammaPool
    /// @param lastFeeIndex - interest accrued to loans in GammaPool
    /// @return newBorrowedInvariant - borrowed invariant with accrued interest
    function accrueBorrowedInvariant(uint256 borrowedInvariant, uint256 lastFeeIndex) internal virtual pure returns(uint256) {
        return  borrowedInvariant * lastFeeIndex / 1e18;
    }

    /// @notice Convert CFMM LP tokens into liquidity invariant units.
    /// @dev In case of CFMM where convertInvariantToLP calculation is different from convertLPToInvariant
    /// @param liquidityInvariant - liquidity invariant borrowed in the GammaPool
    /// @param lastCFMMTotalSupply - total supply of LP tokens issued by CFMM
    /// @param lastCFMMInvariant - liquidity invariant in CFMM
    /// @return lpTokens - liquidity invariant in terms of LP tokens
    function convertInvariantToLP(uint256 liquidityInvariant, uint256 lastCFMMTotalSupply, uint256 lastCFMMInvariant) internal virtual pure returns(uint256) {
        return lastCFMMInvariant == 0 ? 0 : (liquidityInvariant * lastCFMMTotalSupply) / lastCFMMInvariant;
    }

    /// @notice Convert CFMM LP tokens into liquidity invariant units.
    /// @dev In case of CFMM where convertLPToInvariant calculation is different from convertInvariantToLP
    /// @param lpTokens - liquidity invariant borrowed in the GammaPool
    /// @param lastCFMMInvariant - liquidity invariant in CFMM
    /// @param lastCFMMTotalSupply - total supply of LP tokens issued by CFMM
    /// @return liquidityInvariant - liquidity invariant lpTokens represents
    function convertLPToInvariant(uint256 lpTokens, uint256 lastCFMMInvariant, uint256 lastCFMMTotalSupply) internal virtual pure returns(uint256) {
        return convertLPToInvariantRoundUp(lpTokens, lastCFMMInvariant, lastCFMMTotalSupply, false);
    }

    /// @notice Convert CFMM LP tokens into liquidity invariant units, with option to round up
    /// @dev In case of CFMM where convertLPToInvariant calculation is different from convertInvariantToLP
    /// @param lpTokens - liquidity invariant borrowed in the GammaPool
    /// @param lastCFMMInvariant - liquidity invariant in CFMM
    /// @param lastCFMMTotalSupply - total supply of LP tokens issued by CFMM
    /// @param roundUp - if true, round invariant up
    /// @return liquidityInvariant - liquidity invariant lpTokens represents
    function convertLPToInvariantRoundUp(uint256 lpTokens, uint256 lastCFMMInvariant, uint256 lastCFMMTotalSupply, bool roundUp) internal virtual pure returns(uint256) {
        return lastCFMMTotalSupply == 0 ? 0 : ((lpTokens * lastCFMMInvariant) * 10 / lastCFMMTotalSupply + (roundUp ? 9 : 0)) / 10;
    }

    /// @dev Update pool invariant, LP tokens borrowed plus interest, interest rate index, and last block update
    /// @param lastFeeIndex - interest accrued to loans in GammaPool
    /// @param borrowedInvariant - liquidity invariant borrowed in the GammaPool
    /// @param lastCFMMInvariant - liquidity invariant in CFMM
    /// @param lastCFMMTotalSupply - total supply of LP tokens issued by CFMM
    /// @return accFeeIndex - liquidity invariant lpTokenBalance represents
    /// @return newBorrowedInvariant - borrowed liquidity invariant after interest accrual
    function updateStore(uint256 lastFeeIndex, uint256 borrowedInvariant, uint256 lastCFMMInvariant, uint256 lastCFMMTotalSupply) internal virtual returns(uint256 accFeeIndex, uint256 newBorrowedInvariant) {
        // Accrue interest to borrowed liquidity
        newBorrowedInvariant = accrueBorrowedInvariant(borrowedInvariant, lastFeeIndex);
        s.BORROWED_INVARIANT = uint128(newBorrowedInvariant);

        // Convert borrowed liquidity to corresponding CFMM LP tokens using current conversion rate
        s.LP_TOKEN_BORROWED_PLUS_INTEREST = convertInvariantToLP(newBorrowedInvariant, lastCFMMTotalSupply, lastCFMMInvariant);
        uint256 lpInvariant = convertLPToInvariant(s.LP_TOKEN_BALANCE, lastCFMMInvariant, lastCFMMTotalSupply);
        s.LP_INVARIANT = uint128(lpInvariant);

        // Update GammaPool's interest rate index and update last block updated
        accFeeIndex = s.accFeeIndex * lastFeeIndex / 1e18;
        s.accFeeIndex = uint80(accFeeIndex);
        s.emaUtilRate = uint32(_calcUtilRateEma(calcUtilizationRate(lpInvariant, newBorrowedInvariant), s.emaUtilRate,
            GSMath.max(block.number - s.LAST_BLOCK_NUMBER, s.emaMultiplier)));
        s.LAST_BLOCK_NUMBER = uint40(block.number);
    }

    /// @dev Update pool invariant, LP tokens borrowed plus interest, interest rate index, and last block update
    /// @param utilizationRate - interest accrued to loans in GammaPool
    /// @param emaUtilRateLast - interest accrued to loans in GammaPool
    /// @param emaMultiplier - interest accrued to loans in GammaPool
    /// @return emaUtilRate - interest accrued to loans in GammaPool
    function _calcUtilRateEma(uint256 utilizationRate, uint256 emaUtilRateLast, uint256 emaMultiplier) internal virtual view returns(uint256) {
        utilizationRate = utilizationRate / 1e12; // convert to 6 decimals
        if(emaUtilRateLast == 0) {
            return utilizationRate;
        } else {
            uint256 prevWeight;
            unchecked {
                emaMultiplier = GSMath.min(100, emaMultiplier);
                prevWeight = 100 - emaMultiplier;
            }
            // EMA_1 = val * mult + EMA_0 * (1 - mult)
            return utilizationRate * emaMultiplier / 100 + emaUtilRateLast * prevWeight / 100;
        }
    }

    /// @dev Calculate intra block CFMM FeeIndex capped at ~18.44x
    /// @param curCFMMFeeIndex - current lastCFMMFeeIndex (accrued from last intra block update)
    /// @param lastCFMMFeeIndex - lastCFMMFeeIndex that will accrue to curCFMMFeeIndex
    /// @return updLastCFMMFeeIndex - updated lastCFMMFeeIndex
    function calcIntraBlockCFMMFeeIndex(uint256 curCFMMFeeIndex, uint256 lastCFMMFeeIndex) internal pure returns(uint256) {
        return GSMath.min(curCFMMFeeIndex * GSMath.max(lastCFMMFeeIndex, 1e18) / 1e18, type(uint64).max);
    }

    /// @dev Update GammaPool's state variables and pay protocol fee
    /// @return accFeeIndex - liquidity invariant lpTokenBalance represents
    /// @return lastFeeIndex - interest accrued to loans in GammaPool
    /// @return lastCFMMFeeIndex - interest accrued to loans in GammaPool
    function updateIndex() internal virtual returns(uint256 accFeeIndex, uint256 lastFeeIndex, uint256 lastCFMMFeeIndex) {
        uint256 borrowedInvariant = s.BORROWED_INVARIANT;
        uint256 lastCFMMInvariant;
        uint256 lastCFMMTotalSupply;
        uint256 borrowRate;
        uint256 utilizationRate;
        uint256 maxCFMMFeeLeverage;
        uint256 spread;
        (borrowRate, utilizationRate, maxCFMMFeeLeverage, spread) = calcBorrowRate(s.LP_INVARIANT, borrowedInvariant, s.factory, address(this));
        (lastCFMMFeeIndex, lastCFMMInvariant, lastCFMMTotalSupply) = updateCFMMIndex(borrowedInvariant, maxCFMMFeeLeverage);
        uint256 blockDiff = block.number - s.LAST_BLOCK_NUMBER; // Time passed in blocks
        if(blockDiff > 0) {
            lastCFMMFeeIndex = uint256(s.lastCFMMFeeIndex) * lastCFMMFeeIndex / 1e18;
            s.lastCFMMFeeIndex = 1e18;
            lastFeeIndex = calcFeeIndex(lastCFMMFeeIndex, borrowRate, blockDiff, spread);
            (accFeeIndex, borrowedInvariant) = updateStore(lastFeeIndex, borrowedInvariant, lastCFMMInvariant, lastCFMMTotalSupply);
            if(borrowedInvariant > 0) { // Only pay protocol fee if there are loans
                mintToDevs(lastFeeIndex, lastCFMMFeeIndex, utilizationRate);
            }
        } else {
            s.lastCFMMFeeIndex = uint64(calcIntraBlockCFMMFeeIndex(s.lastCFMMFeeIndex, lastCFMMFeeIndex));
            lastFeeIndex = 1e18;
            accFeeIndex = s.accFeeIndex;
            s.LP_TOKEN_BORROWED_PLUS_INTEREST = convertInvariantToLP(borrowedInvariant, lastCFMMTotalSupply, lastCFMMInvariant);
            s.LP_INVARIANT = uint128(convertLPToInvariant(s.LP_TOKEN_BALANCE, lastCFMMInvariant, lastCFMMTotalSupply));
        }
    }

    /// @dev Calculate amount to dilute GS LP tokens as protocol revenue payment
    /// @param lastFeeIndex - interest accrued to loans in GammaPool
    /// @param lastCFMMIndex - liquidity invariant lpTokenBalance represents
    /// @param utilizationRate - utilization rate of the pool (borrowedInvariant/totalInvariant)
    /// @param protocolFee - fee to charge as protocol revenue from interest growth in GammaSwap
    /// @return pctToPrint - percent of total GS LP token shares to print as dilution to pay protocol revenue
    function _calcProtocolDilution(uint256 lastFeeIndex, uint256 lastCFMMIndex, uint256 utilizationRate, uint256 protocolFee) internal virtual view returns(uint256 pctToPrint) {
        if(lastFeeIndex <= lastCFMMIndex || protocolFee == 0) {
            return 0;
        }

        uint256 lastFeeIndexAdj;
        uint256 lastCFMMIndexWeighted = lastCFMMIndex * (1e18 > utilizationRate ? (1e18 - utilizationRate) : 0);
        unchecked {
            lastFeeIndexAdj = lastFeeIndex - (lastFeeIndex - lastCFMMIndex) * GSMath.min(protocolFee, 100000) / 100000; // _protocolFee is 10000 by default (10%)
        }
        uint256 numerator = (lastFeeIndex * utilizationRate + lastCFMMIndexWeighted) / 1e18;
        uint256 denominator = (lastFeeIndexAdj * utilizationRate + lastCFMMIndexWeighted)/ 1e18;
        pctToPrint = GSMath.max(numerator * 1e18 / denominator, 1e18) - 1e18;// Result always is percentage as 18 decimals number or zero
    }

    /// @dev Mint GS LP tokens as protocol fee payment
    /// @param lastFeeIndex - interest accrued to loans in GammaPool
    /// @param lastCFMMIndex - liquidity invariant lpTokenBalance represents
    /// @param utilizationRate - utilization rate of the pool (borrowedInvariant/totalInvariant)
    function mintToDevs(uint256 lastFeeIndex, uint256 lastCFMMIndex, uint256 utilizationRate) internal virtual {
        (address _to, uint256 _protocolFee,,) = IGammaPoolFactory(s.factory).getPoolFee(address(this));
        if(_to != address(0) && _protocolFee > 0) {
            uint256 devShares = s.totalSupply * _calcProtocolDilution(lastFeeIndex, lastCFMMIndex, utilizationRate, _protocolFee) / 1e18;
            if(devShares > 0) {
                _mint(_to, devShares); // protocol fee is paid as dilution
            }
        }
    }

    /// @dev Revert if lpTokens withdrawal causes utilization rate to go over 98%
    /// @param lpTokens - lpTokens expected to change utilization rate
    /// @param isLoan - true if lpTokens are being borrowed
    function checkExpectedUtilizationRate(uint256 lpTokens, bool isLoan) internal virtual {
        uint256 lpTokenInvariant = convertLPToInvariant(lpTokens, s.lastCFMMInvariant, s.lastCFMMTotalSupply);
        uint256 lpInvariant = s.LP_INVARIANT - lpTokenInvariant;
        uint256 borrowedInvariant = s.BORROWED_INVARIANT + (isLoan ? lpTokenInvariant : 0);
        if(calcUtilizationRate(lpInvariant, borrowedInvariant) > 98e16) {
            revert MaxUtilizationRate();
        }
    }

    /// @dev Mint `amount` of GS LP tokens to `account`
    /// @param account - recipient address
    /// @param amount - amount of GS LP tokens to mint
    function _mint(address account, uint256 amount) internal virtual {
        if(amount == 0) revert ZeroAmount();
        s.totalSupply += amount;
        s.balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /// @dev Burn `amount` of GS LP tokens from `account`
    /// @param account - address that owns GS LP tokens to burn
    /// @param amount - amount of GS LP tokens to burn
    function _burn(address account, uint256 amount) internal virtual {
        if(account == address(0)) revert ZeroAddress();

        uint256 accountBalance = s.balanceOf[account];
        if(amount > accountBalance) revert ExcessiveBurn();

        unchecked {
            s.balanceOf[account] = accountBalance - amount;
        }
        s.totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/strategies/lending/IBorrowStrategy.sol";
import "../base/BaseRebalanceStrategy.sol";
import "../base/BaseBorrowStrategy.sol";

/// @title Borrow Strategy abstract contract implementation of IBorrowStrategy
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice All external functions are locked to avoid reentrancy
/// @dev Defines external functions for concrete contract implementations to allow external accounts to borrow liquidity
/// @dev Inherits BaseRebalanceStrategy because BorrowStrategy needs to rebalance collateral to achieve a desires delta
abstract contract BorrowStrategy is IBorrowStrategy, BaseBorrowStrategy, BaseRebalanceStrategy {

    error ExcessiveBorrowing();

    /// @dev See {IBorrowStrategy-calcDynamicOriginationFee}.
    function calcDynamicOriginationFee(uint256 baseOrigFee, uint256 utilRate, uint256 lowUtilRate, uint256 minUtilRate1, uint256 minUtilRate2, uint256 feeDivisor) external virtual override view returns(uint256 origFee) {
        return _calcDynamicOriginationFee(baseOrigFee, utilRate, lowUtilRate, minUtilRate1, minUtilRate2, feeDivisor);
    }

    /// @dev Get the amounts that do not have enough collateral to withdraw from the loan's collateral
    /// @param amounts - collateral quantities requested to withdraw and therefore checked against existing collateral in the loan.
    /// @param tokensHeld - collateral quantities in loan
    /// @return hasUnfundedAmounts - if true, we don't have enough collateral to withdraw for at least on token of the CFMM
    /// @return unfundedAmounts - amount requested to withdraw for which there isn't enough collateral to withdraw
    /// @return _tokensHeld - amount requested to withdraw for which there isn't enough collateral to withdraw
    function getUnfundedAmounts(uint128[] memory amounts, uint128[] memory tokensHeld) internal virtual view returns(bool, uint128[] memory, uint128[] memory){
        uint256 len = tokensHeld.length;
        if(amounts.length != len) revert InvalidAmountsLength();
        uint128[] memory unfundedAmounts = new uint128[](len);
        bool hasUnfundedAmounts = false;
        for(uint256 i = 0; i < len;) {
            if(amounts[i] > tokensHeld[i]) { // if amount requested is higher than existing collateral
                hasUnfundedAmounts = true; // we don't have enough collateral of at least one token to withdraw
                unfundedAmounts[i] = amounts[i]; // amount we are requesting to withdraw for which there isn't enough collateral
            } else {
                unchecked {
                    tokensHeld[i] -= amounts[i];
                }
            }
            unchecked {
                ++i;
            }
        }
        return(hasUnfundedAmounts, unfundedAmounts, tokensHeld);
    }

    /// @notice We do this because we may withdraw the collateral to the CFMM prior to requesting the reserves
    /// @dev Ask for reserve quantities from CFMM if address that will receive withdrawn quantities is CFMM
    /// @param to - address that will receive withdrawn collateral quantities
    /// @return reserves - CFMM reserve quantities
    function _getReserves(address to) internal virtual view returns(uint128[] memory) {
        if(to == s.cfmm) {
            return getReserves(to);
        }
        return s.CFMM_RESERVES;
    }

    /// @notice Assumes that collateral tokens were already deposited but not accounted for
    /// @dev See {IBorrowStrategy-_increaseCollateral}.
    function _increaseCollateral(uint256 tokenId, uint256[] calldata ratio) external virtual override lock returns(uint128[] memory tokensHeld) {
        // Get loan for tokenId, revert if not loan creator
        LibStorage.Loan storage _loan = _getLoan(tokenId);

        // Update loan collateral token amounts with tokens deposited in GammaPool
        (tokensHeld,) = updateCollateral(_loan);

        // Update liquidity debt to include accrued interest since last update
        uint256 loanLiquidity = updateLoan(_loan);

        if(isRatioValid(ratio)) {
            int256[] memory deltas = _calcDeltasForRatio(_loan.tokensHeld, s.CFMM_RESERVES, ratio);
            if(isDeltasValid(deltas)) {
                (tokensHeld,) = rebalanceCollateral(_loan, deltas, s.CFMM_RESERVES);
            }
            // Check that loan is not undercollateralized after swap
            checkMargin(calcInvariant(s.cfmm, tokensHeld) + onLoanUpdate(_loan, tokenId), loanLiquidity);
        } else {
            onLoanUpdate(_loan, tokenId);
        }
        // If not rebalanced, do not check for undercollateralization because adding collateral always improves loan health

        emit LoanUpdated(tokenId, tokensHeld, uint128(loanLiquidity), _loan.initLiquidity, _loan.lpTokens, _loan.rateIndex, TX_TYPE.INCREASE_COLLATERAL);

        emit PoolUpdated(s.LP_TOKEN_BALANCE, s.LP_TOKEN_BORROWED, s.LAST_BLOCK_NUMBER, s.accFeeIndex,
            s.LP_TOKEN_BORROWED_PLUS_INTEREST, s.LP_INVARIANT, s.BORROWED_INVARIANT, s.CFMM_RESERVES, TX_TYPE.INCREASE_COLLATERAL);

        return tokensHeld;
    }

    /// @dev See {IBorrowStrategy-_decreaseCollateral}.
    function _decreaseCollateral(uint256 tokenId, uint128[] memory amounts, address to, uint256[] calldata ratio) external virtual override lock returns(uint128[] memory tokensHeld) {
        // Get loan for tokenId, revert if not loan creator
        LibStorage.Loan storage _loan = _getLoan(tokenId);

        // Update liquidity debt with accrued interest since last update
        uint256 loanLiquidity = updateLoan(_loan);
        if(isRatioValid(ratio)) {
            tokensHeld = _loan.tokensHeld;
            bool hasUnfundedAmounts;
            uint128[] memory unfundedAmounts;
            (hasUnfundedAmounts, unfundedAmounts, tokensHeld) = getUnfundedAmounts(amounts, tokensHeld);

            if(!hasUnfundedAmounts) {
                // Withdraw collateral tokens from loan
                tokensHeld = withdrawCollateral(_loan, amounts, to);

                // rebalance to ratio
                uint128[] memory _reserves = _getReserves(to);
                int256[] memory deltas = _calcDeltasForRatio(tokensHeld, _reserves, ratio);
                if(isDeltasValid(deltas)) {
                    (tokensHeld,) = rebalanceCollateral(_loan, deltas, _reserves);
                }
            } else {
                // rebalance to match ratio after withdrawal
                int256[] memory deltas = _calcDeltasForWithdrawal(unfundedAmounts, tokensHeld, s.CFMM_RESERVES, ratio);
                if(isDeltasValid(deltas)) {
                    rebalanceCollateral(_loan, deltas, s.CFMM_RESERVES);
                }
                // Withdraw collateral tokens from loan
                tokensHeld = withdrawCollateral(_loan, amounts, to);
            }
        } else {
            tokensHeld = withdrawCollateral(_loan, amounts, to);
        }

        // Check that loan is not undercollateralized
        checkMargin(calcInvariant(s.cfmm, tokensHeld) + onLoanUpdate(_loan, tokenId), loanLiquidity);

        emit LoanUpdated(tokenId, tokensHeld, uint128(loanLiquidity), _loan.initLiquidity, _loan.lpTokens, _loan.rateIndex, TX_TYPE.DECREASE_COLLATERAL);

        emit PoolUpdated(s.LP_TOKEN_BALANCE, s.LP_TOKEN_BORROWED, s.LAST_BLOCK_NUMBER, s.accFeeIndex,
            s.LP_TOKEN_BORROWED_PLUS_INTEREST, s.LP_INVARIANT, s.BORROWED_INVARIANT, s.CFMM_RESERVES, TX_TYPE.DECREASE_COLLATERAL);

        return tokensHeld;
    }

    /// @dev See {IBorrowStrategy-_borrowLiquidity}.
    function _borrowLiquidity(uint256 tokenId, uint256 lpTokens, uint256[] calldata ratio) external virtual override lock returns(uint256 liquidityBorrowed, uint256[] memory amounts, uint128[] memory tokensHeld) {
        // Revert if borrowing all CFMM LP tokens in pool
        if(lpTokens >= s.LP_TOKEN_BALANCE) revert ExcessiveBorrowing();

        // Get loan for tokenId, revert if not loan creator
        LibStorage.Loan storage _loan = _getLoan(tokenId);

        // Update liquidity debt to include accrued interest since last update
        uint256 loanLiquidity = updateLoan(_loan);

        // Withdraw reserve tokens from CFMM that lpTokens represent
        amounts = withdrawFromCFMM(s.cfmm, address(this), lpTokens);

        // Add withdrawn tokens as part of loan collateral
        (tokensHeld,) = updateCollateral(_loan);

        // Add liquidity debt to total pool debt and start tracking loan
        (liquidityBorrowed, loanLiquidity) = openLoan(_loan, lpTokens);

        if(isRatioValid(ratio)) {
            //get current reserves without updating
            uint128[] memory _reserves = getReserves(s.cfmm);
            int256[] memory deltas = _calcDeltasForRatio(tokensHeld, _reserves, ratio);
            if(isDeltasValid(deltas)) {
                (tokensHeld,) = rebalanceCollateral(_loan, deltas, _reserves);
            }
        }

        // Check that loan is not undercollateralized
        checkMargin(calcInvariant(s.cfmm, tokensHeld) + onLoanUpdate(_loan, tokenId), loanLiquidity);

        emit LoanUpdated(tokenId, tokensHeld, uint128(loanLiquidity), _loan.initLiquidity, _loan.lpTokens, _loan.rateIndex, TX_TYPE.BORROW_LIQUIDITY);

        emit PoolUpdated(s.LP_TOKEN_BALANCE, s.LP_TOKEN_BORROWED, s.LAST_BLOCK_NUMBER, s.accFeeIndex,
            s.LP_TOKEN_BORROWED_PLUS_INTEREST, s.LP_INVARIANT, s.BORROWED_INVARIANT, s.CFMM_RESERVES, TX_TYPE.BORROW_LIQUIDITY);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/strategies/rebalance/IRebalanceStrategy.sol";
import "../base/BaseRebalanceStrategy.sol";

/// @title Rebalance Strategy abstract contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Calculates trade quantities necessary to trade in the CFMM to achieve a desired collateral ratio
/// @notice Rebalances collateral ratio of a loan to achieve a desired delta
/// @dev All external functions are locked to avoid reentrancy
/// @dev Defines external functions for concrete contract implementations to allow external accounts to rebalance collateral
/// @dev Inherits from BaseRebalanceStrategy all logic necessary to rebalance collateral by trading in the CFMM
abstract contract RebalanceStrategy is IRebalanceStrategy, BaseRebalanceStrategy {

    /// @dev See {ILongStrategy-calcDeltasForRatio}.
    function calcDeltasForRatio(uint128[] memory tokensHeld, uint128[] memory reserves, uint256[] calldata ratio) external virtual override view returns(int256[] memory deltas) {
        return _calcDeltasForRatio(tokensHeld, reserves, ratio);
    }

    /// @dev See {ILongStrategy-calcDeltasToClose}.
    function calcDeltasToClose(uint128[] memory tokensHeld, uint128[] memory reserves, uint256 liquidity, uint256 collateralId)
        external virtual override view returns(int256[] memory deltas) {
        return _calcDeltasToClose(tokensHeld, reserves, liquidity, collateralId);
    }

    /// @dev See {ILongStrategy-calcDeltasForWithdrawal}.
    function calcDeltasForWithdrawal(uint128[] memory amounts, uint128[] memory tokensHeld, uint128[] memory reserves, uint256[] calldata ratio) external virtual override view returns(int256[] memory deltas) {
        return _calcDeltasForWithdrawal(amounts, tokensHeld, reserves, ratio);
    }

    /// @dev See {ILongStrategy-_rebalanceCollateral}.
    function _rebalanceCollateral(uint256 tokenId, int256[] memory deltas, uint256[] calldata ratio) external virtual override lock returns(uint128[] memory tokensHeld) {
        // Get loan for tokenId, revert if not loan creator
        LibStorage.Loan storage _loan = _getLoan(tokenId);

        // Update liquidity debt to include accrued interest since last update
        uint256 loanLiquidity = updateLoan(_loan);

        tokensHeld = _loan.tokensHeld;
        if(isRatioValid(ratio)) {
            deltas = _calcDeltasForRatio(tokensHeld, s.CFMM_RESERVES, ratio);
        }

        if(isDeltasValid(deltas)) {
            (tokensHeld,) = rebalanceCollateral(_loan, deltas, s.CFMM_RESERVES);
        }

        // Check that loan is not undercollateralized after swap
        checkMargin(calcInvariant(s.cfmm, tokensHeld) + onLoanUpdate(_loan, tokenId), loanLiquidity);

        emit LoanUpdated(tokenId, tokensHeld, uint128(loanLiquidity), _loan.initLiquidity, _loan.lpTokens, _loan.rateIndex, TX_TYPE.REBALANCE_COLLATERAL);

        emit PoolUpdated(s.LP_TOKEN_BALANCE, s.LP_TOKEN_BORROWED, s.LAST_BLOCK_NUMBER, s.accFeeIndex,
            s.LP_TOKEN_BORROWED_PLUS_INTEREST, s.LP_INVARIANT, s.BORROWED_INVARIANT, s.CFMM_RESERVES, TX_TYPE.REBALANCE_COLLATERAL);
    }

    /// @dev See {ILongStrategy-_updatePool}
    function _updatePool(uint256 tokenId) external virtual override lock returns(uint256 loanLiquidityDebt, uint256 poolLiquidityDebt) {
        if(tokenId > 0) {
            // Get loan for tokenId, revert if loan does not exist
            LibStorage.Loan storage _loan = _getExistingLoan(tokenId);

            // Update pool and loan liquidity debt to include accrued interest since last update
            loanLiquidityDebt = updateLoan(_loan);

            onLoanUpdate(_loan, tokenId);

            emit LoanUpdated(tokenId, _loan.tokensHeld, uint128(loanLiquidityDebt), _loan.initLiquidity, _loan.lpTokens, _loan.rateIndex, TX_TYPE.UPDATE_POOL);
        } else {
            // Update pool liquidity debt to include accrued interest since last update
            updateIndex();
        }

        poolLiquidityDebt = s.BORROWED_INVARIANT;

        emit PoolUpdated(s.LP_TOKEN_BALANCE, s.LP_TOKEN_BORROWED, s.LAST_BLOCK_NUMBER, s.accFeeIndex,
            s.LP_TOKEN_BORROWED_PLUS_INTEREST, s.LP_INVARIANT, uint128(poolLiquidityDebt), s.CFMM_RESERVES, TX_TYPE.UPDATE_POOL);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Interface for Constant Product Market Maker contract implementations
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Interface to get reserve tokens, deposit liquidity, withdraw liquidity, and swap tokens
/// @dev Interface assumes an UniswapV2 interface. Function mint() is used to deposit and burn() to withdraw
interface ICPMM {
    /// @dev Get token0 address from CFMM
    function token0() external view returns(address);

    /// @dev Get token1 address from CFMM
    function token1() external view returns(address);

    /// @notice Read reserve token quantities in the AMM, and timestamp of last update
    /// @dev Reserve quantities come back as uint112 although we store them as uint128
    /// @return reserve0 - quantity of token0 held in AMM
    /// @return reserve1 - quantity of token1 held in AMM
    /// @return blockTimestampLast - timestamp of the last update block
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    /// @notice Deposit reserve tokens (liquidity) to get LP tokens, requires having sent reserve tokens before calling function
    /// @dev requires sending the reserve tokens in the correct ratio. An incorrect ratio will cause some loss of funds
    /// @param to - address that will receive LP tokens
    /// @return liquidity - LP tokens representing liquidity deposited
    function mint(address to) external returns (uint liquidity);

    /// @notice Withdraw reserve tokens (liquidity) by burning LP tokens, requires having sent LP tokens before calling function
    /// @dev Amounts of reserve tokens you receive match the ratio of reserve tokens in the AMM at the time you call this function
    /// @param to - address that will receive reserve tokens
    /// @return amount0 - quantity withdrawn of token0 LP token represents
    /// @return amount1 - quantity withdrawn of token1 LP token represents
    function burn(address to) external returns (uint amount0, uint amount1);

    /// @notice Exchange one token for another token, must send token amount to exchange first before calling this function
    /// @dev The user specifies which token amount to get. Therefore only one token amount parameter is greater than zero
    /// @param amount0Out - address that will receive reserve tokens
    /// @param amount1Out - address that will receive reserve tokens
    /// @param to - address that will receive output token quantity
    /// @param data - used for flash loan trades
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    /// @dev Synchronize token balances in CFMM with the amount of balances being tracked by the CFMM
    function sync() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @title Interface for contract that has fee information for transacting with AMM
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Used primarily with DeltaSwap
interface IFeeSource {
    /// @dev Get fee charged to GammaSwap from feeSource contract in basis points (e.g. 3 = 3 basis points)
    function gsFee() external view returns(uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Interface for CPMM Math library
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Interface to call math functions to perform calculations used in CPMM strategies
interface ICPMMMath {

    /// @param delta - quantity of token0 bought from CFMM to achieve max collateral
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantity of token0 in CFMM
    /// @param reserve1 - reserve quantity of token1 in CFMM
    /// @param fee1 - trading fee numerator
    /// @param fee2 - trading fee denominator
    /// @return collateral - max collateral liquidity value of tokensHeld after trade using deltas given reserves in CFMM
    function calcCollateralPostTrade(uint256 delta, uint256 tokensHeld0, uint256 tokensHeld1, uint256 reserve0,
        uint256 reserve1, uint256 fee1, uint256 fee2) external view returns(uint256 collateral);

    /// @dev Calculate quantities to trade to rebalance collateral (`tokensHeld`) to the desired `ratio`
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantity of token0 in CFMM
    /// @param reserve1 - reserve quantity of token1 in CFMM
    /// @param fee1 - trading fee numerator
    /// @param fee2 - trading fee denominator
    /// @param decimals0 - decimals of token0
    /// @return deltas - quadratic roots (quantities to trade). The first quadratic root (index 0) is the only feasible trade
    function calcDeltasForMaxLP(uint256 tokensHeld0, uint256 tokensHeld1, uint256 reserve0, uint256 reserve1,
        uint256 fee1, uint256 fee2, uint8 decimals0) external view returns(int256[] memory deltas);

    /// @dev Calculate quantities to trade to rebalance collateral (`tokensHeld`) to the desired `ratio`
    /// @param liquidity - liquidity debt that needs to be repaid after rebalancing loan's collateral quantities
    /// @param ratio0 - numerator (token0) of desired ratio we wish collateral (`tokensHeld`) to have
    /// @param ratio1 - denominator (token1) of desired ratio we wish collateral (`tokensHeld`) to have
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantity of token0 in CFMM
    /// @param reserve1 - reserve quantity of token1 in CFMM
    /// @param decimals0 - decimals of token0
    /// @return deltas - quadratic roots (quantities to trade). The first quadratic root (index 0) is the only feasible trade
    function calcDeltasToCloseSetRatio(uint256 liquidity, uint256 ratio0, uint256 ratio1, uint256 tokensHeld0, uint256 tokensHeld1,
        uint256 reserve0, uint256 reserve1, uint8 decimals0) external view returns(int256[] memory deltas);

    /// @dev how much collateral to trade to have enough to close a position
    /// @param liquidity - liquidity debt that needs to be repaid after rebalancing loan's collateral quantities
    /// @param lastCFMMInvariant - most up to date invariant in CFMM
    /// @param collateral - collateral invariant of loan to rebalance (not token quantities, but their geometric mean)
    /// @param reserve - reserve quantity of token to trade in CFMM
    /// @return delta - quantity of token to trade (> 0 means buy, < 0 means sell)
    function calcDeltasToClose(uint256 liquidity, uint256 lastCFMMInvariant, uint256 collateral, uint256 reserve)
        external pure returns(int256 delta);

    /// @dev Calculate quantities to trade to rebalance collateral (`tokensHeld`) to the desired `ratio`
    /// @param ratio0 - numerator (token0) of desired ratio we wish collateral (`tokensHeld`) to have
    /// @param ratio1 - denominator (token1) of desired ratio we wish collateral (`tokensHeld`) to have
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantity of token0 in CFMM
    /// @param reserve1 - reserve quantity of token1 in CFMM
    /// @param fee1 - trading fee numerator
    /// @param fee2 - trading fee denominator
    /// @return deltas - quadratic roots (quantities to trade). The first quadratic root (index 0) is the only feasible trade
    function calcDeltasForRatio(uint256 ratio0, uint256 ratio1, uint256 tokensHeld0, uint256 tokensHeld1,
        uint256 reserve0, uint256 reserve1, uint256 fee1, uint256 fee2) external view returns(int256[] memory deltas);

    /// @dev Calculate deltas to rebalance collateral for withdrawal while maintaining desired ratio
    /// @param amount - amount of token0 requesting to withdraw
    /// @param ratio0 - numerator of desired ratio to maintain after withdrawal (token0)
    /// @param ratio1 - denominator of desired ratio to maintain after withdrawal (token1)
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantities of token0 in CFMM
    /// @param reserve1 - reserve quantities of token1 in CFMM
    /// @param fee1 - trading fee numerator
    /// @param fee2 - trading fee denominator
    /// @return deltas - quantities of reserve tokens to rebalance after withdrawal. The second quadratic root (index 1) is the only feasible trade
    function calcDeltasForWithdrawal(uint256 amount, uint256 ratio0, uint256 ratio1, uint256 tokensHeld0, uint256 tokensHeld1,
        uint256 reserve0, uint256 reserve1, uint256 fee1, uint256 fee2) external view returns(int256[] memory deltas);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@gammaswap/v1-core/contracts/strategies/base/BaseLongStrategy.sol";
import "./CPMMBaseStrategy.sol";
import "../../../interfaces/external/IFeeSource.sol";

/// @title Base Long Strategy abstract contract for Constant Product Market Maker
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Common functions used by all concrete strategy implementations for CPMM that need access to loans
/// @dev This implementation was specifically designed to work with UniswapV2.
abstract contract CPMMBaseLongStrategy is BaseLongStrategy, CPMMBaseStrategy {

    error BadDelta();
    error ZeroReserves();
    error InvalidTradingFee();
    error InsufficientTokenRepayment();

    /// @return feeSource - source of tradingFee for tradingFee1
    address immutable public feeSource;

    /// @return tradingFee1 - numerator in tradingFee calculation (e.g amount * tradingFee1 / tradingFee2)
    uint24 immutable public tradingFee1;

    /// @return tradingFee2 - denominator in tradingFee calculation (e.g amount * tradingFee1 / tradingFee2)
    uint24 immutable public tradingFee2 ;

    /// @return Returns the minimum liquidity payment amount.
    uint256 constant public MIN_PAY = 1e3;

    /// @dev Initializes the contract by setting `MAX_TOTAL_APY`, `BLOCKS_PER_YEAR`, `tradingFee1`, `tradingFee2`,
    /// @dev `feeSource`, `baseRate`, `optimalUtilRate`, `slope1`, and `slope2`
    constructor(uint256 maxTotalApy_, uint256 blocksPerYear_, uint24 tradingFee1_, uint24 tradingFee2_, address _feeSource,
        uint64 baseRate_, uint64 optimalUtilRate_, uint64 slope1_, uint64 slope2_) CPMMBaseStrategy(maxTotalApy_,
        blocksPerYear_, baseRate_, optimalUtilRate_, slope1_, slope2_) {
        if(tradingFee1_ > tradingFee2_) revert InvalidTradingFee();
        tradingFee1 = tradingFee1_;
        tradingFee2 = tradingFee2_;
        feeSource = _feeSource;
    }

    /// @return Returns the minimum liquidity amount to pay.
    function minPay() internal virtual override view returns(uint256) {
        return MIN_PAY;
    }

    /// @dev See {BaseLongStrategy-calcTokensToRepay}.
    function calcTokensToRepay(uint128[] memory reserves, uint256 liquidity, uint128[] memory maxAmounts) internal virtual override view
        returns(uint256[] memory amounts) {

        amounts = new uint256[](2);
        uint256 lastCFMMInvariant = calcInvariant(address(0), reserves);

        uint256 lastCFMMTotalSupply = s.lastCFMMTotalSupply;
        uint256 expectedLPTokens = liquidity * lastCFMMTotalSupply / lastCFMMInvariant;

        amounts[0] = expectedLPTokens * reserves[0] / lastCFMMTotalSupply + 1;
        amounts[1] = expectedLPTokens * reserves[1] / lastCFMMTotalSupply + 1;

        if(maxAmounts.length == 2) {
            if(amounts[0] > maxAmounts[0]) {
                unchecked {
                    if(amounts[0] - maxAmounts[0] > 1000) revert InsufficientTokenRepayment();
                }
            }
            if(amounts[1] > maxAmounts[1]) {
                unchecked {
                    if(amounts[1] - maxAmounts[1] > 1000) revert InsufficientTokenRepayment();
                }
            }
            amounts[0] = GSMath.min(amounts[0], maxAmounts[0]);
            amounts[1] = GSMath.min(amounts[1], maxAmounts[1]);
        }
    }

    /// @dev See {BaseLongStrategy-beforeRepay}.
    function beforeRepay(LibStorage.Loan storage _loan, uint256[] memory _amounts) internal virtual override {
        address[] memory tokens = s.tokens;
        address cfmm = s.cfmm;
        if(_amounts[0] > 0) sendToken(tokens[0], cfmm, _amounts[0], s.TOKEN_BALANCE[0], _loan.tokensHeld[0]);
        if(_amounts[1] > 0) sendToken(tokens[1], cfmm, _amounts[1], s.TOKEN_BALANCE[1], _loan.tokensHeld[1]);
    }

    /// @dev See {BaseLongStrategy-swapTokens}.
    function swapTokens(LibStorage.Loan storage, uint256[] memory, uint256[] memory inAmts) internal virtual override {
        if(inAmts[0] == 0 && inAmts[1] == 0) return;

        ICPMM(s.cfmm).swap(inAmts[0],inAmts[1],address(this),new bytes(0)); // out amounts already sent in beforeSwapTokens
    }

    /// @dev See {BaseLongStrategy-beforeSwapTokens}.
    function beforeSwapTokens(LibStorage.Loan storage _loan, int256[] memory deltas, uint128[] memory reserves)
        internal virtual override returns(uint256[] memory outAmts, uint256[] memory inAmts) {

        outAmts = new uint256[](2);
        inAmts = new uint256[](2);

        if(deltas[0] == 0 && deltas[1] == 0) {
            return (outAmts, inAmts);
        }

        (inAmts[0], inAmts[1], outAmts[0], outAmts[1]) = calcInAndOutAmounts(_loan, reserves[0], reserves[1],
            deltas[0], deltas[1]);
    }

    /// @dev Calculate expected bought and sold amounts given reserves in CFMM
    /// @param _loan - liquidity loan whose collateral will be used to calculates swap amounts
    /// @param reserve0 - amount of token0 in CFMM
    /// @param reserve1 - amount of token1 in CFMM
    /// @param delta0 - desired amount of collateral token0 from loan to swap (> 0 buy, < 0 sell, 0 ignore)
    /// @param delta1 - desired amount of collateral token1 from loan to swap (> 0 buy, < 0 sell, 0 ignore)
    /// @return inAmt0 - expected amount of token0 to receive from CFMM (buy)
    /// @return inAmt1 - expected amount of token1 to receive from CFMM (buy)
    /// @return outAmt0 - expected amount of token0 to send to CFMM (sell)
    /// @return outAmt1 - expected amount of token1 to send to CFMM (sell)
    function calcInAndOutAmounts(LibStorage.Loan storage _loan, uint256 reserve0, uint256 reserve1, int256 delta0, int256 delta1)
        internal returns(uint256 inAmt0, uint256 inAmt1, uint256 outAmt0, uint256 outAmt1) {
        // can only have one non zero delta
        if(!((delta0 != 0 && delta1 == 0) || (delta0 == 0 && delta1 != 0))) revert BadDelta();

        // inAmt is what GS is getting, outAmt is what GS is sending
        if(delta0 > 0 || delta1 > 0) {
            inAmt0 = uint256(delta0); // buy exact token0 (what you'll ask)
            inAmt1 = uint256(delta1); // buy exact token1 (what you'll ask)
            if(inAmt0 > 0) {
                outAmt0 = 0;
                outAmt1 = calcAmtOut(inAmt0, reserve1, reserve0); // calc what you'll send
                uint256 _outAmt1 = calcActualOutAmt(s.tokens[1], s.cfmm, outAmt1, s.TOKEN_BALANCE[1], _loan.tokensHeld[1]);
                if(_outAmt1 != outAmt1) {
                    outAmt1 = _outAmt1;
                    inAmt0 = calcAmtIn(outAmt1, reserve1, reserve0); // calc what you'll ask
                }
            } else {
                outAmt0 = calcAmtOut(inAmt1, reserve0, reserve1); // calc what you'll send
                outAmt1 = 0;
                uint256 _outAmt0 = calcActualOutAmt(s.tokens[0], s.cfmm, outAmt0, s.TOKEN_BALANCE[0], _loan.tokensHeld[0]);
                if(_outAmt0 != outAmt0) {
                    outAmt0 = _outAmt0;
                    inAmt1 = calcAmtIn(outAmt0, reserve0, reserve1); // calc what you'll ask
                }
            }
        } else {
            outAmt0 = uint256(-delta0); // sell exact token0 (what you'll send)
            outAmt1 = uint256(-delta1); // sell exact token1 (what you'll send) (here we can send then calc how much to ask)
            if(outAmt0 > 0) {
                outAmt0 = calcActualOutAmt(s.tokens[0], s.cfmm, outAmt0, s.TOKEN_BALANCE[0], _loan.tokensHeld[0]);
                inAmt0 = 0;
                inAmt1 = calcAmtIn(outAmt0, reserve0, reserve1); // calc what you'll ask
            } else {
                outAmt1 = calcActualOutAmt(s.tokens[1], s.cfmm, outAmt1, s.TOKEN_BALANCE[1], _loan.tokensHeld[1]);
                inAmt0 = calcAmtIn(outAmt1, reserve1, reserve0); // calc what you'll ask
                inAmt1 = 0;
            }
        }
    }

    /// @dev Calculate actual amount received by recipient in case token has transfer fee
    /// @param token - ERC20 token whose amount we're checking
    /// @param to - recipient of token amount
    /// @param amount - amount of token we're sending to recipient (`to`)
    /// @param balance - total balance of `token` in GammaPool
    /// @param collateral - `token` collateral available in loan
    /// @return outAmt - amount of `token` actually sent to recipient (`to`)
    function calcActualOutAmt(address token, address to, uint256 amount, uint256 balance, uint256 collateral) internal
        returns(uint256) {

        uint256 balanceBefore = GammaSwapLibrary.balanceOf(token, to); // check balance before transfer
        sendToken(token, to, amount, balance, collateral); // perform transfer
        return GammaSwapLibrary.balanceOf(token, to) - balanceBefore; // check balance after transfer
    }

    /// @dev Calculate amount bought (`amtIn`) if selling exactly `amountOut`
    /// @param amountOut - amount sending to CFMM to perform swap
    /// @param reserveOut - amount in CFMM of token being sold
    /// @param reserveIn - amount in CFMM of token being bought
    /// @return amtIn - amount expected to receive in GammaPool (calculated bought amount)
    function calcAmtIn(uint256 amountOut, uint256 reserveOut, uint256 reserveIn) internal view returns (uint256) {
        if(reserveOut == 0 || reserveIn == 0) revert ZeroReserves(); // revert if either reserve quantity in CFMM is zero

        uint256 amountOutWithFee = amountOut * getTradingFee1();
        uint256 denominator = (reserveOut * tradingFee2) + amountOutWithFee;
        return amountOutWithFee * reserveIn / denominator;
    }

    /// @dev Calculate amount sold (`amtOut`) if buying exactly `amountIn`
    /// @param amountIn - amount demanding from CFMM to perform swap
    /// @param reserveOut - amount in CFMM of token being sold
    /// @param reserveIn - amount in CFMM of token being bought
    /// @return amtOut - amount expected to send to GammaPool (calculated sold amount)
    function calcAmtOut(uint256 amountIn, uint256 reserveOut, uint256 reserveIn) internal view returns (uint256) {
        if(reserveOut == 0 || reserveIn == 0) revert ZeroReserves(); // revert if either reserve quantity in CFMM is zero

        uint256 denominator = (reserveIn - amountIn) * getTradingFee1();
        return (reserveOut * amountIn * tradingFee2 / denominator) + 1;
    }

    function getTradingFee1() internal view returns(uint24) {
        return feeSource == address(0) ? tradingFee1 : tradingFee2 - IFeeSource(feeSource).gsFee();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@gammaswap/v1-core/contracts/strategies/rebalance/RebalanceStrategy.sol";
import "../../../interfaces/math/ICPMMMath.sol";
import "./CPMMBaseLongStrategy.sol";

/// @title Base Rebalance Strategy concrete implementation contract for Constant Product Market Maker
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Sets up variables used by BaseRebalanceStrategy and defines internal functions specific to CPMM implementation
/// @dev This implementation was specifically designed to work with UniswapV2
abstract contract CPMMBaseRebalanceStrategy is BaseRebalanceStrategy, CPMMBaseLongStrategy {

    error MissingMathLib();
    error CollateralIdGte2();
    error LowPostTradeCollateral();

    /// @return mathLib - contract containing complex mathematical functions
    address immutable public mathLib;

    /// @dev Initializes the contract by setting `mathLib`, `MAX_TOTAL_APY`, `BLOCKS_PER_YEAR`, `tradingFee1`, `tradingFee2`,
    /// @dev `feeSource`, `baseRate`, `optimalUtilRate`, `slope1`, and `slope2`
    constructor(address mathLib_, uint256 maxTotalApy_, uint256 blocksPerYear_, uint24 tradingFee1_, uint24 tradingFee2_,
        address feeSource_, uint64 baseRate_, uint64 optimalUtilRate_, uint64 slope1_, uint64 slope2_) CPMMBaseLongStrategy(maxTotalApy_,
        blocksPerYear_, tradingFee1_, tradingFee2_, feeSource_, baseRate_, optimalUtilRate_, slope1_, slope2_) {

        if(mathLib_ == address(0)) revert MissingMathLib();
        mathLib = mathLib_;
    }

    /// @dev See {BaseRebalanceStrategy-_calcDeltasToCloseSetRatio}.
    function _calcDeltasToCloseSetRatio(uint128[] memory tokensHeld, uint128[] memory reserves, uint256 liquidity, uint256[] memory ratio) internal override virtual view returns(int256[] memory deltas) {
        deltas = new int256[](2);

        uint8 invDecimals = (s.decimals[0] + s.decimals[1])/2;
        uint256 factor = 10**invDecimals;
        uint256 leftVal = uint256(ratio[1]) * factor;
        uint256 rightVal = uint256(ratio[0]) * factor;
        if(leftVal > rightVal) {
            deltas = _calcDeltasToCloseSetRatioStaticCall(liquidity, tokensHeld[0], tokensHeld[1], reserves[0], reserves[1], ratio[0], ratio[1], invDecimals);
            (deltas[0], deltas[1]) = (deltas[1], 0); // swap result, 1st root (index 0) is the only feasible trade
        } else if(leftVal < rightVal) {
            deltas = _calcDeltasToCloseSetRatioStaticCall(liquidity, tokensHeld[1], tokensHeld[0], reserves[1], reserves[0], ratio[1], ratio[0], invDecimals);
            (deltas[0], deltas[1]) = (0, deltas[1]); // swap result, 1st root (index 0) is the only feasible trade
        }
    }

    /// @dev See {BaseRebalanceStrategy-_calcCollateralPostTrade}.
    function _calcCollateralPostTrade(int256[] memory deltas, uint128[] memory tokensHeld, uint128[] memory reserves) internal override virtual view returns(uint256 collateral) {
        if(deltas[0] > 0) {
            collateral = _calcCollateralPostTradeStaticCall(calcInvariant(address(0), tokensHeld), uint256(deltas[0]), tokensHeld[0], tokensHeld[1], reserves[0], reserves[1]);
        } else if(deltas[1] > 0) {
            collateral = _calcCollateralPostTradeStaticCall(calcInvariant(address(0), tokensHeld), uint256(deltas[1]), tokensHeld[1], tokensHeld[0], reserves[1], reserves[0]);
        } else {
            collateral = calcInvariant(address(0), tokensHeld);
        }
    }

    /// @dev See {BaseRebalanceStrategy-_calcDeltasForMaxLP}.
    function _calcDeltasForMaxLP(uint128[] memory tokensHeld, uint128[] memory reserves) internal override virtual view returns(int256[] memory deltas) {
        // we only buy, therefore when desiredRatio > loanRatio, invert reserves, collaterals, and desiredRatio
        deltas = new int256[](2);

        uint256 leftVal = uint256(reserves[0]) * uint256(tokensHeld[1]);
        uint256 rightVal = uint256(reserves[1]) * uint256(tokensHeld[0]);

        if(leftVal > rightVal) {
            deltas = _calcDeltasForMaxLPStaticCall(tokensHeld[0], tokensHeld[1], reserves[0], reserves[1], s.decimals[0]);
            (deltas[0], deltas[1]) = (deltas[1], 0); // swap result, 1st root (index 0) is the only feasible trade
        } else if(leftVal < rightVal) {
            deltas = _calcDeltasForMaxLPStaticCall(tokensHeld[1], tokensHeld[0], reserves[1], reserves[0], s.decimals[1]);
            (deltas[0], deltas[1]) = (0, deltas[1]); // swap result, 1st root (index 0) is the only feasible trade
        }
    }

    /// @dev See {BaseRebalanceStrategy-_calcDeltasToClose}.
    function _calcDeltasToClose(uint128[] memory tokensHeld, uint128[] memory reserves, uint256 liquidity, uint256 collateralId)
        internal virtual override view returns(int256[] memory deltas) {

        if(collateralId >= 2) revert CollateralIdGte2();

        deltas = new int256[](2);

        (bool success, bytes memory data) = mathLib.staticcall(abi.encodeCall(ICPMMMath.calcDeltasToClose,
            (liquidity, calcInvariant(address(0), reserves), tokensHeld[collateralId], reserves[collateralId])));
        require(success && data.length >= 1);

        deltas[collateralId] = abi.decode(data, (int256));
    }

    /// @dev See {BaseRebalanceStrategy-_calcDeltasForRatio}.
    function _calcDeltasForRatio(uint128[] memory tokensHeld, uint128[] memory reserves, uint256[] calldata ratio)
        internal virtual override view returns(int256[] memory deltas) {
        deltas = new int256[](2);

        // we only buy, therefore when desiredRatio > loanRatio, invert reserves, collaterals, and desiredRatio
        uint256 leftVal = uint256(ratio[1]) * uint256(tokensHeld[0]);
        uint256 rightVal = uint256(ratio[0]) * uint256(tokensHeld[1]);
        if(leftVal > rightVal) { // sell token0, buy token1 (need more token1)
            deltas = _calcDeltasForRatioStaticCall(ratio[1], ratio[0], tokensHeld[1], tokensHeld[0], reserves[1], reserves[0]);
            (deltas[0], deltas[1]) = (0, deltas[0]); // swap result, 1st root (index 0) is the only feasible trade
        } else if(leftVal < rightVal) { // buy token0, sell token1 (need more token0)
            deltas = _calcDeltasForRatioStaticCall(ratio[0], ratio[1], tokensHeld[0], tokensHeld[1], reserves[0], reserves[1]);
            deltas[1] = 0; // 1st quadratic root (index 0) is the only feasible trade
        } // otherwise no trade
    }

    /// @dev Function to perform static call to MathLib.calcDeltasForRatio function
    /// @param liquidity - liquidity debt that needs to be repaid after rebalancing loan's collateral quantities
    /// @param ratio0 - ratio parameter of token0
    /// @param ratio1 - ratio parameter of token1
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantity of token0 in CFMM
    /// @param reserve1 - reserve quantity of token1 in CFMM
    /// @param decimals0 - decimals of token0
    /// @return deltas - quadratic roots (quantities to trade).
    function _calcDeltasToCloseSetRatioStaticCall(uint256 liquidity, uint128 tokensHeld0, uint128 tokensHeld1,
        uint128 reserve0, uint128 reserve1, uint256 ratio0, uint256 ratio1, uint8 decimals0) internal virtual view returns(int256[] memory deltas) {

        (bool success, bytes memory data) = mathLib.staticcall(abi.encodeCall(ICPMMMath.
            calcDeltasToCloseSetRatio, (liquidity, ratio0, ratio1, tokensHeld0, tokensHeld1, reserve0, reserve1, decimals0)));
        require(success && data.length >= 1);

        deltas = abi.decode(data, (int256[]));
    }

    /// @dev Calculate value of collateral in terms of liquidity invariant after transaction
    /// @param preCollateral - pre rebalance collateral
    /// @param delta - quantity of token0 to purchase from CFMM
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantity of token0 in CFMM
    /// @param reserve1 - reserve quantity of token1 in CFMM
    /// @return collateral - collateral after transaction in terms of liquidity invariant
    function _calcCollateralPostTradeStaticCall(uint256 preCollateral, uint256 delta, uint128 tokensHeld0, uint128 tokensHeld1, uint256 reserve0, uint256 reserve1) internal virtual view returns(uint256 collateral) {
        uint256 _tradingFee1 = getTradingFee1();
        uint256 minCollateral = preCollateral * (_tradingFee1 + (tradingFee2 - _tradingFee1) / 2)/ tradingFee2;

        // always buys
        (bool success, bytes memory data) = mathLib.staticcall(abi.encodeCall(ICPMMMath.
            calcCollateralPostTrade, (delta, tokensHeld0, tokensHeld1, reserve0, reserve1, _tradingFee1, tradingFee2)));
        require(success && data.length >= 1);

        collateral = abi.decode(data, (uint256));

        if(collateral < minCollateral) revert LowPostTradeCollateral();
    }

    /// @dev Function to perform static call to MathLib.calcDeltasForRatio function
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantity of token0 in CFMM
    /// @param reserve1 - reserve quantity of token1 in CFMM
    /// @param decimals0 - decimals of token0
    /// @return deltas - quadratic roots (quantities to trade).
    function _calcDeltasForMaxLPStaticCall(uint128 tokensHeld0, uint128 tokensHeld1, uint128 reserve0, uint128 reserve1,
        uint8 decimals0) internal virtual view returns(int256[] memory deltas) {

        // always buys
        (bool success, bytes memory data) = mathLib.staticcall(abi.encodeCall(ICPMMMath.
            calcDeltasForMaxLP, (tokensHeld0, tokensHeld1, reserve0, reserve1, getTradingFee1(), tradingFee2, decimals0)));
        require(success && data.length >= 1);

        deltas = abi.decode(data, (int256[]));
    }

    /// @dev Function to perform static call to MathLib.calcDeltasForRatio function
    /// @param ratio0 - numerator of desired ratio to maintain after withdrawal (token0)
    /// @param ratio1 - denominator of desired ratio to maintain after withdrawal (token1)
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantity of token0 in CFMM
    /// @param reserve1 - reserve quantity of token1 in CFMM
    /// @return deltas - quadratic roots (quantities to trade).
    function _calcDeltasForRatioStaticCall(uint256 ratio0, uint256 ratio1, uint128 tokensHeld0, uint128 tokensHeld1,
        uint128 reserve0, uint128 reserve1) internal virtual view returns(int256[] memory deltas) {

        // always buys
        (bool success, bytes memory data) = mathLib.staticcall(abi.encodeCall(ICPMMMath.calcDeltasForRatio,
            (ratio0, ratio1, tokensHeld0, tokensHeld1, reserve0, reserve1, getTradingFee1(), tradingFee2)));
        require(success && data.length >= 1);

        deltas = abi.decode(data, (int256[]));
    }

    /// @dev See {BaseRebalanceStrategy-_calcDeltasForWithdrawal}.
    function _calcDeltasForWithdrawal(uint128[] memory amounts, uint128[] memory tokensHeld, uint128[] memory reserves,
        uint256[] calldata ratio) internal virtual override view returns(int256[] memory deltas) {

        if(amounts[0] > 0) {
            deltas = _calcDeltasForWithdrawalStaticCall(amounts[0], ratio[0], ratio[1], tokensHeld[0], tokensHeld[1], reserves[0], reserves[1]);
            (deltas[0], deltas[1]) = (deltas[1], 0); // swap result, 2nd root (index 1) is the only feasible trade
        } else if(amounts[1] > 0){
            deltas = _calcDeltasForWithdrawalStaticCall(amounts[1], ratio[1], ratio[0], tokensHeld[1], tokensHeld[0], reserves[1], reserves[0]);
            deltas[0] = 0; // 2nd root (index 1) is the only feasible trade
        } // otherwise no trade
    }

    /// @dev Function to perform static call to MathLib.calcDeltasForWithdrawal function
    /// @param amount - amount of token0 requesting to withdraw
    /// @param ratio0 - numerator of desired ratio to maintain after withdrawal (token0)
    /// @param ratio1 - denominator of desired ratio to maintain after withdrawal (token1)
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantities of token0 in CFMM
    /// @param reserve1 - reserve quantities of token1 in CFMM
    /// @return deltas - quantities of reserve tokens to rebalance after withdrawal.
    function _calcDeltasForWithdrawalStaticCall(uint128 amount, uint256 ratio0, uint256 ratio1,uint128 tokensHeld0, uint128 tokensHeld1,
        uint128 reserve0, uint128 reserve1) internal virtual view returns(int256[] memory deltas) {

        // always buys
        (bool success, bytes memory data) = mathLib.staticcall(abi.encodeCall(ICPMMMath.calcDeltasForWithdrawal,
            (amount, ratio0, ratio1, tokensHeld0, tokensHeld1, reserve0, reserve1, getTradingFee1(), tradingFee2)));
        require(success && data.length >= 1);

        deltas = abi.decode(data, (int256[]));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gammaswap/v1-core/contracts/rates/LinearKinkedRateModel.sol";
import "@gammaswap/v1-core/contracts/strategies/base/BaseStrategy.sol";
import "../../../interfaces/external/cpmm/ICPMM.sol";

/// @title Base Strategy abstract contract for Constant Product Market Maker
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Common functions used by all concrete strategy implementations for Constant Product Market Maker
/// @dev This implementation was specifically designed to work with UniswapV2. Inherits Rate Model
abstract contract CPMMBaseStrategy is BaseStrategy, LinearKinkedRateModel {

    error MaxTotalApy();

    /// @dev Number of blocks network will issue within a ear. Currently expected
    uint256 immutable public BLOCKS_PER_YEAR; // 2628000 blocks per year in ETH mainnet (12 seconds per block)

    /// @dev Max total annual APY the GammaPool will charge liquidity borrowers (e.g. 1,000%).
    uint256 immutable public MAX_TOTAL_APY;

    /// @dev Initializes the contract by setting `MAX_TOTAL_APY`, `BLOCKS_PER_YEAR`, `baseRate`, `optimalUtilRate`, `slope1`, and `slope2`
    constructor(uint256 maxTotalApy_, uint256 blocksPerYear_, uint64 baseRate_, uint64 optimalUtilRate_, uint64 slope1_, uint64 slope2_)
        LinearKinkedRateModel(baseRate_, optimalUtilRate_, slope1_, slope2_) {
        // maxTotalApy (CFMM Fees + GammaSwap interest rate) can't be >= maxApy (max GammaSwap interest rate)
        if(maxTotalApy_ == 0 || maxTotalApy_ < baseRate_ + slope1_ + slope2_) revert MaxTotalApy();

        MAX_TOTAL_APY = maxTotalApy_;
        BLOCKS_PER_YEAR = blocksPerYear_;
    }

    /// @dev See {BaseStrategy-maxTotalApy}.
    function maxTotalApy() internal virtual override view returns(uint256) {
        return MAX_TOTAL_APY;
    }

    /// @dev See {BaseStrategy-blocksPerYear}.
    function blocksPerYear() internal virtual override view returns(uint256) {
        return BLOCKS_PER_YEAR;
    }

    /// @dev See {BaseStrategy-syncCFMM}.
    function syncCFMM(address cfmm) internal virtual override {
        ICPMM(cfmm).sync();
    }

    /// @dev See {BaseStrategy-getReserves}.
    function getReserves(address cfmm) internal virtual override view returns(uint128[] memory reserves) {
        reserves = new uint128[](2);
        (reserves[0], reserves[1],) = ICPMM(cfmm).getReserves();
    }

    /// @dev See {BaseStrategy-getReserves}.
    function getLPReserves(address cfmm, bool isLatest) internal virtual override view returns(uint128[] memory reserves) {
        if(isLatest) {
            reserves = new uint128[](2);
            (reserves[0], reserves[1],) = ICPMM(cfmm).getReserves();
        } else {
            reserves = s.CFMM_RESERVES;
        }
    }

    /// @dev See {BaseStrategy-depositToCFMM}.
    function depositToCFMM(address cfmm, address to, uint256[] memory) internal virtual override returns(uint256) {
        return ICPMM(cfmm).mint(to);
    }

    /// @dev See {BaseStrategy-withdrawFromCFMM}.
    function withdrawFromCFMM(address cfmm, address to, uint256 lpTokens) internal virtual override
        returns(uint256[] memory amounts) {
        GammaSwapLibrary.safeTransfer(cfmm, cfmm, lpTokens);
        amounts = new uint256[](2);
        (amounts[0], amounts[1]) = ICPMM(cfmm).burn(to);
    }

    /// @dev See {BaseStrategy-calcInvariant}.
    function calcInvariant(address, uint128[] memory amounts) internal virtual override view returns(uint256) {
        return GSMath.sqrt(uint256(amounts[0]) * amounts[1]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@gammaswap/v1-core/contracts/strategies/lending/BorrowStrategy.sol";
import "@gammaswap/v1-core/contracts/strategies/rebalance/RebalanceStrategy.sol";
import "../base/CPMMBaseRebalanceStrategy.sol";

/// @title Borrow and Rebalance Strategy concrete implementation contract for Constant Product Market Maker
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Sets up variables used by BorrowStrategy and RebalanceStrategy and defines internal functions specific to CPMM implementation
/// @dev This implementation was specifically designed to work with UniswapV2
contract CPMMBorrowStrategy is CPMMBaseRebalanceStrategy, BorrowStrategy, RebalanceStrategy {

    /// @dev Initializes the contract by setting `mathLib`, `MAX_TOTAL_APY`, `BLOCKS_PER_YEAR`, `tradingFee1`, `tradingFee2`,
    /// @dev `feeSource`, `baseRate`, `optimalUtilRate`, `slope1`, and `slope2`
    constructor(address mathLib_, uint256 maxTotalApy_, uint256 blocksPerYear_, uint24 tradingFee1_, uint24 tradingFee2_,
        address feeSource_, uint64 baseRate_, uint64 optimalUtilRate_, uint64 slope1_, uint64 slope2_) CPMMBaseRebalanceStrategy(mathLib_,
        maxTotalApy_, blocksPerYear_, tradingFee1_, tradingFee2_, feeSource_, baseRate_, optimalUtilRate_, slope1_, slope2_) {
    }

    /// @dev See {BaseBorrowStrategy-getCurrentCFMMPrice}.
    function getCurrentCFMMPrice() internal virtual override view returns(uint256) {
        return s.CFMM_RESERVES[1] * (10 ** s.decimals[0]) / s.CFMM_RESERVES[0];
    }
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