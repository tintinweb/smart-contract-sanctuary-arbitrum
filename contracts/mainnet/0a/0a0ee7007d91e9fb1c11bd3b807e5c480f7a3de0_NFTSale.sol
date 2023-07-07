// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "./Sale.sol";
import "./BRINFT.sol";

/**
 * @dev Contract to perform sales of BRI NFTs
 * Allows users to buy token for other tokens or coins based on predefined rates.
 * Rates differs between plans.
 */
contract NFTSale is Sale {
    using SafeERC20 for IERC20;

    uint256 constant NORMALIZED_DECIMALS = 18;
    uint256 constant ETH_DIVIDER = 10;
    uint256 constant ETH_JACKPOT_PRICE = 1 ether / 5;

    /**
     * @dev The event emitted upon burn deadline being set
     */
    event BurnDeadlineSet(uint256 deadline);

    /**
     * @dev Address to NFT collection that is being sold in the contract
     */
    BRINFT immutable nft;

    /**
     * @dev Reward Token address for burn payouts
     */
    IERC20 immutable rewardToken;

    /**
     * @dev Tokens acceptable as method of burn payment
     */
    mapping(address => bool) acceptedTokens;

    /**
     * @dev Burn deadline to which token owners can burn their NFTs
     */
    uint256 burnDeadline;

    /**
     * @dev The constructor of the contract
     *
     * @param owner_ Owner address for the contract
     * @param vault_ The vault all funds from sales will be passed to
     * @param nft_ The NFT collection that will be sold
     * @param rewardToken_ The reward token address used to distribute rewards for NFT burn
     * @param acceptedTokens_ The addresses of tokens accepted as the burn
     * @param salePlans_ All plans preconfigured with contract creation
     */
    constructor(
        address owner_,
        address payable vault_,
        BRINFT nft_,
        IERC20 rewardToken_,
        address[] memory acceptedTokens_,
        SalePlanConfiguration[] memory salePlans_
    ) Sale(owner_, vault_, salePlans_) {
        rewardToken = rewardToken_;
        nft = nft_;
        for (uint256 i = 0; i < acceptedTokens_.length;) {
            acceptedTokens[acceptedTokens_[i]] = true;
            unchecked {
                ++i;
            }
        }
        burnDeadline = 0;
    }

    /**
     * @dev Owner settable burn deadline. Can be set only once and sets how long token owners can burn their NFTs
     *
     * Note: Before setting the deadline, reward funds should be transfered to the contract
     *
     * @param deadline_ Burn deadline timestamp (in seconds)
     */
    function setBurnDeadline(uint256 deadline_) external onlyOwner {
        if (!nft.pricesSet()) revert Blocked();
        if (burnDeadline != 0) revert AlreadySet();
        burnDeadline = deadline_;
        emit BurnDeadlineSet(burnDeadline);
    }

    /**
     * @dev Method to perform NFT purchase
     *
     * @param plan_ The plan the buy refers to
     * @param amount_ Number of tokens offered for the purchase
     * @param token_ The token used to purchase
     */
    function buy(uint256 plan_, uint256 amount_, address token_) external payable {
        uint256 num_nfts = _deposit(plan_, amount_, token_);
        _retrieveFunds(_msgSender(), token_, amount_);
        nft.mint(_msgSender(), num_nfts);
    }

    /**
     * @dev The function to retrieve leftover reward tokens after burn season.
     *
     * Only the owner of the contract can do that.
     */
    function retrieveRewards() external onlyOwner {
        // slither-disable-start low-level-calls
        // slither-disable-next-line timestamp
        if (burnDeadline >= block.timestamp) revert Blocked();
        if (address(rewardToken) == address(0)) {
            // slither-disable-next-line incorrect-equality
            if (address(this).balance == 0) revert InsufficientFunds();
            (bool sent,) = owner().call{value: address(this).balance}("");
            if (!sent) revert InsufficientFunds();
        } else {
            // slither-disable-next-line incorrect-equality
            if (rewardToken.balanceOf(address(this)) == 0) revert InsufficientFunds();
            rewardToken.safeTransfer(owner(), rewardToken.balanceOf(address(this)));
        }
        // slither-disable-end low-level-calls
    }

    /**
     * @dev Method allowing token owners to burn them in exchange for 0.1 ETH
     *
     * @param tokenId_ Token ID to be burnt
     * @param paymentToken_ Token used to pay for ETH recieved for NFT burn
     */
    function burn(uint256 tokenId_, address paymentToken_) external notSuspended {
        // slither-disable-next-line timestamp
        if (burnDeadline < block.timestamp) revert Timeout();
        if (nft.ownerOf(tokenId_) != _msgSender()) revert Restricted();
        if (!acceptedTokens[paymentToken_] || nft.price(tokenId_) == 0) revert Blocked();

        // We need to denormalize the price from the original 18 digits (normalized) saved in the NFT contract
        uint256 price = nft.price(tokenId_);
        if (IERC20Metadata(paymentToken_).decimals() < NORMALIZED_DECIMALS) {
            price /= 10 ** (NORMALIZED_DECIMALS - IERC20Metadata(paymentToken_).decimals());
        }

        IERC20(paymentToken_).safeTransferFrom(_msgSender(), vault, price);
        nft.burn(tokenId_);
        if (price == ETH_JACKPOT_PRICE) {
            _transfer(_msgSender(), 1 ether);
        } else {
            _transfer(_msgSender(), 1 ether / ETH_DIVIDER);
        }
    }

    function _transfer(address to_, uint256 amount_) internal {
        // slither-disable-start low-level-calls
        if (address(rewardToken) == address(0)) {
            // slither-disable-next-line arbitrary-send-eth
            (bool sent,) = to_.call{value: amount_}("");
            if (!sent) revert InsufficientFunds();
        } else {
            rewardToken.safeTransfer(to_, amount_);
        }
        // slither-disable-end low-level-calls
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

import "./Ownable.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/interfaces/IERC2981.sol";
import "./Errors.sol";

/**
 * @dev Contract implementing BRINFT features for NFTPrivateSale
 */
contract BRINFT is Ownable, ERC721, IERC2981 {
    /**
     * @dev Maximum amount of NFTs that a single mint can produce
     */
    uint256 constant MAX_MINT = 5;

    /**
     * @dev royalties amount denominator
     */
    uint256 constant ROYALTIES_DENOMINATOR = 100;

    /**
     * @dev The event emitted when new sale contract address is set
     */
    event NewSaleContract(address indexed saleContract);

    /**
     * @dev The event emitted when new URI base has been set and prices revealed
     */
    event PricesRevealed();

    /**
     * @dev A max cap for all possible mints for the contract
     */
    uint256 mintCap;

    /**
     * @dev Sale contract address allowed to mint new tokens
     */
    address sale;

    /**
     * @dev Admin address contract allowed to burn tokens
     */
    address immutable admin;

    /**
     * @dev Id of the next token that will be minted
     */
    uint256 nextTokenId;

    /**
     * @dev Base URI of all tokens
     */
    string baseURI;

    /**
     * @dev The mapping for tokens prices
     */
    mapping(uint256 => uint256) public price;

    /**
     * @dev The address royalties will be sent to
     */
    address immutable vault;

    /**
     * @dev The royalties size normalized to 1%
     */
    uint256 immutable royalties;

    /**
     * @dev Flag if bulk deposit has been made already
     */
    bool bulkDepositMade;

    /**
     * @dev Flag if prices have been already set
     */
    bool public pricesSet;

    /**
     * @dev The modifier allowing to pass only sale contract caller
     */
    modifier onlySaleContract() {
        if (_msgSender() != sale) revert Restricted();
        _;
    }

    /**
     * @dev The modifier allowing to pass only admin caller
     */
    modifier onlyAdmin() {
        if (_msgSender() != admin) revert Restricted();
        _;
    }

    /**
     * @dev The modifier allowing to pass admin and owner callers only
     */
    modifier onlyAdminOrOwner() {
        if (_msgSender() != admin && _msgSender() != owner()) revert Restricted();
        _;
    }

    /**
     * @dev The contract constructor.
     *
     * @param owner_ The owner of the contract
     * @param admin_ The admin of the contract
     * @param mintCap_ The cap for all tokens possible to be minted in this contract
     * @param name_ The name of the NFT
     * @param symbol_ The symbol for the NFT
     * @param vault_ The vault that will collect royalties
     * @param royalties_ Percentage for all royalties in NFT sale
     * @param baseURI_ The uri base for all NFTs
     */
    constructor(
        address owner_,
        address admin_,
        uint256 mintCap_,
        string memory name_,
        string memory symbol_,
        address vault_,
        uint256 royalties_,
        string memory baseURI_
    ) ERC721(name_, symbol_) Ownable(owner_) {
        if (vault_ == address(0)) revert ZeroAddress();
        if (admin_ == address(0)) revert ZeroAddress();
        mintCap = mintCap_;
        vault = vault_;
        admin = admin_;
        royalties = royalties_;
        baseURI = baseURI_;
    }

    /**
     * @dev The method to reveal all token prices and updated metadata
     *
     * @param baseURI_ New URI to be set
     * @param prices_ Prices of all tokens in the contract
     */
    function reveal(string calldata baseURI_, uint256[] calldata prices_) external onlyAdminOrOwner {
        if (pricesSet) revert AlreadySet();
        pricesSet = true;
        baseURI = baseURI_;
        for (uint256 i = 0; i < prices_.length;) {
            price[i] = prices_[i];
            unchecked {
                ++i;
            }
        }
        emit PricesRevealed();
    }

    /**
     * @dev Setting new sale contract address
     *
     * @param saleContract_ New sale contract address to be set
     */
    function setSaleContract(address saleContract_) external onlyOwner {
        if (sale != address(0)) revert AlreadySet();
        if (saleContract_ == address(0)) revert ZeroAddress();
        sale = saleContract_;
        emit NewSaleContract(sale);
    }

    /**
     * @dev Minting new tokens
     *
     * @param recipent_ Receiver of newly minted tokens
     * @param amount_ The amount of tokens to be minted (maximum 5)
     */
    function mint(address recipent_, uint256 amount_) external onlySaleContract {
        if (amount_ > MAX_MINT) revert TooBig();
        if (recipent_ == address(0)) revert ZeroAddress();

        _mintMany(recipent_, amount_);
    }

    /**
     * @dev Bulk minting tokens
     *
     * @param amount_ Amount of tokens to be minted
     */
    function bulkMint(uint256 amount_) external onlyOwner {
        if (bulkDepositMade) revert Blocked();
        bulkDepositMade = true;
        _mintMany(_msgSender(), amount_);
    }

    /**
     * @dev This contract implements IERC2981 interface.
     *
     * Note: Implemented manualy due to simplified royalty handling in the contract
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev IERC2981 implementation for royalties
     */
    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (vault, salePrice * royalties / ROYALTIES_DENOMINATOR);
    }

    /**
     * @dev Burning existing tokens
     *
     * Burning is limited to a specific timeframe and returns a specific amount of tokens
     * to token owner.
     *
     * @param tokenId_ Id of the token to be burnt
     */
    function burn(uint256 tokenId_) external onlySaleContract {
        _burn(tokenId_);
        delete price[tokenId_];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _mintMany(address recipent_, uint256 amount_) internal {
        if (amount_ > mintCap) revert CapExceeded();

        mintCap -= amount_;
        for (uint256 i = 0; i < amount_;) {
            nextTokenId++;
            // slither-disable-next-line costly-loop
            _safeMint(recipent_, nextTokenId - 1);
            unchecked {
                ++i;
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}