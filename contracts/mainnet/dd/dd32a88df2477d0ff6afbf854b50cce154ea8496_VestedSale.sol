// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./Sale.sol";
import "./VestingToken.sol";
import "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "./Errors.sol";

contract VestedSale is Sale {
    using SafeERC20 for IERC20Metadata;

    // Currently planned vesting levels are listed below.
    // No enum is used to allow creators increase number of vesting schedules
    // and extend the sale with more batches
    // 0 - TEAM,
    // 1 - ROUND A
    // 2 - ROUND B

    /**
     * @dev Divider to calculate percentage of the vest releases from BPS
     */
    uint256 constant BPS_DIVIDER = 10_000;

    /**
     * @dev A vesting plan definition
     *
     * @param cliff Cliff timeline - meaning when funds will start to get released
     * @param vestingPeriod Number of seconds vesting will proceed after ther cliff date
     * @param dayOneRelease Percentage of tokens released right at the cliff date to the users
     */
    struct VestingPlan {
        uint256 cliff; // Number of days until linear release of funds
        uint256 vestingPeriod; // Number of seconds vesting will last from cliff till the end
        uint256 dayOneRelease; // Percentage (in 0.01 units) released on day one - excluded from vesting
    }

    /**
     * @dev The event emitted on token withdrawal by the investor
     *
     * @param investor Investor address that withdraws tokens
     * @param amount Amount of tokens withdrawn
     */
    event Withdrawn(address indexed investor, uint256 amount);

    /**
     * @dev The event emitted on bulk deposit made by the owner
     *
     * @param plan The sale plan for all deposits made in bulk
     */
    event BulkDepositMade(uint256 indexed plan);

    /**
     * A mapping between sale plans (key) to vesting it is connected to (value)
     */
    mapping(uint256 => uint256) vestingMapping;

    /**
     * An array of all vesting plans configured in the contract
     */
    // slither-disable-next-line similar-names
    VestingPlan[] public vestingPlans;

    /**
     * A special vested coin contracts rewards with all users upon deposits 1-1 the token
     * released on the withdrawal
     */
    VestingToken public immutable vestingToken;

    /**
     * The token address
     */
    IERC20Metadata immutable coin;

    /**
     * @dev The constructor of the contract
     *
     * @param owner_ Owner address for the contract
     * @param vault_ The vault all funds from sales will be passed to
     * @param coin_ The coin that is being sold
     * @param salePlans_ All plans preconfigured with contract creation
     * @param vestingMappings_ Mappings which sale plans are connected to which vesting plans
     * @param vestingPlans_ All vesting plans preconfigured with contract creation
     */
    constructor(
        address owner_,
        address payable vault_,
        IERC20Metadata coin_,
        SalePlanConfiguration[] memory salePlans_,
        uint256[] memory vestingMappings_,
        VestingPlan[] memory vestingPlans_
    ) Sale(owner_, vault_, salePlans_) {
        vestingToken = new VestingToken();

        coin = coin_;
        for (uint256 i = 0; i < vestingPlans_.length;) {
            vestingPlans.push(vestingPlans_[i]);
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < vestingMappings_.length;) {
            vestingMapping[i] = vestingMappings_[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return all vesting plans configurations
     */
    function getAllVestingPlans() external view returns (VestingPlan[] memory) {
        return vestingPlans;
    }

    /**
     * @dev Adds new sale plan (with vesting plan) to the list.
     *
     * @param salePlan_ New sale plan to add
     * @param vestingPlan_ New vesting plan that is connected to the sale plan
     */
    function addNewPlans(SalePlanConfiguration calldata salePlan_, VestingPlan calldata vestingPlan_)
        public
        onlyOwner
    {
        addNewSalePlan(salePlan_, false);
        vestingPlans.push(vestingPlan_);
        vestingMapping[salePlans.length - 1] = vestingPlans.length - 1;
    }

    /**
     * @dev Method to perform the sale by making deposit in other token
     *
     * @param plan_ The plan deposit is made to
     * @param amount_ Amount of token offered
     * @param token_ Token address the purchase is made with. 0 - if native currency is used.
     */
    function deposit(uint256 plan_, uint256 amount_, address token_) external payable {
        uint256 reward = _deposit(plan_, amount_, token_);
        vestingToken.mint(_msgSender(), reward);
        _retrieveFunds(_msgSender(), token_, amount_);
    }

    /**
     * @dev Method allowing the owner to upload a bulk list of deposits made outside of the
     * contract to keep track of its vestings.
     *
     * Reminder: bulkDeposit omits all caps set as global or user-based. Use with caution.
     *
     * @param salePlan_ Sale plan for the bulk upload
     * @param receivers_ An array of the receiver addresses for the bulk upload
     * @param timestamps_ An array of timestamps to set as the deposits vesting start time.
     * @param amounts_ An array of amounts of bulk deposits
     */
    function bulkDeposit(
        uint256 salePlan_,
        address[] calldata receivers_,
        uint256[] calldata timestamps_,
        uint256[] calldata amounts_
    ) external onlyOwner {
        // slither-disable-next-line timestamp
        if (salePlans[salePlan_].endTime <= block.timestamp) revert Timeout();
        emit BulkDepositMade(salePlan_);

        for (uint256 i = 0; i < receivers_.length;) {
            // slither-disable-start reentrancy-no-eth
            // slither-disable-start calls-loop
            vestingToken.mint(receivers_[i], amounts_[i]);
            _internalDeposit(salePlan_, receivers_[i], amounts_[i], timestamps_[i]);
            // slither-disable-end calls-loop
            // slither-disable-end reentrancy-no-eth
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Withdrawal method for vested deposits owners. Automatically calculate
     * and returns user all tokens released by vesting plans so far.
     */
    function withdraw() external notSuspended {
        uint256 to_claim;
        for (uint256 i = 0; i < salePlans.length;) {
            uint256 claimable = _withdrawableFromDeposit(i, _msgSender());
            deposits[i][_msgSender()].withdrawn += claimable;
            to_claim += claimable;
            unchecked {
                ++i;
            }
        }
        emit Withdrawn(_msgSender(), to_claim);
        // slither-disable-next-line incorrect-equality
        if (to_claim == 0) revert NothingToClaim();
        // slither-disable-next-line timestamp
        if (vestingToken.balanceOf(_msgSender()) < to_claim) revert MissingVestingTokens();
        // slither-disable-next-line reentrancy-events
        vestingToken.burn(_msgSender(), to_claim);

        coin.safeTransfer(_msgSender(), to_claim);
    }

    /**
     * @dev Method to calculate how much given invester has unclaimed and unvested funds in the system
     * at given moment.
     *
     * @param investor_ The investor address to calculate funds for.
     *
     * @return The amount of unclaimed and unvested tokens that can be withdrawn.
     */
    function availableForWithdraw(address investor_) public view returns (uint256) {
        uint256 amount;
        for (uint256 i = 0; i < salePlans.length;) {
            amount += _withdrawableFromDeposit(i, investor_);
            unchecked {
                ++i;
            }
        }
        return amount;
    }

    /**
     * @dev Method to calculate how much given invester has unclaimed and unvested funds in the system
     * at given moment.
     *
     * @param investor_ The investor address to calculate funds for.
     * @param plan_ The sale plan to be checked
     *
     * @return The amount of unclaimed and unvested tokens that can be withdrawn.
     */
    function availableForWithdrawInPlan(address investor_, uint256 plan_) public view returns (uint256) {
        return _withdrawableFromDeposit(plan_, investor_);
    }

    /**
     * @dev Overriden implementation to inform about decimal places for sale reward calculations
     * of the sold coin
     */
    function _decimals(uint256) internal virtual override returns (uint256) {
        return coin.decimals();
    }

    /**
     * @dev Internal withdrawal calculator for a single deposit.
     *
     * @param depositIndex_ Index of checked deposit
     * @param investor_ Investor address deposit is assigned to
     *
     * @return Withdrawable amount
     */
    function _withdrawableFromDeposit(uint256 depositIndex_, address investor_) internal view returns (uint256) {
        Deposit storage dep = deposits[depositIndex_][investor_];
        if (dep.amount == 0) return 0;
        VestingPlan storage vest = vestingPlans[vestingMapping[depositIndex_]];
        uint256 cliff = dep.time + vest.cliff;
        // slither-disable-next-line timestamp
        if (block.timestamp >= cliff) {
            // slither-disable-next-line timestamp
            if (block.timestamp > cliff + vest.vestingPeriod) {
                return dep.amount - dep.withdrawn;
            } else {
                uint256 day_one_release = (vest.dayOneRelease * dep.amount) / BPS_DIVIDER;
                uint256 amount_to_release = dep.amount - day_one_release;

                // slither-disable-next-line timestamp
                uint256 seconds_elapsed = block.timestamp - cliff;
                uint256 calc_amount = day_one_release + ((amount_to_release * seconds_elapsed) / vest.vestingPeriod);
                return calc_amount - dep.withdrawn;
            }
        }
        return 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./Ownable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./Errors.sol";

/**
 * @dev Contract to perform sales and vestings of the token.
 * Allows users to buy token for other tokens or coins based on predefined rates.
 * Rates differs between plans. Some plans might not have rates at all.
 * These are predefined plans for vestings made before sale actually starts.
 * With time, owner is able to expand contract with new plans with different rates
 */

abstract contract Sale is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @dev All prices are multiplied by this number to allow smaller fractions of the currency pricing
     */
    uint256 constant PRICE_DIVIDER = 10_000;

    /**
     * @dev Decimals that native ETH has
     */
    uint256 constant ETH_DECIMALS = 18;

    /**
     * @dev The struct defining a single sale plan with rates for all tokens it can be sold with.
     *
     * @param cap Hard cap for the sale plan
     * @param startTime When the private sale round starts
     * @param endTime When the private sale round ends
     */
    struct SalePlan {
        uint256 cap;
        uint256 startTime;
        uint256 endTime;
    }

    /**
     * @dev The currency rate struct for defining rates in bulk
     *
     * @param token Token address this rate relates to or 0 if it relates to natural blockchain coin.
     * @param rate Rate for the token with 18 decimal places. Rate calculated as token_sold_amount = token_amount * rate / (10**18) with all decimal places
     */
    struct CurrencyRate {
        address token; // Token address used for the buy
        uint256 rate; // Rate for the exchange on purchase
    }

    /**
     * @dev Configuration struct defining whitelisted address with its cap
     */
    struct WhitelistConfiguration {
        address whitelisted;
        uint256 cap;
    }

    /**
     * @dev Struct sent on sale plan creation to configure rates and vestings for the plan accordingly
     */
    struct SalePlanConfiguration {
        SalePlan salePlan;
        CurrencyRate[] rates;
        WhitelistConfiguration[] whitelist;
    }

    /**
     * @dev The struct defining a single deposit made upon purchase or as a reward
     *
     * @param time Timestamp of the deposit - calculated as the round closing date
     * @param amount Amount of token vested with the deposit
     * @param withdrawn Amount already withdrawn from the deposit
     */
    struct Deposit {
        uint256 time;
        uint256 amount;
        uint256 withdrawn;
    }

    /**
     * @dev The event emitted on single sale made by the investor
     *
     * @param investor Address of the investor the deposit is linked to
     * @param plan The plan the deposit was made in
     * @param amount Amount that has been vested for the investor
     * @param transactionToken Token address the sale was made with
     */
    event Sold(address indexed investor, uint256 indexed plan, uint256 amount, address transactionToken);

    /**
     * @dev The event emitted when native currency is sent to the contract independently
     */
    event EthReceived(address indexed from, uint256 value);

    /**
     * @dev The event emitted contract is running sale
     *
     * @param onSale Flag if sale is running or not
     */
    event SetOnSale(bool onSale);

    /**
     * @dev The event emitted on new sale plan added to the list
     *
     * @param index Index of the new plan
     * @param isPublic Is newly created plan public to all users
     */
    event NewSalePlan(uint256 indexed index, bool isPublic);

    /**
     * @dev The event emitted on updated whitelist for the sale plan
     *
     * @param salePlan Index of the plan whitelist is being updated for
     */
    event WhitelistUpdated(uint256 indexed salePlan);

    /**
     * The address of the vault receiving all funds from the sales (tokens and coins)
     */
    address payable immutable vault;

    /**
     * The mapping of all deposits made in the sale contract
     */
    mapping(uint256 => mapping(address => Deposit)) public deposits;

    /**
     * The mapping of all currency rates for all sale plans
     */
    mapping(uint256 => mapping(address => uint256)) public currencyRates;

    /**
     * The mapping of all whitelisted addresses with caps
     */
    mapping(uint256 => mapping(address => uint256)) public whitelisted;

    /**
     * An array of whitelisted accounts
     */
    mapping(uint256 => address[]) public whitelistedAccounts;

    /**
     * A mapping of suspended accounts
     */
    mapping(address => bool) public suspended;

    /**
     * A mapping if given sale plan is public
     */
    mapping(uint256 => bool) public isPublic;

    /**
     * An array of all sale plans
     */
    SalePlan[] public salePlans;

    /**
     * The flag if sale contract is currently allowing third parties to perform any deposits
     */
    bool public onSale;

    /**
     * Mapping of total tokens sold in the plan
     */
    mapping(uint256 => uint256) public sold;

    /**
     * Modifier checking if contract is allowed to sell any tokens
     */
    modifier isOnSale(uint256 plan_) {
        if (plan_ >= salePlans.length) revert NotExists();
        if (!onSale || salePlans[plan_].startTime > block.timestamp) revert Blocked();
        if (salePlans[plan_].endTime <= block.timestamp) revert Timeout();
        _;
    }

    /**
     * Modifier checking if account isn't suspended
     */
    modifier notSuspended() {
        if (suspended[_msgSender()]) revert Suspended();
        _;
    }

    /**
     * @dev The constructor of the contract
     *
     * @param owner_ Owner address for the contract
     * @param vault_ The vault all funds from sales will be passed to
     * @param salePlans_ All plans preconfigured with contract creation
     */
    constructor(address owner_, address payable vault_, SalePlanConfiguration[] memory salePlans_) Ownable(owner_) {
        if (vault_ == address(0)) revert ZeroAddress();
        vault = vault_;

        // Set vesting plans configurations
        for (uint256 i = 0; i < salePlans_.length;) {
            salePlans.push(salePlans_[i].salePlan);

            for (uint256 y = 0; y < salePlans_[i].rates.length;) {
                currencyRates[i][salePlans_[i].rates[y].token] = salePlans_[i].rates[y].rate;
                unchecked {
                    ++y;
                }
            }
            for (uint256 z = 0; z < salePlans_[i].whitelist.length;) {
                whitelisted[i][salePlans_[i].whitelist[z].whitelisted] = salePlans_[i].whitelist[z].cap;
                whitelistedAccounts[i].push(salePlans_[i].whitelist[z].whitelisted);
                unchecked {
                    ++z;
                }
            }
            unchecked {
                ++i;
            }
        }

        if (salePlans_.length > 0) {
            onSale = true;
        }
    }

    /**
     * @dev Automatic retrieval of ETH funds
     */
    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    /**
     * @dev Return all plans (round) configurations
     */
    function getAllPlans() external view returns (SalePlan[] memory) {
        return salePlans;
    }

    /**
     * @dev Allowing the owner to start and stop the sale
     *
     * @param onSale_ Flag if sale should be started or stopped
     */
    function setOnSaleStatus(bool onSale_) external onlyOwner {
        if (onSale_ == onSale) revert AlreadySet();
        onSale = onSale_;

        emit SetOnSale(onSale);
    }

    /**
     * @dev Adds new sale plan to the list.
     *
     * @param salePlan_ New sale plan to add
     * @param public_ Is new plan added public
     */
    function addNewSalePlan(SalePlanConfiguration calldata salePlan_, bool public_) public onlyOwner {
        uint256 index = salePlans.length;
        salePlans.push(salePlan_.salePlan);

        for (uint256 i = 0; i < salePlan_.rates.length;) {
            currencyRates[index][salePlan_.rates[i].token] = salePlan_.rates[i].rate;
            unchecked {
                ++i;
            }
        }
        for (uint256 z = 0; z < salePlan_.whitelist.length;) {
            whitelisted[index][salePlan_.whitelist[z].whitelisted] = salePlan_.whitelist[z].cap;
            whitelistedAccounts[index].push(salePlan_.whitelist[z].whitelisted);
            unchecked {
                ++z;
            }
        }

        if (public_) {
            isPublic[index] = public_;
        }

        emit NewSalePlan(index, public_);
    }

    /**
     * @dev Locking or unlocking accounts from sales and withdrawals.
     *
     * @param account_ Account to be suspended or unlocked
     * @param locked_ If account should be locked or unlocked
     */
    function suspendAccount(address account_, bool locked_) external onlyOwner {
        suspended[account_] = locked_;
    }

    /**
     * @dev Updates whitelisted users for given sale plan
     *
     * @param salePlan_ The sale plan id whitelist is being updated for
     * @param whitelistedAddresses_ The whitelisted addresses caps are being updated for
     * @param caps_ Caps for whitelisted addresses
     */
    function addWhitelisted(uint256 salePlan_, address[] memory whitelistedAddresses_, uint256[] memory caps_)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < whitelistedAddresses_.length;) {
            if (whitelisted[salePlan_][whitelistedAddresses_[i]] > 0) {
                whitelistedAccounts[salePlan_].push(whitelistedAddresses_[i]);
            }
            whitelisted[salePlan_][whitelistedAddresses_[i]] = caps_[i];
            unchecked {
                ++i;
            }
        }
        emit WhitelistUpdated(salePlan_);
    }

    /**
     * @dev Method to perform the sale by making deposit in other token
     *
     * @param plan_ The plan the deposit is made to
     * @param amount_ Amount of token offered
     * @param token_ Token address the purchase is made with. 0 - if native currency is used.
     */
    function _deposit(uint256 plan_, uint256 amount_, address token_)
        internal
        isOnSale(plan_)
        notSuspended
        returns (uint256)
    {
        uint256 reward = _reward(token_, amount_, plan_);
        if (reward > _availableForPurchase(plan_, _msgSender()) || reward > salePlans[plan_].cap) {
            revert CapExceeded();
        }
        salePlans[plan_].cap -= reward;
        sold[plan_] += reward;
        _internalDeposit(plan_, _msgSender(), reward, salePlans[plan_].endTime);
        emit Sold(_msgSender(), plan_, amount_, token_);
        return reward;
    }

    /**
     * @dev Internal deposit method that is actually making the deposit record for given receiver
     *
     * @param salePlan_ Sale plan the deposit is being made in
     * @param receiver_ Receiver of the deposit
     * @param amount_ The amount of token vested
     * @param timestamp_ Time of the deposit
     */
    function _internalDeposit(uint256 salePlan_, address receiver_, uint256 amount_, uint256 timestamp_) internal {
        if (receiver_ == address(0)) revert ZeroAddress();
        if (amount_ == 0) revert ZeroValue();

        deposits[salePlan_][receiver_].amount += amount_;
        deposits[salePlan_][receiver_].time = timestamp_;
    }

    /**
     * @dev Method returning amount of tokens still available for purchase for given investora address.
     *
     * @param plan_ The plan the cap is calculated for
     * @param investor_ Investor address to check
     *
     * @return Available token amount investor can still purchase in current sale plan.
     */
    function _availableForPurchase(uint256 plan_, address investor_) internal view returns (uint256) {
        uint256 user_cap = whitelisted[plan_][investor_];

        if (isPublic[plan_]) {
            user_cap = salePlans[plan_].cap;
        } else {
            user_cap -= deposits[plan_][investor_].amount;
        }

        return user_cap;
    }

    /**
     * @dev Calculate amount of the reward to be sent to the user in return
     *
     * Note: This is an example function. Using saved rates as a single token price
     * Price is being normalized based on the tokens decimals used in the purchase
     * This assumes that all tokens used in the purchase are implementing decimals()
     * method.
     *
     * @param token_ The token address used to pay for the purchase
     * @param amount_ The amount of the token used for the purchase
     * @param plan_ The plan the sale is connected to
     *
     * @return The amount of token user should be rewarded with
     */
    function _reward(address token_, uint256 amount_, uint256 plan_) internal virtual returns (uint256) {
        uint256 tokenDecimals = ETH_DECIMALS; // In case token used for purchase is actually a native coin
        if (token_ != address(0)) {
            tokenDecimals = IERC20Metadata(token_).decimals();
        }

        // Depending on the difference in decimal places - we need to normalize amounts in opposite ways
        if (tokenDecimals > _decimals(plan_)) {
            uint256 decimalDiff = tokenDecimals - _decimals(plan_);
            return amount_ * _price(token_, plan_) / (10 ** decimalDiff) / PRICE_DIVIDER;
        } else {
            uint256 decimalDiff = _decimals(plan_) - tokenDecimals;
            return amount_ * _price(token_, plan_) * (10 ** decimalDiff) / PRICE_DIVIDER;
        }
    }

    /**
     * @dev Price rewarded for purchase in given plan with token.
     * The method used by _reward() to calculate the amount
     *
     * @param token_ The token address used for purchase
     * @param plan_ The plan id the purchase is being made in
     *
     * @return The price of a single item purchased in given currency (token)
     */
    function _price(address token_, uint256 plan_) internal virtual returns (uint256) {
        if (currencyRates[plan_][token_] == 0) revert WrongCurrency();
        return currencyRates[plan_][token_];
    }

    /**
     * @dev Decimal places of the item being sold in the sale
     *
     * Note: This method is used by example implementation that can be overriden
     * by any sale contract using this implementation
     *
     * @return The decimal places of sold item
     */
    function _decimals(uint256) internal virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Internal funds retrieval and passing method to the vault
     *
     * @param investor_ Investor address making deposit
     * @param token_ The token address used to purchase the coin or 0 if its native coin of the platform
     * @param amount_ The amount of the purchase
     *
     */
    function _retrieveFunds(address investor_, address token_, uint256 amount_) internal {
        if (token_ == address(0)) {
            if (amount_ != msg.value) revert InsufficientFunds();
            // slither-disable-start low-level-calls
            // slither-disable-next-line arbitrary-send-eth
            (bool sent,) = vault.call{value: amount_}("");
            // slither-disable-end low-level-calls
            if (!sent) revert InsufficientFunds();
        } else {
            if (msg.value > 0) revert WrongCurrency();
            IERC20(token_).safeTransferFrom(investor_, vault, amount_);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "./Ownable.sol";
import "./Errors.sol";

contract VestingToken is ERC20, Ownable {
    constructor() ERC20("BRI Vesting TOKEN", "BRIX") Ownable(msg.sender) {}

    /**
     * @dev Sets decimal places for token to just 9 places instead of default 18
     */

    function decimals() public view virtual override returns (uint8) {
        return 9; // Same decimals as for the token we will be selling (BRI)
    }

    function mint(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }

    function burn(address from_, uint256 amount_) external onlyOwner {
        _burn(from_, amount_);
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal virtual override {
        if (from != address(0) && to != address(0)) revert Blocked();
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/**
 * @dev Action restricted. Given account is not allowed to run it
 */
error Restricted();

/**
 * @dev Trying to set Zero Address to an attribute that cannot be 0
 */
error ZeroAddress();

/**
 * @dev Attribute already set and does not allow resetting
 */
error AlreadySet();

/**
 * @dev A cap has been exceeded - temporarily locked
 */
error CapExceeded();

/**
 * @dev A deadline has been wrongly set
 */
error WrongDeadline();

/**
 * @dev A kill switch is in play. Action restricted and temporarily frozen
 */
error KillSwitch();

/**
 * @dev A value cannot be zero
 */
error ZeroValue();

/**
 * @dev Value exceeded maximum allowed
 */
error TooBig();

/**
 * @dev Appointed item does not exist
 */
error NotExists();

/**
 * @dev Appointed item already exist
 */
error AlreadyExists();

/**
 * @dev Timed action has timed out
 */
error Timeout();

/**
 * @dev Insufficient funds to perform action
 */
error InsufficientFunds();

/**
 * @dev Wrong currency used
 */
error WrongCurrency();

/**
 * @dev Blocked action. For timing or other reasons
 */
error Blocked();

/**
 * @dev Suspended access
 */
error Suspended();

/**
 * @dev Nothing to claim
 */
error NothingToClaim();

/**
 * @dev Missing vesting tokens
 */
error MissingVestingTokens();

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "openzeppelin-contracts/utils/Context.sol";
import "./Errors.sol";

abstract contract Ownable is Context {
    address private _owner;

    constructor(address owner_) {
        if (owner_ == address(0)) revert ZeroAddress();
        _owner = owner_;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != _owner) revert Restricted();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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