//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
/**                                                                                                 
          █████╗ ████████╗██╗      █████╗ ███╗   ██╗████████╗██╗ ██████╗
          ██╔══██╗╚══██╔══╝██║     ██╔══██╗████╗  ██║╚══██╔══╝██║██╔════╝
          ███████║   ██║   ██║     ███████║██╔██╗ ██║   ██║   ██║██║     
          ██╔══██║   ██║   ██║     ██╔══██║██║╚██╗██║   ██║   ██║██║     
          ██║  ██║   ██║   ███████╗██║  ██║██║ ╚████║   ██║   ██║╚██████╗
          ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝ ╚═════╝
                                                                        
          ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗       
          ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝       
          ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗       
          ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║       
          ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║       
          ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝       
                                                               
*/

// Libraries
import {SafeERC20} from "../libraries/SafeERC20.sol";

// Contracts
import {ContractWhitelist} from "../helpers/ContractWhitelist.sol";
import {ReentrancyGuard} from "../helpers/ReentrancyGuard.sol";
import {StructuredLinkedList} from "solidity-linked-list/contracts/StructuredLinkedList.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "../helpers/Pausable.sol";
import {StructuredLinkedList} from "solidity-linked-list/contracts/StructuredLinkedList.sol";

// Interfaces
import {IERC20} from "../interfaces/IERC20.sol";
import {IOptionPricing} from "../interfaces/IOptionPricing.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {IVolatilityOracle} from "../interfaces/IVolatilityOracle.sol";
import {IOptionPricing} from "../interfaces/IOptionPricing.sol";
import {IDopexFeeStrategy} from "../fees/interfaces/IDopexFeeStrategy.sol";

// Structs
import {VaultState, Addresses, OptionsPurchase, DepositPosition, Checkpoint} from "./AtlanticsStructs.sol";

contract AtlanticPutsPool is
    Pausable,
    ReentrancyGuard,
    AccessControl,
    ContractWhitelist
{
    using SafeERC20 for IERC20;
    using StructuredLinkedList for StructuredLinkedList.List;

    uint256 private constant PURCHASE_FEES_KEY = 0;
    uint256 private constant FUNDING_FEES_KEY = 1;
    uint256 private constant SETTLEMENT_FEES_KEY = 2;
    uint256 private constant FEE_BPS_PRECISION = 10000000;

    /// @dev Number of deicmals of deposit/premium token
    uint256 private immutable COLLATERAL_TOKEN_DECIMALS;

    /// @dev Options amounts precision
    uint256 private constant OPTION_TOKEN_DECIMALS = 18;

    /// @dev Number of decimals for max strikes
    uint256 private constant STRIKE_DECIMALS = 8;

    /// @dev Max strike weights divisor/multiplier
    uint256 private constant WEIGHTS_MUL_DIV = 1e18;

    /// @dev Manager role which handles bootstrapping
    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @notice Ongoing epoch of the pool
    uint256 public currentEpoch;

    /// @notice Counter for deposit IDs
    uint256 public depositIdCount = 1;

    /// @notice Counter for option purchase IDs
    uint256 public purchaseIdCount = 1;

    /// @notice Track deposit positions of users
    /// @dev ID => DepositPosition
    mapping(uint256 => DepositPosition) private userDepositPositions;

    /// @notice Track option purchases of users
    /// @dev ID => OptionsPurchase
    mapping(uint256 => OptionsPurchase) private userOptionsPurchases;

    /// @dev epoch => vaultState
    mapping(uint256 => VaultState) public epochVaultStates;

    /// @notice Addresses this contract uses
    Addresses public addresses;

    /**
     * @notice Mapping of max strikes to MaxStrike struct
     * @dev    epoch => strike/node => MaxStrike
     */
    mapping(uint256 => mapping(uint256 => bool)) private isValidStrike;

    /**
     * @notice Mapping to keep track of managed contracts
     * @dev    Contract address => is managed contract?
     */
    mapping(address => bool) public managedContracts;

    /**
     * @notice Total liquidity in a epoch
     * @dev    epoch => liquidity
     */
    mapping(uint256 => uint256) public totalEpochCummulativeLiquidity;

    /**
     * @notice Structured linked list for max strikes
     * @dev    epoch => strike list
     */
    mapping(uint256 => StructuredLinkedList.List) private epochStrikesList;

    /**
     * @notice Checkpoints for a max strike in a epoch
     * @dev    epoch => max strike => Checkpoint[]
     */
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Checkpoint)))
        public epochMaxStrikeCheckpoints;

    mapping(uint256 => mapping(uint256 => uint256))
        public epochMaxStrikeCheckpointsLength;

    uint256 public expireDelayTolerance;

    /**
     *  @notice Start index of checkpoint (reference point to
     *           loop from on _squeeze())
     *  @dev    epoch => index
     */
    mapping(uint256 => mapping(uint256 => uint256))
        public epochMaxStrikeCheckpointStartIndex;

    mapping(uint256 => uint256[2]) public epochMaxStrikesRange;

    mapping(uint256 => uint256) public epochTickSize;

    mapping(address => bool) public whitelistedUsers;

    uint256 public expiryWindow = 1 hours;

    uint256 public fundingInterval;

    bool public isWhitelistUserMode = true;

    bool public useDiscountForFees = true;

    error AtlanticPutsPoolError(uint256 errorCode);

    /*==== EVENTS ====*/

    event ExpireDelayToleranceUpdate(uint256 expireDelayTolerance);

    event EmergencyWithdraw(address sender);

    event Bootstrap(uint256 epoch);

    event NewDeposit(
        uint256 epoch,
        uint256 strike,
        uint256 amount,
        address user,
        address sender
    );

    event NewPurchase(
        uint256 epoch,
        uint256 purchaseId,
        uint256 premium,
        uint256 fee,
        address user,
        address sender
    );

    event NewWithdraw(
        uint256 epoch,
        uint256 strike,
        uint256 checkpoint,
        address user,
        uint256 withdrawableAmount,
        uint256 borrowFees,
        uint256 premium,
        uint256 underlying
    );

    event Unwind(uint256 epoch, uint256 strike, uint256 amount, address caller);

    event UnlockCollateral(
        uint256 epoch,
        uint256 totalCollateral,
        address caller
    );

    event NewSettle(
        uint256 epoch,
        uint256 strike,
        address user,
        uint256 amount,
        uint256 pnl
    );

    event RelockCollateral(
        uint256 epoch,
        uint256 strike,
        uint256 totalCollateral,
        address caller
    );

    event EpochExpired(address sender, uint256 settlementPrice);

    event FundingIntervalSet(uint256 _interval);

    event ManagedContractSet(address _managedContract, bool _setAs);

    event UseDiscountForFeesSet(bool _setAs);

    /*==== CONSTRUCTOR ====*/

    constructor(
        Addresses memory _addresses,
        uint256 _expiryDelayTolerance,
        uint256 _fundingInterval
    ) {
        COLLATERAL_TOKEN_DECIMALS = IERC20(_addresses.quoteToken).decimals();
        addresses = _addresses;
        expireDelayTolerance = _expiryDelayTolerance;
        fundingInterval = _fundingInterval;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    /// @notice Sets the current epoch as expired.
    function expireEpoch() external nonReentrant {
        _whenNotPaused();
        _isEligibleSender();
        _validate(!epochVaultStates[currentEpoch].isVaultExpired, 0);
        uint256 epochExpiry = epochVaultStates[currentEpoch].expiryTime;
        _validate((block.timestamp >= epochExpiry), 1);
        _validate(block.timestamp <= epochExpiry + expireDelayTolerance, 2);
        epochVaultStates[currentEpoch].settlementPrice = getUsdPrice();
        epochVaultStates[currentEpoch].isVaultExpired = true;

        emit EpochExpired(msg.sender, getUsdPrice());
    }

    /// @notice Sets the current epoch as expired. Only can be called by DEFAULT_ADMIN_ROLE.
    /// @param settlementPrice The settlement price
    function expireEpoch(
        uint256 settlementPrice
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _whenNotPaused();
        uint256 epoch = currentEpoch;
        _validate(!epochVaultStates[epoch].isVaultExpired, 0);
        _validate(
            (block.timestamp >
                epochVaultStates[epoch].expiryTime + expireDelayTolerance),
            3
        );
        epochVaultStates[epoch].settlementPrice = settlementPrice;
        epochVaultStates[epoch].isVaultExpired = true;

        emit EpochExpired(msg.sender, settlementPrice);
    }

    /*==== SETTER METHODS ====*/

    /// @notice Pauses the vault for emergency cases
    /// @dev Can only be called by the owner
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the vault
    /// @dev Can only be called by the owner
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Add a contract to the whitelist
    /// @dev Can only be called by the owner
    /// @param _contract Address of the contract that needs to be added to the whitelist
    function addToContractWhitelist(
        address _contract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addToContractWhitelist(_contract);
    }

    /// @notice Remove a contract to the whitelist
    /// @dev Can only be called by the owner
    /// @param _contract Address of the contract that needs to be removed from the whitelist
    function removeFromContractWhitelist(
        address _contract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeFromContractWhitelist(_contract);
    }

    /// @notice Updates the delay tolerance for the expiry epoch function
    /// @dev Can only be called by the owner
    function updateExpireDelayTolerance(
        uint256 _expireDelayTolerance
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        expireDelayTolerance = _expireDelayTolerance;
        emit ExpireDelayToleranceUpdate(_expireDelayTolerance);
    }

    /// @notice Sets (adds) a list of addresses to the address list
    /// @dev Can only be called by the owner
    /// @param _addresses addresses of contracts in the Addresses struct
    function setAddresses(
        Addresses calldata _addresses
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        addresses = _addresses;
    }

    /// @notice Add a managed contract
    /// @param _managedContract Address of the managed contract
    function setManagedContract(
        address _managedContract,
        bool _setAs
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        managedContracts[_managedContract] = _setAs;
        emit ManagedContractSet(_managedContract, _setAs);
    }

    /// @notice Set interval for funding charged.
    /// @param _interval Interval to set. Note: Max 1 day
    function setFundingInterval(
        uint256 _interval
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _validate(_interval <= 1 days, 24);
        fundingInterval = _interval;
        emit FundingIntervalSet(_interval);
    }

    // /*==== METHODS ====*/

    /// @notice Transfers all funds to msg.sender
    /// @dev Can only be called by DEFAULT_ADMIN_ROLE
    /// @param tokens The list of erc20 tokens to withdraw
    /// @param transferNative Whether should transfer the native currency
    function emergencyWithdraw(
        address[] calldata tokens,
        bool transferNative
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        _whenPaused();
        if (transferNative) payable(msg.sender).transfer(address(this).balance);

        for (uint256 i; i < tokens.length; ) {
            IERC20 token = IERC20(tokens[i]);
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
            unchecked {
                ++i;
            }
        }

        emit EmergencyWithdraw(msg.sender);

        return true;
    }

    /**
     * @notice Create a deposit position instance and update ID counter
     * @param _epoch      `Epoch of the pool
     * @param _liquidity  Amount of collateral token deposited
     * @param _maxStrike  Max strike deposited into
     * @param _checkpoint Checkpoint of the max strike deposited into
     * @param _user       Address of the user to deposit for / is depositing
     */
    function _newDepositPosition(
        uint256 _epoch,
        uint256 _liquidity,
        uint256 _maxStrike,
        uint256 _checkpoint,
        address _user
    ) internal returns (uint256 depositId) {
        depositId = depositIdCount;
        userDepositPositions[depositId] = DepositPosition(
            _epoch,
            _maxStrike,
            block.timestamp,
            _liquidity,
            _checkpoint,
            _user
        );
        unchecked {
            ++depositIdCount;
        }
    }

    /**
     * @notice Deposits USD into the ssov-p to mint puts in the next epoch for selected strikes
     * @param _maxStrike Exact price of strike in 1e8 decimals
     * @param _liquidity Amount of liquidity to provide in 1e6 decimals
     * @param _user      Address of the user to deposit for
     */
    function deposit(
        uint256 _maxStrike,
        uint256 _liquidity,
        address _user
    ) external nonReentrant whitelistCheck returns (uint256 depositId) {
        _isEligibleSender();
        _whenNotPaused();
        _validate(_maxStrike <= getUsdPrice(), 4);

        uint256 epoch = currentEpoch;

        _validate(_isVaultReady(epoch), 5);
        _validate(_liquidity > 0, 6);
        _validate(_isValidMaxStrike(_maxStrike, epoch), 7);

        uint256 checkpoint = _updateCheckpoint(epoch, _maxStrike, _liquidity);
        depositId = _newDepositPosition(
            epoch,
            _liquidity,
            _maxStrike,
            checkpoint,
            _user
        );

        _safeTransferFrom(
            addresses.quoteToken,
            msg.sender,
            address(this),
            _liquidity
        );

        totalEpochCummulativeLiquidity[epoch] += _liquidity;

        // Add `maxStrike` if it doesn't exist
        if (!isValidStrike[epoch][_maxStrike]) {
            _addMaxStrike(_maxStrike, epoch);
            isValidStrike[epoch][_maxStrike] = true;
        }

        // Emit event
        emit NewDeposit(epoch, _maxStrike, _liquidity, _user, msg.sender);
    }

    /**
     * @notice Purchases puts for the current epoch
     * @param _strike    Strike index for current epoch
     * @param _amount    Amount of puts to purchase
     * @param _receiver      Address to which options would belong to.
     * @param _account   Address of the user options were purchased
     *                   on behalf of.
     */
    function purchase(
        uint256 _strike,
        uint256 _amount,
        address _receiver,
        address _account
    ) external payable nonReentrant returns (uint256 purchaseId) {
        _whenNotPaused();
        _isManagedContract();
        _validate(_amount > 0, 8);

        uint256 epoch = currentEpoch;

        _validate(_isValidMaxStrike(_strike, epoch), 7);
        _validate(_isVaultReady(epoch), 5);
        _validate(_strike <= epochMaxStrikesRange[epoch][0], 9);

        // Calculate liquidity required
        uint256 collateralRequired = strikeMulAmount(_strike, _amount);

        // Should have adequate cumulative liquidity
        _validate(
            totalEpochCummulativeLiquidity[epoch] >= collateralRequired,
            10
        );

        // Price/premium of option
        uint256 premium = calculatePremium(_strike, _amount);

        // Fees on top of premium for fee distributor
        uint256 fees = calculatePurchaseFees(_account, _strike, _amount);

        purchaseId = _squeezeMaxStrikes(
            epoch,
            _strike,
            collateralRequired,
            _amount,
            premium,
            _receiver
        );

        totalEpochCummulativeLiquidity[epoch] -= collateralRequired;

        _safeTransferFrom(
            addresses.quoteToken,
            msg.sender,
            address(this),
            premium
        );
        _safeTransferFrom(
            addresses.quoteToken,
            msg.sender,
            addresses.feeDistributor,
            fees
        );

        emit NewPurchase(
            epoch,
            purchaseId,
            premium,
            fees,
            _receiver,
            msg.sender
        );
    }

    function _newPurchasePosition(
        address _user,
        uint256 _putStrike,
        uint256 _amount,
        uint256 _epoch
    ) internal returns (uint256 purchaseId) {
        purchaseId = purchaseIdCount;
        userOptionsPurchases[purchaseId].user = _user;
        userOptionsPurchases[purchaseId].optionStrike = _putStrike;
        userOptionsPurchases[purchaseId].optionsAmount = _amount;
        userOptionsPurchases[purchaseId].epoch = _epoch;
        unchecked {
            ++purchaseIdCount;
        }
    }

    /**
     * @notice Loop through max strike looking for liquidity
     * @param epoch              Epoch of the pool
     * @param putStrike          Strike to purchase
     * @param collateralRequired Amount of collateral to squeeze from max strike
     * @param amount             Amount of options to buy
     * @param premium            Amount of premium to distribute
     * @param user               Address of the user purchasing
     */
    function _squeezeMaxStrikes(
        uint256 epoch,
        uint256 putStrike,
        uint256 collateralRequired,
        uint256 amount,
        uint256 premium,
        address user
    ) internal returns (uint256 purchaseId) {
        uint256 liquidityFromMaxStrikes;
        uint256 liquidityProvided;
        uint256 nextStrike = epochMaxStrikesRange[epoch][0];
        uint256 _liquidityRequired;

        purchaseId = _newPurchasePosition(user, putStrike, amount, epoch);

        while (liquidityFromMaxStrikes != collateralRequired) {
            // Unchecked because liquidityProvided from _squeeze max strikes
            // will either be equal or less than collateral required
            unchecked {
                _liquidityRequired =
                    collateralRequired -
                    liquidityFromMaxStrikes;
            }

            _validate(putStrike <= nextStrike, 22);

            liquidityProvided = _squeezeMaxStrikeCheckpoints(
                epoch,
                nextStrike,
                collateralRequired,
                _liquidityRequired,
                premium,
                purchaseId
            );
            unchecked {
                liquidityFromMaxStrikes += liquidityProvided;
            }

            (, nextStrike) = epochStrikesList[epoch].getNextNode(nextStrike);
        }
    }

    /**
     * @notice Pushes new item into strikes, checkpoints and weights in a single-go.
     *         of a options purchase instance
     * @param _purchaseId Options purchase ID
     * @param _maxStrike  Maxstrike to push into strikes array of the options purchase
     * @param _checkpoint Checkpoint to push into checkpoints array of the options purchase
     * @param _weight     Weight (%) to push into weights array of the options purchase
     */
    function _updatePurchasePositionMaxStrikesLiquidity(
        uint256 _purchaseId,
        uint256 _maxStrike,
        uint256 _checkpoint,
        uint256 _weight
    ) internal {
        userOptionsPurchases[_purchaseId].strikes.push(_maxStrike);
        userOptionsPurchases[_purchaseId].checkpoints.push(_checkpoint);
        userOptionsPurchases[_purchaseId].weights.push(_weight);
    }

    /**
     * @notice Squeezes out liquidity from checkpoints within each max strike
     * @param epoch                    Epoch of the pool
     * @param maxStrike                Max strike to squeeze liquidity from
     * @param totalCollateralRequired  Total amount of liquidity required for the option purchase
     * @param collateralRequired       As the loop _squeezeMaxStrikes() accumulates liquidity, this value deducts
     *                                 liquidity is accumulated. collateralRequired = totalCollateralRequired - liquidity
     *                                 accumulated till the max strike in the context of the loop
     * @param premium                  Premium to distribute among the checkpoints and maxstrike
     * @param purchaseId               Options purchase ID
     */
    function _squeezeMaxStrikeCheckpoints(
        uint256 epoch,
        uint256 maxStrike,
        uint256 totalCollateralRequired,
        uint256 collateralRequired,
        uint256 premium,
        uint256 purchaseId
    ) internal returns (uint256 liquidityProvided) {
        uint256 startIndex = epochMaxStrikeCheckpointStartIndex[epoch][
            maxStrike
        ];
        //check if previous checkpoint liquidity all consumed
        if (
            startIndex > 0 &&
            epochMaxStrikeCheckpoints[epoch][maxStrike][startIndex - 1]
                .totalLiquidity >
            epochMaxStrikeCheckpoints[epoch][maxStrike][startIndex - 1]
                .activeCollateral
        ) {
            unchecked {
                --startIndex;
            }
        }
        uint256 endIndex;
        // Unchecked since only max strikes with checkpoints > 0 will come to this point
        unchecked {
            endIndex = epochMaxStrikeCheckpointsLength[epoch][maxStrike] - 1;
        }
        uint256 liquidityProvidedFromCurrentMaxStrike;

        while (
            startIndex <= endIndex && liquidityProvided != collateralRequired
        ) {
            uint256 availableLiquidity = epochMaxStrikeCheckpoints[epoch][
                maxStrike
            ][startIndex].totalLiquidity -
                epochMaxStrikeCheckpoints[epoch][maxStrike][startIndex]
                    .activeCollateral;

            uint256 _requiredLiquidity = collateralRequired - liquidityProvided;

            /// @dev if checkpoint has more than required liquidity
            if (availableLiquidity >= _requiredLiquidity) {
                /// @dev Liquidity provided from current max strike at current index
                unchecked {
                    liquidityProvidedFromCurrentMaxStrike = _requiredLiquidity;
                    liquidityProvided += liquidityProvidedFromCurrentMaxStrike;

                    /// @dev Add to active collateral, later if activeCollateral == totalliquidity, then we stop
                    //  coming back to this checkpoint
                    epochMaxStrikeCheckpoints[epoch][maxStrike][startIndex]
                        .activeCollateral += _requiredLiquidity;

                    /// @dev Add to premium accured
                    epochMaxStrikeCheckpoints[epoch][maxStrike][startIndex]
                        .premiumAccrued +=
                        (liquidityProvidedFromCurrentMaxStrike * premium) /
                        totalCollateralRequired;
                }

                _updatePurchasePositionMaxStrikesLiquidity(
                    purchaseId,
                    maxStrike,
                    startIndex,
                    (liquidityProvidedFromCurrentMaxStrike * WEIGHTS_MUL_DIV) /
                        totalCollateralRequired
                );
            } else if (availableLiquidity != 0) {
                /// @dev if checkpoint has less than required liquidity
                liquidityProvidedFromCurrentMaxStrike = availableLiquidity;
                unchecked {
                    liquidityProvided += liquidityProvidedFromCurrentMaxStrike;

                    epochMaxStrikeCheckpoints[epoch][maxStrike][startIndex]
                        .activeCollateral += liquidityProvided;

                    /// @dev Add to premium accured
                    epochMaxStrikeCheckpoints[epoch][maxStrike][startIndex]
                        .premiumAccrued +=
                        (liquidityProvidedFromCurrentMaxStrike * premium) /
                        totalCollateralRequired;
                }

                _updatePurchasePositionMaxStrikesLiquidity(
                    purchaseId,
                    maxStrike,
                    startIndex,
                    (liquidityProvidedFromCurrentMaxStrike * WEIGHTS_MUL_DIV) /
                        totalCollateralRequired
                );
                unchecked {
                    ++epochMaxStrikeCheckpointStartIndex[epoch][maxStrike];
                }
            }
            unchecked {
                ++startIndex;
            }
        }
    }

    /**
     * @notice Unlock collateral to borrow against AP option. Only Callable by managed contracts
     * @param  purchaseId        User options purchase ID
     * @param  to                Collateral to transfer to
     * @return unlockedCollateral Amount of collateral unlocked plus fees
     */
    function unlockCollateral(
        uint256 purchaseId,
        address to,
        address account
    ) external nonReentrant returns (uint256 unlockedCollateral) {
        _isEligibleSender();
        _whenNotPaused();

        _validate(_isVaultReady(currentEpoch), 5);

        OptionsPurchase memory _userOptionsPurchase = userOptionsPurchases[
            purchaseId
        ];

        unlockedCollateral = strikeMulAmount(
            _userOptionsPurchase.optionStrike,
            _userOptionsPurchase.optionsAmount
        );

        _validate(_userOptionsPurchase.user == msg.sender, 12);
        _validate(!_userOptionsPurchase.unlock, 16);

        _userOptionsPurchase.unlock = true;

        uint256 borrowFees = calculateFundingFees(account, unlockedCollateral);

        for (uint256 i; i < _userOptionsPurchase.strikes.length; ) {
            _unlockCollateral(
                _userOptionsPurchase.epoch,
                _userOptionsPurchase.strikes[i],
                /**
                 *     contribution% * collateral access
                 */
                (_userOptionsPurchase.weights[i] * unlockedCollateral) /
                    WEIGHTS_MUL_DIV,
                (_userOptionsPurchase.weights[i] * borrowFees) /
                    WEIGHTS_MUL_DIV,
                _userOptionsPurchase.checkpoints[i]
            );

            unchecked {
                ++i;
            }
        }

        userOptionsPurchases[purchaseId] = _userOptionsPurchase;

        /// @dev Transfer out collateral
        _safeTransfer(addresses.quoteToken, to, unlockedCollateral);
        _safeTransferFrom(
            addresses.quoteToken,
            msg.sender,
            address(this),
            borrowFees
        );
    }

    /**
     * @notice Helper function for unlockCollateral()
     * @param epoch            epoch of the vault
     * @param maxStrike        Max strike to unlock collateral from
     * @param collateralAmount Amount of collateral to unlock
     * @param _checkpoint      Checkpoint of the max strike.
     */
    function _unlockCollateral(
        uint256 epoch,
        uint256 maxStrike,
        uint256 collateralAmount,
        uint256 borrowFees,
        uint256 _checkpoint
    ) internal {
        unchecked {
            epochMaxStrikeCheckpoints[epoch][maxStrike][_checkpoint]
                .unlockedCollateral += collateralAmount;

            epochMaxStrikeCheckpoints[epoch][maxStrike][_checkpoint]
                .fundingFeesAccrued += borrowFees;
        }

        epochMaxStrikeCheckpoints[epoch][maxStrike][_checkpoint]
            .totalLiquidityBalance -= collateralAmount;

        emit UnlockCollateral(epoch, collateralAmount, msg.sender);
    }

    /**
     * @notice Callable by managed contracts that wish to relock collateral that was unlocked previously
     * @param purchaseId          User options purchase id
     * @param collateralToCollect Amount of collateral to repay in collateral token decimals
     */
    function relockCollateral(
        uint256 purchaseId
    ) external returns (uint256 collateralToCollect) {
        _isEligibleSender();
        _whenNotPaused();

        _validate(_isVaultReady(currentEpoch), 5);
        OptionsPurchase memory _userOptionsPurchase = userOptionsPurchases[
            purchaseId
        ];

        _validate(_userOptionsPurchase.user == msg.sender, 23);
        _validate(_userOptionsPurchase.unlock, 17);

        collateralToCollect = strikeMulAmount(
            _userOptionsPurchase.optionStrike,
            _userOptionsPurchase.optionsAmount
        );

        for (uint256 i; i < _userOptionsPurchase.strikes.length; ) {
            _relockCollateral(
                _userOptionsPurchase.epoch,
                _userOptionsPurchase.strikes[i],
                ((collateralToCollect * _userOptionsPurchase.weights[i]) /
                    WEIGHTS_MUL_DIV),
                _userOptionsPurchase.checkpoints[i]
            );

            unchecked {
                ++i;
            }
        }

        delete userOptionsPurchases[purchaseId].unlock;

        _safeTransferFrom(
            addresses.quoteToken,
            msg.sender,
            address(this),
            collateralToCollect
        );
    }

    /**
     * @notice Update checkpoint states and total unlocked collateral for a max strike
     * @param epoch            Epoch of the pool
     * @param maxStrike        maxStrike to update states for
     * @param collateralAmount Collateral token amount relocked
     * @param checkpoint       Checkpoint pointer to update
     */
    function _relockCollateral(
        uint256 epoch,
        uint256 maxStrike,
        uint256 collateralAmount,
        uint256 checkpoint
    ) internal {
        // Unchecked since collateral relocked cannot be collateral unlocked
        unchecked {
            epochMaxStrikeCheckpoints[epoch][maxStrike][checkpoint]
                .totalLiquidityBalance += collateralAmount;
        }

        epochMaxStrikeCheckpoints[epoch][maxStrike][checkpoint]
            .unlockedCollateral -= collateralAmount;

        emit RelockCollateral(epoch, maxStrike, collateralAmount, msg.sender);
    }

    function getUnwindAmount(
        uint256 _optionsAmount,
        uint256 _optionStrike
    ) public view returns (uint256 unwindAmount) {
        if (_optionStrike < getUsdPrice()) {
            unwindAmount = (_optionsAmount * _optionStrike) / getUsdPrice();
        } else {
            unwindAmount = _optionsAmount;
        }
    }

    /**
     * @notice Settle options in expiry window
     * @param purchaseId ID of options purchase
     * @param receiver   Address of Pnl receiver
     * @param pnlToUser  Total PnL
     */
    function settle(
        uint256 purchaseId,
        address receiver
    ) external returns (uint256 pnlToUser) {
        _isEligibleSender();
        _whenNotPaused();
        _isManagedContract();

        uint256 epoch = currentEpoch;
        uint256 settlementPrice = epochVaultStates[epoch].settlementPrice;
        uint256 expiry = epochVaultStates[epoch].expiryTime;

        _validate(isWithinExerciseWindow(), 13);

        if (expiry >= block.timestamp) {
            settlementPrice = getUsdPrice();
        }

        OptionsPurchase memory _userOptionsPurchase = userOptionsPurchases[
            purchaseId
        ];
        _validate(_userOptionsPurchase.user == msg.sender, 12);

        uint256 pnl = calculatePnl(
            settlementPrice,
            _userOptionsPurchase.optionStrike,
            _userOptionsPurchase.optionsAmount
        );

        _validate(pnl > 0, 14);

        uint256 _pnl;

        IERC20 settlementToken = IERC20(addresses.quoteToken);

        uint256 unlockedCollateral = strikeMulAmount(
            _userOptionsPurchase.optionStrike,
            _userOptionsPurchase.optionsAmount
        );
        uint256 settlement = unlockedCollateral - pnl;

        for (uint256 i; i < _userOptionsPurchase.strikes.length; ) {
            _pnl = (pnl * _userOptionsPurchase.weights[i]) / WEIGHTS_MUL_DIV;

            if (_userOptionsPurchase.unlock) {
                _relockCollateral(
                    _userOptionsPurchase.epoch,
                    _userOptionsPurchase.strikes[i],
                    (settlement * _userOptionsPurchase.weights[i]) /
                        WEIGHTS_MUL_DIV,
                    _userOptionsPurchase.checkpoints[i]
                );
            } else {
                epochMaxStrikeCheckpoints[epoch][
                    _userOptionsPurchase.strikes[i]
                ][_userOptionsPurchase.checkpoints[i]]
                    .totalLiquidityBalance -= _pnl;
                pnlToUser += _pnl;
            }
            unchecked {
                ++i;
            }
        }

        if (_userOptionsPurchase.unlock) {
            settlementToken.safeTransferFrom(
                msg.sender,
                address(this),
                settlement
            );
        } else {
            // Transfer PnL to user
            settlementToken.safeTransfer(receiver, pnlToUser);
        }

        delete userOptionsPurchases[purchaseId];

        // Emit event
        emit NewSettle(
            epoch,
            _userOptionsPurchase.optionStrike,
            msg.sender,
            _userOptionsPurchase.optionsAmount,
            pnl
        );
    }

    /**
     * @notice Calculate Pnl
     * @param price price of BaseToken
     * @param strike strike price of the option
     * @param amount amount of options
     */
    function calculatePnl(
        uint256 price,
        uint256 strike,
        uint256 amount
    ) public view returns (uint256) {
        if (price == 0) price = getUsdPrice();
        return strike > price ? (strikeMulAmount((strike - price), amount)) : 0;
    }

    /**
     * @notice Calculate funding fees based on days left till expiry.
     *
     * @param _collateralAccess Amount of collateral borrowed.
     * @return fees
     */
    function calculateFundingFees(
        address _account,
        uint256 _collateralAccess
    ) public view returns (uint256 fees) {
        uint256 feeBps = IDopexFeeStrategy(addresses.feeStrategy).getFeeBps(
            FUNDING_FEES_KEY,
            _account,
            useDiscountForFees
        );

        uint256 hoursLeftTillExpiry = ((epochVaultStates[currentEpoch]
            .expiryTime - block.timestamp) * 10000) / fundingInterval;

        uint256 finalBps = (feeBps * hoursLeftTillExpiry) / 10000;

        if (finalBps == 0) {
            finalBps = feeBps;
        }

        fees =
            ((_collateralAccess * (FEE_BPS_PRECISION + finalBps)) /
                FEE_BPS_PRECISION) -
            _collateralAccess;
    }

    /**
     * @notice Gracefully exercises an atlantic, sends collateral to integrated protocol,
     *         underlying to writer.
     *         to the option holder/protocol
     * @param  purchaseId   Options purchase id
     * @return unwindAmount Amount charged from caller (unwind amount + fees)
     */
    function unwind(
        uint256 purchaseId
    ) external returns (uint256 unwindAmount) {
        _whenNotPaused();
        _isEligibleSender();

        _validate(_isVaultReady(currentEpoch), 5);

        OptionsPurchase memory _userOptionsPurchase = userOptionsPurchases[
            purchaseId
        ];

        _validate(_userOptionsPurchase.user == msg.sender, 23);
        _validate(_userOptionsPurchase.unlock, 16);

        unwindAmount = getUnwindAmount(
            _userOptionsPurchase.optionsAmount,
            _userOptionsPurchase.optionStrike
        );

        for (uint256 i; i < _userOptionsPurchase.strikes.length; ) {
            // Unwind from maxStrike
            _unwind(
                _userOptionsPurchase.epoch,
                _userOptionsPurchase.strikes[i],
                ((unwindAmount) * _userOptionsPurchase.weights[i]) /
                    WEIGHTS_MUL_DIV,
                _userOptionsPurchase.checkpoints[i]
            );
            unchecked {
                ++i;
            }
        }
        _safeTransferFrom(
            addresses.baseToken,
            msg.sender,
            address(this),
            unwindAmount
        );
        delete userOptionsPurchases[purchaseId];
    }

    /// @dev Helper function to update states within max strikes
    function _unwind(
        uint256 _epoch,
        uint256 _maxStrike,
        uint256 _underlyingAmount,
        uint256 _checkpoint
    ) internal {
        unchecked {
            epochMaxStrikeCheckpoints[_epoch][_maxStrike][_checkpoint]
                .underlyingAccrued += _underlyingAmount;
        }
        emit Unwind(_epoch, _maxStrike, _underlyingAmount, msg.sender);
    }

    /**
     * @notice Withdraws balances for a strike from epoch deposted in to current epoch
     * @param depositId maxstrike to withdraw from
     */
    function withdraw(
        uint256 depositId
    )
        external
        nonReentrant
        returns (
            uint256 userWithdrawableAmount,
            uint256 premium,
            uint256 fundingFees,
            uint256 underlying
        )
    {
        _isEligibleSender();
        _whenNotPaused();

        (userWithdrawableAmount, premium, fundingFees, underlying) = _withdraw(
            depositId
        );

        _safeTransfer(
            addresses.quoteToken,
            msg.sender,
            premium + userWithdrawableAmount + fundingFees
        );
        _safeTransfer(addresses.baseToken, msg.sender, underlying);

        return (userWithdrawableAmount, premium, fundingFees, underlying);
    }

    /**
     * @notice Bootstraps a new epoch, sets the strike based on offset% set. To be called after expiry
     *         of every epoch. Ensure strike offset is set before calling this function
     * @param  expiry   Expiry of the epoch to set.
     * @param  tickSize Spacing between max strikes.
     * @return success
     */
    function bootstrap(
        uint256 expiry,
        uint256 tickSize
    ) external nonReentrant onlyRole(MANAGER_ROLE) returns (bool) {
        uint256 nextEpoch = currentEpoch + 1;

        epochTickSize[nextEpoch] = tickSize;

        VaultState memory _vaultState = epochVaultStates[nextEpoch];

        _validate(expiry > block.timestamp, 19);

        if (currentEpoch > 0)
            _validate(epochVaultStates[nextEpoch - 1].isVaultExpired, 18);

        // Set the next epoch start time
        _vaultState.startTime = block.timestamp;

        _vaultState.expiryTime = expiry;

        _vaultState.isVaultReady = true;

        // Increase the current epoch
        currentEpoch = nextEpoch;

        epochVaultStates[nextEpoch] = _vaultState;

        emit Bootstrap(nextEpoch);

        return true;
    }

    /*==== VIEWS ====*/

    /// @notice Calculate Fees for settlement of options
    /// @param account Account to consider for fee discount.
    /// @param pnl     total pnl.
    /// @return fees
    function calculateSettlementFees(
        address account,
        uint256 pnl
    ) public view returns (uint256 fees) {
        fees = IDopexFeeStrategy(addresses.feeStrategy).getFeeBps(
            SETTLEMENT_FEES_KEY,
            account,
            useDiscountForFees
        );

        fees = ((pnl * (FEE_BPS_PRECISION + fees)) / FEE_BPS_PRECISION) - pnl;
    }

    /// @notice Calculate Fees for purchase
    /// @param strike strike price of the BaseToken option
    /// @param amount amount of options being bought
    /// @return finalFee purchase fee in QuoteToken
    function calculatePurchaseFees(
        address account,
        uint256 strike,
        uint256 amount
    ) public view returns (uint256 finalFee) {
        uint256 feeBps = IDopexFeeStrategy(addresses.feeStrategy).getFeeBps(
            PURCHASE_FEES_KEY,
            account,
            useDiscountForFees
        );

        finalFee =
            (((amount * (FEE_BPS_PRECISION + feeBps)) / FEE_BPS_PRECISION) -
                amount) /
            10 ** (OPTION_TOKEN_DECIMALS - COLLATERAL_TOKEN_DECIMALS);

        if (getUsdPrice() < strike) {
            uint256 feeMultiplier = (((strike * 100) / (getUsdPrice())) - 100) +
                100;
            finalFee = (feeMultiplier * finalFee) / 100;
        }
    }

    /// @notice Calculate premium for an option
    /// @param _strike Strike price of the option
    /// @param _amount Amount of options
    /// @return premium in QuoteToken
    function calculatePremium(
        uint256 _strike,
        uint256 _amount
    ) public view returns (uint256 premium) {
        uint256 currentPrice = getUsdPrice();
        premium = strikeMulAmount(
            IOptionPricing(addresses.optionPricing).getOptionPrice(
                true, // isPut
                epochVaultStates[currentEpoch].expiryTime,
                _strike,
                currentPrice,
                getVolatility(_strike)
            ),
            _amount
        );
    }

    /**
     * @notice Returns the price of the BaseToken in USD
     */
    function getUsdPrice() public view returns (uint256) {
        return
            IPriceOracle(addresses.priceOracle).getPrice(
                addresses.baseToken,
                false,
                false,
                false
            ) / 10 ** (30 - STRIKE_DECIMALS);
    }

    /// @notice Returns the volatility from the volatility oracle
    /// @param _strike Strike of the option
    function getVolatility(uint256 _strike) public view returns (uint256) {
        return
            IVolatilityOracle(addresses.volatilityOracle).getVolatility(
                _strike
            );
    }

    /**
     *   @notice Checks if caller is managed contract
     */
    function _isManagedContract() internal view {
        _validate(managedContracts[msg.sender], 20);
    }

    /**
     * @notice Revert-er function to revert with string error message
     * @param trueCondition Similar to require, a condition that has to be false
     *                      to revert
     * @param errorCode     Index in the errors[] that was set in error controller
     */
    function _validate(bool trueCondition, uint256 errorCode) internal pure {
        if (!trueCondition) {
            revert AtlanticPutsPoolError(errorCode);
        }
    }

    /**
     * @notice Checks if vault is not expired and bootstrapped
     * @param epoch Epoch of the pool
     */
    function _isVaultReady(uint256 epoch) internal view returns (bool) {
        return
            !epochVaultStates[epoch].isVaultExpired &&
            epochVaultStates[epoch].isVaultReady;
    }

    /**
     * @notice Check's if a maxstrike is valid by result of maxstrike % ticksize == 0
     * @param  maxStrike Max-strike amount
     * @param  epoch     Epoch of the pool
     * @return validity  if the max strike is valid
     */
    function _isValidMaxStrike(
        uint256 maxStrike,
        uint256 epoch
    ) private view returns (bool) {
        return maxStrike > 0 && maxStrike % epochTickSize[epoch] == 0;
    }

    function _safeTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
    }

    /**
     * @notice Creates a new checkpoint or update existing one.
     *         current checkpoint
     * @param  epoch     Epoch of the pool
     * @param  maxStrike Max strike deposited into
     * @param  liquidity Amount of deposits / liquidity to add to totalLiquidity, totalLiquidityBalance
     * @return index     Returns the checkpoint number
     */
    function _updateCheckpoint(
        uint256 epoch,
        uint256 maxStrike,
        uint256 liquidity
    ) internal returns (uint256 index) {
        index = epochMaxStrikeCheckpointsLength[epoch][maxStrike];

        if (index == 0) {
            epochMaxStrikeCheckpoints[epoch][maxStrike][index] = (
                Checkpoint(block.timestamp, liquidity, liquidity, 0, 0, 0, 0, 0)
            );
            unchecked {
                ++epochMaxStrikeCheckpointsLength[epoch][maxStrike];
            }
        } else {
            Checkpoint memory currentCheckpoint = epochMaxStrikeCheckpoints[
                epoch
            ][maxStrike][index - 1];

            /**
      @dev Check if checkpoint interval was exceeded compared to previous checkpoint
           start time. if yes then create a new checkpoint or else accumulate to previous
           checkpoint
     */

            /** @dev If a checkpoints options have active collateral, add liquidity to next checkpoint
             */
            if (currentCheckpoint.activeCollateral > 0) {
                epochMaxStrikeCheckpoints[epoch][maxStrike][index]
                    .startTime = block.timestamp;
                epochMaxStrikeCheckpoints[epoch][maxStrike][index]
                    .totalLiquidity += liquidity;
                epochMaxStrikeCheckpoints[epoch][maxStrike][index]
                    .totalLiquidityBalance += liquidity;
                epochMaxStrikeCheckpointsLength[epoch][maxStrike]++;
            } else {
                unchecked {
                    --index;
                }

                currentCheckpoint.totalLiquidity += liquidity;
                currentCheckpoint.totalLiquidityBalance += liquidity;

                epochMaxStrikeCheckpoints[epoch][maxStrike][
                    index
                ] = currentCheckpoint;
            }
        }
    }

    /**
     * @param _depositId Epoch of atlantic pool to inquire
     * @return depositAmount Total deposits of user
     * @return premium       Total premiums earned
     * @return borrowFees    Total borrowFees fees earned
     * @return underlying    Total underlying earned on unwinds
     */
    function _withdraw(
        uint256 _depositId
    )
        private
        returns (
            uint256 depositAmount,
            uint256 premium,
            uint256 borrowFees,
            uint256 underlying
        )
    {
        DepositPosition memory _userDeposit = userDepositPositions[_depositId];

        _validate(_userDeposit.depositor == msg.sender, 23);
        _validate(epochVaultStates[_userDeposit.epoch].isVaultExpired, 1);

        Checkpoint memory _depositCheckpoint = epochMaxStrikeCheckpoints[
            _userDeposit.epoch
        ][_userDeposit.strike][_userDeposit.checkpoint];

        borrowFees +=
            (_userDeposit.liquidity * _depositCheckpoint.fundingFeesAccrued) /
            _depositCheckpoint.totalLiquidity;

        premium +=
            (_userDeposit.liquidity * _depositCheckpoint.premiumAccrued) /
            _depositCheckpoint.totalLiquidity;

        underlying +=
            (_userDeposit.liquidity * _depositCheckpoint.underlyingAccrued) /
            _depositCheckpoint.totalLiquidity;

        depositAmount +=
            (_userDeposit.liquidity *
                _depositCheckpoint.totalLiquidityBalance) /
            _depositCheckpoint.totalLiquidity;

        emit NewWithdraw(
            _userDeposit.epoch,
            _userDeposit.strike,
            _userDeposit.checkpoint,
            msg.sender,
            depositAmount,
            premium,
            borrowFees,
            underlying
        );

        delete userDepositPositions[_depositId];
    }

    /**
     * @notice Add max strike to strikesList (linked list)
     * @param _strike Strike to add to strikesList
     * @param _epoch  Epoch of the pool
     */
    function _addMaxStrike(uint256 _strike, uint256 _epoch) internal {
        uint256 highestMaxStrike = epochMaxStrikesRange[_epoch][0];
        uint256 lowestMaxStrike = epochMaxStrikesRange[_epoch][1];

        if (_strike > highestMaxStrike) {
            epochMaxStrikesRange[_epoch][0] = _strike;
        }
        if (_strike < lowestMaxStrike || lowestMaxStrike == 0) {
            epochMaxStrikesRange[_epoch][1] = _strike;
        }
        // Add new max strike after the next largest strike
        uint256 strikeToInsertAfter = _getSortedSpot(_strike, _epoch);

        if (strikeToInsertAfter == 0)
            epochStrikesList[_epoch].pushBack(_strike);
        else
            epochStrikesList[_epoch].insertBefore(strikeToInsertAfter, _strike);
    }

    /**
     * @param  _value Value of max strike / node
     * @param  _epoch Epoch of the pool
     * @return tail   of the linked list
     */
    function _getSortedSpot(
        uint256 _value,
        uint256 _epoch
    ) private view returns (uint256) {
        if (epochStrikesList[_epoch].sizeOf() == 0) {
            return 0;
        }

        uint256 next;
        (, next) = epochStrikesList[_epoch].getAdjacent(0, true);
        // Switch to descending

        while (
            (next != 0) && ((_value < (isValidStrike[_epoch][next] ? next : 0)))
        ) {
            next = epochStrikesList[_epoch].list[next][true];
        }
        return next;
    }

    /**
     * @notice Multiply strike and amount depending on strike and options decimals
     * @param  _strike Option strike
     * @param  _amount Amount of options
     * @return result  Product of strike and amount in collateral/quote token decimals
     */
    function strikeMulAmount(
        uint256 _strike,
        uint256 _amount
    ) public view returns (uint256 result) {
        uint256 divisor = (STRIKE_DECIMALS + OPTION_TOKEN_DECIMALS) -
            COLLATERAL_TOKEN_DECIMALS;
        return ((_strike * _amount) / 10 ** divisor);
    }

    /**
     * @notice Get OptionsPurchase instance for a given tokenId
     * @param  _tokenId        ID of the options purchase
     * @return OptionsPurchase Options purchase data
     */
    function getOptionsPurchase(
        uint256 _tokenId
    ) external view returns (OptionsPurchase memory) {
        return userOptionsPurchases[_tokenId];
    }

    /**
     * @notice Get deposit position data for a given tokenId
     * @param  _tokenId        ID of the options purchase
     * @return DepositPosition Deposit position data
     */
    function getDepositPosition(
        uint256 _tokenId
    ) external view returns (DepositPosition memory) {
        return userDepositPositions[_tokenId];
    }

    /**
     * @notice Get checkpoints of a maxstrike in a epoch
     * @param  _epoch       Epoch of the pool
     * @param  _maxStrike   Max strike to query for
     * @return _checkpoints array of checkpoints of a max strike
     */
    function getEpochCheckpoints(
        uint256 _epoch,
        uint256 _maxStrike
    ) external view returns (Checkpoint[] memory _checkpoints) {
        _checkpoints = new Checkpoint[](
            epochMaxStrikeCheckpointsLength[_epoch][_maxStrike]
        );

        for (
            uint256 i;
            i < epochMaxStrikeCheckpointsLength[_epoch][_maxStrike];

        ) {
            _checkpoints[i] = epochMaxStrikeCheckpoints[_epoch][_maxStrike][i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Fetches all max strikes written in a epoch
     * @param  epoch Epoch of the pool
     * @return maxStrikes
     */
    function getEpochStrikes(
        uint256 epoch
    ) external view returns (uint256[] memory maxStrikes) {
        maxStrikes = new uint256[](epochStrikesList[epoch].sizeOf());

        uint256 nextNode = epochMaxStrikesRange[epoch][0];
        uint256 iterator;
        while (nextNode != 0) {
            maxStrikes[iterator] = nextNode;
            iterator++;
            (, nextNode) = epochStrikesList[epoch].getNextNode(nextNode);
        }
    }

    function getCurrentEpochTickSize() external view returns (uint256) {
        return epochTickSize[currentEpoch];
    }

    function setUseDiscountForFees(
        bool _setAs
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        useDiscountForFees = _setAs;
        emit UseDiscountForFeesSet(_setAs);
        return true;
    }

    function whitelistUsers(
        address[] calldata _users,
        bool[] calldata _whitelist
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < _users.length; ) {
            whitelistedUsers[_users[i]] = _whitelist[i];
            unchecked {
                ++i;
            }
        }
    }

    function setWhitelistUserMode(
        bool _mode
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isWhitelistUserMode = _mode;
    }

    function isWithinExerciseWindow() public view returns (bool) {
        uint256 expiry = epochVaultStates[currentEpoch].expiryTime;
        return
            block.timestamp >= (expiry - expiryWindow) &&
            block.timestamp <= expiry;
    }

    modifier whitelistCheck() {
        if (isWhitelistUserMode) {
            _validate(whitelistedUsers[msg.sender], 403);
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../interfaces/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/// @title ContractWhitelist
/// @author witherblock
/// @notice A helper contract that lets you add a list of whitelisted contracts that should be able to interact with restricited functions
abstract contract ContractWhitelist {
    /// @dev contract => whitelisted or not
    mapping(address => bool) public whitelistedContracts;

    error AddressNotContract();
    error ContractNotWhitelisted();
    error ContractAlreadyWhitelisted();

    /*==== SETTERS ====*/

    /// @dev add to the contract whitelist
    /// @param _contract the address of the contract to add to the contract whitelist
    function _addToContractWhitelist(address _contract) internal {
        if (!isContract(_contract)) revert AddressNotContract();

        whitelistedContracts[_contract] = true;

        emit AddToContractWhitelist(_contract);
    }

    /// @dev remove from  the contract whitelist
    /// @param _contract the address of the contract to remove from the contract whitelist
    function _removeFromContractWhitelist(address _contract) internal {

        whitelistedContracts[_contract] = false;

        emit RemoveFromContractWhitelist(_contract);
    }

    // modifier is eligible sender modifier
    function _isEligibleSender() internal view {
        // the below condition checks whether the caller is a contract or not
        if (msg.sender != tx.origin) {
            if (!whitelistedContracts[msg.sender]) {
                revert ContractNotWhitelisted();
            }
        }
    }

    /*==== VIEWS ====*/

    /// @dev checks for contract or eoa addresses
    /// @param addr the address to check
    /// @return bool whether the passed address is a contract address
    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /*==== EVENTS ====*/

    event AddToContractWhitelist(address indexed _contract);
    event RemoveFromContractWhitelist(address indexed _contract);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.7;

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

    error ReentrancyCall();

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
        // On the first call to nonReentrant, _notEntered will be true
        if (_status == _ENTERED) revert ReentrancyCall();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStructureInterface {
    function getValue(uint256 _id) external view returns (uint256);
}

/**
 * @title StructuredLinkedList
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */
library StructuredLinkedList {
    uint256 private constant _NULL = 0;
    uint256 private constant _HEAD = 0;

    bool private constant _PREV = false;
    bool private constant _NEXT = true;

    struct List {
        uint256 size;
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function listExists(List storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function nodeExists(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
            if (self.list[_HEAD][_NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function sizeOf(List storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
     */
    function getNode(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function getAdjacent(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function getPreviousNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _PREV);
    }

    /**
     * @dev Can be used before `insert` to build an ordered list.
     * @dev Get the node and then `insertBefore` or `insertAfter` basing on your list order.
     * @dev If you want to order basing on other than `structure.getValue()` override this function
     * @param self stored linked list from contract
     * @param _structure the structure instance
     * @param _value value to seek
     * @return uint256 next node with a value less than _value
     */
    function getSortedSpot(List storage self, address _structure, uint256 _value) internal view returns (uint256) {
        if (sizeOf(self) == 0) {
            return 0;
        }

        uint256 next;
        (, next) = getAdjacent(self, _HEAD, _NEXT);
        while ((next != 0) && ((_value < IStructureInterface(_structure).getValue(next)) != _NEXT)) {
            next = self.list[next][_NEXT];
        }
        return next;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertAfter(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertBefore(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function remove(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; // NOT: SafeMath library should be used here to decrement.

        return _node;
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @return bool true if success, false otherwise
     */
    function pushFront(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    /**
     * @dev Pushes an entry to the tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the tail
     * @return bool true if success, false otherwise
     */
    function pushBack(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    /**
     * @dev Pops the first entry from the head of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popFront(List storage self) internal returns (uint256) {
        return _pop(self, _NEXT);
    }

    /**
     * @dev Pops the first entry from the tail of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popBack(List storage self) internal returns (uint256) {
        return _pop(self, _PREV);
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (_NEXT) or tail (_PREV)
     * @return bool true if success, false otherwise
     */
    function _push(List storage self, uint256 _node, bool _direction) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (_NEXT) or the tail (_PREV)
     * @return uint256 the removed node
     */
    function _pop(List storage self, bool _direction) private returns (uint256) {
        uint256 adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function _insert(List storage self, uint256 _node, uint256 _new, bool _direction) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _link node to link to in the _direction
     * @param _direction direction to insert node in
     */
    function _createLink(List storage self, uint256 _node, uint256 _link, bool _direction) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/// @title Lighter version of the Openzeppelin Pausable contract
/// @author witherblock
/// @notice Helps pause a contract to block the execution of selected functions
/// @dev Difference from the Openzeppelin version is changing the modifiers to internal fns and requires to reverts
abstract contract Pausable {
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
     * @dev Internal function to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _whenNotPaused() internal view {
        if (paused()) revert ContractPaused();
    }

    /**
     * @dev Internal function to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _whenPaused() internal view {
        if (!paused()) revert ContractNotPaused();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual {
        _whenNotPaused();
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual {
        _whenPaused();
        _paused = false;
        emit Unpaused(msg.sender);
    }

    error ContractPaused();
    error ContractNotPaused();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * NOTE: Modified to include symbols and decimals.
 */
interface IERC20 {

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOptionPricing {
  function getOptionPrice(
    bool isPut,
    uint256 expiry,
    uint256 strike,
    uint256 lastPrice,
    uint256 baseIv
  ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceOracle {
  function latestAnswer() external view returns (uint256);

  function getUnderlyingPrice() external view returns (uint256);

  function getCollateralPrice() external view returns (uint256);

  function getPrice(
    address,
    bool,
    bool,
    bool
  ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVolatilityOracle {
    function getVolatility(uint256 strike) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDopexFeeStrategy {
 function getFeeBps(
        uint256 _feeType,
        address _user,
        bool _useDiscount
    ) external view returns (uint256 _feeBps);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Addresses {
  address quoteToken;
  address baseToken;
  address feeDistributor;
  address feeStrategy;
  address optionPricing;
  address priceOracle;
  address volatilityOracle;
}

struct VaultState {
  // Settlement price set on expiry
  uint256 settlementPrice;
  // Timestamp at which the epoch expires
  uint256 expiryTime;
  // Start timestamp of the epoch
  uint256 startTime;
  // Whether vault has been bootstrapped
  bool isVaultReady;
  // Whether vault is expired
  bool isVaultExpired;
}


struct Checkpoint {
  uint256 startTime;
  uint256 totalLiquidity;
  uint256 totalLiquidityBalance;
  uint256 activeCollateral;
  uint256 unlockedCollateral;
  uint256 premiumAccrued;
  uint256 fundingFeesAccrued;
  uint256 underlyingAccrued;
}

struct OptionsPurchase {
  uint256 epoch;
  uint256 optionStrike;
  uint256 optionsAmount;
  uint256[] strikes;
  uint256[] checkpoints;
  uint256[] weights;
  address user;
  bool unlock;
}

struct DepositPosition {
  uint256 epoch;
  uint256 strike;
  uint256 timestamp;
  uint256 liquidity;
  uint256 checkpoint;
  address depositor;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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