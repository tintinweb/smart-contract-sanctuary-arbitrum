/**
 *Submitted for verification at Arbiscan on 2022-05-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// improvement suggestions :
// - switch to ERC1155
// - use an abstraction to support sub-collections, fungibles & ERC1155
// - use a red-black binary tree
// - optimize
// - use NFTs to represent positions
// - use custom errors
// - use wad or ray for valueToLoan
// - rename valueToLoan
// - use only singular for mappings
// - borrow less than full nft value
// - borrow from multiple markets at once
// - change Storage contract name to name not confusing with parameter type
// - create solhint plugin to disallow more than 100-lines files
// - allow callback on transfer (ofc strict reentrency checks to do)
// - add natspec to every func and contract
// - use ERC721's onERC721Received hook to auto borrow on transfer

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

interface ICEth {
    function mint() external payable;

    function redeemUnderlying(uint256) external returns (uint256);
}

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(
        address reserve,
        address rateStrategyAddress
    ) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider()
        external
        view
        returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

/// @notice config constants for Polypus
abstract contract Config {
    /// RINKEBY ///
    // ICEth internal constant CETH =
    //     ICEth(0xd6801a1DfFCd0a410336Ef88DeF4320D6DF1883e);
    /// MUMBAI ///
    uint16 internal constant NO_REFERRAL_CODE = 0;
    // ILendingPool internal constant AAVE_LENDING_POOL =
    //     ILendingPool(0x1758d4e6f68166C4B2d9d0F049F33dEB399Daa1F);
    // IWETH internal constant WMATIC =
    //     IWETH(0xb685400156cF3CBE8725958DeAA61436727A30c3);
    /// ARBITRUM ///
    ILendingPool internal constant AAVE_LENDING_POOL =
        ILendingPool(0x9C55a3C34de5fd46004Fa44a55490108f7cE388F);
    IWETH internal constant WETH =
        IWETH(0x5eb35Fe1f1074Ae8d6D23Bf771705846Cc812c09);
}

uint256 constant RAY = 1e27;
uint256 constant WAD = 1 ether;

/// @notice half of an order book, only loan offers
/// @notice made by suppliers for borrowers
/// @dev this is a double-linked list
struct OfferBook {
    bool isActive;
    mapping(uint256 => Offer) offer;
    uint256 firstId;
    uint256 numberOfOffers;
    mapping(address => uint256) offerIdOf;
    uint256 available;
    // mapping(address => BorrowerPosition) borrowerPositionOf;
}

/// @notice loan offer of `supplier`
struct Offer {
    bool isRemoved;
    uint256 amount;
    uint256 valueToLoan;
    uint256 nextId;
    uint256 prevId;
    address supplier;
}

/// @notice 27-decimals fixed-point number
/// @dev this struct must be used systematically to avoid confusions
struct Ray {
    uint256 ray;
}

/// @notice amount or valueToLoan is out of range
error valueOutOfRange();
error alreadyRemoved();
error removeNonExistentOffer();
error unavailableMarket();
error insertForExistentSupplier();
error etherTransferFailed();
error notEnoughLiquidityAvailable();

/// @notice Storage for Polypus protocol
abstract contract Storage {
    uint256 public numberOfBooks;
    uint256 public minimumDepositableValue;
    uint256 public minimumValueToLoan;
    uint256 public loanDuration;

    /// @dev asset (nft) => OfferBook
    mapping(IERC721 => OfferBook) public bookOf;

    constructor() {
        minimumDepositableValue = 1 ether / 100; // 0.01
        minimumValueToLoan = 0.005 ether;
        loanDuration = 2 weeks;
    }
}

library WadRayMath {
    function mul(Ray memory a, Ray memory b)
        internal
        pure
        returns (Ray memory)
    {
        return Ray({ray: (a.ray * b.ray) / RAY});
    }

    function div(Ray memory a, Ray memory b)
        internal
        pure
        returns (Ray memory)
    {
        return Ray({ray: (a.ray * RAY) / b.ray});
    }

    /// @notice returns a WAD
    function mulByWad(Ray memory a, uint256 b) internal pure returns (uint256) {
        return (a.ray * b) / RAY;
    }

    /// @notice is `a` less than `b`
    function lt(Ray memory a, Ray memory b) internal pure returns (bool) {
        return a.ray < b.ray;
    }

    /// @notice is `a` greater or equal to `b`
    function gte(Ray memory a, Ray memory b) internal pure returns (bool) {
        return a.ray >= b.ray;
    }

    function divWadByRay(uint256 a, Ray memory b)
        internal
        pure
        returns (Ray memory)
    {
        return Ray({ray: (a * (RAY * RAY)) / (b.ray * WAD)});
    }

    function divToRay(uint256 a, uint256 b) internal pure returns (Ray memory) {
        return Ray({ray: (a * RAY) / b});
    }
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// compiler doesn't allow visibility on free functions
/* solhint-disable func-visibility */

/// @notice places the offer in the book sorted from best to worst offer
function insertLogic(
    OfferBook storage book,
    uint256 amount,
    uint256 valueToLoan
) returns (uint256 newId) {
    uint256 firstId = book.firstId;
    uint256 cursor = firstId;
    newId = ++book.numberOfOffers; // id 0 is reserved to null
    book.offer[newId].amount = amount;
    book.offer[newId].valueToLoan = valueToLoan;
    uint256 prevId = cursor;

    while (book.offer[cursor].valueToLoan >= valueToLoan) {
        prevId = cursor;
        cursor = book.offer[cursor].nextId;
    }
    if (cursor == firstId) {
        insertAsFirst(book, newId, cursor);
    } else {
        insertBetween(book, newId, prevId, cursor);
    }
}

/// @notice inserts the id as the best offer in the book
function insertAsFirst(
    OfferBook storage book,
    uint256 newId,
    uint256 nextId
) {
    book.firstId = newId;
    book.offer[newId].nextId = nextId;
    if (nextId != 0) {
        book.offer[nextId].prevId = newId;
    }
}

/// @notice inserts `newId` between `prevId` and `nextId`
function insertBetween(
    OfferBook storage book,
    uint256 newId,
    uint256 prevId,
    uint256 nextId
) {
    if (nextId != 0) {
        book.offer[nextId].prevId = newId;
    }
    book.offer[newId].nextId = nextId;
    book.offer[newId].prevId = prevId;
    book.offer[prevId].nextId = newId;
}

/* solhint-disable func-visibility */

library OfferBookLib {
    /// @return newId the id of the newly created offer
    /// @dev amount and valueToLoan must have been checked before calling
    /// @dev amount and valueToLoan must both be above 0
    function insert(
        OfferBook storage book,
        uint256 amount,
        uint256 valueToLoan,
        address supplier
    ) external returns (uint256 newId) {
        if (amount == 0 || valueToLoan == 0) {
            revert valueOutOfRange();
        }
        if (book.offerIdOf[supplier] != 0) {
            revert insertForExistentSupplier();
        }

        newId = insertLogic(book, amount, valueToLoan);
        book.offer[newId].supplier = supplier;
        book.available += amount;
    }

    /// @notice removes the offer from the book
    function remove(OfferBook storage book, uint256 offerId) external {
        if (offerId > book.numberOfOffers) {
            revert removeNonExistentOffer();
        }
        if (book.offer[offerId].isRemoved) {
            revert alreadyRemoved();
        }

        book.offer[offerId].isRemoved = true;
        book.offerIdOf[book.offer[offerId].supplier] = 0;
        uint256 nextId = book.offer[offerId].nextId;
        uint256 prevId = book.offer[offerId].prevId;

        if (offerId == book.firstId) {
            book.firstId = nextId;
        }
        if (prevId != 0) {
            book.offer[prevId].nextId = nextId;
        }
        if (nextId != 0) {
            book.offer[nextId].prevId = prevId;
        }

        book.available -= book.offer[offerId].amount;
    }

    /// @notice changes the amount of an update, considers it as a new offer
    /// @dev as ordering depends on valueToLoan only,
    /// @dev it doesn't need to be redone
    function updateAmount(
        OfferBook storage book,
        uint256 newAmount,
        uint256 id
    ) external {
        uint256 newId = ++book.numberOfOffers;

        book.offer[newId] = book.offer[id];
        book.offer[id].isRemoved = true;
        book.offer[newId].amount = newAmount;
        book.offer[book.offer[id].prevId].nextId = newId;
        book.offer[book.offer[id].nextId].prevId = newId;
        book.available = book.available - book.offer[id].amount + newAmount;
    }
}

/// @notice all variables needed for the borrow function logic
struct BorrowVars {
    Offer cursor;
    uint256 cursorId;
    Ray collateralToMatch;
    Ray offerValueInAsset;
    uint256 borrowedAmount;
}

/// @notice internal bits of logic for the borrow user interaction
abstract contract BorrowLogic is ERC721Holder, Config {
    using WadRayMath for uint256;
    using WadRayMath for Ray;
    using OfferBookLib for OfferBook;

    /// @notice updates the book and the vars to partially match remaining
    /// @notice assets with the best offer
    function matchAndUpdateOffer(OfferBook storage book, BorrowVars memory vars)
        internal
        returns (BorrowVars memory finalVars)
    {
        uint256 amountTakenFromOffer = vars.offerValueInAsset.mulByWad(
            vars.cursor.amount
        );
        finalVars.borrowedAmount = vars.borrowedAmount + amountTakenFromOffer;
        finalVars.cursor.amount = vars.cursor.amount - amountTakenFromOffer;
        book.updateAmount(finalVars.cursor.amount, vars.cursorId);
        finalVars.collateralToMatch.ray = 0;
    }

    /// @notice transfers the assets from the caller to the contract
    /// @dev caller must have approved the contract
    function takeAssets(IERC721 asset, uint256[] calldata tokenIds) internal {
        for (uint256 i; i < tokenIds.length; i++) {
            asset.transferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    /// @notice checks that the market is active and takes the collateral
    function performPreChecks(
        OfferBook storage book,
        IERC721 asset,
        uint256[] calldata tokenIds
    ) internal {
        if (!book.isActive) {
            revert unavailableMarket();
        }

        takeAssets(asset, tokenIds);
    }

    /// @notice sends ETH to caller that is sitting in compound
    function sendEth(uint256 amount) internal {
        /// ETHEREUM ///
        // CETH.redeemUnderlying(amount);

        /// POLYGON ///
        AAVE_LENDING_POOL.withdraw(address(WETH), amount, address(this));
        WETH.withdraw(amount);
        payable(msg.sender).transfer(amount);
    }

    /// @notice update borrowVars with the new best offer available
    function updateVars(OfferBook storage book, BorrowVars memory vars)
        internal
        view
        returns (BorrowVars memory)
    {
        Offer memory newCursor = book.offer[book.firstId];
        BorrowVars memory newVars = BorrowVars({
            cursor: newCursor,
            cursorId: book.firstId,
            collateralToMatch: vars.collateralToMatch,
            offerValueInAsset: newCursor.amount.divToRay(newCursor.valueToLoan),
            borrowedAmount: vars.borrowedAmount
        });
        return newVars;
    }
}

/// @notice getters for external queries of Polypus internal state
abstract contract Lens is Storage {
    function getOffer(IERC721 asset, uint256 offerId)
        external
        view
        returns (Offer memory)
    {
        return bookOf[asset].offer[offerId];
    }

    function getOfferIdOf(IERC721 asset, address supplier)
        external
        view
        returns (uint256)
    {
        return bookOf[asset].offerIdOf[supplier];
    }
}

/// @notice all entry points of the Polypus protocol
contract Polypus is Storage, Ownable, BorrowLogic, Lens {
    using OfferBookLib for OfferBook;
    using WadRayMath for Ray;
    using WadRayMath for uint256;

    /// ADMIN ///

    /// @notice makes an asset available on the market
    function createMarket(IERC721 asset) external onlyOwner {
        bookOf[asset].isActive = true;
    }

    /// PUBLIC ///

    /// @notice supplies to given market with given value to loan.
    /// @notice updates value to loan and adds the new liquidity.
    function supply(IERC721 asset, uint256 valueToLoan) external payable {
        OfferBook storage book = bookOf[asset];

        supplyChecks(asset, valueToLoan);

        uint256 alreadySupplied;
        uint256 prevOfferId = book.offerIdOf[msg.sender];

        if (prevOfferId != 0) {
            alreadySupplied = book.offer[prevOfferId].amount;
            if (msg.value + alreadySupplied < minimumDepositableValue) {
                revert valueOutOfRange();
            }
            book.remove(prevOfferId);
        } else if (msg.value < minimumDepositableValue) {
            revert valueOutOfRange();
        }

        book.offerIdOf[msg.sender] = book.insert(
            msg.value + alreadySupplied,
            valueToLoan,
            msg.sender
        );
    }

    /// @notice takes assets as collateral and gives
    /// @notice the maximum amount loanable to the caller
    function borrow(IERC721 asset, uint256[] calldata tokenIds)
        external
        returns (uint256)
    {
        OfferBook storage book = bookOf[asset];

        performPreChecks(book, asset, tokenIds);
        BorrowVars memory vars;
        vars.collateralToMatch = Ray({ray: tokenIds.length * RAY});
        do {
            vars = updateVars(book, vars);
            if (vars.cursorId == 0) {
                // reached the end
                revert notEnoughLiquidityAvailable();
            }
            if (vars.collateralToMatch.gte(vars.offerValueInAsset)) {
                book.remove(vars.cursorId);
                vars.collateralToMatch.ray -= vars.offerValueInAsset.ray;
                vars.borrowedAmount += vars.cursor.amount;
            } else {
                // entering this block ends the while loop
                vars = matchAndUpdateOffer(book, vars);
            }
        } while (vars.collateralToMatch.ray > 0);
        sendEth(vars.borrowedAmount);
        return vars.borrowedAmount;
    }

    /// @notice performs initial checks for the supply function
    function supplyChecks(IERC721 asset, uint256 valueToLoan) private {
        OfferBook storage book = bookOf[asset];

        if (valueToLoan < minimumValueToLoan) {
            revert valueOutOfRange();
        }
        if (!book.isActive) {
            revert unavailableMarket();
        }

        /// ETHEREUM ///
        // CETH.mint{value: msg.value}();

        /// POLYGON & ARBITRUM ///
        WETH.deposit{value: msg.value}();
        WETH.approve(address(AAVE_LENDING_POOL), msg.value);
        AAVE_LENDING_POOL.supply(
            address(WETH),
            msg.value,
            address(this),
            NO_REFERRAL_CODE
        );
    }
}