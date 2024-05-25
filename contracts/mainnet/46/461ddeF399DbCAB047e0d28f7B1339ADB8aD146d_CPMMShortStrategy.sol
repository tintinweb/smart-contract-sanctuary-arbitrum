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

/// @title ISendTokensCallback interface to handle callbacks to send tokens
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Used by periphery contracts to transfer token amounts requested by a GammaPool
/// @dev Verifies sender is GammaPool by hashing SendTokensCallbackData contents into msg.sender
interface ISendTokensCallback {

    /// @dev Struct received in sendTokensCallback (`data`) used to identify caller as GammaPool
    struct SendTokensCallbackData {
        /// @dev sender of tokens
        address payer;

        /// @dev address of CFMM that will be used to identify GammaPool
        address cfmm;

        /// @dev protocolId that will be used to identify GammaPool
        uint16 protocolId;
    }

    /// @dev Transfer token `amounts` after verifying identity of caller using `data` is a GammaPool
    /// @param tokens - address of ERC20 tokens that will be transferred
    /// @param amounts - token amounts to be transferred
    /// @param payee - receiver of token `amounts`
    /// @param data - struct used to verify the function caller
    function sendTokensCallback(address[] calldata tokens, uint256[] calldata amounts, address payee, bytes calldata data) external;
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

import "../events/IShortStrategyEvents.sol";

/// @title Interface for Short Strategy
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Used in strategies that deposit and withdraw liquidity from CFMM for liquidity providers
interface IShortStrategy is IShortStrategyEvents {

    /// @dev Parameters used to calculate the GS LP tokens and CFMM LP tokens in the GammaPool after protocol fees and accrued interest
    struct VaultBalancesParams {
        /// @dev address of factory contract of GammaPool
        address factory;
        /// @dev address of GammaPool
        address pool;
        /// @dev address of contract holding rate parameters for pool
        address paramsStore;
        /// @dev storage number of borrowed liquidity invariant in GammaPool
        uint256 BORROWED_INVARIANT;
        /// @dev current liquidity invariant in CFMM
        uint256 latestCfmmInvariant;
        /// @dev current total supply of CFMM LP tokens in existence
        uint256 latestCfmmTotalSupply;
        /// @dev last block number GammaPool was updated
        uint256 LAST_BLOCK_NUMBER;
        /// @dev CFMM liquidity invariant at time of last update of GammaPool
        uint256 lastCFMMInvariant;
        /// @dev CFMM LP Token supply at time of last update of GammaPool
        uint256 lastCFMMTotalSupply;
        /// @dev CFMM Fee Index at time of last update of GammaPool
        uint256 lastCFMMFeeIndex;
        /// @dev current total supply of GS LP tokens
        uint256 totalSupply;
        /// @dev current LP Tokens in GammaPool counted at time of last update
        uint256 LP_TOKEN_BALANCE;
        /// @dev liquidity invariant of LP tokens in GammaPool at time of last update
        uint256 LP_INVARIANT;
    }


    /// @dev Deposit CFMM LP tokens and get GS LP tokens, without doing a transferFrom transaction. Must have sent CFMM LP tokens first
    /// @param to - address of receiver of GS LP token
    /// @return shares - quantity of GS LP tokens received for CFMM LP tokens
    function _depositNoPull(address to) external returns(uint256 shares);

    /// @dev Withdraw CFMM LP tokens, by burning GS LP tokens, without doing a transferFrom transaction. Must have sent GS LP tokens first
    /// @param to - address of receiver of CFMM LP tokens
    /// @return assets - quantity of CFMM LP tokens received for GS LP tokens
    function _withdrawNoPull(address to) external returns(uint256 assets);

    /// @dev Withdraw reserve token quantities of CFMM (instead of CFMM LP tokens), by burning GS LP tokens
    /// @param to - address of receiver of reserve token quantities
    /// @return reserves - quantity of reserve tokens withdrawn from CFMM and sent to receiver
    /// @return assets - quantity of CFMM LP tokens representing reserve tokens withdrawn
    function _withdrawReserves(address to) external returns(uint256[] memory reserves, uint256 assets);

    /// @dev Deposit reserve token quantities to CFMM (instead of CFMM LP tokens) to get CFMM LP tokens, store them in GammaPool and receive GS LP tokens
    /// @param to - address of receiver of GS LP tokens
    /// @param amountsDesired - desired amounts of reserve tokens to deposit
    /// @param amountsMin - minimum amounts of reserve tokens to deposit
    /// @param data - information identifying request to deposit
    /// @return reserves - quantity of actual reserve tokens deposited in CFMM
    /// @return shares - quantity of GS LP tokens received for reserve tokens deposited
    function _depositReserves(address to, uint256[] calldata amountsDesired, uint256[] calldata amountsMin, bytes calldata data) external returns(uint256[] memory reserves, uint256 shares);

    /// @dev Get latest reserves in the CFMM, which can be used for pricing
    /// @param cfmmData - bytes data for calculating CFMM reserves
    /// @return cfmmReserves - reserves in the CFMM
    function _getLatestCFMMReserves(bytes memory cfmmData) external view returns(uint128[] memory cfmmReserves);

    /// @dev Get latest invariant from CFMM
    /// @param cfmmData - bytes data for calculating CFMM invariant
    /// @return cfmmInvariant - reserves in the CFMM
    function _getLatestCFMMInvariant(bytes memory cfmmData) external view returns(uint256 cfmmInvariant);

    /// @dev Calculate current total CFMM LP tokens (real and virtual) in existence in the GammaPool, including accrued interest
    /// @param borrowedInvariant - invariant amount borrowed in GammaPool including accrued interest calculated in last update to GammaPool
    /// @param lpBalance - amount of LP tokens deposited in GammaPool
    /// @param lastCFMMInvariant - invariant amount in CFMM
    /// @param lastCFMMTotalSupply - total supply in CFMM
    /// @param lastFeeIndex - last fees charged by GammaPool since last update
    /// @return totalAssets - total CFMM LP tokens in existence in the pool (real and virtual) including accrued interest
    function totalAssets(uint256 borrowedInvariant, uint256 lpBalance, uint256 lastCFMMInvariant, uint256 lastCFMMTotalSupply, uint256 lastFeeIndex) external view returns(uint256);

    /// @dev Calculate current total GS LP tokens in the GammaPool after dilution from protocol fees
    /// @param factory - address of factory contract that created GammaPool
    /// @param pool - address of pool to get interest rate calculations for
    /// @param lastCFMMFeeIndex - accrued CFMM Fees in storage
    /// @param lastFeeIndex - last fees charged by GammaPool since last update
    /// @param utilizationRate - current utilization rate of GammaPool
    /// @param supply - actual GS LP total supply available in the pool
    /// @return totalSupply - total GS LP tokens in the pool including accrued interest
    function totalSupply(address factory, address pool, uint256 lastCFMMFeeIndex, uint256 lastFeeIndex, uint256 utilizationRate, uint256 supply) external view returns (uint256);

    /// @dev Calculate fees charged by GammaPool since last update to liquidity loans and current borrow rate
    /// @param borrowRate - current borrow rate of GammaPool
    /// @param borrowedInvariant - invariant amount borrowed in GammaPool including accrued interest calculated in last update to GammaPool
    /// @param lastCFMMInvariant - current invariant amount of CFMM in GammaPool
    /// @param lastCFMMTotalSupply - current total supply of CFMM LP shares in GammaPool
    /// @param prevCFMMInvariant - invariant amount in CFMM in last update to GammaPool
    /// @param prevCFMMTotalSupply - total supply in CFMM in last update to GammaPool
    /// @param lastBlockNum - last block GammaPool was updated
    /// @param lastCFMMFeeIndex - last fees accrued by CFMM since last update
    /// @param maxCFMMFeeLeverage - max leverage of CFMM yield
    /// @param spread - spread to add to cfmmFeeIndex
    /// @return lastFeeIndex - last fees charged by GammaPool since last update
    /// @return updLastCFMMFeeIndex - updated fees accrued by CFMM till current block
    function getLastFees(uint256 borrowRate, uint256 borrowedInvariant, uint256 lastCFMMInvariant, uint256 lastCFMMTotalSupply,
        uint256 prevCFMMInvariant, uint256 prevCFMMTotalSupply, uint256 lastBlockNum, uint256 lastCFMMFeeIndex,
        uint256 maxCFMMFeeLeverage, uint256 spread) external view returns(uint256 lastFeeIndex, uint256 updLastCFMMFeeIndex);

    /// @dev Calculate current total GS LP tokens after protocol fees and total CFMM LP tokens (real and virtual) in
    /// @dev existence in the GammaPool after accrued interest. The total assets and supply numbers returned by this
    /// @dev function are used in the ERC4626 implementation of the GammaPool
    /// @param vaultBalanceParams - parameters from GammaPool to calculate current total GS LP Tokens and CFMM LP Tokens after fees and interest
    /// @return assets - total CFMM LP tokens in existence in the pool (real and virtual) including accrued interest
    /// @return supply - total GS LP tokens in the pool including accrued interest
    function totalAssetsAndSupply(VaultBalancesParams memory vaultBalanceParams) external view returns(uint256 assets, uint256 supply);

    /// @dev Calculate balances updated by fees charged since last update
    /// @param lastFeeIndex - last fees charged by GammaPool since last update
    /// @param borrowedInvariant - invariant amount borrowed in GammaPool including accrued interest calculated in last update to GammaPool
    /// @param lpBalance - amount of LP tokens deposited in GammaPool
    /// @param lastCFMMInvariant - invariant amount in CFMM
    /// @param lastCFMMTotalSupply - total supply in CFMM
    /// @return lastLPBalance - last fees accrued by CFMM since last update
    /// @return lastBorrowedLPBalance - last fees charged by GammaPool since last update
    /// @return lastBorrowedInvariant - current borrow rate of GammaPool
    function getLatestBalances(uint256 lastFeeIndex, uint256 borrowedInvariant, uint256 lpBalance, uint256 lastCFMMInvariant,
        uint256 lastCFMMTotalSupply) external view returns(uint256 lastLPBalance, uint256 lastBorrowedLPBalance, uint256 lastBorrowedInvariant);

    /// @dev Update pool invariant, LP tokens borrowed plus interest, interest rate index, and last block update
    /// @param utilizationRate - interest accrued to loans in GammaPool
    /// @param emaUtilRateLast - interest accrued to loans in GammaPool
    /// @param emaMultiplier - interest accrued to loans in GammaPool
    /// @return emaUtilRate - interest accrued to loans in GammaPool
    function calcUtilRateEma(uint256 utilizationRate, uint256 emaUtilRateLast, uint256 emaMultiplier) external view returns(uint256 emaUtilRate);

    /// @dev Synchronize LP_TOKEN_BALANCE with actual CFMM LP tokens deposited in GammaPool
    function _sync() external;

    /***** ERC4626 Functions *****/

    /// @dev Deposit CFMM LP tokens and get GS LP tokens, does a transferFrom according to ERC4626 implementation
    /// @param assets - CFMM LP tokens deposited in exchange for GS LP tokens
    /// @param to - address receiving GS LP tokens
    /// @return shares - quantity of GS LP tokens sent to receiver address (`to`) for CFMM LP tokens
    function _deposit(uint256 assets, address to) external returns (uint256 shares);

    /// @dev Mint GS LP token in exchange for CFMM LP token deposits, does a transferFrom according to ERC4626 implementation
    /// @param shares - GS LP tokens minted from CFMM LP token deposits
    /// @param to - address receiving GS LP tokens
    /// @return assets - quantity of CFMM LP tokens sent to receiver address (`to`)
    function _mint(uint256 shares, address to) external returns (uint256 assets);

    /// @dev Withdraw CFMM LP token by burning GS LP tokens
    /// @param assets - amount of CFMM LP tokens requested to withdraw in exchange for GS LP tokens
    /// @param to - address receiving CFMM LP tokens
    /// @param from - address burning its GS LP tokens
    /// @return shares - quantity of GS LP tokens burned
    function _withdraw(uint256 assets, address to, address from) external returns (uint256 shares);

    /// @dev Redeem GS LP tokens and get CFMM LP token
    /// @param shares - GS LP tokens requested to redeem in exchange for GS LP tokens
    /// @param to - address receiving CFMM LP tokens
    /// @param from - address redeeming GS LP tokens
    /// @return assets - quantity of CFMM LP tokens sent to receiver address (`to`) for GS LP tokens redeemed
    function _redeem(uint256 shares, address to, address from) external returns (uint256 assets);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./IStrategyEvents.sol";

/// @title Short Strategy Events Interface
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Events emitted by all short strategy implementations
interface IShortStrategyEvents is IStrategyEvents {
    /// @dev Event emitted when a deposit of CFMM LP tokens in exchange of GS LP tokens happens (e.g. _deposit, _mint, _depositReserves, _depositNoPull)
    /// @param caller - address calling the function to deposit CFMM LP tokens
    /// @param to - address receiving GS LP tokens
    /// @param assets - amount CFMM LP tokens deposited
    /// @param shares - amount GS LP tokens minted
    event Deposit(address indexed caller, address indexed to, uint256 assets, uint256 shares);

    /// @dev Event emitted when a withdrawal of CFMM LP tokens happens (e.g. _withdraw, _redeem, _withdrawReserves, _withdrawNoPull)
    /// @param caller - address calling the function to withdraw CFMM LP tokens
    /// @param to - address receiving CFMM LP tokens
    /// @param from - address redeeming/burning GS LP tokens
    /// @param assets - amount of CFMM LP tokens withdrawn
    /// @param shares - amount of GS LP tokens redeemed
    event Withdraw(address indexed caller, address indexed to, address indexed from, uint256 assets, uint256 shares);
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
        self.minUtilRate1 = 92; // min util rate 1 is 92%
        self.minUtilRate2 = 80; // min util rate 2 is 80%
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
    error NotEnoughLPInvariant();

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
    function checkExpectedUtilizationRate(uint256 lpTokens, bool isLoan) internal virtual view {
        uint256 lpTokenInvariant = convertLPToInvariant(lpTokens, s.lastCFMMInvariant, s.lastCFMMTotalSupply);
        uint256 lpInvariant = s.LP_INVARIANT;
        if(lpInvariant < lpTokenInvariant) revert NotEnoughLPInvariant();
        unchecked {
            lpInvariant = lpInvariant - lpTokenInvariant;
        }
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

import "../interfaces/strategies/base/IShortStrategy.sol";
import "../interfaces/periphery/ISendTokensCallback.sol";
import "./base/BaseStrategy.sol";

/// @title Short Strategy abstract contract implementation of IShortStrategy
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice All external functions are locked to avoid reentrancy
/// @dev Only defines common functions that would be used by all concrete contracts that deposit and withdraw liquidity
abstract contract ShortStrategy is IShortStrategy, BaseStrategy {

    error ZeroShares();
    error ZeroAssets();
    error ExcessiveWithdrawal();
    error ExcessiveSpend();
    error InvalidAmountsDesiredLength();
    error InvalidAmountsMinLength();

    /// @dev Error thrown when wrong amount of ERC20 token is deposited in GammaPool
    /// @param token - address of ERC20 token that caused the error
    error WrongTokenBalance(address token);

    // Short Gamma

    /// @dev Minimum number of shares issued on first deposit to avoid rounding issues
    uint256 public constant MIN_SHARES = 1e3;

    /// @notice Calculate amounts to deposit in CFMM depending on the CFMM's formula
    /// @dev The user requests desired amounts to deposit and sets minimum amounts since actual amounts are unknown at time of request
    /// @param amountsDesired - desired amounts of reserve tokens to deposit in CFMM
    /// @param amountsMin - minimum amounts of reserve tokens expected to deposit in CFMM
    /// @return reserves - amounts that will be deposited in CFMM
    /// @return payee - address reserve tokens will be sent to. Address holding CFMM's reserves might be different from CFMM's address
    function calcDepositAmounts(uint256[] calldata amountsDesired, uint256[] calldata amountsMin) internal virtual view returns (uint256[] memory reserves, address payee);

    /// @inheritdoc IShortStrategy
    function calcUtilRateEma(uint256 utilizationRate, uint256 emaUtilRateLast, uint256 emaMultiplier) external virtual override view returns(uint256 emaUtilRate) {
        return _calcUtilRateEma(utilizationRate, emaUtilRateLast, emaMultiplier);
    }

    /// @inheritdoc IShortStrategy
    function totalAssets(uint256 borrowedInvariant, uint256 lpBalance, uint256 lastCFMMInvariant, uint256 lastCFMMTotalSupply, uint256 lastFeeIndex) public virtual override view returns(uint256 lastLPBalance) {
        // Return CFMM LP tokens depositedin GammaPool plus borrowed liquidity invariant with accrued interest in terms of CFMM LP tokens
        (lastLPBalance,,) = getLatestBalances(lastFeeIndex, borrowedInvariant, lpBalance, lastCFMMInvariant, lastCFMMTotalSupply);
    }

    /// @inheritdoc IShortStrategy
    function totalSupply(address factory, address pool, uint256 lastCFMMFeeIndex, uint256 lastFeeIndex, uint256 utilizationRate, uint256 supply) public virtual override view returns (uint256) {
        uint256 devShares = 0;
        (address feeTo, uint256 protocolFee,, ) = IGammaPoolFactory(factory).getPoolFee(pool);
        if(feeTo != address(0)) {
            uint256 printPct = _calcProtocolDilution(lastFeeIndex, lastCFMMFeeIndex, utilizationRate, protocolFee);
            devShares = supply * printPct / 1e18;
        }
        return supply + devShares;
    }

    /// @inheritdoc IShortStrategy
    function getLatestBalances(uint256 lastFeeIndex, uint256 borrowedInvariant, uint256 lpBalance, uint256 lastCFMMInvariant, uint256 lastCFMMTotalSupply) public virtual override view
        returns(uint256 lastLPBalance, uint256 lastBorrowedLPBalance, uint256 lastBorrowedInvariant) {
        lastBorrowedInvariant = accrueBorrowedInvariant(borrowedInvariant, lastFeeIndex);
        lastBorrowedLPBalance =  convertInvariantToLP(lastBorrowedInvariant, lastCFMMTotalSupply, lastCFMMInvariant);
        lastLPBalance = lpBalance + lastBorrowedLPBalance;
    }

    /// @inheritdoc IShortStrategy
    function getLastFees(uint256 borrowRate, uint256 borrowedInvariant, uint256 lastCFMMInvariant, uint256 lastCFMMTotalSupply,
        uint256 prevCFMMInvariant, uint256 prevCFMMTotalSupply, uint256 lastBlockNum, uint256 lastCFMMFeeIndex,
        uint256 maxCFMMFeeLeverage, uint256 spread) public virtual override view returns(uint256 lastFeeIndex, uint256 updatedLastCFMMFeeIndex) {
        lastBlockNum = block.number - lastBlockNum;

        updatedLastCFMMFeeIndex = lastBlockNum > 0 ? calcCFMMFeeIndex(borrowedInvariant, lastCFMMInvariant, lastCFMMTotalSupply, prevCFMMInvariant, prevCFMMTotalSupply, maxCFMMFeeLeverage) * lastCFMMFeeIndex / 1e18 : 1e18;

        // Calculate interest that would be charged to entire pool's liquidity debt if pool were updated in this transaction
        lastFeeIndex = calcFeeIndex(updatedLastCFMMFeeIndex, borrowRate, lastBlockNum, spread);
    }

    /// @inheritdoc IShortStrategy
    function totalAssetsAndSupply(VaultBalancesParams memory _params) public virtual override view returns(uint256 assets, uint256 supply) {
        // use lastFeeIndex and cfmmFeeIndex to hold maxCFMMFeeLeverage and spread respectively
        (uint256 borrowRate, uint256 utilizationRate, uint256 lastFeeIndex, uint256 cfmmFeeIndex) = calcBorrowRate(_params.LP_INVARIANT,
            _params.BORROWED_INVARIANT, _params.paramsStore, _params.pool);

        (lastFeeIndex, cfmmFeeIndex) = getLastFees(borrowRate, _params.BORROWED_INVARIANT, _params.latestCfmmInvariant,
            _params.latestCfmmTotalSupply, _params.lastCFMMInvariant, _params.lastCFMMTotalSupply, _params.LAST_BLOCK_NUMBER,
            _params.lastCFMMFeeIndex, lastFeeIndex, cfmmFeeIndex);

        // Total amount of GS LP tokens issued after protocol fees are paid
        assets = totalAssets(_params.BORROWED_INVARIANT, _params.LP_TOKEN_BALANCE, _params.latestCfmmInvariant, _params.latestCfmmTotalSupply, lastFeeIndex);

        // Calculates total CFMM LP tokens, including accrued interest, using state variables
        supply = totalSupply(_params.factory, _params.pool, cfmmFeeIndex, lastFeeIndex, utilizationRate, _params.totalSupply);
    }

    //********* Short Gamma Functions *********//

    /// @inheritdoc IShortStrategy
    function _depositNoPull(address to) external virtual override lock returns(uint256 shares) {
        shares = depositAssetsNoPull(to, false);
    }

    /// @notice Deposit CFMM LP tokens without calling transferFrom
    /// @dev There has to be unaccounted for CFMM LP tokens before calling this function
    /// @param to - address of receiver of GS LP tokens that will be minted
    /// @param isDepositReserves - true if depositing reserve tokens, false if depositing CFMM LP tokens
    /// @return shares - amount of GS LP tokens minted
    function depositAssetsNoPull(address to, bool isDepositReserves) internal virtual returns(uint256 shares) {
        // Unaccounted for CFMM LP tokens in GammaPool, presumably deposited by user requesting GS LP tokens
        uint256 assets = GammaSwapLibrary.balanceOf(s.cfmm, address(this)) - s.LP_TOKEN_BALANCE;

        // Update interest rate and state variables before conversion
        updateIndex();

        // Convert CFMM LP tokens (`assets`) to GS LP tokens (`shares`)
        shares = convertToShares(assets);
        // revert if request is for 0 GS LP tokens
        if(shares == 0) revert ZeroShares();

        // To prevent rounding errors, lock min shares in first deposit
        if(s.totalSupply == 0) {
            shares = shares - MIN_SHARES;
            assets = assets - MIN_SHARES;
            depositAssets(msg.sender, address(0), MIN_SHARES, MIN_SHARES, isDepositReserves);
        }
        // Track CFMM LP tokens (`assets`) in GammaPool and mint GS LP tokens (`shares`) to receiver (`to`)
        depositAssets(msg.sender, to, assets, shares, isDepositReserves);
    }

    /// @inheritdoc IShortStrategy
    function _withdrawNoPull(address to) external virtual override lock returns(uint256 assets) {
        (,assets) = withdrawAssetsNoPull(to, false); // withdraw CFMM LP tokens
    }

    /// @notice Transactions to perform before calling the deposit function in CFMM (e.g. transferring reserve tokens)
    /// @dev Tokens are usually sent to an address calculated by the `calcDepositAmounts` function before calling the deposit function in the CFMM
    /// @param amounts - amounts of reserve tokens to transfer
    /// @param to - destination address of reserve tokens
    /// @param data - information to verify transaction request in contract performing the transfer
    /// @return deposits - amounts deposited at `to`
    function preDepositToCFMM(uint256[] memory amounts, address to, bytes memory data) internal virtual returns (uint256[] memory deposits) {
        address[] storage tokens = s.tokens;
        deposits = new uint256[](tokens.length);
        for(uint256 i; i < tokens.length;) {
            // Get current reserve token balances in destination address
            deposits[i] = GammaSwapLibrary.balanceOf(tokens[i], to);
            unchecked {
                ++i;
            }
        }
        // Ask msg.sender to send reserve tokens to destination address
        ISendTokensCallback(msg.sender).sendTokensCallback(tokens, amounts, to, data);
        uint256 newBalance;
        for(uint256 i; i < tokens.length;) {
            if(amounts[i] > 0) {
                newBalance = GammaSwapLibrary.balanceOf(tokens[i], to);
                // Check destination address received reserve tokens by comparing with previous balances
                if(deposits[i] >= newBalance) revert WrongTokenBalance(tokens[i]);

                unchecked {
                    deposits[i] = newBalance - deposits[i];
                }
            } else {
                deposits[i] = 0;
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IShortStrategy
    function _depositReserves(address to, uint256[] calldata amountsDesired, uint256[] calldata amountsMin, bytes calldata data) external virtual override lock returns(uint256[] memory reserves, uint256 shares) {
        {
            uint256 tokenLen = s.tokens.length;
            if(amountsDesired.length != tokenLen) revert InvalidAmountsDesiredLength();
            if(amountsMin.length != tokenLen) revert InvalidAmountsMinLength();
        }

        address payee; // address that will receive reserve tokens from depositor

        // Calculate amounts of reserve tokens to send and address to send them to
        (reserves, payee) = calcDepositAmounts(amountsDesired, amountsMin);

        // Transfer reserve tokens
        reserves = preDepositToCFMM(reserves, payee, data);

        // Call deposit function requesting CFMM LP tokens from CFMM and deposit them in GammaPool
        depositToCFMM(s.cfmm, address(this), reserves);

        // Mint GS LP Tokens to receiver (`to`) equivalent in value to CFMM LP tokens just deposited
        shares = depositAssetsNoPull(to, true);
    }

    /// @inheritdoc IShortStrategy
    function _withdrawReserves(address to) external virtual override lock returns(uint256[] memory reserves, uint256 assets) {
        (reserves, assets) = withdrawAssetsNoPull(to, true); // Withdraw reserve tokens
    }

    /// @dev Withdraw CFMM LP tokens from GammaPool or reserve tokens from CFMM and send them to receiver address (`to`)
    /// @param to - receiver address of CFMM LP tokens or reserve tokens
    /// @param askForReserves - send reserve tokens to receiver (`to`) if true, send CFMM LP tokens otherwise
    function withdrawAssetsNoPull(address to, bool askForReserves) internal virtual returns(uint256[] memory reserves, uint256 assets) {
        // Check is GammaPool has received GS LP tokens
        uint256 shares = s.balanceOf[address(this)];

        // Update interest rate and state variables before conversion
        updateIndex();

        // Convert GS LP tokens (`shares`) to CFMM LP tokens (`assets`)
        assets = convertToAssets(shares);
        // revert if request is for 0 CFMM LP tokens
        if(assets == 0) revert ZeroAssets();

        // Revert if not enough CFMM LP tokens in GammaPool
        if(assets > s.LP_TOKEN_BALANCE) revert ExcessiveWithdrawal();

        // Send CFMM LP tokens or reserve tokens to receiver (`to`) and burn corresponding GS LP tokens from GammaPool address
        reserves = withdrawAssets(address(this), to, address(this), assets, shares, askForReserves);
    }

    //************* ERC-4626 Functions ************//

    /// @dev Mint GS LP tokens (`shares`) to receiver (`to`) and track CFMM LP tokens (`assets`)
    /// @param caller - user address that requested to deposit CFMM LP tokens
    /// @param to - address receiving GS LP tokens (`shares`)
    /// @param assets - amount of CFMM LP tokens deposited
    /// @param shares - amount of GS LP tokens minted to receiver
    /// @param isDepositReserves - true if depositing reserve tokens, false if depositing CFMM LP tokens
    function depositAssets(address caller, address to, uint256 assets, uint256 shares, bool isDepositReserves) internal virtual {
        _mint(to, shares); // mint GS LP tokens to receiver (`to`)

        // Update CFMM LP token amount tracked by GammaPool and invariant in CFMM belonging to GammaPool
        uint256 lpTokenBalance = GammaSwapLibrary.balanceOf(s.cfmm, address(this));
        uint128 lpInvariant = uint128(convertLPToInvariant(lpTokenBalance, s.lastCFMMInvariant, s.lastCFMMTotalSupply));
        s.LP_TOKEN_BALANCE = lpTokenBalance;
        s.LP_INVARIANT = lpInvariant;

        emit Deposit(caller, to, assets, shares);
        emit PoolUpdated(lpTokenBalance, s.LP_TOKEN_BORROWED, s.LAST_BLOCK_NUMBER, s.accFeeIndex, s.LP_TOKEN_BORROWED_PLUS_INTEREST,
            lpInvariant, s.BORROWED_INVARIANT, s.CFMM_RESERVES, isDepositReserves ? TX_TYPE.DEPOSIT_RESERVES : TX_TYPE.DEPOSIT_LIQUIDITY);

        afterDeposit(assets, shares);
    }

    /// @dev Withdraw CFMM LP tokens (`assets`) or their reserve token equivalent to receiver (`to`) by burning GS LP tokens (`shares`)
    /// @param caller - user address that requested to withdraw CFMM LP tokens
    /// @param to - address receiving CFMM LP tokens (`shares`) or their reserve token equivalent
    /// @param owner - address that owns GS LP tokens (`shares`) that will be burned
    /// @param assets - amount of CFMM LP tokens that will be sent to receiver (`to`)
    /// @param shares - amount of GS LP tokens that will be burned
    /// @param askForReserves - withdraw reserve tokens if true, CFMM LP tokens otherwise
    /// @return reserves - amount of reserve tokens withdrawn if `askForReserves` is true
    function withdrawAssets(address caller, address to, address owner, uint256 assets, uint256 shares, bool askForReserves) internal virtual returns(uint256[] memory reserves){
        if (caller != owner) { // If caller does not own GS LP tokens, check if allowed to burn them
            spendAllowance(owner, caller, shares);
        }

        checkExpectedUtilizationRate(assets, false);

        beforeWithdraw(assets, shares); // Before withdraw hook

        _burn(owner, shares); // Burn owner's GS LP tokens

        address cfmm = s.cfmm; // Save gas
        uint256 lpTokenBalance;
        uint128 lpInvariant;
        if(askForReserves) { // If withdrawing reserve tokens
            reserves = withdrawFromCFMM(cfmm, to, assets); // Changes lastCFMMTotalSupply and lastCFMMInvariant (less assets, less invariant)
            lpTokenBalance = GammaSwapLibrary.balanceOf(cfmm, address(this));
            uint256 lastCFMMInvariant = calcInvariant(cfmm, getLPReserves(cfmm, true));
            uint256 lastCFMMTotalSupply = GammaSwapLibrary.totalSupply(cfmm);
            lpInvariant = uint128(convertLPToInvariant(lpTokenBalance, lastCFMMInvariant, lastCFMMTotalSupply));
            s.lastCFMMInvariant = uint128(lastCFMMInvariant); // Less invariant
            s.lastCFMMTotalSupply = lastCFMMTotalSupply; // Less CFMM LP tokens in existence
        } else { // If withdrawing CFMM LP tokens
            GammaSwapLibrary.safeTransfer(cfmm, to, assets); // doesn't change lastCFMMTotalSupply or lastCFMMInvariant
            lpTokenBalance = GammaSwapLibrary.balanceOf(cfmm, address(this));
            lpInvariant = uint128(convertLPToInvariant(lpTokenBalance, s.lastCFMMInvariant, s.lastCFMMTotalSupply));
        }
        s.LP_INVARIANT = lpInvariant;
        s.LP_TOKEN_BALANCE = lpTokenBalance;

        emit Withdraw(caller, to, owner, assets, shares);
        emit PoolUpdated(lpTokenBalance, s.LP_TOKEN_BORROWED, s.LAST_BLOCK_NUMBER, s.accFeeIndex, s.LP_TOKEN_BORROWED_PLUS_INTEREST,
            lpInvariant, s.BORROWED_INVARIANT, s.CFMM_RESERVES, askForReserves ? TX_TYPE.WITHDRAW_RESERVES : TX_TYPE.WITHDRAW_LIQUIDITY);
    }

    /// @dev Check if `spender` has permissions to spend `amount` of GS LP tokens belonging to `owner`
    /// @param owner - address that owns the GS LP tokens
    /// @param spender - address that will spend the GS LP tokens (`amount`) of the owner
    /// @param amount - amount of owner's GS LP tokens that will be spent
    function spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 allowed = s.allowance[owner][spender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max) { // If limited spending
            // Not allowed to spend that much
            if(allowed < amount) revert ExcessiveSpend();

            unchecked {
                s.allowance[owner][spender] = allowed - amount;
            }
        }
    }

    // ACCOUNTING LOGIC

    /// @dev Check if `spender` has permissions to spend `amount` of GS LP tokens belonging to `owner`
    /// @param assets - address that owns the GS LP tokens
    function convertToShares(uint256 assets) internal view virtual returns (uint256) {
        uint256 supply = s.totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        uint256 _totalAssets = s.LP_TOKEN_BALANCE + s.LP_TOKEN_BORROWED_PLUS_INTEREST;
        return supply == 0 || _totalAssets == 0 ? assets : (assets * supply / _totalAssets);
    }

    /// @dev Check if `spender` has permissions to spend `amount` of GS LP tokens belonging to `owner`
    /// @param shares - address that owns the GS LP tokens
    function convertToAssets(uint256 shares) internal view virtual returns (uint256) {
        uint256 supply = s.totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? shares : (shares * (s.LP_TOKEN_BALANCE + s.LP_TOKEN_BORROWED_PLUS_INTEREST) / supply);
    }

    // INTERNAL HOOKS LOGIC

    /// @dev Hook function that executes before withdrawal of CFMM LP tokens (`withdrawAssets`) but after token conversion
    /// @param assets - amount of CFMM LP tokens
    /// @param shares - amount GS LP tokens
    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    /// @dev Hook function that executes after deposit of CFMM LP tokens
    /// @param assets - amount of CFMM LP tokens
    /// @param shares - amount GS LP tokens
    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "./ShortStrategy.sol";

/// @title Short Strategy ERC4626 abstract contract implementation of IShortStrategy's ERC4626 functions
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice All external functions that modify the state are locked to avoid reentrancy
/// @dev Only defines ERC4626 functions of ShortStrategy
abstract contract ShortStrategyERC4626 is ShortStrategy {

    /// @dev See {IShortStrategy-_deposit}.
    function _deposit(uint256 assets, address to) external virtual override lock returns(uint256 shares) {
        // Update interest rate and state variables before conversion
        updateIndex();

        // Convert CFMM LP tokens to GS LP tokens
        shares = convertToShares(assets);

        // Revert if redeeming 0 GS LP tokens
        if(shares == 0) revert ZeroShares();

        // Transfer CFMM LP tokens (`assets`) from msg.sender to GammaPool and mint GS LP tokens (`shares`) to receiver (`to`)
        depositAssetsFrom(msg.sender, to, assets, shares);
    }

    /// @dev See {IShortStrategy-_mint}.
    function _mint(uint256 shares, address to) external virtual override lock returns(uint256 assets) {
        // Update interest rate and state variables before conversion
        updateIndex();

        // Convert GS LP tokens to CFMM LP tokens
        assets = convertToAssets(shares);

        // Revert if withdrawing 0 CFMM LP tokens
        if(assets == 0) revert ZeroAssets();

        // Transfer CFMM LP tokens (`assets`) from msg.sender to GammaPool and mint GS LP tokens (`shares`) to receiver (`to`)
        depositAssetsFrom(msg.sender, to, assets, shares);
    }

    /// @dev See {IShortStrategy-_withdraw}.
    function _withdraw(uint256 assets, address to, address from) external virtual override lock returns(uint256 shares) {
        // Update interest rate and state variables before conversion
        updateIndex();

        // Revert if not enough CFMM LP tokens to withdraw
        if(assets > s.LP_TOKEN_BALANCE) revert ExcessiveWithdrawal();

        // Convert CFMM LP tokens to GS LP tokens
        shares = convertToShares(assets);

        // Revert if redeeming 0 GS LP tokens
        if(shares == 0) revert ZeroShares();

        // Send CFMM LP tokens to receiver (`to`) and burn corresponding GS LP tokens from msg.sender
        withdrawAssets(msg.sender, to, from, assets, shares, false);
    }

    /// @dev See {IShortStrategy-_redeem}.
    function _redeem(uint256 shares, address to, address from) external virtual override lock returns(uint256 assets) {
        // Update interest rate and state variables before conversion
        updateIndex();

        // Convert GS LP tokens to CFMM LP tokens
        assets = convertToAssets(shares);
        if(assets == 0) revert ZeroAssets(); // revert if withdrawing 0 CFMM LP tokens

        // Revert if not enough CFMM LP tokens to withdraw
        if(assets > s.LP_TOKEN_BALANCE) revert ExcessiveWithdrawal();

        // Send CFMM LP tokens to receiver (`to`) and burn corresponding GS LP tokens from msg.sender
        withdrawAssets(msg.sender, to, from, assets, shares, false);
    }

    /// @dev Deposit CFMM LP tokens (`assets`) via transferFrom and mint corresponding GS LP tokens (`shares`) to receiver (`to`)
    /// @param caller - user address that requested to deposit CFMM LP tokens
    /// @param to - address receiving GS LP tokens (`shares`)
    /// @param assets - amount of CFMM LP tokens deposited
    /// @param shares - amount of GS LP tokens minted to receiver (`to`)
    function depositAssetsFrom(address caller, address to, uint256 assets, uint256 shares) internal virtual {
        // Transfer `assets` (CFMM LP tokens) from `caller` to GammaPool
        GammaSwapLibrary.safeTransferFrom(s.cfmm, caller, address(this), assets);

        // To prevent rounding errors, lock min shares in first deposit
        if(s.totalSupply == 0) {
            shares = shares - MIN_SHARES;
            assets = assets - MIN_SHARES;
            depositAssets(caller, address(0), MIN_SHARES, MIN_SHARES, false);
        }
        // Track CFMM LP tokens (`assets`) in GammaPool and mint GS LP tokens (`shares`) to receiver (`to`)
        depositAssets(caller, to, assets, shares, false);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "./ShortStrategyERC4626.sol";

/// @title Short Strategy Synchronization abstract contract
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Inherits all functions from ShortStrategy already defined by inheriting ShortStrategyERC4626
/// @dev Only defines function to synchronize LP_TOKEN_BALANCE (deposit without issuing shares)
abstract contract ShortStrategySync is ShortStrategyERC4626 {

    /// @dev See {IShortStrategy-_sync}.
    function _sync() external virtual override lock {
        // Do not sync if no first deposit yet
        if(s.totalSupply == 0) revert ZeroShares();

        // Update interest rate and state variables before conversion
        updateIndex();

        // Update CFMM LP token amount tracked by GammaPool and invariant in CFMM belonging to GammaPool
        uint256 lpTokenBalance = GammaSwapLibrary.balanceOf(s.cfmm, address(this));
        uint128 lpInvariant = uint128(convertLPToInvariant(lpTokenBalance, s.lastCFMMInvariant, s.lastCFMMTotalSupply));
        s.LP_TOKEN_BALANCE = lpTokenBalance;
        s.LP_INVARIANT = lpInvariant;

        emit PoolUpdated(lpTokenBalance, s.LP_TOKEN_BORROWED, s.LAST_BLOCK_NUMBER, s.accFeeIndex, s.LP_TOKEN_BORROWED_PLUS_INTEREST,
            lpInvariant, s.BORROWED_INVARIANT, s.CFMM_RESERVES, TX_TYPE.SYNC);
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

import "@gammaswap/v1-core/contracts/strategies/ShortStrategySync.sol";
import "../../interfaces/external/cpmm/ICPMM.sol";
import "./base/CPMMBaseStrategy.sol";

/// @title Short Strategy concrete implementation contract for Constant Product Market Maker
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Sets up variables used by ShortStrategy and defines internal functions specific to CPMM implementation
/// @dev This implementation was specifically designed to work with UniswapV2
contract CPMMShortStrategy is CPMMBaseStrategy, ShortStrategySync {

    error ZeroDeposits();
    error NotOptimalDeposit();
    error ZeroReserves();

    /// @dev Initializes the contract by setting `MAX_TOTAL_APY`, `BLOCKS_PER_YEAR`, `baseRate`, `optimalUtilRate`, `slope1`, and `slope2`
    constructor(uint256 maxTotalApy_, uint256 blocksPerYear_, uint64 baseRate_, uint64 optimalUtilRate_, uint64 slope1_, uint64 slope2_)
        CPMMBaseStrategy(maxTotalApy_, blocksPerYear_, baseRate_, optimalUtilRate_, slope1_, slope2_) {
    }

    /// @dev See {IShortStrategy-_getLatestCFMMReserves}.
    function _getLatestCFMMReserves(bytes memory _cfmm) public virtual override view returns(uint128[] memory reserves) {
        address cfmm_ = abi.decode(_cfmm, (address));
        reserves = new uint128[](2);
        reserves[0] = uint128(GammaSwapLibrary.balanceOf(ICPMM(cfmm_).token0(), cfmm_));
        reserves[1] = uint128(GammaSwapLibrary.balanceOf(ICPMM(cfmm_).token1(), cfmm_));
    }

    /// @dev See {IShortStrategy-_getLatestCFMMInvariant}.
    function _getLatestCFMMInvariant(bytes memory _cfmm) public virtual override view returns(uint256 cfmmInvariant) {
        uint128[] memory reserves = _getLatestCFMMReserves(_cfmm);
        cfmmInvariant = calcInvariant(address(0), reserves);
    }

    /// @dev See {IShortStrategy-calcDepositAmounts}.
    function calcDepositAmounts(uint256[] calldata amountsDesired, uint256[] calldata amountsMin) internal virtual
        override view returns (uint256[] memory amounts, address payee) {

        if(amountsDesired[0] == 0 || amountsDesired[1] == 0) revert ZeroDeposits(); // revert if not depositing anything

        (uint256 reserve0, uint256 reserve1,) = ICPMM(s.cfmm).getReserves();

        payee = s.cfmm; // deposit address is the CFMM

        // if first deposit deposit amounts desired
        if (reserve0 == 0 && reserve1 == 0) {
            return(amountsDesired, payee);
        }

        // revert if one side is zero
        if(reserve0 == 0 || reserve1 == 0) revert ZeroReserves();

        amounts = new uint256[](2);

        // calculate optimal amount1 to deposit if we deposit desired amount0
        uint256 optimalAmount1 = (amountsDesired[0] * reserve1) / reserve0;

        // if optimal amount1 <= desired proceed, else skip if block
        if (optimalAmount1 <= amountsDesired[1]) {
            // check optimal amount1 is greater than minimum deposit acceptable
            checkOptimalAmt(optimalAmount1, amountsMin[1]);
            (amounts[0], amounts[1]) = (amountsDesired[0], optimalAmount1);
            return(amounts, payee);
        }

        // calculate optimal amount0 to deposit if we deposit desired amount1
        uint256 optimalAmount0 = (amountsDesired[1] * reserve0) / reserve1;

        // if optimal amount0 <= desired proceed, else fail
        assert(optimalAmount0 <= amountsDesired[0]);

        // check that optimal amount0 is greater than minimum deposit acceptable
        checkOptimalAmt(optimalAmount0, amountsMin[0]);

        (amounts[0], amounts[1]) = (optimalAmount0, amountsDesired[1]);
    }

    /// @dev Check optimal deposit amount is not less than minimum acceptable deposit amount
    /// @param amountOptimal - optimal deposit amount
    /// @param amountMin - minimum deposit amount
    function checkOptimalAmt(uint256 amountOptimal, uint256 amountMin) internal virtual pure {
        if(amountOptimal < amountMin) revert NotOptimalDeposit();
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