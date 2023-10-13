// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IGauge } from "../interfaces/IGAUGE.sol";
import { IPool } from "../interfaces/IPOOL.sol";

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { WETH } from "solmate/tokens/WETH.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";

/**
 * Bond design:
 * 0) Arbitrum deployment
 * 1) ERC4626 guidance
 * 2) Accept [USDC, USDT, Curve2CoinStablePoolToken(USDC/USDT)] tokens for deposits for ease of investment
 * 3) Treasurey Tokens are USDC / USDT (low risk)
 * 4) Rewards are fixed at 10% per year pro-rata
 * 5) Minimum lock-up period of investment (6 months)
 * 6) All balances are in terms of Curve 2Pool (USDC/USDT) LP value, which mitigates dpeg attacks
 */

/// @title GreenBond vault contract to provide liquidity and earn rewards
/// @author @sandybradley
/// @notice ERC4626 with some key differences:
/// 0) Accept [USDC, USDT, Curve2CoinStablePoolToken(USDC/USDT)] tokens for deposits
contract GreenBond is ERC20("GreenBond", "gBOND", 18) {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               ERRORS
    //////////////////////////////////////////////////////////////*/

    error InsufficientAsset();
    error InsufficientLiquidity();
    error InsufficientBalance();
    error InsufficientAllowance();
    error UnknownToken();
    error ZeroShares();
    error ZeroAmount();
    error ZeroAddress();
    error Overflow();
    error IdenticalAddresses();
    error InsufficientLockupTime();
    error Unauthorized();
    error NoRewardsToClaim();
    error NotProject();

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    

    uint8 public constant USDC_INDEX = 0;
    uint8 public constant USDT_INDEX = 1;
    /// @notice USDC address
    address public constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    /// @notice USDT address
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    /// @notice Curve 2 Pool (USDT / USDC)
    address public constant STABLE_POOL = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
    /// @notice Curve Gauge for 2 Pool (USDT / USDC)
    address public constant GAUGE = 0xCE5F24B7A95e9cBa7df4B54E911B4A3Dc8CDAf6f;
    uint256 public constant YEAR_IN_SECONDS = 365 days;
    ERC20 public constant asset = ERC20(STABLE_POOL);
    
    /*//////////////////////////////////////////////////////////////
                               GLOBALS
    //////////////////////////////////////////////////////////////*/

    /// @notice Fixed reward percent per year
    uint16 public FIXED_INTEREST = 10;

    /// @notice Deposit lockup time, default 3 months
    uint64 public LOCKUP = 3 * 30 days;

    /// @notice Governance address
    address public GOV;

    /// @notice Transient tokens deployed to project (~ 3 months lock-up)
    uint256 public DEPLOYED_TOKENS;

    /// @notice Time weighted average lockup time
    mapping(address => uint256) public depositTimestamps;

    mapping(address => uint256) private rewards;

    mapping(address => uint256) private lastClaimTimestamps;

    /*//////////////////////////////////////////////////////////////
                                PROJECTS
    //////////////////////////////////////////////////////////////*/

    struct Project {
        bool isActive;
        bool isCompleted;
        address admin;
        uint128 totalAssetsSupplied;
        uint128 totalAssetsRepaid;
        string projectName;
        string masterAgreement;
    }

    uint256 public projectCount;
    mapping(uint256 => Project) public projects;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit event
    event Deposit(address indexed depositor, address token, uint256 amount, uint256 shares);

    /// @notice Withdraw event
    event Withdraw(address indexed receiver, address token, uint256 amount, uint256 shares);

    event Claim(address indexed receiver, address token, uint256 amount, uint256 shares);
    event Compound(address indexed receiver, uint256 shares);
    event PaidProject(address admin, uint256 amount, uint256 projectId);
    event ReceivedIncome(address indexed sender, uint256 assets, uint256 projectId);
    event RewardsClaimed(address indexed sender, address token, uint256 tokenAmount, uint256 shares);
    event RewardsCompounded(address indexed sender, uint256 shares);
    event ProjectRegistered(uint256 indexed project);

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        GOV = tx.origin; // CREATE2 deployment requires tx.origin
    }

    /*//////////////////////////////////////////////////////////////
                                 GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    function _govCheck() internal view {
        if (msg.sender != GOV) revert Unauthorized();
    }

    function changeLockup(uint64 newLockup) external {
        _govCheck();
        LOCKUP = newLockup;
    }

    function changeGov(address newGov) external {
        _govCheck();
        GOV = newGov;
    }

    function changeInterest(uint16 newInterest) external {
        _govCheck();
        FIXED_INTEREST = newInterest;
    }

    function _tokenCheck(address token) internal pure {
        if (token != USDC && token != USDT && token != STABLE_POOL) revert UnknownToken();
    }

    function _liquidityCheck(uint256 assets) internal view {
        if (_isZero(assets)) revert ZeroAmount();
        if (IGauge(GAUGE).balanceOf(address(this)) < assets) revert InsufficientLiquidity();
    }

    /**
     * @dev Registers a new Project
     */
    function registerProject(address projectAdmin, string calldata projectName) external returns (uint256) {
        _govCheck();
        if (projectAdmin == address(0)) revert ZeroAddress();

        Project memory project;
        project.admin = projectAdmin;
        project.projectName = projectName;

        unchecked{
            ++projectCount;
        }

        projects[projectCount] = project;

        emit ProjectRegistered(projectCount);

        return projectCount;
    }

    function linkProjectAgreement(uint256 projectId, string calldata masterAgreement) external {
        _govCheck();
        projects[projectId].masterAgreement = masterAgreement;
    }

    function completeProject(uint256 projectId) external {
        _govCheck();
        if (projects[projectId].totalAssetsRepaid > projects[projectId].totalAssetsSupplied) {
            projects[projectId].isCompleted = true;
        }
    }

    function payProject(address token, uint256 tokenAmount, uint256 projectId) external {
        _govCheck();
        if (projectId > projectCount) revert NotProject();
        _tokenCheck(token);
        if (!projects[projectId].isActive) {
            projects[projectId].isActive = true;
        }
        uint256[2] memory amounts;
        if (token == USDT) amounts[USDT_INDEX] = tokenAmount;
        else amounts[USDC_INDEX] = tokenAmount;
        uint256 assets = IPool(STABLE_POOL).calc_token_amount(amounts, false) * 998/1000;
        projects[projectId].totalAssetsSupplied += uint128(assets);

        tokenAmount = _beforeWithdraw(token, assets);

        unchecked {
            DEPLOYED_TOKENS += assets;
        }

        ERC20(token).approve(projects[projectId].admin, tokenAmount);

        emit PaidProject(projects[projectId].admin, assets, projectId);

        ERC20(token).safeTransfer(projects[projectId].admin, tokenAmount);
    }

    function receiveIncome(address token, uint256 tokenAmount, uint256 projectId) external {
        _tokenCheck(token);
        uint256 assets = _deposit(token, tokenAmount);
        projects[projectId].totalAssetsRepaid += uint128(assets);
        if (assets > DEPLOYED_TOKENS) {
            delete DEPLOYED_TOKENS;
        } else {
            unchecked {
                DEPLOYED_TOKENS -= assets;
            }
        }
        emit ReceivedIncome(msg.sender, assets, projectId);
    }

    function recoverToken(address token, address receiver, uint256 tokenAmount) external {
        _govCheck();
        ERC20(token).safeTransfer(receiver, tokenAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit token for gBOND
    /// @dev Requires token approval or value sent with call
    /// @param token Address of token being deposited (For eth sent use weth address)
    /// @param tokenAmount Amount of token to deposit
    /// @return shares returned to sender for deposit
    function deposit(address token, uint256 tokenAmount) external payable virtual returns (uint256 shares) {
        uint256 assets = _deposit(token, tokenAmount);
        shares = previewDeposit(assets);
        if (_isZero(shares)) revert ZeroShares();

        // Set the deposit timestamp for the user
        _updateDepositTimestamp(msg.sender, shares);

        _mint(msg.sender, shares);

        emit Deposit(msg.sender, token, tokenAmount, shares);
    }

    function _updateDepositTimestamp(address account, uint256 shares) internal {
        // Set the deposit timestamp for the user
        uint256 prevBalance = balanceOf[account];
        if (_isZero(prevBalance)) {
            depositTimestamps[account] = block.timestamp;
        } else {
            // multiple deposits, so weight timestamp by amounts
            unchecked {
                depositTimestamps[account] = ((depositTimestamps[account] * prevBalance) + (block.timestamp * shares)) / (prevBalance + shares);
            }
        }
    }

    /// @notice Withdraw shares for usdt. Requires sender to have approved vault to spend share amount
    /// @param token Either Usdt or Usdc
    /// @param shares Shares to withdraw
    /// @return tokenAmount amount of tokens returned
    function withdraw(address token, uint256 shares) public virtual returns (uint256 tokenAmount) {
        _tokenCheck(token);
        if (block.timestamp < depositTimestamps[msg.sender] + LOCKUP) revert InsufficientLockupTime();

        // compound rewards, add to shares
        shares += _compound();
        if (shares > balanceOf[msg.sender]) revert InsufficientBalance();

        uint256 assets = previewRedeem(shares);
        _liquidityCheck(assets);

        tokenAmount = _beforeWithdraw(token, assets);

        _burn(msg.sender, shares);

        emit Withdraw(msg.sender, token, tokenAmount, shares);

        ERC20(token).safeTransfer(msg.sender, tokenAmount);
    }

    function claimRewards(address token) external returns (uint256 tokenAmount) {
        _tokenCheck(token);
        uint256 unclaimedRewards = _calculateUnclaimedRewards(msg.sender);
        if (_isZero(unclaimedRewards)) revert NoRewardsToClaim();
        uint256 assets = previewRedeem(unclaimedRewards);
        _liquidityCheck(assets);

        unchecked {
            rewards[msg.sender] += unclaimedRewards;
            lastClaimTimestamps[msg.sender] = block.timestamp;
        }

        tokenAmount = _beforeWithdraw(token, assets);
        ERC20(token).safeTransfer(msg.sender, tokenAmount);

        emit RewardsClaimed(msg.sender, token, tokenAmount, unclaimedRewards);
    }

    function _compound() internal returns (uint256 unclaimedRewards) {
        unclaimedRewards = _calculateUnclaimedRewards(msg.sender);
        if (_isZero(unclaimedRewards)) return unclaimedRewards;

        unchecked {
            rewards[msg.sender] += unclaimedRewards;
            lastClaimTimestamps[msg.sender] = block.timestamp;
        }

        _mint(msg.sender, unclaimedRewards);

        emit RewardsCompounded(msg.sender, unclaimedRewards);
    }

    function _calculateUnclaimedRewards(address user) internal view returns (uint256 unclaimedRewards) {
        uint256 lastClaimTimestamp = lastClaimTimestamps[user];
        if (_isZero(lastClaimTimestamp)) {
            // User has never claimed rewards before, so calculate from deposit timestamp
            lastClaimTimestamp = depositTimestamps[user];
        }
        unchecked {
            uint256 elapsedTime = block.timestamp - lastClaimTimestamp;
            unclaimedRewards = uint256(FIXED_INTEREST) * elapsedTime * balanceOf[user] / (100 * YEAR_IN_SECONDS);
        }
        return unclaimedRewards;
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256) {
        unchecked {
            return (DEPLOYED_TOKENS + IGauge(GAUGE).balanceOf(address(this)));
        }
    }

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256 assets) {
        assets = convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function _beforeWithdraw(address token, uint256 assets) internal virtual returns (uint256) {
        // withdraw from Curve Gauge
        IGauge(GAUGE).withdraw(assets, address(this), true);
        if (token == STABLE_POOL) return assets;
        // withdraw from Curve pool
        int128 index;
        if (token == USDT) index = 1;
        uint256 minTokenAmount = IPool(STABLE_POOL).calc_withdraw_one_coin(assets, index) * 98 / 100;
        return IPool(STABLE_POOL).remove_liquidity_one_coin(assets, index, minTokenAmount);
    }

    /// @notice Adds liquidity to an currve 2 pool from USDT / USDC
    /// @param token token to stake
    /// @param tokenAmount amount to stake
    /// @return assets amount of liquidity token received, sent to msg.sender
    function _stakeLiquidity(address token, uint256 tokenAmount) internal returns (uint256 assets) {
        if (tokenAmount < 2000) revert InsufficientAsset();
        uint256[2] memory amounts;
        if (token == USDT) amounts[USDT_INDEX] = tokenAmount;
        else amounts[USDC_INDEX] = tokenAmount;
        uint256 minMintAmount = IPool(STABLE_POOL).calc_token_amount(amounts, true) * 98 / 100;
        ERC20(token).approve(STABLE_POOL, tokenAmount);
        assets = IPool(STABLE_POOL).add_liquidity(amounts, minMintAmount);
    }

    /// @custom:gas Uint256 zero check gas saver
    /// @notice Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        /// @solidity memory-safe-assembly
        assembly {
            boolValue := iszero(value)
        }
    }

    /// @custom:gas Uint256 not zero check gas saver
    /// @notice Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        /// @solidity memory-safe-assembly
        assembly {
            boolValue := iszero(iszero(value))
        }
    }

    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable virtual { }

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable { }

    function _deposit(address token, uint256 tokenAmount) internal returns (uint256 assets) {
        if (ERC20(token).allowance(msg.sender, address(this)) < tokenAmount) revert InsufficientAllowance();
        if (token == USDC || token == USDT) {
            // Need to transfer before minting or ERC777s could reenter.
            ERC20(token).safeTransferFrom(msg.sender, address(this), tokenAmount);
            assets = _stakeLiquidity(token, tokenAmount);
        } else if (token == STABLE_POOL) {
            // Need to transfer before minting or ERC777s could reenter.
            ERC20(token).safeTransferFrom(msg.sender, address(this), tokenAmount);
            assets = tokenAmount;
        } else {
            revert UnknownToken();
        }
        // deposit LP to curve
        asset.approve(GAUGE, assets);
        IGauge(GAUGE).deposit(assets);
    }

    /// @dev override erc20 transfer to update receiver deposit timestamp
    function transfer(address to, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;

        _updateDepositTimestamp(to, amount);

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    /// @dev override erc20 transferFrom to update receiver deposit timestamp
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        _updateDepositTimestamp(to, amount);

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }
}

pragma solidity ^0.8.10;

interface IGauge {
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Deposit(address indexed _user, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event UpdateLiquidityLimit(
        address indexed _user,
        uint256 _original_balance,
        uint256 _original_supply,
        uint256 _working_balance,
        uint256 _working_supply
    );
    event Withdraw(address indexed _user, uint256 _value);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function add_reward(address _reward_token, address _distributor) external;
    function allowance(address arg0, address arg1) external view returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
    function balanceOf(address arg0) external view returns (uint256);
    function claim_rewards() external;
    function claim_rewards(address _addr) external;
    function claim_rewards(address _addr, address _receiver) external;
    function claimable_reward(address _user, address _reward_token) external view returns (uint256);
    function claimable_tokens(address addr) external returns (uint256);
    function claimed_reward(address _addr, address _token) external view returns (uint256);
    function decimals() external view returns (uint256);
    function decreaseAllowance(address _spender, uint256 _subtracted_value) external returns (bool);
    function deposit(uint256 _value) external;
    function deposit(uint256 _value, address _user) external;
    function deposit(uint256 _value, address _user, bool _claim_rewards) external;
    function deposit_reward_token(address _reward_token, uint256 _amount) external;
    function factory() external view returns (address);
    function increaseAllowance(address _spender, uint256 _added_value) external returns (bool);
    function inflation_rate(uint256 arg0) external view returns (uint256);
    function initialize(address _lp_token, address _manager) external;
    function integrate_checkpoint() external view returns (uint256);
    function integrate_checkpoint_of(address arg0) external view returns (uint256);
    function integrate_fraction(address arg0) external view returns (uint256);
    function integrate_inv_supply(uint256 arg0) external view returns (uint256);
    function integrate_inv_supply_of(address arg0) external view returns (uint256);
    function is_killed() external view returns (bool);
    function lp_token() external view returns (address);
    function manager() external view returns (address);
    function name() external view returns (string memory);
    function nonces(address arg0) external view returns (uint256);
    function period() external view returns (uint256);
    function period_timestamp(uint256 arg0) external view returns (uint256);
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (bool);
    function reward_count() external view returns (uint256);
    function reward_data(address arg0) external view returns (address, uint256, uint256, uint256, uint256);
    function reward_integral_for(address arg0, address arg1) external view returns (uint256);
    function reward_tokens(uint256 arg0) external view returns (address);
    function rewards_receiver(address arg0) external view returns (address);
    function set_killed(bool _is_killed) external;
    function set_manager(address _manager) external;
    function set_reward_distributor(address _reward_token, address _distributor) external;
    function set_rewards_receiver(address _receiver) external;
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function update_voting_escrow() external;
    function user_checkpoint(address addr) external returns (bool);
    function version() external view returns (string memory);
    function voting_escrow() external view returns (address);
    function withdraw(uint256 _value) external;
    function withdraw(uint256 _value, address _user) external;
    function withdraw(uint256 _value, address _user, bool _claim_rewards) external;
    function working_balances(address arg0) external view returns (uint256);
    function working_supply() external view returns (uint256);
}

pragma solidity ^0.8.10;

interface IPool {
    event AddLiquidity(
        address indexed provider, uint256[2] token_amounts, uint256[2] fees, uint256 invariant, uint256 token_supply
    );
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event CommitNewAdmin(uint256 indexed deadline, address indexed admin);
    event CommitNewFee(uint256 indexed deadline, uint256 fee, uint256 admin_fee);
    event NewAdmin(address indexed admin);
    event NewFee(uint256 fee, uint256 admin_fee);
    event RampA(uint256 old_A, uint256 new_A, uint256 initial_time, uint256 future_time);
    event RemoveLiquidity(address indexed provider, uint256[2] token_amounts, uint256[2] fees, uint256 token_supply);
    event RemoveLiquidityImbalance(
        address indexed provider, uint256[2] token_amounts, uint256[2] fees, uint256 invariant, uint256 token_supply
    );
    event RemoveLiquidityOne(address indexed provider, uint256 token_amount, uint256 coin_amount, uint256 token_supply);
    event StopRampA(uint256 A, uint256 t);
    event TokenExchange(
        address indexed buyer, int128 sold_id, uint256 tokens_sold, int128 bought_id, uint256 tokens_bought
    );
    event Transfer(address indexed sender, address indexed receiver, uint256 value);

    function A() external view returns (uint256);
    function A_precise() external view returns (uint256);
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount, address _receiver)
        external
        returns (uint256);
    function admin_actions_deadline() external view returns (uint256);
    function admin_balances(uint256 i) external view returns (uint256);
    function admin_fee() external view returns (uint256);
    function allowance(address arg0, address arg1) external view returns (uint256);
    function apply_new_fee() external;
    function apply_transfer_ownership() external;
    function approve(address _spender, uint256 _value) external returns (bool);
    function balanceOf(address arg0) external view returns (uint256);
    function balances(uint256 arg0) external view returns (uint256);
    function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);
    function coins(uint256 arg0) external view returns (address);
    function commit_new_fee(uint256 _new_fee, uint256 _new_admin_fee) external;
    function commit_transfer_ownership(address _owner) external;
    function decimals() external view returns (uint256);
    function donate_admin_fees() external;
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy, address _receiver) external returns (uint256);
    function fee() external view returns (uint256);
    function future_A() external view returns (uint256);
    function future_A_time() external view returns (uint256);
    function future_admin_fee() external view returns (uint256);
    function future_fee() external view returns (uint256);
    function future_owner() external view returns (address);
    function get_balances() external view returns (uint256[2] memory);
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function get_virtual_price() external view returns (uint256);
    function initial_A() external view returns (uint256);
    function initial_A_time() external view returns (uint256);
    function kill_me() external;
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function ramp_A(uint256 _future_A, uint256 _future_time) external;
    function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts)
        external
        returns (uint256[2] memory);
    function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts, address _receiver)
        external
        returns (uint256[2] memory);
    function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);
    function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount, address _receiver)
        external
        returns (uint256);
    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received)
        external
        returns (uint256);
    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received, address _receiver)
        external
        returns (uint256);
    function revert_new_parameters() external;
    function revert_transfer_ownership() external;
    function stop_ramp_A() external;
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function transfer_ownership_deadline() external view returns (uint256);
    function unkill_me() external;
    function withdraw_admin_fees() external;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}