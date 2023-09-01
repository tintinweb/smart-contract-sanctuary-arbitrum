// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IFixedStrikeOptionTeller} from "src/interfaces/IFixedStrikeOptionTeller.sol";
import {OLM, ManualStrikeOLM, OracleStrikeOLM} from "src/fixed-strike/liquidity-mining/OLM.sol";

/* ========== ERRORS ========== */
error Factory_InvalidStyle();

/// @dev The OLM Factory contracts allows anyone to deploy new OLM contracts. When deployed, the owner of the OLM is set to the caller.
///      There are two OLM implementations available in the factory: Manual Strike and Oracle Strike. This factory deploys Manual Strike OLMs.
///      See OLM.sol for details on the different implementations.
///      Manual Strike: Owners must manually update the strike price to change it over time
///      Oracle Strike: Strike price is automatically updated based on an oracle and discount.
///      A minimum strike price can be set on the Oracle Strike version to prevent it from going too low.

/// @title Manual Strike Option Liquidity Mining (OLM) Factory
/// @notice Factory for deploying Manual Strike OLM contracts
/// @author Bond Protocol
contract MOLMFactory {
    /* ========== STATE VARIABLES ========== */

    /// @notice Option Teller to be used by OLM contracts
    IFixedStrikeOptionTeller public immutable optionTeller;

    /* ========== CONSTRUCTOR ========== */

    constructor(IFixedStrikeOptionTeller optionTeller_) {
        optionTeller = optionTeller_;
    }

    /* ========== DEPLOY Manual Strike OLM CONTRACTS ========== */

    /// @notice Deploy a new Manual Strike OLM contract with the caller as the owner
    /// @param stakedToken_  ERC20 token that will be staked to earn rewards
    /// @param payoutToken_  ERC20 token that stakers will receive call options for
    /// @return              Address of the new OLM contract
    function deploy(ERC20 stakedToken_, ERC20 payoutToken_) external returns (ManualStrikeOLM) {
        return new ManualStrikeOLM(msg.sender, stakedToken_, optionTeller, payoutToken_);
    }
}

/// @title Oracle Strike Option Liquidity Mining (OLM) Factory
/// @notice Factory for deploying Oracle Strike OLM contracts
/// @author Bond Protocol
contract OOLMFactory {
    /* ========== STATE VARIABLES ========== */

    /// @notice Option Teller to be used by OLM contracts
    IFixedStrikeOptionTeller public immutable optionTeller;

    /* ========== CONSTRUCTOR ========== */

    constructor(IFixedStrikeOptionTeller optionTeller_) {
        optionTeller = optionTeller_;
    }

    /* ========== DEPLOY Oracle Strike OLM CONTRACTS ========== */

    /// @notice Deploy a new Oracle Strike OLM contract with the caller as the owner
    /// @param stakedToken_  ERC20 token that will be staked to earn rewards
    /// @param payoutToken_  ERC20 token that stakers will receive call options for
    /// @return              Address of the new OLM contract
    function deploy(ERC20 stakedToken_, ERC20 payoutToken_) external returns (OracleStrikeOLM) {
        return new OracleStrikeOLM(msg.sender, stakedToken_, optionTeller, payoutToken_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IOptionTeller} from "src/interfaces/IOptionTeller.sol";
import {FixedStrikeOptionToken} from "src/fixed-strike/FixedStrikeOptionToken.sol";

interface IFixedStrikeOptionTeller is IOptionTeller {
    /// @notice             Deploy a new ERC20 fixed strike option token and return its address
    /// @dev                If an option token already exists for the parameters, it returns that address
    /// @param payoutToken_ ERC20 token that the purchaser will receive on execution
    /// @param quoteToken_  ERC20 token used that the purchaser will need to provide on execution
    /// @param eligible_    Timestamp at which the option token can first be executed (gets rounded to nearest day)
    /// @param expiry_      Timestamp at which the option token can no longer be executed (gets rounded to nearest day)
    /// @param receiver_    Address that will receive the proceeds when option tokens are exercised. Also the address that can claim collateral from unexercised options.
    /// @param call_        Whether the option token is a call (true) or a put (false)
    /// @param strikePrice_ Strike price of the option token (in units of quoteToken per payoutToken)
    /// @return             Address of the ERC20 fixed strike option token being created
    function deploy(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external returns (FixedStrikeOptionToken);

    /// @notice              Deposit an ERC20 token and mint an ERC20 fixed strike option token
    /// @param optionToken_  Fixed strike option token to mint
    /// @param amount_       Amount of option tokens to mint (also the number of payout tokens required to be deposited)
    function create(FixedStrikeOptionToken optionToken_, uint256 amount_) external;

    /// @notice              Exercise an ERC20 fixed strike option token. Provide required quote tokens and receive amount of payout tokens.
    /// @param optionToken_  Fixed strike option token to exercise
    /// @param amount_       Amount of option tokens to exercise (also the number of payout tokens to receive)
    /// @dev                 Amount of quote tokens required to exercise is return from the exerciseCost() function
    /// @dev                 If the calling address is the token receiver address, then the amount of option tokens
    /// @dev                 are burned and collateral sent back to receiver, but proceeds are not required.
    /// @dev                 This allows unwrapping option tokens that aren't used prior to expiry.
    function exercise(FixedStrikeOptionToken optionToken_, uint256 amount_) external;

    /// @notice              Reclaim collateral from expired option tokens
    /// @notice              Only callable by the option token receiver address
    /// @param optionToken_  Fixed strike option token to reclaim collateral from
    function reclaim(FixedStrikeOptionToken optionToken_) external;

    /* ========== VIEWS ========== */

    /// @notice              Get the cost to exercise an amount of fixed strike option tokens
    /// @param optionToken_  Fixed strike option token to exercise
    /// @param amount_       Amount of option tokens to exercise
    /// @return token_       Token required to exercise (quoteToken for call, payoutToken for put)
    /// @return cost_        Amount of token_ required to exercise
    function exerciseCost(
        FixedStrikeOptionToken optionToken_,
        uint256 amount_
    ) external view returns (ERC20, uint256);

    /// @notice             Get the FixedStrikeOptionToken contract corresponding to the params, reverts if no token exists
    /// @param payoutToken_ ERC20 token that the purchaser will receive on execution
    /// @param quoteToken_  ERC20 token used that the purchaser will need to provide on execution
    /// @param eligible_    Timestamp at which the option token can first be executed (gets rounded to nearest day)
    /// @param expiry_      Timestamp at which the option token can no longer be executed (gets rounded to nearest day)
    /// @param receiver_    Address that will receive the proceeds when option tokens are exercised. Also the address that can claim collateral from unexercised options.
    /// @param call_        Whether the option token is a call (true) or a put (false)
    /// @param strikePrice_ Strike price of the option token (in units of quoteToken per payoutToken)
    /// @return token_      FixedStrikeOptionToken contract address
    function getOptionToken(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external view returns (FixedStrikeOptionToken);

    /// @notice             Get the hash ID of the fixed strike option token with these parameters
    /// @param payoutToken_ ERC20 token that the purchaser will receive on execution
    /// @param quoteToken_  ERC20 token used that the purchaser will need to provide on execution
    /// @param eligible_    Timestamp at which the option token can first be executed (gets rounded to nearest day)
    /// @param expiry_      Timestamp at which the option token can no longer be executed (gets rounded to nearest day)
    /// @param receiver_    Address that will receive the proceeds when option tokens are exercised. Also the address that can claim collateral from unexercised options.
    /// @param call_        Whether the option token is a call (true) or a put (false)
    /// @param strikePrice_ Strike price of the option token (in units of quoteToken per payoutToken)
    /// @return hash_       Hash ID of the fixed strike option token with these parameters
    function getOptionTokenHash(
        ERC20 payoutToken_,
        ERC20 quoteToken_,
        uint48 eligible_,
        uint48 expiry_,
        address receiver_,
        bool call_,
        uint256 strikePrice_
    ) external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {IBondOracle} from "src/interfaces/IBondOracle.sol";
import {IAllowlist} from "src/interfaces/IAllowlist.sol";

import {FixedStrikeOptionToken} from "src/fixed-strike/FixedStrikeOptionToken.sol";
import {IFixedStrikeOptionTeller} from "src/interfaces/IFixedStrikeOptionTeller.sol";
import {TransferHelper} from "src/lib/TransferHelper.sol";
import {FullMath} from "src/lib/FullMath.sol";

/// @dev The purpose of Option Liquidity Mining is to allow the protocol to
///      re-capture some of the value from liquidity mining rewards when LPs realize profit.
///      Additionally, it can cap the amount of sell pressure on a protocols token in a down
///      market by limiting the profitability of exercising option tokens to above the strike price.
///
///      The OLM contract implements a version of this using fixed strike call options.
///      Protocols can deploy an OLM contract with their specific configuration of staked
///      token and option paramters. The contract implements epoch-based staking rewards to
///      issue new option tokens at fixed time intervals and at a new strike price based on
///      the configuration when an epoch transitions. The owner of the contract can update
///      various staking and option token parameters over time to adjust their rewards program.
///      The owner can also optionally designate an Allowlist contract to limit which users can
///      can stake in the contract. The allowlist should conform to the IAllowlist interface.
///
///      Users can deposit the configured stakedToken into the contract to earn rewards.
///      Rewards are continuously accrued based on the configured reward rate and the total
///      balance of staked tokens in the contract. Any user action updates the reward calculations.
///      Additionally, user actions can trigger a new epoch start, which will earn them additional
///      option tokens in the form of the epoch transition reward for paying the extra gas.
///      Users can claim their outstanding rewards from all epochs or from the next unclaimed epoch.
///      If the option token for a specific epoch has expired, the user will not receive any rewards
///      for that period since they are now worthless.
abstract contract OLM is Owned, ReentrancyGuard {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    /* ========== ERRORS ========== */
    error OLM_InvalidParams();
    error OLM_InvalidAmount();
    error OLM_InvalidEpoch();
    error OLM_ZeroBalance();
    error OLM_PreviousUnclaimedEpoch();
    error OLM_AlreadyInitialized();
    error OLM_NotInitialized();
    error OLM_DepositsDisabled();
    error OLM_NotAllowed();

    /* ========== EVENTS ========== */
    event NewEpoch(uint48 indexed epoch_, FixedStrikeOptionToken optionToken_);

    /* ========== STATE VARIABLES ========== */

    // Staking parameters
    /// @notice Token that is staked in the OLM contract
    ERC20 public immutable stakedToken;
    uint8 internal immutable stakedTokenDecimals;

    /// @notice Whether users can deposit staking tokens into the OLM contract at the current time
    bool public depositsEnabled;

    /// @notice Whether the OLM contract has been initialized
    /// @dev    No settings can be changed or tokens deposited before the OLM contract is initialized
    bool public initialized;

    // Allowlist
    /// @notice (Optional) Address of the allowlist contract which determines which addresses are allowed to interact with the OLM contract
    IAllowlist public allowlist;

    // Option Token Parameters
    /// @notice Option Teller contract that is used to deploy and create option tokens
    IFixedStrikeOptionTeller public immutable optionTeller;

    /// @notice Token that stakers receive call options for
    ERC20 public immutable payoutToken;

    /// @notice Token that stakers must pay to exercise the call options they receive
    ERC20 public quoteToken;

    /// @notice Amount of time (in seconds) from option token deployment to when it can be exercised
    uint48 public timeUntilEligible;

    /// @notice Amount of time (in seconds) from when the option token is eligible to when it expires
    uint48 public eligibleDuration;

    /// @notice Address that will receive the quote tokens when an option is exercised
    address public receiver;

    // Staking epochs

    /// @notice Current staking epoch
    uint48 public epoch;

    /// @notice Staking epoch duration
    uint48 public epochDuration;

    /// @notice Timestamp of the start of the current staking epoch
    uint48 public epochStart;

    // Staking rewards

    /// @notice Amount of time (in seconds) that the reward rate is distributed over
    uint48 public constant REWARD_PERIOD = uint48(1 days);

    /// @notice Timestamp when the stored rewards per token was last updated
    uint48 public lastRewardUpdate;

    /// @notice Amount of option tokens rewarded per reward period
    uint256 public rewardRate;

    /// @notice Global reward distribution variable, used to calculate user rewards
    uint256 public rewardsPerTokenStored;

    /// @notice Amount of option tokens that are rewarded for starting a new epoch
    uint256 public epochTransitionReward;

    /// @notice Rewards Per Token value at the start of each epoch
    mapping(uint48 => uint256) public epochRewardsPerTokenStart;

    // Stake balances

    /// @notice Total amount of staked tokens currently in the contract
    uint256 public totalBalance;

    /// @notice Mapping of staker address to their staked balance
    mapping(address => uint256) public stakeBalance;

    /// @notice Mapping of staker address to the rewards per token they have claimed
    mapping(address => uint256) public rewardsPerTokenClaimed;

    /// @notice Mapping of staker address to the last epoch they claimed rewards for
    mapping(address => uint48) public lastEpochClaimed;

    /// @notice Mapping of epochs to the option tokens that was rewarded for that epoch
    mapping(uint48 => FixedStrikeOptionToken) public epochOptionTokens;

    /* ========== CONSTRUCTOR ========== */

    /// @param owner_        Address of the owner of the OLM contract
    /// @param stakedToken_  Token that is staked in the OLM contract
    /// @param optionTeller_ Option Teller contract that is used by the OLM contract to deploy and create option tokens
    /// @param payoutToken_  Token that stakers receive call options for
    constructor(
        address owner_,
        ERC20 stakedToken_,
        IFixedStrikeOptionTeller optionTeller_,
        ERC20 payoutToken_
    ) Owned(owner_) {
        // Validate parameters
        if (
            owner_ == address(0) ||
            address(stakedToken_) == address(0) ||
            address(stakedToken_).code.length == 0 ||
            address(optionTeller_) == address(0) ||
            address(optionTeller_).code.length == 0 ||
            address(payoutToken_) == address(0) ||
            address(payoutToken_).code.length == 0 ||
            address(stakedToken_) == address(payoutToken_)
        ) revert OLM_InvalidParams();

        // Set staking token parameters
        stakedToken = stakedToken_;
        stakedTokenDecimals = stakedToken_.decimals();

        // Set option token parameters
        optionTeller = optionTeller_;
        payoutToken = payoutToken_;
    }

    /* ========== MODIFIERS ========== */

    /// @notice Modifier that updates the stored rewards per token before a function is executed
    /// @dev    This modifier should be placed on any function where rewards are claimed or staked tokens are deposited/withdrawn.
    /// @dev    Additionally, it should be placed on any functions that modify the reward parameters of the OLM contract.
    modifier updateRewards() {
        // Update the rewards per token and last reward timestamp
        if (lastRewardUpdate != uint48(block.timestamp)) {
            rewardsPerTokenStored = currentRewardsPerToken();
            lastRewardUpdate = uint48(block.timestamp);
        }
        _;
    }

    /// @notice Modifier that tries to start a new epoch before a function is executed and rewards the caller for doing so
    modifier tryNewEpoch() {
        // If the epoch has ended, try to start a new one
        if (uint48(block.timestamp) >= epochStart + epochDuration) {
            _startNewEpoch();
            // Issue reward to caller for starting the new epoch, if not zero
            if (epochTransitionReward > 0) {
                payoutToken.safeApprove(address(optionTeller), epochTransitionReward);
                FixedStrikeOptionToken optionToken = epochOptionTokens[epoch];
                optionTeller.create(optionToken, epochTransitionReward);
                ERC20(address(optionToken)).safeTransfer(msg.sender, epochTransitionReward);
            }
        }
        _;
    }

    /// @notice Modifier that requires the OLM contract to be initialized before a function is executed
    modifier requireInitialized() {
        if (!initialized) revert OLM_NotInitialized();
        _;
    }

    /* ========== INITIALIZATION ========== */

    /// @notice Initializes the OLM contract
    /// @notice Only owner
    /// @dev    This function can only be called once.
    /// @dev    When the function completes, the contract is live. Users can start staking and claiming rewards.
    /// @param quoteToken_            Token that stakers must pay to exercise the call options they receive
    /// @param timeUntilEligible_     Amount of time (in seconds) from option token deployment to when it can be exercised
    /// @param eligibleDuration_      Amount of time (in seconds) from when the option token is eligible to when it expires
    /// @param receiver_              Address that will receive the quote tokens when an option is exercised
    ///                               IMPORTANT: receiver is the only address that can retrieve payout token collateral from expired options.
    ///                               It must be able to call the `reclaim` function on the Option Teller contract.
    /// @param epochDuration_         Staking epoch duration (in seconds)
    /// @param epochTransitionReward_ Amount of option tokens that are rewarded for starting a new epoch
    /// @param rewardRate_            Amount of option tokens rewarded per reward period (1 day)
    /// @param allowlist_             Address of the allowlist contract that can be used to restrict who can stake in the OLM contract.
    ///                               If the zero address, then no allow list is used.
    /// @param allowlistParams_       Parameters that are passed to the allowlist contract when this contract registers with it
    /// @param other_                 Additional parameters that are required by specific implementations of the OLM contract
    function initialize(
        ERC20 quoteToken_,
        uint48 timeUntilEligible_,
        uint48 eligibleDuration_,
        address receiver_,
        uint48 epochDuration_,
        uint256 epochTransitionReward_,
        uint256 rewardRate_,
        IAllowlist allowlist_,
        bytes calldata allowlistParams_,
        bytes calldata other_
    ) external onlyOwner {
        // Revert if already initialized
        if (initialized) revert OLM_AlreadyInitialized();

        // Validate parameters
        // Quote token must be a contract and not the zero address
        if (address(quoteToken_) == address(0) || address(quoteToken_).code.length == 0)
            revert OLM_InvalidParams();

        // The eligible duration must be greater than the minimum option duration on the teller to be a valid option token
        if (eligibleDuration_ < optionTeller.minOptionDuration()) revert OLM_InvalidParams();

        // The option token expiry must be greater than the epoch duration by at least one day
        if (timeUntilEligible_ + eligibleDuration_ - uint48(1 days) < epochDuration_)
            revert OLM_InvalidParams();

        // The receiver cannot be the zero address
        if (receiver_ == address(0)) revert OLM_InvalidParams();

        // If the allowlist is not the zero address, assume it's being used and register the contract
        if (address(allowlist_) != address(0)) {
            // Since an allowlist is being used, we must confirm it is a contract
            if (address(allowlist_).code.length == 0) revert OLM_InvalidParams();

            // Store allowlist
            allowlist = allowlist_;

            // Register contract on allowlist, catch error if fails
            try allowlist.register(allowlistParams_) {} catch {
                revert OLM_InvalidParams();
            }
        }

        // Set option token parameters
        quoteToken = quoteToken_;
        timeUntilEligible = timeUntilEligible_;
        eligibleDuration = eligibleDuration_;
        receiver = receiver_;

        // Set staking epoch parameters
        epochDuration = epochDuration_;
        epochTransitionReward = epochTransitionReward_;

        // Set initial staking variables
        // totalBalance = 0; // don't have to initialize to zero
        // rewardsPerTokenStored = 0; // don't have to initialize to zero
        depositsEnabled = true;
        lastRewardUpdate = uint48(block.timestamp);
        rewardRate = rewardRate_;

        // Set initialized to true
        initialized = true;

        // Pass other parameters to initialize function for implementation specific logic
        _initialize(other_);

        // Starts the first epoch
        _startNewEpoch();
    }

    // Override this function to add implementation specific initialization logic
    function _initialize(bytes calldata params_) internal virtual;

    /* ========== STAKING FUNCTIONS ========== */

    /// @notice Deposit staking tokens into the contract to earn rewards
    /// @notice Only callable if deposits are enabled
    /// @notice Only callable if the user is allowed to stake per the allowlist
    /// @notice May receive reward if calling triggers new epoch
    /// @param amount_ Amount of staking tokens to deposit
    /// @param proof_  Optional proof data for specific allowlist implementations
    function stake(
        uint256 amount_,
        bytes calldata proof_
    ) external nonReentrant requireInitialized updateRewards tryNewEpoch {
        // Revert if deposits are disabled
        if (!depositsEnabled) revert OLM_DepositsDisabled();

        // If allowlist configured, check if user is allowed to stake
        if (address(allowlist) != address(0)) {
            if (!allowlist.isAllowed(msg.sender, proof_)) revert OLM_NotAllowed();
        }

        // Revert if deposit amount is zero to avoid zero transfers
        if (amount_ == 0) revert OLM_InvalidAmount();

        // Get user balance, if non-zero, claim rewards before increasing stake
        uint256 userBalance = stakeBalance[msg.sender];
        if (userBalance > 0) {
            // Claim outstanding rewards, this will update the rewards per token claimed
            _claimRewards();
        } else {
            // Initialize the rewards per token claimed for the user to the stored rewards per token
            rewardsPerTokenClaimed[msg.sender] = rewardsPerTokenStored;
            // Initialize the last epoch claimed to the epoch before the current one
            // Epoch starts at 1 when initialized so this can't revert
            lastEpochClaimed[msg.sender] = epoch - 1;
        }

        // Increase the user's stake balance and the total balance
        stakeBalance[msg.sender] = userBalance + amount_;
        totalBalance += amount_;

        // Transfer the staked tokens from the user to this contract
        stakedToken.safeTransferFrom(msg.sender, address(this), amount_);
    }

    /// @notice Withdraw staking tokens from the contract
    /// @notice May receive reward if calling triggers new epoch
    /// @param amount_ Amount of staking tokens to withdraw
    function unstake(uint256 amount_) external nonReentrant updateRewards tryNewEpoch {
        // Get user balance and check that it's not zero
        uint256 userBalance = stakeBalance[msg.sender];
        if (userBalance == 0) revert OLM_ZeroBalance();

        // Check that amount_ is valid
        if (amount_ > userBalance || amount_ == 0) revert OLM_InvalidAmount();

        // Claim rewards before decreasing stake
        _claimRewards();

        // Decrease the user's stake balance and the total balance
        // Total balance cannot revert if the user value is valid
        stakeBalance[msg.sender] = userBalance - amount_;
        totalBalance -= amount_;

        // Transfer the staked tokens from this contract to the user
        stakedToken.safeTransfer(msg.sender, amount_);
    }

    /// @notice Withdraw entire balance of staking tokens from the contract
    /// @notice May receive reward if calling triggers new epoch
    function unstakeAll() external nonReentrant updateRewards tryNewEpoch {
        // Get user balance and check that it's not zero
        uint256 userBalance = stakeBalance[msg.sender];
        if (userBalance == 0) revert OLM_ZeroBalance();

        // Claim rewards before decreasing stake
        _claimRewards();

        // Decrease the user's stake balance and the total balance
        // Total balance cannot revert since all user balances are less than or equal to the total
        stakeBalance[msg.sender] = 0;
        totalBalance -= userBalance;

        // Transfer the staked tokens from this contract to the user
        stakedToken.safeTransfer(msg.sender, userBalance);
    }

    /// @notice Withdraw entire balance of staking tokens without updating or claiming outstanding rewards.
    /// @notice Rewards will be lost if stake is withdrawn using this function. Only for emergency use.
    function emergencyUnstakeAll() external nonReentrant {
        // Get user balance and check that it's not zero
        uint256 userBalance = stakeBalance[msg.sender];
        if (userBalance == 0) revert OLM_ZeroBalance();

        // Rewards are not claimed and lost

        // Decrease the user's stake balance and the total balance
        // Total balance cannot revert since all user balances are less than or equal to the total
        stakeBalance[msg.sender] = 0;
        totalBalance -= userBalance;

        // Transfer the staked tokens from this contract to the user
        stakedToken.safeTransfer(msg.sender, userBalance);
    }

    /* ========== REWARD FUNCTIONS ========== */

    /// @notice Claim all outstanding rewards for the user across epochs
    function claimRewards() external nonReentrant updateRewards tryNewEpoch returns (uint256) {
        // Revert if user has no stake
        if (stakeBalance[msg.sender] == 0) revert OLM_ZeroBalance();

        // Claim all outstanding rewards
        return _claimRewards();
    }

    function _claimRewards() internal returns (uint256) {
        // Claims all outstanding rewards for the user across epochs
        // If there are unclaimed rewards from epochs where the option token has expired, the rewards are lost

        // Get the last epoch claimed by the user
        uint48 userLastEpoch = lastEpochClaimed[msg.sender];

        // If the last epoch claimed is equal to the current epoch, then only try to claim for the current epoch
        if (userLastEpoch == epoch) return _claimEpochRewards(epoch);

        // If not, then the user has not claimed all rewards
        // Start at the last claimed epoch because they may not have completely claimed that epoch
        uint256 totalRewardsClaimed;
        for (uint48 i = userLastEpoch; i <= epoch; i++) {
            // For each epoch that the user has not claimed rewards for, claim the rewards
            totalRewardsClaimed += _claimEpochRewards(i);
        }

        return totalRewardsClaimed;
    }

    /// @notice Claim all outstanding rewards for the user for the next unclaimed epoch (and any remaining rewards from the previously claimed epoch)
    function claimNextEpochRewards()
        external
        nonReentrant
        updateRewards
        tryNewEpoch
        returns (uint256)
    {
        // Claims all outstanding rewards for the user on their next unclaimed epoch. Allows moving through epochs one txn at a time if desired or to avoid gas issues if a large number of epochs have passed.

        // Revert if user has no stake
        if (stakeBalance[msg.sender] == 0) revert OLM_ZeroBalance();

        // Get the last epoch claimed by the user
        uint48 userLastEpoch = lastEpochClaimed[msg.sender];

        // If the last epoch claimed is equal to the current epoch, then try to claim for the current epoch
        if (userLastEpoch == epoch) return _claimEpochRewards(epoch);

        // If not, then the user has not claimed rewards from the next epoch
        // Check if the user has claimed all rewards from the last epoch first
        uint256 userClaimedRewardsPerToken = rewardsPerTokenClaimed[msg.sender];
        uint256 rewardsPerTokenEnd = epochRewardsPerTokenStart[userLastEpoch + 1];
        if (userClaimedRewardsPerToken < rewardsPerTokenEnd) {
            // If not, then claim the remaining rewards from the last epoch
            uint256 remainingLastEpochRewards = _claimEpochRewards(userLastEpoch);
            uint256 nextEpochRewards = _claimEpochRewards(userLastEpoch + 1);
            return remainingLastEpochRewards + nextEpochRewards;
        } else {
            // If so, then claim the rewards from the next epoch
            return _claimEpochRewards(userLastEpoch + 1);
        }
    }

    function _claimEpochRewards(uint48 epoch_) internal returns (uint256) {
        // Claims all outstanding rewards for the user for the specified epoch
        // If the option token for the epoch has expired, the rewards are lost

        // Check that the epoch is valid
        if (epoch_ > epoch) revert OLM_InvalidEpoch();

        // Get the rewards per token claimed by the user
        uint256 userRewardsClaimed = rewardsPerTokenClaimed[msg.sender];

        // Get the rewards per token at the start of the epoch and the rewards per token at the end of the epoch (start of the next one)
        // If the epoch is the current epoch, the rewards per token at the end of the epoch is the current rewards per token stored
        uint256 rewardsPerTokenStart = epochRewardsPerTokenStart[epoch_];
        uint256 rewardsPerTokenEnd = epoch_ == epoch
            ? rewardsPerTokenStored
            : epochRewardsPerTokenStart[epoch_ + 1];

        // If the user hasn't claimed the rewards up to the start of this epoch, then they have a previous unclaimed epoch
        // External functions protect against this by their ordering, but this makes it explicit
        if (userRewardsClaimed < rewardsPerTokenStart) revert OLM_PreviousUnclaimedEpoch();

        // If user rewards claimed is greater than or equal to the rewards per token at the end of the epoch, then the user has already claimed all rewards for the epoch
        if (userRewardsClaimed >= rewardsPerTokenEnd) return 0;

        // If not, then the user has not claimed all rewards for the epoch

        // Set the rewards per token claimed by the user to the rewards per token at the end of the epoch
        rewardsPerTokenClaimed[msg.sender] = rewardsPerTokenEnd;
        lastEpochClaimed[msg.sender] = epoch_;

        // Get the option token for the epoch
        FixedStrikeOptionToken optionToken = epochOptionTokens[epoch_];
        // If the option token has expired, then the rewards are zero
        if (uint256(optionToken.expiry()) < block.timestamp) return 0;

        // If the option token is still valid, we need to issue rewards
        uint256 rewards = ((rewardsPerTokenEnd - userRewardsClaimed) * stakeBalance[msg.sender]) /
            10 ** stakedTokenDecimals;
        // If the rewards are zero, then the user has already claimed all rewards for the epoch
        // We return early to avoid errors with zero value transfers
        if (rewards == 0) return 0;

        // Mint the option token on the teller
        // This transfers the reward amount of payout tokens to the option teller in exchange for the amount of option tokens
        payoutToken.safeApprove(address(optionTeller), rewards);
        optionTeller.create(optionToken, rewards);

        // Transfer rewards to sender
        ERC20(address(optionToken)).safeTransfer(msg.sender, rewards);

        // Return the amount of rewards claimed
        return rewards;
    }

    function _startNewEpoch() internal {
        // Starts a new epoch, assumes that a check has been performed that the epoch can start and that rewards were updated prior to calling
        epoch++;
        epochStart = uint48(block.timestamp);
        epochRewardsPerTokenStart[epoch] = rewardsPerTokenStored;

        // Deploy new option token and store against the epoch
        FixedStrikeOptionToken optionToken = optionTeller.deploy(
            payoutToken,
            quoteToken,
            uint48(block.timestamp) + timeUntilEligible,
            uint48(block.timestamp) + timeUntilEligible + eligibleDuration,
            receiver,
            true,
            nextStrikePrice()
        );
        epochOptionTokens[epoch] = optionToken;

        // Emit event
        emit NewEpoch(epoch, optionToken);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Returns the current rewards per token value updated to the second
    function currentRewardsPerToken() public view returns (uint256) {
        // Rewards do not accrue if the total balance is zero
        if (totalBalance == 0) return rewardsPerTokenStored;

        // The number of rewards to apply is based on the reward rate and the amount of time that has passed since the last reward update
        // The rewards per token is the current rewards per token plus the rewards to apply divided by the total staked balance
        // We combine the calculations and do division at the end to avoid precision loss
        return
            rewardsPerTokenStored +
            rewardRate.mulDiv(
                (block.timestamp - lastRewardUpdate) * 10 ** stakedTokenDecimals,
                totalBalance * REWARD_PERIOD
            );
    }

    /// @notice Returns the strike price that would be used if a new epoch started right now
    function nextStrikePrice() public view virtual returns (uint256);

    /* ========== ADMIN FUNCTIONS ========== */

    // Staking management

    /// @notice Toggle whether deposits are enabled
    /// @notice Only owner
    /// @param depositsEnabled_ Whether deposits should be enabled
    function setDepositsEnabled(bool depositsEnabled_) external onlyOwner requireInitialized {
        // Set whether deposits are enabled
        depositsEnabled = depositsEnabled_;
    }

    /// @notice Manually start a new epoch
    /// @notice Only owner
    function triggerNextEpoch() external onlyOwner requireInitialized updateRewards {
        // Triggers the next epoch, allowing the owner to move through epochs manually if desired.
        // This allows fixing configuration issues or adjusting for severe market events.
        _startNewEpoch();
    }

    /// @notice Withdraw payout tokens that were deposited to the contract for rewards
    /// @notice Only owner
    /// @param to_     The address to withdraw to
    /// @param amount_ The amount to withdraw
    function withdrawPayoutTokens(address to_, uint256 amount_) external onlyOwner {
        // Revert if the amount is greater than the balance
        // Transfer will check this, but we provide a more helpful error message
        if (amount_ > payoutToken.balanceOf(address(this)) || amount_ == 0)
            revert OLM_InvalidAmount();

        // Withdraws payout tokens from the contract
        payoutToken.safeTransfer(to_, amount_);
    }

    /// @notice Set the staking reward rate
    /// @notice Only owner
    /// @param rewardRate_ Amount of option tokens rewarded per reward period (1 day)
    function setRewardRate(
        uint256 rewardRate_
    ) external onlyOwner requireInitialized updateRewards {
        // Check if a new epoch needs to be started
        // We do this to avoid bad state if the reward rate is changed when a new epoch should have started
        if (block.timestamp >= epochStart + epochDuration) _startNewEpoch();

        // Set the reward rate
        rewardRate = rewardRate_;
    }

    /// @notice Set the epoch duration
    /// @notice Only owner
    /// @param epochDuration_ Staking epoch duration (in seconds)
    function setEpochDuration(uint48 epochDuration_) external onlyOwner requireInitialized {
        // The option token expiry must be greater than the epoch duration
        if (timeUntilEligible + eligibleDuration < epochDuration_) revert OLM_InvalidParams();

        // Set the epoch duration
        epochDuration = epochDuration_;
    }

    /// @notice Set the epoch transition reward
    /// @notice Only owner
    /// @param amount_ Amount of option tokens that are rewarded for starting a new epoch
    function setEpochTransitionReward(uint256 amount_) external onlyOwner requireInitialized {
        // Set the epoch transition reward
        epochTransitionReward = amount_;
    }

    // Option token parameters

    /// @notice Set the option receiver
    /// @notice Only owner
    /// @param receiver_ Address that will receive the quote tokens when an option is exercised
    /// IMPORTANT: receiver is the only address that can retrieve payout token collateral from expired options.
    /// It must be able to call the `reclaim` function on the Option Teller contract.
    function setOptionReceiver(address receiver_) external onlyOwner requireInitialized {
        // Set the receiver
        receiver = receiver_;
    }

    /// @notice Set the option duration
    /// @notice Only owner
    /// @param timeUntilEligible_ Amount of time (in seconds) from option token deployment to when it can be exercised
    /// @param eligibleDuration_  Amount of time (in seconds) from when the option token is eligible to when it expire
    function setOptionDuration(
        uint48 timeUntilEligible_,
        uint48 eligibleDuration_
    ) external onlyOwner requireInitialized {
        // Validate parameters
        // The eligible duration must be greater than the minimum option duration to be a valid option token
        if (eligibleDuration_ < optionTeller.minOptionDuration()) revert OLM_InvalidParams();

        // The option token expiry must be greater than the epoch duration
        if (timeUntilEligible_ + eligibleDuration_ - uint48(1 days) < epochDuration)
            revert OLM_InvalidParams();

        // Set the time until eligible and the eligible duration
        timeUntilEligible = timeUntilEligible_;
        eligibleDuration = eligibleDuration_;
    }

    /// @notice Set the quote token that is used for the option tokens
    /// @notice Only owner
    /// @param quoteToken_ Token that stakers must pay to exercise the call options they receive
    function setQuoteToken(ERC20 quoteToken_) external virtual onlyOwner requireInitialized {
        // Revert if the quote token is the zero address or not a contract
        if (address(quoteToken_) == address(0) || address(quoteToken_).code.length == 0)
            revert OLM_InvalidParams();

        // Set the quote token
        quoteToken = quoteToken_;
    }

    function setAllowlist(
        IAllowlist allowlist_,
        bytes calldata allowlistParams_
    ) external onlyOwner requireInitialized {
        // If the allowlist is not the zero address, assume it's being used and register the contract
        if (address(allowlist_) != address(0)) {
            // Since an allowlist is being used, we must confirm it is a contract
            if (address(allowlist_).code.length == 0) revert OLM_InvalidParams();

            // Store allowlist
            allowlist = allowlist_;

            // Register contract on allowlist, catch error if fails
            try allowlist.register(allowlistParams_) {} catch {
                revert OLM_InvalidParams();
            }
        } else {
            // If the allowlist is the zero address, then remove the current allowlist
            allowlist = IAllowlist(address(0));
        }
    }
}

// Implementations of different strike price setting mechanisms

/// @title Manual Strike Option Liquidity Mining (OLM)
/// @dev The Manual Strike OLM contract allows the owner to manually set the strike price that new option tokens are created with on epoch transition.
/// @author Bond Protocol
contract ManualStrikeOLM is OLM {
    /* ========== STATE VARIABLES ========== */

    /// @notice Strike price to be used for new option tokens
    uint256 public strikePrice;

    /* ========== CONSTRUCTOR ========== */

    /// @param owner_        Address of the owner of the OLM contract
    /// @param stakedToken_  Token that is staked in the OLM contract
    /// @param optionTeller_ Option Teller contract that is used by the OLM contract to deploy and create option tokens
    /// @param payoutToken_  Token that stakers receive call options for
    constructor(
        address owner_,
        ERC20 stakedToken_,
        IFixedStrikeOptionTeller optionTeller_,
        ERC20 payoutToken_
    ) OLM(owner_, stakedToken_, optionTeller_, payoutToken_) {}

    /* ========== INITIALIZE ========== */

    // Additional initialization logic for the manual strike price OLM
    /// @param params_ ABI-encoded bytes containing the initial strike price
    function _initialize(bytes calldata params_) internal override {
        uint256 strikePrice_ = abi.decode(params_, (uint256));

        // Revert if the strike price is 0 since it will be invalid on the teller
        if (strikePrice_ == 0) revert OLM_InvalidParams();

        // Set the strike price
        strikePrice = strikePrice_;
    }

    /* ========== STRIKE PRICE IMPLEMENTATION ========== */

    /// @inheritdoc OLM
    function nextStrikePrice() public view override returns (uint256) {
        return strikePrice;
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /// @notice Set the strike price to be used for future option tokens
    /// @notice Only owner
    /// @param strikePrice_ Strike price for the option tokens formatted as the number of quote tokens required per payout token
    function setStrikePrice(uint256 strikePrice_) external onlyOwner requireInitialized {
        // Revert if the strike price is 0 since it will be invalid on the teller
        if (strikePrice_ == 0) revert OLM_InvalidParams();

        strikePrice = strikePrice_;
    }
}

/// @title Oracle Strike Option Liquidity Mining (OLM)
/// @dev The Oracle Strike OLM contract uses an oracle to determine the fixed strike price when a new option token is created on epoch transition.
///      This should not be confused with Oracle Strike Option Tokens, whose strike price changes dynamically based on the oracle price.
/// @author Bond Protocol
contract OracleStrikeOLM is OLM {
    using FullMath for uint256;

    /* ========== STATE VARIABLES ========== */

    /// @notice Oracle contract used to get a current strike price when creating a new option token
    IBondOracle public oracle;

    /// @notice Discount to the oracle price used to set the strike price when creating a new option token
    uint48 public oracleDiscount;
    uint48 internal constant ONE_HUNDRED_PERCENT = 1e5;

    /// @notice Minimum strike price that can be set when creating a new option token, in number of quote tokens per payout token
    uint256 public minStrikePrice;

    /* ========== CONSTRUCTOR ========== */

    /// @param owner_        Address of the owner of the OLM contract
    /// @param stakedToken_  Token that is staked in the OLM contract
    /// @param optionTeller_ Option Teller contract that is used by the OLM contract to deploy and create option tokens
    /// @param payoutToken_  Token that stakers receive call options for
    constructor(
        address owner_,
        ERC20 stakedToken_,
        IFixedStrikeOptionTeller optionTeller_,
        ERC20 payoutToken_
    ) OLM(owner_, stakedToken_, optionTeller_, payoutToken_) {}

    /* ========== INITIALIZE ========== */

    // Additional initialization logic for the manual strike price OLM
    /// @param params_ ABI-encoded bytes containing the oracle, oracle discount, and minimum strike price
    function _initialize(bytes calldata params_) internal override {
        (IBondOracle oracle_, uint48 oracleDiscount_, uint256 minStrikePrice_) = abi.decode(
            params_,
            (IBondOracle, uint48, uint256)
        );

        // Validate parameters
        // Minimum strike price must be greater than zero and conform to the precision requirements in the option teller
        uint8 quoteDecimals = quoteToken.decimals();
        int8 priceDecimals = _getPriceDecimals(minStrikePrice_, quoteDecimals);

        // Revert if the price decimals are less than the minimum option decimals
        if (minStrikePrice_ == 0 || priceDecimals < -int8(quoteDecimals / 2))
            revert OLM_InvalidParams();

        // Oracle discount must be less than 100% (price cannot be zero)
        if (oracleDiscount_ >= ONE_HUNDRED_PERCENT) revert OLM_InvalidParams();
        // Oracle must be a valid contract
        if (address(oracle_) == address(0) || address(oracle_).code.length == 0)
            revert OLM_InvalidParams();

        // Oracle price must return a non-zero value for the quote and payout tokens
        uint256 oraclePrice = oracle_.currentPrice(quoteToken, payoutToken);
        if (oracle_.currentPrice(quoteToken, payoutToken) == 0) revert OLM_InvalidParams();

        // Convert oracle price to quote token decimals and apply discount
        // Initial oracle price must be greater than or equal to minimum
        // which has been validated for the teller requirements
        uint256 price = oraclePrice
            .mulDiv(10 ** quoteDecimals, 10 ** oracle_.decimals(quoteToken, payoutToken))
            .mulDiv(ONE_HUNDRED_PERCENT - oracleDiscount_, ONE_HUNDRED_PERCENT);
        if (price < minStrikePrice_) revert OLM_InvalidParams();

        // Set parameters
        oracle = oracle_;
        oracleDiscount = oracleDiscount_;
        minStrikePrice = minStrikePrice_;
    }

    /* ========== STRIKE PRICE IMPLEMENTATION ========== */

    /// @inheritdoc OLM
    function nextStrikePrice() public view override returns (uint256) {
        // Get oracle price and convert to quote token decimals
        uint256 price = (oracle.currentPrice(quoteToken, payoutToken) *
            10 ** quoteToken.decimals()) / 10 ** oracle.decimals(quoteToken, payoutToken);

        // Apply discount
        uint256 discountedPrice = (price * (ONE_HUNDRED_PERCENT - oracleDiscount)) /
            ONE_HUNDRED_PERCENT;

        // Return the larger of the discounted price and the minimum strike price
        return discountedPrice > minStrikePrice ? discountedPrice : minStrikePrice;
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /// @notice Set the oracle contract
    /// @notice Only owner
    /// @param oracle_ Oracle contract used to get a current strike price when creating a new option token
    function setOracle(IBondOracle oracle_) external onlyOwner requireInitialized {
        // Oracle must be a valid contract
        if (address(oracle_) == address(0) || address(oracle_).code.length == 0)
            revert OLM_InvalidParams();

        // Oracle price must return a non-zero value for the quote and payout tokens
        if (oracle_.currentPrice(quoteToken, payoutToken) == 0) revert OLM_InvalidParams();
        oracle = oracle_;
    }

    /// @notice Set the oracle discount
    /// @notice Only owner
    /// @param oracleDiscount_ Discount to the oracle price used to set the strike price when creating a new option token
    function setOracleDiscount(uint48 oracleDiscount_) external onlyOwner requireInitialized {
        // Oracle discount must be less than 100% (price cannot be zero)
        if (oracleDiscount_ >= ONE_HUNDRED_PERCENT) revert OLM_InvalidParams();

        oracleDiscount = oracleDiscount_;
    }

    /// @notice Set the minimum strike price
    /// @notice Only owner
    /// @param minStrikePrice_ Minimum strike price that can be set when creating a new option token, in number of quote tokens per payout token
    function setMinStrikePrice(uint256 minStrikePrice_) external onlyOwner requireInitialized {
        // Minimum strike price must be greater than zero and conform to the precision requirements in the option teller
        uint8 quoteDecimals = quoteToken.decimals();
        int8 priceDecimals = _getPriceDecimals(minStrikePrice_, quoteDecimals);

        // Revert if the price decimals are less than the minimum option decimals
        if (minStrikePrice_ == 0 || priceDecimals < -int8(quoteDecimals / 2))
            revert OLM_InvalidParams();

        minStrikePrice = minStrikePrice_;
    }

    /// @inheritdoc OLM
    function setQuoteToken(ERC20 quoteToken_) external override onlyOwner requireInitialized {
        // Revert if the quote token is the zero address or not a contract
        if (address(quoteToken_) == address(0) || address(quoteToken_).code.length == 0)
            revert OLM_InvalidParams();

        // Revert if the oracle price returns a zero value for the new quote token
        if (oracle.currentPrice(quoteToken_, payoutToken) == 0) revert OLM_InvalidParams();

        // Set the quote token
        quoteToken = quoteToken_;
    }

    /// @notice Helper function to calculate number of price decimals in the provided price
    /// @param price_   The price to calculate the number of decimals for
    /// @return         The number of decimals
    function _getPriceDecimals(uint256 price_, uint8 tokenDecimals_) internal pure returns (int8) {
        int8 decimals;
        while (price_ >= 10) {
            price_ = price_ / 10;
            decimals++;
        }

        // Subtract the stated decimals from the calculated decimals to get the relative price decimals.
        // Required to do it this way vs. normalizing at the beginning since price decimals can be negative.
        return decimals - int8(tokenDecimals_);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IOptionTeller {
    /// @notice         Set minimum duration to exercise option
    /// @notice         Access controlled
    /// @dev            Absolute minimum is 1 day (86400 seconds) due to timestamp rounding of eligible and expiry parameters
    /// @param duration_ Minimum duration in seconds
    function setMinOptionDuration(uint48 duration_) external;

    /// @notice         Set protocol fee
    /// @notice         Access controlled
    /// @param fee_     Protocol fee in basis points (3 decimal places)
    function setProtocolFee(uint48 fee_) external;

    /// @notice         Claim fees accrued by protocol in the input tokens and sends them to the provided address
    /// @notice         Access controlled
    /// @param tokens_  Array of tokens to claim fees for
    /// @param to_      Address to send fees to
    function claimFees(ERC20[] memory tokens_, address to_) external;

    /// @notice         Minimum duration an option must be eligible for exercise for (in seconds)
    function minOptionDuration() external view returns (uint48);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {OptionToken, ERC20} from "src/bases/OptionToken.sol";

/// @title Fixed Strike Option Token
/// @notice Fixed Strike Option Token Contract (ERC-20 compatible)
///
/// @dev The Fixed Strike Option Token contract is issued by a
///      Fixed Strike Option Token Teller to represent traditional
///      American-style options on the underlying token with a fixed strike price.
///
///      Call option tokens can be exercised for the underlying token 1:1
///      by paying the amount * strike price in the quote token
///      at any time between the eligible and expiry timestamps.
///
/// @dev This contract uses Clones (https://github.com/wighawag/clones-with-immutable-args)
///      to save gas on deployment and is based on VestedERC20 (https://github.com/ZeframLou/vested-erc20)
///
/// @author Bond Protocol
contract FixedStrikeOptionToken is OptionToken {
    /* ========== IMMUTABLE PARAMETERS ========== */

    /// @notice The strike price of the option
    /// @return _strike The option strike price specified in the amount of quote tokens per underlying token
    function strike() public pure returns (uint256 _strike) {
        return _getArgUint256(0x9e);
    }

    /* ========== VIEW ========== */

    /// @notice Get collection of option parameters in a single call
    /// @return decimals_  The number of decimals for the option token (same as payout token)
    /// @return payout_    The address of the payout token
    /// @return quote_     The address of the quote token
    /// @return eligible_  The option exercise eligibility timestamp
    /// @return expiry_    The option exercise expiry timestamp
    /// @return receiver_  The address of the receiver
    /// @return call_      Whether the option is a call (true) or a put (false)
    /// @return strike_    The option strike price specified in the amount of quote tokens per underlying token
    function getOptionParameters()
        external
        pure
        returns (
            uint8 decimals_,
            ERC20 payout_,
            ERC20 quote_,
            uint48 eligible_,
            uint48 expiry_,
            address receiver_,
            bool call_,
            uint256 strike_
        )
    {
        return (decimals(), payout(), quote(), eligible(), expiry(), receiver(), call(), strike());
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBondOracle {
    /// @notice Returns the price as a ratio of quote tokens to base tokens for the provided token pair scaled by 10^decimals
    function currentPrice(ERC20 quoteToken_, ERC20 payoutToken_) external view returns (uint256);

    /// @notice Returns the number of configured decimals of the price value for the provided token pair
    function decimals(ERC20 quoteToken_, ERC20 payoutToken_) external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IAllowlist {
    /// @notice         Check if address is allowed to interact with sending contract
    /// @param user_    Address to check
    /// @param proof_   Data to be used in determining allow status (optional, depends on specific implementation)
    /// @return         True if allowed, false otherwise
    function isAllowed(address user_, bytes calldata proof_) external view returns (bool);

    /// @notice         Check if address is allowed to interact with market ID on sending contract
    /// @param id_      Market ID to check
    /// @param user_    Address to check
    /// @param proof_   Data to be used in determining allow status (optional, depends on specific implementation
    /// @return         True if allowed, false otherwise
    function isAllowed(
        uint256 id_,
        address user_,
        bytes calldata proof_
    ) external view returns (bool);

    /// @notice         Register allowlist for sending address
    /// @dev            Can be used to intialize or update an allowlist
    /// @param params_  Parameters to configure allowlist (depends on specific implementation)
    function register(bytes calldata params_) external;

    /// @notice         Register allowlist for market ID on sending address
    /// @dev            Can be used to intialize or update an allowlist
    /// @param id_      Market ID to register allowlist for
    /// @param params_  Parameters to configure allowlist (depends on specific implementation)
    function register(uint256 id_, bytes calldata params_) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice Safe ERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// @author Taken from Solmate.
library TransferHelper {
    function safeTransferFrom(ERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, amount)
        );

        require(
            success &&
                (data.length == 0 || abi.decode(data, (bool))) &&
                address(token).code.length > 0,
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(ERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transfer.selector, to, amount)
        );

        require(
            success &&
                (data.length == 0 || abi.decode(data, (bool))) &&
                address(token).code.length > 0,
            "TRANSFER_FAILED"
        );
    }

    function safeApprove(ERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    // function safeTransferETH(address to, uint256 amount) internal {
    //     (bool success, ) = to.call{value: amount}(new bytes(0));

    //     require(success, "ETH_TRANSFER_FAILED");
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {CloneERC20} from "src/lib/clones/CloneERC20.sol";

/// @title Option Token
/// @notice Option Token Contract (ERC-20 compatible)
///
/// @dev The Option Token contract is issued by a Option Token Teller to
///      represent American-style options on the underlying token.
///
///      Call option tokens can be exercised for the underlying token 1:1
///      by paying the amount * strike price in the quote token
///      at any time between the eligible and expiry timestamps.
///
///      Put option tokens can be exercised for the underlying token 1:1
///      by paying the amount of the underlying token to receive the
///      amount * strike price in the quote token at any time between
///      the eligible and expiry timestamps.
///
/// @dev This contract uses Clones (https://github.com/wighawag/clones-with-immutable-args)
///      to save gas on deployment and is based on VestedERC20 (https://github.com/ZeframLou/vested-erc20)
///
/// @author Bond Protocol
abstract contract OptionToken is CloneERC20 {
    /* ========== ERRORS ========== */
    error OptionToken_OnlyTeller();

    /* ========== IMMUTABLE PARAMETERS ========== */

    /// @notice The token that the option is on
    /// @return _payout The address of the payout token
    function payout() public pure returns (ERC20 _payout) {
        return ERC20(_getArgAddress(0x41));
    }

    /// @notice The token that the option is quoted in
    /// @return _quote The address of the quote token
    function quote() public pure returns (ERC20 _quote) {
        return ERC20(_getArgAddress(0x55));
    }

    /// @notice Timestamp at which the Option token can first be exercised
    /// @return _eligible The option exercise eligibility timestamp
    function eligible() public pure returns (uint48 _eligible) {
        return _getArgUint48(0x69);
    }

    /// @notice Timestamp at which the Option token cannot be exercised after
    /// @return _expiry The option exercise expiry timestamp
    function expiry() public pure returns (uint48 _expiry) {
        return _getArgUint48(0x6f);
    }

    /// @notice Address that will receive the proceeds when option tokens are exercised
    /// @return _receiver The address of the receiver
    function receiver() public pure returns (address _receiver) {
        return _getArgAddress(0x75);
    }

    /// @notice Whether the option is a call or a put
    /// @return _call True if the option is a call, false if the option is a put
    function call() public pure returns (bool _call) {
        return _getArgBool(0x89);
    }

    /// @notice Address of the Teller that created the token
    function teller() public pure returns (address _teller) {
        return _getArgAddress(0x8a);
    }

    /* ========== MINT/BURN ========== */

    /// @notice Mint option tokens
    /// @notice Only callable by the Teller that created the token
    /// @param to     The address to mint to
    /// @param amount The amount to mint
    function mint(address to, uint256 amount) external {
        if (msg.sender != teller()) revert OptionToken_OnlyTeller();
        _mint(to, amount);
    }

    /// @notice Burn option tokens
    /// @notice Only callable by the Teller that created the token
    /// @param from   The address to burn from
    /// @param amount The amount to burtn
    function burn(address from, uint256 amount) external {
        if (msg.sender != teller()) revert OptionToken_OnlyTeller();
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Clone} from "src/lib/clones/Clone.sol";

/// @notice Modern and gas efficient ERC20 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract CloneERC20 is Clone {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public nonces;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 public chainId;

    bytes32 internal domainSeparator;

    /*///////////////////////////////////////////////////////////////
                               METADATA
    //////////////////////////////////////////////////////////////*/

    function name() public pure returns (string memory) {
        return string(abi.encodePacked(_getArgUint256(0)));
    }

    function symbol() external pure returns (string memory) {
        return string(abi.encodePacked(_getArgUint256(0x20)));
    }

    function decimals() public pure returns (uint8) {
        return _getArgUint8(0x40);
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == chainId ? domainSeparator : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name())),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function updateDomainSeparator() external {
        require(block.chainid != chainId, "DOMAIN_SEPARATOR_ALREADY_UPDATED");

        chainId = block.chainid;

        domainSeparator = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] += amount;

        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);

        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] -= amount;

        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    function _getImmutableVariablesOffset() internal pure returns (uint256 offset) {
        assembly {
            offset := sub(calldatasize(), add(shr(240, calldataload(sub(calldatasize(), 2))), 2))
        }
    }
}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset) internal pure returns (address arg) {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset) internal pure returns (uint256 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset) internal pure returns (uint64 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint48
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint48(uint256 argOffset) internal pure returns (uint48 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xd0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type bool
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgBool(uint256 argOffset) internal pure returns (bool arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(calldatasize(), add(shr(240, calldataload(sub(calldatasize(), 2))), 2))
        }
    }
}