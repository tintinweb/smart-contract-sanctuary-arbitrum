// SPDX-License-Identifier: GPL-2.0-only
pragma solidity =0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMintBurnToken} from "./interfaces/IMintBurnToken.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPortalV2MultiAsset} from "./interfaces/IPortalV2MultiAsset.sol";
import {Account, SwapData} from "./interfaces/IAdapterV1.sol";
import {EventsLib} from "./libraries/EventsLib.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";
import {IAggregationRouterV6, SwapDescription, IAggregationExecutor} from "./interfaces/IAggregationRouterV6.sol";
import {IRamsesPair} from "./interfaces/IRamses.sol";

/// @title Adapter V1 contract for Portals V2
/// @author Possum Labs
/**
 * @notice This contract accepts and returns user deposits of a single asset
 * The deposits are redirected to a connected Portal contract
 * Users accrue portalEnergy points over time while staking their tokens in the Adapter
 * portalEnergy can be exchanged for PSM tokens via the virtual LP of the connected Portals
 * When selling portalEnergy, users can choose to receive any DEX traded token by routing PSM through 1Inch
 * Users can also opt to receive ETH/PSM V2 LP tokens on Ramses
 * portalEnergy can be minted as standard ERC20 token
 * PortalEnergy Tokens can be burned to increase a recipient portalEnergy balance in the Adapter
 */
contract AdapterV1 is ReentrancyGuard {
    constructor(address _PORTAL_ADDRESS) {
        PORTAL = IPortalV2MultiAsset(_PORTAL_ADDRESS);
        setUp();
        increaseAllowances();
    }

    // ============================================
    // ==               VARIABLES                ==
    // ============================================
    using SafeERC20 for IERC20;

    address constant ONE_INCH_V6_AGGREGATION_ROUTER_CONTRACT_ADDRESS = 0x111111125421cA6dc452d289314280a0f8842A65;
    address constant PSM_WETH_RAMSES_LP = 0x8BfAa6260FF474536f2f76EFdB4A2A782f98C798;
    // address constant RAMSES_ROUTER_ADDRESS = 0xAAA87963EFeB6f7E0a2711F397663105Acb1805e;
    uint256 constant SECONDS_PER_YEAR = 31536000;
    uint256 constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    IPortalV2MultiAsset public immutable PORTAL; // The connected Portal contract
    IERC20 public constant PSM = IERC20(0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5); // the PSM token ERC20
    IERC20 constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); // the ERC20 representation of WETH token
    address public constant OWNER = 0xAb845D09933f52af5642FC87Dd8FBbf553fd7B33;

    IMintBurnToken public portalEnergyToken; // The ERC20 representation of portalEnergy
    IERC20 public principalToken; // The staking token of the Portal
    uint256 denominator; // Used in calculation related to earning portalEnergy

    // IRamsesRouter public constant RAMSES_ROUTER = IRamsesRouter(RAMSES_ROUTER_ADDRESS); // Interface of Ramses Router
    IAggregationRouterV6 public constant ONE_INCH_V6_AGGREGATION_ROUTER =
        IAggregationRouterV6(ONE_INCH_V6_AGGREGATION_ROUTER_CONTRACT_ADDRESS); // Interface of 1inchRouter

    uint256 public totalPrincipalStaked; // Amount of principal staked by all users of the Adapter
    mapping(address => Account) public accounts; // Associate users with their stake position

    address public migrationDestination; // The new Adapter version
    uint256 public votesForMigration; // Track the yes-votes for migrating to a new Adapter
    bool public successMigrated; // True if the migration was executed by minting the stake NFT to the new Adapter
    mapping(address user => uint256 voteCount) public voted; // Track user votes for migration
    uint256 public constant TIMELOCK = 604800; // 7 Days delay before migration can be executed
    uint256 migrationTime;

    uint256 private constant _PARTIAL_FILL = 1 << 0; // 1Inch flag for partial fills

    // ============================================
    // ==               MODIFIERS                ==
    // ============================================
    modifier onlyOwner() {
        if (msg.sender != OWNER) {
            revert ErrorsLib.notOwner();
        }
        _;
    }

    modifier notMigrating() {
        if (migrationDestination != address(0)) {
            revert ErrorsLib.isMigrating();
        }
        _;
    }

    modifier isMigrating() {
        if (migrationDestination == address(0)) {
            revert ErrorsLib.notMigrating();
        }
        _;
    }

    // ============================================
    // ==          MIGRATION MANAGEMENT          ==
    // ============================================
    /// @notice Set the destination address when migrating to a new Adapter contract
    /// @dev Allow the contract owner to propose a new Adapter contract for migration
    /// @dev The current value of migrationDestination must be the zero address
    function proposeMigrationDestination(address _adapter) external onlyOwner notMigrating {
        migrationDestination = _adapter;

        /// @dev emit event that migration has been proposed
        emit EventsLib.MigrationProposed(_adapter);
    }

    /// @notice Capital based voting process to accept the migration contract
    /// @dev Allow users to accept the proposed migration contract
    /// @dev Can only be called if a destination was proposed, i.e. migration is ongoing
    function acceptMigrationDestination() external isMigrating {
        /// @dev Get user stake balance which equals voting power
        Account memory account = accounts[msg.sender];

        /// @dev Ensure that users can only add their current stake balance to votes
        if (voted[msg.sender] == 0) {
            /// @dev Increase the total number of acceptance votes and votes of the user by user stake balance
            votesForMigration += account.stakedBalance;
            voted[msg.sender] = account.stakedBalance;
        }

        /// @dev Check if the votes are in favour of migrating (>50% of capital)
        uint256 votesRequired = totalPrincipalStaked / 2;
        if (votesForMigration > votesRequired && migrationTime == 0) {
            migrationTime = block.timestamp + TIMELOCK;
        }

        /// @dev Emit event that vote has been placed
        emit EventsLib.VotedForMigration(msg.sender, votesForMigration, votesRequired);
    }

    /// @notice This function mints the Portal NFT and transfers user stakes to a new Adapter
    /// @dev Timelock protected function that can only be called once to move capital to a new Adapter
    function executeMigration() external isMigrating {
        /// @dev Ensure that the timelock is set and has passed
        if (block.timestamp < migrationTime || migrationTime == 0) {
            revert ErrorsLib.isTimeLocked();
        }

        /// @dev Ensure that the migration (minting of NFT) can only be performed once
        if (successMigrated == true) {
            revert ErrorsLib.hasMigrated();
        }

        /// @dev Mint an NFT to the new Adapter that holds the current Adapter stake information
        /// @dev IMPORTANT: The migration contract must be able to receive ERC721 tokens
        successMigrated = true;
        totalPrincipalStaked = 0;
        PORTAL.mintNFTposition(migrationDestination);

        /// @dev Emit migration event
        emit EventsLib.migrationExecuted(migrationDestination);
    }

    /// @notice Function to enable the new Adapter to move over account information of users
    /// @dev This function can only be called by the migration address
    /// @dev Transfer user stake information to the new contract (new Adapter)
    function migrateStake(address _user)
        external
        returns (
            uint256 lastUpdateTime,
            uint256 lastMaxLockDuration,
            uint256 stakedBalance,
            uint256 maxStakeDebt,
            uint256 portalEnergy
        )
    {
        /// @dev Check that the Migration is successfull
        if (successMigrated == false) {
            revert ErrorsLib.migrationVotePending();
        }

        /// @dev Check that the caller is the new Adapter contract
        if (msg.sender != migrationDestination) {
            revert ErrorsLib.notCalledByDestination();
        }

        /// @dev Get the current state of the user stake in Adapter and return
        (lastUpdateTime, lastMaxLockDuration, stakedBalance, maxStakeDebt, portalEnergy,,) =
            getUpdateAccount(_user, 0, true);

        /// @dev delete the account of the user in this Adapter
        delete accounts[_user];
    }

    // ============================================
    // ==           STAKING & UNSTAKING          ==
    // ============================================
    /// @notice Simulate updating a user stake position and return the values without updating the struct
    /// @dev Return the simulated up-to-date user stake information
    /// @dev Consider changes from staking or unstaking including burning amount of PE tokens
    /// @param _user The user whose stake position is to be updated
    /// @param _amount The amount to add or subtract from the user's stake position
    /// @param _isPositiveAmount True for staking (add), false for unstaking (subtract)
    function getUpdateAccount(address _user, uint256 _amount, bool _isPositiveAmount)
        public
        view
        returns (
            uint256 lastUpdateTime,
            uint256 lastMaxLockDuration,
            uint256 stakedBalance,
            uint256 maxStakeDebt,
            uint256 portalEnergy,
            uint256 availableToWithdraw,
            uint256 portalEnergyTokensRequired
        )
    {
        /// @dev Get maxLockDuration from portal
        uint256 maxLockDuration = PORTAL.maxLockDuration();

        /// @dev Load user account into memory
        Account memory account = accounts[_user];

        /// @dev initialize helper variables
        uint256 amount = _amount; // to avoid stack too deep issue
        bool isPositive = _isPositiveAmount; // to avoid stack too deep issue
        uint256 portalEnergyNetChange;
        uint256 timePassed = block.timestamp - account.lastUpdateTime;
        uint256 maxLockDifference = maxLockDuration - account.lastMaxLockDuration;
        stakedBalance = account.stakedBalance;

        /// @dev Check that the Stake Balance is sufficient for unstaking the amount
        if (!isPositive && amount > stakedBalance) {
            revert ErrorsLib.InsufficientStakeBalance();
        }

        /// @dev Check the user account state based on stakedBalance
        /// @dev If this variable is 0, the user could not earn PE
        if (stakedBalance > 0) {
            /// @dev Calculate the Portal Energy earned since the last update
            uint256 portalEnergyEarned = stakedBalance * timePassed;

            /// @dev Calculate the gain of Portal Energy from maxLockDuration increase
            uint256 portalEnergyIncrease = stakedBalance * maxLockDifference;

            /// @dev Summarize Portal Energy changes and divide by common denominator
            portalEnergyNetChange = ((portalEnergyEarned + portalEnergyIncrease) * 1e18) / denominator;
        }

        /// @dev Calculate the adjustment of Portal Energy from balance change
        uint256 portalEnergyAdjustment = (amount * maxLockDuration * 1e18) / denominator;

        /// @dev Calculate the amount of Portal Energy Tokens to be burned for unstaking the amount
        portalEnergyTokensRequired = !isPositive
            && portalEnergyAdjustment > (account.portalEnergy + portalEnergyNetChange)
            ? portalEnergyAdjustment - (account.portalEnergy + portalEnergyNetChange)
            : 0;

        /// @dev Set the last update time to the current timestamp
        lastUpdateTime = block.timestamp;

        /// @dev Update the last maxLockDuration
        lastMaxLockDuration = maxLockDuration;

        /// @dev Update the user's staked balance and consider stake or unstake
        stakedBalance = isPositive ? stakedBalance + amount : stakedBalance - amount;

        /// @dev Update the user's max stake debt
        maxStakeDebt = (stakedBalance * maxLockDuration * 1e18) / denominator;

        /// @dev Update the user's portalEnergy and account for stake or unstake
        /// @dev This will be 0 if Portal Energy Tokens must be burned
        portalEnergy = isPositive
            ? account.portalEnergy + portalEnergyNetChange + portalEnergyAdjustment
            : account.portalEnergy + portalEnergyTokensRequired + portalEnergyNetChange - portalEnergyAdjustment;

        /// @dev Update amount available to withdraw
        availableToWithdraw =
            portalEnergy >= maxStakeDebt ? stakedBalance : (stakedBalance * portalEnergy) / maxStakeDebt;
    }

    /// @notice Update user account to the current state
    /// @dev This function updates the user accout to the current state
    /// @dev It takes memory inputs and stores them into the user account struct
    /// @param _user The user whose account is to be updated
    /// @param _stakedBalance The current Staked Balance of the user
    /// @param _maxStakeDebt The current maximum Stake Debt of the user
    /// @param _portalEnergy The current Portal Energy of the user
    function _updateAccount(address _user, uint256 _stakedBalance, uint256 _maxStakeDebt, uint256 _portalEnergy)
        private
    {
        /// @dev Get maxLockDuration from portal
        uint256 maxLockDuration = PORTAL.maxLockDuration();

        /// @dev Update the user account data
        Account storage account = accounts[_user];
        account.lastUpdateTime = block.timestamp;
        account.lastMaxLockDuration = maxLockDuration;
        account.stakedBalance = _stakedBalance;
        account.maxStakeDebt = _maxStakeDebt;
        account.portalEnergy = _portalEnergy;

        /// @dev Emit an event with the updated account information
        emit EventsLib.AdapterPositionUpdated(
            _user,
            account.lastUpdateTime,
            account.lastMaxLockDuration,
            account.stakedBalance,
            account.maxStakeDebt,
            account.portalEnergy
        );
    }

    /// @notice Stake the principal token into the Adapter and then into Portal
    /// @dev This function allows users to stake their principal tokens into the Adapter
    /// @dev Can only be called if the virtual LP is active (indirect condition)
    /// @dev Cannot be called after a migration destination was proposed (withdraw-only mode)
    /// @dev Update the user account
    /// @dev Update the global tracker of staked principal
    /// @dev Stake the principal into the connected Portal
    /// @param _amount The amount of tokens to stake
    function stake(uint256 _amount) external payable notMigrating nonReentrant {
        /// @dev Rely on input validation from Portal

        /// @dev Avoid tricking the function when ETH is the principal token by inserting fake _amount
        if (address(principalToken) == address(0)) {
            _amount = msg.value;
        }

        /// @dev Get the current state of the user stake in Adapter
        (,, uint256 stakedBalance, uint256 maxStakeDebt, uint256 portalEnergy,,) =
            getUpdateAccount(msg.sender, _amount, true);

        /// @dev Update the user stake struct
        _updateAccount(msg.sender, stakedBalance, maxStakeDebt, portalEnergy);

        /// @dev Update the global tracker of staked principal
        totalPrincipalStaked = totalPrincipalStaked + _amount;

        /// @dev Trigger the stake transaction in the Portal & send tokens
        if (address(principalToken) == address(0)) {
            PORTAL.stake{value: _amount}(_amount);
        } else {
            if (msg.value > 0) {
                revert ErrorsLib.NativeTokenNotAllowed();
            }
            principalToken.safeTransferFrom(msg.sender, address(this), _amount);
            PORTAL.stake(_amount);
        }

        /// @dev Emit event that principal has been staked
        emit EventsLib.AdapterStaked(msg.sender, _amount);
    }

    /// @notice Serve unstaking requests & withdraw principal from the connected Portal
    /// @dev This function allows users to unstake their tokens
    /// @dev Cannot be called after migration was executed (indirect condition, Adapter has no funds in Portal)
    /// @dev Update the user account
    /// @dev Update the global tracker of staked principal
    /// @dev Burn Portal Energy Tokens from caller to top up account balance if required
    /// @dev Withdraw principal from the connected Portal
    /// @dev Send the principal tokens to the user
    /// @param _amount The amount of tokens to unstake
    function unstake(uint256 _amount) external nonReentrant {
        /// @dev Rely on input validation from Portal

        /// @dev If the staker had voted for migration, reset the vote
        if (voted[msg.sender] > 0) {
            votesForMigration -= voted[msg.sender];
            voted[msg.sender] = 0;
        }

        /// @dev Get the current state of the user stake
        /// @dev Throws if caller tries to unstake more than stake balance
        /// @dev Will burn Portal Energy tokens if account has insufficient Portal Energy
        (,, uint256 stakedBalance, uint256 maxStakeDebt, uint256 portalEnergy,, uint256 portalEnergyTokensRequired) =
            getUpdateAccount(msg.sender, _amount, false);

        /// @dev Update the user stake struct
        _updateAccount(msg.sender, stakedBalance, maxStakeDebt, portalEnergy);

        /// @dev Update the global tracker of staked principal
        totalPrincipalStaked -= _amount;

        /// @dev Take Portal Energy Tokens from the user if required
        if (portalEnergyTokensRequired > 0) {
            portalEnergyToken.transferFrom(msg.sender, address(this), portalEnergyTokensRequired);

            /// @dev Burn the Portal Energy Tokens to top up PE balance of the Adapter
            PORTAL.burnPortalEnergyToken(address(this), portalEnergyTokensRequired);
        }

        /// @dev Withdraw principal from the Portal to the Adapter
        PORTAL.unstake(_amount);

        /// @dev Send the received token balance to the user
        if (address(principalToken) == address(0)) {
            (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
            if (!sent) {
                revert ErrorsLib.FailedToSendNativeToken();
            }
        } else {
            IERC20(principalToken).safeTransfer(msg.sender, principalToken.balanceOf(address(this)));
        }

        /// @dev Emit the event that funds have been unstaked
        emit EventsLib.AdapterUnstaked(msg.sender, _amount);
    }

    // ============================================
    // ==          TRADE PORTAL ENERGY           ==
    // ============================================
    /// @notice Users sell PSM into the Adapter to top up portalEnergy balance of a recipient in the Adapter
    /// @dev This function allows users to sell PSM tokens to the contract to increase a recipient portalEnergy
    /// @dev Get the correct price from the quote function of the Portal
    /// @dev Increase the portalEnergy (in Adapter) of the recipient by the amount of portalEnergy received
    /// @dev Transfer the PSM tokens from the caller to the contract, then to the Portal
    /// @param _recipient The recipient of the Portal Energy credit
    /// @param _amountInputPSM The amount of PSM tokens to sell
    /// @param _minReceived The minimum amount of portalEnergy to receive
    /// @param _deadline The unix timestamp that marks the deadline for order execution

    function buyPortalEnergy(address _recipient, uint256 _amountInputPSM, uint256 _minReceived, uint256 _deadline)
        external
        notMigrating
    {
        /// @dev Rely on amount input validation from Portal

        /// @dev validate the recipient address
        if (_recipient == address(0)) {
            revert ErrorsLib.InvalidAddress();
        }

        /// @dev Get the amount of portalEnergy received based on the amount of PSM tokens sold
        uint256 amountReceived = PORTAL.quoteBuyPortalEnergy(_amountInputPSM);

        /// @dev Increase the portalEnergy of the recipient by the amount of portalEnergy received
        accounts[_recipient].portalEnergy += amountReceived;

        /// @dev Send PSM from caller to Adapter, then trigger the transaction in the Portal
        /// @dev Approvals are set with different function to save gas
        PSM.transferFrom(msg.sender, address(this), _amountInputPSM);
        PORTAL.buyPortalEnergy(address(this), _amountInputPSM, _minReceived, _deadline);

        /// @dev Emit the event that Portal Energy has been purchased
        emit EventsLib.AdapterEnergyBuyExecuted(msg.sender, _recipient, amountReceived);
    }

    /// @notice Users sell portalEnergy into the Adapter to receive upfront yield
    /// @dev This function allows users to sell portalEnergy to the Adapter with different swap modes
    /// @dev Get the output amount from the quote function
    /// @dev Reduce the portalEnergy balance of the caller by the amount of portalEnergy sold
    /// @dev Perform the type of exchange according to selected mode
    /// @param _recipient The recipient of the output tokens
    /// @param _amountInputPE The amount of Portal Energy to sell (Adapter)
    /// @param _minReceived The minimum amount of PSM to receive
    /// @param _deadline The unix timestamp that marks the deadline for order execution
    /// @param _mode The trading mode of the swap. 0 = PSM, 1 = ETH/PSM LP, 2 = 1Inch swap
    /// @param _actionData Data required for the 1Inch Router, received by 1Inch API
    /// @param _minPSMForLiquidiy Minimum amount of PSM tokens to receive for liquidity addition
    /// @param _minWethForLiquidiy Minimum amount of WETH tokens to receive for liquidity addition
    function sellPortalEnergy(
        address payable _recipient,
        uint256 _amountInputPE,
        uint256 _minReceived,
        uint256 _deadline,
        uint256 _mode,
        bytes calldata _actionData,
        uint256 _minPSMForLiquidiy,
        uint256 _minWethForLiquidiy
    ) external {
        /// @dev Only validate additional input arguments, let other checks float up from Portal
        if (_mode > 2) revert ErrorsLib.InvalidMode();

        /// @dev Get the current state of user stake in Adapter
        (,, uint256 stakedBalance, uint256 maxStakeDebt, uint256 portalEnergy,,) = getUpdateAccount(msg.sender, 0, true);

        /// @dev Check that the user has enough portalEnergy to sell
        if (portalEnergy < _amountInputPE) {
            revert ErrorsLib.InsufficientBalance();
        }

        /// @dev Get the amount of PSM received based on the amount of portalEnergy sold
        uint256 amountReceived = PORTAL.quoteSellPortalEnergy(_amountInputPE);

        /// @dev Update the stake data of the user
        portalEnergy -= _amountInputPE;

        /// @dev Update the user stake struct
        _updateAccount(msg.sender, stakedBalance, maxStakeDebt, portalEnergy);

        /// @dev Sell energy in Portal and get PSM
        PORTAL.sellPortalEnergy(address(this), _amountInputPE, _minReceived, _deadline);

        /// @dev Assemble the swap data from API to use 1Inch Router
        SwapData memory swap = SwapData(_recipient, amountReceived, _actionData);

        /// @dev Transfer PSM, or add liquidity, or exchange on 1Inch and transfer output token
        if (_mode == 0) {
            PSM.safeTransfer(_recipient, amountReceived);
        } else if (_mode == 1) {
            addLiquidity(msg.sender, swap, _minPSMForLiquidiy, _minWethForLiquidiy);
        } else {
            swapOneInch(msg.sender, swap, false);
        }

        /// @dev Emit the event that Portal Energy has been sold
        emit EventsLib.AdapterEnergySellExecuted(msg.sender, _recipient, _amountInputPE);
    }

    // ============================================
    // ==         External Integrations          ==
    // ============================================
    /// @dev This internal function assembles the swap via the 1Inch router from API data
    function swapOneInch(address _caller, SwapData memory _swap, bool _forLiquidity) internal {
        /// @dev decode the data for getting _executor, _description, _data.
        (address _executor, SwapDescription memory _description, bytes memory _data) =
            abi.decode(_swap.actionData, (address, SwapDescription, bytes));

        /// @dev Ensure that the receiving address of the swap is correct
        /// @dev In Mode 1 (LP) the Adapter must receive the output token
        /// @dev In Mode 2 (swap) the user (_recipient) must receive the output token
        if (_forLiquidity && _description.dstReceiver != address(this)) revert ErrorsLib.InvalidSwap();
        if (!_forLiquidity && _description.dstReceiver != _swap.recipient) revert ErrorsLib.InvalidSwap();

        /// @dev Ensure that partial fills are not allowed
        if (_description.flags & _PARTIAL_FILL != 0) revert ErrorsLib.InvalidSwap();

        /// @dev Swap via the 1Inch Router
        /// @dev Allowance is increased in separate function to save gas
        (, uint256 spentAmount_) =
            ONE_INCH_V6_AGGREGATION_ROUTER.swap(IAggregationExecutor(_executor), _description, _data);

        /// @dev If not called from addLiquidity, send remaining PSM back to caller
        if (!_forLiquidity) {
            uint256 remainAmount = _swap.psmAmount - spentAmount_;
            if (remainAmount > 0) PSM.transfer(_caller, remainAmount);
        }
    }

    /// @dev Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    /// @dev This is used to determine how many assets must be supplied to a Pool2 LP
    function quoteLiquidity(uint256 amountA, uint256 reserveA, uint256 reserveB)
        internal
        pure
        returns (uint256 amountB)
    {
        if (amountA == 0) revert ErrorsLib.InvalidAmount();
        if (reserveA == 0 || reserveB == 0) {
            revert ErrorsLib.InsufficientReserves();
        }

        amountB = (amountA * reserveB) / reserveA;
    }

    /// @dev This function is called when mode = 1 in sellPortalEnergy
    /// @dev Sell some amount of PSM for WETH, then pair in Ramses Pool2
    function addLiquidity(
        address _caller,
        SwapData memory _swap,
        uint256 _minPSMForLiquidiy,
        uint256 _minWethForLiquidiy
    ) internal {
        /// @dev perform the 1Inch swap to get some WETH.
        swapOneInch(_caller, _swap, true);

        /// @dev This contract shouldn't hold any token, so we pass all tokens.
        uint256 PSMBalance = PSM.balanceOf(address(this));
        uint256 WETHBalance = WETH.balanceOf(address(this));

        /// @dev Get the correct amount of PSM and WETH to add to the Ramses Pool2
        (uint256 amountPSM, uint256 amountWETH) =
            _addLiquidity(PSMBalance, WETHBalance, _minPSMForLiquidiy, _minWethForLiquidiy);

        /// @dev Get the pair address of the ETH/PSM Pool2 LP
        address pair = PSM_WETH_RAMSES_LP;

        /// @dev Transfer tokens to the LP and mint LP shares to the user
        /// @dev Uses the low level mint function of the pair implementation
        /// @dev Assumes that the pair already exists which is the case
        PSM.safeTransfer(pair, amountPSM);
        WETH.safeTransfer(pair, amountWETH);
        IRamsesPair(pair).mint(_swap.recipient);

        /// @dev Return remaining tokens to the caller
        if (PSM.balanceOf(address(this)) > 0) PSM.transfer(_caller, PSM.balanceOf(address(this)));
        if (WETH.balanceOf(address(this)) > 0) WETH.transfer(_caller, WETH.balanceOf(address(this)));
    }

    /// @dev Calculate the required token amounts of PSM and WETH to add liquidity
    function _addLiquidity(uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin)
        internal
        view
        returns (uint256 amountA, uint256 amountB)
    {
        if (amountADesired < amountAMin) revert ErrorsLib.InvalidAmount();
        if (amountBDesired < amountBMin) revert ErrorsLib.InvalidAmount();

        /// @dev Get the reserves of the pair
        (uint256 reserveA, uint256 reserveB,) = IRamsesPair(PSM_WETH_RAMSES_LP).getReserves();

        /// @dev Calculate how much PSM and WETH are required
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin) {
                    revert ErrorsLib.InvalidAmount();
                }
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                if (amountAOptimal > amountADesired) {
                    revert ErrorsLib.InvalidAmount();
                }
                if (amountAOptimal < amountAMin) {
                    revert ErrorsLib.InvalidAmount();
                }
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    // ============================================
    // ==           PE ERC20 MANAGEMENT          ==
    // ============================================
    /// @notice Users can burn their PortalEnergyTokens to increase their portalEnergy in the Adapter
    /// @dev This function allows users to convert Portal Energy Tokens into internal Adapter PE
    /// @dev Burn Portal Energy Tokens of caller and increase portalEnergy in Adapter
    /// @param _amount The amount of portalEnergyToken to burn

    function burnPortalEnergyToken(address _recipient, uint256 _amount) external notMigrating {
        /// @dev Rely on input validation of the Portal

        /// @dev validate the recipient address
        if (_recipient == address(0)) {
            revert ErrorsLib.InvalidAddress();
        }

        /// @dev Increase the portalEnergy of the recipient by the amount of portalEnergyToken burned
        accounts[_recipient].portalEnergy += _amount;

        /// @dev Transfer Portal Energy Tokens to Adapter so that they can be burned
        portalEnergyToken.transferFrom(msg.sender, address(this), _amount);

        /// @dev Burn portalEnergyToken from the Adapter
        PORTAL.burnPortalEnergyToken(address(this), _amount);

        emit EventsLib.AdapterEnergyBurned(msg.sender, _recipient, _amount);
    }

    /// @notice Users can mint Portal Energy Tokens using their internal balance
    /// @dev This function controls the minting of Portal Energy Token
    /// @dev Decrease portalEnergy of caller and instruct Portal to mint Portal Energy Tokens to the recipient
    /// @param _amount The amount of portalEnergyToken to mint
    function mintPortalEnergyToken(address _recipient, uint256 _amount) external {
        /// @dev Rely on input validation of the Portal

        /// @dev Get the current state of the user stake
        (,, uint256 stakedBalance, uint256 maxStakeDebt, uint256 portalEnergy,,) = getUpdateAccount(msg.sender, 0, true);

        /// @dev Check that the caller has sufficient portalEnergy to mint the amount of portalEnergyToken
        if (portalEnergy < _amount) {
            revert ErrorsLib.InsufficientBalance();
        }

        /// @dev Reduce the portalEnergy of the caller by the amount of minted tokens
        portalEnergy -= _amount;

        /// @dev Update the user stake struct
        _updateAccount(msg.sender, stakedBalance, maxStakeDebt, portalEnergy);

        /// @dev Mint portal energy tokens to the recipient address
        PORTAL.mintPortalEnergyToken(_recipient, _amount);

        emit EventsLib.AdapterEnergyMinted(msg.sender, _recipient, _amount);
    }

    // ============================================
    // ==                GENERAL                 ==
    // ============================================
    /// @dev Increase token spending allowances of Adapter holdings
    function increaseAllowances() public {
        PSM.approve(address(PORTAL), MAX_UINT);
        PSM.approve(ONE_INCH_V6_AGGREGATION_ROUTER_CONTRACT_ADDRESS, MAX_UINT);
        portalEnergyToken.approve(address(PORTAL), MAX_UINT);

        /// @dev  Set approval when ETH is not the principal token
        if (address(principalToken) != address(0)) {
            principalToken.approve(address(PORTAL), 0);
            principalToken.safeIncreaseAllowance(address(PORTAL), MAX_UINT);
        }
    }

    /// @dev Initialize important variables, called by the constructor
    function setUp() internal {
        if (PORTAL.portalEnergyToken() == address(0)) {
            revert ErrorsLib.TokenNotSet();
        }
        principalToken = IERC20(PORTAL.PRINCIPAL_TOKEN_ADDRESS());
        portalEnergyToken = IMintBurnToken(PORTAL.portalEnergyToken());
        denominator = SECONDS_PER_YEAR * PORTAL.DECIMALS_ADJUSTMENT();
    }

    /// @dev Send ETH or the specified token to the VirtualLP
    /// @dev Provide a reward of 5% to the caller
    function salvageToken(address _token) external {
        /// @dev Salvage native ETH
        if (_token == address(0)) {
            uint256 ethSalvage = (address(this).balance * 95) / 100;
            uint256 rewardEth = address(this).balance - ethSalvage;

            /// @dev Send the ETH balance to the VirtualLP & pay reward
            (bool sent1,) = payable(PORTAL.VIRTUAL_LP()).call{value: ethSalvage}("");
            if (!sent1) {
                revert ErrorsLib.FailedToSendNativeToken();
            }
            (bool sent2,) = payable(msg.sender).call{value: rewardEth}("");
            if (!sent2) {
                revert ErrorsLib.FailedToSendNativeToken();
            }
        } else {
            /// @dev Salvage ERC20 tokens
            uint256 salvage = (IERC20(_token).balanceOf(address(this)) * 95) / 100;
            uint256 reward = IERC20(_token).balanceOf(address(this)) - salvage;

            /// @dev Send the token balance to the VirtualLP & pay reward
            IERC20(_token).safeTransfer(PORTAL.VIRTUAL_LP(), salvage);
            IERC20(_token).safeTransfer(msg.sender, reward);
        }
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IRamsesPair {
    function mint(address to) external returns (uint256 liquidity);

    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable returns (uint256); // 0x4b64e492
}

struct SwapDescription {
    address srcToken;
    address dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
}

interface IAggregationRouterV6 {
    /// @notice Performs a swap, delegating all calls encoded in `data` to `_executor`.
    /// @dev router keeps 1 wei of every token on the contract balance for gas optimisations reasons. This affects first swap of every token by leaving 1 wei on the contract.
    /// @param _executor Aggregation _executor that executes calls described in `data`
    /// @param _desc Swap description
    /// @param _data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount_ Resulting token amount
    /// @return spentAmount_ Source token amount
    function swap(IAggregationExecutor _executor, SwapDescription calldata _desc, bytes calldata _data)
        external
        payable
        returns (uint256 returnAmount_, uint256 spentAmount_);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

// ============================================
// ==          CUSTOM ERROR MESSAGES         ==
// ============================================
library ErrorsLib {
    error DeadlineExpired();
    error DurationLocked();
    error DurationTooLow();
    error EmptyAccount();
    error InsufficientBalance();
    error InsufficientReceived();
    error InsufficientStakeBalance();
    error InsufficientToWithdraw();
    error InvalidAddress();
    error InvalidAmount();
    error InvalidConstructor();
    error NativeTokenNotAllowed();
    error TokenExists();
    error FailedToSendNativeToken();

    error InvalidMode();
    error InvalidSwap();
    error InsufficientReserves();
    error notOwner();
    error isTimeLocked();
    error isMigrating();
    error notMigrating();
    error hasMigrated();
    error migrationVotePending();
    error notCalledByDestination();
    error TokenNotSet();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

library EventsLib {
    event AdapterEnergyBuyExecuted(address indexed caller, address indexed recipient, uint256 amount);
    event AdapterEnergySellExecuted(address indexed caller, address indexed recipient, uint256 amount);

    // --- Events related to staking & unstaking ---
    event AdapterStaked(address indexed caller, uint256 amountStaked);
    event AdapterUnstaked(address indexed caller, uint256 amountUnstaked);

    event AdapterPositionUpdated(
        address indexed user,
        uint256 lastUpdateTime,
        uint256 lastMaxLockDuration,
        uint256 stakedBalance,
        uint256 maxStakeDebt,
        uint256 portalEnergy
    );

    // --- Events related to minting and burning PE ---

    event AdapterEnergyBurned(address indexed caller, address indexed recipient, uint256 amount);
    event AdapterEnergyMinted(address indexed caller, address indexed recipient, uint256 amount);

    // --- Events related to migration ---

    event migrationExecuted(address destination);
    event MigrationProposed(address destination);
    event VotedForMigration(address user, uint256 totalVotes, uint256 votesRequired);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

struct Account {
    uint256 lastUpdateTime;
    uint256 lastMaxLockDuration;
    uint256 stakedBalance;
    uint256 maxStakeDebt;
    uint256 portalEnergy;
}

struct SwapData {
    address recipient;
    uint256 psmAmount;
    bytes actionData;
}

interface IAdapterV1 {
    function PORTAL() external view returns (address PORTAL);

    function acceptMigrationDestination() external;

    function executeMigration() external;

    function migrateStake(address _user)
        external
        returns (
            uint256 lastUpdateTime,
            uint256 lastMaxLockDuration,
            uint256 stakedBalance,
            uint256 maxStakeDebt,
            uint256 portalEnergy
        );

    function getUpdateAccount(address _user, uint256 _amount, bool _isPositiveAmount)
        external
        view
        returns (
            uint256 lastUpdateTime,
            uint256 lastMaxLockDuration,
            uint256 stakedBalance,
            uint256 maxStakeDebt,
            uint256 portalEnergy,
            uint256 availableToWithdraw,
            uint256 portalEnergyTokensRequired
        );

    function stake(uint256 _amount) external;

    function unstake(uint256 _amount) external;

    function buyPortalEnergy(address _recipient, uint256 _amountInputPSM, uint256 _minReceived, uint256 _deadline)
        external;

    function sellPortalEnergy(
        address payable _recipient,
        uint256 _amountInputPE,
        uint256 _minReceived,
        uint256 _deadline,
        uint256 _mode,
        bytes calldata _actionData,
        uint256 _minPSMForLiquidiy,
        uint256 _minWethForLiquidiy
    ) external;

    function burnPortalEnergyToken(address _recipient, uint256 _amount) external;

    function mintPortalEnergyToken(address _recipient, uint256 _amount) external;

    function increaseAllowances() external;

    function salvageToken(address _token) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IPortalV2MultiAsset {
    function stake(uint256 _amount) external payable;

    function unstake(uint256 _amount) external;

    function mintNFTposition(address _recipient) external;

    function buyPortalEnergy(address _recipient, uint256 _amountInputPSM, uint256 _minReceived, uint256 _deadline)
        external;

    function sellPortalEnergy(address _recipient, uint256 _amountInputPE, uint256 _minReceived, uint256 _deadline)
        external;

    function quoteBuyPortalEnergy(uint256 _amountInputPSM) external view returns (uint256 amountReceived);

    function quoteSellPortalEnergy(uint256 _amountInputPE) external view returns (uint256 amountReceived);

    function mintPortalEnergyToken(address _recipient, uint256 _amount) external;

    function burnPortalEnergyToken(address _recipient, uint256 _amount) external;

    function maxLockDuration() external view returns (uint256 maxLockDuration);

    function portalEnergyToken() external view returns (address portalEnergyToken);

    function PRINCIPAL_TOKEN_ADDRESS() external view returns (address PRINCIPAL_TOKEN_ADDRESS);

    function DECIMALS_ADJUSTMENT() external view returns (uint256);

    function VIRTUAL_LP() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.19;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintBurnToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.19;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.19;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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